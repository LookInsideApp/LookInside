#if defined(SHOULD_COMPILE_LOOKIN_SERVER)
//
//  LKS_HierarchyDetailsHandler.m
//  LookinServer
//
//  Created by Li Kai on 2019/6/20.
//  https://lookin.work
//

#import "LKS_HierarchyDetailsHandler.h"
#import "LookinDisplayItemDetail.h"
#import "LKS_AttrGroupsMaker.h"
#import "LookinStaticAsyncUpdateTask.h"
#import "LKS_ConnectionManager.h"
#import "LookinServerDefines.h"
#import "LKS_CustomAttrGroupsMaker.h"
#import "LKS_HierarchyDisplayItemsMaker.h"
#import "UIView+LookinServer.h"
#import "NSValue+Lookin.h"
#import "NSObject+LookinServer.h"
#import "CALayer+LookinServer.h"
#if TARGET_OS_IPHONE
#import "UIWindowScene+LookinServer.h"
#endif
@interface LKS_HierarchyDetailsHandler ()

@property(nonatomic, strong) NSMutableArray<LookinStaticAsyncUpdateTasksPackage *> *taskPackages;
/// 标识哪些 oid 已经拉取过 attrGroups 了
@property(nonatomic, strong) NSMutableSet<NSNumber *> *attrGroupsSyncedOids;

@property(nonatomic, copy) LKS_HierarchyDetailsHandler_ProgressBlock progressBlock;
@property(nonatomic, copy) LKS_HierarchyDetailsHandler_FinishBlock finishBlock;

@end

@implementation LKS_HierarchyDetailsHandler

- (instancetype)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleConnectionDidEnd:) name:LKS_ConnectionDidEndNotificationName object:nil];

        self.attrGroupsSyncedOids = [NSMutableSet set];
    }
    return self;
}

- (void)startWithPackages:(NSArray<LookinStaticAsyncUpdateTasksPackage *> *)packages block:(LKS_HierarchyDetailsHandler_ProgressBlock)progressBlock finishedBlock:(LKS_HierarchyDetailsHandler_FinishBlock)finishBlock {
    if (!progressBlock || !finishBlock) {
        NSAssert(NO, @"");
        return;
    }
    if (!packages.count) {
        finishBlock();
        return;
    }
    self.taskPackages = [packages mutableCopy];
    self.progressBlock = progressBlock;
    self.finishBlock = finishBlock;

    [LookinView lks_rebuildGlobalInvolvedRawConstraints];

    [self _dequeueAndHandlePackage];
}

- (void)cancel {
    [self.taskPackages removeAllObjects];
}

- (void)_dequeueAndHandlePackage {
    dispatch_async(dispatch_get_main_queue(), ^{
        LookinStaticAsyncUpdateTasksPackage *package = self.taskPackages.firstObject;
        if (!package) {
            self.finishBlock();
            return;
        }
        NSArray<LookinDisplayItemDetail *> *details = [package.tasks lookin_map:^id(NSUInteger idx, LookinStaticAsyncUpdateTask *task) {
            LookinDisplayItemDetail *itemDetail = [LookinDisplayItemDetail new];
            itemDetail.displayItemOid = task.oid;

            id object = [NSObject lks_objectWithOid:task.oid];

#if TARGET_OS_OSX
            // 处理所有 NSView 对象（包括 layer-backed 的 SwiftUI 视图）
            if ([object isKindOfClass:[NSView class]]) {
                NSView *view = (NSView *)object;
                // 对于 layer-backed 视图，委托给 CALayer 截图路径，
                // 该路径使用 renderInContext:（在现代 macOS 上有效）。
                // cacheDisplayInRect: 只能捕获 drawRect: 的内容，
                // 对 layer-backed 视图会产生空白图片。
                if (view.layer) {
                    CALayer *layer = view.layer;
                    if (task.taskType == LookinStaticAsyncUpdateTaskTypeSoloScreenshot) {
                        itemDetail.soloScreenshot = [layer lks_soloScreenshotWithLowQuality:NO];
                    } else if (task.taskType == LookinStaticAsyncUpdateTaskTypeGroupScreenshot) {
                        itemDetail.groupScreenshot = [layer lks_groupScreenshotWithLowQuality:NO];
                    }
                } else {
                    // 非 layer-backed 视图：使用 cacheDisplayInRect:
                if (task.taskType == LookinStaticAsyncUpdateTaskTypeSoloScreenshot && view.subviews.count) {
                        NSMutableArray<NSView *> *hiddenSubviews = [NSMutableArray array];
                        for (NSView *subview in view.subviews.copy) {
                            if (!subview.isHidden) {
                                subview.hidden = YES;
                                [hiddenSubviews addObject:subview];
                            }
                        }
                    @try {
                            itemDetail.soloScreenshot = [view lks_groupScreenshotWithLowQuality:NO];
                    } @finally {
                            for (NSView *subview in hiddenSubviews) {
                                subview.hidden = NO;
                            }
                    }
                } else if (task.taskType == LookinStaticAsyncUpdateTaskTypeGroupScreenshot) {
                        itemDetail.groupScreenshot = [view lks_groupScreenshotWithLowQuality:NO];
    }
}

                BOOL shouldMakeAttr = [self queryIfShouldMakeAttrsFromTask:task];
                if (shouldMakeAttr) {
                    itemDetail.attributesGroupList = [LKS_AttrGroupsMaker attrGroupsForView:view];

                    NSString *version = task.clientReadableVersion;
                    if (version.length > 0 && [version lookin_numbericOSVersion] >= 10004) {
                        LKS_CustomAttrGroupsMaker *maker = [[LKS_CustomAttrGroupsMaker alloc] initWithView:view];
                        [maker execute];
                        itemDetail.customAttrGroupList = [maker getGroups];
                        itemDetail.customDisplayTitle = [maker getCustomDisplayTitle];
                        itemDetail.danceUISource = [maker getDanceUISource];
                    }
                    [self.attrGroupsSyncedOids addObject:@(task.oid)];
                }
                if (task.needBasisVisualInfo) {
                    itemDetail.frameValue = [NSValue valueWithCGRect:view.frame];
                    itemDetail.boundsValue = [NSValue valueWithCGRect:view.bounds];
                    itemDetail.hiddenValue = @(view.hidden);
                    itemDetail.alphaValue = @(view.layer ? view.layer.opacity : 1);
                }
                if (task.needSubitems) {
                    itemDetail.subitems = [LKS_HierarchyDisplayItemsMaker subitemsOfView:view];
                }
                return itemDetail;

            } else if ([object isKindOfClass:[NSWindow class]]) {
                NSWindow *window = (NSWindow *)object;
                if (task.taskType == LookinStaticAsyncUpdateTaskTypeGroupScreenshot) {
                    CGImageRef cgImage = CGWindowListCreateImage(CGRectZero,
                        kCGWindowListOptionIncludingWindow,
                        (int)window.windowNumber,
                        kCGWindowImageBoundsIgnoreFraming);
                    if (cgImage) {
                        itemDetail.groupScreenshot = [[NSImage alloc] initWithCGImage:cgImage size:window.frame.size];
                        CGImageRelease(cgImage);
                    }
                }
                BOOL shouldMakeAttr = [self queryIfShouldMakeAttrsFromTask:task];
                if (shouldMakeAttr) {
                    itemDetail.attributesGroupList = [LKS_AttrGroupsMaker attrGroupsForWindow:window];
                    [self.attrGroupsSyncedOids addObject:@(task.oid)];
                }
                if (task.needBasisVisualInfo) {
                    CGRect windowBounds = window.frame;
                    windowBounds.origin = CGPointZero;
                    itemDetail.frameValue = [NSValue valueWithCGRect:windowBounds];
                    itemDetail.boundsValue = [NSValue valueWithCGRect:windowBounds];
                    itemDetail.hiddenValue = @(!window.visible);
                    itemDetail.alphaValue = @(window.alphaValue);
                }
                return itemDetail;
            }
#endif
#if TARGET_OS_IPHONE
            if (@available(iOS 13.0, *)) {
                if ([object isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)object;
                    // UIWindowScene has no screenshots
                    BOOL shouldMakeAttr = [self queryIfShouldMakeAttrsFromTask:task];
                    if (shouldMakeAttr) {
                        itemDetail.attributesGroupList = [LKS_AttrGroupsMaker attrGroupsForWindowScene:windowScene];
                        [self.attrGroupsSyncedOids addObject:@(task.oid)];
                    }
                    if (task.needBasisVisualInfo) {
                        itemDetail.hiddenValue = @(NO);
                        itemDetail.alphaValue = @(1.0);
                    }
                    return itemDetail;
                }
            }
#endif
            if (!object || ![object isKindOfClass:[CALayer class]]) {
                itemDetail.failureCode = -1;
                return itemDetail;
            }
            CALayer *layer = object;

            if (task.taskType == LookinStaticAsyncUpdateTaskTypeSoloScreenshot) {
                LookinImage *image = [layer lks_soloScreenshotWithLowQuality:NO];
                itemDetail.soloScreenshot = image;
            } else if (task.taskType == LookinStaticAsyncUpdateTaskTypeGroupScreenshot) {
                LookinImage *image = [layer lks_groupScreenshotWithLowQuality:NO];
                itemDetail.groupScreenshot = image;
            }

            BOOL shouldMakeAttr = [self queryIfShouldMakeAttrsFromTask:task];
            if (shouldMakeAttr) {
                itemDetail.attributesGroupList = [LKS_AttrGroupsMaker attrGroupsForLayer:layer];

                NSString *version = task.clientReadableVersion;
                if (version.length > 0 && [version lookin_numbericOSVersion] >= 10004) {
                    LKS_CustomAttrGroupsMaker *maker = [[LKS_CustomAttrGroupsMaker alloc] initWithLayer:layer];
                    [maker execute];
                    itemDetail.customAttrGroupList = [maker getGroups];
                    itemDetail.customDisplayTitle = [maker getCustomDisplayTitle];
                    itemDetail.danceUISource = [maker getDanceUISource];
                }
                [self.attrGroupsSyncedOids addObject:@(task.oid)];
            }
            if (task.needBasisVisualInfo) {
                itemDetail.frameValue = [NSValue valueWithCGRect:layer.frame];
                itemDetail.boundsValue = [NSValue valueWithCGRect:layer.bounds];
                itemDetail.hiddenValue = [NSNumber numberWithBool:layer.isHidden];
                itemDetail.alphaValue = @(layer.opacity);
            }

            if (task.needSubitems) {
                itemDetail.subitems = [LKS_HierarchyDisplayItemsMaker subitemsOfLayer:layer];
            }

            return itemDetail;
        }];
        self.progressBlock(details);

        [self.taskPackages removeObjectAtIndex:0];
        [self _dequeueAndHandlePackage];
    });
}

- (BOOL)queryIfShouldMakeAttrsFromTask:(LookinStaticAsyncUpdateTask *)task {
    switch (task.attrRequest) {
        case LookinDetailUpdateTaskAttrRequest_Automatic: {
            BOOL alreadyMadeBefore = [self.attrGroupsSyncedOids containsObject:@(task.oid)];
            return !alreadyMadeBefore;
        }
        case LookinDetailUpdateTaskAttrRequest_Need:
            return YES;
        case LookinDetailUpdateTaskAttrRequest_NotNeed:
            return NO;
    }
    NSAssert(NO, @"");
    return YES;
}

- (void)_handleConnectionDidEnd:(id)obj {
    [self cancel];
}

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
