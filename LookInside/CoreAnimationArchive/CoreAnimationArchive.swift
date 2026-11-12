// CoreAnimationArchive.swift
//
// Reads a Core Animation archive: a `.caar` file, declared under the type
// `com.apple.coreanimation-archive`.
//
// The AppKit debug menu writes them. Its Dump Layer item encodes the chosen
// window's layer tree with QuartzCore's `CAEncodeLayerTree`, saves it to the
// dumped app's temporary directory and hands the file to whichever app opens
// the type (`-[NSWorkspace openFile:]`). Nothing in that hand-off names an
// app: Apple's internal Core Animation editor, Mica, receives it only because
// it declares the type, and declaring it here is what lets a Dump Layer open
// in the inspector instead.
//
// The archive is an NSKeyedArchiver archive whose `root` is the dictionary
// `{ "rootLayer": CALayer, "geometryFlipped": Bool }` — the payload an Xcode
// capture stores as `encodedPresentationLayer`. It is decoded through
// QuartzCore's own reader, `CAPackage`, and not through an unarchiver with
// secure coding switched off: such a file can come from anywhere, and
// `CAPackage` decodes against Core Animation's class allow-list
// (`+[NSCoder CA_supportedClasses]`). Where the archive names a class this
// process does not have — a layer subclass private to the app that was
// dumped — it substitutes the nearest superclass in the archived class chain
// that the allow-list accepts, so one custom layer does not cost the tree.

import AppKit
import Foundation
import QuartzCore

/// The layer tree a Core Animation archive holds.
struct CoreAnimationArchiveContents {
    let rootLayer: CALayer
    /// Whether the root layer's coordinate space was flipped where it was
    /// archived: its `contentsAreFlipped` at the time, which counts the flips
    /// of superlayers the archive does not contain.
    let isGeometryFlipped: Bool
}

enum CoreAnimationArchiveError: LocalizedError {
    /// This macOS has no `CAPackage`, or it no longer answers the selectors
    /// the reader relies on.
    case readerUnavailable
    /// The data is not an archive of a layer tree, or it holds classes that
    /// cannot be decoded here. The reason is for logs, not for display.
    case notALayerTree(reason: String?)

    var errorDescription: String? {
        NSLocalizedString(
            "LookInside could not read this Core Animation archive.",
            comment: "Alert shown when a .caar file (a Core Animation archive, as written by Dump Layer in the AppKit debug menu) cannot be opened."
        )
    }

    var recoverySuggestion: String? {
        NSLocalizedString(
            "The file may be damaged, or it may not hold a layer tree.",
            comment: "Explanation under the alert shown when a .caar file (a Core Animation archive) cannot be opened."
        )
    }

    var failureReason: String? {
        switch self {
        case .readerUnavailable:
            "QuartzCore's CAPackage is unavailable."
        case let .notALayerTree(reason):
            reason
        }
    }
}

enum CoreAnimationArchive {
    /// The type the archives are declared under (`kCAPackageTypeArchive`).
    static let typeIdentifier = "com.apple.coreanimation-archive"

    private enum Selectors {
        static let makingPackage = NSSelectorFromString("packageWithData:type:options:error:")
        static let rootLayer = NSSelectorFromString("rootLayer")
        static let isGeometryFlipped = NSSelectorFromString("isGeometryFlipped")
    }

    /// Decodes the layer tree `data` holds.
    ///
    /// Safe to call off the main thread; the layers it returns belong to no
    /// window and are not shown anywhere.
    static func decodingContents(of data: Data) throws -> CoreAnimationArchiveContents {
        guard let packageClass = NSClassFromString("CAPackage"),
              class_getClassMethod(packageClass, Selectors.makingPackage) != nil
        else { throw CoreAnimationArchiveError.readerUnavailable }
        let packageFactory = unsafeBitCast(packageClass as AnyObject, to: CoreAnimationPackageFactory.self)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        var package: NSObject?
        var packageError: Error?
        // A well-formed archive whose root is not a dictionary makes CAPackage
        // send it -objectForKey:, which raises rather than failing; any file
        // can arrive here, so a raise is a malformed file, not a crash.
        let exception = LookinCatchException {
            do {
                package = try packageFactory.makingPackage(with: data, type: typeIdentifier, options: nil)
            } catch {
                packageError = error
            }
        }
        if let exception {
            throw CoreAnimationArchiveError.notALayerTree(
                reason: "\(exception.name.rawValue): \(exception.reason ?? "no reason")"
            )
        }
        // CAPackage answers nil without filling in the error when the archive
        // holds no layer tree, so the error says little either way.
        guard let package else {
            throw CoreAnimationArchiveError.notALayerTree(reason: packageError.map { String(describing: $0) })
        }
        guard package.responds(to: Selectors.rootLayer), package.responds(to: Selectors.isGeometryFlipped) else {
            throw CoreAnimationArchiveError.readerUnavailable
        }
        let packageContents = unsafeBitCast(package, to: CoreAnimationPackage.self)
        guard let rootLayer = packageContents.rootLayer else {
            throw CoreAnimationArchiveError.notALayerTree(reason: "The archive has no root layer.")
        }
        return CoreAnimationArchiveContents(rootLayer: rootLayer, isGeometryFlipped: packageContents.isGeometryFlipped)
    }
}

// MARK: - CAPackage

/// The class side of QuartzCore's private `CAPackage`, declared by the
/// selectors it answers so it can be called without a header.
@objc private protocol CoreAnimationPackageFactory {
    @objc(packageWithData:type:options:error:)
    func makingPackage(with data: Data, type: String, options: [String: Any]?) throws -> NSObject
}

/// The instance side of `CAPackage`: what a decoded package exposes.
@objc private protocol CoreAnimationPackage {
    var rootLayer: CALayer? { get }
    @objc(isGeometryFlipped) var isGeometryFlipped: Bool { get }
}

// MARK: - File name

/// Where a Dump Layer archive came from, as its file name records it:
/// `<process name>-<pid>-<class>-<object address>-layer-<uptime>.caar`
/// (`-[NSWindow _dumpLayer]`, `-[NSView _dumpLayer]` and Mac Catalyst's
/// `-[UINSSceneView _dumpUIWindowLayers]` all use this format).
struct CoreAnimationArchiveOrigin: Equatable {
    let processName: String
    let processIdentifier: Int32
    /// The class of the dumped window or view, as `NSStringFromClass` spells it.
    let className: String
    /// The dumped object's address, as `%p` prints it.
    let objectAddress: String

    /// The process name may itself contain hyphens; a class name cannot, so
    /// the fields are matched from the end.
    private static let fileNamePattern = try? NSRegularExpression(
        pattern: "^(.+)-([0-9]+)-([^-]+)-(0x[0-9a-fA-F]+)-layer-[0-9]+$"
    )

    /// Nil when the name does not follow the Dump Layer format: an archive
    /// saved by some other tool, or renamed.
    init?(fileName: String) {
        let baseName = (fileName as NSString).deletingPathExtension
        let fullRange = NSRange(baseName.startIndex..., in: baseName)
        guard let match = Self.fileNamePattern?.firstMatch(in: baseName, range: fullRange),
              let processNameRange = Range(match.range(at: 1), in: baseName),
              let processIdentifierRange = Range(match.range(at: 2), in: baseName),
              let classNameRange = Range(match.range(at: 3), in: baseName),
              let objectAddressRange = Range(match.range(at: 4), in: baseName),
              let processIdentifier = Int32(baseName[processIdentifierRange])
        else { return nil }
        processName = String(baseName[processNameRange])
        self.processIdentifier = processIdentifier
        className = String(baseName[classNameRange])
        objectAddress = String(baseName[objectAddressRange])
    }
}
