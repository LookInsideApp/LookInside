#import "LKInspectionModelArchive.h"
#import "LKInspectionSession.h"
#import "LookinDisplayItem.h"

// The wire model normally omits screenshots from hierarchy archives. Preserve
// them for local snapshots without changing that model's wire encoding policy.
@interface LKInspectionModelArchiverDelegate : NSObject <NSKeyedArchiverDelegate>
@property(nonatomic, strong) NSMapTable<LookinDisplayItem *, NSNumber *> *originalImageEncoding;
- (void)restoreImageEncoding;
@end

@implementation LKInspectionModelArchiverDelegate
- (instancetype)init {
    if ((self = [super init])) {
        _originalImageEncoding = [NSMapTable strongToStrongObjectsMapTable];
    }
    return self;
}
- (id)archiver:(NSKeyedArchiver *)archiver willEncodeObject:(id)object {
    if ([object isKindOfClass:LookinDisplayItem.class] && ![self.originalImageEncoding objectForKey:object]) {
        LookinDisplayItem *item = object;
        [self.originalImageEncoding setObject:@(item.screenshotEncodeType) forKey:item];
        item.screenshotEncodeType = LookinDisplayItemImageEncodeTypeImage;
    }
    return object;
}
- (void)restoreImageEncoding {
    for (LookinDisplayItem *item in self.originalImageEncoding.keyEnumerator) {
        item.screenshotEncodeType = [self.originalImageEncoding objectForKey:item].unsignedIntegerValue;
    }
}
@end


@implementation LKInspectionModelArchive
+ (NSData *)encodeModel:(id)model error:(NSError **)error {
    NSAssert(NSThread.isMainThread, @"Inspection models must be encoded on the main thread.");
    LKInspectionModelArchiverDelegate *archiveDelegate = [LKInspectionModelArchiverDelegate new];
    @try {
        NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
        encoder.delegate = archiveDelegate;
        [encoder encodeObject:model forKey:NSKeyedArchiveRootObjectKey];
        [encoder finishEncoding];
        return encoder.encodedData;
    } @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:LKInspectionSessionErrorDomain code:LKInspectionSessionErrorInvalidResponse
                                    userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: @"The model could not be encoded."}];
        }
        return nil;
    } @finally {
        [archiveDelegate restoreImageEncoding];
    }
}

+ (id)decodeData:(NSData *)data error:(NSError **)error {
    NSAssert(NSThread.isMainThread, @"Inspection models must be decoded on the main thread.");
    @try {
        NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:error];
        decoder.requiresSecureCoding = NO;
        id result = [decoder decodeObjectForKey:NSKeyedArchiveRootObjectKey];
        [decoder finishDecoding];
        return result;
    } @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:LKInspectionSessionErrorDomain code:LKInspectionSessionErrorInvalidResponse
                                    userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: @"The model could not be decoded."}];
        }
        return nil;
    }
}
@end
