#import "LKInspectionRequestQueue.h"

@interface LKInspectionQueuedRequest : NSObject
@property(nonatomic, copy, nullable) RACSignal *(^requestFactory)(void);
@property(nonatomic, strong, nullable) id<RACSubscriber> subscriber;
@property(nonatomic, strong, nullable) RACDisposable *subscription;
@property(nonatomic, assign) BOOL started;
@property(nonatomic, assign) BOOL finished;
@property(nonatomic, copy, nullable) NSError *(^interruptionError)(NSError *error);
@end

@implementation LKInspectionQueuedRequest
@end

@interface LKInspectionRequestQueue ()
@property(nonatomic, strong) NSMutableArray<LKInspectionQueuedRequest *> *requests;
@property(nonatomic, strong, nullable) NSError *invalidationError;
@end

@implementation LKInspectionRequestQueue

- (instancetype)init {
    if ((self = [super init])) {
        _requests = [NSMutableArray array];
    }
    return self;
}

- (RACSignal *)enqueueRequest:(RACSignal *(^)(void))requestFactory {
    return [self enqueueRequest:requestFactory interruptionError:nil];
}

- (RACSignal *)enqueueRequest:(RACSignal *(^)(void))requestFactory
           interruptionError:(NSError *(^)(NSError *error))interruptionError {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSAssert(NSThread.isMainThread, @"Inspection requests must run on the main thread.");
        if (self.invalidationError) {
            [subscriber sendError:self.invalidationError];
            return nil;
        }
        LKInspectionQueuedRequest *request = [LKInspectionQueuedRequest new];
        request.requestFactory = requestFactory;
        request.interruptionError = interruptionError;
        request.subscriber = subscriber;
        [self.requests addObject:request];
        [self startNextRequest];
        return [RACDisposable disposableWithBlock:^{
            void (^cancelWaiting)(void) = ^{
                request.subscriber = nil;
                if (!request.started && !request.finished) {
                    request.finished = YES;
                    [self.requests removeObjectIdenticalTo:request];
                    [self startNextRequest];
                }
                // A sent operation still drains to its terminal event. Disposing
                // an observer cannot undo a target-side mutation or cancel another
                // subscriber's detail stream.
            };
            if (NSThread.isMainThread) {
                cancelWaiting();
            } else {
                dispatch_async(dispatch_get_main_queue(), cancelWaiting);
            }
        }];
    }];
}

- (void)startNextRequest {
    LKInspectionQueuedRequest *request = self.requests.firstObject;
    if (!request || request.started || self.invalidationError) {
        return;
    }
    request.started = YES;
    RACSignal *source = request.requestFactory();
    request.requestFactory = nil;
    request.subscription = [source subscribeNext:^(id value) {
        if (!request.finished) {
            [request.subscriber sendNext:value];
        }
    } error:^(NSError *error) {
        [self finishRequest:request error:error];
    } completed:^{
        [self finishRequest:request error:nil];
    }];
    if (request.finished) {
        [request.subscription dispose];
        request.subscription = nil;
    }
}

- (void)finishRequest:(LKInspectionQueuedRequest *)request error:(NSError *)error {
    if (request.finished) {
        return;
    }
    request.finished = YES;
    id<RACSubscriber> subscriber = request.subscriber;
    request.subscriber = nil;
    request.subscription = nil;
    request.interruptionError = nil;
    // Keep the finished entry at the head while notifying the caller. A
    // reentrant enqueue must not jump ahead of previously queued operations.
    if (error) {
        [subscriber sendError:error];
    } else {
        [subscriber sendCompleted];
    }
    [self.requests removeObjectIdenticalTo:request];
    [self startNextRequest];
}

- (void)invalidateWithError:(NSError *)error {
    NSAssert(NSThread.isMainThread, @"Inspection requests must run on the main thread.");
    self.invalidationError = error;
    NSArray<LKInspectionQueuedRequest *> *requests = self.requests.copy;
    [self.requests removeAllObjects];
    for (LKInspectionQueuedRequest *request in requests) {
        request.finished = YES;
        [request.subscription dispose];
        request.subscription = nil;
        id<RACSubscriber> subscriber = request.subscriber;
        request.subscriber = nil;
        request.requestFactory = nil;
        NSError *reportedError = request.started && request.interruptionError ? request.interruptionError(error) : error;
        request.interruptionError = nil;
        [subscriber sendError:reportedError];
    }
}

@end
