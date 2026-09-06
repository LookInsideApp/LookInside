//
//  LookinLiveDocument.m
//  LookInside
//

#import "LookinLiveDocument.h"
#import <LookInsideInspectionCore/LookInsideInspectionCore.h>
#import "LKInspectableApp.h"
#import "LKStaticHierarchyDataSource.h"
#import "LKStaticAsyncUpdateManager.h"
#import "LKStaticWindowController.h"
#import "LKAppsManager.h"
#import "LKConnectionManager.h"
#import "Lookin_PTChannel.h"
#import "LookinAppInfo.h"
#import "LookinHierarchyInfo.h"
#import "LKExportManager.h"
#import "LookinDefines.h"

NSNotificationName const LookinLiveDocumentDidOpenNotification = @"LookinLiveDocumentDidOpenNotification";
NSNotificationName const LookinLiveDocumentWillCloseNotification = @"LookinLiveDocumentWillCloseNotification";

@implementation LookinLiveDocument

- (nullable instancetype)initWithInspectableApp:(LKInspectableApp *)app
                                           error:(NSError *_Nullable *_Nullable)outError {
    if (!app) {
        if (outError) {
            *outError = LookinErr_Inner;
        }
        return nil;
    }
    if (self = [super init]) {
        _inspectionSession = [LKInspectionSessionRegistry.sharedRegistry sessionForInspectableApp:app];
    }
    return self;
}

+ (instancetype)documentInWindow:(NSWindow *)window {
    if (!window) {
        return nil;
    }
    NSDocument *doc = [[NSDocumentController sharedDocumentController] documentForWindow:window];
    if ([doc isKindOfClass:[LookinLiveDocument class]]) {
        return (LookinLiveDocument *)doc;
    }
    return nil;
}

- (LKStaticWindowController *)staticWindowController {
    LKStaticWindowController *wc = (LKStaticWindowController *)self.windowControllers.firstObject;
    if ([wc isKindOfClass:[LKStaticWindowController class]]) {
        return wc;
    }
    return nil;
}

- (LKStaticHierarchyDataSource *)hierarchyDataSource {
    return self.staticWindowController.hierarchyDataSource;
}

- (LKStaticAsyncUpdateManager *)asyncUpdateManager {
    return self.staticWindowController.asyncUpdateManager;
}

#pragma mark - NSDocument overrides

- (NSString *)displayName {
    LookinAppInfo *info = self.inspectableApp.appInfo;
    if (info.appName.length && info.deviceDescription.length) {
        return [NSString stringWithFormat:@"%@ — %@", info.appName, info.deviceDescription];
    } else if (info.appName.length) {
        return info.appName;
    }
    return [super displayName];
}

- (BOOL)hasUnautosavedChanges {
    return NO;
}

- (BOOL)isDocumentEdited {
    return NO;
}

+ (BOOL)autosavesInPlace {
    return NO;
}

+ (BOOL)autosavesDrafts {
    return NO;
}

+ (BOOL)preservesVersions {
    return NO;
}

+ (BOOL)usesUbiquitousStorage {
    return NO;
}

- (NSArray<NSString *> *)writableTypesForSaveOperation:(NSSaveOperationType)saveOperation {
    if (saveOperation == NSSaveAsOperation) {
        return @[@"com.lookin.lookin"];
    }
    return @[];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    if (![typeName isEqualToString:@"com.lookin.lookin"]) {
        if (outError) {
            *outError = LookinErr_Inner;
        }
        return nil;
    }
    LookinHierarchyInfo *info = self.hierarchyDataSource.rawHierarchyInfo;
    if (!info) {
        if (outError) {
            *outError = LookinErr_Inner;
        }
        return nil;
    }
    NSData *data = [[LKExportManager sharedInstance] dataFromHierarchyInfo:info
                                                          imageCompression:1.0
                                                                  fileName:NULL];
    if (!data) {
        if (outError) {
            *outError = LookinErr_Inner;
        }
        return nil;
    }
    return data;
}

- (void)makeWindowControllers {
    LKStaticWindowController *wc = [[LKStaticWindowController alloc] initWithInspectableApp:self.inspectableApp];
    [self addWindowController:wc];
}

- (LKInspectableApp *)inspectableApp {
    return self.inspectionSession.inspectableApp;
}

- (NSString *)connectionLossBannerMessage {
    return self.inspectionSession.connectionLossBannerMessage;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingInspectableApp {
    return [NSSet setWithObject:@"inspectionSession.inspectableApp"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingConnectionLossBannerMessage {
    return [NSSet setWithObject:@"inspectionSession.connectionLossBannerMessage"];
}

- (void)close {
    [[NSNotificationCenter defaultCenter] postNotificationName:LookinLiveDocumentWillCloseNotification object:self];
    [super close];
}

@end
