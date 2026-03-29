#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && TARGET_OS_OSX
//
//  NSWindow+LookinServer.h
//  LookinServer
//
//  Created by JH on 11/5/24.
//

#import "TargetConditionals.h"

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSWindow (LookinServer)
// NSWindow 的 rootView 是 contentView 的 superview，例如 NSThemeFrame
@property (nonatomic, readonly) NSView *lks_rootView;

- (NSImage *)lks_snapshotImage;

- (CGRect)lks_bounds;

@end

NS_ASSUME_NONNULL_END

#endif
