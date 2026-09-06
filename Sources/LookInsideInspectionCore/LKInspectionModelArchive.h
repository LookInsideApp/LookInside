#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Local model transfer between same-user inspection processes. This archive
/// includes images and must never be decoded from an untrusted network peer.
NS_SWIFT_UI_ACTOR
NS_SWIFT_NAME(InspectionModelArchive)
@interface LKInspectionModelArchive : NSObject
+ (nullable NSData *)encodeModel:(id)model error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(encode(_:));
+ (nullable id)decodeData:(NSData *)data error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(decode(_:));
@end

NS_ASSUME_NONNULL_END
