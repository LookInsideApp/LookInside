//
//  LKMeasureController.m
//  Lookin
//
//  Created by Li Kai on 2019/10/18.
//  https://lookin.work
//

#import "LKMeasureController.h"
#import "LKHierarchyDataSource.h"
#import "LKPreferenceManager.h"
#import "LookinDisplayItem.h"
#import "LKTextFieldView.h"
#import "LKMeasureResultView.h"
#import "LKNavigationManager.h"
#import "LKPreferenceSwitchView.h"

@interface LKMeasureController ()

@property(nonatomic, strong) LKBaseView *placeholderView;
@property(nonatomic, strong) NSImageView *placeholderImageView;
@property(nonatomic, strong) LKLabel *placeholderTitleLabel;
@property(nonatomic, strong) LKLabel *placeholderSubtitleLabel;
@property(nonatomic, strong) LKMeasureResultView *resultView;
@property(nonatomic, strong) LKHierarchyDataSource *dataSource;
@property(nonatomic, strong) LKLabel *shortcutLabel;
@property(nonatomic, strong) NSButton *lockSwitchButton;

@end

@implementation LKMeasureController

- (instancetype)initWithDataSource:(LKHierarchyDataSource *)dataSource {
    if (self = [self initWithContainerView:nil]) {
        self.dataSource = dataSource;
        
        self.placeholderView = [LKBaseView new];
        self.placeholderView.hasEffectedBackground = YES;
        self.placeholderView.layer.cornerRadius = DashboardCardCornerRadius;
        [self.view addSubview:self.placeholderView];
        
        self.placeholderImageView = [NSImageView new];
        [self.placeholderView addSubview:self.placeholderImageView];
        
        self.placeholderTitleLabel = [LKLabel new];
        self.placeholderTitleLabel.font = [NSFont boldSystemFontOfSize:14];
        self.placeholderTitleLabel.alignment = NSTextAlignmentCenter;
        [self.placeholderView addSubview:self.placeholderTitleLabel];
        
        self.placeholderSubtitleLabel = [LKLabel new];
        self.placeholderSubtitleLabel.font = NSFontMake(12);
        self.placeholderSubtitleLabel.alignment = NSTextAlignmentCenter;
        [self.placeholderView addSubview:self.placeholderSubtitleLabel];
        
        self.resultView = [LKMeasureResultView new];
        [self.view addSubview:self.resultView];
        
        [dataSource.preferenceManager.measureState subscribe:self action:@selector(_measureStatePropertyDidChange:) relatedObject:nil];
        
        @weakify(self);
        [[RACObserve(dataSource, selectedItem) combineLatestWith:RACObserve(dataSource, hoveredItem)] subscribeNext:^(id  _Nullable x) {
            @strongify(self);
            [self _reRender];
        }];
    }
    return self;
}

- (void)viewDidLayout {
    [super viewDidLayout];
    
    CGFloat titleHeight = [LKNavigationManager sharedInstance].windowTitleBarHeight;
    
    NSView *contentView = nil;
    if (self.placeholderView.isVisible) {
        $(self.placeholderView).fullWidth.height([self _placeholderHeightForWidth:self.view.bounds.size.width]).verAlign.offsetY(titleHeight / 2.0);
        [self _layoutPlaceholderView];
        contentView = self.placeholderView;
    }
    if (self.resultView.isVisible) {
        $(self.resultView).fullWidth.heightToFit.verAlign.offsetY(titleHeight / 2.0);
        contentView = self.resultView;
    }
    if (self.shortcutLabel) {
        $(self.shortcutLabel).sizeToFit.horAlign.y(contentView.$maxY + 5);
    }
    if (self.lockSwitchButton) {
        $(self.lockSwitchButton).sizeToFit.horAlign.y(contentView.$maxY + 5);
    }
}

- (void)_measureStatePropertyDidChange:(LookinMsgActionParams *)params {
    self.shortcutLabel.hidden = YES;
    
    LookinMeasureState state = params.integerValue;
    switch (state) {
        case LookinMeasureState_no:
            self.lockSwitchButton.hidden = YES;
            self.lockSwitchButton.state = NSControlStateValueOff;
            break;
            
        case LookinMeasureState_unlocked:
            // 由快捷键触发
            if (!self.lockSwitchButton) {
                self.lockSwitchButton = [NSButton new];
                [self.lockSwitchButton setButtonType:NSButtonTypeSwitch];
                self.lockSwitchButton.font = NSFontMake(15);
                self.lockSwitchButton.title = NSLocalizedString(@"Cancel measure after key up.", nil);
                self.lockSwitchButton.target = self;
                self.lockSwitchButton.action = @selector(handleLockSwitchButton);
                [self.view addSubview:self.lockSwitchButton];
            }
            self.lockSwitchButton.state = NSControlStateValueOn;
            self.lockSwitchButton.hidden = NO;
            break;
            
        case LookinMeasureState_locked: {
            if (!self.shortcutLabel) {
                self.shortcutLabel = [LKLabel new];
                self.shortcutLabel.stringValue = NSLocalizedString(@"shortcut: holding \"option\" key", nil);
                self.shortcutLabel.textColor = [NSColor secondaryLabelColor];
                [self.view addSubview:self.shortcutLabel];
            }
            self.shortcutLabel.hidden = NO;
            break;
        }
    }
    [self _reRender];
}

- (void)_reRender {
    if (self.dataSource.preferenceManager.measureState.currentIntegerValue == LookinMeasureState_no) {
        return;
    }
    if (!self.dataSource.selectedItem) {
        return;
    }
    if (!self.dataSource.hoveredItem || (self.dataSource.selectedItem == self.dataSource.hoveredItem)) {
        NSString *format = NSLocalizedString(@"to measure between it and selected %@.", nil);
        NSString *subtitle = [NSString stringWithFormat:format, self.dataSource.selectedItem.title];
        
        self.resultView.hidden = YES;
        [self _renderPlaceholderWithImage:NSImageMake(@"measure_hover") title:NSLocalizedString(@"Hover on a layer", nil) subtitle:subtitle];
        [self.view setNeedsLayout:YES];
        return;
    }
    
    NSString *sizeInvalidClass = nil;
    NSString *sizeInvalidProperty = nil;
    CGRect selectedItemFrame = [self.dataSource.selectedItem calculateFrameToRoot];
    CGRect hoveredItemFrame = [self.dataSource.hoveredItem calculateFrameToRoot];
    
    if (selectedItemFrame.size.width <= 0) {
        sizeInvalidClass = self.dataSource.selectedItem.title;
        sizeInvalidProperty = @"width";
    } else if (selectedItemFrame.size.height <= 0) {
        sizeInvalidClass = self.dataSource.selectedItem.title;
        sizeInvalidProperty = @"height";
    } else if (hoveredItemFrame.size.width <= 0) {
        sizeInvalidClass = self.dataSource.hoveredItem.title;
        sizeInvalidProperty = @"width";
    } else if (hoveredItemFrame.size.height <= 0) {
        sizeInvalidClass = self.dataSource.hoveredItem.title;
        sizeInvalidProperty = @"height";
    }
    if (sizeInvalidClass || sizeInvalidProperty) {
        NSString *subtitleFormat = NSLocalizedString(@"Selected %@'s %@ is less than or equal to 0.", nil);
        NSString *subtitle = [NSString stringWithFormat:subtitleFormat, sizeInvalidClass, sizeInvalidProperty];
        
        self.resultView.hidden = YES;
        [self _renderPlaceholderWithImage:NSImageMake(@"measure_info") title:NSLocalizedString(@"Invalid Size", nil) subtitle:subtitle];
        [self.view setNeedsLayout:YES];
        return;
    }
    
    self.placeholderView.hidden = YES;
    self.resultView.hidden = NO;
    [self.resultView renderWithMainRect:selectedItemFrame mainImage:self.dataSource.selectedItem.groupScreenshot referRect:hoveredItemFrame referImage:self.dataSource.hoveredItem.groupScreenshot];
    [self.view setNeedsLayout:YES];
}

- (void)_renderPlaceholderWithImage:(NSImage *)image title:(NSString *)title subtitle:(NSString *)subtitle {
    self.placeholderImageView.image = image;
    self.placeholderTitleLabel.stringValue = title;
    self.placeholderSubtitleLabel.stringValue = subtitle;
    self.placeholderView.hidden = NO;
}

- (CGFloat)_placeholderHeightForWidth:(CGFloat)width {
    NSEdgeInsets insets = NSEdgeInsetsMake(15, 5, 12, 5);
    CGFloat contentWidth = width - insets.left - insets.right;
    CGFloat resultHeight = insets.top + insets.bottom;
    resultHeight += self.placeholderImageView.image.size.height;
    resultHeight += 11;
    resultHeight += [self.placeholderTitleLabel heightForWidth:contentWidth];
    resultHeight += 6;
    resultHeight += [self.placeholderSubtitleLabel heightForWidth:contentWidth];
    return resultHeight;
}

- (void)_layoutPlaceholderView {
    NSEdgeInsets insets = NSEdgeInsetsMake(15, 5, 12, 5);
    $(self.placeholderImageView).sizeToFit.horAlign.y(insets.top);
    $(self.placeholderTitleLabel).sizeToFit.horAlign.y(self.placeholderImageView.$maxY + 11);
    $(self.placeholderSubtitleLabel).x(insets.left).toRight(insets.right).heightToFit.y(self.placeholderTitleLabel.$maxY + 6);
}

- (void)handleLockSwitchButton {
    if (!self.lockSwitchButton) {
        return;
    }
    if (self.lockSwitchButton.state == NSControlStateValueOn) {
        [self.dataSource.preferenceManager.measureState setIntegerValue:LookinMeasureState_unlocked ignoreSubscriber:self];
    } else {
        [self.dataSource.preferenceManager.measureState setIntegerValue:LookinMeasureState_locked ignoreSubscriber:self];
    }
}

@end
