#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION || TARGET_OS_MAC)
//
//  LKS_AttrGroupsMaker.m
//  LookinServer
//
//  Created by Li Kai on 2019/6/6.
//  https://lookin.work
//

#import "LKS_AttrGroupsMaker.h"
#import "LookinAttributesGroup.h"
#import "LookinAttributesSection.h"
#import "LookinAttribute.h"
#import "LookinDashboardBlueprint.h"
#import "CALayer+LookinServer.h"

#if TARGET_OS_OSX
#import "Color+Lookin.h"
#import "NSObject+LookinServer.h"
#import "LookinIvarTrace.h"

@implementation LKS_AttrGroupsMaker

+ (LookinAttribute *)_attributeWithID:(LookinAttrIdentifier)identifier type:(LookinAttrType)type value:(id)value {
    LookinAttribute *attribute = [LookinAttribute new];
    attribute.identifier = identifier;
    attribute.attrType = type;
    attribute.value = value;
    return attribute;
}

+ (LookinAttributesSection *)_sectionWithID:(LookinAttrSectionIdentifier)identifier attrs:(NSArray<LookinAttribute *> *)attrs {
    NSArray<LookinAttribute *> *validAttrs = [attrs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(LookinAttribute *attribute, NSDictionary<NSString *, id> *bindings) {
        return attribute != nil;
    }]];
    if (!validAttrs.count) {
        return nil;
    }
    LookinAttributesSection *section = [LookinAttributesSection new];
    section.identifier = identifier;
    section.attributes = validAttrs;
    return section;
}

+ (LookinAttributesGroup *)_groupWithID:(LookinAttrGroupIdentifier)identifier sections:(NSArray<LookinAttributesSection *> *)sections {
    NSArray<LookinAttributesSection *> *validSections = [sections filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(LookinAttributesSection *section, NSDictionary<NSString *, id> *bindings) {
        return section != nil;
    }]];
    if (!validSections.count) {
        return nil;
    }
    LookinAttributesGroup *group = [LookinAttributesGroup new];
    group.identifier = identifier;
    group.attrSections = validSections;
    return group;
}

+ (NSArray<NSString *> *)_classChainForObject:(id)object endingClass:(Class)endingClass {
    NSMutableArray<NSString *> *completedList = [NSMutableArray arrayWithArray:[object lks_classChainList] ?: @[]];
    NSString *endingClassName = NSStringFromClass(endingClass);
    NSUInteger endingIdx = [completedList indexOfObject:endingClassName];
    if (endingIdx != NSNotFound) {
        return [completedList subarrayWithRange:NSMakeRange(0, endingIdx + 1)];
    }
    return completedList.copy;
}

+ (NSArray<NSString *> *)_relationForObject:(id)object {
    NSMutableArray<NSString *> *array = [NSMutableArray array];
    if ([object lks_specialTrace].length) {
        [array addObject:[object lks_specialTrace]];
    }
    for (LookinIvarTrace *trace in [object lks_ivarTraces] ?: @[]) {
        [array addObject:[NSString stringWithFormat:@"(%@ *) -> %@", trace.hostClassName, trace.ivarName]];
    }
    return array.count ? array.copy : nil;
}

+ (NSNumber *)_boolNumber:(BOOL)value {
    return @(value);
}

+ (NSValue *)_rectValue:(CGRect)rect {
    return [NSValue valueWithRect:rect];
}

+ (NSValue *)_pointValue:(CGPoint)point {
    return [NSValue valueWithPoint:point];
}

+ (NSValue *)_sizeValue:(CGSize)size {
    return [NSValue valueWithSize:size];
}

+ (NSValue *)_insetsValue:(NSEdgeInsets)insets {
    return [NSValue valueWithEdgeInsets:insets];
}

+ (NSArray<NSArray<NSString *> *> *)_classValueForObject:(id)object endingClass:(Class)endingClass {
    return @[[self _classChainForObject:object endingClass:endingClass]];
}

+ (NSColor *)_viewBackgroundColor:(NSView *)view {
    if (view.layer) {
        return view.layer.lks_backgroundColor;
    }
    return nil;
}

+ (NSArray<LookinAttribute *> *)_fontAttrsForObject:(id)object nameIdentifier:(LookinAttrIdentifier)nameID sizeIdentifier:(LookinAttrIdentifier)sizeID {
    NSFont *font = nil;
    if ([object isKindOfClass:[NSTextField class]]) {
        font = ((NSTextField *)object).font;
    } else if ([object isKindOfClass:[NSTextView class]]) {
        font = ((NSTextView *)object).font;
    }
    if (!font) {
        return @[];
    }
    return @[
        [self _attributeWithID:nameID type:LookinAttrTypeNSString value:font.fontName ?: @""],
        [self _attributeWithID:sizeID type:LookinAttrTypeDouble value:@(font.pointSize)]
    ];
}

+ (LookinAttributesGroup *)_baseClassGroupForObject:(id)object endingClass:(Class)endingClass {
    return [self _groupWithID:LookinAttrGroup_Class sections:@[
        [self _sectionWithID:LookinAttrSec_Class_Class attrs:@[
            [self _attributeWithID:LookinAttr_Class_Class_Class type:LookinAttrTypeCustomObj value:[self _classValueForObject:object endingClass:endingClass]]
        ]]
    ]];
}

+ (LookinAttributesGroup *)_baseRelationGroupForObject:(id)object {
    return [self _groupWithID:LookinAttrGroup_Relation sections:@[
        [self _sectionWithID:LookinAttrSec_Relation_Relation attrs:@[
            [self _attributeWithID:LookinAttr_Relation_Relation_Relation type:LookinAttrTypeCustomObj value:[self _relationForObject:object]]
        ]]
    ]];
}

+ (NSArray<LookinAttributesGroup *> *)attrGroupsForLayer:(CALayer *)layer {
    if (!layer) {
        return @[];
    }

    NSMutableArray<LookinAttributesGroup *> *groups = [NSMutableArray array];

    LookinAttributesGroup *classGroup = [self _groupWithID:LookinAttrGroup_Class sections:@[
        [self _sectionWithID:LookinAttrSec_Class_Class attrs:@[
            [self _attributeWithID:LookinAttr_Class_Class_Class type:LookinAttrTypeCustomObj value:[layer lks_relatedClassChainList]]
        ]]
    ]];
    if (classGroup) {
        [groups addObject:classGroup];
    }

    NSArray<NSString *> *relation = [layer lks_selfRelation];
    LookinAttributesGroup *relationGroup = [self _groupWithID:LookinAttrGroup_Relation sections:@[
        [self _sectionWithID:LookinAttrSec_Relation_Relation attrs:@[
            [self _attributeWithID:LookinAttr_Relation_Relation_Relation type:LookinAttrTypeCustomObj value:relation]
        ]]
    ]];
    if (relationGroup) {
        [groups addObject:relationGroup];
    }

    LookinAttributesGroup *layoutGroup = [self _groupWithID:LookinAttrGroup_Layout sections:@[
        [self _sectionWithID:LookinAttrSec_Layout_Frame attrs:@[
            [self _attributeWithID:LookinAttr_Layout_Frame_Frame type:LookinAttrTypeCGRect value:[NSValue valueWithRect:layer.frame]]
        ]],
        [self _sectionWithID:LookinAttrSec_Layout_Bounds attrs:@[
            [self _attributeWithID:LookinAttr_Layout_Bounds_Bounds type:LookinAttrTypeCGRect value:[NSValue valueWithRect:layer.bounds]]
        ]],
        [self _sectionWithID:LookinAttrSec_Layout_Position attrs:@[
            [self _attributeWithID:LookinAttr_Layout_Position_Position type:LookinAttrTypeCGPoint value:[NSValue valueWithPoint:layer.position]]
        ]],
        [self _sectionWithID:LookinAttrSec_Layout_AnchorPoint attrs:@[
            [self _attributeWithID:LookinAttr_Layout_AnchorPoint_AnchorPoint type:LookinAttrTypeCGPoint value:[NSValue valueWithPoint:layer.anchorPoint]]
        ]]
    ]];
    if (layoutGroup) {
        [groups addObject:layoutGroup];
    }

    NSColor *backgroundColor = layer.lks_backgroundColor;
    NSColor *borderColor = layer.lks_borderColor;
    NSColor *shadowColor = layer.lks_shadowColor;
    LookinAttributesGroup *viewLayerGroup = [self _groupWithID:LookinAttrGroup_ViewLayer sections:@[
        [self _sectionWithID:LookinAttrSec_ViewLayer_Visibility attrs:@[
            [self _attributeWithID:LookinAttr_ViewLayer_Visibility_Hidden type:LookinAttrTypeBOOL value:@(layer.hidden)],
            [self _attributeWithID:LookinAttr_ViewLayer_Visibility_Opacity type:LookinAttrTypeFloat value:@(layer.opacity)]
        ]],
        [self _sectionWithID:LookinAttrSec_ViewLayer_InterationAndMasks attrs:@[
            [self _attributeWithID:LookinAttr_ViewLayer_InterationAndMasks_MasksToBounds type:LookinAttrTypeBOOL value:@(layer.masksToBounds)]
        ]],
        [self _sectionWithID:LookinAttrSec_ViewLayer_Corner attrs:@[
            [self _attributeWithID:LookinAttr_ViewLayer_Corner_Radius type:LookinAttrTypeDouble value:@(layer.cornerRadius)]
        ]],
        [self _sectionWithID:LookinAttrSec_ViewLayer_BgColor attrs:@[
            [self _attributeWithID:LookinAttr_ViewLayer_BgColor_BgColor type:LookinAttrTypeUIColor value:backgroundColor ? backgroundColor.lookin_rgbaComponents : nil]
        ]],
        [self _sectionWithID:LookinAttrSec_ViewLayer_Border attrs:@[
            [self _attributeWithID:LookinAttr_ViewLayer_Border_Color type:LookinAttrTypeUIColor value:borderColor ? borderColor.lookin_rgbaComponents : nil],
            [self _attributeWithID:LookinAttr_ViewLayer_Border_Width type:LookinAttrTypeDouble value:@(layer.borderWidth)]
        ]],
        [self _sectionWithID:LookinAttrSec_ViewLayer_Shadow attrs:@[
            [self _attributeWithID:LookinAttr_ViewLayer_Shadow_Color type:LookinAttrTypeUIColor value:shadowColor ? shadowColor.lookin_rgbaComponents : nil],
            [self _attributeWithID:LookinAttr_ViewLayer_Shadow_Opacity type:LookinAttrTypeFloat value:@(layer.shadowOpacity)],
            [self _attributeWithID:LookinAttr_ViewLayer_Shadow_Radius type:LookinAttrTypeDouble value:@(layer.shadowRadius)],
            [self _attributeWithID:LookinAttr_ViewLayer_Shadow_OffsetW type:LookinAttrTypeDouble value:@(layer.shadowOffset.width)],
            [self _attributeWithID:LookinAttr_ViewLayer_Shadow_OffsetH type:LookinAttrTypeDouble value:@(layer.shadowOffset.height)]
        ]]
    ]];
    if (viewLayerGroup) {
        [groups addObject:viewLayerGroup];
    }

    return groups.copy;
}

+ (NSArray<LookinAttributesGroup *> *)attrGroupsForView:(NSView *)view {
    if (!view) {
        return @[];
    }

    NSMutableArray<LookinAttributesGroup *> *groups = [NSMutableArray array];

    LookinAttributesGroup *classGroup = [self _baseClassGroupForObject:view endingClass:NSView.class];
    if (classGroup) {
        [groups addObject:classGroup];
    }

    LookinAttributesGroup *relationGroup = [self _baseRelationGroupForObject:view];
    if (relationGroup) {
        [groups addObject:relationGroup];
    }

    NSEdgeInsets safeAreaInsets = NSEdgeInsetsZero;
    if (@available(macOS 11.0, *)) {
        safeAreaInsets = view.safeAreaInsets;
    }
    LookinAttributesGroup *layoutGroup = [self _groupWithID:LookinAttrGroup_Layout sections:@[
        [self _sectionWithID:LookinAttrSec_Layout_Frame attrs:@[
            [self _attributeWithID:LookinAttr_Layout_Frame_Frame type:LookinAttrTypeCGRect value:[self _rectValue:view.frame]]
        ]],
        [self _sectionWithID:LookinAttrSec_Layout_Bounds attrs:@[
            [self _attributeWithID:LookinAttr_Layout_Bounds_Bounds type:LookinAttrTypeCGRect value:[self _rectValue:view.bounds]]
        ]],
        [self _sectionWithID:LookinAttrSec_Layout_SafeArea attrs:@[
            [self _attributeWithID:LookinAttr_Layout_SafeArea_SafeArea type:LookinAttrTypeUIEdgeInsets value:[self _insetsValue:safeAreaInsets]]
        ]],
        [self _sectionWithID:LookinAttrSec_Layout_Position attrs:@[
            [self _attributeWithID:LookinAttr_Layout_Position_Position type:LookinAttrTypeCGPoint value:[self _pointValue:view.layer.position]]
        ]],
        [self _sectionWithID:LookinAttrSec_Layout_AnchorPoint attrs:@[
            [self _attributeWithID:LookinAttr_Layout_AnchorPoint_AnchorPoint type:LookinAttrTypeCGPoint value:[self _pointValue:view.layer.anchorPoint]]
        ]],
    ]];
    if (layoutGroup) {
        [groups addObject:layoutGroup];
    }

    LookinAttributesGroup *autoLayoutGroup = [self _groupWithID:LookinAttrGroup_AutoLayout sections:@[
        [self _sectionWithID:LookinAttrSec_AutoLayout_Constraints attrs:@[
            [self _attributeWithID:LookinAttr_AutoLayout_Constraints_Constraints type:LookinAttrTypeCustomObj value:[view lks_constraints]]
        ]],
        [self _sectionWithID:LookinAttrSec_AutoLayout_IntrinsicSize attrs:@[
            [self _attributeWithID:LookinAttr_AutoLayout_IntrinsicSize_Size type:LookinAttrTypeCGSize value:[self _sizeValue:view.intrinsicContentSize]]
        ]],
        [self _sectionWithID:LookinAttrSec_AutoLayout_Hugging attrs:@[
            [self _attributeWithID:LookinAttr_AutoLayout_Hugging_Hor type:LookinAttrTypeFloat value:@(view.lks_horizontalContentHuggingPriority)],
            [self _attributeWithID:LookinAttr_AutoLayout_Hugging_Ver type:LookinAttrTypeFloat value:@(view.lks_verticalContentHuggingPriority)]
        ]],
        [self _sectionWithID:LookinAttrSec_AutoLayout_Resistance attrs:@[
            [self _attributeWithID:LookinAttr_AutoLayout_Resistance_Hor type:LookinAttrTypeFloat value:@(view.lks_horizontalContentCompressionResistancePriority)],
            [self _attributeWithID:LookinAttr_AutoLayout_Resistance_Ver type:LookinAttrTypeFloat value:@(view.lks_verticalContentCompressionResistancePriority)]
        ]]
    ]];
    if (autoLayoutGroup) {
        [groups addObject:autoLayoutGroup];
    }

    NSColor *backgroundColor = [self _viewBackgroundColor:view];
    NSColor *borderColor = view.layer.lks_borderColor;
    NSColor *shadowColor = view.layer.lks_shadowColor;
    BOOL enabled = ![view isKindOfClass:[NSControl class]] || ((NSControl *)view).enabled;
    LookinAttributesGroup *viewLayerGroup = [self _groupWithID:LookinAttrGroup_ViewLayer sections:@[
        [self _sectionWithID:LookinAttrSec_ViewLayer_Visibility attrs:@[
            [self _attributeWithID:LookinAttr_ViewLayer_Visibility_Hidden type:LookinAttrTypeBOOL value:@(view.hidden)],
            [self _attributeWithID:LookinAttr_ViewLayer_Visibility_Opacity type:LookinAttrTypeFloat value:@(view.layer ? view.layer.opacity : 1)]
        ]],
        [self _sectionWithID:LookinAttrSec_ViewLayer_InterationAndMasks attrs:@[
            [self _attributeWithID:LookinAttr_ViewLayer_InterationAndMasks_Interaction type:LookinAttrTypeBOOL value:[self _boolNumber:enabled]],
            [self _attributeWithID:LookinAttr_ViewLayer_InterationAndMasks_MasksToBounds type:LookinAttrTypeBOOL value:@(view.layer ? view.layer.masksToBounds : NO)]
        ]],
        [self _sectionWithID:LookinAttrSec_ViewLayer_Corner attrs:@[
            [self _attributeWithID:LookinAttr_ViewLayer_Corner_Radius type:LookinAttrTypeDouble value:@(view.layer ? view.layer.cornerRadius : 0)]
        ]],
        [self _sectionWithID:LookinAttrSec_ViewLayer_BgColor attrs:@[
            [self _attributeWithID:LookinAttr_ViewLayer_BgColor_BgColor type:LookinAttrTypeUIColor value:backgroundColor ? backgroundColor.lookin_rgbaComponents : nil]
        ]],
        [self _sectionWithID:LookinAttrSec_ViewLayer_Border attrs:@[
            [self _attributeWithID:LookinAttr_ViewLayer_Border_Color type:LookinAttrTypeUIColor value:borderColor ? borderColor.lookin_rgbaComponents : nil],
            [self _attributeWithID:LookinAttr_ViewLayer_Border_Width type:LookinAttrTypeDouble value:@(view.layer ? view.layer.borderWidth : 0)]
        ]],
        [self _sectionWithID:LookinAttrSec_ViewLayer_Shadow attrs:@[
            [self _attributeWithID:LookinAttr_ViewLayer_Shadow_Color type:LookinAttrTypeUIColor value:shadowColor ? shadowColor.lookin_rgbaComponents : nil],
            [self _attributeWithID:LookinAttr_ViewLayer_Shadow_Opacity type:LookinAttrTypeFloat value:@(view.layer ? view.layer.shadowOpacity : 0)],
            [self _attributeWithID:LookinAttr_ViewLayer_Shadow_Radius type:LookinAttrTypeDouble value:@(view.layer ? view.layer.shadowRadius : 0)],
            [self _attributeWithID:LookinAttr_ViewLayer_Shadow_OffsetW type:LookinAttrTypeDouble value:@(view.layer ? view.layer.shadowOffset.width : 0)],
            [self _attributeWithID:LookinAttr_ViewLayer_Shadow_OffsetH type:LookinAttrTypeDouble value:@(view.layer ? view.layer.shadowOffset.height : 0)]
        ]],
        [self _sectionWithID:LookinAttrSec_ViewLayer_ContentMode attrs:@[
            [self _attributeWithID:LookinAttr_ViewLayer_ContentMode_Mode type:LookinAttrTypeEnumInt value:@(view.contentMode)]
        ]],
        [self _sectionWithID:LookinAttrSec_ViewLayer_TintColor attrs:@[
            [self _attributeWithID:LookinAttr_ViewLayer_TintColor_Color type:LookinAttrTypeUIColor value:view.tintColor ? view.tintColor.lookin_rgbaComponents : nil],
            [self _attributeWithID:LookinAttr_ViewLayer_TintColor_Mode type:LookinAttrTypeEnumInt value:@(view.tintAdjustmentMode)]
        ]],
        [self _sectionWithID:LookinAttrSec_ViewLayer_Tag attrs:@[
            [self _attributeWithID:LookinAttr_ViewLayer_Tag_Tag type:LookinAttrTypeLong value:@(view.tag)]
        ]],
    ]];
    if (viewLayerGroup) {
        [groups addObject:viewLayerGroup];
    }

    if ([view isKindOfClass:[NSStackView class]]) {
        NSStackView *stackView = (NSStackView *)view;
        LookinAttributesGroup *stackGroup = [self _groupWithID:LookinAttrGroup_UIStackView sections:@[
            [self _sectionWithID:LookinAttrSec_UIStackView_Axis attrs:@[
                [self _attributeWithID:LookinAttr_UIStackView_Axis_Axis type:LookinAttrTypeEnumInt value:@(stackView.orientation)]
            ]],
            [self _sectionWithID:LookinAttrSec_UIStackView_Distribution attrs:@[
                [self _attributeWithID:LookinAttr_UIStackView_Distribution_Distribution type:LookinAttrTypeEnumInt value:@(stackView.distribution)]
            ]],
            [self _sectionWithID:LookinAttrSec_UIStackView_Alignment attrs:@[
                [self _attributeWithID:LookinAttr_UIStackView_Alignment_Alignment type:LookinAttrTypeEnumInt value:@(stackView.alignment)]
            ]],
            [self _sectionWithID:LookinAttrSec_UIStackView_Spacing attrs:@[
                [self _attributeWithID:LookinAttr_UIStackView_Spacing_Spacing type:LookinAttrTypeDouble value:@(stackView.spacing)]
            ]]
        ]];
        if (stackGroup) {
            [groups addObject:stackGroup];
        }
    }

    if ([view isKindOfClass:[NSVisualEffectView class]]) {
        NSVisualEffectView *effectView = (NSVisualEffectView *)view;
        LookinAttributesGroup *effectGroup = [self _groupWithID:LookinAttrGroup_UIVisualEffectView sections:@[
            [self _sectionWithID:LookinAttrSec_UIVisualEffectView_Style attrs:@[
                [self _attributeWithID:LookinAttr_UIVisualEffectView_Style_Style type:LookinAttrTypeEnumInt value:effectView.lks_blurEffectStyleNumber]
            ]],
            [self _sectionWithID:LookinAttrSec_UIVisualEffectView_QMUIForegroundColor attrs:@[
                [self _attributeWithID:LookinAttr_UIVisualEffectView_QMUIForegroundColor_Color type:LookinAttrTypeUIColor value:effectView.tintColor ? effectView.tintColor.lookin_rgbaComponents : nil]
            ]]
        ]];
        if (effectGroup) {
            [groups addObject:effectGroup];
        }
    }

    if ([view isKindOfClass:[NSImageView class]]) {
        NSImageView *imageView = (NSImageView *)view;
        LookinAttributesGroup *imageGroup = [self _groupWithID:LookinAttrGroup_UIImageView sections:@[
            [self _sectionWithID:LookinAttrSec_UIImageView_Name attrs:@[
                [self _attributeWithID:LookinAttr_UIImageView_Name_Name type:LookinAttrTypeNSString value:[imageView lks_imageSourceName]]
            ]],
            [self _sectionWithID:LookinAttrSec_UIImageView_Open attrs:@[
                [self _attributeWithID:LookinAttr_UIImageView_Open_Open type:LookinAttrTypeCustomObj value:[imageView lks_imageViewOidIfHasImage]]
            ]]
        ]];
        if (imageGroup) {
            [groups addObject:imageGroup];
        }
    }

    if ([view isKindOfClass:[NSTextField class]]) {
        NSTextField *textField = (NSTextField *)view;
        BOOL editable = textField.isEditable;
        LookinAttributesGroup *textGroup = [self _groupWithID:(editable ? LookinAttrGroup_UITextField : LookinAttrGroup_UILabel) sections:(editable ? @[
            [self _sectionWithID:LookinAttrSec_UITextField_Text attrs:@[
                [self _attributeWithID:LookinAttr_UITextField_Text_Text type:LookinAttrTypeNSString value:textField.stringValue ?: @""]
            ]],
            [self _sectionWithID:LookinAttrSec_UITextField_Placeholder attrs:@[
                [self _attributeWithID:LookinAttr_UITextField_Placeholder_Placeholder type:LookinAttrTypeNSString value:textField.placeholderString]
            ]],
            [self _sectionWithID:LookinAttrSec_UITextField_Font attrs:[self _fontAttrsForObject:textField nameIdentifier:LookinAttr_UITextField_Font_Name sizeIdentifier:LookinAttr_UITextField_Font_Size]],
            [self _sectionWithID:LookinAttrSec_UITextField_TextColor attrs:@[
                [self _attributeWithID:LookinAttr_UITextField_TextColor_Color type:LookinAttrTypeUIColor value:textField.textColor ? textField.textColor.lookin_rgbaComponents : nil]
            ]],
            [self _sectionWithID:LookinAttrSec_UITextField_Alignment attrs:@[
                [self _attributeWithID:LookinAttr_UITextField_Alignment_Alignment type:LookinAttrTypeEnumInt value:@(textField.alignment)]
            ]],
            [self _sectionWithID:LookinAttrSec_UITextField_Clears attrs:@[
                [self _attributeWithID:LookinAttr_UITextField_Clears_ClearsOnBeginEditing type:LookinAttrTypeBOOL value:@(textField.clearsOnBeginEditing)]
            ]],
            [self _sectionWithID:LookinAttrSec_UITextField_CanAdjustFont attrs:@[
                [self _attributeWithID:LookinAttr_UITextField_CanAdjustFont_CanAdjustFont type:LookinAttrTypeBOOL value:@(textField.adjustsFontSizeToFitWidth)]
            ]],
            [self _sectionWithID:LookinAttrSec_UITextField_ClearButtonMode attrs:@[
                [self _attributeWithID:LookinAttr_UITextField_ClearButtonMode_Mode type:LookinAttrTypeEnumInt value:@(textField.clearButtonMode)]
            ]]
        ] : @[
            [self _sectionWithID:LookinAttrSec_UILabel_Text attrs:@[
                [self _attributeWithID:LookinAttr_UILabel_Text_Text type:LookinAttrTypeNSString value:textField.stringValue ?: @""]
            ]],
            [self _sectionWithID:LookinAttrSec_UILabel_Font attrs:[self _fontAttrsForObject:textField nameIdentifier:LookinAttr_UILabel_Font_Name sizeIdentifier:LookinAttr_UILabel_Font_Size]],
            [self _sectionWithID:LookinAttrSec_UILabel_NumberOfLines attrs:@[
                [self _attributeWithID:LookinAttr_UILabel_NumberOfLines_NumberOfLines type:LookinAttrTypeLong value:@(textField.numberOfLines)]
            ]],
            [self _sectionWithID:LookinAttrSec_UILabel_TextColor attrs:@[
                [self _attributeWithID:LookinAttr_UILabel_TextColor_Color type:LookinAttrTypeUIColor value:textField.textColor ? textField.textColor.lookin_rgbaComponents : nil]
            ]],
            [self _sectionWithID:LookinAttrSec_UILabel_Alignment attrs:@[
                [self _attributeWithID:LookinAttr_UILabel_Alignment_Alignment type:LookinAttrTypeEnumInt value:@(textField.alignment)]
            ]],
            [self _sectionWithID:LookinAttrSec_UILabel_BreakMode attrs:@[
                [self _attributeWithID:LookinAttr_UILabel_BreakMode_Mode type:LookinAttrTypeEnumInt value:@(textField.lineBreakMode)]
            ]],
            [self _sectionWithID:LookinAttrSec_UILabel_CanAdjustFont attrs:@[
                [self _attributeWithID:LookinAttr_UILabel_CanAdjustFont_CanAdjustFont type:LookinAttrTypeBOOL value:@(textField.adjustsFontSizeToFitWidth)]
            ]]
        ])];
        if (textGroup) {
            [groups addObject:textGroup];
        }
    }

    if ([view isKindOfClass:[NSTextView class]]) {
        NSTextView *textView = (NSTextView *)view;
        LookinAttributesGroup *textViewGroup = [self _groupWithID:LookinAttrGroup_UITextView sections:@[
            [self _sectionWithID:LookinAttrSec_UITextView_Basic attrs:@[
                [self _attributeWithID:LookinAttr_UITextView_Basic_Editable type:LookinAttrTypeBOOL value:@(textView.editable)],
                [self _attributeWithID:LookinAttr_UITextView_Basic_Selectable type:LookinAttrTypeBOOL value:@(textView.selectable)]
            ]],
            [self _sectionWithID:LookinAttrSec_UITextView_Text attrs:@[
                [self _attributeWithID:LookinAttr_UITextView_Text_Text type:LookinAttrTypeNSString value:textView.string ?: @""]
            ]],
            [self _sectionWithID:LookinAttrSec_UITextView_Font attrs:[self _fontAttrsForObject:textView nameIdentifier:LookinAttr_UITextView_Font_Name sizeIdentifier:LookinAttr_UITextView_Font_Size]],
            [self _sectionWithID:LookinAttrSec_UITextView_TextColor attrs:@[
                [self _attributeWithID:LookinAttr_UITextView_TextColor_Color type:LookinAttrTypeUIColor value:textView.textColor ? textView.textColor.lookin_rgbaComponents : nil]
            ]],
            [self _sectionWithID:LookinAttrSec_UITextView_Alignment attrs:@[
                [self _attributeWithID:LookinAttr_UITextView_Alignment_Alignment type:LookinAttrTypeEnumInt value:@(textView.alignment)]
            ]],
            [self _sectionWithID:LookinAttrSec_UITextView_ContainerInset attrs:@[
                [self _attributeWithID:LookinAttr_UITextView_ContainerInset_Inset type:LookinAttrTypeUIEdgeInsets value:[self _insetsValue:NSEdgeInsetsMake(textView.textContainerInset.height, textView.textContainerInset.width, textView.textContainerInset.height, textView.textContainerInset.width)]]
            ]]
        ]];
        if (textViewGroup) {
            [groups addObject:textViewGroup];
        }
    }

    if ([view isKindOfClass:[NSControl class]]) {
        NSControl *control = (NSControl *)view;
        LookinAttributesGroup *controlGroup = [self _groupWithID:LookinAttrGroup_UIControl sections:@[
            [self _sectionWithID:LookinAttrSec_UIControl_EnabledSelected attrs:@[
                [self _attributeWithID:LookinAttr_UIControl_EnabledSelected_Enabled type:LookinAttrTypeBOOL value:@(control.enabled)],
                [self _attributeWithID:LookinAttr_UIControl_EnabledSelected_Selected type:LookinAttrTypeBOOL value:@(control.selected)]
            ]],
            [self _sectionWithID:LookinAttrSec_UIControl_QMUIOutsideEdge attrs:@[
                [self _attributeWithID:LookinAttr_UIControl_QMUIOutsideEdge_Edge type:LookinAttrTypeUIEdgeInsets value:[self _insetsValue:control.qmui_outsideEdge]]
            ]],
            [self _sectionWithID:LookinAttrSec_UIControl_VerAlignment attrs:@[
                [self _attributeWithID:LookinAttr_UIControl_VerAlignment_Alignment type:LookinAttrTypeEnumInt value:@(control.contentVerticalAlignment)]
            ]],
            [self _sectionWithID:LookinAttrSec_UIControl_HorAlignment attrs:@[
                [self _attributeWithID:LookinAttr_UIControl_HorAlignment_Alignment type:LookinAttrTypeEnumInt value:@(control.contentHorizontalAlignment)]
            ]]
        ]];
        if (controlGroup) {
            [groups addObject:controlGroup];
        }
    }

    if ([view isKindOfClass:[NSButton class]]) {
        NSButton *button = (NSButton *)view;
        LookinAttributesGroup *buttonGroup = [self _groupWithID:LookinAttrGroup_UIButton sections:@[
            [self _sectionWithID:LookinAttrSec_UIButton_ContentInsets attrs:@[
                [self _attributeWithID:LookinAttr_UIButton_ContentInsets_Insets type:LookinAttrTypeUIEdgeInsets value:[self _insetsValue:button.contentEdgeInsets]]
            ]],
            [self _sectionWithID:LookinAttrSec_UIButton_TitleInsets attrs:@[
                [self _attributeWithID:LookinAttr_UIButton_TitleInsets_Insets type:LookinAttrTypeUIEdgeInsets value:[self _insetsValue:button.titleEdgeInsets]]
            ]],
            [self _sectionWithID:LookinAttrSec_UIButton_ImageInsets attrs:@[
                [self _attributeWithID:LookinAttr_UIButton_ImageInsets_Insets type:LookinAttrTypeUIEdgeInsets value:[self _insetsValue:button.imageEdgeInsets]]
            ]]
        ]];
        if (buttonGroup) {
            [groups addObject:buttonGroup];
        }
    }

    if ([view isKindOfClass:[NSScrollView class]]) {
        NSScrollView *scrollView = (NSScrollView *)view;
        NSView *documentView = scrollView.documentView;
        NSEdgeInsets contentInsets = scrollView.contentInsets;
        NSEdgeInsets indicatorInsets = NSEdgeInsetsZero;
        if ([scrollView respondsToSelector:@selector(scrollerInsets)]) {
            indicatorInsets = scrollView.scrollerInsets;
        }
        BOOL allowHorBounce = scrollView.horizontalScrollElasticity != NSScrollElasticityNone;
        BOOL allowVerBounce = scrollView.verticalScrollElasticity != NSScrollElasticityNone;
        LookinAttributesGroup *scrollGroup = [self _groupWithID:LookinAttrGroup_UIScrollView sections:@[
            [self _sectionWithID:LookinAttrSec_UIScrollView_ContentInset attrs:@[
                [self _attributeWithID:LookinAttr_UIScrollView_ContentInset_Inset type:LookinAttrTypeUIEdgeInsets value:[self _insetsValue:contentInsets]]
            ]],
            [self _sectionWithID:LookinAttrSec_UIScrollView_AdjustedInset attrs:@[
                [self _attributeWithID:LookinAttr_UIScrollView_AdjustedInset_Inset type:LookinAttrTypeUIEdgeInsets value:[self _insetsValue:contentInsets]]
            ]],
            [self _sectionWithID:LookinAttrSec_UIScrollView_QMUIInitialInset attrs:@[
                [self _attributeWithID:LookinAttr_UIScrollView_QMUIInitialInset_Inset type:LookinAttrTypeUIEdgeInsets value:[self _insetsValue:contentInsets]]
            ]],
            [self _sectionWithID:LookinAttrSec_UIScrollView_IndicatorInset attrs:@[
                [self _attributeWithID:LookinAttr_UIScrollView_IndicatorInset_Inset type:LookinAttrTypeUIEdgeInsets value:[self _insetsValue:indicatorInsets]]
            ]],
            [self _sectionWithID:LookinAttrSec_UIScrollView_Offset attrs:@[
                [self _attributeWithID:LookinAttr_UIScrollView_Offset_Offset type:LookinAttrTypeCGPoint value:[self _pointValue:scrollView.contentView.bounds.origin]]
            ]],
            [self _sectionWithID:LookinAttrSec_UIScrollView_ContentSize attrs:@[
                [self _attributeWithID:LookinAttr_UIScrollView_ContentSize_Size type:LookinAttrTypeCGSize value:[self _sizeValue:scrollView.contentSize]]
            ]],
            [self _sectionWithID:LookinAttrSec_UIScrollView_Behavior attrs:@[
                [self _attributeWithID:LookinAttr_UIScrollView_Behavior_Behavior type:LookinAttrTypeEnumInt value:@(scrollView.contentInsetAdjustmentBehavior)]
            ]],
            [self _sectionWithID:LookinAttrSec_UIScrollView_ShowsIndicator attrs:@[
                [self _attributeWithID:LookinAttr_UIScrollView_ShowsIndicator_Hor type:LookinAttrTypeBOOL value:@(scrollView.hasHorizontalScroller)],
                [self _attributeWithID:LookinAttr_UIScrollView_ShowsIndicator_Ver type:LookinAttrTypeBOOL value:@(scrollView.hasVerticalScroller)]
            ]],
            [self _sectionWithID:LookinAttrSec_UIScrollView_Bounce attrs:@[
                [self _attributeWithID:LookinAttr_UIScrollView_Bounce_Hor type:LookinAttrTypeBOOL value:@(allowHorBounce)],
                [self _attributeWithID:LookinAttr_UIScrollView_Bounce_Ver type:LookinAttrTypeBOOL value:@(allowVerBounce)]
            ]],
            [self _sectionWithID:LookinAttrSec_UIScrollView_ScrollPaging attrs:@[
                [self _attributeWithID:LookinAttr_UIScrollView_ScrollPaging_ScrollEnabled type:LookinAttrTypeBOOL value:@(YES)],
                [self _attributeWithID:LookinAttr_UIScrollView_ScrollPaging_PagingEnabled type:LookinAttrTypeBOOL value:@(NO)]
            ]],
            [self _sectionWithID:LookinAttrSec_UIScrollView_ContentTouches attrs:@[
                [self _attributeWithID:LookinAttr_UIScrollView_ContentTouches_Delay type:LookinAttrTypeBOOL value:@(scrollView.delaysContentTouches)],
                [self _attributeWithID:LookinAttr_UIScrollView_ContentTouches_CanCancel type:LookinAttrTypeBOOL value:@(scrollView.canCancelContentTouches)]
            ]],
            [self _sectionWithID:LookinAttrSec_UIScrollView_Zoom attrs:@[
                [self _attributeWithID:LookinAttr_UIScrollView_Zoom_Bounce type:LookinAttrTypeBOOL value:@(scrollView.bouncesZoom)],
                [self _attributeWithID:LookinAttr_UIScrollView_Zoom_Scale type:LookinAttrTypeDouble value:@(scrollView.zoomScale)],
                [self _attributeWithID:LookinAttr_UIScrollView_Zoom_MinScale type:LookinAttrTypeDouble value:@(scrollView.minMagnification)],
                [self _attributeWithID:LookinAttr_UIScrollView_Zoom_MaxScale type:LookinAttrTypeDouble value:@(scrollView.maxMagnification)]
            ]]
        ]];
        if (scrollGroup) {
            [groups addObject:scrollGroup];
        }
    }

    if ([view isKindOfClass:[NSTableView class]]) {
        NSTableView *tableView = (NSTableView *)view;
        LookinAttributesGroup *tableGroup = [self _groupWithID:LookinAttrGroup_UITableView sections:@[
            [self _sectionWithID:LookinAttrSec_UITableView_Style attrs:@[
                [self _attributeWithID:LookinAttr_UITableView_Style_Style type:LookinAttrTypeEnumInt value:@(tableView.style)]
            ]],
            [self _sectionWithID:LookinAttrSec_UITableView_SectionsNumber attrs:@[
                [self _attributeWithID:LookinAttr_UITableView_SectionsNumber_Number type:LookinAttrTypeLong value:@(tableView.numberOfSections)]
            ]],
            [self _sectionWithID:LookinAttrSec_UITableView_RowsNumber attrs:@[
                [self _attributeWithID:LookinAttr_UITableView_RowsNumber_Number type:LookinAttrTypeLong value:@(tableView.numberOfRows)]
            ]],
            [self _sectionWithID:LookinAttrSec_UITableView_SeparatorStyle attrs:@[
                [self _attributeWithID:LookinAttr_UITableView_SeparatorStyle_Style type:LookinAttrTypeEnumInt value:@(tableView.separatorStyle)]
            ]],
            [self _sectionWithID:LookinAttrSec_UITableView_SeparatorColor attrs:@[
                [self _attributeWithID:LookinAttr_UITableView_SeparatorColor_Color type:LookinAttrTypeUIColor value:tableView.separatorColor ? tableView.separatorColor.lookin_rgbaComponents : nil]
            ]],
            [self _sectionWithID:LookinAttrSec_UITableView_SeparatorInset attrs:@[
                [self _attributeWithID:LookinAttr_UITableView_SeparatorInset_Inset type:LookinAttrTypeUIEdgeInsets value:[self _insetsValue:tableView.separatorInset]]
            ]]
        ]];
        if (tableGroup) {
            [groups addObject:tableGroup];
        }
    }

    return groups.copy;
}

+ (NSArray<LookinAttributesGroup *> *)attrGroupsForWindow:(NSWindow *)window {
    if (!window) {
        return @[];
    }

    NSMutableArray<LookinAttributesGroup *> *groups = [NSMutableArray array];

    LookinAttributesGroup *classGroup = [self _baseClassGroupForObject:window endingClass:NSWindow.class];
    if (classGroup) {
        [groups addObject:classGroup];
    }

    LookinAttributesGroup *relationGroup = [self _baseRelationGroupForObject:window];
    if (relationGroup) {
        [groups addObject:relationGroup];
    }

    LookinAttributesGroup *layoutGroup = [self _groupWithID:LookinAttrGroup_Layout sections:@[
        [self _sectionWithID:LookinAttrSec_Layout_Frame attrs:@[
            [self _attributeWithID:LookinAttr_Layout_Frame_Frame type:LookinAttrTypeCGRect value:[self _rectValue:window.frame]]
        ]],
        [self _sectionWithID:LookinAttrSec_Layout_Bounds attrs:@[
            [self _attributeWithID:LookinAttr_Layout_Bounds_Bounds type:LookinAttrTypeCGRect value:[self _rectValue:window.contentView.bounds]]
        ]]
    ]];
    if (layoutGroup) {
        [groups addObject:layoutGroup];
    }

    LookinAttributesGroup *viewLayerGroup = [self _groupWithID:LookinAttrGroup_ViewLayer sections:@[
        [self _sectionWithID:LookinAttrSec_ViewLayer_Visibility attrs:@[
            [self _attributeWithID:LookinAttr_ViewLayer_Visibility_Hidden type:LookinAttrTypeBOOL value:@(!window.visible)],
            [self _attributeWithID:LookinAttr_ViewLayer_Visibility_Opacity type:LookinAttrTypeFloat value:@(window.alphaValue)]
        ]]
    ]];
    if (viewLayerGroup) {
        [groups addObject:viewLayerGroup];
    }

    return groups.copy;
}

@end

#else

#import "NSArray+Lookin.h"
#import "LookinIvarTrace.h"
#import "UIColor+LookinServer.h"
#import "LookinServerDefines.h"

@implementation LKS_AttrGroupsMaker

+ (NSArray<LookinAttributesGroup *> *)attrGroupsForLayer:(CALayer *)layer {
    if (!layer) {
        NSAssert(NO, @"");
        return nil;
    }
    NSArray<LookinAttributesGroup *> *groups = [[LookinDashboardBlueprint groupIDs] lookin_map:^id(NSUInteger idx, LookinAttrGroupIdentifier groupID) {
        LookinAttributesGroup *group = [LookinAttributesGroup new];
        group.identifier = groupID;

        NSArray<LookinAttrSectionIdentifier> *secIDs = [LookinDashboardBlueprint sectionIDsForGroupID:groupID];
        group.attrSections = [secIDs lookin_map:^id(NSUInteger idx, LookinAttrSectionIdentifier secID) {
            LookinAttributesSection *sec = [LookinAttributesSection new];
            sec.identifier = secID;
            
            NSArray<LookinAttrIdentifier> *attrIDs = [LookinDashboardBlueprint attrIDsForSectionID:secID];
            sec.attributes = [attrIDs lookin_map:^id(NSUInteger idx, LookinAttrIdentifier attrID) {
                NSInteger minAvailableVersion = [LookinDashboardBlueprint minAvailableOSVersionWithAttrID:attrID];
                if (minAvailableVersion > 0 && (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion < minAvailableVersion)) {
                    return nil;
                }
                
                id targetObj = nil;
                if ([LookinDashboardBlueprint isUIViewPropertyWithAttrID:attrID]) {
                    targetObj = layer.lks_hostView;
                } else {
                    targetObj = layer;
                }
                
                if (targetObj) {
                    Class targetClass = NSClassFromString([LookinDashboardBlueprint classNameWithAttrID:attrID]);
                    if (![targetObj isKindOfClass:targetClass]) {
                        return nil;
                    }
                    
                    LookinAttribute *attr = [self _attributeWithIdentifer:attrID targetObject:targetObj];
                    return attr;
                } else {
                    return nil;
                }
            }];
            
            if (sec.attributes.count) {
                return sec;
            } else {
                return nil;
            }
        }];
        
        if ([groupID isEqualToString:LookinAttrGroup_AutoLayout]) {
            BOOL hasConstraits = [group.attrSections lookin_any:^BOOL(LookinAttributesSection *obj) {
                return [obj.identifier isEqualToString:LookinAttrSec_AutoLayout_Constraints];
            }];
            if (!hasConstraits) {
                return nil;
            }
        }
        
        if (group.attrSections.count) {
            return group;
        } else {
            return nil;
        }
    }];
    
    return groups;
}

+ (LookinAttribute *)_attributeWithIdentifer:(LookinAttrIdentifier)identifier targetObject:(id)target {
    if (!target) {
        NSAssert(NO, @"");
        return nil;
    }
    
    LookinAttribute *attribute = [LookinAttribute new];
    attribute.identifier = identifier;
    
    SEL getter = [LookinDashboardBlueprint getterWithAttrID:identifier];
    if (!getter) {
        NSAssert(NO, @"");
        return nil;
    }
    if (![target respondsToSelector:getter]) {
        return nil;
    }
    NSMethodSignature *signature = [target methodSignatureForSelector:getter];
    if (signature.numberOfArguments > 2) {
        NSAssert(NO, @"getter 不可以有参数");
        return nil;
    }
    if (strcmp([signature methodReturnType], @encode(void)) == 0) {
        NSAssert(NO, @"getter 返回值不能为 void");
        return nil;
    }
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
    invocation.selector = getter;
    [invocation invoke];
    
    const char *returnType = [signature methodReturnType];
    
    if (strcmp(returnType, @encode(char)) == 0) {
        char targetValue;
        [invocation getReturnValue:&targetValue];
        attribute.attrType = LookinAttrTypeChar;
        attribute.value = @(targetValue);
    } else if (strcmp(returnType, @encode(int)) == 0) {
        int targetValue;
        [invocation getReturnValue:&targetValue];
        attribute.value = @(targetValue);
        attribute.attrType = [LookinDashboardBlueprint enumListNameWithAttrID:identifier] ? LookinAttrTypeEnumInt : LookinAttrTypeInt;
    } else if (strcmp(returnType, @encode(short)) == 0) {
        short targetValue;
        [invocation getReturnValue:&targetValue];
        attribute.attrType = LookinAttrTypeShort;
        attribute.value = @(targetValue);
    } else if (strcmp(returnType, @encode(long)) == 0) {
        long targetValue;
        [invocation getReturnValue:&targetValue];
        attribute.value = @(targetValue);
        attribute.attrType = [LookinDashboardBlueprint enumListNameWithAttrID:identifier] ? LookinAttrTypeEnumLong : LookinAttrTypeLong;
    } else if (strcmp(returnType, @encode(long long)) == 0) {
        long long targetValue;
        [invocation getReturnValue:&targetValue];
        attribute.attrType = LookinAttrTypeLongLong;
        attribute.value = @(targetValue);
    } else if (strcmp(returnType, @encode(unsigned char)) == 0) {
        unsigned char targetValue;
        [invocation getReturnValue:&targetValue];
        attribute.attrType = LookinAttrTypeUnsignedChar;
        attribute.value = @(targetValue);
    } else if (strcmp(returnType, @encode(unsigned int)) == 0) {
        unsigned int targetValue;
        [invocation getReturnValue:&targetValue];
        attribute.attrType = LookinAttrTypeUnsignedInt;
        attribute.value = @(targetValue);
    } else if (strcmp(returnType, @encode(unsigned short)) == 0) {
        unsigned short targetValue;
        [invocation getReturnValue:&targetValue];
        attribute.attrType = LookinAttrTypeUnsignedShort;
        attribute.value = @(targetValue);
    } else if (strcmp(returnType, @encode(unsigned long)) == 0) {
        unsigned long targetValue;
        [invocation getReturnValue:&targetValue];
        attribute.attrType = LookinAttrTypeUnsignedLong;
        attribute.value = @(targetValue);
    } else if (strcmp(returnType, @encode(unsigned long long)) == 0) {
        unsigned long long targetValue;
        [invocation getReturnValue:&targetValue];
        attribute.attrType = LookinAttrTypeUnsignedLongLong;
        attribute.value = @(targetValue);
    } else if (strcmp(returnType, @encode(float)) == 0) {
        float targetValue;
        [invocation getReturnValue:&targetValue];
        attribute.attrType = LookinAttrTypeFloat;
        attribute.value = @(targetValue);
    } else if (strcmp(returnType, @encode(double)) == 0) {
        double targetValue;
        [invocation getReturnValue:&targetValue];
        attribute.attrType = LookinAttrTypeDouble;
        attribute.value = @(targetValue);
    } else if (strcmp(returnType, @encode(BOOL)) == 0) {
        BOOL targetValue;
        [invocation getReturnValue:&targetValue];
        attribute.attrType = LookinAttrTypeBOOL;
        attribute.value = @(targetValue);
    } else if (strcmp(returnType, @encode(CGPoint)) == 0) {
        CGPoint targetValue;
        [invocation getReturnValue:&targetValue];
        attribute.attrType = LookinAttrTypeCGPoint;
        attribute.value = [NSValue valueWithCGPoint:targetValue];
    } else if (strcmp(returnType, @encode(CGSize)) == 0) {
        CGSize targetValue;
        [invocation getReturnValue:&targetValue];
        attribute.attrType = LookinAttrTypeCGSize;
        attribute.value = [NSValue valueWithCGSize:targetValue];
    } else if (strcmp(returnType, @encode(CGRect)) == 0) {
        CGRect targetValue;
        [invocation getReturnValue:&targetValue];
        attribute.attrType = LookinAttrTypeCGRect;
        attribute.value = [NSValue valueWithCGRect:targetValue];
    } else {
        NSString *argTypeString = [[NSString alloc] lookin_safeInitWithUTF8String:returnType];
        if ([argTypeString hasPrefix:@"@"]) {
            __unsafe_unretained id returnObjValue;
            [invocation getReturnValue:&returnObjValue];
            if (!returnObjValue && [LookinDashboardBlueprint hideIfNilWithAttrID:identifier]) {
                return nil;
            }
            attribute.attrType = [LookinDashboardBlueprint objectAttrTypeWithAttrID:identifier];
            if (attribute.attrType == LookinAttrTypeUIColor) {
                attribute.value = returnObjValue ? [returnObjValue lks_rgbaComponents] : nil;
            } else {
                attribute.value = returnObjValue;
            }
        } else {
            return nil;
        }
    }
    
    return attribute;
}

@end

#endif

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
