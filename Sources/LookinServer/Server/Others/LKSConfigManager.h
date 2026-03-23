#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION)
//
//  LKSConfigManager.h
//  LookinServer
//
//  Created by likai.123 on 2023/1/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LKSConfigManager : NSObject

+ (NSArray<NSString *> *)collapsedClassList;

+ (NSDictionary<NSString *, UIColor *> *)colorAlias;

+ (BOOL)shouldCaptureScreenshotOfLayer:(CALayer *)layer;

@end

NS_ASSUME_NONNULL_END

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
