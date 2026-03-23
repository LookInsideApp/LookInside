#import <Foundation/Foundation.h>
#import "LICDiscoveredTarget.h"

NS_ASSUME_NONNULL_BEGIN

@interface LICClient : NSObject

- (NSArray<LICDiscoveredTarget *> *)listTargets:(NSError **)error;
- (nullable LICDiscoveredTarget *)inspectTargetWithID:(NSString *)targetID error:(NSError **)error;
- (nullable NSString *)hierarchyForTargetID:(NSString *)targetID format:(NSString *)format error:(NSError **)error;
- (nullable NSURL *)exportTargetID:(NSString *)targetID outputPath:(NSString *)outputPath error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
