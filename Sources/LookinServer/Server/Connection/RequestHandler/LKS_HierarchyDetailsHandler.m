#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION || TARGET_OS_MAC)
//
//  LKS_HierarchyDetailsHandler.m
//  LookinServer
//
//  Created by Li Kai on 2019/6/20.
//  https://lookin.work
//

#import "LKS_HierarchyDetailsHandler.h"
#import "LookinDisplayItemDetail.h"
#import "LookinStaticAsyncUpdateTask.h"
#import "NSObject+LookinServer.h"
#import "CALayer+LookinServer.h"
#import "LKS_AttrGroupsMaker.h"
#import "LKS_HierarchyDisplayItemsMaker.h"
#if TARGET_OS_OSX
#import "LKS_MultiplatformAdapter.h"
#endif

@interface LKS_HierarchyDetailsHandler ()

@property(nonatomic, assign) BOOL cancelled;

@end

@implementation LKS_HierarchyDetailsHandler

#if TARGET_OS_OSX
static NSArray<NSView *> *LKDetailHideVisibleSubviews(NSArray<NSView *> *subviews) {
    NSMutableArray<NSView *> *hiddenSubviews = [NSMutableArray array];
    for (NSView *subview in subviews.copy) {
        if (!subview.isHidden) {
            subview.hidden = YES;
            [hiddenSubviews addObject:subview];
        }
    }
    return hiddenSubviews.copy;
}

static void LKDetailRestoreHiddenSubviews(NSArray<NSView *> *subviews) {
    for (NSView *subview in subviews) {
        subview.hidden = NO;
    }
}

static NSImage *LKDetailSnapshotImageForView(NSView *view) {
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
#endif

- (void)startWithPackages:(NSArray<LookinStaticAsyncUpdateTasksPackage *> *)packages block:(LKS_HierarchyDetailsHandler_ProgressBlock)progressBlock finishedBlock:(LKS_HierarchyDetailsHandler_FinishBlock)finishBlock {
    if (!progressBlock || !finishBlock) {
        return;
    }
    if (!packages.count) {
        finishBlock();
        return;
    }

    for (LookinStaticAsyncUpdateTasksPackage *package in packages) {
        if (self.cancelled) {
            return;
        }
        NSMutableArray<LookinDisplayItemDetail *> *details = [NSMutableArray array];
        for (LookinStaticAsyncUpdateTask *task in package.tasks ?: @[]) {
            LookinDisplayItemDetail *detail = [LookinDisplayItemDetail new];
            detail.displayItemOid = task.oid;
            NSObject *targetObject = [NSObject lks_objectWithOid:task.oid];
#if TARGET_OS_OSX
            if ([targetObject isKindOfClass:NSView.class]) {
                NSView *view = (NSView *)targetObject;
                if (task.taskType == LookinStaticAsyncUpdateTaskTypeSoloScreenshot && view.subviews.count) {
                    NSArray<NSView *> *hiddenSubviews = LKDetailHideVisibleSubviews(view.subviews ?: @[]);
                    @try {
                        detail.soloScreenshot = LKDetailSnapshotImageForView(view);
                    } @finally {
                        LKDetailRestoreHiddenSubviews(hiddenSubviews);
                    }
                } else if (task.taskType == LookinStaticAsyncUpdateTaskTypeGroupScreenshot) {
                    detail.groupScreenshot = LKDetailSnapshotImageForView(view);
                }
                if (task.needBasisVisualInfo) {
                    detail.frameValue = [NSValue valueWithRect:view.frame];
                    detail.boundsValue = [NSValue valueWithRect:view.bounds];
                    detail.hiddenValue = @(view.hidden);
                    detail.alphaValue = @(view.layer ? view.layer.opacity : 1);
                }
                if (task.attrRequest != LookinDetailUpdateTaskAttrRequest_NotNeed) {
                    detail.attributesGroupList = [LKS_AttrGroupsMaker attrGroupsForView:view];
                }
            } else if ([targetObject isKindOfClass:NSWindow.class]) {
                NSWindow *window = (NSWindow *)targetObject;
                if (task.taskType == LookinStaticAsyncUpdateTaskTypeGroupScreenshot) {
                    detail.groupScreenshot = [LKS_MultiplatformAdapter screenshotForWindow:window];
                }
                if (task.needBasisVisualInfo) {
                    detail.frameValue = [NSValue valueWithRect:window.frame];
                    detail.boundsValue = [NSValue valueWithRect:window.contentView.bounds];
                    detail.hiddenValue = @(!window.visible);
                    detail.alphaValue = @(window.alphaValue);
                }
                if (task.attrRequest != LookinDetailUpdateTaskAttrRequest_NotNeed) {
                    detail.attributesGroupList = [LKS_AttrGroupsMaker attrGroupsForWindow:window];
                }
            } else
#endif
            if ([targetObject isKindOfClass:[CALayer class]]) {
                CALayer *layer = (CALayer *)targetObject;
                if (task.taskType == LookinStaticAsyncUpdateTaskTypeSoloScreenshot) {
                    detail.soloScreenshot = [layer lks_soloScreenshotWithLowQuality:NO];
                } else if (task.taskType == LookinStaticAsyncUpdateTaskTypeGroupScreenshot) {
                    detail.groupScreenshot = [layer lks_groupScreenshotWithLowQuality:NO];
                }
                if (task.needBasisVisualInfo) {
#if TARGET_OS_OSX
                    detail.frameValue = [NSValue valueWithRect:layer.frame];
                    detail.boundsValue = [NSValue valueWithRect:layer.bounds];
#else
                    detail.frameValue = [NSValue valueWithCGRect:layer.frame];
                    detail.boundsValue = [NSValue valueWithCGRect:layer.bounds];
#endif
                    detail.hiddenValue = @(layer.hidden);
                    detail.alphaValue = @(layer.opacity);
                }
                if (task.needSubitems) {
                    detail.subitems = [LKS_HierarchyDisplayItemsMaker subitemsOfLayer:layer];
                }
                if (task.attrRequest != LookinDetailUpdateTaskAttrRequest_NotNeed) {
                    detail.attributesGroupList = [LKS_AttrGroupsMaker attrGroupsForLayer:layer];
                }
            } else {
                detail.failureCode = -1;
            }
            [details addObject:detail];
        }
        progressBlock(details.copy);
    }
    if (!self.cancelled) {
        finishBlock();
    }
}

- (void)cancel {
    self.cancelled = YES;
}

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
