//
//  PreferenceValuePolicy.swift
//  LookInsideHostCore
//
//  The ranges the Settings window keeps user-entered preference values in,
//  before the app target writes them to its PreferenceManager.
//

/// What the Settings window stores for a value the user entered.
public enum PreferenceValuePolicy {
    /// Request timeouts, in seconds.
    public static let timeoutRange: ClosedRange<Double> = 0.1 ... 120

    /// Image contrast levels: normal, medium and high.
    public static let imageContrastLevelRange: ClosedRange<Int> = 0 ... 2

    /// A typed timeout moved into `timeoutRange`. A value that is not
    /// finite, or not above 0, means nothing usable was entered, so it
    /// falls back to `defaultValue` instead.
    public static func sanitizedTimeout(_ value: Double, defaultValue: Double) -> Double {
        guard value.isFinite, value > 0 else {
            return defaultValue
        }
        return min(max(value, timeoutRange.lowerBound), timeoutRange.upperBound)
    }

    /// A contrast level moved into `imageContrastLevelRange`.
    public static func clampedImageContrastLevel(_ level: Int) -> Int {
        min(max(level, imageContrastLevelRange.lowerBound), imageContrastLevelRange.upperBound)
    }
}
