#if defined(SHOULD_COMPILE_LOOKIN_SERVER)
//
//  UIView+LookinMobile.h
//  WeRead
//
//  Created by Li Kai on 2018/11/30.
//  Copyright © 2018 tencent. All rights reserved.
//

#import "LookinDefines.h"

@interface CALayer (LookinServer)

/// 如果 myView.layer == myLayer，则 myLayer.lks_hostView 会返回 myView
@property(nonatomic, readonly, weak) LookinView *lks_hostView;

/// Returns YES when this layer is a _UIMultiLayer wrapping a UIView.
/// Detection: delegate is a UIView that responds to _outermostLayer, and
/// [delegate _outermostLayer] == self && [delegate layer] != self.
/// Always returns NO on iOS < 26 (no _outermostLayer selector).
@property(nonatomic, readonly) BOOL lks_isMultiLayerContainer;

/// When lks_isMultiLayerContainer is YES, returns the inner backing layer
/// (i.e. [hostView layer]). Returns nil otherwise.
@property(nonatomic, readonly) CALayer *lks_multiLayerInnerLayer;

- (LookinWindow *)lks_window;

- (CGRect)lks_frameInWindow:(LookinWindow *)window;

- (LookinImage *)lks_groupScreenshotWithLowQuality:(BOOL)lowQuality;
/// 当没有 sublayers 时，该方法返回 nil
- (LookinImage *)lks_soloScreenshotWithLowQuality:(BOOL)lowQuality;

/// 获取和该对象有关的对象的 Class 层级树
- (NSArray<NSArray<NSString *> *> *)lks_relatedClassChainList;

- (NSArray<NSString *> *)lks_selfRelation;

@property(nonatomic, strong) LookinColor *lks_backgroundColor;
@property(nonatomic, strong) LookinColor *lks_borderColor;
@property(nonatomic, strong) LookinColor *lks_shadowColor;
@property(nonatomic, assign) CGFloat lks_shadowOffsetWidth;
@property(nonatomic, assign) CGFloat lks_shadowOffsetHeight;

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
