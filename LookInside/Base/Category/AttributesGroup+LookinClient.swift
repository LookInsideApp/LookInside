//
//  AttributesGroup+LookinClient.swift
//  LookInside
//

import Foundation

extension AttributesGroup {
    /// The group's card title. `isMacTarget` describes the inspected app,
    /// not the Host; it only changes the ViewLayer group, whose title names
    /// the view class (`NSView` vs `UIView`), and the layout guide group.
    @objc(queryDisplayTitleForMacTarget:)
    func queryDisplayTitle(forMacTarget isMacTarget: Bool) -> String {
        if let userCustomTitle, !userCustomTitle.isEmpty {
            return userCustomTitle
        }
        if identifier == LookinAttrGroup_ViewLayer {
            // +groupTitleWithGroupID: picks this title with TARGET_OS_IPHONE,
            // which is always 0 in the Host, so it would say "NSView" even
            // for an iOS target.
            return "CALayer / \(AppHelper.viewClassName(forMacTarget: isMacTarget))"
        }
        if identifier == LookinAttrGroup_LayoutGuide {
            // The group ID is platform-neutral; the title names the inspected
            // platform's actual class.
            return isMacTarget ? "NSLayoutGuide" : "UILayoutGuide"
        }
        return DashboardBlueprint.groupTitle(withGroupID: identifier) ?? ""
    }
}
