#import <XCTest/XCTest.h>
#import <LookInsideInspectionCore/LookInsideInspectionCore.h>

@interface LKControlledInspectableApp : LKInspectableApp
@property(nonatomic, strong) NSMutableArray<NSNumber *> *requestTypes;
@property(nonatomic, strong) NSMutableArray<RACSubject *> *responses;
@end

@implementation LKControlledInspectableApp
- (instancetype)init {
    if ((self = [super init])) {
        _requestTypes = [NSMutableArray array];
        _responses = [NSMutableArray array];
        self.appInfo = [LookinAppInfo new];
        self.appInfo.appInfoIdentifier = 123;
        self.appInfo.screenScale = 1;
        self.appInfo.deviceType = LookinAppInfoDeviceMac;
        self.transportIdentifier = NSUUID.UUID.UUIDString;
    }
    return self;
}
- (RACSignal *)performInspectionRequestWithType:(uint32_t)requestType payload:(id)payload {
    [self.requestTypes addObject:@(requestType)];
    RACSubject *response = [RACSubject subject];
    [self.responses addObject:response];
    return response;
}
@end

@interface LKInspectionSessionTests : XCTestCase
@end

@implementation LKInspectionSessionTests

- (LookinHierarchyInfo *)hierarchyForApplication:(LKInspectableApp *)application {
    LookinDisplayItem *root = [LookinDisplayItem new];
    root.viewObject = [LookinObject new];
    root.viewObject.oid = 10;
    root.frame = CGRectMake(0, 0, 200, 300);
    root.bounds = root.frame;
    LookinDisplayItem *child = [LookinDisplayItem new];
    child.viewObject = [LookinObject new];
    child.viewObject.oid = 20;
    child.frame = CGRectMake(10, 20, 50, 60);
    root.subitems = @[child];
    LookinHierarchyInfo *hierarchy = [LookinHierarchyInfo new];
    hierarchy.appInfo = application.appInfo;
    hierarchy.displayItems = @[root];
    hierarchy.colorAlias = @{@"nested": [NSMutableArray arrayWithObject:@"original"]};
    return hierarchy;
}

- (void)captureHierarchy:(LKInspectionSession *)session application:(LKControlledInspectableApp *)application {
    [[session refreshHierarchyWithInitiator:@"host"] subscribeError:^(NSError *error) {
        XCTFail(@"Unexpected capture failure: %@", error);
    }];
    [application.responses.lastObject sendNext:[self hierarchyForApplication:application]];
    [application.responses.lastObject sendCompleted];
}

- (void)testHierarchyExistsWithoutWindowsAndReadersCannotMutateTheCache {
    XCTAssertNil(NSApp);
    LKControlledInspectableApp *application = [LKControlledInspectableApp new];
    LKInspectionSession *session = [[LKInspectionSession alloc] initWithInspectableApp:application];
    [self captureHierarchy:session application:application];
    LookinHierarchyInfo *firstReader = [session readHierarchyWithError:NULL];
    firstReader.displayItems.firstObject.subitems.firstObject.frame = CGRectZero;
    firstReader.displayItems.firstObject.isExpanded = YES;
    [(NSMutableArray *)firstReader.colorAlias[@"nested"] addObject:@"changed"];
    LookinHierarchyInfo *secondReader = [session readHierarchyWithError:NULL];
    XCTAssertTrue(CGRectEqualToRect(secondReader.displayItems.firstObject.subitems.firstObject.frame,
                                   CGRectMake(10, 20, 50, 60)));
    XCTAssertEqual([secondReader.colorAlias[@"nested"] count], 1);
    XCTAssertFalse(secondReader.displayItems.firstObject.isExpanded);
    XCTAssertEqual(session.hierarchyRevision, 1);
    XCTAssertNil(NSApp);
}

- (void)testRefreshCommitsOnlyAtCompletionAndKeepsPreviousHierarchyOnFailure {
    LKControlledInspectableApp *application = [LKControlledInspectableApp new];
    LKInspectionSession *session = [[LKInspectionSession alloc] initWithInspectableApp:application];
    [self captureHierarchy:session application:application];
    __block NSError *reportedError;
    [[session refreshHierarchyWithInitiator:@"agent"] subscribeError:^(NSError *error) { reportedError = error; }];
    LookinHierarchyInfo *replacement = [self hierarchyForApplication:application];
    replacement.displayItems = @[];
    [application.responses.lastObject sendNext:replacement];
    XCTAssertEqual(session.hierarchyRevision, 1);
    XCTAssertEqual(session.rawFlatItems.count, 2);
    [application.responses.lastObject sendError:[NSError errorWithDomain:@"ControlledTarget" code:1 userInfo:nil]];
    XCTAssertNotNil(reportedError);
    XCTAssertEqual(session.hierarchyRevision, 1);
    XCTAssertEqual(session.rawFlatItems.count, 2);
}

- (void)testDetailStreamsFinishBeforeTheNextRequestAndUpdateAttributesAndImages {
    LKControlledInspectableApp *application = [LKControlledInspectableApp new];
    LKInspectionSession *session = [[LKInspectionSession alloc] initWithInspectableApp:application];
    [self captureHierarchy:session application:application];
    __block NSArray<LookinDisplayItemDetail *> *receivedDetails;
    [[session fetchDetailsWithTaskPackages:@[]] subscribeNext:^(NSArray *details) { receivedDetails = details; }];
    RACSubject *detailResponse = application.responses.lastObject;
    [[session requestWithType:LookinRequestTypeAllSelectorNames payload:@{}] subscribeNext:^(id value) {}];
    LookinDisplayItemDetail *firstDetail = [LookinDisplayItemDetail new];
    firstDetail.displayItemOid = 20;
    firstDetail.alphaValue = @0.25;
    LookinAttribute *attribute = [LookinAttribute new];
    attribute.identifier = @"test-title";
    attribute.attrType = LookinAttrTypeNSString;
    attribute.value = @"captured title";
    LookinAttributesSection *section = [LookinAttributesSection new];
    section.identifier = @"test-section";
    section.attributes = @[attribute];
    LookinAttributesGroup *group = [LookinAttributesGroup new];
    group.identifier = @"test-group";
    group.attrSections = @[section];
    firstDetail.attributesGroupList = @[group];
    firstDetail.soloScreenshot = [[NSImage alloc] initWithSize:NSMakeSize(4, 5)];
    NSBitmapImageRep *pixels = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
        pixelsWide:4 pixelsHigh:5 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES
        isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
    memset(pixels.bitmapData, 255, pixels.bytesPerRow * pixels.pixelsHigh);
    [firstDetail.soloScreenshot addRepresentation:pixels];
    [detailResponse sendNext:@[firstDetail]];
    XCTAssertNil(receivedDetails);
    XCTAssertEqual(application.requestTypes.count, 2);
    LookinDisplayItemDetail *secondDetail = [LookinDisplayItemDetail new];
    secondDetail.displayItemOid = 10;
    secondDetail.hiddenValue = @YES;
    [detailResponse sendNext:@[secondDetail]];
    [detailResponse sendCompleted];
    XCTAssertEqual(receivedDetails.count, 2);
    XCTAssertNotNil(receivedDetails.firstObject.soloScreenshot);
    XCTAssertEqual(application.requestTypes.count, 3);
    LookinHierarchyInfo *captured = session.rawHierarchyInfo;
    XCTAssertTrue(captured.displayItems.firstObject.isHidden);
    LookinAttribute *capturedAttribute = captured.displayItems.firstObject.subitems.firstObject
        .attributesGroupList.firstObject.attrSections.firstObject.attributes.firstObject;
    XCTAssertEqualObjects(capturedAttribute.value, @"captured title");
    capturedAttribute.value = @"presentation changed";
    XCTAssertEqualObjects(session.rawHierarchyInfo.displayItems.firstObject.subitems.firstObject
        .attributesGroupList.firstObject.attrSections.firstObject.attributes.firstObject.value, @"captured title");
    XCTAssertEqualWithAccuracy(captured.displayItems.firstObject.subitems.firstObject.alpha, 0.25, 0.001);
    NSImage *capturedImage = captured.displayItems.firstObject.subitems.firstObject.soloScreenshot;
    XCTAssertNotNil(capturedImage);
    XCTAssertTrue(NSEqualSizes(capturedImage.size, NSMakeSize(4, 5)), @"Actual image size: %@", NSStringFromSize(capturedImage.size));
    capturedImage.size = NSMakeSize(1, 1);
    XCTAssertTrue(NSEqualSizes(session.rawHierarchyInfo.displayItems.firstObject.subitems.firstObject.soloScreenshot.size, NSMakeSize(4, 5)));
    [application.responses.lastObject sendNext:@[]];
    [application.responses.lastObject sendCompleted];
}

- (void)testCancellingOneObserverDoesNotReplayAnInvocationOrInterruptTheNextRequest {
    LKControlledInspectableApp *application = [LKControlledInspectableApp new];
    LKInspectionSession *session = [[LKInspectionSession alloc] initWithInspectableApp:application];
    [self captureHierarchy:session application:application];
    RACDisposable *invocation = [[session requestWithType:LookinRequestTypeInvokeMethod payload:@{}] subscribeNext:^(id value) {}];
    RACSubject *invocationResponse = application.responses.lastObject;
    __block BOOL nextFinished = NO;
    [[session requestWithType:LookinRequestTypeAllSelectorNames payload:@{}] subscribeCompleted:^{ nextFinished = YES; }];
    [invocation dispose];
    XCTAssertEqual(application.requestTypes.count, 2);
    [invocationResponse sendNext:@{@"description": @"invoked"}];
    [invocationResponse sendCompleted];
    XCTAssertEqual(application.requestTypes.count, 3);
    XCTAssertEqual(session.hierarchyRevision, 1);
    XCTAssertTrue(session.requiresRefresh);
    [application.responses.lastObject sendNext:@[]];
    [application.responses.lastObject sendCompleted];
    XCTAssertTrue(nextFinished);
    XCTAssertEqualObjects(application.requestTypes, (@[@(LookinRequestTypeHierarchy), @(LookinRequestTypeInvokeMethod), @(LookinRequestTypeAllSelectorNames)]));
}

- (void)testQueuedCancellationNeverExecutesAndLostMutationReplyReportsUnknownOutcome {
    LKControlledInspectableApp *application = [LKControlledInspectableApp new];
    LKInspectionSession *session = [[LKInspectionSession alloc] initWithInspectableApp:application];
    [self captureHierarchy:session application:application];
    __block NSError *reportedError;
    [[session requestWithType:LookinRequestTypeInvokeMethod payload:@{}] subscribeError:^(NSError *error) { reportedError = error; }];
    RACDisposable *queued = [[session requestWithType:LookinRequestTypeInvokeMethod payload:@{}] subscribeNext:^(id value) {}];
    [queued dispose];
    [application.responses.lastObject sendError:[NSError errorWithDomain:LookinErrorDomain code:LookinErrCode_Timeout userInfo:nil]];
    XCTAssertEqualObjects(reportedError.domain, LKInspectionSessionErrorDomain);
    XCTAssertEqual(reportedError.code, LKInspectionSessionErrorExecutionUnknown);
    XCTAssertEqual(application.requestTypes.count, 2);
    XCTAssertTrue(session.requiresRefresh);
}

- (void)testOldConnectionResponsesCannotPopulateReplacementCache {
    LKControlledInspectableApp *application = [LKControlledInspectableApp new];
    LKInspectionSession *session = [[LKInspectionSession alloc] initWithInspectableApp:application];
    __block NSError *reportedError;
    [[session refreshHierarchyWithInitiator:@"host"] subscribeError:^(NSError *error) { reportedError = error; }];
    RACSubject *oldResponse = application.responses.lastObject;
    LKControlledInspectableApp *replacement = [LKControlledInspectableApp new];
    [session replaceInspectableApp:replacement];
    [oldResponse sendNext:[self hierarchyForApplication:application]];
    [oldResponse sendCompleted];
    XCTAssertEqual(reportedError.code, LKInspectionSessionErrorStaleConnection);
    XCTAssertEqual(session.connectionGeneration, 2);
    XCTAssertNil(session.rawHierarchyInfo);
    [self captureHierarchy:session application:replacement];
    XCTAssertEqual(session.rawFlatItems.count, 2);
}

- (void)testCaptureOptionsCommitOnlyWithASuccessfulExplicitRefresh {
    LKControlledInspectableApp *application = [LKControlledInspectableApp new];
    LKInspectionSession *session = [[LKInspectionSession alloc] initWithInspectableApp:application];
    [self captureHierarchy:session application:application];
    NSDictionary *previousOptions = session.captureOptions;
    [[session updateCaptureOptions:@{@"showBackingLayers": @YES} initiator:@"test"] subscribeError:^(NSError *error) {}];
    [application.responses.lastObject sendError:[NSError errorWithDomain:@"ControlledTarget" code:1 userInfo:nil]];
    XCTAssertEqualObjects(session.captureOptions, previousOptions);
    XCTAssertEqual(session.hierarchyRevision, 1);
    [[session updateCaptureOptions:@{@"showBackingLayers": @YES} initiator:@"test"] subscribeNext:^(id hierarchy) {}];
    [application.responses.lastObject sendNext:[self hierarchyForApplication:application]];
    [application.responses.lastObject sendCompleted];
    XCTAssertEqualObjects(session.captureOptions[@"showBackingLayers"], @YES);
    XCTAssertEqual(session.hierarchyRevision, 2);
    [session readHierarchyWithError:NULL];
    XCTAssertEqualObjects(session.captureOptions[@"showBackingLayers"], @YES);
}

- (void)testReplacementReportsUnknownOutcomeOnlyForTheStartedMutation {
    LKControlledInspectableApp *application = [LKControlledInspectableApp new];
    LKInspectionSession *session = [[LKInspectionSession alloc] initWithInspectableApp:application];
    [self captureHierarchy:session application:application];
    __block NSError *startedError;
    __block NSError *queuedError;
    [[session requestWithType:LookinRequestTypeInvokeMethod payload:@{}]
        subscribeError:^(NSError *error) { startedError = error; }];
    [[session requestWithType:LookinRequestTypeInbuiltAttrModification payload:@{}]
        subscribeError:^(NSError *error) { queuedError = error; }];
    [session replaceInspectableApp:[LKControlledInspectableApp new]];
    XCTAssertEqual(startedError.code, LKInspectionSessionErrorExecutionUnknown);
    XCTAssertEqual(queuedError.code, LKInspectionSessionErrorStaleConnection);
    XCTAssertEqual(application.requestTypes.count, 2);
}

- (void)testObjectRequestsRequireACaptureFromTheCurrentConnection {
    LKControlledInspectableApp *application = [LKControlledInspectableApp new];
    LKInspectionSession *session = [[LKInspectionSession alloc] initWithInspectableApp:application];
    __block NSError *reportedError;
    [[session requestWithType:LookinRequestTypeInvokeMethod payload:@{@"oid": @20, @"text": @"description"}]
        subscribeError:^(NSError *error) { reportedError = error; }];
    XCTAssertEqual(reportedError.code, LKInspectionSessionErrorNotReady);
    XCTAssertEqual(application.requestTypes.count, 0);
    [session replaceInspectableApp:[LKControlledInspectableApp new]];
}

- (void)testAQueuedObjectRequestCannotUseAnIdentifierFromThePreviousHierarchy {
    LKControlledInspectableApp *application = [LKControlledInspectableApp new];
    LKInspectionSession *session = [[LKInspectionSession alloc] initWithInspectableApp:application];
    [self captureHierarchy:session application:application];
    [[session refreshHierarchyWithInitiator:@"agent"] subscribeNext:^(id hierarchy) {}];
    __block NSError *reportedError;
    [[session requestWithType:LookinRequestTypeFetchObject payload:@20]
        subscribeError:^(NSError *error) { reportedError = error; }];
    [application.responses.lastObject sendNext:[self hierarchyForApplication:application]];
    [application.responses.lastObject sendCompleted];
    XCTAssertEqual(reportedError.code, LKInspectionSessionErrorStaleHierarchy);
    XCTAssertEqual(application.requestTypes.count, 2);
}

- (void)testReleasingOneClientLeavesTheOtherClientAndCacheAlive {
    __weak LKInspectionSession *releasedSession;
    @autoreleasepool {
        LKControlledInspectableApp *application = [LKControlledInspectableApp new];
        LKInspectionSession *firstClient = [LKInspectionSessionRegistry.sharedRegistry sessionForInspectableApp:application];
        LKInspectionSession *secondClient = [LKInspectionSessionRegistry.sharedRegistry sessionForInspectableApp:application];
        releasedSession = firstClient;
        [self captureHierarchy:firstClient application:application];
        firstClient = nil;
        XCTAssertEqual(secondClient.rawFlatItems.count, 2);
        secondClient = nil;
    }
    XCTAssertNil(releasedSession);
}

- (void)testSameTargetUsesOneSessionWhileDifferentTransportsStaySeparate {
    LKControlledInspectableApp *application = [LKControlledInspectableApp new];
    LKInspectionSession *first = [LKInspectionSessionRegistry.sharedRegistry sessionForInspectableApp:application];
    XCTAssertEqual(first, [LKInspectionSessionRegistry.sharedRegistry sessionForInspectableApp:application]);
    LKControlledInspectableApp *otherDevice = [LKControlledInspectableApp new];
    LKInspectionSession *second = [LKInspectionSessionRegistry.sharedRegistry sessionForInspectableApp:otherDevice];
    XCTAssertNotEqual(first, second);
    XCTAssertNotEqualObjects(first.sessionIdentifier, second.sessionIdentifier);
}

@end
