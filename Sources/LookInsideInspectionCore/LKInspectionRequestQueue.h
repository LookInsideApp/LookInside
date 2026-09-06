#import <Foundation/Foundation.h>
#import "ReactiveObjC.h"

NS_ASSUME_NONNULL_BEGIN

/// Serializes complete request streams, including work whose caller stopped waiting.
/// All entry points and source callbacks run on the main thread.
NS_SWIFT_NAME(InspectionRequestQueue)
@interface LKInspectionRequestQueue : NSObject

- (RACSignal *)enqueueRequest:(RACSignal *(^)(void))requestFactory;
/// Translates interruption only for an operation whose source has started.
- (RACSignal *)enqueueRequest:(RACSignal *(^)(void))requestFactory
           interruptionError:(NSError *(^_Nullable)(NSError *error))interruptionError;
- (void)invalidateWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
