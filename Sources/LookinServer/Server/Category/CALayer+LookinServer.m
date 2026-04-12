#if defined(SHOULD_COMPILE_LOOKIN_SERVER)
//
//  UIView+LookinMobile.m
//  WeRead
//
//  Created by Li Kai on 2018/11/30.
//  Copyright © 2018 tencent. All rights reserved.
//

#import "CALayer+LookinServer.h"
#import "UIView+LookinServer.h"
#import "LKS_HierarchyDisplayItemsMaker.h"
#import "LookinDisplayItem.h"
#import <objc/runtime.h>
#import "LKS_ConnectionManager.h"
#import "LookinIvarTrace.h"
#import "LookinServerDefines.h"
#import "UIColor+LookinServer.h"
#import "LKS_MultiplatformAdapter.h"
#import "NSWindow+LookinServer.h"

#if TARGET_OS_IPHONE

#pragma mark - MultiLayer Debug Logging

static NSString *LKSMLDescribeRect(CGRect rect) {
    return [NSString stringWithFormat:@"(%.1f,%.1f,%.1f,%.1f)",
            rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
}

static NSString *LKSMLDescribeSize(CGSize size) {
    return [NSString stringWithFormat:@"(%.1fx%.1f)", size.width, size.height];
}

static NSString *LKSMLDescribeView(UIView *view) {
    if (!view) {
        return @"<nil>";
    }
    return [NSString stringWithFormat:@"<%@:%p frame=%@ bounds.origin=(%.1f,%.1f) alpha=%.2f hidden=%d clips=%d>",
            NSStringFromClass(view.class), (void *)view,
            LKSMLDescribeRect(view.frame),
            view.bounds.origin.x, view.bounds.origin.y,
            view.alpha, view.hidden, view.clipsToBounds];
}

static NSString *LKSMLDescribeLayer(CALayer *layer) {
    if (!layer) {
        return @"<nil>";
    }
    return [NSString stringWithFormat:@"<%@:%p bounds=%@>",
            NSStringFromClass(layer.class), (void *)layer,
            LKSMLDescribeRect(layer.bounds)];
}

#define LKSMLLog(fmt, ...) NSLog(@"[LKS-MultiLayer] " fmt, ##__VA_ARGS__)

#pragma mark - MultiLayer Snapshot Mode (debug switch)

/// Snapshot rendering strategy for views living inside a MultiLayer
/// `_UIVisualEffectContentView` subtree. Selected at runtime from an env var
/// or NSUserDefaults key so we can A/B different implementations without
/// rebuilding. See `LKSMultiLayerSnapshotModeValue` for the keys.
typedef NS_ENUM(NSInteger, LKSMultiLayerSnapshotMode) {
    /// Current baseline: `UIScrollView` subclasses use a simple window crop,
    /// everything else falls back to `renderInContext:`.
    LKSMultiLayerSnapshotModeDefault = 0,
    /// B — Xcode-style window crop. Render the whole window via
    /// `drawViewHierarchyInRect:` and crop to the target view, honoring
    /// `clipsToBounds` on ancestors and temporarily clearing the alpha of
    /// views that overlap the target (later siblings on the ancestor chain).
    LKSMultiLayerSnapshotModeWindowCropXcode,
    /// C — Render from the nearest non-MultiLayer ancestor via
    /// `drawViewHierarchyInRect:` and crop. Cheaper than window crop when
    /// the ancestor is local, relies on the ancestor's subtree having no
    /// overlapping siblings.
    LKSMultiLayerSnapshotModeNearestAncestorCrop,
};

static LKSMultiLayerSnapshotMode LKSMultiLayerSnapshotModeValue(void) {
    static LKSMultiLayerSnapshotMode mode;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mode = LKSMultiLayerSnapshotModeWindowCropXcode;
//        NSString *envValue = NSProcessInfo.processInfo.environment[@"LOOKIN_MULTILAYER_SNAPSHOT_MODE"];
//        NSString *defaultsValue = [NSUserDefaults.standardUserDefaults stringForKey:@"LookinServerMultiLayerSnapshotMode"];
//        NSString *rawValue = envValue.length > 0 ? envValue : defaultsValue;
//        NSString *value = [[rawValue lowercaseString] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
//        if ([value isEqualToString:@"b"]
//            || [value isEqualToString:@"windowcrop"]
//            || [value isEqualToString:@"xcode"]) {
//            mode = LKSMultiLayerSnapshotModeWindowCropXcode;
//        } else if ([value isEqualToString:@"c"]
//                   || [value isEqualToString:@"nearest"]
//                   || [value isEqualToString:@"nearestancestor"]) {
//            mode = LKSMultiLayerSnapshotModeNearestAncestorCrop;
//        }
        NSString *name = (mode == LKSMultiLayerSnapshotModeWindowCropXcode) ? @"windowCropXcode(B)"
                       : (mode == LKSMultiLayerSnapshotModeNearestAncestorCrop) ? @"nearestAncestorCrop(C)"
                       : @"default";
        NSLog(@"LookinServer MultiLayer snapshot mode = %@", name);
    });
    return mode;
}

#pragma mark - MultiLayer Detection

static BOOL LKSMultiLayerHostViewIsTextLeaf(UIView *hostView) {
    if (!hostView) {
        return NO;
    }

    if ([hostView isKindOfClass:UILabel.class]) {
        return YES;
    }

    NSString *hostViewClassName = NSStringFromClass(hostView.class);
    return [hostViewClassName rangeOfString:@"Label" options:NSCaseInsensitiveSearch].location != NSNotFound;
}

static BOOL LKSMultiLayerHostViewCanUseDrawHierarchy(UIView *hostView) {
    if (!hostView || hostView.lks_isChildrenViewOfTabBar) {
        return NO;
    }

    if (@available(iOS 13.0, *)) {
        UIWindowScene *scene = hostView.window.windowScene;
        if (scene &&
            scene.activationState != UISceneActivationStateForegroundActive &&
            scene.activationState != UISceneActivationStateForegroundInactive) {
            return NO;
        }
    }

    return YES;
}

/// Returns YES when `view` itself is wrapped by a `_UIMultiLayer` (i.e.
/// `view._outermostLayer != view.layer`).
static BOOL LKSMultiLayerViewIsMultiLayerWrapped(UIView *view) {
    if (!view || ![view respondsToSelector:@selector(_outermostLayer)]) {
        return NO;
    }
    CALayer *outer = [view performSelector:@selector(_outermostLayer)];
    return outer != view.layer;
}

/// Whitelist: only treat `view` as an "effect subtree root" when it is a
/// genuine visual-effect producer. iOS 26 also wraps plain container views
/// like `UIDropShadowView` in `_UIMultiLayer` (for the system shadow pass),
/// but their subtrees render fine via `drawViewHierarchyInRect:` — treating
/// them as effect subtrees would funnel every full-screen container in the
/// app through the window-crop path and snapshot them as the entire window.
///
/// Matching uses `containsString:` rather than `hasPrefix:` so it is robust
/// against Swift module-qualified names (e.g. `UIKit._GlassGroupView`) and
/// mangled class names (`_TtC5UIKit..._GlassGroupLayerView`).
static BOOL LKSMultiLayerWrappedViewIsEffectContainer(UIView *view) {
    if (!view) {
        return NO;
    }
    if ([view isKindOfClass:UIVisualEffectView.class]) {
        return YES;
    }

    NSString *className = NSStringFromClass(view.class);

    // iOS 26 liquid-glass private classes that are not UIVisualEffectView
    // subclasses but still embed custom effect layers we cannot capture via
    // drawViewHierarchyInRect: on the host itself.
    if ([className containsString:@"_UILiquidLens"]
        || [className containsString:@"_UILiquidGlass"]
        || [className containsString:@"_GlassGroup"]) {
        return YES;
    }

    // System bar container wrappers. iOS 26 wraps `_UITabBarContainerWrapperView`
    // (and the navigation/toolbar equivalents) in `_UIMultiLayer` to composite
    // the `_UILiquidLensView` instances embedded inside their subtrees.
    // Whitelisting the wrapper routes the entire bar through the window-crop
    // path — the only reliable way to capture the lens layers (both
    // `renderInContext:` and `drawViewHierarchyInRect:` on the bar itself come
    // up blank).
    if ([className containsString:@"_UITabBar"]
        || [className containsString:@"_UINavigationBar"]
        || [className containsString:@"_UIToolbar"]) {
        return YES;
    }

    return NO;
}

/// Returns YES when an ancestor of `hostView` is both MultiLayer-wrapped and
/// a genuine effect container (see `LKSMultiLayerWrappedViewIsEffectContainer`).
/// Such ancestors' `drawViewHierarchyInRect:` pass returns blank images on
/// iOS 26, so callers take one of the window-crop helpers instead.
static BOOL LKSMultiLayerHostViewIsInsideMultiLayerSubtree(UIView *hostView) {
    for (UIView *current = hostView.superview; current; current = current.superview) {
        if (LKSMultiLayerViewIsMultiLayerWrapped(current)
            && LKSMultiLayerWrappedViewIsEffectContainer(current)) {
            LKSMLLog(@"InsideMultiLayerSubtree YES host=%@ effectAncestor=%@",
                     LKSMLDescribeView(hostView), LKSMLDescribeView(current));
            return YES;
        }
    }
    return NO;
}

static BOOL LKSMultiLayerShouldRenderGroupWithLayerTree(CALayer *layer, UIView *hostView) {
    if (!hostView || hostView.layer != layer) {
        return NO;
    }
    return LKSMultiLayerHostViewIsInsideMultiLayerSubtree(hostView);
}

/// UIScrollView subclasses inside a MultiLayer subtree need a different
/// path: `renderInContext:` produces blank output (scroll view sublayers
/// live in content coords offset by contentOffset that the recursive CA
/// renderer does not map back to the captured context), and
/// `drawViewHierarchyInRect:` on the scroll view itself is also blank
/// because it is nested inside the MultiLayer. The only reliable path is
/// to render the full window snapshot and crop to the scroll view rect.
static BOOL LKSMultiLayerShouldUseWindowCropForScrollView(UIView *hostView) {
    if (!hostView || ![hostView isKindOfClass:UIScrollView.class]) {
        return NO;
    }
    return LKSMultiLayerHostViewIsInsideMultiLayerSubtree(hostView);
}

/// Walks up the superview chain to find the nearest ancestor whose layer is
/// NOT MultiLayer-wrapped. The result is a safe root to call
/// `drawViewHierarchyInRect:` on, because it lives outside the MultiLayer
/// tree that would otherwise produce blank output. Returns nil if every
/// ancestor is wrapped (unusual — window cannot be wrapped).
static UIView *LKSMultiLayerNearestNonMultiLayerAncestor(UIView *hostView) {
    for (UIView *current = hostView.superview; current; current = current.superview) {
        if (!LKSMultiLayerViewIsMultiLayerWrapped(current)) {
            return current;
        }
    }
    return nil;
}

#pragma mark - MultiLayer Snapshot Render Helpers

/// Default mode helper: window-level draw with a single offset, no sibling
/// alpha handling. Works for isolated scroll views in an effect subtree but
/// may leak sibling content through overlap.
static BOOL LKSDrawHostViewUsingWindowCrop(UIView *hostView) {
    UIWindow *window = hostView.window;
    if (!window) {
        LKSMLLog(@"WindowCrop ABORT window=nil host=%@", LKSMLDescribeView(hostView));
        return NO;
    }
    CGRect rectInWindow = [hostView convertRect:hostView.bounds toView:window];
    if (rectInWindow.size.width <= 0 || rectInWindow.size.height <= 0) {
        LKSMLLog(@"WindowCrop ABORT empty rectInWindow=%@ host=%@",
                 LKSMLDescribeRect(rectInWindow), LKSMLDescribeView(hostView));
        return NO;
    }
    LKSMLLog(@"WindowCrop host=%@ rectInWindow=%@ windowBounds=%@",
             LKSMLDescribeView(hostView),
             LKSMLDescribeRect(rectInWindow),
             LKSMLDescribeRect(window.bounds));
    [window drawViewHierarchyInRect:CGRectMake(-rectInWindow.origin.x,
                                               -rectInWindow.origin.y,
                                               window.bounds.size.width,
                                               window.bounds.size.height)
                 afterScreenUpdates:YES];
    return YES;
}

/// Mode B helper: faithful port of
/// `-[DBGViewDebuggerSupport_iOS _renderEffectViewUsingDrawHierarchyInRect:]`
/// for the "self + children" case (we skip Xcode's subview-alpha clearing
/// because Lookin wants the children in the snapshot). Climbs the superview
/// chain to:
///   1. Zero out siblings above (after) the current view on each level.
///   2. Intersect the crop rect with every `clipsToBounds` ancestor.
/// Then draws the window once. When the final clip rect differs from the
/// full view bounds we run a second pass into a temporary image context and
/// `drawInRect:` it back into the caller context at the clip's offset
/// relative to `rectInWindow` — not the host view's local coord — so scroll
/// views whose `bounds.origin != 0` (e.g. `_UIQueuingScrollView` with page
/// spacing) still land their content inside the caller context.
static BOOL LKSDrawHostViewUsingXcodeWindowCrop(UIView *hostView, CGSize contextSize, CGFloat renderScale) {
    UIWindow *window = hostView.window;
    if (!window) {
        LKSMLLog(@"XcodeCrop ABORT window=nil host=%@", LKSMLDescribeView(hostView));
        return NO;
    }
    CGRect rectInWindow = [window convertRect:hostView.bounds fromView:hostView];
    if (CGRectIsEmpty(rectInWindow) || CGRectIsNull(rectInWindow)) {
        LKSMLLog(@"XcodeCrop ABORT empty rectInWindow=%@ host=%@",
                 LKSMLDescribeRect(rectInWindow), LKSMLDescribeView(hostView));
        return NO;
    }
    LKSMLLog(@"XcodeCrop ENTER host=%@ rectInWindow=%@ contextSize=%@ scale=%.2f",
             LKSMLDescribeView(hostView),
             LKSMLDescribeRect(rectInWindow),
             LKSMLDescribeSize(contextSize),
             renderScale);

    NSMutableArray<NSValue *> *alphaViewRefs = [NSMutableArray array];
    NSMutableArray<NSNumber *> *savedAlphas = [NSMutableArray array];
    CGRect clippedRect = rectInWindow;

    @try {
        UIView *current = hostView;
        NSUInteger level = 0;
        while (current != window) {
            UIView *parent = current.superview;
            if (!parent) {
                LKSMLLog(@"XcodeCrop walk level=%lu current=%@ parent=nil (broken chain)",
                         (unsigned long)level, LKSMLDescribeView(current));
                break;
            }
            NSUInteger clearedCount = 0;
            NSUInteger currentIdx = [parent.subviews indexOfObject:current];
            if (currentIdx != NSNotFound) {
                for (NSUInteger i = currentIdx + 1; i < parent.subviews.count; i++) {
                    UIView *sibling = parent.subviews[i];
                    [alphaViewRefs addObject:[NSValue valueWithNonretainedObject:sibling]];
                    [savedAlphas addObject:@(sibling.alpha)];
                    sibling.alpha = 0.0;
                    clearedCount++;
                }
            }
            CGRect beforeClip = clippedRect;
            if (parent.clipsToBounds) {
                CGRect parentRectInWindow = [window convertRect:parent.bounds fromView:parent];
                clippedRect = CGRectIntersection(clippedRect, parentRectInWindow);
                LKSMLLog(@"XcodeCrop walk level=%lu parent=%@ clearedSiblings=%lu clipsToBounds=YES parentRectInWindow=%@ before=%@ after=%@",
                         (unsigned long)level, LKSMLDescribeView(parent),
                         (unsigned long)clearedCount,
                         LKSMLDescribeRect(parentRectInWindow),
                         LKSMLDescribeRect(beforeClip),
                         LKSMLDescribeRect(clippedRect));
            } else {
                LKSMLLog(@"XcodeCrop walk level=%lu parent=%@ clearedSiblings=%lu clipsToBounds=NO",
                         (unsigned long)level, LKSMLDescribeView(parent),
                         (unsigned long)clearedCount);
            }
            current = parent;
            level++;
        }

        if (CGRectIsEmpty(clippedRect) || CGRectIsNull(clippedRect)) {
            LKSMLLog(@"XcodeCrop ABORT empty clippedRect=%@ after walk", LKSMLDescribeRect(clippedRect));
            return NO;
        }

        if (CGSizeEqualToSize(clippedRect.size, contextSize)) {
            // No clipping took effect — draw straight into the caller context.
            LKSMLLog(@"XcodeCrop branch=sameSize clippedRect=%@", LKSMLDescribeRect(clippedRect));
            [window drawViewHierarchyInRect:CGRectMake(-clippedRect.origin.x,
                                                       -clippedRect.origin.y,
                                                       window.bounds.size.width,
                                                       window.bounds.size.height)
                         afterScreenUpdates:YES];
        } else {
            // Clipping shrank the rect. Render into a temporary context sized
            // to the clip, then place that image back into the caller context
            // at the clip's offset within the host view's viewport. Using the
            // window-space delta avoids going through `[hostView convertRect:]`
            // which would bake in `bounds.origin` (contentOffset for scroll
            // views) and push the image outside the caller context.
            CGRect drawRect = CGRectMake(clippedRect.origin.x - rectInWindow.origin.x,
                                         clippedRect.origin.y - rectInWindow.origin.y,
                                         clippedRect.size.width,
                                         clippedRect.size.height);
            LKSMLLog(@"XcodeCrop branch=twoPass clippedRect=%@ drawRect=%@",
                     LKSMLDescribeRect(clippedRect),
                     LKSMLDescribeRect(drawRect));
            UIGraphicsBeginImageContextWithOptions(clippedRect.size, NO, renderScale);
            [window drawViewHierarchyInRect:CGRectMake(-clippedRect.origin.x,
                                                       -clippedRect.origin.y,
                                                       window.bounds.size.width,
                                                       window.bounds.size.height)
                         afterScreenUpdates:YES];
            UIImage *clippedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            [clippedImage drawInRect:drawRect];
        }
        LKSMLLog(@"XcodeCrop DONE host=%@ restoringAlphas=%lu",
                 LKSMLDescribeView(hostView), (unsigned long)alphaViewRefs.count);
        return YES;
    } @finally {
        for (NSUInteger i = 0; i < alphaViewRefs.count; i++) {
            UIView *view = [alphaViewRefs[i] nonretainedObjectValue];
            view.alpha = savedAlphas[i].floatValue;
        }
    }
}

/// Mode C helper: draw from the nearest non-MultiLayer ancestor and crop.
/// Cheaper than Xcode's window crop when the ancestor is local. Assumes the
/// ancestor's own subtree does not produce overlapping siblings that need
/// alpha zeroing.
static BOOL LKSDrawHostViewUsingNearestAncestorCrop(UIView *hostView) {
    UIView *root = LKSMultiLayerNearestNonMultiLayerAncestor(hostView);
    if (!root) {
        LKSMLLog(@"NearestAncestorCrop ABORT root=nil host=%@", LKSMLDescribeView(hostView));
        return NO;
    }
    CGRect rectInRoot = [root convertRect:hostView.bounds fromView:hostView];
    if (CGRectIsEmpty(rectInRoot) || CGRectIsNull(rectInRoot)) {
        LKSMLLog(@"NearestAncestorCrop ABORT empty rectInRoot=%@ host=%@ root=%@",
                 LKSMLDescribeRect(rectInRoot), LKSMLDescribeView(hostView), LKSMLDescribeView(root));
        return NO;
    }
    LKSMLLog(@"NearestAncestorCrop host=%@ root=%@ rectInRoot=%@",
             LKSMLDescribeView(hostView),
             LKSMLDescribeView(root),
             LKSMLDescribeRect(rectInRoot));
    [root drawViewHierarchyInRect:CGRectMake(-rectInRoot.origin.x,
                                             -rectInRoot.origin.y,
                                             root.bounds.size.width,
                                             root.bounds.size.height)
               afterScreenUpdates:YES];
    return YES;
}

/// Dispatch to the configured helper. Returns YES if the helper successfully
/// drew into the current UIGraphicsContext. Caller must fall back to
/// `renderInContext:` when NO is returned.
static BOOL LKSDrawHostViewForMultiLayerEffectSubtree(UIView *hostView, CGSize contextSize, CGFloat renderScale) {
    LKSMultiLayerSnapshotMode mode = LKSMultiLayerSnapshotModeValue();
    LKSMLLog(@"Dispatcher ENTER mode=%ld host=%@", (long)mode, LKSMLDescribeView(hostView));
    BOOL result = NO;
    switch (mode) {
        case LKSMultiLayerSnapshotModeWindowCropXcode:
            result = LKSDrawHostViewUsingXcodeWindowCrop(hostView, contextSize, renderScale);
            break;
        case LKSMultiLayerSnapshotModeNearestAncestorCrop:
            result = LKSDrawHostViewUsingNearestAncestorCrop(hostView);
            break;
        case LKSMultiLayerSnapshotModeDefault:
        default:
            if (LKSMultiLayerShouldUseWindowCropForScrollView(hostView)) {
                result = LKSDrawHostViewUsingWindowCrop(hostView);
            }
            break;
    }
    LKSMLLog(@"Dispatcher EXIT result=%d host=%@", result, LKSMLDescribeView(hostView));
    return result;
}

static BOOL LKSMultiLayerShouldRenderTextWithViewHierarchy(CALayer *layer, UIView *hostView) {
    if (!layer.lks_isMultiLayerContainer || !LKSMultiLayerHostViewIsTextLeaf(hostView)) {
        return NO;
    }

    return LKSMultiLayerHostViewCanUseDrawHierarchy(hostView);
}

static BOOL LKSMultiLayerShouldExposeTextInnerSublayers(CALayer *layer, UIView *hostView) {
    if (!layer.lks_isMultiLayerContainer || !LKSMultiLayerHostViewIsTextLeaf(hostView)) {
        return NO;
    }

    CALayer *innerLayer = layer.lks_multiLayerInnerLayer;
    return innerLayer.sublayers.count > 0;
}
#endif

@implementation CALayer (LookinServer)

- (LookinWindow *)lks_window {
    CALayer *layer = self;
    while (layer) {
        LookinView *hostView = layer.lks_hostView;
        if (hostView.window) {
            return hostView.window;
#if !TARGET_OS_OSX
        } else if ([hostView isKindOfClass:[LookinWindow class]]) {
            return (LookinWindow *)hostView;
#endif
        }
        layer = layer.superlayer;
    }
    return nil;
}

- (CGRect)lks_frameInWindow:(LookinWindow *)window {
    LookinWindow *selfWindow = [self lks_window];
    if (!selfWindow) {
        return CGRectZero;
    }

#if TARGET_OS_IPHONE
    CGRect rectInSelfWindow = [selfWindow.layer convertRect:self.frame fromLayer:self.superlayer];
    CGRect rectInWindow = [window convertRect:rectInSelfWindow fromWindow:selfWindow];
#elif TARGET_OS_OSX
    CGRect rectInSelfWindow = [selfWindow.lks_rootView.layer convertRect:self.frame fromLayer:self.superlayer];
    CGRect rectInWindow = [window.lks_rootView convertRect:rectInSelfWindow fromView:selfWindow.lks_rootView];
#endif
    return rectInWindow;
    }

#pragma mark - Host View

- (LookinView *)lks_hostView {
    if (self.delegate && [self.delegate isKindOfClass:LookinView.class]) {
        LookinView *view = (LookinView *)self.delegate;
        if (view.layer == self) {
            return view;
        }
#if TARGET_OS_IPHONE
        // MultiLayer: _outermostLayer is the view's outermost rendering layer,
        // but view.layer points to the inner backing layer.
        if ([view respondsToSelector:@selector(_outermostLayer)]
            && [view performSelector:@selector(_outermostLayer)] == self) {
            return view;
        }
#endif
    }
    return nil;
}

#pragma mark - MultiLayer Detection

- (BOOL)lks_isMultiLayerContainer {
#if TARGET_OS_IPHONE
    if (!self.delegate || ![self.delegate isKindOfClass:UIView.class]) {
        return NO;
    }
    UIView *view = (UIView *)self.delegate;
    if (![view respondsToSelector:@selector(_outermostLayer)]) {
        return NO;
    }
    CALayer *outermostLayer = [view performSelector:@selector(_outermostLayer)];
    return (outermostLayer == self && view.layer != self);
#else
    return NO;
#endif
}

- (CALayer *)lks_multiLayerInnerLayer {
#if TARGET_OS_IPHONE
    if (!self.lks_isMultiLayerContainer) {
        return nil;
    }
    UIView *view = (UIView *)self.delegate;
    return view.layer;
#else
    return nil;
#endif
}


#pragma mark - Screenshot

#if TARGET_OS_OSX
+ (NSImage *)_lks_renderImageForSize:(CGSize)size contentsAreFlipped:(BOOL)contentsAreFlipped renderBlock:(void (^)(CGContextRef context))renderBlock {
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
    // 与 Xcode View Debugger 行为一致：仅在 contentsAreFlipped 为 YES 时翻转
    if (contentsAreFlipped) {
    CGContextTranslateCTM(context, 0, size.height);
    CGContextScaleCTM(context, 1, -1);
    }
    renderBlock(context);
    [graphicsContext flushGraphics];
    [NSGraphicsContext restoreGraphicsState];

    NSImage *image = [[NSImage alloc] initWithSize:size];
    [image addRepresentation:bitmapRep];
    return image;
}
#endif

- (LookinImage *)lks_groupScreenshotWithLowQuality:(BOOL)lowQuality {

    CGSize renderSize;
#if TARGET_OS_IPHONE
    if (self.lks_isMultiLayerContainer) {
        // Only _UIMultiLayer containers use bounds.size — they inherit the
        // original transform, making frame.size unreliable.
        renderSize = self.bounds.size;
    } else {
        renderSize = self.frame.size;
    }
#else
    renderSize = self.frame.size;
#endif

    CGFloat screenScale = [LKS_MultiplatformAdapter mainScreenScale];
    CGFloat pixelWidth = renderSize.width * screenScale;
    CGFloat pixelHeight = renderSize.height * screenScale;
    if (pixelWidth <= 0 || pixelHeight <= 0) {
        return nil;
    }

    CGFloat renderScale = lowQuality ? 1 : 0;
    CGFloat maxLength = MAX(pixelWidth, pixelHeight);
    if (maxLength > LookinNodeImageMaxLengthInPx) {
        // 确保最终绘制出的图片长和宽都不能超过 LookinNodeImageMaxLengthInPx
        // 如果算出的 renderScale 大于 1 则取 1，因为似乎用 1 渲染的速度要比一个别的奇怪的带小数点的数字要更快
        renderScale = MIN(screenScale * LookinNodeImageMaxLengthInPx / maxLength, 1);
}

    CGSize contextSize = renderSize;
    if (contextSize.width <= 0 || contextSize.height <= 0 || contextSize.width > 20000 || contextSize.height > 20000) {
        NSLog(@"LookinServer - Failed to capture screenshot. Invalid context size: %@ x %@", @(contextSize.width), @(contextSize.height));
    return nil;
}
#if TARGET_OS_IPHONE
    // Only _UIMultiLayer containers themselves use renderInContext: to capture
    // the full multi-layer stack (inner layer + effect layers). Child views
    // inside the structure must still use drawViewHierarchyInRect: because
    // they may rely on visual effects (vibrancy, blur) that renderInContext:
    // cannot capture — e.g. _UIVisualEffectContentView children with adapted
    // text colors would appear invisible without the blur backdrop.
    if (self.lks_isMultiLayerContainer) {
        LookinView *hostView = self.lks_hostView;
        BOOL useViewHierarchyForText = LKSMultiLayerShouldRenderTextWithViewHierarchy(self, hostView);
        LKSMLLog(@"group ENTER container layer=%@ host=%@ contextSize=%@ renderScale=%.2f useViewHierarchyForText=%d",
                 LKSMLDescribeLayer(self),
                 LKSMLDescribeView(hostView),
                 LKSMLDescribeSize(contextSize),
                 renderScale,
                 useViewHierarchyForText);
        UIGraphicsBeginImageContextWithOptions(contextSize, NO, renderScale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (useViewHierarchyForText) {
            LKSMLLog(@"group container path=drawViewHierarchy host=%@", LKSMLDescribeView(hostView));
            [hostView drawViewHierarchyInRect:CGRectMake(0, 0, renderSize.width, renderSize.height) afterScreenUpdates:YES];
        } else if (LKSDrawHostViewForMultiLayerEffectSubtree(hostView, contextSize, renderScale)) {
            // Configured snapshot helper already drew into the current context.
            LKSMLLog(@"group container path=dispatcherDrew host=%@", LKSMLDescribeView(hostView));
        } else {
            LKSMLLog(@"group container path=renderInContext layer=%@", LKSMLDescribeLayer(self));
            [self renderInContext:context];
        }
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        LKSMLLog(@"group EXIT container layer=%@ image=%@",
                 LKSMLDescribeLayer(self),
                 image ? LKSMLDescribeSize(image.size) : @"<nil>");
        return image;
    }

    UIGraphicsBeginImageContextWithOptions(contextSize, NO, renderScale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    // drawViewHierarchyInRect: 从屏幕合成结果渲染，对后台 UIWindowScene 中的 view 会产生错误截图。
    // 当 hostView 所属的 scene 不在前台时，改用 renderInContext:（直接从 layer model tree 渲染）。
    // 对 MultiLayer _UIVisualEffectContentView 子树内的 view，drawViewHierarchyInRect: 会返回空白，
    // 此时走 `LKSDrawHostViewForMultiLayerEffectSubtree` 按当前 snapshot mode 选择不同 crop 策略。
    LookinView *hostView = self.lks_hostView;
    BOOL inMultiLayerEffectSubtree = LKSMultiLayerShouldRenderGroupWithLayerTree(self, hostView);
    BOOL canUseDrawHierarchy = LKSMultiLayerHostViewCanUseDrawHierarchy(hostView);
    LKSMLLog(@"group ENTER layer=%@ host=%@ contextSize=%@ renderScale=%.2f inSubtree=%d canDrawHier=%d",
             LKSMLDescribeLayer(self),
             LKSMLDescribeView(hostView),
             LKSMLDescribeSize(contextSize),
             renderScale,
             inMultiLayerEffectSubtree,
             canUseDrawHierarchy);
    if (inMultiLayerEffectSubtree) {
        if (!LKSDrawHostViewForMultiLayerEffectSubtree(hostView, contextSize, renderScale)) {
            LKSMLLog(@"group path=effectDispatcherFallback->renderInContext layer=%@", LKSMLDescribeLayer(self));
            [self renderInContext:context];
        } else {
            LKSMLLog(@"group path=effectDispatcherDrew host=%@", LKSMLDescribeView(hostView));
        }
    } else if (canUseDrawHierarchy) {
        LKSMLLog(@"group path=drawViewHierarchy host=%@", LKSMLDescribeView(hostView));
        [hostView drawViewHierarchyInRect:CGRectMake(0, 0, renderSize.width, renderSize.height) afterScreenUpdates:YES];
    } else {
        LKSMLLog(@"group path=renderInContext layer=%@", LKSMLDescribeLayer(self));
        [self renderInContext:context];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    LKSMLLog(@"group EXIT layer=%@ image=%@",
             LKSMLDescribeLayer(self),
             image ? LKSMLDescribeSize(image.size) : @"<nil>");
    return image;
#elif TARGET_OS_OSX
    // For leaf layers (no sublayers) whose contents is not a CGImage
    // (e.g. CGDisplayList on macOS 15+), renderInContext: cannot render them.
    // Use drawInContext: instead, which invokes the layer's drawing code.
    if (!self.sublayers.count && self.contents) {
        CFTypeRef cfContents = (__bridge CFTypeRef)self.contents;
        if (CFGetTypeID(cfContents) != CGImageGetTypeID()) {
            return [CALayer _lks_renderImageForSize:self.bounds.size contentsAreFlipped:self.contentsAreFlipped renderBlock:^(CGContextRef context) {
                [self drawInContext:context];
            }];
        }
    }
    return [CALayer _lks_renderImageForSize:self.bounds.size contentsAreFlipped:self.contentsAreFlipped renderBlock:^(CGContextRef context) {
        [self renderInContext:context];
    }];
#endif
}

#if TARGET_OS_IPHONE
/// Solo screenshot for _UIMultiLayer: hide host subviews via layer opacity
/// (matching Xcode's __dbg_snapshotImage approach) and render the inner
/// backing layer. Outer effect siblings are exposed as child display items.
- (LookinImage *)_lks_multiLayerSoloScreenshotWithLowQuality:(BOOL)lowQuality {
    CALayer *innerLayer = self.lks_multiLayerInnerLayer;
    LookinView *hostView = self.lks_hostView;
    if (!innerLayer || !hostView) {
        return nil;
    }

    // Use bounds.size — _UIMultiLayer.frame includes transform effects
    CGSize renderSize = self.bounds.size;
    CGFloat screenScale = [LKS_MultiplatformAdapter mainScreenScale];
    CGFloat pixelWidth = renderSize.width * screenScale;
    CGFloat pixelHeight = renderSize.height * screenScale;
    if (pixelWidth <= 0 || pixelHeight <= 0) {
        return nil;
    }

    CGFloat renderScale = lowQuality ? 1 : 0;
    CGFloat maxLength = MAX(pixelWidth, pixelHeight);
    if (maxLength > LookinNodeImageMaxLengthInPx) {
        renderScale = MIN(screenScale * LookinNodeImageMaxLengthInPx / maxLength, 1);
    }
    CGSize contextSize = renderSize;
    if (contextSize.width <= 0 || contextSize.height <= 0 || contextSize.width > 20000 || contextSize.height > 20000) {
        NSLog(@"LookinServer - Failed to capture MultiLayer solo screenshot. Invalid context size: %@ x %@", @(contextSize.width), @(contextSize.height));
        return nil;
    }

    // Save subview layer opacities and set to 0 (Xcode's approach)
    NSArray<UIView *> *subviews = [hostView.subviews copy];
    BOOL exposeTextInnerSublayers = LKSMultiLayerShouldExposeTextInnerSublayers(self, hostView);
    BOOL useViewHierarchyForText = !exposeTextInnerSublayers && LKSMultiLayerShouldRenderTextWithViewHierarchy(self, hostView);
    CALayer *captureTargetLayer = (exposeTextInnerSublayers || useViewHierarchyForText) ? self : innerLayer;
    NSMutableArray<NSNumber *> *savedOpacities = [NSMutableArray arrayWithCapacity:subviews.count];
    BOOL savedInnerLayerHidden = innerLayer.hidden;
    if (!useViewHierarchyForText) {
        for (UIView *subview in subviews) {
            [savedOpacities addObject:@(subview.layer.opacity)];
            subview.layer.opacity = 0;
        }
        if (exposeTextInnerSublayers) {
            innerLayer.hidden = YES;
        }
    }

    UIImage *image = nil;
    @try {
        UIGraphicsBeginImageContextWithOptions(contextSize, NO, renderScale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (useViewHierarchyForText) {
            [hostView drawViewHierarchyInRect:CGRectMake(0, 0, renderSize.width, renderSize.height) afterScreenUpdates:YES];
        } else {
            [captureTargetLayer renderInContext:context];
        }
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    } @finally {
        if (!useViewHierarchyForText) {
            [subviews enumerateObjectsUsingBlock:^(UIView * _Nonnull subview, NSUInteger index, BOOL * _Nonnull stop) {
                subview.layer.opacity = savedOpacities[index].floatValue;
            }];
            if (exposeTextInnerSublayers) {
                innerLayer.hidden = savedInnerLayerHidden;
            }
        }
    }

    return image;
}
#endif

- (LookinImage *)lks_soloScreenshotWithLowQuality:(BOOL)lowQuality {
#if TARGET_OS_IPHONE
    if (self.lks_isMultiLayerContainer) {
        return [self _lks_multiLayerSoloScreenshotWithLowQuality:lowQuality];
    }
#endif
    if (!self.sublayers.count) {
        return nil;
    }

    CGFloat screenScale = [LKS_MultiplatformAdapter mainScreenScale];
    CGFloat pixelWidth = self.frame.size.width * screenScale;
    CGFloat pixelHeight = self.frame.size.height * screenScale;
    if (pixelWidth <= 0 || pixelHeight <= 0) {
        return nil;
    }

    CGFloat renderScale = lowQuality ? 1 : 0;
    CGFloat maxLength = MAX(pixelWidth, pixelHeight);
    if (maxLength > LookinNodeImageMaxLengthInPx) {
        // 确保最终绘制出的图片长和宽都不能超过 LookinNodeImageMaxLengthInPx
        // 如果算出的 renderScale 大于 1 则取 1，因为似乎用 1 渲染的速度要比一个别的奇怪的带小数点的数字要更快
        renderScale = MIN(screenScale * LookinNodeImageMaxLengthInPx / maxLength, 1);
    }
    CGSize contextSize = self.frame.size;
    if (contextSize.width <= 0 || contextSize.height <= 0 || contextSize.width > 20000 || contextSize.height > 20000) {
        NSLog(@"LookinServer - Failed to capture screenshot. Invalid context size: %@ x %@", @(contextSize.width), @(contextSize.height));
        return nil;
    }
    if (self.sublayers.count) {
        NSArray<CALayer *> *sublayers = [self.sublayers copy];
        NSMutableArray<CALayer *> *visibleSublayers = [NSMutableArray arrayWithCapacity:sublayers.count];
        LookinImage *image = nil;
        @try {
            [sublayers enumerateObjectsUsingBlock:^(__kindof CALayer * _Nonnull sublayer, NSUInteger idx, BOOL * _Nonnull stop) {
                if (!sublayer.hidden) {
                    sublayer.hidden = YES;
                    [visibleSublayers addObject:sublayer];
                }
            }];
#if TARGET_OS_IPHONE
            UIGraphicsBeginImageContextWithOptions(contextSize, NO, renderScale);
            CGContextRef soloContext = UIGraphicsGetCurrentContext();
            [self renderInContext:soloContext];
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
#elif TARGET_OS_OSX
            image = [CALayer _lks_renderImageForSize:self.bounds.size contentsAreFlipped:self.contentsAreFlipped renderBlock:^(CGContextRef context) {
                [self renderInContext:context];
            }];
#endif
        } @finally {
            [visibleSublayers enumerateObjectsUsingBlock:^(CALayer * _Nonnull sublayer, NSUInteger idx, BOOL * _Nonnull stop) {
                sublayer.hidden = NO;
            }];
        }
        return image;
    }
    return nil;
}

- (NSArray<NSArray<NSString *> *> *)lks_relatedClassChainList {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:2];
    if (self.lks_hostView) {
        [array addObject:[CALayer lks_getClassListOfObject:self.lks_hostView endingClass:LookinViewString]];
        LookinViewController* vc = [self.lks_hostView lks_findHostViewController];
        if (vc) {
            [array addObject:[CALayer lks_getClassListOfObject:vc endingClass:LookinViewControllerString]];
        }
    } else {
        [array addObject:[CALayer lks_getClassListOfObject:self endingClass:@"CALayer"]];
    }
    return array.copy;
}

+ (NSArray<NSString *> *)lks_getClassListOfObject:(id)object endingClass:(NSString *)endingClass {
    NSArray<NSString *> *completedList = [object lks_classChainList];
    NSUInteger endingIdx = [completedList indexOfObject:endingClass];
    if (endingIdx != NSNotFound) {
        completedList = [completedList subarrayWithRange:NSMakeRange(0, endingIdx + 1)];
    }
    return completedList;
}

- (NSArray<NSString *> *)lks_selfRelation {
    NSMutableArray *array = [NSMutableArray array];
    NSMutableArray<LookinIvarTrace *> *ivarTraces = [NSMutableArray array];
    if (self.lks_hostView) {
        LookinViewController* vc = [self.lks_hostView lks_findHostViewController];
        if (vc) {
            [array addObject:[NSString stringWithFormat:@"(%@ *).view", NSStringFromClass(vc.class)]];

            [ivarTraces addObjectsFromArray:vc.lks_ivarTraces];
        }
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

- (LookinColor *)lks_backgroundColor {
    return [LookinColor lks_colorWithCGColor:self.backgroundColor];
}
- (void)setLks_backgroundColor:(LookinColor *)lks_backgroundColor {
    self.backgroundColor = lks_backgroundColor.CGColor;
}

- (LookinColor *)lks_borderColor {
    return [LookinColor lks_colorWithCGColor:self.borderColor];
}
- (void)setLks_borderColor:(LookinColor *)lks_borderColor {
    self.borderColor = lks_borderColor.CGColor;
}

- (LookinColor *)lks_shadowColor {
    return [LookinColor lks_colorWithCGColor:self.shadowColor];
}
- (void)setLks_shadowColor:(LookinColor *)lks_shadowColor {
    self.shadowColor = lks_shadowColor.CGColor;
}

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
