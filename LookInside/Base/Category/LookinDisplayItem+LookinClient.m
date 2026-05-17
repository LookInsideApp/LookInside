//
//  LookinDisplayItem+LookinClient.m
//  LookinClient
//
//  Created by likaimacbookhome on 2023/11/1.
//  Copyright © 2023 hughkli. All rights reserved.
//

#import "LookinDisplayItem+LookinClient.h"
#import "LookinIvarTrace.h"
#import "LookinAttributesGroup.h"
#import "LookinAttributesSection.h"
#import "LookinAttribute.h"
#import "LookInside-Swift.h"
#include <stdint.h>

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
                                                 (CGBitmapInfo)kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
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

static BOOL LKClassNameLooksLikeSwiftUISupport(NSString *className) {
    if (className.length == 0) {
        return NO;
    }

    static NSArray<NSString *> *markers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        markers = @[
            @"SwiftUI",
            @"HostingView",
            @"UIHosting",
            @"NSHosting",
            @"ViewRendererHost",
            @"PlatformViewHost",
            @"_UIHosting",
            @"_NSHosting",
        ];
    });

    for (NSString *marker in markers) {
        if ([className containsString:marker]) {
            return YES;
        }
    }
    return NO;
}

static BOOL LKObjectLooksLikeSwiftUISupport(LookinObject *object) {
    if (!object) {
        return NO;
    }

    if (LKClassNameLooksLikeSwiftUISupport(object.rawClassName)) {
        return YES;
    }

    for (NSString *className in object.classChainList) {
        if (LKClassNameLooksLikeSwiftUISupport(className)) {
            return YES;
        }
    }
    return NO;
}

static NSArray<LookinAttributesGroup *> *LKAllAttributeGroupsForItem(LookinDisplayItem *item) {
    NSMutableArray<LookinAttributesGroup *> *groups = [NSMutableArray array];
    if (item.attributesGroupList.count) {
        [groups addObjectsFromArray:item.attributesGroupList];
    }
    if (item.customAttrGroupList.count) {
        [groups addObjectsFromArray:item.customAttrGroupList];
    }
    return groups;
}

static void LKEnumerateAttributesInGroup(LookinAttributesGroup *group, void (^block)(LookinAttribute *attribute)) {
    if (!block) {
        return;
    }
    [group.attrSections enumerateObjectsUsingBlock:^(LookinAttributesSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop) {
        [section.attributes enumerateObjectsUsingBlock:^(LookinAttribute * _Nonnull attribute, NSUInteger idx, BOOL * _Nonnull stop) {
            block(attribute);
        }];
    }];
}

static void LKAddUniqueObject(NSMutableArray *array, id object) {
    if (object && ![array containsObject:object]) {
        [array addObject:object];
    }
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
    if (self.windowObject.oid) {
        return self.windowObject.oid;
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
    NSString *baseTitle = nil;
    if (self.customInfo) {
        baseTitle = self.customInfo.title;
    } else if (self.customDisplayTitle.length > 0) {
        baseTitle = self.customDisplayTitle;
    } else if (self.viewObject) {
        baseTitle = self.viewObject.lk_simpleDemangledClassName;
    } else if (self.layerObject) {
        baseTitle = self.layerObject.lk_simpleDemangledClassName;
    } else if (self.windowObject) {
        baseTitle = self.windowObject.lk_simpleDemangledClassName;
    }
    return [[LKPrivateDiscriminatorStore shared] displayTitleForDisplayItem:self fallback:baseTitle];
}

- (NSString *)subtitle {
    if (self.customInfo) {
        return self.customInfo.subtitle;
    }
    
    NSString *windowControllerName = self.hostWindowControllerObject.lk_simpleDemangledClassName;
    if (windowControllerName.length) {
        return [NSString stringWithFormat:@"%@.window", windowControllerName];
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

- (BOOL)lk_isSwiftUISupportRelated {
    if (LKObjectLooksLikeSwiftUISupport(self.viewObject) ||
        LKObjectLooksLikeSwiftUISupport(self.layerObject) ||
        LKObjectLooksLikeSwiftUISupport(self.windowObject)) {
        return YES;
    }

    if (LKClassNameLooksLikeSwiftUISupport(self.title) ||
        LKClassNameLooksLikeSwiftUISupport(self.subtitle)) {
        return YES;
    }
    return NO;
}

- (NSArray<NSString *> *)lk_swiftUIBackingLayerMemoryAddresses {
    NSMutableArray<NSString *> *addresses = [NSMutableArray array];
    for (LookinAttributesGroup *group in LKAllAttributeGroupsForItem(self)) {
        if (![group.userCustomTitle isEqualToString:@"SwiftUI Layers"]) {
            continue;
        }
        LKEnumerateAttributesInGroup(group, ^(LookinAttribute *attribute) {
            if (![attribute.displayTitle hasSuffix:@"Backed By"] || ![attribute.value isKindOfClass:NSString.class]) {
                return;
            }
            NSString *address = [LookinDisplayItem lk_memoryAddressInObjectDescription:attribute.value];
            LKAddUniqueObject(addresses, address);
        });
    }
    return addresses;
}

- (NSArray<NSNumber *> *)lk_swiftUIBackingDisplayListIDs {
    NSMutableArray<NSNumber *> *displayListIDs = [NSMutableArray array];
    for (LookinAttributesGroup *group in LKAllAttributeGroupsForItem(self)) {
        BOOL isLayersGroup = [group.userCustomTitle isEqualToString:@"SwiftUI Layers"];
        BOOL isDisplayListGroup = [group.userCustomTitle isEqualToString:@"SwiftUI Display List"];
        if (!isLayersGroup && !isDisplayListGroup) {
            continue;
        }
        LKEnumerateAttributesInGroup(group, ^(LookinAttribute *attribute) {
            if (![attribute.value isKindOfClass:NSString.class]) {
                return;
            }
            BOOL isLayerDisplayListID = isLayersGroup && [attribute.displayTitle hasSuffix:@"Display List ID"];
            BOOL isIdentityIDs = isDisplayListGroup && [attribute.displayTitle isEqualToString:@"Identity IDs"];
            if (!isLayerDisplayListID && !isIdentityIDs) {
                return;
            }
            for (NSNumber *displayListID in [LookinDisplayItem lk_validSwiftUIDisplayListIDsInString:attribute.value]) {
                LKAddUniqueObject(displayListIDs, displayListID);
            }
        });
    }
    return displayListIDs;
}

- (NSNumber *)lk_swiftUILayerDisplayListID {
    if (!self.layerObject) {
        return nil;
    }
    for (LookinAttributesGroup *group in LKAllAttributeGroupsForItem(self)) {
        if (![group.userCustomTitle isEqualToString:@"SwiftUI"]) {
            continue;
        }
        __block NSNumber *result = nil;
        LKEnumerateAttributesInGroup(group, ^(LookinAttribute *attribute) {
            if (result || ![attribute.displayTitle isEqualToString:@"Display List ID"] || ![attribute.value isKindOfClass:NSString.class]) {
                return;
            }
            result = [LookinDisplayItem lk_validSwiftUIDisplayListIDsInString:attribute.value].firstObject;
        });
        if (result) {
            return result;
        }
    }
    return nil;
}

- (NSArray<NSString *> *)lk_swiftUILayerSourceTypeNames {
    NSMutableArray<NSString *> *sourceNames = [NSMutableArray array];
    for (LookinAttributesGroup *group in LKAllAttributeGroupsForItem(self)) {
        if (![group.userCustomTitle isEqualToString:@"SwiftUI"]) {
            continue;
        }
        LKEnumerateAttributesInGroup(group, ^(LookinAttribute *attribute) {
            if (([attribute.displayTitle isEqualToString:@"Source"] || [attribute.displayTitle isEqualToString:@"Full Source"]) &&
                [attribute.value isKindOfClass:NSString.class]) {
                LKAddUniqueObject(sourceNames, attribute.value);
            }
        });
    }
    return sourceNames;
}

- (NSArray<NSString *> *)lk_swiftUITypeNames {
    NSMutableArray<NSString *> *typeNames = [NSMutableArray array];
    LKAddUniqueObject(typeNames, self.customInfo.title);
    for (LookinAttributesGroup *group in LKAllAttributeGroupsForItem(self)) {
        if (![group.userCustomTitle isEqualToString:@"SwiftUI Type"]) {
            continue;
        }
        LKEnumerateAttributesInGroup(group, ^(LookinAttribute *attribute) {
            if (([attribute.displayTitle isEqualToString:@"Type"] || [attribute.displayTitle isEqualToString:@"Full Type"]) &&
                [attribute.value isKindOfClass:NSString.class]) {
                LKAddUniqueObject(typeNames, attribute.value);
            }
        });
    }
    return typeNames;
}

+ (NSArray<NSNumber *> *)lk_validSwiftUIDisplayListIDsInString:(NSString *)string {
    if (![string isKindOfClass:NSString.class] || string.length == 0) {
        return @[];
    }
    NSMutableArray<NSNumber *> *result = [NSMutableArray array];
    NSCharacterSet *separatorSet = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    NSArray<NSString *> *tokens = [string componentsSeparatedByCharactersInSet:separatorSet];
    for (NSString *rawToken in tokens) {
        if (rawToken.length == 0) {
            continue;
        }

        NSString *token = rawToken.lowercaseString;
        unsigned long long value = 0;
        NSScanner *scanner = nil;
        if ([token hasPrefix:@"0x"]) {
            scanner = [NSScanner scannerWithString:[token substringFromIndex:2]];
            if (![scanner scanHexLongLong:&value] || !scanner.atEnd) {
                continue;
            }
        } else {
            scanner = [NSScanner scannerWithString:token];
            if (![scanner scanUnsignedLongLong:&value] || !scanner.atEnd) {
                continue;
            }
        }

        if (value == 0 || value == UINT32_MAX || value > UINT32_MAX) {
            continue;
        }
        LKAddUniqueObject(result, @(value));
    }
    return result;
}

+ (NSString *)lk_memoryAddressInObjectDescription:(NSString *)description {
    if (![description isKindOfClass:NSString.class] || description.length == 0) {
        return nil;
    }
    NSRange prefixRange = [description rangeOfString:@"0x" options:NSCaseInsensitiveSearch];
    if (prefixRange.location == NSNotFound) {
        return nil;
    }

    NSUInteger start = prefixRange.location;
    NSUInteger idx = NSMaxRange(prefixRange);
    NSCharacterSet *hexSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];
    while (idx < description.length) {
        unichar ch = [description characterAtIndex:idx];
        if (![hexSet characterIsMember:ch]) {
            break;
        }
        idx++;
    }
    if (idx <= NSMaxRange(prefixRange)) {
        return nil;
    }
    return [[description substringWithRange:NSMakeRange(start, idx - start)] lowercaseString];
}

@end
