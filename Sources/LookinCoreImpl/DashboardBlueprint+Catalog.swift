//
//  DashboardBlueprint+Catalog.swift
//  LookinCore
//
//  The blueprint: every attribute group the dashboard knows, in display
//  order, and the groups both platforms list.
//  Each group lists its sections and each section its attributes, in display
//  order; DashboardBlueprintCatalog.swift explains the entry types and how the
//  lookup tables are derived. A section or attribute without `on:` is on the
//  platforms of the group or section it belongs to.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation

    extension DashboardBlueprintTables {
        /// Every group, in display order. `groupIDs()` lists the ones on the
        /// platform this code runs on; titles and attribute information cover
        /// every group, since the macOS Host shows iOS data.
        static let catalog: [BlueprintGroup] = [
            classGroup,
            relationGroup,
            layoutGroup,
            autoLayoutGroup,
            viewLayerGroup,
            uiStackViewGroup,
            uiVisualEffectViewGroup,
            uiImageViewGroup,
            uiLabelGroup,
            uiControlGroup,
            uiButtonGroup,
            uiScrollViewGroup,
            uiTableViewGroup,
            uiTextViewGroup,
            uiTextFieldGroup,
            uiSliderGroup,
            uiStepperGroup,
            uiSwitchGroup,
            uiSegmentedControlGroup,
            uiProgressViewGroup,
            uiActivityIndicatorViewGroup,
            uiPageControlGroup,
            uiDatePickerGroup,
            uiColorWellGroup,
            uiRefreshControlGroup,
            uiPickerViewGroup,
            uiCalendarViewGroup,
            uiPasteControlGroup,
            uiWindowSceneGroup,
            uiTraitCollectionGroup,
            nsImageViewGroup,
            nsControlGroup,
            nsButtonGroup,
            nsScrollViewGroup,
            nsTableViewGroup,
            nsTextViewGroup,
            nsTextFieldGroup,
            nsVisualEffectViewGroup,
            nsStackViewGroup,
            nsWindowGroup,
            nsSliderGroup,
            nsProgressIndicatorGroup,
            nsSegmentedControlGroup,
            nsPopUpButtonGroup,
            nsComboBoxGroup,
            nsStepperGroup,
            nsColorWellGroup,
            nsSwitchGroup,
            nsDatePickerGroup,
            nsLevelIndicatorGroup,
            nsOutlineViewGroup,
            nsCollectionViewGroup,
            nsBoxGroup,
            nsSplitViewGroup,
            nsTabViewGroup,
            nsGridViewGroup,
            nsCellGroup,
            layoutGuideGroup,
        ]

        #if canImport(UIKit)
            static let viewLayerGroupTitle = "CALayer / UIView"
        #else
            static let viewLayerGroupTitle = "CALayer / NSView"
        #endif

        static let classGroup = BlueprintGroup(LookinAttrGroup_Class, title: "Class", on: .all, sections: [
            BlueprintSection(LookinAttrSec_Class_Class, attributes: [
                BlueprintAttribute(LookinAttr_Class_Class_Class, AttributeInfo(className: "CALayer", getterString: "lks_relatedClassChainList", setterString: "", typeIfObj: .customObj)),
                BlueprintAttribute(LookinAttr_Class_Class_ImagePaths, AttributeInfo(className: "CALayer", getterString: "lks_relatedClassChainImagePaths", setterString: "", typeIfObj: .customObj)),
            ]),
        ])

        static let relationGroup = BlueprintGroup(LookinAttrGroup_Relation, title: "Relation", on: .all, sections: [
            BlueprintSection(LookinAttrSec_Relation_Relation, attributes: [
                BlueprintAttribute(LookinAttr_Relation_Relation_Relation, AttributeInfo(className: "CALayer", getterString: "lks_selfRelation", setterString: "", typeIfObj: .customObj, hideIfNil: true)),
            ]),
        ])

        static let layoutGroup = BlueprintGroup(LookinAttrGroup_Layout, title: "Layout", on: .all, sections: [
            BlueprintSection(LookinAttrSec_Layout_Frame, title: "Frame", attributes: [
                BlueprintAttribute(LookinAttr_Layout_Frame_Frame, AttributeInfo(className: "CALayer", fullTitle: "Frame", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_Layout_Bounds, title: "Bounds", attributes: [
                BlueprintAttribute(LookinAttr_Layout_Bounds_Bounds, AttributeInfo(className: "CALayer", fullTitle: "Bounds", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_Layout_SafeArea, title: "SafeArea", attributes: [
                BlueprintAttribute(LookinAttr_Layout_SafeArea_SafeArea, AttributeInfo(className: viewClassName, fullTitle: "SafeAreaInsets", setterString: "", osVersion: 11)),
            ]),
            BlueprintSection(LookinAttrSec_Layout_Position, title: "Position", attributes: [
                BlueprintAttribute(LookinAttr_Layout_Position_Position, AttributeInfo(className: "CALayer", fullTitle: "Position", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_Layout_AnchorPoint, title: "AnchorPoint", attributes: [
                BlueprintAttribute(LookinAttr_Layout_AnchorPoint_AnchorPoint, AttributeInfo(className: "CALayer", fullTitle: "AnchorPoint", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_Layout_CoordinateSpace, title: "CoordinateSpace", attributes: [
                // Lives under the Layout group rather than the UIWindowScene group,
                // because it is the only geometry a scene exposes — it has no frame.
                BlueprintAttribute(LookinAttr_Layout_CoordinateSpace_CoordinateSpace, AttributeInfo(className: "UIWindowScene", fullTitle: "CoordinateSpace", getterString: "lks_coordinateSpaceBounds", setterString: "", patch: false)),
            ]),
        ])

        static let autoLayoutGroup = BlueprintGroup(LookinAttrGroup_AutoLayout, title: "AutoLayout", on: .all, sections: [
            BlueprintSection(LookinAttrSec_AutoLayout_Constraints, attributes: [
                BlueprintAttribute(LookinAttr_AutoLayout_Constraints_Constraints, AttributeInfo(className: viewClassName, getterString: "lks_constraints", setterString: "", typeIfObj: .customObj, hideIfNil: true)),
            ]),
            BlueprintSection(LookinAttrSec_AutoLayout_IntrinsicSize, title: "IntrinsicSize", attributes: [
                BlueprintAttribute(LookinAttr_AutoLayout_IntrinsicSize_Size, AttributeInfo(className: viewClassName, fullTitle: "IntrinsicContentSize", setterString: "")),
            ]),
            BlueprintSection(LookinAttrSec_AutoLayout_Hugging, title: "HuggingPriority", attributes: [
                BlueprintAttribute(LookinAttr_AutoLayout_Hugging_Hor, AttributeInfo(className: viewClassName, fullTitle: "ContentHuggingPriority(Horizontal)", briefTitle: "H", getterString: "lks_horizontalContentHuggingPriority", setterString: "setLks_horizontalContentHuggingPriority:", patch: true)),
                BlueprintAttribute(LookinAttr_AutoLayout_Hugging_Ver, AttributeInfo(className: viewClassName, fullTitle: "ContentHuggingPriority(Vertical)", briefTitle: "V", getterString: "lks_verticalContentHuggingPriority", setterString: "setLks_verticalContentHuggingPriority:", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_AutoLayout_Resistance, title: "ResistancePriority", attributes: [
                BlueprintAttribute(LookinAttr_AutoLayout_Resistance_Hor, AttributeInfo(className: viewClassName, fullTitle: "ContentCompressionResistancePriority(Horizontal)", briefTitle: "H", getterString: "lks_horizontalContentCompressionResistancePriority", setterString: "setLks_horizontalContentCompressionResistancePriority:", patch: true)),
                BlueprintAttribute(LookinAttr_AutoLayout_Resistance_Ver, AttributeInfo(className: viewClassName, fullTitle: "ContentCompressionResistancePriority(Vertical)", briefTitle: "V", getterString: "lks_verticalContentCompressionResistancePriority", setterString: "setLks_verticalContentCompressionResistancePriority:", patch: true)),
            ]),
        ])

        static let viewLayerGroup = BlueprintGroup(LookinAttrGroup_ViewLayer, title: viewLayerGroupTitle, on: .all, sections: [
            BlueprintSection(LookinAttrSec_ViewLayer_Visibility, attributes: [
                BlueprintAttribute(LookinAttr_ViewLayer_Visibility_Hidden, AttributeInfo(className: "CALayer", fullTitle: "Hidden", getterString: "isHidden", patch: true)),
                BlueprintAttribute(LookinAttr_ViewLayer_Visibility_Opacity, AttributeInfo(className: "CALayer", fullTitle: "Opacity / Alpha", getterString: "opacity", setterString: "setOpacity:", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_ViewLayer_InterationAndMasks, attributes: [
                BlueprintAttribute(LookinAttr_ViewLayer_InterationAndMasks_Interaction, on: .uiKit, AttributeInfo(className: "UIView", fullTitle: "UserInteractionEnabled", getterString: "isUserInteractionEnabled", patch: false)),
                BlueprintAttribute(LookinAttr_ViewLayer_InterationAndMasks_MasksToBounds, AttributeInfo(className: "CALayer", fullTitle: "MasksToBounds / ClipsToBounds", briefTitle: "MasksToBounds", getterString: "masksToBounds", setterString: "setMasksToBounds:", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_ViewLayer_BgColor, title: "BackgroundColor", attributes: [
                BlueprintAttribute(LookinAttr_ViewLayer_BgColor_BgColor, AttributeInfo(className: "CALayer", fullTitle: "BackgroundColor", getterString: "lks_backgroundColor", setterString: "setLks_backgroundColor:", typeIfObj: .uiColor, patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_ViewLayer_Border, title: "Border", attributes: [
                BlueprintAttribute(LookinAttr_ViewLayer_Border_Color, AttributeInfo(className: "CALayer", fullTitle: "BorderColor", getterString: "lks_borderColor", setterString: "setLks_borderColor:", typeIfObj: .uiColor, patch: true)),
                BlueprintAttribute(LookinAttr_ViewLayer_Border_Width, AttributeInfo(className: "CALayer", fullTitle: "BorderWidth", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_ViewLayer_Corner, title: "CornerRadius", attributes: [
                BlueprintAttribute(LookinAttr_ViewLayer_Corner_Radius, AttributeInfo(className: "CALayer", fullTitle: "CornerRadius", briefTitle: "", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_ViewLayer_Shadow, title: "Shadow", attributes: [
                BlueprintAttribute(LookinAttr_ViewLayer_Shadow_Color, AttributeInfo(className: "CALayer", fullTitle: "ShadowColor", getterString: "lks_shadowColor", setterString: "setLks_shadowColor:", typeIfObj: .uiColor, patch: true)),
                BlueprintAttribute(LookinAttr_ViewLayer_Shadow_Opacity, AttributeInfo(className: "CALayer", fullTitle: "ShadowOpacity", briefTitle: "Opacity", patch: true)),
                BlueprintAttribute(LookinAttr_ViewLayer_Shadow_Radius, AttributeInfo(className: "CALayer", fullTitle: "ShadowRadius", briefTitle: "Radius", patch: true)),
                BlueprintAttribute(LookinAttr_ViewLayer_Shadow_OffsetW, AttributeInfo(className: "CALayer", fullTitle: "ShadowOffsetWidth", briefTitle: "OffsetW", getterString: "lks_shadowOffsetWidth", setterString: "setLks_shadowOffsetWidth:", patch: true)),
                BlueprintAttribute(LookinAttr_ViewLayer_Shadow_OffsetH, AttributeInfo(className: "CALayer", fullTitle: "ShadowOffsetHeight", briefTitle: "OffsetH", getterString: "lks_shadowOffsetHeight", setterString: "setLks_shadowOffsetHeight:", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_ViewLayer_Tag, title: "Tag", attributes: [
                BlueprintAttribute(LookinAttr_ViewLayer_Tag_Tag, AttributeInfo(className: viewClassName, fullTitle: "Tag", briefTitle: "", patch: false)),
            ]),
            BlueprintSection(LookinAttrSec_ViewLayer_ContentMode, title: "ContentMode", on: .uiKit, attributes: [
                BlueprintAttribute(LookinAttr_ViewLayer_ContentMode_Mode, AttributeInfo(className: "UIView", fullTitle: "ContentMode", enumList: "UIViewContentMode", patch: true)),
            ]),
            BlueprintSection(LookinAttrSec_ViewLayer_TintColor, title: "TintColor", on: .uiKit, attributes: [
                BlueprintAttribute(LookinAttr_ViewLayer_TintColor_Color, AttributeInfo(className: "UIView", fullTitle: "TintColor", typeIfObj: .uiColor, patch: true)),
                BlueprintAttribute(LookinAttr_ViewLayer_TintColor_Mode, AttributeInfo(className: "UIView", fullTitle: "TintAdjustmentMode", enumList: "UIViewTintAdjustmentMode", patch: true)),
            ]),
        ])

        static let layoutGuideGroup = BlueprintGroup(LookinAttrGroup_LayoutGuide, title: "LayoutGuide", on: .all, sections: [
            BlueprintSection(LookinAttrSec_LayoutGuide_Identifier, title: "Identifier", attributes: [
                BlueprintAttribute(LookinAttr_LayoutGuide_Identifier_Identifier, AttributeInfo(className: layoutGuideClassName, fullTitle: "Identifier", getterString: "identifier", setterString: "", typeIfObj: .nsString, hideIfNil: true)),
            ]),
            BlueprintSection(LookinAttrSec_LayoutGuide_LayoutFrame, title: "LayoutFrame", attributes: [
                BlueprintAttribute(LookinAttr_LayoutGuide_LayoutFrame_LayoutFrame, AttributeInfo(className: layoutGuideClassName, fullTitle: "LayoutFrame", getterString: "lks_layoutFrame", setterString: "")),
            ]),
            BlueprintSection(LookinAttrSec_LayoutGuide_OwningView, title: "OwningView", attributes: [
                BlueprintAttribute(LookinAttr_LayoutGuide_OwningView_OwningView, AttributeInfo(className: layoutGuideClassName, fullTitle: "OwningView", getterString: "lks_owningViewDescription", setterString: "", typeIfObj: .nsString, hideIfNil: true)),
            ]),
        ])
    }

#endif
