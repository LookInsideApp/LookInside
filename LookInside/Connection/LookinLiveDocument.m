//
//  LookinLiveDocument.m
//  LookInside
//

#import "LookinLiveDocument.h"
#import "LKInspectableApp.h"
#import "LKStaticHierarchyDataSource.h"
#import "LKStaticAsyncUpdateManager.h"
#import "LKStaticWindowController.h"
#import "LKAppsManager.h"
#import "LKConnectionManager.h"
#import "Lookin_PTChannel.h"
#import "LookinAppInfo.h"
#import "LookinHierarchyInfo.h"
#import "LKExportManager.h"
#import "LookinDefines.h"

@interface LookinLiveDocument ()

/// Internal readwrite override of the public readonly property. Phase D
/// auto-reconnect replaces this when the original channel dies and a
/// matching app reappears.
@property(nonatomic, strong, readwrite) LKInspectableApp *inspectableApp;

/// Subscription that fires once when the current `inspectableApp.channel`
/// is reported as ending by `LKConnectionManager.channelWillEnd`. Replaced
/// after a successful reconnect because the new app carries a different
/// channel identity.
@property(nonatomic, strong) RACDisposable *channelDidEndDisposable;

/// Periodic `fetchAppInfosWithImage:NO` poll that runs while the doc is
/// disconnected. Disposed on close, on successful reconnect, or when the
/// channel comes back via a new path.
@property(nonatomic, strong) RACDisposable *reconnectAttemptDisposable;

/// Snapshot of the previously-connected app info, used to match the same
/// logical iOS/macOS process across reconnects via
/// `-isEqualToAppInfo:`. Captured the moment the channel ends so it is
/// not affected by future replacements.
@property(nonatomic, strong) LookinAppInfo *lastKnownAppInfo;

@property(nonatomic, copy, readwrite, nullable) NSString *connectionLossBannerMessage;

@end

@implementation LookinLiveDocument

- (nullable instancetype)initWithInspectableApp:(LKInspectableApp *)app
                                           error:(NSError *_Nullable *_Nullable)outError {
    if (!app) {
        if (outError) {
            *outError = LookinErr_Inner;
        }
        return nil;
    }
    if (self = [super init]) {
        _inspectableApp = app;
        [self _lk_subscribeChannelLifecycle];
    }
    return self;
}

+ (instancetype)documentInWindow:(NSWindow *)window {
    if (!window) {
        return nil;
    }
    NSDocument *doc = [[NSDocumentController sharedDocumentController] documentForWindow:window];
    if ([doc isKindOfClass:[LookinLiveDocument class]]) {
        return (LookinLiveDocument *)doc;
    }
    return nil;
}

- (LKStaticHierarchyDataSource *)hierarchyDataSource {
    LKStaticWindowController *wc = (LKStaticWindowController *)self.windowControllers.firstObject;
    if ([wc isKindOfClass:[LKStaticWindowController class]]) {
        return wc.hierarchyDataSource;
    }
    return nil;
}

- (LKStaticAsyncUpdateManager *)asyncUpdateManager {
    LKStaticWindowController *wc = (LKStaticWindowController *)self.windowControllers.firstObject;
    if ([wc isKindOfClass:[LKStaticWindowController class]]) {
        return wc.asyncUpdateManager;
    }
    return nil;
}

#pragma mark - NSDocument overrides

- (NSString *)displayName {
    LookinAppInfo *info = self.inspectableApp.appInfo;
    if (info.appName.length && info.deviceDescription.length) {
        return [NSString stringWithFormat:@"%@ — %@", info.appName, info.deviceDescription];
    } else if (info.appName.length) {
        return info.appName;
    }
    return [super displayName];
}

- (BOOL)hasUnautosavedChanges {
    return NO;
}

- (BOOL)isDocumentEdited {
    return NO;
}

+ (BOOL)autosavesInPlace {
    return NO;
}

+ (BOOL)autosavesDrafts {
    return NO;
}

+ (BOOL)preservesVersions {
    return NO;
}

+ (BOOL)usesUbiquitousStorage {
    return NO;
}

- (NSArray<NSString *> *)writableTypesForSaveOperation:(NSSaveOperationType)saveOperation {
    if (saveOperation == NSSaveAsOperation) {
        return @[@"com.lookin.lookin"];
    }
    return @[];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    if (![typeName isEqualToString:@"com.lookin.lookin"]) {
        if (outError) {
            *outError = LookinErr_Inner;
        }
        return nil;
    }
    LookinHierarchyInfo *info = self.hierarchyDataSource.rawHierarchyInfo;
    if (!info) {
        if (outError) {
            *outError = LookinErr_Inner;
        }
        return nil;
    }
    NSData *data = [[LKExportManager sharedInstance] dataFromHierarchyInfo:info
                                                          imageCompression:1.0
                                                                  fileName:NULL];
    if (!data) {
        if (outError) {
            *outError = LookinErr_Inner;
        }
        return nil;
    }
    return data;
}

- (void)makeWindowControllers {
    LKStaticWindowController *wc = [[LKStaticWindowController alloc] initWithInspectableApp:self.inspectableApp];
    [self addWindowController:wc];
}

- (void)close {
    // Phase D: cancel any in-flight reconnect work *before* the doc is torn
    // down. Channel lifecycle subjects keep weak references to `self`, but
    // disposing here makes the teardown order explicit and avoids one extra
    // tick of work during close.
    [self.channelDidEndDisposable dispose];
    self.channelDidEndDisposable = nil;
    [self.reconnectAttemptDisposable dispose];
    self.reconnectAttemptDisposable = nil;
    [super close];
}

#pragma mark - Phase D: channel lifecycle

- (void)_lk_subscribeChannelLifecycle {
    LKInspectableApp *currentApp = self.inspectableApp;
    Lookin_PTChannel *currentChannel = currentApp.channel;
    if (!currentChannel) {
        // Without a live channel there is nothing to watch for end-of-life;
        // a future reconnect will rewire this when one appears.
        return;
    }

    [self.channelDidEndDisposable dispose];

    @weakify(self);
    RACSignal *currentChannelEnd = [[[LKConnectionManager sharedInstance].channelWillEnd
        filter:^BOOL(Lookin_PTChannel *channel) {
            @strongify(self);
            return channel == self.inspectableApp.channel;
        }] take:1];

    self.channelDidEndDisposable = [currentChannelEnd subscribeNext:^(Lookin_PTChannel *channel) {
        @strongify(self);
        if (!self) {
            return;
        }
        [self _lk_handleChannelDidEnd];
    }];
}

- (void)_lk_handleChannelDidEnd {
    LookinAppInfo *priorInfo = self.inspectableApp.appInfo;
    self.lastKnownAppInfo = priorInfo;

    NSString *appName = priorInfo.appName.length ? priorInfo.appName : NSLocalizedString(@"Inspected app", nil);
    self.connectionLossBannerMessage = [NSString stringWithFormat:
        NSLocalizedString(@"Connection to %@ lost. Trying to reconnect…", nil),
        appName];

    [self _lk_attemptAutoReconnect];
}

- (void)_lk_attemptAutoReconnect {
    if (!self.lastKnownAppInfo) {
        return;
    }

    [self.reconnectAttemptDisposable dispose];

    @weakify(self);
    RACSignal *poll = [[RACSignal interval:3 onScheduler:[RACScheduler scheduler]] flattenMap:^__kindof RACSignal *(NSDate *_Nullable tick) {
        @strongify(self);
        if (!self) {
            return [RACSignal empty];
        }
        return [self _lk_fetchInspectableAppMatchingLastKnown];
    }];

    self.reconnectAttemptDisposable = [poll subscribeNext:^(LKInspectableApp *newApp) {
        @strongify(self);
        if (!self || !newApp) {
            return;
        }
        // Reconnected — rewire identity, clear banner, and resubscribe lifecycle
        // for the *new* channel. The doc's hierarchy data source is reloaded
        // by the caller (toolbar reload, window controller, etc.) the next time
        // a fetch is triggered, so we deliberately do not force a refetch here.
        self.inspectableApp = newApp;
        // The window controller and its async update manager hold
        // `inspectableApp` weakly under the assumption that this doc is
        // the strong owner. Overwriting that strong reference would let the
        // old `LKInspectableApp` deallocate, nilling both weak slots and
        // silently breaking the picker / reload / RPC paths. Republish
        // the new app so the per-window graph stays consistent.
        for (NSWindowController *windowController in self.windowControllers) {
            if (![windowController isKindOfClass:[LKStaticWindowController class]]) {
                continue;
            }
            LKStaticWindowController *staticController = (LKStaticWindowController *)windowController;
            staticController.inspectableApp = newApp;
            staticController.asyncUpdateManager.inspectableApp = newApp;
        }
        self.connectionLossBannerMessage = nil;
        [self.reconnectAttemptDisposable dispose];
        self.reconnectAttemptDisposable = nil;
        [self _lk_subscribeChannelLifecycle];
    }];
}

- (RACSignal *)_lk_fetchInspectableAppMatchingLastKnown {
    LookinAppInfo *targetInfo = self.lastKnownAppInfo;
    if (!targetInfo) {
        return [RACSignal return:nil];
    }
    return [[[[LKAppsManager sharedInstance] fetchAppInfosWithImage:NO localInfos:nil] map:^id _Nullable(NSArray<LKInspectableApp *> *allApps) {
        LKInspectableApp *match = [allApps lookin_firstFiltered:^BOOL(LKInspectableApp *candidate) {
            return [targetInfo isEqualToAppInfo:candidate.appInfo];
        }];
        if (match) {
            // Preserve the previously known app icon — `needImages:NO` means
            // the response carries no icon and we'd otherwise lose it on
            // reconnect.
            match.appInfo.appIcon = targetInfo.appIcon;
        }
        return match;
    }] catch:^RACSignal *(NSError *error) {
        return [RACSignal return:nil];
    }];
}

@end
