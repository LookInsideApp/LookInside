// XcodeViewHierarchyAttributeCatalog.swift
//
// Which dashboard rows an imported capture can fill, and where in the capture
// each one's value lives.
//
// The dashboard's cards are described by `DashboardBlueprint`: groups,
// their sections, the attributes in each, and per attribute the type, the
// enum list and whether a nil value hides the row. A live session walks that
// blueprint on the server and reads each attribute through its getter. An
// imported capture has no getters — it has property records keyed by the
// names Xcode's capture agent chose, which are not Lookin's — so this file is
// the translation: for each attribute identifier, the capture property (or
// properties, tried in order) to read, on which associated object, and how
// to turn its decoded value into the attribute value the card expects.
//
// The group and section order is the blueprint's, restated here because the
// blueprint compiled into the macOS host lists only the AppKit groups; the
// UIKit half exists there for titles and enums but not for ordering. Keep
// this in the blueprint's order so an imported UIKit capture shows its cards
// in the same sequence a live iOS session does.
//
// Rows with no capture counterpart are simply not listed: an image view's
// name comes from the image's metadata, but a scroll view's content offset
// is not captured at all, so that row stays empty rather than wrong.

import AppKit
import Foundation

struct XcodeViewHierarchyAttributeSpecification {
    /// Which object the property is read from.
    enum Source {
        /// The node itself.
        case node
        /// The node's backing layer.
        case layer
        /// The node first, then its layer — for properties both carry.
        case nodeThenLayer
        /// The layer first, then the node.
        case layerThenNode
        /// An AppKit control's cell, where AppKit keeps bezel style and the like.
        case cell
        /// The screen a scene's `screen` reference points at.
        case screen
    }

    /// How the decoded capture value becomes an attribute value.
    enum Kind {
        case bool
        /// An integer, emitted as an enum when the blueprint names an enum list.
        case integer
        case number
        case text
        case color
        case rect
        case point
        case size
        case insets
        case sizeWidth
        case sizeHeight
        case fontName
        case fontSize
        /// The image's name from its metadata, when the capture recorded one.
        case imageName
        /// The image's encoded bytes, for the open-in-Preview row.
        case imageData
        /// One flag of an option set, emitted as a bool.
        case maskBit(UInt64)
    }

    /// Any-of gate on the node's class chain; empty means no gate.
    let classNames: [String]
    let source: Source
    /// Candidate property names, tried in order; the first one present wins.
    let properties: [String]
    let kind: Kind

    init(_ classNames: [String], _ kind: Kind, _ properties: String..., source: Source = .node) {
        self.classNames = classNames
        self.kind = kind
        self.properties = properties
        self.source = source
    }
}

enum XcodeViewHierarchyAttributeCatalog {
    struct Section {
        let identifier: AttributesSection.Identifier
        let attributes: [InspectedAttribute.Identifier]
    }

    struct Group {
        let identifier: AttributesGroup.Identifier
        let sections: [Section]
    }

    // MARK: - Order

    /// The blueprint's order, both platforms, restricted to rows a capture can fill.
    static let groups: [Group] = [
        Group(identifier: .class, sections: [
            Section(identifier: .Class.class, attributes: [.Class.Class.class]),
        ]),
        Group(identifier: .relation, sections: [
            Section(identifier: .Relation.relation, attributes: [.Relation.Relation.relation]),
        ]),
        Group(identifier: .layout, sections: [
            Section(identifier: .Layout.frame, attributes: [.Layout.Frame.frame]),
            Section(identifier: .Layout.bounds, attributes: [.Layout.Bounds.bounds]),
            Section(identifier: .Layout.position, attributes: [.Layout.Position.position]),
            Section(identifier: .Layout.anchorPoint, attributes: [.Layout.AnchorPoint.anchorPoint]),
            Section(identifier: .Layout.coordinateSpace, attributes: [.Layout.CoordinateSpace.coordinateSpace]),
        ]),
        Group(identifier: .autoLayout, sections: [
            Section(identifier: .AutoLayout.constraints, attributes: [.AutoLayout.Constraints.constraints]),
            Section(identifier: .AutoLayout.hugging, attributes: [
                .AutoLayout.Hugging.horizontal, .AutoLayout.Hugging.vertical,
            ]),
            Section(identifier: .AutoLayout.resistance, attributes: [
                .AutoLayout.Resistance.horizontal, .AutoLayout.Resistance.vertical,
            ]),
        ]),
        Group(identifier: .viewLayer, sections: [
            Section(identifier: .ViewLayer.visibility, attributes: [
                .ViewLayer.Visibility.hidden, .ViewLayer.Visibility.opacity,
            ]),
            Section(identifier: .ViewLayer.interactionAndMasks, attributes: [
                .ViewLayer.InteractionAndMasks.interaction, .ViewLayer.InteractionAndMasks.masksToBounds,
            ]),
            Section(identifier: .ViewLayer.backgroundColor, attributes: [.ViewLayer.BackgroundColor.backgroundColor]),
            Section(identifier: .ViewLayer.border, attributes: [
                .ViewLayer.Border.color, .ViewLayer.Border.width,
            ]),
            Section(identifier: .ViewLayer.corner, attributes: [.ViewLayer.Corner.radius]),
            Section(identifier: .ViewLayer.shadow, attributes: [
                .ViewLayer.Shadow.color, .ViewLayer.Shadow.opacity, .ViewLayer.Shadow.radius,
                .ViewLayer.Shadow.offsetWidth, .ViewLayer.Shadow.offsetHeight,
            ]),
            Section(identifier: .ViewLayer.tag, attributes: [.ViewLayer.Tag.tag]),
            Section(identifier: .ViewLayer.contentMode, attributes: [.ViewLayer.ContentMode.mode]),
            Section(identifier: .ViewLayer.tintColor, attributes: [
                .ViewLayer.TintColor.color, .ViewLayer.TintColor.mode,
            ]),
        ]),

        // UIKit
        Group(identifier: .uiStackView, sections: [
            Section(identifier: .UIStackView.axis, attributes: [.UIStackView.Axis.axis]),
            Section(identifier: .UIStackView.distribution, attributes: [.UIStackView.Distribution.distribution]),
            Section(identifier: .UIStackView.alignment, attributes: [.UIStackView.Alignment.alignment]),
            Section(identifier: .UIStackView.spacing, attributes: [.UIStackView.Spacing.spacing]),
        ]),
        Group(identifier: .uiImageView, sections: [
            Section(identifier: .UIImageView.name, attributes: [.UIImageView.Name.name]),
            Section(identifier: .UIImageView.open, attributes: [.UIImageView.Open.open]),
        ]),
        Group(identifier: .uiLabel, sections: [
            Section(identifier: .UILabel.text, attributes: [.UILabel.Text.text]),
            Section(identifier: .UILabel.font, attributes: [.UILabel.Font.name, .UILabel.Font.size]),
            Section(identifier: .UILabel.numberOfLines, attributes: [.UILabel.NumberOfLines.numberOfLines]),
            Section(identifier: .UILabel.textColor, attributes: [.UILabel.TextColor.color]),
            Section(identifier: .UILabel.breakMode, attributes: [.UILabel.BreakMode.mode]),
            Section(identifier: .UILabel.alignment, attributes: [.UILabel.Alignment.alignment]),
            Section(identifier: .UILabel.canAdjustFont, attributes: [.UILabel.CanAdjustFont.canAdjustFont]),
        ]),
        Group(identifier: .uiControl, sections: [
            Section(identifier: .UIControl.enabledSelected, attributes: [
                .UIControl.EnabledSelected.enabled, .UIControl.EnabledSelected.selected,
            ]),
            Section(identifier: .UIControl.verAlignment, attributes: [.UIControl.VerAlignment.alignment]),
            Section(identifier: .UIControl.horAlignment, attributes: [.UIControl.HorAlignment.alignment]),
        ]),
        Group(identifier: .uiButton, sections: [
            Section(identifier: .UIButton.contentInsets, attributes: [.UIButton.ContentInsets.insets]),
            Section(identifier: .UIButton.titleInsets, attributes: [.UIButton.TitleInsets.insets]),
            Section(identifier: .UIButton.imageInsets, attributes: [.UIButton.ImageInsets.insets]),
        ]),
        Group(identifier: .uiScrollView, sections: [
            Section(identifier: .UIScrollView.showsIndicator, attributes: [
                .UIScrollView.ShowsIndicator.horizontal, .UIScrollView.ShowsIndicator.vertical,
            ]),
            Section(identifier: .UIScrollView.bounce, attributes: [
                .UIScrollView.Bounce.horizontal, .UIScrollView.Bounce.vertical,
            ]),
            Section(identifier: .UIScrollView.scrollPaging, attributes: [
                .UIScrollView.ScrollPaging.scrollEnabled, .UIScrollView.ScrollPaging.pagingEnabled,
            ]),
            Section(identifier: .UIScrollView.contentTouches, attributes: [
                .UIScrollView.ContentTouches.delay, .UIScrollView.ContentTouches.canCancel,
            ]),
            Section(identifier: .UIScrollView.zoom, attributes: [
                .UIScrollView.Zoom.bounce, .UIScrollView.Zoom.minScale, .UIScrollView.Zoom.maxScale,
            ]),
        ]),
        Group(identifier: .uiTableView, sections: [
            Section(identifier: .UITableView.style, attributes: [.UITableView.Style.style]),
            Section(identifier: .UITableView.sectionsNumber, attributes: [.UITableView.SectionsNumber.number]),
            Section(identifier: .UITableView.separatorStyle, attributes: [.UITableView.SeparatorStyle.style]),
            Section(identifier: .UITableView.separatorColor, attributes: [.UITableView.SeparatorColor.color]),
            Section(identifier: .UITableView.separatorInset, attributes: [.UITableView.SeparatorInset.inset]),
        ]),
        Group(identifier: .uiTextView, sections: [
            Section(identifier: .UITextView.basic, attributes: [
                .UITextView.Basic.editable, .UITextView.Basic.selectable,
            ]),
            Section(identifier: .UITextView.text, attributes: [.UITextView.Text.text]),
            Section(identifier: .UITextView.font, attributes: [.UITextView.Font.name, .UITextView.Font.size]),
            Section(identifier: .UITextView.textColor, attributes: [.UITextView.TextColor.color]),
            Section(identifier: .UITextView.alignment, attributes: [.UITextView.Alignment.alignment]),
        ]),
        Group(identifier: .uiTextField, sections: [
            Section(identifier: .UITextField.text, attributes: [.UITextField.Text.text]),
            Section(identifier: .UITextField.placeholder, attributes: [.UITextField.Placeholder.placeholder]),
            Section(identifier: .UITextField.font, attributes: [.UITextField.Font.name, .UITextField.Font.size]),
            Section(identifier: .UITextField.textColor, attributes: [.UITextField.TextColor.color]),
            Section(identifier: .UITextField.alignment, attributes: [.UITextField.Alignment.alignment]),
            Section(identifier: .UITextField.clears, attributes: [.UITextField.Clears.clearsOnBeginEditing]),
            Section(identifier: .UITextField.canAdjustFont, attributes: [
                .UITextField.CanAdjustFont.canAdjustFont, .UITextField.CanAdjustFont.minSize,
            ]),
            Section(identifier: .UITextField.clearButtonMode, attributes: [.UITextField.ClearButtonMode.mode]),
        ]),
        Group(identifier: .uiWindowScene, sections: [
            Section(identifier: .UIWindowScene.state, attributes: [.UIWindowScene.State.activationState]),
            Section(identifier: .UIWindowScene.title, attributes: [
                .UIWindowScene.Title.title, .UIWindowScene.Title.subtitle,
            ]),
            Section(identifier: .UIWindowScene.orientation, attributes: [.UIWindowScene.Orientation.interfaceOrientation]),
            Section(identifier: .UIWindowScene.windows, attributes: [
                .UIWindowScene.Windows.windowCount, .UIWindowScene.Windows.keyWindowClassName,
            ]),
            Section(identifier: .UIWindowScene.screen, attributes: [
                .UIWindowScene.Screen.screenBounds, .UIWindowScene.Screen.screenScale,
            ]),
            Section(identifier: .UIWindowScene.traits, attributes: [
                .UIWindowScene.Traits.userInterfaceStyle, .UIWindowScene.Traits.horizontalSizeClass,
                .UIWindowScene.Traits.verticalSizeClass, .UIWindowScene.Traits.layoutDirection,
            ]),
        ]),
        Group(identifier: .uiTraitCollection, sections: [
            Section(identifier: .UITraitCollection.appearance, attributes: [.UITraitCollection.Appearance.userInterfaceStyle]),
            Section(identifier: .UITraitCollection.sizeClass, attributes: [
                .UITraitCollection.SizeClass.horizontalSizeClass, .UITraitCollection.SizeClass.verticalSizeClass,
            ]),
            Section(identifier: .UITraitCollection.layout, attributes: [.UITraitCollection.Layout.layoutDirection]),
        ]),

        // AppKit
        Group(identifier: .nsImageView, sections: [
            Section(identifier: .NSImageView.name, attributes: [.NSImageView.Name.name]),
            Section(identifier: .NSImageView.open, attributes: [.NSImageView.Open.open]),
            Section(identifier: .NSImageView.scaling, attributes: [
                .NSImageView.Scaling.imageScaling, .NSImageView.Scaling.imageAlignment,
                .NSImageView.Scaling.imageFrameStyle,
            ]),
            Section(identifier: .NSImageView.behavior, attributes: [
                .NSImageView.Behavior.animates, .NSImageView.Behavior.editable,
            ]),
            Section(identifier: .NSImageView.contentTintColor, attributes: [.NSImageView.ContentTintColor.contentTintColor]),
        ]),
        Group(identifier: .nsControl, sections: [
            Section(identifier: .NSControl.state, attributes: [
                .NSControl.State.enabled, .NSControl.State.highlighted, .NSControl.State.continuous,
            ]),
            Section(identifier: .NSControl.controlSize, attributes: [.NSControl.ControlSize.size]),
            Section(identifier: .NSControl.font, attributes: [.NSControl.Font.name, .NSControl.Font.size]),
            Section(identifier: .NSControl.alignment, attributes: [.NSControl.Alignment.alignment]),
            Section(identifier: .NSControl.miscellaneous, attributes: [
                .NSControl.Miscellaneous.writingDirection, .NSControl.Miscellaneous.usesSingleLineMode,
                .NSControl.Miscellaneous.allowsExpansionToolTips,
            ]),
            Section(identifier: .NSControl.value, attributes: [.NSControl.Value.doubleValue]),
        ]),
        Group(identifier: .nsButton, sections: [
            Section(identifier: .NSButton.buttonType, attributes: [.NSButton.ButtonType.buttonType]),
            Section(identifier: .NSButton.bezelStyle, attributes: [.NSButton.BezelStyle.bezelStyle]),
            Section(identifier: .NSButton.title, attributes: [
                .NSButton.Title.title, .NSButton.Title.alernateTitle,
            ]),
            Section(identifier: .NSButton.bordered, attributes: [
                .NSButton.Bordered.bordered, .NSButton.Transparent.transparent, .NSButton.Miscellaneous.springLoaded,
            ]),
            Section(identifier: .NSButton.bezelColor, attributes: [.NSButton.ContentTintColor.contentTintColor]),
        ]),
        Group(identifier: .nsScrollView, sections: [
            Section(identifier: .NSScrollView.borderType, attributes: [.NSScrollView.BorderType.borderType]),
            Section(identifier: .NSScrollView.scroller, attributes: [
                .NSScrollView.Scroller.horizontal, .NSScrollView.Scroller.vertical,
                .NSScrollView.Scroller.autohidesScrollers, .NSScrollView.Scroller.scrollerKnobStyle,
            ]),
            Section(identifier: .NSScrollView.lineScroll, attributes: [
                .NSScrollView.LineScroll.horizontal, .NSScrollView.LineScroll.vertical,
            ]),
            Section(identifier: .NSScrollView.pageScroll, attributes: [
                .NSScrollView.PageScroll.horizontal, .NSScrollView.PageScroll.vertical,
            ]),
            Section(identifier: .NSScrollView.scrollElasiticity, attributes: [
                .NSScrollView.ScrollElasiticity.horizontal, .NSScrollView.ScrollElasiticity.vertical,
            ]),
            Section(identifier: .NSScrollView.miscellaneous, attributes: [.NSScrollView.Miscellaneous.usesPredominantAxisScrolling]),
            Section(identifier: .NSScrollView.magnification, attributes: [
                .NSScrollView.Magnification.allowsMagnification, .NSScrollView.Magnification.maximum,
                .NSScrollView.Magnification.minimum,
            ]),
        ]),
        Group(identifier: .nsTableView, sections: [
            Section(identifier: .NSTableView.rowHeight, attributes: [.NSTableView.RowHeight.rowHeight]),
            Section(identifier: .NSTableView.intercellSpacing, attributes: [.NSTableView.IntercellSpacing.intercellSpacing]),
            Section(identifier: .NSTableView.columnAutoresizingStyle, attributes: [.NSTableView.ColumnAutoresizingStyle.columnAutoresizingStyle]),
            Section(identifier: .NSTableView.gridStyleMask, attributes: [.NSTableView.GridStyleMask.gridStyleMask]),
            Section(identifier: .NSTableView.selectionHighlightStyle, attributes: [.NSTableView.SelectionHighlightStyle.selectionHighlightStyle]),
            Section(identifier: .NSTableView.gridColor, attributes: [.NSTableView.GridColor.gridColor]),
            Section(identifier: .NSTableView.rowSizeStyle, attributes: [.NSTableView.RowSizeStyle.rowSizeStyle]),
            Section(identifier: .NSTableView.numberOfColumns, attributes: [.NSTableView.NumberOfColumns.numberOfColumns]),
            Section(identifier: .NSTableView.useAlternatingRowBackgroundColors, attributes: [.NSTableView.UseAlternatingRowBackgroundColors.useAlternatingRowBackgroundColors]),
            Section(identifier: .NSTableView.allowsColumnReordering, attributes: [.NSTableView.AllowsColumnReordering.allowsColumnReordering]),
            Section(identifier: .NSTableView.allowsColumnResizing, attributes: [.NSTableView.AllowsColumnResizing.allowsColumnResizing]),
            Section(identifier: .NSTableView.allowsMultipleSelection, attributes: [.NSTableView.AllowsMultipleSelection.allowsMultipleSelection]),
            Section(identifier: .NSTableView.allowsEmptySelection, attributes: [.NSTableView.AllowsEmptySelection.allowsEmptySelection]),
            Section(identifier: .NSTableView.allowsColumnSelection, attributes: [.NSTableView.AllowsColumnSelection.allowsColumnSelection]),
            Section(identifier: .NSTableView.allowsTypeSelect, attributes: [.NSTableView.AllowsTypeSelect.allowsTypeSelect]),
            Section(identifier: .NSTableView.autosave, attributes: [
                .NSTableView.AutosaveName.autosaveName, .NSTableView.AutosaveTableColumns.autosaveTableColumns,
            ]),
            Section(identifier: .NSTableView.floatsGroupRows, attributes: [.NSTableView.FloatsGroupRows.floatsGroupRows]),
        ]),
        Group(identifier: .nsTextView, sections: [
            Section(identifier: .NSTextView.basic, attributes: [
                .NSTextView.Basic.editable, .NSTextView.Basic.selectable, .NSTextView.Basic.richText,
                .NSTextView.Basic.fieldEditor, .NSTextView.Basic.importsGraphics,
            ]),
            Section(identifier: .NSTextView.string, attributes: [.NSTextView.String.string]),
            Section(identifier: .NSTextView.textColor, attributes: [.NSTextView.TextColor.color]),
            Section(identifier: .NSTextView.baseWritingDirection, attributes: [.NSTextView.BaseWritingDirection.baseWritingDirection]),
        ]),
        Group(identifier: .nsTextField, sections: [
            Section(identifier: .NSTextField.bordered, attributes: [
                .NSTextField.Bordered.bordered, .NSTextField.Bezeled.bezeled, .NSTextField.Editable.editable,
                .NSTextField.DrawsBackground.drawsBackground,
                .NSTextField.AllowsEditingTextAttributes.allowsEditingTextAttributes,
            ]),
            Section(identifier: .NSTextField.textColor, attributes: [
                .NSTextField.TextColor.color, .NSTextField.BackgroundColor.color,
            ]),
            Section(identifier: .NSTextField.placeholder, attributes: [.NSTextField.Placeholder.placeholder]),
        ]),
        Group(identifier: .nsVisualEffectView, sections: [
            Section(identifier: .NSVisualEffectView.material, attributes: [.NSVisualEffectView.Material.material]),
            Section(identifier: .NSVisualEffectView.interiorBackgroundStyle, attributes: [.NSVisualEffectView.InteriorBackgroundStyle.interiorBackgroundStyle]),
            Section(identifier: .NSVisualEffectView.blendingMode, attributes: [.NSVisualEffectView.BlendingMode.blendingMode]),
            Section(identifier: .NSVisualEffectView.state, attributes: [.NSVisualEffectView.State.state]),
            Section(identifier: .NSVisualEffectView.emphasized, attributes: [.NSVisualEffectView.Emphasized.emphasized]),
        ]),
        Group(identifier: .nsStackView, sections: [
            Section(identifier: .NSStackView.orientation, attributes: [.NSStackView.Orientation.orientation]),
            Section(identifier: .NSStackView.edgeInsets, attributes: [.NSStackView.EdgeInsets.edgeInsets]),
            Section(identifier: .NSStackView.distribution, attributes: [.NSStackView.Distribution.distribution]),
            Section(identifier: .NSStackView.alignment, attributes: [.NSStackView.Alignment.alignment]),
            Section(identifier: .NSStackView.spacing, attributes: [.NSStackView.Spacing.spacing]),
        ]),
        Group(identifier: .nsWindow, sections: [
            Section(identifier: .NSWindow.title, attributes: [.NSWindow.Title.title]),
            Section(identifier: .NSWindow.state, attributes: [
                .NSWindow.State.keyWindow, .NSWindow.State.mainWindow, .NSWindow.State.visible,
            ]),
            Section(identifier: .NSWindow.style, attributes: [
                .NSWindow.Style.titled, .NSWindow.Style.closable, .NSWindow.Style.miniaturizable,
                .NSWindow.Style.resizable, .NSWindow.Style.unifiedTitleAndToolbar, .NSWindow.Style.fullScreen,
                .NSWindow.Style.fullSizeContentView, .NSWindow.Style.utilityWindow, .NSWindow.Style.docModalWindow,
                .NSWindow.Style.nonactivatingPanel, .NSWindow.Style.hudWindow,
            ]),
            Section(identifier: .NSWindow.collectionBehavior, attributes: [
                .NSWindow.CollectionBehavior.canJoinAllSpaces, .NSWindow.CollectionBehavior.moveToActiveSpace,
                .NSWindow.CollectionBehavior.participatesInCycle, .NSWindow.CollectionBehavior.ignoresCycle,
                .NSWindow.CollectionBehavior.fullScreenPrimary, .NSWindow.CollectionBehavior.fullScreenAuxiliary,
                .NSWindow.CollectionBehavior.fullScreenNone, .NSWindow.CollectionBehavior.fullScreenAllowsTiling,
                .NSWindow.CollectionBehavior.fullScreenDisallowsTiling,
            ]),
            Section(identifier: .NSWindow.appearance, attributes: [
                .NSWindow.Appearance.alphaValue, .NSWindow.Appearance.opaque, .NSWindow.Appearance.hasShadow,
            ]),
            Section(identifier: .NSWindow.behavior, attributes: [.NSWindow.Behavior.hidesOnDeactivate]),
            Section(identifier: .NSWindow.animationBehavior, attributes: [.NSWindow.Behavior.animationBehavior]),
            Section(identifier: .NSWindow.information, attributes: [.NSWindow.Information.backingScaleFactor]),
        ]),
        Group(identifier: .nsSlider, sections: [
            Section(identifier: .NSSlider.sliderType, attributes: [.NSSlider.SliderType.sliderType]),
            Section(identifier: .NSSlider.range, attributes: [.NSSlider.Range.minValue, .NSSlider.Range.maxValue]),
            Section(identifier: .NSSlider.tickMark, attributes: [
                .NSSlider.TickMark.numberOfTickMarks, .NSSlider.TickMark.tickMarkPosition,
                .NSSlider.TickMark.allowsTickMarkValuesOnly,
            ]),
        ]),
        Group(identifier: .nsProgressIndicator, sections: [
            Section(identifier: .NSProgressIndicator.style, attributes: [.NSProgressIndicator.Style.style]),
            Section(identifier: .NSProgressIndicator.range, attributes: [
                .NSProgressIndicator.Range.minValue, .NSProgressIndicator.Range.maxValue,
                .NSProgressIndicator.Range.doubleValue,
            ]),
            Section(identifier: .NSProgressIndicator.miscellaneous, attributes: [
                .NSProgressIndicator.Miscellaneous.indeterminate, .NSProgressIndicator.Miscellaneous.bezeled,
                .NSProgressIndicator.Miscellaneous.displayedWhenStopped,
            ]),
        ]),
        Group(identifier: .nsSegmentedControl, sections: [
            Section(identifier: .NSSegmentedControl.segmentCount, attributes: [.NSSegmentedControl.SegmentCount.segmentCount]),
            Section(identifier: .NSSegmentedControl.selection, attributes: [.NSSegmentedControl.Selection.selectedSegment]),
            Section(identifier: .NSSegmentedControl.style, attributes: [
                .NSSegmentedControl.Style.segmentStyle, .NSSegmentedControl.Style.trackingMode,
            ]),
        ]),
        Group(identifier: .nsPopUpButton, sections: [
            Section(identifier: .NSPopUpButton.behavior, attributes: [.NSPopUpButton.Behavior.preferredEdge]),
        ]),
        Group(identifier: .nsComboBox, sections: [
            Section(identifier: .NSComboBox.items, attributes: [.NSComboBox.Items.numberOfVisibleItems]),
            Section(identifier: .NSComboBox.miscellaneous, attributes: [
                .NSComboBox.Miscellaneous.buttonBordered, .NSComboBox.Miscellaneous.completes, .NSComboBox.Miscellaneous.usesDataSource,
            ]),
        ]),
        Group(identifier: .nsStepper, sections: [
            Section(identifier: .NSStepper.range, attributes: [
                .NSStepper.Range.minValue, .NSStepper.Range.maxValue, .NSStepper.Range.increment,
            ]),
            Section(identifier: .NSStepper.miscellaneous, attributes: [.NSStepper.Miscellaneous.valueWraps, .NSStepper.Miscellaneous.autorepeat]),
        ]),
        Group(identifier: .nsOutlineView, sections: [
            Section(identifier: .NSOutlineView.indentation, attributes: [.NSOutlineView.Indentation.indentationPerLevel]),
            Section(identifier: .NSOutlineView.miscellaneous, attributes: [
                .NSOutlineView.Miscellaneous.autoresizesOutlineColumn, .NSOutlineView.Miscellaneous.indentationMarkerFollowsCell,
                .NSOutlineView.Miscellaneous.autosaveExpandedItems,
            ]),
        ]),
        Group(identifier: .nsCollectionView, sections: [
            Section(identifier: .NSCollectionView.selection, attributes: [
                .NSCollectionView.Selection.selectable, .NSCollectionView.Selection.allowsMultipleSelection,
                .NSCollectionView.Selection.allowsEmptySelection,
            ]),
        ]),
        Group(identifier: .nsBox, sections: [
            Section(identifier: .NSBox.kind, attributes: [.NSBox.Kind.boxType, .NSBox.Kind.borderType]),
            Section(identifier: .NSBox.title, attributes: [.NSBox.Title.title, .NSBox.Title.titlePosition]),
            Section(identifier: .NSBox.appearance, attributes: [
                .NSBox.Appearance.transparent, .NSBox.Appearance.fillColor, .NSBox.Appearance.borderColor,
            ]),
            Section(identifier: .NSBox.metrics, attributes: [
                .NSBox.Metrics.borderWidth, .NSBox.Metrics.cornerRadius, .NSBox.Metrics.contentViewMargins,
            ]),
        ]),
        Group(identifier: .nsSplitView, sections: [
            Section(identifier: .NSSplitView.orientation, attributes: [.NSSplitView.Orientation.vertical]),
            Section(identifier: .NSSplitView.style, attributes: [
                .NSSplitView.Style.dividerStyle, .NSSplitView.Style.dividerThickness,
            ]),
        ]),
        Group(identifier: .nsCell, sections: [
            Section(identifier: .NSCell.cell, attributes: [
                .NSCell.Cell.enabled, .NSCell.Cell.bordered, .NSCell.Cell.bezeled, .NSCell.Cell.editable,
                .NSCell.Cell.alignment, .NSCell.Cell.controlSize,
            ]),
            Section(identifier: .NSCell.content, attributes: [
                .NSCell.Content.title, .NSCell.Content.fontName, .NSCell.Content.fontSize,
                .NSCell.Content.lineBreakMode,
            ]),
            Section(identifier: .NSCell.behavior, attributes: [
                .NSCell.Behavior.continuous, .NSCell.Behavior.allowsMixedState,
                .NSCell.Behavior.sendsActionOnEndEditing,
            ]),
            Section(identifier: .NSCell.buttonCell, attributes: [.NSCell.ButtonCell.bezelStyle]),
            Section(identifier: .NSCell.textFieldCell, attributes: [.NSCell.TextFieldCell.placeholder]),
        ]),
        Group(identifier: .layoutGuide, sections: [
            Section(identifier: .LayoutGuide.guideIdentifier, attributes: [.LayoutGuide.GuideIdentifier.identifier]),
            Section(identifier: .LayoutGuide.layoutFrame, attributes: [.LayoutGuide.LayoutFrame.layoutFrame]),
            Section(identifier: .LayoutGuide.owningView, attributes: [.LayoutGuide.OwningView.owningView]),
        ]),
    ]

    // MARK: - Specifications

    private typealias Specification = XcodeViewHierarchyAttributeSpecification

    private static let anyView = ["UIView", "NSView"]
    private static let anyViewOrWindow = ["UIView", "NSView", "NSWindow"]

    private static let styleMask = { (flag: NSWindow.StyleMask) in Specification.Kind.maskBit(UInt64(flag.rawValue)) }
    private static let collectionBehavior = { (flag: NSWindow.CollectionBehavior) in
        Specification.Kind.maskBit(UInt64(flag.rawValue))
    }

    /// Where each attribute's value comes from. Attributes built from more
    /// than a property — the class chain, relations, constraints, a scene's
    /// window count — are not here; `XcodeViewHierarchyAttributes` handles them.
    static let specifications: [InspectedAttribute.Identifier: XcodeViewHierarchyAttributeSpecification] = [
        // Layout. AppKit records a view's frame on the view and its layer's
        // on the layer, and the two differ under flipping; the view's is the
        // one the inspector's other cards are built from.
        .Layout.Frame.frame: Specification(anyViewOrWindow, .rect, "frame", source: .nodeThenLayer),
        .Layout.Bounds.bounds: Specification(anyViewOrWindow, .rect, "bounds", source: .nodeThenLayer),
        .Layout.Position.position: Specification(anyView, .point, "position", source: .layerThenNode),
        .Layout.AnchorPoint.anchorPoint: Specification(anyView, .point, "anchorPoint", source: .layerThenNode),
        .Layout.CoordinateSpace.coordinateSpace: Specification(["UIWindowScene"], .rect, "bounds"),

        // Auto Layout sizing
        .AutoLayout.Hugging.horizontal: Specification(anyView, .number, "contentHuggingPriorityHorizontal"),
        .AutoLayout.Hugging.vertical: Specification(anyView, .number, "contentHuggingPriorityVertical"),
        .AutoLayout.Resistance.horizontal: Specification(anyView, .number, "contentCompressionResistancePriorityHorizontal"),
        .AutoLayout.Resistance.vertical: Specification(anyView, .number, "contentCompressionResistancePriorityVertical"),

        // View / layer
        .ViewLayer.Visibility.hidden: Specification(anyView, .bool, "hidden", source: .nodeThenLayer),
        .ViewLayer.Visibility.opacity: Specification(anyView, .number, "alpha", "alphaValue", "opacity", source: .nodeThenLayer),
        .ViewLayer.InteractionAndMasks.interaction: Specification(["UIView"], .bool, "userInteractionEnabled"),
        .ViewLayer.InteractionAndMasks.masksToBounds: Specification(anyView, .bool, "masksToBounds", "clipsToBounds", source: .layerThenNode),
        .ViewLayer.BackgroundColor.backgroundColor: Specification(anyView, .color, "backgroundColor", source: .layerThenNode),
        .ViewLayer.Border.color: Specification(anyView, .color, "borderColor", source: .layer),
        .ViewLayer.Border.width: Specification(anyView, .number, "borderWidth", source: .layer),
        .ViewLayer.Corner.radius: Specification(anyView, .number, "cornerRadius", source: .layerThenNode),
        .ViewLayer.Shadow.color: Specification(anyView, .color, "shadowColor", source: .layer),
        .ViewLayer.Shadow.opacity: Specification(anyView, .number, "shadowOpacity", source: .layer),
        .ViewLayer.Shadow.radius: Specification(anyView, .number, "shadowRadius", source: .layer),
        .ViewLayer.Shadow.offsetWidth: Specification(anyView, .sizeWidth, "shadowOffset", source: .layer),
        .ViewLayer.Shadow.offsetHeight: Specification(anyView, .sizeHeight, "shadowOffset", source: .layer),
        .ViewLayer.Tag.tag: Specification(anyView, .integer, "tag"),
        .ViewLayer.ContentMode.mode: Specification(["UIView"], .integer, "contentMode"),
        .ViewLayer.TintColor.color: Specification(["UIView"], .color, "tintColor"),
        .ViewLayer.TintColor.mode: Specification(["UIView"], .integer, "tintAdjustmentMode"),

        // UIKit
        .UIStackView.Axis.axis: Specification(["UIStackView"], .integer, "axis"),
        .UIStackView.Distribution.distribution: Specification(["UIStackView"], .integer, "distribution"),
        .UIStackView.Alignment.alignment: Specification(["UIStackView"], .integer, "alignment"),
        .UIStackView.Spacing.spacing: Specification(["UIStackView"], .number, "spacing"),

        .UIImageView.Name.name: Specification(["UIImageView"], .imageName, "image"),
        .UIImageView.Open.open: Specification(["UIImageView"], .imageData, "image"),

        .UILabel.Text.text: Specification(["UILabel"], .text, "text"),
        .UILabel.Font.name: Specification(["UILabel"], .fontName, "font"),
        .UILabel.Font.size: Specification(["UILabel"], .fontSize, "font"),
        .UILabel.NumberOfLines.numberOfLines: Specification(["UILabel"], .integer, "numberOfLines"),
        .UILabel.TextColor.color: Specification(["UILabel"], .color, "textColor"),
        .UILabel.BreakMode.mode: Specification(["UILabel"], .integer, "lineBreakMode"),
        .UILabel.Alignment.alignment: Specification(["UILabel"], .integer, "textAlignment"),
        .UILabel.CanAdjustFont.canAdjustFont: Specification(["UILabel"], .bool, "adjustsFontSizeToFitWidth"),

        .UIControl.EnabledSelected.enabled: Specification(["UIControl"], .bool, "enabled"),
        .UIControl.EnabledSelected.selected: Specification(["UIControl"], .bool, "selected"),
        .UIControl.VerAlignment.alignment: Specification(["UIControl"], .integer, "contentVerticalAlignment"),
        .UIControl.HorAlignment.alignment: Specification(["UIControl"], .integer, "contentHorizontalAlignment"),

        .UIButton.ContentInsets.insets: Specification(["UIButton"], .insets, "contentEdgeInsets"),
        .UIButton.TitleInsets.insets: Specification(["UIButton"], .insets, "titleEdgeInsets"),
        .UIButton.ImageInsets.insets: Specification(["UIButton"], .insets, "imageEdgeInsets"),

        .UIScrollView.ShowsIndicator.horizontal: Specification(["UIScrollView"], .bool, "showsHorizontalScrollIndicator"),
        .UIScrollView.ShowsIndicator.vertical: Specification(["UIScrollView"], .bool, "showsVerticalScrollIndicator"),
        .UIScrollView.Bounce.horizontal: Specification(["UIScrollView"], .bool, "alwaysBounceHorizontal"),
        .UIScrollView.Bounce.vertical: Specification(["UIScrollView"], .bool, "alwaysBounceVertical"),
        .UIScrollView.ScrollPaging.scrollEnabled: Specification(["UIScrollView"], .bool, "scrollEnabled"),
        .UIScrollView.ScrollPaging.pagingEnabled: Specification(["UIScrollView"], .bool, "pagingEnabled"),
        .UIScrollView.ContentTouches.delay: Specification(["UIScrollView"], .bool, "delaysContentTouches"),
        .UIScrollView.ContentTouches.canCancel: Specification(["UIScrollView"], .bool, "canCancelContentTouches"),
        .UIScrollView.Zoom.bounce: Specification(["UIScrollView"], .bool, "bouncesZoom"),
        .UIScrollView.Zoom.minScale: Specification(["UIScrollView"], .number, "minimumZoomScale"),
        .UIScrollView.Zoom.maxScale: Specification(["UIScrollView"], .number, "maximumZoomScale"),

        .UITableView.Style.style: Specification(["UITableView"], .integer, "style"),
        .UITableView.SectionsNumber.number: Specification(["UITableView"], .integer, "numberOfSections"),
        .UITableView.SeparatorStyle.style: Specification(["UITableView"], .integer, "separatorStyle"),
        .UITableView.SeparatorColor.color: Specification(["UITableView"], .color, "separatorColor"),
        .UITableView.SeparatorInset.inset: Specification(["UITableView"], .insets, "separatorInset"),

        .UITextView.Basic.editable: Specification(["UITextView"], .bool, "editable"),
        .UITextView.Basic.selectable: Specification(["UITextView"], .bool, "selectable"),
        .UITextView.Text.text: Specification(["UITextView"], .text, "text"),
        .UITextView.Font.name: Specification(["UITextView"], .fontName, "font"),
        .UITextView.Font.size: Specification(["UITextView"], .fontSize, "font"),
        .UITextView.TextColor.color: Specification(["UITextView"], .color, "textColor"),
        .UITextView.Alignment.alignment: Specification(["UITextView"], .integer, "textAlignment"),

        .UITextField.Text.text: Specification(["UITextField"], .text, "text"),
        .UITextField.Placeholder.placeholder: Specification(["UITextField"], .text, "placeholder"),
        .UITextField.Font.name: Specification(["UITextField"], .fontName, "font"),
        .UITextField.Font.size: Specification(["UITextField"], .fontSize, "font"),
        .UITextField.TextColor.color: Specification(["UITextField"], .color, "textColor"),
        .UITextField.Alignment.alignment: Specification(["UITextField"], .integer, "textAlignment"),
        .UITextField.Clears.clearsOnBeginEditing: Specification(["UITextField"], .bool, "clearsOnBeginEditing"),
        .UITextField.CanAdjustFont.canAdjustFont: Specification(["UITextField"], .bool, "adjustsFontSizeToFitWidth"),
        .UITextField.CanAdjustFont.minSize: Specification(["UITextField"], .number, "minimumFontSize"),
        .UITextField.ClearButtonMode.mode: Specification(["UITextField"], .integer, "clearButtonMode"),

        .UIWindowScene.State.activationState: Specification(["UIWindowScene"], .integer, "activationState"),
        .UIWindowScene.Title.title: Specification(["UIWindowScene"], .text, "title"),
        .UIWindowScene.Title.subtitle: Specification(["UIWindowScene"], .text, "subtitle"),
        .UIWindowScene.Orientation.interfaceOrientation: Specification(["UIWindowScene"], .integer, "interfaceOrientation"),
        .UIWindowScene.Screen.screenBounds: Specification(["UIWindowScene"], .rect, "bounds", source: .screen),
        .UIWindowScene.Screen.screenScale: Specification(["UIWindowScene"], .number, "scale", source: .screen),
        .UIWindowScene.Traits.userInterfaceStyle: Specification(["UIWindowScene"], .integer, "traitCollectionUserInterfaceStyle"),
        .UIWindowScene.Traits.horizontalSizeClass: Specification(["UIWindowScene"], .integer, "traitCollectionHorizontalSizeClass"),
        .UIWindowScene.Traits.verticalSizeClass: Specification(["UIWindowScene"], .integer, "traitCollectionVerticalSizeClass"),
        .UIWindowScene.Traits.layoutDirection: Specification(["UIWindowScene"], .integer, "traitCollectionLayoutDirection"),

        .UITraitCollection.Appearance.userInterfaceStyle: Specification(["UIView"], .integer, "traitCollectionUserInterfaceStyle"),
        .UITraitCollection.SizeClass.horizontalSizeClass: Specification(["UIView"], .integer, "traitCollectionHorizontalSizeClass"),
        .UITraitCollection.SizeClass.verticalSizeClass: Specification(["UIView"], .integer, "traitCollectionVerticalSizeClass"),
        .UITraitCollection.Layout.layoutDirection: Specification(["UIView"], .integer, "traitCollectionLayoutDirection"),

        // AppKit
        .NSImageView.Name.name: Specification(["NSImageView"], .imageName, "image"),
        .NSImageView.Open.open: Specification(["NSImageView"], .imageData, "image"),
        .NSImageView.Scaling.imageScaling: Specification(["NSImageView"], .integer, "imageScaling"),
        .NSImageView.Scaling.imageAlignment: Specification(["NSImageView"], .integer, "imageAlignment"),
        .NSImageView.Scaling.imageFrameStyle: Specification(["NSImageView"], .integer, "imageFrameStyle"),
        .NSImageView.Behavior.animates: Specification(["NSImageView"], .bool, "animates"),
        .NSImageView.Behavior.editable: Specification(["NSImageView"], .bool, "editable"),
        .NSImageView.ContentTintColor.contentTintColor: Specification(["NSImageView"], .color, "contentTintColor"),

        .NSControl.State.enabled: Specification(["NSControl"], .bool, "enabled"),
        .NSControl.State.highlighted: Specification(["NSControl"], .bool, "highlighted"),
        .NSControl.State.continuous: Specification(["NSControl"], .bool, "continuous"),
        .NSControl.ControlSize.size: Specification(["NSControl"], .integer, "controlSize"),
        .NSControl.Font.name: Specification(["NSControl"], .fontName, "font"),
        .NSControl.Font.size: Specification(["NSControl"], .fontSize, "font"),
        .NSControl.Alignment.alignment: Specification(["NSControl"], .integer, "alignment"),
        .NSControl.Miscellaneous.writingDirection: Specification(["NSControl"], .integer, "baseWritingDirection"),
        .NSControl.Miscellaneous.usesSingleLineMode: Specification(["NSControl"], .bool, "usesSingleLineMode", source: .cell),
        .NSControl.Miscellaneous.allowsExpansionToolTips: Specification(["NSControl"], .bool, "allowsExpansionToolTips"),
        .NSControl.Value.doubleValue: Specification(["NSControl"], .number, "doubleValue"),

        .NSButton.ButtonType.buttonType: Specification(["NSButton"], .integer, "_buttonType", source: .cell),
        .NSButton.BezelStyle.bezelStyle: Specification(["NSButton"], .integer, "bezelStyle", source: .cell),
        .NSButton.Title.title: Specification(["NSButton"], .text, "title"),
        .NSButton.Title.alernateTitle: Specification(["NSButton"], .text, "alternateTitle"),
        .NSButton.Bordered.bordered: Specification(["NSButton"], .bool, "bordered", source: .cell),
        .NSButton.Transparent.transparent: Specification(["NSButton"], .bool, "transparent", source: .cell),
        .NSButton.Miscellaneous.springLoaded: Specification(["NSButton"], .bool, "springLoaded"),
        .NSButton.ContentTintColor.contentTintColor: Specification(["NSButton"], .color, "contentTintColor"),

        .NSScrollView.BorderType.borderType: Specification(["NSScrollView"], .integer, "borderType"),
        .NSScrollView.Scroller.horizontal: Specification(["NSScrollView"], .bool, "hasHorizontalScroller"),
        .NSScrollView.Scroller.vertical: Specification(["NSScrollView"], .bool, "hasVerticalScroller"),
        .NSScrollView.Scroller.autohidesScrollers: Specification(["NSScrollView"], .bool, "autohidesScrollers"),
        .NSScrollView.Scroller.scrollerKnobStyle: Specification(["NSScrollView"], .integer, "scrollerKnobStyle"),
        .NSScrollView.LineScroll.horizontal: Specification(["NSScrollView"], .number, "horizontalLineScroll"),
        .NSScrollView.LineScroll.vertical: Specification(["NSScrollView"], .number, "verticalLineScroll"),
        .NSScrollView.PageScroll.horizontal: Specification(["NSScrollView"], .number, "horizontalPageScroll"),
        .NSScrollView.PageScroll.vertical: Specification(["NSScrollView"], .number, "verticalPageScroll"),
        .NSScrollView.ScrollElasiticity.horizontal: Specification(["NSScrollView"], .integer, "horizontalScrollElasticity"),
        .NSScrollView.ScrollElasiticity.vertical: Specification(["NSScrollView"], .integer, "verticalScrollElasticity"),
        .NSScrollView.Miscellaneous.usesPredominantAxisScrolling: Specification(["NSScrollView"], .bool, "usesPredominantAxisScrolling"),
        .NSScrollView.Magnification.allowsMagnification: Specification(["NSScrollView"], .bool, "allowsMagnification"),
        .NSScrollView.Magnification.maximum: Specification(["NSScrollView"], .number, "maxMagnification"),
        .NSScrollView.Magnification.minimum: Specification(["NSScrollView"], .number, "minMagnification"),

        .NSTableView.RowHeight.rowHeight: Specification(["NSTableView"], .number, "rowHeight"),
        .NSTableView.IntercellSpacing.intercellSpacing: Specification(["NSTableView"], .size, "intercellSpacing"),
        .NSTableView.ColumnAutoresizingStyle.columnAutoresizingStyle: Specification(["NSTableView"], .integer, "columnAutoresizingStyle"),
        .NSTableView.GridStyleMask.gridStyleMask: Specification(["NSTableView"], .integer, "gridStyleMask"),
        .NSTableView.SelectionHighlightStyle.selectionHighlightStyle: Specification(["NSTableView"], .integer, "selectionHighlightStyle"),
        .NSTableView.GridColor.gridColor: Specification(["NSTableView"], .color, "gridColor"),
        .NSTableView.RowSizeStyle.rowSizeStyle: Specification(["NSTableView"], .integer, "rowSizeStyle"),
        .NSTableView.NumberOfColumns.numberOfColumns: Specification(["NSTableView"], .integer, "numberOfTableColumns"),
        .NSTableView.UseAlternatingRowBackgroundColors.useAlternatingRowBackgroundColors: Specification(["NSTableView"], .bool, "usesAlternatingRowBackgroundColors"),
        .NSTableView.AllowsColumnReordering.allowsColumnReordering: Specification(["NSTableView"], .bool, "allowsColumnReordering"),
        .NSTableView.AllowsColumnResizing.allowsColumnResizing: Specification(["NSTableView"], .bool, "allowsColumnResizing"),
        .NSTableView.AllowsMultipleSelection.allowsMultipleSelection: Specification(["NSTableView"], .bool, "allowsMultipleSelection"),
        .NSTableView.AllowsEmptySelection.allowsEmptySelection: Specification(["NSTableView"], .bool, "allowsEmptySelection"),
        .NSTableView.AllowsColumnSelection.allowsColumnSelection: Specification(["NSTableView"], .bool, "allowsColumnSelection"),
        .NSTableView.AllowsTypeSelect.allowsTypeSelect: Specification(["NSTableView"], .bool, "allowsTypeSelect"),
        .NSTableView.AutosaveName.autosaveName: Specification(["NSTableView"], .text, "autosaveName"),
        .NSTableView.AutosaveTableColumns.autosaveTableColumns: Specification(["NSTableView"], .bool, "autosaveTableColumns"),
        .NSTableView.FloatsGroupRows.floatsGroupRows: Specification(["NSTableView"], .bool, "floatsGroupRows"),

        .NSTextView.Basic.editable: Specification(["NSTextView"], .bool, "editable"),
        .NSTextView.Basic.selectable: Specification(["NSTextView"], .bool, "selectable"),
        .NSTextView.Basic.richText: Specification(["NSTextView"], .bool, "richText"),
        .NSTextView.Basic.fieldEditor: Specification(["NSTextView"], .bool, "fieldEditor"),
        .NSTextView.Basic.importsGraphics: Specification(["NSTextView"], .bool, "importsGraphics"),
        .NSTextView.String.string: Specification(["NSTextView"], .text, "textStorage"),
        .NSTextView.TextColor.color: Specification(["NSTextView"], .color, "textColor"),
        .NSTextView.BaseWritingDirection.baseWritingDirection: Specification(["NSTextView"], .integer, "baseWritingDirection"),

        .NSTextField.Bordered.bordered: Specification(["NSTextField"], .bool, "bordered"),
        .NSTextField.Bezeled.bezeled: Specification(["NSTextField"], .bool, "bezeled"),
        .NSTextField.Editable.editable: Specification(["NSTextField"], .bool, "editable"),
        .NSTextField.DrawsBackground.drawsBackground: Specification(["NSTextField"], .bool, "drawsBackground"),
        .NSTextField.AllowsEditingTextAttributes.allowsEditingTextAttributes: Specification(["NSTextField"], .bool, "allowsEditingTextAttributes"),
        .NSTextField.TextColor.color: Specification(["NSTextField"], .color, "textColor"),
        .NSTextField.BackgroundColor.color: Specification(["NSTextField"], .color, "backgroundColor"),
        .NSTextField.Placeholder.placeholder: Specification(["NSTextField"], .text, "placeholderString", source: .cell),

        .NSVisualEffectView.Material.material: Specification(["NSVisualEffectView"], .integer, "material"),
        .NSVisualEffectView.InteriorBackgroundStyle.interiorBackgroundStyle: Specification(["NSVisualEffectView"], .integer, "interiorBackgroundStyle"),
        .NSVisualEffectView.BlendingMode.blendingMode: Specification(["NSVisualEffectView"], .integer, "blendingMode"),
        .NSVisualEffectView.State.state: Specification(["NSVisualEffectView"], .integer, "state"),
        .NSVisualEffectView.Emphasized.emphasized: Specification(["NSVisualEffectView"], .bool, "emphasized"),

        .NSStackView.Orientation.orientation: Specification(["NSStackView"], .integer, "orientation"),
        .NSStackView.EdgeInsets.edgeInsets: Specification(["NSStackView"], .insets, "edgeInsets"),
        .NSStackView.Distribution.distribution: Specification(["NSStackView"], .integer, "distribution"),
        .NSStackView.Alignment.alignment: Specification(["NSStackView"], .integer, "alignment"),
        .NSStackView.Spacing.spacing: Specification(["NSStackView"], .number, "spacing"),

        .NSWindow.Title.title: Specification(["NSWindow"], .text, "title"),
        .NSWindow.State.keyWindow: Specification(["NSWindow"], .bool, "isKeyWindow"),
        .NSWindow.State.mainWindow: Specification(["NSWindow"], .bool, "isMainWindow"),
        .NSWindow.State.visible: Specification(["NSWindow"], .bool, "visible"),
        .NSWindow.Style.titled: Specification(["NSWindow"], styleMask(.titled), "styleMask"),
        .NSWindow.Style.closable: Specification(["NSWindow"], styleMask(.closable), "styleMask"),
        .NSWindow.Style.miniaturizable: Specification(["NSWindow"], styleMask(.miniaturizable), "styleMask"),
        .NSWindow.Style.resizable: Specification(["NSWindow"], styleMask(.resizable), "styleMask"),
        .NSWindow.Style.unifiedTitleAndToolbar: Specification(["NSWindow"], styleMask(.unifiedTitleAndToolbar), "styleMask"),
        .NSWindow.Style.fullScreen: Specification(["NSWindow"], styleMask(.fullScreen), "styleMask"),
        .NSWindow.Style.fullSizeContentView: Specification(["NSWindow"], styleMask(.fullSizeContentView), "styleMask"),
        .NSWindow.Style.utilityWindow: Specification(["NSWindow"], styleMask(.utilityWindow), "styleMask"),
        .NSWindow.Style.docModalWindow: Specification(["NSWindow"], styleMask(.docModalWindow), "styleMask"),
        .NSWindow.Style.nonactivatingPanel: Specification(["NSWindow"], styleMask(.nonactivatingPanel), "styleMask"),
        .NSWindow.Style.hudWindow: Specification(["NSWindow"], styleMask(.hudWindow), "styleMask"),
        .NSWindow.CollectionBehavior.canJoinAllSpaces: Specification(["NSWindow"], collectionBehavior(.canJoinAllSpaces), "collectionBehavior"),
        .NSWindow.CollectionBehavior.moveToActiveSpace: Specification(["NSWindow"], collectionBehavior(.moveToActiveSpace), "collectionBehavior"),
        .NSWindow.CollectionBehavior.participatesInCycle: Specification(["NSWindow"], collectionBehavior(.participatesInCycle), "collectionBehavior"),
        .NSWindow.CollectionBehavior.ignoresCycle: Specification(["NSWindow"], collectionBehavior(.ignoresCycle), "collectionBehavior"),
        .NSWindow.CollectionBehavior.fullScreenPrimary: Specification(["NSWindow"], collectionBehavior(.fullScreenPrimary), "collectionBehavior"),
        .NSWindow.CollectionBehavior.fullScreenAuxiliary: Specification(["NSWindow"], collectionBehavior(.fullScreenAuxiliary), "collectionBehavior"),
        .NSWindow.CollectionBehavior.fullScreenNone: Specification(["NSWindow"], collectionBehavior(.fullScreenNone), "collectionBehavior"),
        .NSWindow.CollectionBehavior.fullScreenAllowsTiling: Specification(["NSWindow"], collectionBehavior(.fullScreenAllowsTiling), "collectionBehavior"),
        .NSWindow.CollectionBehavior.fullScreenDisallowsTiling: Specification(["NSWindow"], collectionBehavior(.fullScreenDisallowsTiling), "collectionBehavior"),
        .NSWindow.Appearance.alphaValue: Specification(["NSWindow"], .number, "alphaValue"),
        .NSWindow.Appearance.opaque: Specification(["NSWindow"], .bool, "isOpaque"),
        .NSWindow.Appearance.hasShadow: Specification(["NSWindow"], .bool, "hasShadow"),
        .NSWindow.Behavior.hidesOnDeactivate: Specification(["NSWindow"], .bool, "hidesOnDeactivate"),
        .NSWindow.Behavior.animationBehavior: Specification(["NSWindow"], .integer, "animationBehavior"),
        .NSWindow.Information.backingScaleFactor: Specification(["NSWindow"], .number, "backingScaleFactor"),

        .NSSlider.SliderType.sliderType: Specification(["NSSlider"], .integer, "sliderType"),
        .NSSlider.Range.minValue: Specification(["NSSlider"], .number, "minValue"),
        .NSSlider.Range.maxValue: Specification(["NSSlider"], .number, "maxValue"),
        .NSSlider.TickMark.numberOfTickMarks: Specification(["NSSlider"], .integer, "numberOfTickMarks"),
        .NSSlider.TickMark.tickMarkPosition: Specification(["NSSlider"], .integer, "tickMarkPosition"),
        .NSSlider.TickMark.allowsTickMarkValuesOnly: Specification(["NSSlider"], .bool, "allowsTickMarkValuesOnly"),

        .NSProgressIndicator.Style.style: Specification(["NSProgressIndicator"], .integer, "style"),
        .NSProgressIndicator.Range.minValue: Specification(["NSProgressIndicator"], .number, "minValue"),
        .NSProgressIndicator.Range.maxValue: Specification(["NSProgressIndicator"], .number, "maxValue"),
        .NSProgressIndicator.Range.doubleValue: Specification(["NSProgressIndicator"], .number, "doubleValue"),
        .NSProgressIndicator.Miscellaneous.indeterminate: Specification(["NSProgressIndicator"], .bool, "indeterminate"),
        .NSProgressIndicator.Miscellaneous.bezeled: Specification(["NSProgressIndicator"], .bool, "bezeled"),
        .NSProgressIndicator.Miscellaneous.displayedWhenStopped: Specification(["NSProgressIndicator"], .bool, "displayedWhenStopped"),

        .NSSegmentedControl.SegmentCount.segmentCount: Specification(["NSSegmentedControl"], .integer, "segmentCount"),
        .NSSegmentedControl.Selection.selectedSegment: Specification(["NSSegmentedControl"], .integer, "selectedSegment"),
        .NSSegmentedControl.Style.segmentStyle: Specification(["NSSegmentedControl"], .integer, "segmentStyle"),
        .NSSegmentedControl.Style.trackingMode: Specification(["NSSegmentedControl"], .integer, "trackingMode"),

        .NSPopUpButton.Behavior.preferredEdge: Specification(["NSPopUpButton"], .integer, "preferredEdge"),

        .NSComboBox.Items.numberOfVisibleItems: Specification(["NSComboBox"], .integer, "numberOfVisibleItems"),
        .NSComboBox.Miscellaneous.buttonBordered: Specification(["NSComboBox"], .bool, "buttonBordered"),
        .NSComboBox.Miscellaneous.completes: Specification(["NSComboBox"], .bool, "completes"),
        .NSComboBox.Miscellaneous.usesDataSource: Specification(["NSComboBox"], .bool, "usesDataSource"),

        .NSStepper.Range.minValue: Specification(["NSStepper"], .number, "minValue"),
        .NSStepper.Range.maxValue: Specification(["NSStepper"], .number, "maxValue"),
        .NSStepper.Range.increment: Specification(["NSStepper"], .number, "increment"),
        .NSStepper.Miscellaneous.valueWraps: Specification(["NSStepper"], .bool, "valueWraps"),
        .NSStepper.Miscellaneous.autorepeat: Specification(["NSStepper"], .bool, "autorepeat"),

        .NSOutlineView.Indentation.indentationPerLevel: Specification(["NSOutlineView"], .number, "indentationPerLevel"),
        .NSOutlineView.Miscellaneous.autoresizesOutlineColumn: Specification(["NSOutlineView"], .bool, "autoresizesOutlineColumn"),
        .NSOutlineView.Miscellaneous.indentationMarkerFollowsCell: Specification(["NSOutlineView"], .bool, "indentationMarkerFollowsCell"),
        .NSOutlineView.Miscellaneous.autosaveExpandedItems: Specification(["NSOutlineView"], .bool, "autosaveExpandedItems"),

        .NSCollectionView.Selection.selectable: Specification(["NSCollectionView"], .bool, "selectable"),
        .NSCollectionView.Selection.allowsMultipleSelection: Specification(["NSCollectionView"], .bool, "allowsMultipleSelection"),
        .NSCollectionView.Selection.allowsEmptySelection: Specification(["NSCollectionView"], .bool, "allowsEmptySelection"),

        .NSBox.Kind.boxType: Specification(["NSBox"], .integer, "boxType"),
        .NSBox.Kind.borderType: Specification(["NSBox"], .integer, "borderType"),
        .NSBox.Title.title: Specification(["NSBox"], .text, "title"),
        .NSBox.Title.titlePosition: Specification(["NSBox"], .integer, "titlePosition"),
        .NSBox.Appearance.transparent: Specification(["NSBox"], .bool, "transparent"),
        .NSBox.Appearance.fillColor: Specification(["NSBox"], .color, "fillColor"),
        .NSBox.Appearance.borderColor: Specification(["NSBox"], .color, "borderColor"),
        .NSBox.Metrics.borderWidth: Specification(["NSBox"], .number, "borderWidth"),
        .NSBox.Metrics.cornerRadius: Specification(["NSBox"], .number, "cornerRadius"),
        .NSBox.Metrics.contentViewMargins: Specification(["NSBox"], .size, "contentViewMargins"),

        .NSSplitView.Orientation.vertical: Specification(["NSSplitView"], .bool, "vertical"),
        .NSSplitView.Style.dividerStyle: Specification(["NSSplitView"], .integer, "dividerStyle"),
        .NSSplitView.Style.dividerThickness: Specification(["NSSplitView"], .number, "dividerThickness"),

        // AppKit cells, read on the cell node itself
        .NSCell.Cell.enabled: Specification(["NSCell"], .bool, "enabled"),
        .NSCell.Cell.bordered: Specification(["NSCell"], .bool, "bordered"),
        .NSCell.Cell.bezeled: Specification(["NSCell"], .bool, "bezeled"),
        .NSCell.Cell.editable: Specification(["NSCell"], .bool, "editable"),
        .NSCell.Cell.alignment: Specification(["NSCell"], .integer, "alignment"),
        .NSCell.Cell.controlSize: Specification(["NSCell"], .integer, "controlSize"),
        .NSCell.Content.title: Specification(["NSCell"], .text, "title"),
        .NSCell.Content.fontName: Specification(["NSCell"], .fontName, "font"),
        .NSCell.Content.fontSize: Specification(["NSCell"], .fontSize, "font"),
        .NSCell.Content.lineBreakMode: Specification(["NSCell"], .integer, "lineBreakMode"),
        .NSCell.Behavior.continuous: Specification(["NSCell"], .bool, "continuous"),
        .NSCell.Behavior.allowsMixedState: Specification(["NSCell"], .bool, "allowsMixedState"),
        .NSCell.Behavior.sendsActionOnEndEditing: Specification(["NSCell"], .bool, "sendsActionOnEndEditing"),
        .NSCell.ButtonCell.bezelStyle: Specification(["NSButtonCell"], .integer, "bezelStyle"),
        .NSCell.TextFieldCell.placeholder: Specification(["NSTextFieldCell"], .text, "placeholderString"),

        // Layout guides
        .LayoutGuide.GuideIdentifier.identifier: Specification(["UILayoutGuide", "NSLayoutGuide"], .text, "identifier"),
        .LayoutGuide.LayoutFrame.layoutFrame: Specification(["UILayoutGuide", "NSLayoutGuide"], .rect, "layoutFrame", "frame"),
    ]
}
