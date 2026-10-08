//
//  DashboardViewController.swift
//  LookInside
//
//  Created by Li Kai on 2018/8/6.
//  https://lookin.work
//

import AppKit

/// The attribute panel on the right of the inspector: one card per
/// attribute group of the selected item, and a search over attributes and
/// methods. Edits are sent to the inspected app on a live document; a
/// document read from a file is read-only.
@objc(LKDashboardViewController)
final class DashboardViewController: BaseViewController, DashboardCardViewDelegate, DashboardHeaderViewDelegate, DashboardSearchPropertyViewDelegate, DashboardSearchMethodsViewDelegate {
    /// Read by key by the DEBUG UI snapshots.
    @objc private(set) var scrollView: NSScrollView!
    private var documentView: BaseView!
    private var cardContainerView: BaseView!
    private var searchContainerView: BaseView!
    private var headerView: DashboardHeaderView!

    private var groupList: [AttributesGroup] = []
    /// Keyed by `AttributesGroup.uniqueKey`.
    private var cardViews: [String: DashboardCardView] = [:]

    private var searchPropViews: [DashboardSearchPropertyView] = []
    private var searchMethodsView: DashboardSearchMethodsView?
    private var methodsDataSource: DashboardSearchMethodsDataSource?

    private let staticDataSource: StaticHierarchyDataSource?
    private let readDataSource: ReadHierarchyDataSource?

    private var selectedItemObservation: NSKeyValueObservation?
    private var sectionShowingObserver: NSObjectProtocol?
    private var dataSourceSubscriptions: [SyncSubscription] = []

    /// Whether this dashboard shows a live document (rather than one read
    /// from a file).
    @objc let isStaticMode: Bool

    /// The update manager of the owning inspector, which patches the
    /// preview after modifications that need it.
    @objc weak var asyncUpdateManager: StaticAsyncUpdateManager?

    /// The live document that owns this dashboard; its inspectable app
    /// receives attribute modifications and method invocations. Nil on a
    /// document read from a file.
    @objc weak var liveDocument: LiveDocument? {
        didSet { methodsDataSource?.liveDocument = liveDocument }
    }

    @objc(initWithStaticDataSource:)
    init(staticDataSource dataSource: StaticHierarchyDataSource) {
        staticDataSource = dataSource
        readDataSource = nil
        isStaticMode = true
        super.init(containerView: nil)
        didInitialize()
    }

    @objc(initWithReadDataSource:)
    init(readDataSource dataSource: ReadHierarchyDataSource) {
        staticDataSource = nil
        readDataSource = dataSource
        isStaticMode = false
        super.init(containerView: nil)
        didInitialize()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        if let sectionShowingObserver {
            NotificationCenter.default.removeObserver(sectionShowingObserver)
        }
        dataSourceSubscriptions.forEach { $0.cancel() }
    }

    override func makeContainerView() -> NSView {
        let containerView = BaseView()

        documentView = BaseView()

        scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.contentView.documentView = documentView
        containerView.addSubview(scrollView)

        headerView = DashboardHeaderView()
        headerView.delegate = self
        documentView.addSubview(headerView)

        cardContainerView = BaseView()
        documentView.addSubview(cardContainerView)

        searchContainerView = BaseView()
        searchContainerView.isHidden = true
        documentView.addSubview(searchContainerView)

        return containerView
    }

    private func didInitialize() {
        if let staticDataSource {
            observeSelectedItem(of: staticDataSource)

            // Reloads on a later main-queue turn, after the sender is done.
            dataSourceSubscriptions.append(staticDataSource.itemDidChangeAttrGroup.observe { [weak self] item in
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        guard let self, self.staticDataSource?.selectedItem === item else { return }
                        self.reload(groupList: self.groupList(for: item))
                    }
                }
            })

            let methodsDataSource = DashboardSearchMethodsDataSource()
            methodsDataSource.liveDocument = liveDocument
            self.methodsDataSource = methodsDataSource
            dataSourceSubscriptions.append(staticDataSource.didReloadHierarchyInfo.observe { [weak self] in
                self?.methodsDataSource?.clearAllCache()
            })
        } else if let readDataSource {
            observeSelectedItem(of: readDataSource)
        }

        sectionShowingObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(NotificationName_DidChangeSectionShowing), object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.reloadCurrentDisplayItem()
            }
        }
    }

    /// Renders the selected item now and whenever the selection changes,
    /// each time on a later turn of the main queue.
    private func observeSelectedItem(of dataSource: HierarchyDataSource) {
        selectedItemObservation = dataSource.observe(\.selectedItem, options: [.initial, .new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.reload(groupList: self.groupList(for: self.currentDataSource()?.selectedItem))
            }
        }
    }

    // MARK: - Layout

    override func viewDidLayout() {
        super.viewDidLayout()

        scrollView.dashboardLayout.fullFrame()

        let verMargin: CGFloat = 10
        let horInset = DashboardMetrics.horInset
        let contentWidth = DashboardMetrics.viewWidth - horInset * 2

        headerView.dashboardLayout.width(contentWidth).x(horInset).height(23).y(10)

        if !cardContainerView.isHidden {
            cardContainerView.dashboardLayout.width(contentWidth).x(horInset).y(headerView.frame.maxY + verMargin)
            var y: CGFloat = 0
            for group in groupList {
                guard let view = cardViews[group.uniqueKey() ?? ""], !view.isHidden else { continue }
                view.dashboardLayout.width(contentWidth).y(y).heightToFit()
                y = view.frame.maxY + verMargin
            }
            cardContainerView.dashboardLayout.height(y)
            documentView.dashboardLayout.fullWidth().y(0).toMaxY(cardContainerView.frame.maxY)
        }

        if !searchContainerView.isHidden {
            searchContainerView.dashboardLayout.width(contentWidth).x(horInset).y(headerView.frame.maxY + verMargin)
            var y: CGFloat = 0
            for view in searchPropViews where !view.isHidden {
                view.dashboardLayout.width(contentWidth).x(0).heightToFit().y(y)
                y = view.frame.maxY + verMargin
            }
            if let searchMethodsView, searchMethodsView.isVisible {
                searchMethodsView.dashboardLayout.width(contentWidth).y(y).heightToFit()
                y = searchMethodsView.frame.maxY
            }
            searchContainerView.dashboardLayout.height(y)
            documentView.dashboardLayout.fullWidth().y(0).toMaxY(searchContainerView.frame.maxY)
        }
    }

    // MARK: - Rendering

    private func groupList(for item: DisplayItem?) -> [AttributesGroup] {
        guard let item else { return [] }
        let groups = PrivateDiscriminatorStore.shared.appendingPrivateDiscriminatorGroup(to: item.queryAllAttrGroupList(), for: item)
        // Cards are keyed by uniqueKey, so a duplicated key would lay the
        // shared card out twice and leave a blank gap. Servers 0.2.8 and
        // 0.2.9 sent a duplicate Layout group for UIWindowScene nodes.
        return AttributesGroup.groupsByKeepingFirstGroup(forEachUniqueKey: groups)
    }

    private func reload(groupList list: [AttributesGroup]) {
        groupList = list

        if list.isEmpty {
            scrollView.isHidden = true
            return
        }
        scrollView.isHidden = false

        var needlessViews = Array(cardViews.values)
        for group in list {
            let key = group.uniqueKey() ?? ""
            let cardView: DashboardCardView
            if let existing = cardViews[key] {
                cardView = existing
                needlessViews.removeAll { $0 === existing }
            } else {
                cardView = DashboardCardView()
                cardView.dashboardViewController = self
                cardView.delegate = self
                cardViews[key] = cardView
                cardContainerView.addSubview(cardView)
            }
            cardView.isHidden = false
            cardView.attrGroup = group
            cardView.isCollapsed = PreferenceManager.shared.collapsedAttrGroups.contains(group.identifier ?? "")
            cardView.render()
        }
        needlessViews.forEach { $0.isHidden = true }

        view.needsLayout = true
    }

    @objc func reloadCurrentDisplayItem() {
        reload(groupList: groupList(for: currentDataSource()?.selectedItem))
    }

    @objc func currentDataSource() -> HierarchyDataSource? {
        if let staticDataSource {
            return staticDataSource
        }
        if let readDataSource {
            return readDataSource
        }
        assertionFailure()
        return nil
    }

    // MARK: - Modification

    /// Sends `newValue` for `attribute` to the inspected app. Returns
    /// whether a modification was made: a user-custom attribute without a
    /// setter (such as the SwiftUI attributes) is left alone. Failures are
    /// shown in the window, then thrown.
    func modifyAttribute(_ attribute: InspectedAttribute, newValue: Any?) async throws -> Bool {
        if attribute.isUserCustom() {
            // The attribute views already refuse edits of read-only
            // attributes; this keeps any other caller from sending one.
            guard let setterID = attribute.customSetterID, !setterID.isEmpty else {
                return false
            }
            try await modifyCustomAttribute(attribute, newValue: newValue)
        } else {
            try await modifyInbuiltAttribute(attribute, newValue: newValue)
        }
        return true
    }

    private func failModification(_ error: Error) -> Error {
        DashboardStyle.alert(error, window: view.window)
        return error
    }

    private func modifyCustomAttribute(_ attribute: InspectedAttribute, newValue: Any?) async throws {
        guard let modification = DashboardModification.custom(attribute: attribute, newValue: newValue) else {
            assertionFailure()
            throw failModification(ConnectionError.inner)
        }
        // The live document's inspectable app applies the modification.
        guard let inspectableApp = liveDocument?.inspectableApp else {
            throw failModification(ConnectionError.noConnect)
        }
        do {
            _ = try await inspectableApp.submit(modification)
        } catch {
            throw failModification(error)
        }
        NSLog("custom modification - succ")
        attribute.value = newValue
    }

    private func modifyInbuiltAttribute(_ attribute: InspectedAttribute, newValue: Any?) async throws {
        let modifyingItem = attribute.targetDisplayItem
        guard let modification = DashboardModification.inbuilt(attribute: attribute, newValue: newValue, clientReadableVersion: AppHelper.lookinReadableVersion()) else {
            assertionFailure()
            throw failModification(ConnectionError.inner)
        }
        // The live document's inspectable app applies the modification.
        guard let inspectableApp = liveDocument?.inspectableApp else {
            throw failModification(ConnectionError.noConnect)
        }
        let detail: DisplayItemDetail
        do {
            detail = try await inspectableApp.submit(modification)
        } catch {
            throw failModification(error)
        }
        NSLog("modification - succ")
        guard let staticDataSource else {
            assertionFailure()
            return
        }
        // Pressing Return ends editing, which submits; applying the result
        // reloads the cards, which removes the field and ends editing again.
        // The flag keeps that second end-of-editing from submitting (and
        // syncing the image) a second time.
        DashboardTextControlEditingFlag.shared.shouldIgnoreTextEditingChangeEvent = true
        staticDataSource.modify(with: detail)
        DashboardTextControlEditingFlag.shared.shouldIgnoreTextEditingChangeEvent = false

        if DashboardBlueprint.needPatchAfterModification(withAttrID: attribute.identifier), let modifyingItem {
            _ = asyncUpdateManager?.perform(Selector(("updateAfterModifyingDisplayItem:")), with: modifyingItem)
        }
    }

    // MARK: - DashboardCardViewDelegate

    func dashboardCardViewNeedToggleCollapse(_ view: DashboardCardView) {
        guard let manager = currentDataSource()?.preferenceManager(), let identifier = view.attrGroup?.identifier else { return }
        let collapsed = manager.collapsedAttrGroups
        if collapsed.contains(identifier) {
            view.isCollapsed = false
            manager.collapsedAttrGroups = collapsed.filter { $0 != identifier }
        } else {
            view.isCollapsed = true
            manager.collapsedAttrGroups = collapsed + [identifier]
        }
        self.view.needsLayout = true
    }

    // MARK: - DashboardHeaderViewDelegate

    func dashboardHeaderView(_: DashboardHeaderView, didInputString string: String) {
        guard string.count >= 3 else {
            searchContainerView.isHidden = true
            return
        }
        let searchString = string.lowercased()

        // Attributes
        var resultAttrs: [InspectedAttribute] = []
        for group in groupList(for: currentDataSource()?.selectedItem) {
            for section in group.attrSections ?? [] {
                for attr in section.attributes ?? [] {
                    let title = attr.isUserCustom() ? attr.displayTitle : DashboardBlueprint.fullTitle(withAttrID: attr.identifier)
                    if (title ?? "").lowercased().contains(searchString) {
                        resultAttrs.append(attr)
                    }
                }
            }
        }

        while searchPropViews.count < resultAttrs.count {
            let propView = DashboardSearchPropertyView()
            propView.delegate = self
            searchContainerView.addSubview(propView)
            searchPropViews.append(propView)
        }
        for (idx, propView) in searchPropViews.enumerated() {
            if idx < resultAttrs.count {
                propView.render(attribute: resultAttrs[idx])
                propView.isHidden = false
            } else {
                propView.isHidden = true
            }
        }

        // Methods, on a live document only
        guard let staticDataSource, currentDataSource() === staticDataSource, let methodsDataSource else {
            searchContainerView.isHidden = false
            searchMethodsView?.isHidden = true
            view.needsLayout = true
            return
        }

        let methodsView: DashboardSearchMethodsView
        if let searchMethodsView {
            methodsView = searchMethodsView
        } else {
            methodsView = DashboardSearchMethodsView()
            methodsView.delegate = self
            searchContainerView.addSubview(methodsView)
            searchMethodsView = methodsView
        }

        let selectedObject = staticDataSource.selectedItem?.displayingObject()
        let selectedClassName = selectedObject?.rawClassName()
        Task { @MainActor [weak self] in
            do {
                let methodsList = try await methodsDataSource.nonArgMethods(ofClass: selectedClassName)
                guard let self, searchString == self.headerView.currentInputString else { return }
                let searchedMethods = AppHelper.bestMatches(inCandidates: methodsList, input: searchString, maxResultsCount: 5)
                methodsView.render(methods: searchedMethods, oid: selectedObject?.oid ?? 0)
                self.searchContainerView.isHidden = false
                self.view.needsLayout = true
            } catch {
                guard let self, searchString == self.headerView.currentInputString else { return }
                methodsView.render(error: error)
                self.searchContainerView.isHidden = false
                self.view.needsLayout = true
            }
        }
    }

    func dashboardHeaderView(_ view: DashboardHeaderView, didToggleActive isActive: Bool) {
        if isActive {
            cardContainerView.animator().isHidden = true
            currentDataSource()?.shouldAvoidChangingPreviewSelectionDueToDashboardSearch = true
        } else {
            cardContainerView.animator().isHidden = false
            searchContainerView.animator().isHidden = true
            self.view.needsLayout = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                // Ending the search by clicking the preview first resigns
                // here, then (about 0.1 s later) deselects the layer in the
                // preview. The user did not mean to deselect, so the flag
                // stays on a little longer.
                if !view.isActive {
                    self?.currentDataSource()?.shouldAvoidChangingPreviewSelectionDueToDashboardSearch = false
                }
            }
        }
    }

    // MARK: - DashboardSearchMethodsViewDelegate

    func dashboardSearchMethodsView(_: DashboardSearchMethodsView, requestToInvokeMethod method: String, oid: UInt) {
        // The live document's inspectable app invokes the method.
        let inspectableApp = liveDocument?.inspectableApp
        Task { @MainActor [weak self] in
            do {
                guard oid != 0, !method.isEmpty else { throw ConnectionError.inner }
                guard let inspectableApp else { throw ConnectionError.noConnect }
                let value = try await inspectableApp.invokeMethod(oid: oid, text: method)
                let alert = NSAlert()
                alert.messageText = method
                alert.informativeText = value["description"] as? String ?? ""
                alert.alertStyle = .informational
                if let window = self?.view.window {
                    alert.beginSheetModal(for: window, completionHandler: nil)
                } else {
                    alert.runModal()
                }
            } catch {
                DashboardStyle.alert(error, window: self?.view.window)
            }
        }
    }

    // MARK: - DashboardSearchPropertyViewDelegate

    func dashboardSearchPropView(_: DashboardSearchPropertyView, didClickRevealAttribute clickedAttribute: InspectedAttribute) {
        headerView.isActive = false

        var target: (group: AttributesGroup, section: AttributesSection)?
        search: for group in groupList(for: currentDataSource()?.selectedItem) {
            for section in group.attrSections ?? [] where (section.attributes ?? []).contains(where: { $0 === clickedAttribute }) {
                if let identifier = section.identifier, !PreferenceManager.shared.isSectionShowing(identifier) {
                    // Adds the section to its card.
                    PreferenceManager.shared.showSection(identifier)
                }
                target = (group, section)
                break search
            }
        }

        guard let target, let targetCardView = cardViews[target.group.uniqueKey() ?? ""] else {
            assertionFailure()
            return
        }
        if targetCardView.isCollapsed {
            dashboardCardViewNeedToggleCollapse(targetCardView)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self, let targetSectionView = targetCardView.querySectionView(with: target.section) else { return }
            let sectionRect = self.scrollView.contentView.convert(targetSectionView.frame, from: targetSectionView.superview)
            self.scrollView.contentView.animator().scrollToVisible(sectionRect)

            for cardView in self.cardViews.values where !cardView.isHidden {
                if cardView === targetCardView {
                    cardView.playFadeAnimation(highlightRect: cardView.convert(targetSectionView.frame, from: targetSectionView.superview))
                } else {
                    cardView.playFadeAnimation(highlightRect: .zero)
                }
            }
        }
    }
}
