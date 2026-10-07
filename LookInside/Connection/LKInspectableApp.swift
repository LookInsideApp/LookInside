//
//  LKInspectableApp.swift
//  LookInside
//
//  Created by Li Kai on 2018/11/3.
//  https://lookin.work
//
//  One app the Host can inspect, and the requests it sends to that app's
//  Server.
//

import Foundation

/// What a request to the inspected app reports: zero or more values (the
/// `data` of each response), then a failure or a completion.
enum LKAppResponseEvent {
    case value(Any?)
    case failure(NSError)
    case completion
}

@objc(LKInspectableApp)
final class LKInspectableApp: NSObject {
    /// Set when the app's Server is too old or too new for this Host, or
    /// answered the app info request with another error.
    @objc dynamic var serverVersionError: NSError?

    @objc dynamic var appInfo: LookinAppInfo?

    @objc dynamic weak var channel: LKChannel?

    // MARK: - Requests

    /// Sends a request on `channel`. Each response's error becomes a
    /// failure, localized for the object-not-found and inner-error codes;
    /// otherwise its `data`, passed through `transform`, becomes a value.
    /// The returned sink stops the delivery when detached.
    @MainActor
    static func startRequest(
        on channel: LKChannel,
        type: UInt32,
        data: NSObject?,
        transform: ((Any?) -> Any?)? = nil,
        onEvent: @escaping (LKAppResponseEvent) -> Void
    ) -> LKResponseSink {
        var hasEnded = false
        let sink = LKResponseSink { event in
            guard !hasEnded else { return }
            switch event {
            case let .response(attachment):
                if let serverError = attachment?.error {
                    hasEnded = true
                    onEvent(.failure(LKConnectionError.localized(serverError as NSError)))
                } else {
                    let value = attachment?.data
                    onEvent(.value(transform.map { $0(value) } ?? value))
                }
            case let .failure(error):
                hasEnded = true
                onEvent(.failure(error))
            case .completion:
                hasEnded = true
                onEvent(.completion)
            }
        }
        LKConnectionManager.shared.request(type: type, data: data, channel: channel, sink: sink)
        return sink
    }

    /// Every value of a request until it completes.
    @MainActor
    func responses(type: UInt32, data: NSObject?, transform: ((Any?) -> Any?)? = nil) -> AsyncThrowingStream<Any?, Error> {
        AsyncThrowingStream { continuation in
            guard let channel else {
                continuation.finish(throwing: LKConnectionError.noConnect)
                return
            }
            let sink = Self.startRequest(on: channel, type: type, data: data, transform: transform) { event in
                switch event {
                case let .value(value):
                    continuation.yield(value)
                case let .failure(error):
                    continuation.finish(throwing: error)
                case .completion:
                    continuation.finish()
                }
            }
            continuation.onTermination = { _ in
                Task { @MainActor in sink.detach() }
            }
        }
    }

    /// The values of a request, each cast to `Value`. A value of another
    /// type ends the stream with `LookinErr_Inner`.
    @MainActor
    func typedResponses<Value>(type: UInt32, data: NSObject?, as _: Value.Type) -> AsyncThrowingStream<Value, Error> {
        let untyped = responses(type: type, data: data)
        return AsyncThrowingStream { continuation in
            let task = Task { @MainActor in
                do {
                    for try await value in untyped {
                        guard let typed = value as? Value else {
                            throw LKConnectionError.inner
                        }
                        continuation.yield(typed)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// The single value of a request that answers once, cast to `Value`.
    /// A request that completes without a value, or with a value of
    /// another type, throws `LookinErr_Inner`.
    @MainActor
    func response<Value>(type: UInt32, data: NSObject?, as _: Value.Type, transform: ((Any?) -> Any?)? = nil) async throws -> Value {
        for try await value in responses(type: type, data: data, transform: transform) {
            guard let typed = value as? Value else {
                throw LKConnectionError.inner
            }
            return typed
        }
        throw LKConnectionError.inner
    }

    /// Sends a push frame; nothing when the channel is gone.
    @MainActor
    func push(type: UInt32, data: NSObject?) {
        guard let channel else { return }
        LKConnectionManager.shared.push(type: type, data: data, channel: channel)
    }

    /// Ends the waiting request of `type` and reports it as completed.
    @MainActor
    func cancelRequest(type: UInt32) {
        guard let channel else { return }
        LKConnectionManager.shared.cancelRequest(type: type, channel: channel)
    }

    // MARK: - Request payloads

    /// The hierarchy request's parameters: the Host version (since Lookin
    /// 1.0.4), the SwiftUI display mode, and whether to include backing
    /// layers (old Servers ignore the keys they do not know).
    static func hierarchyRequestParameters() -> NSDictionary {
        let parameters = NSMutableDictionary(dictionary: ["clientVersion": LKHelper.lookinReadableVersion() as NSString])
        parameters[LookinParam_SwiftUIDisplayMode] = NSNumber(value: LKSwiftUIHierarchyDisplayModeStore.currentMode().rawValue)
        parameters["showBackingLayers"] = NSNumber(value: LKPreferenceManager.shared.showBackingLayers.currentBOOLValue)
        return parameters
    }

    static func selectorNamesParameters(className: String, hasArg: Bool) -> NSDictionary {
        NSDictionary(
            objects: [className as NSString, NSNumber(value: hasArg)],
            forKeys: ["className" as NSString, "hasArg" as NSString]
        )
    }

    static func invokeMethodParameters(oid: UInt, text: String) -> NSDictionary {
        NSDictionary(
            objects: [NSNumber(value: oid), text as NSString],
            forKeys: ["oid" as NSString, "text" as NSString]
        )
    }

    static func gestureRecognizerParameters(oid: UInt, enabled: Bool) -> NSDictionary {
        NSDictionary(
            objects: [NSNumber(value: oid), NSNumber(value: enabled)],
            forKeys: ["oid" as NSString, "enable" as NSString]
        )
    }

    /// A method without a return value is reported with a local sentence
    /// instead of the Server's marker.
    static func localizingVoidReturn(_ value: Any?) -> Any? {
        guard let dictionary = value as? NSDictionary,
              (dictionary["description"] as? String) == LookinStringFlag_VoidReturn
        else {
            return value
        }
        let localized = dictionary.mutableCopy() as! NSMutableDictionary
        localized["description"] = NSLocalizedString("The method was invoked successfully and no value was returned.", comment: "")
        return localized
    }
}

// MARK: - Async API

extension LKInspectableApp {
    @MainActor
    func hierarchy() async throws -> LookinHierarchyInfo {
        try await response(type: UInt32(LookinRequestTypeHierarchy), data: Self.hierarchyRequestParameters(), as: LookinHierarchyInfo.self)
    }

    /// Returns the updated detail of the modified item.
    @MainActor
    func submit(_ modification: LookinAttributeModification) async throws -> LookinDisplayItemDetail {
        try await response(type: UInt32(LookinRequestTypeInbuiltAttrModification), data: modification, as: LookinDisplayItemDetail.self)
    }

    @MainActor
    func submit(_ modification: LookinCustomAttrModification) async throws -> Any? {
        try await response(type: UInt32(LookinRequestTypeCustomAttrModification), data: modification, as: Any?.self)
    }

    /// One array of details per package the Server finished.
    @MainActor
    func hierarchyDetails(packages: [LookinStaticAsyncUpdateTasksPackage]) -> AsyncThrowingStream<[LookinDisplayItemDetail], Error> {
        typedResponses(type: UInt32(LookinRequestTypeHierarchyDetails), data: packages as NSArray, as: [LookinDisplayItemDetail].self)
    }

    /// Stops the running hierarchy details request: it completes, and the
    /// Server is told to stop sending.
    @objc
    @MainActor
    func cancelHierarchyDetailFetching() {
        cancelRequest(type: UInt32(LookinRequestTypeHierarchyDetails))
        push(type: UInt32(LookinPush_CanceHierarchyDetails), data: nil)
    }

    /// One detail per modified item, as the Server finishes them.
    @MainActor
    func modificationPatch(tasks: [LookinStaticAsyncUpdateTask]) -> AsyncThrowingStream<LookinDisplayItemDetail, Error> {
        typedResponses(type: UInt32(LookinRequestTypeAttrModificationPatch), data: tasks as NSArray, as: LookinDisplayItemDetail.self)
    }

    @MainActor
    func object(oid: UInt) async throws -> LookinObject {
        guard oid != 0 else { throw LKConnectionError.inner }
        return try await response(type: UInt32(LookinRequestTypeFetchObject), data: NSNumber(value: oid), as: LookinObject.self)
    }

    @MainActor
    func attributeGroups(oid: UInt) async throws -> [LookinAttributesGroup] {
        guard oid != 0 else { throw LKConnectionError.inner }
        return try await response(type: UInt32(LookinRequestTypeAllAttrGroups), data: NSNumber(value: oid), as: [LookinAttributesGroup].self)
    }

    @MainActor
    func selectorNames(className: String, hasArg: Bool) async throws -> [String] {
        try await response(
            type: UInt32(LookinRequestTypeAllSelectorNames),
            data: Self.selectorNamesParameters(className: className, hasArg: hasArg),
            as: [String].self
        )
    }

    /// The Server's result dictionary (`description` and related keys).
    @MainActor
    func invokeMethod(oid: UInt, text: String) async throws -> NSDictionary {
        guard oid != 0, !text.isEmpty else { throw LKConnectionError.inner }
        return try await response(
            type: UInt32(LookinRequestTypeInvokeMethod),
            data: Self.invokeMethodParameters(oid: oid, text: text),
            as: NSDictionary.self,
            transform: Self.localizingVoidReturn
        )
    }

    /// The image of the image view `oid`, as encoded image data.
    @MainActor
    func image(imageViewOid oid: UInt) async throws -> Data? {
        guard oid != 0 else { throw LKConnectionError.inner }
        return try await response(type: UInt32(LookinRequestTypeFetchImageViewImage), data: NSNumber(value: oid), as: Data?.self)
    }

    /// Versioned controls for the optional SwiftUI gesture capture service.
    @MainActor
    func controlGestureDebug(_ parameters: NSDictionary) async throws -> NSDictionary {
        try await response(type: UInt32(LookinRequestTypeGestureDebug), data: parameters, as: NSDictionary.self)
    }

    /// Returns whether the recognizer is enabled afterwards.
    @MainActor
    func setGestureRecognizer(oid: UInt, enabled: Bool) async throws -> Bool {
        guard oid != 0 else { throw LKConnectionError.inner }
        return try await response(
            type: UInt32(LookinRequestTypeModifyRecognizerEnable),
            data: Self.gestureRecognizerParameters(oid: oid, enabled: enabled),
            as: Bool.self
        )
    }
}
