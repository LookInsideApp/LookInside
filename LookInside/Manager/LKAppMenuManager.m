//
//  LKAppMenuManager.m
//  Lookin
//
//  Created by Li Kai on 2019/3/20.
//  https://lookin.work
//

#import "LKAppMenuManager.h"
#import "LKNavigationManager.h"
#import "LKPreferenceManager.h"
#import "LKWindowController.h"

static NSUInteger const kTag_About = 11;
static NSUInteger const kTag_Preferences = 12;
static NSUInteger const kTag_CheckUpdates = 13;

static NSUInteger const kTag_Reload = 21;
static NSUInteger const kTag_Dimension = 22;
static NSUInteger const kTag_ZoomIn = 23;
static NSUInteger const kTag_ZoomOut = 24;
static NSUInteger const kTag_DecreaseInterspace = 25;
static NSUInteger const kTag_IncreaseInterspace = 26;
static NSUInteger const kTag_Expansion = 27;
static NSUInteger const kTag_Filter = 28;
static NSUInteger const kTag_OpenInNewWindow = 31;
static NSUInteger const kTag_Export = 32;

static NSUInteger const kTag_GitHub = 57;
static NSUInteger const kTag_Acknowledgements = 72;

static NSMenuItem *LKMenuItem(NSString *title, SEL action, NSString *keyEquivalent, NSEventModifierFlags modifiers, NSInteger tag) {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:keyEquivalent];
    item.keyEquivalentModifierMask = modifiers;
    item.tag = tag;
    return item;
}

static NSMenuItem *LKSubmenuItem(NSString *title, NSMenu *submenu, NSInteger tag) {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
    item.tag = tag;
    item.submenu = submenu;
    return item;
}

@interface LKAppMenuManager ()

@property(nonatomic, copy) NSDictionary<NSNumber *, NSString *> *delegatingTagToSelMap;
@property(nonatomic, strong) NSMenu *recentDocumentsMenu;

@end

@implementation LKAppMenuManager

- (void)_showDisabledExternalLinkAlert:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Link Disabled", nil);
    alert.informativeText = message;
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [alert runModal];
}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static LKAppMenuManager *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone{
    return [self sharedInstance];
}

- (NSString *)_applicationName {
    NSString *bundleDisplayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (bundleDisplayName.length > 0) {
        return bundleDisplayName;
    }
    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (bundleName.length > 0) {
        return bundleName;
    }
    return [NSProcessInfo processInfo].processName ?: @"LookInside";
}

- (NSMenu *)_buildApplicationMenu {
    NSString *appName = [self _applicationName];
    NSMenu *menu = [[NSMenu alloc] initWithTitle:appName];
    [menu addItem:LKMenuItem([NSString stringWithFormat:@"About %@", appName], nil, @"", 0, kTag_About)];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:LKMenuItem(@"Preferences…", nil, @",", NSEventModifierFlagCommand, kTag_Preferences)];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:LKMenuItem(@"Check for Updates…", nil, @"", 0, kTag_CheckUpdates)];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:LKMenuItem([NSString stringWithFormat:@"Hide %@", appName], @selector(hide:), @"h", NSEventModifierFlagCommand, 0)];
    [menu addItem:LKMenuItem(@"Hide Others", @selector(hideOtherApplications:), @"h", NSEventModifierFlagCommand | NSEventModifierFlagOption, 0)];
    [menu addItem:LKMenuItem(@"Show All", @selector(unhideAllApplications:), @"", 0, 0)];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:LKMenuItem([NSString stringWithFormat:@"Quit %@", appName], @selector(terminate:), @"q", NSEventModifierFlagCommand, 0)];
    return menu;
}

- (void)_reloadRecentDocumentsMenu {
    [self.recentDocumentsMenu removeAllItems];

    NSArray<NSURL *> *recentURLs = [NSDocumentController sharedDocumentController].recentDocumentURLs;
    if (recentURLs.count == 0) {
        NSMenuItem *emptyItem = LKMenuItem(@"No Recent Documents", nil, @"", 0, 0);
        emptyItem.enabled = NO;
        [self.recentDocumentsMenu addItem:emptyItem];
        return;
    }

    [recentURLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *title = url.lastPathComponent.length > 0 ? url.lastPathComponent : url.path;
        NSMenuItem *item = LKMenuItem(title, @selector(_handleOpenRecentDocument:), @"", 0, 0);
        item.target = self;
        item.representedObject = url;
        item.toolTip = url.path;
        [self.recentDocumentsMenu addItem:item];
    }];

    [self.recentDocumentsMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *clearItem = LKMenuItem(@"Clear Menu", @selector(clearRecentDocuments:), @"", 0, 0);
    clearItem.target = [NSDocumentController sharedDocumentController];
    [self.recentDocumentsMenu addItem:clearItem];
}

- (NSMenu *)_buildFileMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"File"];
    [menu addItem:LKMenuItem(@"Open…", @selector(openDocument:), @"o", NSEventModifierFlagCommand, 0)];

    self.recentDocumentsMenu = [[NSMenu alloc] initWithTitle:@"Open Recent"];
    self.recentDocumentsMenu.autoenablesItems = NO;
    self.recentDocumentsMenu.delegate = self;
    [self _reloadRecentDocumentsMenu];
    [menu addItem:LKSubmenuItem(@"Open Recent", self.recentDocumentsMenu, 0)];

    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:LKMenuItem(@"Copy to New Window…", nil, @"", 0, kTag_OpenInNewWindow)];
    [menu addItem:LKMenuItem(@"Export…", nil, @"", 0, kTag_Export)];
    return menu;
}

- (NSMenu *)_buildEditMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [menu addItem:LKMenuItem(@"Cut", @selector(cut:), @"x", NSEventModifierFlagCommand, 0)];
    [menu addItem:LKMenuItem(@"Copy", @selector(copy:), @"c", NSEventModifierFlagCommand, 0)];
    [menu addItem:LKMenuItem(@"Paste", @selector(paste:), @"v", NSEventModifierFlagCommand, 0)];
    [menu addItem:LKMenuItem(@"Select All", @selector(selectAll:), @"a", NSEventModifierFlagCommand, 0)];
    return menu;
}

- (NSMenu *)_buildViewMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"View"];
    [menu addItem:LKMenuItem(@"Reload", nil, @"r", NSEventModifierFlagCommand, kTag_Reload)];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:LKMenuItem(@"Filter", nil, @"f", NSEventModifierFlagCommand, kTag_Filter)];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:LKMenuItem(@"2D / 3D", nil, @"\\", NSEventModifierFlagCommand, kTag_Dimension)];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:LKMenuItem(@"Zoom In", nil, @"+", NSEventModifierFlagCommand, kTag_ZoomIn)];
    [menu addItem:LKMenuItem(@"Zoom Out", nil, @"-", NSEventModifierFlagCommand, kTag_ZoomOut)];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:LKMenuItem(@"Decrease Item Separation", nil, @"[", NSEventModifierFlagCommand, kTag_DecreaseInterspace)];
    [menu addItem:LKMenuItem(@"Increase Item Separation", nil, @"]", NSEventModifierFlagCommand, kTag_IncreaseInterspace)];
    [menu addItem:[NSMenuItem separatorItem]];

    NSMenu *expansionMenu = [[NSMenu alloc] initWithTitle:@"Hierarchy Depth"];
    [expansionMenu addItem:LKMenuItem(@"Level 1 (Collapse All)", nil, @"1", NSEventModifierFlagCommand, 271)];
    [expansionMenu addItem:LKMenuItem(@"Level 2", nil, @"2", NSEventModifierFlagCommand, 272)];
    [expansionMenu addItem:LKMenuItem(@"Level 3", nil, @"3", NSEventModifierFlagCommand, 273)];
    [expansionMenu addItem:LKMenuItem(@"Level 4", nil, @"4", NSEventModifierFlagCommand, 274)];
    [expansionMenu addItem:LKMenuItem(@"Level 5 (Expand All)", nil, @"5", NSEventModifierFlagCommand, 275)];
    [menu addItem:LKSubmenuItem(@"Hierarchy Depth", expansionMenu, kTag_Expansion)];

    return menu;
}

- (NSMenu *)_buildWindowMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Window"];
    [menu addItem:LKMenuItem(@"Close", @selector(performClose:), @"w", NSEventModifierFlagCommand, 0)];
    [menu addItem:LKMenuItem(@"Minimize", @selector(performMiniaturize:), @"m", NSEventModifierFlagCommand, 0)];
    [menu addItem:LKMenuItem(@"Zoom", @selector(performZoom:), @"", 0, 0)];
    return menu;
}

- (NSMenu *)_buildHelpMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Help"];
    [menu addItem:LKMenuItem(@"Source Code at GitHub", nil, @"", 0, kTag_GitHub)];
    [menu addItem:LKMenuItem(@"Acknowledgements", nil, @"", 0, kTag_Acknowledgements)];
    return menu;
}

- (void)_installMainMenu {
    NSString *appName = [self _applicationName];
    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"Main Menu"];
    NSMenu *windowMenu = [self _buildWindowMenu];
    NSMenu *helpMenu = [self _buildHelpMenu];

    [mainMenu addItem:LKSubmenuItem(appName, [self _buildApplicationMenu], 0)];
    [mainMenu addItem:LKSubmenuItem(@"File", [self _buildFileMenu], 0)];
    [mainMenu addItem:LKSubmenuItem(@"Edit", [self _buildEditMenu], 0)];
    [mainMenu addItem:LKSubmenuItem(@"View", [self _buildViewMenu], 0)];
    [mainMenu addItem:LKSubmenuItem(@"Window", windowMenu, 0)];
    [mainMenu addItem:LKSubmenuItem(@"Help", helpMenu, 0)];

    NSApp.mainMenu = mainMenu;
    NSApp.windowsMenu = windowMenu;
    if ([NSApp respondsToSelector:@selector(setHelpMenu:)]) {
        [NSApp setHelpMenu:helpMenu];
    }
}

- (void)setup {
    [self _installMainMenu];

    self.delegatingTagToSelMap = @{
                                   @(kTag_Reload):NSStringFromSelector(@selector(appMenuManagerDidSelectReload)),
                                   @(kTag_Dimension):NSStringFromSelector(@selector(appMenuManagerDidSelectDimension)),
                                   @(kTag_ZoomIn):NSStringFromSelector(@selector(appMenuManagerDidSelectZoomIn)),
                                   @(kTag_ZoomOut):NSStringFromSelector(@selector(appMenuManagerDidSelectZoomOut)),
                                   @(kTag_DecreaseInterspace):NSStringFromSelector(@selector(appMenuManagerDidSelectDecreaseInterspace)),
                                   @(kTag_IncreaseInterspace):NSStringFromSelector(@selector(appMenuManagerDidSelectIncreaseInterspace)),
                                   @(kTag_Expansion):NSStringFromSelector(@selector(appMenuManagerDidSelectExpansionIndex:)),
                                   @(kTag_Export):NSStringFromSelector(@selector(appMenuManagerDidSelectExport)),
                                   @(kTag_OpenInNewWindow):NSStringFromSelector(@selector(appMenuManagerDidSelectOpenInNewWindow)),
                                   @(kTag_Filter):NSStringFromSelector(@selector(appMenuManagerDidSelectFilter)),
    };

    NSMenu *menu = [NSApp mainMenu];

    NSMenu *menu_lookin = [menu itemAtIndex:0].submenu;
    menu_lookin.autoenablesItems = NO;
    menu_lookin.delegate = self;

    NSMenuItem *menuItem_about = [menu_lookin itemWithTag:kTag_About];
    menuItem_about.target = self;
    menuItem_about.action = @selector(_handleAbout);

    NSMenuItem *menuItem_preferences = [menu_lookin itemWithTag:kTag_Preferences];
    menuItem_preferences.target = self;
    menuItem_preferences.action = @selector(_handlePreferences);

    NSMenuItem *menuItem_checkUpdates = [menu_lookin itemWithTag:kTag_CheckUpdates];
    menuItem_checkUpdates.target = self;
    menuItem_checkUpdates.action = @selector(_handleCheckUpdates);

    NSMenu *menu_file = [menu itemAtIndex:1].submenu;
    menu_file.autoenablesItems = NO;
    menu_file.delegate = self;

    NSMenu *menu_view = [menu itemAtIndex:3].submenu;
    menu_view.autoenablesItems = NO;
    menu_view.delegate = self;

    NSMenu *menu_help = [menu itemAtIndex:5].submenu;
    menu_help.autoenablesItems = YES;
    menu_help.delegate = self;

    NSMenuItem *githubItem = [menu_help itemWithTag:kTag_GitHub];
    githubItem.target = self;
    githubItem.action = @selector(_handleShowGitHub);

    {
        NSMenuItem *item = [menu_help itemWithTag:kTag_Acknowledgements];
        item.target = self;
        item.action = @selector(_handleAcknowledgements);
    }

    NSArray *itemArray = [menu_file.itemArray arrayByAddingObjectsFromArray:menu_view.itemArray];
    [itemArray enumerateObjectsUsingBlock:^(NSMenuItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *selString = self.delegatingTagToSelMap[@(obj.tag)];
        if (selString) {
            if (obj.hasSubmenu) {
                if (obj.tag == kTag_Expansion) {
                    [obj.submenu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem * _Nonnull expansionSubItem, NSUInteger idx, BOOL * _Nonnull stop) {
                        expansionSubItem.target = self;
                        expansionSubItem.representedObject = @(idx);
                        expansionSubItem.action = @selector(_handleExpansion:);
                    }];
                }
            } else {
                obj.target = self;
                obj.action = @selector(_handleDelegateItem:);
            }
        }
    }];
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (menu == self.recentDocumentsMenu) {
        [self _reloadRecentDocumentsMenu];
        return;
    }

    LKWindowController *wc = [LKNavigationManager sharedInstance].currentKeyWindowController;

    [menu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *selString = self.delegatingTagToSelMap[@(obj.tag)];
        if (selString) {
            SEL delegateSel = NSSelectorFromString(selString);
            obj.enabled = [wc respondsToSelector:delegateSel];
        } else {
            obj.enabled = YES;
        }
    }];
}

- (void)_handlePreferences {
    [[LKNavigationManager sharedInstance] showPreference];
}

- (void)_handleOpenRecentDocument:(NSMenuItem *)item {
    NSURL *url = item.representedObject;
    if (url == nil) {
        return;
    }

    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
        if (error) {
            [NSApp presentError:error];
        }
    }];
}

- (void)_handleDelegateItem:(NSMenuItem *)item {
    NSString *selString = self.delegatingTagToSelMap[@(item.tag)];
    SEL sel = NSSelectorFromString(selString);
    if (!sel) {
        NSAssert(NO, @"");
        return;
    }
    LKWindowController *wc = [LKNavigationManager sharedInstance].currentKeyWindowController;
    if (![wc respondsToSelector:sel]) {
        NSAssert(NO, @"");
        return;
    }
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[wc methodSignatureForSelector:sel]];
    [invocation setTarget:wc];
    [invocation setSelector:sel];
    [invocation invoke];
}

- (void)_handleExpansion:(NSMenuItem *)item {
    NSNumber *idxNum = item.representedObject;
    if (idxNum == nil) {
        NSAssert(NO, @"");
        return;
    }
    NSUInteger index = idxNum.unsignedIntegerValue;

    LKWindowController *wc = [LKNavigationManager sharedInstance].currentKeyWindowController;
    if (![wc respondsToSelector:@selector(appMenuManagerDidSelectExpansionIndex:)]) {
        NSAssert(NO, @"");
        return;
    }
    [wc appMenuManagerDidSelectExpansionIndex:index];
}

- (void)_handleCheckUpdates {
    [self _showDisabledExternalLinkAlert:NSLocalizedString(@"Automatic update checks are disabled in this community build.", nil)];
}

- (void)_handleAbout {
    [[LKNavigationManager sharedInstance] showAbout];
}

- (void)_handleShowGitHub {
    [LKHelper openProjectGitHubRepository];
}

- (void)_handleAcknowledgements {
    [LKHelper openProjectREADME];
}

@end
