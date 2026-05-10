//
//  LookinLiveDocumentController.h
//  LookInside
//
//  Phase D of multi-document support: thin facade that opens (or activates)
//  a `LookinLiveDocument` for a given inspectable app. Acts as the single
//  entry point used by the launch screen, the toolbar app picker, and any
//  future "New Inspection" menu item, so that the rules around channel
//  de-duplication (Q3=P) and "always open in a new window" (Q1=X) live in
//  exactly one place.
//

#import <Foundation/Foundation.h>

@class LookinLiveDocument, LKInspectableApp, Lookin_PTChannel;

NS_ASSUME_NONNULL_BEGIN

@interface LookinLiveDocumentController : NSObject

+ (instancetype)sharedInstance;

/// Opens — or activates an already-open — Live Doc for `app`.
///
/// If a `LookinLiveDocument` already exists whose `inspectableApp.channel`
/// matches `app.channel`, that document's window is brought to front and the
/// completion is invoked with `alreadyOpen=YES` (Q3=P). Otherwise a fresh
/// `LookinLiveDocument` is constructed, registered with
/// `NSDocumentController`, and shown.
///
/// Completion fires on the main thread. If document construction fails
/// `doc` is nil and `err` is populated.
- (void)openLiveDocumentForInspectableApp:(LKInspectableApp *)app
                                completion:(nullable void (^)(LookinLiveDocument *_Nullable doc,
                                                              BOOL alreadyOpen,
                                                              NSError *_Nullable err))completion;

/// Returns the Live Doc currently bound to `channel`, if any. Used by the
/// auto-reconnect path so each Doc only reacts to its own channel ending.
/// Returns nil when `channel` is nil or no Live Doc owns it.
- (nullable LookinLiveDocument *)liveDocumentForChannel:(nullable Lookin_PTChannel *)channel;

@end

NS_ASSUME_NONNULL_END
