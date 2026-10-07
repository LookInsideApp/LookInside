//
//  LKUserActionManager.swift
//  LookInside
//

import Foundation

@objc enum LKUserActionType: Int {
    @objc(LKUserActionType_None) case none
    /// A click, double click, pan or similar in the preview.
    @objc(LKUserActionType_PreviewOperation) case previewOperation
    /// A click in the Dashboard.
    @objc(LKUserActionType_DashboardClick) case dashboardClick
    /// The selected item changed.
    @objc(LKUserActionType_SelectedItemChange) case selectedItemChange
}

@objc protocol LKUserActionManagerDelegate: NSObjectProtocol {
    /// Called for every `sendAction:`.
    @objc(LKUserActionManager:didAct:)
    func lkUserActionManager(_ manager: LKUserActionManager, didAct type: LKUserActionType)
}

/// Broadcasts user actions (preview gestures, Dashboard clicks) to weakly
/// held delegates, for example so an open Dashboard editor can close.
@objc(LKUserActionManager)
final class LKUserActionManager: NSObject {
    private static let shared = LKUserActionManager()

    @objc static func sharedInstance() -> LKUserActionManager {
        shared
    }

    private let delegates = NSPointerArray.weakObjects()

    /// Delegates are held weakly and need no removal; adding one twice
    /// keeps a single entry.
    @objc(addDelegate:)
    func add(_ delegate: LKUserActionManagerDelegate) {
        if delegates.allObjects.contains(where: { ($0 as AnyObject) === delegate }) {
            return
        }
        delegates.addPointer(Unmanaged.passUnretained(delegate as AnyObject).toOpaque())
    }

    @objc(sendAction:)
    func send(_ type: LKUserActionType) {
        guard type != .none else {
            assertionFailure("sendAction: needs an action")
            return
        }
        for case let delegate as LKUserActionManagerDelegate in delegates.allObjects
            where delegate.responds(to: #selector(LKUserActionManagerDelegate.lkUserActionManager(_:didAct:)))
        {
            delegate.lkUserActionManager(self, didAct: type)
        }
    }
}
