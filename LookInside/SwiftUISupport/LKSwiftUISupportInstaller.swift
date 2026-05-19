import AppKit
import CryptoKit
import Foundation
import Security

private extension NSLock {
    func withLock<T>(_ work: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try work()
    }
}

enum LKSwiftUISupportInstallerError: LocalizedError {
    case downloadFailed(String)
    case unzipFailed(String)
    case checksumFailed(String)
    case appBundleNotFound
    case teamIdentifierUnavailable(String)
    case teamIdentifierMismatch(expected: String, found: String)
    case installFailed(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case let .downloadFailed(message):
            return String(format: NSLocalizedString("Failed to download LookInside Auth Server.\n%@", comment: ""), message)
        case let .unzipFailed(message):
            return String(format: NSLocalizedString("Failed to extract LookInside Auth Server.\n%@", comment: ""), message)
        case let .checksumFailed(message):
            return String(format: NSLocalizedString("Failed to verify LookInside Auth Server download.\n%@", comment: ""), message)
        case .appBundleNotFound:
            return NSLocalizedString("The downloaded archive did not contain a LookInside Auth Server bundle.", comment: "")
        case let .teamIdentifierUnavailable(message):
            return String(format: NSLocalizedString("Unable to read the code signature of LookInside Auth Server.\n%@", comment: ""), message)
        case let .teamIdentifierMismatch(expected, found):
            return String(format: NSLocalizedString("LookInside Auth Server is signed by a different team.\nExpected: %1$@\nFound: %2$@", comment: ""), expected, found)
        case let .installFailed(message):
            return String(format: NSLocalizedString("Failed to install LookInside Auth Server.\n%@", comment: ""), message)
        case .cancelled:
            return NSLocalizedString("Installation was cancelled.", comment: "")
        }
    }
}

enum LKSwiftUISupportInstallerStage: String {
    case preparing = "Preparing…"
    case checkingForUpdates = "Checking for updates…"
    case downloading = "Downloading…"
    case extracting = "Extracting…"
    case verifying = "Verifying code signature…"
    case installing = "Installing…"
    case finishing = "Finalizing…"

    var localizedDescription: String {
        switch self {
        case .preparing:
            return NSLocalizedString("Preparing…", comment: "")
        case .checkingForUpdates:
            return NSLocalizedString("Checking for updates…", comment: "")
        case .downloading:
            return NSLocalizedString("Downloading…", comment: "")
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

final class LKSwiftUISupportInstallerCancellation {
    private let lock = NSLock()
    private var cancelled = false
    private weak var downloadTask: URLSessionDownloadTask?
    private weak var unzipProcess: Process?

    var isCancelled: Bool {
        lock.withLock { cancelled }
    }

    func cancel() {
        let task: URLSessionDownloadTask?
        let process: Process?
        lock.lock()
        cancelled = true
        task = downloadTask
        process = unzipProcess
        lock.unlock()

        task?.cancel()
        if process?.isRunning == true {
            process?.terminate()
        }
    }

    func register(downloadTask task: URLSessionDownloadTask?) {
        let shouldCancel = lock.withLock {
            downloadTask = task
            return cancelled
        }
        if shouldCancel {
            task?.cancel()
        }
    }

    func register(unzipProcess process: Process?) {
        let shouldCancel = lock.withLock {
            unzipProcess = process
            return cancelled
        }
        if shouldCancel, process?.isRunning == true {
            process?.terminate()
        }
    }

    func checkCancellation() throws {
        if isCancelled {
            throw LKSwiftUISupportInstallerError.cancelled
        }
    }
}

enum LKSwiftUISupportInstallerLayout {
    static let appBundleName = "lookinside-auth-server.app"
    static let executableLeafName = "lookinside-auth-server"
    static let installParentRelativePath = "Library/Application Support/LookInside/AuthServer/current"
    static let socketRelativePath = "Library/Application Support/LookInside/AuthServer/run/lookinside-auth-server.sock"

    static let downloadURL = URL(string: "https://lookinside-app.com/downloads/auth-server/lookinside-auth-server.app.zip")!
    static let checksumURL = URL(string: "https://lookinside-app.com/downloads/auth-server/lookinside-auth-server.app.zip.sha256")!
    static let versionURL = URL(string: "https://lookinside-app.com/downloads/auth-server/lookinside-auth-server.app.zip.version")!

    static var installedAppURL: URL {
        #if DEBUG
            if debugLocalAuthRepositoryURL != nil {
                return debugInstalledAppURL
            }
        #endif

        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(installParentRelativePath, isDirectory: true)
            .appendingPathComponent(appBundleName, isDirectory: true)
    }

    static var installedExecutableURL: URL {
        installedAppURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("MacOS", isDirectory: true)
            .appendingPathComponent(executableLeafName, isDirectory: false)
    }

    static var installedSocketURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(socketRelativePath, isDirectory: false)
    }

    static var isInstalled: Bool {
        FileManager.default.isExecutableFile(atPath: installedExecutableURL.path)
    }

    static var installedInfoPlistURL: URL {
        installedAppURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Info.plist", isDirectory: false)
    }

    #if DEBUG
        static var debugInstalledAppURL: URL {
            URL(fileURLWithPath: "/tmp", isDirectory: true)
                .appendingPathComponent("lookinside-auth-server-debug", isDirectory: true)
                .appendingPathComponent("current", isDirectory: true)
                .appendingPathComponent(appBundleName, isDirectory: true)
        }

        static var debugLocalAuthRepositoryURL: URL? {
            let fileManager = FileManager.default
            let searchRoots = [
                URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true),
                Bundle.main.bundleURL,
                URL(fileURLWithPath: #filePath, isDirectory: false).deletingLastPathComponent(),
            ]

            for root in searchRoots {
                if let monorepoRoot = findMonorepoRoot(startingAt: root) {
                    let authRepositoryURL = monorepoRoot.appendingPathComponent("LookInside-Auth", isDirectory: true)
                    let projectURL = authRepositoryURL.appendingPathComponent("Project.swift", isDirectory: false)
                    if fileManager.fileExists(atPath: projectURL.path) {
                        return authRepositoryURL
                    }
                }
            }

            return nil
        }

        private static func findMonorepoRoot(startingAt startURL: URL) -> URL? {
            let fileManager = FileManager.default
            var cursor = startURL.standardizedFileURL
            if cursor.hasDirectoryPath == false {
                cursor.deleteLastPathComponent()
            }

            for _ in 0 ..< 12 {
                let gitmodulesURL = cursor.appendingPathComponent(".gitmodules", isDirectory: false)
                let authRepositoryURL = cursor.appendingPathComponent("LookInside-Auth", isDirectory: true)
                if fileManager.fileExists(atPath: gitmodulesURL.path),
                   fileManager.fileExists(atPath: authRepositoryURL.path)
                {
                    return cursor
                }

                let parent = cursor.deletingLastPathComponent()
                guard parent.path != cursor.path else { break }
                cursor = parent
            }

            return nil
        }
    #endif
}

final class LKSwiftUISupportInstaller {
    static let shared = LKSwiftUISupportInstaller()

    private let installLock = NSLock()
    private let cacheLock = NSLock()
    private var cachedPublishedVersion: String?
    private var lastFailedFetchAt: Date?
    private var lastFailedBackgroundInstallAt: Date?
    private static let failedFetchCooldown: TimeInterval = 30
    private static let failedBackgroundInstallCooldown: TimeInterval = 300
    #if DEBUG
        private var debugLocalInstallPrepared = false
    #endif

    func ensureInstalled(presentingWindow: NSWindow?) throws {
        #if DEBUG
            if LKSwiftUISupportInstallerLayout.debugLocalAuthRepositoryURL != nil {
                try ensureDebugLocalInstall()
                return
            }
        #endif

        if LKSwiftUISupportInstallerLayout.isInstalled {
            let installed = installedHelperVersion()
            let published = fetchPublishedVersion()
            if let published, let installed, published != installed {
                LKSwiftUISupportLogger.installer.notice(
                    "installed helper is stale installed=\(installed, privacy: .public) published=\(published, privacy: .public) action=refresh"
                )
                invalidate()
                try runInstallWithModal(presentingWindow: presentingWindow)
                return
            }
            if published == nil {
                LKSwiftUISupportLogger.installer.warning(
                    "published version unavailable; keeping cached helper installed=\(installed ?? "unknown", privacy: .public)"
                )
            }
            try verifyTeamIdentifier(of: LKSwiftUISupportInstallerLayout.installedAppURL)
            return
        }
        try runInstallWithModal(presentingWindow: presentingWindow)
    }

    func ensureInstalledWithoutUserInteraction() throws {
        #if DEBUG
            if LKSwiftUISupportInstallerLayout.debugLocalAuthRepositoryURL != nil {
                try ensureDebugLocalInstall()
                return
            }
        #endif

        try enforceBackgroundInstallCooldown()
        do {
            try ensureInstalledForBackgroundRefresh()
            cacheLock.lkLock {
                lastFailedBackgroundInstallAt = nil
            }
        } catch {
            cacheLock.lkLock {
                lastFailedBackgroundInstallAt = Date()
            }
            throw error
        }
    }

    #if DEBUG
        private func ensureDebugLocalInstall() throws {
            installLock.lock()
            defer { installLock.unlock() }

            if debugLocalInstallPrepared, LKSwiftUISupportInstallerLayout.isInstalled {
                return
            }

            let destination = LKSwiftUISupportInstallerLayout.debugInstalledAppURL
            guard FileManager.default.isExecutableFile(atPath: LKSwiftUISupportInstallerLayout.installedExecutableURL.path) else {
                throw LKSwiftUISupportInstallerError.installFailed(
                    "Debug auth server app is missing. Build the LookInside Debug target again to prepare \(destination.path)."
                )
            }
            try Self.ensureExecutableBit(at: LKSwiftUISupportInstallerLayout.installedExecutableURL)
            debugLocalInstallPrepared = true
            invalidatePublishedVersionCache()
            LKSwiftUISupportLogger.installer.notice(
                "debug auth server app ready destination=\(destination.path, privacy: .public)"
            )
        }
    #endif

    func installedHelperVersion() -> String? {
        let plistURL = LKSwiftUISupportInstallerLayout.installedInfoPlistURL
        guard FileManager.default.fileExists(atPath: plistURL.path),
              let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let value = plist["CFBundleShortVersionString"] as? String,
              value.isEmpty == false
        else {
            return nil
        }
        return value
    }

    func fetchPublishedVersion() -> String? {
        let cachedState: (version: String?, cooldownActive: Bool) = cacheLock.lkLock {
            let cooldown: Bool
            if let lastFailedFetchAt {
                cooldown = Date().timeIntervalSince(lastFailedFetchAt) < Self.failedFetchCooldown
            } else {
                cooldown = false
            }
            return (cachedPublishedVersion, cooldown)
        }
        if let cached = cachedState.version {
            return cached
        }
        if cachedState.cooldownActive {
            return nil
        }
        if Thread.isMainThread {
            return fetchPublishedVersionPresentingProgress()
        }
        return fetchPublishedVersionFromNetwork()
    }

    func publishedVersionFromCache() -> String? {
        cacheLock.lkLock { cachedPublishedVersion }
    }

    private func fetchPublishedVersionPresentingProgress() -> String? {
        let controller = LKSwiftUISupportInstallerWindowController(
            title: NSLocalizedString("Checking LookInside Auth Server", comment: "")
        )
        controller.updateStage(.checkingForUpdates)
        controller.showWindow(self)

        var capturedVersion: String?
        let semaphore = DispatchSemaphore(value: 0)
        Thread.detachNewThread {
            capturedVersion = self.fetchPublishedVersionFromNetwork()
            DispatchQueue.main.async {
                NSApp.stopModal()
                semaphore.signal()
            }
        }
        NSApp.runModal(for: controller.window!)
        _ = semaphore.wait(timeout: .now() + 1)
        controller.close()
        return capturedVersion
    }

    private func fetchPublishedVersionFromNetwork() -> String? {
        var capturedVersion: String?
        let semaphore = DispatchSemaphore(value: 0)
        var request = URLRequest(url: LKSwiftUISupportInstallerLayout.versionURL)
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            if let error {
                LKSwiftUISupportLogger.installer.warning(
                    "version fetch failed: \(error.localizedDescription, privacy: .public)"
                )
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200 ... 299).contains(httpResponse.statusCode),
                  let data
            else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                LKSwiftUISupportLogger.installer.warning(
                    "version fetch returned status=\(status)"
                )
                return
            }
            let trimmed = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            capturedVersion = (trimmed?.isEmpty == false) ? trimmed : nil
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 6)
        cacheLock.lkLock {
            if let capturedVersion {
                cachedPublishedVersion = capturedVersion
                lastFailedFetchAt = nil
            } else {
                lastFailedFetchAt = Date()
            }
        }
        return capturedVersion
    }

    func invalidatePublishedVersionCache() {
        cacheLock.lkLock {
            cachedPublishedVersion = nil
            lastFailedFetchAt = nil
        }
    }

    func invalidate() {
        invalidatePublishedVersionCache()
        let url = LKSwiftUISupportInstallerLayout.installedAppURL
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
                LKSwiftUISupportLogger.installer.info(
                    "invalidated cached helper at \(url.path, privacy: .public)"
                )
            }
        } catch {
            LKSwiftUISupportLogger.installer.error(
                "invalidate failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func verifyTeamIdentifier(of appURL: URL) throws {
        let helperTeamID = try Self.teamIdentifier(atPath: appURL.path)
        let hostTeamID = try? Self.teamIdentifier(atPath: Bundle.main.bundlePath)
        guard let hostTeamID, hostTeamID.isEmpty == false else {
            LKSwiftUISupportLogger.installer.info(
                "host has no Team Identifier; skipping helper Team Identifier check (dev build)"
            )
            return
        }
        guard hostTeamID == helperTeamID else {
            throw LKSwiftUISupportInstallerError.teamIdentifierMismatch(expected: hostTeamID, found: helperTeamID)
        }
    }

    private func runInstallWithModal(presentingWindow: NSWindow?) throws {
        if !Thread.isMainThread {
            var capturedError: Error?
            DispatchQueue.main.sync {
                do {
                    try self.runInstallWithModal(presentingWindow: presentingWindow)
                } catch {
                    capturedError = error
                }
            }
            if let capturedError { throw capturedError }
            return
        }
        installLock.lock()
        defer { installLock.unlock() }

        if LKSwiftUISupportInstallerLayout.isInstalled {
            try verifyTeamIdentifier(of: LKSwiftUISupportInstallerLayout.installedAppURL)
            return
        }

        let cancellation = LKSwiftUISupportInstallerCancellation()
        let controller = LKSwiftUISupportInstallerWindowController()
        var cancelledByUser = false
        controller.onCancel = {
            cancelledByUser = true
            cancellation.cancel()
            NSApp.stopModal()
        }
        controller.showWindow(self)

        var capturedError: Error?
        let semaphore = DispatchSemaphore(value: 0)

        Thread.detachNewThread {
            do {
                try self.performInstall(cancellation: cancellation) { stage in
                    DispatchQueue.main.async {
                        controller.updateStage(stage)
                    }
                }
            } catch {
                capturedError = error
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
            throw LKSwiftUISupportInstallerError.cancelled
        }
        if waitResult == .timedOut {
            cancellation.cancel()
            throw LKSwiftUISupportInstallerError.cancelled
        }
        if let capturedError {
            throw capturedError
        }
    }

    private func enforceBackgroundInstallCooldown() throws {
        let cooldownActive: Bool = cacheLock.lkLock {
            guard let lastFailedBackgroundInstallAt else {
                return false
            }
            return Date().timeIntervalSince(lastFailedBackgroundInstallAt) < Self.failedBackgroundInstallCooldown
        }
        guard cooldownActive == false else {
            throw LKSwiftUISupportInstallerError.installFailed(
                NSLocalizedString("Background Auth Server install is waiting after a recent failure.", comment: "")
            )
        }
    }

    private func ensureInstalledForBackgroundRefresh() throws {
        precondition(Thread.isMainThread == false, "Background Auth Server install must run off the main thread.")

        installLock.lock()
        defer { installLock.unlock() }

        if LKSwiftUISupportInstallerLayout.isInstalled {
            let installed = installedHelperVersion()
            let published = fetchPublishedVersion()
            if let published, let installed, published != installed {
                LKSwiftUISupportLogger.installer.notice(
                    "installed helper is stale installed=\(installed, privacy: .public) published=\(published, privacy: .public) action=background-refresh"
                )
                invalidate()
            } else {
                if published == nil {
                    LKSwiftUISupportLogger.installer.warning(
                        "published version unavailable; keeping cached helper installed=\(installed ?? "unknown", privacy: .public)"
                    )
                }
                try verifyTeamIdentifier(of: LKSwiftUISupportInstallerLayout.installedAppURL)
                return
            }
        }

        let cancellation = LKSwiftUISupportInstallerCancellation()
        try performInstall(cancellation: cancellation) { stage in
            LKSwiftUISupportLogger.installer.info(
                "background install stage=\(stage.rawValue, privacy: .public)"
            )
        }
    }

    private func performInstall(
        cancellation: LKSwiftUISupportInstallerCancellation,
        onStage: @escaping (LKSwiftUISupportInstallerStage) -> Void
    ) throws {
        try cancellation.checkCancellation()
        onStage(.preparing)
        let fileManager = FileManager.default
        let stagingRoot = fileManager.temporaryDirectory
            .appendingPathComponent("LookInsideAuthServer-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: stagingRoot, withIntermediateDirectories: true)
        defer {
            try? fileManager.removeItem(at: stagingRoot)
        }

        try cancellation.checkCancellation()
        onStage(.downloading)
        let zipURL = stagingRoot.appendingPathComponent("helper.zip", isDirectory: false)
        let checksumURL = stagingRoot.appendingPathComponent("helper.zip.sha256", isDirectory: false)
        try downloadSynchronously(from: LKSwiftUISupportInstallerLayout.downloadURL, to: zipURL, cancellation: cancellation)
        try downloadSynchronously(from: LKSwiftUISupportInstallerLayout.checksumURL, to: checksumURL, cancellation: cancellation)

        try cancellation.checkCancellation()
        onStage(.verifying)
        try Self.verifyChecksum(of: zipURL, using: checksumURL)

        try cancellation.checkCancellation()
        onStage(.extracting)
        let extractDir = stagingRoot.appendingPathComponent("extracted", isDirectory: true)
        try fileManager.createDirectory(at: extractDir, withIntermediateDirectories: true)
        try unzip(zipURL, into: extractDir, cancellation: cancellation)

        try cancellation.checkCancellation()
        let stagedApp = try Self.findAppBundle(in: extractDir)

        onStage(.verifying)
        try verifyTeamIdentifier(of: stagedApp)

        try cancellation.checkCancellation()
        onStage(.installing)
        let destination = LKSwiftUISupportInstallerLayout.installedAppURL
        try fileManager.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        do {
            try fileManager.moveItem(at: stagedApp, to: destination)
        } catch {
            throw LKSwiftUISupportInstallerError.installFailed(error.localizedDescription)
        }

        try cancellation.checkCancellation()
        onStage(.finishing)
        try Self.ensureExecutableBit(at: LKSwiftUISupportInstallerLayout.installedExecutableURL)
        try verifyTeamIdentifier(of: destination)
    }

    private func downloadSynchronously(
        from url: URL,
        to destination: URL,
        cancellation: LKSwiftUISupportInstallerCancellation
    ) throws {
        try cancellation.checkCancellation()
        var capturedError: Error?
        var capturedTempURL: URL?
        let semaphore = DispatchSemaphore(value: 0)

        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let task = URLSession.shared.downloadTask(with: request) { tempURL, response, error in
            defer { semaphore.signal() }
            if let error {
                if cancellation.isCancelled || (error as NSError).code == NSURLErrorCancelled {
                    capturedError = LKSwiftUISupportInstallerError.cancelled
                } else {
                    capturedError = LKSwiftUISupportInstallerError.downloadFailed(error.localizedDescription)
                }
                return
            }
            guard cancellation.isCancelled == false else {
                capturedError = LKSwiftUISupportInstallerError.cancelled
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                capturedError = LKSwiftUISupportInstallerError.downloadFailed(
                    NSLocalizedString("No response received.", comment: "")
                )
                return
            }
            guard (200 ... 299).contains(httpResponse.statusCode) else {
                capturedError = LKSwiftUISupportInstallerError.downloadFailed("HTTP \(httpResponse.statusCode)")
                return
            }
            guard let tempURL else {
                capturedError = LKSwiftUISupportInstallerError.downloadFailed(
                    NSLocalizedString("Empty download payload.", comment: "")
                )
                return
            }
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: tempURL, to: destination)
                capturedTempURL = destination
            } catch {
                capturedError = LKSwiftUISupportInstallerError.downloadFailed(error.localizedDescription)
            }
        }
        cancellation.register(downloadTask: task)
        task.resume()
        semaphore.wait()
        cancellation.register(downloadTask: nil)

        try cancellation.checkCancellation()
        if let capturedError {
            throw capturedError
        }
        guard capturedTempURL != nil else {
            throw LKSwiftUISupportInstallerError.downloadFailed(
                NSLocalizedString("Unknown download failure.", comment: "")
            )
        }
    }

    private func unzip(
        _ zipURL: URL,
        into destination: URL,
        cancellation: LKSwiftUISupportInstallerCancellation
    ) throws {
        try cancellation.checkCancellation()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", zipURL.path, destination.path]
        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = Pipe()
        do {
            try process.run()
        } catch {
            throw LKSwiftUISupportInstallerError.unzipFailed(error.localizedDescription)
        }
        cancellation.register(unzipProcess: process)
        process.waitUntilExit()
        cancellation.register(unzipProcess: nil)
        try cancellation.checkCancellation()
        if process.terminationStatus != 0 {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)
                ?? String(format: NSLocalizedString("ditto exited with status %d.", comment: ""), process.terminationStatus)
            throw LKSwiftUISupportInstallerError.unzipFailed(message)
        }
    }

    private static func findAppBundle(in directory: URL) throws -> URL {
        let fileManager = FileManager.default
        let entries = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for entry in entries where entry.pathExtension == "app" {
            return entry
        }
        for entry in entries {
            var isDir: ObjCBool = false
            fileManager.fileExists(atPath: entry.path, isDirectory: &isDir)
            if isDir.boolValue {
                if let match = try? findAppBundle(in: entry) {
                    return match
                }
            }
        }
        throw LKSwiftUISupportInstallerError.appBundleNotFound
    }

    private static func ensureExecutableBit(at url: URL) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else {
            throw LKSwiftUISupportInstallerError.installFailed(
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

    private static func verifyChecksum(of zipURL: URL, using checksumURL: URL) throws {
        let checksumText: String
        do {
            checksumText = try String(contentsOf: checksumURL, encoding: .utf8)
        } catch {
            throw LKSwiftUISupportInstallerError.checksumFailed(error.localizedDescription)
        }

        guard let expected = checksumText
            .split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" })
            .first
            .map({ String($0).lowercased() }),
            expected.count == 64
        else {
            throw LKSwiftUISupportInstallerError.checksumFailed(
                NSLocalizedString("The release checksum file is malformed.", comment: "")
            )
        }

        let zipData: Data
        do {
            zipData = try Data(contentsOf: zipURL)
        } catch {
            throw LKSwiftUISupportInstallerError.checksumFailed(error.localizedDescription)
        }

        let actual = SHA256.hash(data: zipData)
            .map { String(format: "%02x", $0) }
            .joined()

        guard actual == expected else {
            throw LKSwiftUISupportInstallerError.checksumFailed(
                String(format: NSLocalizedString("Expected %1$@, got %2$@.", comment: ""), expected, actual)
            )
        }
    }

    private static func teamIdentifier(atPath path: String) throws -> String {
        let url = URL(fileURLWithPath: path)
        var staticCode: SecStaticCode?
        let createStatus = SecStaticCodeCreateWithPath(url as CFURL, [], &staticCode)
        guard createStatus == errSecSuccess, let staticCode else {
            throw LKSwiftUISupportInstallerError.teamIdentifierUnavailable("SecStaticCodeCreateWithPath failed (OSStatus \(createStatus)).")
        }

        let validateStatus = SecStaticCodeCheckValidity(staticCode, SecCSFlags(rawValue: 0), nil)
        guard validateStatus == errSecSuccess else {
            throw LKSwiftUISupportInstallerError.teamIdentifierUnavailable("Code signature validation failed (OSStatus \(validateStatus)).")
        }

        var infoRef: CFDictionary?
        let infoStatus = SecCodeCopySigningInformation(
            staticCode,
            SecCSFlags(rawValue: kSecCSSigningInformation),
            &infoRef
        )
        guard infoStatus == errSecSuccess, let info = infoRef as? [String: Any] else {
            throw LKSwiftUISupportInstallerError.teamIdentifierUnavailable("SecCodeCopySigningInformation failed (OSStatus \(infoStatus)).")
        }

        guard let teamID = info[kSecCodeInfoTeamIdentifier as String] as? String, teamID.isEmpty == false else {
            throw LKSwiftUISupportInstallerError.teamIdentifierUnavailable("Team identifier is missing from code signing information.")
        }
        return teamID
    }
}

final class LKSwiftUISupportInstallerWindowController: NSWindowController, NSWindowDelegate {
    private let statusLabel = NSTextField(labelWithString: LKSwiftUISupportInstallerStage.preparing.localizedDescription)
    private let progressIndicator = NSProgressIndicator()
    var onCancel: (() -> Void)?

    convenience init() {
        self.init(title: NSLocalizedString("Installing LookInside Auth Server", comment: ""))
    }

    init(title: String) {
        let contentRect = NSRect(x: 0, y: 0, width: 360, height: 140)
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "LookInside"
        window.isReleasedWhenClosed = false
        window.center()
        window.level = .modalPanel

        super.init(window: window)
        window.delegate = self

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.boldSystemFont(ofSize: 13)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.lineBreakMode = .byTruncatingTail

        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = true
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        container.addSubview(statusLabel)
        container.addSubview(progressIndicator)

        window.contentView = container

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            progressIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 14),
            progressIndicator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            progressIndicator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            progressIndicator.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -20),
        ])

        progressIndicator.startAnimation(nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
    }

    func updateStage(_ stage: LKSwiftUISupportInstallerStage) {
        statusLabel.stringValue = stage.localizedDescription
    }

    func windowShouldClose(_: NSWindow) -> Bool {
        onCancel?()
        return true
    }
}
