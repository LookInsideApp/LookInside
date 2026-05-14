//
//  LKPreferenceManager.h
//  Lookin
//
//  Created by Li Kai on 2019/1/8.
//  https://lookin.work
//

#import <Foundation/Foundation.h>
#import "LookinAttributesGroup.h"
#import "LKExportManager.h"
#import "LookinMsgAttribute.h"

extern NSString *const LKWindowSizeName_Dynamic;
extern NSString *const LKWindowSizeName_Static;

/// 初始的 preview scale
extern const CGFloat LKInitialPreviewScale;

/// 默认的层级请求超时时间，单位秒。
extern const NSTimeInterval LKDefaultHierarchyRequestTimeoutInterval;
extern const NSTimeInterval LKDefaultLicenseHandshakeTimeoutInterval;

typedef NS_ENUM(NSInteger, LookinPreferredAppeanranceType) {
    LookinPreferredAppeanranceTypeDark,
    LookinPreferredAppeanranceTypeLight,
    LookinPreferredAppeanranceTypeSystem
};


typedef NS_ENUM(NSInteger, LookinDoubleClickBehavior) {
    LookinDoubleClickBehaviorCollapse,
    LookinDoubleClickBehaviorFocus
};

typedef NS_ENUM(NSInteger, LookinPreferredCallStackType) {
    LookinPreferredCallStackTypeDefault,    // 格式化 + 简略
    LookinPreferredCallStackTypeFormattedCompletely, // 格式化 + 完整
    LookinPreferredCallStackTypeRaw    // 原始堆栈
};

typedef NS_ENUM(NSInteger, LookinMeasureState) {
    LookinMeasureState_no,    // 没有处于测距模式
    LookinMeasureState_unlocked, // 处于测距模式，但未锁定，此时松开手指就会导致退出测距模式
    LookinMeasureState_locked    // 处于测距模式，且锁定，此时松开手指不会退出测距模式
};

@interface LKPreferenceManager : NSObject

+ (instancetype)mainManager;

/// 默认为 NO
@property(nonatomic, assign) BOOL shouldStoreToLocal;

/// 仅在 macOS 10.14 及以后上生效
@property(nonatomic, assign) LookinPreferredAppeanranceType appearanceType;

@property(nonatomic, assign) LookinDoubleClickBehavior doubleClickBehavior;

/// 有效值为 0 ～ 4
@property(nonatomic, assign) NSInteger expansionIndex;

@property(nonatomic, strong, readonly) LookinBOOLMsgAttribute *showOutline;

@property(nonatomic, strong, readonly) LookinBOOLMsgAttribute *showHiddenItems;

// 范围是 0 ～ 1
@property(nonatomic, strong, readonly) LookinDoubleMsgAttribute *zInterspace;

@property(nonatomic, assign) BOOL rgbaFormat;

/// 0 ~ 2
@property(nonatomic, assign) NSInteger imageContrastLevel;

/// 是否自动将选中的 UIView/CALayer 作为控制台的目标对象
@property(nonatomic, assign) BOOL syncConsoleTarget;

/// 是否按目标 App bundle id 持久化层级折叠状态。默认 YES。
/// 关闭后已存储的折叠状态保留在磁盘上，仅停止读取和写入。
@property(nonatomic, assign) BOOL rememberExpansionState;

/// 读取某 bundle id 下记录的展开/折叠状态。key 为结构路径，value 为 @(YES) 表示展开、@(NO) 表示折叠。
/// 未命中返回空字典。为兼容早期仅记录 expanded paths 的存档（NSArray<NSString *>），
/// 读到旧格式时会自动转换为 dict 形式（全部视为 @(YES)）。
- (NSDictionary<NSString *, NSNumber *> *)expansionStateForBundleIdentifier:(NSString *)bundleIdentifier;

/// 写入某 bundle id 下记录的展开/折叠状态，并将该 bundle id 提升到 LRU 队首。
/// 当 LRU 超过容量上限时，最旧的 bundle id 会被静默移除（其对应的展开状态键也会被清理）。
/// 若 rememberExpansionState 为 NO 或 bundleIdentifier 为空，则不做任何操作。
- (void)setExpansionState:(NSDictionary<NSString *, NSNumber *> *)expansionState forBundleIdentifier:(NSString *)bundleIdentifier;

/// 将一个已记录的 bundle id 提升到 LRU 队首。若该 bundle id 未被记录则不做任何操作。
/// 当 rememberExpansionState 为 NO 或 bundleIdentifier 为空时同样不做任何操作。
- (void)bumpExpansionStateBundleIdentifierToMostRecent:(NSString *)bundleIdentifier;

// 被折叠的 AttrGroup
@property(nonatomic, copy) NSArray<LookinAttrGroupIdentifier> *collapsedAttrGroups;

@property(nonatomic, assign) CGFloat preferredExportCompression;

@property(nonatomic, assign) NSTimeInterval hierarchyRequestTimeoutInterval;

@property(nonatomic, assign) NSTimeInterval licenseHandshakeTimeoutInterval;

@property(nonatomic, strong, readonly) LookinBOOLMsgAttribute *freeRotation;

@property(nonatomic, strong, readonly) LookinBOOLMsgAttribute *fastMode;

/// 上次接收到 iOS app 里传过来的 color config 和 collapsedClasses 信息的时间，用来统计
@property(nonatomic, assign) NSTimeInterval receivingConfigTime_Color;
@property(nonatomic, assign) NSTimeInterval receivingConfigTime_Class;

/// 返回某个 section 是否应该被显示在主界面上
- (BOOL)isSectionShowing:(LookinAttrSectionIdentifier)secID;
/// 把某个 section 显示在主界面上
- (void)showSection:(LookinAttrSectionIdentifier)secID;
/// 把某个 section 从主界面上移除
- (void)hideSection:(LookinAttrSectionIdentifier)secID;
/// 当某个 section 被添加或移除时，会发出该通知
extern NSString *const NotificationName_DidChangeSectionShowing;

#pragma mark - 以下属性不会持久化

@property(nonatomic, assign) LookinPreferredCallStackType callStackType;

@property(nonatomic, strong, readonly) LookinIntegerMsgAttribute *previewDimension;

@property(nonatomic, strong, readonly) LookinDoubleMsgAttribute *previewScale;

/// 参数是 LookinMeasureState
@property(nonatomic, strong, readonly) LookinIntegerMsgAttribute *measureState;

/// 是否用户正在按住 cmd 键而处于快速选择模式
@property(nonatomic, strong, readonly) LookinBOOLMsgAttribute *isQuickSelecting;

- (void)reset;

@end
