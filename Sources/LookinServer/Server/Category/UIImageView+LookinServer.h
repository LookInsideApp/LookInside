#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION)
//
//  UIImageView+LookinServer.h
//  LookinServer
//
//  Created by Li Kai on 2019/9/18.
//  https://lookin.work
//

#import <UIKit/UIKit.h>

@interface UIImageView (LookinServer)

- (NSString *)lks_imageSourceName;
- (NSNumber *)lks_imageViewOidIfHasImage;

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
