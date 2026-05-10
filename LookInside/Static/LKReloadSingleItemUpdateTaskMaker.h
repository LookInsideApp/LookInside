//
//  LKReloadSingleItemUpdateTaskMaker.h
//  LookinClient
//
//  Created by likai.123 on 2024/3/3.
//  Copyright © 2024 hughkli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LookinStaticAsyncUpdateTask.h"

@class LKStaticAsyncUpdateManager;

@interface LKReloadSingleItemUpdateTaskMaker : NSObject

/// Phase A 引入:由调用方传入的 per-instance update manager,用于 isUpdating 检查。
/// 若传 nil 则 fallback 到 +sharedInstance。
+ (NSArray<LookinStaticAsyncUpdateTask *> *)makeWithItem:(LookinDisplayItem *)item
                                            updateManager:(LKStaticAsyncUpdateManager *)updateManager;

@end
