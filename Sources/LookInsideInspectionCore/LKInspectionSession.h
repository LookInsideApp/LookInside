#import <Foundation/Foundation.h>
#import "ReactiveObjC.h"
#import "LookinHierarchyInfo.h"
#import "LookinDisplayItemDetail.h"

@class LKInspectableApp, LookinStaticAsyncUpdateTasksPackage;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const LKInspectionSessionDidOpenNotification NS_SWIFT_NAME(InspectionSession.didOpenNotification);
FOUNDATION_EXPORT NSNotificationName const LKInspectionSessionDidCloseNotification NS_SWIFT_NAME(InspectionSession.didCloseNotification);
FOUNDATION_EXPORT NSNotificationName const LKInspectionSessionDidReloadNotification NS_SWIFT_NAME(InspectionSession.didReloadNotification);
FOUNDATION_EXPORT NSNotificationName const LKInspectionSessionDidDisconnectNotification NS_SWIFT_NAME(InspectionSession.didDisconnectNotification);
FOUNDATION_EXPORT NSErrorDomain const LKInspectionSessionErrorDomain NS_SWIFT_NAME(InspectionSessionErrorDomain);

typedef NS_ENUM(NSInteger, LKInspectionSessionErrorCode) {
    LKInspectionSessionErrorNotReady = 1,
    LKInspectionSessionErrorStaleConnection,
    LKInspectionSessionErrorStaleHierarchy,
    LKInspectionSessionErrorInvalidResponse,
    LKInspectionSessionErrorExecutionUnknown,
} NS_SWIFT_NAME(InspectionSessionErrorCode);

/// Owns one target's raw cache and complete request streams, without creating UI.
/// Callers retain the session for as long as they need its connection and cache.
/// Every returned model graph is independent from both the cache and other callers.
NS_SWIFT_UI_ACTOR
NS_SWIFT_NAME(InspectionSession)
@interface LKInspectionSession : NSObject

- (instancetype)initWithInspectableApp:(LKInspectableApp *)inspectableApp;
@property(nonatomic, strong, readonly) LKInspectableApp *inspectableApp;
@property(nonatomic, copy, readonly) NSString *sessionIdentifier;
@property(nonatomic, assign, readonly) uint64_t connectionGeneration;
@property(nonatomic, assign, readonly) uint64_t hierarchyRevision;
@property(nonatomic, copy, readonly) NSDictionary<NSString *, id> *captureOptions;
@property(nonatomic, strong, readonly, nullable) NSDate *captureDate;
@property(nonatomic, assign, readonly) BOOL requiresRefresh;
@property(nonatomic, copy, readonly, nullable) NSString *connectionLossBannerMessage;
@property(nonatomic, copy, readonly) NSString *lastReloadInitiator;
@property(nonatomic, strong, readonly) RACSubject *didReloadHierarchyInfo;
@property(nonatomic, strong, readonly) RACSubject *didUpdateDetails;
@property(nonatomic, copy, readonly) NSArray<LookinDisplayItemDetail *> *latestDetails;

- (nullable LookinHierarchyInfo *)readHierarchyWithError:(NSError *_Nullable *_Nullable)error;
@property(nonatomic, strong, readonly, nullable) LookinHierarchyInfo *rawHierarchyInfo;
@property(nonatomic, copy, readonly, nullable) NSArray<LookinDisplayItem *> *rawFlatItems;
- (RACSignal *)refreshHierarchyWithInitiator:(NSString *)initiator NS_SWIFT_NAME(refreshHierarchy(initiator:));
- (RACSignal *)updateCaptureOptions:(NSDictionary<NSString *, id> *)options initiator:(NSString *)initiator NS_SWIFT_NAME(updateCaptureOptions(_:initiator:));
- (RACSignal *)fetchDetailsWithTaskPackages:(NSArray<LookinStaticAsyncUpdateTasksPackage *> *)packages NS_SWIFT_NAME(detailResponses(packages:));

/// Existing graphical and bridge operations use this same serialized transport.
/// The signal preserves raw remote error codes and streams values until completion.
- (RACSignal *)requestWithType:(uint32_t)requestType payload:(nullable id)payload;
- (void)replaceInspectableApp:(LKInspectableApp *)inspectableApp;

@end

/// Weak registry: a discovery result alone does not keep an inspection alive.
NS_SWIFT_UI_ACTOR
NS_SWIFT_NAME(InspectionSessionRegistry)
@interface LKInspectionSessionRegistry : NSObject
+ (instancetype)sharedRegistry;
- (LKInspectionSession *)sessionForInspectableApp:(LKInspectableApp *)inspectableApp;
@property(nonatomic, copy, readonly) NSArray<LKInspectionSession *> *sessions;
@end

NS_ASSUME_NONNULL_END
