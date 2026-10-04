import Foundation

/// The control protocol LookInside speaks to the iOS injector over USB.
///
/// **This is a contract with a different build, in a different repository.**
/// The other end is `LookInsideDeviceControlWire.swift` in `LookInside-Injector`,
/// and the two files must agree key for key. They are duplicated rather than
/// shared for the same reason `LookinCore` is (see this monorepo's
/// `docs/monorepo/protocol.md`): the injector is a Tuist project with no SwiftPM
/// manifest, so there is nothing for this Xcode project to depend on, and a
/// relative path across two submodules would not survive either repository
/// being checked out on its own.
///
/// What keeps them honest is `LKDeviceControlWireFormatTests`, which pins the
/// encoded JSON rather than only a round trip — a round trip inside one process
/// passes however both ends are wrong.
enum LKDeviceControlWire {
    /// The port the injector listens on inside the device, reached through
    /// usbmuxd.
    ///
    /// After the server's own three ranges — 47164–47169 (simulator),
    /// 47170–47174 (macOS), 47175–47179 (device) — so a single number is
    /// enough: a device runs one injector, where it may run several inspectable
    /// apps.
    static let portNumber: Int32 = 47180

    /// Peertalk frame types. 0 is Peertalk's own end-of-stream marker.
    static let requestFrameType: UInt32 = 1
    static let responseFrameType: UInt32 = 2
}

/// One command, as it travels.
struct LKDeviceControlRequest: Codable, Hashable {
    /// Which command. A plain `String` because that is what the injector reads
    /// it as — it answers an unknown name with a failure that quotes it, rather
    /// than failing to parse.
    var command: String

    /// Set only for ``LKDeviceControlCommand/injectIntoProcess``.
    var processIdentifier: pid_t?

    init(_ command: LKDeviceControlCommand, processIdentifier: pid_t? = nil) {
        self.command = command.wireName
        self.processIdentifier = processIdentifier
    }
}

/// The three commands the injector answers.
///
/// The names carry no `device` prefix deliberately: the same three could serve
/// another kind of peer later, and `deviceProcessList` would be wrong the
/// moment they did.
enum LKDeviceControlCommand: String, CaseIterable {
    case injectionCapability
    case processList
    case injectIntoProcess

    var wireName: String {
        "app.lookinside.injector.control." + rawValue
    }
}

/// How one request turned out.
///
/// Generic over the result because both ends know which command a frame tag
/// belongs to. The failure case names no result type, which is what lets the
/// injector answer a command it could not even identify.
enum LKDeviceControlOutcome<Result: Codable & Hashable>: Codable, Hashable {
    case succeeded(Result)
    case failed(message: String)

    private enum CodingKeys: String, CodingKey {
        case result
        case failureMessage
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let failureMessage = try container.decodeIfPresent(String.self, forKey: .failureMessage) {
            self = .failed(message: failureMessage)
        } else {
            self = .succeeded(try container.decode(Result.self, forKey: .result))
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .succeeded(let result):
            try container.encode(result, forKey: .result)
        case .failed(let message):
            try container.encode(message, forKey: .failureMessage)
        }
    }
}

/// Whether a device can inject, and when it cannot, why.
///
/// The reason is written by the device and shown as-is. Only that end knows its
/// own entitlements, whether it has a payload, and whether it is allowed to
/// stay resident in the background.
enum LKDeviceControlCapability: Codable, Hashable {
    case available
    case unsupported(reason: String)

    private enum CodingKeys: String, CodingKey {
        case unsupportedReason
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let reason = try container.decodeIfPresent(String.self, forKey: .unsupportedReason) {
            self = .unsupported(reason: reason)
        } else {
            self = .available
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .available:
            break
        case .unsupported(let reason):
            try container.encode(reason, forKey: .unsupportedReason)
        }
    }

    var isAvailable: Bool {
        switch self {
        case .available: true
        case .unsupported: false
        }
    }

    var unsupportedReason: String? {
        switch self {
        case .available: nil
        case .unsupported(let reason): reason
        }
    }
}

/// One target on the device.
///
/// An application rather than a bare process, even though the command is
/// `processList`: the injector's lister answers "installed ∩ running", which
/// gives a row the user recognizes by name instead of by executable path.
struct LKDeviceControlProcess: Codable, Hashable {
    var processIdentifier: pid_t
    var name: String
    var bundleIdentifier: String?
    var executablePath: String?

    /// An Apple system application, and therefore an arm64e process.
    var isSystemApplication: Bool

    /// The device's verdict. Carried with the row because this Mac cannot work
    /// it out — only the device knows its own uid and the target's.
    var injectability: LKDeviceControlInjectability
}

/// What the device said about injecting into one target.
enum LKDeviceControlInjectability: Codable, Hashable {
    /// Nothing ruled it out. **Not a promise** — it is also the answer for a
    /// target whose uid could not be read.
    case injectable

    /// The target runs as root and the injector does not. No set of
    /// entitlements gets a uid 501 process the task port of a uid 0 one.
    case requiresRootOnTarget

    case notInjectable(reason: String)

    private enum CodingKeys: String, CodingKey {
        case kind
        case reason
    }

    private enum Kind: String, Codable {
        case injectable
        case requiresRootOnTarget
        case notInjectable
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .injectable:
            self = .injectable
        case .requiresRootOnTarget:
            self = .requiresRootOnTarget
        case .notInjectable:
            self = .notInjectable(reason: try container.decode(String.self, forKey: .reason))
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .injectable:
            try container.encode(Kind.injectable, forKey: .kind)
        case .requiresRootOnTarget:
            try container.encode(Kind.requiresRootOnTarget, forKey: .kind)
        case .notInjectable(let reason):
            try container.encode(Kind.notInjectable, forKey: .kind)
            try container.encode(reason, forKey: .reason)
        }
    }

    var isInjectable: Bool {
        switch self {
        case .injectable: true
        case .requiresRootOnTarget, .notInjectable: false
        }
    }

    /// Why this row cannot be picked, or `nil` when it can.
    var refusalReason: String? {
        switch self {
        case .injectable:
            nil
        case .requiresRootOnTarget:
            NSLocalizedString(
                "That process runs as root, and the injector on the device does not — it cannot take a root process's task port whatever entitlements it carries.",
                comment: ""
            )
        case .notInjectable(let reason):
            reason
        }
    }
}

/// How one injection ended.
///
/// Arrives inside a `succeeded` outcome even when it did not work: the request
/// ran, and these four cases have four different remedies that one failure
/// string would flatten.
enum LKDeviceControlInjectionResult: Codable, Hashable {
    case injected
    case taskPortUnavailable(reason: String)
    case targetRefusedPayload(reason: String)
    case failed(code: Int, reason: String)

    private enum CodingKeys: String, CodingKey {
        case kind
        case reason
        case code
    }

    private enum Kind: String, Codable {
        case injected
        case taskPortUnavailable
        case targetRefusedPayload
        case failed
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .injected:
            self = .injected
        case .taskPortUnavailable:
            self = .taskPortUnavailable(reason: try container.decode(String.self, forKey: .reason))
        case .targetRefusedPayload:
            self = .targetRefusedPayload(reason: try container.decode(String.self, forKey: .reason))
        case .failed:
            self = .failed(
                code: try container.decode(Int.self, forKey: .code),
                reason: try container.decode(String.self, forKey: .reason)
            )
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .injected:
            try container.encode(Kind.injected, forKey: .kind)
        case .taskPortUnavailable(let reason):
            try container.encode(Kind.taskPortUnavailable, forKey: .kind)
            try container.encode(reason, forKey: .reason)
        case .targetRefusedPayload(let reason):
            try container.encode(Kind.targetRefusedPayload, forKey: .kind)
            try container.encode(reason, forKey: .reason)
        case .failed(let code, let reason):
            try container.encode(Kind.failed, forKey: .kind)
            try container.encode(code, forKey: .code)
            try container.encode(reason, forKey: .reason)
        }
    }

    var isInjected: Bool {
        switch self {
        case .injected: true
        case .taskPortUnavailable, .targetRefusedPayload, .failed: false
        }
    }

    var failureReason: String? {
        switch self {
        case .injected: nil
        case .taskPortUnavailable(let reason), .targetRefusedPayload(let reason): reason
        case .failed(_, let reason): reason
        }
    }
}
