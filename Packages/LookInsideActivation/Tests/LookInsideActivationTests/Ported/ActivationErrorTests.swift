import Foundation
@testable import LookInsideActivation
import Testing

struct ActivationErrorTests {
    struct Sample: Sendable {
        let error: ActivationError
        let expectedCode: String
    }

    /// The codes are the strings the 2.3.x helper sent over its socket.
    @Test(arguments: [
        Sample(error: .invalidRequest("bad"), expectedCode: "invalid_request"),
        Sample(error: .keychainFailure("k"), expectedCode: "keychain_failure"),
        Sample(error: .keychainAccessDenied(-128), expectedCode: "keychain_failure"),
        Sample(error: .stateStoreFailure("s"), expectedCode: "state_store_failure"),
        Sample(error: .licenseNotActivated("l"), expectedCode: "license_not_activated"),
        Sample(error: .signingFailed("f"), expectedCode: "signing_failed"),
        Sample(error: .signingDeferred, expectedCode: "signing_failed"),
        Sample(error: .activationFailed("a"), expectedCode: "activation_failed"),
    ])
    func errorCodeMapsEachCase(sample: Sample) {
        #expect(sample.error.errorCode == sample.expectedCode)
    }

    @Test func licenseNotActivatedMessageMatchesHelper() {
        let error = ActivationError.licenseNotActivated("detail")
        #expect(error.errorDescription == "License is not activated on this device.\ndetail")
    }
}
