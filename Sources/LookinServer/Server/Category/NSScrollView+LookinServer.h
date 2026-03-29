#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && TARGET_OS_OSX
//
//  NSScrollView+LookinServer.h
//  LookinServer
//
//  Created by JH on 2024/11/7.
//

#import "TargetConditionals.h"

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSScrollView (LookinServer)

@property (nonatomic) CGPoint lks_contentOffset;
@property (nonatomic) CGSize lks_contentSize;

@end

NS_ASSUME_NONNULL_END

#endif
