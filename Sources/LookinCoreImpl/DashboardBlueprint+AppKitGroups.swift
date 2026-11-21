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
            BlueprintSection(LookinAttrSec_NSImageView_SymbolConfiguration, title: "SymbolConfiguration", attributes: [
                BlueprintAttribute(LookinAttr_NSImageView_SymbolConfiguration_SymbolConfiguration, AttributeInfo(className: "NSImageView", fullTitle: "SymbolConfiguration", getterString: "symbolConfiguration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.description))),
            ]),
            BlueprintSection(LookinAttrSec_NSImageView_AllowsCutCopyPaste, title: "AllowsCutCopyPaste", attributes: [
                BlueprintAttribute(LookinAttr_NSImageView_AllowsCutCopyPaste_AllowsCutCopyPaste, AttributeInfo(className: "NSImageView", fullTitle: "AllowsCutCopyPaste", getterString: "allowsCutCopyPaste", setterString: "setAllowsCutCopyPaste:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSImageView_PreferredImageDynamicRange, title: "PreferredImageDynamicRange", attributes: [
                BlueprintAttribute(LookinAttr_NSImageView_PreferredImageDynamicRange_PreferredImageDynamicRange, AttributeInfo(className: "NSImageView", fullTitle: "PreferredImageDynamicRange", getterString: "preferredImageDynamicRange", setterString: "setPreferredImageDynamicRange:", enumList: "NSImageDynamicRange", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSImageView_ImageDynamicRange, title: "ImageDynamicRange", attributes: [
                BlueprintAttribute(LookinAttr_NSImageView_ImageDynamicRange_ImageDynamicRange, AttributeInfo(className: "NSImageView", fullTitle: "ImageDynamicRange", getterString: "imageDynamicRange", setterString: "", enumList: "NSImageDynamicRange", revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSControl_Tag, title: "Tag", attributes: [
                BlueprintAttribute(LookinAttr_NSControl_Tag_Tag, AttributeInfo(className: "NSControl", fullTitle: "Tag", getterString: "tag", setterString: "setTag:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSControl_RefusesFirstResponder, title: "RefusesFirstResponder", attributes: [
                BlueprintAttribute(LookinAttr_NSControl_RefusesFirstResponder_RefusesFirstResponder, AttributeInfo(className: "NSControl", fullTitle: "RefusesFirstResponder", getterString: "refusesFirstResponder", setterString: "setRefusesFirstResponder:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSControl_LineBreakMode, title: "LineBreakMode", attributes: [
                BlueprintAttribute(LookinAttr_NSControl_LineBreakMode_LineBreakMode, AttributeInfo(className: "NSControl", fullTitle: "LineBreakMode", getterString: "lineBreakMode", setterString: "setLineBreakMode:", enumList: "NSLineBreakMode", patch: true, revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSButton_NSStatusBarButton, title: "NSStatusBarButton", attributes: [
                BlueprintAttribute(LookinAttr_NSButton_NSStatusBarButton_AppearsDisabled, AttributeInfo(className: "NSStatusBarButton", fullTitle: "AppearsDisabled", getterString: "appearsDisabled", setterString: "setAppearsDisabled:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSButton_TintProminence, title: "TintProminence", attributes: [
                BlueprintAttribute(LookinAttr_NSButton_TintProminence_TintProminence, AttributeInfo(className: "NSButton", fullTitle: "TintProminence", getterString: "tintProminence", setterString: "setTintProminence:", enumList: "NSTintProminence", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSButton_Images, title: "Images", attributes: [
                BlueprintAttribute(LookinAttr_NSButton_Images_Image, AttributeInfo(className: "NSButton", fullTitle: "Image", getterString: "image", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_NSButton_Images_AlternateImage, AttributeInfo(className: "NSButton", fullTitle: "AlternateImage", getterString: "alternateImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(LookinAttrSec_NSButton_ImagePosition, title: "ImagePosition", attributes: [
                BlueprintAttribute(LookinAttr_NSButton_ImagePosition_ImagePosition, AttributeInfo(className: "NSButton", fullTitle: "ImagePosition", getterString: "imagePosition", setterString: "setImagePosition:", enumList: "NSCellImagePosition", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSButton_ImageScaling, title: "ImageScaling", attributes: [
                BlueprintAttribute(LookinAttr_NSButton_ImageScaling_ImageScaling, AttributeInfo(className: "NSButton", fullTitle: "ImageScaling", getterString: "imageScaling", setterString: "setImageScaling:", enumList: "NSImageScaling", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSButton_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_NSButton_Behavior_ImageHugsTitle, AttributeInfo(className: "NSButton", fullTitle: "ImageHugsTitle", getterString: "imageHugsTitle", setterString: "setImageHugsTitle:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSButton_Behavior_AllowsMixedState, AttributeInfo(className: "NSButton", fullTitle: "AllowsMixedState", getterString: "allowsMixedState", setterString: "setAllowsMixedState:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSButton_SymbolConfiguration, title: "SymbolConfiguration", attributes: [
                BlueprintAttribute(LookinAttr_NSButton_SymbolConfiguration_SymbolConfiguration, AttributeInfo(className: "NSButton", fullTitle: "SymbolConfiguration", getterString: "symbolConfiguration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.description))),
            ]),
            BlueprintSection(LookinAttrSec_NSButton_State, title: "State", attributes: [
                BlueprintAttribute(LookinAttr_NSButton_State_State, AttributeInfo(className: "NSButton", fullTitle: "State", getterString: "state", setterString: "setState:", enumList: "NSControlStateValue", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSButton_KeyEquivalent, title: "KeyEquivalent", attributes: [
                BlueprintAttribute(LookinAttr_NSButton_KeyEquivalent_KeyEquivalent, AttributeInfo(className: "NSButton", fullTitle: "KeyEquivalent", getterString: "keyEquivalent", setterString: "setKeyEquivalent:", typeIfObj: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSButton_KeyEquivalentModifierMask, title: "KeyEquivalentModifierMask", attributes: [
                BlueprintAttribute(LookinAttr_NSButton_KeyEquivalentModifierMask_KeyEquivalentModifierMask, AttributeInfo(className: "NSButton", fullTitle: "KeyEquivalentModifierMask", getterString: "keyEquivalentModifierMask", setterString: "", revision: 1, presentation: .optionNames("NSEventModifierFlags"))),
            ]),
            BlueprintSection(LookinAttrSec_NSButton_BorderShape, title: "BorderShape", attributes: [
                BlueprintAttribute(LookinAttr_NSButton_BorderShape_BorderShape, AttributeInfo(className: "NSButton", fullTitle: "BorderShape", getterString: "borderShape", setterString: "setBorderShape:", enumList: "NSControlBorderShape", patch: true, revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSScrollView_DocumentVisibleRect, title: "DocumentVisibleRect", attributes: [
                BlueprintAttribute(LookinAttr_NSScrollView_DocumentVisibleRect_DocumentVisibleRect, AttributeInfo(className: "NSScrollView", fullTitle: "DocumentVisibleRect", getterString: "documentVisibleRect", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSScrollView_BackgroundColor, title: "BackgroundColor", attributes: [
                BlueprintAttribute(LookinAttr_NSScrollView_BackgroundColor_BackgroundColor, AttributeInfo(className: "NSScrollView", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSScrollView_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_NSScrollView_Behavior_DrawsBackground, AttributeInfo(className: "NSScrollView", fullTitle: "DrawsBackground", getterString: "drawsBackground", setterString: "setDrawsBackground:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSScrollView_Behavior_TouchScrollingEnabled, AttributeInfo(className: "NSScrollView", fullTitle: "TouchScrollingEnabled", getterString: "isTouchScrollingEnabled", setterString: "setTouchScrollingEnabled:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSScrollView_ContentInsets, title: "ContentInsets", attributes: [
                BlueprintAttribute(LookinAttr_NSScrollView_ContentInsets_ContentInsets, AttributeInfo(className: "NSScrollView", fullTitle: "ContentInsets", getterString: "contentInsets", setterString: "setContentInsets:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSScrollView_MinimumNumberOfTouchesForScrolling, title: "MinimumNumberOfTouchesForScrolling", attributes: [
                BlueprintAttribute(LookinAttr_NSScrollView_MinimumNumberOfTouchesForScrolling_MinimumNumberOfTouchesForScrolling, AttributeInfo(className: "NSScrollView", fullTitle: "MinimumNumberOfTouchesForScrolling", getterString: "minimumNumberOfTouchesForScrolling", setterString: "setMinimumNumberOfTouchesForScrolling:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSScrollView_MaximumNumberOfTouchesForScrolling, title: "MaximumNumberOfTouchesForScrolling", attributes: [
                BlueprintAttribute(LookinAttr_NSScrollView_MaximumNumberOfTouchesForScrolling_MaximumNumberOfTouchesForScrolling, AttributeInfo(className: "NSScrollView", fullTitle: "MaximumNumberOfTouchesForScrolling", getterString: "maximumNumberOfTouchesForScrolling", setterString: "setMaximumNumberOfTouchesForScrolling:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSScrollView_FindBarPosition, title: "FindBarPosition", attributes: [
                BlueprintAttribute(LookinAttr_NSScrollView_FindBarPosition_FindBarPosition, AttributeInfo(className: "NSScrollView", fullTitle: "FindBarPosition", getterString: "findBarPosition", setterString: "setFindBarPosition:", enumList: "NSScrollViewFindBarPosition", patch: true, revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSTableView_BackgroundColor, title: "BackgroundColor", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_BackgroundColor_BackgroundColor, AttributeInfo(className: "NSTableView", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_EffectiveRowSizeStyle, title: "EffectiveRowSizeStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_EffectiveRowSizeStyle_EffectiveRowSizeStyle, AttributeInfo(className: "NSTableView", fullTitle: "EffectiveRowSizeStyle", getterString: "effectiveRowSizeStyle", setterString: "", enumList: "NSTableViewRowSizeStyle", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_EditedColumn, title: "EditedColumn", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_EditedColumn_EditedColumn, AttributeInfo(className: "NSTableView", fullTitle: "EditedColumn", getterString: "editedColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_EditedRow, title: "EditedRow", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_EditedRow_EditedRow, AttributeInfo(className: "NSTableView", fullTitle: "EditedRow", getterString: "editedRow", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_ClickedColumn, title: "ClickedColumn", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_ClickedColumn_ClickedColumn, AttributeInfo(className: "NSTableView", fullTitle: "ClickedColumn", getterString: "clickedColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_ClickedRow, title: "ClickedRow", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_ClickedRow_ClickedRow, AttributeInfo(className: "NSTableView", fullTitle: "ClickedRow", getterString: "clickedRow", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_SelectedColumn, title: "SelectedColumn", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_SelectedColumn_SelectedColumn, AttributeInfo(className: "NSTableView", fullTitle: "SelectedColumn", getterString: "selectedColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_SelectedRow, title: "SelectedRow", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_SelectedRow_SelectedRow, AttributeInfo(className: "NSTableView", fullTitle: "SelectedRow", getterString: "selectedRow", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_NumberOfSelectedColumns, title: "NumberOfSelectedColumns", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_NumberOfSelectedColumns_NumberOfSelectedColumns, AttributeInfo(className: "NSTableView", fullTitle: "NumberOfSelectedColumns", getterString: "numberOfSelectedColumns", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_NumberOfSelectedRows, title: "NumberOfSelectedRows", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_NumberOfSelectedRows_NumberOfSelectedRows, AttributeInfo(className: "NSTableView", fullTitle: "NumberOfSelectedRows", getterString: "numberOfSelectedRows", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableView_EffectiveStyle, title: "EffectiveStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSTableView_EffectiveStyle_EffectiveStyle, AttributeInfo(className: "NSTableView", fullTitle: "EffectiveStyle", getterString: "effectiveStyle", setterString: "", enumList: "NSTableViewStyle", revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSTextView_TextContainerOrigin, title: "TextContainerOrigin", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_TextContainerOrigin_TextContainerOrigin, AttributeInfo(className: "NSTextView", fullTitle: "TextContainerOrigin", getterString: "textContainerOrigin", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextView_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_ShouldDrawInsertionPoint, AttributeInfo(className: "NSTextView", fullTitle: "ShouldDrawInsertionPoint", getterString: "shouldDrawInsertionPoint", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_UsesAdaptiveColorMappingForDarkAppearance, AttributeInfo(className: "NSTextView", fullTitle: "UsesAdaptiveColorMappingForDarkAppearance", getterString: "usesAdaptiveColorMappingForDarkAppearance", setterString: "setUsesAdaptiveColorMappingForDarkAppearance:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_DisplaysLinkToolTips, AttributeInfo(className: "NSTextView", fullTitle: "DisplaysLinkToolTips", getterString: "displaysLinkToolTips", setterString: "setDisplaysLinkToolTips:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_AcceptsGlyphInfo, AttributeInfo(className: "NSTextView", fullTitle: "AcceptsGlyphInfo", getterString: "acceptsGlyphInfo", setterString: "setAcceptsGlyphInfo:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_UsesRuler, AttributeInfo(className: "NSTextView", fullTitle: "UsesRuler", getterString: "usesRuler", setterString: "setUsesRuler:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_UsesInspectorBar, AttributeInfo(className: "NSTextView", fullTitle: "UsesInspectorBar", getterString: "usesInspectorBar", setterString: "setUsesInspectorBar:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_ContinuousSpellCheckingEnabled, AttributeInfo(className: "NSTextView", fullTitle: "ContinuousSpellCheckingEnabled", getterString: "isContinuousSpellCheckingEnabled", setterString: "setContinuousSpellCheckingEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_GrammarCheckingEnabled, AttributeInfo(className: "NSTextView", fullTitle: "GrammarCheckingEnabled", getterString: "isGrammarCheckingEnabled", setterString: "setGrammarCheckingEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_AllowsDocumentBackgroundColorChange, AttributeInfo(className: "NSTextView", fullTitle: "AllowsDocumentBackgroundColorChange", getterString: "allowsDocumentBackgroundColorChange", setterString: "setAllowsDocumentBackgroundColorChange:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_AllowsUndo, AttributeInfo(className: "NSTextView", fullTitle: "AllowsUndo", getterString: "allowsUndo", setterString: "setAllowsUndo:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_CoalescingUndo, AttributeInfo(className: "NSTextView", fullTitle: "CoalescingUndo", getterString: "isCoalescingUndo", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_AllowsImageEditing, AttributeInfo(className: "NSTextView", fullTitle: "AllowsImageEditing", getterString: "allowsImageEditing", setterString: "setAllowsImageEditing:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_UsesRolloverButtonForSelection, AttributeInfo(className: "NSTextView", fullTitle: "UsesRolloverButtonForSelection", getterString: "usesRolloverButtonForSelection", setterString: "setUsesRolloverButtonForSelection:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_DrawsBackground, AttributeInfo(className: "NSTextView", fullTitle: "DrawsBackground", getterString: "drawsBackground", setterString: "setDrawsBackground:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_UsesFontPanel, AttributeInfo(className: "NSTextView", fullTitle: "UsesFontPanel", getterString: "usesFontPanel", setterString: "setUsesFontPanel:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_RulerVisible, AttributeInfo(className: "NSTextView", fullTitle: "RulerVisible", getterString: "isRulerVisible", setterString: "setRulerVisible:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_WritingToolsActive, AttributeInfo(className: "NSTextView", fullTitle: "WritingToolsActive", getterString: "isWritingToolsActive", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_SmartInsertDeleteEnabled, AttributeInfo(className: "NSTextView", fullTitle: "SmartInsertDeleteEnabled", getterString: "smartInsertDeleteEnabled", setterString: "setSmartInsertDeleteEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_AutomaticQuoteSubstitutionEnabled, AttributeInfo(className: "NSTextView", fullTitle: "AutomaticQuoteSubstitutionEnabled", getterString: "isAutomaticQuoteSubstitutionEnabled", setterString: "setAutomaticQuoteSubstitutionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_AutomaticLinkDetectionEnabled, AttributeInfo(className: "NSTextView", fullTitle: "AutomaticLinkDetectionEnabled", getterString: "isAutomaticLinkDetectionEnabled", setterString: "setAutomaticLinkDetectionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_AutomaticDataDetectionEnabled, AttributeInfo(className: "NSTextView", fullTitle: "AutomaticDataDetectionEnabled", getterString: "isAutomaticDataDetectionEnabled", setterString: "setAutomaticDataDetectionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_AutomaticDashSubstitutionEnabled, AttributeInfo(className: "NSTextView", fullTitle: "AutomaticDashSubstitutionEnabled", getterString: "isAutomaticDashSubstitutionEnabled", setterString: "setAutomaticDashSubstitutionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_AutomaticTextReplacementEnabled, AttributeInfo(className: "NSTextView", fullTitle: "AutomaticTextReplacementEnabled", getterString: "isAutomaticTextReplacementEnabled", setterString: "setAutomaticTextReplacementEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_AutomaticSpellingCorrectionEnabled, AttributeInfo(className: "NSTextView", fullTitle: "AutomaticSpellingCorrectionEnabled", getterString: "isAutomaticSpellingCorrectionEnabled", setterString: "setAutomaticSpellingCorrectionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_UsesFindPanel, AttributeInfo(className: "NSTextView", fullTitle: "UsesFindPanel", getterString: "usesFindPanel", setterString: "setUsesFindPanel:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_UsesFindBar, AttributeInfo(className: "NSTextView", fullTitle: "UsesFindBar", getterString: "usesFindBar", setterString: "setUsesFindBar:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_IncrementalSearchingEnabled, AttributeInfo(className: "NSTextView", fullTitle: "IncrementalSearchingEnabled", getterString: "isIncrementalSearchingEnabled", setterString: "setIncrementalSearchingEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_AutomaticTextCompletionEnabled, AttributeInfo(className: "NSTextView", fullTitle: "AutomaticTextCompletionEnabled", getterString: "isAutomaticTextCompletionEnabled", setterString: "setAutomaticTextCompletionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Behavior_AllowsCharacterPickerTouchBarItem, AttributeInfo(className: "NSTextView", fullTitle: "AllowsCharacterPickerTouchBarItem", getterString: "allowsCharacterPickerTouchBarItem", setterString: "setAllowsCharacterPickerTouchBarItem:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextView_SelectionAffinity, title: "SelectionAffinity", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_SelectionAffinity_SelectionAffinity, AttributeInfo(className: "NSTextView", fullTitle: "SelectionAffinity", getterString: "selectionAffinity", setterString: "", enumList: "NSSelectionAffinity", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextView_SelectionGranularity, title: "SelectionGranularity", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_SelectionGranularity_SelectionGranularity, AttributeInfo(className: "NSTextView", fullTitle: "SelectionGranularity", getterString: "selectionGranularity", setterString: "setSelectionGranularity:", enumList: "NSSelectionGranularity", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextView_Colors, title: "Colors", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_Colors_InsertionPointColor, AttributeInfo(className: "NSTextView", fullTitle: "InsertionPointColor", getterString: "insertionPointColor", setterString: "setInsertionPointColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextView_Colors_BackgroundColor, AttributeInfo(className: "NSTextView", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextView_WritingToolsBehavior, title: "WritingToolsBehavior", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_WritingToolsBehavior_WritingToolsBehavior, AttributeInfo(className: "NSTextView", fullTitle: "WritingToolsBehavior", getterString: "writingToolsBehavior", setterString: "setWritingToolsBehavior:", enumList: "NSWritingToolsBehavior", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextView_AllowedWritingToolsResultOptions, title: "AllowedWritingToolsResultOptions", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_AllowedWritingToolsResultOptions_AllowedWritingToolsResultOptions, AttributeInfo(className: "NSTextView", fullTitle: "AllowedWritingToolsResultOptions", getterString: "allowedWritingToolsResultOptions", setterString: "", revision: 1, presentation: .optionNames("NSWritingToolsResultOptions"))),
            ]),
            BlueprintSection(LookinAttrSec_NSTextView_InlinePredictionType, title: "InlinePredictionType", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_InlinePredictionType_InlinePredictionType, AttributeInfo(className: "NSTextView", fullTitle: "InlinePredictionType", getterString: "inlinePredictionType", setterString: "setInlinePredictionType:", enumList: "NSTextInputTraitType", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextView_MathExpressionCompletionType, title: "MathExpressionCompletionType", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_MathExpressionCompletionType_MathExpressionCompletionType, AttributeInfo(className: "NSTextView", fullTitle: "MathExpressionCompletionType", getterString: "mathExpressionCompletionType", setterString: "setMathExpressionCompletionType:", enumList: "NSTextInputTraitType", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextView_SelectedRange, title: "SelectedRange", attributes: [
                BlueprintAttribute(LookinAttr_NSTextView_SelectedRange_SelectedRange, AttributeInfo(className: "NSTextView", fullTitle: "SelectedRange", getterString: "selectedRange", setterString: "", revision: 1, presentation: .structure)),
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
            BlueprintSection(LookinAttrSec_NSTextField_NSTokenField, title: "NSTokenField", attributes: [
                BlueprintAttribute(LookinAttr_NSTextField_NSTokenField_TokenStyle, AttributeInfo(className: "NSTokenField", fullTitle: "TokenStyle", getterString: "tokenStyle", setterString: "setTokenStyle:", enumList: "NSTokenStyle", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextField_NSTokenField_CompletionDelay, AttributeInfo(className: "NSTokenField", fullTitle: "CompletionDelay", getterString: "completionDelay", setterString: "setCompletionDelay:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextField_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_NSTextField_Behavior_AcceptsFirstResponder, AttributeInfo(className: "NSTextField", fullTitle: "AcceptsFirstResponder", getterString: "acceptsFirstResponder", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextField_Behavior_AllowsWritingTools, AttributeInfo(className: "NSTextField", fullTitle: "AllowsWritingTools", getterString: "allowsWritingTools", setterString: "setAllowsWritingTools:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextField_Behavior_AllowsWritingToolsAffordance, AttributeInfo(className: "NSTextField", fullTitle: "AllowsWritingToolsAffordance", getterString: "allowsWritingToolsAffordance", setterString: "setAllowsWritingToolsAffordance:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextField_Behavior_ResolvesNaturalAlignmentWithBaseWritingDirection, AttributeInfo(className: "NSTextField", fullTitle: "ResolvesNaturalAlignmentWithBaseWritingDirection", getterString: "resolvesNaturalAlignmentWithBaseWritingDirection", setterString: "setResolvesNaturalAlignmentWithBaseWritingDirection:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextField_Behavior_AutomaticTextCompletionEnabled, AttributeInfo(className: "NSTextField", fullTitle: "AutomaticTextCompletionEnabled", getterString: "isAutomaticTextCompletionEnabled", setterString: "setAutomaticTextCompletionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTextField_Behavior_AllowsCharacterPickerTouchBarItem, AttributeInfo(className: "NSTextField", fullTitle: "AllowsCharacterPickerTouchBarItem", getterString: "allowsCharacterPickerTouchBarItem", setterString: "setAllowsCharacterPickerTouchBarItem:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextField_BorderShape, title: "BorderShape", attributes: [
                BlueprintAttribute(LookinAttr_NSTextField_BorderShape_BorderShape, AttributeInfo(className: "NSTextField", fullTitle: "BorderShape", getterString: "borderShape", setterString: "setBorderShape:", enumList: "NSControlBorderShape", patch: true, revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSVisualEffectView_MaskImage, title: "MaskImage", attributes: [
                BlueprintAttribute(LookinAttr_NSVisualEffectView_MaskImage_MaskImage, AttributeInfo(className: "NSVisualEffectView", fullTitle: "MaskImage", getterString: "maskImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
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
            BlueprintSection(LookinAttrSec_NSWindow_ContentLayoutRect, title: "ContentLayoutRect", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_ContentLayoutRect_ContentLayoutRect, AttributeInfo(className: "NSWindow", fullTitle: "ContentLayoutRect", getterString: "contentLayoutRect", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_RepresentedURL, title: "RepresentedURL", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_RepresentedURL_RepresentedURL, AttributeInfo(className: "NSWindow", fullTitle: "RepresentedURL", getterString: "representedURL", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.url))),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_RepresentedFilename, title: "RepresentedFilename", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_RepresentedFilename_RepresentedFilename, AttributeInfo(className: "NSWindow", fullTitle: "RepresentedFilename", getterString: "representedFilename", setterString: "setRepresentedFilename:", typeIfObj: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_Flags, title: "Flags", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_Flags_ExcludedFromWindowsMenu, AttributeInfo(className: "NSWindow", fullTitle: "ExcludedFromWindowsMenu", getterString: "isExcludedFromWindowsMenu", setterString: "setExcludedFromWindowsMenu:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_InLiveResize, AttributeInfo(className: "NSWindow", fullTitle: "InLiveResize", getterString: "inLiveResize", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_ViewsNeedDisplay, AttributeInfo(className: "NSWindow", fullTitle: "ViewsNeedDisplay", getterString: "viewsNeedDisplay", setterString: "setViewsNeedDisplay:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_PreservesContentDuringLiveResize, AttributeInfo(className: "NSWindow", fullTitle: "PreservesContentDuringLiveResize", getterString: "preservesContentDuringLiveResize", setterString: "setPreservesContentDuringLiveResize:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_ReleasedWhenClosed, AttributeInfo(className: "NSWindow", fullTitle: "ReleasedWhenClosed", getterString: "isReleasedWhenClosed", setterString: "setReleasedWhenClosed:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_Zoomed, AttributeInfo(className: "NSWindow", fullTitle: "Zoomed", getterString: "isZoomed", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_Miniaturized, AttributeInfo(className: "NSWindow", fullTitle: "Miniaturized", getterString: "isMiniaturized", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_CanHide, AttributeInfo(className: "NSWindow", fullTitle: "CanHide", getterString: "canHide", setterString: "setCanHide:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_DocumentEdited, AttributeInfo(className: "NSWindow", fullTitle: "DocumentEdited", getterString: "isDocumentEdited", setterString: "setDocumentEdited:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_WorksWhenModal, AttributeInfo(className: "NSWindow", fullTitle: "WorksWhenModal", getterString: "worksWhenModal", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_PreventsApplicationTerminationWhenModal, AttributeInfo(className: "NSWindow", fullTitle: "PreventsApplicationTerminationWhenModal", getterString: "preventsApplicationTerminationWhenModal", setterString: "setPreventsApplicationTerminationWhenModal:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_AllowsToolTipsWhenApplicationIsInactive, AttributeInfo(className: "NSWindow", fullTitle: "AllowsToolTipsWhenApplicationIsInactive", getterString: "allowsToolTipsWhenApplicationIsInactive", setterString: "setAllowsToolTipsWhenApplicationIsInactive:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_HasDynamicDepthLimit, AttributeInfo(className: "NSWindow", fullTitle: "HasDynamicDepthLimit", getterString: "hasDynamicDepthLimit", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_AllowsConcurrentViewDrawing, AttributeInfo(className: "NSWindow", fullTitle: "AllowsConcurrentViewDrawing", getterString: "allowsConcurrentViewDrawing", setterString: "setAllowsConcurrentViewDrawing:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_DisplaysWhenScreenProfileChanges, AttributeInfo(className: "NSWindow", fullTitle: "DisplaysWhenScreenProfileChanges", getterString: "displaysWhenScreenProfileChanges", setterString: "setDisplaysWhenScreenProfileChanges:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_CanBecomeVisibleWithoutLogin, AttributeInfo(className: "NSWindow", fullTitle: "CanBecomeVisibleWithoutLogin", getterString: "canBecomeVisibleWithoutLogin", setterString: "setCanBecomeVisibleWithoutLogin:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_OnActiveSpace, AttributeInfo(className: "NSWindow", fullTitle: "OnActiveSpace", getterString: "isOnActiveSpace", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_Sheet, AttributeInfo(className: "NSWindow", fullTitle: "Sheet", getterString: "isSheet", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_AutorecalculatesKeyViewLoop, AttributeInfo(className: "NSWindow", fullTitle: "AutorecalculatesKeyViewLoop", getterString: "autorecalculatesKeyViewLoop", setterString: "setAutorecalculatesKeyViewLoop:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_HasActiveWindowSharingSession, AttributeInfo(className: "NSWindow", fullTitle: "HasActiveWindowSharingSession", getterString: "hasActiveWindowSharingSession", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_AcceptsMouseMovedEvents, AttributeInfo(className: "NSWindow", fullTitle: "AcceptsMouseMovedEvents", getterString: "acceptsMouseMovedEvents", setterString: "setAcceptsMouseMovedEvents:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_IgnoresMouseEvents, AttributeInfo(className: "NSWindow", fullTitle: "IgnoresMouseEvents", getterString: "ignoresMouseEvents", setterString: "setIgnoresMouseEvents:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_AreCursorRectsEnabled, AttributeInfo(className: "NSWindow", fullTitle: "AreCursorRectsEnabled", getterString: "areCursorRectsEnabled", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_Restorable, AttributeInfo(className: "NSWindow", fullTitle: "Restorable", getterString: "isRestorable", setterString: "setRestorable:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_HasCloseBox, AttributeInfo(className: "NSWindow", fullTitle: "HasCloseBox", getterString: "hasCloseBox", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_HasTitleBar, AttributeInfo(className: "NSWindow", fullTitle: "HasTitleBar", getterString: "hasTitleBar", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_FloatingPanel, AttributeInfo(className: "NSWindow", fullTitle: "FloatingPanel", getterString: "isFloatingPanel", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_Miniaturizable, AttributeInfo(className: "NSWindow", fullTitle: "Miniaturizable", getterString: "isMiniaturizable", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_ModalPanel, AttributeInfo(className: "NSWindow", fullTitle: "ModalPanel", getterString: "isModalPanel", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_Resizable, AttributeInfo(className: "NSWindow", fullTitle: "Resizable", getterString: "isResizable", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSWindow_Flags_Zoomable, AttributeInfo(className: "NSWindow", fullTitle: "Zoomable", getterString: "isZoomable", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_StyleMask, title: "StyleMask", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_StyleMask_StyleMask, AttributeInfo(className: "NSWindow", fullTitle: "StyleMask", getterString: "styleMask", setterString: "", revision: 1, presentation: .optionNames("NSWindowStyleMask"))),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_CascadingReferenceFrame, title: "CascadingReferenceFrame", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_CascadingReferenceFrame_CascadingReferenceFrame, AttributeInfo(className: "NSWindow", fullTitle: "CascadingReferenceFrame", getterString: "cascadingReferenceFrame", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_ResizeIncrements, title: "ResizeIncrements", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_ResizeIncrements_ResizeIncrements, AttributeInfo(className: "NSWindow", fullTitle: "ResizeIncrements", getterString: "resizeIncrements", setterString: "setResizeIncrements:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_AspectRatio, title: "AspectRatio", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_AspectRatio_AspectRatio, AttributeInfo(className: "NSWindow", fullTitle: "AspectRatio", getterString: "aspectRatio", setterString: "setAspectRatio:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_ContentResizeIncrements, title: "ContentResizeIncrements", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_ContentResizeIncrements_ContentResizeIncrements, AttributeInfo(className: "NSWindow", fullTitle: "ContentResizeIncrements", getterString: "contentResizeIncrements", setterString: "setContentResizeIncrements:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_ContentAspectRatio, title: "ContentAspectRatio", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_ContentAspectRatio_ContentAspectRatio, AttributeInfo(className: "NSWindow", fullTitle: "ContentAspectRatio", getterString: "contentAspectRatio", setterString: "setContentAspectRatio:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_MiniwindowTitle, title: "MiniwindowTitle", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_MiniwindowTitle_MiniwindowTitle, AttributeInfo(className: "NSWindow", fullTitle: "MiniwindowTitle", getterString: "miniwindowTitle", setterString: "setMiniwindowTitle:", typeIfObj: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_BackingType, title: "BackingType", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_BackingType_BackingType, AttributeInfo(className: "NSWindow", fullTitle: "BackingType", getterString: "backingType", setterString: "setBackingType:", enumList: "NSBackingStoreType", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_DepthLimit, title: "DepthLimit", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_DepthLimit_DepthLimit, AttributeInfo(className: "NSWindow", fullTitle: "DepthLimit", getterString: "depthLimit", setterString: "setDepthLimit:", enumList: "NSWindowDepth", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_Screen, title: "Screen", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_Screen_Screen, AttributeInfo(className: "NSWindow", fullTitle: "Screen", getterString: "screen", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.screen))),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_DeepestScreen, title: "DeepestScreen", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_DeepestScreen_DeepestScreen, AttributeInfo(className: "NSWindow", fullTitle: "DeepestScreen", getterString: "deepestScreen", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.screen))),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_SharingType, title: "SharingType", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_SharingType_SharingType, AttributeInfo(className: "NSWindow", fullTitle: "SharingType", getterString: "sharingType", setterString: "setSharingType:", enumList: "NSWindowSharingType", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_CollectionBehaviorOptions, title: "CollectionBehaviorOptions", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_CollectionBehaviorOptions_CollectionBehavior, AttributeInfo(className: "NSWindow", fullTitle: "CollectionBehavior", getterString: "collectionBehavior", setterString: "", revision: 1, presentation: .optionNames("NSWindowCollectionBehavior"))),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_ContentMinSize, title: "ContentMinSize", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_ContentMinSize_ContentMinSize, AttributeInfo(className: "NSWindow", fullTitle: "ContentMinSize", getterString: "contentMinSize", setterString: "setContentMinSize:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_ContentMaxSize, title: "ContentMaxSize", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_ContentMaxSize_ContentMaxSize, AttributeInfo(className: "NSWindow", fullTitle: "ContentMaxSize", getterString: "contentMaxSize", setterString: "setContentMaxSize:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_MinFullScreenContentSize, title: "MinFullScreenContentSize", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_MinFullScreenContentSize_MinFullScreenContentSize, AttributeInfo(className: "NSWindow", fullTitle: "MinFullScreenContentSize", getterString: "minFullScreenContentSize", setterString: "setMinFullScreenContentSize:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_MaxFullScreenContentSize, title: "MaxFullScreenContentSize", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_MaxFullScreenContentSize_MaxFullScreenContentSize, AttributeInfo(className: "NSWindow", fullTitle: "MaxFullScreenContentSize", getterString: "maxFullScreenContentSize", setterString: "setMaxFullScreenContentSize:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_OcclusionState, title: "OcclusionState", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_OcclusionState_OcclusionState, AttributeInfo(className: "NSWindow", fullTitle: "OcclusionState", getterString: "occlusionState", setterString: "", revision: 1, presentation: .optionNames("NSWindowOcclusionState"))),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_KeyViewSelectionDirection, title: "KeyViewSelectionDirection", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_KeyViewSelectionDirection_KeyViewSelectionDirection, AttributeInfo(className: "NSWindow", fullTitle: "KeyViewSelectionDirection", getterString: "keyViewSelectionDirection", setterString: "", enumList: "NSSelectionDirection", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_Toolbar, title: "Toolbar", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_Toolbar_Toolbar, AttributeInfo(className: "NSWindow", fullTitle: "Toolbar", getterString: "toolbar", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.toolbar))),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_OrderedIndex, title: "OrderedIndex", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_OrderedIndex_OrderedIndex, AttributeInfo(className: "NSWindow", fullTitle: "OrderedIndex", getterString: "orderedIndex", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSWindow_FirstResponder, title: "FirstResponder", attributes: [
                BlueprintAttribute(LookinAttr_NSWindow_FirstResponder_FirstResponder, AttributeInfo(className: "NSWindow", fullTitle: "FirstResponder", getterString: "firstResponder", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.className))),
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
            BlueprintSection(LookinAttrSec_NSSlider_NeutralValue, title: "NeutralValue", attributes: [
                BlueprintAttribute(LookinAttr_NSSlider_NeutralValue_NeutralValue, AttributeInfo(className: "NSSlider", fullTitle: "NeutralValue", getterString: "neutralValue", setterString: "setNeutralValue:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSSlider_TintProminence, title: "TintProminence", attributes: [
                BlueprintAttribute(LookinAttr_NSSlider_TintProminence_TintProminence, AttributeInfo(className: "NSSlider", fullTitle: "TintProminence", getterString: "tintProminence", setterString: "setTintProminence:", enumList: "NSTintProminence", patch: true, revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSProgressIndicator_ControlSize, title: "ControlSize", attributes: [
                BlueprintAttribute(LookinAttr_NSProgressIndicator_ControlSize_ControlSize, AttributeInfo(className: "NSProgressIndicator", fullTitle: "ControlSize", getterString: "controlSize", setterString: "setControlSize:", enumList: "NSControlSize", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSProgressIndicator_UsesThreadedAnimation, title: "UsesThreadedAnimation", attributes: [
                BlueprintAttribute(LookinAttr_NSProgressIndicator_UsesThreadedAnimation_UsesThreadedAnimation, AttributeInfo(className: "NSProgressIndicator", fullTitle: "UsesThreadedAnimation", getterString: "usesThreadedAnimation", setterString: "setUsesThreadedAnimation:", patch: true, revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSSegmentedControl_Role, title: "Role", attributes: [
                BlueprintAttribute(LookinAttr_NSSegmentedControl_Role_Role, AttributeInfo(className: "NSSegmentedControl", fullTitle: "Role", getterString: "role", setterString: "setRole:", enumList: "NSSegmentedControlRole", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSSegmentedControl_SpringLoaded, title: "SpringLoaded", attributes: [
                BlueprintAttribute(LookinAttr_NSSegmentedControl_SpringLoaded_SpringLoaded, AttributeInfo(className: "NSSegmentedControl", fullTitle: "SpringLoaded", getterString: "isSpringLoaded", setterString: "setSpringLoaded:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSSegmentedControl_DoubleValueForSelectedSegment, title: "DoubleValueForSelectedSegment", attributes: [
                BlueprintAttribute(LookinAttr_NSSegmentedControl_DoubleValueForSelectedSegment_DoubleValueForSelectedSegment, AttributeInfo(className: "NSSegmentedControl", fullTitle: "DoubleValueForSelectedSegment", getterString: "doubleValueForSelectedSegment", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSSegmentedControl_IndexOfSelectedItem, title: "IndexOfSelectedItem", attributes: [
                BlueprintAttribute(LookinAttr_NSSegmentedControl_IndexOfSelectedItem_IndexOfSelectedItem, AttributeInfo(className: "NSSegmentedControl", fullTitle: "IndexOfSelectedItem", getterString: "indexOfSelectedItem", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSSegmentedControl_SegmentDistribution, title: "SegmentDistribution", attributes: [
                BlueprintAttribute(LookinAttr_NSSegmentedControl_SegmentDistribution_SegmentDistribution, AttributeInfo(className: "NSSegmentedControl", fullTitle: "SegmentDistribution", getterString: "segmentDistribution", setterString: "setSegmentDistribution:", enumList: "NSSegmentDistribution", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSSegmentedControl_BorderShape, title: "BorderShape", attributes: [
                BlueprintAttribute(LookinAttr_NSSegmentedControl_BorderShape_BorderShape, AttributeInfo(className: "NSSegmentedControl", fullTitle: "BorderShape", getterString: "borderShape", setterString: "setBorderShape:", enumList: "NSControlBorderShape", patch: true, revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSPopUpButton_Menu, title: "Menu", attributes: [
                BlueprintAttribute(LookinAttr_NSPopUpButton_Menu_Menu, AttributeInfo(className: "NSPopUpButton", fullTitle: "Menu", getterString: "menu", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.menu))),
            ]),
            BlueprintSection(LookinAttrSec_NSPopUpButton_Flags, title: "Flags", attributes: [
                BlueprintAttribute(LookinAttr_NSPopUpButton_Flags_UsesItemFromMenu, AttributeInfo(className: "NSPopUpButton", fullTitle: "UsesItemFromMenu", getterString: "usesItemFromMenu", setterString: "setUsesItemFromMenu:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSPopUpButton_Flags_AltersStateOfSelectedItem, AttributeInfo(className: "NSPopUpButton", fullTitle: "AltersStateOfSelectedItem", getterString: "altersStateOfSelectedItem", setterString: "setAltersStateOfSelectedItem:", patch: true, revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSComboBox_IndexOfSelectedItem, title: "IndexOfSelectedItem", attributes: [
                BlueprintAttribute(LookinAttr_NSComboBox_IndexOfSelectedItem_IndexOfSelectedItem, AttributeInfo(className: "NSComboBox", fullTitle: "IndexOfSelectedItem", getterString: "indexOfSelectedItem", setterString: "", revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSColorWell_Image, title: "Image", attributes: [
                BlueprintAttribute(LookinAttr_NSColorWell_Image_Image, AttributeInfo(className: "NSColorWell", fullTitle: "Image", getterString: "image", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(LookinAttrSec_NSColorWell_SupportsAlpha, title: "SupportsAlpha", attributes: [
                BlueprintAttribute(LookinAttr_NSColorWell_SupportsAlpha_SupportsAlpha, AttributeInfo(className: "NSColorWell", fullTitle: "SupportsAlpha", getterString: "supportsAlpha", setterString: "setSupportsAlpha:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSColorWell_MaximumLinearExposure, title: "MaximumLinearExposure", attributes: [
                BlueprintAttribute(LookinAttr_NSColorWell_MaximumLinearExposure_MaximumLinearExposure, AttributeInfo(className: "NSColorWell", fullTitle: "MaximumLinearExposure", getterString: "maximumLinearExposure", setterString: "setMaximumLinearExposure:", patch: true, revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSDatePicker_Colors, title: "Colors", attributes: [
                BlueprintAttribute(LookinAttr_NSDatePicker_Colors_BackgroundColor, AttributeInfo(className: "NSDatePicker", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSDatePicker_Colors_TextColor, AttributeInfo(className: "NSDatePicker", fullTitle: "TextColor", getterString: "textColor", setterString: "setTextColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSDatePicker_DatePickerElements, title: "DatePickerElements", attributes: [
                BlueprintAttribute(LookinAttr_NSDatePicker_DatePickerElements_DatePickerElements, AttributeInfo(className: "NSDatePicker", fullTitle: "DatePickerElements", getterString: "datePickerElements", setterString: "", revision: 1, presentation: .optionNames("NSDatePickerElementFlags"))),
            ]),
            BlueprintSection(LookinAttrSec_NSDatePicker_Calendar, title: "Calendar", attributes: [
                BlueprintAttribute(LookinAttr_NSDatePicker_Calendar_Calendar, AttributeInfo(className: "NSDatePicker", fullTitle: "Calendar", getterString: "calendar", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.calendar))),
            ]),
            BlueprintSection(LookinAttrSec_NSDatePicker_Locale, title: "Locale", attributes: [
                BlueprintAttribute(LookinAttr_NSDatePicker_Locale_Locale, AttributeInfo(className: "NSDatePicker", fullTitle: "Locale", getterString: "locale", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.locale))),
            ]),
            BlueprintSection(LookinAttrSec_NSDatePicker_TimeZone, title: "TimeZone", attributes: [
                BlueprintAttribute(LookinAttr_NSDatePicker_TimeZone_TimeZone, AttributeInfo(className: "NSDatePicker", fullTitle: "TimeZone", getterString: "timeZone", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.timeZone))),
            ]),
            BlueprintSection(LookinAttrSec_NSDatePicker_TimeInterval, title: "TimeInterval", attributes: [
                BlueprintAttribute(LookinAttr_NSDatePicker_TimeInterval_TimeInterval, AttributeInfo(className: "NSDatePicker", fullTitle: "TimeInterval", getterString: "timeInterval", setterString: "setTimeInterval:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSDatePicker_PresentsCalendarOverlay, title: "PresentsCalendarOverlay", attributes: [
                BlueprintAttribute(LookinAttr_NSDatePicker_PresentsCalendarOverlay_PresentsCalendarOverlay, AttributeInfo(className: "NSDatePicker", fullTitle: "PresentsCalendarOverlay", getterString: "presentsCalendarOverlay", setterString: "setPresentsCalendarOverlay:", patch: true, revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSLevelIndicator_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_NSLevelIndicator_Behavior_Editable, AttributeInfo(className: "NSLevelIndicator", fullTitle: "Editable", getterString: "isEditable", setterString: "setEditable:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSLevelIndicator_Behavior_DrawsTieredCapacityLevels, AttributeInfo(className: "NSLevelIndicator", fullTitle: "DrawsTieredCapacityLevels", getterString: "drawsTieredCapacityLevels", setterString: "setDrawsTieredCapacityLevels:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSLevelIndicator_TickMarkPosition, title: "TickMarkPosition", attributes: [
                BlueprintAttribute(LookinAttr_NSLevelIndicator_TickMarkPosition_TickMarkPosition, AttributeInfo(className: "NSLevelIndicator", fullTitle: "TickMarkPosition", getterString: "tickMarkPosition", setterString: "setTickMarkPosition:", enumList: "NSTickMarkPosition", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSLevelIndicator_Colors, title: "Colors", attributes: [
                BlueprintAttribute(LookinAttr_NSLevelIndicator_Colors_FillColor, AttributeInfo(className: "NSLevelIndicator", fullTitle: "FillColor", getterString: "fillColor", setterString: "setFillColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSLevelIndicator_Colors_WarningFillColor, AttributeInfo(className: "NSLevelIndicator", fullTitle: "WarningFillColor", getterString: "warningFillColor", setterString: "setWarningFillColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSLevelIndicator_Colors_CriticalFillColor, AttributeInfo(className: "NSLevelIndicator", fullTitle: "CriticalFillColor", getterString: "criticalFillColor", setterString: "setCriticalFillColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSLevelIndicator_PlaceholderVisibility, title: "PlaceholderVisibility", attributes: [
                BlueprintAttribute(LookinAttr_NSLevelIndicator_PlaceholderVisibility_PlaceholderVisibility, AttributeInfo(className: "NSLevelIndicator", fullTitle: "PlaceholderVisibility", getterString: "placeholderVisibility", setterString: "setPlaceholderVisibility:", enumList: "NSLevelIndicatorPlaceholderVisibility", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSLevelIndicator_Images, title: "Images", attributes: [
                BlueprintAttribute(LookinAttr_NSLevelIndicator_Images_RatingImage, AttributeInfo(className: "NSLevelIndicator", fullTitle: "RatingImage", getterString: "ratingImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_NSLevelIndicator_Images_RatingPlaceholderImage, AttributeInfo(className: "NSLevelIndicator", fullTitle: "RatingPlaceholderImage", getterString: "ratingPlaceholderImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
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
            BlueprintSection(LookinAttrSec_NSOutlineView_UserInterfaceLayoutDirection, title: "UserInterfaceLayoutDirection", attributes: [
                BlueprintAttribute(LookinAttr_NSOutlineView_UserInterfaceLayoutDirection_UserInterfaceLayoutDirection, AttributeInfo(className: "NSOutlineView", fullTitle: "UserInterfaceLayoutDirection", getterString: "userInterfaceLayoutDirection", setterString: "setUserInterfaceLayoutDirection:", enumList: "NSUserInterfaceLayoutDirection", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSOutlineView_StronglyReferencesItems, title: "StronglyReferencesItems", attributes: [
                BlueprintAttribute(LookinAttr_NSOutlineView_StronglyReferencesItems_StronglyReferencesItems, AttributeInfo(className: "NSOutlineView", fullTitle: "StronglyReferencesItems", getterString: "stronglyReferencesItems", setterString: "setStronglyReferencesItems:", patch: true, revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSCollectionView_BackgroundViewScrollsWithContent, title: "BackgroundViewScrollsWithContent", attributes: [
                BlueprintAttribute(LookinAttr_NSCollectionView_BackgroundViewScrollsWithContent_BackgroundViewScrollsWithContent, AttributeInfo(className: "NSCollectionView", fullTitle: "BackgroundViewScrollsWithContent", getterString: "backgroundViewScrollsWithContent", setterString: "setBackgroundViewScrollsWithContent:", patch: true, revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSBox_TitleFont, title: "TitleFont", attributes: [
                BlueprintAttribute(LookinAttr_NSBox_TitleFont_TitleFont, AttributeInfo(className: "NSBox", fullTitle: "TitleFont", getterString: "titleFont", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.font))),
            ]),
            BlueprintSection(LookinAttrSec_NSBox_BorderRect, title: "BorderRect", attributes: [
                BlueprintAttribute(LookinAttr_NSBox_BorderRect_BorderRect, AttributeInfo(className: "NSBox", fullTitle: "BorderRect", getterString: "borderRect", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSBox_TitleRect, title: "TitleRect", attributes: [
                BlueprintAttribute(LookinAttr_NSBox_TitleRect_TitleRect, AttributeInfo(className: "NSBox", fullTitle: "TitleRect", getterString: "titleRect", setterString: "", revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSSplitView_DividerColor, title: "DividerColor", attributes: [
                BlueprintAttribute(LookinAttr_NSSplitView_DividerColor_DividerColor, AttributeInfo(className: "NSSplitView", fullTitle: "DividerColor", getterString: "dividerColor", setterString: "", typeIfObj: .uiColor, hideIfNil: true, revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSTabView_Font, title: "Font", attributes: [
                BlueprintAttribute(LookinAttr_NSTabView_Font_Font, AttributeInfo(className: "NSTabView", fullTitle: "Font", getterString: "font", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.font))),
            ]),
            BlueprintSection(LookinAttrSec_NSTabView_MinimumSize, title: "MinimumSize", attributes: [
                BlueprintAttribute(LookinAttr_NSTabView_MinimumSize_MinimumSize, AttributeInfo(className: "NSTabView", fullTitle: "MinimumSize", getterString: "minimumSize", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTabView_ControlSize, title: "ControlSize", attributes: [
                BlueprintAttribute(LookinAttr_NSTabView_ControlSize_ControlSize, AttributeInfo(className: "NSTabView", fullTitle: "ControlSize", getterString: "controlSize", setterString: "setControlSize:", enumList: "NSControlSize", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTabView_ContentRect, title: "ContentRect", attributes: [
                BlueprintAttribute(LookinAttr_NSTabView_ContentRect_ContentRect, AttributeInfo(className: "NSTabView", fullTitle: "ContentRect", getterString: "contentRect", setterString: "", revision: 1)),
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
            BlueprintSection(LookinAttrSec_NSGridView_RowAlignment, title: "RowAlignment", attributes: [
                BlueprintAttribute(LookinAttr_NSGridView_RowAlignment_RowAlignment, AttributeInfo(className: "NSGridView", fullTitle: "RowAlignment", getterString: "rowAlignment", setterString: "setRowAlignment:", enumList: "NSGridRowAlignment", patch: true, revision: 1)),
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
                BlueprintAttribute(LookinAttr_NSCell_ButtonCell_HighlightsBy, AttributeInfo(className: "NSButtonCell", fullTitle: "HighlightsBy", getterString: "highlightsBy", setterString: "", revision: 1, presentation: .optionNames("NSCellStyleMask"))),
                BlueprintAttribute(LookinAttr_NSCell_ButtonCell_ShowsStateBy, AttributeInfo(className: "NSButtonCell", fullTitle: "ShowsStateBy", getterString: "showsStateBy", setterString: "", revision: 1, presentation: .optionNames("NSCellStyleMask"))),
                BlueprintAttribute(LookinAttr_NSCell_ButtonCell_Title, AttributeInfo(className: "NSButtonCell", fullTitle: "Title", getterString: "title", setterString: "", typeIfObj: .nsString, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_ButtonCell_AttributedTitle, AttributeInfo(className: "NSButtonCell", fullTitle: "AttributedTitle", getterString: "attributedTitle", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.attributedString))),
                BlueprintAttribute(LookinAttr_NSCell_ButtonCell_AttributedAlternateTitle, AttributeInfo(className: "NSButtonCell", fullTitle: "AttributedAlternateTitle", getterString: "attributedAlternateTitle", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.attributedString))),
                BlueprintAttribute(LookinAttr_NSCell_ButtonCell_AlternateImage, AttributeInfo(className: "NSButtonCell", fullTitle: "AlternateImage", getterString: "alternateImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_NSCell_ButtonCell_ImageScaling, AttributeInfo(className: "NSButtonCell", fullTitle: "ImageScaling", getterString: "imageScaling", setterString: "", enumList: "NSImageScaling", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_ButtonCell_KeyEquivalentModifierMask, AttributeInfo(className: "NSButtonCell", fullTitle: "KeyEquivalentModifierMask", getterString: "keyEquivalentModifierMask", setterString: "", revision: 1, presentation: .optionNames("NSEventModifierFlags"))),
                BlueprintAttribute(LookinAttr_NSCell_ButtonCell_Transparent, AttributeInfo(className: "NSButtonCell", fullTitle: "Transparent", getterString: "isTransparent", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_ButtonCell_Opaque, AttributeInfo(className: "NSButtonCell", fullTitle: "Opaque", getterString: "isOpaque", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_ButtonCell_ImageDimsWhenDisabled, AttributeInfo(className: "NSButtonCell", fullTitle: "ImageDimsWhenDisabled", getterString: "imageDimsWhenDisabled", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_ButtonCell_BackgroundColor, AttributeInfo(className: "NSButtonCell", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "", typeIfObj: .uiColor, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_TextFieldCell, title: "NSTextFieldCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_TextFieldCell_Placeholder, AttributeInfo(className: "NSTextFieldCell", fullTitle: "Placeholder", getterString: "placeholderString", setterString: "", typeIfObj: .nsString, hideIfNil: true)),
                BlueprintAttribute(LookinAttr_NSCell_TextFieldCell_DrawsBackground, AttributeInfo(className: "NSTextFieldCell", fullTitle: "DrawsBackground", getterString: "drawsBackground", setterString: "")),
                BlueprintAttribute(LookinAttr_NSCell_TextFieldCell_TextColor, AttributeInfo(className: "NSTextFieldCell", fullTitle: "TextColor", getterString: "textColor", setterString: "", typeIfObj: .uiColor, hideIfNil: true)),
                BlueprintAttribute(LookinAttr_NSCell_TextFieldCell_BackgroundColor, AttributeInfo(className: "NSTextFieldCell", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "", typeIfObj: .uiColor, hideIfNil: true)),
                BlueprintAttribute(LookinAttr_NSCell_TextFieldCell_BezelStyle, AttributeInfo(className: "NSTextFieldCell", fullTitle: "BezelStyle", getterString: "bezelStyle", setterString: "", enumList: "NSTextFieldBezelStyle")),
                BlueprintAttribute(LookinAttr_NSCell_TextFieldCell_PlaceholderAttributedString, AttributeInfo(className: "NSTextFieldCell", fullTitle: "PlaceholderAttributedString", getterString: "placeholderAttributedString", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.attributedString))),
                BlueprintAttribute(LookinAttr_NSCell_TextFieldCell_AllowedInputSourceLocales, AttributeInfo(className: "NSTextFieldCell", fullTitle: "AllowedInputSourceLocales", getterString: "allowedInputSourceLocales", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_ControlView, title: "ControlView", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_ControlView_ControlView, AttributeInfo(className: "NSCell", fullTitle: "ControlView", getterString: "controlView", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.className))),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_Flags, title: "Flags", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_Flags_Opaque, AttributeInfo(className: "NSCell", fullTitle: "Opaque", getterString: "isOpaque", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_Flags_Scrollable, AttributeInfo(className: "NSCell", fullTitle: "Scrollable", getterString: "isScrollable", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_Flags_HasValidObjectValue, AttributeInfo(className: "NSCell", fullTitle: "HasValidObjectValue", getterString: "hasValidObjectValue", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_Flags_AllowsUndo, AttributeInfo(className: "NSCell", fullTitle: "AllowsUndo", getterString: "allowsUndo", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_Flags_TruncatesLastVisibleLine, AttributeInfo(className: "NSCell", fullTitle: "TruncatesLastVisibleLine", getterString: "truncatesLastVisibleLine", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_Flags_UsesSingleLineMode, AttributeInfo(className: "NSCell", fullTitle: "UsesSingleLineMode", getterString: "usesSingleLineMode", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_Flags_RefusesFirstResponder, AttributeInfo(className: "NSCell", fullTitle: "RefusesFirstResponder", getterString: "refusesFirstResponder", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_Flags_AcceptsFirstResponder, AttributeInfo(className: "NSCell", fullTitle: "AcceptsFirstResponder", getterString: "acceptsFirstResponder", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_Flags_ShowsFirstResponder, AttributeInfo(className: "NSCell", fullTitle: "ShowsFirstResponder", getterString: "showsFirstResponder", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_Flags_WantsNotificationForMarkedText, AttributeInfo(className: "NSCell", fullTitle: "WantsNotificationForMarkedText", getterString: "wantsNotificationForMarkedText", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_Flags_AllowsEditingTextAttributes, AttributeInfo(className: "NSCell", fullTitle: "AllowsEditingTextAttributes", getterString: "allowsEditingTextAttributes", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_Flags_ImportsGraphics, AttributeInfo(className: "NSCell", fullTitle: "ImportsGraphics", getterString: "importsGraphics", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_Font, title: "Font", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_Font_Font, AttributeInfo(className: "NSCell", fullTitle: "Font", getterString: "font", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.font))),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_KeyEquivalent, title: "KeyEquivalent", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_KeyEquivalent_KeyEquivalent, AttributeInfo(className: "NSCell", fullTitle: "KeyEquivalent", getterString: "keyEquivalent", setterString: "", typeIfObj: .nsString, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_StringValue, title: "StringValue", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_StringValue_StringValue, AttributeInfo(className: "NSCell", fullTitle: "StringValue", getterString: "stringValue", setterString: "", typeIfObj: .nsString, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_IntValue, title: "IntValue", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_IntValue_IntValue, AttributeInfo(className: "NSCell", fullTitle: "IntValue", getterString: "intValue", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_FloatValue, title: "FloatValue", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_FloatValue_FloatValue, AttributeInfo(className: "NSCell", fullTitle: "FloatValue", getterString: "floatValue", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_DoubleValue, title: "DoubleValue", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_DoubleValue_DoubleValue, AttributeInfo(className: "NSCell", fullTitle: "DoubleValue", getterString: "doubleValue", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_IntegerValue, title: "IntegerValue", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_IntegerValue_IntegerValue, AttributeInfo(className: "NSCell", fullTitle: "IntegerValue", getterString: "integerValue", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_Image, title: "Image", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_Image_Image, AttributeInfo(className: "NSCell", fullTitle: "Image", getterString: "image", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_CellSize, title: "CellSize", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_CellSize_CellSize, AttributeInfo(className: "NSCell", fullTitle: "CellSize", getterString: "cellSize", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_MouseDownFlags, title: "MouseDownFlags", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_MouseDownFlags_MouseDownFlags, AttributeInfo(className: "NSCell", fullTitle: "MouseDownFlags", getterString: "mouseDownFlags", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_Menu, title: "Menu", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_Menu_Menu, AttributeInfo(className: "NSCell", fullTitle: "Menu", getterString: "menu", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.menu))),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_BaseWritingDirection, title: "BaseWritingDirection", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_BaseWritingDirection_BaseWritingDirection, AttributeInfo(className: "NSCell", fullTitle: "BaseWritingDirection", getterString: "baseWritingDirection", setterString: "", enumList: "NSWritingDirection", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_UserInterfaceLayoutDirection, title: "UserInterfaceLayoutDirection", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_UserInterfaceLayoutDirection_UserInterfaceLayoutDirection, AttributeInfo(className: "NSCell", fullTitle: "UserInterfaceLayoutDirection", getterString: "userInterfaceLayoutDirection", setterString: "", enumList: "NSUserInterfaceLayoutDirection", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_FocusRingType, title: "FocusRingType", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_FocusRingType_FocusRingType, AttributeInfo(className: "NSCell", fullTitle: "FocusRingType", getterString: "focusRingType", setterString: "", enumList: "NSFocusRingType", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_AttributedStringValue, title: "AttributedStringValue", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_AttributedStringValue_AttributedStringValue, AttributeInfo(className: "NSCell", fullTitle: "AttributedStringValue", getterString: "attributedStringValue", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.attributedString))),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NextState, title: "NextState", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NextState_NextState, AttributeInfo(className: "NSCell", fullTitle: "NextState", getterString: "nextState", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_BackgroundStyle, title: "BackgroundStyle", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_BackgroundStyle_BackgroundStyle, AttributeInfo(className: "NSCell", fullTitle: "BackgroundStyle", getterString: "backgroundStyle", setterString: "", enumList: "NSBackgroundStyle", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_InteriorBackgroundStyle, title: "InteriorBackgroundStyle", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_InteriorBackgroundStyle_InteriorBackgroundStyle, AttributeInfo(className: "NSCell", fullTitle: "InteriorBackgroundStyle", getterString: "interiorBackgroundStyle", setterString: "", enumList: "NSBackgroundStyle", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NSActionCell, title: "NSActionCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NSActionCell_Tag, AttributeInfo(className: "NSActionCell", fullTitle: "Tag", getterString: "tag", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NSMenuItemCell, title: "NSMenuItemCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NSMenuItemCell_NeedsSizing, AttributeInfo(className: "NSMenuItemCell", fullTitle: "NeedsSizing", getterString: "needsSizing", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSMenuItemCell_NeedsDisplay, AttributeInfo(className: "NSMenuItemCell", fullTitle: "NeedsDisplay", getterString: "needsDisplay", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSMenuItemCell_Tag, AttributeInfo(className: "NSMenuItemCell", fullTitle: "Tag", getterString: "tag", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NSPopUpButtonCell, title: "NSPopUpButtonCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NSPopUpButtonCell_Menu, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "Menu", getterString: "menu", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.menu))),
                BlueprintAttribute(LookinAttr_NSCell_NSPopUpButtonCell_PullsDown, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "PullsDown", getterString: "pullsDown", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSPopUpButtonCell_AutoenablesItems, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "AutoenablesItems", getterString: "autoenablesItems", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSPopUpButtonCell_PreferredEdge, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "PreferredEdge", getterString: "preferredEdge", setterString: "", enumList: "NSRectEdge", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSPopUpButtonCell_UsesItemFromMenu, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "UsesItemFromMenu", getterString: "usesItemFromMenu", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSPopUpButtonCell_AltersStateOfSelectedItem, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "AltersStateOfSelectedItem", getterString: "altersStateOfSelectedItem", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSPopUpButtonCell_NumberOfItems, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "NumberOfItems", getterString: "numberOfItems", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSPopUpButtonCell_IndexOfSelectedItem, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "IndexOfSelectedItem", getterString: "indexOfSelectedItem", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSPopUpButtonCell_ItemTitles, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "ItemTitles", getterString: "itemTitles", setterString: "", revision: 1, presentation: .count)),
                BlueprintAttribute(LookinAttr_NSCell_NSPopUpButtonCell_TitleOfSelectedItem, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "TitleOfSelectedItem", getterString: "titleOfSelectedItem", setterString: "", typeIfObj: .nsString, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSPopUpButtonCell_ArrowPosition, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "ArrowPosition", getterString: "arrowPosition", setterString: "", enumList: "NSPopUpArrowPosition", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NSDatePickerCell, title: "NSDatePickerCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NSDatePickerCell_DatePickerStyle, AttributeInfo(className: "NSDatePickerCell", fullTitle: "DatePickerStyle", getterString: "datePickerStyle", setterString: "", enumList: "NSDatePickerStyle", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSDatePickerCell_DrawsBackground, AttributeInfo(className: "NSDatePickerCell", fullTitle: "DrawsBackground", getterString: "drawsBackground", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSDatePickerCell_BackgroundColor, AttributeInfo(className: "NSDatePickerCell", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "", typeIfObj: .uiColor, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSDatePickerCell_TextColor, AttributeInfo(className: "NSDatePickerCell", fullTitle: "TextColor", getterString: "textColor", setterString: "", typeIfObj: .uiColor, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSDatePickerCell_DatePickerMode, AttributeInfo(className: "NSDatePickerCell", fullTitle: "DatePickerMode", getterString: "datePickerMode", setterString: "", enumList: "NSDatePickerMode", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSDatePickerCell_DatePickerElements, AttributeInfo(className: "NSDatePickerCell", fullTitle: "DatePickerElements", getterString: "datePickerElements", setterString: "", revision: 1, presentation: .optionNames("NSDatePickerElementFlags"))),
                BlueprintAttribute(LookinAttr_NSCell_NSDatePickerCell_Calendar, AttributeInfo(className: "NSDatePickerCell", fullTitle: "Calendar", getterString: "calendar", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.calendar))),
                BlueprintAttribute(LookinAttr_NSCell_NSDatePickerCell_Locale, AttributeInfo(className: "NSDatePickerCell", fullTitle: "Locale", getterString: "locale", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.locale))),
                BlueprintAttribute(LookinAttr_NSCell_NSDatePickerCell_TimeZone, AttributeInfo(className: "NSDatePickerCell", fullTitle: "TimeZone", getterString: "timeZone", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.timeZone))),
                BlueprintAttribute(LookinAttr_NSCell_NSDatePickerCell_DateValue, AttributeInfo(className: "NSDatePickerCell", fullTitle: "DateValue", getterString: "dateValue", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.date))),
                BlueprintAttribute(LookinAttr_NSCell_NSDatePickerCell_TimeInterval, AttributeInfo(className: "NSDatePickerCell", fullTitle: "TimeInterval", getterString: "timeInterval", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSDatePickerCell_MinDate, AttributeInfo(className: "NSDatePickerCell", fullTitle: "MinDate", getterString: "minDate", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.date))),
                BlueprintAttribute(LookinAttr_NSCell_NSDatePickerCell_MaxDate, AttributeInfo(className: "NSDatePickerCell", fullTitle: "MaxDate", getterString: "maxDate", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.date))),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NSFormCell, title: "NSFormCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NSFormCell_TitleWidth, AttributeInfo(className: "NSFormCell", fullTitle: "TitleWidth", getterString: "titleWidth", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSFormCell_Title, AttributeInfo(className: "NSFormCell", fullTitle: "Title", getterString: "title", setterString: "", typeIfObj: .nsString, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSFormCell_TitleFont, AttributeInfo(className: "NSFormCell", fullTitle: "TitleFont", getterString: "titleFont", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.font))),
                BlueprintAttribute(LookinAttr_NSCell_NSFormCell_Opaque, AttributeInfo(className: "NSFormCell", fullTitle: "Opaque", getterString: "isOpaque", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSFormCell_PlaceholderString, AttributeInfo(className: "NSFormCell", fullTitle: "PlaceholderString", getterString: "placeholderString", setterString: "", typeIfObj: .nsString, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSFormCell_PlaceholderAttributedString, AttributeInfo(className: "NSFormCell", fullTitle: "PlaceholderAttributedString", getterString: "placeholderAttributedString", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.attributedString))),
                BlueprintAttribute(LookinAttr_NSCell_NSFormCell_TitleAlignment, AttributeInfo(className: "NSFormCell", fullTitle: "TitleAlignment", getterString: "titleAlignment", setterString: "", enumList: "NSTextAlignment", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSFormCell_TitleBaseWritingDirection, AttributeInfo(className: "NSFormCell", fullTitle: "TitleBaseWritingDirection", getterString: "titleBaseWritingDirection", setterString: "", enumList: "NSWritingDirection", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSFormCell_PreferredTextFieldWidth, AttributeInfo(className: "NSFormCell", fullTitle: "PreferredTextFieldWidth", getterString: "preferredTextFieldWidth", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSFormCell_AttributedTitle, AttributeInfo(className: "NSFormCell", fullTitle: "AttributedTitle", getterString: "attributedTitle", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.attributedString))),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NSLevelIndicatorCell, title: "NSLevelIndicatorCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NSLevelIndicatorCell_LevelIndicatorStyle, AttributeInfo(className: "NSLevelIndicatorCell", fullTitle: "LevelIndicatorStyle", getterString: "levelIndicatorStyle", setterString: "", enumList: "NSLevelIndicatorStyle", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSLevelIndicatorCell_MinValue, AttributeInfo(className: "NSLevelIndicatorCell", fullTitle: "MinValue", getterString: "minValue", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSLevelIndicatorCell_MaxValue, AttributeInfo(className: "NSLevelIndicatorCell", fullTitle: "MaxValue", getterString: "maxValue", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSLevelIndicatorCell_WarningValue, AttributeInfo(className: "NSLevelIndicatorCell", fullTitle: "WarningValue", getterString: "warningValue", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSLevelIndicatorCell_CriticalValue, AttributeInfo(className: "NSLevelIndicatorCell", fullTitle: "CriticalValue", getterString: "criticalValue", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSLevelIndicatorCell_TickMarkPosition, AttributeInfo(className: "NSLevelIndicatorCell", fullTitle: "TickMarkPosition", getterString: "tickMarkPosition", setterString: "", enumList: "NSTickMarkPosition", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSLevelIndicatorCell_NumberOfTickMarks, AttributeInfo(className: "NSLevelIndicatorCell", fullTitle: "NumberOfTickMarks", getterString: "numberOfTickMarks", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSLevelIndicatorCell_NumberOfMajorTickMarks, AttributeInfo(className: "NSLevelIndicatorCell", fullTitle: "NumberOfMajorTickMarks", getterString: "numberOfMajorTickMarks", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NSPathCell, title: "NSPathCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NSPathCell_PathStyle, AttributeInfo(className: "NSPathCell", fullTitle: "PathStyle", getterString: "pathStyle", setterString: "", enumList: "NSPathStyle", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSPathCell_URL, AttributeInfo(className: "NSPathCell", fullTitle: "URL", getterString: "URL", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.url))),
                BlueprintAttribute(LookinAttr_NSCell_NSPathCell_AllowedTypes, AttributeInfo(className: "NSPathCell", fullTitle: "AllowedTypes", getterString: "allowedTypes", setterString: "", revision: 1, presentation: .count)),
                BlueprintAttribute(LookinAttr_NSCell_NSPathCell_PathComponentCells, AttributeInfo(className: "NSPathCell", fullTitle: "PathComponentCells", getterString: "pathComponentCells", setterString: "", revision: 1, presentation: .count)),
                BlueprintAttribute(LookinAttr_NSCell_NSPathCell_BackgroundColor, AttributeInfo(className: "NSPathCell", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "", typeIfObj: .uiColor, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSPathCell_PlaceholderString, AttributeInfo(className: "NSPathCell", fullTitle: "PlaceholderString", getterString: "placeholderString", setterString: "", typeIfObj: .nsString, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSPathCell_PlaceholderAttributedString, AttributeInfo(className: "NSPathCell", fullTitle: "PlaceholderAttributedString", getterString: "placeholderAttributedString", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.attributedString))),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NSSegmentedCell, title: "NSSegmentedCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NSSegmentedCell_SegmentCount, AttributeInfo(className: "NSSegmentedCell", fullTitle: "SegmentCount", getterString: "segmentCount", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSSegmentedCell_SelectedSegment, AttributeInfo(className: "NSSegmentedCell", fullTitle: "SelectedSegment", getterString: "selectedSegment", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSSegmentedCell_TrackingMode, AttributeInfo(className: "NSSegmentedCell", fullTitle: "TrackingMode", getterString: "trackingMode", setterString: "", enumList: "NSSegmentSwitchTracking", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSSegmentedCell_SegmentStyle, AttributeInfo(className: "NSSegmentedCell", fullTitle: "SegmentStyle", getterString: "segmentStyle", setterString: "", enumList: "NSSegmentStyle", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NSSliderCell, title: "NSSliderCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NSSliderCell_MinValue, AttributeInfo(className: "NSSliderCell", fullTitle: "MinValue", getterString: "minValue", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSSliderCell_MaxValue, AttributeInfo(className: "NSSliderCell", fullTitle: "MaxValue", getterString: "maxValue", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSSliderCell_AltIncrementValue, AttributeInfo(className: "NSSliderCell", fullTitle: "AltIncrementValue", getterString: "altIncrementValue", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSSliderCell_SliderType, AttributeInfo(className: "NSSliderCell", fullTitle: "SliderType", getterString: "sliderType", setterString: "", enumList: "NSSliderType", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSSliderCell_Vertical, AttributeInfo(className: "NSSliderCell", fullTitle: "Vertical", getterString: "isVertical", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSSliderCell_TrackRect, AttributeInfo(className: "NSSliderCell", fullTitle: "TrackRect", getterString: "trackRect", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSSliderCell_KnobThickness, AttributeInfo(className: "NSSliderCell", fullTitle: "KnobThickness", getterString: "knobThickness", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSSliderCell_NumberOfTickMarks, AttributeInfo(className: "NSSliderCell", fullTitle: "NumberOfTickMarks", getterString: "numberOfTickMarks", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSSliderCell_TickMarkPosition, AttributeInfo(className: "NSSliderCell", fullTitle: "TickMarkPosition", getterString: "tickMarkPosition", setterString: "", enumList: "NSTickMarkPosition", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSSliderCell_AllowsTickMarkValuesOnly, AttributeInfo(className: "NSSliderCell", fullTitle: "AllowsTickMarkValuesOnly", getterString: "allowsTickMarkValuesOnly", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NSStepperCell, title: "NSStepperCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NSStepperCell_MinValue, AttributeInfo(className: "NSStepperCell", fullTitle: "MinValue", getterString: "minValue", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSStepperCell_MaxValue, AttributeInfo(className: "NSStepperCell", fullTitle: "MaxValue", getterString: "maxValue", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSStepperCell_Increment, AttributeInfo(className: "NSStepperCell", fullTitle: "Increment", getterString: "increment", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSStepperCell_ValueWraps, AttributeInfo(className: "NSStepperCell", fullTitle: "ValueWraps", getterString: "valueWraps", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSStepperCell_Autorepeat, AttributeInfo(className: "NSStepperCell", fullTitle: "Autorepeat", getterString: "autorepeat", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NSComboBoxCell, title: "NSComboBoxCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NSComboBoxCell_HasVerticalScroller, AttributeInfo(className: "NSComboBoxCell", fullTitle: "HasVerticalScroller", getterString: "hasVerticalScroller", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSComboBoxCell_IntercellSpacing, AttributeInfo(className: "NSComboBoxCell", fullTitle: "IntercellSpacing", getterString: "intercellSpacing", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSComboBoxCell_ItemHeight, AttributeInfo(className: "NSComboBoxCell", fullTitle: "ItemHeight", getterString: "itemHeight", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSComboBoxCell_NumberOfVisibleItems, AttributeInfo(className: "NSComboBoxCell", fullTitle: "NumberOfVisibleItems", getterString: "numberOfVisibleItems", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSComboBoxCell_ButtonBordered, AttributeInfo(className: "NSComboBoxCell", fullTitle: "ButtonBordered", getterString: "isButtonBordered", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSComboBoxCell_UsesDataSource, AttributeInfo(className: "NSComboBoxCell", fullTitle: "UsesDataSource", getterString: "usesDataSource", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSComboBoxCell_IndexOfSelectedItem, AttributeInfo(className: "NSComboBoxCell", fullTitle: "IndexOfSelectedItem", getterString: "indexOfSelectedItem", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSComboBoxCell_NumberOfItems, AttributeInfo(className: "NSComboBoxCell", fullTitle: "NumberOfItems", getterString: "numberOfItems", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSComboBoxCell_Completes, AttributeInfo(className: "NSComboBoxCell", fullTitle: "Completes", getterString: "completes", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSComboBoxCell_ObjectValues, AttributeInfo(className: "NSComboBoxCell", fullTitle: "ObjectValues", getterString: "objectValues", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NSPathComponentCell, title: "NSPathComponentCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NSPathComponentCell_Image, AttributeInfo(className: "NSPathComponentCell", fullTitle: "Image", getterString: "image", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_NSCell_NSPathComponentCell_URL, AttributeInfo(className: "NSPathComponentCell", fullTitle: "URL", getterString: "URL", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.url))),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NSSearchFieldCell, title: "NSSearchFieldCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NSSearchFieldCell_SearchMenuTemplate, AttributeInfo(className: "NSSearchFieldCell", fullTitle: "SearchMenuTemplate", getterString: "searchMenuTemplate", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.menu))),
                BlueprintAttribute(LookinAttr_NSCell_NSSearchFieldCell_SendsWholeSearchString, AttributeInfo(className: "NSSearchFieldCell", fullTitle: "SendsWholeSearchString", getterString: "sendsWholeSearchString", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSSearchFieldCell_MaximumRecents, AttributeInfo(className: "NSSearchFieldCell", fullTitle: "MaximumRecents", getterString: "maximumRecents", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSSearchFieldCell_RecentSearches, AttributeInfo(className: "NSSearchFieldCell", fullTitle: "RecentSearches", getterString: "recentSearches", setterString: "", revision: 1, presentation: .count)),
                BlueprintAttribute(LookinAttr_NSCell_NSSearchFieldCell_SendsSearchStringImmediately, AttributeInfo(className: "NSSearchFieldCell", fullTitle: "SendsSearchStringImmediately", getterString: "sendsSearchStringImmediately", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NSSecureTextFieldCell, title: "NSSecureTextFieldCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NSSecureTextFieldCell_EchosBullets, AttributeInfo(className: "NSSecureTextFieldCell", fullTitle: "EchosBullets", getterString: "echosBullets", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NSTokenFieldCell, title: "NSTokenFieldCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NSTokenFieldCell_TokenStyle, AttributeInfo(className: "NSTokenFieldCell", fullTitle: "TokenStyle", getterString: "tokenStyle", setterString: "", enumList: "NSTokenStyle", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSTokenFieldCell_CompletionDelay, AttributeInfo(className: "NSTokenFieldCell", fullTitle: "CompletionDelay", getterString: "completionDelay", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NSBrowserCell, title: "NSBrowserCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NSBrowserCell_Leaf, AttributeInfo(className: "NSBrowserCell", fullTitle: "Leaf", getterString: "isLeaf", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSBrowserCell_Loaded, AttributeInfo(className: "NSBrowserCell", fullTitle: "Loaded", getterString: "isLoaded", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSBrowserCell_Image, AttributeInfo(className: "NSBrowserCell", fullTitle: "Image", getterString: "image", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_NSCell_NSBrowserCell_AlternateImage, AttributeInfo(className: "NSBrowserCell", fullTitle: "AlternateImage", getterString: "alternateImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(LookinAttrSec_NSCell_NSImageCell, title: "NSImageCell", on: .all, attributes: [
                BlueprintAttribute(LookinAttr_NSCell_NSImageCell_ImageAlignment, AttributeInfo(className: "NSImageCell", fullTitle: "ImageAlignment", getterString: "imageAlignment", setterString: "", enumList: "NSImageAlignment", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSImageCell_ImageScaling, AttributeInfo(className: "NSImageCell", fullTitle: "ImageScaling", getterString: "imageScaling", setterString: "", enumList: "NSImageScaling", revision: 1)),
                BlueprintAttribute(LookinAttr_NSCell_NSImageCell_ImageFrameStyle, AttributeInfo(className: "NSImageCell", fullTitle: "ImageFrameStyle", getterString: "imageFrameStyle", setterString: "", enumList: "NSImageFrameStyle", revision: 1)),
            ]),
        ])

        static let nsClipViewGroup = BlueprintGroup(LookinAttrGroup_NSClipView, title: "NSClipView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSClipView_BackgroundColor, title: "BackgroundColor", attributes: [
                BlueprintAttribute(LookinAttr_NSClipView_BackgroundColor_BackgroundColor, AttributeInfo(className: "NSClipView", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSClipView_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_NSClipView_Behavior_DrawsBackground, AttributeInfo(className: "NSClipView", fullTitle: "DrawsBackground", getterString: "drawsBackground", setterString: "setDrawsBackground:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSClipView_Behavior_AutomaticallyAdjustsContentInsets, AttributeInfo(className: "NSClipView", fullTitle: "AutomaticallyAdjustsContentInsets", getterString: "automaticallyAdjustsContentInsets", setterString: "setAutomaticallyAdjustsContentInsets:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSClipView_DocumentRect, title: "DocumentRect", attributes: [
                BlueprintAttribute(LookinAttr_NSClipView_DocumentRect_DocumentRect, AttributeInfo(className: "NSClipView", fullTitle: "DocumentRect", getterString: "documentRect", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSClipView_DocumentVisibleRect, title: "DocumentVisibleRect", attributes: [
                BlueprintAttribute(LookinAttr_NSClipView_DocumentVisibleRect_DocumentVisibleRect, AttributeInfo(className: "NSClipView", fullTitle: "DocumentVisibleRect", getterString: "documentVisibleRect", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSClipView_ContentInsets, title: "ContentInsets", attributes: [
                BlueprintAttribute(LookinAttr_NSClipView_ContentInsets_ContentInsets, AttributeInfo(className: "NSClipView", fullTitle: "ContentInsets", getterString: "contentInsets", setterString: "setContentInsets:", patch: true, revision: 1)),
            ]),
        ])


        static let nsScrollerGroup = BlueprintGroup(LookinAttrGroup_NSScroller, title: "NSScroller", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSScroller_ScrollerStyle, title: "ScrollerStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSScroller_ScrollerStyle_ScrollerStyle, AttributeInfo(className: "NSScroller", fullTitle: "ScrollerStyle", getterString: "scrollerStyle", setterString: "setScrollerStyle:", enumList: "NSScrollerStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSScroller_KnobStyle, title: "KnobStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSScroller_KnobStyle_KnobStyle, AttributeInfo(className: "NSScroller", fullTitle: "KnobStyle", getterString: "knobStyle", setterString: "setKnobStyle:", enumList: "NSScrollerKnobStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSScroller_UsableParts, title: "UsableParts", attributes: [
                BlueprintAttribute(LookinAttr_NSScroller_UsableParts_UsableParts, AttributeInfo(className: "NSScroller", fullTitle: "UsableParts", getterString: "usableParts", setterString: "", enumList: "NSUsableScrollerParts", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSScroller_ControlSize, title: "ControlSize", attributes: [
                BlueprintAttribute(LookinAttr_NSScroller_ControlSize_ControlSize, AttributeInfo(className: "NSScroller", fullTitle: "ControlSize", getterString: "controlSize", setterString: "setControlSize:", enumList: "NSControlSize", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSScroller_HitPart, title: "HitPart", attributes: [
                BlueprintAttribute(LookinAttr_NSScroller_HitPart_HitPart, AttributeInfo(className: "NSScroller", fullTitle: "HitPart", getterString: "hitPart", setterString: "", enumList: "NSScrollerPart", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSScroller_KnobProportion, title: "KnobProportion", attributes: [
                BlueprintAttribute(LookinAttr_NSScroller_KnobProportion_KnobProportion, AttributeInfo(className: "NSScroller", fullTitle: "KnobProportion", getterString: "knobProportion", setterString: "setKnobProportion:", patch: true, revision: 1)),
            ]),
        ])


        static let nsBrowserGroup = BlueprintGroup(LookinAttrGroup_NSBrowser, title: "NSBrowser", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSBrowser_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_NSBrowser_Behavior_Loaded, AttributeInfo(className: "NSBrowser", fullTitle: "Loaded", getterString: "isLoaded", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSBrowser_Behavior_ReusesColumns, AttributeInfo(className: "NSBrowser", fullTitle: "ReusesColumns", getterString: "reusesColumns", setterString: "setReusesColumns:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSBrowser_Behavior_HasHorizontalScroller, AttributeInfo(className: "NSBrowser", fullTitle: "HasHorizontalScroller", getterString: "hasHorizontalScroller", setterString: "setHasHorizontalScroller:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSBrowser_Behavior_AutohidesScroller, AttributeInfo(className: "NSBrowser", fullTitle: "AutohidesScroller", getterString: "autohidesScroller", setterString: "setAutohidesScroller:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSBrowser_Behavior_SeparatesColumns, AttributeInfo(className: "NSBrowser", fullTitle: "SeparatesColumns", getterString: "separatesColumns", setterString: "setSeparatesColumns:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSBrowser_Behavior_Titled, AttributeInfo(className: "NSBrowser", fullTitle: "Titled", getterString: "isTitled", setterString: "setTitled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSBrowser_Behavior_AllowsMultipleSelection, AttributeInfo(className: "NSBrowser", fullTitle: "AllowsMultipleSelection", getterString: "allowsMultipleSelection", setterString: "setAllowsMultipleSelection:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSBrowser_Behavior_AllowsBranchSelection, AttributeInfo(className: "NSBrowser", fullTitle: "AllowsBranchSelection", getterString: "allowsBranchSelection", setterString: "setAllowsBranchSelection:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSBrowser_Behavior_AllowsEmptySelection, AttributeInfo(className: "NSBrowser", fullTitle: "AllowsEmptySelection", getterString: "allowsEmptySelection", setterString: "setAllowsEmptySelection:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSBrowser_Behavior_TakesTitleFromPreviousColumn, AttributeInfo(className: "NSBrowser", fullTitle: "TakesTitleFromPreviousColumn", getterString: "takesTitleFromPreviousColumn", setterString: "setTakesTitleFromPreviousColumn:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSBrowser_Behavior_SendsActionOnArrowKeys, AttributeInfo(className: "NSBrowser", fullTitle: "SendsActionOnArrowKeys", getterString: "sendsActionOnArrowKeys", setterString: "setSendsActionOnArrowKeys:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSBrowser_Behavior_PrefersAllColumnUserResizing, AttributeInfo(className: "NSBrowser", fullTitle: "PrefersAllColumnUserResizing", getterString: "prefersAllColumnUserResizing", setterString: "setPrefersAllColumnUserResizing:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSBrowser_Behavior_AllowsTypeSelect, AttributeInfo(className: "NSBrowser", fullTitle: "AllowsTypeSelect", getterString: "allowsTypeSelect", setterString: "setAllowsTypeSelect:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSBrowser_MinColumnWidth, title: "MinColumnWidth", attributes: [
                BlueprintAttribute(LookinAttr_NSBrowser_MinColumnWidth_MinColumnWidth, AttributeInfo(className: "NSBrowser", fullTitle: "MinColumnWidth", getterString: "minColumnWidth", setterString: "setMinColumnWidth:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSBrowser_MaxVisibleColumns, title: "MaxVisibleColumns", attributes: [
                BlueprintAttribute(LookinAttr_NSBrowser_MaxVisibleColumns_MaxVisibleColumns, AttributeInfo(className: "NSBrowser", fullTitle: "MaxVisibleColumns", getterString: "maxVisibleColumns", setterString: "setMaxVisibleColumns:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSBrowser_PathSeparator, title: "PathSeparator", attributes: [
                BlueprintAttribute(LookinAttr_NSBrowser_PathSeparator_PathSeparator, AttributeInfo(className: "NSBrowser", fullTitle: "PathSeparator", getterString: "pathSeparator", setterString: "setPathSeparator:", typeIfObj: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSBrowser_ClickedColumn, title: "ClickedColumn", attributes: [
                BlueprintAttribute(LookinAttr_NSBrowser_ClickedColumn_ClickedColumn, AttributeInfo(className: "NSBrowser", fullTitle: "ClickedColumn", getterString: "clickedColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSBrowser_ClickedRow, title: "ClickedRow", attributes: [
                BlueprintAttribute(LookinAttr_NSBrowser_ClickedRow_ClickedRow, AttributeInfo(className: "NSBrowser", fullTitle: "ClickedRow", getterString: "clickedRow", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSBrowser_SelectedColumn, title: "SelectedColumn", attributes: [
                BlueprintAttribute(LookinAttr_NSBrowser_SelectedColumn_SelectedColumn, AttributeInfo(className: "NSBrowser", fullTitle: "SelectedColumn", getterString: "selectedColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSBrowser_LastColumn, title: "LastColumn", attributes: [
                BlueprintAttribute(LookinAttr_NSBrowser_LastColumn_LastColumn, AttributeInfo(className: "NSBrowser", fullTitle: "LastColumn", getterString: "lastColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSBrowser_NumberOfVisibleColumns, title: "NumberOfVisibleColumns", attributes: [
                BlueprintAttribute(LookinAttr_NSBrowser_NumberOfVisibleColumns_NumberOfVisibleColumns, AttributeInfo(className: "NSBrowser", fullTitle: "NumberOfVisibleColumns", getterString: "numberOfVisibleColumns", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSBrowser_FirstVisibleColumn, title: "FirstVisibleColumn", attributes: [
                BlueprintAttribute(LookinAttr_NSBrowser_FirstVisibleColumn_FirstVisibleColumn, AttributeInfo(className: "NSBrowser", fullTitle: "FirstVisibleColumn", getterString: "firstVisibleColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSBrowser_LastVisibleColumn, title: "LastVisibleColumn", attributes: [
                BlueprintAttribute(LookinAttr_NSBrowser_LastVisibleColumn_LastVisibleColumn, AttributeInfo(className: "NSBrowser", fullTitle: "LastVisibleColumn", getterString: "lastVisibleColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSBrowser_TitleHeight, title: "TitleHeight", attributes: [
                BlueprintAttribute(LookinAttr_NSBrowser_TitleHeight_TitleHeight, AttributeInfo(className: "NSBrowser", fullTitle: "TitleHeight", getterString: "titleHeight", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSBrowser_ColumnResizingType, title: "ColumnResizingType", attributes: [
                BlueprintAttribute(LookinAttr_NSBrowser_ColumnResizingType_ColumnResizingType, AttributeInfo(className: "NSBrowser", fullTitle: "ColumnResizingType", getterString: "columnResizingType", setterString: "setColumnResizingType:", enumList: "NSBrowserColumnResizingType", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSBrowser_BackgroundColor, title: "BackgroundColor", attributes: [
                BlueprintAttribute(LookinAttr_NSBrowser_BackgroundColor_BackgroundColor, AttributeInfo(className: "NSBrowser", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
        ])


        static let nsMatrixGroup = BlueprintGroup(LookinAttrGroup_NSMatrix, title: "NSMatrix", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSMatrix_Mode, title: "Mode", attributes: [
                BlueprintAttribute(LookinAttr_NSMatrix_Mode_Mode, AttributeInfo(className: "NSMatrix", fullTitle: "Mode", getterString: "mode", setterString: "setMode:", enumList: "NSMatrixMode", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSMatrix_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_NSMatrix_Behavior_AllowsEmptySelection, AttributeInfo(className: "NSMatrix", fullTitle: "AllowsEmptySelection", getterString: "allowsEmptySelection", setterString: "setAllowsEmptySelection:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSMatrix_Behavior_SelectionByRect, AttributeInfo(className: "NSMatrix", fullTitle: "SelectionByRect", getterString: "isSelectionByRect", setterString: "setSelectionByRect:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSMatrix_Behavior_DrawsCellBackground, AttributeInfo(className: "NSMatrix", fullTitle: "DrawsCellBackground", getterString: "drawsCellBackground", setterString: "setDrawsCellBackground:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSMatrix_Behavior_DrawsBackground, AttributeInfo(className: "NSMatrix", fullTitle: "DrawsBackground", getterString: "drawsBackground", setterString: "setDrawsBackground:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSMatrix_Behavior_AutosizesCells, AttributeInfo(className: "NSMatrix", fullTitle: "AutosizesCells", getterString: "autosizesCells", setterString: "setAutosizesCells:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSMatrix_Behavior_Autoscroll, AttributeInfo(className: "NSMatrix", fullTitle: "Autoscroll", getterString: "isAutoscroll", setterString: "setAutoscroll:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSMatrix_Behavior_AutorecalculatesCellSize, AttributeInfo(className: "NSMatrix", fullTitle: "AutorecalculatesCellSize", getterString: "autorecalculatesCellSize", setterString: "setAutorecalculatesCellSize:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSMatrix_Behavior_TabKeyTraversesCells, AttributeInfo(className: "NSMatrix", fullTitle: "TabKeyTraversesCells", getterString: "tabKeyTraversesCells", setterString: "setTabKeyTraversesCells:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSMatrix_SelectedRow, title: "SelectedRow", attributes: [
                BlueprintAttribute(LookinAttr_NSMatrix_SelectedRow_SelectedRow, AttributeInfo(className: "NSMatrix", fullTitle: "SelectedRow", getterString: "selectedRow", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSMatrix_SelectedColumn, title: "SelectedColumn", attributes: [
                BlueprintAttribute(LookinAttr_NSMatrix_SelectedColumn_SelectedColumn, AttributeInfo(className: "NSMatrix", fullTitle: "SelectedColumn", getterString: "selectedColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSMatrix_CellSize, title: "CellSize", attributes: [
                BlueprintAttribute(LookinAttr_NSMatrix_CellSize_CellSize, AttributeInfo(className: "NSMatrix", fullTitle: "CellSize", getterString: "cellSize", setterString: "setCellSize:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSMatrix_IntercellSpacing, title: "IntercellSpacing", attributes: [
                BlueprintAttribute(LookinAttr_NSMatrix_IntercellSpacing_IntercellSpacing, AttributeInfo(className: "NSMatrix", fullTitle: "IntercellSpacing", getterString: "intercellSpacing", setterString: "setIntercellSpacing:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSMatrix_Colors, title: "Colors", attributes: [
                BlueprintAttribute(LookinAttr_NSMatrix_Colors_BackgroundColor, AttributeInfo(className: "NSMatrix", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSMatrix_Colors_CellBackgroundColor, AttributeInfo(className: "NSMatrix", fullTitle: "CellBackgroundColor", getterString: "cellBackgroundColor", setterString: "setCellBackgroundColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSMatrix_NumberOfRows, title: "NumberOfRows", attributes: [
                BlueprintAttribute(LookinAttr_NSMatrix_NumberOfRows_NumberOfRows, AttributeInfo(className: "NSMatrix", fullTitle: "NumberOfRows", getterString: "numberOfRows", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSMatrix_NumberOfColumns, title: "NumberOfColumns", attributes: [
                BlueprintAttribute(LookinAttr_NSMatrix_NumberOfColumns_NumberOfColumns, AttributeInfo(className: "NSMatrix", fullTitle: "NumberOfColumns", getterString: "numberOfColumns", setterString: "", revision: 1)),
            ]),
        ])


        static let nsPathControlGroup = BlueprintGroup(LookinAttrGroup_NSPathControl, title: "NSPathControl", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSPathControl_Editable, title: "Editable", attributes: [
                BlueprintAttribute(LookinAttr_NSPathControl_Editable_Editable, AttributeInfo(className: "NSPathControl", fullTitle: "Editable", getterString: "isEditable", setterString: "setEditable:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSPathControl_PlaceholderString, title: "PlaceholderString", attributes: [
                BlueprintAttribute(LookinAttr_NSPathControl_PlaceholderString_PlaceholderString, AttributeInfo(className: "NSPathControl", fullTitle: "PlaceholderString", getterString: "placeholderString", setterString: "setPlaceholderString:", typeIfObj: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSPathControl_URL, title: "URL", attributes: [
                BlueprintAttribute(LookinAttr_NSPathControl_URL_URL, AttributeInfo(className: "NSPathControl", fullTitle: "URL", getterString: "URL", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.url))),
            ]),
            BlueprintSection(LookinAttrSec_NSPathControl_PathStyle, title: "PathStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSPathControl_PathStyle_PathStyle, AttributeInfo(className: "NSPathControl", fullTitle: "PathStyle", getterString: "pathStyle", setterString: "setPathStyle:", enumList: "NSPathStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSPathControl_BackgroundColor, title: "BackgroundColor", attributes: [
                BlueprintAttribute(LookinAttr_NSPathControl_BackgroundColor_BackgroundColor, AttributeInfo(className: "NSPathControl", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSPathControl_Menu, title: "Menu", attributes: [
                BlueprintAttribute(LookinAttr_NSPathControl_Menu_Menu, AttributeInfo(className: "NSPathControl", fullTitle: "Menu", getterString: "menu", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.menu))),
            ]),
        ])


        static let nsRuleEditorGroup = BlueprintGroup(LookinAttrGroup_NSRuleEditor, title: "NSRuleEditor", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSRuleEditor_NestingMode, title: "NestingMode", attributes: [
                BlueprintAttribute(LookinAttr_NSRuleEditor_NestingMode_NestingMode, AttributeInfo(className: "NSRuleEditor", fullTitle: "NestingMode", getterString: "nestingMode", setterString: "setNestingMode:", enumList: "NSRuleEditorNestingMode", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSRuleEditor_RowHeight, title: "RowHeight", attributes: [
                BlueprintAttribute(LookinAttr_NSRuleEditor_RowHeight_RowHeight, AttributeInfo(className: "NSRuleEditor", fullTitle: "RowHeight", getterString: "rowHeight", setterString: "setRowHeight:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSRuleEditor_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_NSRuleEditor_Behavior_Editable, AttributeInfo(className: "NSRuleEditor", fullTitle: "Editable", getterString: "isEditable", setterString: "setEditable:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSRuleEditor_Behavior_CanRemoveAllRows, AttributeInfo(className: "NSRuleEditor", fullTitle: "CanRemoveAllRows", getterString: "canRemoveAllRows", setterString: "setCanRemoveAllRows:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSRuleEditor_NumberOfRows, title: "NumberOfRows", attributes: [
                BlueprintAttribute(LookinAttr_NSRuleEditor_NumberOfRows_NumberOfRows, AttributeInfo(className: "NSRuleEditor", fullTitle: "NumberOfRows", getterString: "numberOfRows", setterString: "", revision: 1)),
            ]),
        ])


        static let nsSearchFieldGroup = BlueprintGroup(LookinAttrGroup_NSSearchField, title: "NSSearchField", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSSearchField_SearchTextBounds, title: "SearchTextBounds", attributes: [
                BlueprintAttribute(LookinAttr_NSSearchField_SearchTextBounds_SearchTextBounds, AttributeInfo(className: "NSSearchField", fullTitle: "SearchTextBounds", getterString: "searchTextBounds", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSSearchField_SearchButtonBounds, title: "SearchButtonBounds", attributes: [
                BlueprintAttribute(LookinAttr_NSSearchField_SearchButtonBounds_SearchButtonBounds, AttributeInfo(className: "NSSearchField", fullTitle: "SearchButtonBounds", getterString: "searchButtonBounds", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSSearchField_CancelButtonBounds, title: "CancelButtonBounds", attributes: [
                BlueprintAttribute(LookinAttr_NSSearchField_CancelButtonBounds_CancelButtonBounds, AttributeInfo(className: "NSSearchField", fullTitle: "CancelButtonBounds", getterString: "cancelButtonBounds", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSSearchField_SearchMenuTemplate, title: "SearchMenuTemplate", attributes: [
                BlueprintAttribute(LookinAttr_NSSearchField_SearchMenuTemplate_SearchMenuTemplate, AttributeInfo(className: "NSSearchField", fullTitle: "SearchMenuTemplate", getterString: "searchMenuTemplate", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.menu))),
            ]),
            BlueprintSection(LookinAttrSec_NSSearchField_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_NSSearchField_Behavior_SendsWholeSearchString, AttributeInfo(className: "NSSearchField", fullTitle: "SendsWholeSearchString", getterString: "sendsWholeSearchString", setterString: "setSendsWholeSearchString:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSSearchField_Behavior_SendsSearchStringImmediately, AttributeInfo(className: "NSSearchField", fullTitle: "SendsSearchStringImmediately", getterString: "sendsSearchStringImmediately", setterString: "setSendsSearchStringImmediately:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSSearchField_MaximumRecents, title: "MaximumRecents", attributes: [
                BlueprintAttribute(LookinAttr_NSSearchField_MaximumRecents_MaximumRecents, AttributeInfo(className: "NSSearchField", fullTitle: "MaximumRecents", getterString: "maximumRecents", setterString: "setMaximumRecents:", patch: true, revision: 1)),
            ]),
        ])


        static let nsComboButtonGroup = BlueprintGroup(LookinAttrGroup_NSComboButton, title: "NSComboButton", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSComboButton_Title, title: "Title", attributes: [
                BlueprintAttribute(LookinAttr_NSComboButton_Title_Title, AttributeInfo(className: "NSComboButton", fullTitle: "Title", getterString: "title", setterString: "setTitle:", typeIfObj: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSComboButton_Image, title: "Image", attributes: [
                BlueprintAttribute(LookinAttr_NSComboButton_Image_Image, AttributeInfo(className: "NSComboButton", fullTitle: "Image", getterString: "image", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(LookinAttrSec_NSComboButton_ImageScaling, title: "ImageScaling", attributes: [
                BlueprintAttribute(LookinAttr_NSComboButton_ImageScaling_ImageScaling, AttributeInfo(className: "NSComboButton", fullTitle: "ImageScaling", getterString: "imageScaling", setterString: "setImageScaling:", enumList: "NSImageScaling", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSComboButton_Menu, title: "Menu", attributes: [
                BlueprintAttribute(LookinAttr_NSComboButton_Menu_Menu, AttributeInfo(className: "NSComboButton", fullTitle: "Menu", getterString: "menu", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.menu))),
            ]),
            BlueprintSection(LookinAttrSec_NSComboButton_Style, title: "Style", attributes: [
                BlueprintAttribute(LookinAttr_NSComboButton_Style_Style, AttributeInfo(className: "NSComboButton", fullTitle: "Style", getterString: "style", setterString: "setStyle:", enumList: "NSComboButtonStyle", patch: true, revision: 1)),
            ]),
        ])


        static let nsGlassEffectViewGroup = BlueprintGroup(LookinAttrGroup_NSGlassEffectView, title: "NSGlassEffectView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSGlassEffectView_CornerRadius, title: "CornerRadius", attributes: [
                BlueprintAttribute(LookinAttr_NSGlassEffectView_CornerRadius_CornerRadius, AttributeInfo(className: "NSGlassEffectView", fullTitle: "CornerRadius", getterString: "cornerRadius", setterString: "setCornerRadius:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSGlassEffectView_TintColor, title: "TintColor", attributes: [
                BlueprintAttribute(LookinAttr_NSGlassEffectView_TintColor_TintColor, AttributeInfo(className: "NSGlassEffectView", fullTitle: "TintColor", getterString: "tintColor", setterString: "setTintColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSGlassEffectView_Style, title: "Style", attributes: [
                BlueprintAttribute(LookinAttr_NSGlassEffectView_Style_Style, AttributeInfo(className: "NSGlassEffectView", fullTitle: "Style", getterString: "style", setterString: "setStyle:", enumList: "NSGlassEffectViewStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSGlassEffectView_EffectIsInteractive, title: "EffectIsInteractive", attributes: [
                BlueprintAttribute(LookinAttr_NSGlassEffectView_EffectIsInteractive_EffectIsInteractive, AttributeInfo(className: "NSGlassEffectView", fullTitle: "EffectIsInteractive", getterString: "effectIsInteractive", setterString: "setEffectIsInteractive:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSGlassEffectView_NSGlassEffectContainerView, title: "NSGlassEffectContainerView", attributes: [
                BlueprintAttribute(LookinAttr_NSGlassEffectView_NSGlassEffectContainerView_Spacing, AttributeInfo(className: "NSGlassEffectContainerView", fullTitle: "Spacing", getterString: "spacing", setterString: "setSpacing:", patch: true, revision: 1)),
            ]),
        ])


        static let nsBackgroundExtensionViewGroup = BlueprintGroup(LookinAttrGroup_NSBackgroundExtensionView, title: "NSBackgroundExtensionView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSBackgroundExtensionView_AutomaticallyPlacesContentView, title: "AutomaticallyPlacesContentView", attributes: [
                BlueprintAttribute(LookinAttr_NSBackgroundExtensionView_AutomaticallyPlacesContentView_AutomaticallyPlacesContentView, AttributeInfo(className: "NSBackgroundExtensionView", fullTitle: "AutomaticallyPlacesContentView", getterString: "automaticallyPlacesContentView", setterString: "setAutomaticallyPlacesContentView:", patch: true, revision: 1)),
            ]),
        ])


        static let nsRulerViewGroup = BlueprintGroup(LookinAttrGroup_NSRulerView, title: "NSRulerView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSRulerView_Orientation, title: "Orientation", attributes: [
                BlueprintAttribute(LookinAttr_NSRulerView_Orientation_Orientation, AttributeInfo(className: "NSRulerView", fullTitle: "Orientation", getterString: "orientation", setterString: "setOrientation:", enumList: "NSRulerOrientation", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSRulerView_BaselineLocation, title: "BaselineLocation", attributes: [
                BlueprintAttribute(LookinAttr_NSRulerView_BaselineLocation_BaselineLocation, AttributeInfo(className: "NSRulerView", fullTitle: "BaselineLocation", getterString: "baselineLocation", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSRulerView_RequiredThickness, title: "RequiredThickness", attributes: [
                BlueprintAttribute(LookinAttr_NSRulerView_RequiredThickness_RequiredThickness, AttributeInfo(className: "NSRulerView", fullTitle: "RequiredThickness", getterString: "requiredThickness", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSRulerView_RuleThickness, title: "RuleThickness", attributes: [
                BlueprintAttribute(LookinAttr_NSRulerView_RuleThickness_RuleThickness, AttributeInfo(className: "NSRulerView", fullTitle: "RuleThickness", getterString: "ruleThickness", setterString: "setRuleThickness:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSRulerView_ReservedThicknessForMarkers, title: "ReservedThicknessForMarkers", attributes: [
                BlueprintAttribute(LookinAttr_NSRulerView_ReservedThicknessForMarkers_ReservedThicknessForMarkers, AttributeInfo(className: "NSRulerView", fullTitle: "ReservedThicknessForMarkers", getterString: "reservedThicknessForMarkers", setterString: "setReservedThicknessForMarkers:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSRulerView_ReservedThicknessForAccessoryView, title: "ReservedThicknessForAccessoryView", attributes: [
                BlueprintAttribute(LookinAttr_NSRulerView_ReservedThicknessForAccessoryView_ReservedThicknessForAccessoryView, AttributeInfo(className: "NSRulerView", fullTitle: "ReservedThicknessForAccessoryView", getterString: "reservedThicknessForAccessoryView", setterString: "setReservedThicknessForAccessoryView:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSRulerView_MeasurementUnits, title: "MeasurementUnits", attributes: [
                BlueprintAttribute(LookinAttr_NSRulerView_MeasurementUnits_MeasurementUnits, AttributeInfo(className: "NSRulerView", fullTitle: "MeasurementUnits", getterString: "measurementUnits", setterString: "", typeIfObj: .nsString, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSRulerView_OriginOffset, title: "OriginOffset", attributes: [
                BlueprintAttribute(LookinAttr_NSRulerView_OriginOffset_OriginOffset, AttributeInfo(className: "NSRulerView", fullTitle: "OriginOffset", getterString: "originOffset", setterString: "setOriginOffset:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSRulerView_Flipped, title: "Flipped", attributes: [
                BlueprintAttribute(LookinAttr_NSRulerView_Flipped_Flipped, AttributeInfo(className: "NSRulerView", fullTitle: "Flipped", getterString: "isFlipped", setterString: "", revision: 1)),
            ]),
        ])


        static let nsTableCellViewGroup = BlueprintGroup(LookinAttrGroup_NSTableCellView, title: "NSTableCellView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSTableCellView_BackgroundStyle, title: "BackgroundStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSTableCellView_BackgroundStyle_BackgroundStyle, AttributeInfo(className: "NSTableCellView", fullTitle: "BackgroundStyle", getterString: "backgroundStyle", setterString: "setBackgroundStyle:", enumList: "NSBackgroundStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableCellView_RowSizeStyle, title: "RowSizeStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSTableCellView_RowSizeStyle_RowSizeStyle, AttributeInfo(className: "NSTableCellView", fullTitle: "RowSizeStyle", getterString: "rowSizeStyle", setterString: "setRowSizeStyle:", enumList: "NSTableViewRowSizeStyle", patch: true, revision: 1)),
            ]),
        ])


        static let nsTableRowViewGroup = BlueprintGroup(LookinAttrGroup_NSTableRowView, title: "NSTableRowView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSTableRowView_SelectionHighlightStyle, title: "SelectionHighlightStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSTableRowView_SelectionHighlightStyle_SelectionHighlightStyle, AttributeInfo(className: "NSTableRowView", fullTitle: "SelectionHighlightStyle", getterString: "selectionHighlightStyle", setterString: "setSelectionHighlightStyle:", enumList: "NSTableViewSelectionHighlightStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableRowView_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_NSTableRowView_Behavior_Emphasized, AttributeInfo(className: "NSTableRowView", fullTitle: "Emphasized", getterString: "isEmphasized", setterString: "setEmphasized:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTableRowView_Behavior_GroupRowStyle, AttributeInfo(className: "NSTableRowView", fullTitle: "GroupRowStyle", getterString: "isGroupRowStyle", setterString: "setGroupRowStyle:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTableRowView_Behavior_Selected, AttributeInfo(className: "NSTableRowView", fullTitle: "Selected", getterString: "isSelected", setterString: "setSelected:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTableRowView_Behavior_PreviousRowSelected, AttributeInfo(className: "NSTableRowView", fullTitle: "PreviousRowSelected", getterString: "isPreviousRowSelected", setterString: "setPreviousRowSelected:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTableRowView_Behavior_NextRowSelected, AttributeInfo(className: "NSTableRowView", fullTitle: "NextRowSelected", getterString: "isNextRowSelected", setterString: "setNextRowSelected:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTableRowView_Behavior_Floating, AttributeInfo(className: "NSTableRowView", fullTitle: "Floating", getterString: "isFloating", setterString: "setFloating:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSTableRowView_Behavior_TargetForDropOperation, AttributeInfo(className: "NSTableRowView", fullTitle: "TargetForDropOperation", getterString: "isTargetForDropOperation", setterString: "setTargetForDropOperation:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableRowView_DraggingDestinationFeedbackStyle, title: "DraggingDestinationFeedbackStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSTableRowView_DraggingDestinationFeedbackStyle_DraggingDestinationFeedbackStyle, AttributeInfo(className: "NSTableRowView", fullTitle: "DraggingDestinationFeedbackStyle", getterString: "draggingDestinationFeedbackStyle", setterString: "setDraggingDestinationFeedbackStyle:", enumList: "NSTableViewDraggingDestinationFeedbackStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableRowView_IndentationForDropOperation, title: "IndentationForDropOperation", attributes: [
                BlueprintAttribute(LookinAttr_NSTableRowView_IndentationForDropOperation_IndentationForDropOperation, AttributeInfo(className: "NSTableRowView", fullTitle: "IndentationForDropOperation", getterString: "indentationForDropOperation", setterString: "setIndentationForDropOperation:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableRowView_InteriorBackgroundStyle, title: "InteriorBackgroundStyle", attributes: [
                BlueprintAttribute(LookinAttr_NSTableRowView_InteriorBackgroundStyle_InteriorBackgroundStyle, AttributeInfo(className: "NSTableRowView", fullTitle: "InteriorBackgroundStyle", getterString: "interiorBackgroundStyle", setterString: "", enumList: "NSBackgroundStyle", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableRowView_BackgroundColor, title: "BackgroundColor", attributes: [
                BlueprintAttribute(LookinAttr_NSTableRowView_BackgroundColor_BackgroundColor, AttributeInfo(className: "NSTableRowView", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableRowView_NumberOfColumns, title: "NumberOfColumns", attributes: [
                BlueprintAttribute(LookinAttr_NSTableRowView_NumberOfColumns_NumberOfColumns, AttributeInfo(className: "NSTableRowView", fullTitle: "NumberOfColumns", getterString: "numberOfColumns", setterString: "", revision: 1)),
            ]),
        ])


        static let nsTableHeaderViewGroup = BlueprintGroup(LookinAttrGroup_NSTableHeaderView, title: "NSTableHeaderView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSTableHeaderView_DraggedColumn, title: "DraggedColumn", attributes: [
                BlueprintAttribute(LookinAttr_NSTableHeaderView_DraggedColumn_DraggedColumn, AttributeInfo(className: "NSTableHeaderView", fullTitle: "DraggedColumn", getterString: "draggedColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableHeaderView_DraggedDistance, title: "DraggedDistance", attributes: [
                BlueprintAttribute(LookinAttr_NSTableHeaderView_DraggedDistance_DraggedDistance, AttributeInfo(className: "NSTableHeaderView", fullTitle: "DraggedDistance", getterString: "draggedDistance", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTableHeaderView_ResizedColumn, title: "ResizedColumn", attributes: [
                BlueprintAttribute(LookinAttr_NSTableHeaderView_ResizedColumn_ResizedColumn, AttributeInfo(className: "NSTableHeaderView", fullTitle: "ResizedColumn", getterString: "resizedColumn", setterString: "", revision: 1)),
            ]),
        ])


        static let nsTextInsertionIndicatorGroup = BlueprintGroup(LookinAttrGroup_NSTextInsertionIndicator, title: "NSTextInsertionIndicator", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSTextInsertionIndicator_DisplayMode, title: "DisplayMode", attributes: [
                BlueprintAttribute(LookinAttr_NSTextInsertionIndicator_DisplayMode_DisplayMode, AttributeInfo(className: "NSTextInsertionIndicator", fullTitle: "DisplayMode", getterString: "displayMode", setterString: "setDisplayMode:", enumList: "NSTextInsertionIndicatorDisplayMode", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextInsertionIndicator_Color, title: "Color", attributes: [
                BlueprintAttribute(LookinAttr_NSTextInsertionIndicator_Color_Color, AttributeInfo(className: "NSTextInsertionIndicator", fullTitle: "Color", getterString: "color", setterString: "setColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSTextInsertionIndicator_AutomaticModeOptions, title: "AutomaticModeOptions", attributes: [
                BlueprintAttribute(LookinAttr_NSTextInsertionIndicator_AutomaticModeOptions_AutomaticModeOptions, AttributeInfo(className: "NSTextInsertionIndicator", fullTitle: "AutomaticModeOptions", getterString: "automaticModeOptions", setterString: "", revision: 1, presentation: .optionNames("NSTextInsertionIndicatorAutomaticModeOptions"))),
            ]),
        ])

        static let nsViewGroup = BlueprintGroup(LookinAttrGroup_NSView, title: "NSView", on: .appKit, sections: [
            BlueprintSection(LookinAttrSec_NSView_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_NSView_Behavior_NeedsUpdateConstraints, AttributeInfo(className: "NSView", fullTitle: "NeedsUpdateConstraints", getterString: "needsUpdateConstraints", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_TranslatesAutoresizingMaskIntoConstraints, AttributeInfo(className: "NSView", fullTitle: "TranslatesAutoresizingMaskIntoConstraints", getterString: "translatesAutoresizingMaskIntoConstraints", setterString: "setTranslatesAutoresizingMaskIntoConstraints:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_HorizontalContentSizeConstraintActive, AttributeInfo(className: "NSView", fullTitle: "HorizontalContentSizeConstraintActive", getterString: "isHorizontalContentSizeConstraintActive", setterString: "setHorizontalContentSizeConstraintActive:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_VerticalContentSizeConstraintActive, AttributeInfo(className: "NSView", fullTitle: "VerticalContentSizeConstraintActive", getterString: "isVerticalContentSizeConstraintActive", setterString: "setVerticalContentSizeConstraintActive:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_HiddenOrHasHiddenAncestor, AttributeInfo(className: "NSView", fullTitle: "HiddenOrHasHiddenAncestor", getterString: "isHiddenOrHasHiddenAncestor", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_WantsDefaultClipping, AttributeInfo(className: "NSView", fullTitle: "WantsDefaultClipping", getterString: "wantsDefaultClipping", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_PostsFrameChangedNotifications, AttributeInfo(className: "NSView", fullTitle: "PostsFrameChangedNotifications", getterString: "postsFrameChangedNotifications", setterString: "setPostsFrameChangedNotifications:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_AutoresizesSubviews, AttributeInfo(className: "NSView", fullTitle: "AutoresizesSubviews", getterString: "autoresizesSubviews", setterString: "setAutoresizesSubviews:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_Flipped, AttributeInfo(className: "NSView", fullTitle: "Flipped", getterString: "isFlipped", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_RotatedFromBase, AttributeInfo(className: "NSView", fullTitle: "RotatedFromBase", getterString: "isRotatedFromBase", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_RotatedOrScaledFromBase, AttributeInfo(className: "NSView", fullTitle: "RotatedOrScaledFromBase", getterString: "isRotatedOrScaledFromBase", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_Opaque, AttributeInfo(className: "NSView", fullTitle: "Opaque", getterString: "isOpaque", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_CanDrawConcurrently, AttributeInfo(className: "NSView", fullTitle: "CanDrawConcurrently", getterString: "canDrawConcurrently", setterString: "setCanDrawConcurrently:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_NeedsDisplay, AttributeInfo(className: "NSView", fullTitle: "NeedsDisplay", getterString: "needsDisplay", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_NeedsPanelToBecomeKey, AttributeInfo(className: "NSView", fullTitle: "NeedsPanelToBecomeKey", getterString: "needsPanelToBecomeKey", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_MouseDownCanMoveWindow, AttributeInfo(className: "NSView", fullTitle: "MouseDownCanMoveWindow", getterString: "mouseDownCanMoveWindow", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_WantsRestingTouches, AttributeInfo(className: "NSView", fullTitle: "WantsRestingTouches", getterString: "wantsRestingTouches", setterString: "setWantsRestingTouches:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_WantsLayer, AttributeInfo(className: "NSView", fullTitle: "WantsLayer", getterString: "wantsLayer", setterString: "setWantsLayer:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_WantsUpdateLayer, AttributeInfo(className: "NSView", fullTitle: "WantsUpdateLayer", getterString: "wantsUpdateLayer", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_CanDrawSubviewsIntoLayer, AttributeInfo(className: "NSView", fullTitle: "CanDrawSubviewsIntoLayer", getterString: "canDrawSubviewsIntoLayer", setterString: "setCanDrawSubviewsIntoLayer:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_NeedsLayout, AttributeInfo(className: "NSView", fullTitle: "NeedsLayout", getterString: "needsLayout", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_LayerUsesCoreImageFilters, AttributeInfo(className: "NSView", fullTitle: "LayerUsesCoreImageFilters", getterString: "layerUsesCoreImageFilters", setterString: "setLayerUsesCoreImageFilters:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_ClipsToBounds, AttributeInfo(className: "NSView", fullTitle: "ClipsToBounds", getterString: "clipsToBounds", setterString: "setClipsToBounds:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_PostsBoundsChangedNotifications, AttributeInfo(className: "NSView", fullTitle: "PostsBoundsChangedNotifications", getterString: "postsBoundsChangedNotifications", setterString: "setPostsBoundsChangedNotifications:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_InLiveResize, AttributeInfo(className: "NSView", fullTitle: "InLiveResize", getterString: "inLiveResize", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_PreservesContentDuringLiveResize, AttributeInfo(className: "NSView", fullTitle: "PreservesContentDuringLiveResize", getterString: "preservesContentDuringLiveResize", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_AllowsVibrancy, AttributeInfo(className: "NSView", fullTitle: "AllowsVibrancy", getterString: "allowsVibrancy", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_CanBecomeKeyView, AttributeInfo(className: "NSView", fullTitle: "CanBecomeKeyView", getterString: "canBecomeKeyView", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_InFullScreenMode, AttributeInfo(className: "NSView", fullTitle: "InFullScreenMode", getterString: "isInFullScreenMode", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_NSView_Behavior_PrefersCompactControlSizeMetrics, AttributeInfo(className: "NSView", fullTitle: "PrefersCompactControlSizeMetrics", getterString: "prefersCompactControlSizeMetrics", setterString: "setPrefersCompactControlSizeMetrics:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSView_AlignmentRectInsets, title: "AlignmentRectInsets", attributes: [
                BlueprintAttribute(LookinAttr_NSView_AlignmentRectInsets_AlignmentRectInsets, AttributeInfo(className: "NSView", fullTitle: "AlignmentRectInsets", getterString: "alignmentRectInsets", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSView_AutoresizingMask, title: "AutoresizingMask", attributes: [
                BlueprintAttribute(LookinAttr_NSView_AutoresizingMask_AutoresizingMask, AttributeInfo(className: "NSView", fullTitle: "AutoresizingMask", getterString: "autoresizingMask", setterString: "", revision: 1, presentation: .optionNames("NSAutoresizingMaskOptions"))),
            ]),
            BlueprintSection(LookinAttrSec_NSView_FrameRotation, title: "FrameRotation", attributes: [
                BlueprintAttribute(LookinAttr_NSView_FrameRotation_FrameRotation, AttributeInfo(className: "NSView", fullTitle: "FrameRotation", getterString: "frameRotation", setterString: "setFrameRotation:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSView_FrameCenterRotation, title: "FrameCenterRotation", attributes: [
                BlueprintAttribute(LookinAttr_NSView_FrameCenterRotation_FrameCenterRotation, AttributeInfo(className: "NSView", fullTitle: "FrameCenterRotation", getterString: "frameCenterRotation", setterString: "setFrameCenterRotation:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSView_BoundsRotation, title: "BoundsRotation", attributes: [
                BlueprintAttribute(LookinAttr_NSView_BoundsRotation_BoundsRotation, AttributeInfo(className: "NSView", fullTitle: "BoundsRotation", getterString: "boundsRotation", setterString: "setBoundsRotation:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSView_VisibleRect, title: "VisibleRect", attributes: [
                BlueprintAttribute(LookinAttr_NSView_VisibleRect_VisibleRect, AttributeInfo(className: "NSView", fullTitle: "VisibleRect", getterString: "visibleRect", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSView_LayerContentsRedrawPolicy, title: "LayerContentsRedrawPolicy", attributes: [
                BlueprintAttribute(LookinAttr_NSView_LayerContentsRedrawPolicy_LayerContentsRedrawPolicy, AttributeInfo(className: "NSView", fullTitle: "LayerContentsRedrawPolicy", getterString: "layerContentsRedrawPolicy", setterString: "setLayerContentsRedrawPolicy:", enumList: "NSViewLayerContentsRedrawPolicy", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSView_LayerContentsPlacement, title: "LayerContentsPlacement", attributes: [
                BlueprintAttribute(LookinAttr_NSView_LayerContentsPlacement_LayerContentsPlacement, AttributeInfo(className: "NSView", fullTitle: "LayerContentsPlacement", getterString: "layerContentsPlacement", setterString: "setLayerContentsPlacement:", enumList: "NSViewLayerContentsPlacement", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSView_CompositingFilter, title: "CompositingFilter", attributes: [
                BlueprintAttribute(LookinAttr_NSView_CompositingFilter_CompositingFilter, AttributeInfo(className: "NSView", fullTitle: "CompositingFilter", getterString: "compositingFilter", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.className))),
            ]),
            BlueprintSection(LookinAttrSec_NSView_Shadow, title: "Shadow", attributes: [
                BlueprintAttribute(LookinAttr_NSView_Shadow_Shadow, AttributeInfo(className: "NSView", fullTitle: "Shadow", getterString: "shadow", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.shadow))),
            ]),
            BlueprintSection(LookinAttrSec_NSView_ToolTip, title: "ToolTip", attributes: [
                BlueprintAttribute(LookinAttr_NSView_ToolTip_ToolTip, AttributeInfo(className: "NSView", fullTitle: "ToolTip", getterString: "toolTip", setterString: "setToolTip:", typeIfObj: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSView_UserInterfaceLayoutDirection, title: "UserInterfaceLayoutDirection", attributes: [
                BlueprintAttribute(LookinAttr_NSView_UserInterfaceLayoutDirection_UserInterfaceLayoutDirection, AttributeInfo(className: "NSView", fullTitle: "UserInterfaceLayoutDirection", getterString: "userInterfaceLayoutDirection", setterString: "setUserInterfaceLayoutDirection:", enumList: "NSUserInterfaceLayoutDirection", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSView_PreparedContentRect, title: "PreparedContentRect", attributes: [
                BlueprintAttribute(LookinAttr_NSView_PreparedContentRect_PreparedContentRect, AttributeInfo(className: "NSView", fullTitle: "PreparedContentRect", getterString: "preparedContentRect", setterString: "setPreparedContentRect:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSView_FocusRingType, title: "FocusRingType", attributes: [
                BlueprintAttribute(LookinAttr_NSView_FocusRingType_FocusRingType, AttributeInfo(className: "NSView", fullTitle: "FocusRingType", getterString: "focusRingType", setterString: "setFocusRingType:", enumList: "NSFocusRingType", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSView_FocusRingMaskBounds, title: "FocusRingMaskBounds", attributes: [
                BlueprintAttribute(LookinAttr_NSView_FocusRingMaskBounds_FocusRingMaskBounds, AttributeInfo(className: "NSView", fullTitle: "FocusRingMaskBounds", getterString: "focusRingMaskBounds", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSView_ExclusiveGestureBehavior, title: "ExclusiveGestureBehavior", attributes: [
                BlueprintAttribute(LookinAttr_NSView_ExclusiveGestureBehavior_ExclusiveGestureBehavior, AttributeInfo(className: "NSView", fullTitle: "ExclusiveGestureBehavior", getterString: "exclusiveGestureBehavior", setterString: "setExclusiveGestureBehavior:", enumList: "NSViewExclusiveGestureBehavior", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSView_AllowedTouchTypes, title: "AllowedTouchTypes", attributes: [
                BlueprintAttribute(LookinAttr_NSView_AllowedTouchTypes_AllowedTouchTypes, AttributeInfo(className: "NSView", fullTitle: "AllowedTouchTypes", getterString: "allowedTouchTypes", setterString: "", revision: 1, presentation: .optionNames("NSTouchTypeMask"))),
            ]),
            BlueprintSection(LookinAttrSec_NSView_AdditionalSafeAreaInsets, title: "AdditionalSafeAreaInsets", attributes: [
                BlueprintAttribute(LookinAttr_NSView_AdditionalSafeAreaInsets_AdditionalSafeAreaInsets, AttributeInfo(className: "NSView", fullTitle: "AdditionalSafeAreaInsets", getterString: "additionalSafeAreaInsets", setterString: "setAdditionalSafeAreaInsets:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_NSView_SafeAreaRect, title: "SafeAreaRect", attributes: [
                BlueprintAttribute(LookinAttr_NSView_SafeAreaRect_SafeAreaRect, AttributeInfo(className: "NSView", fullTitle: "SafeAreaRect", getterString: "safeAreaRect", setterString: "", revision: 1)),
            ]),
        ])
    }

#endif
