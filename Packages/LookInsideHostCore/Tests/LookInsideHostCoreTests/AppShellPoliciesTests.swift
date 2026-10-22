import Foundation
@testable import LookInsideHostCore
import Testing

struct ExpansionStatePolicyTests {
    @Test func keysKeepTheirStoredNames() {
        #expect(ExpansionStatePolicy.lruKey == "ExpansionStateBundleLRU")
        #expect(ExpansionStatePolicy.stateKey(forBundleIdentifier: "com.example.app") == "ExpansionState.com.example.app")
        #expect(ExpansionStatePolicy.capacity == 20)
    }

    @Test func movingToFrontDropsDuplicatesAndMalformedEntries() {
        let stored: [Any] = ["a", "b", 3, "", "c", "b"]
        #expect(ExpansionStatePolicy.lru(movingToFront: "b", in: stored) == ["b", "a", "c"])
        #expect(ExpansionStatePolicy.lru(movingToFront: "x", in: nil) == ["x"])
        #expect(ExpansionStatePolicy.lru(movingToFront: "x", in: "not an array") == ["x"])
    }

    @Test func evictionKeepsTheMostRecentEntries() {
        let lru = (0 ..< 22).map { "app\($0)" }
        let (kept, evicted) = ExpansionStatePolicy.evicting(lru)
        #expect(kept.count == 20)
        #expect(kept.first == "app0")
        #expect(evicted == ["app20", "app21"])
        #expect(ExpansionStatePolicy.evicting(["a"]).evicted.isEmpty)
    }

    @Test func bumpOnlyMovesARecordedIdThatIsNotFirst() {
        #expect(ExpansionStatePolicy.shouldBump("b", in: ["a", "b"]))
        #expect(!ExpansionStatePolicy.shouldBump("a", in: ["a", "b"]))
        #expect(!ExpansionStatePolicy.shouldBump("c", in: ["a", "b"]))
        #expect(!ExpansionStatePolicy.shouldBump("a", in: nil))
    }

    @Test func decodesTheDictionaryFormat() {
        let stored: NSDictionary = ["a/b": NSNumber(value: true), "a/c": NSNumber(value: false), "": NSNumber(value: true), "bad": "x"]
        #expect(ExpansionStatePolicy.decodeState(stored) == ["a/b": true, "a/c": false])
    }

    @Test func decodesTheLegacyArrayFormatAsExpanded() {
        let stored: NSArray = ["a/b", "", NSNumber(value: 1), "a/c"]
        #expect(ExpansionStatePolicy.decodeState(stored) == ["a/b": true, "a/c": true])
        #expect(ExpansionStatePolicy.decodeState(nil).isEmpty)
        #expect(ExpansionStatePolicy.decodeState("x").isEmpty)
    }

    @Test func roundTripsThroughUserDefaults() throws {
        let suite = "LookInsideHostCoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(["p": true, "q": false], forKey: "state")
        defaults.set(["p", "q"], forKey: "legacy")
        #expect(ExpansionStatePolicy.decodeState(defaults.object(forKey: "state")) == ["p": true, "q": false])
        #expect(ExpansionStatePolicy.decodeState(defaults.object(forKey: "legacy")) == ["p": true, "q": true])
    }
}

struct ServerVersionComparisonTests {
    @Test func numericVersionWeighsThreeComponents() {
        #expect(ServerVersionComparison.numericVersion("1.2.7") == 10207)
        #expect(ServerVersionComparison.numericVersion("1.2") == 10200)
        #expect(ServerVersionComparison.numericVersion("1.2.7.9") == 10207)
        #expect(ServerVersionComparison.numericVersion("0.2.9") == 209)
        #expect(ServerVersionComparison.numericVersion("2a.1") == 20100)
        #expect(ServerVersionComparison.numericVersion("") == 0)
    }

    @Test func comparesExpectedAgainstReal() {
        #expect(ServerVersionComparison.satisfies(expectedVersion: "1.2.7", realVersion: "1.2.7") == true)
        #expect(ServerVersionComparison.satisfies(expectedVersion: "1.2.7", realVersion: "1.3") == true)
        #expect(ServerVersionComparison.satisfies(expectedVersion: "1.2.7", realVersion: "1.2.6") == false)
        #expect(ServerVersionComparison.satisfies(expectedVersion: "1.2.7", realVersion: "") == nil)
    }
}

struct SwiftUISelectionMigrationTests {
    @Test func parsesThePreOrderIndex() {
        #expect(SwiftUISelectionMigration.preOrderIndex(of: "swiftui:abc:12") == 12)
        #expect(SwiftUISelectionMigration.preOrderIndex(of: "swiftui:abc:12x") == nil)
        #expect(SwiftUISelectionMigration.preOrderIndex(of: "swiftui") == nil)
        #expect(SwiftUISelectionMigration.preOrderIndex(of: "swiftui:abc:") == nil)
    }

    @Test func keepsAnIdThatSurvived() {
        let ids: [String?] = [nil, "swiftui:h:1", "swiftui:h:4"]
        #expect(SwiftUISelectionMigration.target(priorIdentifier: "swiftui:h:4", in: ids) == .exact(2))
    }

    @Test func movesToTheNextSurvivingItem() {
        let ids: [String?] = ["swiftui:h:9", "view:1", "swiftui:h:5", "swiftui:h:2"]
        #expect(SwiftUISelectionMigration.target(priorIdentifier: "swiftui:h:3", in: ids) == .migrated(2))
    }

    @Test func givesUpWithoutALaterItem() {
        let ids: [String?] = ["swiftui:h:1", "swiftui:h:2"]
        #expect(SwiftUISelectionMigration.target(priorIdentifier: "swiftui:h:3", in: ids) == .none)
        #expect(SwiftUISelectionMigration.target(priorIdentifier: "", in: ids) == .none)
        #expect(SwiftUISelectionMigration.target(priorIdentifier: "swiftui:h:x", in: ids) == .none)
    }
}
