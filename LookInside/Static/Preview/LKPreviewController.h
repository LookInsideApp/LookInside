//
//  LKPreviewViewController.h
//  Lookin
//
//  Created by Li Kai on 2018/8/6.
//  https://lookin.work
//

#import "LKBaseViewController.h"

@class LKHierarchyDataSource, LKStaticViewController, LKStaticAsyncUpdateManager;

@interface LKPreviewController : LKBaseViewController

- (instancetype)initWithDataSource:(LKHierarchyDataSource *)dataSource;

@property(nonatomic, weak) LKStaticViewController *staticViewController;

/// Phase A 引入:由 owner 注入的 per-instance update manager(weak)。
/// 仅在 live workspace 路径下用到;archive 路径下保持 nil。
@property(nonatomic, weak) LKStaticAsyncUpdateManager *asyncUpdateManager;

@end
