import Foundation
import Security

enum LKInstallerCodeSignature {
    struct TeamIdentifierMismatch: LocalizedError {
        let expected: String
        let found: String

        var errorDescription: String? {
            String(
                format: NSLocalizedString("Code is signed by a different team.\nExpected: %1$@\nFound: %2$@", comment: ""),
                expected,
                found
            )
        }
    }

    struct TeamIdentifierUnavailable: LocalizedError {
        let message: String

        var errorDescription: String? {
            String(format: NSLocalizedString("Unable to read code signature.\n%@", comment: ""), message)
        }
    }

    static func teamIdentifier(atPath path: String) throws -> String {
        let url = URL(fileURLWithPath: path)
        var staticCode: SecStaticCode?
        let createStatus = SecStaticCodeCreateWithPath(url as CFURL, [], &staticCode)
        guard createStatus == errSecSuccess, let staticCode else {
            throw TeamIdentifierUnavailable(message: "SecStaticCodeCreateWithPath failed (OSStatus \(createStatus)).")
        }

        let validateStatus = SecStaticCodeCheckValidity(staticCode, SecCSFlags(rawValue: 0), nil)
        guard validateStatus == errSecSuccess else {
            throw TeamIdentifierUnavailable(message: "Code signature validation failed (OSStatus \(validateStatus)).")
        }

        var infoRef: CFDictionary?
        let infoStatus = SecCodeCopySigningInformation(
            staticCode,
            SecCSFlags(rawValue: kSecCSSigningInformation),
            &infoRef
        )
        guard infoStatus == errSecSuccess, let info = infoRef as? [String: Any] else {
            throw TeamIdentifierUnavailable(message: "SecCodeCopySigningInformation failed (OSStatus \(infoStatus)).")
        }

        guard let teamID = info[kSecCodeInfoTeamIdentifier as String] as? String, teamID.isEmpty == false else {
            throw TeamIdentifierUnavailable(message: "Team identifier is missing from code signing information.")
        }
        return teamID
    }

    /// Reads the team identifier of the target at `targetURL` and validates that
    /// it matches the host process's team identifier.
    ///
    /// Strategy:
    /// - Read host first. If the host has no team identifier (dev / ad-hoc
    ///   build), skip the target check entirely — dev builds are inherently
    ///   trust-on-first-build, and external artifacts may be unsigned during
    ///   development too.
    /// - Only when the host carries a real team identifier do we require the
    ///   target to be properly signed and to match.
    ///
    /// Errors are re-thrown via `unavailableErrorBuilder` / `mismatchErrorBuilder`
    /// so callers can wrap them in their own domain-specific error types.
    static func verifyTeamIdentifierMatchesHost(
        of targetURL: URL,
        unavailableErrorBuilder: (String) -> Error,
        mismatchErrorBuilder: (_ expected: String, _ found: String) -> Error
    ) throws {
        let hostTeamID = try? teamIdentifier(atPath: Bundle.main.bundlePath)
        guard let hostTeamID, hostTeamID.isEmpty == false else {
            LKInstallerLogger.installer.info(
                "verifyTeamIdentifierMatchesHost: host has no team identifier (dev build); skipping target team check at \(targetURL.path, privacy: .public)"
            )
            return
        }

        let targetTeamID: String
        do {
            targetTeamID = try teamIdentifier(atPath: targetURL.path)
        } catch let error as TeamIdentifierUnavailable {
            throw unavailableErrorBuilder(error.message)
        }
        guard hostTeamID == targetTeamID else {
            throw mismatchErrorBuilder(hostTeamID, targetTeamID)
        }
        LKInstallerLogger.installer.info(
            "verifyTeamIdentifierMatchesHost: host=\(hostTeamID, privacy: .public) matches target at \(targetURL.path, privacy: .public)"
        )
    }
}
