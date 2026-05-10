//
//  AppDelegate.m
//  Lookin
//
//  Created by Li Kai on 2018/8/4.
//  https://lookin.work
//

#import "AppDelegate.h"
#import "LKNavigationManager.h"
#import "LKConnectionManager.h"
#import "LKPreferenceManager.h"
#import "LKAppMenuManager.h"
#import "LKLaunchWindowController.h"
#import "LookinDocument.h"
#import "LookInside-Swift.h"
#import "NSString+Score.h"
#import "LookinDashboardBlueprint.h"
#import "LKPreferenceManager.h"
#import "LKAppsManager.h"
#import "LKInspectableApp.h"
#import "LookinLiveDocument.h"

@interface AppDelegate ()

@property(nonatomic, assign) BOOL launchedToOpenFile;

@end

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [[LKAppMenuManager sharedInstance] setup];
    
    [RACObserve([LKPreferenceManager mainManager], appearanceType) subscribeNext:^(NSNumber *number) {
        LookinPreferredAppeanranceType type = [number integerValue];
        switch (type) {
            case LookinPreferredAppeanranceTypeDark:
                NSApp.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
                break;
            case LookinPreferredAppeanranceTypeLight:
                NSApp.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
                break;
            default:
                NSApp.appearance = nil;
                break;
        }
    }];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [LKConnectionManager sharedInstance];
    if (!self.launchedToOpenFile) {
        [[LKNavigationManager sharedInstance] showLaunch];
    }

    [self _lk_installActivationStateObserverExample];

#ifdef DEBUG
    [self _runTests];
    [self _lk_installLiveDocDebugMenu];
#endif
}

#ifdef DEBUG

#pragma mark - Phase B Debug 后门

/// Phase B 临时菜单:Debug > Open Live Doc for Inspecting App。
/// 验收 LookinLiveDocument 能在不接连接流的前提下单独 spawn 一个窗口。
/// Phase D 完成连接流改造后,本菜单连同 -[_lk_debugOpenLiveDoc:] 一起删掉。
- (void)_lk_installLiveDocDebugMenu {
    NSMenu *mainMenu = NSApp.mainMenu;
    if (!mainMenu) {
        return;
    }
    NSMenuItem *debugRoot = [[NSMenuItem alloc] init];
    debugRoot.title = @"Debug";
    NSMenu *debugMenu = [[NSMenu alloc] initWithTitle:@"Debug"];
    debugRoot.submenu = debugMenu;
    [mainMenu addItem:debugRoot];

    NSMenuItem *openLiveDocItem = [[NSMenuItem alloc] initWithTitle:@"Open Live Doc for Inspecting App"
                                                             action:@selector(_lk_debugOpenLiveDoc:)
                                                      keyEquivalent:@""];
    openLiveDocItem.target = self;
    [debugMenu addItem:openLiveDocItem];
}

- (void)_lk_debugOpenLiveDoc:(id)sender {
    LKInspectableApp *app = [LKAppsManager sharedInstance].inspectingApp;
    if (!app) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"No inspecting app";
        alert.informativeText = @"Connect a target via the Launch window first, then try again.";
        [alert runModal];
        return;
    }
    NSError *error = nil;
    LookinLiveDocument *doc = [[LookinLiveDocument alloc] initWithInspectableApp:app error:&error];
    if (!doc) {
        if (error) {
            [NSApp presentError:error];
        }
        return;
    }
    [[NSDocumentController sharedDocumentController] addDocument:doc];
    [doc makeWindowControllers];
    [doc showWindows];
}

#endif

- (void)_lk_installActivationStateObserverExample {
    LKSwiftUISupportGatekeeper *gatekeeper = [LKSwiftUISupportGatekeeper sharedInstance];
    NSLog(@"[LK-Activation] initial state=%ld (polling every 5s; waits for auth server)",
          (long)gatekeeper.activationState);

    [NSNotificationCenter.defaultCenter
        addObserver:self
           selector:@selector(_lk_activationStateDidChange:)
               name:LKSwiftUISupportGatekeeper.activationStateDidChangeNotificationName
             object:nil];
}

- (void)_lk_activationStateDidChange:(NSNotification *)note {
    NSNumber *state = note.userInfo[@"activationState"];
    NSString *label;
    switch ((LKSwiftUISupportActivationState)state.integerValue) {
        case LKSwiftUISupportActivationStateUnknown:      label = @"unknown"; break;
        case LKSwiftUISupportActivationStateNotActivated: label = @"notActivated"; break;
        case LKSwiftUISupportActivationStateActivated:    label = @"activated"; break;
    }
    NSLog(@"[LK-Activation] state changed -> %@ (raw=%@)", label, state);
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    self.launchedToOpenFile = YES;
    NSError *error;
    BOOL isSuccessful = [[LKNavigationManager sharedInstance] showReaderWithFilePath:filename error:&error];    
    return isSuccessful;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    [[LKSwiftUISupportGatekeeper sharedInstance] shutdownRuntime];

    // 清理打开 UIImageView 的图片时创建的临时文件
    NSArray<NSString *> *tempImageFilesToDelete = [LKHelper sharedInstance].tempImageFiles;
    if (tempImageFilesToDelete.count == 0) {
        return NSTerminateNow;
    }
    [tempImageFilesToDelete enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isSucc = [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        if (!isSucc) {
            NSAssert(NO, @"");
        }
    }];
    return NSTerminateNow;
}

/// 一些单元测试
- (void)_runTests {
    // 确保 LookinAttrGroupIdentifier 的 value 没有重复
    NSArray<LookinAttrGroupIdentifier> *allGroupIDs = [LookinDashboardBlueprint groupIDs];
    NSSet<LookinAttrGroupIdentifier> *allGroupIDs_unique = [NSSet setWithArray:allGroupIDs];
    if (allGroupIDs.count != allGroupIDs_unique.count) {
        NSAssert(NO, @"");
    }
    
    // 确保 LookinAttrSectionIdentifier 的 value 没有重复
    NSMutableArray<LookinAttrSectionIdentifier> *allSecIDs = [NSMutableArray array];
    [allGroupIDs enumerateObjectsUsingBlock:^(LookinAttrGroupIdentifier  _Nonnull groupID, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<LookinAttrSectionIdentifier> *secIDs = [LookinDashboardBlueprint sectionIDsForGroupID:groupID];
        [allSecIDs addObjectsFromArray:secIDs];
    }];
    NSSet<LookinAttrSectionIdentifier> *allSecIDs_unique = [NSSet setWithArray:allSecIDs];
    if (allSecIDs.count != allSecIDs_unique.count) {
        NSAssert(NO, @"");
    }
    
    // 确保 LookinAttrIdentifier 的 value 没有重复
    NSMutableArray<LookinAttrIdentifier> *allAttrIDs = [NSMutableArray array];
    [allSecIDs enumerateObjectsUsingBlock:^(LookinAttrSectionIdentifier  _Nonnull secID, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<LookinAttrIdentifier> *attrIDs = [LookinDashboardBlueprint attrIDsForSectionID:secID];
        [allAttrIDs addObjectsFromArray:attrIDs];
    }];
    NSSet<LookinAttrIdentifier> *allAttrIDs_unique = [NSSet setWithArray:allAttrIDs];
    if (allAttrIDs.count != allAttrIDs_unique.count) {
        NSAssert(NO, @"");
    }
}

@end
