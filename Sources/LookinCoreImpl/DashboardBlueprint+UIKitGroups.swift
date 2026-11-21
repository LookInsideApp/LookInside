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
        ])

        static let uiVisualEffectViewGroup = BlueprintGroup(LookinAttrGroup_UIVisualEffectView, title: "UIVisualEffectView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIVisualEffectView_Style, title: "Style", attributes: [
                BlueprintAttribute(LookinAttr_UIVisualEffectView_Style_Style, AttributeInfo(className: "UIVisualEffectView", getterString: "lks_blurEffectStyleNumber", setterString: "setLks_blurEffectStyleNumber:", typeIfObj: .customObj, enumList: "UIBlurEffectStyle", patch: true, hideIfNil: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIVisualEffectView_QMUIForegroundColor, title: "ForegroundColor", attributes: [
                BlueprintAttribute(LookinAttr_UIVisualEffectView_QMUIForegroundColor_Color, AttributeInfo(className: "QMUIVisualEffectView", fullTitle: "ForegroundColor", typeIfObj: .uiColor, patch: true)),
            ]),
        ])

        static let uiImageViewGroup = BlueprintGroup(LookinAttrGroup_UIImageView, title: "UIImageView", on: .uiKit, sections: [
            BlueprintSection(LookinAttrSec_UIImageView_Name, title: "ImageName", attributes: [
                BlueprintAttribute(LookinAttr_UIImageView_Name_Name, AttributeInfo(className: "UIImageView", fullTitle: "ImageName", getterString: "lks_imageSourceName", setterString: "", typeIfObj: .nsString, hideIfNil: true)),
            ]),
            BlueprintSection(LookinAttrSec_UIImageView_Open, attributes: [
                BlueprintAttribute(LookinAttr_UIImageView_Open_Open, AttributeInfo(className: "UIImageView", getterString: "lks_imageViewOidIfHasImage", setterString: "", typeIfObj: .customObj, hideIfNil: true)),
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
    }

#endif
