#import <XCTest/XCTest.h>
#import <LookInsideInspectionCore/LookInsideInspectionCore.h>
#import <arpa/inet.h>
#import <fcntl.h>
#import <sys/socket.h>
#import <unistd.h>

@interface LKControlledInspectionPayload : Lookin_PTData
@property(nonatomic, strong) NSData *encodedResponse;
@end

@implementation LKControlledInspectionPayload
- (dispatch_data_t)dispatchData {
    return self.encodedResponse.createReferencingDispatchData;
}
@end

/// Drives the real transport receive path through encoded wire attachments.
/// Replies are delivered by the test after sendFrameOfType: has returned.
@interface LKControlledInspectionChannel : Lookin_PTChannel
@property(nonatomic, strong) NSMutableArray<NSDictionary<NSString *, NSNumber *> *> *sentFrames;
@property(nonatomic, assign) BOOL closed;
- (void)replyToFrame:(NSUInteger)frameIndex data:(id)data totalCount:(NSUInteger)totalCount
       currentCount:(NSUInteger)currentCount error:(NSError *)error;
@end

@implementation LKControlledInspectionChannel
- (instancetype)init {
    if ((self = [super init])) {
        _sentFrames = [NSMutableArray array];
        self.delegate = (id<Lookin_PTChannelDelegate>)LKConnectionManager.sharedInstance;
    }
    return self;
}
- (BOOL)isConnected { return !self.closed; }
- (void)close { self.closed = YES; }
- (void)sendFrameOfType:(uint32_t)frameType tag:(uint32_t)requestTag
           withPayload:(dispatch_data_t)payload callback:(void (^)(NSError *))callback {
    [self.sentFrames addObject:@{@"type": @(frameType), @"tag": @(requestTag)}];
    if (callback) callback(nil);
}
- (void)replyToFrame:(NSUInteger)frameIndex data:(id)data totalCount:(NSUInteger)totalCount
       currentCount:(NSUInteger)currentCount error:(NSError *)error {
    NSDictionary<NSString *, NSNumber *> *frame = self.sentFrames[frameIndex];
    LookinConnectionResponseAttachment *attachment = [LookinConnectionResponseAttachment new];
    attachment.lookinServerVersion = LOOKIN_SUPPORTED_SERVER_MIN;
    attachment.data = data;
    attachment.dataTotalCount = totalCount;
    attachment.currentDataCount = currentCount;
    attachment.error = error;
    LKControlledInspectionPayload *payload = [LKControlledInspectionPayload new];
    payload.encodedResponse = [NSKeyedArchiver archivedDataWithRootObject:attachment requiringSecureCoding:NO error:NULL];
    [self.delegate ioFrameChannel:self didReceiveFrameOfType:frame[@"type"].unsignedIntValue
                             tag:frame[@"tag"].unsignedIntValue payload:payload];
}
@end

@interface LKInspectionTransportTests : XCTestCase
@end

@implementation LKInspectionTransportTests

- (void)testDiscoveryFindsAReusedListenerWithoutDisconnectingThePreviousApplication {
    LKConnectionManager *manager = LKConnectionManager.sharedInstance;
    NSArray *originalSimulatorPorts = [manager valueForKey:@"allSimulatorPorts"];
    NSArray *originalMacPorts = [manager valueForKey:@"allMacPorts"];
    NSMutableArray *originalDevicePorts = [manager valueForKey:@"allUSBPorts"];
    BOOL (^originalOwnershipProvider)(NSError **) = LKInspectionEnvironment.sharedEnvironment.acquireConnectionOwnership;
    LKInspectionEnvironment.sharedEnvironment.acquireConnectionOwnership = ^BOOL(NSError **error) { return YES; };

    int listener = socket(AF_INET, SOCK_STREAM, 0);
    XCTAssertGreaterThanOrEqual(listener, 0);
    int allowsReuse = 1;
    setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, &allowsReuse, sizeof(allowsReuse));
    struct sockaddr_in address = {0};
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    XCTAssertEqual(bind(listener, (struct sockaddr *)&address, sizeof(address)), 0);
    socklen_t addressLength = sizeof(address);
    XCTAssertEqual(getsockname(listener, (struct sockaddr *)&address, &addressLength), 0);
    XCTAssertEqual(listen(listener, 8), 0);
    fcntl(listener, F_SETFL, O_NONBLOCK);
    NSObject *endpoint = [NSClassFromString(@"LKMacConnectionPort") new];
    [endpoint setValue:@(ntohs(address.sin_port)) forKey:@"portNumber"];
    NSObject *unavailableEndpoint = [NSClassFromString(@"LKSimulatorConnectionPort") new];
    [unavailableEndpoint setValue:@0 forKey:@"portNumber"];
    [manager setValue:@[endpoint] forKey:@"allMacPorts"];
    [manager setValue:@[unavailableEndpoint] forKey:@"allSimulatorPorts"];
    [manager setValue:[NSMutableArray array] forKey:@"allUSBPorts"];

    __block NSArray<Lookin_PTChannel *> *firstChannels = nil;
    XCTestExpectation *firstDiscovery = [self expectationWithDescription:@"The first application connects"];
    [[manager tryToConnectAllPorts] subscribeNext:^(NSArray *channels) {
        firstChannels = channels;
        [firstDiscovery fulfill];
    }];
    [self waitForExpectations:@[firstDiscovery] timeout:2];
    XCTAssertEqual(firstChannels.count, 1);
    int acceptedConnection = accept(listener, NULL, NULL);
    close(listener);
    listener = socket(AF_INET, SOCK_STREAM, 0);
    setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, &allowsReuse, sizeof(allowsReuse));
    XCTAssertEqual(bind(listener, (struct sockaddr *)&address, sizeof(address)), 0);
    XCTAssertEqual(listen(listener, 8), 0);

    __block NSArray<Lookin_PTChannel *> *rediscoveredChannels = nil;
    XCTestExpectation *secondDiscovery = [self expectationWithDescription:@"The reused port is probed again"];
    [[manager tryToConnectAllPorts] subscribeNext:^(NSArray *channels) {
        rediscoveredChannels = channels;
        [secondDiscovery fulfill];
    }];
    [self waitForExpectations:@[secondDiscovery] timeout:2];
    XCTAssertEqual(rediscoveredChannels.count, 2);
    XCTAssertTrue([rediscoveredChannels containsObject:firstChannels.firstObject]);
    XCTAssertTrue(firstChannels.firstObject.isConnected);
    for (Lookin_PTChannel *channel in rediscoveredChannels) {
        XCTAssertEqualObjects([manager transportIdentifierForChannel:channel], @"mac");
        [channel close];
    }
    for (Lookin_PTChannel *channel in firstChannels) [channel close];
    close(acceptedConnection);
    close(listener);
    [manager setValue:originalSimulatorPorts forKey:@"allSimulatorPorts"];
    [manager setValue:originalMacPorts forKey:@"allMacPorts"];
    [manager setValue:originalDevicePorts forKey:@"allUSBPorts"];
    LKInspectionEnvironment.sharedEnvironment.acquireConnectionOwnership = originalOwnershipProvider;
}

- (void)testSameTypeRequestsDrainEveryFrameAndLateTagsCannotReachTheNextCaller {
    LKControlledInspectionChannel *channel = [LKControlledInspectionChannel new];
    LKConnectionManager *manager = LKConnectionManager.sharedInstance;
    __block NSUInteger cancelledCallerValues = 0;
    RACDisposable *firstRequest = [[manager requestWithType:LookinRequestTypeHierarchyDetails data:@[] channel:channel]
        subscribeNext:^(id value) { cancelledCallerValues += 1; }];
    __block NSArray *secondValues;
    __block BOOL secondCompleted = NO;
    [[manager requestWithType:LookinRequestTypeHierarchyDetails data:@[] channel:channel]
        subscribeNext:^(RACTuple *response) {
            LookinConnectionResponseAttachment *attachment = response.first;
            secondValues = attachment.data;
        } error:^(NSError *error) {
            XCTFail(@"Unexpected transport error: %@", error);
        } completed:^{ secondCompleted = YES; }];
    XCTAssertEqual(channel.sentFrames.count, 1);
    [channel replyToFrame:0 data:nil totalCount:0 currentCount:0 error:nil];
    [firstRequest dispose];
    [channel replyToFrame:1 data:@[@"first fragment"] totalCount:2 currentCount:1 error:nil];
    XCTAssertEqual(channel.sentFrames.count, 2);
    [channel replyToFrame:1 data:@[@"last fragment"] totalCount:2 currentCount:1 error:nil];
    XCTAssertEqual(channel.sentFrames.count, 3);
    [channel replyToFrame:2 data:nil totalCount:0 currentCount:0 error:nil];
    [channel replyToFrame:1 data:@[@"late old fragment"] totalCount:2 currentCount:1 error:nil];
    XCTAssertNil(secondValues);
    XCTAssertFalse(secondCompleted);
    [channel replyToFrame:3 data:@[@"second caller"] totalCount:0 currentCount:0 error:nil];
    XCTAssertEqualObjects(secondValues, (@[@"second caller"]));
    XCTAssertTrue(secondCompleted);
    XCTAssertEqual(cancelledCallerValues, 0);
    uint32_t previousTag = 0;
    for (NSDictionary<NSString *, NSNumber *> *frame in channel.sentFrames) {
        uint32_t currentTag = frame[@"tag"].unsignedIntValue;
        XCTAssertGreaterThan(currentTag, previousTag);
        previousTag = currentTag;
    }
    [channel close];
}

- (void)testBasicCaptureNeedsNoActivationAndLicenseErrorsRemainNoninteractive {
    XCTAssertNil(NSApp);
    LKControlledInspectionChannel *channel = [LKControlledInspectionChannel new];
    LKInspectableApp *application = [LKInspectableApp new];
    application.channel = channel;
    application.appInfo = [LookinAppInfo new];
    LKInspectionSession *session = [[LKInspectionSession alloc] initWithInspectableApp:application];
    __block LookinHierarchyInfo *capturedHierarchy;
    [[session refreshHierarchyWithInitiator:@"test"] subscribeNext:^(LookinHierarchyInfo *hierarchy) {
        capturedHierarchy = hierarchy;
    }];
    [channel replyToFrame:0 data:nil totalCount:0 currentCount:0 error:nil];
    XCTAssertEqual(channel.sentFrames[1][@"type"].unsignedIntValue, LookinRequestTypeHierarchy);
    LookinHierarchyInfo *hierarchy = [LookinHierarchyInfo new];
    hierarchy.displayItems = @[];
    [channel replyToFrame:1 data:hierarchy totalCount:0 currentCount:0 error:nil];
    XCTAssertNotNil(capturedHierarchy);
    __block NSError *reportedError;
    [[session requestWithType:LookinRequestTypeHierarchyDetails payload:@[]]
        subscribeError:^(NSError *error) { reportedError = error; }];
    [channel replyToFrame:2 data:nil totalCount:0 currentCount:0 error:nil];
    NSError *licenseError = [NSError errorWithDomain:LookinErrorDomain code:LookinErrCode_LicenseRequired userInfo:nil];
    [channel replyToFrame:3 data:nil totalCount:0 currentCount:0 error:licenseError];
    XCTAssertEqualObjects(reportedError.domain, LookinErrorDomain);
    XCTAssertEqual(reportedError.code, LookinErrCode_LicenseRequired);
    XCTAssertEqual(channel.sentFrames.count, 4);
    XCTAssertNil(NSApp);
    [channel close];
}

- (void)testDisconnectAfterInvocationReportsUnknownWithoutReplaying {
    LKControlledInspectionChannel *channel = [LKControlledInspectionChannel new];
    LKInspectableApp *application = [LKInspectableApp new];
    application.channel = channel;
    application.appInfo = [LookinAppInfo new];
    LKInspectionSession *session = [[LKInspectionSession alloc] initWithInspectableApp:application];
    [[session refreshHierarchyWithInitiator:@"test"] subscribeNext:^(id hierarchy) {}];
    [channel replyToFrame:0 data:nil totalCount:0 currentCount:0 error:nil];
    LookinHierarchyInfo *hierarchy = [LookinHierarchyInfo new];
    hierarchy.displayItems = @[];
    [channel replyToFrame:1 data:hierarchy totalCount:0 currentCount:0 error:nil];
    __block NSError *reportedError;
    [[session requestWithType:LookinRequestTypeInvokeMethod payload:@{@"oid": @20, @"text": @"description"}]
        subscribeError:^(NSError *error) { reportedError = error; }];
    [channel replyToFrame:2 data:nil totalCount:0 currentCount:0 error:nil];
    XCTAssertEqual(channel.sentFrames[3][@"type"].unsignedIntValue, LookinRequestTypeInvokeMethod);
    channel.closed = YES;
    [channel.delegate ioFrameChannel:channel didEndWithError:nil];
    XCTAssertEqual(reportedError.code, LKInspectionSessionErrorExecutionUnknown);
    XCTAssertEqual(channel.sentFrames.count, 4);
    XCTAssertTrue(session.requiresRefresh);
}

@end
