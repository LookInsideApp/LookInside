//
//  DashboardBlueprint+Sections.swift
//  LookinCore
//
//  The attributes of each section.
//  Translated from LookinDashboardBlueprint.m; the output of every public
//  class method is pinned by Tests/LookinServerHierarchyTests/
//  BlueprintEquivalenceTests and its Fixtures/blueprint-<platform>.txt.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    extension DashboardBlueprintTables {
        /// `+attrIDsForSectionID:`, in display order.
        static let attrIDsBySectionID: [String: [String]] = {
            var table: [String: [String]] = [:]
            table[LookinAttrSec_Class_Class] = [LookinAttr_Class_Class_Class]
            table[LookinAttrSec_Relation_Relation] = [LookinAttr_Relation_Relation_Relation]
            table[LookinAttrSec_Layout_Frame] = [LookinAttr_Layout_Frame_Frame]
            table[LookinAttrSec_Layout_Bounds] = [LookinAttr_Layout_Bounds_Bounds]
            table[LookinAttrSec_Layout_SafeArea] = [LookinAttr_Layout_SafeArea_SafeArea]
            table[LookinAttrSec_Layout_Position] = [LookinAttr_Layout_Position_Position]
            table[LookinAttrSec_Layout_AnchorPoint] = [LookinAttr_Layout_AnchorPoint_AnchorPoint]
            table[LookinAttrSec_Layout_CoordinateSpace] = [LookinAttr_Layout_CoordinateSpace_CoordinateSpace]
            table[LookinAttrSec_AutoLayout_Hugging] = [
                LookinAttr_AutoLayout_Hugging_Hor,
                LookinAttr_AutoLayout_Hugging_Ver,
            ]
            table[LookinAttrSec_AutoLayout_Resistance] = [
                LookinAttr_AutoLayout_Resistance_Hor,
                LookinAttr_AutoLayout_Resistance_Ver,
            ]
            table[LookinAttrSec_AutoLayout_Constraints] = [LookinAttr_AutoLayout_Constraints_Constraints]
            table[LookinAttrSec_AutoLayout_IntrinsicSize] = [LookinAttr_AutoLayout_IntrinsicSize_Size]
            table[LookinAttrSec_ViewLayer_Visibility] = [
                LookinAttr_ViewLayer_Visibility_Hidden,
                LookinAttr_ViewLayer_Visibility_Opacity,
            ]
            table[LookinAttrSec_ViewLayer_InterationAndMasks] = {
                var ids: [String] = []
                #if canImport(UIKit)
                    ids.append(LookinAttr_ViewLayer_InterationAndMasks_Interaction)
                #endif
                ids.append(LookinAttr_ViewLayer_InterationAndMasks_MasksToBounds)
                return ids
            }()
            table[LookinAttrSec_ViewLayer_Corner] = [LookinAttr_ViewLayer_Corner_Radius]
            table[LookinAttrSec_ViewLayer_BgColor] = [LookinAttr_ViewLayer_BgColor_BgColor]
            table[LookinAttrSec_ViewLayer_Border] = [
                LookinAttr_ViewLayer_Border_Color,
                LookinAttr_ViewLayer_Border_Width,
            ]
            table[LookinAttrSec_ViewLayer_Shadow] = [
                LookinAttr_ViewLayer_Shadow_Color,
                LookinAttr_ViewLayer_Shadow_Opacity,
                LookinAttr_ViewLayer_Shadow_Radius,
                LookinAttr_ViewLayer_Shadow_OffsetW,
                LookinAttr_ViewLayer_Shadow_OffsetH,
            ]
            #if canImport(UIKit)
                table[LookinAttrSec_ViewLayer_ContentMode] = [LookinAttr_ViewLayer_ContentMode_Mode]
                table[LookinAttrSec_ViewLayer_TintColor] = [
                    LookinAttr_ViewLayer_TintColor_Color,
                    LookinAttr_ViewLayer_TintColor_Mode,
                ]
            #endif
            table[LookinAttrSec_ViewLayer_Tag] = [LookinAttr_ViewLayer_Tag_Tag]
            #if canImport(UIKit)
                table[LookinAttrSec_UIStackView_Axis] = [LookinAttr_UIStackView_Axis_Axis]
                table[LookinAttrSec_UIStackView_Distribution] = [LookinAttr_UIStackView_Distribution_Distribution]
                table[LookinAttrSec_UIStackView_Alignment] = [LookinAttr_UIStackView_Alignment_Alignment]
                table[LookinAttrSec_UIStackView_Spacing] = [LookinAttr_UIStackView_Spacing_Spacing]
                table[LookinAttrSec_UIVisualEffectView_Style] = [LookinAttr_UIVisualEffectView_Style_Style]
                table[LookinAttrSec_UIVisualEffectView_QMUIForegroundColor] = [LookinAttr_UIVisualEffectView_QMUIForegroundColor_Color]
                table[LookinAttrSec_UIImageView_Name] = [LookinAttr_UIImageView_Name_Name]
                table[LookinAttrSec_UIImageView_Open] = [LookinAttr_UIImageView_Open_Open]
                table[LookinAttrSec_UILabel_Font] = [
                    LookinAttr_UILabel_Font_Name,
                    LookinAttr_UILabel_Font_Size,
                ]
                table[LookinAttrSec_UILabel_NumberOfLines] = [LookinAttr_UILabel_NumberOfLines_NumberOfLines]
                table[LookinAttrSec_UILabel_Text] = [LookinAttr_UILabel_Text_Text]
                table[LookinAttrSec_UILabel_TextColor] = [LookinAttr_UILabel_TextColor_Color]
                table[LookinAttrSec_UILabel_BreakMode] = [LookinAttr_UILabel_BreakMode_Mode]
                table[LookinAttrSec_UILabel_Alignment] = [LookinAttr_UILabel_Alignment_Alignment]
                table[LookinAttrSec_UILabel_CanAdjustFont] = [LookinAttr_UILabel_CanAdjustFont_CanAdjustFont]
                table[LookinAttrSec_UIControl_EnabledSelected] = [
                    LookinAttr_UIControl_EnabledSelected_Enabled,
                    LookinAttr_UIControl_EnabledSelected_Selected,
                ]
                table[LookinAttrSec_UIControl_QMUIOutsideEdge] = [LookinAttr_UIControl_QMUIOutsideEdge_Edge]
                table[LookinAttrSec_UIControl_VerAlignment] = [LookinAttr_UIControl_VerAlignment_Alignment]
                table[LookinAttrSec_UIControl_HorAlignment] = [LookinAttr_UIControl_HorAlignment_Alignment]
                table[LookinAttrSec_UIButton_ContentInsets] = [LookinAttr_UIButton_ContentInsets_Insets]
                table[LookinAttrSec_UIButton_TitleInsets] = [LookinAttr_UIButton_TitleInsets_Insets]
                table[LookinAttrSec_UIButton_ImageInsets] = [LookinAttr_UIButton_ImageInsets_Insets]
                table[LookinAttrSec_UIScrollView_ContentInset] = [LookinAttr_UIScrollView_ContentInset_Inset]
                table[LookinAttrSec_UIScrollView_AdjustedInset] = [LookinAttr_UIScrollView_AdjustedInset_Inset]
                table[LookinAttrSec_UIScrollView_QMUIInitialInset] = [LookinAttr_UIScrollView_QMUIInitialInset_Inset]
                table[LookinAttrSec_UIScrollView_IndicatorInset] = [LookinAttr_UIScrollView_IndicatorInset_Inset]
                table[LookinAttrSec_UIScrollView_Offset] = [LookinAttr_UIScrollView_Offset_Offset]
                table[LookinAttrSec_UIScrollView_ContentSize] = [LookinAttr_UIScrollView_ContentSize_Size]
                table[LookinAttrSec_UIScrollView_Behavior] = [LookinAttr_UIScrollView_Behavior_Behavior]
                table[LookinAttrSec_UIScrollView_ShowsIndicator] = [
                    LookinAttr_UIScrollView_ShowsIndicator_Hor,
                    LookinAttr_UIScrollView_ShowsIndicator_Ver,
                ]
                table[LookinAttrSec_UIScrollView_Bounce] = [
                    LookinAttr_UIScrollView_Bounce_Hor,
                    LookinAttr_UIScrollView_Bounce_Ver,
                ]
                table[LookinAttrSec_UIScrollView_ScrollPaging] = [
                    LookinAttr_UIScrollView_ScrollPaging_ScrollEnabled,
                    LookinAttr_UIScrollView_ScrollPaging_PagingEnabled,
                ]
                table[LookinAttrSec_UIScrollView_ContentTouches] = [
                    LookinAttr_UIScrollView_ContentTouches_Delay,
                    LookinAttr_UIScrollView_ContentTouches_CanCancel,
                ]
                table[LookinAttrSec_UIScrollView_Zoom] = [
                    LookinAttr_UIScrollView_Zoom_Bounce,
                    LookinAttr_UIScrollView_Zoom_Scale,
                    LookinAttr_UIScrollView_Zoom_MinScale,
                    LookinAttr_UIScrollView_Zoom_MaxScale,
                ]
                table[LookinAttrSec_UITableView_Style] = [LookinAttr_UITableView_Style_Style]
                table[LookinAttrSec_UITableView_SectionsNumber] = [LookinAttr_UITableView_SectionsNumber_Number]
                table[LookinAttrSec_UITableView_RowsNumber] = [LookinAttr_UITableView_RowsNumber_Number]
                table[LookinAttrSec_UITableView_SeparatorInset] = [LookinAttr_UITableView_SeparatorInset_Inset]
                table[LookinAttrSec_UITableView_SeparatorColor] = [LookinAttr_UITableView_SeparatorColor_Color]
                table[LookinAttrSec_UITableView_SeparatorStyle] = [LookinAttr_UITableView_SeparatorStyle_Style]
                table[LookinAttrSec_UITextView_Basic] = [
                    LookinAttr_UITextView_Basic_Editable,
                    LookinAttr_UITextView_Basic_Selectable,
                ]
                table[LookinAttrSec_UITextView_Text] = [LookinAttr_UITextView_Text_Text]
                table[LookinAttrSec_UITextView_Font] = [
                    LookinAttr_UITextView_Font_Name,
                    LookinAttr_UITextView_Font_Size,
                ]
                table[LookinAttrSec_UITextView_TextColor] = [LookinAttr_UITextView_TextColor_Color]
                table[LookinAttrSec_UITextView_Alignment] = [LookinAttr_UITextView_Alignment_Alignment]
                table[LookinAttrSec_UITextView_ContainerInset] = [LookinAttr_UITextView_ContainerInset_Inset]
                table[LookinAttrSec_UITextField_Text] = [LookinAttr_UITextField_Text_Text]
                table[LookinAttrSec_UITextField_Placeholder] = [LookinAttr_UITextField_Placeholder_Placeholder]
                table[LookinAttrSec_UITextField_Font] = [
                    LookinAttr_UITextField_Font_Name,
                    LookinAttr_UITextField_Font_Size,
                ]
                table[LookinAttrSec_UITextField_TextColor] = [LookinAttr_UITextField_TextColor_Color]
                table[LookinAttrSec_UITextField_Alignment] = [LookinAttr_UITextField_Alignment_Alignment]
                table[LookinAttrSec_UITextField_Clears] = [
                    LookinAttr_UITextField_Clears_ClearsOnBeginEditing,
                    LookinAttr_UITextField_Clears_ClearsOnInsertion,
                ]
                table[LookinAttrSec_UITextField_CanAdjustFont] = [
                    LookinAttr_UITextField_CanAdjustFont_CanAdjustFont,
                    LookinAttr_UITextField_CanAdjustFont_MinSize,
                ]
                table[LookinAttrSec_UITextField_ClearButtonMode] = [LookinAttr_UITextField_ClearButtonMode_Mode]
                table[LookinAttrSec_UIWindowScene_State] = [LookinAttr_UIWindowScene_State_ActivationState]
                table[LookinAttrSec_UIWindowScene_Title] = [
                    LookinAttr_UIWindowScene_Title_Title,
                    LookinAttr_UIWindowScene_Title_Subtitle,
                ]
                table[LookinAttrSec_UIWindowScene_Orientation] = [LookinAttr_UIWindowScene_Orientation_InterfaceOrientation]
                table[LookinAttrSec_UIWindowScene_Windows] = [
                    LookinAttr_UIWindowScene_Windows_WindowCount,
                    LookinAttr_UIWindowScene_Windows_KeyWindowClassName,
                ]
                table[LookinAttrSec_UIWindowScene_Screen] = [
                    LookinAttr_UIWindowScene_Screen_ScreenBounds,
                    LookinAttr_UIWindowScene_Screen_ScreenScale,
                ]
                table[LookinAttrSec_UIWindowScene_StatusBar] = [
                    LookinAttr_UIWindowScene_StatusBar_StatusBarHidden,
                    LookinAttr_UIWindowScene_StatusBar_StatusBarStyle,
                    LookinAttr_UIWindowScene_StatusBar_StatusBarFrame,
                ]
                table[LookinAttrSec_UIWindowScene_Traits] = [
                    LookinAttr_UIWindowScene_Traits_UserInterfaceStyle,
                    LookinAttr_UIWindowScene_Traits_HorizontalSizeClass,
                    LookinAttr_UIWindowScene_Traits_VerticalSizeClass,
                    LookinAttr_UIWindowScene_Traits_UserInterfaceLevel,
                    LookinAttr_UIWindowScene_Traits_ActiveAppearance,
                    LookinAttr_UIWindowScene_Traits_AccessibilityContrast,
                    LookinAttr_UIWindowScene_Traits_LegibilityWeight,
                    LookinAttr_UIWindowScene_Traits_DisplayScale,
                    LookinAttr_UIWindowScene_Traits_DisplayGamut,
                    LookinAttr_UIWindowScene_Traits_UserInterfaceIdiom,
                    LookinAttr_UIWindowScene_Traits_LayoutDirection,
                    LookinAttr_UIWindowScene_Traits_PreferredContentSizeCategory,
                    LookinAttr_UIWindowScene_Traits_SceneCaptureState,
                    LookinAttr_UIWindowScene_Traits_ImageDynamicRange,
                    LookinAttr_UIWindowScene_Traits_TypesettingLanguage,
                ]
                table[LookinAttrSec_UIWindowScene_Session] = [
                    LookinAttr_UIWindowScene_Session_PersistentIdentifier,
                    LookinAttr_UIWindowScene_Session_SessionRole,
                    LookinAttr_UIWindowScene_Session_StateRestorationActivityType,
                    LookinAttr_UIWindowScene_Session_UserInfo,
                ]
                table[LookinAttrSec_UIWindowScene_Configuration] = [
                    LookinAttr_UIWindowScene_Configuration_Name,
                    LookinAttr_UIWindowScene_Configuration_SceneClass,
                    LookinAttr_UIWindowScene_Configuration_DelegateClass,
                    LookinAttr_UIWindowScene_Configuration_Storyboard,
                ]
                table[LookinAttrSec_UIWindowScene_Geometry] = [
                    LookinAttr_UIWindowScene_Geometry_SystemFrame,
                    LookinAttr_UIWindowScene_Geometry_InterfaceOrientationLocked,
                    LookinAttr_UIWindowScene_Geometry_InteractivelyResizing,
                ]
                table[LookinAttrSec_UIWindowScene_ActivationConditions] = [
                    LookinAttr_UIWindowScene_ActivationConditions_CanActivate,
                    LookinAttr_UIWindowScene_ActivationConditions_PrefersToActivate,
                ]
                table[LookinAttrSec_UIWindowScene_SizeRestrictions] = [
                    LookinAttr_UIWindowScene_SizeRestrictions_MinimumSize,
                    LookinAttr_UIWindowScene_SizeRestrictions_MaximumSize,
                    LookinAttr_UIWindowScene_SizeRestrictions_AllowsFullScreen,
                ]
                table[LookinAttrSec_UIWindowScene_WindowingBehaviors] = [
                    LookinAttr_UIWindowScene_WindowingBehaviors_Closable,
                    LookinAttr_UIWindowScene_WindowingBehaviors_Miniaturizable,
                    LookinAttr_UIWindowScene_WindowingBehaviors_FullScreen,
                ]
                table[LookinAttrSec_UIWindowScene_Pointer] = [LookinAttr_UIWindowScene_Pointer_Locked]
                table[LookinAttrSec_UIWindowScene_Protection] = [LookinAttr_UIWindowScene_Protection_UserAuthenticationEnabled]
                // UITraitCollection
                table[LookinAttrSec_UITraitCollection_Appearance] = [
                    LookinAttr_UITraitCollection_Appearance_UserInterfaceStyle,
                    LookinAttr_UITraitCollection_Appearance_UserInterfaceLevel,
                    LookinAttr_UITraitCollection_Appearance_ActiveAppearance,
                    LookinAttr_UITraitCollection_Appearance_AccessibilityContrast,
                    LookinAttr_UITraitCollection_Appearance_LegibilityWeight,
                ]
                table[LookinAttrSec_UITraitCollection_SizeClass] = [
                    LookinAttr_UITraitCollection_SizeClass_HorizontalSizeClass,
                    LookinAttr_UITraitCollection_SizeClass_VerticalSizeClass,
                ]
                table[LookinAttrSec_UITraitCollection_Display] = [
                    LookinAttr_UITraitCollection_Display_DisplayScale,
                    LookinAttr_UITraitCollection_Display_DisplayGamut,
                    LookinAttr_UITraitCollection_Display_ImageDynamicRange,
                ]
                table[LookinAttrSec_UITraitCollection_Device] = [
                    LookinAttr_UITraitCollection_Device_UserInterfaceIdiom,
                    LookinAttr_UITraitCollection_Device_ForceTouchCapability,
                ]
                table[LookinAttrSec_UITraitCollection_Layout] = [LookinAttr_UITraitCollection_Layout_LayoutDirection]
                table[LookinAttrSec_UITraitCollection_Content] = [
                    LookinAttr_UITraitCollection_Content_PreferredContentSizeCategory,
                    LookinAttr_UITraitCollection_Content_TypesettingLanguage,
                ]
            #endif
            #if os(macOS)
                table[LookinAttrSec_NSImageView_Name] = [LookinAttr_NSImageView_Name_Name]
                table[LookinAttrSec_NSImageView_Open] = [LookinAttr_NSImageView_Open_Open]
                table[LookinAttrSec_NSImageView_Scaling] = [
                    LookinAttr_NSImageView_Scaling_ImageScaling,
                    LookinAttr_NSImageView_Scaling_ImageAlignment,
                    LookinAttr_NSImageView_Scaling_ImageFrameStyle,
                ]
                table[LookinAttrSec_NSImageView_Behavior] = [
                    LookinAttr_NSImageView_Behavior_Animates,
                    LookinAttr_NSImageView_Behavior_Editable,
                ]
                table[LookinAttrSec_NSImageView_ContentTintColor] = [LookinAttr_NSImageView_ContentTintColor_ContentTintColor]
                table[LookinAttrSec_NSControl_State] = [
                    LookinAttr_NSControl_State_Enabled,
                    LookinAttr_NSControl_State_Highlighted,
                    LookinAttr_NSControl_State_Continuous,
                ]
                table[LookinAttrSec_NSControl_ControlSize] = [LookinAttr_NSControl_ControlSize_Size]
                table[LookinAttrSec_NSControl_Font] = [
                    LookinAttr_NSControl_Font_Name,
                    LookinAttr_NSControl_Font_Size,
                ]
                table[LookinAttrSec_NSControl_Alignment] = [LookinAttr_NSControl_Alignment_Alignment]
                table[LookinAttrSec_NSControl_Misc] = [
                    LookinAttr_NSControl_Misc_WritingDirection,
                    LookinAttr_NSControl_Misc_IgnoresMultiClick,
                    LookinAttr_NSControl_Misc_UsesSingleLineMode,
                    LookinAttr_NSControl_Misc_AllowsExpansionToolTips,
                ]
                table[LookinAttrSec_NSControl_StringValue] = [LookinAttr_NSControl_Value_StringValue]
                table[LookinAttrSec_NSControl_Value] = [
                    LookinAttr_NSControl_Value_IntValue,
                    LookinAttr_NSControl_Value_IntegerValue,
                    LookinAttr_NSControl_Value_FloatValue,
                    LookinAttr_NSControl_Value_DoubleValue,
                ]
                table[LookinAttrSec_NSButton_ButtonType] = [LookinAttr_NSButton_ButtonType_ButtonType]
                table[LookinAttrSec_NSButton_Title] = [
                    LookinAttr_NSButton_Title_Title,
                    LookinAttr_NSButton_Title_AlernateTitle,
                ]
                table[LookinAttrSec_NSButton_BezelStyle] = [LookinAttr_NSButton_BezelStyle_BezelStyle]
                table[LookinAttrSec_NSButton_Bordered] = [
                    LookinAttr_NSButton_Bordered_Bordered,
                    LookinAttr_NSButton_Transparent_Transparent,
                    LookinAttr_NSButton_Misc_ShowsBorderOnlyWhileMouseInside,
                    LookinAttr_NSButton_Misc_SpringLoaded,
                    LookinAttr_NSButton_Misc_HasDestructiveAction,
                ]
                table[LookinAttrSec_NSButton_BezelColor] = [
                    LookinAttr_NSButton_BezelColor_BezelColor,
                    LookinAttr_NSButton_ContentTintColor_ContentTintColor,
                ]
                table[LookinAttrSec_NSButton_Misc] = [LookinAttr_NSButton_Misc_MaxAcceleratorLevel]
                table[LookinAttrSec_NSScrollView_ContentOffset] = [LookinAttr_NSScrollView_ContentOffset_Offset]
                table[LookinAttrSec_NSScrollView_ContentSize] = [LookinAttr_NSScrollView_ContentSize_Size]
                table[LookinAttrSec_NSScrollView_ContentInset] = [
                    LookinAttr_NSScrollView_ContentInset_ContentInset,
                    LookinAttr_NSScrollView_ContentInset_AutomaticallyAdjustsContentInsets,
                ]
                table[LookinAttrSec_NSScrollView_BorderType] = [LookinAttr_NSScrollView_BorderType_BorderType]
                table[LookinAttrSec_NSScrollView_Scroller] = [
                    LookinAttr_NSScrollView_Scroller_Horizontal,
                    LookinAttr_NSScrollView_Scroller_Vertical,
                    LookinAttr_NSScrollView_Scroller_AutohidesScrollers,
                    LookinAttr_NSScrollView_Scroller_ScrollerStyle,
                    LookinAttr_NSScrollView_Scroller_ScrollerKnobStyle,
                    LookinAttr_NSScrollView_Scroller_ScrollerInsets,
                ]
                table[LookinAttrSec_NSScrollView_Ruler] = [
                    LookinAttr_NSScrollView_Ruler_Horizontal,
                    LookinAttr_NSScrollView_Ruler_Vertical,
                    LookinAttr_NSScrollView_Ruler_Visible,
                ]
                table[LookinAttrSec_NSScrollView_LineScroll] = [
                    LookinAttr_NSScrollView_LineScroll_Horizontal,
                    LookinAttr_NSScrollView_LineScroll_Vertical,
                    LookinAttr_NSScrollView_LineScroll_LineScroll,
                ]
                table[LookinAttrSec_NSScrollView_PageScroll] = [
                    LookinAttr_NSScrollView_PageScroll_Horizontal,
                    LookinAttr_NSScrollView_PageScroll_Vertical,
                    LookinAttr_NSScrollView_PageScroll_PageScroll,
                ]
                table[LookinAttrSec_NSScrollView_ScrollElasiticity] = [
                    LookinAttr_NSScrollView_ScrollElasiticity_Horizontal,
                    LookinAttr_NSScrollView_ScrollElasiticity_Vertical,
                ]
                table[LookinAttrSec_NSScrollView_Misc] = [
                    LookinAttr_NSScrollView_Misc_ScrollsDynamically,
                    LookinAttr_NSScrollView_Misc_UsesPredominantAxisScrolling,
                ]
                table[LookinAttrSec_NSScrollView_Magnification] = [
                    LookinAttr_NSScrollView_Magnification_AllowsMagnification,
                    LookinAttr_NSScrollView_Magnification_Magnification,
                    LookinAttr_NSScrollView_Magnification_Max,
                    LookinAttr_NSScrollView_Magnification_Min,
                ]
                table[LookinAttrSec_NSTableView_RowHeight] = [LookinAttr_NSTableView_RowHeight_RowHeight]
                table[LookinAttrSec_NSTableView_AutomaticRowHeights] = [LookinAttr_NSTableView_AutomaticRowHeights_AutomaticRowHeights]
                table[LookinAttrSec_NSTableView_IntercellSpacing] = [LookinAttr_NSTableView_IntercellSpacing_IntercellSpacing]
                table[LookinAttrSec_NSTableView_Style] = [LookinAttr_NSTableView_Style_Style]
                table[LookinAttrSec_NSTableView_ColumnAutoresizingStyle] = [LookinAttr_NSTableView_ColumnAutoresizingStyle_ColumnAutoresizingStyle]
                table[LookinAttrSec_NSTableView_GridStyleMask] = [LookinAttr_NSTableView_GridStyleMask_GridStyleMask]
                table[LookinAttrSec_NSTableView_SelectionHighlightStyle] = [LookinAttr_NSTableView_SelectionHighlightStyle_SelectionHighlightStyle]
                table[LookinAttrSec_NSTableView_GridColor] = [LookinAttr_NSTableView_GridColor_GridColor]
                table[LookinAttrSec_NSTableView_RowSizeStyle] = [LookinAttr_NSTableView_RowSizeStyle_RowSizeStyle]
                table[LookinAttrSec_NSTableView_NumberOfRows] = [LookinAttr_NSTableView_NumberOfRows_NumberOfRows]
                table[LookinAttrSec_NSTableView_NumberOfColumns] = [LookinAttr_NSTableView_NumberOfColumns_NumberOfColumns]
                table[LookinAttrSec_NSTableView_UseAlternatingRowBackgroundColors] = [LookinAttr_NSTableView_UseAlternatingRowBackgroundColors_UseAlternatingRowBackgroundColors]
                table[LookinAttrSec_NSTableView_AllowsColumnReordering] = [LookinAttr_NSTableView_AllowsColumnReordering_AllowsColumnReordering]
                table[LookinAttrSec_NSTableView_AllowsColumnResizing] = [LookinAttr_NSTableView_AllowsColumnResizing_AllowsColumnResizing]
                table[LookinAttrSec_NSTableView_AllowsMultipleSelection] = [LookinAttr_NSTableView_AllowsMultipleSelection_AllowsMultipleSelection]
                table[LookinAttrSec_NSTableView_AllowsEmptySelection] = [LookinAttr_NSTableView_AllowsEmptySelection_AllowsEmptySelection]
                table[LookinAttrSec_NSTableView_AllowsColumnSelection] = [LookinAttr_NSTableView_AllowsColumnSelection_AllowsColumnSelection]
                table[LookinAttrSec_NSTableView_AllowsTypeSelect] = [LookinAttr_NSTableView_AllowsTypeSelect_AllowsTypeSelect]
                table[LookinAttrSec_NSTableView_DraggingDestinationFeedbackStyle] = [LookinAttr_NSTableView_DraggingDestinationFeedbackStyle_DraggingDestinationFeedbackStyle]
                table[LookinAttrSec_NSTableView_Autosave] = [
                    LookinAttr_NSTableView_AutosaveName_AutosaveName,
                    LookinAttr_NSTableView_AutosaveTableColumns_AutosaveTableColumns,
                ]
                table[LookinAttrSec_NSTableView_FloatsGroupRows] = [LookinAttr_NSTableView_FloatsGroupRows_FloatsGroupRows]
                table[LookinAttrSec_NSTableView_RowActionsVisible] = [LookinAttr_NSTableView_RowActionsVisible_RowActionsVisible]
                table[LookinAttrSec_NSTableView_UsesStaticContents] = [LookinAttr_NSTableView_UsesStaticContents_UsesStaticContents]
                table[LookinAttrSec_NSTableView_UserInterfaceLayoutDirection] = [LookinAttr_NSTableView_UserInterfaceLayoutDirection_UserInterfaceLayoutDirection]
                table[LookinAttrSec_NSTableView_VerticalMotionCanBeginDrag] = [LookinAttr_NSTableView_VerticalMotionCanBeginDrag_VerticalMotionCanBeginDrag]
                table[LookinAttrSec_NSTextView_Font] = [
                    LookinAttr_NSTextView_Font_Name,
                    LookinAttr_NSTextView_Font_Size,
                ]
                table[LookinAttrSec_NSTextView_Basic] = [
                    LookinAttr_NSTextView_Basic_Editable,
                    LookinAttr_NSTextView_Basic_Selectable,
                    LookinAttr_NSTextView_Basic_RichText,
                    LookinAttr_NSTextView_Basic_FieldEditor,
                    LookinAttr_NSTextView_Basic_ImportsGraphics,
                ]
                table[LookinAttrSec_NSTextView_String] = [LookinAttr_NSTextView_String_String]
                table[LookinAttrSec_NSTextView_TextColor] = [LookinAttr_NSTextView_TextColor_Color]
                table[LookinAttrSec_NSTextView_Alignment] = [LookinAttr_NSTextView_Alignment_Alignment]
                table[LookinAttrSec_NSTextView_ContainerInset] = [LookinAttr_NSTextView_ContainerInset_Inset]
                table[LookinAttrSec_NSTextView_BaseWritingDirection] = [LookinAttr_NSTextView_BaseWritingDirection_BaseWritingDirection]
                table[LookinAttrSec_NSTextView_Size] = [
                    LookinAttr_NSTextView_MaxSize_MaxSize,
                    LookinAttr_NSTextView_MinSize_MinSize,
                ]
                table[LookinAttrSec_NSTextView_Resizable] = [
                    LookinAttr_NSTextView_Resizable_Horizontal,
                    LookinAttr_NSTextView_Resizable_Vertical,
                ]
                table[LookinAttrSec_NSTextField_BezelStyle] = [LookinAttr_NSTextField_BezelStyle_BezelStyle]
                table[LookinAttrSec_NSTextField_Bordered] = [
                    LookinAttr_NSTextField_Bordered_Bordered,
                    LookinAttr_NSTextField_Bezeled_Bezeled,
                    LookinAttr_NSTextField_Editable_Editable,
                    LookinAttr_NSTextField_Selectable_Selectable,
                    LookinAttr_NSTextField_DrawsBackground_DrawsBackground,
                    LookinAttr_NSTextField_AllowsDefaultTighteningForTruncation_AllowsDefaultTighteningForTruncation,
                    LookinAttr_NSTextField_AllowsEditingTextAttributes_AllowsEditingTextAttributes,
                    LookinAttr_NSTextField_ImportsGraphics_ImportsGraphics,
                ]
                table[LookinAttrSec_NSTextField_TextColor] = [
                    LookinAttr_NSTextField_TextColor_Color,
                    LookinAttr_NSTextField_BackgroundColor_Color,
                ]
                table[LookinAttrSec_NSTextField_Placeholder] = [LookinAttr_NSTextField_Placeholder_Placeholder]
                table[LookinAttrSec_NSTextField_LineBreakStrategy] = [LookinAttr_NSTextField_LineBreakStrategy_LineBreakStrategy]
                table[LookinAttrSec_NSTextField_PreferredMaxLayoutWidth] = [
                    LookinAttr_NSTextField_PreferredMaxLayoutWidth_PreferredMaxLayoutWidth,
                    LookinAttr_NSTextField_MaximumNumberOfLines_MaximumNumberOfLines,
                ]
                table[LookinAttrSec_NSVisualEffectView_Material] = [LookinAttr_NSVisualEffectView_Material_Material]
                table[LookinAttrSec_NSVisualEffectView_InteriorBackgroundStyle] = [LookinAttr_NSVisualEffectView_InteriorBackgroundStyle_InteriorBackgroundStyle]
                table[LookinAttrSec_NSVisualEffectView_BlendingMode] = [LookinAttr_NSVisualEffectView_BlendingMode_BlendingMode]
                table[LookinAttrSec_NSVisualEffectView_State] = [LookinAttr_NSVisualEffectView_State_State]
                table[LookinAttrSec_NSVisualEffectView_Emphasized] = [LookinAttr_NSVisualEffectView_Emphasized_Emphasized]
                table[LookinAttrSec_NSStackView_Orientation] = [LookinAttr_NSStackView_Orientation_Orientation]
                table[LookinAttrSec_NSStackView_EdgeInsets] = [LookinAttr_NSStackView_EdgeInsets_EdgeInsets]
                table[LookinAttrSec_NSStackView_DetachesHiddenViews] = [LookinAttr_NSStackView_DetachesHiddenViews_DetachesHiddenViews]
                table[LookinAttrSec_NSStackView_Distribution] = [LookinAttr_NSStackView_Distribution_Distribution]
                table[LookinAttrSec_NSStackView_Alignment] = [LookinAttr_NSStackView_Alignment_Alignment]
                table[LookinAttrSec_NSStackView_Spacing] = [LookinAttr_NSStackView_Spacing_Spacing]
                table[LookinAttrSec_NSWindow_Title] = [LookinAttr_NSWindow_Title_Title]
                table[LookinAttrSec_NSWindow_Subtitle] = [LookinAttr_NSWindow_Title_Subtitle]
                table[LookinAttrSec_NSWindow_State] = [
                    LookinAttr_NSWindow_State_KeyWindow,
                    LookinAttr_NSWindow_State_MainWindow,
                    LookinAttr_NSWindow_State_Visible,
                    LookinAttr_NSWindow_State_CanBecomeKeyWindow,
                    LookinAttr_NSWindow_State_CanBecomeMainWindow,
                ]
                table[LookinAttrSec_NSWindow_Style] = [
                    LookinAttr_NSWindow_Style_Titled,
                    LookinAttr_NSWindow_Style_Closable,
                    LookinAttr_NSWindow_Style_Miniaturizable,
                    LookinAttr_NSWindow_Style_Resizable,
                    LookinAttr_NSWindow_Style_UnifiedTitleAndToolbar,
                    LookinAttr_NSWindow_Style_FullScreen,
                    LookinAttr_NSWindow_Style_FullSizeContentView,
                    LookinAttr_NSWindow_Style_UtilityWindow,
                    LookinAttr_NSWindow_Style_DocModalWindow,
                    LookinAttr_NSWindow_Style_NonactivatingPanel,
                    LookinAttr_NSWindow_Style_HUDWindow,
                ]
                table[LookinAttrSec_NSWindow_CollectionBehavior] = [
                    LookinAttr_NSWindow_CollectionBehavior_CanJoinAllSpaces,
                    LookinAttr_NSWindow_CollectionBehavior_MoveToActiveSpace,
                    LookinAttr_NSWindow_CollectionBehavior_ParticipatesInCycle,
                    LookinAttr_NSWindow_CollectionBehavior_IgnoresCycle,
                    LookinAttr_NSWindow_CollectionBehavior_FullScreenPrimary,
                    LookinAttr_NSWindow_CollectionBehavior_FullScreenAuxiliary,
                    LookinAttr_NSWindow_CollectionBehavior_FullScreenNone,
                    LookinAttr_NSWindow_CollectionBehavior_FullScreenAllowsTiling,
                    LookinAttr_NSWindow_CollectionBehavior_FullScreenDisallowsTiling,
                ]
                table[LookinAttrSec_NSWindow_Appearance] = [
                    LookinAttr_NSWindow_Appearance_TitlebarAppearsTransparent,
                    LookinAttr_NSWindow_Appearance_BackgroundColor,
                    LookinAttr_NSWindow_Appearance_AlphaValue,
                    LookinAttr_NSWindow_Appearance_Opaque,
                    LookinAttr_NSWindow_Appearance_HasShadow,
                ]
                table[LookinAttrSec_NSWindow_TitleVisibility] = [LookinAttr_NSWindow_Appearance_TitleVisibility]
                table[LookinAttrSec_NSWindow_ToolbarStyle] = [LookinAttr_NSWindow_Appearance_ToolbarStyle]
                table[LookinAttrSec_NSWindow_TitlebarSeparatorStyle] = [LookinAttr_NSWindow_Appearance_TitlebarSeparatorStyle]
                table[LookinAttrSec_NSWindow_Behavior] = [
                    LookinAttr_NSWindow_Behavior_Movable,
                    LookinAttr_NSWindow_Behavior_MovableByWindowBackground,
                    LookinAttr_NSWindow_Behavior_HidesOnDeactivate,
                ]
                table[LookinAttrSec_NSWindow_AnimationBehavior] = [LookinAttr_NSWindow_Behavior_AnimationBehavior]
                table[LookinAttrSec_NSWindow_Level] = [LookinAttr_NSWindow_Behavior_Level]
                table[LookinAttrSec_NSWindow_TabbingMode] = [LookinAttr_NSWindow_Behavior_TabbingMode]
                table[LookinAttrSec_NSWindow_Size] = [
                    LookinAttr_NSWindow_Size_MinSize,
                    LookinAttr_NSWindow_Size_MaxSize,
                ]
                table[LookinAttrSec_NSWindow_Info] = [
                    LookinAttr_NSWindow_Info_WindowNumber,
                    LookinAttr_NSWindow_Info_BackingScaleFactor,
                ]
                table[LookinAttrSec_NSSlider_SliderType] = [LookinAttr_NSSlider_SliderType_SliderType]
                table[LookinAttrSec_NSSlider_Range] = [
                    LookinAttr_NSSlider_Range_MinValue,
                    LookinAttr_NSSlider_Range_MaxValue,
                ]
                table[LookinAttrSec_NSSlider_TickMark] = [
                    LookinAttr_NSSlider_TickMark_NumberOfTickMarks,
                    LookinAttr_NSSlider_TickMark_TickMarkPosition,
                    LookinAttr_NSSlider_TickMark_AllowsTickMarkValuesOnly,
                ]
                table[LookinAttrSec_NSSlider_Misc] = [
                    LookinAttr_NSSlider_Misc_Vertical,
                    LookinAttr_NSSlider_Misc_KnobThickness,
                    LookinAttr_NSSlider_Misc_AltIncrementValue,
                    LookinAttr_NSSlider_Misc_TrackFillColor,
                ]
                table[LookinAttrSec_NSProgressIndicator_Style] = [LookinAttr_NSProgressIndicator_Style_Style]
                table[LookinAttrSec_NSProgressIndicator_Range] = [
                    LookinAttr_NSProgressIndicator_Range_MinValue,
                    LookinAttr_NSProgressIndicator_Range_MaxValue,
                    LookinAttr_NSProgressIndicator_Range_DoubleValue,
                ]
                table[LookinAttrSec_NSProgressIndicator_Misc] = [
                    LookinAttr_NSProgressIndicator_Misc_Indeterminate,
                    LookinAttr_NSProgressIndicator_Misc_Bezeled,
                    LookinAttr_NSProgressIndicator_Misc_DisplayedWhenStopped,
                ]
                table[LookinAttrSec_NSSegmentedControl_SegmentCount] = [LookinAttr_NSSegmentedControl_SegmentCount_SegmentCount]
                table[LookinAttrSec_NSSegmentedControl_Selection] = [LookinAttr_NSSegmentedControl_Selection_SelectedSegment]
                table[LookinAttrSec_NSSegmentedControl_Style] = [
                    LookinAttr_NSSegmentedControl_Style_SegmentStyle,
                    LookinAttr_NSSegmentedControl_Style_TrackingMode,
                ]
                table[LookinAttrSec_NSSegmentedControl_Colors] = [LookinAttr_NSSegmentedControl_Colors_SelectedSegmentBezelColor]
                table[LookinAttrSec_NSPopUpButton_Behavior] = [
                    LookinAttr_NSPopUpButton_Behavior_PullsDown,
                    LookinAttr_NSPopUpButton_Behavior_AutoenablesItems,
                    LookinAttr_NSPopUpButton_Behavior_PreferredEdge,
                ]
                table[LookinAttrSec_NSPopUpButton_Selection] = [
                    LookinAttr_NSPopUpButton_Selection_SelectedTag,
                    LookinAttr_NSPopUpButton_Selection_IndexOfSelectedItem,
                    LookinAttr_NSPopUpButton_Selection_TitleOfSelectedItem,
                ]
                table[LookinAttrSec_NSPopUpButton_Items] = [LookinAttr_NSPopUpButton_Items_NumberOfItems]
                table[LookinAttrSec_NSComboBox_Items] = [
                    LookinAttr_NSComboBox_Items_NumberOfItems,
                    LookinAttr_NSComboBox_Items_HasVerticalScroller,
                    LookinAttr_NSComboBox_Items_NumberOfVisibleItems,
                    LookinAttr_NSComboBox_Items_IntercellSpacing,
                    LookinAttr_NSComboBox_Items_ItemHeight,
                ]
                table[LookinAttrSec_NSComboBox_Misc] = [
                    LookinAttr_NSComboBox_Misc_ButtonBordered,
                    LookinAttr_NSComboBox_Misc_Completes,
                    LookinAttr_NSComboBox_Misc_UsesDataSource,
                ]
                table[LookinAttrSec_NSStepper_Range] = [
                    LookinAttr_NSStepper_Range_MinValue,
                    LookinAttr_NSStepper_Range_MaxValue,
                    LookinAttr_NSStepper_Range_Increment,
                ]
                table[LookinAttrSec_NSStepper_Misc] = [
                    LookinAttr_NSStepper_Misc_ValueWraps,
                    LookinAttr_NSStepper_Misc_Autorepeat,
                ]
                table[LookinAttrSec_NSColorWell_Color] = [LookinAttr_NSColorWell_Color_Color]
                table[LookinAttrSec_NSColorWell_Misc] = [
                    LookinAttr_NSColorWell_Misc_Bordered,
                    LookinAttr_NSColorWell_Misc_Active,
                    LookinAttr_NSColorWell_Misc_ColorWellStyle,
                ]
                table[LookinAttrSec_NSSwitch_State] = [LookinAttr_NSSwitch_State_State]
                table[LookinAttrSec_NSDatePicker_Style] = [
                    LookinAttr_NSDatePicker_Style_DatePickerStyle,
                    LookinAttr_NSDatePicker_Style_DatePickerMode,
                ]
                table[LookinAttrSec_NSDatePicker_Range] = [
                    LookinAttr_NSDatePicker_Range_DateValue,
                    LookinAttr_NSDatePicker_Range_MinDate,
                    LookinAttr_NSDatePicker_Range_MaxDate,
                ]
                table[LookinAttrSec_NSDatePicker_Misc] = [
                    LookinAttr_NSDatePicker_Misc_Bordered,
                    LookinAttr_NSDatePicker_Misc_Bezeled,
                    LookinAttr_NSDatePicker_Misc_DrawsBackground,
                ]
                table[LookinAttrSec_NSLevelIndicator_Style] = [LookinAttr_NSLevelIndicator_Style_Style]
                table[LookinAttrSec_NSLevelIndicator_Range] = [
                    LookinAttr_NSLevelIndicator_Range_MinValue,
                    LookinAttr_NSLevelIndicator_Range_MaxValue,
                    LookinAttr_NSLevelIndicator_Range_WarningValue,
                    LookinAttr_NSLevelIndicator_Range_CriticalValue,
                ]
                table[LookinAttrSec_NSLevelIndicator_TickMark] = [
                    LookinAttr_NSLevelIndicator_TickMark_NumberOfTickMarks,
                    LookinAttr_NSLevelIndicator_TickMark_NumberOfMajorTickMarks,
                ]
                table[LookinAttrSec_NSOutlineView_Indentation] = [LookinAttr_NSOutlineView_Indentation_IndentationPerLevel]
                table[LookinAttrSec_NSOutlineView_Misc] = [
                    LookinAttr_NSOutlineView_Misc_AutoresizesOutlineColumn,
                    LookinAttr_NSOutlineView_Misc_IndentationMarkerFollowsCell,
                    LookinAttr_NSOutlineView_Misc_AutosaveExpandedItems,
                ]
                table[LookinAttrSec_NSCollectionView_Selection] = [
                    LookinAttr_NSCollectionView_Selection_Selectable,
                    LookinAttr_NSCollectionView_Selection_AllowsMultipleSelection,
                    LookinAttr_NSCollectionView_Selection_AllowsEmptySelection,
                ]
                table[LookinAttrSec_NSCollectionView_Info] = [LookinAttr_NSCollectionView_Info_NumberOfSections]
                table[LookinAttrSec_NSCollectionView_Colors] = [LookinAttr_NSCollectionView_Colors_BackgroundColors]
                table[LookinAttrSec_NSBox_Type] = [
                    LookinAttr_NSBox_Type_BoxType,
                    LookinAttr_NSBox_Type_BorderType,
                ]
                table[LookinAttrSec_NSBox_Title] = [
                    LookinAttr_NSBox_Title_Title,
                    LookinAttr_NSBox_Title_TitlePosition,
                ]
                table[LookinAttrSec_NSBox_Appearance] = [
                    LookinAttr_NSBox_Appearance_Transparent,
                    LookinAttr_NSBox_Appearance_FillColor,
                    LookinAttr_NSBox_Appearance_BorderColor,
                ]
                table[LookinAttrSec_NSBox_Metrics] = [
                    LookinAttr_NSBox_Metrics_BorderWidth,
                    LookinAttr_NSBox_Metrics_CornerRadius,
                    LookinAttr_NSBox_Metrics_ContentViewMargins,
                ]
                table[LookinAttrSec_NSSplitView_Orientation] = [LookinAttr_NSSplitView_Orientation_Vertical]
                table[LookinAttrSec_NSSplitView_Style] = [
                    LookinAttr_NSSplitView_Style_DividerStyle,
                    LookinAttr_NSSplitView_Style_DividerThickness,
                ]
                table[LookinAttrSec_NSSplitView_Misc] = [LookinAttr_NSSplitView_Misc_ArrangesAllSubviews]
                table[LookinAttrSec_NSTabView_Type] = [
                    LookinAttr_NSTabView_Type_TabViewType,
                    LookinAttr_NSTabView_Type_TabPosition,
                    LookinAttr_NSTabView_Type_TabViewBorderType,
                ]
                table[LookinAttrSec_NSTabView_Misc] = [
                    LookinAttr_NSTabView_Misc_AllowsTruncatedLabels,
                    LookinAttr_NSTabView_Misc_DrawsBackground,
                ]
                table[LookinAttrSec_NSTabView_Info] = [LookinAttr_NSTabView_Info_NumberOfTabViewItems]
                table[LookinAttrSec_NSGridView_Dimensions] = [
                    LookinAttr_NSGridView_Dimensions_NumberOfColumns,
                    LookinAttr_NSGridView_Dimensions_NumberOfRows,
                ]
                table[LookinAttrSec_NSGridView_Spacing] = [
                    LookinAttr_NSGridView_Spacing_RowSpacing,
                    LookinAttr_NSGridView_Spacing_ColumnSpacing,
                ]
                table[LookinAttrSec_NSGridView_Placement] = [
                    LookinAttr_NSGridView_Placement_XPlacement,
                    LookinAttr_NSGridView_Placement_YPlacement,
                ]
            #endif
            table[LookinAttrSec_LayoutGuide_Identifier] = [LookinAttr_LayoutGuide_Identifier_Identifier]
            table[LookinAttrSec_LayoutGuide_LayoutFrame] = [LookinAttr_LayoutGuide_LayoutFrame_LayoutFrame]
            table[LookinAttrSec_LayoutGuide_OwningView] = [LookinAttr_LayoutGuide_OwningView_OwningView]
            table[LookinAttrSec_NSCell_Cell] = [
                LookinAttr_NSCell_Cell_Type,
                LookinAttr_NSCell_Cell_State,
                LookinAttr_NSCell_Cell_Enabled,
                LookinAttr_NSCell_Cell_Bordered,
                LookinAttr_NSCell_Cell_Bezeled,
                LookinAttr_NSCell_Cell_Highlighted,
                LookinAttr_NSCell_Cell_Editable,
                LookinAttr_NSCell_Cell_Selectable,
                LookinAttr_NSCell_Cell_Alignment,
                LookinAttr_NSCell_Cell_ControlSize,
            ]
            table[LookinAttrSec_NSCell_Content] = [
                LookinAttr_NSCell_Content_Title,
                LookinAttr_NSCell_Content_FontName,
                LookinAttr_NSCell_Content_FontSize,
                LookinAttr_NSCell_Content_LineBreakMode,
                LookinAttr_NSCell_Content_Wraps,
            ]
            table[LookinAttrSec_NSCell_Behavior] = [
                LookinAttr_NSCell_Behavior_Tag,
                LookinAttr_NSCell_Behavior_Continuous,
                LookinAttr_NSCell_Behavior_AllowsMixedState,
                LookinAttr_NSCell_Behavior_SendsActionOnEndEditing,
            ]
            table[LookinAttrSec_NSCell_ButtonCell] = [
                LookinAttr_NSCell_ButtonCell_BezelStyle,
                LookinAttr_NSCell_ButtonCell_ImagePosition,
                LookinAttr_NSCell_ButtonCell_ShowsBorderOnlyWhileMouseInside,
                LookinAttr_NSCell_ButtonCell_KeyEquivalent,
                LookinAttr_NSCell_ButtonCell_AlternateTitle,
            ]
            table[LookinAttrSec_NSCell_TextFieldCell] = [
                LookinAttr_NSCell_TextFieldCell_Placeholder,
                LookinAttr_NSCell_TextFieldCell_DrawsBackground,
                LookinAttr_NSCell_TextFieldCell_TextColor,
                LookinAttr_NSCell_TextFieldCell_BackgroundColor,
                LookinAttr_NSCell_TextFieldCell_BezelStyle,
            ]
            return table
        }()
    }

#endif
