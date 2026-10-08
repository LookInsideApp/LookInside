//
//  ConsoleDataSource.swift
//  LookInside
//
//  The Console's state: the transcript rows, the target object, the objects
//  highlighted in the hierarchy and the objects recent calls returned. It
//  calls methods on the inspected app through the live document's
//  InspectableApp.
//

import AppKit
import LookInsideHostCore

/// One transcript row.
struct ConsoleRowItem {
    enum Kind {
        /// The input field, always the last row.
        case input
        /// A call: the target in `highlightText`, the method in `normalText`.
        case submit
        /// A call's returned description in `normalText`.
        case returnValue
    }

    var kind: Kind
    var highlightText: String?
    var normalText: String?
}

@MainActor
final class ConsoleDataSource {
    /// An object returned by a call, with the call that returned it.
    struct RecentObject {
        var object: InspectedObject
        var message: String
    }

    weak var liveDocument: LiveDocument?

    /// Called after `rowItems` changes.
    var rowItemsDidChange: (() -> Void)?
    /// Called after `currentObject` changes.
    var currentObjectDidChange: (() -> Void)?

    private(set) var rowItems: [ConsoleRowItem] = [ConsoleRowItem(kind: .input)] {
        didSet { rowItemsDidChange?() }
    }

    /// The object calls are sent to.
    private(set) var currentObject: InspectedObject? {
        didSet { currentObjectDidChange?() }
    }

    /// The objects of the item selected in the hierarchy: its view
    /// controller, window controller, layer, view, window and kind object.
    private(set) var selectedObjects: [InspectedObject] = [] {
        didSet { syncConsoleTargetIfNeeded() }
    }

    private(set) var recentObjects = ConsoleRecentList<RecentObject>()

    var isShowingConsole = false {
        didSet { syncConsoleTargetIfNeeded() }
    }

    /// Selector names by raw class name, fetched once per class.
    private var selectorNamesByClass: [String: [String]] = [:]
    private var selectionObservation: NSKeyValueObservation?

    init(hierarchyDataSource: HierarchyDataSource) {
        selectionObservation = hierarchyDataSource.observe(\.selectedItem, options: [.initial, .new]) {
            [weak self] dataSource, _ in
            let objects = Self.objects(of: dataSource.selectedItem)
            MainActor.assumeIsolated {
                self?.selectedObjects = objects
            }
        }
    }

    private nonisolated static func objects(of item: DisplayItem?) -> [InspectedObject] {
        guard let item else { return [] }
        return [item.hostViewControllerObject, item.hostWindowControllerObject, item.layerObject,
                item.viewObject, item.windowObject, item.kindObject].compactMap { $0 }
    }

    var currentObjectSelectorNames: [String] {
        currentObject?.rawClassName().flatMap { selectorNamesByClass[$0] } ?? []
    }

    func submit(_ text: String) async throws {
        try await submit(object: currentObject, text: text)
    }

    /// Calls `text` on `object` and appends the call and its result to the
    /// transcript. An object it returns joins the recent objects.
    func submit(object: InspectedObject?, text: String) async throws {
        guard currentObject != nil, let object else {
            throw ConnectionError.inner
        }
        let check = ConsoleInputCheck(text)
        if check == .empty {
            throw PeripheralAlerts.error(title: NSLocalizedString("Content is empty.", comment: ""), detail: "")
        }
        guard let inspectableApp = liveDocument?.inspectableApp else {
            throw ConnectionError.noConnect
        }
        switch check {
        case .hasArguments:
            let format = NSLocalizedString("You can click \"Pause\" button near the bottom-left corner in Xcode to pause your iOS app, and input in Xcode console like the contents below:\nexpr [((%@ *)%@) %@]", comment: "")
            let detail = String(format: format, object.rawClassName() ?? "(null)", object.memoryAddress ?? "(null)", text)
            throw PeripheralAlerts.error(
                title: NSLocalizedString("LookInside doesn't support invoking methods with arguments yet.", comment: ""),
                detail: detail
            )
        case .unsupportedSyntax:
            throw PeripheralAlerts.error(
                title: NSLocalizedString("LookInside doesn't support this syntax yet. Please input a method or property name.", comment: ""),
                detail: ""
            )
        case .accepted, .empty:
            break
        }

        let result = try await inspectableApp.invokeMethod(oid: object.oid, text: text)
        let returnDescription = result["description"] as? String
        let returnObject = result["object"] as? InspectedObject
        let target = "<\(object.lk_simpleDemangledClassName()): \(object.memoryAddress ?? "(null)")>"

        var rows = rowItems
        rows.insert(ConsoleRowItem(kind: .submit, highlightText: target, normalText: text), at: rows.count - 1)
        if let returnDescription, !returnDescription.isEmpty {
            rows.insert(ConsoleRowItem(kind: .returnValue, normalText: returnDescription), at: rows.count - 1)
        }
        if let returnObject {
            recentObjects.insert(RecentObject(object: returnObject, message: "\(target) => \(text)"), id: returnObject.oid)
        }
        rowItems = rows
    }

    /// Makes `object` the call target, fetching its class's selector names first when needed.
    func makeObjectCurrent(_ object: InspectedObject?) async throws {
        guard let object, let className = object.rawClassName(), !className.isEmpty else {
            throw ConnectionError.inner
        }
        guard let inspectableApp = liveDocument?.inspectableApp else {
            throw ConnectionError.noConnect
        }
        if selectorNamesByClass[className] != nil {
            currentObject = object
            return
        }
        let names = try await inspectableApp.selectorNames(className: className, hasArg: true)
        selectorNamesByClass[className] = names
        currentObject = object
    }

    func clearHistoryContents() {
        rowItems = [ConsoleRowItem(kind: .input)]
    }

    private func syncConsoleTargetIfNeeded() {
        guard isShowingConsole, let lastSelected = selectedObjects.last else { return }
        if PreferenceManager.shared.syncConsoleTarget || currentObject == nil {
            Task {
                try? await makeObjectCurrent(lastSelected)
            }
        }
    }
}
