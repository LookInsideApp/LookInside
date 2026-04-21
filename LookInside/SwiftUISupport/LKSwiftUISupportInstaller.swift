import AppKit
import CryptoKit
import Foundation
import Security

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
            return "Failed to download LookInside Auth Server.\n\(message)"
        case let .unzipFailed(message):
            return "Failed to extract LookInside Auth Server.\n\(message)"
        case let .checksumFailed(message):
            return "Failed to verify LookInside Auth Server download.\n\(message)"
        case .appBundleNotFound:
            return "The downloaded archive did not contain a LookInside Auth Server bundle."
        case let .teamIdentifierUnavailable(message):
            return "Unable to read the code signature of LookInside Auth Server.\n\(message)"
        case let .teamIdentifierMismatch(expected, found):
            return "LookInside Auth Server is signed by a different team.\nExpected: \(expected)\nFound: \(found)"
        case let .installFailed(message):
            return "Failed to install LookInside Auth Server.\n\(message)"
        case .cancelled:
            return "Installation was cancelled."
        }
    }
}

enum LKSwiftUISupportInstallerStage: String {
    case preparing = "Preparing…"
    case downloading = "Downloading…"
    case extracting = "Extracting…"
    case verifying = "Verifying code signature…"
    case installing = "Installing…"
    case finishing = "Finalizing…"
}

enum LKSwiftUISupportInstallerLayout {
    static let appBundleName = "lookinside-auth-server.app"
    static let executableLeafName = "lookinside-auth-server"
    static let installParentRelativePath = "Library/Application Support/LookInside/AuthServer/current"
    static let socketRelativePath = "Library/Application Support/LookInside/AuthServer/run/lookinside-auth-server.sock"

    static let downloadURL = URL(string: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/lookinside-auth-server.app.zip")!
    static let checksumURL = URL(string: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/lookinside-auth-server.app.zip.sha256")!
    static let versionURL = URL(string: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/lookinside-auth-server.app.zip.version")!

    static var installedAppURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
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
}

final class LKSwiftUISupportInstaller {
    static let shared = LKSwiftUISupportInstaller()

    private let installLock = NSLock()
    private let cacheLock = NSLock()
    private var cachedPublishedVersion: String?

    func ensureInstalled(presentingWindow: NSWindow?) throws {
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

    func installedHelperVersion() -> String? {
        let plistURL = LKSwiftUISupportInstallerLayout.installedInfoPlistURL
        guard FileManager.default.fileExists(atPath: plistURL.path),
              let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let value = plist["CFBundleShortVersionString"] as? String,
              value.isEmpty == false else {
            return nil
        }
        return value
    }

    func fetchPublishedVersion() -> String? {
        if let cached = cacheLock.lkLock({ cachedPublishedVersion }) {
            return cached
        }
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
                  (200...299).contains(httpResponse.statusCode),
                  let data else {
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
        if let capturedVersion {
            cacheLock.lkLock { cachedPublishedVersion = capturedVersion }
        }
        return capturedVersion
    }

    func invalidatePublishedVersionCache() {
        cacheLock.lkLock { cachedPublishedVersion = nil }
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

    private func runInstallWithModal(presentingWindow _: NSWindow?) throws {
        assert(Thread.isMainThread, "Installer must be invoked on the main thread.")
        installLock.lock()
        defer { installLock.unlock() }

        if LKSwiftUISupportInstallerLayout.isInstalled {
            try verifyTeamIdentifier(of: LKSwiftUISupportInstallerLayout.installedAppURL)
            return
        }

        let controller = LKSwiftUISupportInstallerWindowController()
        controller.showWindow(self)

        var capturedError: Error?
        let semaphore = DispatchSemaphore(value: 0)

        Thread.detachNewThread {
            do {
                try self.performInstall { stage in
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
        _ = semaphore.wait(timeout: .now() + 1)
        controller.close()

        if let capturedError {
            throw capturedError
        }
    }

    private func performInstall(onStage: @escaping (LKSwiftUISupportInstallerStage) -> Void) throws {
        onStage(.preparing)
        let fileManager = FileManager.default
        let stagingRoot = fileManager.temporaryDirectory
            .appendingPathComponent("LookInsideAuthServer-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: stagingRoot, withIntermediateDirectories: true)
        defer {
            try? fileManager.removeItem(at: stagingRoot)
        }

        onStage(.downloading)
        let zipURL = stagingRoot.appendingPathComponent("helper.zip", isDirectory: false)
        let checksumURL = stagingRoot.appendingPathComponent("helper.zip.sha256", isDirectory: false)
        try downloadSynchronously(from: LKSwiftUISupportInstallerLayout.downloadURL, to: zipURL)
        try downloadSynchronously(from: LKSwiftUISupportInstallerLayout.checksumURL, to: checksumURL)

        onStage(.verifying)
        try Self.verifyChecksum(of: zipURL, using: checksumURL)

        onStage(.extracting)
        let extractDir = stagingRoot.appendingPathComponent("extracted", isDirectory: true)
        try fileManager.createDirectory(at: extractDir, withIntermediateDirectories: true)
        try unzip(zipURL, into: extractDir)

        let stagedApp = try Self.findAppBundle(in: extractDir)

        onStage(.verifying)
        try verifyTeamIdentifier(of: stagedApp)

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

        onStage(.finishing)
        try Self.ensureExecutableBit(at: LKSwiftUISupportInstallerLayout.installedExecutableURL)
        try verifyTeamIdentifier(of: destination)
    }

    private func downloadSynchronously(from url: URL, to destination: URL) throws {
        var capturedError: Error?
        var capturedTempURL: URL?
        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            defer { semaphore.signal() }
            if let error {
                capturedError = LKSwiftUISupportInstallerError.downloadFailed(error.localizedDescription)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                capturedError = LKSwiftUISupportInstallerError.downloadFailed("No response received.")
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                capturedError = LKSwiftUISupportInstallerError.downloadFailed("HTTP \(httpResponse.statusCode)")
                return
            }
            guard let tempURL else {
                capturedError = LKSwiftUISupportInstallerError.downloadFailed("Empty download payload.")
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
        task.resume()
        semaphore.wait()

        if let capturedError {
            throw capturedError
        }
        guard capturedTempURL != nil else {
            throw LKSwiftUISupportInstallerError.downloadFailed("Unknown download failure.")
        }
    }

    private func unzip(_ zipURL: URL, into destination: URL) throws {
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
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8) ?? "ditto exited with status \(process.terminationStatus)."
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
            throw LKSwiftUISupportInstallerError.installFailed("Executable not found at \(url.path)")
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
            throw LKSwiftUISupportInstallerError.checksumFailed("The release checksum file is malformed.")
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
            throw LKSwiftUISupportInstallerError.checksumFailed("Expected \(expected), got \(actual).")
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

final class LKSwiftUISupportInstallerWindowController: NSWindowController {
    private let statusLabel = NSTextField(labelWithString: LKSwiftUISupportInstallerStage.preparing.rawValue)
    private let progressIndicator = NSProgressIndicator()

    init() {
        let contentRect = NSRect(x: 0, y: 0, width: 360, height: 140)
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.title = "LookInside"
        window.isReleasedWhenClosed = false
        window.center()
        window.level = .modalPanel

        super.init(window: window)

        let titleLabel = NSTextField(labelWithString: "Installing LookInside Auth Server")
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
        statusLabel.stringValue = stage.rawValue
    }
}
