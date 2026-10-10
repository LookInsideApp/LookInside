//
//  SwiftDemangler.swift
//  LookinClient
//
//  Created by likai.123 on 2024/1/14.
//  Copyright © 2024 hughkli. All rights reserved.
//

import Demangling
import Foundation

public class SwiftDemangler: NSObject {
    private static var simpleCache: [String: String] = [:]
    private static var completedCache: [String: String] = [:]

    private static func demangle(_ input: String, options: DemangleOptions) -> String? {
        return try? demangleAsNode(input).print(using: options)
    }

    /// 这里返回的结果会尽可能地短，去除了很多信息
    @objc public static func simpleParse(input: String) -> String {
        if let cachedResult = simpleCache[input] {
            return cachedResult
        }
        let result = demangle(input, options: .interfaceType) ?? input
        simpleCache[input] = result
        return result
    }

    /// 这里返回的结果会尽可能地长、包含了 module name 等各种信息
    @objc public static func completedParse(input: String) -> String {
        if let cachedResult = completedCache[input] {
            return cachedResult
        }
        let result = demangle(input, options: .default) ?? input
        completedCache[input] = result
        return result
    }
}
