import AppKit
import UIFoundationToolbox

/// Resolves the icon shown for the device an inspected app runs on.
///
/// Real hardware gets the full-colour artwork Apple ships for that exact model in
/// CoreTypes.bundle — the same icon About This Mac and the Finder sidebar use — resolved
/// from the model identifier LookinServer reports (e.g. "iPhone16,2", "Mac15,7"). A
/// simulator gets an SF Symbol of the simulated device family instead, so a simulated
/// iPhone stays visually distinct from a real one at a glance.
///
/// Returns nil whenever no model-based icon applies, in which case callers fall back to
/// their asset catalog artwork. That happens for a LookinServer predating
/// `deviceModelIdentifier`, for a host appInfo cached before this field existed, and for
/// a model this macOS does not declare (hardware newer than the host OS, or a VM).
@objc(LKDeviceIconProvider)
final class LKDeviceIconProvider: NSObject {
    /// Height of the device icon in the window toolbar, matching the legacy
    /// `icon_*_small` assets (32 pixels at 2x).
    @objc static let toolbarPointSize: CGFloat = 16

    /// Height of the device icon in a tips view, whose image view has a fixed 18×18 frame.
    @objc static let tipsPointSize: CGFloat = 18

    /// Height of the device icon on a launch app card, matching the legacy `icon_*_big`
    /// assets (72 pixels at 2x).
    @objc static let launchPointSize: CGFloat = 36

    /// The fraction of its square canvas that CoreTypes device artwork actually fills;
    /// the rest is transparent padding. Measured from the shipped icns at several sizes.
    private static let deviceArtworkFillRatio: CGFloat = 0.8

    /// The device icon for an inspected app, or nil when the caller should fall back to
    /// its own asset catalog image.
    ///
    /// - Parameters:
    ///   - appInfo: The inspected app's info, as reported by LookinServer.
    ///   - pointSize: The height the icon is laid out at, in points.
    @objc(deviceIconForAppInfo:pointSize:)
    static func deviceIcon(forAppInfo appInfo: LookinAppInfo?, pointSize: CGFloat) -> NSImage? {
        guard let appInfo,
              let modelIdentifier = appInfo.deviceModelIdentifier,
              modelIdentifier.isEmpty == false
        else {
            return nil
        }
        if appInfo.deviceType == .simulator {
            return simulatorIcon(forModelIdentifier: modelIdentifier, pointSize: pointSize)
        }
        return hardwareIcon(forModelIdentifier: modelIdentifier, pointSize: pointSize)
    }

    /// The full-colour CoreTypes icon for a physical device.
    private static func hardwareIcon(forModelIdentifier modelIdentifier: String, pointSize: CGFloat) -> NSImage? {
        guard let icon = NSWorkspace.shared.box.declaredDeviceIcon(forModelIdentifier: modelIdentifier),
              let resizedIcon = icon.copy() as? NSImage
        else {
            return nil
        }
        // Resize a copy: NSWorkspace vends a shared multi-representation icns, and setting
        // `size` on it would resize the icon for every other caller in the process too.
        resizedIcon.size = NSSize(width: pointSize, height: pointSize)
        return resizedIcon
    }

    /// A template SF Symbol standing in for a simulated device.
    ///
    /// The symbol is deliberately monochrome line art rather than the simulated model's
    /// colour icon — the point is that a simulator reads as a simulator. Callers display
    /// it as a template image, so it picks up the surrounding control tint.
    private static func simulatorIcon(forModelIdentifier modelIdentifier: String, pointSize: CGFloat) -> NSImage? {
        guard let symbolIcon = NSWorkspace.shared.box.declaredDeviceSymbolIcon(forModelIdentifier: modelIdentifier) else {
            return nil
        }
        let symbolConfiguration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        guard let configuredIcon = symbolIcon.withSymbolConfiguration(symbolConfiguration),
              configuredIcon.size.width > 0, configuredIcon.size.height > 0
        else {
            return nil
        }
        // Draw the symbol into a square box of exactly `pointSize`, filling the same
        // fraction of it that CoreTypes artwork does. Two things force this. A symbol's
        // rendered box overshoots its point size by a per-symbol amount ("iphone.gen3" is
        // 19pt tall at point size 16, "macbook.gen2" is 27pt wide), and the toolbar lays
        // this image view out with sizeToFit, so an unnormalised box would shift every
        // control after it. And an edge-to-edge symbol reads as noticeably larger than the
        // padded colour icon a neighbouring real device gets.
        let artworkScale = min(
            pointSize * Self.deviceArtworkFillRatio / configuredIcon.size.width,
            pointSize * Self.deviceArtworkFillRatio / configuredIcon.size.height
        )
        let artworkSize = NSSize(
            width: configuredIcon.size.width * artworkScale,
            height: configuredIcon.size.height * artworkScale
        )
        let boxedIcon = NSImage(size: NSSize(width: pointSize, height: pointSize), flipped: false) { boxRect in
            configuredIcon.draw(in: NSRect(
                x: boxRect.midX - artworkSize.width / 2,
                y: boxRect.midY - artworkSize.height / 2,
                width: artworkSize.width,
                height: artworkSize.height
            ))
            return true
        }
        boxedIcon.isTemplate = true
        return boxedIcon
    }
}
