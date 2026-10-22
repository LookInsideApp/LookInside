// Fuzzy match score of an abbreviation against a string, ported from the
// Host's NSString+Score category (reference: http://jsfiddle.net/JrLVD/).
// The Host ranks Dashboard search suggestions with it. The walk runs over
// UTF-16 units through NSString, exactly as the original did, so scores
// stay identical for non-ASCII input.

import Foundation

public enum StringScore {
    public struct Options: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let none = Options(rawValue: 1 << 0)
        /// Divides by the string's length instead, so shorter words win.
        public static let favorSmallerWords = Options(rawValue: 1 << 1)
        public static let reducedLongStringPenalty = Options(rawValue: 1 << 2)
    }

    /// Letters and spaces survive; everything else is dropped before scoring.
    private static let invalidCharacters: CharacterSet = {
        var valid = CharacterSet.lowercaseLetters
        valid.formUnion(.uppercaseLetters)
        valid.insert(charactersIn: " ")
        return valid.inverted
    }()

    private static func decomposed(_ string: String) -> NSString {
        (string as NSString).decomposedStringWithCanonicalMapping
            .components(separatedBy: invalidCharacters)
            .joined() as NSString
    }

    /// Scores `abbreviation` against `string`: 1 for an exact match, 0 when
    /// a character is missing and `fuzziness` is nil, otherwise a weighted
    /// mix of matched characters, same-case, start-of-word and acronym
    /// bonuses.
    public static func score(_ string: String, against abbreviation: String, fuzziness: Double? = nil, options: Options = .none) -> Double {
        var remaining = decomposed(string)
        let other = decomposed(abbreviation)

        if remaining.isEqual(to: other as String) {
            return 1
        }
        if other.length == 0 {
            return 0
        }

        var totalCharacterScore: Double = 0
        let otherLength = other.length
        let stringLength = remaining.length
        var startOfStringBonus = false
        var fuzzies: Double = 1
        let otherUpper = other.uppercased as NSString
        let otherLower = other.lowercased as NSString
        // The original read the fuzziness through -[NSNumber floatValue].
        let fuzzinessValue = fuzziness.map { Double(Float($0)) } ?? 0
        let space = (" " as NSString).character(at: 0)

        for index in 0 ..< otherLength {
            var characterScore = 0.1
            var indexInString = NSNotFound
            let range = NSRange(location: index, length: 1)
            let character = other.character(at: index)
            let lowerLocation = remaining.range(of: otherLower.substring(with: range)).location
            let upperLocation = remaining.range(of: otherUpper.substring(with: range)).location

            if lowerLocation == NSNotFound, upperLocation == NSNotFound {
                guard fuzziness != nil else { return 0 }
                fuzzies += 1 - fuzzinessValue
            } else if lowerLocation != NSNotFound, upperLocation != NSNotFound {
                indexInString = min(lowerLocation, upperLocation)
            } else {
                indexInString = lowerLocation != NSNotFound ? lowerLocation : upperLocation
            }

            // Same-case bonus.
            if indexInString != NSNotFound, remaining.character(at: indexInString) == character {
                characterScore += 0.1
            }

            if indexInString == 0 {
                // Matching the first character of what is left of the string.
                characterScore += 0.6
                if index == 0 {
                    startOfStringBonus = true
                }
            } else if indexInString != NSNotFound {
                // Acronym bonus: the first letter of a word counts as if two
                // perfect matches came before it.
                if remaining.character(at: indexInString - 1) == space {
                    characterScore += 0.8
                }
            }

            // Matching is sequential: drop everything up to the match.
            if indexInString != NSNotFound {
                remaining = remaining.substring(from: indexInString + 1) as NSString
            }

            totalCharacterScore += characterScore
        }

        if options.contains(.favorSmallerWords) {
            return totalCharacterScore / Double(stringLength)
        }

        let otherStringScore = totalCharacterScore / Double(otherLength)
        var finalScore: Double
        if options.contains(.reducedLongStringPenalty) {
            // Integer division, as in the original (which gave 0 on arm64
            // for an empty string instead of trapping).
            let percentageOfMatchedString = stringLength == 0 ? 0 : Double(otherLength / stringLength)
            let wordScore = otherStringScore * percentageOfMatchedString
            finalScore = (wordScore + otherStringScore) / 2
        } else {
            finalScore = ((otherStringScore * (Double(otherLength) / Double(stringLength))) + otherStringScore) / 2
        }

        finalScore /= fuzzies

        if startOfStringBonus, finalScore + 0.15 < 1 {
            finalScore += 0.15
        }
        return finalScore
    }
}
