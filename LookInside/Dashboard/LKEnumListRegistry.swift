//
//  LKEnumListRegistry.swift
//  LookInside
//
//  Created by Li Kai on 2018/11/21.
//  https://lookin.work
//
//  The values and names of every enum the Dashboard can show and edit,
//  keyed by the enum list name `LookinDashboardBlueprint` gives an
//  attribute. Foundation only, so the tests can compile it on its own.
//

import Foundation

/// One case of an enum: its name, raw value, and the first OS major
/// version that has it (0 for every version).
@objc(LKEnumListRegistryKeyValueItem)
final class LKEnumListRegistryKeyValueItem: NSObject {
    @objc let desc: String
    @objc let value: Int
    @objc let availableOSVersion: Int

    init(desc: String, value: Int, availableOSVersion: Int) {
        self.desc = desc
        self.value = value
        self.availableOSVersion = availableOSVersion
    }
}

@objc(LKEnumListRegistry)
final class LKEnumListRegistry: NSObject {
    @objc(sharedInstance)
    static let shared = LKEnumListRegistry()

    private let data: [String: [LKEnumListRegistryKeyValueItem]]

    override private init() {
        data = Self.makeData()
        super.init()
    }

    /// The cases of `enumName` in menu order, or nil for an unknown list.
    @objc(itemsForEnumName:)
    func items(forEnumName enumName: String?) -> [LKEnumListRegistryKeyValueItem]? {
        guard let enumName else { return nil }
        return data[enumName]
    }

    /// The name of the first case of `enumName` whose value is `value`.
    @objc(descForEnumName:value:)
    func desc(forEnumName enumName: String?, value: Int) -> String? {
        guard let items = items(forEnumName: enumName) else {
            assertionFailure("unknown enum list \(enumName ?? "nil")")
            return nil
        }
        return items.first { $0.value == value }?.desc
    }

    /// Every list, for the tests.
    var allEnumNames: [String] {
        Array(data.keys)
    }

    private static func item(_ desc: String, _ value: Int, _ availableOSVersion: Int = 0) -> LKEnumListRegistryKeyValueItem {
        LKEnumListRegistryKeyValueItem(desc: desc, value: value, availableOSVersion: availableOSVersion)
    }

    /// Lists are assigned in order; a later assignment of the same name
    /// replaces the earlier one, as `NSTextFieldBezelStyle` does.
    private static func makeData() -> [String: [LKEnumListRegistryKeyValueItem]] {
        var data: [String: [LKEnumListRegistryKeyValueItem]] = [:]

        data["UIControlContentVerticalAlignment"] = [item("UIControlContentVerticalAlignmentCenter", 0),
                                                     item("UIControlContentVerticalAlignmentTop", 1),
                                                     item("UIControlContentVerticalAlignmentBottom", 2),
                                                     item("UIControlContentVerticalAlignmentFill", 3)]

        data["UIControlContentHorizontalAlignment"] = [item("UIControlContentHorizontalAlignmentCenter", 0),
                                                       item("UIControlContentHorizontalAlignmentLeft", 1),
                                                       item("UIControlContentHorizontalAlignmentRight", 2),
                                                       item("UIControlContentHorizontalAlignmentFill", 3),
                                                       item("UIControlContentHorizontalAlignmentLeading", 4, 11),
                                                       item("UIControlContentHorizontalAlignmentTrailing", 5, 11)]

        data["UIViewContentMode"] = [item("UIViewContentModeScaleToFill", 0),
                                     item("UIViewContentModeScaleAspectFit", 1),
                                     item("UIViewContentModeScaleAspectFill", 2),
                                     item("UIViewContentModeRedraw", 3),
                                     item("UIViewContentModeCenter", 4),
                                     item("UIViewContentModeTop", 5),
                                     item("UIViewContentModeBottom", 6),
                                     item("UIViewContentModeLeft", 7),
                                     item("UIViewContentModeRight", 8),
                                     item("UIViewContentModeTopLeft", 9),
                                     item("UIViewContentModeTopRight", 10),
                                     item("UIViewContentModeBottomLeft", 11),
                                     item("UIViewContentModeBottomRight", 12)]

        data["UIViewTintAdjustmentMode"] = [item("UIViewTintAdjustmentModeAutomatic", 0),
                                            item("UIViewTintAdjustmentModeNormal", 1),
                                            item("UIViewTintAdjustmentModeDimmed", 2)]

        data["NSTextAlignment"] = [item("NSTextAlignmentLeft", 0),
                                   item("NSTextAlignmentCenter", 1),
                                   item("NSTextAlignmentRight", 2),
                                   item("NSTextAlignmentJustified", 3),
                                   item("NSTextAlignmentNatural", 4)]

        data["NSLineBreakMode"] = [item("NSLineBreakByWordWrapping", 0),
                                   item("NSLineBreakByCharWrapping", 1),
                                   item("NSLineBreakByClipping", 2),
                                   item("NSLineBreakByTruncatingHead", 3),
                                   item("NSLineBreakByTruncatingTail", 4),
                                   item("NSLineBreakByTruncatingMiddle", 5)]

        data["UIScrollViewContentInsetAdjustmentBehavior"] = [
            item("UIScrollViewContentInsetAdjustmentAutomatic", 0),
            item("UIScrollViewContentInsetAdjustmentScrollableAxes", 1),
            item("UIScrollViewContentInsetAdjustmentNever", 2),
            item("UIScrollViewContentInsetAdjustmentAlways", 3),
        ]

        data["UITableViewStyle"] = [item("UITableViewStylePlain", 0),
                                    item("UITableViewStyleGrouped", 1)]

        data["UITextFieldViewMode"] = [item("UITextFieldViewModeNever", 0),
                                       item("UITextFieldViewModeWhileEditing", 1),
                                       item("UITextFieldViewModeUnlessEditing", 2),
                                       item("UITextFieldViewModeAlways", 3)]

        data["UIAccessibilityNavigationStyle"] = [
            item("UIAccessibilityNavigationStyleAutomatic", 0),
            item("UIAccessibilityNavigationStyleSeparate", 1),
            item("UIAccessibilityNavigationStyleCombined", 2),
        ]

        data["QMUIButtonImagePosition"] = [
            item("QMUIButtonImagePositionTop", 0),
            item("QMUIButtonImagePositionLeft", 1),
            item("QMUIButtonImagePositionBottom", 2),
            item("QMUIButtonImagePositionRight", 3),
        ]

        data["UITableViewCellSeparatorStyle"] = [
            item("UITableViewCellSeparatorStyleNone", 0),
            item("UITableViewCellSeparatorStyleSingleLine", 1),
            item("UITableViewCellSeparatorStyleSingleLineEtched", 2),
        ]

        data["UIBlurEffectStyle"] = [
            item("UIBlurEffectStyleExtraLight", 0),
            item("UIBlurEffectStyleLight", 1),
            item("UIBlurEffectStyleDark", 2),
            //            item("UIBlurEffectStyleExtraDark", 3), // 该值被官方标注了 API_UNAVAILABLE(ios)，因此这里跳过
            item("UIBlurEffectStyleRegular", 4, 10),
            item("UIBlurEffectStyleProminent", 5, 10),
            item("UIBlurEffectStyleSystemUltraThinMaterial", 6, 13),
            item("UIBlurEffectStyleSystemThinMaterial", 7, 13),
            item("UIBlurEffectStyleSystemMaterial", 8, 13),
            item("UIBlurEffectStyleSystemThickMaterial", 9, 13),
            item("UIBlurEffectStyleSystemChromeMaterial", 10, 13),
            item("UIBlurEffectStyleSystemUltraThinMaterialLight", 11, 13),
            item("UIBlurEffectStyleSystemThinMaterialLight", 12, 13),
            item("UIBlurEffectStyleSystemMaterialLight", 13, 13),
            item("UIBlurEffectStyleSystemThickMaterialLight", 14, 13),
            item("UIBlurEffectStyleSystemChromeMaterialLight", 15, 13),
            item("UIBlurEffectStyleSystemUltraThinMaterialDark", 16, 13),
            item("UIBlurEffectStyleSystemThinMaterialDark", 17, 13),
            item("UIBlurEffectStyleSystemMaterialDark", 18, 13),
            item("UIBlurEffectStyleSystemThickMaterialDark", 19, 13),
            item("UIBlurEffectStyleSystemChromeMaterialDark", 20, 13),
        ]

        data["UILayoutConstraintAxis"] = [
            item("UILayoutConstraintAxisHorizontal", 0),
            item("UILayoutConstraintAxisVertical", 1),
        ]

        data["UIStackViewDistribution"] = [
            item("UIStackViewDistributionFill", 0),
            item("UIStackViewDistributionFillEqually", 1),
            item("UIStackViewDistributionFillProportionally", 2),
            item("UIStackViewDistributionEqualSpacing", 3),
            item("UIStackViewDistributionEqualCentering", 4),
        ]

        data["UIStackViewAlignment"] = [
            item("UIStackViewAlignmentFill", 0),
            item("UIStackViewAlignmentLeading (Top)", 1),
            item("UIStackViewAlignmentFirstBaseline", 2),
            item("UIStackViewAlignmentCenter", 3),
            item("UIStackViewAlignmentTrailing (Bottom)", 4),
            item("UIStackViewAlignmentLastBaseline", 5),
        ]
        data["NSWritingDirection"] = [
            item("NSWritingDirectionNatural", -1),
            item("NSWritingDirectionLeftToRight", 0),
            item("NSWritingDirectionRightToLeft", 1),
        ]
        data["NSTextAlignment_AppKit"] = [
            item("NSTextAlignmentLeft", 0),
            item("NSTextAlignmentRight", 1),
            item("NSTextAlignmentCenter", 2),
            item("NSTextAlignmentJustified", 3),
            item("NSTextAlignmentNatural", 4),
        ]
        data["NSCellType"] = [
            item("NSNullCellType", 0),
            item("NSTextCellType", 1),
            item("NSImageCellType", 2),
        ]
        data["NSTextFieldBezelStyle"] = [
            item("NSTextFieldSquareBezel", 0),
            item("NSTextFieldRoundedBezel", 1),
        ]
        data["NSButtonType"] = [
            item("NSButtonTypeMomentaryLight", 0),
            item("NSButtonTypePushOnPushOff", 1),
            item("NSButtonTypeToggle", 2),
            item("NSButtonTypeSwitch", 3),
            item("NSButtonTypeRadio", 4),
            item("NSButtonTypeMomentaryChange", 5),
            item("NSButtonTypeOnOff", 6),
            item("NSButtonTypeMomentaryPushIn", 7),
            item("NSButtonTypeAccelerator", 8),
            item("NSButtonTypeMultiLevelAccelerator", 9),
        ]
        data["NSBezelStyle"] = [
            item("NSBezelStyleAutomatic", 0),
            item("NSBezelStylePush", 1),
            item("NSBezelStyleFlexiblePush", 2),
            item("NSBezelStyleDisclosure", 5),
            item("NSBezelStyleShadowlessSquare", 6),
            item("NSBezelStyleCircular", 7),
            item("NSBezelStyleTexturedSquare", 8),
            item("NSBezelStyleHelpButton", 9),
            item("NSBezelStyleSmallSquare", 10),
            item("NSBezelStyleToolbar", 11),
            item("NSBezelStyleAccessoryBarAction", 12),
            item("NSBezelStyleAccessoryBar", 13),
            item("NSBezelStylePushDisclosure", 14),
            item("NSBezelStyleBadge", 15),
        ]
        data["NSTextFieldBezelStyle"] = [
            item("NSTextFieldSquareBezel", 0),
            item("NSTextFieldRoundedBezel", 1),
        ]
        data["NSLineBreakStrategy"] = [
            item("NSLineBreakStrategyNone", 0),
            item("NSLineBreakStrategyPushOut", 1),
            item("NSLineBreakStrategyHangulWordPriority", 2),
            item("NSLineBreakStrategyStandard", 0xFFFF),
        ]
        data["NSCellImagePosition"] = [
            item("NSNoImage", 0),
            item("NSImageOnly", 1),
            item("NSImageLeft", 2),
            item("NSImageRight", 3),
            item("NSImageBelow", 4),
            item("NSImageAbove", 5),
            item("NSImageOverlaps", 6),
            item("NSImageLeading", 7),
            item("NSImageTrailing", 8),
        ]
        data["NSImageScaling"] = [
            item("NSImageScaleProportionallyDown", 0),
            item("NSImageScaleAxesIndependently", 1),
            item("NSImageScaleNone", 2),
            item("NSImageScaleProportionallyUpOrDown", 3),
        ]
        data["NSImageAlignment"] = [
            item("NSImageAlignCenter", 0),
            item("NSImageAlignTop", 1),
            item("NSImageAlignTopLeft", 2),
            item("NSImageAlignTopRight", 3),
            item("NSImageAlignLeft", 4),
            item("NSImageAlignBottom", 5),
            item("NSImageAlignBottomLeft", 6),
            item("NSImageAlignBottomRight", 7),
            item("NSImageAlignRight", 8),
        ]
        data["NSImageFrameStyle"] = [
            item("NSImageFrameNone", 0),
            item("NSImageFramePhoto", 1),
            item("NSImageFrameGrayBezel", 2),
            item("NSImageFrameGroove", 3),
            item("NSImageFrameButton", 4),
        ]
        data["NSControlStateValue"] = [
            item("NSControlStateValueOff", 0),
            item("NSControlStateValueOn", 1),
            item("NSControlStateValueMixed", -1),
        ]

        data["NSControlSize"] = [
            item("NSControlSizeRegular", 0),
            item("NSControlSizeSmall", 1),
            item("NSControlSizeMini", 2),
            item("NSControlSizeLarge", 3),
        ]
        data["NSEventModifierFlags"] = [
            item("NSEventModifierFlagCapsLock", 1 << 16),
            item("NSEventModifierFlagShift", 1 << 17),
            item("NSEventModifierFlagControl", 1 << 18),
            item("NSEventModifierFlagOption", 1 << 19),
            item("NSEventModifierFlagCommand", 1 << 20),
            item("NSEventModifierFlagNumericPad", 1 << 21),
            item("NSEventModifierFlagHelp", 1 << 22),
            item("NSEventModifierFlagFunction", 1 << 23),
        ]
        data["NSScrollElasticity"] = [
            item("NSScrollElasticityAutomatic", 0),
            item("NSScrollElasticityNone", 1),
            item("NSScrollElasticityAllowed", 2),
        ]
        data["NSBorderType"] = [
            item("NSNoBorder", 0),
            item("NSLineBorder", 1),
            item("NSBezelBorder", 2),
            item("NSGrooveBorder", 3),
        ]
        data["NSScrollerStyle"] = [
            item("NSScrollerStyleLegacy", 0),
            item("NSScrollerStyleOverlay", 1),
        ]
        data["NSScrollerKnobStyle"] = [
            item("NSScrollerKnobStyleDefault", 0),
            item("NSScrollerKnobStyleDark", 1),
            item("NSScrollerKnobStyleLight", 2),
        ]
        data["NSTableViewColumnAutoresizingStyle"] = [
            item("NSTableViewNoColumnAutoresizing", 0),
            item("NSTableViewUniformColumnAutoresizingStyle", 1),
            item("NSTableViewSequentialColumnAutoresizingStyle", 2),
            item("NSTableViewReverseSequentialColumnAutoresizingStyle", 3),
            item("NSTableViewLastColumnOnlyAutoresizingStyle", 4),
            item("NSTableViewFirstColumnOnlyAutoresizingStyle", 5),
        ]
        data["NSTableViewGridLineStyle"] = [
            item("NSTableViewGridNone", 0),
            item("NSTableViewSolidVerticalGridLineMask", 1 << 0),
            item("NSTableViewSolidHorizontalGridLineMask", 1 << 1),
            item("NSTableViewDashedHorizontalGridLineMask", 1 << 3),
        ]
        data["NSTableViewRowSizeStyle"] = [
            item("NSTableViewRowSizeStyleDefault", -1),
            item("NSTableViewRowSizeStyleCustom", 0),
            item("NSTableViewRowSizeStyleSmall", 1),
            item("NSTableViewRowSizeStyleMedium", 2),
            item("NSTableViewRowSizeStyleLarge", 3),
        ]
        data["NSTableViewStyle"] = [
            item("NSTableViewStyleAutomatic", 0),
            item("NSTableViewStyleFullWidth", 1),
            item("NSTableViewStyleInset", 2),
            item("NSTableViewStyleSourceList", 3),
            item("NSTableViewStylePlain", 4),
        ]
        data["NSTableViewSelectionHighlightStyle"] = [
            item("NSTableViewSelectionHighlightStyleNone", -1),
            item("NSTableViewSelectionHighlightStyleRegular", 0),
            item("NSTableViewSelectionHighlightStyleSourceList", 1),
        ]
        data["NSTableViewDraggingDestinationFeedbackStyle"] = [
            item("NSTableViewDraggingDestinationFeedbackStyleNone", -1),
            item("NSTableViewDraggingDestinationFeedbackStyleRegular", 0),
            item("NSTableViewDraggingDestinationFeedbackStyleSourceList", 1),
            item("NSTableViewDraggingDestinationFeedbackStyleGap", 2),
        ]
        data["NSUserInterfaceLayoutDirection"] = [
            item("NSUserInterfaceLayoutDirectionLeftToRight", 0),
            item("NSUserInterfaceLayoutDirectionRightToLeft", 1),
        ]
        data["NSVisualEffectMaterial"] = [
            item("NSVisualEffectMaterialAppearanceBased", 0),
            item("NSVisualEffectMaterialLight", 1),
            item("NSVisualEffectMaterialDark", 2),
            item("NSVisualEffectMaterialTitlebar", 3),
            item("NSVisualEffectMaterialSelection", 4),
            item("NSVisualEffectMaterialMenu", 5),
            item("NSVisualEffectMaterialPopover", 6),
            item("NSVisualEffectMaterialSidebar", 7),
            item("NSVisualEffectMaterialMediumLight", 8),
            item("NSVisualEffectMaterialUltraDark", 9),
            item("NSVisualEffectMaterialHeaderView", 10),
            item("NSVisualEffectMaterialSheet", 11),
            item("NSVisualEffectMaterialWindowBackground", 12),
            item("NSVisualEffectMaterialHUDWindow", 13),
            item("NSVisualEffectMaterialFullScreenUI", 15),
            item("NSVisualEffectMaterialToolTip", 17),
            item("NSVisualEffectMaterialContentBackground", 18),
            item("NSVisualEffectMaterialUnderWindowBackground", 21),
            item("NSVisualEffectMaterialUnderPageBackground", 22),
        ]
        data["NSVisualEffectBlendingMode"] = [
            item("NSVisualEffectBlendingModeBehindWindow", 0),
            item("NSVisualEffectBlendingModeWithinWindow", 1),
        ]
        data["NSVisualEffectState"] = [
            item("NSVisualEffectStateFollowsWindowActiveState", 0),
            item("NSVisualEffectStateActive", 1),
            item("NSVisualEffectStateInactive", 2),
        ]
        data["NSBackgroundStyle"] = [
            item("NSBackgroundStyleNormal", 0),
            item("NSBackgroundStyleEmphasized", 1),
            item("NSBackgroundStyleRaised", 2),
            item("NSBackgroundStyleLowered", 3),
        ]
        data["NSStackViewDistribution"] = [
            item("NSStackViewDistributionGravityAreas", -1),
            item("NSStackViewDistributionFill", 0),
            item("NSStackViewDistributionFillEqually", 1),
            item("NSStackViewDistributionFillProportionally", 2),
            item("NSStackViewDistributionEqualSpacing", 3),
            item("NSStackViewDistributionEqualCentering", 4),
        ]
        data["NSUserInterfaceLayoutOrientation"] = [
            item("NSUserInterfaceLayoutOrientationHorizontal", 0),
            item("NSUserInterfaceLayoutOrientationVertical", 1),
        ]
        data["NSLayoutAttribute"] = [
            item("NSLayoutAttributeNotAnAttribute", 0),
            item("NSLayoutAttributeLeft", 1),
            item("NSLayoutAttributeRight", 2),
            item("NSLayoutAttributeTop", 3),
            item("NSLayoutAttributeBottom", 4),
            item("NSLayoutAttributeLeading", 5),
            item("NSLayoutAttributeTrailing", 6),
            item("NSLayoutAttributeWidth", 7),
            item("NSLayoutAttributeHeight", 8),
            item("NSLayoutAttributeCenterX", 9),
            item("NSLayoutAttributeCenterY", 10),
            item("NSLayoutAttributeLastBaseline", 11),
            item("NSLayoutAttributeFirstBaseline", 12),
        ]
        data["NSWindowTitleVisibility"] = [
            item("NSWindowTitleVisible", 0),
            item("NSWindowTitleHidden", 1),
        ]
        data["NSWindowAnimationBehavior"] = [
            item("NSWindowAnimationBehaviorDefault", 0),
            item("NSWindowAnimationBehaviorNone", 2),
            item("NSWindowAnimationBehaviorDocumentWindow", 3),
            item("NSWindowAnimationBehaviorUtilityWindow", 4),
            item("NSWindowAnimationBehaviorAlertPanel", 5),
        ]
        data["NSWindowToolbarStyle"] = [
            item("NSWindowToolbarStyleAutomatic", 0),
            item("NSWindowToolbarStyleExpanded", 1),
            item("NSWindowToolbarStylePreference", 2),
            item("NSWindowToolbarStyleUnified", 3),
            item("NSWindowToolbarStyleUnifiedCompact", 4),
        ]
        data["NSTitlebarSeparatorStyle"] = [
            item("NSTitlebarSeparatorStyleAutomatic", 0),
            item("NSTitlebarSeparatorStyleNone", 1),
            item("NSTitlebarSeparatorStyleLine", 2),
            item("NSTitlebarSeparatorStyleShadow", 3),
        ]
        data["NSWindowLevel"] = [
            item("NSNormalWindowLevel", 0),
            item("NSFloatingWindowLevel", 3),
            item("NSSubmenuWindowLevel", 3),
            item("NSTornOffMenuWindowLevel", 3),
            item("NSModalPanelWindowLevel", 8),
            item("NSMainMenuWindowLevel", 24),
            item("NSStatusWindowLevel", 25),
            item("NSPopUpMenuWindowLevel", 101),
            item("NSScreenSaverWindowLevel", 1000),
        ]
        data["NSWindowTabbingMode"] = [
            item("NSWindowTabbingModeAutomatic", 0),
            item("NSWindowTabbingModePreferred", 1),
            item("NSWindowTabbingModeDisallowed", 2),
        ]

        // MARK: - UIWindowScene

        data["UISceneActivationState"] = [
            item("UISceneActivationStateUnattached", -1),
            item("UISceneActivationStateForegroundActive", 0),
            item("UISceneActivationStateForegroundInactive", 1),
            item("UISceneActivationStateBackground", 2),
        ]
        data["UIInterfaceOrientation"] = [
            item("UIInterfaceOrientationUnknown", 0),
            item("UIInterfaceOrientationPortrait", 1),
            item("UIInterfaceOrientationPortraitUpsideDown", 2),
            item("UIInterfaceOrientationLandscapeLeft", 3),
            item("UIInterfaceOrientationLandscapeRight", 4),
        ]
        data["UIStatusBarStyle"] = [
            item("UIStatusBarStyleDefault", 0),
            item("UIStatusBarStyleLightContent", 1),
            item("UIStatusBarStyleDarkContent", 3),
        ]
        data["UIUserInterfaceStyle"] = [
            item("UIUserInterfaceStyleUnspecified", 0),
            item("UIUserInterfaceStyleLight", 1),
            item("UIUserInterfaceStyleDark", 2),
        ]
        data["UIUserInterfaceSizeClass"] = [
            item("UIUserInterfaceSizeClassUnspecified", 0),
            item("UIUserInterfaceSizeClassCompact", 1),
            item("UIUserInterfaceSizeClassRegular", 2),
        ]

        // MARK: - UITraitCollection

        data["UIUserInterfaceIdiom"] = [
            item("UIUserInterfaceIdiomUnspecified", -1),
            item("UIUserInterfaceIdiomPhone", 0),
            item("UIUserInterfaceIdiomPad", 1),
            item("UIUserInterfaceIdiomTV", 2),
            item("UIUserInterfaceIdiomCarPlay", 3),
            item("UIUserInterfaceIdiomMac", 5, 14),
            item("UIUserInterfaceIdiomVision", 6, 17),
        ]
        data["UIUserInterfaceLevel"] = [
            item("UIUserInterfaceLevelUnspecified", -1),
            item("UIUserInterfaceLevelBase", 0),
            item("UIUserInterfaceLevelElevated", 1),
        ]
        data["UIUserInterfaceActiveAppearance"] = [
            item("UIUserInterfaceActiveAppearanceUnspecified", -1),
            item("UIUserInterfaceActiveAppearanceInactive", 0),
            item("UIUserInterfaceActiveAppearanceActive", 1),
        ]
        data["UIAccessibilityContrast"] = [
            item("UIAccessibilityContrastUnspecified", -1),
            item("UIAccessibilityContrastNormal", 0),
            item("UIAccessibilityContrastHigh", 1),
        ]
        data["UILegibilityWeight"] = [
            item("UILegibilityWeightUnspecified", -1),
            item("UILegibilityWeightRegular", 0),
            item("UILegibilityWeightBold", 1),
        ]
        data["UIForceTouchCapability"] = [
            item("UIForceTouchCapabilityUnknown", 0),
            item("UIForceTouchCapabilityUnavailable", 1),
            item("UIForceTouchCapabilityAvailable", 2),
        ]
        data["UIDisplayGamut"] = [
            item("UIDisplayGamutUnspecified", -1),
            item("UIDisplayGamutSRGB", 0),
            item("UIDisplayGamutP3", 1),
        ]
        data["UITraitEnvironmentLayoutDirection"] = [
            item("UITraitEnvironmentLayoutDirectionUnspecified", -1),
            item("UITraitEnvironmentLayoutDirectionLeftToRight", 0),
            item("UITraitEnvironmentLayoutDirectionRightToLeft", 1),
        ]
        data["UIImageDynamicRange"] = [
            item("UIImageDynamicRangeUnspecified", -1),
            item("UIImageDynamicRangeStandard", 0),
            item("UIImageDynamicRangeConstrainedHigh", 1),
            item("UIImageDynamicRangeHigh", 2),
        ]
        data["UISceneCaptureState"] = [
            item("UISceneCaptureStateUnspecified", -1),
            item("UISceneCaptureStateInactive", 0),
            item("UISceneCaptureStateActive", 1),
        ]

        // MARK: - NSSlider

        data["NSSliderType"] = [
            item("NSSliderTypeLinear", 0),
            item("NSSliderTypeCircular", 1),
        ]
        data["NSTickMarkPosition"] = [
            item("NSTickMarkPositionBelow", 0),
            item("NSTickMarkPositionAbove", 1),
            item("NSTickMarkPositionLeading", 0),
            item("NSTickMarkPositionTrailing", 1),
        ]

        // MARK: - NSProgressIndicator

        data["NSProgressIndicatorStyle"] = [
            item("NSProgressIndicatorStyleBar", 0),
            item("NSProgressIndicatorStyleSpinning", 1),
        ]

        // MARK: - NSSegmentedControl

        data["NSSegmentStyle"] = [
            item("NSSegmentStyleAutomatic", 0),
            item("NSSegmentStyleRounded", 1),
            item("NSSegmentStyleRoundRect", 3),
            item("NSSegmentStyleTexturedSquare", 4),
            item("NSSegmentStyleSmallSquare", 6),
            item("NSSegmentStyleSeparated", 8),
            item("NSSegmentStyleTexturedRounded", 2),
            item("NSSegmentStyleCapsule", 5),
        ]
        data["NSSegmentSwitchTracking"] = [
            item("NSSegmentSwitchTrackingSelectOne", 0),
            item("NSSegmentSwitchTrackingSelectAny", 1),
            item("NSSegmentSwitchTrackingMomentary", 2),
            item("NSSegmentSwitchTrackingMomentaryAccelerator", 3),
        ]

        // MARK: - NSPopUpButton

        data["NSRectEdge"] = [
            item("NSRectEdgeMinX", 0),
            item("NSRectEdgeMinY", 1),
            item("NSRectEdgeMaxX", 2),
            item("NSRectEdgeMaxY", 3),
        ]

        // MARK: - NSColorWell

        data["NSColorWellStyle"] = [
            item("NSColorWellStyleDefault", 0),
            item("NSColorWellStyleMinimal", 1),
            item("NSColorWellStyleExpanded", 2),
        ]

        // MARK: - NSDatePicker

        data["NSDatePickerStyle"] = [
            item("NSDatePickerStyleTextFieldAndStepper", 0),
            item("NSDatePickerStyleClockAndCalendar", 1),
            item("NSDatePickerStyleTextField", 2),
        ]
        data["NSDatePickerMode"] = [
            item("NSDatePickerModeSingle", 0),
            item("NSDatePickerModeRange", 1),
        ]

        // MARK: - NSLevelIndicator

        data["NSLevelIndicatorStyle"] = [
            item("NSLevelIndicatorStyleRelevancy", 0),
            item("NSLevelIndicatorStyleContinuousCapacity", 1),
            item("NSLevelIndicatorStyleDiscreteCapacity", 2),
            item("NSLevelIndicatorStyleRating", 3),
        ]

        // MARK: - NSBox

        data["NSBoxType"] = [
            item("NSBoxPrimary", 0),
            item("NSBoxSeparator", 2),
            item("NSBoxCustom", 4),
        ]
        data["NSTitlePosition"] = [
            item("NSNoTitle", 0),
            item("NSAboveTop", 1),
            item("NSAtTop", 2),
            item("NSBelowTop", 3),
            item("NSAboveBottom", 4),
            item("NSAtBottom", 5),
            item("NSBelowBottom", 6),
        ]

        // MARK: - NSSplitView

        data["NSSplitViewDividerStyle"] = [
            item("NSSplitViewDividerStyleThick", 1),
            item("NSSplitViewDividerStyleThin", 2),
            item("NSSplitViewDividerStylePaneSplitter", 3),
        ]

        // MARK: - NSTabView

        data["NSTabViewType"] = [
            item("NSTopTabsBezelBorder", 0),
            item("NSLeftTabsBezelBorder", 1),
            item("NSBottomTabsBezelBorder", 2),
            item("NSRightTabsBezelBorder", 3),
            item("NSNoTabsBezelBorder", 4),
            item("NSNoTabsLineBorder", 5),
            item("NSNoTabsNoBorder", 6),
        ]
        data["NSTabPosition"] = [
            item("NSTabPositionNone", 0),
            item("NSTabPositionTop", 1),
            item("NSTabPositionLeft", 2),
            item("NSTabPositionBottom", 3),
            item("NSTabPositionRight", 4),
        ]
        data["NSTabViewBorderType"] = [
            item("NSTabViewBorderTypeNone", 0),
            item("NSTabViewBorderTypeLine", 1),
            item("NSTabViewBorderTypeBezel", 2),
        ]

        // MARK: - NSGridView

        data["NSGridCellPlacement"] = [
            item("NSGridCellPlacementInherited", 0),
            item("NSGridCellPlacementNone", 1),
            item("NSGridCellPlacementLeading", 2),
            item("NSGridCellPlacementTop", 2),
            item("NSGridCellPlacementTrailing", 3),
            item("NSGridCellPlacementBottom", 3),
            item("NSGridCellPlacementCenter", 4),
            item("NSGridCellPlacementFill", 5),
        ]

        return data
    }
}
