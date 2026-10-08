import Foundation

/// Coverage for merging a `.viewhierarchy` capture's responses into one object graph.
///
/// Each case here stands for a merge rule taken from Xcode's own reader
/// (`DBGDataCoordinatorTargetHub`), plus the one rule this reader adds on top
/// of it: a new capture replaces the previous one whole. They share a failure
/// signature: break any one of them and the import still succeeds, still
/// shows a tree, and is quietly wrong — duplicated nodes, a view's layer
/// promoted to a subview, a property blanked by a later response that only
/// meant "unchanged", or a replaced view lingering beside its replacement.
@main
struct XcodeViewHierarchyObjectGraphTests {
    static func main() {
        testObjectDescribedTwiceIsOneNode()
        testChildGroupBecomesOwnedChildren()
        testAdditionalGroupsAreNotChildren()
        testReferenceDoesNotClobberDescribedObject()
        testReferenceBeforeDescriptionIsFilledInLater()
        testTopLevelPropertyRoutesByKeyPath()
        testPropertyNameIsRecoveredFromKeyPath()
        testUnchangedStatusDoesNotOverwrite()
        testFailedStatusDoesNotOverwrite()
        testRetrievedStatusOverwrites()
        testLegacyPropertyValueStatusIsMigrated()
        testLegacyStatusOneDropsItsValue()
        testChildOrderIsPreserved()
        testRootGroupsAreRecorded()
        testPropertyForUnknownObjectStillLands()
        testMalformedValueIsReportedNotFatal()
        testClassChainIsBuiltFromClassInformation()
        testClassChainOfUnknownClassIsJustItself()
        testNewCaptureReplacesTheEarlierOne()
        testReusedAddressesDoNotFormACycle()
        print("Xcode view hierarchy object graph tests passed")
    }

    // MARK: - Identity and merging

    /// A capture writes the same object into several responses. Keying by
    /// `objectID` is what keeps one node instead of one per mention.
    private static func testObjectDescribedTwiceIsOneNode() {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: response(groups: [
            group("com.apple.UIKit.UIView", objects: [object("0x1", className: "UIView")]),
        ]))
        builder.ingesting(response: response(groups: [
            group("com.apple.UIKit.UIView", objects: [object("0x1", className: "UIView")]),
        ]))
        let graph = builder.build()
        expect(graph.nodesByIdentifier.count == 1, "expected one node, got \(graph.nodesByIdentifier.count)")
        expect(graph.rootIdentifiers(inGroup: "com.apple.UIKit.UIView") == ["0x1"],
               "the root list must not repeat the identifier")
    }

    private static func testChildGroupBecomesOwnedChildren() {
        let graph = graphFrom(groups: [
            group("com.apple.UIKit.UIView", objects: [
                object("0x1", className: "UIView", childGroup: group("com.apple.UIKit.UIView", objects: [
                    object("0x2", className: "UILabel"),
                    object("0x3", className: "UIButton"),
                ])),
            ]),
        ])
        guard let parent = graph.node("0x1") else { fail("parent node missing") }
        expect(parent.childIdentifiers == ["0x2", "0x3"], "children mismatch: \(parent.childIdentifiers)")
        expect(graph.node("0x2")?.className == "UILabel", "child class was not recorded")
    }

    /// A view's layer, constraints and view controller arrive as additional
    /// groups. Folding them into `childIdentifiers` would put a CALayer in the
    /// view tree as though it were a subview.
    private static func testAdditionalGroupsAreNotChildren() {
        let graph = graphFrom(groups: [
            group("com.apple.UIKit.UIView", objects: [
                object("0x1", className: "UIView", additionalGroups: [
                    group("com.apple.QuartzCore.CALayer", objects: [reference("0x9")]),
                    group("com.apple.UIKit.NSLayoutConstraint", objects: [reference("0xA"), reference("0xB")]),
                ]),
            ]),
        ])
        guard let view = graph.node("0x1") else { fail("view node missing") }
        expect(view.childIdentifiers.isEmpty, "associated objects must not become children: \(view.childIdentifiers)")
        expect(view.associatedIdentifiers(inGroup: "com.apple.QuartzCore.CALayer") == ["0x9"],
               "layer association missing")
        expect(view.associatedIdentifiers(inGroup: "com.apple.UIKit.NSLayoutConstraint") == ["0xA", "0xB"],
               "constraint associations missing")
    }

    /// A reference names an object described in full elsewhere in the same
    /// capture; applying it as an update would erase that description. Root
    /// groups are ingested in key order, so the layer group here is read
    /// before the view group that references it.
    private static func testReferenceDoesNotClobberDescribedObject() {
        let graph = graphFrom(groups: [
            group("com.apple.QuartzCore.CALayer", objects: [object("0x9", className: "CALayer")]),
            group("com.apple.UIKit.UIView", objects: [
                object("0x1", className: "UIView", additionalGroups: [
                    group("com.apple.QuartzCore.CALayer", objects: [reference("0x9")]),
                ]),
            ]),
        ])
        expect(graph.node("0x9")?.className == "CALayer",
               "a later reference erased the described class: \(String(describing: graph.node("0x9")?.className))")
    }

    /// The reverse order also has to work: the reference is read first (the
    /// AppKit group key sorts before the QuartzCore one), the full description
    /// later.
    private static func testReferenceBeforeDescriptionIsFilledInLater() {
        let graph = graphFrom(groups: [
            group("com.apple.AppKit.NSView", objects: [
                object("0x1", className: "NSView", additionalGroups: [
                    group("com.apple.QuartzCore.CALayer", objects: [reference("0x9")]),
                ]),
            ]),
            group("com.apple.QuartzCore.CALayer", objects: [object("0x9", className: "CALayer")]),
        ])
        expect(graph.node("0x9")?.className == "CALayer", "the later description was not applied")
    }

    // MARK: - Out-of-band properties

    private static func testTopLevelPropertyRoutesByKeyPath() {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: response(groups: [
            group("com.apple.UIKit.UIView", objects: [object("0x1", className: "UIView")]),
        ]))
        builder.ingesting(response: response(properties: [
            "0x1.frame": propertyDescription(
                name: "frame", format: "CGf, CGf, CGf, CGf",
                value: ["0x0p+0", "0x0p+0", "0x1.9p+6", "0x1.4p+5"]
            ),
        ]))
        let graph = builder.build()
        guard let frame = graph.node("0x1")?.property(named: "frame") else { fail("frame did not land on the node") }
        guard let components = frame.value.numericComponents(expectedCount: 4) else { fail("frame did not decode") }
        expect(components == [0, 0, 100, 40], "frame mismatch: \(components)")
    }

    /// Some descriptions omit `propertyName`; the key path is the fallback.
    private static func testPropertyNameIsRecoveredFromKeyPath() {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: response(properties: [
            "0x1.alpha": ["propertyFormat": "CGf", "propertyValue": "0x1p-1", "fetchStatus": NSNumber(value: 4)],
        ]))
        let graph = builder.build()
        expect(graph.node("0x1")?.property(named: "alpha")?.value.doubleValue == 0.5,
               "property name should be recovered from the key path")
    }

    // MARK: - Fetch status

    /// `unchanged` means "you already have it". Applying it as a value blanks
    /// whatever an earlier response established.
    private static func testUnchangedStatusDoesNotOverwrite() {
        let graph = graphWithFrameThenStatus(8)
        guard let frame = graph.node("0x1")?.property(named: "frame") else { fail("frame missing") }
        expect(frame.value.numericComponents(expectedCount: 4) == [0, 0, 100, 40],
               "an unchanged status overwrote the value: \(frame.value)")
    }

    private static func testFailedStatusDoesNotOverwrite() {
        let graph = graphWithFrameThenStatus(0)
        guard let frame = graph.node("0x1")?.property(named: "frame") else { fail("frame missing") }
        expect(frame.value.numericComponents(expectedCount: 4) == [0, 0, 100, 40],
               "a failed status overwrote the value: \(frame.value)")
    }

    private static func testRetrievedStatusOverwrites() {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: response(properties: [
            "0x1.frame": propertyDescription(
                name: "frame", format: "CGf, CGf, CGf, CGf",
                value: ["0x0p+0", "0x0p+0", "0x1.9p+6", "0x1.4p+5"]
            ),
        ]))
        builder.ingesting(response: response(properties: [
            "0x1.frame": propertyDescription(
                name: "frame", format: "CGf, CGf, CGf, CGf",
                value: ["0x0p+0", "0x0p+0", "0x1p+1", "0x1p+1"]
            ),
        ]))
        let graph = builder.build()
        expect(graph.node("0x1")?.property(named: "frame")?.value.numericComponents(expectedCount: 4) == [0, 0, 2, 2],
               "a retrieved value must replace the earlier one")
    }

    private static func graphWithFrameThenStatus(_ status: Int) -> XcodeViewHierarchyObjectGraph {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: response(properties: [
            "0x1.frame": propertyDescription(
                name: "frame", format: "CGf, CGf, CGf, CGf",
                value: ["0x0p+0", "0x0p+0", "0x1.9p+6", "0x1.4p+5"]
            ),
        ]))
        builder.ingesting(response: response(properties: [
            "0x1.frame": [
                "propertyName": "frame",
                "propertyFormat": "CGf, CGf, CGf, CGf",
                "fetchStatus": NSNumber(value: status),
            ],
        ]))
        return builder.build()
    }

    // MARK: - Legacy documents

    /// Version 1 spelled the outcome `propertyValueStatus` with different codes.
    /// Without the migration, every property in an old export reads as failed.
    private static func testLegacyPropertyValueStatusIsMigrated() {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        var legacyResponse = response(properties: [
            "0x1.alpha": [
                "propertyName": "alpha",
                "propertyFormat": "CGf",
                "propertyValue": "0x1p+0",
                "propertyValueStatus": NSNumber(value: 0),
            ],
        ])
        legacyResponse["version"] = NSNumber(value: 1)
        builder.ingesting(response: legacyResponse)
        let graph = builder.build()
        expect(graph.node("0x1")?.property(named: "alpha")?.value.doubleValue == 1.0,
               "a version-1 status of 0 means the value was retrieved")
    }

    /// Status 1 in version 1 meant "retrieved, but the value is not usable";
    /// Xcode drops the value and keeps the status successful.
    private static func testLegacyStatusOneDropsItsValue() {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        var legacyResponse = response(properties: [
            "0x1.alpha": [
                "propertyName": "alpha",
                "propertyFormat": "CGf",
                "propertyValue": "0x1p+0",
                "propertyValueStatus": NSNumber(value: 1),
            ],
        ])
        legacyResponse["version"] = NSNumber(value: 1)
        builder.ingesting(response: legacyResponse)
        let graph = builder.build()
        guard let alpha = graph.node("0x1")?.property(named: "alpha") else { fail("alpha missing") }
        expect(alpha.value == .absent, "a version-1 status of 1 must drop the value, got \(alpha.value)")
    }

    // MARK: - Ordering and structure

    /// Sibling order is the on-screen z-order; a set would lose it.
    private static func testChildOrderIsPreserved() {
        let graph = graphFrom(groups: [
            group("com.apple.UIKit.UIView", objects: [
                object("0x1", className: "UIView", childGroup: group("com.apple.UIKit.UIView", objects: [
                    object("0xC", className: "UIView"),
                    object("0xA", className: "UIView"),
                    object("0xB", className: "UIView"),
                ])),
            ]),
        ])
        expect(graph.node("0x1")?.childIdentifiers == ["0xC", "0xA", "0xB"],
               "child order must follow the capture, not sorting")
    }

    private static func testRootGroupsAreRecorded() {
        let graph = graphFrom(groups: [
            group("com.apple.UIKit.UIWindow", objects: [object("0x1", className: "UIWindow")]),
            group("com.apple.UIKit.UIView", objects: [object("0x2", className: "UIView")]),
        ])
        let groupNames = graph.rootGroups.map(\.groupingIdentifier)
        expect(groupNames.contains("com.apple.UIKit.UIWindow"), "window group missing: \(groupNames)")
        expect(groupNames.contains("com.apple.UIKit.UIView"), "view group missing: \(groupNames)")
    }

    /// Properties can name an object no response described; keeping the value
    /// beats dropping it.
    private static func testPropertyForUnknownObjectStillLands() {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: response(properties: [
            "0xDEAD.hidden": propertyDescription(name: "hidden", format: "b", value: "1"),
        ]))
        let graph = builder.build()
        expect(graph.node("0xDEAD")?.property(named: "hidden")?.value.boolValue == true,
               "a property for an undescribed object should still be kept")
    }

    /// One unreadable property must not abort the import of the whole capture.
    private static func testMalformedValueIsReportedNotFatal() {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: response(properties: [
            "0x1.frame": propertyDescription(name: "frame", format: "CGf, CGf, CGf, CGf", value: ["0x0p+0"]),
            "0x1.hidden": propertyDescription(name: "hidden", format: "b", value: "1"),
        ]))
        let graph = builder.build()
        expect(graph.decodingIssues.count == 1, "expected one recorded issue, got \(graph.decodingIssues.count)")
        expect(graph.node("0x1")?.property(named: "hidden")?.value.boolValue == true,
               "a sibling property must still decode after a malformed one")
    }

    // MARK: - Class information

    /// The capture nests classes by subclass; the inspector reads the chain in
    /// the other direction, and shows and searches it.
    private static func testClassChainIsBuiltFromClassInformation() {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: [
            "version": NSNumber(value: 2),
            "classInformation": [
                [
                    "className": "NSObject",
                    "subclasses": [
                        [
                            "className": "UIResponder",
                            "subclasses": [
                                ["className": "UIView", "subclasses": [["className": "UILabel"]]],
                            ],
                        ],
                    ],
                ],
            ],
        ])
        let graph = builder.build()
        expect(graph.classChain(forClassName: "UILabel") == ["UILabel", "UIView", "UIResponder", "NSObject"],
               "chain mismatch: \(graph.classChain(forClassName: "UILabel"))")
    }

    private static func testClassChainOfUnknownClassIsJustItself() {
        let graph = XcodeViewHierarchyObjectGraphBuilder().build()
        expect(graph.classChain(forClassName: "MysteryView") == ["MysteryView"],
               "an unknown class should still yield a one-element chain")
    }

    // MARK: - Repeated captures

    /// A document can hold several captures of one process: Xcode records
    /// every request of a session, and each re-capture appends a hierarchy
    /// response of its own. Every capture is complete by itself, and objects
    /// freed in between have had their addresses reused, so merging captures
    /// by address leaves stale views beside their replacements. The latest
    /// capture is the document; the earlier ones are discarded whole.
    private static func testNewCaptureReplacesTheEarlierOne() {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: response(groups: [
            group("com.apple.AppKit.NSView", objects: [
                object("0x1", className: "NSView", childGroup: group("com.apple.AppKit.NSView", objects: [
                    object("0x2", className: "NSView", childGroup: group("com.apple.AppKit.NSView", objects: [
                        object("0x3", className: "NSTableRowView"),
                    ])),
                ])),
            ]),
        ]))
        builder.ingesting(response: response(properties: [
            "0x2.hidden": propertyDescription(name: "hidden", format: "b", value: "0"),
        ]))
        // The second capture: 0x2 is gone, 0x4 took its place, and the
        // address 0x3 now belongs to a different object.
        builder.ingesting(response: response(groups: [
            group("com.apple.AppKit.NSView", objects: [
                object("0x1", className: "NSView", childGroup: group("com.apple.AppKit.NSView", objects: [
                    object("0x4", className: "NSView", childGroup: group("com.apple.AppKit.NSView", objects: [
                        object("0x3", className: "NSTextField"),
                    ])),
                ])),
            ]),
        ]))
        let graph = builder.build()
        expect(graph.captureCount == 2, "expected two captures, got \(graph.captureCount)")
        expect(graph.node("0x1")?.childIdentifiers == ["0x4"],
               "the earlier capture's child survived: \(String(describing: graph.node("0x1")?.childIdentifiers))")
        expect(graph.node("0x2") == nil, "an object only the earlier capture described must be gone")
        expect(graph.node("0x3")?.className == "NSTextField",
               "a reused address must carry the latest class: \(String(describing: graph.node("0x3")?.className))")
        expect(graph.rootIdentifiers(inGroup: "com.apple.AppKit.NSView") == ["0x1"],
               "root list mismatch: \(graph.rootIdentifiers(inGroup: "com.apple.AppKit.NSView"))")
    }

    /// The shape that crashes Xcode itself when it opens such a document: two
    /// objects whose addresses swapped roles between captures. Merged by
    /// address, each is the other's child, and any walk of the tree recurses
    /// until the stack is gone.
    private static func testReusedAddressesDoNotFormACycle() {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: response(groups: [
            group("com.apple.AppKit.NSView", objects: [
                object("0x1", className: "NSView", childGroup: group("com.apple.AppKit.NSView", objects: [
                    object("0x2", className: "NSImageView", childGroup: group("com.apple.AppKit.NSView", objects: [
                        object("0x3", className: "_NSImageViewSimpleImageView"),
                    ])),
                ])),
            ]),
        ]))
        builder.ingesting(response: response(groups: [
            group("com.apple.AppKit.NSView", objects: [
                object("0x1", className: "NSView", childGroup: group("com.apple.AppKit.NSView", objects: [
                    object("0x3", className: "NSTableCellView", childGroup: group("com.apple.AppKit.NSView", objects: [
                        object("0x2", className: "NSImageView"),
                    ])),
                ])),
            ]),
        ]))
        let graph = builder.build()
        expect(graph.node("0x3")?.childIdentifiers == ["0x2"],
               "the latest capture's children were lost: \(String(describing: graph.node("0x3")?.childIdentifiers))")
        expect(graph.node("0x2")?.childIdentifiers.isEmpty == true,
               "the earlier capture's children leaked into a reused address: \(String(describing: graph.node("0x2")?.childIdentifiers))")
    }

    // MARK: - Fixture builders

    private static func response(
        groups: [[String: Any]] = [],
        properties: [String: Any] = [:]
    ) -> [String: Any] {
        var topLevelGroups: [String: Any] = [:]
        for group in groups {
            topLevelGroups[group["groupingID"] as? String ?? ""] = group
        }
        return [
            "version": NSNumber(value: 2),
            "topLevelGroups": topLevelGroups,
            "topLevelPropertyDescriptions": properties,
        ]
    }

    private static func group(_ groupingIdentifier: String, objects: [[String: Any]]) -> [String: Any] {
        ["groupingID": groupingIdentifier, "debugHierarchyObjects": objects]
    }

    private static func object(
        _ objectIdentifier: String,
        className: String,
        childGroup: [String: Any]? = nil,
        additionalGroups: [[String: Any]]? = nil
    ) -> [String: Any] {
        var object: [String: Any] = ["objectID": objectIdentifier, "className": className]
        if let childGroup {
            object["childGroup"] = childGroup
        }
        if let additionalGroups {
            object["additionalGroups"] = additionalGroups
        }
        return object
    }

    /// The shape a capture uses to point at an object described elsewhere.
    private static func reference(_ objectIdentifier: String) -> [String: Any] {
        [
            "objectID": objectIdentifier,
            "propertyVisibility": NSNumber(value: 1),
            "propertyLogicalType": "DebugHierarchyLogicalPropertyTypePointer",
        ]
    }

    private static func propertyDescription(name: String, format: String, value: Any) -> [String: Any] {
        [
            "propertyName": name,
            "propertyFormat": format,
            "propertyValue": value,
            "fetchStatus": NSNumber(value: 4),
        ]
    }

    private static func graphFrom(groups: [[String: Any]]) -> XcodeViewHierarchyObjectGraph {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: response(groups: groups))
        return builder.build()
    }

    // MARK: - Helpers

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
