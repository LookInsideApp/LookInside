//
//  LKReloadSingleItemUpdateTaskMaker.m
//  LookinClient
//
//  Created by likai.123 on 2024/3/3.
//  Copyright © 2024 hughkli. All rights reserved.
//

#import "LKReloadSingleItemUpdateTaskMaker.h"
#import "LKStaticAsyncUpdateManager.h"
#import "LKInspectableApp.h"
#import "LKVersionComparer.h"
#import "LookinDisplayItem+LookinClient.h"
#import "LookInside-Swift.h"

@implementation LKReloadSingleItemUpdateTaskMaker

+ (NSArray<LookinStaticAsyncUpdateTask *> *)makeWithItem:(LookinDisplayItem *)item
                                            updateManager:(LKStaticAsyncUpdateManager *)updateManager {
    if (!item || updateManager.isUpdating) {
        NSAssert(NO, @"");
        return nil;
    }
    LookinAppInfo *currentAppInfo = updateManager.inspectableApp.appInfo;
    NSString *serverVersion = currentAppInfo.serverReadableVersion;
    BOOL supported = [LKVersionComparer compareWithExpectedVersion:@"1.2.7" realVersion:serverVersion];
    if (!supported) {
        AlertErrorText(NSLocalizedString(@"Operation failed.", nil), NSLocalizedString(@"Please upgrade the LookinServer SDK version in your iOS project to 1.2.7 or higher.", nil), CurrentKeyWindow);
        return nil;
    }
    if ([LKHelper appInfoLooksLikeMacTarget:currentAppInfo] &&
        [item lk_isSwiftUISupportRelated] &&
        ![[LKSwiftUISupportGatekeeper sharedInstance] allowProtectedFeatureAccessForWindow:CurrentKeyWindow]) {
        return nil;
    }
    NSMutableArray<LookinStaticAsyncUpdateTask *> *tasks = [NSMutableArray array];

    if (item.doNotFetchScreenshotReason == LookinFetchScreenshotPermitted) {
        LookinStaticAsyncUpdateTask *task = [self taskFromItem:item appInfo:currentAppInfo];
        if (task) {
            task.taskType = LookinStaticAsyncUpdateTaskTypeGroupScreenshot;
            [tasks addObject:task];
        }

        if (item.isExpandable) {
            LookinStaticAsyncUpdateTask *task2 = [self taskFromItem:item appInfo:currentAppInfo];
            if (task2) {
                task2.taskType = LookinStaticAsyncUpdateTaskTypeSoloScreenshot;
                [tasks addObject:task2];
            }
        }
    } else {
        LookinStaticAsyncUpdateTask *task = [self taskFromItem:item appInfo:currentAppInfo];
        if (task) {
            task.taskType = LookinStaticAsyncUpdateTaskTypeNoScreenshot;
            [tasks addObject:task];
        }
    }
    [tasks firstObject].needBasisVisualInfo = YES;
    return tasks;
}

+ (LookinStaticAsyncUpdateTask *)taskFromItem:(LookinDisplayItem *)item appInfo:(LookinAppInfo *)appInfo {
    BOOL prefersViewOID = [LKHelper appInfoLooksLikeMacTarget:appInfo];
    unsigned long oid = [item bestObjectOidPreferView:prefersViewOID];
    if (!oid) {
        return nil;
    }
    LookinStaticAsyncUpdateTask *task = [LookinStaticAsyncUpdateTask new];
    task.oid = oid;
    task.frameSize = item.frame.size;
    task.clientReadableVersion = [LKHelper lookinReadableVersion];
    return task;
}

@end
