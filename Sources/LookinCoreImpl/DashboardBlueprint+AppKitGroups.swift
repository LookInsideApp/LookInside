//
//  DashboardBlueprint+AppKitGroups.swift
//  LookinCore
//
//  The groups only AppKit lists. The NSCell group's sections are on both
//  platforms, as they always were, so its section list answers on iOS too.
//  Each group lists its sections and each section its attributes, in display
//  order; DashboardBlueprintCatalog.swift explains the entry types and how the
//  lookup tables are derived. A section or attribute without `on:` is on the
//  platforms of the group or section it belongs to.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation

    extension DashboardBlueprintTables {
        static let nsImageViewGroup = BlueprintGroup(.nsImageView, title: "NSImageView", on: .appKit, sections: [
            BlueprintSection(.NSImageView.name, title: "ImageName", attributes: [
                BlueprintAttribute(.NSImageView.Name.name, AttributeInfo(className: "NSImageView", fullTitle: "ImageName", getterString: "lks_imageSourceName", setterString: "", objectValueType: .nsString, hideIfNil: true)),
            ]),
            BlueprintSection(.NSImageView.open, title: "Open", attributes: [
                BlueprintAttribute(.NSImageView.Open.open, AttributeInfo(className: "NSImageView", getterString: "lks_imageViewOidIfHasImage", setterString: "", objectValueType: .customObject, hideIfNil: true)),
            ]),
            BlueprintSection(.NSImageView.scaling, title: "Scaling", attributes: [
                BlueprintAttribute(.NSImageView.Scaling.imageScaling, AttributeInfo(className: "NSImageView", fullTitle: "ImageScaling", enumList: "NSImageScaling", patch: true)),
                BlueprintAttribute(.NSImageView.Scaling.imageAlignment, AttributeInfo(className: "NSImageView", fullTitle: "ImageAlignment", enumList: "NSImageAlignment", patch: true)),
                BlueprintAttribute(.NSImageView.Scaling.imageFrameStyle, AttributeInfo(className: "NSImageView", fullTitle: "ImageFrameStyle", enumList: "NSImageFrameStyle", patch: true)),
            ]),
            BlueprintSection(.NSImageView.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.NSImageView.Behavior.animates, AttributeInfo(className: "NSImageView", fullTitle: "Animates", patch: true)),
                BlueprintAttribute(.NSImageView.Behavior.editable, AttributeInfo(className: "NSImageView", fullTitle: "Editable", getterString: "isEditable", patch: true)),
            ]),
            BlueprintSection(.NSImageView.contentTintColor, title: "ContentTintColor", attributes: [
                BlueprintAttribute(.NSImageView.ContentTintColor.contentTintColor, AttributeInfo(className: "NSImageView", fullTitle: "ContentTintColor", objectValueType: .uiColor, patch: true)),
            ]),
            BlueprintSection(.NSImageView.symbolConfiguration, title: "SymbolConfiguration", attributes: [
                BlueprintAttribute(.NSImageView.SymbolConfiguration.symbolConfiguration, AttributeInfo(className: "NSImageView", fullTitle: "SymbolConfiguration", getterString: "symbolConfiguration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.description))),
            ]),
            BlueprintSection(.NSImageView.allowsCutCopyPaste, title: "AllowsCutCopyPaste", attributes: [
                BlueprintAttribute(.NSImageView.AllowsCutCopyPaste.allowsCutCopyPaste, AttributeInfo(className: "NSImageView", fullTitle: "AllowsCutCopyPaste", getterString: "allowsCutCopyPaste", setterString: "setAllowsCutCopyPaste:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSImageView.preferredImageDynamicRange, title: "PreferredImageDynamicRange", attributes: [
                BlueprintAttribute(.NSImageView.PreferredImageDynamicRange.preferredImageDynamicRange, AttributeInfo(className: "NSImageView", fullTitle: "PreferredImageDynamicRange", getterString: "preferredImageDynamicRange", setterString: "setPreferredImageDynamicRange:", enumList: "NSImageDynamicRange", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSImageView.imageDynamicRange, title: "ImageDynamicRange", attributes: [
                BlueprintAttribute(.NSImageView.ImageDynamicRange.imageDynamicRange, AttributeInfo(className: "NSImageView", fullTitle: "ImageDynamicRange", getterString: "imageDynamicRange", setterString: "", enumList: "NSImageDynamicRange", revision: 1)),
            ]),
        ])

        static let nsControlGroup = BlueprintGroup(.nsControl, title: "NSControl", on: .appKit, sections: [
            BlueprintSection(.NSControl.state, title: "State", attributes: [
                BlueprintAttribute(.NSControl.State.enabled, AttributeInfo(className: "NSControl", fullTitle: "Enabled", getterString: "isEnabled", patch: true)),
                BlueprintAttribute(.NSControl.State.highlighted, AttributeInfo(className: "NSControl", fullTitle: "Highlighted", getterString: "isHighlighted", patch: true)),
                BlueprintAttribute(.NSControl.State.continuous, AttributeInfo(className: "NSControl", fullTitle: "Continuous", getterString: "isContinuous", patch: false)),
            ]),
            BlueprintSection(.NSControl.controlSize, title: "ControlSize", attributes: [
                BlueprintAttribute(.NSControl.ControlSize.size, AttributeInfo(className: "NSControl", fullTitle: "ControlSize", enumList: "NSControlSize", patch: true)),
            ]),
            BlueprintSection(.NSControl.font, title: "Font", attributes: [
                BlueprintAttribute(.NSControl.Font.name, AttributeInfo(className: "NSControl", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", objectValueType: .nsString, patch: false)),
                BlueprintAttribute(.NSControl.Font.size, AttributeInfo(className: "NSControl", fullTitle: "FontSize", getterString: "lks_fontSize", setterString: "setLks_fontSize:", patch: true)),
            ]),
            BlueprintSection(.NSControl.alignment, title: "Alignment", attributes: [
                BlueprintAttribute(.NSControl.Alignment.alignment, AttributeInfo(className: "NSControl", fullTitle: "Alignment", enumList: "NSTextAlignment_AppKit", patch: true)),
            ]),
            BlueprintSection(.NSControl.miscellaneous, title: "Misc", attributes: [
                BlueprintAttribute(.NSControl.Miscellaneous.writingDirection, AttributeInfo(className: "NSControl", fullTitle: "BaseWritingDirection", enumList: "NSWritingDirection", patch: false)),
                BlueprintAttribute(.NSControl.Miscellaneous.ignoresMultiClick, AttributeInfo(className: "NSControl", fullTitle: "IgnoresMultiClick", patch: false)),
                BlueprintAttribute(.NSControl.Miscellaneous.usesSingleLineMode, AttributeInfo(className: "NSControl", fullTitle: "UsesSingleLineMode", patch: false)),
                BlueprintAttribute(.NSControl.Miscellaneous.allowsExpansionToolTips, AttributeInfo(className: "NSControl", fullTitle: "AllowsExpansionToolTips", patch: false)),
            ]),
            BlueprintSection(.NSControl.stringValue, title: "StringValue", attributes: [
                BlueprintAttribute(.NSControl.Value.stringValue, AttributeInfo(className: "NSControl", fullTitle: "StringValue", objectValueType: .nsString, patch: true)),
            ]),
            BlueprintSection(.NSControl.value, title: "Value", attributes: [
                BlueprintAttribute(.NSControl.Value.intValue, AttributeInfo(className: "NSControl", fullTitle: "IntValue", patch: true)),
                BlueprintAttribute(.NSControl.Value.integerValue, AttributeInfo(className: "NSControl", fullTitle: "IntegerValue", patch: true)),
                BlueprintAttribute(.NSControl.Value.floatValue, AttributeInfo(className: "NSControl", fullTitle: "FloatValue", patch: true)),
                BlueprintAttribute(.NSControl.Value.doubleValue, AttributeInfo(className: "NSControl", fullTitle: "DoubleValue", patch: true)),
            ]),
            BlueprintSection(.NSControl.tag, title: "Tag", attributes: [
                BlueprintAttribute(.NSControl.Tag.tag, AttributeInfo(className: "NSControl", fullTitle: "Tag", getterString: "tag", setterString: "setTag:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSControl.refusesFirstResponder, title: "RefusesFirstResponder", attributes: [
                BlueprintAttribute(.NSControl.RefusesFirstResponder.refusesFirstResponder, AttributeInfo(className: "NSControl", fullTitle: "RefusesFirstResponder", getterString: "refusesFirstResponder", setterString: "setRefusesFirstResponder:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSControl.lineBreakMode, title: "LineBreakMode", attributes: [
                BlueprintAttribute(.NSControl.LineBreakMode.lineBreakMode, AttributeInfo(className: "NSControl", fullTitle: "LineBreakMode", getterString: "lineBreakMode", setterString: "setLineBreakMode:", enumList: "NSLineBreakMode", patch: true, revision: 1)),
            ]),
        ])

        static let nsButtonGroup = BlueprintGroup(.nsButton, title: "NSButton", on: .appKit, sections: [
            BlueprintSection(.NSButton.buttonType, title: "ButtonType", attributes: [
                BlueprintAttribute(.NSButton.ButtonType.buttonType, AttributeInfo(className: "NSButton", fullTitle: "ButtonType", getterString: "lks_buttonType", enumList: "NSButtonType", patch: true)),
            ]),
            BlueprintSection(.NSButton.bezelStyle, title: "BezelStyle", attributes: [
                BlueprintAttribute(.NSButton.BezelStyle.bezelStyle, AttributeInfo(className: "NSButton", fullTitle: "BezelStyle", enumList: "NSBezelStyle", patch: true)),
            ]),
            BlueprintSection(.NSButton.title, title: "Title", attributes: [
                BlueprintAttribute(.NSButton.Title.title, AttributeInfo(className: "NSButton", fullTitle: "Title", objectValueType: .nsString, patch: true)),
                BlueprintAttribute(.NSButton.Title.alernateTitle, AttributeInfo(className: "NSButton", fullTitle: "AlternateTitle", objectValueType: .nsString, patch: true)),
            ]),
            BlueprintSection(.NSButton.bordered, attributes: [
                BlueprintAttribute(.NSButton.Bordered.bordered, AttributeInfo(className: "NSButton", fullTitle: "Bordered", getterString: "isBordered", patch: true)),
                BlueprintAttribute(.NSButton.Transparent.transparent, AttributeInfo(className: "NSButton", fullTitle: "Transparent", getterString: "isTransparent", patch: true)),
                BlueprintAttribute(.NSButton.Miscellaneous.showsBorderOnlyWhileMouseInside, AttributeInfo(className: "NSButton", fullTitle: "ShowsBorderOnlyWhileMouseInside", patch: true)),
                // Derived getter would be -springLoaded; the property is -isSpringLoaded.
                BlueprintAttribute(.NSButton.Miscellaneous.springLoaded, AttributeInfo(className: "NSButton", fullTitle: "SpringLoaded", getterString: "isSpringLoaded", patch: true)),
                BlueprintAttribute(.NSButton.Miscellaneous.hasDestructiveAction, AttributeInfo(className: "NSButton", fullTitle: "HasDestructiveAction", patch: true)),
            ]),
            BlueprintSection(.NSButton.bezelColor, title: "Colors", attributes: [
                BlueprintAttribute(.NSButton.BezelColor.bezelColor, AttributeInfo(className: "NSButton", fullTitle: "BezelColor", objectValueType: .uiColor, patch: true)),
                BlueprintAttribute(.NSButton.ContentTintColor.contentTintColor, AttributeInfo(className: "NSButton", fullTitle: "ContentTintColor", objectValueType: .uiColor, patch: true)),
            ]),
            BlueprintSection(.NSButton.miscellaneous, title: "Misc", attributes: [
                BlueprintAttribute(.NSButton.Miscellaneous.maxAcceleratorLevel, AttributeInfo(className: "NSButton", fullTitle: "MaxAcceleratorLevel", patch: true)),
            ]),
            BlueprintSection(.NSButton.nsStatusBarButton, title: "NSStatusBarButton", attributes: [
                BlueprintAttribute(.NSButton.NSStatusBarButton.appearsDisabled, AttributeInfo(className: "NSStatusBarButton", fullTitle: "AppearsDisabled", getterString: "appearsDisabled", setterString: "setAppearsDisabled:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSButton.tintProminence, title: "TintProminence", attributes: [
                BlueprintAttribute(.NSButton.TintProminence.tintProminence, AttributeInfo(className: "NSButton", fullTitle: "TintProminence", getterString: "tintProminence", setterString: "setTintProminence:", enumList: "NSTintProminence", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSButton.images, title: "Images", attributes: [
                BlueprintAttribute(.NSButton.Images.image, AttributeInfo(className: "NSButton", fullTitle: "Image", getterString: "image", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.NSButton.Images.alternateImage, AttributeInfo(className: "NSButton", fullTitle: "AlternateImage", getterString: "alternateImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(.NSButton.imagePosition, title: "ImagePosition", attributes: [
                BlueprintAttribute(.NSButton.ImagePosition.imagePosition, AttributeInfo(className: "NSButton", fullTitle: "ImagePosition", getterString: "imagePosition", setterString: "setImagePosition:", enumList: "NSCellImagePosition", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSButton.imageScaling, title: "ImageScaling", attributes: [
                BlueprintAttribute(.NSButton.ImageScaling.imageScaling, AttributeInfo(className: "NSButton", fullTitle: "ImageScaling", getterString: "imageScaling", setterString: "setImageScaling:", enumList: "NSImageScaling", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSButton.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.NSButton.Behavior.imageHugsTitle, AttributeInfo(className: "NSButton", fullTitle: "ImageHugsTitle", getterString: "imageHugsTitle", setterString: "setImageHugsTitle:", patch: true, revision: 1)),
                BlueprintAttribute(.NSButton.Behavior.allowsMixedState, AttributeInfo(className: "NSButton", fullTitle: "AllowsMixedState", getterString: "allowsMixedState", setterString: "setAllowsMixedState:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSButton.symbolConfiguration, title: "SymbolConfiguration", attributes: [
                BlueprintAttribute(.NSButton.SymbolConfiguration.symbolConfiguration, AttributeInfo(className: "NSButton", fullTitle: "SymbolConfiguration", getterString: "symbolConfiguration", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.description))),
            ]),
            BlueprintSection(.NSButton.state, title: "State", attributes: [
                BlueprintAttribute(.NSButton.State.state, AttributeInfo(className: "NSButton", fullTitle: "State", getterString: "state", setterString: "setState:", enumList: "NSControlStateValue", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSButton.keyEquivalent, title: "KeyEquivalent", attributes: [
                BlueprintAttribute(.NSButton.KeyEquivalent.keyEquivalent, AttributeInfo(className: "NSButton", fullTitle: "KeyEquivalent", getterString: "keyEquivalent", setterString: "setKeyEquivalent:", objectValueType: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSButton.keyEquivalentModifierMask, title: "KeyEquivalentModifierMask", attributes: [
                BlueprintAttribute(.NSButton.KeyEquivalentModifierMask.keyEquivalentModifierMask, AttributeInfo(className: "NSButton", fullTitle: "KeyEquivalentModifierMask", getterString: "keyEquivalentModifierMask", setterString: "", revision: 1, presentation: .optionNames("NSEventModifierFlags"))),
            ]),
            BlueprintSection(.NSButton.borderShape, title: "BorderShape", attributes: [
                BlueprintAttribute(.NSButton.BorderShape.borderShape, AttributeInfo(className: "NSButton", fullTitle: "BorderShape", getterString: "borderShape", setterString: "setBorderShape:", enumList: "NSControlBorderShape", patch: true, revision: 1)),
            ]),
        ])

        static let nsScrollViewGroup = BlueprintGroup(.nsScrollView, title: "NSScrollView", on: .appKit, sections: [
            BlueprintSection(.NSScrollView.contentOffset, title: "ContentOffset", attributes: [
                BlueprintAttribute(.NSScrollView.ContentOffset.offset, AttributeInfo(className: "NSScrollView", fullTitle: "ContentOffset", getterString: "lks_contentOffset", setterString: "lks_setContentOffset:", patch: true)),
            ]),
            BlueprintSection(.NSScrollView.contentSize, title: "ContentSize", attributes: [
                BlueprintAttribute(.NSScrollView.ContentSize.size, AttributeInfo(className: "NSScrollView", fullTitle: "ContentSize", getterString: "lks_contentSize", setterString: "lks_setContentSize:", patch: true)),
            ]),
            BlueprintSection(.NSScrollView.contentInset, title: "ContentInset", attributes: [
                BlueprintAttribute(.NSScrollView.ContentInset.contentInset, AttributeInfo(className: "NSScrollView", fullTitle: "ContentInset", patch: true)),
                BlueprintAttribute(.NSScrollView.ContentInset.automaticallyAdjustsContentInsets, AttributeInfo(className: "NSScrollView", fullTitle: "AutomaticallyAdjustsContentInsets", patch: true)),
            ]),
            BlueprintSection(.NSScrollView.borderType, title: "BorderType", attributes: [
                BlueprintAttribute(.NSScrollView.BorderType.borderType, AttributeInfo(className: "NSScrollView", fullTitle: "BorderType", enumList: "NSBorderType", patch: true)),
            ]),
            BlueprintSection(.NSScrollView.scroller, title: "Scroller", attributes: [
                BlueprintAttribute(.NSScrollView.Scroller.horizontal, AttributeInfo(className: "NSScrollView", fullTitle: "HasHorizontalScroller", patch: true)),
                BlueprintAttribute(.NSScrollView.Scroller.vertical, AttributeInfo(className: "NSScrollView", fullTitle: "HasVerticalScroller", patch: true)),
                BlueprintAttribute(.NSScrollView.Scroller.autohidesScrollers, AttributeInfo(className: "NSScrollView", fullTitle: "AutohidesScrollers", patch: true)),
                BlueprintAttribute(.NSScrollView.Scroller.scrollerStyle, AttributeInfo(className: "NSScrollView", fullTitle: "ScrollerStyle", enumList: "NSScrollerStyle", patch: true)),
                BlueprintAttribute(.NSScrollView.Scroller.scrollerKnobStyle, AttributeInfo(className: "NSScrollView", fullTitle: "ScrollerKnobStyle", enumList: "NSScrollerKnobStyle", patch: true)),
                BlueprintAttribute(.NSScrollView.Scroller.scrollerInsets, AttributeInfo(className: "NSScrollView", fullTitle: "ScrollerInsets", patch: true)),
            ]),
            BlueprintSection(.NSScrollView.ruler, title: "Ruler", attributes: [
                BlueprintAttribute(.NSScrollView.Ruler.horizontal, AttributeInfo(className: "NSScrollView", fullTitle: "HasHorizontalRuler", patch: true)),
                BlueprintAttribute(.NSScrollView.Ruler.vertical, AttributeInfo(className: "NSScrollView", fullTitle: "HasVerticalRuler", patch: true)),
                BlueprintAttribute(.NSScrollView.Ruler.visible, AttributeInfo(className: "NSScrollView", fullTitle: "RulersVisible", patch: true)),
            ]),
            BlueprintSection(.NSScrollView.lineScroll, title: "LineScroll", attributes: [
                // briefTitle is display-only and never crosses the wire. These six
                // sit three-to-a-row with the label inside the field, so the section
                // title carries the meaning ("LineScroll") and the field only marks
                // the axis — the same shape as the scroller inset row above.
                BlueprintAttribute(.NSScrollView.LineScroll.horizontal, AttributeInfo(className: "NSScrollView", fullTitle: "HorizontalLineScroll", briefTitle: "H", patch: true)),
                BlueprintAttribute(.NSScrollView.LineScroll.vertical, AttributeInfo(className: "NSScrollView", fullTitle: "VerticalLineScroll", briefTitle: "V", patch: true)),
                BlueprintAttribute(.NSScrollView.LineScroll.lineScroll, AttributeInfo(className: "NSScrollView", fullTitle: "LineScroll", briefTitle: "⇄", patch: true)),
            ]),
            BlueprintSection(.NSScrollView.pageScroll, title: "PageScroll", attributes: [
                BlueprintAttribute(.NSScrollView.PageScroll.horizontal, AttributeInfo(className: "NSScrollView", fullTitle: "HorizontalPageScroll", briefTitle: "H", patch: true)),
                BlueprintAttribute(.NSScrollView.PageScroll.vertical, AttributeInfo(className: "NSScrollView", fullTitle: "VerticalPageScroll", briefTitle: "V", patch: true)),
                BlueprintAttribute(.NSScrollView.PageScroll.pageScroll, AttributeInfo(className: "NSScrollView", fullTitle: "PageScroll", briefTitle: "⇄", patch: true)),
            ]),
            BlueprintSection(.NSScrollView.scrollElasiticity, title: "ScrollElasiticity", attributes: [
                BlueprintAttribute(.NSScrollView.ScrollElasiticity.horizontal, AttributeInfo(className: "NSScrollView", fullTitle: "HorizontalScrollElasticity", enumList: "NSScrollElasticity", patch: true)),
                BlueprintAttribute(.NSScrollView.ScrollElasiticity.vertical, AttributeInfo(className: "NSScrollView", fullTitle: "VerticalScrollElasticity", enumList: "NSScrollElasticity", patch: true)),
            ]),
            BlueprintSection(.NSScrollView.miscellaneous, title: "Misc", attributes: [
                BlueprintAttribute(.NSScrollView.Miscellaneous.scrollsDynamically, AttributeInfo(className: "NSScrollView", fullTitle: "ScrollsDynamically", patch: true)),
                BlueprintAttribute(.NSScrollView.Miscellaneous.usesPredominantAxisScrolling, AttributeInfo(className: "NSScrollView", fullTitle: "UsesPredominantAxisScrolling", patch: true)),
            ]),
            BlueprintSection(.NSScrollView.magnification, title: "Magnification", attributes: [
                BlueprintAttribute(.NSScrollView.Magnification.allowsMagnification, AttributeInfo(className: "NSScrollView", fullTitle: "AllowsMagnification", patch: true)),
                // Three to a row under the AllowsMagnification switch; the section
                // title already says "Magnification", so the fields only need to
                // say which of the three values they are.
                BlueprintAttribute(.NSScrollView.Magnification.magnification, AttributeInfo(className: "NSScrollView", fullTitle: "Magnification", briefTitle: "Current", patch: true)),
                // Explicit getter/setter: the derived names would be
                // -maximunMagnification / -minimumMagnification, and NSScrollView
                // spells them -maxMagnification / -minMagnification. Deriving them
                // produced selectors nobody responds to, so both rows silently read
                // as nil and never appeared in the dashboard at all.
                BlueprintAttribute(.NSScrollView.Magnification.maximum, AttributeInfo(className: "NSScrollView", fullTitle: "MaximumMagnification", briefTitle: "Max", getterString: "maxMagnification", setterString: "setMaxMagnification:", patch: true)),
                BlueprintAttribute(.NSScrollView.Magnification.minimum, AttributeInfo(className: "NSScrollView", fullTitle: "MinimumMagnification", briefTitle: "Min", getterString: "minMagnification", setterString: "setMinMagnification:", patch: true)),
            ]),
            BlueprintSection(.NSScrollView.documentVisibleRect, title: "DocumentVisibleRect", attributes: [
                BlueprintAttribute(.NSScrollView.DocumentVisibleRect.documentVisibleRect, AttributeInfo(className: "NSScrollView", fullTitle: "DocumentVisibleRect", getterString: "documentVisibleRect", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSScrollView.backgroundColor, title: "BackgroundColor", attributes: [
                BlueprintAttribute(.NSScrollView.BackgroundColor.backgroundColor, AttributeInfo(className: "NSScrollView", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSScrollView.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.NSScrollView.Behavior.drawsBackground, AttributeInfo(className: "NSScrollView", fullTitle: "DrawsBackground", getterString: "drawsBackground", setterString: "setDrawsBackground:", patch: true, revision: 1)),
                BlueprintAttribute(.NSScrollView.Behavior.touchScrollingEnabled, AttributeInfo(className: "NSScrollView", fullTitle: "TouchScrollingEnabled", getterString: "isTouchScrollingEnabled", setterString: "setTouchScrollingEnabled:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSScrollView.contentInsets, title: "ContentInsets", attributes: [
                BlueprintAttribute(.NSScrollView.ContentInsets.contentInsets, AttributeInfo(className: "NSScrollView", fullTitle: "ContentInsets", getterString: "contentInsets", setterString: "setContentInsets:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSScrollView.minimumNumberOfTouchesForScrolling, title: "MinimumNumberOfTouchesForScrolling", attributes: [
                BlueprintAttribute(.NSScrollView.MinimumNumberOfTouchesForScrolling.minimumNumberOfTouchesForScrolling, AttributeInfo(className: "NSScrollView", fullTitle: "MinimumNumberOfTouchesForScrolling", getterString: "minimumNumberOfTouchesForScrolling", setterString: "setMinimumNumberOfTouchesForScrolling:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSScrollView.maximumNumberOfTouchesForScrolling, title: "MaximumNumberOfTouchesForScrolling", attributes: [
                BlueprintAttribute(.NSScrollView.MaximumNumberOfTouchesForScrolling.maximumNumberOfTouchesForScrolling, AttributeInfo(className: "NSScrollView", fullTitle: "MaximumNumberOfTouchesForScrolling", getterString: "maximumNumberOfTouchesForScrolling", setterString: "setMaximumNumberOfTouchesForScrolling:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSScrollView.findBarPosition, title: "FindBarPosition", attributes: [
                BlueprintAttribute(.NSScrollView.FindBarPosition.findBarPosition, AttributeInfo(className: "NSScrollView", fullTitle: "FindBarPosition", getterString: "findBarPosition", setterString: "setFindBarPosition:", enumList: "NSScrollViewFindBarPosition", patch: true, revision: 1)),
            ]),
        ])

        static let nsTableViewGroup = BlueprintGroup(.nsTableView, title: "NSTableView", on: .appKit, sections: [
            BlueprintSection(.NSTableView.rowHeight, title: "RowHeight", attributes: [
                BlueprintAttribute(.NSTableView.RowHeight.rowHeight, AttributeInfo(className: "NSTableView", fullTitle: "RowHeight", patch: true)),
            ]),
            BlueprintSection(.NSTableView.automaticRowHeights, title: "AutomaticRowHeights", attributes: [
                // NSTableView spells this usesAutomaticRowHeights, so both the
                // derived getter and the derived setter miss.
                BlueprintAttribute(.NSTableView.AutomaticRowHeights.automaticRowHeights, AttributeInfo(className: "NSTableView", fullTitle: "AutomaticRowHeights", getterString: "usesAutomaticRowHeights", setterString: "setUsesAutomaticRowHeights:", patch: true)),
            ]),
            BlueprintSection(.NSTableView.intercellSpacing, title: "IntercellSpacing", attributes: [
                BlueprintAttribute(.NSTableView.IntercellSpacing.intercellSpacing, AttributeInfo(className: "NSTableView", fullTitle: "IntercellSpacing", patch: true)),
            ]),
            BlueprintSection(.NSTableView.style, title: "Style", attributes: [
                BlueprintAttribute(.NSTableView.Style.style, AttributeInfo(className: "NSTableView", fullTitle: "Style", enumList: "NSTableViewStyle", patch: true)),
            ]),
            BlueprintSection(.NSTableView.columnAutoresizingStyle, title: "ColumnAutoresizingStyle", attributes: [
                BlueprintAttribute(.NSTableView.ColumnAutoresizingStyle.columnAutoresizingStyle, AttributeInfo(className: "NSTableView", fullTitle: "ColumnAutoresizingStyle", enumList: "NSTableViewColumnAutoresizingStyle", patch: true)),
            ]),
            BlueprintSection(.NSTableView.gridStyleMask, title: "GridStyleMask", attributes: [
                BlueprintAttribute(.NSTableView.GridStyleMask.gridStyleMask, AttributeInfo(className: "NSTableView", fullTitle: "GridStyleMask", enumList: "NSTableViewGridLineStyle", patch: true)),
            ]),
            BlueprintSection(.NSTableView.selectionHighlightStyle, title: "SelectionHighlightStyle", attributes: [
                BlueprintAttribute(.NSTableView.SelectionHighlightStyle.selectionHighlightStyle, AttributeInfo(className: "NSTableView", fullTitle: "SelectionHighlightStyle", enumList: "NSTableViewSelectionHighlightStyle", patch: true)),
            ]),
            BlueprintSection(.NSTableView.gridColor, title: "GridColor", attributes: [
                BlueprintAttribute(.NSTableView.GridColor.gridColor, AttributeInfo(className: "NSTableView", fullTitle: "GridColor", objectValueType: .uiColor, patch: true)),
            ]),
            BlueprintSection(.NSTableView.rowSizeStyle, title: "RowSizeStyle", attributes: [
                BlueprintAttribute(.NSTableView.RowSizeStyle.rowSizeStyle, AttributeInfo(className: "NSTableView", fullTitle: "RowSizeStyle", enumList: "NSTableViewRowSizeStyle", patch: true)),
            ]),
            BlueprintSection(.NSTableView.numberOfRows, title: "NumberOfRows", attributes: [
                BlueprintAttribute(.NSTableView.NumberOfRows.numberOfRows, AttributeInfo(className: "NSTableView", fullTitle: "NumberOfRows", setterString: "", patch: true)),
            ]),
            BlueprintSection(.NSTableView.numberOfColumns, title: "NumberOfColumns", attributes: [
                BlueprintAttribute(.NSTableView.NumberOfColumns.numberOfColumns, AttributeInfo(className: "NSTableView", fullTitle: "NumberOfColumns", setterString: "", patch: true)),
            ]),
            BlueprintSection(.NSTableView.useAlternatingRowBackgroundColors, title: "UseAlternatingRowBackgroundColors", attributes: [
                BlueprintAttribute(.NSTableView.UseAlternatingRowBackgroundColors.useAlternatingRowBackgroundColors, AttributeInfo(className: "NSTableView", fullTitle: "UsesAlternatingRowBackgroundColors", patch: true)),
            ]),
            BlueprintSection(.NSTableView.allowsColumnReordering, title: "AllowsColumnReordering", attributes: [
                BlueprintAttribute(.NSTableView.AllowsColumnReordering.allowsColumnReordering, AttributeInfo(className: "NSTableView", fullTitle: "AllowsColumnReordering", patch: true)),
            ]),
            BlueprintSection(.NSTableView.allowsColumnResizing, title: "AllowsColumnResizing", attributes: [
                BlueprintAttribute(.NSTableView.AllowsColumnResizing.allowsColumnResizing, AttributeInfo(className: "NSTableView", fullTitle: "AllowsColumnResizing", patch: true)),
            ]),
            BlueprintSection(.NSTableView.allowsMultipleSelection, title: "AllowsMultipleSelection", attributes: [
                BlueprintAttribute(.NSTableView.AllowsMultipleSelection.allowsMultipleSelection, AttributeInfo(className: "NSTableView", fullTitle: "AllowsMultipleSelection", patch: true)),
            ]),
            BlueprintSection(.NSTableView.allowsEmptySelection, title: "AllowsEmptySelection", attributes: [
                BlueprintAttribute(.NSTableView.AllowsEmptySelection.allowsEmptySelection, AttributeInfo(className: "NSTableView", fullTitle: "AllowsEmptySelection", patch: true)),
            ]),
            BlueprintSection(.NSTableView.allowsColumnSelection, title: "AllowsColumnSelection", attributes: [
                BlueprintAttribute(.NSTableView.AllowsColumnSelection.allowsColumnSelection, AttributeInfo(className: "NSTableView", fullTitle: "AllowsColumnSelection", patch: true)),
            ]),
            BlueprintSection(.NSTableView.allowsTypeSelect, title: "AllowsTypeSelect", attributes: [
                BlueprintAttribute(.NSTableView.AllowsTypeSelect.allowsTypeSelect, AttributeInfo(className: "NSTableView", fullTitle: "AllowsTypeSelect", patch: true)),
            ]),
            BlueprintSection(.NSTableView.draggingDestinationFeedbackStyle, title: "DraggingDestinationFeedbackStyle", attributes: [
                BlueprintAttribute(.NSTableView.DraggingDestinationFeedbackStyle.draggingDestinationFeedbackStyle, AttributeInfo(className: "NSTableView", fullTitle: "DraggingDestinationFeedbackStyle", enumList: "NSTableViewDraggingDestinationFeedbackStyle", patch: true)),
            ]),
            BlueprintSection(.NSTableView.autosave, title: "Autosave", attributes: [
                BlueprintAttribute(.NSTableView.AutosaveName.autosaveName, AttributeInfo(className: "NSTableView", fullTitle: "AutosaveName", objectValueType: .nsString, patch: true)),
                BlueprintAttribute(.NSTableView.AutosaveTableColumns.autosaveTableColumns, AttributeInfo(className: "NSTableView", fullTitle: "AutosaveTableColumns", patch: true)),
            ]),
            BlueprintSection(.NSTableView.floatsGroupRows, title: "FloatsGroupRows", attributes: [
                BlueprintAttribute(.NSTableView.FloatsGroupRows.floatsGroupRows, AttributeInfo(className: "NSTableView", fullTitle: "FloatsGroupRows", patch: true)),
            ]),
            BlueprintSection(.NSTableView.rowActionsVisible, title: "RowActionsVisible", attributes: [
                BlueprintAttribute(.NSTableView.RowActionsVisible.rowActionsVisible, AttributeInfo(className: "NSTableView", fullTitle: "RowActionsVisible", patch: true)),
            ]),
            BlueprintSection(.NSTableView.usesStaticContents, title: "UsesStaticContents", attributes: [
                BlueprintAttribute(.NSTableView.UsesStaticContents.usesStaticContents, AttributeInfo(className: "NSTableView", fullTitle: "UsesStaticContents", patch: true)),
            ]),
            BlueprintSection(.NSTableView.userInterfaceLayoutDirection, title: "UserInterfaceLayoutDirection", attributes: [
                BlueprintAttribute(.NSTableView.UserInterfaceLayoutDirection.userInterfaceLayoutDirection, AttributeInfo(className: "NSTableView", fullTitle: "UserInterfaceLayoutDirection", enumList: "NSUserInterfaceLayoutDirection", patch: true)),
            ]),
            BlueprintSection(.NSTableView.verticalMotionCanBeginDrag, title: "VerticalMotionCanBeginDrag", attributes: [
                BlueprintAttribute(.NSTableView.VerticalMotionCanBeginDrag.verticalMotionCanBeginDrag, AttributeInfo(className: "NSTableView", fullTitle: "VerticalMotionCanBeginDrag", patch: true)),
            ]),
            BlueprintSection(.NSTableView.backgroundColor, title: "BackgroundColor", attributes: [
                BlueprintAttribute(.NSTableView.BackgroundColor.backgroundColor, AttributeInfo(className: "NSTableView", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSTableView.effectiveRowSizeStyle, title: "EffectiveRowSizeStyle", attributes: [
                BlueprintAttribute(.NSTableView.EffectiveRowSizeStyle.effectiveRowSizeStyle, AttributeInfo(className: "NSTableView", fullTitle: "EffectiveRowSizeStyle", getterString: "effectiveRowSizeStyle", setterString: "", enumList: "NSTableViewRowSizeStyle", revision: 1)),
            ]),
            BlueprintSection(.NSTableView.editedColumn, title: "EditedColumn", attributes: [
                BlueprintAttribute(.NSTableView.EditedColumn.editedColumn, AttributeInfo(className: "NSTableView", fullTitle: "EditedColumn", getterString: "editedColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSTableView.editedRow, title: "EditedRow", attributes: [
                BlueprintAttribute(.NSTableView.EditedRow.editedRow, AttributeInfo(className: "NSTableView", fullTitle: "EditedRow", getterString: "editedRow", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSTableView.clickedColumn, title: "ClickedColumn", attributes: [
                BlueprintAttribute(.NSTableView.ClickedColumn.clickedColumn, AttributeInfo(className: "NSTableView", fullTitle: "ClickedColumn", getterString: "clickedColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSTableView.clickedRow, title: "ClickedRow", attributes: [
                BlueprintAttribute(.NSTableView.ClickedRow.clickedRow, AttributeInfo(className: "NSTableView", fullTitle: "ClickedRow", getterString: "clickedRow", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSTableView.selectedColumn, title: "SelectedColumn", attributes: [
                BlueprintAttribute(.NSTableView.SelectedColumn.selectedColumn, AttributeInfo(className: "NSTableView", fullTitle: "SelectedColumn", getterString: "selectedColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSTableView.selectedRow, title: "SelectedRow", attributes: [
                BlueprintAttribute(.NSTableView.SelectedRow.selectedRow, AttributeInfo(className: "NSTableView", fullTitle: "SelectedRow", getterString: "selectedRow", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSTableView.numberOfSelectedColumns, title: "NumberOfSelectedColumns", attributes: [
                BlueprintAttribute(.NSTableView.NumberOfSelectedColumns.numberOfSelectedColumns, AttributeInfo(className: "NSTableView", fullTitle: "NumberOfSelectedColumns", getterString: "numberOfSelectedColumns", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSTableView.numberOfSelectedRows, title: "NumberOfSelectedRows", attributes: [
                BlueprintAttribute(.NSTableView.NumberOfSelectedRows.numberOfSelectedRows, AttributeInfo(className: "NSTableView", fullTitle: "NumberOfSelectedRows", getterString: "numberOfSelectedRows", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSTableView.effectiveStyle, title: "EffectiveStyle", attributes: [
                BlueprintAttribute(.NSTableView.EffectiveStyle.effectiveStyle, AttributeInfo(className: "NSTableView", fullTitle: "EffectiveStyle", getterString: "effectiveStyle", setterString: "", enumList: "NSTableViewStyle", revision: 1)),
            ]),
        ])

        static let nsTextViewGroup = BlueprintGroup(.nsTextView, title: "NSTextView", on: .appKit, sections: [
            BlueprintSection(.NSTextView.font, title: "Font", attributes: [
                BlueprintAttribute(.NSTextView.Font.name, AttributeInfo(className: "NSTextView", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", objectValueType: .nsString, patch: false)),
                BlueprintAttribute(.NSTextView.Font.size, AttributeInfo(className: "NSTextView", fullTitle: "FontSize", getterString: "lks_fontSize", setterString: "setLks_fontSize:", patch: true)),
            ]),
            BlueprintSection(.NSTextView.basic, title: "Basic", attributes: [
                BlueprintAttribute(.NSTextView.Basic.editable, AttributeInfo(className: "NSTextView", fullTitle: "Editable", getterString: "isEditable", patch: false)),
                BlueprintAttribute(.NSTextView.Basic.selectable, AttributeInfo(className: "NSTextView", fullTitle: "Selectable", getterString: "isSelectable", patch: false)),
                BlueprintAttribute(.NSTextView.Basic.richText, AttributeInfo(className: "NSTextView", fullTitle: "RichText", getterString: "isRichText", patch: false)),
                BlueprintAttribute(.NSTextView.Basic.fieldEditor, AttributeInfo(className: "NSTextView", fullTitle: "FieldEditor", getterString: "isFieldEditor", patch: false)),
                BlueprintAttribute(.NSTextView.Basic.importsGraphics, AttributeInfo(className: "NSTextView", fullTitle: "ImportsGraphics", patch: false)),
            ]),
            BlueprintSection(.NSTextView.string, title: "String", attributes: [
                BlueprintAttribute(.NSTextView.String.string, AttributeInfo(className: "NSTextView", fullTitle: "String", objectValueType: .nsString, patch: true)),
            ]),
            BlueprintSection(.NSTextView.textColor, title: "TextColor", attributes: [
                BlueprintAttribute(.NSTextView.TextColor.color, AttributeInfo(className: "NSTextView", fullTitle: "TextColor", objectValueType: .uiColor, patch: true)),
            ]),
            BlueprintSection(.NSTextView.alignment, title: "Alignment", attributes: [
                BlueprintAttribute(.NSTextView.Alignment.alignment, AttributeInfo(className: "NSTextView", fullTitle: "Alignment", enumList: "NSTextAlignment_AppKit", patch: true)),
            ]),
            BlueprintSection(.NSTextView.containerInset, title: "ContainerInset", attributes: [
                BlueprintAttribute(.NSTextView.ContainerInset.inset, AttributeInfo(className: "NSTextView", fullTitle: "TextContainerInset", patch: true)),
            ]),
            BlueprintSection(.NSTextView.baseWritingDirection, title: "BaseWritingDirection", attributes: [
                BlueprintAttribute(.NSTextView.BaseWritingDirection.baseWritingDirection, AttributeInfo(className: "NSTextView", fullTitle: "BaseWritingDirection", enumList: "NSWritingDirection", patch: false)),
            ]),
            BlueprintSection(.NSTextView.size, title: "Size", attributes: [
                BlueprintAttribute(.NSTextView.MaxSize.maxSize, AttributeInfo(className: "NSTextView", fullTitle: "MaxSize", patch: true)),
                BlueprintAttribute(.NSTextView.MinSize.minSize, AttributeInfo(className: "NSTextView", fullTitle: "MinSize", patch: true)),
            ]),
            BlueprintSection(.NSTextView.resizable, title: "Resizable", attributes: [
                // Derived getter would be -horizontallyResizable; it is -isHorizontallyResizable.
                BlueprintAttribute(.NSTextView.Resizable.horizontal, AttributeInfo(className: "NSTextView", fullTitle: "HorizontallyResizable", getterString: "isHorizontallyResizable", patch: false)),
                // Derived getter would be -verticallyResizable; it is -isVerticallyResizable.
                BlueprintAttribute(.NSTextView.Resizable.vertical, AttributeInfo(className: "NSTextView", fullTitle: "VerticallyResizable", getterString: "isVerticallyResizable", patch: false)),
            ]),
            BlueprintSection(.NSTextView.textContainerOrigin, title: "TextContainerOrigin", attributes: [
                BlueprintAttribute(.NSTextView.TextContainerOrigin.textContainerOrigin, AttributeInfo(className: "NSTextView", fullTitle: "TextContainerOrigin", getterString: "textContainerOrigin", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSTextView.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.NSTextView.Behavior.shouldDrawInsertionPoint, AttributeInfo(className: "NSTextView", fullTitle: "ShouldDrawInsertionPoint", getterString: "shouldDrawInsertionPoint", setterString: "", revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.usesAdaptiveColorMappingForDarkAppearance, AttributeInfo(className: "NSTextView", fullTitle: "UsesAdaptiveColorMappingForDarkAppearance", getterString: "usesAdaptiveColorMappingForDarkAppearance", setterString: "setUsesAdaptiveColorMappingForDarkAppearance:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.displaysLinkToolTips, AttributeInfo(className: "NSTextView", fullTitle: "DisplaysLinkToolTips", getterString: "displaysLinkToolTips", setterString: "setDisplaysLinkToolTips:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.acceptsGlyphInfo, AttributeInfo(className: "NSTextView", fullTitle: "AcceptsGlyphInfo", getterString: "acceptsGlyphInfo", setterString: "setAcceptsGlyphInfo:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.usesRuler, AttributeInfo(className: "NSTextView", fullTitle: "UsesRuler", getterString: "usesRuler", setterString: "setUsesRuler:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.usesInspectorBar, AttributeInfo(className: "NSTextView", fullTitle: "UsesInspectorBar", getterString: "usesInspectorBar", setterString: "setUsesInspectorBar:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.continuousSpellCheckingEnabled, AttributeInfo(className: "NSTextView", fullTitle: "ContinuousSpellCheckingEnabled", getterString: "isContinuousSpellCheckingEnabled", setterString: "setContinuousSpellCheckingEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.grammarCheckingEnabled, AttributeInfo(className: "NSTextView", fullTitle: "GrammarCheckingEnabled", getterString: "isGrammarCheckingEnabled", setterString: "setGrammarCheckingEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.allowsDocumentBackgroundColorChange, AttributeInfo(className: "NSTextView", fullTitle: "AllowsDocumentBackgroundColorChange", getterString: "allowsDocumentBackgroundColorChange", setterString: "setAllowsDocumentBackgroundColorChange:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.allowsUndo, AttributeInfo(className: "NSTextView", fullTitle: "AllowsUndo", getterString: "allowsUndo", setterString: "setAllowsUndo:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.coalescingUndo, AttributeInfo(className: "NSTextView", fullTitle: "CoalescingUndo", getterString: "isCoalescingUndo", setterString: "", revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.allowsImageEditing, AttributeInfo(className: "NSTextView", fullTitle: "AllowsImageEditing", getterString: "allowsImageEditing", setterString: "setAllowsImageEditing:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.usesRolloverButtonForSelection, AttributeInfo(className: "NSTextView", fullTitle: "UsesRolloverButtonForSelection", getterString: "usesRolloverButtonForSelection", setterString: "setUsesRolloverButtonForSelection:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.drawsBackground, AttributeInfo(className: "NSTextView", fullTitle: "DrawsBackground", getterString: "drawsBackground", setterString: "setDrawsBackground:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.usesFontPanel, AttributeInfo(className: "NSTextView", fullTitle: "UsesFontPanel", getterString: "usesFontPanel", setterString: "setUsesFontPanel:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.rulerVisible, AttributeInfo(className: "NSTextView", fullTitle: "RulerVisible", getterString: "isRulerVisible", setterString: "setRulerVisible:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.writingToolsActive, AttributeInfo(className: "NSTextView", fullTitle: "WritingToolsActive", getterString: "isWritingToolsActive", setterString: "", revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.smartInsertDeleteEnabled, AttributeInfo(className: "NSTextView", fullTitle: "SmartInsertDeleteEnabled", getterString: "smartInsertDeleteEnabled", setterString: "setSmartInsertDeleteEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.automaticQuoteSubstitutionEnabled, AttributeInfo(className: "NSTextView", fullTitle: "AutomaticQuoteSubstitutionEnabled", getterString: "isAutomaticQuoteSubstitutionEnabled", setterString: "setAutomaticQuoteSubstitutionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.automaticLinkDetectionEnabled, AttributeInfo(className: "NSTextView", fullTitle: "AutomaticLinkDetectionEnabled", getterString: "isAutomaticLinkDetectionEnabled", setterString: "setAutomaticLinkDetectionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.automaticDataDetectionEnabled, AttributeInfo(className: "NSTextView", fullTitle: "AutomaticDataDetectionEnabled", getterString: "isAutomaticDataDetectionEnabled", setterString: "setAutomaticDataDetectionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.automaticDashSubstitutionEnabled, AttributeInfo(className: "NSTextView", fullTitle: "AutomaticDashSubstitutionEnabled", getterString: "isAutomaticDashSubstitutionEnabled", setterString: "setAutomaticDashSubstitutionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.automaticTextReplacementEnabled, AttributeInfo(className: "NSTextView", fullTitle: "AutomaticTextReplacementEnabled", getterString: "isAutomaticTextReplacementEnabled", setterString: "setAutomaticTextReplacementEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.automaticSpellingCorrectionEnabled, AttributeInfo(className: "NSTextView", fullTitle: "AutomaticSpellingCorrectionEnabled", getterString: "isAutomaticSpellingCorrectionEnabled", setterString: "setAutomaticSpellingCorrectionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.usesFindPanel, AttributeInfo(className: "NSTextView", fullTitle: "UsesFindPanel", getterString: "usesFindPanel", setterString: "setUsesFindPanel:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.usesFindBar, AttributeInfo(className: "NSTextView", fullTitle: "UsesFindBar", getterString: "usesFindBar", setterString: "setUsesFindBar:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.incrementalSearchingEnabled, AttributeInfo(className: "NSTextView", fullTitle: "IncrementalSearchingEnabled", getterString: "isIncrementalSearchingEnabled", setterString: "setIncrementalSearchingEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.automaticTextCompletionEnabled, AttributeInfo(className: "NSTextView", fullTitle: "AutomaticTextCompletionEnabled", getterString: "isAutomaticTextCompletionEnabled", setterString: "setAutomaticTextCompletionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Behavior.allowsCharacterPickerTouchBarItem, AttributeInfo(className: "NSTextView", fullTitle: "AllowsCharacterPickerTouchBarItem", getterString: "allowsCharacterPickerTouchBarItem", setterString: "setAllowsCharacterPickerTouchBarItem:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSTextView.selectionAffinity, title: "SelectionAffinity", attributes: [
                BlueprintAttribute(.NSTextView.SelectionAffinity.selectionAffinity, AttributeInfo(className: "NSTextView", fullTitle: "SelectionAffinity", getterString: "selectionAffinity", setterString: "", enumList: "NSSelectionAffinity", revision: 1)),
            ]),
            BlueprintSection(.NSTextView.selectionGranularity, title: "SelectionGranularity", attributes: [
                BlueprintAttribute(.NSTextView.SelectionGranularity.selectionGranularity, AttributeInfo(className: "NSTextView", fullTitle: "SelectionGranularity", getterString: "selectionGranularity", setterString: "setSelectionGranularity:", enumList: "NSSelectionGranularity", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSTextView.colors, title: "Colors", attributes: [
                BlueprintAttribute(.NSTextView.Colors.insertionPointColor, AttributeInfo(className: "NSTextView", fullTitle: "InsertionPointColor", getterString: "insertionPointColor", setterString: "setInsertionPointColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.NSTextView.Colors.backgroundColor, AttributeInfo(className: "NSTextView", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSTextView.writingToolsBehavior, title: "WritingToolsBehavior", attributes: [
                BlueprintAttribute(.NSTextView.WritingToolsBehavior.writingToolsBehavior, AttributeInfo(className: "NSTextView", fullTitle: "WritingToolsBehavior", getterString: "writingToolsBehavior", setterString: "setWritingToolsBehavior:", enumList: "NSWritingToolsBehavior", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSTextView.allowedWritingToolsResultOptions, title: "AllowedWritingToolsResultOptions", attributes: [
                BlueprintAttribute(.NSTextView.AllowedWritingToolsResultOptions.allowedWritingToolsResultOptions, AttributeInfo(className: "NSTextView", fullTitle: "AllowedWritingToolsResultOptions", getterString: "allowedWritingToolsResultOptions", setterString: "", revision: 1, presentation: .optionNames("NSWritingToolsResultOptions"))),
            ]),
            BlueprintSection(.NSTextView.inlinePredictionType, title: "InlinePredictionType", attributes: [
                BlueprintAttribute(.NSTextView.InlinePredictionType.inlinePredictionType, AttributeInfo(className: "NSTextView", fullTitle: "InlinePredictionType", getterString: "inlinePredictionType", setterString: "setInlinePredictionType:", enumList: "NSTextInputTraitType", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSTextView.mathExpressionCompletionType, title: "MathExpressionCompletionType", attributes: [
                BlueprintAttribute(.NSTextView.MathExpressionCompletionType.mathExpressionCompletionType, AttributeInfo(className: "NSTextView", fullTitle: "MathExpressionCompletionType", getterString: "mathExpressionCompletionType", setterString: "setMathExpressionCompletionType:", enumList: "NSTextInputTraitType", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSTextView.selectedRange, title: "SelectedRange", attributes: [
                BlueprintAttribute(.NSTextView.SelectedRange.selectedRange, AttributeInfo(className: "NSTextView", fullTitle: "SelectedRange", getterString: "selectedRange", setterString: "", revision: 1, presentation: .structure)),
            ]),
        ])

        static let nsTextFieldGroup = BlueprintGroup(.nsTextField, title: "NSTextField", on: .appKit, sections: [
            BlueprintSection(.NSTextField.bezelStyle, title: "BezelStyle", attributes: [
                BlueprintAttribute(.NSTextField.BezelStyle.bezelStyle, AttributeInfo(className: "NSTextField", fullTitle: "BezelStyle", enumList: "NSTextFieldBezelStyle", patch: true)),
            ]),
            BlueprintSection(.NSTextField.lineBreakStrategy, title: "LineBreakStrategy", attributes: [
                BlueprintAttribute(.NSTextField.LineBreakStrategy.lineBreakStrategy, AttributeInfo(className: "NSTextField", fullTitle: "LineBreakStrategy", enumList: "NSLineBreakStrategy", patch: true)),
            ]),
            BlueprintSection(.NSTextField.bordered, attributes: [
                BlueprintAttribute(.NSTextField.Bordered.bordered, AttributeInfo(className: "NSTextField", fullTitle: "Bordered", getterString: "isBordered", patch: false)),
                BlueprintAttribute(.NSTextField.Bezeled.bezeled, AttributeInfo(className: "NSTextField", fullTitle: "Bezeled", getterString: "isBezeled", patch: false)),
                BlueprintAttribute(.NSTextField.Editable.editable, AttributeInfo(className: "NSTextField", fullTitle: "Editable", getterString: "isEditable", patch: false)),
                BlueprintAttribute(.NSTextField.Selectable.selectable, AttributeInfo(className: "NSTextField", fullTitle: "Selectable", getterString: "isSelectable", patch: false)),
                BlueprintAttribute(.NSTextField.DrawsBackground.drawsBackground, AttributeInfo(className: "NSTextField", fullTitle: "DrawsBackground", patch: true)),
                BlueprintAttribute(.NSTextField.AllowsDefaultTighteningForTruncation.allowsDefaultTighteningForTruncation, AttributeInfo(className: "NSTextField", fullTitle: "AllowsDefaultTighteningForTruncation", patch: true)),
                BlueprintAttribute(.NSTextField.AllowsEditingTextAttributes.allowsEditingTextAttributes, AttributeInfo(className: "NSTextField", fullTitle: "AllowsEditingTextAttributes", patch: true)),
                BlueprintAttribute(.NSTextField.ImportsGraphics.importsGraphics, AttributeInfo(className: "NSTextField", fullTitle: "ImportsGraphics", patch: true)),
            ]),
            BlueprintSection(.NSTextField.textColor, title: "Colors", attributes: [
                BlueprintAttribute(.NSTextField.TextColor.color, AttributeInfo(className: "NSTextField", fullTitle: "TextColor", objectValueType: .uiColor, patch: true)),
                BlueprintAttribute(.NSTextField.BackgroundColor.color, AttributeInfo(className: "NSTextField", fullTitle: "BackgroundColor", objectValueType: .uiColor, patch: true)),
            ]),
            BlueprintSection(.NSTextField.placeholder, title: "Placeholder", attributes: [
                BlueprintAttribute(.NSTextField.Placeholder.placeholder, AttributeInfo(className: "NSTextField", fullTitle: "PlaceholderString", objectValueType: .nsString, patch: true)),
            ]),
            BlueprintSection(.NSTextField.preferredMaxLayoutWidth, title: "Layout", attributes: [
                BlueprintAttribute(.NSTextField.PreferredMaxLayoutWidth.preferredMaxLayoutWidth, AttributeInfo(className: "NSTextField", fullTitle: "PreferredMaxLayoutWidth", patch: true)),
                BlueprintAttribute(.NSTextField.MaximumNumberOfLines.maximumNumberOfLines, AttributeInfo(className: "NSTextField", fullTitle: "MaximumNumberOfLines", patch: true)),
            ]),
            BlueprintSection(.NSTextField.nsTokenField, title: "NSTokenField", attributes: [
                BlueprintAttribute(.NSTextField.NSTokenField.tokenStyle, AttributeInfo(className: "NSTokenField", fullTitle: "TokenStyle", getterString: "tokenStyle", setterString: "setTokenStyle:", enumList: "NSTokenStyle", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextField.NSTokenField.completionDelay, AttributeInfo(className: "NSTokenField", fullTitle: "CompletionDelay", getterString: "completionDelay", setterString: "setCompletionDelay:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSTextField.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.NSTextField.Behavior.acceptsFirstResponder, AttributeInfo(className: "NSTextField", fullTitle: "AcceptsFirstResponder", getterString: "acceptsFirstResponder", setterString: "", revision: 1)),
                BlueprintAttribute(.NSTextField.Behavior.allowsWritingTools, AttributeInfo(className: "NSTextField", fullTitle: "AllowsWritingTools", getterString: "allowsWritingTools", setterString: "setAllowsWritingTools:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextField.Behavior.allowsWritingToolsAffordance, AttributeInfo(className: "NSTextField", fullTitle: "AllowsWritingToolsAffordance", getterString: "allowsWritingToolsAffordance", setterString: "setAllowsWritingToolsAffordance:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextField.Behavior.resolvesNaturalAlignmentWithBaseWritingDirection, AttributeInfo(className: "NSTextField", fullTitle: "ResolvesNaturalAlignmentWithBaseWritingDirection", getterString: "resolvesNaturalAlignmentWithBaseWritingDirection", setterString: "setResolvesNaturalAlignmentWithBaseWritingDirection:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextField.Behavior.automaticTextCompletionEnabled, AttributeInfo(className: "NSTextField", fullTitle: "AutomaticTextCompletionEnabled", getterString: "isAutomaticTextCompletionEnabled", setterString: "setAutomaticTextCompletionEnabled:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTextField.Behavior.allowsCharacterPickerTouchBarItem, AttributeInfo(className: "NSTextField", fullTitle: "AllowsCharacterPickerTouchBarItem", getterString: "allowsCharacterPickerTouchBarItem", setterString: "setAllowsCharacterPickerTouchBarItem:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSTextField.borderShape, title: "BorderShape", attributes: [
                BlueprintAttribute(.NSTextField.BorderShape.borderShape, AttributeInfo(className: "NSTextField", fullTitle: "BorderShape", getterString: "borderShape", setterString: "setBorderShape:", enumList: "NSControlBorderShape", patch: true, revision: 1)),
            ]),
        ])

        static let nsVisualEffectViewGroup = BlueprintGroup(.nsVisualEffectView, title: "NSVisualEffectView", on: .appKit, sections: [
            BlueprintSection(.NSVisualEffectView.material, title: "Material", attributes: [
                BlueprintAttribute(.NSVisualEffectView.Material.material, AttributeInfo(className: "NSVisualEffectView", fullTitle: "Material", enumList: "NSVisualEffectMaterial", patch: true)),
            ]),
            BlueprintSection(.NSVisualEffectView.interiorBackgroundStyle, title: "InteriorBackgroundStyle", attributes: [
                BlueprintAttribute(.NSVisualEffectView.InteriorBackgroundStyle.interiorBackgroundStyle, AttributeInfo(className: "NSVisualEffectView", fullTitle: "InteriorBackgroundStyle", enumList: "NSBackgroundStyle", patch: true)),
            ]),
            BlueprintSection(.NSVisualEffectView.blendingMode, title: "BlendingMode", attributes: [
                BlueprintAttribute(.NSVisualEffectView.BlendingMode.blendingMode, AttributeInfo(className: "NSVisualEffectView", fullTitle: "BlendingMode", enumList: "NSVisualEffectBlendingMode", patch: true)),
            ]),
            BlueprintSection(.NSVisualEffectView.state, title: "State", attributes: [
                BlueprintAttribute(.NSVisualEffectView.State.state, AttributeInfo(className: "NSVisualEffectView", fullTitle: "State", enumList: "NSVisualEffectState", patch: true)),
            ]),
            BlueprintSection(.NSVisualEffectView.emphasized, title: "Emphasized", attributes: [
                BlueprintAttribute(.NSVisualEffectView.Emphasized.emphasized, AttributeInfo(className: "NSVisualEffectView", fullTitle: "Emphasized", getterString: "isEmphasized", patch: true)),
            ]),
            BlueprintSection(.NSVisualEffectView.maskImage, title: "MaskImage", attributes: [
                BlueprintAttribute(.NSVisualEffectView.MaskImage.maskImage, AttributeInfo(className: "NSVisualEffectView", fullTitle: "MaskImage", getterString: "maskImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
        ])

        static let nsStackViewGroup = BlueprintGroup(.nsStackView, title: "NSStackView", on: .appKit, sections: [
            BlueprintSection(.NSStackView.orientation, title: "Orientation", attributes: [
                BlueprintAttribute(.NSStackView.Orientation.orientation, AttributeInfo(className: "NSStackView", fullTitle: "Orientation", enumList: "NSUserInterfaceLayoutOrientation", patch: true)),
            ]),
            BlueprintSection(.NSStackView.edgeInsets, title: "EdgeInsets", attributes: [
                BlueprintAttribute(.NSStackView.EdgeInsets.edgeInsets, AttributeInfo(className: "NSStackView", fullTitle: "EdgeInsets", patch: true)),
            ]),
            BlueprintSection(.NSStackView.detachesHiddenViews, title: "DetachesHiddenViews", attributes: [
                BlueprintAttribute(.NSStackView.DetachesHiddenViews.detachesHiddenViews, AttributeInfo(className: "NSStackView", fullTitle: "DetachesHiddenViews", patch: true)),
            ]),
            BlueprintSection(.NSStackView.distribution, title: "Distribution", attributes: [
                BlueprintAttribute(.NSStackView.Distribution.distribution, AttributeInfo(className: "NSStackView", fullTitle: "Distribution", enumList: "NSStackViewDistribution", patch: true)),
            ]),
            BlueprintSection(.NSStackView.alignment, title: "Alignment", attributes: [
                BlueprintAttribute(.NSStackView.Alignment.alignment, AttributeInfo(className: "NSStackView", fullTitle: "Alignment", enumList: "NSLayoutAttribute", patch: true)),
            ]),
            BlueprintSection(.NSStackView.spacing, title: "Spacing", attributes: [
                BlueprintAttribute(.NSStackView.Spacing.spacing, AttributeInfo(className: "NSStackView", fullTitle: "Spacing", patch: true)),
            ]),
        ])

        static let nsWindowGroup = BlueprintGroup(.nsWindow, title: "NSWindow", on: .appKit, sections: [
            BlueprintSection(.NSWindow.title, title: "Title", attributes: [
                BlueprintAttribute(.NSWindow.Title.title, AttributeInfo(className: "NSWindow", fullTitle: "Title", objectValueType: .nsString, patch: false)),
            ]),
            BlueprintSection(.NSWindow.subtitle, title: "Subtitle", attributes: [
                BlueprintAttribute(.NSWindow.Title.subtitle, AttributeInfo(className: "NSWindow", fullTitle: "Subtitle", objectValueType: .nsString, patch: false, osVersion: 11)),
            ]),
            BlueprintSection(.NSWindow.state, title: "State", attributes: [
                BlueprintAttribute(.NSWindow.State.keyWindow, AttributeInfo(className: "NSWindow", fullTitle: "KeyWindow", getterString: "isKeyWindow", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.State.mainWindow, AttributeInfo(className: "NSWindow", fullTitle: "MainWindow", getterString: "isMainWindow", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.State.visible, AttributeInfo(className: "NSWindow", fullTitle: "Visible", getterString: "isVisible", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.State.canBecomeKeyWindow, AttributeInfo(className: "NSWindow", fullTitle: "CanBecomeKeyWindow", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.State.canBecomeMainWindow, AttributeInfo(className: "NSWindow", fullTitle: "CanBecomeMainWindow", setterString: "", patch: false)),
            ]),
            BlueprintSection(.NSWindow.style, title: "StyleMask", attributes: [
                BlueprintAttribute(.NSWindow.Style.titled, AttributeInfo(className: "NSWindow", fullTitle: "Titled", getterString: "lks_styleMaskTitled", setterString: "setLks_styleMaskTitled:", patch: true)),
                BlueprintAttribute(.NSWindow.Style.closable, AttributeInfo(className: "NSWindow", fullTitle: "Closable", getterString: "lks_styleMaskClosable", setterString: "setLks_styleMaskClosable:", patch: true)),
                BlueprintAttribute(.NSWindow.Style.miniaturizable, AttributeInfo(className: "NSWindow", fullTitle: "Miniaturizable", getterString: "lks_styleMaskMiniaturizable", setterString: "setLks_styleMaskMiniaturizable:", patch: true)),
                BlueprintAttribute(.NSWindow.Style.resizable, AttributeInfo(className: "NSWindow", fullTitle: "Resizable", getterString: "lks_styleMaskResizable", setterString: "setLks_styleMaskResizable:", patch: true)),
                BlueprintAttribute(.NSWindow.Style.unifiedTitleAndToolbar, AttributeInfo(className: "NSWindow", fullTitle: "UnifiedTitleAndToolbar", getterString: "lks_styleMaskUnifiedTitleAndToolbar", setterString: "setLks_styleMaskUnifiedTitleAndToolbar:", patch: true)),
                BlueprintAttribute(.NSWindow.Style.fullScreen, AttributeInfo(className: "NSWindow", fullTitle: "FullScreen", getterString: "lks_styleMaskFullScreen", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.Style.fullSizeContentView, AttributeInfo(className: "NSWindow", fullTitle: "FullSizeContentView", getterString: "lks_styleMaskFullSizeContentView", setterString: "setLks_styleMaskFullSizeContentView:", patch: true)),
                BlueprintAttribute(.NSWindow.Style.utilityWindow, AttributeInfo(className: "NSWindow", fullTitle: "UtilityWindow", getterString: "lks_styleMaskUtilityWindow", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.Style.docModalWindow, AttributeInfo(className: "NSWindow", fullTitle: "DocModalWindow", getterString: "lks_styleMaskDocModalWindow", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.Style.nonactivatingPanel, AttributeInfo(className: "NSWindow", fullTitle: "NonactivatingPanel", getterString: "lks_styleMaskNonactivatingPanel", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.Style.hudWindow, AttributeInfo(className: "NSWindow", fullTitle: "HUDWindow", getterString: "lks_styleMaskHUDWindow", setterString: "", patch: false)),
            ]),
            BlueprintSection(.NSWindow.collectionBehavior, title: "CollectionBehavior", attributes: [
                BlueprintAttribute(.NSWindow.CollectionBehavior.canJoinAllSpaces, AttributeInfo(className: "NSWindow", fullTitle: "CanJoinAllSpaces", getterString: "lks_collectionBehaviorCanJoinAllSpaces", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.CollectionBehavior.moveToActiveSpace, AttributeInfo(className: "NSWindow", fullTitle: "MoveToActiveSpace", getterString: "lks_collectionBehaviorMoveToActiveSpace", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.CollectionBehavior.participatesInCycle, AttributeInfo(className: "NSWindow", fullTitle: "ParticipatesInCycle", getterString: "lks_collectionBehaviorParticipatesInCycle", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.CollectionBehavior.ignoresCycle, AttributeInfo(className: "NSWindow", fullTitle: "IgnoresCycle", getterString: "lks_collectionBehaviorIgnoresCycle", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.CollectionBehavior.fullScreenPrimary, AttributeInfo(className: "NSWindow", fullTitle: "FullScreenPrimary", getterString: "lks_collectionBehaviorFullScreenPrimary", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.CollectionBehavior.fullScreenAuxiliary, AttributeInfo(className: "NSWindow", fullTitle: "FullScreenAuxiliary", getterString: "lks_collectionBehaviorFullScreenAuxiliary", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.CollectionBehavior.fullScreenNone, AttributeInfo(className: "NSWindow", fullTitle: "FullScreenNone", getterString: "lks_collectionBehaviorFullScreenNone", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.CollectionBehavior.fullScreenAllowsTiling, AttributeInfo(className: "NSWindow", fullTitle: "FullScreenAllowsTiling", getterString: "lks_collectionBehaviorFullScreenAllowsTiling", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.CollectionBehavior.fullScreenDisallowsTiling, AttributeInfo(className: "NSWindow", fullTitle: "FullScreenDisallowsTiling", getterString: "lks_collectionBehaviorFullScreenDisallowsTiling", setterString: "", patch: false)),
            ]),
            BlueprintSection(.NSWindow.appearance, title: "Appearance", attributes: [
                BlueprintAttribute(.NSWindow.Appearance.titlebarAppearsTransparent, AttributeInfo(className: "NSWindow", fullTitle: "TitlebarAppearsTransparent", patch: true)),
                BlueprintAttribute(.NSWindow.Appearance.backgroundColor, AttributeInfo(className: "NSWindow", fullTitle: "BackgroundColor", objectValueType: .uiColor, patch: true)),
                BlueprintAttribute(.NSWindow.Appearance.alphaValue, AttributeInfo(className: "NSWindow", fullTitle: "AlphaValue", patch: true)),
                BlueprintAttribute(.NSWindow.Appearance.opaque, AttributeInfo(className: "NSWindow", fullTitle: "Opaque", getterString: "isOpaque", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.Appearance.hasShadow, AttributeInfo(className: "NSWindow", fullTitle: "HasShadow", patch: true)),
            ]),
            BlueprintSection(.NSWindow.titleVisibility, title: "TitleVisibility", attributes: [
                BlueprintAttribute(.NSWindow.Appearance.titleVisibility, AttributeInfo(className: "NSWindow", fullTitle: "TitleVisibility", enumList: "NSWindowTitleVisibility", patch: true)),
            ]),
            BlueprintSection(.NSWindow.toolbarStyle, title: "ToolbarStyle", attributes: [
                BlueprintAttribute(.NSWindow.Appearance.toolbarStyle, AttributeInfo(className: "NSWindow", fullTitle: "ToolbarStyle", enumList: "NSWindowToolbarStyle", patch: true, osVersion: 11)),
            ]),
            BlueprintSection(.NSWindow.titlebarSeparatorStyle, title: "TitlebarSeparatorStyle", attributes: [
                BlueprintAttribute(.NSWindow.Appearance.titlebarSeparatorStyle, AttributeInfo(className: "NSWindow", fullTitle: "TitlebarSeparatorStyle", enumList: "NSTitlebarSeparatorStyle", patch: true, osVersion: 11)),
            ]),
            BlueprintSection(.NSWindow.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.NSWindow.Behavior.movable, AttributeInfo(className: "NSWindow", fullTitle: "Movable", getterString: "isMovable", patch: false)),
                BlueprintAttribute(.NSWindow.Behavior.movableByWindowBackground, AttributeInfo(className: "NSWindow", fullTitle: "MovableByWindowBackground", getterString: "isMovableByWindowBackground", patch: false)),
                BlueprintAttribute(.NSWindow.Behavior.hidesOnDeactivate, AttributeInfo(className: "NSWindow", fullTitle: "HidesOnDeactivate", patch: true)),
            ]),
            BlueprintSection(.NSWindow.animationBehavior, title: "AnimationBehavior", attributes: [
                BlueprintAttribute(.NSWindow.Behavior.animationBehavior, AttributeInfo(className: "NSWindow", fullTitle: "AnimationBehavior", enumList: "NSWindowAnimationBehavior", patch: false)),
            ]),
            BlueprintSection(.NSWindow.level, title: "Level", attributes: [
                BlueprintAttribute(.NSWindow.Behavior.level, AttributeInfo(className: "NSWindow", fullTitle: "Level", enumList: "NSWindowLevel", patch: true)),
            ]),
            BlueprintSection(.NSWindow.tabbingMode, title: "TabbingMode", attributes: [
                BlueprintAttribute(.NSWindow.Behavior.tabbingMode, AttributeInfo(className: "NSWindow", fullTitle: "TabbingMode", enumList: "NSWindowTabbingMode", patch: true)),
            ]),
            BlueprintSection(.NSWindow.size, title: "Size", attributes: [
                BlueprintAttribute(.NSWindow.Size.minSize, AttributeInfo(className: "NSWindow", fullTitle: "MinSize", patch: true)),
                BlueprintAttribute(.NSWindow.Size.maxSize, AttributeInfo(className: "NSWindow", fullTitle: "MaxSize", patch: true)),
            ]),
            BlueprintSection(.NSWindow.information, title: "Info", attributes: [
                BlueprintAttribute(.NSWindow.Information.windowNumber, AttributeInfo(className: "NSWindow", fullTitle: "WindowNumber", setterString: "", patch: false)),
                BlueprintAttribute(.NSWindow.Information.backingScaleFactor, AttributeInfo(className: "NSWindow", fullTitle: "BackingScaleFactor", setterString: "", patch: false)),
            ]),
            BlueprintSection(.NSWindow.contentLayoutRect, title: "ContentLayoutRect", attributes: [
                BlueprintAttribute(.NSWindow.ContentLayoutRect.contentLayoutRect, AttributeInfo(className: "NSWindow", fullTitle: "ContentLayoutRect", getterString: "contentLayoutRect", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSWindow.representedURL, title: "RepresentedURL", attributes: [
                BlueprintAttribute(.NSWindow.RepresentedURL.representedURL, AttributeInfo(className: "NSWindow", fullTitle: "RepresentedURL", getterString: "representedURL", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.url))),
            ]),
            BlueprintSection(.NSWindow.representedFilename, title: "RepresentedFilename", attributes: [
                BlueprintAttribute(.NSWindow.RepresentedFilename.representedFilename, AttributeInfo(className: "NSWindow", fullTitle: "RepresentedFilename", getterString: "representedFilename", setterString: "setRepresentedFilename:", objectValueType: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSWindow.flags, title: "Flags", attributes: [
                BlueprintAttribute(.NSWindow.Flags.excludedFromWindowsMenu, AttributeInfo(className: "NSWindow", fullTitle: "ExcludedFromWindowsMenu", getterString: "isExcludedFromWindowsMenu", setterString: "setExcludedFromWindowsMenu:", patch: true, revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.inLiveResize, AttributeInfo(className: "NSWindow", fullTitle: "InLiveResize", getterString: "inLiveResize", setterString: "", revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.viewsNeedDisplay, AttributeInfo(className: "NSWindow", fullTitle: "ViewsNeedDisplay", getterString: "viewsNeedDisplay", setterString: "setViewsNeedDisplay:", patch: true, revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.preservesContentDuringLiveResize, AttributeInfo(className: "NSWindow", fullTitle: "PreservesContentDuringLiveResize", getterString: "preservesContentDuringLiveResize", setterString: "setPreservesContentDuringLiveResize:", patch: true, revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.releasedWhenClosed, AttributeInfo(className: "NSWindow", fullTitle: "ReleasedWhenClosed", getterString: "isReleasedWhenClosed", setterString: "setReleasedWhenClosed:", patch: true, revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.zoomed, AttributeInfo(className: "NSWindow", fullTitle: "Zoomed", getterString: "isZoomed", setterString: "", revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.miniaturized, AttributeInfo(className: "NSWindow", fullTitle: "Miniaturized", getterString: "isMiniaturized", setterString: "", revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.canHide, AttributeInfo(className: "NSWindow", fullTitle: "CanHide", getterString: "canHide", setterString: "setCanHide:", patch: true, revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.documentEdited, AttributeInfo(className: "NSWindow", fullTitle: "DocumentEdited", getterString: "isDocumentEdited", setterString: "setDocumentEdited:", patch: true, revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.worksWhenModal, AttributeInfo(className: "NSWindow", fullTitle: "WorksWhenModal", getterString: "worksWhenModal", setterString: "", revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.preventsApplicationTerminationWhenModal, AttributeInfo(className: "NSWindow", fullTitle: "PreventsApplicationTerminationWhenModal", getterString: "preventsApplicationTerminationWhenModal", setterString: "setPreventsApplicationTerminationWhenModal:", patch: true, revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.allowsToolTipsWhenApplicationIsInactive, AttributeInfo(className: "NSWindow", fullTitle: "AllowsToolTipsWhenApplicationIsInactive", getterString: "allowsToolTipsWhenApplicationIsInactive", setterString: "setAllowsToolTipsWhenApplicationIsInactive:", patch: true, revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.hasDynamicDepthLimit, AttributeInfo(className: "NSWindow", fullTitle: "HasDynamicDepthLimit", getterString: "hasDynamicDepthLimit", setterString: "", revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.allowsConcurrentViewDrawing, AttributeInfo(className: "NSWindow", fullTitle: "AllowsConcurrentViewDrawing", getterString: "allowsConcurrentViewDrawing", setterString: "setAllowsConcurrentViewDrawing:", patch: true, revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.displaysWhenScreenProfileChanges, AttributeInfo(className: "NSWindow", fullTitle: "DisplaysWhenScreenProfileChanges", getterString: "displaysWhenScreenProfileChanges", setterString: "setDisplaysWhenScreenProfileChanges:", patch: true, revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.canBecomeVisibleWithoutLogin, AttributeInfo(className: "NSWindow", fullTitle: "CanBecomeVisibleWithoutLogin", getterString: "canBecomeVisibleWithoutLogin", setterString: "setCanBecomeVisibleWithoutLogin:", patch: true, revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.onActiveSpace, AttributeInfo(className: "NSWindow", fullTitle: "OnActiveSpace", getterString: "isOnActiveSpace", setterString: "", revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.sheet, AttributeInfo(className: "NSWindow", fullTitle: "Sheet", getterString: "isSheet", setterString: "", revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.autorecalculatesKeyViewLoop, AttributeInfo(className: "NSWindow", fullTitle: "AutorecalculatesKeyViewLoop", getterString: "autorecalculatesKeyViewLoop", setterString: "setAutorecalculatesKeyViewLoop:", patch: true, revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.hasActiveWindowSharingSession, AttributeInfo(className: "NSWindow", fullTitle: "HasActiveWindowSharingSession", getterString: "hasActiveWindowSharingSession", setterString: "", revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.acceptsMouseMovedEvents, AttributeInfo(className: "NSWindow", fullTitle: "AcceptsMouseMovedEvents", getterString: "acceptsMouseMovedEvents", setterString: "setAcceptsMouseMovedEvents:", patch: true, revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.ignoresMouseEvents, AttributeInfo(className: "NSWindow", fullTitle: "IgnoresMouseEvents", getterString: "ignoresMouseEvents", setterString: "setIgnoresMouseEvents:", patch: true, revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.areCursorRectsEnabled, AttributeInfo(className: "NSWindow", fullTitle: "AreCursorRectsEnabled", getterString: "areCursorRectsEnabled", setterString: "", revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.restorable, AttributeInfo(className: "NSWindow", fullTitle: "Restorable", getterString: "isRestorable", setterString: "setRestorable:", patch: true, revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.hasCloseBox, AttributeInfo(className: "NSWindow", fullTitle: "HasCloseBox", getterString: "hasCloseBox", setterString: "", revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.hasTitleBar, AttributeInfo(className: "NSWindow", fullTitle: "HasTitleBar", getterString: "hasTitleBar", setterString: "", revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.floatingPanel, AttributeInfo(className: "NSWindow", fullTitle: "FloatingPanel", getterString: "isFloatingPanel", setterString: "", revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.miniaturizable, AttributeInfo(className: "NSWindow", fullTitle: "Miniaturizable", getterString: "isMiniaturizable", setterString: "", revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.modalPanel, AttributeInfo(className: "NSWindow", fullTitle: "ModalPanel", getterString: "isModalPanel", setterString: "", revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.resizable, AttributeInfo(className: "NSWindow", fullTitle: "Resizable", getterString: "isResizable", setterString: "", revision: 1)),
                BlueprintAttribute(.NSWindow.Flags.zoomable, AttributeInfo(className: "NSWindow", fullTitle: "Zoomable", getterString: "isZoomable", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSWindow.styleMask, title: "StyleMask", attributes: [
                BlueprintAttribute(.NSWindow.StyleMask.styleMask, AttributeInfo(className: "NSWindow", fullTitle: "StyleMask", getterString: "styleMask", setterString: "", revision: 1, presentation: .optionNames("NSWindowStyleMask"))),
            ]),
            BlueprintSection(.NSWindow.cascadingReferenceFrame, title: "CascadingReferenceFrame", attributes: [
                BlueprintAttribute(.NSWindow.CascadingReferenceFrame.cascadingReferenceFrame, AttributeInfo(className: "NSWindow", fullTitle: "CascadingReferenceFrame", getterString: "cascadingReferenceFrame", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSWindow.resizeIncrements, title: "ResizeIncrements", attributes: [
                BlueprintAttribute(.NSWindow.ResizeIncrements.resizeIncrements, AttributeInfo(className: "NSWindow", fullTitle: "ResizeIncrements", getterString: "resizeIncrements", setterString: "setResizeIncrements:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSWindow.aspectRatio, title: "AspectRatio", attributes: [
                BlueprintAttribute(.NSWindow.AspectRatio.aspectRatio, AttributeInfo(className: "NSWindow", fullTitle: "AspectRatio", getterString: "aspectRatio", setterString: "setAspectRatio:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSWindow.contentResizeIncrements, title: "ContentResizeIncrements", attributes: [
                BlueprintAttribute(.NSWindow.ContentResizeIncrements.contentResizeIncrements, AttributeInfo(className: "NSWindow", fullTitle: "ContentResizeIncrements", getterString: "contentResizeIncrements", setterString: "setContentResizeIncrements:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSWindow.contentAspectRatio, title: "ContentAspectRatio", attributes: [
                BlueprintAttribute(.NSWindow.ContentAspectRatio.contentAspectRatio, AttributeInfo(className: "NSWindow", fullTitle: "ContentAspectRatio", getterString: "contentAspectRatio", setterString: "setContentAspectRatio:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSWindow.miniwindowTitle, title: "MiniwindowTitle", attributes: [
                BlueprintAttribute(.NSWindow.MiniwindowTitle.miniwindowTitle, AttributeInfo(className: "NSWindow", fullTitle: "MiniwindowTitle", getterString: "miniwindowTitle", setterString: "setMiniwindowTitle:", objectValueType: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSWindow.backingType, title: "BackingType", attributes: [
                BlueprintAttribute(.NSWindow.BackingType.backingType, AttributeInfo(className: "NSWindow", fullTitle: "BackingType", getterString: "backingType", setterString: "setBackingType:", enumList: "NSBackingStoreType", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSWindow.depthLimit, title: "DepthLimit", attributes: [
                BlueprintAttribute(.NSWindow.DepthLimit.depthLimit, AttributeInfo(className: "NSWindow", fullTitle: "DepthLimit", getterString: "depthLimit", setterString: "setDepthLimit:", enumList: "NSWindowDepth", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSWindow.screen, title: "Screen", attributes: [
                BlueprintAttribute(.NSWindow.Screen.screen, AttributeInfo(className: "NSWindow", fullTitle: "Screen", getterString: "screen", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.screen))),
            ]),
            BlueprintSection(.NSWindow.deepestScreen, title: "DeepestScreen", attributes: [
                BlueprintAttribute(.NSWindow.DeepestScreen.deepestScreen, AttributeInfo(className: "NSWindow", fullTitle: "DeepestScreen", getterString: "deepestScreen", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.screen))),
            ]),
            BlueprintSection(.NSWindow.sharingType, title: "SharingType", attributes: [
                BlueprintAttribute(.NSWindow.SharingType.sharingType, AttributeInfo(className: "NSWindow", fullTitle: "SharingType", getterString: "sharingType", setterString: "setSharingType:", enumList: "NSWindowSharingType", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSWindow.collectionBehaviorOptions, title: "CollectionBehaviorOptions", attributes: [
                BlueprintAttribute(.NSWindow.CollectionBehaviorOptions.collectionBehavior, AttributeInfo(className: "NSWindow", fullTitle: "CollectionBehavior", getterString: "collectionBehavior", setterString: "", revision: 1, presentation: .optionNames("NSWindowCollectionBehavior"))),
            ]),
            BlueprintSection(.NSWindow.contentMinSize, title: "ContentMinSize", attributes: [
                BlueprintAttribute(.NSWindow.ContentMinSize.contentMinSize, AttributeInfo(className: "NSWindow", fullTitle: "ContentMinSize", getterString: "contentMinSize", setterString: "setContentMinSize:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSWindow.contentMaxSize, title: "ContentMaxSize", attributes: [
                BlueprintAttribute(.NSWindow.ContentMaxSize.contentMaxSize, AttributeInfo(className: "NSWindow", fullTitle: "ContentMaxSize", getterString: "contentMaxSize", setterString: "setContentMaxSize:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSWindow.minFullScreenContentSize, title: "MinFullScreenContentSize", attributes: [
                BlueprintAttribute(.NSWindow.MinFullScreenContentSize.minFullScreenContentSize, AttributeInfo(className: "NSWindow", fullTitle: "MinFullScreenContentSize", getterString: "minFullScreenContentSize", setterString: "setMinFullScreenContentSize:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSWindow.maxFullScreenContentSize, title: "MaxFullScreenContentSize", attributes: [
                BlueprintAttribute(.NSWindow.MaxFullScreenContentSize.maxFullScreenContentSize, AttributeInfo(className: "NSWindow", fullTitle: "MaxFullScreenContentSize", getterString: "maxFullScreenContentSize", setterString: "setMaxFullScreenContentSize:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSWindow.occlusionState, title: "OcclusionState", attributes: [
                BlueprintAttribute(.NSWindow.OcclusionState.occlusionState, AttributeInfo(className: "NSWindow", fullTitle: "OcclusionState", getterString: "occlusionState", setterString: "", revision: 1, presentation: .optionNames("NSWindowOcclusionState"))),
            ]),
            BlueprintSection(.NSWindow.keyViewSelectionDirection, title: "KeyViewSelectionDirection", attributes: [
                BlueprintAttribute(.NSWindow.KeyViewSelectionDirection.keyViewSelectionDirection, AttributeInfo(className: "NSWindow", fullTitle: "KeyViewSelectionDirection", getterString: "keyViewSelectionDirection", setterString: "", enumList: "NSSelectionDirection", revision: 1)),
            ]),
            BlueprintSection(.NSWindow.toolbar, title: "Toolbar", attributes: [
                BlueprintAttribute(.NSWindow.Toolbar.toolbar, AttributeInfo(className: "NSWindow", fullTitle: "Toolbar", getterString: "toolbar", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.toolbar))),
            ]),
            BlueprintSection(.NSWindow.orderedIndex, title: "OrderedIndex", attributes: [
                BlueprintAttribute(.NSWindow.OrderedIndex.orderedIndex, AttributeInfo(className: "NSWindow", fullTitle: "OrderedIndex", getterString: "orderedIndex", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSWindow.firstResponder, title: "FirstResponder", attributes: [
                BlueprintAttribute(.NSWindow.FirstResponder.firstResponder, AttributeInfo(className: "NSWindow", fullTitle: "FirstResponder", getterString: "firstResponder", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.className))),
            ]),
        ])

        static let nsSliderGroup = BlueprintGroup(.nsSlider, title: "NSSlider", on: .appKit, sections: [
            BlueprintSection(.NSSlider.sliderType, title: "SliderType", attributes: [
                BlueprintAttribute(.NSSlider.SliderType.sliderType, AttributeInfo(className: "NSSlider", fullTitle: "SliderType", enumList: "NSSliderType", patch: true)),
            ]),
            BlueprintSection(.NSSlider.range, title: "Range", attributes: [
                BlueprintAttribute(.NSSlider.Range.minValue, AttributeInfo(className: "NSSlider", fullTitle: "MinValue", patch: true)),
                BlueprintAttribute(.NSSlider.Range.maxValue, AttributeInfo(className: "NSSlider", fullTitle: "MaxValue", patch: true)),
            ]),
            BlueprintSection(.NSSlider.tickMark, title: "TickMark", attributes: [
                BlueprintAttribute(.NSSlider.TickMark.numberOfTickMarks, AttributeInfo(className: "NSSlider", fullTitle: "NumberOfTickMarks", patch: true)),
                BlueprintAttribute(.NSSlider.TickMark.tickMarkPosition, AttributeInfo(className: "NSSlider", fullTitle: "TickMarkPosition", enumList: "NSTickMarkPosition", patch: true)),
                BlueprintAttribute(.NSSlider.TickMark.allowsTickMarkValuesOnly, AttributeInfo(className: "NSSlider", fullTitle: "AllowsTickMarkValuesOnly", patch: true)),
            ]),
            BlueprintSection(.NSSlider.miscellaneous, title: "Misc", attributes: [
                BlueprintAttribute(.NSSlider.Miscellaneous.vertical, AttributeInfo(className: "NSSlider", fullTitle: "Vertical", getterString: "isVertical", setterString: "", patch: false)),
                BlueprintAttribute(.NSSlider.Miscellaneous.knobThickness, AttributeInfo(className: "NSSlider", fullTitle: "KnobThickness", setterString: "", patch: false)),
                BlueprintAttribute(.NSSlider.Miscellaneous.altIncrementValue, AttributeInfo(className: "NSSlider", fullTitle: "AltIncrementValue", patch: true)),
                BlueprintAttribute(.NSSlider.Miscellaneous.trackFillColor, AttributeInfo(className: "NSSlider", fullTitle: "TrackFillColor", objectValueType: .uiColor, patch: true, hideIfNil: true)),
            ]),
            BlueprintSection(.NSSlider.neutralValue, title: "NeutralValue", attributes: [
                BlueprintAttribute(.NSSlider.NeutralValue.neutralValue, AttributeInfo(className: "NSSlider", fullTitle: "NeutralValue", getterString: "neutralValue", setterString: "setNeutralValue:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSSlider.tintProminence, title: "TintProminence", attributes: [
                BlueprintAttribute(.NSSlider.TintProminence.tintProminence, AttributeInfo(className: "NSSlider", fullTitle: "TintProminence", getterString: "tintProminence", setterString: "setTintProminence:", enumList: "NSTintProminence", patch: true, revision: 1)),
            ]),
        ])

        static let nsProgressIndicatorGroup = BlueprintGroup(.nsProgressIndicator, title: "NSProgressIndicator", on: .appKit, sections: [
            BlueprintSection(.NSProgressIndicator.style, title: "Style", attributes: [
                BlueprintAttribute(.NSProgressIndicator.Style.style, AttributeInfo(className: "NSProgressIndicator", fullTitle: "Style", enumList: "NSProgressIndicatorStyle", patch: true)),
            ]),
            BlueprintSection(.NSProgressIndicator.range, title: "Range", attributes: [
                BlueprintAttribute(.NSProgressIndicator.Range.minValue, AttributeInfo(className: "NSProgressIndicator", fullTitle: "MinValue", patch: true)),
                BlueprintAttribute(.NSProgressIndicator.Range.maxValue, AttributeInfo(className: "NSProgressIndicator", fullTitle: "MaxValue", patch: true)),
                BlueprintAttribute(.NSProgressIndicator.Range.doubleValue, AttributeInfo(className: "NSProgressIndicator", fullTitle: "DoubleValue", patch: true)),
            ]),
            BlueprintSection(.NSProgressIndicator.miscellaneous, title: "Misc", attributes: [
                BlueprintAttribute(.NSProgressIndicator.Miscellaneous.indeterminate, AttributeInfo(className: "NSProgressIndicator", fullTitle: "Indeterminate", getterString: "isIndeterminate", patch: true)),
                BlueprintAttribute(.NSProgressIndicator.Miscellaneous.bezeled, AttributeInfo(className: "NSProgressIndicator", fullTitle: "Bezeled", getterString: "isBezeled", patch: true)),
                BlueprintAttribute(.NSProgressIndicator.Miscellaneous.displayedWhenStopped, AttributeInfo(className: "NSProgressIndicator", fullTitle: "DisplayedWhenStopped", getterString: "isDisplayedWhenStopped", patch: true)),
            ]),
            BlueprintSection(.NSProgressIndicator.controlSize, title: "ControlSize", attributes: [
                BlueprintAttribute(.NSProgressIndicator.ControlSize.controlSize, AttributeInfo(className: "NSProgressIndicator", fullTitle: "ControlSize", getterString: "controlSize", setterString: "setControlSize:", enumList: "NSControlSize", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSProgressIndicator.usesThreadedAnimation, title: "UsesThreadedAnimation", attributes: [
                BlueprintAttribute(.NSProgressIndicator.UsesThreadedAnimation.usesThreadedAnimation, AttributeInfo(className: "NSProgressIndicator", fullTitle: "UsesThreadedAnimation", getterString: "usesThreadedAnimation", setterString: "setUsesThreadedAnimation:", patch: true, revision: 1)),
            ]),
        ])

        static let nsSegmentedControlGroup = BlueprintGroup(.nsSegmentedControl, title: "NSSegmentedControl", on: .appKit, sections: [
            BlueprintSection(.NSSegmentedControl.segmentCount, title: "SegmentCount", attributes: [
                BlueprintAttribute(.NSSegmentedControl.SegmentCount.segmentCount, AttributeInfo(className: "NSSegmentedControl", fullTitle: "SegmentCount", patch: true)),
            ]),
            BlueprintSection(.NSSegmentedControl.selection, title: "Selection", attributes: [
                BlueprintAttribute(.NSSegmentedControl.Selection.selectedSegment, AttributeInfo(className: "NSSegmentedControl", fullTitle: "SelectedSegment", patch: true)),
            ]),
            BlueprintSection(.NSSegmentedControl.style, title: "Style", attributes: [
                BlueprintAttribute(.NSSegmentedControl.Style.segmentStyle, AttributeInfo(className: "NSSegmentedControl", fullTitle: "SegmentStyle", enumList: "NSSegmentStyle", patch: true)),
                BlueprintAttribute(.NSSegmentedControl.Style.trackingMode, AttributeInfo(className: "NSSegmentedControl", fullTitle: "TrackingMode", enumList: "NSSegmentSwitchTracking", patch: true)),
            ]),
            BlueprintSection(.NSSegmentedControl.colors, title: "Colors", attributes: [
                BlueprintAttribute(.NSSegmentedControl.Colors.selectedSegmentBezelColor, AttributeInfo(className: "NSSegmentedControl", fullTitle: "SelectedSegmentBezelColor", objectValueType: .uiColor, patch: true, hideIfNil: true)),
            ]),
            BlueprintSection(.NSSegmentedControl.role, title: "Role", attributes: [
                BlueprintAttribute(.NSSegmentedControl.Role.role, AttributeInfo(className: "NSSegmentedControl", fullTitle: "Role", getterString: "role", setterString: "setRole:", enumList: "NSSegmentedControlRole", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSSegmentedControl.springLoaded, title: "SpringLoaded", attributes: [
                BlueprintAttribute(.NSSegmentedControl.SpringLoaded.springLoaded, AttributeInfo(className: "NSSegmentedControl", fullTitle: "SpringLoaded", getterString: "isSpringLoaded", setterString: "setSpringLoaded:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSSegmentedControl.doubleValueForSelectedSegment, title: "DoubleValueForSelectedSegment", attributes: [
                BlueprintAttribute(.NSSegmentedControl.DoubleValueForSelectedSegment.doubleValueForSelectedSegment, AttributeInfo(className: "NSSegmentedControl", fullTitle: "DoubleValueForSelectedSegment", getterString: "doubleValueForSelectedSegment", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSSegmentedControl.indexOfSelectedItem, title: "IndexOfSelectedItem", attributes: [
                BlueprintAttribute(.NSSegmentedControl.IndexOfSelectedItem.indexOfSelectedItem, AttributeInfo(className: "NSSegmentedControl", fullTitle: "IndexOfSelectedItem", getterString: "indexOfSelectedItem", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSSegmentedControl.segmentDistribution, title: "SegmentDistribution", attributes: [
                BlueprintAttribute(.NSSegmentedControl.SegmentDistribution.segmentDistribution, AttributeInfo(className: "NSSegmentedControl", fullTitle: "SegmentDistribution", getterString: "segmentDistribution", setterString: "setSegmentDistribution:", enumList: "NSSegmentDistribution", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSSegmentedControl.borderShape, title: "BorderShape", attributes: [
                BlueprintAttribute(.NSSegmentedControl.BorderShape.borderShape, AttributeInfo(className: "NSSegmentedControl", fullTitle: "BorderShape", getterString: "borderShape", setterString: "setBorderShape:", enumList: "NSControlBorderShape", patch: true, revision: 1)),
            ]),
        ])

        static let nsPopUpButtonGroup = BlueprintGroup(.nsPopUpButton, title: "NSPopUpButton", on: .appKit, sections: [
            BlueprintSection(.NSPopUpButton.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.NSPopUpButton.Behavior.pullsDown, AttributeInfo(className: "NSPopUpButton", fullTitle: "PullsDown", patch: true)),
                BlueprintAttribute(.NSPopUpButton.Behavior.autoenablesItems, AttributeInfo(className: "NSPopUpButton", fullTitle: "AutoenablesItems", patch: true)),
                BlueprintAttribute(.NSPopUpButton.Behavior.preferredEdge, AttributeInfo(className: "NSPopUpButton", fullTitle: "PreferredEdge", enumList: "NSRectEdge", patch: true)),
            ]),
            BlueprintSection(.NSPopUpButton.selection, title: "Selection", attributes: [
                BlueprintAttribute(.NSPopUpButton.Selection.selectedTag, AttributeInfo(className: "NSPopUpButton", fullTitle: "SelectedTag", setterString: "", patch: false)),
                BlueprintAttribute(.NSPopUpButton.Selection.indexOfSelectedItem, AttributeInfo(className: "NSPopUpButton", fullTitle: "IndexOfSelectedItem", setterString: "", patch: false)),
                BlueprintAttribute(.NSPopUpButton.Selection.titleOfSelectedItem, AttributeInfo(className: "NSPopUpButton", fullTitle: "TitleOfSelectedItem", setterString: "", objectValueType: .nsString, patch: false, hideIfNil: true)),
            ]),
            BlueprintSection(.NSPopUpButton.items, title: "Items", attributes: [
                BlueprintAttribute(.NSPopUpButton.Items.numberOfItems, AttributeInfo(className: "NSPopUpButton", fullTitle: "NumberOfItems", setterString: "", patch: false)),
            ]),
            BlueprintSection(.NSPopUpButton.menu, title: "Menu", attributes: [
                BlueprintAttribute(.NSPopUpButton.Menu.menu, AttributeInfo(className: "NSPopUpButton", fullTitle: "Menu", getterString: "menu", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.menu))),
            ]),
            BlueprintSection(.NSPopUpButton.flags, title: "Flags", attributes: [
                BlueprintAttribute(.NSPopUpButton.Flags.usesItemFromMenu, AttributeInfo(className: "NSPopUpButton", fullTitle: "UsesItemFromMenu", getterString: "usesItemFromMenu", setterString: "setUsesItemFromMenu:", patch: true, revision: 1)),
                BlueprintAttribute(.NSPopUpButton.Flags.altersStateOfSelectedItem, AttributeInfo(className: "NSPopUpButton", fullTitle: "AltersStateOfSelectedItem", getterString: "altersStateOfSelectedItem", setterString: "setAltersStateOfSelectedItem:", patch: true, revision: 1)),
            ]),
        ])

        static let nsComboBoxGroup = BlueprintGroup(.nsComboBox, title: "NSComboBox", on: .appKit, sections: [
            BlueprintSection(.NSComboBox.items, title: "Items", attributes: [
                BlueprintAttribute(.NSComboBox.Items.numberOfItems, AttributeInfo(className: "NSComboBox", fullTitle: "NumberOfItems", setterString: "", patch: false)),
                BlueprintAttribute(.NSComboBox.Items.hasVerticalScroller, AttributeInfo(className: "NSComboBox", fullTitle: "HasVerticalScroller", patch: true)),
                BlueprintAttribute(.NSComboBox.Items.numberOfVisibleItems, AttributeInfo(className: "NSComboBox", fullTitle: "NumberOfVisibleItems", patch: true)),
                BlueprintAttribute(.NSComboBox.Items.intercellSpacing, AttributeInfo(className: "NSComboBox", fullTitle: "IntercellSpacing", patch: true)),
                BlueprintAttribute(.NSComboBox.Items.itemHeight, AttributeInfo(className: "NSComboBox", fullTitle: "ItemHeight", patch: true)),
            ]),
            BlueprintSection(.NSComboBox.miscellaneous, title: "Misc", attributes: [
                BlueprintAttribute(.NSComboBox.Miscellaneous.buttonBordered, AttributeInfo(className: "NSComboBox", fullTitle: "ButtonBordered", getterString: "isButtonBordered", patch: true)),
                BlueprintAttribute(.NSComboBox.Miscellaneous.completes, AttributeInfo(className: "NSComboBox", fullTitle: "Completes", patch: true)),
                BlueprintAttribute(.NSComboBox.Miscellaneous.usesDataSource, AttributeInfo(className: "NSComboBox", fullTitle: "UsesDataSource", patch: false)),
            ]),
            BlueprintSection(.NSComboBox.indexOfSelectedItem, title: "IndexOfSelectedItem", attributes: [
                BlueprintAttribute(.NSComboBox.IndexOfSelectedItem.indexOfSelectedItem, AttributeInfo(className: "NSComboBox", fullTitle: "IndexOfSelectedItem", getterString: "indexOfSelectedItem", setterString: "", revision: 1)),
            ]),
        ])

        static let nsStepperGroup = BlueprintGroup(.nsStepper, title: "NSStepper", on: .appKit, sections: [
            BlueprintSection(.NSStepper.range, title: "Range", attributes: [
                BlueprintAttribute(.NSStepper.Range.minValue, AttributeInfo(className: "NSStepper", fullTitle: "MinValue", patch: true)),
                BlueprintAttribute(.NSStepper.Range.maxValue, AttributeInfo(className: "NSStepper", fullTitle: "MaxValue", patch: true)),
                BlueprintAttribute(.NSStepper.Range.increment, AttributeInfo(className: "NSStepper", fullTitle: "Increment", patch: true)),
            ]),
            BlueprintSection(.NSStepper.miscellaneous, title: "Misc", attributes: [
                BlueprintAttribute(.NSStepper.Miscellaneous.valueWraps, AttributeInfo(className: "NSStepper", fullTitle: "ValueWraps", patch: true)),
                BlueprintAttribute(.NSStepper.Miscellaneous.autorepeat, AttributeInfo(className: "NSStepper", fullTitle: "Autorepeat", patch: true)),
            ]),
        ])

        static let nsColorWellGroup = BlueprintGroup(.nsColorWell, title: "NSColorWell", on: .appKit, sections: [
            BlueprintSection(.NSColorWell.color, title: "Color", attributes: [
                BlueprintAttribute(.NSColorWell.Color.color, AttributeInfo(className: "NSColorWell", fullTitle: "Color", objectValueType: .uiColor, patch: true)),
            ]),
            BlueprintSection(.NSColorWell.miscellaneous, title: "Misc", attributes: [
                BlueprintAttribute(.NSColorWell.Miscellaneous.bordered, AttributeInfo(className: "NSColorWell", fullTitle: "Bordered", getterString: "isBordered", patch: true)),
                BlueprintAttribute(.NSColorWell.Miscellaneous.active, AttributeInfo(className: "NSColorWell", fullTitle: "Active", getterString: "isActive", setterString: "", patch: false)),
                BlueprintAttribute(.NSColorWell.Miscellaneous.colorWellStyle, AttributeInfo(className: "NSColorWell", fullTitle: "ColorWellStyle", enumList: "NSColorWellStyle", patch: true, osVersion: 13)),
            ]),
            BlueprintSection(.NSColorWell.image, title: "Image", attributes: [
                BlueprintAttribute(.NSColorWell.Image.image, AttributeInfo(className: "NSColorWell", fullTitle: "Image", getterString: "image", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(.NSColorWell.supportsAlpha, title: "SupportsAlpha", attributes: [
                BlueprintAttribute(.NSColorWell.SupportsAlpha.supportsAlpha, AttributeInfo(className: "NSColorWell", fullTitle: "SupportsAlpha", getterString: "supportsAlpha", setterString: "setSupportsAlpha:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSColorWell.maximumLinearExposure, title: "MaximumLinearExposure", attributes: [
                BlueprintAttribute(.NSColorWell.MaximumLinearExposure.maximumLinearExposure, AttributeInfo(className: "NSColorWell", fullTitle: "MaximumLinearExposure", getterString: "maximumLinearExposure", setterString: "setMaximumLinearExposure:", patch: true, revision: 1)),
            ]),
        ])

        static let nsSwitchGroup = BlueprintGroup(.nsSwitch, title: "NSSwitch", on: .appKit, sections: [
            BlueprintSection(.NSSwitch.state, title: "State", attributes: [
                BlueprintAttribute(.NSSwitch.State.state, AttributeInfo(className: "NSSwitch", fullTitle: "State", enumList: "NSControlStateValue", patch: true, osVersion: 15)),
            ]),
        ])

        static let nsDatePickerGroup = BlueprintGroup(.nsDatePicker, title: "NSDatePicker", on: .appKit, sections: [
            BlueprintSection(.NSDatePicker.style, title: "Style", attributes: [
                BlueprintAttribute(.NSDatePicker.Style.datePickerStyle, AttributeInfo(className: "NSDatePicker", fullTitle: "DatePickerStyle", enumList: "NSDatePickerStyle", patch: true)),
                BlueprintAttribute(.NSDatePicker.Style.datePickerMode, AttributeInfo(className: "NSDatePicker", fullTitle: "DatePickerMode", enumList: "NSDatePickerMode", patch: true)),
            ]),
            BlueprintSection(.NSDatePicker.range, title: "Range", attributes: [
                BlueprintAttribute(.NSDatePicker.Range.dateValue, AttributeInfo(className: "NSDatePicker", fullTitle: "DateValue", setterString: "", objectValueType: .customObject, patch: false)),
                BlueprintAttribute(.NSDatePicker.Range.minDate, AttributeInfo(className: "NSDatePicker", fullTitle: "MinDate", setterString: "", objectValueType: .customObject, patch: false, hideIfNil: true)),
                BlueprintAttribute(.NSDatePicker.Range.maxDate, AttributeInfo(className: "NSDatePicker", fullTitle: "MaxDate", setterString: "", objectValueType: .customObject, patch: false, hideIfNil: true)),
            ]),
            BlueprintSection(.NSDatePicker.miscellaneous, title: "Misc", attributes: [
                BlueprintAttribute(.NSDatePicker.Miscellaneous.bordered, AttributeInfo(className: "NSDatePicker", fullTitle: "Bordered", getterString: "isBordered", patch: true)),
                BlueprintAttribute(.NSDatePicker.Miscellaneous.bezeled, AttributeInfo(className: "NSDatePicker", fullTitle: "Bezeled", getterString: "isBezeled", patch: true)),
                BlueprintAttribute(.NSDatePicker.Miscellaneous.drawsBackground, AttributeInfo(className: "NSDatePicker", fullTitle: "DrawsBackground", patch: true)),
            ]),
            BlueprintSection(.NSDatePicker.colors, title: "Colors", attributes: [
                BlueprintAttribute(.NSDatePicker.Colors.backgroundColor, AttributeInfo(className: "NSDatePicker", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.NSDatePicker.Colors.textColor, AttributeInfo(className: "NSDatePicker", fullTitle: "TextColor", getterString: "textColor", setterString: "setTextColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSDatePicker.datePickerElements, title: "DatePickerElements", attributes: [
                BlueprintAttribute(.NSDatePicker.DatePickerElements.datePickerElements, AttributeInfo(className: "NSDatePicker", fullTitle: "DatePickerElements", getterString: "datePickerElements", setterString: "", revision: 1, presentation: .optionNames("NSDatePickerElementFlags"))),
            ]),
            BlueprintSection(.NSDatePicker.calendar, title: "Calendar", attributes: [
                BlueprintAttribute(.NSDatePicker.Calendar.calendar, AttributeInfo(className: "NSDatePicker", fullTitle: "Calendar", getterString: "calendar", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.calendar))),
            ]),
            BlueprintSection(.NSDatePicker.locale, title: "Locale", attributes: [
                BlueprintAttribute(.NSDatePicker.Locale.locale, AttributeInfo(className: "NSDatePicker", fullTitle: "Locale", getterString: "locale", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.locale))),
            ]),
            BlueprintSection(.NSDatePicker.timeZone, title: "TimeZone", attributes: [
                BlueprintAttribute(.NSDatePicker.TimeZone.timeZone, AttributeInfo(className: "NSDatePicker", fullTitle: "TimeZone", getterString: "timeZone", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.timeZone))),
            ]),
            BlueprintSection(.NSDatePicker.timeInterval, title: "TimeInterval", attributes: [
                BlueprintAttribute(.NSDatePicker.TimeInterval.timeInterval, AttributeInfo(className: "NSDatePicker", fullTitle: "TimeInterval", getterString: "timeInterval", setterString: "setTimeInterval:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSDatePicker.presentsCalendarOverlay, title: "PresentsCalendarOverlay", attributes: [
                BlueprintAttribute(.NSDatePicker.PresentsCalendarOverlay.presentsCalendarOverlay, AttributeInfo(className: "NSDatePicker", fullTitle: "PresentsCalendarOverlay", getterString: "presentsCalendarOverlay", setterString: "setPresentsCalendarOverlay:", patch: true, revision: 1)),
            ]),
        ])

        static let nsLevelIndicatorGroup = BlueprintGroup(.nsLevelIndicator, title: "NSLevelIndicator", on: .appKit, sections: [
            BlueprintSection(.NSLevelIndicator.style, title: "Style", attributes: [
                BlueprintAttribute(.NSLevelIndicator.Style.style, AttributeInfo(className: "NSLevelIndicator", fullTitle: "LevelIndicatorStyle", enumList: "NSLevelIndicatorStyle", patch: true)),
            ]),
            BlueprintSection(.NSLevelIndicator.range, title: "Range", attributes: [
                BlueprintAttribute(.NSLevelIndicator.Range.minValue, AttributeInfo(className: "NSLevelIndicator", fullTitle: "MinValue", patch: true)),
                BlueprintAttribute(.NSLevelIndicator.Range.maxValue, AttributeInfo(className: "NSLevelIndicator", fullTitle: "MaxValue", patch: true)),
                BlueprintAttribute(.NSLevelIndicator.Range.warningValue, AttributeInfo(className: "NSLevelIndicator", fullTitle: "WarningValue", patch: true)),
                BlueprintAttribute(.NSLevelIndicator.Range.criticalValue, AttributeInfo(className: "NSLevelIndicator", fullTitle: "CriticalValue", patch: true)),
            ]),
            BlueprintSection(.NSLevelIndicator.tickMark, title: "TickMark", attributes: [
                BlueprintAttribute(.NSLevelIndicator.TickMark.numberOfTickMarks, AttributeInfo(className: "NSLevelIndicator", fullTitle: "NumberOfTickMarks", patch: true)),
                BlueprintAttribute(.NSLevelIndicator.TickMark.numberOfMajorTickMarks, AttributeInfo(className: "NSLevelIndicator", fullTitle: "NumberOfMajorTickMarks", patch: true)),
            ]),
            BlueprintSection(.NSLevelIndicator.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.NSLevelIndicator.Behavior.editable, AttributeInfo(className: "NSLevelIndicator", fullTitle: "Editable", getterString: "isEditable", setterString: "setEditable:", patch: true, revision: 1)),
                BlueprintAttribute(.NSLevelIndicator.Behavior.drawsTieredCapacityLevels, AttributeInfo(className: "NSLevelIndicator", fullTitle: "DrawsTieredCapacityLevels", getterString: "drawsTieredCapacityLevels", setterString: "setDrawsTieredCapacityLevels:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSLevelIndicator.tickMarkPosition, title: "TickMarkPosition", attributes: [
                BlueprintAttribute(.NSLevelIndicator.TickMarkPosition.tickMarkPosition, AttributeInfo(className: "NSLevelIndicator", fullTitle: "TickMarkPosition", getterString: "tickMarkPosition", setterString: "setTickMarkPosition:", enumList: "NSTickMarkPosition", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSLevelIndicator.colors, title: "Colors", attributes: [
                BlueprintAttribute(.NSLevelIndicator.Colors.fillColor, AttributeInfo(className: "NSLevelIndicator", fullTitle: "FillColor", getterString: "fillColor", setterString: "setFillColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.NSLevelIndicator.Colors.warningFillColor, AttributeInfo(className: "NSLevelIndicator", fullTitle: "WarningFillColor", getterString: "warningFillColor", setterString: "setWarningFillColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.NSLevelIndicator.Colors.criticalFillColor, AttributeInfo(className: "NSLevelIndicator", fullTitle: "CriticalFillColor", getterString: "criticalFillColor", setterString: "setCriticalFillColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSLevelIndicator.placeholderVisibility, title: "PlaceholderVisibility", attributes: [
                BlueprintAttribute(.NSLevelIndicator.PlaceholderVisibility.placeholderVisibility, AttributeInfo(className: "NSLevelIndicator", fullTitle: "PlaceholderVisibility", getterString: "placeholderVisibility", setterString: "setPlaceholderVisibility:", enumList: "NSLevelIndicatorPlaceholderVisibility", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSLevelIndicator.images, title: "Images", attributes: [
                BlueprintAttribute(.NSLevelIndicator.Images.ratingImage, AttributeInfo(className: "NSLevelIndicator", fullTitle: "RatingImage", getterString: "ratingImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.NSLevelIndicator.Images.ratingPlaceholderImage, AttributeInfo(className: "NSLevelIndicator", fullTitle: "RatingPlaceholderImage", getterString: "ratingPlaceholderImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
        ])

        static let nsOutlineViewGroup = BlueprintGroup(.nsOutlineView, title: "NSOutlineView", on: .appKit, sections: [
            BlueprintSection(.NSOutlineView.indentation, title: "Indentation", attributes: [
                BlueprintAttribute(.NSOutlineView.Indentation.indentationPerLevel, AttributeInfo(className: "NSOutlineView", fullTitle: "IndentationPerLevel", patch: true)),
            ]),
            BlueprintSection(.NSOutlineView.miscellaneous, title: "Misc", attributes: [
                BlueprintAttribute(.NSOutlineView.Miscellaneous.autoresizesOutlineColumn, AttributeInfo(className: "NSOutlineView", fullTitle: "AutoresizesOutlineColumn", patch: true)),
                BlueprintAttribute(.NSOutlineView.Miscellaneous.indentationMarkerFollowsCell, AttributeInfo(className: "NSOutlineView", fullTitle: "IndentationMarkerFollowsCell", patch: true)),
                BlueprintAttribute(.NSOutlineView.Miscellaneous.autosaveExpandedItems, AttributeInfo(className: "NSOutlineView", fullTitle: "AutosaveExpandedItems", patch: true)),
            ]),
            BlueprintSection(.NSOutlineView.userInterfaceLayoutDirection, title: "UserInterfaceLayoutDirection", attributes: [
                BlueprintAttribute(.NSOutlineView.UserInterfaceLayoutDirection.userInterfaceLayoutDirection, AttributeInfo(className: "NSOutlineView", fullTitle: "UserInterfaceLayoutDirection", getterString: "userInterfaceLayoutDirection", setterString: "setUserInterfaceLayoutDirection:", enumList: "NSUserInterfaceLayoutDirection", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSOutlineView.stronglyReferencesItems, title: "StronglyReferencesItems", attributes: [
                BlueprintAttribute(.NSOutlineView.StronglyReferencesItems.stronglyReferencesItems, AttributeInfo(className: "NSOutlineView", fullTitle: "StronglyReferencesItems", getterString: "stronglyReferencesItems", setterString: "setStronglyReferencesItems:", patch: true, revision: 1)),
            ]),
        ])

        static let nsCollectionViewGroup = BlueprintGroup(.nsCollectionView, title: "NSCollectionView", on: .appKit, sections: [
            BlueprintSection(.NSCollectionView.selection, title: "Selection", attributes: [
                BlueprintAttribute(.NSCollectionView.Selection.selectable, AttributeInfo(className: "NSCollectionView", fullTitle: "Selectable", getterString: "isSelectable", patch: true)),
                BlueprintAttribute(.NSCollectionView.Selection.allowsMultipleSelection, AttributeInfo(className: "NSCollectionView", fullTitle: "AllowsMultipleSelection", patch: true)),
                BlueprintAttribute(.NSCollectionView.Selection.allowsEmptySelection, AttributeInfo(className: "NSCollectionView", fullTitle: "AllowsEmptySelection", patch: true)),
            ]),
            BlueprintSection(.NSCollectionView.information, title: "Info", attributes: [
                BlueprintAttribute(.NSCollectionView.Information.numberOfSections, AttributeInfo(className: "NSCollectionView", fullTitle: "NumberOfSections", setterString: "", patch: false)),
            ]),
            BlueprintSection(.NSCollectionView.colors, title: "Colors", attributes: [
                BlueprintAttribute(.NSCollectionView.Colors.backgroundColors, AttributeInfo(className: "NSCollectionView", fullTitle: "BackgroundColors", setterString: "", objectValueType: .customObject, patch: false)),
            ]),
            BlueprintSection(.NSCollectionView.backgroundViewScrollsWithContent, title: "BackgroundViewScrollsWithContent", attributes: [
                BlueprintAttribute(.NSCollectionView.BackgroundViewScrollsWithContent.backgroundViewScrollsWithContent, AttributeInfo(className: "NSCollectionView", fullTitle: "BackgroundViewScrollsWithContent", getterString: "backgroundViewScrollsWithContent", setterString: "setBackgroundViewScrollsWithContent:", patch: true, revision: 1)),
            ]),
        ])

        static let nsBoxGroup = BlueprintGroup(.nsBox, title: "NSBox", on: .appKit, sections: [
            BlueprintSection(.NSBox.kind, title: "Type", attributes: [
                BlueprintAttribute(.NSBox.Kind.boxType, AttributeInfo(className: "NSBox", fullTitle: "BoxType", enumList: "NSBoxType", patch: true)),
                BlueprintAttribute(.NSBox.Kind.borderType, AttributeInfo(className: "NSBox", fullTitle: "BorderType", enumList: "NSBorderType", patch: true)),
            ]),
            BlueprintSection(.NSBox.title, title: "Title", attributes: [
                BlueprintAttribute(.NSBox.Title.title, AttributeInfo(className: "NSBox", fullTitle: "Title", objectValueType: .nsString, patch: true)),
                BlueprintAttribute(.NSBox.Title.titlePosition, AttributeInfo(className: "NSBox", fullTitle: "TitlePosition", enumList: "NSTitlePosition", patch: true)),
            ]),
            BlueprintSection(.NSBox.appearance, title: "Appearance", attributes: [
                BlueprintAttribute(.NSBox.Appearance.transparent, AttributeInfo(className: "NSBox", fullTitle: "Transparent", getterString: "isTransparent", patch: true)),
                BlueprintAttribute(.NSBox.Appearance.fillColor, AttributeInfo(className: "NSBox", fullTitle: "FillColor", objectValueType: .uiColor, patch: true)),
                BlueprintAttribute(.NSBox.Appearance.borderColor, AttributeInfo(className: "NSBox", fullTitle: "BorderColor", objectValueType: .uiColor, patch: true)),
            ]),
            BlueprintSection(.NSBox.metrics, title: "Metrics", attributes: [
                BlueprintAttribute(.NSBox.Metrics.borderWidth, AttributeInfo(className: "NSBox", fullTitle: "BorderWidth", patch: true)),
                BlueprintAttribute(.NSBox.Metrics.cornerRadius, AttributeInfo(className: "NSBox", fullTitle: "CornerRadius", patch: true)),
                BlueprintAttribute(.NSBox.Metrics.contentViewMargins, AttributeInfo(className: "NSBox", fullTitle: "ContentViewMargins", patch: true)),
            ]),
            BlueprintSection(.NSBox.titleFont, title: "TitleFont", attributes: [
                BlueprintAttribute(.NSBox.TitleFont.titleFont, AttributeInfo(className: "NSBox", fullTitle: "TitleFont", getterString: "titleFont", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.font))),
            ]),
            BlueprintSection(.NSBox.borderRect, title: "BorderRect", attributes: [
                BlueprintAttribute(.NSBox.BorderRect.borderRect, AttributeInfo(className: "NSBox", fullTitle: "BorderRect", getterString: "borderRect", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSBox.titleRect, title: "TitleRect", attributes: [
                BlueprintAttribute(.NSBox.TitleRect.titleRect, AttributeInfo(className: "NSBox", fullTitle: "TitleRect", getterString: "titleRect", setterString: "", revision: 1)),
            ]),
        ])

        static let nsSplitViewGroup = BlueprintGroup(.nsSplitView, title: "NSSplitView", on: .appKit, sections: [
            BlueprintSection(.NSSplitView.orientation, title: "Orientation", attributes: [
                BlueprintAttribute(.NSSplitView.Orientation.vertical, AttributeInfo(className: "NSSplitView", fullTitle: "Vertical", getterString: "isVertical", patch: true)),
            ]),
            BlueprintSection(.NSSplitView.style, title: "Style", attributes: [
                BlueprintAttribute(.NSSplitView.Style.dividerStyle, AttributeInfo(className: "NSSplitView", fullTitle: "DividerStyle", enumList: "NSSplitViewDividerStyle", patch: true)),
                BlueprintAttribute(.NSSplitView.Style.dividerThickness, AttributeInfo(className: "NSSplitView", fullTitle: "DividerThickness", setterString: "", patch: false)),
            ]),
            BlueprintSection(.NSSplitView.miscellaneous, title: "Misc", attributes: [
                BlueprintAttribute(.NSSplitView.Miscellaneous.arrangesAllSubviews, AttributeInfo(className: "NSSplitView", fullTitle: "ArrangesAllSubviews", patch: true)),
            ]),
            BlueprintSection(.NSSplitView.dividerColor, title: "DividerColor", attributes: [
                BlueprintAttribute(.NSSplitView.DividerColor.dividerColor, AttributeInfo(className: "NSSplitView", fullTitle: "DividerColor", getterString: "dividerColor", setterString: "", objectValueType: .uiColor, hideIfNil: true, revision: 1)),
            ]),
        ])

        static let nsTabViewGroup = BlueprintGroup(.nsTabView, title: "NSTabView", on: .appKit, sections: [
            BlueprintSection(.NSTabView.kind, title: "Type", attributes: [
                BlueprintAttribute(.NSTabView.Kind.tabViewType, AttributeInfo(className: "NSTabView", fullTitle: "TabViewType", enumList: "NSTabViewType", patch: true)),
                BlueprintAttribute(.NSTabView.Kind.tabPosition, AttributeInfo(className: "NSTabView", fullTitle: "TabPosition", enumList: "NSTabPosition", patch: true, osVersion: 14)),
                BlueprintAttribute(.NSTabView.Kind.tabViewBorderType, AttributeInfo(className: "NSTabView", fullTitle: "TabViewBorderType", enumList: "NSTabViewBorderType", patch: true, osVersion: 14)),
            ]),
            BlueprintSection(.NSTabView.miscellaneous, title: "Misc", attributes: [
                BlueprintAttribute(.NSTabView.Miscellaneous.allowsTruncatedLabels, AttributeInfo(className: "NSTabView", fullTitle: "AllowsTruncatedLabels", patch: true)),
                BlueprintAttribute(.NSTabView.Miscellaneous.drawsBackground, AttributeInfo(className: "NSTabView", fullTitle: "DrawsBackground", patch: true)),
            ]),
            BlueprintSection(.NSTabView.information, title: "Info", attributes: [
                BlueprintAttribute(.NSTabView.Information.numberOfTabViewItems, AttributeInfo(className: "NSTabView", fullTitle: "NumberOfTabViewItems", setterString: "", patch: false)),
            ]),
            BlueprintSection(.NSTabView.font, title: "Font", attributes: [
                BlueprintAttribute(.NSTabView.Font.font, AttributeInfo(className: "NSTabView", fullTitle: "Font", getterString: "font", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.font))),
            ]),
            BlueprintSection(.NSTabView.minimumSize, title: "MinimumSize", attributes: [
                BlueprintAttribute(.NSTabView.MinimumSize.minimumSize, AttributeInfo(className: "NSTabView", fullTitle: "MinimumSize", getterString: "minimumSize", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSTabView.controlSize, title: "ControlSize", attributes: [
                BlueprintAttribute(.NSTabView.ControlSize.controlSize, AttributeInfo(className: "NSTabView", fullTitle: "ControlSize", getterString: "controlSize", setterString: "setControlSize:", enumList: "NSControlSize", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSTabView.contentRect, title: "ContentRect", attributes: [
                BlueprintAttribute(.NSTabView.ContentRect.contentRect, AttributeInfo(className: "NSTabView", fullTitle: "ContentRect", getterString: "contentRect", setterString: "", revision: 1)),
            ]),
        ])

        static let nsGridViewGroup = BlueprintGroup(.nsGridView, title: "NSGridView", on: .appKit, sections: [
            BlueprintSection(.NSGridView.dimensions, title: "Dimensions", attributes: [
                BlueprintAttribute(.NSGridView.Dimensions.numberOfColumns, AttributeInfo(className: "NSGridView", fullTitle: "NumberOfColumns", setterString: "", patch: false)),
                BlueprintAttribute(.NSGridView.Dimensions.numberOfRows, AttributeInfo(className: "NSGridView", fullTitle: "NumberOfRows", setterString: "", patch: false)),
            ]),
            BlueprintSection(.NSGridView.spacing, title: "Spacing", attributes: [
                BlueprintAttribute(.NSGridView.Spacing.rowSpacing, AttributeInfo(className: "NSGridView", fullTitle: "RowSpacing", patch: true)),
                BlueprintAttribute(.NSGridView.Spacing.columnSpacing, AttributeInfo(className: "NSGridView", fullTitle: "ColumnSpacing", patch: true)),
            ]),
            BlueprintSection(.NSGridView.placement, title: "Placement", attributes: [
                BlueprintAttribute(.NSGridView.Placement.xPlacement, AttributeInfo(className: "NSGridView", fullTitle: "XPlacement", enumList: "NSGridCellPlacement", patch: true)),
                BlueprintAttribute(.NSGridView.Placement.yPlacement, AttributeInfo(className: "NSGridView", fullTitle: "YPlacement", enumList: "NSGridCellPlacement", patch: true)),
            ]),
            BlueprintSection(.NSGridView.rowAlignment, title: "RowAlignment", attributes: [
                BlueprintAttribute(.NSGridView.RowAlignment.rowAlignment, AttributeInfo(className: "NSGridView", fullTitle: "RowAlignment", getterString: "rowAlignment", setterString: "setRowAlignment:", enumList: "NSGridRowAlignment", patch: true, revision: 1)),
            ]),
        ])

        static let nsCellGroup = BlueprintGroup(.nsCell, title: "NSCell", on: .appKit, sections: [
            BlueprintSection(.NSCell.cell, title: "Cell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.Cell.type, AttributeInfo(className: "NSCell", fullTitle: "CellType", getterString: "type", setterString: "", enumList: "NSCellType")),
                BlueprintAttribute(.NSCell.Cell.state, AttributeInfo(className: "NSCell", fullTitle: "State", getterString: "state", setterString: "", enumList: "NSControlStateValue")),
                BlueprintAttribute(.NSCell.Cell.enabled, AttributeInfo(className: "NSCell", fullTitle: "Enabled", getterString: "isEnabled", setterString: "")),
                BlueprintAttribute(.NSCell.Cell.bordered, AttributeInfo(className: "NSCell", fullTitle: "Bordered", getterString: "isBordered", setterString: "")),
                BlueprintAttribute(.NSCell.Cell.bezeled, AttributeInfo(className: "NSCell", fullTitle: "Bezeled", getterString: "isBezeled", setterString: "")),
                BlueprintAttribute(.NSCell.Cell.highlighted, AttributeInfo(className: "NSCell", fullTitle: "Highlighted", getterString: "isHighlighted", setterString: "")),
                BlueprintAttribute(.NSCell.Cell.editable, AttributeInfo(className: "NSCell", fullTitle: "Editable", getterString: "isEditable", setterString: "")),
                BlueprintAttribute(.NSCell.Cell.selectable, AttributeInfo(className: "NSCell", fullTitle: "Selectable", getterString: "isSelectable", setterString: "")),
                BlueprintAttribute(.NSCell.Cell.alignment, AttributeInfo(className: "NSCell", fullTitle: "Alignment", getterString: "alignment", setterString: "", enumList: "NSTextAlignment_AppKit")),
                BlueprintAttribute(.NSCell.Cell.controlSize, AttributeInfo(className: "NSCell", fullTitle: "ControlSize", getterString: "controlSize", setterString: "", enumList: "NSControlSize")),
            ]),
            BlueprintSection(.NSCell.content, title: "Content", on: .all, attributes: [
                BlueprintAttribute(.NSCell.Content.title, AttributeInfo(className: "NSCell", fullTitle: "Title", getterString: "title", setterString: "", objectValueType: .nsString, hideIfNil: true)),
                BlueprintAttribute(.NSCell.Content.fontName, AttributeInfo(className: "NSCell", fullTitle: "FontName", getterString: "lks_fontName", setterString: "", objectValueType: .nsString, hideIfNil: true)),
                BlueprintAttribute(.NSCell.Content.fontSize, AttributeInfo(className: "NSCell", fullTitle: "FontSize", getterString: "lks_fontSize", setterString: "")),
                BlueprintAttribute(.NSCell.Content.lineBreakMode, AttributeInfo(className: "NSCell", fullTitle: "LineBreakMode", getterString: "lineBreakMode", setterString: "", enumList: "NSLineBreakMode")),
                BlueprintAttribute(.NSCell.Content.wraps, AttributeInfo(className: "NSCell", fullTitle: "Wraps", getterString: "wraps", setterString: "")),
            ]),
            BlueprintSection(.NSCell.behavior, title: "Behavior", on: .all, attributes: [
                BlueprintAttribute(.NSCell.Behavior.tag, AttributeInfo(className: "NSCell", fullTitle: "Tag", getterString: "tag", setterString: "")),
                BlueprintAttribute(.NSCell.Behavior.continuous, AttributeInfo(className: "NSCell", fullTitle: "Continuous", getterString: "isContinuous", setterString: "")),
                BlueprintAttribute(.NSCell.Behavior.allowsMixedState, AttributeInfo(className: "NSCell", fullTitle: "AllowsMixedState", getterString: "allowsMixedState", setterString: "")),
                BlueprintAttribute(.NSCell.Behavior.sendsActionOnEndEditing, AttributeInfo(className: "NSCell", fullTitle: "SendsActionOnEndEditing", getterString: "sendsActionOnEndEditing", setterString: "")),
            ]),
            BlueprintSection(.NSCell.buttonCell, title: "NSButtonCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.ButtonCell.bezelStyle, AttributeInfo(className: "NSButtonCell", fullTitle: "BezelStyle", getterString: "bezelStyle", setterString: "", enumList: "NSBezelStyle")),
                BlueprintAttribute(.NSCell.ButtonCell.imagePosition, AttributeInfo(className: "NSButtonCell", fullTitle: "ImagePosition", getterString: "imagePosition", setterString: "", enumList: "NSCellImagePosition")),
                BlueprintAttribute(.NSCell.ButtonCell.showsBorderOnlyWhileMouseInside, AttributeInfo(className: "NSButtonCell", fullTitle: "ShowsBorderOnlyWhileMouseInside", getterString: "showsBorderOnlyWhileMouseInside", setterString: "")),
                BlueprintAttribute(.NSCell.ButtonCell.keyEquivalent, AttributeInfo(className: "NSButtonCell", fullTitle: "KeyEquivalent", getterString: "keyEquivalent", setterString: "", objectValueType: .nsString, hideIfNil: true)),
                BlueprintAttribute(.NSCell.ButtonCell.alternateTitle, AttributeInfo(className: "NSButtonCell", fullTitle: "AlternateTitle", getterString: "alternateTitle", setterString: "", objectValueType: .nsString, hideIfNil: true)),
                BlueprintAttribute(.NSCell.ButtonCell.highlightsBy, AttributeInfo(className: "NSButtonCell", fullTitle: "HighlightsBy", getterString: "highlightsBy", setterString: "", revision: 1, presentation: .optionNames("NSCellStyleMask"))),
                BlueprintAttribute(.NSCell.ButtonCell.showsStateBy, AttributeInfo(className: "NSButtonCell", fullTitle: "ShowsStateBy", getterString: "showsStateBy", setterString: "", revision: 1, presentation: .optionNames("NSCellStyleMask"))),
                BlueprintAttribute(.NSCell.ButtonCell.title, AttributeInfo(className: "NSButtonCell", fullTitle: "Title", getterString: "title", setterString: "", objectValueType: .nsString, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.NSCell.ButtonCell.attributedTitle, AttributeInfo(className: "NSButtonCell", fullTitle: "AttributedTitle", getterString: "attributedTitle", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.attributedString))),
                BlueprintAttribute(.NSCell.ButtonCell.attributedAlternateTitle, AttributeInfo(className: "NSButtonCell", fullTitle: "AttributedAlternateTitle", getterString: "attributedAlternateTitle", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.attributedString))),
                BlueprintAttribute(.NSCell.ButtonCell.alternateImage, AttributeInfo(className: "NSButtonCell", fullTitle: "AlternateImage", getterString: "alternateImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.NSCell.ButtonCell.imageScaling, AttributeInfo(className: "NSButtonCell", fullTitle: "ImageScaling", getterString: "imageScaling", setterString: "", enumList: "NSImageScaling", revision: 1)),
                BlueprintAttribute(.NSCell.ButtonCell.keyEquivalentModifierMask, AttributeInfo(className: "NSButtonCell", fullTitle: "KeyEquivalentModifierMask", getterString: "keyEquivalentModifierMask", setterString: "", revision: 1, presentation: .optionNames("NSEventModifierFlags"))),
                BlueprintAttribute(.NSCell.ButtonCell.transparent, AttributeInfo(className: "NSButtonCell", fullTitle: "Transparent", getterString: "isTransparent", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.ButtonCell.opaque, AttributeInfo(className: "NSButtonCell", fullTitle: "Opaque", getterString: "isOpaque", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.ButtonCell.imageDimsWhenDisabled, AttributeInfo(className: "NSButtonCell", fullTitle: "ImageDimsWhenDisabled", getterString: "imageDimsWhenDisabled", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.ButtonCell.backgroundColor, AttributeInfo(className: "NSButtonCell", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "", objectValueType: .uiColor, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSCell.textFieldCell, title: "NSTextFieldCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.TextFieldCell.placeholder, AttributeInfo(className: "NSTextFieldCell", fullTitle: "Placeholder", getterString: "placeholderString", setterString: "", objectValueType: .nsString, hideIfNil: true)),
                BlueprintAttribute(.NSCell.TextFieldCell.drawsBackground, AttributeInfo(className: "NSTextFieldCell", fullTitle: "DrawsBackground", getterString: "drawsBackground", setterString: "")),
                BlueprintAttribute(.NSCell.TextFieldCell.textColor, AttributeInfo(className: "NSTextFieldCell", fullTitle: "TextColor", getterString: "textColor", setterString: "", objectValueType: .uiColor, hideIfNil: true)),
                BlueprintAttribute(.NSCell.TextFieldCell.backgroundColor, AttributeInfo(className: "NSTextFieldCell", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "", objectValueType: .uiColor, hideIfNil: true)),
                BlueprintAttribute(.NSCell.TextFieldCell.bezelStyle, AttributeInfo(className: "NSTextFieldCell", fullTitle: "BezelStyle", getterString: "bezelStyle", setterString: "", enumList: "NSTextFieldBezelStyle")),
                BlueprintAttribute(.NSCell.TextFieldCell.placeholderAttributedString, AttributeInfo(className: "NSTextFieldCell", fullTitle: "PlaceholderAttributedString", getterString: "placeholderAttributedString", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.attributedString))),
                BlueprintAttribute(.NSCell.TextFieldCell.allowedInputSourceLocales, AttributeInfo(className: "NSTextFieldCell", fullTitle: "AllowedInputSourceLocales", getterString: "allowedInputSourceLocales", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(.NSCell.controlView, title: "ControlView", on: .all, attributes: [
                BlueprintAttribute(.NSCell.ControlView.controlView, AttributeInfo(className: "NSCell", fullTitle: "ControlView", getterString: "controlView", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.className))),
            ]),
            BlueprintSection(.NSCell.flags, title: "Flags", on: .all, attributes: [
                BlueprintAttribute(.NSCell.Flags.opaque, AttributeInfo(className: "NSCell", fullTitle: "Opaque", getterString: "isOpaque", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.Flags.scrollable, AttributeInfo(className: "NSCell", fullTitle: "Scrollable", getterString: "isScrollable", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.Flags.hasValidObjectValue, AttributeInfo(className: "NSCell", fullTitle: "HasValidObjectValue", getterString: "hasValidObjectValue", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.Flags.allowsUndo, AttributeInfo(className: "NSCell", fullTitle: "AllowsUndo", getterString: "allowsUndo", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.Flags.truncatesLastVisibleLine, AttributeInfo(className: "NSCell", fullTitle: "TruncatesLastVisibleLine", getterString: "truncatesLastVisibleLine", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.Flags.usesSingleLineMode, AttributeInfo(className: "NSCell", fullTitle: "UsesSingleLineMode", getterString: "usesSingleLineMode", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.Flags.refusesFirstResponder, AttributeInfo(className: "NSCell", fullTitle: "RefusesFirstResponder", getterString: "refusesFirstResponder", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.Flags.acceptsFirstResponder, AttributeInfo(className: "NSCell", fullTitle: "AcceptsFirstResponder", getterString: "acceptsFirstResponder", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.Flags.showsFirstResponder, AttributeInfo(className: "NSCell", fullTitle: "ShowsFirstResponder", getterString: "showsFirstResponder", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.Flags.wantsNotificationForMarkedText, AttributeInfo(className: "NSCell", fullTitle: "WantsNotificationForMarkedText", getterString: "wantsNotificationForMarkedText", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.Flags.allowsEditingTextAttributes, AttributeInfo(className: "NSCell", fullTitle: "AllowsEditingTextAttributes", getterString: "allowsEditingTextAttributes", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.Flags.importsGraphics, AttributeInfo(className: "NSCell", fullTitle: "ImportsGraphics", getterString: "importsGraphics", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSCell.font, title: "Font", on: .all, attributes: [
                BlueprintAttribute(.NSCell.Font.font, AttributeInfo(className: "NSCell", fullTitle: "Font", getterString: "font", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.font))),
            ]),
            BlueprintSection(.NSCell.keyEquivalent, title: "KeyEquivalent", on: .all, attributes: [
                BlueprintAttribute(.NSCell.KeyEquivalent.keyEquivalent, AttributeInfo(className: "NSCell", fullTitle: "KeyEquivalent", getterString: "keyEquivalent", setterString: "", objectValueType: .nsString, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSCell.stringValue, title: "StringValue", on: .all, attributes: [
                BlueprintAttribute(.NSCell.StringValue.stringValue, AttributeInfo(className: "NSCell", fullTitle: "StringValue", getterString: "stringValue", setterString: "", objectValueType: .nsString, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSCell.intValue, title: "IntValue", on: .all, attributes: [
                BlueprintAttribute(.NSCell.IntValue.intValue, AttributeInfo(className: "NSCell", fullTitle: "IntValue", getterString: "intValue", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSCell.floatValue, title: "FloatValue", on: .all, attributes: [
                BlueprintAttribute(.NSCell.FloatValue.floatValue, AttributeInfo(className: "NSCell", fullTitle: "FloatValue", getterString: "floatValue", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSCell.doubleValue, title: "DoubleValue", on: .all, attributes: [
                BlueprintAttribute(.NSCell.DoubleValue.doubleValue, AttributeInfo(className: "NSCell", fullTitle: "DoubleValue", getterString: "doubleValue", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSCell.integerValue, title: "IntegerValue", on: .all, attributes: [
                BlueprintAttribute(.NSCell.IntegerValue.integerValue, AttributeInfo(className: "NSCell", fullTitle: "IntegerValue", getterString: "integerValue", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSCell.image, title: "Image", on: .all, attributes: [
                BlueprintAttribute(.NSCell.Image.image, AttributeInfo(className: "NSCell", fullTitle: "Image", getterString: "image", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(.NSCell.cellSize, title: "CellSize", on: .all, attributes: [
                BlueprintAttribute(.NSCell.CellSize.cellSize, AttributeInfo(className: "NSCell", fullTitle: "CellSize", getterString: "cellSize", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSCell.mouseDownFlags, title: "MouseDownFlags", on: .all, attributes: [
                BlueprintAttribute(.NSCell.MouseDownFlags.mouseDownFlags, AttributeInfo(className: "NSCell", fullTitle: "MouseDownFlags", getterString: "mouseDownFlags", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSCell.menu, title: "Menu", on: .all, attributes: [
                BlueprintAttribute(.NSCell.Menu.menu, AttributeInfo(className: "NSCell", fullTitle: "Menu", getterString: "menu", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.menu))),
            ]),
            BlueprintSection(.NSCell.baseWritingDirection, title: "BaseWritingDirection", on: .all, attributes: [
                BlueprintAttribute(.NSCell.BaseWritingDirection.baseWritingDirection, AttributeInfo(className: "NSCell", fullTitle: "BaseWritingDirection", getterString: "baseWritingDirection", setterString: "", enumList: "NSWritingDirection", revision: 1)),
            ]),
            BlueprintSection(.NSCell.userInterfaceLayoutDirection, title: "UserInterfaceLayoutDirection", on: .all, attributes: [
                BlueprintAttribute(.NSCell.UserInterfaceLayoutDirection.userInterfaceLayoutDirection, AttributeInfo(className: "NSCell", fullTitle: "UserInterfaceLayoutDirection", getterString: "userInterfaceLayoutDirection", setterString: "", enumList: "NSUserInterfaceLayoutDirection", revision: 1)),
            ]),
            BlueprintSection(.NSCell.focusRingType, title: "FocusRingType", on: .all, attributes: [
                BlueprintAttribute(.NSCell.FocusRingType.focusRingType, AttributeInfo(className: "NSCell", fullTitle: "FocusRingType", getterString: "focusRingType", setterString: "", enumList: "NSFocusRingType", revision: 1)),
            ]),
            BlueprintSection(.NSCell.attributedStringValue, title: "AttributedStringValue", on: .all, attributes: [
                BlueprintAttribute(.NSCell.AttributedStringValue.attributedStringValue, AttributeInfo(className: "NSCell", fullTitle: "AttributedStringValue", getterString: "attributedStringValue", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.attributedString))),
            ]),
            BlueprintSection(.NSCell.nextState, title: "NextState", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NextState.nextState, AttributeInfo(className: "NSCell", fullTitle: "NextState", getterString: "nextState", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSCell.backgroundStyle, title: "BackgroundStyle", on: .all, attributes: [
                BlueprintAttribute(.NSCell.BackgroundStyle.backgroundStyle, AttributeInfo(className: "NSCell", fullTitle: "BackgroundStyle", getterString: "backgroundStyle", setterString: "", enumList: "NSBackgroundStyle", revision: 1)),
            ]),
            BlueprintSection(.NSCell.interiorBackgroundStyle, title: "InteriorBackgroundStyle", on: .all, attributes: [
                BlueprintAttribute(.NSCell.InteriorBackgroundStyle.interiorBackgroundStyle, AttributeInfo(className: "NSCell", fullTitle: "InteriorBackgroundStyle", getterString: "interiorBackgroundStyle", setterString: "", enumList: "NSBackgroundStyle", revision: 1)),
            ]),
            BlueprintSection(.NSCell.nsActionCell, title: "NSActionCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NSActionCell.tag, AttributeInfo(className: "NSActionCell", fullTitle: "Tag", getterString: "tag", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSCell.nsMenuItemCell, title: "NSMenuItemCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NSMenuItemCell.needsSizing, AttributeInfo(className: "NSMenuItemCell", fullTitle: "NeedsSizing", getterString: "needsSizing", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSMenuItemCell.needsDisplay, AttributeInfo(className: "NSMenuItemCell", fullTitle: "NeedsDisplay", getterString: "needsDisplay", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSMenuItemCell.tag, AttributeInfo(className: "NSMenuItemCell", fullTitle: "Tag", getterString: "tag", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSCell.nsPopUpButtonCell, title: "NSPopUpButtonCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NSPopUpButtonCell.menu, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "Menu", getterString: "menu", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.menu))),
                BlueprintAttribute(.NSCell.NSPopUpButtonCell.pullsDown, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "PullsDown", getterString: "pullsDown", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSPopUpButtonCell.autoenablesItems, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "AutoenablesItems", getterString: "autoenablesItems", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSPopUpButtonCell.preferredEdge, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "PreferredEdge", getterString: "preferredEdge", setterString: "", enumList: "NSRectEdge", revision: 1)),
                BlueprintAttribute(.NSCell.NSPopUpButtonCell.usesItemFromMenu, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "UsesItemFromMenu", getterString: "usesItemFromMenu", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSPopUpButtonCell.altersStateOfSelectedItem, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "AltersStateOfSelectedItem", getterString: "altersStateOfSelectedItem", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSPopUpButtonCell.numberOfItems, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "NumberOfItems", getterString: "numberOfItems", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSPopUpButtonCell.indexOfSelectedItem, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "IndexOfSelectedItem", getterString: "indexOfSelectedItem", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSPopUpButtonCell.itemTitles, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "ItemTitles", getterString: "itemTitles", setterString: "", revision: 1, presentation: .count)),
                BlueprintAttribute(.NSCell.NSPopUpButtonCell.titleOfSelectedItem, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "TitleOfSelectedItem", getterString: "titleOfSelectedItem", setterString: "", objectValueType: .nsString, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.NSCell.NSPopUpButtonCell.arrowPosition, AttributeInfo(className: "NSPopUpButtonCell", fullTitle: "ArrowPosition", getterString: "arrowPosition", setterString: "", enumList: "NSPopUpArrowPosition", revision: 1)),
            ]),
            BlueprintSection(.NSCell.nsDatePickerCell, title: "NSDatePickerCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NSDatePickerCell.datePickerStyle, AttributeInfo(className: "NSDatePickerCell", fullTitle: "DatePickerStyle", getterString: "datePickerStyle", setterString: "", enumList: "NSDatePickerStyle", revision: 1)),
                BlueprintAttribute(.NSCell.NSDatePickerCell.drawsBackground, AttributeInfo(className: "NSDatePickerCell", fullTitle: "DrawsBackground", getterString: "drawsBackground", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSDatePickerCell.backgroundColor, AttributeInfo(className: "NSDatePickerCell", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "", objectValueType: .uiColor, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.NSCell.NSDatePickerCell.textColor, AttributeInfo(className: "NSDatePickerCell", fullTitle: "TextColor", getterString: "textColor", setterString: "", objectValueType: .uiColor, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.NSCell.NSDatePickerCell.datePickerMode, AttributeInfo(className: "NSDatePickerCell", fullTitle: "DatePickerMode", getterString: "datePickerMode", setterString: "", enumList: "NSDatePickerMode", revision: 1)),
                BlueprintAttribute(.NSCell.NSDatePickerCell.datePickerElements, AttributeInfo(className: "NSDatePickerCell", fullTitle: "DatePickerElements", getterString: "datePickerElements", setterString: "", revision: 1, presentation: .optionNames("NSDatePickerElementFlags"))),
                BlueprintAttribute(.NSCell.NSDatePickerCell.calendar, AttributeInfo(className: "NSDatePickerCell", fullTitle: "Calendar", getterString: "calendar", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.calendar))),
                BlueprintAttribute(.NSCell.NSDatePickerCell.locale, AttributeInfo(className: "NSDatePickerCell", fullTitle: "Locale", getterString: "locale", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.locale))),
                BlueprintAttribute(.NSCell.NSDatePickerCell.timeZone, AttributeInfo(className: "NSDatePickerCell", fullTitle: "TimeZone", getterString: "timeZone", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.timeZone))),
                BlueprintAttribute(.NSCell.NSDatePickerCell.dateValue, AttributeInfo(className: "NSDatePickerCell", fullTitle: "DateValue", getterString: "dateValue", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.date))),
                BlueprintAttribute(.NSCell.NSDatePickerCell.timeInterval, AttributeInfo(className: "NSDatePickerCell", fullTitle: "TimeInterval", getterString: "timeInterval", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSDatePickerCell.minDate, AttributeInfo(className: "NSDatePickerCell", fullTitle: "MinDate", getterString: "minDate", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.date))),
                BlueprintAttribute(.NSCell.NSDatePickerCell.maxDate, AttributeInfo(className: "NSDatePickerCell", fullTitle: "MaxDate", getterString: "maxDate", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.date))),
            ]),
            BlueprintSection(.NSCell.nsFormCell, title: "NSFormCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NSFormCell.titleWidth, AttributeInfo(className: "NSFormCell", fullTitle: "TitleWidth", getterString: "titleWidth", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSFormCell.title, AttributeInfo(className: "NSFormCell", fullTitle: "Title", getterString: "title", setterString: "", objectValueType: .nsString, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.NSCell.NSFormCell.titleFont, AttributeInfo(className: "NSFormCell", fullTitle: "TitleFont", getterString: "titleFont", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.font))),
                BlueprintAttribute(.NSCell.NSFormCell.opaque, AttributeInfo(className: "NSFormCell", fullTitle: "Opaque", getterString: "isOpaque", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSFormCell.placeholderString, AttributeInfo(className: "NSFormCell", fullTitle: "PlaceholderString", getterString: "placeholderString", setterString: "", objectValueType: .nsString, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.NSCell.NSFormCell.placeholderAttributedString, AttributeInfo(className: "NSFormCell", fullTitle: "PlaceholderAttributedString", getterString: "placeholderAttributedString", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.attributedString))),
                BlueprintAttribute(.NSCell.NSFormCell.titleAlignment, AttributeInfo(className: "NSFormCell", fullTitle: "TitleAlignment", getterString: "titleAlignment", setterString: "", enumList: "NSTextAlignment", revision: 1)),
                BlueprintAttribute(.NSCell.NSFormCell.titleBaseWritingDirection, AttributeInfo(className: "NSFormCell", fullTitle: "TitleBaseWritingDirection", getterString: "titleBaseWritingDirection", setterString: "", enumList: "NSWritingDirection", revision: 1)),
                BlueprintAttribute(.NSCell.NSFormCell.preferredTextFieldWidth, AttributeInfo(className: "NSFormCell", fullTitle: "PreferredTextFieldWidth", getterString: "preferredTextFieldWidth", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSFormCell.attributedTitle, AttributeInfo(className: "NSFormCell", fullTitle: "AttributedTitle", getterString: "attributedTitle", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.attributedString))),
            ]),
            BlueprintSection(.NSCell.nsLevelIndicatorCell, title: "NSLevelIndicatorCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NSLevelIndicatorCell.levelIndicatorStyle, AttributeInfo(className: "NSLevelIndicatorCell", fullTitle: "LevelIndicatorStyle", getterString: "levelIndicatorStyle", setterString: "", enumList: "NSLevelIndicatorStyle", revision: 1)),
                BlueprintAttribute(.NSCell.NSLevelIndicatorCell.minValue, AttributeInfo(className: "NSLevelIndicatorCell", fullTitle: "MinValue", getterString: "minValue", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSLevelIndicatorCell.maxValue, AttributeInfo(className: "NSLevelIndicatorCell", fullTitle: "MaxValue", getterString: "maxValue", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSLevelIndicatorCell.warningValue, AttributeInfo(className: "NSLevelIndicatorCell", fullTitle: "WarningValue", getterString: "warningValue", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSLevelIndicatorCell.criticalValue, AttributeInfo(className: "NSLevelIndicatorCell", fullTitle: "CriticalValue", getterString: "criticalValue", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSLevelIndicatorCell.tickMarkPosition, AttributeInfo(className: "NSLevelIndicatorCell", fullTitle: "TickMarkPosition", getterString: "tickMarkPosition", setterString: "", enumList: "NSTickMarkPosition", revision: 1)),
                BlueprintAttribute(.NSCell.NSLevelIndicatorCell.numberOfTickMarks, AttributeInfo(className: "NSLevelIndicatorCell", fullTitle: "NumberOfTickMarks", getterString: "numberOfTickMarks", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSLevelIndicatorCell.numberOfMajorTickMarks, AttributeInfo(className: "NSLevelIndicatorCell", fullTitle: "NumberOfMajorTickMarks", getterString: "numberOfMajorTickMarks", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSCell.nsPathCell, title: "NSPathCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NSPathCell.pathStyle, AttributeInfo(className: "NSPathCell", fullTitle: "PathStyle", getterString: "pathStyle", setterString: "", enumList: "NSPathStyle", revision: 1)),
                BlueprintAttribute(.NSCell.NSPathCell.url, AttributeInfo(className: "NSPathCell", fullTitle: "URL", getterString: "URL", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.url))),
                BlueprintAttribute(.NSCell.NSPathCell.allowedTypes, AttributeInfo(className: "NSPathCell", fullTitle: "AllowedTypes", getterString: "allowedTypes", setterString: "", revision: 1, presentation: .count)),
                BlueprintAttribute(.NSCell.NSPathCell.pathComponentCells, AttributeInfo(className: "NSPathCell", fullTitle: "PathComponentCells", getterString: "pathComponentCells", setterString: "", revision: 1, presentation: .count)),
                BlueprintAttribute(.NSCell.NSPathCell.backgroundColor, AttributeInfo(className: "NSPathCell", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "", objectValueType: .uiColor, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.NSCell.NSPathCell.placeholderString, AttributeInfo(className: "NSPathCell", fullTitle: "PlaceholderString", getterString: "placeholderString", setterString: "", objectValueType: .nsString, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.NSCell.NSPathCell.placeholderAttributedString, AttributeInfo(className: "NSPathCell", fullTitle: "PlaceholderAttributedString", getterString: "placeholderAttributedString", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.attributedString))),
            ]),
            BlueprintSection(.NSCell.nsSegmentedCell, title: "NSSegmentedCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NSSegmentedCell.segmentCount, AttributeInfo(className: "NSSegmentedCell", fullTitle: "SegmentCount", getterString: "segmentCount", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSSegmentedCell.selectedSegment, AttributeInfo(className: "NSSegmentedCell", fullTitle: "SelectedSegment", getterString: "selectedSegment", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSSegmentedCell.trackingMode, AttributeInfo(className: "NSSegmentedCell", fullTitle: "TrackingMode", getterString: "trackingMode", setterString: "", enumList: "NSSegmentSwitchTracking", revision: 1)),
                BlueprintAttribute(.NSCell.NSSegmentedCell.segmentStyle, AttributeInfo(className: "NSSegmentedCell", fullTitle: "SegmentStyle", getterString: "segmentStyle", setterString: "", enumList: "NSSegmentStyle", revision: 1)),
            ]),
            BlueprintSection(.NSCell.nsSliderCell, title: "NSSliderCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NSSliderCell.minValue, AttributeInfo(className: "NSSliderCell", fullTitle: "MinValue", getterString: "minValue", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSSliderCell.maxValue, AttributeInfo(className: "NSSliderCell", fullTitle: "MaxValue", getterString: "maxValue", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSSliderCell.altIncrementValue, AttributeInfo(className: "NSSliderCell", fullTitle: "AltIncrementValue", getterString: "altIncrementValue", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSSliderCell.sliderType, AttributeInfo(className: "NSSliderCell", fullTitle: "SliderType", getterString: "sliderType", setterString: "", enumList: "NSSliderType", revision: 1)),
                BlueprintAttribute(.NSCell.NSSliderCell.vertical, AttributeInfo(className: "NSSliderCell", fullTitle: "Vertical", getterString: "isVertical", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSSliderCell.trackRect, AttributeInfo(className: "NSSliderCell", fullTitle: "TrackRect", getterString: "trackRect", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSSliderCell.knobThickness, AttributeInfo(className: "NSSliderCell", fullTitle: "KnobThickness", getterString: "knobThickness", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSSliderCell.numberOfTickMarks, AttributeInfo(className: "NSSliderCell", fullTitle: "NumberOfTickMarks", getterString: "numberOfTickMarks", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSSliderCell.tickMarkPosition, AttributeInfo(className: "NSSliderCell", fullTitle: "TickMarkPosition", getterString: "tickMarkPosition", setterString: "", enumList: "NSTickMarkPosition", revision: 1)),
                BlueprintAttribute(.NSCell.NSSliderCell.allowsTickMarkValuesOnly, AttributeInfo(className: "NSSliderCell", fullTitle: "AllowsTickMarkValuesOnly", getterString: "allowsTickMarkValuesOnly", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSCell.nsStepperCell, title: "NSStepperCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NSStepperCell.minValue, AttributeInfo(className: "NSStepperCell", fullTitle: "MinValue", getterString: "minValue", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSStepperCell.maxValue, AttributeInfo(className: "NSStepperCell", fullTitle: "MaxValue", getterString: "maxValue", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSStepperCell.increment, AttributeInfo(className: "NSStepperCell", fullTitle: "Increment", getterString: "increment", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSStepperCell.valueWraps, AttributeInfo(className: "NSStepperCell", fullTitle: "ValueWraps", getterString: "valueWraps", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSStepperCell.autorepeat, AttributeInfo(className: "NSStepperCell", fullTitle: "Autorepeat", getterString: "autorepeat", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSCell.nsComboBoxCell, title: "NSComboBoxCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NSComboBoxCell.hasVerticalScroller, AttributeInfo(className: "NSComboBoxCell", fullTitle: "HasVerticalScroller", getterString: "hasVerticalScroller", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSComboBoxCell.intercellSpacing, AttributeInfo(className: "NSComboBoxCell", fullTitle: "IntercellSpacing", getterString: "intercellSpacing", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSComboBoxCell.itemHeight, AttributeInfo(className: "NSComboBoxCell", fullTitle: "ItemHeight", getterString: "itemHeight", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSComboBoxCell.numberOfVisibleItems, AttributeInfo(className: "NSComboBoxCell", fullTitle: "NumberOfVisibleItems", getterString: "numberOfVisibleItems", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSComboBoxCell.buttonBordered, AttributeInfo(className: "NSComboBoxCell", fullTitle: "ButtonBordered", getterString: "isButtonBordered", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSComboBoxCell.usesDataSource, AttributeInfo(className: "NSComboBoxCell", fullTitle: "UsesDataSource", getterString: "usesDataSource", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSComboBoxCell.indexOfSelectedItem, AttributeInfo(className: "NSComboBoxCell", fullTitle: "IndexOfSelectedItem", getterString: "indexOfSelectedItem", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSComboBoxCell.numberOfItems, AttributeInfo(className: "NSComboBoxCell", fullTitle: "NumberOfItems", getterString: "numberOfItems", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSComboBoxCell.completes, AttributeInfo(className: "NSComboBoxCell", fullTitle: "Completes", getterString: "completes", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSComboBoxCell.objectValues, AttributeInfo(className: "NSComboBoxCell", fullTitle: "ObjectValues", getterString: "objectValues", setterString: "", revision: 1, presentation: .count)),
            ]),
            BlueprintSection(.NSCell.nsPathComponentCell, title: "NSPathComponentCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NSPathComponentCell.image, AttributeInfo(className: "NSPathComponentCell", fullTitle: "Image", getterString: "image", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.NSCell.NSPathComponentCell.url, AttributeInfo(className: "NSPathComponentCell", fullTitle: "URL", getterString: "URL", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.url))),
            ]),
            BlueprintSection(.NSCell.nsSearchFieldCell, title: "NSSearchFieldCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NSSearchFieldCell.searchMenuTemplate, AttributeInfo(className: "NSSearchFieldCell", fullTitle: "SearchMenuTemplate", getterString: "searchMenuTemplate", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.menu))),
                BlueprintAttribute(.NSCell.NSSearchFieldCell.sendsWholeSearchString, AttributeInfo(className: "NSSearchFieldCell", fullTitle: "SendsWholeSearchString", getterString: "sendsWholeSearchString", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSSearchFieldCell.maximumRecents, AttributeInfo(className: "NSSearchFieldCell", fullTitle: "MaximumRecents", getterString: "maximumRecents", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSSearchFieldCell.recentSearches, AttributeInfo(className: "NSSearchFieldCell", fullTitle: "RecentSearches", getterString: "recentSearches", setterString: "", revision: 1, presentation: .count)),
                BlueprintAttribute(.NSCell.NSSearchFieldCell.sendsSearchStringImmediately, AttributeInfo(className: "NSSearchFieldCell", fullTitle: "SendsSearchStringImmediately", getterString: "sendsSearchStringImmediately", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSCell.nsSecureTextFieldCell, title: "NSSecureTextFieldCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NSSecureTextFieldCell.echosBullets, AttributeInfo(className: "NSSecureTextFieldCell", fullTitle: "EchosBullets", getterString: "echosBullets", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSCell.nsTokenFieldCell, title: "NSTokenFieldCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NSTokenFieldCell.tokenStyle, AttributeInfo(className: "NSTokenFieldCell", fullTitle: "TokenStyle", getterString: "tokenStyle", setterString: "", enumList: "NSTokenStyle", revision: 1)),
                BlueprintAttribute(.NSCell.NSTokenFieldCell.completionDelay, AttributeInfo(className: "NSTokenFieldCell", fullTitle: "CompletionDelay", getterString: "completionDelay", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSCell.nsBrowserCell, title: "NSBrowserCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NSBrowserCell.leaf, AttributeInfo(className: "NSBrowserCell", fullTitle: "Leaf", getterString: "isLeaf", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSBrowserCell.loaded, AttributeInfo(className: "NSBrowserCell", fullTitle: "Loaded", getterString: "isLoaded", setterString: "", revision: 1)),
                BlueprintAttribute(.NSCell.NSBrowserCell.image, AttributeInfo(className: "NSBrowserCell", fullTitle: "Image", getterString: "image", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
                BlueprintAttribute(.NSCell.NSBrowserCell.alternateImage, AttributeInfo(className: "NSBrowserCell", fullTitle: "AlternateImage", getterString: "alternateImage", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(.NSCell.nsImageCell, title: "NSImageCell", on: .all, attributes: [
                BlueprintAttribute(.NSCell.NSImageCell.imageAlignment, AttributeInfo(className: "NSImageCell", fullTitle: "ImageAlignment", getterString: "imageAlignment", setterString: "", enumList: "NSImageAlignment", revision: 1)),
                BlueprintAttribute(.NSCell.NSImageCell.imageScaling, AttributeInfo(className: "NSImageCell", fullTitle: "ImageScaling", getterString: "imageScaling", setterString: "", enumList: "NSImageScaling", revision: 1)),
                BlueprintAttribute(.NSCell.NSImageCell.imageFrameStyle, AttributeInfo(className: "NSImageCell", fullTitle: "ImageFrameStyle", getterString: "imageFrameStyle", setterString: "", enumList: "NSImageFrameStyle", revision: 1)),
            ]),
        ])

        static let nsClipViewGroup = BlueprintGroup(.nsClipView, title: "NSClipView", on: .appKit, sections: [
            BlueprintSection(.NSClipView.backgroundColor, title: "BackgroundColor", attributes: [
                BlueprintAttribute(.NSClipView.BackgroundColor.backgroundColor, AttributeInfo(className: "NSClipView", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSClipView.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.NSClipView.Behavior.drawsBackground, AttributeInfo(className: "NSClipView", fullTitle: "DrawsBackground", getterString: "drawsBackground", setterString: "setDrawsBackground:", patch: true, revision: 1)),
                BlueprintAttribute(.NSClipView.Behavior.automaticallyAdjustsContentInsets, AttributeInfo(className: "NSClipView", fullTitle: "AutomaticallyAdjustsContentInsets", getterString: "automaticallyAdjustsContentInsets", setterString: "setAutomaticallyAdjustsContentInsets:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSClipView.documentRect, title: "DocumentRect", attributes: [
                BlueprintAttribute(.NSClipView.DocumentRect.documentRect, AttributeInfo(className: "NSClipView", fullTitle: "DocumentRect", getterString: "documentRect", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSClipView.documentVisibleRect, title: "DocumentVisibleRect", attributes: [
                BlueprintAttribute(.NSClipView.DocumentVisibleRect.documentVisibleRect, AttributeInfo(className: "NSClipView", fullTitle: "DocumentVisibleRect", getterString: "documentVisibleRect", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSClipView.contentInsets, title: "ContentInsets", attributes: [
                BlueprintAttribute(.NSClipView.ContentInsets.contentInsets, AttributeInfo(className: "NSClipView", fullTitle: "ContentInsets", getterString: "contentInsets", setterString: "setContentInsets:", patch: true, revision: 1)),
            ]),
        ])


        static let nsScrollerGroup = BlueprintGroup(.nsScroller, title: "NSScroller", on: .appKit, sections: [
            BlueprintSection(.NSScroller.scrollerStyle, title: "ScrollerStyle", attributes: [
                BlueprintAttribute(.NSScroller.ScrollerStyle.scrollerStyle, AttributeInfo(className: "NSScroller", fullTitle: "ScrollerStyle", getterString: "scrollerStyle", setterString: "setScrollerStyle:", enumList: "NSScrollerStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSScroller.knobStyle, title: "KnobStyle", attributes: [
                BlueprintAttribute(.NSScroller.KnobStyle.knobStyle, AttributeInfo(className: "NSScroller", fullTitle: "KnobStyle", getterString: "knobStyle", setterString: "setKnobStyle:", enumList: "NSScrollerKnobStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSScroller.usableParts, title: "UsableParts", attributes: [
                BlueprintAttribute(.NSScroller.UsableParts.usableParts, AttributeInfo(className: "NSScroller", fullTitle: "UsableParts", getterString: "usableParts", setterString: "", enumList: "NSUsableScrollerParts", revision: 1)),
            ]),
            BlueprintSection(.NSScroller.controlSize, title: "ControlSize", attributes: [
                BlueprintAttribute(.NSScroller.ControlSize.controlSize, AttributeInfo(className: "NSScroller", fullTitle: "ControlSize", getterString: "controlSize", setterString: "setControlSize:", enumList: "NSControlSize", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSScroller.hitPart, title: "HitPart", attributes: [
                BlueprintAttribute(.NSScroller.HitPart.hitPart, AttributeInfo(className: "NSScroller", fullTitle: "HitPart", getterString: "hitPart", setterString: "", enumList: "NSScrollerPart", revision: 1)),
            ]),
            BlueprintSection(.NSScroller.knobProportion, title: "KnobProportion", attributes: [
                BlueprintAttribute(.NSScroller.KnobProportion.knobProportion, AttributeInfo(className: "NSScroller", fullTitle: "KnobProportion", getterString: "knobProportion", setterString: "setKnobProportion:", patch: true, revision: 1)),
            ]),
        ])


        static let nsBrowserGroup = BlueprintGroup(.nsBrowser, title: "NSBrowser", on: .appKit, sections: [
            BlueprintSection(.NSBrowser.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.NSBrowser.Behavior.loaded, AttributeInfo(className: "NSBrowser", fullTitle: "Loaded", getterString: "isLoaded", setterString: "", revision: 1)),
                BlueprintAttribute(.NSBrowser.Behavior.reusesColumns, AttributeInfo(className: "NSBrowser", fullTitle: "ReusesColumns", getterString: "reusesColumns", setterString: "setReusesColumns:", patch: true, revision: 1)),
                BlueprintAttribute(.NSBrowser.Behavior.hasHorizontalScroller, AttributeInfo(className: "NSBrowser", fullTitle: "HasHorizontalScroller", getterString: "hasHorizontalScroller", setterString: "setHasHorizontalScroller:", patch: true, revision: 1)),
                BlueprintAttribute(.NSBrowser.Behavior.autohidesScroller, AttributeInfo(className: "NSBrowser", fullTitle: "AutohidesScroller", getterString: "autohidesScroller", setterString: "setAutohidesScroller:", patch: true, revision: 1)),
                BlueprintAttribute(.NSBrowser.Behavior.separatesColumns, AttributeInfo(className: "NSBrowser", fullTitle: "SeparatesColumns", getterString: "separatesColumns", setterString: "setSeparatesColumns:", patch: true, revision: 1)),
                BlueprintAttribute(.NSBrowser.Behavior.titled, AttributeInfo(className: "NSBrowser", fullTitle: "Titled", getterString: "isTitled", setterString: "setTitled:", patch: true, revision: 1)),
                BlueprintAttribute(.NSBrowser.Behavior.allowsMultipleSelection, AttributeInfo(className: "NSBrowser", fullTitle: "AllowsMultipleSelection", getterString: "allowsMultipleSelection", setterString: "setAllowsMultipleSelection:", patch: true, revision: 1)),
                BlueprintAttribute(.NSBrowser.Behavior.allowsBranchSelection, AttributeInfo(className: "NSBrowser", fullTitle: "AllowsBranchSelection", getterString: "allowsBranchSelection", setterString: "setAllowsBranchSelection:", patch: true, revision: 1)),
                BlueprintAttribute(.NSBrowser.Behavior.allowsEmptySelection, AttributeInfo(className: "NSBrowser", fullTitle: "AllowsEmptySelection", getterString: "allowsEmptySelection", setterString: "setAllowsEmptySelection:", patch: true, revision: 1)),
                BlueprintAttribute(.NSBrowser.Behavior.takesTitleFromPreviousColumn, AttributeInfo(className: "NSBrowser", fullTitle: "TakesTitleFromPreviousColumn", getterString: "takesTitleFromPreviousColumn", setterString: "setTakesTitleFromPreviousColumn:", patch: true, revision: 1)),
                BlueprintAttribute(.NSBrowser.Behavior.sendsActionOnArrowKeys, AttributeInfo(className: "NSBrowser", fullTitle: "SendsActionOnArrowKeys", getterString: "sendsActionOnArrowKeys", setterString: "setSendsActionOnArrowKeys:", patch: true, revision: 1)),
                BlueprintAttribute(.NSBrowser.Behavior.prefersAllColumnUserResizing, AttributeInfo(className: "NSBrowser", fullTitle: "PrefersAllColumnUserResizing", getterString: "prefersAllColumnUserResizing", setterString: "setPrefersAllColumnUserResizing:", patch: true, revision: 1)),
                BlueprintAttribute(.NSBrowser.Behavior.allowsTypeSelect, AttributeInfo(className: "NSBrowser", fullTitle: "AllowsTypeSelect", getterString: "allowsTypeSelect", setterString: "setAllowsTypeSelect:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSBrowser.minColumnWidth, title: "MinColumnWidth", attributes: [
                BlueprintAttribute(.NSBrowser.MinColumnWidth.minColumnWidth, AttributeInfo(className: "NSBrowser", fullTitle: "MinColumnWidth", getterString: "minColumnWidth", setterString: "setMinColumnWidth:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSBrowser.maxVisibleColumns, title: "MaxVisibleColumns", attributes: [
                BlueprintAttribute(.NSBrowser.MaxVisibleColumns.maxVisibleColumns, AttributeInfo(className: "NSBrowser", fullTitle: "MaxVisibleColumns", getterString: "maxVisibleColumns", setterString: "setMaxVisibleColumns:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSBrowser.pathSeparator, title: "PathSeparator", attributes: [
                BlueprintAttribute(.NSBrowser.PathSeparator.pathSeparator, AttributeInfo(className: "NSBrowser", fullTitle: "PathSeparator", getterString: "pathSeparator", setterString: "setPathSeparator:", objectValueType: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSBrowser.clickedColumn, title: "ClickedColumn", attributes: [
                BlueprintAttribute(.NSBrowser.ClickedColumn.clickedColumn, AttributeInfo(className: "NSBrowser", fullTitle: "ClickedColumn", getterString: "clickedColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSBrowser.clickedRow, title: "ClickedRow", attributes: [
                BlueprintAttribute(.NSBrowser.ClickedRow.clickedRow, AttributeInfo(className: "NSBrowser", fullTitle: "ClickedRow", getterString: "clickedRow", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSBrowser.selectedColumn, title: "SelectedColumn", attributes: [
                BlueprintAttribute(.NSBrowser.SelectedColumn.selectedColumn, AttributeInfo(className: "NSBrowser", fullTitle: "SelectedColumn", getterString: "selectedColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSBrowser.lastColumn, title: "LastColumn", attributes: [
                BlueprintAttribute(.NSBrowser.LastColumn.lastColumn, AttributeInfo(className: "NSBrowser", fullTitle: "LastColumn", getterString: "lastColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSBrowser.numberOfVisibleColumns, title: "NumberOfVisibleColumns", attributes: [
                BlueprintAttribute(.NSBrowser.NumberOfVisibleColumns.numberOfVisibleColumns, AttributeInfo(className: "NSBrowser", fullTitle: "NumberOfVisibleColumns", getterString: "numberOfVisibleColumns", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSBrowser.firstVisibleColumn, title: "FirstVisibleColumn", attributes: [
                BlueprintAttribute(.NSBrowser.FirstVisibleColumn.firstVisibleColumn, AttributeInfo(className: "NSBrowser", fullTitle: "FirstVisibleColumn", getterString: "firstVisibleColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSBrowser.lastVisibleColumn, title: "LastVisibleColumn", attributes: [
                BlueprintAttribute(.NSBrowser.LastVisibleColumn.lastVisibleColumn, AttributeInfo(className: "NSBrowser", fullTitle: "LastVisibleColumn", getterString: "lastVisibleColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSBrowser.titleHeight, title: "TitleHeight", attributes: [
                BlueprintAttribute(.NSBrowser.TitleHeight.titleHeight, AttributeInfo(className: "NSBrowser", fullTitle: "TitleHeight", getterString: "titleHeight", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSBrowser.columnResizingType, title: "ColumnResizingType", attributes: [
                BlueprintAttribute(.NSBrowser.ColumnResizingType.columnResizingType, AttributeInfo(className: "NSBrowser", fullTitle: "ColumnResizingType", getterString: "columnResizingType", setterString: "setColumnResizingType:", enumList: "NSBrowserColumnResizingType", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSBrowser.backgroundColor, title: "BackgroundColor", attributes: [
                BlueprintAttribute(.NSBrowser.BackgroundColor.backgroundColor, AttributeInfo(className: "NSBrowser", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
        ])


        static let nsMatrixGroup = BlueprintGroup(.nsMatrix, title: "NSMatrix", on: .appKit, sections: [
            BlueprintSection(.NSMatrix.mode, title: "Mode", attributes: [
                BlueprintAttribute(.NSMatrix.Mode.mode, AttributeInfo(className: "NSMatrix", fullTitle: "Mode", getterString: "mode", setterString: "setMode:", enumList: "NSMatrixMode", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSMatrix.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.NSMatrix.Behavior.allowsEmptySelection, AttributeInfo(className: "NSMatrix", fullTitle: "AllowsEmptySelection", getterString: "allowsEmptySelection", setterString: "setAllowsEmptySelection:", patch: true, revision: 1)),
                BlueprintAttribute(.NSMatrix.Behavior.selectionByRect, AttributeInfo(className: "NSMatrix", fullTitle: "SelectionByRect", getterString: "isSelectionByRect", setterString: "setSelectionByRect:", patch: true, revision: 1)),
                BlueprintAttribute(.NSMatrix.Behavior.drawsCellBackground, AttributeInfo(className: "NSMatrix", fullTitle: "DrawsCellBackground", getterString: "drawsCellBackground", setterString: "setDrawsCellBackground:", patch: true, revision: 1)),
                BlueprintAttribute(.NSMatrix.Behavior.drawsBackground, AttributeInfo(className: "NSMatrix", fullTitle: "DrawsBackground", getterString: "drawsBackground", setterString: "setDrawsBackground:", patch: true, revision: 1)),
                BlueprintAttribute(.NSMatrix.Behavior.autosizesCells, AttributeInfo(className: "NSMatrix", fullTitle: "AutosizesCells", getterString: "autosizesCells", setterString: "setAutosizesCells:", patch: true, revision: 1)),
                BlueprintAttribute(.NSMatrix.Behavior.autoscroll, AttributeInfo(className: "NSMatrix", fullTitle: "Autoscroll", getterString: "isAutoscroll", setterString: "setAutoscroll:", patch: true, revision: 1)),
                BlueprintAttribute(.NSMatrix.Behavior.autorecalculatesCellSize, AttributeInfo(className: "NSMatrix", fullTitle: "AutorecalculatesCellSize", getterString: "autorecalculatesCellSize", setterString: "setAutorecalculatesCellSize:", patch: true, revision: 1)),
                BlueprintAttribute(.NSMatrix.Behavior.tabKeyTraversesCells, AttributeInfo(className: "NSMatrix", fullTitle: "TabKeyTraversesCells", getterString: "tabKeyTraversesCells", setterString: "setTabKeyTraversesCells:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSMatrix.selectedRow, title: "SelectedRow", attributes: [
                BlueprintAttribute(.NSMatrix.SelectedRow.selectedRow, AttributeInfo(className: "NSMatrix", fullTitle: "SelectedRow", getterString: "selectedRow", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSMatrix.selectedColumn, title: "SelectedColumn", attributes: [
                BlueprintAttribute(.NSMatrix.SelectedColumn.selectedColumn, AttributeInfo(className: "NSMatrix", fullTitle: "SelectedColumn", getterString: "selectedColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSMatrix.cellSize, title: "CellSize", attributes: [
                BlueprintAttribute(.NSMatrix.CellSize.cellSize, AttributeInfo(className: "NSMatrix", fullTitle: "CellSize", getterString: "cellSize", setterString: "setCellSize:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSMatrix.intercellSpacing, title: "IntercellSpacing", attributes: [
                BlueprintAttribute(.NSMatrix.IntercellSpacing.intercellSpacing, AttributeInfo(className: "NSMatrix", fullTitle: "IntercellSpacing", getterString: "intercellSpacing", setterString: "setIntercellSpacing:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSMatrix.colors, title: "Colors", attributes: [
                BlueprintAttribute(.NSMatrix.Colors.backgroundColor, AttributeInfo(className: "NSMatrix", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
                BlueprintAttribute(.NSMatrix.Colors.cellBackgroundColor, AttributeInfo(className: "NSMatrix", fullTitle: "CellBackgroundColor", getterString: "cellBackgroundColor", setterString: "setCellBackgroundColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSMatrix.numberOfRows, title: "NumberOfRows", attributes: [
                BlueprintAttribute(.NSMatrix.NumberOfRows.numberOfRows, AttributeInfo(className: "NSMatrix", fullTitle: "NumberOfRows", getterString: "numberOfRows", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSMatrix.numberOfColumns, title: "NumberOfColumns", attributes: [
                BlueprintAttribute(.NSMatrix.NumberOfColumns.numberOfColumns, AttributeInfo(className: "NSMatrix", fullTitle: "NumberOfColumns", getterString: "numberOfColumns", setterString: "", revision: 1)),
            ]),
        ])


        static let nsPathControlGroup = BlueprintGroup(.nsPathControl, title: "NSPathControl", on: .appKit, sections: [
            BlueprintSection(.NSPathControl.editable, title: "Editable", attributes: [
                BlueprintAttribute(.NSPathControl.Editable.editable, AttributeInfo(className: "NSPathControl", fullTitle: "Editable", getterString: "isEditable", setterString: "setEditable:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSPathControl.placeholderString, title: "PlaceholderString", attributes: [
                BlueprintAttribute(.NSPathControl.PlaceholderString.placeholderString, AttributeInfo(className: "NSPathControl", fullTitle: "PlaceholderString", getterString: "placeholderString", setterString: "setPlaceholderString:", objectValueType: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSPathControl.url, title: "URL", attributes: [
                BlueprintAttribute(.NSPathControl.URL.url, AttributeInfo(className: "NSPathControl", fullTitle: "URL", getterString: "URL", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.url))),
            ]),
            BlueprintSection(.NSPathControl.pathStyle, title: "PathStyle", attributes: [
                BlueprintAttribute(.NSPathControl.PathStyle.pathStyle, AttributeInfo(className: "NSPathControl", fullTitle: "PathStyle", getterString: "pathStyle", setterString: "setPathStyle:", enumList: "NSPathStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSPathControl.backgroundColor, title: "BackgroundColor", attributes: [
                BlueprintAttribute(.NSPathControl.BackgroundColor.backgroundColor, AttributeInfo(className: "NSPathControl", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSPathControl.menu, title: "Menu", attributes: [
                BlueprintAttribute(.NSPathControl.Menu.menu, AttributeInfo(className: "NSPathControl", fullTitle: "Menu", getterString: "menu", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.menu))),
            ]),
        ])


        static let nsRuleEditorGroup = BlueprintGroup(.nsRuleEditor, title: "NSRuleEditor", on: .appKit, sections: [
            BlueprintSection(.NSRuleEditor.nestingMode, title: "NestingMode", attributes: [
                BlueprintAttribute(.NSRuleEditor.NestingMode.nestingMode, AttributeInfo(className: "NSRuleEditor", fullTitle: "NestingMode", getterString: "nestingMode", setterString: "setNestingMode:", enumList: "NSRuleEditorNestingMode", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSRuleEditor.rowHeight, title: "RowHeight", attributes: [
                BlueprintAttribute(.NSRuleEditor.RowHeight.rowHeight, AttributeInfo(className: "NSRuleEditor", fullTitle: "RowHeight", getterString: "rowHeight", setterString: "setRowHeight:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSRuleEditor.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.NSRuleEditor.Behavior.editable, AttributeInfo(className: "NSRuleEditor", fullTitle: "Editable", getterString: "isEditable", setterString: "setEditable:", patch: true, revision: 1)),
                BlueprintAttribute(.NSRuleEditor.Behavior.canRemoveAllRows, AttributeInfo(className: "NSRuleEditor", fullTitle: "CanRemoveAllRows", getterString: "canRemoveAllRows", setterString: "setCanRemoveAllRows:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSRuleEditor.numberOfRows, title: "NumberOfRows", attributes: [
                BlueprintAttribute(.NSRuleEditor.NumberOfRows.numberOfRows, AttributeInfo(className: "NSRuleEditor", fullTitle: "NumberOfRows", getterString: "numberOfRows", setterString: "", revision: 1)),
            ]),
        ])


        static let nsSearchFieldGroup = BlueprintGroup(.nsSearchField, title: "NSSearchField", on: .appKit, sections: [
            BlueprintSection(.NSSearchField.searchTextBounds, title: "SearchTextBounds", attributes: [
                BlueprintAttribute(.NSSearchField.SearchTextBounds.searchTextBounds, AttributeInfo(className: "NSSearchField", fullTitle: "SearchTextBounds", getterString: "searchTextBounds", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSSearchField.searchButtonBounds, title: "SearchButtonBounds", attributes: [
                BlueprintAttribute(.NSSearchField.SearchButtonBounds.searchButtonBounds, AttributeInfo(className: "NSSearchField", fullTitle: "SearchButtonBounds", getterString: "searchButtonBounds", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSSearchField.cancelButtonBounds, title: "CancelButtonBounds", attributes: [
                BlueprintAttribute(.NSSearchField.CancelButtonBounds.cancelButtonBounds, AttributeInfo(className: "NSSearchField", fullTitle: "CancelButtonBounds", getterString: "cancelButtonBounds", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSSearchField.searchMenuTemplate, title: "SearchMenuTemplate", attributes: [
                BlueprintAttribute(.NSSearchField.SearchMenuTemplate.searchMenuTemplate, AttributeInfo(className: "NSSearchField", fullTitle: "SearchMenuTemplate", getterString: "searchMenuTemplate", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.menu))),
            ]),
            BlueprintSection(.NSSearchField.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.NSSearchField.Behavior.sendsWholeSearchString, AttributeInfo(className: "NSSearchField", fullTitle: "SendsWholeSearchString", getterString: "sendsWholeSearchString", setterString: "setSendsWholeSearchString:", patch: true, revision: 1)),
                BlueprintAttribute(.NSSearchField.Behavior.sendsSearchStringImmediately, AttributeInfo(className: "NSSearchField", fullTitle: "SendsSearchStringImmediately", getterString: "sendsSearchStringImmediately", setterString: "setSendsSearchStringImmediately:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSSearchField.maximumRecents, title: "MaximumRecents", attributes: [
                BlueprintAttribute(.NSSearchField.MaximumRecents.maximumRecents, AttributeInfo(className: "NSSearchField", fullTitle: "MaximumRecents", getterString: "maximumRecents", setterString: "setMaximumRecents:", patch: true, revision: 1)),
            ]),
        ])


        static let nsComboButtonGroup = BlueprintGroup(.nsComboButton, title: "NSComboButton", on: .appKit, sections: [
            BlueprintSection(.NSComboButton.title, title: "Title", attributes: [
                BlueprintAttribute(.NSComboButton.Title.title, AttributeInfo(className: "NSComboButton", fullTitle: "Title", getterString: "title", setterString: "setTitle:", objectValueType: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSComboButton.image, title: "Image", attributes: [
                BlueprintAttribute(.NSComboButton.Image.image, AttributeInfo(className: "NSComboButton", fullTitle: "Image", getterString: "image", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.image))),
            ]),
            BlueprintSection(.NSComboButton.imageScaling, title: "ImageScaling", attributes: [
                BlueprintAttribute(.NSComboButton.ImageScaling.imageScaling, AttributeInfo(className: "NSComboButton", fullTitle: "ImageScaling", getterString: "imageScaling", setterString: "setImageScaling:", enumList: "NSImageScaling", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSComboButton.menu, title: "Menu", attributes: [
                BlueprintAttribute(.NSComboButton.Menu.menu, AttributeInfo(className: "NSComboButton", fullTitle: "Menu", getterString: "menu", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.menu))),
            ]),
            BlueprintSection(.NSComboButton.style, title: "Style", attributes: [
                BlueprintAttribute(.NSComboButton.Style.style, AttributeInfo(className: "NSComboButton", fullTitle: "Style", getterString: "style", setterString: "setStyle:", enumList: "NSComboButtonStyle", patch: true, revision: 1)),
            ]),
        ])


        static let nsGlassEffectViewGroup = BlueprintGroup(.nsGlassEffectView, title: "NSGlassEffectView", on: .appKit, sections: [
            BlueprintSection(.NSGlassEffectView.cornerRadius, title: "CornerRadius", attributes: [
                BlueprintAttribute(.NSGlassEffectView.CornerRadius.cornerRadius, AttributeInfo(className: "NSGlassEffectView", fullTitle: "CornerRadius", getterString: "cornerRadius", setterString: "setCornerRadius:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSGlassEffectView.tintColor, title: "TintColor", attributes: [
                BlueprintAttribute(.NSGlassEffectView.TintColor.tintColor, AttributeInfo(className: "NSGlassEffectView", fullTitle: "TintColor", getterString: "tintColor", setterString: "setTintColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSGlassEffectView.style, title: "Style", attributes: [
                BlueprintAttribute(.NSGlassEffectView.Style.style, AttributeInfo(className: "NSGlassEffectView", fullTitle: "Style", getterString: "style", setterString: "setStyle:", enumList: "NSGlassEffectViewStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSGlassEffectView.effectIsInteractive, title: "EffectIsInteractive", attributes: [
                BlueprintAttribute(.NSGlassEffectView.EffectIsInteractive.effectIsInteractive, AttributeInfo(className: "NSGlassEffectView", fullTitle: "EffectIsInteractive", getterString: "effectIsInteractive", setterString: "setEffectIsInteractive:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSGlassEffectView.nsGlassEffectContainerView, title: "NSGlassEffectContainerView", attributes: [
                BlueprintAttribute(.NSGlassEffectView.NSGlassEffectContainerView.spacing, AttributeInfo(className: "NSGlassEffectContainerView", fullTitle: "Spacing", getterString: "spacing", setterString: "setSpacing:", patch: true, revision: 1)),
            ]),
        ])


        static let nsBackgroundExtensionViewGroup = BlueprintGroup(.nsBackgroundExtensionView, title: "NSBackgroundExtensionView", on: .appKit, sections: [
            BlueprintSection(.NSBackgroundExtensionView.automaticallyPlacesContentView, title: "AutomaticallyPlacesContentView", attributes: [
                BlueprintAttribute(.NSBackgroundExtensionView.AutomaticallyPlacesContentView.automaticallyPlacesContentView, AttributeInfo(className: "NSBackgroundExtensionView", fullTitle: "AutomaticallyPlacesContentView", getterString: "automaticallyPlacesContentView", setterString: "setAutomaticallyPlacesContentView:", patch: true, revision: 1)),
            ]),
        ])


        static let nsRulerViewGroup = BlueprintGroup(.nsRulerView, title: "NSRulerView", on: .appKit, sections: [
            BlueprintSection(.NSRulerView.orientation, title: "Orientation", attributes: [
                BlueprintAttribute(.NSRulerView.Orientation.orientation, AttributeInfo(className: "NSRulerView", fullTitle: "Orientation", getterString: "orientation", setterString: "setOrientation:", enumList: "NSRulerOrientation", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSRulerView.baselineLocation, title: "BaselineLocation", attributes: [
                BlueprintAttribute(.NSRulerView.BaselineLocation.baselineLocation, AttributeInfo(className: "NSRulerView", fullTitle: "BaselineLocation", getterString: "baselineLocation", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSRulerView.requiredThickness, title: "RequiredThickness", attributes: [
                BlueprintAttribute(.NSRulerView.RequiredThickness.requiredThickness, AttributeInfo(className: "NSRulerView", fullTitle: "RequiredThickness", getterString: "requiredThickness", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSRulerView.ruleThickness, title: "RuleThickness", attributes: [
                BlueprintAttribute(.NSRulerView.RuleThickness.ruleThickness, AttributeInfo(className: "NSRulerView", fullTitle: "RuleThickness", getterString: "ruleThickness", setterString: "setRuleThickness:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSRulerView.reservedThicknessForMarkers, title: "ReservedThicknessForMarkers", attributes: [
                BlueprintAttribute(.NSRulerView.ReservedThicknessForMarkers.reservedThicknessForMarkers, AttributeInfo(className: "NSRulerView", fullTitle: "ReservedThicknessForMarkers", getterString: "reservedThicknessForMarkers", setterString: "setReservedThicknessForMarkers:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSRulerView.reservedThicknessForAccessoryView, title: "ReservedThicknessForAccessoryView", attributes: [
                BlueprintAttribute(.NSRulerView.ReservedThicknessForAccessoryView.reservedThicknessForAccessoryView, AttributeInfo(className: "NSRulerView", fullTitle: "ReservedThicknessForAccessoryView", getterString: "reservedThicknessForAccessoryView", setterString: "setReservedThicknessForAccessoryView:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSRulerView.measurementUnits, title: "MeasurementUnits", attributes: [
                BlueprintAttribute(.NSRulerView.MeasurementUnits.measurementUnits, AttributeInfo(className: "NSRulerView", fullTitle: "MeasurementUnits", getterString: "measurementUnits", setterString: "", objectValueType: .nsString, revision: 1)),
            ]),
            BlueprintSection(.NSRulerView.originOffset, title: "OriginOffset", attributes: [
                BlueprintAttribute(.NSRulerView.OriginOffset.originOffset, AttributeInfo(className: "NSRulerView", fullTitle: "OriginOffset", getterString: "originOffset", setterString: "setOriginOffset:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSRulerView.flipped, title: "Flipped", attributes: [
                BlueprintAttribute(.NSRulerView.Flipped.flipped, AttributeInfo(className: "NSRulerView", fullTitle: "Flipped", getterString: "isFlipped", setterString: "", revision: 1)),
            ]),
        ])


        static let nsTableCellViewGroup = BlueprintGroup(.nsTableCellView, title: "NSTableCellView", on: .appKit, sections: [
            BlueprintSection(.NSTableCellView.backgroundStyle, title: "BackgroundStyle", attributes: [
                BlueprintAttribute(.NSTableCellView.BackgroundStyle.backgroundStyle, AttributeInfo(className: "NSTableCellView", fullTitle: "BackgroundStyle", getterString: "backgroundStyle", setterString: "setBackgroundStyle:", enumList: "NSBackgroundStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSTableCellView.rowSizeStyle, title: "RowSizeStyle", attributes: [
                BlueprintAttribute(.NSTableCellView.RowSizeStyle.rowSizeStyle, AttributeInfo(className: "NSTableCellView", fullTitle: "RowSizeStyle", getterString: "rowSizeStyle", setterString: "setRowSizeStyle:", enumList: "NSTableViewRowSizeStyle", patch: true, revision: 1)),
            ]),
        ])


        static let nsTableRowViewGroup = BlueprintGroup(.nsTableRowView, title: "NSTableRowView", on: .appKit, sections: [
            BlueprintSection(.NSTableRowView.selectionHighlightStyle, title: "SelectionHighlightStyle", attributes: [
                BlueprintAttribute(.NSTableRowView.SelectionHighlightStyle.selectionHighlightStyle, AttributeInfo(className: "NSTableRowView", fullTitle: "SelectionHighlightStyle", getterString: "selectionHighlightStyle", setterString: "setSelectionHighlightStyle:", enumList: "NSTableViewSelectionHighlightStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSTableRowView.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.NSTableRowView.Behavior.emphasized, AttributeInfo(className: "NSTableRowView", fullTitle: "Emphasized", getterString: "isEmphasized", setterString: "setEmphasized:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTableRowView.Behavior.groupRowStyle, AttributeInfo(className: "NSTableRowView", fullTitle: "GroupRowStyle", getterString: "isGroupRowStyle", setterString: "setGroupRowStyle:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTableRowView.Behavior.selected, AttributeInfo(className: "NSTableRowView", fullTitle: "Selected", getterString: "isSelected", setterString: "setSelected:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTableRowView.Behavior.previousRowSelected, AttributeInfo(className: "NSTableRowView", fullTitle: "PreviousRowSelected", getterString: "isPreviousRowSelected", setterString: "setPreviousRowSelected:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTableRowView.Behavior.nextRowSelected, AttributeInfo(className: "NSTableRowView", fullTitle: "NextRowSelected", getterString: "isNextRowSelected", setterString: "setNextRowSelected:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTableRowView.Behavior.floating, AttributeInfo(className: "NSTableRowView", fullTitle: "Floating", getterString: "isFloating", setterString: "setFloating:", patch: true, revision: 1)),
                BlueprintAttribute(.NSTableRowView.Behavior.targetForDropOperation, AttributeInfo(className: "NSTableRowView", fullTitle: "TargetForDropOperation", getterString: "isTargetForDropOperation", setterString: "setTargetForDropOperation:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSTableRowView.draggingDestinationFeedbackStyle, title: "DraggingDestinationFeedbackStyle", attributes: [
                BlueprintAttribute(.NSTableRowView.DraggingDestinationFeedbackStyle.draggingDestinationFeedbackStyle, AttributeInfo(className: "NSTableRowView", fullTitle: "DraggingDestinationFeedbackStyle", getterString: "draggingDestinationFeedbackStyle", setterString: "setDraggingDestinationFeedbackStyle:", enumList: "NSTableViewDraggingDestinationFeedbackStyle", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSTableRowView.indentationForDropOperation, title: "IndentationForDropOperation", attributes: [
                BlueprintAttribute(.NSTableRowView.IndentationForDropOperation.indentationForDropOperation, AttributeInfo(className: "NSTableRowView", fullTitle: "IndentationForDropOperation", getterString: "indentationForDropOperation", setterString: "setIndentationForDropOperation:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSTableRowView.interiorBackgroundStyle, title: "InteriorBackgroundStyle", attributes: [
                BlueprintAttribute(.NSTableRowView.InteriorBackgroundStyle.interiorBackgroundStyle, AttributeInfo(className: "NSTableRowView", fullTitle: "InteriorBackgroundStyle", getterString: "interiorBackgroundStyle", setterString: "", enumList: "NSBackgroundStyle", revision: 1)),
            ]),
            BlueprintSection(.NSTableRowView.backgroundColor, title: "BackgroundColor", attributes: [
                BlueprintAttribute(.NSTableRowView.BackgroundColor.backgroundColor, AttributeInfo(className: "NSTableRowView", fullTitle: "BackgroundColor", getterString: "backgroundColor", setterString: "setBackgroundColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSTableRowView.numberOfColumns, title: "NumberOfColumns", attributes: [
                BlueprintAttribute(.NSTableRowView.NumberOfColumns.numberOfColumns, AttributeInfo(className: "NSTableRowView", fullTitle: "NumberOfColumns", getterString: "numberOfColumns", setterString: "", revision: 1)),
            ]),
        ])


        static let nsTableHeaderViewGroup = BlueprintGroup(.nsTableHeaderView, title: "NSTableHeaderView", on: .appKit, sections: [
            BlueprintSection(.NSTableHeaderView.draggedColumn, title: "DraggedColumn", attributes: [
                BlueprintAttribute(.NSTableHeaderView.DraggedColumn.draggedColumn, AttributeInfo(className: "NSTableHeaderView", fullTitle: "DraggedColumn", getterString: "draggedColumn", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSTableHeaderView.draggedDistance, title: "DraggedDistance", attributes: [
                BlueprintAttribute(.NSTableHeaderView.DraggedDistance.draggedDistance, AttributeInfo(className: "NSTableHeaderView", fullTitle: "DraggedDistance", getterString: "draggedDistance", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSTableHeaderView.resizedColumn, title: "ResizedColumn", attributes: [
                BlueprintAttribute(.NSTableHeaderView.ResizedColumn.resizedColumn, AttributeInfo(className: "NSTableHeaderView", fullTitle: "ResizedColumn", getterString: "resizedColumn", setterString: "", revision: 1)),
            ]),
        ])


        static let nsTextInsertionIndicatorGroup = BlueprintGroup(.nsTextInsertionIndicator, title: "NSTextInsertionIndicator", on: .appKit, sections: [
            BlueprintSection(.NSTextInsertionIndicator.displayMode, title: "DisplayMode", attributes: [
                BlueprintAttribute(.NSTextInsertionIndicator.DisplayMode.displayMode, AttributeInfo(className: "NSTextInsertionIndicator", fullTitle: "DisplayMode", getterString: "displayMode", setterString: "setDisplayMode:", enumList: "NSTextInsertionIndicatorDisplayMode", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSTextInsertionIndicator.color, title: "Color", attributes: [
                BlueprintAttribute(.NSTextInsertionIndicator.Color.color, AttributeInfo(className: "NSTextInsertionIndicator", fullTitle: "Color", getterString: "color", setterString: "setColor:", objectValueType: .uiColor, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSTextInsertionIndicator.automaticModeOptions, title: "AutomaticModeOptions", attributes: [
                BlueprintAttribute(.NSTextInsertionIndicator.AutomaticModeOptions.automaticModeOptions, AttributeInfo(className: "NSTextInsertionIndicator", fullTitle: "AutomaticModeOptions", getterString: "automaticModeOptions", setterString: "", revision: 1, presentation: .optionNames("NSTextInsertionIndicatorAutomaticModeOptions"))),
            ]),
        ])

        static let nsViewGroup = BlueprintGroup(.nsView, title: "NSView", on: .appKit, sections: [
            BlueprintSection(.NSView.behavior, title: "Behavior", attributes: [
                BlueprintAttribute(.NSView.Behavior.needsUpdateConstraints, AttributeInfo(className: "NSView", fullTitle: "NeedsUpdateConstraints", getterString: "needsUpdateConstraints", setterString: "", revision: 1)),
                BlueprintAttribute(.NSView.Behavior.translatesAutoresizingMaskIntoConstraints, AttributeInfo(className: "NSView", fullTitle: "TranslatesAutoresizingMaskIntoConstraints", getterString: "translatesAutoresizingMaskIntoConstraints", setterString: "setTranslatesAutoresizingMaskIntoConstraints:", patch: true, revision: 1)),
                BlueprintAttribute(.NSView.Behavior.horizontalContentSizeConstraintActive, AttributeInfo(className: "NSView", fullTitle: "HorizontalContentSizeConstraintActive", getterString: "isHorizontalContentSizeConstraintActive", setterString: "setHorizontalContentSizeConstraintActive:", patch: true, revision: 1)),
                BlueprintAttribute(.NSView.Behavior.verticalContentSizeConstraintActive, AttributeInfo(className: "NSView", fullTitle: "VerticalContentSizeConstraintActive", getterString: "isVerticalContentSizeConstraintActive", setterString: "setVerticalContentSizeConstraintActive:", patch: true, revision: 1)),
                BlueprintAttribute(.NSView.Behavior.hiddenOrHasHiddenAncestor, AttributeInfo(className: "NSView", fullTitle: "HiddenOrHasHiddenAncestor", getterString: "isHiddenOrHasHiddenAncestor", setterString: "", revision: 1)),
                BlueprintAttribute(.NSView.Behavior.wantsDefaultClipping, AttributeInfo(className: "NSView", fullTitle: "WantsDefaultClipping", getterString: "wantsDefaultClipping", setterString: "", revision: 1)),
                BlueprintAttribute(.NSView.Behavior.postsFrameChangedNotifications, AttributeInfo(className: "NSView", fullTitle: "PostsFrameChangedNotifications", getterString: "postsFrameChangedNotifications", setterString: "setPostsFrameChangedNotifications:", patch: true, revision: 1)),
                BlueprintAttribute(.NSView.Behavior.autoresizesSubviews, AttributeInfo(className: "NSView", fullTitle: "AutoresizesSubviews", getterString: "autoresizesSubviews", setterString: "setAutoresizesSubviews:", patch: true, revision: 1)),
                BlueprintAttribute(.NSView.Behavior.flipped, AttributeInfo(className: "NSView", fullTitle: "Flipped", getterString: "isFlipped", setterString: "", revision: 1)),
                BlueprintAttribute(.NSView.Behavior.rotatedFromBase, AttributeInfo(className: "NSView", fullTitle: "RotatedFromBase", getterString: "isRotatedFromBase", setterString: "", revision: 1)),
                BlueprintAttribute(.NSView.Behavior.rotatedOrScaledFromBase, AttributeInfo(className: "NSView", fullTitle: "RotatedOrScaledFromBase", getterString: "isRotatedOrScaledFromBase", setterString: "", revision: 1)),
                BlueprintAttribute(.NSView.Behavior.opaque, AttributeInfo(className: "NSView", fullTitle: "Opaque", getterString: "isOpaque", setterString: "", revision: 1)),
                BlueprintAttribute(.NSView.Behavior.canDrawConcurrently, AttributeInfo(className: "NSView", fullTitle: "CanDrawConcurrently", getterString: "canDrawConcurrently", setterString: "setCanDrawConcurrently:", patch: true, revision: 1)),
                BlueprintAttribute(.NSView.Behavior.needsDisplay, AttributeInfo(className: "NSView", fullTitle: "NeedsDisplay", getterString: "needsDisplay", setterString: "", revision: 1)),
                BlueprintAttribute(.NSView.Behavior.needsPanelToBecomeKey, AttributeInfo(className: "NSView", fullTitle: "NeedsPanelToBecomeKey", getterString: "needsPanelToBecomeKey", setterString: "", revision: 1)),
                BlueprintAttribute(.NSView.Behavior.mouseDownCanMoveWindow, AttributeInfo(className: "NSView", fullTitle: "MouseDownCanMoveWindow", getterString: "mouseDownCanMoveWindow", setterString: "", revision: 1)),
                BlueprintAttribute(.NSView.Behavior.wantsRestingTouches, AttributeInfo(className: "NSView", fullTitle: "WantsRestingTouches", getterString: "wantsRestingTouches", setterString: "setWantsRestingTouches:", patch: true, revision: 1)),
                BlueprintAttribute(.NSView.Behavior.wantsLayer, AttributeInfo(className: "NSView", fullTitle: "WantsLayer", getterString: "wantsLayer", setterString: "setWantsLayer:", patch: true, revision: 1)),
                BlueprintAttribute(.NSView.Behavior.wantsUpdateLayer, AttributeInfo(className: "NSView", fullTitle: "WantsUpdateLayer", getterString: "wantsUpdateLayer", setterString: "", revision: 1)),
                BlueprintAttribute(.NSView.Behavior.canDrawSubviewsIntoLayer, AttributeInfo(className: "NSView", fullTitle: "CanDrawSubviewsIntoLayer", getterString: "canDrawSubviewsIntoLayer", setterString: "setCanDrawSubviewsIntoLayer:", patch: true, revision: 1)),
                BlueprintAttribute(.NSView.Behavior.needsLayout, AttributeInfo(className: "NSView", fullTitle: "NeedsLayout", getterString: "needsLayout", setterString: "", revision: 1)),
                BlueprintAttribute(.NSView.Behavior.layerUsesCoreImageFilters, AttributeInfo(className: "NSView", fullTitle: "LayerUsesCoreImageFilters", getterString: "layerUsesCoreImageFilters", setterString: "setLayerUsesCoreImageFilters:", patch: true, revision: 1)),
                BlueprintAttribute(.NSView.Behavior.clipsToBounds, AttributeInfo(className: "NSView", fullTitle: "ClipsToBounds", getterString: "clipsToBounds", setterString: "setClipsToBounds:", patch: true, revision: 1)),
                BlueprintAttribute(.NSView.Behavior.postsBoundsChangedNotifications, AttributeInfo(className: "NSView", fullTitle: "PostsBoundsChangedNotifications", getterString: "postsBoundsChangedNotifications", setterString: "setPostsBoundsChangedNotifications:", patch: true, revision: 1)),
                BlueprintAttribute(.NSView.Behavior.inLiveResize, AttributeInfo(className: "NSView", fullTitle: "InLiveResize", getterString: "inLiveResize", setterString: "", revision: 1)),
                BlueprintAttribute(.NSView.Behavior.preservesContentDuringLiveResize, AttributeInfo(className: "NSView", fullTitle: "PreservesContentDuringLiveResize", getterString: "preservesContentDuringLiveResize", setterString: "", revision: 1)),
                BlueprintAttribute(.NSView.Behavior.allowsVibrancy, AttributeInfo(className: "NSView", fullTitle: "AllowsVibrancy", getterString: "allowsVibrancy", setterString: "", revision: 1)),
                BlueprintAttribute(.NSView.Behavior.canBecomeKeyView, AttributeInfo(className: "NSView", fullTitle: "CanBecomeKeyView", getterString: "canBecomeKeyView", setterString: "", revision: 1)),
                BlueprintAttribute(.NSView.Behavior.inFullScreenMode, AttributeInfo(className: "NSView", fullTitle: "InFullScreenMode", getterString: "isInFullScreenMode", setterString: "", revision: 1)),
                BlueprintAttribute(.NSView.Behavior.prefersCompactControlSizeMetrics, AttributeInfo(className: "NSView", fullTitle: "PrefersCompactControlSizeMetrics", getterString: "prefersCompactControlSizeMetrics", setterString: "setPrefersCompactControlSizeMetrics:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSView.alignmentRectInsets, title: "AlignmentRectInsets", attributes: [
                BlueprintAttribute(.NSView.AlignmentRectInsets.alignmentRectInsets, AttributeInfo(className: "NSView", fullTitle: "AlignmentRectInsets", getterString: "alignmentRectInsets", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSView.autoresizingMask, title: "AutoresizingMask", attributes: [
                BlueprintAttribute(.NSView.AutoresizingMask.autoresizingMask, AttributeInfo(className: "NSView", fullTitle: "AutoresizingMask", getterString: "autoresizingMask", setterString: "", revision: 1, presentation: .optionNames("NSAutoresizingMaskOptions"))),
            ]),
            BlueprintSection(.NSView.frameRotation, title: "FrameRotation", attributes: [
                BlueprintAttribute(.NSView.FrameRotation.frameRotation, AttributeInfo(className: "NSView", fullTitle: "FrameRotation", getterString: "frameRotation", setterString: "setFrameRotation:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSView.frameCenterRotation, title: "FrameCenterRotation", attributes: [
                BlueprintAttribute(.NSView.FrameCenterRotation.frameCenterRotation, AttributeInfo(className: "NSView", fullTitle: "FrameCenterRotation", getterString: "frameCenterRotation", setterString: "setFrameCenterRotation:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSView.boundsRotation, title: "BoundsRotation", attributes: [
                BlueprintAttribute(.NSView.BoundsRotation.boundsRotation, AttributeInfo(className: "NSView", fullTitle: "BoundsRotation", getterString: "boundsRotation", setterString: "setBoundsRotation:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSView.visibleRect, title: "VisibleRect", attributes: [
                BlueprintAttribute(.NSView.VisibleRect.visibleRect, AttributeInfo(className: "NSView", fullTitle: "VisibleRect", getterString: "visibleRect", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSView.layerContentsRedrawPolicy, title: "LayerContentsRedrawPolicy", attributes: [
                BlueprintAttribute(.NSView.LayerContentsRedrawPolicy.layerContentsRedrawPolicy, AttributeInfo(className: "NSView", fullTitle: "LayerContentsRedrawPolicy", getterString: "layerContentsRedrawPolicy", setterString: "setLayerContentsRedrawPolicy:", enumList: "NSViewLayerContentsRedrawPolicy", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSView.layerContentsPlacement, title: "LayerContentsPlacement", attributes: [
                BlueprintAttribute(.NSView.LayerContentsPlacement.layerContentsPlacement, AttributeInfo(className: "NSView", fullTitle: "LayerContentsPlacement", getterString: "layerContentsPlacement", setterString: "setLayerContentsPlacement:", enumList: "NSViewLayerContentsPlacement", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSView.compositingFilter, title: "CompositingFilter", attributes: [
                BlueprintAttribute(.NSView.CompositingFilter.compositingFilter, AttributeInfo(className: "NSView", fullTitle: "CompositingFilter", getterString: "compositingFilter", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.className))),
            ]),
            BlueprintSection(.NSView.shadow, title: "Shadow", attributes: [
                BlueprintAttribute(.NSView.Shadow.shadow, AttributeInfo(className: "NSView", fullTitle: "Shadow", getterString: "shadow", setterString: "", hideIfNil: true, revision: 1, presentation: .summary(.shadow))),
            ]),
            BlueprintSection(.NSView.toolTip, title: "ToolTip", attributes: [
                BlueprintAttribute(.NSView.ToolTip.toolTip, AttributeInfo(className: "NSView", fullTitle: "ToolTip", getterString: "toolTip", setterString: "setToolTip:", objectValueType: .nsString, patch: true, hideIfNil: true, revision: 1)),
            ]),
            BlueprintSection(.NSView.userInterfaceLayoutDirection, title: "UserInterfaceLayoutDirection", attributes: [
                BlueprintAttribute(.NSView.UserInterfaceLayoutDirection.userInterfaceLayoutDirection, AttributeInfo(className: "NSView", fullTitle: "UserInterfaceLayoutDirection", getterString: "userInterfaceLayoutDirection", setterString: "setUserInterfaceLayoutDirection:", enumList: "NSUserInterfaceLayoutDirection", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSView.preparedContentRect, title: "PreparedContentRect", attributes: [
                BlueprintAttribute(.NSView.PreparedContentRect.preparedContentRect, AttributeInfo(className: "NSView", fullTitle: "PreparedContentRect", getterString: "preparedContentRect", setterString: "setPreparedContentRect:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSView.focusRingType, title: "FocusRingType", attributes: [
                BlueprintAttribute(.NSView.FocusRingType.focusRingType, AttributeInfo(className: "NSView", fullTitle: "FocusRingType", getterString: "focusRingType", setterString: "setFocusRingType:", enumList: "NSFocusRingType", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSView.focusRingMaskBounds, title: "FocusRingMaskBounds", attributes: [
                BlueprintAttribute(.NSView.FocusRingMaskBounds.focusRingMaskBounds, AttributeInfo(className: "NSView", fullTitle: "FocusRingMaskBounds", getterString: "focusRingMaskBounds", setterString: "", revision: 1)),
            ]),
            BlueprintSection(.NSView.exclusiveGestureBehavior, title: "ExclusiveGestureBehavior", attributes: [
                BlueprintAttribute(.NSView.ExclusiveGestureBehavior.exclusiveGestureBehavior, AttributeInfo(className: "NSView", fullTitle: "ExclusiveGestureBehavior", getterString: "exclusiveGestureBehavior", setterString: "setExclusiveGestureBehavior:", enumList: "NSViewExclusiveGestureBehavior", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSView.allowedTouchTypes, title: "AllowedTouchTypes", attributes: [
                BlueprintAttribute(.NSView.AllowedTouchTypes.allowedTouchTypes, AttributeInfo(className: "NSView", fullTitle: "AllowedTouchTypes", getterString: "allowedTouchTypes", setterString: "", revision: 1, presentation: .optionNames("NSTouchTypeMask"))),
            ]),
            BlueprintSection(.NSView.additionalSafeAreaInsets, title: "AdditionalSafeAreaInsets", attributes: [
                BlueprintAttribute(.NSView.AdditionalSafeAreaInsets.additionalSafeAreaInsets, AttributeInfo(className: "NSView", fullTitle: "AdditionalSafeAreaInsets", getterString: "additionalSafeAreaInsets", setterString: "setAdditionalSafeAreaInsets:", patch: true, revision: 1)),
            ]),
            BlueprintSection(.NSView.safeAreaRect, title: "SafeAreaRect", attributes: [
                BlueprintAttribute(.NSView.SafeAreaRect.safeAreaRect, AttributeInfo(className: "NSView", fullTitle: "SafeAreaRect", getterString: "safeAreaRect", setterString: "", revision: 1)),
            ]),
        ])
    }

#endif
