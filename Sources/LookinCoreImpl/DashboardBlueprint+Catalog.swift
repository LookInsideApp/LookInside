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
            caLayerGroup,
            uiViewGroup,
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
            uiCollectionViewGroup,
            uiCollectionReusableViewGroup,
            uiTableViewCellGroup,
            uiTableViewHeaderFooterViewGroup,
            uiNavigationBarGroup,
            uiTabBarGroup,
            uiToolbarGroup,
            uiSearchBarGroup,
            uiInputViewGroup,
            uiContentUnavailableViewGroup,
            uiBackgroundExtensionViewGroup,
            uiWindowGroup,
            uiWindowSceneGroup,
            uiTraitCollectionGroup,
            nsViewGroup,
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
            nsClipViewGroup,
            nsScrollerGroup,
            nsBrowserGroup,
            nsMatrixGroup,
            nsPathControlGroup,
            nsRuleEditorGroup,
            nsSearchFieldGroup,
            nsComboButtonGroup,
            nsGlassEffectViewGroup,
            nsBackgroundExtensionViewGroup,
            nsRulerViewGroup,
            nsTableCellViewGroup,
            nsTableRowViewGroup,
            nsTableHeaderViewGroup,
            nsTextInsertionIndicatorGroup,
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

        static let caLayerGroup = BlueprintGroup(LookinAttrGroup_CALayer, title: "CALayer", on: .all, sections: [
            BlueprintSection(LookinAttrSec_CALayer_ZPosition, title: "ZPosition", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_ZPosition_ZPosition, AttributeInfo(className: "CALayer", fullTitle: "ZPosition", getterString: "zPosition", setterString: "setZPosition:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_AnchorPointZ, title: "AnchorPointZ", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_AnchorPointZ_AnchorPointZ, AttributeInfo(className: "CALayer", fullTitle: "AnchorPointZ", getterString: "anchorPointZ", setterString: "setAnchorPointZ:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_Transform, title: "Transform", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_Transform_Transform, AttributeInfo(className: "CALayer", fullTitle: "Transform", getterString: "transform", setterString: "", revision: 1, presentation: .structure)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_Behavior, title: "Behavior", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_Behavior_DoubleSided, AttributeInfo(className: "CALayer", fullTitle: "DoubleSided", getterString: "isDoubleSided", setterString: "setDoubleSided:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_Behavior_GeometryFlipped, AttributeInfo(className: "CALayer", fullTitle: "GeometryFlipped", getterString: "isGeometryFlipped", setterString: "setGeometryFlipped:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_Behavior_Opaque, AttributeInfo(className: "CALayer", fullTitle: "Opaque", getterString: "isOpaque", setterString: "setOpaque:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_Behavior_NeedsDisplayOnBoundsChange, AttributeInfo(className: "CALayer", fullTitle: "NeedsDisplayOnBoundsChange", getterString: "needsDisplayOnBoundsChange", setterString: "setNeedsDisplayOnBoundsChange:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_Behavior_DrawsAsynchronously, AttributeInfo(className: "CALayer", fullTitle: "DrawsAsynchronously", getterString: "drawsAsynchronously", setterString: "setDrawsAsynchronously:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_Behavior_AllowsEdgeAntialiasing, AttributeInfo(className: "CALayer", fullTitle: "AllowsEdgeAntialiasing", getterString: "allowsEdgeAntialiasing", setterString: "setAllowsEdgeAntialiasing:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_Behavior_AllowsGroupOpacity, AttributeInfo(className: "CALayer", fullTitle: "AllowsGroupOpacity", getterString: "allowsGroupOpacity", setterString: "setAllowsGroupOpacity:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_Behavior_ShouldRasterize, AttributeInfo(className: "CALayer", fullTitle: "ShouldRasterize", getterString: "shouldRasterize", setterString: "setShouldRasterize:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_SublayerTransform, title: "SublayerTransform", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_SublayerTransform_SublayerTransform, AttributeInfo(className: "CALayer", fullTitle: "SublayerTransform", getterString: "sublayerTransform", setterString: "", revision: 1, presentation: .structure)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_ContentsRect, title: "ContentsRect", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_ContentsRect_ContentsRect, AttributeInfo(className: "CALayer", fullTitle: "ContentsRect", getterString: "contentsRect", setterString: "setContentsRect:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_ContentsGravity, title: "ContentsGravity", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_ContentsGravity_ContentsGravity, AttributeInfo(className: "CALayer", fullTitle: "ContentsGravity", getterString: "contentsGravity", setterString: "", typeIfObj: .nsString, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_ContentsScale, title: "ContentsScale", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_ContentsScale_ContentsScale, AttributeInfo(className: "CALayer", fullTitle: "ContentsScale", getterString: "contentsScale", setterString: "setContentsScale:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_ContentsCenter, title: "ContentsCenter", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_ContentsCenter_ContentsCenter, AttributeInfo(className: "CALayer", fullTitle: "ContentsCenter", getterString: "contentsCenter", setterString: "setContentsCenter:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_ContentsFormat, title: "ContentsFormat", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_ContentsFormat_ContentsFormat, AttributeInfo(className: "CALayer", fullTitle: "ContentsFormat", getterString: "contentsFormat", setterString: "", typeIfObj: .nsString, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_ToneMapMode, title: "ToneMapMode", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_ToneMapMode_ToneMapMode, AttributeInfo(className: "CALayer", fullTitle: "ToneMapMode", getterString: "toneMapMode", setterString: "", typeIfObj: .nsString, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_PreferredDynamicRange, title: "PreferredDynamicRange", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_PreferredDynamicRange_PreferredDynamicRange, AttributeInfo(className: "CALayer", fullTitle: "PreferredDynamicRange", getterString: "preferredDynamicRange", setterString: "", typeIfObj: .nsString, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_ContentsHeadroom, title: "ContentsHeadroom", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_ContentsHeadroom_ContentsHeadroom, AttributeInfo(className: "CALayer", fullTitle: "ContentsHeadroom", getterString: "contentsHeadroom", setterString: "setContentsHeadroom:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_MinificationFilter, title: "MinificationFilter", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_MinificationFilter_MinificationFilter, AttributeInfo(className: "CALayer", fullTitle: "MinificationFilter", getterString: "minificationFilter", setterString: "", typeIfObj: .nsString, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_MagnificationFilter, title: "MagnificationFilter", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_MagnificationFilter_MagnificationFilter, AttributeInfo(className: "CALayer", fullTitle: "MagnificationFilter", getterString: "magnificationFilter", setterString: "", typeIfObj: .nsString, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_MinificationFilterBias, title: "MinificationFilterBias", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_MinificationFilterBias_MinificationFilterBias, AttributeInfo(className: "CALayer", fullTitle: "MinificationFilterBias", getterString: "minificationFilterBias", setterString: "setMinificationFilterBias:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_MaskedCorners, title: "MaskedCorners", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_MaskedCorners_MaskedCorners, AttributeInfo(className: "CALayer", fullTitle: "MaskedCorners", getterString: "maskedCorners", setterString: "", revision: 1, presentation: .optionNames("CACornerMask"))),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_CornerCurve, title: "CornerCurve", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_CornerCurve_CornerCurve, AttributeInfo(className: "CALayer", fullTitle: "CornerCurve", getterString: "cornerCurve", setterString: "", typeIfObj: .nsString, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_RasterizationScale, title: "RasterizationScale", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_RasterizationScale_RasterizationScale, AttributeInfo(className: "CALayer", fullTitle: "RasterizationScale", getterString: "rasterizationScale", setterString: "setRasterizationScale:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_ShadowPath, title: "ShadowPath", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_ShadowPath_ShadowPath, AttributeInfo(className: "CALayer", fullTitle: "ShadowPath", getterString: "shadowPath", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.path))),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_Name, title: "Name", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_Name_Name, AttributeInfo(className: "CALayer", fullTitle: "Name", getterString: "name", setterString: "setName:", typeIfObj: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_VisibleRect, title: "VisibleRect", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_VisibleRect_VisibleRect, AttributeInfo(className: "CALayer", fullTitle: "VisibleRect", getterString: "visibleRect", setterString: "", revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_CAShapeLayer, title: "CAShapeLayer", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_CAShapeLayer_Path, AttributeInfo(className: "CAShapeLayer", fullTitle: "Path", getterString: "path", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.path))),
                BlueprintAttribute(LookinAttr_CALayer_CAShapeLayer_FillColor, AttributeInfo(className: "CAShapeLayer", fullTitle: "FillColor", getterString: "fillColor", setterString: "", revision: 1, presentation: .cgColor)),
                BlueprintAttribute(LookinAttr_CALayer_CAShapeLayer_FillRule, AttributeInfo(className: "CAShapeLayer", fullTitle: "FillRule", getterString: "fillRule", setterString: "", typeIfObj: .nsString, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAShapeLayer_StrokeColor, AttributeInfo(className: "CAShapeLayer", fullTitle: "StrokeColor", getterString: "strokeColor", setterString: "", revision: 1, presentation: .cgColor)),
                BlueprintAttribute(LookinAttr_CALayer_CAShapeLayer_StrokeStart, AttributeInfo(className: "CAShapeLayer", fullTitle: "StrokeStart", getterString: "strokeStart", setterString: "setStrokeStart:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAShapeLayer_StrokeEnd, AttributeInfo(className: "CAShapeLayer", fullTitle: "StrokeEnd", getterString: "strokeEnd", setterString: "setStrokeEnd:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAShapeLayer_LineWidth, AttributeInfo(className: "CAShapeLayer", fullTitle: "LineWidth", getterString: "lineWidth", setterString: "setLineWidth:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAShapeLayer_MiterLimit, AttributeInfo(className: "CAShapeLayer", fullTitle: "MiterLimit", getterString: "miterLimit", setterString: "setMiterLimit:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAShapeLayer_LineCap, AttributeInfo(className: "CAShapeLayer", fullTitle: "LineCap", getterString: "lineCap", setterString: "", typeIfObj: .nsString, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAShapeLayer_LineJoin, AttributeInfo(className: "CAShapeLayer", fullTitle: "LineJoin", getterString: "lineJoin", setterString: "", typeIfObj: .nsString, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAShapeLayer_LineDashPhase, AttributeInfo(className: "CAShapeLayer", fullTitle: "LineDashPhase", getterString: "lineDashPhase", setterString: "setLineDashPhase:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAShapeLayer_LineDashPattern, AttributeInfo(className: "CAShapeLayer", fullTitle: "LineDashPattern", getterString: "lineDashPattern", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_CAGradientLayer, title: "CAGradientLayer", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_CAGradientLayer_Colors, AttributeInfo(className: "CAGradientLayer", fullTitle: "Colors", getterString: "colors", setterString: "", revision: 1, presentation: .count)),
                BlueprintAttribute(LookinAttr_CALayer_CAGradientLayer_Locations, AttributeInfo(className: "CAGradientLayer", fullTitle: "Locations", getterString: "locations", setterString: "", revision: 1, presentation: .count)),
                BlueprintAttribute(LookinAttr_CALayer_CAGradientLayer_StartPoint, AttributeInfo(className: "CAGradientLayer", fullTitle: "StartPoint", getterString: "startPoint", setterString: "setStartPoint:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAGradientLayer_EndPoint, AttributeInfo(className: "CAGradientLayer", fullTitle: "EndPoint", getterString: "endPoint", setterString: "setEndPoint:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAGradientLayer_Type, AttributeInfo(className: "CAGradientLayer", fullTitle: "Type", getterString: "type", setterString: "", typeIfObj: .nsString, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_CATextLayer, title: "CATextLayer", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_CATextLayer_FontSize, AttributeInfo(className: "CATextLayer", fullTitle: "FontSize", getterString: "fontSize", setterString: "setFontSize:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CATextLayer_ForegroundColor, AttributeInfo(className: "CATextLayer", fullTitle: "ForegroundColor", getterString: "foregroundColor", setterString: "", revision: 1, presentation: .cgColor)),
                BlueprintAttribute(LookinAttr_CALayer_CATextLayer_Wrapped, AttributeInfo(className: "CATextLayer", fullTitle: "Wrapped", getterString: "isWrapped", setterString: "setWrapped:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CATextLayer_TruncationMode, AttributeInfo(className: "CATextLayer", fullTitle: "TruncationMode", getterString: "truncationMode", setterString: "", typeIfObj: .nsString, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CATextLayer_AlignmentMode, AttributeInfo(className: "CATextLayer", fullTitle: "AlignmentMode", getterString: "alignmentMode", setterString: "", typeIfObj: .nsString, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CATextLayer_AllowsFontSubpixelQuantization, AttributeInfo(className: "CATextLayer", fullTitle: "AllowsFontSubpixelQuantization", getterString: "allowsFontSubpixelQuantization", setterString: "setAllowsFontSubpixelQuantization:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_CAReplicatorLayer, title: "CAReplicatorLayer", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_CAReplicatorLayer_InstanceCount, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "InstanceCount", getterString: "instanceCount", setterString: "setInstanceCount:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAReplicatorLayer_PreservesDepth, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "PreservesDepth", getterString: "preservesDepth", setterString: "setPreservesDepth:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAReplicatorLayer_InstanceDelay, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "InstanceDelay", getterString: "instanceDelay", setterString: "setInstanceDelay:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAReplicatorLayer_InstanceTransform, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "InstanceTransform", getterString: "instanceTransform", setterString: "", revision: 1, presentation: .structure)),
                BlueprintAttribute(LookinAttr_CALayer_CAReplicatorLayer_InstanceColor, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "InstanceColor", getterString: "instanceColor", setterString: "", revision: 1, presentation: .cgColor)),
                BlueprintAttribute(LookinAttr_CALayer_CAReplicatorLayer_InstanceRedOffset, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "InstanceRedOffset", getterString: "instanceRedOffset", setterString: "setInstanceRedOffset:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAReplicatorLayer_InstanceGreenOffset, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "InstanceGreenOffset", getterString: "instanceGreenOffset", setterString: "setInstanceGreenOffset:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAReplicatorLayer_InstanceBlueOffset, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "InstanceBlueOffset", getterString: "instanceBlueOffset", setterString: "setInstanceBlueOffset:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAReplicatorLayer_InstanceAlphaOffset, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "InstanceAlphaOffset", getterString: "instanceAlphaOffset", setterString: "setInstanceAlphaOffset:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_CAEmitterLayer, title: "CAEmitterLayer", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_CAEmitterLayer_EmitterCells, AttributeInfo(className: "CAEmitterLayer", fullTitle: "EmitterCells", getterString: "emitterCells", setterString: "", revision: 1, presentation: .count)),
                BlueprintAttribute(LookinAttr_CALayer_CAEmitterLayer_BirthRate, AttributeInfo(className: "CAEmitterLayer", fullTitle: "BirthRate", getterString: "birthRate", setterString: "setBirthRate:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAEmitterLayer_Lifetime, AttributeInfo(className: "CAEmitterLayer", fullTitle: "Lifetime", getterString: "lifetime", setterString: "setLifetime:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAEmitterLayer_EmitterPosition, AttributeInfo(className: "CAEmitterLayer", fullTitle: "EmitterPosition", getterString: "emitterPosition", setterString: "setEmitterPosition:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAEmitterLayer_EmitterZPosition, AttributeInfo(className: "CAEmitterLayer", fullTitle: "EmitterZPosition", getterString: "emitterZPosition", setterString: "setEmitterZPosition:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAEmitterLayer_EmitterSize, AttributeInfo(className: "CAEmitterLayer", fullTitle: "EmitterSize", getterString: "emitterSize", setterString: "setEmitterSize:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAEmitterLayer_EmitterDepth, AttributeInfo(className: "CAEmitterLayer", fullTitle: "EmitterDepth", getterString: "emitterDepth", setterString: "setEmitterDepth:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAEmitterLayer_EmitterShape, AttributeInfo(className: "CAEmitterLayer", fullTitle: "EmitterShape", getterString: "emitterShape", setterString: "", typeIfObj: .nsString, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAEmitterLayer_EmitterMode, AttributeInfo(className: "CAEmitterLayer", fullTitle: "EmitterMode", getterString: "emitterMode", setterString: "", typeIfObj: .nsString, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAEmitterLayer_RenderMode, AttributeInfo(className: "CAEmitterLayer", fullTitle: "RenderMode", getterString: "renderMode", setterString: "", typeIfObj: .nsString, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAEmitterLayer_PreservesDepth, AttributeInfo(className: "CAEmitterLayer", fullTitle: "PreservesDepth", getterString: "preservesDepth", setterString: "setPreservesDepth:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAEmitterLayer_Velocity, AttributeInfo(className: "CAEmitterLayer", fullTitle: "Velocity", getterString: "velocity", setterString: "setVelocity:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAEmitterLayer_Scale, AttributeInfo(className: "CAEmitterLayer", fullTitle: "Scale", getterString: "scale", setterString: "setScale:", patch: true, revision: 1)),
                BlueprintAttribute(LookinAttr_CALayer_CAEmitterLayer_Spin, AttributeInfo(className: "CAEmitterLayer", fullTitle: "Spin", getterString: "spin", setterString: "setSpin:", patch: true, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_CAScrollLayer, title: "CAScrollLayer", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_CAScrollLayer_ScrollMode, AttributeInfo(className: "CAScrollLayer", fullTitle: "ScrollMode", getterString: "scrollMode", setterString: "", typeIfObj: .nsString, revision: 1)),
            ]),
            BlueprintSection(LookinAttrSec_CALayer_CATiledLayer, title: "CATiledLayer", attributes: [
                BlueprintAttribute(LookinAttr_CALayer_CATiledLayer_TileSize, AttributeInfo(className: "CATiledLayer", fullTitle: "TileSize", getterString: "tileSize", setterString: "setTileSize:", patch: true, revision: 1)),
            ]),
        ])
    }

#endif
