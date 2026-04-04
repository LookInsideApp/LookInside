#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && TARGET_OS_IPHONE
//
//  UIWindowScene+LookinServer.m
//  LookinServer
//

#import "UIWindowScene+LookinServer.h"
#import "NSObject+LookinServer.h"
#import "NSArray+Lookin.h"

@implementation UIWindowScene (LookinServer)

- (NSArray<NSArray<NSString *> *> *)lks_relatedClassChainList {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:1];
    NSArray<NSString *> *completedList = [self lks_classChainList];
    NSUInteger endingIndex = [completedList indexOfObject:@"UIScene"];
    if (endingIndex != NSNotFound) {
        completedList = [completedList subarrayWithRange:NSMakeRange(0, endingIndex + 1)];
    }
    [array addObject:completedList];
    return array.copy;
}

- (NSArray<NSString *> *)lks_selfRelation {
    NSMutableArray *array = [NSMutableArray array];
    if (self.delegate) {
        [array addObject:[NSString stringWithFormat:@"(%@ *) delegate", NSStringFromClass([(NSObject *)self.delegate class])]];
    }
    return array.copy;
}

- (NSInteger)lks_windowCount {
    return (NSInteger)self.windows.count;
}

- (NSString *)lks_keyWindowClassName {
    UIWindow *keyWindow = nil;
    if (@available(iOS 15.0, *)) {
        keyWindow = self.keyWindow;
    } else {
        for (UIWindow *window in self.windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
    }
    return keyWindow ? NSStringFromClass(keyWindow.class) : nil;
}

- (CGRect)lks_screenBounds {
    return self.screen ? self.screen.bounds : CGRectZero;
}

- (CGFloat)lks_screenScale {
    return self.screen ? self.screen.scale : 1.0;
}

- (BOOL)lks_statusBarHidden {
    return self.statusBarManager ? self.statusBarManager.isStatusBarHidden : YES;
}

- (NSInteger)lks_statusBarStyle {
    return self.statusBarManager ? (NSInteger)self.statusBarManager.statusBarStyle : 0;
}

- (CGRect)lks_statusBarFrame {
    return self.statusBarManager ? self.statusBarManager.statusBarFrame : CGRectZero;
}

- (NSInteger)lks_userInterfaceStyle {
    return (NSInteger)self.traitCollection.userInterfaceStyle;
}

- (NSInteger)lks_horizontalSizeClass {
    return (NSInteger)self.traitCollection.horizontalSizeClass;
}

- (NSInteger)lks_verticalSizeClass {
    return (NSInteger)self.traitCollection.verticalSizeClass;
}

- (NSString *)lks_sessionPersistentIdentifier {
    return self.session.persistentIdentifier;
}

- (NSString *)lks_sessionRole {
    return self.session.role;
}

- (NSInteger)lks_userInterfaceLevel {
    return (NSInteger)self.traitCollection.userInterfaceLevel;
}

- (NSInteger)lks_activeAppearance {
    if (@available(iOS 14.0, *)) {
        return (NSInteger)self.traitCollection.activeAppearance;
    }
    return -1;
}

- (NSInteger)lks_accessibilityContrast {
    return (NSInteger)self.traitCollection.accessibilityContrast;
}

- (NSInteger)lks_legibilityWeight {
    return (NSInteger)self.traitCollection.legibilityWeight;
}

- (CGFloat)lks_traitDisplayScale {
    return self.traitCollection.displayScale;
}

- (NSInteger)lks_displayGamut {
    return (NSInteger)self.traitCollection.displayGamut;
}

- (NSInteger)lks_userInterfaceIdiom {
    return (NSInteger)self.traitCollection.userInterfaceIdiom;
}

- (NSInteger)lks_layoutDirection {
    return (NSInteger)self.traitCollection.layoutDirection;
}

- (NSString *)lks_preferredContentSizeCategory {
    return self.traitCollection.preferredContentSizeCategory;
}

- (NSInteger)lks_sceneCaptureState {
    if (@available(iOS 17.0, *)) {
        return (NSInteger)self.traitCollection.sceneCaptureState;
    }
    return -1;
}

- (NSInteger)lks_imageDynamicRange {
    if (@available(iOS 17.0, *)) {
        return (NSInteger)self.traitCollection.imageDynamicRange;
    }
    return -1;
}

- (NSString *)lks_typesettingLanguage {
    if (@available(iOS 17.0, *)) {
        return self.traitCollection.typesettingLanguage;
    }
    return nil;
}

@end

#endif
