#ifdef SHOULD_COMPILE_LOOKIN_SERVER

#import "LookInsideServerLogger.h"

NSString *const LookInsideServerLogLevelEnvironmentKey = @"LOOKINSIDE_SERVER_LOG_LEVEL";

static LookInsideServerLogLevel LookInsideServerLogLevelFromEnvironment(void) {
    NSString *rawValue = NSProcessInfo.processInfo.environment[LookInsideServerLogLevelEnvironmentKey];
    if (rawValue.length == 0) {
        return LookInsideServerLogLevelDefault;
    }

    NSString *value = [rawValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if ([value isEqualToString:@"0"]) {
        return LookInsideServerLogLevelDebug;
    }
    if ([value isEqualToString:@"1"]) {
        return LookInsideServerLogLevelInfo;
    }
    if ([value isEqualToString:@"2"]) {
        return LookInsideServerLogLevelDefault;
    }
    if ([value isEqualToString:@"3"]) {
        return LookInsideServerLogLevelWarning;
    }
    if ([value isEqualToString:@"4"]) {
        return LookInsideServerLogLevelError;
    }
    return LookInsideServerLogLevelDefault;
}

static NSString *LookInsideServerLogLevelName(LookInsideServerLogLevel level) {
    switch (level) {
        case LookInsideServerLogLevelDebug:
            return @"debug";
        case LookInsideServerLogLevelInfo:
            return @"info";
        case LookInsideServerLogLevelDefault:
            return @"default";
        case LookInsideServerLogLevelWarning:
            return @"warning";
        case LookInsideServerLogLevelError:
            return @"error";
    }
}

@implementation LookInsideServerLogger

+ (LookInsideServerLogLevel)minimumLogLevel {
    static LookInsideServerLogLevel level;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        level = LookInsideServerLogLevelFromEnvironment();
    });
    return level;
}

+ (BOOL)shouldLogAtLevel:(LookInsideServerLogLevel)level {
    LookInsideServerLogLevel minimumLevel = self.minimumLogLevel;
    return level >= minimumLevel;
}

+ (void)logWithLevel:(LookInsideServerLogLevel)level message:(NSString *)message {
    if (![self shouldLogAtLevel:level]) {
        return;
    }
    NSLog(@"LookinServer [%@] - %@", LookInsideServerLogLevelName(level), message);
}

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
