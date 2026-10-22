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
        let identifier: String
        let attributes: [String]
    }

    struct Group {
        let identifier: String
        let sections: [Section]
    }

    // MARK: - Order

    /// The blueprint's order, both platforms, restricted to rows a capture can fill.
    static let groups: [Group] = [
        Group(identifier: LookinAttrGroup_Class, sections: [
            Section(identifier: LookinAttrSec_Class_Class, attributes: [LookinAttr_Class_Class_Class]),
        ]),
        Group(identifier: LookinAttrGroup_Relation, sections: [
            Section(identifier: LookinAttrSec_Relation_Relation, attributes: [LookinAttr_Relation_Relation_Relation]),
        ]),
        Group(identifier: LookinAttrGroup_Layout, sections: [
            Section(identifier: LookinAttrSec_Layout_Frame, attributes: [LookinAttr_Layout_Frame_Frame]),
            Section(identifier: LookinAttrSec_Layout_Bounds, attributes: [LookinAttr_Layout_Bounds_Bounds]),
            Section(identifier: LookinAttrSec_Layout_Position, attributes: [LookinAttr_Layout_Position_Position]),
            Section(identifier: LookinAttrSec_Layout_AnchorPoint, attributes: [LookinAttr_Layout_AnchorPoint_AnchorPoint]),
            Section(identifier: LookinAttrSec_Layout_CoordinateSpace, attributes: [LookinAttr_Layout_CoordinateSpace_CoordinateSpace]),
        ]),
        Group(identifier: LookinAttrGroup_AutoLayout, sections: [
            Section(identifier: LookinAttrSec_AutoLayout_Constraints, attributes: [LookinAttr_AutoLayout_Constraints_Constraints]),
            Section(identifier: LookinAttrSec_AutoLayout_Hugging, attributes: [
                LookinAttr_AutoLayout_Hugging_Hor, LookinAttr_AutoLayout_Hugging_Ver,
            ]),
            Section(identifier: LookinAttrSec_AutoLayout_Resistance, attributes: [
                LookinAttr_AutoLayout_Resistance_Hor, LookinAttr_AutoLayout_Resistance_Ver,
            ]),
        ]),
        Group(identifier: LookinAttrGroup_ViewLayer, sections: [
            Section(identifier: LookinAttrSec_ViewLayer_Visibility, attributes: [
                LookinAttr_ViewLayer_Visibility_Hidden, LookinAttr_ViewLayer_Visibility_Opacity,
            ]),
            Section(identifier: LookinAttrSec_ViewLayer_InterationAndMasks, attributes: [
                LookinAttr_ViewLayer_InterationAndMasks_Interaction, LookinAttr_ViewLayer_InterationAndMasks_MasksToBounds,
            ]),
            Section(identifier: LookinAttrSec_ViewLayer_BgColor, attributes: [LookinAttr_ViewLayer_BgColor_BgColor]),
            Section(identifier: LookinAttrSec_ViewLayer_Border, attributes: [
                LookinAttr_ViewLayer_Border_Color, LookinAttr_ViewLayer_Border_Width,
            ]),
            Section(identifier: LookinAttrSec_ViewLayer_Corner, attributes: [LookinAttr_ViewLayer_Corner_Radius]),
            Section(identifier: LookinAttrSec_ViewLayer_Shadow, attributes: [
                LookinAttr_ViewLayer_Shadow_Color, LookinAttr_ViewLayer_Shadow_Opacity, LookinAttr_ViewLayer_Shadow_Radius,
                LookinAttr_ViewLayer_Shadow_OffsetW, LookinAttr_ViewLayer_Shadow_OffsetH,
            ]),
            Section(identifier: LookinAttrSec_ViewLayer_Tag, attributes: [LookinAttr_ViewLayer_Tag_Tag]),
            Section(identifier: LookinAttrSec_ViewLayer_ContentMode, attributes: [LookinAttr_ViewLayer_ContentMode_Mode]),
            Section(identifier: LookinAttrSec_ViewLayer_TintColor, attributes: [
                LookinAttr_ViewLayer_TintColor_Color, LookinAttr_ViewLayer_TintColor_Mode,
            ]),
        ]),

        // UIKit
        Group(identifier: LookinAttrGroup_UIStackView, sections: [
            Section(identifier: LookinAttrSec_UIStackView_Axis, attributes: [LookinAttr_UIStackView_Axis_Axis]),
            Section(identifier: LookinAttrSec_UIStackView_Distribution, attributes: [LookinAttr_UIStackView_Distribution_Distribution]),
            Section(identifier: LookinAttrSec_UIStackView_Alignment, attributes: [LookinAttr_UIStackView_Alignment_Alignment]),
            Section(identifier: LookinAttrSec_UIStackView_Spacing, attributes: [LookinAttr_UIStackView_Spacing_Spacing]),
        ]),
        Group(identifier: LookinAttrGroup_UIImageView, sections: [
            Section(identifier: LookinAttrSec_UIImageView_Name, attributes: [LookinAttr_UIImageView_Name_Name]),
            Section(identifier: LookinAttrSec_UIImageView_Open, attributes: [LookinAttr_UIImageView_Open_Open]),
        ]),
        Group(identifier: LookinAttrGroup_UILabel, sections: [
            Section(identifier: LookinAttrSec_UILabel_Text, attributes: [LookinAttr_UILabel_Text_Text]),
            Section(identifier: LookinAttrSec_UILabel_Font, attributes: [LookinAttr_UILabel_Font_Name, LookinAttr_UILabel_Font_Size]),
            Section(identifier: LookinAttrSec_UILabel_NumberOfLines, attributes: [LookinAttr_UILabel_NumberOfLines_NumberOfLines]),
            Section(identifier: LookinAttrSec_UILabel_TextColor, attributes: [LookinAttr_UILabel_TextColor_Color]),
            Section(identifier: LookinAttrSec_UILabel_BreakMode, attributes: [LookinAttr_UILabel_BreakMode_Mode]),
            Section(identifier: LookinAttrSec_UILabel_Alignment, attributes: [LookinAttr_UILabel_Alignment_Alignment]),
            Section(identifier: LookinAttrSec_UILabel_CanAdjustFont, attributes: [LookinAttr_UILabel_CanAdjustFont_CanAdjustFont]),
        ]),
        Group(identifier: LookinAttrGroup_UIControl, sections: [
            Section(identifier: LookinAttrSec_UIControl_EnabledSelected, attributes: [
                LookinAttr_UIControl_EnabledSelected_Enabled, LookinAttr_UIControl_EnabledSelected_Selected,
            ]),
            Section(identifier: LookinAttrSec_UIControl_VerAlignment, attributes: [LookinAttr_UIControl_VerAlignment_Alignment]),
            Section(identifier: LookinAttrSec_UIControl_HorAlignment, attributes: [LookinAttr_UIControl_HorAlignment_Alignment]),
        ]),
        Group(identifier: LookinAttrGroup_UIButton, sections: [
            Section(identifier: LookinAttrSec_UIButton_ContentInsets, attributes: [LookinAttr_UIButton_ContentInsets_Insets]),
            Section(identifier: LookinAttrSec_UIButton_TitleInsets, attributes: [LookinAttr_UIButton_TitleInsets_Insets]),
            Section(identifier: LookinAttrSec_UIButton_ImageInsets, attributes: [LookinAttr_UIButton_ImageInsets_Insets]),
        ]),
        Group(identifier: LookinAttrGroup_UIScrollView, sections: [
            Section(identifier: LookinAttrSec_UIScrollView_ShowsIndicator, attributes: [
                LookinAttr_UIScrollView_ShowsIndicator_Hor, LookinAttr_UIScrollView_ShowsIndicator_Ver,
            ]),
            Section(identifier: LookinAttrSec_UIScrollView_Bounce, attributes: [
                LookinAttr_UIScrollView_Bounce_Hor, LookinAttr_UIScrollView_Bounce_Ver,
            ]),
            Section(identifier: LookinAttrSec_UIScrollView_ScrollPaging, attributes: [
                LookinAttr_UIScrollView_ScrollPaging_ScrollEnabled, LookinAttr_UIScrollView_ScrollPaging_PagingEnabled,
            ]),
            Section(identifier: LookinAttrSec_UIScrollView_ContentTouches, attributes: [
                LookinAttr_UIScrollView_ContentTouches_Delay, LookinAttr_UIScrollView_ContentTouches_CanCancel,
            ]),
            Section(identifier: LookinAttrSec_UIScrollView_Zoom, attributes: [
                LookinAttr_UIScrollView_Zoom_Bounce, LookinAttr_UIScrollView_Zoom_MinScale, LookinAttr_UIScrollView_Zoom_MaxScale,
            ]),
        ]),
        Group(identifier: LookinAttrGroup_UITableView, sections: [
            Section(identifier: LookinAttrSec_UITableView_Style, attributes: [LookinAttr_UITableView_Style_Style]),
            Section(identifier: LookinAttrSec_UITableView_SectionsNumber, attributes: [LookinAttr_UITableView_SectionsNumber_Number]),
            Section(identifier: LookinAttrSec_UITableView_SeparatorStyle, attributes: [LookinAttr_UITableView_SeparatorStyle_Style]),
            Section(identifier: LookinAttrSec_UITableView_SeparatorColor, attributes: [LookinAttr_UITableView_SeparatorColor_Color]),
            Section(identifier: LookinAttrSec_UITableView_SeparatorInset, attributes: [LookinAttr_UITableView_SeparatorInset_Inset]),
        ]),
        Group(identifier: LookinAttrGroup_UITextView, sections: [
            Section(identifier: LookinAttrSec_UITextView_Basic, attributes: [
                LookinAttr_UITextView_Basic_Editable, LookinAttr_UITextView_Basic_Selectable,
            ]),
            Section(identifier: LookinAttrSec_UITextView_Text, attributes: [LookinAttr_UITextView_Text_Text]),
            Section(identifier: LookinAttrSec_UITextView_Font, attributes: [LookinAttr_UITextView_Font_Name, LookinAttr_UITextView_Font_Size]),
            Section(identifier: LookinAttrSec_UITextView_TextColor, attributes: [LookinAttr_UITextView_TextColor_Color]),
            Section(identifier: LookinAttrSec_UITextView_Alignment, attributes: [LookinAttr_UITextView_Alignment_Alignment]),
        ]),
        Group(identifier: LookinAttrGroup_UITextField, sections: [
            Section(identifier: LookinAttrSec_UITextField_Text, attributes: [LookinAttr_UITextField_Text_Text]),
            Section(identifier: LookinAttrSec_UITextField_Placeholder, attributes: [LookinAttr_UITextField_Placeholder_Placeholder]),
            Section(identifier: LookinAttrSec_UITextField_Font, attributes: [LookinAttr_UITextField_Font_Name, LookinAttr_UITextField_Font_Size]),
            Section(identifier: LookinAttrSec_UITextField_TextColor, attributes: [LookinAttr_UITextField_TextColor_Color]),
            Section(identifier: LookinAttrSec_UITextField_Alignment, attributes: [LookinAttr_UITextField_Alignment_Alignment]),
            Section(identifier: LookinAttrSec_UITextField_Clears, attributes: [LookinAttr_UITextField_Clears_ClearsOnBeginEditing]),
            Section(identifier: LookinAttrSec_UITextField_CanAdjustFont, attributes: [
                LookinAttr_UITextField_CanAdjustFont_CanAdjustFont, LookinAttr_UITextField_CanAdjustFont_MinSize,
            ]),
            Section(identifier: LookinAttrSec_UITextField_ClearButtonMode, attributes: [LookinAttr_UITextField_ClearButtonMode_Mode]),
        ]),
        Group(identifier: LookinAttrGroup_UIWindowScene, sections: [
            Section(identifier: LookinAttrSec_UIWindowScene_State, attributes: [LookinAttr_UIWindowScene_State_ActivationState]),
            Section(identifier: LookinAttrSec_UIWindowScene_Title, attributes: [
                LookinAttr_UIWindowScene_Title_Title, LookinAttr_UIWindowScene_Title_Subtitle,
            ]),
            Section(identifier: LookinAttrSec_UIWindowScene_Orientation, attributes: [LookinAttr_UIWindowScene_Orientation_InterfaceOrientation]),
            Section(identifier: LookinAttrSec_UIWindowScene_Windows, attributes: [
                LookinAttr_UIWindowScene_Windows_WindowCount, LookinAttr_UIWindowScene_Windows_KeyWindowClassName,
            ]),
            Section(identifier: LookinAttrSec_UIWindowScene_Screen, attributes: [
                LookinAttr_UIWindowScene_Screen_ScreenBounds, LookinAttr_UIWindowScene_Screen_ScreenScale,
            ]),
            Section(identifier: LookinAttrSec_UIWindowScene_Traits, attributes: [
                LookinAttr_UIWindowScene_Traits_UserInterfaceStyle, LookinAttr_UIWindowScene_Traits_HorizontalSizeClass,
                LookinAttr_UIWindowScene_Traits_VerticalSizeClass, LookinAttr_UIWindowScene_Traits_LayoutDirection,
            ]),
        ]),
        Group(identifier: LookinAttrGroup_UITraitCollection, sections: [
            Section(identifier: LookinAttrSec_UITraitCollection_Appearance, attributes: [LookinAttr_UITraitCollection_Appearance_UserInterfaceStyle]),
            Section(identifier: LookinAttrSec_UITraitCollection_SizeClass, attributes: [
                LookinAttr_UITraitCollection_SizeClass_HorizontalSizeClass, LookinAttr_UITraitCollection_SizeClass_VerticalSizeClass,
            ]),
            Section(identifier: LookinAttrSec_UITraitCollection_Layout, attributes: [LookinAttr_UITraitCollection_Layout_LayoutDirection]),
        ]),

        // AppKit
        Group(identifier: LookinAttrGroup_NSImageView, sections: [
            Section(identifier: LookinAttrSec_NSImageView_Name, attributes: [LookinAttr_NSImageView_Name_Name]),
            Section(identifier: LookinAttrSec_NSImageView_Open, attributes: [LookinAttr_NSImageView_Open_Open]),
            Section(identifier: LookinAttrSec_NSImageView_Scaling, attributes: [
                LookinAttr_NSImageView_Scaling_ImageScaling, LookinAttr_NSImageView_Scaling_ImageAlignment,
                LookinAttr_NSImageView_Scaling_ImageFrameStyle,
            ]),
            Section(identifier: LookinAttrSec_NSImageView_Behavior, attributes: [
                LookinAttr_NSImageView_Behavior_Animates, LookinAttr_NSImageView_Behavior_Editable,
            ]),
            Section(identifier: LookinAttrSec_NSImageView_ContentTintColor, attributes: [LookinAttr_NSImageView_ContentTintColor_ContentTintColor]),
        ]),
        Group(identifier: LookinAttrGroup_NSControl, sections: [
            Section(identifier: LookinAttrSec_NSControl_State, attributes: [
                LookinAttr_NSControl_State_Enabled, LookinAttr_NSControl_State_Highlighted, LookinAttr_NSControl_State_Continuous,
            ]),
            Section(identifier: LookinAttrSec_NSControl_ControlSize, attributes: [LookinAttr_NSControl_ControlSize_Size]),
            Section(identifier: LookinAttrSec_NSControl_Font, attributes: [LookinAttr_NSControl_Font_Name, LookinAttr_NSControl_Font_Size]),
            Section(identifier: LookinAttrSec_NSControl_Alignment, attributes: [LookinAttr_NSControl_Alignment_Alignment]),
            Section(identifier: LookinAttrSec_NSControl_Misc, attributes: [
                LookinAttr_NSControl_Misc_WritingDirection, LookinAttr_NSControl_Misc_UsesSingleLineMode,
                LookinAttr_NSControl_Misc_AllowsExpansionToolTips,
            ]),
            Section(identifier: LookinAttrSec_NSControl_Value, attributes: [LookinAttr_NSControl_Value_DoubleValue]),
        ]),
        Group(identifier: LookinAttrGroup_NSButton, sections: [
            Section(identifier: LookinAttrSec_NSButton_ButtonType, attributes: [LookinAttr_NSButton_ButtonType_ButtonType]),
            Section(identifier: LookinAttrSec_NSButton_BezelStyle, attributes: [LookinAttr_NSButton_BezelStyle_BezelStyle]),
            Section(identifier: LookinAttrSec_NSButton_Title, attributes: [
                LookinAttr_NSButton_Title_Title, LookinAttr_NSButton_Title_AlernateTitle,
            ]),
            Section(identifier: LookinAttrSec_NSButton_Bordered, attributes: [
                LookinAttr_NSButton_Bordered_Bordered, LookinAttr_NSButton_Transparent_Transparent, LookinAttr_NSButton_Misc_SpringLoaded,
            ]),
            Section(identifier: LookinAttrSec_NSButton_BezelColor, attributes: [LookinAttr_NSButton_ContentTintColor_ContentTintColor]),
        ]),
        Group(identifier: LookinAttrGroup_NSScrollView, sections: [
            Section(identifier: LookinAttrSec_NSScrollView_BorderType, attributes: [LookinAttr_NSScrollView_BorderType_BorderType]),
            Section(identifier: LookinAttrSec_NSScrollView_Scroller, attributes: [
                LookinAttr_NSScrollView_Scroller_Horizontal, LookinAttr_NSScrollView_Scroller_Vertical,
                LookinAttr_NSScrollView_Scroller_AutohidesScrollers, LookinAttr_NSScrollView_Scroller_ScrollerKnobStyle,
            ]),
            Section(identifier: LookinAttrSec_NSScrollView_LineScroll, attributes: [
                LookinAttr_NSScrollView_LineScroll_Horizontal, LookinAttr_NSScrollView_LineScroll_Vertical,
            ]),
            Section(identifier: LookinAttrSec_NSScrollView_PageScroll, attributes: [
                LookinAttr_NSScrollView_PageScroll_Horizontal, LookinAttr_NSScrollView_PageScroll_Vertical,
            ]),
            Section(identifier: LookinAttrSec_NSScrollView_ScrollElasiticity, attributes: [
                LookinAttr_NSScrollView_ScrollElasiticity_Horizontal, LookinAttr_NSScrollView_ScrollElasiticity_Vertical,
            ]),
            Section(identifier: LookinAttrSec_NSScrollView_Misc, attributes: [LookinAttr_NSScrollView_Misc_UsesPredominantAxisScrolling]),
            Section(identifier: LookinAttrSec_NSScrollView_Magnification, attributes: [
                LookinAttr_NSScrollView_Magnification_AllowsMagnification, LookinAttr_NSScrollView_Magnification_Max,
                LookinAttr_NSScrollView_Magnification_Min,
            ]),
        ]),
        Group(identifier: LookinAttrGroup_NSTableView, sections: [
            Section(identifier: LookinAttrSec_NSTableView_RowHeight, attributes: [LookinAttr_NSTableView_RowHeight_RowHeight]),
            Section(identifier: LookinAttrSec_NSTableView_IntercellSpacing, attributes: [LookinAttr_NSTableView_IntercellSpacing_IntercellSpacing]),
            Section(identifier: LookinAttrSec_NSTableView_ColumnAutoresizingStyle, attributes: [LookinAttr_NSTableView_ColumnAutoresizingStyle_ColumnAutoresizingStyle]),
            Section(identifier: LookinAttrSec_NSTableView_GridStyleMask, attributes: [LookinAttr_NSTableView_GridStyleMask_GridStyleMask]),
            Section(identifier: LookinAttrSec_NSTableView_SelectionHighlightStyle, attributes: [LookinAttr_NSTableView_SelectionHighlightStyle_SelectionHighlightStyle]),
            Section(identifier: LookinAttrSec_NSTableView_GridColor, attributes: [LookinAttr_NSTableView_GridColor_GridColor]),
            Section(identifier: LookinAttrSec_NSTableView_RowSizeStyle, attributes: [LookinAttr_NSTableView_RowSizeStyle_RowSizeStyle]),
            Section(identifier: LookinAttrSec_NSTableView_NumberOfColumns, attributes: [LookinAttr_NSTableView_NumberOfColumns_NumberOfColumns]),
            Section(identifier: LookinAttrSec_NSTableView_UseAlternatingRowBackgroundColors, attributes: [LookinAttr_NSTableView_UseAlternatingRowBackgroundColors_UseAlternatingRowBackgroundColors]),
            Section(identifier: LookinAttrSec_NSTableView_AllowsColumnReordering, attributes: [LookinAttr_NSTableView_AllowsColumnReordering_AllowsColumnReordering]),
            Section(identifier: LookinAttrSec_NSTableView_AllowsColumnResizing, attributes: [LookinAttr_NSTableView_AllowsColumnResizing_AllowsColumnResizing]),
            Section(identifier: LookinAttrSec_NSTableView_AllowsMultipleSelection, attributes: [LookinAttr_NSTableView_AllowsMultipleSelection_AllowsMultipleSelection]),
            Section(identifier: LookinAttrSec_NSTableView_AllowsEmptySelection, attributes: [LookinAttr_NSTableView_AllowsEmptySelection_AllowsEmptySelection]),
            Section(identifier: LookinAttrSec_NSTableView_AllowsColumnSelection, attributes: [LookinAttr_NSTableView_AllowsColumnSelection_AllowsColumnSelection]),
            Section(identifier: LookinAttrSec_NSTableView_AllowsTypeSelect, attributes: [LookinAttr_NSTableView_AllowsTypeSelect_AllowsTypeSelect]),
            Section(identifier: LookinAttrSec_NSTableView_Autosave, attributes: [
                LookinAttr_NSTableView_AutosaveName_AutosaveName, LookinAttr_NSTableView_AutosaveTableColumns_AutosaveTableColumns,
            ]),
            Section(identifier: LookinAttrSec_NSTableView_FloatsGroupRows, attributes: [LookinAttr_NSTableView_FloatsGroupRows_FloatsGroupRows]),
        ]),
        Group(identifier: LookinAttrGroup_NSTextView, sections: [
            Section(identifier: LookinAttrSec_NSTextView_Basic, attributes: [
                LookinAttr_NSTextView_Basic_Editable, LookinAttr_NSTextView_Basic_Selectable, LookinAttr_NSTextView_Basic_RichText,
                LookinAttr_NSTextView_Basic_FieldEditor, LookinAttr_NSTextView_Basic_ImportsGraphics,
            ]),
            Section(identifier: LookinAttrSec_NSTextView_String, attributes: [LookinAttr_NSTextView_String_String]),
            Section(identifier: LookinAttrSec_NSTextView_TextColor, attributes: [LookinAttr_NSTextView_TextColor_Color]),
            Section(identifier: LookinAttrSec_NSTextView_BaseWritingDirection, attributes: [LookinAttr_NSTextView_BaseWritingDirection_BaseWritingDirection]),
        ]),
        Group(identifier: LookinAttrGroup_NSTextField, sections: [
            Section(identifier: LookinAttrSec_NSTextField_Bordered, attributes: [
                LookinAttr_NSTextField_Bordered_Bordered, LookinAttr_NSTextField_Bezeled_Bezeled, LookinAttr_NSTextField_Editable_Editable,
                LookinAttr_NSTextField_DrawsBackground_DrawsBackground,
                LookinAttr_NSTextField_AllowsEditingTextAttributes_AllowsEditingTextAttributes,
            ]),
            Section(identifier: LookinAttrSec_NSTextField_TextColor, attributes: [
                LookinAttr_NSTextField_TextColor_Color, LookinAttr_NSTextField_BackgroundColor_Color,
            ]),
            Section(identifier: LookinAttrSec_NSTextField_Placeholder, attributes: [LookinAttr_NSTextField_Placeholder_Placeholder]),
        ]),
        Group(identifier: LookinAttrGroup_NSVisualEffectView, sections: [
            Section(identifier: LookinAttrSec_NSVisualEffectView_Material, attributes: [LookinAttr_NSVisualEffectView_Material_Material]),
            Section(identifier: LookinAttrSec_NSVisualEffectView_InteriorBackgroundStyle, attributes: [LookinAttr_NSVisualEffectView_InteriorBackgroundStyle_InteriorBackgroundStyle]),
            Section(identifier: LookinAttrSec_NSVisualEffectView_BlendingMode, attributes: [LookinAttr_NSVisualEffectView_BlendingMode_BlendingMode]),
            Section(identifier: LookinAttrSec_NSVisualEffectView_State, attributes: [LookinAttr_NSVisualEffectView_State_State]),
            Section(identifier: LookinAttrSec_NSVisualEffectView_Emphasized, attributes: [LookinAttr_NSVisualEffectView_Emphasized_Emphasized]),
        ]),
        Group(identifier: LookinAttrGroup_NSStackView, sections: [
            Section(identifier: LookinAttrSec_NSStackView_Orientation, attributes: [LookinAttr_NSStackView_Orientation_Orientation]),
            Section(identifier: LookinAttrSec_NSStackView_EdgeInsets, attributes: [LookinAttr_NSStackView_EdgeInsets_EdgeInsets]),
            Section(identifier: LookinAttrSec_NSStackView_Distribution, attributes: [LookinAttr_NSStackView_Distribution_Distribution]),
            Section(identifier: LookinAttrSec_NSStackView_Alignment, attributes: [LookinAttr_NSStackView_Alignment_Alignment]),
            Section(identifier: LookinAttrSec_NSStackView_Spacing, attributes: [LookinAttr_NSStackView_Spacing_Spacing]),
        ]),
        Group(identifier: LookinAttrGroup_NSWindow, sections: [
            Section(identifier: LookinAttrSec_NSWindow_Title, attributes: [LookinAttr_NSWindow_Title_Title]),
            Section(identifier: LookinAttrSec_NSWindow_State, attributes: [
                LookinAttr_NSWindow_State_KeyWindow, LookinAttr_NSWindow_State_MainWindow, LookinAttr_NSWindow_State_Visible,
            ]),
            Section(identifier: LookinAttrSec_NSWindow_Style, attributes: [
                LookinAttr_NSWindow_Style_Titled, LookinAttr_NSWindow_Style_Closable, LookinAttr_NSWindow_Style_Miniaturizable,
                LookinAttr_NSWindow_Style_Resizable, LookinAttr_NSWindow_Style_UnifiedTitleAndToolbar, LookinAttr_NSWindow_Style_FullScreen,
                LookinAttr_NSWindow_Style_FullSizeContentView, LookinAttr_NSWindow_Style_UtilityWindow, LookinAttr_NSWindow_Style_DocModalWindow,
                LookinAttr_NSWindow_Style_NonactivatingPanel, LookinAttr_NSWindow_Style_HUDWindow,
            ]),
            Section(identifier: LookinAttrSec_NSWindow_CollectionBehavior, attributes: [
                LookinAttr_NSWindow_CollectionBehavior_CanJoinAllSpaces, LookinAttr_NSWindow_CollectionBehavior_MoveToActiveSpace,
                LookinAttr_NSWindow_CollectionBehavior_ParticipatesInCycle, LookinAttr_NSWindow_CollectionBehavior_IgnoresCycle,
                LookinAttr_NSWindow_CollectionBehavior_FullScreenPrimary, LookinAttr_NSWindow_CollectionBehavior_FullScreenAuxiliary,
                LookinAttr_NSWindow_CollectionBehavior_FullScreenNone, LookinAttr_NSWindow_CollectionBehavior_FullScreenAllowsTiling,
                LookinAttr_NSWindow_CollectionBehavior_FullScreenDisallowsTiling,
            ]),
            Section(identifier: LookinAttrSec_NSWindow_Appearance, attributes: [
                LookinAttr_NSWindow_Appearance_AlphaValue, LookinAttr_NSWindow_Appearance_Opaque, LookinAttr_NSWindow_Appearance_HasShadow,
            ]),
            Section(identifier: LookinAttrSec_NSWindow_Behavior, attributes: [LookinAttr_NSWindow_Behavior_HidesOnDeactivate]),
            Section(identifier: LookinAttrSec_NSWindow_AnimationBehavior, attributes: [LookinAttr_NSWindow_Behavior_AnimationBehavior]),
            Section(identifier: LookinAttrSec_NSWindow_Info, attributes: [LookinAttr_NSWindow_Info_BackingScaleFactor]),
        ]),
        Group(identifier: LookinAttrGroup_NSSlider, sections: [
            Section(identifier: LookinAttrSec_NSSlider_SliderType, attributes: [LookinAttr_NSSlider_SliderType_SliderType]),
            Section(identifier: LookinAttrSec_NSSlider_Range, attributes: [LookinAttr_NSSlider_Range_MinValue, LookinAttr_NSSlider_Range_MaxValue]),
            Section(identifier: LookinAttrSec_NSSlider_TickMark, attributes: [
                LookinAttr_NSSlider_TickMark_NumberOfTickMarks, LookinAttr_NSSlider_TickMark_TickMarkPosition,
                LookinAttr_NSSlider_TickMark_AllowsTickMarkValuesOnly,
            ]),
        ]),
        Group(identifier: LookinAttrGroup_NSProgressIndicator, sections: [
            Section(identifier: LookinAttrSec_NSProgressIndicator_Style, attributes: [LookinAttr_NSProgressIndicator_Style_Style]),
            Section(identifier: LookinAttrSec_NSProgressIndicator_Range, attributes: [
                LookinAttr_NSProgressIndicator_Range_MinValue, LookinAttr_NSProgressIndicator_Range_MaxValue,
                LookinAttr_NSProgressIndicator_Range_DoubleValue,
            ]),
            Section(identifier: LookinAttrSec_NSProgressIndicator_Misc, attributes: [
                LookinAttr_NSProgressIndicator_Misc_Indeterminate, LookinAttr_NSProgressIndicator_Misc_Bezeled,
                LookinAttr_NSProgressIndicator_Misc_DisplayedWhenStopped,
            ]),
        ]),
        Group(identifier: LookinAttrGroup_NSSegmentedControl, sections: [
            Section(identifier: LookinAttrSec_NSSegmentedControl_SegmentCount, attributes: [LookinAttr_NSSegmentedControl_SegmentCount_SegmentCount]),
            Section(identifier: LookinAttrSec_NSSegmentedControl_Selection, attributes: [LookinAttr_NSSegmentedControl_Selection_SelectedSegment]),
            Section(identifier: LookinAttrSec_NSSegmentedControl_Style, attributes: [
                LookinAttr_NSSegmentedControl_Style_SegmentStyle, LookinAttr_NSSegmentedControl_Style_TrackingMode,
            ]),
        ]),
        Group(identifier: LookinAttrGroup_NSPopUpButton, sections: [
            Section(identifier: LookinAttrSec_NSPopUpButton_Behavior, attributes: [LookinAttr_NSPopUpButton_Behavior_PreferredEdge]),
        ]),
        Group(identifier: LookinAttrGroup_NSComboBox, sections: [
            Section(identifier: LookinAttrSec_NSComboBox_Items, attributes: [LookinAttr_NSComboBox_Items_NumberOfVisibleItems]),
            Section(identifier: LookinAttrSec_NSComboBox_Misc, attributes: [
                LookinAttr_NSComboBox_Misc_ButtonBordered, LookinAttr_NSComboBox_Misc_Completes, LookinAttr_NSComboBox_Misc_UsesDataSource,
            ]),
        ]),
        Group(identifier: LookinAttrGroup_NSStepper, sections: [
            Section(identifier: LookinAttrSec_NSStepper_Range, attributes: [
                LookinAttr_NSStepper_Range_MinValue, LookinAttr_NSStepper_Range_MaxValue, LookinAttr_NSStepper_Range_Increment,
            ]),
            Section(identifier: LookinAttrSec_NSStepper_Misc, attributes: [LookinAttr_NSStepper_Misc_ValueWraps, LookinAttr_NSStepper_Misc_Autorepeat]),
        ]),
        Group(identifier: LookinAttrGroup_NSOutlineView, sections: [
            Section(identifier: LookinAttrSec_NSOutlineView_Indentation, attributes: [LookinAttr_NSOutlineView_Indentation_IndentationPerLevel]),
            Section(identifier: LookinAttrSec_NSOutlineView_Misc, attributes: [
                LookinAttr_NSOutlineView_Misc_AutoresizesOutlineColumn, LookinAttr_NSOutlineView_Misc_IndentationMarkerFollowsCell,
                LookinAttr_NSOutlineView_Misc_AutosaveExpandedItems,
            ]),
        ]),
        Group(identifier: LookinAttrGroup_NSCollectionView, sections: [
            Section(identifier: LookinAttrSec_NSCollectionView_Selection, attributes: [
                LookinAttr_NSCollectionView_Selection_Selectable, LookinAttr_NSCollectionView_Selection_AllowsMultipleSelection,
                LookinAttr_NSCollectionView_Selection_AllowsEmptySelection,
            ]),
        ]),
        Group(identifier: LookinAttrGroup_NSBox, sections: [
            Section(identifier: LookinAttrSec_NSBox_Type, attributes: [LookinAttr_NSBox_Type_BoxType, LookinAttr_NSBox_Type_BorderType]),
            Section(identifier: LookinAttrSec_NSBox_Title, attributes: [LookinAttr_NSBox_Title_Title, LookinAttr_NSBox_Title_TitlePosition]),
            Section(identifier: LookinAttrSec_NSBox_Appearance, attributes: [
                LookinAttr_NSBox_Appearance_Transparent, LookinAttr_NSBox_Appearance_FillColor, LookinAttr_NSBox_Appearance_BorderColor,
            ]),
            Section(identifier: LookinAttrSec_NSBox_Metrics, attributes: [
                LookinAttr_NSBox_Metrics_BorderWidth, LookinAttr_NSBox_Metrics_CornerRadius, LookinAttr_NSBox_Metrics_ContentViewMargins,
            ]),
        ]),
        Group(identifier: LookinAttrGroup_NSSplitView, sections: [
            Section(identifier: LookinAttrSec_NSSplitView_Orientation, attributes: [LookinAttr_NSSplitView_Orientation_Vertical]),
            Section(identifier: LookinAttrSec_NSSplitView_Style, attributes: [
                LookinAttr_NSSplitView_Style_DividerStyle, LookinAttr_NSSplitView_Style_DividerThickness,
            ]),
        ]),
        Group(identifier: LookinAttrGroup_NSCell, sections: [
            Section(identifier: LookinAttrSec_NSCell_Cell, attributes: [
                LookinAttr_NSCell_Cell_Enabled, LookinAttr_NSCell_Cell_Bordered, LookinAttr_NSCell_Cell_Bezeled, LookinAttr_NSCell_Cell_Editable,
                LookinAttr_NSCell_Cell_Alignment, LookinAttr_NSCell_Cell_ControlSize,
            ]),
            Section(identifier: LookinAttrSec_NSCell_Content, attributes: [
                LookinAttr_NSCell_Content_Title, LookinAttr_NSCell_Content_FontName, LookinAttr_NSCell_Content_FontSize,
                LookinAttr_NSCell_Content_LineBreakMode,
            ]),
            Section(identifier: LookinAttrSec_NSCell_Behavior, attributes: [
                LookinAttr_NSCell_Behavior_Continuous, LookinAttr_NSCell_Behavior_AllowsMixedState,
                LookinAttr_NSCell_Behavior_SendsActionOnEndEditing,
            ]),
            Section(identifier: LookinAttrSec_NSCell_ButtonCell, attributes: [LookinAttr_NSCell_ButtonCell_BezelStyle]),
            Section(identifier: LookinAttrSec_NSCell_TextFieldCell, attributes: [LookinAttr_NSCell_TextFieldCell_Placeholder]),
        ]),
        Group(identifier: LookinAttrGroup_LayoutGuide, sections: [
            Section(identifier: LookinAttrSec_LayoutGuide_Identifier, attributes: [LookinAttr_LayoutGuide_Identifier_Identifier]),
            Section(identifier: LookinAttrSec_LayoutGuide_LayoutFrame, attributes: [LookinAttr_LayoutGuide_LayoutFrame_LayoutFrame]),
            Section(identifier: LookinAttrSec_LayoutGuide_OwningView, attributes: [LookinAttr_LayoutGuide_OwningView_OwningView]),
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
    static let specifications: [String: XcodeViewHierarchyAttributeSpecification] = [
        // Layout. AppKit records a view's frame on the view and its layer's
        // on the layer, and the two differ under flipping; the view's is the
        // one the inspector's other cards are built from.
        LookinAttr_Layout_Frame_Frame: Specification(anyViewOrWindow, .rect, "frame", source: .nodeThenLayer),
        LookinAttr_Layout_Bounds_Bounds: Specification(anyViewOrWindow, .rect, "bounds", source: .nodeThenLayer),
        LookinAttr_Layout_Position_Position: Specification(anyView, .point, "position", source: .layerThenNode),
        LookinAttr_Layout_AnchorPoint_AnchorPoint: Specification(anyView, .point, "anchorPoint", source: .layerThenNode),
        LookinAttr_Layout_CoordinateSpace_CoordinateSpace: Specification(["UIWindowScene"], .rect, "bounds"),

        // Auto Layout sizing
        LookinAttr_AutoLayout_Hugging_Hor: Specification(anyView, .number, "contentHuggingPriorityHorizontal"),
        LookinAttr_AutoLayout_Hugging_Ver: Specification(anyView, .number, "contentHuggingPriorityVertical"),
        LookinAttr_AutoLayout_Resistance_Hor: Specification(anyView, .number, "contentCompressionResistancePriorityHorizontal"),
        LookinAttr_AutoLayout_Resistance_Ver: Specification(anyView, .number, "contentCompressionResistancePriorityVertical"),

        // View / layer
        LookinAttr_ViewLayer_Visibility_Hidden: Specification(anyView, .bool, "hidden", source: .nodeThenLayer),
        LookinAttr_ViewLayer_Visibility_Opacity: Specification(anyView, .number, "alpha", "alphaValue", "opacity", source: .nodeThenLayer),
        LookinAttr_ViewLayer_InterationAndMasks_Interaction: Specification(["UIView"], .bool, "userInteractionEnabled"),
        LookinAttr_ViewLayer_InterationAndMasks_MasksToBounds: Specification(anyView, .bool, "masksToBounds", "clipsToBounds", source: .layerThenNode),
        LookinAttr_ViewLayer_BgColor_BgColor: Specification(anyView, .color, "backgroundColor", source: .layerThenNode),
        LookinAttr_ViewLayer_Border_Color: Specification(anyView, .color, "borderColor", source: .layer),
        LookinAttr_ViewLayer_Border_Width: Specification(anyView, .number, "borderWidth", source: .layer),
        LookinAttr_ViewLayer_Corner_Radius: Specification(anyView, .number, "cornerRadius", source: .layerThenNode),
        LookinAttr_ViewLayer_Shadow_Color: Specification(anyView, .color, "shadowColor", source: .layer),
        LookinAttr_ViewLayer_Shadow_Opacity: Specification(anyView, .number, "shadowOpacity", source: .layer),
        LookinAttr_ViewLayer_Shadow_Radius: Specification(anyView, .number, "shadowRadius", source: .layer),
        LookinAttr_ViewLayer_Shadow_OffsetW: Specification(anyView, .sizeWidth, "shadowOffset", source: .layer),
        LookinAttr_ViewLayer_Shadow_OffsetH: Specification(anyView, .sizeHeight, "shadowOffset", source: .layer),
        LookinAttr_ViewLayer_Tag_Tag: Specification(anyView, .integer, "tag"),
        LookinAttr_ViewLayer_ContentMode_Mode: Specification(["UIView"], .integer, "contentMode"),
        LookinAttr_ViewLayer_TintColor_Color: Specification(["UIView"], .color, "tintColor"),
        LookinAttr_ViewLayer_TintColor_Mode: Specification(["UIView"], .integer, "tintAdjustmentMode"),

        // UIKit
        LookinAttr_UIStackView_Axis_Axis: Specification(["UIStackView"], .integer, "axis"),
        LookinAttr_UIStackView_Distribution_Distribution: Specification(["UIStackView"], .integer, "distribution"),
        LookinAttr_UIStackView_Alignment_Alignment: Specification(["UIStackView"], .integer, "alignment"),
        LookinAttr_UIStackView_Spacing_Spacing: Specification(["UIStackView"], .number, "spacing"),

        LookinAttr_UIImageView_Name_Name: Specification(["UIImageView"], .imageName, "image"),
        LookinAttr_UIImageView_Open_Open: Specification(["UIImageView"], .imageData, "image"),

        LookinAttr_UILabel_Text_Text: Specification(["UILabel"], .text, "text"),
        LookinAttr_UILabel_Font_Name: Specification(["UILabel"], .fontName, "font"),
        LookinAttr_UILabel_Font_Size: Specification(["UILabel"], .fontSize, "font"),
        LookinAttr_UILabel_NumberOfLines_NumberOfLines: Specification(["UILabel"], .integer, "numberOfLines"),
        LookinAttr_UILabel_TextColor_Color: Specification(["UILabel"], .color, "textColor"),
        LookinAttr_UILabel_BreakMode_Mode: Specification(["UILabel"], .integer, "lineBreakMode"),
        LookinAttr_UILabel_Alignment_Alignment: Specification(["UILabel"], .integer, "textAlignment"),
        LookinAttr_UILabel_CanAdjustFont_CanAdjustFont: Specification(["UILabel"], .bool, "adjustsFontSizeToFitWidth"),

        LookinAttr_UIControl_EnabledSelected_Enabled: Specification(["UIControl"], .bool, "enabled"),
        LookinAttr_UIControl_EnabledSelected_Selected: Specification(["UIControl"], .bool, "selected"),
        LookinAttr_UIControl_VerAlignment_Alignment: Specification(["UIControl"], .integer, "contentVerticalAlignment"),
        LookinAttr_UIControl_HorAlignment_Alignment: Specification(["UIControl"], .integer, "contentHorizontalAlignment"),

        LookinAttr_UIButton_ContentInsets_Insets: Specification(["UIButton"], .insets, "contentEdgeInsets"),
        LookinAttr_UIButton_TitleInsets_Insets: Specification(["UIButton"], .insets, "titleEdgeInsets"),
        LookinAttr_UIButton_ImageInsets_Insets: Specification(["UIButton"], .insets, "imageEdgeInsets"),

        LookinAttr_UIScrollView_ShowsIndicator_Hor: Specification(["UIScrollView"], .bool, "showsHorizontalScrollIndicator"),
        LookinAttr_UIScrollView_ShowsIndicator_Ver: Specification(["UIScrollView"], .bool, "showsVerticalScrollIndicator"),
        LookinAttr_UIScrollView_Bounce_Hor: Specification(["UIScrollView"], .bool, "alwaysBounceHorizontal"),
        LookinAttr_UIScrollView_Bounce_Ver: Specification(["UIScrollView"], .bool, "alwaysBounceVertical"),
        LookinAttr_UIScrollView_ScrollPaging_ScrollEnabled: Specification(["UIScrollView"], .bool, "scrollEnabled"),
        LookinAttr_UIScrollView_ScrollPaging_PagingEnabled: Specification(["UIScrollView"], .bool, "pagingEnabled"),
        LookinAttr_UIScrollView_ContentTouches_Delay: Specification(["UIScrollView"], .bool, "delaysContentTouches"),
        LookinAttr_UIScrollView_ContentTouches_CanCancel: Specification(["UIScrollView"], .bool, "canCancelContentTouches"),
        LookinAttr_UIScrollView_Zoom_Bounce: Specification(["UIScrollView"], .bool, "bouncesZoom"),
        LookinAttr_UIScrollView_Zoom_MinScale: Specification(["UIScrollView"], .number, "minimumZoomScale"),
        LookinAttr_UIScrollView_Zoom_MaxScale: Specification(["UIScrollView"], .number, "maximumZoomScale"),

        LookinAttr_UITableView_Style_Style: Specification(["UITableView"], .integer, "style"),
        LookinAttr_UITableView_SectionsNumber_Number: Specification(["UITableView"], .integer, "numberOfSections"),
        LookinAttr_UITableView_SeparatorStyle_Style: Specification(["UITableView"], .integer, "separatorStyle"),
        LookinAttr_UITableView_SeparatorColor_Color: Specification(["UITableView"], .color, "separatorColor"),
        LookinAttr_UITableView_SeparatorInset_Inset: Specification(["UITableView"], .insets, "separatorInset"),

        LookinAttr_UITextView_Basic_Editable: Specification(["UITextView"], .bool, "editable"),
        LookinAttr_UITextView_Basic_Selectable: Specification(["UITextView"], .bool, "selectable"),
        LookinAttr_UITextView_Text_Text: Specification(["UITextView"], .text, "text"),
        LookinAttr_UITextView_Font_Name: Specification(["UITextView"], .fontName, "font"),
        LookinAttr_UITextView_Font_Size: Specification(["UITextView"], .fontSize, "font"),
        LookinAttr_UITextView_TextColor_Color: Specification(["UITextView"], .color, "textColor"),
        LookinAttr_UITextView_Alignment_Alignment: Specification(["UITextView"], .integer, "textAlignment"),

        LookinAttr_UITextField_Text_Text: Specification(["UITextField"], .text, "text"),
        LookinAttr_UITextField_Placeholder_Placeholder: Specification(["UITextField"], .text, "placeholder"),
        LookinAttr_UITextField_Font_Name: Specification(["UITextField"], .fontName, "font"),
        LookinAttr_UITextField_Font_Size: Specification(["UITextField"], .fontSize, "font"),
        LookinAttr_UITextField_TextColor_Color: Specification(["UITextField"], .color, "textColor"),
        LookinAttr_UITextField_Alignment_Alignment: Specification(["UITextField"], .integer, "textAlignment"),
        LookinAttr_UITextField_Clears_ClearsOnBeginEditing: Specification(["UITextField"], .bool, "clearsOnBeginEditing"),
        LookinAttr_UITextField_CanAdjustFont_CanAdjustFont: Specification(["UITextField"], .bool, "adjustsFontSizeToFitWidth"),
        LookinAttr_UITextField_CanAdjustFont_MinSize: Specification(["UITextField"], .number, "minimumFontSize"),
        LookinAttr_UITextField_ClearButtonMode_Mode: Specification(["UITextField"], .integer, "clearButtonMode"),

        LookinAttr_UIWindowScene_State_ActivationState: Specification(["UIWindowScene"], .integer, "activationState"),
        LookinAttr_UIWindowScene_Title_Title: Specification(["UIWindowScene"], .text, "title"),
        LookinAttr_UIWindowScene_Title_Subtitle: Specification(["UIWindowScene"], .text, "subtitle"),
        LookinAttr_UIWindowScene_Orientation_InterfaceOrientation: Specification(["UIWindowScene"], .integer, "interfaceOrientation"),
        LookinAttr_UIWindowScene_Screen_ScreenBounds: Specification(["UIWindowScene"], .rect, "bounds", source: .screen),
        LookinAttr_UIWindowScene_Screen_ScreenScale: Specification(["UIWindowScene"], .number, "scale", source: .screen),
        LookinAttr_UIWindowScene_Traits_UserInterfaceStyle: Specification(["UIWindowScene"], .integer, "traitCollectionUserInterfaceStyle"),
        LookinAttr_UIWindowScene_Traits_HorizontalSizeClass: Specification(["UIWindowScene"], .integer, "traitCollectionHorizontalSizeClass"),
        LookinAttr_UIWindowScene_Traits_VerticalSizeClass: Specification(["UIWindowScene"], .integer, "traitCollectionVerticalSizeClass"),
        LookinAttr_UIWindowScene_Traits_LayoutDirection: Specification(["UIWindowScene"], .integer, "traitCollectionLayoutDirection"),

        LookinAttr_UITraitCollection_Appearance_UserInterfaceStyle: Specification(["UIView"], .integer, "traitCollectionUserInterfaceStyle"),
        LookinAttr_UITraitCollection_SizeClass_HorizontalSizeClass: Specification(["UIView"], .integer, "traitCollectionHorizontalSizeClass"),
        LookinAttr_UITraitCollection_SizeClass_VerticalSizeClass: Specification(["UIView"], .integer, "traitCollectionVerticalSizeClass"),
        LookinAttr_UITraitCollection_Layout_LayoutDirection: Specification(["UIView"], .integer, "traitCollectionLayoutDirection"),

        // AppKit
        LookinAttr_NSImageView_Name_Name: Specification(["NSImageView"], .imageName, "image"),
        LookinAttr_NSImageView_Open_Open: Specification(["NSImageView"], .imageData, "image"),
        LookinAttr_NSImageView_Scaling_ImageScaling: Specification(["NSImageView"], .integer, "imageScaling"),
        LookinAttr_NSImageView_Scaling_ImageAlignment: Specification(["NSImageView"], .integer, "imageAlignment"),
        LookinAttr_NSImageView_Scaling_ImageFrameStyle: Specification(["NSImageView"], .integer, "imageFrameStyle"),
        LookinAttr_NSImageView_Behavior_Animates: Specification(["NSImageView"], .bool, "animates"),
        LookinAttr_NSImageView_Behavior_Editable: Specification(["NSImageView"], .bool, "editable"),
        LookinAttr_NSImageView_ContentTintColor_ContentTintColor: Specification(["NSImageView"], .color, "contentTintColor"),

        LookinAttr_NSControl_State_Enabled: Specification(["NSControl"], .bool, "enabled"),
        LookinAttr_NSControl_State_Highlighted: Specification(["NSControl"], .bool, "highlighted"),
        LookinAttr_NSControl_State_Continuous: Specification(["NSControl"], .bool, "continuous"),
        LookinAttr_NSControl_ControlSize_Size: Specification(["NSControl"], .integer, "controlSize"),
        LookinAttr_NSControl_Font_Name: Specification(["NSControl"], .fontName, "font"),
        LookinAttr_NSControl_Font_Size: Specification(["NSControl"], .fontSize, "font"),
        LookinAttr_NSControl_Alignment_Alignment: Specification(["NSControl"], .integer, "alignment"),
        LookinAttr_NSControl_Misc_WritingDirection: Specification(["NSControl"], .integer, "baseWritingDirection"),
        LookinAttr_NSControl_Misc_UsesSingleLineMode: Specification(["NSControl"], .bool, "usesSingleLineMode", source: .cell),
        LookinAttr_NSControl_Misc_AllowsExpansionToolTips: Specification(["NSControl"], .bool, "allowsExpansionToolTips"),
        LookinAttr_NSControl_Value_DoubleValue: Specification(["NSControl"], .number, "doubleValue"),

        LookinAttr_NSButton_ButtonType_ButtonType: Specification(["NSButton"], .integer, "_buttonType", source: .cell),
        LookinAttr_NSButton_BezelStyle_BezelStyle: Specification(["NSButton"], .integer, "bezelStyle", source: .cell),
        LookinAttr_NSButton_Title_Title: Specification(["NSButton"], .text, "title"),
        LookinAttr_NSButton_Title_AlernateTitle: Specification(["NSButton"], .text, "alternateTitle"),
        LookinAttr_NSButton_Bordered_Bordered: Specification(["NSButton"], .bool, "bordered", source: .cell),
        LookinAttr_NSButton_Transparent_Transparent: Specification(["NSButton"], .bool, "transparent", source: .cell),
        LookinAttr_NSButton_Misc_SpringLoaded: Specification(["NSButton"], .bool, "springLoaded"),
        LookinAttr_NSButton_ContentTintColor_ContentTintColor: Specification(["NSButton"], .color, "contentTintColor"),

        LookinAttr_NSScrollView_BorderType_BorderType: Specification(["NSScrollView"], .integer, "borderType"),
        LookinAttr_NSScrollView_Scroller_Horizontal: Specification(["NSScrollView"], .bool, "hasHorizontalScroller"),
        LookinAttr_NSScrollView_Scroller_Vertical: Specification(["NSScrollView"], .bool, "hasVerticalScroller"),
        LookinAttr_NSScrollView_Scroller_AutohidesScrollers: Specification(["NSScrollView"], .bool, "autohidesScrollers"),
        LookinAttr_NSScrollView_Scroller_ScrollerKnobStyle: Specification(["NSScrollView"], .integer, "scrollerKnobStyle"),
        LookinAttr_NSScrollView_LineScroll_Horizontal: Specification(["NSScrollView"], .number, "horizontalLineScroll"),
        LookinAttr_NSScrollView_LineScroll_Vertical: Specification(["NSScrollView"], .number, "verticalLineScroll"),
        LookinAttr_NSScrollView_PageScroll_Horizontal: Specification(["NSScrollView"], .number, "horizontalPageScroll"),
        LookinAttr_NSScrollView_PageScroll_Vertical: Specification(["NSScrollView"], .number, "verticalPageScroll"),
        LookinAttr_NSScrollView_ScrollElasiticity_Horizontal: Specification(["NSScrollView"], .integer, "horizontalScrollElasticity"),
        LookinAttr_NSScrollView_ScrollElasiticity_Vertical: Specification(["NSScrollView"], .integer, "verticalScrollElasticity"),
        LookinAttr_NSScrollView_Misc_UsesPredominantAxisScrolling: Specification(["NSScrollView"], .bool, "usesPredominantAxisScrolling"),
        LookinAttr_NSScrollView_Magnification_AllowsMagnification: Specification(["NSScrollView"], .bool, "allowsMagnification"),
        LookinAttr_NSScrollView_Magnification_Max: Specification(["NSScrollView"], .number, "maxMagnification"),
        LookinAttr_NSScrollView_Magnification_Min: Specification(["NSScrollView"], .number, "minMagnification"),

        LookinAttr_NSTableView_RowHeight_RowHeight: Specification(["NSTableView"], .number, "rowHeight"),
        LookinAttr_NSTableView_IntercellSpacing_IntercellSpacing: Specification(["NSTableView"], .size, "intercellSpacing"),
        LookinAttr_NSTableView_ColumnAutoresizingStyle_ColumnAutoresizingStyle: Specification(["NSTableView"], .integer, "columnAutoresizingStyle"),
        LookinAttr_NSTableView_GridStyleMask_GridStyleMask: Specification(["NSTableView"], .integer, "gridStyleMask"),
        LookinAttr_NSTableView_SelectionHighlightStyle_SelectionHighlightStyle: Specification(["NSTableView"], .integer, "selectionHighlightStyle"),
        LookinAttr_NSTableView_GridColor_GridColor: Specification(["NSTableView"], .color, "gridColor"),
        LookinAttr_NSTableView_RowSizeStyle_RowSizeStyle: Specification(["NSTableView"], .integer, "rowSizeStyle"),
        LookinAttr_NSTableView_NumberOfColumns_NumberOfColumns: Specification(["NSTableView"], .integer, "numberOfTableColumns"),
        LookinAttr_NSTableView_UseAlternatingRowBackgroundColors_UseAlternatingRowBackgroundColors: Specification(["NSTableView"], .bool, "usesAlternatingRowBackgroundColors"),
        LookinAttr_NSTableView_AllowsColumnReordering_AllowsColumnReordering: Specification(["NSTableView"], .bool, "allowsColumnReordering"),
        LookinAttr_NSTableView_AllowsColumnResizing_AllowsColumnResizing: Specification(["NSTableView"], .bool, "allowsColumnResizing"),
        LookinAttr_NSTableView_AllowsMultipleSelection_AllowsMultipleSelection: Specification(["NSTableView"], .bool, "allowsMultipleSelection"),
        LookinAttr_NSTableView_AllowsEmptySelection_AllowsEmptySelection: Specification(["NSTableView"], .bool, "allowsEmptySelection"),
        LookinAttr_NSTableView_AllowsColumnSelection_AllowsColumnSelection: Specification(["NSTableView"], .bool, "allowsColumnSelection"),
        LookinAttr_NSTableView_AllowsTypeSelect_AllowsTypeSelect: Specification(["NSTableView"], .bool, "allowsTypeSelect"),
        LookinAttr_NSTableView_AutosaveName_AutosaveName: Specification(["NSTableView"], .text, "autosaveName"),
        LookinAttr_NSTableView_AutosaveTableColumns_AutosaveTableColumns: Specification(["NSTableView"], .bool, "autosaveTableColumns"),
        LookinAttr_NSTableView_FloatsGroupRows_FloatsGroupRows: Specification(["NSTableView"], .bool, "floatsGroupRows"),

        LookinAttr_NSTextView_Basic_Editable: Specification(["NSTextView"], .bool, "editable"),
        LookinAttr_NSTextView_Basic_Selectable: Specification(["NSTextView"], .bool, "selectable"),
        LookinAttr_NSTextView_Basic_RichText: Specification(["NSTextView"], .bool, "richText"),
        LookinAttr_NSTextView_Basic_FieldEditor: Specification(["NSTextView"], .bool, "fieldEditor"),
        LookinAttr_NSTextView_Basic_ImportsGraphics: Specification(["NSTextView"], .bool, "importsGraphics"),
        LookinAttr_NSTextView_String_String: Specification(["NSTextView"], .text, "textStorage"),
        LookinAttr_NSTextView_TextColor_Color: Specification(["NSTextView"], .color, "textColor"),
        LookinAttr_NSTextView_BaseWritingDirection_BaseWritingDirection: Specification(["NSTextView"], .integer, "baseWritingDirection"),

        LookinAttr_NSTextField_Bordered_Bordered: Specification(["NSTextField"], .bool, "bordered"),
        LookinAttr_NSTextField_Bezeled_Bezeled: Specification(["NSTextField"], .bool, "bezeled"),
        LookinAttr_NSTextField_Editable_Editable: Specification(["NSTextField"], .bool, "editable"),
        LookinAttr_NSTextField_DrawsBackground_DrawsBackground: Specification(["NSTextField"], .bool, "drawsBackground"),
        LookinAttr_NSTextField_AllowsEditingTextAttributes_AllowsEditingTextAttributes: Specification(["NSTextField"], .bool, "allowsEditingTextAttributes"),
        LookinAttr_NSTextField_TextColor_Color: Specification(["NSTextField"], .color, "textColor"),
        LookinAttr_NSTextField_BackgroundColor_Color: Specification(["NSTextField"], .color, "backgroundColor"),
        LookinAttr_NSTextField_Placeholder_Placeholder: Specification(["NSTextField"], .text, "placeholderString", source: .cell),

        LookinAttr_NSVisualEffectView_Material_Material: Specification(["NSVisualEffectView"], .integer, "material"),
        LookinAttr_NSVisualEffectView_InteriorBackgroundStyle_InteriorBackgroundStyle: Specification(["NSVisualEffectView"], .integer, "interiorBackgroundStyle"),
        LookinAttr_NSVisualEffectView_BlendingMode_BlendingMode: Specification(["NSVisualEffectView"], .integer, "blendingMode"),
        LookinAttr_NSVisualEffectView_State_State: Specification(["NSVisualEffectView"], .integer, "state"),
        LookinAttr_NSVisualEffectView_Emphasized_Emphasized: Specification(["NSVisualEffectView"], .bool, "emphasized"),

        LookinAttr_NSStackView_Orientation_Orientation: Specification(["NSStackView"], .integer, "orientation"),
        LookinAttr_NSStackView_EdgeInsets_EdgeInsets: Specification(["NSStackView"], .insets, "edgeInsets"),
        LookinAttr_NSStackView_Distribution_Distribution: Specification(["NSStackView"], .integer, "distribution"),
        LookinAttr_NSStackView_Alignment_Alignment: Specification(["NSStackView"], .integer, "alignment"),
        LookinAttr_NSStackView_Spacing_Spacing: Specification(["NSStackView"], .number, "spacing"),

        LookinAttr_NSWindow_Title_Title: Specification(["NSWindow"], .text, "title"),
        LookinAttr_NSWindow_State_KeyWindow: Specification(["NSWindow"], .bool, "isKeyWindow"),
        LookinAttr_NSWindow_State_MainWindow: Specification(["NSWindow"], .bool, "isMainWindow"),
        LookinAttr_NSWindow_State_Visible: Specification(["NSWindow"], .bool, "visible"),
        LookinAttr_NSWindow_Style_Titled: Specification(["NSWindow"], styleMask(.titled), "styleMask"),
        LookinAttr_NSWindow_Style_Closable: Specification(["NSWindow"], styleMask(.closable), "styleMask"),
        LookinAttr_NSWindow_Style_Miniaturizable: Specification(["NSWindow"], styleMask(.miniaturizable), "styleMask"),
        LookinAttr_NSWindow_Style_Resizable: Specification(["NSWindow"], styleMask(.resizable), "styleMask"),
        LookinAttr_NSWindow_Style_UnifiedTitleAndToolbar: Specification(["NSWindow"], styleMask(.unifiedTitleAndToolbar), "styleMask"),
        LookinAttr_NSWindow_Style_FullScreen: Specification(["NSWindow"], styleMask(.fullScreen), "styleMask"),
        LookinAttr_NSWindow_Style_FullSizeContentView: Specification(["NSWindow"], styleMask(.fullSizeContentView), "styleMask"),
        LookinAttr_NSWindow_Style_UtilityWindow: Specification(["NSWindow"], styleMask(.utilityWindow), "styleMask"),
        LookinAttr_NSWindow_Style_DocModalWindow: Specification(["NSWindow"], styleMask(.docModalWindow), "styleMask"),
        LookinAttr_NSWindow_Style_NonactivatingPanel: Specification(["NSWindow"], styleMask(.nonactivatingPanel), "styleMask"),
        LookinAttr_NSWindow_Style_HUDWindow: Specification(["NSWindow"], styleMask(.hudWindow), "styleMask"),
        LookinAttr_NSWindow_CollectionBehavior_CanJoinAllSpaces: Specification(["NSWindow"], collectionBehavior(.canJoinAllSpaces), "collectionBehavior"),
        LookinAttr_NSWindow_CollectionBehavior_MoveToActiveSpace: Specification(["NSWindow"], collectionBehavior(.moveToActiveSpace), "collectionBehavior"),
        LookinAttr_NSWindow_CollectionBehavior_ParticipatesInCycle: Specification(["NSWindow"], collectionBehavior(.participatesInCycle), "collectionBehavior"),
        LookinAttr_NSWindow_CollectionBehavior_IgnoresCycle: Specification(["NSWindow"], collectionBehavior(.ignoresCycle), "collectionBehavior"),
        LookinAttr_NSWindow_CollectionBehavior_FullScreenPrimary: Specification(["NSWindow"], collectionBehavior(.fullScreenPrimary), "collectionBehavior"),
        LookinAttr_NSWindow_CollectionBehavior_FullScreenAuxiliary: Specification(["NSWindow"], collectionBehavior(.fullScreenAuxiliary), "collectionBehavior"),
        LookinAttr_NSWindow_CollectionBehavior_FullScreenNone: Specification(["NSWindow"], collectionBehavior(.fullScreenNone), "collectionBehavior"),
        LookinAttr_NSWindow_CollectionBehavior_FullScreenAllowsTiling: Specification(["NSWindow"], collectionBehavior(.fullScreenAllowsTiling), "collectionBehavior"),
        LookinAttr_NSWindow_CollectionBehavior_FullScreenDisallowsTiling: Specification(["NSWindow"], collectionBehavior(.fullScreenDisallowsTiling), "collectionBehavior"),
        LookinAttr_NSWindow_Appearance_AlphaValue: Specification(["NSWindow"], .number, "alphaValue"),
        LookinAttr_NSWindow_Appearance_Opaque: Specification(["NSWindow"], .bool, "isOpaque"),
        LookinAttr_NSWindow_Appearance_HasShadow: Specification(["NSWindow"], .bool, "hasShadow"),
        LookinAttr_NSWindow_Behavior_HidesOnDeactivate: Specification(["NSWindow"], .bool, "hidesOnDeactivate"),
        LookinAttr_NSWindow_Behavior_AnimationBehavior: Specification(["NSWindow"], .integer, "animationBehavior"),
        LookinAttr_NSWindow_Info_BackingScaleFactor: Specification(["NSWindow"], .number, "backingScaleFactor"),

        LookinAttr_NSSlider_SliderType_SliderType: Specification(["NSSlider"], .integer, "sliderType"),
        LookinAttr_NSSlider_Range_MinValue: Specification(["NSSlider"], .number, "minValue"),
        LookinAttr_NSSlider_Range_MaxValue: Specification(["NSSlider"], .number, "maxValue"),
        LookinAttr_NSSlider_TickMark_NumberOfTickMarks: Specification(["NSSlider"], .integer, "numberOfTickMarks"),
        LookinAttr_NSSlider_TickMark_TickMarkPosition: Specification(["NSSlider"], .integer, "tickMarkPosition"),
        LookinAttr_NSSlider_TickMark_AllowsTickMarkValuesOnly: Specification(["NSSlider"], .bool, "allowsTickMarkValuesOnly"),

        LookinAttr_NSProgressIndicator_Style_Style: Specification(["NSProgressIndicator"], .integer, "style"),
        LookinAttr_NSProgressIndicator_Range_MinValue: Specification(["NSProgressIndicator"], .number, "minValue"),
        LookinAttr_NSProgressIndicator_Range_MaxValue: Specification(["NSProgressIndicator"], .number, "maxValue"),
        LookinAttr_NSProgressIndicator_Range_DoubleValue: Specification(["NSProgressIndicator"], .number, "doubleValue"),
        LookinAttr_NSProgressIndicator_Misc_Indeterminate: Specification(["NSProgressIndicator"], .bool, "indeterminate"),
        LookinAttr_NSProgressIndicator_Misc_Bezeled: Specification(["NSProgressIndicator"], .bool, "bezeled"),
        LookinAttr_NSProgressIndicator_Misc_DisplayedWhenStopped: Specification(["NSProgressIndicator"], .bool, "displayedWhenStopped"),

        LookinAttr_NSSegmentedControl_SegmentCount_SegmentCount: Specification(["NSSegmentedControl"], .integer, "segmentCount"),
        LookinAttr_NSSegmentedControl_Selection_SelectedSegment: Specification(["NSSegmentedControl"], .integer, "selectedSegment"),
        LookinAttr_NSSegmentedControl_Style_SegmentStyle: Specification(["NSSegmentedControl"], .integer, "segmentStyle"),
        LookinAttr_NSSegmentedControl_Style_TrackingMode: Specification(["NSSegmentedControl"], .integer, "trackingMode"),

        LookinAttr_NSPopUpButton_Behavior_PreferredEdge: Specification(["NSPopUpButton"], .integer, "preferredEdge"),

        LookinAttr_NSComboBox_Items_NumberOfVisibleItems: Specification(["NSComboBox"], .integer, "numberOfVisibleItems"),
        LookinAttr_NSComboBox_Misc_ButtonBordered: Specification(["NSComboBox"], .bool, "buttonBordered"),
        LookinAttr_NSComboBox_Misc_Completes: Specification(["NSComboBox"], .bool, "completes"),
        LookinAttr_NSComboBox_Misc_UsesDataSource: Specification(["NSComboBox"], .bool, "usesDataSource"),

        LookinAttr_NSStepper_Range_MinValue: Specification(["NSStepper"], .number, "minValue"),
        LookinAttr_NSStepper_Range_MaxValue: Specification(["NSStepper"], .number, "maxValue"),
        LookinAttr_NSStepper_Range_Increment: Specification(["NSStepper"], .number, "increment"),
        LookinAttr_NSStepper_Misc_ValueWraps: Specification(["NSStepper"], .bool, "valueWraps"),
        LookinAttr_NSStepper_Misc_Autorepeat: Specification(["NSStepper"], .bool, "autorepeat"),

        LookinAttr_NSOutlineView_Indentation_IndentationPerLevel: Specification(["NSOutlineView"], .number, "indentationPerLevel"),
        LookinAttr_NSOutlineView_Misc_AutoresizesOutlineColumn: Specification(["NSOutlineView"], .bool, "autoresizesOutlineColumn"),
        LookinAttr_NSOutlineView_Misc_IndentationMarkerFollowsCell: Specification(["NSOutlineView"], .bool, "indentationMarkerFollowsCell"),
        LookinAttr_NSOutlineView_Misc_AutosaveExpandedItems: Specification(["NSOutlineView"], .bool, "autosaveExpandedItems"),

        LookinAttr_NSCollectionView_Selection_Selectable: Specification(["NSCollectionView"], .bool, "selectable"),
        LookinAttr_NSCollectionView_Selection_AllowsMultipleSelection: Specification(["NSCollectionView"], .bool, "allowsMultipleSelection"),
        LookinAttr_NSCollectionView_Selection_AllowsEmptySelection: Specification(["NSCollectionView"], .bool, "allowsEmptySelection"),

        LookinAttr_NSBox_Type_BoxType: Specification(["NSBox"], .integer, "boxType"),
        LookinAttr_NSBox_Type_BorderType: Specification(["NSBox"], .integer, "borderType"),
        LookinAttr_NSBox_Title_Title: Specification(["NSBox"], .text, "title"),
        LookinAttr_NSBox_Title_TitlePosition: Specification(["NSBox"], .integer, "titlePosition"),
        LookinAttr_NSBox_Appearance_Transparent: Specification(["NSBox"], .bool, "transparent"),
        LookinAttr_NSBox_Appearance_FillColor: Specification(["NSBox"], .color, "fillColor"),
        LookinAttr_NSBox_Appearance_BorderColor: Specification(["NSBox"], .color, "borderColor"),
        LookinAttr_NSBox_Metrics_BorderWidth: Specification(["NSBox"], .number, "borderWidth"),
        LookinAttr_NSBox_Metrics_CornerRadius: Specification(["NSBox"], .number, "cornerRadius"),
        LookinAttr_NSBox_Metrics_ContentViewMargins: Specification(["NSBox"], .size, "contentViewMargins"),

        LookinAttr_NSSplitView_Orientation_Vertical: Specification(["NSSplitView"], .bool, "vertical"),
        LookinAttr_NSSplitView_Style_DividerStyle: Specification(["NSSplitView"], .integer, "dividerStyle"),
        LookinAttr_NSSplitView_Style_DividerThickness: Specification(["NSSplitView"], .number, "dividerThickness"),

        // AppKit cells, read on the cell node itself
        LookinAttr_NSCell_Cell_Enabled: Specification(["NSCell"], .bool, "enabled"),
        LookinAttr_NSCell_Cell_Bordered: Specification(["NSCell"], .bool, "bordered"),
        LookinAttr_NSCell_Cell_Bezeled: Specification(["NSCell"], .bool, "bezeled"),
        LookinAttr_NSCell_Cell_Editable: Specification(["NSCell"], .bool, "editable"),
        LookinAttr_NSCell_Cell_Alignment: Specification(["NSCell"], .integer, "alignment"),
        LookinAttr_NSCell_Cell_ControlSize: Specification(["NSCell"], .integer, "controlSize"),
        LookinAttr_NSCell_Content_Title: Specification(["NSCell"], .text, "title"),
        LookinAttr_NSCell_Content_FontName: Specification(["NSCell"], .fontName, "font"),
        LookinAttr_NSCell_Content_FontSize: Specification(["NSCell"], .fontSize, "font"),
        LookinAttr_NSCell_Content_LineBreakMode: Specification(["NSCell"], .integer, "lineBreakMode"),
        LookinAttr_NSCell_Behavior_Continuous: Specification(["NSCell"], .bool, "continuous"),
        LookinAttr_NSCell_Behavior_AllowsMixedState: Specification(["NSCell"], .bool, "allowsMixedState"),
        LookinAttr_NSCell_Behavior_SendsActionOnEndEditing: Specification(["NSCell"], .bool, "sendsActionOnEndEditing"),
        LookinAttr_NSCell_ButtonCell_BezelStyle: Specification(["NSButtonCell"], .integer, "bezelStyle"),
        LookinAttr_NSCell_TextFieldCell_Placeholder: Specification(["NSTextFieldCell"], .text, "placeholderString"),

        // Layout guides
        LookinAttr_LayoutGuide_Identifier_Identifier: Specification(["UILayoutGuide", "NSLayoutGuide"], .text, "identifier"),
        LookinAttr_LayoutGuide_LayoutFrame_LayoutFrame: Specification(["UILayoutGuide", "NSLayoutGuide"], .rect, "layoutFrame", "frame"),
    ]
}
