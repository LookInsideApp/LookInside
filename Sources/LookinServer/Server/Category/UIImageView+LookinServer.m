#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION)
//
//  UIImageView+LookinServer.m
//  LookinServer
//
//  Created by Li Kai on 2019/9/18.
//  https://lookin.work
//

#import "UIImageView+LookinServer.h"
#import "UIImage+LookinServer.h"
#import "NSObject+LookinServer.h"

@implementation UIImageView (LookinServer)

- (NSString *)lks_imageSourceName {
    return self.image.lks_imageSourceName;
}

- (NSNumber *)lks_imageViewOidIfHasImage {
    if (!self.image) {
        return nil;
    }
    unsigned long oid = [self lks_registerOid];
    return @(oid);
}

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
