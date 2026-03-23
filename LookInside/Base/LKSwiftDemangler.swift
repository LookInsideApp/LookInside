//
//  LKSwiftDemangler.swift
//  LookinClient
//
//  Created by likai.123 on 2024/1/14.
//  Copyright © 2024 hughkli. All rights reserved.
//

import Foundation

public class LKSwiftDemangler: NSObject {
    private static var simpleCache: [String: String] = [:]
    private static var completedCache: [String: String] = [:]

    @_silgen_name("swift_demangle")
    private static func runtimeDemangle(
        _ mangledName: UnsafePointer<UInt8>?,
        _ mangledNameLength: UInt,
        _ outputBuffer: UnsafeMutablePointer<UInt8>?,
        _ outputBufferSize: UnsafeMutablePointer<Int>?,
        _ flags: UInt32
    ) -> UnsafeMutablePointer<Int8>?

    private static func demangle(_ input: String) -> String? {
        guard !input.isEmpty else {
            return nil
        }
        return input.utf8CString.withUnsafeBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else {
                return nil
            }
            let mangledName = UnsafeRawPointer(baseAddress).assumingMemoryBound(to: UInt8.self)
            guard let demangled = runtimeDemangle(mangledName, UInt(buffer.count - 1), nil, nil, 0) else {
                return nil
            }
            defer { free(demangled) }
            return String(cString: demangled)
        }
    }

    private static func simplify(_ demangled: String) -> String {
        guard let firstDot = demangled.firstIndex(of: ".") else {
            return demangled
        }
        let moduleName = demangled[..<firstDot]
        guard moduleName.range(of: #"^[A-Za-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil else {
            return demangled
        }
        return String(demangled[demangled.index(after: firstDot)...])
    }

    /// 这里返回的结果会尽可能地短，去除了很多信息
    @objc public static func simpleParse(input: String) -> String {
        if let cachedResult = simpleCache[input] {
            return cachedResult
        }
        let result = demangle(input).map(simplify) ?? input
        simpleCache[input] = result
        return result
    }

    /// 这里返回的结果会尽可能地长、包含了 module name 等各种信息
    @objc public static func completedParse(input: String) -> String {
        if let cachedResult = completedCache[input] {
            return cachedResult
        }
        let result = demangle(input) ?? input
        completedCache[input] = result
        return result
    }
}
