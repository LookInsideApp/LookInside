//
//  AppDelegate.swift
//  Example-iOS
//
//  Created by JH on 2026/3/31.
//  Copyright © 2026 hughkli. All rights reserved.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        true
    }

    // MARK: UISceneSession Lifecycle

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let userActivity = options.userActivities.first {
            switch userActivity.activityType {
            case "detail":
                return UISceneConfiguration(name: "Detail", sessionRole: connectingSceneSession.role)
            case "settings":
                return UISceneConfiguration(name: "Settings", sessionRole: connectingSceneSession.role)
            default:
                break
            }
        }
        return UISceneConfiguration(name: "Main", sessionRole: connectingSceneSession.role)
    }

    func application(_: UIApplication, didDiscardSceneSessions _: Set<UISceneSession>) {}
}
