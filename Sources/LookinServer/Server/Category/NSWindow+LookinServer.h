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

// Returns the class chain list for this window, used by the Class attribute group
- (NSArray<NSArray<NSString *> *> *)lks_relatedClassChainList;

// Returns the self relation strings for this window, used by the Relation attribute group
- (NSArray<NSString *> *)lks_selfRelation;

@end

NS_ASSUME_NONNULL_END

#endif
