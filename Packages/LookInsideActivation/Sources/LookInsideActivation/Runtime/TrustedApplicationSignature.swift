import Foundation
import Security

/// Decides whether the application at a user-writable path may join a new
/// license key's access list.
///
/// The installed 2.3.x helper lives under Application Support, where any
/// process of the user can replace it. It is trusted only when its code
/// signature satisfies the requirement the helper itself enforced:
/// - an Apple-issued chain (`anchor apple generic`);
/// - the helper's identifier, `app.lookinside.LookInsideAuthServer`;
/// - a Mac App Store leaf (OID 1.2.840.113635.100.6.1.9), or a Developer ID
///   intermediate (1.2.840.113635.100.6.2.6) with a Developer ID
///   Application leaf (1.2.840.113635.100.6.1.13);
/// - the same team as the running Host. The team is read from the Host's
///   own signature at run time, so no team identifier is built in. An ad-hoc
///   signed or unsigned Host has no team, and then nothing is trusted.
///
/// The access-list entry is made first and the bundle checked after, at the
/// same path. The bundle's code-directory hash is read before and after; a
/// bundle that changed in between, or fails the check, is refused.
enum TrustedApplicationSignature {
    static let helperIdentifier = "app.lookinside.LookInsideAuthServer"

    /// The Security calls the check makes. Tests replace them.
    struct Operations: Sendable {
        /// Code-directory hash of the bundle at a path, or `nil` when it is
        /// not signed or not readable.
        var codeDirectoryHash: @Sendable (_ path: String) -> Data?
        /// Access-list entry for the application at a path.
        var makeApplication: @Sendable (_ path: String) -> SecTrustedApplication?
        /// Code-directory hash of the bundle at a path when its signature is
        /// valid and satisfies a requirement, otherwise `nil`.
        var validatedCodeDirectoryHash: @Sendable (_ path: String, _ requirement: String) -> Data?

        static let system = Operations(
            codeDirectoryHash: { TrustedApplicationSignature.codeDirectoryHash(path: $0, requirement: nil) },
            makeApplication: { path in
                var application: SecTrustedApplication?
                guard SecTrustedApplicationCreateFromPath(path, &application) == errSecSuccess else {
                    return nil
                }
                return application
            },
            validatedCodeDirectoryHash: { TrustedApplicationSignature.codeDirectoryHash(path: $0, requirement: $1) }
        )
    }

    /// Code requirement for the helper signed by `teamID`, or `nil` when
    /// `teamID` is missing or not a team identifier.
    static func requirement(forTeamID teamID: String?, identifier: String = helperIdentifier) -> String? {
        guard let teamID, isTeamIdentifier(teamID), isBundleIdentifier(identifier) else {
            return nil
        }
        return [
            "anchor apple generic",
            #"identifier "\#(identifier)""#,
            #"certificate leaf[subject.OU] = "\#(teamID)""#,
            "(certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */"
                + " or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */"
                + " and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */)",
        ].joined(separator: " and ")
    }

    /// The access-list entry for the helper at `path` when a Host signed by
    /// `hostTeamID` may trust it, otherwise `nil`. No Security call is made
    /// when the Host has no team.
    static func trustedApplication(
        atPath path: String,
        hostTeamID: String?,
        operations: Operations = .system
    ) -> SecTrustedApplication? {
        guard let requirement = requirement(forTeamID: hostTeamID),
              let before = operations.codeDirectoryHash(path),
              let application = operations.makeApplication(path),
              let after = operations.validatedCodeDirectoryHash(path, requirement),
              before == after
        else {
            return nil
        }
        return application
    }

    /// `trustedApplication(atPath:hostTeamID:operations:)` for the running
    /// Host, checking the bundle's signature on disk.
    static func trustedHelperApplication(atPath path: String) -> SecTrustedApplication? {
        trustedApplication(atPath: path, hostTeamID: currentProcessTeamID())
    }

    /// Team identifier in the running process's signature, or `nil` for an
    /// ad-hoc signed or unsigned process.
    static func currentProcessTeamID() -> String? {
        var code: SecCode?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code else {
            return nil
        }
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode else {
            return nil
        }
        return signingInformation(staticCode)?[kSecCodeInfoTeamIdentifier as String] as? String
    }

    /// Code-directory hash of the code at `path` when its signature is valid
    /// and, with a `requirement`, satisfies it. `nil` otherwise.
    static func codeDirectoryHash(path: String, requirement: String?) -> Data? {
        var staticCode: SecStaticCode?
        guard
            SecStaticCodeCreateWithPath(URL(fileURLWithPath: path) as CFURL, [], &staticCode) == errSecSuccess,
            let staticCode
        else {
            return nil
        }
        var secRequirement: SecRequirement?
        if let requirement {
            guard SecRequirementCreateWithString(requirement as CFString, [], &secRequirement) == errSecSuccess,
                  secRequirement != nil
            else {
                return nil
            }
        }
        let flags = SecCSFlags(rawValue: kSecCSCheckAllArchitectures | kSecCSStrictValidate)
        guard SecStaticCodeCheckValidity(staticCode, flags, secRequirement) == errSecSuccess else {
            return nil
        }
        return signingInformation(staticCode)?[kSecCodeInfoUnique as String] as? Data
    }

    /// `true` when the code at `path` has a valid signature that satisfies
    /// `requirement`.
    static func staticCodeSatisfies(path: String, requirement: String) -> Bool {
        codeDirectoryHash(path: path, requirement: requirement) != nil
    }

    private static func signingInformation(_ staticCode: SecStaticCode) -> [String: Any]? {
        var information: CFDictionary?
        guard
            SecCodeCopySigningInformation(
                staticCode,
                SecCSFlags(rawValue: kSecCSSigningInformation),
                &information
            ) == errSecSuccess
        else {
            return nil
        }
        return information as? [String: Any]
    }

    /// Ten upper-case letters or digits, so the value cannot change the
    /// requirement's meaning.
    private static func isTeamIdentifier(_ value: String) -> Bool {
        value.count == 10
            && value.unicodeScalars.allSatisfy { scalar in
                ("A" ... "Z").contains(scalar) || ("0" ... "9").contains(scalar)
            }
    }

    /// Letters, digits, dots and hyphens only.
    private static func isBundleIdentifier(_ value: String) -> Bool {
        value.isEmpty == false
            && value.unicodeScalars.allSatisfy { scalar in
                ("a" ... "z").contains(scalar) || ("A" ... "Z").contains(scalar) || ("0" ... "9").contains(scalar)
                    || scalar == "." || scalar == "-"
            }
    }
}
