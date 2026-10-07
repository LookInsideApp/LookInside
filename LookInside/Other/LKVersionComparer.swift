//
//  LKVersionComparer.swift
//  LookInside
//
//  Created by likai.123 on 2023/10/30.
//  Copyright © 2023 hughkli. All rights reserved.
//

import Foundation
import LookInsideHostCore

@objc(LKVersionComparer)
final class LKVersionComparer: NSObject {
    /// latest 指网上最高的 LookinServer 版本号，user 指用户真实的版本号。如果用户版本号低于最高版本号，则该方法返回 NO，此时应该提示用户升级。
    @objc(compareWithNewest:user:)
    static func compare(newest latest: String?, user: String?) -> Bool {
        compare(expectedVersion: latest, realVersion: user)
    }

    /// 如果 realVersion 等于或高于 expectedVersion，则该方法返回 YES（换句话说：用户的实际版本号满足我们的需要）
    /// A nil version reads as unparseable.
    @objc(compareWithExpectedVersion:realVersion:)
    static func compare(expectedVersion: String?, realVersion: String?) -> Bool {
        let expected = expectedVersion ?? ""
        let real = realVersion ?? ""
        guard let satisfied = ServerVersionComparison.satisfies(expectedVersion: expected, realVersion: real) else {
            assertionFailure("unparseable version: expected \(expected), real \(real)")
            return false
        }
        return satisfied
    }
}
