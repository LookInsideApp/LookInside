//
//  LKStaticWindowController.h
//  Lookin
//
//  Created by Li Kai on 2018/11/4.
//  https://lookin.work
//

#import "LKWindowController.h"
#import "LKMenuPopoverAppsListController.h"

@class LKStaticViewController, LKStaticHierarchyDataSource, LKStaticAsyncUpdateManager, LKInspectableApp, RACSignal, LKInspectionSession;

/// Error domain for the refusals `-reloadHierarchySignal` raises on its own
/// behalf. Errors forwarded from the Peertalk round-trip keep their original
/// `LookinErrorDomain` code, so callers can tell "the host would not start a
/// reload" apart from "the target app failed the reload".
extern NSErrorDomain const LKStaticWindowControllerReloadErrorDomain;

/// Who asked for a hierarchy reload. Recorded on the window controller at
/// the moment a reload actually begins, so an observer of the data
/// source's `didReloadHierarchyInfo` can attribute the reload it just saw.
///
/// Reading it is race-free because the reload gate serializes reloads: a
/// second request cannot start while one is in flight, so the value can
/// only change between reloads, never during one.
typedef NS_ENUM(NSInteger, LKHierarchyReloadInitiator) {
    /// A person acted in the inspector -- the toolbar button, the menu
    /// item, or an automatic reload the host decided on.
    LKHierarchyReloadInitiatorHost = 0,
    /// A bridge client asked for it (the MCPBridge `hierarchy.refresh`
    /// route). Clients filter on this to ignore their own echo.
    LKHierarchyReloadInitiatorAgent = 1,
};

typedef NS_ENUM(NSInteger, LKStaticWindowControllerReloadErrorCode) {
    /// A hierarchy fetch is already in flight on this window.
    LKStaticWindowControllerReloadErrorAlreadyInProgress = 1,
    /// The async detail sync is running. Reloading now would throw away
    /// work already paid for, so the caller has to stop it first.
    LKStaticWindowControllerReloadErrorDetailSyncInProgress = 2,
    /// No inspectable app is bound to this window.
    LKStaticWindowControllerReloadErrorNoInspectableApp = 3,
    /// The window went away while the fetch was in flight, leaving no data
    /// source to absorb the result.
    LKStaticWindowControllerReloadErrorWindowClosed = 4,
    /// The fetch finished without ever delivering a hierarchy and without
    /// reporting an error -- reachable when the Peertalk channel tears down
    /// mid-request. Distinct from `WindowClosed`: the window is still here,
    /// the target app simply never answered.
    LKStaticWindowControllerReloadErrorNoResponse = 5,
};

@interface LKStaticWindowController : LKWindowController

@property(nonatomic, strong, readonly) LKStaticViewController *viewController;

/// Phase A 引入:per-instance hierarchy data source(由本 windowController 持有)。
@property(nonatomic, strong, readonly) LKStaticHierarchyDataSource *hierarchyDataSource;

/// Phase A 引入:per-instance async update manager(由本 windowController 持有)。
@property(nonatomic, strong, readonly) LKStaticAsyncUpdateManager *asyncUpdateManager;

/// 由 owner(LookinLiveDocument)注入的 inspectable app(weak)。Phase F 起所有
/// RPC 路径完全依赖该字段,不再有兜底全局。
@property(nonatomic, weak) LKInspectableApp *inspectableApp;
@property(nonatomic, strong) LKInspectionSession *inspectionSession;

/// LookinLiveDocument 创建 windowController 时使用,在标准 -init 之上把
/// inspectableApp 注入到本 controller 与其 asyncUpdateManager 上,这样后续
/// 所有 RPC 调用都通过该 app。
- (instancetype)initWithInspectableApp:(LKInspectableApp *)app;

- (void)popupAllInspectableAppsWithSource:(MenuPopoverAppsListControllerEventSource)source;

/// Reloads this window's hierarchy the way the toolbar reload button does:
/// same re-entrancy gate, same progress indicator, same `keepState:YES`
/// hand-off to the data source. The one thing it does NOT do is put up the
/// modal error sheet — that stays in the button's own handler, so callers
/// arriving from outside the UI (the MCPBridge `hierarchy.refresh` route)
/// can never drop a dialog on a user who did not ask for one.
///
/// The fetch starts when this method is called, not when the returned
/// signal is subscribed to, and the result is replayed to every subscriber.
/// Sends the reloaded `LookinHierarchyInfo` once and completes; by the time
/// that value arrives `hierarchyDataSource` has already absorbed it, so
/// subscribers observe a settled hierarchy rather than racing it.
///
/// Errors either in `LKStaticWindowControllerReloadErrorDomain` (this
/// window refused to start) or in `LookinErrorDomain` (the target app
/// failed the fetch).
///
/// `initiator` is recorded on `lastReloadInitiator` only if the reload
/// actually starts, so a refused request never mislabels the reload that
/// refused it.
- (RACSignal *)reloadHierarchySignalWithInitiator:(LKHierarchyReloadInitiator)initiator;

/// Who asked for the most recent reload that actually started. Meaningful
/// from the moment the fetch begins, which is before the data source
/// publishes `didReloadHierarchyInfo` -- so an observer of that subject
/// reads the value belonging to the reload it is being told about.
@property(nonatomic, assign, readonly) LKHierarchyReloadInitiator lastReloadInitiator;

@end
