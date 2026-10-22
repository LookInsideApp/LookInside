@testable import LookInsideActivation
import Testing

@Test(arguments: [
    (LicenseClass.full, true, ActivationPath.direct),
    (LicenseClass.full, false, ActivationPath.direct),
    (LicenseClass.trial, true, ActivationPath.timeAnchored),
    (LicenseClass.trial, false, ActivationPath.direct),
])
func activationPolicySelectsExpectedPath(
    licenseClass: LicenseClass,
    requiresSecureTimestampForTrial: Bool,
    expectedPath: ActivationPath
) {
    let policy = ActivationPolicy(requiresSecureTimestampForTrial: requiresSecureTimestampForTrial)

    #expect(policy.activationPath(for: licenseClass) == expectedPath)
}
