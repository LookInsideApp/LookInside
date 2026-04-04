//
//  LKPreferenceManager.m
//  Lookin
//
//  Created by Li Kai on 2019/1/8.
//  https://lookin.work
//

#import "LKPreferenceManager.h"
#import "LookinDashboardBlueprint.h"
#import "LKPreviewView.h"

NSString *const NotificationName_DidChangeSectionShowing = @"NotificationName_DidChangeSectionShowing";

NSString *const LKWindowSizeName_Dynamic = @"LKWindowSizeName_Dynamic";
NSString *const LKWindowSizeName_Static = @"LKWindowSizeName_Static";

const CGFloat LKInitialPreviewScale = 0.27;

static NSString * const Key_PreviousClientVersion = @"preVer";
static NSString * const Key_ShowOutline = @"showOutline";
static NSString * const Key_ShowHiddenItems = @"showHiddenItems";
static NSString * const Key_RgbaFormat = @"egbaFormat";
static NSString * const Key_ZInterspace = @"zInterspace_v095";
static NSString * const Key_AppearanceType = @"appearanceType";
static NSString * const Key_DoubleClickBehavior = @"doubleClickBehavior";
static NSString * const Key_ExpansionIndex = @"expansionIndex";
static NSString * const Key_ContrastLevel = @"contrastLevel";
static NSString * const Key_SectionsShow = @"ss";
static NSString * const Key_CollapsedGroups = @"collapsedGroups_918";
static NSString * const Key_PreferredExportCompression = @"preferredExportCompression";
static NSString * const Key_CallStackType = @"callStackType";
static NSString * const Key_SyncConsoleTarget = @"syncConsoleTarget";
static NSString * const Key_FreeRotation = @"FreeRotation";
static NSString * const Key_FastMode = @"fastMode";
static NSString * const Key_ReceivingConfigTime_Color = @"ConfigTime_Color";
static NSString * const Key_ReceivingConfigTime_Class = @"ConfigTime_Class";

@interface LKPreferenceManager ()

@property(nonatomic, strong) NSMutableDictionary<LookinAttrSectionIdentifier, NSNumber *> *storedSectionShowConfig;

@end

@implementation LKPreferenceManager

+ (instancetype)mainManager {
    static dispatch_once_t onceToken;
    static LKPreferenceManager *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
        instance.shouldStoreToLocal = YES;
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _previewScale = [LookinDoubleMsgAttribute attributeWithDouble:LKInitialPreviewScale];
        _previewDimension = [LookinIntegerMsgAttribute attributeWithInteger:LookinPreviewDimension3D];
        _measureState = [LookinIntegerMsgAttribute attributeWithInteger:LookinMeasureState_no];
        _isQuickSelecting = [LookinBOOLMsgAttribute attributeWithBOOL:NO];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        // 如果本次 Lookin 客户端的 version 和上次不同，则该变量会被置为 YES
//        BOOL clientVersionHasChanged = NO;
        NSInteger prevClientVersion = [userDefaults integerForKey:Key_PreviousClientVersion];
        if (prevClientVersion != LOOKIN_CLIENT_VERSION) {
//            clientVersionHasChanged = YES;
            [[NSUserDefaults standardUserDefaults] setInteger:LOOKIN_CLIENT_VERSION forKey:Key_PreviousClientVersion];
        }
        
        NSNumber *obj_showOutline = [userDefaults objectForKey:Key_ShowOutline];
        if (obj_showOutline != nil) {
            _showOutline = [LookinBOOLMsgAttribute attributeWithBOOL:[obj_showOutline boolValue]];
        } else {
            _showOutline = [LookinBOOLMsgAttribute attributeWithBOOL:YES];
            [userDefaults setObject:@(YES) forKey:Key_ShowOutline];
        }
        [self.showHiddenItems subscribe:self action:@selector(_handleShowOutlineDidChange:) relatedObject:nil];
        
        NSNumber *obj_showHiddenItems = [userDefaults objectForKey:Key_ShowHiddenItems];
        if (obj_showHiddenItems != nil) {
            _showHiddenItems = [LookinBOOLMsgAttribute attributeWithBOOL:[obj_showHiddenItems boolValue]];
        } else {
            _showHiddenItems = [LookinBOOLMsgAttribute attributeWithBOOL:NO];
            [userDefaults setObject:@(NO) forKey:Key_ShowHiddenItems];
        }
        [self.showHiddenItems subscribe:self action:@selector(_handleShowHiddenItemsChange:) relatedObject:nil];
        
        NSNumber *obj_doubleClickBehavior = [userDefaults objectForKey:Key_DoubleClickBehavior];
        if (obj_doubleClickBehavior) {
            _doubleClickBehavior = [obj_doubleClickBehavior intValue];
        } else {
            _doubleClickBehavior = LookinDoubleClickBehaviorCollapse;
            [userDefaults setObject:@(_doubleClickBehavior) forKey:Key_DoubleClickBehavior];
        }
        
        NSNumber *obj_rgbaFormat = [userDefaults objectForKey:Key_RgbaFormat];
        if (obj_rgbaFormat != nil) {
            _rgbaFormat = [obj_rgbaFormat boolValue];
        } else {
            _rgbaFormat = YES;
            [userDefaults setObject:@(_rgbaFormat) forKey:Key_RgbaFormat];
        }
        
        double zInterspaceValue;
        NSNumber *obj_zInterspace = [userDefaults objectForKey:Key_ZInterspace];
        if (obj_zInterspace != nil) {
            zInterspaceValue = [obj_zInterspace doubleValue];
        } else {
            /// 默认值为 0.22
            zInterspaceValue = .22;
            [userDefaults setObject:@(zInterspaceValue) forKey:Key_ZInterspace];
        }
        zInterspaceValue = MAX(MIN(zInterspaceValue, LookinPreviewMaxZInterspace), LookinPreviewMinZInterspace);
        _zInterspace = [LookinDoubleMsgAttribute attributeWithDouble:zInterspaceValue];
        [self.zInterspace subscribe:self action:@selector(_handleZInterspaceDidChange:) relatedObject:nil];
        
        NSNumber *obj_appearanceType = [userDefaults objectForKey:Key_AppearanceType];
        if (obj_appearanceType != nil) {
            _appearanceType = [obj_appearanceType integerValue];
        } else {
            _appearanceType = LookinPreferredAppeanranceTypeSystem;
            [userDefaults setObject:@(_appearanceType) forKey:Key_AppearanceType];
        }
        
        NSNumber *obj_expansionIndex = [userDefaults objectForKey:Key_ExpansionIndex];
        if (obj_expansionIndex != nil) {
            _expansionIndex = [obj_expansionIndex integerValue];
        } else {
            _expansionIndex = 3;
            [userDefaults setObject:@(_expansionIndex) forKey:Key_ExpansionIndex];
        }
        
        NSNumber *obj_contrastLevel = [userDefaults objectForKey:Key_ContrastLevel];
        if (obj_contrastLevel != nil) {
            _imageContrastLevel = [obj_contrastLevel integerValue];
        } else {
            _imageContrastLevel = 0;
            [userDefaults setObject:@(_imageContrastLevel) forKey:Key_ContrastLevel];
        }
        
        NSNumber *obj_syncConsoleTarget = [userDefaults objectForKey:Key_SyncConsoleTarget];
        if (obj_syncConsoleTarget != nil) {
            _syncConsoleTarget = [obj_syncConsoleTarget boolValue];
        } else {
            _syncConsoleTarget = YES;
            [userDefaults setObject:@(_syncConsoleTarget) forKey:Key_SyncConsoleTarget];
        }
        
        NSNumber *obj_freeRotation = [userDefaults objectForKey:Key_FreeRotation];
        if (obj_freeRotation != nil) {
            _freeRotation = [LookinBOOLMsgAttribute attributeWithBOOL:obj_freeRotation.boolValue];
        } else {
            _freeRotation = [LookinBOOLMsgAttribute attributeWithBOOL:YES];
            [userDefaults setObject:@(_freeRotation.currentBOOLValue) forKey:Key_FreeRotation];
        }
        [self.freeRotation subscribe:self action:@selector(_handleFreeRotationDidChange:) relatedObject:nil];
        
        NSNumber *obj_fastMode = [userDefaults objectForKey:Key_FastMode];
        if (obj_fastMode != nil) {
            _fastMode = [LookinBOOLMsgAttribute attributeWithBOOL:obj_fastMode.boolValue];
        } else {
            _fastMode = [LookinBOOLMsgAttribute attributeWithBOOL:NO];
            [userDefaults setObject:@(_fastMode.currentBOOLValue) forKey:Key_FastMode];
        }
        [self.fastMode subscribe:self action:@selector(_handleFastModeDidChange:) relatedObject:nil];
        
        self.storedSectionShowConfig = [[userDefaults objectForKey:Key_SectionsShow] mutableCopy];
        if (!self.storedSectionShowConfig) {
            self.storedSectionShowConfig = [NSMutableDictionary dictionary];
        }
        
        _collapsedAttrGroups = [userDefaults objectForKey:Key_CollapsedGroups];
        if (!_collapsedAttrGroups) {
            _collapsedAttrGroups = @[LookinAttrGroup_Class];
        }
        
        NSNumber *obj_preferredExportCompression = [userDefaults objectForKey:Key_PreferredExportCompression];
        if (obj_preferredExportCompression != nil) {
            _preferredExportCompression = [obj_preferredExportCompression doubleValue];
        } else {
            /// 这里的默认值需要在 LKExportAccessory.m 里定义的选项里面
            _preferredExportCompression = .5;
            [userDefaults setObject:@(_preferredExportCompression) forKey:Key_PreferredExportCompression];
        }
        
        _receivingConfigTime_Color = [userDefaults doubleForKey:Key_ReceivingConfigTime_Color];
        _receivingConfigTime_Class = [userDefaults doubleForKey:Key_ReceivingConfigTime_Class];
    }
    return self;
}

- (void)_handleShowOutlineDidChange:(LookinMsgActionParams *)param {
    if (self.shouldStoreToLocal) {
        [[NSUserDefaults standardUserDefaults] setObject:@(param.boolValue) forKey:Key_ShowOutline];
    }
}

- (void)_handleShowHiddenItemsChange:(LookinMsgActionParams *)param {
    if (self.shouldStoreToLocal) {
        [[NSUserDefaults standardUserDefaults] setObject:@(param.boolValue) forKey:Key_ShowHiddenItems];
    }
}

- (void)setRgbaFormat:(BOOL)rgbaFormat {
    if (_rgbaFormat == rgbaFormat) {
        return;
    }
    _rgbaFormat = rgbaFormat;
    if (self.shouldStoreToLocal) {
        [[NSUserDefaults standardUserDefaults] setObject:@(rgbaFormat) forKey:Key_RgbaFormat];
    }
}

- (void)setDoubleClickBehavior:(LookinDoubleClickBehavior)doubleClickBehavior {
    _doubleClickBehavior = doubleClickBehavior;
    if (self.shouldStoreToLocal) {
        [[NSUserDefaults standardUserDefaults] setObject:@(doubleClickBehavior) forKey:Key_DoubleClickBehavior];
    }
}

- (void)setAppearanceType:(LookinPreferredAppeanranceType)appearanceType {
    if (_appearanceType == appearanceType) {
        return;
    }
    _appearanceType = appearanceType;
    if (self.shouldStoreToLocal) {
        [[NSUserDefaults standardUserDefaults] setObject:@(appearanceType) forKey:Key_AppearanceType];
    }
}

- (void)setExpansionIndex:(NSInteger)expansionIndex {
    if (_expansionIndex == expansionIndex) {
        return;
    }
    _expansionIndex = expansionIndex;
    if (self.shouldStoreToLocal) {
        [[NSUserDefaults standardUserDefaults] setObject:@(expansionIndex) forKey:Key_ExpansionIndex];
    }
}

- (void)setImageContrastLevel:(NSInteger)imageContrastLevel {
    if (_imageContrastLevel == imageContrastLevel) {
        return;
    }
    _imageContrastLevel = imageContrastLevel;
    
    if (self.shouldStoreToLocal) {
        [[NSUserDefaults standardUserDefaults] setObject:@(imageContrastLevel) forKey:Key_ContrastLevel];
    }
}

- (void)setCollapsedAttrGroups:(NSArray<NSNumber *> *)collapsedAttrGroups {
    _collapsedAttrGroups = collapsedAttrGroups.copy;
    if (self.shouldStoreToLocal) {
        [[NSUserDefaults standardUserDefaults] setObject:collapsedAttrGroups forKey:Key_CollapsedGroups];
    }
}

- (void)setPreferredExportCompression:(CGFloat)preferredExportCompression {
    if (_preferredExportCompression == preferredExportCompression) {
        return;
    }
    _preferredExportCompression = preferredExportCompression;
    if (self.shouldStoreToLocal) {
        [[NSUserDefaults standardUserDefaults] setObject:@(preferredExportCompression) forKey:Key_PreferredExportCompression];
    }
}

- (void)setCallStackType:(LookinPreferredCallStackType)callStackType {
    if (callStackType < 0 || callStackType > 2) {
        NSAssert(NO, @"");
        callStackType = 0;
    }
    _callStackType = callStackType;
}

- (void)setSyncConsoleTarget:(BOOL)syncConsoleTarget {
    if (_syncConsoleTarget == syncConsoleTarget) {
        return;
    }
    _syncConsoleTarget = syncConsoleTarget;
    if (self.shouldStoreToLocal) {
        [[NSUserDefaults standardUserDefaults] setObject:@(syncConsoleTarget) forKey:Key_SyncConsoleTarget];
    }
}

- (void)setReceivingConfigTime_Class:(NSTimeInterval)receivingConfigTime_Class {
    _receivingConfigTime_Class = receivingConfigTime_Class;
    [[NSUserDefaults standardUserDefaults] setDouble:receivingConfigTime_Class forKey:Key_ReceivingConfigTime_Class];
}

- (void)setReceivingConfigTime_Color:(NSTimeInterval)receivingConfigTime_Color {
    _receivingConfigTime_Color = receivingConfigTime_Color;
    [[NSUserDefaults standardUserDefaults] setDouble:receivingConfigTime_Color forKey:Key_ReceivingConfigTime_Color];
}

- (void)_handleFreeRotationDidChange:(LookinMsgActionParams *)param {
    if (!self.shouldStoreToLocal) {
        return;
    }
    BOOL boolValue = param.boolValue;
    [[NSUserDefaults standardUserDefaults] setObject:@(boolValue) forKey:Key_FreeRotation];
}

- (void)_handleFastModeDidChange:(LookinMsgActionParams *)param {
    if (!self.shouldStoreToLocal) {
        return;
    }
    BOOL boolValue = param.boolValue;
    [[NSUserDefaults standardUserDefaults] setObject:@(boolValue) forKey:Key_FastMode];
}


- (void)_handleZInterspaceDidChange:(LookinMsgActionParams *)param {
    if (!self.shouldStoreToLocal) {
        return;
    }
    double doubleValue = param.doubleValue;
    [[NSUserDefaults standardUserDefaults] setObject:@(doubleValue) forKey:Key_ZInterspace];
}

/// 返回某个 section 是否应该被显示在主界面上
- (BOOL)isSectionShowing:(LookinAttrSectionIdentifier)secID {
    if (self.storedSectionShowConfig[secID] != nil) {
        return [self.storedSectionShowConfig[secID] boolValue];
    }
    NSSet<LookinAttrSectionIdentifier> *showingSecIDs = [self _showingSecIDsInDefault];
    if ([showingSecIDs containsObject:secID]) {
        return YES;
    } else {
        return NO;
    }
}

/// 把某个 section 显示在主界面上
- (void)showSection:(LookinAttrSectionIdentifier)secID {
    if ([self isSectionShowing:secID]) {
        NSAssert(NO, @"");
        return;
    }
    self.storedSectionShowConfig[secID] = @(YES);
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationName_DidChangeSectionShowing object:nil];
    [[NSUserDefaults standardUserDefaults] setObject:self.storedSectionShowConfig.copy forKey:Key_SectionsShow];
}

/// 把某个 section 从主界面上移除
- (void)hideSection:(LookinAttrSectionIdentifier)secID {
    if (![self isSectionShowing:secID]) {
        NSAssert(NO, @"");
        return;
    }
    self.storedSectionShowConfig[secID] = @(NO);
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationName_DidChangeSectionShowing object:nil];
    [[NSUserDefaults standardUserDefaults] setObject:self.storedSectionShowConfig.copy forKey:Key_SectionsShow];
}

/// 返回默认情况下，哪些 section 应该被显示在主界面上
- (NSSet<LookinAttrSectionIdentifier> *)_showingSecIDsInDefault {
    static dispatch_once_t onceToken;
    static NSSet *targetSet = nil;
    dispatch_once(&onceToken,^{
        NSArray<LookinAttrSectionIdentifier> *array = @[LookinAttrSec_Class_Class,
                                                        
                                                        LookinAttrSec_Relation_Relation,
                                                        
                                                        LookinAttrSec_Layout_Frame,
                                                        LookinAttrSec_Layout_Bounds,
                                                        
                                                        LookinAttrSec_AutoLayout_Hugging,
                                                        LookinAttrSec_AutoLayout_Resistance,
                                                        LookinAttrSec_AutoLayout_Constraints,
                                                        LookinAttrSec_AutoLayout_IntrinsicSize,
                                                        
                                                        LookinAttrSec_ViewLayer_Visibility,
                                                        LookinAttrSec_ViewLayer_InterationAndMasks,
                                                        LookinAttrSec_ViewLayer_Corner,
                                                        LookinAttrSec_ViewLayer_BgColor,
                                                        LookinAttrSec_ViewLayer_Border,
                                                        LookinAttrSec_ViewLayer_Shadow,
                                                        
                                                        LookinAttrSec_UIStackView_Axis,
                                                        LookinAttrSec_UIStackView_Alignment,
                                                        LookinAttrSec_UIStackView_Distribution,
                                                        LookinAttrSec_UIStackView_Spacing,
                                                        
                                                        LookinAttrSec_UIVisualEffectView_Style,
                                                        LookinAttrSec_UIVisualEffectView_QMUIForegroundColor,
                                                        
                                                        LookinAttrSec_UIImageView_Name,
                                                        LookinAttrSec_UIImageView_Open,
                                                        
                                                        LookinAttrSec_UILabel_Text,
                                                        LookinAttrSec_UILabel_Font,
                                                        LookinAttrSec_UILabel_NumberOfLines,
                                                        LookinAttrSec_UILabel_TextColor,
                                                        LookinAttrSec_UILabel_BreakMode,
                                                        LookinAttrSec_UILabel_Alignment,
                                                        
                                                        LookinAttrSec_UIControl_EnabledSelected,
                                                        LookinAttrSec_UIControl_QMUIOutsideEdge,
                                                        
                                                        LookinAttrSec_UIButton_ContentInsets,
                                                        
                                                        LookinAttrSec_UIScrollView_ContentInset,
                                                        LookinAttrSec_UIScrollView_AdjustedInset,
                                                        LookinAttrSec_UIScrollView_IndicatorInset,
                                                        LookinAttrSec_UIScrollView_Offset,
                                                        LookinAttrSec_UIScrollView_ContentSize,
                                                        LookinAttrSec_UIScrollView_Behavior,
                                                        
                                                        LookinAttrSec_UITableView_Style,
                                                        LookinAttrSec_UITableView_SectionsNumber,
                                                        LookinAttrSec_UITableView_RowsNumber,
                                                        
                                                        LookinAttrSec_UITextView_Text,
                                                        LookinAttrSec_UITextView_Font,
                                                        LookinAttrSec_UITextView_TextColor,
                                                        LookinAttrSec_UITextView_Alignment,
                                                        LookinAttrSec_UITextView_ContainerInset,
                                                        
                                                        LookinAttrSec_UITextField_Text,
                                                        LookinAttrSec_UITextField_Font,
                                                        LookinAttrSec_UITextField_TextColor,
                                                        LookinAttrSec_UITextField_Alignment,

                                                        // NSWindow
                                                        LookinAttrSec_NSWindow_Title,
                                                        LookinAttrSec_NSWindow_Subtitle,
                                                        LookinAttrSec_NSWindow_State,
                                                        LookinAttrSec_NSWindow_Style,
                                                        LookinAttrSec_NSWindow_CollectionBehavior,
                                                        LookinAttrSec_NSWindow_Appearance,
                                                        LookinAttrSec_NSWindow_TitleVisibility,
                                                        LookinAttrSec_NSWindow_ToolbarStyle,
                                                        LookinAttrSec_NSWindow_TitlebarSeparatorStyle,
                                                        LookinAttrSec_NSWindow_Behavior,
                                                        LookinAttrSec_NSWindow_AnimationBehavior,
                                                        LookinAttrSec_NSWindow_Level,
                                                        LookinAttrSec_NSWindow_TabbingMode,
                                                        LookinAttrSec_NSWindow_Size,
                                                        LookinAttrSec_NSWindow_Info,
                                                        // NSImageView
                                                        LookinAttrSec_NSImageView_Name,
                                                        LookinAttrSec_NSImageView_Open,
                                                        LookinAttrSec_NSImageView_Scaling,
                                                        LookinAttrSec_NSImageView_Behavior,
                                                        LookinAttrSec_NSImageView_ContentTintColor,
                                                        // NSControl
                                                        LookinAttrSec_NSControl_State,
                                                        LookinAttrSec_NSControl_ControlSize,
                                                        LookinAttrSec_NSControl_Font,
                                                        LookinAttrSec_NSControl_Alignment,
                                                        LookinAttrSec_NSControl_Misc,
                                                        LookinAttrSec_NSControl_StringValue,
                                                        LookinAttrSec_NSControl_Value,
                                                        // NSButton
                                                        LookinAttrSec_NSButton_ButtonType,
                                                        LookinAttrSec_NSButton_Title,
                                                        LookinAttrSec_NSButton_BezelStyle,
                                                        LookinAttrSec_NSButton_Bordered,
                                                        LookinAttrSec_NSButton_BezelColor,
                                                        LookinAttrSec_NSButton_Misc,
                                                        // NSScrollView
                                                        LookinAttrSec_NSScrollView_ContentOffset,
                                                        LookinAttrSec_NSScrollView_ContentSize,
                                                        LookinAttrSec_NSScrollView_ContentInset,
                                                        LookinAttrSec_NSScrollView_BorderType,
                                                        LookinAttrSec_NSScrollView_Scroller,
                                                        LookinAttrSec_NSScrollView_Ruler,
                                                        LookinAttrSec_NSScrollView_LineScroll,
                                                        LookinAttrSec_NSScrollView_PageScroll,
                                                        LookinAttrSec_NSScrollView_ScrollElasiticity,
                                                        LookinAttrSec_NSScrollView_Misc,
                                                        LookinAttrSec_NSScrollView_Magnification,
                                                        // NSTableView
                                                        LookinAttrSec_NSTableView_RowHeight,
                                                        LookinAttrSec_NSTableView_AutomaticRowHeights,
                                                        LookinAttrSec_NSTableView_IntercellSpacing,
                                                        LookinAttrSec_NSTableView_Style,
                                                        LookinAttrSec_NSTableView_ColumnAutoresizingStyle,
                                                        LookinAttrSec_NSTableView_GridStyleMask,
                                                        LookinAttrSec_NSTableView_SelectionHighlightStyle,
                                                        LookinAttrSec_NSTableView_GridColor,
                                                        LookinAttrSec_NSTableView_RowSizeStyle,
                                                        LookinAttrSec_NSTableView_NumberOfRows,
                                                        LookinAttrSec_NSTableView_NumberOfColumns,
                                                        LookinAttrSec_NSTableView_UseAlternatingRowBackgroundColors,
                                                        LookinAttrSec_NSTableView_AllowsColumnReordering,
                                                        LookinAttrSec_NSTableView_AllowsColumnResizing,
                                                        LookinAttrSec_NSTableView_AllowsMultipleSelection,
                                                        LookinAttrSec_NSTableView_AllowsEmptySelection,
                                                        LookinAttrSec_NSTableView_AllowsColumnSelection,
                                                        LookinAttrSec_NSTableView_AllowsTypeSelect,
                                                        LookinAttrSec_NSTableView_DraggingDestinationFeedbackStyle,
                                                        LookinAttrSec_NSTableView_Autosave,
                                                        LookinAttrSec_NSTableView_FloatsGroupRows,
                                                        LookinAttrSec_NSTableView_RowActionsVisible,
                                                        LookinAttrSec_NSTableView_UsesStaticContents,
                                                        LookinAttrSec_NSTableView_UserInterfaceLayoutDirection,
                                                        LookinAttrSec_NSTableView_VerticalMotionCanBeginDrag,
                                                        // NSTextField
                                                        LookinAttrSec_NSTextField_BezelStyle,
                                                        LookinAttrSec_NSTextField_Bordered,
                                                        LookinAttrSec_NSTextField_TextColor,
                                                        LookinAttrSec_NSTextField_Placeholder,
                                                        LookinAttrSec_NSTextField_LineBreakStrategy,
                                                        LookinAttrSec_NSTextField_PreferredMaxLayoutWidth,
                                                        // NSTextView
                                                        LookinAttrSec_NSTextView_String,
                                                        LookinAttrSec_NSTextView_Basic,
                                                        LookinAttrSec_NSTextView_Font,
                                                        LookinAttrSec_NSTextView_TextColor,
                                                        LookinAttrSec_NSTextView_Alignment,
                                                        LookinAttrSec_NSTextView_ContainerInset,
                                                        LookinAttrSec_NSTextView_BaseWritingDirection,
                                                        LookinAttrSec_NSTextView_Size,
                                                        LookinAttrSec_NSTextView_Resizable,
                                                        // NSVisualEffectView
                                                        LookinAttrSec_NSVisualEffectView_Material,
                                                        LookinAttrSec_NSVisualEffectView_InteriorBackgroundStyle,
                                                        LookinAttrSec_NSVisualEffectView_BlendingMode,
                                                        LookinAttrSec_NSVisualEffectView_State,
                                                        LookinAttrSec_NSVisualEffectView_Emphasized,
                                                        // NSStackView
                                                        LookinAttrSec_NSStackView_Orientation,
                                                        LookinAttrSec_NSStackView_EdgeInsets,
                                                        LookinAttrSec_NSStackView_DetachesHiddenViews,
                                                        LookinAttrSec_NSStackView_Distribution,
                                                        LookinAttrSec_NSStackView_Alignment,
                                                        LookinAttrSec_NSStackView_Spacing,
                                                        // NSSlider
                                                        LookinAttrSec_NSSlider_SliderType,
                                                        LookinAttrSec_NSSlider_Range,
                                                        LookinAttrSec_NSSlider_TickMark,
                                                        LookinAttrSec_NSSlider_Misc,
                                                        // NSProgressIndicator
                                                        LookinAttrSec_NSProgressIndicator_Style,
                                                        LookinAttrSec_NSProgressIndicator_Range,
                                                        LookinAttrSec_NSProgressIndicator_Misc,
                                                        // NSSegmentedControl
                                                        LookinAttrSec_NSSegmentedControl_SegmentCount,
                                                        LookinAttrSec_NSSegmentedControl_Selection,
                                                        LookinAttrSec_NSSegmentedControl_Style,
                                                        LookinAttrSec_NSSegmentedControl_Colors,
                                                        // NSPopUpButton
                                                        LookinAttrSec_NSPopUpButton_Behavior,
                                                        LookinAttrSec_NSPopUpButton_Selection,
                                                        LookinAttrSec_NSPopUpButton_Items,
                                                        // NSComboBox
                                                        LookinAttrSec_NSComboBox_Items,
                                                        LookinAttrSec_NSComboBox_Misc,
                                                        // NSStepper
                                                        LookinAttrSec_NSStepper_Range,
                                                        LookinAttrSec_NSStepper_Misc,
                                                        // NSColorWell
                                                        LookinAttrSec_NSColorWell_Color,
                                                        LookinAttrSec_NSColorWell_Misc,
                                                        // NSSwitch
                                                        LookinAttrSec_NSSwitch_State,
                                                        // NSDatePicker
                                                        LookinAttrSec_NSDatePicker_Style,
                                                        LookinAttrSec_NSDatePicker_Range,
                                                        LookinAttrSec_NSDatePicker_Misc,
                                                        // NSLevelIndicator
                                                        LookinAttrSec_NSLevelIndicator_Style,
                                                        LookinAttrSec_NSLevelIndicator_Range,
                                                        LookinAttrSec_NSLevelIndicator_TickMark,
                                                        // NSOutlineView
                                                        LookinAttrSec_NSOutlineView_Indentation,
                                                        LookinAttrSec_NSOutlineView_Misc,
                                                        // NSCollectionView
                                                        LookinAttrSec_NSCollectionView_Selection,
                                                        LookinAttrSec_NSCollectionView_Info,
                                                        LookinAttrSec_NSCollectionView_Colors,
                                                        // NSBox
                                                        LookinAttrSec_NSBox_Type,
                                                        LookinAttrSec_NSBox_Title,
                                                        LookinAttrSec_NSBox_Appearance,
                                                        LookinAttrSec_NSBox_Metrics,
                                                        // NSSplitView
                                                        LookinAttrSec_NSSplitView_Orientation,
                                                        LookinAttrSec_NSSplitView_Style,
                                                        LookinAttrSec_NSSplitView_Misc,
                                                        // NSTabView
                                                        LookinAttrSec_NSTabView_Type,
                                                        LookinAttrSec_NSTabView_Misc,
                                                        LookinAttrSec_NSTabView_Info,
                                                        // NSGridView
                                                        LookinAttrSec_NSGridView_Dimensions,
                                                        LookinAttrSec_NSGridView_Spacing,
                                                        LookinAttrSec_NSGridView_Placement,
                                                        // UIWindowScene
                                                        LookinAttrSec_UIWindowScene_State,
                                                        LookinAttrSec_UIWindowScene_Title,
                                                        LookinAttrSec_UIWindowScene_Orientation,
                                                        LookinAttrSec_UIWindowScene_Windows,
                                                        LookinAttrSec_UIWindowScene_Screen,
                                                        LookinAttrSec_UIWindowScene_StatusBar,
                                                        LookinAttrSec_UIWindowScene_Traits,
                                                        LookinAttrSec_UIWindowScene_Session,
                                                        // UITraitCollection
                                                        LookinAttrSec_UITraitCollection_Appearance,
                                                        LookinAttrSec_UITraitCollection_SizeClass,
                                                        LookinAttrSec_UITraitCollection_Display,
                                                        LookinAttrSec_UITraitCollection_Device,
                                                        LookinAttrSec_UITraitCollection_Layout,
                                                        LookinAttrSec_UITraitCollection_Content,

        ];
        targetSet = [NSSet setWithArray:array];
    });
    return targetSet;
}

- (void)reset {
}

@end
