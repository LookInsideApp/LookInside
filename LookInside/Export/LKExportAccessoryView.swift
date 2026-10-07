//
//  LKExportAccessoryView.swift
//  LookInside
//
//  The save panel accessory of the `.lookin` export: an image-quality menu
//  bound to the preferred export compression, and the resulting file size.
//

import AppKit
import LookInsideHostCore

@objc(LKExportAccessoryView)
final class LKExportAccessoryView: LKBaseView {
    private static let insetTop: CGFloat = 20
    private static let insetBottom: CGFloat = 10
    private static let buttonWidth: CGFloat = 150
    private static let sizeLabelTop: CGFloat = 5

    /// The exported size in bytes, shown in megabytes.
    @objc var dataSize: UInt = 0 {
        didSet {
            sizeLabel.stringValue = String(format: NSLocalizedString("File Size: %.2f M", comment: ""),
                                           ExportNaming.megabytes(dataSize))
        }
    }

    private let compressionLabel = LKLabel()
    private let compressionButton = NSPopUpButton()
    private let sizeLabel = LKLabel()
    private var compressionObservation: NSKeyValueObservation?
    private var lastObservedCompression: CGFloat?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        compressionLabel.stringValue = NSLocalizedString("Image Quality:", comment: "")
        compressionLabel.font = .systemFont(ofSize: 15)
        compressionLabel.alignment = .right
        addSubview(compressionLabel)

        compressionButton.font = .systemFont(ofSize: 14)
        compressionButton.target = self
        compressionButton.action = #selector(handleCompressionButton)
        compressionButton.addItems(withTitles: ExportNaming.compressionOptions.map(ExportNaming.compressionTitle))
        addSubview(compressionButton)

        sizeLabel.font = .systemFont(ofSize: 13)
        sizeLabel.stringValue = NSLocalizedString("File Size", comment: "")
        sizeLabel.alignment = .right
        addSubview(sizeLabel)

        compressionObservation = LKPreferenceManager.shared.observe(\.preferredExportCompression, options: [.initial, .new]) {
            [weak self] manager, _ in
            let compression = manager.preferredExportCompression
            MainActor.assumeIsolated {
                self?.selectCompression(compression)
            }
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func selectCompression(_ compression: CGFloat) {
        guard compression != lastObservedCompression else { return }
        lastObservedCompression = compression
        let index = ExportNaming.compressionIndex(for: Double(compression)) ?? -1
        if compressionButton.indexOfSelectedItem != index {
            compressionButton.selectItem(at: index)
        }
    }

    override func layout() {
        super.layout()
        compressionLabel.lkpSizeToFit()
        compressionLabel.lkpSetY(Self.insetTop)
        compressionLabel.lkpSetX(0)

        compressionButton.lkpSetWidth(Self.buttonWidth)
        compressionButton.lkpHeightToFit()
        compressionButton.lkpSetX(compressionLabel.frame.maxX)
        compressionButton.lkpSetMidY(compressionLabel.frame.midY)

        sizeLabel.lkpFullWidth()
        sizeLabel.lkpHeightToFit()
        sizeLabel.lkpSetY(compressionButton.frame.maxY + Self.sizeLabelTop)
    }

    @objc private func handleCompressionButton() {
        let index = compressionButton.indexOfSelectedItem
        guard ExportNaming.compressionOptions.indices.contains(index) else { return }
        LKPreferenceManager.shared.preferredExportCompression = CGFloat(ExportNaming.compressionOptions[index])
    }

    override func sizeThatFits(_: NSSize) -> NSSize {
        let labelSize = compressionLabel.sizeThatFits(lkpMaxSize)
        return NSSize(width: labelSize.width + Self.buttonWidth,
                      height: Self.insetTop + labelSize.height + Self.sizeLabelTop
                          + sizeLabel.sizeThatFits(lkpMaxSize).height + Self.insetBottom)
    }
}
