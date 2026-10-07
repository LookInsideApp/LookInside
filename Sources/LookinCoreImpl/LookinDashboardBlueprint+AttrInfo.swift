//
//  LookinDashboardBlueprint+AttrInfo.swift
//  LookinCore
//
//  Class, titles, accessors and flags of every attribute.
//  Translated from LookinDashboardBlueprint.m; the output of every public
//  class method is pinned by Tests/LookinServerHierarchyTests/
//  BlueprintEquivalenceTests and its Fixtures/blueprint-<platform>.txt.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    extension LookinDashboardBlueprintTables {
        /// The per-attribute information behind the attribute queries. See
        /// `AttrInfo` for what each field means.
        static let attrInfo: [String: AttrInfo] = {
            var table: [String: AttrInfo] = [:]
            table[LookinAttr_Class_Class_Class] = AttrInfo(className: "CALayer", getterString: "lks_relatedClassChainList", setterString: "", typeIfObj: .customObj)
            table[LookinAttr_Relation_Relation_Relation] = AttrInfo(className: "CALayer", getterString: "lks_selfRelation", setterString: "", typeIfObj: .customObj, hideIfNil: true)
            table[LookinAttr_Layout_Frame_Frame] = AttrInfo(className: "CALayer", fullTitle: "Frame", patch: true)
            table[LookinAttr_Layout_Bounds_Bounds] = AttrInfo(className: "CALayer", fullTitle: "Bounds", patch: true)
            // Attributes that exist on both platforms must appear exactly once
            // in this table, with the className split per platform
            // (viewClassName, layoutGuideClassName). A second assignment under
            // the same key would overwrite the first, so one platform's
            // className would name a class it does not have and the row would
            // vanish from the dashboard.
            table[LookinAttr_Layout_SafeArea_SafeArea] = AttrInfo(className: viewClassName, fullTitle: "SafeAreaInsets", setterString: "", osVersion: 11)
            table[LookinAttr_Layout_Position_Position] = AttrInfo(className: "CALayer", fullTitle: "Position", patch: true)
            table[LookinAttr_Layout_AnchorPoint_AnchorPoint] = AttrInfo(className: "CALayer", fullTitle: "AnchorPoint", patch: true)
            table[LookinAttr_AutoLayout_Hugging_Hor] = AttrInfo(className: viewClassName, fullTitle: "ContentHuggingPriority(Horizontal)", briefTitle: "H", getterString: "lks_horizontalContentHuggingPriority", setterString: "setLks_horizontalContentHuggingPriority:", patch: true)
            table[LookinAttr_AutoLayout_Hugging_Ver] = AttrInfo(className: viewClassName, fullTitle: "ContentHuggingPriority(Vertical)", briefTitle: "V", getterString: "lks_verticalContentHuggingPriority", setterString: "setLks_verticalContentHuggingPriority:", patch: true)
            table[LookinAttr_AutoLayout_Resistance_Hor] = AttrInfo(className: viewClassName, fullTitle: "ContentCompressionResistancePriority(Horizontal)", briefTitle: "H", getterString: "lks_horizontalContentCompressionResistancePriority", setterString: "setLks_horizontalContentCompressionResistancePriority:", patch: true)
            table[LookinAttr_AutoLayout_Resistance_Ver] = AttrInfo(className: viewClassName, fullTitle: "ContentCompressionResistancePriority(Vertical)", briefTitle: "V", getterString: "lks_verticalContentCompressionResistancePriority", setterString: "setLks_verticalContentCompressionResistancePriority:", patch: true)
            table[LookinAttr_AutoLayout_Constraints_Constraints] = AttrInfo(className: viewClassName, getterString: "lks_constraints", setterString: "", typeIfObj: .customObj, hideIfNil: true)
            table[LookinAttr_AutoLayout_IntrinsicSize_Size] = AttrInfo(className: viewClassName, fullTitle: "IntrinsicContentSize", setterString: "")
            table[LookinAttr_ViewLayer_InterationAndMasks_Interaction] = AttrInfo(className: "UIView", fullTitle: "UserInteractionEnabled", getterString: "isUserInteractionEnabled", patch: false)
            table[LookinAttr_ViewLayer_ContentMode_Mode] = AttrInfo(className: "UIView", fullTitle: "ContentMode", enumList: "UIViewContentMode", patch: true)
            table[LookinAttr_ViewLayer_TintColor_Color] = AttrInfo(className: "UIView", fullTitle: "TintColor", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_ViewLayer_TintColor_Mode] = AttrInfo(className: "UIView", fullTitle: "TintAdjustmentMode", enumList: "UIViewTintAdjustmentMode", patch: true)
            table[LookinAttr_LayoutGuide_Identifier_Identifier] = AttrInfo(className: layoutGuideClassName, fullTitle: "Identifier", getterString: "identifier", setterString: "", typeIfObj: .nsString, hideIfNil: true)
            table[LookinAttr_LayoutGuide_LayoutFrame_LayoutFrame] = AttrInfo(className: layoutGuideClassName, fullTitle: "LayoutFrame", getterString: "lks_layoutFrame", setterString: "")
            table[LookinAttr_LayoutGuide_OwningView_OwningView] = AttrInfo(className: layoutGuideClassName, fullTitle: "OwningView", getterString: "lks_owningViewDescription", setterString: "", typeIfObj: .nsString, hideIfNil: true)
            table[LookinAttr_NSCell_Cell_Type] = AttrInfo(className: "NSCell", fullTitle: "CellType", getterString: "type", setterString: "", enumList: "NSCellType")
            table[LookinAttr_NSCell_Cell_State] = AttrInfo(className: "NSCell", fullTitle: "State", getterString: "state", setterString: "", enumList: "NSControlStateValue")
            table[LookinAttr_NSCell_Cell_Enabled] = AttrInfo(className: "NSCell", fullTitle: "Enabled", getterString: "isEnabled", setterString: "")
            table[LookinAttr_NSCell_Cell_Bordered] = AttrInfo(className: "NSCell", fullTitle: "Bordered", getterString: "isBordered", setterString: "")
            table[LookinAttr_NSCell_Cell_Bezeled] = AttrInfo(className: "NSCell", fullTitle: "Bezeled", getterString: "isBezeled", setterString: "")
            table[LookinAttr_NSCell_Cell_Highlighted] = AttrInfo(className: "NSCell", fullTitle: "Highlighted", getterString: "isHighlighted", setterString: "")
            table[LookinAttr_NSCell_Cell_Editable] = AttrInfo(className: "NSCell", fullTitle: "Editable", getterString: "isEditable", setterString: "")
            table[LookinAttr_NSCell_Cell_Selectable] = AttrInfo(className: "NSCell", fullTitle: "Selectable", getterString: "isSelectable", setterString: "")
            table[LookinAttr_NSCell_Cell_Alignment] = AttrInfo(className: "NSCell", fullTitle: "Alignment", getterString: "alignment", setterString: "", enumList: "NSTextAlignment_AppKit")
            table[LookinAttr_NSCell_Cell_ControlSize] = AttrInfo(className: "NSCell", fullTitle: "ControlSize", getterString: "controlSize", setterString: "", enumList: "NSControlSize")
            table[LookinAttr_NSCell_ButtonCell_BezelStyle] = AttrInfo(className: "NSButtonCell", fullTitle: "BezelStyle", getterString: "bezelStyle", setterString: "", enumList: "NSBezelStyle")
            table[LookinAttr_NSCell_ButtonCell_ImagePosition] = AttrInfo(className: "NSButtonCell", fullTitle: "ImagePosition", getterString: "imagePosition", setterString: "", enumList: "NSCellImagePosition")
            table[LookinAttr_NSCell_ButtonCell_ShowsBorderOnlyWhileMouseInside] = AttrInfo(className: "NSButtonCell", fullTitle: "ShowsBorderOnlyWhileMouseInside", getterString: "showsBorderOnlyWhileMouseInside", setterString: "")
            table[LookinAttr_NSCell_TextFieldCell_Placeholder] = AttrInfo(className: "NSTextFieldCell", fullTitle: "Placeholder", getterString: "placeholderString", setterString: "", typeIfObj: .nsString, hideIfNil: true)
            table[LookinAttr_NSCell_TextFieldCell_DrawsBackground] = AttrInfo(className: "NSTextFieldCell", fullTitle: "DrawsBackground", getterString: "drawsBackground", setterString: "")
            table[LookinAttr_NSCell_Content_Title] = AttrInfo(className: "NSCell", fullTitle: "Title", getterString: "title", setterString: "", typeIfObj: .nsString, hideIfNil: true)
            table[LookinAttr_NSCell_Content_FontName] = AttrInfo(className: "NSCell", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", typeIfObj: .nsString, hideIfNil: true)
            table[LookinAttr_NSCell_Content_FontSize] = AttrInfo(className: "NSCell", fullTitle: "FontSize", getterString: "lks_fontSize", setterString: "")
            table[LookinAttr_NSCell_Content_LineBreakMode] = AttrInfo(className: "NSCell", fullTitle: "LineBreakMode", getterString: "lineBreakMode", setterString: "", enumList: "NSLineBreakMode")
            table[LookinAttr_NSCell_Content_Wraps] = AttrInfo(className: "NSCell", fullTitle: "Wraps", getterString: "wraps", setterString: "")
            table[LookinAttr_NSCell_Behavior_Tag] = AttrInfo(className: "NSCell", fullTitle: "Tag", getterString: "tag", setterString: "")
            table[LookinAttr_NSCell_Behavior_Continuous] = AttrInfo(className: "NSCell", fullTitle: "Continuous", getterString: "isContinuous", setterString: "")
            table[LookinAttr_NSCell_Behavior_AllowsMixedState] = AttrInfo(className: "NSCell", fullTitle: "AllowsMixedState", getterString: "allowsMixedState", setterString: "")
            table[LookinAttr_NSCell_Behavior_SendsActionOnEndEditing] = AttrInfo(className: "NSCell", fullTitle: "SendsActionOnEndEditing", getterString: "sendsActionOnEndEditing", setterString: "")
            table[LookinAttr_NSCell_ButtonCell_KeyEquivalent] = AttrInfo(className: "NSButtonCell", fullTitle: "KeyEquivalent", getterString: "keyEquivalent", setterString: "", typeIfObj: .nsString, hideIfNil: true)
            table[LookinAttr_NSCell_ButtonCell_AlternateTitle] = AttrInfo(className: "NSButtonCell", fullTitle: "AlternateTitle", getterString: "alternateTitle", setterString: "", typeIfObj: .nsString, hideIfNil: true)
            table[LookinAttr_NSCell_TextFieldCell_TextColor] = AttrInfo(className: "NSTextFieldCell", fullTitle: "TextColor", getterString: "textColor", setterString: "", typeIfObj: .uiColor, hideIfNil: true)
            table[LookinAttr_NSCell_TextFieldCell_BackgroundColor] = AttrInfo(className: "NSTextFieldCell", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "", typeIfObj: .uiColor, hideIfNil: true)
            table[LookinAttr_NSCell_TextFieldCell_BezelStyle] = AttrInfo(className: "NSTextFieldCell", fullTitle: "BezelStyle", getterString: "bezelStyle", setterString: "", enumList: "NSTextFieldBezelStyle")
            table[LookinAttr_ViewLayer_Tag_Tag] = AttrInfo(className: viewClassName, fullTitle: "Tag", briefTitle: "", patch: false)
            table[LookinAttr_ViewLayer_Visibility_Hidden] = AttrInfo(className: "CALayer", fullTitle: "Hidden", getterString: "isHidden", patch: true)
            table[LookinAttr_ViewLayer_Visibility_Opacity] = AttrInfo(className: "CALayer", fullTitle: "Opacity / Alpha", getterString: "opacity", setterString: "setOpacity:", patch: true)
            table[LookinAttr_ViewLayer_InterationAndMasks_MasksToBounds] = AttrInfo(className: "CALayer", fullTitle: "MasksToBounds / ClipsToBounds", briefTitle: "MasksToBounds", getterString: "masksToBounds", setterString: "setMasksToBounds:", patch: true)
            table[LookinAttr_ViewLayer_Corner_Radius] = AttrInfo(className: "CALayer", fullTitle: "CornerRadius", briefTitle: "", patch: true)
            table[LookinAttr_ViewLayer_BgColor_BgColor] = AttrInfo(className: "CALayer", fullTitle: "BackgroundColor", getterString: "lks_backgroundColor", setterString: "setLks_backgroundColor:", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_ViewLayer_Border_Color] = AttrInfo(className: "CALayer", fullTitle: "BorderColor", getterString: "lks_borderColor", setterString: "setLks_borderColor:", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_ViewLayer_Border_Width] = AttrInfo(className: "CALayer", fullTitle: "BorderWidth", patch: true)
            table[LookinAttr_ViewLayer_Shadow_Color] = AttrInfo(className: "CALayer", fullTitle: "ShadowColor", getterString: "lks_shadowColor", setterString: "setLks_shadowColor:", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_ViewLayer_Shadow_Opacity] = AttrInfo(className: "CALayer", fullTitle: "ShadowOpacity", briefTitle: "Opacity", patch: true)
            table[LookinAttr_ViewLayer_Shadow_Radius] = AttrInfo(className: "CALayer", fullTitle: "ShadowRadius", briefTitle: "Radius", patch: true)
            table[LookinAttr_ViewLayer_Shadow_OffsetW] = AttrInfo(className: "CALayer", fullTitle: "ShadowOffsetWidth", briefTitle: "OffsetW", getterString: "lks_shadowOffsetWidth", setterString: "setLks_shadowOffsetWidth:", patch: true)
            table[LookinAttr_ViewLayer_Shadow_OffsetH] = AttrInfo(className: "CALayer", fullTitle: "ShadowOffsetHeight", briefTitle: "OffsetH", getterString: "lks_shadowOffsetHeight", setterString: "setLks_shadowOffsetHeight:", patch: true)
            table[LookinAttr_UIStackView_Axis_Axis] = AttrInfo(className: "UIStackView", fullTitle: "Axis", enumList: "UILayoutConstraintAxis", patch: true)
            table[LookinAttr_UIStackView_Distribution_Distribution] = AttrInfo(className: "UIStackView", fullTitle: "Distribution", enumList: "UIStackViewDistribution", patch: true)
            table[LookinAttr_UIStackView_Alignment_Alignment] = AttrInfo(className: "UIStackView", fullTitle: "Alignment", enumList: "UIStackViewAlignment", patch: true)
            table[LookinAttr_UIStackView_Spacing_Spacing] = AttrInfo(className: "UIStackView", fullTitle: "Spacing", patch: true)
            table[LookinAttr_UIVisualEffectView_Style_Style] = AttrInfo(className: "UIVisualEffectView", getterString: "lks_blurEffectStyleNumber", setterString: "setLks_blurEffectStyleNumber:", typeIfObj: .customObj, enumList: "UIBlurEffectStyle", patch: true, hideIfNil: true)
            table[LookinAttr_UIVisualEffectView_QMUIForegroundColor_Color] = AttrInfo(className: "QMUIVisualEffectView", fullTitle: "ForegroundColor", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_UIImageView_Name_Name] = AttrInfo(className: "UIImageView", fullTitle: "ImageName", getterString: "lks_imageSourceName", setterString: "", typeIfObj: .nsString, hideIfNil: true)
            table[LookinAttr_UIImageView_Open_Open] = AttrInfo(className: "UIImageView", getterString: "lks_imageViewOidIfHasImage", setterString: "", typeIfObj: .customObj, hideIfNil: true)
            table[LookinAttr_UILabel_Text_Text] = AttrInfo(className: "UILabel", fullTitle: "Text", typeIfObj: .nsString, patch: true)
            table[LookinAttr_UILabel_NumberOfLines_NumberOfLines] = AttrInfo(className: "UILabel", fullTitle: "NumberOfLines", briefTitle: "", patch: true)
            table[LookinAttr_UILabel_Font_Size] = AttrInfo(className: "UILabel", fullTitle: "FontSize", briefTitle: "FontSize", getterString: "lks_fontSize", setterString: "setLks_fontSize:", patch: true)
            table[LookinAttr_UILabel_Font_Name] = AttrInfo(className: "UILabel", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", typeIfObj: .nsString, patch: false)
            table[LookinAttr_UILabel_TextColor_Color] = AttrInfo(className: "UILabel", fullTitle: "TextColor", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_UILabel_Alignment_Alignment] = AttrInfo(className: "UILabel", fullTitle: "TextAlignment", enumList: "NSTextAlignment", patch: true)
            table[LookinAttr_UILabel_BreakMode_Mode] = AttrInfo(className: "UILabel", fullTitle: "LineBreakMode", enumList: "NSLineBreakMode", patch: true)
            table[LookinAttr_UILabel_CanAdjustFont_CanAdjustFont] = AttrInfo(className: "UILabel", fullTitle: "AdjustsFontSizeToFitWidth", patch: true)
            table[LookinAttr_UIControl_EnabledSelected_Enabled] = AttrInfo(className: "UIControl", fullTitle: "Enabled", getterString: "isEnabled", patch: false)
            table[LookinAttr_UIControl_EnabledSelected_Selected] = AttrInfo(className: "UIControl", fullTitle: "Selected", getterString: "isSelected", patch: true)
            table[LookinAttr_UIControl_VerAlignment_Alignment] = AttrInfo(className: "UIControl", fullTitle: "ContentVerticalAlignment", enumList: "UIControlContentVerticalAlignment", patch: true)
            table[LookinAttr_UIControl_HorAlignment_Alignment] = AttrInfo(className: "UIControl", fullTitle: "ContentHorizontalAlignment", enumList: "UIControlContentHorizontalAlignment", patch: true)
            table[LookinAttr_UIControl_QMUIOutsideEdge_Edge] = AttrInfo(className: "UIControl", fullTitle: "qmui_outsideEdge")
            table[LookinAttr_UIButton_ContentInsets_Insets] = AttrInfo(className: "UIButton", fullTitle: "ContentEdgeInsets", patch: true)
            table[LookinAttr_UIButton_TitleInsets_Insets] = AttrInfo(className: "UIButton", fullTitle: "TitleEdgeInsets", patch: true)
            table[LookinAttr_UIButton_ImageInsets_Insets] = AttrInfo(className: "UIButton", fullTitle: "ImageEdgeInsets", patch: true)
            table[LookinAttr_UIScrollView_Offset_Offset] = AttrInfo(className: "UIScrollView", fullTitle: "ContentOffset", patch: true)
            table[LookinAttr_UIScrollView_ContentSize_Size] = AttrInfo(className: "UIScrollView", fullTitle: "ContentSize", patch: true)
            table[LookinAttr_UIScrollView_ContentInset_Inset] = AttrInfo(className: "UIScrollView", fullTitle: "ContentInset", patch: true)
            table[LookinAttr_UIScrollView_QMUIInitialInset_Inset] = AttrInfo(className: "UIScrollView", fullTitle: "qmui_initialContentInset", patch: true)
            table[LookinAttr_UIScrollView_AdjustedInset_Inset] = AttrInfo(className: "UIScrollView", fullTitle: "AdjustedContentInset", setterString: "", osVersion: 11)
            table[LookinAttr_UIScrollView_Behavior_Behavior] = AttrInfo(className: "UIScrollView", fullTitle: "ContentInsetAdjustmentBehavior", enumList: "UIScrollViewContentInsetAdjustmentBehavior", patch: true, osVersion: 11)
            table[LookinAttr_UIScrollView_IndicatorInset_Inset] = AttrInfo(className: "UIScrollView", fullTitle: "ScrollIndicatorInsets", patch: false)
            table[LookinAttr_UIScrollView_ScrollPaging_ScrollEnabled] = AttrInfo(className: "UIScrollView", fullTitle: "ScrollEnabled", getterString: "isScrollEnabled", patch: false)
            table[LookinAttr_UIScrollView_ScrollPaging_PagingEnabled] = AttrInfo(className: "UIScrollView", fullTitle: "PagingEnabled", getterString: "isPagingEnabled", patch: false)
            table[LookinAttr_UIScrollView_Bounce_Ver] = AttrInfo(className: "UIScrollView", fullTitle: "AlwaysBounceVertical", briefTitle: "Vertical", patch: false)
            table[LookinAttr_UIScrollView_Bounce_Hor] = AttrInfo(className: "UIScrollView", fullTitle: "AlwaysBounceHorizontal", briefTitle: "Horizontal", patch: false)
            table[LookinAttr_UIScrollView_ShowsIndicator_Hor] = AttrInfo(className: "UIScrollView", fullTitle: "ShowsHorizontalScrollIndicator", briefTitle: "Horizontal", patch: false)
            table[LookinAttr_UIScrollView_ShowsIndicator_Ver] = AttrInfo(className: "UIScrollView", fullTitle: "ShowsVerticalScrollIndicator", briefTitle: "Vertical", patch: false)
            table[LookinAttr_UIScrollView_ContentTouches_Delay] = AttrInfo(className: "UIScrollView", fullTitle: "DelaysContentTouches", patch: false)
            table[LookinAttr_UIScrollView_ContentTouches_CanCancel] = AttrInfo(className: "UIScrollView", fullTitle: "CanCancelContentTouches", patch: false)
            table[LookinAttr_UIScrollView_Zoom_MinScale] = AttrInfo(className: "UIScrollView", fullTitle: "MinimumZoomScale", briefTitle: "MinScale", patch: false)
            table[LookinAttr_UIScrollView_Zoom_MaxScale] = AttrInfo(className: "UIScrollView", fullTitle: "MaximumZoomScale", briefTitle: "MaxScale", patch: false)
            table[LookinAttr_UIScrollView_Zoom_Scale] = AttrInfo(className: "UIScrollView", fullTitle: "ZoomScale", briefTitle: "Scale", patch: true)
            table[LookinAttr_UIScrollView_Zoom_Bounce] = AttrInfo(className: "UIScrollView", fullTitle: "BouncesZoom", patch: false)
            table[LookinAttr_UITableView_Style_Style] = AttrInfo(className: "UITableView", fullTitle: "Style", setterString: "", enumList: "UITableViewStyle", patch: true)
            table[LookinAttr_UITableView_SectionsNumber_Number] = AttrInfo(className: "UITableView", fullTitle: "NumberOfSections", setterString: "", patch: true)
            table[LookinAttr_UITableView_RowsNumber_Number] = AttrInfo(className: "UITableView", getterString: "lks_numberOfRows", setterString: "", typeIfObj: .customObj)
            table[LookinAttr_UITableView_SeparatorInset_Inset] = AttrInfo(className: "UITableView", fullTitle: "SeparatorInset", patch: false)
            table[LookinAttr_UITableView_SeparatorColor_Color] = AttrInfo(className: "UITableView", fullTitle: "SeparatorColor", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_UITableView_SeparatorStyle_Style] = AttrInfo(className: "UITableView", fullTitle: "SeparatorStyle", enumList: "UITableViewCellSeparatorStyle", patch: true)
            table[LookinAttr_UITextView_Text_Text] = AttrInfo(className: "UITextView", fullTitle: "Text", typeIfObj: .nsString, patch: true)
            table[LookinAttr_UITextView_Font_Name] = AttrInfo(className: "UITextView", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", typeIfObj: .nsString, patch: false)
            table[LookinAttr_UITextView_Font_Size] = AttrInfo(className: "UITextView", fullTitle: "FontSize", getterString: "lks_fontSize", setterString: "setLks_fontSize:", patch: true)
            table[LookinAttr_UITextView_Basic_Editable] = AttrInfo(className: "UITextView", fullTitle: "Editable", getterString: "isEditable", patch: false)
            table[LookinAttr_UITextView_Basic_Selectable] = AttrInfo(className: "UITextView", fullTitle: "Selectable", getterString: "isSelectable", patch: false)
            table[LookinAttr_UITextView_TextColor_Color] = AttrInfo(className: "UITextView", fullTitle: "TextColor", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_UITextView_Alignment_Alignment] = AttrInfo(className: "UITextView", fullTitle: "TextAlignment", enumList: "NSTextAlignment", patch: true)
            table[LookinAttr_UITextView_ContainerInset_Inset] = AttrInfo(className: "UITextView", fullTitle: "TextContainerInset", patch: true)
            table[LookinAttr_UITextField_Font_Name] = AttrInfo(className: "UITextField", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", typeIfObj: .nsString, patch: false)
            table[LookinAttr_UITextField_Font_Size] = AttrInfo(className: "UITextField", fullTitle: "FontSize", getterString: "lks_fontSize", setterString: "setLks_fontSize:", patch: true)
            table[LookinAttr_UITextField_TextColor_Color] = AttrInfo(className: "UITextField", fullTitle: "TextColor", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_UITextField_Alignment_Alignment] = AttrInfo(className: "UITextField", fullTitle: "TextAlignment", enumList: "NSTextAlignment", patch: true)
            table[LookinAttr_UITextField_Text_Text] = AttrInfo(className: "UITextField", fullTitle: "Text", typeIfObj: .nsString, patch: true)
            table[LookinAttr_UITextField_Placeholder_Placeholder] = AttrInfo(className: "UITextField", fullTitle: "Placeholder", typeIfObj: .nsString, patch: true)
            table[LookinAttr_UITextField_Clears_ClearsOnBeginEditing] = AttrInfo(className: "UITextField", fullTitle: "ClearsOnBeginEditing", patch: false)
            table[LookinAttr_UITextField_Clears_ClearsOnInsertion] = AttrInfo(className: "UITextField", fullTitle: "ClearsOnInsertion", patch: false)
            table[LookinAttr_UITextField_CanAdjustFont_CanAdjustFont] = AttrInfo(className: "UITextField", fullTitle: "AdjustsFontSizeToFitWidth", patch: true)
            table[LookinAttr_UITextField_CanAdjustFont_MinSize] = AttrInfo(className: "UITextField", fullTitle: "MinimumFontSize", patch: true)
            table[LookinAttr_UITextField_ClearButtonMode_Mode] = AttrInfo(className: "UITextField", fullTitle: "ClearButtonMode", enumList: "UITextFieldViewMode", patch: false)
            table[LookinAttr_NSImageView_Name_Name] = AttrInfo(className: "NSImageView", fullTitle: "ImageName", getterString: "lks_imageSourceName", setterString: "", typeIfObj: .nsString, hideIfNil: true)
            table[LookinAttr_NSImageView_Open_Open] = AttrInfo(className: "NSImageView", getterString: "lks_imageViewOidIfHasImage", setterString: "", typeIfObj: .customObj, hideIfNil: true)
            table[LookinAttr_NSImageView_Scaling_ImageScaling] = AttrInfo(className: "NSImageView", fullTitle: "ImageScaling", enumList: "NSImageScaling", patch: true)
            table[LookinAttr_NSImageView_Scaling_ImageAlignment] = AttrInfo(className: "NSImageView", fullTitle: "ImageAlignment", enumList: "NSImageAlignment", patch: true)
            table[LookinAttr_NSImageView_Scaling_ImageFrameStyle] = AttrInfo(className: "NSImageView", fullTitle: "ImageFrameStyle", enumList: "NSImageFrameStyle", patch: true)
            table[LookinAttr_NSImageView_Behavior_Animates] = AttrInfo(className: "NSImageView", fullTitle: "Animates", patch: true)
            table[LookinAttr_NSImageView_Behavior_Editable] = AttrInfo(className: "NSImageView", fullTitle: "Editable", getterString: "isEditable", patch: true)
            table[LookinAttr_NSImageView_ContentTintColor_ContentTintColor] = AttrInfo(className: "NSImageView", fullTitle: "ContentTintColor", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_NSControl_State_Enabled] = AttrInfo(className: "NSControl", fullTitle: "Enabled", getterString: "isEnabled", patch: true)
            table[LookinAttr_NSControl_State_Highlighted] = AttrInfo(className: "NSControl", fullTitle: "Highlighted", getterString: "isHighlighted", patch: true)
            table[LookinAttr_NSControl_State_Continuous] = AttrInfo(className: "NSControl", fullTitle: "Continuous", getterString: "isContinuous", patch: false)
            table[LookinAttr_NSControl_ControlSize_Size] = AttrInfo(className: "NSControl", fullTitle: "ControlSize", enumList: "NSControlSize", patch: true)
            table[LookinAttr_NSControl_Font_Name] = AttrInfo(className: "NSControl", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", typeIfObj: .nsString, patch: false)
            table[LookinAttr_NSControl_Font_Size] = AttrInfo(className: "NSControl", fullTitle: "FontSize", getterString: "lks_fontSize", setterString: "setLks_fontSize:", patch: true)
            table[LookinAttr_NSControl_Alignment_Alignment] = AttrInfo(className: "NSControl", fullTitle: "Alignment", enumList: "NSTextAlignment_AppKit", patch: true)
            table[LookinAttr_NSControl_Misc_WritingDirection] = AttrInfo(className: "NSControl", fullTitle: "BaseWritingDirection", enumList: "NSWritingDirection", patch: false)
            table[LookinAttr_NSControl_Misc_IgnoresMultiClick] = AttrInfo(className: "NSControl", fullTitle: "IgnoresMultiClick", patch: false)
            table[LookinAttr_NSControl_Misc_UsesSingleLineMode] = AttrInfo(className: "NSControl", fullTitle: "UsesSingleLineMode", patch: false)
            table[LookinAttr_NSControl_Misc_AllowsExpansionToolTips] = AttrInfo(className: "NSControl", fullTitle: "AllowsExpansionToolTips", patch: false)
            table[LookinAttr_NSControl_Value_StringValue] = AttrInfo(className: "NSControl", fullTitle: "StringValue", typeIfObj: .nsString, patch: true)
            table[LookinAttr_NSControl_Value_IntValue] = AttrInfo(className: "NSControl", fullTitle: "IntValue", patch: true)
            table[LookinAttr_NSControl_Value_IntegerValue] = AttrInfo(className: "NSControl", fullTitle: "IntegerValue", patch: true)
            table[LookinAttr_NSControl_Value_FloatValue] = AttrInfo(className: "NSControl", fullTitle: "FloatValue", patch: true)
            table[LookinAttr_NSControl_Value_DoubleValue] = AttrInfo(className: "NSControl", fullTitle: "DoubleValue", patch: true)
            table[LookinAttr_NSButton_ButtonType_ButtonType] = AttrInfo(className: "NSButton", fullTitle: "ButtonType", getterString: "lks_buttonType", enumList: "NSButtonType", patch: true)
            table[LookinAttr_NSButton_Title_Title] = AttrInfo(className: "NSButton", fullTitle: "Title", typeIfObj: .nsString, patch: true)
            table[LookinAttr_NSButton_Title_AlernateTitle] = AttrInfo(className: "NSButton", fullTitle: "AlternateTitle", typeIfObj: .nsString, patch: true)
            table[LookinAttr_NSButton_BezelStyle_BezelStyle] = AttrInfo(className: "NSButton", fullTitle: "BezelStyle", enumList: "NSBezelStyle", patch: true)
            table[LookinAttr_NSButton_Bordered_Bordered] = AttrInfo(className: "NSButton", fullTitle: "Bordered", getterString: "isBordered", patch: true)
            table[LookinAttr_NSButton_Transparent_Transparent] = AttrInfo(className: "NSButton", fullTitle: "Transparent", getterString: "isTransparent", patch: true)
            table[LookinAttr_NSButton_BezelColor_BezelColor] = AttrInfo(className: "NSButton", fullTitle: "BezelColor", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_NSButton_ContentTintColor_ContentTintColor] = AttrInfo(className: "NSButton", fullTitle: "ContentTintColor", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_NSButton_Misc_ShowsBorderOnlyWhileMouseInside] = AttrInfo(className: "NSButton", fullTitle: "ShowsBorderOnlyWhileMouseInside", patch: true)
            table[LookinAttr_NSButton_Misc_MaxAcceleratorLevel] = AttrInfo(className: "NSButton", fullTitle: "MaxAcceleratorLevel", patch: true)
            // Derived getter would be -springLoaded; the property is -isSpringLoaded.
            table[LookinAttr_NSButton_Misc_SpringLoaded] = AttrInfo(className: "NSButton", fullTitle: "SpringLoaded", getterString: "isSpringLoaded", patch: true)
            table[LookinAttr_NSButton_Misc_HasDestructiveAction] = AttrInfo(className: "NSButton", fullTitle: "HasDestructiveAction", patch: true)
            table[LookinAttr_NSScrollView_ContentOffset_Offset] = AttrInfo(className: "NSScrollView", fullTitle: "ContentOffset", getterString: "lks_contentOffset", setterString: "lks_setContentOffset:", patch: true)
            table[LookinAttr_NSScrollView_ContentSize_Size] = AttrInfo(className: "NSScrollView", fullTitle: "ContentSize", getterString: "lks_contentSize", setterString: "lks_setContentSize:", patch: true)
            table[LookinAttr_NSScrollView_ContentInset_ContentInset] = AttrInfo(className: "NSScrollView", fullTitle: "ContentInset", patch: true)
            table[LookinAttr_NSScrollView_ContentInset_AutomaticallyAdjustsContentInsets] = AttrInfo(className: "NSScrollView", fullTitle: "AutomaticallyAdjustsContentInsets", patch: true)
            table[LookinAttr_NSScrollView_BorderType_BorderType] = AttrInfo(className: "NSScrollView", fullTitle: "BorderType", enumList: "NSBorderType", patch: true)
            table[LookinAttr_NSScrollView_Scroller_Horizontal] = AttrInfo(className: "NSScrollView", fullTitle: "HasHorizontalScroller", patch: true)
            table[LookinAttr_NSScrollView_Scroller_Vertical] = AttrInfo(className: "NSScrollView", fullTitle: "HasVerticalScroller", patch: true)
            table[LookinAttr_NSScrollView_Scroller_AutohidesScrollers] = AttrInfo(className: "NSScrollView", fullTitle: "AutohidesScrollers", patch: true)
            table[LookinAttr_NSScrollView_Scroller_ScrollerStyle] = AttrInfo(className: "NSScrollView", fullTitle: "ScrollerStyle", enumList: "NSScrollerStyle", patch: true)
            table[LookinAttr_NSScrollView_Scroller_ScrollerKnobStyle] = AttrInfo(className: "NSScrollView", fullTitle: "ScrollerKnobStyle", enumList: "NSScrollerKnobStyle", patch: true)
            table[LookinAttr_NSScrollView_Scroller_ScrollerInsets] = AttrInfo(className: "NSScrollView", fullTitle: "ScrollerInsets", patch: true)
            table[LookinAttr_NSScrollView_Ruler_Horizontal] = AttrInfo(className: "NSScrollView", fullTitle: "HasHorizontalRuler", patch: true)
            table[LookinAttr_NSScrollView_Ruler_Vertical] = AttrInfo(className: "NSScrollView", fullTitle: "HasVerticalRuler", patch: true)
            table[LookinAttr_NSScrollView_Ruler_Visible] = AttrInfo(className: "NSScrollView", fullTitle: "RulersVisible", patch: true)
            // briefTitle is display-only and never crosses the wire. These six
            // sit three-to-a-row with the label inside the field, so the section
            // title carries the meaning ("LineScroll") and the field only marks
            // the axis — the same shape as the scroller inset row above.
            table[LookinAttr_NSScrollView_LineScroll_Horizontal] = AttrInfo(className: "NSScrollView", fullTitle: "HorizontalLineScroll", briefTitle: "H", patch: true)
            table[LookinAttr_NSScrollView_LineScroll_Vertical] = AttrInfo(className: "NSScrollView", fullTitle: "VerticalLineScroll", briefTitle: "V", patch: true)
            table[LookinAttr_NSScrollView_LineScroll_LineScroll] = AttrInfo(className: "NSScrollView", fullTitle: "LineScroll", briefTitle: "⇄", patch: true)
            table[LookinAttr_NSScrollView_PageScroll_Horizontal] = AttrInfo(className: "NSScrollView", fullTitle: "HorizontalPageScroll", briefTitle: "H", patch: true)
            table[LookinAttr_NSScrollView_PageScroll_Vertical] = AttrInfo(className: "NSScrollView", fullTitle: "VerticalPageScroll", briefTitle: "V", patch: true)
            table[LookinAttr_NSScrollView_PageScroll_PageScroll] = AttrInfo(className: "NSScrollView", fullTitle: "PageScroll", briefTitle: "⇄", patch: true)
            table[LookinAttr_NSScrollView_ScrollElasiticity_Horizontal] = AttrInfo(className: "NSScrollView", fullTitle: "HorizontalScrollElasticity", enumList: "NSScrollElasticity", patch: true)
            table[LookinAttr_NSScrollView_ScrollElasiticity_Vertical] = AttrInfo(className: "NSScrollView", fullTitle: "VerticalScrollElasticity", enumList: "NSScrollElasticity", patch: true)
            table[LookinAttr_NSScrollView_Misc_ScrollsDynamically] = AttrInfo(className: "NSScrollView", fullTitle: "ScrollsDynamically", patch: true)
            table[LookinAttr_NSScrollView_Misc_UsesPredominantAxisScrolling] = AttrInfo(className: "NSScrollView", fullTitle: "UsesPredominantAxisScrolling", patch: true)
            table[LookinAttr_NSScrollView_Magnification_AllowsMagnification] = AttrInfo(className: "NSScrollView", fullTitle: "AllowsMagnification", patch: true)
            // Three to a row under the AllowsMagnification switch; the section
            // title already says "Magnification", so the fields only need to
            // say which of the three values they are.
            table[LookinAttr_NSScrollView_Magnification_Magnification] = AttrInfo(className: "NSScrollView", fullTitle: "Magnification", briefTitle: "Current", patch: true)
            // Explicit getter/setter: the derived names would be
            // -maximunMagnification / -minimumMagnification, and NSScrollView
            // spells them -maxMagnification / -minMagnification. Deriving them
            // produced selectors nobody responds to, so both rows silently read
            // as nil and never appeared in the dashboard at all.
            table[LookinAttr_NSScrollView_Magnification_Max] = AttrInfo(className: "NSScrollView", fullTitle: "MaximumMagnification", briefTitle: "Max", getterString: "maxMagnification", setterString: "setMaxMagnification:", patch: true)
            table[LookinAttr_NSScrollView_Magnification_Min] = AttrInfo(className: "NSScrollView", fullTitle: "MinimumMagnification", briefTitle: "Min", getterString: "minMagnification", setterString: "setMinMagnification:", patch: true)
            table[LookinAttr_NSTableView_AllowsColumnReordering_AllowsColumnReordering] = AttrInfo(className: "NSTableView", fullTitle: "AllowsColumnReordering", patch: true)
            table[LookinAttr_NSTableView_AllowsColumnResizing_AllowsColumnResizing] = AttrInfo(className: "NSTableView", fullTitle: "AllowsColumnResizing", patch: true)
            table[LookinAttr_NSTableView_ColumnAutoresizingStyle_ColumnAutoresizingStyle] = AttrInfo(className: "NSTableView", fullTitle: "ColumnAutoresizingStyle", enumList: "NSTableViewColumnAutoresizingStyle", patch: true)
            table[LookinAttr_NSTableView_GridStyleMask_GridStyleMask] = AttrInfo(className: "NSTableView", fullTitle: "GridStyleMask", enumList: "NSTableViewGridLineStyle", patch: true)
            table[LookinAttr_NSTableView_IntercellSpacing_IntercellSpacing] = AttrInfo(className: "NSTableView", fullTitle: "IntercellSpacing", patch: true)
            table[LookinAttr_NSTableView_UseAlternatingRowBackgroundColors_UseAlternatingRowBackgroundColors] = AttrInfo(className: "NSTableView", fullTitle: "UsesAlternatingRowBackgroundColors", patch: true)
            table[LookinAttr_NSTableView_GridColor_GridColor] = AttrInfo(className: "NSTableView", fullTitle: "GridColor", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_NSTableView_RowSizeStyle_RowSizeStyle] = AttrInfo(className: "NSTableView", fullTitle: "RowSizeStyle", enumList: "NSTableViewRowSizeStyle", patch: true)
            table[LookinAttr_NSTableView_RowHeight_RowHeight] = AttrInfo(className: "NSTableView", fullTitle: "RowHeight", patch: true)
            table[LookinAttr_NSTableView_NumberOfRows_NumberOfRows] = AttrInfo(className: "NSTableView", fullTitle: "NumberOfRows", setterString: "", patch: true)
            table[LookinAttr_NSTableView_NumberOfColumns_NumberOfColumns] = AttrInfo(className: "NSTableView", fullTitle: "NumberOfColumns", setterString: "", patch: true)
            table[LookinAttr_NSTableView_VerticalMotionCanBeginDrag_VerticalMotionCanBeginDrag] = AttrInfo(className: "NSTableView", fullTitle: "VerticalMotionCanBeginDrag", patch: true)
            table[LookinAttr_NSTableView_AllowsMultipleSelection_AllowsMultipleSelection] = AttrInfo(className: "NSTableView", fullTitle: "AllowsMultipleSelection", patch: true)
            table[LookinAttr_NSTableView_AllowsEmptySelection_AllowsEmptySelection] = AttrInfo(className: "NSTableView", fullTitle: "AllowsEmptySelection", patch: true)
            table[LookinAttr_NSTableView_AllowsColumnSelection_AllowsColumnSelection] = AttrInfo(className: "NSTableView", fullTitle: "AllowsColumnSelection", patch: true)
            table[LookinAttr_NSTableView_AllowsTypeSelect_AllowsTypeSelect] = AttrInfo(className: "NSTableView", fullTitle: "AllowsTypeSelect", patch: true)
            table[LookinAttr_NSTableView_SelectionHighlightStyle_SelectionHighlightStyle] = AttrInfo(className: "NSTableView", fullTitle: "SelectionHighlightStyle", enumList: "NSTableViewSelectionHighlightStyle", patch: true)
            table[LookinAttr_NSTableView_DraggingDestinationFeedbackStyle_DraggingDestinationFeedbackStyle] = AttrInfo(className: "NSTableView", fullTitle: "DraggingDestinationFeedbackStyle", enumList: "NSTableViewDraggingDestinationFeedbackStyle", patch: true)
            // NSTableView spells this usesAutomaticRowHeights, so both the
            // derived getter and the derived setter miss.
            table[LookinAttr_NSTableView_AutomaticRowHeights_AutomaticRowHeights] = AttrInfo(className: "NSTableView", fullTitle: "AutomaticRowHeights", getterString: "usesAutomaticRowHeights", setterString: "setUsesAutomaticRowHeights:", patch: true)
            table[LookinAttr_NSTableView_AutosaveName_AutosaveName] = AttrInfo(className: "NSTableView", fullTitle: "AutosaveName", patch: true)
            table[LookinAttr_NSTableView_AutosaveTableColumns_AutosaveTableColumns] = AttrInfo(className: "NSTableView", fullTitle: "AutosaveTableColumns", patch: true)
            table[LookinAttr_NSTableView_FloatsGroupRows_FloatsGroupRows] = AttrInfo(className: "NSTableView", fullTitle: "FloatsGroupRows", patch: true)
            table[LookinAttr_NSTableView_RowActionsVisible_RowActionsVisible] = AttrInfo(className: "NSTableView", fullTitle: "RowActionsVisible", patch: true)
            table[LookinAttr_NSTableView_UsesStaticContents_UsesStaticContents] = AttrInfo(className: "NSTableView", fullTitle: "UsesStaticContents", patch: true)
            table[LookinAttr_NSTableView_UserInterfaceLayoutDirection_UserInterfaceLayoutDirection] = AttrInfo(className: "NSTableView", fullTitle: "UserInterfaceLayoutDirection", enumList: "NSUserInterfaceLayoutDirection", patch: true)
            table[LookinAttr_NSTableView_Style_Style] = AttrInfo(className: "NSTableView", fullTitle: "Style", enumList: "NSTableViewStyle", patch: true)
            table[LookinAttr_NSTextView_Font_Name] = AttrInfo(className: "NSTextView", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", typeIfObj: .nsString, patch: false)
            table[LookinAttr_NSTextView_Font_Size] = AttrInfo(className: "NSTextView", fullTitle: "FontSize", getterString: "lks_fontSize", setterString: "setLks_fontSize:", patch: true)
            table[LookinAttr_NSTextView_Basic_Editable] = AttrInfo(className: "NSTextView", fullTitle: "Editable", getterString: "isEditable", patch: false)
            table[LookinAttr_NSTextView_Basic_Selectable] = AttrInfo(className: "NSTextView", fullTitle: "Selectable", getterString: "isSelectable", patch: false)
            table[LookinAttr_NSTextView_Basic_RichText] = AttrInfo(className: "NSTextView", fullTitle: "RichText", getterString: "isRichText", patch: false)
            table[LookinAttr_NSTextView_Basic_FieldEditor] = AttrInfo(className: "NSTextView", fullTitle: "FieldEditor", getterString: "isFieldEditor", patch: false)
            table[LookinAttr_NSTextView_Basic_ImportsGraphics] = AttrInfo(className: "NSTextView", fullTitle: "ImportsGraphics", patch: false)
            table[LookinAttr_NSTextView_String_String] = AttrInfo(className: "NSTextView", fullTitle: "String", typeIfObj: .nsString, patch: true)
            table[LookinAttr_NSTextView_TextColor_Color] = AttrInfo(className: "NSTextView", fullTitle: "TextColor", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_NSTextView_Alignment_Alignment] = AttrInfo(className: "NSTextView", fullTitle: "Alignment", enumList: "NSTextAlignment_AppKit", patch: true)
            table[LookinAttr_NSTextView_ContainerInset_Inset] = AttrInfo(className: "NSTextView", fullTitle: "TextContainerInset", patch: true)
            table[LookinAttr_NSTextView_BaseWritingDirection_BaseWritingDirection] = AttrInfo(className: "NSTextView", fullTitle: "BaseWritingDirection", enumList: "NSWritingDirection", patch: false)
            table[LookinAttr_NSTextView_MaxSize_MaxSize] = AttrInfo(className: "NSTextView", fullTitle: "MaxSize", patch: true)
            table[LookinAttr_NSTextView_MinSize_MinSize] = AttrInfo(className: "NSTextView", fullTitle: "MinSize", patch: true)
            // Derived getter would be -horizontallyResizable; it is -isHorizontallyResizable.
            table[LookinAttr_NSTextView_Resizable_Horizontal] = AttrInfo(className: "NSTextView", fullTitle: "HorizontallyResizable", getterString: "isHorizontallyResizable", patch: false)
            // Derived getter would be -verticallyResizable; it is -isVerticallyResizable.
            table[LookinAttr_NSTextView_Resizable_Vertical] = AttrInfo(className: "NSTextView", fullTitle: "VerticallyResizable", getterString: "isVerticallyResizable", patch: false)
            table[LookinAttr_NSTextField_Bordered_Bordered] = AttrInfo(className: "NSTextField", fullTitle: "Bordered", getterString: "isBordered", patch: false)
            table[LookinAttr_NSTextField_Bezeled_Bezeled] = AttrInfo(className: "NSTextField", fullTitle: "Bezeled", getterString: "isBezeled", patch: false)
            table[LookinAttr_NSTextField_Editable_Editable] = AttrInfo(className: "NSTextField", fullTitle: "Editable", getterString: "isEditable", patch: false)
            table[LookinAttr_NSTextField_Selectable_Selectable] = AttrInfo(className: "NSTextField", fullTitle: "Selectable", getterString: "isSelectable", patch: false)
            table[LookinAttr_NSTextField_DrawsBackground_DrawsBackground] = AttrInfo(className: "NSTextField", fullTitle: "DrawsBackground", patch: true)
            table[LookinAttr_NSTextField_BezelStyle_BezelStyle] = AttrInfo(className: "NSTextField", fullTitle: "BezelStyle", enumList: "NSTextFieldBezelStyle", patch: true)
            table[LookinAttr_NSTextField_PreferredMaxLayoutWidth_PreferredMaxLayoutWidth] = AttrInfo(className: "NSTextField", fullTitle: "PreferredMaxLayoutWidth", patch: true)
            table[LookinAttr_NSTextField_MaximumNumberOfLines_MaximumNumberOfLines] = AttrInfo(className: "NSTextField", fullTitle: "MaximumNumberOfLines", patch: true)
            table[LookinAttr_NSTextField_AllowsDefaultTighteningForTruncation_AllowsDefaultTighteningForTruncation] = AttrInfo(className: "NSTextField", fullTitle: "AllowsDefaultTighteningForTruncation", patch: true)
            table[LookinAttr_NSTextField_LineBreakStrategy_LineBreakStrategy] = AttrInfo(className: "NSTextField", fullTitle: "LineBreakStrategy", enumList: "NSLineBreakStrategy", patch: true)
            table[LookinAttr_NSTextField_Placeholder_Placeholder] = AttrInfo(className: "NSTextField", fullTitle: "PlaceholderString", typeIfObj: .nsString, patch: true)
            table[LookinAttr_NSTextField_TextColor_Color] = AttrInfo(className: "NSTextField", fullTitle: "TextColor", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_NSTextField_BackgroundColor_Color] = AttrInfo(className: "NSTextField", fullTitle: "BackgroundColor", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_NSTextField_AllowsEditingTextAttributes_AllowsEditingTextAttributes] = AttrInfo(className: "NSTextField", fullTitle: "AllowsEditingTextAttributes", patch: true)
            table[LookinAttr_NSTextField_ImportsGraphics_ImportsGraphics] = AttrInfo(className: "NSTextField", fullTitle: "ImportsGraphics", patch: true)
            table[LookinAttr_NSVisualEffectView_Material_Material] = AttrInfo(className: "NSVisualEffectView", fullTitle: "Material", enumList: "NSVisualEffectMaterial", patch: true)
            table[LookinAttr_NSVisualEffectView_InteriorBackgroundStyle_InteriorBackgroundStyle] = AttrInfo(className: "NSVisualEffectView", fullTitle: "InteriorBackgroundStyle", enumList: "NSBackgroundStyle", patch: true)
            table[LookinAttr_NSVisualEffectView_BlendingMode_BlendingMode] = AttrInfo(className: "NSVisualEffectView", fullTitle: "BlendingMode", enumList: "NSVisualEffectBlendingMode", patch: true)
            table[LookinAttr_NSVisualEffectView_State_State] = AttrInfo(className: "NSVisualEffectView", fullTitle: "State", enumList: "NSVisualEffectState", patch: true)
            table[LookinAttr_NSVisualEffectView_Emphasized_Emphasized] = AttrInfo(className: "NSVisualEffectView", fullTitle: "Emphasized", getterString: "isEmphasized", patch: true)
            table[LookinAttr_NSStackView_Orientation_Orientation] = AttrInfo(className: "NSStackView", fullTitle: "Orientation", enumList: "NSUserInterfaceLayoutOrientation", patch: true)
            table[LookinAttr_NSStackView_EdgeInsets_EdgeInsets] = AttrInfo(className: "NSStackView", fullTitle: "EdgeInsets", patch: true)
            table[LookinAttr_NSStackView_DetachesHiddenViews_DetachesHiddenViews] = AttrInfo(className: "NSStackView", fullTitle: "DetachesHiddenViews", patch: true)
            table[LookinAttr_NSStackView_Distribution_Distribution] = AttrInfo(className: "NSStackView", fullTitle: "Distribution", enumList: "NSStackViewDistribution", patch: true)
            table[LookinAttr_NSStackView_Alignment_Alignment] = AttrInfo(className: "NSStackView", fullTitle: "Alignment", enumList: "NSLayoutAttribute", patch: true)
            table[LookinAttr_NSStackView_Spacing_Spacing] = AttrInfo(className: "NSStackView", fullTitle: "Spacing", patch: true)

            // MARK: - NSWindow

            table[LookinAttr_NSWindow_Title_Title] = AttrInfo(className: "NSWindow", fullTitle: "Title", typeIfObj: .nsString, patch: false)
            table[LookinAttr_NSWindow_Title_Subtitle] = AttrInfo(className: "NSWindow", fullTitle: "Subtitle", typeIfObj: .nsString, patch: false, osVersion: 11)
            table[LookinAttr_NSWindow_State_KeyWindow] = AttrInfo(className: "NSWindow", fullTitle: "KeyWindow", getterString: "isKeyWindow", setterString: "", patch: false)
            table[LookinAttr_NSWindow_State_MainWindow] = AttrInfo(className: "NSWindow", fullTitle: "MainWindow", getterString: "isMainWindow", setterString: "", patch: false)
            table[LookinAttr_NSWindow_State_Visible] = AttrInfo(className: "NSWindow", fullTitle: "Visible", getterString: "isVisible", setterString: "", patch: false)
            table[LookinAttr_NSWindow_State_CanBecomeKeyWindow] = AttrInfo(className: "NSWindow", fullTitle: "CanBecomeKeyWindow", setterString: "", patch: false)
            table[LookinAttr_NSWindow_State_CanBecomeMainWindow] = AttrInfo(className: "NSWindow", fullTitle: "CanBecomeMainWindow", setterString: "", patch: false)
            table[LookinAttr_NSWindow_Style_Titled] = AttrInfo(className: "NSWindow", fullTitle: "Titled", getterString: "lks_styleMaskTitled", setterString: "setLks_styleMaskTitled:", patch: true)
            table[LookinAttr_NSWindow_Style_Closable] = AttrInfo(className: "NSWindow", fullTitle: "Closable", getterString: "lks_styleMaskClosable", setterString: "setLks_styleMaskClosable:", patch: true)
            table[LookinAttr_NSWindow_Style_Miniaturizable] = AttrInfo(className: "NSWindow", fullTitle: "Miniaturizable", getterString: "lks_styleMaskMiniaturizable", setterString: "setLks_styleMaskMiniaturizable:", patch: true)
            table[LookinAttr_NSWindow_Style_Resizable] = AttrInfo(className: "NSWindow", fullTitle: "Resizable", getterString: "lks_styleMaskResizable", setterString: "setLks_styleMaskResizable:", patch: true)
            table[LookinAttr_NSWindow_Style_UnifiedTitleAndToolbar] = AttrInfo(className: "NSWindow", fullTitle: "UnifiedTitleAndToolbar", getterString: "lks_styleMaskUnifiedTitleAndToolbar", setterString: "setLks_styleMaskUnifiedTitleAndToolbar:", patch: true)
            table[LookinAttr_NSWindow_Style_FullScreen] = AttrInfo(className: "NSWindow", fullTitle: "FullScreen", getterString: "lks_styleMaskFullScreen", setterString: "", patch: false)
            table[LookinAttr_NSWindow_Style_FullSizeContentView] = AttrInfo(className: "NSWindow", fullTitle: "FullSizeContentView", getterString: "lks_styleMaskFullSizeContentView", setterString: "setLks_styleMaskFullSizeContentView:", patch: true)
            table[LookinAttr_NSWindow_Style_UtilityWindow] = AttrInfo(className: "NSWindow", fullTitle: "UtilityWindow", getterString: "lks_styleMaskUtilityWindow", setterString: "", patch: false)
            table[LookinAttr_NSWindow_Style_DocModalWindow] = AttrInfo(className: "NSWindow", fullTitle: "DocModalWindow", getterString: "lks_styleMaskDocModalWindow", setterString: "", patch: false)
            table[LookinAttr_NSWindow_Style_NonactivatingPanel] = AttrInfo(className: "NSWindow", fullTitle: "NonactivatingPanel", getterString: "lks_styleMaskNonactivatingPanel", setterString: "", patch: false)
            table[LookinAttr_NSWindow_Style_HUDWindow] = AttrInfo(className: "NSWindow", fullTitle: "HUDWindow", getterString: "lks_styleMaskHUDWindow", setterString: "", patch: false)
            table[LookinAttr_NSWindow_CollectionBehavior_CanJoinAllSpaces] = AttrInfo(className: "NSWindow", fullTitle: "CanJoinAllSpaces", getterString: "lks_collectionBehaviorCanJoinAllSpaces", setterString: "", patch: false)
            table[LookinAttr_NSWindow_CollectionBehavior_MoveToActiveSpace] = AttrInfo(className: "NSWindow", fullTitle: "MoveToActiveSpace", getterString: "lks_collectionBehaviorMoveToActiveSpace", setterString: "", patch: false)
            table[LookinAttr_NSWindow_CollectionBehavior_ParticipatesInCycle] = AttrInfo(className: "NSWindow", fullTitle: "ParticipatesInCycle", getterString: "lks_collectionBehaviorParticipatesInCycle", setterString: "", patch: false)
            table[LookinAttr_NSWindow_CollectionBehavior_IgnoresCycle] = AttrInfo(className: "NSWindow", fullTitle: "IgnoresCycle", getterString: "lks_collectionBehaviorIgnoresCycle", setterString: "", patch: false)
            table[LookinAttr_NSWindow_CollectionBehavior_FullScreenPrimary] = AttrInfo(className: "NSWindow", fullTitle: "FullScreenPrimary", getterString: "lks_collectionBehaviorFullScreenPrimary", setterString: "", patch: false)
            table[LookinAttr_NSWindow_CollectionBehavior_FullScreenAuxiliary] = AttrInfo(className: "NSWindow", fullTitle: "FullScreenAuxiliary", getterString: "lks_collectionBehaviorFullScreenAuxiliary", setterString: "", patch: false)
            table[LookinAttr_NSWindow_CollectionBehavior_FullScreenNone] = AttrInfo(className: "NSWindow", fullTitle: "FullScreenNone", getterString: "lks_collectionBehaviorFullScreenNone", setterString: "", patch: false)
            table[LookinAttr_NSWindow_CollectionBehavior_FullScreenAllowsTiling] = AttrInfo(className: "NSWindow", fullTitle: "FullScreenAllowsTiling", getterString: "lks_collectionBehaviorFullScreenAllowsTiling", setterString: "", patch: false)
            table[LookinAttr_NSWindow_CollectionBehavior_FullScreenDisallowsTiling] = AttrInfo(className: "NSWindow", fullTitle: "FullScreenDisallowsTiling", getterString: "lks_collectionBehaviorFullScreenDisallowsTiling", setterString: "", patch: false)
            table[LookinAttr_NSWindow_Appearance_TitlebarAppearsTransparent] = AttrInfo(className: "NSWindow", fullTitle: "TitlebarAppearsTransparent", patch: true)
            table[LookinAttr_NSWindow_Appearance_TitleVisibility] = AttrInfo(className: "NSWindow", fullTitle: "TitleVisibility", enumList: "NSWindowTitleVisibility", patch: true)
            table[LookinAttr_NSWindow_Appearance_ToolbarStyle] = AttrInfo(className: "NSWindow", fullTitle: "ToolbarStyle", enumList: "NSWindowToolbarStyle", patch: true, osVersion: 11)
            table[LookinAttr_NSWindow_Appearance_TitlebarSeparatorStyle] = AttrInfo(className: "NSWindow", fullTitle: "TitlebarSeparatorStyle", enumList: "NSTitlebarSeparatorStyle", patch: true, osVersion: 11)
            table[LookinAttr_NSWindow_Appearance_BackgroundColor] = AttrInfo(className: "NSWindow", fullTitle: "BackgroundColor", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_NSWindow_Appearance_AlphaValue] = AttrInfo(className: "NSWindow", fullTitle: "AlphaValue", patch: true)
            table[LookinAttr_NSWindow_Appearance_Opaque] = AttrInfo(className: "NSWindow", fullTitle: "Opaque", getterString: "isOpaque", setterString: "", patch: false)
            table[LookinAttr_NSWindow_Appearance_HasShadow] = AttrInfo(className: "NSWindow", fullTitle: "HasShadow", patch: true)
            table[LookinAttr_NSWindow_Behavior_Movable] = AttrInfo(className: "NSWindow", fullTitle: "Movable", getterString: "isMovable", patch: false)
            table[LookinAttr_NSWindow_Behavior_MovableByWindowBackground] = AttrInfo(className: "NSWindow", fullTitle: "MovableByWindowBackground", getterString: "isMovableByWindowBackground", patch: false)
            table[LookinAttr_NSWindow_Behavior_AnimationBehavior] = AttrInfo(className: "NSWindow", fullTitle: "AnimationBehavior", enumList: "NSWindowAnimationBehavior", patch: false)
            table[LookinAttr_NSWindow_Behavior_Level] = AttrInfo(className: "NSWindow", fullTitle: "Level", enumList: "NSWindowLevel", patch: true)
            table[LookinAttr_NSWindow_Behavior_HidesOnDeactivate] = AttrInfo(className: "NSWindow", fullTitle: "HidesOnDeactivate", patch: true)
            table[LookinAttr_NSWindow_Behavior_TabbingMode] = AttrInfo(className: "NSWindow", fullTitle: "TabbingMode", enumList: "NSWindowTabbingMode", patch: true)
            table[LookinAttr_NSWindow_Size_MinSize] = AttrInfo(className: "NSWindow", fullTitle: "MinSize", patch: true)
            table[LookinAttr_NSWindow_Size_MaxSize] = AttrInfo(className: "NSWindow", fullTitle: "MaxSize", patch: true)
            table[LookinAttr_NSWindow_Info_WindowNumber] = AttrInfo(className: "NSWindow", fullTitle: "WindowNumber", setterString: "", patch: false)
            table[LookinAttr_NSWindow_Info_BackingScaleFactor] = AttrInfo(className: "NSWindow", fullTitle: "BackingScaleFactor", setterString: "", patch: false)

            // MARK: - UIWindowScene

            // Lives under the Layout group rather than the UIWindowScene group,
            // because it is the only geometry a scene exposes — it has no frame.
            table[LookinAttr_Layout_CoordinateSpace_CoordinateSpace] = AttrInfo(className: "UIWindowScene", fullTitle: "CoordinateSpace", getterString: "lks_coordinateSpaceBounds", setterString: "", patch: false)
            table[LookinAttr_UIWindowScene_State_ActivationState] = AttrInfo(className: "UIWindowScene", fullTitle: "ActivationState", getterString: "activationState", setterString: "", enumList: "UISceneActivationState", patch: false)
            table[LookinAttr_UIWindowScene_Title_Title] = AttrInfo(className: "UIWindowScene", fullTitle: "Title", typeIfObj: .nsString, patch: true)
            table[LookinAttr_UIWindowScene_Title_Subtitle] = AttrInfo(className: "UIWindowScene", fullTitle: "Subtitle", typeIfObj: .nsString, patch: true, osVersion: 15)
            table[LookinAttr_UIWindowScene_Orientation_InterfaceOrientation] = AttrInfo(className: "UIWindowScene", fullTitle: "InterfaceOrientation", getterString: "lks_interfaceOrientation", setterString: "", enumList: "UIInterfaceOrientation", patch: false)
            table[LookinAttr_UIWindowScene_Windows_WindowCount] = AttrInfo(className: "UIWindowScene", fullTitle: "WindowCount", getterString: "lks_windowCount", setterString: "", patch: false)
            table[LookinAttr_UIWindowScene_Windows_KeyWindowClassName] = AttrInfo(className: "UIWindowScene", fullTitle: "KeyWindowClassName", getterString: "lks_keyWindowClassName", setterString: "", typeIfObj: .nsString, patch: false)
            table[LookinAttr_UIWindowScene_Screen_ScreenBounds] = AttrInfo(className: "UIWindowScene", fullTitle: "ScreenBounds", getterString: "lks_screenBounds", setterString: "", patch: false)
            table[LookinAttr_UIWindowScene_Screen_ScreenScale] = AttrInfo(className: "UIWindowScene", fullTitle: "ScreenScale", getterString: "lks_screenScale", setterString: "", patch: false)
            table[LookinAttr_UIWindowScene_StatusBar_StatusBarHidden] = AttrInfo(className: "UIWindowScene", fullTitle: "StatusBarHidden", getterString: "lks_statusBarHidden", setterString: "", patch: false)
            table[LookinAttr_UIWindowScene_StatusBar_StatusBarStyle] = AttrInfo(className: "UIWindowScene", fullTitle: "StatusBarStyle", getterString: "lks_statusBarStyle", setterString: "", enumList: "UIStatusBarStyle", patch: false)
            table[LookinAttr_UIWindowScene_StatusBar_StatusBarFrame] = AttrInfo(className: "UIWindowScene", fullTitle: "StatusBarFrame", getterString: "lks_statusBarFrame", setterString: "", patch: false)
            table[LookinAttr_UIWindowScene_Traits_UserInterfaceStyle] = AttrInfo(className: "UIWindowScene", fullTitle: "UserInterfaceStyle", getterString: "lks_userInterfaceStyle", setterString: "", enumList: "UIUserInterfaceStyle", patch: false)
            table[LookinAttr_UIWindowScene_Traits_HorizontalSizeClass] = AttrInfo(className: "UIWindowScene", fullTitle: "HorizontalSizeClass", getterString: "lks_horizontalSizeClass", setterString: "", enumList: "UIUserInterfaceSizeClass", patch: false)
            table[LookinAttr_UIWindowScene_Traits_VerticalSizeClass] = AttrInfo(className: "UIWindowScene", fullTitle: "VerticalSizeClass", getterString: "lks_verticalSizeClass", setterString: "", enumList: "UIUserInterfaceSizeClass", patch: false)
            table[LookinAttr_UIWindowScene_Traits_UserInterfaceLevel] = AttrInfo(className: "UIWindowScene", fullTitle: "UserInterfaceLevel", getterString: "lks_userInterfaceLevel", setterString: "", enumList: "UIUserInterfaceLevel", patch: false, osVersion: 13)
            table[LookinAttr_UIWindowScene_Traits_ActiveAppearance] = AttrInfo(className: "UIWindowScene", fullTitle: "ActiveAppearance", getterString: "lks_activeAppearance", setterString: "", enumList: "UIUserInterfaceActiveAppearance", patch: false, osVersion: 14)
            table[LookinAttr_UIWindowScene_Traits_AccessibilityContrast] = AttrInfo(className: "UIWindowScene", fullTitle: "AccessibilityContrast", getterString: "lks_accessibilityContrast", setterString: "", enumList: "UIAccessibilityContrast", patch: false, osVersion: 13)
            table[LookinAttr_UIWindowScene_Traits_LegibilityWeight] = AttrInfo(className: "UIWindowScene", fullTitle: "LegibilityWeight", getterString: "lks_legibilityWeight", setterString: "", enumList: "UILegibilityWeight", patch: false, osVersion: 13)
            table[LookinAttr_UIWindowScene_Traits_DisplayScale] = AttrInfo(className: "UIWindowScene", fullTitle: "DisplayScale", getterString: "lks_traitDisplayScale", setterString: "", patch: false, osVersion: 13)
            table[LookinAttr_UIWindowScene_Traits_DisplayGamut] = AttrInfo(className: "UIWindowScene", fullTitle: "DisplayGamut", getterString: "lks_displayGamut", setterString: "", enumList: "UIDisplayGamut", patch: false, osVersion: 13)
            table[LookinAttr_UIWindowScene_Traits_UserInterfaceIdiom] = AttrInfo(className: "UIWindowScene", fullTitle: "UserInterfaceIdiom", getterString: "lks_userInterfaceIdiom", setterString: "", enumList: "UIUserInterfaceIdiom", patch: false, osVersion: 13)
            table[LookinAttr_UIWindowScene_Traits_LayoutDirection] = AttrInfo(className: "UIWindowScene", fullTitle: "LayoutDirection", getterString: "lks_layoutDirection", setterString: "", enumList: "UITraitEnvironmentLayoutDirection", patch: false, osVersion: 13)
            table[LookinAttr_UIWindowScene_Traits_PreferredContentSizeCategory] = AttrInfo(className: "UIWindowScene", fullTitle: "PreferredContentSizeCategory", getterString: "lks_preferredContentSizeCategory", setterString: "", typeIfObj: .nsString, patch: false, osVersion: 13)
            table[LookinAttr_UIWindowScene_Traits_SceneCaptureState] = AttrInfo(className: "UIWindowScene", fullTitle: "SceneCaptureState", getterString: "lks_sceneCaptureState", setterString: "", enumList: "UISceneCaptureState", patch: false, osVersion: 17)
            table[LookinAttr_UIWindowScene_Traits_ImageDynamicRange] = AttrInfo(className: "UIWindowScene", fullTitle: "ImageDynamicRange", getterString: "lks_imageDynamicRange", setterString: "", enumList: "UIImageDynamicRange", patch: false, osVersion: 17)
            table[LookinAttr_UIWindowScene_Traits_TypesettingLanguage] = AttrInfo(className: "UIWindowScene", fullTitle: "TypesettingLanguage", getterString: "lks_typesettingLanguage", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true, osVersion: 17)
            table[LookinAttr_UIWindowScene_Session_PersistentIdentifier] = AttrInfo(className: "UIWindowScene", fullTitle: "PersistentIdentifier", getterString: "lks_sessionPersistentIdentifier", setterString: "", typeIfObj: .nsString, patch: false)
            table[LookinAttr_UIWindowScene_Session_SessionRole] = AttrInfo(className: "UIWindowScene", fullTitle: "SessionRole", getterString: "lks_sessionRole", setterString: "", typeIfObj: .nsString, patch: false)
            table[LookinAttr_UIWindowScene_Session_StateRestorationActivityType] = AttrInfo(className: "UIWindowScene", fullTitle: "StateRestorationActivity", getterString: "lks_sessionStateRestorationActivityType", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true)
            table[LookinAttr_UIWindowScene_Session_UserInfo] = AttrInfo(className: "UIWindowScene", fullTitle: "UserInfo", getterString: "lks_sessionUserInfoJSONString", setterString: "", typeIfObj: .json, patch: false, hideIfNil: true)
            // UISceneConfiguration — describes which classes and storyboard back
            // this scene. DelegateClass is the class declared in the configuration,
            // which is not necessarily the class of the delegate instance shown in
            // the Relation group; a mismatch between the two is worth noticing.
            table[LookinAttr_UIWindowScene_Configuration_Name] = AttrInfo(className: "UIWindowScene", fullTitle: "Name", getterString: "lks_configurationName", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true)
            table[LookinAttr_UIWindowScene_Configuration_SceneClass] = AttrInfo(className: "UIWindowScene", fullTitle: "SceneClass", getterString: "lks_configurationSceneClassName", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true)
            table[LookinAttr_UIWindowScene_Configuration_DelegateClass] = AttrInfo(className: "UIWindowScene", fullTitle: "DelegateClass", getterString: "lks_configurationDelegateClassName", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true)
            table[LookinAttr_UIWindowScene_Configuration_Storyboard] = AttrInfo(className: "UIWindowScene", fullTitle: "Storyboard", getterString: "lks_configurationStoryboardDescription", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true)
            // UIWindowSceneGeometry — every entry returns an object so that it can
            // disappear via hideIfNil on platforms and OS versions that lack it.
            table[LookinAttr_UIWindowScene_Geometry_SystemFrame] = AttrInfo(className: "UIWindowScene", fullTitle: "SystemFrame", getterString: "lks_geometrySystemFrame", setterString: "", typeIfObj: .cgRect, patch: false, hideIfNil: true, osVersion: 16)
            table[LookinAttr_UIWindowScene_Geometry_InterfaceOrientationLocked] = AttrInfo(className: "UIWindowScene", fullTitle: "InterfaceOrientationLocked", getterString: "lks_geometryInterfaceOrientationLocked", setterString: "", typeIfObj: .BOOL, patch: false, hideIfNil: true, osVersion: 26)
            table[LookinAttr_UIWindowScene_Geometry_InteractivelyResizing] = AttrInfo(className: "UIWindowScene", fullTitle: "InteractivelyResizing", getterString: "lks_geometryInteractivelyResizing", setterString: "", typeIfObj: .BOOL, patch: false, hideIfNil: true, osVersion: 26)
            // UISceneActivationConditions — shown as the predicates' format strings.
            table[LookinAttr_UIWindowScene_ActivationConditions_CanActivate] = AttrInfo(className: "UIWindowScene", fullTitle: "CanActivateForTargetContentIdentifier", briefTitle: "CanActivate", getterString: "lks_canActivateForTargetContentIdentifierPredicateFormat", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true)
            table[LookinAttr_UIWindowScene_ActivationConditions_PrefersToActivate] = AttrInfo(className: "UIWindowScene", fullTitle: "PrefersToActivateForTargetContentIdentifier", briefTitle: "PrefersToActivate", getterString: "lks_prefersToActivateForTargetContentIdentifierPredicateFormat", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true)
            // UISceneSizeRestrictions — nil on iPhone, so the whole section drops out there.
            table[LookinAttr_UIWindowScene_SizeRestrictions_MinimumSize] = AttrInfo(className: "UIWindowScene", fullTitle: "MinimumSize", getterString: "lks_sizeRestrictionsMinimumSize", setterString: "", typeIfObj: .cgSize, patch: false, hideIfNil: true)
            table[LookinAttr_UIWindowScene_SizeRestrictions_MaximumSize] = AttrInfo(className: "UIWindowScene", fullTitle: "MaximumSize", getterString: "lks_sizeRestrictionsMaximumSize", setterString: "", typeIfObj: .cgSize, patch: false, hideIfNil: true)
            table[LookinAttr_UIWindowScene_SizeRestrictions_AllowsFullScreen] = AttrInfo(className: "UIWindowScene", fullTitle: "AllowsFullScreen", getterString: "lks_sizeRestrictionsAllowsFullScreen", setterString: "", typeIfObj: .BOOL, patch: false, hideIfNil: true)
            // UISceneWindowingBehaviors — nil outside iPad multitasking and Catalyst.
            table[LookinAttr_UIWindowScene_WindowingBehaviors_Closable] = AttrInfo(className: "UIWindowScene", fullTitle: "Closable", getterString: "lks_windowingBehaviorsClosable", setterString: "", typeIfObj: .BOOL, patch: false, hideIfNil: true, osVersion: 16)
            table[LookinAttr_UIWindowScene_WindowingBehaviors_Miniaturizable] = AttrInfo(className: "UIWindowScene", fullTitle: "Miniaturizable", getterString: "lks_windowingBehaviorsMiniaturizable", setterString: "", typeIfObj: .BOOL, patch: false, hideIfNil: true, osVersion: 16)
            table[LookinAttr_UIWindowScene_WindowingBehaviors_FullScreen] = AttrInfo(className: "UIWindowScene", fullTitle: "FullScreen", getterString: "lks_fullScreen", setterString: "", typeIfObj: .BOOL, patch: false, hideIfNil: true)
            table[LookinAttr_UIWindowScene_Pointer_Locked] = AttrInfo(className: "UIWindowScene", fullTitle: "Locked", getterString: "lks_pointerLocked", setterString: "", typeIfObj: .BOOL, patch: false, hideIfNil: true, osVersion: 14)
            table[LookinAttr_UIWindowScene_Protection_UserAuthenticationEnabled] = AttrInfo(className: "UIWindowScene", fullTitle: "UserAuthenticationEnabled", getterString: "lks_systemProtectionUserAuthenticationEnabled", setterString: "", typeIfObj: .BOOL, patch: false, hideIfNil: true, osVersion: 18)

            // MARK: - UITraitCollection

            table[LookinAttr_UITraitCollection_Appearance_UserInterfaceStyle] = AttrInfo(className: "UIView", fullTitle: "UserInterfaceStyle", getterString: "lks_traitCollection_userInterfaceStyle", setterString: "", enumList: "UIUserInterfaceStyle", patch: false, osVersion: 12)
            table[LookinAttr_UITraitCollection_Appearance_UserInterfaceLevel] = AttrInfo(className: "UIView", fullTitle: "UserInterfaceLevel", getterString: "lks_traitCollection_userInterfaceLevel", setterString: "", enumList: "UIUserInterfaceLevel", patch: false, osVersion: 13)
            table[LookinAttr_UITraitCollection_Appearance_ActiveAppearance] = AttrInfo(className: "UIView", fullTitle: "ActiveAppearance", getterString: "lks_traitCollection_activeAppearance", setterString: "", enumList: "UIUserInterfaceActiveAppearance", patch: false, osVersion: 14)
            table[LookinAttr_UITraitCollection_Appearance_AccessibilityContrast] = AttrInfo(className: "UIView", fullTitle: "AccessibilityContrast", getterString: "lks_traitCollection_accessibilityContrast", setterString: "", enumList: "UIAccessibilityContrast", patch: false, osVersion: 13)
            table[LookinAttr_UITraitCollection_Appearance_LegibilityWeight] = AttrInfo(className: "UIView", fullTitle: "LegibilityWeight", getterString: "lks_traitCollection_legibilityWeight", setterString: "", enumList: "UILegibilityWeight", patch: false, osVersion: 13)
            table[LookinAttr_UITraitCollection_SizeClass_HorizontalSizeClass] = AttrInfo(className: "UIView", fullTitle: "HorizontalSizeClass", getterString: "lks_traitCollection_horizontalSizeClass", setterString: "", enumList: "UIUserInterfaceSizeClass", patch: false)
            table[LookinAttr_UITraitCollection_SizeClass_VerticalSizeClass] = AttrInfo(className: "UIView", fullTitle: "VerticalSizeClass", getterString: "lks_traitCollection_verticalSizeClass", setterString: "", enumList: "UIUserInterfaceSizeClass", patch: false)
            table[LookinAttr_UITraitCollection_Display_DisplayScale] = AttrInfo(className: "UIView", fullTitle: "DisplayScale", getterString: "lks_traitCollection_displayScale", setterString: "", patch: false)
            table[LookinAttr_UITraitCollection_Display_DisplayGamut] = AttrInfo(className: "UIView", fullTitle: "DisplayGamut", getterString: "lks_traitCollection_displayGamut", setterString: "", enumList: "UIDisplayGamut", patch: false, osVersion: 10)
            table[LookinAttr_UITraitCollection_Display_ImageDynamicRange] = AttrInfo(className: "UIView", fullTitle: "ImageDynamicRange", getterString: "lks_traitCollection_imageDynamicRange", setterString: "", enumList: "UIImageDynamicRange", patch: false, osVersion: 17)
            table[LookinAttr_UITraitCollection_Device_UserInterfaceIdiom] = AttrInfo(className: "UIView", fullTitle: "UserInterfaceIdiom", getterString: "lks_traitCollection_userInterfaceIdiom", setterString: "", enumList: "UIUserInterfaceIdiom", patch: false)
            table[LookinAttr_UITraitCollection_Device_ForceTouchCapability] = AttrInfo(className: "UIView", fullTitle: "ForceTouchCapability", getterString: "lks_traitCollection_forceTouchCapability", setterString: "", enumList: "UIForceTouchCapability", patch: false, osVersion: 9)
            table[LookinAttr_UITraitCollection_Layout_LayoutDirection] = AttrInfo(className: "UIView", fullTitle: "LayoutDirection", getterString: "lks_traitCollection_layoutDirection", setterString: "", enumList: "UITraitEnvironmentLayoutDirection", patch: false, osVersion: 10)
            table[LookinAttr_UITraitCollection_Content_PreferredContentSizeCategory] = AttrInfo(className: "UIView", fullTitle: "PreferredContentSizeCategory", getterString: "lks_traitCollection_preferredContentSizeCategory", setterString: "", typeIfObj: .nsString, patch: false, osVersion: 10)
            table[LookinAttr_UITraitCollection_Content_TypesettingLanguage] = AttrInfo(className: "UIView", fullTitle: "TypesettingLanguage", getterString: "lks_traitCollection_typesettingLanguage", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true, osVersion: 17)

            // MARK: - NSSlider

            table[LookinAttr_NSSlider_SliderType_SliderType] = AttrInfo(className: "NSSlider", fullTitle: "SliderType", enumList: "NSSliderType", patch: true)
            table[LookinAttr_NSSlider_Range_MinValue] = AttrInfo(className: "NSSlider", fullTitle: "MinValue", patch: true)
            table[LookinAttr_NSSlider_Range_MaxValue] = AttrInfo(className: "NSSlider", fullTitle: "MaxValue", patch: true)
            table[LookinAttr_NSSlider_TickMark_NumberOfTickMarks] = AttrInfo(className: "NSSlider", fullTitle: "NumberOfTickMarks", patch: true)
            table[LookinAttr_NSSlider_TickMark_TickMarkPosition] = AttrInfo(className: "NSSlider", fullTitle: "TickMarkPosition", enumList: "NSTickMarkPosition", patch: true)
            table[LookinAttr_NSSlider_TickMark_AllowsTickMarkValuesOnly] = AttrInfo(className: "NSSlider", fullTitle: "AllowsTickMarkValuesOnly", patch: true)
            table[LookinAttr_NSSlider_Misc_Vertical] = AttrInfo(className: "NSSlider", fullTitle: "Vertical", getterString: "isVertical", setterString: "", patch: false)
            table[LookinAttr_NSSlider_Misc_KnobThickness] = AttrInfo(className: "NSSlider", fullTitle: "KnobThickness", setterString: "", patch: false)
            table[LookinAttr_NSSlider_Misc_AltIncrementValue] = AttrInfo(className: "NSSlider", fullTitle: "AltIncrementValue", patch: true)
            table[LookinAttr_NSSlider_Misc_TrackFillColor] = AttrInfo(className: "NSSlider", fullTitle: "TrackFillColor", typeIfObj: .uiColor, patch: true, hideIfNil: true)

            // MARK: - NSProgressIndicator

            table[LookinAttr_NSProgressIndicator_Style_Style] = AttrInfo(className: "NSProgressIndicator", fullTitle: "Style", enumList: "NSProgressIndicatorStyle", patch: true)
            table[LookinAttr_NSProgressIndicator_Range_MinValue] = AttrInfo(className: "NSProgressIndicator", fullTitle: "MinValue", patch: true)
            table[LookinAttr_NSProgressIndicator_Range_MaxValue] = AttrInfo(className: "NSProgressIndicator", fullTitle: "MaxValue", patch: true)
            table[LookinAttr_NSProgressIndicator_Range_DoubleValue] = AttrInfo(className: "NSProgressIndicator", fullTitle: "DoubleValue", patch: true)
            table[LookinAttr_NSProgressIndicator_Misc_Indeterminate] = AttrInfo(className: "NSProgressIndicator", fullTitle: "Indeterminate", getterString: "isIndeterminate", patch: true)
            table[LookinAttr_NSProgressIndicator_Misc_Bezeled] = AttrInfo(className: "NSProgressIndicator", fullTitle: "Bezeled", getterString: "isBezeled", patch: true)
            table[LookinAttr_NSProgressIndicator_Misc_DisplayedWhenStopped] = AttrInfo(className: "NSProgressIndicator", fullTitle: "DisplayedWhenStopped", getterString: "isDisplayedWhenStopped", patch: true)

            // MARK: - NSSegmentedControl

            table[LookinAttr_NSSegmentedControl_SegmentCount_SegmentCount] = AttrInfo(className: "NSSegmentedControl", fullTitle: "SegmentCount", patch: true)
            table[LookinAttr_NSSegmentedControl_Selection_SelectedSegment] = AttrInfo(className: "NSSegmentedControl", fullTitle: "SelectedSegment", patch: true)
            table[LookinAttr_NSSegmentedControl_Style_SegmentStyle] = AttrInfo(className: "NSSegmentedControl", fullTitle: "SegmentStyle", enumList: "NSSegmentStyle", patch: true)
            table[LookinAttr_NSSegmentedControl_Style_TrackingMode] = AttrInfo(className: "NSSegmentedControl", fullTitle: "TrackingMode", enumList: "NSSegmentSwitchTracking", patch: true)
            table[LookinAttr_NSSegmentedControl_Colors_SelectedSegmentBezelColor] = AttrInfo(className: "NSSegmentedControl", fullTitle: "SelectedSegmentBezelColor", typeIfObj: .uiColor, patch: true, hideIfNil: true)

            // MARK: - NSPopUpButton

            table[LookinAttr_NSPopUpButton_Behavior_PullsDown] = AttrInfo(className: "NSPopUpButton", fullTitle: "PullsDown", patch: true)
            table[LookinAttr_NSPopUpButton_Behavior_AutoenablesItems] = AttrInfo(className: "NSPopUpButton", fullTitle: "AutoenablesItems", patch: true)
            table[LookinAttr_NSPopUpButton_Behavior_PreferredEdge] = AttrInfo(className: "NSPopUpButton", fullTitle: "PreferredEdge", enumList: "NSRectEdge", patch: true)
            table[LookinAttr_NSPopUpButton_Selection_SelectedTag] = AttrInfo(className: "NSPopUpButton", fullTitle: "SelectedTag", setterString: "", patch: false)
            table[LookinAttr_NSPopUpButton_Selection_IndexOfSelectedItem] = AttrInfo(className: "NSPopUpButton", fullTitle: "IndexOfSelectedItem", setterString: "", patch: false)
            table[LookinAttr_NSPopUpButton_Selection_TitleOfSelectedItem] = AttrInfo(className: "NSPopUpButton", fullTitle: "TitleOfSelectedItem", setterString: "", typeIfObj: .nsString, patch: false, hideIfNil: true)
            table[LookinAttr_NSPopUpButton_Items_NumberOfItems] = AttrInfo(className: "NSPopUpButton", fullTitle: "NumberOfItems", setterString: "", patch: false)

            // MARK: - NSComboBox

            table[LookinAttr_NSComboBox_Items_NumberOfItems] = AttrInfo(className: "NSComboBox", fullTitle: "NumberOfItems", setterString: "", patch: false)
            table[LookinAttr_NSComboBox_Items_HasVerticalScroller] = AttrInfo(className: "NSComboBox", fullTitle: "HasVerticalScroller", patch: true)
            table[LookinAttr_NSComboBox_Items_NumberOfVisibleItems] = AttrInfo(className: "NSComboBox", fullTitle: "NumberOfVisibleItems", patch: true)
            table[LookinAttr_NSComboBox_Items_IntercellSpacing] = AttrInfo(className: "NSComboBox", fullTitle: "IntercellSpacing", patch: true)
            table[LookinAttr_NSComboBox_Items_ItemHeight] = AttrInfo(className: "NSComboBox", fullTitle: "ItemHeight", patch: true)
            table[LookinAttr_NSComboBox_Misc_ButtonBordered] = AttrInfo(className: "NSComboBox", fullTitle: "ButtonBordered", getterString: "isButtonBordered", patch: true)
            table[LookinAttr_NSComboBox_Misc_Completes] = AttrInfo(className: "NSComboBox", fullTitle: "Completes", patch: true)
            table[LookinAttr_NSComboBox_Misc_UsesDataSource] = AttrInfo(className: "NSComboBox", fullTitle: "UsesDataSource", patch: false)

            // MARK: - NSStepper

            table[LookinAttr_NSStepper_Range_MinValue] = AttrInfo(className: "NSStepper", fullTitle: "MinValue", patch: true)
            table[LookinAttr_NSStepper_Range_MaxValue] = AttrInfo(className: "NSStepper", fullTitle: "MaxValue", patch: true)
            table[LookinAttr_NSStepper_Range_Increment] = AttrInfo(className: "NSStepper", fullTitle: "Increment", patch: true)
            table[LookinAttr_NSStepper_Misc_ValueWraps] = AttrInfo(className: "NSStepper", fullTitle: "ValueWraps", patch: true)
            table[LookinAttr_NSStepper_Misc_Autorepeat] = AttrInfo(className: "NSStepper", fullTitle: "Autorepeat", patch: true)

            // MARK: - NSColorWell

            table[LookinAttr_NSColorWell_Color_Color] = AttrInfo(className: "NSColorWell", fullTitle: "Color", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_NSColorWell_Misc_Bordered] = AttrInfo(className: "NSColorWell", fullTitle: "Bordered", getterString: "isBordered", patch: true)
            table[LookinAttr_NSColorWell_Misc_Active] = AttrInfo(className: "NSColorWell", fullTitle: "Active", getterString: "isActive", setterString: "", patch: false)
            table[LookinAttr_NSColorWell_Misc_ColorWellStyle] = AttrInfo(className: "NSColorWell", fullTitle: "ColorWellStyle", enumList: "NSColorWellStyle", patch: true, osVersion: 13)

            // MARK: - NSSwitch

            table[LookinAttr_NSSwitch_State_State] = AttrInfo(className: "NSSwitch", fullTitle: "State", enumList: "NSControlStateValue", patch: true, osVersion: 15)

            // MARK: - NSDatePicker

            table[LookinAttr_NSDatePicker_Style_DatePickerStyle] = AttrInfo(className: "NSDatePicker", fullTitle: "DatePickerStyle", enumList: "NSDatePickerStyle", patch: true)
            table[LookinAttr_NSDatePicker_Style_DatePickerMode] = AttrInfo(className: "NSDatePicker", fullTitle: "DatePickerMode", enumList: "NSDatePickerMode", patch: true)
            table[LookinAttr_NSDatePicker_Range_DateValue] = AttrInfo(className: "NSDatePicker", fullTitle: "DateValue", setterString: "", typeIfObj: .customObj, patch: false)
            table[LookinAttr_NSDatePicker_Range_MinDate] = AttrInfo(className: "NSDatePicker", fullTitle: "MinDate", setterString: "", typeIfObj: .customObj, patch: false, hideIfNil: true)
            table[LookinAttr_NSDatePicker_Range_MaxDate] = AttrInfo(className: "NSDatePicker", fullTitle: "MaxDate", setterString: "", typeIfObj: .customObj, patch: false, hideIfNil: true)
            table[LookinAttr_NSDatePicker_Misc_Bordered] = AttrInfo(className: "NSDatePicker", fullTitle: "Bordered", getterString: "isBordered", patch: true)
            table[LookinAttr_NSDatePicker_Misc_Bezeled] = AttrInfo(className: "NSDatePicker", fullTitle: "Bezeled", getterString: "isBezeled", patch: true)
            table[LookinAttr_NSDatePicker_Misc_DrawsBackground] = AttrInfo(className: "NSDatePicker", fullTitle: "DrawsBackground", patch: true)

            // MARK: - NSLevelIndicator

            table[LookinAttr_NSLevelIndicator_Style_Style] = AttrInfo(className: "NSLevelIndicator", fullTitle: "LevelIndicatorStyle", enumList: "NSLevelIndicatorStyle", patch: true)
            table[LookinAttr_NSLevelIndicator_Range_MinValue] = AttrInfo(className: "NSLevelIndicator", fullTitle: "MinValue", patch: true)
            table[LookinAttr_NSLevelIndicator_Range_MaxValue] = AttrInfo(className: "NSLevelIndicator", fullTitle: "MaxValue", patch: true)
            table[LookinAttr_NSLevelIndicator_Range_WarningValue] = AttrInfo(className: "NSLevelIndicator", fullTitle: "WarningValue", patch: true)
            table[LookinAttr_NSLevelIndicator_Range_CriticalValue] = AttrInfo(className: "NSLevelIndicator", fullTitle: "CriticalValue", patch: true)
            table[LookinAttr_NSLevelIndicator_TickMark_NumberOfTickMarks] = AttrInfo(className: "NSLevelIndicator", fullTitle: "NumberOfTickMarks", patch: true)
            table[LookinAttr_NSLevelIndicator_TickMark_NumberOfMajorTickMarks] = AttrInfo(className: "NSLevelIndicator", fullTitle: "NumberOfMajorTickMarks", patch: true)

            // MARK: - NSOutlineView

            table[LookinAttr_NSOutlineView_Indentation_IndentationPerLevel] = AttrInfo(className: "NSOutlineView", fullTitle: "IndentationPerLevel", patch: true)
            table[LookinAttr_NSOutlineView_Misc_AutoresizesOutlineColumn] = AttrInfo(className: "NSOutlineView", fullTitle: "AutoresizesOutlineColumn", patch: true)
            table[LookinAttr_NSOutlineView_Misc_IndentationMarkerFollowsCell] = AttrInfo(className: "NSOutlineView", fullTitle: "IndentationMarkerFollowsCell", patch: true)
            table[LookinAttr_NSOutlineView_Misc_AutosaveExpandedItems] = AttrInfo(className: "NSOutlineView", fullTitle: "AutosaveExpandedItems", patch: true)

            // MARK: - NSCollectionView

            table[LookinAttr_NSCollectionView_Selection_Selectable] = AttrInfo(className: "NSCollectionView", fullTitle: "Selectable", getterString: "isSelectable", patch: true)
            table[LookinAttr_NSCollectionView_Selection_AllowsMultipleSelection] = AttrInfo(className: "NSCollectionView", fullTitle: "AllowsMultipleSelection", patch: true)
            table[LookinAttr_NSCollectionView_Selection_AllowsEmptySelection] = AttrInfo(className: "NSCollectionView", fullTitle: "AllowsEmptySelection", patch: true)
            table[LookinAttr_NSCollectionView_Info_NumberOfSections] = AttrInfo(className: "NSCollectionView", fullTitle: "NumberOfSections", setterString: "", patch: false)
            table[LookinAttr_NSCollectionView_Colors_BackgroundColors] = AttrInfo(className: "NSCollectionView", fullTitle: "BackgroundColors", setterString: "", typeIfObj: .customObj, patch: false)

            // MARK: - NSBox

            table[LookinAttr_NSBox_Type_BoxType] = AttrInfo(className: "NSBox", fullTitle: "BoxType", enumList: "NSBoxType", patch: true)
            table[LookinAttr_NSBox_Type_BorderType] = AttrInfo(className: "NSBox", fullTitle: "BorderType", enumList: "NSBorderType", patch: true)
            table[LookinAttr_NSBox_Title_Title] = AttrInfo(className: "NSBox", fullTitle: "Title", typeIfObj: .nsString, patch: true)
            table[LookinAttr_NSBox_Title_TitlePosition] = AttrInfo(className: "NSBox", fullTitle: "TitlePosition", enumList: "NSTitlePosition", patch: true)
            table[LookinAttr_NSBox_Appearance_Transparent] = AttrInfo(className: "NSBox", fullTitle: "Transparent", getterString: "isTransparent", patch: true)
            table[LookinAttr_NSBox_Appearance_FillColor] = AttrInfo(className: "NSBox", fullTitle: "FillColor", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_NSBox_Appearance_BorderColor] = AttrInfo(className: "NSBox", fullTitle: "BorderColor", typeIfObj: .uiColor, patch: true)
            table[LookinAttr_NSBox_Metrics_BorderWidth] = AttrInfo(className: "NSBox", fullTitle: "BorderWidth", patch: true)
            table[LookinAttr_NSBox_Metrics_CornerRadius] = AttrInfo(className: "NSBox", fullTitle: "CornerRadius", patch: true)
            table[LookinAttr_NSBox_Metrics_ContentViewMargins] = AttrInfo(className: "NSBox", fullTitle: "ContentViewMargins", patch: true)

            // MARK: - NSSplitView

            table[LookinAttr_NSSplitView_Orientation_Vertical] = AttrInfo(className: "NSSplitView", fullTitle: "Vertical", getterString: "isVertical", patch: true)
            table[LookinAttr_NSSplitView_Style_DividerStyle] = AttrInfo(className: "NSSplitView", fullTitle: "DividerStyle", enumList: "NSSplitViewDividerStyle", patch: true)
            table[LookinAttr_NSSplitView_Style_DividerThickness] = AttrInfo(className: "NSSplitView", fullTitle: "DividerThickness", setterString: "", patch: false)
            table[LookinAttr_NSSplitView_Misc_ArrangesAllSubviews] = AttrInfo(className: "NSSplitView", fullTitle: "ArrangesAllSubviews", patch: true)

            // MARK: - NSTabView

            table[LookinAttr_NSTabView_Type_TabViewType] = AttrInfo(className: "NSTabView", fullTitle: "TabViewType", enumList: "NSTabViewType", patch: true)
            table[LookinAttr_NSTabView_Type_TabPosition] = AttrInfo(className: "NSTabView", fullTitle: "TabPosition", enumList: "NSTabPosition", patch: true, osVersion: 14)
            table[LookinAttr_NSTabView_Type_TabViewBorderType] = AttrInfo(className: "NSTabView", fullTitle: "TabViewBorderType", enumList: "NSTabViewBorderType", patch: true, osVersion: 14)
            table[LookinAttr_NSTabView_Misc_AllowsTruncatedLabels] = AttrInfo(className: "NSTabView", fullTitle: "AllowsTruncatedLabels", patch: true)
            table[LookinAttr_NSTabView_Misc_DrawsBackground] = AttrInfo(className: "NSTabView", fullTitle: "DrawsBackground", patch: true)
            table[LookinAttr_NSTabView_Info_NumberOfTabViewItems] = AttrInfo(className: "NSTabView", fullTitle: "NumberOfTabViewItems", setterString: "", patch: false)

            // MARK: - NSGridView

            table[LookinAttr_NSGridView_Dimensions_NumberOfColumns] = AttrInfo(className: "NSGridView", fullTitle: "NumberOfColumns", setterString: "", patch: false)
            table[LookinAttr_NSGridView_Dimensions_NumberOfRows] = AttrInfo(className: "NSGridView", fullTitle: "NumberOfRows", setterString: "", patch: false)
            table[LookinAttr_NSGridView_Spacing_RowSpacing] = AttrInfo(className: "NSGridView", fullTitle: "RowSpacing", patch: true)
            table[LookinAttr_NSGridView_Spacing_ColumnSpacing] = AttrInfo(className: "NSGridView", fullTitle: "ColumnSpacing", patch: true)
            table[LookinAttr_NSGridView_Placement_XPlacement] = AttrInfo(className: "NSGridView", fullTitle: "XPlacement", enumList: "NSGridCellPlacement", patch: true)
            table[LookinAttr_NSGridView_Placement_YPlacement] = AttrInfo(className: "NSGridView", fullTitle: "YPlacement", enumList: "NSGridCellPlacement", patch: true)
            return table
        }()
    }

#endif
