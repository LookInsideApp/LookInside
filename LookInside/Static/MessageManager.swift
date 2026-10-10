//
//  MessageManager.swift
//  LookInside
//
//  Created by likai.123 on 2023/10/30.
//  Copyright © 2023 hughkli. All rights reserved.
//

import Foundation

/// The notices the inspector window shows under its toolbar message
/// button. Identifiers are `jobsMessageIdentifier` and `swiftSubspecMessageIdentifier`
/// (StaticConstants.swift).
final class MessageManager: NSObject {
    /// Set once the jobs notice was dismissed.
    private static let hasReadJobsDefaultsKey = "LKMessageManager_HasReadJobs"

    private static let shared = MessageManager()

    @objc class func sharedInstance() -> MessageManager {
        shared
    }

    private var messages = Set<String>()

    override private init() {
        super.init()
    }

    @objc(addMessage:)
    func addMessage(_ message: String) {
        messages.insert(message)
    }

    @objc(removeMessage:)
    func removeMessage(_ message: String) {
        messages.remove(message)
        if message == jobsMessageIdentifier {
            UserDefaults.standard.set(true, forKey: Self.hasReadJobsDefaultsKey)
        }
    }

    /// The current messages, shortest first.
    @objc func queryMessages() -> [String] {
        // A stable sort over an unordered set: ties keep whatever order the
        // set yields, as NSSet's -allObjects did.
        Array(messages).sorted { $0.utf16.count < $1.utf16.count }
    }

    #if DEBUG
        @objc func reset() {
            UserDefaults.standard.removeObject(forKey: Self.hasReadJobsDefaultsKey)
        }
    #endif
}
