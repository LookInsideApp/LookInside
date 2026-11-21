//
//  DashboardBlueprint+AppKitGroups.swift
//  LookinCore
//
//  The groups only AppKit lists. The NSCell group's sections are on both
//  platforms, as they always were, so its section list answers on iOS too.
//  Each group lists its sections and each section its attributes, in display
//  order; DashboardBlueprintCatalog.swift explains the entry types and how the
//  lookup tables are derived. A section or attribute without `on:` is on the
//  platforms of the group or section it belongs to.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation

    extension DashboardBlueprintTables {
        static let nsImageViewGroup = BlueprintGroup(LookinAttrGroup_NSImageView, title: "NSImageView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSImageView_Name, title: "ImageName", attributes: [
                BlueprintAttribute(LookinAttr_NSImageView_Name_Name, AttributeInfo(className: "NSImageView", fullTitle: "ImageName", getterString: "lks_imageSourceName", setterString: "", typeIfObj: .nsString, hideIfNil: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSImageView_Open, title: "Open", attributes: [
                BlueprintAttribute(LookinAttr_NSImageView_Open_Open, AttributeInfo(className: "NSImageView", getterString: "lks_imageViewOidIfHasImage", setterString: "", typeIfObj: .customObj, hideIfNil: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSImageView_Scaling, title: "Scaling", attributes: [
                BlueprintAttribute(LookinAttr_NSImageView_Scaling_ImageScaling, AttributeInfo(className: "NSImageView", fullTitle: "ImageScaling", enumList: "NSImageScaling", patch: true)),
                BlueprintAttribute(LookinAttr_NSImageView_Scaling_ImageAlignment, AttributeInfo(className: "NSImageView", fullTitle: "ImageAlignment", enumList: "NSImageAlignment", patch: true)),
                BlueprintAttribute(LookinAttr_NSImageView_Scaling_ImageFrameStyle, AttributeInfo(className: "NSImageView", fullTitle: "ImageFrameStyle", enumList: "NSImageFrameStyle", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSImageView_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_NSImageView_Behavior_Animates, AttributeInfo(className: "NSImageView", fullTitle: "Animates", patch: true)),
                BlueprintAttribute(LookinAttr_NSImageView_Behavior_Editable, AttributeInfo(className: "NSImageView", fullTitle: "Editable", getterString: "isEditable", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSImageView_ContentTintColor, title: "ContentTintColor", attributes: [
                BlueprintAttribute(LookinAttr_NSImageView_ContentTintColor_ContentTintColor, AttributeInfo(className: "NSImageView", fullTitle: "ContentTintColor", typeIfObj: .uiColor, patch: true)),
            ]),
        ])

        static let nsControlGroup = BlueprintGroup(LookinAttrGroup_NSControl, title: "NSControl", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSControl_State, title: "State", attributes: [
                BlueprintAttribute(LookinAttr_NSControl_State_Enabled, AttributeInfo(className: "NSControl", fullTitle: "Enabled", getterString: "isEnabled", patch: true)),
                BlueprintAttribute(LookinAttr_NSControl_State_Highlighted, AttributeInfo(className: "NSControl", fullTitle: "Highlighted", getterString: "isHighlighted", patch: true)),
                BlueprintAttribute(LookinAttr_NSControl_State_Continuous, AttributeInfo(className: "NSControl", fullTitle: "Continuous", getterString: "isContinuous", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_NSControl_ControlSize, title: "ControlSize", attributes: [
                BlueprintAttribute(LookinAttr_NSControl_ControlSize_Size, AttributeInfo(className: "NSControl", fullTitle: "ControlSize", enumList: "NSControlSize", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSControl_Font, title: "Font", attributes: [
                BlueprintAttribute(LookinAttr_NSControl_Font_Name, AttributeInfo(className: "NSControl", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", typeIfObj: .nsString, patch: false)),
                BlueprintAttribute(LookinAttr_NSControl_Font_Size, AttributeInfo(className: "NSControl", fullTitle: "FontSize", getterString: "lks_fontSize", setterString: "setLks_fontSize:", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSControl_Alignment, title: "Alignment", attributes: [
                BlueprintAttribute(LookinAttr_NSControl_Alignment_Alignment, AttributeInfo(className: "NSControl", fullTitle: "Alignment", enumList: "NSTextAlignment_AppKit", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSControl_Misc, title: "Misc", attributes: [
                BlueprintAttribute(LookinAttr_NSControl_Misc_WritingDirection, AttributeInfo(className: "NSControl", fullTitle: "BaseWritingDirection", enumList: "NSWritingDirection", patch: false)),
                BlueprintAttribute(LookinAttr_NSControl_Misc_IgnoresMultiClick, AttributeInfo(className: "NSControl", fullTitle: "IgnoresMultiClick", patch: false)),
                BlueprintAttribute(LookinAttr_NSControl_Misc_UsesSingleLineMode, AttributeInfo(className: "NSControl", fullTitle: "UsesSingleLineMode", patch: false)),
                BlueprintAttribute(LookinAttr_NSControl_Misc_AllowsExpansionToolTips, AttributeInfo(className: "NSControl", fullTitle: "AllowsExpansionToolTips", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_NSControl_StringValue, title: "StringValue", attributes: [
                BlueprintAttribute(LookinAttr_NSControl_Value_StringValue, AttributeInfo(className: "NSControl", fullTitle: "StringValue", typeIfObj: .nsString, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSControl_Value, title: "Value", attributes: [
                BlueprintAttribute(LookinAttr_NSControl_Value_IntValue, AttributeInfo(className: "NSControl", fullTitle: "IntValue", patch: true)),
                BlueprintAttribute(LookinAttr_NSControl_Value_IntegerValue, AttributeInfo(className: "NSControl", fullTitle: "IntegerValue", patch: true)),
                BlueprintAttribute(LookinAttr_NSControl_Value_FloatValue, AttributeInfo(className: "NSControl", fullTitle: "FloatValue", patch: true)),
                BlueprintAttribute(LookinAttr_NSControl_Value_DoubleValue, AttributeInfo(className: "NSControl", fullTitle: "DoubleValue", patch: true)),
            ]),
        ])

        static let nsButtonGroup = BlueprintGroup(LookinAttrGroup_NSButton, title: "NSButton", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSButton_ButtonType, title: "ButtonType", attributes: [
                BlueprintAttribute(LookinAttr_NSButton_ButtonType_ButtonType, AttributeInfo(className: "NSButton", fullTitle: "ButtonType", getterString: "lks_buttonType", enumList: "NSButtonType", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSButton_BezelStyle, title: "BezelStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSButton_BezelStyle_BezelStyle, AttributeInfo(className: "NSButton", fullTitle: "BezelStyle", enumList: "NSBezelStyle", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSButton_Title, title: "Title", attributes: [
                BlueprintAttribute(LookinAttr_NSButton_Title_Title, AttributeInfo(className: "NSButton", fullTitle: "Title", typeIfObj: .nsString, patch: true)),
                BlueprintAttribute(LookinAttr_NSButton_Title_AlernateTitle, AttributeInfo(className: "NSButton", fullTitle: "AlternateTitle", typeIfObj: .nsString, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSButton_Bordered, attributes: [
                BlueprintAttribute(LookinAttr_NSButton_Bordered_Bordered, AttributeInfo(className: "NSButton", fullTitle: "Bordered", getterString: "isBordered", patch: true)),
                BlueprintAttribute(LookinAttr_NSButton_Transparent_Transparent, AttributeInfo(className: "NSButton", fullTitle: "Transparent", getterString: "isTransparent", patch: true)),
                BlueprintAttribute(LookinAttr_NSButton_Misc_ShowsBorderOnlyWhileMouseInside, AttributeInfo(className: "NSButton", fullTitle: "ShowsBorderOnlyWhileMouseInside", patch: true)),
                // Derived getter would be -springLoaded; the property is -isSpringLoaded.
                BlueprintAttribute(LookinAttr_NSButton_Misc_SpringLoaded, AttributeInfo(className: "NSButton", fullTitle: "SpringLoaded", getterString: "isSpringLoaded", patch: true)),
                BlueprintAttribute(LookinAttr_NSButton_Misc_HasDestructiveAction, AttributeInfo(className: "NSButton", fullTitle: "HasDestructiveAction", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSButton_BezelColor, title: "Colors", attributes: [
                BlueprintAttribute(LookinAttr_NSButton_BezelColor_BezelColor, AttributeInfo(className: "NSButton", fullTitle: "BezelColor", typeIfObj: .uiColor, patch: true)),
                BlueprintAttribute(LookinAttr_NSButton_ContentTintColor_ContentTintColor, AttributeInfo(className: "NSButton", fullTitle: "ContentTintColor", typeIfObj: .uiColor, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSButton_Misc, title: "Misc", attributes: [
                BlueprintAttribute(LookinAttr_NSButton_Misc_MaxAcceleratorLevel, AttributeInfo(className: "NSButton", fullTitle: "MaxAcceleratorLevel", patch: true)),
            ]),
        ])

        static let nsScrollViewGroup = BlueprintGroup(LookinAttrGroup_NSScrollView, title: "NSScrollView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSScrollView_ContentOffset, title: "ContentOffset", attributes: [
                BlueprintAttribute(LookinAttr_NSScrollView_ContentOffset_Offset, AttributeInfo(className: "NSScrollView", fullTitle: "ContentOffset", getterString: "lks_contentOffset", setterString: "lks_setContentOffset:", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSScrollView_ContentSize, title: "ContentSize", attributes: [
                BlueprintAttribute(LookinAttr_NSScrollView_ContentSize_Size, AttributeInfo(className: "NSScrollView", fullTitle: "ContentSize", getterString: "lks_contentSize", setterString: "lks_setContentSize:", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSScrollView_ContentInset, title: "ContentInset", attributes: [
                BlueprintAttribute(LookinAttr_NSScrollView_ContentInset_ContentInset, AttributeInfo(className: "NSScrollView", fullTitle: "ContentInset", patch: true)),
                BlueprintAttribute(LookinAttr_NSScrollView_ContentInset_AutomaticallyAdjustsContentInsets, AttributeInfo(className: "NSScrollView", fullTitle: "AutomaticallyAdjustsContentInsets", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSScrollView_BorderType, title: "BorderType", attributes: [
                BlueprintAttribute(LookinAttr_NSScrollView_BorderType_BorderType, AttributeInfo(className: "NSScrollView", fullTitle: "BorderType", enumList: "NSBorderType", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSScrollView_Scroller, title: "Scroller", attributes: [
                BlueprintAttribute(LookinAttr_NSScrollView_Scroller_Horizontal, AttributeInfo(className: "NSScrollView", fullTitle: "HasHorizontalScroller", patch: true)),
                BlueprintAttribute(LookinAttr_NSScrollView_Scroller_Vertical, AttributeInfo(className: "NSScrollView", fullTitle: "HasVerticalScroller", patch: true)),
                BlueprintAttribute(LookinAttr_NSScrollView_Scroller_AutohidesScrollers, AttributeInfo(className: "NSScrollView", fullTitle: "AutohidesScrollers", patch: true)),
                BlueprintAttribute(LookinAttr_NSScrollView_Scroller_ScrollerStyle, AttributeInfo(className: "NSScrollView", fullTitle: "ScrollerStyle", enumList: "NSScrollerStyle", patch: true)),
                BlueprintAttribute(LookinAttr_NSScrollView_Scroller_ScrollerKnobStyle, AttributeInfo(className: "NSScrollView", fullTitle: "ScrollerKnobStyle", enumList: "NSScrollerKnobStyle", patch: true)),
                BlueprintAttribute(LookinAttr_NSScrollView_Scroller_ScrollerInsets, AttributeInfo(className: "NSScrollView", fullTitle: "ScrollerInsets", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSScrollView_Ruler, title: "Ruler", attributes: [
                BlueprintAttribute(LookinAttr_NSScrollView_Ruler_Horizontal, AttributeInfo(className: "NSScrollView", fullTitle: "HasHorizontalRuler", patch: true)),
                BlueprintAttribute(LookinAttr_NSScrollView_Ruler_Vertical, AttributeInfo(className: "NSScrollView", fullTitle: "HasVerticalRuler", patch: true)),
                BlueprintAttribute(LookinAttr_NSScrollView_Ruler_Visible, AttributeInfo(className: "NSScrollView", fullTitle: "RulersVisible", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSScrollView_LineScroll, title: "LineScroll", attributes: [
                // briefTitle is display-only and never crosses the wire. These six
                // sit three-to-a-row with the label inside the field, so the section
                // title carries the meaning ("LineScroll") and the field only marks
                // the axis — the same shape as the scroller inset row above.
                BlueprintAttribute(LookinAttr_NSScrollView_LineScroll_Horizontal, AttributeInfo(className: "NSScrollView", fullTitle: "HorizontalLineScroll", briefTitle: "H", patch: true)),
                BlueprintAttribute(LookinAttr_NSScrollView_LineScroll_Vertical, AttributeInfo(className: "NSScrollView", fullTitle: "VerticalLineScroll", briefTitle: "V", patch: true)),
                BlueprintAttribute(LookinAttr_NSScrollView_LineScroll_LineScroll, AttributeInfo(className: "NSScrollView", fullTitle: "LineScroll", briefTitle: "⇄", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSScrollView_PageScroll, title: "PageScroll", attributes: [
                BlueprintAttribute(LookinAttr_NSScrollView_PageScroll_Horizontal, AttributeInfo(className: "NSScrollView", fullTitle: "HorizontalPageScroll", briefTitle: "H", patch: true)),
                BlueprintAttribute(LookinAttr_NSScrollView_PageScroll_Vertical, AttributeInfo(className: "NSScrollView", fullTitle: "VerticalPageScroll", briefTitle: "V", patch: true)),
                BlueprintAttribute(LookinAttr_NSScrollView_PageScroll_PageScroll, AttributeInfo(className: "NSScrollView", fullTitle: "PageScroll", briefTitle: "⇄", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSScrollView_ScrollElasiticity, title: "ScrollElasiticity", attributes: [
                BlueprintAttribute(LookinAttr_NSScrollView_ScrollElasiticity_Horizontal, AttributeInfo(className: "NSScrollView", fullTitle: "HorizontalScrollElasticity", enumList: "NSScrollElasticity", patch: true)),
                BlueprintAttribute(LookinAttr_NSScrollView_ScrollElasiticity_Vertical, AttributeInfo(className: "NSScrollView", fullTitle: "VerticalScrollElasticity", enumList: "NSScrollElasticity", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSScrollView_Misc, title: "Misc", attributes: [
                BlueprintAttribute(LookinAttr_NSScrollView_Misc_ScrollsDynamically, AttributeInfo(className: "NSScrollView", fullTitle: "ScrollsDynamically", patch: true)),
                BlueprintAttribute(LookinAttr_NSScrollView_Misc_UsesPredominantAxisScrolling, AttributeInfo(className: "NSScrollView", fullTitle: "UsesPredominantAxisScrolling", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSScrollView_Magnification, title: "Magnification", attributes: [
                BlueprintAttribute(LookinAttr_NSScrollView_Magnification_AllowsMagnification, AttributeInfo(className: "NSScrollView", fullTitle: "AllowsMagnification", patch: true)),
                // Three to a row under the AllowsMagnification switch; the section
                // title already says "Magnification", so the fields only need to
                // say which of the three values they are.
                BlueprintAttribute(LookinAttr_NSScrollView_Magnification_Magnification, AttributeInfo(className: "NSScrollView", fullTitle: "Magnification", briefTitle: "Current", patch: true)),
                // Explicit getter/setter: the derived names would be
                // -maximunMagnification / -minimumMagnification, and NSScrollView
                // spells them -maxMagnification / -minMagnification. Deriving them
                // produced selectors nobody responds to, so both rows silently read
                // as nil and never appeared in the dashboard at all.
                BlueprintAttribute(LookinAttr_NSScrollView_Magnification_Max, AttributeInfo(className: "NSScrollView", fullTitle: "MaximumMagnification", briefTitle: "Max", getterString: "maxMagnification", setterString: "setMaxMagnification:", patch: true)),
                BlueprintAttribute(LookinAttr_NSScrollView_Magnification_Min, AttributeInfo(className: "NSScrollView", fullTitle: "MinimumMagnification", briefTitle: "Min", getterString: "minMagnification", setterString: "setMinMagnification:", patch: true)),
            ]),
        ])

        static let nsTableViewGroup = BlueprintGroup(LookinAttrGroup_NSTableView, title: "NSTableView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSTableView_RowHeight, title: "RowHeight", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_RowHeight_RowHeight, AttributeInfo(className: "NSTableView", fullTitle: "RowHeight", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_AutomaticRowHeights, title: "AutomaticRowHeights", attributes: [
                // NSTableView spells this usesAutomaticRowHeights, so both the
                // derived getter and the derived setter miss.
                BlueprintAttribute(LookinAttr_NSTableView_AutomaticRowHeights_AutomaticRowHeights, AttributeInfo(className: "NSTableView", fullTitle: "AutomaticRowHeights", getterString: "usesAutomaticRowHeights", setterString: "setUsesAutomaticRowHeights:", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_IntercellSpacing, title: "IntercellSpacing", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_IntercellSpacing_IntercellSpacing, AttributeInfo(className: "NSTableView", fullTitle: "IntercellSpacing", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_Style, title: "Style", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_Style_Style, AttributeInfo(className: "NSTableView", fullTitle: "Style", enumList: "NSTableViewStyle", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_ColumnAutoresizingStyle, title: "ColumnAutoresizingStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_ColumnAutoresizingStyle_ColumnAutoresizingStyle, AttributeInfo(className: "NSTableView", fullTitle: "ColumnAutoresizingStyle", enumList: "NSTableViewColumnAutoresizingStyle", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_GridStyleMask, title: "GridStyleMask", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_GridStyleMask_GridStyleMask, AttributeInfo(className: "NSTableView", fullTitle: "GridStyleMask", enumList: "NSTableViewGridLineStyle", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_SelectionHighlightStyle, title: "SelectionHighlightStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_SelectionHighlightStyle_SelectionHighlightStyle, AttributeInfo(className: "NSTableView", fullTitle: "SelectionHighlightStyle", enumList: "NSTableViewSelectionHighlightStyle", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_GridColor, title: "GridColor", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_GridColor_GridColor, AttributeInfo(className: "NSTableView", fullTitle: "GridColor", typeIfObj: .uiColor, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_RowSizeStyle, title: "RowSizeStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_RowSizeStyle_RowSizeStyle, AttributeInfo(className: "NSTableView", fullTitle: "RowSizeStyle", enumList: "NSTableViewRowSizeStyle", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_NumberOfRows, title: "NumberOfRows", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_NumberOfRows_NumberOfRows, AttributeInfo(className: "NSTableView", fullTitle: "NumberOfRows", setterString: "", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_NumberOfColumns, title: "NumberOfColumns", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_NumberOfColumns_NumberOfColumns, AttributeInfo(className: "NSTableView", fullTitle: "NumberOfColumns", setterString: "", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_UseAlternatingRowBackgroundColors, title: "UseAlternatingRowBackgroundColors", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_UseAlternatingRowBackgroundColors_UseAlternatingRowBackgroundColors, AttributeInfo(className: "NSTableView", fullTitle: "UsesAlternatingRowBackgroundColors", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_AllowsColumnReordering, title: "AllowsColumnReordering", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_AllowsColumnReordering_AllowsColumnReordering, AttributeInfo(className: "NSTableView", fullTitle: "AllowsColumnReordering", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_AllowsColumnResizing, title: "AllowsColumnResizing", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_AllowsColumnResizing_AllowsColumnResizing, AttributeInfo(className: "NSTableView", fullTitle: "AllowsColumnResizing", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_AllowsMultipleSelection, title: "AllowsMultipleSelection", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_AllowsMultipleSelection_AllowsMultipleSelection, AttributeInfo(className: "NSTableView", fullTitle: "AllowsMultipleSelection", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_AllowsEmptySelection, title: "AllowsEmptySelection", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_AllowsEmptySelection_AllowsEmptySelection, AttributeInfo(className: "NSTableView", fullTitle: "AllowsEmptySelection", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_AllowsColumnSelection, title: "AllowsColumnSelection", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_AllowsColumnSelection_AllowsColumnSelection, AttributeInfo(className: "NSTableView", fullTitle: "AllowsColumnSelection", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_AllowsTypeSelect, title: "AllowsTypeSelect", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_AllowsTypeSelect_AllowsTypeSelect, AttributeInfo(className: "NSTableView", fullTitle: "AllowsTypeSelect", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_DraggingDestinationFeedbackStyle, title: "DraggingDestinationFeedbackStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_DraggingDestinationFeedbackStyle_DraggingDestinationFeedbackStyle, AttributeInfo(className: "NSTableView", fullTitle: "DraggingDestinationFeedbackStyle", enumList: "NSTableViewDraggingDestinationFeedbackStyle", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_Autosave, title: "Autosave", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_AutosaveName_AutosaveName, AttributeInfo(className: "NSTableView", fullTitle: "AutosaveName", typeIfObj: .nsString, patch: true)),
                BlueprintAttribute(LookinAttr_NSTableView_AutosaveTableColumns_AutosaveTableColumns, AttributeInfo(className: "NSTableView", fullTitle: "AutosaveTableColumns", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_FloatsGroupRows, title: "FloatsGroupRows", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_FloatsGroupRows_FloatsGroupRows, AttributeInfo(className: "NSTableView", fullTitle: "FloatsGroupRows", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_RowActionsVisible, title: "RowActionsVisible", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_RowActionsVisible_RowActionsVisible, AttributeInfo(className: "NSTableView", fullTitle: "RowActionsVisible", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_UsesStaticContents, title: "UsesStaticContents", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_UsesStaticContents_UsesStaticContents, AttributeInfo(className: "NSTableView", fullTitle: "UsesStaticContents", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_UserInterfaceLayoutDirection, title: "UserInterfaceLayoutDirection", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_UserInterfaceLayoutDirection_UserInterfaceLayoutDirection, AttributeInfo(className: "NSTableView", fullTitle: "UserInterfaceLayoutDirection", enumList: "NSUserInterfaceLayoutDirection", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_VerticalMotionCanBeginDrag, title: "VerticalMotionCanBeginDrag", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_VerticalMotionCanBeginDrag_VerticalMotionCanBeginDrag, AttributeInfo(className: "NSTableView", fullTitle: "VerticalMotionCanBeginDrag", patch: true)),
            ]),
        ])

        static let nsTextViewGroup = BlueprintGroup(LookinAttrGroup_NSTextView, title: "NSTextView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSTextView_Font, title: "Font", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_Font_Name, AttributeInfo(className: "NSTextView", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", typeIfObj: .nsString, patch: false)),
                BlueprintAttribute(LookinAttr_NSTextView_Font_Size, AttributeInfo(className: "NSTextView", fullTitle: "FontSize", getterString: "lks_fontSize", setterString: "setLks_fontSize:", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextView_Basic, title: "Basic", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_Basic_Editable, AttributeInfo(className: "NSTextView", fullTitle: "Editable", getterString: "isEditable", patch: false)),
                BlueprintAttribute(LookinAttr_NSTextView_Basic_Selectable, AttributeInfo(className: "NSTextView", fullTitle: "Selectable", getterString: "isSelectable", patch: false)),
                BlueprintAttribute(LookinAttr_NSTextView_Basic_RichText, AttributeInfo(className: "NSTextView", fullTitle: "RichText", getterString: "isRichText", patch: false)),
                BlueprintAttribute(LookinAttr_NSTextView_Basic_FieldEditor, AttributeInfo(className: "NSTextView", fullTitle: "FieldEditor", getterString: "isFieldEditor", patch: false)),
                BlueprintAttribute(LookinAttr_NSTextView_Basic_ImportsGraphics, AttributeInfo(className: "NSTextView", fullTitle: "ImportsGraphics", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextView_String, title: "String", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_String_String, AttributeInfo(className: "NSTextView", fullTitle: "String", typeIfObj: .nsString, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextView_TextColor, title: "TextColor", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_TextColor_Color, AttributeInfo(className: "NSTextView", fullTitle: "TextColor", typeIfObj: .uiColor, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextView_Alignment, title: "Alignment", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_Alignment_Alignment, AttributeInfo(className: "NSTextView", fullTitle: "Alignment", enumList: "NSTextAlignment_AppKit", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextView_ContainerInset, title: "ContainerInset", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_ContainerInset_Inset, AttributeInfo(className: "NSTextView", fullTitle: "TextContainerInset", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextView_BaseWritingDirection, title: "BaseWritingDirection", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_BaseWritingDirection_BaseWritingDirection, AttributeInfo(className: "NSTextView", fullTitle: "BaseWritingDirection", enumList: "NSWritingDirection", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextView_Size, title: "Size", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_MaxSize_MaxSize, AttributeInfo(className: "NSTextView", fullTitle: "MaxSize", patch: true)),
                BlueprintAttribute(LookinAttr_NSTextView_MinSize_MinSize, AttributeInfo(className: "NSTextView", fullTitle: "MinSize", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextView_Resizable, title: "Resizable", attributes: [
                // Derived getter would be -horizontallyResizable; it is -isHorizontallyResizable.
                BlueprintAttribute(LookinAttr_NSTextView_Resizable_Horizontal, AttributeInfo(className: "NSTextView", fullTitle: "HorizontallyResizable", getterString: "isHorizontallyResizable", patch: false)),
                // Derived getter would be -verticallyResizable; it is -isVerticallyResizable.
                BlueprintAttribute(LookinAttr_NSTextView_Resizable_Vertical, AttributeInfo(className: "NSTextView", fullTitle: "VerticallyResizable", getterString: "isVerticallyResizable", patch: false)),
            ]),
        ])

        static let nsTextFieldGroup = BlueprintGroup(LookinAttrGroup_NSTextField, title: "NSTextField", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSTextField_BezelStyle, title: "BezelStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSTextField_BezelStyle_BezelStyle, AttributeInfo(className: "NSTextField", fullTitle: "BezelStyle", enumList: "NSTextFieldBezelStyle", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextField_LineBreakStrategy, title: "LineBreakStrategy", attributes: [
                BlueprintAttribute(LookinAttr_NSTextField_LineBreakStrategy_LineBreakStrategy, AttributeInfo(className: "NSTextField", fullTitle: "LineBreakStrategy", enumList: "NSLineBreakStrategy", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextField_Bordered, attributes: [
                BlueprintAttribute(LookinAttr_NSTextField_Bordered_Bordered, AttributeInfo(className: "NSTextField", fullTitle: "Bordered", getterString: "isBordered", patch: false)),
                BlueprintAttribute(LookinAttr_NSTextField_Bezeled_Bezeled, AttributeInfo(className: "NSTextField", fullTitle: "Bezeled", getterString: "isBezeled", patch: false)),
                BlueprintAttribute(LookinAttr_NSTextField_Editable_Editable, AttributeInfo(className: "NSTextField", fullTitle: "Editable", getterString: "isEditable", patch: false)),
                BlueprintAttribute(LookinAttr_NSTextField_Selectable_Selectable, AttributeInfo(className: "NSTextField", fullTitle: "Selectable", getterString: "isSelectable", patch: false)),
                BlueprintAttribute(LookinAttr_NSTextField_DrawsBackground_DrawsBackground, AttributeInfo(className: "NSTextField", fullTitle: "DrawsBackground", patch: true)),
                BlueprintAttribute(LookinAttr_NSTextField_AllowsDefaultTighteningForTruncation_AllowsDefaultTighteningForTruncation, AttributeInfo(className: "NSTextField", fullTitle: "AllowsDefaultTighteningForTruncation", patch: true)),
                BlueprintAttribute(LookinAttr_NSTextField_AllowsEditingTextAttributes_AllowsEditingTextAttributes, AttributeInfo(className: "NSTextField", fullTitle: "AllowsEditingTextAttributes", patch: true)),
                BlueprintAttribute(LookinAttr_NSTextField_ImportsGraphics_ImportsGraphics, AttributeInfo(className: "NSTextField", fullTitle: "ImportsGraphics", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextField_TextColor, title: "Colors", attributes: [
                BlueprintAttribute(LookinAttr_NSTextField_TextColor_Color, AttributeInfo(className: "NSTextField", fullTitle: "TextColor", typeIfObj: .uiColor, patch: true)),
                BlueprintAttribute(LookinAttr_NSTextField_BackgroundColor_Color, AttributeInfo(className: "NSTextField", fullTitle: "BackgroundColor", typeIfObj: .uiColor, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextField_Placeholder, title: "Placeholder", attributes: [
                BlueprintAttribute(LookinAttr_NSTextField_Placeholder_Placeholder, AttributeInfo(className: "NSTextField", fullTitle: "PlaceholderString", typeIfObj: .nsString, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextField_PreferredMaxLayoutWidth, title: "Layout", attributes: [
                BlueprintAttribute(LookinAttr_NSTextField_PreferredMaxLayoutWidth_PreferredMaxLayoutWidth, AttributeInfo(className: "NSTextField", fullTitle: "PreferredMaxLayoutWidth", patch: true)),
                BlueprintAttribute(LookinAttr_NSTextField_MaximumNumberOfLines_MaximumNumberOfLines, AttributeInfo(className: "NSTextField", fullTitle: "MaximumNumberOfLines", patch: true)),
            ]),
        ])

        static let nsVisualEffectViewGroup = BlueprintGroup(LookinAttrGroup_NSVisualEffectView, title: "NSVisualEffectView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSVisualEffectView_Material, title: "Material", attributes: [
                BlueprintAttribute(LookinAttr_NSVisualEffectView_Material_Material, AttributeInfo(className: "NSVisualEffectView", fullTitle: "Material", enumList: "NSVisualEffectMaterial", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSVisualEffectView_InteriorBackgroundStyle, title: "InteriorBackgroundStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSVisualEffectView_InteriorBackgroundStyle_InteriorBackgroundStyle, AttributeInfo(className: "NSVisualEffectView", fullTitle: "InteriorBackgroundStyle", enumList: "NSBackgroundStyle", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSVisualEffectView_BlendingMode, title: "BlendingMode", attributes: [
                BlueprintAttribute(LookinAttr_NSVisualEffectView_BlendingMode_BlendingMode, AttributeInfo(className: "NSVisualEffectView", fullTitle: "BlendingMode", enumList: "NSVisualEffectBlendingMode", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSVisualEffectView_State, title: "State", attributes: [
                BlueprintAttribute(LookinAttr_NSVisualEffectView_State_State, AttributeInfo(className: "NSVisualEffectView", fullTitle: "State", enumList: "NSVisualEffectState", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSVisualEffectView_Emphasized, title: "Emphasized", attributes: [
                BlueprintAttribute(LookinAttr_NSVisualEffectView_Emphasized_Emphasized, AttributeInfo(className: "NSVisualEffectView", fullTitle: "Emphasized", getterString: "isEmphasized", patch: true)),
            ]),
        ])

        static let nsStackViewGroup = BlueprintGroup(LookinAttrGroup_NSStackView, title: "NSStackView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSStackView_Orientation, title: "Orientation", attributes: [
                BlueprintAttribute(LookinAttr_NSStackView_Orientation_Orientation, AttributeInfo(className: "NSStackView", fullTitle: "Orientation", enumList: "NSUserInterfaceLayoutOrientation", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSStackView_EdgeInsets, title: "EdgeInsets", attributes: [
                BlueprintAttribute(LookinAttr_NSStackView_EdgeInsets_EdgeInsets, AttributeInfo(className: "NSStackView", fullTitle: "EdgeInsets", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSStackView_DetachesHiddenViews, title: "DetachesHiddenViews", attributes: [
                BlueprintAttribute(LookinAttr_NSStackView_DetachesHiddenViews_DetachesHiddenViews, AttributeInfo(className: "NSStackView", fullTitle: "DetachesHiddenViews", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSStackView_Distribution, title: "Distribution", attributes: [
                BlueprintAttribute(LookinAttr_NSStackView_Distribution_Distribution, AttributeInfo(className: "NSStackView", fullTitle: "Distribution", enumList: "NSStackViewDistribution", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSStackView_Alignment, title: "Alignment", attributes: [
                BlueprintAttribute(LookinAttr_NSStackView_Alignment_Alignment, AttributeInfo(className: "NSStackView", fullTitle: "Alignment", enumList: "NSLayoutAttribute", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSStackView_Spacing, title: "Spacing", attributes: [
                BlueprintAttribute(LookinAttr_NSStackView_Spacing_Spacing, AttributeInfo(className: "NSStackView", fullTitle: "Spacing", patch: true)),
            ]),
        ])

        static let nsWindowGroup = BlueprintGroup(LookinAttrGroup_NSWindow, title: "NSWindow", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSWindow_Title, title: "Title", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_Title_Title, AttributeInfo(className: "NSWindow", fullTitle: "Title", typeIfObj: .nsString, patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_Subtitle, title: "Subtitle", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_Title_Subtitle, AttributeInfo(className: "NSWindow", fullTitle: "Subtitle", typeIfObj: .nsString, patch: false, osVersion: 11)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_State, title: "State", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_State_KeyWindow, AttributeInfo(className: "NSWindow", fullTitle: "KeyWindow", getterString: "isKeyWindow", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_State_MainWindow, AttributeInfo(className: "NSWindow", fullTitle: "MainWindow", getterString: "isMainWindow", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_State_Visible, AttributeInfo(className: "NSWindow", fullTitle: "Visible", getterString: "isVisible", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_State_CanBecomeKeyWindow, AttributeInfo(className: "NSWindow", fullTitle: "CanBecomeKeyWindow", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_State_CanBecomeMainWindow, AttributeInfo(className: "NSWindow", fullTitle: "CanBecomeMainWindow", setterString: "", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_Style, title: "StyleMask", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_Style_Titled, AttributeInfo(className: "NSWindow", fullTitle: "Titled", getterString: "lks_styleMaskTitled", setterString: "setLks_styleMaskTitled:", patch: true)),
                BlueprintAttribute(LookinAttr_NSWindow_Style_Closable, AttributeInfo(className: "NSWindow", fullTitle: "Closable", getterString: "lks_styleMaskClosable", setterString: "setLks_styleMaskClosable:", patch: true)),
                BlueprintAttribute(LookinAttr_NSWindow_Style_Miniaturizable, AttributeInfo(className: "NSWindow", fullTitle: "Miniaturizable", getterString: "lks_styleMaskMiniaturizable", setterString: "setLks_styleMaskMiniaturizable:", patch: true)),
                BlueprintAttribute(LookinAttr_NSWindow_Style_Resizable, AttributeInfo(className: "NSWindow", fullTitle: "Resizable", getterString: "lks_styleMaskResizable", setterString: "setLks_styleMaskResizable:", patch: true)),
                BlueprintAttribute(LookinAttr_NSWindow_Style_UnifiedTitleAndToolbar, AttributeInfo(className: "NSWindow", fullTitle: "UnifiedTitleAndToolbar", getterString: "lks_styleMaskUnifiedTitleAndToolbar", setterString: "setLks_styleMaskUnifiedTitleAndToolbar:", patch: true)),
                BlueprintAttribute(LookinAttr_NSWindow_Style_FullScreen, AttributeInfo(className: "NSWindow", fullTitle: "FullScreen", getterString: "lks_styleMaskFullScreen", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_Style_FullSizeContentView, AttributeInfo(className: "NSWindow", fullTitle: "FullSizeContentView", getterString: "lks_styleMaskFullSizeContentView", setterString: "setLks_styleMaskFullSizeContentView:", patch: true)),
                BlueprintAttribute(LookinAttr_NSWindow_Style_UtilityWindow, AttributeInfo(className: "NSWindow", fullTitle: "UtilityWindow", getterString: "lks_styleMaskUtilityWindow", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_Style_DocModalWindow, AttributeInfo(className: "NSWindow", fullTitle: "DocModalWindow", getterString: "lks_styleMaskDocModalWindow", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_Style_NonactivatingPanel, AttributeInfo(className: "NSWindow", fullTitle: "NonactivatingPanel", getterString: "lks_styleMaskNonactivatingPanel", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_Style_HUDWindow, AttributeInfo(className: "NSWindow", fullTitle: "HUDWindow", getterString: "lks_styleMaskHUDWindow", setterString: "", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_CollectionBehavior, title: "CollectionBehavior", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_CollectionBehavior_CanJoinAllSpaces, AttributeInfo(className: "NSWindow", fullTitle: "CanJoinAllSpaces", getterString: "lks_collectionBehaviorCanJoinAllSpaces", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_CollectionBehavior_MoveToActiveSpace, AttributeInfo(className: "NSWindow", fullTitle: "MoveToActiveSpace", getterString: "lks_collectionBehaviorMoveToActiveSpace", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_CollectionBehavior_ParticipatesInCycle, AttributeInfo(className: "NSWindow", fullTitle: "ParticipatesInCycle", getterString: "lks_collectionBehaviorParticipatesInCycle", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_CollectionBehavior_IgnoresCycle, AttributeInfo(className: "NSWindow", fullTitle: "IgnoresCycle", getterString: "lks_collectionBehaviorIgnoresCycle", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_CollectionBehavior_FullScreenPrimary, AttributeInfo(className: "NSWindow", fullTitle: "FullScreenPrimary", getterString: "lks_collectionBehaviorFullScreenPrimary", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_CollectionBehavior_FullScreenAuxiliary, AttributeInfo(className: "NSWindow", fullTitle: "FullScreenAuxiliary", getterString: "lks_collectionBehaviorFullScreenAuxiliary", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_CollectionBehavior_FullScreenNone, AttributeInfo(className: "NSWindow", fullTitle: "FullScreenNone", getterString: "lks_collectionBehaviorFullScreenNone", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_CollectionBehavior_FullScreenAllowsTiling, AttributeInfo(className: "NSWindow", fullTitle: "FullScreenAllowsTiling", getterString: "lks_collectionBehaviorFullScreenAllowsTiling", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_CollectionBehavior_FullScreenDisallowsTiling, AttributeInfo(className: "NSWindow", fullTitle: "FullScreenDisallowsTiling", getterString: "lks_collectionBehaviorFullScreenDisallowsTiling", setterString: "", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_Appearance, title: "Appearance", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_Appearance_TitlebarAppearsTransparent, AttributeInfo(className: "NSWindow", fullTitle: "TitlebarAppearsTransparent", patch: true)),
                BlueprintAttribute(LookinAttr_NSWindow_Appearance_BackgroundColor, AttributeInfo(className: "NSWindow", fullTitle: "BackgroundColor", typeIfObj: .uiColor, patch: true)),
                BlueprintAttribute(LookinAttr_NSWindow_Appearance_AlphaValue, AttributeInfo(className: "NSWindow", fullTitle: "AlphaValue", patch: true)),
                BlueprintAttribute(LookinAttr_NSWindow_Appearance_Opaque, AttributeInfo(className: "NSWindow", fullTitle: "Opaque", getterString: "isOpaque", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_Appearance_HasShadow, AttributeInfo(className: "NSWindow", fullTitle: "HasShadow", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_TitleVisibility, title: "TitleVisibility", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_Appearance_TitleVisibility, AttributeInfo(className: "NSWindow", fullTitle: "TitleVisibility", enumList: "NSWindowTitleVisibility", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_ToolbarStyle, title: "ToolbarStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_Appearance_ToolbarStyle, AttributeInfo(className: "NSWindow", fullTitle: "ToolbarStyle", enumList: "NSWindowToolbarStyle", patch: true, osVersion: 11)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_TitlebarSeparatorStyle, title: "TitlebarSeparatorStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_Appearance_TitlebarSeparatorStyle, AttributeInfo(className: "NSWindow", fullTitle: "TitlebarSeparatorStyle", enumList: "NSTitlebarSeparatorStyle", patch: true, osVersion: 11)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_Behavior_Movable, AttributeInfo(className: "NSWindow", fullTitle: "Movable", getterString: "isMovable", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_Behavior_MovableByWindowBackground, AttributeInfo(className: "NSWindow", fullTitle: "MovableByWindowBackground", getterString: "isMovableByWindowBackground", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_Behavior_HidesOnDeactivate, AttributeInfo(className: "NSWindow", fullTitle: "HidesOnDeactivate", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_AnimationBehavior, title: "AnimationBehavior", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_Behavior_AnimationBehavior, AttributeInfo(className: "NSWindow", fullTitle: "AnimationBehavior", enumList: "NSWindowAnimationBehavior", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_Level, title: "Level", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_Behavior_Level, AttributeInfo(className: "NSWindow", fullTitle: "Level", enumList: "NSWindowLevel", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_TabbingMode, title: "TabbingMode", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_Behavior_TabbingMode, AttributeInfo(className: "NSWindow", fullTitle: "TabbingMode", enumList: "NSWindowTabbingMode", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_Size, title: "Size", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_Size_MinSize, AttributeInfo(className: "NSWindow", fullTitle: "MinSize", patch: true)),
                BlueprintAttribute(LookinAttr_NSWindow_Size_MaxSize, AttributeInfo(className: "NSWindow", fullTitle: "MaxSize", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_Info, title: "Info", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_Info_WindowNumber, AttributeInfo(className: "NSWindow", fullTitle: "WindowNumber", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSWindow_Info_BackingScaleFactor, AttributeInfo(className: "NSWindow", fullTitle: "BackingScaleFactor", setterString: "", patch: false)),
            ]),
        ])

        static let nsSliderGroup = BlueprintGroup(LookinAttrGroup_NSSlider, title: "NSSlider", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSSlider_SliderType, title: "SliderType", attributes: [
                BlueprintAttribute(LookinAttr_NSSlider_SliderType_SliderType, AttributeInfo(className: "NSSlider", fullTitle: "SliderType", enumList: "NSSliderType", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSSlider_Range, title: "Range", attributes: [
                BlueprintAttribute(LookinAttr_NSSlider_Range_MinValue, AttributeInfo(className: "NSSlider", fullTitle: "MinValue", patch: true)),
                BlueprintAttribute(LookinAttr_NSSlider_Range_MaxValue, AttributeInfo(className: "NSSlider", fullTitle: "MaxValue", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSSlider_TickMark, title: "TickMark", attributes: [
                BlueprintAttribute(LookinAttr_NSSlider_TickMark_NumberOfTickMarks, AttributeInfo(className: "NSSlider", fullTitle: "NumberOfTickMarks", patch: true)),
                BlueprintAttribute(LookinAttr_NSSlider_TickMark_TickMarkPosition, AttributeInfo(className: "NSSlider", fullTitle: "TickMarkPosition", enumList: "NSTickMarkPosition", patch: true)),
                BlueprintAttribute(LookinAttr_NSSlider_TickMark_AllowsTickMarkValuesOnly, AttributeInfo(className: "NSSlider", fullTitle: "AllowsTickMarkValuesOnly", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSSlider_Misc, title: "Misc", attributes: [
                BlueprintAttribute(LookinAttr_NSSlider_Misc_Vertical, AttributeInfo(className: "NSSlider", fullTitle: "Vertical", getterString: "isVertical", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSSlider_Misc_KnobThickness, AttributeInfo(className: "NSSlider", fullTitle: "KnobThickness", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSSlider_Misc_AltIncrementValue, AttributeInfo(className: "NSSlider", fullTitle: "AltIncrementValue", patch: true)),
                BlueprintAttribute(LookinAttr_NSSlider_Misc_TrackFillColor, AttributeInfo(className: "NSSlider", fullTitle: "TrackFillColor", typeIfObj: .uiColor, patch: true, hideIfNil: true)),
            ]),
        ])

        static let nsProgressIndicatorGroup = BlueprintGroup(LookinAttrGroup_NSProgressIndicator, title: "NSProgressIndicator", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSProgressIndicator_Style, title: "Style", attributes: [
                BlueprintAttribute(LookinAttr_NSProgressIndicator_Style_Style, AttributeInfo(className: "NSProgressIndicator", fullTitle: "Style", enumList: "NSProgressIndicatorStyle", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSProgressIndicator_Range, title: "Range", attributes: [
                BlueprintAttribute(LookinAttr_NSProgressIndicator_Range_MinValue, AttributeInfo(className: "NSProgressIndicator", fullTitle: "MinValue", patch: true)),
                BlueprintAttribute(LookinAttr_NSProgressIndicator_Range_MaxValue, AttributeInfo(className: "NSProgressIndicator", fullTitle: "MaxValue", patch: true)),
                BlueprintAttribute(LookinAttr_NSProgressIndicator_Range_DoubleValue, AttributeInfo(className: "NSProgressIndicator", fullTitle: "DoubleValue", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSProgressIndicator_Misc, title: "Misc", attributes: [
                BlueprintAttribute(LookinAttr_NSProgressIndicator_Misc_Indeterminate, AttributeInfo(className: "NSProgressIndicator", fullTitle: "Indeterminate", getterString: "isIndeterminate", patch: true)),
                BlueprintAttribute(LookinAttr_NSProgressIndicator_Misc_Bezeled, AttributeInfo(className: "NSProgressIndicator", fullTitle: "Bezeled", getterString: "isBezeled", patch: true)),
                BlueprintAttribute(LookinAttr_NSProgressIndicator_Misc_DisplayedWhenStopped, AttributeInfo(className: "NSProgressIndicator", fullTitle: "DisplayedWhenStopped", getterString: "isDisplayedWhenStopped", patch: true)),
            ]),
        ])

        static let nsSegmentedControlGroup = BlueprintGroup(LookinAttrGroup_NSSegmentedControl, title: "NSSegmentedControl", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSSegmentedControl_SegmentCount, title: "SegmentCount", attributes: [
                BlueprintAttribute(LookinAttr_NSSegmentedControl_SegmentCount_SegmentCount, AttributeInfo(className: "NSSegmentedControl", fullTitle: "SegmentCount", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSSegmentedControl_Selection, title: "Selection", attributes: [
                BlueprintAttribute(LookinAttr_NSSegmentedControl_Selection_SelectedSegment, AttributeInfo(className: "NSSegmentedControl", fullTitle: "SelectedSegment", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSSegmentedControl_Style, title: "Style", attributes: [
                BlueprintAttribute(LookinAttr_NSSegmentedControl_Style_SegmentStyle, AttributeInfo(className: "NSSegmentedControl", fullTitle: "SegmentStyle", enumList: "NSSegmentStyle", patch: true)),
                BlueprintAttribute(LookinAttr_NSSegmentedControl_Style_TrackingMode, AttributeInfo(className: "NSSegmentedControl", fullTitle: "TrackingMode", enumList: "NSSegmentSwitchTracking", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSSegmentedControl_Colors, title: "Colors", attributes: [
                BlueprintAttribute(LookinAttr_NSSegmentedControl_Colors_SelectedSegmentBezelColor, AttributeInfo(className: "NSSegmentedControl", fullTitle: "SelectedSegmentBezelColor", typeIfObj: .uiColor, patch: true, hideIfNil: true)),
            ]),
        ])

        static let nsPopUpButtonGroup = BlueprintGroup(LookinAttrGroup_NSPopUpButton, title: "NSPopUpButton", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSPopUpButton_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_NSPopUpButton_Behavior_PullsDown, AttributeInfo(className: "NSPopUpButton", fullTitle: "PullsDown", patch: true)),
                BlueprintAttribute(LookinAttr_NSPopUpButton_Behavior_AutoenablesItems, AttributeInfo(className: "NSPopUpButton", fullTitle: "AutoenablesItems", patch: true)),
                BlueprintAttribute(LookinAttr_NSPopUpButton_Behavior_PreferredEdge, AttributeInfo(className: "NSPopUpButton", fullTitle: "PreferredEdge", enumList: "NSRectEdge", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSPopUpButton_Selection, title: "Selection", attributes: [
                BlueprintAttribute(LookinAttr_NSPopUpButton_Selection_SelectedTag, AttributeInfo(className: "NSPopUpButton", fullTitle: "SelectedTag", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSPopUpButton_Selection_IndexOfSelectedItem, AttributeInfo(className: "NSPopUpButton", fullTitle: "IndexOfSelectedItem", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSPopUpButton_Selection_TitleOfSelectedItem, AttributeInfo(className: "NSPopUpButton", fullTitle: "TitleOfSelectedItem", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSPopUpButton_Items, title: "Items", attributes: [
                BlueprintAttribute(LookinAttr_NSPopUpButton_Items_NumberOfItems, AttributeInfo(className: "NSPopUpButton", fullTitle: "NumberOfItems", setterString: "", patch: false)),
            ]),
        ])

        static let nsComboBoxGroup = BlueprintGroup(LookinAttrGroup_NSComboBox, title: "NSComboBox", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSComboBox_Items, title: "Items", attributes: [
                BlueprintAttribute(LookinAttr_NSComboBox_Items_NumberOfItems, AttributeInfo(className: "NSComboBox", fullTitle: "NumberOfItems", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSComboBox_Items_HasVerticalScroller, AttributeInfo(className: "NSComboBox", fullTitle: "HasVerticalScroller", patch: true)),
                BlueprintAttribute(LookinAttr_NSComboBox_Items_NumberOfVisibleItems, AttributeInfo(className: "NSComboBox", fullTitle: "NumberOfVisibleItems", patch: true)),
                BlueprintAttribute(LookinAttr_NSComboBox_Items_IntercellSpacing, AttributeInfo(className: "NSComboBox", fullTitle: "IntercellSpacing", patch: true)),
                BlueprintAttribute(LookinAttr_NSComboBox_Items_ItemHeight, AttributeInfo(className: "NSComboBox", fullTitle: "ItemHeight", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSComboBox_Misc, title: "Misc", attributes: [
                BlueprintAttribute(LookinAttr_NSComboBox_Misc_ButtonBordered, AttributeInfo(className: "NSComboBox", fullTitle: "ButtonBordered", getterString: "isButtonBordered", patch: true)),
                BlueprintAttribute(LookinAttr_NSComboBox_Misc_Completes, AttributeInfo(className: "NSComboBox", fullTitle: "Completes", patch: true)),
                BlueprintAttribute(LookinAttr_NSComboBox_Misc_UsesDataSource, AttributeInfo(className: "NSComboBox", fullTitle: "UsesDataSource", patch: false)),
            ]),
        ])

        static let nsStepperGroup = BlueprintGroup(LookinAttrGroup_NSStepper, title: "NSStepper", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSStepper_Range, title: "Range", attributes: [
                BlueprintAttribute(LookinAttr_NSStepper_Range_MinValue, AttributeInfo(className: "NSStepper", fullTitle: "MinValue", patch: true)),
                BlueprintAttribute(LookinAttr_NSStepper_Range_MaxValue, AttributeInfo(className: "NSStepper", fullTitle: "MaxValue", patch: true)),
                BlueprintAttribute(LookinAttr_NSStepper_Range_Increment, AttributeInfo(className: "NSStepper", fullTitle: "Increment", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSStepper_Misc, title: "Misc", attributes: [
                BlueprintAttribute(LookinAttr_NSStepper_Misc_ValueWraps, AttributeInfo(className: "NSStepper", fullTitle: "ValueWraps", patch: true)),
                BlueprintAttribute(LookinAttr_NSStepper_Misc_Autorepeat, AttributeInfo(className: "NSStepper", fullTitle: "Autorepeat", patch: true)),
            ]),
        ])

        static let nsColorWellGroup = BlueprintGroup(LookinAttrGroup_NSColorWell, title: "NSColorWell", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSColorWell_Color, title: "Color", attributes: [
                BlueprintAttribute(LookinAttr_NSColorWell_Color_Color, AttributeInfo(className: "NSColorWell", fullTitle: "Color", typeIfObj: .uiColor, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSColorWell_Misc, title: "Misc", attributes: [
                BlueprintAttribute(LookinAttr_NSColorWell_Misc_Bordered, AttributeInfo(className: "NSColorWell", fullTitle: "Bordered", getterString: "isBordered", patch: true)),
                BlueprintAttribute(LookinAttr_NSColorWell_Misc_Active, AttributeInfo(className: "NSColorWell", fullTitle: "Active", getterString: "isActive", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSColorWell_Misc_ColorWellStyle, AttributeInfo(className: "NSColorWell", fullTitle: "ColorWellStyle", enumList: "NSColorWellStyle", patch: true, osVersion: 13)),
            ]),
        ])

        static let nsSwitchGroup = BlueprintGroup(LookinAttrGroup_NSSwitch, title: "NSSwitch", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSSwitch_State, title: "State", attributes: [
                BlueprintAttribute(LookinAttr_NSSwitch_State_State, AttributeInfo(className: "NSSwitch", fullTitle: "State", enumList: "NSControlStateValue", patch: true, osVersion: 15)),
            ]),
        ])

        static let nsDatePickerGroup = BlueprintGroup(LookinAttrGroup_NSDatePicker, title: "NSDatePicker", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSDatePicker_Style, title: "Style", attributes: [
                BlueprintAttribute(LookinAttr_NSDatePicker_Style_DatePickerStyle, AttributeInfo(className: "NSDatePicker", fullTitle: "DatePickerStyle", enumList: "NSDatePickerStyle", patch: true)),
                BlueprintAttribute(LookinAttr_NSDatePicker_Style_DatePickerMode, AttributeInfo(className: "NSDatePicker", fullTitle: "DatePickerMode", enumList: "NSDatePickerMode", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSDatePicker_Range, title: "Range", attributes: [
                BlueprintAttribute(LookinAttr_NSDatePicker_Range_DateValue, AttributeInfo(className: "NSDatePicker", fullTitle: "DateValue", setterString: "", typeIfObj: .customObj, patch: false)),
                BlueprintAttribute(LookinAttr_NSDatePicker_Range_MinDate, AttributeInfo(className: "NSDatePicker", fullTitle: "MinDate", setterString: "", typeIfObj: .customObj, patch: false, hideIfNil: true)),
                BlueprintAttribute(LookinAttr_NSDatePicker_Range_MaxDate, AttributeInfo(className: "NSDatePicker", fullTitle: "MaxDate", setterString: "", typeIfObj: .customObj, patch: false, hideIfNil: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSDatePicker_Misc, title: "Misc", attributes: [
                BlueprintAttribute(LookinAttr_NSDatePicker_Misc_Bordered, AttributeInfo(className: "NSDatePicker", fullTitle: "Bordered", getterString: "isBordered", patch: true)),
                BlueprintAttribute(LookinAttr_NSDatePicker_Misc_Bezeled, AttributeInfo(className: "NSDatePicker", fullTitle: "Bezeled", getterString: "isBezeled", patch: true)),
                BlueprintAttribute(LookinAttr_NSDatePicker_Misc_DrawsBackground, AttributeInfo(className: "NSDatePicker", fullTitle: "DrawsBackground", patch: true)),
            ]),
        ])

        static let nsLevelIndicatorGroup = BlueprintGroup(LookinAttrGroup_NSLevelIndicator, title: "NSLevelIndicator", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSLevelIndicator_Style, title: "Style", attributes: [
                BlueprintAttribute(LookinAttr_NSLevelIndicator_Style_Style, AttributeInfo(className: "NSLevelIndicator", fullTitle: "LevelIndicatorStyle", enumList: "NSLevelIndicatorStyle", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSLevelIndicator_Range, title: "Range", attributes: [
                BlueprintAttribute(LookinAttr_NSLevelIndicator_Range_MinValue, AttributeInfo(className: "NSLevelIndicator", fullTitle: "MinValue", patch: true)),
                BlueprintAttribute(LookinAttr_NSLevelIndicator_Range_MaxValue, AttributeInfo(className: "NSLevelIndicator", fullTitle: "MaxValue", patch: true)),
                BlueprintAttribute(LookinAttr_NSLevelIndicator_Range_WarningValue, AttributeInfo(className: "NSLevelIndicator", fullTitle: "WarningValue", patch: true)),
                BlueprintAttribute(LookinAttr_NSLevelIndicator_Range_CriticalValue, AttributeInfo(className: "NSLevelIndicator", fullTitle: "CriticalValue", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSLevelIndicator_TickMark, title: "TickMark", attributes: [
                BlueprintAttribute(LookinAttr_NSLevelIndicator_TickMark_NumberOfTickMarks, AttributeInfo(className: "NSLevelIndicator", fullTitle: "NumberOfTickMarks", patch: true)),
                BlueprintAttribute(LookinAttr_NSLevelIndicator_TickMark_NumberOfMajorTickMarks, AttributeInfo(className: "NSLevelIndicator", fullTitle: "NumberOfMajorTickMarks", patch: true)),
            ]),
        ])

        static let nsOutlineViewGroup = BlueprintGroup(LookinAttrGroup_NSOutlineView, title: "NSOutlineView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSOutlineView_Indentation, title: "Indentation", attributes: [
                BlueprintAttribute(LookinAttr_NSOutlineView_Indentation_IndentationPerLevel, AttributeInfo(className: "NSOutlineView", fullTitle: "IndentationPerLevel", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSOutlineView_Misc, title: "Misc", attributes: [
                BlueprintAttribute(LookinAttr_NSOutlineView_Misc_AutoresizesOutlineColumn, AttributeInfo(className: "NSOutlineView", fullTitle: "AutoresizesOutlineColumn", patch: true)),
                BlueprintAttribute(LookinAttr_NSOutlineView_Misc_IndentationMarkerFollowsCell, AttributeInfo(className: "NSOutlineView", fullTitle: "IndentationMarkerFollowsCell", patch: true)),
                BlueprintAttribute(LookinAttr_NSOutlineView_Misc_AutosaveExpandedItems, AttributeInfo(className: "NSOutlineView", fullTitle: "AutosaveExpandedItems", patch: true)),
            ]),
        ])

        static let nsCollectionViewGroup = BlueprintGroup(LookinAttrGroup_NSCollectionView, title: "NSCollectionView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSCollectionView_Selection, title: "Selection", attributes: [
                BlueprintAttribute(LookinAttr_NSCollectionView_Selection_Selectable, AttributeInfo(className: "NSCollectionView", fullTitle: "Selectable", getterString: "isSelectable", patch: true)),
                BlueprintAttribute(LookinAttr_NSCollectionView_Selection_AllowsMultipleSelection, AttributeInfo(className: "NSCollectionView", fullTitle: "AllowsMultipleSelection", patch: true)),
                BlueprintAttribute(LookinAttr_NSCollectionView_Selection_AllowsEmptySelection, AttributeInfo(className: "NSCollectionView", fullTitle: "AllowsEmptySelection", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSCollectionView_Info, title: "Info", attributes: [
                BlueprintAttribute(LookinAttr_NSCollectionView_Info_NumberOfSections, AttributeInfo(className: "NSCollectionView", fullTitle: "NumberOfSections", setterString: "", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_NSCollectionView_Colors, title: "Colors", attributes: [
                BlueprintAttribute(LookinAttr_NSCollectionView_Colors_BackgroundColors, AttributeInfo(className: "NSCollectionView", fullTitle: "BackgroundColors", setterString: "", typeIfObj: .customObj, patch: false)),
            ]),
        ])

        static let nsBoxGroup = BlueprintGroup(LookinAttrGroup_NSBox, title: "NSBox", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSBox_Type, title: "Type", attributes: [
                BlueprintAttribute(LookinAttr_NSBox_Type_BoxType, AttributeInfo(className: "NSBox", fullTitle: "BoxType", enumList: "NSBoxType", patch: true)),
                BlueprintAttribute(LookinAttr_NSBox_Type_BorderType, AttributeInfo(className: "NSBox", fullTitle: "BorderType", enumList: "NSBorderType", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSBox_Title, title: "Title", attributes: [
                BlueprintAttribute(LookinAttr_NSBox_Title_Title, AttributeInfo(className: "NSBox", fullTitle: "Title", typeIfObj: .nsString, patch: true)),
                BlueprintAttribute(LookinAttr_NSBox_Title_TitlePosition, AttributeInfo(className: "NSBox", fullTitle: "TitlePosition", enumList: "NSTitlePosition", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSBox_Appearance, title: "Appearance", attributes: [
                BlueprintAttribute(LookinAttr_NSBox_Appearance_Transparent, AttributeInfo(className: "NSBox", fullTitle: "Transparent", getterString: "isTransparent", patch: true)),
                BlueprintAttribute(LookinAttr_NSBox_Appearance_FillColor, AttributeInfo(className: "NSBox", fullTitle: "FillColor", typeIfObj: .uiColor, patch: true)),
                BlueprintAttribute(LookinAttr_NSBox_Appearance_BorderColor, AttributeInfo(className: "NSBox", fullTitle: "BorderColor", typeIfObj: .uiColor, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSBox_Metrics, title: "Metrics", attributes: [
                BlueprintAttribute(LookinAttr_NSBox_Metrics_BorderWidth, AttributeInfo(className: "NSBox", fullTitle: "BorderWidth", patch: true)),
                BlueprintAttribute(LookinAttr_NSBox_Metrics_CornerRadius, AttributeInfo(className: "NSBox", fullTitle: "CornerRadius", patch: true)),
                BlueprintAttribute(LookinAttr_NSBox_Metrics_ContentViewMargins, AttributeInfo(className: "NSBox", fullTitle: "ContentViewMargins", patch: true)),
            ]),
        ])

        static let nsSplitViewGroup = BlueprintGroup(LookinAttrGroup_NSSplitView, title: "NSSplitView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSSplitView_Orientation, title: "Orientation", attributes: [
                BlueprintAttribute(LookinAttr_NSSplitView_Orientation_Vertical, AttributeInfo(className: "NSSplitView", fullTitle: "Vertical", getterString: "isVertical", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSSplitView_Style, title: "Style", attributes: [
                BlueprintAttribute(LookinAttr_NSSplitView_Style_DividerStyle, AttributeInfo(className: "NSSplitView", fullTitle: "DividerStyle", enumList: "NSSplitViewDividerStyle", patch: true)),
                BlueprintAttribute(LookinAttr_NSSplitView_Style_DividerThickness, AttributeInfo(className: "NSSplitView", fullTitle: "DividerThickness", setterString: "", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_NSSplitView_Misc, title: "Misc", attributes: [
                BlueprintAttribute(LookinAttr_NSSplitView_Misc_ArrangesAllSubviews, AttributeInfo(className: "NSSplitView", fullTitle: "ArrangesAllSubviews", patch: true)),
            ]),
        ])

        static let nsTabViewGroup = BlueprintGroup(LookinAttrGroup_NSTabView, title: "NSTabView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSTabView_Type, title: "Type", attributes: [
                BlueprintAttribute(LookinAttr_NSTabView_Type_TabViewType, AttributeInfo(className: "NSTabView", fullTitle: "TabViewType", enumList: "NSTabViewType", patch: true)),
                BlueprintAttribute(LookinAttr_NSTabView_Type_TabPosition, AttributeInfo(className: "NSTabView", fullTitle: "TabPosition", enumList: "NSTabPosition", patch: true, osVersion: 14)),
                BlueprintAttribute(LookinAttr_NSTabView_Type_TabViewBorderType, AttributeInfo(className: "NSTabView", fullTitle: "TabViewBorderType", enumList: "NSTabViewBorderType", patch: true, osVersion: 14)),
            ]),
            BlueprintSection(LookinAttrSec_NSTabView_Misc, title: "Misc", attributes: [
                BlueprintAttribute(LookinAttr_NSTabView_Misc_AllowsTruncatedLabels, AttributeInfo(className: "NSTabView", fullTitle: "AllowsTruncatedLabels", patch: true)),
                BlueprintAttribute(LookinAttr_NSTabView_Misc_DrawsBackground, AttributeInfo(className: "NSTabView", fullTitle: "DrawsBackground", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSTabView_Info, title: "Info", attributes: [
                BlueprintAttribute(LookinAttr_NSTabView_Info_NumberOfTabViewItems, AttributeInfo(className: "NSTabView", fullTitle: "NumberOfTabViewItems", setterString: "", patch: false)),
            ]),
        ])

        static let nsGridViewGroup = BlueprintGroup(LookinAttrGroup_NSGridView, title: "NSGridView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSGridView_Dimensions, title: "Dimensions", attributes: [
                BlueprintAttribute(LookinAttr_NSGridView_Dimensions_NumberOfColumns, AttributeInfo(className: "NSGridView", fullTitle: "NumberOfColumns", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_NSGridView_Dimensions_NumberOfRows, AttributeInfo(className: "NSGridView", fullTitle: "NumberOfRows", setterString: "", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_NSGridView_Spacing, title: "Spacing", attributes: [
                BlueprintAttribute(LookinAttr_NSGridView_Spacing_RowSpacing, AttributeInfo(className: "NSGridView", fullTitle: "RowSpacing", patch: true)),
                BlueprintAttribute(LookinAttr_NSGridView_Spacing_ColumnSpacing, AttributeInfo(className: "NSGridView", fullTitle: "ColumnSpacing", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSGridView_Placement, title: "Placement", attributes: [
                BlueprintAttribute(LookinAttr_NSGridView_Placement_XPlacement, AttributeInfo(className: "NSGridView", fullTitle: "XPlacement", enumList: "NSGridCellPlacement", patch: true)),
                BlueprintAttribute(LookinAttr_NSGridView_Placement_YPlacement, AttributeInfo(className: "NSGridView", fullTitle: "YPlacement", enumList: "NSGridCellPlacement", patch: true)),
            ]),
        ])

        static let nsCellGroup = BlueprintGroup(LookinAttrGroup_NSCell, title: "NSCell", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSCell_Cell, title: "Cell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_Cell_Type, AttributeInfo(className: "NSCell", fullTitle: "CellType", getterString: "type", setterString: "", enumList: "NSCellType")),
                BlueprintAttribute(LookinAttr_NSCell_Cell_State, AttributeInfo(className: "NSCell", fullTitle: "State", getterString: "state", setterString: "", enumList: "NSControlStateValue")),
                BlueprintAttribute(LookinAttr_NSCell_Cell_Enabled, AttributeInfo(className: "NSCell", fullTitle: "Enabled", getterString: "isEnabled", setterString: "")),
                BlueprintAttribute(LookinAttr_NSCell_Cell_Bordered, AttributeInfo(className: "NSCell", fullTitle: "Bordered", getterString: "isBordered", setterString: "")),
                BlueprintAttribute(LookinAttr_NSCell_Cell_Bezeled, AttributeInfo(className: "NSCell", fullTitle: "Bezeled", getterString: "isBezeled", setterString: "")),
                BlueprintAttribute(LookinAttr_NSCell_Cell_Highlighted, AttributeInfo(className: "NSCell", fullTitle: "Highlighted", getterString: "isHighlighted", setterString: "")),
                BlueprintAttribute(LookinAttr_NSCell_Cell_Editable, AttributeInfo(className: "NSCell", fullTitle: "Editable", getterString: "isEditable", setterString: "")),
                BlueprintAttribute(LookinAttr_NSCell_Cell_Selectable, AttributeInfo(className: "NSCell", fullTitle: "Selectable", getterString: "isSelectable", setterString: "")),
                BlueprintAttribute(LookinAttr_NSCell_Cell_Alignment, AttributeInfo(className: "NSCell", fullTitle: "Alignment", getterString: "alignment", setterString: "", enumList: "NSTextAlignment_AppKit")),
                BlueprintAttribute(LookinAttr_NSCell_Cell_ControlSize, AttributeInfo(className: "NSCell", fullTitle: "ControlSize", getterString: "controlSize", setterString: "", enumList: "NSControlSize")),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_Content, title: "Content", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_Content_Title, AttributeInfo(className: "NSCell", fullTitle: "Title", getterString: "title", setterString: "", typeIfObj: .nsString, hideIfNil: true)),
                BlueprintAttribute(LookinAttr_NSCell_Content_FontName, AttributeInfo(className: "NSCell", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", typeIfObj: .nsString, hideIfNil: true)),
                BlueprintAttribute(LookinAttr_NSCell_Content_FontSize, AttributeInfo(className: "NSCell", fullTitle: "FontSize", getterString: "lks_fontSize", setterString: "")),
                BlueprintAttribute(LookinAttr_NSCell_Content_LineBreakMode, AttributeInfo(className: "NSCell", fullTitle: "LineBreakMode", getterString: "lineBreakMode", setterString: "", enumList: "NSLineBreakMode")),
                BlueprintAttribute(LookinAttr_NSCell_Content_Wraps, AttributeInfo(className: "NSCell", fullTitle: "Wraps", getterString: "wraps", setterString: "")),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_Behavior, title: "Behavior", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_Behavior_Tag, AttributeInfo(className: "NSCell", fullTitle: "Tag", getterString: "tag", setterString: "")),
                BlueprintAttribute(LookinAttr_NSCell_Behavior_Continuous, AttributeInfo(className: "NSCell", fullTitle: "Continuous", getterString: "isContinuous", setterString: "")),
                BlueprintAttribute(LookinAttr_NSCell_Behavior_AllowsMixedState, AttributeInfo(className: "NSCell", fullTitle: "AllowsMixedState", getterString: "allowsMixedState", setterString: "")),
                BlueprintAttribute(LookinAttr_NSCell_Behavior_SendsActionOnEndEditing, AttributeInfo(className: "NSCell", fullTitle: "SendsActionOnEndEditing", getterString: "sendsActionOnEndEditing", setterString: "")),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_ButtonCell, title: "NSButtonCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_ButtonCell_BezelStyle, AttributeInfo(className: "NSButtonCell", fullTitle: "BezelStyle", getterString: "bezelStyle", setterString: "", enumList: "NSBezelStyle")),
                BlueprintAttribute(LookinAttr_NSCell_ButtonCell_ImagePosition, AttributeInfo(className: "NSButtonCell", fullTitle: "ImagePosition", getterString: "imagePosition", setterString: "", enumList: "NSCellImagePosition")),
                BlueprintAttribute(LookinAttr_NSCell_ButtonCell_ShowsBorderOnlyWhileMouseInside, AttributeInfo(className: "NSButtonCell", fullTitle: "ShowsBorderOnlyWhileMouseInside", getterString: "showsBorderOnlyWhileMouseInside", setterString: "")),
                BlueprintAttribute(LookinAttr_NSCell_ButtonCell_KeyEquivalent, AttributeInfo(className: "NSButtonCell", fullTitle: "KeyEquivalent", getterString: "keyEquivalent", setterString: "", typeIfObj: .nsString, hideIfNil: true)),
                BlueprintAttribute(LookinAttr_NSCell_ButtonCell_AlternateTitle, AttributeInfo(className: "NSButtonCell", fullTitle: "AlternateTitle", getterString: "alternateTitle", setterString: "", typeIfObj: .nsString, hideIfNil: true)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_TextFieldCell, title: "NSTextFieldCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_TextFieldCell_Placeholder, AttributeInfo(className: "NSTextFieldCell", fullTitle: "Placeholder", getterString: "placeholderString", setterString: "", typeIfObj: .nsString, hideIfNil: true)),
                BlueprintAttribute(LookinAttr_NSCell_TextFieldCell_DrawsBackground, AttributeInfo(className: "NSTextFieldCell", fullTitle: "DrawsBackground", getterString: "drawsBackground", setterString: "")),
                BlueprintAttribute(LookinAttr_NSCell_TextFieldCell_TextColor, AttributeInfo(className: "NSTextFieldCell", fullTitle: "TextColor", getterString: "textColor", setterString: "", typeIfObj: .uiColor, hideIfNil: true)),
                BlueprintAttribute(LookinAttr_NSCell_TextFieldCell_BackgroundColor, AttributeInfo(className: "NSTextFieldCell", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "", typeIfObj: .uiColor, hideIfNil: true)),
                BlueprintAttribute(LookinAttr_NSCell_TextFieldCell_BezelStyle, AttributeInfo(className: "NSTextFieldCell", fullTitle: "BezelStyle", getterString: "bezelStyle", setterString: "", enumList: "NSTextFieldBezelStyle")),
            ]),
        ])
    }

#endif
