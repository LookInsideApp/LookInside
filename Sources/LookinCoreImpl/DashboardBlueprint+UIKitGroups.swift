//
//  DashboardBlueprint+UIKitGroups.swift
//  LookinCore
//
//  The groups only UIKit lists.
//  Each group lists its sections and each section its attributes, in display
//  order; DashboardBlueprintCatalog.swift explains the entry types and how the
//  lookup tables are derived. A section or attribute without `on:` is on the
//  platforms of the group or section it belongs to.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation

    extension DashboardBlueprintTables {
        static let uiStackViewGroup = BlueprintGroup(.uiStackView, title: "UIStackView", on: .uiKit, sections: [
            BlueprintSection(.UIStackView.axis, title: "Axis", attributes: [
                BlueprintAttribute(.UIStackView.Axis.axis, AttributeInfo(className: "UIStackView", fullTitle: "Axis", enumList: "UILayoutConstraintAxis", patch: true)),
            ]),
            BlueprintSection(.UIStackView.distribution, title: "Distribution", attributes: [
                BlueprintAttribute(.UIStackView.Distribution.distribution, AttributeInfo(className: "UIStackView", fullTitle: "Distribution", enumList: "UIStackViewDistribution", patch: true)),
            ]),
            BlueprintSection(.UIStackView.alignment, title: "Alignment", attributes: [
                BlueprintAttribute(.UIStackView.Alignment.alignment, AttributeInfo(className: "UIStackView", fullTitle: "Alignment", enumList: "UIStackViewAlignment", patch: true)),
            ]),
            BlueprintSection(.UIStackView.spacing, attributes: [
                BlueprintAttribute(.UIStackView.Spacing.spacing, AttributeInfo(className: "UIStackView", fullTitle: "Spacing", patch: true)),
            ]),
            BlueprintSection(.UIStackView.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UIStackView.Behavior.baselineRelativeArrangement, AttributeInfo(className: "UIStackView", fullTitle: "BaselineRelativeArrangement", getterString: "isBaselineRelativeArrangement", setterString: "setBaselineRelativeArrangement:", patch: true, revision: 1)),
                BlueprintAttribute(.UIStackView.Behavior.layoutMarginsRelativeArrangement, AttributeInfo(className: "UIStackView", fullTitle: "LayoutMarginsRelativeArrangement", getterString: "isLayoutMarginsRelativeArrangement", setterString: "setLayoutMarginsRelativeArrangement:", patch: true, revision: 1)),
            ]),
        ])

        static let uiVisualEffectViewGroup = BlueprintGroup(.uiVisualEffectView, title: "UIVisualEffectView", on: .uiKit, sections: [
            BlueprintSection(.UIVisualEffectView.style, title: "Style", attributes: [
                BlueprintAttribute(.UIVisualEffectView.Style.style, AttributeInfo(className: "UIVisualEffectView", getterString: "lks_blurEffectStyleNumber", setterString: "setLks_blurEffectStyleNumber:", objectValueType: .customObject, enumList: "UIBlurEffectStyle", patch: true, hideIfNil: true)),
            ]),
            BlueprintSection(.UIVisualEffectView.qmuiForegroundColor, title: "ForegroundColor", attributes: [
                BlueprintAttribute(.UIVisualEffectView.QMUIForegroundColor.color, AttributeInfo(className: "QMUIVisualEffectView", fullTitle: "ForegroundColor", objectValueType: .uiColor, patch: true)),
            ]),
            BlueprintSection(.UIVisualEffectView.effect, title: "Effect", attributes: [
                BlueprintAttribute(.UIVisualEffectView.Effect.effect, AttributeInfo(className: "UIVisualEffectView", fullTitle: "Effect", getterString: "effect", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.className))),
            ]),
        ])

        static let uiImageViewGroup = BlueprintGroup(.uiImageView, title: "UIImageView", on: .uiKit, sections: [
            BlueprintSection(.UIImageView.name, title: "ImageName", attributes: [
                BlueprintAttribute(.UIImageView.Name.name, AttributeInfo(className: "UIImageView", fullTitle: "ImageName", getterString: "lks_imageSourceName", setterString: "", objectValueType: .nsString, hideIfNil: true)),
            ]),
            BlueprintSection(.UIImageView.open, attributes: [
                BlueprintAttribute(.UIImageView.Open.open, AttributeInfo(className: "UIImageView", getterString: "lks_imageViewOidIfHasImage", setterString: "", objectValueType: .customObject, hideIfNil: true)),
            ]),
            BlueprintSection(.UIImageView.highlightedImage, title: "HighlightedImage", attributes: [
                BlueprintAttribute(.UIImageView.HighlightedImage.highlightedImage, AttributeInfo(className: "UIImageView", fullTitle: "HighlightedImage", getterString: "highlightedImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(.UIImageView.preferredSymbolConfiguration, title: "PreferredSymbolConfiguration", attributes: [
                BlueprintAttribute(.UIImageView.PreferredSymbolConfiguration.preferredSymbolConfiguration, AttributeInfo(className: "UIImageView", fullTitle: "PreferredSymbolConfiguration", getterString: "preferredSymbolConfiguration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.description))),
            ]),
            BlueprintSection(.UIImageView.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UIImageView.Behavior.highlighted, AttributeInfo(className: "UIImageView", fullTitle: "Highlighted", getterString: "isHighlighted", setterString: "setHighlighted:", patch: true, revision: 1)),
                BlueprintAttribute(.UIImageView.Behavior.animating, AttributeInfo(className: "UIImageView", fullTitle: "Animating", getterString: "isAnimating", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.UIImageView.animationImages, title: "AnimationImages", attributes: [
                BlueprintAttribute(.UIImageView.AnimationImages.animationImages, AttributeInfo(className: "UIImageView", fullTitle: "AnimationImages", getterString: "animationImages", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(.UIImageView.highlightedAnimationImages, title: "HighlightedAnimationImages", attributes: [
                BlueprintAttribute(.UIImageView.HighlightedAnimationImages.highlightedAnimationImages, AttributeInfo(className: "UIImageView", fullTitle: "HighlightedAnimationImages", getterString: "highlightedAnimationImages", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(.UIImageView.animationDuration, title: "AnimationDuration", attributes: [
                BlueprintAttribute(.UIImageView.AnimationDuration.animationDuration, AttributeInfo(className: "UIImageView", fullTitle: "AnimationDuration", getterString: "animationDuration", setterString: "setAnimationDuration:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIImageView.animationRepeatCount, title: "AnimationRepeatCount", attributes: [
                BlueprintAttribute(.UIImageView.AnimationRepeatCount.animationRepeatCount, AttributeInfo(className: "UIImageView", fullTitle: "AnimationRepeatCount", getterString: "animationRepeatCount", setterString: "setAnimationRepeatCount:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIImageView.preferredImageDynamicRange, title: "PreferredImageDynamicRange", attributes: [
                BlueprintAttribute(.UIImageView.PreferredImageDynamicRange.preferredImageDynamicRange, AttributeInfo(className: "UIImageView", fullTitle: "PreferredImageDynamicRange", getterString: "preferredImageDynamicRange", setterString: "setPreferredImageDynamicRange:", enumList: "UIImageDynamicRange", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIImageView.imageDynamicRange, title: "ImageDynamicRange", attributes: [
                BlueprintAttribute(.UIImageView.ImageDynamicRange.imageDynamicRange, AttributeInfo(className: "UIImageView", fullTitle: "ImageDynamicRange", getterString: "imageDynamicRange", setterString: "", enumList: "UIImageDynamicRange", revision: 1)),
            ]),
        ])

        static let uiLabelGroup = BlueprintGroup(.uiLabel, title: "UILabel", on: .uiKit, sections: [
            BlueprintSection(.UILabel.text, title: "Text", attributes: [
                BlueprintAttribute(.UILabel.Text.text, AttributeInfo(className: "UILabel", fullTitle: "Text", objectValueType: .nsString, patch: true)),
            ]),
            BlueprintSection(.UILabel.font, title: "Font", attributes: [
                BlueprintAttribute(.UILabel.Font.name, AttributeInfo(className: "UILabel", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", objectValueType: .nsString, patch: false)),
                BlueprintAttribute(.UILabel.Font.size, AttributeInfo(className: "UILabel", fullTitle: "FontSize", briefTitle: "FontSize", getterString: "lks_fontSize", setterString: "setLks_fontSize:", patch: true)),
            ]),
            BlueprintSection(.UILabel.numberOfLines, title: "NumberOfLines", attributes: [
                BlueprintAttribute(.UILabel.NumberOfLines.numberOfLines, AttributeInfo(className: "UILabel", fullTitle: "NumberOfLines", briefTitle: "", patch: true)),
            ]),
            BlueprintSection(.UILabel.textColor, title: "TextColor", attributes: [
                BlueprintAttribute(.UILabel.TextColor.color, AttributeInfo(className: "UILabel", fullTitle: "TextColor", objectValueType: .uiColor, patch: true)),
            ]),
            BlueprintSection(.UILabel.breakMode, title: "LineBreakMode", attributes: [
                BlueprintAttribute(.UILabel.BreakMode.mode, AttributeInfo(className: "UILabel", fullTitle: "LineBreakMode", enumList: "NSLineBreakMode", patch: true)),
            ]),
            BlueprintSection(.UILabel.alignment, title: "TextAlignment", attributes: [
                BlueprintAttribute(.UILabel.Alignment.alignment, AttributeInfo(className: "UILabel", fullTitle: "TextAlignment", enumList: "NSTextAlignment", patch: true)),
            ]),
            BlueprintSection(.UILabel.canAdjustFont, attributes: [
                BlueprintAttribute(.UILabel.CanAdjustFont.canAdjustFont, AttributeInfo(className: "UILabel", fullTitle: "AdjustsFontSizeToFitWidth", patch: true)),
            ]),
            BlueprintSection(.UILabel.preferredVibrancy, title: "PreferredVibrancy", attributes: [
                BlueprintAttribute(.UILabel.PreferredVibrancy.preferredVibrancy, AttributeInfo(className: "UILabel", fullTitle: "PreferredVibrancy", getterString: "preferredVibrancy", setterString: "setPreferredVibrancy:", enumList: "UILabelVibrancy", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UILabel.colors, title: "Colors", attributes: [
                BlueprintAttribute(.UILabel.Colors.shadowColor, AttributeInfo(className: "UILabel", fullTitle: "ShadowColor", getterString: "shadowColor", setterString: "setShadowColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.UILabel.Colors.highlightedTextColor, AttributeInfo(className: "UILabel", fullTitle: "HighlightedTextColor", getterString: "highlightedTextColor", setterString: "setHighlightedTextColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UILabel.shadowOffset, title: "ShadowOffset", attributes: [
                BlueprintAttribute(.UILabel.ShadowOffset.shadowOffset, AttributeInfo(className: "UILabel", fullTitle: "ShadowOffset", getterString: "shadowOffset", setterString: "setShadowOffset:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UILabel.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UILabel.Behavior.highlighted, AttributeInfo(className: "UILabel", fullTitle: "Highlighted", getterString: "isHighlighted", setterString: "setHighlighted:", patch: true, revision: 1)),
                BlueprintAttribute(.UILabel.Behavior.enabled, AttributeInfo(className: "UILabel", fullTitle: "Enabled", getterString: "isEnabled", setterString: "setEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.UILabel.Behavior.allowsDefaultTighteningForTruncation, AttributeInfo(className: "UILabel", fullTitle: "AllowsDefaultTighteningForTruncation", getterString: "allowsDefaultTighteningForTruncation", setterString: "setAllowsDefaultTighteningForTruncation:", patch: true, revision: 1)),
                BlueprintAttribute(.UILabel.Behavior.showsExpansionTextWhenTruncated, AttributeInfo(className: "UILabel", fullTitle: "ShowsExpansionTextWhenTruncated", getterString: "showsExpansionTextWhenTruncated", setterString: "setShowsExpansionTextWhenTruncated:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UILabel.baselineAdjustment, title: "BaselineAdjustment", attributes: [
                BlueprintAttribute(.UILabel.BaselineAdjustment.baselineAdjustment, AttributeInfo(className: "UILabel", fullTitle: "BaselineAdjustment", getterString: "baselineAdjustment", setterString: "setBaselineAdjustment:", enumList: "UIBaselineAdjustment", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UILabel.minimumScaleFactor, title: "MinimumScaleFactor", attributes: [
                BlueprintAttribute(.UILabel.MinimumScaleFactor.minimumScaleFactor, AttributeInfo(className: "UILabel", fullTitle: "MinimumScaleFactor", getterString: "minimumScaleFactor", setterString: "setMinimumScaleFactor:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UILabel.lineBreakStrategy, title: "LineBreakStrategy", attributes: [
                BlueprintAttribute(.UILabel.LineBreakStrategy.lineBreakStrategy, AttributeInfo(className: "UILabel", fullTitle: "LineBreakStrategy", getterString: "lineBreakStrategy", setterString: "", revision: 1, presentation: .optionNames("NSLineBreakStrategy"))),
            ]),
            BlueprintSection(.UILabel.preferredMaxLayoutWidth, title: "PreferredMaxLayoutWidth", attributes: [
                BlueprintAttribute(.UILabel.PreferredMaxLayoutWidth.preferredMaxLayoutWidth, AttributeInfo(className: "UILabel", fullTitle: "PreferredMaxLayoutWidth", getterString: "preferredMaxLayoutWidth", setterString: "setPreferredMaxLayoutWidth:", patch: true, revision: 1)),
            ]),
        ])

        static let uiControlGroup = BlueprintGroup(.uiControl, title: "UIControl", on: .uiKit, sections: [
            BlueprintSection(.UIControl.enabledSelected, attributes: [
                BlueprintAttribute(.UIControl.EnabledSelected.enabled, AttributeInfo(className: "UIControl", fullTitle: "Enabled", getterString: "isEnabled", patch: false)),
                BlueprintAttribute(.UIControl.EnabledSelected.selected, AttributeInfo(className: "UIControl", fullTitle: "Selected", getterString: "isSelected", patch: true)),
            ]),
            BlueprintSection(.UIControl.qmuiOutsideEdge, title: "QMUI_outsideEdge", attributes: [
                BlueprintAttribute(.UIControl.QMUIOutsideEdge.edge, AttributeInfo(className: "UIControl", fullTitle: "qmui_outsideEdge")),
            ]),
            BlueprintSection(.UIControl.verAlignment, title: "VerticalAlignment", attributes: [
                BlueprintAttribute(.UIControl.VerAlignment.alignment, AttributeInfo(className: "UIControl", fullTitle: "ContentVerticalAlignment", enumList: "UIControlContentVerticalAlignment", patch: true)),
            ]),
            BlueprintSection(.UIControl.horAlignment, title: "HorizontalAlignment", attributes: [
                BlueprintAttribute(.UIControl.HorAlignment.alignment, AttributeInfo(className: "UIControl", fullTitle: "ContentHorizontalAlignment", enumList: "UIControlContentHorizontalAlignment", patch: true)),
            ]),
            BlueprintSection(.UIControl.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UIControl.Behavior.highlighted, AttributeInfo(className: "UIControl", fullTitle: "Highlighted", getterString: "isHighlighted", setterString: "setHighlighted:", patch: true, revision: 1)),
                BlueprintAttribute(.UIControl.Behavior.tracking, AttributeInfo(className: "UIControl", fullTitle: "Tracking", getterString: "isTracking", setterString: "", revision: 1)),
                BlueprintAttribute(.UIControl.Behavior.touchInside, AttributeInfo(className: "UIControl", fullTitle: "TouchInside", getterString: "isTouchInside", setterString: "", revision: 1)),
                BlueprintAttribute(.UIControl.Behavior.contextMenuInteractionEnabled, AttributeInfo(className: "UIControl", fullTitle: "ContextMenuInteractionEnabled", getterString: "isContextMenuInteractionEnabled", setterString: "setContextMenuInteractionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.UIControl.Behavior.showsMenuAsPrimaryAction, AttributeInfo(className: "UIControl", fullTitle: "ShowsMenuAsPrimaryAction", getterString: "showsMenuAsPrimaryAction", setterString: "setShowsMenuAsPrimaryAction:", patch: true, revision: 1)),
                BlueprintAttribute(.UIControl.Behavior.symbolAnimationEnabled, AttributeInfo(className: "UIControl", fullTitle: "SymbolAnimationEnabled", getterString: "isSymbolAnimationEnabled", setterString: "setSymbolAnimationEnabled:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIControl.effectiveContentHorizontalAlignment, title: "EffectiveContentHorizontalAlignment", attributes: [
                BlueprintAttribute(.UIControl.EffectiveContentHorizontalAlignment.effectiveContentHorizontalAlignment, AttributeInfo(className: "UIControl", fullTitle: "EffectiveContentHorizontalAlignment", getterString: "effectiveContentHorizontalAlignment", setterString: "", enumList: "UIControlContentHorizontalAlignment", revision: 1)),
            ]),
            BlueprintSection(.UIControl.state, title: "State", attributes: [
                BlueprintAttribute(.UIControl.State.state, AttributeInfo(className: "UIControl", fullTitle: "State", getterString: "state", setterString: "", revision: 1, presentation: .optionNames("UIControlState"))),
            ]),
            BlueprintSection(.UIControl.allControlEvents, title: "AllControlEvents", attributes: [
                BlueprintAttribute(.UIControl.AllControlEvents.allControlEvents, AttributeInfo(className: "UIControl", fullTitle: "AllControlEvents", getterString: "allControlEvents", setterString: "", revision: 1, presentation: .optionNames("UIControlEvents"))),
            ]),
            BlueprintSection(.UIControl.toolTip, title: "ToolTip", attributes: [
                BlueprintAttribute(.UIControl.ToolTip.toolTip, AttributeInfo(className: "UIControl", fullTitle: "ToolTip", getterString: "toolTip", setterString: "setToolTip:", objectValueType: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
        ])

        static let uiButtonGroup = BlueprintGroup(.uiButton, title: "UIButton", on: .uiKit, sections: [
            BlueprintSection(.UIButton.contentInsets, title: "ContentInsets", attributes: [
                BlueprintAttribute(.UIButton.ContentInsets.insets, AttributeInfo(className: "UIButton", fullTitle: "ContentEdgeInsets", patch: true)),
            ]),
            BlueprintSection(.UIButton.titleInsets, title: "TitleInsets", attributes: [
                BlueprintAttribute(.UIButton.TitleInsets.insets, AttributeInfo(className: "UIButton", fullTitle: "TitleEdgeInsets", patch: true)),
            ]),
            BlueprintSection(.UIButton.imageInsets, title: "ImageInsets", attributes: [
                BlueprintAttribute(.UIButton.ImageInsets.insets, AttributeInfo(className: "UIButton", fullTitle: "ImageEdgeInsets", patch: true)),
            ]),
            BlueprintSection(.UIButton.behavioralStyle, title: "BehavioralStyle", attributes: [
                BlueprintAttribute(.UIButton.BehavioralStyle.behavioralStyle, AttributeInfo(className: "UIButton", fullTitle: "BehavioralStyle", getterString: "behavioralStyle", setterString: "", enumList: "UIBehavioralStyle", revision: 1)),
            ]),
            BlueprintSection(.UIButton.preferredBehavioralStyle, title: "PreferredBehavioralStyle", attributes: [
                BlueprintAttribute(.UIButton.PreferredBehavioralStyle.preferredBehavioralStyle, AttributeInfo(className: "UIButton", fullTitle: "PreferredBehavioralStyle", getterString: "preferredBehavioralStyle", setterString: "setPreferredBehavioralStyle:", enumList: "UIBehavioralStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIButton.configuration, title: "Configuration", attributes: [
                BlueprintAttribute(.UIButton.Configuration.configuration, AttributeInfo(className: "UIButton", fullTitle: "Configuration", getterString: "configuration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.configuration))),
            ]),
            BlueprintSection(.UIButton.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UIButton.Behavior.automaticallyUpdatesConfiguration, AttributeInfo(className: "UIButton", fullTitle: "AutomaticallyUpdatesConfiguration", getterString: "automaticallyUpdatesConfiguration", setterString: "setAutomaticallyUpdatesConfiguration:", patch: true, revision: 1)),
                BlueprintAttribute(.UIButton.Behavior.hovered, AttributeInfo(className: "UIButton", fullTitle: "Hovered", getterString: "isHovered", setterString: "", revision: 1)),
                BlueprintAttribute(.UIButton.Behavior.held, AttributeInfo(className: "UIButton", fullTitle: "Held", getterString: "isHeld", setterString: "", revision: 1)),
                BlueprintAttribute(.UIButton.Behavior.pointerInteractionEnabled, AttributeInfo(className: "UIButton", fullTitle: "PointerInteractionEnabled", getterString: "isPointerInteractionEnabled", setterString: "setPointerInteractionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.UIButton.Behavior.changesSelectionAsPrimaryAction, AttributeInfo(className: "UIButton", fullTitle: "ChangesSelectionAsPrimaryAction", getterString: "changesSelectionAsPrimaryAction", setterString: "setChangesSelectionAsPrimaryAction:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIButton.buttonType, title: "ButtonType", attributes: [
                BlueprintAttribute(.UIButton.ButtonType.buttonType, AttributeInfo(className: "UIButton", fullTitle: "ButtonType", getterString: "buttonType", setterString: "", enumList: "UIButtonType", revision: 1)),
            ]),
            BlueprintSection(.UIButton.role, title: "Role", attributes: [
                BlueprintAttribute(.UIButton.Role.role, AttributeInfo(className: "UIButton", fullTitle: "Role", getterString: "role", setterString: "setRole:", enumList: "UIButtonRole", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIButton.menu, title: "Menu", attributes: [
                BlueprintAttribute(.UIButton.Menu.menu, AttributeInfo(className: "UIButton", fullTitle: "Menu", getterString: "menu", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.menu))),
            ]),
            BlueprintSection(.UIButton.currentTitle, title: "CurrentTitle", attributes: [
                BlueprintAttribute(.UIButton.CurrentTitle.currentTitle, AttributeInfo(className: "UIButton", fullTitle: "CurrentTitle", getterString: "currentTitle", setterString: "", objectValueType: .nsString, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UIButton.colors, title: "Colors", attributes: [
                BlueprintAttribute(.UIButton.Colors.currentTitleColor, AttributeInfo(className: "UIButton", fullTitle: "CurrentTitleColor", getterString: "currentTitleColor", setterString: "", objectValueType: .uiColor, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.UIButton.Colors.currentTitleShadowColor, AttributeInfo(className: "UIButton", fullTitle: "CurrentTitleShadowColor", getterString: "currentTitleShadowColor", setterString: "", objectValueType: .uiColor, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UIButton.images, title: "Images", attributes: [
                BlueprintAttribute(.UIButton.Images.currentImage, AttributeInfo(className: "UIButton", fullTitle: "CurrentImage", getterString: "currentImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.UIButton.Images.currentBackgroundImage, AttributeInfo(className: "UIButton", fullTitle: "CurrentBackgroundImage", getterString: "currentBackgroundImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(.UIButton.currentPreferredSymbolConfiguration, title: "CurrentPreferredSymbolConfiguration", attributes: [
                BlueprintAttribute(.UIButton.CurrentPreferredSymbolConfiguration.currentPreferredSymbolConfiguration, AttributeInfo(className: "UIButton", fullTitle: "CurrentPreferredSymbolConfiguration", getterString: "currentPreferredSymbolConfiguration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.description))),
            ]),
        ])

        static let uiScrollViewGroup = BlueprintGroup(.uiScrollView, title: "UIScrollView", on: .uiKit, sections: [
            BlueprintSection(.UIScrollView.contentInset, title: "ContentInset", attributes: [
                BlueprintAttribute(.UIScrollView.ContentInset.inset, AttributeInfo(className: "UIScrollView", fullTitle: "ContentInset", patch: true)),
            ]),
            BlueprintSection(.UIScrollView.adjustedInset, title: "AdjustedContentInset", attributes: [
                BlueprintAttribute(.UIScrollView.AdjustedInset.inset, AttributeInfo(className: "UIScrollView", fullTitle: "AdjustedContentInset", setterString: "", osVersion: 11)),
            ]),
            BlueprintSection(.UIScrollView.qmuiInitialInset, title: "QMUI_initialContentInset", attributes: [
                BlueprintAttribute(.UIScrollView.QMUIInitialInset.inset, AttributeInfo(className: "UIScrollView", fullTitle: "qmui_initialContentInset", patch: true)),
            ]),
            BlueprintSection(.UIScrollView.indicatorInset, title: "ScrollIndicatorInsets", attributes: [
                BlueprintAttribute(.UIScrollView.IndicatorInset.inset, AttributeInfo(className: "UIScrollView", fullTitle: "ScrollIndicatorInsets", patch: false)),
            ]),
            BlueprintSection(.UIScrollView.offset, title: "ContentOffset", attributes: [
                BlueprintAttribute(.UIScrollView.Offset.offset, AttributeInfo(className: "UIScrollView", fullTitle: "ContentOffset", patch: true)),
            ]),
            BlueprintSection(.UIScrollView.contentSize, title: "ContentSize", attributes: [
                BlueprintAttribute(.UIScrollView.ContentSize.size, AttributeInfo(className: "UIScrollView", fullTitle: "ContentSize", patch: true)),
            ]),
            BlueprintSection(.UIScrollView.behavior, title: "InsetAdjustmentBehavior", attributes: [
                BlueprintAttribute(.UIScrollView.Behavior.behavior, AttributeInfo(className: "UIScrollView", fullTitle: "ContentInsetAdjustmentBehavior", enumList: "UIScrollViewContentInsetAdjustmentBehavior", patch: true, osVersion: 11)),
            ]),
            BlueprintSection(.UIScrollView.showsIndicator, title: "ShowsScrollIndicator", attributes: [
                BlueprintAttribute(.UIScrollView.ShowsIndicator.horizontal, AttributeInfo(className: "UIScrollView", fullTitle: "ShowsHorizontalScrollIndicator", briefTitle: "Horizontal", patch: false)),
                BlueprintAttribute(.UIScrollView.ShowsIndicator.vertical, AttributeInfo(className: "UIScrollView", fullTitle: "ShowsVerticalScrollIndicator", briefTitle: "Vertical", patch: false)),
            ]),
            BlueprintSection(.UIScrollView.bounce, title: "AlwaysBounce", attributes: [
                BlueprintAttribute(.UIScrollView.Bounce.horizontal, AttributeInfo(className: "UIScrollView", fullTitle: "AlwaysBounceHorizontal", briefTitle: "Horizontal", patch: false)),
                BlueprintAttribute(.UIScrollView.Bounce.vertical, AttributeInfo(className: "UIScrollView", fullTitle: "AlwaysBounceVertical", briefTitle: "Vertical", patch: false)),
            ]),
            BlueprintSection(.UIScrollView.scrollPaging, attributes: [
                BlueprintAttribute(.UIScrollView.ScrollPaging.scrollEnabled, AttributeInfo(className: "UIScrollView", fullTitle: "ScrollEnabled", getterString: "isScrollEnabled", patch: false)),
                BlueprintAttribute(.UIScrollView.ScrollPaging.pagingEnabled, AttributeInfo(className: "UIScrollView", fullTitle: "PagingEnabled", getterString: "isPagingEnabled", patch: false)),
            ]),
            BlueprintSection(.UIScrollView.contentTouches, attributes: [
                BlueprintAttribute(.UIScrollView.ContentTouches.delay, AttributeInfo(className: "UIScrollView", fullTitle: "DelaysContentTouches", patch: false)),
                BlueprintAttribute(.UIScrollView.ContentTouches.canCancel, AttributeInfo(className: "UIScrollView", fullTitle: "CanCancelContentTouches", patch: false)),
            ]),
            BlueprintSection(.UIScrollView.zoom, title: "Zoom", attributes: [
                BlueprintAttribute(.UIScrollView.Zoom.bounce, AttributeInfo(className: "UIScrollView", fullTitle: "BouncesZoom", patch: false)),
                BlueprintAttribute(.UIScrollView.Zoom.scale, AttributeInfo(className: "UIScrollView", fullTitle: "ZoomScale", briefTitle: "Scale", patch: true)),
                BlueprintAttribute(.UIScrollView.Zoom.minScale, AttributeInfo(className: "UIScrollView", fullTitle: "MinimumZoomScale", briefTitle: "MinScale", patch: false)),
                BlueprintAttribute(.UIScrollView.Zoom.maxScale, AttributeInfo(className: "UIScrollView", fullTitle: "MaximumZoomScale", briefTitle: "MaxScale", patch: false)),
            ]),
            BlueprintSection(.UIScrollView.contentAlignmentPoint, title: "ContentAlignmentPoint", attributes: [
                BlueprintAttribute(.UIScrollView.ContentAlignmentPoint.contentAlignmentPoint, AttributeInfo(className: "UIScrollView", fullTitle: "ContentAlignmentPoint", getterString: "contentAlignmentPoint", setterString: "setContentAlignmentPoint:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIScrollView.flags, title: "Flags", attributes: [
                BlueprintAttribute(.UIScrollView.Flags.automaticallyAdjustsScrollIndicatorInsets, AttributeInfo(className: "UIScrollView", fullTitle: "AutomaticallyAdjustsScrollIndicatorInsets", getterString: "automaticallyAdjustsScrollIndicatorInsets", setterString: "setAutomaticallyAdjustsScrollIndicatorInsets:", patch: true, revision: 1)),
                BlueprintAttribute(.UIScrollView.Flags.directionalLockEnabled, AttributeInfo(className: "UIScrollView", fullTitle: "DirectionalLockEnabled", getterString: "isDirectionalLockEnabled", setterString: "setDirectionalLockEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.UIScrollView.Flags.bounces, AttributeInfo(className: "UIScrollView", fullTitle: "Bounces", getterString: "bounces", setterString: "setBounces:", patch: true, revision: 1)),
                BlueprintAttribute(.UIScrollView.Flags.bouncesHorizontally, AttributeInfo(className: "UIScrollView", fullTitle: "BouncesHorizontally", getterString: "bouncesHorizontally", setterString: "setBouncesHorizontally:", patch: true, revision: 1)),
                BlueprintAttribute(.UIScrollView.Flags.bouncesVertically, AttributeInfo(className: "UIScrollView", fullTitle: "BouncesVertically", getterString: "bouncesVertically", setterString: "setBouncesVertically:", patch: true, revision: 1)),
                BlueprintAttribute(.UIScrollView.Flags.transfersHorizontalScrollingToParent, AttributeInfo(className: "UIScrollView", fullTitle: "TransfersHorizontalScrollingToParent", getterString: "transfersHorizontalScrollingToParent", setterString: "setTransfersHorizontalScrollingToParent:", patch: true, revision: 1)),
                BlueprintAttribute(.UIScrollView.Flags.transfersVerticalScrollingToParent, AttributeInfo(className: "UIScrollView", fullTitle: "TransfersVerticalScrollingToParent", getterString: "transfersVerticalScrollingToParent", setterString: "setTransfersVerticalScrollingToParent:", patch: true, revision: 1)),
                BlueprintAttribute(.UIScrollView.Flags.tracking, AttributeInfo(className: "UIScrollView", fullTitle: "Tracking", getterString: "isTracking", setterString: "", revision: 1)),
                BlueprintAttribute(.UIScrollView.Flags.dragging, AttributeInfo(className: "UIScrollView", fullTitle: "Dragging", getterString: "isDragging", setterString: "", revision: 1)),
                BlueprintAttribute(.UIScrollView.Flags.decelerating, AttributeInfo(className: "UIScrollView", fullTitle: "Decelerating", getterString: "isDecelerating", setterString: "", revision: 1)),
                BlueprintAttribute(.UIScrollView.Flags.scrollAnimating, AttributeInfo(className: "UIScrollView", fullTitle: "ScrollAnimating", getterString: "isScrollAnimating", setterString: "", revision: 1)),
                BlueprintAttribute(.UIScrollView.Flags.zooming, AttributeInfo(className: "UIScrollView", fullTitle: "Zooming", getterString: "isZooming", setterString: "", revision: 1)),
                BlueprintAttribute(.UIScrollView.Flags.zoomBouncing, AttributeInfo(className: "UIScrollView", fullTitle: "ZoomBouncing", getterString: "isZoomBouncing", setterString: "", revision: 1)),
                BlueprintAttribute(.UIScrollView.Flags.zoomAnimating, AttributeInfo(className: "UIScrollView", fullTitle: "ZoomAnimating", getterString: "isZoomAnimating", setterString: "", revision: 1)),
                BlueprintAttribute(.UIScrollView.Flags.scrollsToTop, AttributeInfo(className: "UIScrollView", fullTitle: "ScrollsToTop", getterString: "scrollsToTop", setterString: "setScrollsToTop:", patch: true, revision: 1)),
                BlueprintAttribute(.UIScrollView.Flags.allowsKeyboardScrolling, AttributeInfo(className: "UIScrollView", fullTitle: "AllowsKeyboardScrolling", getterString: "allowsKeyboardScrolling", setterString: "setAllowsKeyboardScrolling:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIScrollView.indicatorStyle, title: "IndicatorStyle", attributes: [
                BlueprintAttribute(.UIScrollView.IndicatorStyle.indicatorStyle, AttributeInfo(className: "UIScrollView", fullTitle: "IndicatorStyle", getterString: "indicatorStyle", setterString: "setIndicatorStyle:", enumList: "UIScrollViewIndicatorStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIScrollView.verticalScrollIndicatorInsets, title: "VerticalScrollIndicatorInsets", attributes: [
                BlueprintAttribute(.UIScrollView.VerticalScrollIndicatorInsets.verticalScrollIndicatorInsets, AttributeInfo(className: "UIScrollView", fullTitle: "VerticalScrollIndicatorInsets", getterString: "verticalScrollIndicatorInsets", setterString: "setVerticalScrollIndicatorInsets:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIScrollView.horizontalScrollIndicatorInsets, title: "HorizontalScrollIndicatorInsets", attributes: [
                BlueprintAttribute(.UIScrollView.HorizontalScrollIndicatorInsets.horizontalScrollIndicatorInsets, AttributeInfo(className: "UIScrollView", fullTitle: "HorizontalScrollIndicatorInsets", getterString: "horizontalScrollIndicatorInsets", setterString: "setHorizontalScrollIndicatorInsets:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIScrollView.decelerationRate, title: "DecelerationRate", attributes: [
                BlueprintAttribute(.UIScrollView.DecelerationRate.decelerationRate, AttributeInfo(className: "UIScrollView", fullTitle: "DecelerationRate", getterString: "decelerationRate", setterString: "setDecelerationRate:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIScrollView.indexDisplayMode, title: "IndexDisplayMode", attributes: [
                BlueprintAttribute(.UIScrollView.IndexDisplayMode.indexDisplayMode, AttributeInfo(className: "UIScrollView", fullTitle: "IndexDisplayMode", getterString: "indexDisplayMode", setterString: "setIndexDisplayMode:", enumList: "UIScrollViewIndexDisplayMode", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIScrollView.keyboardDismissMode, title: "KeyboardDismissMode", attributes: [
                BlueprintAttribute(.UIScrollView.KeyboardDismissMode.keyboardDismissMode, AttributeInfo(className: "UIScrollView", fullTitle: "KeyboardDismissMode", getterString: "keyboardDismissMode", setterString: "setKeyboardDismissMode:", enumList: "UIScrollViewKeyboardDismissMode", patch: true, revision: 1)),
            ]),
        ])

        static let uiTableViewGroup = BlueprintGroup(.uiTableView, title: "UITableView", on: .uiKit, sections: [
            BlueprintSection(.UITableView.style, title: "Style", attributes: [
                BlueprintAttribute(.UITableView.Style.style, AttributeInfo(className: "UITableView", fullTitle: "Style", setterString: "", enumList: "UITableViewStyle", patch: true)),
            ]),
            BlueprintSection(.UITableView.sectionsNumber, title: "NumberOfSections", attributes: [
                BlueprintAttribute(.UITableView.SectionsNumber.number, AttributeInfo(className: "UITableView", fullTitle: "NumberOfSections", setterString: "", patch: true)),
            ]),
            BlueprintSection(.UITableView.rowsNumber, title: "NumberOfRows", attributes: [
                BlueprintAttribute(.UITableView.RowsNumber.number, AttributeInfo(className: "UITableView", getterString: "lks_numberOfRows", setterString: "", objectValueType: .customObject)),
            ]),
            BlueprintSection(.UITableView.separatorStyle, title: "SeparatorStyle", attributes: [
                BlueprintAttribute(.UITableView.SeparatorStyle.style, AttributeInfo(className: "UITableView", fullTitle: "SeparatorStyle", enumList: "UITableViewCellSeparatorStyle", patch: true)),
            ]),
            BlueprintSection(.UITableView.separatorColor, title: "SeparatorColor", attributes: [
                BlueprintAttribute(.UITableView.SeparatorColor.color, AttributeInfo(className: "UITableView", fullTitle: "SeparatorColor", objectValueType: .uiColor, patch: true)),
            ]),
            BlueprintSection(.UITableView.separatorInset, title: "SeparatorInset", attributes: [
                BlueprintAttribute(.UITableView.SeparatorInset.inset, AttributeInfo(className: "UITableView", fullTitle: "SeparatorInset", patch: false)),
            ]),
            BlueprintSection(.UITableView.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UITableView.Behavior.prefetchingEnabled, AttributeInfo(className: "UITableView", fullTitle: "PrefetchingEnabled", getterString: "isPrefetchingEnabled", setterString: "setPrefetchingEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableView.Behavior.hasUncommittedUpdates, AttributeInfo(className: "UITableView", fullTitle: "HasUncommittedUpdates", getterString: "hasUncommittedUpdates", setterString: "", revision: 1)),
                BlueprintAttribute(.UITableView.Behavior.editing, AttributeInfo(className: "UITableView", fullTitle: "Editing", getterString: "isEditing", setterString: "setEditing:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableView.Behavior.allowsSelection, AttributeInfo(className: "UITableView", fullTitle: "AllowsSelection", getterString: "allowsSelection", setterString: "setAllowsSelection:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableView.Behavior.allowsSelectionDuringEditing, AttributeInfo(className: "UITableView", fullTitle: "AllowsSelectionDuringEditing", getterString: "allowsSelectionDuringEditing", setterString: "setAllowsSelectionDuringEditing:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableView.Behavior.allowsMultipleSelection, AttributeInfo(className: "UITableView", fullTitle: "AllowsMultipleSelection", getterString: "allowsMultipleSelection", setterString: "setAllowsMultipleSelection:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableView.Behavior.allowsMultipleSelectionDuringEditing, AttributeInfo(className: "UITableView", fullTitle: "AllowsMultipleSelectionDuringEditing", getterString: "allowsMultipleSelectionDuringEditing", setterString: "setAllowsMultipleSelectionDuringEditing:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableView.Behavior.cellLayoutMarginsFollowReadableWidth, AttributeInfo(className: "UITableView", fullTitle: "CellLayoutMarginsFollowReadableWidth", getterString: "cellLayoutMarginsFollowReadableWidth", setterString: "setCellLayoutMarginsFollowReadableWidth:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableView.Behavior.insetsContentViewsToSafeArea, AttributeInfo(className: "UITableView", fullTitle: "InsetsContentViewsToSafeArea", getterString: "insetsContentViewsToSafeArea", setterString: "setInsetsContentViewsToSafeArea:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableView.Behavior.remembersLastFocusedIndexPath, AttributeInfo(className: "UITableView", fullTitle: "RemembersLastFocusedIndexPath", getterString: "remembersLastFocusedIndexPath", setterString: "setRemembersLastFocusedIndexPath:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableView.Behavior.selectionFollowsFocus, AttributeInfo(className: "UITableView", fullTitle: "SelectionFollowsFocus", getterString: "selectionFollowsFocus", setterString: "setSelectionFollowsFocus:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableView.Behavior.allowsFocus, AttributeInfo(className: "UITableView", fullTitle: "AllowsFocus", getterString: "allowsFocus", setterString: "setAllowsFocus:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableView.Behavior.allowsFocusDuringEditing, AttributeInfo(className: "UITableView", fullTitle: "AllowsFocusDuringEditing", getterString: "allowsFocusDuringEditing", setterString: "setAllowsFocusDuringEditing:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableView.Behavior.dragInteractionEnabled, AttributeInfo(className: "UITableView", fullTitle: "DragInteractionEnabled", getterString: "dragInteractionEnabled", setterString: "setDragInteractionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableView.Behavior.hasActiveDrag, AttributeInfo(className: "UITableView", fullTitle: "HasActiveDrag", getterString: "hasActiveDrag", setterString: "", revision: 1)),
                BlueprintAttribute(.UITableView.Behavior.hasActiveDrop, AttributeInfo(className: "UITableView", fullTitle: "HasActiveDrop", getterString: "hasActiveDrop", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.UITableView.rowHeight, title: "RowHeight", attributes: [
                BlueprintAttribute(.UITableView.RowHeight.rowHeight, AttributeInfo(className: "UITableView", fullTitle: "RowHeight", getterString: "rowHeight", setterString: "setRowHeight:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableView.sectionHeaderHeight, title: "SectionHeaderHeight", attributes: [
                BlueprintAttribute(.UITableView.SectionHeaderHeight.sectionHeaderHeight, AttributeInfo(className: "UITableView", fullTitle: "SectionHeaderHeight", getterString: "sectionHeaderHeight", setterString: "setSectionHeaderHeight:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableView.sectionFooterHeight, title: "SectionFooterHeight", attributes: [
                BlueprintAttribute(.UITableView.SectionFooterHeight.sectionFooterHeight, AttributeInfo(className: "UITableView", fullTitle: "SectionFooterHeight", getterString: "sectionFooterHeight", setterString: "setSectionFooterHeight:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableView.estimatedRowHeight, title: "EstimatedRowHeight", attributes: [
                BlueprintAttribute(.UITableView.EstimatedRowHeight.estimatedRowHeight, AttributeInfo(className: "UITableView", fullTitle: "EstimatedRowHeight", getterString: "estimatedRowHeight", setterString: "setEstimatedRowHeight:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableView.estimatedSectionHeaderHeight, title: "EstimatedSectionHeaderHeight", attributes: [
                BlueprintAttribute(.UITableView.EstimatedSectionHeaderHeight.estimatedSectionHeaderHeight, AttributeInfo(className: "UITableView", fullTitle: "EstimatedSectionHeaderHeight", getterString: "estimatedSectionHeaderHeight", setterString: "setEstimatedSectionHeaderHeight:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableView.estimatedSectionFooterHeight, title: "EstimatedSectionFooterHeight", attributes: [
                BlueprintAttribute(.UITableView.EstimatedSectionFooterHeight.estimatedSectionFooterHeight, AttributeInfo(className: "UITableView", fullTitle: "EstimatedSectionFooterHeight", getterString: "estimatedSectionFooterHeight", setterString: "setEstimatedSectionFooterHeight:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableView.fillerRowHeight, title: "FillerRowHeight", attributes: [
                BlueprintAttribute(.UITableView.FillerRowHeight.fillerRowHeight, AttributeInfo(className: "UITableView", fullTitle: "FillerRowHeight", getterString: "fillerRowHeight", setterString: "setFillerRowHeight:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableView.sectionHeaderTopPadding, title: "SectionHeaderTopPadding", attributes: [
                BlueprintAttribute(.UITableView.SectionHeaderTopPadding.sectionHeaderTopPadding, AttributeInfo(className: "UITableView", fullTitle: "SectionHeaderTopPadding", getterString: "sectionHeaderTopPadding", setterString: "setSectionHeaderTopPadding:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableView.separatorInsetReference, title: "SeparatorInsetReference", attributes: [
                BlueprintAttribute(.UITableView.SeparatorInsetReference.separatorInsetReference, AttributeInfo(className: "UITableView", fullTitle: "SeparatorInsetReference", getterString: "separatorInsetReference", setterString: "setSeparatorInsetReference:", enumList: "UITableViewSeparatorInsetReference", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableView.selfSizingInvalidation, title: "SelfSizingInvalidation", attributes: [
                BlueprintAttribute(.UITableView.SelfSizingInvalidation.selfSizingInvalidation, AttributeInfo(className: "UITableView", fullTitle: "SelfSizingInvalidation", getterString: "selfSizingInvalidation", setterString: "setSelfSizingInvalidation:", enumList: "UITableViewSelfSizingInvalidation", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableView.indexPathsForSelectedRows, title: "IndexPathsForSelectedRows", attributes: [
                BlueprintAttribute(.UITableView.IndexPathsForSelectedRows.indexPathsForSelectedRows, AttributeInfo(className: "UITableView", fullTitle: "IndexPathsForSelectedRows", getterString: "indexPathsForSelectedRows", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(.UITableView.sectionIndexMinimumDisplayRowCount, title: "SectionIndexMinimumDisplayRowCount", attributes: [
                BlueprintAttribute(.UITableView.SectionIndexMinimumDisplayRowCount.sectionIndexMinimumDisplayRowCount, AttributeInfo(className: "UITableView", fullTitle: "SectionIndexMinimumDisplayRowCount", getterString: "sectionIndexMinimumDisplayRowCount", setterString: "setSectionIndexMinimumDisplayRowCount:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableView.colors, title: "Colors", attributes: [
                BlueprintAttribute(.UITableView.Colors.sectionIndexColor, AttributeInfo(className: "UITableView", fullTitle: "SectionIndexColor", getterString: "sectionIndexColor", setterString: "setSectionIndexColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.UITableView.Colors.sectionIndexBackgroundColor, AttributeInfo(className: "UITableView", fullTitle: "SectionIndexBackgroundColor", getterString: "sectionIndexBackgroundColor", setterString: "setSectionIndexBackgroundColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.UITableView.Colors.sectionIndexTrackingBackgroundColor, AttributeInfo(className: "UITableView", fullTitle: "SectionIndexTrackingBackgroundColor", getterString: "sectionIndexTrackingBackgroundColor", setterString: "setSectionIndexTrackingBackgroundColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UITableView.separatorEffect, title: "SeparatorEffect", attributes: [
                BlueprintAttribute(.UITableView.SeparatorEffect.separatorEffect, AttributeInfo(className: "UITableView", fullTitle: "SeparatorEffect", getterString: "separatorEffect", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.className))),
            ]),
            BlueprintSection(.UITableView.contentHuggingElements, title: "ContentHuggingElements", attributes: [
                BlueprintAttribute(.UITableView.ContentHuggingElements.contentHuggingElements, AttributeInfo(className: "UITableView", fullTitle: "ContentHuggingElements", getterString: "contentHuggingElements", setterString: "", revision: 1, presentation: .optionNames("UITableViewContentHuggingElements"))),
            ]),
        ])

        static let uiTextViewGroup = BlueprintGroup(.uiTextView, title: "UITextView", on: .uiKit, sections: [
            BlueprintSection(.UITextView.basic, attributes: [
                BlueprintAttribute(.UITextView.Basic.editable, AttributeInfo(className: "UITextView", fullTitle: "Editable", getterString: "isEditable", patch: false)),
                BlueprintAttribute(.UITextView.Basic.selectable, AttributeInfo(className: "UITextView", fullTitle: "Selectable", getterString: "isSelectable", patch: false)),
            ]),
            BlueprintSection(.UITextView.text, title: "Text", attributes: [
                BlueprintAttribute(.UITextView.Text.text, AttributeInfo(className: "UITextView", fullTitle: "Text", objectValueType: .nsString, patch: true)),
            ]),
            BlueprintSection(.UITextView.font, title: "Font", attributes: [
                BlueprintAttribute(.UITextView.Font.name, AttributeInfo(className: "UITextView", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", objectValueType: .nsString, patch: false)),
                BlueprintAttribute(.UITextView.Font.size, AttributeInfo(className: "UITextView", fullTitle: "FontSize", getterString: "lks_fontSize", setterString: "setLks_fontSize:", patch: true)),
            ]),
            BlueprintSection(.UITextView.textColor, title: "TextColor", attributes: [
                BlueprintAttribute(.UITextView.TextColor.color, AttributeInfo(className: "UITextView", fullTitle: "TextColor", objectValueType: .uiColor, patch: true)),
            ]),
            BlueprintSection(.UITextView.alignment, title: "TextAlignment", attributes: [
                BlueprintAttribute(.UITextView.Alignment.alignment, AttributeInfo(className: "UITextView", fullTitle: "TextAlignment", enumList: "NSTextAlignment", patch: true)),
            ]),
            BlueprintSection(.UITextView.containerInset, title: "ContainerInset", attributes: [
                BlueprintAttribute(.UITextView.ContainerInset.inset, AttributeInfo(className: "UITextView", fullTitle: "TextContainerInset", patch: true)),
            ]),
            BlueprintSection(.UITextView.dataDetectorTypes, title: "DataDetectorTypes", attributes: [
                BlueprintAttribute(.UITextView.DataDetectorTypes.dataDetectorTypes, AttributeInfo(className: "UITextView", fullTitle: "DataDetectorTypes", getterString: "dataDetectorTypes", setterString: "", revision: 1, presentation: .optionNames("UIDataDetectorTypes"))),
            ]),
            BlueprintSection(.UITextView.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UITextView.Behavior.allowsEditingTextAttributes, AttributeInfo(className: "UITextView", fullTitle: "AllowsEditingTextAttributes", getterString: "allowsEditingTextAttributes", setterString: "setAllowsEditingTextAttributes:", patch: true, revision: 1)),
                BlueprintAttribute(.UITextView.Behavior.clearsOnInsertion, AttributeInfo(className: "UITextView", fullTitle: "ClearsOnInsertion", getterString: "clearsOnInsertion", setterString: "setClearsOnInsertion:", patch: true, revision: 1)),
                BlueprintAttribute(.UITextView.Behavior.usesStandardTextScaling, AttributeInfo(className: "UITextView", fullTitle: "UsesStandardTextScaling", getterString: "usesStandardTextScaling", setterString: "setUsesStandardTextScaling:", patch: true, revision: 1)),
                BlueprintAttribute(.UITextView.Behavior.findInteractionEnabled, AttributeInfo(className: "UITextView", fullTitle: "FindInteractionEnabled", getterString: "isFindInteractionEnabled", setterString: "setFindInteractionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.UITextView.Behavior.writingToolsActive, AttributeInfo(className: "UITextView", fullTitle: "WritingToolsActive", getterString: "isWritingToolsActive", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.UITextView.borderStyle, title: "BorderStyle", attributes: [
                BlueprintAttribute(.UITextView.BorderStyle.borderStyle, AttributeInfo(className: "UITextView", fullTitle: "BorderStyle", getterString: "borderStyle", setterString: "setBorderStyle:", enumList: "UITextViewBorderStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITextView.writingToolsBehavior, title: "WritingToolsBehavior", attributes: [
                BlueprintAttribute(.UITextView.WritingToolsBehavior.writingToolsBehavior, AttributeInfo(className: "UITextView", fullTitle: "WritingToolsBehavior", getterString: "writingToolsBehavior", setterString: "setWritingToolsBehavior:", enumList: "UIWritingToolsBehavior", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITextView.allowedWritingToolsResultOptions, title: "AllowedWritingToolsResultOptions", attributes: [
                BlueprintAttribute(.UITextView.AllowedWritingToolsResultOptions.allowedWritingToolsResultOptions, AttributeInfo(className: "UITextView", fullTitle: "AllowedWritingToolsResultOptions", getterString: "allowedWritingToolsResultOptions", setterString: "", revision: 1, presentation: .optionNames("UIWritingToolsResultOptions"))),
            ]),
        ])

        static let uiTextFieldGroup = BlueprintGroup(.uiTextField, title: "UITextField", on: .uiKit, sections: [
            BlueprintSection(.UITextField.text, title: "Text", attributes: [
                BlueprintAttribute(.UITextField.Text.text, AttributeInfo(className: "UITextField", fullTitle: "Text", objectValueType: .nsString, patch: true)),
            ]),
            BlueprintSection(.UITextField.placeholder, title: "Placeholder", attributes: [
                BlueprintAttribute(.UITextField.Placeholder.placeholder, AttributeInfo(className: "UITextField", fullTitle: "Placeholder", objectValueType: .nsString, patch: true)),
            ]),
            BlueprintSection(.UITextField.font, title: "Font", attributes: [
                BlueprintAttribute(.UITextField.Font.name, AttributeInfo(className: "UITextField", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", objectValueType: .nsString, patch: false)),
                BlueprintAttribute(.UITextField.Font.size, AttributeInfo(className: "UITextField", fullTitle: "FontSize", getterString: "lks_fontSize", setterString: "setLks_fontSize:", patch: true)),
            ]),
            BlueprintSection(.UITextField.textColor, title: "TextColor", attributes: [
                BlueprintAttribute(.UITextField.TextColor.color, AttributeInfo(className: "UITextField", fullTitle: "TextColor", objectValueType: .uiColor, patch: true)),
            ]),
            BlueprintSection(.UITextField.alignment, title: "TextAlignment", attributes: [
                BlueprintAttribute(.UITextField.Alignment.alignment, AttributeInfo(className: "UITextField", fullTitle: "TextAlignment", enumList: "NSTextAlignment", patch: true)),
            ]),
            BlueprintSection(.UITextField.clears, attributes: [
                BlueprintAttribute(.UITextField.Clears.clearsOnBeginEditing, AttributeInfo(className: "UITextField", fullTitle: "ClearsOnBeginEditing", patch: false)),
                BlueprintAttribute(.UITextField.Clears.clearsOnInsertion, AttributeInfo(className: "UITextField", fullTitle: "ClearsOnInsertion", patch: false)),
            ]),
            BlueprintSection(.UITextField.canAdjustFont, attributes: [
                BlueprintAttribute(.UITextField.CanAdjustFont.canAdjustFont, AttributeInfo(className: "UITextField", fullTitle: "AdjustsFontSizeToFitWidth", patch: true)),
                BlueprintAttribute(.UITextField.CanAdjustFont.minSize, AttributeInfo(className: "UITextField", fullTitle: "MinimumFontSize", patch: true)),
            ]),
            BlueprintSection(.UITextField.clearButtonMode, title: "ClearButtonMode", attributes: [
                BlueprintAttribute(.UITextField.ClearButtonMode.mode, AttributeInfo(className: "UITextField", fullTitle: "ClearButtonMode", enumList: "UITextFieldViewMode", patch: false)),
            ]),
            BlueprintSection(.UITextField.uiSearchTextField, title: "UISearchTextField", attributes: [
                BlueprintAttribute(.UITextField.UISearchTextField.tokens, AttributeInfo(className: "UISearchTextField", fullTitle: "Tokens", getterString: "tokens", setterString: "", revision: 1, presentation: .count)),
                BlueprintAttribute(.UITextField.UISearchTextField.tokenBackgroundColor, AttributeInfo(className: "UISearchTextField", fullTitle: "TokenBackgroundColor", getterString: "tokenBackgroundColor", setterString: "setTokenBackgroundColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.UITextField.UISearchTextField.allowsDeletingTokens, AttributeInfo(className: "UISearchTextField", fullTitle: "AllowsDeletingTokens", getterString: "allowsDeletingTokens", setterString: "setAllowsDeletingTokens:", patch: true, revision: 1)),
                BlueprintAttribute(.UITextField.UISearchTextField.allowsCopyingTokens, AttributeInfo(className: "UISearchTextField", fullTitle: "AllowsCopyingTokens", getterString: "allowsCopyingTokens", setterString: "setAllowsCopyingTokens:", patch: true, revision: 1)),
                BlueprintAttribute(.UITextField.UISearchTextField.searchSuggestions, AttributeInfo(className: "UISearchTextField", fullTitle: "SearchSuggestions", getterString: "searchSuggestions", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(.UITextField.borderStyle, title: "BorderStyle", attributes: [
                BlueprintAttribute(.UITextField.BorderStyle.borderStyle, AttributeInfo(className: "UITextField", fullTitle: "BorderStyle", getterString: "borderStyle", setterString: "setBorderStyle:", enumList: "UITextBorderStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITextField.images, title: "Images", attributes: [
                BlueprintAttribute(.UITextField.Images.background, AttributeInfo(className: "UITextField", fullTitle: "Background", getterString: "background", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.UITextField.Images.disabledBackground, AttributeInfo(className: "UITextField", fullTitle: "DisabledBackground", getterString: "disabledBackground", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(.UITextField.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UITextField.Behavior.editing, AttributeInfo(className: "UITextField", fullTitle: "Editing", getterString: "isEditing", setterString: "", revision: 1)),
                BlueprintAttribute(.UITextField.Behavior.allowsEditingTextAttributes, AttributeInfo(className: "UITextField", fullTitle: "AllowsEditingTextAttributes", getterString: "allowsEditingTextAttributes", setterString: "setAllowsEditingTextAttributes:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITextField.leftViewMode, title: "LeftViewMode", attributes: [
                BlueprintAttribute(.UITextField.LeftViewMode.leftViewMode, AttributeInfo(className: "UITextField", fullTitle: "LeftViewMode", getterString: "leftViewMode", setterString: "setLeftViewMode:", enumList: "UITextFieldViewMode", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITextField.rightViewMode, title: "RightViewMode", attributes: [
                BlueprintAttribute(.UITextField.RightViewMode.rightViewMode, AttributeInfo(className: "UITextField", fullTitle: "RightViewMode", getterString: "rightViewMode", setterString: "setRightViewMode:", enumList: "UITextFieldViewMode", patch: true, revision: 1)),
            ]),
        ])

        static let uiWindowSceneGroup = BlueprintGroup(.uiWindowScene, title: "UIWindowScene", on: .uiKit, sections: [
            BlueprintSection(.UIWindowScene.state, title: "State", attributes: [
                BlueprintAttribute(.UIWindowScene.State.activationState, AttributeInfo(className: "UIWindowScene", fullTitle: "ActivationState", getterString: "activationState", setterString: "", enumList: "UISceneActivationState", patch: false)),
            ]),
            BlueprintSection(.UIWindowScene.title, title: "Title", attributes: [
                BlueprintAttribute(.UIWindowScene.Title.title, AttributeInfo(className: "UIWindowScene", fullTitle: "Title", objectValueType: .nsString, patch: true)),
                BlueprintAttribute(.UIWindowScene.Title.subtitle, AttributeInfo(className: "UIWindowScene", fullTitle: "Subtitle", objectValueType: .nsString, patch: true, osVersion: 15)),
            ]),
            BlueprintSection(.UIWindowScene.orientation, title: "Orientation", attributes: [
                BlueprintAttribute(.UIWindowScene.Orientation.interfaceOrientation, AttributeInfo(className: "UIWindowScene", fullTitle: "InterfaceOrientation", getterString: "lks_interfaceOrientation", setterString: "", enumList: "UIInterfaceOrientation", patch: false)),
            ]),
            BlueprintSection(.UIWindowScene.geometry, title: "Geometry", attributes: [
                // UIWindowSceneGeometry — every entry returns an object so that it can
                // disappear via hideIfNil on platforms and OS versions that lack it.
                BlueprintAttribute(.UIWindowScene.Geometry.systemFrame, AttributeInfo(className: "UIWindowScene", fullTitle: "SystemFrame", getterString: "lks_geometrySystemFrame", setterString: "", objectValueType: .cgRect, patch: false, hideIfNil: true, osVersion: 16)),
                BlueprintAttribute(.UIWindowScene.Geometry.interfaceOrientationLocked, AttributeInfo(className: "UIWindowScene", fullTitle: "InterfaceOrientationLocked", getterString: "lks_geometryInterfaceOrientationLocked", setterString: "", objectValueType: .bool, patch: false, hideIfNil: true, osVersion: 26)),
                BlueprintAttribute(.UIWindowScene.Geometry.interactivelyResizing, AttributeInfo(className: "UIWindowScene", fullTitle: "InteractivelyResizing", getterString: "lks_geometryInteractivelyResizing", setterString: "", objectValueType: .bool, patch: false, hideIfNil: true, osVersion: 26)),
            ]),
            BlueprintSection(.UIWindowScene.windows, title: "Windows", attributes: [
                BlueprintAttribute(.UIWindowScene.Windows.windowCount, AttributeInfo(className: "UIWindowScene", fullTitle: "WindowCount", getterString: "lks_windowCount", setterString: "", patch: false)),
                BlueprintAttribute(.UIWindowScene.Windows.keyWindowClassName, AttributeInfo(className: "UIWindowScene", fullTitle: "KeyWindowClassName", getterString: "lks_keyWindowClassName", setterString: "", objectValueType: .nsString, patch: false)),
            ]),
            BlueprintSection(.UIWindowScene.screen, title: "Screen", attributes: [
                BlueprintAttribute(.UIWindowScene.Screen.screenBounds, AttributeInfo(className: "UIWindowScene", fullTitle: "ScreenBounds", getterString: "lks_screenBounds", setterString: "", patch: false)),
                BlueprintAttribute(.UIWindowScene.Screen.screenScale, AttributeInfo(className: "UIWindowScene", fullTitle: "ScreenScale", getterString: "lks_screenScale", setterString: "", patch: false)),
            ]),
            BlueprintSection(.UIWindowScene.statusBar, title: "StatusBar", attributes: [
                BlueprintAttribute(.UIWindowScene.StatusBar.statusBarHidden, AttributeInfo(className: "UIWindowScene", fullTitle: "StatusBarHidden", getterString: "lks_statusBarHidden", setterString: "", patch: false)),
                BlueprintAttribute(.UIWindowScene.StatusBar.statusBarStyle, AttributeInfo(className: "UIWindowScene", fullTitle: "StatusBarStyle", getterString: "lks_statusBarStyle", setterString: "", enumList: "UIStatusBarStyle", patch: false)),
                BlueprintAttribute(.UIWindowScene.StatusBar.statusBarFrame, AttributeInfo(className: "UIWindowScene", fullTitle: "StatusBarFrame", getterString: "lks_statusBarFrame", setterString: "", patch: false)),
            ]),
            BlueprintSection(.UIWindowScene.sizeRestrictions, title: "SizeRestrictions", attributes: [
                // UISceneSizeRestrictions — nil on iPhone, so the whole section drops out there.
                BlueprintAttribute(.UIWindowScene.SizeRestrictions.minimumSize, AttributeInfo(className: "UIWindowScene", fullTitle: "MinimumSize", getterString: "lks_sizeRestrictionsMinimumSize", setterString: "", objectValueType: .cgSize, patch: false, hideIfNil: true)),
                BlueprintAttribute(.UIWindowScene.SizeRestrictions.maximumSize, AttributeInfo(className: "UIWindowScene", fullTitle: "MaximumSize", getterString: "lks_sizeRestrictionsMaximumSize", setterString: "", objectValueType: .cgSize, patch: false, hideIfNil: true)),
                BlueprintAttribute(.UIWindowScene.SizeRestrictions.allowsFullScreen, AttributeInfo(className: "UIWindowScene", fullTitle: "AllowsFullScreen", getterString: "lks_sizeRestrictionsAllowsFullScreen", setterString: "", objectValueType: .bool, patch: false, hideIfNil: true)),
            ]),
            BlueprintSection(.UIWindowScene.windowingBehaviors, title: "WindowingBehaviors", attributes: [
                // UISceneWindowingBehaviors — nil outside iPad multitasking and Catalyst.
                BlueprintAttribute(.UIWindowScene.WindowingBehaviors.closable, AttributeInfo(className: "UIWindowScene", fullTitle: "Closable", getterString: "lks_windowingBehaviorsClosable", setterString: "", objectValueType: .bool, patch: false, hideIfNil: true, osVersion: 16)),
                BlueprintAttribute(.UIWindowScene.WindowingBehaviors.miniaturizable, AttributeInfo(className: "UIWindowScene", fullTitle: "Miniaturizable", getterString: "lks_windowingBehaviorsMiniaturizable", setterString: "", objectValueType: .bool, patch: false, hideIfNil: true, osVersion: 16)),
                BlueprintAttribute(.UIWindowScene.WindowingBehaviors.fullScreen, AttributeInfo(className: "UIWindowScene", fullTitle: "FullScreen", getterString: "lks_fullScreen", setterString: "", objectValueType: .bool, patch: false, hideIfNil: true)),
            ]),
            BlueprintSection(.UIWindowScene.pointer, title: "Pointer", attributes: [
                BlueprintAttribute(.UIWindowScene.Pointer.locked, AttributeInfo(className: "UIWindowScene", fullTitle: "Locked", getterString: "lks_pointerLocked", setterString: "", objectValueType: .bool, patch: false, hideIfNil: true, osVersion: 14)),
            ]),
            BlueprintSection(.UIWindowScene.protection, title: "Protection", attributes: [
                BlueprintAttribute(.UIWindowScene.Protection.userAuthenticationEnabled, AttributeInfo(className: "UIWindowScene", fullTitle: "UserAuthenticationEnabled", getterString: "lks_systemProtectionUserAuthenticationEnabled", setterString: "", objectValueType: .bool, patch: false, hideIfNil: true, osVersion: 18)),
            ]),
            BlueprintSection(.UIWindowScene.traits, title: "Traits", attributes: [
                BlueprintAttribute(.UIWindowScene.Traits.userInterfaceStyle, AttributeInfo(className: "UIWindowScene", fullTitle: "UserInterfaceStyle", getterString: "lks_userInterfaceStyle", setterString: "", enumList: "UIUserInterfaceStyle", patch: false)),
                BlueprintAttribute(.UIWindowScene.Traits.horizontalSizeClass, AttributeInfo(className: "UIWindowScene", fullTitle: "HorizontalSizeClass", getterString: "lks_horizontalSizeClass", setterString: "", enumList: "UIUserInterfaceSizeClass", patch: false)),
                BlueprintAttribute(.UIWindowScene.Traits.verticalSizeClass, AttributeInfo(className: "UIWindowScene", fullTitle: "VerticalSizeClass", getterString: "lks_verticalSizeClass", setterString: "", enumList: "UIUserInterfaceSizeClass", patch: false)),
                BlueprintAttribute(.UIWindowScene.Traits.userInterfaceLevel, AttributeInfo(className: "UIWindowScene", fullTitle: "UserInterfaceLevel", getterString: "lks_userInterfaceLevel", setterString: "", enumList: "UIUserInterfaceLevel", patch: false, osVersion: 13)),
                BlueprintAttribute(.UIWindowScene.Traits.activeAppearance, AttributeInfo(className: "UIWindowScene", fullTitle: "ActiveAppearance", getterString: "lks_activeAppearance", setterString: "", enumList: "UIUserInterfaceActiveAppearance", patch: false, osVersion: 14)),
                BlueprintAttribute(.UIWindowScene.Traits.accessibilityContrast, AttributeInfo(className: "UIWindowScene", fullTitle: "AccessibilityContrast", getterString: "lks_accessibilityContrast", setterString: "", enumList: "UIAccessibilityContrast", patch: false, osVersion: 13)),
                BlueprintAttribute(.UIWindowScene.Traits.legibilityWeight, AttributeInfo(className: "UIWindowScene", fullTitle: "LegibilityWeight", getterString: "lks_legibilityWeight", setterString: "", enumList: "UILegibilityWeight", patch: false, osVersion: 13)),
                BlueprintAttribute(.UIWindowScene.Traits.displayScale, AttributeInfo(className: "UIWindowScene", fullTitle: "DisplayScale", getterString: "lks_traitDisplayScale", setterString: "", patch: false, osVersion: 13)),
                BlueprintAttribute(.UIWindowScene.Traits.displayGamut, AttributeInfo(className: "UIWindowScene", fullTitle: "DisplayGamut", getterString: "lks_displayGamut", setterString: "", enumList: "UIDisplayGamut", patch: false, osVersion: 13)),
                BlueprintAttribute(.UIWindowScene.Traits.userInterfaceIdiom, AttributeInfo(className: "UIWindowScene", fullTitle: "UserInterfaceIdiom", getterString: "lks_userInterfaceIdiom", setterString: "", enumList: "UIUserInterfaceIdiom", patch: false, osVersion: 13)),
                BlueprintAttribute(.UIWindowScene.Traits.layoutDirection, AttributeInfo(className: "UIWindowScene", fullTitle: "LayoutDirection", getterString: "lks_layoutDirection", setterString: "", enumList: "UITraitEnvironmentLayoutDirection", patch: false, osVersion: 13)),
                BlueprintAttribute(.UIWindowScene.Traits.preferredContentSizeCategory, AttributeInfo(className: "UIWindowScene", fullTitle: "PreferredContentSizeCategory", getterString: "lks_preferredContentSizeCategory", setterString: "", objectValueType: .nsString, patch: false, osVersion: 13)),
                BlueprintAttribute(.UIWindowScene.Traits.sceneCaptureState, AttributeInfo(className: "UIWindowScene", fullTitle: "SceneCaptureState", getterString: "lks_sceneCaptureState", setterString: "", enumList: "UISceneCaptureState", patch: false, osVersion: 17)),
                BlueprintAttribute(.UIWindowScene.Traits.imageDynamicRange, AttributeInfo(className: "UIWindowScene", fullTitle: "ImageDynamicRange", getterString: "lks_imageDynamicRange", setterString: "", enumList: "UIImageDynamicRange", patch: false, osVersion: 17)),
                BlueprintAttribute(.UIWindowScene.Traits.typesettingLanguage, AttributeInfo(className: "UIWindowScene", fullTitle: "TypesettingLanguage", getterString: "lks_typesettingLanguage", setterString: "", objectValueType: .nsString, patch: false, hideIfNil: true, osVersion: 17)),
            ]),
            BlueprintSection(.UIWindowScene.session, title: "Session", attributes: [
                BlueprintAttribute(.UIWindowScene.Session.persistentIdentifier, AttributeInfo(className: "UIWindowScene", fullTitle: "PersistentIdentifier", getterString: "lks_sessionPersistentIdentifier", setterString: "", objectValueType: .nsString, patch: false)),
                BlueprintAttribute(.UIWindowScene.Session.sessionRole, AttributeInfo(className: "UIWindowScene", fullTitle: "SessionRole", getterString: "lks_sessionRole", setterString: "", objectValueType: .nsString, patch: false)),
                BlueprintAttribute(.UIWindowScene.Session.stateRestorationActivityType, AttributeInfo(className: "UIWindowScene", fullTitle: "StateRestorationActivity", getterString: "lks_sessionStateRestorationActivityType", setterString: "", objectValueType: .nsString, patch: false, hideIfNil: true)),
                BlueprintAttribute(.UIWindowScene.Session.userInfo, AttributeInfo(className: "UIWindowScene", fullTitle: "UserInfo", getterString: "lks_sessionUserInfoJSONString", setterString: "", objectValueType: .json, patch: false, hideIfNil: true)),
            ]),
            BlueprintSection(.UIWindowScene.configuration, title: "Configuration", attributes: [
                // UISceneConfiguration — describes which classes and storyboard back
                // this scene. DelegateClass is the class declared in the configuration,
                // which is not necessarily the class of the delegate instance shown in
                // the Relation group; a mismatch between the two is worth noticing.
                BlueprintAttribute(.UIWindowScene.Configuration.name, AttributeInfo(className: "UIWindowScene", fullTitle: "Name", getterString: "lks_configurationName", setterString: "", objectValueType: .nsString, patch: false, hideIfNil: true)),
                BlueprintAttribute(.UIWindowScene.Configuration.sceneClass, AttributeInfo(className: "UIWindowScene", fullTitle: "SceneClass", getterString: "lks_configurationSceneClassName", setterString: "", objectValueType: .nsString, patch: false, hideIfNil: true)),
                BlueprintAttribute(.UIWindowScene.Configuration.delegateClass, AttributeInfo(className: "UIWindowScene", fullTitle: "DelegateClass", getterString: "lks_configurationDelegateClassName", setterString: "", objectValueType: .nsString, patch: false, hideIfNil: true)),
                BlueprintAttribute(.UIWindowScene.Configuration.storyboard, AttributeInfo(className: "UIWindowScene", fullTitle: "Storyboard", getterString: "lks_configurationStoryboardDescription", setterString: "", objectValueType: .nsString, patch: false, hideIfNil: true)),
            ]),
            BlueprintSection(.UIWindowScene.activationConditions, title: "ActivationConditions", attributes: [
                // UISceneActivationConditions — shown as the predicates' format strings.
                BlueprintAttribute(.UIWindowScene.ActivationConditions.canActivate, AttributeInfo(className: "UIWindowScene", fullTitle: "CanActivateForTargetContentIdentifier", briefTitle: "CanActivate", getterString: "lks_canActivateForTargetContentIdentifierPredicateFormat", setterString: "", objectValueType: .nsString, patch: false, hideIfNil: true)),
                BlueprintAttribute(.UIWindowScene.ActivationConditions.prefersToActivate, AttributeInfo(className: "UIWindowScene", fullTitle: "PrefersToActivateForTargetContentIdentifier", briefTitle: "PrefersToActivate", getterString: "lks_prefersToActivateForTargetContentIdentifierPredicateFormat", setterString: "", objectValueType: .nsString, patch: false, hideIfNil: true)),
            ]),
        ])

        static let uiTraitCollectionGroup = BlueprintGroup(.uiTraitCollection, title: "UITraitCollection", on: .uiKit, sections: [
            BlueprintSection(.UITraitCollection.appearance, title: "Appearance", attributes: [
                BlueprintAttribute(.UITraitCollection.Appearance.userInterfaceStyle, AttributeInfo(className: "UIView", fullTitle: "UserInterfaceStyle", getterString: "lks_traitCollection_userInterfaceStyle", setterString: "", enumList: "UIUserInterfaceStyle", patch: false, osVersion: 12)),
                BlueprintAttribute(.UITraitCollection.Appearance.userInterfaceLevel, AttributeInfo(className: "UIView", fullTitle: "UserInterfaceLevel", getterString: "lks_traitCollection_userInterfaceLevel", setterString: "", enumList: "UIUserInterfaceLevel", patch: false, osVersion: 13)),
                BlueprintAttribute(.UITraitCollection.Appearance.activeAppearance, AttributeInfo(className: "UIView", fullTitle: "ActiveAppearance", getterString: "lks_traitCollection_activeAppearance", setterString: "", enumList: "UIUserInterfaceActiveAppearance", patch: false, osVersion: 14)),
                BlueprintAttribute(.UITraitCollection.Appearance.accessibilityContrast, AttributeInfo(className: "UIView", fullTitle: "AccessibilityContrast", getterString: "lks_traitCollection_accessibilityContrast", setterString: "", enumList: "UIAccessibilityContrast", patch: false, osVersion: 13)),
                BlueprintAttribute(.UITraitCollection.Appearance.legibilityWeight, AttributeInfo(className: "UIView", fullTitle: "LegibilityWeight", getterString: "lks_traitCollection_legibilityWeight", setterString: "", enumList: "UILegibilityWeight", patch: false, osVersion: 13)),
            ]),
            BlueprintSection(.UITraitCollection.sizeClass, title: "SizeClass", attributes: [
                BlueprintAttribute(.UITraitCollection.SizeClass.horizontalSizeClass, AttributeInfo(className: "UIView", fullTitle: "HorizontalSizeClass", getterString: "lks_traitCollection_horizontalSizeClass", setterString: "", enumList: "UIUserInterfaceSizeClass", patch: false)),
                BlueprintAttribute(.UITraitCollection.SizeClass.verticalSizeClass, AttributeInfo(className: "UIView", fullTitle: "VerticalSizeClass", getterString: "lks_traitCollection_verticalSizeClass", setterString: "", enumList: "UIUserInterfaceSizeClass", patch: false)),
            ]),
            BlueprintSection(.UITraitCollection.display, title: "Display", attributes: [
                BlueprintAttribute(.UITraitCollection.Display.displayScale, AttributeInfo(className: "UIView", fullTitle: "DisplayScale", getterString: "lks_traitCollection_displayScale", setterString: "", patch: false)),
                BlueprintAttribute(.UITraitCollection.Display.displayGamut, AttributeInfo(className: "UIView", fullTitle: "DisplayGamut", getterString: "lks_traitCollection_displayGamut", setterString: "", enumList: "UIDisplayGamut", patch: false, osVersion: 10)),
                BlueprintAttribute(.UITraitCollection.Display.imageDynamicRange, AttributeInfo(className: "UIView", fullTitle: "ImageDynamicRange", getterString: "lks_traitCollection_imageDynamicRange", setterString: "", enumList: "UIImageDynamicRange", patch: false, osVersion: 17)),
            ]),
            BlueprintSection(.UITraitCollection.device, title: "Device", attributes: [
                BlueprintAttribute(.UITraitCollection.Device.userInterfaceIdiom, AttributeInfo(className: "UIView", fullTitle: "UserInterfaceIdiom", getterString: "lks_traitCollection_userInterfaceIdiom", setterString: "", enumList: "UIUserInterfaceIdiom", patch: false)),
                BlueprintAttribute(.UITraitCollection.Device.forceTouchCapability, AttributeInfo(className: "UIView", fullTitle: "ForceTouchCapability", getterString: "lks_traitCollection_forceTouchCapability", setterString: "", enumList: "UIForceTouchCapability", patch: false, osVersion: 9)),
            ]),
            BlueprintSection(.UITraitCollection.layout, title: "Layout", attributes: [
                BlueprintAttribute(.UITraitCollection.Layout.layoutDirection, AttributeInfo(className: "UIView", fullTitle: "LayoutDirection", getterString: "lks_traitCollection_layoutDirection", setterString: "", enumList: "UITraitEnvironmentLayoutDirection", patch: false, osVersion: 10)),
            ]),
            BlueprintSection(.UITraitCollection.content, title: "Content", attributes: [
                BlueprintAttribute(.UITraitCollection.Content.preferredContentSizeCategory, AttributeInfo(className: "UIView", fullTitle: "PreferredContentSizeCategory", getterString: "lks_traitCollection_preferredContentSizeCategory", setterString: "", objectValueType: .nsString, patch: false, osVersion: 10)),
                BlueprintAttribute(.UITraitCollection.Content.typesettingLanguage, AttributeInfo(className: "UIView", fullTitle: "TypesettingLanguage", getterString: "lks_traitCollection_typesettingLanguage", setterString: "", objectValueType: .nsString, patch: false, hideIfNil: true, osVersion: 17)),
            ]),
        ])

        static let uiSliderGroup = BlueprintGroup(.uiSlider, title: "UISlider", on: .uiKit, sections: [
            BlueprintSection(.UISlider.behavioralStyle, title: "BehavioralStyle", attributes: [
                BlueprintAttribute(.UISlider.BehavioralStyle.behavioralStyle, AttributeInfo(className: "UISlider", fullTitle: "BehavioralStyle", getterString: "behavioralStyle", setterString: "", enumList: "UIBehavioralStyle", revision: 1)),
            ]),
            BlueprintSection(.UISlider.preferredBehavioralStyle, title: "PreferredBehavioralStyle", attributes: [
                BlueprintAttribute(.UISlider.PreferredBehavioralStyle.preferredBehavioralStyle, AttributeInfo(className: "UISlider", fullTitle: "PreferredBehavioralStyle", getterString: "preferredBehavioralStyle", setterString: "setPreferredBehavioralStyle:", enumList: "UIBehavioralStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UISlider.value, title: "Value", attributes: [
                BlueprintAttribute(.UISlider.Value.value, AttributeInfo(className: "UISlider", fullTitle: "Value", getterString: "value", setterString: "setValue:", patch: true, revision: 1)),
                BlueprintAttribute(.UISlider.Value.minimumValue, AttributeInfo(className: "UISlider", fullTitle: "MinimumValue", getterString: "minimumValue", setterString: "setMinimumValue:", patch: true, revision: 1)),
                BlueprintAttribute(.UISlider.Value.maximumValue, AttributeInfo(className: "UISlider", fullTitle: "MaximumValue", getterString: "maximumValue", setterString: "setMaximumValue:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UISlider.images, title: "Images", attributes: [
                BlueprintAttribute(.UISlider.Images.minimumValueImage, AttributeInfo(className: "UISlider", fullTitle: "MinimumValueImage", getterString: "minimumValueImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.UISlider.Images.maximumValueImage, AttributeInfo(className: "UISlider", fullTitle: "MaximumValueImage", getterString: "maximumValueImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.UISlider.Images.currentThumbImage, AttributeInfo(className: "UISlider", fullTitle: "CurrentThumbImage", getterString: "currentThumbImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.UISlider.Images.currentMinimumTrackImage, AttributeInfo(className: "UISlider", fullTitle: "CurrentMinimumTrackImage", getterString: "currentMinimumTrackImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.UISlider.Images.currentMaximumTrackImage, AttributeInfo(className: "UISlider", fullTitle: "CurrentMaximumTrackImage", getterString: "currentMaximumTrackImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(.UISlider.continuous, title: "Continuous", attributes: [
                BlueprintAttribute(.UISlider.Continuous.continuous, AttributeInfo(className: "UISlider", fullTitle: "Continuous", getterString: "isContinuous", setterString: "setContinuous:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UISlider.sliderStyle, title: "SliderStyle", attributes: [
                BlueprintAttribute(.UISlider.SliderStyle.sliderStyle, AttributeInfo(className: "UISlider", fullTitle: "SliderStyle", getterString: "sliderStyle", setterString: "setSliderStyle:", enumList: "UISliderStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UISlider.colors, title: "Colors", attributes: [
                BlueprintAttribute(.UISlider.Colors.minimumTrackTintColor, AttributeInfo(className: "UISlider", fullTitle: "MinimumTrackTintColor", getterString: "minimumTrackTintColor", setterString: "setMinimumTrackTintColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.UISlider.Colors.maximumTrackTintColor, AttributeInfo(className: "UISlider", fullTitle: "MaximumTrackTintColor", getterString: "maximumTrackTintColor", setterString: "setMaximumTrackTintColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.UISlider.Colors.thumbTintColor, AttributeInfo(className: "UISlider", fullTitle: "ThumbTintColor", getterString: "thumbTintColor", setterString: "setThumbTintColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
        ])


        static let uiStepperGroup = BlueprintGroup(.uiStepper, title: "UIStepper", on: .uiKit, sections: [
            BlueprintSection(.UIStepper.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UIStepper.Behavior.continuous, AttributeInfo(className: "UIStepper", fullTitle: "Continuous", getterString: "isContinuous", setterString: "setContinuous:", patch: true, revision: 1)),
                BlueprintAttribute(.UIStepper.Behavior.autorepeat, AttributeInfo(className: "UIStepper", fullTitle: "Autorepeat", getterString: "autorepeat", setterString: "setAutorepeat:", patch: true, revision: 1)),
                BlueprintAttribute(.UIStepper.Behavior.wraps, AttributeInfo(className: "UIStepper", fullTitle: "Wraps", getterString: "wraps", setterString: "setWraps:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIStepper.value, title: "Value", attributes: [
                BlueprintAttribute(.UIStepper.Value.value, AttributeInfo(className: "UIStepper", fullTitle: "Value", getterString: "value", setterString: "setValue:", patch: true, revision: 1)),
                BlueprintAttribute(.UIStepper.Value.minimumValue, AttributeInfo(className: "UIStepper", fullTitle: "MinimumValue", getterString: "minimumValue", setterString: "setMinimumValue:", patch: true, revision: 1)),
                BlueprintAttribute(.UIStepper.Value.maximumValue, AttributeInfo(className: "UIStepper", fullTitle: "MaximumValue", getterString: "maximumValue", setterString: "setMaximumValue:", patch: true, revision: 1)),
                BlueprintAttribute(.UIStepper.Value.stepValue, AttributeInfo(className: "UIStepper", fullTitle: "StepValue", getterString: "stepValue", setterString: "setStepValue:", patch: true, revision: 1)),
            ]),
        ])


        static let uiSwitchGroup = BlueprintGroup(.uiSwitch, title: "UISwitch", on: .uiKit, sections: [
            BlueprintSection(.UISwitch.colors, title: "Colors", attributes: [
                BlueprintAttribute(.UISwitch.Colors.onTintColor, AttributeInfo(className: "UISwitch", fullTitle: "OnTintColor", getterString: "onTintColor", setterString: "setOnTintColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.UISwitch.Colors.thumbTintColor, AttributeInfo(className: "UISwitch", fullTitle: "ThumbTintColor", getterString: "thumbTintColor", setterString: "setThumbTintColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UISwitch.images, title: "Images", attributes: [
                BlueprintAttribute(.UISwitch.Images.onImage, AttributeInfo(className: "UISwitch", fullTitle: "OnImage", getterString: "onImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.UISwitch.Images.offImage, AttributeInfo(className: "UISwitch", fullTitle: "OffImage", getterString: "offImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(.UISwitch.title, title: "Title", attributes: [
                BlueprintAttribute(.UISwitch.Title.title, AttributeInfo(className: "UISwitch", fullTitle: "Title", getterString: "title", setterString: "setTitle:", objectValueType: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UISwitch.style, title: "Style", attributes: [
                BlueprintAttribute(.UISwitch.Style.style, AttributeInfo(className: "UISwitch", fullTitle: "Style", getterString: "style", setterString: "", enumList: "UISwitchStyle", revision: 1)),
            ]),
            BlueprintSection(.UISwitch.preferredStyle, title: "PreferredStyle", attributes: [
                BlueprintAttribute(.UISwitch.PreferredStyle.preferredStyle, AttributeInfo(className: "UISwitch", fullTitle: "PreferredStyle", getterString: "preferredStyle", setterString: "setPreferredStyle:", enumList: "UISwitchStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UISwitch.on, title: "On", attributes: [
                BlueprintAttribute(.UISwitch.On.on, AttributeInfo(className: "UISwitch", fullTitle: "On", getterString: "isOn", setterString: "setOn:", patch: true, revision: 1)),
            ]),
        ])


        static let uiSegmentedControlGroup = BlueprintGroup(.uiSegmentedControl, title: "UISegmentedControl", on: .uiKit, sections: [
            BlueprintSection(.UISegmentedControl.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UISegmentedControl.Behavior.momentary, AttributeInfo(className: "UISegmentedControl", fullTitle: "Momentary", getterString: "isMomentary", setterString: "setMomentary:", patch: true, revision: 1)),
                BlueprintAttribute(.UISegmentedControl.Behavior.apportionsSegmentWidthsByContent, AttributeInfo(className: "UISegmentedControl", fullTitle: "ApportionsSegmentWidthsByContent", getterString: "apportionsSegmentWidthsByContent", setterString: "setApportionsSegmentWidthsByContent:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UISegmentedControl.numberOfSegments, title: "NumberOfSegments", attributes: [
                BlueprintAttribute(.UISegmentedControl.NumberOfSegments.numberOfSegments, AttributeInfo(className: "UISegmentedControl", fullTitle: "NumberOfSegments", getterString: "numberOfSegments", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.UISegmentedControl.selectedSegmentIndex, title: "SelectedSegmentIndex", attributes: [
                BlueprintAttribute(.UISegmentedControl.SelectedSegmentIndex.selectedSegmentIndex, AttributeInfo(className: "UISegmentedControl", fullTitle: "SelectedSegmentIndex", getterString: "selectedSegmentIndex", setterString: "setSelectedSegmentIndex:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UISegmentedControl.selectedSegmentTintColor, title: "SelectedSegmentTintColor", attributes: [
                BlueprintAttribute(.UISegmentedControl.SelectedSegmentTintColor.selectedSegmentTintColor, AttributeInfo(className: "UISegmentedControl", fullTitle: "SelectedSegmentTintColor", getterString: "selectedSegmentTintColor", setterString: "setSelectedSegmentTintColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
        ])


        static let uiProgressViewGroup = BlueprintGroup(.uiProgressView, title: "UIProgressView", on: .uiKit, sections: [
            BlueprintSection(.UIProgressView.progressViewStyle, title: "ProgressViewStyle", attributes: [
                BlueprintAttribute(.UIProgressView.ProgressViewStyle.progressViewStyle, AttributeInfo(className: "UIProgressView", fullTitle: "ProgressViewStyle", getterString: "progressViewStyle", setterString: "setProgressViewStyle:", enumList: "UIProgressViewStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIProgressView.progress, title: "Progress", attributes: [
                BlueprintAttribute(.UIProgressView.Progress.progress, AttributeInfo(className: "UIProgressView", fullTitle: "Progress", getterString: "progress", setterString: "setProgress:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIProgressView.colors, title: "Colors", attributes: [
                BlueprintAttribute(.UIProgressView.Colors.progressTintColor, AttributeInfo(className: "UIProgressView", fullTitle: "ProgressTintColor", getterString: "progressTintColor", setterString: "setProgressTintColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.UIProgressView.Colors.trackTintColor, AttributeInfo(className: "UIProgressView", fullTitle: "TrackTintColor", getterString: "trackTintColor", setterString: "setTrackTintColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UIProgressView.images, title: "Images", attributes: [
                BlueprintAttribute(.UIProgressView.Images.progressImage, AttributeInfo(className: "UIProgressView", fullTitle: "ProgressImage", getterString: "progressImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.UIProgressView.Images.trackImage, AttributeInfo(className: "UIProgressView", fullTitle: "TrackImage", getterString: "trackImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
        ])


        static let uiActivityIndicatorViewGroup = BlueprintGroup(.uiActivityIndicatorView, title: "UIActivityIndicatorView", on: .uiKit, sections: [
            BlueprintSection(.UIActivityIndicatorView.activityIndicatorViewStyle, title: "ActivityIndicatorViewStyle", attributes: [
                BlueprintAttribute(.UIActivityIndicatorView.ActivityIndicatorViewStyle.activityIndicatorViewStyle, AttributeInfo(className: "UIActivityIndicatorView", fullTitle: "ActivityIndicatorViewStyle", getterString: "activityIndicatorViewStyle", setterString: "setActivityIndicatorViewStyle:", enumList: "UIActivityIndicatorViewStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIActivityIndicatorView.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UIActivityIndicatorView.Behavior.hidesWhenStopped, AttributeInfo(className: "UIActivityIndicatorView", fullTitle: "HidesWhenStopped", getterString: "hidesWhenStopped", setterString: "setHidesWhenStopped:", patch: true, revision: 1)),
                BlueprintAttribute(.UIActivityIndicatorView.Behavior.animating, AttributeInfo(className: "UIActivityIndicatorView", fullTitle: "Animating", getterString: "isAnimating", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.UIActivityIndicatorView.color, title: "Color", attributes: [
                BlueprintAttribute(.UIActivityIndicatorView.Color.color, AttributeInfo(className: "UIActivityIndicatorView", fullTitle: "Color", getterString: "color", setterString: "setColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
        ])


        static let uiPageControlGroup = BlueprintGroup(.uiPageControl, title: "UIPageControl", on: .uiKit, sections: [
            BlueprintSection(.UIPageControl.numberOfPages, title: "NumberOfPages", attributes: [
                BlueprintAttribute(.UIPageControl.NumberOfPages.numberOfPages, AttributeInfo(className: "UIPageControl", fullTitle: "NumberOfPages", getterString: "numberOfPages", setterString: "setNumberOfPages:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIPageControl.currentPage, title: "CurrentPage", attributes: [
                BlueprintAttribute(.UIPageControl.CurrentPage.currentPage, AttributeInfo(className: "UIPageControl", fullTitle: "CurrentPage", getterString: "currentPage", setterString: "setCurrentPage:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIPageControl.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UIPageControl.Behavior.hidesForSinglePage, AttributeInfo(className: "UIPageControl", fullTitle: "HidesForSinglePage", getterString: "hidesForSinglePage", setterString: "setHidesForSinglePage:", patch: true, revision: 1)),
                BlueprintAttribute(.UIPageControl.Behavior.allowsContinuousInteraction, AttributeInfo(className: "UIPageControl", fullTitle: "AllowsContinuousInteraction", getterString: "allowsContinuousInteraction", setterString: "setAllowsContinuousInteraction:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIPageControl.colors, title: "Colors", attributes: [
                BlueprintAttribute(.UIPageControl.Colors.pageIndicatorTintColor, AttributeInfo(className: "UIPageControl", fullTitle: "PageIndicatorTintColor", getterString: "pageIndicatorTintColor", setterString: "setPageIndicatorTintColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.UIPageControl.Colors.currentPageIndicatorTintColor, AttributeInfo(className: "UIPageControl", fullTitle: "CurrentPageIndicatorTintColor", getterString: "currentPageIndicatorTintColor", setterString: "setCurrentPageIndicatorTintColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UIPageControl.backgroundStyle, title: "BackgroundStyle", attributes: [
                BlueprintAttribute(.UIPageControl.BackgroundStyle.backgroundStyle, AttributeInfo(className: "UIPageControl", fullTitle: "BackgroundStyle", getterString: "backgroundStyle", setterString: "setBackgroundStyle:", enumList: "UIPageControlBackgroundStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIPageControl.direction, title: "Direction", attributes: [
                BlueprintAttribute(.UIPageControl.Direction.direction, AttributeInfo(className: "UIPageControl", fullTitle: "Direction", getterString: "direction", setterString: "setDirection:", enumList: "UIPageControlDirection", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIPageControl.interactionState, title: "InteractionState", attributes: [
                BlueprintAttribute(.UIPageControl.InteractionState.interactionState, AttributeInfo(className: "UIPageControl", fullTitle: "InteractionState", getterString: "interactionState", setterString: "", enumList: "UIPageControlInteractionState", revision: 1)),
            ]),
            BlueprintSection(.UIPageControl.images, title: "Images", attributes: [
                BlueprintAttribute(.UIPageControl.Images.preferredIndicatorImage, AttributeInfo(className: "UIPageControl", fullTitle: "PreferredIndicatorImage", getterString: "preferredIndicatorImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.UIPageControl.Images.preferredCurrentPageIndicatorImage, AttributeInfo(className: "UIPageControl", fullTitle: "PreferredCurrentPageIndicatorImage", getterString: "preferredCurrentPageIndicatorImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
        ])


        static let uiDatePickerGroup = BlueprintGroup(.uiDatePicker, title: "UIDatePicker", on: .uiKit, sections: [
            BlueprintSection(.UIDatePicker.datePickerMode, title: "DatePickerMode", attributes: [
                BlueprintAttribute(.UIDatePicker.DatePickerMode.datePickerMode, AttributeInfo(className: "UIDatePicker", fullTitle: "DatePickerMode", getterString: "datePickerMode", setterString: "setDatePickerMode:", enumList: "UIDatePickerMode", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIDatePicker.locale, title: "Locale", attributes: [
                BlueprintAttribute(.UIDatePicker.Locale.locale, AttributeInfo(className: "UIDatePicker", fullTitle: "Locale", getterString: "locale", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.locale))),
            ]),
            BlueprintSection(.UIDatePicker.calendar, title: "Calendar", attributes: [
                BlueprintAttribute(.UIDatePicker.Calendar.calendar, AttributeInfo(className: "UIDatePicker", fullTitle: "Calendar", getterString: "calendar", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.calendar))),
            ]),
            BlueprintSection(.UIDatePicker.timeZone, title: "TimeZone", attributes: [
                BlueprintAttribute(.UIDatePicker.TimeZone.timeZone, AttributeInfo(className: "UIDatePicker", fullTitle: "TimeZone", getterString: "timeZone", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.timeZone))),
            ]),
            BlueprintSection(.UIDatePicker.date, title: "Date", attributes: [
                BlueprintAttribute(.UIDatePicker.Date.date, AttributeInfo(className: "UIDatePicker", fullTitle: "Date", getterString: "date", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.date))),
            ]),
            BlueprintSection(.UIDatePicker.minimumDate, title: "MinimumDate", attributes: [
                BlueprintAttribute(.UIDatePicker.MinimumDate.minimumDate, AttributeInfo(className: "UIDatePicker", fullTitle: "MinimumDate", getterString: "minimumDate", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.date))),
            ]),
            BlueprintSection(.UIDatePicker.maximumDate, title: "MaximumDate", attributes: [
                BlueprintAttribute(.UIDatePicker.MaximumDate.maximumDate, AttributeInfo(className: "UIDatePicker", fullTitle: "MaximumDate", getterString: "maximumDate", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.date))),
            ]),
            BlueprintSection(.UIDatePicker.countDownDuration, title: "CountDownDuration", attributes: [
                BlueprintAttribute(.UIDatePicker.CountDownDuration.countDownDuration, AttributeInfo(className: "UIDatePicker", fullTitle: "CountDownDuration", getterString: "countDownDuration", setterString: "setCountDownDuration:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIDatePicker.minuteInterval, title: "MinuteInterval", attributes: [
                BlueprintAttribute(.UIDatePicker.MinuteInterval.minuteInterval, AttributeInfo(className: "UIDatePicker", fullTitle: "MinuteInterval", getterString: "minuteInterval", setterString: "setMinuteInterval:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIDatePicker.preferredDatePickerStyle, title: "PreferredDatePickerStyle", attributes: [
                BlueprintAttribute(.UIDatePicker.PreferredDatePickerStyle.preferredDatePickerStyle, AttributeInfo(className: "UIDatePicker", fullTitle: "PreferredDatePickerStyle", getterString: "preferredDatePickerStyle", setterString: "setPreferredDatePickerStyle:", enumList: "UIDatePickerStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIDatePicker.datePickerStyle, title: "DatePickerStyle", attributes: [
                BlueprintAttribute(.UIDatePicker.DatePickerStyle.datePickerStyle, AttributeInfo(className: "UIDatePicker", fullTitle: "DatePickerStyle", getterString: "datePickerStyle", setterString: "", enumList: "UIDatePickerStyle", revision: 1)),
            ]),
            BlueprintSection(.UIDatePicker.roundsToMinuteInterval, title: "RoundsToMinuteInterval", attributes: [
                BlueprintAttribute(.UIDatePicker.RoundsToMinuteInterval.roundsToMinuteInterval, AttributeInfo(className: "UIDatePicker", fullTitle: "RoundsToMinuteInterval", getterString: "roundsToMinuteInterval", setterString: "setRoundsToMinuteInterval:", patch: true, revision: 1)),
            ]),
        ])


        static let uiColorWellGroup = BlueprintGroup(.uiColorWell, title: "UIColorWell", on: .uiKit, sections: [
            BlueprintSection(.UIColorWell.title, title: "Title", attributes: [
                BlueprintAttribute(.UIColorWell.Title.title, AttributeInfo(className: "UIColorWell", fullTitle: "Title", getterString: "title", setterString: "setTitle:", objectValueType: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UIColorWell.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UIColorWell.Behavior.supportsAlpha, AttributeInfo(className: "UIColorWell", fullTitle: "SupportsAlpha", getterString: "supportsAlpha", setterString: "setSupportsAlpha:", patch: true, revision: 1)),
                BlueprintAttribute(.UIColorWell.Behavior.supportsEyedropper, AttributeInfo(className: "UIColorWell", fullTitle: "SupportsEyedropper", getterString: "supportsEyedropper", setterString: "setSupportsEyedropper:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIColorWell.selectedColor, title: "SelectedColor", attributes: [
                BlueprintAttribute(.UIColorWell.SelectedColor.selectedColor, AttributeInfo(className: "UIColorWell", fullTitle: "SelectedColor", getterString: "selectedColor", setterString: "setSelectedColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UIColorWell.maximumLinearExposure, title: "MaximumLinearExposure", attributes: [
                BlueprintAttribute(.UIColorWell.MaximumLinearExposure.maximumLinearExposure, AttributeInfo(className: "UIColorWell", fullTitle: "MaximumLinearExposure", getterString: "maximumLinearExposure", setterString: "setMaximumLinearExposure:", patch: true, revision: 1)),
            ]),
        ])


        static let uiRefreshControlGroup = BlueprintGroup(.uiRefreshControl, title: "UIRefreshControl", on: .uiKit, sections: [
            BlueprintSection(.UIRefreshControl.refreshing, title: "Refreshing", attributes: [
                BlueprintAttribute(.UIRefreshControl.Refreshing.refreshing, AttributeInfo(className: "UIRefreshControl", fullTitle: "Refreshing", getterString: "isRefreshing", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.UIRefreshControl.attributedTitle, title: "AttributedTitle", attributes: [
                BlueprintAttribute(.UIRefreshControl.AttributedTitle.attributedTitle, AttributeInfo(className: "UIRefreshControl", fullTitle: "AttributedTitle", getterString: "attributedTitle", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.attributedString))),
            ]),
        ])


        static let uiPickerViewGroup = BlueprintGroup(.uiPickerView, title: "UIPickerView", on: .uiKit, sections: [
            BlueprintSection(.UIPickerView.numberOfComponents, title: "NumberOfComponents", attributes: [
                BlueprintAttribute(.UIPickerView.NumberOfComponents.numberOfComponents, AttributeInfo(className: "UIPickerView", fullTitle: "NumberOfComponents", getterString: "numberOfComponents", setterString: "", revision: 1)),
            ]),
        ])


        static let uiCalendarViewGroup = BlueprintGroup(.uiCalendarView, title: "UICalendarView", on: .uiKit, sections: [
            BlueprintSection(.UICalendarView.locale, title: "Locale", attributes: [
                BlueprintAttribute(.UICalendarView.Locale.locale, AttributeInfo(className: "UICalendarView", fullTitle: "Locale", getterString: "locale", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.locale))),
            ]),
            BlueprintSection(.UICalendarView.calendar, title: "Calendar", attributes: [
                BlueprintAttribute(.UICalendarView.Calendar.calendar, AttributeInfo(className: "UICalendarView", fullTitle: "Calendar", getterString: "calendar", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.calendar))),
            ]),
            BlueprintSection(.UICalendarView.timeZone, title: "TimeZone", attributes: [
                BlueprintAttribute(.UICalendarView.TimeZone.timeZone, AttributeInfo(className: "UICalendarView", fullTitle: "TimeZone", getterString: "timeZone", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.timeZone))),
            ]),
            BlueprintSection(.UICalendarView.fontDesign, title: "FontDesign", attributes: [
                BlueprintAttribute(.UICalendarView.FontDesign.fontDesign, AttributeInfo(className: "UICalendarView", fullTitle: "FontDesign", getterString: "fontDesign", setterString: "", objectValueType: .nsString, revision: 1)),
            ]),
            BlueprintSection(.UICalendarView.wantsDateDecorations, title: "WantsDateDecorations", attributes: [
                BlueprintAttribute(.UICalendarView.WantsDateDecorations.wantsDateDecorations, AttributeInfo(className: "UICalendarView", fullTitle: "WantsDateDecorations", getterString: "wantsDateDecorations", setterString: "setWantsDateDecorations:", patch: true, revision: 1)),
            ]),
        ])


        static let uiPasteControlGroup = BlueprintGroup(.uiPasteControl, title: "UIPasteControl", on: .uiKit, sections: [
            BlueprintSection(.UIPasteControl.configuration, title: "Configuration", attributes: [
                BlueprintAttribute(.UIPasteControl.Configuration.configuration, AttributeInfo(className: "UIPasteControl", fullTitle: "Configuration", getterString: "configuration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.configuration))),
            ]),
        ])

        static let uiCollectionViewGroup = BlueprintGroup(.uiCollectionView, title: "UICollectionView", on: .uiKit, sections: [
            BlueprintSection(.UICollectionView.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UICollectionView.Behavior.prefetchingEnabled, AttributeInfo(className: "UICollectionView", fullTitle: "PrefetchingEnabled", getterString: "isPrefetchingEnabled", setterString: "setPrefetchingEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.UICollectionView.Behavior.dragInteractionEnabled, AttributeInfo(className: "UICollectionView", fullTitle: "DragInteractionEnabled", getterString: "dragInteractionEnabled", setterString: "setDragInteractionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.UICollectionView.Behavior.allowsSelection, AttributeInfo(className: "UICollectionView", fullTitle: "AllowsSelection", getterString: "allowsSelection", setterString: "setAllowsSelection:", patch: true, revision: 1)),
                BlueprintAttribute(.UICollectionView.Behavior.allowsMultipleSelection, AttributeInfo(className: "UICollectionView", fullTitle: "AllowsMultipleSelection", getterString: "allowsMultipleSelection", setterString: "setAllowsMultipleSelection:", patch: true, revision: 1)),
                BlueprintAttribute(.UICollectionView.Behavior.hasUncommittedUpdates, AttributeInfo(className: "UICollectionView", fullTitle: "HasUncommittedUpdates", getterString: "hasUncommittedUpdates", setterString: "", revision: 1)),
                BlueprintAttribute(.UICollectionView.Behavior.remembersLastFocusedIndexPath, AttributeInfo(className: "UICollectionView", fullTitle: "RemembersLastFocusedIndexPath", getterString: "remembersLastFocusedIndexPath", setterString: "setRemembersLastFocusedIndexPath:", patch: true, revision: 1)),
                BlueprintAttribute(.UICollectionView.Behavior.selectionFollowsFocus, AttributeInfo(className: "UICollectionView", fullTitle: "SelectionFollowsFocus", getterString: "selectionFollowsFocus", setterString: "setSelectionFollowsFocus:", patch: true, revision: 1)),
                BlueprintAttribute(.UICollectionView.Behavior.allowsFocus, AttributeInfo(className: "UICollectionView", fullTitle: "AllowsFocus", getterString: "allowsFocus", setterString: "setAllowsFocus:", patch: true, revision: 1)),
                BlueprintAttribute(.UICollectionView.Behavior.allowsFocusDuringEditing, AttributeInfo(className: "UICollectionView", fullTitle: "AllowsFocusDuringEditing", getterString: "allowsFocusDuringEditing", setterString: "setAllowsFocusDuringEditing:", patch: true, revision: 1)),
                BlueprintAttribute(.UICollectionView.Behavior.hasActiveDrag, AttributeInfo(className: "UICollectionView", fullTitle: "HasActiveDrag", getterString: "hasActiveDrag", setterString: "", revision: 1)),
                BlueprintAttribute(.UICollectionView.Behavior.hasActiveDrop, AttributeInfo(className: "UICollectionView", fullTitle: "HasActiveDrop", getterString: "hasActiveDrop", setterString: "", revision: 1)),
                BlueprintAttribute(.UICollectionView.Behavior.editing, AttributeInfo(className: "UICollectionView", fullTitle: "Editing", getterString: "isEditing", setterString: "setEditing:", patch: true, revision: 1)),
                BlueprintAttribute(.UICollectionView.Behavior.allowsSelectionDuringEditing, AttributeInfo(className: "UICollectionView", fullTitle: "AllowsSelectionDuringEditing", getterString: "allowsSelectionDuringEditing", setterString: "setAllowsSelectionDuringEditing:", patch: true, revision: 1)),
                BlueprintAttribute(.UICollectionView.Behavior.allowsMultipleSelectionDuringEditing, AttributeInfo(className: "UICollectionView", fullTitle: "AllowsMultipleSelectionDuringEditing", getterString: "allowsMultipleSelectionDuringEditing", setterString: "setAllowsMultipleSelectionDuringEditing:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UICollectionView.reorderingCadence, title: "ReorderingCadence", attributes: [
                BlueprintAttribute(.UICollectionView.ReorderingCadence.reorderingCadence, AttributeInfo(className: "UICollectionView", fullTitle: "ReorderingCadence", getterString: "reorderingCadence", setterString: "setReorderingCadence:", enumList: "UICollectionViewReorderingCadence", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UICollectionView.selfSizingInvalidation, title: "SelfSizingInvalidation", attributes: [
                BlueprintAttribute(.UICollectionView.SelfSizingInvalidation.selfSizingInvalidation, AttributeInfo(className: "UICollectionView", fullTitle: "SelfSizingInvalidation", getterString: "selfSizingInvalidation", setterString: "setSelfSizingInvalidation:", enumList: "UICollectionViewSelfSizingInvalidation", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UICollectionView.indexPathsForSelectedItems, title: "IndexPathsForSelectedItems", attributes: [
                BlueprintAttribute(.UICollectionView.IndexPathsForSelectedItems.indexPathsForSelectedItems, AttributeInfo(className: "UICollectionView", fullTitle: "IndexPathsForSelectedItems", getterString: "indexPathsForSelectedItems", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(.UICollectionView.numberOfSections, title: "NumberOfSections", attributes: [
                BlueprintAttribute(.UICollectionView.NumberOfSections.numberOfSections, AttributeInfo(className: "UICollectionView", fullTitle: "NumberOfSections", getterString: "numberOfSections", setterString: "", revision: 1)),
            ]),
        ])


        static let uiCollectionReusableViewGroup = BlueprintGroup(.uiCollectionReusableView, title: "UICollectionReusableView", on: .uiKit, sections: [
            BlueprintSection(.UICollectionReusableView.reuseIdentifier, title: "ReuseIdentifier", attributes: [
                BlueprintAttribute(.UICollectionReusableView.ReuseIdentifier.reuseIdentifier, AttributeInfo(className: "UICollectionReusableView", fullTitle: "ReuseIdentifier", getterString: "reuseIdentifier", setterString: "", objectValueType: .nsString, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UICollectionReusableView.uiCollectionViewCell, title: "UICollectionViewCell", attributes: [
                BlueprintAttribute(.UICollectionReusableView.UICollectionViewCell.automaticallyUpdatesContentConfiguration, AttributeInfo(className: "UICollectionViewCell", fullTitle: "AutomaticallyUpdatesContentConfiguration", getterString: "automaticallyUpdatesContentConfiguration", setterString: "setAutomaticallyUpdatesContentConfiguration:", patch: true, revision: 1)),
                BlueprintAttribute(.UICollectionReusableView.UICollectionViewCell.selected, AttributeInfo(className: "UICollectionViewCell", fullTitle: "Selected", getterString: "isSelected", setterString: "setSelected:", patch: true, revision: 1)),
                BlueprintAttribute(.UICollectionReusableView.UICollectionViewCell.highlighted, AttributeInfo(className: "UICollectionViewCell", fullTitle: "Highlighted", getterString: "isHighlighted", setterString: "setHighlighted:", patch: true, revision: 1)),
                BlueprintAttribute(.UICollectionReusableView.UICollectionViewCell.backgroundConfiguration, AttributeInfo(className: "UICollectionViewCell", fullTitle: "BackgroundConfiguration", getterString: "backgroundConfiguration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.configuration))),
                BlueprintAttribute(.UICollectionReusableView.UICollectionViewCell.automaticallyUpdatesBackgroundConfiguration, AttributeInfo(className: "UICollectionViewCell", fullTitle: "AutomaticallyUpdatesBackgroundConfiguration", getterString: "automaticallyUpdatesBackgroundConfiguration", setterString: "setAutomaticallyUpdatesBackgroundConfiguration:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UICollectionReusableView.uiCollectionViewListCell, title: "UICollectionViewListCell", attributes: [
                BlueprintAttribute(.UICollectionReusableView.UICollectionViewListCell.indentationLevel, AttributeInfo(className: "UICollectionViewListCell", fullTitle: "IndentationLevel", getterString: "indentationLevel", setterString: "setIndentationLevel:", patch: true, revision: 1)),
                BlueprintAttribute(.UICollectionReusableView.UICollectionViewListCell.indentationWidth, AttributeInfo(className: "UICollectionViewListCell", fullTitle: "IndentationWidth", getterString: "indentationWidth", setterString: "setIndentationWidth:", patch: true, revision: 1)),
                BlueprintAttribute(.UICollectionReusableView.UICollectionViewListCell.indentsAccessories, AttributeInfo(className: "UICollectionViewListCell", fullTitle: "IndentsAccessories", getterString: "indentsAccessories", setterString: "setIndentsAccessories:", patch: true, revision: 1)),
                BlueprintAttribute(.UICollectionReusableView.UICollectionViewListCell.accessories, AttributeInfo(className: "UICollectionViewListCell", fullTitle: "Accessories", getterString: "accessories", setterString: "", revision: 1, presentation: .count)),
            ]),
        ])


        static let uiTableViewCellGroup = BlueprintGroup(.uiTableViewCell, title: "UITableViewCell", on: .uiKit, sections: [
            BlueprintSection(.UITableViewCell.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UITableViewCell.Behavior.automaticallyUpdatesContentConfiguration, AttributeInfo(className: "UITableViewCell", fullTitle: "AutomaticallyUpdatesContentConfiguration", getterString: "automaticallyUpdatesContentConfiguration", setterString: "setAutomaticallyUpdatesContentConfiguration:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableViewCell.Behavior.automaticallyUpdatesBackgroundConfiguration, AttributeInfo(className: "UITableViewCell", fullTitle: "AutomaticallyUpdatesBackgroundConfiguration", getterString: "automaticallyUpdatesBackgroundConfiguration", setterString: "setAutomaticallyUpdatesBackgroundConfiguration:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableViewCell.Behavior.selected, AttributeInfo(className: "UITableViewCell", fullTitle: "Selected", getterString: "isSelected", setterString: "setSelected:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableViewCell.Behavior.highlighted, AttributeInfo(className: "UITableViewCell", fullTitle: "Highlighted", getterString: "isHighlighted", setterString: "setHighlighted:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableViewCell.Behavior.showsReorderControl, AttributeInfo(className: "UITableViewCell", fullTitle: "ShowsReorderControl", getterString: "showsReorderControl", setterString: "setShowsReorderControl:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableViewCell.Behavior.shouldIndentWhileEditing, AttributeInfo(className: "UITableViewCell", fullTitle: "ShouldIndentWhileEditing", getterString: "shouldIndentWhileEditing", setterString: "setShouldIndentWhileEditing:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableViewCell.Behavior.editing, AttributeInfo(className: "UITableViewCell", fullTitle: "Editing", getterString: "isEditing", setterString: "setEditing:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableViewCell.Behavior.showingDeleteConfirmation, AttributeInfo(className: "UITableViewCell", fullTitle: "ShowingDeleteConfirmation", getterString: "showingDeleteConfirmation", setterString: "", revision: 1)),
                BlueprintAttribute(.UITableViewCell.Behavior.userInteractionEnabledWhileDragging, AttributeInfo(className: "UITableViewCell", fullTitle: "UserInteractionEnabledWhileDragging", getterString: "userInteractionEnabledWhileDragging", setterString: "setUserInteractionEnabledWhileDragging:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableViewCell.backgroundConfiguration, title: "BackgroundConfiguration", attributes: [
                BlueprintAttribute(.UITableViewCell.BackgroundConfiguration.backgroundConfiguration, AttributeInfo(className: "UITableViewCell", fullTitle: "BackgroundConfiguration", getterString: "backgroundConfiguration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.configuration))),
            ]),
            BlueprintSection(.UITableViewCell.reuseIdentifier, title: "ReuseIdentifier", attributes: [
                BlueprintAttribute(.UITableViewCell.ReuseIdentifier.reuseIdentifier, AttributeInfo(className: "UITableViewCell", fullTitle: "ReuseIdentifier", getterString: "reuseIdentifier", setterString: "", objectValueType: .nsString, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UITableViewCell.selectionStyle, title: "SelectionStyle", attributes: [
                BlueprintAttribute(.UITableViewCell.SelectionStyle.selectionStyle, AttributeInfo(className: "UITableViewCell", fullTitle: "SelectionStyle", getterString: "selectionStyle", setterString: "setSelectionStyle:", enumList: "UITableViewCellSelectionStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableViewCell.editingStyle, title: "EditingStyle", attributes: [
                BlueprintAttribute(.UITableViewCell.EditingStyle.editingStyle, AttributeInfo(className: "UITableViewCell", fullTitle: "EditingStyle", getterString: "editingStyle", setterString: "", enumList: "UITableViewCellEditingStyle", revision: 1)),
            ]),
            BlueprintSection(.UITableViewCell.accessoryType, title: "AccessoryType", attributes: [
                BlueprintAttribute(.UITableViewCell.AccessoryType.accessoryType, AttributeInfo(className: "UITableViewCell", fullTitle: "AccessoryType", getterString: "accessoryType", setterString: "setAccessoryType:", enumList: "UITableViewCellAccessoryType", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableViewCell.editingAccessoryType, title: "EditingAccessoryType", attributes: [
                BlueprintAttribute(.UITableViewCell.EditingAccessoryType.editingAccessoryType, AttributeInfo(className: "UITableViewCell", fullTitle: "EditingAccessoryType", getterString: "editingAccessoryType", setterString: "setEditingAccessoryType:", enumList: "UITableViewCellAccessoryType", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableViewCell.indentationLevel, title: "IndentationLevel", attributes: [
                BlueprintAttribute(.UITableViewCell.IndentationLevel.indentationLevel, AttributeInfo(className: "UITableViewCell", fullTitle: "IndentationLevel", getterString: "indentationLevel", setterString: "setIndentationLevel:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableViewCell.indentationWidth, title: "IndentationWidth", attributes: [
                BlueprintAttribute(.UITableViewCell.IndentationWidth.indentationWidth, AttributeInfo(className: "UITableViewCell", fullTitle: "IndentationWidth", getterString: "indentationWidth", setterString: "setIndentationWidth:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableViewCell.separatorInset, title: "SeparatorInset", attributes: [
                BlueprintAttribute(.UITableViewCell.SeparatorInset.separatorInset, AttributeInfo(className: "UITableViewCell", fullTitle: "SeparatorInset", getterString: "separatorInset", setterString: "setSeparatorInset:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableViewCell.focusStyle, title: "FocusStyle", attributes: [
                BlueprintAttribute(.UITableViewCell.FocusStyle.focusStyle, AttributeInfo(className: "UITableViewCell", fullTitle: "FocusStyle", getterString: "focusStyle", setterString: "setFocusStyle:", enumList: "UITableViewCellFocusStyle", patch: true, revision: 1)),
            ]),
        ])


        static let uiTableViewHeaderFooterViewGroup = BlueprintGroup(.uiTableViewHeaderFooterView, title: "UITableViewHeaderFooterView", on: .uiKit, sections: [
            BlueprintSection(.UITableViewHeaderFooterView.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UITableViewHeaderFooterView.Behavior.automaticallyUpdatesContentConfiguration, AttributeInfo(className: "UITableViewHeaderFooterView", fullTitle: "AutomaticallyUpdatesContentConfiguration", getterString: "automaticallyUpdatesContentConfiguration", setterString: "setAutomaticallyUpdatesContentConfiguration:", patch: true, revision: 1)),
                BlueprintAttribute(.UITableViewHeaderFooterView.Behavior.automaticallyUpdatesBackgroundConfiguration, AttributeInfo(className: "UITableViewHeaderFooterView", fullTitle: "AutomaticallyUpdatesBackgroundConfiguration", getterString: "automaticallyUpdatesBackgroundConfiguration", setterString: "setAutomaticallyUpdatesBackgroundConfiguration:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITableViewHeaderFooterView.backgroundConfiguration, title: "BackgroundConfiguration", attributes: [
                BlueprintAttribute(.UITableViewHeaderFooterView.BackgroundConfiguration.backgroundConfiguration, AttributeInfo(className: "UITableViewHeaderFooterView", fullTitle: "BackgroundConfiguration", getterString: "backgroundConfiguration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.configuration))),
            ]),
            BlueprintSection(.UITableViewHeaderFooterView.reuseIdentifier, title: "ReuseIdentifier", attributes: [
                BlueprintAttribute(.UITableViewHeaderFooterView.ReuseIdentifier.reuseIdentifier, AttributeInfo(className: "UITableViewHeaderFooterView", fullTitle: "ReuseIdentifier", getterString: "reuseIdentifier", setterString: "", objectValueType: .nsString, hideIfNil: true, revision: 1)),
            ]),
        ])


        static let uiNavigationBarGroup = BlueprintGroup(.uiNavigationBar, title: "UINavigationBar", on: .uiKit, sections: [
            BlueprintSection(.UINavigationBar.barStyle, title: "BarStyle", attributes: [
                BlueprintAttribute(.UINavigationBar.BarStyle.barStyle, AttributeInfo(className: "UINavigationBar", fullTitle: "BarStyle", getterString: "barStyle", setterString: "setBarStyle:", enumList: "UIBarStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UINavigationBar.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UINavigationBar.Behavior.translucent, AttributeInfo(className: "UINavigationBar", fullTitle: "Translucent", getterString: "isTranslucent", setterString: "setTranslucent:", patch: true, revision: 1)),
                BlueprintAttribute(.UINavigationBar.Behavior.prefersLargeTitles, AttributeInfo(className: "UINavigationBar", fullTitle: "PrefersLargeTitles", getterString: "prefersLargeTitles", setterString: "setPrefersLargeTitles:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UINavigationBar.topItem, title: "TopItem", attributes: [
                BlueprintAttribute(.UINavigationBar.TopItem.topItem, AttributeInfo(className: "UINavigationBar", fullTitle: "TopItem", getterString: "topItem", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.navigationItem))),
            ]),
            BlueprintSection(.UINavigationBar.backItem, title: "BackItem", attributes: [
                BlueprintAttribute(.UINavigationBar.BackItem.backItem, AttributeInfo(className: "UINavigationBar", fullTitle: "BackItem", getterString: "backItem", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.navigationItem))),
            ]),
            BlueprintSection(.UINavigationBar.currentNSToolbarSection, title: "CurrentNSToolbarSection", attributes: [
                BlueprintAttribute(.UINavigationBar.CurrentNSToolbarSection.currentNSToolbarSection, AttributeInfo(className: "UINavigationBar", fullTitle: "CurrentNSToolbarSection", getterString: "currentNSToolbarSection", setterString: "", enumList: "UINavigationBarNSToolbarSection", revision: 1)),
            ]),
            BlueprintSection(.UINavigationBar.behavioralStyle, title: "BehavioralStyle", attributes: [
                BlueprintAttribute(.UINavigationBar.BehavioralStyle.behavioralStyle, AttributeInfo(className: "UINavigationBar", fullTitle: "BehavioralStyle", getterString: "behavioralStyle", setterString: "", enumList: "UIBehavioralStyle", revision: 1)),
            ]),
            BlueprintSection(.UINavigationBar.preferredBehavioralStyle, title: "PreferredBehavioralStyle", attributes: [
                BlueprintAttribute(.UINavigationBar.PreferredBehavioralStyle.preferredBehavioralStyle, AttributeInfo(className: "UINavigationBar", fullTitle: "PreferredBehavioralStyle", getterString: "preferredBehavioralStyle", setterString: "setPreferredBehavioralStyle:", enumList: "UIBehavioralStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UINavigationBar.barTintColor, title: "BarTintColor", attributes: [
                BlueprintAttribute(.UINavigationBar.BarTintColor.barTintColor, AttributeInfo(className: "UINavigationBar", fullTitle: "BarTintColor", getterString: "barTintColor", setterString: "setBarTintColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UINavigationBar.images, title: "Images", attributes: [
                BlueprintAttribute(.UINavigationBar.Images.shadowImage, AttributeInfo(className: "UINavigationBar", fullTitle: "ShadowImage", getterString: "shadowImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.UINavigationBar.Images.backIndicatorImage, AttributeInfo(className: "UINavigationBar", fullTitle: "BackIndicatorImage", getterString: "backIndicatorImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.UINavigationBar.Images.backIndicatorTransitionMaskImage, AttributeInfo(className: "UINavigationBar", fullTitle: "BackIndicatorTransitionMaskImage", getterString: "backIndicatorTransitionMaskImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
        ])


        static let uiTabBarGroup = BlueprintGroup(.uiTabBar, title: "UITabBar", on: .uiKit, sections: [
            BlueprintSection(.UITabBar.selectedItem, title: "SelectedItem", attributes: [
                BlueprintAttribute(.UITabBar.SelectedItem.selectedItem, AttributeInfo(className: "UITabBar", fullTitle: "SelectedItem", getterString: "selectedItem", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.barItem))),
            ]),
            BlueprintSection(.UITabBar.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UITabBar.Behavior.customizing, AttributeInfo(className: "UITabBar", fullTitle: "Customizing", getterString: "isCustomizing", setterString: "", revision: 1)),
                BlueprintAttribute(.UITabBar.Behavior.translucent, AttributeInfo(className: "UITabBar", fullTitle: "Translucent", getterString: "isTranslucent", setterString: "setTranslucent:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITabBar.colors, title: "Colors", attributes: [
                BlueprintAttribute(.UITabBar.Colors.barTintColor, AttributeInfo(className: "UITabBar", fullTitle: "BarTintColor", getterString: "barTintColor", setterString: "setBarTintColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.UITabBar.Colors.unselectedItemTintColor, AttributeInfo(className: "UITabBar", fullTitle: "UnselectedItemTintColor", getterString: "unselectedItemTintColor", setterString: "setUnselectedItemTintColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UITabBar.images, title: "Images", attributes: [
                BlueprintAttribute(.UITabBar.Images.backgroundImage, AttributeInfo(className: "UITabBar", fullTitle: "BackgroundImage", getterString: "backgroundImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.UITabBar.Images.selectionIndicatorImage, AttributeInfo(className: "UITabBar", fullTitle: "SelectionIndicatorImage", getterString: "selectionIndicatorImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.UITabBar.Images.shadowImage, AttributeInfo(className: "UITabBar", fullTitle: "ShadowImage", getterString: "shadowImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(.UITabBar.itemPositioning, title: "ItemPositioning", attributes: [
                BlueprintAttribute(.UITabBar.ItemPositioning.itemPositioning, AttributeInfo(className: "UITabBar", fullTitle: "ItemPositioning", getterString: "itemPositioning", setterString: "setItemPositioning:", enumList: "UITabBarItemPositioning", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITabBar.itemWidth, title: "ItemWidth", attributes: [
                BlueprintAttribute(.UITabBar.ItemWidth.itemWidth, AttributeInfo(className: "UITabBar", fullTitle: "ItemWidth", getterString: "itemWidth", setterString: "setItemWidth:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITabBar.itemSpacing, title: "ItemSpacing", attributes: [
                BlueprintAttribute(.UITabBar.ItemSpacing.itemSpacing, AttributeInfo(className: "UITabBar", fullTitle: "ItemSpacing", getterString: "itemSpacing", setterString: "setItemSpacing:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UITabBar.barStyle, title: "BarStyle", attributes: [
                BlueprintAttribute(.UITabBar.BarStyle.barStyle, AttributeInfo(className: "UITabBar", fullTitle: "BarStyle", getterString: "barStyle", setterString: "setBarStyle:", enumList: "UIBarStyle", patch: true, revision: 1)),
            ]),
        ])


        static let uiToolbarGroup = BlueprintGroup(.uiToolbar, title: "UIToolbar", on: .uiKit, sections: [
            BlueprintSection(.UIToolbar.barStyle, title: "BarStyle", attributes: [
                BlueprintAttribute(.UIToolbar.BarStyle.barStyle, AttributeInfo(className: "UIToolbar", fullTitle: "BarStyle", getterString: "barStyle", setterString: "setBarStyle:", enumList: "UIBarStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIToolbar.translucent, title: "Translucent", attributes: [
                BlueprintAttribute(.UIToolbar.Translucent.translucent, AttributeInfo(className: "UIToolbar", fullTitle: "Translucent", getterString: "isTranslucent", setterString: "setTranslucent:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIToolbar.barTintColor, title: "BarTintColor", attributes: [
                BlueprintAttribute(.UIToolbar.BarTintColor.barTintColor, AttributeInfo(className: "UIToolbar", fullTitle: "BarTintColor", getterString: "barTintColor", setterString: "setBarTintColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
        ])


        static let uiSearchBarGroup = BlueprintGroup(.uiSearchBar, title: "UISearchBar", on: .uiKit, sections: [
            BlueprintSection(.UISearchBar.barStyle, title: "BarStyle", attributes: [
                BlueprintAttribute(.UISearchBar.BarStyle.barStyle, AttributeInfo(className: "UISearchBar", fullTitle: "BarStyle", getterString: "barStyle", setterString: "setBarStyle:", enumList: "UIBarStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UISearchBar.text, title: "Text", attributes: [
                BlueprintAttribute(.UISearchBar.Text.text, AttributeInfo(className: "UISearchBar", fullTitle: "Text", getterString: "text", setterString: "setText:", objectValueType: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UISearchBar.prompt, title: "Prompt", attributes: [
                BlueprintAttribute(.UISearchBar.Prompt.prompt, AttributeInfo(className: "UISearchBar", fullTitle: "Prompt", getterString: "prompt", setterString: "setPrompt:", objectValueType: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UISearchBar.placeholder, title: "Placeholder", attributes: [
                BlueprintAttribute(.UISearchBar.Placeholder.placeholder, AttributeInfo(className: "UISearchBar", fullTitle: "Placeholder", getterString: "placeholder", setterString: "setPlaceholder:", objectValueType: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UISearchBar.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UISearchBar.Behavior.showsBookmarkButton, AttributeInfo(className: "UISearchBar", fullTitle: "ShowsBookmarkButton", getterString: "showsBookmarkButton", setterString: "setShowsBookmarkButton:", patch: true, revision: 1)),
                BlueprintAttribute(.UISearchBar.Behavior.showsCancelButton, AttributeInfo(className: "UISearchBar", fullTitle: "ShowsCancelButton", getterString: "showsCancelButton", setterString: "setShowsCancelButton:", patch: true, revision: 1)),
                BlueprintAttribute(.UISearchBar.Behavior.showsSearchResultsButton, AttributeInfo(className: "UISearchBar", fullTitle: "ShowsSearchResultsButton", getterString: "showsSearchResultsButton", setterString: "setShowsSearchResultsButton:", patch: true, revision: 1)),
                BlueprintAttribute(.UISearchBar.Behavior.searchResultsButtonSelected, AttributeInfo(className: "UISearchBar", fullTitle: "SearchResultsButtonSelected", getterString: "isSearchResultsButtonSelected", setterString: "setSearchResultsButtonSelected:", patch: true, revision: 1)),
                BlueprintAttribute(.UISearchBar.Behavior.translucent, AttributeInfo(className: "UISearchBar", fullTitle: "Translucent", getterString: "isTranslucent", setterString: "setTranslucent:", patch: true, revision: 1)),
                BlueprintAttribute(.UISearchBar.Behavior.showsScopeBar, AttributeInfo(className: "UISearchBar", fullTitle: "ShowsScopeBar", getterString: "showsScopeBar", setterString: "setShowsScopeBar:", patch: true, revision: 1)),
                BlueprintAttribute(.UISearchBar.Behavior.enabled, AttributeInfo(className: "UISearchBar", fullTitle: "Enabled", getterString: "isEnabled", setterString: "setEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.UISearchBar.Behavior.lookToDictateEnabled, AttributeInfo(className: "UISearchBar", fullTitle: "LookToDictateEnabled", getterString: "isLookToDictateEnabled", setterString: "setLookToDictateEnabled:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UISearchBar.barTintColor, title: "BarTintColor", attributes: [
                BlueprintAttribute(.UISearchBar.BarTintColor.barTintColor, AttributeInfo(className: "UISearchBar", fullTitle: "BarTintColor", getterString: "barTintColor", setterString: "setBarTintColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UISearchBar.searchBarStyle, title: "SearchBarStyle", attributes: [
                BlueprintAttribute(.UISearchBar.SearchBarStyle.searchBarStyle, AttributeInfo(className: "UISearchBar", fullTitle: "SearchBarStyle", getterString: "searchBarStyle", setterString: "setSearchBarStyle:", enumList: "UISearchBarStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UISearchBar.scopeButtonTitles, title: "ScopeButtonTitles", attributes: [
                BlueprintAttribute(.UISearchBar.ScopeButtonTitles.scopeButtonTitles, AttributeInfo(className: "UISearchBar", fullTitle: "ScopeButtonTitles", getterString: "scopeButtonTitles", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(.UISearchBar.selectedScopeButtonIndex, title: "SelectedScopeButtonIndex", attributes: [
                BlueprintAttribute(.UISearchBar.SelectedScopeButtonIndex.selectedScopeButtonIndex, AttributeInfo(className: "UISearchBar", fullTitle: "SelectedScopeButtonIndex", getterString: "selectedScopeButtonIndex", setterString: "setSelectedScopeButtonIndex:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UISearchBar.images, title: "Images", attributes: [
                BlueprintAttribute(.UISearchBar.Images.backgroundImage, AttributeInfo(className: "UISearchBar", fullTitle: "BackgroundImage", getterString: "backgroundImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.UISearchBar.Images.scopeBarBackgroundImage, AttributeInfo(className: "UISearchBar", fullTitle: "ScopeBarBackgroundImage", getterString: "scopeBarBackgroundImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(.UISearchBar.searchFieldBackgroundPositionAdjustment, title: "SearchFieldBackgroundPositionAdjustment", attributes: [
                BlueprintAttribute(.UISearchBar.SearchFieldBackgroundPositionAdjustment.searchFieldBackgroundPositionAdjustment, AttributeInfo(className: "UISearchBar", fullTitle: "SearchFieldBackgroundPositionAdjustment", getterString: "searchFieldBackgroundPositionAdjustment", setterString: "", revision: 1, presentation: .structure)),
            ]),
            BlueprintSection(.UISearchBar.searchTextPositionAdjustment, title: "SearchTextPositionAdjustment", attributes: [
                BlueprintAttribute(.UISearchBar.SearchTextPositionAdjustment.searchTextPositionAdjustment, AttributeInfo(className: "UISearchBar", fullTitle: "SearchTextPositionAdjustment", getterString: "searchTextPositionAdjustment", setterString: "", revision: 1, presentation: .structure)),
            ]),
        ])


        static let uiInputViewGroup = BlueprintGroup(.uiInputView, title: "UIInputView", on: .uiKit, sections: [
            BlueprintSection(.UIInputView.inputViewStyle, title: "InputViewStyle", attributes: [
                BlueprintAttribute(.UIInputView.InputViewStyle.inputViewStyle, AttributeInfo(className: "UIInputView", fullTitle: "InputViewStyle", getterString: "inputViewStyle", setterString: "", enumList: "UIInputViewStyle", revision: 1)),
            ]),
            BlueprintSection(.UIInputView.allowsSelfSizing, title: "AllowsSelfSizing", attributes: [
                BlueprintAttribute(.UIInputView.AllowsSelfSizing.allowsSelfSizing, AttributeInfo(className: "UIInputView", fullTitle: "AllowsSelfSizing", getterString: "allowsSelfSizing", setterString: "setAllowsSelfSizing:", patch: true, revision: 1)),
            ]),
        ])


        static let uiContentUnavailableViewGroup = BlueprintGroup(.uiContentUnavailableView, title: "UIContentUnavailableView", on: .uiKit, sections: [
            BlueprintSection(.UIContentUnavailableView.configuration, title: "Configuration", attributes: [
                BlueprintAttribute(.UIContentUnavailableView.Configuration.configuration, AttributeInfo(className: "UIContentUnavailableView", fullTitle: "Configuration", getterString: "configuration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.configuration))),
            ]),
            BlueprintSection(.UIContentUnavailableView.scrollEnabled, title: "ScrollEnabled", attributes: [
                BlueprintAttribute(.UIContentUnavailableView.ScrollEnabled.scrollEnabled, AttributeInfo(className: "UIContentUnavailableView", fullTitle: "ScrollEnabled", getterString: "isScrollEnabled", setterString: "setScrollEnabled:", patch: true, revision: 1)),
            ]),
        ])


        static let uiBackgroundExtensionViewGroup = BlueprintGroup(.uiBackgroundExtensionView, title: "UIBackgroundExtensionView", on: .uiKit, sections: [
            BlueprintSection(.UIBackgroundExtensionView.automaticallyPlacesContentView, title: "AutomaticallyPlacesContentView", attributes: [
                BlueprintAttribute(.UIBackgroundExtensionView.AutomaticallyPlacesContentView.automaticallyPlacesContentView, AttributeInfo(className: "UIBackgroundExtensionView", fullTitle: "AutomaticallyPlacesContentView", getterString: "automaticallyPlacesContentView", setterString: "setAutomaticallyPlacesContentView:", patch: true, revision: 1)),
            ]),
        ])


        static let uiWindowGroup = BlueprintGroup(.uiWindow, title: "UIWindow", on: .uiKit, sections: [
            BlueprintSection(.UIWindow.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UIWindow.Behavior.canResizeToFitContent, AttributeInfo(className: "UIWindow", fullTitle: "CanResizeToFitContent", getterString: "canResizeToFitContent", setterString: "setCanResizeToFitContent:", patch: true, revision: 1)),
                BlueprintAttribute(.UIWindow.Behavior.keyWindow, AttributeInfo(className: "UIWindow", fullTitle: "KeyWindow", getterString: "isKeyWindow", setterString: "", revision: 1)),
                BlueprintAttribute(.UIWindow.Behavior.canBecomeKeyWindow, AttributeInfo(className: "UIWindow", fullTitle: "CanBecomeKeyWindow", getterString: "canBecomeKeyWindow", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.UIWindow.windowLevel, title: "WindowLevel", attributes: [
                BlueprintAttribute(.UIWindow.WindowLevel.windowLevel, AttributeInfo(className: "UIWindow", fullTitle: "WindowLevel", getterString: "windowLevel", setterString: "setWindowLevel:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIWindow.rootViewController, title: "RootViewController", attributes: [
                BlueprintAttribute(.UIWindow.RootViewController.rootViewController, AttributeInfo(className: "UIWindow", fullTitle: "RootViewController", getterString: "rootViewController", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.className))),
            ]),
        ])

        static let uiViewGroup = BlueprintGroup(.uiView, title: "UIView", on: .uiKit, sections: [
            BlueprintSection(.UIView.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.UIView.Behavior.accessibilityIgnoresInvertColors, AttributeInfo(className: "UIView", fullTitle: "AccessibilityIgnoresInvertColors", getterString: "accessibilityIgnoresInvertColors", setterString: "setAccessibilityIgnoresInvertColors:", patch: true, revision: 1)),
                BlueprintAttribute(.UIView.Behavior.showsLargeContentViewer, AttributeInfo(className: "UIView", fullTitle: "ShowsLargeContentViewer", getterString: "showsLargeContentViewer", setterString: "setShowsLargeContentViewer:", patch: true, revision: 1)),
                BlueprintAttribute(.UIView.Behavior.scalesLargeContentImage, AttributeInfo(className: "UIView", fullTitle: "ScalesLargeContentImage", getterString: "scalesLargeContentImage", setterString: "setScalesLargeContentImage:", patch: true, revision: 1)),
                BlueprintAttribute(.UIView.Behavior.canBecomeFocused, AttributeInfo(className: "UIView", fullTitle: "CanBecomeFocused", getterString: "canBecomeFocused", setterString: "", revision: 1)),
                BlueprintAttribute(.UIView.Behavior.focused, AttributeInfo(className: "UIView", fullTitle: "Focused", getterString: "isFocused", setterString: "", revision: 1)),
                BlueprintAttribute(.UIView.Behavior.multipleTouchEnabled, AttributeInfo(className: "UIView", fullTitle: "MultipleTouchEnabled", getterString: "isMultipleTouchEnabled", setterString: "setMultipleTouchEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.UIView.Behavior.exclusiveTouch, AttributeInfo(className: "UIView", fullTitle: "ExclusiveTouch", getterString: "isExclusiveTouch", setterString: "setExclusiveTouch:", patch: true, revision: 1)),
                BlueprintAttribute(.UIView.Behavior.autoresizesSubviews, AttributeInfo(className: "UIView", fullTitle: "AutoresizesSubviews", getterString: "autoresizesSubviews", setterString: "setAutoresizesSubviews:", patch: true, revision: 1)),
                BlueprintAttribute(.UIView.Behavior.preservesSuperviewLayoutMargins, AttributeInfo(className: "UIView", fullTitle: "PreservesSuperviewLayoutMargins", getterString: "preservesSuperviewLayoutMargins", setterString: "setPreservesSuperviewLayoutMargins:", patch: true, revision: 1)),
                BlueprintAttribute(.UIView.Behavior.insetsLayoutMarginsFromSafeArea, AttributeInfo(className: "UIView", fullTitle: "InsetsLayoutMarginsFromSafeArea", getterString: "insetsLayoutMarginsFromSafeArea", setterString: "setInsetsLayoutMarginsFromSafeArea:", patch: true, revision: 1)),
                BlueprintAttribute(.UIView.Behavior.clearsContextBeforeDrawing, AttributeInfo(className: "UIView", fullTitle: "ClearsContextBeforeDrawing", getterString: "clearsContextBeforeDrawing", setterString: "setClearsContextBeforeDrawing:", patch: true, revision: 1)),
                BlueprintAttribute(.UIView.Behavior.translatesAutoresizingMaskIntoConstraints, AttributeInfo(className: "UIView", fullTitle: "TranslatesAutoresizingMaskIntoConstraints", getterString: "translatesAutoresizingMaskIntoConstraints", setterString: "setTranslatesAutoresizingMaskIntoConstraints:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIView.largeContentTitle, title: "LargeContentTitle", attributes: [
                BlueprintAttribute(.UIView.LargeContentTitle.largeContentTitle, AttributeInfo(className: "UIView", fullTitle: "LargeContentTitle", getterString: "largeContentTitle", setterString: "setLargeContentTitle:", objectValueType: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UIView.largeContentImageInsets, title: "LargeContentImageInsets", attributes: [
                BlueprintAttribute(.UIView.LargeContentImageInsets.largeContentImageInsets, AttributeInfo(className: "UIView", fullTitle: "LargeContentImageInsets", getterString: "largeContentImageInsets", setterString: "setLargeContentImageInsets:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIView.focusGroupIdentifier, title: "FocusGroupIdentifier", attributes: [
                BlueprintAttribute(.UIView.FocusGroupIdentifier.focusGroupIdentifier, AttributeInfo(className: "UIView", fullTitle: "FocusGroupIdentifier", getterString: "focusGroupIdentifier", setterString: "setFocusGroupIdentifier:", objectValueType: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UIView.semanticContentAttribute, title: "SemanticContentAttribute", attributes: [
                BlueprintAttribute(.UIView.SemanticContentAttribute.semanticContentAttribute, AttributeInfo(className: "UIView", fullTitle: "SemanticContentAttribute", getterString: "semanticContentAttribute", setterString: "setSemanticContentAttribute:", enumList: "UISemanticContentAttribute", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIView.effectiveUserInterfaceLayoutDirection, title: "EffectiveUserInterfaceLayoutDirection", attributes: [
                BlueprintAttribute(.UIView.EffectiveUserInterfaceLayoutDirection.effectiveUserInterfaceLayoutDirection, AttributeInfo(className: "UIView", fullTitle: "EffectiveUserInterfaceLayoutDirection", getterString: "effectiveUserInterfaceLayoutDirection", setterString: "", enumList: "UIUserInterfaceLayoutDirection", revision: 1)),
            ]),
            BlueprintSection(.UIView.transform, title: "Transform", attributes: [
                BlueprintAttribute(.UIView.Transform.transform, AttributeInfo(className: "UIView", fullTitle: "Transform", getterString: "transform", setterString: "", revision: 1, presentation: .structure)),
            ]),
            BlueprintSection(.UIView.transform3D, title: "Transform3D", attributes: [
                BlueprintAttribute(.UIView.Transform3D.transform3D, AttributeInfo(className: "UIView", fullTitle: "Transform3D", getterString: "transform3D", setterString: "", revision: 1, presentation: .structure)),
            ]),
            BlueprintSection(.UIView.contentScaleFactor, title: "ContentScaleFactor", attributes: [
                BlueprintAttribute(.UIView.ContentScaleFactor.contentScaleFactor, AttributeInfo(className: "UIView", fullTitle: "ContentScaleFactor", getterString: "contentScaleFactor", setterString: "setContentScaleFactor:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIView.autoresizingMask, title: "AutoresizingMask", attributes: [
                BlueprintAttribute(.UIView.AutoresizingMask.autoresizingMask, AttributeInfo(className: "UIView", fullTitle: "AutoresizingMask", getterString: "autoresizingMask", setterString: "", revision: 1, presentation: .optionNames("UIViewAutoresizing"))),
            ]),
            BlueprintSection(.UIView.layoutMargins, title: "LayoutMargins", attributes: [
                BlueprintAttribute(.UIView.LayoutMargins.layoutMargins, AttributeInfo(className: "UIView", fullTitle: "LayoutMargins", getterString: "layoutMargins", setterString: "setLayoutMargins:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIView.directionalLayoutMargins, title: "DirectionalLayoutMargins", attributes: [
                BlueprintAttribute(.UIView.DirectionalLayoutMargins.directionalLayoutMargins, AttributeInfo(className: "UIView", fullTitle: "DirectionalLayoutMargins", getterString: "directionalLayoutMargins", setterString: "", revision: 1, presentation: .structure)),
            ]),
            BlueprintSection(.UIView.alignmentRectInsets, title: "AlignmentRectInsets", attributes: [
                BlueprintAttribute(.UIView.AlignmentRectInsets.alignmentRectInsets, AttributeInfo(className: "UIView", fullTitle: "AlignmentRectInsets", getterString: "alignmentRectInsets", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.UIView.restorationIdentifier, title: "RestorationIdentifier", attributes: [
                BlueprintAttribute(.UIView.RestorationIdentifier.restorationIdentifier, AttributeInfo(className: "UIView", fullTitle: "RestorationIdentifier", getterString: "restorationIdentifier", setterString: "setRestorationIdentifier:", objectValueType: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UIView.overrideUserInterfaceStyle, title: "OverrideUserInterfaceStyle", attributes: [
                BlueprintAttribute(.UIView.OverrideUserInterfaceStyle.overrideUserInterfaceStyle, AttributeInfo(className: "UIView", fullTitle: "OverrideUserInterfaceStyle", getterString: "overrideUserInterfaceStyle", setterString: "setOverrideUserInterfaceStyle:", enumList: "UIUserInterfaceStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.UIView.minimumContentSizeCategory, title: "MinimumContentSizeCategory", attributes: [
                BlueprintAttribute(.UIView.MinimumContentSizeCategory.minimumContentSizeCategory, AttributeInfo(className: "UIView", fullTitle: "MinimumContentSizeCategory", getterString: "minimumContentSizeCategory", setterString: "", objectValueType: .nsString, revision: 1)),
            ]),
            BlueprintSection(.UIView.maximumContentSizeCategory, title: "MaximumContentSizeCategory", attributes: [
                BlueprintAttribute(.UIView.MaximumContentSizeCategory.maximumContentSizeCategory, AttributeInfo(className: "UIView", fullTitle: "MaximumContentSizeCategory", getterString: "maximumContentSizeCategory", setterString: "", objectValueType: .nsString, revision: 1)),
            ]),
            BlueprintSection(.UIView.appliedContentSizeCategoryLimitsDescription, title: "AppliedContentSizeCategoryLimitsDescription", attributes: [
                BlueprintAttribute(.UIView.AppliedContentSizeCategoryLimitsDescription.appliedContentSizeCategoryLimitsDescription, AttributeInfo(className: "UIView", fullTitle: "AppliedContentSizeCategoryLimitsDescription", getterString: "appliedContentSizeCategoryLimitsDescription", setterString: "", objectValueType: .nsString, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.UIView.cornerConfiguration, title: "CornerConfiguration", attributes: [
                BlueprintAttribute(.UIView.CornerConfiguration.cornerConfiguration, AttributeInfo(className: "UIView", fullTitle: "CornerConfiguration", getterString: "cornerConfiguration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.description))),
            ]),
        ])
    }

#endif
