#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION || TARGET_OS_MAC)
//
//  LKS_ExportManager.h
//  LookinServer
//
//  Created by Li Kai on 2019/5/13.
//  https://lookin.work
//

#import <Foundation/Foundation.h>

@interface LKS_ExportManager : NSObject

+ (instancetype)sharedInstance;

- (void)exportAndShare;

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
