import Darwin
import Foundation
import LookInsideInspectionCore
import LookInsideInspectionProtocol
import Security

/// GPL-side protocol client. Only the separately distributed authorization helper
/// reads private keys or signs challenges; this service never installs that helper.
@MainActor
final class InspectionAuthorization {
    private(set) var isActivated = false
    private(set) var failure = InspectionFailure.licenseRequired
    var onActivationChange: ((Bool) -> Void)?
    private let helperURL: URL
    private let socketPath: String
    private let stateURL: URL

    init() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let installedHelper = homeDirectory.appendingPathComponent("Library/Application Support/LookInside/AuthServer/current/lookinside-auth-server.app/Contents/MacOS/lookinside-auth-server")
        let installedSocket = homeDirectory.appendingPathComponent("Library/Application Support/LookInside/AuthServer/run/lookinside-auth-server.sock").path
        #if DEBUG
            helperURL = ProcessInfo.processInfo.environment["LOOKINSIDE_AUTH_SERVER_PATH"].map { URL(fileURLWithPath: $0) } ?? installedHelper
            socketPath = ProcessInfo.processInfo.environment["LOOKINSIDE_AUTH_SERVER_SOCKET_PATH"] ?? installedSocket
        #else
            helperURL = installedHelper
            socketPath = installedSocket
        #endif
        stateURL = homeDirectory.appendingPathComponent("Library/Application Support/LookInside/AuthServer/state/state.json")
    }

    func configureEnvironment() {
        let environment = InspectionEnvironment.shared()
        environment.licenseIsActivated = { [weak self] in MainActor.assumeIsolated { self?.isActivated == true } }
        environment.licenseProofForChallenge = { [weak self] challenge, errorPointer in
            do {
                let proof = try MainActor.assumeIsolated {
                    guard let self else { throw InspectionFailure.licenseRequired }
                    return try self.proof(for: challenge)
                }
                return proof.dictionary
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    func prepare(allowsUserInteraction: Bool = false) throws {
        let previous = isActivated
        defer { notifyActivationChange(previous: previous) }
        isActivated = false
        // A missing local license is a normal basic-inspection configuration.
        // No helper, network request, or trial is started in that case.
        guard allowsUserInteraction || FileManager.default.fileExists(atPath: stateURL.path) else { failure = .licenseRequired; return }
        do {
            let informationURL = helperURL.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Info.plist")
            guard FileManager.default.isExecutableFile(atPath: helperURL.path),
                  let data = try? Data(contentsOf: informationURL),
                  let information = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                  information["LookInsideSupportsNoninteractiveInspection"] as? Bool == true,
                  !allowsUserInteraction || information["LookInsideSupportsServiceOwnedInteraction"] as? Bool == true
            else {
                throw InspectionFailure(code: "license.helperUnavailable", message: "Install the current Auth Server through LookInside before using protected features from the CLI.")
            }
            var health: [String: InspectionValue]
            do { health = try request("health.ping") }
            catch let transportFailure as InspectionFailure where transportFailure.code == "service.unavailable" {
                try validateInstalledHelper()
                let runtime = try InspectionRuntimePaths(socketPath: socketPath)
                try runtime.prepareDirectory()
                _ = try InspectionServiceLauncher.launch(executableURL: helperURL,
                                                         arguments: ["--non-interactive", "--lookinside-pid", String(getpid()), "--socket-path", socketPath])
                let deadline = ProcessInfo.processInfo.systemUptime + 3
                while true {
                    do { health = try request("health.ping"); break }
                    catch let startupFailure as InspectionFailure where startupFailure.code == "service.unavailable" {
                        guard ProcessInfo.processInfo.systemUptime < deadline else { throw startupFailure }
                        Thread.sleep(forTimeInterval: 0.05)
                    }
                }
            }
            guard health["is_non_interactive"]?.booleanValue == true,
                  let ownerIdentifier = health["owner_process_identifier"]?.integerValue
            else {
                throw InspectionFailure(code: "license.helperUnavailable", message: "The running Auth Server does not support noninteractive inspection. Update it through LookInside.")
            }
            guard ownerIdentifier == Int64(getpid()) else {
                throw InspectionFailure(code: "service.ownerConflict", message: "The Auth Server belongs to another process. End that inspection before using the CLI.")
            }
            let decision = try request("license.check_access")["decision"]?.stringValue
            isActivated = decision == "allow" || decision == "allow_with_warning"
            failure = .licenseRequired
        } catch let failure as InspectionFailure {
            self.failure = failure
            if failure.code == "service.ownerConflict" || allowsUserInteraction {
                throw failure
            }
        } catch {
            failure = InspectionFailure(code: "license.helperUnavailable", message: "The authorization helper could not be contacted. Open LookInside to repair the helper installation.")
            if allowsUserInteraction {
                throw failure
            }
        }
    }

    func forward(_ envelope: InspectionValue) async throws -> InspectionValue {
        guard var request = envelope.objectValue, let method = request["method"]?.stringValue,
              ["health.ping", "license.check_access", "license.refresh_status", "ui.show_activation",
               "ui.show_activation_prompt", "ui.show_license", "ui.show_alert"].contains(method)
        else {
            throw InspectionFailure.invalidParameters
        }
        let allowsUserInteraction = method.hasPrefix("ui.") || method == "license.refresh_status"
        try prepare(allowsUserInteraction: allowsUserInteraction)
        request["allow_user_interaction"] = .bool(allowsUserInteraction)
        let data = try JSONEncoder().encode(InspectionValue.object(request))
        let socketPath = socketPath
        let responseData = try await Task.detached { [self] in
            try InspectionSocketClient.exchangeUntilEnd(data, socketPath: socketPath, timeout: 25,
                                                        validatePeer: validateHelperProcess)
        }.value
        let response = try JSONDecoder().decode(InspectionValue.self, from: responseData)
        guard let object = response.objectValue, object["protocol_version"]?.integerValue == 1,
              object["request_id"] == request["request_id"] else { throw InspectionFailure.internalError }
        if method == "license.check_access" || method == "license.refresh_status",
           let decision = object["payload"]?.objectValue?["decision"]?.stringValue
        {
            let previous = isActivated
            isActivated = decision == "allow" || decision == "allow_with_warning"
            notifyActivationChange(previous: previous)
        }
        return response
    }

    private func notifyActivationChange(previous: Bool) {
        guard previous != isActivated else { return }
        ConnectionManager.sharedInstance().authorizationStateDidChange()
        onActivationChange?(isActivated)
    }

    private func proof(for challenge: [String: Any]) throws -> InspectionLicenseProof {
        guard isActivated else { throw failure }
        guard let nonce = challenge["nonce"] as? Data, nonce.count == 32,
              let serverIdentifier = challenge["server_instance_id"] as? String, !serverIdentifier.isEmpty else { throw InspectionFailure.invalidParameters }
        do {
            let payload = try request("license.sign_challenge", payload: [
                "nonce": .string(nonce.map { String(format: "%02x", $0) }.joined()), "server_instance_id": .string(serverIdentifier),
            ])
            guard let signatureText = payload["signature"]?.stringValue, let signature = Data(base64Encoded: signatureText), !signature.isEmpty,
                  let certificateText = payload["intermediate_cert_der"]?.stringValue, let certificate = Data(base64Encoded: certificateText), !certificate.isEmpty,
                  let deviceIdentifier = payload["udid"]?.stringValue, !deviceIdentifier.isEmpty
            else {
                throw InspectionFailure(code: "license.helperUnavailable", message: "The Auth Server returned an invalid license proof.")
            }
            return InspectionLicenseProof(nonce: nonce, serverIdentifier: serverIdentifier, signature: signature, certificate: certificate, deviceIdentifier: deviceIdentifier)
        } catch let failure as InspectionFailure {
            self.failure = failure
            throw failure
        }
    }

    private func request(_ method: String, payload: [String: InspectionValue] = [:]) throws -> [String: InspectionValue] {
        let identifier = UUID().uuidString
        let envelope: InspectionValue = .object(["protocol_version": .integer(1), "request_id": .string(identifier), "method": .string(method), "payload": .object(payload)])
        let data = try InspectionSocketClient.exchangeUntilEnd(JSONEncoder().encode(envelope), socketPath: socketPath, timeout: 3, validatePeer: validateHelperProcess)
        guard let response = try JSONDecoder().decode(InspectionValue.self, from: data).objectValue,
              response["protocol_version"]?.integerValue == 1, response["request_id"]?.stringValue == identifier
        else {
            throw InspectionFailure(code: "license.helperUnavailable", message: "The Auth Server response is incompatible.")
        }
        if response["ok"]?.booleanValue != true {
            let error = response["error"]?.objectValue
            let code: String
            switch error?["code"]?.stringValue {
            case "interaction_required", "keychain_failure": code = "license.interactionRequired"
            case "client_in_use": code = "service.ownerConflict"
            case "license_not_activated": code = "license.entitlementRequired"
            case "invalid_request": code = "license.invalidClient"
            default: code = "license.helperUnavailable"
            }
            throw InspectionFailure(code: code, message: error?["message"]?.stringValue ?? "The authorization request failed.")
        }
        guard let payload = response["payload"]?.objectValue else { throw InspectionFailure.internalError }
        return payload
    }

    private func validateInstalledHelper() throws {
        #if !DEBUG
            var code: SecStaticCode?
            guard SecStaticCodeCreateWithPath(helperURL as CFURL, [], &code) == errSecSuccess, let code,
                  try SecStaticCodeCheckValidity(code, [], helperRequirement()) == errSecSuccess else { throw invalidHelper() }
        #endif
    }

    private nonisolated func validateHelperProcess(_ processIdentifier: pid_t) throws {
        #if !DEBUG
            var code: SecCode?
            guard SecCodeCopyGuestWithAttributes(nil, [kSecGuestAttributePid: processIdentifier] as CFDictionary, [], &code) == errSecSuccess, let code,
                  try SecCodeCheckValidity(code, [], helperRequirement()) == errSecSuccess else { throw invalidHelper() }
        #endif
    }

    private nonisolated func helperRequirement() throws -> SecRequirement {
        var requirement: SecRequirement?
        let text = "anchor apple generic and identifier \"app.lookinside.LookInsideAuthServer\" and certificate leaf[subject.OU] = \"964G86XT2P\""
        guard SecRequirementCreateWithString(text as CFString, [], &requirement) == errSecSuccess, let requirement else { throw invalidHelper() }
        return requirement
    }

    private nonisolated func invalidHelper() -> InspectionFailure {
        InspectionFailure(code: "license.invalidClient", message: "The Auth Server code signature does not match the trusted helper identity.")
    }
}

private struct InspectionLicenseProof: Sendable {
    let nonce: Data
    let serverIdentifier: String
    let signature: Data
    let certificate: Data
    let deviceIdentifier: String

    var dictionary: [String: Any] {
        ["nonce": nonce, "server_instance_id": serverIdentifier, "signature": signature, "intermediate_cert_der": certificate, "udid": deviceIdentifier]
    }
}
