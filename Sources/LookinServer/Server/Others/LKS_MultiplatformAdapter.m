#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION || TARGET_OS_MAC)
//
//  LKS_MultiplatformAdapter.m
//  
//
//  Created by nixjiang on 2024/3/12.
//

#import "LKS_MultiplatformAdapter.h"
#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#else
#import <UIKit/UIKit.h>
#endif

@implementation LKS_MultiplatformAdapter

#if TARGET_OS_OSX

+ (NSWindow *)keyWindow {
    NSWindow *keyWindow = NSApplication.sharedApplication.keyWindow;
    if (keyWindow) {
        return keyWindow;
    }
    return [self allWindows].firstObject;
}

+ (NSArray<NSWindow *> *)allWindows {
    NSArray<NSWindow *> *windows = NSApplication.sharedApplication.orderedWindows ?: @[];
    return [windows filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSWindow *window, NSDictionary<NSString *, id> *bindings) {
        return window.contentView != nil;
    }]];
}

+ (NSImage *)screenshotForWindow:(NSWindow *)window {
    if (!window || !window.contentView) {
        return nil;
    }

    NSRect bounds = window.contentView.bounds;
    if (bounds.size.width <= 0 || bounds.size.height <= 0) {
        return nil;
    }

    NSBitmapImageRep *bitmapRep = [window.contentView bitmapImageRepForCachingDisplayInRect:bounds];
    if (!bitmapRep) {
        return nil;
    }
    [window.contentView cacheDisplayInRect:bounds toBitmapImageRep:bitmapRep];
    NSImage *image = [[NSImage alloc] initWithSize:bounds.size];
    [image addRepresentation:bitmapRep];
    return image;
}

+ (CGRect)mainScreenBounds {
    return NSScreen.mainScreen.frame;
}

+ (CGFloat)mainScreenScale {
    return NSScreen.mainScreen.backingScaleFactor ?: 1;
}

+ (NSString *)deviceDescription {
    NSString *name = NSHost.currentHost.localizedName;
    if (name.length) {
        return name;
    }
    return @"Mac";
}

+ (NSString *)operatingSystemDescription {
    NSProcessInfo *info = NSProcessInfo.processInfo;
    NSOperatingSystemVersion version = info.operatingSystemVersion;
    return [NSString stringWithFormat:@"macOS %ld.%ld.%ld", (long)version.majorVersion, (long)version.minorVersion, (long)version.patchVersion];
}

+ (NSUInteger)operatingSystemMainVersion {
    return NSProcessInfo.processInfo.operatingSystemVersion.majorVersion;
}

+ (BOOL)isiPad {
    return NO;
}

#else

+ (BOOL)isiPad {
    static BOOL s_isiPad = NO;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *nsModel = [UIDevice currentDevice].model;
        s_isiPad = [nsModel hasPrefix:@"iPad"];
    });

    return s_isiPad;
}

+ (CGRect)mainScreenBounds {
#if TARGET_OS_VISION
    return [LKS_MultiplatformAdapter getFirstActiveWindowScene].coordinateSpace.bounds;
#else
    return [UIScreen mainScreen].bounds;
#endif
}

+ (CGFloat)mainScreenScale {
#if TARGET_OS_VISION
    return 2.f;
#else
    return [UIScreen mainScreen].scale;
#endif
}

+ (NSString *)deviceDescription {
    return UIDevice.currentDevice.name ?: @"";
}

+ (NSString *)operatingSystemDescription {
    return UIDevice.currentDevice.systemVersion ?: @"";
}

+ (NSUInteger)operatingSystemMainVersion {
    NSString *mainVersionStr = [UIDevice.currentDevice.systemVersion componentsSeparatedByString:@"."].firstObject;
    return (NSUInteger)mainVersionStr.integerValue;
}

#if TARGET_OS_VISION
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

+ (UIWindow *)keyWindow {
#if TARGET_OS_VISION
    return [self getFirstActiveWindowScene].keyWindow;
#else
    return [UIApplication sharedApplication].keyWindow;
#endif
}

+ (NSArray<UIWindow *> *)allWindows {
#if TARGET_OS_VISION
    NSMutableArray<UIWindow *> *windows = [NSMutableArray new];
    for (UIScene *scene in
         UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        [windows addObjectsFromArray:windowScene.windows];
        
        // 以UIModalPresentationFormSheet形式展示的页面由系统私有window承载，不出现在scene.windows，不过可以从scene.keyWindow中获取
        if (![windows containsObject:windowScene.keyWindow]) {
            if (![NSStringFromClass(windowScene.keyWindow.class) containsString:@"HUD"]) {
                [windows addObject:windowScene.keyWindow];
            }
        }
    }

    return [windows copy];
#else
    return [[UIApplication sharedApplication].windows copy];
#endif
}

#endif

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
