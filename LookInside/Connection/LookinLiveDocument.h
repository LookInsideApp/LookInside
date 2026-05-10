//
//  LookinLiveDocument.h
//  LookInside
//
//  Phase B of multi-document support: NSDocument that owns a single live
//  Peertalk inspection session against one LKInspectableApp. The document
//  is "untitled" by default, never autosaves, and exposes Save As to export
//  the current hierarchy snapshot as a `.lookin` archive.
//

#import <Cocoa/Cocoa.h>

@class LKInspectableApp, LKStaticHierarchyDataSource, LKStaticAsyncUpdateManager, LKStaticWindowController;

NS_ASSUME_NONNULL_BEGIN

@interface LookinLiveDocument : NSDocument

/// The inspectable app this document represents. Stable for callers in the
/// sense that the document keeps its identity, but Phase D reconnect logic
/// will swap the underlying `LKInspectableApp` (new channel + new
/// LookinAppInfo) when the previous channel goes away and a matching app
/// reappears. Public surface remains readonly; internal class extension
/// declares the readwrite override.
@property(nonatomic, strong, readonly) LKInspectableApp *inspectableApp;

/// Phase D: human-readable reason for the current connection loss, or nil
/// when the doc is connected. Phase E will surface this as a banner in
/// the window controller; Phase D leaves it as a side-channel for that
/// upcoming UI work and for debugging in the meantime.
@property(nonatomic, copy, readonly, nullable) NSString *connectionLossBannerMessage;

/// Convenience accessor that returns the per-doc hierarchy data source owned
/// by this document's window controller. Returns nil before
/// -makeWindowControllers has run.
@property(nonatomic, weak, readonly, nullable) LKStaticHierarchyDataSource *hierarchyDataSource;

/// Convenience accessor for this document's async update manager. Returns nil
/// before -makeWindowControllers has run.
@property(nonatomic, weak, readonly, nullable) LKStaticAsyncUpdateManager *asyncUpdateManager;

/// Designated initializer. Returns nil with `outError` populated when `app`
/// is nil. Phase B does not establish or validate the channel here; that is
/// the caller's responsibility.
- (nullable instancetype)initWithInspectableApp:(LKInspectableApp *)app
                                           error:(NSError *_Nullable *_Nullable)outError;

/// Returns the Live Doc whose window hosts `window`, or nil if `window`
/// is not bound to a Live Doc. Used by views and per-window utilities
/// that need to resolve "the inspectable app for this window" without
/// holding a direct doc reference.
+ (nullable instancetype)documentInWindow:(nullable NSWindow *)window;

@end

NS_ASSUME_NONNULL_END
