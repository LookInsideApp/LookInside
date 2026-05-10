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

/// 由 owner(LookinLiveDocument)注入的 inspectable app(weak)。Phase F 起所有
/// RPC 路径完全依赖该字段,不再有兜底全局。
@property(nonatomic, weak) LKInspectableApp *inspectableApp;

/// Phase A 引入:返回 +sharedInstance 兼容路径仍在使用的 windowController 实例。
/// Phase F 起 Live Doc 主流程不再依赖该字段;它仅服务于
/// `LKStaticHierarchyDataSource +sharedInstance` / `LKStaticAsyncUpdateManager +sharedInstance`
/// 兼容入口的 fallback,以及"Open in New Window"等已分离场景。
+ (instancetype)singletonForLegacy;

/// LookinLiveDocument 创建 windowController 时使用,在标准 -init 之上把
/// inspectableApp 注入到本 controller 与其 asyncUpdateManager 上,这样后续
/// 所有 RPC 调用都通过该 app。
- (instancetype)initWithInspectableApp:(LKInspectableApp *)app;

- (void)popupAllInspectableAppsWithSource:(MenuPopoverAppsListControllerEventSource)source;

@end
