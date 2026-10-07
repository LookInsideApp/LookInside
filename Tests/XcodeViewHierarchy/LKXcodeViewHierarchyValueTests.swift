import Foundation

/// Coverage for the `.viewhierarchy` property value decoder.
///
/// These cases are the written-down form of a format specification that Apple
/// never published: it was recovered from Xcode's own reader
/// (`DBGDecodeValueFromJSONCompatibleValue` in DebugHierarchyFoundation) and
/// cross-checked against real exports. Nothing here is a guess, and nothing
/// here can be re-derived by reading the format's documentation, because there
/// is none. If a case below starts failing, the format changed — that is the
/// signal this file exists to give.
///
/// The one that matters most is the hexadecimal float: every geometry value in
/// every capture is encoded as a C99 hex float, so reading it with an ordinary
/// decimal parser silently yields zero for the entire hierarchy.
@main
struct LKXcodeViewHierarchyValueTests {
    static func main() {
        testHexadecimalFloatIsParsed()
        testNegativeHexadecimalFloatIsParsed()
        testDecimalFloatStillParses()
        testRectUsesFourSpecifiers()
        testTransformUsesSixteenSpecifiers()
        testSpecifierCountMismatchIsRejected()
        testMultipleSpecifiersOnNonArrayIsRejected()
        testBooleanReadsZeroAsFalse()
        testSignedIntegerIsParsed()
        testUnsignedIntegerIsHexadecimal()
        testUnsignedIntegerHexIsNotReadAsDecimal()
        testShortUnsignedIntegerIsDecimal()
        testUnsignedMaskEncodedAsNegativeIsReinterpreted()
        testAllBitsSetUnsignedValueSurvives()
        testPlainTextPassesThrough()
        testBase64DataIsDecoded()
        testObjectReferenceIsDecoded()
        testImageStructureCarriesMetadata()
        testImageStringFormIsDecoded()
        testColorDecodesNestedComponentFormat()
        testFontDecodesHexMetrics()
        testCustomFormatIsPreservedVerbatim()
        testUnknownStructuredSpecifierIsPreserved()
        testUnknownScalarSpecifierIsRejected()
        testMissingValueIsAbsent()
        testNullValueIsAbsent()
        testFetchStatusGatesValueApplication()
        print("Xcode view hierarchy value tests passed")
    }

    // MARK: - Hexadecimal floats (the trap this decoder exists for)

    /// `0x1.a555555555555p+4` is 26.333…, the kind of number a layout produces.
    /// A decimal parser reads it as 0 and every frame in the file collapses.
    private static func testHexadecimalFloatIsParsed() {
        let value = decode(jsonValue: "0x1.a555555555555p+4", format: "CGf")
        guard let number = value.doubleValue else { fail("CGf did not decode to a number") }
        expect(abs(number - 26.333333333333332) < 0.000001, "expected 26.3333, got \(number)")
    }

    private static func testNegativeHexadecimalFloatIsParsed() {
        let value = decode(jsonValue: "-0x1.067p+2", format: "d")
        guard let number = value.doubleValue else { fail("negative hex float did not decode") }
        expect(abs(number - -4.100585937500) < 0.000001, "expected -4.1006, got \(number)")
    }

    /// Not every capture field is a hex float; plain decimals must still work.
    private static func testDecimalFloatStillParses() {
        let value = decode(jsonValue: "2.5", format: "f")
        expect(value.doubleValue == 2.5, "expected 2.5, got \(String(describing: value.doubleValue))")
    }

    // MARK: - Multi-specifier composites

    private static func testRectUsesFourSpecifiers() {
        let value = decode(
            jsonValue: ["0x0p+0", "0x1.3p+4", "0x1.4p+6", "0x1.8p+5"],
            format: "CGf, CGf, CGf, CGf"
        )
        guard let components = value.numericComponents(expectedCount: 4) else {
            fail("rect did not decode to four components")
        }
        expect(components[0] == 0, "origin.x should be 0, got \(components[0])")
        expect(components[1] == 19, "origin.y should be 19, got \(components[1])")
        expect(components[2] == 80, "width should be 80, got \(components[2])")
        expect(components[3] == 48, "height should be 48, got \(components[3])")
    }

    /// A CATransform3D arrives as sixteen specifiers, not as a nested structure.
    private static func testTransformUsesSixteenSpecifiers() {
        let identityText = Array(repeating: "0x0p+0", count: 16).enumerated().map { index, zero in
            index % 5 == 0 ? "0x1p+0" : zero
        }
        let format = Array(repeating: "CGf", count: 16).joined(separator: ", ")
        let value = decode(jsonValue: identityText, format: format)
        guard let components = value.numericComponents(expectedCount: 16) else {
            fail("transform did not decode to sixteen components")
        }
        expect(components[0] == 1 && components[5] == 1 && components[10] == 1 && components[15] == 1,
               "diagonal of the identity transform should be ones")
        expect(components[1] == 0, "off-diagonal should be zero")
    }

    private static func testSpecifierCountMismatchIsRejected() {
        expectFailure(jsonValue: ["0x0p+0", "0x0p+0"], format: "CGf, CGf, CGf, CGf",
                      "a two-element value under a four-specifier format must be rejected")
    }

    private static func testMultipleSpecifiersOnNonArrayIsRejected() {
        expectFailure(jsonValue: "0x0p+0", format: "CGf, CGf",
                      "a scalar under a multi-specifier format must be rejected")
    }

    // MARK: - Scalars

    private static func testBooleanReadsZeroAsFalse() {
        expect(decode(jsonValue: "0", format: "b").boolValue == false, "\"0\" should be false")
        expect(decode(jsonValue: "1", format: "b").boolValue == true, "\"1\" should be true")
    }

    private static func testSignedIntegerIsParsed() {
        let value = decode(jsonValue: "-42", format: "integer")
        guard case let .integer(number) = value else { fail("integer did not decode") }
        expect(number == -42, "expected -42, got \(number)")
    }

    /// `uinteger` is read with `%lx`, so its digits are unprefixed hexadecimal.
    /// Real captures rely on this: a toolbar item's `visibilityPriority` of
    /// 1000 travels as "3e8".
    private static func testUnsignedIntegerIsHexadecimal() {
        let value = decode(jsonValue: "3e8", format: "uinteger")
        guard case let .unsignedInteger(number) = value else { fail("uinteger did not decode") }
        expect(number == 1000, "expected 1000 from hex 3e8, got \(number)")
    }

    /// The silent-corruption case. "100" is a perfectly good decimal string, so
    /// a decimal reader returns 100 and never errors — but the value is 256.
    /// Only digits a-f would have exposed the mistake.
    private static func testUnsignedIntegerHexIsNotReadAsDecimal() {
        let value = decode(jsonValue: "100", format: "uinteger")
        guard case let .unsignedInteger(number) = value else { fail("uinteger did not decode") }
        expect(number == 256, "uinteger '100' is hexadecimal and must be 256, got \(number)")
    }

    /// `ui` is the exception: Xcode reads it with `%u`, in decimal.
    private static func testShortUnsignedIntegerIsDecimal() {
        let value = decode(jsonValue: "100", format: "ui")
        guard case let .unsignedInteger(number) = value else { fail("ui did not decode") }
        expect(number == 100, "ui '100' is decimal and must be 100, got \(number)")
    }

    /// A signed value written where an unsigned one was expected keeps its bits
    /// rather than being rejected.
    private static func testUnsignedMaskEncodedAsNegativeIsReinterpreted() {
        let value = decode(jsonValue: "-1", format: "uinteger")
        guard case let .unsignedInteger(number) = value else { fail("uinteger did not decode") }
        expect(number == UInt64.max, "expected UInt64.max, got \(number)")
    }

    /// `tagForSegment` and `_buttonType` of -1 travel as sixteen f's; parsing
    /// must not overflow on the full 64-bit range.
    private static func testAllBitsSetUnsignedValueSurvives() {
        let value = decode(jsonValue: "ffffffffffffffff", format: "ul")
        guard case let .unsignedInteger(number) = value else { fail("ul did not decode") }
        expect(number == UInt64.max, "expected UInt64.max, got \(number)")
    }

    private static func testPlainTextPassesThrough() {
        expect(decode(jsonValue: "Play", format: "public.plain-text").textValue == "Play",
               "plain text should pass through unchanged")
    }

    private static func testBase64DataIsDecoded() {
        let payload = Data("hierarchy".utf8)
        let value = decode(jsonValue: payload.base64EncodedString(), format: "public.data")
        guard case let .binaryData(decoded) = value else { fail("public.data did not decode") }
        expect(decoded == payload, "round-tripped data should match")
    }

    // MARK: - Structured values

    private static func testObjectReferenceIsDecoded() {
        let value = decode(
            jsonValue: ["className": "NSLayoutConstraint", "memoryAddress": "0x1060b7100"],
            format: "objectInfo"
        )
        guard case let .objectReference(reference) = value else { fail("objectInfo did not decode") }
        expect(reference.className == "NSLayoutConstraint", "class name mismatch: \(reference.className)")
        expect(reference.objectIdentifier == "0x1060b7100", "identifier mismatch: \(reference.objectIdentifier)")
    }

    private static func testImageStructureCarriesMetadata() {
        let pixels = Data([0x89, 0x50, 0x4E, 0x47])
        let value = decode(
            jsonValue: [
                "imageData": pixels.base64EncodedString(),
                "metadata": [
                    "width": 23.5,
                    "height": 21.0,
                    "isSystemSymbol": true,
                    "isFromMainBundle": false,
                    "isUIKitImage": false,
                    "imageName": "chevron.right",
                ] as [String: Any],
            ] as [String: Any],
            format: "image"
        )
        guard case let .image(image) = value else { fail("image structure did not decode") }
        expect(image.encodedData == pixels, "image bytes should round-trip")
        guard let metadata = image.metadata else { fail("image metadata was dropped") }
        expect(metadata.width == 23.5 && metadata.height == 21.0, "image metadata size mismatch")
        expect(metadata.isSystemSymbol, "isSystemSymbol should survive")
        expect(metadata.imageName == "chevron.right", "image name mismatch")
    }

    /// The other image form: a bare base64 string whose format *is* the type.
    private static func testImageStringFormIsDecoded() {
        let pixels = Data([0x89, 0x50, 0x4E, 0x47])
        let value = decode(jsonValue: pixels.base64EncodedString(), format: "public.png")
        guard case let .image(image) = value else { fail("public.png did not decode") }
        expect(image.encodedData == pixels, "image bytes should round-trip")
        expect(image.metadata == nil, "string-form images carry no metadata")
    }

    /// A colour nests a second format string for its components — the decoder
    /// has to recurse rather than assume four channels.
    private static func testColorDecodesNestedComponentFormat() {
        let value = decode(
            jsonValue: [
                "colorSpaceName": "kCGColorSpaceSRGB",
                "componentValuesFormat": "CGf, CGf, CGf, CGf",
                "componentValues": ["0x0p+0", "0x0p+0", "0x0p+0", "0x1p+0"],
            ] as [String: Any],
            format: "color"
        )
        guard case let .color(color) = value else { fail("color did not decode") }
        expect(color.colorSpaceName == "kCGColorSpaceSRGB", "colour space mismatch")
        expect(color.components == [0, 0, 0, 1], "components mismatch: \(color.components)")
    }

    private static func testFontDecodesHexMetrics() {
        let value = decode(
            jsonValue: [
                "fontName": ".SFUI-Regular",
                "familyName": ".AppleSystemUIFont",
                "pointSize": "0x1.1p+4",
                "ascender": "0x1.1p+4",
                "descender": "-0x1.067p+2",
                "leading": "0x0p+0",
                "capHeight": "0x1.8p+3",
                "xHeight": "0x1.1e58p+3",
            ] as [String: Any],
            format: "font"
        )
        guard case let .font(font) = value else { fail("font did not decode") }
        expect(font.fontName == ".SFUI-Regular", "font name mismatch")
        expect(font.pointSize == 17, "point size should be 17, got \(font.pointSize)")
        expect(font.lineHeight == nil, "absent lineHeight should stay nil")
    }

    // MARK: - Forward compatibility

    private static func testCustomFormatIsPreservedVerbatim() {
        let value = decode(jsonValue: ["a", "b"], format: "custom")
        guard case let .custom(text) = value else { fail("custom format did not pass through") }
        expect(text.contains("a") && text.contains("b"), "custom payload should be preserved: \(text)")
    }

    /// A capture from a newer Xcode may carry structured specifiers this build
    /// has never seen. Keeping them as text is what lets the file still open.
    private static func testUnknownStructuredSpecifierIsPreserved() {
        let value = decode(jsonValue: ["something": "new"], format: "materialEffect")
        guard case let .custom(text) = value else { fail("unknown structure should be preserved as custom") }
        expect(text.contains("new"), "unknown structure payload should survive: \(text)")
    }

    /// An unknown *scalar* specifier is a different matter: silently keeping a
    /// misread number would corrupt geometry, so it must surface as an error.
    private static func testUnknownScalarSpecifierIsRejected() {
        expectFailure(jsonValue: "12", format: "quaternion",
                      "an unknown scalar specifier must be reported, not guessed")
    }

    // MARK: - Absent values

    private static func testMissingValueIsAbsent() {
        expect(decode(jsonValue: nil, format: "CGf") == .absent, "nil value should decode as absent")
    }

    private static func testNullValueIsAbsent() {
        expect(decode(jsonValue: NSNull(), format: "CGf") == .absent, "NSNull should decode as absent")
    }

    // MARK: - Fetch status

    /// Only `retrieved` carries a usable value. `unchanged` means the capture
    /// deliberately omitted it because an earlier response already had it, and
    /// applying it as a value would blank the property.
    private static func testFetchStatusGatesValueApplication() {
        expect(LKXcodeViewHierarchyFetchStatus.retrieved.skipsValueApplication == false,
               "retrieved values must be applied")
        expect(LKXcodeViewHierarchyFetchStatus.noValue.skipsValueApplication == false,
               "an explicit no-value must be applied as absent")
        expect(LKXcodeViewHierarchyFetchStatus.unchanged.skipsValueApplication,
               "unchanged must not overwrite an existing value")
        expect(LKXcodeViewHierarchyFetchStatus.failed.skipsValueApplication,
               "a failed fetch must not overwrite an existing value")
        expect(LKXcodeViewHierarchyFetchStatus(rawValue: 4) == .retrieved, "4 is the retrieved status")
        expect(LKXcodeViewHierarchyFetchStatus(rawValue: 8) == .unchanged, "8 is the unchanged status")
    }

    // MARK: - Helpers

    private static func decode(jsonValue: Any?, format: String) -> LKXcodeViewHierarchyValue {
        do {
            return try LKXcodeViewHierarchyValueDecoder.decoding(jsonValue: jsonValue, format: format)
        } catch {
            fail("decoding '\(format)' threw: \(error)")
        }
    }

    private static func expectFailure(jsonValue: Any?, format: String, _ message: String) {
        do {
            let value = try LKXcodeViewHierarchyValueDecoder.decoding(jsonValue: jsonValue, format: format)
            fail("\(message) — but it decoded to \(value)")
        } catch {
            // Expected.
        }
    }

    private static func expect(_ condition: Bool, _ message: String) {
        guard condition else {
            fail(message)
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        Foundation.exit(1)
    }
}
