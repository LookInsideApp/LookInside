#import "LKInspectionEnvironment.h"

@implementation LKInspectionEnvironment

+ (instancetype)sharedEnvironment {
    static LKInspectionEnvironment *environment;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        environment = [LKInspectionEnvironment new];
    });
    return environment;
}

- (instancetype)init {
    if ((self = [super init])) {
        _clientReadableVersion = @"0";
        _hierarchyRequestTimeoutInterval = 30;
        _licenseHandshakeTimeoutInterval = 10;
        _initialCaptureOptions = @{};
    }
    return self;
}

@end
