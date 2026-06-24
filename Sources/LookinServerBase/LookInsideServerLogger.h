#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const LookInsideServerLogLevelEnvironmentKey;

typedef NS_ENUM(NSInteger, LookInsideServerLogLevel) {
    /// Detailed diagnostics.
    LookInsideServerLogLevelDebug = 0,
    /// High-volume runtime events.
    LookInsideServerLogLevelInfo = 1,
    /// Normal lifecycle events. This is the default.
    LookInsideServerLogLevelDefault = 2,
    /// Unexpected but recoverable conditions.
    LookInsideServerLogLevelWarning = 3,
    /// Failures and invalid states.
    LookInsideServerLogLevelError = 4,
};

@interface LookInsideServerLogger : NSObject

@property(class, atomic, readonly) LookInsideServerLogLevel minimumLogLevel;

+ (BOOL)shouldLogAtLevel:(LookInsideServerLogLevel)level;
+ (void)logWithLevel:(LookInsideServerLogLevel)level message:(NSString *)message;

@end

#define LookInsideServerLogAtLevel(level, format, ...) \
    do { \
        if ([LookInsideServerLogger shouldLogAtLevel:(level)]) { \
            [LookInsideServerLogger logWithLevel:(level) message:[NSString stringWithFormat:(format), ##__VA_ARGS__]]; \
        } \
    } while (0)

#define LookInsideServerLogDebug(format, ...) LookInsideServerLogAtLevel(LookInsideServerLogLevelDebug, (format), ##__VA_ARGS__)
#define LookInsideServerLogInfo(format, ...) LookInsideServerLogAtLevel(LookInsideServerLogLevelInfo, (format), ##__VA_ARGS__)
#define LookInsideServerLogDefault(format, ...) LookInsideServerLogAtLevel(LookInsideServerLogLevelDefault, (format), ##__VA_ARGS__)
#define LookInsideServerLogWarning(format, ...) LookInsideServerLogAtLevel(LookInsideServerLogLevelWarning, (format), ##__VA_ARGS__)
#define LookInsideServerLogError(format, ...) LookInsideServerLogAtLevel(LookInsideServerLogLevelError, (format), ##__VA_ARGS__)

NS_ASSUME_NONNULL_END
