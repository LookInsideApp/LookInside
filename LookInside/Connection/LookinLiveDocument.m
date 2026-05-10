//
//  LookinLiveDocument.m
//  LookInside
//

#import "LookinLiveDocument.h"
#import "LKInspectableApp.h"
#import "LKStaticHierarchyDataSource.h"
#import "LKStaticAsyncUpdateManager.h"
#import "LKStaticWindowController.h"
#import "LookinAppInfo.h"
#import "LookinHierarchyInfo.h"
#import "LKExportManager.h"
#import "LookinDefines.h"

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
        _inspectableApp = app;
    }
    return self;
}

- (LKStaticHierarchyDataSource *)hierarchyDataSource {
    LKStaticWindowController *wc = (LKStaticWindowController *)self.windowControllers.firstObject;
    if ([wc isKindOfClass:[LKStaticWindowController class]]) {
        return wc.hierarchyDataSource;
    }
    return nil;
}

- (LKStaticAsyncUpdateManager *)asyncUpdateManager {
    LKStaticWindowController *wc = (LKStaticWindowController *)self.windowControllers.firstObject;
    if ([wc isKindOfClass:[LKStaticWindowController class]]) {
        return wc.asyncUpdateManager;
    }
    return nil;
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

@end
