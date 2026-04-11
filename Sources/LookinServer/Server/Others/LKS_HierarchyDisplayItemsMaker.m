#ifdef SHOULD_COMPILE_LOOKIN_SERVER

//
//  LKS_HierarchyDisplayItemsMaker.m
//  LookinServer
//
//  Created by Li Kai on 2019/2/19.
//  https://lookin.work
//

#import "LKS_HierarchyDisplayItemsMaker.h"
#import "LookinDisplayItem.h"
#import "LKS_TraceManager.h"
#import "LKS_AttrGroupsMaker.h"
#import "LKS_EventHandlerMaker.h"
#import "LookinServerDefines.h"
#import "UIColor+LookinServer.h"
#import "LKSConfigManager.h"
#import "LKS_CustomAttrGroupsMaker.h"
#import "LKS_CustomDisplayItemsMaker.h"
#import "LKS_CustomAttrSetterManager.h"
#import "LKS_MultiplatformAdapter.h"
#import "NSValue+Lookin.h"
#import "LookinAttributesGroup.h"
#import "LookinAttributesSection.h"
#import "LookinAttribute.h"
#import "LookinAttrIdentifiers.h"
//#import "LookinObject+LookinServer.h"
#import "UIView+LookinServer.h"
#import "CALayer+LookinServer.h"
#import "NSWindow+LookinServer.h"
#if TARGET_OS_IPHONE
#import "UIWindowScene+LookinServer.h"
#endif

#if TARGET_OS_IPHONE
static NSArray<CALayer *> *LKSOrderedSublayersForDisplay(CALayer *layer) {
    NSArray<CALayer *> *sublayers = [layer.sublayers copy];
    if (!layer.lks_isMultiLayerContainer) {
        return sublayers ?: @[];
    }

    CALayer *innerLayer = layer.lks_multiLayerInnerLayer;
    if (!innerLayer) {
        return sublayers ?: @[];
    }
    NSArray<CALayer *> *innerSublayers = [innerLayer.sublayers copy];

    NSMutableArray<CALayer *> *orderedSublayers = [NSMutableArray array];
    BOOL insertedInnerSublayers = NO;
    for (CALayer *sublayer in sublayers) {
        if (sublayer == innerLayer) {
            [orderedSublayers addObjectsFromArray:innerSublayers ?: @[]];
            insertedInnerSublayers = YES;
        } else {
            [orderedSublayers addObject:sublayer];
        }
    }
    if (!insertedInnerSublayers) {
        [orderedSublayers addObjectsFromArray:innerSublayers ?: @[]];
    }
    return orderedSublayers.copy;
}
#endif

@implementation LKS_HierarchyDisplayItemsMaker

+ (NSArray<LookinDisplayItem *> *)itemsWithScreenshots:(BOOL)hasScreenshots attrList:(BOOL)hasAttrList lowImageQuality:(BOOL)lowQuality readCustomInfo:(BOOL)readCustomInfo saveCustomSetter:(BOOL)saveCustomSetter {

    [[LKS_TraceManager sharedInstance] reload];

#if TARGET_OS_IPHONE
    NSMutableArray<LookinDisplayItem *> *resultArray = [NSMutableArray array];
    if (@available(iOS 13.0, *)) {
        // iOS 13+: group windows by UIWindowScene, scene is the top-level container
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            UIWindowScene *windowScene = (UIWindowScene *)scene;

            // Create the scene display item
            LookinDisplayItem *sceneItem = [LookinDisplayItem new];
            sceneItem.windowObject = [LookinObject instanceWithObject:windowScene];
            sceneItem.shouldCaptureImage = YES;
            sceneItem.alpha = 1.0;

            // Build display title: "UIWindowScene – Title (State)"
            NSString *sceneTitle = windowScene.title.length > 0 ? windowScene.title : nil;
            NSString *stateString = nil;
            switch (windowScene.activationState) {
                case UISceneActivationStateForegroundActive: stateString = @"Foreground Active"; break;
                case UISceneActivationStateForegroundInactive: stateString = @"Foreground Inactive"; break;
                case UISceneActivationStateBackground: stateString = @"Background"; break;
                case UISceneActivationStateUnattached: stateString = @"Unattached"; break;
                default: stateString = @"Unknown"; break;
            }
            NSMutableString *displayTitle = [NSMutableString stringWithString:@"UIWindowScene"];
            if (sceneTitle) {
                [displayTitle appendFormat:@" – %@", sceneTitle];
            }
            [displayTitle appendFormat:@" (%@)", stateString];
            sceneItem.customDisplayTitle = displayTitle;

            if (hasAttrList) {
                sceneItem.attributesGroupList = [LKS_AttrGroupsMaker attrGroupsForWindowScene:windowScene];
            }

            // Build child items for each window in this scene
            NSMutableArray<LookinDisplayItem *> *windowItems = [NSMutableArray array];
            NSArray<UIWindow *> *windows = windowScene.windows;
            for (UIWindow *window in windows) {
                LookinDisplayItem *windowItem = [self _displayItemWithLayer:window.layer screenshots:hasScreenshots attrList:hasAttrList lowImageQuality:lowQuality readCustomInfo:readCustomInfo saveCustomSetter:saveCustomSetter];
                if (windowItem) {
                    windowItem.representedAsKeyWindow = window.isKeyWindow;
                    [windowItems addObject:windowItem];
                }
            }

            // Also check for keyWindow not in windows list (e.g. form sheet presentations)
            UIWindow *keyWindow = nil;
            if (@available(iOS 15.0, *)) {
                keyWindow = windowScene.keyWindow;
            } else {
                for (UIWindow *window in windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
            }
            if (keyWindow && ![windows containsObject:keyWindow]) {
                if (![NSStringFromClass(keyWindow.class) containsString:@"HUD"]) {
                    LookinDisplayItem *keyWindowItem = [self _displayItemWithLayer:keyWindow.layer screenshots:hasScreenshots attrList:hasAttrList lowImageQuality:lowQuality readCustomInfo:readCustomInfo saveCustomSetter:saveCustomSetter];
                    if (keyWindowItem) {
                        keyWindowItem.representedAsKeyWindow = YES;
                        [windowItems addObject:keyWindowItem];
                    }
                }
            }

            // 如果 scene 包含 key window，则将 scene 也标记为 key
            for (LookinDisplayItem *windowItem in windowItems) {
                if (windowItem.representedAsKeyWindow) {
                    sceneItem.representedAsKeyWindow = YES;
                    break;
                }
            }

            sceneItem.subitems = windowItems;
            [resultArray addObject:sceneItem];
        }
    } else {
        // iOS 12 fallback: flat window list without scene grouping
        NSArray<LookinWindow *> *windows = [LKS_MultiplatformAdapter allWindows];
        for (LookinWindow *window in windows) {
            LookinDisplayItem *item = [self _displayItemWithLayer:window.layer screenshots:hasScreenshots attrList:hasAttrList lowImageQuality:lowQuality readCustomInfo:readCustomInfo saveCustomSetter:saveCustomSetter];
            if (item) {
                item.representedAsKeyWindow = window.isKeyWindow;
                [resultArray addObject:item];
            }
        }
    }

    return [resultArray copy];
#elif TARGET_OS_OSX
    NSArray<LookinWindow *> *windows = [LKS_MultiplatformAdapter allWindows];
    NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:windows.count];
    [windows enumerateObjectsUsingBlock:^(__kindof LookinWindow * _Nonnull window, NSUInteger idx, BOOL * _Nonnull stop) {
        // macOS: view is the source of truth — always start from the root view
        NSView *rootView = window.lks_rootView;
        LookinDisplayItem *item = [LookinDisplayItem new];
        item.windowObject = [LookinObject instanceWithObject:window];
        item.frame = window.lks_bounds;
        item.bounds = window.lks_bounds;
        item.backgroundColor = window.backgroundColor;
        item.shouldCaptureImage = YES;
        item.alpha = window.alphaValue;
        if (rootView.layer) {
            item.groupScreenshot = [rootView.layer lks_groupScreenshotWithLowQuality:lowQuality];
            item.soloScreenshot = [rootView.layer lks_soloScreenshotWithLowQuality:lowQuality];
        } else {
            item.groupScreenshot = [rootView lks_groupScreenshotWithLowQuality:lowQuality];
            item.soloScreenshot = [rootView lks_soloScreenshotWithLowQuality:lowQuality];
        }
        item.screenshotEncodeType = LookinDisplayItemImageEncodeTypeNSData;
        if (window.windowController) {
            item.hostWindowControllerObject = [LookinObject instanceWithObject:window.windowController];
        }
        if (hasAttrList) {
            item.attributesGroupList = [LKS_AttrGroupsMaker attrGroupsForWindow:window];
        }
        if (rootView) {
            item.subitems = @[[self _displayItemWithView:rootView screenshots:hasScreenshots attrList:hasAttrList lowImageQuality:lowQuality readCustomInfo:readCustomInfo saveCustomSetter:saveCustomSetter]];
        }
        item.representedAsKeyWindow = window.isKeyWindow;
        if (item) {
            [resultArray addObject:item];
        }
    }];

    return [resultArray copy];
#endif
}

+ (LookinDisplayItem *)_displayItemWithLayer:(CALayer *)layer screenshots:(BOOL)hasScreenshots attrList:(BOOL)hasAttrList lowImageQuality:(BOOL)lowQuality readCustomInfo:(BOOL)readCustomInfo saveCustomSetter:(BOOL)saveCustomSetter {
    if (!layer) {
        return nil;
    }

#if TARGET_OS_OSX
    // macOS: if this layer has a host view, delegate to the view-based path
    // to preserve the view hierarchy as the source of truth.
    LookinView *earlyHostView = layer.lks_hostView;
    if (earlyHostView) {
        return [self _displayItemWithView:earlyHostView screenshots:hasScreenshots attrList:hasAttrList lowImageQuality:lowQuality readCustomInfo:readCustomInfo saveCustomSetter:saveCustomSetter];
    }
#endif

    LookinDisplayItem *item = [LookinDisplayItem new];
    CGRect layerFrame = layer.frame;
    LookinView *hostView = layer.lks_hostView;
    if (hostView && hostView.superview) {
        layerFrame = [hostView.superview convertRect:layerFrame toView:nil];
    }
    if ([self validateFrame:layerFrame]) {
    item.frame = layer.frame;
    } else {
        NSLog(@"LookinServer - The layer frame(%@) seems really weird. Lookin will ignore it to avoid potential render error in Lookin.", NSStringFromCGRect(layer.frame));
        item.frame = CGRectZero;
    }
    item.bounds = layer.bounds;
    if (hasScreenshots) {
        item.soloScreenshot = [layer lks_soloScreenshotWithLowQuality:lowQuality];
        item.groupScreenshot = [layer lks_groupScreenshotWithLowQuality:lowQuality];
        item.screenshotEncodeType = LookinDisplayItemImageEncodeTypeNSData;
    }

    if (hasAttrList) {
        item.attributesGroupList = [LKS_AttrGroupsMaker attrGroupsForLayer:layer];
        LKS_CustomAttrGroupsMaker *maker = [[LKS_CustomAttrGroupsMaker alloc] initWithLayer:layer];
        [maker execute];
        item.customAttrGroupList = [maker getGroups];
        item.customDisplayTitle = [maker getCustomDisplayTitle];
        item.danceuiSource = [maker getDanceUISource];
    }

#if TARGET_OS_IPHONE
    // Annotate MultiLayer rendering mode in the attribute panel
    if (layer.lks_isMultiLayerContainer) {
        LookinAttribute *multiLayerAttr = [LookinAttribute new];
        multiLayerAttr.identifier = LookinAttr_UserCustom;
        multiLayerAttr.displayTitle = @"MultiLayer";
        multiLayerAttr.attrType = LookinAttrTypeBOOL;
        multiLayerAttr.value = @(YES);

        LookinAttributesSection *renderingSection = [LookinAttributesSection new];
        renderingSection.identifier = LookinAttrSec_UserCustom;
        renderingSection.attributes = @[multiLayerAttr];

        LookinAttributesGroup *renderingGroup = [LookinAttributesGroup new];
        renderingGroup.identifier = LookinAttrGroup_UserCustom;
        renderingGroup.userCustomTitle = @"Rendering";
        renderingGroup.attrSections = @[renderingSection];

        if (item.customAttrGroupList) {
            item.customAttrGroupList = [item.customAttrGroupList arrayByAddingObject:renderingGroup];
        } else {
            item.customAttrGroupList = @[renderingGroup];
        }
    }
#endif

    item.isHidden = layer.isHidden;
    item.alpha = layer.opacity;
    item.layerObject = [LookinObject instanceWithObject:layer];
    item.shouldCaptureImage = [LKSConfigManager shouldCaptureScreenshotOfLayer:layer];

    LookinView *view = layer.lks_hostView;
    if (view) {
#if TARGET_OS_OSX
        item.flipped = view.isFlipped;
#endif
        item.viewObject = [LookinObject instanceWithObject:view];
        item.eventHandlers = [LKS_EventHandlerMaker makeForView:view];
        item.backgroundColor = [view valueForKeyPath:@"backgroundColor"];

        LookinViewController* vc = [view lks_findHostViewController];
        if (vc) {
            item.hostViewControllerObject = [LookinObject instanceWithObject:vc];
        }
    } else {
#if TARGET_OS_OSX
        item.flipped = layer.isGeometryFlipped;
#endif
        item.backgroundColor = [LookinColor lks_colorWithCGColor:layer.backgroundColor];
    }

#if TARGET_OS_OSX
    // macOS 上优先使用视图层级遍历，因为它是权威的。
    // macOS 26+ 上 layer.sublayers 可能不包含所有子视图的 backing layer。
    if (view && view.subviews.count > 0) {
        NSMutableArray<LookinDisplayItem *> *allSubitems = [NSMutableArray array];
        NSMutableSet<CALayer *> *processedLayers = [NSMutableSet set];

        for (NSView *subview in view.subviews.copy) {
            if (subview.layer) {
                [processedLayers addObject:subview.layer];
                LookinDisplayItem *subviewItem = [self _displayItemWithLayer:subview.layer screenshots:hasScreenshots attrList:hasAttrList lowImageQuality:lowQuality readCustomInfo:readCustomInfo saveCustomSetter:saveCustomSetter];
                if (subviewItem) {
                    [allSubitems addObject:subviewItem];
                }
            } else {
                LookinDisplayItem *subviewItem = [self _displayItemWithView:subview screenshots:hasScreenshots attrList:hasAttrList lowImageQuality:lowQuality readCustomInfo:readCustomInfo saveCustomSetter:saveCustomSetter];
                if (subviewItem) {
                    [allSubitems addObject:subviewItem];
        }
    }
        }

        // 添加未关联到任何子视图的孤立 sublayer
        for (CALayer *sublayer in layer.sublayers.copy) {
            if (![processedLayers containsObject:sublayer]) {
                LookinDisplayItem *sublayerItem = [self _displayItemWithLayer:sublayer screenshots:hasScreenshots attrList:hasAttrList lowImageQuality:lowQuality readCustomInfo:readCustomInfo saveCustomSetter:saveCustomSetter];
                if (sublayerItem) {
                    [allSubitems addObject:sublayerItem];
                }
            }
        }

        item.subitems = allSubitems.copy;
    } else if (layer.sublayers.count) {
        NSArray<CALayer *> *sublayers = [layer.sublayers copy];
        NSMutableArray<LookinDisplayItem *> *allSubitems = [NSMutableArray arrayWithCapacity:sublayers.count];
        [sublayers enumerateObjectsUsingBlock:^(__kindof CALayer * _Nonnull sublayer, NSUInteger idx, BOOL * _Nonnull stop) {
            LookinDisplayItem *sublayer_item = [self _displayItemWithLayer:sublayer screenshots:hasScreenshots attrList:hasAttrList lowImageQuality:lowQuality readCustomInfo:readCustomInfo saveCustomSetter:saveCustomSetter];
            if (sublayer_item) {
                [allSubitems addObject:sublayer_item];
            }
        }];
        item.subitems = [allSubitems copy];
    }
#else
    NSArray<CALayer *> *sublayers = LKSOrderedSublayersForDisplay(layer);
    if (sublayers.count) {
        NSMutableArray<LookinDisplayItem *> *allSubitems = [NSMutableArray arrayWithCapacity:sublayers.count];
        [sublayers enumerateObjectsUsingBlock:^(__kindof CALayer * _Nonnull sublayer, NSUInteger idx, BOOL * _Nonnull stop) {
            LookinDisplayItem *sublayer_item = [self _displayItemWithLayer:sublayer screenshots:hasScreenshots attrList:hasAttrList lowImageQuality:lowQuality readCustomInfo:readCustomInfo saveCustomSetter:saveCustomSetter];
            if (sublayer_item) {
                [allSubitems addObject:sublayer_item];
            }
        }];
        item.subitems = [allSubitems copy];
    }
#endif
    if (readCustomInfo) {
        NSArray<LookinDisplayItem *> *customSubitems = [[[LKS_CustomDisplayItemsMaker alloc] initWithLayer:layer saveAttrSetter:saveCustomSetter] make];
        if (customSubitems.count > 0) {
            if (item.subitems) {
                item.subitems = [item.subitems arrayByAddingObjectsFromArray:customSubitems];
            } else {
                item.subitems = customSubitems;
            }
        }
    }

    return item;
}

+ (NSArray<LookinDisplayItem *> *)subitemsOfLayer:(CALayer *)layer {
    if (!layer) {
        return @[];
    }
#if TARGET_OS_OSX
    // macOS: if this layer has a host view, delegate to the view-based path
    LookinView *hostView = layer.lks_hostView;
    if (hostView) {
        return [self subitemsOfView:hostView];
    }
    if (layer.sublayers.count == 0) {
        return @[];
    }
#else
    NSArray<CALayer *> *sublayers = LKSOrderedSublayersForDisplay(layer);
    if (sublayers.count == 0) {
        return @[];
    }
#endif
    [[LKS_TraceManager sharedInstance] reload];

    NSMutableArray<LookinDisplayItem *> *resultSubitems = [NSMutableArray array];

#if TARGET_OS_OSX
    NSArray<CALayer *> *sublayers = [layer.sublayers copy];
#endif
    [sublayers enumerateObjectsUsingBlock:^(__kindof CALayer * _Nonnull sublayer, NSUInteger idx, BOOL * _Nonnull stop) {
        LookinDisplayItem *sublayerItem = [self _displayItemWithLayer:sublayer screenshots:NO attrList:NO lowImageQuality:NO readCustomInfo:YES saveCustomSetter:YES];
        if (sublayerItem) {
            [resultSubitems addObject:sublayerItem];
        }
    }];

    NSArray<LookinDisplayItem *> *customSubitems = [[[LKS_CustomDisplayItemsMaker alloc] initWithLayer:layer saveAttrSetter:YES] make];
    if (customSubitems.count > 0) {
        [resultSubitems addObjectsFromArray:customSubitems];
    }

    return resultSubitems;
}

#if TARGET_OS_OSX
+ (LookinDisplayItem *)_displayItemWithView:(NSView *)view screenshots:(BOOL)hasScreenshots attrList:(BOOL)hasAttrList lowImageQuality:(BOOL)lowQuality readCustomInfo:(BOOL)readCustomInfo saveCustomSetter:(BOOL)saveCustomSetter {
    if (!view) {
        return nil;
    }

    LookinDisplayItem *item = [LookinDisplayItem new];
    CGRect viewFrame = view.frame;

    if (view.superview) {
        viewFrame = [view.superview convertRect:viewFrame toView:nil];
    }
    if ([self validateFrame:viewFrame]) {
        item.frame = view.frame;
    } else {
        NSLog(@"LookinServer - The layer frame(%@) seems really weird. Lookin will ignore it to avoid potential render error in Lookin.", NSStringFromCGRect(view.frame));
        item.frame = CGRectZero;
    }
    item.bounds = view.bounds;
    item.flipped = view.isFlipped;
    if (hasScreenshots) {
        item.soloScreenshot = [view lks_soloScreenshotWithLowQuality:lowQuality];
        item.groupScreenshot = [view lks_groupScreenshotWithLowQuality:lowQuality];
        item.screenshotEncodeType = LookinDisplayItemImageEncodeTypeNSData;
    }

    if (hasAttrList) {
        item.attributesGroupList = [LKS_AttrGroupsMaker attrGroupsForView:view];
        LKS_CustomAttrGroupsMaker *maker = [[LKS_CustomAttrGroupsMaker alloc] initWithView:view];
        [maker execute];
        item.customAttrGroupList = [maker getGroups];
        item.customDisplayTitle = [maker getCustomDisplayTitle];
        item.danceuiSource = [maker getDanceUISource];
    }

    item.isHidden = view.isHidden;
    item.alpha = view.alphaValue;
    item.viewObject = [LookinObject instanceWithObject:view];

    // Check if the backing layer's delegate matches this view.
    // For special layers like NSVBCALayerHost (used by NSRemoteView), the
    // delegate is not the host view, so lks_hostView returns nil.
    // In that case, expose the backing layer as a separate child node
    // instead of merging it into this view node.
    CALayer *viewLayer = view.layer;
    // Direct delegate check — lks_hostView has an additional view.layer==self
    // guard that can fail for some standard AppKit views, so check delegate directly
    BOOL backingLayerOwnedByView = (viewLayer != nil && viewLayer.delegate == (id<CALayerDelegate>)view);
    if (viewLayer && backingLayerOwnedByView) {
        item.layerObject = [LookinObject instanceWithObject:viewLayer];
    }
    item.shouldCaptureImage = [LKSConfigManager shouldCaptureScreenshotOfView:view];

    item.eventHandlers = [LKS_EventHandlerMaker makeForView:view];
    item.backgroundColor = [view valueForKeyPath:@"backgroundColor"];

    LookinViewController* vc = [view lks_findHostViewController];
    if (vc) {
        item.hostViewControllerObject = [LookinObject instanceWithObject:vc];
    }

    // View is the source of truth: always recurse through view.subviews
    {
        NSMutableArray<LookinDisplayItem *> *allSubitems = [NSMutableArray array];
        NSMutableSet<CALayer *> *processedLayers = [NSMutableSet set];

        for (NSView *subview in view.subviews.copy) {
            LookinDisplayItem *subviewItem = [self _displayItemWithView:subview screenshots:hasScreenshots attrList:hasAttrList lowImageQuality:lowQuality readCustomInfo:readCustomInfo saveCustomSetter:saveCustomSetter];
            if (subviewItem) {
                [allSubitems addObject:subviewItem];
            }
            if (subview.layer) {
                [processedLayers addObject:subview.layer];
            }
        }

        // Expose backing layer as separate child when delegate doesn't match
        if (viewLayer && !backingLayerOwnedByView) {
            [processedLayers addObject:viewLayer];
            LookinDisplayItem *backingLayerItem = [self _displayItemWithLayer:viewLayer screenshots:hasScreenshots attrList:hasAttrList lowImageQuality:lowQuality readCustomInfo:readCustomInfo saveCustomSetter:saveCustomSetter];
            if (backingLayerItem) {
                [allSubitems addObject:backingLayerItem];
            }
        }

        // Add orphan sublayers (sublayers not associated with any subview)
        if (viewLayer && backingLayerOwnedByView) {
            for (CALayer *sublayer in viewLayer.sublayers.copy) {
                if (![processedLayers containsObject:sublayer]) {
                    LookinDisplayItem *sublayerItem = [self _displayItemWithLayer:sublayer screenshots:hasScreenshots attrList:hasAttrList lowImageQuality:lowQuality readCustomInfo:readCustomInfo saveCustomSetter:saveCustomSetter];
                    if (sublayerItem) {
                        [allSubitems addObject:sublayerItem];
                    }
                }
            }
        }

        if (allSubitems.count > 0) {
            item.subitems = allSubitems.copy;
        }
    }
    if (readCustomInfo) {
        NSArray<LookinDisplayItem *> *customSubitems;
        if (viewLayer) {
            // Always use initWithLayer: when view has a layer, regardless of delegate match.
            // LKS_CustomDisplayItemsMaker.initWithView: only handles layerless views.
            customSubitems = [[[LKS_CustomDisplayItemsMaker alloc] initWithLayer:viewLayer saveAttrSetter:saveCustomSetter] make];
        } else {
            customSubitems = [[[LKS_CustomDisplayItemsMaker alloc] initWithView:view saveAttrSetter:saveCustomSetter] make];
        }
        if (customSubitems.count > 0) {
            if (item.subitems) {
                item.subitems = [item.subitems arrayByAddingObjectsFromArray:customSubitems];
            } else {
                item.subitems = customSubitems;
            }
        }
    }

    return item;
}

+ (NSArray<LookinDisplayItem *> *)subitemsOfView:(NSView *)view {
    if (!view) {
        return @[];
    }

    CALayer *viewLayer = view.layer;
    BOOL backingLayerOwnedByView = (viewLayer != nil && viewLayer.delegate == (id<CALayerDelegate>)view);

    BOOL hasExposedBackingLayer = (viewLayer != nil && !backingLayerOwnedByView);
    BOOL hasOrphanSublayers = (viewLayer != nil && backingLayerOwnedByView && viewLayer.sublayers.count > 0);
    BOOL hasSubviews = view.subviews.count > 0;

    if (!hasSubviews && !hasExposedBackingLayer && !hasOrphanSublayers) {
        return @[];
    }

    [[LKS_TraceManager sharedInstance] reload];

    NSMutableArray<LookinDisplayItem *> *resultSubitems = [NSMutableArray array];
    NSMutableSet<CALayer *> *processedLayers = [NSMutableSet set];

    // Always recurse through view.subviews
    for (NSView *subview in view.subviews.copy) {
        LookinDisplayItem *subviewItem = [self _displayItemWithView:subview screenshots:NO attrList:NO lowImageQuality:NO readCustomInfo:YES saveCustomSetter:YES];
        if (subviewItem) {
            [resultSubitems addObject:subviewItem];
        }
        if (subview.layer) {
            [processedLayers addObject:subview.layer];
        }
    }

    // Expose backing layer as separate child when delegate doesn't match
    if (hasExposedBackingLayer) {
        [processedLayers addObject:viewLayer];
        LookinDisplayItem *backingLayerItem = [self _displayItemWithLayer:viewLayer screenshots:NO attrList:NO lowImageQuality:NO readCustomInfo:YES saveCustomSetter:YES];
        if (backingLayerItem) {
            [resultSubitems addObject:backingLayerItem];
        }
    }

    // Add orphan sublayers
    if (viewLayer && backingLayerOwnedByView) {
        for (CALayer *sublayer in viewLayer.sublayers.copy) {
            if (![processedLayers containsObject:sublayer]) {
                LookinDisplayItem *sublayerItem = [self _displayItemWithLayer:sublayer screenshots:NO attrList:NO lowImageQuality:NO readCustomInfo:YES saveCustomSetter:YES];
                if (sublayerItem) {
                    [resultSubitems addObject:sublayerItem];
                }
            }
        }
    }

    NSArray<LookinDisplayItem *> *customSubitems;
    if (viewLayer) {
        customSubitems = [[[LKS_CustomDisplayItemsMaker alloc] initWithLayer:viewLayer saveAttrSetter:YES] make];
    } else {
        customSubitems = [[[LKS_CustomDisplayItemsMaker alloc] initWithView:view saveAttrSetter:YES] make];
    }
    if (customSubitems.count > 0) {
        [resultSubitems addObjectsFromArray:customSubitems];
    }

    return resultSubitems;
}
#endif


+ (BOOL)validateFrame:(CGRect)frame {
    return !CGRectIsNull(frame) && !CGRectIsInfinite(frame) && ![self cgRectIsNaN:frame] && ![self cgRectIsInf:frame] && ![self cgRectIsUnreasonable:frame];
}

+ (BOOL)cgRectIsNaN:(CGRect)rect {
    return isnan(rect.origin.x) || isnan(rect.origin.y) || isnan(rect.size.width) || isnan(rect.size.height);
}

+ (BOOL)cgRectIsInf:(CGRect)rect {
    return isinf(rect.origin.x) || isinf(rect.origin.y) || isinf(rect.size.width) || isinf(rect.size.height);
}

+ (BOOL)cgRectIsUnreasonable:(CGRect)rect {
    return ABS(rect.origin.x) > 100000 || ABS(rect.origin.y) > 100000 || rect.size.width < 0 || rect.size.height < 0 || rect.size.width > 100000 || rect.size.height > 100000;
}

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
