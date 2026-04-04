//
//  LKEnumListRegistry.m
//  Lookin
//
//  Created by Li Kai on 2018/11/21.
//  https://lookin.work
//

#import "LKEnumListRegistry.h"

#define MakeItemWithVersion(descArg, valueArg, availableMinOSVersion) [LKEnumListRegistryKeyValueItem itemWithDesc:descArg value:valueArg availableOSVersion:availableMinOSVersion]
#define MakeItem(descArg, valueArg) MakeItemWithVersion(descArg, valueArg, 0)

@implementation LKEnumListRegistryKeyValueItem

+ (instancetype)itemWithDesc:(NSString *)desc value:(long)value availableOSVersion:(NSInteger)osVersion {
    LKEnumListRegistryKeyValueItem *MakeItem = [LKEnumListRegistryKeyValueItem new];
    MakeItem.desc = desc;
    MakeItem.value = value;
    MakeItem.availableOSVersion = osVersion;
    return MakeItem;
}

@end;

@interface LKEnumListRegistry ()

@property(nonatomic, copy) NSDictionary<NSString *, NSArray<LKEnumListRegistryKeyValueItem *> *> *data;

@end

@implementation LKEnumListRegistry

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static LKEnumListRegistry *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone{
    return [self sharedInstance];
}

- (instancetype)init {
    if (self = [super init]) {
        NSMutableDictionary *mData = [NSMutableDictionary dictionary];
        
        mData[@"UIControlContentVerticalAlignment"] = @[MakeItem(@"UIControlContentVerticalAlignmentCenter", 0),
                                                        MakeItem(@"UIControlContentVerticalAlignmentTop", 1),
                                                        MakeItem(@"UIControlContentVerticalAlignmentBottom", 2),
                                                        MakeItem(@"UIControlContentVerticalAlignmentFill", 3)];
        
        mData[@"UIControlContentHorizontalAlignment"] = @[MakeItem(@"UIControlContentHorizontalAlignmentCenter", 0),
                                                          MakeItem(@"UIControlContentHorizontalAlignmentLeft", 1),
                                                          MakeItem(@"UIControlContentHorizontalAlignmentRight", 2),
                                                          MakeItem(@"UIControlContentHorizontalAlignmentFill", 3),
                                                          MakeItemWithVersion(@"UIControlContentHorizontalAlignmentLeading", 4, 11),
                                                          MakeItemWithVersion(@"UIControlContentHorizontalAlignmentTrailing", 5, 11)];
        
        mData[@"UIViewContentMode"] = @[MakeItem(@"UIViewContentModeScaleToFill", 0),
                                        MakeItem(@"UIViewContentModeScaleAspectFit", 1),
                                        MakeItem(@"UIViewContentModeScaleAspectFill", 2),
                                        MakeItem(@"UIViewContentModeRedraw", 3),
                                        MakeItem(@"UIViewContentModeCenter", 4),
                                        MakeItem(@"UIViewContentModeTop", 5),
                                        MakeItem(@"UIViewContentModeBottom", 6),
                                        MakeItem(@"UIViewContentModeLeft", 7),
                                        MakeItem(@"UIViewContentModeRight", 8),
                                        MakeItem(@"UIViewContentModeTopLeft", 9),
                                        MakeItem(@"UIViewContentModeTopRight", 10),
                                        MakeItem(@"UIViewContentModeBottomLeft", 11),
                                        MakeItem(@"UIViewContentModeBottomRight", 12)];
        
        mData[@"UIViewTintAdjustmentMode"] = @[MakeItem(@"UIViewTintAdjustmentModeAutomatic", 0),
                                               MakeItem(@"UIViewTintAdjustmentModeNormal", 1),
                                               MakeItem(@"UIViewTintAdjustmentModeDimmed", 2)];
        
        mData[@"NSTextAlignment"] = @[MakeItem(@"NSTextAlignmentLeft", 0),
                                      MakeItem(@"NSTextAlignmentCenter", 1),
                                      MakeItem(@"NSTextAlignmentRight", 2),
                                      MakeItem(@"NSTextAlignmentJustified", 3),
                                      MakeItem(@"NSTextAlignmentNatural", 4)];
        
        mData[@"NSLineBreakMode"] = @[MakeItem(@"NSLineBreakByWordWrapping", 0),
                                      MakeItem(@"NSLineBreakByCharWrapping", 1),
                                      MakeItem(@"NSLineBreakByClipping", 2),
                                      MakeItem(@"NSLineBreakByTruncatingHead", 3),
                                      MakeItem(@"NSLineBreakByTruncatingTail", 4),
                                      MakeItem(@"NSLineBreakByTruncatingMiddle", 5)];
        
        mData[@"UIScrollViewContentInsetAdjustmentBehavior"] = @[
            MakeItem(@"UIScrollViewContentInsetAdjustmentAutomatic", 0),
            MakeItem(@"UIScrollViewContentInsetAdjustmentScrollableAxes", 1),
            MakeItem(@"UIScrollViewContentInsetAdjustmentNever", 2),
            MakeItem(@"UIScrollViewContentInsetAdjustmentAlways", 3)];
        
        mData[@"UITableViewStyle"] = @[MakeItem(@"UITableViewStylePlain", 0),
                                       MakeItem(@"UITableViewStyleGrouped", 1)];
        
        mData[@"UITextFieldViewMode"] = @[MakeItem(@"UITextFieldViewModeNever", 0),
                                          MakeItem(@"UITextFieldViewModeWhileEditing", 1),
                                          MakeItem(@"UITextFieldViewModeUnlessEditing", 2),
                                          MakeItem(@"UITextFieldViewModeAlways", 3)];
        
        mData[@"UIAccessibilityNavigationStyle"] = @[
            MakeItem(@"UIAccessibilityNavigationStyleAutomatic", 0),
            MakeItem(@"UIAccessibilityNavigationStyleSeparate", 1),
            MakeItem(@"UIAccessibilityNavigationStyleCombined", 2)];
        
        mData[@"QMUIButtonImagePosition"] = @[
            MakeItem(@"QMUIButtonImagePositionTop", 0),
            MakeItem(@"QMUIButtonImagePositionLeft", 1),
            MakeItem(@"QMUIButtonImagePositionBottom", 2),
            MakeItem(@"QMUIButtonImagePositionRight", 3)];
        
        mData[@"UITableViewCellSeparatorStyle"] = @[
            MakeItem(@"UITableViewCellSeparatorStyleNone", 0),
            MakeItem(@"UITableViewCellSeparatorStyleSingleLine", 1),
            MakeItem(@"UITableViewCellSeparatorStyleSingleLineEtched", 2)];
        
        mData[@"UIBlurEffectStyle"] = @[
            MakeItem(@"UIBlurEffectStyleExtraLight", 0),
            MakeItem(@"UIBlurEffectStyleLight", 1),
            MakeItem(@"UIBlurEffectStyleDark", 2),
//            MakeItem(@"UIBlurEffectStyleExtraDark", 3), // 该值被官方标注了 API_UNAVAILABLE(ios)，因此这里跳过
            MakeItemWithVersion(@"UIBlurEffectStyleRegular", 4, 10),
            MakeItemWithVersion(@"UIBlurEffectStyleProminent", 5, 10),
            MakeItemWithVersion(@"UIBlurEffectStyleSystemUltraThinMaterial", 6, 13),
            MakeItemWithVersion(@"UIBlurEffectStyleSystemThinMaterial", 7, 13),
            MakeItemWithVersion(@"UIBlurEffectStyleSystemMaterial", 8, 13),
            MakeItemWithVersion(@"UIBlurEffectStyleSystemThickMaterial", 9, 13),
            MakeItemWithVersion(@"UIBlurEffectStyleSystemChromeMaterial", 10, 13),
            MakeItemWithVersion(@"UIBlurEffectStyleSystemUltraThinMaterialLight", 11, 13),
            MakeItemWithVersion(@"UIBlurEffectStyleSystemThinMaterialLight", 12, 13),
            MakeItemWithVersion(@"UIBlurEffectStyleSystemMaterialLight", 13, 13),
            MakeItemWithVersion(@"UIBlurEffectStyleSystemThickMaterialLight", 14, 13),
            MakeItemWithVersion(@"UIBlurEffectStyleSystemChromeMaterialLight", 15, 13),
            MakeItemWithVersion(@"UIBlurEffectStyleSystemUltraThinMaterialDark", 16, 13),
            MakeItemWithVersion(@"UIBlurEffectStyleSystemThinMaterialDark", 17, 13),
            MakeItemWithVersion(@"UIBlurEffectStyleSystemMaterialDark", 18, 13),
            MakeItemWithVersion(@"UIBlurEffectStyleSystemThickMaterialDark", 19, 13),
            MakeItemWithVersion(@"UIBlurEffectStyleSystemChromeMaterialDark", 20, 13),
        ];
        
        mData[@"UILayoutConstraintAxis"] = @[
            MakeItem(@"UILayoutConstraintAxisHorizontal", 0),
            MakeItem(@"UILayoutConstraintAxisVertical", 1),
        ];
        
        mData[@"UIStackViewDistribution"] = @[
            MakeItem(@"UIStackViewDistributionFill", 0),
            MakeItem(@"UIStackViewDistributionFillEqually", 1),
            MakeItem(@"UIStackViewDistributionFillProportionally", 2),
            MakeItem(@"UIStackViewDistributionEqualSpacing", 3),
            MakeItem(@"UIStackViewDistributionEqualCentering", 4)
        ];
        
        mData[@"UIStackViewAlignment"] = @[
            MakeItem(@"UIStackViewAlignmentFill", 0),
            MakeItem(@"UIStackViewAlignmentLeading (Top)", 1),
            MakeItem(@"UIStackViewAlignmentFirstBaseline", 2),
            MakeItem(@"UIStackViewAlignmentCenter", 3),
            MakeItem(@"UIStackViewAlignmentTrailing (Bottom)", 4),
            MakeItem(@"UIStackViewAlignmentLastBaseline", 5)
        ];
        mData[@"NSWritingDirection"] = @[
            MakeItem(@"NSWritingDirectionNatural", -1),
            MakeItem(@"NSWritingDirectionLeftToRight", 0),
            MakeItem(@"NSWritingDirectionRightToLeft", 1)
        ];
        mData[@"NSTextAlignment_AppKit"] = @[
            MakeItem(@"NSTextAlignmentLeft", 0),
            MakeItem(@"NSTextAlignmentRight", 1),
            MakeItem(@"NSTextAlignmentCenter", 2),
            MakeItem(@"NSTextAlignmentJustified", 3),
            MakeItem(@"NSTextAlignmentNatural", 4)
        ];
        mData[@"NSButtonType"] = @[
            MakeItem(@"NSButtonTypeMomentaryLight", 0),
            MakeItem(@"NSButtonTypePushOnPushOff", 1),
            MakeItem(@"NSButtonTypeToggle", 2),
            MakeItem(@"NSButtonTypeSwitch", 3),
            MakeItem(@"NSButtonTypeRadio", 4),
            MakeItem(@"NSButtonTypeMomentaryChange", 5),
            MakeItem(@"NSButtonTypeOnOff", 6),
            MakeItem(@"NSButtonTypeMomentaryPushIn", 7),
            MakeItem(@"NSButtonTypeAccelerator", 8),
            MakeItem(@"NSButtonTypeMultiLevelAccelerator", 9),
        ];
        mData[@"NSBezelStyle"] = @[
            MakeItem(@"NSBezelStyleAutomatic", 0),
            MakeItem(@"NSBezelStylePush", 1),
            MakeItem(@"NSBezelStyleFlexiblePush", 2),
            MakeItem(@"NSBezelStyleDisclosure", 5),
            MakeItem(@"NSBezelStyleShadowlessSquare", 6),
            MakeItem(@"NSBezelStyleCircular", 7),
            MakeItem(@"NSBezelStyleTexturedSquare", 8),
            MakeItem(@"NSBezelStyleHelpButton", 9),
            MakeItem(@"NSBezelStyleSmallSquare", 10),
            MakeItem(@"NSBezelStyleToolbar", 11),
            MakeItem(@"NSBezelStyleAccessoryBarAction", 12),
            MakeItem(@"NSBezelStyleAccessoryBar", 13),
            MakeItem(@"NSBezelStylePushDisclosure", 14),
            MakeItem(@"NSBezelStyleBadge", 15),
        ];
        mData[@"NSTextFieldBezelStyle"] = @[
            MakeItem(@"NSTextFieldSquareBezel", 0),
            MakeItem(@"NSTextFieldRoundedBezel", 1),
        ];
        mData[@"NSLineBreakStrategy"] = @[
            MakeItem(@"NSLineBreakStrategyNone", 0),
            MakeItem(@"NSLineBreakStrategyPushOut", 1),
            MakeItem(@"NSLineBreakStrategyHangulWordPriority", 2),
            MakeItem(@"NSLineBreakStrategyStandard", 0xFFFF),
        ];
        mData[@"NSCellImagePosition"] = @[
            MakeItem(@"NSNoImage", 0),
            MakeItem(@"NSImageOnly", 1),
            MakeItem(@"NSImageLeft", 2),
            MakeItem(@"NSImageRight", 3),
            MakeItem(@"NSImageBelow", 4),
            MakeItem(@"NSImageAbove", 5),
            MakeItem(@"NSImageOverlaps", 6),
            MakeItem(@"NSImageLeading", 7),
            MakeItem(@"NSImageTrailing", 8),
        ];
        mData[@"NSImageScaling"] = @[
            MakeItem(@"NSImageScaleProportionallyDown", 0),
            MakeItem(@"NSImageScaleAxesIndependently", 1),
            MakeItem(@"NSImageScaleNone", 2),
            MakeItem(@"NSImageScaleProportionallyUpOrDown", 3),
        ];
        mData[@"NSImageAlignment"] = @[
            MakeItem(@"NSImageAlignCenter", 0),
            MakeItem(@"NSImageAlignTop", 1),
            MakeItem(@"NSImageAlignTopLeft", 2),
            MakeItem(@"NSImageAlignTopRight", 3),
            MakeItem(@"NSImageAlignLeft", 4),
            MakeItem(@"NSImageAlignBottom", 5),
            MakeItem(@"NSImageAlignBottomLeft", 6),
            MakeItem(@"NSImageAlignBottomRight", 7),
            MakeItem(@"NSImageAlignRight", 8),
        ];
        mData[@"NSImageFrameStyle"] = @[
            MakeItem(@"NSImageFrameNone", 0),
            MakeItem(@"NSImageFramePhoto", 1),
            MakeItem(@"NSImageFrameGrayBezel", 2),
            MakeItem(@"NSImageFrameGroove", 3),
            MakeItem(@"NSImageFrameButton", 4),
        ];
        mData[@"NSControlStateValue"] = @[
            MakeItem(@"NSControlStateValueOff", 0),
            MakeItem(@"NSControlStateValueOn", 1),
            MakeItem(@"NSControlStateValueMixed", -1),
        ];
        
        mData[@"NSControlSize"] = @[
            MakeItem(@"NSControlSizeRegular", 0),
            MakeItem(@"NSControlSizeSmall", 1),
            MakeItem(@"NSControlSizeMini", 2),
            MakeItem(@"NSControlSizeLarge", 3),
        ];
        mData[@"NSEventModifierFlags"] = @[
            MakeItem(@"NSEventModifierFlagCapsLock", 1 << 16),
            MakeItem(@"NSEventModifierFlagShift", 1 << 17),
            MakeItem(@"NSEventModifierFlagControl", 1 << 18),
            MakeItem(@"NSEventModifierFlagOption", 1 << 19),
            MakeItem(@"NSEventModifierFlagCommand", 1 << 20),
            MakeItem(@"NSEventModifierFlagNumericPad", 1 << 21),
            MakeItem(@"NSEventModifierFlagHelp", 1 << 22),
            MakeItem(@"NSEventModifierFlagFunction", 1 << 23),
        ];
        mData[@"NSScrollElasticity"] = @[
            MakeItem(@"NSScrollElasticityAutomatic", 0),
            MakeItem(@"NSScrollElasticityNone", 1),
            MakeItem(@"NSScrollElasticityAllowed", 2),
        ];
        mData[@"NSBorderType"] = @[
            MakeItem(@"NSNoBorder", 0),
            MakeItem(@"NSLineBorder", 1),
            MakeItem(@"NSBezelBorder", 2),
            MakeItem(@"NSGrooveBorder", 3),
        ];
        mData[@"NSScrollerStyle"] = @[
            MakeItem(@"NSScrollerStyleLegacy", 0),
            MakeItem(@"NSScrollerStyleOverlay", 1),
        ];
        mData[@"NSScrollerKnobStyle"] = @[
            MakeItem(@"NSScrollerKnobStyleDefault", 0),
            MakeItem(@"NSScrollerKnobStyleDark", 1),
            MakeItem(@"NSScrollerKnobStyleLight", 2),
        ];
        mData[@"NSTableViewColumnAutoresizingStyle"] = @[
            MakeItem(@"NSTableViewNoColumnAutoresizing", 0),
            MakeItem(@"NSTableViewUniformColumnAutoresizingStyle", 1),
            MakeItem(@"NSTableViewSequentialColumnAutoresizingStyle", 2),
            MakeItem(@"NSTableViewReverseSequentialColumnAutoresizingStyle", 3),
            MakeItem(@"NSTableViewLastColumnOnlyAutoresizingStyle", 4),
            MakeItem(@"NSTableViewFirstColumnOnlyAutoresizingStyle", 5),
        ];
        mData[@"NSTableViewGridLineStyle"] = @[
            MakeItem(@"NSTableViewGridNone", 0),
            MakeItem(@"NSTableViewSolidVerticalGridLineMask", 1 << 0),
            MakeItem(@"NSTableViewSolidHorizontalGridLineMask", 1 << 1),
            MakeItem(@"NSTableViewDashedHorizontalGridLineMask", 1 << 3),
        ];
        mData[@"NSTableViewRowSizeStyle"] = @[
            MakeItem(@"NSTableViewRowSizeStyleDefault", -1),
            MakeItem(@"NSTableViewRowSizeStyleCustom", 0),
            MakeItem(@"NSTableViewRowSizeStyleSmall", 1),
            MakeItem(@"NSTableViewRowSizeStyleMedium", 2),
            MakeItem(@"NSTableViewRowSizeStyleLarge", 3),
        ];
        mData[@"NSTableViewStyle"] = @[
            MakeItem(@"NSTableViewStyleAutomatic", 0),
            MakeItem(@"NSTableViewStyleFullWidth", 1),
            MakeItem(@"NSTableViewStyleInset", 2),
            MakeItem(@"NSTableViewStyleSourceList", 3),
            MakeItem(@"NSTableViewStylePlain", 4),
        ];
        mData[@"NSTableViewSelectionHighlightStyle"] = @[
            MakeItem(@"NSTableViewSelectionHighlightStyleNone", -1),
            MakeItem(@"NSTableViewSelectionHighlightStyleRegular", 0),
            MakeItem(@"NSTableViewSelectionHighlightStyleSourceList", 1),
        ];
        mData[@"NSTableViewDraggingDestinationFeedbackStyle"] = @[
            MakeItem(@"NSTableViewDraggingDestinationFeedbackStyleNone", -1),
            MakeItem(@"NSTableViewDraggingDestinationFeedbackStyleRegular", 0),
            MakeItem(@"NSTableViewDraggingDestinationFeedbackStyleSourceList", 1),
            MakeItem(@"NSTableViewDraggingDestinationFeedbackStyleGap", 2),
        ];
        mData[@"NSUserInterfaceLayoutDirection"] = @[
            MakeItem(@"NSUserInterfaceLayoutDirectionLeftToRight", 0),
            MakeItem(@"NSUserInterfaceLayoutDirectionRightToLeft", 1),
        ];
        mData[@"NSVisualEffectMaterial"] = @[
            MakeItem(@"NSVisualEffectMaterialAppearanceBased", 0),
            MakeItem(@"NSVisualEffectMaterialLight", 1),
            MakeItem(@"NSVisualEffectMaterialDark", 2),
            MakeItem(@"NSVisualEffectMaterialTitlebar", 3),
            MakeItem(@"NSVisualEffectMaterialSelection", 4),
            MakeItem(@"NSVisualEffectMaterialMenu", 5),
            MakeItem(@"NSVisualEffectMaterialPopover", 6),
            MakeItem(@"NSVisualEffectMaterialSidebar", 7),
            MakeItem(@"NSVisualEffectMaterialMediumLight", 8),
            MakeItem(@"NSVisualEffectMaterialUltraDark", 9),
            MakeItem(@"NSVisualEffectMaterialHeaderView", 10),
            MakeItem(@"NSVisualEffectMaterialSheet", 11),
            MakeItem(@"NSVisualEffectMaterialWindowBackground", 12),
            MakeItem(@"NSVisualEffectMaterialHUDWindow", 13),
            MakeItem(@"NSVisualEffectMaterialFullScreenUI", 15),
            MakeItem(@"NSVisualEffectMaterialToolTip", 17),
            MakeItem(@"NSVisualEffectMaterialContentBackground", 18),
            MakeItem(@"NSVisualEffectMaterialUnderWindowBackground", 21),
            MakeItem(@"NSVisualEffectMaterialUnderPageBackground", 22),
        ];
        mData[@"NSVisualEffectBlendingMode"] = @[
            MakeItem(@"NSVisualEffectBlendingModeBehindWindow", 0),
            MakeItem(@"NSVisualEffectBlendingModeWithinWindow", 1),
        ];
        mData[@"NSVisualEffectState"] = @[
            MakeItem(@"NSVisualEffectStateFollowsWindowActiveState", 0),
            MakeItem(@"NSVisualEffectStateActive", 1),
            MakeItem(@"NSVisualEffectStateInactive", 2),
        ];
        mData[@"NSBackgroundStyle"] = @[
            MakeItem(@"NSBackgroundStyleNormal", 0),
            MakeItem(@"NSBackgroundStyleEmphasized", 1),
            MakeItem(@"NSBackgroundStyleRaised", 2),
            MakeItem(@"NSBackgroundStyleLowered", 3),
        ];
        mData[@"NSStackViewDistribution"] = @[
            MakeItem(@"NSStackViewDistributionGravityAreas", -1),
            MakeItem(@"NSStackViewDistributionFill", 0),
            MakeItem(@"NSStackViewDistributionFillEqually", 1),
            MakeItem(@"NSStackViewDistributionFillProportionally", 2),
            MakeItem(@"NSStackViewDistributionEqualSpacing", 3),
            MakeItem(@"NSStackViewDistributionEqualCentering", 4),
        ];
        mData[@"NSUserInterfaceLayoutOrientation"] = @[
            MakeItem(@"NSUserInterfaceLayoutOrientationHorizontal", 0),
            MakeItem(@"NSUserInterfaceLayoutOrientationVertical", 1),
        ];
        mData[@"NSLayoutAttribute"] = @[
            MakeItem(@"NSLayoutAttributeNotAnAttribute", 0),
            MakeItem(@"NSLayoutAttributeLeft", 1),
            MakeItem(@"NSLayoutAttributeRight", 2),
            MakeItem(@"NSLayoutAttributeTop", 3),
            MakeItem(@"NSLayoutAttributeBottom", 4),
            MakeItem(@"NSLayoutAttributeLeading", 5),
            MakeItem(@"NSLayoutAttributeTrailing", 6),
            MakeItem(@"NSLayoutAttributeWidth", 7),
            MakeItem(@"NSLayoutAttributeHeight", 8),
            MakeItem(@"NSLayoutAttributeCenterX", 9),
            MakeItem(@"NSLayoutAttributeCenterY", 10),
            MakeItem(@"NSLayoutAttributeLastBaseline", 11),
            MakeItem(@"NSLayoutAttributeFirstBaseline", 12),
        ];
        mData[@"NSWindowTitleVisibility"] = @[
            MakeItem(@"NSWindowTitleVisible", 0),
            MakeItem(@"NSWindowTitleHidden", 1),
        ];
        mData[@"NSWindowAnimationBehavior"] = @[
            MakeItem(@"NSWindowAnimationBehaviorDefault", 0),
            MakeItem(@"NSWindowAnimationBehaviorNone", 2),
            MakeItem(@"NSWindowAnimationBehaviorDocumentWindow", 3),
            MakeItem(@"NSWindowAnimationBehaviorUtilityWindow", 4),
            MakeItem(@"NSWindowAnimationBehaviorAlertPanel", 5),
        ];
        mData[@"NSWindowToolbarStyle"] = @[
            MakeItem(@"NSWindowToolbarStyleAutomatic", 0),
            MakeItem(@"NSWindowToolbarStyleExpanded", 1),
            MakeItem(@"NSWindowToolbarStylePreference", 2),
            MakeItem(@"NSWindowToolbarStyleUnified", 3),
            MakeItem(@"NSWindowToolbarStyleUnifiedCompact", 4),
        ];
        mData[@"NSTitlebarSeparatorStyle"] = @[
            MakeItem(@"NSTitlebarSeparatorStyleAutomatic", 0),
            MakeItem(@"NSTitlebarSeparatorStyleNone", 1),
            MakeItem(@"NSTitlebarSeparatorStyleLine", 2),
            MakeItem(@"NSTitlebarSeparatorStyleShadow", 3),
        ];
        mData[@"NSWindowLevel"] = @[
            MakeItem(@"NSNormalWindowLevel", 0),
            MakeItem(@"NSFloatingWindowLevel", 3),
            MakeItem(@"NSSubmenuWindowLevel", 3),
            MakeItem(@"NSTornOffMenuWindowLevel", 3),
            MakeItem(@"NSModalPanelWindowLevel", 8),
            MakeItem(@"NSMainMenuWindowLevel", 24),
            MakeItem(@"NSStatusWindowLevel", 25),
            MakeItem(@"NSPopUpMenuWindowLevel", 101),
            MakeItem(@"NSScreenSaverWindowLevel", 1000),
        ];
        mData[@"NSWindowTabbingMode"] = @[
            MakeItem(@"NSWindowTabbingModeAutomatic", 0),
            MakeItem(@"NSWindowTabbingModePreferred", 1),
            MakeItem(@"NSWindowTabbingModeDisallowed", 2),
        ];

        // MARK: - UIWindowScene
        mData[@"UISceneActivationState"] = @[
            MakeItem(@"UISceneActivationStateUnattached", -1),
            MakeItem(@"UISceneActivationStateForegroundActive", 0),
            MakeItem(@"UISceneActivationStateForegroundInactive", 1),
            MakeItem(@"UISceneActivationStateBackground", 2),
        ];
        mData[@"UIInterfaceOrientation"] = @[
            MakeItem(@"UIInterfaceOrientationUnknown", 0),
            MakeItem(@"UIInterfaceOrientationPortrait", 1),
            MakeItem(@"UIInterfaceOrientationPortraitUpsideDown", 2),
            MakeItem(@"UIInterfaceOrientationLandscapeLeft", 3),
            MakeItem(@"UIInterfaceOrientationLandscapeRight", 4),
        ];
        mData[@"UIStatusBarStyle"] = @[
            MakeItem(@"UIStatusBarStyleDefault", 0),
            MakeItem(@"UIStatusBarStyleLightContent", 1),
            MakeItem(@"UIStatusBarStyleDarkContent", 3),
        ];
        mData[@"UIUserInterfaceStyle"] = @[
            MakeItem(@"UIUserInterfaceStyleUnspecified", 0),
            MakeItem(@"UIUserInterfaceStyleLight", 1),
            MakeItem(@"UIUserInterfaceStyleDark", 2),
        ];
        mData[@"UIUserInterfaceSizeClass"] = @[
            MakeItem(@"UIUserInterfaceSizeClassUnspecified", 0),
            MakeItem(@"UIUserInterfaceSizeClassCompact", 1),
            MakeItem(@"UIUserInterfaceSizeClassRegular", 2),
        ];

        // MARK: - UITraitCollection
        mData[@"UIUserInterfaceIdiom"] = @[
            MakeItem(@"UIUserInterfaceIdiomUnspecified", -1),
            MakeItem(@"UIUserInterfaceIdiomPhone", 0),
            MakeItem(@"UIUserInterfaceIdiomPad", 1),
            MakeItem(@"UIUserInterfaceIdiomTV", 2),
            MakeItem(@"UIUserInterfaceIdiomCarPlay", 3),
            MakeItemWithVersion(@"UIUserInterfaceIdiomMac", 5, 14),
            MakeItemWithVersion(@"UIUserInterfaceIdiomVision", 6, 17),
        ];
        mData[@"UIUserInterfaceLevel"] = @[
            MakeItem(@"UIUserInterfaceLevelUnspecified", -1),
            MakeItem(@"UIUserInterfaceLevelBase", 0),
            MakeItem(@"UIUserInterfaceLevelElevated", 1),
        ];
        mData[@"UIUserInterfaceActiveAppearance"] = @[
            MakeItem(@"UIUserInterfaceActiveAppearanceUnspecified", -1),
            MakeItem(@"UIUserInterfaceActiveAppearanceInactive", 0),
            MakeItem(@"UIUserInterfaceActiveAppearanceActive", 1),
        ];
        mData[@"UIAccessibilityContrast"] = @[
            MakeItem(@"UIAccessibilityContrastUnspecified", -1),
            MakeItem(@"UIAccessibilityContrastNormal", 0),
            MakeItem(@"UIAccessibilityContrastHigh", 1),
        ];
        mData[@"UILegibilityWeight"] = @[
            MakeItem(@"UILegibilityWeightUnspecified", -1),
            MakeItem(@"UILegibilityWeightRegular", 0),
            MakeItem(@"UILegibilityWeightBold", 1),
        ];
        mData[@"UIForceTouchCapability"] = @[
            MakeItem(@"UIForceTouchCapabilityUnknown", 0),
            MakeItem(@"UIForceTouchCapabilityUnavailable", 1),
            MakeItem(@"UIForceTouchCapabilityAvailable", 2),
        ];
        mData[@"UIDisplayGamut"] = @[
            MakeItem(@"UIDisplayGamutUnspecified", -1),
            MakeItem(@"UIDisplayGamutSRGB", 0),
            MakeItem(@"UIDisplayGamutP3", 1),
        ];
        mData[@"UITraitEnvironmentLayoutDirection"] = @[
            MakeItem(@"UITraitEnvironmentLayoutDirectionUnspecified", -1),
            MakeItem(@"UITraitEnvironmentLayoutDirectionLeftToRight", 0),
            MakeItem(@"UITraitEnvironmentLayoutDirectionRightToLeft", 1),
        ];
        mData[@"UIImageDynamicRange"] = @[
            MakeItem(@"UIImageDynamicRangeUnspecified", -1),
            MakeItem(@"UIImageDynamicRangeStandard", 0),
            MakeItem(@"UIImageDynamicRangeConstrainedHigh", 1),
            MakeItem(@"UIImageDynamicRangeHigh", 2),
        ];
        mData[@"UISceneCaptureState"] = @[
            MakeItem(@"UISceneCaptureStateUnspecified", -1),
            MakeItem(@"UISceneCaptureStateInactive", 0),
            MakeItem(@"UISceneCaptureStateActive", 1),
        ];

        // MARK: - NSSlider
        mData[@"NSSliderType"] = @[
            MakeItem(@"NSSliderTypeLinear", 0),
            MakeItem(@"NSSliderTypeCircular", 1),
        ];
        mData[@"NSTickMarkPosition"] = @[
            MakeItem(@"NSTickMarkPositionBelow", 0),
            MakeItem(@"NSTickMarkPositionAbove", 1),
            MakeItem(@"NSTickMarkPositionLeading", 0),
            MakeItem(@"NSTickMarkPositionTrailing", 1),
        ];

        // MARK: - NSProgressIndicator
        mData[@"NSProgressIndicatorStyle"] = @[
            MakeItem(@"NSProgressIndicatorStyleBar", 0),
            MakeItem(@"NSProgressIndicatorStyleSpinning", 1),
        ];

        // MARK: - NSSegmentedControl
        mData[@"NSSegmentStyle"] = @[
            MakeItem(@"NSSegmentStyleAutomatic", 0),
            MakeItem(@"NSSegmentStyleRounded", 1),
            MakeItem(@"NSSegmentStyleRoundRect", 3),
            MakeItem(@"NSSegmentStyleTexturedSquare", 4),
            MakeItem(@"NSSegmentStyleSmallSquare", 6),
            MakeItem(@"NSSegmentStyleSeparated", 8),
            MakeItem(@"NSSegmentStyleTexturedRounded", 2),
            MakeItem(@"NSSegmentStyleCapsule", 5),
        ];
        mData[@"NSSegmentSwitchTracking"] = @[
            MakeItem(@"NSSegmentSwitchTrackingSelectOne", 0),
            MakeItem(@"NSSegmentSwitchTrackingSelectAny", 1),
            MakeItem(@"NSSegmentSwitchTrackingMomentary", 2),
            MakeItem(@"NSSegmentSwitchTrackingMomentaryAccelerator", 3),
        ];

        // MARK: - NSPopUpButton
        mData[@"NSRectEdge"] = @[
            MakeItem(@"NSRectEdgeMinX", 0),
            MakeItem(@"NSRectEdgeMinY", 1),
            MakeItem(@"NSRectEdgeMaxX", 2),
            MakeItem(@"NSRectEdgeMaxY", 3),
        ];

        // MARK: - NSColorWell
        mData[@"NSColorWellStyle"] = @[
            MakeItem(@"NSColorWellStyleDefault", 0),
            MakeItem(@"NSColorWellStyleMinimal", 1),
            MakeItem(@"NSColorWellStyleExpanded", 2),
        ];

        // MARK: - NSDatePicker
        mData[@"NSDatePickerStyle"] = @[
            MakeItem(@"NSDatePickerStyleTextFieldAndStepper", 0),
            MakeItem(@"NSDatePickerStyleClockAndCalendar", 1),
            MakeItem(@"NSDatePickerStyleTextField", 2),
        ];
        mData[@"NSDatePickerMode"] = @[
            MakeItem(@"NSDatePickerModeSingle", 0),
            MakeItem(@"NSDatePickerModeRange", 1),
        ];

        // MARK: - NSLevelIndicator
        mData[@"NSLevelIndicatorStyle"] = @[
            MakeItem(@"NSLevelIndicatorStyleRelevancy", 0),
            MakeItem(@"NSLevelIndicatorStyleContinuousCapacity", 1),
            MakeItem(@"NSLevelIndicatorStyleDiscreteCapacity", 2),
            MakeItem(@"NSLevelIndicatorStyleRating", 3),
        ];

        // MARK: - NSBox
        mData[@"NSBoxType"] = @[
            MakeItem(@"NSBoxPrimary", 0),
            MakeItem(@"NSBoxSeparator", 2),
            MakeItem(@"NSBoxCustom", 4),
        ];
        mData[@"NSTitlePosition"] = @[
            MakeItem(@"NSNoTitle", 0),
            MakeItem(@"NSAboveTop", 1),
            MakeItem(@"NSAtTop", 2),
            MakeItem(@"NSBelowTop", 3),
            MakeItem(@"NSAboveBottom", 4),
            MakeItem(@"NSAtBottom", 5),
            MakeItem(@"NSBelowBottom", 6),
        ];

        // MARK: - NSSplitView
        mData[@"NSSplitViewDividerStyle"] = @[
            MakeItem(@"NSSplitViewDividerStyleThick", 1),
            MakeItem(@"NSSplitViewDividerStyleThin", 2),
            MakeItem(@"NSSplitViewDividerStylePaneSplitter", 3),
        ];

        // MARK: - NSTabView
        mData[@"NSTabViewType"] = @[
            MakeItem(@"NSTopTabsBezelBorder", 0),
            MakeItem(@"NSLeftTabsBezelBorder", 1),
            MakeItem(@"NSBottomTabsBezelBorder", 2),
            MakeItem(@"NSRightTabsBezelBorder", 3),
            MakeItem(@"NSNoTabsBezelBorder", 4),
            MakeItem(@"NSNoTabsLineBorder", 5),
            MakeItem(@"NSNoTabsNoBorder", 6),
        ];
        mData[@"NSTabPosition"] = @[
            MakeItem(@"NSTabPositionNone", 0),
            MakeItem(@"NSTabPositionTop", 1),
            MakeItem(@"NSTabPositionLeft", 2),
            MakeItem(@"NSTabPositionBottom", 3),
            MakeItem(@"NSTabPositionRight", 4),
        ];
        mData[@"NSTabViewBorderType"] = @[
            MakeItem(@"NSTabViewBorderTypeNone", 0),
            MakeItem(@"NSTabViewBorderTypeLine", 1),
            MakeItem(@"NSTabViewBorderTypeBezel", 2),
        ];

        // MARK: - NSGridView
        mData[@"NSGridCellPlacement"] = @[
            MakeItem(@"NSGridCellPlacementInherited", 0),
            MakeItem(@"NSGridCellPlacementNone", 1),
            MakeItem(@"NSGridCellPlacementLeading", 2),
            MakeItem(@"NSGridCellPlacementTop", 2),
            MakeItem(@"NSGridCellPlacementTrailing", 3),
            MakeItem(@"NSGridCellPlacementBottom", 3),
            MakeItem(@"NSGridCellPlacementCenter", 4),
            MakeItem(@"NSGridCellPlacementFill", 5),
        ];

        self.data = mData;
    }
    return self;
}

- (NSArray<LKEnumListRegistryKeyValueItem *> *)itemsForEnumName:(NSString *)enumName {
    NSArray<LKEnumListRegistryKeyValueItem *> *items = self.data[enumName];
    return items;
}

- (NSString *)descForEnumName:(NSString *)enumName value:(long)value {
    NSArray<LKEnumListRegistryKeyValueItem *> *items = [self itemsForEnumName:enumName];
    if (!items) {
        NSAssert(NO, @"");
        return nil;
    }
    LKEnumListRegistryKeyValueItem *MakeItem = [items lookin_firstFiltered:^BOOL(LKEnumListRegistryKeyValueItem *obj) {
        return (obj.value == value);
    }];
    return MakeItem.desc;
}

@end
