// What the Host offers for an inspected app, decided by the platform its app
// info names (`InspectedAppInfo.osDescription`, "watchOS 27.2" and the like).

import Foundation

public enum InspectedPlatform {
    /// Whether the app runs watchOS.
    public static func isWatchOS(osDescription: String?) -> Bool {
        (osDescription ?? "").lowercased().hasPrefix("watchos")
    }

    /// Whether the Host offers changing the app: editing attributes, calling
    /// methods, switching gesture recognizers. A watchOS Server is inspected
    /// read-only and refuses every such request, so the Host does not offer
    /// them there.
    public static func allowsModification(osDescription: String?) -> Bool {
        !isWatchOS(osDescription: osDescription)
    }
}
