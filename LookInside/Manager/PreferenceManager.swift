//
//  PreferenceManager.swift
//  LookInside
//
//  Created by Li Kai on 2019/1/8.
//  https://lookin.work
//
//  The user's preferences. `mainManager` stores them in the standard user
//  defaults under the original keys; other instances (the reader windows)
//  start from the stored values and keep their changes in memory.
//
//  Properties are KVO-observable; the MessageAttribute ones notify their
//  subscribers instead.
//

import AppKit
import LookInsideHostCore

let LKWindowSizeName_Dynamic = "LKWindowSizeName_Dynamic"
let LKWindowSizeName_Static = "LKWindowSizeName_Static"

/// The initial preview scale.
let LKInitialPreviewScale: CGFloat = 0.27

/// The default hierarchy request timeout, in seconds.
let LKDefaultHierarchyRequestTimeoutInterval: TimeInterval = 15
let LKDefaultLicenseHandshakeTimeoutInterval: TimeInterval = 5

/// Posted when a dashboard section is added or removed.
let NotificationName_DidChangeSectionShowing = "NotificationName_DidChangeSectionShowing"

// The raw values of these enums are stored in the user defaults; never
// reorder the cases.

@objc enum PreferredAppearanceType: Int {
    case dark
    case light
    case system
}

@objc enum DoubleClickBehavior: Int {
    case collapse
    case focus
}

@objc enum PreferredCallStackType: Int {
    /// Formatted and shortened.
    case `default`
    /// Formatted, complete.
    case formattedCompletely
    /// The raw call stack.
    case raw
}

@objc enum MeasureState: Int {
    /// Not measuring.
    case no
    /// Measuring until the key is released.
    case unlocked
    /// Measuring until the user turns it off.
    case locked
}

@objc(LKPreferenceManager)
final class PreferenceManager: NSObject {
    /// User-defaults keys. Never rename: they hold existing users' settings.
    private enum Key {
        static let previousClientVersion = "preVer"
        static let showOutline = "showOutline"
        static let showHiddenItems = "showHiddenItems"
        static let showSystemLayoutGuides = "showSystemLayoutGuides"
        static let showBackingLayers = "showBackingLayers"
        static let rgbaFormat = "egbaFormat"
        static let zInterspace = "zInterspace_v095"
        static let appearanceType = "appearanceType"
        static let doubleClickBehavior = "doubleClickBehavior"
        static let expansionIndex = "expansionIndex"
        static let contrastLevel = "contrastLevel"
        static let sectionsShow = "ss"
        static let collapsedGroups = "collapsedGroups_918"
        static let preferredExportCompression = "preferredExportCompression"
        static let hierarchyRequestTimeoutInterval = "hierarchyRequestTimeoutInterval"
        static let licenseHandshakeTimeoutInterval = "licenseHandshakeTimeoutInterval"
        static let syncConsoleTarget = "syncConsoleTarget"
        static let freeRotation = "FreeRotation"
        static let fastMode = "fastMode"
        static let receivingConfigTimeColor = "ConfigTime_Color"
        static let receivingConfigTimeClass = "ConfigTime_Class"
        static let rememberExpansionState = "rememberExpansionState"
    }

    static let shared: PreferenceManager = {
        let manager = PreferenceManager()
        manager.shouldStoreToLocal = true
        return manager
    }()

    private var defaults: UserDefaults {
        .standard
    }

    /// 默认为 NO
    @objc var shouldStoreToLocal = false

    @objc dynamic var appearanceType: PreferredAppearanceType {
        didSet {
            guard oldValue != appearanceType else { return }
            store(appearanceType.rawValue, forKey: Key.appearanceType)
        }
    }

    @objc dynamic var doubleClickBehavior: DoubleClickBehavior {
        didSet {
            store(doubleClickBehavior.rawValue, forKey: Key.doubleClickBehavior)
        }
    }

    /// 有效值为 0 ～ 4
    @objc dynamic var expansionIndex: Int {
        didSet {
            guard oldValue != expansionIndex else { return }
            store(expansionIndex, forKey: Key.expansionIndex)
        }
    }

    /// Not stored: the subscription in the Objective-C version targeted
    /// `showHiddenItems` before it existed, so changes were never written.
    @objc let showOutline: BoolMessageAttribute

    @objc let showHiddenItems: BoolMessageAttribute

    /// 是否在层级树里显示系统自动创建的 LayoutGuide（safe area、layout margins 等）。
    /// 默认显示；关闭只是宿主端过滤，数据仍在。用户自建 guide 不受此开关影响。
    @objc let showSystemLayoutGuides: BoolMessageAttribute

    /// 是否显示 view 的 backing layer 子树（backing-layer-toggle 提案）。
    /// 默认关闭。开启后像 Xcode 的 Show Layers：每个 view 节点下展开完整 layer 子树，
    /// 内容显示在真正渲染它的 layer 上，view 节点变为线框。切换时重新拉取层级。
    @objc let showBackingLayers: BoolMessageAttribute

    /// 范围是 0 ～ 1
    @objc let zInterspace: DoubleMessageAttribute

    @objc dynamic var rgbaFormat: Bool {
        didSet {
            guard oldValue != rgbaFormat else { return }
            store(rgbaFormat, forKey: Key.rgbaFormat)
        }
    }

    /// 0 ~ 2
    @objc dynamic var imageContrastLevel: Int {
        didSet {
            guard oldValue != imageContrastLevel else { return }
            store(imageContrastLevel, forKey: Key.contrastLevel)
        }
    }

    /// 是否自动将选中的 UIView/CALayer 作为控制台的目标对象
    @objc dynamic var syncConsoleTarget: Bool {
        didSet {
            guard oldValue != syncConsoleTarget else { return }
            store(syncConsoleTarget, forKey: Key.syncConsoleTarget)
        }
    }

    /// 是否按目标 App bundle id 持久化层级折叠状态。默认 YES。
    /// 关闭后已存储的折叠状态保留在磁盘上，仅停止读取和写入。
    @objc dynamic var rememberExpansionState: Bool {
        didSet {
            guard oldValue != rememberExpansionState else { return }
            store(rememberExpansionState, forKey: Key.rememberExpansionState)
        }
    }

    /// 被折叠的 AttrGroup
    @objc dynamic var collapsedAttrGroups: [String] {
        didSet {
            store(collapsedAttrGroups, forKey: Key.collapsedGroups)
        }
    }

    @objc dynamic var preferredExportCompression: CGFloat {
        didSet {
            guard oldValue != preferredExportCompression else { return }
            store(Double(preferredExportCompression), forKey: Key.preferredExportCompression)
        }
    }

    private var storedHierarchyRequestTimeoutInterval: TimeInterval

    /// A value of 0 or less resets to the default.
    @objc dynamic var hierarchyRequestTimeoutInterval: TimeInterval {
        get { storedHierarchyRequestTimeoutInterval }
        set {
            let value = newValue <= 0 ? LKDefaultHierarchyRequestTimeoutInterval : newValue
            guard storedHierarchyRequestTimeoutInterval != value else { return }
            storedHierarchyRequestTimeoutInterval = value
            store(value, forKey: Key.hierarchyRequestTimeoutInterval)
        }
    }

    private var storedLicenseHandshakeTimeoutInterval: TimeInterval

    /// A value of 0 or less resets to the default.
    @objc dynamic var licenseHandshakeTimeoutInterval: TimeInterval {
        get { storedLicenseHandshakeTimeoutInterval }
        set {
            let value = newValue <= 0 ? LKDefaultLicenseHandshakeTimeoutInterval : newValue
            guard storedLicenseHandshakeTimeoutInterval != value else { return }
            storedLicenseHandshakeTimeoutInterval = value
            store(value, forKey: Key.licenseHandshakeTimeoutInterval)
        }
    }

    @objc let freeRotation: BoolMessageAttribute

    @objc let fastMode: BoolMessageAttribute

    /// 上次接收到 iOS app 里传过来的 color config 和 collapsedClasses 信息的时间，用来统计
    /// Always stored, even when `shouldStoreToLocal` is off.
    @objc dynamic var receivingConfigTime_Color: TimeInterval {
        didSet {
            defaults.set(receivingConfigTime_Color, forKey: Key.receivingConfigTimeColor)
        }
    }

    @objc dynamic var receivingConfigTime_Class: TimeInterval {
        didSet {
            defaults.set(receivingConfigTime_Class, forKey: Key.receivingConfigTimeClass)
        }
    }

    private var storedSectionShowConfig: [String: Bool]

    // MARK: - Not stored

    private var storedCallStackType: PreferredCallStackType = .default

    @objc dynamic var callStackType: PreferredCallStackType {
        get { storedCallStackType }
        set {
            if newValue.rawValue < 0 || newValue.rawValue > 2 {
                assertionFailure("callStackType out of range: \(newValue.rawValue)")
                storedCallStackType = .default
            } else {
                storedCallStackType = newValue
            }
        }
    }

    /// 参数是 PreviewDimension
    @objc let previewDimension: IntegerMessageAttribute

    @objc let previewScale: DoubleMessageAttribute

    /// 参数是 MeasureState
    @objc let measureState: IntegerMessageAttribute

    /// 是否用户正在按住 cmd 键而处于快速选择模式
    @objc let isQuickSelecting: BoolMessageAttribute

    // MARK: - Init

    /// Reads every stored value; a missing one is set to its default and
    /// written back, as before.
    override init() {
        let defaults = UserDefaults.standard

        previewScale = DoubleMessageAttribute(double: Double(LKInitialPreviewScale))
        previewDimension = IntegerMessageAttribute(integer: Int(PreviewDimension.dimension3D.rawValue))
        measureState = IntegerMessageAttribute(integer: MeasureState.no.rawValue)
        isQuickSelecting = BoolMessageAttribute(bool: false)

        if defaults.integer(forKey: Key.previousClientVersion) != Int(LOOKIN_CLIENT_VERSION) {
            defaults.set(Int(LOOKIN_CLIENT_VERSION), forKey: Key.previousClientVersion)
        }

        // The stored number for `key`, or `fallback` written back.
        func number(_ key: String, default fallback: NSNumber) -> NSNumber {
            if let stored = Self.storedNumber(defaults.object(forKey: key)) {
                return stored
            }
            defaults.set(fallback, forKey: key)
            return fallback
        }

        showOutline = BoolMessageAttribute(bool: number(Key.showOutline, default: true).boolValue)
        showHiddenItems = BoolMessageAttribute(bool: number(Key.showHiddenItems, default: false).boolValue)
        showSystemLayoutGuides = BoolMessageAttribute(bool: number(Key.showSystemLayoutGuides, default: true).boolValue)
        showBackingLayers = BoolMessageAttribute(bool: number(Key.showBackingLayers, default: false).boolValue)
        doubleClickBehavior = DoubleClickBehavior(rawValue: number(Key.doubleClickBehavior, default: NSNumber(value: DoubleClickBehavior.collapse.rawValue)).intValue) ?? .collapse
        rgbaFormat = number(Key.rgbaFormat, default: true).boolValue

        // 默认值为 0.22
        let zInterspaceValue = number(Key.zInterspace, default: 0.22).doubleValue
        zInterspace = DoubleMessageAttribute(double: max(min(zInterspaceValue, Double(LookinPreviewMaxZInterspace)), Double(LookinPreviewMinZInterspace)))

        appearanceType = PreferredAppearanceType(rawValue: number(Key.appearanceType, default: NSNumber(value: PreferredAppearanceType.system.rawValue)).intValue) ?? .system
        expansionIndex = number(Key.expansionIndex, default: 3).intValue
        imageContrastLevel = number(Key.contrastLevel, default: 0).intValue
        syncConsoleTarget = number(Key.syncConsoleTarget, default: true).boolValue
        freeRotation = BoolMessageAttribute(bool: number(Key.freeRotation, default: true).boolValue)
        fastMode = BoolMessageAttribute(bool: number(Key.fastMode, default: false).boolValue)

        var sectionShowConfig: [String: Bool] = [:]
        if let stored = defaults.object(forKey: Key.sectionsShow) as? NSDictionary {
            for case let (secID as String, value as NSNumber) in stored {
                sectionShowConfig[secID] = value.boolValue
            }
        }
        storedSectionShowConfig = sectionShowConfig

        collapsedAttrGroups = (defaults.object(forKey: Key.collapsedGroups) as? [String]) ?? [LookinAttrGroup_Class as String]

        // 这里的默认值需要在 LKExportAccessory.m 里定义的选项里面
        preferredExportCompression = CGFloat(number(Key.preferredExportCompression, default: 0.5).doubleValue)

        storedHierarchyRequestTimeoutInterval = Self.positiveInterval(
            defaults, key: Key.hierarchyRequestTimeoutInterval, fallback: LKDefaultHierarchyRequestTimeoutInterval
        )
        storedLicenseHandshakeTimeoutInterval = Self.positiveInterval(
            defaults, key: Key.licenseHandshakeTimeoutInterval, fallback: LKDefaultLicenseHandshakeTimeoutInterval
        )

        receivingConfigTime_Color = defaults.double(forKey: Key.receivingConfigTimeColor)
        receivingConfigTime_Class = defaults.double(forKey: Key.receivingConfigTimeClass)

        rememberExpansionState = number(Key.rememberExpansionState, default: true).boolValue

        super.init()

        showHiddenItems.subscribe(self, action: #selector(handleShowHiddenItemsChange(_:)), relatedObject: nil)
        showSystemLayoutGuides.subscribe(self, action: #selector(handleShowSystemLayoutGuidesChange(_:)), relatedObject: nil)
        showBackingLayers.subscribe(self, action: #selector(handleShowBackingLayersChange(_:)), relatedObject: nil)
        zInterspace.subscribe(self, action: #selector(handleZInterspaceDidChange(_:)), relatedObject: nil)
        freeRotation.subscribe(self, action: #selector(handleFreeRotationDidChange(_:)), relatedObject: nil)
        fastMode.subscribe(self, action: #selector(handleFastModeDidChange(_:)), relatedObject: nil)
    }

    /// A stored value read the way the Objective-C manager read it, with
    /// -integerValue / -doubleValue / -boolValue: an NSNumber, or a string.
    /// A `-key value` launch argument (the e2e scripts pass
    /// `-appearanceType 0`) reaches the argument domain as a string.
    private static func storedNumber(_ object: Any?) -> NSNumber? {
        switch object {
        case let number as NSNumber:
            return number
        case let string as NSString:
            let value = string.doubleValue
            if value == 0, string.boolValue {
                return NSNumber(value: true)
            }
            return NSNumber(value: value)
        default:
            return nil
        }
    }

    /// A stored interval above 0, or `fallback` written back.
    private static func positiveInterval(_ defaults: UserDefaults, key: String, fallback: TimeInterval) -> TimeInterval {
        if let stored = storedNumber(defaults.object(forKey: key)), stored.doubleValue > 0 {
            return stored.doubleValue
        }
        defaults.set(fallback, forKey: key)
        return fallback
    }

    /// Writes `value` when this manager stores its changes.
    private func store(_ value: Any, forKey key: String) {
        guard shouldStoreToLocal else { return }
        defaults.set(value, forKey: key)
    }

    // MARK: - Expansion state

    /// 读取某 bundle id 下记录的展开/折叠状态。key 为结构路径，value 为 @(YES) 表示展开、@(NO) 表示折叠。
    /// 未命中返回空字典。为兼容早期仅记录 expanded paths 的存档（NSArray<NSString *>），
    /// 读到旧格式时会自动转换为 dict 形式（全部视为 @(YES)）。
    @objc(expansionStateForBundleIdentifier:)
    func expansionState(forBundleIdentifier bundleIdentifier: String?) -> [String: NSNumber] {
        guard let bundleIdentifier, !bundleIdentifier.isEmpty else {
            return [:]
        }
        let stored = defaults.object(forKey: ExpansionStatePolicy.stateKey(forBundleIdentifier: bundleIdentifier))
        return ExpansionStatePolicy.decodeState(stored).mapValues { NSNumber(value: $0) }
    }

    /// 写入某 bundle id 下记录的展开/折叠状态，并将该 bundle id 提升到 LRU 队首。
    /// 当 LRU 超过容量上限时，最旧的 bundle id 会被静默移除（其对应的展开状态键也会被清理）。
    /// 若 rememberExpansionState 为 NO 或 bundleIdentifier 为空，则不做任何操作。
    @objc(setExpansionState:forBundleIdentifier:)
    func setExpansionState(_ expansionState: [String: NSNumber]?, forBundleIdentifier bundleIdentifier: String?) {
        guard let bundleIdentifier, !bundleIdentifier.isEmpty, rememberExpansionState, shouldStoreToLocal else {
            return
        }
        let lru = ExpansionStatePolicy.lru(movingToFront: bundleIdentifier, in: defaults.object(forKey: ExpansionStatePolicy.lruKey))
        let (kept, evicted) = ExpansionStatePolicy.evicting(lru)
        for evictedBundleIdentifier in evicted {
            defaults.removeObject(forKey: ExpansionStatePolicy.stateKey(forBundleIdentifier: evictedBundleIdentifier))
        }
        defaults.set(expansionState ?? [:], forKey: ExpansionStatePolicy.stateKey(forBundleIdentifier: bundleIdentifier))
        defaults.set(kept, forKey: ExpansionStatePolicy.lruKey)
    }

    /// 将一个已记录的 bundle id 提升到 LRU 队首。若该 bundle id 未被记录则不做任何操作。
    /// 当 rememberExpansionState 为 NO 或 bundleIdentifier 为空时同样不做任何操作。
    @objc(bumpExpansionStateBundleIdentifierToMostRecent:)
    func bumpExpansionStateBundleIdentifierToMostRecent(_ bundleIdentifier: String?) {
        guard let bundleIdentifier, !bundleIdentifier.isEmpty, rememberExpansionState, shouldStoreToLocal else {
            return
        }
        let storedLRU = defaults.object(forKey: ExpansionStatePolicy.lruKey)
        // Absent → the first setExpansionState:... call will record it.
        guard ExpansionStatePolicy.shouldBump(bundleIdentifier, in: storedLRU) else {
            return
        }
        defaults.set(ExpansionStatePolicy.lru(movingToFront: bundleIdentifier, in: storedLRU), forKey: ExpansionStatePolicy.lruKey)
    }

    // MARK: - Attribute subscribers

    @objc private func handleShowHiddenItemsChange(_ param: MessageActionParameters) {
        store(param.boolValue, forKey: Key.showHiddenItems)
    }

    @objc private func handleShowSystemLayoutGuidesChange(_ param: MessageActionParameters) {
        store(param.boolValue, forKey: Key.showSystemLayoutGuides)
    }

    @objc private func handleShowBackingLayersChange(_ param: MessageActionParameters) {
        store(param.boolValue, forKey: Key.showBackingLayers)
    }

    @objc private func handleFreeRotationDidChange(_ param: MessageActionParameters) {
        store(param.boolValue, forKey: Key.freeRotation)
    }

    @objc private func handleFastModeDidChange(_ param: MessageActionParameters) {
        store(param.boolValue, forKey: Key.fastMode)
    }

    @objc private func handleZInterspaceDidChange(_ param: MessageActionParameters) {
        store(param.doubleValue, forKey: Key.zInterspace)
    }

    // MARK: - Dashboard sections

    /// 返回某个 section 是否应该被显示在主界面上
    @objc func isSectionShowing(_ secID: String) -> Bool {
        if let stored = storedSectionShowConfig[secID] {
            return stored
        }
        return Self.sectionsShowingByDefault.contains(secID)
    }

    /// 把某个 section 显示在主界面上
    @objc func showSection(_ secID: String) {
        setSection(secID, showing: true)
    }

    /// 把某个 section 从主界面上移除
    @objc func hideSection(_ secID: String) {
        setSection(secID, showing: false)
    }

    /// Always stored, even when `shouldStoreToLocal` is off.
    private func setSection(_ secID: String, showing: Bool) {
        guard isSectionShowing(secID) != showing else {
            assertionFailure("section \(secID) is already \(showing ? "shown" : "hidden")")
            return
        }
        storedSectionShowConfig[secID] = showing
        NotificationCenter.default.post(name: NSNotification.Name(NotificationName_DidChangeSectionShowing), object: nil)
        defaults.set(storedSectionShowConfig, forKey: Key.sectionsShow)
    }

    @objc func reset() {}

    /// 返回默认情况下，哪些 section 应该被显示在主界面上
    private static let sectionsShowingByDefault: Set<String> = Set(([
        LookinAttrSec_Class_Class,
        LookinAttrSec_Relation_Relation,
        LookinAttrSec_Layout_Frame,
        LookinAttrSec_Layout_Bounds,
        LookinAttrSec_Layout_CoordinateSpace,
        LookinAttrSec_AutoLayout_Hugging,
        LookinAttrSec_AutoLayout_Resistance,
        LookinAttrSec_AutoLayout_Constraints,
        LookinAttrSec_AutoLayout_IntrinsicSize,
        LookinAttrSec_LayoutGuide_Identifier,
        LookinAttrSec_LayoutGuide_LayoutFrame,
        LookinAttrSec_LayoutGuide_OwningView,
        LookinAttrSec_NSCell_Cell,
        LookinAttrSec_NSCell_Content,
        LookinAttrSec_NSCell_Behavior,
        LookinAttrSec_NSCell_ButtonCell,
        LookinAttrSec_NSCell_TextFieldCell,
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
        LookinAttrSec_UIWindowScene_Geometry,
        LookinAttrSec_UIWindowScene_SizeRestrictions,
        LookinAttrSec_UIWindowScene_WindowingBehaviors,
        LookinAttrSec_UIWindowScene_Pointer,
        LookinAttrSec_UIWindowScene_Protection,
        LookinAttrSec_UIWindowScene_Traits,
        LookinAttrSec_UIWindowScene_Session,
        LookinAttrSec_UIWindowScene_Configuration,
        LookinAttrSec_UIWindowScene_ActivationConditions,
        // UITraitCollection
        LookinAttrSec_UITraitCollection_Appearance,
        LookinAttrSec_UITraitCollection_SizeClass,
        LookinAttrSec_UITraitCollection_Display,
        LookinAttrSec_UITraitCollection_Device,
        LookinAttrSec_UITraitCollection_Layout,
        LookinAttrSec_UITraitCollection_Content,
    ] as [NSString]).map { $0 as String })
}
