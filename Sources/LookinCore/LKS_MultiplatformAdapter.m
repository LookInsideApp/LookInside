#ifdef SHOULD_COMPILE_LOOKIN_SERVER
//
//  LKS_MultiplatformAdapter.m
//
//
//  Created by nixjiang on 2024/3/12.
//

#import "LKS_MultiplatformAdapter.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

#if TARGET_OS_IPHONE
// Private +[UIScene _scenesIncludingInternal:] signature. Returns every
// UIScene the process has created, including ones UIApplication.connectedScenes
// hides (e.g. _UIKeyboardWindowScene on iOS 17+). Available since iOS 13.
@protocol _LKS_UISceneInternalClassAPI <NSObject>
+ (NSArray<UIScene *> *)_scenesIncludingInternal:(BOOL)includeInternal;
@end

// Private -[UIWindowScene _allWindowsIncludingInternalWindows:onlyVisibleWindows:]
// signature. The public `windows` getter routes through this with
// includeInternal=NO, filtering out every UIWindow whose -isInternalWindow
// returns YES. On iOS 26+ -[UIRemoteKeyboardWindow isInternalWindow] is
// hardcoded to YES, so the soft-keyboard window disappears from the public
// list. Calling with includeInternal=YES bypasses the filter and surfaces it.
@protocol _LKS_UIWindowSceneInternalAPI <NSObject>
- (NSArray<UIWindow *> *)_allWindowsIncludingInternalWindows:(BOOL)includeInternal
                                          onlyVisibleWindows:(BOOL)onlyVisible;
@end
#endif

@implementation LKS_MultiplatformAdapter

+ (BOOL)isiPad {
#if TARGET_OS_IPHONE
    static BOOL s_isiPad = NO;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *nsModel = [UIDevice currentDevice].model;
        s_isiPad = [nsModel hasPrefix:@"iPad"];
    });

    return s_isiPad;
#else
    return NO;
#endif
}

+ (BOOL)isMac {
#if TARGET_OS_OSX
    return YES;
#else
    return NO;
#endif
}

+ (CGRect)mainScreenBounds {
#if TARGET_OS_VISION || TARGET_OS_MACCATALYST
    return [LKS_MultiplatformAdapter getFirstActiveWindowScene].coordinateSpace.bounds;
#elif TARGET_OS_IPHONE
    return [UIScreen mainScreen].bounds;
#elif TARGET_OS_OSX
    // 这里不能返回屏幕的bounds，因为在macOS上，窗口可以不全屏显示，Lookin的设计是基于窗口的，一般iOS中屏幕的bounds就是窗口的bounds，所以这里直接返回窗口的bounds
    CGFloat maxWidth = 0;
    CGFloat maxHeight = 0;
    CGRect bounds = CGRectZero;
    for (NSWindow *window in NSApplication.sharedApplication.windows) {
        maxWidth = MAX(maxWidth, window.frame.size.width);
        maxHeight = MAX(maxHeight, window.frame.size.height);
    }
    bounds.size = CGSizeMake(maxWidth, maxHeight);
    return bounds;
#else
    return CGRectZero;
#endif
}

+ (CGFloat)mainScreenScale {
#if TARGET_OS_VISION
    return 2.f;
#elif TARGET_OS_IPHONE
    return [UIScreen mainScreen].scale;
#elif TARGET_OS_OSX
    return [NSScreen mainScreen].backingScaleFactor;
#else
    return 1.f;
#endif
}

#if TARGET_OS_VISION || TARGET_OS_MACCATALYST
+ (UIWindowScene *)getFirstActiveWindowScene {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        if (windowScene.activationState == UISceneActivationStateForegroundActive) {
            return windowScene;
        }
    }
    return nil;
}
#endif

+ (LookinWindow *)keyWindow {
#if TARGET_OS_VISION
    return [self getFirstActiveWindowScene].keyWindow;
#elif TARGET_OS_IPHONE
    return [LookinApplication sharedApplication].keyWindow;
#elif TARGET_OS_OSX
    return [LookinApplication sharedApplication].keyWindow;
#else
    return nil;
#endif
}


+ (NSArray<LookinWindow *> *)allWindows {
#if TARGET_OS_IPHONE
    NSArray<UIWindowScene *> *scenes = [self allWindowScenes];
    if (scenes.count > 0) {
        NSMutableArray<UIWindow *> *windows = [NSMutableArray new];
        for (UIWindowScene *windowScene in scenes) {
            for (UIWindow *window in [self allWindowsForWindowScene:windowScene]) {
                if (![windows containsObject:window]) {
                    [windows addObject:window];
                }
            }

            // UIModalPresentationFormSheet uses a private window that is
            // missing from scene.windows but reachable via scene.keyWindow.
            // UIWindowScene.keyWindow is iOS 15+ only; on iOS 13/14 the form
            // sheet window is reachable through scene.windows anyway.
            if (@available(iOS 15.0, tvOS 15.0, macCatalyst 15.0, *)) {
                UIWindow *sceneKeyWindow = windowScene.keyWindow;
                if (sceneKeyWindow && ![windows containsObject:sceneKeyWindow]) {
                    if (![NSStringFromClass(sceneKeyWindow.class) containsString:@"HUD"]) {
                        [windows addObject:sceneKeyWindow];
                    }
                }
            }
        }
        if (windows.count > 0) {
            return [windows copy];
        }
    }
#if TARGET_OS_VISION
    // visionOS deprecates -[UIApplication windows] outright; there's no global
    // window list to fall back to, so just return empty.
    return @[];
#else
    return [[LookinApplication sharedApplication].windows copy];
#endif
#else
    return [[LookinApplication sharedApplication].windows copy];
#endif
}

#if TARGET_OS_IPHONE
+ (NSArray<UIWindowScene *> *)allWindowScenes {
    NSArray<UIScene *> *allScenes = nil;
    Class<_LKS_UISceneInternalClassAPI> uiSceneClass = (Class<_LKS_UISceneInternalClassAPI>)UIScene.class;
    if ([uiSceneClass respondsToSelector:@selector(_scenesIncludingInternal:)]) {
        allScenes = [uiSceneClass _scenesIncludingInternal:YES];
    }
    if (allScenes.count == 0) {
        allScenes = UIApplication.sharedApplication.connectedScenes.allObjects;
    }

    NSMutableArray<UIWindowScene *> *windowScenes = [NSMutableArray arrayWithCapacity:allScenes.count];
    for (UIScene *scene in allScenes) {
        if ([scene isKindOfClass:UIWindowScene.class]) {
            [windowScenes addObject:(UIWindowScene *)scene];
        }
    }
    return [windowScenes copy];
}

+ (NSArray<UIWindow *> *)allWindowsForWindowScene:(UIWindowScene *)scene {
    if (!scene) {
        return @[];
    }
    SEL selector = @selector(_allWindowsIncludingInternalWindows:onlyVisibleWindows:);
    if ([scene respondsToSelector:selector]) {
        NSArray<UIWindow *> *windows = [(id<_LKS_UIWindowSceneInternalAPI>)scene
            _allWindowsIncludingInternalWindows:YES
            onlyVisibleWindows:NO];
        if (windows.count > 0) {
            return windows;
        }
    }
    return scene.windows ?: @[];
}
#endif

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
