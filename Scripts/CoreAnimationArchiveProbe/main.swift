// CoreAnimationArchiveProbe — throwaway diagnostic for the `.caar` import work.
//
// Runs the import pipeline the Core Animation archive document uses (decode,
// number, render, convert) on real archives and prints what came out, so the
// result can be checked against a real window without opening the inspector.
//
//   --dump-window   Builds an off-screen AppKit window with assorted controls,
//                   some inside flipped containers, and has AppKit write its
//                   Dump Layer archive (`-[NSWindow _dumpLayer]`, the call the
//                   debug menu makes), then imports that file.
//   <file.caar>     Imports an existing archive, from Dump Layer or another tool.
//
// The root's group image of every import is written next to the summary, in
// the directory given by --output-directory (default: the temporary
// directory), so its orientation can be looked at.
//
// Not part of any app target. Build with
// Scripts/build-core-animation-archive-probe.sh.

import AppKit
import Foundation
import QuartzCore

// MARK: - A window to dump

/// A view that says whether it is flipped, so a flipped container can be
/// built without a private class.
final class FlippedContainerView: NSView {
    override var isFlipped: Bool {
        true
    }
}

@MainActor
func makingDumpLayerArchive() -> URL? {
    _ = NSApplication.shared
    NSApp.setActivationPolicy(.prohibited)

    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 420, height: 300),
        styleMask: [.titled, .closable, .resizable],
        backing: .buffered,
        defer: false
    )
    window.title = "Dump Layer Probe"
    guard let contentView = window.contentView else { return nil }
    contentView.wantsLayer = true

    // Bottom up in the unflipped content view: the label sits near the top.
    let topLabel = NSTextField(labelWithString: "Top of the content view")
    topLabel.frame = NSRect(x: 20, y: 250, width: 300, height: 22)
    contentView.addSubview(topLabel)

    let button = NSButton(title: "A Button", target: nil, action: nil)
    button.frame = NSRect(x: 20, y: 200, width: 120, height: 32)
    contentView.addSubview(button)

    // A flipped container whose first child is at y = 0, i.e. its top, and
    // inside it another flipped container: flips within flips.
    let flippedContainer = FlippedContainerView(frame: NSRect(x: 20, y: 20, width: 380, height: 160))
    flippedContainer.wantsLayer = true
    flippedContainer.layer?.backgroundColor = NSColor.systemYellow.withAlphaComponent(0.3).cgColor
    contentView.addSubview(flippedContainer)

    let flippedTopLabel = NSTextField(labelWithString: "Top of the flipped container")
    flippedTopLabel.frame = NSRect(x: 10, y: 0, width: 300, height: 22)
    flippedContainer.addSubview(flippedTopLabel)

    let nestedContainer = FlippedContainerView(frame: NSRect(x: 10, y: 40, width: 200, height: 100))
    nestedContainer.wantsLayer = true
    nestedContainer.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.3).cgColor
    flippedContainer.addSubview(nestedContainer)

    let nestedTopLabel = NSTextField(labelWithString: "Top of the nested one")
    nestedTopLabel.frame = NSRect(x: 5, y: 0, width: 190, height: 22)
    nestedContainer.addSubview(nestedTopLabel)

    let imageView = NSImageView(frame: NSRect(x: 240, y: 40, width: 64, height: 64))
    imageView.image = NSImage(systemSymbolName: "arrow.up", accessibilityDescription: nil)
    imageView.imageScaling = .scaleProportionallyUpOrDown
    flippedContainer.addSubview(imageView)

    window.displayIfNeeded()
    CATransaction.flush()

    // The debug menu's own call: encodes the window's root layer and writes
    // `<process>-<pid>-<class>-<address>-layer-<uptime>.caar`.
    let dumpLayer = NSSelectorFromString("_dumpLayer")
    guard window.responds(to: dumpLayer),
          let path = window.perform(dumpLayer)?.takeUnretainedValue() as? String
    else { return nil }
    return URL(fileURLWithPath: path)
}

// MARK: - Import

struct ImportSummary {
    let nodeCount: Int
    let maximumDepth: Int
    let flippedNodeCount: Int
    let soloImageCount: Int
    let groupImageCount: Int
    let imageBytes: Int
    let appName: String
    let rootSize: CGSize
    let classCounts: [String: Int]
}

func importing(_ url: URL, outputDirectory: URL) throws -> ImportSummary {
    let data = try Data(contentsOf: url)
    let contents = try CoreAnimationArchive.decodingContents(of: data)
    let tree = CoreAnimationArchiveLayerTree(contents: contents)
    let screenshots = try CoreAnimationArchivePixelRecovery.recovering(from: tree)
    let capture = CoreAnimationArchiveCapture(
        tree: tree,
        screenshots: screenshots,
        origin: CoreAnimationArchiveOrigin(fileName: url.lastPathComponent)
    )
    let file = CoreAnimationArchiveConverter.makingHierarchyFile(from: capture)

    var nodeCount = 0
    var maximumDepth = 0
    var flippedNodeCount = 0
    var classCounts: [String: Int] = [:]
    func walking(_ items: [DisplayItem], depth: Int) {
        for item in items {
            nodeCount += 1
            maximumDepth = max(maximumDepth, depth)
            if item.isFlipped {
                flippedNodeCount += 1
            }
            classCounts[item.layerObject?.classChainList?.first ?? "?", default: 0] += 1
            // Where the inspector places the coloured nodes, in its bottom-up
            // root space: compare with the root image, measured from its top.
            if let backgroundColor = item.backgroundColor?.usingColorSpace(.sRGB), backgroundColor.alphaComponent > 0.1 {
                let frameToRoot = item.calculateFrameToRoot()
                print(String(
                    format: "  coloured node #%lu (%.2f %.2f %.2f %.2f): frame to root x %.0f y %.0f w %.0f h %.0f, flipped %@",
                    item.layerObject?.oid ?? 0,
                    backgroundColor.redComponent, backgroundColor.greenComponent,
                    backgroundColor.blueComponent, backgroundColor.alphaComponent,
                    frameToRoot.origin.x, frameToRoot.origin.y, frameToRoot.width, frameToRoot.height,
                    item.isFlipped ? "yes" : "no"
                ))
            }
            walking(item.subitems ?? [], depth: depth + 1)
        }
    }
    let rootItems = file.hierarchyInfo?.displayItems ?? []
    walking(rootItems, depth: 1)

    let soloImages = file.soloScreenshots ?? [:]
    let groupImages = file.groupScreenshots ?? [:]
    if let rootImage = groupImages[NSNumber(value: 1)] {
        let imageURL = outputDirectory.appendingPathComponent(url.deletingPathExtension().lastPathComponent + "-root.png")
        try rootImage.write(to: imageURL)
        print("  root image: \(imageURL.path)")
    }
    return ImportSummary(
        nodeCount: nodeCount,
        maximumDepth: maximumDepth,
        flippedNodeCount: flippedNodeCount,
        soloImageCount: soloImages.count,
        groupImageCount: groupImages.count,
        imageBytes: soloImages.values.reduce(0) { $0 + $1.count } + groupImages.values.reduce(0) { $0 + $1.count },
        appName: file.hierarchyInfo?.appInfo?.appName ?? "?",
        rootSize: rootItems.first?.frame.size ?? .zero,
        classCounts: classCounts
    )
}

// MARK: - Main

@MainActor
func runningProbe() -> Int32 {
    var arguments = Array(CommandLine.arguments.dropFirst())
    var outputDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
    if let flagIndex = arguments.firstIndex(of: "--output-directory"), flagIndex + 1 < arguments.count {
        outputDirectory = URL(fileURLWithPath: arguments[flagIndex + 1], isDirectory: true)
        arguments.removeSubrange(flagIndex ... flagIndex + 1)
    }
    try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    var archiveURLs: [URL] = []
    if let flagIndex = arguments.firstIndex(of: "--dump-window") {
        arguments.remove(at: flagIndex)
        guard let dumpedURL = makingDumpLayerArchive() else {
            print("could not make AppKit dump the window")
            return 1
        }
        print("Dump Layer wrote \(dumpedURL.path)")
        archiveURLs.append(dumpedURL)
    }
    archiveURLs += arguments.map { URL(fileURLWithPath: $0) }
    guard !archiveURLs.isEmpty else {
        print("usage: CoreAnimationArchiveProbe [--dump-window] [file.caar ...] [--output-directory directory]")
        return 64
    }

    var failureCount: Int32 = 0
    for url in archiveURLs {
        print("\(url.lastPathComponent):")
        let start = Date()
        do {
            let summary = try importing(url, outputDirectory: outputDirectory)
            let elapsed = Date().timeIntervalSince(start)
            print("  app \(summary.appName), root \(summary.rootSize.width) × \(summary.rootSize.height)")
            print("  \(summary.nodeCount) nodes, depth \(summary.maximumDepth), \(summary.flippedNodeCount) flipped")
            print("  \(summary.groupImageCount) group images, \(summary.soloImageCount) solo images, \(summary.imageBytes / 1024) KB")
            let classes = summary.classCounts.sorted { $0.value > $1.value }.prefix(8).map { "\($0.key) \($0.value)" }
            print("  classes: \(classes.joined(separator: ", "))")
            print(String(format: "  imported in %.2f s", elapsed))
        } catch {
            failureCount += 1
            print("  FAILED: \(error) — \((error as? CoreAnimationArchiveError)?.failureReason ?? "")")
        }
    }
    return failureCount == 0 ? 0 : 1
}

exit(MainActor.assumeIsolated { runningProbe() })
