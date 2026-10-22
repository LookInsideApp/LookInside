// ViewHierarchyProbe — throwaway diagnostic for the `.viewhierarchy` import work.
//
// Measures how much per-layer pixel content can be recovered from the
// `encodedPresentationLayer` archives inside an Xcode-exported view hierarchy
// bundle. It answers the one question that cannot be settled by inspecting the
// files offline: whether NSKeyedUnarchiver in an ordinary process resolves the
// private QuartzCore coding proxies and yields a renderable CALayer tree.
//
// Not part of any app target. Build with Scripts/build-viewhierarchy-probe.sh.

import AppKit
import Compression
import Foundation

// MARK: - Gzip

/// Inflates a gzip member, or returns the input unchanged when it carries no
/// gzip magic. Response entries inside a bundle are compressed only when the
/// capture requested transport compression, so both forms occur.
func inflatingGzipIfNeeded(_ payload: Data) -> Data? {
    let bytes = [UInt8](payload)
    guard bytes.count > 18, bytes[0] == 0x1F, bytes[1] == 0x8B else { return payload }
    guard bytes[2] == 8 else { return nil }

    let flags = bytes[3]
    var cursor = 10
    if flags & 0x04 != 0 {
        guard cursor + 1 < bytes.count else { return nil }
        let extraLength = Int(bytes[cursor]) | (Int(bytes[cursor + 1]) << 8)
        cursor += 2 + extraLength
    }
    if flags & 0x08 != 0 {
        while cursor < bytes.count, bytes[cursor] != 0 {
            cursor += 1
        }
        cursor += 1
    }
    if flags & 0x10 != 0 {
        while cursor < bytes.count, bytes[cursor] != 0 {
            cursor += 1
        }
        cursor += 1
    }
    if flags & 0x02 != 0 {
        cursor += 2
    }
    guard cursor < bytes.count - 8 else { return nil }

    let deflateBytes = Array(bytes[cursor ..< (bytes.count - 8)])
    let trailer = bytes.suffix(4)
    let declaredSize = trailer.enumerated().reduce(0) { partial, element in
        partial | (Int(element.element) << (8 * element.offset))
    }

    var capacity = max(declaredSize, 64 * 1024)
    for _ in 0 ..< 6 {
        var destination = [UInt8](repeating: 0, count: capacity)
        let writtenCount = deflateBytes.withUnsafeBufferPointer { source in
            destination.withUnsafeMutableBufferPointer { target in
                compression_decode_buffer(
                    target.baseAddress!, capacity,
                    source.baseAddress!, deflateBytes.count,
                    nil, COMPRESSION_ZLIB
                )
            }
        }
        if writtenCount > 0, writtenCount < capacity {
            return Data(destination[0 ..< writtenCount])
        }
        if writtenCount == capacity, capacity == declaredSize {
            return Data(destination)
        }
        capacity *= 2
    }
    return nil
}

// MARK: - Bundle loading

struct ResponseEntry {
    let fileName: String
    let json: [String: Any]
}

func loadingResponses(fromBundleAt bundleURL: URL) -> [ResponseEntry] {
    let responsesDirectory = bundleURL.appendingPathComponent("RequestResponses")
    guard let fileNames = try? FileManager.default.contentsOfDirectory(atPath: responsesDirectory.path) else {
        return []
    }
    return fileNames.sorted().compactMap { fileName in
        let fileURL = responsesDirectory.appendingPathComponent(fileName)
        guard let rawData = try? Data(contentsOf: fileURL),
              let inflatedData = inflatingGzipIfNeeded(rawData),
              let parsed = try? JSONSerialization.jsonObject(with: inflatedData),
              let json = parsed as? [String: Any]
        else { return nil }
        return ResponseEntry(fileName: fileName, json: json)
    }
}

/// Collects every `<objectID>.encodedPresentationLayer` property value across responses.
func collectingEncodedPresentationLayers(in responses: [ResponseEntry]) -> [(objectIdentifier: String, base64Payload: String)] {
    var collected: [(String, String)] = []
    for response in responses {
        guard let descriptions = response.json["topLevelPropertyDescriptions"] as? [String: Any] else { continue }
        for (keyPath, rawDescription) in descriptions {
            guard keyPath.hasSuffix(".encodedPresentationLayer"),
                  let description = rawDescription as? [String: Any],
                  let payload = description["propertyValue"] as? String
            else { continue }
            let objectIdentifier = String(keyPath.prefix(while: { $0 != "." }))
            collected.append((objectIdentifier, payload))
        }
    }
    return collected
}

// MARK: - Unarchiving

/// Decodes one `encodedPresentationLayer` payload into its root CALayer.
/// The archive's root object is a dictionary of the form
/// `{ "rootLayer": CALayer, "geometryFlipped": Bool }`.
func unarchivingRootLayer(fromBase64 payload: String) -> (rootLayer: CALayer, geometryFlipped: Bool)? {
    guard let archiveData = Data(base64Encoded: payload) else {
        print("      ! base64 decode failed")
        return nil
    }
    do {
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: archiveData)
        unarchiver.requiresSecureCoding = false
        let decoded = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey)
        unarchiver.finishDecoding()
        guard let rootDictionary = decoded as? [String: Any] else {
            print("      ! root object was \(type(of: decoded)), expected dictionary")
            return nil
        }
        guard let rootLayer = rootDictionary["rootLayer"] as? CALayer else {
            print("      ! no rootLayer; root keys = \(Array(rootDictionary.keys))")
            return nil
        }
        let geometryFlipped = (rootDictionary["geometryFlipped"] as? NSNumber)?.boolValue ?? false
        return (rootLayer, geometryFlipped)
    } catch {
        print("      ! unarchive threw: \(error.localizedDescription)")
        return nil
    }
}

// MARK: - Rendering

struct RecoveryStatistics {
    var layerCount = 0
    var layersWithContents = 0
    var layersWithNonEmptyGroupRender = 0
    var layersWithNonEmptyGroupRenderWithSuppression = 0
    var layersWithNonEmptySoloRender = 0
    var layersWithZeroArea = 0
    var classHistogram: [String: Int] = [:]
}

/// Layer classes that make `renderInContext:` emit an empty bitmap for the whole
/// tree when they are visible anywhere inside it. Established for live capture in
/// docs/monorepo/portal-layer-group-screenshot-plan.md; this probe checks whether
/// the same hazard survives archiving.
let poisoningLayerClassNames: Set<String> = ["CAPortalLayer", "CABackdropLayer"]

/// Temporarily hides every poisoning layer in the subtree, runs `body`, then restores.
func suppressingPoisoningLayers<Result>(under layer: CALayer, perform body: () -> Result) -> Result {
    var hiddenLayers: [CALayer] = []
    func collect(_ candidate: CALayer) {
        if poisoningLayerClassNames.contains(String(describing: type(of: candidate))), !candidate.isHidden {
            candidate.isHidden = true
            hiddenLayers.append(candidate)
        }
        for sublayer in candidate.sublayers ?? [] {
            collect(sublayer)
        }
    }
    collect(layer)
    defer { for hidden in hiddenLayers {
        hidden.isHidden = false
    } }
    return body()
}

/// Fraction of pixels with a non-zero alpha channel, 0 when the layer has no area.
func measuringOpaqueCoverage(of layer: CALayer, includingSublayers: Bool) -> Double {
    let width = Int(layer.bounds.width.rounded())
    let height = Int(layer.bounds.height.rounded())
    guard width > 0, height > 0, width < 20000, height < 20000 else { return -1 }

    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return -1 }

    var detachedSublayers: [CALayer]?
    if !includingSublayers, let existing = layer.sublayers, !existing.isEmpty {
        detachedSublayers = existing
        layer.sublayers = nil
    }
    context.translateBy(x: -layer.bounds.origin.x, y: -layer.bounds.origin.y)
    layer.render(in: context)
    if let detachedSublayers {
        layer.sublayers = detachedSublayers
    }

    guard let pixels = context.data else { return -1 }
    let buffer = pixels.bindMemory(to: UInt8.self, capacity: width * height * 4)
    var opaqueCount = 0
    for pixelIndex in stride(from: 3, to: width * height * 4, by: 4) where buffer[pixelIndex] != 0 {
        opaqueCount += 1
    }
    return Double(opaqueCount) / Double(width * height)
}

func gatheringStatistics(for layer: CALayer, into statistics: inout RecoveryStatistics) {
    statistics.layerCount += 1
    statistics.classHistogram[String(describing: type(of: layer)), default: 0] += 1
    if layer.contents != nil {
        statistics.layersWithContents += 1
    }

    let groupCoverage = measuringOpaqueCoverage(of: layer, includingSublayers: true)
    if groupCoverage < 0 {
        statistics.layersWithZeroArea += 1
    } else {
        if groupCoverage > 0 {
            statistics.layersWithNonEmptyGroupRender += 1
        }
        let suppressedCoverage = suppressingPoisoningLayers(under: layer) {
            measuringOpaqueCoverage(of: layer, includingSublayers: true)
        }
        if suppressedCoverage > 0 {
            statistics.layersWithNonEmptyGroupRenderWithSuppression += 1
        }
        if measuringOpaqueCoverage(of: layer, includingSublayers: false) > 0 {
            statistics.layersWithNonEmptySoloRender += 1
        }
    }

    for sublayer in layer.sublayers ?? [] {
        gatheringStatistics(for: sublayer, into: &statistics)
    }
}

func writingPreviewImage(of layer: CALayer, to fileURL: URL) {
    let width = Int(layer.bounds.width.rounded())
    let height = Int(layer.bounds.height.rounded())
    guard width > 0, height > 0,
          let context = CGContext(
              data: nil, width: width, height: height,
              bitsPerComponent: 8, bytesPerRow: width * 4,
              space: CGColorSpaceCreateDeviceRGB(),
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          )
    else { return }
    context.translateBy(x: -layer.bounds.origin.x, y: -layer.bounds.origin.y)
    layer.render(in: context)
    guard let renderedImage = context.makeImage() else { return }
    let bitmap = NSBitmapImageRep(cgImage: renderedImage)
    guard let pngData = bitmap.representation(using: .png, properties: [:]) else { return }
    try? pngData.write(to: fileURL)
}

// MARK: - Entry point

let arguments = CommandLine.arguments
guard arguments.count > 1 else {
    print("usage: ViewHierarchyProbe <bundle.viewhierarchy> [more bundles...]")
    exit(2)
}

let previewDirectory = URL(fileURLWithPath: "/tmp/claude/vh-probe/rendered")
try? FileManager.default.createDirectory(at: previewDirectory, withIntermediateDirectories: true)

for bundlePath in arguments.dropFirst() {
    let bundleURL = URL(fileURLWithPath: bundlePath)
    print("=== \(bundleURL.lastPathComponent) ===")

    let responses = loadingResponses(fromBundleAt: bundleURL)
    print("  responses parsed: \(responses.count)")

    let archives = collectingEncodedPresentationLayers(in: responses)
    print("  encodedPresentationLayer archives: \(archives.count)")

    var totals = RecoveryStatistics()
    var successfulArchiveCount = 0

    for (archiveIndex, archive) in archives.enumerated() {
        guard let (rootLayer, geometryFlipped) = unarchivingRootLayer(fromBase64: archive.base64Payload) else {
            print("    [\(archive.objectIdentifier)] UNARCHIVE FAILED")
            continue
        }
        successfulArchiveCount += 1

        var statistics = RecoveryStatistics()
        gatheringStatistics(for: rootLayer, into: &statistics)

        var summaryFields: [String] = []
        summaryFields.append("layers=\(statistics.layerCount)")
        summaryFields.append("contents=\(statistics.layersWithContents)")
        summaryFields.append("groupRendered=\(statistics.layersWithNonEmptyGroupRender)")
        summaryFields.append("soloRendered=\(statistics.layersWithNonEmptySoloRender)")
        summaryFields.append("zeroArea=\(statistics.layersWithZeroArea)")
        summaryFields.append("flipped=\(geometryFlipped)")
        summaryFields.append("bounds=\(NSStringFromRect(rootLayer.bounds))")
        print("    [\(archive.objectIdentifier)] " + summaryFields.joined(separator: " "))

        totals.layerCount += statistics.layerCount
        totals.layersWithContents += statistics.layersWithContents
        totals.layersWithNonEmptyGroupRender += statistics.layersWithNonEmptyGroupRender
        totals.layersWithNonEmptyGroupRenderWithSuppression += statistics.layersWithNonEmptyGroupRenderWithSuppression
        totals.layersWithNonEmptySoloRender += statistics.layersWithNonEmptySoloRender
        totals.layersWithZeroArea += statistics.layersWithZeroArea
        for (className, count) in statistics.classHistogram {
            totals.classHistogram[className, default: 0] += count
        }

        let previewName = "\(bundleURL.deletingPathExtension().lastPathComponent)-\(archiveIndex)-\(archive.objectIdentifier).png"
        writingPreviewImage(of: rootLayer, to: previewDirectory.appendingPathComponent(previewName))
    }

    let renderableDenominator = max(totals.layerCount - totals.layersWithZeroArea, 1)
    print("  TOTAL archives decoded: \(successfulArchiveCount)/\(archives.count)")
    print("  TOTAL layers: \(totals.layerCount) "
        + "(zero-area \(totals.layersWithZeroArea), renderable \(renderableDenominator))")
    print("  layers carrying contents: \(totals.layersWithContents)")
    print(String(format: "  group render non-empty: %d (%.1f%% of renderable)",
                 totals.layersWithNonEmptyGroupRender,
                 100.0 * Double(totals.layersWithNonEmptyGroupRender) / Double(renderableDenominator)))
    print(String(format: "  group render with portal/backdrop suppressed: %d (%.1f%% of renderable)",
                 totals.layersWithNonEmptyGroupRenderWithSuppression,
                 100.0 * Double(totals.layersWithNonEmptyGroupRenderWithSuppression) / Double(renderableDenominator)))
    print(String(format: "  solo render non-empty:  %d (%.1f%% of renderable)",
                 totals.layersWithNonEmptySoloRender,
                 100.0 * Double(totals.layersWithNonEmptySoloRender) / Double(renderableDenominator)))
    let topClasses = totals.classHistogram.sorted { $0.value > $1.value }.prefix(8)
    print("  layer classes: " + topClasses.map { "\($0.key)=\($0.value)" }.joined(separator: " "))
}

print("\nrendered previews written to \(previewDirectory.path)")
