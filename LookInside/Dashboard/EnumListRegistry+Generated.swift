//
//  EnumListRegistry+Generated.swift
//  LookInside
//
//  The enum lists the Dashboard needs beyond the hand-written ones in
//  EnumListRegistry.swift, read from the SDK headers by the monorepo's
//  Scripts/generate-enum-tables.py. Do not edit; rerun the script after
//  adding an attribute with a new enum list.
//

import Foundation

extension EnumListRegistry {
    static func addGeneratedLists(to data: inout [String: [EnumListRegistryKeyValueItem]]) {
        data["NSBackingStoreType"] = [
            item("NSBackingStoreRetained", 0, 10),
            item("NSBackingStoreNonretained", 1, 10),
            item("NSBackingStoreBuffered", 2),
        ]

        data["NSBrowserColumnResizingType"] = [
            item("NSBrowserNoColumnResizing", 0),
            item("NSBrowserAutoColumnResizing", 1),
            item("NSBrowserUserColumnResizing", 2),
        ]

        data["NSComboButtonStyle"] = [
            item("NSComboButtonStyleSplit", 0),
            item("NSComboButtonStyleUnified", 1),
        ]

        data["NSControlBorderShape"] = [
            item("NSControlBorderShapeAutomatic", 0),
            item("NSControlBorderShapeCapsule", 1),
            item("NSControlBorderShapeRoundedRectangle", 2),
            item("NSControlBorderShapeCircle", 3),
        ]

        data["NSFocusRingType"] = [
            item("NSFocusRingTypeDefault", 0),
            item("NSFocusRingTypeNone", 1),
            item("NSFocusRingTypeExterior", 2),
        ]

        data["NSGlassEffectViewStyle"] = [
            item("NSGlassEffectViewStyleRegular", 0),
            item("NSGlassEffectViewStyleClear", 1),
        ]

        data["NSGridRowAlignment"] = [
            item("NSGridRowAlignmentInherited", 0),
            item("NSGridRowAlignmentNone", 1),
            item("NSGridRowAlignmentFirstBaseline", 2),
            item("NSGridRowAlignmentLastBaseline", 3),
        ]

        data["NSImageDynamicRange"] = [
            item("NSImageDynamicRangeUnspecified", -1),
            item("NSImageDynamicRangeStandard", 0),
            item("NSImageDynamicRangeConstrainedHigh", 1),
            item("NSImageDynamicRangeHigh", 2),
        ]

        data["NSLevelIndicatorPlaceholderVisibility"] = [
            item("NSLevelIndicatorPlaceholderVisibilityAutomatic", 0),
            item("NSLevelIndicatorPlaceholderVisibilityAlways", 1),
            item("NSLevelIndicatorPlaceholderVisibilityWhileEditing", 2),
        ]

        data["NSMatrixMode"] = [
            item("NSRadioModeMatrix", 0),
            item("NSHighlightModeMatrix", 1),
            item("NSListModeMatrix", 2),
            item("NSTrackModeMatrix", 3),
        ]

        data["NSPathStyle"] = [
            item("NSPathStyleStandard", 0),
            item("NSPathStylePopUp", 2),
            item("NSPathStyleNavigationBar", 1, 10),
        ]

        data["NSPopUpArrowPosition"] = [
            item("NSPopUpNoArrow", 0),
            item("NSPopUpArrowAtCenter", 1),
            item("NSPopUpArrowAtBottom", 2),
        ]

        data["NSRuleEditorNestingMode"] = [
            item("NSRuleEditorNestingModeSingle", 0),
            item("NSRuleEditorNestingModeList", 1),
            item("NSRuleEditorNestingModeCompound", 2),
            item("NSRuleEditorNestingModeSimple", 3),
        ]

        data["NSRulerOrientation"] = [
            item("NSHorizontalRuler", 0),
            item("NSVerticalRuler", 1),
        ]

        data["NSScrollViewFindBarPosition"] = [
            item("NSScrollViewFindBarPositionAboveHorizontalRuler", 0),
            item("NSScrollViewFindBarPositionAboveContent", 1),
            item("NSScrollViewFindBarPositionBelowContent", 2),
        ]

        data["NSScrollerPart"] = [
            item("NSScrollerNoPart", 0),
            item("NSScrollerDecrementPage", 1),
            item("NSScrollerKnob", 2),
            item("NSScrollerIncrementPage", 3),
            item("NSScrollerDecrementLine", 4, 10),
            item("NSScrollerIncrementLine", 5, 10),
            item("NSScrollerKnobSlot", 6),
        ]

        data["NSSegmentDistribution"] = [
            item("NSSegmentDistributionFit", 0),
            item("NSSegmentDistributionFill", 1),
            item("NSSegmentDistributionFillEqually", 2),
            item("NSSegmentDistributionFillProportionally", 3),
        ]

        data["NSSegmentedControlRole"] = [
            item("NSSegmentedControlRoleAutomatic", 0),
            item("NSSegmentedControlRoleTabs", 1),
            item("NSSegmentedControlRoleValueSelection", 2),
        ]

        data["NSSelectionAffinity"] = [
            item("NSSelectionAffinityUpstream", 0),
            item("NSSelectionAffinityDownstream", 1),
        ]

        data["NSSelectionDirection"] = [
            item("NSDirectSelection", 0),
            item("NSSelectingNext", 1),
            item("NSSelectingPrevious", 2),
        ]

        data["NSSelectionGranularity"] = [
            item("NSSelectByCharacter", 0),
            item("NSSelectByWord", 1),
            item("NSSelectByParagraph", 2),
        ]

        data["NSTextInputTraitType"] = [
            item("NSTextInputTraitTypeDefault", 0),
            item("NSTextInputTraitTypeNo", 1),
            item("NSTextInputTraitTypeYes", 2),
        ]

        data["NSTextInsertionIndicatorDisplayMode"] = [
            item("NSTextInsertionIndicatorDisplayModeAutomatic", 0),
            item("NSTextInsertionIndicatorDisplayModeHidden", 1),
            item("NSTextInsertionIndicatorDisplayModeVisible", 2),
        ]

        data["NSTintProminence"] = [
            item("NSTintProminenceAutomatic", 0),
            item("NSTintProminenceNone", 1),
            item("NSTintProminencePrimary", 2),
            item("NSTintProminenceSecondary", 3),
        ]

        data["NSTokenStyle"] = [
            item("NSTokenStyleDefault", 0),
            item("NSTokenStyleNone", 1),
            item("NSTokenStyleRounded", 2),
            item("NSTokenStyleSquared", 3, 10),
            item("NSTokenStylePlainSquared", 4, 10),
        ]

        data["NSUsableScrollerParts"] = [
            item("NSNoScrollerParts", 0),
            item("NSOnlyScrollerArrows", 1, 10),
            item("NSAllScrollerParts", 2),
        ]

        data["NSViewExclusiveGestureBehavior"] = [
            item("NSViewExclusiveGestureBehaviorInherit", 0),
            item("NSViewExclusiveGestureBehaviorExclusive", 1),
            item("NSViewExclusiveGestureBehaviorNotExclusive", 2),
        ]

        data["NSViewLayerContentsPlacement"] = [
            item("NSViewLayerContentsPlacementScaleAxesIndependently", 0),
            item("NSViewLayerContentsPlacementScaleProportionallyToFit", 1),
            item("NSViewLayerContentsPlacementScaleProportionallyToFill", 2),
            item("NSViewLayerContentsPlacementCenter", 3),
            item("NSViewLayerContentsPlacementTop", 4),
            item("NSViewLayerContentsPlacementTopRight", 5),
            item("NSViewLayerContentsPlacementRight", 6),
            item("NSViewLayerContentsPlacementBottomRight", 7),
            item("NSViewLayerContentsPlacementBottom", 8),
            item("NSViewLayerContentsPlacementBottomLeft", 9),
            item("NSViewLayerContentsPlacementLeft", 10),
            item("NSViewLayerContentsPlacementTopLeft", 11),
        ]

        data["NSViewLayerContentsRedrawPolicy"] = [
            item("NSViewLayerContentsRedrawNever", 0),
            item("NSViewLayerContentsRedrawOnSetNeedsDisplay", 1),
            item("NSViewLayerContentsRedrawDuringViewResize", 2),
            item("NSViewLayerContentsRedrawBeforeViewResize", 3),
            item("NSViewLayerContentsRedrawCrossfade", 4, 10),
        ]

        data["NSWindowDepth"] = [
            item("NSWindowDepthTwentyfourBitRGB", 520),
            item("NSWindowDepthSixtyfourBitRGB", 528),
            item("NSWindowDepthOnehundredtwentyeightBitRGB", 544),
        ]

        data["NSWindowSharingType"] = [
            item("NSWindowSharingNone", 0),
            item("NSWindowSharingReadOnly", 1),
        ]

        data["NSWritingToolsBehavior"] = [
            item("NSWritingToolsBehaviorNone", -1),
            item("NSWritingToolsBehaviorDefault", 0),
            item("NSWritingToolsBehaviorComplete", 1),
            item("NSWritingToolsBehaviorLimited", 2),
        ]

        data["UIActivityIndicatorViewStyle"] = [
            item("UIActivityIndicatorViewStyleMedium", 100, 13),
            item("UIActivityIndicatorViewStyleLarge", 101, 13),
            item("UIActivityIndicatorViewStyleWhiteLarge", 0, 2),
            item("UIActivityIndicatorViewStyleWhite", 1, 2),
            item("UIActivityIndicatorViewStyleGray", 2, 2),
        ]

        data["UIBarStyle"] = [
            item("UIBarStyleDefault", 0),
            item("UIBarStyleBlack", 1),
            item("UIBarStyleBlackTranslucent", 2, 2),
        ]

        data["UIBaselineAdjustment"] = [
            item("UIBaselineAdjustmentAlignBaselines", 0),
            item("UIBaselineAdjustmentAlignCenters", 1),
            item("UIBaselineAdjustmentNone", 2),
        ]

        data["UIBehavioralStyle"] = [
            item("UIBehavioralStyleAutomatic", 0),
            item("UIBehavioralStylePad", 1),
            item("UIBehavioralStyleMac", 2),
        ]

        data["UIButtonRole"] = [
            item("UIButtonRoleNormal", 0),
            item("UIButtonRolePrimary", 1),
            item("UIButtonRoleCancel", 2),
            item("UIButtonRoleDestructive", 3),
        ]

        data["UIButtonType"] = [
            item("UIButtonTypeCustom", 0),
            item("UIButtonTypeSystem", 1, 7),
            item("UIButtonTypeDetailDisclosure", 2),
            item("UIButtonTypeInfoLight", 3),
            item("UIButtonTypeInfoDark", 4),
            item("UIButtonTypeContactAdd", 5),
            item("UIButtonTypeClose", 7, 13),
        ]

        data["UICollectionViewReorderingCadence"] = [
            item("UICollectionViewReorderingCadenceImmediate", 0),
            item("UICollectionViewReorderingCadenceFast", 1),
            item("UICollectionViewReorderingCadenceSlow", 2),
        ]

        data["UICollectionViewSelfSizingInvalidation"] = [
            item("UICollectionViewSelfSizingInvalidationDisabled", 0),
            item("UICollectionViewSelfSizingInvalidationEnabled", 1),
            item("UICollectionViewSelfSizingInvalidationEnabledIncludingConstraints", 2),
        ]

        data["UIDatePickerMode"] = [
            item("UIDatePickerModeTime", 0),
            item("UIDatePickerModeDate", 1),
            item("UIDatePickerModeDateAndTime", 2),
            item("UIDatePickerModeCountDownTimer", 3),
            item("UIDatePickerModeYearAndMonth", 4, 17),
        ]

        data["UIDatePickerStyle"] = [
            item("UIDatePickerStyleAutomatic", 0),
            item("UIDatePickerStyleWheels", 1),
            item("UIDatePickerStyleCompact", 2),
            item("UIDatePickerStyleInline", 3, 14),
        ]

        data["UIInputViewStyle"] = [
            item("UIInputViewStyleDefault", 0),
            item("UIInputViewStyleKeyboard", 1),
        ]

        data["UILabelVibrancy"] = [
            item("UILabelVibrancyNone", 0),
            item("UILabelVibrancyAutomatic", 1),
        ]

        data["UINavigationBarNSToolbarSection"] = [
            item("UINavigationBarNSToolbarSectionNone", 0),
            item("UINavigationBarNSToolbarSectionSidebar", 1),
            item("UINavigationBarNSToolbarSectionSupplementary", 2),
            item("UINavigationBarNSToolbarSectionContent", 3),
        ]

        data["UIPageControlBackgroundStyle"] = [
            item("UIPageControlBackgroundStyleAutomatic", 0),
            item("UIPageControlBackgroundStyleProminent", 1),
            item("UIPageControlBackgroundStyleMinimal", 2),
        ]

        data["UIPageControlDirection"] = [
            item("UIPageControlDirectionNatural", 0),
            item("UIPageControlDirectionLeftToRight", 1),
            item("UIPageControlDirectionRightToLeft", 2),
            item("UIPageControlDirectionTopToBottom", 3),
            item("UIPageControlDirectionBottomToTop", 4),
        ]

        data["UIPageControlInteractionState"] = [
            item("UIPageControlInteractionStateNone", 0),
            item("UIPageControlInteractionStateDiscrete", 1),
            item("UIPageControlInteractionStateContinuous", 2),
        ]

        data["UIProgressViewStyle"] = [
            item("UIProgressViewStyleDefault", 0),
            item("UIProgressViewStyleBar", 1),
        ]

        data["UIScrollViewIndexDisplayMode"] = [
            item("UIScrollViewIndexDisplayModeAutomatic", 0),
            item("UIScrollViewIndexDisplayModeAlwaysHidden", 1),
        ]

        data["UIScrollViewIndicatorStyle"] = [
            item("UIScrollViewIndicatorStyleDefault", 0),
            item("UIScrollViewIndicatorStyleBlack", 1),
            item("UIScrollViewIndicatorStyleWhite", 2),
        ]

        data["UIScrollViewKeyboardDismissMode"] = [
            item("UIScrollViewKeyboardDismissModeNone", 0),
            item("UIScrollViewKeyboardDismissModeOnDrag", 1),
            item("UIScrollViewKeyboardDismissModeInteractive", 2),
            item("UIScrollViewKeyboardDismissModeOnDragWithAccessory", 3),
            item("UIScrollViewKeyboardDismissModeInteractiveWithAccessory", 4),
        ]

        data["UISearchBarStyle"] = [
            item("UISearchBarStyleDefault", 0),
            item("UISearchBarStyleProminent", 1),
            item("UISearchBarStyleMinimal", 2),
        ]

        data["UISemanticContentAttribute"] = [
            item("UISemanticContentAttributeUnspecified", 0),
            item("UISemanticContentAttributePlayback", 1),
            item("UISemanticContentAttributeSpatial", 2),
            item("UISemanticContentAttributeForceLeftToRight", 3),
            item("UISemanticContentAttributeForceRightToLeft", 4),
        ]

        data["UISliderStyle"] = [
            item("UISliderStyleDefault", 0),
            item("UISliderStyleThumbless", 1),
        ]

        data["UISwitchStyle"] = [
            item("UISwitchStyleAutomatic", 0),
            item("UISwitchStyleCheckbox", 1),
            item("UISwitchStyleSliding", 2),
        ]

        data["UITabBarItemPositioning"] = [
            item("UITabBarItemPositioningAutomatic", 0),
            item("UITabBarItemPositioningFill", 1),
            item("UITabBarItemPositioningCentered", 2),
        ]

        data["UITableViewCellAccessoryType"] = [
            item("UITableViewCellAccessoryNone", 0),
            item("UITableViewCellAccessoryDisclosureIndicator", 1),
            item("UITableViewCellAccessoryDetailDisclosureButton", 2),
            item("UITableViewCellAccessoryCheckmark", 3),
            item("UITableViewCellAccessoryDetailButton", 4, 7),
        ]

        data["UITableViewCellEditingStyle"] = [
            item("UITableViewCellEditingStyleNone", 0),
            item("UITableViewCellEditingStyleDelete", 1),
            item("UITableViewCellEditingStyleInsert", 2),
        ]

        data["UITableViewCellFocusStyle"] = [
            item("UITableViewCellFocusStyleDefault", 0),
            item("UITableViewCellFocusStyleCustom", 1),
        ]

        data["UITableViewCellSelectionStyle"] = [
            item("UITableViewCellSelectionStyleNone", 0),
            item("UITableViewCellSelectionStyleBlue", 1),
            item("UITableViewCellSelectionStyleGray", 2),
            item("UITableViewCellSelectionStyleDefault", 3, 7),
        ]

        data["UITableViewSelfSizingInvalidation"] = [
            item("UITableViewSelfSizingInvalidationDisabled", 0),
            item("UITableViewSelfSizingInvalidationEnabled", 1),
            item("UITableViewSelfSizingInvalidationEnabledIncludingConstraints", 2),
        ]

        data["UITableViewSeparatorInsetReference"] = [
            item("UITableViewSeparatorInsetFromCellEdges", 0),
            item("UITableViewSeparatorInsetFromAutomaticInsets", 1),
        ]

        data["UITextBorderStyle"] = [
            item("UITextBorderStyleNone", 0),
            item("UITextBorderStyleLine", 1),
            item("UITextBorderStyleBezel", 2),
            item("UITextBorderStyleRoundedRect", 3),
        ]

        data["UITextViewBorderStyle"] = [
            item("UITextViewBorderStyleNone", 0),
        ]

        data["UIUserInterfaceLayoutDirection"] = [
            item("UIUserInterfaceLayoutDirectionLeftToRight", 0),
            item("UIUserInterfaceLayoutDirectionRightToLeft", 1),
        ]

        data["UIWritingToolsBehavior"] = [
            item("UIWritingToolsBehaviorNone", -1),
            item("UIWritingToolsBehaviorDefault", 0),
            item("UIWritingToolsBehaviorComplete", 1),
            item("UIWritingToolsBehaviorLimited", 2),
        ]
    }
}
