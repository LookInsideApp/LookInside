#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION)
//
//  UIColor+LookinServer.h
//  LookinServer
//
//  Created by Li Kai on 2019/6/5.
//  https://lookin.work
//

#import <UIKit/UIKit.h>

@interface UIColor (LookinServer)

- (NSArray<NSNumber *> *)lks_rgbaComponents;
+ (instancetype)lks_colorFromRGBAComponents:(NSArray<NSNumber *> *)components;

- (NSString *)lks_rgbaString;
- (NSString *)lks_hexString;

/// will check if the argument is a real CGColor
+ (UIColor *)lks_colorWithCGColor:(CGColorRef)cgColor;

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
