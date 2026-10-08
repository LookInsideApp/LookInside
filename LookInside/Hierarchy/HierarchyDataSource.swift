//
//  HierarchyDataSource.swift
//  LookInside
//
//  Created by Li Kai on 2019/5/6.
//  https://lookin.work
//

import AppKit
import LookInsideHostCore
import FoundationToolbox

/// What the data source is showing. KVO-observable through `state`.
@objc enum HierarchyDataSourceState: UInt {
    case normal
    case search
    case focus
}

/// What a hierarchy data source reports besides its KVO-observable
/// properties (`state`, `selectedItem`, `hoveredItem`, `displayingFlatItems`,
/// `rawHierarchyInfo`).
enum HierarchyDataSourceEvent {
    case willReloadHierarchyInfo
    case didReloadHierarchyInfo
    case didReloadFlatItemsWithSearchOrFocus
    case itemDidChangeHiddenAlphaValue(DisplayItem)
    case itemDidChangeAttrGroup(DisplayItem)
    /// Sent with no item: the preview rebuilds from the whole tree.
    case itemDidChangeNoPreview
    /// Static (live) data sources only.
    case itemDidChangeFrame(DisplayItem)
}

/// Classes collapsed by the expansion presets, together with the
/// hierarchy's own `collapsedClassList`.
private let classesPreferredToCollapse: Set<String> = [
    "UILabel", "UIPickerView", "UIProgressView", "UIActivityIndicatorView", "UIAlertView", "UIActionSheet",
    "UISearchBar", "UIButton", "UITextView", "UIDatePicker", "UIPageControl", "UISegmentedControl", "UITextField",
    "UISlider", "UISwitch", "UIVisualEffectView", "UIImageView", "WKCommonWebView", "UITextEffectsWindow",
]

/// Windows that never get a preview.
private let classesWithNoPreview: Set<String> = ["UITextEffectsWindow", "UIRemoteKeyboardWindow"]

/// Associated-object key of the expansion recorded before a search or focus,
/// restored when it ends.
private let expandedBeforeSearchOrFocusKey = "isExpandedBeforeSearching"

private func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

/// "Layer 2 Display List ID" -> 1; nil without a positive ordinal.
private func swiftUILayerOrdinal(fromAttributeTitle title: String) -> Int? {
    guard title.hasPrefix("Layer ") else {
        return nil
    }
    let scanner = Scanner(string: String(title.dropFirst("Layer ".count)))
    guard let value = scanner.scanInt(), value > 0 else {
        return nil
    }
    return value - 1
}

private func rectsAlmostEqual(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
    let tolerance: CGFloat = 1
    return abs(lhs.minX - rhs.minX) <= tolerance
        && abs(lhs.minY - rhs.minY) <= tolerance
        && abs(lhs.width - rhs.width) <= tolerance
        && abs(lhs.height - rhs.height) <= tolerance
}

private func swiftUINode(_ item: DisplayItem, matchesSourceTypes sourceTypes: [String]) -> Bool {
    guard !sourceTypes.isEmpty else {
        return true
    }
    let itemTypes = item.swiftUITypeNames()
    return sourceTypes.contains { itemTypes.contains($0) }
}

private func ancestors(of item: DisplayItem) -> [DisplayItem] {
    var result: [DisplayItem] = []
    item.enumerateAncestors { ancestor, _ in
        result.append(ancestor)
    }
    return result
}

private func selfAndDescendants(of item: DisplayItem) -> [DisplayItem] {
    var result: [DisplayItem] = []
    item.enumerateSelfAndChildren { node in
        result.append(node)
    }
    return result
}

/// The hierarchy tree of a document: the flat rows, selection, hover,
/// expansion, search and focus. Subclasses supply the preference manager.
@Loggable(subsystem: "com.lookinside.app")
class HierarchyDataSource: NSObject {
    /// KVO-observable.
    @objc dynamic var state: HierarchyDataSourceState {
        storedState
    }

    // Synchronous events; see SyncSignal. Everything sent on them also
    // reaches `events()`.
    final let willReloadHierarchyInfo = SyncSignal<Void>()
    final let didReloadHierarchyInfo = SyncSignal<Void>()
    /// An item's `isHidden` or `alpha` changed.
    final let itemDidChangeHiddenAlphaValue = SyncSignal<DisplayItem>()
    /// An item's attribute groups changed.
    final let itemDidChangeAttrGroup = SyncSignal<DisplayItem>()
    /// The preview rebuilds from the whole tree.
    final let itemDidChangeNoPreview = SyncSignal<Void>()
    /// A search or focus changed `flatItems`.
    final let didReloadFlatItemsWithSearchOrFocus = SyncSignal<Void>()

    /// Every display item of the tree, visible or not.
    @objc var rawFlatItems: [DisplayItem]? {
        get { storedRawFlatItems }
        set {
            storedRawFlatItems = newValue
            rebuildOidMap()
        }
    }

    /// All items in normal state; the shown subset while searching or
    /// focusing.
    @objc dynamic var flatItems: [DisplayItem]?

    /// The rows: the items of `flatItems` that no collapsed ancestor hides.
    /// KVO-observable.
    @objc dynamic var displayingFlatItems: [DisplayItem]? {
        storedDisplayingFlatItems
    }

    @objc dynamic weak var selectedItem: DisplayItem? {
        didSet {
            selectedItemDidChange(from: oldValue)
        }
    }

    @objc dynamic weak var hoveredItem: DisplayItem? {
        didSet {
            hoveredItemDidChange(from: oldValue)
        }
    }

    @objc var selectColorMenu: NSMenu? {
        storedSelectColorMenu
    }

    /// The tag of the color menu's "Other…" item.
    @objc var customColorMenuItemTag: Int {
        10
    }

    /// The tag of the color menu's "switch color format" item.
    @objc var toggleColorFormatMenuItemTag: Int {
        11
    }

    /// KVO-observable.
    @objc dynamic var rawHierarchyInfo: HierarchyInfo? {
        storedRawHierarchyInfo
    }

    /// While the dashboard is being searched, the preview must not change the
    /// selection when a layer is clicked.
    @objc var shouldAvoidChangingPreviewSelectionDueToDashboardSearch: Bool = false

    @objc var serverSideIsSwiftProject: Bool {
        storedServerSideIsSwiftProject
    }

    // Storage of the read-only properties. Writes go
    // through the setters below, which post the KVO notifications.
    private var storedState: HierarchyDataSourceState = .normal
    private var storedDisplayingFlatItems: [DisplayItem]?
    private var storedRawHierarchyInfo: HierarchyInfo?
    private var storedSelectColorMenu: NSMenu?
    private var storedServerSideIsSwiftProject = false
    private var storedRawFlatItems: [DisplayItem]?
    private var oidToDisplayItem: [UInt: DisplayItem] = [:]
    /// Alias names by `rgbaString`.
    private var colorToAliasMap: [String: [String]] = [:]
    private var lastRGBAFormat: Bool?
    private var rgbaFormatObservation: NSKeyValueObservation?
    private var signalSubscriptions: [SyncSubscription] = []
    final let eventBroadcaster = AsyncBroadcaster<HierarchyDataSourceEvent>()

    override init() {
        super.init()
        forwardSignalsToEvents()

        rgbaFormatObservation = PreferenceManager.shared.observe(\.rgbaFormat, options: [.new]) { [weak self] preferences, _ in
            guard let self else { return }
            // Every change after the first value, skipping repeats.
            let format = preferences.rgbaFormat
            if let lastRGBAFormat, lastRGBAFormat == format {
                return
            }
            lastRGBAFormat = format
            setUpColors()
        }

        // Toggling the system-layout-guide visibility re-filters the visible
        // rows; the tree data itself keeps every node.
        PreferenceManager.shared.showSystemLayoutGuides.subscribe(
            self,
            action: #selector(handleShowSystemLayoutGuidesDidChange(_:)),
            relatedObject: nil
        )
    }

    deinit {
        eventBroadcaster.finish()
        #log(.default, "\(NSStringFromClass(type(of: self)), privacy: .public) dealloc")
    }

    // MARK: - Reload

    @objc(reloadWithHierarchyInfo:keepState:)
    func reload(with info: HierarchyInfo?, keepState: Bool) {
        // Path identifiers of the old items resolve their root index against
        // the old root items, so take them before replacing the info.
        let previousRootItems = rawHierarchyInfo?.displayItems ?? []

        setKVO("rawHierarchyInfo") { storedRawHierarchyInfo = info }

        willReloadHierarchyInfo.send()

        if !(info?.colorAlias ?? [:]).isEmpty {
            PreferenceManager.shared.receivingConfigTime_Color = Date().timeIntervalSince1970
        }
        if !(info?.collapsedClassList ?? []).isEmpty {
            PreferenceManager.shared.receivingConfigTime_Class = Date().timeIntervalSince1970
        }

        var previousSelectedOid: UInt = 0
        var previousExpansion: [String: NSNumber] = [:]
        let prefersViewOID = AppHelper.appInfoLooksLikeMacTarget(info?.appInfo)
        if keepState {
            previousSelectedOid = selectedItem?.bestObjectOidPreferView(prefersViewOID) ?? 0
            for item in flatItems ?? [] {
                if let path = Self.pathIdentifier(for: item, inRootItems: previousRootItems) {
                    previousExpansion[path] = NSNumber(value: item.isExpanded)
                }
            }
        }

        setUpColors()

        // Flatten the tree; this also sets every item's indentLevel.
        rawFlatItems = DisplayItem.flatItems(fromHierarchicalItems: info?.displayItems ?? [])
        let items = rawFlatItems ?? []

        let collapsedClasses = classesPreferredToCollapse.union(info?.collapsedClassList ?? [])
        for item in items {
            if item.itemIsKindOfClasses(withNames: collapsedClasses) {
                item.enumerateSelfAndChildren { $0.preferToBeCollapsed = true }
            }
            // Windows sit at indent 0 (macOS, iOS before 13) or 1 (inside an
            // iOS 13+ scene).
            if item.indentLevel() <= 1, item.itemIsKindOfClasses(withNames: classesWithNoPreview) {
                item.noPreview = true
            }
            if !item.isPixelBearing() {
                // Guides, cells and a view's outer layer have no pixels of
                // their own: a screenshot would draw the owning view's
                // content a second time. No screenshot task; they stay in
                // the preview (guides and cells on their owner's plane, the
                // outer layer as a parallel plane of its own).
                item.doNotFetchScreenshotReason = .doNotFetchScreenshotForNoPixels
            }
            if !item.isUserCustom(), !item.shouldCaptureImage {
                item.enumerateSelfAndChildren { node in
                    node.noPreview = true
                    node.doNotFetchScreenshotReason = .doNotFetchScreenshotForUserConfig
                }
            }
            if !serverSideIsSwiftProject, item.displayingObject()?.completedDemangledClassName().contains(".") == true {
                storedServerSideIsSwiftProject = true
            }
            if let source = item.customInfo?.danceuiSource, !source.isEmpty {
                DanceUIAttributeMaker.makeDanceUIJumpAttribute(item, danceSource: source)
            }
        }

        flatItems = items

        var itemToSelect: DisplayItem?
        if keepState {
            itemToSelect = displayItem(withOid: previousSelectedOid)
        }

        var expansionIndex = preferenceManager().expansionIndex
        if (flatItems?.count ?? 0) > 300, expansionIndex > 2 {
            expansionIndex = 2
        }

        var referenceDict: [String: NSNumber]?
        if keepState {
            referenceDict = previousExpansion
        } else {
            // Cold reload: restore the state persisted for this bundle id
            // (expanded and user-collapsed items). Paths it lacks keep the
            // preset's behavior.
            let preferences = preferenceManager()
            if preferences.rememberExpansionState,
               let bundleIdentifier = info?.appInfo?.appBundleIdentifier, !bundleIdentifier.isEmpty
            {
                let stored = preferences.expansionState(forBundleIdentifier: bundleIdentifier)
                if !stored.isEmpty {
                    referenceDict = stored
                }
            }
        }
        if itemToSelect == nil {
            var presetSelection: DisplayItem?
            adjustExpansion(by: expansionIndex, referenceDict: referenceDict, selectedItem: &presetSelection)
            itemToSelect = presetSelection
        } else {
            adjustExpansion(by: expansionIndex, referenceDict: referenceDict, selectedItem: nil)
        }

        selectedItem = itemToSelect ?? flatItems?.first

        if state != .normal {
            // Searching or focusing ends with a reload.
            setState(.normal)
        }

        didReloadHierarchyInfo.send()
    }

    // MARK: - Rows

    @objc func numberOfRows() -> Int {
        displayingFlatItems?.count ?? 0
    }

    @objc(itemAtRow:)
    func item(atRow index: Int) -> DisplayItem? {
        guard let rows = displayingFlatItems, rows.indices.contains(index) else {
            return nil
        }
        return rows[index]
    }

    @objc(rowForItem:)
    func row(for item: DisplayItem?) -> Int {
        displayingFlatItems?.firstIndex { $0 === item } ?? NSNotFound
    }

    @objc(displayItemWithOid:)
    func displayItem(withOid oid: UInt) -> DisplayItem? {
        oidToDisplayItem[oid]
    }

    @objc func buildDisplayingFlatItems() {
        let showSystemLayoutGuides = PreferenceManager.shared.showSystemLayoutGuides.currentBOOLValue
        let rows = (flatItems ?? []).filter { item in
            guard item.displayingInHierarchy else {
                return false
            }
            // System-created layout guides can be hidden; user guides always
            // show, and the data keeps every node either way.
            if !showSystemLayoutGuides, item.representsSystemManagedNode, item.resolvedNodeKind() == .layoutGuide {
                return false
            }
            return true
        }
        setKVO("displayingFlatItems") { storedDisplayingFlatItems = rows }
    }

    /// Posts the KVO notifications of a read-only property around `write`.
    private func setKVO(_ key: String, _ write: () -> Void) {
        willChangeValue(forKey: key)
        write()
        didChangeValue(forKey: key)
    }

    private func setState(_ state: HierarchyDataSourceState) {
        setKVO("state") { storedState = state }
    }

    // MARK: - Selection

    private func selectedItemDidChange(from previousItem: DisplayItem?) {
        let item = selectedItem
        guard item !== previousItem else {
            return
        }

        previousItem?.notifySelectionChangeToDelegates()
        item?.notifySelectionChangeToDelegates()

        UserActionManager.sharedInstance().send(.selectedItemChange)

        if NSColorPanel.sharedColorPanelExists {
            NSColorPanel.shared.close()
        }

        // Clearing the selection ends measuring.
        let measureState = preferenceManager().measureState
        if item == nil, measureState.currentIntegerValue != MeasureState.no.rawValue {
            measureState.setIntegerValue(MeasureState.no.rawValue, ignoreSubscriber: nil)
        }
    }

    private func hoveredItemDidChange(from previousItem: DisplayItem?) {
        let item = hoveredItem
        guard item !== previousItem else {
            return
        }
        previousItem?.notifyHoverChangeToDelegates()
        item?.notifyHoverChangeToDelegates()
    }

    @objc(selectAndRevealItem:)
    func selectAndRevealItem(_ item: DisplayItem?) {
        guard let item else {
            return
        }
        if !containsInFlatItems(item) {
            switch state {
            case .search:
                endSearch()
            case .focus:
                endFocus()
            default:
                break
            }
        }
        guard containsInFlatItems(item) else {
            return
        }
        if !item.displayingInHierarchy {
            expand(toShow: item)
        }
        selectedItem = item
    }

    private func containsInFlatItems(_ item: DisplayItem) -> Bool {
        (flatItems ?? []).contains { $0 === item }
    }

    // MARK: - Expansion

    /// - Parameters:
    ///   - index: the expansion preset, 0 (collapse to the windows) to 4
    ///     (expand everything).
    ///   - referenceDict: expansion by path identifier; an item with an
    ///     entry keeps it instead of the preset.
    ///   - selectedItem: receives the item the preset suggests selecting.
    @objc(adjustExpansionByIndex:referenceDict:selectedItem:)
    func adjustExpansion(
        by index: Int,
        referenceDict: [String: NSNumber]?,
        selectedItem: AutoreleasingUnsafeMutablePointer<DisplayItem?>?
    ) {
        var index = index
        if index < 0 || index > 4 {
            assertionFailure("adjustExpansionByIndex, index is \(index)")
            index = max(min(index, 4), 0)
        }

        preferenceManager().expansionIndex = index

        let rootItems = rawHierarchyInfo?.displayItems ?? []
        let items = flatItems ?? []

        for item in items {
            item.hasDeterminedExpansion = false
            guard item.isExpandable else {
                item.hasDeterminedExpansion = true
                continue
            }
            if let referenceDict,
               let path = Self.pathIdentifier(for: item, inRootItems: rootItems),
               let previous = referenceDict[path]
            {
                // Known item: keep its state.
                item.isExpanded = previous.boolValue
                item.hasDeterminedExpansion = true
            }
        }

        func collapseUndetermined() {
            for item in items where !item.hasDeterminedExpansion {
                item.isExpanded = false
            }
        }

        switch index {
        case 0:
            // Collapse everything down to the top-level windows.
            var preferredSelection: DisplayItem?
            for item in items where !item.hasDeterminedExpansion {
                item.isExpanded = false
                if item.representedAsKeyWindow {
                    preferredSelection = item
                }
            }
            selectedItem?.pointee = preferredSelection

        case 4:
            // Expand everything, buttons, tab bars and navigation bars
            // included.
            for item in items where !item.hasDeterminedExpansion {
                item.isExpanded = !item.inNoPreviewHierarchy
            }
            if let selectedItem {
                var preferredSelection: DisplayItem?
                if let keyWindowRoot = rootItems.first(where: { $0.representedAsKeyWindow }) {
                    let windowItems = DisplayItem.flatItems(fromHierarchicalItems: [keyWindowRoot])
                    preferredSelection = windowItems.last {
                        $0.hostViewControllerObject != nil || $0.hostWindowControllerObject != nil
                    }
                }
                selectedItem.pointee = preferredSelection
            }

        default:
            guard let keyWindowItem = rootItems.first(where: { $0.representedAsKeyWindow }) ?? rootItems.first else {
                break
            }
            applyViewControllerPreset(
                index: index,
                keyWindowItem: keyWindowItem,
                rootItems: rootItems,
                selectedItem: selectedItem,
                collapseUndetermined: collapseUndetermined
            )
        }

        buildDisplayingFlatItems()
    }

    /// Presets 1 to 3, built around the key window's view controllers.
    private func applyViewControllerPreset(
        index: Int,
        keyWindowItem: DisplayItem,
        rootItems: [DisplayItem],
        selectedItem: AutoreleasingUnsafeMutablePointer<DisplayItem?>?,
        collapseUndetermined: () -> Void
    ) {
        // A scene container (window object only, no view or layer) holds the
        // real key window among its children; the UITransitionView search
        // runs on that one.
        var actualKeyWindow: DisplayItem? = keyWindowItem
        let keyWindowKind = keyWindowItem.resolvedNodeKind()
        if keyWindowKind == .window || keyWindowKind == .windowScene {
            let children = keyWindowItem.subitems ?? []
            actualKeyWindow = children.first { $0.representedAsKeyWindow } ?? children.first
        }

        // Collapse every other window, overriding the reference state, so a
        // scene that is not key never stays open.
        for windowItem in rootItems where windowItem !== keyWindowItem {
            for item in DisplayItem.flatItems(fromHierarchicalItems: [windowItem]) {
                item.isExpanded = false
                item.hasDeterminedExpansion = true
            }
        }

        // Open the last UITransitionView, collapse the ones before it.
        let transitionViews = (actualKeyWindow?.subitems ?? []).filter { $0.title() == "UITransitionView" }
        for (offset, item) in transitionViews.enumerated() where !item.hasDeterminedExpansion {
            item.isExpanded = offset == transitionViews.count - 1
            item.hasDeterminedExpansion = true
        }

        var viewControllerItems: [DisplayItem] = []
        // The Objective-C version tested the show-hidden-items preference
        // attribute object, not its value; the object is never nil, so
        // hidden subtrees are not folded here.
        let showHiddenItems = true
        for item in DisplayItem.flatItems(fromHierarchicalItems: [keyWindowItem]) {
            if item.hostViewControllerObject != nil || item.hostWindowControllerObject != nil {
                viewControllerItems.append(item)
                continue
            }
            if item.hasDeterminedExpansion {
                continue
            }
            if item.inNoPreviewHierarchy || item.preferToBeCollapsed || (!showHiddenItems && item.inHiddenHierarchy) {
                // Fold no-preview subtrees and the usual controls (UIButton
                // and the like).
                item.isExpanded = false
                item.hasDeterminedExpansion = true
                continue
            }
            if item.itemIsKindOfClasses(withNames: ["UINavigationBar", "UITabBar"]) {
                item.enumerateSelfAndChildren { node in
                    guard !node.hasDeterminedExpansion else {
                        return
                    }
                    node.isExpanded = false
                    node.hasDeterminedExpansion = true
                }
            }
        }

        selectedItem?.pointee = viewControllerItems.last

        switch index {
        case 1:
            // Show exactly the view controllers. Leaf first, so of several
            // controllers on one branch only the deepest is collapsed.
            for controllerItem in viewControllerItems.reversed() {
                controllerItem.enumerateSelfAndAncestors { item, _ in
                    guard !item.hasDeterminedExpansion else {
                        return
                    }
                    item.isExpanded = item !== controllerItem
                    item.hasDeterminedExpansion = true
                }
            }
            collapseUndetermined()

        case 2:
            // Open three levels below each view controller.
            for controllerItem in viewControllerItems.reversed() {
                controllerItem.enumerateAncestors { item, _ in
                    guard !item.hasDeterminedExpansion else {
                        return
                    }
                    item.isExpanded = true
                    item.hasDeterminedExpansion = true
                }
                // A typical table or collection view opens two levels, so
                // the cells show but not their content views.
                let firstChild = controllerItem.subitems?.first
                let hasTableOrCollectionView = firstChild?.itemIsKindOfClasses(withNames: ["UITableView", "UICollectionView"]) ?? false
                let levels = hasTableOrCollectionView ? 2 : 3
                let controllerLevel = controllerItem.indentLevel()
                controllerItem.enumerateSelfAndChildren { item in
                    guard !item.hasDeterminedExpansion else {
                        return
                    }
                    if item.indentLevel() < controllerLevel + levels {
                        item.isExpanded = true
                        item.hasDeterminedExpansion = true
                    }
                }
            }
            collapseUndetermined()

        case 3:
            // Open most of it.
            for item in flatItems ?? [] where !item.hasDeterminedExpansion {
                item.isExpanded = true
                item.hasDeterminedExpansion = true
            }

        default:
            break
        }
    }

    @objc(collapseItem:)
    func collapse(_ item: DisplayItem?) {
        guard let item, item.isExpandable, item.isExpanded else {
            return
        }
        item.isExpanded = false
        buildDisplayingFlatItems()
        persistExpansionStateToPreferences()
    }

    @objc(expandItem:)
    func expand(_ item: DisplayItem?) {
        guard let item, item.isExpandable, !item.isExpanded else {
            return
        }
        item.isExpanded = true
        buildDisplayingFlatItems()
        persistExpansionStateToPreferences()
    }

    @objc(expandToShowItem:)
    func expand(toShow item: DisplayItem?) {
        var didChange = false
        item?.enumerateAncestors { ancestor, _ in
            guard !ancestor.isExpanded else {
                return
            }
            ancestor.isExpanded = true
            didChange = true
        }
        buildDisplayingFlatItems()
        if didChange {
            persistExpansionStateToPreferences()
        }
    }

    @objc(expandItemsRootedByItem:)
    func expandItemsRooted(by item: DisplayItem?) {
        let includePreferredCollapsed = item?.preferToBeCollapsed ?? false
        item?.enumerateSelfAndChildren { node in
            guard node.isExpandable, !node.isExpanded else {
                return
            }
            if includePreferredCollapsed || !node.preferToBeCollapsed {
                node.isExpanded = true
            }
        }
        buildDisplayingFlatItems()
        persistExpansionStateToPreferences()
    }

    @objc(collapseAllChildrenOfItem:)
    func collapseAllChildren(of item: DisplayItem?) {
        item?.enumerateSelfAndChildren { node in
            guard node !== item, node.isExpandable, node.isExpanded else {
                return
            }
            node.isExpanded = false
        }
        buildDisplayingFlatItems()
        persistExpansionStateToPreferences()
    }

    // MARK: - Path identity

    /// "<rootIndex>/<class>:<siblingIndex>/..." from the root to `item`; nil
    /// when a node of the chain has no class (UserCustom-only nodes), when
    /// a sibling index cannot be resolved, or when `rootItems` is empty.
    @objc(pathIdentifierForItem:inRootItems:)
    class func pathIdentifier(for item: DisplayItem?, inRootItems rootItems: [DisplayItem]?) -> String? {
        guard let item else {
            return nil
        }
        return HierarchyPathIdentifier.make(
            for: item,
            rootItems: rootItems ?? [],
            parent: { $0.super },
            children: { $0.subitems ?? [] },
            // The leaf class in the view, layer, window order of `title`.
            className: { $0.displayingObject()?.classChainList?.first }
        )
    }

    /// Persists every expandable item's state, expanded and collapsed, for
    /// the target app's bundle identifier, so a cold reload restores the
    /// user's collapses too. Does nothing when remembering is off or there is
    /// no bundle identifier.
    @objc func persistExpansionStateToPreferences() {
        let preferences = preferenceManager()
        guard preferences.rememberExpansionState else {
            return
        }
        guard let bundleIdentifier = rawHierarchyInfo?.appInfo?.appBundleIdentifier, !bundleIdentifier.isEmpty else {
            return
        }
        preferences.setExpansionState(collectExpansionState(), forBundleIdentifier: bundleIdentifier)
    }

    private func collectExpansionState() -> [String: NSNumber] {
        let rootItems = rawHierarchyInfo?.displayItems ?? []
        guard !rootItems.isEmpty else {
            return [:]
        }
        var state: [String: NSNumber] = [:]
        for item in flatItems ?? [] where item.isExpandable {
            if let path = Self.pathIdentifier(for: item, inRootItems: rootItems) {
                state[path] = NSNumber(value: item.isExpanded)
            }
        }
        return state
    }

    // MARK: - Search and focus

    /// Call while the user types a non-empty search string; replaces
    /// `flatItems` and `displayingFlatItems`.
    @objc(searchWithString:)
    func search(with string: String?) {
        guard let string, !string.isEmpty else {
            assertionFailure("searching for an empty string")
            return
        }
        let items = rawFlatItems ?? []

        if state != .search {
            recordExpansionBeforeSearchOrFocus(items)
            setState(.search)
        }

        selectedItem = nil

        for item in items {
            item.highlightedSearchString = nil
        }
        let shown = HierarchySearchVisibility.apply(
            flatItems: items,
            matches: { $0.isMatched(withSearch: string) },
            ancestors: ancestors(of:),
            selfAndDescendants: selfAndDescendants(of:),
            setExpanded: { $0.isExpanded = $1 },
            didMatch: { $0.highlightedSearchString = string }
        )
        for item in shown {
            item.isInSearch = true
        }
        flatItems = shown
        didReloadFlatItemsWithSearchOrFocus.send()

        buildDisplayingFlatItems()
    }

    /// Call when the search field is closed; restores the expansion from
    /// before the search and keeps the selection visible.
    @objc func endSearch() {
        guard state != .normal else {
            return
        }
        setState(.normal)

        for item in rawFlatItems ?? [] {
            item.isInSearch = false
            item.highlightedSearchString = nil
            item.isExpanded = item.getBindBool(forKey: expandedBeforeSearchOrFocusKey)
        }
        // The item selected while searching stays selected and visible.
        selectedItem?.enumerateAncestors { item, _ in
            item.isExpanded = true
        }

        flatItems = rawFlatItems
        didReloadFlatItemsWithSearchOrFocus.send()

        buildDisplayingFlatItems()
    }

    /// Entered from the normal or the search state.
    @objc(focusDisplayItem:)
    func focus(_ item: DisplayItem?) {
        guard let item else {
            assertionFailure("focusing nil")
            return
        }
        switch state {
        case .normal:
            recordExpansionBeforeSearchOrFocus(rawFlatItems ?? [])
        case .search:
            for item in rawFlatItems ?? [] {
                item.isInSearch = false
                item.highlightedSearchString = nil
            }
        default:
            break
        }
        setState(.focus)

        flatItems = selfAndDescendants(of: item)
        didReloadFlatItemsWithSearchOrFocus.send()
        buildDisplayingFlatItems()
    }

    @objc func endFocus() {
        guard state != .normal else {
            return
        }
        setState(.normal)

        for item in rawFlatItems ?? [] {
            item.isExpanded = item.getBindBool(forKey: expandedBeforeSearchOrFocusKey)
        }

        flatItems = rawFlatItems
        didReloadFlatItemsWithSearchOrFocus.send()
        buildDisplayingFlatItems()
    }

    private func recordExpansionBeforeSearchOrFocus(_ items: [DisplayItem]) {
        for item in items {
            item.bindBool(item.isExpanded, forKey: expandedBeforeSearchOrFocusKey)
        }
    }

    // MARK: - SwiftUI jumps

    /// SwiftUI node -> its matched CALayer nodes; empty when there is none.
    @objc(swiftUIBackingLayerItemsForItem:)
    func swiftUIBackingLayerItems(for item: DisplayItem?) -> [DisplayItem]? {
        guard let item else {
            return []
        }
        var result: [DisplayItem] = []
        func add(_ candidate: DisplayItem?) {
            if let candidate, !result.contains(where: { $0 === candidate }) {
                result.append(candidate)
            }
        }
        for address in item.swiftUIBackingLayerMemoryAddresses() {
            add(layerItem(withMemoryAddress: address))
        }
        for displayListID in item.swiftUIBackingDisplayListIDs() {
            add(layerItem(withDisplayListID: displayListID))
        }
        return result
    }

    /// CALayer node -> its SwiftUI node, or nil.
    @objc(swiftUISourceItemForLayerItem:)
    func swiftUISourceItem(forLayerItem item: DisplayItem?) -> DisplayItem? {
        guard let item, let displayListID = item.swiftUILayerDisplayListID() else {
            return nil
        }
        return swiftUIItem(withDisplayListID: displayListID) ?? swiftUIItemForLayerItemByFrameAndSource(item)
    }

    /// Dashboard row -> its SwiftUI / CALayer jump target, or nil when the
    /// row has none.
    @objc(swiftUIJumpTargetForAttribute:)
    func swiftUIJumpTarget(for attribute: InspectedAttribute?) -> DisplayItem? {
        guard let attribute, let sourceItem = attribute.targetDisplayItem, let value = attribute.value as? String else {
            return nil
        }
        let title = attribute.displayTitle ?? ""
        let sourceIsSwiftUI = sourceItem.customInfo?.isSwiftUI == true
            || !sourceItem.swiftUIBackingDisplayListIDs().isEmpty
            || !sourceItem.swiftUIBackingLayerMemoryAddresses().isEmpty

        if sourceIsSwiftUI {
            if title.hasSuffix("Backed By") {
                return layerItem(withMemoryAddress: DisplayItem.memoryAddress(inObjectDescription: value))
            }
            if title.hasSuffix("Display List ID") || title == "Identity IDs" {
                for displayListID in DisplayItem.validSwiftUIDisplayListIDs(in: value) {
                    if let target = layerItem(withDisplayListID: displayListID) {
                        return target
                    }
                }
                let layerItems = swiftUIBackingLayerItems(for: sourceItem) ?? []
                if let ordinal = swiftUILayerOrdinal(fromAttributeTitle: title), layerItems.indices.contains(ordinal) {
                    return layerItems[ordinal]
                }
            }
            return nil
        }

        if sourceItem.layerObject != nil, title == "Display List ID" {
            let displayListID = DisplayItem.validSwiftUIDisplayListIDs(in: value).first
                ?? sourceItem.swiftUILayerDisplayListID()
            return swiftUIItem(withDisplayListID: displayListID) ?? swiftUIItemForLayerItemByFrameAndSource(sourceItem)
        }
        return nil
    }

    private func layerItem(withMemoryAddress memoryAddress: String?) -> DisplayItem? {
        guard let memoryAddress, !memoryAddress.isEmpty else {
            return nil
        }
        let normalized = memoryAddress.lowercased()
        return (rawFlatItems ?? []).first { $0.layerObject?.memoryAddress?.lowercased() == normalized }
    }

    private func layerItem(withDisplayListID displayListID: NSNumber?) -> DisplayItem? {
        guard let displayListID else {
            return nil
        }
        return (rawFlatItems ?? []).first { item in
            item.layerObject != nil && item.swiftUILayerDisplayListID()?.isEqual(to: displayListID) == true
        }
    }

    /// The deepest SwiftUI node backed by `displayListID`.
    private func swiftUIItem(withDisplayListID displayListID: NSNumber?) -> DisplayItem? {
        guard let displayListID else {
            return nil
        }
        var result: DisplayItem?
        for item in rawFlatItems ?? [] where item.swiftUIBackingDisplayListIDs().contains(displayListID) {
            if result == nil || item.indentLevel() > result!.indentLevel() {
                result = item
            }
        }
        return result
    }

    /// The deepest SwiftUI node with the layer's frame and source type.
    private func swiftUIItemForLayerItemByFrameAndSource(_ layerItem: DisplayItem) -> DisplayItem? {
        guard layerItem.layerObject != nil else {
            return nil
        }
        let layerFrame = layerItem.calculateFrameToRoot()
        let sourceTypes = layerItem.swiftUILayerSourceTypeNames()
        var result: DisplayItem?
        for item in rawFlatItems ?? [] {
            guard item.customInfo?.isSwiftUI == true, item.hasValidFrameToRoot() else {
                continue
            }
            guard swiftUINode(item, matchesSourceTypes: sourceTypes),
                  rectsAlmostEqual(layerFrame, item.calculateFrameToRoot())
            else {
                continue
            }
            if result == nil || item.indentLevel() > result!.indentLevel() {
                result = item
            }
        }
        return result
    }

    // MARK: - Colors

    /// The hierarchy's alias names of `color`, or nil.
    @objc(aliasForColor:)
    func alias(for color: NSColor?) -> [String]? {
        guard let color else {
            return nil
        }
        return colorToAliasMap[color.rgbaString()]
    }

    private func setUpColors() {
        let catalog = ColorAliasCatalog<NSColor>(aliases: colorAliasEntries(), colorKey: { $0.rgbaString() })
        colorToAliasMap = catalog.aliasesByColorKey
        storedSelectColorMenu = makeColorMenu(aliasEntries: catalog.entries, usingRGBAFormat: PreferenceManager.shared.rgbaFormat)
    }

    /// `colorAlias` maps an alias to a color, or a group title to a
    /// dictionary of aliases and colors. Read as the Objective-C dictionary
    /// so its entries keep their enumeration order.
    private func colorAliasEntries() -> [(key: String, value: ColorAliasCatalog<NSColor>.Value)] {
        guard let colorAlias = rawHierarchyInfo?.value(forKey: "colorAlias") as? NSDictionary else {
            return []
        }
        var entries: [(key: String, value: ColorAliasCatalog<NSColor>.Value)] = []
        colorAlias.enumerateKeysAndObjects { key, value, _ in
            guard let key = key as? String else {
                return
            }
            if let color = value as? NSColor {
                entries.append((key, .color(color)))
            } else if let group = value as? NSDictionary {
                var members: [(alias: String, color: NSColor)] = []
                group.enumerateKeysAndObjects { alias, color, _ in
                    if let alias = alias as? String, let color = color as? NSColor {
                        members.append((alias, color))
                    }
                }
                entries.append((key, .group(members)))
            } else {
                assertionFailure("unsupported color alias value")
                entries.append((key, .unsupported))
            }
        }
        return entries
    }

    private func makeColorMenu(aliasEntries: [ColorAliasCatalog<NSColor>.Entry], usingRGBAFormat rgbaFormat: Bool) -> NSMenu {
        let defaultColors = [
            color(0, 0, 0),
            color(126, 126, 126),
            color(255, 255, 255),
            color(0, 166, 248, 0.5),
            color(253, 62, 0),
            color(105, 190, 0),
            color(254, 182, 2),
        ]
        var defaultItems: [(title: String, color: NSColor?)] = [
            ("nil", nil),
            ("clear color", color(0, 0, 0, 0)),
        ]
        defaultItems += defaultColors.map { (rgbaFormat ? $0.rgbaString() : $0.hexString(), $0) }

        let menu = NSMenu()
        for item in defaultItems {
            menu.addItem(colorMenuItem(title: item.title, color: item.color))
        }
        if !aliasEntries.isEmpty {
            menu.addItem(.separator())
        }
        for entry in aliasEntries {
            switch entry {
            case let .color(title, color):
                menu.addItem(colorMenuItem(title: title, color: color))
            case let .section(title, items):
                let sectionItem = NSMenuItem()
                sectionItem.image = NSImage(size: NSSize(width: 1, height: 22))
                menu.addItem(sectionItem)
                sectionItem.title = title
                let submenu = NSMenu()
                for item in items {
                    submenu.addItem(colorMenuItem(title: item.title, color: item.color))
                }
                sectionItem.submenu = submenu
            }
        }

        menu.addItem(.separator())
        let otherItem = NSMenuItem()
        otherItem.image = NSImage(size: NSSize(width: 1, height: 22))
        otherItem.title = NSLocalizedString("Other…", comment: "")
        otherItem.tag = customColorMenuItemTag
        menu.addItem(otherItem)

        menu.addItem(.separator())
        let formatItem = NSMenuItem()
        formatItem.image = NSImage(size: NSSize(width: 1, height: 22))
        formatItem.title = rgbaFormat
            ? NSLocalizedString("Switch color format to HEX", comment: "")
            : NSLocalizedString("Switch color format to RGBA", comment: "")
        formatItem.tag = toggleColorFormatMenuItemTag
        menu.addItem(formatItem)

        return menu
    }

    private func colorMenuItem(title: String, color: NSColor?) -> NSMenuItem {
        let item = NSMenuItem()
        item.image = ColorIndicatorLayer.image(with: color, shapeSize: NSSize(width: 20, height: 20), insets: NSEdgeInsets(top: 4, left: 5, bottom: 4, right: 6))
        item.title = title
        item.representedObject = color
        return item
    }

    // MARK: - Others

    /// Subclasses return their preference manager.
    @objc func preferenceManager() -> PreferenceManager {
        assertionFailure("should implement by subclass")
        return PreferenceManager.shared
    }

    /// YES in read-only mode, such as an opened file.
    @objc func isReadOnly() -> Bool {
        true
    }

    private func rebuildOidMap() {
        var map: [UInt: DisplayItem] = [:]
        map.reserveCapacity((storedRawFlatItems?.count ?? 0) * 2)
        for item in storedRawFlatItems ?? [] {
            for object in [item.viewObject, item.layerObject, item.windowObject, item.kindObject] {
                if let oid = object?.oid, oid != 0 {
                    map[UInt(oid)] = item
                }
            }
        }
        oidToDisplayItem = map
    }

    @objc private func handleShowSystemLayoutGuidesDidChange(_: MessageActionParameters?) {
        buildDisplayingFlatItems()
    }

    private func forwardSignalsToEvents() {
        let broadcaster = eventBroadcaster
        func forward<Value>(_ signal: SyncSignal<Value>, _ event: @escaping (Value) -> HierarchyDataSourceEvent) {
            signalSubscriptions.append(signal.observe { [weak broadcaster] value in
                broadcaster?.yield(event(value))
            })
        }
        forward(willReloadHierarchyInfo) { .willReloadHierarchyInfo }
        forward(didReloadHierarchyInfo) { .didReloadHierarchyInfo }
        forward(didReloadFlatItemsWithSearchOrFocus) { .didReloadFlatItemsWithSearchOrFocus }
        forward(itemDidChangeNoPreview) { .itemDidChangeNoPreview }
        forward(itemDidChangeHiddenAlphaValue) { .itemDidChangeHiddenAlphaValue($0) }
        forward(itemDidChangeAttrGroup) { .itemDidChangeAttrGroup($0) }
    }
}

extension HierarchyDataSource {
    /// The data source's events from now on; see `HierarchyDataSourceEvent`.
    /// Ends when the data source is released.
    func events() -> AsyncStream<HierarchyDataSourceEvent> {
        eventBroadcaster.subscribe()
    }
}
