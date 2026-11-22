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

        static let classGroup = BlueprintGroup(.class, title: "Class", on: .all, sections: [
            BlueprintSection(.Class.class, attributes: [
                BlueprintAttribute(.Class.Class.class, AttributeInfo(className: "CALayer", getterString: "lks_relatedClassChainList", setterString: "", objectValueType: .customObject)),
                BlueprintAttribute(.Class.Class.imagePaths, AttributeInfo(className: "CALayer", getterString: "lks_relatedClassChainImagePaths", setterString: "", objectValueType: .customObject)),
            ]),
        ])

        static let relationGroup = BlueprintGroup(.relation, title: "Relation", on: .all, sections: [
            BlueprintSection(.Relation.relation, attributes: [
                BlueprintAttribute(.Relation.Relation.relation, AttributeInfo(className: "CALayer", getterString: "lks_selfRelation", setterString: "", objectValueType: .customObject, hideIfNil: true)),
            ]),
        ])

        static let layoutGroup = BlueprintGroup(.layout, title: "Layout", on: .all, sections: [
            BlueprintSection(.Layout.frame, title: "Frame", attributes: [
                BlueprintAttribute(.Layout.Frame.frame, AttributeInfo(className: "CALayer", fullTitle: "Frame", patch: true)),
            ]),
            BlueprintSection(.Layout.bounds, title: "Bounds", attributes: [
                BlueprintAttribute(.Layout.Bounds.bounds, AttributeInfo(className: "CALayer", fullTitle: "Bounds", patch: true)),
            ]),
            BlueprintSection(.Layout.safeArea, title: "SafeArea", attributes: [
                BlueprintAttribute(.Layout.SafeArea.safeArea, AttributeInfo(className: viewClassName, fullTitle: "SafeAreaInsets", setterString: "", osVersion: 11)),
            ]),
            BlueprintSection(.Layout.position, title: "Position", attributes: [
                BlueprintAttribute(.Layout.Position.position, AttributeInfo(className: "CALayer", fullTitle: "Position", patch: true)),
            ]),
            BlueprintSection(.Layout.anchorPoint, title: "AnchorPoint", attributes: [
                BlueprintAttribute(.Layout.AnchorPoint.anchorPoint, AttributeInfo(className: "CALayer", fullTitle: "AnchorPoint", patch: true)),
            ]),
            BlueprintSection(.Layout.coordinateSpace, title: "CoordinateSpace", attributes: [
                // Lives under the Layout group rather than the UIWindowScene group,
                // because it is the only geometry a scene exposes — it has no frame.
                BlueprintAttribute(.Layout.CoordinateSpace.coordinateSpace, AttributeInfo(className: "UIWindowScene", fullTitle: "CoordinateSpace", getterString: "lks_coordinateSpaceBounds", setterString: "", patch: false)),
            ]),
        ])

        static let autoLayoutGroup = BlueprintGroup(.autoLayout, title: "AutoLayout", on: .all, sections: [
            BlueprintSection(.AutoLayout.constraints, attributes: [
                BlueprintAttribute(.AutoLayout.Constraints.constraints, AttributeInfo(className: viewClassName, getterString: "lks_constraints", setterString: "", objectValueType: .customObject, hideIfNil: true)),
            ]),
            BlueprintSection(.AutoLayout.intrinsicSize, title: "IntrinsicSize", attributes: [
                BlueprintAttribute(.AutoLayout.IntrinsicSize.size, AttributeInfo(className: viewClassName, fullTitle: "IntrinsicContentSize", setterString: "")),
            ]),
            BlueprintSection(.AutoLayout.hugging, title: "HuggingPriority", attributes: [
                BlueprintAttribute(.AutoLayout.Hugging.horizontal, AttributeInfo(className: viewClassName, fullTitle: "ContentHuggingPriority(Horizontal)", briefTitle: "H", getterString: "lks_horizontalContentHuggingPriority", setterString: "setLks_horizontalContentHuggingPriority:", patch: true)),
                BlueprintAttribute(.AutoLayout.Hugging.vertical, AttributeInfo(className: viewClassName, fullTitle: "ContentHuggingPriority(Vertical)", briefTitle: "V", getterString: "lks_verticalContentHuggingPriority", setterString: "setLks_verticalContentHuggingPriority:", patch: true)),
            ]),
            BlueprintSection(.AutoLayout.resistance, title: "ResistancePriority", attributes: [
                BlueprintAttribute(.AutoLayout.Resistance.horizontal, AttributeInfo(className: viewClassName, fullTitle: "ContentCompressionResistancePriority(Horizontal)", briefTitle: "H", getterString: "lks_horizontalContentCompressionResistancePriority", setterString: "setLks_horizontalContentCompressionResistancePriority:", patch: true)),
                BlueprintAttribute(.AutoLayout.Resistance.vertical, AttributeInfo(className: viewClassName, fullTitle: "ContentCompressionResistancePriority(Vertical)", briefTitle: "V", getterString: "lks_verticalContentCompressionResistancePriority", setterString: "setLks_verticalContentCompressionResistancePriority:", patch: true)),
            ]),
        ])

        static let viewLayerGroup = BlueprintGroup(.viewLayer, title: viewLayerGroupTitle, on: .all, sections: [
            BlueprintSection(.ViewLayer.visibility, attributes: [
                BlueprintAttribute(.ViewLayer.Visibility.hidden, AttributeInfo(className: "CALayer", fullTitle: "Hidden", getterString: "isHidden", patch: true)),
                BlueprintAttribute(.ViewLayer.Visibility.opacity, AttributeInfo(className: "CALayer", fullTitle: "Opacity / Alpha", getterString: "opacity", setterString: "setOpacity:", patch: true)),
            ]),
            BlueprintSection(.ViewLayer.interactionAndMasks, attributes: [
                BlueprintAttribute(.ViewLayer.InteractionAndMasks.interaction, on: .uiKit, AttributeInfo(className: "UIView", fullTitle: "UserInteractionEnabled", getterString: "isUserInteractionEnabled", patch: false)),
                BlueprintAttribute(.ViewLayer.InteractionAndMasks.masksToBounds, AttributeInfo(className: "CALayer", fullTitle: "MasksToBounds / ClipsToBounds", briefTitle: "MasksToBounds", getterString: "masksToBounds", setterString: "setMasksToBounds:", patch: true)),
            ]),
            BlueprintSection(.ViewLayer.backgroundColor, title: "BackgroundColor", attributes: [
                BlueprintAttribute(.ViewLayer.BackgroundColor.backgroundColor, AttributeInfo(className: "CALayer", fullTitle: "BackgroundColor", getterString: "lks_backgroundColor", setterString: "setLks_backgroundColor:", objectValueType: .uiColor, patch: true)),
            ]),
            BlueprintSection(.ViewLayer.border, title: "Border", attributes: [
                BlueprintAttribute(.ViewLayer.Border.color, AttributeInfo(className: "CALayer", fullTitle: "BorderColor", getterString: "lks_borderColor", setterString: "setLks_borderColor:", objectValueType: .uiColor, patch: true)),
                BlueprintAttribute(.ViewLayer.Border.width, AttributeInfo(className: "CALayer", fullTitle: "BorderWidth", patch: true)),
            ]),
            BlueprintSection(.ViewLayer.corner, title: "CornerRadius", attributes: [
                BlueprintAttribute(.ViewLayer.Corner.radius, AttributeInfo(className: "CALayer", fullTitle: "CornerRadius", briefTitle: "", patch: true)),
            ]),
            BlueprintSection(.ViewLayer.shadow, title: "Shadow", attributes: [
                BlueprintAttribute(.ViewLayer.Shadow.color, AttributeInfo(className: "CALayer", fullTitle: "ShadowColor", getterString: "lks_shadowColor", setterString: "setLks_shadowColor:", objectValueType: .uiColor, patch: true)),
                BlueprintAttribute(.ViewLayer.Shadow.opacity, AttributeInfo(className: "CALayer", fullTitle: "ShadowOpacity", briefTitle: "Opacity", patch: true)),
                BlueprintAttribute(.ViewLayer.Shadow.radius, AttributeInfo(className: "CALayer", fullTitle: "ShadowRadius", briefTitle: "Radius", patch: true)),
                BlueprintAttribute(.ViewLayer.Shadow.offsetWidth, AttributeInfo(className: "CALayer", fullTitle: "ShadowOffsetWidth", briefTitle: "OffsetW", getterString: "lks_shadowOffsetWidth", setterString: "setLks_shadowOffsetWidth:", patch: true)),
                BlueprintAttribute(.ViewLayer.Shadow.offsetHeight, AttributeInfo(className: "CALayer", fullTitle: "ShadowOffsetHeight", briefTitle: "OffsetH", getterString: "lks_shadowOffsetHeight", setterString: "setLks_shadowOffsetHeight:", patch: true)),
            ]),
            BlueprintSection(.ViewLayer.tag, title: "Tag", attributes: [
                BlueprintAttribute(.ViewLayer.Tag.tag, AttributeInfo(className: viewClassName, fullTitle: "Tag", briefTitle: "", patch: false)),
            ]),
            BlueprintSection(.ViewLayer.contentMode, title: "ContentMode", on: .uiKit, attributes: [
                BlueprintAttribute(.ViewLayer.ContentMode.mode, AttributeInfo(className: "UIView", fullTitle: "ContentMode", enumList: "UIViewContentMode", patch: true)),
            ]),
            BlueprintSection(.ViewLayer.tintColor, title: "TintColor", on: .uiKit, attributes: [
                BlueprintAttribute(.ViewLayer.TintColor.color, AttributeInfo(className: "UIView", fullTitle: "TintColor", objectValueType: .uiColor, patch: true)),
                BlueprintAttribute(.ViewLayer.TintColor.mode, AttributeInfo(className: "UIView", fullTitle: "TintAdjustmentMode", enumList: "UIViewTintAdjustmentMode", patch: true)),
            ]),
        ])

        static let layoutGuideGroup = BlueprintGroup(.layoutGuide, title: "LayoutGuide", on: .all, sections: [
            BlueprintSection(.LayoutGuide.guideIdentifier, title: "Identifier", attributes: [
                BlueprintAttribute(.LayoutGuide.GuideIdentifier.identifier, AttributeInfo(className: layoutGuideClassName, fullTitle: "Identifier", getterString: "identifier", setterString: "", objectValueType: .nsString, hideIfNil: true)),
            ]),
            BlueprintSection(.LayoutGuide.layoutFrame, title: "LayoutFrame", attributes: [
                BlueprintAttribute(.LayoutGuide.LayoutFrame.layoutFrame, AttributeInfo(className: layoutGuideClassName, fullTitle: "LayoutFrame", getterString: "lks_layoutFrame", setterString: "")),
            ]),
            BlueprintSection(.LayoutGuide.owningView, title: "OwningView", attributes: [
                BlueprintAttribute(.LayoutGuide.OwningView.owningView, AttributeInfo(className: layoutGuideClassName, fullTitle: "OwningView", getterString: "lks_owningViewDescription", setterString: "", objectValueType: .nsString, hideIfNil: true)),
            ]),
        ])

        static let caLayerGroup = BlueprintGroup(.caLayer, title: "CALayer", on: .all, sections: [
            BlueprintSection(.CALayer.zPosition, title: "ZPosition", attributes: [
                BlueprintAttribute(.CALayer.ZPosition.zPosition, AttributeInfo(className: "CALayer", fullTitle: "ZPosition", getterString: "zPosition", setterString: "setZPosition:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.CALayer.anchorPointZ, title: "AnchorPointZ", attributes: [
                BlueprintAttribute(.CALayer.AnchorPointZ.anchorPointZ, AttributeInfo(className: "CALayer", fullTitle: "AnchorPointZ", getterString: "anchorPointZ", setterString: "setAnchorPointZ:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.CALayer.transform, title: "Transform", attributes: [
                BlueprintAttribute(.CALayer.Transform.transform, AttributeInfo(className: "CALayer", fullTitle: "Transform", getterString: "transform", setterString: "", revision: 1, presentation: .structure)),
            ]),
            BlueprintSection(.CALayer.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.CALayer.Behavior.doubleSided, AttributeInfo(className: "CALayer", fullTitle: "DoubleSided", getterString: "isDoubleSided", setterString: "setDoubleSided:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.Behavior.geometryFlipped, AttributeInfo(className: "CALayer", fullTitle: "GeometryFlipped", getterString: "isGeometryFlipped", setterString: "setGeometryFlipped:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.Behavior.opaque, AttributeInfo(className: "CALayer", fullTitle: "Opaque", getterString: "isOpaque", setterString: "setOpaque:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.Behavior.needsDisplayOnBoundsChange, AttributeInfo(className: "CALayer", fullTitle: "NeedsDisplayOnBoundsChange", getterString: "needsDisplayOnBoundsChange", setterString: "setNeedsDisplayOnBoundsChange:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.Behavior.drawsAsynchronously, AttributeInfo(className: "CALayer", fullTitle: "DrawsAsynchronously", getterString: "drawsAsynchronously", setterString: "setDrawsAsynchronously:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.Behavior.allowsEdgeAntialiasing, AttributeInfo(className: "CALayer", fullTitle: "AllowsEdgeAntialiasing", getterString: "allowsEdgeAntialiasing", setterString: "setAllowsEdgeAntialiasing:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.Behavior.allowsGroupOpacity, AttributeInfo(className: "CALayer", fullTitle: "AllowsGroupOpacity", getterString: "allowsGroupOpacity", setterString: "setAllowsGroupOpacity:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.Behavior.shouldRasterize, AttributeInfo(className: "CALayer", fullTitle: "ShouldRasterize", getterString: "shouldRasterize", setterString: "setShouldRasterize:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.CALayer.sublayerTransform, title: "SublayerTransform", attributes: [
                BlueprintAttribute(.CALayer.SublayerTransform.sublayerTransform, AttributeInfo(className: "CALayer", fullTitle: "SublayerTransform", getterString: "sublayerTransform", setterString: "", revision: 1, presentation: .structure)),
            ]),
            BlueprintSection(.CALayer.contentsRect, title: "ContentsRect", attributes: [
                BlueprintAttribute(.CALayer.ContentsRect.contentsRect, AttributeInfo(className: "CALayer", fullTitle: "ContentsRect", getterString: "contentsRect", setterString: "setContentsRect:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.CALayer.contentsGravity, title: "ContentsGravity", attributes: [
                BlueprintAttribute(.CALayer.ContentsGravity.contentsGravity, AttributeInfo(className: "CALayer", fullTitle: "ContentsGravity", getterString: "contentsGravity", setterString: "", objectValueType: .nsString, revision: 1)),
            ]),
            BlueprintSection(.CALayer.contentsScale, title: "ContentsScale", attributes: [
                BlueprintAttribute(.CALayer.ContentsScale.contentsScale, AttributeInfo(className: "CALayer", fullTitle: "ContentsScale", getterString: "contentsScale", setterString: "setContentsScale:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.CALayer.contentsCenter, title: "ContentsCenter", attributes: [
                BlueprintAttribute(.CALayer.ContentsCenter.contentsCenter, AttributeInfo(className: "CALayer", fullTitle: "ContentsCenter", getterString: "contentsCenter", setterString: "setContentsCenter:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.CALayer.contentsFormat, title: "ContentsFormat", attributes: [
                BlueprintAttribute(.CALayer.ContentsFormat.contentsFormat, AttributeInfo(className: "CALayer", fullTitle: "ContentsFormat", getterString: "contentsFormat", setterString: "", objectValueType: .nsString, revision: 1)),
            ]),
            BlueprintSection(.CALayer.toneMapMode, title: "ToneMapMode", attributes: [
                BlueprintAttribute(.CALayer.ToneMapMode.toneMapMode, AttributeInfo(className: "CALayer", fullTitle: "ToneMapMode", getterString: "toneMapMode", setterString: "", objectValueType: .nsString, revision: 1)),
            ]),
            BlueprintSection(.CALayer.preferredDynamicRange, title: "PreferredDynamicRange", attributes: [
                BlueprintAttribute(.CALayer.PreferredDynamicRange.preferredDynamicRange, AttributeInfo(className: "CALayer", fullTitle: "PreferredDynamicRange", getterString: "preferredDynamicRange", setterString: "", objectValueType: .nsString, revision: 1)),
            ]),
            BlueprintSection(.CALayer.contentsHeadroom, title: "ContentsHeadroom", attributes: [
                BlueprintAttribute(.CALayer.ContentsHeadroom.contentsHeadroom, AttributeInfo(className: "CALayer", fullTitle: "ContentsHeadroom", getterString: "contentsHeadroom", setterString: "setContentsHeadroom:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.CALayer.minificationFilter, title: "MinificationFilter", attributes: [
                BlueprintAttribute(.CALayer.MinificationFilter.minificationFilter, AttributeInfo(className: "CALayer", fullTitle: "MinificationFilter", getterString: "minificationFilter", setterString: "", objectValueType: .nsString, revision: 1)),
            ]),
            BlueprintSection(.CALayer.magnificationFilter, title: "MagnificationFilter", attributes: [
                BlueprintAttribute(.CALayer.MagnificationFilter.magnificationFilter, AttributeInfo(className: "CALayer", fullTitle: "MagnificationFilter", getterString: "magnificationFilter", setterString: "", objectValueType: .nsString, revision: 1)),
            ]),
            BlueprintSection(.CALayer.minificationFilterBias, title: "MinificationFilterBias", attributes: [
                BlueprintAttribute(.CALayer.MinificationFilterBias.minificationFilterBias, AttributeInfo(className: "CALayer", fullTitle: "MinificationFilterBias", getterString: "minificationFilterBias", setterString: "setMinificationFilterBias:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.CALayer.maskedCorners, title: "MaskedCorners", attributes: [
                BlueprintAttribute(.CALayer.MaskedCorners.maskedCorners, AttributeInfo(className: "CALayer", fullTitle: "MaskedCorners", getterString: "maskedCorners", setterString: "", revision: 1, presentation: .optionNames("CACornerMask"))),
            ]),
            BlueprintSection(.CALayer.cornerCurve, title: "CornerCurve", attributes: [
                BlueprintAttribute(.CALayer.CornerCurve.cornerCurve, AttributeInfo(className: "CALayer", fullTitle: "CornerCurve", getterString: "cornerCurve", setterString: "", objectValueType: .nsString, revision: 1)),
            ]),
            BlueprintSection(.CALayer.rasterizationScale, title: "RasterizationScale", attributes: [
                BlueprintAttribute(.CALayer.RasterizationScale.rasterizationScale, AttributeInfo(className: "CALayer", fullTitle: "RasterizationScale", getterString: "rasterizationScale", setterString: "setRasterizationScale:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.CALayer.shadowPath, title: "ShadowPath", attributes: [
                BlueprintAttribute(.CALayer.ShadowPath.shadowPath, AttributeInfo(className: "CALayer", fullTitle: "ShadowPath", getterString: "shadowPath", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.path))),
            ]),
            BlueprintSection(.CALayer.name, title: "Name", attributes: [
                BlueprintAttribute(.CALayer.Name.name, AttributeInfo(className: "CALayer", fullTitle: "Name", getterString: "name", setterString: "setName:", objectValueType: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.CALayer.visibleRect, title: "VisibleRect", attributes: [
                BlueprintAttribute(.CALayer.VisibleRect.visibleRect, AttributeInfo(className: "CALayer", fullTitle: "VisibleRect", getterString: "visibleRect", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.CALayer.caShapeLayer, title: "CAShapeLayer", attributes: [
                BlueprintAttribute(.CALayer.CAShapeLayer.path, AttributeInfo(className: "CAShapeLayer", fullTitle: "Path", getterString: "path", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.path))),
                BlueprintAttribute(.CALayer.CAShapeLayer.fillColor, AttributeInfo(className: "CAShapeLayer", fullTitle: "FillColor", getterString: "fillColor", setterString: "", revision: 1, presentation: .cgColor)),
                BlueprintAttribute(.CALayer.CAShapeLayer.fillRule, AttributeInfo(className: "CAShapeLayer", fullTitle: "FillRule", getterString: "fillRule", setterString: "", objectValueType: .nsString, revision: 1)),
                BlueprintAttribute(.CALayer.CAShapeLayer.strokeColor, AttributeInfo(className: "CAShapeLayer", fullTitle: "StrokeColor", getterString: "strokeColor", setterString: "", revision: 1, presentation: .cgColor)),
                BlueprintAttribute(.CALayer.CAShapeLayer.strokeStart, AttributeInfo(className: "CAShapeLayer", fullTitle: "StrokeStart", getterString: "strokeStart", setterString: "setStrokeStart:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAShapeLayer.strokeEnd, AttributeInfo(className: "CAShapeLayer", fullTitle: "StrokeEnd", getterString: "strokeEnd", setterString: "setStrokeEnd:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAShapeLayer.lineWidth, AttributeInfo(className: "CAShapeLayer", fullTitle: "LineWidth", getterString: "lineWidth", setterString: "setLineWidth:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAShapeLayer.miterLimit, AttributeInfo(className: "CAShapeLayer", fullTitle: "MiterLimit", getterString: "miterLimit", setterString: "setMiterLimit:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAShapeLayer.lineCap, AttributeInfo(className: "CAShapeLayer", fullTitle: "LineCap", getterString: "lineCap", setterString: "", objectValueType: .nsString, revision: 1)),
                BlueprintAttribute(.CALayer.CAShapeLayer.lineJoin, AttributeInfo(className: "CAShapeLayer", fullTitle: "LineJoin", getterString: "lineJoin", setterString: "", objectValueType: .nsString, revision: 1)),
                BlueprintAttribute(.CALayer.CAShapeLayer.lineDashPhase, AttributeInfo(className: "CAShapeLayer", fullTitle: "LineDashPhase", getterString: "lineDashPhase", setterString: "setLineDashPhase:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAShapeLayer.lineDashPattern, AttributeInfo(className: "CAShapeLayer", fullTitle: "LineDashPattern", getterString: "lineDashPattern", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(.CALayer.caGradientLayer, title: "CAGradientLayer", attributes: [
                BlueprintAttribute(.CALayer.CAGradientLayer.colors, AttributeInfo(className: "CAGradientLayer", fullTitle: "Colors", getterString: "colors", setterString: "", revision: 1, presentation: .count)),
                BlueprintAttribute(.CALayer.CAGradientLayer.locations, AttributeInfo(className: "CAGradientLayer", fullTitle: "Locations", getterString: "locations", setterString: "", revision: 1, presentation: .count)),
                BlueprintAttribute(.CALayer.CAGradientLayer.startPoint, AttributeInfo(className: "CAGradientLayer", fullTitle: "StartPoint", getterString: "startPoint", setterString: "setStartPoint:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAGradientLayer.endPoint, AttributeInfo(className: "CAGradientLayer", fullTitle: "EndPoint", getterString: "endPoint", setterString: "setEndPoint:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAGradientLayer.type, AttributeInfo(className: "CAGradientLayer", fullTitle: "Type", getterString: "type", setterString: "", objectValueType: .nsString, revision: 1)),
            ]),
            BlueprintSection(.CALayer.caTextLayer, title: "CATextLayer", attributes: [
                BlueprintAttribute(.CALayer.CATextLayer.fontSize, AttributeInfo(className: "CATextLayer", fullTitle: "FontSize", getterString: "fontSize", setterString: "setFontSize:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CATextLayer.foregroundColor, AttributeInfo(className: "CATextLayer", fullTitle: "ForegroundColor", getterString: "foregroundColor", setterString: "", revision: 1, presentation: .cgColor)),
                BlueprintAttribute(.CALayer.CATextLayer.wrapped, AttributeInfo(className: "CATextLayer", fullTitle: "Wrapped", getterString: "isWrapped", setterString: "setWrapped:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CATextLayer.truncationMode, AttributeInfo(className: "CATextLayer", fullTitle: "TruncationMode", getterString: "truncationMode", setterString: "", objectValueType: .nsString, revision: 1)),
                BlueprintAttribute(.CALayer.CATextLayer.alignmentMode, AttributeInfo(className: "CATextLayer", fullTitle: "AlignmentMode", getterString: "alignmentMode", setterString: "", objectValueType: .nsString, revision: 1)),
                BlueprintAttribute(.CALayer.CATextLayer.allowsFontSubpixelQuantization, AttributeInfo(className: "CATextLayer", fullTitle: "AllowsFontSubpixelQuantization", getterString: "allowsFontSubpixelQuantization", setterString: "setAllowsFontSubpixelQuantization:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.CALayer.caReplicatorLayer, title: "CAReplicatorLayer", attributes: [
                BlueprintAttribute(.CALayer.CAReplicatorLayer.instanceCount, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "InstanceCount", getterString: "instanceCount", setterString: "setInstanceCount:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAReplicatorLayer.preservesDepth, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "PreservesDepth", getterString: "preservesDepth", setterString: "setPreservesDepth:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAReplicatorLayer.instanceDelay, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "InstanceDelay", getterString: "instanceDelay", setterString: "setInstanceDelay:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAReplicatorLayer.instanceTransform, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "InstanceTransform", getterString: "instanceTransform", setterString: "", revision: 1, presentation: .structure)),
                BlueprintAttribute(.CALayer.CAReplicatorLayer.instanceColor, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "InstanceColor", getterString: "instanceColor", setterString: "", revision: 1, presentation: .cgColor)),
                BlueprintAttribute(.CALayer.CAReplicatorLayer.instanceRedOffset, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "InstanceRedOffset", getterString: "instanceRedOffset", setterString: "setInstanceRedOffset:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAReplicatorLayer.instanceGreenOffset, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "InstanceGreenOffset", getterString: "instanceGreenOffset", setterString: "setInstanceGreenOffset:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAReplicatorLayer.instanceBlueOffset, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "InstanceBlueOffset", getterString: "instanceBlueOffset", setterString: "setInstanceBlueOffset:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAReplicatorLayer.instanceAlphaOffset, AttributeInfo(className: "CAReplicatorLayer", fullTitle: "InstanceAlphaOffset", getterString: "instanceAlphaOffset", setterString: "setInstanceAlphaOffset:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.CALayer.caEmitterLayer, title: "CAEmitterLayer", attributes: [
                BlueprintAttribute(.CALayer.CAEmitterLayer.emitterCells, AttributeInfo(className: "CAEmitterLayer", fullTitle: "EmitterCells", getterString: "emitterCells", setterString: "", revision: 1, presentation: .count)),
                BlueprintAttribute(.CALayer.CAEmitterLayer.birthRate, AttributeInfo(className: "CAEmitterLayer", fullTitle: "BirthRate", getterString: "birthRate", setterString: "setBirthRate:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAEmitterLayer.lifetime, AttributeInfo(className: "CAEmitterLayer", fullTitle: "Lifetime", getterString: "lifetime", setterString: "setLifetime:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAEmitterLayer.emitterPosition, AttributeInfo(className: "CAEmitterLayer", fullTitle: "EmitterPosition", getterString: "emitterPosition", setterString: "setEmitterPosition:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAEmitterLayer.emitterZPosition, AttributeInfo(className: "CAEmitterLayer", fullTitle: "EmitterZPosition", getterString: "emitterZPosition", setterString: "setEmitterZPosition:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAEmitterLayer.emitterSize, AttributeInfo(className: "CAEmitterLayer", fullTitle: "EmitterSize", getterString: "emitterSize", setterString: "setEmitterSize:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAEmitterLayer.emitterDepth, AttributeInfo(className: "CAEmitterLayer", fullTitle: "EmitterDepth", getterString: "emitterDepth", setterString: "setEmitterDepth:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAEmitterLayer.emitterShape, AttributeInfo(className: "CAEmitterLayer", fullTitle: "EmitterShape", getterString: "emitterShape", setterString: "", objectValueType: .nsString, revision: 1)),
                BlueprintAttribute(.CALayer.CAEmitterLayer.emitterMode, AttributeInfo(className: "CAEmitterLayer", fullTitle: "EmitterMode", getterString: "emitterMode", setterString: "", objectValueType: .nsString, revision: 1)),
                BlueprintAttribute(.CALayer.CAEmitterLayer.renderMode, AttributeInfo(className: "CAEmitterLayer", fullTitle: "RenderMode", getterString: "renderMode", setterString: "", objectValueType: .nsString, revision: 1)),
                BlueprintAttribute(.CALayer.CAEmitterLayer.preservesDepth, AttributeInfo(className: "CAEmitterLayer", fullTitle: "PreservesDepth", getterString: "preservesDepth", setterString: "setPreservesDepth:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAEmitterLayer.velocity, AttributeInfo(className: "CAEmitterLayer", fullTitle: "Velocity", getterString: "velocity", setterString: "setVelocity:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAEmitterLayer.scale, AttributeInfo(className: "CAEmitterLayer", fullTitle: "Scale", getterString: "scale", setterString: "setScale:", patch: true, revision: 1)),
                BlueprintAttribute(.CALayer.CAEmitterLayer.spin, AttributeInfo(className: "CAEmitterLayer", fullTitle: "Spin", getterString: "spin", setterString: "setSpin:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.CALayer.caScrollLayer, title: "CAScrollLayer", attributes: [
                BlueprintAttribute(.CALayer.CAScrollLayer.scrollMode, AttributeInfo(className: "CAScrollLayer", fullTitle: "ScrollMode", getterString: "scrollMode", setterString: "", objectValueType: .nsString, revision: 1)),
            ]),
            BlueprintSection(.CALayer.caTiledLayer, title: "CATiledLayer", attributes: [
                BlueprintAttribute(.CALayer.CATiledLayer.tileSize, AttributeInfo(className: "CATiledLayer", fullTitle: "TileSize", getterString: "tileSize", setterString: "setTileSize:", patch: true, revision: 1)),
            ]),
        ])
    }

#endif
