// CoreAnimationArchiveDefaultApplication.swift
//
// Which app opens Core Animation archives, and making LookInside that app.
//
// Dump Layer opens its archive in the type's default app. Where nothing else
// declares the type, that is LookInside without any setting. Where Apple's
// Mica is installed, Mica declares the type as its owner and wins, so the
// Settings window offers to make LookInside the default instead — the same
// change Finder's "Open With > Change All…" makes.

import AppKit
import Foundation
import Observation
import UniformTypeIdentifiers

/// The two Launch Services calls the setting needs, so tests can stand in for
/// the system's own default-app table.
@MainActor
protocol DefaultApplicationWorkspace {
    func urlForApplication(toOpen contentType: UTType) -> URL?
    func makingDefaultApplication(at applicationURL: URL, toOpen contentType: UTType) async throws
}

extension NSWorkspace: DefaultApplicationWorkspace {
    func makingDefaultApplication(at applicationURL: URL, toOpen contentType: UTType) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            setDefaultApplication(at: applicationURL, toOpen: contentType) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

@MainActor
@Observable
final class CoreAnimationArchiveDefaultApplication {
    /// Who opens Core Animation archives right now.
    enum Handler: Equatable {
        case lookInside
        /// Another app, by its display name.
        case otherApplication(name: String)
        /// Nothing is registered for the type.
        case none
    }

    static let contentType = UTType(importedAs: CoreAnimationArchive.typeIdentifier, conformingTo: .data)

    private(set) var handler: Handler = .none
    /// True while a change is being made, so it cannot be asked for twice.
    private(set) var isChanging = false

    @ObservationIgnored private let workspace: DefaultApplicationWorkspace
    @ObservationIgnored private let applicationURL: URL
    @ObservationIgnored private let applicationBundleIdentifier: String?

    init(
        workspace: DefaultApplicationWorkspace = NSWorkspace.shared,
        applicationURL: URL = Bundle.main.bundleURL,
        applicationBundleIdentifier: String? = Bundle.main.bundleIdentifier
    ) {
        self.workspace = workspace
        self.applicationURL = applicationURL
        self.applicationBundleIdentifier = applicationBundleIdentifier
        refresh()
    }

    /// Reads the current default again; it can change in Finder at any time.
    func refresh() {
        guard let handlerURL = workspace.urlForApplication(toOpen: Self.contentType) else {
            handler = .none
            return
        }
        handler = isThisApplication(handlerURL) ? .lookInside : .otherApplication(name: Self.displayName(of: handlerURL))
    }

    /// Makes LookInside the default app for Core Animation archives.
    func makeLookInsideTheDefault() async throws {
        guard !isChanging else { return }
        isChanging = true
        defer {
            isChanging = false
            refresh()
        }
        try await workspace.makingDefaultApplication(at: applicationURL, toOpen: Self.contentType)
    }

    /// Another copy of LookInside — a release build next to a debug one —
    /// counts as LookInside: any of them opens the archive the same way.
    private func isThisApplication(_ handlerURL: URL) -> Bool {
        if let applicationBundleIdentifier,
           let handlerBundleIdentifier = Bundle(url: handlerURL)?.bundleIdentifier
        {
            return handlerBundleIdentifier == applicationBundleIdentifier
        }
        return handlerURL.standardizedFileURL.resolvingSymlinksInPath()
            == applicationURL.standardizedFileURL.resolvingSymlinksInPath()
    }

    private static func displayName(of applicationURL: URL) -> String {
        let displayName = FileManager.default.displayName(atPath: applicationURL.path)
        return displayName.hasSuffix(".app") ? String(displayName.dropLast(4)) : displayName
    }
}
