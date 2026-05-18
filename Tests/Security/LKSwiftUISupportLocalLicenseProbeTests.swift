import Foundation

@main
struct LKSwiftUISupportLocalLicenseProbeTests {
    static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
            .appendingPathComponent("local-license-probe", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        expect(
            LKSwiftUISupportLocalLicenseProbe.probe(stateURL: root.appendingPathComponent("missing.json")) == .missing,
            "missing state file"
        )

        let invalidJSON = root.appendingPathComponent("invalid.json")
        try "nope".write(to: invalidJSON, atomically: true, encoding: .utf8)
        expectUnreadable(
            LKSwiftUISupportLocalLicenseProbe.probe(stateURL: invalidJSON),
            "invalid json"
        )

        let emptyState = root.appendingPathComponent("empty.json")
        try "{}".write(to: emptyState, atomically: true, encoding: .utf8)
        expect(
            LKSwiftUISupportLocalLicenseProbe.probe(stateURL: emptyState) == .missing,
            "empty state"
        )

        let trialOnlyState = root.appendingPathComponent("trial.json")
        try #"{ "deviceFingerprint": { "deviceID": "device-1" } }"#
            .write(to: trialOnlyState, atomically: true, encoding: .utf8)
        expect(
            LKSwiftUISupportLocalLicenseProbe.probe(stateURL: trialOnlyState) == .missing,
            "trial-only disk state"
        )

        let paidLeaseState = root.appendingPathComponent("paid-lease.json")
        try #"{ "entitlementStatus": { "currentLease": { "certificateID": "cert-1" } } }"#
            .write(to: paidLeaseState, atomically: true, encoding: .utf8)
        expect(
            LKSwiftUISupportLocalLicenseProbe.probe(stateURL: paidLeaseState) == .present,
            "paid current lease"
        )

        let activationResponseState = root.appendingPathComponent("activation-response.json")
        try #"{ "activationResponse": { "activation": { "activationID": "activation-1" } } }"#
            .write(to: activationResponseState, atomically: true, encoding: .utf8)
        expect(
            LKSwiftUISupportLocalLicenseProbe.probe(stateURL: activationResponseState) == .present,
            "activation response"
        )
    }

    private static func expect(_ condition: Bool, _ message: String) {
        guard condition else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            Foundation.exit(1)
        }
    }

    private static func expectUnreadable(_ result: LKSwiftUISupportLocalLicenseProbeResult, _ message: String) {
        guard case .unreadable = result else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            Foundation.exit(1)
        }
    }
}
