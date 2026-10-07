//
//  LKDashboardAttributeStringArrayView.swift
//  LookInside
//
//  Created by Li Kai on 2019/6/15.
//  https://lookin.work
//

import AppKit

/// A list of selectable texts separated by hairlines: the class chain and
/// the relations of an object.
class LKDashboardAttributeStringArrayView: LKDashboardAttributeView {
    private let labelsVerInterSpace: CGFloat = 10

    private var labels: [LKLabel] = []
    private var sepLayers: [CALayer] = []
    private var danceButton: NSButton?

    /// The texts to list. Subclasses must override.
    func stringList(with _: LookinAttribute) -> [String] {
        assertionFailure("should implement by subclass")
        return []
    }

    override func layout() {
        super.layout()
        for (idx, label) in labels.enumerated() {
            let y = idx > 0 ? labels[idx - 1].frame.maxY + labelsVerInterSpace : 0
            label.dashboardLayout.fullFrame().heightToFit().y(y)
            if idx > 0 {
                guard sepLayers.indices.contains(idx - 1) else {
                    assertionFailure()
                    continue
                }
                sepLayers[idx - 1].dashboardLayout.fullFrame().height(1).y(label.frame.minY - labelsVerInterSpace / 2.0 + 1)
            }
        }
        if let danceButton, danceButton.isVisible {
            danceButton.dashboardLayout.width(150).horAlign().height(25).bottom(0)
        }
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        var size = limitedSize
        var height: CGFloat = 0
        for (idx, label) in labels.enumerated() {
            height += label.sizeThatFits(limitedSize).height
            if idx > 0 {
                height += labelsVerInterSpace
            }
        }
        if let danceButton, danceButton.isVisible {
            height += 35
        }
        size.height = height
        return size
    }

    override func renderWithAttribute() {
        guard let attribute else { return }
        let list = stringList(with: attribute)

        while labels.count > list.count {
            labels.removeLast().removeFromSuperview()
        }
        while labels.count < list.count {
            let label = LKLabel()
            label.lineBreakStrategy = []
            label.isSelectable = true
            label.allowsEditingTextAttributes = true
            addSubview(label)
            labels.append(label)
        }
        for (label, string) in zip(labels, list) {
            label.attributedStringValue = LKDashboardText.attributed(string, font: LKDashboardStyle.font(12), color: .labelColor, lineHeight: 18)
        }

        let separatorCount = list.count > 1 ? list.count - 1 : 0
        while sepLayers.count > separatorCount {
            sepLayers.removeLast().removeFromSuperlayer()
        }
        while sepLayers.count < separatorCount {
            let sepLayer = CALayer()
            sepLayer.lookin_removeImplicitAnimations()
            layer?.addSublayer(sepLayer)
            sepLayers.append(sepLayer)
        }
        if list.count > 1 {
            updateColors()
        }

        danceButton?.isHidden = true
        if attribute.identifier == LookinAttr_Class_Class_Class, danceSource(of: attribute) != nil {
            let button = danceButtonIfNeeded()
            button.title = NSLocalizedString("Navigate…", comment: "")
            button.isHidden = false
        }

        needsLayout = true
    }

    override func updateColors() {
        super.updateColors()
        let color = LKDashboardStyle.separatorColor(isDarkMode: isDarkMode()).cgColor
        for sepLayer in sepLayers {
            sepLayer.backgroundColor = color
        }
    }

    private func danceSource(of attribute: LookinAttribute?) -> String? {
        let item = attribute?.targetDisplayItem
        return item?.danceuiSource ?? item?.customInfo?.danceuiSource
    }

    private func danceButtonIfNeeded() -> NSButton {
        if let danceButton {
            return danceButton
        }
        let button = NSButton.lk_normalButton(withTitle: "", target: self, action: #selector(handleDanceButton))
        button.font = LKDashboardStyle.font(12)
        addSubview(button)
        danceButton = button
        return button
    }

    @objc private func handleDanceButton() {
        DanceScriptManager.shared().handleText(danceSource(of: attribute))
    }
}

/// The class chain of the object, one class list per entry, demangled.
@objc(LKDashboardAttributeClassView)
final class LKDashboardAttributeClassView: LKDashboardAttributeStringArrayView {
    override func stringList(with attribute: LookinAttribute) -> [String] {
        let lists = attribute.value as? [[String]] ?? []
        return lists.map { rawClassList in
            rawClassList.map { LKSwiftDemangler.completedParse(input: $0) }.joined(separator: "\n")
        }
    }
}

/// The relations of the object ("(AAA : BBB *)" and "(AAA *)" texts), with
/// the Swift class names demangled. Cached on the attribute.
@objc(LKDashboardAttributeRelationView)
final class LKDashboardAttributeRelationView: LKDashboardAttributeStringArrayView {
    private static let cacheKey = "cachedDemangled"

    private static let memberRegex = try! NSRegularExpression(pattern: #"\(\s*(\w+)\s*:\s*(\w+)\s*\*\s*\)"#)
    private static let objectRegex = try! NSRegularExpression(pattern: #"\(\s*(\w+)\s*\*\s*\)"#)

    override func stringList(with attribute: LookinAttribute) -> [String] {
        if let cache = attribute.lookin_getBindObject(forKey: Self.cacheKey) as? [String] {
            return cache
        }
        let raw = attribute.value as? [String] ?? []
        let demangled = raw.map(Self.demangle)
        attribute.lookin_bindObject(demangled, forKey: Self.cacheKey)
        return demangled
    }

    static func demangle(_ rawText: String) -> String {
        let text = rawText as NSString
        let fullRange = NSRange(location: 0, length: text.length)

        // "(AAA : BBB *)"
        if let match = memberRegex.firstMatch(in: rawText, range: fullRange) {
            let range1 = match.range(at: 1)
            let range2 = match.range(at: 2)
            let substring1 = text.substring(with: range1)
            let substring2 = text.substring(with: range2)
            let demangled1 = LKSwiftDemangler.simpleParse(input: substring1)
            let demangled2 = LKSwiftDemangler.simpleParse(input: substring2)
            let replaced = text.replacingCharacters(in: range1, with: demangled1) as NSString
            return replaced.replacingOccurrences(of: substring2, with: demangled2)
        }

        // "(AAA *)"
        if let match = objectRegex.firstMatch(in: rawText, range: fullRange) {
            let range = match.range(at: 1)
            let demangled = LKSwiftDemangler.simpleParse(input: text.substring(with: range))
            return text.replacingCharacters(in: range, with: demangled)
        }

        return rawText
    }
}
