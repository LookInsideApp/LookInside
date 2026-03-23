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
