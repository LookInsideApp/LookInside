import Foundation

@main
struct LKInjectionStartGateTests {
    static func main() {
        var gate = LKInjectionStartGate()
        var gateChecks = 0

        let blocked = gate.begin {
            gateChecks += 1
            return false
        }
        expect(blocked == .blocked, "denied gate blocks")
        expect(gateChecks == 1, "denied gate checks access once")
        expect(gate.isInProgress == false, "denied gate does not enter in-progress state")

        let started = gate.begin {
            gateChecks += 1
            return true
        }
        expect(started == .started, "allowed gate starts")
        expect(gateChecks == 2, "allowed gate checks access")
        expect(gate.isInProgress, "started gate enters in-progress state")

        let reentry = gate.begin {
            gateChecks += 1
            return true
        }
        expect(reentry == .alreadyInProgress, "reentry is ignored")
        expect(gateChecks == 2, "reentry does not re-check access")
        expect(gate.isInProgress, "reentry keeps in-progress state")

        gate.finish()
        expect(gate.isInProgress == false, "finish clears in-progress state")

        let restarted = gate.begin {
            gateChecks += 1
            return true
        }
        expect(restarted == .started, "gate can start after finish")
        expect(gateChecks == 3, "restart checks access")

        expect(
            LKInjectionDaemonReadiness.nextStep(for: .enabled) == .proceed,
            "enabled daemon proceeds without prompting"
        )
        expect(
            LKInjectionDaemonReadiness.nextStep(for: .notRegistered) == .requestRegistrationConsent,
            "unregistered daemon asks for explicit user consent"
        )
        expect(
            LKInjectionDaemonReadiness.nextStep(for: .requiresApproval) == .waitForApproval,
            "pending daemon approval waits for system approval"
        )
        expect(
            LKInjectionDaemonReadiness.nextStep(for: .notFound) == .reportMissingBundle,
            "missing bundled daemon is reported as a damaged app bundle"
        )
        expect(
            LKInjectionDaemonReadiness.nextStep(for: .unknown(42)) == .reportUnsupportedStatus(42),
            "unknown daemon status is surfaced as unsupported"
        )
    }

    private static func expect(_ condition: Bool, _ message: String) {
        guard condition else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            Foundation.exit(1)
        }
    }
}
