//
//  LKHierarchyDataSource.h
//  Lookin
//
//  Created by Li Kai on 2019/5/6.
//  https://lookin.work
//

#import <Foundation/Foundation.h>

@class LookinHierarchyInfo, LookinDisplayItem, LKPreferenceManager, LookinAttribute;

typedef NS_ENUM(NSUInteger, LKHierarchyDataSourceState) {
    LKHierarchyDataSourceStateNormal,
    LKHierarchyDataSourceStateSearch,
    LKHierarchyDataSourceStateFocus,
};

@interface LKHierarchyDataSource : NSObject

/// 业务可以 observe 该属性
@property(nonatomic, assign, readonly) LKHierarchyDataSourceState state;

/**
 如果 keepState 为 YES，则会尽量维持刷新之前的折叠状态和选中态
 */
- (void)reloadWithHierarchyInfo:(LookinHierarchyInfo *)info keepState:(BOOL)keepState;
@property(nonatomic, strong, readonly) RACSubject *willReloadHierarchyInfo;
@property(nonatomic, strong, readonly) RACSubject *didReloadHierarchyInfo;

@property(nonatomic, copy) NSArray<LookinDisplayItem *> *rawFlatItems;

/// 一维数组，包含所有 hierarchy 树中可见和不可见的 displayItems
/// 搜索或聚焦状态下，flatItems 是 rawFlatItems 的子集（normal 状态下，flatItems 和 rawFlatItems 等价）
@property(nonatomic, copy) NSArray<LookinDisplayItem *> *flatItems;

/// 一维数组，只包括在 hierarchy 树中因为未被折叠而可见的 displayItems
/// 业务可以 observe 该属性
@property(nonatomic, copy, readonly) NSArray<LookinDisplayItem *> *displayingFlatItems;

/**
 index 范围：0 ~ 4
 referenceDict 的 key 为结构路径（参见 +pathIdentifierForItem:inRootItems:），value 为 @(YES)/@(NO) 即是否展开，它记录了一组 displayItem 的展开状态
 在调整一个 item 的 expansion 时，如果 referenceDict 中存在这个 item 的记录则会采用 referenceDict 里的数据，否则会重新根据 index 来调整
 */
- (void)adjustExpansionByIndex:(NSInteger)index referenceDict:(NSDictionary<NSString *, NSNumber *> *)referenceDict selectedItem:(LookinDisplayItem **)selectedItem;

/**
 Computes a structural path identifier for `item` using its superItem chain.
 Format: "<rootIndex>/<class>:<siblingIndex>/<class>:<siblingIndex>/..." (left-to-right root → leaf).
 Returns nil if any chain segment lacks a class (typically UserCustom-only nodes), if the
 sibling index is unresolvable, or if `rootItems` is empty.
 */
+ (NSString *)pathIdentifierForItem:(LookinDisplayItem *)item
                        inRootItems:(NSArray<LookinDisplayItem *> *)rootItems;

/// Persists every expandable item's current expand/collapse state to LKPreferenceManager,
/// keyed by the current target app's bundle identifier. Records both YES (expanded) and
/// NO (collapsed) entries so cold reloads can restore user-driven collapses, not just
/// expansions. No-ops when the rememberExpansionState toggle is OFF or the bundle
/// identifier is empty.
- (void)persistExpansionStateToPreferences;

/// 当前应该被显示的 rows 行数
- (NSInteger)numberOfRows;

/// 获取指定行的 item
- (LookinDisplayItem *)itemAtRow:(NSInteger)index;

/// 获取指定 item 的 row，可能为 NSNotFound
- (NSInteger)rowForItem:(LookinDisplayItem *)item;

/// 当前选中的 item
@property(nonatomic, weak) LookinDisplayItem *selectedItem;

/// 当前被鼠标 hover 的 item
@property(nonatomic, weak) LookinDisplayItem *hoveredItem;

/// 某个颜色的业务别名，如果不存在则返回 nil
- (NSArray<NSString *> *)aliasForColor:(NSColor *)color;
/// 在 dashboard 里选择颜色时弹出的 menu
@property(nonatomic, strong, readonly) NSMenu *selectColorMenu;
/// 该 tag 标示这个 menuItem 是“自定义……”那个选项
@property(nonatomic, assign, readonly) NSInteger customColorMenuItemTag;
/// The menu tag of "switch color format"
@property(nonatomic, assign, readonly) NSInteger toggleColorFormatMenuItemTag;

/// 将 item 折叠起来，如果该 item 没有 subitems 或已经被折叠，则该方法不起任何作用
- (void)collapseItem:(LookinDisplayItem *)item;

/// 将 item 展开，如果该 item 没有 subitems 或已经被展开，则该方法不起任何作用
- (void)expandItem:(LookinDisplayItem *)item;

/// 如果 item 在 hierarchy 中可见则该方法不执行任何操作，否则会将 item 的所有上级元素展开以显示 item
- (void)expandToShowItem:(LookinDisplayItem *)item;
/// 把 item 及所有后代元素全部展开
- (void)expandItemsRootedByItem:(LookinDisplayItem *)item;
/// 把 item 所有后代元素全部折叠（但是不折叠 item 自身）
- (void)collapseAllChildrenOfItem:(LookinDisplayItem *)item;

/// 通过 oid 找到对应的 displayItem
- (LookinDisplayItem *)displayItemWithOid:(unsigned long)oid;

/// 选择目标 item，并确保它的祖先在 hierarchy 中展开可见。
- (void)selectAndRevealItem:(LookinDisplayItem *)item;

/// SwiftUI 节点 -> 已匹配的 CALayer 节点。返回空数组表示没有可跳转目标。
- (NSArray<LookinDisplayItem *> *)swiftUIBackingLayerItemsForItem:(LookinDisplayItem *)item;

/// CALayer 节点 -> 对应的 SwiftUI 节点。返回 nil 表示没有可跳转目标。
- (LookinDisplayItem *)swiftUISourceItemForLayerItem:(LookinDisplayItem *)item;

/// Dashboard row -> 对应的 SwiftUI/CALayer 跳转目标。返回 nil 表示该 row 不支持跳转。
- (LookinDisplayItem *)swiftUIJumpTargetForAttribute:(LookinAttribute *)attribute;

@property(nonatomic, strong, readonly) LookinHierarchyInfo *rawHierarchyInfo;

/// 某个 item 的 isHidden 或 alpha 发生改变
@property(nonatomic, strong, readonly) RACSubject *itemDidChangeHiddenAlphaValue;
/// 某个 item 的 attrGroup 改变
@property(nonatomic, strong, readonly) RACSubject *itemDidChangeAttrGroup;

@property(nonatomic, strong, readonly) RACSubject *itemDidChangeNoPreview;

/// 子类实现该方法
- (LKPreferenceManager *)preferenceManager;

/// 当该属性为 YES 时，表示正处于 dashboard 搜索状态中，此时 preview 界面不应该响应图层点击
@property(nonatomic, assign) BOOL shouldAvoidChangingPreviewSelectionDueToDashboardSearch;

@property(nonatomic, assign, readonly) BOOL serverSideIsSwiftProject;

/// 只读模式下（比如打开一个文件），该方法返回 YES
- (BOOL)isReadOnly;

- (void)buildDisplayingFlatItems;

#pragma mark - Search or Focus

/// 应该在用户输入搜索词时调用该方法，内部会直接更改 flatItems 和 displayingFlatItems 对象
/// string 不能为 nil 或空字符串
- (void)searchWithString:(NSString *)string;


/// 应该在点击搜索框的关闭按钮时调用该方法，用来恢复搜索前的状态等一系列工作
- (void)endSearch;

/// 由于搜索或 Focus 而修改了 flatItems
@property(nonatomic, strong, readonly) RACSubject *didReloadFlatItemsWithSearchOrFocus;

- (void)focusDisplayItem:(LookinDisplayItem *)item;
- (void)endFocus;

@end
