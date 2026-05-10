//
//  LKMainViewController.h
//  Lookin
//
//  Created by Li Kai on 2018/8/4.
//  https://lookin.work
//

#import <Cocoa/Cocoa.h>

@class LKPreviewController, LKProgressIndicatorView, LKHierarchyView, LKStaticHierarchyDataSource, LKStaticAsyncUpdateManager;

@interface LKStaticViewController : LKBaseViewController

@property(nonatomic, strong, readonly) LKPreviewController *viewsPreviewController;

@property(nonatomic, strong) LKProgressIndicatorView *progressView;

@property(nonatomic, assign) BOOL showConsole;

/// Per-doc data source. Owner (LKStaticWindowController) supplies it through
/// -initWithHierarchyDataSource:asyncUpdateManager: so it is non-nil during
/// the -setView: path that subscribes to its signals.
@property(nonatomic, weak, readonly) LKStaticHierarchyDataSource *hierarchyDataSource;

/// Per-doc async update manager. Same lifetime guarantee as `hierarchyDataSource`.
@property(nonatomic, weak, readonly) LKStaticAsyncUpdateManager *asyncUpdateManager;

/// Designated initializer. Both arguments must be non-nil; LKBaseViewController
/// triggers -setView: synchronously during -init, and -setView: subscribes to
/// the data source's signals, so they need to be wired before super-init runs.
- (instancetype)initWithHierarchyDataSource:(LKStaticHierarchyDataSource *)dataSource
                          asyncUpdateManager:(LKStaticAsyncUpdateManager *)updateManager;

/// 获取当前的 hierarchyView
- (LKHierarchyView *)currentHierarchyView;

@end
