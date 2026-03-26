#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION || TARGET_OS_MAC)
//
//  LKS_MultiplatformAdapter.h
//  
//
//  Created by nixjiang on 2024/3/12.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#else
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface LKS_MultiplatformAdapter : NSObject

#if TARGET_OS_OSX

+ (NSWindow *)keyWindow;

+ (NSArray<NSWindow *> *)allWindows;

+ (NSImage *)screenshotForWindow:(NSWindow *)window;

#else

+ (UIWindow *)keyWindow;

+ (NSArray<UIWindow *> *)allWindows;

#endif

+ (CGRect)mainScreenBounds;

+ (CGFloat)mainScreenScale;

+ (NSString *)deviceDescription;

+ (NSString *)operatingSystemDescription;

+ (NSUInteger)operatingSystemMainVersion;

+ (BOOL)isiPad;

@end

NS_ASSUME_NONNULL_END

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
