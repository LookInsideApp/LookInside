import AppKit
import Foundation

enum LKInjectableFrameworkInstallerError: LocalizedError {
    case downloadFailed(String)
    case unzipFailed(String)
    case xcframeworkSliceNotFound
    case teamIdentifierUnavailable(String)
    case teamIdentifierMismatch(expected: String, found: String)
    case installFailed(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case let .downloadFailed(message):
            return String(format: NSLocalizedString("Failed to download LookInside Server framework.\n%@", comment: ""), message)
        case let .unzipFailed(message):
            return String(format: NSLocalizedString("Failed to extract LookInside Server framework.\n%@", comment: ""), message)
        case .xcframeworkSliceNotFound:
            return NSLocalizedString("The downloaded archive did not contain a macOS slice of LookInsideServer.xcframework.", comment: "")
        case let .teamIdentifierUnavailable(message):
            return String(format: NSLocalizedString("Unable to read the code signature of LookInside Server framework.\n%@", comment: ""), message)
        case let .teamIdentifierMismatch(expected, found):
            return String(format: NSLocalizedString("LookInside Server framework is signed by a different team.\nExpected: %1$@\nFound: %2$@", comment: ""), expected, found)
        case let .installFailed(message):
            return String(format: NSLocalizedString("Failed to install LookInside Server framework.\n%@", comment: ""), message)
        case .cancelled:
            return NSLocalizedString("Installation was cancelled.", comment: "")
        }
    }
}

enum LKInjectableFrameworkInstallerStage {
    case preparing
    case checkingForUpdates
    case downloading
    case extracting
    case verifying
    case installing
    case finishing

    var localizedDescription: String {
        switch self {
        case .preparing:
            return NSLocalizedString("Preparing…", comment: "")
        case .checkingForUpdates:
            return NSLocalizedString("Checking for updates…", comment: "")
        case .downloading:
            return NSLocalizedString("Downloading LookInside Server framework…", comment: "")
        case .extracting:
            return NSLocalizedString("Extracting…", comment: "")
        case .verifying:
            return NSLocalizedString("Verifying code signature…", comment: "")
        case .installing:
            return NSLocalizedString("Installing…", comment: "")
        case .finishing:
            return NSLocalizedString("Finalizing…", comment: "")
        }
    }
}

enum LKInjectableFrameworkInstallerLayout {
    /// Hard floor — bundled-baseline server version this build of the client is
    /// known to be compatible with. If the GitHub latest-release lookup fails
    /// (rate limit, offline) the installer falls back to this version.
    static let minimumServerVersion = "0.2.2"

    static let repositoryOwner = "LookInsideApp"
    static let repositoryName = "LookInside-Release"
    static let assetName = "LookInsideServer.xcframework.zip"

    /// Folder name inside the xcframework that holds the macOS slice.
    /// Apple's xcframework convention is `<platform>-<archs>` joined by `_`.
    static let macOSSliceFolderName = "macos-arm64_x86_64"

    static let xcframeworkBundleName = "LookInsideServer.xcframework"
    static let frameworkBundleName = "LookInsideServer.framework"

    static var rootDirectoryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/LookInside/InjectableFrameworks", isDirectory: true)
    }

    static func versionDirectoryURL(for version: String) -> URL {
        rootDirectoryURL.appendingPathComponent(version, isDirectory: true)
    }

    static func installedFrameworkURL(for version: String) -> URL {
        versionDirectoryURL(for: version)
            .appendingPathComponent(frameworkBundleName, isDirectory: true)
    }

    static func assetDownloadURL(for version: String) -> URL {
        URL(string: "https://github.com/\(repositoryOwner)/\(repositoryName)/releases/download/\(version)/\(assetName)")!
    }

    static var latestReleaseAPIURL: URL {
        URL(string: "https://api.github.com/repos/\(repositoryOwner)/\(repositoryName)/releases/latest")!
    }
}

struct LKInjectableFrameworkInstallation {
    let version: String
    let frameworkURL: URL
}

final class LKInjectableFrameworkInstaller {
    static let shared = LKInjectableFrameworkInstaller()

    private init() {}

    private let installLock = NSLock()

    /// Ensures `LookInsideServer.framework` is installed under
    /// `~/Library/Application Support/LookInside/InjectableFrameworks/<version>/`
    /// and returns the framework URL plus the version actually installed.
    ///
    /// Behavior:
    /// - Resolves the target version: tries to read the latest release tag
    ///   from GitHub, falling back to `minimumServerVersion` if the lookup
    ///   fails or returns a version older than the minimum.
    /// - If the resolved version is already installed and its code signature
    ///   matches the host team identifier, returns immediately.
    /// - Otherwise presents a modal progress window while downloading,
    ///   extracting, signature-verifying and moving the framework into place.
    func ensureInstalled(presentingWindow: NSWindow?) throws -> LKInjectableFrameworkInstallation {
        if !Thread.isMainThread {
            var captured: Result<LKInjectableFrameworkInstallation, Error>!
            DispatchQueue.main.sync {
                do {
                    let installation = try self.ensureInstalled(presentingWindow: presentingWindow)
                    captured = .success(installation)
                } catch {
                    captured = .failure(error)
                }
            }
            return try captured.get()
        }

        installLock.lock()
        defer { installLock.unlock() }

        let targetVersion = resolveTargetVersion()
        let installedURL = LKInjectableFrameworkInstallerLayout.installedFrameworkURL(for: targetVersion)

        if FileManager.default.fileExists(atPath: installedURL.path) {
            do {
                try verifyTeamIdentifier(of: installedURL)
                LKInstallerLogger.installer.info(
                    "injectable framework already installed version=\(targetVersion, privacy: .public)"
                )
                return LKInjectableFrameworkInstallation(version: targetVersion, frameworkURL: installedURL)
            } catch {
                LKInstallerLogger.installer.notice(
                    "installed framework signature invalid, re-downloading: \(error.localizedDescription, privacy: .public)"
                )
                try? FileManager.default.removeItem(at: installedURL)
            }
        }

        return try runInstallWithModal(version: targetVersion, presentingWindow: presentingWindow)
    }

    func verifyTeamIdentifier(of frameworkURL: URL) throws {
        try LKInstallerCodeSignature.verifyTeamIdentifierMatchesHost(
            of: frameworkURL,
            unavailableErrorBuilder: { LKInjectableFrameworkInstallerError.teamIdentifierUnavailable($0) },
            mismatchErrorBuilder: { expected, found in
                LKInjectableFrameworkInstallerError.teamIdentifierMismatch(expected: expected, found: found)
            }
        )
    }

    // MARK: - Version resolution

    private func resolveTargetVersion() -> String {
        let minimum = LKInjectableFrameworkInstallerLayout.minimumServerVersion
        guard let latest = fetchLatestVersionFromGitHub() else {
            LKInstallerLogger.installer.info(
                "GH latest-release lookup unavailable, falling back to minimum version=\(minimum, privacy: .public)"
            )
            return minimum
        }
        if compareSemver(latest, minimum) >= 0 {
            return latest
        }
        LKInstallerLogger.installer.notice(
            "GH latest=\(latest, privacy: .public) is older than minimum=\(minimum, privacy: .public); using minimum"
        )
        return minimum
    }

    private func fetchLatestVersionFromGitHub() -> String? {
        var capturedTag: String?
        let semaphore = DispatchSemaphore(value: 0)

        var request = URLRequest(url: LKInjectableFrameworkInstallerLayout.latestReleaseAPIURL)
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            if let error {
                LKInstallerLogger.installer.warning(
                    "GH latest fetch failed: \(error.localizedDescription, privacy: .public)"
                )
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200 ... 299).contains(httpResponse.statusCode),
                  let data
            else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                LKInstallerLogger.installer.warning("GH latest fetch returned status=\(status)")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let tag = json?["tag_name"] as? String, tag.isEmpty == false {
                    capturedTag = tag
                }
            } catch {
                LKInstallerLogger.installer.warning(
                    "GH latest JSON parse failed: \(error.localizedDescription, privacy: .public)"
                )
            }
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 6)
        return capturedTag
    }

    /// Compares two dotted decimal version strings (e.g. "0.2.10" vs "0.2.2").
    /// Returns -1 / 0 / +1. Missing components are treated as 0.
    private func compareSemver(_ left: String, _ right: String) -> Int {
        let leftParts = left.split(separator: ".").map { Int($0) ?? 0 }
        let rightParts = right.split(separator: ".").map { Int($0) ?? 0 }
        let count = max(leftParts.count, rightParts.count)
        for index in 0 ..< count {
            let leftValue = index < leftParts.count ? leftParts[index] : 0
            let rightValue = index < rightParts.count ? rightParts[index] : 0
            if leftValue < rightValue { return -1 }
            if leftValue > rightValue { return 1 }
        }
        return 0
    }

    // MARK: - Install flow

    private func runInstallWithModal(version: String, presentingWindow _: NSWindow?) throws -> LKInjectableFrameworkInstallation {
        precondition(Thread.isMainThread, "runInstallWithModal must run on the main thread")

        let cancellation = LKInstallerCancellation()
        let controller = LKInstallerProgressWindowController(
            title: NSLocalizedString("Downloading LookInside Server Framework", comment: ""),
            initialStatus: LKInjectableFrameworkInstallerStage.preparing.localizedDescription
        )
        var cancelledByUser = false
        controller.onCancel = {
            cancelledByUser = true
            cancellation.cancel()
            NSApp.stopModal()
        }
        controller.showWindow(self)

        var captured: Result<LKInjectableFrameworkInstallation, Error>!
        let semaphore = DispatchSemaphore(value: 0)

        Thread.detachNewThread {
            do {
                let installation = try self.performInstall(version: version, cancellation: cancellation) { stage in
                    DispatchQueue.main.async {
                        controller.updateStatus(stage.localizedDescription)
                    }
                }
                captured = .success(installation)
            } catch {
                captured = .failure(error)
            }
            DispatchQueue.main.async {
                NSApp.stopModal()
                semaphore.signal()
            }
        }

        NSApp.runModal(for: controller.window!)
        let waitResult = semaphore.wait(timeout: .now() + 5)
        controller.close()

        if cancelledByUser {
            throw LKInjectableFrameworkInstallerError.cancelled
        }
        if waitResult == .timedOut {
            cancellation.cancel()
            throw LKInjectableFrameworkInstallerError.cancelled
        }
        return try captured.get()
    }

    private func performInstall(
        version: String,
        cancellation: LKInstallerCancellation,
        onStage: @escaping (LKInjectableFrameworkInstallerStage) -> Void
    ) throws -> LKInjectableFrameworkInstallation {
        do {
            try cancellation.checkCancellation()
            onStage(.preparing)
            let fileManager = FileManager.default
            let stagingRoot = fileManager.temporaryDirectory
                .appendingPathComponent("LookInsideServerFramework-\(UUID().uuidString)", isDirectory: true)
            try fileManager.createDirectory(at: stagingRoot, withIntermediateDirectories: true)
            defer {
                try? fileManager.removeItem(at: stagingRoot)
            }

            try cancellation.checkCancellation()
            onStage(.downloading)
            let zipURL = stagingRoot.appendingPathComponent("server.xcframework.zip", isDirectory: false)
            try LKInstallerDownloader.download(
                from: LKInjectableFrameworkInstallerLayout.assetDownloadURL(for: version),
                to: zipURL,
                cancellation: cancellation,
                timeout: 120,
                errorBuilder: { LKInjectableFrameworkInstallerError.downloadFailed($0) }
            )

            try cancellation.checkCancellation()
            onStage(.extracting)
            let extractDir = stagingRoot.appendingPathComponent("extracted", isDirectory: true)
            try fileManager.createDirectory(at: extractDir, withIntermediateDirectories: true)
            try LKInstallerArchiveExtractor.unzip(
                zipURL,
                into: extractDir,
                cancellation: cancellation,
                errorBuilder: { LKInjectableFrameworkInstallerError.unzipFailed($0) }
            )

            try cancellation.checkCancellation()
            let stagedFramework = try locateMacFramework(in: extractDir)

            onStage(.verifying)
            try verifyTeamIdentifier(of: stagedFramework)

            try cancellation.checkCancellation()
            onStage(.installing)
            let destinationDir = LKInjectableFrameworkInstallerLayout.versionDirectoryURL(for: version)
            let destinationFramework = LKInjectableFrameworkInstallerLayout.installedFrameworkURL(for: version)
            try fileManager.createDirectory(
                at: destinationDir,
                withIntermediateDirectories: true
            )
            if fileManager.fileExists(atPath: destinationFramework.path) {
                try fileManager.removeItem(at: destinationFramework)
            }
            do {
                try fileManager.moveItem(at: stagedFramework, to: destinationFramework)
            } catch {
                throw LKInjectableFrameworkInstallerError.installFailed(error.localizedDescription)
            }

            try cancellation.checkCancellation()
            onStage(.finishing)
            try verifyTeamIdentifier(of: destinationFramework)

            LKInstallerLogger.installer.info(
                "injectable framework installed version=\(version, privacy: .public) path=\(destinationFramework.path, privacy: .public)"
            )
            return LKInjectableFrameworkInstallation(version: version, frameworkURL: destinationFramework)
        } catch is LKInstallerCancelled {
            throw LKInjectableFrameworkInstallerError.cancelled
        }
    }

    /// Walks the extracted directory looking for
    /// `LookInsideServer.xcframework/macos-*/LookInsideServer.framework`.
    /// The exact mac slice folder is matched by prefix `macos-` so we keep
    /// working if Apple ever changes the arch suffix.
    private func locateMacFramework(in directory: URL) throws -> URL {
        let fileManager = FileManager.default
        let xcframework = directory
            .appendingPathComponent(LKInjectableFrameworkInstallerLayout.xcframeworkBundleName, isDirectory: true)

        var searchRoots: [URL] = []
        if fileManager.fileExists(atPath: xcframework.path) {
            searchRoots.append(xcframework)
        }
        if let topLevel = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            for entry in topLevel where entry.pathExtension == "xcframework" {
                searchRoots.append(entry)
            }
        }

        for root in searchRoots {
            guard let children = try? fileManager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else {
                continue
            }
            for slice in children where slice.lastPathComponent.hasPrefix("macos-") {
                let framework = slice
                    .appendingPathComponent(LKInjectableFrameworkInstallerLayout.frameworkBundleName, isDirectory: true)
                if fileManager.fileExists(atPath: framework.path) {
                    return framework
                }
            }
        }

        throw LKInjectableFrameworkInstallerError.xcframeworkSliceNotFound
    }
}
