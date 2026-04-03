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
@property (nonatomic, readonly, nullable) NSView *lks_rootView;

- (NSImage *)lks_snapshotImage;

- (CGRect)lks_bounds;

// Returns the class chain list for this window, used by the Class attribute group
- (NSArray<NSArray<NSString *> *> *)lks_relatedClassChainList;

// Returns the self relation strings for this window, used by the Relation attribute group
- (NSArray<NSString *> *)lks_selfRelation;

// styleMask flag accessors - individual BOOL getters/setters for each mask bit
@property (nonatomic, readonly) BOOL lks_styleMaskTitled;
@property (nonatomic, readonly) BOOL lks_styleMaskClosable;
@property (nonatomic, readonly) BOOL lks_styleMaskMiniaturizable;
@property (nonatomic, readonly) BOOL lks_styleMaskResizable;
@property (nonatomic, readonly) BOOL lks_styleMaskUnifiedTitleAndToolbar;
@property (nonatomic, readonly) BOOL lks_styleMaskFullScreen;
@property (nonatomic, readonly) BOOL lks_styleMaskFullSizeContentView;
@property (nonatomic, readonly) BOOL lks_styleMaskUtilityWindow;
@property (nonatomic, readonly) BOOL lks_styleMaskDocModalWindow;
@property (nonatomic, readonly) BOOL lks_styleMaskNonactivatingPanel;
@property (nonatomic, readonly) BOOL lks_styleMaskHUDWindow;

// collectionBehavior flag accessors
@property (nonatomic, readonly) BOOL lks_collectionBehaviorCanJoinAllSpaces;
@property (nonatomic, readonly) BOOL lks_collectionBehaviorMoveToActiveSpace;
@property (nonatomic, readonly) BOOL lks_collectionBehaviorParticipatesInCycle;
@property (nonatomic, readonly) BOOL lks_collectionBehaviorIgnoresCycle;
@property (nonatomic, readonly) BOOL lks_collectionBehaviorFullScreenPrimary;
@property (nonatomic, readonly) BOOL lks_collectionBehaviorFullScreenAuxiliary;
@property (nonatomic, readonly) BOOL lks_collectionBehaviorFullScreenNone;
@property (nonatomic, readonly) BOOL lks_collectionBehaviorFullScreenAllowsTiling;
@property (nonatomic, readonly) BOOL lks_collectionBehaviorFullScreenDisallowsTiling;

@end

NS_ASSUME_NONNULL_END

#endif
