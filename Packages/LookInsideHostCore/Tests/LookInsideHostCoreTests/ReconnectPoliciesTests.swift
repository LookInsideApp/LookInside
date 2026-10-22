import Foundation
@testable import LookInsideHostCore
import Testing

struct ChannelLivenessPolicyTests {
    private static let pingType: UInt32 = 200
    private static let appInfoType: UInt32 = 201
    private static let hierarchyType: UInt32 = 202

    private let policy = ChannelLivenessPolicy(probeRequestTypes: [Self.pingType, Self.appInfoType], silenceBeforeClosing: 5)

    @Test("a probe that times out on a channel silent for longer than the limit closes it", arguments: [pingType, appInfoType])
    func aTimedOutProbeOnASilentChannelClosesIt(requestType: UInt32) {
        #expect(policy.shouldCloseChannel(afterTimeoutOfRequestType: requestType, secondsSinceLastReceive: 5))
        #expect(policy.shouldCloseChannel(afterTimeoutOfRequestType: requestType, secondsSinceLastReceive: 60))
    }

    /// An app busy with a large refresh misses a 0.5 s ping but still sends
    /// progress and detail frames.
    @Test("a probe that times out on a channel that received data recently keeps it")
    func aTimedOutProbeOnAChannelStillReceivingKeepsIt() {
        #expect(!policy.shouldCloseChannel(afterTimeoutOfRequestType: Self.pingType, secondsSinceLastReceive: 4.9))
        #expect(!policy.shouldCloseChannel(afterTimeoutOfRequestType: Self.appInfoType, secondsSinceLastReceive: 0))
    }

    @Test("a timeout of a request other than a probe never closes the channel")
    func aTimeoutOfAnotherRequestKeepsTheChannel() {
        #expect(!policy.shouldCloseChannel(afterTimeoutOfRequestType: Self.hierarchyType, secondsSinceLastReceive: 600))
    }
}

struct ReconnectTargetSelectionTests {
    private static func identity(
        appName: String? = "Photos",
        bundleIdentifier: String? = "com.apple.mobileslideshow",
        deviceDescription: String? = "iPhone",
        deviceModelIdentifier: String? = "iPhone16,2",
        osDescription: String? = "iOS 26.4",
        deviceType: Int = 2
    ) -> InspectedAppIdentity {
        InspectedAppIdentity(
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            deviceDescription: deviceDescription,
            deviceModelIdentifier: deviceModelIdentifier,
            osDescription: osDescription,
            deviceType: deviceType
        )
    }

    private static func inspectable(_ identity: InspectedAppIdentity) -> ReconnectCandidate {
        ReconnectCandidate(identity: identity, canBeInspected: true)
    }

    @Test("the one app that is the lost app again is taken over")
    func theOneMatchingAppIsTakenOver() {
        let candidates = [
            Self.inspectable(Self.identity(appName: "Settings", bundleIdentifier: "com.apple.Preferences")),
            Self.inspectable(Self.identity()),
        ]
        #expect(ReconnectTargetSelection.candidateIndex(for: Self.identity(), among: candidates) == 1)
    }

    /// Two apps with one display name on one device: "iPhone" is all iOS 16
    /// and later report as the device description.
    @Test("an app with the same name but another bundle identifier is not taken over")
    func anotherBundleIdentifierIsNotTakenOver() {
        let candidates = [Self.inspectable(Self.identity(bundleIdentifier: "com.example.photos"))]
        #expect(ReconnectTargetSelection.candidateIndex(for: Self.identity(), among: candidates) == nil)
    }

    @Test("an app on another device model is not taken over")
    func anotherDeviceModelIsNotTakenOver() {
        let candidates = [Self.inspectable(Self.identity(deviceModelIdentifier: "iPhone15,3"))]
        #expect(ReconnectTargetSelection.candidateIndex(for: Self.identity(), among: candidates) == nil)
    }

    @Test("a Server that reports no bundle identifier or model is matched on the other fields")
    func missingOptionalFieldsDoNotPreventAMatch() {
        let olderServer = Self.identity(bundleIdentifier: nil, deviceModelIdentifier: nil)
        #expect(ReconnectTargetSelection.candidateIndex(for: Self.identity(), among: [Self.inspectable(olderServer)]) == 0)
        #expect(ReconnectTargetSelection.candidateIndex(for: olderServer, among: [Self.inspectable(Self.identity())]) == 0)
    }

    @Test("when several apps match, none is taken over")
    func severalMatchesAreNotTakenOver() {
        let candidates = [Self.inspectable(Self.identity()), Self.inspectable(Self.identity())]
        #expect(ReconnectTargetSelection.candidateIndex(for: Self.identity(), among: candidates) == nil)
    }

    /// An app whose Server is too old for this Host comes back without a
    /// channel; taking it over would leave the window with nothing to watch.
    @Test("an app the Host cannot inspect is not taken over")
    func anAppThatCannotBeInspectedIsNotTakenOver() {
        let candidates = [ReconnectCandidate(identity: Self.identity(), canBeInspected: false)]
        #expect(ReconnectTargetSelection.candidateIndex(for: Self.identity(), among: candidates) == nil)
    }

    @Test("an app that cannot be inspected does not make an inspectable match ambiguous")
    func anUninspectableTwinDoesNotBlockTheInspectableOne() {
        let candidates = [
            ReconnectCandidate(identity: Self.identity(), canBeInspected: false),
            Self.inspectable(Self.identity()),
        ]
        #expect(ReconnectTargetSelection.candidateIndex(for: Self.identity(), among: candidates) == 1)
    }

    @Test("an app without a name matches nothing, as InspectedAppInfo.isEqual(to:) has it")
    func aNilNameMatchesNothing() {
        let unnamed = Self.identity(appName: nil)
        #expect(ReconnectTargetSelection.candidateIndex(for: unnamed, among: [Self.inspectable(unnamed)]) == nil)
    }
}

struct ApplicationStatePushTests {
    @Test("the push reports the active flag the Server sent")
    func readsTheActiveFlag() {
        #expect(ApplicationStatePush.isActive(inPayload: ["active": NSNumber(value: false)] as NSDictionary) == false)
        #expect(ApplicationStatePush.isActive(inPayload: ["active": NSNumber(value: true)] as NSDictionary) == true)
    }

    @Test("a payload without the flag is ignored")
    func ignoresAPayloadWithoutTheFlag() {
        #expect(ApplicationStatePush.isActive(inPayload: nil) == nil)
        #expect(ApplicationStatePush.isActive(inPayload: NSDictionary()) == nil)
        #expect(ApplicationStatePush.isActive(inPayload: ["active": "yes"] as NSDictionary) == nil)
        #expect(ApplicationStatePush.isActive(inPayload: NSNumber(value: true)) == nil)
    }
}
