#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION || TARGET_OS_MAC)
//
//  LKS_HierarchyDisplayItemsMaker.m
//  LookinServer
//
//  Created by Li Kai on 2019/2/19.
//  https://lookin.work
//

#import "LKS_HierarchyDisplayItemsMaker.h"
#import "LookinDisplayItem.h"
#import "LookinObject.h"
#import "LKS_AttrGroupsMaker.h"
#import "CALayer+LookinServer.h"
#import "NSObject+LookinServer.h"
#import "LKS_MultiplatformAdapter.h"

#if TARGET_OS_OSX

@implementation LKS_HierarchyDisplayItemsMaker

static NSArray<NSView *> *LKHideVisibleSubviewsForScreenshot(NSArray<NSView *> *subviews) {
    NSMutableArray<NSView *> *hiddenSubviews = [NSMutableArray array];
    for (NSView *subview in subviews.copy) {
        if (!subview.isHidden) {
            subview.hidden = YES;
            [hiddenSubviews addObject:subview];
        }
    }
    return hiddenSubviews.copy;
}

static void LKRestoreHiddenSubviewsForScreenshot(NSArray<NSView *> *subviews) {
    for (NSView *subview in subviews) {
        subview.hidden = NO;
    }
}

static NSImage *LKSnapshotImageForView(NSView *view) {
    if (!view || view.bounds.size.width <= 0 || view.bounds.size.height <= 0) {
        return nil;
    }
    NSBitmapImageRep *bitmapRep = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
    if (!bitmapRep) {
        return nil;
    }
    [bitmapRep setSize:view.bounds.size];
    [view cacheDisplayInRect:view.bounds toBitmapImageRep:bitmapRep];
    NSImage *image = [[NSImage alloc] initWithSize:view.bounds.size];
    [image addRepresentation:bitmapRep];
    return image;
}

+ (CGRect)_normalizedScreenRect:(CGRect)rect forWindow:(NSWindow *)window {
    NSScreen *screen = window.screen ?: NSScreen.mainScreen;
    if (!screen) {
        return rect;
    }
    CGFloat x = rect.origin.x - screen.frame.origin.x;
    CGFloat y = NSMaxY(screen.frame) - CGRectGetMaxY(rect);
    return CGRectMake(x, y, rect.size.width, rect.size.height);
}

+ (CGRect)_windowRectForView:(NSView *)view {
    if (!view.window) {
        return view.frame;
    }
    NSRect rectInWindow = [view convertRect:view.bounds toView:nil];
    NSRect windowFrame = view.window.frame;
    return NSMakeRect(windowFrame.origin.x + rectInWindow.origin.x,
                      windowFrame.origin.y + rectInWindow.origin.y,
                      rectInWindow.size.width,
                      rectInWindow.size.height);
}

+ (LookinDisplayItem *)_itemForLayer:(CALayer *)layer
                              window:(NSWindow *)window
                         screenshots:(BOOL)hasScreenshots
                            attrList:(BOOL)hasAttrList {
    if (!layer) {
        return nil;
    }
    LookinDisplayItem *item = [LookinDisplayItem new];
    item.layerObject = [LookinObject instanceWithObject:layer];
    item.frame = [self _normalizedScreenRect:[layer lks_frameInWindow:window] forWindow:window];
    item.bounds = layer.bounds;
    item.isHidden = layer.hidden;
    item.alpha = layer.opacity;
    item.backgroundColor = layer.lks_backgroundColor;
    item.shouldCaptureImage = YES;
    item.screenshotEncodeType = LookinDisplayItemImageEncodeTypeNSData;
    if (hasScreenshots) {
        item.groupScreenshot = [layer lks_groupScreenshotWithLowQuality:NO];
        item.soloScreenshot = [layer lks_soloScreenshotWithLowQuality:NO];
    }
    if (hasAttrList) {
        item.attributesGroupList = [LKS_AttrGroupsMaker attrGroupsForLayer:layer];
    }

    NSMutableArray<LookinDisplayItem *> *children = [NSMutableArray array];
    for (CALayer *sublayer in layer.sublayers ?: @[]) {
        if (sublayer.lks_hostView) {
            continue;
        }
        LookinDisplayItem *child = [self _itemForLayer:sublayer window:window screenshots:hasScreenshots attrList:hasAttrList];
        if (child) {
            [children addObject:child];
        }
    }
    item.subitems = children.copy;
    return item;
}

+ (LookinDisplayItem *)_itemForView:(NSView *)view
                             window:(NSWindow *)window
                        screenshots:(BOOL)hasScreenshots
                           attrList:(BOOL)hasAttrList
                    lowImageQuality:(BOOL)lowQuality {
    LookinDisplayItem *item = [LookinDisplayItem new];
    item.viewObject = [LookinObject instanceWithObject:view];
    if (view.layer) {
        item.layerObject = [LookinObject instanceWithObject:view.layer];
        item.backgroundColor = view.layer.lks_backgroundColor;
    }
    if (hasAttrList) {
        item.attributesGroupList = [LKS_AttrGroupsMaker attrGroupsForView:view];
    }
    if (hasScreenshots) {
        item.groupScreenshot = LKSnapshotImageForView(view);
        if (view.subviews.count) {
            NSArray<NSView *> *hiddenSubviews = LKHideVisibleSubviewsForScreenshot(view.subviews ?: @[]);
            @try {
                item.soloScreenshot = LKSnapshotImageForView(view);
            } @finally {
                LKRestoreHiddenSubviewsForScreenshot(hiddenSubviews);
            }
        }
    }

    item.frame = [self _normalizedScreenRect:[self _windowRectForView:view] forWindow:window];
    item.bounds = view.bounds;
    item.isHidden = view.isHidden;
    item.alpha = 1;
    item.shouldCaptureImage = YES;
    item.screenshotEncodeType = LookinDisplayItemImageEncodeTypeNSData;

    NSMutableArray<LookinDisplayItem *> *children = [NSMutableArray array];
    for (NSView *subview in view.subviews ?: @[]) {
        LookinDisplayItem *child = [self _itemForView:subview window:window screenshots:hasScreenshots attrList:hasAttrList lowImageQuality:lowQuality];
        if (child) {
            [children addObject:child];
        }
    }
    if (view.layer) {
        for (CALayer *sublayer in view.layer.sublayers ?: @[]) {
            if (sublayer.lks_hostView) {
                continue;
            }
            LookinDisplayItem *layerChild = [self _itemForLayer:sublayer window:window screenshots:hasScreenshots attrList:hasAttrList];
            if (layerChild) {
                [children addObject:layerChild];
            }
        }
    }
    item.subitems = children.copy;
    return item;
}

+ (NSArray<LookinDisplayItem *> *)itemsWithScreenshots:(BOOL)hasScreenshots attrList:(BOOL)hasAttrList lowImageQuality:(BOOL)lowQuality readCustomInfo:(BOOL)readCustomInfo saveCustomSetter:(BOOL)saveCustomSetter {
    if (hasAttrList) {
        [NSView lks_rebuildGlobalInvolvedRawConstraints];
    }
    NSMutableArray<LookinDisplayItem *> *items = [NSMutableArray array];
    for (NSWindow *window in [LKS_MultiplatformAdapter allWindows]) {
        LookinDisplayItem *windowItem = [LookinDisplayItem new];
        windowItem.viewObject = [LookinObject instanceWithObject:window];
        if (window.contentView.layer) {
            windowItem.layerObject = [LookinObject instanceWithObject:window.contentView.layer];
        }
        windowItem.representedAsKeyWindow = window.keyWindow;
        windowItem.frame = [self _normalizedScreenRect:window.frame forWindow:window];
        windowItem.bounds = window.contentView.bounds;
        windowItem.isHidden = !window.visible;
        windowItem.alpha = window.alphaValue;
        windowItem.shouldCaptureImage = YES;
        windowItem.screenshotEncodeType = LookinDisplayItemImageEncodeTypeNSData;
        if (hasAttrList) {
            windowItem.attributesGroupList = [LKS_AttrGroupsMaker attrGroupsForWindow:window];
        }
        if (window.contentView) {
            LookinDisplayItem *contentItem = [self _itemForView:window.contentView window:window screenshots:hasScreenshots attrList:hasAttrList lowImageQuality:lowQuality];
            windowItem.subitems = contentItem ? @[contentItem] : @[];
        }
        [items addObject:windowItem];
    }
    return items.copy;
}

+ (NSArray<LookinDisplayItem *> *)subitemsOfLayer:(CALayer *)layer {
    if (!layer) {
        return @[];
    }
    NSWindow *window = [layer lks_window];
    NSMutableArray<LookinDisplayItem *> *items = [NSMutableArray array];
    for (CALayer *sublayer in layer.sublayers ?: @[]) {
        if (sublayer.lks_hostView) {
            continue;
        }
        LookinDisplayItem *item = [self _itemForLayer:sublayer window:window screenshots:NO attrList:NO];
        if (item) {
            [items addObject:item];
        }
    }
    return items.copy;
}

@end

#else

#import "LKS_TraceManager.h"
#import "LKS_EventHandlerMaker.h"
#import "LookinServerDefines.h"
#import "UIColor+LookinServer.h"
#import "LKSConfigManager.h"
#import "LKS_CustomAttrGroupsMaker.h"
#import "LKS_CustomDisplayItemsMaker.h"
#import "LKS_CustomAttrSetterManager.h"

@implementation LKS_HierarchyDisplayItemsMaker

+ (NSArray<LookinDisplayItem *> *)itemsWithScreenshots:(BOOL)hasScreenshots attrList:(BOOL)hasAttrList lowImageQuality:(BOOL)lowQuality readCustomInfo:(BOOL)readCustomInfo saveCustomSetter:(BOOL)saveCustomSetter {
    [[LKS_TraceManager sharedInstance] reload];
    NSArray<UIWindow *> *windows = [LKS_MultiplatformAdapter allWindows];
    NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:windows.count];
    [windows enumerateObjectsUsingBlock:^(__kindof UIWindow * _Nonnull window, NSUInteger idx, BOOL * _Nonnull stop) {
        LookinDisplayItem *item = [self _displayItemWithLayer:window.layer screenshots:hasScreenshots attrList:hasAttrList lowImageQuality:lowQuality readCustomInfo:readCustomInfo saveCustomSetter:saveCustomSetter];
        item.representedAsKeyWindow = window.isKeyWindow;
        if (item) {
            [resultArray addObject:item];
        }
    }];
    return [resultArray copy];
}

+ (LookinDisplayItem *)_displayItemWithLayer:(CALayer *)layer screenshots:(BOOL)hasScreenshots attrList:(BOOL)hasAttrList lowImageQuality:(BOOL)lowQuality readCustomInfo:(BOOL)readCustomInfo saveCustomSetter:(BOOL)saveCustomSetter {
    if (!layer) {
        return nil;
    }
    LookinDisplayItem *item = [LookinDisplayItem new];
    item.frame = layer.frame;
    item.bounds = layer.bounds;
    if (hasScreenshots) {
        item.soloScreenshot = [layer lks_soloScreenshotWithLowQuality:lowQuality];
        item.groupScreenshot = [layer lks_groupScreenshotWithLowQuality:lowQuality];
        item.screenshotEncodeType = LookinDisplayItemImageEncodeTypeNSData;
    }
    if (hasAttrList) {
        item.attributesGroupList = [LKS_AttrGroupsMaker attrGroupsForLayer:layer];
    }
    item.isHidden = layer.isHidden;
    item.alpha = layer.opacity;
    item.layerObject = [LookinObject instanceWithObject:layer];
    item.shouldCaptureImage = [LKSConfigManager shouldCaptureScreenshotOfLayer:layer];
    if (layer.lks_hostView) {
        UIView *view = layer.lks_hostView;
        item.viewObject = [LookinObject instanceWithObject:view];
        item.eventHandlers = [LKS_EventHandlerMaker makeForView:view];
        item.backgroundColor = view.backgroundColor;
    } else {
        item.backgroundColor = [UIColor lks_colorWithCGColor:layer.backgroundColor];
    }
    NSMutableArray<LookinDisplayItem *> *children = [NSMutableArray array];
    for (CALayer *sublayer in layer.sublayers ?: @[]) {
        LookinDisplayItem *child = [self _displayItemWithLayer:sublayer screenshots:hasScreenshots attrList:hasAttrList lowImageQuality:lowQuality readCustomInfo:readCustomInfo saveCustomSetter:saveCustomSetter];
        if (child) {
            [children addObject:child];
        }
    }
    item.subitems = children.copy;
    return item;
}

+ (NSArray<LookinDisplayItem *> *)subitemsOfLayer:(CALayer *)layer {
    if (!layer) {
        return @[];
    }
    NSMutableArray<LookinDisplayItem *> *items = [NSMutableArray array];
    for (CALayer *sublayer in layer.sublayers ?: @[]) {
        LookinDisplayItem *item = [self _displayItemWithLayer:sublayer screenshots:NO attrList:NO lowImageQuality:NO readCustomInfo:YES saveCustomSetter:YES];
        if (item) {
            [items addObject:item];
        }
    }
    return items.copy;
}

@end

#endif

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
