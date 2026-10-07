//
//  NSString+LookinClient.swift
//  LookInside
//

import Foundation
import LookInsideHostCore

extension NSString {
    /// The string with its first UTF-16 unit uppercased; nil when empty.
    @objc func lk_capitalizedString() -> String? {
        guard length > 0 else { return nil }
        return (substring(to: 1) as NSString).uppercased + substring(from: 1)
    }

    @objc(scoreAgainst:)
    func score(against otherString: String) -> CGFloat {
        score(against: otherString, fuzziness: nil)
    }

    @objc(scoreAgainst:fuzziness:)
    func score(against otherString: String, fuzziness: NSNumber?) -> CGFloat {
        score(against: otherString, fuzziness: fuzziness, options: StringScore.Options.none.rawValue)
    }

    /// Fuzzy match score of `otherString` (an abbreviation) against this
    /// string; `options` takes the NSStringScoreOption bits.
    @objc(scoreAgainst:fuzziness:options:)
    func score(against otherString: String, fuzziness: NSNumber?, options: UInt) -> CGFloat {
        StringScore.score(self as String, against: otherString, fuzziness: fuzziness?.doubleValue, options: StringScore.Options(rawValue: options))
    }
}
