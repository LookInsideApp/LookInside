//
//  LKHierarchyDataSource.m
//  Lookin
//
//  Created by Li Kai on 2019/5/6.
//  https://lookin.work
//

#import "LKHierarchyDataSource.h"
#import "LookinHierarchyInfo.h"
#import "LookinAppInfo.h"
#import "LookinDisplayItem.h"
#import "LookinAttribute.h"
#import "LKPreferenceManager.h"
#import "LKColorIndicatorLayer.h"
#import "LKUserActionManager.h"
#import "LookinDisplayItem+LookinClient.h"
#import "LKDanceUIAttrMaker.h"
#import "LKStaticAsyncUpdateManager.h"
#include <math.h>

@interface LKSelectColorItem : NSObject

+ (instancetype)itemWithTitle:(NSString *)title color:(LookinColor *)color;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, strong) NSColor *color;

@end

@implementation LKSelectColorItem

+ (instancetype)itemWithTitle:(NSString *)title color:(LookinColor *)color {
    LKSelectColorItem *item = [LKSelectColorItem new];
    item.title = title;
    item.color = color;
    return item;
}

@end

@interface LKSelectColorItemsSection : NSObject

@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSArray<LKSelectColorItem *> *items;

@end

@implementation LKSelectColorItemsSection

- (void)setItems:(NSArray<LKSelectColorItem *> *)items {
    _items = [items sortedArrayUsingComparator:^NSComparisonResult(LKSelectColorItem * _Nonnull obj1, LKSelectColorItem * _Nonnull obj2) {
        return [obj1.title caseInsensitiveCompare:obj2.title];
    }].copy;
}

@end

@interface LookinDisplayItem (LKHierarchyDataSource)

/// 记录搜索之前的 isExpanded 的值，用来在结束搜索后恢复
@property(nonatomic, assign) BOOL isExpandedBeforeSearchOrFocus;

@end

@implementation LookinDisplayItem (LKHierarchyDataSource)

- (void)setIsExpandedBeforeSearchOrFocus:(BOOL)isExpandedBeforeSearching {
    [self lookin_bindBOOL:isExpandedBeforeSearching forKey:@"isExpandedBeforeSearching"];
}

- (BOOL)isExpandedBeforeSearchOrFocus {
    return [self lookin_getBindBOOLForKey:@"isExpandedBeforeSearching"];
}

@end

static NSInteger LKSwiftUILayerOrdinalFromAttributeTitle(NSString *title) {
    if (![title hasPrefix:@"Layer "]) {
        return NSNotFound;
    }
    NSScanner *scanner = [NSScanner scannerWithString:[title substringFromIndex:@"Layer ".length]];
    NSInteger value = 0;
    if (![scanner scanInteger:&value] || value <= 0) {
        return NSNotFound;
    }
    return value - 1;
}

static void LKAddUniqueDisplayItem(NSMutableArray<LookinDisplayItem *> *items, LookinDisplayItem *item) {
    if (item && ![items containsObject:item]) {
        [items addObject:item];
    }
}

static BOOL LKRectsAlmostEqual(CGRect lhs, CGRect rhs) {
    CGFloat tolerance = 1.0;
    return fabs(lhs.origin.x - rhs.origin.x) <= tolerance &&
           fabs(lhs.origin.y - rhs.origin.y) <= tolerance &&
           fabs(lhs.size.width - rhs.size.width) <= tolerance &&
           fabs(lhs.size.height - rhs.size.height) <= tolerance;
}

/// Returns the item's leaf class name using the view → layer → window priority order shared
/// with `LookinDisplayItem.title`; returns nil for UserCustom-only nodes (no classChainList).
static NSString *LKDisplayItemPrimaryClassName(LookinDisplayItem *item) {
    NSArray<NSString *> *chain = item.viewObject.classChainList;
    if (chain.count == 0) {
        chain = item.layerObject.classChainList;
    }
    if (chain.count == 0) {
        chain = item.windowObject.classChainList;
    }
    return chain.firstObject;
}

static BOOL LKSwiftUIItemMatchesSourceTypes(LookinDisplayItem *item, NSArray<NSString *> *sourceTypes) {
    if (sourceTypes.count == 0) {
        return YES;
    }
    NSArray<NSString *> *itemTypes = [item lk_swiftUITypeNames];
    for (NSString *sourceType in sourceTypes) {
        if ([itemTypes containsObject:sourceType]) {
            return YES;
        }
    }
    return NO;
}

@interface LKHierarchyDataSource ()
@property(nonatomic, assign) LKHierarchyDataSourceState state;

@property(nonatomic, strong, readwrite) LookinHierarchyInfo *rawHierarchyInfo;

/// displayingFlatItems 是 flatItems 的子集，仅包含用户可以看到的 items，而那些被折叠的 items 会被剔除。换句话说，当用户展开或收起 item 时，displayingFlatItems 属性会被 buildDisplayingFlatItems 方法不断更新
@property(nonatomic, copy, readwrite) NSArray<LookinDisplayItem *> *displayingFlatItems;

@property(nonatomic, strong, readwrite) NSMenu *selectColorMenu;
@property(nonatomic, copy) NSDictionary<NSNumber *, LookinDisplayItem *> *oidToDisplayItemMap;

/**
 key 是 rgba 字符串，value 是 alias 字符串数组，比如：
 
 @{
 @"(255, 255, 255, 1)": @[@"MyWhite", @"MainThemeWhite"],
 @"(255, 0, 0, 0.5)": @[@"BestRed", @"TransparentRed"]
 };
 
 */
@property(nonatomic, strong) NSDictionary<NSString *, NSArray<NSString *> *> *colorToAliasMap;

- (LookinDisplayItem *)_layerItemWithMemoryAddress:(NSString *)memoryAddress;
- (LookinDisplayItem *)_layerItemWithDisplayListID:(NSNumber *)displayListID;
- (LookinDisplayItem *)_swiftUIItemWithDisplayListID:(NSNumber *)displayListID;
- (LookinDisplayItem *)_swiftUIItemForLayerItemByFrameAndSource:(LookinDisplayItem *)layerItem;

@end

@implementation LKHierarchyDataSource

- (instancetype)init {
    if (self = [super init]) {
        _itemDidChangeHiddenAlphaValue = [RACSubject subject];
        _itemDidChangeAttrGroup = [RACSubject subject];
        _itemDidChangeNoPreview = [RACSubject subject];
        _didReloadHierarchyInfo = [RACSubject subject];
        _willReloadHierarchyInfo = [RACSubject subject];
        _didReloadFlatItemsWithSearchOrFocus = [RACSubject subject];
        
        @weakify(self);
        [[[RACObserve([LKPreferenceManager mainManager], rgbaFormat) skip:1] distinctUntilChanged] subscribeNext:^(id  _Nullable x) {
            @strongify(self);
            [self _setUpColors];
        }];
    }
    return self;
}

- (void)reloadWithHierarchyInfo:(LookinHierarchyInfo *)info keepState:(BOOL)keepState {
    // Snapshot the previous root items before overwriting rawHierarchyInfo so that path
    // identifiers built from the OLD flatItems' superItem chains still resolve their root
    // index against the OLD displayItems array.
    NSArray<LookinDisplayItem *> *prevRootItems = self.rawHierarchyInfo.displayItems;

    self.rawHierarchyInfo = info;

    [self.willReloadHierarchyInfo sendNext:nil];

    if (info.colorAlias.count) {
        [LKPreferenceManager mainManager].receivingConfigTime_Color = [[NSDate date] timeIntervalSince1970];
    }
    if (info.collapsedClassList.count) {
        [LKPreferenceManager mainManager].receivingConfigTime_Class = [[NSDate date] timeIntervalSince1970];
    }
    
    unsigned long prevSelectedOid = 0;
    NSMutableDictionary<NSString *, NSNumber *> *prevExpansionMap = nil;
    BOOL prefersViewOID = [LKHelper appInfoLooksLikeMacTarget:info.appInfo];
    if (keepState) {
        prevSelectedOid = [self.selectedItem bestObjectOidPreferView:prefersViewOID];

        prevExpansionMap = [NSMutableDictionary dictionary];
        [self.flatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *path = [LKHierarchyDataSource pathIdentifierForItem:obj inRootItems:prevRootItems];
            if (path) {
                prevExpansionMap[path] = @(obj.isExpanded);
            }
        }];
    }
    
    // 设置 color alias 和 select color menu
    [self _setUpColors];
    
    // 根据 subitems 属性打平为二维数组，同时给每个 item 设置 indentLevel
    self.rawFlatItems = [LookinDisplayItem flatItemsFromHierarchicalItems:info.displayItems];
    NSArray<LookinDisplayItem *> *flatItems = self.rawFlatItems.copy;
    
    // 设置 preferToBeCollapsed 属性
    NSSet<NSString *> *classesPreferredToCollapse = [NSSet setWithObjects:@"UILabel", @"UIPickerView", @"UIProgressView", @"UIActivityIndicatorView", @"UIAlertView", @"UIActionSheet", @"UISearchBar", @"UIButton", @"UITextView", @"UIDatePicker", @"UIPageControl", @"UISegmentedControl", @"UITextField", @"UISlider", @"UISwitch", @"UIVisualEffectView", @"UIImageView", @"WKCommonWebView", @"UITextEffectsWindow", nil];
    if (info.collapsedClassList.count) {
        classesPreferredToCollapse = [classesPreferredToCollapse setByAddingObjectsFromArray:info.collapsedClassList];
    }
    // no preview
    NSSet<NSString *> *classesWithNoPreview = [NSSet setWithArray:@[@"UITextEffectsWindow", @"UIRemoteKeyboardWindow"]];
    
    [flatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj itemIsKindOfClassesWithNames:classesPreferredToCollapse]) {
            [obj enumerateSelfAndChildren:^(LookinDisplayItem *item) {
                item.preferToBeCollapsed = YES;
            }];
        }
        
        // 在 indentLevel 0（iOS 13 之前的 window 或 macOS）和 indentLevel 1（iOS 13+ scene 下的 window）都检查
        if (obj.indentLevel <= 1) {
            if ([obj itemIsKindOfClassesWithNames:classesWithNoPreview]) {
                obj.noPreview = YES;
            }
        }
        
        if (!obj.isUserCustom && !obj.shouldCaptureImage) {
            [obj enumerateSelfAndChildren:^(LookinDisplayItem *item) {
                item.noPreview = YES;
                item.doNotFetchScreenshotReason = LookinDoNotFetchScreenshotForUserConfig;
            }];
        }
//        } else if ([LKPreferenceManager mainManager].showHiddenItems.currentBOOLValue == NO && obj.inHiddenHierarchy) {
//            [obj enumerateSelfAndChildren:^(LookinDisplayItem *item) {
//                item.noPreview = YES;
//                item.doNotFetchScreenshotReason = LookinDoNotFetchScreenshotForHidden;
//            }];
//        }
        
        if (!self.serverSideIsSwiftProject) {
            if ([obj.displayingObject.lk_completedDemangledClassName containsString:@"."]) {
                _serverSideIsSwiftProject = YES;
            }
        }
        
        if (obj.customInfo.danceuiSource.length > 0) {
            [LKDanceUIAttrMaker makeDanceUIJumpAttribute:obj danceSource:obj.customInfo.danceuiSource];
        }
    }];
    
    self.flatItems = flatItems;
    
    // 设置选中
    LookinDisplayItem *shouldSelectedItem = nil;
    if (keepState) {
        LookinDisplayItem *prevSelectedItem = [self displayItemWithOid:prevSelectedOid];
        if (prevSelectedItem) {
            shouldSelectedItem = prevSelectedItem;
        }
    }

    // 设置展开和折叠
    NSInteger expansionIndex = self.preferenceManager.expansionIndex;
    if (self.flatItems.count > 300) {
        if (expansionIndex > 2) {
            expansionIndex = 2;
        }
    }

    NSDictionary<NSString *, NSNumber *> *referenceDict = nil;
    if (keepState) {
        referenceDict = prevExpansionMap;
    } else {
        // Cold reload: seed the reference dict from the persisted state for this bundle id
        // so adjustExpansionByIndex: restores the matching items (both expanded and
        // user-collapsed). Paths not in the dict keep the index-driven preset behavior.
        LKPreferenceManager *prefs = self.preferenceManager;
        NSString *bundleId = info.appInfo.appBundleIdentifier;
        if (prefs.rememberExpansionState && bundleId.length > 0) {
            NSDictionary<NSString *, NSNumber *> *storedState = [prefs expansionStateForBundleIdentifier:bundleId];
            if (storedState.count > 0) {
                referenceDict = storedState;
            }
        }
    }
    [self adjustExpansionByIndex:expansionIndex referenceDict:referenceDict selectedItem:(shouldSelectedItem ? nil : &shouldSelectedItem)];
    
    if (!shouldSelectedItem) {
        shouldSelectedItem = self.flatItems.firstObject;
    }
    self.selectedItem = shouldSelectedItem;

    if (self.state != LKHierarchyDataSourceStateNormal) {
        // 可能在 search 或 focus 状态，要退出
        self.state = LKHierarchyDataSourceStateNormal;
    }
    
    [self.didReloadHierarchyInfo sendNext:nil];
}

- (NSInteger)numberOfRows {
    return self.displayingFlatItems.count;
}

- (LookinDisplayItem *)itemAtRow:(NSInteger)index {
    if (index < 0) {
        return nil;
    }
    if ([self.displayingFlatItems lookin_hasIndex:index]) {
        return self.displayingFlatItems[index];
    }
    return nil;
}

- (NSInteger)rowForItem:(LookinDisplayItem *)item {
    NSInteger row = [self.displayingFlatItems indexOfObject:item];
    return row;
}

- (void)setSelectedItem:(LookinDisplayItem *)selectedItem {
    if (_selectedItem == selectedItem) {
        return;
    }
    LookinDisplayItem *prevItem = _selectedItem;
    _selectedItem = selectedItem;
    
    [prevItem notifySelectionChangeToDelegates];
    [_selectedItem notifySelectionChangeToDelegates];

    [[LKUserActionManager sharedInstance] sendAction:LKUserActionType_SelectedItemChange];
    
    if (NSColorPanel.sharedColorPanelExists) {
        [[NSColorPanel sharedColorPanel] close];
    }

    if (!selectedItem && self.preferenceManager.measureState.currentIntegerValue != LookinMeasureState_no) {
        // 如果当前在测距，则取消
        [self.preferenceManager.measureState setIntegerValue:LookinMeasureState_no ignoreSubscriber:nil];
    }
}

- (void)setHoveredItem:(LookinDisplayItem *)hoveredItem {
    if (_hoveredItem == hoveredItem) {
        return;
    }
    LookinDisplayItem *prevItem = _hoveredItem;
    _hoveredItem = hoveredItem;
    [prevItem notifyHoverChangeToDelegates];
    [_hoveredItem notifyHoverChangeToDelegates];
}

- (void)adjustExpansionByIndex:(NSInteger)index referenceDict:(NSDictionary<NSString *, NSNumber *> *)referenceDict selectedItem:(LookinDisplayItem **)selectedItem {
    if (index < 0 || index > 4) {
        NSAssert(NO, @"adjustExpansionByIndex, index 为 %@", @(index));
        index = MAX(MIN(index, 4), 0);
    }

    self.preferenceManager.expansionIndex = index;

    NSArray<LookinDisplayItem *> *rootItems = self.rawHierarchyInfo.displayItems;

    __block NSUInteger expandedCount = self.flatItems.count;
    [self.flatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.hasDeterminedExpansion = NO;

        if (!obj.isExpandable) {
            obj.hasDeterminedExpansion = YES;
            expandedCount--;
            return;
        }

        if (referenceDict) {
            NSString *path = [LKHierarchyDataSource pathIdentifierForItem:obj inRootItems:rootItems];
            NSNumber *prevState = path ? referenceDict[path] : nil;
            if (prevState != nil) {
                // 旧的对象，直接维持之前的状态
                obj.isExpanded = [prevState boolValue];
                obj.hasDeterminedExpansion = YES;
                if (!obj.isExpanded) {
                    expandedCount--;
                }
            }
        }
    }];
    
    if (index == 0) {
        // 全部折叠，只剩下最顶层的 UIWindow
        
        __block LookinDisplayItem *preferedSelectedItem = nil;
        [self.flatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.hasDeterminedExpansion) {
                return;
            }
            obj.isExpanded = NO;
            
            if (obj.representedAsKeyWindow) {
                preferedSelectedItem = obj;
            }
        }];
            
        if (selectedItem) {
            *selectedItem = preferedSelectedItem;
        }
        
    } else if (index == 4) {
        // 全部展开，包括 UIButton、UITabBar、UINavigationBar 等等，全部展开
        [self.flatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.hasDeterminedExpansion) {
                return;
            }
            if (obj.inNoPreviewHierarchy) {
                obj.isExpanded = NO;
                return;
            }
            obj.isExpanded = YES;
        }];
        
        if (selectedItem) {
            __block LookinDisplayItem *preferedSelectedItem = nil;
            LookinDisplayItem *keyWindowRootItem = [self.rawHierarchyInfo.displayItems lookin_firstFiltered:^BOOL(LookinDisplayItem *obj) {
                return obj.representedAsKeyWindow;
            }];
            if (keyWindowRootItem) {
                [[LookinDisplayItem flatItemsFromHierarchicalItems:@[keyWindowRootItem]] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.hostViewControllerObject || obj.hostWindowControllerObject) {
                        preferedSelectedItem = obj;
                        *stop = YES;
                    }
                }];
            }
            *selectedItem = preferedSelectedItem;
        }
        
    } else {
        LookinDisplayItem *keyWindowItem = [self.rawHierarchyInfo.displayItems lookin_firstFiltered:^BOOL(LookinDisplayItem *windowItem) {
            return windowItem.representedAsKeyWindow;
        }];
        if (!keyWindowItem) {
            keyWindowItem = self.rawHierarchyInfo.displayItems.firstObject;
        }
        if (keyWindowItem) {

        // 如果 keyWindowItem 是 scene 容器（只有 windowObject，没有 layer/view），
        // 在其子项中找到实际的 key window，用于 UITransitionView 搜索
        LookinDisplayItem *actualKeyWindow = keyWindowItem;
        if (keyWindowItem.windowObject && !keyWindowItem.layerObject && !keyWindowItem.viewObject) {
            for (LookinDisplayItem *child in keyWindowItem.subitems) {
                if (child.representedAsKeyWindow) {
                    actualKeyWindow = child;
                    break;
                }
            }
            if (actualKeyWindow == keyWindowItem) {
                actualKeyWindow = keyWindowItem.subitems.firstObject;
            }
        }

        [self.rawHierarchyInfo.displayItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull windowItem, NSUInteger idx, BOOL * _Nonnull stop) {
            if (windowItem == keyWindowItem) {
                return;
            }
            // 非 keyWindow 上的都折叠起来
            // 强制折叠：覆盖 referenceDict 的旧展开状态，防止非 key scene 保持展开
            NSArray<LookinDisplayItem *> *flatNonKey = [LookinDisplayItem flatItemsFromHierarchicalItems:@[windowItem]];
            for (LookinDisplayItem *obj in flatNonKey) {
                obj.isExpanded = NO;
                obj.hasDeterminedExpansion = YES;
            }
        }];

        NSArray<LookinDisplayItem *> *UITransitionViewItems = [actualKeyWindow.subitems lookin_filter:^BOOL(LookinDisplayItem *obj) {
            return [obj.title isEqualToString:@"UITransitionView"];
        }];
        [UITransitionViewItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.hasDeterminedExpansion) {
                return;
            }
            if (idx == (UITransitionViewItems.count - 1)) {
                // 展开最后一个 UITransitionView
                obj.isExpanded = YES;
            } else {
                // 折叠前几个 UITransitionView
                obj.isExpanded = NO;
            }
            obj.hasDeterminedExpansion = YES;
        }];
        
        NSMutableArray<LookinDisplayItem *> *viewControllerItems = [NSMutableArray array];
        [[LookinDisplayItem flatItemsFromHierarchicalItems:@[keyWindowItem]] enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.hostViewControllerObject || obj.hostWindowControllerObject) {
                [viewControllerItems addObject:obj];
                return;
            }
            if (obj.hasDeterminedExpansion) {
                return;
            }
            if (obj.inNoPreviewHierarchy || obj.preferToBeCollapsed || (![LKPreferenceManager mainManager].showHiddenItems && obj.inHiddenHierarchy)) {
                // 把 noPreview 和 UIButton 之类常用控件叠起来
                obj.isExpanded = NO;
                obj.hasDeterminedExpansion = YES;
                return;
            }
            if ([obj itemIsKindOfClassesWithNames:[NSSet setWithObjects:@"UINavigationBar", @"UITabBar", nil]]) {
                // 把 NavigationBar 和 TabBar 折叠起来
                [obj enumerateSelfAndChildren:^(LookinDisplayItem *item) {
                    if (item.hasDeterminedExpansion) {
                        return;
                    }
                    item.isExpanded = NO;
                    item.hasDeterminedExpansion = YES;
                }];
                return;
            }
        }];
        
        if (selectedItem) {
            *selectedItem = viewControllerItems.lastObject;
        }
        
        if (index == 1) {
            // 恰好把 viewController 显示出来
            // 倒序，以确保多个 viewController 在同一条树上时，只有最 leaf 的那一个是被折叠的
            [viewControllerItems enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(LookinDisplayItem * _Nonnull viewControllerItem, NSUInteger idx, BOOL * _Nonnull stop) {
                [viewControllerItem enumerateSelfAndAncestors:^(LookinDisplayItem *item, BOOL *stop) {
                    // 把 viewController 的 ancestors 都展开
                    if (item.hasDeterminedExpansion) {
                        return;
                    }
                    item.isExpanded = (item != viewControllerItem);
                    item.hasDeterminedExpansion = YES;
                }];
            }];
            
            // 剩下未处理的都折叠
            [self.flatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.hasDeterminedExpansion) {
                    return;
                }
                obj.isExpanded = NO;
            }];
        
        } else if (index == 2) {
            // 从 viewController 开始算向 leaf 多推 3 层
            [viewControllerItems enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(LookinDisplayItem * _Nonnull viewControllerItem, NSUInteger idx, BOOL * _Nonnull stop) {
                [viewControllerItem enumerateAncestors:^(LookinDisplayItem *item, BOOL *stop) {
                    // 把 viewController 的 ancestors 都展开
                    if (item.hasDeterminedExpansion) {
                        return;
                    }
                    item.isExpanded = YES;
                    item.hasDeterminedExpansion = YES;
                }];
                
                BOOL hasTableOrCollectionView = [viewControllerItem.subitems.firstObject itemIsKindOfClassesWithNames:[NSSet setWithObjects:@"UITableView", @"UICollectionView", nil]];
                // 如果是那种典型的 UITableView 或 UICollectionView 的话，则向 leaf 方向推进 2 层（这样就可以让 cell 恰好露出来而不露出来 cell 的 contentView），否则就推 3 层
                NSUInteger indentsForward = hasTableOrCollectionView ? 2 : 3;

                [viewControllerItem enumerateSelfAndChildren:^(LookinDisplayItem *item) {
                    if (item.hasDeterminedExpansion) {
                        return;
                    }
                    if (item.indentLevel < viewControllerItem.indentLevel + indentsForward) {
                        item.isExpanded = YES;
                        item.hasDeterminedExpansion = YES;
                    }
                }];
            }];
            
            // 剩下未处理的都折叠
            [self.flatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.hasDeterminedExpansion) {
                    return;
                }
                obj.isExpanded = NO;
            }];
            
        } else if (index == 3) {
            // 展开大部分
            [self.flatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.hasDeterminedExpansion) {
                    return;
                }
                obj.isExpanded = YES;
                obj.hasDeterminedExpansion = YES;
            }];
        }
        } // if (keyWindowItem)
    }

    [self buildDisplayingFlatItems];
}

- (LookinDisplayItem *)displayItemWithOid:(unsigned long)oid {
    LookinDisplayItem *item = self.oidToDisplayItemMap[@(oid)];
    return item;
}

- (void)selectAndRevealItem:(LookinDisplayItem *)item {
    if (!item) {
        return;
    }
    if (![self.flatItems containsObject:item]) {
        if (self.state == LKHierarchyDataSourceStateSearch) {
            [self endSearch];
        } else if (self.state == LKHierarchyDataSourceStateFocus) {
            [self endFocus];
        }
    }
    if (![self.flatItems containsObject:item]) {
        return;
    }
    if (!item.displayingInHierarchy) {
        [self expandToShowItem:item];
    }
    self.selectedItem = item;
}

- (NSArray<LookinDisplayItem *> *)swiftUIBackingLayerItemsForItem:(LookinDisplayItem *)item {
    NSMutableArray<LookinDisplayItem *> *result = [NSMutableArray array];
    for (NSString *address in [item lk_swiftUIBackingLayerMemoryAddresses]) {
        LKAddUniqueDisplayItem(result, [self _layerItemWithMemoryAddress:address]);
    }
    for (NSNumber *displayListID in [item lk_swiftUIBackingDisplayListIDs]) {
        LKAddUniqueDisplayItem(result, [self _layerItemWithDisplayListID:displayListID]);
    }
    return result;
}

- (LookinDisplayItem *)swiftUISourceItemForLayerItem:(LookinDisplayItem *)item {
    NSNumber *displayListID = [item lk_swiftUILayerDisplayListID];
    if (!displayListID) {
        return nil;
    }
    return [self _swiftUIItemWithDisplayListID:displayListID] ?: [self _swiftUIItemForLayerItemByFrameAndSource:item];
}

- (LookinDisplayItem *)swiftUIJumpTargetForAttribute:(LookinAttribute *)attribute {
    LookinDisplayItem *sourceItem = attribute.targetDisplayItem;
    if (!sourceItem || ![attribute.value isKindOfClass:NSString.class]) {
        return nil;
    }

    NSString *title = attribute.displayTitle;
    NSString *value = attribute.value;
    BOOL sourceIsSwiftUI = sourceItem.customInfo.isSwiftUI || [sourceItem lk_swiftUIBackingDisplayListIDs].count || [sourceItem lk_swiftUIBackingLayerMemoryAddresses].count;

    if (sourceIsSwiftUI) {
        if ([title hasSuffix:@"Backed By"]) {
            return [self _layerItemWithMemoryAddress:[LookinDisplayItem lk_memoryAddressInObjectDescription:value]];
        }
        if ([title hasSuffix:@"Display List ID"] || [title isEqualToString:@"Identity IDs"]) {
            for (NSNumber *displayListID in [LookinDisplayItem lk_validSwiftUIDisplayListIDsInString:value]) {
                LookinDisplayItem *target = [self _layerItemWithDisplayListID:displayListID];
                if (target) {
                    return target;
                }
            }
            NSInteger layerIndex = LKSwiftUILayerOrdinalFromAttributeTitle(title);
            NSArray<LookinDisplayItem *> *layerItems = [self swiftUIBackingLayerItemsForItem:sourceItem];
            if (layerIndex != NSNotFound && [layerItems lookin_hasIndex:layerIndex]) {
                return layerItems[layerIndex];
            }
        }
        return nil;
    }

    if (sourceItem.layerObject && [title isEqualToString:@"Display List ID"]) {
        NSNumber *displayListID = [LookinDisplayItem lk_validSwiftUIDisplayListIDsInString:value].firstObject;
        if (!displayListID) {
            displayListID = [sourceItem lk_swiftUILayerDisplayListID];
        }
        return [self _swiftUIItemWithDisplayListID:displayListID] ?: [self _swiftUIItemForLayerItemByFrameAndSource:sourceItem];
    }
    return nil;
}

- (void)setRawFlatItems:(NSArray<LookinDisplayItem *> *)rawFlatItems {
    _rawFlatItems = rawFlatItems.copy;
    
    NSMutableDictionary<NSNumber *, LookinDisplayItem *> *map = [NSMutableDictionary dictionaryWithCapacity:rawFlatItems.count * 2];
    [rawFlatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.viewObject.oid) {
            map[@(obj.viewObject.oid)] = obj;
        }
        if (obj.layerObject.oid) {
            map[@(obj.layerObject.oid)] = obj;
        }
        if (obj.windowObject.oid) {
            map[@(obj.windowObject.oid)] = obj;
        }
    }];
    self.oidToDisplayItemMap = map;
}

- (LookinDisplayItem *)_layerItemWithMemoryAddress:(NSString *)memoryAddress {
    if (memoryAddress.length == 0) {
        return nil;
    }
    NSString *normalizedAddress = memoryAddress.lowercaseString;
    for (LookinDisplayItem *item in self.rawFlatItems) {
        if ([item.layerObject.memoryAddress.lowercaseString isEqualToString:normalizedAddress]) {
            return item;
        }
    }
    return nil;
}

- (LookinDisplayItem *)_layerItemWithDisplayListID:(NSNumber *)displayListID {
    if (!displayListID) {
        return nil;
    }
    for (LookinDisplayItem *item in self.rawFlatItems) {
        if (!item.layerObject) {
            continue;
        }
        if ([[item lk_swiftUILayerDisplayListID] isEqualToNumber:displayListID]) {
            return item;
        }
    }
    return nil;
}

- (LookinDisplayItem *)_swiftUIItemWithDisplayListID:(NSNumber *)displayListID {
    if (!displayListID) {
        return nil;
    }
    LookinDisplayItem *result = nil;
    for (LookinDisplayItem *item in self.rawFlatItems) {
        if ([[item lk_swiftUIBackingDisplayListIDs] containsObject:displayListID]) {
            if (!result || item.indentLevel > result.indentLevel) {
                result = item;
            }
        }
    }
    return result;
}

- (LookinDisplayItem *)_swiftUIItemForLayerItemByFrameAndSource:(LookinDisplayItem *)layerItem {
    if (!layerItem.layerObject) {
        return nil;
    }
    CGRect layerFrame = [layerItem calculateFrameToRoot];
    NSArray<NSString *> *sourceTypes = [layerItem lk_swiftUILayerSourceTypeNames];
    LookinDisplayItem *result = nil;
    for (LookinDisplayItem *item in self.rawFlatItems) {
        if (!item.customInfo.isSwiftUI || ![item hasValidFrameToRoot]) {
            continue;
        }
        if (!LKSwiftUIItemMatchesSourceTypes(item, sourceTypes)) {
            continue;
        }
        if (!LKRectsAlmostEqual(layerFrame, [item calculateFrameToRoot])) {
            continue;
        }
        if (!result || item.indentLevel > result.indentLevel) {
            result = item;
        }
    }
    return result;
}

- (void)buildDisplayingFlatItems {
    NSMutableArray<LookinDisplayItem *> *displayingItems = [NSMutableArray array];
    [self.flatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.displayingInHierarchy) {
            [displayingItems addObject:obj];
        }
    }];
    self.displayingFlatItems = displayingItems;
}

- (void)collapseItem:(LookinDisplayItem *)item {
    if (!item.isExpandable) {
        return;
    }
    if (!item.isExpanded) {
        return;
    }
    item.isExpanded = NO;
    [self buildDisplayingFlatItems];
    [self persistExpansionStateToPreferences];
}

- (void)expandItem:(LookinDisplayItem *)item {
    if (!item.isExpandable) {
        return;
    }
    if (item.isExpanded) {
        return;
    }
    item.isExpanded = YES;
    [self buildDisplayingFlatItems];
    [self persistExpansionStateToPreferences];
}

- (void)expandToShowItem:(LookinDisplayItem *)item {
    __block BOOL didChange = NO;
    [item enumerateAncestors:^(LookinDisplayItem *targetItem, BOOL *stop) {
        if (!targetItem.isExpanded) {
            targetItem.isExpanded = YES;
            didChange = YES;
        }
    }];

    [self buildDisplayingFlatItems];
    if (didChange) {
        [self persistExpansionStateToPreferences];
    }
}

- (void)expandItemsRootedByItem:(LookinDisplayItem *)item {
    if (item.preferToBeCollapsed) {
        [item enumerateSelfAndChildren:^(LookinDisplayItem *targetItem) {
            if (targetItem.isExpandable && !targetItem.isExpanded) {
                targetItem.isExpanded = YES;
            }
        }];
    } else {
        [item enumerateSelfAndChildren:^(LookinDisplayItem *targetItem) {
            if (targetItem.isExpandable && !targetItem.isExpanded && ![targetItem preferToBeCollapsed]) {
                targetItem.isExpanded = YES;
            }
        }];
    }

    [self buildDisplayingFlatItems];
    [self persistExpansionStateToPreferences];
}

- (void)collapseAllChildrenOfItem:(LookinDisplayItem *)item {
    [item enumerateSelfAndChildren:^(LookinDisplayItem *enumeratedItem) {
        if (enumeratedItem == item) {
            return;
        }
        if (!enumeratedItem.isExpandable) {
            return;
        }
        if (!enumeratedItem.isExpanded) {
            return;
        }
        enumeratedItem.isExpanded = NO;
    }];
    [self buildDisplayingFlatItems];
    [self persistExpansionStateToPreferences];
}

#pragma mark - Search

- (void)searchWithString:(NSString *)string {
    if (string.length == 0) {
        NSAssert(NO, @"");
        return;
    }
    
    if (self.state != LKHierarchyDataSourceStateSearch) {
        [self.rawFlatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.isExpandedBeforeSearchOrFocus = obj.isExpanded;
        }];
        self.state = LKHierarchyDataSourceStateSearch;
    }
    
    self.selectedItem = nil;
    
    /// 被打上这个标记的都是本次搜索需要在界面中显示出来的（尽管可能会被折叠）
    NSString *Key_ShouldShow = @"show";
    [self.rawFlatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull displayItem, NSUInteger idx, BOOL * _Nonnull stop) {
        // 先
        [displayItem lookin_bindBOOL:NO forKey:Key_ShouldShow];
        displayItem.highlightedSearchString = nil;
    }];
    [self.rawFlatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull displayItem, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isMatched = [displayItem isMatchedWithSearchString:string];
        if (isMatched) {
            displayItem.highlightedSearchString = string;
            [displayItem enumerateAncestors:^(LookinDisplayItem *ancestor, BOOL *stop) {
                // 上级元素都显示且展开
                ancestor.isExpanded = YES;
                [ancestor lookin_bindBOOL:YES forKey:Key_ShouldShow];
            }];
            [displayItem enumerateSelfAndChildren:^(LookinDisplayItem *selfOrChild) {
                // 自身和下级元素都显示但折叠，允许用户手动展开
                selfOrChild.isExpanded = NO;
                [selfOrChild lookin_bindBOOL:YES forKey:Key_ShouldShow];
            }];
        }
    }];
    
    NSArray<LookinDisplayItem *> *flatItems = [self.rawFlatItems lookin_filter:^BOOL(LookinDisplayItem *displayItem) {
        BOOL shouldShow = [displayItem lookin_getBindBOOLForKey:Key_ShouldShow];
        if (shouldShow) {
            displayItem.isInSearch = YES;
        }
        return shouldShow;
    }];
    self.flatItems = flatItems;
    [self.didReloadFlatItemsWithSearchOrFocus sendNext:nil];
    
    [self buildDisplayingFlatItems];
}

// 有可能从 normal 状态或 search 状态进入该状态
- (void)focusDisplayItem:(LookinDisplayItem *)item {
    if (!item) {
        NSAssert(NO, @"");
        return;
    }

    if (self.state == LKHierarchyDataSourceStateNormal) {
        [self.rawFlatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.isExpandedBeforeSearchOrFocus = obj.isExpanded;
        }];
    } else if (self.state == LKHierarchyDataSourceStateSearch) {
        [self.rawFlatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.isInSearch = NO;
            obj.highlightedSearchString = nil;
        }];
    }
    self.state = LKHierarchyDataSourceStateFocus;

    NSMutableArray *newFlatItems = [NSMutableArray array];
    [item enumerateSelfAndChildren:^(LookinDisplayItem *currItem) {
        [newFlatItems addObject:currItem];
    }];
    self.flatItems = newFlatItems;
    [self.didReloadFlatItemsWithSearchOrFocus sendNext:nil];
    [self buildDisplayingFlatItems];
}

- (void)endFocus {
    if (self.state == LKHierarchyDataSourceStateNormal) {
        return;
    }
    self.state = LKHierarchyDataSourceStateNormal;
    
    [self.rawFlatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.isExpanded = obj.isExpandedBeforeSearchOrFocus;
    }];
    
    self.flatItems = self.rawFlatItems;
    [self.didReloadFlatItemsWithSearchOrFocus sendNext:nil];
    [self buildDisplayingFlatItems];
}

- (void)endSearch {
    if (self.state == LKHierarchyDataSourceStateNormal) {
        return;
    }
    self.state = LKHierarchyDataSourceStateNormal;
    
    [self.rawFlatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.isInSearch = NO;
        obj.highlightedSearchString = nil;
        obj.isExpanded = obj.isExpandedBeforeSearchOrFocus;
    }];
    /// 搜索时被选中的 item，在结束搜索后也应该处于被选中且可见的状态
    [self.selectedItem enumerateAncestors:^(LookinDisplayItem *item, BOOL *stop) {
        item.isExpanded = YES;
    }];
    
    self.flatItems = self.rawFlatItems;
    [self.didReloadFlatItemsWithSearchOrFocus sendNext:nil];
    
    [self buildDisplayingFlatItems];
}

#pragma mark - Colors

- (NSArray<NSString *> *)aliasForColor:(NSColor *)color {
    if (!color) {
        return nil;
    }
    NSString *rgbaString = color.rgbaString;
    NSArray<NSString *> *names = self.colorToAliasMap[rgbaString];
    return names;
}

- (void)_setUpColors {
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *colorToAliasMap = [NSMutableDictionary dictionary];
    /// 成员可能是 LKSelectColorItem 和 LKSelectColorItemsSection 混杂在一起
    NSMutableArray *aliasColorItemsOrSections = [NSMutableArray array];
    
    /**
     hierarchyInfo.colorAlias 可以有三种结构：
     1）key 是颜色别名，value 是 UIColor/NSColor。即 <NSString *, Color *>
     2）key 是一组颜色的标题，value 是 NSDictionary，而这个 NSDictionary 的 key 是颜色别名，value 是 UIColor / NSColor。即 <NSString *, NSDictionary<NSString *, Color *> *>
     3）以上两者混在一起
     */
    [self.rawHierarchyInfo.colorAlias enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull colorOrDict, BOOL * _Nonnull stop) {
        if ([colorOrDict isKindOfClass:[NSColor class]]) {
            NSString *colorDesc = [((NSColor *)colorOrDict) rgbaString];
            if (colorDesc) {
                if (!colorToAliasMap[colorDesc]) {
                    colorToAliasMap[colorDesc] = [NSMutableArray array];
                }
                [colorToAliasMap[colorDesc] addObject:key];
            }
            
            [aliasColorItemsOrSections addObject:[LKSelectColorItem itemWithTitle:key color:(NSColor *)colorOrDict]];
            
        } else if ([colorOrDict isKindOfClass:[NSDictionary class]]) {
            LKSelectColorItemsSection *section = [LKSelectColorItemsSection new];
            section.title = key;
            NSMutableArray<LKSelectColorItem *> *aliasItems = [NSMutableArray array];
            
            [((NSDictionary *)colorOrDict) enumerateKeysAndObjectsUsingBlock:^(NSString *colorAliaName, NSColor *colorObj, BOOL * _Nonnull stop) {
                NSString *colorDesc = colorObj.rgbaString;
                if (colorDesc) {
                    if (!colorToAliasMap[colorDesc]) {
                        colorToAliasMap[colorDesc] = [NSMutableArray array];
                    }
                    [colorToAliasMap[colorDesc] addObject:colorAliaName];
                }
                
                [aliasItems addObject:[LKSelectColorItem itemWithTitle:colorAliaName color:colorObj]];
            }];
            
            if (aliasItems.count) {
                section.items = aliasItems;
                [aliasColorItemsOrSections addObject:section];
            }
            
        } else {
            NSAssert(NO, @"");
        }
    }];
    
    [aliasColorItemsOrSections sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        if ([obj1 isKindOfClass:[LKSelectColorItem class]]) {
            if ([obj2 isKindOfClass:[LKSelectColorItem class]]) {
                return [((LKSelectColorItem *)obj1).title caseInsensitiveCompare:((LKSelectColorItem *)obj2).title];
            }
            if ([obj2 isKindOfClass:[LKSelectColorItemsSection class]]) {
                return NSOrderedAscending;
            }
        }
        if ([obj1 isKindOfClass:[LKSelectColorItemsSection class]]) {
            if ([obj2 isKindOfClass:[LKSelectColorItem class]]) {
                return NSOrderedDescending;
            }
            if ([obj2 isKindOfClass:[LKSelectColorItemsSection class]]) {
                return [((LKSelectColorItemsSection *)obj1).title caseInsensitiveCompare:((LKSelectColorItemsSection *)obj2).title];
            }
        }
        NSAssert(NO, @"");
        return NSOrderedAscending;
    }];
    
    self.colorToAliasMap = colorToAliasMap;
    self.selectColorMenu = [self _makeMenuWithAliasColorItemsOrSections:aliasColorItemsOrSections usingRGBAFormat:[LKPreferenceManager mainManager].rgbaFormat];
}

- (NSMenu *)_makeMenuWithAliasColorItemsOrSections:(NSArray *)AliasColorItemsOrSections usingRGBAFormat:(BOOL)rgbaFormat {
    NSMutableArray *menuModel = [NSMutableArray array];
    
    [menuModel addObject:[LKSelectColorItem itemWithTitle:@"nil" color:nil]];
    [menuModel addObject:[LKSelectColorItem itemWithTitle:@"clear color" color:LookinColorRGBAMake(0, 0, 0, 0)]];
    
    NSArray<NSColor *> *defaultColors = @[LookinColorMake(0, 0, 0),
                                          LookinColorMake(126, 126, 126),
                                          LookinColorMake(255, 255, 255),
                                          LookinColorRGBAMake(0, 166, 248, .5),
                                          LookinColorMake(253, 62, 0),
                                          LookinColorMake(105, 190, 0),
                                          LookinColorMake(254, 182, 2)];
    NSArray<LKSelectColorItem *> *defaultColorItems = [defaultColors lookin_map:^id(NSUInteger idx, NSColor *value) {
        LKSelectColorItem *item = [LKSelectColorItem new];
        item.color = value;
        if (value) {
            item.title = rgbaFormat ? [value rgbaString]: [value hexString];
        } else {
            item.title = @"nil";
        }
        return item;
    }];
    [menuModel addObjectsFromArray:defaultColorItems];
    
    NSUInteger defaultItemsCount = menuModel.count;
    
    if (AliasColorItemsOrSections) {
        [menuModel addObjectsFromArray:AliasColorItemsOrSections];
    }
    
    NSMenu *menu = [NSMenu new];
    [menuModel enumerateObjectsUsingBlock:^(id itemOrSection, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == defaultItemsCount) {
            [menu addItem:[NSMenuItem separatorItem]];
        }
        
        if ([itemOrSection isKindOfClass:[LKSelectColorItemsSection class]]) {
            LKSelectColorItemsSection *itemsSection = itemOrSection;
            
            NSMenuItem *menuItem = [NSMenuItem new];
            menuItem.image = [[NSImage alloc] initWithSize:NSMakeSize(1, 22)];
            [menu addItem:menuItem];
            menuItem.title = itemsSection.title;
            
            NSMenu *submenu = [NSMenu new];
            [itemsSection.items enumerateObjectsUsingBlock:^(LKSelectColorItem * _Nonnull subAliasItem, NSUInteger idx, BOOL * _Nonnull stop) {
                NSMenuItem *subMenuItem = [self _menuItemFromColorItem:subAliasItem];
                [submenu addItem:subMenuItem];
            }];
            menuItem.submenu = submenu;
            
        } else if ([itemOrSection isKindOfClass:[LKSelectColorItem class]]) {
            NSMenuItem *menuItem = [self _menuItemFromColorItem:itemOrSection];
            [menu addItem:menuItem];
            
        } else {
            NSAssert(NO, @"");
        }
    }];
    
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:({
        NSMenuItem *menuItem = [NSMenuItem new];
        menuItem.image = [[NSImage alloc] initWithSize:NSMakeSize(1, 22)];
        menuItem.title = NSLocalizedString(@"Other…", nil);
        menuItem.tag = self.customColorMenuItemTag;
        menuItem;
    })];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:({
        NSMenuItem *menuItem = [NSMenuItem new];
        menuItem.image = [[NSImage alloc] initWithSize:NSMakeSize(1, 22)];
        if (rgbaFormat) {
            menuItem.title = NSLocalizedString(@"Switch color format to HEX", nil);
        } else {
            menuItem.title = NSLocalizedString(@"Switch color format to RGBA", nil);
        }
        menuItem.tag = self.toggleColorFormatMenuItemTag;
        menuItem;
    })];
    
    return menu;
}

- (NSMenuItem *)_menuItemFromColorItem:(LKSelectColorItem *)item {
    NSImage *image = [LKColorIndicatorLayer imageWithColor:item.color shapeSize:NSMakeSize(20, 20) insets:NSEdgeInsetsMake(4, 5, 4, 6)];
    NSMenuItem *menuItem = [NSMenuItem new];
    menuItem.image = image;
    menuItem.title = item.title;
    menuItem.representedObject = item.color;
    return menuItem;
}

- (NSInteger)customColorMenuItemTag {
    return 10;
}

- (NSInteger)toggleColorFormatMenuItemTag {
    return 11;
}

#pragma mark - Path Identity

+ (NSString *)pathIdentifierForItem:(LookinDisplayItem *)item
                        inRootItems:(NSArray<LookinDisplayItem *> *)rootItems {
    if (!item || rootItems.count == 0) {
        return nil;
    }

    // Walk up to root, recording (class, siblingIndex) segments leaf-first.
    NSMutableArray<NSString *> *segments = [NSMutableArray array];
    LookinDisplayItem *cursor = item;
    while (cursor.superItem) {
        LookinDisplayItem *parent = cursor.superItem;
        NSUInteger siblingIndex = [parent.subitems indexOfObject:cursor];
        if (siblingIndex == NSNotFound) {
            return nil;
        }
        NSString *className = LKDisplayItemPrimaryClassName(cursor);
        if (className.length == 0) {
            return nil;
        }
        [segments addObject:[NSString stringWithFormat:@"%@:%lu", className, (unsigned long)siblingIndex]];
        cursor = parent;
    }

    NSUInteger rootIndex = [rootItems indexOfObject:cursor];
    if (rootIndex == NSNotFound) {
        return nil;
    }

    NSMutableString *path = [NSMutableString stringWithFormat:@"%lu", (unsigned long)rootIndex];
    // segments was filled leaf-first; emit root → leaf order.
    [segments enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString * _Nonnull segment, NSUInteger idx, BOOL * _Nonnull stop) {
        [path appendFormat:@"/%@", segment];
    }];
    return path.copy;
}

- (NSDictionary<NSString *, NSNumber *> *)_collectExpansionStateMap {
    NSArray<LookinDisplayItem *> *rootItems = self.rawHierarchyInfo.displayItems;
    if (rootItems.count == 0) {
        return @{};
    }

    NSMutableDictionary<NSString *, NSNumber *> *expansionState = [NSMutableDictionary dictionary];
    [self.flatItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!obj.isExpandable) {
            return;
        }
        NSString *path = [LKHierarchyDataSource pathIdentifierForItem:obj inRootItems:rootItems];
        if (path) {
            expansionState[path] = @(obj.isExpanded);
        }
    }];
    return expansionState.copy;
}

- (void)persistExpansionStateToPreferences {
    LKPreferenceManager *prefs = self.preferenceManager;
    if (!prefs.rememberExpansionState) {
        return;
    }
    NSString *bundleId = self.rawHierarchyInfo.appInfo.appBundleIdentifier;
    if (bundleId.length == 0) {
        return;
    }
    NSDictionary<NSString *, NSNumber *> *expansionState = [self _collectExpansionStateMap];
    [prefs setExpansionState:expansionState forBundleIdentifier:bundleId];
}

#pragma mark - Others

/// 子类实现该方法
- (LKPreferenceManager *)preferenceManager {
    NSAssert(NO, @"should implement by subclass");
    return nil;
}

- (void)dealloc {
    NSLog(@"%@ dealloc", self.class);
}

- (BOOL)isReadOnly {
    return YES;
}

@end
