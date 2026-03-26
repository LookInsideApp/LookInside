#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION || TARGET_OS_MAC)
//
//  NSObject+LookinServer.h
//  LookinServer
//
//  Created by Li Kai on 2019/4/21.
//  https://lookin.work
//

#import "LookinDefines.h"
#import <Foundation/Foundation.h>
#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

@class LookinIvarTrace;

@interface NSObject (LookinServer)

#pragma mark - oid

/// 如果 oid 不存在则会创建新的 oid
- (unsigned long)lks_registerOid;

/// 0 表示不存在
@property(nonatomic, assign) unsigned long lks_oid;

+ (NSObject *)lks_objectWithOid:(unsigned long)oid;

#pragma mark - trace

@property(nonatomic, copy) NSArray<LookinIvarTrace *> *lks_ivarTraces;

@property(nonatomic, copy) NSString *lks_specialTrace;

+ (void)lks_clearAllObjectsTraces;

/**
 获取当前对象的 Class 层级树，如 @[@"UIView", @"UIResponder", @"NSObject"]。未 demangle，有 Swift Module Name
 */
- (NSArray<NSString *> *)lks_classChainList;

@end

#if TARGET_OS_OSX

@interface NSView (LookinServer)

@property(nonatomic, assign) float lks_horizontalContentHuggingPriority;
@property(nonatomic, assign) float lks_verticalContentHuggingPriority;
@property(nonatomic, assign) float lks_horizontalContentCompressionResistancePriority;
@property(nonatomic, assign) float lks_verticalContentCompressionResistancePriority;
@property(nonatomic, strong) NSMutableArray<NSLayoutConstraint *> *lks_involvedRawConstraints;
@property(nonatomic, assign, getter=isUserInteractionEnabled) BOOL userInteractionEnabled;
@property(nonatomic, assign) NSInteger contentMode;
@property(nonatomic, strong) NSColor *tintColor;
@property(nonatomic, assign) NSInteger tintAdjustmentMode;
@property(nonatomic, assign) NSInteger tag;

+ (void)lks_rebuildGlobalInvolvedRawConstraints;
- (NSArray *)lks_constraints;

@end

@interface NSControl (LookinServer)

@property(nonatomic, assign, getter=isSelected) BOOL selected;
@property(nonatomic, assign) NSInteger contentVerticalAlignment;
@property(nonatomic, assign) NSInteger contentHorizontalAlignment;
@property(nonatomic, assign) NSEdgeInsets qmui_outsideEdge;

@end

@interface NSButton (LookinServer)

@property(nonatomic, assign) NSEdgeInsets contentEdgeInsets;
@property(nonatomic, assign) NSEdgeInsets titleEdgeInsets;
@property(nonatomic, assign) NSEdgeInsets imageEdgeInsets;

@end

@interface NSScrollView (LookinServer)

@property(nonatomic, assign) CGPoint contentOffset;
@property(nonatomic, assign) CGSize contentSize;
@property(nonatomic, assign) NSEdgeInsets adjustedContentInset;
@property(nonatomic, assign) NSInteger contentInsetAdjustmentBehavior;
@property(nonatomic, assign) BOOL delaysContentTouches;
@property(nonatomic, assign) BOOL canCancelContentTouches;
@property(nonatomic, assign) BOOL bouncesZoom;
@property(nonatomic, assign) CGFloat zoomScale;

@end

@interface NSTableView (LookinServer)

@property(nonatomic, assign) NSInteger style;
@property(nonatomic, assign) NSInteger numberOfSections;
@property(nonatomic, assign) NSInteger separatorStyle;
@property(nonatomic, strong) NSColor *separatorColor;
@property(nonatomic, assign) NSEdgeInsets separatorInset;
- (NSNumber *)lks_numberOfRows;

@end

@interface NSStackView (LookinServer)

@property(nonatomic, assign) NSInteger axis;

@end

@interface NSVisualEffectView (LookinServer)

- (NSNumber *)lks_blurEffectStyleNumber;
- (void)setLks_blurEffectStyleNumber:(NSNumber *)value;

@end

@interface NSImageView (LookinServer)

- (NSString *)lks_imageSourceName;
- (NSNumber *)lks_imageViewOidIfHasImage;

@end

@interface NSTextField (LookinServer)

@property(nonatomic, assign) CGFloat lks_fontSize;
@property(nonatomic, copy) NSString *text;
@property(nonatomic, copy) NSString *placeholder;
@property(nonatomic, assign) NSInteger numberOfLines;
@property(nonatomic, assign) NSLineBreakMode lineBreakMode;
@property(nonatomic, assign) BOOL adjustsFontSizeToFitWidth;
@property(nonatomic, assign) BOOL clearsOnBeginEditing;
@property(nonatomic, assign) NSInteger clearButtonMode;
- (NSString *)lks_fontName;

@end

@interface NSTextView (LookinServer)

@property(nonatomic, assign) CGFloat lks_fontSize;
@property(nonatomic, copy) NSString *text;
- (NSString *)lks_fontName;

@end

#endif

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
