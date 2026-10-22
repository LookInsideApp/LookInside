// The `.lookin` export's naming and image-quality choices, shared by the save
// panel accessory and the exporter.

import Foundation

public enum ExportNaming {
    /// The image-quality choices the save panel offers, as scale factors.
    public static let compressionOptions: [Double] = [0.1, 0.3, 0.5, 0.75, 1]

    /// The menu title of a quality choice: the percentage as `NSNumber`
    /// prints it, then "%" (`@"%@%%"` with `@(value * 100)`).
    public static func compressionTitle(_ compression: Double) -> String {
        "\(NSNumber(value: compression * 100))%"
    }

    /// The index of the first choice within 0.05 of `compression`, or nil.
    public static func compressionIndex(for compression: Double) -> Int? {
        compressionOptions.firstIndex { abs(compression - $0) < 0.05 }
    }

    /// `<app>_ios<major>_<MMddHHmm>.lookin`. The major version is
    /// `osDescription` up to its first dot; a missing value prints as "(null)",
    /// as the Objective-C format did.
    public static func fileName(
        appName: String?,
        osDescription: String?,
        date: Date,
        timeZone: TimeZone = .current,
        locale: Locale = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = locale
        formatter.dateFormat = "MMddHHmm"
        let time = formatter.string(from: date)
        let osMajor = osDescription.map { description in
            description.firstIndex(of: ".").map { String(description[..<$0]) } ?? description
        }
        return "\(appName ?? "(null)")_ios\(osMajor ?? "(null)")_\(time).lookin"
    }

    /// The size line of the save panel accessory, in megabytes (10^6 bytes).
    public static func megabytes(_ byteCount: UInt) -> Double {
        Double(byteCount) / 1000.0 / 1000.0
    }
}
