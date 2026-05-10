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
#import "LKWindowController.h"
#import "LookinArchiveDocument.h"
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
    // Phase C: launch window only appears when no document has been opened by the
    // OS (Finder double-click / Open With) before this point.
    NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
    if (!self.launchedToOpenFile && documentController.documents.count == 0) {
        [[LKNavigationManager sharedInstance] showLaunch];
    }

    [self _lk_installActivationStateObserverExample];

    // Phase E: when the last document closes, bring Launch back (Q2=A) so the
    // app never sits without any visible UI.
    [NSNotificationCenter.defaultCenter
        addObserver:self
           selector:@selector(_lk_handleWindowWillClose:)
               name:NSWindowWillCloseNotification
             object:nil];

#ifdef DEBUG
    [self _runTests];
    [self _lk_installLiveDocDebugMenu];
#endif
}

- (void)_lk_handleWindowWillClose:(NSNotification *)note {
    NSWindow *closingWindow = note.object;
    if (![closingWindow.windowController isKindOfClass:[LKWindowController class]]) {
        return;
    }
    // Closing the Launch window itself shouldn't re-spawn Launch; only Doc
    // (Live / Archive) windows trigger the "no docs left" reopen.
    LKLaunchWindowController *launchWC = [LKNavigationManager sharedInstance].launchWindowController;
    if (closingWindow == launchWC.window) {
        return;
    }
    // Defer one tick so NSDocumentController has finished removing the doc.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _lk_showLaunchIfNoDocuments];
    });
}

- (void)_lk_showLaunchIfNoDocuments {
    if ([NSDocumentController sharedDocumentController].documents.count > 0) {
        return;
    }
    LKLaunchWindowController *launchWC = [LKNavigationManager sharedInstance].launchWindowController;
    if (launchWC.window.isVisible) {
        return;
    }
    [[LKNavigationManager sharedInstance] showLaunch];
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // Debug-only bridge: reads the deprecated single-app slot to spawn a Live
    // Doc against whatever the legacy launch flow connected to. Removed in Phase F
    // along with the slot itself.
    LKInspectableApp *app = [LKAppsManager sharedInstance].inspectingApp;
#pragma clang diagnostic pop
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
    // Phase E (Q2=A): keep the app alive after the last window closes so we can
    // bring the Launch window back instead of quitting. Quit goes through the
    // standard Cmd-Q path.
    return NO;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    // Phase E: there is no meaningful "untitled" document in this app. New
    // Inspection / Open are explicit user actions; suppress the macOS default
    // behavior that would create one on activation.
    return NO;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender {
    return NO;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    // Dock-icon click after closing all windows: bring Launch back.
    if (!flag) {
        [self _lk_showLaunchIfNoDocuments];
    }
    return YES;
}

- (void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls {
    // Phase C: replaces the legacy -application:openFile:. Routing flows through
    // NSDocumentController so .lookin archives integrate with Recent Documents,
    // proxy icon dragging, Save As, and de-duplication of already-open files.
    self.launchedToOpenFile = YES;
    NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
    for (NSURL *url in urls) {
        [documentController openDocumentWithContentsOfURL:url
                                                   display:YES
                                         completionHandler:^(NSDocument *_Nullable document,
                                                             BOOL alreadyOpen,
                                                             NSError *_Nullable error) {
            if (!document && error) {
                [NSApp presentError:error];
            }
        }];
    }
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
