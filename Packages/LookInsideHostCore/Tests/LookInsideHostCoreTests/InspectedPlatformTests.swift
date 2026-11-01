@testable import LookInsideHostCore
import Testing

/// Watch apps are inspected read-only; every other platform can be changed.
@Suite("Inspected platform")
struct InspectedPlatformTests {
    @Test("A watch app is read-only", arguments: ["watchOS 27.2", "watchOS 26.0", "WATCHOS 26"])
    func watchAppIsReadOnly(osDescription: String) {
        #expect(InspectedPlatform.isWatchOS(osDescription: osDescription))
        #expect(!InspectedPlatform.allowsModification(osDescription: osDescription))
    }

    @Test("Other apps can be changed", arguments: ["iOS 26.4", "tvOS 27.2", "macOS 27.1", "macCatalyst 27.1", ""])
    func otherAppsCanBeChanged(osDescription: String) {
        #expect(!InspectedPlatform.isWatchOS(osDescription: osDescription))
        #expect(InspectedPlatform.allowsModification(osDescription: osDescription))
    }

    @Test("An app without app info can be changed, as before")
    func missingAppInfoCanBeChanged() {
        #expect(InspectedPlatform.allowsModification(osDescription: nil))
    }
}
