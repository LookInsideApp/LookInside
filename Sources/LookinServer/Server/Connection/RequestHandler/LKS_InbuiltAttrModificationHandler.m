#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION || TARGET_OS_MAC)
//
//  LKS_InbuiltAttrModificationHandler.m
//  LookinServer
//
//  Created by Li Kai on 2019/6/12.
//  https://lookin.work
//

#import "LKS_InbuiltAttrModificationHandler.h"
#import "LookinAttributeModification.h"
#import "LookinDisplayItemDetail.h"
#import "LookinStaticAsyncUpdateTask.h"
#import "LKS_AttrGroupsMaker.h"
#import "NSObject+LookinServer.h"
#import "CALayer+LookinServer.h"
#import "LookinServerDefines.h"

#if TARGET_OS_MAC
#import "Color+Lookin.h"

@implementation LKS_InbuiltAttrModificationHandler

+ (NSArray<LookinAttributesGroup *> *)_attrGroupsForReceiver:(NSObject *)receiver {
    if ([receiver isKindOfClass:[CALayer class]]) {
        return [LKS_AttrGroupsMaker attrGroupsForLayer:(CALayer *)receiver];
    }
    if ([receiver isKindOfClass:[NSView class]]) {
        return [LKS_AttrGroupsMaker attrGroupsForView:(NSView *)receiver];
    }
    if ([receiver isKindOfClass:[NSWindow class]]) {
        return [LKS_AttrGroupsMaker attrGroupsForWindow:(NSWindow *)receiver];
    }
    return nil;
}

+ (void)_fillBasisDetail:(LookinDisplayItemDetail *)detail withReceiver:(NSObject *)receiver {
    if ([receiver isKindOfClass:[CALayer class]]) {
        CALayer *layer = (CALayer *)receiver;
        detail.frameValue = [NSValue valueWithRect:layer.frame];
        detail.boundsValue = [NSValue valueWithRect:layer.bounds];
        detail.hiddenValue = @(layer.hidden);
        detail.alphaValue = @(layer.opacity);
    } else if ([receiver isKindOfClass:[NSView class]]) {
        NSView *view = (NSView *)receiver;
        detail.frameValue = [NSValue valueWithRect:view.frame];
        detail.boundsValue = [NSValue valueWithRect:view.bounds];
        detail.hiddenValue = @(view.hidden);
        detail.alphaValue = @(view.layer ? view.layer.opacity : 1);
    } else if ([receiver isKindOfClass:[NSWindow class]]) {
        NSWindow *window = (NSWindow *)receiver;
        detail.frameValue = [NSValue valueWithRect:window.frame];
        detail.boundsValue = [NSValue valueWithRect:window.contentView.bounds];
        detail.hiddenValue = @(!window.visible);
        detail.alphaValue = @(window.alphaValue);
    }
}

+ (void)handleModification:(LookinAttributeModification *)modification completion:(void (^)(LookinDisplayItemDetail *data, NSError *error))completion {
    if (!completion || ![modification isKindOfClass:[LookinAttributeModification class]]) {
        if (completion) {
            completion(nil, LookinErr_Inner);
        }
        return;
    }

    NSObject *receiver = [NSObject lks_objectWithOid:modification.targetOid];
    if (!receiver) {
        completion(nil, LookinErr_ObjNotFound);
        return;
    }
    if (![receiver respondsToSelector:modification.setterSelector]) {
        completion(nil, LookinErr_Inner);
        return;
    }

    NSMethodSignature *setterSignature = [receiver methodSignatureForSelector:modification.setterSelector];
    if (!setterSignature || setterSignature.numberOfArguments != 3) {
        completion(nil, LookinErr_Inner);
        return;
    }

    NSInvocation *setterInvocation = [NSInvocation invocationWithMethodSignature:setterSignature];
    setterInvocation.target = receiver;
    setterInvocation.selector = modification.setterSelector;

    switch (modification.attrType) {
        case LookinAttrTypeBOOL: {
            BOOL value = [(NSNumber *)modification.value boolValue];
            [setterInvocation setArgument:&value atIndex:2];
            break;
        }
        case LookinAttrTypeFloat: {
            float value = [(NSNumber *)modification.value floatValue];
            [setterInvocation setArgument:&value atIndex:2];
            break;
        }
        case LookinAttrTypeDouble: {
            double value = [(NSNumber *)modification.value doubleValue];
            [setterInvocation setArgument:&value atIndex:2];
            break;
        }
        case LookinAttrTypeCGPoint: {
            CGPoint value = [(NSValue *)modification.value pointValue];
            [setterInvocation setArgument:&value atIndex:2];
            break;
        }
        case LookinAttrTypeCGRect: {
            CGRect value = [(NSValue *)modification.value rectValue];
            [setterInvocation setArgument:&value atIndex:2];
            break;
        }
        case LookinAttrTypeUIColor: {
            NSColor *color = [NSColor lookin_colorFromRGBAComponents:modification.value];
            [setterInvocation setArgument:&color atIndex:2];
            [setterInvocation retainArguments];
            break;
        }
        default:
            completion(nil, LookinErr_Inner);
            return;
    }

    NSError *error = nil;
    @try {
        [setterInvocation invoke];
    } @catch (NSException *exception) {
        error = [NSError errorWithDomain:LookinErrorDomain code:LookinErrCode_Exception userInfo:@{
            NSLocalizedDescriptionKey: @"The modification may have failed.",
            NSLocalizedRecoverySuggestionErrorKey: exception.reason ?: @"Unknown exception."
        }];
    }

    LookinDisplayItemDetail *detail = [LookinDisplayItemDetail new];
    detail.displayItemOid = modification.targetOid;
    detail.attributesGroupList = [self _attrGroupsForReceiver:receiver];
    [self _fillBasisDetail:detail withReceiver:receiver];
    completion(detail, error);
}

+ (void)handlePatchWithTasks:(NSArray<LookinStaticAsyncUpdateTask *> *)tasks block:(void (^)(LookinDisplayItemDetail *data))block {
    if (!block) {
        return;
    }
    for (LookinStaticAsyncUpdateTask *task in tasks) {
        LookinDisplayItemDetail *detail = [LookinDisplayItemDetail new];
        detail.displayItemOid = task.oid;
        NSObject *receiver = [NSObject lks_objectWithOid:task.oid];
        if (!receiver) {
            block(detail);
            continue;
        }
        if ([receiver isKindOfClass:[CALayer class]] && task.taskType == LookinStaticAsyncUpdateTaskTypeSoloScreenshot) {
            CALayer *layer = (CALayer *)receiver;
            detail.soloScreenshot = [layer lks_soloScreenshotWithLowQuality:NO];
        } else if ([receiver isKindOfClass:[CALayer class]] && task.taskType == LookinStaticAsyncUpdateTaskTypeGroupScreenshot) {
            CALayer *layer = (CALayer *)receiver;
            detail.groupScreenshot = [layer lks_groupScreenshotWithLowQuality:NO];
        } else if ([receiver isKindOfClass:[NSView class]]) {
            NSView *view = (NSView *)receiver;
            if (task.taskType == LookinStaticAsyncUpdateTaskTypeSoloScreenshot && view.subviews.count > 0) {
                NSArray<NSView *> *hiddenSubviews = [view.subviews filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSView *subview, NSDictionary<NSString *, id> *bindings) {
                    return !subview.hidden;
                }]];
                [hiddenSubviews enumerateObjectsUsingBlock:^(NSView *subview, NSUInteger idx, BOOL *stop) {
                    subview.hidden = YES;
                }];
                @try {
                    NSBitmapImageRep *bitmapRep = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
                    [view cacheDisplayInRect:view.bounds toBitmapImageRep:bitmapRep];
                    NSImage *image = [[NSImage alloc] initWithSize:view.bounds.size];
                    [image addRepresentation:bitmapRep];
                    detail.soloScreenshot = image;
                } @finally {
                    [hiddenSubviews enumerateObjectsUsingBlock:^(NSView *subview, NSUInteger idx, BOOL *stop) {
                        subview.hidden = NO;
                    }];
                }
            } else if (task.taskType == LookinStaticAsyncUpdateTaskTypeGroupScreenshot) {
                NSBitmapImageRep *bitmapRep = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
                [view cacheDisplayInRect:view.bounds toBitmapImageRep:bitmapRep];
                NSImage *image = [[NSImage alloc] initWithSize:view.bounds.size];
                [image addRepresentation:bitmapRep];
                detail.groupScreenshot = image;
            }
        }
        block(detail);
    }
}

@end

#else

#import "UIColor+LookinServer.h"
#import "LKS_CustomAttrGroupsMaker.h"

@implementation LKS_InbuiltAttrModificationHandler

+ (void)handleModification:(LookinAttributeModification *)modification completion:(void (^)(LookinDisplayItemDetail *data, NSError *error))completion {
    completion(nil, LookinErr_Inner);
}

+ (void)handlePatchWithTasks:(NSArray<LookinStaticAsyncUpdateTask *> *)tasks block:(void (^)(LookinDisplayItemDetail *data))block {
    if (!block) {
        return;
    }
    for (LookinStaticAsyncUpdateTask *task in tasks) {
        LookinDisplayItemDetail *detail = [LookinDisplayItemDetail new];
        detail.displayItemOid = task.oid;
        block(detail);
    }
}

@end

#endif

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
