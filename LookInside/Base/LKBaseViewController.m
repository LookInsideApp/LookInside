//
//  LKBaseViewController.m
//  Lookin
//
//  Created by Li Kai on 2018/8/28.
//  https://lookin.work
//

#import "LKBaseViewController.h"
#import "LKWindowController.h"
#import "LKTipsView.h"
#import "LKInspectableApp.h"
#import "LKNavigationManager.h"
#import "LKStaticWindowController.h"
#import "LookinLiveDocument.h"

@interface LKBaseViewController ()

@end

@implementation LKBaseViewController

- (instancetype)initWithContainerView:(NSView *)view {
    if (self = [super initWithNibName:nil bundle:nil]) {
        if (!view) {
            view = [self makeContainerView];
        }
        self.view = view;
    }
    return self;
}

- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithContainerView:nil];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    return [self initWithContainerView:nil];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    _isViewAppeared = YES;
}

- (void)setView:(NSView *)view {
    [super setView:view];
    if (self.shouldShowConnectionTips) {
        _connectionTipsView = [LKRedTipsView new];
        self.connectionTipsView.hidden = YES;
        self.connectionTipsView.title = NSLocalizedString(@"Reconnecting…", nil);
        self.connectionTipsView.buttonText = NSLocalizedString(@"Change App", nil);
        self.connectionTipsView.target = self;
        self.connectionTipsView.clickAction = @selector(_handleClickReconnectTips);
    }
}

- (void)viewWillAppear {
    [super viewWillAppear];
    if (!self.shouldShowConnectionTips || self.connectionTipsView == nil) {
        return;
    }
    // Phase F: drive the per-window banner from the host Live Doc's
    // `connectionLossBannerMessage` (set when the channel dies, cleared
    // when Phase D auto-reconnect succeeds). The lookup happens once
    // here because the window↔doc binding is fixed for this controller's
    // lifetime once the doc has called `-makeWindowControllers`.
    LookinLiveDocument *doc = [LookinLiveDocument documentInWindow:self.view.window];
    if (!doc) {
        return;
    }
    LKInspectableApp *initialApp = doc.inspectableApp;
    if (initialApp) {
        [self.connectionTipsView setImageByAppInfo:initialApp.appInfo];
    }
    @weakify(self);
    [[RACObserve(doc, connectionLossBannerMessage) takeUntil:self.rac_willDeallocSignal]
        subscribeNext:^(NSString *message) {
        @strongify(self);
        NSView *containerView = self.view;
        if (message.length == 0) {
            [self.connectionTipsView endAnimation];
            self.connectionTipsView.hidden = YES;
        } else {
            if (!self.connectionTipsView.superview) {
                [containerView addSubview:self.connectionTipsView];
            }
            self.connectionTipsView.hidden = NO;
            [self.connectionTipsView startAnimation];
            [containerView setNeedsLayout:YES];
        }
    }];
    // Track inspectableApp swaps (Phase D auto-reconnect) so the banner
    // image stays in sync with the currently-bound app.
    [[RACObserve(doc, inspectableApp) takeUntil:self.rac_willDeallocSignal]
        subscribeNext:^(LKInspectableApp *app) {
        @strongify(self);
        if (app) {
            [self.connectionTipsView setImageByAppInfo:app.appInfo];
        }
    }];
}

- (void)viewDidLayout {
    [super viewDidLayout];
    if (self.connectionTipsView.isVisible) {
        CGFloat windowTitleHeight = [LKNavigationManager sharedInstance].windowTitleBarHeight;
        $(self.connectionTipsView).sizeToFit.horAlign.y(windowTitleHeight + 10);
    }
}

- (void)_handleClickReconnectTips {
    // Phase F: each Live Doc owns its own banner now, so clicking the
    // "Change App" pill on this window's banner pops up the picker on
    // *this* window (rather than routing through a global Static
    // workspace singleton).
    NSWindowController *wc = self.view.window.windowController;
    if ([wc isKindOfClass:[LKStaticWindowController class]]) {
        [(LKStaticWindowController *)wc popupAllInspectableAppsWithSource:MenuPopoverAppsListControllerEventSourceNoConnectionTips];
    }
}

- (void)dealloc {
    NSLog(@"%@ dealloc", self.class);
}

@end

@implementation LKBaseViewController (NSSubclassingHooks)

- (NSView *)makeContainerView {
    return [[LKBaseView alloc] init];
}

- (BOOL)shouldShowConnectionTips {
    return NO;
}

@end
