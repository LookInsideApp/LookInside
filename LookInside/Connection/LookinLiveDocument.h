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

/// The inspectable app this document represents. Fixed for the document's
/// lifetime; reconnect logic (Phase D) replaces the channel underneath but
/// keeps the LKInspectableApp identity stable.
@property(nonatomic, strong, readonly) LKInspectableApp *inspectableApp;

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

@end

NS_ASSUME_NONNULL_END
