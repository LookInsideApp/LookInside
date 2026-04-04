# UITraitCollection Inspection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add comprehensive UITraitCollection inspection at both per-UIView (new group, 15 properties) and UIWindowScene (12 new properties) levels.

**Architecture:** Follows existing Blueprint pattern — declare identifiers, register group/section/attr relationships and metadata, add category getter methods, register enum lists. Two independent groups: `LookinAttrGroup_UITraitCollection` (className=UIView) and expanded `LookinAttrSec_UIWindowScene_Traits` (className=UIWindowScene). All properties read-only.

**Tech Stack:** Objective-C, UIKit, LookinServer Blueprint system

**Important:** This project has dual-copy architecture — `Sources/LookinCore/` (macOS client) and `Sources/LookinServer/Shared/` (server library) contain parallel copies of `LookinAttrIdentifiers.h/.m` and `LookinDashboardBlueprint.m`. Both copies must be kept in sync. The Core copy has additional entries (groupTitle, sectionTitle) that the Shared copy omits because the server doesn't display titles.

---

### Task 1: Add UITraitCollection identifiers to LookinCore

**Files:**
- Modify: `Sources/LookinCore/LookinAttrIdentifiers.h:63-64` (after `LookinAttrGroup_NSGridView`, before `LookinAttrGroup_UserCustom`)
- Modify: `Sources/LookinCore/LookinAttrIdentifiers.h:397-407` (section area, after NSGridView sections, before UIWindowScene sections)
- Modify: `Sources/LookinCore/LookinAttrIdentifiers.h:722-726` (attr area, after existing UIWindowScene traits, before Session)
- Modify: `Sources/LookinCore/LookinAttrIdentifiers.h:726-727` (add new UITraitCollection attrs after UIWindowScene section)
- Modify: `Sources/LookinCore/LookinAttrIdentifiers.m:628-654` (after NSWindow attrs, in UIWindowScene area)

- [ ] **Step 1: Add group, section, and attr extern declarations to `Sources/LookinCore/LookinAttrIdentifiers.h`**

After `extern LookinAttrGroupIdentifier const LookinAttrGroup_NSGridView;` (line 62) and before `extern LookinAttrGroupIdentifier const LookinAttrGroup_UserCustom;` (line 64), add:

```objc
// UITraitCollection
extern LookinAttrGroupIdentifier const LookinAttrGroup_UITraitCollection;
```

After `extern LookinAttrSectionIdentifier const LookinAttrSec_NSGridView_Placement;` (line 395) and before `// UIWindowScene` (line 397), add:

```objc
// UITraitCollection
extern LookinAttrSectionIdentifier const LookinAttrSec_UITraitCollection_Appearance;
extern LookinAttrSectionIdentifier const LookinAttrSec_UITraitCollection_SizeClass;
extern LookinAttrSectionIdentifier const LookinAttrSec_UITraitCollection_Display;
extern LookinAttrSectionIdentifier const LookinAttrSec_UITraitCollection_Device;
extern LookinAttrSectionIdentifier const LookinAttrSec_UITraitCollection_Layout;
extern LookinAttrSectionIdentifier const LookinAttrSec_UITraitCollection_Content;
```

After `extern LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_VerticalSizeClass;` (line 724), add 12 new UIWindowScene trait attrs:

```objc
extern LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_UserInterfaceLevel;
extern LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_ActiveAppearance;
extern LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_AccessibilityContrast;
extern LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_LegibilityWeight;
extern LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_DisplayScale;
extern LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_DisplayGamut;
extern LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_UserInterfaceIdiom;
extern LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_LayoutDirection;
extern LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_PreferredContentSizeCategory;
extern LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_SceneCaptureState;
extern LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_ImageDynamicRange;
extern LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_TypesettingLanguage;
```

After the UIWindowScene session attrs (after line 726), add UITraitCollection attrs:

```objc
// UITraitCollection
extern LookinAttrIdentifier const LookinAttr_UITraitCollection_Appearance_UserInterfaceStyle;
extern LookinAttrIdentifier const LookinAttr_UITraitCollection_Appearance_UserInterfaceLevel;
extern LookinAttrIdentifier const LookinAttr_UITraitCollection_Appearance_ActiveAppearance;
extern LookinAttrIdentifier const LookinAttr_UITraitCollection_Appearance_AccessibilityContrast;
extern LookinAttrIdentifier const LookinAttr_UITraitCollection_Appearance_LegibilityWeight;
extern LookinAttrIdentifier const LookinAttr_UITraitCollection_SizeClass_HorizontalSizeClass;
extern LookinAttrIdentifier const LookinAttr_UITraitCollection_SizeClass_VerticalSizeClass;
extern LookinAttrIdentifier const LookinAttr_UITraitCollection_Display_DisplayScale;
extern LookinAttrIdentifier const LookinAttr_UITraitCollection_Display_DisplayGamut;
extern LookinAttrIdentifier const LookinAttr_UITraitCollection_Display_ImageDynamicRange;
extern LookinAttrIdentifier const LookinAttr_UITraitCollection_Device_UserInterfaceIdiom;
extern LookinAttrIdentifier const LookinAttr_UITraitCollection_Device_ForceTouchCapability;
extern LookinAttrIdentifier const LookinAttr_UITraitCollection_Layout_LayoutDirection;
extern LookinAttrIdentifier const LookinAttr_UITraitCollection_Content_PreferredContentSizeCategory;
extern LookinAttrIdentifier const LookinAttr_UITraitCollection_Content_TypesettingLanguage;
```

- [ ] **Step 2: Add string value definitions to `Sources/LookinCore/LookinAttrIdentifiers.m`**

After the existing UIWindowScene Session attr definitions (after line 654, before `LookinAttrIdentifier const LookinAttr_NSSlider_SliderType_SliderType`), add:

```objc
// UIWindowScene additional traits
LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_UserInterfaceLevel = @"UIWindowScene_Traits_UserInterfaceLevel";
LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_ActiveAppearance = @"UIWindowScene_Traits_ActiveAppearance";
LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_AccessibilityContrast = @"UIWindowScene_Traits_AccessibilityContrast";
LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_LegibilityWeight = @"UIWindowScene_Traits_LegibilityWeight";
LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_DisplayScale = @"UIWindowScene_Traits_DisplayScale";
LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_DisplayGamut = @"UIWindowScene_Traits_DisplayGamut";
LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_UserInterfaceIdiom = @"UIWindowScene_Traits_UserInterfaceIdiom";
LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_LayoutDirection = @"UIWindowScene_Traits_LayoutDirection";
LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_PreferredContentSizeCategory = @"UIWindowScene_Traits_PreferredContentSizeCategory";
LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_SceneCaptureState = @"UIWindowScene_Traits_SceneCaptureState";
LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_ImageDynamicRange = @"UIWindowScene_Traits_ImageDynamicRange";
LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_TypesettingLanguage = @"UIWindowScene_Traits_TypesettingLanguage";

// UITraitCollection
LookinAttrGroupIdentifier const LookinAttrGroup_UITraitCollection = @"UITraitCollection";

LookinAttrSectionIdentifier const LookinAttrSec_UITraitCollection_Appearance = @"UITraitCollection_Appearance";
LookinAttrSectionIdentifier const LookinAttrSec_UITraitCollection_SizeClass = @"UITraitCollection_SizeClass";
LookinAttrSectionIdentifier const LookinAttrSec_UITraitCollection_Display = @"UITraitCollection_Display";
LookinAttrSectionIdentifier const LookinAttrSec_UITraitCollection_Device = @"UITraitCollection_Device";
LookinAttrSectionIdentifier const LookinAttrSec_UITraitCollection_Layout = @"UITraitCollection_Layout";
LookinAttrSectionIdentifier const LookinAttrSec_UITraitCollection_Content = @"UITraitCollection_Content";

LookinAttrIdentifier const LookinAttr_UITraitCollection_Appearance_UserInterfaceStyle = @"UITraitCollection_Appearance_UserInterfaceStyle";
LookinAttrIdentifier const LookinAttr_UITraitCollection_Appearance_UserInterfaceLevel = @"UITraitCollection_Appearance_UserInterfaceLevel";
LookinAttrIdentifier const LookinAttr_UITraitCollection_Appearance_ActiveAppearance = @"UITraitCollection_Appearance_ActiveAppearance";
LookinAttrIdentifier const LookinAttr_UITraitCollection_Appearance_AccessibilityContrast = @"UITraitCollection_Appearance_AccessibilityContrast";
LookinAttrIdentifier const LookinAttr_UITraitCollection_Appearance_LegibilityWeight = @"UITraitCollection_Appearance_LegibilityWeight";
LookinAttrIdentifier const LookinAttr_UITraitCollection_SizeClass_HorizontalSizeClass = @"UITraitCollection_SizeClass_HorizontalSizeClass";
LookinAttrIdentifier const LookinAttr_UITraitCollection_SizeClass_VerticalSizeClass = @"UITraitCollection_SizeClass_VerticalSizeClass";
LookinAttrIdentifier const LookinAttr_UITraitCollection_Display_DisplayScale = @"UITraitCollection_Display_DisplayScale";
LookinAttrIdentifier const LookinAttr_UITraitCollection_Display_DisplayGamut = @"UITraitCollection_Display_DisplayGamut";
LookinAttrIdentifier const LookinAttr_UITraitCollection_Display_ImageDynamicRange = @"UITraitCollection_Display_ImageDynamicRange";
LookinAttrIdentifier const LookinAttr_UITraitCollection_Device_UserInterfaceIdiom = @"UITraitCollection_Device_UserInterfaceIdiom";
LookinAttrIdentifier const LookinAttr_UITraitCollection_Device_ForceTouchCapability = @"UITraitCollection_Device_ForceTouchCapability";
LookinAttrIdentifier const LookinAttr_UITraitCollection_Layout_LayoutDirection = @"UITraitCollection_Layout_LayoutDirection";
LookinAttrIdentifier const LookinAttr_UITraitCollection_Content_PreferredContentSizeCategory = @"UITraitCollection_Content_PreferredContentSizeCategory";
LookinAttrIdentifier const LookinAttr_UITraitCollection_Content_TypesettingLanguage = @"UITraitCollection_Content_TypesettingLanguage";
```

- [ ] **Step 3: Commit**

```bash
git add Sources/LookinCore/LookinAttrIdentifiers.h Sources/LookinCore/LookinAttrIdentifiers.m
git commit -m "feat: add UITraitCollection identifier declarations (LookinCore)"
```

---

### Task 2: Sync identifiers to LookinServer/Shared

**Files:**
- Modify: `Sources/LookinServer/Shared/LookinAttrIdentifiers.h:591-594`
- Modify: `Sources/LookinServer/Shared/LookinAttrIdentifiers.m:575-579`

- [ ] **Step 1: Add the same extern declarations to `Sources/LookinServer/Shared/LookinAttrIdentifiers.h`**

The structure mirrors LookinCore. After `extern LookinAttrIdentifier const LookinAttr_UIWindowScene_Traits_VerticalSizeClass;` (line 591), add the same 12 UIWindowScene trait externs. After `extern LookinAttrIdentifier const LookinAttr_UIWindowScene_Session_SessionRole;` (line 593), add the UITraitCollection group/section/attr externs (same 1 group + 6 sections + 15 attrs as Task 1).

The exact code is identical to Task 1, Step 1.

- [ ] **Step 2: Add the same string value definitions to `Sources/LookinServer/Shared/LookinAttrIdentifiers.m`**

After `LookinAttrIdentifier const LookinAttr_UIWindowScene_Session_SessionRole` (line 577), add the same definitions as Task 1, Step 2.

The exact code is identical to Task 1, Step 2.

- [ ] **Step 3: Commit**

```bash
git add Sources/LookinServer/Shared/LookinAttrIdentifiers.h Sources/LookinServer/Shared/LookinAttrIdentifiers.m
git commit -m "feat: sync UITraitCollection identifiers to LookinServer/Shared"
```

---

### Task 3: Register UITraitCollection in LookinCore DashboardBlueprint

**Files:**
- Modify: `Sources/LookinCore/LookinDashboardBlueprint.m`

This file has four methods to update: `groupIDs`, `sectionIDsForGroupID:`, `attrIDsForSectionID:`, `groupTitleWithGroupID:`, `sectionTitleWithSectionID:`, and `_infoForAttrID:`.

- [ ] **Step 1: Add UITraitCollection to `groupIDs` method**

In the `groupIDs` method, after `LookinAttrGroup_UIWindowScene` (line 38) and before `#endif` (line 39), add:

```objc
            LookinAttrGroup_UITraitCollection,
```

Note: `LookinAttrGroup_UIWindowScene` currently does NOT have a trailing comma. Add a comma after it first, then add the new line.

- [ ] **Step 2: Add UITraitCollection to `sectionIDsForGroupID:` method**

In the `sectionIDsForGroupID:` dict, after the `LookinAttrGroup_UIWindowScene` entry (lines 176-185) and before `#endif` (line 186), add:

```objc
            LookinAttrGroup_UITraitCollection: @[
                LookinAttrSec_UITraitCollection_Appearance,
                LookinAttrSec_UITraitCollection_SizeClass,
                LookinAttrSec_UITraitCollection_Display,
                LookinAttrSec_UITraitCollection_Device,
                LookinAttrSec_UITraitCollection_Layout,
                LookinAttrSec_UITraitCollection_Content,
            ],
```

- [ ] **Step 3: Expand UIWindowScene Traits and add UITraitCollection to `attrIDsForSectionID:` method**

In the `attrIDsForSectionID:` dict, replace the existing `LookinAttrSec_UIWindowScene_Traits` entry (lines 610-614) with:

```objc
            LookinAttrSec_UIWindowScene_Traits: @[
                LookinAttr_UIWindowScene_Traits_UserInterfaceStyle,
                LookinAttr_UIWindowScene_Traits_HorizontalSizeClass,
                LookinAttr_UIWindowScene_Traits_VerticalSizeClass,
                LookinAttr_UIWindowScene_Traits_UserInterfaceLevel,
                LookinAttr_UIWindowScene_Traits_ActiveAppearance,
                LookinAttr_UIWindowScene_Traits_AccessibilityContrast,
                LookinAttr_UIWindowScene_Traits_LegibilityWeight,
                LookinAttr_UIWindowScene_Traits_DisplayScale,
                LookinAttr_UIWindowScene_Traits_DisplayGamut,
                LookinAttr_UIWindowScene_Traits_UserInterfaceIdiom,
                LookinAttr_UIWindowScene_Traits_LayoutDirection,
                LookinAttr_UIWindowScene_Traits_PreferredContentSizeCategory,
                LookinAttr_UIWindowScene_Traits_SceneCaptureState,
                LookinAttr_UIWindowScene_Traits_ImageDynamicRange,
                LookinAttr_UIWindowScene_Traits_TypesettingLanguage,
            ],
```

After the `LookinAttrSec_UIWindowScene_Session` entry (lines 615-618) and before `#endif` (line 619), add:

```objc
            // UITraitCollection
            LookinAttrSec_UITraitCollection_Appearance: @[
                LookinAttr_UITraitCollection_Appearance_UserInterfaceStyle,
                LookinAttr_UITraitCollection_Appearance_UserInterfaceLevel,
                LookinAttr_UITraitCollection_Appearance_ActiveAppearance,
                LookinAttr_UITraitCollection_Appearance_AccessibilityContrast,
                LookinAttr_UITraitCollection_Appearance_LegibilityWeight,
            ],
            LookinAttrSec_UITraitCollection_SizeClass: @[
                LookinAttr_UITraitCollection_SizeClass_HorizontalSizeClass,
                LookinAttr_UITraitCollection_SizeClass_VerticalSizeClass,
            ],
            LookinAttrSec_UITraitCollection_Display: @[
                LookinAttr_UITraitCollection_Display_DisplayScale,
                LookinAttr_UITraitCollection_Display_DisplayGamut,
                LookinAttr_UITraitCollection_Display_ImageDynamicRange,
            ],
            LookinAttrSec_UITraitCollection_Device: @[
                LookinAttr_UITraitCollection_Device_UserInterfaceIdiom,
                LookinAttr_UITraitCollection_Device_ForceTouchCapability,
            ],
            LookinAttrSec_UITraitCollection_Layout: @[
                LookinAttr_UITraitCollection_Layout_LayoutDirection,
            ],
            LookinAttrSec_UITraitCollection_Content: @[
                LookinAttr_UITraitCollection_Content_PreferredContentSizeCategory,
                LookinAttr_UITraitCollection_Content_TypesettingLanguage,
            ],
```

- [ ] **Step 4: Add group title for UITraitCollection in `groupTitleWithGroupID:` method**

In the `groupTitleWithGroupID:` dict, after `LookinAttrGroup_UIWindowScene: @"UIWindowScene",` (line 1222) add:

```objc
            LookinAttrGroup_UITraitCollection: @"UITraitCollection",
```

- [ ] **Step 5: Add section titles for UITraitCollection in `sectionTitleWithSectionID:` method**

In the `sectionTitleWithSectionID:` dict, after `LookinAttrSec_UIWindowScene_Session: @"Session",` (line 1473) add:

```objc
            // UITraitCollection
            LookinAttrSec_UITraitCollection_Appearance: @"Appearance",
            LookinAttrSec_UITraitCollection_SizeClass: @"SizeClass",
            LookinAttrSec_UITraitCollection_Display: @"Display",
            LookinAttrSec_UITraitCollection_Device: @"Device",
            LookinAttrSec_UITraitCollection_Layout: @"Layout",
            LookinAttrSec_UITraitCollection_Content: @"Content",
```

- [ ] **Step 6: Add attribute metadata in `_infoForAttrID:` method**

After the existing `LookinAttr_UIWindowScene_Traits_VerticalSizeClass` entry (ends at line 3278), add metadata for the 12 new UIWindowScene trait attrs:

```objc
            LookinAttr_UIWindowScene_Traits_UserInterfaceLevel: @{
                @"className": @"UIWindowScene",
                @"fullTitle": @"UserInterfaceLevel",
                @"getterString": @"lks_userInterfaceLevel",
                @"setterString": @"",
                @"enumList": @"UIUserInterfaceLevel",
                @"patch": @(NO),
                @"osVersion": @(13)
            },
            LookinAttr_UIWindowScene_Traits_ActiveAppearance: @{
                @"className": @"UIWindowScene",
                @"fullTitle": @"ActiveAppearance",
                @"getterString": @"lks_activeAppearance",
                @"setterString": @"",
                @"enumList": @"UIUserInterfaceActiveAppearance",
                @"patch": @(NO),
                @"osVersion": @(14)
            },
            LookinAttr_UIWindowScene_Traits_AccessibilityContrast: @{
                @"className": @"UIWindowScene",
                @"fullTitle": @"AccessibilityContrast",
                @"getterString": @"lks_accessibilityContrast",
                @"setterString": @"",
                @"enumList": @"UIAccessibilityContrast",
                @"patch": @(NO),
                @"osVersion": @(13)
            },
            LookinAttr_UIWindowScene_Traits_LegibilityWeight: @{
                @"className": @"UIWindowScene",
                @"fullTitle": @"LegibilityWeight",
                @"getterString": @"lks_legibilityWeight",
                @"setterString": @"",
                @"enumList": @"UILegibilityWeight",
                @"patch": @(NO),
                @"osVersion": @(13)
            },
            LookinAttr_UIWindowScene_Traits_DisplayScale: @{
                @"className": @"UIWindowScene",
                @"fullTitle": @"DisplayScale",
                @"getterString": @"lks_traitDisplayScale",
                @"setterString": @"",
                @"patch": @(NO),
                @"osVersion": @(13)
            },
            LookinAttr_UIWindowScene_Traits_DisplayGamut: @{
                @"className": @"UIWindowScene",
                @"fullTitle": @"DisplayGamut",
                @"getterString": @"lks_displayGamut",
                @"setterString": @"",
                @"enumList": @"UIDisplayGamut",
                @"patch": @(NO),
                @"osVersion": @(13)
            },
            LookinAttr_UIWindowScene_Traits_UserInterfaceIdiom: @{
                @"className": @"UIWindowScene",
                @"fullTitle": @"UserInterfaceIdiom",
                @"getterString": @"lks_userInterfaceIdiom",
                @"setterString": @"",
                @"enumList": @"UIUserInterfaceIdiom",
                @"patch": @(NO),
                @"osVersion": @(13)
            },
            LookinAttr_UIWindowScene_Traits_LayoutDirection: @{
                @"className": @"UIWindowScene",
                @"fullTitle": @"LayoutDirection",
                @"getterString": @"lks_layoutDirection",
                @"setterString": @"",
                @"enumList": @"UITraitEnvironmentLayoutDirection",
                @"patch": @(NO),
                @"osVersion": @(13)
            },
            LookinAttr_UIWindowScene_Traits_PreferredContentSizeCategory: @{
                @"className": @"UIWindowScene",
                @"fullTitle": @"PreferredContentSizeCategory",
                @"getterString": @"lks_preferredContentSizeCategory",
                @"setterString": @"",
                @"typeIfObj": @(LookinAttrTypeNSString),
                @"patch": @(NO),
                @"osVersion": @(13)
            },
            LookinAttr_UIWindowScene_Traits_SceneCaptureState: @{
                @"className": @"UIWindowScene",
                @"fullTitle": @"SceneCaptureState",
                @"getterString": @"lks_sceneCaptureState",
                @"setterString": @"",
                @"enumList": @"UISceneCaptureState",
                @"patch": @(NO),
                @"osVersion": @(17)
            },
            LookinAttr_UIWindowScene_Traits_ImageDynamicRange: @{
                @"className": @"UIWindowScene",
                @"fullTitle": @"ImageDynamicRange",
                @"getterString": @"lks_imageDynamicRange",
                @"setterString": @"",
                @"enumList": @"UIImageDynamicRange",
                @"patch": @(NO),
                @"osVersion": @(17)
            },
            LookinAttr_UIWindowScene_Traits_TypesettingLanguage: @{
                @"className": @"UIWindowScene",
                @"fullTitle": @"TypesettingLanguage",
                @"getterString": @"lks_typesettingLanguage",
                @"setterString": @"",
                @"typeIfObj": @(LookinAttrTypeNSString),
                @"hideIfNil": @(YES),
                @"patch": @(NO),
                @"osVersion": @(17)
            },
```

After the UIWindowScene Session metadata (after `LookinAttr_UIWindowScene_Session_SessionRole` entry, around line 3294), add metadata for UITraitCollection attrs:

```objc
            // MARK: - UITraitCollection
            LookinAttr_UITraitCollection_Appearance_UserInterfaceStyle: @{
                @"className": @"UIView",
                @"fullTitle": @"UserInterfaceStyle",
                @"getterString": @"lks_traitCollection_userInterfaceStyle",
                @"setterString": @"",
                @"enumList": @"UIUserInterfaceStyle",
                @"patch": @(NO),
                @"osVersion": @(12)
            },
            LookinAttr_UITraitCollection_Appearance_UserInterfaceLevel: @{
                @"className": @"UIView",
                @"fullTitle": @"UserInterfaceLevel",
                @"getterString": @"lks_traitCollection_userInterfaceLevel",
                @"setterString": @"",
                @"enumList": @"UIUserInterfaceLevel",
                @"patch": @(NO),
                @"osVersion": @(13)
            },
            LookinAttr_UITraitCollection_Appearance_ActiveAppearance: @{
                @"className": @"UIView",
                @"fullTitle": @"ActiveAppearance",
                @"getterString": @"lks_traitCollection_activeAppearance",
                @"setterString": @"",
                @"enumList": @"UIUserInterfaceActiveAppearance",
                @"patch": @(NO),
                @"osVersion": @(14)
            },
            LookinAttr_UITraitCollection_Appearance_AccessibilityContrast: @{
                @"className": @"UIView",
                @"fullTitle": @"AccessibilityContrast",
                @"getterString": @"lks_traitCollection_accessibilityContrast",
                @"setterString": @"",
                @"enumList": @"UIAccessibilityContrast",
                @"patch": @(NO),
                @"osVersion": @(13)
            },
            LookinAttr_UITraitCollection_Appearance_LegibilityWeight: @{
                @"className": @"UIView",
                @"fullTitle": @"LegibilityWeight",
                @"getterString": @"lks_traitCollection_legibilityWeight",
                @"setterString": @"",
                @"enumList": @"UILegibilityWeight",
                @"patch": @(NO),
                @"osVersion": @(13)
            },
            LookinAttr_UITraitCollection_SizeClass_HorizontalSizeClass: @{
                @"className": @"UIView",
                @"fullTitle": @"HorizontalSizeClass",
                @"getterString": @"lks_traitCollection_horizontalSizeClass",
                @"setterString": @"",
                @"enumList": @"UIUserInterfaceSizeClass",
                @"patch": @(NO)
            },
            LookinAttr_UITraitCollection_SizeClass_VerticalSizeClass: @{
                @"className": @"UIView",
                @"fullTitle": @"VerticalSizeClass",
                @"getterString": @"lks_traitCollection_verticalSizeClass",
                @"setterString": @"",
                @"enumList": @"UIUserInterfaceSizeClass",
                @"patch": @(NO)
            },
            LookinAttr_UITraitCollection_Display_DisplayScale: @{
                @"className": @"UIView",
                @"fullTitle": @"DisplayScale",
                @"getterString": @"lks_traitCollection_displayScale",
                @"setterString": @"",
                @"patch": @(NO)
            },
            LookinAttr_UITraitCollection_Display_DisplayGamut: @{
                @"className": @"UIView",
                @"fullTitle": @"DisplayGamut",
                @"getterString": @"lks_traitCollection_displayGamut",
                @"setterString": @"",
                @"enumList": @"UIDisplayGamut",
                @"patch": @(NO),
                @"osVersion": @(10)
            },
            LookinAttr_UITraitCollection_Display_ImageDynamicRange: @{
                @"className": @"UIView",
                @"fullTitle": @"ImageDynamicRange",
                @"getterString": @"lks_traitCollection_imageDynamicRange",
                @"setterString": @"",
                @"enumList": @"UIImageDynamicRange",
                @"patch": @(NO),
                @"osVersion": @(17)
            },
            LookinAttr_UITraitCollection_Device_UserInterfaceIdiom: @{
                @"className": @"UIView",
                @"fullTitle": @"UserInterfaceIdiom",
                @"getterString": @"lks_traitCollection_userInterfaceIdiom",
                @"setterString": @"",
                @"enumList": @"UIUserInterfaceIdiom",
                @"patch": @(NO)
            },
            LookinAttr_UITraitCollection_Device_ForceTouchCapability: @{
                @"className": @"UIView",
                @"fullTitle": @"ForceTouchCapability",
                @"getterString": @"lks_traitCollection_forceTouchCapability",
                @"setterString": @"",
                @"enumList": @"UIForceTouchCapability",
                @"patch": @(NO),
                @"osVersion": @(9)
            },
            LookinAttr_UITraitCollection_Layout_LayoutDirection: @{
                @"className": @"UIView",
                @"fullTitle": @"LayoutDirection",
                @"getterString": @"lks_traitCollection_layoutDirection",
                @"setterString": @"",
                @"enumList": @"UITraitEnvironmentLayoutDirection",
                @"patch": @(NO),
                @"osVersion": @(10)
            },
            LookinAttr_UITraitCollection_Content_PreferredContentSizeCategory: @{
                @"className": @"UIView",
                @"fullTitle": @"PreferredContentSizeCategory",
                @"getterString": @"lks_traitCollection_preferredContentSizeCategory",
                @"setterString": @"",
                @"typeIfObj": @(LookinAttrTypeNSString),
                @"patch": @(NO),
                @"osVersion": @(10)
            },
            LookinAttr_UITraitCollection_Content_TypesettingLanguage: @{
                @"className": @"UIView",
                @"fullTitle": @"TypesettingLanguage",
                @"getterString": @"lks_traitCollection_typesettingLanguage",
                @"setterString": @"",
                @"typeIfObj": @(LookinAttrTypeNSString),
                @"hideIfNil": @(YES),
                @"patch": @(NO),
                @"osVersion": @(17)
            },
```

- [ ] **Step 7: Commit**

```bash
git add Sources/LookinCore/LookinDashboardBlueprint.m
git commit -m "feat: register UITraitCollection group and expanded UIWindowScene traits in LookinCore blueprint"
```

---

### Task 4: Sync DashboardBlueprint to LookinServer/Shared

**Files:**
- Modify: `Sources/LookinServer/Shared/LookinDashboardBlueprint.m`

Apply the same changes as Task 3, with the following differences:
- The Shared copy does **not** have `groupTitleWithGroupID:` entries for UIWindowScene (those are only in the LookinCore copy which has all group titles without `#if` guards). The Shared copy uses `#if TARGET_OS_IPHONE` / `#else` guards for group titles. Add `LookinAttrGroup_UITraitCollection: @"UITraitCollection",` in the `#if TARGET_OS_IPHONE` block after `LookinAttrGroup_UIStackView: @"UIStackView",` (line 911).
- The Shared copy does **not** have UIWindowScene section titles (they are only in Core). Add them to the Shared copy in the `sectionTitleWithSectionID:` dict — but note the Shared copy ends its dict at line 1090 without UIWindowScene entries. Add the UITraitCollection section titles before the closing `};`.

- [ ] **Step 1: Add UITraitCollection to `groupIDs` method**

After `LookinAttrGroup_UIWindowScene` (line 38) and before `#endif` (line 39), add with trailing comma fix:

```objc
            LookinAttrGroup_UITraitCollection,
```

(Same fix: add comma after `LookinAttrGroup_UIWindowScene` first.)

- [ ] **Step 2: Add UITraitCollection to `sectionIDsForGroupID:` method**

After the `LookinAttrGroup_UIWindowScene` entry (lines 160-169) and before `#endif` (line 170), add (same code as Task 3 Step 2):

```objc
            LookinAttrGroup_UITraitCollection: @[
                LookinAttrSec_UITraitCollection_Appearance,
                LookinAttrSec_UITraitCollection_SizeClass,
                LookinAttrSec_UITraitCollection_Display,
                LookinAttrSec_UITraitCollection_Device,
                LookinAttrSec_UITraitCollection_Layout,
                LookinAttrSec_UITraitCollection_Content,
            ],
```

- [ ] **Step 3: Expand UIWindowScene Traits and add UITraitCollection to `attrIDsForSectionID:` method**

Same as Task 3 Step 3, but at the Shared copy's line numbers:
- Replace `LookinAttrSec_UIWindowScene_Traits` entry (lines 501-505) with the expanded 15-attr version
- After `LookinAttrSec_UIWindowScene_Session` entry (lines 506-509) and before `#endif` (line 510), add UITraitCollection section entries

- [ ] **Step 4: Add group title in `groupTitleWithGroupID:` method**

In the `#if TARGET_OS_IPHONE` block (after `LookinAttrGroup_UIStackView: @"UIStackView",` line 911), add:

```objc
            LookinAttrGroup_UIWindowScene: @"UIWindowScene",
            LookinAttrGroup_UITraitCollection: @"UITraitCollection",
```

Note: The Shared copy currently does NOT have `LookinAttrGroup_UIWindowScene` in its groupTitle dict. Add both.

- [ ] **Step 5: Add section titles in `sectionTitleWithSectionID:` method**

Before the closing `};` of the dict (line 1090), add:

```objc
            // UIWindowScene
            LookinAttrSec_UIWindowScene_State: @"State",
            LookinAttrSec_UIWindowScene_Title: @"Title",
            LookinAttrSec_UIWindowScene_Orientation: @"Orientation",
            LookinAttrSec_UIWindowScene_Windows: @"Windows",
            LookinAttrSec_UIWindowScene_Screen: @"Screen",
            LookinAttrSec_UIWindowScene_StatusBar: @"StatusBar",
            LookinAttrSec_UIWindowScene_Traits: @"Traits",
            LookinAttrSec_UIWindowScene_Session: @"Session",
            // UITraitCollection
            LookinAttrSec_UITraitCollection_Appearance: @"Appearance",
            LookinAttrSec_UITraitCollection_SizeClass: @"SizeClass",
            LookinAttrSec_UITraitCollection_Display: @"Display",
            LookinAttrSec_UITraitCollection_Device: @"Device",
            LookinAttrSec_UITraitCollection_Layout: @"Layout",
            LookinAttrSec_UITraitCollection_Content: @"Content",
```

- [ ] **Step 6: Add attribute metadata in `_infoForAttrID:` method**

Same as Task 3 Step 6, but at the Shared copy's line numbers. After the existing `LookinAttr_UIWindowScene_Traits_VerticalSizeClass` entry (around line 2212), add the 12 UIWindowScene trait metadata entries. After the Session entries (around line 2228), add the 15 UITraitCollection attribute metadata entries.

The code is identical to Task 3 Step 6.

- [ ] **Step 7: Commit**

```bash
git add Sources/LookinServer/Shared/LookinDashboardBlueprint.m
git commit -m "feat: sync UITraitCollection blueprint to LookinServer/Shared"
```

---

### Task 5: Add UIView category getter methods

**Files:**
- Modify: `Sources/LookinServer/Server/Category/UIView+LookinServer.h`
- Modify: `Sources/LookinServer/Server/Category/UIView+LookinServer.m`

- [ ] **Step 1: Add method declarations to `UIView+LookinServer.h`**

Before `@end` (line 46), inside the existing `#if defined(SHOULD_COMPILE_LOOKIN_SERVER)` guard, add:

```objc
#if TARGET_OS_IPHONE
// UITraitCollection getters
@property (nonatomic, readonly) NSInteger lks_traitCollection_userInterfaceStyle;
@property (nonatomic, readonly) NSInteger lks_traitCollection_userInterfaceLevel;
@property (nonatomic, readonly) NSInteger lks_traitCollection_activeAppearance;
@property (nonatomic, readonly) NSInteger lks_traitCollection_accessibilityContrast;
@property (nonatomic, readonly) NSInteger lks_traitCollection_legibilityWeight;
@property (nonatomic, readonly) NSInteger lks_traitCollection_horizontalSizeClass;
@property (nonatomic, readonly) NSInteger lks_traitCollection_verticalSizeClass;
@property (nonatomic, readonly) CGFloat lks_traitCollection_displayScale;
@property (nonatomic, readonly) NSInteger lks_traitCollection_displayGamut;
@property (nonatomic, readonly) NSInteger lks_traitCollection_imageDynamicRange;
@property (nonatomic, readonly) NSInteger lks_traitCollection_userInterfaceIdiom;
@property (nonatomic, readonly) NSInteger lks_traitCollection_forceTouchCapability;
@property (nonatomic, readonly) NSInteger lks_traitCollection_layoutDirection;
@property (nonatomic, readonly, nullable) NSString *lks_traitCollection_preferredContentSizeCategory;
@property (nonatomic, readonly, nullable) NSString *lks_traitCollection_typesettingLanguage;
#endif
```

- [ ] **Step 2: Add method implementations to `UIView+LookinServer.m`**

Before `@end` in the implementation, add inside a `#if TARGET_OS_IPHONE` guard:

```objc
#if TARGET_OS_IPHONE

// MARK: - UITraitCollection getters

- (NSInteger)lks_traitCollection_userInterfaceStyle {
    if (@available(iOS 12.0, *)) {
        return (NSInteger)self.traitCollection.userInterfaceStyle;
    }
    return 0;
}

- (NSInteger)lks_traitCollection_userInterfaceLevel {
    if (@available(iOS 13.0, *)) {
        return (NSInteger)self.traitCollection.userInterfaceLevel;
    }
    return -1;
}

- (NSInteger)lks_traitCollection_activeAppearance {
    if (@available(iOS 14.0, *)) {
        return (NSInteger)self.traitCollection.activeAppearance;
    }
    return -1;
}

- (NSInteger)lks_traitCollection_accessibilityContrast {
    if (@available(iOS 13.0, *)) {
        return (NSInteger)self.traitCollection.accessibilityContrast;
    }
    return -1;
}

- (NSInteger)lks_traitCollection_legibilityWeight {
    if (@available(iOS 13.0, *)) {
        return (NSInteger)self.traitCollection.legibilityWeight;
    }
    return -1;
}

- (NSInteger)lks_traitCollection_horizontalSizeClass {
    return (NSInteger)self.traitCollection.horizontalSizeClass;
}

- (NSInteger)lks_traitCollection_verticalSizeClass {
    return (NSInteger)self.traitCollection.verticalSizeClass;
}

- (CGFloat)lks_traitCollection_displayScale {
    return self.traitCollection.displayScale;
}

- (NSInteger)lks_traitCollection_displayGamut {
    if (@available(iOS 10.0, *)) {
        return (NSInteger)self.traitCollection.displayGamut;
    }
    return -1;
}

- (NSInteger)lks_traitCollection_imageDynamicRange {
    if (@available(iOS 17.0, *)) {
        return (NSInteger)self.traitCollection.imageDynamicRange;
    }
    return -1;
}

- (NSInteger)lks_traitCollection_userInterfaceIdiom {
    return (NSInteger)self.traitCollection.userInterfaceIdiom;
}

- (NSInteger)lks_traitCollection_forceTouchCapability {
    return (NSInteger)self.traitCollection.forceTouchCapability;
}

- (NSInteger)lks_traitCollection_layoutDirection {
    if (@available(iOS 10.0, *)) {
        return (NSInteger)self.traitCollection.layoutDirection;
    }
    return -1;
}

- (NSString *)lks_traitCollection_preferredContentSizeCategory {
    if (@available(iOS 10.0, *)) {
        return self.traitCollection.preferredContentSizeCategory;
    }
    return nil;
}

- (NSString *)lks_traitCollection_typesettingLanguage {
    if (@available(iOS 17.0, *)) {
        return self.traitCollection.typesettingLanguage;
    }
    return nil;
}

#endif
```

- [ ] **Step 3: Commit**

```bash
git add Sources/LookinServer/Server/Category/UIView+LookinServer.h Sources/LookinServer/Server/Category/UIView+LookinServer.m
git commit -m "feat: add UITraitCollection getter methods to UIView+LookinServer"
```

---

### Task 6: Add UIWindowScene category getter methods

**Files:**
- Modify: `Sources/LookinServer/Server/Category/UIWindowScene+LookinServer.h`
- Modify: `Sources/LookinServer/Server/Category/UIWindowScene+LookinServer.m`

- [ ] **Step 1: Add method declarations to `UIWindowScene+LookinServer.h`**

Before `@end` (line 35), add:

```objc
// Additional trait getters
@property (nonatomic, readonly) NSInteger lks_userInterfaceLevel;
@property (nonatomic, readonly) NSInteger lks_activeAppearance;
@property (nonatomic, readonly) NSInteger lks_accessibilityContrast;
@property (nonatomic, readonly) NSInteger lks_legibilityWeight;
@property (nonatomic, readonly) CGFloat lks_traitDisplayScale;
@property (nonatomic, readonly) NSInteger lks_displayGamut;
@property (nonatomic, readonly) NSInteger lks_userInterfaceIdiom;
@property (nonatomic, readonly) NSInteger lks_layoutDirection;
@property (nonatomic, readonly, nullable) NSString *lks_preferredContentSizeCategory;
@property (nonatomic, readonly) NSInteger lks_sceneCaptureState;
@property (nonatomic, readonly) NSInteger lks_imageDynamicRange;
@property (nonatomic, readonly, nullable) NSString *lks_typesettingLanguage;
```

Note: `lks_traitDisplayScale` instead of `lks_displayScale` to avoid collision with the existing `lks_screenScale` getter (which reads `screen.scale`, not `traitCollection.displayScale`).

- [ ] **Step 2: Add method implementations to `UIWindowScene+LookinServer.m`**

Before `@end` (line 91), add:

```objc
- (NSInteger)lks_userInterfaceLevel {
    return (NSInteger)self.traitCollection.userInterfaceLevel;
}

- (NSInteger)lks_activeAppearance {
    if (@available(iOS 14.0, *)) {
        return (NSInteger)self.traitCollection.activeAppearance;
    }
    return -1;
}

- (NSInteger)lks_accessibilityContrast {
    return (NSInteger)self.traitCollection.accessibilityContrast;
}

- (NSInteger)lks_legibilityWeight {
    return (NSInteger)self.traitCollection.legibilityWeight;
}

- (CGFloat)lks_traitDisplayScale {
    return self.traitCollection.displayScale;
}

- (NSInteger)lks_displayGamut {
    return (NSInteger)self.traitCollection.displayGamut;
}

- (NSInteger)lks_userInterfaceIdiom {
    return (NSInteger)self.traitCollection.userInterfaceIdiom;
}

- (NSInteger)lks_layoutDirection {
    return (NSInteger)self.traitCollection.layoutDirection;
}

- (NSString *)lks_preferredContentSizeCategory {
    return self.traitCollection.preferredContentSizeCategory;
}

- (NSInteger)lks_sceneCaptureState {
    if (@available(iOS 17.0, *)) {
        return (NSInteger)self.traitCollection.sceneCaptureState;
    }
    return -1;
}

- (NSInteger)lks_imageDynamicRange {
    if (@available(iOS 17.0, *)) {
        return (NSInteger)self.traitCollection.imageDynamicRange;
    }
    return -1;
}

- (NSString *)lks_typesettingLanguage {
    if (@available(iOS 17.0, *)) {
        return self.traitCollection.typesettingLanguage;
    }
    return nil;
}
```

Note: Many properties don't need `@available` here because `UIWindowScene` itself requires iOS 13, so `userInterfaceLevel`, `accessibilityContrast`, `legibilityWeight`, `displayGamut`, `layoutDirection`, `preferredContentSizeCategory` are all available.

- [ ] **Step 3: Commit**

```bash
git add Sources/LookinServer/Server/Category/UIWindowScene+LookinServer.h Sources/LookinServer/Server/Category/UIWindowScene+LookinServer.m
git commit -m "feat: add additional trait getter methods to UIWindowScene+LookinServer"
```

---

### Task 7: Add enum lists to LKEnumListRegistry

**Files:**
- Modify: `LookInside/Dashboard/LKEnumListRegistry.m`

- [ ] **Step 1: Add 10 new enum tables**

After the existing `// MARK: - UIWindowScene` section (after `mData[@"UIUserInterfaceSizeClass"]` entry, around line 471), add:

```objc
        // MARK: - UITraitCollection
        mData[@"UIUserInterfaceIdiom"] = @[
            MakeItem(@"UIUserInterfaceIdiomUnspecified", -1),
            MakeItem(@"UIUserInterfaceIdiomPhone", 0),
            MakeItem(@"UIUserInterfaceIdiomPad", 1),
            MakeItem(@"UIUserInterfaceIdiomTV", 2),
            MakeItem(@"UIUserInterfaceIdiomCarPlay", 3),
            MakeItemWithVersion(@"UIUserInterfaceIdiomMac", 5, 14),
            MakeItemWithVersion(@"UIUserInterfaceIdiomVision", 6, 17),
        ];
        mData[@"UIUserInterfaceLevel"] = @[
            MakeItem(@"UIUserInterfaceLevelUnspecified", -1),
            MakeItem(@"UIUserInterfaceLevelBase", 0),
            MakeItem(@"UIUserInterfaceLevelElevated", 1),
        ];
        mData[@"UIUserInterfaceActiveAppearance"] = @[
            MakeItem(@"UIUserInterfaceActiveAppearanceUnspecified", -1),
            MakeItem(@"UIUserInterfaceActiveAppearanceInactive", 0),
            MakeItem(@"UIUserInterfaceActiveAppearanceActive", 1),
        ];
        mData[@"UIAccessibilityContrast"] = @[
            MakeItem(@"UIAccessibilityContrastUnspecified", -1),
            MakeItem(@"UIAccessibilityContrastNormal", 0),
            MakeItem(@"UIAccessibilityContrastHigh", 1),
        ];
        mData[@"UILegibilityWeight"] = @[
            MakeItem(@"UILegibilityWeightUnspecified", -1),
            MakeItem(@"UILegibilityWeightRegular", 0),
            MakeItem(@"UILegibilityWeightBold", 1),
        ];
        mData[@"UIForceTouchCapability"] = @[
            MakeItem(@"UIForceTouchCapabilityUnknown", 0),
            MakeItem(@"UIForceTouchCapabilityUnavailable", 1),
            MakeItem(@"UIForceTouchCapabilityAvailable", 2),
        ];
        mData[@"UIDisplayGamut"] = @[
            MakeItem(@"UIDisplayGamutUnspecified", -1),
            MakeItem(@"UIDisplayGamutSRGB", 0),
            MakeItem(@"UIDisplayGamutP3", 1),
        ];
        mData[@"UITraitEnvironmentLayoutDirection"] = @[
            MakeItem(@"UITraitEnvironmentLayoutDirectionUnspecified", -1),
            MakeItem(@"UITraitEnvironmentLayoutDirectionLeftToRight", 0),
            MakeItem(@"UITraitEnvironmentLayoutDirectionRightToLeft", 1),
        ];
        mData[@"UIImageDynamicRange"] = @[
            MakeItem(@"UIImageDynamicRangeUnspecified", -1),
            MakeItem(@"UIImageDynamicRangeStandard", 0),
            MakeItem(@"UIImageDynamicRangeConstrainedHigh", 1),
            MakeItem(@"UIImageDynamicRangeHigh", 2),
        ];
        mData[@"UISceneCaptureState"] = @[
            MakeItem(@"UISceneCaptureStateUnspecified", -1),
            MakeItem(@"UISceneCaptureStateInactive", 0),
            MakeItem(@"UISceneCaptureStateActive", 1),
        ];
```

- [ ] **Step 2: Commit**

```bash
git add LookInside/Dashboard/LKEnumListRegistry.m
git commit -m "feat: add UITraitCollection enum lists to LKEnumListRegistry"
```

---

### Task 8: Register UITraitCollection sections in LKPreferenceManager

**Files:**
- Modify: `LookInside/Manager/LKPreferenceManager.m:596-605`

- [ ] **Step 1: Add UITraitCollection section identifiers to the preference tracking set**

After the UIWindowScene section entries (after `LookinAttrSec_UIWindowScene_Session,` line 604, before the closing `];` on line 606), add:

```objc
                                                        // UITraitCollection
                                                        LookinAttrSec_UITraitCollection_Appearance,
                                                        LookinAttrSec_UITraitCollection_SizeClass,
                                                        LookinAttrSec_UITraitCollection_Display,
                                                        LookinAttrSec_UITraitCollection_Device,
                                                        LookinAttrSec_UITraitCollection_Layout,
                                                        LookinAttrSec_UITraitCollection_Content,
```

- [ ] **Step 2: Commit**

```bash
git add LookInside/Manager/LKPreferenceManager.m
git commit -m "feat: register UITraitCollection sections in LKPreferenceManager"
```

---

### Task 9: Add UITraitCollection group icon mapping

**Files:**
- Modify: `LookInside/Dashboard/LKDashboardCardView.m` (if icon mapping exists for groups)

- [ ] **Step 1: Check if icon mapping is needed**

Search `LKDashboardCardView.m` for the existing `UIWindowScene` icon mapping pattern. If a dictionary maps group identifiers to icons (like SF Symbols or image names), add an entry for `LookinAttrGroup_UITraitCollection`. If no icon mapping exists, skip this step.

A reasonable icon would be `@"paintbrush"` or `@"slider.horizontal.3"` (SF Symbols representing appearance/traits).

- [ ] **Step 2: Commit (if changes were made)**

```bash
git add LookInside/Dashboard/LKDashboardCardView.m
git commit -m "feat: add UITraitCollection dashboard card icon"
```

---

### Task 10: Build verification

- [ ] **Step 1: Build the LookinServer target for iOS Simulator**

Use XcodeBuildMCP or xcodebuild to build the server library for iOS Simulator and verify no compilation errors:

```bash
xcodebuild -project LookInside.xcodeproj -scheme LookinServer -destination 'generic/platform=iOS Simulator' build 2>&1 | xcsift
```

- [ ] **Step 2: Build the LookInside macOS client**

```bash
xcodebuild -project LookInside.xcodeproj -scheme LookInside build 2>&1 | xcsift
```

- [ ] **Step 3: Fix any compilation errors and commit fixes**

If there are errors, fix them and commit:

```bash
git add -A
git commit -m "fix: resolve UITraitCollection build errors"
```
