//
//  LookinLiveDocument.h
//  LookInside
//
//  A graphical document retaining a shared inspection session. The document
//  exports its presentation snapshot and does not own transport or reconnection.
//

#import <Cocoa/Cocoa.h>

@class LKInspectableApp, LKStaticHierarchyDataSource, LKStaticAsyncUpdateManager, LKStaticWindowController, LKInspectionSession;

NS_ASSUME_NONNULL_BEGIN

/// Posted after the graphical document and its window controllers are registered.
extern NSNotificationName const LookinLiveDocumentDidOpenNotification;

/// Posted (object = the document) at the start of `-close`, while the
/// document is still fully formed. Observers must not assume anything
/// about it survives the return of this notification.
extern NSNotificationName const LookinLiveDocumentWillCloseNotification;

@interface LookinLiveDocument : NSDocument

/// Owns inspection state before any window is constructed. Each window keeps
/// independent presentation models copied from this session.
@property(nonatomic, strong, readonly) LKInspectionSession *inspectionSession;

/// The session's current target. Reconnection can replace the app and channel.
@property(nonatomic, strong, readonly) LKInspectableApp *inspectableApp;

/// The session's connection-loss message, displayed by the graphical adapter.
@property(nonatomic, copy, readonly, nullable) NSString *connectionLossBannerMessage;

/// Convenience accessor that returns the per-doc hierarchy data source owned
/// by this document's window controller. Returns nil before
/// -makeWindowControllers has run.
@property(nonatomic, weak, readonly, nullable) LKStaticHierarchyDataSource *hierarchyDataSource;

/// Convenience accessor for this document's async update manager. Returns nil
/// before -makeWindowControllers has run.
@property(nonatomic, weak, readonly, nullable) LKStaticAsyncUpdateManager *asyncUpdateManager;

/// The graphical window controller, or nil before makeWindowControllers.
@property(nonatomic, weak, readonly, nullable) LKStaticWindowController *staticWindowController;

/// Retains the target's session; the caller establishes the channel beforehand.
- (nullable instancetype)initWithInspectableApp:(LKInspectableApp *)app
                                           error:(NSError *_Nullable *_Nullable)outError;

/// Returns the Live Doc whose window hosts `window`, or nil if `window`
/// is not bound to a Live Doc. Used by views and per-window utilities
/// that need to resolve "the inspectable app for this window" without
/// holding a direct doc reference.
+ (nullable instancetype)documentInWindow:(nullable NSWindow *)window;

@end

NS_ASSUME_NONNULL_END
