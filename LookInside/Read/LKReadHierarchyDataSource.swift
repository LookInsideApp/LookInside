//
//  LKReadHierarchyDataSource.swift
//  Lookin
//
//  Created by Li Kai on 2019/5/12.
//  https://lookin.work
//

import AppKit

/// The hierarchy of a `.lookin` file: the tree the file holds, with the
/// stored screenshots put back on the items. It uses the reader window's own
/// preference set.
@objc(LKReadHierarchyDataSource)
final class LKReadHierarchyDataSource: LKHierarchyDataSource {
    private let readPreferenceManager: LKPreferenceManager

    @objc(initWithFile:preferenceManager:)
    init(file: LookinHierarchyFile, preferenceManager manager: LKPreferenceManager) {
        readPreferenceManager = manager
        super.init()

        reload(with: file.hierarchyInfo, keepState: false)

        let solo = file.soloScreenshots ?? [:]
        let group = file.groupScreenshots ?? [:]
        guard !solo.isEmpty || !group.isEmpty else { return }
        // A Mac capture keys its screenshots by the view's oid, an iOS one by
        // the layer's.
        let prefersViewOID = LKHelper.appInfoLooksLikeMacTarget(file.hierarchyInfo?.appInfo)
        for item in flatItems ?? [] {
            let screenshots = LKReadScreenshotLookup.screenshots(
                forOids: item.availableObjectOidsPreferView(prefersViewOID),
                solo: solo,
                group: group
            )
            if let data = screenshots.solo {
                item.soloScreenshot = NSImage(data: data)
            }
            if let data = screenshots.group {
                item.groupScreenshot = NSImage(data: data)
            }
        }
    }

    override func preferenceManager() -> LKPreferenceManager! {
        readPreferenceManager
    }
}
