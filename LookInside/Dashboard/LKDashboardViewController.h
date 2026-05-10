//
//  LKDashboardViewController.h
//  Lookin
//
//  Created by Li Kai on 2018/8/6.
//  https://lookin.work
//

#import <Cocoa/Cocoa.h>

@class LKHierarchyDataSource, LKStaticHierarchyDataSource, LookinAttribute, LKReadHierarchyDataSource, LookinDisplayItem, LKStaticAsyncUpdateManager;

@interface LKDashboardViewController : LKBaseViewController

- (instancetype)initWithStaticDataSource:(LKStaticHierarchyDataSource *)dataSource;

- (instancetype)initWithReadDataSource:(LKReadHierarchyDataSource *)dataSource;

/// Phase A 引入:由 owner(LKStaticViewController)注入的 per-instance update manager(weak)。
/// Live workspace 触发 modification 时优先用本实例,nil 时回落 +sharedInstance。
@property(nonatomic, weak) LKStaticAsyncUpdateManager *asyncUpdateManager;

- (LKHierarchyDataSource *)currentDataSource;

- (RACSignal *)modifyAttribute:(LookinAttribute *)attribute newValue:(id)newValue;

/// 如果为 YES 则表示当前使用的是 StaticDataSource 而非 ReadDataSource
@property(nonatomic, assign, readonly) BOOL isStaticMode;

@end
