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

/// Phase A 引入:由 owner(LKStaticWindowController)注入的 per-instance data source(weak)。
/// 必须在 -setView: 触发前(即 self.view 第一次访问前)注入。
@property(nonatomic, weak) LKStaticHierarchyDataSource *hierarchyDataSource;

/// Phase A 引入:由 owner 注入的 per-instance async update manager(weak)。
@property(nonatomic, weak) LKStaticAsyncUpdateManager *asyncUpdateManager;

/// 获取当前的 hierarchyView
- (LKHierarchyView *)currentHierarchyView;

@end
