//
//  LookinDisplayItem+LookinClient.m
//  LookinClient
//
//  Created by likaimacbookhome on 2023/11/1.
//  Copyright © 2023 hughkli. All rights reserved.
//

#import "LookinDisplayItem+LookinClient.h"
#import "LookinIvarTrace.h"

enum {
    LKVisiblePixelSampleWidth = 16,
    LKVisiblePixelSampleHeight = 16,
    LKVisiblePixelBytesPerPixel = 4,
};

static CGFloat LKApproximateVisiblePixelRatio(NSImage *image) {
    if (!image || image.size.width <= 0 || image.size.height <= 0) {
        return 0;
    }

    CGRect proposedRect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGImageRef cgImage = [image CGImageForProposedRect:&proposedRect context:nil hints:nil];
    if (!cgImage) {
        return 0;
    }

    const size_t bytesPerRow = LKVisiblePixelSampleWidth * LKVisiblePixelBytesPerPixel;
    uint8_t pixels[LKVisiblePixelSampleWidth * LKVisiblePixelSampleHeight * LKVisiblePixelBytesPerPixel];
    memset(pixels, 0, sizeof(pixels));

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (!colorSpace) {
        return 0;
    }

    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 LKVisiblePixelSampleWidth,
                                                 LKVisiblePixelSampleHeight,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    if (!context) {
        return 0;
    }

    CGContextDrawImage(context, CGRectMake(0, 0, LKVisiblePixelSampleWidth, LKVisiblePixelSampleHeight), cgImage);
    CGContextRelease(context);

    NSUInteger visiblePixelCount = 0;
    const NSUInteger totalPixelCount = LKVisiblePixelSampleWidth * LKVisiblePixelSampleHeight;
    for (NSUInteger idx = 0; idx < totalPixelCount; idx++) {
        const uint8_t alpha = pixels[idx * LKVisiblePixelBytesPerPixel + 3];
        if (alpha > 12) {
            visiblePixelCount++;
        }
    }

    return (CGFloat)visiblePixelCount / (CGFloat)totalPixelCount;
}

static BOOL LKShouldFallbackToGroupScreenshot(NSImage *soloScreenshot, NSImage *groupScreenshot) {
    if (!groupScreenshot) {
        return NO;
    }
    if (!soloScreenshot) {
        return YES;
    }

    CGFloat soloVisibleRatio = LKApproximateVisiblePixelRatio(soloScreenshot);
    if (soloVisibleRatio >= 0.02) {
        return NO;
    }

    CGFloat groupVisibleRatio = LKApproximateVisiblePixelRatio(groupScreenshot);
    return groupVisibleRatio > MAX(0.05, soloVisibleRatio * 4.0);
}

@implementation LookinDisplayItem (LookinClient)

- (BOOL)_lk_usesAbsoluteRootCoordinates {
    LookinDisplayItem *rootItem = self;
    while (rootItem.superItem) {
        rootItem = rootItem.superItem;
    }

    LookinObject *rootObject = rootItem.windowObject ?: rootItem.viewObject ?: rootItem.layerObject;
    for (NSString *className in rootObject.classChainList ?: @[]) {
        if ([className hasPrefix:@"NSWindow"]) {
            return YES;
        }
    }
    return NO;
}

- (LookinDisplayItem *)_lk_rootItem {
    LookinDisplayItem *rootItem = self;
    while (rootItem.superItem) {
        rootItem = rootItem.superItem;
    }
    return rootItem;
}

- (unsigned long)bestObjectOidPreferView:(BOOL)preferView {
    // 始终优先使用 layerObject.oid，以匹配上游行为。
    // 上游服务端 detail handler 通过 CALayer OID 解析并截图，
    // 这是经过验证的可靠路径。
    if (self.layerObject.oid) {
        return self.layerObject.oid;
    }
    if (self.viewObject.oid) {
        return self.viewObject.oid;
    }
    return 0;
}

- (NSArray<NSNumber *> *)availableObjectOidsPreferView:(BOOL)preferView {
    NSMutableOrderedSet<NSNumber *> *oids = [NSMutableOrderedSet orderedSet];
    unsigned long preferredOid = [self bestObjectOidPreferView:preferView];
    if (preferredOid) {
        [oids addObject:@(preferredOid)];
    }
    if (self.viewObject.oid) {
        [oids addObject:@(self.viewObject.oid)];
    }
    if (self.layerObject.oid) {
        [oids addObject:@(self.layerObject.oid)];
    }
    return oids.array;
}

- (NSString *)title {
    if (self.customInfo) {
        return self.customInfo.title;
    } else if (self.customDisplayTitle.length > 0) {
        return self.customDisplayTitle;
    } else if (self.viewObject) {
        return self.viewObject.lk_simpleDemangledClassName;
    } else if (self.layerObject) {
        return self.layerObject.lk_simpleDemangledClassName;
    } else if (self.windowObject) {
        return self.windowObject.lk_simpleDemangledClassName;
    } else {
        return nil;
    }
}

- (NSString *)subtitle {
    if (self.customInfo) {
        return self.customInfo.subtitle;
    }
    
    NSString *text = self.hostViewControllerObject.lk_simpleDemangledClassName;
    if (text.length) {
        return [NSString stringWithFormat:@"%@.view", text];
    }
    
    LookinObject *representedObject = self.windowObject ? : self.viewObject ? : self.layerObject;
    if (representedObject.specialTrace.length) {
        return representedObject.specialTrace;
        
    }
    if (representedObject.ivarTraces.count) {
        NSArray<NSString *> *ivarNameList = [representedObject.ivarTraces lookin_map:^id(NSUInteger idx, LookinIvarTrace *value) {
            return value.ivarName;
        }];
        return [[[NSSet setWithArray:ivarNameList] allObjects] componentsJoinedByString:@"   "];
    }
    
    return nil;
}

- (BOOL)representedForSystemClass {
    return [self.title hasPrefix:@"UI"] || [self.title hasPrefix:@"CA"] || [self.title hasPrefix:@"_"] || [self.title hasPrefix:@"NS"];
}

- (NSImage *)appropriateScreenshot {
    if (self.isExpandable && self.isExpanded) {
        return self.soloScreenshot;
    }
    return self.groupScreenshot;
}

- (BOOL)usesGroupScreenshotFallbackInPreview {
    if (!(self.isExpandable && self.isExpanded)) {
        return NO;
    }
    // Window 根节点的 soloScreenshot 始终是近乎透明的（只有窗口边框）。
    // 这是预期行为——子视图负责渲染实际内容。不要对这些节点回退到
    // groupScreenshot，否则祖先抑制逻辑会导致所有子视图变为空白。
    if (self.windowObject && !self.layerObject && !self.viewObject) {
        return NO;
    }
    return LKShouldFallbackToGroupScreenshot(self.soloScreenshot, self.groupScreenshot);
}

- (BOOL)hasAncestorUsingGroupScreenshotFallbackInPreview {
    __block BOOL found = NO;
    [self enumerateAncestors:^(LookinDisplayItem *item, BOOL *stop) {
        if ([item usesGroupScreenshotFallbackInPreview]) {
            found = YES;
            *stop = YES;
        }
    }];
    return found;
}

- (BOOL)isUserCustom {
    return self.customInfo != nil;
}

- (BOOL)hasPreviewBoxAbility {
    if (!self.customInfo) {
        return YES;
    }
    if ([self.customInfo hasValidFrame]) {
        return YES;
    }
    return NO;
}

- (BOOL)hasValidFrameToRoot {
    if (self.customInfo) {
        return [self.customInfo hasValidFrame];
    }
    return [LKHelper validateFrame:self.frame];
}

//- (CGRect)calculateFrameToRoot {
//    if (self.customInfo) {
//        return [self.customInfo.frameInWindow rectValue];
//    }
//    if (!self.superItem) {
//        return self.frame;
//    }
//    CGRect superFrameToRoot = [self.superItem calculateFrameToRoot];
//    CGRect superBounds = self.superItem.bounds;
//    CGRect selfFrame = self.frame;
//    
//    CGFloat x = selfFrame.origin.x - superBounds.origin.x + superFrameToRoot.origin.x;
//    CGFloat y = selfFrame.origin.y - superBounds.origin.y + superFrameToRoot.origin.y;
//    
//    CGFloat width = selfFrame.size.width;
//    CGFloat height = selfFrame.size.height;
//    return CGRectMake(x, y, width, height);
//}

- (CGRect)calculateFrameToRoot {
    if (self.customInfo) {
        return [self.customInfo.frameInWindow rectValue];
    }
    if (!self.superItem) {
        return self.frame;
    }
    
    CGRect superFrameToRoot = [self.superItem calculateFrameToRoot];
    CGRect superBounds = self.superItem.bounds;
    CGRect selfFrame = self.frame;
    
    CGFloat x = selfFrame.origin.x - superBounds.origin.x + superFrameToRoot.origin.x;
    CGFloat y;
    
    if (self.superItem.isFlipped) {
        y = superFrameToRoot.origin.y + (superBounds.size.height - selfFrame.origin.y - selfFrame.size.height);
    } else {
        y = selfFrame.origin.y - superBounds.origin.y + superFrameToRoot.origin.y;
    }
    
    CGFloat width = selfFrame.size.width;
    CGFloat height = selfFrame.size.height;
    return CGRectMake(x, y, width, height);
}


- (BOOL)isMatchedWithSearchString:(NSString *)string {
    if (string.length == 0) {
        NSAssert(NO, @"");
        return NO;
    }
    NSString *searchString = string.lowercaseString;
    if ([self.title.lowercaseString containsString:searchString]) {
        return YES;
    }
    if ([self.subtitle.lowercaseString containsString:searchString]) {
        return YES;
    }
    if ([self.viewObject.memoryAddress containsString:searchString]) {
        return YES;
    }
    if ([self.layerObject.memoryAddress containsString:searchString]) {
        return YES;
    }
    if ([self.windowObject.memoryAddress containsString:searchString]) {
        return YES;
    }
    return NO;
}

- (void)enumerateSelfAndAncestors:(void (^)(LookinDisplayItem *, BOOL *))block {
    if (!block) {
        return;
    }
    LookinDisplayItem *item = self;
    while (item) {
        BOOL shouldStop = NO;
        block(item, &shouldStop);
        if (shouldStop) {
            break;
        }
        item = item.superItem;
    }
}

- (void)enumerateAncestors:(void (^)(LookinDisplayItem *, BOOL *))block {
    [self.superItem enumerateSelfAndAncestors:block];
}

- (void)enumerateSelfAndChildren:(void (^)(LookinDisplayItem *item))block {
    if (!block) {
        return;
    }
    
    block(self);
    [self.subitems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull subitem, NSUInteger idx, BOOL * _Nonnull stop) {
        [subitem enumerateSelfAndChildren:block];
    }];
}

- (BOOL)itemIsKindOfClassWithName:(NSString *)className {
    if (!className) {
        NSAssert(NO, @"");
        return NO;
    }
    return [self itemIsKindOfClassesWithNames:[NSSet setWithObject:className]];
}

- (BOOL)itemIsKindOfClassesWithNames:(NSSet<NSString *> *)targetClassNames {
    if (!targetClassNames.count) {
        return NO;
    }
    LookinObject *selfObj = self.windowObject ? : self.viewObject ? : self.layerObject;
    if (!selfObj) {
        return NO;
    }
    
    __block BOOL boolValue = NO;
    [targetClassNames enumerateObjectsUsingBlock:^(NSString * _Nonnull targetClassName, BOOL * _Nonnull stop_outer) {
        [selfObj.classChainList enumerateObjectsUsingBlock:^(NSString * _Nonnull selfClass, NSUInteger idx, BOOL * _Nonnull stop_inner) {
            NSString *nonPrefixSelfClass = [selfClass componentsSeparatedByString:@"."].lastObject;
            if ([nonPrefixSelfClass isEqualToString:targetClassName]) {
                boolValue = YES;
                *stop_inner = YES;
            }
        }];
        if (boolValue) {
            *stop_outer = YES;
        }
    }];
    
    return boolValue;
}

@end
