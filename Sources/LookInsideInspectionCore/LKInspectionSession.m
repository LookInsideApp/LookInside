#import "LKInspectionSession.h"
#import "LKInspectionEnvironment.h"
#import "LKInspectionRequestQueue.h"
#import "LKInspectableApp.h"
#import "LKConnectionManager.h"
#import "LKAppsManager.h"
#import "LookinAppInfo.h"
#import "LookinDisplayItem.h"
#import "LookinObject.h"
#import "Lookin_PTChannel.h"
#import "LookinDefines.h"

NSNotificationName const LKInspectionSessionDidOpenNotification = @"LKInspectionSessionDidOpenNotification";
NSNotificationName const LKInspectionSessionDidCloseNotification = @"LKInspectionSessionDidCloseNotification";
NSNotificationName const LKInspectionSessionDidReloadNotification = @"LKInspectionSessionDidReloadNotification";
NSNotificationName const LKInspectionSessionDidDisconnectNotification = @"LKInspectionSessionDidDisconnectNotification";
NSErrorDomain const LKInspectionSessionErrorDomain = @"LKInspectionSessionErrorDomain";

static NSError *LKInspectionSessionError(LKInspectionSessionErrorCode code, NSString *message) {
    return [NSError errorWithDomain:LKInspectionSessionErrorDomain code:code
                          userInfo:@{NSLocalizedDescriptionKey: message}];
}

static NSError *LKInspectionUnknownExecutionError(NSError *underlyingError) {
    return [NSError errorWithDomain:LKInspectionSessionErrorDomain code:LKInspectionSessionErrorExecutionUnknown
                          userInfo:@{NSLocalizedDescriptionKey:
                              @"The target may have executed the operation. Its result is unknown; do not retry automatically.",
                              NSUnderlyingErrorKey: underlyingError}];
}

// The wire model normally omits screenshots from hierarchy archives. Preserve
// them for local snapshots without changing that model's wire encoding policy.
@interface LKInspectionSnapshotArchiverDelegate : NSObject <NSKeyedArchiverDelegate>
@property(nonatomic, strong) NSMapTable<LookinDisplayItem *, NSNumber *> *originalImageEncoding;
- (void)restoreImageEncoding;
@end

@implementation LKInspectionSnapshotArchiverDelegate
- (instancetype)init {
    if ((self = [super init])) {
        _originalImageEncoding = [NSMapTable strongToStrongObjectsMapTable];
    }
    return self;
}
- (id)archiver:(NSKeyedArchiver *)archiver willEncodeObject:(id)object {
    if ([object isKindOfClass:LookinDisplayItem.class] && ![self.originalImageEncoding objectForKey:object]) {
        LookinDisplayItem *item = object;
        [self.originalImageEncoding setObject:@(item.screenshotEncodeType) forKey:item];
        item.screenshotEncodeType = LookinDisplayItemImageEncodeTypeImage;
    }
    return object;
}
- (void)restoreImageEncoding {
    for (LookinDisplayItem *item in self.originalImageEncoding.keyEnumerator) {
        item.screenshotEncodeType = [self.originalImageEncoding objectForKey:item].unsignedIntegerValue;
    }
}
@end

// Only trusted, already decoded model graphs enter this local copy operation.
// The main thread owns the graph for the entire synchronous archive operation.
static id LKInspectionCopyModel(id model, NSError **error) {
    if (!model) {
        return nil;
    }
    LKInspectionSnapshotArchiverDelegate *archiveDelegate = [LKInspectionSnapshotArchiverDelegate new];
    @try {
        NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
        encoder.delegate = archiveDelegate;
        [encoder encodeObject:model forKey:NSKeyedArchiveRootObjectKey];
        [encoder finishEncoding];
        NSData *data = encoder.encodedData;
        if (!data) {
            return nil;
        }
        NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:error];
        decoder.requiresSecureCoding = NO;
        id result = [decoder decodeObjectForKey:NSKeyedArchiveRootObjectKey];
        [decoder finishDecoding];
        return result;
    } @catch (NSException *exception) {
        if (error) {
            *error = LKInspectionSessionError(LKInspectionSessionErrorInvalidResponse,
                                             exception.reason ?: @"The inspection model could not be copied.");
        }
        return nil;
    } @finally {
        [archiveDelegate restoreImageEncoding];
    }
}

static BOOL LKInspectionRequestMayMutateTarget(uint32_t requestType) {
    return requestType == LookinRequestTypeInbuiltAttrModification
        || requestType == LookinRequestTypeCustomAttrModification
        || requestType == LookinRequestTypeInvokeMethod
        || requestType == LookinRequestTypeModifyRecognizerEnable;
}

@interface LKInspectionSessionRegistry ()
@property(nonatomic, strong) NSHashTable<LKInspectionSession *> *registeredSessions;
- (void)registerSession:(LKInspectionSession *)session;
@end

@interface LKInspectionSession ()
@property(nonatomic, strong, readwrite) LKInspectableApp *inspectableApp;
@property(nonatomic, assign, readwrite) uint64_t connectionGeneration;
@property(nonatomic, assign, readwrite) uint64_t hierarchyRevision;
@property(nonatomic, copy, readwrite) NSDictionary<NSString *, id> *captureOptions;
@property(nonatomic, strong, readwrite) NSDate *captureDate;
@property(nonatomic, assign, readwrite) BOOL requiresRefresh;
@property(nonatomic, copy, readwrite) NSString *lastReloadInitiator;
@property(nonatomic, copy, readwrite) NSString *connectionLossBannerMessage;
@property(nonatomic, strong) LookinHierarchyInfo *cachedHierarchy;
@property(nonatomic, copy) NSDictionary<NSNumber *, LookinDisplayItem *> *cachedItemsByObjectIdentifier;
@property(nonatomic, copy) NSArray<LookinDisplayItemDetail *> *cachedDetails;
@property(nonatomic, strong) LKInspectionRequestQueue *requestQueue;
@property(nonatomic, strong) RACDisposable *channelSubscription;
@property(nonatomic, strong) RACDisposable *reconnectSubscription;
@end

@implementation LKInspectionSession

- (instancetype)initWithInspectableApp:(LKInspectableApp *)inspectableApp {
    NSParameterAssert(inspectableApp);
    NSAssert(NSThread.isMainThread, @"Inspection sessions must run on the main thread.");
    if ((self = [super init])) {
        _inspectableApp = inspectableApp;
        _sessionIdentifier = NSUUID.UUID.UUIDString;
        _connectionGeneration = 1;
        LKInspectionEnvironment *environment = LKInspectionEnvironment.sharedEnvironment;
        _captureOptions = environment.initialCaptureOptionsProvider
            ? environment.initialCaptureOptionsProvider().copy : environment.initialCaptureOptions.copy;
        _requiresRefresh = YES;
        _lastReloadInitiator = @"host";
        _requestQueue = [LKInspectionRequestQueue new];
        _didReloadHierarchyInfo = [RACSubject subject];
        _didUpdateDetails = [RACSubject subject];
        [inspectableApp bindInspectionSession:self];
        [self observeConnection];
        [LKInspectionSessionRegistry.sharedRegistry registerSession:self];
    }
    return self;
}

- (void)dealloc {
    [_channelSubscription dispose];
    [_reconnectSubscription dispose];
    // Do not publish self from dealloc; an observer could retain a dying object.
    [[NSNotificationCenter defaultCenter] postNotificationName:LKInspectionSessionDidCloseNotification
                                                       object:nil
                                                     userInfo:@{@"appInfo": _inspectableApp.appInfo ?: NSNull.null,
                                                                @"sessionIdentifier": _sessionIdentifier}];
}

- (LookinHierarchyInfo *)readHierarchyWithError:(NSError **)error {
    NSAssert(NSThread.isMainThread, @"Inspection sessions must run on the main thread.");
    if (!self.cachedHierarchy) {
        if (error) {
            *error = LKInspectionSessionError(LKInspectionSessionErrorNotReady, @"No complete hierarchy has been captured.");
        }
        return nil;
    }
    return LKInspectionCopyModel(self.cachedHierarchy, error);
}

- (LookinHierarchyInfo *)rawHierarchyInfo {
    return [self readHierarchyWithError:nil];
}

- (NSArray<LookinDisplayItem *> *)rawFlatItems {
    LookinHierarchyInfo *hierarchy = self.rawHierarchyInfo;
    return hierarchy ? [LookinDisplayItem flatItemsFromHierarchicalItems:hierarchy.displayItems] : nil;
}

- (NSArray<LookinDisplayItemDetail *> *)latestDetails {
    return LKInspectionCopyModel(self.cachedDetails, NULL) ?: @[];
}

- (RACSignal *)refreshHierarchyWithInitiator:(NSString *)initiator {
    return [self enqueueRequestWithType:LookinRequestTypeHierarchy payload:nil
                             initiator:initiator captureOptions:nil];
}

- (RACSignal *)updateCaptureOptions:(NSDictionary<NSString *,id> *)options initiator:(NSString *)initiator {
    return [self enqueueRequestWithType:LookinRequestTypeHierarchy payload:nil
                             initiator:initiator captureOptions:options.copy];
}

- (RACSignal *)fetchDetailsWithTaskPackages:(NSArray<LookinStaticAsyncUpdateTasksPackage *> *)packages {
    return [[[self requestWithType:LookinRequestTypeHierarchyDetails payload:packages] collect]
        map:^NSArray *(NSArray<NSArray<LookinDisplayItemDetail *> *> *responses) {
            NSMutableArray<LookinDisplayItemDetail *> *details = [NSMutableArray array];
            for (NSArray<LookinDisplayItemDetail *> *response in responses) {
                [details addObjectsFromArray:response];
            }
            return details.copy;
        }];
}

- (RACSignal *)requestWithType:(uint32_t)requestType payload:(id)payload {
    return [self enqueueRequestWithType:requestType payload:payload initiator:@"host" captureOptions:nil];
}

- (RACSignal *)enqueueRequestWithType:(uint32_t)requestType
                             payload:(id)payload
                           initiator:(NSString *)initiator
                      captureOptions:(NSDictionary<NSString *, id> *)newOptions {
    NSAssert(NSThread.isMainThread, @"Inspection sessions must run on the main thread.");
    uint64_t expectedGeneration = self.connectionGeneration;
    uint64_t expectedRevision = self.hierarchyRevision;
    return [self.requestQueue enqueueRequest:^RACSignal *{
        if (expectedGeneration != self.connectionGeneration) {
            return [RACSignal error:LKInspectionSessionError(LKInspectionSessionErrorStaleConnection,
                                                         @"The target connection changed before the operation started.")];
        }
        if (requestType != LookinRequestTypeHierarchy && expectedRevision != self.hierarchyRevision) {
            return [RACSignal error:LKInspectionSessionError(LKInspectionSessionErrorStaleHierarchy,
                                                         @"The hierarchy changed before the operation started. Query it again.")];
        }
        if (requestType != LookinRequestTypeHierarchy && !self.cachedHierarchy) {
            return [RACSignal error:LKInspectionSessionError(LKInspectionSessionErrorNotReady,
                @"Capture a hierarchy from the current connection before requesting objects.")];
        }
        NSDictionary *options = newOptions ?: self.captureOptions;
        id requestPayload = payload;
        if (requestType == LookinRequestTypeHierarchy) {
            NSMutableDictionary *parameters = options.mutableCopy;
            parameters[@"clientVersion"] = LKInspectionEnvironment.sharedEnvironment.clientReadableVersion;
            requestPayload = parameters;
        }
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            NSMutableArray *responses = [NSMutableArray array];
            __block BOOL failed = NO;
            return [[self.inspectableApp performInspectionRequestWithType:requestType payload:requestPayload]
                subscribeNext:^(id response) {
                    if (response) {
                        [responses addObject:response];
                        if (requestType == LookinRequestTypeHierarchyDetails) {
                            // Legacy graphical consumers use each frame for
                            // progress. Cache publication still waits for the
                            // complete stream; async consumers collect it all.
                            NSError *copyError = nil;
                            id independentResponse = LKInspectionCopyModel(response, &copyError);
                            if (independentResponse) {
                                [subscriber sendNext:independentResponse];
                            } else {
                                failed = YES;
                                [subscriber sendError:copyError ?: LKInspectionSessionError(LKInspectionSessionErrorInvalidResponse,
                                    @"The target returned an unsupported detail frame.")];
                            }
                        }
                    }
                } error:^(NSError *error) {
                    failed = YES;
                    if (LKInspectionRequestMayMutateTarget(requestType)) {
                        self.requiresRefresh = YES;
                    }
                    if (LKInspectionRequestMayMutateTarget(requestType)
                        && [error.domain isEqualToString:LookinErrorDomain]
                        && (error.code == LookinErrCode_Timeout || error.code == LookinErrCode_NoConnect
                            || error.code == LookinErrCode_PeerTalk)) {
                        [subscriber sendError:LKInspectionUnknownExecutionError(error)];
                    } else {
                        [subscriber sendError:error];
                    }
                } completed:^{
                    if (failed) {
                        return;
                    }
                    if (expectedGeneration != self.connectionGeneration) {
                        [subscriber sendError:LKInspectionSessionError(LKInspectionSessionErrorStaleConnection,
                                                                    @"The response belongs to an earlier connection.")];
                        return;
                    }
                    if (responses.count == 0) {
                        [subscriber sendError:LKInspectionSessionError(LKInspectionSessionErrorInvalidResponse,
                                                                    @"The target completed without returning a response.")];
                        return;
                    }
                    NSError *copyError = nil;
                    NSArray *independentResponses = LKInspectionCopyModel(responses, &copyError);
                    if (!independentResponses) {
                        [subscriber sendError:copyError ?: LKInspectionSessionError(LKInspectionSessionErrorInvalidResponse,
                                                                                 @"The target returned an unsupported model.")];
                        return;
                    }
                    if (requestType == LookinRequestTypeHierarchy) {
                        if (independentResponses.count != 1 || ![independentResponses.firstObject isKindOfClass:LookinHierarchyInfo.class]) {
                            [subscriber sendError:LKInspectionSessionError(LKInspectionSessionErrorInvalidResponse,
                                                                        @"The target did not return a complete hierarchy.")];
                            return;
                        }
                        self.cachedHierarchy = independentResponses.firstObject;
                        self.cachedDetails = @[];
                        [self rebuildObjectIndex];
                        self.captureOptions = options.copy;
                        self.captureDate = NSDate.date;
                        self.hierarchyRevision += 1;
                        self.requiresRefresh = NO;
                        self.lastReloadInitiator = initiator;
                        [self.didReloadHierarchyInfo sendNext:nil];
                        [[NSNotificationCenter defaultCenter] postNotificationName:LKInspectionSessionDidReloadNotification object:self];
                    } else {
                        if (expectedRevision != self.hierarchyRevision) {
                            [subscriber sendError:LKInspectionSessionError(LKInspectionSessionErrorStaleHierarchy,
                                                                        @"The response belongs to an earlier hierarchy.")];
                            return;
                        }
                        NSMutableArray<LookinDisplayItemDetail *> *details = [NSMutableArray array];
                        for (id response in independentResponses) {
                            if ([response isKindOfClass:LookinDisplayItemDetail.class]) {
                                [details addObject:response];
                            } else if ([response isKindOfClass:NSArray.class]) {
                                for (id element in response) {
                                    if ([element isKindOfClass:LookinDisplayItemDetail.class]) {
                                        [details addObject:element];
                                    }
                                }
                            }
                        }
                        for (LookinDisplayItemDetail *detail in details) {
                            [self applyDetailToCache:detail];
                        }
                        if (details.count) {
                            self.cachedDetails = details.copy;
                            [self.didUpdateDetails sendNext:nil];
                        }
                        if (LKInspectionRequestMayMutateTarget(requestType)) {
                            self.requiresRefresh = YES;
                        }
                    }
                    // Observers never receive the instances just committed to the cache.
                    if (requestType != LookinRequestTypeHierarchyDetails) {
                        for (id response in responses) {
                            [subscriber sendNext:LKInspectionCopyModel(response, nil)];
                        }
                    }
                    [subscriber sendCompleted];
                }];
        }];
    } interruptionError:^NSError *(NSError *error) {
        if (LKInspectionRequestMayMutateTarget(requestType)) {
            self.requiresRefresh = YES;
            return LKInspectionUnknownExecutionError(error);
        }
        return error;
    }];
}

- (void)rebuildObjectIndex {
    NSMutableDictionary<NSNumber *, LookinDisplayItem *> *index = [NSMutableDictionary dictionary];
    NSArray<LookinDisplayItem *> *items = [LookinDisplayItem flatItemsFromHierarchicalItems:self.cachedHierarchy.displayItems];
    for (LookinDisplayItem *item in items) {
        unsigned long objectIdentifier = item.displayingObject.oid;
        if (objectIdentifier && !index[@(objectIdentifier)]) index[@(objectIdentifier)] = item;
    }
    // Dedicated backing-layer nodes take precedence over their view's alias.
    for (LookinDisplayItem *item in items) {
        for (NSNumber *objectIdentifier in @[@(item.viewObject.oid), @(item.layerObject.oid),
                                             @(item.windowObject.oid), @(item.kindObject.oid)]) {
            if (objectIdentifier.unsignedLongValue && !index[objectIdentifier]) index[objectIdentifier] = item;
        }
    }
    self.cachedItemsByObjectIdentifier = index.copy;
}

- (void)applyDetailToCache:(LookinDisplayItemDetail *)detail {
    if (detail.failureCode || !self.cachedHierarchy) {
        return;
    }
    LookinDisplayItem *matchedItem = self.cachedItemsByObjectIdentifier[@(detail.displayItemOid)];
    if (!matchedItem) {
        return;
    }
    if (detail.frameValue) matchedItem.frame = detail.frameValue.rectValue;
    if (detail.boundsValue) matchedItem.bounds = detail.boundsValue.rectValue;
    if (detail.hiddenValue) matchedItem.isHidden = detail.hiddenValue.boolValue;
    if (detail.alphaValue) matchedItem.alpha = detail.alphaValue.doubleValue;
    if (detail.customDisplayTitle) matchedItem.customDisplayTitle = detail.customDisplayTitle;
    if (detail.danceUISource) matchedItem.danceuiSource = detail.danceUISource;
    if (detail.groupScreenshot) matchedItem.groupScreenshot = detail.groupScreenshot;
    if (detail.soloScreenshot) matchedItem.soloScreenshot = detail.soloScreenshot;
    if (detail.attributesGroupList) matchedItem.attributesGroupList = detail.attributesGroupList;
    if (detail.customAttrGroupList) matchedItem.customAttrGroupList = detail.customAttrGroupList;
    if (detail.subitems) {
        matchedItem.subitems = detail.subitems;
        [self rebuildObjectIndex];
    }
}

- (void)replaceInspectableApp:(LKInspectableApp *)inspectableApp {
    NSAssert(NSThread.isMainThread, @"Inspection sessions must run on the main thread.");
    [self.requestQueue invalidateWithError:LKInspectionSessionError(LKInspectionSessionErrorStaleConnection,
                                                                @"The target connection was replaced.")];
    self.requestQueue = [LKInspectionRequestQueue new];
    self.connectionGeneration += 1;
    self.cachedHierarchy = nil;
    self.cachedItemsByObjectIdentifier = @{};
    self.cachedDetails = @[];
    self.captureDate = nil;
    self.requiresRefresh = YES;
    [self.inspectableApp bindInspectionSession:nil];
    self.inspectableApp = inspectableApp;
    [inspectableApp bindInspectionSession:self];
    self.connectionLossBannerMessage = nil;
    [self.reconnectSubscription dispose];
    self.reconnectSubscription = nil;
    [self observeConnection];
}

- (void)observeConnection {
    [self.channelSubscription dispose];
    if (!self.inspectableApp.channel) {
        return;
    }
    __weak LKInspectionSession *weakSession = self;
    self.channelSubscription = [LKConnectionManager.sharedInstance.channelWillEnd subscribeNext:^(Lookin_PTChannel *channel) {
        LKInspectionSession *session = weakSession;
        if (!session || channel != session.inspectableApp.channel) {
            return;
        }
        session.requiresRefresh = YES;
        [session.requestQueue invalidateWithError:LookinErr_NoConnect];
        session.connectionLossBannerMessage = [NSString stringWithFormat:
            NSLocalizedString(@"Connection to %@ lost. Trying to reconnect…", nil),
            session.inspectableApp.appInfo.appName ?: NSLocalizedString(@"Inspected app", nil)];
        [[NSNotificationCenter defaultCenter] postNotificationName:LKInspectionSessionDidDisconnectNotification object:session];
        [session startReconnecting];
    }];
}

- (void)startReconnecting {
    [self.reconnectSubscription dispose];
    __weak LKInspectionSession *weakSession = self;
    RACSignal *attempts = [[RACSignal interval:3 onScheduler:RACScheduler.mainThreadScheduler]
        flattenMap:^RACSignal *(NSDate *date) {
            return [[LKAppsManager.sharedInstance fetchAppInfosWithImage:NO localInfos:nil] catch:^RACSignal *(NSError *error) {
                return [RACSignal empty];
            }];
        }];
    self.reconnectSubscription = [attempts subscribeNext:^(NSArray<LKInspectableApp *> *applications) {
        LKInspectionSession *session = weakSession;
        if (!session) return;
        NSMutableArray<LKInspectableApp *> *matches = [NSMutableArray array];
        for (LKInspectableApp *application in applications) {
            if ([session.inspectableApp.appInfo isEqualToAppInfo:application.appInfo]
                && [session.inspectableApp.transportIdentifier isEqualToString:application.transportIdentifier]) {
                [matches addObject:application];
            }
        }
        if (matches.count == 1) {
            LKInspectableApp *application = matches.firstObject;
            application.appInfo.appIcon = session.inspectableApp.appInfo.appIcon;
            [session replaceInspectableApp:application];
        }
    }];
}

@end

@implementation LKInspectionSessionRegistry

+ (instancetype)sharedRegistry {
    static LKInspectionSessionRegistry *registry;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ registry = [LKInspectionSessionRegistry new]; });
    return registry;
}

- (instancetype)init {
    if ((self = [super init])) {
        _registeredSessions = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)registerSession:(LKInspectionSession *)session {
    [self.registeredSessions addObject:session];
    [[NSNotificationCenter defaultCenter] postNotificationName:LKInspectionSessionDidOpenNotification object:session];
}

- (NSArray<LKInspectionSession *> *)sessions {
    return self.registeredSessions.allObjects;
}

- (LKInspectionSession *)sessionForInspectableApp:(LKInspectableApp *)inspectableApp {
    NSAssert(NSThread.isMainThread, @"Inspection sessions must run on the main thread.");
    for (LKInspectionSession *session in self.sessions) {
        LKInspectableApp *existingApplication = session.inspectableApp;
        if (existingApplication == inspectableApp
            || (inspectableApp.appInfo.appInfoIdentifier != 0
                && existingApplication.appInfo.appInfoIdentifier == inspectableApp.appInfo.appInfoIdentifier
                && [existingApplication.transportIdentifier isEqualToString:inspectableApp.transportIdentifier])) {
            return session;
        }
    }
    return [[LKInspectionSession alloc] initWithInspectableApp:inspectableApp];
}

@end
