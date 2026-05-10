//
//  LookinLiveDocumentController.m
//  LookInside
//

#import "LookinLiveDocumentController.h"

#import <AppKit/AppKit.h>

#import "LookinLiveDocument.h"
#import "LKInspectableApp.h"
#import "Lookin_PTChannel.h"
#import "LookinDefines.h"

@implementation LookinLiveDocumentController

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static LookinLiveDocumentController *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

- (void)openLiveDocumentForInspectableApp:(LKInspectableApp *)app
                                completion:(void (^)(LookinLiveDocument *_Nullable doc,
                                                     BOOL alreadyOpen,
                                                     NSError *_Nullable err))completion {
    if (!app) {
        if (completion) {
            completion(nil, NO, LookinErr_Inner);
        }
        return;
    }

    void (^finish)(LookinLiveDocument *, BOOL, NSError *) = ^(LookinLiveDocument *doc,
                                                              BOOL alreadyOpen,
                                                              NSError *err) {
        if (!completion) {
            return;
        }
        if ([NSThread isMainThread]) {
            completion(doc, alreadyOpen, err);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(doc, alreadyOpen, err);
            });
        }
    };

    LookinLiveDocument *existing = [self liveDocumentForChannel:app.channel];
    if (existing) {
        // Q3=P: same channel already has a Live Doc, just bring it forward.
        [existing showWindows];
        finish(existing, YES, nil);
        return;
    }

    NSError *initError = nil;
    LookinLiveDocument *doc = [[LookinLiveDocument alloc] initWithInspectableApp:app error:&initError];
    if (!doc) {
        finish(nil, NO, initError ?: LookinErr_Inner);
        return;
    }

    [[NSDocumentController sharedDocumentController] addDocument:doc];
    [doc makeWindowControllers];
    [doc showWindows];
    finish(doc, NO, nil);
}

- (LookinLiveDocument *)liveDocumentForChannel:(Lookin_PTChannel *)channel {
    if (!channel) {
        return nil;
    }
    NSDocumentController *controller = [NSDocumentController sharedDocumentController];
    for (NSDocument *doc in controller.documents) {
        if (![doc isKindOfClass:[LookinLiveDocument class]]) {
            continue;
        }
        LookinLiveDocument *liveDoc = (LookinLiveDocument *)doc;
        if (liveDoc.inspectableApp.channel == channel) {
            return liveDoc;
        }
    }
    return nil;
}

@end
