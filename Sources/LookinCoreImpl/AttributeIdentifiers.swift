//
//  AttributeIdentifiers.swift
//  LookinCore
//
//  The identifiers of every attribute group, section and attribute the
//  dashboard shows, as static members of AttributesGroup.Identifier,
//  AttributesSection.Identifier and InspectedAttribute.Identifier: groups
//  directly, sections under their group, attributes under their group and
//  section. The strings are what crosses the wire; they are the values of
//  Lookin's LookinAttrIdentifiers.h / .m (created by Li Kai on 2019/9/18,
//  https://lookin.work), unchanged.
//
//  A value must be unique across groups, sections and attributes together
//  (the Host's AppDelegate and the blueprint tests check it), and a value once
//  used must not come back for something else: the Host stores section
//  identifiers in UserDefaults to remember which sections are shown. Retire
//  an identifier by commenting it out, not by deleting it.
//
//  Keep one declaration per line, exactly
//      public static let <name>: <Type> = "<value>"
//  inside `extension <Owner>.Identifier {` and `public enum <Name> {` lines
//  whose closing braces stand on lines of their own.
//  Scripts/generate-test-attribute-identifiers.sh reads these lines to write
//  the Objective-C tests' copy, Tests/Support/LookinTestAttributeIdentifiers.h;
//  rerun it after changing this file.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    // MARK: - Groups

    extension AttributesGroup.Identifier {
        public static let unspecified: Self = "n"
        public static let `class`: Self = "c"
        public static let relation: Self = "r"
        public static let layout: Self = "l"
        public static let autoLayout: Self = "a"
        public static let viewLayer: Self = "vl"
        public static let uiImageView: Self = "i"
        public static let uiLabel: Self = "la"
        public static let uiControl: Self = "co"
        public static let uiButton: Self = "b"
        public static let uiScrollView: Self = "s"
        public static let uiTableView: Self = "ta"
        public static let uiTextView: Self = "te"
        public static let uiTextField: Self = "tf"
        public static let uiVisualEffectView: Self = "ve"
        public static let uiStackView: Self = "UIStackView"
        public static let nsImageView: Self = "NSImageView"
        public static let nsControl: Self = "NSControl"
        public static let nsButton: Self = "NSButton"
        public static let nsScrollView: Self = "NSScrollView"
        public static let nsTableView: Self = "NSTableView"
        public static let nsTextView: Self = "NSTextView"
        public static let nsTextField: Self = "NSTextField"
        public static let nsVisualEffectView: Self = "NSVisualEffectView"
        public static let nsStackView: Self = "NSStackView"
        public static let nsWindow: Self = "NSWindow"
        public static let nsSlider: Self = "NSSlider"
        public static let nsProgressIndicator: Self = "NSProgressIndicator"
        public static let nsSegmentedControl: Self = "NSSegmentedControl"
        public static let nsPopUpButton: Self = "NSPopUpButton"
        public static let nsComboBox: Self = "NSComboBox"
        public static let nsStepper: Self = "NSStepper"
        public static let nsColorWell: Self = "NSColorWell"
        public static let nsSwitch: Self = "NSSwitch"
        public static let nsDatePicker: Self = "NSDatePicker"
        public static let nsLevelIndicator: Self = "NSLevelIndicator"
        public static let nsOutlineView: Self = "NSOutlineView"
        public static let nsCollectionView: Self = "NSCollectionView"
        public static let nsBox: Self = "NSBox"
        public static let nsSplitView: Self = "NSSplitView"
        public static let nsTabView: Self = "NSTabView"
        public static let nsGridView: Self = "NSGridView"
        /// Platform-neutral group shared by UILayoutGuide and NSLayoutGuide nodes.
        public static let layoutGuide: Self = "LayoutGuide"
        /// AppKit only: the attributes of NSCell nodes.
        public static let nsCell: Self = "NSCell"
        /// Attribute groups an app adds through LookinServer's custom attributes.
        public static let userCustom: Self = "guc"
        // UIWindowScene
        public static let uiWindowScene: Self = "UIWindowScene"
        // UITraitCollection
        public static let uiTraitCollection: Self = "UITraitCollection"
        public static let uiSlider: Self = "UISlider"
        public static let uiStepper: Self = "UIStepper"
        public static let uiSwitch: Self = "UISwitch"
        public static let uiSegmentedControl: Self = "UISegmentedControl"
        public static let uiProgressView: Self = "UIProgressView"
        public static let uiActivityIndicatorView: Self = "UIActivityIndicatorView"
        public static let uiPageControl: Self = "UIPageControl"
        public static let uiDatePicker: Self = "UIDatePicker"
        public static let uiColorWell: Self = "UIColorWell"
        public static let uiRefreshControl: Self = "UIRefreshControl"
        public static let uiPickerView: Self = "UIPickerView"
        public static let uiCalendarView: Self = "UICalendarView"
        public static let uiPasteControl: Self = "UIPasteControl"
        public static let uiCollectionView: Self = "UICollectionView"
        public static let uiCollectionReusableView: Self = "UICollectionReusableView"
        public static let uiTableViewCell: Self = "UITableViewCell"
        public static let uiTableViewHeaderFooterView: Self = "UITableViewHeaderFooterView"
        public static let uiNavigationBar: Self = "UINavigationBar"
        public static let uiTabBar: Self = "UITabBar"
        public static let uiToolbar: Self = "UIToolbar"
        public static let uiSearchBar: Self = "UISearchBar"
        public static let uiInputView: Self = "UIInputView"
        public static let uiContentUnavailableView: Self = "UIContentUnavailableView"
        public static let uiBackgroundExtensionView: Self = "UIBackgroundExtensionView"
        public static let uiWindow: Self = "UIWindow"
        public static let uiView: Self = "UIView"
        public static let nsClipView: Self = "NSClipView"
        public static let nsScroller: Self = "NSScroller"
        public static let nsBrowser: Self = "NSBrowser"
        public static let nsMatrix: Self = "NSMatrix"
        public static let nsPathControl: Self = "NSPathControl"
        public static let nsRuleEditor: Self = "NSRuleEditor"
        public static let nsSearchField: Self = "NSSearchField"
        public static let nsComboButton: Self = "NSComboButton"
        public static let nsGlassEffectView: Self = "NSGlassEffectView"
        public static let nsBackgroundExtensionView: Self = "NSBackgroundExtensionView"
        public static let nsRulerView: Self = "NSRulerView"
        public static let nsTableCellView: Self = "NSTableCellView"
        public static let nsTableRowView: Self = "NSTableRowView"
        public static let nsTableHeaderView: Self = "NSTableHeaderView"
        public static let nsTextInsertionIndicator: Self = "NSTextInsertionIndicator"
        public static let nsView: Self = "NSView"
        public static let caLayer: Self = "CALayer"
    }

    // MARK: - Sections

    extension AttributesSection.Identifier {
        public static let unspecified: Self = "n"
        public static let userCustom: Self = "sec_ctm"

        public enum Class {
            public static let `class`: AttributesSection.Identifier = "cl_c"
        }

        public enum Relation {
            public static let relation: AttributesSection.Identifier = "r_r"
        }

        public enum Layout {
            public static let frame: AttributesSection.Identifier = "l_f"
            public static let bounds: AttributesSection.Identifier = "l_b"
            public static let safeArea: AttributesSection.Identifier = "l_s"
            public static let position: AttributesSection.Identifier = "l_p"
            public static let anchorPoint: AttributesSection.Identifier = "l_a"
            /// Only used by UIWindowScene, which has no frame of its own.
            public static let coordinateSpace: AttributesSection.Identifier = "l_c"
        }

        public enum AutoLayout {
            public static let hugging: AttributesSection.Identifier = "a_h"
            public static let resistance: AttributesSection.Identifier = "a_r"
            public static let constraints: AttributesSection.Identifier = "a_c"
            public static let intrinsicSize: AttributesSection.Identifier = "a_i"
        }

        public enum ViewLayer {
            public static let visibility: AttributesSection.Identifier = "v_v"
            public static let interactionAndMasks: AttributesSection.Identifier = "v_i"
            public static let corner: AttributesSection.Identifier = "v_c"
            public static let backgroundColor: AttributesSection.Identifier = "v_b"
            public static let border: AttributesSection.Identifier = "v_bo"
            public static let shadow: AttributesSection.Identifier = "v_s"
            public static let contentMode: AttributesSection.Identifier = "v_co"
            public static let tintColor: AttributesSection.Identifier = "v_t"
            public static let tag: AttributesSection.Identifier = "v_ta"
        }

        public enum UIImageView {
            public static let name: AttributesSection.Identifier = "i_n"
            public static let open: AttributesSection.Identifier = "i_o"
            public static let highlightedImage: AttributesSection.Identifier = "UIImageView_HighlightedImage"
            public static let preferredSymbolConfiguration: AttributesSection.Identifier = "UIImageView_PreferredSymbolConfiguration"
            public static let behavior: AttributesSection.Identifier = "UIImageView_Behavior"
            public static let animationImages: AttributesSection.Identifier = "UIImageView_AnimationImages"
            public static let highlightedAnimationImages: AttributesSection.Identifier = "UIImageView_HighlightedAnimationImages"
            public static let animationDuration: AttributesSection.Identifier = "UIImageView_AnimationDuration"
            public static let animationRepeatCount: AttributesSection.Identifier = "UIImageView_AnimationRepeatCount"
            public static let preferredImageDynamicRange: AttributesSection.Identifier = "UIImageView_PreferredImageDynamicRange"
            public static let imageDynamicRange: AttributesSection.Identifier = "UIImageView_ImageDynamicRange"
        }

        public enum UILabel {
            public static let text: AttributesSection.Identifier = "lb_t"
            public static let font: AttributesSection.Identifier = "lb_f"
            public static let numberOfLines: AttributesSection.Identifier = "lb_n"
            public static let textColor: AttributesSection.Identifier = "lb_tc"
            public static let breakMode: AttributesSection.Identifier = "lb_b"
            public static let alignment: AttributesSection.Identifier = "lb_a"
            public static let canAdjustFont: AttributesSection.Identifier = "lb_c"
            public static let preferredVibrancy: AttributesSection.Identifier = "UILabel_PreferredVibrancy"
            public static let colors: AttributesSection.Identifier = "UILabel_Colors"
            public static let shadowOffset: AttributesSection.Identifier = "UILabel_ShadowOffset"
            public static let behavior: AttributesSection.Identifier = "UILabel_Behavior"
            public static let baselineAdjustment: AttributesSection.Identifier = "UILabel_BaselineAdjustment"
            public static let minimumScaleFactor: AttributesSection.Identifier = "UILabel_MinimumScaleFactor"
            public static let lineBreakStrategy: AttributesSection.Identifier = "UILabel_LineBreakStrategy"
            public static let preferredMaxLayoutWidth: AttributesSection.Identifier = "UILabel_PreferredMaxLayoutWidth"
        }

        public enum UIControl {
            public static let enabledSelected: AttributesSection.Identifier = "c_e"
            public static let verAlignment: AttributesSection.Identifier = "c_v"
            public static let horAlignment: AttributesSection.Identifier = "c_h"
            public static let qmuiOutsideEdge: AttributesSection.Identifier = "c_o"
            public static let behavior: AttributesSection.Identifier = "UIControl_Behavior"
            public static let effectiveContentHorizontalAlignment: AttributesSection.Identifier = "UIControl_EffectiveContentHorizontalAlignment"
            public static let state: AttributesSection.Identifier = "UIControl_State"
            public static let allControlEvents: AttributesSection.Identifier = "UIControl_AllControlEvents"
            public static let toolTip: AttributesSection.Identifier = "UIControl_ToolTip"
        }

        public enum UIButton {
            public static let contentInsets: AttributesSection.Identifier = "b_c"
            public static let titleInsets: AttributesSection.Identifier = "b_t"
            public static let imageInsets: AttributesSection.Identifier = "b_i"
            public static let behavioralStyle: AttributesSection.Identifier = "UIButton_BehavioralStyle"
            public static let preferredBehavioralStyle: AttributesSection.Identifier = "UIButton_PreferredBehavioralStyle"
            public static let configuration: AttributesSection.Identifier = "UIButton_Configuration"
            public static let behavior: AttributesSection.Identifier = "UIButton_Behavior"
            public static let buttonType: AttributesSection.Identifier = "UIButton_ButtonType"
            public static let role: AttributesSection.Identifier = "UIButton_Role"
            public static let menu: AttributesSection.Identifier = "UIButton_Menu"
            public static let currentTitle: AttributesSection.Identifier = "UIButton_CurrentTitle"
            public static let colors: AttributesSection.Identifier = "UIButton_Colors"
            public static let images: AttributesSection.Identifier = "UIButton_Images"
            public static let currentPreferredSymbolConfiguration: AttributesSection.Identifier = "UIButton_CurrentPreferredSymbolConfiguration"
        }

        public enum UIScrollView {
            public static let contentInset: AttributesSection.Identifier = "s_c"
            public static let adjustedInset: AttributesSection.Identifier = "s_a"
            public static let indicatorInset: AttributesSection.Identifier = "s_i"
            public static let offset: AttributesSection.Identifier = "s_o"
            public static let contentSize: AttributesSection.Identifier = "s_cs"
            public static let behavior: AttributesSection.Identifier = "s_b"
            public static let showsIndicator: AttributesSection.Identifier = "s_si"
            public static let bounce: AttributesSection.Identifier = "s_bo"
            public static let scrollPaging: AttributesSection.Identifier = "s_s"
            public static let contentTouches: AttributesSection.Identifier = "s_ct"
            public static let zoom: AttributesSection.Identifier = "s_z"
            public static let qmuiInitialInset: AttributesSection.Identifier = "s_ii"
            public static let contentAlignmentPoint: AttributesSection.Identifier = "UIScrollView_ContentAlignmentPoint"
            public static let flags: AttributesSection.Identifier = "UIScrollView_Flags"
            public static let indicatorStyle: AttributesSection.Identifier = "UIScrollView_IndicatorStyle"
            public static let verticalScrollIndicatorInsets: AttributesSection.Identifier = "UIScrollView_VerticalScrollIndicatorInsets"
            public static let horizontalScrollIndicatorInsets: AttributesSection.Identifier = "UIScrollView_HorizontalScrollIndicatorInsets"
            public static let decelerationRate: AttributesSection.Identifier = "UIScrollView_DecelerationRate"
            public static let indexDisplayMode: AttributesSection.Identifier = "UIScrollView_IndexDisplayMode"
            public static let keyboardDismissMode: AttributesSection.Identifier = "UIScrollView_KeyboardDismissMode"
        }

        public enum UITableView {
            public static let style: AttributesSection.Identifier = "t_s"
            public static let sectionsNumber: AttributesSection.Identifier = "t_sn"
            public static let rowsNumber: AttributesSection.Identifier = "t_r"
            public static let separatorStyle: AttributesSection.Identifier = "t_ss"
            public static let separatorColor: AttributesSection.Identifier = "t_sc"
            public static let separatorInset: AttributesSection.Identifier = "t_si"
            public static let behavior: AttributesSection.Identifier = "UITableView_Behavior"
            public static let rowHeight: AttributesSection.Identifier = "UITableView_RowHeight"
            public static let sectionHeaderHeight: AttributesSection.Identifier = "UITableView_SectionHeaderHeight"
            public static let sectionFooterHeight: AttributesSection.Identifier = "UITableView_SectionFooterHeight"
            public static let estimatedRowHeight: AttributesSection.Identifier = "UITableView_EstimatedRowHeight"
            public static let estimatedSectionHeaderHeight: AttributesSection.Identifier = "UITableView_EstimatedSectionHeaderHeight"
            public static let estimatedSectionFooterHeight: AttributesSection.Identifier = "UITableView_EstimatedSectionFooterHeight"
            public static let fillerRowHeight: AttributesSection.Identifier = "UITableView_FillerRowHeight"
            public static let sectionHeaderTopPadding: AttributesSection.Identifier = "UITableView_SectionHeaderTopPadding"
            public static let separatorInsetReference: AttributesSection.Identifier = "UITableView_SeparatorInsetReference"
            public static let selfSizingInvalidation: AttributesSection.Identifier = "UITableView_SelfSizingInvalidation"
            public static let indexPathsForSelectedRows: AttributesSection.Identifier = "UITableView_IndexPathsForSelectedRows"
            public static let sectionIndexMinimumDisplayRowCount: AttributesSection.Identifier = "UITableView_SectionIndexMinimumDisplayRowCount"
            public static let colors: AttributesSection.Identifier = "UITableView_Colors"
            public static let separatorEffect: AttributesSection.Identifier = "UITableView_SeparatorEffect"
            public static let contentHuggingElements: AttributesSection.Identifier = "UITableView_ContentHuggingElements"
        }

        public enum UITextView {
            public static let basic: AttributesSection.Identifier = "tv_b"
            public static let text: AttributesSection.Identifier = "tv_t"
            public static let font: AttributesSection.Identifier = "tv_f"
            public static let textColor: AttributesSection.Identifier = "tv_tc"
            public static let alignment: AttributesSection.Identifier = "tv_a"
            public static let containerInset: AttributesSection.Identifier = "tv_c"
            public static let dataDetectorTypes: AttributesSection.Identifier = "UITextView_DataDetectorTypes"
            public static let behavior: AttributesSection.Identifier = "UITextView_Behavior"
            public static let borderStyle: AttributesSection.Identifier = "UITextView_BorderStyle"
            public static let writingToolsBehavior: AttributesSection.Identifier = "UITextView_WritingToolsBehavior"
            public static let allowedWritingToolsResultOptions: AttributesSection.Identifier = "UITextView_AllowedWritingToolsResultOptions"
        }

        public enum UITextField {
            public static let text: AttributesSection.Identifier = "tf_t"
            public static let placeholder: AttributesSection.Identifier = "tf_p"
            public static let font: AttributesSection.Identifier = "tf_f"
            public static let textColor: AttributesSection.Identifier = "tf_tc"
            public static let alignment: AttributesSection.Identifier = "tf_a"
            public static let clears: AttributesSection.Identifier = "tf_c"
            public static let canAdjustFont: AttributesSection.Identifier = "tf_ca"
            public static let clearButtonMode: AttributesSection.Identifier = "tf_cb"
            public static let uiSearchTextField: AttributesSection.Identifier = "UITextField_UISearchTextField"
            public static let borderStyle: AttributesSection.Identifier = "UITextField_BorderStyle"
            public static let images: AttributesSection.Identifier = "UITextField_Images"
            public static let behavior: AttributesSection.Identifier = "UITextField_Behavior"
            public static let leftViewMode: AttributesSection.Identifier = "UITextField_LeftViewMode"
            public static let rightViewMode: AttributesSection.Identifier = "UITextField_RightViewMode"
        }

        public enum UIVisualEffectView {
            public static let style: AttributesSection.Identifier = "ve_s"
            public static let qmuiForegroundColor: AttributesSection.Identifier = "ve_f"
            public static let effect: AttributesSection.Identifier = "UIVisualEffectView_Effect"
        }

        public enum UIStackView {
            public static let axis: AttributesSection.Identifier = "usv_axis"
            public static let distribution: AttributesSection.Identifier = "usv_dis"
            public static let alignment: AttributesSection.Identifier = "usv_align"
            public static let spacing: AttributesSection.Identifier = "usv_spa"
            public static let behavior: AttributesSection.Identifier = "UIStackView_Behavior"
        }

        public enum NSImageView {
            public static let name: AttributesSection.Identifier = "NSImageView_Name"
            public static let open: AttributesSection.Identifier = "NSImageView_Open"
            public static let scaling: AttributesSection.Identifier = "NSImageView_Scaling"
            public static let behavior: AttributesSection.Identifier = "NSImageView_Behavior"
            public static let contentTintColor: AttributesSection.Identifier = "NSImageView_ContentTintColor"
            public static let symbolConfiguration: AttributesSection.Identifier = "NSImageView_SymbolConfiguration"
            public static let allowsCutCopyPaste: AttributesSection.Identifier = "NSImageView_AllowsCutCopyPaste"
            public static let preferredImageDynamicRange: AttributesSection.Identifier = "NSImageView_PreferredImageDynamicRange"
            public static let imageDynamicRange: AttributesSection.Identifier = "NSImageView_ImageDynamicRange"
        }

        public enum NSControl {
            public static let state: AttributesSection.Identifier = "NSControl_State"
            public static let controlSize: AttributesSection.Identifier = "NSControl_ControlSize"
            public static let font: AttributesSection.Identifier = "NSControl_Font"
            public static let alignment: AttributesSection.Identifier = "NSControl_Alignment"
            public static let miscellaneous: AttributesSection.Identifier = "NSControl_Misc"
            public static let value: AttributesSection.Identifier = "NSControl_Value"
            public static let stringValue: AttributesSection.Identifier = "NSControl_StringValue"
            public static let tag: AttributesSection.Identifier = "NSControl_Tag"
            public static let refusesFirstResponder: AttributesSection.Identifier = "NSControl_RefusesFirstResponder"
            public static let lineBreakMode: AttributesSection.Identifier = "NSControl_LineBreakMode"
        }

        public enum NSButton {
            public static let buttonType: AttributesSection.Identifier = "NSButton_ButtonType"
            public static let title: AttributesSection.Identifier = "NSButton_Title"
            public static let bezelStyle: AttributesSection.Identifier = "NSButton_BezelStyle"
            public static let bordered: AttributesSection.Identifier = "NSButton_Bordered"
            public static let transparent: AttributesSection.Identifier = "NSButton_Transparent"
            public static let bezelColor: AttributesSection.Identifier = "NSButton_BezelColor"
            public static let contentTintColor: AttributesSection.Identifier = "NSButton_ContentTintColor"
            public static let miscellaneous: AttributesSection.Identifier = "NSButton_Misc"
            public static let nsStatusBarButton: AttributesSection.Identifier = "NSButton_NSStatusBarButton"
            public static let tintProminence: AttributesSection.Identifier = "NSButton_TintProminence"
            public static let images: AttributesSection.Identifier = "NSButton_Images"
            public static let imagePosition: AttributesSection.Identifier = "NSButton_ImagePosition"
            public static let imageScaling: AttributesSection.Identifier = "NSButton_ImageScaling"
            public static let behavior: AttributesSection.Identifier = "NSButton_Behavior"
            public static let symbolConfiguration: AttributesSection.Identifier = "NSButton_SymbolConfiguration"
            public static let state: AttributesSection.Identifier = "NSButton_State"
            public static let keyEquivalent: AttributesSection.Identifier = "NSButton_KeyEquivalent"
            public static let keyEquivalentModifierMask: AttributesSection.Identifier = "NSButton_KeyEquivalentModifierMask"
            public static let borderShape: AttributesSection.Identifier = "NSButton_BorderShape"
        }

        public enum NSScrollView {
            public static let contentOffset: AttributesSection.Identifier = "NSScrollView_ContentOffset"
            public static let contentSize: AttributesSection.Identifier = "NSScrollView_ContentSize"
            public static let contentInset: AttributesSection.Identifier = "NSScrollView_ContentInset"
            public static let borderType: AttributesSection.Identifier = "NSScrollView_BorderType"
            public static let scroller: AttributesSection.Identifier = "NSScrollView_Scroller"
            public static let ruler: AttributesSection.Identifier = "NSScrollView_Ruler"
            public static let lineScroll: AttributesSection.Identifier = "NSScrollView_LineScroll"
            public static let pageScroll: AttributesSection.Identifier = "NSScrollView_PageScroll"
            public static let scrollElasiticity: AttributesSection.Identifier = "NSScrollView_ScrollElasiticity"
            public static let miscellaneous: AttributesSection.Identifier = "NSScrollView_Misc"
            public static let magnification: AttributesSection.Identifier = "NSScrollView_Magnification"
            public static let documentVisibleRect: AttributesSection.Identifier = "NSScrollView_DocumentVisibleRect"
            public static let backgroundColor: AttributesSection.Identifier = "NSScrollView_BackgroundColor"
            public static let behavior: AttributesSection.Identifier = "NSScrollView_Behavior"
            public static let contentInsets: AttributesSection.Identifier = "NSScrollView_ContentInsets"
            public static let minimumNumberOfTouchesForScrolling: AttributesSection.Identifier = "NSScrollView_MinimumNumberOfTouchesForScrolling"
            public static let maximumNumberOfTouchesForScrolling: AttributesSection.Identifier = "NSScrollView_MaximumNumberOfTouchesForScrolling"
            public static let findBarPosition: AttributesSection.Identifier = "NSScrollView_FindBarPosition"
        }

        public enum NSTableView {
            public static let rowHeight: AttributesSection.Identifier = "NSTableView_RowHeight"
            public static let automaticRowHeights: AttributesSection.Identifier = "NSTableView_AutomaticRowHeights"
            public static let intercellSpacing: AttributesSection.Identifier = "NSTableView_IntercellSpacing"
            public static let style: AttributesSection.Identifier = "NSTableView_Style"
            public static let columnAutoresizingStyle: AttributesSection.Identifier = "NSTableView_ColumnAutoresizingStyle"
            public static let gridStyleMask: AttributesSection.Identifier = "NSTableView_GridStyleMask"
            public static let selectionHighlightStyle: AttributesSection.Identifier = "NSTableView_SelectionHighlightStyle"
            public static let gridColor: AttributesSection.Identifier = "NSTableView_GridColor"
            public static let rowSizeStyle: AttributesSection.Identifier = "NSTableView_RowSizeStyle"
            public static let numberOfRows: AttributesSection.Identifier = "NSTableView_NumberOfRows"
            public static let numberOfColumns: AttributesSection.Identifier = "NSTableView_NumberOfColumns"
            public static let useAlternatingRowBackgroundColors: AttributesSection.Identifier = "NSTableView_UseAlternatingRowBackgroundColors"
            public static let allowsColumnReordering: AttributesSection.Identifier = "NSTableView_AllowsColumnReordering"
            public static let allowsColumnResizing: AttributesSection.Identifier = "NSTableView_AllowsColumnResizing"
            public static let allowsMultipleSelection: AttributesSection.Identifier = "NSTableView_AllowsMultipleSelection"
            public static let allowsEmptySelection: AttributesSection.Identifier = "NSTableView_AllowsEmptySelection"
            public static let allowsColumnSelection: AttributesSection.Identifier = "NSTableView_AllowsColumnSelection"
            public static let allowsTypeSelect: AttributesSection.Identifier = "NSTableView_AllowsTypeSelect"
            public static let draggingDestinationFeedbackStyle: AttributesSection.Identifier = "NSTableView_DraggingDestinationFeedbackStyle"
            public static let autosave: AttributesSection.Identifier = "NSTableView_Autosave"
            public static let floatsGroupRows: AttributesSection.Identifier = "NSTableView_FloatsGroupRows"
            public static let rowActionsVisible: AttributesSection.Identifier = "NSTableView_RowActionsVisible"
            public static let usesStaticContents: AttributesSection.Identifier = "NSTableView_UsesStaticContents"
            public static let userInterfaceLayoutDirection: AttributesSection.Identifier = "NSTableView_UserInterfaceLayoutDirection"
            public static let verticalMotionCanBeginDrag: AttributesSection.Identifier = "NSTableView_VerticalMotionCanBeginDrag"
            public static let backgroundColor: AttributesSection.Identifier = "NSTableView_BackgroundColor"
            public static let effectiveRowSizeStyle: AttributesSection.Identifier = "NSTableView_EffectiveRowSizeStyle"
            public static let editedColumn: AttributesSection.Identifier = "NSTableView_EditedColumn"
            public static let editedRow: AttributesSection.Identifier = "NSTableView_EditedRow"
            public static let clickedColumn: AttributesSection.Identifier = "NSTableView_ClickedColumn"
            public static let clickedRow: AttributesSection.Identifier = "NSTableView_ClickedRow"
            public static let selectedColumn: AttributesSection.Identifier = "NSTableView_SelectedColumn"
            public static let selectedRow: AttributesSection.Identifier = "NSTableView_SelectedRow"
            public static let numberOfSelectedColumns: AttributesSection.Identifier = "NSTableView_NumberOfSelectedColumns"
            public static let numberOfSelectedRows: AttributesSection.Identifier = "NSTableView_NumberOfSelectedRows"
            public static let effectiveStyle: AttributesSection.Identifier = "NSTableView_EffectiveStyle"
        }

        public enum NSTextView {
            public static let font: AttributesSection.Identifier = "NSTextView_Font"
            public static let basic: AttributesSection.Identifier = "NSTextView_Basic"
            public static let string: AttributesSection.Identifier = "NSTextView_String"
            public static let textColor: AttributesSection.Identifier = "NSTextView_TextColor"
            public static let alignment: AttributesSection.Identifier = "NSTextView_Alignment"
            public static let containerInset: AttributesSection.Identifier = "NSTextView_ContainerInset"
            public static let baseWritingDirection: AttributesSection.Identifier = "NSTextView_BaseWritingDirection"
            public static let size: AttributesSection.Identifier = "NSTextView_Size"
            public static let resizable: AttributesSection.Identifier = "NSTextView_Resizable"
            public static let textContainerOrigin: AttributesSection.Identifier = "NSTextView_TextContainerOrigin"
            public static let behavior: AttributesSection.Identifier = "NSTextView_Behavior"
            public static let selectionAffinity: AttributesSection.Identifier = "NSTextView_SelectionAffinity"
            public static let selectionGranularity: AttributesSection.Identifier = "NSTextView_SelectionGranularity"
            public static let colors: AttributesSection.Identifier = "NSTextView_Colors"
            public static let writingToolsBehavior: AttributesSection.Identifier = "NSTextView_WritingToolsBehavior"
            public static let allowedWritingToolsResultOptions: AttributesSection.Identifier = "NSTextView_AllowedWritingToolsResultOptions"
            public static let inlinePredictionType: AttributesSection.Identifier = "NSTextView_InlinePredictionType"
            public static let mathExpressionCompletionType: AttributesSection.Identifier = "NSTextView_MathExpressionCompletionType"
            public static let selectedRange: AttributesSection.Identifier = "NSTextView_SelectedRange"
        }

        public enum NSTextField {
            public static let bordered: AttributesSection.Identifier = "NSTextField_Bordered"
            public static let bezeled: AttributesSection.Identifier = "NSTextField_Bezeled"
            public static let bezelStyle: AttributesSection.Identifier = "NSTextField_BezelStyle"
            public static let editable: AttributesSection.Identifier = "NSTextField_Editable"
            public static let selectable: AttributesSection.Identifier = "NSTextField_Selectable"
            public static let drawsBackground: AttributesSection.Identifier = "NSTextField_DrawsBackground"
            public static let preferredMaxLayoutWidth: AttributesSection.Identifier = "NSTextField_PreferredMaxLayoutWidth"
            public static let maximumNumberOfLines: AttributesSection.Identifier = "NSTextField_MaximumNumberOfLines"
            public static let allowsDefaultTighteningForTruncation: AttributesSection.Identifier = "NSTextField_AllowsDefaultTighteningForTruncation"
            public static let lineBreakStrategy: AttributesSection.Identifier = "NSTextField_LineBreakStrategy"
            public static let placeholder: AttributesSection.Identifier = "NSTextField_Placeholder"
            public static let textColor: AttributesSection.Identifier = "NSTextField_TextColor"
            public static let nsTokenField: AttributesSection.Identifier = "NSTextField_NSTokenField"
            public static let behavior: AttributesSection.Identifier = "NSTextField_Behavior"
            public static let borderShape: AttributesSection.Identifier = "NSTextField_BorderShape"
        }

        public enum NSVisualEffectView {
            public static let material: AttributesSection.Identifier = "NSVisualEffectView_Material"
            public static let interiorBackgroundStyle: AttributesSection.Identifier = "NSVisualEffectView_InteriorBackgroundStyle"
            public static let blendingMode: AttributesSection.Identifier = "NSVisualEffectView_BlendingMode"
            public static let state: AttributesSection.Identifier = "NSVisualEffectView_State"
            public static let emphasized: AttributesSection.Identifier = "NSVisualEffectView_Emphasized"
            public static let maskImage: AttributesSection.Identifier = "NSVisualEffectView_MaskImage"
        }

        public enum NSStackView {
            public static let orientation: AttributesSection.Identifier = "NSStackView_Orientation"
            public static let edgeInsets: AttributesSection.Identifier = "NSStackView_EdgeInsets"
            public static let detachesHiddenViews: AttributesSection.Identifier = "NSStackView_DetachesHiddenViews"
            public static let distribution: AttributesSection.Identifier = "NSStackView_Distribution"
            public static let alignment: AttributesSection.Identifier = "NSStackView_Alignment"
            public static let spacing: AttributesSection.Identifier = "NSStackView_Spacing"
        }

        public enum NSWindow {
            public static let title: AttributesSection.Identifier = "NSWindow_Title"
            public static let subtitle: AttributesSection.Identifier = "NSWindow_Subtitle"
            public static let state: AttributesSection.Identifier = "NSWindow_State"
            public static let style: AttributesSection.Identifier = "NSWindow_Style"
            public static let collectionBehavior: AttributesSection.Identifier = "NSWindow_CollectionBehavior"
            public static let appearance: AttributesSection.Identifier = "NSWindow_Appearance"
            public static let titleVisibility: AttributesSection.Identifier = "NSWindow_TitleVisibility"
            public static let toolbarStyle: AttributesSection.Identifier = "NSWindow_ToolbarStyle"
            public static let titlebarSeparatorStyle: AttributesSection.Identifier = "NSWindow_TitlebarSeparatorStyle"
            public static let behavior: AttributesSection.Identifier = "NSWindow_Behavior"
            public static let animationBehavior: AttributesSection.Identifier = "NSWindow_AnimationBehavior"
            public static let level: AttributesSection.Identifier = "NSWindow_Level"
            public static let tabbingMode: AttributesSection.Identifier = "NSWindow_TabbingMode"
            public static let size: AttributesSection.Identifier = "NSWindow_Size"
            public static let information: AttributesSection.Identifier = "NSWindow_Info"
            public static let contentLayoutRect: AttributesSection.Identifier = "NSWindow_ContentLayoutRect"
            public static let representedURL: AttributesSection.Identifier = "NSWindow_RepresentedURL"
            public static let representedFilename: AttributesSection.Identifier = "NSWindow_RepresentedFilename"
            public static let flags: AttributesSection.Identifier = "NSWindow_Flags"
            public static let styleMask: AttributesSection.Identifier = "NSWindow_StyleMask"
            public static let cascadingReferenceFrame: AttributesSection.Identifier = "NSWindow_CascadingReferenceFrame"
            public static let resizeIncrements: AttributesSection.Identifier = "NSWindow_ResizeIncrements"
            public static let aspectRatio: AttributesSection.Identifier = "NSWindow_AspectRatio"
            public static let contentResizeIncrements: AttributesSection.Identifier = "NSWindow_ContentResizeIncrements"
            public static let contentAspectRatio: AttributesSection.Identifier = "NSWindow_ContentAspectRatio"
            public static let miniwindowTitle: AttributesSection.Identifier = "NSWindow_MiniwindowTitle"
            public static let backingType: AttributesSection.Identifier = "NSWindow_BackingType"
            public static let depthLimit: AttributesSection.Identifier = "NSWindow_DepthLimit"
            public static let screen: AttributesSection.Identifier = "NSWindow_Screen"
            public static let deepestScreen: AttributesSection.Identifier = "NSWindow_DeepestScreen"
            public static let sharingType: AttributesSection.Identifier = "NSWindow_SharingType"
            public static let collectionBehaviorOptions: AttributesSection.Identifier = "NSWindow_CollectionBehaviorOptions"
            public static let contentMinSize: AttributesSection.Identifier = "NSWindow_ContentMinSize"
            public static let contentMaxSize: AttributesSection.Identifier = "NSWindow_ContentMaxSize"
            public static let minFullScreenContentSize: AttributesSection.Identifier = "NSWindow_MinFullScreenContentSize"
            public static let maxFullScreenContentSize: AttributesSection.Identifier = "NSWindow_MaxFullScreenContentSize"
            public static let occlusionState: AttributesSection.Identifier = "NSWindow_OcclusionState"
            public static let keyViewSelectionDirection: AttributesSection.Identifier = "NSWindow_KeyViewSelectionDirection"
            public static let toolbar: AttributesSection.Identifier = "NSWindow_Toolbar"
            public static let orderedIndex: AttributesSection.Identifier = "NSWindow_OrderedIndex"
            public static let firstResponder: AttributesSection.Identifier = "NSWindow_FirstResponder"
        }

        public enum NSSlider {
            public static let sliderType: AttributesSection.Identifier = "NSSlider_SliderType"
            public static let range: AttributesSection.Identifier = "NSSlider_Range"
            public static let tickMark: AttributesSection.Identifier = "NSSlider_TickMark"
            public static let miscellaneous: AttributesSection.Identifier = "NSSlider_Misc"
            public static let neutralValue: AttributesSection.Identifier = "NSSlider_NeutralValue"
            public static let tintProminence: AttributesSection.Identifier = "NSSlider_TintProminence"
        }

        public enum NSProgressIndicator {
            public static let style: AttributesSection.Identifier = "NSProgressIndicator_Style"
            public static let range: AttributesSection.Identifier = "NSProgressIndicator_Range"
            public static let miscellaneous: AttributesSection.Identifier = "NSProgressIndicator_Misc"
            public static let controlSize: AttributesSection.Identifier = "NSProgressIndicator_ControlSize"
            public static let usesThreadedAnimation: AttributesSection.Identifier = "NSProgressIndicator_UsesThreadedAnimation"
        }

        public enum NSSegmentedControl {
            public static let segmentCount: AttributesSection.Identifier = "NSSegmentedControl_SegmentCount"
            public static let selection: AttributesSection.Identifier = "NSSegmentedControl_Selection"
            public static let style: AttributesSection.Identifier = "NSSegmentedControl_Style"
            public static let colors: AttributesSection.Identifier = "NSSegmentedControl_Colors"
            public static let role: AttributesSection.Identifier = "NSSegmentedControl_Role"
            public static let springLoaded: AttributesSection.Identifier = "NSSegmentedControl_SpringLoaded"
            public static let doubleValueForSelectedSegment: AttributesSection.Identifier = "NSSegmentedControl_DoubleValueForSelectedSegment"
            public static let indexOfSelectedItem: AttributesSection.Identifier = "NSSegmentedControl_IndexOfSelectedItem"
            public static let segmentDistribution: AttributesSection.Identifier = "NSSegmentedControl_SegmentDistribution"
            public static let borderShape: AttributesSection.Identifier = "NSSegmentedControl_BorderShape"
        }

        public enum NSPopUpButton {
            public static let behavior: AttributesSection.Identifier = "NSPopUpButton_Behavior"
            public static let selection: AttributesSection.Identifier = "NSPopUpButton_Selection"
            public static let items: AttributesSection.Identifier = "NSPopUpButton_Items"
            public static let menu: AttributesSection.Identifier = "NSPopUpButton_Menu"
            public static let flags: AttributesSection.Identifier = "NSPopUpButton_Flags"
        }

        public enum NSComboBox {
            public static let items: AttributesSection.Identifier = "NSComboBox_Items"
            public static let miscellaneous: AttributesSection.Identifier = "NSComboBox_Misc"
            public static let indexOfSelectedItem: AttributesSection.Identifier = "NSComboBox_IndexOfSelectedItem"
        }

        public enum NSStepper {
            public static let range: AttributesSection.Identifier = "NSStepper_Range"
            public static let miscellaneous: AttributesSection.Identifier = "NSStepper_Misc"
        }

        public enum NSColorWell {
            public static let color: AttributesSection.Identifier = "NSColorWell_Color"
            public static let miscellaneous: AttributesSection.Identifier = "NSColorWell_Misc"
            public static let image: AttributesSection.Identifier = "NSColorWell_Image"
            public static let supportsAlpha: AttributesSection.Identifier = "NSColorWell_SupportsAlpha"
            public static let maximumLinearExposure: AttributesSection.Identifier = "NSColorWell_MaximumLinearExposure"
        }

        public enum NSSwitch {
            public static let state: AttributesSection.Identifier = "NSSwitch_State"
        }

        public enum NSDatePicker {
            public static let style: AttributesSection.Identifier = "NSDatePicker_Style"
            public static let range: AttributesSection.Identifier = "NSDatePicker_Range"
            public static let miscellaneous: AttributesSection.Identifier = "NSDatePicker_Misc"
            public static let colors: AttributesSection.Identifier = "NSDatePicker_Colors"
            public static let datePickerElements: AttributesSection.Identifier = "NSDatePicker_DatePickerElements"
            public static let calendar: AttributesSection.Identifier = "NSDatePicker_Calendar"
            public static let locale: AttributesSection.Identifier = "NSDatePicker_Locale"
            public static let timeZone: AttributesSection.Identifier = "NSDatePicker_TimeZone"
            public static let timeInterval: AttributesSection.Identifier = "NSDatePicker_TimeInterval"
            public static let presentsCalendarOverlay: AttributesSection.Identifier = "NSDatePicker_PresentsCalendarOverlay"
        }

        public enum NSLevelIndicator {
            public static let style: AttributesSection.Identifier = "NSLevelIndicator_Style"
            public static let range: AttributesSection.Identifier = "NSLevelIndicator_Range"
            public static let tickMark: AttributesSection.Identifier = "NSLevelIndicator_TickMark"
            public static let behavior: AttributesSection.Identifier = "NSLevelIndicator_Behavior"
            public static let tickMarkPosition: AttributesSection.Identifier = "NSLevelIndicator_TickMarkPosition"
            public static let colors: AttributesSection.Identifier = "NSLevelIndicator_Colors"
            public static let placeholderVisibility: AttributesSection.Identifier = "NSLevelIndicator_PlaceholderVisibility"
            public static let images: AttributesSection.Identifier = "NSLevelIndicator_Images"
        }

        public enum NSOutlineView {
            public static let indentation: AttributesSection.Identifier = "NSOutlineView_Indentation"
            public static let miscellaneous: AttributesSection.Identifier = "NSOutlineView_Misc"
            public static let userInterfaceLayoutDirection: AttributesSection.Identifier = "NSOutlineView_UserInterfaceLayoutDirection"
            public static let stronglyReferencesItems: AttributesSection.Identifier = "NSOutlineView_StronglyReferencesItems"
        }

        public enum NSCollectionView {
            public static let selection: AttributesSection.Identifier = "NSCollectionView_Selection"
            public static let information: AttributesSection.Identifier = "NSCollectionView_Info"
            public static let colors: AttributesSection.Identifier = "NSCollectionView_Colors"
            public static let backgroundViewScrollsWithContent: AttributesSection.Identifier = "NSCollectionView_BackgroundViewScrollsWithContent"
        }

        public enum NSBox {
            public static let kind: AttributesSection.Identifier = "NSBox_Type"
            public static let title: AttributesSection.Identifier = "NSBox_Title"
            public static let appearance: AttributesSection.Identifier = "NSBox_Appearance"
            public static let metrics: AttributesSection.Identifier = "NSBox_Metrics"
            public static let titleFont: AttributesSection.Identifier = "NSBox_TitleFont"
            public static let borderRect: AttributesSection.Identifier = "NSBox_BorderRect"
            public static let titleRect: AttributesSection.Identifier = "NSBox_TitleRect"
        }

        public enum NSSplitView {
            public static let orientation: AttributesSection.Identifier = "NSSplitView_Orientation"
            public static let style: AttributesSection.Identifier = "NSSplitView_Style"
            public static let miscellaneous: AttributesSection.Identifier = "NSSplitView_Misc"
            public static let dividerColor: AttributesSection.Identifier = "NSSplitView_DividerColor"
        }

        public enum NSTabView {
            public static let kind: AttributesSection.Identifier = "NSTabView_Type"
            public static let miscellaneous: AttributesSection.Identifier = "NSTabView_Misc"
            public static let information: AttributesSection.Identifier = "NSTabView_Info"
            public static let font: AttributesSection.Identifier = "NSTabView_Font"
            public static let minimumSize: AttributesSection.Identifier = "NSTabView_MinimumSize"
            public static let controlSize: AttributesSection.Identifier = "NSTabView_ControlSize"
            public static let contentRect: AttributesSection.Identifier = "NSTabView_ContentRect"
        }

        public enum NSGridView {
            public static let dimensions: AttributesSection.Identifier = "NSGridView_Dimensions"
            public static let spacing: AttributesSection.Identifier = "NSGridView_Spacing"
            public static let placement: AttributesSection.Identifier = "NSGridView_Placement"
            public static let rowAlignment: AttributesSection.Identifier = "NSGridView_RowAlignment"
        }

        public enum LayoutGuide {
            public static let guideIdentifier: AttributesSection.Identifier = "LayoutGuide_Identifier"
            public static let layoutFrame: AttributesSection.Identifier = "LayoutGuide_LayoutFrame"
            public static let owningView: AttributesSection.Identifier = "LayoutGuide_OwningView"
            public static let constraints: AttributesSection.Identifier = "LayoutGuide_Constraints"
            public static let keyboardLayoutGuide: AttributesSection.Identifier = "LayoutGuide_KeyboardLayoutGuide"
            public static let keyboardDismissPadding: AttributesSection.Identifier = "LayoutGuide_KeyboardDismissPadding"
            public static let constraintsActiveNearEdges: AttributesSection.Identifier = "LayoutGuide_ConstraintsActiveNearEdges"
            public static let constraintsActiveAwayFromEdges: AttributesSection.Identifier = "LayoutGuide_ConstraintsActiveAwayFromEdges"
        }

        public enum NSCell {
            public static let cell: AttributesSection.Identifier = "NSCell_Cell"
            public static let content: AttributesSection.Identifier = "NSCell_Content"
            public static let behavior: AttributesSection.Identifier = "NSCell_Behavior"
            public static let buttonCell: AttributesSection.Identifier = "NSCell_ButtonCell"
            public static let textFieldCell: AttributesSection.Identifier = "NSCell_TextFieldCell"
            public static let controlView: AttributesSection.Identifier = "NSCell_ControlView"
            public static let flags: AttributesSection.Identifier = "NSCell_Flags"
            public static let font: AttributesSection.Identifier = "NSCell_Font"
            public static let keyEquivalent: AttributesSection.Identifier = "NSCell_KeyEquivalent"
            public static let stringValue: AttributesSection.Identifier = "NSCell_StringValue"
            public static let intValue: AttributesSection.Identifier = "NSCell_IntValue"
            public static let floatValue: AttributesSection.Identifier = "NSCell_FloatValue"
            public static let doubleValue: AttributesSection.Identifier = "NSCell_DoubleValue"
            public static let integerValue: AttributesSection.Identifier = "NSCell_IntegerValue"
            public static let image: AttributesSection.Identifier = "NSCell_Image"
            public static let cellSize: AttributesSection.Identifier = "NSCell_CellSize"
            public static let mouseDownFlags: AttributesSection.Identifier = "NSCell_MouseDownFlags"
            public static let menu: AttributesSection.Identifier = "NSCell_Menu"
            public static let baseWritingDirection: AttributesSection.Identifier = "NSCell_BaseWritingDirection"
            public static let userInterfaceLayoutDirection: AttributesSection.Identifier = "NSCell_UserInterfaceLayoutDirection"
            public static let focusRingType: AttributesSection.Identifier = "NSCell_FocusRingType"
            public static let attributedStringValue: AttributesSection.Identifier = "NSCell_AttributedStringValue"
            public static let nextState: AttributesSection.Identifier = "NSCell_NextState"
            public static let backgroundStyle: AttributesSection.Identifier = "NSCell_BackgroundStyle"
            public static let interiorBackgroundStyle: AttributesSection.Identifier = "NSCell_InteriorBackgroundStyle"
            public static let nsActionCell: AttributesSection.Identifier = "NSCell_NSActionCell"
            public static let nsMenuItemCell: AttributesSection.Identifier = "NSCell_NSMenuItemCell"
            public static let nsPopUpButtonCell: AttributesSection.Identifier = "NSCell_NSPopUpButtonCell"
            public static let nsDatePickerCell: AttributesSection.Identifier = "NSCell_NSDatePickerCell"
            public static let nsFormCell: AttributesSection.Identifier = "NSCell_NSFormCell"
            public static let nsLevelIndicatorCell: AttributesSection.Identifier = "NSCell_NSLevelIndicatorCell"
            public static let nsPathCell: AttributesSection.Identifier = "NSCell_NSPathCell"
            public static let nsSegmentedCell: AttributesSection.Identifier = "NSCell_NSSegmentedCell"
            public static let nsSliderCell: AttributesSection.Identifier = "NSCell_NSSliderCell"
            public static let nsStepperCell: AttributesSection.Identifier = "NSCell_NSStepperCell"
            public static let nsComboBoxCell: AttributesSection.Identifier = "NSCell_NSComboBoxCell"
            public static let nsPathComponentCell: AttributesSection.Identifier = "NSCell_NSPathComponentCell"
            public static let nsSearchFieldCell: AttributesSection.Identifier = "NSCell_NSSearchFieldCell"
            public static let nsSecureTextFieldCell: AttributesSection.Identifier = "NSCell_NSSecureTextFieldCell"
            public static let nsTokenFieldCell: AttributesSection.Identifier = "NSCell_NSTokenFieldCell"
            public static let nsBrowserCell: AttributesSection.Identifier = "NSCell_NSBrowserCell"
            public static let nsImageCell: AttributesSection.Identifier = "NSCell_NSImageCell"
        }

        public enum UIWindowScene {
            public static let state: AttributesSection.Identifier = "UIWindowScene_State"
            public static let title: AttributesSection.Identifier = "UIWindowScene_Title"
            public static let orientation: AttributesSection.Identifier = "UIWindowScene_Orientation"
            public static let windows: AttributesSection.Identifier = "UIWindowScene_Windows"
            public static let screen: AttributesSection.Identifier = "UIWindowScene_Screen"
            public static let statusBar: AttributesSection.Identifier = "UIWindowScene_StatusBar"
            public static let traits: AttributesSection.Identifier = "UIWindowScene_Traits"
            public static let session: AttributesSection.Identifier = "UIWindowScene_Session"
            public static let configuration: AttributesSection.Identifier = "UIWindowScene_Configuration"
            public static let geometry: AttributesSection.Identifier = "UIWindowScene_Geometry"
            public static let activationConditions: AttributesSection.Identifier = "UIWindowScene_ActivationConditions"
            public static let sizeRestrictions: AttributesSection.Identifier = "UIWindowScene_SizeRestrictions"
            public static let windowingBehaviors: AttributesSection.Identifier = "UIWindowScene_WindowingBehaviors"
            public static let pointer: AttributesSection.Identifier = "UIWindowScene_Pointer"
            public static let protection: AttributesSection.Identifier = "UIWindowScene_Protection"
        }

        public enum UITraitCollection {
            public static let appearance: AttributesSection.Identifier = "UITraitCollection_Appearance"
            public static let sizeClass: AttributesSection.Identifier = "UITraitCollection_SizeClass"
            public static let display: AttributesSection.Identifier = "UITraitCollection_Display"
            public static let device: AttributesSection.Identifier = "UITraitCollection_Device"
            public static let layout: AttributesSection.Identifier = "UITraitCollection_Layout"
            public static let content: AttributesSection.Identifier = "UITraitCollection_Content"
        }

        public enum UISlider {
            public static let behavioralStyle: AttributesSection.Identifier = "UISlider_BehavioralStyle"
            public static let preferredBehavioralStyle: AttributesSection.Identifier = "UISlider_PreferredBehavioralStyle"
            public static let value: AttributesSection.Identifier = "UISlider_Value"
            public static let images: AttributesSection.Identifier = "UISlider_Images"
            public static let continuous: AttributesSection.Identifier = "UISlider_Continuous"
            public static let sliderStyle: AttributesSection.Identifier = "UISlider_SliderStyle"
            public static let colors: AttributesSection.Identifier = "UISlider_Colors"
        }

        public enum UIStepper {
            public static let behavior: AttributesSection.Identifier = "UIStepper_Behavior"
            public static let value: AttributesSection.Identifier = "UIStepper_Value"
        }

        public enum UISwitch {
            public static let colors: AttributesSection.Identifier = "UISwitch_Colors"
            public static let images: AttributesSection.Identifier = "UISwitch_Images"
            public static let title: AttributesSection.Identifier = "UISwitch_Title"
            public static let style: AttributesSection.Identifier = "UISwitch_Style"
            public static let preferredStyle: AttributesSection.Identifier = "UISwitch_PreferredStyle"
            public static let on: AttributesSection.Identifier = "UISwitch_On"
        }

        public enum UISegmentedControl {
            public static let behavior: AttributesSection.Identifier = "UISegmentedControl_Behavior"
            public static let numberOfSegments: AttributesSection.Identifier = "UISegmentedControl_NumberOfSegments"
            public static let selectedSegmentIndex: AttributesSection.Identifier = "UISegmentedControl_SelectedSegmentIndex"
            public static let selectedSegmentTintColor: AttributesSection.Identifier = "UISegmentedControl_SelectedSegmentTintColor"
        }

        public enum UIProgressView {
            public static let progressViewStyle: AttributesSection.Identifier = "UIProgressView_ProgressViewStyle"
            public static let progress: AttributesSection.Identifier = "UIProgressView_Progress"
            public static let colors: AttributesSection.Identifier = "UIProgressView_Colors"
            public static let images: AttributesSection.Identifier = "UIProgressView_Images"
        }

        public enum UIActivityIndicatorView {
            public static let activityIndicatorViewStyle: AttributesSection.Identifier = "UIActivityIndicatorView_ActivityIndicatorViewStyle"
            public static let behavior: AttributesSection.Identifier = "UIActivityIndicatorView_Behavior"
            public static let color: AttributesSection.Identifier = "UIActivityIndicatorView_Color"
        }

        public enum UIPageControl {
            public static let numberOfPages: AttributesSection.Identifier = "UIPageControl_NumberOfPages"
            public static let currentPage: AttributesSection.Identifier = "UIPageControl_CurrentPage"
            public static let behavior: AttributesSection.Identifier = "UIPageControl_Behavior"
            public static let colors: AttributesSection.Identifier = "UIPageControl_Colors"
            public static let backgroundStyle: AttributesSection.Identifier = "UIPageControl_BackgroundStyle"
            public static let direction: AttributesSection.Identifier = "UIPageControl_Direction"
            public static let interactionState: AttributesSection.Identifier = "UIPageControl_InteractionState"
            public static let images: AttributesSection.Identifier = "UIPageControl_Images"
        }

        public enum UIDatePicker {
            public static let datePickerMode: AttributesSection.Identifier = "UIDatePicker_DatePickerMode"
            public static let locale: AttributesSection.Identifier = "UIDatePicker_Locale"
            public static let calendar: AttributesSection.Identifier = "UIDatePicker_Calendar"
            public static let timeZone: AttributesSection.Identifier = "UIDatePicker_TimeZone"
            public static let date: AttributesSection.Identifier = "UIDatePicker_Date"
            public static let minimumDate: AttributesSection.Identifier = "UIDatePicker_MinimumDate"
            public static let maximumDate: AttributesSection.Identifier = "UIDatePicker_MaximumDate"
            public static let countDownDuration: AttributesSection.Identifier = "UIDatePicker_CountDownDuration"
            public static let minuteInterval: AttributesSection.Identifier = "UIDatePicker_MinuteInterval"
            public static let preferredDatePickerStyle: AttributesSection.Identifier = "UIDatePicker_PreferredDatePickerStyle"
            public static let datePickerStyle: AttributesSection.Identifier = "UIDatePicker_DatePickerStyle"
            public static let roundsToMinuteInterval: AttributesSection.Identifier = "UIDatePicker_RoundsToMinuteInterval"
        }

        public enum UIColorWell {
            public static let title: AttributesSection.Identifier = "UIColorWell_Title"
            public static let behavior: AttributesSection.Identifier = "UIColorWell_Behavior"
            public static let selectedColor: AttributesSection.Identifier = "UIColorWell_SelectedColor"
            public static let maximumLinearExposure: AttributesSection.Identifier = "UIColorWell_MaximumLinearExposure"
        }

        public enum UIRefreshControl {
            public static let refreshing: AttributesSection.Identifier = "UIRefreshControl_Refreshing"
            public static let attributedTitle: AttributesSection.Identifier = "UIRefreshControl_AttributedTitle"
        }

        public enum UIPickerView {
            public static let numberOfComponents: AttributesSection.Identifier = "UIPickerView_NumberOfComponents"
        }

        public enum UICalendarView {
            public static let locale: AttributesSection.Identifier = "UICalendarView_Locale"
            public static let calendar: AttributesSection.Identifier = "UICalendarView_Calendar"
            public static let timeZone: AttributesSection.Identifier = "UICalendarView_TimeZone"
            public static let fontDesign: AttributesSection.Identifier = "UICalendarView_FontDesign"
            public static let wantsDateDecorations: AttributesSection.Identifier = "UICalendarView_WantsDateDecorations"
        }

        public enum UIPasteControl {
            public static let configuration: AttributesSection.Identifier = "UIPasteControl_Configuration"
        }

        public enum UICollectionView {
            public static let behavior: AttributesSection.Identifier = "UICollectionView_Behavior"
            public static let reorderingCadence: AttributesSection.Identifier = "UICollectionView_ReorderingCadence"
            public static let selfSizingInvalidation: AttributesSection.Identifier = "UICollectionView_SelfSizingInvalidation"
            public static let indexPathsForSelectedItems: AttributesSection.Identifier = "UICollectionView_IndexPathsForSelectedItems"
            public static let numberOfSections: AttributesSection.Identifier = "UICollectionView_NumberOfSections"
        }

        public enum UICollectionReusableView {
            public static let reuseIdentifier: AttributesSection.Identifier = "UICollectionReusableView_ReuseIdentifier"
            public static let uiCollectionViewCell: AttributesSection.Identifier = "UICollectionReusableView_UICollectionViewCell"
            public static let uiCollectionViewListCell: AttributesSection.Identifier = "UICollectionReusableView_UICollectionViewListCell"
        }

        public enum UITableViewCell {
            public static let behavior: AttributesSection.Identifier = "UITableViewCell_Behavior"
            public static let backgroundConfiguration: AttributesSection.Identifier = "UITableViewCell_BackgroundConfiguration"
            public static let reuseIdentifier: AttributesSection.Identifier = "UITableViewCell_ReuseIdentifier"
            public static let selectionStyle: AttributesSection.Identifier = "UITableViewCell_SelectionStyle"
            public static let editingStyle: AttributesSection.Identifier = "UITableViewCell_EditingStyle"
            public static let accessoryType: AttributesSection.Identifier = "UITableViewCell_AccessoryType"
            public static let editingAccessoryType: AttributesSection.Identifier = "UITableViewCell_EditingAccessoryType"
            public static let indentationLevel: AttributesSection.Identifier = "UITableViewCell_IndentationLevel"
            public static let indentationWidth: AttributesSection.Identifier = "UITableViewCell_IndentationWidth"
            public static let separatorInset: AttributesSection.Identifier = "UITableViewCell_SeparatorInset"
            public static let focusStyle: AttributesSection.Identifier = "UITableViewCell_FocusStyle"
        }

        public enum UITableViewHeaderFooterView {
            public static let behavior: AttributesSection.Identifier = "UITableViewHeaderFooterView_Behavior"
            public static let backgroundConfiguration: AttributesSection.Identifier = "UITableViewHeaderFooterView_BackgroundConfiguration"
            public static let reuseIdentifier: AttributesSection.Identifier = "UITableViewHeaderFooterView_ReuseIdentifier"
        }

        public enum UINavigationBar {
            public static let barStyle: AttributesSection.Identifier = "UINavigationBar_BarStyle"
            public static let behavior: AttributesSection.Identifier = "UINavigationBar_Behavior"
            public static let topItem: AttributesSection.Identifier = "UINavigationBar_TopItem"
            public static let backItem: AttributesSection.Identifier = "UINavigationBar_BackItem"
            public static let currentNSToolbarSection: AttributesSection.Identifier = "UINavigationBar_CurrentNSToolbarSection"
            public static let behavioralStyle: AttributesSection.Identifier = "UINavigationBar_BehavioralStyle"
            public static let preferredBehavioralStyle: AttributesSection.Identifier = "UINavigationBar_PreferredBehavioralStyle"
            public static let barTintColor: AttributesSection.Identifier = "UINavigationBar_BarTintColor"
            public static let images: AttributesSection.Identifier = "UINavigationBar_Images"
        }

        public enum UITabBar {
            public static let selectedItem: AttributesSection.Identifier = "UITabBar_SelectedItem"
            public static let behavior: AttributesSection.Identifier = "UITabBar_Behavior"
            public static let colors: AttributesSection.Identifier = "UITabBar_Colors"
            public static let images: AttributesSection.Identifier = "UITabBar_Images"
            public static let itemPositioning: AttributesSection.Identifier = "UITabBar_ItemPositioning"
            public static let itemWidth: AttributesSection.Identifier = "UITabBar_ItemWidth"
            public static let itemSpacing: AttributesSection.Identifier = "UITabBar_ItemSpacing"
            public static let barStyle: AttributesSection.Identifier = "UITabBar_BarStyle"
        }

        public enum UIToolbar {
            public static let barStyle: AttributesSection.Identifier = "UIToolbar_BarStyle"
            public static let translucent: AttributesSection.Identifier = "UIToolbar_Translucent"
            public static let barTintColor: AttributesSection.Identifier = "UIToolbar_BarTintColor"
        }

        public enum UISearchBar {
            public static let barStyle: AttributesSection.Identifier = "UISearchBar_BarStyle"
            public static let text: AttributesSection.Identifier = "UISearchBar_Text"
            public static let prompt: AttributesSection.Identifier = "UISearchBar_Prompt"
            public static let placeholder: AttributesSection.Identifier = "UISearchBar_Placeholder"
            public static let behavior: AttributesSection.Identifier = "UISearchBar_Behavior"
            public static let barTintColor: AttributesSection.Identifier = "UISearchBar_BarTintColor"
            public static let searchBarStyle: AttributesSection.Identifier = "UISearchBar_SearchBarStyle"
            public static let scopeButtonTitles: AttributesSection.Identifier = "UISearchBar_ScopeButtonTitles"
            public static let selectedScopeButtonIndex: AttributesSection.Identifier = "UISearchBar_SelectedScopeButtonIndex"
            public static let images: AttributesSection.Identifier = "UISearchBar_Images"
            public static let searchFieldBackgroundPositionAdjustment: AttributesSection.Identifier = "UISearchBar_SearchFieldBackgroundPositionAdjustment"
            public static let searchTextPositionAdjustment: AttributesSection.Identifier = "UISearchBar_SearchTextPositionAdjustment"
        }

        public enum UIInputView {
            public static let inputViewStyle: AttributesSection.Identifier = "UIInputView_InputViewStyle"
            public static let allowsSelfSizing: AttributesSection.Identifier = "UIInputView_AllowsSelfSizing"
        }

        public enum UIContentUnavailableView {
            public static let configuration: AttributesSection.Identifier = "UIContentUnavailableView_Configuration"
            public static let scrollEnabled: AttributesSection.Identifier = "UIContentUnavailableView_ScrollEnabled"
        }

        public enum UIBackgroundExtensionView {
            public static let automaticallyPlacesContentView: AttributesSection.Identifier = "UIBackgroundExtensionView_AutomaticallyPlacesContentView"
        }

        public enum UIWindow {
            public static let behavior: AttributesSection.Identifier = "UIWindow_Behavior"
            public static let windowLevel: AttributesSection.Identifier = "UIWindow_WindowLevel"
            public static let rootViewController: AttributesSection.Identifier = "UIWindow_RootViewController"
        }

        public enum UIView {
            public static let behavior: AttributesSection.Identifier = "UIView_Behavior"
            public static let largeContentTitle: AttributesSection.Identifier = "UIView_LargeContentTitle"
            public static let largeContentImageInsets: AttributesSection.Identifier = "UIView_LargeContentImageInsets"
            public static let focusGroupIdentifier: AttributesSection.Identifier = "UIView_FocusGroupIdentifier"
            public static let semanticContentAttribute: AttributesSection.Identifier = "UIView_SemanticContentAttribute"
            public static let effectiveUserInterfaceLayoutDirection: AttributesSection.Identifier = "UIView_EffectiveUserInterfaceLayoutDirection"
            public static let transform: AttributesSection.Identifier = "UIView_Transform"
            public static let transform3D: AttributesSection.Identifier = "UIView_Transform3D"
            public static let contentScaleFactor: AttributesSection.Identifier = "UIView_ContentScaleFactor"
            public static let autoresizingMask: AttributesSection.Identifier = "UIView_AutoresizingMask"
            public static let layoutMargins: AttributesSection.Identifier = "UIView_LayoutMargins"
            public static let directionalLayoutMargins: AttributesSection.Identifier = "UIView_DirectionalLayoutMargins"
            public static let alignmentRectInsets: AttributesSection.Identifier = "UIView_AlignmentRectInsets"
            public static let restorationIdentifier: AttributesSection.Identifier = "UIView_RestorationIdentifier"
            public static let overrideUserInterfaceStyle: AttributesSection.Identifier = "UIView_OverrideUserInterfaceStyle"
            public static let minimumContentSizeCategory: AttributesSection.Identifier = "UIView_MinimumContentSizeCategory"
            public static let maximumContentSizeCategory: AttributesSection.Identifier = "UIView_MaximumContentSizeCategory"
            public static let appliedContentSizeCategoryLimitsDescription: AttributesSection.Identifier = "UIView_AppliedContentSizeCategoryLimitsDescription"
            public static let cornerConfiguration: AttributesSection.Identifier = "UIView_CornerConfiguration"
        }

        public enum NSClipView {
            public static let backgroundColor: AttributesSection.Identifier = "NSClipView_BackgroundColor"
            public static let behavior: AttributesSection.Identifier = "NSClipView_Behavior"
            public static let documentRect: AttributesSection.Identifier = "NSClipView_DocumentRect"
            public static let documentVisibleRect: AttributesSection.Identifier = "NSClipView_DocumentVisibleRect"
            public static let contentInsets: AttributesSection.Identifier = "NSClipView_ContentInsets"
        }

        public enum NSScroller {
            public static let scrollerStyle: AttributesSection.Identifier = "NSScroller_ScrollerStyle"
            public static let knobStyle: AttributesSection.Identifier = "NSScroller_KnobStyle"
            public static let usableParts: AttributesSection.Identifier = "NSScroller_UsableParts"
            public static let controlSize: AttributesSection.Identifier = "NSScroller_ControlSize"
            public static let hitPart: AttributesSection.Identifier = "NSScroller_HitPart"
            public static let knobProportion: AttributesSection.Identifier = "NSScroller_KnobProportion"
        }

        public enum NSBrowser {
            public static let behavior: AttributesSection.Identifier = "NSBrowser_Behavior"
            public static let minColumnWidth: AttributesSection.Identifier = "NSBrowser_MinColumnWidth"
            public static let maxVisibleColumns: AttributesSection.Identifier = "NSBrowser_MaxVisibleColumns"
            public static let pathSeparator: AttributesSection.Identifier = "NSBrowser_PathSeparator"
            public static let clickedColumn: AttributesSection.Identifier = "NSBrowser_ClickedColumn"
            public static let clickedRow: AttributesSection.Identifier = "NSBrowser_ClickedRow"
            public static let selectedColumn: AttributesSection.Identifier = "NSBrowser_SelectedColumn"
            public static let lastColumn: AttributesSection.Identifier = "NSBrowser_LastColumn"
            public static let numberOfVisibleColumns: AttributesSection.Identifier = "NSBrowser_NumberOfVisibleColumns"
            public static let firstVisibleColumn: AttributesSection.Identifier = "NSBrowser_FirstVisibleColumn"
            public static let lastVisibleColumn: AttributesSection.Identifier = "NSBrowser_LastVisibleColumn"
            public static let titleHeight: AttributesSection.Identifier = "NSBrowser_TitleHeight"
            public static let columnResizingType: AttributesSection.Identifier = "NSBrowser_ColumnResizingType"
            public static let backgroundColor: AttributesSection.Identifier = "NSBrowser_BackgroundColor"
        }

        public enum NSMatrix {
            public static let mode: AttributesSection.Identifier = "NSMatrix_Mode"
            public static let behavior: AttributesSection.Identifier = "NSMatrix_Behavior"
            public static let selectedRow: AttributesSection.Identifier = "NSMatrix_SelectedRow"
            public static let selectedColumn: AttributesSection.Identifier = "NSMatrix_SelectedColumn"
            public static let cellSize: AttributesSection.Identifier = "NSMatrix_CellSize"
            public static let intercellSpacing: AttributesSection.Identifier = "NSMatrix_IntercellSpacing"
            public static let colors: AttributesSection.Identifier = "NSMatrix_Colors"
            public static let numberOfRows: AttributesSection.Identifier = "NSMatrix_NumberOfRows"
            public static let numberOfColumns: AttributesSection.Identifier = "NSMatrix_NumberOfColumns"
        }

        public enum NSPathControl {
            public static let editable: AttributesSection.Identifier = "NSPathControl_Editable"
            public static let placeholderString: AttributesSection.Identifier = "NSPathControl_PlaceholderString"
            public static let url: AttributesSection.Identifier = "NSPathControl_URL"
            public static let pathStyle: AttributesSection.Identifier = "NSPathControl_PathStyle"
            public static let backgroundColor: AttributesSection.Identifier = "NSPathControl_BackgroundColor"
            public static let menu: AttributesSection.Identifier = "NSPathControl_Menu"
        }

        public enum NSRuleEditor {
            public static let nestingMode: AttributesSection.Identifier = "NSRuleEditor_NestingMode"
            public static let rowHeight: AttributesSection.Identifier = "NSRuleEditor_RowHeight"
            public static let behavior: AttributesSection.Identifier = "NSRuleEditor_Behavior"
            public static let numberOfRows: AttributesSection.Identifier = "NSRuleEditor_NumberOfRows"
        }

        public enum NSSearchField {
            public static let searchTextBounds: AttributesSection.Identifier = "NSSearchField_SearchTextBounds"
            public static let searchButtonBounds: AttributesSection.Identifier = "NSSearchField_SearchButtonBounds"
            public static let cancelButtonBounds: AttributesSection.Identifier = "NSSearchField_CancelButtonBounds"
            public static let searchMenuTemplate: AttributesSection.Identifier = "NSSearchField_SearchMenuTemplate"
            public static let behavior: AttributesSection.Identifier = "NSSearchField_Behavior"
            public static let maximumRecents: AttributesSection.Identifier = "NSSearchField_MaximumRecents"
        }

        public enum NSComboButton {
            public static let title: AttributesSection.Identifier = "NSComboButton_Title"
            public static let image: AttributesSection.Identifier = "NSComboButton_Image"
            public static let imageScaling: AttributesSection.Identifier = "NSComboButton_ImageScaling"
            public static let menu: AttributesSection.Identifier = "NSComboButton_Menu"
            public static let style: AttributesSection.Identifier = "NSComboButton_Style"
        }

        public enum NSGlassEffectView {
            public static let cornerRadius: AttributesSection.Identifier = "NSGlassEffectView_CornerRadius"
            public static let tintColor: AttributesSection.Identifier = "NSGlassEffectView_TintColor"
            public static let style: AttributesSection.Identifier = "NSGlassEffectView_Style"
            public static let effectIsInteractive: AttributesSection.Identifier = "NSGlassEffectView_EffectIsInteractive"
            public static let nsGlassEffectContainerView: AttributesSection.Identifier = "NSGlassEffectView_NSGlassEffectContainerView"
        }

        public enum NSBackgroundExtensionView {
            public static let automaticallyPlacesContentView: AttributesSection.Identifier = "NSBackgroundExtensionView_AutomaticallyPlacesContentView"
        }

        public enum NSRulerView {
            public static let orientation: AttributesSection.Identifier = "NSRulerView_Orientation"
            public static let baselineLocation: AttributesSection.Identifier = "NSRulerView_BaselineLocation"
            public static let requiredThickness: AttributesSection.Identifier = "NSRulerView_RequiredThickness"
            public static let ruleThickness: AttributesSection.Identifier = "NSRulerView_RuleThickness"
            public static let reservedThicknessForMarkers: AttributesSection.Identifier = "NSRulerView_ReservedThicknessForMarkers"
            public static let reservedThicknessForAccessoryView: AttributesSection.Identifier = "NSRulerView_ReservedThicknessForAccessoryView"
            public static let measurementUnits: AttributesSection.Identifier = "NSRulerView_MeasurementUnits"
            public static let originOffset: AttributesSection.Identifier = "NSRulerView_OriginOffset"
            public static let flipped: AttributesSection.Identifier = "NSRulerView_Flipped"
        }

        public enum NSTableCellView {
            public static let backgroundStyle: AttributesSection.Identifier = "NSTableCellView_BackgroundStyle"
            public static let rowSizeStyle: AttributesSection.Identifier = "NSTableCellView_RowSizeStyle"
        }

        public enum NSTableRowView {
            public static let selectionHighlightStyle: AttributesSection.Identifier = "NSTableRowView_SelectionHighlightStyle"
            public static let behavior: AttributesSection.Identifier = "NSTableRowView_Behavior"
            public static let draggingDestinationFeedbackStyle: AttributesSection.Identifier = "NSTableRowView_DraggingDestinationFeedbackStyle"
            public static let indentationForDropOperation: AttributesSection.Identifier = "NSTableRowView_IndentationForDropOperation"
            public static let interiorBackgroundStyle: AttributesSection.Identifier = "NSTableRowView_InteriorBackgroundStyle"
            public static let backgroundColor: AttributesSection.Identifier = "NSTableRowView_BackgroundColor"
            public static let numberOfColumns: AttributesSection.Identifier = "NSTableRowView_NumberOfColumns"
        }

        public enum NSTableHeaderView {
            public static let draggedColumn: AttributesSection.Identifier = "NSTableHeaderView_DraggedColumn"
            public static let draggedDistance: AttributesSection.Identifier = "NSTableHeaderView_DraggedDistance"
            public static let resizedColumn: AttributesSection.Identifier = "NSTableHeaderView_ResizedColumn"
        }

        public enum NSTextInsertionIndicator {
            public static let displayMode: AttributesSection.Identifier = "NSTextInsertionIndicator_DisplayMode"
            public static let color: AttributesSection.Identifier = "NSTextInsertionIndicator_Color"
            public static let automaticModeOptions: AttributesSection.Identifier = "NSTextInsertionIndicator_AutomaticModeOptions"
        }

        public enum NSView {
            public static let behavior: AttributesSection.Identifier = "NSView_Behavior"
            public static let alignmentRectInsets: AttributesSection.Identifier = "NSView_AlignmentRectInsets"
            public static let autoresizingMask: AttributesSection.Identifier = "NSView_AutoresizingMask"
            public static let frameRotation: AttributesSection.Identifier = "NSView_FrameRotation"
            public static let frameCenterRotation: AttributesSection.Identifier = "NSView_FrameCenterRotation"
            public static let boundsRotation: AttributesSection.Identifier = "NSView_BoundsRotation"
            public static let visibleRect: AttributesSection.Identifier = "NSView_VisibleRect"
            public static let layerContentsRedrawPolicy: AttributesSection.Identifier = "NSView_LayerContentsRedrawPolicy"
            public static let layerContentsPlacement: AttributesSection.Identifier = "NSView_LayerContentsPlacement"
            public static let compositingFilter: AttributesSection.Identifier = "NSView_CompositingFilter"
            public static let shadow: AttributesSection.Identifier = "NSView_Shadow"
            public static let toolTip: AttributesSection.Identifier = "NSView_ToolTip"
            public static let userInterfaceLayoutDirection: AttributesSection.Identifier = "NSView_UserInterfaceLayoutDirection"
            public static let preparedContentRect: AttributesSection.Identifier = "NSView_PreparedContentRect"
            public static let focusRingType: AttributesSection.Identifier = "NSView_FocusRingType"
            public static let focusRingMaskBounds: AttributesSection.Identifier = "NSView_FocusRingMaskBounds"
            public static let exclusiveGestureBehavior: AttributesSection.Identifier = "NSView_ExclusiveGestureBehavior"
            public static let allowedTouchTypes: AttributesSection.Identifier = "NSView_AllowedTouchTypes"
            public static let additionalSafeAreaInsets: AttributesSection.Identifier = "NSView_AdditionalSafeAreaInsets"
            public static let safeAreaRect: AttributesSection.Identifier = "NSView_SafeAreaRect"
        }

        public enum CALayer {
            public static let zPosition: AttributesSection.Identifier = "CALayer_ZPosition"
            public static let anchorPointZ: AttributesSection.Identifier = "CALayer_AnchorPointZ"
            public static let transform: AttributesSection.Identifier = "CALayer_Transform"
            public static let behavior: AttributesSection.Identifier = "CALayer_Behavior"
            public static let sublayerTransform: AttributesSection.Identifier = "CALayer_SublayerTransform"
            public static let contentsRect: AttributesSection.Identifier = "CALayer_ContentsRect"
            public static let contentsGravity: AttributesSection.Identifier = "CALayer_ContentsGravity"
            public static let contentsScale: AttributesSection.Identifier = "CALayer_ContentsScale"
            public static let contentsCenter: AttributesSection.Identifier = "CALayer_ContentsCenter"
            public static let contentsFormat: AttributesSection.Identifier = "CALayer_ContentsFormat"
            public static let toneMapMode: AttributesSection.Identifier = "CALayer_ToneMapMode"
            public static let preferredDynamicRange: AttributesSection.Identifier = "CALayer_PreferredDynamicRange"
            public static let contentsHeadroom: AttributesSection.Identifier = "CALayer_ContentsHeadroom"
            public static let minificationFilter: AttributesSection.Identifier = "CALayer_MinificationFilter"
            public static let magnificationFilter: AttributesSection.Identifier = "CALayer_MagnificationFilter"
            public static let minificationFilterBias: AttributesSection.Identifier = "CALayer_MinificationFilterBias"
            public static let maskedCorners: AttributesSection.Identifier = "CALayer_MaskedCorners"
            public static let cornerCurve: AttributesSection.Identifier = "CALayer_CornerCurve"
            public static let rasterizationScale: AttributesSection.Identifier = "CALayer_RasterizationScale"
            public static let shadowPath: AttributesSection.Identifier = "CALayer_ShadowPath"
            public static let name: AttributesSection.Identifier = "CALayer_Name"
            public static let visibleRect: AttributesSection.Identifier = "CALayer_VisibleRect"
            public static let caShapeLayer: AttributesSection.Identifier = "CALayer_CAShapeLayer"
            public static let caGradientLayer: AttributesSection.Identifier = "CALayer_CAGradientLayer"
            public static let caTextLayer: AttributesSection.Identifier = "CALayer_CATextLayer"
            public static let caReplicatorLayer: AttributesSection.Identifier = "CALayer_CAReplicatorLayer"
            public static let caEmitterLayer: AttributesSection.Identifier = "CALayer_CAEmitterLayer"
            public static let caScrollLayer: AttributesSection.Identifier = "CALayer_CAScrollLayer"
            public static let caTiledLayer: AttributesSection.Identifier = "CALayer_CATiledLayer"
        }
    }

    // MARK: - Attributes

    extension InspectedAttribute.Identifier {
        public static let unspecified: Self = "n"
        /// Attributes an app adds through LookinServer's custom attributes.
        public static let userCustom: Self = "ctm"

        public enum Class {
            public enum Class {
                public static let `class`: InspectedAttribute.Identifier = "c_c_c"
                /// The images the classes of InspectedAttribute.Identifier.Class.Class.class come from, one path per
                /// class name, in the same nested order. Only sent to Hosts that ask for it
                /// (LookinStaticAsyncUpdateTask.wantsClassImagePaths).
                public static let imagePaths: InspectedAttribute.Identifier = "c_c_ip"
            }
        }

        public enum Relation {
            public enum Relation {
                public static let relation: InspectedAttribute.Identifier = "r_r_r"
            }
        }

        public enum Layout {
            public enum Frame {
                public static let frame: InspectedAttribute.Identifier = "l_f_f"
            }

            public enum Bounds {
                public static let bounds: InspectedAttribute.Identifier = "l_b_b"
            }

            public enum SafeArea {
                public static let safeArea: InspectedAttribute.Identifier = "l_s_s"
            }

            public enum Position {
                public static let position: InspectedAttribute.Identifier = "l_p_p"
            }

            public enum AnchorPoint {
                public static let anchorPoint: InspectedAttribute.Identifier = "l_a_a"
            }

            public enum CoordinateSpace {
                /// Only used by UIWindowScene, which has no frame of its own.
                public static let coordinateSpace: InspectedAttribute.Identifier = "l_c_c"
            }
        }

        public enum AutoLayout {
            public enum Hugging {
                public static let horizontal: InspectedAttribute.Identifier = "al_h_h"
                public static let vertical: InspectedAttribute.Identifier = "al_h_v"
            }

            public enum Resistance {
                public static let horizontal: InspectedAttribute.Identifier = "al_r_h"
                public static let vertical: InspectedAttribute.Identifier = "al_r_v"
            }

            public enum Constraints {
                public static let constraints: InspectedAttribute.Identifier = "al_c_c"
            }

            public enum IntrinsicSize {
                public static let size: InspectedAttribute.Identifier = "cl_i_s"
            }
        }

        public enum ViewLayer {
            public enum Visibility {
                public static let hidden: InspectedAttribute.Identifier = "vl_v_h"
                public static let opacity: InspectedAttribute.Identifier = "vl_v_o"
            }

            public enum InteractionAndMasks {
                public static let interaction: InspectedAttribute.Identifier = "vl_i_i"
                public static let masksToBounds: InspectedAttribute.Identifier = "vl_i_m"
            }

            public enum Corner {
                public static let radius: InspectedAttribute.Identifier = "vl_c_r"
            }

            public enum BackgroundColor {
                public static let backgroundColor: InspectedAttribute.Identifier = "vl_b_b"
            }

            public enum Border {
                public static let color: InspectedAttribute.Identifier = "vl_b_c"
                public static let width: InspectedAttribute.Identifier = "vl_b_w"
            }

            public enum Shadow {
                public static let color: InspectedAttribute.Identifier = "vl_s_c"
                public static let opacity: InspectedAttribute.Identifier = "vl_s_o"
                public static let radius: InspectedAttribute.Identifier = "vl_s_r"
                public static let offsetWidth: InspectedAttribute.Identifier = "vl_s_ow"
                public static let offsetHeight: InspectedAttribute.Identifier = "vl_s_oh"
            }

            public enum ContentMode {
                public static let mode: InspectedAttribute.Identifier = "vl_c_m"
            }

            public enum TintColor {
                public static let color: InspectedAttribute.Identifier = "vl_t_c"
                public static let mode: InspectedAttribute.Identifier = "vl_t_m"
            }

            public enum Tag {
                public static let tag: InspectedAttribute.Identifier = "vl_t_t"
            }
        }

        public enum UIImageView {
            public enum Name {
                public static let name: InspectedAttribute.Identifier = "iv_n_n"
            }

            public enum Open {
                public static let open: InspectedAttribute.Identifier = "iv_o_o"
            }

            public enum HighlightedImage {
                public static let highlightedImage: InspectedAttribute.Identifier = "UIImageView_HighlightedImage_HighlightedImage"
            }

            public enum PreferredSymbolConfiguration {
                public static let preferredSymbolConfiguration: InspectedAttribute.Identifier = "UIImageView_PreferredSymbolConfiguration_PreferredSymbolConfiguration"
            }

            public enum Behavior {
                public static let highlighted: InspectedAttribute.Identifier = "UIImageView_Behavior_Highlighted"
                public static let animating: InspectedAttribute.Identifier = "UIImageView_Behavior_Animating"
            }

            public enum AnimationImages {
                public static let animationImages: InspectedAttribute.Identifier = "UIImageView_AnimationImages_AnimationImages"
            }

            public enum HighlightedAnimationImages {
                public static let highlightedAnimationImages: InspectedAttribute.Identifier = "UIImageView_HighlightedAnimationImages_HighlightedAnimationImages"
            }

            public enum AnimationDuration {
                public static let animationDuration: InspectedAttribute.Identifier = "UIImageView_AnimationDuration_AnimationDuration"
            }

            public enum AnimationRepeatCount {
                public static let animationRepeatCount: InspectedAttribute.Identifier = "UIImageView_AnimationRepeatCount_AnimationRepeatCount"
            }

            public enum PreferredImageDynamicRange {
                public static let preferredImageDynamicRange: InspectedAttribute.Identifier = "UIImageView_PreferredImageDynamicRange_PreferredImageDynamicRange"
            }

            public enum ImageDynamicRange {
                public static let imageDynamicRange: InspectedAttribute.Identifier = "UIImageView_ImageDynamicRange_ImageDynamicRange"
            }
        }

        public enum UILabel {
            public enum Text {
                public static let text: InspectedAttribute.Identifier = "lb_t_t"
            }

            public enum Font {
                public static let name: InspectedAttribute.Identifier = "lb_f_n"
                public static let size: InspectedAttribute.Identifier = "lb_f_s"
            }

            public enum NumberOfLines {
                public static let numberOfLines: InspectedAttribute.Identifier = "lb_n_n"
            }

            public enum TextColor {
                public static let color: InspectedAttribute.Identifier = "lb_t_c"
            }

            public enum Alignment {
                public static let alignment: InspectedAttribute.Identifier = "lb_a_a"
            }

            public enum BreakMode {
                public static let mode: InspectedAttribute.Identifier = "lb_b_m"
            }

            public enum CanAdjustFont {
                public static let canAdjustFont: InspectedAttribute.Identifier = "lb_c_c"
            }

            public enum PreferredVibrancy {
                public static let preferredVibrancy: InspectedAttribute.Identifier = "UILabel_PreferredVibrancy_PreferredVibrancy"
            }

            public enum Colors {
                public static let shadowColor: InspectedAttribute.Identifier = "UILabel_Colors_ShadowColor"
                public static let highlightedTextColor: InspectedAttribute.Identifier = "UILabel_Colors_HighlightedTextColor"
            }

            public enum ShadowOffset {
                public static let shadowOffset: InspectedAttribute.Identifier = "UILabel_ShadowOffset_ShadowOffset"
            }

            public enum Behavior {
                public static let highlighted: InspectedAttribute.Identifier = "UILabel_Behavior_Highlighted"
                public static let enabled: InspectedAttribute.Identifier = "UILabel_Behavior_Enabled"
                public static let allowsDefaultTighteningForTruncation: InspectedAttribute.Identifier = "UILabel_Behavior_AllowsDefaultTighteningForTruncation"
                public static let showsExpansionTextWhenTruncated: InspectedAttribute.Identifier = "UILabel_Behavior_ShowsExpansionTextWhenTruncated"
            }

            public enum BaselineAdjustment {
                public static let baselineAdjustment: InspectedAttribute.Identifier = "UILabel_BaselineAdjustment_BaselineAdjustment"
            }

            public enum MinimumScaleFactor {
                public static let minimumScaleFactor: InspectedAttribute.Identifier = "UILabel_MinimumScaleFactor_MinimumScaleFactor"
            }

            public enum LineBreakStrategy {
                public static let lineBreakStrategy: InspectedAttribute.Identifier = "UILabel_LineBreakStrategy_LineBreakStrategy"
            }

            public enum PreferredMaxLayoutWidth {
                public static let preferredMaxLayoutWidth: InspectedAttribute.Identifier = "UILabel_PreferredMaxLayoutWidth_PreferredMaxLayoutWidth"
            }
        }

        public enum UIControl {
            public enum EnabledSelected {
                public static let enabled: InspectedAttribute.Identifier = "ct_e_e"
                public static let selected: InspectedAttribute.Identifier = "ct_e_s"
            }

            public enum VerAlignment {
                public static let alignment: InspectedAttribute.Identifier = "ct_v_a"
            }

            public enum HorAlignment {
                public static let alignment: InspectedAttribute.Identifier = "ct_h_a"
            }

            public enum QMUIOutsideEdge {
                public static let edge: InspectedAttribute.Identifier = "ct_o_e"
            }

            public enum Behavior {
                public static let highlighted: InspectedAttribute.Identifier = "UIControl_Behavior_Highlighted"
                public static let tracking: InspectedAttribute.Identifier = "UIControl_Behavior_Tracking"
                public static let touchInside: InspectedAttribute.Identifier = "UIControl_Behavior_TouchInside"
                public static let contextMenuInteractionEnabled: InspectedAttribute.Identifier = "UIControl_Behavior_ContextMenuInteractionEnabled"
                public static let showsMenuAsPrimaryAction: InspectedAttribute.Identifier = "UIControl_Behavior_ShowsMenuAsPrimaryAction"
                public static let symbolAnimationEnabled: InspectedAttribute.Identifier = "UIControl_Behavior_SymbolAnimationEnabled"
            }

            public enum EffectiveContentHorizontalAlignment {
                public static let effectiveContentHorizontalAlignment: InspectedAttribute.Identifier = "UIControl_EffectiveContentHorizontalAlignment_EffectiveContentHorizontalAlignment"
            }

            public enum State {
                public static let state: InspectedAttribute.Identifier = "UIControl_State_State"
            }

            public enum AllControlEvents {
                public static let allControlEvents: InspectedAttribute.Identifier = "UIControl_AllControlEvents_AllControlEvents"
            }

            public enum ToolTip {
                public static let toolTip: InspectedAttribute.Identifier = "UIControl_ToolTip_ToolTip"
            }
        }

        public enum UIButton {
            public enum ContentInsets {
                public static let insets: InspectedAttribute.Identifier = "bt_c_i"
            }

            public enum TitleInsets {
                public static let insets: InspectedAttribute.Identifier = "bt_t_i"
            }

            public enum ImageInsets {
                public static let insets: InspectedAttribute.Identifier = "bt_i_i"
            }

            public enum BehavioralStyle {
                public static let behavioralStyle: InspectedAttribute.Identifier = "UIButton_BehavioralStyle_BehavioralStyle"
            }

            public enum PreferredBehavioralStyle {
                public static let preferredBehavioralStyle: InspectedAttribute.Identifier = "UIButton_PreferredBehavioralStyle_PreferredBehavioralStyle"
            }

            public enum Configuration {
                public static let configuration: InspectedAttribute.Identifier = "UIButton_Configuration_Configuration"
            }

            public enum Behavior {
                public static let automaticallyUpdatesConfiguration: InspectedAttribute.Identifier = "UIButton_Behavior_AutomaticallyUpdatesConfiguration"
                public static let hovered: InspectedAttribute.Identifier = "UIButton_Behavior_Hovered"
                public static let held: InspectedAttribute.Identifier = "UIButton_Behavior_Held"
                public static let pointerInteractionEnabled: InspectedAttribute.Identifier = "UIButton_Behavior_PointerInteractionEnabled"
                public static let changesSelectionAsPrimaryAction: InspectedAttribute.Identifier = "UIButton_Behavior_ChangesSelectionAsPrimaryAction"
            }

            public enum ButtonType {
                public static let buttonType: InspectedAttribute.Identifier = "UIButton_ButtonType_ButtonType"
            }

            public enum Role {
                public static let role: InspectedAttribute.Identifier = "UIButton_Role_Role"
            }

            public enum Menu {
                public static let menu: InspectedAttribute.Identifier = "UIButton_Menu_Menu"
            }

            public enum CurrentTitle {
                public static let currentTitle: InspectedAttribute.Identifier = "UIButton_CurrentTitle_CurrentTitle"
            }

            public enum Colors {
                public static let currentTitleColor: InspectedAttribute.Identifier = "UIButton_Colors_CurrentTitleColor"
                public static let currentTitleShadowColor: InspectedAttribute.Identifier = "UIButton_Colors_CurrentTitleShadowColor"
            }

            public enum Images {
                public static let currentImage: InspectedAttribute.Identifier = "UIButton_Images_CurrentImage"
                public static let currentBackgroundImage: InspectedAttribute.Identifier = "UIButton_Images_CurrentBackgroundImage"
            }

            public enum CurrentPreferredSymbolConfiguration {
                public static let currentPreferredSymbolConfiguration: InspectedAttribute.Identifier = "UIButton_CurrentPreferredSymbolConfiguration_CurrentPreferredSymbolConfiguration"
            }
        }

        public enum UIScrollView {
            public enum Offset {
                public static let offset: InspectedAttribute.Identifier = "sv_o_o"
            }

            public enum ContentSize {
                public static let size: InspectedAttribute.Identifier = "sv_c_s"
            }

            public enum ContentInset {
                public static let inset: InspectedAttribute.Identifier = "sv_c_i"
            }

            public enum AdjustedInset {
                public static let inset: InspectedAttribute.Identifier = "sv_a_i"
            }

            public enum Behavior {
                public static let behavior: InspectedAttribute.Identifier = "sv_b_b"
            }

            public enum IndicatorInset {
                public static let inset: InspectedAttribute.Identifier = "sv_i_i"
            }

            public enum ScrollPaging {
                public static let scrollEnabled: InspectedAttribute.Identifier = "sv_s_s"
                public static let pagingEnabled: InspectedAttribute.Identifier = "sv_s_p"
            }

            public enum Bounce {
                public static let vertical: InspectedAttribute.Identifier = "sv_b_v"
                public static let horizontal: InspectedAttribute.Identifier = "sv_b_h"
            }

            public enum ShowsIndicator {
                public static let horizontal: InspectedAttribute.Identifier = "sv_h_h"
                public static let vertical: InspectedAttribute.Identifier = "sv_s_v"
            }

            public enum ContentTouches {
                public static let delay: InspectedAttribute.Identifier = "sv_c_d"
                public static let canCancel: InspectedAttribute.Identifier = "sv_c_c"
            }

            public enum Zoom {
                public static let minScale: InspectedAttribute.Identifier = "sv_z_mi"
                public static let maxScale: InspectedAttribute.Identifier = "sv_z_ma"
                public static let scale: InspectedAttribute.Identifier = "sv_z_s"
                public static let bounce: InspectedAttribute.Identifier = "sv_z_b"
            }

            public enum QMUIInitialInset {
                public static let inset: InspectedAttribute.Identifier = "sv_qi_i"
            }

            public enum ContentAlignmentPoint {
                public static let contentAlignmentPoint: InspectedAttribute.Identifier = "UIScrollView_ContentAlignmentPoint_ContentAlignmentPoint"
            }

            public enum Flags {
                public static let automaticallyAdjustsScrollIndicatorInsets: InspectedAttribute.Identifier = "UIScrollView_Flags_AutomaticallyAdjustsScrollIndicatorInsets"
                public static let directionalLockEnabled: InspectedAttribute.Identifier = "UIScrollView_Flags_DirectionalLockEnabled"
                public static let bounces: InspectedAttribute.Identifier = "UIScrollView_Flags_Bounces"
                public static let bouncesHorizontally: InspectedAttribute.Identifier = "UIScrollView_Flags_BouncesHorizontally"
                public static let bouncesVertically: InspectedAttribute.Identifier = "UIScrollView_Flags_BouncesVertically"
                public static let transfersHorizontalScrollingToParent: InspectedAttribute.Identifier = "UIScrollView_Flags_TransfersHorizontalScrollingToParent"
                public static let transfersVerticalScrollingToParent: InspectedAttribute.Identifier = "UIScrollView_Flags_TransfersVerticalScrollingToParent"
                public static let tracking: InspectedAttribute.Identifier = "UIScrollView_Flags_Tracking"
                public static let dragging: InspectedAttribute.Identifier = "UIScrollView_Flags_Dragging"
                public static let decelerating: InspectedAttribute.Identifier = "UIScrollView_Flags_Decelerating"
                public static let scrollAnimating: InspectedAttribute.Identifier = "UIScrollView_Flags_ScrollAnimating"
                public static let zooming: InspectedAttribute.Identifier = "UIScrollView_Flags_Zooming"
                public static let zoomBouncing: InspectedAttribute.Identifier = "UIScrollView_Flags_ZoomBouncing"
                public static let zoomAnimating: InspectedAttribute.Identifier = "UIScrollView_Flags_ZoomAnimating"
                public static let scrollsToTop: InspectedAttribute.Identifier = "UIScrollView_Flags_ScrollsToTop"
                public static let allowsKeyboardScrolling: InspectedAttribute.Identifier = "UIScrollView_Flags_AllowsKeyboardScrolling"
            }

            public enum IndicatorStyle {
                public static let indicatorStyle: InspectedAttribute.Identifier = "UIScrollView_IndicatorStyle_IndicatorStyle"
            }

            public enum VerticalScrollIndicatorInsets {
                public static let verticalScrollIndicatorInsets: InspectedAttribute.Identifier = "UIScrollView_VerticalScrollIndicatorInsets_VerticalScrollIndicatorInsets"
            }

            public enum HorizontalScrollIndicatorInsets {
                public static let horizontalScrollIndicatorInsets: InspectedAttribute.Identifier = "UIScrollView_HorizontalScrollIndicatorInsets_HorizontalScrollIndicatorInsets"
            }

            public enum DecelerationRate {
                public static let decelerationRate: InspectedAttribute.Identifier = "UIScrollView_DecelerationRate_DecelerationRate"
            }

            public enum IndexDisplayMode {
                public static let indexDisplayMode: InspectedAttribute.Identifier = "UIScrollView_IndexDisplayMode_IndexDisplayMode"
            }

            public enum KeyboardDismissMode {
                public static let keyboardDismissMode: InspectedAttribute.Identifier = "UIScrollView_KeyboardDismissMode_KeyboardDismissMode"
            }
        }

        public enum UITableView {
            public enum Style {
                public static let style: InspectedAttribute.Identifier = "tv_s_s"
            }

            public enum SectionsNumber {
                public static let number: InspectedAttribute.Identifier = "tv_s_n"
            }

            public enum RowsNumber {
                public static let number: InspectedAttribute.Identifier = "tv_r_n"
            }

            public enum SeparatorInset {
                public static let inset: InspectedAttribute.Identifier = "tv_s_i"
            }

            public enum SeparatorColor {
                public static let color: InspectedAttribute.Identifier = "tv_s_c"
            }

            public enum SeparatorStyle {
                public static let style: InspectedAttribute.Identifier = "tv_ss_s"
            }

            public enum Behavior {
                public static let prefetchingEnabled: InspectedAttribute.Identifier = "UITableView_Behavior_PrefetchingEnabled"
                public static let hasUncommittedUpdates: InspectedAttribute.Identifier = "UITableView_Behavior_HasUncommittedUpdates"
                public static let editing: InspectedAttribute.Identifier = "UITableView_Behavior_Editing"
                public static let allowsSelection: InspectedAttribute.Identifier = "UITableView_Behavior_AllowsSelection"
                public static let allowsSelectionDuringEditing: InspectedAttribute.Identifier = "UITableView_Behavior_AllowsSelectionDuringEditing"
                public static let allowsMultipleSelection: InspectedAttribute.Identifier = "UITableView_Behavior_AllowsMultipleSelection"
                public static let allowsMultipleSelectionDuringEditing: InspectedAttribute.Identifier = "UITableView_Behavior_AllowsMultipleSelectionDuringEditing"
                public static let cellLayoutMarginsFollowReadableWidth: InspectedAttribute.Identifier = "UITableView_Behavior_CellLayoutMarginsFollowReadableWidth"
                public static let insetsContentViewsToSafeArea: InspectedAttribute.Identifier = "UITableView_Behavior_InsetsContentViewsToSafeArea"
                public static let remembersLastFocusedIndexPath: InspectedAttribute.Identifier = "UITableView_Behavior_RemembersLastFocusedIndexPath"
                public static let selectionFollowsFocus: InspectedAttribute.Identifier = "UITableView_Behavior_SelectionFollowsFocus"
                public static let allowsFocus: InspectedAttribute.Identifier = "UITableView_Behavior_AllowsFocus"
                public static let allowsFocusDuringEditing: InspectedAttribute.Identifier = "UITableView_Behavior_AllowsFocusDuringEditing"
                public static let dragInteractionEnabled: InspectedAttribute.Identifier = "UITableView_Behavior_DragInteractionEnabled"
                public static let hasActiveDrag: InspectedAttribute.Identifier = "UITableView_Behavior_HasActiveDrag"
                public static let hasActiveDrop: InspectedAttribute.Identifier = "UITableView_Behavior_HasActiveDrop"
            }

            public enum RowHeight {
                public static let rowHeight: InspectedAttribute.Identifier = "UITableView_RowHeight_RowHeight"
            }

            public enum SectionHeaderHeight {
                public static let sectionHeaderHeight: InspectedAttribute.Identifier = "UITableView_SectionHeaderHeight_SectionHeaderHeight"
            }

            public enum SectionFooterHeight {
                public static let sectionFooterHeight: InspectedAttribute.Identifier = "UITableView_SectionFooterHeight_SectionFooterHeight"
            }

            public enum EstimatedRowHeight {
                public static let estimatedRowHeight: InspectedAttribute.Identifier = "UITableView_EstimatedRowHeight_EstimatedRowHeight"
            }

            public enum EstimatedSectionHeaderHeight {
                public static let estimatedSectionHeaderHeight: InspectedAttribute.Identifier = "UITableView_EstimatedSectionHeaderHeight_EstimatedSectionHeaderHeight"
            }

            public enum EstimatedSectionFooterHeight {
                public static let estimatedSectionFooterHeight: InspectedAttribute.Identifier = "UITableView_EstimatedSectionFooterHeight_EstimatedSectionFooterHeight"
            }

            public enum FillerRowHeight {
                public static let fillerRowHeight: InspectedAttribute.Identifier = "UITableView_FillerRowHeight_FillerRowHeight"
            }

            public enum SectionHeaderTopPadding {
                public static let sectionHeaderTopPadding: InspectedAttribute.Identifier = "UITableView_SectionHeaderTopPadding_SectionHeaderTopPadding"
            }

            public enum SeparatorInsetReference {
                public static let separatorInsetReference: InspectedAttribute.Identifier = "UITableView_SeparatorInsetReference_SeparatorInsetReference"
            }

            public enum SelfSizingInvalidation {
                public static let selfSizingInvalidation: InspectedAttribute.Identifier = "UITableView_SelfSizingInvalidation_SelfSizingInvalidation"
            }

            public enum IndexPathsForSelectedRows {
                public static let indexPathsForSelectedRows: InspectedAttribute.Identifier = "UITableView_IndexPathsForSelectedRows_IndexPathsForSelectedRows"
            }

            public enum SectionIndexMinimumDisplayRowCount {
                public static let sectionIndexMinimumDisplayRowCount: InspectedAttribute.Identifier = "UITableView_SectionIndexMinimumDisplayRowCount_SectionIndexMinimumDisplayRowCount"
            }

            public enum Colors {
                public static let sectionIndexColor: InspectedAttribute.Identifier = "UITableView_Colors_SectionIndexColor"
                public static let sectionIndexBackgroundColor: InspectedAttribute.Identifier = "UITableView_Colors_SectionIndexBackgroundColor"
                public static let sectionIndexTrackingBackgroundColor: InspectedAttribute.Identifier = "UITableView_Colors_SectionIndexTrackingBackgroundColor"
            }

            public enum SeparatorEffect {
                public static let separatorEffect: InspectedAttribute.Identifier = "UITableView_SeparatorEffect_SeparatorEffect"
            }

            public enum ContentHuggingElements {
                public static let contentHuggingElements: InspectedAttribute.Identifier = "UITableView_ContentHuggingElements_ContentHuggingElements"
            }
        }

        public enum UITextView {
            public enum Font {
                public static let name: InspectedAttribute.Identifier = "te_f_n"
                public static let size: InspectedAttribute.Identifier = "te_f_s"
            }

            public enum Basic {
                public static let editable: InspectedAttribute.Identifier = "te_b_e"
                public static let selectable: InspectedAttribute.Identifier = "te_b_s"
            }

            public enum Text {
                public static let text: InspectedAttribute.Identifier = "te_t_t"
            }

            public enum TextColor {
                public static let color: InspectedAttribute.Identifier = "te_t_c"
            }

            public enum Alignment {
                public static let alignment: InspectedAttribute.Identifier = "te_a_a"
            }

            public enum ContainerInset {
                public static let inset: InspectedAttribute.Identifier = "te_c_i"
            }

            public enum DataDetectorTypes {
                public static let dataDetectorTypes: InspectedAttribute.Identifier = "UITextView_DataDetectorTypes_DataDetectorTypes"
            }

            public enum Behavior {
                public static let allowsEditingTextAttributes: InspectedAttribute.Identifier = "UITextView_Behavior_AllowsEditingTextAttributes"
                public static let clearsOnInsertion: InspectedAttribute.Identifier = "UITextView_Behavior_ClearsOnInsertion"
                public static let usesStandardTextScaling: InspectedAttribute.Identifier = "UITextView_Behavior_UsesStandardTextScaling"
                public static let findInteractionEnabled: InspectedAttribute.Identifier = "UITextView_Behavior_FindInteractionEnabled"
                public static let writingToolsActive: InspectedAttribute.Identifier = "UITextView_Behavior_WritingToolsActive"
            }

            public enum BorderStyle {
                public static let borderStyle: InspectedAttribute.Identifier = "UITextView_BorderStyle_BorderStyle"
            }

            public enum WritingToolsBehavior {
                public static let writingToolsBehavior: InspectedAttribute.Identifier = "UITextView_WritingToolsBehavior_WritingToolsBehavior"
            }

            public enum AllowedWritingToolsResultOptions {
                public static let allowedWritingToolsResultOptions: InspectedAttribute.Identifier = "UITextView_AllowedWritingToolsResultOptions_AllowedWritingToolsResultOptions"
            }
        }

        public enum UITextField {
            public enum Text {
                public static let text: InspectedAttribute.Identifier = "tf_t_t"
            }

            public enum Placeholder {
                public static let placeholder: InspectedAttribute.Identifier = "tf_p_p"
            }

            public enum Font {
                public static let name: InspectedAttribute.Identifier = "tf_f_n"
                public static let size: InspectedAttribute.Identifier = "tf_f_s"
            }

            public enum TextColor {
                public static let color: InspectedAttribute.Identifier = "tf_t_c"
            }

            public enum Alignment {
                public static let alignment: InspectedAttribute.Identifier = "tf_a_a"
            }

            public enum Clears {
                public static let clearsOnBeginEditing: InspectedAttribute.Identifier = "tf_c_c"
                public static let clearsOnInsertion: InspectedAttribute.Identifier = "tf_c_co"
            }

            public enum CanAdjustFont {
                public static let canAdjustFont: InspectedAttribute.Identifier = "tf_c_ca"
                public static let minSize: InspectedAttribute.Identifier = "tf_c_m"
            }

            public enum ClearButtonMode {
                public static let mode: InspectedAttribute.Identifier = "tf_cb_m"
            }

            public enum UISearchTextField {
                public static let tokens: InspectedAttribute.Identifier = "UITextField_UISearchTextField_Tokens"
                public static let tokenBackgroundColor: InspectedAttribute.Identifier = "UITextField_UISearchTextField_TokenBackgroundColor"
                public static let allowsDeletingTokens: InspectedAttribute.Identifier = "UITextField_UISearchTextField_AllowsDeletingTokens"
                public static let allowsCopyingTokens: InspectedAttribute.Identifier = "UITextField_UISearchTextField_AllowsCopyingTokens"
                public static let searchSuggestions: InspectedAttribute.Identifier = "UITextField_UISearchTextField_SearchSuggestions"
            }

            public enum BorderStyle {
                public static let borderStyle: InspectedAttribute.Identifier = "UITextField_BorderStyle_BorderStyle"
            }

            public enum Images {
                public static let background: InspectedAttribute.Identifier = "UITextField_Images_Background"
                public static let disabledBackground: InspectedAttribute.Identifier = "UITextField_Images_DisabledBackground"
            }

            public enum Behavior {
                public static let editing: InspectedAttribute.Identifier = "UITextField_Behavior_Editing"
                public static let allowsEditingTextAttributes: InspectedAttribute.Identifier = "UITextField_Behavior_AllowsEditingTextAttributes"
            }

            public enum LeftViewMode {
                public static let leftViewMode: InspectedAttribute.Identifier = "UITextField_LeftViewMode_LeftViewMode"
            }

            public enum RightViewMode {
                public static let rightViewMode: InspectedAttribute.Identifier = "UITextField_RightViewMode_RightViewMode"
            }
        }

        public enum UIVisualEffectView {
            public enum Style {
                public static let style: InspectedAttribute.Identifier = "ve_s_s"
            }

            public enum QMUIForegroundColor {
                public static let color: InspectedAttribute.Identifier = "ve_f_c"
            }

            public enum Effect {
                public static let effect: InspectedAttribute.Identifier = "UIVisualEffectView_Effect_Effect"
            }
        }

        public enum UIStackView {
            public enum Axis {
                public static let axis: InspectedAttribute.Identifier = "usv_axis_axis"
            }

            public enum Distribution {
                public static let distribution: InspectedAttribute.Identifier = "usv_dis_dis"
            }

            public enum Alignment {
                public static let alignment: InspectedAttribute.Identifier = "usv_ali_ali"
            }

            public enum Spacing {
                public static let spacing: InspectedAttribute.Identifier = "usv_spa_spa"
            }

            public enum Behavior {
                public static let baselineRelativeArrangement: InspectedAttribute.Identifier = "UIStackView_Behavior_BaselineRelativeArrangement"
                public static let layoutMarginsRelativeArrangement: InspectedAttribute.Identifier = "UIStackView_Behavior_LayoutMarginsRelativeArrangement"
            }
        }

        public enum NSImageView {
            public enum Name {
                public static let name: InspectedAttribute.Identifier = "NSImageView_Name_Name"
            }

            public enum Open {
                public static let open: InspectedAttribute.Identifier = "NSImageView_Open_Open"
            }

            public enum Scaling {
                public static let imageScaling: InspectedAttribute.Identifier = "NSImageView_Scaling_ImageScaling"
                public static let imageAlignment: InspectedAttribute.Identifier = "NSImageView_Scaling_ImageAlignment"
                public static let imageFrameStyle: InspectedAttribute.Identifier = "NSImageView_Scaling_ImageFrameStyle"
            }

            public enum Behavior {
                public static let animates: InspectedAttribute.Identifier = "NSImageView_Behavior_Animates"
                public static let editable: InspectedAttribute.Identifier = "NSImageView_Behavior_Editable"
            }

            public enum ContentTintColor {
                public static let contentTintColor: InspectedAttribute.Identifier = "NSImageView_ContentTintColor_ContentTintColor"
            }

            public enum SymbolConfiguration {
                public static let symbolConfiguration: InspectedAttribute.Identifier = "NSImageView_SymbolConfiguration_SymbolConfiguration"
            }

            public enum AllowsCutCopyPaste {
                public static let allowsCutCopyPaste: InspectedAttribute.Identifier = "NSImageView_AllowsCutCopyPaste_AllowsCutCopyPaste"
            }

            public enum PreferredImageDynamicRange {
                public static let preferredImageDynamicRange: InspectedAttribute.Identifier = "NSImageView_PreferredImageDynamicRange_PreferredImageDynamicRange"
            }

            public enum ImageDynamicRange {
                public static let imageDynamicRange: InspectedAttribute.Identifier = "NSImageView_ImageDynamicRange_ImageDynamicRange"
            }
        }

        public enum NSControl {
            public enum State {
                public static let enabled: InspectedAttribute.Identifier = "NSControl_State_Enabled"
                public static let highlighted: InspectedAttribute.Identifier = "NSControl_State_Highlighted"
                public static let continuous: InspectedAttribute.Identifier = "NSControl_State_Continuous"
            }

            public enum ControlSize {
                public static let size: InspectedAttribute.Identifier = "NSControl_ControlSize_Size"
            }

            public enum Font {
                public static let name: InspectedAttribute.Identifier = "NSControl_Font_Name"
                public static let size: InspectedAttribute.Identifier = "NSControl_Font_Size"
            }

            public enum Alignment {
                public static let alignment: InspectedAttribute.Identifier = "NSControl_Alignment_Alignment"
            }

            public enum Miscellaneous {
                public static let writingDirection: InspectedAttribute.Identifier = "NSControl_Misc_WritingDirection"
                public static let ignoresMultiClick: InspectedAttribute.Identifier = "NSControl_Misc_IgnoresMultiClick"
                public static let usesSingleLineMode: InspectedAttribute.Identifier = "NSControl_Misc_UsesSingleLineMode"
                public static let allowsExpansionToolTips: InspectedAttribute.Identifier = "NSControl_Misc_AllowsExpansionToolTips"
            }

            public enum Value {
                public static let stringValue: InspectedAttribute.Identifier = "NSControl_Value_StringValue"
                public static let intValue: InspectedAttribute.Identifier = "NSControl_Value_IntValue"
                public static let integerValue: InspectedAttribute.Identifier = "NSControl_Value_IntegerValue"
                public static let floatValue: InspectedAttribute.Identifier = "NSControl_Value_FloatValue"
                public static let doubleValue: InspectedAttribute.Identifier = "NSControl_Value_DoubleValue"
            }

            public enum Tag {
                public static let tag: InspectedAttribute.Identifier = "NSControl_Tag_Tag"
            }

            public enum RefusesFirstResponder {
                public static let refusesFirstResponder: InspectedAttribute.Identifier = "NSControl_RefusesFirstResponder_RefusesFirstResponder"
            }

            public enum LineBreakMode {
                public static let lineBreakMode: InspectedAttribute.Identifier = "NSControl_LineBreakMode_LineBreakMode"
            }
        }

        public enum NSButton {
            public enum ButtonType {
                public static let buttonType: InspectedAttribute.Identifier = "NSButton_ButtonType_ButtonType"
            }

            public enum Title {
                public static let title: InspectedAttribute.Identifier = "NSButton_Title_Title"
                public static let alernateTitle: InspectedAttribute.Identifier = "NSButton_Title_AlernateTitle"
            }

            public enum BezelStyle {
                public static let bezelStyle: InspectedAttribute.Identifier = "NSButton_BezelStyle_BezelStyle"
            }

            public enum Bordered {
                public static let bordered: InspectedAttribute.Identifier = "NSButton_Bordered_Bordered"
            }

            public enum Transparent {
                public static let transparent: InspectedAttribute.Identifier = "NSButton_Transparent_Transparent"
            }

            public enum BezelColor {
                public static let bezelColor: InspectedAttribute.Identifier = "NSButton_BezelColor_BezelColor"
            }

            public enum ContentTintColor {
                public static let contentTintColor: InspectedAttribute.Identifier = "NSButton_ContentTintColor_ContentTintColor"
            }

            public enum Miscellaneous {
                public static let showsBorderOnlyWhileMouseInside: InspectedAttribute.Identifier = "NSButton_Misc_ShowsBorderOnlyWhileMouseInside"
                public static let maxAcceleratorLevel: InspectedAttribute.Identifier = "NSButton_Misc_MaxAcceleratorLevel"
                public static let springLoaded: InspectedAttribute.Identifier = "NSButton_Misc_SpringLoaded"
                public static let hasDestructiveAction: InspectedAttribute.Identifier = "NSButton_Misc_HasDestructiveAction"
            }

            public enum NSStatusBarButton {
                public static let appearsDisabled: InspectedAttribute.Identifier = "NSButton_NSStatusBarButton_AppearsDisabled"
            }

            public enum TintProminence {
                public static let tintProminence: InspectedAttribute.Identifier = "NSButton_TintProminence_TintProminence"
            }

            public enum Images {
                public static let image: InspectedAttribute.Identifier = "NSButton_Images_Image"
                public static let alternateImage: InspectedAttribute.Identifier = "NSButton_Images_AlternateImage"
            }

            public enum ImagePosition {
                public static let imagePosition: InspectedAttribute.Identifier = "NSButton_ImagePosition_ImagePosition"
            }

            public enum ImageScaling {
                public static let imageScaling: InspectedAttribute.Identifier = "NSButton_ImageScaling_ImageScaling"
            }

            public enum Behavior {
                public static let imageHugsTitle: InspectedAttribute.Identifier = "NSButton_Behavior_ImageHugsTitle"
                public static let allowsMixedState: InspectedAttribute.Identifier = "NSButton_Behavior_AllowsMixedState"
            }

            public enum SymbolConfiguration {
                public static let symbolConfiguration: InspectedAttribute.Identifier = "NSButton_SymbolConfiguration_SymbolConfiguration"
            }

            public enum State {
                public static let state: InspectedAttribute.Identifier = "NSButton_State_State"
            }

            public enum KeyEquivalent {
                public static let keyEquivalent: InspectedAttribute.Identifier = "NSButton_KeyEquivalent_KeyEquivalent"
            }

            public enum KeyEquivalentModifierMask {
                public static let keyEquivalentModifierMask: InspectedAttribute.Identifier = "NSButton_KeyEquivalentModifierMask_KeyEquivalentModifierMask"
            }

            public enum BorderShape {
                public static let borderShape: InspectedAttribute.Identifier = "NSButton_BorderShape_BorderShape"
            }
        }

        public enum NSScrollView {
            public enum ContentOffset {
                public static let offset: InspectedAttribute.Identifier = "NSScrollView_ContentOffset_Offset"
            }

            public enum ContentSize {
                public static let size: InspectedAttribute.Identifier = "NSScrollView_ContentSize_Size"
            }

            public enum ContentInset {
                public static let contentInset: InspectedAttribute.Identifier = "NSScrollView_ContentInset_ContentInset"
                public static let automaticallyAdjustsContentInsets: InspectedAttribute.Identifier = "NSScrollView_ContentInset_AutomaticallyAdjustsContentInsets"
            }

            public enum BorderType {
                public static let borderType: InspectedAttribute.Identifier = "NSScrollView_BorderType_BorderType"
            }

            public enum Scroller {
                public static let horizontal: InspectedAttribute.Identifier = "NSScrollView_Scroller_Horizontal"
                public static let vertical: InspectedAttribute.Identifier = "NSScrollView_Scroller_Vertical"
                public static let autohidesScrollers: InspectedAttribute.Identifier = "NSScrollView_Scroller_AutohidesScrollers"
                public static let scrollerStyle: InspectedAttribute.Identifier = "NSScrollView_Scroller_ScrollerStyle"
                public static let scrollerKnobStyle: InspectedAttribute.Identifier = "NSScrollView_Scroller_ScrollerKnobStyle"
                public static let scrollerInsets: InspectedAttribute.Identifier = "NSScrollView_Scroller_ScrollerInsets"
            }

            public enum Ruler {
                public static let horizontal: InspectedAttribute.Identifier = "NSScrollView_Ruler_Horizontal"
                public static let vertical: InspectedAttribute.Identifier = "NSScrollView_Ruler_Vertical"
                public static let visible: InspectedAttribute.Identifier = "NSScrollView_Ruler_Visible"
            }

            public enum LineScroll {
                public static let horizontal: InspectedAttribute.Identifier = "NSScrollView_LineScroll_Horizontal"
                public static let vertical: InspectedAttribute.Identifier = "NSScrollView_LineScroll_Vertical"
                public static let lineScroll: InspectedAttribute.Identifier = "NSScrollView_LineScroll_LineScroll"
            }

            public enum PageScroll {
                public static let horizontal: InspectedAttribute.Identifier = "NSScrollView_PageScroll_Horizontal"
                public static let vertical: InspectedAttribute.Identifier = "NSScrollView_PageScroll_Vertical"
                public static let pageScroll: InspectedAttribute.Identifier = "NSScrollView_PageScroll_PageScroll"
            }

            public enum ScrollElasiticity {
                public static let horizontal: InspectedAttribute.Identifier = "NSScrollView_ScrollElasiticity_Horizontal"
                public static let vertical: InspectedAttribute.Identifier = "NSScrollView_ScrollElasiticity_Vertical"
            }

            public enum Miscellaneous {
                public static let scrollsDynamically: InspectedAttribute.Identifier = "NSScrollView_Misc_ScrollsDynamically"
                public static let usesPredominantAxisScrolling: InspectedAttribute.Identifier = "NSScrollView_Misc_UsesPredominantAxisScrolling"
            }

            public enum Magnification {
                public static let allowsMagnification: InspectedAttribute.Identifier = "NSScrollView_Magnification_AllowsMagnification"
                public static let magnification: InspectedAttribute.Identifier = "NSScrollView_Magnification_Magnification"
                public static let maximum: InspectedAttribute.Identifier = "NSScrollView_Magnification_Max"
                public static let minimum: InspectedAttribute.Identifier = "NSScrollView_Magnification_Min"
            }

            public enum DocumentVisibleRect {
                public static let documentVisibleRect: InspectedAttribute.Identifier = "NSScrollView_DocumentVisibleRect_DocumentVisibleRect"
            }

            public enum BackgroundColor {
                public static let backgroundColor: InspectedAttribute.Identifier = "NSScrollView_BackgroundColor_BackgroundColor"
            }

            public enum Behavior {
                public static let drawsBackground: InspectedAttribute.Identifier = "NSScrollView_Behavior_DrawsBackground"
                public static let touchScrollingEnabled: InspectedAttribute.Identifier = "NSScrollView_Behavior_TouchScrollingEnabled"
            }

            public enum ContentInsets {
                public static let contentInsets: InspectedAttribute.Identifier = "NSScrollView_ContentInsets_ContentInsets"
            }

            public enum MinimumNumberOfTouchesForScrolling {
                public static let minimumNumberOfTouchesForScrolling: InspectedAttribute.Identifier = "NSScrollView_MinimumNumberOfTouchesForScrolling_MinimumNumberOfTouchesForScrolling"
            }

            public enum MaximumNumberOfTouchesForScrolling {
                public static let maximumNumberOfTouchesForScrolling: InspectedAttribute.Identifier = "NSScrollView_MaximumNumberOfTouchesForScrolling_MaximumNumberOfTouchesForScrolling"
            }

            public enum FindBarPosition {
                public static let findBarPosition: InspectedAttribute.Identifier = "NSScrollView_FindBarPosition_FindBarPosition"
            }
        }

        public enum NSTableView {
            public enum AllowsColumnReordering {
                public static let allowsColumnReordering: InspectedAttribute.Identifier = "NSTableView_AllowsColumnReordering_AllowsColumnReordering"
            }

            public enum AllowsColumnResizing {
                public static let allowsColumnResizing: InspectedAttribute.Identifier = "NSTableView_AllowsColumnResizing_AllowsColumnResizing"
            }

            public enum ColumnAutoresizingStyle {
                public static let columnAutoresizingStyle: InspectedAttribute.Identifier = "NSTableView_ColumnAutoresizingStyle_ColumnAutoresizingStyle"
            }

            public enum GridStyleMask {
                public static let gridStyleMask: InspectedAttribute.Identifier = "NSTableView_GridStyleMask_GridStyleMask"
            }

            public enum IntercellSpacing {
                public static let intercellSpacing: InspectedAttribute.Identifier = "NSTableView_IntercellSpacing_IntercellSpacing"
            }

            public enum UseAlternatingRowBackgroundColors {
                public static let useAlternatingRowBackgroundColors: InspectedAttribute.Identifier = "NSTableView_UseAlternatingRowBackgroundColors_UseAlternatingRowBackgroundColors"
            }

            public enum GridColor {
                public static let gridColor: InspectedAttribute.Identifier = "NSTableView_GridColor_GridColor"
            }

            public enum RowSizeStyle {
                public static let rowSizeStyle: InspectedAttribute.Identifier = "NSTableView_RowSizeStyle_RowSizeStyle"
            }

            public enum RowHeight {
                public static let rowHeight: InspectedAttribute.Identifier = "NSTableView_RowHeight_RowHeight"
            }

            public enum NumberOfRows {
                public static let numberOfRows: InspectedAttribute.Identifier = "NSTableView_NumberOfRows_NumberOfRows"
            }

            public enum NumberOfColumns {
                public static let numberOfColumns: InspectedAttribute.Identifier = "NSTableView_NumberOfColumns_NumberOfColumns"
            }

            public enum VerticalMotionCanBeginDrag {
                public static let verticalMotionCanBeginDrag: InspectedAttribute.Identifier = "NSTableView_VerticalMotionCanBeginDrag_VerticalMotionCanBeginDrag"
            }

            public enum AllowsMultipleSelection {
                public static let allowsMultipleSelection: InspectedAttribute.Identifier = "NSTableView_AllowsMultipleSelection_AllowsMultipleSelection"
            }

            public enum AllowsEmptySelection {
                public static let allowsEmptySelection: InspectedAttribute.Identifier = "NSTableView_AllowsEmptySelection_AllowsEmptySelection"
            }

            public enum AllowsColumnSelection {
                public static let allowsColumnSelection: InspectedAttribute.Identifier = "NSTableView_AllowsColumnSelection_AllowsColumnSelection"
            }

            public enum AllowsTypeSelect {
                public static let allowsTypeSelect: InspectedAttribute.Identifier = "NSTableView_AllowsTypeSelect_AllowsTypeSelect"
            }

            public enum SelectionHighlightStyle {
                public static let selectionHighlightStyle: InspectedAttribute.Identifier = "NSTableView_SelectionHighlightStyle_SelectionHighlightStyle"
            }

            public enum DraggingDestinationFeedbackStyle {
                public static let draggingDestinationFeedbackStyle: InspectedAttribute.Identifier = "NSTableView_DraggingDestinationFeedbackStyle_DraggingDestinationFeedbackStyle"
            }

            public enum AutomaticRowHeights {
                public static let automaticRowHeights: InspectedAttribute.Identifier = "NSTableView_AutomaticRowHeights_AutomaticRowHeights"
            }

            public enum AutosaveName {
                public static let autosaveName: InspectedAttribute.Identifier = "NSTableView_AutosaveName_AutosaveName"
            }

            public enum AutosaveTableColumns {
                public static let autosaveTableColumns: InspectedAttribute.Identifier = "NSTableView_AutosaveTableColumns_AutosaveTableColumns"
            }

            public enum FloatsGroupRows {
                public static let floatsGroupRows: InspectedAttribute.Identifier = "NSTableView_FloatsGroupRows_FloatsGroupRows"
            }

            public enum RowActionsVisible {
                public static let rowActionsVisible: InspectedAttribute.Identifier = "NSTableView_RowActionsVisible_RowActionsVisible"
            }

            public enum UsesStaticContents {
                public static let usesStaticContents: InspectedAttribute.Identifier = "NSTableView_UsesStaticContents_UsesStaticContents"
            }

            public enum UserInterfaceLayoutDirection {
                public static let userInterfaceLayoutDirection: InspectedAttribute.Identifier = "NSTableView_UserInterfaceLayoutDirection_UserInterfaceLayoutDirection"
            }

            public enum Style {
                public static let style: InspectedAttribute.Identifier = "NSTableView_Style_Style"
            }

            public enum BackgroundColor {
                public static let backgroundColor: InspectedAttribute.Identifier = "NSTableView_BackgroundColor_BackgroundColor"
            }

            public enum EffectiveRowSizeStyle {
                public static let effectiveRowSizeStyle: InspectedAttribute.Identifier = "NSTableView_EffectiveRowSizeStyle_EffectiveRowSizeStyle"
            }

            public enum EditedColumn {
                public static let editedColumn: InspectedAttribute.Identifier = "NSTableView_EditedColumn_EditedColumn"
            }

            public enum EditedRow {
                public static let editedRow: InspectedAttribute.Identifier = "NSTableView_EditedRow_EditedRow"
            }

            public enum ClickedColumn {
                public static let clickedColumn: InspectedAttribute.Identifier = "NSTableView_ClickedColumn_ClickedColumn"
            }

            public enum ClickedRow {
                public static let clickedRow: InspectedAttribute.Identifier = "NSTableView_ClickedRow_ClickedRow"
            }

            public enum SelectedColumn {
                public static let selectedColumn: InspectedAttribute.Identifier = "NSTableView_SelectedColumn_SelectedColumn"
            }

            public enum SelectedRow {
                public static let selectedRow: InspectedAttribute.Identifier = "NSTableView_SelectedRow_SelectedRow"
            }

            public enum NumberOfSelectedColumns {
                public static let numberOfSelectedColumns: InspectedAttribute.Identifier = "NSTableView_NumberOfSelectedColumns_NumberOfSelectedColumns"
            }

            public enum NumberOfSelectedRows {
                public static let numberOfSelectedRows: InspectedAttribute.Identifier = "NSTableView_NumberOfSelectedRows_NumberOfSelectedRows"
            }

            public enum EffectiveStyle {
                public static let effectiveStyle: InspectedAttribute.Identifier = "NSTableView_EffectiveStyle_EffectiveStyle"
            }
        }

        public enum NSTextView {
            public enum Font {
                public static let name: InspectedAttribute.Identifier = "NSTextView_Font_Name"
                public static let size: InspectedAttribute.Identifier = "NSTextView_Font_Size"
            }

            public enum Basic {
                public static let editable: InspectedAttribute.Identifier = "NSTextView_Basic_Editable"
                public static let selectable: InspectedAttribute.Identifier = "NSTextView_Basic_Selectable"
                public static let richText: InspectedAttribute.Identifier = "NSTextView_Basic_RichText"
                public static let fieldEditor: InspectedAttribute.Identifier = "NSTextView_Basic_FieldEditor"
                public static let importsGraphics: InspectedAttribute.Identifier = "NSTextView_Basic_ImportsGraphics"
            }

            public enum String {
                public static let string: InspectedAttribute.Identifier = "NSTextView_String_String"
            }

            public enum TextColor {
                public static let color: InspectedAttribute.Identifier = "NSTextView_TextColor_Color"
            }

            public enum Alignment {
                public static let alignment: InspectedAttribute.Identifier = "NSTextView_Alignment_Alignment"
            }

            public enum ContainerInset {
                public static let inset: InspectedAttribute.Identifier = "NSTextView_ContainerInset_Inset"
            }

            public enum BaseWritingDirection {
                public static let baseWritingDirection: InspectedAttribute.Identifier = "NSTextView_BaseWritingDirection_BaseWritingDirection"
            }

            public enum MaxSize {
                public static let maxSize: InspectedAttribute.Identifier = "NSTextView_MaxSize_MaxSize"
            }

            public enum MinSize {
                public static let minSize: InspectedAttribute.Identifier = "NSTextView_MinSize_MinSize"
            }

            public enum Resizable {
                public static let horizontal: InspectedAttribute.Identifier = "NSTextView_Resizable_Horizontal"
                public static let vertical: InspectedAttribute.Identifier = "NSTextView_Resizable_Vertical"
            }

            public enum TextContainerOrigin {
                public static let textContainerOrigin: InspectedAttribute.Identifier = "NSTextView_TextContainerOrigin_TextContainerOrigin"
            }

            public enum Behavior {
                public static let shouldDrawInsertionPoint: InspectedAttribute.Identifier = "NSTextView_Behavior_ShouldDrawInsertionPoint"
                public static let usesAdaptiveColorMappingForDarkAppearance: InspectedAttribute.Identifier = "NSTextView_Behavior_UsesAdaptiveColorMappingForDarkAppearance"
                public static let displaysLinkToolTips: InspectedAttribute.Identifier = "NSTextView_Behavior_DisplaysLinkToolTips"
                public static let acceptsGlyphInfo: InspectedAttribute.Identifier = "NSTextView_Behavior_AcceptsGlyphInfo"
                public static let usesRuler: InspectedAttribute.Identifier = "NSTextView_Behavior_UsesRuler"
                public static let usesInspectorBar: InspectedAttribute.Identifier = "NSTextView_Behavior_UsesInspectorBar"
                public static let continuousSpellCheckingEnabled: InspectedAttribute.Identifier = "NSTextView_Behavior_ContinuousSpellCheckingEnabled"
                public static let grammarCheckingEnabled: InspectedAttribute.Identifier = "NSTextView_Behavior_GrammarCheckingEnabled"
                public static let allowsDocumentBackgroundColorChange: InspectedAttribute.Identifier = "NSTextView_Behavior_AllowsDocumentBackgroundColorChange"
                public static let allowsUndo: InspectedAttribute.Identifier = "NSTextView_Behavior_AllowsUndo"
                public static let coalescingUndo: InspectedAttribute.Identifier = "NSTextView_Behavior_CoalescingUndo"
                public static let allowsImageEditing: InspectedAttribute.Identifier = "NSTextView_Behavior_AllowsImageEditing"
                public static let usesRolloverButtonForSelection: InspectedAttribute.Identifier = "NSTextView_Behavior_UsesRolloverButtonForSelection"
                public static let drawsBackground: InspectedAttribute.Identifier = "NSTextView_Behavior_DrawsBackground"
                public static let usesFontPanel: InspectedAttribute.Identifier = "NSTextView_Behavior_UsesFontPanel"
                public static let rulerVisible: InspectedAttribute.Identifier = "NSTextView_Behavior_RulerVisible"
                public static let writingToolsActive: InspectedAttribute.Identifier = "NSTextView_Behavior_WritingToolsActive"
                public static let smartInsertDeleteEnabled: InspectedAttribute.Identifier = "NSTextView_Behavior_SmartInsertDeleteEnabled"
                public static let automaticQuoteSubstitutionEnabled: InspectedAttribute.Identifier = "NSTextView_Behavior_AutomaticQuoteSubstitutionEnabled"
                public static let automaticLinkDetectionEnabled: InspectedAttribute.Identifier = "NSTextView_Behavior_AutomaticLinkDetectionEnabled"
                public static let automaticDataDetectionEnabled: InspectedAttribute.Identifier = "NSTextView_Behavior_AutomaticDataDetectionEnabled"
                public static let automaticDashSubstitutionEnabled: InspectedAttribute.Identifier = "NSTextView_Behavior_AutomaticDashSubstitutionEnabled"
                public static let automaticTextReplacementEnabled: InspectedAttribute.Identifier = "NSTextView_Behavior_AutomaticTextReplacementEnabled"
                public static let automaticSpellingCorrectionEnabled: InspectedAttribute.Identifier = "NSTextView_Behavior_AutomaticSpellingCorrectionEnabled"
                public static let usesFindPanel: InspectedAttribute.Identifier = "NSTextView_Behavior_UsesFindPanel"
                public static let usesFindBar: InspectedAttribute.Identifier = "NSTextView_Behavior_UsesFindBar"
                public static let incrementalSearchingEnabled: InspectedAttribute.Identifier = "NSTextView_Behavior_IncrementalSearchingEnabled"
                public static let automaticTextCompletionEnabled: InspectedAttribute.Identifier = "NSTextView_Behavior_AutomaticTextCompletionEnabled"
                public static let allowsCharacterPickerTouchBarItem: InspectedAttribute.Identifier = "NSTextView_Behavior_AllowsCharacterPickerTouchBarItem"
            }

            public enum SelectionAffinity {
                public static let selectionAffinity: InspectedAttribute.Identifier = "NSTextView_SelectionAffinity_SelectionAffinity"
            }

            public enum SelectionGranularity {
                public static let selectionGranularity: InspectedAttribute.Identifier = "NSTextView_SelectionGranularity_SelectionGranularity"
            }

            public enum Colors {
                public static let insertionPointColor: InspectedAttribute.Identifier = "NSTextView_Colors_InsertionPointColor"
                public static let backgroundColor: InspectedAttribute.Identifier = "NSTextView_Colors_BackgroundColor"
            }

            public enum WritingToolsBehavior {
                public static let writingToolsBehavior: InspectedAttribute.Identifier = "NSTextView_WritingToolsBehavior_WritingToolsBehavior"
            }

            public enum AllowedWritingToolsResultOptions {
                public static let allowedWritingToolsResultOptions: InspectedAttribute.Identifier = "NSTextView_AllowedWritingToolsResultOptions_AllowedWritingToolsResultOptions"
            }

            public enum InlinePredictionType {
                public static let inlinePredictionType: InspectedAttribute.Identifier = "NSTextView_InlinePredictionType_InlinePredictionType"
            }

            public enum MathExpressionCompletionType {
                public static let mathExpressionCompletionType: InspectedAttribute.Identifier = "NSTextView_MathExpressionCompletionType_MathExpressionCompletionType"
            }

            public enum SelectedRange {
                public static let selectedRange: InspectedAttribute.Identifier = "NSTextView_SelectedRange_SelectedRange"
            }
        }

        public enum NSTextField {
            public enum Bordered {
                public static let bordered: InspectedAttribute.Identifier = "NSTextField_Bordered_Bordered"
            }

            public enum Bezeled {
                public static let bezeled: InspectedAttribute.Identifier = "NSTextField_Bezeled_Bezeled"
            }

            public enum Editable {
                public static let editable: InspectedAttribute.Identifier = "NSTextField_Editable_Editable"
            }

            public enum Selectable {
                public static let selectable: InspectedAttribute.Identifier = "NSTextField_Selectable_Selectable"
            }

            public enum DrawsBackground {
                public static let drawsBackground: InspectedAttribute.Identifier = "NSTextField_DrawsBackground_DrawsBackground"
            }

            public enum BezelStyle {
                public static let bezelStyle: InspectedAttribute.Identifier = "NSTextField_BezelStyle_BezelStyle"
            }

            public enum PreferredMaxLayoutWidth {
                public static let preferredMaxLayoutWidth: InspectedAttribute.Identifier = "NSTextField_PreferredMaxLayoutWidth_PreferredMaxLayoutWidth"
            }

            public enum MaximumNumberOfLines {
                public static let maximumNumberOfLines: InspectedAttribute.Identifier = "NSTextField_MaximumNumberOfLines_MaximumNumberOfLines"
            }

            public enum AllowsDefaultTighteningForTruncation {
                public static let allowsDefaultTighteningForTruncation: InspectedAttribute.Identifier = "NSTextField_AllowsDefaultTighteningForTruncation_AllowsDefaultTighteningForTruncation"
            }

            public enum LineBreakStrategy {
                public static let lineBreakStrategy: InspectedAttribute.Identifier = "NSTextField_LineBreakStrategy_LineBreakStrategy"
            }

            public enum Placeholder {
                public static let placeholder: InspectedAttribute.Identifier = "NSTextField_Placeholder_Placeholder"
            }

            public enum TextColor {
                public static let color: InspectedAttribute.Identifier = "NSTextField_TextColor_Color"
            }

            public enum BackgroundColor {
                public static let color: InspectedAttribute.Identifier = "NSTextField_BackgroundColor_Color"
            }

            public enum AllowsEditingTextAttributes {
                public static let allowsEditingTextAttributes: InspectedAttribute.Identifier = "NSTextField_AllowsEditingTextAttributes_AllowsEditingTextAttributes"
            }

            public enum ImportsGraphics {
                public static let importsGraphics: InspectedAttribute.Identifier = "NSTextField_ImportsGraphics_ImportsGraphics"
            }

            public enum NSTokenField {
                public static let tokenStyle: InspectedAttribute.Identifier = "NSTextField_NSTokenField_TokenStyle"
                public static let completionDelay: InspectedAttribute.Identifier = "NSTextField_NSTokenField_CompletionDelay"
            }

            public enum Behavior {
                public static let acceptsFirstResponder: InspectedAttribute.Identifier = "NSTextField_Behavior_AcceptsFirstResponder"
                public static let allowsWritingTools: InspectedAttribute.Identifier = "NSTextField_Behavior_AllowsWritingTools"
                public static let allowsWritingToolsAffordance: InspectedAttribute.Identifier = "NSTextField_Behavior_AllowsWritingToolsAffordance"
                public static let resolvesNaturalAlignmentWithBaseWritingDirection: InspectedAttribute.Identifier = "NSTextField_Behavior_ResolvesNaturalAlignmentWithBaseWritingDirection"
                public static let automaticTextCompletionEnabled: InspectedAttribute.Identifier = "NSTextField_Behavior_AutomaticTextCompletionEnabled"
                public static let allowsCharacterPickerTouchBarItem: InspectedAttribute.Identifier = "NSTextField_Behavior_AllowsCharacterPickerTouchBarItem"
            }

            public enum BorderShape {
                public static let borderShape: InspectedAttribute.Identifier = "NSTextField_BorderShape_BorderShape"
            }
        }

        public enum NSVisualEffectView {
            public enum Material {
                public static let material: InspectedAttribute.Identifier = "NSVisualEffectView_Material_Material"
            }

            public enum InteriorBackgroundStyle {
                public static let interiorBackgroundStyle: InspectedAttribute.Identifier = "NSVisualEffectView_InteriorBackgroundStyle_InteriorBackgroundStyle"
            }

            public enum BlendingMode {
                public static let blendingMode: InspectedAttribute.Identifier = "NSVisualEffectView_BlendingMode_BlendingMode"
            }

            public enum State {
                public static let state: InspectedAttribute.Identifier = "NSVisualEffectView_State_State"
            }

            public enum Emphasized {
                public static let emphasized: InspectedAttribute.Identifier = "NSVisualEffectView_Emphasized_Emphasized"
            }

            public enum MaskImage {
                public static let maskImage: InspectedAttribute.Identifier = "NSVisualEffectView_MaskImage_MaskImage"
            }
        }

        public enum NSStackView {
            public enum Orientation {
                public static let orientation: InspectedAttribute.Identifier = "NSStackView_Orientation_Orientation"
            }

            public enum EdgeInsets {
                public static let edgeInsets: InspectedAttribute.Identifier = "NSStackView_EdgeInsets_EdgeInsets"
            }

            public enum DetachesHiddenViews {
                public static let detachesHiddenViews: InspectedAttribute.Identifier = "NSStackView_DetachesHiddenViews_DetachesHiddenViews"
            }

            public enum Distribution {
                public static let distribution: InspectedAttribute.Identifier = "NSStackView_Distribution_Distribution"
            }

            public enum Alignment {
                public static let alignment: InspectedAttribute.Identifier = "NSStackView_Alignment_Alignment"
            }

            public enum Spacing {
                public static let spacing: InspectedAttribute.Identifier = "NSStackView_Spacing_Spacing"
            }
        }

        public enum NSWindow {
            public enum Title {
                public static let title: InspectedAttribute.Identifier = "NSWindow_Title_Title"
                public static let subtitle: InspectedAttribute.Identifier = "NSWindow_Title_Subtitle"
            }

            public enum State {
                public static let keyWindow: InspectedAttribute.Identifier = "NSWindow_State_KeyWindow"
                public static let mainWindow: InspectedAttribute.Identifier = "NSWindow_State_MainWindow"
                public static let visible: InspectedAttribute.Identifier = "NSWindow_State_Visible"
                public static let canBecomeKeyWindow: InspectedAttribute.Identifier = "NSWindow_State_CanBecomeKeyWindow"
                public static let canBecomeMainWindow: InspectedAttribute.Identifier = "NSWindow_State_CanBecomeMainWindow"
            }

            public enum Style {
                public static let titled: InspectedAttribute.Identifier = "NSWindow_Style_Titled"
                public static let closable: InspectedAttribute.Identifier = "NSWindow_Style_Closable"
                public static let miniaturizable: InspectedAttribute.Identifier = "NSWindow_Style_Miniaturizable"
                public static let resizable: InspectedAttribute.Identifier = "NSWindow_Style_Resizable"
                public static let unifiedTitleAndToolbar: InspectedAttribute.Identifier = "NSWindow_Style_UnifiedTitleAndToolbar"
                public static let fullScreen: InspectedAttribute.Identifier = "NSWindow_Style_FullScreen"
                public static let fullSizeContentView: InspectedAttribute.Identifier = "NSWindow_Style_FullSizeContentView"
                public static let utilityWindow: InspectedAttribute.Identifier = "NSWindow_Style_UtilityWindow"
                public static let docModalWindow: InspectedAttribute.Identifier = "NSWindow_Style_DocModalWindow"
                public static let nonactivatingPanel: InspectedAttribute.Identifier = "NSWindow_Style_NonactivatingPanel"
                public static let hudWindow: InspectedAttribute.Identifier = "NSWindow_Style_HUDWindow"
            }

            public enum CollectionBehavior {
                public static let canJoinAllSpaces: InspectedAttribute.Identifier = "NSWindow_CollectionBehavior_CanJoinAllSpaces"
                public static let moveToActiveSpace: InspectedAttribute.Identifier = "NSWindow_CollectionBehavior_MoveToActiveSpace"
                public static let participatesInCycle: InspectedAttribute.Identifier = "NSWindow_CollectionBehavior_ParticipatesInCycle"
                public static let ignoresCycle: InspectedAttribute.Identifier = "NSWindow_CollectionBehavior_IgnoresCycle"
                public static let fullScreenPrimary: InspectedAttribute.Identifier = "NSWindow_CollectionBehavior_FullScreenPrimary"
                public static let fullScreenAuxiliary: InspectedAttribute.Identifier = "NSWindow_CollectionBehavior_FullScreenAuxiliary"
                public static let fullScreenNone: InspectedAttribute.Identifier = "NSWindow_CollectionBehavior_FullScreenNone"
                public static let fullScreenAllowsTiling: InspectedAttribute.Identifier = "NSWindow_CollectionBehavior_FullScreenAllowsTiling"
                public static let fullScreenDisallowsTiling: InspectedAttribute.Identifier = "NSWindow_CollectionBehavior_FullScreenDisallowsTiling"
            }

            public enum Appearance {
                public static let titlebarAppearsTransparent: InspectedAttribute.Identifier = "NSWindow_Appearance_TitlebarAppearsTransparent"
                public static let titleVisibility: InspectedAttribute.Identifier = "NSWindow_Appearance_TitleVisibility"
                public static let toolbarStyle: InspectedAttribute.Identifier = "NSWindow_Appearance_ToolbarStyle"
                public static let titlebarSeparatorStyle: InspectedAttribute.Identifier = "NSWindow_Appearance_TitlebarSeparatorStyle"
                public static let backgroundColor: InspectedAttribute.Identifier = "NSWindow_Appearance_BackgroundColor"
                public static let alphaValue: InspectedAttribute.Identifier = "NSWindow_Appearance_AlphaValue"
                public static let opaque: InspectedAttribute.Identifier = "NSWindow_Appearance_Opaque"
                public static let hasShadow: InspectedAttribute.Identifier = "NSWindow_Appearance_HasShadow"
            }

            public enum Behavior {
                public static let movable: InspectedAttribute.Identifier = "NSWindow_Behavior_Movable"
                public static let movableByWindowBackground: InspectedAttribute.Identifier = "NSWindow_Behavior_MovableByWindowBackground"
                public static let animationBehavior: InspectedAttribute.Identifier = "NSWindow_Behavior_AnimationBehavior"
                public static let level: InspectedAttribute.Identifier = "NSWindow_Behavior_Level"
                public static let hidesOnDeactivate: InspectedAttribute.Identifier = "NSWindow_Behavior_HidesOnDeactivate"
                public static let tabbingMode: InspectedAttribute.Identifier = "NSWindow_Behavior_TabbingMode"
            }

            public enum Size {
                public static let minSize: InspectedAttribute.Identifier = "NSWindow_Size_MinSize"
                public static let maxSize: InspectedAttribute.Identifier = "NSWindow_Size_MaxSize"
            }

            public enum Information {
                public static let windowNumber: InspectedAttribute.Identifier = "NSWindow_Info_WindowNumber"
                public static let backingScaleFactor: InspectedAttribute.Identifier = "NSWindow_Info_BackingScaleFactor"
            }

            public enum ContentLayoutRect {
                public static let contentLayoutRect: InspectedAttribute.Identifier = "NSWindow_ContentLayoutRect_ContentLayoutRect"
            }

            public enum RepresentedURL {
                public static let representedURL: InspectedAttribute.Identifier = "NSWindow_RepresentedURL_RepresentedURL"
            }

            public enum RepresentedFilename {
                public static let representedFilename: InspectedAttribute.Identifier = "NSWindow_RepresentedFilename_RepresentedFilename"
            }

            public enum Flags {
                public static let excludedFromWindowsMenu: InspectedAttribute.Identifier = "NSWindow_Flags_ExcludedFromWindowsMenu"
                public static let inLiveResize: InspectedAttribute.Identifier = "NSWindow_Flags_InLiveResize"
                public static let viewsNeedDisplay: InspectedAttribute.Identifier = "NSWindow_Flags_ViewsNeedDisplay"
                public static let preservesContentDuringLiveResize: InspectedAttribute.Identifier = "NSWindow_Flags_PreservesContentDuringLiveResize"
                public static let releasedWhenClosed: InspectedAttribute.Identifier = "NSWindow_Flags_ReleasedWhenClosed"
                public static let zoomed: InspectedAttribute.Identifier = "NSWindow_Flags_Zoomed"
                public static let miniaturized: InspectedAttribute.Identifier = "NSWindow_Flags_Miniaturized"
                public static let canHide: InspectedAttribute.Identifier = "NSWindow_Flags_CanHide"
                public static let documentEdited: InspectedAttribute.Identifier = "NSWindow_Flags_DocumentEdited"
                public static let worksWhenModal: InspectedAttribute.Identifier = "NSWindow_Flags_WorksWhenModal"
                public static let preventsApplicationTerminationWhenModal: InspectedAttribute.Identifier = "NSWindow_Flags_PreventsApplicationTerminationWhenModal"
                public static let allowsToolTipsWhenApplicationIsInactive: InspectedAttribute.Identifier = "NSWindow_Flags_AllowsToolTipsWhenApplicationIsInactive"
                public static let hasDynamicDepthLimit: InspectedAttribute.Identifier = "NSWindow_Flags_HasDynamicDepthLimit"
                public static let allowsConcurrentViewDrawing: InspectedAttribute.Identifier = "NSWindow_Flags_AllowsConcurrentViewDrawing"
                public static let displaysWhenScreenProfileChanges: InspectedAttribute.Identifier = "NSWindow_Flags_DisplaysWhenScreenProfileChanges"
                public static let canBecomeVisibleWithoutLogin: InspectedAttribute.Identifier = "NSWindow_Flags_CanBecomeVisibleWithoutLogin"
                public static let onActiveSpace: InspectedAttribute.Identifier = "NSWindow_Flags_OnActiveSpace"
                public static let sheet: InspectedAttribute.Identifier = "NSWindow_Flags_Sheet"
                public static let autorecalculatesKeyViewLoop: InspectedAttribute.Identifier = "NSWindow_Flags_AutorecalculatesKeyViewLoop"
                public static let hasActiveWindowSharingSession: InspectedAttribute.Identifier = "NSWindow_Flags_HasActiveWindowSharingSession"
                public static let acceptsMouseMovedEvents: InspectedAttribute.Identifier = "NSWindow_Flags_AcceptsMouseMovedEvents"
                public static let ignoresMouseEvents: InspectedAttribute.Identifier = "NSWindow_Flags_IgnoresMouseEvents"
                public static let areCursorRectsEnabled: InspectedAttribute.Identifier = "NSWindow_Flags_AreCursorRectsEnabled"
                public static let restorable: InspectedAttribute.Identifier = "NSWindow_Flags_Restorable"
                public static let hasCloseBox: InspectedAttribute.Identifier = "NSWindow_Flags_HasCloseBox"
                public static let hasTitleBar: InspectedAttribute.Identifier = "NSWindow_Flags_HasTitleBar"
                public static let floatingPanel: InspectedAttribute.Identifier = "NSWindow_Flags_FloatingPanel"
                public static let miniaturizable: InspectedAttribute.Identifier = "NSWindow_Flags_Miniaturizable"
                public static let modalPanel: InspectedAttribute.Identifier = "NSWindow_Flags_ModalPanel"
                public static let resizable: InspectedAttribute.Identifier = "NSWindow_Flags_Resizable"
                public static let zoomable: InspectedAttribute.Identifier = "NSWindow_Flags_Zoomable"
            }

            public enum StyleMask {
                public static let styleMask: InspectedAttribute.Identifier = "NSWindow_StyleMask_StyleMask"
            }

            public enum CascadingReferenceFrame {
                public static let cascadingReferenceFrame: InspectedAttribute.Identifier = "NSWindow_CascadingReferenceFrame_CascadingReferenceFrame"
            }

            public enum ResizeIncrements {
                public static let resizeIncrements: InspectedAttribute.Identifier = "NSWindow_ResizeIncrements_ResizeIncrements"
            }

            public enum AspectRatio {
                public static let aspectRatio: InspectedAttribute.Identifier = "NSWindow_AspectRatio_AspectRatio"
            }

            public enum ContentResizeIncrements {
                public static let contentResizeIncrements: InspectedAttribute.Identifier = "NSWindow_ContentResizeIncrements_ContentResizeIncrements"
            }

            public enum ContentAspectRatio {
                public static let contentAspectRatio: InspectedAttribute.Identifier = "NSWindow_ContentAspectRatio_ContentAspectRatio"
            }

            public enum MiniwindowTitle {
                public static let miniwindowTitle: InspectedAttribute.Identifier = "NSWindow_MiniwindowTitle_MiniwindowTitle"
            }

            public enum BackingType {
                public static let backingType: InspectedAttribute.Identifier = "NSWindow_BackingType_BackingType"
            }

            public enum DepthLimit {
                public static let depthLimit: InspectedAttribute.Identifier = "NSWindow_DepthLimit_DepthLimit"
            }

            public enum Screen {
                public static let screen: InspectedAttribute.Identifier = "NSWindow_Screen_Screen"
            }

            public enum DeepestScreen {
                public static let deepestScreen: InspectedAttribute.Identifier = "NSWindow_DeepestScreen_DeepestScreen"
            }

            public enum SharingType {
                public static let sharingType: InspectedAttribute.Identifier = "NSWindow_SharingType_SharingType"
            }

            public enum CollectionBehaviorOptions {
                public static let collectionBehavior: InspectedAttribute.Identifier = "NSWindow_CollectionBehaviorOptions_CollectionBehavior"
            }

            public enum ContentMinSize {
                public static let contentMinSize: InspectedAttribute.Identifier = "NSWindow_ContentMinSize_ContentMinSize"
            }

            public enum ContentMaxSize {
                public static let contentMaxSize: InspectedAttribute.Identifier = "NSWindow_ContentMaxSize_ContentMaxSize"
            }

            public enum MinFullScreenContentSize {
                public static let minFullScreenContentSize: InspectedAttribute.Identifier = "NSWindow_MinFullScreenContentSize_MinFullScreenContentSize"
            }

            public enum MaxFullScreenContentSize {
                public static let maxFullScreenContentSize: InspectedAttribute.Identifier = "NSWindow_MaxFullScreenContentSize_MaxFullScreenContentSize"
            }

            public enum OcclusionState {
                public static let occlusionState: InspectedAttribute.Identifier = "NSWindow_OcclusionState_OcclusionState"
            }

            public enum KeyViewSelectionDirection {
                public static let keyViewSelectionDirection: InspectedAttribute.Identifier = "NSWindow_KeyViewSelectionDirection_KeyViewSelectionDirection"
            }

            public enum Toolbar {
                public static let toolbar: InspectedAttribute.Identifier = "NSWindow_Toolbar_Toolbar"
            }

            public enum OrderedIndex {
                public static let orderedIndex: InspectedAttribute.Identifier = "NSWindow_OrderedIndex_OrderedIndex"
            }

            public enum FirstResponder {
                public static let firstResponder: InspectedAttribute.Identifier = "NSWindow_FirstResponder_FirstResponder"
            }
        }

        public enum UIWindowScene {
            public enum State {
                public static let activationState: InspectedAttribute.Identifier = "UIWindowScene_State_ActivationState"
            }

            public enum Title {
                public static let title: InspectedAttribute.Identifier = "UIWindowScene_Title_Title"
                public static let subtitle: InspectedAttribute.Identifier = "UIWindowScene_Title_Subtitle"
            }

            public enum Orientation {
                public static let interfaceOrientation: InspectedAttribute.Identifier = "UIWindowScene_Orientation_InterfaceOrientation"
            }

            public enum Windows {
                public static let windowCount: InspectedAttribute.Identifier = "UIWindowScene_Windows_WindowCount"
                public static let keyWindowClassName: InspectedAttribute.Identifier = "UIWindowScene_Windows_KeyWindowClassName"
            }

            public enum Screen {
                public static let screenBounds: InspectedAttribute.Identifier = "UIWindowScene_Screen_ScreenBounds"
                public static let screenScale: InspectedAttribute.Identifier = "UIWindowScene_Screen_ScreenScale"
            }

            public enum StatusBar {
                public static let statusBarHidden: InspectedAttribute.Identifier = "UIWindowScene_StatusBar_StatusBarHidden"
                public static let statusBarStyle: InspectedAttribute.Identifier = "UIWindowScene_StatusBar_StatusBarStyle"
                public static let statusBarFrame: InspectedAttribute.Identifier = "UIWindowScene_StatusBar_StatusBarFrame"
            }

            public enum Traits {
                public static let userInterfaceStyle: InspectedAttribute.Identifier = "UIWindowScene_Traits_UserInterfaceStyle"
                public static let horizontalSizeClass: InspectedAttribute.Identifier = "UIWindowScene_Traits_HorizontalSizeClass"
                public static let verticalSizeClass: InspectedAttribute.Identifier = "UIWindowScene_Traits_VerticalSizeClass"
                // UIWindowScene additional traits
                public static let userInterfaceLevel: InspectedAttribute.Identifier = "UIWindowScene_Traits_UserInterfaceLevel"
                public static let activeAppearance: InspectedAttribute.Identifier = "UIWindowScene_Traits_ActiveAppearance"
                public static let accessibilityContrast: InspectedAttribute.Identifier = "UIWindowScene_Traits_AccessibilityContrast"
                public static let legibilityWeight: InspectedAttribute.Identifier = "UIWindowScene_Traits_LegibilityWeight"
                public static let displayScale: InspectedAttribute.Identifier = "UIWindowScene_Traits_DisplayScale"
                public static let displayGamut: InspectedAttribute.Identifier = "UIWindowScene_Traits_DisplayGamut"
                public static let userInterfaceIdiom: InspectedAttribute.Identifier = "UIWindowScene_Traits_UserInterfaceIdiom"
                public static let layoutDirection: InspectedAttribute.Identifier = "UIWindowScene_Traits_LayoutDirection"
                public static let preferredContentSizeCategory: InspectedAttribute.Identifier = "UIWindowScene_Traits_PreferredContentSizeCategory"
                public static let sceneCaptureState: InspectedAttribute.Identifier = "UIWindowScene_Traits_SceneCaptureState"
                public static let imageDynamicRange: InspectedAttribute.Identifier = "UIWindowScene_Traits_ImageDynamicRange"
                public static let typesettingLanguage: InspectedAttribute.Identifier = "UIWindowScene_Traits_TypesettingLanguage"
            }

            public enum Session {
                public static let persistentIdentifier: InspectedAttribute.Identifier = "UIWindowScene_Session_PersistentIdentifier"
                public static let sessionRole: InspectedAttribute.Identifier = "UIWindowScene_Session_SessionRole"
                public static let stateRestorationActivityType: InspectedAttribute.Identifier = "UIWindowScene_Session_StateRestorationActivityType"
                public static let userInfo: InspectedAttribute.Identifier = "UIWindowScene_Session_UserInfo"
            }

            public enum Configuration {
                public static let name: InspectedAttribute.Identifier = "UIWindowScene_Configuration_Name"
                public static let sceneClass: InspectedAttribute.Identifier = "UIWindowScene_Configuration_SceneClass"
                public static let delegateClass: InspectedAttribute.Identifier = "UIWindowScene_Configuration_DelegateClass"
                public static let storyboard: InspectedAttribute.Identifier = "UIWindowScene_Configuration_Storyboard"
            }

            public enum Geometry {
                public static let systemFrame: InspectedAttribute.Identifier = "UIWindowScene_Geometry_SystemFrame"
                public static let interfaceOrientationLocked: InspectedAttribute.Identifier = "UIWindowScene_Geometry_InterfaceOrientationLocked"
                public static let interactivelyResizing: InspectedAttribute.Identifier = "UIWindowScene_Geometry_InteractivelyResizing"
            }

            public enum ActivationConditions {
                public static let canActivate: InspectedAttribute.Identifier = "UIWindowScene_ActivationConditions_CanActivate"
                public static let prefersToActivate: InspectedAttribute.Identifier = "UIWindowScene_ActivationConditions_PrefersToActivate"
            }

            public enum SizeRestrictions {
                public static let minimumSize: InspectedAttribute.Identifier = "UIWindowScene_SizeRestrictions_MinimumSize"
                public static let maximumSize: InspectedAttribute.Identifier = "UIWindowScene_SizeRestrictions_MaximumSize"
                public static let allowsFullScreen: InspectedAttribute.Identifier = "UIWindowScene_SizeRestrictions_AllowsFullScreen"
            }

            public enum WindowingBehaviors {
                public static let closable: InspectedAttribute.Identifier = "UIWindowScene_WindowingBehaviors_Closable"
                public static let miniaturizable: InspectedAttribute.Identifier = "UIWindowScene_WindowingBehaviors_Miniaturizable"
                public static let fullScreen: InspectedAttribute.Identifier = "UIWindowScene_WindowingBehaviors_FullScreen"
            }

            public enum Pointer {
                public static let locked: InspectedAttribute.Identifier = "UIWindowScene_Pointer_Locked"
            }

            public enum Protection {
                public static let userAuthenticationEnabled: InspectedAttribute.Identifier = "UIWindowScene_Protection_UserAuthenticationEnabled"
            }
        }

        public enum UITraitCollection {
            public enum Appearance {
                public static let userInterfaceStyle: InspectedAttribute.Identifier = "UITraitCollection_Appearance_UserInterfaceStyle"
                public static let userInterfaceLevel: InspectedAttribute.Identifier = "UITraitCollection_Appearance_UserInterfaceLevel"
                public static let activeAppearance: InspectedAttribute.Identifier = "UITraitCollection_Appearance_ActiveAppearance"
                public static let accessibilityContrast: InspectedAttribute.Identifier = "UITraitCollection_Appearance_AccessibilityContrast"
                public static let legibilityWeight: InspectedAttribute.Identifier = "UITraitCollection_Appearance_LegibilityWeight"
            }

            public enum SizeClass {
                public static let horizontalSizeClass: InspectedAttribute.Identifier = "UITraitCollection_SizeClass_HorizontalSizeClass"
                public static let verticalSizeClass: InspectedAttribute.Identifier = "UITraitCollection_SizeClass_VerticalSizeClass"
            }

            public enum Display {
                public static let displayScale: InspectedAttribute.Identifier = "UITraitCollection_Display_DisplayScale"
                public static let displayGamut: InspectedAttribute.Identifier = "UITraitCollection_Display_DisplayGamut"
                public static let imageDynamicRange: InspectedAttribute.Identifier = "UITraitCollection_Display_ImageDynamicRange"
            }

            public enum Device {
                public static let userInterfaceIdiom: InspectedAttribute.Identifier = "UITraitCollection_Device_UserInterfaceIdiom"
                public static let forceTouchCapability: InspectedAttribute.Identifier = "UITraitCollection_Device_ForceTouchCapability"
            }

            public enum Layout {
                public static let layoutDirection: InspectedAttribute.Identifier = "UITraitCollection_Layout_LayoutDirection"
            }

            public enum Content {
                public static let preferredContentSizeCategory: InspectedAttribute.Identifier = "UITraitCollection_Content_PreferredContentSizeCategory"
                public static let typesettingLanguage: InspectedAttribute.Identifier = "UITraitCollection_Content_TypesettingLanguage"
            }
        }

        public enum NSSlider {
            public enum SliderType {
                public static let sliderType: InspectedAttribute.Identifier = "NSSlider_SliderType_SliderType"
            }

            public enum Range {
                public static let minValue: InspectedAttribute.Identifier = "NSSlider_Range_MinValue"
                public static let maxValue: InspectedAttribute.Identifier = "NSSlider_Range_MaxValue"
            }

            public enum TickMark {
                public static let numberOfTickMarks: InspectedAttribute.Identifier = "NSSlider_TickMark_NumberOfTickMarks"
                public static let tickMarkPosition: InspectedAttribute.Identifier = "NSSlider_TickMark_TickMarkPosition"
                public static let allowsTickMarkValuesOnly: InspectedAttribute.Identifier = "NSSlider_TickMark_AllowsTickMarkValuesOnly"
            }

            public enum Miscellaneous {
                public static let vertical: InspectedAttribute.Identifier = "NSSlider_Misc_Vertical"
                public static let knobThickness: InspectedAttribute.Identifier = "NSSlider_Misc_KnobThickness"
                public static let altIncrementValue: InspectedAttribute.Identifier = "NSSlider_Misc_AltIncrementValue"
                public static let trackFillColor: InspectedAttribute.Identifier = "NSSlider_Misc_TrackFillColor"
            }

            public enum NeutralValue {
                public static let neutralValue: InspectedAttribute.Identifier = "NSSlider_NeutralValue_NeutralValue"
            }

            public enum TintProminence {
                public static let tintProminence: InspectedAttribute.Identifier = "NSSlider_TintProminence_TintProminence"
            }
        }

        public enum NSProgressIndicator {
            public enum Style {
                public static let style: InspectedAttribute.Identifier = "NSProgressIndicator_Style_Style"
            }

            public enum Range {
                public static let minValue: InspectedAttribute.Identifier = "NSProgressIndicator_Range_MinValue"
                public static let maxValue: InspectedAttribute.Identifier = "NSProgressIndicator_Range_MaxValue"
                public static let doubleValue: InspectedAttribute.Identifier = "NSProgressIndicator_Range_DoubleValue"
            }

            public enum Miscellaneous {
                public static let indeterminate: InspectedAttribute.Identifier = "NSProgressIndicator_Misc_Indeterminate"
                public static let bezeled: InspectedAttribute.Identifier = "NSProgressIndicator_Misc_Bezeled"
                public static let displayedWhenStopped: InspectedAttribute.Identifier = "NSProgressIndicator_Misc_DisplayedWhenStopped"
            }

            public enum ControlSize {
                public static let controlSize: InspectedAttribute.Identifier = "NSProgressIndicator_ControlSize_ControlSize"
            }

            public enum UsesThreadedAnimation {
                public static let usesThreadedAnimation: InspectedAttribute.Identifier = "NSProgressIndicator_UsesThreadedAnimation_UsesThreadedAnimation"
            }
        }

        public enum NSSegmentedControl {
            public enum SegmentCount {
                public static let segmentCount: InspectedAttribute.Identifier = "NSSegmentedControl_SegmentCount_SegmentCount"
            }

            public enum Selection {
                public static let selectedSegment: InspectedAttribute.Identifier = "NSSegmentedControl_Selection_SelectedSegment"
            }

            public enum Style {
                public static let segmentStyle: InspectedAttribute.Identifier = "NSSegmentedControl_Style_SegmentStyle"
                public static let trackingMode: InspectedAttribute.Identifier = "NSSegmentedControl_Style_TrackingMode"
            }

            public enum Colors {
                public static let selectedSegmentBezelColor: InspectedAttribute.Identifier = "NSSegmentedControl_Colors_SelectedSegmentBezelColor"
            }

            public enum Role {
                public static let role: InspectedAttribute.Identifier = "NSSegmentedControl_Role_Role"
            }

            public enum SpringLoaded {
                public static let springLoaded: InspectedAttribute.Identifier = "NSSegmentedControl_SpringLoaded_SpringLoaded"
            }

            public enum DoubleValueForSelectedSegment {
                public static let doubleValueForSelectedSegment: InspectedAttribute.Identifier = "NSSegmentedControl_DoubleValueForSelectedSegment_DoubleValueForSelectedSegment"
            }

            public enum IndexOfSelectedItem {
                public static let indexOfSelectedItem: InspectedAttribute.Identifier = "NSSegmentedControl_IndexOfSelectedItem_IndexOfSelectedItem"
            }

            public enum SegmentDistribution {
                public static let segmentDistribution: InspectedAttribute.Identifier = "NSSegmentedControl_SegmentDistribution_SegmentDistribution"
            }

            public enum BorderShape {
                public static let borderShape: InspectedAttribute.Identifier = "NSSegmentedControl_BorderShape_BorderShape"
            }
        }

        public enum NSPopUpButton {
            public enum Behavior {
                public static let pullsDown: InspectedAttribute.Identifier = "NSPopUpButton_Behavior_PullsDown"
                public static let autoenablesItems: InspectedAttribute.Identifier = "NSPopUpButton_Behavior_AutoenablesItems"
                public static let preferredEdge: InspectedAttribute.Identifier = "NSPopUpButton_Behavior_PreferredEdge"
            }

            public enum Selection {
                public static let selectedTag: InspectedAttribute.Identifier = "NSPopUpButton_Selection_SelectedTag"
                public static let indexOfSelectedItem: InspectedAttribute.Identifier = "NSPopUpButton_Selection_IndexOfSelectedItem"
                public static let titleOfSelectedItem: InspectedAttribute.Identifier = "NSPopUpButton_Selection_TitleOfSelectedItem"
            }

            public enum Items {
                public static let numberOfItems: InspectedAttribute.Identifier = "NSPopUpButton_Items_NumberOfItems"
            }

            public enum Menu {
                public static let menu: InspectedAttribute.Identifier = "NSPopUpButton_Menu_Menu"
            }

            public enum Flags {
                public static let usesItemFromMenu: InspectedAttribute.Identifier = "NSPopUpButton_Flags_UsesItemFromMenu"
                public static let altersStateOfSelectedItem: InspectedAttribute.Identifier = "NSPopUpButton_Flags_AltersStateOfSelectedItem"
            }
        }

        public enum NSComboBox {
            public enum Items {
                public static let numberOfItems: InspectedAttribute.Identifier = "NSComboBox_Items_NumberOfItems"
                public static let hasVerticalScroller: InspectedAttribute.Identifier = "NSComboBox_Items_HasVerticalScroller"
                public static let numberOfVisibleItems: InspectedAttribute.Identifier = "NSComboBox_Items_NumberOfVisibleItems"
                public static let intercellSpacing: InspectedAttribute.Identifier = "NSComboBox_Items_IntercellSpacing"
                public static let itemHeight: InspectedAttribute.Identifier = "NSComboBox_Items_ItemHeight"
            }

            public enum Miscellaneous {
                public static let buttonBordered: InspectedAttribute.Identifier = "NSComboBox_Misc_ButtonBordered"
                public static let completes: InspectedAttribute.Identifier = "NSComboBox_Misc_Completes"
                public static let usesDataSource: InspectedAttribute.Identifier = "NSComboBox_Misc_UsesDataSource"
            }

            public enum IndexOfSelectedItem {
                public static let indexOfSelectedItem: InspectedAttribute.Identifier = "NSComboBox_IndexOfSelectedItem_IndexOfSelectedItem"
            }
        }

        public enum NSStepper {
            public enum Range {
                public static let minValue: InspectedAttribute.Identifier = "NSStepper_Range_MinValue"
                public static let maxValue: InspectedAttribute.Identifier = "NSStepper_Range_MaxValue"
                public static let increment: InspectedAttribute.Identifier = "NSStepper_Range_Increment"
            }

            public enum Miscellaneous {
                public static let valueWraps: InspectedAttribute.Identifier = "NSStepper_Misc_ValueWraps"
                public static let autorepeat: InspectedAttribute.Identifier = "NSStepper_Misc_Autorepeat"
            }
        }

        public enum NSColorWell {
            public enum Color {
                public static let color: InspectedAttribute.Identifier = "NSColorWell_Color_Color"
            }

            public enum Miscellaneous {
                public static let bordered: InspectedAttribute.Identifier = "NSColorWell_Misc_Bordered"
                public static let active: InspectedAttribute.Identifier = "NSColorWell_Misc_Active"
                public static let colorWellStyle: InspectedAttribute.Identifier = "NSColorWell_Misc_ColorWellStyle"
            }

            public enum Image {
                public static let image: InspectedAttribute.Identifier = "NSColorWell_Image_Image"
            }

            public enum SupportsAlpha {
                public static let supportsAlpha: InspectedAttribute.Identifier = "NSColorWell_SupportsAlpha_SupportsAlpha"
            }

            public enum MaximumLinearExposure {
                public static let maximumLinearExposure: InspectedAttribute.Identifier = "NSColorWell_MaximumLinearExposure_MaximumLinearExposure"
            }
        }

        public enum NSSwitch {
            public enum State {
                public static let state: InspectedAttribute.Identifier = "NSSwitch_State_State"
            }
        }

        public enum NSDatePicker {
            public enum Style {
                public static let datePickerStyle: InspectedAttribute.Identifier = "NSDatePicker_Style_DatePickerStyle"
                public static let datePickerMode: InspectedAttribute.Identifier = "NSDatePicker_Style_DatePickerMode"
            }

            public enum Range {
                public static let dateValue: InspectedAttribute.Identifier = "NSDatePicker_Range_DateValue"
                public static let minDate: InspectedAttribute.Identifier = "NSDatePicker_Range_MinDate"
                public static let maxDate: InspectedAttribute.Identifier = "NSDatePicker_Range_MaxDate"
            }

            public enum Miscellaneous {
                public static let bordered: InspectedAttribute.Identifier = "NSDatePicker_Misc_Bordered"
                public static let bezeled: InspectedAttribute.Identifier = "NSDatePicker_Misc_Bezeled"
                public static let drawsBackground: InspectedAttribute.Identifier = "NSDatePicker_Misc_DrawsBackground"
            }

            public enum Colors {
                public static let backgroundColor: InspectedAttribute.Identifier = "NSDatePicker_Colors_BackgroundColor"
                public static let textColor: InspectedAttribute.Identifier = "NSDatePicker_Colors_TextColor"
            }

            public enum DatePickerElements {
                public static let datePickerElements: InspectedAttribute.Identifier = "NSDatePicker_DatePickerElements_DatePickerElements"
            }

            public enum Calendar {
                public static let calendar: InspectedAttribute.Identifier = "NSDatePicker_Calendar_Calendar"
            }

            public enum Locale {
                public static let locale: InspectedAttribute.Identifier = "NSDatePicker_Locale_Locale"
            }

            public enum TimeZone {
                public static let timeZone: InspectedAttribute.Identifier = "NSDatePicker_TimeZone_TimeZone"
            }

            public enum TimeInterval {
                public static let timeInterval: InspectedAttribute.Identifier = "NSDatePicker_TimeInterval_TimeInterval"
            }

            public enum PresentsCalendarOverlay {
                public static let presentsCalendarOverlay: InspectedAttribute.Identifier = "NSDatePicker_PresentsCalendarOverlay_PresentsCalendarOverlay"
            }
        }

        public enum NSLevelIndicator {
            public enum Style {
                public static let style: InspectedAttribute.Identifier = "NSLevelIndicator_Style_Style"
            }

            public enum Range {
                public static let minValue: InspectedAttribute.Identifier = "NSLevelIndicator_Range_MinValue"
                public static let maxValue: InspectedAttribute.Identifier = "NSLevelIndicator_Range_MaxValue"
                public static let warningValue: InspectedAttribute.Identifier = "NSLevelIndicator_Range_WarningValue"
                public static let criticalValue: InspectedAttribute.Identifier = "NSLevelIndicator_Range_CriticalValue"
            }

            public enum TickMark {
                public static let numberOfTickMarks: InspectedAttribute.Identifier = "NSLevelIndicator_TickMark_NumberOfTickMarks"
                public static let numberOfMajorTickMarks: InspectedAttribute.Identifier = "NSLevelIndicator_TickMark_NumberOfMajorTickMarks"
            }

            public enum Behavior {
                public static let editable: InspectedAttribute.Identifier = "NSLevelIndicator_Behavior_Editable"
                public static let drawsTieredCapacityLevels: InspectedAttribute.Identifier = "NSLevelIndicator_Behavior_DrawsTieredCapacityLevels"
            }

            public enum TickMarkPosition {
                public static let tickMarkPosition: InspectedAttribute.Identifier = "NSLevelIndicator_TickMarkPosition_TickMarkPosition"
            }

            public enum Colors {
                public static let fillColor: InspectedAttribute.Identifier = "NSLevelIndicator_Colors_FillColor"
                public static let warningFillColor: InspectedAttribute.Identifier = "NSLevelIndicator_Colors_WarningFillColor"
                public static let criticalFillColor: InspectedAttribute.Identifier = "NSLevelIndicator_Colors_CriticalFillColor"
            }

            public enum PlaceholderVisibility {
                public static let placeholderVisibility: InspectedAttribute.Identifier = "NSLevelIndicator_PlaceholderVisibility_PlaceholderVisibility"
            }

            public enum Images {
                public static let ratingImage: InspectedAttribute.Identifier = "NSLevelIndicator_Images_RatingImage"
                public static let ratingPlaceholderImage: InspectedAttribute.Identifier = "NSLevelIndicator_Images_RatingPlaceholderImage"
            }
        }

        public enum NSOutlineView {
            public enum Indentation {
                public static let indentationPerLevel: InspectedAttribute.Identifier = "NSOutlineView_Indentation_IndentationPerLevel"
            }

            public enum Miscellaneous {
                public static let autoresizesOutlineColumn: InspectedAttribute.Identifier = "NSOutlineView_Misc_AutoresizesOutlineColumn"
                public static let indentationMarkerFollowsCell: InspectedAttribute.Identifier = "NSOutlineView_Misc_IndentationMarkerFollowsCell"
                public static let autosaveExpandedItems: InspectedAttribute.Identifier = "NSOutlineView_Misc_AutosaveExpandedItems"
            }

            public enum UserInterfaceLayoutDirection {
                public static let userInterfaceLayoutDirection: InspectedAttribute.Identifier = "NSOutlineView_UserInterfaceLayoutDirection_UserInterfaceLayoutDirection"
            }

            public enum StronglyReferencesItems {
                public static let stronglyReferencesItems: InspectedAttribute.Identifier = "NSOutlineView_StronglyReferencesItems_StronglyReferencesItems"
            }
        }

        public enum NSCollectionView {
            public enum Selection {
                public static let selectable: InspectedAttribute.Identifier = "NSCollectionView_Selection_Selectable"
                public static let allowsMultipleSelection: InspectedAttribute.Identifier = "NSCollectionView_Selection_AllowsMultipleSelection"
                public static let allowsEmptySelection: InspectedAttribute.Identifier = "NSCollectionView_Selection_AllowsEmptySelection"
            }

            public enum Information {
                public static let numberOfSections: InspectedAttribute.Identifier = "NSCollectionView_Info_NumberOfSections"
            }

            public enum Colors {
                public static let backgroundColors: InspectedAttribute.Identifier = "NSCollectionView_Colors_BackgroundColors"
            }

            public enum BackgroundViewScrollsWithContent {
                public static let backgroundViewScrollsWithContent: InspectedAttribute.Identifier = "NSCollectionView_BackgroundViewScrollsWithContent_BackgroundViewScrollsWithContent"
            }
        }

        public enum NSBox {
            public enum Kind {
                public static let boxType: InspectedAttribute.Identifier = "NSBox_Type_BoxType"
                public static let borderType: InspectedAttribute.Identifier = "NSBox_Type_BorderType"
            }

            public enum Title {
                public static let title: InspectedAttribute.Identifier = "NSBox_Title_Title"
                public static let titlePosition: InspectedAttribute.Identifier = "NSBox_Title_TitlePosition"
            }

            public enum Appearance {
                public static let transparent: InspectedAttribute.Identifier = "NSBox_Appearance_Transparent"
                public static let fillColor: InspectedAttribute.Identifier = "NSBox_Appearance_FillColor"
                public static let borderColor: InspectedAttribute.Identifier = "NSBox_Appearance_BorderColor"
            }

            public enum Metrics {
                public static let borderWidth: InspectedAttribute.Identifier = "NSBox_Metrics_BorderWidth"
                public static let cornerRadius: InspectedAttribute.Identifier = "NSBox_Metrics_CornerRadius"
                public static let contentViewMargins: InspectedAttribute.Identifier = "NSBox_Metrics_ContentViewMargins"
            }

            public enum TitleFont {
                public static let titleFont: InspectedAttribute.Identifier = "NSBox_TitleFont_TitleFont"
            }

            public enum BorderRect {
                public static let borderRect: InspectedAttribute.Identifier = "NSBox_BorderRect_BorderRect"
            }

            public enum TitleRect {
                public static let titleRect: InspectedAttribute.Identifier = "NSBox_TitleRect_TitleRect"
            }
        }

        public enum NSSplitView {
            public enum Orientation {
                public static let vertical: InspectedAttribute.Identifier = "NSSplitView_Orientation_Vertical"
            }

            public enum Style {
                public static let dividerStyle: InspectedAttribute.Identifier = "NSSplitView_Style_DividerStyle"
                public static let dividerThickness: InspectedAttribute.Identifier = "NSSplitView_Style_DividerThickness"
            }

            public enum Miscellaneous {
                public static let arrangesAllSubviews: InspectedAttribute.Identifier = "NSSplitView_Misc_ArrangesAllSubviews"
            }

            public enum DividerColor {
                public static let dividerColor: InspectedAttribute.Identifier = "NSSplitView_DividerColor_DividerColor"
            }
        }

        public enum NSTabView {
            public enum Kind {
                public static let tabViewType: InspectedAttribute.Identifier = "NSTabView_Type_TabViewType"
                public static let tabPosition: InspectedAttribute.Identifier = "NSTabView_Type_TabPosition"
                public static let tabViewBorderType: InspectedAttribute.Identifier = "NSTabView_Type_TabViewBorderType"
            }

            public enum Miscellaneous {
                public static let allowsTruncatedLabels: InspectedAttribute.Identifier = "NSTabView_Misc_AllowsTruncatedLabels"
                public static let drawsBackground: InspectedAttribute.Identifier = "NSTabView_Misc_DrawsBackground"
            }

            public enum Information {
                public static let numberOfTabViewItems: InspectedAttribute.Identifier = "NSTabView_Info_NumberOfTabViewItems"
            }

            public enum Font {
                public static let font: InspectedAttribute.Identifier = "NSTabView_Font_Font"
            }

            public enum MinimumSize {
                public static let minimumSize: InspectedAttribute.Identifier = "NSTabView_MinimumSize_MinimumSize"
            }

            public enum ControlSize {
                public static let controlSize: InspectedAttribute.Identifier = "NSTabView_ControlSize_ControlSize"
            }

            public enum ContentRect {
                public static let contentRect: InspectedAttribute.Identifier = "NSTabView_ContentRect_ContentRect"
            }
        }

        public enum NSGridView {
            public enum Dimensions {
                public static let numberOfColumns: InspectedAttribute.Identifier = "NSGridView_Dimensions_NumberOfColumns"
                public static let numberOfRows: InspectedAttribute.Identifier = "NSGridView_Dimensions_NumberOfRows"
            }

            public enum Spacing {
                public static let rowSpacing: InspectedAttribute.Identifier = "NSGridView_Spacing_RowSpacing"
                public static let columnSpacing: InspectedAttribute.Identifier = "NSGridView_Spacing_ColumnSpacing"
            }

            public enum Placement {
                public static let xPlacement: InspectedAttribute.Identifier = "NSGridView_Placement_XPlacement"
                public static let yPlacement: InspectedAttribute.Identifier = "NSGridView_Placement_YPlacement"
            }

            public enum RowAlignment {
                public static let rowAlignment: InspectedAttribute.Identifier = "NSGridView_RowAlignment_RowAlignment"
            }
        }

        public enum LayoutGuide {
            public enum GuideIdentifier {
                public static let identifier: InspectedAttribute.Identifier = "LayoutGuide_Identifier_Identifier"
            }

            public enum LayoutFrame {
                public static let layoutFrame: InspectedAttribute.Identifier = "LayoutGuide_LayoutFrame_LayoutFrame"
            }

            public enum OwningView {
                public static let owningView: InspectedAttribute.Identifier = "LayoutGuide_OwningView_OwningView"
            }

            public enum Constraints {
                public static let constraints: InspectedAttribute.Identifier = "LayoutGuide_Constraints_Constraints"
            }

            public enum KeyboardLayoutGuide {
                public static let followsUndockedKeyboard: InspectedAttribute.Identifier = "LayoutGuide_KeyboardLayoutGuide_FollowsUndockedKeyboard"
                public static let usesBottomSafeArea: InspectedAttribute.Identifier = "LayoutGuide_KeyboardLayoutGuide_UsesBottomSafeArea"
            }

            public enum KeyboardDismissPadding {
                public static let keyboardDismissPadding: InspectedAttribute.Identifier = "LayoutGuide_KeyboardDismissPadding_KeyboardDismissPadding"
            }

            public enum ConstraintsActiveNearEdges {
                public static let constraints: InspectedAttribute.Identifier = "LayoutGuide_ConstraintsActiveNearEdges_Constraints"
            }

            public enum ConstraintsActiveAwayFromEdges {
                public static let constraints: InspectedAttribute.Identifier = "LayoutGuide_ConstraintsActiveAwayFromEdges_Constraints"
            }
        }

        public enum NSCell {
            public enum Cell {
                public static let type: InspectedAttribute.Identifier = "NSCell_Cell_Type"
                public static let state: InspectedAttribute.Identifier = "NSCell_Cell_State"
                public static let enabled: InspectedAttribute.Identifier = "NSCell_Cell_Enabled"
                public static let bordered: InspectedAttribute.Identifier = "NSCell_Cell_Bordered"
                public static let bezeled: InspectedAttribute.Identifier = "NSCell_Cell_Bezeled"
                public static let highlighted: InspectedAttribute.Identifier = "NSCell_Cell_Highlighted"
                public static let editable: InspectedAttribute.Identifier = "NSCell_Cell_Editable"
                public static let selectable: InspectedAttribute.Identifier = "NSCell_Cell_Selectable"
                public static let alignment: InspectedAttribute.Identifier = "NSCell_Cell_Alignment"
                public static let controlSize: InspectedAttribute.Identifier = "NSCell_Cell_ControlSize"
            }

            public enum ButtonCell {
                public static let bezelStyle: InspectedAttribute.Identifier = "NSCell_ButtonCell_BezelStyle"
                public static let imagePosition: InspectedAttribute.Identifier = "NSCell_ButtonCell_ImagePosition"
                public static let showsBorderOnlyWhileMouseInside: InspectedAttribute.Identifier = "NSCell_ButtonCell_ShowsBorderOnlyWhileMouseInside"
                public static let keyEquivalent: InspectedAttribute.Identifier = "NSCell_ButtonCell_KeyEquivalent"
                public static let alternateTitle: InspectedAttribute.Identifier = "NSCell_ButtonCell_AlternateTitle"
                public static let highlightsBy: InspectedAttribute.Identifier = "NSCell_ButtonCell_HighlightsBy"
                public static let showsStateBy: InspectedAttribute.Identifier = "NSCell_ButtonCell_ShowsStateBy"
                public static let title: InspectedAttribute.Identifier = "NSCell_ButtonCell_Title"
                public static let attributedTitle: InspectedAttribute.Identifier = "NSCell_ButtonCell_AttributedTitle"
                public static let attributedAlternateTitle: InspectedAttribute.Identifier = "NSCell_ButtonCell_AttributedAlternateTitle"
                public static let alternateImage: InspectedAttribute.Identifier = "NSCell_ButtonCell_AlternateImage"
                public static let imageScaling: InspectedAttribute.Identifier = "NSCell_ButtonCell_ImageScaling"
                public static let keyEquivalentModifierMask: InspectedAttribute.Identifier = "NSCell_ButtonCell_KeyEquivalentModifierMask"
                public static let transparent: InspectedAttribute.Identifier = "NSCell_ButtonCell_Transparent"
                public static let opaque: InspectedAttribute.Identifier = "NSCell_ButtonCell_Opaque"
                public static let imageDimsWhenDisabled: InspectedAttribute.Identifier = "NSCell_ButtonCell_ImageDimsWhenDisabled"
                public static let backgroundColor: InspectedAttribute.Identifier = "NSCell_ButtonCell_BackgroundColor"
            }

            public enum TextFieldCell {
                public static let placeholder: InspectedAttribute.Identifier = "NSCell_TextFieldCell_Placeholder"
                public static let drawsBackground: InspectedAttribute.Identifier = "NSCell_TextFieldCell_DrawsBackground"
                public static let textColor: InspectedAttribute.Identifier = "NSCell_TextFieldCell_TextColor"
                public static let backgroundColor: InspectedAttribute.Identifier = "NSCell_TextFieldCell_BackgroundColor"
                public static let bezelStyle: InspectedAttribute.Identifier = "NSCell_TextFieldCell_BezelStyle"
                public static let placeholderAttributedString: InspectedAttribute.Identifier = "NSCell_TextFieldCell_PlaceholderAttributedString"
                public static let allowedInputSourceLocales: InspectedAttribute.Identifier = "NSCell_TextFieldCell_AllowedInputSourceLocales"
            }

            public enum Content {
                public static let title: InspectedAttribute.Identifier = "NSCell_Content_Title"
                public static let fontName: InspectedAttribute.Identifier = "NSCell_Content_FontName"
                public static let fontSize: InspectedAttribute.Identifier = "NSCell_Content_FontSize"
                public static let lineBreakMode: InspectedAttribute.Identifier = "NSCell_Content_LineBreakMode"
                public static let wraps: InspectedAttribute.Identifier = "NSCell_Content_Wraps"
            }

            public enum Behavior {
                public static let tag: InspectedAttribute.Identifier = "NSCell_Behavior_Tag"
                public static let continuous: InspectedAttribute.Identifier = "NSCell_Behavior_Continuous"
                public static let allowsMixedState: InspectedAttribute.Identifier = "NSCell_Behavior_AllowsMixedState"
                public static let sendsActionOnEndEditing: InspectedAttribute.Identifier = "NSCell_Behavior_SendsActionOnEndEditing"
            }

            public enum ControlView {
                public static let controlView: InspectedAttribute.Identifier = "NSCell_ControlView_ControlView"
            }

            public enum Flags {
                public static let opaque: InspectedAttribute.Identifier = "NSCell_Flags_Opaque"
                public static let scrollable: InspectedAttribute.Identifier = "NSCell_Flags_Scrollable"
                public static let hasValidObjectValue: InspectedAttribute.Identifier = "NSCell_Flags_HasValidObjectValue"
                public static let allowsUndo: InspectedAttribute.Identifier = "NSCell_Flags_AllowsUndo"
                public static let truncatesLastVisibleLine: InspectedAttribute.Identifier = "NSCell_Flags_TruncatesLastVisibleLine"
                public static let usesSingleLineMode: InspectedAttribute.Identifier = "NSCell_Flags_UsesSingleLineMode"
                public static let refusesFirstResponder: InspectedAttribute.Identifier = "NSCell_Flags_RefusesFirstResponder"
                public static let acceptsFirstResponder: InspectedAttribute.Identifier = "NSCell_Flags_AcceptsFirstResponder"
                public static let showsFirstResponder: InspectedAttribute.Identifier = "NSCell_Flags_ShowsFirstResponder"
                public static let wantsNotificationForMarkedText: InspectedAttribute.Identifier = "NSCell_Flags_WantsNotificationForMarkedText"
                public static let allowsEditingTextAttributes: InspectedAttribute.Identifier = "NSCell_Flags_AllowsEditingTextAttributes"
                public static let importsGraphics: InspectedAttribute.Identifier = "NSCell_Flags_ImportsGraphics"
            }

            public enum Font {
                public static let font: InspectedAttribute.Identifier = "NSCell_Font_Font"
            }

            public enum KeyEquivalent {
                public static let keyEquivalent: InspectedAttribute.Identifier = "NSCell_KeyEquivalent_KeyEquivalent"
            }

            public enum StringValue {
                public static let stringValue: InspectedAttribute.Identifier = "NSCell_StringValue_StringValue"
            }

            public enum IntValue {
                public static let intValue: InspectedAttribute.Identifier = "NSCell_IntValue_IntValue"
            }

            public enum FloatValue {
                public static let floatValue: InspectedAttribute.Identifier = "NSCell_FloatValue_FloatValue"
            }

            public enum DoubleValue {
                public static let doubleValue: InspectedAttribute.Identifier = "NSCell_DoubleValue_DoubleValue"
            }

            public enum IntegerValue {
                public static let integerValue: InspectedAttribute.Identifier = "NSCell_IntegerValue_IntegerValue"
            }

            public enum Image {
                public static let image: InspectedAttribute.Identifier = "NSCell_Image_Image"
            }

            public enum CellSize {
                public static let cellSize: InspectedAttribute.Identifier = "NSCell_CellSize_CellSize"
            }

            public enum MouseDownFlags {
                public static let mouseDownFlags: InspectedAttribute.Identifier = "NSCell_MouseDownFlags_MouseDownFlags"
            }

            public enum Menu {
                public static let menu: InspectedAttribute.Identifier = "NSCell_Menu_Menu"
            }

            public enum BaseWritingDirection {
                public static let baseWritingDirection: InspectedAttribute.Identifier = "NSCell_BaseWritingDirection_BaseWritingDirection"
            }

            public enum UserInterfaceLayoutDirection {
                public static let userInterfaceLayoutDirection: InspectedAttribute.Identifier = "NSCell_UserInterfaceLayoutDirection_UserInterfaceLayoutDirection"
            }

            public enum FocusRingType {
                public static let focusRingType: InspectedAttribute.Identifier = "NSCell_FocusRingType_FocusRingType"
            }

            public enum AttributedStringValue {
                public static let attributedStringValue: InspectedAttribute.Identifier = "NSCell_AttributedStringValue_AttributedStringValue"
            }

            public enum NextState {
                public static let nextState: InspectedAttribute.Identifier = "NSCell_NextState_NextState"
            }

            public enum BackgroundStyle {
                public static let backgroundStyle: InspectedAttribute.Identifier = "NSCell_BackgroundStyle_BackgroundStyle"
            }

            public enum InteriorBackgroundStyle {
                public static let interiorBackgroundStyle: InspectedAttribute.Identifier = "NSCell_InteriorBackgroundStyle_InteriorBackgroundStyle"
            }

            public enum NSActionCell {
                public static let tag: InspectedAttribute.Identifier = "NSCell_NSActionCell_Tag"
            }

            public enum NSMenuItemCell {
                public static let needsSizing: InspectedAttribute.Identifier = "NSCell_NSMenuItemCell_NeedsSizing"
                public static let needsDisplay: InspectedAttribute.Identifier = "NSCell_NSMenuItemCell_NeedsDisplay"
                public static let tag: InspectedAttribute.Identifier = "NSCell_NSMenuItemCell_Tag"
            }

            public enum NSPopUpButtonCell {
                public static let menu: InspectedAttribute.Identifier = "NSCell_NSPopUpButtonCell_Menu"
                public static let pullsDown: InspectedAttribute.Identifier = "NSCell_NSPopUpButtonCell_PullsDown"
                public static let autoenablesItems: InspectedAttribute.Identifier = "NSCell_NSPopUpButtonCell_AutoenablesItems"
                public static let preferredEdge: InspectedAttribute.Identifier = "NSCell_NSPopUpButtonCell_PreferredEdge"
                public static let usesItemFromMenu: InspectedAttribute.Identifier = "NSCell_NSPopUpButtonCell_UsesItemFromMenu"
                public static let altersStateOfSelectedItem: InspectedAttribute.Identifier = "NSCell_NSPopUpButtonCell_AltersStateOfSelectedItem"
                public static let numberOfItems: InspectedAttribute.Identifier = "NSCell_NSPopUpButtonCell_NumberOfItems"
                public static let indexOfSelectedItem: InspectedAttribute.Identifier = "NSCell_NSPopUpButtonCell_IndexOfSelectedItem"
                public static let itemTitles: InspectedAttribute.Identifier = "NSCell_NSPopUpButtonCell_ItemTitles"
                public static let titleOfSelectedItem: InspectedAttribute.Identifier = "NSCell_NSPopUpButtonCell_TitleOfSelectedItem"
                public static let arrowPosition: InspectedAttribute.Identifier = "NSCell_NSPopUpButtonCell_ArrowPosition"
            }

            public enum NSDatePickerCell {
                public static let datePickerStyle: InspectedAttribute.Identifier = "NSCell_NSDatePickerCell_DatePickerStyle"
                public static let drawsBackground: InspectedAttribute.Identifier = "NSCell_NSDatePickerCell_DrawsBackground"
                public static let backgroundColor: InspectedAttribute.Identifier = "NSCell_NSDatePickerCell_BackgroundColor"
                public static let textColor: InspectedAttribute.Identifier = "NSCell_NSDatePickerCell_TextColor"
                public static let datePickerMode: InspectedAttribute.Identifier = "NSCell_NSDatePickerCell_DatePickerMode"
                public static let datePickerElements: InspectedAttribute.Identifier = "NSCell_NSDatePickerCell_DatePickerElements"
                public static let calendar: InspectedAttribute.Identifier = "NSCell_NSDatePickerCell_Calendar"
                public static let locale: InspectedAttribute.Identifier = "NSCell_NSDatePickerCell_Locale"
                public static let timeZone: InspectedAttribute.Identifier = "NSCell_NSDatePickerCell_TimeZone"
                public static let dateValue: InspectedAttribute.Identifier = "NSCell_NSDatePickerCell_DateValue"
                public static let timeInterval: InspectedAttribute.Identifier = "NSCell_NSDatePickerCell_TimeInterval"
                public static let minDate: InspectedAttribute.Identifier = "NSCell_NSDatePickerCell_MinDate"
                public static let maxDate: InspectedAttribute.Identifier = "NSCell_NSDatePickerCell_MaxDate"
            }

            public enum NSFormCell {
                public static let titleWidth: InspectedAttribute.Identifier = "NSCell_NSFormCell_TitleWidth"
                public static let title: InspectedAttribute.Identifier = "NSCell_NSFormCell_Title"
                public static let titleFont: InspectedAttribute.Identifier = "NSCell_NSFormCell_TitleFont"
                public static let opaque: InspectedAttribute.Identifier = "NSCell_NSFormCell_Opaque"
                public static let placeholderString: InspectedAttribute.Identifier = "NSCell_NSFormCell_PlaceholderString"
                public static let placeholderAttributedString: InspectedAttribute.Identifier = "NSCell_NSFormCell_PlaceholderAttributedString"
                public static let titleAlignment: InspectedAttribute.Identifier = "NSCell_NSFormCell_TitleAlignment"
                public static let titleBaseWritingDirection: InspectedAttribute.Identifier = "NSCell_NSFormCell_TitleBaseWritingDirection"
                public static let preferredTextFieldWidth: InspectedAttribute.Identifier = "NSCell_NSFormCell_PreferredTextFieldWidth"
                public static let attributedTitle: InspectedAttribute.Identifier = "NSCell_NSFormCell_AttributedTitle"
            }

            public enum NSLevelIndicatorCell {
                public static let levelIndicatorStyle: InspectedAttribute.Identifier = "NSCell_NSLevelIndicatorCell_LevelIndicatorStyle"
                public static let minValue: InspectedAttribute.Identifier = "NSCell_NSLevelIndicatorCell_MinValue"
                public static let maxValue: InspectedAttribute.Identifier = "NSCell_NSLevelIndicatorCell_MaxValue"
                public static let warningValue: InspectedAttribute.Identifier = "NSCell_NSLevelIndicatorCell_WarningValue"
                public static let criticalValue: InspectedAttribute.Identifier = "NSCell_NSLevelIndicatorCell_CriticalValue"
                public static let tickMarkPosition: InspectedAttribute.Identifier = "NSCell_NSLevelIndicatorCell_TickMarkPosition"
                public static let numberOfTickMarks: InspectedAttribute.Identifier = "NSCell_NSLevelIndicatorCell_NumberOfTickMarks"
                public static let numberOfMajorTickMarks: InspectedAttribute.Identifier = "NSCell_NSLevelIndicatorCell_NumberOfMajorTickMarks"
            }

            public enum NSPathCell {
                public static let pathStyle: InspectedAttribute.Identifier = "NSCell_NSPathCell_PathStyle"
                public static let url: InspectedAttribute.Identifier = "NSCell_NSPathCell_URL"
                public static let allowedTypes: InspectedAttribute.Identifier = "NSCell_NSPathCell_AllowedTypes"
                public static let pathComponentCells: InspectedAttribute.Identifier = "NSCell_NSPathCell_PathComponentCells"
                public static let backgroundColor: InspectedAttribute.Identifier = "NSCell_NSPathCell_BackgroundColor"
                public static let placeholderString: InspectedAttribute.Identifier = "NSCell_NSPathCell_PlaceholderString"
                public static let placeholderAttributedString: InspectedAttribute.Identifier = "NSCell_NSPathCell_PlaceholderAttributedString"
            }

            public enum NSSegmentedCell {
                public static let segmentCount: InspectedAttribute.Identifier = "NSCell_NSSegmentedCell_SegmentCount"
                public static let selectedSegment: InspectedAttribute.Identifier = "NSCell_NSSegmentedCell_SelectedSegment"
                public static let trackingMode: InspectedAttribute.Identifier = "NSCell_NSSegmentedCell_TrackingMode"
                public static let segmentStyle: InspectedAttribute.Identifier = "NSCell_NSSegmentedCell_SegmentStyle"
            }

            public enum NSSliderCell {
                public static let minValue: InspectedAttribute.Identifier = "NSCell_NSSliderCell_MinValue"
                public static let maxValue: InspectedAttribute.Identifier = "NSCell_NSSliderCell_MaxValue"
                public static let altIncrementValue: InspectedAttribute.Identifier = "NSCell_NSSliderCell_AltIncrementValue"
                public static let sliderType: InspectedAttribute.Identifier = "NSCell_NSSliderCell_SliderType"
                public static let vertical: InspectedAttribute.Identifier = "NSCell_NSSliderCell_Vertical"
                public static let trackRect: InspectedAttribute.Identifier = "NSCell_NSSliderCell_TrackRect"
                public static let knobThickness: InspectedAttribute.Identifier = "NSCell_NSSliderCell_KnobThickness"
                public static let numberOfTickMarks: InspectedAttribute.Identifier = "NSCell_NSSliderCell_NumberOfTickMarks"
                public static let tickMarkPosition: InspectedAttribute.Identifier = "NSCell_NSSliderCell_TickMarkPosition"
                public static let allowsTickMarkValuesOnly: InspectedAttribute.Identifier = "NSCell_NSSliderCell_AllowsTickMarkValuesOnly"
            }

            public enum NSStepperCell {
                public static let minValue: InspectedAttribute.Identifier = "NSCell_NSStepperCell_MinValue"
                public static let maxValue: InspectedAttribute.Identifier = "NSCell_NSStepperCell_MaxValue"
                public static let increment: InspectedAttribute.Identifier = "NSCell_NSStepperCell_Increment"
                public static let valueWraps: InspectedAttribute.Identifier = "NSCell_NSStepperCell_ValueWraps"
                public static let autorepeat: InspectedAttribute.Identifier = "NSCell_NSStepperCell_Autorepeat"
            }

            public enum NSComboBoxCell {
                public static let hasVerticalScroller: InspectedAttribute.Identifier = "NSCell_NSComboBoxCell_HasVerticalScroller"
                public static let intercellSpacing: InspectedAttribute.Identifier = "NSCell_NSComboBoxCell_IntercellSpacing"
                public static let itemHeight: InspectedAttribute.Identifier = "NSCell_NSComboBoxCell_ItemHeight"
                public static let numberOfVisibleItems: InspectedAttribute.Identifier = "NSCell_NSComboBoxCell_NumberOfVisibleItems"
                public static let buttonBordered: InspectedAttribute.Identifier = "NSCell_NSComboBoxCell_ButtonBordered"
                public static let usesDataSource: InspectedAttribute.Identifier = "NSCell_NSComboBoxCell_UsesDataSource"
                public static let indexOfSelectedItem: InspectedAttribute.Identifier = "NSCell_NSComboBoxCell_IndexOfSelectedItem"
                public static let numberOfItems: InspectedAttribute.Identifier = "NSCell_NSComboBoxCell_NumberOfItems"
                public static let completes: InspectedAttribute.Identifier = "NSCell_NSComboBoxCell_Completes"
                public static let objectValues: InspectedAttribute.Identifier = "NSCell_NSComboBoxCell_ObjectValues"
            }

            public enum NSPathComponentCell {
                public static let image: InspectedAttribute.Identifier = "NSCell_NSPathComponentCell_Image"
                public static let url: InspectedAttribute.Identifier = "NSCell_NSPathComponentCell_URL"
            }

            public enum NSSearchFieldCell {
                public static let searchMenuTemplate: InspectedAttribute.Identifier = "NSCell_NSSearchFieldCell_SearchMenuTemplate"
                public static let sendsWholeSearchString: InspectedAttribute.Identifier = "NSCell_NSSearchFieldCell_SendsWholeSearchString"
                public static let maximumRecents: InspectedAttribute.Identifier = "NSCell_NSSearchFieldCell_MaximumRecents"
                public static let recentSearches: InspectedAttribute.Identifier = "NSCell_NSSearchFieldCell_RecentSearches"
                public static let sendsSearchStringImmediately: InspectedAttribute.Identifier = "NSCell_NSSearchFieldCell_SendsSearchStringImmediately"
            }

            public enum NSSecureTextFieldCell {
                public static let echosBullets: InspectedAttribute.Identifier = "NSCell_NSSecureTextFieldCell_EchosBullets"
            }

            public enum NSTokenFieldCell {
                public static let tokenStyle: InspectedAttribute.Identifier = "NSCell_NSTokenFieldCell_TokenStyle"
                public static let completionDelay: InspectedAttribute.Identifier = "NSCell_NSTokenFieldCell_CompletionDelay"
            }

            public enum NSBrowserCell {
                public static let leaf: InspectedAttribute.Identifier = "NSCell_NSBrowserCell_Leaf"
                public static let loaded: InspectedAttribute.Identifier = "NSCell_NSBrowserCell_Loaded"
                public static let image: InspectedAttribute.Identifier = "NSCell_NSBrowserCell_Image"
                public static let alternateImage: InspectedAttribute.Identifier = "NSCell_NSBrowserCell_AlternateImage"
            }

            public enum NSImageCell {
                public static let imageAlignment: InspectedAttribute.Identifier = "NSCell_NSImageCell_ImageAlignment"
                public static let imageScaling: InspectedAttribute.Identifier = "NSCell_NSImageCell_ImageScaling"
                public static let imageFrameStyle: InspectedAttribute.Identifier = "NSCell_NSImageCell_ImageFrameStyle"
            }
        }

        public enum UISlider {
            public enum BehavioralStyle {
                public static let behavioralStyle: InspectedAttribute.Identifier = "UISlider_BehavioralStyle_BehavioralStyle"
            }

            public enum PreferredBehavioralStyle {
                public static let preferredBehavioralStyle: InspectedAttribute.Identifier = "UISlider_PreferredBehavioralStyle_PreferredBehavioralStyle"
            }

            public enum Value {
                public static let value: InspectedAttribute.Identifier = "UISlider_Value_Value"
                public static let minimumValue: InspectedAttribute.Identifier = "UISlider_Value_MinimumValue"
                public static let maximumValue: InspectedAttribute.Identifier = "UISlider_Value_MaximumValue"
            }

            public enum Images {
                public static let minimumValueImage: InspectedAttribute.Identifier = "UISlider_Images_MinimumValueImage"
                public static let maximumValueImage: InspectedAttribute.Identifier = "UISlider_Images_MaximumValueImage"
                public static let currentThumbImage: InspectedAttribute.Identifier = "UISlider_Images_CurrentThumbImage"
                public static let currentMinimumTrackImage: InspectedAttribute.Identifier = "UISlider_Images_CurrentMinimumTrackImage"
                public static let currentMaximumTrackImage: InspectedAttribute.Identifier = "UISlider_Images_CurrentMaximumTrackImage"
            }

            public enum Continuous {
                public static let continuous: InspectedAttribute.Identifier = "UISlider_Continuous_Continuous"
            }

            public enum SliderStyle {
                public static let sliderStyle: InspectedAttribute.Identifier = "UISlider_SliderStyle_SliderStyle"
            }

            public enum Colors {
                public static let minimumTrackTintColor: InspectedAttribute.Identifier = "UISlider_Colors_MinimumTrackTintColor"
                public static let maximumTrackTintColor: InspectedAttribute.Identifier = "UISlider_Colors_MaximumTrackTintColor"
                public static let thumbTintColor: InspectedAttribute.Identifier = "UISlider_Colors_ThumbTintColor"
            }
        }

        public enum UIStepper {
            public enum Behavior {
                public static let continuous: InspectedAttribute.Identifier = "UIStepper_Behavior_Continuous"
                public static let autorepeat: InspectedAttribute.Identifier = "UIStepper_Behavior_Autorepeat"
                public static let wraps: InspectedAttribute.Identifier = "UIStepper_Behavior_Wraps"
            }

            public enum Value {
                public static let value: InspectedAttribute.Identifier = "UIStepper_Value_Value"
                public static let minimumValue: InspectedAttribute.Identifier = "UIStepper_Value_MinimumValue"
                public static let maximumValue: InspectedAttribute.Identifier = "UIStepper_Value_MaximumValue"
                public static let stepValue: InspectedAttribute.Identifier = "UIStepper_Value_StepValue"
            }
        }

        public enum UISwitch {
            public enum Colors {
                public static let onTintColor: InspectedAttribute.Identifier = "UISwitch_Colors_OnTintColor"
                public static let thumbTintColor: InspectedAttribute.Identifier = "UISwitch_Colors_ThumbTintColor"
            }

            public enum Images {
                public static let onImage: InspectedAttribute.Identifier = "UISwitch_Images_OnImage"
                public static let offImage: InspectedAttribute.Identifier = "UISwitch_Images_OffImage"
            }

            public enum Title {
                public static let title: InspectedAttribute.Identifier = "UISwitch_Title_Title"
            }

            public enum Style {
                public static let style: InspectedAttribute.Identifier = "UISwitch_Style_Style"
            }

            public enum PreferredStyle {
                public static let preferredStyle: InspectedAttribute.Identifier = "UISwitch_PreferredStyle_PreferredStyle"
            }

            public enum On {
                public static let on: InspectedAttribute.Identifier = "UISwitch_On_On"
            }
        }

        public enum UISegmentedControl {
            public enum Behavior {
                public static let momentary: InspectedAttribute.Identifier = "UISegmentedControl_Behavior_Momentary"
                public static let apportionsSegmentWidthsByContent: InspectedAttribute.Identifier = "UISegmentedControl_Behavior_ApportionsSegmentWidthsByContent"
            }

            public enum NumberOfSegments {
                public static let numberOfSegments: InspectedAttribute.Identifier = "UISegmentedControl_NumberOfSegments_NumberOfSegments"
            }

            public enum SelectedSegmentIndex {
                public static let selectedSegmentIndex: InspectedAttribute.Identifier = "UISegmentedControl_SelectedSegmentIndex_SelectedSegmentIndex"
            }

            public enum SelectedSegmentTintColor {
                public static let selectedSegmentTintColor: InspectedAttribute.Identifier = "UISegmentedControl_SelectedSegmentTintColor_SelectedSegmentTintColor"
            }
        }

        public enum UIProgressView {
            public enum ProgressViewStyle {
                public static let progressViewStyle: InspectedAttribute.Identifier = "UIProgressView_ProgressViewStyle_ProgressViewStyle"
            }

            public enum Progress {
                public static let progress: InspectedAttribute.Identifier = "UIProgressView_Progress_Progress"
            }

            public enum Colors {
                public static let progressTintColor: InspectedAttribute.Identifier = "UIProgressView_Colors_ProgressTintColor"
                public static let trackTintColor: InspectedAttribute.Identifier = "UIProgressView_Colors_TrackTintColor"
            }

            public enum Images {
                public static let progressImage: InspectedAttribute.Identifier = "UIProgressView_Images_ProgressImage"
                public static let trackImage: InspectedAttribute.Identifier = "UIProgressView_Images_TrackImage"
            }
        }

        public enum UIActivityIndicatorView {
            public enum ActivityIndicatorViewStyle {
                public static let activityIndicatorViewStyle: InspectedAttribute.Identifier = "UIActivityIndicatorView_ActivityIndicatorViewStyle_ActivityIndicatorViewStyle"
            }

            public enum Behavior {
                public static let hidesWhenStopped: InspectedAttribute.Identifier = "UIActivityIndicatorView_Behavior_HidesWhenStopped"
                public static let animating: InspectedAttribute.Identifier = "UIActivityIndicatorView_Behavior_Animating"
            }

            public enum Color {
                public static let color: InspectedAttribute.Identifier = "UIActivityIndicatorView_Color_Color"
            }
        }

        public enum UIPageControl {
            public enum NumberOfPages {
                public static let numberOfPages: InspectedAttribute.Identifier = "UIPageControl_NumberOfPages_NumberOfPages"
            }

            public enum CurrentPage {
                public static let currentPage: InspectedAttribute.Identifier = "UIPageControl_CurrentPage_CurrentPage"
            }

            public enum Behavior {
                public static let hidesForSinglePage: InspectedAttribute.Identifier = "UIPageControl_Behavior_HidesForSinglePage"
                public static let allowsContinuousInteraction: InspectedAttribute.Identifier = "UIPageControl_Behavior_AllowsContinuousInteraction"
            }

            public enum Colors {
                public static let pageIndicatorTintColor: InspectedAttribute.Identifier = "UIPageControl_Colors_PageIndicatorTintColor"
                public static let currentPageIndicatorTintColor: InspectedAttribute.Identifier = "UIPageControl_Colors_CurrentPageIndicatorTintColor"
            }

            public enum BackgroundStyle {
                public static let backgroundStyle: InspectedAttribute.Identifier = "UIPageControl_BackgroundStyle_BackgroundStyle"
            }

            public enum Direction {
                public static let direction: InspectedAttribute.Identifier = "UIPageControl_Direction_Direction"
            }

            public enum InteractionState {
                public static let interactionState: InspectedAttribute.Identifier = "UIPageControl_InteractionState_InteractionState"
            }

            public enum Images {
                public static let preferredIndicatorImage: InspectedAttribute.Identifier = "UIPageControl_Images_PreferredIndicatorImage"
                public static let preferredCurrentPageIndicatorImage: InspectedAttribute.Identifier = "UIPageControl_Images_PreferredCurrentPageIndicatorImage"
            }
        }

        public enum UIDatePicker {
            public enum DatePickerMode {
                public static let datePickerMode: InspectedAttribute.Identifier = "UIDatePicker_DatePickerMode_DatePickerMode"
            }

            public enum Locale {
                public static let locale: InspectedAttribute.Identifier = "UIDatePicker_Locale_Locale"
            }

            public enum Calendar {
                public static let calendar: InspectedAttribute.Identifier = "UIDatePicker_Calendar_Calendar"
            }

            public enum TimeZone {
                public static let timeZone: InspectedAttribute.Identifier = "UIDatePicker_TimeZone_TimeZone"
            }

            public enum Date {
                public static let date: InspectedAttribute.Identifier = "UIDatePicker_Date_Date"
            }

            public enum MinimumDate {
                public static let minimumDate: InspectedAttribute.Identifier = "UIDatePicker_MinimumDate_MinimumDate"
            }

            public enum MaximumDate {
                public static let maximumDate: InspectedAttribute.Identifier = "UIDatePicker_MaximumDate_MaximumDate"
            }

            public enum CountDownDuration {
                public static let countDownDuration: InspectedAttribute.Identifier = "UIDatePicker_CountDownDuration_CountDownDuration"
            }

            public enum MinuteInterval {
                public static let minuteInterval: InspectedAttribute.Identifier = "UIDatePicker_MinuteInterval_MinuteInterval"
            }

            public enum PreferredDatePickerStyle {
                public static let preferredDatePickerStyle: InspectedAttribute.Identifier = "UIDatePicker_PreferredDatePickerStyle_PreferredDatePickerStyle"
            }

            public enum DatePickerStyle {
                public static let datePickerStyle: InspectedAttribute.Identifier = "UIDatePicker_DatePickerStyle_DatePickerStyle"
            }

            public enum RoundsToMinuteInterval {
                public static let roundsToMinuteInterval: InspectedAttribute.Identifier = "UIDatePicker_RoundsToMinuteInterval_RoundsToMinuteInterval"
            }
        }

        public enum UIColorWell {
            public enum Title {
                public static let title: InspectedAttribute.Identifier = "UIColorWell_Title_Title"
            }

            public enum Behavior {
                public static let supportsAlpha: InspectedAttribute.Identifier = "UIColorWell_Behavior_SupportsAlpha"
                public static let supportsEyedropper: InspectedAttribute.Identifier = "UIColorWell_Behavior_SupportsEyedropper"
            }

            public enum SelectedColor {
                public static let selectedColor: InspectedAttribute.Identifier = "UIColorWell_SelectedColor_SelectedColor"
            }

            public enum MaximumLinearExposure {
                public static let maximumLinearExposure: InspectedAttribute.Identifier = "UIColorWell_MaximumLinearExposure_MaximumLinearExposure"
            }
        }

        public enum UIRefreshControl {
            public enum Refreshing {
                public static let refreshing: InspectedAttribute.Identifier = "UIRefreshControl_Refreshing_Refreshing"
            }

            public enum AttributedTitle {
                public static let attributedTitle: InspectedAttribute.Identifier = "UIRefreshControl_AttributedTitle_AttributedTitle"
            }
        }

        public enum UIPickerView {
            public enum NumberOfComponents {
                public static let numberOfComponents: InspectedAttribute.Identifier = "UIPickerView_NumberOfComponents_NumberOfComponents"
            }
        }

        public enum UICalendarView {
            public enum Locale {
                public static let locale: InspectedAttribute.Identifier = "UICalendarView_Locale_Locale"
            }

            public enum Calendar {
                public static let calendar: InspectedAttribute.Identifier = "UICalendarView_Calendar_Calendar"
            }

            public enum TimeZone {
                public static let timeZone: InspectedAttribute.Identifier = "UICalendarView_TimeZone_TimeZone"
            }

            public enum FontDesign {
                public static let fontDesign: InspectedAttribute.Identifier = "UICalendarView_FontDesign_FontDesign"
            }

            public enum WantsDateDecorations {
                public static let wantsDateDecorations: InspectedAttribute.Identifier = "UICalendarView_WantsDateDecorations_WantsDateDecorations"
            }
        }

        public enum UIPasteControl {
            public enum Configuration {
                public static let configuration: InspectedAttribute.Identifier = "UIPasteControl_Configuration_Configuration"
            }
        }

        public enum UICollectionView {
            public enum Behavior {
                public static let prefetchingEnabled: InspectedAttribute.Identifier = "UICollectionView_Behavior_PrefetchingEnabled"
                public static let dragInteractionEnabled: InspectedAttribute.Identifier = "UICollectionView_Behavior_DragInteractionEnabled"
                public static let allowsSelection: InspectedAttribute.Identifier = "UICollectionView_Behavior_AllowsSelection"
                public static let allowsMultipleSelection: InspectedAttribute.Identifier = "UICollectionView_Behavior_AllowsMultipleSelection"
                public static let hasUncommittedUpdates: InspectedAttribute.Identifier = "UICollectionView_Behavior_HasUncommittedUpdates"
                public static let remembersLastFocusedIndexPath: InspectedAttribute.Identifier = "UICollectionView_Behavior_RemembersLastFocusedIndexPath"
                public static let selectionFollowsFocus: InspectedAttribute.Identifier = "UICollectionView_Behavior_SelectionFollowsFocus"
                public static let allowsFocus: InspectedAttribute.Identifier = "UICollectionView_Behavior_AllowsFocus"
                public static let allowsFocusDuringEditing: InspectedAttribute.Identifier = "UICollectionView_Behavior_AllowsFocusDuringEditing"
                public static let hasActiveDrag: InspectedAttribute.Identifier = "UICollectionView_Behavior_HasActiveDrag"
                public static let hasActiveDrop: InspectedAttribute.Identifier = "UICollectionView_Behavior_HasActiveDrop"
                public static let editing: InspectedAttribute.Identifier = "UICollectionView_Behavior_Editing"
                public static let allowsSelectionDuringEditing: InspectedAttribute.Identifier = "UICollectionView_Behavior_AllowsSelectionDuringEditing"
                public static let allowsMultipleSelectionDuringEditing: InspectedAttribute.Identifier = "UICollectionView_Behavior_AllowsMultipleSelectionDuringEditing"
            }

            public enum ReorderingCadence {
                public static let reorderingCadence: InspectedAttribute.Identifier = "UICollectionView_ReorderingCadence_ReorderingCadence"
            }

            public enum SelfSizingInvalidation {
                public static let selfSizingInvalidation: InspectedAttribute.Identifier = "UICollectionView_SelfSizingInvalidation_SelfSizingInvalidation"
            }

            public enum IndexPathsForSelectedItems {
                public static let indexPathsForSelectedItems: InspectedAttribute.Identifier = "UICollectionView_IndexPathsForSelectedItems_IndexPathsForSelectedItems"
            }

            public enum NumberOfSections {
                public static let numberOfSections: InspectedAttribute.Identifier = "UICollectionView_NumberOfSections_NumberOfSections"
            }
        }

        public enum UICollectionReusableView {
            public enum ReuseIdentifier {
                public static let reuseIdentifier: InspectedAttribute.Identifier = "UICollectionReusableView_ReuseIdentifier_ReuseIdentifier"
            }

            public enum UICollectionViewCell {
                public static let automaticallyUpdatesContentConfiguration: InspectedAttribute.Identifier = "UICollectionReusableView_UICollectionViewCell_AutomaticallyUpdatesContentConfiguration"
                public static let selected: InspectedAttribute.Identifier = "UICollectionReusableView_UICollectionViewCell_Selected"
                public static let highlighted: InspectedAttribute.Identifier = "UICollectionReusableView_UICollectionViewCell_Highlighted"
                public static let backgroundConfiguration: InspectedAttribute.Identifier = "UICollectionReusableView_UICollectionViewCell_BackgroundConfiguration"
                public static let automaticallyUpdatesBackgroundConfiguration: InspectedAttribute.Identifier = "UICollectionReusableView_UICollectionViewCell_AutomaticallyUpdatesBackgroundConfiguration"
            }

            public enum UICollectionViewListCell {
                public static let indentationLevel: InspectedAttribute.Identifier = "UICollectionReusableView_UICollectionViewListCell_IndentationLevel"
                public static let indentationWidth: InspectedAttribute.Identifier = "UICollectionReusableView_UICollectionViewListCell_IndentationWidth"
                public static let indentsAccessories: InspectedAttribute.Identifier = "UICollectionReusableView_UICollectionViewListCell_IndentsAccessories"
                public static let accessories: InspectedAttribute.Identifier = "UICollectionReusableView_UICollectionViewListCell_Accessories"
            }
        }

        public enum UITableViewCell {
            public enum Behavior {
                public static let automaticallyUpdatesContentConfiguration: InspectedAttribute.Identifier = "UITableViewCell_Behavior_AutomaticallyUpdatesContentConfiguration"
                public static let automaticallyUpdatesBackgroundConfiguration: InspectedAttribute.Identifier = "UITableViewCell_Behavior_AutomaticallyUpdatesBackgroundConfiguration"
                public static let selected: InspectedAttribute.Identifier = "UITableViewCell_Behavior_Selected"
                public static let highlighted: InspectedAttribute.Identifier = "UITableViewCell_Behavior_Highlighted"
                public static let showsReorderControl: InspectedAttribute.Identifier = "UITableViewCell_Behavior_ShowsReorderControl"
                public static let shouldIndentWhileEditing: InspectedAttribute.Identifier = "UITableViewCell_Behavior_ShouldIndentWhileEditing"
                public static let editing: InspectedAttribute.Identifier = "UITableViewCell_Behavior_Editing"
                public static let showingDeleteConfirmation: InspectedAttribute.Identifier = "UITableViewCell_Behavior_ShowingDeleteConfirmation"
                public static let userInteractionEnabledWhileDragging: InspectedAttribute.Identifier = "UITableViewCell_Behavior_UserInteractionEnabledWhileDragging"
            }

            public enum BackgroundConfiguration {
                public static let backgroundConfiguration: InspectedAttribute.Identifier = "UITableViewCell_BackgroundConfiguration_BackgroundConfiguration"
            }

            public enum ReuseIdentifier {
                public static let reuseIdentifier: InspectedAttribute.Identifier = "UITableViewCell_ReuseIdentifier_ReuseIdentifier"
            }

            public enum SelectionStyle {
                public static let selectionStyle: InspectedAttribute.Identifier = "UITableViewCell_SelectionStyle_SelectionStyle"
            }

            public enum EditingStyle {
                public static let editingStyle: InspectedAttribute.Identifier = "UITableViewCell_EditingStyle_EditingStyle"
            }

            public enum AccessoryType {
                public static let accessoryType: InspectedAttribute.Identifier = "UITableViewCell_AccessoryType_AccessoryType"
            }

            public enum EditingAccessoryType {
                public static let editingAccessoryType: InspectedAttribute.Identifier = "UITableViewCell_EditingAccessoryType_EditingAccessoryType"
            }

            public enum IndentationLevel {
                public static let indentationLevel: InspectedAttribute.Identifier = "UITableViewCell_IndentationLevel_IndentationLevel"
            }

            public enum IndentationWidth {
                public static let indentationWidth: InspectedAttribute.Identifier = "UITableViewCell_IndentationWidth_IndentationWidth"
            }

            public enum SeparatorInset {
                public static let separatorInset: InspectedAttribute.Identifier = "UITableViewCell_SeparatorInset_SeparatorInset"
            }

            public enum FocusStyle {
                public static let focusStyle: InspectedAttribute.Identifier = "UITableViewCell_FocusStyle_FocusStyle"
            }
        }

        public enum UITableViewHeaderFooterView {
            public enum Behavior {
                public static let automaticallyUpdatesContentConfiguration: InspectedAttribute.Identifier = "UITableViewHeaderFooterView_Behavior_AutomaticallyUpdatesContentConfiguration"
                public static let automaticallyUpdatesBackgroundConfiguration: InspectedAttribute.Identifier = "UITableViewHeaderFooterView_Behavior_AutomaticallyUpdatesBackgroundConfiguration"
            }

            public enum BackgroundConfiguration {
                public static let backgroundConfiguration: InspectedAttribute.Identifier = "UITableViewHeaderFooterView_BackgroundConfiguration_BackgroundConfiguration"
            }

            public enum ReuseIdentifier {
                public static let reuseIdentifier: InspectedAttribute.Identifier = "UITableViewHeaderFooterView_ReuseIdentifier_ReuseIdentifier"
            }
        }

        public enum UINavigationBar {
            public enum BarStyle {
                public static let barStyle: InspectedAttribute.Identifier = "UINavigationBar_BarStyle_BarStyle"
            }

            public enum Behavior {
                public static let translucent: InspectedAttribute.Identifier = "UINavigationBar_Behavior_Translucent"
                public static let prefersLargeTitles: InspectedAttribute.Identifier = "UINavigationBar_Behavior_PrefersLargeTitles"
            }

            public enum TopItem {
                public static let topItem: InspectedAttribute.Identifier = "UINavigationBar_TopItem_TopItem"
            }

            public enum BackItem {
                public static let backItem: InspectedAttribute.Identifier = "UINavigationBar_BackItem_BackItem"
            }

            public enum CurrentNSToolbarSection {
                public static let currentNSToolbarSection: InspectedAttribute.Identifier = "UINavigationBar_CurrentNSToolbarSection_CurrentNSToolbarSection"
            }

            public enum BehavioralStyle {
                public static let behavioralStyle: InspectedAttribute.Identifier = "UINavigationBar_BehavioralStyle_BehavioralStyle"
            }

            public enum PreferredBehavioralStyle {
                public static let preferredBehavioralStyle: InspectedAttribute.Identifier = "UINavigationBar_PreferredBehavioralStyle_PreferredBehavioralStyle"
            }

            public enum BarTintColor {
                public static let barTintColor: InspectedAttribute.Identifier = "UINavigationBar_BarTintColor_BarTintColor"
            }

            public enum Images {
                public static let shadowImage: InspectedAttribute.Identifier = "UINavigationBar_Images_ShadowImage"
                public static let backIndicatorImage: InspectedAttribute.Identifier = "UINavigationBar_Images_BackIndicatorImage"
                public static let backIndicatorTransitionMaskImage: InspectedAttribute.Identifier = "UINavigationBar_Images_BackIndicatorTransitionMaskImage"
            }
        }

        public enum UITabBar {
            public enum SelectedItem {
                public static let selectedItem: InspectedAttribute.Identifier = "UITabBar_SelectedItem_SelectedItem"
            }

            public enum Behavior {
                public static let customizing: InspectedAttribute.Identifier = "UITabBar_Behavior_Customizing"
                public static let translucent: InspectedAttribute.Identifier = "UITabBar_Behavior_Translucent"
            }

            public enum Colors {
                public static let barTintColor: InspectedAttribute.Identifier = "UITabBar_Colors_BarTintColor"
                public static let unselectedItemTintColor: InspectedAttribute.Identifier = "UITabBar_Colors_UnselectedItemTintColor"
            }

            public enum Images {
                public static let backgroundImage: InspectedAttribute.Identifier = "UITabBar_Images_BackgroundImage"
                public static let selectionIndicatorImage: InspectedAttribute.Identifier = "UITabBar_Images_SelectionIndicatorImage"
                public static let shadowImage: InspectedAttribute.Identifier = "UITabBar_Images_ShadowImage"
            }

            public enum ItemPositioning {
                public static let itemPositioning: InspectedAttribute.Identifier = "UITabBar_ItemPositioning_ItemPositioning"
            }

            public enum ItemWidth {
                public static let itemWidth: InspectedAttribute.Identifier = "UITabBar_ItemWidth_ItemWidth"
            }

            public enum ItemSpacing {
                public static let itemSpacing: InspectedAttribute.Identifier = "UITabBar_ItemSpacing_ItemSpacing"
            }

            public enum BarStyle {
                public static let barStyle: InspectedAttribute.Identifier = "UITabBar_BarStyle_BarStyle"
            }
        }

        public enum UIToolbar {
            public enum BarStyle {
                public static let barStyle: InspectedAttribute.Identifier = "UIToolbar_BarStyle_BarStyle"
            }

            public enum Translucent {
                public static let translucent: InspectedAttribute.Identifier = "UIToolbar_Translucent_Translucent"
            }

            public enum BarTintColor {
                public static let barTintColor: InspectedAttribute.Identifier = "UIToolbar_BarTintColor_BarTintColor"
            }
        }

        public enum UISearchBar {
            public enum BarStyle {
                public static let barStyle: InspectedAttribute.Identifier = "UISearchBar_BarStyle_BarStyle"
            }

            public enum Text {
                public static let text: InspectedAttribute.Identifier = "UISearchBar_Text_Text"
            }

            public enum Prompt {
                public static let prompt: InspectedAttribute.Identifier = "UISearchBar_Prompt_Prompt"
            }

            public enum Placeholder {
                public static let placeholder: InspectedAttribute.Identifier = "UISearchBar_Placeholder_Placeholder"
            }

            public enum Behavior {
                public static let showsBookmarkButton: InspectedAttribute.Identifier = "UISearchBar_Behavior_ShowsBookmarkButton"
                public static let showsCancelButton: InspectedAttribute.Identifier = "UISearchBar_Behavior_ShowsCancelButton"
                public static let showsSearchResultsButton: InspectedAttribute.Identifier = "UISearchBar_Behavior_ShowsSearchResultsButton"
                public static let searchResultsButtonSelected: InspectedAttribute.Identifier = "UISearchBar_Behavior_SearchResultsButtonSelected"
                public static let translucent: InspectedAttribute.Identifier = "UISearchBar_Behavior_Translucent"
                public static let showsScopeBar: InspectedAttribute.Identifier = "UISearchBar_Behavior_ShowsScopeBar"
                public static let enabled: InspectedAttribute.Identifier = "UISearchBar_Behavior_Enabled"
                public static let lookToDictateEnabled: InspectedAttribute.Identifier = "UISearchBar_Behavior_LookToDictateEnabled"
            }

            public enum BarTintColor {
                public static let barTintColor: InspectedAttribute.Identifier = "UISearchBar_BarTintColor_BarTintColor"
            }

            public enum SearchBarStyle {
                public static let searchBarStyle: InspectedAttribute.Identifier = "UISearchBar_SearchBarStyle_SearchBarStyle"
            }

            public enum ScopeButtonTitles {
                public static let scopeButtonTitles: InspectedAttribute.Identifier = "UISearchBar_ScopeButtonTitles_ScopeButtonTitles"
            }

            public enum SelectedScopeButtonIndex {
                public static let selectedScopeButtonIndex: InspectedAttribute.Identifier = "UISearchBar_SelectedScopeButtonIndex_SelectedScopeButtonIndex"
            }

            public enum Images {
                public static let backgroundImage: InspectedAttribute.Identifier = "UISearchBar_Images_BackgroundImage"
                public static let scopeBarBackgroundImage: InspectedAttribute.Identifier = "UISearchBar_Images_ScopeBarBackgroundImage"
            }

            public enum SearchFieldBackgroundPositionAdjustment {
                public static let searchFieldBackgroundPositionAdjustment: InspectedAttribute.Identifier = "UISearchBar_SearchFieldBackgroundPositionAdjustment_SearchFieldBackgroundPositionAdjustment"
            }

            public enum SearchTextPositionAdjustment {
                public static let searchTextPositionAdjustment: InspectedAttribute.Identifier = "UISearchBar_SearchTextPositionAdjustment_SearchTextPositionAdjustment"
            }
        }

        public enum UIInputView {
            public enum InputViewStyle {
                public static let inputViewStyle: InspectedAttribute.Identifier = "UIInputView_InputViewStyle_InputViewStyle"
            }

            public enum AllowsSelfSizing {
                public static let allowsSelfSizing: InspectedAttribute.Identifier = "UIInputView_AllowsSelfSizing_AllowsSelfSizing"
            }
        }

        public enum UIContentUnavailableView {
            public enum Configuration {
                public static let configuration: InspectedAttribute.Identifier = "UIContentUnavailableView_Configuration_Configuration"
            }

            public enum ScrollEnabled {
                public static let scrollEnabled: InspectedAttribute.Identifier = "UIContentUnavailableView_ScrollEnabled_ScrollEnabled"
            }
        }

        public enum UIBackgroundExtensionView {
            public enum AutomaticallyPlacesContentView {
                public static let automaticallyPlacesContentView: InspectedAttribute.Identifier = "UIBackgroundExtensionView_AutomaticallyPlacesContentView_AutomaticallyPlacesContentView"
            }
        }

        public enum UIWindow {
            public enum Behavior {
                public static let canResizeToFitContent: InspectedAttribute.Identifier = "UIWindow_Behavior_CanResizeToFitContent"
                public static let keyWindow: InspectedAttribute.Identifier = "UIWindow_Behavior_KeyWindow"
                public static let canBecomeKeyWindow: InspectedAttribute.Identifier = "UIWindow_Behavior_CanBecomeKeyWindow"
            }

            public enum WindowLevel {
                public static let windowLevel: InspectedAttribute.Identifier = "UIWindow_WindowLevel_WindowLevel"
            }

            public enum RootViewController {
                public static let rootViewController: InspectedAttribute.Identifier = "UIWindow_RootViewController_RootViewController"
            }
        }

        public enum UIView {
            public enum Behavior {
                public static let accessibilityIgnoresInvertColors: InspectedAttribute.Identifier = "UIView_Behavior_AccessibilityIgnoresInvertColors"
                public static let showsLargeContentViewer: InspectedAttribute.Identifier = "UIView_Behavior_ShowsLargeContentViewer"
                public static let scalesLargeContentImage: InspectedAttribute.Identifier = "UIView_Behavior_ScalesLargeContentImage"
                public static let canBecomeFocused: InspectedAttribute.Identifier = "UIView_Behavior_CanBecomeFocused"
                public static let focused: InspectedAttribute.Identifier = "UIView_Behavior_Focused"
                public static let multipleTouchEnabled: InspectedAttribute.Identifier = "UIView_Behavior_MultipleTouchEnabled"
                public static let exclusiveTouch: InspectedAttribute.Identifier = "UIView_Behavior_ExclusiveTouch"
                public static let autoresizesSubviews: InspectedAttribute.Identifier = "UIView_Behavior_AutoresizesSubviews"
                public static let preservesSuperviewLayoutMargins: InspectedAttribute.Identifier = "UIView_Behavior_PreservesSuperviewLayoutMargins"
                public static let insetsLayoutMarginsFromSafeArea: InspectedAttribute.Identifier = "UIView_Behavior_InsetsLayoutMarginsFromSafeArea"
                public static let clearsContextBeforeDrawing: InspectedAttribute.Identifier = "UIView_Behavior_ClearsContextBeforeDrawing"
                public static let translatesAutoresizingMaskIntoConstraints: InspectedAttribute.Identifier = "UIView_Behavior_TranslatesAutoresizingMaskIntoConstraints"
            }

            public enum LargeContentTitle {
                public static let largeContentTitle: InspectedAttribute.Identifier = "UIView_LargeContentTitle_LargeContentTitle"
            }

            public enum LargeContentImageInsets {
                public static let largeContentImageInsets: InspectedAttribute.Identifier = "UIView_LargeContentImageInsets_LargeContentImageInsets"
            }

            public enum FocusGroupIdentifier {
                public static let focusGroupIdentifier: InspectedAttribute.Identifier = "UIView_FocusGroupIdentifier_FocusGroupIdentifier"
            }

            public enum SemanticContentAttribute {
                public static let semanticContentAttribute: InspectedAttribute.Identifier = "UIView_SemanticContentAttribute_SemanticContentAttribute"
            }

            public enum EffectiveUserInterfaceLayoutDirection {
                public static let effectiveUserInterfaceLayoutDirection: InspectedAttribute.Identifier = "UIView_EffectiveUserInterfaceLayoutDirection_EffectiveUserInterfaceLayoutDirection"
            }

            public enum Transform {
                public static let transform: InspectedAttribute.Identifier = "UIView_Transform_Transform"
            }

            public enum Transform3D {
                public static let transform3D: InspectedAttribute.Identifier = "UIView_Transform3D_Transform3D"
            }

            public enum ContentScaleFactor {
                public static let contentScaleFactor: InspectedAttribute.Identifier = "UIView_ContentScaleFactor_ContentScaleFactor"
            }

            public enum AutoresizingMask {
                public static let autoresizingMask: InspectedAttribute.Identifier = "UIView_AutoresizingMask_AutoresizingMask"
            }

            public enum LayoutMargins {
                public static let layoutMargins: InspectedAttribute.Identifier = "UIView_LayoutMargins_LayoutMargins"
            }

            public enum DirectionalLayoutMargins {
                public static let directionalLayoutMargins: InspectedAttribute.Identifier = "UIView_DirectionalLayoutMargins_DirectionalLayoutMargins"
            }

            public enum AlignmentRectInsets {
                public static let alignmentRectInsets: InspectedAttribute.Identifier = "UIView_AlignmentRectInsets_AlignmentRectInsets"
            }

            public enum RestorationIdentifier {
                public static let restorationIdentifier: InspectedAttribute.Identifier = "UIView_RestorationIdentifier_RestorationIdentifier"
            }

            public enum OverrideUserInterfaceStyle {
                public static let overrideUserInterfaceStyle: InspectedAttribute.Identifier = "UIView_OverrideUserInterfaceStyle_OverrideUserInterfaceStyle"
            }

            public enum MinimumContentSizeCategory {
                public static let minimumContentSizeCategory: InspectedAttribute.Identifier = "UIView_MinimumContentSizeCategory_MinimumContentSizeCategory"
            }

            public enum MaximumContentSizeCategory {
                public static let maximumContentSizeCategory: InspectedAttribute.Identifier = "UIView_MaximumContentSizeCategory_MaximumContentSizeCategory"
            }

            public enum AppliedContentSizeCategoryLimitsDescription {
                public static let appliedContentSizeCategoryLimitsDescription: InspectedAttribute.Identifier = "UIView_AppliedContentSizeCategoryLimitsDescription_AppliedContentSizeCategoryLimitsDescription"
            }

            public enum CornerConfiguration {
                public static let cornerConfiguration: InspectedAttribute.Identifier = "UIView_CornerConfiguration_CornerConfiguration"
            }
        }

        public enum NSClipView {
            public enum BackgroundColor {
                public static let backgroundColor: InspectedAttribute.Identifier = "NSClipView_BackgroundColor_BackgroundColor"
            }

            public enum Behavior {
                public static let drawsBackground: InspectedAttribute.Identifier = "NSClipView_Behavior_DrawsBackground"
                public static let automaticallyAdjustsContentInsets: InspectedAttribute.Identifier = "NSClipView_Behavior_AutomaticallyAdjustsContentInsets"
            }

            public enum DocumentRect {
                public static let documentRect: InspectedAttribute.Identifier = "NSClipView_DocumentRect_DocumentRect"
            }

            public enum DocumentVisibleRect {
                public static let documentVisibleRect: InspectedAttribute.Identifier = "NSClipView_DocumentVisibleRect_DocumentVisibleRect"
            }

            public enum ContentInsets {
                public static let contentInsets: InspectedAttribute.Identifier = "NSClipView_ContentInsets_ContentInsets"
            }
        }

        public enum NSScroller {
            public enum ScrollerStyle {
                public static let scrollerStyle: InspectedAttribute.Identifier = "NSScroller_ScrollerStyle_ScrollerStyle"
            }

            public enum KnobStyle {
                public static let knobStyle: InspectedAttribute.Identifier = "NSScroller_KnobStyle_KnobStyle"
            }

            public enum UsableParts {
                public static let usableParts: InspectedAttribute.Identifier = "NSScroller_UsableParts_UsableParts"
            }

            public enum ControlSize {
                public static let controlSize: InspectedAttribute.Identifier = "NSScroller_ControlSize_ControlSize"
            }

            public enum HitPart {
                public static let hitPart: InspectedAttribute.Identifier = "NSScroller_HitPart_HitPart"
            }

            public enum KnobProportion {
                public static let knobProportion: InspectedAttribute.Identifier = "NSScroller_KnobProportion_KnobProportion"
            }
        }

        public enum NSBrowser {
            public enum Behavior {
                public static let loaded: InspectedAttribute.Identifier = "NSBrowser_Behavior_Loaded"
                public static let reusesColumns: InspectedAttribute.Identifier = "NSBrowser_Behavior_ReusesColumns"
                public static let hasHorizontalScroller: InspectedAttribute.Identifier = "NSBrowser_Behavior_HasHorizontalScroller"
                public static let autohidesScroller: InspectedAttribute.Identifier = "NSBrowser_Behavior_AutohidesScroller"
                public static let separatesColumns: InspectedAttribute.Identifier = "NSBrowser_Behavior_SeparatesColumns"
                public static let titled: InspectedAttribute.Identifier = "NSBrowser_Behavior_Titled"
                public static let allowsMultipleSelection: InspectedAttribute.Identifier = "NSBrowser_Behavior_AllowsMultipleSelection"
                public static let allowsBranchSelection: InspectedAttribute.Identifier = "NSBrowser_Behavior_AllowsBranchSelection"
                public static let allowsEmptySelection: InspectedAttribute.Identifier = "NSBrowser_Behavior_AllowsEmptySelection"
                public static let takesTitleFromPreviousColumn: InspectedAttribute.Identifier = "NSBrowser_Behavior_TakesTitleFromPreviousColumn"
                public static let sendsActionOnArrowKeys: InspectedAttribute.Identifier = "NSBrowser_Behavior_SendsActionOnArrowKeys"
                public static let prefersAllColumnUserResizing: InspectedAttribute.Identifier = "NSBrowser_Behavior_PrefersAllColumnUserResizing"
                public static let allowsTypeSelect: InspectedAttribute.Identifier = "NSBrowser_Behavior_AllowsTypeSelect"
            }

            public enum MinColumnWidth {
                public static let minColumnWidth: InspectedAttribute.Identifier = "NSBrowser_MinColumnWidth_MinColumnWidth"
            }

            public enum MaxVisibleColumns {
                public static let maxVisibleColumns: InspectedAttribute.Identifier = "NSBrowser_MaxVisibleColumns_MaxVisibleColumns"
            }

            public enum PathSeparator {
                public static let pathSeparator: InspectedAttribute.Identifier = "NSBrowser_PathSeparator_PathSeparator"
            }

            public enum ClickedColumn {
                public static let clickedColumn: InspectedAttribute.Identifier = "NSBrowser_ClickedColumn_ClickedColumn"
            }

            public enum ClickedRow {
                public static let clickedRow: InspectedAttribute.Identifier = "NSBrowser_ClickedRow_ClickedRow"
            }

            public enum SelectedColumn {
                public static let selectedColumn: InspectedAttribute.Identifier = "NSBrowser_SelectedColumn_SelectedColumn"
            }

            public enum LastColumn {
                public static let lastColumn: InspectedAttribute.Identifier = "NSBrowser_LastColumn_LastColumn"
            }

            public enum NumberOfVisibleColumns {
                public static let numberOfVisibleColumns: InspectedAttribute.Identifier = "NSBrowser_NumberOfVisibleColumns_NumberOfVisibleColumns"
            }

            public enum FirstVisibleColumn {
                public static let firstVisibleColumn: InspectedAttribute.Identifier = "NSBrowser_FirstVisibleColumn_FirstVisibleColumn"
            }

            public enum LastVisibleColumn {
                public static let lastVisibleColumn: InspectedAttribute.Identifier = "NSBrowser_LastVisibleColumn_LastVisibleColumn"
            }

            public enum TitleHeight {
                public static let titleHeight: InspectedAttribute.Identifier = "NSBrowser_TitleHeight_TitleHeight"
            }

            public enum ColumnResizingType {
                public static let columnResizingType: InspectedAttribute.Identifier = "NSBrowser_ColumnResizingType_ColumnResizingType"
            }

            public enum BackgroundColor {
                public static let backgroundColor: InspectedAttribute.Identifier = "NSBrowser_BackgroundColor_BackgroundColor"
            }
        }

        public enum NSMatrix {
            public enum Mode {
                public static let mode: InspectedAttribute.Identifier = "NSMatrix_Mode_Mode"
            }

            public enum Behavior {
                public static let allowsEmptySelection: InspectedAttribute.Identifier = "NSMatrix_Behavior_AllowsEmptySelection"
                public static let selectionByRect: InspectedAttribute.Identifier = "NSMatrix_Behavior_SelectionByRect"
                public static let drawsCellBackground: InspectedAttribute.Identifier = "NSMatrix_Behavior_DrawsCellBackground"
                public static let drawsBackground: InspectedAttribute.Identifier = "NSMatrix_Behavior_DrawsBackground"
                public static let autosizesCells: InspectedAttribute.Identifier = "NSMatrix_Behavior_AutosizesCells"
                public static let autoscroll: InspectedAttribute.Identifier = "NSMatrix_Behavior_Autoscroll"
                public static let autorecalculatesCellSize: InspectedAttribute.Identifier = "NSMatrix_Behavior_AutorecalculatesCellSize"
                public static let tabKeyTraversesCells: InspectedAttribute.Identifier = "NSMatrix_Behavior_TabKeyTraversesCells"
            }

            public enum SelectedRow {
                public static let selectedRow: InspectedAttribute.Identifier = "NSMatrix_SelectedRow_SelectedRow"
            }

            public enum SelectedColumn {
                public static let selectedColumn: InspectedAttribute.Identifier = "NSMatrix_SelectedColumn_SelectedColumn"
            }

            public enum CellSize {
                public static let cellSize: InspectedAttribute.Identifier = "NSMatrix_CellSize_CellSize"
            }

            public enum IntercellSpacing {
                public static let intercellSpacing: InspectedAttribute.Identifier = "NSMatrix_IntercellSpacing_IntercellSpacing"
            }

            public enum Colors {
                public static let backgroundColor: InspectedAttribute.Identifier = "NSMatrix_Colors_BackgroundColor"
                public static let cellBackgroundColor: InspectedAttribute.Identifier = "NSMatrix_Colors_CellBackgroundColor"
            }

            public enum NumberOfRows {
                public static let numberOfRows: InspectedAttribute.Identifier = "NSMatrix_NumberOfRows_NumberOfRows"
            }

            public enum NumberOfColumns {
                public static let numberOfColumns: InspectedAttribute.Identifier = "NSMatrix_NumberOfColumns_NumberOfColumns"
            }
        }

        public enum NSPathControl {
            public enum Editable {
                public static let editable: InspectedAttribute.Identifier = "NSPathControl_Editable_Editable"
            }

            public enum PlaceholderString {
                public static let placeholderString: InspectedAttribute.Identifier = "NSPathControl_PlaceholderString_PlaceholderString"
            }

            public enum URL {
                public static let url: InspectedAttribute.Identifier = "NSPathControl_URL_URL"
            }

            public enum PathStyle {
                public static let pathStyle: InspectedAttribute.Identifier = "NSPathControl_PathStyle_PathStyle"
            }

            public enum BackgroundColor {
                public static let backgroundColor: InspectedAttribute.Identifier = "NSPathControl_BackgroundColor_BackgroundColor"
            }

            public enum Menu {
                public static let menu: InspectedAttribute.Identifier = "NSPathControl_Menu_Menu"
            }
        }

        public enum NSRuleEditor {
            public enum NestingMode {
                public static let nestingMode: InspectedAttribute.Identifier = "NSRuleEditor_NestingMode_NestingMode"
            }

            public enum RowHeight {
                public static let rowHeight: InspectedAttribute.Identifier = "NSRuleEditor_RowHeight_RowHeight"
            }

            public enum Behavior {
                public static let editable: InspectedAttribute.Identifier = "NSRuleEditor_Behavior_Editable"
                public static let canRemoveAllRows: InspectedAttribute.Identifier = "NSRuleEditor_Behavior_CanRemoveAllRows"
            }

            public enum NumberOfRows {
                public static let numberOfRows: InspectedAttribute.Identifier = "NSRuleEditor_NumberOfRows_NumberOfRows"
            }
        }

        public enum NSSearchField {
            public enum SearchTextBounds {
                public static let searchTextBounds: InspectedAttribute.Identifier = "NSSearchField_SearchTextBounds_SearchTextBounds"
            }

            public enum SearchButtonBounds {
                public static let searchButtonBounds: InspectedAttribute.Identifier = "NSSearchField_SearchButtonBounds_SearchButtonBounds"
            }

            public enum CancelButtonBounds {
                public static let cancelButtonBounds: InspectedAttribute.Identifier = "NSSearchField_CancelButtonBounds_CancelButtonBounds"
            }

            public enum SearchMenuTemplate {
                public static let searchMenuTemplate: InspectedAttribute.Identifier = "NSSearchField_SearchMenuTemplate_SearchMenuTemplate"
            }

            public enum Behavior {
                public static let sendsWholeSearchString: InspectedAttribute.Identifier = "NSSearchField_Behavior_SendsWholeSearchString"
                public static let sendsSearchStringImmediately: InspectedAttribute.Identifier = "NSSearchField_Behavior_SendsSearchStringImmediately"
            }

            public enum MaximumRecents {
                public static let maximumRecents: InspectedAttribute.Identifier = "NSSearchField_MaximumRecents_MaximumRecents"
            }
        }

        public enum NSComboButton {
            public enum Title {
                public static let title: InspectedAttribute.Identifier = "NSComboButton_Title_Title"
            }

            public enum Image {
                public static let image: InspectedAttribute.Identifier = "NSComboButton_Image_Image"
            }

            public enum ImageScaling {
                public static let imageScaling: InspectedAttribute.Identifier = "NSComboButton_ImageScaling_ImageScaling"
            }

            public enum Menu {
                public static let menu: InspectedAttribute.Identifier = "NSComboButton_Menu_Menu"
            }

            public enum Style {
                public static let style: InspectedAttribute.Identifier = "NSComboButton_Style_Style"
            }
        }

        public enum NSGlassEffectView {
            public enum CornerRadius {
                public static let cornerRadius: InspectedAttribute.Identifier = "NSGlassEffectView_CornerRadius_CornerRadius"
            }

            public enum TintColor {
                public static let tintColor: InspectedAttribute.Identifier = "NSGlassEffectView_TintColor_TintColor"
            }

            public enum Style {
                public static let style: InspectedAttribute.Identifier = "NSGlassEffectView_Style_Style"
            }

            public enum EffectIsInteractive {
                public static let effectIsInteractive: InspectedAttribute.Identifier = "NSGlassEffectView_EffectIsInteractive_EffectIsInteractive"
            }

            public enum NSGlassEffectContainerView {
                public static let spacing: InspectedAttribute.Identifier = "NSGlassEffectView_NSGlassEffectContainerView_Spacing"
            }
        }

        public enum NSBackgroundExtensionView {
            public enum AutomaticallyPlacesContentView {
                public static let automaticallyPlacesContentView: InspectedAttribute.Identifier = "NSBackgroundExtensionView_AutomaticallyPlacesContentView_AutomaticallyPlacesContentView"
            }
        }

        public enum NSRulerView {
            public enum Orientation {
                public static let orientation: InspectedAttribute.Identifier = "NSRulerView_Orientation_Orientation"
            }

            public enum BaselineLocation {
                public static let baselineLocation: InspectedAttribute.Identifier = "NSRulerView_BaselineLocation_BaselineLocation"
            }

            public enum RequiredThickness {
                public static let requiredThickness: InspectedAttribute.Identifier = "NSRulerView_RequiredThickness_RequiredThickness"
            }

            public enum RuleThickness {
                public static let ruleThickness: InspectedAttribute.Identifier = "NSRulerView_RuleThickness_RuleThickness"
            }

            public enum ReservedThicknessForMarkers {
                public static let reservedThicknessForMarkers: InspectedAttribute.Identifier = "NSRulerView_ReservedThicknessForMarkers_ReservedThicknessForMarkers"
            }

            public enum ReservedThicknessForAccessoryView {
                public static let reservedThicknessForAccessoryView: InspectedAttribute.Identifier = "NSRulerView_ReservedThicknessForAccessoryView_ReservedThicknessForAccessoryView"
            }

            public enum MeasurementUnits {
                public static let measurementUnits: InspectedAttribute.Identifier = "NSRulerView_MeasurementUnits_MeasurementUnits"
            }

            public enum OriginOffset {
                public static let originOffset: InspectedAttribute.Identifier = "NSRulerView_OriginOffset_OriginOffset"
            }

            public enum Flipped {
                public static let flipped: InspectedAttribute.Identifier = "NSRulerView_Flipped_Flipped"
            }
        }

        public enum NSTableCellView {
            public enum BackgroundStyle {
                public static let backgroundStyle: InspectedAttribute.Identifier = "NSTableCellView_BackgroundStyle_BackgroundStyle"
            }

            public enum RowSizeStyle {
                public static let rowSizeStyle: InspectedAttribute.Identifier = "NSTableCellView_RowSizeStyle_RowSizeStyle"
            }
        }

        public enum NSTableRowView {
            public enum SelectionHighlightStyle {
                public static let selectionHighlightStyle: InspectedAttribute.Identifier = "NSTableRowView_SelectionHighlightStyle_SelectionHighlightStyle"
            }

            public enum Behavior {
                public static let emphasized: InspectedAttribute.Identifier = "NSTableRowView_Behavior_Emphasized"
                public static let groupRowStyle: InspectedAttribute.Identifier = "NSTableRowView_Behavior_GroupRowStyle"
                public static let selected: InspectedAttribute.Identifier = "NSTableRowView_Behavior_Selected"
                public static let previousRowSelected: InspectedAttribute.Identifier = "NSTableRowView_Behavior_PreviousRowSelected"
                public static let nextRowSelected: InspectedAttribute.Identifier = "NSTableRowView_Behavior_NextRowSelected"
                public static let floating: InspectedAttribute.Identifier = "NSTableRowView_Behavior_Floating"
                public static let targetForDropOperation: InspectedAttribute.Identifier = "NSTableRowView_Behavior_TargetForDropOperation"
            }

            public enum DraggingDestinationFeedbackStyle {
                public static let draggingDestinationFeedbackStyle: InspectedAttribute.Identifier = "NSTableRowView_DraggingDestinationFeedbackStyle_DraggingDestinationFeedbackStyle"
            }

            public enum IndentationForDropOperation {
                public static let indentationForDropOperation: InspectedAttribute.Identifier = "NSTableRowView_IndentationForDropOperation_IndentationForDropOperation"
            }

            public enum InteriorBackgroundStyle {
                public static let interiorBackgroundStyle: InspectedAttribute.Identifier = "NSTableRowView_InteriorBackgroundStyle_InteriorBackgroundStyle"
            }

            public enum BackgroundColor {
                public static let backgroundColor: InspectedAttribute.Identifier = "NSTableRowView_BackgroundColor_BackgroundColor"
            }

            public enum NumberOfColumns {
                public static let numberOfColumns: InspectedAttribute.Identifier = "NSTableRowView_NumberOfColumns_NumberOfColumns"
            }
        }

        public enum NSTableHeaderView {
            public enum DraggedColumn {
                public static let draggedColumn: InspectedAttribute.Identifier = "NSTableHeaderView_DraggedColumn_DraggedColumn"
            }

            public enum DraggedDistance {
                public static let draggedDistance: InspectedAttribute.Identifier = "NSTableHeaderView_DraggedDistance_DraggedDistance"
            }

            public enum ResizedColumn {
                public static let resizedColumn: InspectedAttribute.Identifier = "NSTableHeaderView_ResizedColumn_ResizedColumn"
            }
        }

        public enum NSTextInsertionIndicator {
            public enum DisplayMode {
                public static let displayMode: InspectedAttribute.Identifier = "NSTextInsertionIndicator_DisplayMode_DisplayMode"
            }

            public enum Color {
                public static let color: InspectedAttribute.Identifier = "NSTextInsertionIndicator_Color_Color"
            }

            public enum AutomaticModeOptions {
                public static let automaticModeOptions: InspectedAttribute.Identifier = "NSTextInsertionIndicator_AutomaticModeOptions_AutomaticModeOptions"
            }
        }

        public enum NSView {
            public enum Behavior {
                public static let needsUpdateConstraints: InspectedAttribute.Identifier = "NSView_Behavior_NeedsUpdateConstraints"
                public static let translatesAutoresizingMaskIntoConstraints: InspectedAttribute.Identifier = "NSView_Behavior_TranslatesAutoresizingMaskIntoConstraints"
                public static let horizontalContentSizeConstraintActive: InspectedAttribute.Identifier = "NSView_Behavior_HorizontalContentSizeConstraintActive"
                public static let verticalContentSizeConstraintActive: InspectedAttribute.Identifier = "NSView_Behavior_VerticalContentSizeConstraintActive"
                public static let hiddenOrHasHiddenAncestor: InspectedAttribute.Identifier = "NSView_Behavior_HiddenOrHasHiddenAncestor"
                public static let wantsDefaultClipping: InspectedAttribute.Identifier = "NSView_Behavior_WantsDefaultClipping"
                public static let postsFrameChangedNotifications: InspectedAttribute.Identifier = "NSView_Behavior_PostsFrameChangedNotifications"
                public static let autoresizesSubviews: InspectedAttribute.Identifier = "NSView_Behavior_AutoresizesSubviews"
                public static let flipped: InspectedAttribute.Identifier = "NSView_Behavior_Flipped"
                public static let rotatedFromBase: InspectedAttribute.Identifier = "NSView_Behavior_RotatedFromBase"
                public static let rotatedOrScaledFromBase: InspectedAttribute.Identifier = "NSView_Behavior_RotatedOrScaledFromBase"
                public static let opaque: InspectedAttribute.Identifier = "NSView_Behavior_Opaque"
                public static let canDrawConcurrently: InspectedAttribute.Identifier = "NSView_Behavior_CanDrawConcurrently"
                public static let needsDisplay: InspectedAttribute.Identifier = "NSView_Behavior_NeedsDisplay"
                public static let needsPanelToBecomeKey: InspectedAttribute.Identifier = "NSView_Behavior_NeedsPanelToBecomeKey"
                public static let mouseDownCanMoveWindow: InspectedAttribute.Identifier = "NSView_Behavior_MouseDownCanMoveWindow"
                public static let wantsRestingTouches: InspectedAttribute.Identifier = "NSView_Behavior_WantsRestingTouches"
                public static let wantsLayer: InspectedAttribute.Identifier = "NSView_Behavior_WantsLayer"
                public static let wantsUpdateLayer: InspectedAttribute.Identifier = "NSView_Behavior_WantsUpdateLayer"
                public static let canDrawSubviewsIntoLayer: InspectedAttribute.Identifier = "NSView_Behavior_CanDrawSubviewsIntoLayer"
                public static let needsLayout: InspectedAttribute.Identifier = "NSView_Behavior_NeedsLayout"
                public static let layerUsesCoreImageFilters: InspectedAttribute.Identifier = "NSView_Behavior_LayerUsesCoreImageFilters"
                public static let clipsToBounds: InspectedAttribute.Identifier = "NSView_Behavior_ClipsToBounds"
                public static let postsBoundsChangedNotifications: InspectedAttribute.Identifier = "NSView_Behavior_PostsBoundsChangedNotifications"
                public static let inLiveResize: InspectedAttribute.Identifier = "NSView_Behavior_InLiveResize"
                public static let preservesContentDuringLiveResize: InspectedAttribute.Identifier = "NSView_Behavior_PreservesContentDuringLiveResize"
                public static let allowsVibrancy: InspectedAttribute.Identifier = "NSView_Behavior_AllowsVibrancy"
                public static let canBecomeKeyView: InspectedAttribute.Identifier = "NSView_Behavior_CanBecomeKeyView"
                public static let inFullScreenMode: InspectedAttribute.Identifier = "NSView_Behavior_InFullScreenMode"
                public static let prefersCompactControlSizeMetrics: InspectedAttribute.Identifier = "NSView_Behavior_PrefersCompactControlSizeMetrics"
            }

            public enum AlignmentRectInsets {
                public static let alignmentRectInsets: InspectedAttribute.Identifier = "NSView_AlignmentRectInsets_AlignmentRectInsets"
            }

            public enum AutoresizingMask {
                public static let autoresizingMask: InspectedAttribute.Identifier = "NSView_AutoresizingMask_AutoresizingMask"
            }

            public enum FrameRotation {
                public static let frameRotation: InspectedAttribute.Identifier = "NSView_FrameRotation_FrameRotation"
            }

            public enum FrameCenterRotation {
                public static let frameCenterRotation: InspectedAttribute.Identifier = "NSView_FrameCenterRotation_FrameCenterRotation"
            }

            public enum BoundsRotation {
                public static let boundsRotation: InspectedAttribute.Identifier = "NSView_BoundsRotation_BoundsRotation"
            }

            public enum VisibleRect {
                public static let visibleRect: InspectedAttribute.Identifier = "NSView_VisibleRect_VisibleRect"
            }

            public enum LayerContentsRedrawPolicy {
                public static let layerContentsRedrawPolicy: InspectedAttribute.Identifier = "NSView_LayerContentsRedrawPolicy_LayerContentsRedrawPolicy"
            }

            public enum LayerContentsPlacement {
                public static let layerContentsPlacement: InspectedAttribute.Identifier = "NSView_LayerContentsPlacement_LayerContentsPlacement"
            }

            public enum CompositingFilter {
                public static let compositingFilter: InspectedAttribute.Identifier = "NSView_CompositingFilter_CompositingFilter"
            }

            public enum Shadow {
                public static let shadow: InspectedAttribute.Identifier = "NSView_Shadow_Shadow"
            }

            public enum ToolTip {
                public static let toolTip: InspectedAttribute.Identifier = "NSView_ToolTip_ToolTip"
            }

            public enum UserInterfaceLayoutDirection {
                public static let userInterfaceLayoutDirection: InspectedAttribute.Identifier = "NSView_UserInterfaceLayoutDirection_UserInterfaceLayoutDirection"
            }

            public enum PreparedContentRect {
                public static let preparedContentRect: InspectedAttribute.Identifier = "NSView_PreparedContentRect_PreparedContentRect"
            }

            public enum FocusRingType {
                public static let focusRingType: InspectedAttribute.Identifier = "NSView_FocusRingType_FocusRingType"
            }

            public enum FocusRingMaskBounds {
                public static let focusRingMaskBounds: InspectedAttribute.Identifier = "NSView_FocusRingMaskBounds_FocusRingMaskBounds"
            }

            public enum ExclusiveGestureBehavior {
                public static let exclusiveGestureBehavior: InspectedAttribute.Identifier = "NSView_ExclusiveGestureBehavior_ExclusiveGestureBehavior"
            }

            public enum AllowedTouchTypes {
                public static let allowedTouchTypes: InspectedAttribute.Identifier = "NSView_AllowedTouchTypes_AllowedTouchTypes"
            }

            public enum AdditionalSafeAreaInsets {
                public static let additionalSafeAreaInsets: InspectedAttribute.Identifier = "NSView_AdditionalSafeAreaInsets_AdditionalSafeAreaInsets"
            }

            public enum SafeAreaRect {
                public static let safeAreaRect: InspectedAttribute.Identifier = "NSView_SafeAreaRect_SafeAreaRect"
            }
        }

        public enum CALayer {
            public enum ZPosition {
                public static let zPosition: InspectedAttribute.Identifier = "CALayer_ZPosition_ZPosition"
            }

            public enum AnchorPointZ {
                public static let anchorPointZ: InspectedAttribute.Identifier = "CALayer_AnchorPointZ_AnchorPointZ"
            }

            public enum Transform {
                public static let transform: InspectedAttribute.Identifier = "CALayer_Transform_Transform"
            }

            public enum Behavior {
                public static let doubleSided: InspectedAttribute.Identifier = "CALayer_Behavior_DoubleSided"
                public static let geometryFlipped: InspectedAttribute.Identifier = "CALayer_Behavior_GeometryFlipped"
                public static let opaque: InspectedAttribute.Identifier = "CALayer_Behavior_Opaque"
                public static let needsDisplayOnBoundsChange: InspectedAttribute.Identifier = "CALayer_Behavior_NeedsDisplayOnBoundsChange"
                public static let drawsAsynchronously: InspectedAttribute.Identifier = "CALayer_Behavior_DrawsAsynchronously"
                public static let allowsEdgeAntialiasing: InspectedAttribute.Identifier = "CALayer_Behavior_AllowsEdgeAntialiasing"
                public static let allowsGroupOpacity: InspectedAttribute.Identifier = "CALayer_Behavior_AllowsGroupOpacity"
                public static let shouldRasterize: InspectedAttribute.Identifier = "CALayer_Behavior_ShouldRasterize"
            }

            public enum SublayerTransform {
                public static let sublayerTransform: InspectedAttribute.Identifier = "CALayer_SublayerTransform_SublayerTransform"
            }

            public enum ContentsRect {
                public static let contentsRect: InspectedAttribute.Identifier = "CALayer_ContentsRect_ContentsRect"
            }

            public enum ContentsGravity {
                public static let contentsGravity: InspectedAttribute.Identifier = "CALayer_ContentsGravity_ContentsGravity"
            }

            public enum ContentsScale {
                public static let contentsScale: InspectedAttribute.Identifier = "CALayer_ContentsScale_ContentsScale"
            }

            public enum ContentsCenter {
                public static let contentsCenter: InspectedAttribute.Identifier = "CALayer_ContentsCenter_ContentsCenter"
            }

            public enum ContentsFormat {
                public static let contentsFormat: InspectedAttribute.Identifier = "CALayer_ContentsFormat_ContentsFormat"
            }

            public enum ToneMapMode {
                public static let toneMapMode: InspectedAttribute.Identifier = "CALayer_ToneMapMode_ToneMapMode"
            }

            public enum PreferredDynamicRange {
                public static let preferredDynamicRange: InspectedAttribute.Identifier = "CALayer_PreferredDynamicRange_PreferredDynamicRange"
            }

            public enum ContentsHeadroom {
                public static let contentsHeadroom: InspectedAttribute.Identifier = "CALayer_ContentsHeadroom_ContentsHeadroom"
            }

            public enum MinificationFilter {
                public static let minificationFilter: InspectedAttribute.Identifier = "CALayer_MinificationFilter_MinificationFilter"
            }

            public enum MagnificationFilter {
                public static let magnificationFilter: InspectedAttribute.Identifier = "CALayer_MagnificationFilter_MagnificationFilter"
            }

            public enum MinificationFilterBias {
                public static let minificationFilterBias: InspectedAttribute.Identifier = "CALayer_MinificationFilterBias_MinificationFilterBias"
            }

            public enum MaskedCorners {
                public static let maskedCorners: InspectedAttribute.Identifier = "CALayer_MaskedCorners_MaskedCorners"
            }

            public enum CornerCurve {
                public static let cornerCurve: InspectedAttribute.Identifier = "CALayer_CornerCurve_CornerCurve"
            }

            public enum RasterizationScale {
                public static let rasterizationScale: InspectedAttribute.Identifier = "CALayer_RasterizationScale_RasterizationScale"
            }

            public enum ShadowPath {
                public static let shadowPath: InspectedAttribute.Identifier = "CALayer_ShadowPath_ShadowPath"
            }

            public enum Name {
                public static let name: InspectedAttribute.Identifier = "CALayer_Name_Name"
            }

            public enum VisibleRect {
                public static let visibleRect: InspectedAttribute.Identifier = "CALayer_VisibleRect_VisibleRect"
            }

            public enum CAShapeLayer {
                public static let path: InspectedAttribute.Identifier = "CALayer_CAShapeLayer_Path"
                public static let fillColor: InspectedAttribute.Identifier = "CALayer_CAShapeLayer_FillColor"
                public static let fillRule: InspectedAttribute.Identifier = "CALayer_CAShapeLayer_FillRule"
                public static let strokeColor: InspectedAttribute.Identifier = "CALayer_CAShapeLayer_StrokeColor"
                public static let strokeStart: InspectedAttribute.Identifier = "CALayer_CAShapeLayer_StrokeStart"
                public static let strokeEnd: InspectedAttribute.Identifier = "CALayer_CAShapeLayer_StrokeEnd"
                public static let lineWidth: InspectedAttribute.Identifier = "CALayer_CAShapeLayer_LineWidth"
                public static let miterLimit: InspectedAttribute.Identifier = "CALayer_CAShapeLayer_MiterLimit"
                public static let lineCap: InspectedAttribute.Identifier = "CALayer_CAShapeLayer_LineCap"
                public static let lineJoin: InspectedAttribute.Identifier = "CALayer_CAShapeLayer_LineJoin"
                public static let lineDashPhase: InspectedAttribute.Identifier = "CALayer_CAShapeLayer_LineDashPhase"
                public static let lineDashPattern: InspectedAttribute.Identifier = "CALayer_CAShapeLayer_LineDashPattern"
            }

            public enum CAGradientLayer {
                public static let colors: InspectedAttribute.Identifier = "CALayer_CAGradientLayer_Colors"
                public static let locations: InspectedAttribute.Identifier = "CALayer_CAGradientLayer_Locations"
                public static let startPoint: InspectedAttribute.Identifier = "CALayer_CAGradientLayer_StartPoint"
                public static let endPoint: InspectedAttribute.Identifier = "CALayer_CAGradientLayer_EndPoint"
                public static let type: InspectedAttribute.Identifier = "CALayer_CAGradientLayer_Type"
            }

            public enum CATextLayer {
                public static let fontSize: InspectedAttribute.Identifier = "CALayer_CATextLayer_FontSize"
                public static let foregroundColor: InspectedAttribute.Identifier = "CALayer_CATextLayer_ForegroundColor"
                public static let wrapped: InspectedAttribute.Identifier = "CALayer_CATextLayer_Wrapped"
                public static let truncationMode: InspectedAttribute.Identifier = "CALayer_CATextLayer_TruncationMode"
                public static let alignmentMode: InspectedAttribute.Identifier = "CALayer_CATextLayer_AlignmentMode"
                public static let allowsFontSubpixelQuantization: InspectedAttribute.Identifier = "CALayer_CATextLayer_AllowsFontSubpixelQuantization"
            }

            public enum CAReplicatorLayer {
                public static let instanceCount: InspectedAttribute.Identifier = "CALayer_CAReplicatorLayer_InstanceCount"
                public static let preservesDepth: InspectedAttribute.Identifier = "CALayer_CAReplicatorLayer_PreservesDepth"
                public static let instanceDelay: InspectedAttribute.Identifier = "CALayer_CAReplicatorLayer_InstanceDelay"
                public static let instanceTransform: InspectedAttribute.Identifier = "CALayer_CAReplicatorLayer_InstanceTransform"
                public static let instanceColor: InspectedAttribute.Identifier = "CALayer_CAReplicatorLayer_InstanceColor"
                public static let instanceRedOffset: InspectedAttribute.Identifier = "CALayer_CAReplicatorLayer_InstanceRedOffset"
                public static let instanceGreenOffset: InspectedAttribute.Identifier = "CALayer_CAReplicatorLayer_InstanceGreenOffset"
                public static let instanceBlueOffset: InspectedAttribute.Identifier = "CALayer_CAReplicatorLayer_InstanceBlueOffset"
                public static let instanceAlphaOffset: InspectedAttribute.Identifier = "CALayer_CAReplicatorLayer_InstanceAlphaOffset"
            }

            public enum CAEmitterLayer {
                public static let emitterCells: InspectedAttribute.Identifier = "CALayer_CAEmitterLayer_EmitterCells"
                public static let birthRate: InspectedAttribute.Identifier = "CALayer_CAEmitterLayer_BirthRate"
                public static let lifetime: InspectedAttribute.Identifier = "CALayer_CAEmitterLayer_Lifetime"
                public static let emitterPosition: InspectedAttribute.Identifier = "CALayer_CAEmitterLayer_EmitterPosition"
                public static let emitterZPosition: InspectedAttribute.Identifier = "CALayer_CAEmitterLayer_EmitterZPosition"
                public static let emitterSize: InspectedAttribute.Identifier = "CALayer_CAEmitterLayer_EmitterSize"
                public static let emitterDepth: InspectedAttribute.Identifier = "CALayer_CAEmitterLayer_EmitterDepth"
                public static let emitterShape: InspectedAttribute.Identifier = "CALayer_CAEmitterLayer_EmitterShape"
                public static let emitterMode: InspectedAttribute.Identifier = "CALayer_CAEmitterLayer_EmitterMode"
                public static let renderMode: InspectedAttribute.Identifier = "CALayer_CAEmitterLayer_RenderMode"
                public static let preservesDepth: InspectedAttribute.Identifier = "CALayer_CAEmitterLayer_PreservesDepth"
                public static let velocity: InspectedAttribute.Identifier = "CALayer_CAEmitterLayer_Velocity"
                public static let scale: InspectedAttribute.Identifier = "CALayer_CAEmitterLayer_Scale"
                public static let spin: InspectedAttribute.Identifier = "CALayer_CAEmitterLayer_Spin"
            }

            public enum CAScrollLayer {
                public static let scrollMode: InspectedAttribute.Identifier = "CALayer_CAScrollLayer_ScrollMode"
            }

            public enum CATiledLayer {
                public static let tileSize: InspectedAttribute.Identifier = "CALayer_CATiledLayer_TileSize"
            }
        }
    }

#endif
