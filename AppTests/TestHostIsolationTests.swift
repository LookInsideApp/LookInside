//
//  TestHostIsolationTests.swift
//  LookInsideAppTests
//
//  The test action points the activation runtime at a state directory and
//  a file keychain of the build's own (LookInside.xcscheme). Without them
//  the tests would read and write the user's license state and raise
//  login-keychain prompts, so a scheme that loses them must fail here.
//

import Foundation
import LookInsideActivation
import Testing

extension HostAppTests {
    @MainActor
    struct TestHostIsolationTests {
        @Test func activationRuntimeUsesTheTestActionsStateAndKeychain() throws {
            let environment = ProcessInfo.processInfo.environment
            let stateDirectory = try #require(environment["LOOKINSIDE_ACTIVATION_STATE_DIR"])
            let keychainPath = try #require(environment["LOOKINSIDE_ACTIVATION_KEYCHAIN_PATH"])

            for path in [stateDirectory, keychainPath] {
                #expect(!path.contains("$("), "the scheme's build setting was not expanded: \(path)")
                #expect(!path.contains("Application Support/LookInside"), "\(path) is the app's own state")
            }
            #expect(ActivationDebugOverrides.stateDirectoryURL?.path == stateDirectory)
            #expect(ActivationDebugOverrides.keychainPath == keychainPath)
        }
    }
}
