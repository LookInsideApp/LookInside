import Foundation
import Security

/// The shared installed-artifact contract used by the GUI installer and the
/// headless service. First-time preparation remains an explicit GUI action.
public enum InjectableFrameworkRepository {
    public static let minimumVersion = "0.2.2"
    public static let frameworkName = "LookInsideServer.framework"

    public static var rootDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/LookInside/InjectableFrameworks", isDirectory: true)
    }

    public static func frameworkURL(version: String) -> URL {
        rootDirectory.appendingPathComponent(version, isDirectory: true)
            .appendingPathComponent(frameworkName, isDirectory: true)
    }

    public static func preparedFramework() throws -> URL {
        let directories = (try? FileManager.default.contentsOfDirectory(at: rootDirectory, includingPropertiesForKeys: nil)) ?? []
        let versions = directories.map(\.lastPathComponent).filter {
            let components = $0.split(separator: ".", omittingEmptySubsequences: false)
            return components.count == 3 && components.allSatisfy { !$0.isEmpty && $0.allSatisfy(\.isNumber) }
                && $0.compare(minimumVersion, options: .numeric) != .orderedAscending
        }.sorted { $0.compare($1, options: .numeric) == .orderedDescending }
        guard let version = versions.first else { throw preparationRequired() }
        let framework = frameworkURL(version: version)
        try validate(framework)
        guard Bundle(url: framework)?.object(forInfoDictionaryKey: "LookInsideSupportsProcessIdentity") as? Bool == true
        else { throw preparationRequired() }
        return framework
    }

    public static func validate(_ framework: URL) throws {
        var code: SecStaticCode?
        var requirement: SecRequirement?
        let identity = #"anchor apple generic and certificate leaf[subject.OU] = "964G86XT2P" and identifier "app.lookinside.LookInsideServer""#
        guard framework.lastPathComponent == frameworkName,
              SecRequirementCreateWithString(identity as CFString, [], &requirement) == errSecSuccess,
              SecStaticCodeCreateWithPath(framework as CFURL, [], &code) == errSecSuccess, let code,
              SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSCheckAllArchitectures), requirement) == errSecSuccess
        else { throw preparationRequired() }
    }

    private static func preparationRequired() -> NSError {
        NSError(domain: "com.lookinside.injection", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Prepare the current signed LookInsideServer framework using Attach to Running App in LookInside, then retry.",
            "inspectionFailureCode": "injection.preparationRequired",
        ])
    }
}
