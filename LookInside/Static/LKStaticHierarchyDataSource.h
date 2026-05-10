//
//  LKStaticHierarchyDataSource.h
//  Lookin
//
//  Created by Li Kai on 2018/12/21.
//  https://lookin.work
//

#import "LookinDefines.h"
#import "LKHierarchyDataSource.h"

@class LookinDisplayItemDetail, LookinStaticDisplayItem, LookinAppInfo, LKStaticAsyncUpdateManager;

@interface LKStaticHierarchyDataSource : LKHierarchyDataSource

+ (instancetype)sharedInstance;

@property(nonatomic, strong, readonly) LookinAppInfo *appInfo;

/// 反向引用 owner 链上的 update manager，用于 Phase A 解耦单例(weak,因为 owner 是 windowController)
@property(nonatomic, weak) LKStaticAsyncUpdateManager *asyncUpdateManager;

#pragma mark - Signal

/// 某些 item 的 frame 发生改变
@property(nonatomic, strong, readonly) RACSubject *itemsDidChangeFrame;

- (void)modifyWithDisplayItemDetail:(LookinDisplayItemDetail *)detail;

@end
