//
//  LKExportManager.swift
//  LookInside
//
//  Writes a hierarchy as a `.lookin` archive (screenshots scaled by the chosen
//  image quality and stored as LZW TIFF, keyed by object id) and saves a
//  single item's screenshot as a TIFF file.
//

import AppKit
import LookInsideHostCore
import UniformTypeIdentifiers

@objc(LKExportManager)
final class LKExportManager: NSObject {
    private static let shared = LKExportManager()

    @objc class func sharedInstance() -> LKExportManager {
        shared
    }

    /// The archive data of `info`, with every screenshot scaled by
    /// `compression` (clamped to 0.01...1). When `fileName` is given it
    /// receives the suggested file name.
    @objc(dataFromHierarchyInfo:imageCompression:fileName:)
    func data(from info: LookinHierarchyInfo,
              imageCompression compression: CGFloat,
              fileName: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Data?
    {
        let file = LookinHierarchyFile()
        file.serverVersion = info.serverVersion
        file.hierarchyInfo = info

        var soloScreenshots: [NSNumber: Data] = [:]
        var groupScreenshots: [NSNumber: Data] = [:]
        let prefersViewOID = LKHelper.appInfoLooksLikeMacTarget(info.appInfo)
        let allItems = LookinDisplayItem.flatItems(fromHierarchicalItems: info.displayItems ?? []) ?? []
        for displayItem in allItems {
            let oid = displayItem.bestObjectOidPreferView(prefersViewOID)
            if oid == 0 {
                continue
            }
            displayItem.screenshotEncodeType = .none
            let key = NSNumber(value: oid)
            soloScreenshots[key] = Self.compressedData(from: displayItem.soloScreenshot, compression: compression)
            groupScreenshots[key] = Self.compressedData(from: displayItem.groupScreenshot, compression: compression)
        }
        file.soloScreenshots = soloScreenshots
        file.groupScreenshots = groupScreenshots

        let document = LookinArchiveDocument()
        document.hierarchyFile = file
        var exportedData: Data?
        do {
            exportedData = try document.data(ofType: "com.lookin.lookin")
        } catch {
            assertionFailure("Encoding the .lookin archive failed: \(error)")
        }

        if let fileName {
            fileName.pointee = ExportNaming.fileName(appName: info.appInfo?.appName,
                                                     osDescription: info.appInfo?.osDescription,
                                                     date: Date()) as NSString
        }
        return exportedData
    }

    private static func compressedData(from sourceImage: NSImage?, compression: CGFloat) -> Data? {
        guard let sourceImage else {
            return nil
        }
        let compression = max(min(compression, 1), 0.01)
        let targetSize = NSSize(width: sourceImage.size.width * compression, height: sourceImage.size.height * compression)
        let targetFrame = NSRect(origin: .zero, size: targetSize)
        let sourceImageRep = sourceImage.bestRepresentation(for: targetFrame, context: nil, hints: nil)

        let resizedImage = NSImage(size: targetSize)
        resizedImage.lockFocus()
        sourceImageRep?.draw(in: targetFrame)
        resizedImage.unlockFocus()

        guard let tiff = resizedImage.tiffRepresentation, let imageRep = NSBitmapImageRep(data: tiff) else {
            return nil
        }
        return imageRep.tiffRepresentation(using: .lzw, factor: 1)
    }

    /// Asks where to save `displayItem`'s group screenshot and writes it as TIFF.
    @MainActor
    @objc(exportScreenshotWithDisplayItem:)
    class func exportScreenshot(with displayItem: LookinDisplayItem) {
        guard let image = displayItem.groupScreenshot,
              let imageData = image.tiffRepresentation(using: .lzw, factor: 1)
        else {
            LKPeripheralAlerts.show(LKConnectionError.inner, in: LKPeripheralAlerts.keyWindow)
            return
        }

        let panel = NSSavePanel()
        let title = displayItem.title()
        panel.nameFieldStringValue = title.isEmpty ? "LookInsideImage" : title
        panel.allowsOtherFileTypes = false
        panel.allowedContentTypes = [.tiff]
        panel.isExtensionHidden = true
        panel.canCreateDirectories = true
        let completion: (NSApplication.ModalResponse) -> Void = { result in
            guard result == .OK, let url = panel.url else { return }
            do {
                try imageData.write(to: URL(fileURLWithPath: url.path))
            } catch {
                LKPeripheralAlerts.show(error, in: LKPeripheralAlerts.keyWindow)
                assertionFailure("Writing the screenshot failed: \(error)")
            }
        }
        if let window = LKPeripheralAlerts.keyWindow {
            panel.beginSheetModal(for: window, completionHandler: completion)
        } else {
            panel.begin(completionHandler: completion)
        }
    }
}
