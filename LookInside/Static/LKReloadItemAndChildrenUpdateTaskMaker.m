//
//  LKReloadItemAndChildrenUpdateTaskMaker.m
//  LookinClient
//
//  Created by likai.123 on 2024/3/3.
//  Copyright © 2024 hughkli. All rights reserved.
//

#import "LKReloadItemAndChildrenUpdateTaskMaker.h"
#import "LKStaticAsyncUpdateManager.h"
#import "LKInspectableApp.h"
#import "LKVersionComparer.h"
#import "LookinDisplayItem+LookinClient.h"
#import "LookInside-Swift.h"

@implementation LKReloadItemAndChildrenUpdateTaskMaker

+ (NSArray<LookinStaticAsyncUpdateTask *> *)makeWithItem:(LookinDisplayItem *)item
                                            updateManager:(LKStaticAsyncUpdateManager *)updateManager {
    LKStaticAsyncUpdateManager *resolvedManager = updateManager ?: [LKStaticAsyncUpdateManager sharedInstance];
    if (!item || resolvedManager.isUpdating) {
        NSAssert(NO, @"");
        return nil;
    }
    // Phase F: read the per-doc inspectable app via the update manager
    // owner chain instead of the deprecated single-slot global.
    LookinAppInfo *currentAppInfo = resolvedManager.inspectableApp.appInfo;
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
    BOOL prefersViewOID = [LKHelper appInfoLooksLikeMacTarget:currentAppInfo];
    unsigned long oid = [item bestObjectOidPreferView:prefersViewOID];
    if (!oid) {
        return nil;
    }
    LookinStaticAsyncUpdateTask *task = [LookinStaticAsyncUpdateTask new];
    task.oid = oid;
    task.taskType = LookinStaticAsyncUpdateTaskTypeNoScreenshot;
    task.attrRequest = LookinDetailUpdateTaskAttrRequest_NotNeed;
    task.needBasisVisualInfo = YES;
    task.needSubitems = YES;
    task.frameSize = item.frame.size;
    task.clientReadableVersion = [LKHelper lookinReadableVersion];
    return @[task];
}

@end
