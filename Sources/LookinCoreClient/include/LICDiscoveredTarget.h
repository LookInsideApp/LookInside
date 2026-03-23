#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LICDiscoveredTarget : NSObject

@property(nonatomic, copy) NSString *targetID;
@property(nonatomic, copy) NSString *transport;
@property(nonatomic, assign) NSInteger port;
@property(nonatomic, copy, nullable) NSString *deviceID;
@property(nonatomic, copy) NSString *appName;
@property(nonatomic, copy) NSString *bundleIdentifier;
@property(nonatomic, copy) NSString *deviceDescription;
@property(nonatomic, copy) NSString *osDescription;
@property(nonatomic, assign) NSInteger serverVersion;
@property(nonatomic, copy) NSString *serverReadableVersion;
@property(nonatomic, assign) NSInteger appInfoIdentifier;

@end

NS_ASSUME_NONNULL_END

