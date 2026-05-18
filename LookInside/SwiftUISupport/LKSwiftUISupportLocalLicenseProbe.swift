import Foundation

enum LKSwiftUISupportLocalLicenseProbeResult: Equatable {
    case present
    case missing
    case unreadable(String)

    var hasPersistedLicenseMaterial: Bool {
        switch self {
        case .present:
            return true
        case .missing, .unreadable:
            return false
        }
    }

    var debugDescription: String {
        switch self {
        case .present:
            return "present"
        case .missing:
            return "missing"
        case let .unreadable(message):
            return "unreadable: \(message)"
        }
    }
}

enum LKSwiftUISupportLocalLicenseProbe {
    static var defaultStateURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(
                "Library/Application Support/LookInside/AuthServer/state/state.json",
                isDirectory: false
            )
    }

    static func probe() -> LKSwiftUISupportLocalLicenseProbeResult {
        probe(stateURL: defaultStateURL)
    }

    static func probe(stateURL: URL) -> LKSwiftUISupportLocalLicenseProbeResult {
        let data: Data
        do {
            data = try Data(contentsOf: stateURL)
        } catch CocoaError.fileReadNoSuchFile {
            return .missing
        } catch {
            return .unreadable(error.localizedDescription)
        }

        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            return .unreadable(error.localizedDescription)
        }

        guard let state = object as? [String: Any] else {
            return .unreadable(
                NSLocalizedString("Auth Server state file is not a JSON object.", comment: "")
            )
        }

        if hasDictionaryValue(forKey: "activationResponse", in: state) {
            return .present
        }

        guard let entitlementStatus = state["entitlementStatus"] as? [String: Any] else {
            return .missing
        }

        if hasDictionaryValue(forKey: "currentLease", in: entitlementStatus) {
            return .present
        }

        return .missing
    }

    private static func hasDictionaryValue(forKey key: String, in dictionary: [String: Any]) -> Bool {
        guard let value = dictionary[key], !(value is NSNull) else {
            return false
        }
        guard let nested = value as? [String: Any] else {
            return false
        }
        return nested.isEmpty == false
    }
}
