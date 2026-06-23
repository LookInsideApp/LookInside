#ifdef SHOULD_COMPILE_LOOKIN_SERVER
//
//  LKS_MultiplatformAdapter.h
//
//
//  Created by nixjiang on 2024/3/12.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

#import "LookinDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKS_MultiplatformAdapter : NSObject

+ (LookinWindow *)keyWindow;

+ (NSArray<LookinWindow *> *)allWindows;

#if TARGET_OS_IPHONE
/// Returns every live UIWindowScene, including internal ones that
/// UIApplication.connectedScenes hides (e.g. _UIKeyboardWindowScene on
/// iOS 17+). Falls back to connectedScenes if the private entry point is
/// unavailable.
+ (NSArray<UIWindowScene *> *)allWindowScenes;

/// Returns every UIWindow attached to the given scene, including ones whose
/// -isInternalWindow returns YES (e.g. UIRemoteKeyboardWindow on iOS 26+,
/// which is filtered out by the public -[UIWindowScene windows] getter).
/// Falls back to scene.windows if the private getter is unavailable.
+ (NSArray<UIWindow *> *)allWindowsForWindowScene:(UIWindowScene *)scene;
#endif

+ (CGRect)mainScreenBounds;

+ (CGFloat)mainScreenScale;

+ (BOOL)isiPad;

+ (BOOL)isMac;

@end

NS_ASSUME_NONNULL_END

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
