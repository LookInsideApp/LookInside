#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION || TARGET_OS_MAC)
//
//  UIView+LookinMobile.m
//  WeRead
//
//  Created by Li Kai on 2018/11/30.
//  Copyright © 2018 tencent. All rights reserved.
//

#import "CALayer+LookinServer.h"
#import "NSArray+Lookin.h"
#import "LookinIvarTrace.h"
#import "NSObject+LookinServer.h"
#if !TARGET_OS_OSX
#import "UIColor+LookinServer.h"
#endif

@implementation CALayer (LookinServer)

#if TARGET_OS_OSX
static NSArray<NSView *> *LKHideVisibleSubviews(NSArray<NSView *> *subviews) {
    NSMutableArray<NSView *> *hiddenSubviews = [NSMutableArray array];
    for (NSView *subview in subviews.copy) {
        if (!subview.isHidden) {
            subview.hidden = YES;
            [hiddenSubviews addObject:subview];
        }
    }
    return hiddenSubviews.copy;
}
#endif

static NSArray<CALayer *> *LKHideVisibleNonHostSublayers(NSArray<CALayer *> *sublayers) {
    NSMutableArray<CALayer *> *hiddenSublayers = [NSMutableArray array];
    for (CALayer *sublayer in sublayers.copy) {
        if (sublayer.hidden || sublayer.lks_hostView) {
            continue;
        }
        sublayer.hidden = YES;
        [hiddenSublayers addObject:sublayer];
    }
    return hiddenSublayers.copy;
}

#if TARGET_OS_OSX
static void LKRestoreHiddenViews(NSArray<NSView *> *subviews) {
    for (NSView *subview in subviews) {
        subview.hidden = NO;
    }
}
#endif

static void LKRestoreHiddenLayers(NSArray<CALayer *> *sublayers) {
    for (CALayer *sublayer in sublayers) {
        sublayer.hidden = NO;
    }
}

+ (NSArray<NSString *> *)lks_getClassListOfObject:(id)object endingClass:(NSString *)endingClass {
    NSArray<NSString *> *completedList = [object lks_classChainList];
    NSUInteger endingIdx = [completedList indexOfObject:endingClass];
    if (endingIdx != NSNotFound) {
        completedList = [completedList subarrayWithRange:NSMakeRange(0, endingIdx + 1)];
    }
    return completedList;
}

#if TARGET_OS_OSX

- (NSWindow *)lks_window {
    CALayer *layer = self;
    while (layer) {
        NSView *hostView = layer.lks_hostView;
        if (hostView.window) {
            return hostView.window;
        }
        layer = layer.superlayer;
    }
    return nil;
}

- (CGRect)lks_frameInWindow:(NSWindow *)window {
    if (!window) {
        return CGRectZero;
    }
    NSView *hostView = self.lks_hostView;
    if (hostView) {
        NSRect rectInWindow = [hostView convertRect:hostView.bounds toView:nil];
        return [window convertRectToScreen:rectInWindow];
    }

    CALayer *ancestorLayer = self.superlayer;
    while (ancestorLayer && !ancestorLayer.lks_hostView) {
        ancestorLayer = ancestorLayer.superlayer;
    }
    if (ancestorLayer.lks_hostView && ancestorLayer.lks_hostView.layer) {
        NSView *ancestorHostView = ancestorLayer.lks_hostView;
        CGRect rectInHostView = [ancestorHostView.layer convertRect:self.frame fromLayer:self.superlayer];
        NSRect rectInWindow = [ancestorHostView convertRect:rectInHostView toView:nil];
        return [window convertRectToScreen:rectInWindow];
    }

    if (self.superlayer && window.contentView.layer) {
        CGRect rectInContent = [window.contentView.layer convertRect:self.frame fromLayer:self.superlayer];
        return [window convertRectToScreen:rectInContent];
    }
    return self.frame;
}

- (NSView *)lks_hostView {
    if (self.delegate && [self.delegate isKindOfClass:NSView.class]) {
        NSView *view = (NSView *)self.delegate;
        if (view.layer == self) {
            return view;
        }
    }
    return nil;
}

+ (NSImage *)_lks_renderImageForSize:(CGSize)size renderBlock:(void (^)(CGContextRef context))renderBlock {
    if (size.width <= 0 || size.height <= 0 || size.width > 20000 || size.height > 20000) {
        return nil;
    }

    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:NULL
                      pixelsWide:(NSInteger)ceil(size.width)
                      pixelsHigh:(NSInteger)ceil(size.height)
                   bitsPerSample:8
                 samplesPerPixel:4
                        hasAlpha:YES
                        isPlanar:NO
                  colorSpaceName:NSDeviceRGBColorSpace
                     bytesPerRow:0
                    bitsPerPixel:0];
    if (!bitmapRep) {
        return nil;
    }

    NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmapRep];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:graphicsContext];
    CGContextRef context = graphicsContext.CGContext;
    CGContextTranslateCTM(context, 0, size.height);
    CGContextScaleCTM(context, 1, -1);
    renderBlock(context);
    [graphicsContext flushGraphics];
    [NSGraphicsContext restoreGraphicsState];

    NSImage *image = [[NSImage alloc] initWithSize:size];
    [image addRepresentation:bitmapRep];
    return image;
}

- (NSImage *)lks_groupScreenshotWithLowQuality:(BOOL)lowQuality {
    NSView *hostView = self.lks_hostView;
    if (hostView) {
        NSRect bounds = hostView.bounds;
        if (bounds.size.width <= 0 || bounds.size.height <= 0) {
            return nil;
        }
        NSBitmapImageRep *bitmapRep = [hostView bitmapImageRepForCachingDisplayInRect:bounds];
        if (!bitmapRep) {
            return nil;
        }
        [hostView cacheDisplayInRect:bounds toBitmapImageRep:bitmapRep];
        NSImage *image = [[NSImage alloc] initWithSize:bounds.size];
        [image addRepresentation:bitmapRep];
        return image;
    }

    return [CALayer _lks_renderImageForSize:self.bounds.size renderBlock:^(CGContextRef context) {
        [self renderInContext:context];
    }];
}

- (NSImage *)lks_soloScreenshotWithLowQuality:(BOOL)lowQuality {
    NSView *hostView = self.lks_hostView;
    if (!hostView && !self.sublayers.count) {
        return nil;
    }

    NSArray<NSView *> *hiddenSubviews = @[];
    NSArray<CALayer *> *hiddenSublayers = @[];
    if (hostView) {
        hiddenSubviews = LKHideVisibleSubviews(hostView.subviews ?: @[]);
    }
    hiddenSublayers = LKHideVisibleNonHostSublayers(self.sublayers ?: @[]);

    NSImage *image = nil;
    @try {
        image = [self lks_groupScreenshotWithLowQuality:lowQuality];
    } @finally {
        LKRestoreHiddenViews(hiddenSubviews);
        LKRestoreHiddenLayers(hiddenSublayers);
    }
    return image;
}

- (NSArray<NSArray<NSString *> *> *)lks_relatedClassChainList {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:2];
    if (self.lks_hostView) {
        [array addObject:[CALayer lks_getClassListOfObject:self.lks_hostView endingClass:@"NSView"]];
    } else {
        [array addObject:[CALayer lks_getClassListOfObject:self endingClass:@"CALayer"]];
    }
    return array.copy;
}

- (NSArray<NSString *> *)lks_selfRelation {
    NSMutableArray<NSString *> *array = [NSMutableArray array];
    NSArray<LookinIvarTrace *> *ivarTraces = self.lks_hostView ? self.lks_hostView.lks_ivarTraces : self.lks_ivarTraces;
    if (self.lks_hostView.lks_specialTrace.length) {
        [array addObject:self.lks_hostView.lks_specialTrace];
    } else if (self.lks_specialTrace.length) {
        [array addObject:self.lks_specialTrace];
    }
    for (LookinIvarTrace *trace in ivarTraces) {
        [array addObject:[NSString stringWithFormat:@"(%@ *) -> %@", trace.hostClassName, trace.ivarName]];
    }
    return array.count ? array.copy : nil;
}

- (NSColor *)lks_backgroundColor {
    return self.backgroundColor ? [NSColor colorWithCGColor:self.backgroundColor] : nil;
}

- (void)setLks_backgroundColor:(NSColor *)lks_backgroundColor {
    self.backgroundColor = lks_backgroundColor.CGColor;
}

- (NSColor *)lks_borderColor {
    return self.borderColor ? [NSColor colorWithCGColor:self.borderColor] : nil;
}

- (void)setLks_borderColor:(NSColor *)lks_borderColor {
    self.borderColor = lks_borderColor.CGColor;
}

- (NSColor *)lks_shadowColor {
    return self.shadowColor ? [NSColor colorWithCGColor:self.shadowColor] : nil;
}

- (void)setLks_shadowColor:(NSColor *)lks_shadowColor {
    self.shadowColor = lks_shadowColor.CGColor;
}

#else

- (UIWindow *)lks_window {
    CALayer *layer = self;
    while (layer) {
        UIView *hostView = layer.lks_hostView;
        if (hostView.window) {
            return hostView.window;
        } else if ([hostView isKindOfClass:[UIWindow class]]) {
            return (UIWindow *)hostView;
        }
        layer = layer.superlayer;
    }
    return nil;
}

- (CGRect)lks_frameInWindow:(UIWindow *)window {
    UIWindow *selfWindow = [self lks_window];
    if (!selfWindow) {
        return CGRectZero;
    }
    
    CGRect rectInSelfWindow = [selfWindow.layer convertRect:self.frame fromLayer:self.superlayer];
    CGRect rectInWindow = [window convertRect:rectInSelfWindow fromWindow:selfWindow];
    return rectInWindow;
}

- (UIView *)lks_hostView {
    if (self.delegate && [self.delegate isKindOfClass:UIView.class]) {
        UIView *view = (UIView *)self.delegate;
        if (view.layer == self) {
            return view;
        }
    }
    return nil;
}

- (UIImage *)lks_groupScreenshotWithLowQuality:(BOOL)lowQuality {
    CGFloat renderScale = lowQuality ? 1 : 0;
    CGSize contextSize = self.frame.size;
    if (contextSize.width <= 0 || contextSize.height <= 0 || contextSize.width > 20000 || contextSize.height > 20000) {
        return nil;
    }
    UIGraphicsBeginImageContextWithOptions(contextSize, NO, renderScale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (self.lks_hostView) {
        [self.lks_hostView drawViewHierarchyInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) afterScreenUpdates:YES];
    } else {
        [self renderInContext:context];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)lks_soloScreenshotWithLowQuality:(BOOL)lowQuality {
    if (!self.sublayers.count) {
        return nil;
    }
    NSMutableArray<CALayer *> *visibleSublayers = [NSMutableArray array];
    [self.sublayers.copy enumerateObjectsUsingBlock:^(__kindof CALayer * _Nonnull sublayer, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!sublayer.hidden) {
            sublayer.hidden = YES;
            [visibleSublayers addObject:sublayer];
        }
    }];
    UIImage *image = [self lks_groupScreenshotWithLowQuality:lowQuality];
    [visibleSublayers enumerateObjectsUsingBlock:^(CALayer * _Nonnull sublayer, NSUInteger idx, BOOL * _Nonnull stop) {
        sublayer.hidden = NO;
    }];
    return image;
}

- (NSArray<NSArray<NSString *> *> *)lks_relatedClassChainList {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:2];
    if (self.lks_hostView) {
        [array addObject:[CALayer lks_getClassListOfObject:self.lks_hostView endingClass:@"UIView"]];
    } else {
        [array addObject:[CALayer lks_getClassListOfObject:self endingClass:@"CALayer"]];
    }
    return array.copy;
}

- (NSArray<NSString *> *)lks_selfRelation {
    NSMutableArray *array = [NSMutableArray array];
    NSMutableArray<LookinIvarTrace *> *ivarTraces = [NSMutableArray array];
    if (self.lks_hostView) {
        [ivarTraces addObjectsFromArray:self.lks_hostView.lks_ivarTraces];
    } else {
        [ivarTraces addObjectsFromArray:self.lks_ivarTraces];
    }
    if (ivarTraces.count) {
        [array addObjectsFromArray:[ivarTraces lookin_map:^id(NSUInteger idx, LookinIvarTrace *value) {
            return [NSString stringWithFormat:@"(%@ *) -> %@", value.hostClassName, value.ivarName];
        }]];
    }
    return array.count ? array.copy : nil;
}

- (UIColor *)lks_backgroundColor {
    return [UIColor lks_colorWithCGColor:self.backgroundColor];
}

- (void)setLks_backgroundColor:(UIColor *)lks_backgroundColor {
    self.backgroundColor = lks_backgroundColor.CGColor;
}

- (UIColor *)lks_borderColor {
    return [UIColor lks_colorWithCGColor:self.borderColor];
}

- (void)setLks_borderColor:(UIColor *)lks_borderColor {
    self.borderColor = lks_borderColor.CGColor;
}

- (UIColor *)lks_shadowColor {
    return [UIColor lks_colorWithCGColor:self.shadowColor];
}

- (void)setLks_shadowColor:(UIColor *)lks_shadowColor {
    self.shadowColor = lks_shadowColor.CGColor;
}

#endif

- (CGFloat)lks_shadowOffsetWidth {
    return self.shadowOffset.width;
}

- (void)setLks_shadowOffsetWidth:(CGFloat)lks_shadowOffsetWidth {
    self.shadowOffset = CGSizeMake(lks_shadowOffsetWidth, self.shadowOffset.height);
}

- (CGFloat)lks_shadowOffsetHeight {
    return self.shadowOffset.height;
}

- (void)setLks_shadowOffsetHeight:(CGFloat)lks_shadowOffsetHeight {
    self.shadowOffset = CGSizeMake(self.shadowOffset.width, lks_shadowOffsetHeight);
}

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
