#import "LICClient.h"

#import "LookinCore.h"
#import "../LookinCore/LookinStaticAsyncUpdateTask.h"
#import <dispatch/dispatch.h>

static NSString * const LICErrorDomain = @"LookInsideCLI";

typedef NS_ENUM(NSInteger, LICErrorCode) {
    LICErrorCodeInvalidResponse = 1,
    LICErrorCodeTargetNotFound = 2,
    LICErrorCodeTimeout = 3,
    LICErrorCodeDisconnected = 4,
    LICErrorCodeServerVersion = 5,
};

@implementation LICDiscoveredTarget
@end

@interface LICPendingRequest : NSObject
@property(nonatomic, strong) dispatch_semaphore_t semaphore;
@property(nonatomic, strong, nullable) LookinConnectionResponseAttachment *attachment;
@property(nonatomic, strong, nullable) NSError *error;
@property(nonatomic, assign) BOOL finished;
@end

@implementation LICPendingRequest
- (instancetype)init {
    if (self = [super init]) {
        _semaphore = dispatch_semaphore_create(0);
    }
    return self;
}
@end

@interface LICChannelSession : NSObject <Lookin_PTChannelDelegate>
@property(nonatomic, strong) Lookin_PTChannel *channel;
@property(nonatomic, strong) NSMutableDictionary<NSString *, LICPendingRequest *> *pendingRequests;
@property(nonatomic, strong) dispatch_queue_t callbackQueue;
@property(nonatomic, assign) uint32_t nextTag;
@end

@implementation LICChannelSession

- (instancetype)init {
    if (self = [super init]) {
        _callbackQueue = dispatch_queue_create("com.lookinside.cli.peertalk", DISPATCH_QUEUE_SERIAL);
        Lookin_PTProtocol *protocol = [Lookin_PTProtocol sharedProtocolForQueue:_callbackQueue];
        _channel = [[Lookin_PTChannel alloc] initWithProtocol:protocol delegate:self];
        _pendingRequests = [NSMutableDictionary dictionary];
        _nextTag = 1;
    }
    return self;
}

- (void)close {
    [self.channel close];
}

- (NSString *)_keyWithType:(uint32_t)type tag:(uint32_t)tag {
    return [NSString stringWithFormat:@"%u:%u", type, tag];
}

- (uint32_t)_allocateTag {
    uint32_t tag = self.nextTag;
    self.nextTag += 1;
    return tag;
}

- (void)_setPendingRequest:(LICPendingRequest *)pending forKey:(NSString *)key {
    @synchronized (self) {
        self.pendingRequests[key] = pending;
    }
}

- (nullable LICPendingRequest *)_pendingRequestForKey:(NSString *)key {
    @synchronized (self) {
        return self.pendingRequests[key];
    }
}

- (void)_removePendingRequestForKey:(NSString *)key {
    @synchronized (self) {
        [self.pendingRequests removeObjectForKey:key];
    }
}

- (NSArray<LICPendingRequest *> *)_allPendingRequests {
    @synchronized (self) {
        return self.pendingRequests.allValues.copy;
    }
}

- (LookinConnectionResponseAttachment *)validatedRequestType:(uint32_t)type data:(NSObject *)data pingTimeout:(NSTimeInterval)pingTimeout requestTimeout:(NSTimeInterval)requestTimeout error:(NSError **)error {
    LookinConnectionResponseAttachment *pingResponse = [self requestType:LookinRequestTypePing data:nil timeout:pingTimeout error:error];
    if (!pingResponse) {
        return nil;
    }

    NSError *versionError = [self.class validateServerVersion:pingResponse.lookinServerVersion];
    if (versionError) {
        if (error) {
            *error = versionError;
        }
        return nil;
    }

    return [self requestType:type data:data timeout:requestTimeout error:error];
}

- (LookinConnectionResponseAttachment *)requestType:(uint32_t)type data:(NSObject *)data timeout:(NSTimeInterval)timeout error:(NSError **)error {
    if (!self.channel.isConnected) {
        if (error) {
            *error = [NSError errorWithDomain:LICErrorDomain code:LICErrorCodeDisconnected userInfo:@{NSLocalizedDescriptionKey:@"The target connection is not active."}];
        }
        return nil;
    }

    uint32_t tag = [self _allocateTag];
    NSString *key = [self _keyWithType:type tag:tag];
    LICPendingRequest *pending = [[LICPendingRequest alloc] init];
    [self _setPendingRequest:pending forKey:key];

    LookinConnectionAttachment *attachment = [LookinConnectionAttachment new];
    attachment.data = data;
    NSError *archiveError = nil;
    NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:attachment requiringSecureCoding:YES error:&archiveError];
    if (archiveError) {
        [self _removePendingRequestForKey:key];
        if (error) {
            *error = archiveError;
        }
        return nil;
    }

    dispatch_data_t payload = [archivedData createReferencingDispatchData];
    __weak typeof(self) weakSelf = self;
    [self.channel sendFrameOfType:type tag:tag withPayload:payload callback:^(NSError *callbackError) {
        if (!callbackError) {
            return;
        }
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        LICPendingRequest *activePending = [self _pendingRequestForKey:key];
        if (!activePending || activePending.finished) {
            return;
        }
        activePending.error = callbackError;
        activePending.finished = YES;
        dispatch_semaphore_signal(activePending.semaphore);
    }];

    dispatch_time_t deadline = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC));
    long waitResult = dispatch_semaphore_wait(pending.semaphore, deadline);
    [self _removePendingRequestForKey:key];

    if (waitResult != 0) {
        if (error) {
            *error = [NSError errorWithDomain:LICErrorDomain code:LICErrorCodeTimeout userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Request %u timed out after %.2fs.", type, timeout]}];
        }
        return nil;
    }

    if (pending.error) {
        if (error) {
            *error = pending.error;
        }
        return nil;
    }

    if (!pending.attachment) {
        if (error) {
            *error = [NSError errorWithDomain:LICErrorDomain code:LICErrorCodeInvalidResponse userInfo:@{NSLocalizedDescriptionKey:@"Request finished without a response attachment."}];
        }
        return nil;
    }

    if (pending.attachment.appIsInBackground) {
        if (error) {
            *error = [NSError errorWithDomain:LICErrorDomain code:LICErrorCodeInvalidResponse userInfo:@{NSLocalizedDescriptionKey:@"The target app is in the background and cannot answer requests."}];
        }
        return nil;
    }

    if (pending.attachment.error) {
        if (error) {
            *error = pending.attachment.error;
        }
        return nil;
    }

    return pending.attachment;
}

+ (NSError *)validateServerVersion:(NSInteger)serverVersion {
    if (serverVersion == -1 || serverVersion == 100) {
        return [NSError errorWithDomain:LICErrorDomain code:LICErrorCodeServerVersion userInfo:@{NSLocalizedDescriptionKey:@"Server version is too old for this client."}];
    }
    if (serverVersion > LOOKIN_SUPPORTED_SERVER_MAX) {
        return [NSError errorWithDomain:LICErrorDomain code:LICErrorCodeServerVersion userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Server version %@ is newer than this client supports.", @(serverVersion)]}];
    }
    if (serverVersion < LOOKIN_SUPPORTED_SERVER_MIN) {
        return [NSError errorWithDomain:LICErrorDomain code:LICErrorCodeServerVersion userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Server version %@ is older than this client supports.", @(serverVersion)]}];
    }
    return nil;
}

- (BOOL)ioFrameChannel:(Lookin_PTChannel *)channel shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize {
    return [self _pendingRequestForKey:[self _keyWithType:type tag:tag]] != nil;
}

- (void)ioFrameChannel:(Lookin_PTChannel *)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(Lookin_PTData *)payload {
    NSString *key = [self _keyWithType:type tag:tag];
    LICPendingRequest *pending = [self _pendingRequestForKey:key];
    if (!pending || pending.finished) {
        return;
    }

    NSData *data = [NSData dataWithContentsOfDispatchData:payload.dispatchData];
    NSError *unarchiveError = nil;
    NSObject *object = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSObject class] fromData:data error:&unarchiveError];
    if (unarchiveError) {
        pending.error = unarchiveError;
    } else if (![object isKindOfClass:[LookinConnectionResponseAttachment class]]) {
        pending.error = [NSError errorWithDomain:LICErrorDomain code:LICErrorCodeInvalidResponse userInfo:@{NSLocalizedDescriptionKey:@"Received an unexpected response payload."}];
    } else {
        pending.attachment = (LookinConnectionResponseAttachment *)object;
    }

    pending.finished = YES;
    dispatch_semaphore_signal(pending.semaphore);
}

- (void)ioFrameChannel:(Lookin_PTChannel *)channel didEndWithError:(NSError *)error {
    NSError *finalError = error ?: [NSError errorWithDomain:LICErrorDomain code:LICErrorCodeDisconnected userInfo:@{NSLocalizedDescriptionKey:@"The target connection ended unexpectedly."}];
    for (LICPendingRequest *pending in [self _allPendingRequests]) {
        if (pending.finished) {
            continue;
        }
        pending.error = finalError;
        pending.finished = YES;
        dispatch_semaphore_signal(pending.semaphore);
    }
    @synchronized (self) {
        [self.pendingRequests removeAllObjects];
    }
}

@end

@interface LICClient ()
- (LICChannelSession *)connectToLoopbackPort:(NSInteger)port timeout:(NSTimeInterval)timeout retries:(NSInteger)retries retryDelay:(NSTimeInterval)retryDelay error:(NSError **)error;
- (nullable LICDiscoveredTarget *)directTargetForTransport:(NSString *)transport port:(NSInteger)port deviceID:(nullable NSString *)deviceID appInfoIdentifier:(NSInteger)appInfoIdentifier error:(NSError **)error;
- (BOOL)parseTargetID:(NSString *)targetID transport:(NSString * __autoreleasing *)transport port:(NSInteger *)port deviceID:(NSString * __autoreleasing *)deviceID appInfoIdentifier:(NSInteger *)appInfoIdentifier;
- (nullable LICChannelSession *)openSessionForTarget:(LICDiscoveredTarget *)target error:(NSError **)error;
- (nullable LookinHierarchyInfo *)fetchHierarchyWithSession:(LICChannelSession *)session error:(NSError **)error;
- (nullable NSArray<LookinDisplayItemDetail *> *)fetchHierarchyDetailsWithHierarchyInfo:(LookinHierarchyInfo *)hierarchyInfo preferViewOID:(BOOL)preferViewOID session:(LICChannelSession *)session error:(NSError **)error;
@end

static unsigned long LICBestObjectOIDForItem(LookinDisplayItem *item, BOOL preferViewOID) {
    if (preferViewOID && item.viewObject.oid) {
        return item.viewObject.oid;
    }
    if (item.layerObject.oid) {
        return item.layerObject.oid;
    }
    if (item.viewObject.oid) {
        return item.viewObject.oid;
    }
    return 0;
}

@implementation LICClient

- (NSArray<LICDiscoveredTarget *> *)listTargets:(NSError **)error {
    NSMutableArray<LICDiscoveredTarget *> *targets = [NSMutableArray array];
    [targets addObjectsFromArray:[self simulatorTargets]];
    [targets addObjectsFromArray:[self macTargets]];
    [targets addObjectsFromArray:[self usbTargets]];
    [targets sortUsingComparator:^NSComparisonResult(LICDiscoveredTarget *lhs, LICDiscoveredTarget *rhs) {
        NSComparisonResult transportCompare = [lhs.transport compare:rhs.transport];
        if (transportCompare != NSOrderedSame) {
            return transportCompare;
        }
        NSComparisonResult appCompare = [lhs.appName localizedCaseInsensitiveCompare:rhs.appName];
        if (appCompare != NSOrderedSame) {
            return appCompare;
        }
        return [lhs.targetID compare:rhs.targetID];
    }];
    return targets;
}

- (LICDiscoveredTarget *)inspectTargetWithID:(NSString *)targetID error:(NSError **)error {
    LICDiscoveredTarget *target = [self resolveTargetID:targetID error:error];
    return target;
}

- (NSString *)hierarchyForTargetID:(NSString *)targetID format:(NSString *)format error:(NSError **)error {
    LookinHierarchyInfo *hierarchyInfo = [self fetchHierarchyForTargetID:targetID error:error];
    if (!hierarchyInfo) {
        return nil;
    }

    if ([format isEqualToString:@"json"]) {
        NSDictionary *payload = [self hierarchyJSONObject:hierarchyInfo];
        NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:error];
        if (!data) {
            return nil;
        }
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }

    return [self renderTree:hierarchyInfo];
}

- (NSURL *)exportTargetID:(NSString *)targetID outputPath:(NSString *)outputPath error:(NSError **)error {
    LICDiscoveredTarget *target = [self resolveTargetID:targetID error:error];
    if (!target) {
        return nil;
    }

    LICChannelSession *session = [self openSessionForTarget:target error:error];
    if (!session) {
        return nil;
    }

    LookinHierarchyInfo *hierarchyInfo = [self fetchHierarchyWithSession:session error:error];
    if (!hierarchyInfo) {
        [session close];
        return nil;
    }

    NSString *expandedPath = [outputPath stringByExpandingTildeInPath];
    NSURL *url = [NSURL fileURLWithPath:expandedPath];
    [[NSFileManager defaultManager] createDirectoryAtURL:url.URLByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];

    NSString *ext = url.pathExtension.lowercaseString;
    if ([ext isEqualToString:@"archive"] || [ext isEqualToString:@"lookin"] || [ext isEqualToString:@"lookinside"]) {
        BOOL preferViewOID = (hierarchyInfo.appInfo.deviceType == LookinAppInfoDeviceMac);
        NSArray<LookinDisplayItemDetail *> *details = [self fetchHierarchyDetailsWithHierarchyInfo:hierarchyInfo preferViewOID:preferViewOID session:session error:error];
        [session close];
        if (!details) {
            return nil;
        }

        NSMutableDictionary<NSNumber *, NSData *> *soloScreenshots = [NSMutableDictionary dictionary];
        NSMutableDictionary<NSNumber *, NSData *> *groupScreenshots = [NSMutableDictionary dictionary];
        for (LookinDisplayItemDetail *detail in details) {
            if (detail.failureCode != 0 || detail.displayItemOid == 0) {
                continue;
            }
#if TARGET_OS_IPHONE
            NSData *soloData = UIImagePNGRepresentation(detail.soloScreenshot);
#elif TARGET_OS_OSX
            NSData *soloData = [detail.soloScreenshot TIFFRepresentation];
#endif
            if (soloData) {
                soloScreenshots[@(detail.displayItemOid)] = soloData;
            }
#if TARGET_OS_IPHONE
            NSData *groupData = UIImagePNGRepresentation(detail.groupScreenshot);
#elif TARGET_OS_OSX
            NSData *groupData = [detail.groupScreenshot TIFFRepresentation];
#endif
            if (groupData) {
                groupScreenshots[@(detail.displayItemOid)] = groupData;
            }
        }

        LookinHierarchyFile *archive = [LookinHierarchyFile new];
        archive.serverVersion = hierarchyInfo.serverVersion;
        archive.hierarchyInfo = hierarchyInfo;
        archive.soloScreenshots = soloScreenshots.copy;
        archive.groupScreenshots = groupScreenshots.copy;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:archive requiringSecureCoding:YES error:error];
        if (!data) {
            return nil;
        }
        if (![data writeToURL:url options:NSDataWritingAtomic error:error]) {
            return nil;
        }
        return url;
    }

    [session close];

    NSDictionary *payload = [self hierarchyJSONObject:hierarchyInfo];
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:error];
    if (!data) {
        return nil;
    }
    if (![data writeToURL:url options:NSDataWritingAtomic error:error]) {
        return nil;
    }
    return url;
}

- (NSArray<LICDiscoveredTarget *> *)simulatorTargets {
    NSMutableArray<LICDiscoveredTarget *> *targets = [NSMutableArray array];
    for (NSInteger port = LookinSimulatorIPv4PortNumberStart; port <= LookinSimulatorIPv4PortNumberEnd; port++) {
        NSError *error = nil;
        LICChannelSession *session = [self connectToLoopbackPort:port timeout:0.6 retries:2 retryDelay:0.1 error:&error];
        if (!session) {
            continue;
        }
        LICDiscoveredTarget *target = [self targetFromSession:session transport:@"simulator" port:port deviceID:nil error:nil];
        [session close];
        if (target) {
            [targets addObject:target];
        }
    }
    return targets;
}

- (NSArray<LICDiscoveredTarget *> *)macTargets {
    NSMutableArray<LICDiscoveredTarget *> *targets = [NSMutableArray array];
    for (NSInteger port = LookinMacIPv4PortNumberStart; port <= LookinMacIPv4PortNumberEnd; port++) {
        NSError *error = nil;
        LICChannelSession *session = [self connectToLoopbackPort:port timeout:0.6 retries:2 retryDelay:0.1 error:&error];
        if (!session) {
            continue;
        }
        LICDiscoveredTarget *target = [self targetFromSession:session transport:@"mac" port:port deviceID:nil error:nil];
        [session close];
        if (target) {
            [targets addObject:target];
        }
    }
    return targets;
}

- (NSArray<LICDiscoveredTarget *> *)usbTargets {
    NSMutableArray<LICDiscoveredTarget *> *targets = [NSMutableArray array];
    NSArray<NSNumber *> *deviceIDs = [self attachedUSBDeviceIDs];
    if (deviceIDs.count == 0) {
        return targets;
    }

    dispatch_semaphore_t done = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        for (NSNumber *deviceID in deviceIDs) {
            for (NSInteger port = LookinUSBDeviceIPv4PortNumberStart; port <= LookinUSBDeviceIPv4PortNumberEnd; port++) {
                NSError *error = nil;
                LICChannelSession *session = [self connectToUSBDeviceID:deviceID port:port error:&error];
                if (!session) {
                    continue;
                }
                LICDiscoveredTarget *target = [self targetFromSession:session transport:@"usb" port:port deviceID:deviceID.stringValue error:nil];
                [session close];
                if (target) {
                    @synchronized (targets) {
                        [targets addObject:target];
                    }
                }
            }
        }
        dispatch_semaphore_signal(done);
    });

    while (dispatch_semaphore_wait(done, DISPATCH_TIME_NOW) != 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    }
    return targets;
}

- (NSArray<NSNumber *> *)attachedUSBDeviceIDs {
    NSMutableOrderedSet<NSNumber *> *deviceIDs = [NSMutableOrderedSet orderedSet];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    id token = [center addObserverForName:Lookin_PTUSBDeviceDidAttachNotification object:[Lookin_PTUSBHub sharedHub] queue:nil usingBlock:^(NSNotification *note) {
        NSNumber *deviceID = note.userInfo[@"DeviceID"];
        if (deviceID) {
            [deviceIDs addObject:deviceID];
        }
    }];

    [Lookin_PTUSBHub sharedHub];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];
    [center removeObserver:token];
    return deviceIDs.array;
}

- (LICChannelSession *)connectToLoopbackPort:(NSInteger)port timeout:(NSTimeInterval)timeout error:(NSError **)error {
    return [self connectToLoopbackPort:port timeout:timeout retries:0 retryDelay:0 error:error];
}

- (LICChannelSession *)connectToLoopbackPort:(NSInteger)port timeout:(NSTimeInterval)timeout retries:(NSInteger)retries retryDelay:(NSTimeInterval)retryDelay error:(NSError **)error {
    NSError *latestError = nil;
    for (NSInteger attempt = 0; attempt <= retries; attempt++) {
        LICChannelSession *session = [self _connectToLoopbackPortOnce:port timeout:timeout error:&latestError];
        if (session) {
            return session;
        }
        if (attempt < retries) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:retryDelay]];
        }
    }
    if (error) {
        *error = latestError;
    }
    return nil;
}

- (LICChannelSession *)_connectToLoopbackPortOnce:(NSInteger)port timeout:(NSTimeInterval)timeout error:(NSError **)error {
    LICChannelSession *session = [[LICChannelSession alloc] init];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSError *callbackError = nil;
    [session.channel connectToPort:(in_port_t)port IPv4Address:INADDR_LOOPBACK callback:^(NSError *connectError, Lookin_PTAddress *address) {
        callbackError = connectError;
        dispatch_semaphore_signal(semaphore);
    }];
    long waitResult = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)));
    if (waitResult != 0) {
        [session close];
        if (error) {
            *error = [NSError errorWithDomain:LICErrorDomain code:LICErrorCodeTimeout userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Timed out connecting to loopback port %@", @(port)]}];
        }
        return nil;
    }
    if (callbackError) {
        [session close];
        if (error) {
            *error = callbackError;
        }
        return nil;
    }
    return session;
}

- (LICChannelSession *)connectToSimulatorPort:(NSInteger)port error:(NSError **)error {
    return [self connectToLoopbackPort:port timeout:0.6 error:error];
}

- (LICChannelSession *)connectToUSBDeviceID:(NSNumber *)deviceID port:(NSInteger)port error:(NSError **)error {
    LICChannelSession *session = [[LICChannelSession alloc] init];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSError *callbackError = nil;
    [session.channel connectToPort:(int)port overUSBHub:[Lookin_PTUSBHub sharedHub] deviceID:deviceID callback:^(NSError *connectError) {
        callbackError = connectError;
        dispatch_semaphore_signal(semaphore);
    }];
    long waitResult = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)));
    if (waitResult != 0) {
        [session close];
        if (error) {
            *error = [NSError errorWithDomain:LICErrorDomain code:LICErrorCodeTimeout userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Timed out connecting to USB port %@ on device %@.", @(port), deviceID]}];
        }
        return nil;
    }
    if (callbackError) {
        [session close];
        if (error) {
            *error = callbackError;
        }
        return nil;
    }
    return session;
}

- (LICDiscoveredTarget *)targetFromSession:(LICChannelSession *)session transport:(NSString *)transport port:(NSInteger)port deviceID:(NSString *)deviceID error:(NSError **)error {
    NSDictionary *params = @{@"needImages": @NO, @"local": @[]};
    LookinConnectionResponseAttachment *response = [session validatedRequestType:LookinRequestTypeApp data:params pingTimeout:0.5 requestTimeout:2 error:error];
    if (!response) {
        return nil;
    }
    if (![response.data isKindOfClass:[LookinAppInfo class]]) {
        if (error) {
            *error = [NSError errorWithDomain:LICErrorDomain code:LICErrorCodeInvalidResponse userInfo:@{NSLocalizedDescriptionKey:@"App payload was not a LookinAppInfo object."}];
        }
        return nil;
    }
    LookinAppInfo *appInfo = (LookinAppInfo *)response.data;
    LICDiscoveredTarget *target = [LICDiscoveredTarget new];
    target.transport = transport;
    target.port = port;
    target.deviceID = deviceID;
    target.appName = appInfo.appName ?: @"Unknown App";
    target.bundleIdentifier = appInfo.appBundleIdentifier ?: @"";
    target.deviceDescription = appInfo.deviceDescription ?: @"";
    target.osDescription = appInfo.osDescription ?: @"";
    target.serverVersion = appInfo.serverVersion;
    target.serverReadableVersion = appInfo.serverReadableVersion ?: @"";
    target.appInfoIdentifier = appInfo.appInfoIdentifier;
    NSMutableArray<NSString *> *pieces = [NSMutableArray arrayWithObject:transport];
    if (deviceID.length && ![transport isEqualToString:@"mac"]) {
        [pieces addObject:deviceID];
    }
    [pieces addObject:[NSString stringWithFormat:@"%@", @(port)]];
    [pieces addObject:[NSString stringWithFormat:@"%@", @(appInfo.appInfoIdentifier)]];
    target.targetID = [pieces componentsJoinedByString:@":"];
    return target;
}

- (LICDiscoveredTarget *)resolveTargetID:(NSString *)targetID error:(NSError **)error {
    NSArray<LICDiscoveredTarget *> *targets = [self listTargets:nil];
    for (LICDiscoveredTarget *target in targets) {
        if ([target.targetID isEqualToString:targetID]) {
            return target;
        }
    }

    NSString *transport = nil;
    NSString *deviceID = nil;
    NSInteger port = 0;
    NSInteger appInfoIdentifier = 0;
    if ([self parseTargetID:targetID transport:&transport port:&port deviceID:&deviceID appInfoIdentifier:&appInfoIdentifier]) {
        for (LICDiscoveredTarget *target in targets) {
            if (![target.transport isEqualToString:transport]) {
                continue;
            }
            if (target.appInfoIdentifier != appInfoIdentifier) {
                continue;
            }
            if (target.port != port) {
                continue;
            }
            if (deviceID.length > 0 && ![target.deviceID isEqualToString:deviceID]) {
                continue;
            }
            return target;
        }

        LICDiscoveredTarget *directTarget = [self directTargetForTransport:transport port:port deviceID:deviceID appInfoIdentifier:appInfoIdentifier error:nil];
        if (directTarget) {
            return directTarget;
        }
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (targets.count == 0) {
        userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:@"Target '%@' was not found. No inspectable apps are currently available.", targetID];
    } else {
        NSArray<NSString *> *available = [targets valueForKey:@"targetID"];
        userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:@"Target '%@' was not found. Available targets: %@", targetID, [available componentsJoinedByString:@", "]];
    }
    if (error) {
        *error = [NSError errorWithDomain:LICErrorDomain code:LICErrorCodeTargetNotFound userInfo:userInfo];
    }
    return nil;
}

- (LookinHierarchyInfo *)fetchHierarchyForTargetID:(NSString *)targetID error:(NSError **)error {
    LICDiscoveredTarget *target = [self resolveTargetID:targetID error:error];
    if (!target) {
        return nil;
    }

    LICChannelSession *session = [self openSessionForTarget:target error:error];
    if (!session) {
        return nil;
    }

    LookinHierarchyInfo *hierarchyInfo = [self fetchHierarchyWithSession:session error:error];
    [session close];
    return hierarchyInfo;
}

- (LICChannelSession *)openSessionForTarget:(LICDiscoveredTarget *)target error:(NSError **)error {
    __block LICChannelSession *session = nil;
    __block NSError *connectError = nil;
    if ([target.transport isEqualToString:@"usb"]) {
        dispatch_semaphore_t done = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            session = [self connectToUSBDeviceID:@(target.deviceID.integerValue) port:target.port error:&connectError];
            dispatch_semaphore_signal(done);
        });
        while (dispatch_semaphore_wait(done, DISPATCH_TIME_NOW) != 0) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
        }
    } else {
        session = [self connectToLoopbackPort:target.port timeout:0.8 retries:3 retryDelay:0.1 error:&connectError];
    }
    if (!session && error) {
        *error = connectError;
    }
    return session;
}

- (LookinHierarchyInfo *)fetchHierarchyWithSession:(LICChannelSession *)session error:(NSError **)error {
    NSDictionary *params = @{@"clientVersion": LOOKIN_SERVER_READABLE_VERSION};
    LookinConnectionResponseAttachment *response = [session validatedRequestType:LookinRequestTypeHierarchy data:params pingTimeout:2 requestTimeout:5 error:error];
    if (!response) {
        return nil;
    }
    if (![response.data isKindOfClass:[LookinHierarchyInfo class]]) {
        if (error) {
            *error = [NSError errorWithDomain:LICErrorDomain code:LICErrorCodeInvalidResponse userInfo:@{NSLocalizedDescriptionKey:@"Hierarchy payload was not a LookinHierarchyInfo object."}];
        }
        return nil;
    }
    return (LookinHierarchyInfo *)response.data;
}

- (NSArray<LookinDisplayItemDetail *> *)fetchHierarchyDetailsWithHierarchyInfo:(LookinHierarchyInfo *)hierarchyInfo preferViewOID:(BOOL)preferViewOID session:(LICChannelSession *)session error:(NSError **)error {
    NSArray<LookinDisplayItem *> *flatItems = [LookinDisplayItem flatItemsFromHierarchicalItems:hierarchyInfo.displayItems ?: @[]];
    NSMutableArray<LookinStaticAsyncUpdateTask *> *tasks = [NSMutableArray array];
    for (LookinDisplayItem *item in flatItems) {
        unsigned long oid = LICBestObjectOIDForItem(item, preferViewOID);
        if (oid == 0) {
            continue;
        }

        LookinStaticAsyncUpdateTask *groupTask = [LookinStaticAsyncUpdateTask new];
        groupTask.oid = oid;
        groupTask.taskType = LookinStaticAsyncUpdateTaskTypeGroupScreenshot;
        groupTask.attrRequest = LookinDetailUpdateTaskAttrRequest_NotNeed;
        groupTask.clientReadableVersion = LOOKIN_SERVER_READABLE_VERSION;
        [tasks addObject:groupTask];

        if (item.isExpandable) {
            LookinStaticAsyncUpdateTask *soloTask = [LookinStaticAsyncUpdateTask new];
            soloTask.oid = oid;
            soloTask.taskType = LookinStaticAsyncUpdateTaskTypeSoloScreenshot;
            soloTask.attrRequest = LookinDetailUpdateTaskAttrRequest_NotNeed;
            soloTask.clientReadableVersion = LOOKIN_SERVER_READABLE_VERSION;
            [tasks addObject:soloTask];
        }
    }

    LookinStaticAsyncUpdateTasksPackage *package = [LookinStaticAsyncUpdateTasksPackage new];
    package.tasks = tasks.copy;

    LookinConnectionResponseAttachment *response = [session validatedRequestType:LookinRequestTypeHierarchyDetails data:@[package] pingTimeout:2 requestTimeout:30 error:error];
    if (!response) {
        return nil;
    }
    if (![response.data isKindOfClass:[NSArray class]]) {
        if (error) {
            *error = [NSError errorWithDomain:LICErrorDomain code:LICErrorCodeInvalidResponse userInfo:@{NSLocalizedDescriptionKey:@"Hierarchy details payload was not an array."}];
        }
        return nil;
    }
    return (NSArray<LookinDisplayItemDetail *> *)response.data;
}

- (nullable LICDiscoveredTarget *)directTargetForTransport:(NSString *)transport port:(NSInteger)port deviceID:(nullable NSString *)deviceID appInfoIdentifier:(NSInteger)appInfoIdentifier error:(NSError **)error {
    LICChannelSession *session = nil;
    if ([transport isEqualToString:@"usb"]) {
        session = [self connectToUSBDeviceID:@(deviceID.integerValue) port:port error:error];
    } else {
        session = [self connectToLoopbackPort:port timeout:0.8 retries:3 retryDelay:0.1 error:error];
    }
    if (!session) {
        return nil;
    }

    LICDiscoveredTarget *target = [self targetFromSession:session transport:transport port:port deviceID:deviceID error:error];
    [session close];
    if (!target) {
        return nil;
    }
    if (target.appInfoIdentifier != appInfoIdentifier) {
        return nil;
    }
    return target;
}

- (BOOL)parseTargetID:(NSString *)targetID transport:(NSString * __autoreleasing *)transport port:(NSInteger *)port deviceID:(NSString * __autoreleasing *)deviceID appInfoIdentifier:(NSInteger *)appInfoIdentifier {
    NSArray<NSString *> *pieces = [targetID componentsSeparatedByString:@":"];
    if (pieces.count < 3) {
        return NO;
    }

    NSString *resolvedTransport = pieces.firstObject ?: @"";
    NSString *resolvedDeviceID = nil;
    NSInteger resolvedPort = 0;
    NSInteger resolvedAppInfoIdentifier = 0;

    if ([resolvedTransport isEqualToString:@"usb"]) {
        if (pieces.count != 4) {
            return NO;
        }
        resolvedDeviceID = pieces[1];
        resolvedPort = pieces[2].integerValue;
        resolvedAppInfoIdentifier = pieces[3].integerValue;
    } else {
        if (pieces.count != 3) {
            return NO;
        }
        resolvedPort = pieces[1].integerValue;
        resolvedAppInfoIdentifier = pieces[2].integerValue;
    }

    if (resolvedPort <= 0 || resolvedAppInfoIdentifier <= 0) {
        return NO;
    }

    if (transport) {
        *transport = resolvedTransport;
    }
    if (port) {
        *port = resolvedPort;
    }
    if (deviceID) {
        *deviceID = resolvedDeviceID;
    }
    if (appInfoIdentifier) {
        *appInfoIdentifier = resolvedAppInfoIdentifier;
    }
    return YES;
}

- (NSDictionary *)hierarchyJSONObject:(LookinHierarchyInfo *)hierarchyInfo {
    NSMutableArray *items = [NSMutableArray array];
    for (LookinDisplayItem *item in hierarchyInfo.displayItems ?: @[]) {
        [items addObject:[self itemJSONObject:item]];
    }
    return @{
        @"app": [self appJSONObject:hierarchyInfo.appInfo],
        @"serverVersion": @(hierarchyInfo.serverVersion),
        @"displayItems": items,
        @"collapsedClassList": hierarchyInfo.collapsedClassList ?: @[],
        @"colorAlias": hierarchyInfo.colorAlias ?: @{},
    };
}

- (NSDictionary *)appJSONObject:(LookinAppInfo *)appInfo {
    if (!appInfo) {
        return @{};
    }
    return @{
        @"appName": appInfo.appName ?: @"",
        @"bundleIdentifier": appInfo.appBundleIdentifier ?: @"",
        @"deviceDescription": appInfo.deviceDescription ?: @"",
        @"deviceType": [NSString stringWithFormat:@"%@", @(appInfo.deviceType)],
        @"osDescription": appInfo.osDescription ?: @"",
        @"osMainVersion": @(appInfo.osMainVersion),
        @"screenWidth": @(appInfo.screenWidth),
        @"screenHeight": @(appInfo.screenHeight),
        @"screenScale": @(appInfo.screenScale),
        @"serverVersion": @(appInfo.serverVersion),
        @"serverReadableVersion": appInfo.serverReadableVersion ?: @"",
        @"swiftEnabledInLookinServer": @(appInfo.swiftEnabledInLookinServer),
        @"appInfoIdentifier": @(appInfo.appInfoIdentifier),
    };
}

- (NSDictionary *)itemJSONObject:(LookinDisplayItem *)item {
    LookinObject *displayObject = item.displayingObject;
    NSMutableArray *children = [NSMutableArray array];
    for (LookinDisplayItem *child in item.subitems ?: @[]) {
        [children addObject:[self itemJSONObject:child]];
    }
    return @{
        @"className": [displayObject rawClassName] ?: @"",
        @"memoryAddress": displayObject.memoryAddress ?: @"",
        @"oid": @(displayObject.oid),
        @"frame": [self rectDictionary:item.frame],
        @"bounds": [self rectDictionary:item.bounds],
        @"alpha": @(item.alpha),
        @"isHidden": @(item.isHidden),
        @"representedAsKeyWindow": @(item.representedAsKeyWindow),
        @"customDisplayTitle": item.customDisplayTitle ?: @"",
        @"children": children,
    };
}

- (NSDictionary *)rectDictionary:(CGRect)rect {
    return @{
        @"x": @(rect.origin.x),
        @"y": @(rect.origin.y),
        @"width": @(rect.size.width),
        @"height": @(rect.size.height),
    };
}

- (NSString *)renderTree:(LookinHierarchyInfo *)hierarchyInfo {
    NSMutableString *output = [NSMutableString string];
    for (LookinDisplayItem *item in hierarchyInfo.displayItems ?: @[]) {
        [self appendTreeForItem:item indent:0 into:output];
    }
    if ([output hasSuffix:@"\n"]) {
        [output deleteCharactersInRange:NSMakeRange(output.length - 1, 1)];
    }
    return output;
}

- (void)appendTreeForItem:(LookinDisplayItem *)item indent:(NSUInteger)indent into:(NSMutableString *)output {
    NSMutableString *line = [NSMutableString string];
    for (NSUInteger i = 0; i < indent; i++) {
        [line appendString:@"  "];
    }
    LookinObject *displayObject = item.displayingObject;
    NSString *className = [displayObject rawClassName] ?: @"Unknown";
    [line appendFormat:@"- %@#%@", className, @(displayObject.oid)];
    if (item.representedAsKeyWindow) {
        [line appendString:@" [keyWindow]"];
    }
    if (item.isHidden) {
        [line appendString:@" hidden"];
    }
    if (item.alpha != 1) {
        [line appendFormat:@" alpha=%.2f", item.alpha];
    }
    [line appendFormat:@" frame={%@, %@, %@, %@}",
     [self formattedNumber:item.frame.origin.x],
     [self formattedNumber:item.frame.origin.y],
     [self formattedNumber:item.frame.size.width],
     [self formattedNumber:item.frame.size.height]];
    if (item.customDisplayTitle.length) {
        [line appendFormat:@" \"%@\"", item.customDisplayTitle];
    }
    [output appendFormat:@"%@\n", line];

    for (LookinDisplayItem *child in item.subitems ?: @[]) {
        [self appendTreeForItem:child indent:indent + 1 into:output];
    }
}

- (NSString *)formattedNumber:(double)value {
    if (round(value) == value) {
        return [NSString stringWithFormat:@"%@", @((NSInteger)value)];
    }
    return [NSString stringWithFormat:@"%.2f", value];
}

@end
