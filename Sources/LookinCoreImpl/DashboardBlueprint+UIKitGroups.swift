//
//  DashboardBlueprint+UIKitGroups.swift
//  LookinCore
//
//  The groups only UIKit lists.
//  Each group lists its sections and each section its attributes, in display
//  order; DashboardBlueprintCatalog.swift explains the entry types and how the
//  lookup tables are derived. A section or attribute without `on:` is on the
//  platforms of the group or section it belongs to.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation

    extension DashboardBlueprintTables {
        static let uiStackViewGroup = BlueprintGroup(LookinAttrGroup_UIStackView, title: "UIStackView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIStackView_Axis, title: "Axis", attributes: [
                BlueprintAttribute(LookinAttr_UIStackView_Axis_Axis, AttributeInfo(className: "UIStackView", fullTitle: "Axis", enumList: "UILayoutConstraintAxis", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIStackView_Distribution, title: "Distribution", attributes: [
                BlueprintAttribute(LookinAttr_UIStackView_Distribution_Distribution, AttributeInfo(className: "UIStackView", fullTitle: "Distribution", enumList: "UIStackViewDistribution", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIStackView_Alignment, title: "Alignment", attributes: [
                BlueprintAttribute(LookinAttr_UIStackView_Alignment_Alignment, AttributeInfo(className: "UIStackView", fullTitle: "Alignment", enumList: "UIStackViewAlignment", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIStackView_Spacing, attributes: [
                BlueprintAttribute(LookinAttr_UIStackView_Spacing_Spacing, AttributeInfo(className: "UIStackView", fullTitle: "Spacing", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIStackView_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UIStackView_Behavior_BaselineRelativeArrangement, AttributeInfo(className: "UIStackView", fullTitle: "BaselineRelativeArrangement", getterString: "isBaselineRelativeArrangement", setterString: "setBaselineRelativeArrangement:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIStackView_Behavior_LayoutMarginsRelativeArrangement, AttributeInfo(className: "UIStackView", fullTitle: "LayoutMarginsRelativeArrangement", getterString: "isLayoutMarginsRelativeArrangement", setterString: "setLayoutMarginsRelativeArrangement:", patch: true, revision: 1)),
            ]),
        ])

        static let uiVisualEffectViewGroup = BlueprintGroup(LookinAttrGroup_UIVisualEffectView, title: "UIVisualEffectView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIVisualEffectView_Style, title: "Style", attributes: [
                BlueprintAttribute(LookinAttr_UIVisualEffectView_Style_Style, AttributeInfo(className: "UIVisualEffectView", getterString: "lks_blurEffectStyleNumber", setterString: "setLks_blurEffectStyleNumber:", typeIfObj: .customObj, enumList: "UIBlurEffectStyle", patch: true, hideIfNil: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIVisualEffectView_QMUIForegroundColor, title: "ForegroundColor", attributes: [
                BlueprintAttribute(LookinAttr_UIVisualEffectView_QMUIForegroundColor_Color, AttributeInfo(className: "QMUIVisualEffectView", fullTitle: "ForegroundColor", typeIfObj: .uiColor, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIVisualEffectView_Effect, title: "Effect", attributes: [
                BlueprintAttribute(LookinAttr_UIVisualEffectView_Effect_Effect, AttributeInfo(className: "UIVisualEffectView", fullTitle: "Effect", getterString: "effect", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.className))),
            ]),
        ])

        static let uiImageViewGroup = BlueprintGroup(LookinAttrGroup_UIImageView, title: "UIImageView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIImageView_Name, title: "ImageName", attributes: [
                BlueprintAttribute(LookinAttr_UIImageView_Name_Name, AttributeInfo(className: "UIImageView", fullTitle: "ImageName", getterString: "lks_imageSourceName", setterString: "", typeIfObj: .nsString, hideIfNil: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIImageView_Open, attributes: [
                BlueprintAttribute(LookinAttr_UIImageView_Open_Open, AttributeInfo(className: "UIImageView", getterString: "lks_imageViewOidIfHasImage", setterString: "", typeIfObj: .customObj, hideIfNil: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIImageView_HighlightedImage, title: "HighlightedImage", attributes: [
                BlueprintAttribute(LookinAttr_UIImageView_HighlightedImage_HighlightedImage, AttributeInfo(className: "UIImageView", fullTitle: "HighlightedImage", getterString: "highlightedImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(LookinAttrSec_UIImageView_PreferredSymbolConfiguration, title: "PreferredSymbolConfiguration", attributes: [
                BlueprintAttribute(LookinAttr_UIImageView_PreferredSymbolConfiguration_PreferredSymbolConfiguration, AttributeInfo(className: "UIImageView", fullTitle: "PreferredSymbolConfiguration", getterString: "preferredSymbolConfiguration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.description))),
            ]),
            BlueprintSection(LookinAttrSec_UIImageView_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UIImageView_Behavior_Highlighted, AttributeInfo(className: "UIImageView", fullTitle: "Highlighted", getterString: "isHighlighted", setterString: "setHighlighted:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIImageView_Behavior_Animating, AttributeInfo(className: "UIImageView", fullTitle: "Animating", getterString: "isAnimating", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIImageView_AnimationImages, title: "AnimationImages", attributes: [
                BlueprintAttribute(LookinAttr_UIImageView_AnimationImages_AnimationImages, AttributeInfo(className: "UIImageView", fullTitle: "AnimationImages", getterString: "animationImages", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(LookinAttrSec_UIImageView_HighlightedAnimationImages, title: "HighlightedAnimationImages", attributes: [
                BlueprintAttribute(LookinAttr_UIImageView_HighlightedAnimationImages_HighlightedAnimationImages, AttributeInfo(className: "UIImageView", fullTitle: "HighlightedAnimationImages", getterString: "highlightedAnimationImages", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(LookinAttrSec_UIImageView_AnimationDuration, title: "AnimationDuration", attributes: [
                BlueprintAttribute(LookinAttr_UIImageView_AnimationDuration_AnimationDuration, AttributeInfo(className: "UIImageView", fullTitle: "AnimationDuration", getterString: "animationDuration", setterString: "setAnimationDuration:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIImageView_AnimationRepeatCount, title: "AnimationRepeatCount", attributes: [
                BlueprintAttribute(LookinAttr_UIImageView_AnimationRepeatCount_AnimationRepeatCount, AttributeInfo(className: "UIImageView", fullTitle: "AnimationRepeatCount", getterString: "animationRepeatCount", setterString: "setAnimationRepeatCount:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIImageView_PreferredImageDynamicRange, title: "PreferredImageDynamicRange", attributes: [
                BlueprintAttribute(LookinAttr_UIImageView_PreferredImageDynamicRange_PreferredImageDynamicRange, AttributeInfo(className: "UIImageView", fullTitle: "PreferredImageDynamicRange", getterString: "preferredImageDynamicRange", setterString: "setPreferredImageDynamicRange:", enumList: "UIImageDynamicRange", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIImageView_ImageDynamicRange, title: "ImageDynamicRange", attributes: [
                BlueprintAttribute(LookinAttr_UIImageView_ImageDynamicRange_ImageDynamicRange, AttributeInfo(className: "UIImageView", fullTitle: "ImageDynamicRange", getterString: "imageDynamicRange", setterString: "", enumList: "UIImageDynamicRange", revision: 1)),
            ]),
        ])

        static let uiLabelGroup = BlueprintGroup(LookinAttrGroup_UILabel, title: "UILabel", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UILabel_Text, title: "Text", attributes: [
                BlueprintAttribute(LookinAttr_UILabel_Text_Text, AttributeInfo(className: "UILabel", fullTitle: "Text", typeIfObj: .nsString, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UILabel_Font, title: "Font", attributes: [
                BlueprintAttribute(LookinAttr_UILabel_Font_Name, AttributeInfo(className: "UILabel", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", typeIfObj: .nsString, patch: false)),
                BlueprintAttribute(LookinAttr_UILabel_Font_Size, AttributeInfo(className: "UILabel", fullTitle: "FontSize", briefTitle: "FontSize", getterString: "lks_fontSize", setterString: "setLks_fontSize:", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UILabel_NumberOfLines, title: "NumberOfLines", attributes: [
                BlueprintAttribute(LookinAttr_UILabel_NumberOfLines_NumberOfLines, AttributeInfo(className: "UILabel", fullTitle: "NumberOfLines", briefTitle: "", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UILabel_TextColor, title: "TextColor", attributes: [
                BlueprintAttribute(LookinAttr_UILabel_TextColor_Color, AttributeInfo(className: "UILabel", fullTitle: "TextColor", typeIfObj: .uiColor, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UILabel_BreakMode, title: "LineBreakMode", attributes: [
                BlueprintAttribute(LookinAttr_UILabel_BreakMode_Mode, AttributeInfo(className: "UILabel", fullTitle: "LineBreakMode", enumList: "NSLineBreakMode", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UILabel_Alignment, title: "TextAlignment", attributes: [
                BlueprintAttribute(LookinAttr_UILabel_Alignment_Alignment, AttributeInfo(className: "UILabel", fullTitle: "TextAlignment", enumList: "NSTextAlignment", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UILabel_CanAdjustFont, attributes: [
                BlueprintAttribute(LookinAttr_UILabel_CanAdjustFont_CanAdjustFont, AttributeInfo(className: "UILabel", fullTitle: "AdjustsFontSizeToFitWidth", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UILabel_PreferredVibrancy, title: "PreferredVibrancy", attributes: [
                BlueprintAttribute(LookinAttr_UILabel_PreferredVibrancy_PreferredVibrancy, AttributeInfo(className: "UILabel", fullTitle: "PreferredVibrancy", getterString: "preferredVibrancy", setterString: "setPreferredVibrancy:", enumList: "UILabelVibrancy", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UILabel_Colors, title: "Colors", attributes: [
                BlueprintAttribute(LookinAttr_UILabel_Colors_ShadowColor, AttributeInfo(className: "UILabel", fullTitle: "ShadowColor", getterString: "shadowColor", setterString: "setShadowColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UILabel_Colors_HighlightedTextColor, AttributeInfo(className: "UILabel", fullTitle: "HighlightedTextColor", getterString: "highlightedTextColor", setterString: "setHighlightedTextColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UILabel_ShadowOffset, title: "ShadowOffset", attributes: [
                BlueprintAttribute(LookinAttr_UILabel_ShadowOffset_ShadowOffset, AttributeInfo(className: "UILabel", fullTitle: "ShadowOffset", getterString: "shadowOffset", setterString: "setShadowOffset:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UILabel_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UILabel_Behavior_Highlighted, AttributeInfo(className: "UILabel", fullTitle: "Highlighted", getterString: "isHighlighted", setterString: "setHighlighted:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UILabel_Behavior_Enabled, AttributeInfo(className: "UILabel", fullTitle: "Enabled", getterString: "isEnabled", setterString: "setEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UILabel_Behavior_AllowsDefaultTighteningForTruncation, AttributeInfo(className: "UILabel", fullTitle: "AllowsDefaultTighteningForTruncation", getterString: "allowsDefaultTighteningForTruncation", setterString: "setAllowsDefaultTighteningForTruncation:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UILabel_Behavior_ShowsExpansionTextWhenTruncated, AttributeInfo(className: "UILabel", fullTitle: "ShowsExpansionTextWhenTruncated", getterString: "showsExpansionTextWhenTruncated", setterString: "setShowsExpansionTextWhenTruncated:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UILabel_BaselineAdjustment, title: "BaselineAdjustment", attributes: [
                BlueprintAttribute(LookinAttr_UILabel_BaselineAdjustment_BaselineAdjustment, AttributeInfo(className: "UILabel", fullTitle: "BaselineAdjustment", getterString: "baselineAdjustment", setterString: "setBaselineAdjustment:", enumList: "UIBaselineAdjustment", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UILabel_MinimumScaleFactor, title: "MinimumScaleFactor", attributes: [
                BlueprintAttribute(LookinAttr_UILabel_MinimumScaleFactor_MinimumScaleFactor, AttributeInfo(className: "UILabel", fullTitle: "MinimumScaleFactor", getterString: "minimumScaleFactor", setterString: "setMinimumScaleFactor:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UILabel_LineBreakStrategy, title: "LineBreakStrategy", attributes: [
                BlueprintAttribute(LookinAttr_UILabel_LineBreakStrategy_LineBreakStrategy, AttributeInfo(className: "UILabel", fullTitle: "LineBreakStrategy", getterString: "lineBreakStrategy", setterString: "", revision: 1, presentation: .optionNames("NSLineBreakStrategy"))),
            ]),
            BlueprintSection(LookinAttrSec_UILabel_PreferredMaxLayoutWidth, title: "PreferredMaxLayoutWidth", attributes: [
                BlueprintAttribute(LookinAttr_UILabel_PreferredMaxLayoutWidth_PreferredMaxLayoutWidth, AttributeInfo(className: "UILabel", fullTitle: "PreferredMaxLayoutWidth", getterString: "preferredMaxLayoutWidth", setterString: "setPreferredMaxLayoutWidth:", patch: true, revision: 1)),
            ]),
        ])

        static let uiControlGroup = BlueprintGroup(LookinAttrGroup_UIControl, title: "UIControl", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIControl_EnabledSelected, attributes: [
                BlueprintAttribute(LookinAttr_UIControl_EnabledSelected_Enabled, AttributeInfo(className: "UIControl", fullTitle: "Enabled", getterString: "isEnabled", patch: false)),
                BlueprintAttribute(LookinAttr_UIControl_EnabledSelected_Selected, AttributeInfo(className: "UIControl", fullTitle: "Selected", getterString: "isSelected", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIControl_QMUIOutsideEdge, title: "QMUI_outsideEdge", attributes: [
                BlueprintAttribute(LookinAttr_UIControl_QMUIOutsideEdge_Edge, AttributeInfo(className: "UIControl", fullTitle: "qmui_outsideEdge")),
            ]),
            BlueprintSection(LookinAttrSec_UIControl_VerAlignment, title: "VerticalAlignment", attributes: [
                BlueprintAttribute(LookinAttr_UIControl_VerAlignment_Alignment, AttributeInfo(className: "UIControl", fullTitle: "ContentVerticalAlignment", enumList: "UIControlContentVerticalAlignment", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIControl_HorAlignment, title: "HorizontalAlignment", attributes: [
                BlueprintAttribute(LookinAttr_UIControl_HorAlignment_Alignment, AttributeInfo(className: "UIControl", fullTitle: "ContentHorizontalAlignment", enumList: "UIControlContentHorizontalAlignment", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIControl_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UIControl_Behavior_Highlighted, AttributeInfo(className: "UIControl", fullTitle: "Highlighted", getterString: "isHighlighted", setterString: "setHighlighted:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIControl_Behavior_Tracking, AttributeInfo(className: "UIControl", fullTitle: "Tracking", getterString: "isTracking", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UIControl_Behavior_TouchInside, AttributeInfo(className: "UIControl", fullTitle: "TouchInside", getterString: "isTouchInside", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UIControl_Behavior_ContextMenuInteractionEnabled, AttributeInfo(className: "UIControl", fullTitle: "ContextMenuInteractionEnabled", getterString: "isContextMenuInteractionEnabled", setterString: "setContextMenuInteractionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIControl_Behavior_ShowsMenuAsPrimaryAction, AttributeInfo(className: "UIControl", fullTitle: "ShowsMenuAsPrimaryAction", getterString: "showsMenuAsPrimaryAction", setterString: "setShowsMenuAsPrimaryAction:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIControl_Behavior_SymbolAnimationEnabled, AttributeInfo(className: "UIControl", fullTitle: "SymbolAnimationEnabled", getterString: "isSymbolAnimationEnabled", setterString: "setSymbolAnimationEnabled:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIControl_EffectiveContentHorizontalAlignment, title: "EffectiveContentHorizontalAlignment", attributes: [
                BlueprintAttribute(LookinAttr_UIControl_EffectiveContentHorizontalAlignment_EffectiveContentHorizontalAlignment, AttributeInfo(className: "UIControl", fullTitle: "EffectiveContentHorizontalAlignment", getterString: "effectiveContentHorizontalAlignment", setterString: "", enumList: "UIControlContentHorizontalAlignment", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIControl_State, title: "State", attributes: [
                BlueprintAttribute(LookinAttr_UIControl_State_State, AttributeInfo(className: "UIControl", fullTitle: "State", getterString: "state", setterString: "", revision: 1, presentation: .optionNames("UIControlState"))),
            ]),
            BlueprintSection(LookinAttrSec_UIControl_AllControlEvents, title: "AllControlEvents", attributes: [
                BlueprintAttribute(LookinAttr_UIControl_AllControlEvents_AllControlEvents, AttributeInfo(className: "UIControl", fullTitle: "AllControlEvents", getterString: "allControlEvents", setterString: "", revision: 1, presentation: .optionNames("UIControlEvents"))),
            ]),
            BlueprintSection(LookinAttrSec_UIControl_ToolTip, title: "ToolTip", attributes: [
                BlueprintAttribute(LookinAttr_UIControl_ToolTip_ToolTip, AttributeInfo(className: "UIControl", fullTitle: "ToolTip", getterString: "toolTip", setterString: "setToolTip:", typeIfObj: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
        ])

        static let uiButtonGroup = BlueprintGroup(LookinAttrGroup_UIButton, title: "UIButton", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIButton_ContentInsets, title: "ContentInsets", attributes: [
                BlueprintAttribute(LookinAttr_UIButton_ContentInsets_Insets, AttributeInfo(className: "UIButton", fullTitle: "ContentEdgeInsets", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIButton_TitleInsets, title: "TitleInsets", attributes: [
                BlueprintAttribute(LookinAttr_UIButton_TitleInsets_Insets, AttributeInfo(className: "UIButton", fullTitle: "TitleEdgeInsets", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIButton_ImageInsets, title: "ImageInsets", attributes: [
                BlueprintAttribute(LookinAttr_UIButton_ImageInsets_Insets, AttributeInfo(className: "UIButton", fullTitle: "ImageEdgeInsets", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIButton_BehavioralStyle, title: "BehavioralStyle", attributes: [
                BlueprintAttribute(LookinAttr_UIButton_BehavioralStyle_BehavioralStyle, AttributeInfo(className: "UIButton", fullTitle: "BehavioralStyle", getterString: "behavioralStyle", setterString: "", enumList: "UIBehavioralStyle", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIButton_PreferredBehavioralStyle, title: "PreferredBehavioralStyle", attributes: [
                BlueprintAttribute(LookinAttr_UIButton_PreferredBehavioralStyle_PreferredBehavioralStyle, AttributeInfo(className: "UIButton", fullTitle: "PreferredBehavioralStyle", getterString: "preferredBehavioralStyle", setterString: "setPreferredBehavioralStyle:", enumList: "UIBehavioralStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIButton_Configuration, title: "Configuration", attributes: [
                BlueprintAttribute(LookinAttr_UIButton_Configuration_Configuration, AttributeInfo(className: "UIButton", fullTitle: "Configuration", getterString: "configuration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.configuration))),
            ]),
            BlueprintSection(LookinAttrSec_UIButton_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UIButton_Behavior_AutomaticallyUpdatesConfiguration, AttributeInfo(className: "UIButton", fullTitle: "AutomaticallyUpdatesConfiguration", getterString: "automaticallyUpdatesConfiguration", setterString: "setAutomaticallyUpdatesConfiguration:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIButton_Behavior_Hovered, AttributeInfo(className: "UIButton", fullTitle: "Hovered", getterString: "isHovered", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UIButton_Behavior_Held, AttributeInfo(className: "UIButton", fullTitle: "Held", getterString: "isHeld", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UIButton_Behavior_PointerInteractionEnabled, AttributeInfo(className: "UIButton", fullTitle: "PointerInteractionEnabled", getterString: "isPointerInteractionEnabled", setterString: "setPointerInteractionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIButton_Behavior_ChangesSelectionAsPrimaryAction, AttributeInfo(className: "UIButton", fullTitle: "ChangesSelectionAsPrimaryAction", getterString: "changesSelectionAsPrimaryAction", setterString: "setChangesSelectionAsPrimaryAction:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIButton_ButtonType, title: "ButtonType", attributes: [
                BlueprintAttribute(LookinAttr_UIButton_ButtonType_ButtonType, AttributeInfo(className: "UIButton", fullTitle: "ButtonType", getterString: "buttonType", setterString: "", enumList: "UIButtonType", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIButton_Role, title: "Role", attributes: [
                BlueprintAttribute(LookinAttr_UIButton_Role_Role, AttributeInfo(className: "UIButton", fullTitle: "Role", getterString: "role", setterString: "setRole:", enumList: "UIButtonRole", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIButton_Menu, title: "Menu", attributes: [
                BlueprintAttribute(LookinAttr_UIButton_Menu_Menu, AttributeInfo(className: "UIButton", fullTitle: "Menu", getterString: "menu", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.menu))),
            ]),
            BlueprintSection(LookinAttrSec_UIButton_CurrentTitle, title: "CurrentTitle", attributes: [
                BlueprintAttribute(LookinAttr_UIButton_CurrentTitle_CurrentTitle, AttributeInfo(className: "UIButton", fullTitle: "CurrentTitle", getterString: "currentTitle", setterString: "", typeIfObj: .nsString, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIButton_Colors, title: "Colors", attributes: [
                BlueprintAttribute(LookinAttr_UIButton_Colors_CurrentTitleColor, AttributeInfo(className: "UIButton", fullTitle: "CurrentTitleColor", getterString: "currentTitleColor", setterString: "", typeIfObj: .uiColor, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIButton_Colors_CurrentTitleShadowColor, AttributeInfo(className: "UIButton", fullTitle: "CurrentTitleShadowColor", getterString: "currentTitleShadowColor", setterString: "", typeIfObj: .uiColor, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIButton_Images, title: "Images", attributes: [
                BlueprintAttribute(LookinAttr_UIButton_Images_CurrentImage, AttributeInfo(className: "UIButton", fullTitle: "CurrentImage", getterString: "currentImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_UIButton_Images_CurrentBackgroundImage, AttributeInfo(className: "UIButton", fullTitle: "CurrentBackgroundImage", getterString: "currentBackgroundImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(LookinAttrSec_UIButton_CurrentPreferredSymbolConfiguration, title: "CurrentPreferredSymbolConfiguration", attributes: [
                BlueprintAttribute(LookinAttr_UIButton_CurrentPreferredSymbolConfiguration_CurrentPreferredSymbolConfiguration, AttributeInfo(className: "UIButton", fullTitle: "CurrentPreferredSymbolConfiguration", getterString: "currentPreferredSymbolConfiguration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.description))),
            ]),
        ])

        static let uiScrollViewGroup = BlueprintGroup(LookinAttrGroup_UIScrollView, title: "UIScrollView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIScrollView_ContentInset, title: "ContentInset", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_ContentInset_Inset, AttributeInfo(className: "UIScrollView", fullTitle: "ContentInset", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_AdjustedInset, title: "AdjustedContentInset", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_AdjustedInset_Inset, AttributeInfo(className: "UIScrollView", fullTitle: "AdjustedContentInset", setterString: "", osVersion: 11)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_QMUIInitialInset, title: "QMUI_initialContentInset", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_QMUIInitialInset_Inset, AttributeInfo(className: "UIScrollView", fullTitle: "qmui_initialContentInset", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_IndicatorInset, title: "ScrollIndicatorInsets", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_IndicatorInset_Inset, AttributeInfo(className: "UIScrollView", fullTitle: "ScrollIndicatorInsets", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_Offset, title: "ContentOffset", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_Offset_Offset, AttributeInfo(className: "UIScrollView", fullTitle: "ContentOffset", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_ContentSize, title: "ContentSize", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_ContentSize_Size, AttributeInfo(className: "UIScrollView", fullTitle: "ContentSize", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_Behavior, title: "InsetAdjustmentBehavior", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_Behavior_Behavior, AttributeInfo(className: "UIScrollView", fullTitle: "ContentInsetAdjustmentBehavior", enumList: "UIScrollViewContentInsetAdjustmentBehavior", patch: true, osVersion: 11)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_ShowsIndicator, title: "ShowsScrollIndicator", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_ShowsIndicator_Hor, AttributeInfo(className: "UIScrollView", fullTitle: "ShowsHorizontalScrollIndicator", briefTitle: "Horizontal", patch: false)),
                BlueprintAttribute(LookinAttr_UIScrollView_ShowsIndicator_Ver, AttributeInfo(className: "UIScrollView", fullTitle: "ShowsVerticalScrollIndicator", briefTitle: "Vertical", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_Bounce, title: "AlwaysBounce", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_Bounce_Hor, AttributeInfo(className: "UIScrollView", fullTitle: "AlwaysBounceHorizontal", briefTitle: "Horizontal", patch: false)),
                BlueprintAttribute(LookinAttr_UIScrollView_Bounce_Ver, AttributeInfo(className: "UIScrollView", fullTitle: "AlwaysBounceVertical", briefTitle: "Vertical", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_ScrollPaging, attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_ScrollPaging_ScrollEnabled, AttributeInfo(className: "UIScrollView", fullTitle: "ScrollEnabled", getterString: "isScrollEnabled", patch: false)),
                BlueprintAttribute(LookinAttr_UIScrollView_ScrollPaging_PagingEnabled, AttributeInfo(className: "UIScrollView", fullTitle: "PagingEnabled", getterString: "isPagingEnabled", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_ContentTouches, attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_ContentTouches_Delay, AttributeInfo(className: "UIScrollView", fullTitle: "DelaysContentTouches", patch: false)),
                BlueprintAttribute(LookinAttr_UIScrollView_ContentTouches_CanCancel, AttributeInfo(className: "UIScrollView", fullTitle: "CanCancelContentTouches", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_Zoom, title: "Zoom", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_Zoom_Bounce, AttributeInfo(className: "UIScrollView", fullTitle: "BouncesZoom", patch: false)),
                BlueprintAttribute(LookinAttr_UIScrollView_Zoom_Scale, AttributeInfo(className: "UIScrollView", fullTitle: "ZoomScale", briefTitle: "Scale", patch: true)),
                BlueprintAttribute(LookinAttr_UIScrollView_Zoom_MinScale, AttributeInfo(className: "UIScrollView", fullTitle: "MinimumZoomScale", briefTitle: "MinScale", patch: false)),
                BlueprintAttribute(LookinAttr_UIScrollView_Zoom_MaxScale, AttributeInfo(className: "UIScrollView", fullTitle: "MaximumZoomScale", briefTitle: "MaxScale", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_ContentAlignmentPoint, title: "ContentAlignmentPoint", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_ContentAlignmentPoint_ContentAlignmentPoint, AttributeInfo(className: "UIScrollView", fullTitle: "ContentAlignmentPoint", getterString: "contentAlignmentPoint", setterString: "setContentAlignmentPoint:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_Flags, title: "Flags", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_Flags_AutomaticallyAdjustsScrollIndicatorInsets, AttributeInfo(className: "UIScrollView", fullTitle: "AutomaticallyAdjustsScrollIndicatorInsets", getterString: "automaticallyAdjustsScrollIndicatorInsets", setterString: "setAutomaticallyAdjustsScrollIndicatorInsets:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIScrollView_Flags_DirectionalLockEnabled, AttributeInfo(className: "UIScrollView", fullTitle: "DirectionalLockEnabled", getterString: "isDirectionalLockEnabled", setterString: "setDirectionalLockEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIScrollView_Flags_Bounces, AttributeInfo(className: "UIScrollView", fullTitle: "Bounces", getterString: "bounces", setterString: "setBounces:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIScrollView_Flags_BouncesHorizontally, AttributeInfo(className: "UIScrollView", fullTitle: "BouncesHorizontally", getterString: "bouncesHorizontally", setterString: "setBouncesHorizontally:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIScrollView_Flags_BouncesVertically, AttributeInfo(className: "UIScrollView", fullTitle: "BouncesVertically", getterString: "bouncesVertically", setterString: "setBouncesVertically:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIScrollView_Flags_TransfersHorizontalScrollingToParent, AttributeInfo(className: "UIScrollView", fullTitle: "TransfersHorizontalScrollingToParent", getterString: "transfersHorizontalScrollingToParent", setterString: "setTransfersHorizontalScrollingToParent:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIScrollView_Flags_TransfersVerticalScrollingToParent, AttributeInfo(className: "UIScrollView", fullTitle: "TransfersVerticalScrollingToParent", getterString: "transfersVerticalScrollingToParent", setterString: "setTransfersVerticalScrollingToParent:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIScrollView_Flags_Tracking, AttributeInfo(className: "UIScrollView", fullTitle: "Tracking", getterString: "isTracking", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UIScrollView_Flags_Dragging, AttributeInfo(className: "UIScrollView", fullTitle: "Dragging", getterString: "isDragging", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UIScrollView_Flags_Decelerating, AttributeInfo(className: "UIScrollView", fullTitle: "Decelerating", getterString: "isDecelerating", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UIScrollView_Flags_ScrollAnimating, AttributeInfo(className: "UIScrollView", fullTitle: "ScrollAnimating", getterString: "isScrollAnimating", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UIScrollView_Flags_Zooming, AttributeInfo(className: "UIScrollView", fullTitle: "Zooming", getterString: "isZooming", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UIScrollView_Flags_ZoomBouncing, AttributeInfo(className: "UIScrollView", fullTitle: "ZoomBouncing", getterString: "isZoomBouncing", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UIScrollView_Flags_ZoomAnimating, AttributeInfo(className: "UIScrollView", fullTitle: "ZoomAnimating", getterString: "isZoomAnimating", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UIScrollView_Flags_ScrollsToTop, AttributeInfo(className: "UIScrollView", fullTitle: "ScrollsToTop", getterString: "scrollsToTop", setterString: "setScrollsToTop:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIScrollView_Flags_AllowsKeyboardScrolling, AttributeInfo(className: "UIScrollView", fullTitle: "AllowsKeyboardScrolling", getterString: "allowsKeyboardScrolling", setterString: "setAllowsKeyboardScrolling:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_IndicatorStyle, title: "IndicatorStyle", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_IndicatorStyle_IndicatorStyle, AttributeInfo(className: "UIScrollView", fullTitle: "IndicatorStyle", getterString: "indicatorStyle", setterString: "setIndicatorStyle:", enumList: "UIScrollViewIndicatorStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_VerticalScrollIndicatorInsets, title: "VerticalScrollIndicatorInsets", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_VerticalScrollIndicatorInsets_VerticalScrollIndicatorInsets, AttributeInfo(className: "UIScrollView", fullTitle: "VerticalScrollIndicatorInsets", getterString: "verticalScrollIndicatorInsets", setterString: "setVerticalScrollIndicatorInsets:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_HorizontalScrollIndicatorInsets, title: "HorizontalScrollIndicatorInsets", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_HorizontalScrollIndicatorInsets_HorizontalScrollIndicatorInsets, AttributeInfo(className: "UIScrollView", fullTitle: "HorizontalScrollIndicatorInsets", getterString: "horizontalScrollIndicatorInsets", setterString: "setHorizontalScrollIndicatorInsets:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_DecelerationRate, title: "DecelerationRate", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_DecelerationRate_DecelerationRate, AttributeInfo(className: "UIScrollView", fullTitle: "DecelerationRate", getterString: "decelerationRate", setterString: "setDecelerationRate:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_IndexDisplayMode, title: "IndexDisplayMode", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_IndexDisplayMode_IndexDisplayMode, AttributeInfo(className: "UIScrollView", fullTitle: "IndexDisplayMode", getterString: "indexDisplayMode", setterString: "setIndexDisplayMode:", enumList: "UIScrollViewIndexDisplayMode", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIScrollView_KeyboardDismissMode, title: "KeyboardDismissMode", attributes: [
                BlueprintAttribute(LookinAttr_UIScrollView_KeyboardDismissMode_KeyboardDismissMode, AttributeInfo(className: "UIScrollView", fullTitle: "KeyboardDismissMode", getterString: "keyboardDismissMode", setterString: "setKeyboardDismissMode:", enumList: "UIScrollViewKeyboardDismissMode", patch: true, revision: 1)),
            ]),
        ])

        static let uiTableViewGroup = BlueprintGroup(LookinAttrGroup_UITableView, title: "UITableView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UITableView_Style, title: "Style", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_Style_Style, AttributeInfo(className: "UITableView", fullTitle: "Style", setterString: "", enumList: "UITableViewStyle", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_SectionsNumber, title: "NumberOfSections", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_SectionsNumber_Number, AttributeInfo(className: "UITableView", fullTitle: "NumberOfSections", setterString: "", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_RowsNumber, title: "NumberOfRows", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_RowsNumber_Number, AttributeInfo(className: "UITableView", getterString: "lks_numberOfRows", setterString: "", typeIfObj: .customObj)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_SeparatorStyle, title: "SeparatorStyle", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_SeparatorStyle_Style, AttributeInfo(className: "UITableView", fullTitle: "SeparatorStyle", enumList: "UITableViewCellSeparatorStyle", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_SeparatorColor, title: "SeparatorColor", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_SeparatorColor_Color, AttributeInfo(className: "UITableView", fullTitle: "SeparatorColor", typeIfObj: .uiColor, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_SeparatorInset, title: "SeparatorInset", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_SeparatorInset_Inset, AttributeInfo(className: "UITableView", fullTitle: "SeparatorInset", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_Behavior_PrefetchingEnabled, AttributeInfo(className: "UITableView", fullTitle: "PrefetchingEnabled", getterString: "isPrefetchingEnabled", setterString: "setPrefetchingEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableView_Behavior_HasUncommittedUpdates, AttributeInfo(className: "UITableView", fullTitle: "HasUncommittedUpdates", getterString: "hasUncommittedUpdates", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UITableView_Behavior_Editing, AttributeInfo(className: "UITableView", fullTitle: "Editing", getterString: "isEditing", setterString: "setEditing:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableView_Behavior_AllowsSelection, AttributeInfo(className: "UITableView", fullTitle: "AllowsSelection", getterString: "allowsSelection", setterString: "setAllowsSelection:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableView_Behavior_AllowsSelectionDuringEditing, AttributeInfo(className: "UITableView", fullTitle: "AllowsSelectionDuringEditing", getterString: "allowsSelectionDuringEditing", setterString: "setAllowsSelectionDuringEditing:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableView_Behavior_AllowsMultipleSelection, AttributeInfo(className: "UITableView", fullTitle: "AllowsMultipleSelection", getterString: "allowsMultipleSelection", setterString: "setAllowsMultipleSelection:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableView_Behavior_AllowsMultipleSelectionDuringEditing, AttributeInfo(className: "UITableView", fullTitle: "AllowsMultipleSelectionDuringEditing", getterString: "allowsMultipleSelectionDuringEditing", setterString: "setAllowsMultipleSelectionDuringEditing:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableView_Behavior_CellLayoutMarginsFollowReadableWidth, AttributeInfo(className: "UITableView", fullTitle: "CellLayoutMarginsFollowReadableWidth", getterString: "cellLayoutMarginsFollowReadableWidth", setterString: "setCellLayoutMarginsFollowReadableWidth:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableView_Behavior_InsetsContentViewsToSafeArea, AttributeInfo(className: "UITableView", fullTitle: "InsetsContentViewsToSafeArea", getterString: "insetsContentViewsToSafeArea", setterString: "setInsetsContentViewsToSafeArea:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableView_Behavior_RemembersLastFocusedIndexPath, AttributeInfo(className: "UITableView", fullTitle: "RemembersLastFocusedIndexPath", getterString: "remembersLastFocusedIndexPath", setterString: "setRemembersLastFocusedIndexPath:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableView_Behavior_SelectionFollowsFocus, AttributeInfo(className: "UITableView", fullTitle: "SelectionFollowsFocus", getterString: "selectionFollowsFocus", setterString: "setSelectionFollowsFocus:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableView_Behavior_AllowsFocus, AttributeInfo(className: "UITableView", fullTitle: "AllowsFocus", getterString: "allowsFocus", setterString: "setAllowsFocus:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableView_Behavior_AllowsFocusDuringEditing, AttributeInfo(className: "UITableView", fullTitle: "AllowsFocusDuringEditing", getterString: "allowsFocusDuringEditing", setterString: "setAllowsFocusDuringEditing:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableView_Behavior_DragInteractionEnabled, AttributeInfo(className: "UITableView", fullTitle: "DragInteractionEnabled", getterString: "dragInteractionEnabled", setterString: "setDragInteractionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableView_Behavior_HasActiveDrag, AttributeInfo(className: "UITableView", fullTitle: "HasActiveDrag", getterString: "hasActiveDrag", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UITableView_Behavior_HasActiveDrop, AttributeInfo(className: "UITableView", fullTitle: "HasActiveDrop", getterString: "hasActiveDrop", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_RowHeight, title: "RowHeight", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_RowHeight_RowHeight, AttributeInfo(className: "UITableView", fullTitle: "RowHeight", getterString: "rowHeight", setterString: "setRowHeight:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_SectionHeaderHeight, title: "SectionHeaderHeight", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_SectionHeaderHeight_SectionHeaderHeight, AttributeInfo(className: "UITableView", fullTitle: "SectionHeaderHeight", getterString: "sectionHeaderHeight", setterString: "setSectionHeaderHeight:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_SectionFooterHeight, title: "SectionFooterHeight", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_SectionFooterHeight_SectionFooterHeight, AttributeInfo(className: "UITableView", fullTitle: "SectionFooterHeight", getterString: "sectionFooterHeight", setterString: "setSectionFooterHeight:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_EstimatedRowHeight, title: "EstimatedRowHeight", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_EstimatedRowHeight_EstimatedRowHeight, AttributeInfo(className: "UITableView", fullTitle: "EstimatedRowHeight", getterString: "estimatedRowHeight", setterString: "setEstimatedRowHeight:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_EstimatedSectionHeaderHeight, title: "EstimatedSectionHeaderHeight", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_EstimatedSectionHeaderHeight_EstimatedSectionHeaderHeight, AttributeInfo(className: "UITableView", fullTitle: "EstimatedSectionHeaderHeight", getterString: "estimatedSectionHeaderHeight", setterString: "setEstimatedSectionHeaderHeight:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_EstimatedSectionFooterHeight, title: "EstimatedSectionFooterHeight", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_EstimatedSectionFooterHeight_EstimatedSectionFooterHeight, AttributeInfo(className: "UITableView", fullTitle: "EstimatedSectionFooterHeight", getterString: "estimatedSectionFooterHeight", setterString: "setEstimatedSectionFooterHeight:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_FillerRowHeight, title: "FillerRowHeight", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_FillerRowHeight_FillerRowHeight, AttributeInfo(className: "UITableView", fullTitle: "FillerRowHeight", getterString: "fillerRowHeight", setterString: "setFillerRowHeight:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_SectionHeaderTopPadding, title: "SectionHeaderTopPadding", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_SectionHeaderTopPadding_SectionHeaderTopPadding, AttributeInfo(className: "UITableView", fullTitle: "SectionHeaderTopPadding", getterString: "sectionHeaderTopPadding", setterString: "setSectionHeaderTopPadding:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_SeparatorInsetReference, title: "SeparatorInsetReference", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_SeparatorInsetReference_SeparatorInsetReference, AttributeInfo(className: "UITableView", fullTitle: "SeparatorInsetReference", getterString: "separatorInsetReference", setterString: "setSeparatorInsetReference:", enumList: "UITableViewSeparatorInsetReference", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_SelfSizingInvalidation, title: "SelfSizingInvalidation", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_SelfSizingInvalidation_SelfSizingInvalidation, AttributeInfo(className: "UITableView", fullTitle: "SelfSizingInvalidation", getterString: "selfSizingInvalidation", setterString: "setSelfSizingInvalidation:", enumList: "UITableViewSelfSizingInvalidation", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_IndexPathsForSelectedRows, title: "IndexPathsForSelectedRows", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_IndexPathsForSelectedRows_IndexPathsForSelectedRows, AttributeInfo(className: "UITableView", fullTitle: "IndexPathsForSelectedRows", getterString: "indexPathsForSelectedRows", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_SectionIndexMinimumDisplayRowCount, title: "SectionIndexMinimumDisplayRowCount", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_SectionIndexMinimumDisplayRowCount_SectionIndexMinimumDisplayRowCount, AttributeInfo(className: "UITableView", fullTitle: "SectionIndexMinimumDisplayRowCount", getterString: "sectionIndexMinimumDisplayRowCount", setterString: "setSectionIndexMinimumDisplayRowCount:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_Colors, title: "Colors", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_Colors_SectionIndexColor, AttributeInfo(className: "UITableView", fullTitle: "SectionIndexColor", getterString: "sectionIndexColor", setterString: "setSectionIndexColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableView_Colors_SectionIndexBackgroundColor, AttributeInfo(className: "UITableView", fullTitle: "SectionIndexBackgroundColor", getterString: "sectionIndexBackgroundColor", setterString: "setSectionIndexBackgroundColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableView_Colors_SectionIndexTrackingBackgroundColor, AttributeInfo(className: "UITableView", fullTitle: "SectionIndexTrackingBackgroundColor", getterString: "sectionIndexTrackingBackgroundColor", setterString: "setSectionIndexTrackingBackgroundColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_SeparatorEffect, title: "SeparatorEffect", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_SeparatorEffect_SeparatorEffect, AttributeInfo(className: "UITableView", fullTitle: "SeparatorEffect", getterString: "separatorEffect", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.className))),
            ]),
            BlueprintSection(LookinAttrSec_UITableView_ContentHuggingElements, title: "ContentHuggingElements", attributes: [
                BlueprintAttribute(LookinAttr_UITableView_ContentHuggingElements_ContentHuggingElements, AttributeInfo(className: "UITableView", fullTitle: "ContentHuggingElements", getterString: "contentHuggingElements", setterString: "", revision: 1, presentation: .optionNames("UITableViewContentHuggingElements"))),
            ]),
        ])

        static let uiTextViewGroup = BlueprintGroup(LookinAttrGroup_UITextView, title: "UITextView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UITextView_Basic, attributes: [
                BlueprintAttribute(LookinAttr_UITextView_Basic_Editable, AttributeInfo(className: "UITextView", fullTitle: "Editable", getterString: "isEditable", patch: false)),
                BlueprintAttribute(LookinAttr_UITextView_Basic_Selectable, AttributeInfo(className: "UITextView", fullTitle: "Selectable", getterString: "isSelectable", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_UITextView_Text, title: "Text", attributes: [
                BlueprintAttribute(LookinAttr_UITextView_Text_Text, AttributeInfo(className: "UITextView", fullTitle: "Text", typeIfObj: .nsString, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UITextView_Font, title: "Font", attributes: [
                BlueprintAttribute(LookinAttr_UITextView_Font_Name, AttributeInfo(className: "UITextView", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", typeIfObj: .nsString, patch: false)),
                BlueprintAttribute(LookinAttr_UITextView_Font_Size, AttributeInfo(className: "UITextView", fullTitle: "FontSize", getterString: "lks_fontSize", setterString: "setLks_fontSize:", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UITextView_TextColor, title: "TextColor", attributes: [
                BlueprintAttribute(LookinAttr_UITextView_TextColor_Color, AttributeInfo(className: "UITextView", fullTitle: "TextColor", typeIfObj: .uiColor, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UITextView_Alignment, title: "TextAlignment", attributes: [
                BlueprintAttribute(LookinAttr_UITextView_Alignment_Alignment, AttributeInfo(className: "UITextView", fullTitle: "TextAlignment", enumList: "NSTextAlignment", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UITextView_ContainerInset, title: "ContainerInset", attributes: [
                BlueprintAttribute(LookinAttr_UITextView_ContainerInset_Inset, AttributeInfo(className: "UITextView", fullTitle: "TextContainerInset", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UITextView_DataDetectorTypes, title: "DataDetectorTypes", attributes: [
                BlueprintAttribute(LookinAttr_UITextView_DataDetectorTypes_DataDetectorTypes, AttributeInfo(className: "UITextView", fullTitle: "DataDetectorTypes", getterString: "dataDetectorTypes", setterString: "", revision: 1, presentation: .optionNames("UIDataDetectorTypes"))),
            ]),
            BlueprintSection(LookinAttrSec_UITextView_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UITextView_Behavior_AllowsEditingTextAttributes, AttributeInfo(className: "UITextView", fullTitle: "AllowsEditingTextAttributes", getterString: "allowsEditingTextAttributes", setterString: "setAllowsEditingTextAttributes:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITextView_Behavior_ClearsOnInsertion, AttributeInfo(className: "UITextView", fullTitle: "ClearsOnInsertion", getterString: "clearsOnInsertion", setterString: "setClearsOnInsertion:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITextView_Behavior_UsesStandardTextScaling, AttributeInfo(className: "UITextView", fullTitle: "UsesStandardTextScaling", getterString: "usesStandardTextScaling", setterString: "setUsesStandardTextScaling:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITextView_Behavior_FindInteractionEnabled, AttributeInfo(className: "UITextView", fullTitle: "FindInteractionEnabled", getterString: "isFindInteractionEnabled", setterString: "setFindInteractionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITextView_Behavior_WritingToolsActive, AttributeInfo(className: "UITextView", fullTitle: "WritingToolsActive", getterString: "isWritingToolsActive", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITextView_BorderStyle, title: "BorderStyle", attributes: [
                BlueprintAttribute(LookinAttr_UITextView_BorderStyle_BorderStyle, AttributeInfo(className: "UITextView", fullTitle: "BorderStyle", getterString: "borderStyle", setterString: "setBorderStyle:", enumList: "UITextViewBorderStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITextView_WritingToolsBehavior, title: "WritingToolsBehavior", attributes: [
                BlueprintAttribute(LookinAttr_UITextView_WritingToolsBehavior_WritingToolsBehavior, AttributeInfo(className: "UITextView", fullTitle: "WritingToolsBehavior", getterString: "writingToolsBehavior", setterString: "setWritingToolsBehavior:", enumList: "UIWritingToolsBehavior", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITextView_AllowedWritingToolsResultOptions, title: "AllowedWritingToolsResultOptions", attributes: [
                BlueprintAttribute(LookinAttr_UITextView_AllowedWritingToolsResultOptions_AllowedWritingToolsResultOptions, AttributeInfo(className: "UITextView", fullTitle: "AllowedWritingToolsResultOptions", getterString: "allowedWritingToolsResultOptions", setterString: "", revision: 1, presentation: .optionNames("UIWritingToolsResultOptions"))),
            ]),
        ])

        static let uiTextFieldGroup = BlueprintGroup(LookinAttrGroup_UITextField, title: "UITextField", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UITextField_Text, title: "Text", attributes: [
                BlueprintAttribute(LookinAttr_UITextField_Text_Text, AttributeInfo(className: "UITextField", fullTitle: "Text", typeIfObj: .nsString, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UITextField_Placeholder, title: "Placeholder", attributes: [
                BlueprintAttribute(LookinAttr_UITextField_Placeholder_Placeholder, AttributeInfo(className: "UITextField", fullTitle: "Placeholder", typeIfObj: .nsString, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UITextField_Font, title: "Font", attributes: [
                BlueprintAttribute(LookinAttr_UITextField_Font_Name, AttributeInfo(className: "UITextField", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", typeIfObj: .nsString, patch: false)),
                BlueprintAttribute(LookinAttr_UITextField_Font_Size, AttributeInfo(className: "UITextField", fullTitle: "FontSize", getterString: "lks_fontSize", setterString: "setLks_fontSize:", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UITextField_TextColor, title: "TextColor", attributes: [
                BlueprintAttribute(LookinAttr_UITextField_TextColor_Color, AttributeInfo(className: "UITextField", fullTitle: "TextColor", typeIfObj: .uiColor, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UITextField_Alignment, title: "TextAlignment", attributes: [
                BlueprintAttribute(LookinAttr_UITextField_Alignment_Alignment, AttributeInfo(className: "UITextField", fullTitle: "TextAlignment", enumList: "NSTextAlignment", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UITextField_Clears, attributes: [
                BlueprintAttribute(LookinAttr_UITextField_Clears_ClearsOnBeginEditing, AttributeInfo(className: "UITextField", fullTitle: "ClearsOnBeginEditing", patch: false)),
                BlueprintAttribute(LookinAttr_UITextField_Clears_ClearsOnInsertion, AttributeInfo(className: "UITextField", fullTitle: "ClearsOnInsertion", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_UITextField_CanAdjustFont, attributes: [
                BlueprintAttribute(LookinAttr_UITextField_CanAdjustFont_CanAdjustFont, AttributeInfo(className: "UITextField", fullTitle: "AdjustsFontSizeToFitWidth", patch: true)),
                BlueprintAttribute(LookinAttr_UITextField_CanAdjustFont_MinSize, AttributeInfo(className: "UITextField", fullTitle: "MinimumFontSize", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_UITextField_ClearButtonMode, title: "ClearButtonMode", attributes: [
                BlueprintAttribute(LookinAttr_UITextField_ClearButtonMode_Mode, AttributeInfo(className: "UITextField", fullTitle: "ClearButtonMode", enumList: "UITextFieldViewMode", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_UITextField_UISearchTextField, title: "UISearchTextField", attributes: [
                BlueprintAttribute(LookinAttr_UITextField_UISearchTextField_Tokens, AttributeInfo(className: "UISearchTextField", fullTitle: "Tokens", getterString: "tokens", setterString: "", revision: 1, presentation: .count)),
                BlueprintAttribute(LookinAttr_UITextField_UISearchTextField_TokenBackgroundColor, AttributeInfo(className: "UISearchTextField", fullTitle: "TokenBackgroundColor", getterString: "tokenBackgroundColor", setterString: "setTokenBackgroundColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITextField_UISearchTextField_AllowsDeletingTokens, AttributeInfo(className: "UISearchTextField", fullTitle: "AllowsDeletingTokens", getterString: "allowsDeletingTokens", setterString: "setAllowsDeletingTokens:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITextField_UISearchTextField_AllowsCopyingTokens, AttributeInfo(className: "UISearchTextField", fullTitle: "AllowsCopyingTokens", getterString: "allowsCopyingTokens", setterString: "setAllowsCopyingTokens:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITextField_UISearchTextField_SearchSuggestions, AttributeInfo(className: "UISearchTextField", fullTitle: "SearchSuggestions", getterString: "searchSuggestions", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(LookinAttrSec_UITextField_BorderStyle, title: "BorderStyle", attributes: [
                BlueprintAttribute(LookinAttr_UITextField_BorderStyle_BorderStyle, AttributeInfo(className: "UITextField", fullTitle: "BorderStyle", getterString: "borderStyle", setterString: "setBorderStyle:", enumList: "UITextBorderStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITextField_Images, title: "Images", attributes: [
                BlueprintAttribute(LookinAttr_UITextField_Images_Background, AttributeInfo(className: "UITextField", fullTitle: "Background", getterString: "background", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_UITextField_Images_DisabledBackground, AttributeInfo(className: "UITextField", fullTitle: "DisabledBackground", getterString: "disabledBackground", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(LookinAttrSec_UITextField_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UITextField_Behavior_Editing, AttributeInfo(className: "UITextField", fullTitle: "Editing", getterString: "isEditing", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UITextField_Behavior_AllowsEditingTextAttributes, AttributeInfo(className: "UITextField", fullTitle: "AllowsEditingTextAttributes", getterString: "allowsEditingTextAttributes", setterString: "setAllowsEditingTextAttributes:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITextField_LeftViewMode, title: "LeftViewMode", attributes: [
                BlueprintAttribute(LookinAttr_UITextField_LeftViewMode_LeftViewMode, AttributeInfo(className: "UITextField", fullTitle: "LeftViewMode", getterString: "leftViewMode", setterString: "setLeftViewMode:", enumList: "UITextFieldViewMode", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITextField_RightViewMode, title: "RightViewMode", attributes: [
                BlueprintAttribute(LookinAttr_UITextField_RightViewMode_RightViewMode, AttributeInfo(className: "UITextField", fullTitle: "RightViewMode", getterString: "rightViewMode", setterString: "setRightViewMode:", enumList: "UITextFieldViewMode", patch: true, revision: 1)),
            ]),
        ])

        static let uiWindowSceneGroup = BlueprintGroup(LookinAttrGroup_UIWindowScene, title: "UIWindowScene", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIWindowScene_State, title: "State", attributes: [
                BlueprintAttribute(LookinAttr_UIWindowScene_State_ActivationState, AttributeInfo(className: "UIWindowScene", fullTitle: "ActivationState", getterString: "activationState", setterString: "", enumList: "UISceneActivationState", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_UIWindowScene_Title, title: "Title", attributes: [
                BlueprintAttribute(LookinAttr_UIWindowScene_Title_Title, AttributeInfo(className: "UIWindowScene", fullTitle: "Title", typeIfObj: .nsString, patch: true)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Title_Subtitle, AttributeInfo(className: "UIWindowScene", fullTitle: "Subtitle", typeIfObj: .nsString, patch: true, osVersion: 15)),
            ]),
            BlueprintSection(LookinAttrSec_UIWindowScene_Orientation, title: "Orientation", attributes: [
                BlueprintAttribute(LookinAttr_UIWindowScene_Orientation_InterfaceOrientation, AttributeInfo(className: "UIWindowScene", fullTitle: "InterfaceOrientation", getterString: "lks_interfaceOrientation", setterString: "", enumList: "UIInterfaceOrientation", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_UIWindowScene_Geometry, title: "Geometry", attributes: [
                // UIWindowSceneGeometry — every entry returns an object so that it can
                // disappear via hideIfNil on platforms and OS versions that lack it.
                BlueprintAttribute(LookinAttr_UIWindowScene_Geometry_SystemFrame, AttributeInfo(className: "UIWindowScene", fullTitle: "SystemFrame", getterString: "lks_geometrySystemFrame", setterString: "", typeIfObj: .cgRect, patch: false, hideIfNil: true, osVersion: 16)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Geometry_InterfaceOrientationLocked, AttributeInfo(className: "UIWindowScene", fullTitle: "InterfaceOrientationLocked", getterString: "lks_geometryInterfaceOrientationLocked", setterString: "", typeIfObj: .BOOL, patch: false, hideIfNil: true, osVersion: 26)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Geometry_InteractivelyResizing, AttributeInfo(className: "UIWindowScene", fullTitle: "InteractivelyResizing", getterString: "lks_geometryInteractivelyResizing", setterString: "", typeIfObj: .BOOL, patch: false, hideIfNil: true, osVersion: 26)),
            ]),
            BlueprintSection(LookinAttrSec_UIWindowScene_Windows, title: "Windows", attributes: [
                BlueprintAttribute(LookinAttr_UIWindowScene_Windows_WindowCount, AttributeInfo(className: "UIWindowScene", fullTitle: "WindowCount", getterString: "lks_windowCount", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Windows_KeyWindowClassName, AttributeInfo(className: "UIWindowScene", fullTitle: "KeyWindowClassName", getterString: "lks_keyWindowClassName", setterString: "", typeIfObj: .nsString, patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_UIWindowScene_Screen, title: "Screen", attributes: [
                BlueprintAttribute(LookinAttr_UIWindowScene_Screen_ScreenBounds, AttributeInfo(className: "UIWindowScene", fullTitle: "ScreenBounds", getterString: "lks_screenBounds", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Screen_ScreenScale, AttributeInfo(className: "UIWindowScene", fullTitle: "ScreenScale", getterString: "lks_screenScale", setterString: "", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_UIWindowScene_StatusBar, title: "StatusBar", attributes: [
                BlueprintAttribute(LookinAttr_UIWindowScene_StatusBar_StatusBarHidden, AttributeInfo(className: "UIWindowScene", fullTitle: "StatusBarHidden", getterString: "lks_statusBarHidden", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_UIWindowScene_StatusBar_StatusBarStyle, AttributeInfo(className: "UIWindowScene", fullTitle: "StatusBarStyle", getterString: "lks_statusBarStyle", setterString: "", enumList: "UIStatusBarStyle", patch: false)),
                BlueprintAttribute(LookinAttr_UIWindowScene_StatusBar_StatusBarFrame, AttributeInfo(className: "UIWindowScene", fullTitle: "StatusBarFrame", getterString: "lks_statusBarFrame", setterString: "", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_UIWindowScene_SizeRestrictions, title: "SizeRestrictions", attributes: [
                // UISceneSizeRestrictions — nil on iPhone, so the whole section drops out there.
                BlueprintAttribute(LookinAttr_UIWindowScene_SizeRestrictions_MinimumSize, AttributeInfo(className: "UIWindowScene", fullTitle: "MinimumSize", getterString: "lks_sizeRestrictionsMinimumSize", setterString: "", typeIfObj: .cgSize, patch: false, hideIfNil: true)),
                BlueprintAttribute(LookinAttr_UIWindowScene_SizeRestrictions_MaximumSize, AttributeInfo(className: "UIWindowScene", fullTitle: "MaximumSize", getterString: "lks_sizeRestrictionsMaximumSize", setterString: "", typeIfObj: .cgSize, patch: false, hideIfNil: true)),
                BlueprintAttribute(LookinAttr_UIWindowScene_SizeRestrictions_AllowsFullScreen, AttributeInfo(className: "UIWindowScene", fullTitle: "AllowsFullScreen", getterString: "lks_sizeRestrictionsAllowsFullScreen", setterString: "", typeIfObj: .BOOL, patch: false, hideIfNil: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIWindowScene_WindowingBehaviors, title: "WindowingBehaviors", attributes: [
                // UISceneWindowingBehaviors — nil outside iPad multitasking and Catalyst.
                BlueprintAttribute(LookinAttr_UIWindowScene_WindowingBehaviors_Closable, AttributeInfo(className: "UIWindowScene", fullTitle: "Closable", getterString: "lks_windowingBehaviorsClosable", setterString: "", typeIfObj: .BOOL, patch: false, hideIfNil: true, osVersion: 16)),
                BlueprintAttribute(LookinAttr_UIWindowScene_WindowingBehaviors_Miniaturizable, AttributeInfo(className: "UIWindowScene", fullTitle: "Miniaturizable", getterString: "lks_windowingBehaviorsMiniaturizable", setterString: "", typeIfObj: .BOOL, patch: false, hideIfNil: true, osVersion: 16)),
                BlueprintAttribute(LookinAttr_UIWindowScene_WindowingBehaviors_FullScreen, AttributeInfo(className: "UIWindowScene", fullTitle: "FullScreen", getterString: "lks_fullScreen", setterString: "", typeIfObj: .BOOL, patch: false, hideIfNil: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIWindowScene_Pointer, title: "Pointer", attributes: [
                BlueprintAttribute(LookinAttr_UIWindowScene_Pointer_Locked, AttributeInfo(className: "UIWindowScene", fullTitle: "Locked", getterString: "lks_pointerLocked", setterString: "", typeIfObj: .BOOL, patch: false, hideIfNil: true, osVersion: 14)),
            ]),
            BlueprintSection(LookinAttrSec_UIWindowScene_Protection, title: "Protection", attributes: [
                BlueprintAttribute(LookinAttr_UIWindowScene_Protection_UserAuthenticationEnabled, AttributeInfo(className: "UIWindowScene", fullTitle: "UserAuthenticationEnabled", getterString: "lks_systemProtectionUserAuthenticationEnabled", setterString: "", typeIfObj: .BOOL, patch: false, hideIfNil: true, osVersion: 18)),
            ]),
            BlueprintSection(LookinAttrSec_UIWindowScene_Traits, title: "Traits", attributes: [
                BlueprintAttribute(LookinAttr_UIWindowScene_Traits_UserInterfaceStyle, AttributeInfo(className: "UIWindowScene", fullTitle: "UserInterfaceStyle", getterString: "lks_userInterfaceStyle", setterString: "", enumList: "UIUserInterfaceStyle", patch: false)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Traits_HorizontalSizeClass, AttributeInfo(className: "UIWindowScene", fullTitle: "HorizontalSizeClass", getterString: "lks_horizontalSizeClass", setterString: "", enumList: "UIUserInterfaceSizeClass", patch: false)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Traits_VerticalSizeClass, AttributeInfo(className: "UIWindowScene", fullTitle: "VerticalSizeClass", getterString: "lks_verticalSizeClass", setterString: "", enumList: "UIUserInterfaceSizeClass", patch: false)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Traits_UserInterfaceLevel, AttributeInfo(className: "UIWindowScene", fullTitle: "UserInterfaceLevel", getterString: "lks_userInterfaceLevel", setterString: "", enumList: "UIUserInterfaceLevel", patch: false, osVersion: 13)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Traits_ActiveAppearance, AttributeInfo(className: "UIWindowScene", fullTitle: "ActiveAppearance", getterString: "lks_activeAppearance", setterString: "", enumList: "UIUserInterfaceActiveAppearance", patch: false, osVersion: 14)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Traits_AccessibilityContrast, AttributeInfo(className: "UIWindowScene", fullTitle: "AccessibilityContrast", getterString: "lks_accessibilityContrast", setterString: "", enumList: "UIAccessibilityContrast", patch: false, osVersion: 13)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Traits_LegibilityWeight, AttributeInfo(className: "UIWindowScene", fullTitle: "LegibilityWeight", getterString: "lks_legibilityWeight", setterString: "", enumList: "UILegibilityWeight", patch: false, osVersion: 13)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Traits_DisplayScale, AttributeInfo(className: "UIWindowScene", fullTitle: "DisplayScale", getterString: "lks_traitDisplayScale", setterString: "", patch: false, osVersion: 13)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Traits_DisplayGamut, AttributeInfo(className: "UIWindowScene", fullTitle: "DisplayGamut", getterString: "lks_displayGamut", setterString: "", enumList: "UIDisplayGamut", patch: false, osVersion: 13)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Traits_UserInterfaceIdiom, AttributeInfo(className: "UIWindowScene", fullTitle: "UserInterfaceIdiom", getterString: "lks_userInterfaceIdiom", setterString: "", enumList: "UIUserInterfaceIdiom", patch: false, osVersion: 13)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Traits_LayoutDirection, AttributeInfo(className: "UIWindowScene", fullTitle: "LayoutDirection", getterString: "lks_layoutDirection", setterString: "", enumList: "UITraitEnvironmentLayoutDirection", patch: false, osVersion: 13)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Traits_PreferredContentSizeCategory, AttributeInfo(className: "UIWindowScene", fullTitle: "PreferredContentSizeCategory", getterString: "lks_preferredContentSizeCategory", setterString: "", typeIfObj: .nsString, patch: false, osVersion: 13)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Traits_SceneCaptureState, AttributeInfo(className: "UIWindowScene", fullTitle: "SceneCaptureState", getterString: "lks_sceneCaptureState", setterString: "", enumList: "UISceneCaptureState", patch: false, osVersion: 17)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Traits_ImageDynamicRange, AttributeInfo(className: "UIWindowScene", fullTitle: "ImageDynamicRange", getterString: "lks_imageDynamicRange", setterString: "", enumList: "UIImageDynamicRange", patch: false, osVersion: 17)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Traits_TypesettingLanguage, AttributeInfo(className: "UIWindowScene", fullTitle: "TypesettingLanguage", getterString: "lks_typesettingLanguage", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true, osVersion: 17)),
            ]),
            BlueprintSection(LookinAttrSec_UIWindowScene_Session, title: "Session", attributes: [
                BlueprintAttribute(LookinAttr_UIWindowScene_Session_PersistentIdentifier, AttributeInfo(className: "UIWindowScene", fullTitle: "PersistentIdentifier", getterString: "lks_sessionPersistentIdentifier", setterString: "", typeIfObj: .nsString, patch: false)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Session_SessionRole, AttributeInfo(className: "UIWindowScene", fullTitle: "SessionRole", getterString: "lks_sessionRole", setterString: "", typeIfObj: .nsString, patch: false)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Session_StateRestorationActivityType, AttributeInfo(className: "UIWindowScene", fullTitle: "StateRestorationActivity", getterString: "lks_sessionStateRestorationActivityType", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Session_UserInfo, AttributeInfo(className: "UIWindowScene", fullTitle: "UserInfo", getterString: "lks_sessionUserInfoJSONString", setterString: "", typeIfObj: .json, patch: false, hideIfNil: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIWindowScene_Configuration, title: "Configuration", attributes: [
                // UISceneConfiguration — describes which classes and storyboard back
                // this scene. DelegateClass is the class declared in the configuration,
                // which is not necessarily the class of the delegate instance shown in
                // the Relation group; a mismatch between the two is worth noticing.
                BlueprintAttribute(LookinAttr_UIWindowScene_Configuration_Name, AttributeInfo(className: "UIWindowScene", fullTitle: "Name", getterString: "lks_configurationName", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Configuration_SceneClass, AttributeInfo(className: "UIWindowScene", fullTitle: "SceneClass", getterString: "lks_configurationSceneClassName", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Configuration_DelegateClass, AttributeInfo(className: "UIWindowScene", fullTitle: "DelegateClass", getterString: "lks_configurationDelegateClassName", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true)),
                BlueprintAttribute(LookinAttr_UIWindowScene_Configuration_Storyboard, AttributeInfo(className: "UIWindowScene", fullTitle: "Storyboard", getterString: "lks_configurationStoryboardDescription", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIWindowScene_ActivationConditions, title: "ActivationConditions", attributes: [
                // UISceneActivationConditions — shown as the predicates' format strings.
                BlueprintAttribute(LookinAttr_UIWindowScene_ActivationConditions_CanActivate, AttributeInfo(className: "UIWindowScene", fullTitle: "CanActivateForTargetContentIdentifier", briefTitle: "CanActivate", getterString: "lks_canActivateForTargetContentIdentifierPredicateFormat", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true)),
                BlueprintAttribute(LookinAttr_UIWindowScene_ActivationConditions_PrefersToActivate, AttributeInfo(className: "UIWindowScene", fullTitle: "PrefersToActivateForTargetContentIdentifier", briefTitle: "PrefersToActivate", getterString: "lks_prefersToActivateForTargetContentIdentifierPredicateFormat", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true)),
            ]),
        ])

        static let uiTraitCollectionGroup = BlueprintGroup(LookinAttrGroup_UITraitCollection, title: "UITraitCollection", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UITraitCollection_Appearance, title: "Appearance", attributes: [
                BlueprintAttribute(LookinAttr_UITraitCollection_Appearance_UserInterfaceStyle, AttributeInfo(className: "UIView", fullTitle: "UserInterfaceStyle", getterString: "lks_traitCollection_userInterfaceStyle", setterString: "", enumList: "UIUserInterfaceStyle", patch: false, osVersion: 12)),
                BlueprintAttribute(LookinAttr_UITraitCollection_Appearance_UserInterfaceLevel, AttributeInfo(className: "UIView", fullTitle: "UserInterfaceLevel", getterString: "lks_traitCollection_userInterfaceLevel", setterString: "", enumList: "UIUserInterfaceLevel", patch: false, osVersion: 13)),
                BlueprintAttribute(LookinAttr_UITraitCollection_Appearance_ActiveAppearance, AttributeInfo(className: "UIView", fullTitle: "ActiveAppearance", getterString: "lks_traitCollection_activeAppearance", setterString: "", enumList: "UIUserInterfaceActiveAppearance", patch: false, osVersion: 14)),
                BlueprintAttribute(LookinAttr_UITraitCollection_Appearance_AccessibilityContrast, AttributeInfo(className: "UIView", fullTitle: "AccessibilityContrast", getterString: "lks_traitCollection_accessibilityContrast", setterString: "", enumList: "UIAccessibilityContrast", patch: false, osVersion: 13)),
                BlueprintAttribute(LookinAttr_UITraitCollection_Appearance_LegibilityWeight, AttributeInfo(className: "UIView", fullTitle: "LegibilityWeight", getterString: "lks_traitCollection_legibilityWeight", setterString: "", enumList: "UILegibilityWeight", patch: false, osVersion: 13)),
            ]),
            BlueprintSection(LookinAttrSec_UITraitCollection_SizeClass, title: "SizeClass", attributes: [
                BlueprintAttribute(LookinAttr_UITraitCollection_SizeClass_HorizontalSizeClass, AttributeInfo(className: "UIView", fullTitle: "HorizontalSizeClass", getterString: "lks_traitCollection_horizontalSizeClass", setterString: "", enumList: "UIUserInterfaceSizeClass", patch: false)),
                BlueprintAttribute(LookinAttr_UITraitCollection_SizeClass_VerticalSizeClass, AttributeInfo(className: "UIView", fullTitle: "VerticalSizeClass", getterString: "lks_traitCollection_verticalSizeClass", setterString: "", enumList: "UIUserInterfaceSizeClass", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_UITraitCollection_Display, title: "Display", attributes: [
                BlueprintAttribute(LookinAttr_UITraitCollection_Display_DisplayScale, AttributeInfo(className: "UIView", fullTitle: "DisplayScale", getterString: "lks_traitCollection_displayScale", setterString: "", patch: false)),
                BlueprintAttribute(LookinAttr_UITraitCollection_Display_DisplayGamut, AttributeInfo(className: "UIView", fullTitle: "DisplayGamut", getterString: "lks_traitCollection_displayGamut", setterString: "", enumList: "UIDisplayGamut", patch: false, osVersion: 10)),
                BlueprintAttribute(LookinAttr_UITraitCollection_Display_ImageDynamicRange, AttributeInfo(className: "UIView", fullTitle: "ImageDynamicRange", getterString: "lks_traitCollection_imageDynamicRange", setterString: "", enumList: "UIImageDynamicRange", patch: false, osVersion: 17)),
            ]),
            BlueprintSection(LookinAttrSec_UITraitCollection_Device, title: "Device", attributes: [
                BlueprintAttribute(LookinAttr_UITraitCollection_Device_UserInterfaceIdiom, AttributeInfo(className: "UIView", fullTitle: "UserInterfaceIdiom", getterString: "lks_traitCollection_userInterfaceIdiom", setterString: "", enumList: "UIUserInterfaceIdiom", patch: false)),
                BlueprintAttribute(LookinAttr_UITraitCollection_Device_ForceTouchCapability, AttributeInfo(className: "UIView", fullTitle: "ForceTouchCapability", getterString: "lks_traitCollection_forceTouchCapability", setterString: "", enumList: "UIForceTouchCapability", patch: false, osVersion: 9)),
            ]),
            BlueprintSection(LookinAttrSec_UITraitCollection_Layout, title: "Layout", attributes: [
                BlueprintAttribute(LookinAttr_UITraitCollection_Layout_LayoutDirection, AttributeInfo(className: "UIView", fullTitle: "LayoutDirection", getterString: "lks_traitCollection_layoutDirection", setterString: "", enumList: "UITraitEnvironmentLayoutDirection", patch: false, osVersion: 10)),
            ]),
            BlueprintSection(LookinAttrSec_UITraitCollection_Content, title: "Content", attributes: [
                BlueprintAttribute(LookinAttr_UITraitCollection_Content_PreferredContentSizeCategory, AttributeInfo(className: "UIView", fullTitle: "PreferredContentSizeCategory", getterString: "lks_traitCollection_preferredContentSizeCategory", setterString: "", typeIfObj: .nsString, patch: false, osVersion: 10)),
                BlueprintAttribute(LookinAttr_UITraitCollection_Content_TypesettingLanguage, AttributeInfo(className: "UIView", fullTitle: "TypesettingLanguage", getterString: "lks_traitCollection_typesettingLanguage", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true, osVersion: 17)),
            ]),
        ])

        static let uiSliderGroup = BlueprintGroup(LookinAttrGroup_UISlider, title: "UISlider", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UISlider_BehavioralStyle, title: "BehavioralStyle", attributes: [
                BlueprintAttribute(LookinAttr_UISlider_BehavioralStyle_BehavioralStyle, AttributeInfo(className: "UISlider", fullTitle: "BehavioralStyle", getterString: "behavioralStyle", setterString: "", enumList: "UIBehavioralStyle", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISlider_PreferredBehavioralStyle, title: "PreferredBehavioralStyle", attributes: [
                BlueprintAttribute(LookinAttr_UISlider_PreferredBehavioralStyle_PreferredBehavioralStyle, AttributeInfo(className: "UISlider", fullTitle: "PreferredBehavioralStyle", getterString: "preferredBehavioralStyle", setterString: "setPreferredBehavioralStyle:", enumList: "UIBehavioralStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISlider_Value, title: "Value", attributes: [
                BlueprintAttribute(LookinAttr_UISlider_Value_Value, AttributeInfo(className: "UISlider", fullTitle: "Value", getterString: "value", setterString: "setValue:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UISlider_Value_MinimumValue, AttributeInfo(className: "UISlider", fullTitle: "MinimumValue", getterString: "minimumValue", setterString: "setMinimumValue:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UISlider_Value_MaximumValue, AttributeInfo(className: "UISlider", fullTitle: "MaximumValue", getterString: "maximumValue", setterString: "setMaximumValue:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISlider_Images, title: "Images", attributes: [
                BlueprintAttribute(LookinAttr_UISlider_Images_MinimumValueImage, AttributeInfo(className: "UISlider", fullTitle: "MinimumValueImage", getterString: "minimumValueImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_UISlider_Images_MaximumValueImage, AttributeInfo(className: "UISlider", fullTitle: "MaximumValueImage", getterString: "maximumValueImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_UISlider_Images_CurrentThumbImage, AttributeInfo(className: "UISlider", fullTitle: "CurrentThumbImage", getterString: "currentThumbImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_UISlider_Images_CurrentMinimumTrackImage, AttributeInfo(className: "UISlider", fullTitle: "CurrentMinimumTrackImage", getterString: "currentMinimumTrackImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_UISlider_Images_CurrentMaximumTrackImage, AttributeInfo(className: "UISlider", fullTitle: "CurrentMaximumTrackImage", getterString: "currentMaximumTrackImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(LookinAttrSec_UISlider_Continuous, title: "Continuous", attributes: [
                BlueprintAttribute(LookinAttr_UISlider_Continuous_Continuous, AttributeInfo(className: "UISlider", fullTitle: "Continuous", getterString: "isContinuous", setterString: "setContinuous:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISlider_SliderStyle, title: "SliderStyle", attributes: [
                BlueprintAttribute(LookinAttr_UISlider_SliderStyle_SliderStyle, AttributeInfo(className: "UISlider", fullTitle: "SliderStyle", getterString: "sliderStyle", setterString: "setSliderStyle:", enumList: "UISliderStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISlider_Colors, title: "Colors", attributes: [
                BlueprintAttribute(LookinAttr_UISlider_Colors_MinimumTrackTintColor, AttributeInfo(className: "UISlider", fullTitle: "MinimumTrackTintColor", getterString: "minimumTrackTintColor", setterString: "setMinimumTrackTintColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UISlider_Colors_MaximumTrackTintColor, AttributeInfo(className: "UISlider", fullTitle: "MaximumTrackTintColor", getterString: "maximumTrackTintColor", setterString: "setMaximumTrackTintColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UISlider_Colors_ThumbTintColor, AttributeInfo(className: "UISlider", fullTitle: "ThumbTintColor", getterString: "thumbTintColor", setterString: "setThumbTintColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
        ])


        static let uiStepperGroup = BlueprintGroup(LookinAttrGroup_UIStepper, title: "UIStepper", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIStepper_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UIStepper_Behavior_Continuous, AttributeInfo(className: "UIStepper", fullTitle: "Continuous", getterString: "isContinuous", setterString: "setContinuous:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIStepper_Behavior_Autorepeat, AttributeInfo(className: "UIStepper", fullTitle: "Autorepeat", getterString: "autorepeat", setterString: "setAutorepeat:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIStepper_Behavior_Wraps, AttributeInfo(className: "UIStepper", fullTitle: "Wraps", getterString: "wraps", setterString: "setWraps:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIStepper_Value, title: "Value", attributes: [
                BlueprintAttribute(LookinAttr_UIStepper_Value_Value, AttributeInfo(className: "UIStepper", fullTitle: "Value", getterString: "value", setterString: "setValue:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIStepper_Value_MinimumValue, AttributeInfo(className: "UIStepper", fullTitle: "MinimumValue", getterString: "minimumValue", setterString: "setMinimumValue:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIStepper_Value_MaximumValue, AttributeInfo(className: "UIStepper", fullTitle: "MaximumValue", getterString: "maximumValue", setterString: "setMaximumValue:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIStepper_Value_StepValue, AttributeInfo(className: "UIStepper", fullTitle: "StepValue", getterString: "stepValue", setterString: "setStepValue:", patch: true, revision: 1)),
            ]),
        ])


        static let uiSwitchGroup = BlueprintGroup(LookinAttrGroup_UISwitch, title: "UISwitch", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UISwitch_Colors, title: "Colors", attributes: [
                BlueprintAttribute(LookinAttr_UISwitch_Colors_OnTintColor, AttributeInfo(className: "UISwitch", fullTitle: "OnTintColor", getterString: "onTintColor", setterString: "setOnTintColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UISwitch_Colors_ThumbTintColor, AttributeInfo(className: "UISwitch", fullTitle: "ThumbTintColor", getterString: "thumbTintColor", setterString: "setThumbTintColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISwitch_Images, title: "Images", attributes: [
                BlueprintAttribute(LookinAttr_UISwitch_Images_OnImage, AttributeInfo(className: "UISwitch", fullTitle: "OnImage", getterString: "onImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_UISwitch_Images_OffImage, AttributeInfo(className: "UISwitch", fullTitle: "OffImage", getterString: "offImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(LookinAttrSec_UISwitch_Title, title: "Title", attributes: [
                BlueprintAttribute(LookinAttr_UISwitch_Title_Title, AttributeInfo(className: "UISwitch", fullTitle: "Title", getterString: "title", setterString: "setTitle:", typeIfObj: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISwitch_Style, title: "Style", attributes: [
                BlueprintAttribute(LookinAttr_UISwitch_Style_Style, AttributeInfo(className: "UISwitch", fullTitle: "Style", getterString: "style", setterString: "", enumList: "UISwitchStyle", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISwitch_PreferredStyle, title: "PreferredStyle", attributes: [
                BlueprintAttribute(LookinAttr_UISwitch_PreferredStyle_PreferredStyle, AttributeInfo(className: "UISwitch", fullTitle: "PreferredStyle", getterString: "preferredStyle", setterString: "setPreferredStyle:", enumList: "UISwitchStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISwitch_On, title: "On", attributes: [
                BlueprintAttribute(LookinAttr_UISwitch_On_On, AttributeInfo(className: "UISwitch", fullTitle: "On", getterString: "isOn", setterString: "setOn:", patch: true, revision: 1)),
            ]),
        ])


        static let uiSegmentedControlGroup = BlueprintGroup(LookinAttrGroup_UISegmentedControl, title: "UISegmentedControl", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UISegmentedControl_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UISegmentedControl_Behavior_Momentary, AttributeInfo(className: "UISegmentedControl", fullTitle: "Momentary", getterString: "isMomentary", setterString: "setMomentary:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UISegmentedControl_Behavior_ApportionsSegmentWidthsByContent, AttributeInfo(className: "UISegmentedControl", fullTitle: "ApportionsSegmentWidthsByContent", getterString: "apportionsSegmentWidthsByContent", setterString: "setApportionsSegmentWidthsByContent:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISegmentedControl_NumberOfSegments, title: "NumberOfSegments", attributes: [
                BlueprintAttribute(LookinAttr_UISegmentedControl_NumberOfSegments_NumberOfSegments, AttributeInfo(className: "UISegmentedControl", fullTitle: "NumberOfSegments", getterString: "numberOfSegments", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISegmentedControl_SelectedSegmentIndex, title: "SelectedSegmentIndex", attributes: [
                BlueprintAttribute(LookinAttr_UISegmentedControl_SelectedSegmentIndex_SelectedSegmentIndex, AttributeInfo(className: "UISegmentedControl", fullTitle: "SelectedSegmentIndex", getterString: "selectedSegmentIndex", setterString: "setSelectedSegmentIndex:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISegmentedControl_SelectedSegmentTintColor, title: "SelectedSegmentTintColor", attributes: [
                BlueprintAttribute(LookinAttr_UISegmentedControl_SelectedSegmentTintColor_SelectedSegmentTintColor, AttributeInfo(className: "UISegmentedControl", fullTitle: "SelectedSegmentTintColor", getterString: "selectedSegmentTintColor", setterString: "setSelectedSegmentTintColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
        ])


        static let uiProgressViewGroup = BlueprintGroup(LookinAttrGroup_UIProgressView, title: "UIProgressView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIProgressView_ProgressViewStyle, title: "ProgressViewStyle", attributes: [
                BlueprintAttribute(LookinAttr_UIProgressView_ProgressViewStyle_ProgressViewStyle, AttributeInfo(className: "UIProgressView", fullTitle: "ProgressViewStyle", getterString: "progressViewStyle", setterString: "setProgressViewStyle:", enumList: "UIProgressViewStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIProgressView_Progress, title: "Progress", attributes: [
                BlueprintAttribute(LookinAttr_UIProgressView_Progress_Progress, AttributeInfo(className: "UIProgressView", fullTitle: "Progress", getterString: "progress", setterString: "setProgress:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIProgressView_Colors, title: "Colors", attributes: [
                BlueprintAttribute(LookinAttr_UIProgressView_Colors_ProgressTintColor, AttributeInfo(className: "UIProgressView", fullTitle: "ProgressTintColor", getterString: "progressTintColor", setterString: "setProgressTintColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIProgressView_Colors_TrackTintColor, AttributeInfo(className: "UIProgressView", fullTitle: "TrackTintColor", getterString: "trackTintColor", setterString: "setTrackTintColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIProgressView_Images, title: "Images", attributes: [
                BlueprintAttribute(LookinAttr_UIProgressView_Images_ProgressImage, AttributeInfo(className: "UIProgressView", fullTitle: "ProgressImage", getterString: "progressImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_UIProgressView_Images_TrackImage, AttributeInfo(className: "UIProgressView", fullTitle: "TrackImage", getterString: "trackImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
        ])


        static let uiActivityIndicatorViewGroup = BlueprintGroup(LookinAttrGroup_UIActivityIndicatorView, title: "UIActivityIndicatorView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIActivityIndicatorView_ActivityIndicatorViewStyle, title: "ActivityIndicatorViewStyle", attributes: [
                BlueprintAttribute(LookinAttr_UIActivityIndicatorView_ActivityIndicatorViewStyle_ActivityIndicatorViewStyle, AttributeInfo(className: "UIActivityIndicatorView", fullTitle: "ActivityIndicatorViewStyle", getterString: "activityIndicatorViewStyle", setterString: "setActivityIndicatorViewStyle:", enumList: "UIActivityIndicatorViewStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIActivityIndicatorView_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UIActivityIndicatorView_Behavior_HidesWhenStopped, AttributeInfo(className: "UIActivityIndicatorView", fullTitle: "HidesWhenStopped", getterString: "hidesWhenStopped", setterString: "setHidesWhenStopped:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIActivityIndicatorView_Behavior_Animating, AttributeInfo(className: "UIActivityIndicatorView", fullTitle: "Animating", getterString: "isAnimating", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIActivityIndicatorView_Color, title: "Color", attributes: [
                BlueprintAttribute(LookinAttr_UIActivityIndicatorView_Color_Color, AttributeInfo(className: "UIActivityIndicatorView", fullTitle: "Color", getterString: "color", setterString: "setColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
        ])


        static let uiPageControlGroup = BlueprintGroup(LookinAttrGroup_UIPageControl, title: "UIPageControl", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIPageControl_NumberOfPages, title: "NumberOfPages", attributes: [
                BlueprintAttribute(LookinAttr_UIPageControl_NumberOfPages_NumberOfPages, AttributeInfo(className: "UIPageControl", fullTitle: "NumberOfPages", getterString: "numberOfPages", setterString: "setNumberOfPages:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIPageControl_CurrentPage, title: "CurrentPage", attributes: [
                BlueprintAttribute(LookinAttr_UIPageControl_CurrentPage_CurrentPage, AttributeInfo(className: "UIPageControl", fullTitle: "CurrentPage", getterString: "currentPage", setterString: "setCurrentPage:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIPageControl_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UIPageControl_Behavior_HidesForSinglePage, AttributeInfo(className: "UIPageControl", fullTitle: "HidesForSinglePage", getterString: "hidesForSinglePage", setterString: "setHidesForSinglePage:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIPageControl_Behavior_AllowsContinuousInteraction, AttributeInfo(className: "UIPageControl", fullTitle: "AllowsContinuousInteraction", getterString: "allowsContinuousInteraction", setterString: "setAllowsContinuousInteraction:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIPageControl_Colors, title: "Colors", attributes: [
                BlueprintAttribute(LookinAttr_UIPageControl_Colors_PageIndicatorTintColor, AttributeInfo(className: "UIPageControl", fullTitle: "PageIndicatorTintColor", getterString: "pageIndicatorTintColor", setterString: "setPageIndicatorTintColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIPageControl_Colors_CurrentPageIndicatorTintColor, AttributeInfo(className: "UIPageControl", fullTitle: "CurrentPageIndicatorTintColor", getterString: "currentPageIndicatorTintColor", setterString: "setCurrentPageIndicatorTintColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIPageControl_BackgroundStyle, title: "BackgroundStyle", attributes: [
                BlueprintAttribute(LookinAttr_UIPageControl_BackgroundStyle_BackgroundStyle, AttributeInfo(className: "UIPageControl", fullTitle: "BackgroundStyle", getterString: "backgroundStyle", setterString: "setBackgroundStyle:", enumList: "UIPageControlBackgroundStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIPageControl_Direction, title: "Direction", attributes: [
                BlueprintAttribute(LookinAttr_UIPageControl_Direction_Direction, AttributeInfo(className: "UIPageControl", fullTitle: "Direction", getterString: "direction", setterString: "setDirection:", enumList: "UIPageControlDirection", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIPageControl_InteractionState, title: "InteractionState", attributes: [
                BlueprintAttribute(LookinAttr_UIPageControl_InteractionState_InteractionState, AttributeInfo(className: "UIPageControl", fullTitle: "InteractionState", getterString: "interactionState", setterString: "", enumList: "UIPageControlInteractionState", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIPageControl_Images, title: "Images", attributes: [
                BlueprintAttribute(LookinAttr_UIPageControl_Images_PreferredIndicatorImage, AttributeInfo(className: "UIPageControl", fullTitle: "PreferredIndicatorImage", getterString: "preferredIndicatorImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_UIPageControl_Images_PreferredCurrentPageIndicatorImage, AttributeInfo(className: "UIPageControl", fullTitle: "PreferredCurrentPageIndicatorImage", getterString: "preferredCurrentPageIndicatorImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
        ])


        static let uiDatePickerGroup = BlueprintGroup(LookinAttrGroup_UIDatePicker, title: "UIDatePicker", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIDatePicker_DatePickerMode, title: "DatePickerMode", attributes: [
                BlueprintAttribute(LookinAttr_UIDatePicker_DatePickerMode_DatePickerMode, AttributeInfo(className: "UIDatePicker", fullTitle: "DatePickerMode", getterString: "datePickerMode", setterString: "setDatePickerMode:", enumList: "UIDatePickerMode", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIDatePicker_Locale, title: "Locale", attributes: [
                BlueprintAttribute(LookinAttr_UIDatePicker_Locale_Locale, AttributeInfo(className: "UIDatePicker", fullTitle: "Locale", getterString: "locale", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.locale))),
            ]),
            BlueprintSection(LookinAttrSec_UIDatePicker_Calendar, title: "Calendar", attributes: [
                BlueprintAttribute(LookinAttr_UIDatePicker_Calendar_Calendar, AttributeInfo(className: "UIDatePicker", fullTitle: "Calendar", getterString: "calendar", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.calendar))),
            ]),
            BlueprintSection(LookinAttrSec_UIDatePicker_TimeZone, title: "TimeZone", attributes: [
                BlueprintAttribute(LookinAttr_UIDatePicker_TimeZone_TimeZone, AttributeInfo(className: "UIDatePicker", fullTitle: "TimeZone", getterString: "timeZone", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.timeZone))),
            ]),
            BlueprintSection(LookinAttrSec_UIDatePicker_Date, title: "Date", attributes: [
                BlueprintAttribute(LookinAttr_UIDatePicker_Date_Date, AttributeInfo(className: "UIDatePicker", fullTitle: "Date", getterString: "date", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.date))),
            ]),
            BlueprintSection(LookinAttrSec_UIDatePicker_MinimumDate, title: "MinimumDate", attributes: [
                BlueprintAttribute(LookinAttr_UIDatePicker_MinimumDate_MinimumDate, AttributeInfo(className: "UIDatePicker", fullTitle: "MinimumDate", getterString: "minimumDate", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.date))),
            ]),
            BlueprintSection(LookinAttrSec_UIDatePicker_MaximumDate, title: "MaximumDate", attributes: [
                BlueprintAttribute(LookinAttr_UIDatePicker_MaximumDate_MaximumDate, AttributeInfo(className: "UIDatePicker", fullTitle: "MaximumDate", getterString: "maximumDate", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.date))),
            ]),
            BlueprintSection(LookinAttrSec_UIDatePicker_CountDownDuration, title: "CountDownDuration", attributes: [
                BlueprintAttribute(LookinAttr_UIDatePicker_CountDownDuration_CountDownDuration, AttributeInfo(className: "UIDatePicker", fullTitle: "CountDownDuration", getterString: "countDownDuration", setterString: "setCountDownDuration:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIDatePicker_MinuteInterval, title: "MinuteInterval", attributes: [
                BlueprintAttribute(LookinAttr_UIDatePicker_MinuteInterval_MinuteInterval, AttributeInfo(className: "UIDatePicker", fullTitle: "MinuteInterval", getterString: "minuteInterval", setterString: "setMinuteInterval:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIDatePicker_PreferredDatePickerStyle, title: "PreferredDatePickerStyle", attributes: [
                BlueprintAttribute(LookinAttr_UIDatePicker_PreferredDatePickerStyle_PreferredDatePickerStyle, AttributeInfo(className: "UIDatePicker", fullTitle: "PreferredDatePickerStyle", getterString: "preferredDatePickerStyle", setterString: "setPreferredDatePickerStyle:", enumList: "UIDatePickerStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIDatePicker_DatePickerStyle, title: "DatePickerStyle", attributes: [
                BlueprintAttribute(LookinAttr_UIDatePicker_DatePickerStyle_DatePickerStyle, AttributeInfo(className: "UIDatePicker", fullTitle: "DatePickerStyle", getterString: "datePickerStyle", setterString: "", enumList: "UIDatePickerStyle", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIDatePicker_RoundsToMinuteInterval, title: "RoundsToMinuteInterval", attributes: [
                BlueprintAttribute(LookinAttr_UIDatePicker_RoundsToMinuteInterval_RoundsToMinuteInterval, AttributeInfo(className: "UIDatePicker", fullTitle: "RoundsToMinuteInterval", getterString: "roundsToMinuteInterval", setterString: "setRoundsToMinuteInterval:", patch: true, revision: 1)),
            ]),
        ])


        static let uiColorWellGroup = BlueprintGroup(LookinAttrGroup_UIColorWell, title: "UIColorWell", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIColorWell_Title, title: "Title", attributes: [
                BlueprintAttribute(LookinAttr_UIColorWell_Title_Title, AttributeInfo(className: "UIColorWell", fullTitle: "Title", getterString: "title", setterString: "setTitle:", typeIfObj: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIColorWell_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UIColorWell_Behavior_SupportsAlpha, AttributeInfo(className: "UIColorWell", fullTitle: "SupportsAlpha", getterString: "supportsAlpha", setterString: "setSupportsAlpha:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIColorWell_Behavior_SupportsEyedropper, AttributeInfo(className: "UIColorWell", fullTitle: "SupportsEyedropper", getterString: "supportsEyedropper", setterString: "setSupportsEyedropper:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIColorWell_SelectedColor, title: "SelectedColor", attributes: [
                BlueprintAttribute(LookinAttr_UIColorWell_SelectedColor_SelectedColor, AttributeInfo(className: "UIColorWell", fullTitle: "SelectedColor", getterString: "selectedColor", setterString: "setSelectedColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIColorWell_MaximumLinearExposure, title: "MaximumLinearExposure", attributes: [
                BlueprintAttribute(LookinAttr_UIColorWell_MaximumLinearExposure_MaximumLinearExposure, AttributeInfo(className: "UIColorWell", fullTitle: "MaximumLinearExposure", getterString: "maximumLinearExposure", setterString: "setMaximumLinearExposure:", patch: true, revision: 1)),
            ]),
        ])


        static let uiRefreshControlGroup = BlueprintGroup(LookinAttrGroup_UIRefreshControl, title: "UIRefreshControl", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIRefreshControl_Refreshing, title: "Refreshing", attributes: [
                BlueprintAttribute(LookinAttr_UIRefreshControl_Refreshing_Refreshing, AttributeInfo(className: "UIRefreshControl", fullTitle: "Refreshing", getterString: "isRefreshing", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIRefreshControl_AttributedTitle, title: "AttributedTitle", attributes: [
                BlueprintAttribute(LookinAttr_UIRefreshControl_AttributedTitle_AttributedTitle, AttributeInfo(className: "UIRefreshControl", fullTitle: "AttributedTitle", getterString: "attributedTitle", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.attributedString))),
            ]),
        ])


        static let uiPickerViewGroup = BlueprintGroup(LookinAttrGroup_UIPickerView, title: "UIPickerView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIPickerView_NumberOfComponents, title: "NumberOfComponents", attributes: [
                BlueprintAttribute(LookinAttr_UIPickerView_NumberOfComponents_NumberOfComponents, AttributeInfo(className: "UIPickerView", fullTitle: "NumberOfComponents", getterString: "numberOfComponents", setterString: "", revision: 1)),
            ]),
        ])


        static let uiCalendarViewGroup = BlueprintGroup(LookinAttrGroup_UICalendarView, title: "UICalendarView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UICalendarView_Locale, title: "Locale", attributes: [
                BlueprintAttribute(LookinAttr_UICalendarView_Locale_Locale, AttributeInfo(className: "UICalendarView", fullTitle: "Locale", getterString: "locale", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.locale))),
            ]),
            BlueprintSection(LookinAttrSec_UICalendarView_Calendar, title: "Calendar", attributes: [
                BlueprintAttribute(LookinAttr_UICalendarView_Calendar_Calendar, AttributeInfo(className: "UICalendarView", fullTitle: "Calendar", getterString: "calendar", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.calendar))),
            ]),
            BlueprintSection(LookinAttrSec_UICalendarView_TimeZone, title: "TimeZone", attributes: [
                BlueprintAttribute(LookinAttr_UICalendarView_TimeZone_TimeZone, AttributeInfo(className: "UICalendarView", fullTitle: "TimeZone", getterString: "timeZone", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.timeZone))),
            ]),
            BlueprintSection(LookinAttrSec_UICalendarView_FontDesign, title: "FontDesign", attributes: [
                BlueprintAttribute(LookinAttr_UICalendarView_FontDesign_FontDesign, AttributeInfo(className: "UICalendarView", fullTitle: "FontDesign", getterString: "fontDesign", setterString: "", typeIfObj: .nsString, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UICalendarView_WantsDateDecorations, title: "WantsDateDecorations", attributes: [
                BlueprintAttribute(LookinAttr_UICalendarView_WantsDateDecorations_WantsDateDecorations, AttributeInfo(className: "UICalendarView", fullTitle: "WantsDateDecorations", getterString: "wantsDateDecorations", setterString: "setWantsDateDecorations:", patch: true, revision: 1)),
            ]),
        ])


        static let uiPasteControlGroup = BlueprintGroup(LookinAttrGroup_UIPasteControl, title: "UIPasteControl", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIPasteControl_Configuration, title: "Configuration", attributes: [
                BlueprintAttribute(LookinAttr_UIPasteControl_Configuration_Configuration, AttributeInfo(className: "UIPasteControl", fullTitle: "Configuration", getterString: "configuration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.configuration))),
            ]),
        ])

        static let uiCollectionViewGroup = BlueprintGroup(LookinAttrGroup_UICollectionView, title: "UICollectionView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UICollectionView_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UICollectionView_Behavior_PrefetchingEnabled, AttributeInfo(className: "UICollectionView", fullTitle: "PrefetchingEnabled", getterString: "isPrefetchingEnabled", setterString: "setPrefetchingEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionView_Behavior_DragInteractionEnabled, AttributeInfo(className: "UICollectionView", fullTitle: "DragInteractionEnabled", getterString: "dragInteractionEnabled", setterString: "setDragInteractionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionView_Behavior_AllowsSelection, AttributeInfo(className: "UICollectionView", fullTitle: "AllowsSelection", getterString: "allowsSelection", setterString: "setAllowsSelection:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionView_Behavior_AllowsMultipleSelection, AttributeInfo(className: "UICollectionView", fullTitle: "AllowsMultipleSelection", getterString: "allowsMultipleSelection", setterString: "setAllowsMultipleSelection:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionView_Behavior_HasUncommittedUpdates, AttributeInfo(className: "UICollectionView", fullTitle: "HasUncommittedUpdates", getterString: "hasUncommittedUpdates", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionView_Behavior_RemembersLastFocusedIndexPath, AttributeInfo(className: "UICollectionView", fullTitle: "RemembersLastFocusedIndexPath", getterString: "remembersLastFocusedIndexPath", setterString: "setRemembersLastFocusedIndexPath:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionView_Behavior_SelectionFollowsFocus, AttributeInfo(className: "UICollectionView", fullTitle: "SelectionFollowsFocus", getterString: "selectionFollowsFocus", setterString: "setSelectionFollowsFocus:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionView_Behavior_AllowsFocus, AttributeInfo(className: "UICollectionView", fullTitle: "AllowsFocus", getterString: "allowsFocus", setterString: "setAllowsFocus:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionView_Behavior_AllowsFocusDuringEditing, AttributeInfo(className: "UICollectionView", fullTitle: "AllowsFocusDuringEditing", getterString: "allowsFocusDuringEditing", setterString: "setAllowsFocusDuringEditing:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionView_Behavior_HasActiveDrag, AttributeInfo(className: "UICollectionView", fullTitle: "HasActiveDrag", getterString: "hasActiveDrag", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionView_Behavior_HasActiveDrop, AttributeInfo(className: "UICollectionView", fullTitle: "HasActiveDrop", getterString: "hasActiveDrop", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionView_Behavior_Editing, AttributeInfo(className: "UICollectionView", fullTitle: "Editing", getterString: "isEditing", setterString: "setEditing:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionView_Behavior_AllowsSelectionDuringEditing, AttributeInfo(className: "UICollectionView", fullTitle: "AllowsSelectionDuringEditing", getterString: "allowsSelectionDuringEditing", setterString: "setAllowsSelectionDuringEditing:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionView_Behavior_AllowsMultipleSelectionDuringEditing, AttributeInfo(className: "UICollectionView", fullTitle: "AllowsMultipleSelectionDuringEditing", getterString: "allowsMultipleSelectionDuringEditing", setterString: "setAllowsMultipleSelectionDuringEditing:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UICollectionView_ReorderingCadence, title: "ReorderingCadence", attributes: [
                BlueprintAttribute(LookinAttr_UICollectionView_ReorderingCadence_ReorderingCadence, AttributeInfo(className: "UICollectionView", fullTitle: "ReorderingCadence", getterString: "reorderingCadence", setterString: "setReorderingCadence:", enumList: "UICollectionViewReorderingCadence", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UICollectionView_SelfSizingInvalidation, title: "SelfSizingInvalidation", attributes: [
                BlueprintAttribute(LookinAttr_UICollectionView_SelfSizingInvalidation_SelfSizingInvalidation, AttributeInfo(className: "UICollectionView", fullTitle: "SelfSizingInvalidation", getterString: "selfSizingInvalidation", setterString: "setSelfSizingInvalidation:", enumList: "UICollectionViewSelfSizingInvalidation", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UICollectionView_IndexPathsForSelectedItems, title: "IndexPathsForSelectedItems", attributes: [
                BlueprintAttribute(LookinAttr_UICollectionView_IndexPathsForSelectedItems_IndexPathsForSelectedItems, AttributeInfo(className: "UICollectionView", fullTitle: "IndexPathsForSelectedItems", getterString: "indexPathsForSelectedItems", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(LookinAttrSec_UICollectionView_NumberOfSections, title: "NumberOfSections", attributes: [
                BlueprintAttribute(LookinAttr_UICollectionView_NumberOfSections_NumberOfSections, AttributeInfo(className: "UICollectionView", fullTitle: "NumberOfSections", getterString: "numberOfSections", setterString: "", revision: 1)),
            ]),
        ])


        static let uiCollectionReusableViewGroup = BlueprintGroup(LookinAttrGroup_UICollectionReusableView, title: "UICollectionReusableView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UICollectionReusableView_ReuseIdentifier, title: "ReuseIdentifier", attributes: [
                BlueprintAttribute(LookinAttr_UICollectionReusableView_ReuseIdentifier_ReuseIdentifier, AttributeInfo(className: "UICollectionReusableView", fullTitle: "ReuseIdentifier", getterString: "reuseIdentifier", setterString: "", typeIfObj: .nsString, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UICollectionReusableView_UICollectionViewCell, title: "UICollectionViewCell", attributes: [
                BlueprintAttribute(LookinAttr_UICollectionReusableView_UICollectionViewCell_AutomaticallyUpdatesContentConfiguration, AttributeInfo(className: "UICollectionViewCell", fullTitle: "AutomaticallyUpdatesContentConfiguration", getterString: "automaticallyUpdatesContentConfiguration", setterString: "setAutomaticallyUpdatesContentConfiguration:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionReusableView_UICollectionViewCell_Selected, AttributeInfo(className: "UICollectionViewCell", fullTitle: "Selected", getterString: "isSelected", setterString: "setSelected:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionReusableView_UICollectionViewCell_Highlighted, AttributeInfo(className: "UICollectionViewCell", fullTitle: "Highlighted", getterString: "isHighlighted", setterString: "setHighlighted:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionReusableView_UICollectionViewCell_BackgroundConfiguration, AttributeInfo(className: "UICollectionViewCell", fullTitle: "BackgroundConfiguration", getterString: "backgroundConfiguration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.configuration))),
                BlueprintAttribute(LookinAttr_UICollectionReusableView_UICollectionViewCell_AutomaticallyUpdatesBackgroundConfiguration, AttributeInfo(className: "UICollectionViewCell", fullTitle: "AutomaticallyUpdatesBackgroundConfiguration", getterString: "automaticallyUpdatesBackgroundConfiguration", setterString: "setAutomaticallyUpdatesBackgroundConfiguration:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UICollectionReusableView_UICollectionViewListCell, title: "UICollectionViewListCell", attributes: [
                BlueprintAttribute(LookinAttr_UICollectionReusableView_UICollectionViewListCell_IndentationLevel, AttributeInfo(className: "UICollectionViewListCell", fullTitle: "IndentationLevel", getterString: "indentationLevel", setterString: "setIndentationLevel:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionReusableView_UICollectionViewListCell_IndentationWidth, AttributeInfo(className: "UICollectionViewListCell", fullTitle: "IndentationWidth", getterString: "indentationWidth", setterString: "setIndentationWidth:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionReusableView_UICollectionViewListCell_IndentsAccessories, AttributeInfo(className: "UICollectionViewListCell", fullTitle: "IndentsAccessories", getterString: "indentsAccessories", setterString: "setIndentsAccessories:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UICollectionReusableView_UICollectionViewListCell_Accessories, AttributeInfo(className: "UICollectionViewListCell", fullTitle: "Accessories", getterString: "accessories", setterString: "", revision: 1, presentation: .count)),
            ]),
        ])


        static let uiTableViewCellGroup = BlueprintGroup(LookinAttrGroup_UITableViewCell, title: "UITableViewCell", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UITableViewCell_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UITableViewCell_Behavior_AutomaticallyUpdatesContentConfiguration, AttributeInfo(className: "UITableViewCell", fullTitle: "AutomaticallyUpdatesContentConfiguration", getterString: "automaticallyUpdatesContentConfiguration", setterString: "setAutomaticallyUpdatesContentConfiguration:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableViewCell_Behavior_AutomaticallyUpdatesBackgroundConfiguration, AttributeInfo(className: "UITableViewCell", fullTitle: "AutomaticallyUpdatesBackgroundConfiguration", getterString: "automaticallyUpdatesBackgroundConfiguration", setterString: "setAutomaticallyUpdatesBackgroundConfiguration:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableViewCell_Behavior_Selected, AttributeInfo(className: "UITableViewCell", fullTitle: "Selected", getterString: "isSelected", setterString: "setSelected:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableViewCell_Behavior_Highlighted, AttributeInfo(className: "UITableViewCell", fullTitle: "Highlighted", getterString: "isHighlighted", setterString: "setHighlighted:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableViewCell_Behavior_ShowsReorderControl, AttributeInfo(className: "UITableViewCell", fullTitle: "ShowsReorderControl", getterString: "showsReorderControl", setterString: "setShowsReorderControl:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableViewCell_Behavior_ShouldIndentWhileEditing, AttributeInfo(className: "UITableViewCell", fullTitle: "ShouldIndentWhileEditing", getterString: "shouldIndentWhileEditing", setterString: "setShouldIndentWhileEditing:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableViewCell_Behavior_Editing, AttributeInfo(className: "UITableViewCell", fullTitle: "Editing", getterString: "isEditing", setterString: "setEditing:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableViewCell_Behavior_ShowingDeleteConfirmation, AttributeInfo(className: "UITableViewCell", fullTitle: "ShowingDeleteConfirmation", getterString: "showingDeleteConfirmation", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UITableViewCell_Behavior_UserInteractionEnabledWhileDragging, AttributeInfo(className: "UITableViewCell", fullTitle: "UserInteractionEnabledWhileDragging", getterString: "userInteractionEnabledWhileDragging", setterString: "setUserInteractionEnabledWhileDragging:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableViewCell_BackgroundConfiguration, title: "BackgroundConfiguration", attributes: [
                BlueprintAttribute(LookinAttr_UITableViewCell_BackgroundConfiguration_BackgroundConfiguration, AttributeInfo(className: "UITableViewCell", fullTitle: "BackgroundConfiguration", getterString: "backgroundConfiguration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.configuration))),
            ]),
            BlueprintSection(LookinAttrSec_UITableViewCell_ReuseIdentifier, title: "ReuseIdentifier", attributes: [
                BlueprintAttribute(LookinAttr_UITableViewCell_ReuseIdentifier_ReuseIdentifier, AttributeInfo(className: "UITableViewCell", fullTitle: "ReuseIdentifier", getterString: "reuseIdentifier", setterString: "", typeIfObj: .nsString, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableViewCell_SelectionStyle, title: "SelectionStyle", attributes: [
                BlueprintAttribute(LookinAttr_UITableViewCell_SelectionStyle_SelectionStyle, AttributeInfo(className: "UITableViewCell", fullTitle: "SelectionStyle", getterString: "selectionStyle", setterString: "setSelectionStyle:", enumList: "UITableViewCellSelectionStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableViewCell_EditingStyle, title: "EditingStyle", attributes: [
                BlueprintAttribute(LookinAttr_UITableViewCell_EditingStyle_EditingStyle, AttributeInfo(className: "UITableViewCell", fullTitle: "EditingStyle", getterString: "editingStyle", setterString: "", enumList: "UITableViewCellEditingStyle", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableViewCell_AccessoryType, title: "AccessoryType", attributes: [
                BlueprintAttribute(LookinAttr_UITableViewCell_AccessoryType_AccessoryType, AttributeInfo(className: "UITableViewCell", fullTitle: "AccessoryType", getterString: "accessoryType", setterString: "setAccessoryType:", enumList: "UITableViewCellAccessoryType", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableViewCell_EditingAccessoryType, title: "EditingAccessoryType", attributes: [
                BlueprintAttribute(LookinAttr_UITableViewCell_EditingAccessoryType_EditingAccessoryType, AttributeInfo(className: "UITableViewCell", fullTitle: "EditingAccessoryType", getterString: "editingAccessoryType", setterString: "setEditingAccessoryType:", enumList: "UITableViewCellAccessoryType", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableViewCell_IndentationLevel, title: "IndentationLevel", attributes: [
                BlueprintAttribute(LookinAttr_UITableViewCell_IndentationLevel_IndentationLevel, AttributeInfo(className: "UITableViewCell", fullTitle: "IndentationLevel", getterString: "indentationLevel", setterString: "setIndentationLevel:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableViewCell_IndentationWidth, title: "IndentationWidth", attributes: [
                BlueprintAttribute(LookinAttr_UITableViewCell_IndentationWidth_IndentationWidth, AttributeInfo(className: "UITableViewCell", fullTitle: "IndentationWidth", getterString: "indentationWidth", setterString: "setIndentationWidth:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableViewCell_SeparatorInset, title: "SeparatorInset", attributes: [
                BlueprintAttribute(LookinAttr_UITableViewCell_SeparatorInset_SeparatorInset, AttributeInfo(className: "UITableViewCell", fullTitle: "SeparatorInset", getterString: "separatorInset", setterString: "setSeparatorInset:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableViewCell_FocusStyle, title: "FocusStyle", attributes: [
                BlueprintAttribute(LookinAttr_UITableViewCell_FocusStyle_FocusStyle, AttributeInfo(className: "UITableViewCell", fullTitle: "FocusStyle", getterString: "focusStyle", setterString: "setFocusStyle:", enumList: "UITableViewCellFocusStyle", patch: true, revision: 1)),
            ]),
        ])


        static let uiTableViewHeaderFooterViewGroup = BlueprintGroup(LookinAttrGroup_UITableViewHeaderFooterView, title: "UITableViewHeaderFooterView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UITableViewHeaderFooterView_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UITableViewHeaderFooterView_Behavior_AutomaticallyUpdatesContentConfiguration, AttributeInfo(className: "UITableViewHeaderFooterView", fullTitle: "AutomaticallyUpdatesContentConfiguration", getterString: "automaticallyUpdatesContentConfiguration", setterString: "setAutomaticallyUpdatesContentConfiguration:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITableViewHeaderFooterView_Behavior_AutomaticallyUpdatesBackgroundConfiguration, AttributeInfo(className: "UITableViewHeaderFooterView", fullTitle: "AutomaticallyUpdatesBackgroundConfiguration", getterString: "automaticallyUpdatesBackgroundConfiguration", setterString: "setAutomaticallyUpdatesBackgroundConfiguration:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITableViewHeaderFooterView_BackgroundConfiguration, title: "BackgroundConfiguration", attributes: [
                BlueprintAttribute(LookinAttr_UITableViewHeaderFooterView_BackgroundConfiguration_BackgroundConfiguration, AttributeInfo(className: "UITableViewHeaderFooterView", fullTitle: "BackgroundConfiguration", getterString: "backgroundConfiguration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.configuration))),
            ]),
            BlueprintSection(LookinAttrSec_UITableViewHeaderFooterView_ReuseIdentifier, title: "ReuseIdentifier", attributes: [
                BlueprintAttribute(LookinAttr_UITableViewHeaderFooterView_ReuseIdentifier_ReuseIdentifier, AttributeInfo(className: "UITableViewHeaderFooterView", fullTitle: "ReuseIdentifier", getterString: "reuseIdentifier", setterString: "", typeIfObj: .nsString, hideIfNil: true, revision: 1)),
            ]),
        ])


        static let uiNavigationBarGroup = BlueprintGroup(LookinAttrGroup_UINavigationBar, title: "UINavigationBar", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UINavigationBar_BarStyle, title: "BarStyle", attributes: [
                BlueprintAttribute(LookinAttr_UINavigationBar_BarStyle_BarStyle, AttributeInfo(className: "UINavigationBar", fullTitle: "BarStyle", getterString: "barStyle", setterString: "setBarStyle:", enumList: "UIBarStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UINavigationBar_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UINavigationBar_Behavior_Translucent, AttributeInfo(className: "UINavigationBar", fullTitle: "Translucent", getterString: "isTranslucent", setterString: "setTranslucent:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UINavigationBar_Behavior_PrefersLargeTitles, AttributeInfo(className: "UINavigationBar", fullTitle: "PrefersLargeTitles", getterString: "prefersLargeTitles", setterString: "setPrefersLargeTitles:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UINavigationBar_TopItem, title: "TopItem", attributes: [
                BlueprintAttribute(LookinAttr_UINavigationBar_TopItem_TopItem, AttributeInfo(className: "UINavigationBar", fullTitle: "TopItem", getterString: "topItem", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.navigationItem))),
            ]),
            BlueprintSection(LookinAttrSec_UINavigationBar_BackItem, title: "BackItem", attributes: [
                BlueprintAttribute(LookinAttr_UINavigationBar_BackItem_BackItem, AttributeInfo(className: "UINavigationBar", fullTitle: "BackItem", getterString: "backItem", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.navigationItem))),
            ]),
            BlueprintSection(LookinAttrSec_UINavigationBar_CurrentNSToolbarSection, title: "CurrentNSToolbarSection", attributes: [
                BlueprintAttribute(LookinAttr_UINavigationBar_CurrentNSToolbarSection_CurrentNSToolbarSection, AttributeInfo(className: "UINavigationBar", fullTitle: "CurrentNSToolbarSection", getterString: "currentNSToolbarSection", setterString: "", enumList: "UINavigationBarNSToolbarSection", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UINavigationBar_BehavioralStyle, title: "BehavioralStyle", attributes: [
                BlueprintAttribute(LookinAttr_UINavigationBar_BehavioralStyle_BehavioralStyle, AttributeInfo(className: "UINavigationBar", fullTitle: "BehavioralStyle", getterString: "behavioralStyle", setterString: "", enumList: "UIBehavioralStyle", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UINavigationBar_PreferredBehavioralStyle, title: "PreferredBehavioralStyle", attributes: [
                BlueprintAttribute(LookinAttr_UINavigationBar_PreferredBehavioralStyle_PreferredBehavioralStyle, AttributeInfo(className: "UINavigationBar", fullTitle: "PreferredBehavioralStyle", getterString: "preferredBehavioralStyle", setterString: "setPreferredBehavioralStyle:", enumList: "UIBehavioralStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UINavigationBar_BarTintColor, title: "BarTintColor", attributes: [
                BlueprintAttribute(LookinAttr_UINavigationBar_BarTintColor_BarTintColor, AttributeInfo(className: "UINavigationBar", fullTitle: "BarTintColor", getterString: "barTintColor", setterString: "setBarTintColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UINavigationBar_Images, title: "Images", attributes: [
                BlueprintAttribute(LookinAttr_UINavigationBar_Images_ShadowImage, AttributeInfo(className: "UINavigationBar", fullTitle: "ShadowImage", getterString: "shadowImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_UINavigationBar_Images_BackIndicatorImage, AttributeInfo(className: "UINavigationBar", fullTitle: "BackIndicatorImage", getterString: "backIndicatorImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_UINavigationBar_Images_BackIndicatorTransitionMaskImage, AttributeInfo(className: "UINavigationBar", fullTitle: "BackIndicatorTransitionMaskImage", getterString: "backIndicatorTransitionMaskImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
        ])


        static let uiTabBarGroup = BlueprintGroup(LookinAttrGroup_UITabBar, title: "UITabBar", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UITabBar_SelectedItem, title: "SelectedItem", attributes: [
                BlueprintAttribute(LookinAttr_UITabBar_SelectedItem_SelectedItem, AttributeInfo(className: "UITabBar", fullTitle: "SelectedItem", getterString: "selectedItem", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.barItem))),
            ]),
            BlueprintSection(LookinAttrSec_UITabBar_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UITabBar_Behavior_Customizing, AttributeInfo(className: "UITabBar", fullTitle: "Customizing", getterString: "isCustomizing", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UITabBar_Behavior_Translucent, AttributeInfo(className: "UITabBar", fullTitle: "Translucent", getterString: "isTranslucent", setterString: "setTranslucent:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITabBar_Colors, title: "Colors", attributes: [
                BlueprintAttribute(LookinAttr_UITabBar_Colors_BarTintColor, AttributeInfo(className: "UITabBar", fullTitle: "BarTintColor", getterString: "barTintColor", setterString: "setBarTintColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UITabBar_Colors_UnselectedItemTintColor, AttributeInfo(className: "UITabBar", fullTitle: "UnselectedItemTintColor", getterString: "unselectedItemTintColor", setterString: "setUnselectedItemTintColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITabBar_Images, title: "Images", attributes: [
                BlueprintAttribute(LookinAttr_UITabBar_Images_BackgroundImage, AttributeInfo(className: "UITabBar", fullTitle: "BackgroundImage", getterString: "backgroundImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_UITabBar_Images_SelectionIndicatorImage, AttributeInfo(className: "UITabBar", fullTitle: "SelectionIndicatorImage", getterString: "selectionIndicatorImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_UITabBar_Images_ShadowImage, AttributeInfo(className: "UITabBar", fullTitle: "ShadowImage", getterString: "shadowImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(LookinAttrSec_UITabBar_ItemPositioning, title: "ItemPositioning", attributes: [
                BlueprintAttribute(LookinAttr_UITabBar_ItemPositioning_ItemPositioning, AttributeInfo(className: "UITabBar", fullTitle: "ItemPositioning", getterString: "itemPositioning", setterString: "setItemPositioning:", enumList: "UITabBarItemPositioning", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITabBar_ItemWidth, title: "ItemWidth", attributes: [
                BlueprintAttribute(LookinAttr_UITabBar_ItemWidth_ItemWidth, AttributeInfo(className: "UITabBar", fullTitle: "ItemWidth", getterString: "itemWidth", setterString: "setItemWidth:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITabBar_ItemSpacing, title: "ItemSpacing", attributes: [
                BlueprintAttribute(LookinAttr_UITabBar_ItemSpacing_ItemSpacing, AttributeInfo(className: "UITabBar", fullTitle: "ItemSpacing", getterString: "itemSpacing", setterString: "setItemSpacing:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UITabBar_BarStyle, title: "BarStyle", attributes: [
                BlueprintAttribute(LookinAttr_UITabBar_BarStyle_BarStyle, AttributeInfo(className: "UITabBar", fullTitle: "BarStyle", getterString: "barStyle", setterString: "setBarStyle:", enumList: "UIBarStyle", patch: true, revision: 1)),
            ]),
        ])


        static let uiToolbarGroup = BlueprintGroup(LookinAttrGroup_UIToolbar, title: "UIToolbar", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIToolbar_BarStyle, title: "BarStyle", attributes: [
                BlueprintAttribute(LookinAttr_UIToolbar_BarStyle_BarStyle, AttributeInfo(className: "UIToolbar", fullTitle: "BarStyle", getterString: "barStyle", setterString: "setBarStyle:", enumList: "UIBarStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIToolbar_Translucent, title: "Translucent", attributes: [
                BlueprintAttribute(LookinAttr_UIToolbar_Translucent_Translucent, AttributeInfo(className: "UIToolbar", fullTitle: "Translucent", getterString: "isTranslucent", setterString: "setTranslucent:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIToolbar_BarTintColor, title: "BarTintColor", attributes: [
                BlueprintAttribute(LookinAttr_UIToolbar_BarTintColor_BarTintColor, AttributeInfo(className: "UIToolbar", fullTitle: "BarTintColor", getterString: "barTintColor", setterString: "setBarTintColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
        ])


        static let uiSearchBarGroup = BlueprintGroup(LookinAttrGroup_UISearchBar, title: "UISearchBar", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UISearchBar_BarStyle, title: "BarStyle", attributes: [
                BlueprintAttribute(LookinAttr_UISearchBar_BarStyle_BarStyle, AttributeInfo(className: "UISearchBar", fullTitle: "BarStyle", getterString: "barStyle", setterString: "setBarStyle:", enumList: "UIBarStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISearchBar_Text, title: "Text", attributes: [
                BlueprintAttribute(LookinAttr_UISearchBar_Text_Text, AttributeInfo(className: "UISearchBar", fullTitle: "Text", getterString: "text", setterString: "setText:", typeIfObj: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISearchBar_Prompt, title: "Prompt", attributes: [
                BlueprintAttribute(LookinAttr_UISearchBar_Prompt_Prompt, AttributeInfo(className: "UISearchBar", fullTitle: "Prompt", getterString: "prompt", setterString: "setPrompt:", typeIfObj: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISearchBar_Placeholder, title: "Placeholder", attributes: [
                BlueprintAttribute(LookinAttr_UISearchBar_Placeholder_Placeholder, AttributeInfo(className: "UISearchBar", fullTitle: "Placeholder", getterString: "placeholder", setterString: "setPlaceholder:", typeIfObj: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISearchBar_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UISearchBar_Behavior_ShowsBookmarkButton, AttributeInfo(className: "UISearchBar", fullTitle: "ShowsBookmarkButton", getterString: "showsBookmarkButton", setterString: "setShowsBookmarkButton:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UISearchBar_Behavior_ShowsCancelButton, AttributeInfo(className: "UISearchBar", fullTitle: "ShowsCancelButton", getterString: "showsCancelButton", setterString: "setShowsCancelButton:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UISearchBar_Behavior_ShowsSearchResultsButton, AttributeInfo(className: "UISearchBar", fullTitle: "ShowsSearchResultsButton", getterString: "showsSearchResultsButton", setterString: "setShowsSearchResultsButton:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UISearchBar_Behavior_SearchResultsButtonSelected, AttributeInfo(className: "UISearchBar", fullTitle: "SearchResultsButtonSelected", getterString: "isSearchResultsButtonSelected", setterString: "setSearchResultsButtonSelected:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UISearchBar_Behavior_Translucent, AttributeInfo(className: "UISearchBar", fullTitle: "Translucent", getterString: "isTranslucent", setterString: "setTranslucent:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UISearchBar_Behavior_ShowsScopeBar, AttributeInfo(className: "UISearchBar", fullTitle: "ShowsScopeBar", getterString: "showsScopeBar", setterString: "setShowsScopeBar:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UISearchBar_Behavior_Enabled, AttributeInfo(className: "UISearchBar", fullTitle: "Enabled", getterString: "isEnabled", setterString: "setEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UISearchBar_Behavior_LookToDictateEnabled, AttributeInfo(className: "UISearchBar", fullTitle: "LookToDictateEnabled", getterString: "isLookToDictateEnabled", setterString: "setLookToDictateEnabled:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISearchBar_BarTintColor, title: "BarTintColor", attributes: [
                BlueprintAttribute(LookinAttr_UISearchBar_BarTintColor_BarTintColor, AttributeInfo(className: "UISearchBar", fullTitle: "BarTintColor", getterString: "barTintColor", setterString: "setBarTintColor:", typeIfObj: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISearchBar_SearchBarStyle, title: "SearchBarStyle", attributes: [
                BlueprintAttribute(LookinAttr_UISearchBar_SearchBarStyle_SearchBarStyle, AttributeInfo(className: "UISearchBar", fullTitle: "SearchBarStyle", getterString: "searchBarStyle", setterString: "setSearchBarStyle:", enumList: "UISearchBarStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISearchBar_ScopeButtonTitles, title: "ScopeButtonTitles", attributes: [
                BlueprintAttribute(LookinAttr_UISearchBar_ScopeButtonTitles_ScopeButtonTitles, AttributeInfo(className: "UISearchBar", fullTitle: "ScopeButtonTitles", getterString: "scopeButtonTitles", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(LookinAttrSec_UISearchBar_SelectedScopeButtonIndex, title: "SelectedScopeButtonIndex", attributes: [
                BlueprintAttribute(LookinAttr_UISearchBar_SelectedScopeButtonIndex_SelectedScopeButtonIndex, AttributeInfo(className: "UISearchBar", fullTitle: "SelectedScopeButtonIndex", getterString: "selectedScopeButtonIndex", setterString: "setSelectedScopeButtonIndex:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UISearchBar_Images, title: "Images", attributes: [
                BlueprintAttribute(LookinAttr_UISearchBar_Images_BackgroundImage, AttributeInfo(className: "UISearchBar", fullTitle: "BackgroundImage", getterString: "backgroundImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(LookinAttr_UISearchBar_Images_ScopeBarBackgroundImage, AttributeInfo(className: "UISearchBar", fullTitle: "ScopeBarBackgroundImage", getterString: "scopeBarBackgroundImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(LookinAttrSec_UISearchBar_SearchFieldBackgroundPositionAdjustment, title: "SearchFieldBackgroundPositionAdjustment", attributes: [
                BlueprintAttribute(LookinAttr_UISearchBar_SearchFieldBackgroundPositionAdjustment_SearchFieldBackgroundPositionAdjustment, AttributeInfo(className: "UISearchBar", fullTitle: "SearchFieldBackgroundPositionAdjustment", getterString: "searchFieldBackgroundPositionAdjustment", setterString: "", revision: 1, presentation: .structure)),
            ]),
            BlueprintSection(LookinAttrSec_UISearchBar_SearchTextPositionAdjustment, title: "SearchTextPositionAdjustment", attributes: [
                BlueprintAttribute(LookinAttr_UISearchBar_SearchTextPositionAdjustment_SearchTextPositionAdjustment, AttributeInfo(className: "UISearchBar", fullTitle: "SearchTextPositionAdjustment", getterString: "searchTextPositionAdjustment", setterString: "", revision: 1, presentation: .structure)),
            ]),
        ])


        static let uiInputViewGroup = BlueprintGroup(LookinAttrGroup_UIInputView, title: "UIInputView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIInputView_InputViewStyle, title: "InputViewStyle", attributes: [
                BlueprintAttribute(LookinAttr_UIInputView_InputViewStyle_InputViewStyle, AttributeInfo(className: "UIInputView", fullTitle: "InputViewStyle", getterString: "inputViewStyle", setterString: "", enumList: "UIInputViewStyle", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIInputView_AllowsSelfSizing, title: "AllowsSelfSizing", attributes: [
                BlueprintAttribute(LookinAttr_UIInputView_AllowsSelfSizing_AllowsSelfSizing, AttributeInfo(className: "UIInputView", fullTitle: "AllowsSelfSizing", getterString: "allowsSelfSizing", setterString: "setAllowsSelfSizing:", patch: true, revision: 1)),
            ]),
        ])


        static let uiContentUnavailableViewGroup = BlueprintGroup(LookinAttrGroup_UIContentUnavailableView, title: "UIContentUnavailableView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIContentUnavailableView_Configuration, title: "Configuration", attributes: [
                BlueprintAttribute(LookinAttr_UIContentUnavailableView_Configuration_Configuration, AttributeInfo(className: "UIContentUnavailableView", fullTitle: "Configuration", getterString: "configuration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.configuration))),
            ]),
            BlueprintSection(LookinAttrSec_UIContentUnavailableView_ScrollEnabled, title: "ScrollEnabled", attributes: [
                BlueprintAttribute(LookinAttr_UIContentUnavailableView_ScrollEnabled_ScrollEnabled, AttributeInfo(className: "UIContentUnavailableView", fullTitle: "ScrollEnabled", getterString: "isScrollEnabled", setterString: "setScrollEnabled:", patch: true, revision: 1)),
            ]),
        ])


        static let uiBackgroundExtensionViewGroup = BlueprintGroup(LookinAttrGroup_UIBackgroundExtensionView, title: "UIBackgroundExtensionView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIBackgroundExtensionView_AutomaticallyPlacesContentView, title: "AutomaticallyPlacesContentView", attributes: [
                BlueprintAttribute(LookinAttr_UIBackgroundExtensionView_AutomaticallyPlacesContentView_AutomaticallyPlacesContentView, AttributeInfo(className: "UIBackgroundExtensionView", fullTitle: "AutomaticallyPlacesContentView", getterString: "automaticallyPlacesContentView", setterString: "setAutomaticallyPlacesContentView:", patch: true, revision: 1)),
            ]),
        ])


        static let uiWindowGroup = BlueprintGroup(LookinAttrGroup_UIWindow, title: "UIWindow", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIWindow_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UIWindow_Behavior_CanResizeToFitContent, AttributeInfo(className: "UIWindow", fullTitle: "CanResizeToFitContent", getterString: "canResizeToFitContent", setterString: "setCanResizeToFitContent:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIWindow_Behavior_KeyWindow, AttributeInfo(className: "UIWindow", fullTitle: "KeyWindow", getterString: "isKeyWindow", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UIWindow_Behavior_CanBecomeKeyWindow, AttributeInfo(className: "UIWindow", fullTitle: "CanBecomeKeyWindow", getterString: "canBecomeKeyWindow", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIWindow_WindowLevel, title: "WindowLevel", attributes: [
                BlueprintAttribute(LookinAttr_UIWindow_WindowLevel_WindowLevel, AttributeInfo(className: "UIWindow", fullTitle: "WindowLevel", getterString: "windowLevel", setterString: "setWindowLevel:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIWindow_RootViewController, title: "RootViewController", attributes: [
                BlueprintAttribute(LookinAttr_UIWindow_RootViewController_RootViewController, AttributeInfo(className: "UIWindow", fullTitle: "RootViewController", getterString: "rootViewController", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.className))),
            ]),
        ])

        static let uiViewGroup = BlueprintGroup(LookinAttrGroup_UIView, title: "UIView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIView_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_UIView_Behavior_AccessibilityIgnoresInvertColors, AttributeInfo(className: "UIView", fullTitle: "AccessibilityIgnoresInvertColors", getterString: "accessibilityIgnoresInvertColors", setterString: "setAccessibilityIgnoresInvertColors:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIView_Behavior_ShowsLargeContentViewer, AttributeInfo(className: "UIView", fullTitle: "ShowsLargeContentViewer", getterString: "showsLargeContentViewer", setterString: "setShowsLargeContentViewer:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIView_Behavior_ScalesLargeContentImage, AttributeInfo(className: "UIView", fullTitle: "ScalesLargeContentImage", getterString: "scalesLargeContentImage", setterString: "setScalesLargeContentImage:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIView_Behavior_CanBecomeFocused, AttributeInfo(className: "UIView", fullTitle: "CanBecomeFocused", getterString: "canBecomeFocused", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UIView_Behavior_Focused, AttributeInfo(className: "UIView", fullTitle: "Focused", getterString: "isFocused", setterString: "", revision: 1)),
                BlueprintAttribute(LookinAttr_UIView_Behavior_MultipleTouchEnabled, AttributeInfo(className: "UIView", fullTitle: "MultipleTouchEnabled", getterString: "isMultipleTouchEnabled", setterString: "setMultipleTouchEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIView_Behavior_ExclusiveTouch, AttributeInfo(className: "UIView", fullTitle: "ExclusiveTouch", getterString: "isExclusiveTouch", setterString: "setExclusiveTouch:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIView_Behavior_AutoresizesSubviews, AttributeInfo(className: "UIView", fullTitle: "AutoresizesSubviews", getterString: "autoresizesSubviews", setterString: "setAutoresizesSubviews:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIView_Behavior_PreservesSuperviewLayoutMargins, AttributeInfo(className: "UIView", fullTitle: "PreservesSuperviewLayoutMargins", getterString: "preservesSuperviewLayoutMargins", setterString: "setPreservesSuperviewLayoutMargins:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIView_Behavior_InsetsLayoutMarginsFromSafeArea, AttributeInfo(className: "UIView", fullTitle: "InsetsLayoutMarginsFromSafeArea", getterString: "insetsLayoutMarginsFromSafeArea", setterString: "setInsetsLayoutMarginsFromSafeArea:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIView_Behavior_ClearsContextBeforeDrawing, AttributeInfo(className: "UIView", fullTitle: "ClearsContextBeforeDrawing", getterString: "clearsContextBeforeDrawing", setterString: "setClearsContextBeforeDrawing:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_UIView_Behavior_TranslatesAutoresizingMaskIntoConstraints, AttributeInfo(className: "UIView", fullTitle: "TranslatesAutoresizingMaskIntoConstraints", getterString: "translatesAutoresizingMaskIntoConstraints", setterString: "setTranslatesAutoresizingMaskIntoConstraints:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIView_LargeContentTitle, title: "LargeContentTitle", attributes: [
                BlueprintAttribute(LookinAttr_UIView_LargeContentTitle_LargeContentTitle, AttributeInfo(className: "UIView", fullTitle: "LargeContentTitle", getterString: "largeContentTitle", setterString: "setLargeContentTitle:", typeIfObj: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIView_LargeContentImageInsets, title: "LargeContentImageInsets", attributes: [
                BlueprintAttribute(LookinAttr_UIView_LargeContentImageInsets_LargeContentImageInsets, AttributeInfo(className: "UIView", fullTitle: "LargeContentImageInsets", getterString: "largeContentImageInsets", setterString: "setLargeContentImageInsets:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIView_FocusGroupIdentifier, title: "FocusGroupIdentifier", attributes: [
                BlueprintAttribute(LookinAttr_UIView_FocusGroupIdentifier_FocusGroupIdentifier, AttributeInfo(className: "UIView", fullTitle: "FocusGroupIdentifier", getterString: "focusGroupIdentifier", setterString: "setFocusGroupIdentifier:", typeIfObj: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIView_SemanticContentAttribute, title: "SemanticContentAttribute", attributes: [
                BlueprintAttribute(LookinAttr_UIView_SemanticContentAttribute_SemanticContentAttribute, AttributeInfo(className: "UIView", fullTitle: "SemanticContentAttribute", getterString: "semanticContentAttribute", setterString: "setSemanticContentAttribute:", enumList: "UISemanticContentAttribute", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIView_EffectiveUserInterfaceLayoutDirection, title: "EffectiveUserInterfaceLayoutDirection", attributes: [
                BlueprintAttribute(LookinAttr_UIView_EffectiveUserInterfaceLayoutDirection_EffectiveUserInterfaceLayoutDirection, AttributeInfo(className: "UIView", fullTitle: "EffectiveUserInterfaceLayoutDirection", getterString: "effectiveUserInterfaceLayoutDirection", setterString: "", enumList: "UIUserInterfaceLayoutDirection", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIView_Transform, title: "Transform", attributes: [
                BlueprintAttribute(LookinAttr_UIView_Transform_Transform, AttributeInfo(className: "UIView", fullTitle: "Transform", getterString: "transform", setterString: "", revision: 1, presentation: .structure)),
            ]),
            BlueprintSection(LookinAttrSec_UIView_Transform3D, title: "Transform3D", attributes: [
                BlueprintAttribute(LookinAttr_UIView_Transform3D_Transform3D, AttributeInfo(className: "UIView", fullTitle: "Transform3D", getterString: "transform3D", setterString: "", revision: 1, presentation: .structure)),
            ]),
            BlueprintSection(LookinAttrSec_UIView_ContentScaleFactor, title: "ContentScaleFactor", attributes: [
                BlueprintAttribute(LookinAttr_UIView_ContentScaleFactor_ContentScaleFactor, AttributeInfo(className: "UIView", fullTitle: "ContentScaleFactor", getterString: "contentScaleFactor", setterString: "setContentScaleFactor:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIView_AutoresizingMask, title: "AutoresizingMask", attributes: [
                BlueprintAttribute(LookinAttr_UIView_AutoresizingMask_AutoresizingMask, AttributeInfo(className: "UIView", fullTitle: "AutoresizingMask", getterString: "autoresizingMask", setterString: "", revision: 1, presentation: .optionNames("UIViewAutoresizing"))),
            ]),
            BlueprintSection(LookinAttrSec_UIView_LayoutMargins, title: "LayoutMargins", attributes: [
                BlueprintAttribute(LookinAttr_UIView_LayoutMargins_LayoutMargins, AttributeInfo(className: "UIView", fullTitle: "LayoutMargins", getterString: "layoutMargins", setterString: "setLayoutMargins:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIView_DirectionalLayoutMargins, title: "DirectionalLayoutMargins", attributes: [
                BlueprintAttribute(LookinAttr_UIView_DirectionalLayoutMargins_DirectionalLayoutMargins, AttributeInfo(className: "UIView", fullTitle: "DirectionalLayoutMargins", getterString: "directionalLayoutMargins", setterString: "", revision: 1, presentation: .structure)),
            ]),
            BlueprintSection(LookinAttrSec_UIView_AlignmentRectInsets, title: "AlignmentRectInsets", attributes: [
                BlueprintAttribute(LookinAttr_UIView_AlignmentRectInsets_AlignmentRectInsets, AttributeInfo(className: "UIView", fullTitle: "AlignmentRectInsets", getterString: "alignmentRectInsets", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIView_RestorationIdentifier, title: "RestorationIdentifier", attributes: [
                BlueprintAttribute(LookinAttr_UIView_RestorationIdentifier_RestorationIdentifier, AttributeInfo(className: "UIView", fullTitle: "RestorationIdentifier", getterString: "restorationIdentifier", setterString: "setRestorationIdentifier:", typeIfObj: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIView_OverrideUserInterfaceStyle, title: "OverrideUserInterfaceStyle", attributes: [
                BlueprintAttribute(LookinAttr_UIView_OverrideUserInterfaceStyle_OverrideUserInterfaceStyle, AttributeInfo(className: "UIView", fullTitle: "OverrideUserInterfaceStyle", getterString: "overrideUserInterfaceStyle", setterString: "setOverrideUserInterfaceStyle:", enumList: "UIUserInterfaceStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIView_MinimumContentSizeCategory, title: "MinimumContentSizeCategory", attributes: [
                BlueprintAttribute(LookinAttr_UIView_MinimumContentSizeCategory_MinimumContentSizeCategory, AttributeInfo(className: "UIView", fullTitle: "MinimumContentSizeCategory", getterString: "minimumContentSizeCategory", setterString: "", typeIfObj: .nsString, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIView_MaximumContentSizeCategory, title: "MaximumContentSizeCategory", attributes: [
                BlueprintAttribute(LookinAttr_UIView_MaximumContentSizeCategory_MaximumContentSizeCategory, AttributeInfo(className: "UIView", fullTitle: "MaximumContentSizeCategory", getterString: "maximumContentSizeCategory", setterString: "", typeIfObj: .nsString, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIView_AppliedContentSizeCategoryLimitsDescription, title: "AppliedContentSizeCategoryLimitsDescription", attributes: [
                BlueprintAttribute(LookinAttr_UIView_AppliedContentSizeCategoryLimitsDescription_AppliedContentSizeCategoryLimitsDescription, AttributeInfo(className: "UIView", fullTitle: "AppliedContentSizeCategoryLimitsDescription", getterString: "appliedContentSizeCategoryLimitsDescription", setterString: "", typeIfObj: .nsString, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_UIView_CornerConfiguration, title: "CornerConfiguration", attributes: [
                BlueprintAttribute(LookinAttr_UIView_CornerConfiguration_CornerConfiguration, AttributeInfo(className: "UIView", fullTitle: "CornerConfiguration", getterString: "cornerConfiguration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.description))),
            ]),
        ])
    }

#endif
