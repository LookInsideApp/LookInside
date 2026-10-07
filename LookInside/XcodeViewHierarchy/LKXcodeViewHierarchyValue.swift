// LKXcodeViewHierarchyValue.swift
//
// The value model of an Xcode `.viewhierarchy` capture, and the decoder that
// turns a JSON property description into it.
//
// Every property in the file is a pair of a JSON value and a `propertyFormat`
// string; the format is what says how to read the value. The scheme is Xcode's,
// recovered from `DBGDecodeValueFromJSONCompatibleValue` in
// DebugHierarchyFoundation, and it works like this:
//
//   * The format is a comma-separated list of specifiers. Two or more
//     specifiers mean the JSON value is an array of exactly that many
//     elements, each decoded by its own specifier — this is how a CGRect
//     ("CGf, CGf, CGf, CGf") or a CATransform3D (sixteen of them) travels.
//   * A single specifier decodes a scalar carried as a JSON *string*, or a
//     structured value carried as a JSON dictionary.
//   * Every floating-point number is a C99 hexadecimal float ("0x1.1e58p+3"),
//     never a decimal literal, so it round-trips exactly.
//   * The literal format "custom" means "no schema" and the value passes
//     through untouched.
//
// Numbers inside an image's `metadata` are the one documented exception: they
// are ordinary JSON numbers rather than hex-float strings.
//
// Integer radix is per specifier, and it is not consistent. Xcode reads each
// one with a fixed `sscanf` format, and these are those formats:
//
//     i  %d      ui  %u       decimal
//     l  %ld     ul  %lx      unsigned long is HEXADECIMAL
//     ll %lld    ull %llx     unsigned long long is HEXADECIMAL
//     integer %ld            uinteger %lx (via unsigned long)
//
// So `ui` is decimal while `ul`, `ull` and `uinteger` are unprefixed
// hexadecimal — an inconsistency in Xcode's own reader that a compatible
// reader has to reproduce exactly. Reading `uinteger` as decimal is the
// dangerous mistake here: "100" then yields 100 instead of 256, and only
// values containing a-f announce the error.

import Foundation

// MARK: - Structured payloads

/// A reference to another object in the capture, as carried by properties like
/// a constraint's `firstItem` or a layer's `delegate`.
struct LKXcodeViewHierarchyObjectReference: Equatable {
    let className: String
    let objectIdentifier: String
}

struct LKXcodeViewHierarchyImageMetadata: Equatable {
    let width: Double
    let height: Double
    let imageName: String?
    let bundleIdentifier: String?
    let isSystemSymbol: Bool
    let isFromMainBundle: Bool
    let isUIKitImage: Bool
    let symbolConfigurationSummary: String?
    let baselineOffsetFromBottom: Double?
}

struct LKXcodeViewHierarchyImage: Equatable {
    /// Encoded image bytes; PNG unless a more specific type identifier says otherwise.
    let encodedData: Data
    let typeIdentifier: String
    let metadata: LKXcodeViewHierarchyImageMetadata?
}

struct LKXcodeViewHierarchyColor: Equatable {
    let colorSpaceName: String
    let components: [Double]
    let colorName: String?
    let catalogName: String?
}

struct LKXcodeViewHierarchyFont: Equatable {
    let fontName: String
    let familyName: String
    let pointSize: Double
    let ascender: Double
    let descender: Double
    let leading: Double
    let capHeight: Double
    let xHeight: Double
    let lineHeight: Double?
}

// MARK: - Value

indirect enum LKXcodeViewHierarchyValue: Equatable {
    case boolean(Bool)
    case number(Double)
    case integer(Int64)
    case unsignedInteger(UInt64)
    case text(String)
    case binaryData(Data)
    case image(LKXcodeViewHierarchyImage)
    case color(LKXcodeViewHierarchyColor)
    case font(LKXcodeViewHierarchyFont)
    case objectReference(LKXcodeViewHierarchyObjectReference)
    case list([LKXcodeViewHierarchyValue])
    /// A value the capture declared as schema-less ("custom"), kept as its JSON text.
    case custom(String)
    /// The property exists but carries no value (unfetched, unchanged, or explicitly nil).
    case absent
}

extension LKXcodeViewHierarchyValue {
    /// Convenience for the geometry the conversion layer cares about most.
    var doubleValue: Double? {
        switch self {
        case let .number(value): return value
        case let .integer(value): return Double(value)
        case let .unsignedInteger(value): return Double(value)
        case let .boolean(value): return value ? 1 : 0
        default: return nil
        }
    }

    var boolValue: Bool? {
        switch self {
        case let .boolean(value): return value
        case let .integer(value): return value != 0
        case let .unsignedInteger(value): return value != 0
        case let .number(value): return value != 0
        default: return nil
        }
    }

    var textValue: String? {
        if case let .text(value) = self {
            return value
        }
        return nil
    }

    /// The `count` doubles of a multi-specifier numeric value (rect, point, transform).
    func numericComponents(expectedCount: Int) -> [Double]? {
        guard case let .list(elements) = self, elements.count == expectedCount else { return nil }
        var components: [Double] = []
        components.reserveCapacity(expectedCount)
        for element in elements {
            guard let component = element.doubleValue else { return nil }
            components.append(component)
        }
        return components
    }
}

// MARK: - Fetch status

/// Why a property description does or does not carry a value.
///
/// Taken from Xcode's reader: only `retrieved` and `unchanged` are meaningful
/// outcomes, and `unchanged` means "reuse what you already have" rather than
/// "no value". Values outside the known set are treated as failures.
enum LKXcodeViewHierarchyFetchStatus: Int {
    case failed = 0
    case noValue = 1
    case retrieved = 4
    case unchanged = 8

    /// True when the description should be skipped rather than applied.
    var skipsValueApplication: Bool {
        self == .failed || self == .unchanged
    }
}

// MARK: - Decoder

enum LKXcodeViewHierarchyValueDecodingError: Error, CustomStringConvertible {
    case specifierCountMismatch(format: String, valueCount: Int, specifierCount: Int)
    case multipleSpecifiersOnNonArray(format: String)
    case unsupportedSpecifier(String)
    case malformedScalar(specifier: String, text: String)
    case malformedStructure(specifier: String)

    var description: String {
        switch self {
        case let .specifierCountMismatch(format, valueCount, specifierCount):
            return "value has \(valueCount) elements but format '\(format)' has \(specifierCount) specifiers"
        case let .multipleSpecifiersOnNonArray(format):
            return "format '\(format)' has multiple specifiers but the value is not an array"
        case let .unsupportedSpecifier(specifier):
            return "unsupported format specifier '\(specifier)'"
        case let .malformedScalar(specifier, text):
            return "value '\(text)' is not readable as '\(specifier)'"
        case let .malformedStructure(specifier):
            return "structured value for '\(specifier)' is missing required fields"
        }
    }
}

enum LKXcodeViewHierarchyValueDecoder {
    static let customFormat = "custom"

    /// Splits a `propertyFormat` into its comma-separated specifiers.
    static func specifiers(inFormat format: String) -> [String] {
        format.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// Decodes one property description's value.
    ///
    /// `jsonValue` is the raw `propertyValue`; `nil` (or `NSNull`) yields `.absent`,
    /// which is the common case — most descriptions in a capture carry no value.
    static func decoding(jsonValue: Any?, format: String) throws -> LKXcodeViewHierarchyValue {
        guard let jsonValue, !(jsonValue is NSNull) else { return .absent }

        if format == customFormat {
            return .custom(customTextRepresentation(of: jsonValue))
        }

        let formatSpecifiers = specifiers(inFormat: format)
        guard !formatSpecifiers.isEmpty else { return .absent }

        if formatSpecifiers.count > 1 {
            guard let elements = jsonValue as? [Any] else {
                throw LKXcodeViewHierarchyValueDecodingError.multipleSpecifiersOnNonArray(format: format)
            }
            guard elements.count == formatSpecifiers.count else {
                throw LKXcodeViewHierarchyValueDecodingError.specifierCountMismatch(
                    format: format, valueCount: elements.count, specifierCount: formatSpecifiers.count
                )
            }
            let decodedElements = try zip(elements, formatSpecifiers).map { element, specifier in
                try decoding(jsonValue: element, format: specifier)
            }
            return .list(decodedElements)
        }

        let specifier = formatSpecifiers[0]
        if let text = jsonValue as? String {
            return try decodingScalar(text: text, specifier: specifier)
        }
        if let structure = jsonValue as? [String: Any] {
            return try decodingStructure(structure, specifier: specifier)
        }
        if let elements = jsonValue as? [Any] {
            // A single specifier over an array: decode each element the same way.
            return try .list(elements.map { try decoding(jsonValue: $0, format: specifier) })
        }
        if let number = jsonValue as? NSNumber {
            // Defensive: a capture that inlined a JSON number where a hex-float
            // string was expected still yields a usable value.
            return .number(number.doubleValue)
        }
        throw LKXcodeViewHierarchyValueDecodingError.malformedStructure(specifier: specifier)
    }

    // MARK: Scalars

    private static func decodingScalar(text: String, specifier: String) throws -> LKXcodeViewHierarchyValue {
        switch specifier {
        case "b":
            guard let value = parsingSignedInteger(text, radix: 10) else {
                throw LKXcodeViewHierarchyValueDecodingError.malformedScalar(specifier: specifier, text: text)
            }
            return .boolean(value != 0)
        case "CGf", "f", "d":
            guard let value = parsingFloatingPoint(text) else {
                throw LKXcodeViewHierarchyValueDecodingError.malformedScalar(specifier: specifier, text: text)
            }
            return .number(value)
        case "integer", "i", "l", "ll":
            guard let value = parsingSignedInteger(text, radix: 10) else {
                throw LKXcodeViewHierarchyValueDecodingError.malformedScalar(specifier: specifier, text: text)
            }
            return .integer(value)
        case "ui":
            // The one unsigned specifier Xcode reads as decimal (`%u`).
            guard let value = parsingUnsignedInteger(text, radix: 10) else {
                throw LKXcodeViewHierarchyValueDecodingError.malformedScalar(specifier: specifier, text: text)
            }
            return .unsignedInteger(value)
        case "uinteger", "ul", "ull":
            guard let value = parsingUnsignedInteger(text, radix: 16) else {
                throw LKXcodeViewHierarchyValueDecodingError.malformedScalar(specifier: specifier, text: text)
            }
            return .unsignedInteger(value)
        case "public.plain-text", "attrStr":
            return .text(text)
        case "public.data":
            guard let data = Data(base64Encoded: text) else {
                throw LKXcodeViewHierarchyValueDecodingError.malformedScalar(specifier: specifier, text: text)
            }
            return .binaryData(data)
        case "public.png", "public.tiff", "public.jpeg":
            guard let data = Data(base64Encoded: text) else {
                throw LKXcodeViewHierarchyValueDecodingError.malformedScalar(specifier: specifier, text: text)
            }
            return .image(LKXcodeViewHierarchyImage(encodedData: data, typeIdentifier: specifier, metadata: nil))
        default:
            throw LKXcodeViewHierarchyValueDecodingError.unsupportedSpecifier(specifier)
        }
    }

    /// Parses a C99 hexadecimal float, which is how every real number travels.
    static func parsingFloatingPoint(_ text: String) -> Double? {
        if let value = Double(text) {
            return value
        }
        return text.withCString { pointer -> Double? in
            var endPointer: UnsafeMutablePointer<CChar>?
            let value = strtod(pointer, &endPointer)
            guard let endPointer, endPointer.pointee == 0, endPointer != pointer else { return nil }
            return value
        }
    }

    static func parsingSignedInteger(_ text: String, radix: Int) -> Int64? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Int64(trimmed, radix: radix)
    }

    /// Parses an unsigned value in the radix Xcode wrote it in.
    ///
    /// Hexadecimal values are unprefixed and may occupy the full 64-bit range,
    /// so `ffffffffffffffff` (an all-bits-set mask, or a `-1` tag reinterpreted)
    /// has to survive rather than overflow.
    static func parsingUnsignedInteger(_ text: String, radix: Int) -> UInt64? {
        var trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if radix == 16, trimmed.hasPrefix("0x") || trimmed.hasPrefix("0X") {
            trimmed = String(trimmed.dropFirst(2))
        }
        if let value = UInt64(trimmed, radix: radix) {
            return value
        }
        // A negative decimal where an unsigned value was expected is a signed
        // representation of the same bits; keep the bits rather than reject.
        if let signedValue = Int64(trimmed, radix: radix) {
            return UInt64(bitPattern: signedValue)
        }
        return nil
    }

    // MARK: Structures

    private static func decodingStructure(
        _ structure: [String: Any],
        specifier: String
    ) throws -> LKXcodeViewHierarchyValue {
        switch specifier {
        case "objectInfo":
            guard let className = structure["className"] as? String,
                  let memoryAddress = structure["memoryAddress"] as? String
            else { throw LKXcodeViewHierarchyValueDecodingError.malformedStructure(specifier: specifier) }
            return .objectReference(
                LKXcodeViewHierarchyObjectReference(className: className, objectIdentifier: memoryAddress)
            )

        case "image":
            guard let encodedText = structure["imageData"] as? String,
                  let encodedData = Data(base64Encoded: encodedText)
            else { throw LKXcodeViewHierarchyValueDecodingError.malformedStructure(specifier: specifier) }
            return .image(
                LKXcodeViewHierarchyImage(
                    encodedData: encodedData,
                    typeIdentifier: "public.png",
                    metadata: decodingImageMetadata(structure["metadata"] as? [String: Any])
                )
            )

        case "color":
            guard let colorSpaceName = structure["colorSpaceName"] as? String else {
                throw LKXcodeViewHierarchyValueDecodingError.malformedStructure(specifier: specifier)
            }
            let componentsFormat = structure["componentValuesFormat"] as? String ?? ""
            let decodedComponents = try decoding(
                jsonValue: structure["componentValues"], format: componentsFormat
            )
            let componentCount = specifiers(inFormat: componentsFormat).count
            let components = decodedComponents.numericComponents(expectedCount: componentCount) ?? []
            return .color(
                LKXcodeViewHierarchyColor(
                    colorSpaceName: colorSpaceName,
                    components: components,
                    colorName: structure["colorName"] as? String,
                    catalogName: structure["catalogName"] as? String
                )
            )

        case "font":
            guard let fontName = structure["fontName"] as? String,
                  let familyName = structure["familyName"] as? String
            else { throw LKXcodeViewHierarchyValueDecodingError.malformedStructure(specifier: specifier) }
            func metric(_ key: String) -> Double {
                guard let text = structure[key] as? String else { return 0 }
                return parsingFloatingPoint(text) ?? 0
            }
            let lineHeight = (structure["lineHeight"] as? String).flatMap(parsingFloatingPoint)
            return .font(
                LKXcodeViewHierarchyFont(
                    fontName: fontName,
                    familyName: familyName,
                    pointSize: metric("pointSize"),
                    ascender: metric("ascender"),
                    descender: metric("descender"),
                    leading: metric("leading"),
                    capHeight: metric("capHeight"),
                    xHeight: metric("xHeight"),
                    lineHeight: lineHeight
                )
            )

        default:
            // An unfamiliar structured specifier is kept verbatim rather than
            // dropped: a capture from a newer Xcode must still open.
            return .custom(customTextRepresentation(of: structure))
        }
    }

    private static func decodingImageMetadata(_ metadata: [String: Any]?) -> LKXcodeViewHierarchyImageMetadata? {
        guard let metadata else { return nil }
        return LKXcodeViewHierarchyImageMetadata(
            width: (metadata["width"] as? NSNumber)?.doubleValue ?? 0,
            height: (metadata["height"] as? NSNumber)?.doubleValue ?? 0,
            imageName: metadata["imageName"] as? String,
            bundleIdentifier: metadata["bundleIdentifier"] as? String,
            isSystemSymbol: (metadata["isSystemSymbol"] as? NSNumber)?.boolValue ?? false,
            isFromMainBundle: (metadata["isFromMainBundle"] as? NSNumber)?.boolValue ?? false,
            isUIKitImage: (metadata["isUIKitImage"] as? NSNumber)?.boolValue ?? false,
            symbolConfigurationSummary: metadata["symbolConfigurationSummary"] as? String,
            baselineOffsetFromBottom: (metadata["baselineOffsetFromBottom"] as? NSNumber)?.doubleValue
        )
    }

    private static func customTextRepresentation(of jsonValue: Any) -> String {
        if let text = jsonValue as? String {
            return text
        }
        if JSONSerialization.isValidJSONObject(jsonValue),
           let data = try? JSONSerialization.data(withJSONObject: jsonValue),
           let text = String(data: data, encoding: .utf8)
        {
            return text
        }
        return String(describing: jsonValue)
    }
}
