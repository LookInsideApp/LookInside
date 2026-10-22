//
//  DashboardBlueprint+Groups.swift
//  LookinCore
//
//  Group order, the sections of each group, and group and section titles.
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
        /// `+groupIDs`, in display order.
        static let groupIDs: [String] = {
            var ids: [String] = []
            ids += [
                LookinAttrGroup_Class,
                LookinAttrGroup_Relation,
                LookinAttrGroup_Layout,
                LookinAttrGroup_AutoLayout,
                LookinAttrGroup_ViewLayer,
            ]
            #if canImport(UIKit)
                ids += [
                    LookinAttrGroup_UIStackView,
                    LookinAttrGroup_UIVisualEffectView,
                    LookinAttrGroup_UIImageView,
                    LookinAttrGroup_UILabel,
                    LookinAttrGroup_UIControl,
                    LookinAttrGroup_UIButton,
                    LookinAttrGroup_UIScrollView,
                    LookinAttrGroup_UITableView,
                    LookinAttrGroup_UITextView,
                    LookinAttrGroup_UITextField,
                    LookinAttrGroup_UIWindowScene,
                    LookinAttrGroup_UITraitCollection,
                ]
            #endif
            #if os(macOS)
                ids += [
                    LookinAttrGroup_NSImageView,
                    LookinAttrGroup_NSControl,
                    LookinAttrGroup_NSButton,
                    LookinAttrGroup_NSScrollView,
                    LookinAttrGroup_NSTableView,
                    LookinAttrGroup_NSTextView,
                    LookinAttrGroup_NSTextField,
                    LookinAttrGroup_NSVisualEffectView,
                    LookinAttrGroup_NSStackView,
                    LookinAttrGroup_NSWindow,
                    LookinAttrGroup_NSSlider,
                    LookinAttrGroup_NSProgressIndicator,
                    LookinAttrGroup_NSSegmentedControl,
                    LookinAttrGroup_NSPopUpButton,
                    LookinAttrGroup_NSComboBox,
                    LookinAttrGroup_NSStepper,
                    LookinAttrGroup_NSColorWell,
                    LookinAttrGroup_NSSwitch,
                    LookinAttrGroup_NSDatePicker,
                    LookinAttrGroup_NSLevelIndicator,
                    LookinAttrGroup_NSOutlineView,
                    LookinAttrGroup_NSCollectionView,
                    LookinAttrGroup_NSBox,
                    LookinAttrGroup_NSSplitView,
                    LookinAttrGroup_NSTabView,
                    LookinAttrGroup_NSGridView,
                    LookinAttrGroup_NSCell,
                ]
            #endif
            // Platform-neutral: LayoutGuide nodes exist on both platforms
            ids.append(LookinAttrGroup_LayoutGuide)
            return ids
        }()

        /// `+sectionIDsForGroupID:`.
        static let sectionIDsByGroupID: [String: [String]] = {
            var table: [String: [String]] = [:]
            table[LookinAttrGroup_Class] = [LookinAttrSec_Class_Class]
            table[LookinAttrGroup_Relation] = [LookinAttrSec_Relation_Relation]
            table[LookinAttrGroup_Layout] = [
                LookinAttrSec_Layout_Frame,
                LookinAttrSec_Layout_Bounds,
                LookinAttrSec_Layout_SafeArea,
                LookinAttrSec_Layout_Position,
                LookinAttrSec_Layout_AnchorPoint,
                LookinAttrSec_Layout_CoordinateSpace,
            ]
            table[LookinAttrGroup_AutoLayout] = [
                LookinAttrSec_AutoLayout_Constraints,
                LookinAttrSec_AutoLayout_IntrinsicSize,
                LookinAttrSec_AutoLayout_Hugging,
                LookinAttrSec_AutoLayout_Resistance,
            ]
            table[LookinAttrGroup_ViewLayer] = {
                var ids: [String] = []
                ids += [
                    LookinAttrSec_ViewLayer_Visibility,
                    LookinAttrSec_ViewLayer_InterationAndMasks,
                    LookinAttrSec_ViewLayer_BgColor,
                    LookinAttrSec_ViewLayer_Border,
                    LookinAttrSec_ViewLayer_Corner,
                    LookinAttrSec_ViewLayer_Shadow,
                    LookinAttrSec_ViewLayer_Tag,
                ]
                #if canImport(UIKit)
                    ids += [
                        LookinAttrSec_ViewLayer_ContentMode,
                        LookinAttrSec_ViewLayer_TintColor,
                    ]
                #endif
                return ids
            }()
            #if canImport(UIKit)
                table[LookinAttrGroup_UIStackView] = [
                    LookinAttrSec_UIStackView_Axis,
                    LookinAttrSec_UIStackView_Distribution,
                    LookinAttrSec_UIStackView_Alignment,
                    LookinAttrSec_UIStackView_Spacing,
                ]
                table[LookinAttrGroup_UIVisualEffectView] = [
                    LookinAttrSec_UIVisualEffectView_Style,
                    LookinAttrSec_UIVisualEffectView_QMUIForegroundColor,
                ]
                table[LookinAttrGroup_UIImageView] = [
                    LookinAttrSec_UIImageView_Name,
                    LookinAttrSec_UIImageView_Open,
                ]
                table[LookinAttrGroup_UILabel] = [
                    LookinAttrSec_UILabel_Text,
                    LookinAttrSec_UILabel_Font,
                    LookinAttrSec_UILabel_NumberOfLines,
                    LookinAttrSec_UILabel_TextColor,
                    LookinAttrSec_UILabel_BreakMode,
                    LookinAttrSec_UILabel_Alignment,
                    LookinAttrSec_UILabel_CanAdjustFont,
                ]
                table[LookinAttrGroup_UIControl] = [
                    LookinAttrSec_UIControl_EnabledSelected,
                    LookinAttrSec_UIControl_QMUIOutsideEdge,
                    LookinAttrSec_UIControl_VerAlignment,
                    LookinAttrSec_UIControl_HorAlignment,
                ]
                table[LookinAttrGroup_UIButton] = [
                    LookinAttrSec_UIButton_ContentInsets,
                    LookinAttrSec_UIButton_TitleInsets,
                    LookinAttrSec_UIButton_ImageInsets,
                ]
                table[LookinAttrGroup_UIScrollView] = [
                    LookinAttrSec_UIScrollView_ContentInset,
                    LookinAttrSec_UIScrollView_AdjustedInset,
                    LookinAttrSec_UIScrollView_QMUIInitialInset,
                    LookinAttrSec_UIScrollView_IndicatorInset,
                    LookinAttrSec_UIScrollView_Offset,
                    LookinAttrSec_UIScrollView_ContentSize,
                    LookinAttrSec_UIScrollView_Behavior,
                    LookinAttrSec_UIScrollView_ShowsIndicator,
                    LookinAttrSec_UIScrollView_Bounce,
                    LookinAttrSec_UIScrollView_ScrollPaging,
                    LookinAttrSec_UIScrollView_ContentTouches,
                    LookinAttrSec_UIScrollView_Zoom,
                ]
                table[LookinAttrGroup_UITableView] = [
                    LookinAttrSec_UITableView_Style,
                    LookinAttrSec_UITableView_SectionsNumber,
                    LookinAttrSec_UITableView_RowsNumber,
                    LookinAttrSec_UITableView_SeparatorStyle,
                    LookinAttrSec_UITableView_SeparatorColor,
                    LookinAttrSec_UITableView_SeparatorInset,
                ]
                table[LookinAttrGroup_UITextView] = [
                    LookinAttrSec_UITextView_Basic,
                    LookinAttrSec_UITextView_Text,
                    LookinAttrSec_UITextView_Font,
                    LookinAttrSec_UITextView_TextColor,
                    LookinAttrSec_UITextView_Alignment,
                    LookinAttrSec_UITextView_ContainerInset,
                ]
                table[LookinAttrGroup_UITextField] = [
                    LookinAttrSec_UITextField_Text,
                    LookinAttrSec_UITextField_Placeholder,
                    LookinAttrSec_UITextField_Font,
                    LookinAttrSec_UITextField_TextColor,
                    LookinAttrSec_UITextField_Alignment,
                    LookinAttrSec_UITextField_Clears,
                    LookinAttrSec_UITextField_CanAdjustFont,
                    LookinAttrSec_UITextField_ClearButtonMode,
                ]
                table[LookinAttrGroup_UIWindowScene] = [
                    LookinAttrSec_UIWindowScene_State,
                    LookinAttrSec_UIWindowScene_Title,
                    LookinAttrSec_UIWindowScene_Orientation,
                    LookinAttrSec_UIWindowScene_Geometry,
                    LookinAttrSec_UIWindowScene_Windows,
                    LookinAttrSec_UIWindowScene_Screen,
                    LookinAttrSec_UIWindowScene_StatusBar,
                    LookinAttrSec_UIWindowScene_SizeRestrictions,
                    LookinAttrSec_UIWindowScene_WindowingBehaviors,
                    LookinAttrSec_UIWindowScene_Pointer,
                    LookinAttrSec_UIWindowScene_Protection,
                    LookinAttrSec_UIWindowScene_Traits,
                    LookinAttrSec_UIWindowScene_Session,
                    LookinAttrSec_UIWindowScene_Configuration,
                    LookinAttrSec_UIWindowScene_ActivationConditions,
                ]
                table[LookinAttrGroup_UITraitCollection] = [
                    LookinAttrSec_UITraitCollection_Appearance,
                    LookinAttrSec_UITraitCollection_SizeClass,
                    LookinAttrSec_UITraitCollection_Display,
                    LookinAttrSec_UITraitCollection_Device,
                    LookinAttrSec_UITraitCollection_Layout,
                    LookinAttrSec_UITraitCollection_Content,
                ]
            #endif
            #if os(macOS)
                table[LookinAttrGroup_NSImageView] = [
                    LookinAttrSec_NSImageView_Name,
                    LookinAttrSec_NSImageView_Open,
                    LookinAttrSec_NSImageView_Scaling,
                    LookinAttrSec_NSImageView_Behavior,
                    LookinAttrSec_NSImageView_ContentTintColor,
                ]
                table[LookinAttrGroup_NSControl] = [
                    LookinAttrSec_NSControl_State,
                    LookinAttrSec_NSControl_ControlSize,
                    LookinAttrSec_NSControl_Font,
                    LookinAttrSec_NSControl_Alignment,
                    LookinAttrSec_NSControl_Misc,
                    LookinAttrSec_NSControl_StringValue,
                    LookinAttrSec_NSControl_Value,
                ]
                table[LookinAttrGroup_NSButton] = [
                    LookinAttrSec_NSButton_ButtonType,
                    LookinAttrSec_NSButton_BezelStyle,
                    LookinAttrSec_NSButton_Title,
                    LookinAttrSec_NSButton_Bordered,
                    LookinAttrSec_NSButton_BezelColor,
                    LookinAttrSec_NSButton_Misc,
                ]
                table[LookinAttrGroup_NSScrollView] = [
                    LookinAttrSec_NSScrollView_ContentOffset,
                    LookinAttrSec_NSScrollView_ContentSize,
                    LookinAttrSec_NSScrollView_ContentInset,
                    LookinAttrSec_NSScrollView_BorderType,
                    LookinAttrSec_NSScrollView_Scroller,
                    LookinAttrSec_NSScrollView_Ruler,
                    LookinAttrSec_NSScrollView_LineScroll,
                    LookinAttrSec_NSScrollView_PageScroll,
                    LookinAttrSec_NSScrollView_ScrollElasiticity,
                    LookinAttrSec_NSScrollView_Misc,
                    LookinAttrSec_NSScrollView_Magnification,
                ]
                table[LookinAttrGroup_NSTableView] = [
                    LookinAttrSec_NSTableView_RowHeight,
                    LookinAttrSec_NSTableView_AutomaticRowHeights,
                    LookinAttrSec_NSTableView_IntercellSpacing,
                    LookinAttrSec_NSTableView_Style,
                    LookinAttrSec_NSTableView_ColumnAutoresizingStyle,
                    LookinAttrSec_NSTableView_GridStyleMask,
                    LookinAttrSec_NSTableView_SelectionHighlightStyle,
                    LookinAttrSec_NSTableView_GridColor,
                    LookinAttrSec_NSTableView_RowSizeStyle,
                    LookinAttrSec_NSTableView_NumberOfRows,
                    LookinAttrSec_NSTableView_NumberOfColumns,
                    LookinAttrSec_NSTableView_UseAlternatingRowBackgroundColors,
                    LookinAttrSec_NSTableView_AllowsColumnReordering,
                    LookinAttrSec_NSTableView_AllowsColumnResizing,
                    LookinAttrSec_NSTableView_AllowsMultipleSelection,
                    LookinAttrSec_NSTableView_AllowsEmptySelection,
                    LookinAttrSec_NSTableView_AllowsColumnSelection,
                    LookinAttrSec_NSTableView_AllowsTypeSelect,
                    LookinAttrSec_NSTableView_DraggingDestinationFeedbackStyle,
                    LookinAttrSec_NSTableView_Autosave,
                    LookinAttrSec_NSTableView_FloatsGroupRows,
                    LookinAttrSec_NSTableView_RowActionsVisible,
                    LookinAttrSec_NSTableView_UsesStaticContents,
                    LookinAttrSec_NSTableView_UserInterfaceLayoutDirection,
                    LookinAttrSec_NSTableView_VerticalMotionCanBeginDrag,
                ]
                table[LookinAttrGroup_NSTextView] = [
                    LookinAttrSec_NSTextView_Font,
                    LookinAttrSec_NSTextView_Basic,
                    LookinAttrSec_NSTextView_String,
                    LookinAttrSec_NSTextView_TextColor,
                    LookinAttrSec_NSTextView_Alignment,
                    LookinAttrSec_NSTextView_ContainerInset,
                    LookinAttrSec_NSTextView_BaseWritingDirection,
                    LookinAttrSec_NSTextView_Size,
                    LookinAttrSec_NSTextView_Resizable,
                ]
                table[LookinAttrGroup_NSTextField] = [
                    LookinAttrSec_NSTextField_BezelStyle,
                    LookinAttrSec_NSTextField_LineBreakStrategy,
                    LookinAttrSec_NSTextField_Bordered,
                    LookinAttrSec_NSTextField_TextColor,
                    LookinAttrSec_NSTextField_Placeholder,
                    LookinAttrSec_NSTextField_PreferredMaxLayoutWidth,
                ]
                table[LookinAttrGroup_NSVisualEffectView] = [
                    LookinAttrSec_NSVisualEffectView_Material,
                    LookinAttrSec_NSVisualEffectView_InteriorBackgroundStyle,
                    LookinAttrSec_NSVisualEffectView_BlendingMode,
                    LookinAttrSec_NSVisualEffectView_State,
                    LookinAttrSec_NSVisualEffectView_Emphasized,
                ]
                table[LookinAttrGroup_NSStackView] = [
                    LookinAttrSec_NSStackView_Orientation,
                    LookinAttrSec_NSStackView_EdgeInsets,
                    LookinAttrSec_NSStackView_DetachesHiddenViews,
                    LookinAttrSec_NSStackView_Distribution,
                    LookinAttrSec_NSStackView_Alignment,
                    LookinAttrSec_NSStackView_Spacing,
                ]
                table[LookinAttrGroup_NSWindow] = [
                    LookinAttrSec_NSWindow_Title,
                    LookinAttrSec_NSWindow_Subtitle,
                    LookinAttrSec_NSWindow_State,
                    LookinAttrSec_NSWindow_Style,
                    LookinAttrSec_NSWindow_CollectionBehavior,
                    LookinAttrSec_NSWindow_Appearance,
                    LookinAttrSec_NSWindow_TitleVisibility,
                    LookinAttrSec_NSWindow_ToolbarStyle,
                    LookinAttrSec_NSWindow_TitlebarSeparatorStyle,
                    LookinAttrSec_NSWindow_Behavior,
                    LookinAttrSec_NSWindow_AnimationBehavior,
                    LookinAttrSec_NSWindow_Level,
                    LookinAttrSec_NSWindow_TabbingMode,
                    LookinAttrSec_NSWindow_Size,
                    LookinAttrSec_NSWindow_Info,
                ]
                table[LookinAttrGroup_NSSlider] = [
                    LookinAttrSec_NSSlider_SliderType,
                    LookinAttrSec_NSSlider_Range,
                    LookinAttrSec_NSSlider_TickMark,
                    LookinAttrSec_NSSlider_Misc,
                ]
                table[LookinAttrGroup_NSProgressIndicator] = [
                    LookinAttrSec_NSProgressIndicator_Style,
                    LookinAttrSec_NSProgressIndicator_Range,
                    LookinAttrSec_NSProgressIndicator_Misc,
                ]
                table[LookinAttrGroup_NSSegmentedControl] = [
                    LookinAttrSec_NSSegmentedControl_SegmentCount,
                    LookinAttrSec_NSSegmentedControl_Selection,
                    LookinAttrSec_NSSegmentedControl_Style,
                    LookinAttrSec_NSSegmentedControl_Colors,
                ]
                table[LookinAttrGroup_NSPopUpButton] = [
                    LookinAttrSec_NSPopUpButton_Behavior,
                    LookinAttrSec_NSPopUpButton_Selection,
                    LookinAttrSec_NSPopUpButton_Items,
                ]
                table[LookinAttrGroup_NSComboBox] = [
                    LookinAttrSec_NSComboBox_Items,
                    LookinAttrSec_NSComboBox_Misc,
                ]
                table[LookinAttrGroup_NSStepper] = [
                    LookinAttrSec_NSStepper_Range,
                    LookinAttrSec_NSStepper_Misc,
                ]
                table[LookinAttrGroup_NSColorWell] = [
                    LookinAttrSec_NSColorWell_Color,
                    LookinAttrSec_NSColorWell_Misc,
                ]
                table[LookinAttrGroup_NSSwitch] = [LookinAttrSec_NSSwitch_State]
                table[LookinAttrGroup_NSDatePicker] = [
                    LookinAttrSec_NSDatePicker_Style,
                    LookinAttrSec_NSDatePicker_Range,
                    LookinAttrSec_NSDatePicker_Misc,
                ]
                table[LookinAttrGroup_NSLevelIndicator] = [
                    LookinAttrSec_NSLevelIndicator_Style,
                    LookinAttrSec_NSLevelIndicator_Range,
                    LookinAttrSec_NSLevelIndicator_TickMark,
                ]
                table[LookinAttrGroup_NSOutlineView] = [
                    LookinAttrSec_NSOutlineView_Indentation,
                    LookinAttrSec_NSOutlineView_Misc,
                ]
                table[LookinAttrGroup_NSCollectionView] = [
                    LookinAttrSec_NSCollectionView_Selection,
                    LookinAttrSec_NSCollectionView_Info,
                    LookinAttrSec_NSCollectionView_Colors,
                ]
                table[LookinAttrGroup_NSBox] = [
                    LookinAttrSec_NSBox_Type,
                    LookinAttrSec_NSBox_Title,
                    LookinAttrSec_NSBox_Appearance,
                    LookinAttrSec_NSBox_Metrics,
                ]
                table[LookinAttrGroup_NSSplitView] = [
                    LookinAttrSec_NSSplitView_Orientation,
                    LookinAttrSec_NSSplitView_Style,
                    LookinAttrSec_NSSplitView_Misc,
                ]
                table[LookinAttrGroup_NSTabView] = [
                    LookinAttrSec_NSTabView_Type,
                    LookinAttrSec_NSTabView_Misc,
                    LookinAttrSec_NSTabView_Info,
                ]
                table[LookinAttrGroup_NSGridView] = [
                    LookinAttrSec_NSGridView_Dimensions,
                    LookinAttrSec_NSGridView_Spacing,
                    LookinAttrSec_NSGridView_Placement,
                ]
            #endif
            table[LookinAttrGroup_LayoutGuide] = [
                LookinAttrSec_LayoutGuide_Identifier,
                LookinAttrSec_LayoutGuide_LayoutFrame,
                LookinAttrSec_LayoutGuide_OwningView,
            ]
            table[LookinAttrGroup_NSCell] = [
                LookinAttrSec_NSCell_Cell,
                LookinAttrSec_NSCell_Content,
                LookinAttrSec_NSCell_Behavior,
                LookinAttrSec_NSCell_ButtonCell,
                LookinAttrSec_NSCell_TextFieldCell,
            ]
            return table
        }()

        /// `+groupTitleWithGroupID:`. The macOS client displays iOS data, so
        /// both platforms carry every title.
        static let groupTitles: [String: String] = {
            var table: [String: String] = [:]
            table[LookinAttrGroup_Class] = "Class"
            table[LookinAttrGroup_Relation] = "Relation"
            table[LookinAttrGroup_Layout] = "Layout"
            table[LookinAttrGroup_AutoLayout] = "AutoLayout"
            // iOS groups (macOS client displays iOS data, so both platforms need all titles)
            table[LookinAttrGroup_UIImageView] = "UIImageView"
            table[LookinAttrGroup_UILabel] = "UILabel"
            table[LookinAttrGroup_UIControl] = "UIControl"
            table[LookinAttrGroup_UIButton] = "UIButton"
            table[LookinAttrGroup_UIScrollView] = "UIScrollView"
            table[LookinAttrGroup_UITableView] = "UITableView"
            table[LookinAttrGroup_UITextView] = "UITextView"
            table[LookinAttrGroup_UITextField] = "UITextField"
            table[LookinAttrGroup_UIVisualEffectView] = "UIVisualEffectView"
            table[LookinAttrGroup_UIStackView] = "UIStackView"
            table[LookinAttrGroup_UIWindowScene] = "UIWindowScene"
            table[LookinAttrGroup_UITraitCollection] = "UITraitCollection"
            // macOS groups
            table[LookinAttrGroup_NSImageView] = "NSImageView"
            table[LookinAttrGroup_NSControl] = "NSControl"
            table[LookinAttrGroup_NSButton] = "NSButton"
            table[LookinAttrGroup_NSScrollView] = "NSScrollView"
            table[LookinAttrGroup_NSTableView] = "NSTableView"
            table[LookinAttrGroup_NSTextView] = "NSTextView"
            table[LookinAttrGroup_NSTextField] = "NSTextField"
            table[LookinAttrGroup_NSVisualEffectView] = "NSVisualEffectView"
            table[LookinAttrGroup_NSStackView] = "NSStackView"
            table[LookinAttrGroup_NSWindow] = "NSWindow"
            table[LookinAttrGroup_NSSlider] = "NSSlider"
            table[LookinAttrGroup_NSProgressIndicator] = "NSProgressIndicator"
            table[LookinAttrGroup_NSSegmentedControl] = "NSSegmentedControl"
            table[LookinAttrGroup_NSPopUpButton] = "NSPopUpButton"
            table[LookinAttrGroup_NSComboBox] = "NSComboBox"
            table[LookinAttrGroup_NSStepper] = "NSStepper"
            table[LookinAttrGroup_NSColorWell] = "NSColorWell"
            table[LookinAttrGroup_NSSwitch] = "NSSwitch"
            table[LookinAttrGroup_NSDatePicker] = "NSDatePicker"
            table[LookinAttrGroup_NSLevelIndicator] = "NSLevelIndicator"
            table[LookinAttrGroup_NSOutlineView] = "NSOutlineView"
            table[LookinAttrGroup_NSCollectionView] = "NSCollectionView"
            table[LookinAttrGroup_NSBox] = "NSBox"
            table[LookinAttrGroup_NSSplitView] = "NSSplitView"
            table[LookinAttrGroup_NSTabView] = "NSTabView"
            table[LookinAttrGroup_NSGridView] = "NSGridView"
            // Platform-neutral; the host renders it as UILayoutGuide or
            // NSLayoutGuide depending on the inspected app's platform.
            table[LookinAttrGroup_LayoutGuide] = "LayoutGuide"
            table[LookinAttrGroup_NSCell] = "NSCell"
            #if canImport(UIKit)
                table[LookinAttrGroup_ViewLayer] = "CALayer / UIView"
            #else
                table[LookinAttrGroup_ViewLayer] = "CALayer / NSView"
            #endif
            return table
        }()

        /// `+sectionTitleWithSectionID:`; a missing entry means no title.
        static let sectionTitles: [String: String] = {
            var table: [String: String] = [:]
            table[LookinAttrSec_Layout_Frame] = "Frame"
            table[LookinAttrSec_Layout_Bounds] = "Bounds"
            table[LookinAttrSec_Layout_SafeArea] = "SafeArea"
            table[LookinAttrSec_Layout_Position] = "Position"
            table[LookinAttrSec_Layout_AnchorPoint] = "AnchorPoint"
            table[LookinAttrSec_Layout_CoordinateSpace] = "CoordinateSpace"
            table[LookinAttrSec_AutoLayout_Hugging] = "HuggingPriority"
            table[LookinAttrSec_AutoLayout_Resistance] = "ResistancePriority"
            table[LookinAttrSec_AutoLayout_IntrinsicSize] = "IntrinsicSize"
            table[LookinAttrSec_ViewLayer_Corner] = "CornerRadius"
            table[LookinAttrSec_ViewLayer_BgColor] = "BackgroundColor"
            table[LookinAttrSec_ViewLayer_Border] = "Border"
            table[LookinAttrSec_ViewLayer_Shadow] = "Shadow"
            table[LookinAttrSec_ViewLayer_Tag] = "Tag"
            table[LookinAttrSec_ViewLayer_ContentMode] = "ContentMode"
            table[LookinAttrSec_ViewLayer_TintColor] = "TintColor"
            table[LookinAttrSec_UIStackView_Axis] = "Axis"
            table[LookinAttrSec_UIStackView_Distribution] = "Distribution"
            table[LookinAttrSec_UIStackView_Alignment] = "Alignment"
            table[LookinAttrSec_UIVisualEffectView_Style] = "Style"
            table[LookinAttrSec_UIVisualEffectView_QMUIForegroundColor] = "ForegroundColor"
            table[LookinAttrSec_UIImageView_Name] = "ImageName"
            table[LookinAttrSec_UILabel_TextColor] = "TextColor"
            table[LookinAttrSec_UITextView_TextColor] = "TextColor"
            table[LookinAttrSec_UITextField_TextColor] = "TextColor"
            table[LookinAttrSec_UILabel_BreakMode] = "LineBreakMode"
            table[LookinAttrSec_UILabel_NumberOfLines] = "NumberOfLines"
            table[LookinAttrSec_UILabel_Text] = "Text"
            table[LookinAttrSec_UITextView_Text] = "Text"
            table[LookinAttrSec_UITextField_Text] = "Text"
            table[LookinAttrSec_UITextField_Placeholder] = "Placeholder"
            table[LookinAttrSec_UILabel_Alignment] = "TextAlignment"
            table[LookinAttrSec_UITextView_Alignment] = "TextAlignment"
            table[LookinAttrSec_UITextField_Alignment] = "TextAlignment"
            table[LookinAttrSec_UIControl_HorAlignment] = "HorizontalAlignment"
            table[LookinAttrSec_UIControl_VerAlignment] = "VerticalAlignment"
            table[LookinAttrSec_UIControl_QMUIOutsideEdge] = "QMUI_outsideEdge"
            table[LookinAttrSec_UIButton_ContentInsets] = "ContentInsets"
            table[LookinAttrSec_UIButton_TitleInsets] = "TitleInsets"
            table[LookinAttrSec_UIButton_ImageInsets] = "ImageInsets"
            table[LookinAttrSec_UIScrollView_QMUIInitialInset] = "QMUI_initialContentInset"
            table[LookinAttrSec_UIScrollView_ContentInset] = "ContentInset"
            table[LookinAttrSec_UIScrollView_AdjustedInset] = "AdjustedContentInset"
            table[LookinAttrSec_UIScrollView_IndicatorInset] = "ScrollIndicatorInsets"
            table[LookinAttrSec_UIScrollView_Offset] = "ContentOffset"
            table[LookinAttrSec_UIScrollView_ContentSize] = "ContentSize"
            table[LookinAttrSec_UIScrollView_Behavior] = "InsetAdjustmentBehavior"
            table[LookinAttrSec_UIScrollView_ShowsIndicator] = "ShowsScrollIndicator"
            table[LookinAttrSec_UIScrollView_Bounce] = "AlwaysBounce"
            table[LookinAttrSec_UIScrollView_Zoom] = "Zoom"
            table[LookinAttrSec_UITableView_Style] = "Style"
            table[LookinAttrSec_UITableView_SectionsNumber] = "NumberOfSections"
            table[LookinAttrSec_UITableView_RowsNumber] = "NumberOfRows"
            table[LookinAttrSec_UITableView_SeparatorColor] = "SeparatorColor"
            table[LookinAttrSec_UITableView_SeparatorInset] = "SeparatorInset"
            table[LookinAttrSec_UITableView_SeparatorStyle] = "SeparatorStyle"
            table[LookinAttrSec_UILabel_Font] = "Font"
            table[LookinAttrSec_UITextField_Font] = "Font"
            table[LookinAttrSec_UITextView_Font] = "Font"
            table[LookinAttrSec_UITextView_ContainerInset] = "ContainerInset"
            table[LookinAttrSec_UITextField_ClearButtonMode] = "ClearButtonMode"
            table[LookinAttrSec_NSImageView_Name] = "ImageName"
            table[LookinAttrSec_NSImageView_Open] = "Open"
            table[LookinAttrSec_NSImageView_Scaling] = "Scaling"
            table[LookinAttrSec_NSImageView_Behavior] = "Behavior"
            table[LookinAttrSec_NSImageView_ContentTintColor] = "ContentTintColor"
            table[LookinAttrSec_NSControl_State] = "State"
            table[LookinAttrSec_NSControl_ControlSize] = "ControlSize"
            table[LookinAttrSec_NSControl_Font] = "Font"
            table[LookinAttrSec_NSControl_Alignment] = "Alignment"
            table[LookinAttrSec_NSControl_Misc] = "Misc"
            table[LookinAttrSec_NSControl_StringValue] = "StringValue"
            table[LookinAttrSec_NSControl_Value] = "Value"
            table[LookinAttrSec_NSButton_ButtonType] = "ButtonType"
            table[LookinAttrSec_NSButton_Title] = "Title"
            table[LookinAttrSec_NSButton_BezelStyle] = "BezelStyle"
            table[LookinAttrSec_NSButton_BezelColor] = "Colors"
            table[LookinAttrSec_NSButton_Misc] = "Misc"
            table[LookinAttrSec_NSScrollView_ContentOffset] = "ContentOffset"
            table[LookinAttrSec_NSScrollView_ContentSize] = "ContentSize"
            table[LookinAttrSec_NSScrollView_ContentInset] = "ContentInset"
            table[LookinAttrSec_NSScrollView_BorderType] = "BorderType"
            table[LookinAttrSec_NSScrollView_Scroller] = "Scroller"
            table[LookinAttrSec_NSScrollView_Ruler] = "Ruler"
            table[LookinAttrSec_NSScrollView_LineScroll] = "LineScroll"
            table[LookinAttrSec_NSScrollView_PageScroll] = "PageScroll"
            table[LookinAttrSec_NSScrollView_ScrollElasiticity] = "ScrollElasiticity"
            table[LookinAttrSec_NSScrollView_Misc] = "Misc"
            table[LookinAttrSec_NSScrollView_Magnification] = "Magnification"
            table[LookinAttrSec_NSTableView_RowHeight] = "RowHeight"
            table[LookinAttrSec_NSTableView_AutomaticRowHeights] = "AutomaticRowHeights"
            table[LookinAttrSec_NSTableView_IntercellSpacing] = "IntercellSpacing"
            table[LookinAttrSec_NSTableView_Style] = "Style"
            table[LookinAttrSec_NSTableView_ColumnAutoresizingStyle] = "ColumnAutoresizingStyle"
            table[LookinAttrSec_NSTableView_GridStyleMask] = "GridStyleMask"
            table[LookinAttrSec_NSTableView_SelectionHighlightStyle] = "SelectionHighlightStyle"
            table[LookinAttrSec_NSTableView_GridColor] = "GridColor"
            table[LookinAttrSec_NSTableView_RowSizeStyle] = "RowSizeStyle"
            table[LookinAttrSec_NSTableView_NumberOfRows] = "NumberOfRows"
            table[LookinAttrSec_NSTableView_NumberOfColumns] = "NumberOfColumns"
            table[LookinAttrSec_NSTableView_UseAlternatingRowBackgroundColors] = "UseAlternatingRowBackgroundColors"
            table[LookinAttrSec_NSTableView_AllowsColumnReordering] = "AllowsColumnReordering"
            table[LookinAttrSec_NSTableView_AllowsColumnResizing] = "AllowsColumnResizing"
            table[LookinAttrSec_NSTableView_AllowsMultipleSelection] = "AllowsMultipleSelection"
            table[LookinAttrSec_NSTableView_AllowsEmptySelection] = "AllowsEmptySelection"
            table[LookinAttrSec_NSTableView_AllowsColumnSelection] = "AllowsColumnSelection"
            table[LookinAttrSec_NSTableView_AllowsTypeSelect] = "AllowsTypeSelect"
            table[LookinAttrSec_NSTableView_DraggingDestinationFeedbackStyle] = "DraggingDestinationFeedbackStyle"
            table[LookinAttrSec_NSTableView_Autosave] = "Autosave"
            table[LookinAttrSec_NSTableView_FloatsGroupRows] = "FloatsGroupRows"
            table[LookinAttrSec_NSTableView_RowActionsVisible] = "RowActionsVisible"
            table[LookinAttrSec_NSTableView_UsesStaticContents] = "UsesStaticContents"
            table[LookinAttrSec_NSTableView_UserInterfaceLayoutDirection] = "UserInterfaceLayoutDirection"
            table[LookinAttrSec_NSTableView_VerticalMotionCanBeginDrag] = "VerticalMotionCanBeginDrag"
            table[LookinAttrSec_NSTextView_Font] = "Font"
            table[LookinAttrSec_NSTextView_Basic] = "Basic"
            table[LookinAttrSec_NSTextView_String] = "String"
            table[LookinAttrSec_NSTextView_TextColor] = "TextColor"
            table[LookinAttrSec_NSTextView_Alignment] = "Alignment"
            table[LookinAttrSec_NSTextView_ContainerInset] = "ContainerInset"
            table[LookinAttrSec_NSTextView_BaseWritingDirection] = "BaseWritingDirection"
            table[LookinAttrSec_NSTextView_Size] = "Size"
            table[LookinAttrSec_NSTextView_Resizable] = "Resizable"
            table[LookinAttrSec_NSTextField_BezelStyle] = "BezelStyle"
            table[LookinAttrSec_NSTextField_LineBreakStrategy] = "LineBreakStrategy"
            table[LookinAttrSec_NSTextField_TextColor] = "Colors"
            table[LookinAttrSec_NSTextField_Placeholder] = "Placeholder"
            table[LookinAttrSec_NSTextField_PreferredMaxLayoutWidth] = "Layout"
            table[LookinAttrSec_NSVisualEffectView_Material] = "Material"
            table[LookinAttrSec_NSVisualEffectView_InteriorBackgroundStyle] = "InteriorBackgroundStyle"
            table[LookinAttrSec_NSVisualEffectView_BlendingMode] = "BlendingMode"
            table[LookinAttrSec_NSVisualEffectView_State] = "State"
            table[LookinAttrSec_NSVisualEffectView_Emphasized] = "Emphasized"
            table[LookinAttrSec_NSStackView_Orientation] = "Orientation"
            table[LookinAttrSec_NSStackView_EdgeInsets] = "EdgeInsets"
            table[LookinAttrSec_NSStackView_DetachesHiddenViews] = "DetachesHiddenViews"
            table[LookinAttrSec_NSStackView_Distribution] = "Distribution"
            table[LookinAttrSec_NSStackView_Alignment] = "Alignment"
            table[LookinAttrSec_NSStackView_Spacing] = "Spacing"
            table[LookinAttrSec_NSWindow_Title] = "Title"
            table[LookinAttrSec_NSWindow_Subtitle] = "Subtitle"
            table[LookinAttrSec_NSWindow_State] = "State"
            table[LookinAttrSec_NSWindow_Style] = "StyleMask"
            table[LookinAttrSec_NSWindow_CollectionBehavior] = "CollectionBehavior"
            table[LookinAttrSec_NSWindow_Appearance] = "Appearance"
            table[LookinAttrSec_NSWindow_TitleVisibility] = "TitleVisibility"
            table[LookinAttrSec_NSWindow_ToolbarStyle] = "ToolbarStyle"
            table[LookinAttrSec_NSWindow_TitlebarSeparatorStyle] = "TitlebarSeparatorStyle"
            table[LookinAttrSec_NSWindow_Behavior] = "Behavior"
            table[LookinAttrSec_NSWindow_AnimationBehavior] = "AnimationBehavior"
            table[LookinAttrSec_NSWindow_Level] = "Level"
            table[LookinAttrSec_NSWindow_TabbingMode] = "TabbingMode"
            table[LookinAttrSec_NSWindow_Size] = "Size"
            table[LookinAttrSec_NSWindow_Info] = "Info"
            table[LookinAttrSec_NSSlider_SliderType] = "SliderType"
            table[LookinAttrSec_NSSlider_Range] = "Range"
            table[LookinAttrSec_NSSlider_TickMark] = "TickMark"
            table[LookinAttrSec_NSSlider_Misc] = "Misc"
            table[LookinAttrSec_NSProgressIndicator_Style] = "Style"
            table[LookinAttrSec_NSProgressIndicator_Range] = "Range"
            table[LookinAttrSec_NSProgressIndicator_Misc] = "Misc"
            table[LookinAttrSec_NSSegmentedControl_SegmentCount] = "SegmentCount"
            table[LookinAttrSec_NSSegmentedControl_Selection] = "Selection"
            table[LookinAttrSec_NSSegmentedControl_Style] = "Style"
            table[LookinAttrSec_NSSegmentedControl_Colors] = "Colors"
            table[LookinAttrSec_NSPopUpButton_Behavior] = "Behavior"
            table[LookinAttrSec_NSPopUpButton_Selection] = "Selection"
            table[LookinAttrSec_NSPopUpButton_Items] = "Items"
            table[LookinAttrSec_NSComboBox_Items] = "Items"
            table[LookinAttrSec_NSComboBox_Misc] = "Misc"
            table[LookinAttrSec_NSStepper_Range] = "Range"
            table[LookinAttrSec_NSStepper_Misc] = "Misc"
            table[LookinAttrSec_NSColorWell_Color] = "Color"
            table[LookinAttrSec_NSColorWell_Misc] = "Misc"
            table[LookinAttrSec_NSSwitch_State] = "State"
            table[LookinAttrSec_NSDatePicker_Style] = "Style"
            table[LookinAttrSec_NSDatePicker_Range] = "Range"
            table[LookinAttrSec_NSDatePicker_Misc] = "Misc"
            table[LookinAttrSec_NSLevelIndicator_Style] = "Style"
            table[LookinAttrSec_NSLevelIndicator_Range] = "Range"
            table[LookinAttrSec_NSLevelIndicator_TickMark] = "TickMark"
            table[LookinAttrSec_NSOutlineView_Indentation] = "Indentation"
            table[LookinAttrSec_NSOutlineView_Misc] = "Misc"
            table[LookinAttrSec_NSCollectionView_Selection] = "Selection"
            table[LookinAttrSec_NSCollectionView_Info] = "Info"
            table[LookinAttrSec_NSCollectionView_Colors] = "Colors"
            table[LookinAttrSec_NSBox_Type] = "Type"
            table[LookinAttrSec_NSBox_Title] = "Title"
            table[LookinAttrSec_NSBox_Appearance] = "Appearance"
            table[LookinAttrSec_NSBox_Metrics] = "Metrics"
            table[LookinAttrSec_NSSplitView_Orientation] = "Orientation"
            table[LookinAttrSec_NSSplitView_Style] = "Style"
            table[LookinAttrSec_NSSplitView_Misc] = "Misc"
            table[LookinAttrSec_NSTabView_Type] = "Type"
            table[LookinAttrSec_NSTabView_Misc] = "Misc"
            table[LookinAttrSec_NSTabView_Info] = "Info"
            table[LookinAttrSec_NSGridView_Dimensions] = "Dimensions"
            table[LookinAttrSec_NSGridView_Spacing] = "Spacing"
            table[LookinAttrSec_NSGridView_Placement] = "Placement"
            // LayoutGuide
            table[LookinAttrSec_LayoutGuide_Identifier] = "Identifier"
            table[LookinAttrSec_LayoutGuide_LayoutFrame] = "LayoutFrame"
            table[LookinAttrSec_LayoutGuide_OwningView] = "OwningView"
            // NSCell
            table[LookinAttrSec_NSCell_Cell] = "Cell"
            table[LookinAttrSec_NSCell_Content] = "Content"
            table[LookinAttrSec_NSCell_Behavior] = "Behavior"
            table[LookinAttrSec_NSCell_ButtonCell] = "NSButtonCell"
            table[LookinAttrSec_NSCell_TextFieldCell] = "NSTextFieldCell"
            // UIWindowScene
            table[LookinAttrSec_UIWindowScene_State] = "State"
            table[LookinAttrSec_UIWindowScene_Title] = "Title"
            table[LookinAttrSec_UIWindowScene_Orientation] = "Orientation"
            table[LookinAttrSec_UIWindowScene_Windows] = "Windows"
            table[LookinAttrSec_UIWindowScene_Screen] = "Screen"
            table[LookinAttrSec_UIWindowScene_StatusBar] = "StatusBar"
            table[LookinAttrSec_UIWindowScene_Traits] = "Traits"
            table[LookinAttrSec_UIWindowScene_Session] = "Session"
            table[LookinAttrSec_UIWindowScene_Configuration] = "Configuration"
            table[LookinAttrSec_UIWindowScene_Geometry] = "Geometry"
            table[LookinAttrSec_UIWindowScene_ActivationConditions] = "ActivationConditions"
            table[LookinAttrSec_UIWindowScene_SizeRestrictions] = "SizeRestrictions"
            table[LookinAttrSec_UIWindowScene_WindowingBehaviors] = "WindowingBehaviors"
            table[LookinAttrSec_UIWindowScene_Pointer] = "Pointer"
            table[LookinAttrSec_UIWindowScene_Protection] = "Protection"
            // UITraitCollection
            table[LookinAttrSec_UITraitCollection_Appearance] = "Appearance"
            table[LookinAttrSec_UITraitCollection_SizeClass] = "SizeClass"
            table[LookinAttrSec_UITraitCollection_Display] = "Display"
            table[LookinAttrSec_UITraitCollection_Device] = "Device"
            table[LookinAttrSec_UITraitCollection_Layout] = "Layout"
            table[LookinAttrSec_UITraitCollection_Content] = "Content"
            return table
        }()
    }

#endif
