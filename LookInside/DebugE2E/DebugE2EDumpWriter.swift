#if DEBUG
    import AppKit
    import Foundation
    import LookInsideHostCore

    /// Writes what the Host loaded for one live document as a normalized
    /// `snapshot.json`, in the same format lookin-probe writes (shared
    /// `SnapshotNormalizer`), so the diff tool of
    /// Scripts/reborn-e2e/LookinProbe compares both.
    ///
    /// The Host merges each detail into its display item, so a node has one
    /// `item` record (hierarchy plus merged details) and no separate `detail`.
    /// The Host decodes screenshots into images it does not archive, so a
    /// node's `host` record names their pixel sizes; the pixels themselves are
    /// covered by lookin-probe.
    @objc(LKDebugE2EDumpWriter)
    final class DebugE2EDumpWriter: NSObject {
        @objc(writeSnapshotForDataSource:app:platform:toDirectory:error:)
        static func writeSnapshot(
            for dataSource: StaticHierarchyDataSource,
            app: InspectableApp,
            platform: String,
            to directory: URL
        ) throws {
            guard let hierarchy = dataSource.rawHierarchyInfo else {
                throw SnapshotError("the data source has no hierarchy")
            }
            guard let appInfo = app.appInfo ?? hierarchy.appInfo else {
                throw SnapshotError("the inspected app has no app info")
            }
            let nodes = SnapshotNormalizer.collectNodes(roots: hierarchy.displayItems ?? [])
            let childrenByParent = SnapshotNormalizer.childrenByParent(nodes)
            let idsByItem = Dictionary(
                nodes.map { (ObjectIdentifier($0.item), $0.id) },
                uniquingKeysWith: { first, _ in first }
            )
            let displayingItems = dataSource.displayingFlatItems ?? []
            let displayingSet = Set(displayingItems.compactMap { idsByItem[ObjectIdentifier($0)] })
            // The outline shows its items in tree order; taking that order
            // from `nodes` applies the canonical sibling order to it too.
            let displayingIDs = nodes.map(\.id).filter { displayingSet.contains($0) }

            var flatNodes: [[String: Any]] = []
            var nodesWithAttributes = 0
            for node in nodes {
                let item = node.item
                let attributesLoaded = (item.attributesGroupList?.isEmpty == false)
                if attributesLoaded {
                    nodesWithAttributes += 1
                }
                var host: [String: Any] = [
                    "title": item.title() ?? NSNull(),
                    "subtitle": normalizedSubtitle(item.subtitle()),
                    "indentLevel": item.indentLevel(),
                    "isExpandable": item.isExpandable,
                    "isExpanded": item.isExpandable ? item.isExpanded : NSNull(),
                    "displayed": displayingSet.contains(node.id),
                    "doNotFetchScreenshotReason": item.doNotFetchScreenshotReason.rawValue,
                    "attributesLoaded": attributesLoaded,
                ]
                host["soloScreenshot"] = imageSize(item.soloScreenshot)
                host["groupScreenshot"] = imageSize(item.groupScreenshot)
                flatNodes.append([
                    "id": node.id,
                    "parent": node.parentID.isEmpty ? NSNull() : node.parentID,
                    "depth": node.depth,
                    "children": childrenByParent[node.id] ?? [],
                    "item": SnapshotNormalizer.nodeObjectJSON(item, imageSink: sizeOnlyImage),
                    "host": host,
                ])
            }

            let session = SnapshotNormalizer.sessionStateJSON(
                hostAppearance: NSApp.effectiveAppearance.name.rawValue
            )
            let raw: [String: Any] = [
                "format": 1,
                "host": [
                    "transport": "host-ui",
                    "platform": platform,
                    "activationState": activationStateName(),
                    "channelLicensed": isChannelLicensed(for: app),
                    "nodeCount": nodes.count,
                    "displayedNodeCount": displayingIDs.count,
                    "nodesWithAttributes": nodesWithAttributes,
                    // Informational here; the diff checks session-state.json.
                    "session": session,
                ],
                "appInfo": SnapshotNormalizer.appInfoJSON(appInfo, imageSink: sizeOnlyImage),
                "hierarchy": SnapshotNormalizer.hierarchyJSON(hierarchy),
                "roots": childrenByParent[""] ?? [],
                "displayed": displayingIDs,
                "nodes": flatNodes,
            ]
            guard let snapshot = SnapshotNormalizer.normalize(raw) as? [String: Any] else {
                throw SnapshotError("normalization did not return an object")
            }
            let data = try SnapshotNormalizer.serialize(snapshot)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: directory.appendingPathComponent("snapshot.json"), options: .atomic)
            try SnapshotNormalizer.writeSessionState(session, to: directory)
        }

        /// The outline subtitle can list the ivars that reference the object
        /// (`-[LookinDisplayItem subtitle]`), joined in hash-set order. They are
        /// sorted, and the timing-dependent ones dropped, as in the item JSON.
        private static func normalizedSubtitle(_ subtitle: String?) -> Any {
            guard let subtitle, !subtitle.isEmpty else { return NSNull() }
            let separator = "   "
            return subtitle.components(separatedBy: separator)
                .filter { !SnapshotNormalizer.volatileIvarNames.contains($0) }
                .sorted()
                .joined(separator: separator)
        }

        /// Images stand in as their pixel size only; see the type comment.
        private static func sizeOnlyImage(_ image: CGImage, _: [String]) -> Any {
            ["$imageSize": [image.width, image.height]]
        }

        private static func imageSize(_ image: NSImage?) -> Any {
            guard let image else { return NSNull() }
            var rect = CGRect(origin: .zero, size: image.size)
            guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
                return ["$imageSize": NSNull()]
            }
            return sizeOnlyImage(cgImage, [])
        }

        /// The list the launch window shows, from
        /// `AppsManager.scanApps(needImages: true, localInfos: nil)`:
        /// nil when no channel is connected. `completion` runs on the main
        /// thread, after this method returns.
        @objc(fetchAppsWithCompletion:)
        @MainActor
        static func fetchApps(completion: @escaping ([InspectableApp]?) -> Void) {
            Task { @MainActor in
                let result = await AppsManager.shared.scanApps(needImages: true, localInfos: nil)
                completion(result.channelCount == 0 ? nil : result.apps)
            }
        }

        /// `app`'s hierarchy, or the error the request failed with.
        /// `completion` runs on the main thread, after this method returns.
        @objc(fetchHierarchyForApp:completion:)
        @MainActor
        static func fetchHierarchy(for app: InspectableApp, completion: @escaping (HierarchyInfo?, Error?) -> Void) {
            Task { @MainActor in
                do {
                    try completion(await app.hierarchy(), nil)
                } catch {
                    completion(nil, error)
                }
            }
        }

        /// Whether the 220/221 license handshake succeeded on `app`'s channel,
        /// as the Host's connection layer records it.
        @objc(isChannelLicensedForApp:)
        static func isChannelLicensed(for app: InspectableApp) -> Bool {
            MainActor.assumeIsolated {
                app.channel?.connectionState.licenseHandshake.isVerified ?? false
            }
        }

        private static func activationStateName() -> String {
            switch SwiftUISupportGatekeeper.sharedInstance().activationState {
            case .unknown: return "unknown"
            case .notActivated: return "notActivated"
            case .activated: return "activated"
            }
        }
    }
#endif
