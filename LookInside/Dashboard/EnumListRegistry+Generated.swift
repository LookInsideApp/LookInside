//
//  EnumListRegistry+Generated.swift
//  LookInside
//
//  The enum lists the Dashboard needs beyond the hand-written ones in
//  EnumListRegistry.swift, read from the SDK headers by the monorepo's
//  Scripts/generate-enum-tables.py. Do not edit; rerun the script after
//  adding an attribute with a new enum list.
//

import Foundation

extension EnumListRegistry {
    static func addGeneratedLists(to data: inout [String: [EnumListRegistryKeyValueItem]]) {
        data["UIActivityIndicatorViewStyle"] = [
            item("UIActivityIndicatorViewStyleMedium", 100, 13),
            item("UIActivityIndicatorViewStyleLarge", 101, 13),
            item("UIActivityIndicatorViewStyleWhiteLarge", 0, 2),
            item("UIActivityIndicatorViewStyleWhite", 1, 2),
            item("UIActivityIndicatorViewStyleGray", 2, 2),
        ]

        data["UIBehavioralStyle"] = [
            item("UIBehavioralStyleAutomatic", 0),
            item("UIBehavioralStylePad", 1),
            item("UIBehavioralStyleMac", 2),
        ]

        data["UIDatePickerMode"] = [
            item("UIDatePickerModeTime", 0),
            item("UIDatePickerModeDate", 1),
            item("UIDatePickerModeDateAndTime", 2),
            item("UIDatePickerModeCountDownTimer", 3),
            item("UIDatePickerModeYearAndMonth", 4, 17),
        ]

        data["UIDatePickerStyle"] = [
            item("UIDatePickerStyleAutomatic", 0),
            item("UIDatePickerStyleWheels", 1),
            item("UIDatePickerStyleCompact", 2),
            item("UIDatePickerStyleInline", 3, 14),
        ]

        data["UIPageControlBackgroundStyle"] = [
            item("UIPageControlBackgroundStyleAutomatic", 0),
            item("UIPageControlBackgroundStyleProminent", 1),
            item("UIPageControlBackgroundStyleMinimal", 2),
        ]

        data["UIPageControlDirection"] = [
            item("UIPageControlDirectionNatural", 0),
            item("UIPageControlDirectionLeftToRight", 1),
            item("UIPageControlDirectionRightToLeft", 2),
            item("UIPageControlDirectionTopToBottom", 3),
            item("UIPageControlDirectionBottomToTop", 4),
        ]

        data["UIPageControlInteractionState"] = [
            item("UIPageControlInteractionStateNone", 0),
            item("UIPageControlInteractionStateDiscrete", 1),
            item("UIPageControlInteractionStateContinuous", 2),
        ]

        data["UIProgressViewStyle"] = [
            item("UIProgressViewStyleDefault", 0),
            item("UIProgressViewStyleBar", 1),
        ]

        data["UISliderStyle"] = [
            item("UISliderStyleDefault", 0),
            item("UISliderStyleThumbless", 1),
        ]

        data["UISwitchStyle"] = [
            item("UISwitchStyleAutomatic", 0),
            item("UISwitchStyleCheckbox", 1),
            item("UISwitchStyleSliding", 2),
        ]
    }
}
