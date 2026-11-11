import AppKit
import Foundation
import QuartzCore

/// Coverage for reading Core Animation archives (`.caar`) and the file names
/// Dump Layer gives them.
///
/// The fixtures are made by QuartzCore's own `CAEncodeLayerTree`, the function
/// the AppKit debug menu calls, so the archives under test are byte for byte
/// what a Dump Layer writes. The cases that matter most are the ones a file
/// from elsewhere can trigger: a class this process does not have, data that
/// is no archive at all, and an archive whose root is not a layer tree — each
/// must end in an error, never in a raised exception taking the app down.
@main
struct CoreAnimationArchiveDecodingTests {
    static func main() {
        testDecodesWhatCoreAnimationEncodes()
        testKeepsTheFlipOfSuperlayersLeftOutOfTheArchive()
        testEncoderArchivesOnlyQuartzCoreClasses()
        testUnknownLayerClassDecodesAsItsNearestKnownSuperclass()
        testDataThatIsNoArchiveIsRejected()
        testArchiveWhoseRootIsNoDictionaryIsRejected()
        testArchiveWithoutARootLayerIsRejected()
        testReadsTheDumpLayerFileName()
        testReadsAProcessNameContainingHyphens()
        testReadsASwiftClassName()
        testIgnoresFileNamesOutsideTheDumpLayerFormat()
        print("Core Animation archive decoding tests passed")
    }

    // MARK: - Decoding

    private static func testDecodesWhatCoreAnimationEncodes() {
        let rootLayer = CALayer()
        rootLayer.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        rootLayer.backgroundColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = CGRect(x: 10, y: 20, width: 30, height: 40)
        shapeLayer.path = CGPath(rect: CGRect(x: 0, y: 0, width: 30, height: 40), transform: nil)
        let textLayer = CATextLayer()
        textLayer.frame = CGRect(x: 50, y: 10, width: 100, height: 20)
        textLayer.string = "Dump Layer"
        rootLayer.addSublayer(shapeLayer)
        rootLayer.addSublayer(textLayer)

        let contents = decodedContents(of: encodingLayerTree(rootLayer), "a tree CAEncodeLayerTree wrote")
        expect(type(of: contents.rootLayer) == CALayer.self, "the root should decode as a CALayer")
        expect(contents.rootLayer.frame == rootLayer.frame, "the root should keep its frame")
        expect(contents.rootLayer.backgroundColor?.components == [1, 0, 0, 1], "the root should keep its background colour")
        expect(!contents.isGeometryFlipped, "an unflipped root should be recorded as unflipped")

        let sublayers = contents.rootLayer.sublayers ?? []
        expect(sublayers.count == 2, "both sublayers should decode, got \(sublayers.count)")
        guard sublayers.count == 2 else { return }
        expect(sublayers[0] is CAShapeLayer, "the shape layer should keep its class")
        expect(sublayers[0].frame == shapeLayer.frame, "the shape layer should keep its frame")
        expect((sublayers[0] as? CAShapeLayer)?.path != nil, "the shape layer should keep its path")
        expect(sublayers[1] is CATextLayer, "the text layer should keep its class")
        expect((sublayers[1] as? CATextLayer)?.string as? String == "Dump Layer", "the text layer should keep its string")
    }

    /// `geometryFlipped` is relative to the superlayer, so a root archived out
    /// of a flipped superlayer carries no flag of its own; only the archive's
    /// `geometryFlipped` entry says its space was flipped. The reader must
    /// hand that entry on rather than the root's own flag.
    ///
    /// The root has a sublayer, as a dumped view's layer does: on macOS 27.2
    /// `CAEncodeLayerTree` writes an archive that no unarchiver can read for
    /// a root with a flipped superlayer and no sublayers.
    private static func testKeepsTheFlipOfSuperlayersLeftOutOfTheArchive() {
        let flippedSuperlayer = CALayer()
        flippedSuperlayer.isGeometryFlipped = true
        let rootLayer = CALayer()
        rootLayer.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        let sublayer = CALayer()
        sublayer.frame = CGRect(x: 4, y: 4, width: 8, height: 8)
        rootLayer.addSublayer(sublayer)
        flippedSuperlayer.addSublayer(rootLayer)
        expect(rootLayer.contentsAreFlipped(), "fixture: the root should inherit its superlayer's flip")

        let contents = decodedContents(of: encodingLayerTree(rootLayer), "a root archived out of a flipped superlayer")
        expect(contents.isGeometryFlipped, "the archive should record the flip the superlayer gave the root")
        expect(!contents.rootLayer.isGeometryFlipped, "the root's own flag should stay as it was archived")
    }

    /// `CAEncodeLayerTree` never writes a class from outside QuartzCore: a
    /// layer of any other class (AppKit's backing layers, the app's own
    /// subclasses) is archived as a copy of its nearest QuartzCore superclass.
    private static func testEncoderArchivesOnlyQuartzCoreClasses() {
        let rootLayer = CALayer()
        rootLayer.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        let gradientLayer = AppDefinedGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
        rootLayer.addSublayer(gradientLayer)

        let contents = decodedContents(of: encodingLayerTree(rootLayer), "a tree holding an app-defined layer class")
        guard let decodedLayer = contents.rootLayer.sublayers?.first else {
            fail("the app-defined layer should be archived")
        }
        expect(type(of: decodedLayer) == CAGradientLayer.self, "the app-defined class should arrive as CAGradientLayer, got \(type(of: decodedLayer))")
        expect(decodedLayer.frame == gradientLayer.frame, "the copy should keep the layer's frame")
    }

    /// Other tools write archives naming classes this process does not have
    /// (Mica's own layer classes, say). The reader must fall back to the
    /// nearest superclass the archive records instead of losing the tree.
    /// No encoder can be made to write such a name, so the fixture renames a
    /// class in a real archive.
    private static func testUnknownLayerClassDecodesAsItsNearestKnownSuperclass() {
        let rootLayer = CALayer()
        rootLayer.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
        gradientLayer.colors = [CGColor(gray: 0, alpha: 1), CGColor(gray: 1, alpha: 1)]
        rootLayer.addSublayer(gradientLayer)
        let archive = archiveRenamingClass(
            "CAGradientLayer",
            to: "LookInsideTestsMissingGradientLayer",
            in: encodingLayerTree(rootLayer)
        )

        let contents = decodedContents(of: archive, "an archive naming a missing class")
        guard let decodedLayer = contents.rootLayer.sublayers?.first else {
            fail("the layer of the missing class should still decode")
        }
        expect(type(of: decodedLayer) == CAGradientLayer.self, "a missing class should decode as CAGradientLayer, got \(type(of: decodedLayer))")
        expect(decodedLayer.frame == gradientLayer.frame, "the substituted layer should keep its frame")
    }

    private static func testDataThatIsNoArchiveIsRejected() {
        expectRejection(of: Data("not an archive".utf8), "plain text")
        expectRejection(of: Data(), "empty data")
    }

    /// CAPackage sends the root -objectForKey:, which a string answers with
    /// an exception. The reader must turn that into an error.
    private static func testArchiveWhoseRootIsNoDictionaryIsRejected() {
        let data = archivedData(rootObject: "not a layer tree" as NSString)
        expectRejection(of: data, "an archive whose root is a string")
    }

    private static func testArchiveWithoutARootLayerIsRejected() {
        let data = archivedData(rootObject: ["rootLayer": "not a layer", "geometryFlipped": false] as NSDictionary)
        expectRejection(of: data, "an archive whose root layer is a string")
    }

    // MARK: - File name

    private static func testReadsTheDumpLayerFileName() {
        let origin = CoreAnimationArchiveOrigin(fileName: "RuntimeViewer-48213-NSWindow-0x13a8045f0-layer-391827364512.caar")
        expect(origin?.processName == "RuntimeViewer", "the process name should be read")
        expect(origin?.processIdentifier == 48213, "the pid should be read")
        expect(origin?.className == "NSWindow", "the class name should be read")
        expect(origin?.objectAddress == "0x13a8045f0", "the object address should be read")
    }

    private static func testReadsAProcessNameContainingHyphens() {
        let origin = CoreAnimationArchiveOrigin(fileName: "Some-Helper-App-77-_NSPopoverWindow-0x1-layer-5.caar")
        expect(origin?.processName == "Some-Helper-App", "the hyphens should stay in the process name")
        expect(origin?.processIdentifier == 77, "the pid should follow the last hyphenated part of the name")
        expect(origin?.className == "_NSPopoverWindow", "the class name should be read")
    }

    private static func testReadsASwiftClassName() {
        let origin = CoreAnimationArchiveOrigin(fileName: "Viewer-9-Viewer.MainWindow-0xabc-layer-12.caar")
        expect(origin?.className == "Viewer.MainWindow", "a module-qualified class name should be read whole")
    }

    private static func testIgnoresFileNamesOutsideTheDumpLayerFormat() {
        expect(CoreAnimationArchiveOrigin(fileName: "Animation.caar") == nil, "an ordinary name should not parse")
        expect(CoreAnimationArchiveOrigin(fileName: "App-12-NSWindow-12-layer-3.caar") == nil, "an address must be hexadecimal with 0x")
    }

    // MARK: - Helpers

    private typealias EncodeLayerTreeFunction = @convention(c) (CALayer) -> Unmanaged<NSData>?

    /// QuartzCore's `CAEncodeLayerTree`, the function Dump Layer archives with.
    /// It returns a +1 reference.
    private static func encodingLayerTree(_ layer: CALayer) -> Data {
        let defaultHandle = UnsafeMutableRawPointer(bitPattern: -2)
        guard let symbol = dlsym(defaultHandle, "CAEncodeLayerTree") else {
            fail("CAEncodeLayerTree is not exported by this QuartzCore")
        }
        let encodeLayerTree = unsafeBitCast(symbol, to: EncodeLayerTreeFunction.self)
        guard let data = encodeLayerTree(layer)?.takeRetainedValue() else {
            fail("CAEncodeLayerTree returned no data")
        }
        return data as Data
    }

    /// `data` with every object of `className` recorded as an unknown subclass
    /// of it: the class entry's name becomes `newClassName`, prepended to the
    /// chain the archive records for it.
    private static func archiveRenamingClass(_ className: String, to newClassName: String, in data: Data) -> Data {
        guard var archive = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              var objects = archive["$objects"] as? [Any]
        else { fail("fixture: the archive is no property list") }
        var renamedEntryCount = 0
        for (index, object) in objects.enumerated() {
            guard var classEntry = object as? [String: Any],
                  classEntry["$classname"] as? String == className,
                  let classChain = classEntry["$classes"] as? [String]
            else { continue }
            classEntry["$classname"] = newClassName
            classEntry["$classes"] = [newClassName] + classChain
            objects[index] = classEntry
            renamedEntryCount += 1
        }
        guard renamedEntryCount > 0 else { fail("fixture: the archive names no \(className)") }
        archive["$objects"] = objects
        guard let renamedData = try? PropertyListSerialization.data(fromPropertyList: archive, format: .binary, options: 0)
        else { fail("fixture: the renamed archive could not be written") }
        return renamedData
    }

    private static func archivedData(rootObject: NSObject) -> Data {
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encode(rootObject, forKey: NSKeyedArchiveRootObjectKey)
        archiver.finishEncoding()
        return archiver.encodedData
    }

    private static func decodedContents(of data: Data, _ description: String) -> CoreAnimationArchiveContents {
        do {
            return try CoreAnimationArchive.decodingContents(of: data)
        } catch {
            fail("\(description) failed to decode: \(error) — \((error as? CoreAnimationArchiveError)?.failureReason ?? "")")
        }
    }

    private static func expectRejection(of data: Data, _ description: String) {
        do {
            _ = try CoreAnimationArchive.decodingContents(of: data)
            fail("\(description) should be rejected")
        } catch CoreAnimationArchiveError.notALayerTree {
            // Rejected as malformed: what a bad file should produce.
        } catch {
            fail("\(description) should be rejected as no layer tree, got \(error)")
        }
    }

    private static func expect(_ condition: Bool, _ message: String) {
        guard condition else {
            fail(message)
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(1)
    }
}

/// A layer subclass defined outside QuartzCore, as an app's own would be.
private final class AppDefinedGradientLayer: CAGradientLayer {}
