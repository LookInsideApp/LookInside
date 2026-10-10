import AppKit
import Foundation

/// Coverage for turning a decoded capture into the inspector's model.
///
/// The converter is the one place that builds `DisplayItem` trees in
/// memory: outside the server, which sets every field explicitly, and outside
/// the archive decoder, which supplies compatibility defaults for absent keys.
/// Any field whose Objective-C default differs from what the reader expects is
/// therefore a trap here, and the two cases below are the two already fallen
/// into. Both share a failure signature — the import succeeds, the tree is
/// built, and the reader is then unusable: an assertion while drawing the
/// dashboard, and a preview that receives nothing.
@main
struct XcodeViewHierarchyConverterTests {
    static func main() {
        testColorAttributesCarryRGBAComponents()
        testEveryConvertedNodeOptsIntoScreenshots()
        testAppKitTopLevelFollowsXcodeSidebar()
        testUIKitTopLevelFollowsXcodeSidebar()
        testClassCardListsRelatedClassChains()
        testUIKitCardsFollowTheCapture()
        testAppKitCardsReadTheCell()
        testConstraintsCardFollowsTheServerModel()
        testLayerNodesFollowTheServerShape()
        testBackingLayerToggleExpandsTheLayerTree()
        testWrappedUIKitViewsKeepXcodesNesting()
        print("Xcode view hierarchy converter tests passed")
    }

    // MARK: - Dashboard contract

    /// A `LookinAttrTypeUIColor` value is an RGBA array of four numbers in
    /// 0...1 (`LookinAttrType.h`); the dashboard's colour card asserts on
    /// anything else. Handing it an `NSColor` raised on the first card drawn
    /// and aborted opening the document.
    private static func testColorAttributesCarryRGBAComponents() {
        let file = convertedFixture()
        var colorAttributes: [(identifier: String, value: Any?)] = []
        walk(file.hierarchyInfo?.displayItems ?? []) { item in
            for group in item.attributesGroupList ?? [] {
                for section in group.attrSections ?? [] {
                    for attribute in section.attributes ?? [] where attribute.attrType == .uiColor {
                        colorAttributes.append((attribute.identifier ?? "", attribute.value))
                    }
                }
            }
        }
        expect(colorAttributes.count == 2,
               "expected the layer's background and border colours, got \(colorAttributes.count)")

        for (identifier, value) in colorAttributes {
            guard let components = value as? [NSNumber] else {
                fail("\(identifier) carries \(value.map { "\(type(of: $0))" } ?? "nil") rather than an RGBA NSNumber array")
            }
            expect(components.count == 4, "\(identifier) needs 4 components, got \(components.count)")
            expect(NSColor.sRGBColor(fromRGBAComponents: components) != nil,
                   "\(identifier) does not decode as a colour")
        }

        let background = colorAttributes
            .first { $0.identifier == LookinAttr_ViewLayer_BgColor_BgColor }?
            .value as? [NSNumber]
        expect(background?.map(\.doubleValue) == [0.5, 0.25, 1, 1],
               "background colour components mismatch: \(String(describing: background))")
    }

    // MARK: - Preview contract

    /// `shouldCaptureImage` is NO on a freshly initialised item, and the host
    /// reads NO as "the user's config excluded this layer": it marks the node
    /// and its whole subtree `noPreview`, so the preview receives nothing.
    /// Every node the converter emits — window, view, layout guide, cell —
    /// has to opt in explicitly, the way the server does for each kind.
    private static func testEveryConvertedNodeOptsIntoScreenshots() {
        let file = convertedFixture()
        var kindsSeen: Set<LookinDisplayItemNodeKind> = []
        walk(file.hierarchyInfo?.displayItems ?? []) { item in
            kindsSeen.insert(item.nodeKind)
            expect(item.shouldCaptureImage,
                   "\(item) (nodeKind \(item.nodeKind.rawValue)) would be dropped from the preview: shouldCaptureImage is NO")
        }
        expect(kindsSeen == [.window, .view, .layoutGuide, .cell],
               "fixture must cover window, view, layout guide and cell nodes; saw \(kindsSeen.map(\.rawValue).sorted())")
    }

    // MARK: - Top-level contract

    /// The top level must come out the way Xcode's sidebar lists a capture,
    /// which is not the order — or the membership — of the capture's root
    /// groups. Xcode lists window controllers first (each with its windows),
    /// then windows no controller owns, with the key window's controller
    /// moved to the front; child windows join the list after the root ones;
    /// and of the root views only an NSTouchBarView with children survives.
    /// The first real capture opened (Finder) showed a detached status bar
    /// and path bar as top-level rows beside the windows — the two root
    /// views this rule now drops.
    private static func testAppKitTopLevelFollowsXcodeSidebar() {
        let file = convert(appKitSidebarFixture())
        let rootItems = file.hierarchyInfo?.displayItems ?? []

        expect(rootItems.map(displayedObjectIdentifier) == [0x3, 0x1, 0x2, 0x4, 0x60],
               "top level should be key window's controller, other controller, unowned windows, touch bar; got \(rootItems.map(displayedObjectIdentifier).map { String($0, radix: 16) })")
        expect(rootItems.map(\.nodeKind) == [.window, .window, .window, .window, .view],
               "top-level kinds mismatch: \(rootItems.map(\.nodeKind.rawValue))")
        expect(rootItems.map(\.representedAsKeyWindow) == [true, false, false, false, false],
               "only the application's key window is marked key")
        expect(rootItems[1].hostWindowControllerObject?.oid == 0xC1,
               "a controller-owned window row carries its controller")
        expect(rootItems[2].hostWindowControllerObject == nil,
               "an unowned window row carries no controller")

        let childWindowRow = rootItems[3]
        expect(childWindowRow.windowObject?.oid == 0x4, "the child window is listed as a window of its own")
        expect(rootItems[0].subitems?.map(displayedObjectIdentifier) == [0x30],
               "a child window must not be nested under its parent as a view; got \(String(describing: rootItems[0].subitems?.map(displayedObjectIdentifier)))")

        var everyIdentifier: Set<UInt> = []
        walk(rootItems) { everyIdentifier.insert(displayedObjectIdentifier($0)) }
        expect(!everyIdentifier.contains(0x50) && !everyIdentifier.contains(0x51),
               "a detached view controller view must not appear anywhere in the tree")
        expect(!everyIdentifier.contains(0x70), "a childless NSTouchBarView is not a top-level row")
    }

    /// On UIKit the window owners are scenes, and Xcode gives each a row of
    /// its own with its windows beneath — the shape a live session produces
    /// too. Windows that are internal or invisible are left out, except
    /// keyboard and iMessage extension windows, whose view controllers are
    /// the user's code; a system overlay window is always left out, and a
    /// remote keyboard window never earns the exception.
    private static func testUIKitTopLevelFollowsXcodeSidebar() {
        let file = convert(uiKitSidebarFixture())
        let rootItems = file.hierarchyInfo?.displayItems ?? []

        expect(rootItems.map(displayedObjectIdentifier) == [0xF2, 0xF1, 0x4],
               "top level should be the key window's scene, the other scene, then the sceneless window; got \(rootItems.map(displayedObjectIdentifier).map { String($0, radix: 16) })")
        expect(rootItems.map(\.nodeKind) == [.windowScene, .windowScene, .window],
               "top-level kinds mismatch: \(rootItems.map(\.nodeKind.rawValue))")
        expect(rootItems[0].subitems?.map(displayedObjectIdentifier) == [0x2],
               "the key scene lists its one visible window")
        expect(rootItems[1].subitems?.map(displayedObjectIdentifier) == [0x1, 0x6],
               "the other scene keeps its visible window and the keyboard window, dropping the internal one; got \(String(describing: rootItems[1].subitems?.map(displayedObjectIdentifier)))")
        expect(rootItems[0].representedAsKeyWindow && rootItems[0].subitems?.first?.representedAsKeyWindow == true,
               "the key window and the scene holding it are both marked key")
        expect(!rootItems[1].representedAsKeyWindow && !rootItems[2].representedAsKeyWindow,
               "no other row is marked key")
        expect(rootItems[0].customDisplayTitle == "UIWindowScene – Main (Foreground Active)",
               "scene title mismatch: \(String(describing: rootItems[0].customDisplayTitle))")
        expect(rootItems[0].windowObject?.classChainList?.first == "UIWindowScene",
               "a scene node rides windowObject like the server's")

        var everyIdentifier: Set<UInt> = []
        walk(rootItems) { item in
            everyIdentifier.insert(displayedObjectIdentifier(item))
            expect(item.shouldCaptureImage, "\(item) would be dropped from the preview: shouldCaptureImage is NO")
        }
        for skippedIdentifier: UInt in [0x3, 0x5, 0x7, 0x8] {
            expect(!everyIdentifier.contains(skippedIdentifier),
                   "window 0x\(String(skippedIdentifier, radix: 16)) should have been skipped")
        }
    }

    // MARK: - Dashboard cards

    /// The Class card lists the node's chain cut at the framework class the
    /// inspector treats as the root of its kind, then its controller's chain
    /// cut the same way — the server's `lks_relatedClassChainList`. The first
    /// version handed the card a bare class name, and the card, built for
    /// lists of chains, showed a single line: the lineage the capture records
    /// in `classInformation` never reached the dashboard.
    private static func testClassCardListsRelatedClassChains() {
        let uiKit = convert(uiKitCardsFixture())
        let scene = uiKit.hierarchyInfo?.displayItems?.first
        expect(classChains(of: scene) == [["UIWindowScene", "UIScene"]],
               "a scene's chain stops at UIScene; got \(String(describing: classChains(of: scene)))")
        let window = scene?.subitems?.first
        expect(classChains(of: window) == [["UIWindow", "UIView"]],
               "a window's chain stops at UIView and lists no controller; got \(String(describing: classChains(of: window)))")
        expect(attribute(LookinAttr_Relation_Relation_Relation, of: window) == nil,
               "a window is not its root view controller's view, so it has no relation row")
        let button = item(withObjectIdentifier: 0x11, in: uiKit)
        expect(classChains(of: button) == [["MyButton", "UIButton", "UIControl", "UIView"], ["MyViewController", "UIViewController"]],
               "a controller's view lists its own chain and the controller's; got \(String(describing: classChains(of: button)))")
        expect(relations(of: button) == ["(MyViewController *).view"],
               "relation row mismatch: \(String(describing: relations(of: button)))")
        let guide = item(withObjectIdentifier: 0x30, in: uiKit)
        expect(classChains(of: guide) == [["UILayoutGuide"]],
               "a layout guide's chain stops at UILayoutGuide; got \(String(describing: classChains(of: guide)))")

        let appKit = convert(appKitCardsFixture())
        let panel = appKit.hierarchyInfo?.displayItems?.first
        expect(classChains(of: panel) == [["NSPanel", "NSWindow"], ["MyWindowController", "NSWindowController"]],
               "an AppKit window lists its chain to NSWindow and its controller's; got \(String(describing: classChains(of: panel)))")
        expect(relations(of: panel) == ["(MyWindowController *).window", "(MyDelegate *) delegate"],
               "window relation rows mismatch: \(String(describing: relations(of: panel)))")
        let cell = item(withObjectIdentifier: 0x40, in: appKit)
        expect(classChains(of: cell) == [["NSButtonCell", "NSActionCell", "NSCell"]],
               "a cell's chain stops at NSCell; got \(String(describing: classChains(of: cell)))")
        expect(relations(of: cell) == ["(NSButton *).cell"],
               "cell relation mismatch: \(String(describing: relations(of: cell)))")
    }

    /// Every UIKit card the catalog maps, on the kinds of value the capture
    /// writes: text, a font structure, a gray colour widened to RGBA, an enum
    /// that must come out typed as one, insets, an image with its metadata
    /// name and bytes, and a nil that the blueprint says to show.
    private static func testUIKitCardsFollowTheCapture() {
        let file = convert(uiKitCardsFixture())

        let label = item(withObjectIdentifier: 0x12, in: file)
        expect(groupIdentifiers(of: label) == [LookinAttrGroup_Class, LookinAttrGroup_Layout, LookinAttrGroup_ViewLayer, LookinAttrGroup_UILabel],
               "a label's cards come in the blueprint's order; got \(groupIdentifiers(of: label))")
        expectAttribute(LookinAttr_UILabel_Text_Text, of: label, type: .nsString, equals: "Hello" as NSString)
        expectAttribute(LookinAttr_UILabel_Font_Name, of: label, type: .nsString, equals: ".SFUI-Regular" as NSString)
        expectAttribute(LookinAttr_UILabel_Font_Size, of: label, type: .double, equals: NSNumber(value: 17))
        expectAttribute(LookinAttr_UILabel_NumberOfLines_NumberOfLines, of: label, type: .long, equals: NSNumber(value: 2))
        expectAttribute(LookinAttr_UILabel_Alignment_Alignment, of: label, type: .enumLong, equals: NSNumber(value: 1))
        expectAttribute(LookinAttr_UILabel_TextColor_Color, of: label, type: .uiColor,
                        equals: [1, 1, 1, 0.5].map { NSNumber(value: $0) } as NSArray)
        expect(attribute(LookinAttr_AutoLayout_Hugging_Hor, of: label) == nil,
               "sizing priorities alone do not earn an Auto Layout card, as on the server")

        let untitledLabel = item(withObjectIdentifier: 0x16, in: file)
        guard let textAttribute = attribute(LookinAttr_UILabel_Text_Text, of: untitledLabel) else {
            fail("a label whose text is nil still shows its Text row")
        }
        expect(textAttribute.value == nil, "a captured nil text is reported as nil, not dropped")

        let imageView = item(withObjectIdentifier: 0x13, in: file)
        expectAttribute(LookinAttr_UIImageView_Name_Name, of: imageView, type: .nsString, equals: "star.fill" as NSString)
        expectAttribute(LookinAttr_UIImageView_Open_Open, of: imageView, type: .customObj, equals: imageBytes as NSData)
        expectAttribute(LookinAttr_ViewLayer_ContentMode_Mode, of: imageView, type: .enumLong, equals: NSNumber(value: 1))
        let emptyImageView = item(withObjectIdentifier: 0x14, in: file)
        expect(!groupIdentifiers(of: emptyImageView).contains(LookinAttrGroup_UIImageView),
               "an image view without an image shows no image rows")

        let button = item(withObjectIdentifier: 0x11, in: file)
        guard let insets = attribute(LookinAttr_UIButton_ContentInsets_Insets, of: button),
              insets.attrType == .uiEdgeInsets, let insetsValue = insets.value as? NSValue
        else { fail("a button's content insets come out as an insets value") }
        expect(NSEdgeInsetsEqual(insetsValue.edgeInsetsValue, NSEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)),
               "insets are top, left, bottom, right; got \(insetsValue.edgeInsetsValue)")
        expectAttribute(LookinAttr_UIControl_EnabledSelected_Enabled, of: button, type: .BOOL, equals: NSNumber(value: true))
        expectAttribute(LookinAttr_ViewLayer_InterationAndMasks_MasksToBounds, of: button, type: .BOOL, equals: NSNumber(value: true))

        let stackView = item(withObjectIdentifier: 0x15, in: file)
        expectAttribute(LookinAttr_UIStackView_Axis_Axis, of: stackView, type: .enumLong, equals: NSNumber(value: 1))
        expectAttribute(LookinAttr_UIStackView_Spacing_Spacing, of: stackView, type: .double, equals: NSNumber(value: 8))

        let scene = file.hierarchyInfo?.displayItems?.first
        expectAttribute(LookinAttr_UIWindowScene_Title_Title, of: scene, type: .nsString, equals: "Main" as NSString)
        expectAttribute(LookinAttr_UIWindowScene_State_ActivationState, of: scene, type: .enumLong, equals: NSNumber(value: 0))
        expectAttribute(LookinAttr_UIWindowScene_Windows_WindowCount, of: scene, type: .long, equals: NSNumber(value: 1))
        expectAttribute(LookinAttr_UIWindowScene_Windows_KeyWindowClassName, of: scene, type: .nsString, equals: "UIWindow" as NSString)
        expectAttribute(LookinAttr_UIWindowScene_Screen_ScreenScale, of: scene, type: .double, equals: NSNumber(value: 3))
        guard let screenBounds = attribute(LookinAttr_UIWindowScene_Screen_ScreenBounds, of: scene)?.value as? NSValue else {
            fail("a scene's screen bounds are read through its screen reference")
        }
        expect(screenBounds.rectValue == CGRect(x: 0, y: 0, width: 402, height: 874),
               "screen bounds mismatch: \(screenBounds.rectValue)")
    }

    /// AppKit keeps a control's bezel style, button type and placeholder on
    /// its cell, and the capture records them there; the control's cards
    /// must read through to the cell, while the cell node reads itself. A
    /// window's style mask and collection behaviour arrive as one integer
    /// and fan out into the blueprint's one-flag-per-row switches.
    private static func testAppKitCardsReadTheCell() {
        let file = convert(appKitCardsFixture())

        let panel = file.hierarchyInfo?.displayItems?.first
        expect(groupIdentifiers(of: panel) == [LookinAttrGroup_Class, LookinAttrGroup_Relation, LookinAttrGroup_Layout, LookinAttrGroup_NSWindow],
               "a window's cards: class, relation, layout, window; got \(groupIdentifiers(of: panel))")
        expectAttribute(LookinAttr_NSWindow_Title_Title, of: panel, type: .nsString, equals: "Inspector" as NSString)
        expectAttribute(LookinAttr_NSWindow_State_KeyWindow, of: panel, type: .BOOL, equals: NSNumber(value: true))
        expectAttribute(LookinAttr_NSWindow_Style_Titled, of: panel, type: .BOOL, equals: NSNumber(value: true))
        expectAttribute(LookinAttr_NSWindow_Style_Resizable, of: panel, type: .BOOL, equals: NSNumber(value: true))
        expectAttribute(LookinAttr_NSWindow_Style_HUDWindow, of: panel, type: .BOOL, equals: NSNumber(value: false))
        expectAttribute(LookinAttr_NSWindow_CollectionBehavior_FullScreenPrimary, of: panel, type: .BOOL, equals: NSNumber(value: true))
        expectAttribute(LookinAttr_NSWindow_CollectionBehavior_CanJoinAllSpaces, of: panel, type: .BOOL, equals: NSNumber(value: false))
        guard let frame = attribute(LookinAttr_Layout_Frame_Frame, of: panel)?.value as? NSValue else {
            fail("an AppKit window's frame reaches the Layout card")
        }
        expect(frame.rectValue == CGRect(x: 10, y: 20, width: 300, height: 200), "window frame mismatch: \(frame.rectValue)")

        let button = item(withObjectIdentifier: 0x11, in: file)
        expectAttribute(LookinAttr_NSButton_BezelStyle_BezelStyle, of: button, type: .enumLong, equals: NSNumber(value: 1))
        expectAttribute(LookinAttr_NSButton_ButtonType_ButtonType, of: button, type: .enumLong, equals: NSNumber(value: 7))
        expectAttribute(LookinAttr_NSButton_Bordered_Bordered, of: button, type: .BOOL, equals: NSNumber(value: true))
        expectAttribute(LookinAttr_NSButton_Title_Title, of: button, type: .nsString, equals: "OK" as NSString)
        expectAttribute(LookinAttr_NSControl_Font_Name, of: button, type: .nsString, equals: ".SFNS-Regular" as NSString)
        expectAttribute(LookinAttr_NSControl_Alignment_Alignment, of: button, type: .enumLong, equals: NSNumber(value: 2))

        let textField = item(withObjectIdentifier: 0x12, in: file)
        expectAttribute(LookinAttr_NSTextField_Placeholder_Placeholder, of: textField, type: .nsString, equals: "Search" as NSString)
        expectAttribute(LookinAttr_NSTextField_Editable_Editable, of: textField, type: .BOOL, equals: NSNumber(value: true))

        let cell = item(withObjectIdentifier: 0x40, in: file)
        expect(groupIdentifiers(of: cell) == [LookinAttrGroup_Class, LookinAttrGroup_Relation, LookinAttrGroup_NSCell],
               "a cell's cards: class, relation, cell; got \(groupIdentifiers(of: cell))")
        expectAttribute(LookinAttr_NSCell_Cell_Bordered, of: cell, type: .BOOL, equals: NSNumber(value: true))
        expectAttribute(LookinAttr_NSCell_Content_Title, of: cell, type: .nsString, equals: "OK" as NSString)
        expectAttribute(LookinAttr_NSCell_ButtonCell_BezelStyle, of: cell, type: .enumLong, equals: NSNumber(value: 1))
    }

    /// The Auto Layout card carries the server's constraint model: every
    /// active constraint naming the view as an item, each end typed relative
    /// to the view (self, superview, another view, a layout guide, nil), and
    /// marked effective when the capture lists it among the constraints
    /// affecting the view's layout. Inactive constraints are left out, as the
    /// whole product leaves them out.
    private static func testConstraintsCardFollowsTheServerModel() {
        let file = convert(uiKitCardsFixture())
        let button = item(withObjectIdentifier: 0x11, in: file)
        guard let constraintsAttribute = attribute(LookinAttr_AutoLayout_Constraints_Constraints, of: button),
              constraintsAttribute.attrType == .customObj,
              let constraints = constraintsAttribute.value as? [AutoLayoutConstraint]
        else { fail("a view with constraints gets a constraints row carrying LookinAutoLayoutConstraint values") }

        expect(constraints.map(\.constraintOid) == [0xD1, 0xD2, 0xD4],
               "the active constraints naming the view, in identifier order; got \(constraints.map { String($0.constraintOid, radix: 16) })")
        expect(constraints.map(\.effective) == [true, false, false],
               "only the constraint the capture lists as affecting the view is effective; got \(constraints.map(\.effective))")
        expect(constraints.map(\.firstItemType) == [.`self`, .`self`, .layoutGuide],
               "first item types mismatch: \(constraints.map(\.firstItemType.rawValue))")
        expect(constraints.map(\.secondItemType) == [.`nil`, .super, .`self`],
               "second item types mismatch: \(constraints.map(\.secondItemType.rawValue))")
        expect(constraints[0].firstAttribute == 7 && constraints[0].constant == 100 && constraints[0].priority == 1000
            && constraints[0].relation == .equal && constraints[0].secondItem == nil,
            "width constraint fields mismatch")
        expect(constraints[1].secondItem?.oid == 0x10 && constraints[1].constant == 8 && constraints[1].relation == .greaterThanOrEqual,
               "superview constraint fields mismatch")
        expect(constraints[2].firstItem?.classChainList == ["UILayoutGuide", "NSObject"] && constraints[2].identifier == "guide-leading",
               "layout guide endpoint carries its class chain and the constraint its identifier")

        let hugging = attribute(LookinAttr_AutoLayout_Hugging_Hor, of: button)
        expect(hugging?.attrType == .double && (hugging?.value as? NSNumber)?.doubleValue == 250,
               "sizing priorities ride along once the card exists")
        let rootView = item(withObjectIdentifier: 0x10, in: file)
        expect((attribute(LookinAttr_AutoLayout_Constraints_Constraints, of: rootView)?.value as? [AutoLayoutConstraint])?
            .map(\.constraintOid) == [0xD2],
            "the superview lists the same constraint from its own side")
    }

    // MARK: - Layer nodes

    /// Toggle off — the server's default shape. A view and its backing layer
    /// are one node routed by the layer; the sublayers that back no view are
    /// layer nodes at their z positions among the subviews; AppKit's drawing
    /// containers stay inside the view; and a layer node's cards are the
    /// layer rows only.
    private static func testLayerNodesFollowTheServerShape() {
        let file = convert(appKitLayerTreeFixture(), screenshots: layerTreeScreenshots(), showingBackingLayers: false)
        let contentView = item(withObjectIdentifier: 0x10, in: file)
        expect(contentView.layerObject?.oid == 0x100, "a merged view node rides its backing layer")
        expect(childShape(of: contentView) == ["layer:0x101", "view:0x11", "layer:0x103"],
               "orphan sublayers sit at their z positions and the drawing container is hidden; got \(childShape(of: contentView))")
        let subview = item(withObjectIdentifier: 0x11, in: file)
        expect(childShape(of: subview).isEmpty, "a drawing container is not a node with the toggle off; got \(childShape(of: subview))")

        let gradient = item(withObjectIdentifier: 0x101, in: file)
        expect(gradient.nodeKind == .layer, "an orphan sublayer is a layer node")
        expect(gradient.frame == CGRect(x: 10, y: 10, width: 50, height: 50), "a layer node keeps the layer's frame; got \(gradient.frame)")
        expect(classChains(of: gradient) == [["CAGradientLayer", "CALayer"]],
               "a layer node's chain stops at CALayer; got \(String(describing: classChains(of: gradient)))")
        expect(attribute(LookinAttr_Layout_Frame_Frame, of: gradient) != nil, "a layer node answers the layer rows")
        expect(attribute(LookinAttr_ViewLayer_Tag_Tag, of: gradient) == nil, "a layer node has no view rows")

        expect(file.soloScreenshots?[0x100] == imageData("solo-100"), "the merged node's solo is the layer's own content")
        expect(file.groupScreenshots?[0x100] == imageData("group-100"), "the merged node's group is the whole subtree")
        expect(file.groupScreenshots?[0x10] == nil && file.soloScreenshots?[0x10] == nil,
               "nothing is filed under the view oid while the layer routes the node")
        expect(file.groupScreenshots?[0x101] == imageData("group-101"), "a layer node's images are filed under its own oid")
        expect(contentView.groupScreenshotRegion == CGRect(x: 10, y: 10, width: 100, height: 50),
               "a partial group image carries its region onto the node; got \(contentView.groupScreenshotRegion)")
        expect(contentView.soloScreenshotRegion == .zero, "solo images always cover the node")
    }

    /// Toggle on: the backing layer is a node of its own, first among the
    /// view's children, carrying every sublayer that backs no view — drawing
    /// containers included — and the pixels move with it: the view node has
    /// no solo and routes by its own oid, the backing layer's group leaves
    /// out the subviews' planes.
    private static func testBackingLayerToggleExpandsTheLayerTree() {
        let file = convert(appKitLayerTreeFixture(), screenshots: layerTreeScreenshots(), showingBackingLayers: true)
        let contentView = item(withObjectIdentifier: 0x10, in: file)
        expect(childShape(of: contentView) == ["backingLayer:0x100", "view:0x11"],
               "the backing layer comes first, then the subviews; got \(childShape(of: contentView))")
        let backingLayer = item(withObjectIdentifier: 0x100, in: file)
        expect(backingLayer.nodeKind == .backingLayer, "the backing layer node has its own kind")
        expect(backingLayer.frame == CGRect(x: 0, y: 0, width: 200, height: 100),
               "the backing layer covers its view edge to edge; got \(backingLayer.frame)")
        expect(childShape(of: backingLayer) == ["layer:0x101", "layer:0x102", "layer:0x103"],
               "the backing layer carries the non-view sublayers, drawing container included; got \(childShape(of: backingLayer))")
        let subview = item(withObjectIdentifier: 0x11, in: file)
        expect(childShape(of: subview) == ["backingLayer:0x110"], "a leaf view still gets its backing layer; got \(childShape(of: subview))")
        expect(childShape(of: item(withObjectIdentifier: 0x110, in: file)) == ["layer:0x111"],
               "the label's drawing container is where its text lives")

        expect(file.groupScreenshots?[0x10] == imageData("group-100"), "the view node keeps the folded look, filed under the view oid")
        expect(file.soloScreenshots?[0x10] == nil, "the view node has no solo: expanded it is a wireframe")
        expect(file.soloScreenshots?[0x100] == imageData("solo-100"), "the backing layer's solo is its own content")
        expect(file.groupScreenshots?[0x100] == imageData("excluding-100"),
               "the backing layer's group leaves out the subviews' planes")
        expect(file.groupScreenshots?[0x110] == imageData("group-110"),
               "a backing layer with no views beneath shows its whole subtree")
        expect(contentView.groupScreenshotRegion == CGRect(x: 10, y: 10, width: 100, height: 50),
               "the view node's folded image keeps the full render's region; got \(contentView.groupScreenshotRegion)")
        expect(backingLayer.groupScreenshotRegion == CGRect(x: 0, y: 0, width: 200, height: 30),
               "the backing layer's image keeps the region of the render without the subviews; got \(backingLayer.groupScreenshotRegion)")
    }

    /// iOS 26 wraps a view's backing layer in a `_UIMultiLayer`, and the
    /// capture associates the view with the wrapper. The node rides the
    /// backing layer beneath (the sublayer whose delegate is the view) with
    /// the wrapper's geometry. Toggle off, the wrapper follows the view as a
    /// pixelless coplanar child; toggle on, Xcode's nesting applies: view →
    /// wrapper → backing layer, with anything else parked on the wrapper as
    /// the wrapper's own child.
    private static func testWrappedUIKitViewsKeepXcodesNesting() {
        let screenshots = XcodeViewHierarchyScreenshots(
            soloByObjectIdentifier: [:],
            groupByObjectIdentifier: ["0x1000": imageData("group-1000"), "0x1201": imageData("group-1201")],
            failedArchiveIdentifiers: []
        )
        let folded = convert(uiKitWrapperFixture(), screenshots: screenshots, showingBackingLayers: false)
        let foldedImageView = item(withObjectIdentifier: 0x11, in: folded)
        expect(foldedImageView.layerObject?.oid == 0x1201, "the node rides the backing layer beneath the wrapper")
        expect(foldedImageView.frame == CGRect(x: 10, y: 20, width: 40, height: 30),
               "geometry comes from the wrapper, which UIKit moved it onto; got \(foldedImageView.frame)")
        expect(childShape(of: foldedImageView) == ["layer:0x1202", "viewOuterLayer:0x1200"],
               "toggle off: parked sublayers, then the wrapper as a coplanar child; got \(childShape(of: foldedImageView))")
        let wrapper = item(withObjectIdentifier: 0x1200, in: folded)
        expect(wrapper.frame == CGRect(x: 0, y: 0, width: 40, height: 30), "the wrapper covers the view it wraps; got \(wrapper.frame)")
        expect(folded.groupScreenshots?[0x1201] == imageData("group-1201"), "the merged node's images are filed under the backing layer")

        let expanded = convert(uiKitWrapperFixture(), screenshots: screenshots, showingBackingLayers: true)
        let expandedImageView = item(withObjectIdentifier: 0x11, in: expanded)
        expect(childShape(of: expandedImageView) == ["viewOuterLayer:0x1200"],
               "toggle on: the wrapper is the only layer child; got \(childShape(of: expandedImageView))")
        expect(childShape(of: item(withObjectIdentifier: 0x1200, in: expanded)) == ["backingLayer:0x1201", "layer:0x1202"],
               "the backing layer nests inside the wrapper with the parked sublayer beside it")
        expect(expanded.groupScreenshots?[0x11] == imageData("group-1201"), "the view node routes by its own oid")
        let window = item(withObjectIdentifier: 0x1, in: expanded)
        expect(childShape(of: window) == ["backingLayer:0x1000", "view:0x10"],
               "a UIWindow is a view and gets its backing layer too; got \(childShape(of: window))")
        expect(expanded.groupScreenshots?[0x1] == imageData("group-1000"), "the window node routes by the window oid")
    }

    /// The kinds and objects of a node's children, e.g. `["layer:0x101", "view:0x11"]`.
    private static func childShape(of item: DisplayItem) -> [String] {
        (item.subitems ?? []).map { subitem in
            let kindName: String
            switch subitem.nodeKind {
            case .layer: kindName = "layer"
            case .view: kindName = "view"
            case .window: kindName = "window"
            case .windowScene: kindName = "windowScene"
            case .layoutGuide: kindName = "layoutGuide"
            case .cell: kindName = "cell"
            case .viewOuterLayer: kindName = "viewOuterLayer"
            case .backingLayer: kindName = "backingLayer"
            default: kindName = "other"
            }
            return "\(kindName):0x\(String(displayedObjectIdentifier(subitem), radix: 16))"
        }
    }

    /// Stand-in image bytes; the converter files them without looking inside.
    private static func imageData(_ label: String) -> Data {
        Data(label.utf8)
    }

    private static func layerTreeScreenshots() -> XcodeViewHierarchyScreenshots {
        XcodeViewHierarchyScreenshots(
            soloByObjectIdentifier: ["0x100": imageData("solo-100")],
            groupByObjectIdentifier: [
                "0x100": imageData("group-100"), "0x101": imageData("group-101"), "0x102": imageData("group-102"),
                "0x110": imageData("group-110"), "0x111": imageData("group-111"),
            ],
            groupExcludingHostedViewsByObjectIdentifier: ["0x100": imageData("excluding-100")],
            groupRegionByObjectIdentifier: ["0x100": CGRect(x: 10, y: 10, width: 100, height: 50)],
            groupExcludingHostedViewsRegionByObjectIdentifier: ["0x100": CGRect(x: 0, y: 0, width: 200, height: 30)],
            failedArchiveIdentifiers: []
        )
    }

    /// An AppKit window whose content view's backing layer carries, in z
    /// order: an orphan gradient layer, the subview's backing layer, a drawing
    /// container (AppKit's own drawing: no delegate, a backing store for
    /// contents) and an image layer the app assigned. The subview's backing
    /// layer holds the label's own drawing container.
    private static func appKitLayerTreeFixture() -> XcodeViewHierarchyObjectGraph {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: response(
            groups: [
                group("com.apple.AppKit.NSWindow", objects: [
                    object("0x1", className: "NSWindow", additionalGroups: [
                        group("com.apple.AppKit.NSView", objects: [reference("0x10")]),
                    ]),
                ]),
                group("com.apple.AppKit.NSView", objects: [
                    object(
                        "0x10", className: "NSView",
                        childGroup: group("com.apple.AppKit.NSView", objects: [
                            object("0x11", className: "NSTextField", additionalGroups: [
                                group("com.apple.QuartzCore.CALayer", objects: [reference("0x110")]),
                            ]),
                        ]),
                        additionalGroups: [
                            group("com.apple.QuartzCore.CALayer", objects: [reference("0x100")]),
                        ]
                    ),
                ]),
                group("com.apple.QuartzCore.CALayer", objects: [
                    object("0x100", className: "NSViewBackingLayer", childGroup: group("com.apple.QuartzCore.CALayer", objects: [
                        object("0x101", className: "CAGradientLayer"),
                        object("0x110", className: "NSViewBackingLayer", childGroup: group("com.apple.QuartzCore.CALayer", objects: [
                            object("0x111", className: "ContentLayer"),
                        ])),
                        object("0x102", className: "ContentLayer"),
                        object("0x103", className: "CALayer"),
                    ])),
                ]),
            ],
            properties: [
                "0x10.frame": propertyDescription(name: "frame", format: "CGf, CGf, CGf, CGf", value: ["0x0p+0", "0x0p+0", "0x1.9p+7", "0x1.9p+6"]),
                "0x11.frame": propertyDescription(name: "frame", format: "CGf, CGf, CGf, CGf", value: ["0x0p+0", "0x0p+0", "0x1.9p+6", "0x1.4p+4"]),
                "0x100.frame": propertyDescription(name: "frame", format: "CGf, CGf, CGf, CGf", value: ["0x0p+0", "0x0p+0", "0x1.9p+7", "0x1.9p+6"]),
                "0x100.bounds": propertyDescription(name: "bounds", format: "CGf, CGf, CGf, CGf", value: ["0x0p+0", "0x0p+0", "0x1.9p+7", "0x1.9p+6"]),
                "0x101.frame": propertyDescription(name: "frame", format: "CGf, CGf, CGf, CGf", value: ["0x1.4p+3", "0x1.4p+3", "0x1.9p+5", "0x1.9p+5"]),
                "0x101.hidden": propertyDescription(name: "hidden", format: "b", value: "0"),
                "0x102.delegate": valuelessPropertyDescription(name: "delegate", format: "objectInfo"),
                "0x102.contentsDescription": propertyDescription(name: "contentsDescription", format: "public.plain-text", value: "<CABackingStore 0x1 (buffer [200 100] A8)>"),
                "0x103.contentsDescription": propertyDescription(name: "contentsDescription", format: "public.plain-text", value: "<CGImage 0x2 width = 10, height = 10>"),
                "0x110.frame": propertyDescription(name: "frame", format: "CGf, CGf, CGf, CGf", value: ["0x0p+0", "0x0p+0", "0x1.9p+6", "0x1.4p+4"]),
                "0x110.bounds": propertyDescription(name: "bounds", format: "CGf, CGf, CGf, CGf", value: ["0x0p+0", "0x0p+0", "0x1.9p+6", "0x1.4p+4"]),
                "0x111.delegate": valuelessPropertyDescription(name: "delegate", format: "objectInfo"),
                "0x111.contentsDescription": propertyDescription(name: "contentsDescription", format: "public.plain-text", value: "<CABackingStore 0x3 (buffer [100 20] A8)>"),
            ],
            classInformation: [
                classNode("NSObject", [
                    classNode("CALayer", [classNode("CAGradientLayer"), classNode("NSViewBackingLayer"), classNode("ContentLayer")]),
                    classNode("NSResponder", [
                        classNode("NSView", [classNode("NSControl", [classNode("NSTextField")])]),
                        classNode("NSWindow"),
                    ]),
                ]),
            ]
        ))
        return builder.build()
    }

    /// A UIKit window with one root view and an image view whose backing
    /// layer UIKit wrapped in a `_UIMultiLayer`, with a second layer parked
    /// on the wrapper that belongs to someone else.
    private static func uiKitWrapperFixture() -> XcodeViewHierarchyObjectGraph {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: response(
            groups: [
                group("com.apple.UIKit.UIApplication", objects: [
                    object("0xa0", className: "UIApplication", additionalGroups: [
                        group("com.apple.UIKit.UIWindow", objects: [reference("0x1")]),
                    ]),
                ]),
                group("com.apple.UIKit.UIScene", objects: [
                    object("0xf1", className: "UIWindowScene", additionalGroups: [
                        group("com.apple.UIKit.UIWindow", objects: [reference("0x1")]),
                    ]),
                ]),
                group("com.apple.UIKit.UIWindow", objects: [
                    object(
                        "0x1", className: "UIWindow",
                        childGroup: group("com.apple.UIKit.UIView", objects: [
                            object(
                                "0x10", className: "UIView",
                                childGroup: group("com.apple.UIKit.UIView", objects: [
                                    object("0x11", className: "UIImageView", additionalGroups: [
                                        group("com.apple.QuartzCore.CALayer", objects: [reference("0x1200")]),
                                    ]),
                                ]),
                                additionalGroups: [
                                    group("com.apple.QuartzCore.CALayer", objects: [reference("0x1100")]),
                                ]
                            ),
                        ]),
                        additionalGroups: [
                            group("com.apple.UIKit.UIScene", objects: [reference("0xf1")]),
                            group("com.apple.QuartzCore.CALayer", objects: [reference("0x1000")]),
                        ]
                    ),
                ]),
                group("com.apple.QuartzCore.CALayer", objects: [
                    object("0x1000", className: "CALayer", childGroup: group("com.apple.QuartzCore.CALayer", objects: [
                        object("0x1100", className: "CALayer", childGroup: group("com.apple.QuartzCore.CALayer", objects: [
                            object("0x1200", className: "_UIMultiLayer", childGroup: group("com.apple.QuartzCore.CALayer", objects: [
                                object("0x1201", className: "CALayer"),
                                object("0x1202", className: "CALayer"),
                            ])),
                        ])),
                    ])),
                ]),
            ],
            properties: [
                "0x1000.frame": propertyDescription(name: "frame", format: "CGf, CGf, CGf, CGf", value: ["0x0p+0", "0x0p+0", "0x1.2cp+8", "0x1.9p+8"]),
                "0x1000.bounds": propertyDescription(name: "bounds", format: "CGf, CGf, CGf, CGf", value: ["0x0p+0", "0x0p+0", "0x1.2cp+8", "0x1.9p+8"]),
                "0x1100.frame": propertyDescription(name: "frame", format: "CGf, CGf, CGf, CGf", value: ["0x0p+0", "0x0p+0", "0x1.2cp+8", "0x1.9p+8"]),
                "0x1200.frame": propertyDescription(name: "frame", format: "CGf, CGf, CGf, CGf", value: ["0x1.4p+3", "0x1.4p+4", "0x1.4p+5", "0x1.ep+4"]),
                "0x1200.bounds": propertyDescription(name: "bounds", format: "CGf, CGf, CGf, CGf", value: ["0x0p+0", "0x0p+0", "0x1.4p+5", "0x1.ep+4"]),
                "0x1200.delegate": propertyDescription(name: "delegate", format: "objectInfo", value: objectReference("UIImageView", "0x11")),
                "0x1201.frame": propertyDescription(name: "frame", format: "CGf, CGf, CGf, CGf", value: ["0x0p+0", "0x0p+0", "0x1.4p+5", "0x1.ep+4"]),
                "0x1201.bounds": propertyDescription(name: "bounds", format: "CGf, CGf, CGf, CGf", value: ["0x0p+0", "0x0p+0", "0x1.4p+5", "0x1.ep+4"]),
                "0x1201.delegate": propertyDescription(name: "delegate", format: "objectInfo", value: objectReference("UIImageView", "0x11")),
                "0x1202.frame": propertyDescription(name: "frame", format: "CGf, CGf, CGf, CGf", value: ["0x0p+0", "0x0p+0", "0x1.4p+5", "0x1.ep+4"]),
                "0x1202.delegate": propertyDescription(name: "delegate", format: "objectInfo", value: objectReference("UIView", "0x99")),
            ],
            classInformation: [
                classNode("NSObject", [
                    classNode("CALayer", [classNode("_UIMultiLayer")]),
                    classNode("UIResponder", [classNode("UIView", [classNode("UIImageView"), classNode("UIWindow")])]),
                    classNode("UIScene", [classNode("UIWindowScene")]),
                ]),
            ]
        ))
        return builder.build()
    }

    // MARK: - Fixture

    /// The capture-side shape of a detached AppKit view alongside windows
    /// with and without controllers, a child window, and touch bars:
    ///
    /// - controllers `0xc1` → window `0x1`, `0xc2` → window `0x3` (key);
    /// - window `0x2` has no controller; window `0x3` has child window `0x4`;
    /// - root views: the four window frames, a detached `TStatusBar` (`0x50`)
    ///   owned by a view controller, an `NSTouchBarView` with a child (`0x60`)
    ///   and one without (`0x70`).
    private static func appKitSidebarFixture() -> XcodeViewHierarchyObjectGraph {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: response(groups: [
            group("com.apple.AppKit.NSApplication", objects: [
                object("0xa0", className: "NSApplication", additionalGroups: [
                    group("com.apple.AppKit.NSWindow", objects: [reference("0x1"), reference("0x2"), reference("0x3")]),
                ]),
            ]),
            group("com.apple.AppKit.NSWindowController", objects: [
                object("0xc1", className: "NSWindowController", additionalGroups: [
                    group("com.apple.AppKit.NSWindow", objects: [reference("0x1")]),
                ]),
                object("0xc2", className: "NSWindowController", additionalGroups: [
                    group("com.apple.AppKit.NSWindow", objects: [reference("0x3")]),
                ]),
            ]),
            group("com.apple.AppKit.NSWindow", objects: [
                object("0x1", className: "NSWindow", additionalGroups: [
                    group("com.apple.AppKit.NSView", objects: [reference("0x10")]),
                    group("com.apple.AppKit.NSWindowController", objects: [reference("0xc1")]),
                ]),
                object("0x2", className: "NSWindow", additionalGroups: [
                    group("com.apple.AppKit.NSView", objects: [reference("0x20")]),
                ]),
                object(
                    "0x3", className: "NSWindow",
                    childGroup: group("com.apple.AppKit.NSWindow", objects: [
                        object("0x4", className: "NSPanel", additionalGroups: [
                            group("com.apple.AppKit.NSView", objects: [reference("0x40")]),
                        ]),
                    ]),
                    additionalGroups: [
                        group("com.apple.AppKit.NSView", objects: [reference("0x30")]),
                        group("com.apple.AppKit.NSWindowController", objects: [reference("0xc2")]),
                    ]
                ),
            ]),
            group("com.apple.AppKit.NSView", objects: [
                object("0x10", className: "NSNextStepFrame"),
                object("0x20", className: "NSNextStepFrame"),
                object("0x30", className: "NSThemeFrame"),
                object("0x40", className: "NSNextStepFrame"),
                object(
                    "0x50", className: "TStatusBar",
                    childGroup: group("com.apple.AppKit.NSView", objects: [object("0x51", className: "NSView")]),
                    additionalGroups: [
                        group("com.apple.AppKit.NSViewController", objects: [
                            object("0x55", className: "TStatusBarController"),
                        ]),
                    ]
                ),
                object(
                    "0x60", className: "NSTouchBarView",
                    childGroup: group("com.apple.AppKit.NSView", objects: [object("0x61", className: "NSView")])
                ),
                object("0x70", className: "NSTouchBarView"),
            ]),
        ]))
        builder.ingesting(response: response(properties: [
            "0xa0.keyWindow": propertyDescription(name: "keyWindow", format: "public.plain-text", value: "0x3"),
        ]))
        return builder.build()
    }

    /// The capture-side shape of a UIKit app with two scenes:
    ///
    /// - scene `0xf1` owns windows `0x1` (visible), `0x3` (internal), `0x6`
    ///   (internal, hosting a `UIInputViewController`) and `0x8` (a
    ///   `UIRemoteKeyboardWindow` hosting the same);
    /// - scene `0xf2` owns window `0x2`, the application's key window;
    /// - windows `0x4` (visible), `0x5` (invisible) and `0x7` (a system
    ///   overlay window) belong to no scene.
    private static func uiKitSidebarFixture() -> XcodeViewHierarchyObjectGraph {
        func window(
            _ objectIdentifier: String,
            className: String = "UIWindow",
            scene: String? = nil,
            controller: [String: Any]? = nil
        ) -> [String: Any] {
            var additionalGroups: [[String: Any]] = []
            if let scene {
                additionalGroups.append(group("com.apple.UIKit.UIScene", objects: [reference(scene)]))
            }
            if let controller {
                additionalGroups.append(group("com.apple.UIKit.UIViewController", objects: [controller]))
            }
            return object(
                objectIdentifier, className: className,
                childGroup: group("com.apple.UIKit.UIView", objects: [
                    object(objectIdentifier + "1", className: "UIView"),
                ]),
                additionalGroups: additionalGroups
            )
        }
        func flags(_ objectIdentifier: String, internal isInternal: Bool, visible: Bool) -> [String: Any] {
            [
                "\(objectIdentifier).internal": propertyDescription(name: "internal", format: "b", value: isInternal ? "1" : "0"),
                "\(objectIdentifier).visible": propertyDescription(name: "visible", format: "b", value: visible ? "1" : "0"),
            ]
        }
        // The user's controller sits one level down in the keyboard window's
        // controller tree, which Xcode walks rather than just the top level.
        func keyboardController(_ objectIdentifier: String) -> [String: Any] {
            object(
                objectIdentifier, className: "UICompatibilityInputViewController",
                childGroup: group("com.apple.UIKit.UIViewController", objects: [
                    object(objectIdentifier + "1", className: "UIInputViewController"),
                ])
            )
        }

        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: response(groups: [
            group("com.apple.UIKit.UIApplication", objects: [
                object("0xa0", className: "UIApplication", additionalGroups: [
                    group("com.apple.UIKit.UIWindow", objects: [reference("0x1"), reference("0x2")]),
                ]),
            ]),
            group("com.apple.UIKit.UIScene", objects: [
                object("0xf1", className: "UIWindowScene", additionalGroups: [
                    group("com.apple.UIKit.UIWindow", objects: [reference("0x1"), reference("0x3"), reference("0x6"), reference("0x8")]),
                ]),
                object("0xf2", className: "UIWindowScene", additionalGroups: [
                    group("com.apple.UIKit.UIWindow", objects: [reference("0x2")]),
                ]),
            ]),
            group("com.apple.UIKit.UIWindow", objects: [
                window("0x1", scene: "0xf1"),
                window("0x2", scene: "0xf2"),
                window("0x3", scene: "0xf1"),
                window("0x4"),
                window("0x5"),
                window("0x6", className: "UITextEffectsWindow", scene: "0xf1", controller: keyboardController("0x66")),
                window("0x7", className: "_UIWindowSystemOverlayWindow"),
                window("0x8", className: "UIRemoteKeyboardWindow", scene: "0xf1", controller: keyboardController("0x88")),
            ]),
        ]))
        var properties: [String: Any] = [
            "0xa0.keyWindow": propertyDescription(name: "keyWindow", format: "public.plain-text", value: "0x2"),
            "0xf2.title": propertyDescription(name: "title", format: "public.plain-text", value: "Main"),
            "0xf2.activationState": propertyDescription(name: "activationState", format: "integer", value: "0"),
        ]
        properties.merge(flags("0x1", internal: false, visible: true)) { current, _ in current }
        properties.merge(flags("0x2", internal: false, visible: true)) { current, _ in current }
        properties.merge(flags("0x3", internal: true, visible: true)) { current, _ in current }
        properties.merge(flags("0x4", internal: false, visible: true)) { current, _ in current }
        properties.merge(flags("0x5", internal: false, visible: false)) { current, _ in current }
        properties.merge(flags("0x6", internal: true, visible: true)) { current, _ in current }
        properties.merge(flags("0x7", internal: false, visible: true)) { current, _ in current }
        properties.merge(flags("0x8", internal: true, visible: true)) { current, _ in current }
        builder.ingesting(response: response(properties: properties))
        return builder.build()
    }

    private static let imageBytes = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00])

    /// A UIKit capture with the class table filled in and one of each kind
    /// of value the cards read: scene `0xf1` → window `0x1` → root view
    /// `0x10` holding a button `0x11` (a `MyButton`, the view of
    /// `MyViewController`), labels `0x12` / `0x16` (the second with nil
    /// text), image views `0x13` / `0x14` (the second with no image), a stack
    /// view `0x15`, and a layout guide `0x30`; constraints `0xd1`–`0xd5`.
    private static func uiKitCardsFixture() -> XcodeViewHierarchyObjectGraph {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: response(
            groups: [
                group("com.apple.UIKit.UIApplication", objects: [
                    object("0xa0", className: "UIApplication", additionalGroups: [
                        group("com.apple.UIKit.UIWindow", objects: [reference("0x1")]),
                    ]),
                ]),
                group("com.apple.UIKit.UIScene", objects: [
                    object("0xf1", className: "UIWindowScene", additionalGroups: [
                        group("com.apple.UIKit.UIWindow", objects: [reference("0x1")]),
                    ]),
                ]),
                group("com.apple.UIKit.UIWindow", objects: [
                    object(
                        "0x1", className: "UIWindow",
                        childGroup: group("com.apple.UIKit.UIView", objects: [
                            object(
                                "0x10", className: "UIView",
                                childGroup: group("com.apple.UIKit.UIView", objects: [
                                    object("0x11", className: "MyButton", additionalGroups: [
                                        group("com.apple.UIKit.UIViewController", objects: [
                                            object("0xc1", className: "MyViewController"),
                                        ]),
                                        group("com.apple.QuartzCore.CALayer", objects: [object("0x21", className: "CALayer")]),
                                    ]),
                                    object("0x12", className: "UILabel"),
                                    object("0x13", className: "UIImageView"),
                                    object("0x14", className: "UIImageView"),
                                    object("0x15", className: "UIStackView"),
                                    object("0x16", className: "UILabel"),
                                ]),
                                additionalGroups: [
                                    group("com.apple.UIKit.UILayoutGuide", objects: [
                                        object("0x30", className: "UILayoutGuide"),
                                    ]),
                                ]
                            ),
                        ]),
                        additionalGroups: [
                            group("com.apple.UIKit.UIScene", objects: [reference("0xf1")]),
                            group("com.apple.UIKit.UIViewController", objects: [reference("0xc1")]),
                        ]
                    ),
                ]),
                group("com.apple.UIKit.NSLayoutConstraint", objects: [
                    constraint("0xd1", first: ("0x11", "MyButton", 7), relation: 0, second: nil, constant: "100", active: true),
                    constraint("0xd2", first: ("0x11", "MyButton", 3), relation: 1, second: ("0x10", "UIView", 3), constant: "8", active: true),
                    constraint("0xd3", first: ("0x11", "MyButton", 8), relation: 0, second: nil, constant: "50", active: false),
                    constraint("0xd4", first: ("0x30", "UILayoutGuide", 5), relation: 0, second: ("0x11", "MyButton", 5), constant: "0", active: true, identifier: "guide-leading"),
                    constraint("0xd5", first: ("0x14", "UIImageView", 7), relation: 0, second: nil, constant: "40", active: true),
                ]),
                group("com.apple.UIKit.UIScreen", objects: [object("0xe0", className: "UIScreen")]),
            ],
            classInformation: [
                classNode("NSObject", [
                    classNode("UIResponder", [
                        classNode("UIView", [
                            classNode("UIWindow"),
                            classNode("UIControl", [classNode("UIButton", [classNode("MyButton")])]),
                            classNode("UILabel"), classNode("UIImageView"), classNode("UIStackView"),
                        ]),
                        classNode("UIViewController", [classNode("MyViewController")]),
                        classNode("UIScene", [classNode("UIWindowScene")]),
                    ]),
                    classNode("UILayoutGuide"), classNode("NSLayoutConstraint"), classNode("UIScreen"), classNode("CALayer"),
                ]),
            ]
        ))
        builder.ingesting(response: response(properties: [
            "0xa0.keyWindow": propertyDescription(name: "keyWindow", format: "public.plain-text", value: "0x1"),
            "0xf1.title": propertyDescription(name: "title", format: "public.plain-text", value: "Main"),
            "0xf1.activationState": propertyDescription(name: "activationState", format: "integer", value: "0"),
            "0xf1.screen": propertyDescription(name: "screen", format: "objectInfo", value: objectReference("UIScreen", "0xe0")),
            "0xe0.bounds": propertyDescription(name: "bounds", format: "CGf, CGf, CGf, CGf", value: ["0", "0", "402", "874"]),
            "0xe0.scale": propertyDescription(name: "scale", format: "CGf", value: "3"),
            "0x1.internal": propertyDescription(name: "internal", format: "b", value: "0"),
            "0x1.visible": propertyDescription(name: "visible", format: "b", value: "1"),

            "0x11.contentEdgeInsets": propertyDescription(name: "contentEdgeInsets", format: "CGf, CGf, CGf, CGf", value: ["1", "2", "3", "4"]),
            "0x11.enabled": propertyDescription(name: "enabled", format: "b", value: "1"),
            "0x11.contentHuggingPriorityHorizontal": propertyDescription(name: "contentHuggingPriorityHorizontal", format: "f", value: "250"),
            "0x11.horizontalAffectingConstraints": propertyDescription(name: "horizontalAffectingConstraints", format: "public.plain-text", value: "0xd1, 0xd9"),
            "0x21.masksToBounds": propertyDescription(name: "masksToBounds", format: "b", value: "1"),

            "0x12.frame": propertyDescription(name: "frame", format: "CGf, CGf, CGf, CGf", value: ["0", "0", "120", "20"]),
            "0x12.text": propertyDescription(name: "text", format: "public.plain-text", value: "Hello"),
            "0x12.font": propertyDescription(name: "font", format: "font", value: font(name: ".SFUI-Regular", size: "17")),
            "0x12.textColor": propertyDescription(name: "textColor", format: "color", value: grayColor(["1", "0.5"])),
            "0x12.numberOfLines": propertyDescription(name: "numberOfLines", format: "integer", value: "2"),
            "0x12.textAlignment": propertyDescription(name: "textAlignment", format: "integer", value: "1"),
            "0x12.hidden": propertyDescription(name: "hidden", format: "b", value: "0"),
            "0x12.contentHuggingPriorityHorizontal": propertyDescription(name: "contentHuggingPriorityHorizontal", format: "f", value: "250"),
            "0x16.text": valuelessPropertyDescription(name: "text", format: "public.plain-text"),

            "0x13.image": propertyDescription(name: "image", format: "image", value: image(imageBytes, name: "star.fill")),
            "0x13.contentMode": propertyDescription(name: "contentMode", format: "integer", value: "1"),
            "0x14.image": valuelessPropertyDescription(name: "image", format: "public.png"),

            "0x15.axis": propertyDescription(name: "axis", format: "integer", value: "1"),
            "0x15.spacing": propertyDescription(name: "spacing", format: "CGf", value: "8"),
        ]))
        return builder.build()
    }

    /// An AppKit capture: panel `0x1` (key, owned by `MyWindowController`
    /// `0xc1`, delegate `MyDelegate`) → content view `0x10` → button `0x11`
    /// with cell `0x40` and text field `0x12` with cell `0x41`.
    private static func appKitCardsFixture() -> XcodeViewHierarchyObjectGraph {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: response(
            groups: [
                group("com.apple.AppKit.NSApplication", objects: [
                    object("0xa0", className: "NSApplication", additionalGroups: [
                        group("com.apple.AppKit.NSWindow", objects: [reference("0x1")]),
                    ]),
                ]),
                group("com.apple.AppKit.NSWindowController", objects: [
                    object("0xc1", className: "MyWindowController", additionalGroups: [
                        group("com.apple.AppKit.NSWindow", objects: [reference("0x1")]),
                    ]),
                ]),
                group("com.apple.AppKit.NSWindow", objects: [
                    object("0x1", className: "NSPanel", additionalGroups: [
                        group("com.apple.AppKit.NSView", objects: [reference("0x10")]),
                        group("com.apple.AppKit.NSWindowController", objects: [reference("0xc1")]),
                    ]),
                ]),
                group("com.apple.AppKit.NSView", objects: [
                    object(
                        "0x10", className: "NSView",
                        childGroup: group("com.apple.AppKit.NSView", objects: [
                            object("0x11", className: "NSButton", additionalGroups: [
                                group("com.apple.AppKit.NSCell", objects: [object("0x40", className: "NSButtonCell")]),
                            ]),
                            object("0x12", className: "NSTextField", additionalGroups: [
                                group("com.apple.AppKit.NSCell", objects: [object("0x41", className: "NSTextFieldCell")]),
                            ]),
                        ])
                    ),
                ]),
            ],
            classInformation: [
                classNode("NSObject", [
                    classNode("NSResponder", [
                        classNode("NSView", [classNode("NSControl", [classNode("NSButton"), classNode("NSTextField")])]),
                        classNode("NSWindow", [classNode("NSPanel")]),
                        classNode("NSWindowController", [classNode("MyWindowController")]),
                    ]),
                    classNode("NSCell", [classNode("NSActionCell", [classNode("NSButtonCell")]), classNode("NSTextFieldCell")]),
                    classNode("MyDelegate"),
                ]),
            ]
        ))
        builder.ingesting(response: response(properties: [
            "0xa0.keyWindow": propertyDescription(name: "keyWindow", format: "public.plain-text", value: "0x1"),
            "0x1.title": propertyDescription(name: "title", format: "public.plain-text", value: "Inspector"),
            "0x1.isKeyWindow": propertyDescription(name: "isKeyWindow", format: "b", value: "1"),
            // uinteger is hexadecimal: f = titled | closable | miniaturizable | resizable.
            "0x1.styleMask": propertyDescription(name: "styleMask", format: "uinteger", value: "f"),
            // 80 = fullScreenPrimary (1 << 7).
            "0x1.collectionBehavior": propertyDescription(name: "collectionBehavior", format: "uinteger", value: "80"),
            "0x1.frame": propertyDescription(name: "frame", format: "CGf, CGf, CGf, CGf", value: ["10", "20", "300", "200"]),
            "0x1.delegate": propertyDescription(name: "delegate", format: "objectInfo", value: objectReference("MyDelegate", "0xe1")),

            "0x11.title": propertyDescription(name: "title", format: "public.plain-text", value: "OK"),
            "0x11.font": propertyDescription(name: "font", format: "font", value: font(name: ".SFNS-Regular", size: "13")),
            "0x11.alignment": propertyDescription(name: "alignment", format: "uinteger", value: "2"),
            "0x40.bezelStyle": propertyDescription(name: "bezelStyle", format: "uinteger", value: "1"),
            "0x40._buttonType": propertyDescription(name: "_buttonType", format: "uinteger", value: "7"),
            "0x40.bordered": propertyDescription(name: "bordered", format: "b", value: "1"),
            "0x40.title": propertyDescription(name: "title", format: "public.plain-text", value: "OK"),

            "0x12.editable": propertyDescription(name: "editable", format: "b", value: "1"),
            "0x41.placeholderString": propertyDescription(name: "placeholderString", format: "public.plain-text", value: "Search"),
        ]))
        return builder.build()
    }

    // MARK: - Card helpers

    private static func item(withObjectIdentifier identifier: UInt, in file: HierarchyFile) -> DisplayItem {
        var found: DisplayItem?
        walk(file.hierarchyInfo?.displayItems ?? []) { item in
            if found == nil, displayedObjectIdentifier(item) == identifier {
                found = item
            }
        }
        guard let found else { fail("no node with object identifier 0x\(String(identifier, radix: 16))") }
        return found
    }

    private static func attribute(_ identifier: String, of item: DisplayItem?) -> InspectedAttribute? {
        for group in item?.attributesGroupList ?? [] {
            for section in group.attrSections ?? [] {
                if let attribute = section.attributes?.first(where: { $0.identifier == identifier }) {
                    return attribute
                }
            }
        }
        return nil
    }

    private static func expectAttribute(
        _ identifier: String,
        of item: DisplayItem?,
        type attrType: LookinAttrType,
        equals expected: NSObject
    ) {
        guard let attribute = attribute(identifier, of: item) else { fail("\(identifier) is missing") }
        expect(attribute.attrType == attrType, "\(identifier) has type \(attribute.attrType.rawValue), expected \(attrType.rawValue)")
        expect((attribute.value as? NSObject) == expected,
               "\(identifier) is \(String(describing: attribute.value)), expected \(expected)")
    }

    private static func groupIdentifiers(of item: DisplayItem?) -> [String] {
        (item?.attributesGroupList ?? []).compactMap(\.identifier)
    }

    private static func classChains(of item: DisplayItem?) -> [[String]]? {
        attribute(LookinAttr_Class_Class_Class, of: item)?.value as? [[String]]
    }

    private static func relations(of item: DisplayItem?) -> [String]? {
        attribute(LookinAttr_Relation_Relation_Relation, of: item)?.value as? [String]
    }

    /// The object a row stands for, whichever slot its kind rides.
    private static func displayedObjectIdentifier(_ item: DisplayItem) -> UInt {
        (item.kindObject ?? item.windowObject ?? item.viewObject ?? item.layerObject)?.oid ?? 0
    }

    /// An AppKit capture: one window whose content view owns a layer carrying
    /// background and border colours and a layout guide, plus a control
    /// subview with a cell. Every node kind the converter emits appears once.
    private static func convertedFixture() -> HierarchyFile {
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: response(groups: [
            group("com.apple.AppKit.NSWindow", objects: [
                object("0x1", className: "NSWindow", additionalGroups: [
                    group("com.apple.AppKit.NSView", objects: [reference("0x10")]),
                ]),
            ]),
            group("com.apple.AppKit.NSView", objects: [
                object(
                    "0x10", className: "NSView",
                    childGroup: group("com.apple.AppKit.NSView", objects: [
                        object("0x11", className: "NSButton", additionalGroups: [
                            group("com.apple.AppKit.NSCell", objects: [
                                object("0x40", className: "NSButtonCell"),
                            ]),
                        ]),
                    ]),
                    additionalGroups: [
                        group("com.apple.QuartzCore.CALayer", objects: [object("0x20", className: "CALayer")]),
                        group("com.apple.AppKit.NSLayoutGuide", objects: [
                            object("0x30", className: "NSLayoutGuide"),
                        ]),
                    ]
                ),
            ]),
        ]))
        builder.ingesting(response: response(properties: [
            "0x20.backgroundColor": propertyDescription(
                name: "backgroundColor", format: "color",
                value: color(["0x1p-1", "0x1p-2", "0x1p+0", "0x1p+0"])
            ),
            "0x20.borderColor": propertyDescription(
                name: "borderColor", format: "color",
                value: color(["0x0p+0", "0x0p+0", "0x0p+0", "0x1p-1"])
            ),
        ]))

        return convert(builder.build())
    }

    /// Runs the converter over a graph with no recovered pixels.
    private static func convert(_ graph: XcodeViewHierarchyObjectGraph) -> HierarchyFile {
        convert(
            graph,
            screenshots: XcodeViewHierarchyScreenshots(
                soloByObjectIdentifier: [:], groupByObjectIdentifier: [:], failedArchiveIdentifiers: []
            ),
            showingBackingLayers: false
        )
    }

    private static func convert(
        _ graph: XcodeViewHierarchyObjectGraph,
        screenshots: XcodeViewHierarchyScreenshots,
        showingBackingLayers: Bool
    ) -> HierarchyFile {
        let bundle = XcodeViewHierarchyBundle(
            metadata: XcodeViewHierarchyBundleMetadata(
                documentVersion: "1", runnableDisplayName: "Fixture", runnableProcessIdentifier: 1
            ),
            graph: graph,
            failedResponseCount: 0,
            succeededResponseCount: 2
        )
        do {
            return try XcodeViewHierarchyConverter.makingHierarchyFile(
                from: bundle, screenshots: screenshots, showingBackingLayers: showingBackingLayers
            )
        } catch {
            fail("conversion failed: \(error)")
        }
    }

    private static func response(
        groups: [[String: Any]] = [],
        properties: [String: Any] = [:],
        classInformation: [[String: Any]] = []
    ) -> [String: Any] {
        var topLevelGroups: [String: Any] = [:]
        for group in groups {
            topLevelGroups[group["groupingID"] as? String ?? ""] = group
        }
        return [
            "version": NSNumber(value: 2),
            "topLevelGroups": topLevelGroups,
            "topLevelPropertyDescriptions": properties,
            "classInformation": classInformation,
        ]
    }

    /// One entry of the capture's class table, nested by subclass.
    private static func classNode(_ className: String, _ subclasses: [[String: Any]] = []) -> [String: Any] {
        ["className": className, "subclasses": subclasses]
    }

    /// A constraint object with its properties inline, as the capture writes them.
    private static func constraint(
        _ objectIdentifier: String,
        first: (identifier: String, className: String, attribute: Int),
        relation: Int,
        second: (identifier: String, className: String, attribute: Int)?,
        constant: String,
        active: Bool,
        identifier: String? = nil
    ) -> [String: Any] {
        var properties: [[String: Any]] = [
            propertyDescription(name: "firstItem", format: "objectInfo", value: objectReference(first.className, first.identifier)),
            propertyDescription(name: "firstAttribute", format: "integer", value: String(first.attribute)),
            propertyDescription(name: "relation", format: "integer", value: String(relation)),
            propertyDescription(name: "secondAttribute", format: "integer", value: String(second?.attribute ?? 0)),
            propertyDescription(name: "constant", format: "CGf", value: constant),
            propertyDescription(name: "multiplier", format: "f", value: "1"),
            propertyDescription(name: "priority", format: "f", value: "1000"),
            propertyDescription(name: "active", format: "b", value: active ? "1" : "0"),
        ]
        if let second {
            properties.append(propertyDescription(name: "secondItem", format: "objectInfo", value: objectReference(second.className, second.identifier)))
        } else {
            properties.append(valuelessPropertyDescription(name: "secondItem", format: "objectInfo"))
        }
        if let identifier {
            properties.append(propertyDescription(name: "identifier", format: "public.plain-text", value: identifier))
        }
        var object = object(objectIdentifier, className: "NSLayoutConstraint")
        object["properties"] = properties
        return object
    }

    private static func objectReference(_ className: String, _ objectIdentifier: String) -> [String: Any] {
        ["className": className, "memoryAddress": objectIdentifier]
    }

    /// A property whose fetch succeeded with no value: the captured nil.
    private static func valuelessPropertyDescription(name: String, format: String) -> [String: Any] {
        ["propertyName": name, "propertyFormat": format, "fetchStatus": NSNumber(value: 4)]
    }

    private static func font(name: String, size: String) -> [String: Any] {
        ["fontName": name, "familyName": ".AppleSystemUIFont", "pointSize": size]
    }

    private static func grayColor(_ hexFloatComponents: [String]) -> [String: Any] {
        [
            "colorSpaceName": "kCGColorSpaceExtendedGray",
            "componentValuesFormat": "CGf, CGf",
            "componentValues": hexFloatComponents,
        ]
    }

    private static func image(_ data: Data, name: String) -> [String: Any] {
        [
            "imageData": data.base64EncodedString(),
            "metadata": ["imageName": name, "width": NSNumber(value: 10), "height": NSNumber(value: 10)],
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

    /// The capture's colour structure: sRGB components as C99 hex floats.
    private static func color(_ hexFloatComponents: [String]) -> [String: Any] {
        [
            "colorSpaceName": "kCGColorSpaceSRGB",
            "componentValuesFormat": "CGf, CGf, CGf, CGf",
            "componentValues": hexFloatComponents,
        ]
    }

    // MARK: - Helpers

    private static func walk(_ items: [DisplayItem], _ visit: (DisplayItem) -> Void) {
        for item in items {
            visit(item)
            walk(item.subitems ?? [], visit)
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
