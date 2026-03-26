#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION || TARGET_OS_MAC)
//
//  Lookin.h
//  Lookin
//
//  Created by Li Kai on 2018/8/5.
//  https://lookin.work
//

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#else
#import <UIKit/UIKit.h>
#endif

extern NSString *const LKS_ConnectionDidEndNotificationName;

@class LookinConnectionResponseAttachment;

@interface LKS_ConnectionManager : NSObject

+ (instancetype)sharedInstance;

@property(nonatomic, assign) BOOL applicationIsActive;
@property(nonatomic, assign) int preferredListenPort;

- (void)respond:(LookinConnectionResponseAttachment *)data requestType:(uint32_t)requestType tag:(uint32_t)tag;

- (void)pushData:(NSObject *)data type:(uint32_t)type;

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
