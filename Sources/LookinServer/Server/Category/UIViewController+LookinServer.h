#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION)
//
//  UIViewController+LookinServer.h
//  LookinServer
//
//  Created by Li Kai on 2019/4/22.
//  https://lookin.work
//

#import <UIKit/UIKit.h>

@interface UIViewController (LookinServer)

+ (UIViewController *)lks_visibleViewController;

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
