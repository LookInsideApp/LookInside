@testable import LookInsideHostCore
import Testing

struct PreferenceValuePolicyTests {
    @Test(arguments: [
        (typed: 15.0, stored: 15.0),
        (typed: 0.05, stored: 0.1),
        (typed: 500, stored: 120),
        (typed: 0, stored: 7),
        (typed: -3, stored: 7),
        (typed: .nan, stored: 7),
        (typed: .infinity, stored: 7),
    ])
    func aTypedTimeoutIsKeptBetweenATenthOfASecondAndTwoMinutes(typed: Double, stored: Double) {
        #expect(PreferenceValuePolicy.sanitizedTimeout(typed, defaultValue: 7) == stored)
    }

    @Test(arguments: [
        (chosen: -1, stored: 0),
        (chosen: 0, stored: 0),
        (chosen: 1, stored: 1),
        (chosen: 2, stored: 2),
        (chosen: 5, stored: 2),
    ])
    func theImageContrastLevelStaysBetweenNormalAndHigh(chosen: Int, stored: Int) {
        #expect(PreferenceValuePolicy.clampedImageContrastLevel(chosen) == stored)
    }
}
