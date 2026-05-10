//
//  LKDeviceManager.m
//  Lookin
//
//  Created by Li Kai on 2018/11/3.
//  https://lookin.work
//

#import "LKAppsManager.h"
#import "Lookin_PTChannel.h"
#import "LKConnectionManager.h"
#import "LookinDefines.h"
#import "LookinAppInfo.h"
#import "LookinHierarchyInfo.h"
#import "LookinConnectionResponseAttachment.h"

NSString *const LKInspectingAppDidEndNotificationName = @"LKInspectingAppDidEndNotificationName";

@interface LKAppsManager ()

@property(nonatomic, strong) RACSubject *willConnectToApp;

@end

@implementation LKAppsManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static LKAppsManager *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone{
    return [self sharedInstance];
}

- (instancetype)init {
    if (self = [super init]) {
        // Phase D: subjects survive only so deprecated readers (and the
        // dead-code `setInspectingApp:` below) don't crash on nil. Phase F
        // removes them outright.
        _willConnectToApp = [RACSubject subject];
        _didAutoReconnectSucc = [RACSubject subject];
        // Phase D: the global `channelWillEnd` auto-reconnect pipeline used
        // to live here. It was tied to the single `self.inspectingApp` slot
        // and is incompatible with multiple Live Docs each owning their own
        // channel. Reconnect responsibility now lives in
        // `LookinLiveDocument._lk_subscribeChannelLifecycle`, which scopes
        // each subscription to one doc's channel.
    }
    return self;
}

- (void)setInspectingApp:(LKInspectableApp *)inspectingApp {
    BOOL shouldPostNotification = (_inspectingApp && !inspectingApp);
    
    _inspectingApp = inspectingApp;
    if (inspectingApp) {
        [self.willConnectToApp sendNext:inspectingApp];
    }
    
    if (shouldPostNotification) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LKInspectingAppDidEndNotificationName object:self];
    }
}

// Phase D: `_fetchInspectableAppWithSimilarInfo:` was the helper used by the
// deleted global auto-reconnect pipeline. The equivalent logic now lives in
// `LookinLiveDocument._lk_fetchInspectableAppMatchingLastKnown`.

- (RACSignal *)fetchAppInfosWithImage:(BOOL)needImages localInfos:(NSArray<LookinAppInfo *> *)localInfos {
    NSArray<LookinAppInfo *> *validAppInfos = [localInfos lookin_filter:^BOOL(LookinAppInfo *info) {
        /// 超过 8 秒则认为过期
        return [[NSDate date] timeIntervalSince1970] - info.cachedTimestamp <= 8;
    }];
    
    NSArray<NSNumber *> *localInfoIdentifiers = [validAppInfos lookin_map:^id(NSUInteger idx, LookinAppInfo *value) {
        return @(value.appInfoIdentifier);
    }] ? : @[];
    NSDictionary *params = @{@"needImages":@(needImages), @"local":localInfoIdentifiers};
    
    return [[[[LKConnectionManager sharedInstance] tryToConnectAllPorts] flattenMap:^__kindof RACSignal * _Nullable(NSArray<Lookin_PTChannel *> *connectedChannels) {
        if (!connectedChannels.count) {
            // 没有任何 channel
            return [RACSignal return:nil];
        }
        
        NSArray<RACSignal *> *signals = [connectedChannels lookin_map:^id(NSUInteger idx, Lookin_PTChannel *channel) {
            return [[[LKConnectionManager sharedInstance] requestWithType:LookinRequestTypeApp data:params channel:channel] catch:^RACSignal * _Nonnull(NSError * _Nonnull error) {
                if (error.code == LookinErrCode_ServerVersionTooHigh ||
                    error.code == LookinErrCode_ServerVersionTooLow) {
                    // 这些 Lookin 版本不匹配错误应该被保留，因为业务需要显示这些错误
                    return [RACSignal return:error];
                } else {
                    // 位于后台无法执行代码的 channel 会走到这里，应该过滤掉这些 channel
                    return [RACSignal return:nil];
                }
            }];
        }];
        return [RACSignal zip:signals];
    
    }] map:^id _Nullable(RACTuple * _Nullable x) {
        NSArray<LKInspectableApp *> *apps = [x.allObjects lookin_map:^id(NSUInteger idx, id value) {
            if (value == [NSNull null]) {
                // 位于后台无法执行代码的 app
                return nil;
            }
            
            if ([value isKindOfClass:[NSError class]]) {
                // Lookin 版本不匹配的 app
                LKInspectableApp *app = [[LKInspectableApp alloc] init];
                app.serverVersionError = value;
                return app;
            }
            
            if ([value isKindOfClass:[RACTuple class]]) {
                RACTupleUnpack(LookinConnectionResponseAttachment *response, Lookin_PTChannel *relatedChannel) = value;
                if (response.error) {
                    NSLog(@"LookinClient - app info request failed, domain:%@, code:%@, description:%@",
                          response.error.domain,
                          @(response.error.code),
                          response.error.localizedDescription);
                    if (response.error.code == LookinErrCode_LicenseRequired) {
                        return nil;
                    }
                    LKInspectableApp *app = [[LKInspectableApp alloc] init];
                    app.serverVersionError = response.error;
                    app.channel = relatedChannel;
                    return app;
                } else {
                    LookinAppInfo *receivedInfo = response.data;
                    receivedInfo.cachedTimestamp = [[NSDate date] timeIntervalSince1970];
                    if (receivedInfo.shouldUseCache) {
                        // 使用之前拉取的旧 info
                        LookinAppInfo *localInfo = [validAppInfos lookin_firstFiltered:^BOOL(LookinAppInfo *obj) {
                            return obj.appInfoIdentifier == receivedInfo.appInfoIdentifier;
                        }];
                        if (localInfo) {
                            receivedInfo = localInfo;
                        }
                    }
                    
                    LKInspectableApp *app = [[LKInspectableApp alloc] init];
                    app.appInfo = receivedInfo;
                    app.channel = relatedChannel;
                    return app;
                }
            }
            
            NSAssert(NO, @"");
            return nil;
        }];
        return apps;
    }];
}

@end
