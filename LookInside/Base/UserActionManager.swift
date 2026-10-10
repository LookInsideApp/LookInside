//
//  UserActionManager.swift
//  LookInside
//

import Foundation

enum UserActionType {
    case none
    /// A click, double click, pan or similar in the preview.
    case previewOperation
    /// A click in the Dashboard.
    case dashboardClick
    /// The selected item changed.
    case selectedItemChange
}

protocol UserActionManagerDelegate: AnyObject {
    /// Called for every `send(_:)`.
    func userActionManager(_ manager: UserActionManager, didAct type: UserActionType)
}

/// Broadcasts user actions (preview gestures, Dashboard clicks) to weakly
/// held delegates, for example so an open Dashboard editor can close.
final class UserActionManager: NSObject {
    private static let shared = UserActionManager()

    static func sharedInstance() -> UserActionManager {
        shared
    }

    private let delegates = NSPointerArray.weakObjects()

    /// Delegates are held weakly and need no removal; adding one twice
    /// keeps a single entry.
    func add(_ delegate: UserActionManagerDelegate) {
        if delegates.allObjects.contains(where: { ($0 as AnyObject) === delegate }) {
            return
        }
        delegates.addPointer(Unmanaged.passUnretained(delegate as AnyObject).toOpaque())
    }

    func send(_ type: UserActionType) {
        guard type != .none else {
            assertionFailure("send(_:) needs an action")
            return
        }
        for case let delegate as UserActionManagerDelegate in delegates.allObjects {
            delegate.userActionManager(self, didAct: type)
        }
    }
}
