import Foundation

enum LKInstallerFilesystem {
    /// Ensures the executable bit is set on `url`. No-op if already executable.
    static func ensureExecutableBit(at url: URL, errorBuilder: (String) -> Error) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else {
            throw errorBuilder(
                String(format: NSLocalizedString("Executable not found at %@", comment: ""), url.path)
            )
        }
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        if let perms = attributes[.posixPermissions] as? NSNumber {
            let current = perms.int16Value
            let desired = current | 0o111
            if desired != current {
                try fileManager.setAttributes(
                    [.posixPermissions: NSNumber(value: desired)],
                    ofItemAtPath: url.path
                )
            }
        }
    }
}
