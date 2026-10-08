//
//  LKHelper.swift
//  Lookin
//
//  Created by Li Kai on 2018/8/4.
//  https://lookin.work
//

import AppKit
import LookInsideHostCore

let HierarchyMinWidth: CGFloat = 200
let MeasureViewWidth: CGFloat = 240
let DashboardViewWidth: CGFloat = 260
let DashboardHorInset: CGFloat = 10
let DashboardAttrItemHorInterspace: CGFloat = 10
let DashboardAttrItemVerInterspace: CGFloat = 9
let DashboardCardControlCornerRadius: CGFloat = 4
let DashboardSectionMarginTop: CGFloat = 10
let DashboardCardCornerRadius: CGFloat = 6
let DashboardSearchCardInset: CGFloat = 6
let ConsoleInsetLeft: CGFloat = 10
let ConsoleInsetRight: CGFloat = 26
let ZoomSliderMaxValue: CGFloat = 2.8

struct HorizontalMargins {
    var left: CGFloat
    var right: CGFloat
}

final class LKHelper {
    private static let shared = LKHelper()

    static func sharedInstance() -> LKHelper {
        shared
    }

    private init() {}

    /// 使用 UIImageView 的 “使用预览打开该图片” 功能时会创建临时图片文件，它们的路径会保存在这里，Lookin 退出时应当删除这些临时文件
    /// 创建图片的相关逻辑见 LKDashboardAttributeReadOnlyViews.swift
    var tempImageFiles: [String] = []

    static func showDisabledExternalLinkAlert(withMessage message: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Link Disabled", comment: "")
        alert.informativeText = message
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert.runModal()
    }

    static func italicFont(ofSize fontSize: CGFloat) -> NSFont? {
        let fontDescriptor = NSFont.systemFont(ofSize: fontSize).fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: fontDescriptor, size: fontSize)
    }

    static func lookinReadableVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    static func openLookinWebsite(withPath _: String) {
        showDisabledExternalLinkAlert(withMessage: NSLocalizedString("Legacy website links are disabled in this community build. See the local repository README for current documentation.", comment: ""))
    }

    static func openLookinOfficialWebsite() {
        showDisabledExternalLinkAlert(withMessage: NSLocalizedString("A public project website is not configured for this build yet.", comment: ""))
    }

    static func openCustomConfigWebsite() {
        showDisabledExternalLinkAlert(withMessage: NSLocalizedString("Legacy documentation links are disabled in this community build.", comment: ""))
    }

    static func openProjectGitHubRepository() {
        if let url = URL(string: "https://github.com/Lakr233/LookInside") {
            NSWorkspace.shared.open(url)
        }
    }

    static func openProjectREADME() {
        let readmePath = (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent("README.md")
        guard FileManager.default.fileExists(atPath: readmePath) else {
            showDisabledExternalLinkAlert(withMessage: NSLocalizedString("README.md was not found in the current repository checkout.", comment: ""))
            return
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: readmePath))
    }

    private static let isEnglishLanguage: Bool = {
        guard let language = Locale.preferredLanguages.first else {
            return true
        }
        return !language.hasPrefix("zh")
    }()

    static func isEnglish() -> Bool {
        isEnglishLanguage
    }

    static func appInfoLooksLikeMacTarget(_ appInfo: InspectedAppInfo?) -> Bool {
        guard let appInfo else {
            return false
        }
        if appInfo.deviceType == .mac {
            return true
        }
        if appInfo.deviceType == .macCatalyst {
            // Catalyst runs on a Mac but draws UIKit views, and this predicate is about the view
            // framework, not the hardware. Answer false here rather than falling through: the
            // heuristics below match on the Mac's own computer name ("JH's Mac Studio Ultra"),
            // which a Catalyst app reports as its deviceDescription.
            return false
        }

        let osDescription = (appInfo.osDescription as NSString?)?.lowercased ?? ""
        let deviceDescription = (appInfo.deviceDescription as NSString?)?.lowercased ?? ""
        return osDescription.contains("macos")
            || osDescription.contains("os x")
            || deviceDescription.contains("mac")
    }

    /// The name of the view class the inspected app actually uses: "NSView" for AppKit
    /// targets, "UIView" otherwise. UI copy must never hardcode either name, because
    /// the host is always compiled for macOS while the inspected app may be either.
    static func viewClassName(forMacTarget isMacTarget: Bool) -> String {
        isMacTarget ? "NSView" : "UIView"
    }

    /// Convenience wrapper combining appInfoLooksLikeMacTarget(_:) and viewClassName(forMacTarget:).
    static func viewClassName(for appInfo: InspectedAppInfo?) -> String {
        viewClassName(forMacTarget: appInfoLooksLikeMacTarget(appInfo))
    }

    /// 返回用户的系统主题色
    static func accentColor() -> NSColor {
        .controlAccentColor
    }

    static func bestMatches(inCandidates candidates: [String], input: String, maxResultsCount: Int) -> [String] {
        var topResults: [(string: String, score: CGFloat)] = []
        var lowestScore: CGFloat = 1

        let input = (input as NSString).lowercased
        for candidate in candidates {
            if lowestScore >= 1, topResults.count >= maxResultsCount {
                break
            }

            let candidateLowercase = (candidate as NSString).lowercased
            let score: CGFloat
            if (candidateLowercase as NSString).contains(input) {
                score = 1
            } else {
                score = (input as NSString).score(against: candidateLowercase, fuzziness: 0.5, options: StringScore.Options.none.rawValue)
            }

            if topResults.count < maxResultsCount {
                topResults.append((candidate, score))
                if score < lowestScore {
                    lowestScore = score
                }
                continue
            }

            if score > lowestScore, let indexToDelete = topResults.indices.min(by: { topResults[$0].score < topResults[$1].score }) {
                topResults.remove(at: indexToDelete)
                topResults.append((candidate, score))
                lowestScore = topResults.map(\.score).min() ?? 0
            }
        }

        topResults.sort { $0.score > $1.score }
        return topResults.map(\.string)
    }

    /// 返回系统的 NSTextView.scrollableTextView()
    static func scrollableTextView() -> NSScrollView {
        NSTextView.scrollableTextView()
    }

    // Frame validation moved into LookinCore as LookinIsUsableRect, next to the
    // calculateFrameToRoot walk that consumes it.
}
