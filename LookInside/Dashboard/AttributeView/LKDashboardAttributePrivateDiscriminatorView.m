//
//  LKDashboardAttributePrivateDiscriminatorView.m
//  LookInside
//

#import "LKDashboardAttributePrivateDiscriminatorView.h"
#import "LKDashboardViewController.h"
#import "LookinAttribute.h"
#import "LookinDisplayItem.h"
#import "LookInside-Swift.h"

static NSString *const LKPrivateDiscriminatorDashboardStateDidChangeNotification = @"LKPrivateDiscriminatorDashboardStateDidChange";

@interface LKPrivateDiscriminatorCopyLabel : NSTextField

@property(nonatomic, copy) NSString *fieldName;

@end

@implementation LKPrivateDiscriminatorCopyLabel

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.bezeled = NO;
        self.drawsBackground = NO;
        self.editable = NO;
        self.selectable = NO;
        self.font = [NSFont systemFontOfSize:12];
        self.textColor = NSColor.labelColor;
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

@property(nonatomic, strong) NSTextField *idTitleLabel;
@property(nonatomic, strong) LKPrivateDiscriminatorCopyLabel *idValueLabel;
@property(nonatomic, strong) NSButton *idCopyButton;
@property(nonatomic, strong) NSTextField *moduleTitleLabel;
@property(nonatomic, strong) NSTextField *moduleField;
@property(nonatomic, strong) LKPrivateDiscriminatorCopyLabel *moduleValueLabel;
@property(nonatomic, strong) NSButton *moduleCopyButton;
@property(nonatomic, strong) NSTextField *filenameTitleLabel;
@property(nonatomic, strong) NSTextField *filenameField;
@property(nonatomic, strong) LKPrivateDiscriminatorCopyLabel *filenameValueLabel;
@property(nonatomic, strong) NSButton *filenameCopyButton;
@property(nonatomic, strong) NSTextField *sourceLabel;
@property(nonatomic, strong) NSTextField *messageLabel;
@property(nonatomic, strong) NSButton *importButton;
@property(nonatomic, strong) NSButton *guessButton;
@property(nonatomic, strong) NSButton *cancelButton;
@property(nonatomic, strong) LKBaseView *idSeparator;
@property(nonatomic, strong) LKBaseView *moduleSeparator;
@property(nonatomic, strong) LKBaseView *filenameSeparator;
@property(nonatomic, strong) LKBaseView *toastView;
@property(nonatomic, strong) NSTextField *toastLabel;

@property(nonatomic, strong) LKPrivateDiscriminatorDashboardPayload *payload;
@property(nonatomic, copy) NSString *localMessage;
@property(nonatomic, assign) BOOL localMessageIsError;

@end

@implementation LKDashboardAttributePrivateDiscriminatorView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.layer.cornerRadius = 7;
        self.layer.borderWidth = 1;
        self.backgroundColorName = @"DashboardCardValueBGColor";

        self.idTitleLabel = [self _makeTitleLabel:NSLocalizedString(@"ID", nil)];
        self.idValueLabel = [self _makeCopyLabelNamed:NSLocalizedString(@"ID", nil)];
        self.idValueLabel.font = [NSFont monospacedSystemFontOfSize:12.5 weight:NSFontWeightRegular];
        self.idCopyButton = [self _makeCopyButton];

        self.moduleTitleLabel = [self _makeTitleLabel:NSLocalizedString(@"Module", nil)];
        self.moduleField = [self _makeTextFieldWithPlaceholder:NSLocalizedString(@"ModuleName", nil)];
        self.moduleValueLabel = [self _makeCopyLabelNamed:NSLocalizedString(@"Module", nil)];
        self.moduleValueLabel.font = [NSFont systemFontOfSize:13];
        self.moduleCopyButton = [self _makeCopyButton];
        self.filenameTitleLabel = [self _makeTitleLabel:NSLocalizedString(@"Filename", nil)];
        self.filenameField = [self _makeTextFieldWithPlaceholder:NSLocalizedString(@"File.swift", nil)];
        self.filenameValueLabel = [self _makeCopyLabelNamed:NSLocalizedString(@"Filename", nil)];
        self.filenameValueLabel.font = [NSFont systemFontOfSize:13];
        self.filenameCopyButton = [self _makeCopyButton];

        self.sourceLabel = [self _makeValueLabel:@""];
        self.sourceLabel.font = [NSFont systemFontOfSize:11];
        self.sourceLabel.textColor = NSColor.secondaryLabelColor;

        self.messageLabel = [self _makeValueLabel:@""];
        self.messageLabel.font = [NSFont systemFontOfSize:11];
        self.messageLabel.maximumNumberOfLines = 0;

        self.importButton = [NSButton buttonWithTitle:NSLocalizedString(@"Import from your codebase", nil) target:self action:@selector(_handleImportButton:)];
        self.importButton.bezelStyle = NSBezelStyleRounded;

        self.guessButton = [NSButton buttonWithTitle:NSLocalizedString(@"Guess by swift-pd-guess", nil) target:self action:@selector(_handleGuessButton:)];
        self.guessButton.bezelStyle = NSBezelStyleRounded;

        self.cancelButton = [NSButton buttonWithTitle:NSLocalizedString(@"Cancel", nil) target:self action:@selector(_handleCancelButton:)];
        self.cancelButton.bezelStyle = NSBezelStyleRounded;

        self.idSeparator = [self _makeSeparator];
        self.moduleSeparator = [self _makeSeparator];
        self.filenameSeparator = [self _makeSeparator];

        self.toastView = [LKBaseView new];
        self.toastView.layer.cornerRadius = 10;
        self.toastView.hidden = YES;
        self.toastView.alphaValue = 0;

        self.toastLabel = [NSTextField labelWithString:NSLocalizedString(@"Copied", nil)];
        self.toastLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold];
        self.toastLabel.textColor = NSColor.whiteColor;
        self.toastLabel.alignment = NSTextAlignmentCenter;
        [self.toastView addSubview:self.toastLabel];

        NSArray<NSView *> *subviews = @[
            self.idTitleLabel,
            self.idValueLabel,
            self.idCopyButton,
            self.idSeparator,
            self.moduleTitleLabel,
            self.moduleField,
            self.moduleValueLabel,
            self.moduleCopyButton,
            self.moduleSeparator,
            self.filenameTitleLabel,
            self.filenameField,
            self.filenameValueLabel,
            self.filenameCopyButton,
            self.filenameSeparator,
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

- (void)layout {
    [super layout];

    CGFloat x = 8;
    CGFloat y = 10;
    CGFloat width = MAX(self.$width - 16, 1);
    CGFloat titleWidth = 72;
    CGFloat fieldX = x + titleWidth + 8;
    CGFloat copySize = 20;
    CGFloat copyGap = 6;
    CGFloat fieldWidth = MAX(width - titleWidth - 8, 1);
    CGFloat rowHeight = 24;
    CGFloat visibleIDCopyWidth = self.idCopyButton.hidden ? 0 : (copySize + copyGap);
    CGFloat visibleModuleCopyWidth = self.moduleCopyButton.hidden ? 0 : (copySize + copyGap);
    CGFloat visibleFilenameCopyWidth = self.filenameCopyButton.hidden ? 0 : (copySize + copyGap);

    $(self.idTitleLabel).x(x).y(y + 3).width(titleWidth).height(18);
    CGFloat idValueWidth = MAX(fieldWidth - visibleIDCopyWidth, 1);
    CGFloat idHeight = MAX(18, [self.idValueLabel sizeThatFits:NSMakeSize(idValueWidth, CGFLOAT_MAX)].height);
    $(self.idValueLabel).x(fieldX).y(y).width(idValueWidth).height(idHeight);
    if (!self.idCopyButton.hidden) {
        $(self.idCopyButton).x(self.idValueLabel.$maxX + copyGap).y(y - 1).width(copySize).height(copySize);
    }
    y = MAX(self.idTitleLabel.$maxY, self.idValueLabel.$maxY) + 8;
    [self _layoutSeparator:self.idSeparator x:x y:y - 4 width:width];
    y += 4;

    $(self.moduleTitleLabel).x(x).y(y + 4).width(titleWidth).height(18);
    if (self.moduleField.hidden) {
        CGFloat moduleValueWidth = MAX(fieldWidth - visibleModuleCopyWidth, 1);
        CGFloat moduleHeight = MAX(18, [self.moduleValueLabel sizeThatFits:NSMakeSize(moduleValueWidth, CGFLOAT_MAX)].height);
        $(self.moduleValueLabel).x(fieldX).y(y + 3).width(moduleValueWidth).height(moduleHeight);
        if (!self.moduleCopyButton.hidden) {
            $(self.moduleCopyButton).x(self.moduleValueLabel.$maxX + copyGap).y(y + 2).width(copySize).height(copySize);
        }
        y = MAX(self.moduleTitleLabel.$maxY, self.moduleValueLabel.$maxY) + 8;
    } else {
        $(self.moduleField).x(fieldX).y(y).width(fieldWidth).height(rowHeight);
        y = self.moduleField.$maxY + 8;
    }
    [self _layoutSeparator:self.moduleSeparator x:x y:y - 4 width:width];
    y += 4;

    $(self.filenameTitleLabel).x(x).y(y + 4).width(titleWidth).height(18);
    if (self.filenameField.hidden) {
        CGFloat filenameValueWidth = MAX(fieldWidth - visibleFilenameCopyWidth, 1);
        CGFloat filenameHeight = MAX(18, [self.filenameValueLabel sizeThatFits:NSMakeSize(filenameValueWidth, CGFLOAT_MAX)].height);
        $(self.filenameValueLabel).x(fieldX).y(y + 3).width(filenameValueWidth).height(filenameHeight);
        if (!self.filenameCopyButton.hidden) {
            $(self.filenameCopyButton).x(self.filenameValueLabel.$maxX + copyGap).y(y + 2).width(copySize).height(copySize);
        }
        y = MAX(self.filenameTitleLabel.$maxY, self.filenameValueLabel.$maxY) + 8;
    } else {
        $(self.filenameField).x(fieldX).y(y).width(fieldWidth).height(rowHeight);
        y = self.filenameField.$maxY + 8;
    }
    self.filenameSeparator.hidden = self.sourceLabel.hidden && self.messageLabel.hidden && self.importButton.hidden && self.guessButton.hidden && self.cancelButton.hidden;
    if (!self.filenameSeparator.hidden) {
        [self _layoutSeparator:self.filenameSeparator x:x y:y - 4 width:width];
        y += 4;
    }

    if (!self.sourceLabel.hidden) {
        $(self.sourceLabel).x(x).y(y).width(width).heightToFit;
        y = self.sourceLabel.$maxY + 8;
    }

    if (!self.messageLabel.hidden) {
        $(self.messageLabel).x(x).y(y).width(width).heightToFit;
        y = self.messageLabel.$maxY + 8;
    }

    if (!self.importButton.hidden) {
        $(self.importButton).x(x).y(y).height(rowHeight).width(width);
        y = self.importButton.$maxY + 6;
    }

    if (!self.guessButton.hidden) {
        $(self.guessButton).x(x).y(y).height(rowHeight).width(width);
        y = self.guessButton.$maxY + 2;
    }

    if (!self.cancelButton.hidden) {
        $(self.cancelButton).x(x).y(y).height(rowHeight).width(86);
    }

    if (!self.toastView.hidden) {
        $(self.toastLabel).x(8).toRight(8).heightToFit.verAlign;
    }
}

- (NSSize)sizeThatFits:(NSSize)limitedSize {
    CGFloat width = MAX(limitedSize.width, 1);
    CGFloat contentWidth = MAX(width - 16, 1);
    CGFloat fieldWidth = MAX(contentWidth - 72 - 8, 1);
    CGFloat copyWidth = 26;
    CGFloat idHeight = MAX(18, [self.idValueLabel sizeThatFits:NSMakeSize(MAX(fieldWidth - copyWidth, 1), CGFLOAT_MAX)].height);
    CGFloat moduleHeight = self.moduleField.hidden
        ? MAX(18, [self.moduleValueLabel sizeThatFits:NSMakeSize(MAX(fieldWidth - (self.moduleCopyButton.hidden ? 0 : copyWidth), 1), CGFLOAT_MAX)].height)
        : 24;
    CGFloat filenameHeight = self.filenameField.hidden
        ? MAX(18, [self.filenameValueLabel sizeThatFits:NSMakeSize(MAX(fieldWidth - (self.filenameCopyButton.hidden ? 0 : copyWidth), 1), CGFLOAT_MAX)].height)
        : 24;

    CGFloat height = 10 + idHeight + 12 + moduleHeight + 12 + filenameHeight + 10;
    if (!self.sourceLabel.hidden) {
        height += [self.sourceLabel sizeThatFits:NSMakeSize(width - 16, CGFLOAT_MAX)].height + 8;
    }
    if (!self.messageLabel.hidden) {
        height += [self.messageLabel sizeThatFits:NSMakeSize(width - 16, CGFLOAT_MAX)].height + 8;
    }
    if (!self.importButton.hidden) {
        height += 30;
    }
    if (!self.guessButton.hidden) {
        height += 26;
    }
    if (!self.cancelButton.hidden) {
        height += 26;
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

- (NSTextField *)_makeTitleLabel:(NSString *)title {
    NSTextField *label = [NSTextField labelWithString:title];
    label.font = [NSFont systemFontOfSize:12 weight:NSFontWeightSemibold];
    label.textColor = NSColor.secondaryLabelColor;
    return label;
}

- (NSTextField *)_makeValueLabel:(NSString *)value {
    NSTextField *label = [NSTextField wrappingLabelWithString:value];
    label.font = [NSFont systemFontOfSize:13];
    label.textColor = NSColor.labelColor;
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
    NSButton *button = [NSButton buttonWithImage:image ?: NSImage.new target:self action:@selector(_handleCopyButton:)];
    button.bezelStyle = NSBezelStyleRoundRect;
    button.bordered = NO;
    button.imagePosition = NSImageOnly;
    button.toolTip = NSLocalizedString(@"Copy", nil);
    if (image) {
        image.template = YES;
    }
    return button;
}

- (LKBaseView *)_makeSeparator {
    LKBaseView *separator = [LKBaseView new];
    return separator;
}

- (NSTextField *)_makeTextFieldWithPlaceholder:(NSString *)placeholder {
    NSTextField *field = [NSTextField new];
    field.placeholderString = placeholder;
    field.font = [NSFont systemFontOfSize:12];
    field.target = self;
    field.action = @selector(_submitManualValue:);
    return field;
}

- (void)_layoutSeparator:(LKBaseView *)separator x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width {
    separator.hidden = NO;
    $(separator).x(x).y(y).width(width).height(1);
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
    NSRect sourceFrame = sourceView.frame;
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

    NSColor *borderColor = [NSColor.separatorColor colorWithAlphaComponent:self.isDarkMode ? 0.55 : 0.65];
    self.layer.borderColor = borderColor.CGColor;
    NSColor *separatorColor = [NSColor.separatorColor colorWithAlphaComponent:self.isDarkMode ? 0.45 : 0.5];
    NSArray<LKBaseView *> *separators = @[self.idSeparator ?: LKBaseView.new, self.moduleSeparator ?: LKBaseView.new, self.filenameSeparator ?: LKBaseView.new];
    for (LKBaseView *separator in separators) {
        separator.backgroundColor = separatorColor;
    }
    NSColor *iconColor = self.isDarkMode ? NSColor.secondaryLabelColor : NSColor.tertiaryLabelColor;
    self.idCopyButton.contentTintColor = iconColor;
    self.moduleCopyButton.contentTintColor = iconColor;
    self.filenameCopyButton.contentTintColor = iconColor;
    self.toastView.backgroundColor = [NSColor.controlAccentColor colorWithAlphaComponent:self.isDarkMode ? 0.92 : 0.88];
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
    self.messageLabel.textColor = isError ? NSColor.systemRedColor : NSColor.secondaryLabelColor;
    self.messageLabel.hidden = (message.length == 0);
}

@end
