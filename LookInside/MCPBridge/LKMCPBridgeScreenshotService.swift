// LKMCPBridgeScreenshotService.swift
//
// Handles the `screenshot.read` bridge route: renders one display item —
// either on its own (`solo`) or together with its whole subtree
// (`group`) — and returns it as PNG bytes.
//
// Why every mode goes through RPC 203 rather than RPC 201 `App`:
//   RPC 201 with `needImages=YES` also carries a whole-app screenshot
//   (`LookinAppInfo.screenshot`), but reaching it means driving
//   AppsManager's discovery request, which re-scans
//   *every* Peertalk port and rebuilds a fresh `InspectableApp` list
//   for all connected apps. That is a heavyweight, side-effecting
//   operation to perform for one picture, and the resulting screenshot
//   is whatever the app looked like when the scan ran. Taking a `group`
//   screenshot of the key window instead produces the same picture,
//   freshly rendered, over the same code path as every other mode.
//   Callers who want "the whole screen" simply omit `objectIdentifier`
//   and get the key window's group screenshot.
//
// Caching: the host already holds `soloScreenshot` / `groupScreenshot`
// on `LookinDisplayItem` whenever the inspector UI has rendered that
// view. Those are served directly (`fromCache: true`) so repeat calls
// stay cheap. On a miss the service issues RPC 203 with the matching
// task type. InspectionSession commits the complete response to its cache
// and graphical subscribers before this service encodes the fresh image.
//
// Redaction: screenshots are pixels, and the host's secure-content
// redactor only ever operated on attribute *strings*. A screenshot is
// therefore returned unredacted, and the result carries
// `containsSecureContent` so the agent — and the human reading its
// transcript — can see when the frame covered a secure input view.
// Blacking out secure regions is deliberately deferred; see
// docs/monorepo/mcp-design.md §E.3.

import AppKit
import CoreGraphics
import Foundation
import LookInsideInspectionCore
import os

@MainActor
public final class LKMCPBridgeScreenshotService {
    // MARK: - Configuration

    /// Default cap on the longest side of the returned image, in pixels.
    /// Screenshots land directly in an LLM context window, where a full
    /// 3x device screenshot costs a meaningful share of the budget for
    /// detail no agent uses. 1024 keeps interface text legible while
    /// holding a typical PNG in the low hundreds of kilobytes.
    private static let defaultMaximumPixelDimension = 1024

    /// Hard ceiling for `maximumPixelDimension`. Above this the base64
    /// payload starts to rival the connection's 8 MB frame cap for no
    /// practical gain.
    private static let hardMaximumPixelDimension = 4096

    /// Lower bound, purely to reject nonsense input (0, negatives).
    private static let minimumPixelDimension = 16

    // MARK: - Error code constants from LookinDefines.h

    //
    // See LKMCPBridgeInvocationService for the duplication rationale.

    private static let lookinErrCodeObjectNotFound = -500
    private static let lookinErrCodeInner = -401
    private static let lookinErrCodeLicenseRequired = -408
    private static let lookinErrCodeNoConnect = -403
    private static let lookinErrCodeTimeout = -405

    private static let logger = Logger(subsystem: "com.lookinside.app", category: "MCPBridge.Screenshot")

    public init() {}

    // MARK: - Screenshot mode

    /// Which of the two `LookinDisplayItemDetail` screenshot slots the
    /// caller wants. Mirrors `LookinStaticAsyncUpdateTaskType` minus its
    /// `NoScreenshot` case, which has no meaning on this route.
    private enum ScreenshotMode: String {
        /// The view alone, with its subviews hidden during capture.
        case solo
        /// The view together with everything it contains.
        case group

        var taskType: LookinStaticAsyncUpdateTaskType {
            switch self {
            case .solo: return .soloScreenshot
            case .group: return .groupScreenshot
            }
        }

        func cachedImage(on displayItem: LookinDisplayItem) -> NSImage? {
            switch self {
            case .solo: return displayItem.soloScreenshot
            case .group: return displayItem.groupScreenshot
            }
        }

        func image(in detail: LookinDisplayItemDetail) -> NSImage? {
            switch self {
            case .solo: return detail.soloScreenshot
            case .group: return detail.groupScreenshot
            }
        }
    }

    // MARK: - Entry point

    public func handle(request: LKMCPBridgeRequest) async -> LKMCPBridgeResponse {
        guard request.method == "screenshot.read" else {
            return .failure(identifier: request.identifier, error: .unknownMethod)
        }
        return await handleScreenshotRead(
            identifier: request.identifier,
            parameters: request.parameters
        )
    }

    // MARK: - screenshot.read

    private func handleScreenshotRead(
        identifier: String,
        parameters: [String: LKMCPBridgeJSONValue]?
    ) async -> LKMCPBridgeResponse {
        guard let parameters,
              case let .string(targetIdentifier)? = parameters["targetIdentifier"]
        else {
            return .failure(identifier: identifier, error: .invalidParameters)
        }

        let requestedObjectIdentifier: String?
        if case let .string(raw)? = parameters["objectIdentifier"] {
            requestedObjectIdentifier = raw
        } else {
            requestedObjectIdentifier = nil
        }

        let mode: ScreenshotMode
        if case let .string(raw)? = parameters["mode"] {
            guard let parsed = ScreenshotMode(rawValue: raw) else {
                return .failure(
                    identifier: identifier,
                    error: LKMCPBridgeErrorPayload(
                        code: "screenshot.invalidMode",
                        message: "Unsupported screenshot mode \"\(raw)\". Valid modes are \"solo\" and \"group\"."
                    )
                )
            }
            mode = parsed
        } else {
            mode = .group
        }

        let maximumPixelDimension: Int
        switch parameters["maximumPixelDimension"] {
        case let .integer(raw)?:
            maximumPixelDimension = Int(raw)
        case let .double(raw)?:
            maximumPixelDimension = Int(raw)
        case .none, .some(.null):
            maximumPixelDimension = Self.defaultMaximumPixelDimension
        default:
            return .failure(identifier: identifier, error: .invalidParameters)
        }
        guard maximumPixelDimension >= Self.minimumPixelDimension,
              maximumPixelDimension <= Self.hardMaximumPixelDimension
        else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "screenshot.invalidPixelDimension",
                    message: "maximumPixelDimension must be between \(Self.minimumPixelDimension) and \(Self.hardMaximumPixelDimension); received \(maximumPixelDimension)."
                )
            )
        }

        // Live-session lookup
        guard let session = InspectionSessionLookup.findSession(targetIdentifier: targetIdentifier) else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "hierarchy.targetNotFound",
                    message: "No inspection session found for target identifier \(targetIdentifier)."
                )
            )
        }
        guard session.captureDate != nil else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "hierarchy.notReady",
                    message: "Live session has not loaded a hierarchy yet."
                )
            )
        }

        // Resolve which display item to capture.
        let roots = InspectionSessionLookup.topLevelDisplayItems(in: session)
        let displayItem: LookinDisplayItem
        if let requestedObjectIdentifier {
            guard let found = InspectionSessionLookup.findDisplayItem(
                amongRoots: roots,
                matchingObjectIdentifier: requestedObjectIdentifier
            ) else {
                return .failure(
                    identifier: identifier,
                    error: LKMCPBridgeErrorPayload(
                        code: "screenshot.objectNotFound",
                        message: "Object identifier \(requestedObjectIdentifier) is not present in this target's hierarchy. Refresh via get_hierarchy and retry."
                    )
                )
            }
            displayItem = found
        } else {
            // No explicit target: capture the key window, which is what
            // "show me the screen" means. Fall back to the first root
            // when no window reports itself as key (can happen briefly
            // during app launch or when the app is backgrounded).
            guard let keyWindowItem = roots.first(where: { $0.representedAsKeyWindow }) ?? roots.first else {
                return .failure(
                    identifier: identifier,
                    error: LKMCPBridgeErrorPayload(
                        code: "screenshot.objectNotFound",
                        message: "This target's hierarchy has no top-level window to capture."
                    )
                )
            }
            displayItem = keyWindowItem
        }

        let resolvedObjectIdentifier = InspectionSessionLookup.objectIdentifierString(for: displayItem)
        let containsSecureContent = Self.subtreeContainsSecureContent(rootDisplayItem: displayItem)

        // Fast path: the inspector UI already rendered this view, so the
        // image is sitting on the display item.
        if let cachedImage = mode.cachedImage(on: displayItem) {
            return encodeResponse(
                identifier: identifier,
                image: cachedImage,
                objectIdentifier: resolvedObjectIdentifier,
                mode: mode,
                displayItem: displayItem,
                maximumPixelDimension: maximumPixelDimension,
                containsSecureContent: containsSecureContent,
                servedFromCache: true
            )
        }

        // Slow path: ask the target app to render it now.
        guard let nativeObjectIdentifier = displayItem.displayingObject()?.oid,
              nativeObjectIdentifier != 0
        else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "screenshot.objectNotFound",
                    message: "The resolved display item has no live object behind it; it was probably deallocated. Refresh via get_hierarchy and retry."
                )
            )
        }

        let task = LookinStaticAsyncUpdateTask()
        task.oid = nativeObjectIdentifier
        task.taskType = mode.taskType
        // Attributes are `read_attributes` / `read_view_details` territory;
        // asking for them here would make the target app build attribute
        // groups it is about to throw away.
        task.attrRequest = .notNeed
        task.needBasisVisualInfo = false
        task.needSubitems = false
        task.clientReadableVersion = InspectionEnvironment.shared().clientReadableVersion

        let package = LookinStaticAsyncUpdateTasksPackage()
        package.tasks = [task]

        guard let signal = session.inspectableApp.rawFetchHierarchyDetail(withTaskPackages: [package]) else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "screenshot.internalError",
                    message: "The target's inspectable app returned no signal for the fetch."
                )
            )
        }

        let frames: [NSArray]
        do {
            frames = try await LKMCPBridgeRACBridge.awaitAllValues(of: signal, as: NSArray.self)
        } catch RACBridgeError.completedWithoutValue {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "screenshot.notAvailable",
                    message: "The target app completed the render request without returning an image."
                )
            )
        } catch RACBridgeError.cancelled {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "screenshot.cancelled",
                    message: "The render was cancelled before the target app returned an image."
                )
            )
        } catch let error as NSError {
            // Must stay below the RACBridgeError clauses. Every Swift error
            // bridges to NSError, so this pattern matches everything -- above
            // them it silently swallows both, and they become dead code.
            return .failure(identifier: identifier, error: mapScreenshotError(error))
        } catch {
            Self.logger.error("screenshot.read bridge error: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }

        // Find our detail in the streamed frames. We sent exactly one
        // task, so at most one detail can match.
        var matchingDetail: LookinDisplayItemDetail?
        for frame in frames {
            for entry in frame {
                guard let detail = entry as? LookinDisplayItemDetail,
                      detail.displayItemOid == nativeObjectIdentifier
                else { continue }
                matchingDetail = detail
                break
            }
            if matchingDetail != nil {
                break
            }
        }

        guard let detail = matchingDetail else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "screenshot.notAvailable",
                    message: "The target app did not return a detail for the requested object."
                )
            )
        }
        if detail.failureCode == -1 {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "screenshot.objectNotFound",
                    message: "The target app could not find the requested object; it may have been deallocated. Refresh via get_hierarchy and retry."
                )
            )
        }

        // Merge into the host cache so the inspector UI and any repeat
        // call see the same image without another round-trip.

        guard let renderedImage = mode.image(in: detail) else {
            // The server has real paths that return a detail with no
            // image — notably `solo` on an AppKit view that is not
            // layer-backed and has no subviews, where neither capture
            // branch fires. Tell the agent to retry in `group` rather
            // than leaving it to guess.
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "screenshot.notAvailable",
                    message: "The target app returned no \(mode.rawValue) screenshot for this object. Some views cannot be captured in \"solo\" mode; retry with mode \"group\"."
                )
            )
        }

        return encodeResponse(
            identifier: identifier,
            image: renderedImage,
            objectIdentifier: resolvedObjectIdentifier,
            mode: mode,
            displayItem: displayItem,
            maximumPixelDimension: maximumPixelDimension,
            containsSecureContent: containsSecureContent,
            servedFromCache: false
        )
    }

    // MARK: - Encoding

    private func encodeResponse(
        identifier: String,
        image: NSImage,
        objectIdentifier: String,
        mode: ScreenshotMode,
        displayItem: LookinDisplayItem,
        maximumPixelDimension: Int,
        containsSecureContent: Bool,
        servedFromCache: Bool
    ) -> LKMCPBridgeResponse {
        guard let encoded = Self.encodePNG(from: image, maximumPixelDimension: maximumPixelDimension) else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "screenshot.encodingFailed",
                    message: "The captured image could not be encoded as PNG."
                )
            )
        }

        let result = LKMCPBridgeScreenshotResult(
            objectIdentifier: objectIdentifier,
            mode: mode.rawValue,
            imageData: encoded.pngData.base64EncodedString(),
            mimeType: "image/png",
            pixelWidth: encoded.pixelWidth,
            pixelHeight: encoded.pixelHeight,
            sourcePixelWidth: encoded.sourcePixelWidth,
            sourcePixelHeight: encoded.sourcePixelHeight,
            byteCount: encoded.pngData.count,
            frame: LKMCPBridgeRect(cgRect: InspectionSessionLookup.rootSpaceFrame(for: displayItem)),
            servedFromCache: servedFromCache,
            containsSecureContent: containsSecureContent
        )

        do {
            let payload = try encodeAsJSONValue(result)
            return .success(identifier: identifier, result: payload)
        } catch {
            Self.logger.error("screenshot.read encode failed: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }
    }

    /// Encodes an `NSImage` as PNG, downscaling so the longest side does
    /// not exceed `maximumPixelDimension`. Works in pixels rather than
    /// points throughout: the source is a Retina capture whose point size
    /// is half (or a third) of what actually matters for payload size.
    private static func encodePNG(
        from image: NSImage,
        maximumPixelDimension: Int
    ) -> (pngData: Data, pixelWidth: Int, pixelHeight: Int, sourcePixelWidth: Int, sourcePixelHeight: Int)? {
        guard let sourceImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let sourcePixelWidth = sourceImage.width
        let sourcePixelHeight = sourceImage.height
        guard sourcePixelWidth > 0, sourcePixelHeight > 0 else { return nil }

        let longestSourceSide = max(sourcePixelWidth, sourcePixelHeight)
        let renderedImage: CGImage
        let targetPixelWidth: Int
        let targetPixelHeight: Int

        if longestSourceSide > maximumPixelDimension {
            let scaleFactor = Double(maximumPixelDimension) / Double(longestSourceSide)
            targetPixelWidth = max(1, Int((Double(sourcePixelWidth) * scaleFactor).rounded()))
            targetPixelHeight = max(1, Int((Double(sourcePixelHeight) * scaleFactor).rounded()))
            guard let context = CGContext(
                data: nil,
                width: targetPixelWidth,
                height: targetPixelHeight,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return nil
            }
            context.interpolationQuality = .high
            context.draw(
                sourceImage,
                in: CGRect(x: 0, y: 0, width: targetPixelWidth, height: targetPixelHeight)
            )
            guard let scaledImage = context.makeImage() else { return nil }
            renderedImage = scaledImage
        } else {
            targetPixelWidth = sourcePixelWidth
            targetPixelHeight = sourcePixelHeight
            renderedImage = sourceImage
        }

        let bitmapRepresentation = NSBitmapImageRep(cgImage: renderedImage)
        guard let pngData = bitmapRepresentation.representation(using: .png, properties: [:]) else {
            return nil
        }
        return (
            pngData: pngData,
            pixelWidth: targetPixelWidth,
            pixelHeight: targetPixelHeight,
            sourcePixelWidth: sourcePixelWidth,
            sourcePixelHeight: sourcePixelHeight
        )
    }

    // MARK: - Helpers

    /// Walks a display item and everything under it looking for a view
    /// the secure-content detector flags. A `group` screenshot renders
    /// the whole subtree, so a secure field nested three levels down
    /// still ends up in the returned pixels.
    private static func subtreeContainsSecureContent(rootDisplayItem: LookinDisplayItem) -> Bool {
        var pendingItems: [LookinDisplayItem] = [rootDisplayItem]
        while pendingItems.isEmpty == false {
            let currentItem = pendingItems.removeFirst()
            if LKMCPBridgeSecureContentDetector.isSecure(displayItem: currentItem) {
                return true
            }
            if let subitems = currentItem.subitems {
                pendingItems.append(contentsOf: subitems)
            }
        }
        return false
    }

    private func mapScreenshotError(_ error: NSError) -> LKMCPBridgeErrorPayload {
        if let sessionError = InspectionSessionLookup.errorPayload(for: error, operation: "screenshot") {
            return sessionError
        }
        switch error.code {
        case Self.lookinErrCodeObjectNotFound:
            return LKMCPBridgeErrorPayload(
                code: "screenshot.objectNotFound",
                message: "The target app could not find the requested object. It may have been deallocated; refresh via get_hierarchy and retry."
            )
        case Self.lookinErrCodeInner:
            return LKMCPBridgeErrorPayload(
                code: "screenshot.internalError",
                message: "The target app rejected the render request with a generic inner error."
            )
        case Self.lookinErrCodeLicenseRequired:
            return .licenseRequired
        case Self.lookinErrCodeNoConnect:
            return LKMCPBridgeErrorPayload(
                code: "screenshot.disconnected",
                message: "The target app is no longer connected. Re-attach from the LookInside inspector and try again."
            )
        case Self.lookinErrCodeTimeout:
            return LKMCPBridgeErrorPayload(
                code: "screenshot.timeout",
                message: "The target app did not render within the request timeout. Check whether the target is paused in Xcode."
            )
        default:
            Self.logger.error("screenshot.read received unmapped error code \(error.code, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return LKMCPBridgeErrorPayload(
                code: "screenshot.internalError",
                message: "The target app reported an unexpected error (code \(error.code))."
            )
        }
    }

    private func encodeAsJSONValue(_ value: some Encodable) throws -> LKMCPBridgeJSONValue {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(LKMCPBridgeJSONValue.self, from: data)
    }
}
