//
//  SelectedNodeAttributesTests.swift
//  LookInsideAppTests
//
//  A refresh asks the inspected app for the blueprint attribute groups of
//  the selected node alone: the displayed rows get their extension and
//  custom groups, a newly selected node its full groups at once, and the
//  whole-tree fetch before a file is written every node's
//  (selected-node-attributes-plan.md). Driven through a FakeServer that
//  answers 203 as a Server of either age would.
//

import AppKit
@testable import LookInside
import Testing

extension HostAppTests {
    @MainActor
    struct SelectedNodeAttributesTests {
        private static func layerItem(oid: UInt, subitems: [DisplayItem] = []) -> DisplayItem {
            let layerObject = InspectedObject()
            layerObject.oid = oid
            layerObject.classChainList = ["CALayer", "NSObject"]
            let item = DisplayItem()
            item.nodeKind = .layer
            item.layerObject = layerObject
            item.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            item.bounds = item.frame
            item.alpha = 1
            item.subitems = subitems
            return item
        }

        private static func group(_ identifier: AttributesGroup.Identifier) -> AttributesGroup {
            let group = AttributesGroup()
            group.identifier = identifier
            group.attrSections = []
            return group
        }

        /// Answers each 203 task as a Server does: a task asking for the
        /// extension and custom groups gets an extension group, one asking
        /// for every group gets a Class group too. An older Server does not
        /// know `omitsBlueprintAttributes` and sends every group.
        private static func answeringDetails(on server: FakeServer, knowsOmittingBlueprint: Bool) {
            server.responders[UInt32(RequestType.hierarchyDetails)] = { data in
                let packages = data as? [StaticAsyncUpdateTasksPackage] ?? []
                return packages.flatMap { $0.tasks ?? [] }.map { task in
                    let detail = DisplayItemDetail()
                    detail.displayItemOid = task.oid
                    if task.attrRequest == .need {
                        let omits = knowsOmittingBlueprint && task.omitsBlueprintAttributes
                        detail.attributesGroupList = omits ? [group("ExtensionGroup")] : [group(AttributesGroup.Identifier.class), group("ExtensionGroup")]
                    }
                    return detail
                } as NSArray
            }
        }

        /// Every 203 task the Server received, in order.
        private static func detailTasks(in server: FakeServer) -> [StaticAsyncUpdateTask] {
            server.receivedRequests
                .filter { $0.type == UInt32(RequestType.hierarchyDetails) }
                .flatMap { request in (request.data as? [StaticAsyncUpdateTasksPackage] ?? []).flatMap { $0.tasks ?? [] } }
        }

        /// What a test holds for the length of a session.
        private struct Session {
            let channel: ServerChannel
            let app: InspectableApp
            let dataSource: StaticHierarchyDataSource
            let manager: StaticAsyncUpdateManager
            let items: [DisplayItem]
        }

        /// A root with three children, loaded, expanded and its displayed
        /// rows fetched. A reload selects the root.
        private static func loadedSession(on server: FakeServer) async -> Session {
            let children = [layerItem(oid: 2), layerItem(oid: 3), layerItem(oid: 4)]
            let root = layerItem(oid: 1, subitems: children)
            let info = HierarchyInfo()
            server.appInfo.screenScale = 2
            info.appInfo = server.appInfo
            info.displayItems = [root]
            let channel = server.connectChannel()
            let app = InspectableApp()
            app.appInfo = info.appInfo
            app.channel = channel
            // A preference set of its own: expanding the root must not store the
            // fake app's expansion state in the app's settings.
            let dataSource = StaticHierarchyDataSource(preferenceManager: PreferenceManager())
            let manager = StaticAsyncUpdateManager(hierarchyDataSource: dataSource, inspectableApp: nil)
            manager.inspectableApp = app
            dataSource.reload(with: info, keepState: false)
            dataSource.expand(root)
            manager.updateForDisplayingItems()
            let displayed = dataSource.displayingFlatItems ?? []
            _ = await waitUntil { !displayed.isEmpty && displayed.allSatisfy { $0.attributesGroupList != nil } && !manager.isUpdating() && !manager.isPrefetching() }
            return Session(channel: channel, app: app, dataSource: dataSource, manager: manager, items: [root] + children)
        }

        @Test func displayedRowsGetExtensionGroupsAndASelectedNodeItsFullGroupsAtOnce() async throws {
            let server = FakeServer()
            Self.answeringDetails(on: server, knowsOmittingBlueprint: true)
            let session = await Self.loadedSession(on: server)
            let root = session.items[0]
            #expect(session.dataSource.selectedItem === root)
            let displayed = try #require(session.dataSource.displayingFlatItems)
            #expect(displayed.count == 4)
            let rows = displayed.filter { $0 !== root }

            // The selected root gets every group, the other rows the
            // extension and custom groups.
            let refreshTasks = Self.detailTasks(in: server).filter { $0.attrRequest == .need }
            #expect(refreshTasks.first?.oid == 1)
            #expect(refreshTasks.filter { !$0.omitsBlueprintAttributes }.map(\.oid) == [1])
            #expect(Set(refreshTasks.filter { $0.omitsBlueprintAttributes }.map(\.oid)) == [2, 3, 4])
            #expect(root.hasBlueprintAttributes)
            #expect(rows.allSatisfy { !$0.hasBlueprintAttributes })

            let selected = try #require(rows.dropFirst().first)
            let tasksBeforeSelecting = Self.detailTasks(in: server).count
            session.dataSource.selectedItem = selected
            #expect(await waitUntil { selected.hasBlueprintAttributes })
            let selectionTasks = Self.detailTasks(in: server).dropFirst(tasksBeforeSelecting).filter { $0.attrRequest == .need }
            #expect(selectionTasks.map(\.oid) == [selected.layerObject?.oid ?? 0])
            #expect(selectionTasks.allSatisfy { !$0.omitsBlueprintAttributes })
            // The extension group stays, next to the blueprint group.
            #expect(selected.attributesGroupList?.compactMap(\.identifier) == [AttributesGroup.Identifier.class, "ExtensionGroup"])

            // Selecting it again, or after another node, asks for nothing more.
            _ = await waitUntil { !session.manager.isUpdating() && !session.manager.isPrefetching() }
            let tasksAfterSelecting = Self.detailTasks(in: server).count
            session.dataSource.selectedItem = nil
            session.dataSource.selectedItem = selected
            try? await Task.sleep(for: .milliseconds(200))
            #expect(Self.detailTasks(in: server).count == tasksAfterSelecting)
        }

        @Test func wholeTreeFetchBringsEveryNodesBlueprintGroups() async {
            let server = FakeServer()
            Self.answeringDetails(on: server, knowsOmittingBlueprint: true)
            let session = await Self.loadedSession(on: server)
            var isFinished = false
            session.manager.fetchWholeTree { isFinished = true }
            #expect(await waitUntil(timeout: .seconds(10)) { isFinished })
            #expect(session.items.allSatisfy { $0.hasBlueprintAttributes })
        }

        @Test func fullGroupsFromAnOlderServerAreNotFetchedAgainOnSelection() async throws {
            let server = FakeServer()
            Self.answeringDetails(on: server, knowsOmittingBlueprint: false)
            let session = await Self.loadedSession(on: server)
            let displayed = try #require(session.dataSource.displayingFlatItems)
            #expect(displayed.count == 4)
            #expect(displayed.allSatisfy { $0.hasBlueprintAttributes })
            let tasksBeforeSelecting = Self.detailTasks(in: server).count
            session.dataSource.selectedItem = displayed.last
            try? await Task.sleep(for: .milliseconds(200))
            #expect(Self.detailTasks(in: server).count == tasksBeforeSelecting)
        }

        @Test func blueprintGroupsOfEitherPlatformAreRecognised() {
            let item = Self.layerItem(oid: 9)
            #expect(!item.hasBlueprintAttributes)
            item.attributesGroupList = [Self.group("ExtensionGroup")]
            #expect(!item.hasBlueprintAttributes)
            item.attributesGroupList = [Self.group(AttributesGroup.Identifier.uiView)]
            #expect(item.hasBlueprintAttributes)
            item.attributesGroupList = [Self.group(AttributesGroup.Identifier.nsView)]
            #expect(item.hasBlueprintAttributes)
        }

        @Test func extensionGroupsAloneDoNotTakeTheBlueprintGroupsAway() {
            let item = Self.layerItem(oid: 5)
            // A preference set of its own: expanding the root must not store the
            // fake app's expansion state in the app's settings.
            let dataSource = StaticHierarchyDataSource(preferenceManager: PreferenceManager())
            let info = HierarchyInfo()
            info.appInfo = InspectedAppInfo()
            info.appInfo?.screenScale = 2
            info.displayItems = [item]
            dataSource.reload(with: info, keepState: false)
            item.attributesGroupList = [Self.group(AttributesGroup.Identifier.class), Self.group("ExtensionGroup")]

            let detail = DisplayItemDetail()
            detail.displayItemOid = 5
            detail.attributesGroupList = [Self.group("NewerExtensionGroup")]
            dataSource.modify(with: detail)
            #expect(item.attributesGroupList?.compactMap(\.identifier) == [AttributesGroup.Identifier.class, "NewerExtensionGroup"])

            // A node asked for its extension groups that has none holds an
            // empty list, so it is not asked again.
            let bare = Self.layerItem(oid: 6)
            info.displayItems = [bare]
            dataSource.reload(with: info, keepState: false)
            let emptyDetail = DisplayItemDetail()
            emptyDetail.displayItemOid = 6
            emptyDetail.attributesGroupList = []
            dataSource.modify(with: emptyDetail)
            #expect(bare.attributesGroupList?.isEmpty == true)
        }
    }
}
