#ifdef SHOULD_COMPILE_LOOKIN_SERVER

//
//  LookinDisplayItem.m
//  qmuidemo
//
//  Created by Li Kai on 2018/11/15.
//  Copyright © 2018 QMUI Team. All rights reserved.
//

#import "LookinDisplayItem.h"
#import "LookinAttributesGroup.h"
#import "LookinAttributesSection.h"
#import "LookinAttribute.h"
#import "LookinEventHandler.h"
#import "LookinIvarTrace.h"
#import "Color+Lookin.h"
#import "NSArray+Lookin.h"
#import "NSObject+Lookin.h"
#import "LookinDashboardBlueprint.h"

#if TARGET_OS_IPHONE
#import "UIColor+LookinServer.h"
#import "UIImage+LookinServer.h"
#elif TARGET_OS_OSX
#endif

@interface LookinDisplayItem ()

@property(nonatomic, assign, readwrite) CGRect frameToRoot;
@property(nonatomic, assign, readwrite) BOOL inNoPreviewHierarchy;
@property(nonatomic, assign) NSInteger indentLevel;
@property(nonatomic, assign, readwrite) BOOL isExpandable;
@property(nonatomic, assign, readwrite) BOOL inHiddenHierarchy;
@property(nonatomic, assign, readwrite) BOOL displayingInHierarchy;

@end

@interface LookinDisplayItem (LK_KuGouHierarchyCollapse)

+ (id)lk_kg_runtimePreferenceManager;
+ (NSNumber *)lk_kg_boolFromEnvForKey:(NSString *)key;
+ (BOOL)lk_kg_shouldShowAllPages;
+ (BOOL)lk_kg_shouldShowDrawer;
+ (NSArray<LookinDisplayItem *> *)lk_kg_filterSubitems:(NSArray<LookinDisplayItem *> *)subitems;
+ (NSArray<LookinDisplayItem *> *)lk_kg_filterContentContainerSubitems:(NSArray<LookinDisplayItem *> *)subitems;
+ (NSArray<LookinDisplayItem *> *)lk_kg_filterMainBackScaleViewSubitems:(NSArray<LookinDisplayItem *> *)subitems;
+ (NSArray<LookinDisplayItem *> *)lk_kg_filterMainBackViewSubitems:(NSArray<LookinDisplayItem *> *)subitems;
+ (NSArray<LookinDisplayItem *> *)lk_kg_filterContentViewSubitems:(NSArray<LookinDisplayItem *> *)subitems;

@end

@implementation LookinDisplayItem

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone {
    LookinDisplayItem *newDisplayItem = [[LookinDisplayItem allocWithZone:zone] init];
    newDisplayItem.subitems = [self.subitems lookin_map:^id(NSUInteger idx, LookinDisplayItem *value) {
        return value.copy;
    }];
    newDisplayItem.customInfo = self.customInfo.copy;
    newDisplayItem.isHidden = self.isHidden;
    newDisplayItem.alpha = self.alpha;
    newDisplayItem.frame = self.frame;
    newDisplayItem.bounds = self.bounds;
#if TARGET_OS_OSX
    newDisplayItem.flipped = self.isFlipped;
#endif
    newDisplayItem.soloScreenshot = self.soloScreenshot;
    newDisplayItem.groupScreenshot = self.groupScreenshot;
    newDisplayItem.viewObject = self.viewObject.copy;
    newDisplayItem.layerObject = self.layerObject.copy;
    newDisplayItem.windowObject = self.windowObject.copy;
    newDisplayItem.hostViewControllerObject = self.hostViewControllerObject.copy;
    newDisplayItem.hostWindowControllerObject = self.hostWindowControllerObject.copy;
    newDisplayItem.attributesGroupList = [self.attributesGroupList lookin_map:^id(NSUInteger idx, LookinAttributesGroup *value) {
        return value.copy;
    }];
    newDisplayItem.customAttrGroupList = [self.customAttrGroupList lookin_map:^id(NSUInteger idx, LookinAttributesGroup *value) {
        return value.copy;
    }];
    newDisplayItem.eventHandlers = [self.eventHandlers lookin_map:^id(NSUInteger idx, LookinEventHandler *value) {
        return value.copy;
    }];
    newDisplayItem.shouldCaptureImage = self.shouldCaptureImage;
    newDisplayItem.representedAsKeyWindow = self.representedAsKeyWindow;
    newDisplayItem.customDisplayTitle = self.customDisplayTitle;
    newDisplayItem.danceuiSource = self.danceuiSource;
    [newDisplayItem _updateDisplayingInHierarchyProperty];
    return newDisplayItem;
}
#pragma mark - <NSCoding>

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.customInfo forKey:@"customInfo"];
    [aCoder encodeObject:self.subitems forKey:@"subitems"];
    [aCoder encodeBool:self.isHidden forKey:@"hidden"];
    [aCoder encodeFloat:self.alpha forKey:@"alpha"];
#if TARGET_OS_OSX
    [aCoder encodeBool:self.isFlipped forKey:@"isFlipped"];
#endif
    [aCoder encodeObject:self.viewObject forKey:@"viewObject"];
    [aCoder encodeObject:self.layerObject forKey:@"layerObject"];
    [aCoder encodeObject:self.windowObject forKey:@"windowObject"];
    [aCoder encodeObject:self.hostViewControllerObject forKey:@"hostViewControllerObject"];
    [aCoder encodeObject:self.hostWindowControllerObject forKey:@"hostWindowControllerObject"];
    [aCoder encodeObject:self.attributesGroupList forKey:@"attributesGroupList"];
    [aCoder encodeObject:self.customAttrGroupList forKey:@"customAttrGroupList"];
    [aCoder encodeBool:self.representedAsKeyWindow forKey:@"representedAsKeyWindow"];
    [aCoder encodeObject:self.eventHandlers forKey:@"eventHandlers"];
    [aCoder encodeBool:self.shouldCaptureImage forKey:@"shouldCaptureImage"];
    if (self.screenshotEncodeType == LookinDisplayItemImageEncodeTypeNSData) {
        [aCoder encodeObject:[self.soloScreenshot lookin_encodedObjectWithType:LookinCodingValueTypeImage] forKey:@"soloScreenshot"];
        [aCoder encodeObject:[self.groupScreenshot lookin_encodedObjectWithType:LookinCodingValueTypeImage] forKey:@"groupScreenshot"];
    } else if (self.screenshotEncodeType == LookinDisplayItemImageEncodeTypeImage) {
        [aCoder encodeObject:self.soloScreenshot forKey:@"soloScreenshot"];
        [aCoder encodeObject:self.groupScreenshot forKey:@"groupScreenshot"];
    }
    [aCoder encodeObject:self.customDisplayTitle forKey:@"customDisplayTitle"];
    [aCoder encodeObject:self.danceuiSource forKey:@"danceuiSource"];
#if TARGET_OS_IPHONE
    [aCoder encodeCGRect:self.frame forKey:@"frame"];
    [aCoder encodeCGRect:self.bounds forKey:@"bounds"];
    [aCoder encodeObject:self.backgroundColor.lks_rgbaComponents forKey:@"backgroundColor"];
    
#elif TARGET_OS_OSX
    [aCoder encodeRect:self.frame forKey:@"frame"];
    [aCoder encodeRect:self.bounds forKey:@"bounds"];
    [aCoder encodeObject:self.backgroundColor.lookin_rgbaComponents forKey:@"backgroundColor"];
#endif
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.customInfo = [aDecoder decodeObjectForKey:@"customInfo"];
        self.subitems = [aDecoder decodeObjectForKey:@"subitems"];
        self.isHidden = [aDecoder decodeBoolForKey:@"hidden"];
        self.alpha = [aDecoder decodeFloatForKey:@"alpha"];
#if TARGET_OS_OSX
        self.flipped = [aDecoder decodeBoolForKey:@"isFlipped"];
#endif
        self.windowObject = [aDecoder decodeObjectForKey:@"windowObject"];
        self.viewObject = [aDecoder decodeObjectForKey:@"viewObject"];
        self.layerObject = [aDecoder decodeObjectForKey:@"layerObject"];
        self.hostViewControllerObject = [aDecoder decodeObjectForKey:@"hostViewControllerObject"];
        self.hostWindowControllerObject = [aDecoder decodeObjectForKey:@"hostWindowControllerObject"];
        self.attributesGroupList = [aDecoder decodeObjectForKey:@"attributesGroupList"];
        self.customAttrGroupList = [aDecoder decodeObjectForKey:@"customAttrGroupList"];
        self.representedAsKeyWindow = [aDecoder decodeBoolForKey:@"representedAsKeyWindow"];
        
        id soloScreenshotObj = [aDecoder decodeObjectForKey:@"soloScreenshot"];
        if (soloScreenshotObj) {
            if ([soloScreenshotObj isKindOfClass:[NSData class]]) {
                self.soloScreenshot = [soloScreenshotObj lookin_decodedObjectWithType:LookinCodingValueTypeImage];
            } else if ([soloScreenshotObj isKindOfClass:[LookinImage class]]) {
                self.soloScreenshot = soloScreenshotObj;
            } else {
                NSAssert(NO, @"");
            }
        }
        
        id groupScreenshotObj = [aDecoder decodeObjectForKey:@"groupScreenshot"];
        if (groupScreenshotObj) {
            if ([groupScreenshotObj isKindOfClass:[NSData class]]) {
                self.groupScreenshot = [groupScreenshotObj lookin_decodedObjectWithType:LookinCodingValueTypeImage];
            } else if ([groupScreenshotObj isKindOfClass:[LookinImage class]]) {
                self.groupScreenshot = groupScreenshotObj;
            } else {
                NSAssert(NO, @"");
            }            
        }
        
        self.eventHandlers = [aDecoder decodeObjectForKey:@"eventHandlers"];
        /// 该属性从 LookinServer 1.1.3 开始添加
        self.shouldCaptureImage = [aDecoder containsValueForKey:@"shouldCaptureImage"] ? [aDecoder decodeBoolForKey:@"shouldCaptureImage"] : YES;
        self.customDisplayTitle = [aDecoder decodeObjectForKey:@"customDisplayTitle"];
        self.danceuiSource = [aDecoder decodeObjectForKey:@"danceuiSource"];
#if TARGET_OS_IPHONE
        self.frame = [aDecoder decodeCGRectForKey:@"frame"];
        self.bounds = [aDecoder decodeCGRectForKey:@"bounds"];
        self.backgroundColor = [UIColor lks_colorFromRGBAComponents:[aDecoder decodeObjectForKey:@"backgroundColor"]];
#elif TARGET_OS_OSX
        self.frame = [aDecoder decodeRectForKey:@"frame"];
        self.bounds = [aDecoder decodeRectForKey:@"bounds"];
        self.backgroundColor = [NSColor lookin_colorFromRGBAComponents:[aDecoder decodeObjectForKey:@"backgroundColor"]];
        
#endif
        [self _updateDisplayingInHierarchyProperty];
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)init {
    if (self = [super init]) {
        /// 在手机端，displayItem 被创建时会调用这个方法
        [self _updateDisplayingInHierarchyProperty];
    }
    return self;
}

- (LookinObject *)displayingObject {
    return self.windowObject ? : self.viewObject ? : self.layerObject;
}

- (void)setAttributesGroupList:(NSArray<LookinAttributesGroup *> *)attributesGroupList {
    _attributesGroupList = attributesGroupList;
    
    [_attributesGroupList enumerateObjectsUsingBlock:^(LookinAttributesGroup * _Nonnull group, NSUInteger idx, BOOL * _Nonnull stop) {
        [group.attrSections enumerateObjectsUsingBlock:^(LookinAttributesSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop) {
            [section.attributes enumerateObjectsUsingBlock:^(LookinAttribute * _Nonnull attr, NSUInteger idx, BOOL * _Nonnull stop) {
                attr.targetDisplayItem = self;
            }];
        }];
    }];
}

- (void)setCustomAttrGroupList:(NSArray<LookinAttributesGroup *> *)customAttrGroupList {
    _customAttrGroupList = customAttrGroupList;
    // 传进来的时候就已经排好序了
    [customAttrGroupList enumerateObjectsUsingBlock:^(LookinAttributesGroup * _Nonnull group, NSUInteger idx, BOOL * _Nonnull stop) {
        [group.attrSections enumerateObjectsUsingBlock:^(LookinAttributesSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop) {
            [section.attributes enumerateObjectsUsingBlock:^(LookinAttribute * _Nonnull attr, NSUInteger idx, BOOL * _Nonnull stop) {
                attr.targetDisplayItem = self;
            }];
        }];
    }];
}

- (void)setSubitems:(NSArray<LookinDisplayItem *> *)subitems {
    [_subitems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.superItem = nil;
    }];
    
    _subitems = subitems;
    
    self.isExpandable = (subitems.count > 0);
    
    [subitems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSAssert(!obj.superItem, @"");
        obj.superItem = self;
        
        [obj _updateInHiddenHierarchyProperty];
        [obj _updateDisplayingInHierarchyProperty];
    }];
}

- (void)setIsExpandable:(BOOL)isExpandable {
    if (_isExpandable == isExpandable) {
        return;
    }
    _isExpandable = isExpandable;
    [self _notifyDelegatesWith:LookinDisplayItemProperty_IsExpandable];
}

- (void)setIsExpanded:(BOOL)isExpanded {
    if (_isExpanded == isExpanded) {
        return;
    }
    _isExpanded = isExpanded;
    [self.subitems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj _updateDisplayingInHierarchyProperty];
    }];
    [self _notifyDelegatesWith:LookinDisplayItemProperty_IsExpanded];
}

- (void)setSoloScreenshot:(LookinImage *)soloScreenshot {
    if (_soloScreenshot == soloScreenshot) {
        return;
    }
    _soloScreenshot = soloScreenshot;
    [self _notifyDelegatesWith:LookinDisplayItemProperty_SoloScreenshot];
}

- (void)notifySelectionChangeToDelegates {
    [self _notifyDelegatesWith:LookinDisplayItemProperty_IsSelected];
}

- (void)notifyHoverChangeToDelegates {
    [self _notifyDelegatesWith:LookinDisplayItemProperty_IsHovered];
}

- (void)setDoNotFetchScreenshotReason:(LookinDoNotFetchScreenshotReason)doNotFetchScreenshotReason {
    if (_doNotFetchScreenshotReason == doNotFetchScreenshotReason) {
        return;
    }
    _doNotFetchScreenshotReason = doNotFetchScreenshotReason;
    [self _notifyDelegatesWith:LookinDisplayItemProperty_AvoidSyncScreenshot];
}

- (void)setGroupScreenshot:(LookinImage *)groupScreenshot {
    if (_groupScreenshot == groupScreenshot) {
        return;
    }
    _groupScreenshot = groupScreenshot;
    [self _notifyDelegatesWith:LookinDisplayItemProperty_GroupScreenshot];
}

- (void)setDisplayingInHierarchy:(BOOL)displayingInHierarchy {
    if (_displayingInHierarchy == displayingInHierarchy) {
        return;
    }
    _displayingInHierarchy = displayingInHierarchy;
    [self.subitems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj _updateDisplayingInHierarchyProperty];
    }];
    
    [self _notifyDelegatesWith:LookinDisplayItemProperty_DisplayingInHierarchy];
}

- (void)_updateDisplayingInHierarchyProperty {
    if (self.superItem && (!self.superItem.displayingInHierarchy || !self.superItem.isExpanded)) {
        self.displayingInHierarchy = NO;
    } else {
        self.displayingInHierarchy = YES;
    }
}

- (void)setIsHidden:(BOOL)isHidden {
    _isHidden = isHidden;
    [self _updateInHiddenHierarchyProperty];
}

- (void)setAlpha:(float)alpha {
    _alpha = alpha;
    [self _updateInHiddenHierarchyProperty];
}

- (void)setInHiddenHierarchy:(BOOL)inHiddenHierarchy {
    if (_inHiddenHierarchy == inHiddenHierarchy) {
        return;
    }
    _inHiddenHierarchy = inHiddenHierarchy;
    [self.subitems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj _updateInHiddenHierarchyProperty];
    }];
    
    [self _notifyDelegatesWith:LookinDisplayItemProperty_InHiddenHierarchy];
}

- (void)_updateInHiddenHierarchyProperty {
    if (self.superItem.inHiddenHierarchy || self.isHidden || self.alpha <= 0) {
        self.inHiddenHierarchy = YES;
    } else {
        self.inHiddenHierarchy = NO;
    }
}

#pragma mark - 酷狗（KuGou）KGMainViewController 层级折叠

/**
 酷狗 iOS 客户端没有使用 UINavigationController / UITabBarController 管理页面，而是用
 KGMainViewController 不断 addChildViewController:，被 add 的所有 subVC 始终都实时挂在视图树上
 （系统的容器在页面离屏后会 remove，而酷狗不会）。这导致 Lookin / Reveal 每次 snapshot 都会
 渲染海量控件。这里在打平层级时，把 KGMainViewController.view 下的子树折叠为「只显示最上面的
 那个 VC」，并默认隐藏抽屉（_setViewContainer）。

 通过两个开关控制（都默认 NO，即默认折叠）：
   - kgShowAllPages：YES 时彻底关闭折叠逻辑，显示完整的原始层级（所有页面）。
   - kgShowDrawer：  YES 时保留抽屉（_setViewContainer）的子层级。

 这两个开关由 macOS 客户端的 LKPreferenceManager 持有。LookinCore 需要保持可在 iOS 端编译，
 因此不能直接 import 客户端的 LKPreferenceManager 头文件，这里改用运行时（NSClassFromString）
 读取；在 iOS 端（找不到该类时）回退到 NSUserDefaults，默认值为 NO。
 */

/// 运行时获取 [LKPreferenceManager mainManager] 单例，类或方法不存在时返回 nil。
+ (id)lk_kg_runtimePreferenceManager {
    Class prefManagerClass = NSClassFromString(@"LKPreferenceManager");
    if (!prefManagerClass) {
        return nil;
    }
    SEL mainManagerSelector = NSSelectorFromString(@"mainManager");
    if (![prefManagerClass respondsToSelector:mainManagerSelector]) {
        return nil;
    }
    id managerInstance = nil;
    @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        managerInstance = [prefManagerClass performSelector:mainManagerSelector];
#pragma clang diagnostic pop
    } @catch (NSException *exception) {
        managerInstance = nil;
    }
    return managerInstance;
}

/// 把环境变量解析为 BOOL。无此变量或无法识别时返回 nil。
/// 识别 1/true/yes/on（真）与 0/false/no/off（假），大小写不敏感。
+ (NSNumber *)lk_kg_boolFromEnvForKey:(NSString *)key {
    NSString *raw = NSProcessInfo.processInfo.environment[key];
    if (raw.length == 0) {
        return nil;
    }
    NSString *v = raw.lowercaseString;
    if ([v isEqualToString:@"1"] || [v isEqualToString:@"true"] || [v isEqualToString:@"yes"] || [v isEqualToString:@"on"]) {
        return @YES;
    }
    if ([v isEqualToString:@"0"] || [v isEqualToString:@"false"] || [v isEqualToString:@"no"] || [v isEqualToString:@"off"]) {
        return @NO;
    }
    return nil;
}

/// 是否显示全部页面（即关闭折叠逻辑）。默认 NO。
/// 优先级：macOS 客户端 LKPreferenceManager（GUI 按钮） > 环境变量 > NSUserDefaults。
/// 环境变量 LOOKIN_MCP_SHOW_ALL_PAGES 供 lookinside-mcp 等无 GUI 的进程使用。
+ (BOOL)lk_kg_shouldShowAllPages {
    id manager = [self lk_kg_runtimePreferenceManager];
    if (manager) {
        @try {
            id value = [manager valueForKeyPath:@"kgShowAllPages.currentBOOLValue"];
            if ([value isKindOfClass:[NSNumber class]]) {
                return [value boolValue];
            }
        } @catch (NSException *exception) {
        }
        return NO;
    }
    NSNumber *envValue = [self lk_kg_boolFromEnvForKey:@"LOOKIN_MCP_SHOW_ALL_PAGES"];
    if (envValue != nil) {
        return envValue.boolValue;
    }
    return [NSUserDefaults.standardUserDefaults boolForKey:@"KGShouldDisableLookinHook"];
}

/// 是否显示抽屉（_setViewContainer）。默认 NO。
/// 优先级：macOS 客户端 LKPreferenceManager（GUI 按钮） > 环境变量 > NSUserDefaults。
/// 环境变量 LOOKIN_MCP_SHOW_DRAWER 供 lookinside-mcp 等无 GUI 的进程使用。
+ (BOOL)lk_kg_shouldShowDrawer {
    id manager = [self lk_kg_runtimePreferenceManager];
    if (manager) {
        @try {
            id value = [manager valueForKeyPath:@"kgShowDrawer.currentBOOLValue"];
            if ([value isKindOfClass:[NSNumber class]]) {
                return [value boolValue];
            }
        } @catch (NSException *exception) {
        }
        return NO;
    }
    NSNumber *envValue = [self lk_kg_boolFromEnvForKey:@"LOOKIN_MCP_SHOW_DRAWER"];
    if (envValue != nil) {
        return envValue.boolValue;
    }
    return [NSUserDefaults.standardUserDefaults boolForKey:@"KGShouldShowSetContainer"];
}

+ (NSArray<LookinDisplayItem *> *)flatItemsFromHierarchicalItems:(NSArray<LookinDisplayItem *> *)items {
    NSMutableArray *resultArray = [NSMutableArray array];

    [items enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.superItem) {
            obj.indentLevel = obj.superItem.indentLevel + 1;
        }
        [resultArray addObject:obj];

        // 注意：这里始终对 KGMainViewController 子树做处理。两个开关是相互独立的：
        //   - 「显示抽屉」(kgShowDrawer)   只控制抽屉 _setViewContainer 是否展示；
        //   - 「显示全部页面」(kgShowAllPages) 只控制是否折叠页面栈（只留最上面的 VC）。
        // 因此即使打开「显示全部页面」，抽屉仍然受「显示抽屉」单独控制，不会被连带展示。
        NSString *subTitle = obj.viewObject.specialTrace;
        if (subTitle && [subTitle containsString:@"KGMainViewController"] && [subTitle containsString:@".view"]) {
            obj.subitems = [self lk_kg_filterSubitems:obj.subitems];
        }

        if (obj.subitems.count) {
            [resultArray addObjectsFromArray:[self flatItemsFromHierarchicalItems:obj.subitems]];
        }
    }];

    return resultArray;
}

+ (void)lk_kg_applyKuGouCollapseToHierarchicalItems:(NSArray<LookinDisplayItem *> *)items {
    // 与 flatItemsFromHierarchicalItems: 中的折叠逻辑完全一致，只是不打平、只就地修改子树，
    // 方便 lookinside-mcp 这类直接遍历 displayItems 树的客户端复用。
    [items enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *subTitle = obj.viewObject.specialTrace;
        if (subTitle && [subTitle containsString:@"KGMainViewController"] && [subTitle containsString:@".view"]) {
            obj.subitems = [self lk_kg_filterSubitems:obj.subitems];
        }
        if (obj.subitems.count) {
            [self lk_kg_applyKuGouCollapseToHierarchicalItems:obj.subitems];
        }
    }];
}

/// KGMainViewController.view 的直接子层。新框架下存在 _contentContainer（主框架容器），
/// 旧框架下则没有，直接把 KGMainViewController.view 的子层当作内容容器处理。
+ (NSArray<LookinDisplayItem *> *)lk_kg_filterSubitems:(NSArray<LookinDisplayItem *> *)subitems {
    NSMutableArray *filteredItems = [NSMutableArray arrayWithArray:subitems];

    // 是不是新版本（含 _contentContainer）
    __block BOOL hasFoundContentContainer = NO;
    __block int count = 0;
    [filteredItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<NSString *> *ivarNames = [item.viewObject.ivarTraces valueForKey:@"ivarName"];
        if ([ivarNames containsObject:@"_contentContainer"]) {
            // 主框架容器
            item.subitems = [self lk_kg_filterContentContainerSubitems:item.subitems];
            count += 1;
            hasFoundContentContainer = YES;
        }
        if (count >= 2) {
            *stop = YES;
        }
    }];

    if (!hasFoundContentContainer) {
        // 旧版本：没有 _contentContainer，直接按内容容器处理
        return [self lk_kg_filterContentContainerSubitems:subitems];
    }

    return filteredItems;
}

+ (NSArray<LookinDisplayItem *> *)lk_kg_filterContentContainerSubitems:(NSArray<LookinDisplayItem *> *)subitems {
    BOOL showAllPages = [self lk_kg_shouldShowAllPages];
    BOOL shouldShowDrawer = [self lk_kg_shouldShowDrawer];

    NSMutableArray *filteredItems = [NSMutableArray arrayWithArray:subitems];
    __block BOOL isSetContentNotEmpty = NO;
    [filteredItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<NSString *> *ivarNames = [item.viewObject.ivarTraces valueForKey:@"ivarName"];

        if ([ivarNames containsObject:@"_setViewContainer"]) {
            // 抽屉：只由「显示抽屉」控制，和「显示全部页面」相互独立
            if (!shouldShowDrawer) {
                item.subitems = nil;
            }
        } else if (!showAllPages && [ivarNames containsObject:@"_mainBackScaleView"]) {
            // 页面折叠相关：仅在未开启「显示全部页面」时进行
            item.subitems = [self lk_kg_filterMainBackScaleViewSubitems:item.subitems];
        } else if (!showAllPages && [ivarNames containsObject:@"_setContentView"]) {
            item.subitems = [self lk_kg_filterContentViewSubitems:item.subitems];
            isSetContentNotEmpty = item.subitems.count > 0;
        }
    }];

    if (!showAllPages && isSetContentNotEmpty) {
        // 设置层（抽屉内容层）非空时，主缩放层让位：但抽屉本身仍只由「显示抽屉」控制
        filteredItems = [NSMutableArray arrayWithArray:subitems];
        [filteredItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            NSArray<NSString *> *ivarNames = [item.viewObject.ivarTraces valueForKey:@"ivarName"];

            if ([ivarNames containsObject:@"_setViewContainer"]) {
                if (!shouldShowDrawer) {
                    item.subitems = nil;
                }
            } else if ([ivarNames containsObject:@"_mainBackScaleView"]) {
                item.subitems = nil;
            } else if ([ivarNames containsObject:@"_setContentView"]) {
                item.subitems = [self lk_kg_filterContentViewSubitems:item.subitems];
                isSetContentNotEmpty = item.subitems.count > 0;
            }
        }];
    }

    return filteredItems;
}

+ (NSArray<LookinDisplayItem *> *)lk_kg_filterMainBackScaleViewSubitems:(NSArray<LookinDisplayItem *> *)subitems {
    NSMutableArray *filteredItems = [NSMutableArray arrayWithArray:subitems];

    [filteredItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<NSString *> *ivarNames = [item.viewObject.ivarTraces valueForKey:@"ivarName"];
        if ([ivarNames containsObject:@"_mainBackView"]) {
            item.subitems = [self lk_kg_filterMainBackViewSubitems:item.subitems];
            *stop = YES;
        }
    }];

    return filteredItems;
}

+ (NSArray<LookinDisplayItem *> *)lk_kg_filterMainBackViewSubitems:(NSArray<LookinDisplayItem *> *)subitems {
    NSMutableArray *filteredItems = [NSMutableArray arrayWithArray:subitems];

    __block int count = 0;
    [filteredItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<NSString *> *ivarNames = [item.viewObject.ivarTraces valueForKey:@"ivarName"];

        if ([ivarNames containsObject:@"_guideBarContainer"]) {
            // 侧边栏
        } else if ([ivarNames containsObject:@"_contentView"]) {
            item.subitems = [self lk_kg_filterContentViewSubitems:item.subitems];
            count += 1;
        } else if ([ivarNames containsObject:@"_fullSizeContentView"]) {
            item.subitems = [self lk_kg_filterContentViewSubitems:item.subitems];
            if (item.subitems.count >= 2) {
                count += 1;
            }
        }

        if (count >= 2) {
            *stop = YES;
        }
    }];

    if (count > 1) {
        filteredItems = [NSMutableArray arrayWithArray:subitems];
        // 两个内容容器都有内容时，只保留 _fullSizeContentView
        [filteredItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            NSArray<NSString *> *ivarNames = [item.viewObject.ivarTraces valueForKey:@"ivarName"];

            if ([ivarNames containsObject:@"_fullSizeContentView"]) {
                item.subitems = [self lk_kg_filterContentViewSubitems:item.subitems];
            }
            if ([ivarNames containsObject:@"_contentView"]) {
                item.subitems = nil;
            }
        }];
    }

    return filteredItems;
}

+ (NSArray<LookinDisplayItem *> *)lk_kg_filterContentViewSubitems:(NSArray<LookinDisplayItem *> *)subitems {
    NSMutableArray *filteredItems = [NSMutableArray arrayWithCapacity:2];

    __block int count = 0;
    [subitems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<NSString *> *ivarNames = [item.viewObject.ivarTraces valueForKey:@"ivarName"];

        if ([ivarNames containsObject:@"_backShadowView"]) {
            // 最上面 VC 下面第一层的阴影
            [filteredItems addObject:item];
            count += 1;
        } else if (idx == subitems.count - 1) {
            // 最上面的那个 VC
            [filteredItems addObject:item];
            count += 1;
        }
        if (count >= 2) {
            *stop = YES;
        }
    }];

    // 在首页时，阴影不会移动到下方，此时保留原始子层
    if (filteredItems.count < 2) {
        filteredItems = [NSMutableArray arrayWithArray:subitems];
    }

    return filteredItems;
}

- (NSString *)description {
    if (self.viewObject) {
        return self.viewObject.rawClassName;
    } else if (self.layerObject) {
        return self.layerObject.rawClassName;
    } else if (self.windowObject) {
        return self.windowObject.rawClassName;
    } else {
        return [super description];
    }
}

- (void)setPreviewItemDelegate:(id<LookinDisplayItemDelegate>)previewItemDelegate {
    _previewItemDelegate = previewItemDelegate;
    
    if (![previewItemDelegate respondsToSelector:@selector(displayItem:propertyDidChange:)]) {
        NSAssert(NO, @"");
        _previewItemDelegate = nil;
        return;
    }
    [self.previewItemDelegate displayItem:self propertyDidChange:LookinDisplayItemProperty_None];
}

- (void)setRowViewDelegate:(id<LookinDisplayItemDelegate>)rowViewDelegate {
    if (_rowViewDelegate == rowViewDelegate) {
        return;
    }
    _rowViewDelegate = rowViewDelegate;
    
    if (![rowViewDelegate respondsToSelector:@selector(displayItem:propertyDidChange:)]) {
        NSAssert(NO, @"");
        _rowViewDelegate = nil;
        return;
    }
    [self.rowViewDelegate displayItem:self propertyDidChange:LookinDisplayItemProperty_None];
}

- (void)setFrame:(CGRect)frame {
    _frame = frame;
    [self recursivelyNotifyFrameToRootMayChange];
}

- (void)recursivelyNotifyFrameToRootMayChange {
    [self _notifyDelegatesWith:LookinDisplayItemProperty_FrameToRoot];

    [self.subitems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj recursivelyNotifyFrameToRootMayChange];
    }];
}

- (void)setBounds:(CGRect)bounds {
    _bounds = bounds;
    [self recursivelyNotifyFrameToRootMayChange];
}

- (void)setInNoPreviewHierarchy:(BOOL)inNoPreviewHierarchy {
    if (_inNoPreviewHierarchy == inNoPreviewHierarchy) {
        return;
    }
    _inNoPreviewHierarchy = inNoPreviewHierarchy;
    [self.subitems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj _updateInNoPreviewHierarchy];
    }];
    [self _notifyDelegatesWith:LookinDisplayItemProperty_InNoPreviewHierarchy];
}

- (void)setNoPreview:(BOOL)noPreview {
    _noPreview = noPreview;
    [self _updateInNoPreviewHierarchy];
}

- (void)_updateInNoPreviewHierarchy {
    if (self.superItem.inNoPreviewHierarchy || self.noPreview) {
        self.inNoPreviewHierarchy = YES;
    } else {
        self.inNoPreviewHierarchy = NO;
    }
}

- (void)_notifyDelegatesWith:(LookinDisplayItemProperty)property {
    [self.previewItemDelegate displayItem:self propertyDidChange:property];
    [self.rowViewDelegate displayItem:self propertyDidChange:property];
}

- (void)setIsInSearch:(BOOL)isInSearch {
    _isInSearch = isInSearch;
    [self _notifyDelegatesWith:LookinDisplayItemProperty_IsInSearch];
}

- (void)setHighlightedSearchString:(NSString *)highlightedSearchString {
    _highlightedSearchString = highlightedSearchString;
    [self _notifyDelegatesWith:LookinDisplayItemProperty_HighlightedSearchString];
}

- (NSArray<LookinAttributesGroup *> *)queryAllAttrGroupList {
    NSMutableArray *array = [NSMutableArray array];
    if (self.attributesGroupList) {
        [array addObjectsFromArray:self.attributesGroupList];
    }
    if (self.customAttrGroupList) {
        [array addObjectsFromArray:self.customAttrGroupList];
    }
    return array;
}

//- (void)dealloc
//{
//    NSLog(@"moss dealloc -%@", self);
//}


#if TARGET_OS_IPHONE
- (void)setFlipped:(BOOL)flipped {}

- (BOOL)isFlipped {
    return NO;
}
#endif

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
