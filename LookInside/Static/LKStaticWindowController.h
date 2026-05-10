//
//  LKStaticWindowController.h
//  Lookin
//
//  Created by Li Kai on 2018/11/4.
//  https://lookin.work
//

#import "LKWindowController.h"
#import "LKMenuPopoverAppsListController.h"

@class LKStaticViewController, LKStaticHierarchyDataSource, LKStaticAsyncUpdateManager, LKInspectableApp;

@interface LKStaticWindowController : LKWindowController

@property(nonatomic, strong, readonly) LKStaticViewController *viewController;

/// Phase A 引入:per-instance hierarchy data source(由本 windowController 持有)。
@property(nonatomic, strong, readonly) LKStaticHierarchyDataSource *hierarchyDataSource;

/// Phase A 引入:per-instance async update manager(由本 windowController 持有)。
@property(nonatomic, strong, readonly) LKStaticAsyncUpdateManager *asyncUpdateManager;

/// Phase A 引入:由 owner(Phase D 之后是 LookinLiveDocument)注入的 inspectable app(weak)。
/// Phase A 阶段保持为 nil,所有 inspectable app 读取继续兜底到 LKAppsManager.inspectingApp。
@property(nonatomic, weak) LKInspectableApp *inspectableApp;

/// Phase A 引入:返回当前唯一(legacy)的 LKStaticWindowController 实例。
/// 单 App 主流程下该方法返回 launch 完成后创建的那个 windowController;
/// 多 LookinLiveDocument 引入后该方法被废弃(Phase F 删除)。
+ (instancetype)singletonForLegacy;

/// Phase B 引入:Live Doc 创建 windowController 时使用,在标准 -init 之上把
/// inspectableApp 注入到本 controller 与其 asyncUpdateManager 上,这样后续
/// 所有 RPC 调用都通过该 app(而不是回退到 LKAppsManager.inspectingApp)。
- (instancetype)initWithInspectableApp:(LKInspectableApp *)app;

- (void)popupAllInspectableAppsWithSource:(MenuPopoverAppsListControllerEventSource)source;

@end
