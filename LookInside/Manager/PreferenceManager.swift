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

let windowSizeNameDynamic = "LKWindowSizeName_Dynamic"
let windowSizeNameStatic = "LKWindowSizeName_Static"

/// The initial preview scale.
let initialPreviewScale: CGFloat = 0.27

/// The default hierarchy request timeout, in seconds.
let defaultHierarchyRequestTimeoutInterval: TimeInterval = 15
let defaultLicenseHandshakeTimeoutInterval: TimeInterval = 5

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

/// Whether Liquid Glass layers stay out of the preview until the user shows
/// one. Where the inspected app's Server takes the images — an older Server,
/// a window too large for its layers to be sent — a capture of the glass is
/// only its white shape source (see `PreviewGlassLayers`); where LookInside
/// draws the images from a layer archive, the glass is drawn as on screen.
@objc enum GlassLayerVisibility: Int, CaseIterable {
    /// Every glass layer stays in the preview.
    case show
    /// Glass layers stay out of the preview where LookInside cannot draw
    /// them. The default.
    case hideWhereNotDrawn
    /// Glass layers stay out of the preview where LookInside cannot draw
    /// them; where it can, the glass AppKit puts behind a split view item
    /// does, which covers the item's content in the preview. The glass of
    /// controls stays.
    case hide

    /// Whether a glass layer stays out of the preview, given whether
    /// LookInside draws its images (`isDrawnByLookInside`) and whether it is
    /// the glass AppKit puts behind a split view item, a sidebar's or an
    /// inspector's (`isSplitViewBackground`).
    func hidesGlassLayer(isDrawnByLookInside: Bool, isSplitViewBackground: Bool) -> Bool {
        switch self {
        case .show:
            false
        case .hideWhereNotDrawn:
            !isDrawnByLookInside
        case .hide:
            !isDrawnByLookInside || isSplitViewBackground
        }
    }

    /// Whether images LookInside draws leave any glass out.
    var hidesGlassDrawnByLookInside: Bool {
        hidesGlassLayer(isDrawnByLookInside: true, isSplitViewBackground: true)
    }
}

/// How far an inspected Mac app's Server goes to show the app as it looks in
/// front while LookInside, in front itself, takes its images. Each level does
/// what the one before it does, and more.
@objc enum InspectedAppKeyAppearanceLevel: Int, CaseIterable {
    /// The app's windows keep their inactive look.
    case off
    /// The window the app would make key is drawn as key, so AppKit's own
    /// views look active; the app is told nothing. The default.
    case drawsAsKey
    /// As `drawsAsKey`, and the app is told that window is key, so views it
    /// draws itself from `isKeyWindow` look active too; the app's own
    /// become-key and resign-key code runs on every refresh.
    case treatsAsKey

    /// The level on the wire.
    var serverLevel: KeyAppearanceLevel {
        switch self {
        case .off:
            .off
        case .drawsAsKey:
            .drawsAsKey
        case .treatsAsKey:
            .treatsAsKey
        }
    }

    /// The app and hierarchy request parameters that carry the level: the
    /// level for Servers that know it, and the switch older Servers read, on
    /// at any level but off — so an older Server draws the window as key when
    /// it is to be treated as key.
    var requestParameters: [NSString: NSNumber] {
        [
            RequestParameterKey.keyAppearanceLevel as NSString: NSNumber(value: serverLevel.rawValue),
            RequestParameterKey.keepsKeyAppearance as NSString: NSNumber(value: self != .off),
        ]
    }
}

enum MeasureState: Int {
    /// Not measuring.
    case no
    /// Measuring until the key is released.
    case unlocked
    /// Measuring until the user turns it off.
    case locked
}

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
        static let receivingConfigTimeColor = "ConfigTime_Color"
        static let receivingConfigTimeClass = "ConfigTime_Class"
        static let rememberExpansionState = "rememberExpansionState"
        /// The switch the Liquid Glass choice replaced; read once to carry
        /// its value over, and left in place for a Host that still reads it.
        static let hidesGlassLayersInPreview = "hideGlassLayersInPreview"
        static let glassLayerVisibility = "glassLayerVisibility"
        /// The switch the key appearance level replaced; read once to carry
        /// its value over, and left in place for a Host that still reads it.
        static let drawsInspectedAppAsActive = "drawsInspectedAppAsActive"
        static let inspectedAppKeyAppearanceLevel = "inspectedAppKeyAppearanceLevel"
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
    var shouldStoreToLocal = false

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
    var expansionIndex: Int {
        didSet {
            guard oldValue != expansionIndex else { return }
            store(expansionIndex, forKey: Key.expansionIndex)
        }
    }

    /// Not stored: the subscription in the Objective-C version targeted
    /// `showHiddenItems` before it existed, so changes were never written.
    let showOutline: BoolMessageAttribute

    let showHiddenItems: BoolMessageAttribute

    /// 是否在层级树里显示系统自动创建的 LayoutGuide（safe area、layout margins 等）。
    /// 默认显示；关闭只是宿主端过滤，数据仍在。用户自建 guide 不受此开关影响。
    let showSystemLayoutGuides: BoolMessageAttribute

    /// 是否显示 view 的 backing layer 子树（backing-layer-toggle 提案）。
    /// 默认关闭。开启后像 Xcode 的 Show Layers：每个 view 节点下展开完整 layer 子树，
    /// 内容显示在真正渲染它的 layer 上，view 节点变为线框。切换时重新拉取层级。
    let showBackingLayers: BoolMessageAttribute

    /// 范围是 0 ～ 1
    let zInterspace: DoubleMessageAttribute

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

    /// Whether Liquid Glass layers stay out of the preview until the user
    /// shows one. Default `.hideWhereNotDrawn`.
    @objc dynamic var glassLayerVisibility: GlassLayerVisibility {
        didSet {
            guard oldValue != glassLayerVisibility else { return }
            store(glassLayerVisibility.rawValue, forKey: Key.glassLayerVisibility)
        }
    }

    /// How far a Mac app's Server goes to show the app as it looks in front
    /// while it takes images, though LookInside is in front. Sent with the app
    /// and hierarchy requests (`InspectedAppKeyAppearanceLevel.requestParameters`).
    /// Default `.drawsAsKey`.
    @objc dynamic var inspectedAppKeyAppearanceLevel: InspectedAppKeyAppearanceLevel {
        didSet {
            guard oldValue != inspectedAppKeyAppearanceLevel else { return }
            store(inspectedAppKeyAppearanceLevel.rawValue, forKey: Key.inspectedAppKeyAppearanceLevel)
        }
    }

    /// 被折叠的属性组
    var collapsedAttributeGroups: [AttributesGroup.Identifier] {
        didSet {
            store(collapsedAttributeGroups.map(\.rawValue), forKey: Key.collapsedGroups)
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
            let value = newValue <= 0 ? defaultHierarchyRequestTimeoutInterval : newValue
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
            let value = newValue <= 0 ? defaultLicenseHandshakeTimeoutInterval : newValue
            guard storedLicenseHandshakeTimeoutInterval != value else { return }
            storedLicenseHandshakeTimeoutInterval = value
            store(value, forKey: Key.licenseHandshakeTimeoutInterval)
        }
    }

    let freeRotation: BoolMessageAttribute

    /// 上次接收到 iOS app 里传过来的 color config 和 collapsedClasses 信息的时间，用来统计
    /// Always stored, even when `shouldStoreToLocal` is off.
    var receivingConfigTime_Color: TimeInterval {
        didSet {
            defaults.set(receivingConfigTime_Color, forKey: Key.receivingConfigTimeColor)
        }
    }

    var receivingConfigTime_Class: TimeInterval {
        didSet {
            defaults.set(receivingConfigTime_Class, forKey: Key.receivingConfigTimeClass)
        }
    }

    private var storedSectionShowConfig: [String: Bool]

    // MARK: - Not stored

    /// 参数是 PreviewDimension
    let previewDimension: IntegerMessageAttribute

    let previewScale: DoubleMessageAttribute

    /// 参数是 MeasureState
    let measureState: IntegerMessageAttribute

    /// 是否用户正在按住 cmd 键而处于快速选择模式
    let isQuickSelecting: BoolMessageAttribute

    // MARK: - Init

    /// Reads every stored value; a missing one is set to its default and
    /// written back, as before.
    override init() {
        let defaults = UserDefaults.standard

        previewScale = DoubleMessageAttribute(double: Double(initialPreviewScale))
        previewDimension = IntegerMessageAttribute(integer: Int(PreviewDimension.dimension3D.rawValue))
        measureState = IntegerMessageAttribute(integer: MeasureState.no.rawValue)
        isQuickSelecting = BoolMessageAttribute(bool: false)

        if defaults.integer(forKey: Key.previousClientVersion) != Int(ProtocolVersion.client) {
            defaults.set(Int(ProtocolVersion.client), forKey: Key.previousClientVersion)
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
        zInterspace = DoubleMessageAttribute(double: max(min(zInterspaceValue, Double(previewMaxZInterspace)), Double(previewMinZInterspace)))

        appearanceType = PreferredAppearanceType(rawValue: number(Key.appearanceType, default: NSNumber(value: PreferredAppearanceType.system.rawValue)).intValue) ?? .system
        expansionIndex = number(Key.expansionIndex, default: 3).intValue
        imageContrastLevel = number(Key.contrastLevel, default: 0).intValue
        syncConsoleTarget = number(Key.syncConsoleTarget, default: true).boolValue
        freeRotation = BoolMessageAttribute(bool: number(Key.freeRotation, default: true).boolValue)

        var sectionShowConfig: [String: Bool] = [:]
        if let stored = defaults.object(forKey: Key.sectionsShow) as? NSDictionary {
            for case let (sectionIdentifier as String, value as NSNumber) in stored {
                sectionShowConfig[sectionIdentifier] = value.boolValue
            }
        }
        storedSectionShowConfig = sectionShowConfig

        collapsedAttributeGroups = ((defaults.object(forKey: Key.collapsedGroups) as? [String]) ?? [AttributesGroup.Identifier.class.rawValue]).map(AttributesGroup.Identifier.init(rawValue:))

        // 这里的默认值需要在 LKExportAccessory.m 里定义的选项里面
        preferredExportCompression = CGFloat(number(Key.preferredExportCompression, default: 0.5).doubleValue)

        storedHierarchyRequestTimeoutInterval = Self.positiveInterval(
            defaults, key: Key.hierarchyRequestTimeoutInterval, fallback: defaultHierarchyRequestTimeoutInterval
        )
        storedLicenseHandshakeTimeoutInterval = Self.positiveInterval(
            defaults, key: Key.licenseHandshakeTimeoutInterval, fallback: defaultLicenseHandshakeTimeoutInterval
        )

        receivingConfigTime_Color = defaults.double(forKey: Key.receivingConfigTimeColor)
        receivingConfigTime_Class = defaults.double(forKey: Key.receivingConfigTimeClass)

        rememberExpansionState = number(Key.rememberExpansionState, default: true).boolValue
        glassLayerVisibility = Self.storedGlassLayerVisibility(defaults)
        inspectedAppKeyAppearanceLevel = Self.storedInspectedAppKeyAppearanceLevel(defaults)

        super.init()

        showHiddenItems.subscribe(self, action: #selector(handleShowHiddenItemsChange(_:)), relatedObject: nil)
        showSystemLayoutGuides.subscribe(self, action: #selector(handleShowSystemLayoutGuidesChange(_:)), relatedObject: nil)
        showBackingLayers.subscribe(self, action: #selector(handleShowBackingLayersChange(_:)), relatedObject: nil)
        zInterspace.subscribe(self, action: #selector(handleZInterspaceDidChange(_:)), relatedObject: nil)
        freeRotation.subscribe(self, action: #selector(handleFreeRotationDidChange(_:)), relatedObject: nil)
    }

    /// The stored Liquid Glass choice. Without one, it is carried over from
    /// the switch it replaced: on (the default) became hiding where the glass
    /// cannot be drawn, off became showing every glass layer. The choice is
    /// then written back like every missing value; the switch is left alone.
    static func storedGlassLayerVisibility(_ defaults: UserDefaults) -> GlassLayerVisibility {
        if let stored = storedNumber(defaults.object(forKey: Key.glassLayerVisibility)),
           let visibility = GlassLayerVisibility(rawValue: stored.intValue)
        {
            return visibility
        }
        let switchWasOn = storedNumber(defaults.object(forKey: Key.hidesGlassLayersInPreview))?.boolValue ?? true
        let visibility: GlassLayerVisibility = switchWasOn ? .hideWhereNotDrawn : .show
        defaults.set(visibility.rawValue, forKey: Key.glassLayerVisibility)
        return visibility
    }

    /// The stored key appearance level. Without one, it is carried over from
    /// the switch it replaced: on (the default) became drawing as key, off
    /// became off. The level is then written back like every missing value;
    /// the switch is left alone.
    static func storedInspectedAppKeyAppearanceLevel(_ defaults: UserDefaults) -> InspectedAppKeyAppearanceLevel {
        if let stored = storedNumber(defaults.object(forKey: Key.inspectedAppKeyAppearanceLevel)),
           let level = InspectedAppKeyAppearanceLevel(rawValue: stored.intValue)
        {
            return level
        }
        let switchWasOn = storedNumber(defaults.object(forKey: Key.drawsInspectedAppAsActive))?.boolValue ?? true
        let level: InspectedAppKeyAppearanceLevel = switchWasOn ? .drawsAsKey : .off
        defaults.set(level.rawValue, forKey: Key.inspectedAppKeyAppearanceLevel)
        return level
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

    @objc private func handleZInterspaceDidChange(_ param: MessageActionParameters) {
        store(param.doubleValue, forKey: Key.zInterspace)
    }

    // MARK: - Dashboard sections

    /// 返回某个 section 是否应该被显示在主界面上
    func isSectionShowing(_ section: AttributesSection.Identifier) -> Bool {
        if let stored = storedSectionShowConfig[section.rawValue] {
            return stored
        }
        return Self.sectionsShowingByDefault.contains(section)
    }

    /// 把某个 section 显示在主界面上
    func showSection(_ section: AttributesSection.Identifier) {
        setSection(section, showing: true)
    }

    /// 把某个 section 从主界面上移除
    func hideSection(_ section: AttributesSection.Identifier) {
        setSection(section, showing: false)
    }

    /// Always stored, even when `shouldStoreToLocal` is off. The settings keep
    /// the identifier's string.
    private func setSection(_ section: AttributesSection.Identifier, showing: Bool) {
        guard isSectionShowing(section) != showing else {
            assertionFailure("section \(section) is already \(showing ? "shown" : "hidden")")
            return
        }
        storedSectionShowConfig[section.rawValue] = showing
        NotificationCenter.default.post(name: NSNotification.Name(NotificationName_DidChangeSectionShowing), object: nil)
        defaults.set(storedSectionShowConfig, forKey: Key.sectionsShow)
    }

    func reset() {}

    /// 返回默认情况下，哪些 section 应该被显示在主界面上
    static let sectionsShowingByDefault: Set<AttributesSection.Identifier> = [
        AttributesSection.Identifier.Class.class,
        AttributesSection.Identifier.Relation.relation,
        AttributesSection.Identifier.Layout.frame,
        AttributesSection.Identifier.Layout.bounds,
        AttributesSection.Identifier.Layout.coordinateSpace,
        AttributesSection.Identifier.AutoLayout.hugging,
        AttributesSection.Identifier.AutoLayout.resistance,
        AttributesSection.Identifier.AutoLayout.constraints,
        AttributesSection.Identifier.AutoLayout.intrinsicSize,
        AttributesSection.Identifier.LayoutGuide.guideIdentifier,
        AttributesSection.Identifier.LayoutGuide.layoutFrame,
        AttributesSection.Identifier.LayoutGuide.owningView,
        AttributesSection.Identifier.LayoutGuide.keyboardLayoutGuide,
        AttributesSection.Identifier.LayoutGuide.constraintsActiveNearEdges,
        AttributesSection.Identifier.LayoutGuide.constraintsActiveAwayFromEdges,
        AttributesSection.Identifier.NSCell.cell,
        AttributesSection.Identifier.NSCell.content,
        AttributesSection.Identifier.NSCell.behavior,
        AttributesSection.Identifier.NSCell.buttonCell,
        AttributesSection.Identifier.NSCell.textFieldCell,
        AttributesSection.Identifier.ViewLayer.visibility,
        AttributesSection.Identifier.ViewLayer.interactionAndMasks,
        AttributesSection.Identifier.ViewLayer.corner,
        AttributesSection.Identifier.ViewLayer.backgroundColor,
        AttributesSection.Identifier.ViewLayer.border,
        AttributesSection.Identifier.ViewLayer.shadow,
        AttributesSection.Identifier.UIStackView.axis,
        AttributesSection.Identifier.UIStackView.alignment,
        AttributesSection.Identifier.UIStackView.distribution,
        AttributesSection.Identifier.UIStackView.spacing,
        AttributesSection.Identifier.UIVisualEffectView.style,
        AttributesSection.Identifier.UIVisualEffectView.qmuiForegroundColor,
        AttributesSection.Identifier.UIImageView.name,
        AttributesSection.Identifier.UIImageView.open,
        AttributesSection.Identifier.UILabel.text,
        AttributesSection.Identifier.UILabel.font,
        AttributesSection.Identifier.UILabel.numberOfLines,
        AttributesSection.Identifier.UILabel.textColor,
        AttributesSection.Identifier.UILabel.breakMode,
        AttributesSection.Identifier.UILabel.alignment,
        AttributesSection.Identifier.UIControl.enabledSelected,
        AttributesSection.Identifier.UIControl.qmuiOutsideEdge,
        AttributesSection.Identifier.UIButton.contentInsets,
        AttributesSection.Identifier.UIScrollView.contentInset,
        AttributesSection.Identifier.UIScrollView.adjustedInset,
        AttributesSection.Identifier.UIScrollView.indicatorInset,
        AttributesSection.Identifier.UIScrollView.offset,
        AttributesSection.Identifier.UIScrollView.contentSize,
        AttributesSection.Identifier.UIScrollView.behavior,
        AttributesSection.Identifier.UITableView.style,
        AttributesSection.Identifier.UITableView.sectionsNumber,
        AttributesSection.Identifier.UITableView.rowsNumber,
        AttributesSection.Identifier.UITextView.text,
        AttributesSection.Identifier.UITextView.font,
        AttributesSection.Identifier.UITextView.textColor,
        AttributesSection.Identifier.UITextView.alignment,
        AttributesSection.Identifier.UITextView.containerInset,
        AttributesSection.Identifier.UITextField.text,
        AttributesSection.Identifier.UITextField.font,
        AttributesSection.Identifier.UITextField.textColor,
        AttributesSection.Identifier.UITextField.alignment,
        // NSWindow
        AttributesSection.Identifier.NSWindow.title,
        AttributesSection.Identifier.NSWindow.subtitle,
        AttributesSection.Identifier.NSWindow.state,
        AttributesSection.Identifier.NSWindow.style,
        AttributesSection.Identifier.NSWindow.collectionBehavior,
        AttributesSection.Identifier.NSWindow.appearance,
        AttributesSection.Identifier.NSWindow.titleVisibility,
        AttributesSection.Identifier.NSWindow.toolbarStyle,
        AttributesSection.Identifier.NSWindow.titlebarSeparatorStyle,
        AttributesSection.Identifier.NSWindow.behavior,
        AttributesSection.Identifier.NSWindow.animationBehavior,
        AttributesSection.Identifier.NSWindow.level,
        AttributesSection.Identifier.NSWindow.tabbingMode,
        AttributesSection.Identifier.NSWindow.size,
        AttributesSection.Identifier.NSWindow.information,
        // NSImageView
        AttributesSection.Identifier.NSImageView.name,
        AttributesSection.Identifier.NSImageView.open,
        AttributesSection.Identifier.NSImageView.scaling,
        AttributesSection.Identifier.NSImageView.behavior,
        AttributesSection.Identifier.NSImageView.contentTintColor,
        // NSControl
        AttributesSection.Identifier.NSControl.state,
        AttributesSection.Identifier.NSControl.controlSize,
        AttributesSection.Identifier.NSControl.font,
        AttributesSection.Identifier.NSControl.alignment,
        AttributesSection.Identifier.NSControl.miscellaneous,
        AttributesSection.Identifier.NSControl.stringValue,
        AttributesSection.Identifier.NSControl.value,
        // NSButton
        AttributesSection.Identifier.NSButton.buttonType,
        AttributesSection.Identifier.NSButton.title,
        AttributesSection.Identifier.NSButton.bezelStyle,
        AttributesSection.Identifier.NSButton.bordered,
        AttributesSection.Identifier.NSButton.bezelColor,
        AttributesSection.Identifier.NSButton.miscellaneous,
        // NSScrollView
        AttributesSection.Identifier.NSScrollView.contentOffset,
        AttributesSection.Identifier.NSScrollView.contentSize,
        AttributesSection.Identifier.NSScrollView.contentInset,
        AttributesSection.Identifier.NSScrollView.borderType,
        AttributesSection.Identifier.NSScrollView.scroller,
        AttributesSection.Identifier.NSScrollView.ruler,
        AttributesSection.Identifier.NSScrollView.lineScroll,
        AttributesSection.Identifier.NSScrollView.pageScroll,
        AttributesSection.Identifier.NSScrollView.scrollElasiticity,
        AttributesSection.Identifier.NSScrollView.miscellaneous,
        AttributesSection.Identifier.NSScrollView.magnification,
        // NSTableView
        AttributesSection.Identifier.NSTableView.rowHeight,
        AttributesSection.Identifier.NSTableView.automaticRowHeights,
        AttributesSection.Identifier.NSTableView.intercellSpacing,
        AttributesSection.Identifier.NSTableView.style,
        AttributesSection.Identifier.NSTableView.columnAutoresizingStyle,
        AttributesSection.Identifier.NSTableView.gridStyleMask,
        AttributesSection.Identifier.NSTableView.selectionHighlightStyle,
        AttributesSection.Identifier.NSTableView.gridColor,
        AttributesSection.Identifier.NSTableView.rowSizeStyle,
        AttributesSection.Identifier.NSTableView.numberOfRows,
        AttributesSection.Identifier.NSTableView.numberOfColumns,
        AttributesSection.Identifier.NSTableView.useAlternatingRowBackgroundColors,
        AttributesSection.Identifier.NSTableView.allowsColumnReordering,
        AttributesSection.Identifier.NSTableView.allowsColumnResizing,
        AttributesSection.Identifier.NSTableView.allowsMultipleSelection,
        AttributesSection.Identifier.NSTableView.allowsEmptySelection,
        AttributesSection.Identifier.NSTableView.allowsColumnSelection,
        AttributesSection.Identifier.NSTableView.allowsTypeSelect,
        AttributesSection.Identifier.NSTableView.draggingDestinationFeedbackStyle,
        AttributesSection.Identifier.NSTableView.autosave,
        AttributesSection.Identifier.NSTableView.floatsGroupRows,
        AttributesSection.Identifier.NSTableView.rowActionsVisible,
        AttributesSection.Identifier.NSTableView.usesStaticContents,
        AttributesSection.Identifier.NSTableView.userInterfaceLayoutDirection,
        AttributesSection.Identifier.NSTableView.verticalMotionCanBeginDrag,
        // NSTextField
        AttributesSection.Identifier.NSTextField.bezelStyle,
        AttributesSection.Identifier.NSTextField.bordered,
        AttributesSection.Identifier.NSTextField.textColor,
        AttributesSection.Identifier.NSTextField.placeholder,
        AttributesSection.Identifier.NSTextField.lineBreakStrategy,
        AttributesSection.Identifier.NSTextField.preferredMaxLayoutWidth,
        // NSTextView
        AttributesSection.Identifier.NSTextView.string,
        AttributesSection.Identifier.NSTextView.basic,
        AttributesSection.Identifier.NSTextView.font,
        AttributesSection.Identifier.NSTextView.textColor,
        AttributesSection.Identifier.NSTextView.alignment,
        AttributesSection.Identifier.NSTextView.containerInset,
        AttributesSection.Identifier.NSTextView.baseWritingDirection,
        AttributesSection.Identifier.NSTextView.size,
        AttributesSection.Identifier.NSTextView.resizable,
        // NSVisualEffectView
        AttributesSection.Identifier.NSVisualEffectView.material,
        AttributesSection.Identifier.NSVisualEffectView.interiorBackgroundStyle,
        AttributesSection.Identifier.NSVisualEffectView.blendingMode,
        AttributesSection.Identifier.NSVisualEffectView.state,
        AttributesSection.Identifier.NSVisualEffectView.emphasized,
        // NSStackView
        AttributesSection.Identifier.NSStackView.orientation,
        AttributesSection.Identifier.NSStackView.edgeInsets,
        AttributesSection.Identifier.NSStackView.detachesHiddenViews,
        AttributesSection.Identifier.NSStackView.distribution,
        AttributesSection.Identifier.NSStackView.alignment,
        AttributesSection.Identifier.NSStackView.spacing,
        // NSSlider
        AttributesSection.Identifier.NSSlider.sliderType,
        AttributesSection.Identifier.NSSlider.range,
        AttributesSection.Identifier.NSSlider.tickMark,
        AttributesSection.Identifier.NSSlider.miscellaneous,
        // NSProgressIndicator
        AttributesSection.Identifier.NSProgressIndicator.style,
        AttributesSection.Identifier.NSProgressIndicator.range,
        AttributesSection.Identifier.NSProgressIndicator.miscellaneous,
        // NSSegmentedControl
        AttributesSection.Identifier.NSSegmentedControl.segmentCount,
        AttributesSection.Identifier.NSSegmentedControl.selection,
        AttributesSection.Identifier.NSSegmentedControl.style,
        AttributesSection.Identifier.NSSegmentedControl.colors,
        // NSPopUpButton
        AttributesSection.Identifier.NSPopUpButton.behavior,
        AttributesSection.Identifier.NSPopUpButton.selection,
        AttributesSection.Identifier.NSPopUpButton.items,
        // NSComboBox
        AttributesSection.Identifier.NSComboBox.items,
        AttributesSection.Identifier.NSComboBox.miscellaneous,
        // NSStepper
        AttributesSection.Identifier.NSStepper.range,
        AttributesSection.Identifier.NSStepper.miscellaneous,
        // NSColorWell
        AttributesSection.Identifier.NSColorWell.color,
        AttributesSection.Identifier.NSColorWell.miscellaneous,
        // NSSwitch
        AttributesSection.Identifier.NSSwitch.state,
        // NSDatePicker
        AttributesSection.Identifier.NSDatePicker.style,
        AttributesSection.Identifier.NSDatePicker.range,
        AttributesSection.Identifier.NSDatePicker.miscellaneous,
        // NSLevelIndicator
        AttributesSection.Identifier.NSLevelIndicator.style,
        AttributesSection.Identifier.NSLevelIndicator.range,
        AttributesSection.Identifier.NSLevelIndicator.tickMark,
        // NSOutlineView
        AttributesSection.Identifier.NSOutlineView.indentation,
        AttributesSection.Identifier.NSOutlineView.miscellaneous,
        // NSCollectionView
        AttributesSection.Identifier.NSCollectionView.selection,
        AttributesSection.Identifier.NSCollectionView.information,
        AttributesSection.Identifier.NSCollectionView.colors,
        // NSBox
        AttributesSection.Identifier.NSBox.kind,
        AttributesSection.Identifier.NSBox.title,
        AttributesSection.Identifier.NSBox.appearance,
        AttributesSection.Identifier.NSBox.metrics,
        // NSSplitView
        AttributesSection.Identifier.NSSplitView.orientation,
        AttributesSection.Identifier.NSSplitView.style,
        AttributesSection.Identifier.NSSplitView.miscellaneous,
        // NSTabView
        AttributesSection.Identifier.NSTabView.kind,
        AttributesSection.Identifier.NSTabView.miscellaneous,
        AttributesSection.Identifier.NSTabView.information,
        // NSGridView
        AttributesSection.Identifier.NSGridView.dimensions,
        AttributesSection.Identifier.NSGridView.spacing,
        AttributesSection.Identifier.NSGridView.placement,
        // UIWindowScene
        AttributesSection.Identifier.UIWindowScene.state,
        AttributesSection.Identifier.UIWindowScene.title,
        AttributesSection.Identifier.UIWindowScene.orientation,
        AttributesSection.Identifier.UIWindowScene.windows,
        AttributesSection.Identifier.UIWindowScene.screen,
        AttributesSection.Identifier.UIWindowScene.statusBar,
        AttributesSection.Identifier.UIWindowScene.geometry,
        AttributesSection.Identifier.UIWindowScene.sizeRestrictions,
        AttributesSection.Identifier.UIWindowScene.windowingBehaviors,
        AttributesSection.Identifier.UIWindowScene.pointer,
        AttributesSection.Identifier.UIWindowScene.protection,
        AttributesSection.Identifier.UIWindowScene.traits,
        AttributesSection.Identifier.UIWindowScene.session,
        AttributesSection.Identifier.UIWindowScene.configuration,
        AttributesSection.Identifier.UIWindowScene.activationConditions,
        // UITraitCollection
        AttributesSection.Identifier.UITraitCollection.appearance,
        AttributesSection.Identifier.UITraitCollection.sizeClass,
        AttributesSection.Identifier.UITraitCollection.display,
        AttributesSection.Identifier.UITraitCollection.device,
        AttributesSection.Identifier.UITraitCollection.layout,
        AttributesSection.Identifier.UITraitCollection.content,
        // UISlider
        AttributesSection.Identifier.UISlider.behavioralStyle,
        AttributesSection.Identifier.UISlider.preferredBehavioralStyle,
        AttributesSection.Identifier.UISlider.value,
        AttributesSection.Identifier.UISlider.images,
        AttributesSection.Identifier.UISlider.continuous,
        AttributesSection.Identifier.UISlider.sliderStyle,
        AttributesSection.Identifier.UISlider.colors,
        // UIStepper
        AttributesSection.Identifier.UIStepper.behavior,
        AttributesSection.Identifier.UIStepper.value,
        // UISwitch
        AttributesSection.Identifier.UISwitch.colors,
        AttributesSection.Identifier.UISwitch.images,
        AttributesSection.Identifier.UISwitch.title,
        AttributesSection.Identifier.UISwitch.style,
        AttributesSection.Identifier.UISwitch.preferredStyle,
        AttributesSection.Identifier.UISwitch.on,
        // UISegmentedControl
        AttributesSection.Identifier.UISegmentedControl.behavior,
        AttributesSection.Identifier.UISegmentedControl.numberOfSegments,
        AttributesSection.Identifier.UISegmentedControl.selectedSegmentIndex,
        AttributesSection.Identifier.UISegmentedControl.selectedSegmentTintColor,
        // UIProgressView
        AttributesSection.Identifier.UIProgressView.progressViewStyle,
        AttributesSection.Identifier.UIProgressView.progress,
        AttributesSection.Identifier.UIProgressView.colors,
        AttributesSection.Identifier.UIProgressView.images,
        // UIActivityIndicatorView
        AttributesSection.Identifier.UIActivityIndicatorView.activityIndicatorViewStyle,
        AttributesSection.Identifier.UIActivityIndicatorView.behavior,
        AttributesSection.Identifier.UIActivityIndicatorView.color,
        // UIPageControl
        AttributesSection.Identifier.UIPageControl.numberOfPages,
        AttributesSection.Identifier.UIPageControl.currentPage,
        AttributesSection.Identifier.UIPageControl.behavior,
        AttributesSection.Identifier.UIPageControl.colors,
        AttributesSection.Identifier.UIPageControl.backgroundStyle,
        AttributesSection.Identifier.UIPageControl.direction,
        AttributesSection.Identifier.UIPageControl.interactionState,
        AttributesSection.Identifier.UIPageControl.images,
        // UIDatePicker
        AttributesSection.Identifier.UIDatePicker.datePickerMode,
        AttributesSection.Identifier.UIDatePicker.locale,
        AttributesSection.Identifier.UIDatePicker.calendar,
        AttributesSection.Identifier.UIDatePicker.timeZone,
        AttributesSection.Identifier.UIDatePicker.date,
        AttributesSection.Identifier.UIDatePicker.minimumDate,
        AttributesSection.Identifier.UIDatePicker.maximumDate,
        AttributesSection.Identifier.UIDatePicker.countDownDuration,
        AttributesSection.Identifier.UIDatePicker.minuteInterval,
        AttributesSection.Identifier.UIDatePicker.preferredDatePickerStyle,
        AttributesSection.Identifier.UIDatePicker.datePickerStyle,
        AttributesSection.Identifier.UIDatePicker.roundsToMinuteInterval,
        // UIColorWell
        AttributesSection.Identifier.UIColorWell.title,
        AttributesSection.Identifier.UIColorWell.behavior,
        AttributesSection.Identifier.UIColorWell.selectedColor,
        AttributesSection.Identifier.UIColorWell.maximumLinearExposure,
        // UIRefreshControl
        AttributesSection.Identifier.UIRefreshControl.refreshing,
        AttributesSection.Identifier.UIRefreshControl.attributedTitle,
        // UIPickerView
        AttributesSection.Identifier.UIPickerView.numberOfComponents,
        // UICalendarView
        AttributesSection.Identifier.UICalendarView.locale,
        AttributesSection.Identifier.UICalendarView.calendar,
        AttributesSection.Identifier.UICalendarView.timeZone,
        AttributesSection.Identifier.UICalendarView.fontDesign,
        AttributesSection.Identifier.UICalendarView.wantsDateDecorations,
        // UIPasteControl
        AttributesSection.Identifier.UIPasteControl.configuration,
        // UIControl (added sections)
        AttributesSection.Identifier.UIControl.behavior,
        // UICollectionView
        AttributesSection.Identifier.UICollectionView.behavior,
        AttributesSection.Identifier.UICollectionView.reorderingCadence,
        AttributesSection.Identifier.UICollectionView.selfSizingInvalidation,
        AttributesSection.Identifier.UICollectionView.indexPathsForSelectedItems,
        AttributesSection.Identifier.UICollectionView.numberOfSections,
        // UICollectionReusableView
        AttributesSection.Identifier.UICollectionReusableView.reuseIdentifier,
        AttributesSection.Identifier.UICollectionReusableView.uiCollectionViewCell,
        AttributesSection.Identifier.UICollectionReusableView.uiCollectionViewListCell,
        // UITableViewCell
        AttributesSection.Identifier.UITableViewCell.behavior,
        AttributesSection.Identifier.UITableViewCell.backgroundConfiguration,
        AttributesSection.Identifier.UITableViewCell.reuseIdentifier,
        AttributesSection.Identifier.UITableViewCell.selectionStyle,
        AttributesSection.Identifier.UITableViewCell.editingStyle,
        AttributesSection.Identifier.UITableViewCell.accessoryType,
        AttributesSection.Identifier.UITableViewCell.editingAccessoryType,
        AttributesSection.Identifier.UITableViewCell.indentationLevel,
        AttributesSection.Identifier.UITableViewCell.indentationWidth,
        AttributesSection.Identifier.UITableViewCell.separatorInset,
        AttributesSection.Identifier.UITableViewCell.focusStyle,
        // UITableViewHeaderFooterView
        AttributesSection.Identifier.UITableViewHeaderFooterView.behavior,
        AttributesSection.Identifier.UITableViewHeaderFooterView.backgroundConfiguration,
        AttributesSection.Identifier.UITableViewHeaderFooterView.reuseIdentifier,
        // UINavigationBar
        AttributesSection.Identifier.UINavigationBar.barStyle,
        AttributesSection.Identifier.UINavigationBar.behavior,
        AttributesSection.Identifier.UINavigationBar.topItem,
        AttributesSection.Identifier.UINavigationBar.backItem,
        AttributesSection.Identifier.UINavigationBar.currentNSToolbarSection,
        AttributesSection.Identifier.UINavigationBar.behavioralStyle,
        AttributesSection.Identifier.UINavigationBar.preferredBehavioralStyle,
        AttributesSection.Identifier.UINavigationBar.barTintColor,
        AttributesSection.Identifier.UINavigationBar.images,
        // UITabBar
        AttributesSection.Identifier.UITabBar.selectedItem,
        AttributesSection.Identifier.UITabBar.behavior,
        AttributesSection.Identifier.UITabBar.colors,
        AttributesSection.Identifier.UITabBar.images,
        AttributesSection.Identifier.UITabBar.itemPositioning,
        AttributesSection.Identifier.UITabBar.itemWidth,
        AttributesSection.Identifier.UITabBar.itemSpacing,
        AttributesSection.Identifier.UITabBar.barStyle,
        // UIToolbar
        AttributesSection.Identifier.UIToolbar.barStyle,
        AttributesSection.Identifier.UIToolbar.translucent,
        AttributesSection.Identifier.UIToolbar.barTintColor,
        // UISearchBar
        AttributesSection.Identifier.UISearchBar.barStyle,
        AttributesSection.Identifier.UISearchBar.text,
        AttributesSection.Identifier.UISearchBar.prompt,
        AttributesSection.Identifier.UISearchBar.placeholder,
        AttributesSection.Identifier.UISearchBar.behavior,
        AttributesSection.Identifier.UISearchBar.barTintColor,
        AttributesSection.Identifier.UISearchBar.searchBarStyle,
        AttributesSection.Identifier.UISearchBar.scopeButtonTitles,
        AttributesSection.Identifier.UISearchBar.selectedScopeButtonIndex,
        AttributesSection.Identifier.UISearchBar.images,
        AttributesSection.Identifier.UISearchBar.searchFieldBackgroundPositionAdjustment,
        AttributesSection.Identifier.UISearchBar.searchTextPositionAdjustment,
        // UIInputView
        AttributesSection.Identifier.UIInputView.inputViewStyle,
        AttributesSection.Identifier.UIInputView.allowsSelfSizing,
        // UIContentUnavailableView
        AttributesSection.Identifier.UIContentUnavailableView.configuration,
        AttributesSection.Identifier.UIContentUnavailableView.scrollEnabled,
        // UIBackgroundExtensionView
        AttributesSection.Identifier.UIBackgroundExtensionView.automaticallyPlacesContentView,
        // UIWindow
        AttributesSection.Identifier.UIWindow.behavior,
        AttributesSection.Identifier.UIWindow.windowLevel,
        AttributesSection.Identifier.UIWindow.rootViewController,
        // UIView
        AttributesSection.Identifier.UIView.behavior,
        AttributesSection.Identifier.UIView.transform,
        AttributesSection.Identifier.UIView.layoutMargins,
        // UIButton (added sections)
        AttributesSection.Identifier.UIButton.configuration,
        AttributesSection.Identifier.UIButton.buttonType,
        AttributesSection.Identifier.UIButton.currentTitle,
        // UILabel (added sections)
        AttributesSection.Identifier.UILabel.behavior,
        // UIImageView (added sections)
        AttributesSection.Identifier.UIImageView.behavior,
        // UIScrollView (added sections)
        AttributesSection.Identifier.UIScrollView.flags,
        // UITableView (added sections)
        AttributesSection.Identifier.UITableView.behavior,
        AttributesSection.Identifier.UITableView.rowHeight,
        AttributesSection.Identifier.UITableView.estimatedRowHeight,
        // UITextField (added sections)
        AttributesSection.Identifier.UITextField.borderStyle,
        // UIStackView (added sections)
        AttributesSection.Identifier.UIStackView.behavior,
        // UIVisualEffectView (added sections)
        AttributesSection.Identifier.UIVisualEffectView.effect,
        // NSClipView
        AttributesSection.Identifier.NSClipView.backgroundColor,
        AttributesSection.Identifier.NSClipView.behavior,
        AttributesSection.Identifier.NSClipView.documentRect,
        AttributesSection.Identifier.NSClipView.documentVisibleRect,
        AttributesSection.Identifier.NSClipView.contentInsets,
        // NSScroller
        AttributesSection.Identifier.NSScroller.scrollerStyle,
        AttributesSection.Identifier.NSScroller.knobStyle,
        AttributesSection.Identifier.NSScroller.usableParts,
        AttributesSection.Identifier.NSScroller.controlSize,
        AttributesSection.Identifier.NSScroller.hitPart,
        AttributesSection.Identifier.NSScroller.knobProportion,
        // NSBrowser
        AttributesSection.Identifier.NSBrowser.behavior,
        AttributesSection.Identifier.NSBrowser.minColumnWidth,
        AttributesSection.Identifier.NSBrowser.maxVisibleColumns,
        AttributesSection.Identifier.NSBrowser.pathSeparator,
        AttributesSection.Identifier.NSBrowser.clickedColumn,
        AttributesSection.Identifier.NSBrowser.clickedRow,
        AttributesSection.Identifier.NSBrowser.selectedColumn,
        AttributesSection.Identifier.NSBrowser.lastColumn,
        AttributesSection.Identifier.NSBrowser.numberOfVisibleColumns,
        AttributesSection.Identifier.NSBrowser.firstVisibleColumn,
        AttributesSection.Identifier.NSBrowser.lastVisibleColumn,
        AttributesSection.Identifier.NSBrowser.titleHeight,
        AttributesSection.Identifier.NSBrowser.columnResizingType,
        AttributesSection.Identifier.NSBrowser.backgroundColor,
        // NSMatrix
        AttributesSection.Identifier.NSMatrix.mode,
        AttributesSection.Identifier.NSMatrix.behavior,
        AttributesSection.Identifier.NSMatrix.selectedRow,
        AttributesSection.Identifier.NSMatrix.selectedColumn,
        AttributesSection.Identifier.NSMatrix.cellSize,
        AttributesSection.Identifier.NSMatrix.intercellSpacing,
        AttributesSection.Identifier.NSMatrix.colors,
        AttributesSection.Identifier.NSMatrix.numberOfRows,
        AttributesSection.Identifier.NSMatrix.numberOfColumns,
        // NSPathControl
        AttributesSection.Identifier.NSPathControl.editable,
        AttributesSection.Identifier.NSPathControl.placeholderString,
        AttributesSection.Identifier.NSPathControl.url,
        AttributesSection.Identifier.NSPathControl.pathStyle,
        AttributesSection.Identifier.NSPathControl.backgroundColor,
        AttributesSection.Identifier.NSPathControl.menu,
        // NSRuleEditor
        AttributesSection.Identifier.NSRuleEditor.nestingMode,
        AttributesSection.Identifier.NSRuleEditor.rowHeight,
        AttributesSection.Identifier.NSRuleEditor.behavior,
        AttributesSection.Identifier.NSRuleEditor.numberOfRows,
        // NSSearchField
        AttributesSection.Identifier.NSSearchField.searchTextBounds,
        AttributesSection.Identifier.NSSearchField.searchButtonBounds,
        AttributesSection.Identifier.NSSearchField.cancelButtonBounds,
        AttributesSection.Identifier.NSSearchField.searchMenuTemplate,
        AttributesSection.Identifier.NSSearchField.behavior,
        AttributesSection.Identifier.NSSearchField.maximumRecents,
        // NSComboButton
        AttributesSection.Identifier.NSComboButton.title,
        AttributesSection.Identifier.NSComboButton.image,
        AttributesSection.Identifier.NSComboButton.imageScaling,
        AttributesSection.Identifier.NSComboButton.menu,
        AttributesSection.Identifier.NSComboButton.style,
        // NSGlassEffectView
        AttributesSection.Identifier.NSGlassEffectView.cornerRadius,
        AttributesSection.Identifier.NSGlassEffectView.tintColor,
        AttributesSection.Identifier.NSGlassEffectView.style,
        AttributesSection.Identifier.NSGlassEffectView.effectIsInteractive,
        AttributesSection.Identifier.NSGlassEffectView.nsGlassEffectContainerView,
        // NSBackgroundExtensionView
        AttributesSection.Identifier.NSBackgroundExtensionView.automaticallyPlacesContentView,
        // NSRulerView
        AttributesSection.Identifier.NSRulerView.orientation,
        AttributesSection.Identifier.NSRulerView.baselineLocation,
        AttributesSection.Identifier.NSRulerView.requiredThickness,
        AttributesSection.Identifier.NSRulerView.ruleThickness,
        AttributesSection.Identifier.NSRulerView.reservedThicknessForMarkers,
        AttributesSection.Identifier.NSRulerView.reservedThicknessForAccessoryView,
        AttributesSection.Identifier.NSRulerView.measurementUnits,
        AttributesSection.Identifier.NSRulerView.originOffset,
        AttributesSection.Identifier.NSRulerView.flipped,
        // NSTableCellView
        AttributesSection.Identifier.NSTableCellView.backgroundStyle,
        AttributesSection.Identifier.NSTableCellView.rowSizeStyle,
        // NSTableRowView
        AttributesSection.Identifier.NSTableRowView.selectionHighlightStyle,
        AttributesSection.Identifier.NSTableRowView.behavior,
        AttributesSection.Identifier.NSTableRowView.draggingDestinationFeedbackStyle,
        AttributesSection.Identifier.NSTableRowView.indentationForDropOperation,
        AttributesSection.Identifier.NSTableRowView.interiorBackgroundStyle,
        AttributesSection.Identifier.NSTableRowView.backgroundColor,
        AttributesSection.Identifier.NSTableRowView.numberOfColumns,
        // NSTableHeaderView
        AttributesSection.Identifier.NSTableHeaderView.draggedColumn,
        AttributesSection.Identifier.NSTableHeaderView.draggedDistance,
        AttributesSection.Identifier.NSTableHeaderView.resizedColumn,
        // NSTextInsertionIndicator
        AttributesSection.Identifier.NSTextInsertionIndicator.displayMode,
        AttributesSection.Identifier.NSTextInsertionIndicator.color,
        AttributesSection.Identifier.NSTextInsertionIndicator.automaticModeOptions,
        // NSView
        AttributesSection.Identifier.NSView.behavior,
        AttributesSection.Identifier.NSView.autoresizingMask,
        // NSButton (added sections)
        AttributesSection.Identifier.NSButton.state,
        // NSTextView (added sections)
        AttributesSection.Identifier.NSTextView.selectedRange,
        // NSWindow (added sections)
        AttributesSection.Identifier.NSWindow.styleMask,
        AttributesSection.Identifier.NSWindow.firstResponder,
        // CALayer
        AttributesSection.Identifier.CALayer.transform,
        AttributesSection.Identifier.CALayer.behavior,
        AttributesSection.Identifier.CALayer.caShapeLayer,
        AttributesSection.Identifier.CALayer.caGradientLayer,
        AttributesSection.Identifier.CALayer.caTextLayer,
        AttributesSection.Identifier.CALayer.caReplicatorLayer,
        AttributesSection.Identifier.CALayer.caEmitterLayer,
        AttributesSection.Identifier.CALayer.caScrollLayer,
        AttributesSection.Identifier.CALayer.caTiledLayer,
    ]
}
