import Foundation
import LookInsideInspectionCore

enum RACBridgeError: Error, LocalizedError {
    case completedWithoutValue
    case cancelled

    var errorDescription: String? {
        switch self {
        case .completedWithoutValue:
            return "The source signal completed without producing a valid value."
        case .cancelled:
            return "Waiting for the inspection result was cancelled."
        }
    }
}

/// Keeps the bridge's error contract while sharing the core's cancellation-safe
/// continuation adapter. Disposing a waiter leaves a sent session request draining.
@MainActor
enum LKMCPBridgeRACBridge {
    static func awaitAllValues<Element>(
        of signal: RACSignal<AnyObject>,
        as elementType: Element.Type = Element.self
    ) async throws -> [Element] {
        do {
            return try await InspectionSignalAwaiter.allValues(of: signal, as: elementType)
        } catch is CancellationError {
            throw RACBridgeError.cancelled
        } catch InspectionSignalError.invalidResponse {
            throw RACBridgeError.completedWithoutValue
        }
    }

    static func awaitFirstValue<Value>(
        of signal: RACSignal<AnyObject>,
        as valueType: Value.Type = Value.self
    ) async throws -> Value {
        let values = try await awaitAllValues(of: signal.take(1), as: valueType)
        guard let value = values.first else {
            throw RACBridgeError.completedWithoutValue
        }
        return value
    }
}
