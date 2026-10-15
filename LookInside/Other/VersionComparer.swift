//
//  VersionComparer.swift
//  LookInside
//
//  Created by likai.123 on 2023/10/30.
//  Copyright © 2023 hughkli. All rights reserved.
//

import Foundation
import LookInsideHostCore

final class VersionComparer: NSObject {
    /// 如果 realVersion 等于或高于 expectedVersion，则该方法返回 YES（换句话说：用户的实际版本号满足我们的需要）
    /// A nil version reads as unparseable.
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
