//
//  AttributeOptionNames.swift
//  LookinCore
//
//  The named values of the option sets `.optionNames` attributes show as
//  text, keyed by the option set's name. The monorepo's
//  Scripts/generate-enum-tables.py writes this file from the SDK headers;
//  do not edit it by hand.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation

    public extension AttributeOptionNames {
        static let tables: [String: [AttributeOptionName]] = [
            "NSLineBreakStrategy": [
                AttributeOptionName("none", 0x0),
                AttributeOptionName("pushOut", 0x1),
                AttributeOptionName("hangulWordPriority", 0x2),
                AttributeOptionName("standard", 0xFFFF),
            ],
            "UIControlEvents": [
                AttributeOptionName("touchDown", 0x1),
                AttributeOptionName("touchDownRepeat", 0x2),
                AttributeOptionName("touchDragInside", 0x4),
                AttributeOptionName("touchDragOutside", 0x8),
                AttributeOptionName("touchDragEnter", 0x10),
                AttributeOptionName("touchDragExit", 0x20),
                AttributeOptionName("touchUpInside", 0x40),
                AttributeOptionName("touchUpOutside", 0x80),
                AttributeOptionName("touchCancel", 0x100),
                AttributeOptionName("valueChanged", 0x1000),
                AttributeOptionName("primaryActionTriggered", 0x2000),
                AttributeOptionName("menuActionTriggered", 0x4000),
                AttributeOptionName("editingDidBegin", 0x10000),
                AttributeOptionName("editingChanged", 0x20000),
                AttributeOptionName("editingDidEnd", 0x40000),
                AttributeOptionName("editingDidEndOnExit", 0x80000),
                AttributeOptionName("allTouchEvents", 0xFFF),
                AttributeOptionName("allEditingEvents", 0xF0000),
                AttributeOptionName("applicationReserved", 0xF000000),
                AttributeOptionName("systemReserved", 0xF0000000),
                AttributeOptionName("allEvents", 0xFFFFFFFF),
            ],
            "UIControlState": [
                AttributeOptionName("normal", 0x0),
                AttributeOptionName("highlighted", 0x1),
                AttributeOptionName("disabled", 0x2),
                AttributeOptionName("selected", 0x4),
                AttributeOptionName("focused", 0x8),
                AttributeOptionName("application", 0xFF0000),
                AttributeOptionName("reserved", 0xFF000000),
            ],
            "UIDataDetectorTypes": [
                AttributeOptionName("phoneNumber", 0x1),
                AttributeOptionName("link", 0x2),
                AttributeOptionName("address", 0x4),
                AttributeOptionName("calendarEvent", 0x8),
                AttributeOptionName("shipmentTrackingNumber", 0x10),
                AttributeOptionName("flightNumber", 0x20),
                AttributeOptionName("lookupSuggestion", 0x40),
                AttributeOptionName("money", 0x80),
                AttributeOptionName("physicalValue", 0x100),
                AttributeOptionName("none", 0x0),
                AttributeOptionName("all", 0xFFFFFFFFFFFFFFFF),
            ],
            "UITableViewContentHuggingElements": [
                AttributeOptionName("none", 0x0),
                AttributeOptionName("sectionHeaders", 0x1),
            ],
            "UIViewAutoresizing": [
                AttributeOptionName("none", 0x0),
                AttributeOptionName("flexibleLeftMargin", 0x1),
                AttributeOptionName("flexibleWidth", 0x2),
                AttributeOptionName("flexibleRightMargin", 0x4),
                AttributeOptionName("flexibleTopMargin", 0x8),
                AttributeOptionName("flexibleHeight", 0x10),
                AttributeOptionName("flexibleBottomMargin", 0x20),
            ],
            "UIWritingToolsResultOptions": [
                AttributeOptionName("default", 0x0),
                AttributeOptionName("plainText", 0x1),
                AttributeOptionName("richText", 0x2),
                AttributeOptionName("list", 0x4),
                AttributeOptionName("table", 0x8),
                AttributeOptionName("presentationIntent", 0x10),
            ],
        ]
    }

#endif
