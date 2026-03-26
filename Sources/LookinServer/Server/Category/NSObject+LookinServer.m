#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION || TARGET_OS_MAC)
//
//  NSObject+LookinServer.m
//  LookinServer
//
//  Created by Li Kai on 2019/4/21.
//  https://lookin.work
//

#import "NSObject+Lookin.h"
#import "NSObject+LookinServer.h"
#import "NSArray+Lookin.h"
#import "LookinServerDefines.h"
#import "LKS_ObjectRegistry.h"
#if TARGET_OS_MAC
#import "LookinObject.h"
#import "LookinAutoLayoutConstraint.h"
#import "LKS_MultiplatformAdapter.h"

@interface LookinAutoLayoutConstraint (LookinServerFactory)
+ (instancetype)instanceFromNSConstraint:(NSLayoutConstraint *)constraint isEffective:(BOOL)isEffective firstItemType:(LookinConstraintItemType)firstItemType secondItemType:(LookinConstraintItemType)secondItemType;
@end
#endif
#import <objc/runtime.h>

@implementation NSObject (LookinServer)

#pragma mark - oid

- (unsigned long)lks_registerOid {
    if (!self.lks_oid) {
        unsigned long oid = [[LKS_ObjectRegistry sharedInstance] addObject:self];
        self.lks_oid = oid;
    }
    return self.lks_oid;
}

- (void)setLks_oid:(unsigned long)lks_oid {
    [self lookin_bindObject:@(lks_oid) forKey:@"lks_oid"];
}

- (unsigned long)lks_oid {
    NSNumber *number = [self lookin_getBindObjectForKey:@"lks_oid"];
    return [number unsignedLongValue];
}

+ (NSObject *)lks_objectWithOid:(unsigned long)oid {
    return [[LKS_ObjectRegistry sharedInstance] objectWithOid:oid];
}

#pragma mark - trace

- (void)setLks_ivarTraces:(NSArray<LookinIvarTrace *> *)lks_ivarTraces {
    [self lookin_bindObject:lks_ivarTraces.copy forKey:@"lks_ivarTraces"];
    
    if (lks_ivarTraces) {
        [[NSObject lks_allObjectsWithTraces] addPointer:(void *)self];
    }
}

- (NSArray<LookinIvarTrace *> *)lks_ivarTraces {
    return [self lookin_getBindObjectForKey:@"lks_ivarTraces"];
}

- (void)setLks_specialTrace:(NSString *)lks_specialTrace {
    [self lookin_bindObject:lks_specialTrace forKey:@"lks_specialTrace"];
    if (lks_specialTrace) {
        [[NSObject lks_allObjectsWithTraces] addPointer:(void *)self];
    }
}
- (NSString *)lks_specialTrace {
    return [self lookin_getBindObjectForKey:@"lks_specialTrace"];
}

+ (void)lks_clearAllObjectsTraces {
    [[[NSObject lks_allObjectsWithTraces] allObjects] enumerateObjectsUsingBlock:^(NSObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.lks_ivarTraces = nil;
        obj.lks_specialTrace = nil;
    }];
    [NSObject lks_allObjectsWithTraces].count = 0;
}

+ (NSPointerArray *)lks_allObjectsWithTraces {
    static dispatch_once_t onceToken;
    static NSPointerArray *lks_allObjectsWithTraces = nil;
    dispatch_once(&onceToken,^{
        lks_allObjectsWithTraces = [NSPointerArray weakObjectsPointerArray];
    });
    return lks_allObjectsWithTraces;
}

- (NSArray<NSString *> *)lks_classChainList {
    NSMutableArray<NSString *> *classChainList = [NSMutableArray array];
    Class currentClass = self.class;
    
    while (currentClass) {
        NSString *currentClassName = NSStringFromClass(currentClass);
        if (currentClassName) {
            [classChainList addObject:currentClassName];
        }
        currentClass = [currentClass superclass];
    }
    return classChainList.copy;
}

@end

#if TARGET_OS_MAC

static const void *LKUserInteractionEnabledKey = &LKUserInteractionEnabledKey;
static const void *LKContentModeKey = &LKContentModeKey;
static const void *LKTintColorKey = &LKTintColorKey;
static const void *LKTintAdjustmentModeKey = &LKTintAdjustmentModeKey;
static const void *LKTagKey = &LKTagKey;
static const void *LKSelectedKey = &LKSelectedKey;
static const void *LKContentVerticalAlignmentKey = &LKContentVerticalAlignmentKey;
static const void *LKContentHorizontalAlignmentKey = &LKContentHorizontalAlignmentKey;
static const void *LKOutsideEdgeKey = &LKOutsideEdgeKey;
static const void *LKButtonContentInsetsKey = &LKButtonContentInsetsKey;
static const void *LKButtonTitleInsetsKey = &LKButtonTitleInsetsKey;
static const void *LKButtonImageInsetsKey = &LKButtonImageInsetsKey;
static const void *LKScrollAdjustmentBehaviorKey = &LKScrollAdjustmentBehaviorKey;
static const void *LKScrollDelaysTouchesKey = &LKScrollDelaysTouchesKey;
static const void *LKScrollCanCancelTouchesKey = &LKScrollCanCancelTouchesKey;
static const void *LKTableStyleKey = &LKTableStyleKey;
static const void *LKTableSectionsKey = &LKTableSectionsKey;
static const void *LKTableSeparatorStyleKey = &LKTableSeparatorStyleKey;
static const void *LKTableSeparatorColorKey = &LKTableSeparatorColorKey;
static const void *LKTableSeparatorInsetKey = &LKTableSeparatorInsetKey;
static const void *LKTextClearsOnBeginEditingKey = &LKTextClearsOnBeginEditingKey;
static const void *LKTextClearButtonModeKey = &LKTextClearButtonModeKey;

static NSNumber *LKGetAssociatedNumber(id object, const void *key) {
    return objc_getAssociatedObject(object, key);
}

static void LKSetAssociatedNumber(id object, const void *key, NSInteger value) {
    objc_setAssociatedObject(object, key, @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static NSValue *LKGetAssociatedValue(id object, const void *key) {
    return objc_getAssociatedObject(object, key);
}

static void LKSetAssociatedEdgeInsets(id object, const void *key, NSEdgeInsets insets) {
    objc_setAssociatedObject(object, key, [NSValue valueWithEdgeInsets:insets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static NSEdgeInsets LKGetAssociatedEdgeInsets(id object, const void *key) {
    NSValue *value = LKGetAssociatedValue(object, key);
    return value ? value.edgeInsetsValue : NSEdgeInsetsZero;
}

@implementation NSView (LookinServer)

- (void)setLks_verticalContentHuggingPriority:(float)value {
    [self setContentHuggingPriority:value forOrientation:NSLayoutConstraintOrientationVertical];
}

- (float)lks_verticalContentHuggingPriority {
    return [self contentHuggingPriorityForOrientation:NSLayoutConstraintOrientationVertical];
}

- (void)setLks_horizontalContentHuggingPriority:(float)value {
    [self setContentHuggingPriority:value forOrientation:NSLayoutConstraintOrientationHorizontal];
}

- (float)lks_horizontalContentHuggingPriority {
    return [self contentHuggingPriorityForOrientation:NSLayoutConstraintOrientationHorizontal];
}

- (void)setLks_verticalContentCompressionResistancePriority:(float)value {
    [self setContentCompressionResistancePriority:value forOrientation:NSLayoutConstraintOrientationVertical];
}

- (float)lks_verticalContentCompressionResistancePriority {
    return [self contentCompressionResistancePriorityForOrientation:NSLayoutConstraintOrientationVertical];
}

- (void)setLks_horizontalContentCompressionResistancePriority:(float)value {
    [self setContentCompressionResistancePriority:value forOrientation:NSLayoutConstraintOrientationHorizontal];
}

- (float)lks_horizontalContentCompressionResistancePriority {
    return [self contentCompressionResistancePriorityForOrientation:NSLayoutConstraintOrientationHorizontal];
}

+ (void)lks_rebuildGlobalInvolvedRawConstraints {
    [[LKS_MultiplatformAdapter allWindows] enumerateObjectsUsingBlock:^(NSWindow *window, NSUInteger idx, BOOL *stop) {
        [self lks_removeInvolvedRawConstraintsForViewsRootedByView:window.contentView];
    }];
    [[LKS_MultiplatformAdapter allWindows] enumerateObjectsUsingBlock:^(NSWindow *window, NSUInteger idx, BOOL *stop) {
        [self lks_addInvolvedRawConstraintsForViewsRootedByView:window.contentView];
    }];
}

+ (void)lks_addInvolvedRawConstraintsForViewsRootedByView:(NSView *)rootView {
    [rootView.constraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop) {
        NSView *firstView = [constraint.firstItem isKindOfClass:[NSView class]] ? constraint.firstItem : nil;
        if (firstView && ![firstView.lks_involvedRawConstraints containsObject:constraint]) {
            if (!firstView.lks_involvedRawConstraints) {
                firstView.lks_involvedRawConstraints = [NSMutableArray array];
            }
            [firstView.lks_involvedRawConstraints addObject:constraint];
        }

        NSView *secondView = [constraint.secondItem isKindOfClass:[NSView class]] ? constraint.secondItem : nil;
        if (secondView && ![secondView.lks_involvedRawConstraints containsObject:constraint]) {
            if (!secondView.lks_involvedRawConstraints) {
                secondView.lks_involvedRawConstraints = [NSMutableArray array];
            }
            [secondView.lks_involvedRawConstraints addObject:constraint];
        }
    }];

    [rootView.subviews enumerateObjectsUsingBlock:^(NSView *subview, NSUInteger idx, BOOL *stop) {
        [self lks_addInvolvedRawConstraintsForViewsRootedByView:subview];
    }];
}

+ (void)lks_removeInvolvedRawConstraintsForViewsRootedByView:(NSView *)rootView {
    [rootView.lks_involvedRawConstraints removeAllObjects];
    [rootView.subviews enumerateObjectsUsingBlock:^(NSView *subview, NSUInteger idx, BOOL *stop) {
        [self lks_removeInvolvedRawConstraintsForViewsRootedByView:subview];
    }];
}

- (void)setLks_involvedRawConstraints:(NSMutableArray<NSLayoutConstraint *> *)constraints {
    [self lookin_bindObject:constraints forKey:@"lks_involvedRawConstraints"];
}

- (NSMutableArray<NSLayoutConstraint *> *)lks_involvedRawConstraints {
    return [self lookin_getBindObjectForKey:@"lks_involvedRawConstraints"];
}

- (NSArray<LookinAutoLayoutConstraint *> *)lks_constraints {
    NSMutableArray<NSLayoutConstraint *> *effectiveConstraints = [NSMutableArray array];
    [effectiveConstraints addObjectsFromArray:[self constraintsAffectingLayoutForOrientation:NSLayoutConstraintOrientationHorizontal]];
    [effectiveConstraints addObjectsFromArray:[self constraintsAffectingLayoutForOrientation:NSLayoutConstraintOrientationVertical]];

    NSArray<LookinAutoLayoutConstraint *> *constraints = [self.lks_involvedRawConstraints lookin_map:^id(NSUInteger idx, NSLayoutConstraint *constraint) {
        BOOL isEffective = [effectiveConstraints containsObject:constraint];
        if (!constraint.active) {
            return nil;
        }
        LookinConstraintItemType firstItemType = [self _lks_constraintItemTypeForItem:constraint.firstItem];
        LookinConstraintItemType secondItemType = [self _lks_constraintItemTypeForItem:constraint.secondItem];
        return [LookinAutoLayoutConstraint instanceFromNSConstraint:constraint
                                                        isEffective:isEffective
                                                      firstItemType:firstItemType
                                                     secondItemType:secondItemType];
    }];
    return constraints.count ? constraints : nil;
}

- (LookinConstraintItemType)_lks_constraintItemTypeForItem:(id)item {
    if (!item) {
        return LookinConstraintItemTypeNil;
    }
    if (item == self) {
        return LookinConstraintItemTypeSelf;
    }
    if (item == self.superview) {
        return LookinConstraintItemTypeSuper;
    }
    if ([item isKindOfClass:[NSLayoutGuide class]]) {
        return LookinConstraintItemTypeLayoutGuide;
    }
    if ([item isKindOfClass:[NSView class]]) {
        return LookinConstraintItemTypeView;
    }
    return LookinConstraintItemTypeUnknown;
}

- (void)setUserInteractionEnabled:(BOOL)value {
    objc_setAssociatedObject(self, LKUserInteractionEnabledKey, @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isUserInteractionEnabled {
    NSNumber *value = LKGetAssociatedNumber(self, LKUserInteractionEnabledKey);
    return value ? value.boolValue : YES;
}

- (void)setContentMode:(NSInteger)value {
    LKSetAssociatedNumber(self, LKContentModeKey, value);
    if ([self isKindOfClass:[NSImageView class]]) {
        NSImageView *imageView = (NSImageView *)self;
        switch (value) {
            case 1:
                imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
                break;
            case 2:
                imageView.imageScaling = NSImageScaleAxesIndependently;
                break;
            case 4:
                imageView.imageScaling = NSImageScaleNone;
                break;
            default:
                break;
        }
    }
}

- (NSInteger)contentMode {
    NSNumber *value = LKGetAssociatedNumber(self, LKContentModeKey);
    if (value) {
        return value.integerValue;
    }
    if ([self isKindOfClass:[NSImageView class]]) {
        switch (((NSImageView *)self).imageScaling) {
            case NSImageScaleNone:
                return 4;
            case NSImageScaleProportionallyUpOrDown:
            case NSImageScaleProportionallyDown:
                return 1;
            case NSImageScaleAxesIndependently:
                return 0;
        }
    }
    return 0;
}

- (void)setTintColor:(NSColor *)value {
    objc_setAssociatedObject(self, LKTintColorKey, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSColor *)tintColor {
    return objc_getAssociatedObject(self, LKTintColorKey);
}

- (void)setTintAdjustmentMode:(NSInteger)value {
    LKSetAssociatedNumber(self, LKTintAdjustmentModeKey, value);
}

- (NSInteger)tintAdjustmentMode {
    NSNumber *value = LKGetAssociatedNumber(self, LKTintAdjustmentModeKey);
    return value ? value.integerValue : 0;
}

- (void)setTag:(NSInteger)value {
    LKSetAssociatedNumber(self, LKTagKey, value);
}

- (NSInteger)tag {
    NSNumber *value = LKGetAssociatedNumber(self, LKTagKey);
    return value ? value.integerValue : 0;
}

@end

@implementation NSControl (LookinServer)

- (void)setSelected:(BOOL)value {
    if ([self isKindOfClass:[NSButton class]]) {
        ((NSButton *)self).state = value ? NSControlStateValueOn : NSControlStateValueOff;
        return;
    }
    objc_setAssociatedObject(self, LKSelectedKey, @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isSelected {
    if ([self isKindOfClass:[NSButton class]]) {
        return ((NSButton *)self).state == NSControlStateValueOn;
    }
    NSNumber *value = LKGetAssociatedNumber(self, LKSelectedKey);
    return value.boolValue;
}

- (void)setContentVerticalAlignment:(NSInteger)value {
    LKSetAssociatedNumber(self, LKContentVerticalAlignmentKey, value);
}

- (NSInteger)contentVerticalAlignment {
    NSNumber *value = LKGetAssociatedNumber(self, LKContentVerticalAlignmentKey);
    return value ? value.integerValue : 0;
}

- (void)setContentHorizontalAlignment:(NSInteger)value {
    LKSetAssociatedNumber(self, LKContentHorizontalAlignmentKey, value);
}

- (NSInteger)contentHorizontalAlignment {
    NSNumber *value = LKGetAssociatedNumber(self, LKContentHorizontalAlignmentKey);
    if (value) {
        return value.integerValue;
    }
    return 0;
}

- (void)setQmui_outsideEdge:(NSEdgeInsets)value {
    LKSetAssociatedEdgeInsets(self, LKOutsideEdgeKey, value);
}

- (NSEdgeInsets)qmui_outsideEdge {
    return LKGetAssociatedEdgeInsets(self, LKOutsideEdgeKey);
}

@end

@implementation NSButton (LookinServer)

- (void)setContentEdgeInsets:(NSEdgeInsets)value {
    LKSetAssociatedEdgeInsets(self, LKButtonContentInsetsKey, value);
}

- (NSEdgeInsets)contentEdgeInsets {
    return LKGetAssociatedEdgeInsets(self, LKButtonContentInsetsKey);
}

- (void)setTitleEdgeInsets:(NSEdgeInsets)value {
    LKSetAssociatedEdgeInsets(self, LKButtonTitleInsetsKey, value);
}

- (NSEdgeInsets)titleEdgeInsets {
    return LKGetAssociatedEdgeInsets(self, LKButtonTitleInsetsKey);
}

- (void)setImageEdgeInsets:(NSEdgeInsets)value {
    LKSetAssociatedEdgeInsets(self, LKButtonImageInsetsKey, value);
}

- (NSEdgeInsets)imageEdgeInsets {
    return LKGetAssociatedEdgeInsets(self, LKButtonImageInsetsKey);
}

@end

@implementation NSScrollView (LookinServer)

- (void)setContentOffset:(CGPoint)value {
    [self.contentView scrollToPoint:value];
    [self reflectScrolledClipView:self.contentView];
}

- (CGPoint)contentOffset {
    return self.contentView.bounds.origin;
}

- (void)setContentSize:(CGSize)value {
    if (self.documentView) {
        NSRect frame = self.documentView.frame;
        frame.size = value;
        self.documentView.frame = frame;
    }
}

- (CGSize)contentSize {
    return self.documentView ? self.documentView.frame.size : CGSizeZero;
}

- (void)setAdjustedContentInset:(NSEdgeInsets)value {
    self.contentInsets = value;
}

- (NSEdgeInsets)adjustedContentInset {
    return self.contentInsets;
}

- (void)setContentInsetAdjustmentBehavior:(NSInteger)value {
    LKSetAssociatedNumber(self, LKScrollAdjustmentBehaviorKey, value);
}

- (NSInteger)contentInsetAdjustmentBehavior {
    NSNumber *value = LKGetAssociatedNumber(self, LKScrollAdjustmentBehaviorKey);
    return value ? value.integerValue : 0;
}

- (void)setDelaysContentTouches:(BOOL)value {
    objc_setAssociatedObject(self, LKScrollDelaysTouchesKey, @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)delaysContentTouches {
    NSNumber *value = LKGetAssociatedNumber(self, LKScrollDelaysTouchesKey);
    return value ? value.boolValue : NO;
}

- (void)setCanCancelContentTouches:(BOOL)value {
    objc_setAssociatedObject(self, LKScrollCanCancelTouchesKey, @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)canCancelContentTouches {
    NSNumber *value = LKGetAssociatedNumber(self, LKScrollCanCancelTouchesKey);
    return value ? value.boolValue : YES;
}

- (void)setBouncesZoom:(BOOL)value {
    self.allowsMagnification = value;
}

- (BOOL)bouncesZoom {
    return self.allowsMagnification;
}

- (void)setZoomScale:(CGFloat)value {
    self.magnification = value;
}

- (CGFloat)zoomScale {
    return self.magnification;
}

@end

@implementation NSTableView (LookinServer)

- (void)setStyle:(NSInteger)value {
    LKSetAssociatedNumber(self, LKTableStyleKey, value);
}

- (NSInteger)style {
    NSNumber *value = LKGetAssociatedNumber(self, LKTableStyleKey);
    return value ? value.integerValue : 0;
}

- (void)setNumberOfSections:(NSInteger)value {
    LKSetAssociatedNumber(self, LKTableSectionsKey, value);
}

- (NSInteger)numberOfSections {
    NSNumber *value = LKGetAssociatedNumber(self, LKTableSectionsKey);
    if (value) {
        return value.integerValue;
    }
    return self.numberOfRows > 0 ? 1 : 0;
}

- (void)setSeparatorStyle:(NSInteger)value {
    LKSetAssociatedNumber(self, LKTableSeparatorStyleKey, value);
    self.gridStyleMask = value == 0 ? NSTableViewGridNone : NSTableViewSolidHorizontalGridLineMask;
}

- (NSInteger)separatorStyle {
    NSNumber *value = LKGetAssociatedNumber(self, LKTableSeparatorStyleKey);
    if (value) {
        return value.integerValue;
    }
    return self.gridStyleMask == NSTableViewGridNone ? 0 : 1;
}

- (void)setSeparatorColor:(NSColor *)value {
    objc_setAssociatedObject(self, LKTableSeparatorColorKey, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.gridColor = value;
}

- (NSColor *)separatorColor {
    NSColor *value = objc_getAssociatedObject(self, LKTableSeparatorColorKey);
    return value ?: self.gridColor;
}

- (void)setSeparatorInset:(NSEdgeInsets)value {
    LKSetAssociatedEdgeInsets(self, LKTableSeparatorInsetKey, value);
}

- (NSEdgeInsets)separatorInset {
    return LKGetAssociatedEdgeInsets(self, LKTableSeparatorInsetKey);
}

- (NSNumber *)lks_numberOfRows {
    return @(self.numberOfRows);
}

@end

@implementation NSStackView (LookinServer)

- (void)setAxis:(NSInteger)value {
    self.orientation = value;
}

- (NSInteger)axis {
    return self.orientation;
}

@end

@implementation NSVisualEffectView (LookinServer)

- (NSNumber *)lks_blurEffectStyleNumber {
    return @(self.material);
}

- (void)setLks_blurEffectStyleNumber:(NSNumber *)value {
    if (!value) {
        return;
    }
    self.material = value.integerValue;
}

@end

@implementation NSImageView (LookinServer)

- (NSString *)lks_imageSourceName {
    return self.image.name;
}

- (NSNumber *)lks_imageViewOidIfHasImage {
    if (!self.image) {
        return nil;
    }
    return @([self lks_registerOid]);
}

@end

@implementation NSTextField (LookinServer)

- (void)setText:(NSString *)value {
    self.stringValue = value ?: @"";
}

- (NSString *)text {
    return self.stringValue ?: @"";
}

- (void)setPlaceholder:(NSString *)value {
    self.placeholderString = value;
}

- (NSString *)placeholder {
    return self.placeholderString;
}

- (void)setNumberOfLines:(NSInteger)value {
    if ([self.cell respondsToSelector:@selector(setUsesSingleLineMode:)]) {
        [(id)self.cell setUsesSingleLineMode:(value == 1)];
    }
    if ([self.cell respondsToSelector:@selector(setWraps:)]) {
        [(id)self.cell setWraps:(value != 1)];
    }
    if ([self.cell respondsToSelector:@selector(setScrollable:)]) {
        [(id)self.cell setScrollable:NO];
    }
}

- (NSInteger)numberOfLines {
    if ([self.cell respondsToSelector:@selector(wraps)] && [(id)self.cell wraps]) {
        return 0;
    }
    return 1;
}

- (void)setLineBreakMode:(NSLineBreakMode)value {
    if ([self.cell respondsToSelector:@selector(setLineBreakMode:)]) {
        [(id)self.cell setLineBreakMode:value];
    }
}

- (NSLineBreakMode)lineBreakMode {
    if ([self.cell respondsToSelector:@selector(lineBreakMode)]) {
        return ((NSTextFieldCell *)self.cell).lineBreakMode;
    }
    return NSLineBreakByTruncatingTail;
}

- (void)setAdjustsFontSizeToFitWidth:(BOOL)value {
    if ([self.cell respondsToSelector:@selector(setAllowsDefaultTighteningForTruncation:)]) {
        [(id)self.cell setAllowsDefaultTighteningForTruncation:value];
    }
}

- (BOOL)adjustsFontSizeToFitWidth {
    if ([self.cell respondsToSelector:@selector(allowsDefaultTighteningForTruncation)]) {
        return [(id)self.cell allowsDefaultTighteningForTruncation];
    }
    return NO;
}

- (void)setClearsOnBeginEditing:(BOOL)value {
    objc_setAssociatedObject(self, LKTextClearsOnBeginEditingKey, @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)clearsOnBeginEditing {
    NSNumber *value = LKGetAssociatedNumber(self, LKTextClearsOnBeginEditingKey);
    return value.boolValue;
}

- (void)setClearButtonMode:(NSInteger)value {
    LKSetAssociatedNumber(self, LKTextClearButtonModeKey, value);
}

- (NSInteger)clearButtonMode {
    NSNumber *value = LKGetAssociatedNumber(self, LKTextClearButtonModeKey);
    return value ? value.integerValue : 0;
}

- (CGFloat)lks_fontSize {
    return self.font.pointSize;
}

- (void)setLks_fontSize:(CGFloat)value {
    self.font = [self.font fontWithSize:value];
}

- (NSString *)lks_fontName {
    return self.font.fontName;
}

@end

@implementation NSTextView (LookinServer)

- (void)setText:(NSString *)value {
    self.string = value ?: @"";
}

- (NSString *)text {
    return self.string ?: @"";
}

- (CGFloat)lks_fontSize {
    return self.font.pointSize;
}

- (void)setLks_fontSize:(CGFloat)value {
    self.font = [self.font fontWithSize:value];
}

- (NSString *)lks_fontName {
    return self.font.fontName;
}

@end

#endif

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
