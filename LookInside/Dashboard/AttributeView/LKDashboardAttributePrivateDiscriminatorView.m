//
//  LKDashboardAttributePrivateDiscriminatorView.m
//  LookInside
//

#import "LKDashboardAttributePrivateDiscriminatorView.h"
#import "LKDashboardViewController.h"
#import "LookinAttribute.h"
#import "LookinDisplayItem.h"
#import "LookInside-Swift.h"
#import "NSButton+LookinClient.h"

static NSString *const LKPrivateDiscriminatorDashboardStateDidChangeNotification = @"LKPrivateDiscriminatorDashboardStateDidChange";

static const CGFloat kPDRowTitleWidth = 64;
static const CGFloat kPDCardPaddingLeft = 8;
static const CGFloat kPDCardPaddingRight = 4;
static const CGFloat kPDCardInnerSpacing = 6;
static const CGFloat kPDCardVerticalPadding = 4;
static const CGFloat kPDCopySize = 20;
static const CGFloat kPDRowMinHeight = 24;
static const CGFloat kPDButtonHeight = 24;

@interface LKPrivateDiscriminatorCopyLabel : LKLabel

@property(nonatomic, copy) NSString *fieldName;

@end

@implementation LKPrivateDiscriminatorCopyLabel

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.font = NSFontMake(12);
        self.textColor = [NSColor colorNamed:@"DashboardCardValueColor"];
        self.lineBreakMode = NSLineBreakByCharWrapping;
        self.maximumNumberOfLines = 0;
        self.toolTip = NSLocalizedString(@"Click to copy", nil);
    }
    return self;
}

- (void)mouseDown:(NSEvent *)event {
    NSString *value = self.stringValue;
    if (value.length == 0) {
        [super mouseDown:event];
        return;
    }

    [NSApp sendAction:self.action to:self.target from:self];
}

- (void)resetCursorRects {
    [super resetCursorRects];
    [self addCursorRect:self.bounds cursor:NSCursor.pointingHandCursor];
}

@end

@interface LKDashboardAttributePrivateDiscriminatorView ()

@property(nonatomic, strong) LKBaseView *idCard;
@property(nonatomic, strong) LKLabel *idTitleLabel;
@property(nonatomic, strong) LKPrivateDiscriminatorCopyLabel *idValueLabel;
@property(nonatomic, strong) NSButton *idCopyButton;

@property(nonatomic, strong) LKBaseView *moduleCard;
@property(nonatomic, strong) LKLabel *moduleTitleLabel;
@property(nonatomic, strong) NSTextField *moduleField;
@property(nonatomic, strong) LKPrivateDiscriminatorCopyLabel *moduleValueLabel;
@property(nonatomic, strong) NSButton *moduleCopyButton;

@property(nonatomic, strong) LKBaseView *filenameCard;
@property(nonatomic, strong) LKLabel *filenameTitleLabel;
@property(nonatomic, strong) NSTextField *filenameField;
@property(nonatomic, strong) LKPrivateDiscriminatorCopyLabel *filenameValueLabel;
@property(nonatomic, strong) NSButton *filenameCopyButton;

@property(nonatomic, strong) LKLabel *sourceLabel;
@property(nonatomic, strong) LKLabel *messageLabel;

@property(nonatomic, strong) NSButton *importButton;
@property(nonatomic, strong) NSButton *guessButton;
@property(nonatomic, strong) NSButton *cancelButton;

@property(nonatomic, strong) LKBaseView *toastView;
@property(nonatomic, strong) LKLabel *toastLabel;

@property(nonatomic, strong) LKPrivateDiscriminatorDashboardPayload *payload;
@property(nonatomic, copy) NSString *localMessage;
@property(nonatomic, assign) BOOL localMessageIsError;

@end

@implementation LKDashboardAttributePrivateDiscriminatorView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.idCard = [self _makeCard];
        self.idTitleLabel = [self _makeTitleLabel:NSLocalizedString(@"ID", nil)];
        self.idValueLabel = [self _makeCopyLabelNamed:NSLocalizedString(@"ID", nil)];
        self.idValueLabel.font = [NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular];
        self.idCopyButton = [self _makeCopyButton];
        [self.idCard addSubview:self.idTitleLabel];
        [self.idCard addSubview:self.idValueLabel];
        [self.idCard addSubview:self.idCopyButton];

        self.moduleCard = [self _makeCard];
        self.moduleTitleLabel = [self _makeTitleLabel:NSLocalizedString(@"Module", nil)];
        self.moduleField = [self _makeTextFieldWithPlaceholder:NSLocalizedString(@"ModuleName", nil)];
        self.moduleValueLabel = [self _makeCopyLabelNamed:NSLocalizedString(@"Module", nil)];
        self.moduleCopyButton = [self _makeCopyButton];
        [self.moduleCard addSubview:self.moduleTitleLabel];
        [self.moduleCard addSubview:self.moduleField];
        [self.moduleCard addSubview:self.moduleValueLabel];
        [self.moduleCard addSubview:self.moduleCopyButton];

        self.filenameCard = [self _makeCard];
        self.filenameTitleLabel = [self _makeTitleLabel:NSLocalizedString(@"Filename", nil)];
        self.filenameField = [self _makeTextFieldWithPlaceholder:NSLocalizedString(@"File.swift", nil)];
        self.filenameValueLabel = [self _makeCopyLabelNamed:NSLocalizedString(@"Filename", nil)];
        self.filenameCopyButton = [self _makeCopyButton];
        [self.filenameCard addSubview:self.filenameTitleLabel];
        [self.filenameCard addSubview:self.filenameField];
        [self.filenameCard addSubview:self.filenameValueLabel];
        [self.filenameCard addSubview:self.filenameCopyButton];

        self.sourceLabel = [LKLabel new];
        self.sourceLabel.font = NSFontMake(11);
        self.sourceLabel.textColor = [NSColor colorNamed:@"DashboardInputAccessoryColor"];
        self.sourceLabel.maximumNumberOfLines = 0;
        self.sourceLabel.lineBreakMode = NSLineBreakByWordWrapping;

        self.messageLabel = [LKLabel new];
        self.messageLabel.font = NSFontMake(11);
        self.messageLabel.maximumNumberOfLines = 0;
        self.messageLabel.lineBreakMode = NSLineBreakByWordWrapping;

        self.importButton = [NSButton lk_normalButtonWithTitle:NSLocalizedString(@"Import from your codebase", nil) target:self action:@selector(_handleImportButton:)];
        self.importButton.font = NSFontMake(12);

        self.guessButton = [NSButton lk_normalButtonWithTitle:NSLocalizedString(@"Guess by swift-pd-guess", nil) target:self action:@selector(_handleGuessButton:)];
        self.guessButton.font = NSFontMake(12);

        self.cancelButton = [NSButton lk_normalButtonWithTitle:NSLocalizedString(@"Cancel", nil) target:self action:@selector(_handleCancelButton:)];
        self.cancelButton.font = NSFontMake(12);

        self.toastView = [LKBaseView new];
        self.toastView.layer.cornerRadius = DashboardCardControlCornerRadius;
        self.toastView.hidden = YES;
        self.toastView.alphaValue = 0;

        self.toastLabel = [LKLabel new];
        self.toastLabel.stringValue = NSLocalizedString(@"Copied", nil);
        self.toastLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold];
        self.toastLabel.textColor = NSColor.whiteColor;
        self.toastLabel.alignment = NSTextAlignmentCenter;
        [self.toastView addSubview:self.toastLabel];

        NSArray<NSView *> *subviews = @[
            self.idCard,
            self.moduleCard,
            self.filenameCard,
            self.sourceLabel,
            self.messageLabel,
            self.importButton,
            self.guessButton,
            self.cancelButton,
            self.toastView,
        ];
        [subviews enumerateObjectsUsingBlock:^(NSView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
            [self addSubview:view];
        }];

        [self updateColors];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_handleDashboardStateDidChange:)
                                                     name:LKPrivateDiscriminatorDashboardStateDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)renderWithAttribute {
    [super renderWithAttribute];

    self.payload = [self.attribute.value isKindOfClass:LKPrivateDiscriminatorDashboardPayload.class]
        ? self.attribute.value
        : nil;

    self.idValueLabel.stringValue = self.payload.discriminatorID ?: @"";
    self.moduleField.stringValue = self.payload.module ?: @"";
    self.filenameField.stringValue = self.payload.filename ?: @"";
    self.moduleValueLabel.stringValue = self.payload.module ?: @"";
    self.filenameValueLabel.stringValue = self.payload.filename ?: @"";

    BOOL canEdit = self.payload && !self.payload.isMatched && !self.payload.isGuessRunning;
    self.moduleField.editable = canEdit;
    self.filenameField.editable = canEdit;
    self.moduleField.enabled = canEdit;
    self.filenameField.enabled = canEdit;
    self.moduleField.hidden = !canEdit;
    self.filenameField.hidden = !canEdit;
    self.moduleValueLabel.hidden = canEdit;
    self.filenameValueLabel.hidden = canEdit;
    self.idCopyButton.hidden = (self.idValueLabel.stringValue.length == 0);
    self.moduleCopyButton.hidden = canEdit || self.moduleValueLabel.stringValue.length == 0;
    self.filenameCopyButton.hidden = canEdit || self.filenameValueLabel.stringValue.length == 0;

    self.importButton.hidden = self.payload.isMatched || self.payload.isGuessRunning;
    self.guessButton.hidden = self.payload.isMatched || self.payload.isGuessRunning;
    self.cancelButton.hidden = !self.payload.isGuessRunning;

    if (self.payload.isMatched) {
        NSString *source = self.payload.source.length ? self.payload.source : @"matched";
        self.sourceLabel.stringValue = self.payload.isVerified
            ? [NSString stringWithFormat:NSLocalizedString(@"Verified from %@.", nil), source]
            : [NSString stringWithFormat:NSLocalizedString(@"Matched from %@.", nil), source];
        self.sourceLabel.hidden = NO;
    } else {
        self.sourceLabel.stringValue = @"";
        self.sourceLabel.hidden = YES;
    }

    [self _renderMessage];
    [self setNeedsLayout:YES];
}

#pragma mark - Layout

- (CGFloat)_valueWidthForCardWidth:(CGFloat)cardWidth copyHidden:(BOOL)copyHidden {
    CGFloat width = cardWidth - kPDCardPaddingLeft - kPDRowTitleWidth - kPDCardInnerSpacing;
    if (copyHidden) {
        width -= kPDCardPaddingLeft;
    } else {
        width -= kPDCopySize + kPDCardInnerSpacing + kPDCardPaddingRight;
    }
    return MAX(width, 1);
}

- (CGFloat)_cardHeightForLabel:(LKPrivateDiscriminatorCopyLabel *)label
                     cardWidth:(CGFloat)cardWidth
                    copyHidden:(BOOL)copyHidden {
    CGFloat valueWidth = [self _valueWidthForCardWidth:cardWidth copyHidden:copyHidden];
    CGFloat valueHeight = MAX(18, [label sizeThatFits:NSMakeSize(valueWidth, CGFLOAT_MAX)].height);
    return MAX(valueHeight + kPDCardVerticalPadding * 2, kPDRowMinHeight);
}

- (CGFloat)_moduleCardHeightForCardWidth:(CGFloat)cardWidth {
    if (self.moduleField.hidden) {
        return [self _cardHeightForLabel:self.moduleValueLabel cardWidth:cardWidth copyHidden:self.moduleCopyButton.hidden];
    }
    return kPDRowMinHeight;
}

- (CGFloat)_filenameCardHeightForCardWidth:(CGFloat)cardWidth {
    if (self.filenameField.hidden) {
        return [self _cardHeightForLabel:self.filenameValueLabel cardWidth:cardWidth copyHidden:self.filenameCopyButton.hidden];
    }
    return kPDRowMinHeight;
}

- (void)layout {
    [super layout];

    CGFloat width = MAX(self.$width, 1);
    CGFloat verSpacing = DashboardAttrItemVerInterspace;

    CGFloat y = 0;

    CGFloat idHeight = [self _cardHeightForLabel:self.idValueLabel cardWidth:width copyHidden:self.idCopyButton.hidden];
    $(self.idCard).x(0).y(y).width(width).height(idHeight);
    [self _layoutCard:self.idCard
           titleLabel:self.idTitleLabel
                field:nil
           valueLabel:self.idValueLabel
           copyButton:self.idCopyButton];
    y += idHeight + verSpacing;

    CGFloat moduleHeight = [self _moduleCardHeightForCardWidth:width];
    $(self.moduleCard).x(0).y(y).width(width).height(moduleHeight);
    [self _layoutCard:self.moduleCard
           titleLabel:self.moduleTitleLabel
                field:self.moduleField
           valueLabel:self.moduleValueLabel
           copyButton:self.moduleCopyButton];
    y += moduleHeight + verSpacing;

    CGFloat filenameHeight = [self _filenameCardHeightForCardWidth:width];
    $(self.filenameCard).x(0).y(y).width(width).height(filenameHeight);
    [self _layoutCard:self.filenameCard
           titleLabel:self.filenameTitleLabel
                field:self.filenameField
           valueLabel:self.filenameValueLabel
           copyButton:self.filenameCopyButton];
    y += filenameHeight + verSpacing;

    if (!self.sourceLabel.hidden) {
        $(self.sourceLabel).x(kPDCardPaddingLeft).y(y).width(MAX(width - kPDCardPaddingLeft * 2, 1)).heightToFit;
        y = self.sourceLabel.$maxY + verSpacing;
    }

    if (!self.messageLabel.hidden) {
        $(self.messageLabel).x(kPDCardPaddingLeft).y(y).width(MAX(width - kPDCardPaddingLeft * 2, 1)).heightToFit;
        y = self.messageLabel.$maxY + verSpacing;
    }

    if (!self.importButton.hidden) {
        $(self.importButton).x(0).y(y).width(width).height(kPDButtonHeight);
        y = self.importButton.$maxY + 6;
    }

    if (!self.guessButton.hidden) {
        $(self.guessButton).x(0).y(y).width(width).height(kPDButtonHeight);
        y = self.guessButton.$maxY + 2;
    }

    if (!self.cancelButton.hidden) {
        $(self.cancelButton).x(0).y(y).width(86).height(kPDButtonHeight);
    }

    if (!self.toastView.hidden) {
        $(self.toastLabel).x(8).toRight(8).heightToFit.verAlign;
    }
}

- (void)_layoutCard:(LKBaseView *)card
         titleLabel:(LKLabel *)titleLabel
              field:(NSTextField *)field
         valueLabel:(LKPrivateDiscriminatorCopyLabel *)valueLabel
         copyButton:(NSButton *)copyButton {
    CGFloat cardWidth = card.$width;
    CGFloat cardHeight = card.$height;
    BOOL fieldVisible = field && !field.hidden;
    BOOL copyVisible = copyButton && !copyButton.hidden;

    CGFloat titleHeight = MAX(14, [titleLabel sizeThatFits:NSMakeSize(kPDRowTitleWidth, CGFLOAT_MAX)].height);
    $(titleLabel).x(kPDCardPaddingLeft).y(MAX(0, (cardHeight - titleHeight) / 2.0)).width(kPDRowTitleWidth).height(titleHeight);

    CGFloat contentX = kPDCardPaddingLeft + kPDRowTitleWidth + kPDCardInnerSpacing;
    CGFloat contentRightX = copyVisible ? cardWidth - kPDCardPaddingRight - kPDCopySize - kPDCardInnerSpacing : cardWidth - kPDCardPaddingLeft;
    CGFloat contentWidth = MAX(contentRightX - contentX, 1);

    if (fieldVisible) {
        valueLabel.hidden = YES;
        CGFloat fieldHeight = MAX(18, [field intrinsicContentSize].height);
        $(field).x(contentX - 3).y(MAX(0, (cardHeight - fieldHeight) / 2.0)).width(contentWidth + 6).height(fieldHeight);
    } else if (field) {
        // 即便 fieldVisible 是 NO 也保持 hidden 状态由 renderWithAttribute 控制
    }

    if (!fieldVisible) {
        CGFloat valueHeight = MAX(18, [valueLabel sizeThatFits:NSMakeSize(contentWidth, CGFLOAT_MAX)].height);
        $(valueLabel).x(contentX).y(MAX(0, (cardHeight - valueHeight) / 2.0)).width(contentWidth).height(valueHeight);
    }

    if (copyVisible) {
        CGFloat copyY = MAX(0, (cardHeight - kPDCopySize) / 2.0);
        $(copyButton).x(cardWidth - kPDCardPaddingRight - kPDCopySize).y(copyY).width(kPDCopySize).height(kPDCopySize);
    }
}

- (NSSize)sizeThatFits:(NSSize)limitedSize {
    CGFloat width = MAX(limitedSize.width, 1);
    CGFloat verSpacing = DashboardAttrItemVerInterspace;

    CGFloat height = 0;
    height += [self _cardHeightForLabel:self.idValueLabel cardWidth:width copyHidden:self.idCopyButton.hidden];
    height += verSpacing;
    height += [self _moduleCardHeightForCardWidth:width];
    height += verSpacing;
    height += [self _filenameCardHeightForCardWidth:width];

    CGFloat sideTextWidth = MAX(width - kPDCardPaddingLeft * 2, 1);

    if (!self.sourceLabel.hidden) {
        height += verSpacing;
        height += [self.sourceLabel sizeThatFits:NSMakeSize(sideTextWidth, CGFLOAT_MAX)].height;
    }
    if (!self.messageLabel.hidden) {
        height += verSpacing;
        height += [self.messageLabel sizeThatFits:NSMakeSize(sideTextWidth, CGFLOAT_MAX)].height;
    }

    if (!self.importButton.hidden) {
        height += verSpacing;
        height += kPDButtonHeight;
    }
    if (!self.guessButton.hidden) {
        height += self.importButton.hidden ? verSpacing : 6;
        height += kPDButtonHeight;
    }
    if (!self.cancelButton.hidden) {
        if (self.importButton.hidden && self.guessButton.hidden) {
            height += verSpacing;
        } else {
            height += 2;
        }
        height += kPDButtonHeight;
    }

    limitedSize.height = height;
    return limitedSize;
}

- (NSUInteger)numberOfColumnsOccupied {
    return 1;
}

#pragma mark - Actions

- (void)_submitManualValue:(id)sender {
    if (!self.payload || self.payload.isMatched) {
        return;
    }

    NSError *error = nil;
    BOOL saved = [[LKPrivateDiscriminatorStore shared] submitPrivateDiscriminatorForDisplayItem:self.attribute.targetDisplayItem
                                                                                        module:self.moduleField.stringValue
                                                                                      filename:self.filenameField.stringValue
                                                                                         error:&error];
    if (saved) {
        self.localMessage = NSLocalizedString(@"Saved.", nil);
        self.localMessageIsError = NO;
        [self.dashboardViewController reloadCurrentDisplayItem];
    } else {
        self.localMessage = error.localizedDescription ?: NSLocalizedString(@"Verification failed.", nil);
        self.localMessageIsError = YES;
        [self _renderMessage];
        [self.window makeFirstResponder:nil];
        [self setNeedsLayout:YES];
    }
}

- (void)_handleImportButton:(NSButton *)button {
    NSError *error = nil;
    BOOL imported = [[LKPrivateDiscriminatorStore shared] importPrivateDiscriminatorFromCodebaseForDisplayItem:self.attribute.targetDisplayItem
                                                                                                        window:self.window
                                                                                                         error:&error];
    if (imported) {
        self.localMessage = nil;
        [self.dashboardViewController reloadCurrentDisplayItem];
    } else if (error) {
        self.localMessage = error.localizedDescription;
        self.localMessageIsError = YES;
        [self _renderMessage];
        [self setNeedsLayout:YES];
    }
}

- (void)_handleGuessButton:(NSButton *)button {
    [[LKPrivateDiscriminatorStore shared] beginSwiftPDGuessForDisplayItem:self.attribute.targetDisplayItem window:self.window];
    [self.dashboardViewController reloadCurrentDisplayItem];
}

- (void)_handleCancelButton:(NSButton *)button {
    [[LKPrivateDiscriminatorStore shared] cancelSwiftPDGuessForDisplayItem:self.attribute.targetDisplayItem];
}

- (void)_handleCopyLabel:(LKPrivateDiscriminatorCopyLabel *)label {
    [self _copyString:label.stringValue sourceView:label];
}

- (void)_handleCopyButton:(NSButton *)button {
    if (button == self.idCopyButton) {
        [self _copyString:self.idValueLabel.stringValue sourceView:button];
    } else if (button == self.moduleCopyButton) {
        [self _copyString:self.moduleValueLabel.stringValue sourceView:button];
    } else if (button == self.filenameCopyButton) {
        [self _copyString:self.filenameValueLabel.stringValue sourceView:button];
    }
}

- (void)_handleDashboardStateDidChange:(NSNotification *)notification {
    [self.dashboardViewController reloadCurrentDisplayItem];
}

- (void)_hideCopyToast {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        context.duration = 0.12;
        self.toastView.animator.alphaValue = 0;
    } completionHandler:^{
        self.toastView.hidden = YES;
    }];
}

#pragma mark - Views

- (LKBaseView *)_makeCard {
    LKBaseView *card = [LKBaseView new];
    card.layer.cornerRadius = DashboardCardControlCornerRadius;
    card.backgroundColorName = @"DashboardCardValueBGColor";
    return card;
}

- (LKLabel *)_makeTitleLabel:(NSString *)title {
    LKLabel *label = [LKLabel new];
    label.stringValue = title;
    label.font = NSFontMake(11);
    label.textColor = [NSColor colorNamed:@"DashboardInputAccessoryColor"];
    return label;
}

- (LKPrivateDiscriminatorCopyLabel *)_makeCopyLabelNamed:(NSString *)name {
    LKPrivateDiscriminatorCopyLabel *label = [LKPrivateDiscriminatorCopyLabel new];
    label.fieldName = name;
    label.target = self;
    label.action = @selector(_handleCopyLabel:);
    return label;
}

- (NSButton *)_makeCopyButton {
    NSImage *image = [NSImage imageWithSystemSymbolName:@"doc.on.doc" accessibilityDescription:NSLocalizedString(@"Copy", nil)];
    NSButton *button = [NSButton lk_buttonWithImage:image ?: NSImage.new target:self action:@selector(_handleCopyButton:)];
    button.imagePosition = NSImageOnly;
    button.toolTip = NSLocalizedString(@"Copy", nil);
    if (image) {
        image.template = YES;
    }
    return button;
}

- (NSTextField *)_makeTextFieldWithPlaceholder:(NSString *)placeholder {
    NSTextField *field = [NSTextField new];
    field.placeholderString = placeholder;
    field.font = NSFontMake(12);
    field.bezeled = NO;
    field.drawsBackground = NO;
    field.textColor = [NSColor colorNamed:@"DashboardCardValueColor"];
    field.focusRingType = NSFocusRingTypeNone;
    field.target = self;
    field.action = @selector(_submitManualValue:);
    return field;
}

- (void)_copyString:(NSString *)value sourceView:(NSView *)sourceView {
    if (value.length == 0) {
        return;
    }
    NSPasteboard *pasteboard = NSPasteboard.generalPasteboard;
    [pasteboard clearContents];
    [pasteboard setString:value forType:NSPasteboardTypeString];
    [self _showCopyToastNearView:sourceView];
}

- (void)_showCopyToastNearView:(NSView *)sourceView {
    self.toastLabel.stringValue = NSLocalizedString(@"Copied", nil);
    [self.toastLabel sizeToFit];

    CGFloat toastWidth = ceil(self.toastLabel.$width) + 18;
    CGFloat toastHeight = 22;
    NSRect sourceFrame = [sourceView convertRect:sourceView.bounds toView:self];
    CGFloat toastX = NSMidX(sourceFrame) - toastWidth / 2.0;
    toastX = MIN(MAX(toastX, 6), MAX(self.$width - toastWidth - 6, 6));
    CGFloat toastY = NSMinY(sourceFrame) - toastHeight - 4;
    if (toastY < 4) {
        toastY = NSMaxY(sourceFrame) + 4;
    }

    $(self.toastView).x(toastX).y(toastY).width(toastWidth).height(toastHeight);
    $(self.toastLabel).x(8).toRight(8).heightToFit.verAlign;
    self.toastView.hidden = NO;
    self.toastView.alphaValue = 1;

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_hideCopyToast) object:nil];
    [self performSelector:@selector(_hideCopyToast) withObject:nil afterDelay:1.0];
}

- (void)updateColors {
    [super updateColors];

    NSColor *iconColor = self.isDarkMode ? NSColor.secondaryLabelColor : NSColor.tertiaryLabelColor;
    self.idCopyButton.contentTintColor = iconColor;
    self.moduleCopyButton.contentTintColor = iconColor;
    self.filenameCopyButton.contentTintColor = iconColor;
    self.toastView.backgroundColor = [NSColor.controlAccentColor colorWithAlphaComponent:self.isDarkMode ? 0.9 : 0.85];
}

- (void)_renderMessage {
    NSString *message = self.localMessage;
    BOOL isError = self.localMessageIsError;

    if (self.payload.warningText.length) {
        message = self.payload.warningText;
        isError = YES;
    } else if (self.payload.guessStatusText.length) {
        message = self.payload.guessStatusText;
        isError = self.payload.isGuessFailed;
    }

    self.messageLabel.stringValue = message ?: @"";
    self.messageLabel.textColor = isError ? NSColor.systemRedColor : [NSColor colorNamed:@"DashboardInputAccessoryColor"];
    self.messageLabel.hidden = (message.length == 0);
}

@end
