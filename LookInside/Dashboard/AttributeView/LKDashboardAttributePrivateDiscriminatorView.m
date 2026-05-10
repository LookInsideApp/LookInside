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

@interface LKDashboardAttributePrivateDiscriminatorView ()

@property(nonatomic, strong) NSTextField *idTitleLabel;
@property(nonatomic, strong) NSTextField *idValueLabel;
@property(nonatomic, strong) NSTextField *moduleTitleLabel;
@property(nonatomic, strong) NSTextField *moduleField;
@property(nonatomic, strong) NSTextField *filenameTitleLabel;
@property(nonatomic, strong) NSTextField *filenameField;
@property(nonatomic, strong) NSTextField *sourceLabel;
@property(nonatomic, strong) NSTextField *messageLabel;
@property(nonatomic, strong) NSButton *importButton;
@property(nonatomic, strong) NSButton *guessButton;
@property(nonatomic, strong) NSButton *cancelButton;

@property(nonatomic, strong) LKPrivateDiscriminatorDashboardPayload *payload;
@property(nonatomic, copy) NSString *localMessage;
@property(nonatomic, assign) BOOL localMessageIsError;

@end

@implementation LKDashboardAttributePrivateDiscriminatorView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.layer.cornerRadius = DashboardCardControlCornerRadius;
        self.backgroundColorName = @"DashboardCardValueBGColor";

        self.idTitleLabel = [self _makeTitleLabel:@"ID"];
        self.idValueLabel = [self _makeValueLabel:@""];
        self.idValueLabel.selectable = YES;

        self.moduleTitleLabel = [self _makeTitleLabel:@"Module"];
        self.moduleField = [self _makeTextFieldWithPlaceholder:@"ModuleName"];
        self.filenameTitleLabel = [self _makeTitleLabel:@"Filename"];
        self.filenameField = [self _makeTextFieldWithPlaceholder:@"File.swift"];

        self.sourceLabel = [self _makeValueLabel:@""];
        self.sourceLabel.font = [NSFont systemFontOfSize:11];
        self.sourceLabel.textColor = NSColor.secondaryLabelColor;

        self.messageLabel = [self _makeValueLabel:@""];
        self.messageLabel.font = [NSFont systemFontOfSize:11];
        self.messageLabel.maximumNumberOfLines = 0;

        self.importButton = [NSButton buttonWithTitle:@"Import from your codebase" target:self action:@selector(_handleImportButton:)];
        self.importButton.bezelStyle = NSBezelStyleRounded;

        self.guessButton = [NSButton buttonWithTitle:@"Guess by swift-pd-guess" target:self action:@selector(_handleGuessButton:)];
        self.guessButton.bezelStyle = NSBezelStyleRounded;

        self.cancelButton = [NSButton buttonWithTitle:@"Cancel" target:self action:@selector(_handleCancelButton:)];
        self.cancelButton.bezelStyle = NSBezelStyleRounded;

        NSArray<NSView *> *subviews = @[
            self.idTitleLabel,
            self.idValueLabel,
            self.moduleTitleLabel,
            self.moduleField,
            self.filenameTitleLabel,
            self.filenameField,
            self.sourceLabel,
            self.messageLabel,
            self.importButton,
            self.guessButton,
            self.cancelButton,
        ];
        [subviews enumerateObjectsUsingBlock:^(NSView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
            [self addSubview:view];
        }];

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

    BOOL canEdit = self.payload && !self.payload.isMatched && !self.payload.isGuessRunning;
    self.moduleField.editable = canEdit;
    self.filenameField.editable = canEdit;
    self.moduleField.enabled = canEdit;
    self.filenameField.enabled = canEdit;

    self.importButton.hidden = self.payload.isMatched || self.payload.isGuessRunning;
    self.guessButton.hidden = self.payload.isMatched || self.payload.isGuessRunning;
    self.cancelButton.hidden = !self.payload.isGuessRunning;

    if (self.payload.isMatched) {
        NSString *source = self.payload.source.length ? self.payload.source : @"matched";
        self.sourceLabel.stringValue = self.payload.isVerified
            ? [NSString stringWithFormat:@"Verified from %@.", source]
            : [NSString stringWithFormat:@"Matched from %@.", source];
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
    CGFloat y = 8;
    CGFloat width = MAX(self.$width - 16, 1);
    CGFloat titleWidth = 58;
    CGFloat fieldX = x + titleWidth + 8;
    CGFloat fieldWidth = MAX(width - titleWidth - 8, 1);
    CGFloat rowHeight = 24;

    $(self.idTitleLabel).x(x).y(y + 3).width(titleWidth).height(18);
    $(self.idValueLabel).x(fieldX).y(y).width(fieldWidth).height(34);
    y = self.idValueLabel.$maxY + 8;

    $(self.moduleTitleLabel).x(x).y(y + 4).width(titleWidth).height(18);
    $(self.moduleField).x(fieldX).y(y).width(fieldWidth).height(rowHeight);
    y = self.moduleField.$maxY + 8;

    $(self.filenameTitleLabel).x(x).y(y + 4).width(titleWidth).height(18);
    $(self.filenameField).x(fieldX).y(y).width(fieldWidth).height(rowHeight);
    y = self.filenameField.$maxY + 8;

    if (!self.sourceLabel.hidden) {
        $(self.sourceLabel).x(x).y(y).width(width).heightToFit;
        y = self.sourceLabel.$maxY + 8;
    }

    if (!self.messageLabel.hidden) {
        $(self.messageLabel).x(x).y(y).width(width).heightToFit;
        y = self.messageLabel.$maxY + 8;
    }

    if (!self.importButton.hidden) {
        $(self.importButton).x(x).y(y).height(rowHeight).width(154);
        $(self.guessButton).x(self.importButton.$maxX + 8).y(y).height(rowHeight).width(MAX(width - 162, 120));
        y = self.importButton.$maxY + 2;
    }

    if (!self.cancelButton.hidden) {
        $(self.cancelButton).x(x).y(y).height(rowHeight).width(86);
    }
}

- (NSSize)sizeThatFits:(NSSize)limitedSize {
    CGFloat width = MAX(limitedSize.width, 1);
    CGFloat height = 8 + 34 + 8 + 24 + 8 + 24 + 8;
    if (!self.sourceLabel.hidden) {
        height += [self.sourceLabel sizeThatFits:NSMakeSize(width - 16, CGFLOAT_MAX)].height + 8;
    }
    if (!self.messageLabel.hidden) {
        height += [self.messageLabel sizeThatFits:NSMakeSize(width - 16, CGFLOAT_MAX)].height + 8;
    }
    if (!self.importButton.hidden) {
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
        self.localMessage = @"Saved.";
        self.localMessageIsError = NO;
        [self.dashboardViewController reloadCurrentDisplayItem];
    } else {
        self.localMessage = error.localizedDescription ?: @"Verification failed.";
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

- (void)_handleDashboardStateDidChange:(NSNotification *)notification {
    [self.dashboardViewController reloadCurrentDisplayItem];
}

#pragma mark - Views

- (NSTextField *)_makeTitleLabel:(NSString *)title {
    NSTextField *label = [NSTextField labelWithString:title];
    label.font = [NSFont systemFontOfSize:11 weight:NSFontWeightMedium];
    label.textColor = NSColor.secondaryLabelColor;
    return label;
}

- (NSTextField *)_makeValueLabel:(NSString *)value {
    NSTextField *label = [NSTextField wrappingLabelWithString:value];
    label.font = [NSFont systemFontOfSize:12];
    label.textColor = NSColor.labelColor;
    return label;
}

- (NSTextField *)_makeTextFieldWithPlaceholder:(NSString *)placeholder {
    NSTextField *field = [NSTextField new];
    field.placeholderString = placeholder;
    field.font = [NSFont systemFontOfSize:12];
    field.target = self;
    field.action = @selector(_submitManualValue:);
    return field;
}

- (void)_renderMessage {
    NSString *message = self.localMessage;
    BOOL isError = self.localMessageIsError;

    if (self.payload.warningText.length) {
        message = self.payload.warningText;
        isError = YES;
    } else if (self.payload.guessStatusText.length) {
        message = self.payload.guessStatusText;
        isError = [self.payload.guessStatusText hasPrefix:@"Failed"];
    }

    self.messageLabel.stringValue = message ?: @"";
    self.messageLabel.textColor = isError ? NSColor.systemRedColor : NSColor.secondaryLabelColor;
    self.messageLabel.hidden = (message.length == 0);
}

@end
