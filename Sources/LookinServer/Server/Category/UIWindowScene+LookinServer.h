#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && TARGET_OS_IPHONE
//
//  UIWindowScene+LookinServer.h
//  LookinServer
//

#import "TargetConditionals.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface UIWindowScene (LookinServer)

// Returns the class chain list for this scene, truncated at UIScene
- (NSArray<NSArray<NSString *> *> *)lks_relatedClassChainList;

// Returns the self relation strings (delegate class name)
- (NSArray<NSString *> *)lks_selfRelation;

// Pass-through getters for sub-object properties
@property (nonatomic, readonly) NSInteger lks_windowCount;
@property (nonatomic, readonly, nullable) NSString *lks_keyWindowClassName;
@property (nonatomic, readonly) CGRect lks_screenBounds;
@property (nonatomic, readonly) CGFloat lks_screenScale;
@property (nonatomic, readonly) BOOL lks_statusBarHidden;
@property (nonatomic, readonly) NSInteger lks_statusBarStyle;
@property (nonatomic, readonly) CGRect lks_statusBarFrame;
@property (nonatomic, readonly) NSInteger lks_userInterfaceStyle;
@property (nonatomic, readonly) NSInteger lks_horizontalSizeClass;
@property (nonatomic, readonly) NSInteger lks_verticalSizeClass;
@property (nonatomic, readonly, nullable) NSString *lks_sessionPersistentIdentifier;
@property (nonatomic, readonly, nullable) NSString *lks_sessionRole;

// Additional trait getters
@property (nonatomic, readonly) NSInteger lks_userInterfaceLevel;
@property (nonatomic, readonly) NSInteger lks_activeAppearance;
@property (nonatomic, readonly) NSInteger lks_accessibilityContrast;
@property (nonatomic, readonly) NSInteger lks_legibilityWeight;
@property (nonatomic, readonly) CGFloat lks_traitDisplayScale;
@property (nonatomic, readonly) NSInteger lks_displayGamut;
@property (nonatomic, readonly) NSInteger lks_userInterfaceIdiom;
@property (nonatomic, readonly) NSInteger lks_layoutDirection;
@property (nonatomic, readonly, nullable) NSString *lks_preferredContentSizeCategory;
@property (nonatomic, readonly) NSInteger lks_sceneCaptureState;
@property (nonatomic, readonly) NSInteger lks_imageDynamicRange;
@property (nonatomic, readonly, nullable) NSString *lks_typesettingLanguage;

@end

NS_ASSUME_NONNULL_END

#endif
