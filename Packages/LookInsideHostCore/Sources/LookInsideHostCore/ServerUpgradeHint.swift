import Foundation

/// The release a Server reports in its 220 LicenseChallenge reply.
///
/// Servers newer than 0.2.9 add two optional keys to the reply:
/// `lookinside_server_version` (the marketing version, "dev" in an
/// unreleased build) and `lookinside_server_build` (an integer). A 0.2.9
/// Server sends neither. Only the nonce and the server instance id are
/// required for the handshake; these keys only drive the upgrade hint, and a
/// modified Server can omit or forge them, so they are never a security
/// boundary.
public struct ServerRelease: Equatable, Sendable {
    public static let versionKey = "lookinside_server_version"
    public static let buildKey = "lookinside_server_build"

    /// The newest release that does not report its version.
    public static let lastReleaseWithoutVersion = SemanticVersion(major: 0, minor: 2, patch: 9)

    public let version: String?
    public let build: Int?

    public init(version: String?, build: Int?) {
        self.version = version
        self.build = build
    }

    /// Reads the two keys from the decoded 220 payload (an `NSDictionary`).
    /// A key with a value of the wrong type counts as missing.
    public static func parse(_ payload: Any?) -> ServerRelease {
        let dictionary = payload as? [AnyHashable: Any]
        let version = dictionary?[versionKey] as? String
        let build = (dictionary?[buildKey] as? NSNumber)?.intValue
        return ServerRelease(version: version, build: build)
    }

    /// Whether the Host suggests that the app's integrator upgrade the
    /// Server: when a key is missing (a 0.2.9 or older Server), or when the
    /// version is a SemVer at or below 0.2.9. A version that is not SemVer,
    /// such as "dev" from an unreleased build, gets no hint.
    public var suggestsUpgrade: Bool {
        guard let version, build != nil else {
            return true
        }
        guard let semanticVersion = SemanticVersion(version) else {
            return false
        }
        return semanticVersion <= Self.lastReleaseWithoutVersion
    }
}

/// `MAJOR.MINOR.PATCH`, with an optional pre-release and build suffix that
/// the comparison ignores.
public struct SemanticVersion: Comparable, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// Parses `1.2.3`, `1.2.3-rc.1` or `1.2.3+42`; nil for anything else.
    public init?(_ string: String) {
        var core = Substring(string)
        if let suffixStart = core.firstIndex(where: { $0 == "-" || $0 == "+" }) {
            let suffix = core[core.index(after: suffixStart)...]
            guard !suffix.isEmpty, suffix.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "." || $0 == "-" || $0 == "+") }) else {
                return nil
            }
            core = core[..<suffixStart]
        }
        let parts = core.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            return nil
        }
        var numbers: [Int] = []
        for part in parts {
            guard !part.isEmpty, part.allSatisfy({ $0.isASCII && $0.isNumber }), let number = Int(part) else {
                return nil
            }
            numbers.append(number)
        }
        self.init(major: numbers[0], minor: numbers[1], patch: numbers[2])
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}

/// Shows the upgrade hint at most once per inspected app for the life of the
/// Host process.
///
/// Not thread-safe; the Host keeps it on the main actor.
public final class ServerUpgradeHintLedger {
    private var hintedApps = Set<String>()

    public init() {}

    /// `true` the first time it is asked about `appKey` with a release that
    /// suggests an upgrade; the hint is then recorded as shown.
    public func shouldShowHint(for release: ServerRelease, appKey: String) -> Bool {
        guard release.suggestsUpgrade else {
            return false
        }
        return hintedApps.insert(appKey).inserted
    }
}
