import Foundation
import LookinMCPCore

/// `lookinside-mcp health` — entry point developers hit when something looks off.
/// Output is plain text on stdout (humans read this directly) and the JSON-shaped
/// summary on stderr (for piping). Nonzero exit when nothing is reachable so it
/// composes with shell scripts and CI.
enum HealthCommand {
    static func run() -> Int32 {
        let client = LiveLookinClient(connectTimeout: 0.8)
        let apps = client.discover()
        print("lookinside-mcp \(LookinMCP.version)")
        if apps.isEmpty {
            print("status: no_target")
            print("No Debug build with LookinServer is currently reachable.")
            print("Try:")
            print("  • launch your app in a Simulator with LookinServer embedded (SPM or CocoaPods),")
            print("  • for a USB device, ensure usbmuxd is running and the device is unlocked,")
            print("  • or pass --snapshot <file.lookin> to serve from a captured snapshot.")
            return 1
        }
        print("status: ok")
        print("found \(apps.count) reachable app\(apps.count == 1 ? "" : "s"):")
        for app in apps {
            let name = app.appInfo.appName ?? "<unknown>"
            let bundle = app.appInfo.appBundleIdentifier ?? "<unknown>"
            print("  • \(name) (\(bundle)) — \(app.platform) port \(app.port)")
        }
        return 0
    }
}
