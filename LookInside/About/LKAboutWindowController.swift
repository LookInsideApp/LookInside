//
//  LKAboutWindowController.swift
//  LookInside
//
//  The About window: app icon, name, version, tagline and the license line
//  with links to upstream Lookin and the LookInside website.
//

import AppKit

@objc(LKAboutWindowController)
final class LKAboutWindowController: LKWindowController {
    @objc init() {
        let window = LKWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 460),
                              styleMask: [.titled, .closable, .fullSizeContentView],
                              backing: .buffered, defer: true)
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.center()

        super.init(window: window)
        let viewController = LKAboutViewController()
        window.contentView = viewController.view
        contentViewController = viewController
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

@objc(LKAboutViewController)
final class LKAboutViewController: LKBaseViewController {
    private static let upstreamURL = "https://github.com/QMUI/LookinServer"
    private static let homeURL = "https://lookinside-app.com"
    private static let padding: CGFloat = 16

    private var backgroundImageView: LKBaseView?
    private var paperOverlayView: LKBaseView?
    private var contentStackView: NSStackView?
    private var legalTextView: NSTextView?

    init() {
        super.init(containerView: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func makeContainerView() -> NSView {
        let containerView = LKBaseView()
        containerView.backgroundColors = LKTwoColors(
            colorInLightMode: NSColor(calibratedRed: 0.99, green: 0.97, blue: 0.93, alpha: 1),
            colorInDarkMode: NSColor(calibratedWhite: 0.10, alpha: 1)
        )

        let backgroundImageView = LKBaseView()
        backgroundImageView.wantsLayer = true
        backgroundImageView.layer?.contents = NSImage(named: "aboutHeroBg")
        backgroundImageView.layer?.contentsGravity = .resizeAspectFill
        backgroundImageView.layer?.masksToBounds = true
        backgroundImageView.layer?.opacity = 0.25
        containerView.addSubview(backgroundImageView)
        self.backgroundImageView = backgroundImageView

        let paperOverlayView = LKBaseView()
        paperOverlayView.backgroundColors = LKTwoColors(
            colorInLightMode: NSColor(calibratedRed: 0.99, green: 0.97, blue: 0.93, alpha: 0.55),
            colorInDarkMode: NSColor(calibratedWhite: 0.10, alpha: 0.55)
        )
        containerView.addSubview(paperOverlayView)
        self.paperOverlayView = paperOverlayView

        let iconImageView = NSImageView()
        iconImageView.image = NSApp.applicationIconImage
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        iconImageView.widthAnchor.constraint(equalToConstant: 96).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 96).isActive = true

        let serifDescriptor = NSFontDescriptor(fontAttributes: [:]).withDesign(.serif)
        let titleFont = serifDescriptor.flatMap { NSFont(descriptor: $0, size: 30) }
            ?? NSFont.systemFont(ofSize: 30, weight: .regular)
        let footnoteFont = NSFont.preferredFont(forTextStyle: .footnote, options: [:])

        let titleLabel = LKLabel()
        titleLabel.stringValue = "LookInside"
        titleLabel.textColors = LKTwoColors(colorInLightMode: NSColor(calibratedWhite: 0.12, alpha: 1),
                                            colorInDarkMode: NSColor(calibratedWhite: 0.96, alpha: 1))
        titleLabel.font = titleFont

        let info = Bundle.main.infoDictionary
        let dotVersion = info?["CFBundleShortVersionString"] as? String ?? "(null)"
        let numberVersion = info?["CFBundleVersion"] as? String ?? "(null)"
        let versionLabel = LKLabel()
        versionLabel.stringValue = "Version \(dotVersion) (\(numberVersion))"
        versionLabel.textColors = LKTwoColors(colorInLightMode: NSColor(calibratedWhite: 0.35, alpha: 1),
                                              colorInDarkMode: NSColor(calibratedWhite: 0.78, alpha: 1))
        versionLabel.font = footnoteFont

        let taglineLabel = LKLabel()
        taglineLabel.stringValue = "A SwiftUI- and UIKit-aware view debugger.\nWalk every layer. Read every modifier."
        taglineLabel.textColors = LKTwoColors(colorInLightMode: NSColor(calibratedWhite: 0.30, alpha: 1),
                                              colorInDarkMode: NSColor(calibratedWhite: 0.82, alpha: 1))
        taglineLabel.font = footnoteFont
        taglineLabel.alignment = .center
        taglineLabel.maximumNumberOfLines = 2

        let contentStackView = NSStackView(views: [iconImageView, titleLabel, versionLabel, taglineLabel])
        contentStackView.orientation = .vertical
        contentStackView.alignment = .centerX
        contentStackView.spacing = 16
        containerView.addSubview(contentStackView)
        self.contentStackView = contentStackView

        let legalTextView = NSTextView(frame: .zero)
        legalTextView.isEditable = false
        legalTextView.isSelectable = true
        legalTextView.drawsBackground = false
        legalTextView.textContainerInset = .zero
        legalTextView.textContainer?.lineFragmentPadding = 0
        legalTextView.linkTextAttributes = [
            .foregroundColor: NSColor(calibratedRed: 0.40, green: 0.32, blue: 0.62, alpha: 1),
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .cursor: NSCursor.pointingHand,
        ]
        legalTextView.textStorage?.setAttributedString(Self.legalText(font: footnoteFont))
        containerView.addSubview(legalTextView)
        self.legalTextView = legalTextView

        return containerView
    }

    private static func legalText(font: NSFont) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 2
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(calibratedWhite: 0.40, alpha: 1),
            .paragraphStyle: paragraph,
        ]
        let year = Calendar.current.component(.year, from: Date())

        let legal = NSMutableAttributedString()
        func append(_ string: String, link: String? = nil) {
            let start = legal.length
            legal.append(NSAttributedString(string: string, attributes: attributes))
            if let link {
                legal.addAttribute(.link, value: link, range: NSRange(location: start, length: legal.length - start))
            }
        }
        append("© \(year) LookInside-App. Released under GPL-3.0.\n")
        append("Based on ")
        append("Lookin", link: upstreamURL)
        append(" by QMUI · ")
        append("lookinside-app.com", link: homeURL)
        return legal
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        let padding = Self.padding
        backgroundImageView?.lkpFullFrame()
        paperOverlayView?.lkpFullFrame()

        let viewSize = view.bounds.size
        guard let legalTextView, let contentStackView else { return }
        let legalSize = legalTextView.attributedString().boundingRect(
            with: NSSize(width: viewSize.width - padding * 2, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin
        ).size
        let legalHeight = ceil(legalSize.height) + 4
        let legalY = viewSize.height - padding - legalHeight
        legalTextView.lkpSetWidth(viewSize.width - padding * 2)
        legalTextView.lkpSetHeight(legalHeight)
        legalTextView.lkpHorAlign()
        legalTextView.lkpSetY(legalY)

        let stackSize = contentStackView.fittingSize
        let available = legalY - padding - padding
        let stackY = padding + max(0, (available - stackSize.height) / 2)
        contentStackView.lkpSetWidth(stackSize.width)
        contentStackView.lkpSetHeight(stackSize.height)
        contentStackView.lkpHorAlign()
        contentStackView.lkpSetY(stackY)
    }
}
