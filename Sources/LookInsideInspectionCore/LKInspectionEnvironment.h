#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Noninteractive host policy supplied before discovering or inspecting targets.
/// UI presentation belongs to observers in the graphical application.
NS_SWIFT_NAME(InspectionEnvironment)
@interface LKInspectionEnvironment : NSObject
+ (instancetype)sharedEnvironment;
@property(nonatomic, copy) NSString *clientReadableVersion;
@property(nonatomic, assign) NSTimeInterval hierarchyRequestTimeoutInterval;
@property(nonatomic, assign) NSTimeInterval licenseHandshakeTimeoutInterval;
@property(nonatomic, copy) NSDictionary<NSString *, id> *initialCaptureOptions;
@property(nonatomic, copy, nullable) NSDictionary<NSString *, id> *(^initialCaptureOptionsProvider)(void);
@property(nonatomic, copy, nullable) BOOL (^licenseIsActivated)(void);
@property(nonatomic, copy, nullable) NSDictionary<NSString *, id> *_Nullable (^licenseProofForChallenge)(
    NSDictionary<NSString *, id> *challenge, NSError *_Nullable *_Nullable error);
@end

NS_ASSUME_NONNULL_END
