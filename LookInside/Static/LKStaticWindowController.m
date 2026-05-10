//
//  LKStaticWindowController.m
//  Lookin
//
//  Created by Li Kai on 2018/11/4.
//  https://lookin.work
//

#import "LKStaticWindowController.h"
#import "LKStaticViewController.h"
#import "LKMenuPopoverSettingController.h"
#import "LKStaticHierarchyDataSource.h"
#import "LKNavigationManager.h"
#import "LKPreferenceManager.h"
#import "LKAppsManager.h"
#import "LKInspectableApp.h"
#import "LKMenuPopoverAppsListController.h"
#import "LKProgressIndicatorView.h"
#import "LookinDisplayItem.h"
#import "LookinObject.h"
#import "LKWindowToolbarHelper.h"
#import "LKWindowToolbarAppButton.h"
#import "LKExportManager.h"
#import "LookinHierarchyInfo.h"
#import "LKExportAccessoryView.h"
#import "LKWindow.h"
#import "LKStaticAsyncUpdateManager.h"
#import "LookinHierarchyFile.h"
#import "LookinLiveDocument.h"
#import "LookinLiveDocumentController.h"
#import "LKPreviewView.h"
#import "LKHierarchyView.h"
#import "LKPerformanceReporter.h"
#import "LKMessageManager.h"
#import "LKHelper.h"
#import "LKSwiftUIHierarchyDisplayMode.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface LKStaticWindowController () <NSToolbarDelegate, LKStaticAsyncUpdateManagerDelegate>

@property(nonatomic, strong) NSMutableDictionary<NSString *, NSToolbarItem *> *toolbarItemsMap;

/// 当拉取 hierarchy 和更新截图时，该属性为 YES
@property(nonatomic, assign) BOOL isFetchingHierarchy;
@property(nonatomic, assign) BOOL isFetchingDetails;

@property(nonatomic, strong, readwrite) LKStaticHierarchyDataSource *hierarchyDataSource;
@property(nonatomic, strong, readwrite) LKStaticAsyncUpdateManager *asyncUpdateManager;

@end

@implementation LKStaticWindowController

- (instancetype)initWithInspectableApp:(LKInspectableApp *)app {
    if (self = [self init]) {
        // 由 LookinLiveDocument 调用,把 app 注入到本 wc 与其 asyncUpdateManager,
        // 这样所有 RPC 请求(reload、modify 等)都路由到该 app 的 channel。
        self.inspectableApp = app;
        self.asyncUpdateManager.inspectableApp = app;
    }
    return self;
}

- (instancetype)init {
    NSSize screenSize = [NSScreen mainScreen].frame.size;
    LKWindow *window = [[LKWindow alloc] initWithContentRect:NSMakeRect(0, 0, screenSize.width * .7, screenSize.height * .7) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable|NSWindowStyleMaskFullSizeContentView backing:NSBackingStoreBuffered defer:YES];
    window.tabbingMode = NSWindowTabbingModeDisallowed;
    window.titleVisibility = NSWindowTitleHidden;
    if (@available(macOS 11.0, *)) {
        window.toolbarStyle = NSWindowToolbarStyleUnified;
    }
    window.minSize = NSMakeSize(HierarchyMinWidth + DashboardViewWidth + 200, 500);
    [window center];
    [window setFrameUsingName:LKWindowSizeName_Static];
    
    if (self = [self initWithWindow:window]) {
        // Phase F: persist this window's frame across launches using
        // AppKit's window-controller autosave hook. The previous
        // `LKNavigationManager.windowWillClose:` save path went away
        // with `staticWindowController`, so saving moves here.
        self.windowFrameAutosaveName = LKWindowSizeName_Static;
        // 创建 viewController 之前先 new 自己的 dataSource + updateManager。
        _hierarchyDataSource = [[LKStaticHierarchyDataSource alloc] init];
        _asyncUpdateManager = [[LKStaticAsyncUpdateManager alloc] initWithHierarchyDataSource:_hierarchyDataSource
                                                                                inspectableApp:nil];
        _hierarchyDataSource.asyncUpdateManager = _asyncUpdateManager;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_handleSwiftUIModeDidChange:)
                                                     name:LKSwiftUIHierarchyDisplayModeDidChangeNotification
                                                   object:nil];

        // LKStaticViewController's -setView: runs synchronously inside its
        // designated init, so the per-doc data source / update manager are
        // passed in up-front rather than via post-init property writes.
        _viewController = [[LKStaticViewController alloc] initWithHierarchyDataSource:_hierarchyDataSource
                                                                    asyncUpdateManager:_asyncUpdateManager];
        window.contentView = self.viewController.view;
        self.contentViewController = self.viewController;

        NSToolbar *toolbar = [[NSToolbar alloc] init];
        toolbar.displayMode = NSToolbarDisplayModeIconAndLabel;
        toolbar.sizeMode = NSToolbarSizeModeRegular;
        toolbar.delegate = self;
        window.toolbar = toolbar;

        NSToolbarItem *reloadItem = self.toolbarItemsMap[LKToolBarIdentifier_Reload];
        @weakify(self);
        self.asyncUpdateManager.delegate = self;

        [[[RACSignal combineLatest:@[RACObserve(self, isFetchingHierarchy),
                                     RACObserve(self, isFetchingDetails)]] distinctUntilChanged] subscribeNext:^(RACTuple * _Nullable x) {
            @strongify(self);
            [@[LKToolBarIdentifier_App, LKToolBarIdentifier_Console, LKToolBarIdentifier_FastMode] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSToolbarItem *item = self.toolbarItemsMap[obj];
                if (self.isFetchingHierarchy || self.isFetchingDetails) {
                    item.enabled = NO;
                } else {
                    item.enabled = YES;
                }
            }];
        }];
        [[RACObserve(self, isFetchingHierarchy) distinctUntilChanged] subscribeNext:^(NSNumber *x) {
            reloadItem.enabled = ![x boolValue];
        }];

        [RACObserve(self.hierarchyDataSource, selectedItem) subscribeNext:^(id  _Nullable x) {
            @strongify(self);
            NSButton *measureButton = (NSButton *)self.toolbarItemsMap[LKToolBarIdentifier_Measure].view;
            BOOL canMeasure = !!x;
            measureButton.enabled = canMeasure;
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _autoConnectAppIfRequested];
        });
    }
    return self;
}

- (void)_autoConnectAppIfRequested {
    NSDictionary<NSString *, NSString *> *environment = NSProcessInfo.processInfo.environment;
    NSString *targetBundleID = environment[@"LOOKINSIDE_AUTO_CONNECT_BUNDLE_ID"];
    BOOL shouldConnectFirst = [environment[@"LOOKINSIDE_AUTO_CONNECT_FIRST"] boolValue];
    if (targetBundleID.length == 0 && !shouldConnectFirst) {
        return;
    }

    [self.viewController.progressView animateToProgress:InitialIndicatorProgressWhenFetchHierarchy];

    @weakify(self);
    [[[[LKAppsManager sharedInstance] fetchAppInfosWithImage:YES localInfos:nil] deliverOnMainThread] subscribeNext:^(NSArray<LKInspectableApp *> *apps) {
        @strongify(self);
        LKInspectableApp *targetApp = nil;
        if (targetBundleID.length > 0) {
            targetApp = [apps lookin_firstFiltered:^BOOL(LKInspectableApp *app) {
                return [app.appInfo.appBundleIdentifier isEqualToString:targetBundleID];
            }];
        } else if (shouldConnectFirst) {
            targetApp = [apps lookin_firstFiltered:^BOOL(LKInspectableApp *app) {
                return app.serverVersionError == nil && app.appInfo != nil;
            }];
        }

        if (!targetApp) {
            [self.viewController.progressView resetToZero];
            return;
        }

        // Phase F: per-window inspectableApp is now the only source of
        // truth — the deprecated single-slot global fallback is gone.
        LKInspectableApp *currentApp = self.inspectableApp;
        BOOL isTheSameApp = currentApp && [currentApp.appInfo isEqualToAppInfo:targetApp.appInfo];
        [[targetApp fetchHierarchyData] subscribeNext:^(LookinHierarchyInfo *info) {
            [self _applyHierarchyInfo:info forApp:targetApp keepState:isTheSameApp];
        } error:^(NSError * _Nullable error) {
            [self.viewController.progressView resetToZero];
            AlertError(error, self.window);
        }];
    } error:^(NSError * _Nullable error) {
        @strongify(self);
        [self.viewController.progressView resetToZero];
    }];
}

- (void)popupAllInspectableAppsWithSource:(MenuPopoverAppsListControllerEventSource)source {
    NSView *appItemView = [self.toolbarItemsMap objectForKey:LKToolBarIdentifier_App].view;

    @weakify(self);
    [[[[LKAppsManager sharedInstance] fetchAppInfosWithImage:YES localInfos:nil] deliverOnMainThread] subscribeNext:^(NSArray<LKInspectableApp *> *apps) {
        @strongify(self);
        LKMenuPopoverAppsListController *vc = [[LKMenuPopoverAppsListController alloc] initWithApps:apps source:source];
        NSPopover *popover = [[NSPopover alloc] init];
        @weakify(popover);
        vc.didSelectApp = ^(LKInspectableApp *app) {
            @strongify(self);
            @strongify(popover);
            [popover close];

            if (app.serverVersionError) {
                if (app.serverVersionError.code == LookinErrCode_ServerVersionTooLow) {
                    [LKHelper openLookinWebsiteWithPath:@"faq/server-version-too-low/"];
                } else {
                    [LKHelper openLookinWebsiteWithPath:@"faq/server-version-too-high/"];
                }
                return;
            }

            // Phase D (Q1=X): a different App means "open in a new window"
            // rather than swapping this window's target. The current doc keeps
            // its identity (its `inspectableApp` and channel are untouched),
            // and `LookinLiveDocumentController` handles channel-level
            // de-duplication (Q3=P) so picking the *same* second App while it
            // is already open just refocuses that other window.
            LookinAppInfo *currentInfo = self.inspectableApp.appInfo;
            BOOL isTheSameApp = currentInfo && [currentInfo isEqualToAppInfo:app.appInfo];

            if (!isTheSameApp) {
                [[LookinLiveDocumentController sharedInstance]
                    openLiveDocumentForInspectableApp:app
                                           completion:nil];
                return;
            }

            // Same app — keep the historic in-place reload behavior.
            [self.viewController.progressView animateToProgress:InitialIndicatorProgressWhenFetchHierarchy];
            [[app fetchHierarchyData] subscribeNext:^(LookinHierarchyInfo *info) {
                [self _applyHierarchyInfo:info forApp:app keepState:YES];
            } error:^(NSError * _Nullable error) {
                AlertError(error, self.window);
                [self.viewController.progressView resetToZero];
            }];
        };

        popover.behavior = NSPopoverBehaviorTransient;
        popover.animates = NO;
        popover.contentSize = vc.bestSize;
        popover.contentViewController = vc;
        [popover showRelativeToRect:NSMakeRect(0, 0, appItemView.bounds.size.width, appItemView.bounds.size.height) ofView:appItemView preferredEdge:NSRectEdgeMaxY];

    } error:^(NSError * _Nullable error) {
        NSAssert(NO, @"该方法不应该 sendError");
    }];
}

#pragma mark - NSToolbarDelegate

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    NSMutableArray *ret = @[LKToolBarIdentifier_Reload, LKToolBarIdentifier_FastMode, LKToolBarIdentifier_App, LKToolBarIdentifier_SwiftUIMode, NSToolbarFlexibleSpaceItemIdentifier, LKToolBarIdentifier_Dimension, LKToolBarIdentifier_Rotation, LKToolBarIdentifier_Setting, NSToolbarFlexibleSpaceItemIdentifier, LKToolBarIdentifier_Scale, NSToolbarFlexibleSpaceItemIdentifier, LKToolBarIdentifier_Measure, LKToolBarIdentifier_Console].mutableCopy;
    if ([[[LKMessageManager sharedInstance] queryMessages] count] > 0) {
        [ret addObject:LKToolBarIdentifier_Message];
    }
    return [ret copy];;
}

- (nullable NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *item = self.toolbarItemsMap[itemIdentifier];
    if (!item) {
        if (!self.toolbarItemsMap) {
            self.toolbarItemsMap = [NSMutableDictionary dictionary];
        }
        item = [[LKWindowToolbarHelper sharedInstance] makeToolBarItemWithIdentifier:itemIdentifier preferenceManager:[LKPreferenceManager mainManager]];
        self.toolbarItemsMap[itemIdentifier] = item;
        
        if ([item.itemIdentifier isEqualToString:LKToolBarIdentifier_Reload]) {
            item.target = self;
            item.action = @selector(_handleReload);
        } else if ([item.itemIdentifier isEqualToString:LKToolBarIdentifier_App]) {
            item.target = self;
            item.action = @selector(_handleApp);
            // Phase F: bind this window's App icon to the owning Live
            // Doc's inspectable app. KVO covers Phase D auto-reconnect
            // because `LookinLiveDocument` swaps `inspectableApp` in
            // place when the channel comes back.
            LKWindowToolbarAppButton *appButton = (LKWindowToolbarAppButton *)item.view;
            [[RACObserve(self, inspectableApp) takeUntil:item.rac_willDeallocSignal]
                subscribeNext:^(LKInspectableApp *app) {
                appButton.appInfo = app.appInfo;
            }];
        } else if ([item.itemIdentifier isEqualToString:LKToolBarIdentifier_Rotation]) {
            item.target = self;
            item.action = @selector(_handleFreeRotation);
        } else if ([item.itemIdentifier isEqualToString:LKToolBarIdentifier_Setting]) {
            item.label = NSLocalizedString(@"View", nil);
            item.target = self;
            item.action = @selector(_handleSetting:);
        } else if ([item.itemIdentifier isEqualToString:LKToolBarIdentifier_Console]) {
            item.target = self;
            item.action = @selector(_handleConsole);
            
            [[[RACObserve(self.viewController, showConsole) distinctUntilChanged] skip:1] subscribeNext:^(NSNumber *x) {
                ((NSButton *)item.view).state = x.boolValue ? NSControlStateValueOn : NSControlStateValueOff;
            }];
        } else if ([item.itemIdentifier isEqualToString:LKToolBarIdentifier_Message]) {
            item.label = NSLocalizedString(@"Notifications", nil);
            item.target = self;
            item.action = @selector(_handleMessage:);
        } else if ([item.itemIdentifier isEqualToString:LKToolBarIdentifier_FastMode]) {
            item.target = self;
            item.action = @selector(handleFastMode);
        }
    }
    return item;
}

#pragma mark - Event Handler

- (void)_handleReload {
    if (self.isFetchingDetails) {
        // 停止拉取
        [self.asyncUpdateManager endUpdating];
        return;
    }

    // Phase F: this window's bound app is the only source of truth.
    LKInspectableApp *app = self.inspectableApp;
    if (!app) {
        [self popupAllInspectableAppsWithSource:MenuPopoverAppsListControllerEventSourceReloadButton];
        return;
    }
    
    if (self.isFetchingHierarchy) {
        return;
    }
    
    self.isFetchingHierarchy = YES;
    
    [self.viewController.progressView animateToProgress:InitialIndicatorProgressWhenFetchHierarchy];
    
    [LKPerformanceReporter.sharedInstance willStartReload];
    @weakify(self);
    [[app fetchHierarchyData] subscribeNext:^(LookinHierarchyInfo *info) {
        [self.viewController.progressView finishWithCompletion:nil];
        [self.hierarchyDataSource reloadWithHierarchyInfo:info keepState:YES];
        self.isFetchingHierarchy = NO;

        [LKPerformanceReporter.sharedInstance didFetchHierarchy];
        
    } error:^(NSError * _Nullable error) {
        // error
        @strongify(self);
        [self.viewController.progressView resetToZero];
        self.isFetchingHierarchy = NO;
        
        [[NSAlert alertWithError:error] beginSheetModalForWindow:self.window completionHandler:nil];
    }];
}

- (void)_handleApp {
    // 停止可能存在的刷新倒计时    
    [self popupAllInspectableAppsWithSource:MenuPopoverAppsListControllerEventSourceAppButton];
}

- (void)_handleSetting:(NSButton *)button {
    NSPopover *popover = [[NSPopover alloc] init];
    popover.behavior = NSPopoverBehaviorTransient;
    popover.animates = NO;
    popover.contentSize = NSMakeSize(IsEnglish ? 270 : 350, 200);
    popover.contentViewController = [[LKMenuPopoverSettingController alloc] initWithPreferenceManager:[LKPreferenceManager mainManager]];
    [popover showRelativeToRect:NSMakeRect(0, 0, button.bounds.size.width, button.bounds.size.height) ofView:button preferredEdge:NSRectEdgeMaxY];
}

- (void)_handleConsole {
    self.viewController.showConsole = !self.viewController.showConsole;
}

- (void)handleFastMode {
    BOOL boolValue = [LKPreferenceManager mainManager].fastMode.currentBOOLValue;
    [[LKPreferenceManager mainManager].fastMode setBOOLValue:!boolValue ignoreSubscriber:nil];
}

- (void)_handleMessage:(NSButton *)button {
    NSMenu *menu = [NSMenu new];
    
    NSArray<NSString *> *msgs = [[LKMessageManager sharedInstance] queryMessages];
    for (NSString *msg in msgs) {
        if ([msg isEqualToString:LKMessage_Jobs]) {
            [menu addItem:({
                NSMenuItem *menuItem = [NSMenuItem new];
                menuItem.image = [NSImage imageNamed:@"Icon_Inspiration_small"];
                menuItem.title = NSLocalizedString(@"Job openings…(China)", nil);
                menuItem.target = self;
                menuItem.action = @selector(handleJobsMenuItem);
                menuItem;
            })];
            [menu addItem:[NSMenuItem separatorItem]];
            continue;
        }
        
        if ([msg isEqualToString:LKMessage_SwiftSubspec]) {
            [menu addItem:({
                NSMenuItem *menuItem = [NSMenuItem new];
                menuItem.image = [NSImage imageNamed:@"Icon_Inspiration_small"];
                menuItem.title = NSLocalizedString(@"Your iOS project seems to use Swift, but you haven't turn on Swift optimization for LookInside", nil);
                menuItem;
            })];
            [menu addItem:({
                NSMenuItem *menuItem = [NSMenuItem new];
                menuItem.image = [[NSImage alloc] initWithSize:NSMakeSize(18, 1)];
                menuItem.title = NSLocalizedString(@"How to turn on…", nil);
                menuItem.target = self;
                menuItem.action = @selector(handleTurnOnSwift);
                menuItem;
            })];
            [menu addItem:[NSMenuItem separatorItem]];
            continue;
        }
    }

    if (menu.numberOfItems == 0) {
        [menu addItem:({
            NSMenuItem *menuItem = [NSMenuItem new];
            menuItem.title = NSLocalizedString(@"No message", nil);
            menuItem;
        })];
    }
    
    [NSMenu popUpContextMenu:menu withEvent:[[NSApplication sharedApplication] currentEvent] forView:button];
}

- (void)_handleFreeRotation {
    BOOL boolValue = [LKPreferenceManager mainManager].freeRotation.currentBOOLValue;
    [[LKPreferenceManager mainManager].freeRotation setBOOLValue:!boolValue ignoreSubscriber:nil];
}

#pragma mark - <LKAppMenuManagerDelegate>

- (void)appMenuManagerDidSelectReload {    
    if (self.isFetchingHierarchy) {
        return;
    }
    if (self.isFetchingDetails) {
        NSError *error = LookinErrorMake(NSLocalizedString(@"Cannot reload at this time", NIL), NSLocalizedString(@"Please wait until current sync is completed. You can get sync progress in the upper-left corner of this window.", nil));
        [[NSAlert alertWithError:error] beginSheetModalForWindow:self.window completionHandler:nil];
        return;
    }
    [self _handleReload];
}

- (void)appMenuManagerDidSelectDimension {
    LKPreferenceManager *manager = [LKPreferenceManager mainManager];
    if (manager.previewDimension.currentIntegerValue == LookinPreviewDimension2D) {
        [manager.previewDimension setIntegerValue:LookinPreviewDimension3D ignoreSubscriber:nil];
    } else {
        [manager.previewDimension setIntegerValue:LookinPreviewDimension2D ignoreSubscriber:nil];
    }
}

- (void)appMenuManagerDidSelectZoomIn {
    LKPreferenceManager *manager = [LKPreferenceManager mainManager];
    double currentScale = manager.previewScale.currentDoubleValue;
    double targetScale = MIN(MAX(currentScale + 0.1, LookinPreviewMinScale), LookinPreviewMaxScale);
    [manager.previewScale setDoubleValue:targetScale ignoreSubscriber:nil];
}

- (void)appMenuManagerDidSelectZoomOut {
    LKPreferenceManager *manager = [LKPreferenceManager mainManager];
    double currentScale = manager.previewScale.currentDoubleValue;
    double targetScale = MIN(MAX(currentScale - 0.1, LookinPreviewMinScale), LookinPreviewMaxScale);
    [manager.previewScale setDoubleValue:targetScale ignoreSubscriber:nil];
}

- (void)appMenuManagerDidSelectDecreaseInterspace {
    LKPreferenceManager *manager = [LKPreferenceManager mainManager];
    double currentValue = manager.zInterspace.currentDoubleValue;
    double newValue = currentValue - 0.1;
    newValue = MIN(MAX(newValue, LookinPreviewMinZInterspace), LookinPreviewMaxZInterspace);
    [manager.zInterspace setDoubleValue:newValue ignoreSubscriber:nil];
}

- (void)appMenuManagerDidSelectIncreaseInterspace {
    LKPreferenceManager *manager = [LKPreferenceManager mainManager];
    double currentValue = manager.zInterspace.currentDoubleValue;
    double newValue = currentValue + 0.1;
    newValue = MIN(MAX(newValue, LookinPreviewMinZInterspace), LookinPreviewMaxZInterspace);
    [manager.zInterspace setDoubleValue:newValue ignoreSubscriber:nil];
}

- (void)appMenuManagerDidSelectExpansionIndex:(NSUInteger)index {
    [self.hierarchyDataSource adjustExpansionByIndex:index referenceDict:nil selectedItem:nil];
}

- (void)appMenuManagerDidSelectExport {
    LKExportManager *exportManager = [LKExportManager sharedInstance];
    LookinHierarchyInfo *hierarchyInfo = self.hierarchyDataSource.rawHierarchyInfo;
    
    __block NSString *fileName;
    __block NSData *exportedData = nil;
    
    LKExportAccessoryView *accessoryView = [LKExportAccessoryView new];
    $(accessoryView).sizeToFit;
    [RACObserve([LKPreferenceManager mainManager], preferredExportCompression) subscribeNext:^(NSNumber *num) {
        CGFloat compression = num.doubleValue;
        exportedData = [exportManager dataFromHierarchyInfo:hierarchyInfo imageCompression:compression fileName:&fileName];
        accessoryView.dataSize = exportedData.length;
    }];
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.accessoryView = accessoryView;
    [panel setNameFieldStringValue:fileName];
    [panel setAllowsOtherFileTypes:NO];
    panel.allowedContentTypes = @[[UTType typeWithIdentifier:@"com.lookin.lookin"] ?: UTTypeData];
    [panel setExtensionHidden:YES];
    [panel setCanCreateDirectories:YES];
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            NSString *path = [[panel URL] path];
            NSError *writeError;
            if (!exportedData) {
                NSAssert(NO, @"LookinClient - write fail, no data");
                return;
            }
            BOOL writeSucc = [exportedData writeToFile:path options:0 error:&writeError];
            if (!writeSucc) {
                NSLog(@"LookinClient - write fail:%@", writeError);
            }
        }
    }];
    
}

- (void)appMenuManagerDidSelectOpenInNewWindow {
    LookinHierarchyInfo *newHierarchyInfo = self.hierarchyDataSource.rawHierarchyInfo.copy;
    LookinHierarchyFile *file = [LookinHierarchyFile new];
    file.serverVersion = newHierarchyInfo.serverVersion;
    file.hierarchyInfo = newHierarchyInfo;
    [[LKNavigationManager sharedInstance] showReaderWithHierarchyFile:file title:nil];
}

- (void)appMenuManagerDidSelectFilter {
    [[self.viewController currentHierarchyView] activateSearchBar];
}

- (void)handleJobsMenuItem {
    [LKHelper showDisabledExternalLinkAlertWithMessage:NSLocalizedString(@"This upstream community link is not available in this build.", nil)];
    [[LKMessageManager sharedInstance] removeMessage:LKMessage_Jobs];
}

- (void)handleTurnOnSwift {
    [LKHelper showDisabledExternalLinkAlertWithMessage:NSLocalizedString(@"Legacy Swift integration guides are disabled in this community build. See the repository README instead.", nil)];
}


/// LKStaticAsyncUpdateManagerDelegate
- (void)detailUpdateTasksTotalCount:(NSUInteger)totalCount finishedCount:(NSUInteger)finishedCount {
    NSToolbarItem *reloadItem = self.toolbarItemsMap[LKToolBarIdentifier_Reload];
    NSButton *reloadButton = (NSButton *)reloadItem.view;
    
    BOOL isFetching = (totalCount > finishedCount);
    
    if (isFetching) {
        if (self.isFetchingDetails) {
            // 继续维持 fetch 状态
        } else {
            // 进入 fetch 状态
            self.isFetchingDetails = YES;
            
            NSImage *image = NSImageMake(@"icon_stop");
            image.template = YES;
            reloadButton.image = image;
        }
        reloadItem.label = [NSString stringWithFormat:@"%@ / %@", @(finishedCount), @(totalCount)];
        
    } else {
        if (self.isFetchingDetails) {
            // 退出 fetch 状态
            self.isFetchingDetails = NO;
            reloadItem.label = NSLocalizedString(@"Reload", nil);
            
            NSImage *image = NSImageMake(@"icon_reload");
            image.template = YES;
            reloadButton.image = image;
        } else {
            // 继续维持“非 fetch”状态
        }
    }
}

- (void)detailUpdateReceivedError:(NSError *)error {
    AlertError(error, self.window);
}

#pragma mark - Hierarchy Reload Helpers

- (void)_applyHierarchyInfo:(LookinHierarchyInfo *)info forApp:(LKInspectableApp *)app keepState:(BOOL)keepState {
    [self.viewController.progressView finishWithCompletion:nil];
    // Phase D: bind the app to this window's owned state. Same-window
    // reload paths (auto-connect, toolbar-same-app, SwiftUI mode toggle)
    // all flow through here, so this is the single point that owns
    // wiring `app` into the per-instance graph (`asyncUpdateManager` is
    // what dispatches RPCs).
    self.inspectableApp = app;
    self.asyncUpdateManager.inspectableApp = app;
    [self.hierarchyDataSource reloadWithHierarchyInfo:info keepState:keepState];
}

- (void)_handleSwiftUIModeDidChange:(NSNotification *)note {
    // Phase F: per-doc app is now the only source of truth.
    LKInspectableApp *app = self.inspectableApp;
    if (!app) {
        return;
    }

    // Capture pre-fetch selection so we can restore (or migrate) after reload.
    LookinDisplayItem *priorSelection = self.hierarchyDataSource.selectedItem;
    NSString *priorSwiftUIID = priorSelection.customInfo.swiftUIDisplayItemID;
    BOOL priorWasSwiftUI = [priorSwiftUIID hasPrefix:@"swiftui:"];

    [app cancelHierarchyDetailFetching];
    [self.viewController.progressView animateToProgress:InitialIndicatorProgressWhenFetchHierarchy];
    @weakify(self);
    [[app fetchHierarchyData] subscribeNext:^(LookinHierarchyInfo *info) {
        @strongify(self);
        // Mode toggle keeps the same target app, so keepState=YES preserves
        // expansion / scroll where possible. Selection migration handled below.
        [self _applyHierarchyInfo:info forApp:app keepState:YES];

        if (priorWasSwiftUI) {
            [self _restoreSwiftUISelectionWithPriorID:priorSwiftUIID];
        }
    } error:^(NSError *error) {
        @strongify(self);
        [self.viewController.progressView resetToZero];
        AlertError(error, self.window);
    }];
}

- (void)_restoreSwiftUISelectionWithPriorID:(NSString *)priorSelectionID {
    if (priorSelectionID.length == 0) {
        return;
    }

    NSArray<LookinDisplayItem *> *flatItems = self.hierarchyDataSource.displayingFlatItems;
    LookinDisplayItem *(^findByID)(NSString *) = ^LookinDisplayItem *(NSString *targetID) {
        for (LookinDisplayItem *item in flatItems) {
            if ([item.customInfo.swiftUIDisplayItemID isEqualToString:targetID]) {
                return item;
            }
        }
        return nil;
    };

    LookinDisplayItem *match = findByID(priorSelectionID);
    if (match) {
        // ID preserved in new tree — restore exactly.
        self.hierarchyDataSource.selectedItem = match;
        return;
    }

    // ID gone (compact elided it). Find smallest pre-order index N greater
    // than priorIndex that is present in the new tree.
    NSInteger priorIndex = [self _swiftUIPreOrderIndexFromID:priorSelectionID];
    if (priorIndex < 0) {
        return;
    }

    LookinDisplayItem *fallback = nil;
    NSInteger fallbackIndex = NSIntegerMax;
    for (LookinDisplayItem *item in flatItems) {
        NSString *itemID = item.customInfo.swiftUIDisplayItemID;
        if (![itemID hasPrefix:@"swiftui:"]) {
            continue;
        }
        NSInteger candidateIndex = [self _swiftUIPreOrderIndexFromID:itemID];
        if (candidateIndex > priorIndex && candidateIndex < fallbackIndex) {
            fallbackIndex = candidateIndex;
            fallback = item;
        }
    }
    if (fallback) {
        self.hierarchyDataSource.selectedItem = fallback;
        [self _showSelectionMigratedToastForItem:fallback];
    }
}

/// `swiftui:<hostHash>:<index>` 中末段索引;解析失败返回 -1。
- (NSInteger)_swiftUIPreOrderIndexFromID:(NSString *)displayItemID {
    NSRange lastColon = [displayItemID rangeOfString:@":" options:NSBackwardsSearch];
    if (lastColon.location == NSNotFound) {
        return -1;
    }
    NSString *tail = [displayItemID substringFromIndex:NSMaxRange(lastColon)];
    NSScanner *scanner = [NSScanner scannerWithString:tail];
    NSInteger value = -1;
    if (![scanner scanInteger:&value] || !scanner.atEnd) {
        return -1;
    }
    return value;
}

/// 临时浮层 toast — 非阻塞,2 秒后 fade out 并自动清理。
/// 不能用 NSAlert sheet,modal sheet 会在 dismiss 之前阻塞用户再次切 segmented control。
- (void)_showSelectionMigratedToastForItem:(LookinDisplayItem *)item {
    NSString *typeName = item.customInfo.title ?: @"SwiftUI item";
    NSString *message = [NSString stringWithFormat:
        NSLocalizedString(@"Selection moved to %@ (modifiers folded in compact mode).",
                          @"hierarchy.swiftui.selection.migrated.body"),
        typeName];

    NSView *host = self.viewController.view;
    NSTextField *toast = [NSTextField labelWithString:message];
    toast.font = [NSFont systemFontOfSize:12 weight:NSFontWeightMedium];
    toast.textColor = [NSColor whiteColor];
    toast.alignment = NSTextAlignmentCenter;
    toast.lineBreakMode = NSLineBreakByTruncatingTail;
    toast.wantsLayer = YES;
    toast.layer.backgroundColor = [[[NSColor blackColor] colorWithAlphaComponent:0.78] CGColor];
    toast.layer.cornerRadius = 6;
    toast.translatesAutoresizingMaskIntoConstraints = NO;
    [host addSubview:toast];
    [NSLayoutConstraint activateConstraints:@[
        [toast.centerXAnchor constraintEqualToAnchor:host.centerXAnchor],
        [toast.bottomAnchor constraintEqualToAnchor:host.bottomAnchor constant:-32],
        [toast.widthAnchor constraintLessThanOrEqualToAnchor:host.widthAnchor multiplier:0.7],
        [toast.heightAnchor constraintGreaterThanOrEqualToConstant:28],
    ]];
    // 2 秒后启动 0.3 秒 alpha → 0 动画,完成后 removeFromSuperview。
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *ctx) {
            ctx.duration = 0.3;
            toast.animator.alphaValue = 0;
        } completionHandler:^{
            [toast removeFromSuperview];
        }];
    });
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:LKSwiftUIHierarchyDisplayModeDidChangeNotification
                                                object:nil];
}

@end
