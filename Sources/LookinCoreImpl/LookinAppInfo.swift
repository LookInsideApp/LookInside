//
//  LookinAppInfo.swift
//  qmuidemo
//
//  Was LookinAppInfo.m: the 201
//  reply and part of every hierarchy. The coding keys and scalar encodings are
//  pinned by Tests/WireFormatGolden.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif
    #if canImport(UIKit)
        import UIKit
    #elseif os(macOS)
        import AppKit
    #endif

    private let CodingKey_AppIcon = "1"
    private let CodingKey_Screenshot = "2"
    private let CodingKey_DeviceDescription = "3"
    private let CodingKey_OsDescription = "4"
    private let CodingKey_AppName = "5"
    private let CodingKey_ScreenWidth = "6"
    private let CodingKey_ScreenHeight = "7"
    private let CodingKey_DeviceType = "8"

    /// Reads a sysctl entry as a string, or nil when it is unavailable or empty.
    private func LookinAppInfoSysctlStringValue(_ sysctlName: String) -> String? {
        var valueSize = 0
        if sysctlbyname(sysctlName, nil, &valueSize, nil, 0) != 0 || valueSize == 0 {
            return nil
        }
        var valueBuffer = [CChar](repeating: 0, count: valueSize)
        var value: String?
        if sysctlbyname(sysctlName, &valueBuffer, &valueSize, nil, 0) == 0 {
            value = String(validatingCString: valueBuffer)
        }
        guard let value, !value.isEmpty else {
            return nil
        }
        return value
    }

    #if targetEnvironment(macCatalyst)
        /// This Mac's user-facing computer name, e.g. "JH's Mac Studio Ultra".
        /// Nil when it cannot be read, which callers must tolerate.
        ///
        /// Needed because -[UIDevice name] answers the literal string "iPad" on
        /// Catalyst. That names a device family, not this machine, so it
        /// identifies nothing to the person reading the host's device label.
        private func LookinAppInfoMacHostLocalizedName() -> String? {
            let currentHostSelector = NSSelectorFromString("currentHost")
            guard let hostClass = NSClassFromString("NSHost"), (hostClass as AnyObject).responds(to: currentHostSelector) else {
                return nil
            }
            // NSHost is declared only in the AppKit-flavoured Foundation headers,
            // which a Catalyst target does not see, but the class is present and
            // works at runtime.
            guard let currentHost = (hostClass as AnyObject).perform(currentHostSelector)?.takeUnretainedValue() else {
                return nil
            }
            let localizedNameSelector = NSSelectorFromString("localizedName")
            guard currentHost.responds(to: localizedNameSelector) else {
                return nil
            }
            guard let localizedName = currentHost.perform(localizedNameSelector)?.takeUnretainedValue() as? NSString, localizedName.length > 0 else {
                return nil
            }
            return localizedName as String
        }
    #endif

    /// `+getAppInfoIdentifier`: random per launch, stable until the app is
    /// killed.
    private let LookinAppInfoIdentifier: Int = {
        let nowMicros = UInt64(Date().timeIntervalSince1970 * 1_000_000.0)
        let processID = UInt64(ProcessInfo.processInfo.processIdentifier)
        let randomBits = UInt64(arc4random())
        var identifier = Int(truncatingIfNeeded: (nowMicros << 12) ^ (processID << 1) ^ randomBits)
        if identifier <= 0 {
            identifier = Int(truncatingIfNeeded: processID ^ (randomBits != 0 ? randomBits : 1))
        }
        return identifier
    }()

    /// `+currentDeviceModelIdentifier`: the hardware model identifier of the
    /// device this process runs on, e.g. "iPhone16,2". Nil when it cannot be
    /// determined, which callers must tolerate.
    private let LookinAppInfoDeviceModelIdentifier: String? = {
        #if targetEnvironment(simulator)
            // hw.machine reports the *host* Mac's architecture ("arm64") inside a
            // simulator, which identifies no device at all. The simulated model is
            // only available from the environment simctl prepares for the process.
            return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]
        #elseif os(macOS) || targetEnvironment(macCatalyst)
            // On macOS hw.machine is the CPU architecture; the Mac model lives in
            // hw.model.
            return LookinAppInfoSysctlStringValue("hw.model")
        #else
            return LookinAppInfoSysctlStringValue("hw.machine")
        #endif
    }()

    /// `+isSimulator`.
    private func LookinAppInfoIsSimulator() -> Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }

    private func LookinAppInfoAppName() -> String {
        let info = Bundle.main.infoDictionary
        if let displayName = info?["CFBundleDisplayName"] as? NSString, displayName.length > 0 {
            return displayName as String
        }
        if let name = info?["CFBundleName"] as? NSString, name.length > 0 {
            return name as String
        }
        return ProcessInfo.processInfo.processName
    }

    private func LookinAppInfoAppIcon() -> LookinImage? {
        #if os(tvOS)
            return nil
        #elseif canImport(UIKit)
            var imageName: String?
            if let bundleIcons = Bundle.main.infoDictionary?["CFBundleIcons"] as? NSDictionary {
                let primaryIcon = bundleIcons.object(forKey: "CFBundlePrimaryIcon")
                if let primaryIcon = primaryIcon as? NSDictionary {
                    imageName = (primaryIcon.object(forKey: "CFBundleIconFiles") as? NSArray)?.lastObject as? String
                } else if let primaryIcon = primaryIcon as? String {
                    imageName = primaryIcon
                }
            }
            guard let imageName, !imageName.isEmpty else {
                // The name is normally something like "AppIcon60x60", but it can
                // be nil; [UIImage imageNamed:nil] would log "CUICatalog: Invalid
                // asset name supplied: '(null)'".
                return nil
            }
            return UIImage(named: imageName)
        #elseif os(macOS)
            return NSApplication.shared.applicationIconImage
        #endif
    }

    private func LookinAppInfoScreenshotImage() -> LookinImage? {
        // The old header declared +keyWindow nonnull, but it answers nil whenever
        // no window is key; read it through the runtime so Swift sees the nil.
        var window = (LKS_MultiplatformAdapter.self as AnyObject).perform(NSSelectorFromString("keyWindow"))?.takeUnretainedValue() as? LookinWindow
        #if os(macOS)
            // keyWindow is nil on macOS while the app is inactive or in the
            // background. Fall back to the main window, then to any window.
            if window == nil {
                window = NSApplication.shared.mainWindow
            }
            if window == nil {
                window = NSApplication.shared.windows.first
            }
        #endif
        guard let window else {
            return nil
        }
        #if canImport(UIKit)
            let size = window.bounds.size
            if size.width <= 0 || size.height <= 0 {
                // UIGraphicsBeginImageContext() raises for a zero size:
                // https://github.com/hughkli/Lookin/issues/21
                return nil
            }
            UIGraphicsBeginImageContextWithOptions(size, true, 0.4)
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        #elseif os(macOS)
            // ScreenCaptureKit is async and prompts for screen recording
            // permission; the synchronous CGWindowListCreateImage is enough to
            // capture this app's own window thumbnail.
            guard let cgImage = LookinAppInfoWindowListImage(CGWindowID(window.windowNumber)) else {
                return nil
            }
            return NSImage(cgImage: cgImage, size: window.frame.size)
        #endif
    }

    #if os(macOS)
        @available(macOS, deprecated: 14.0)
        private func LookinAppInfoDeprecatedWindowListImage(_ windowID: CGWindowID) -> CGImage? {
            CGWindowListCreateImage(.zero, .optionIncludingWindow, windowID, .boundsIgnoreFraming)
        }

        /// Calls the deprecated CGWindowListCreateImage without a warning at
        /// every use site (the original silenced -Wdeprecated-declarations).
        private let LookinAppInfoWindowListImage: (CGWindowID) -> CGImage? = LookinAppInfoDeprecatedWindowListImage
    #endif

    @objc(LookinAppInfo)
    public class LookinAppInfo: NSObject, NSCoding, NSSecureCoding, NSCopying {
        @objc(appInfoIdentifier)
        public var appInfoIdentifier: UInt = 0
        @objc(shouldUseCache)
        public var shouldUseCache: Bool = false
        @objc(serverVersion)
        public var serverVersion: Int32 = 0
        /// Declared `assign` before the Swift rewrite (a dangling-pointer risk);
        /// strong now, with no change on the wire.
        @objc(serverReadableVersion)
        public var serverReadableVersion: String!
        @objc(swiftEnabledInLookinServer)
        public var swiftEnabledInLookinServer: Int32 = 0
        @objc(screenshot)
        public var screenshot: LookinImage!
        @objc(appIcon)
        public var appIcon: LookinImage!
        @objc(appName)
        public var appName: String!
        @objc(appBundleIdentifier)
        public var appBundleIdentifier: String!
        @objc(deviceDescription)
        public var deviceDescription: String!
        @objc(deviceModelIdentifier)
        public var deviceModelIdentifier: String!
        @objc(osDescription)
        public var osDescription: String!
        @objc(osMainVersion)
        public var osMainVersion: UInt = 0
        @objc(deviceType)
        public var deviceType: LookinAppInfoDevice = .simulator
        @objc(screenWidth)
        public var screenWidth: Double = 0
        @objc(screenHeight)
        public var screenHeight: Double = 0
        @objc(screenScale)
        public var screenScale: Double = 0
        @objc(cachedTimestamp)
        public var cachedTimestamp: TimeInterval = 0
        /// Zero for older/unsupported servers; currently 1 for gesture capture.
        @objc(gestureDebugProtocolVersion)
        public var gestureDebugProtocolVersion: UInt = 0

        override public init() {
            super.init()
        }

        // MARK: NSCopying

        @objc(copyWithZone:)
        public func copy(with _: NSZone? = nil) -> Any {
            let newAppInfo = LookinAppInfo()
            newAppInfo.appIcon = appIcon
            newAppInfo.gestureDebugProtocolVersion = gestureDebugProtocolVersion
            newAppInfo.appName = appName
            newAppInfo.deviceDescription = deviceDescription
            newAppInfo.deviceModelIdentifier = deviceModelIdentifier
            newAppInfo.osDescription = osDescription
            newAppInfo.osMainVersion = osMainVersion
            newAppInfo.deviceType = deviceType
            newAppInfo.screenWidth = screenWidth
            newAppInfo.screenHeight = screenHeight
            newAppInfo.screenScale = screenScale
            newAppInfo.appInfoIdentifier = appInfoIdentifier
            newAppInfo.cachedTimestamp = cachedTimestamp
            return newAppInfo
        }

        // MARK: NSSecureCoding

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            serverVersion = aDecoder.decodeCInt(forKey: "serverVersion")
            serverReadableVersion = aDecoder.decodeObject(forKey: "serverReadableVersion") as? String
            swiftEnabledInLookinServer = aDecoder.decodeCInt(forKey: "swiftEnabledInLookinServer")
            gestureDebugProtocolVersion = UInt(bitPattern: aDecoder.decodeInteger(forKey: "gestureDebugProtocolVersion"))
            let screenshotData = aDecoder.decodeObject(forKey: CodingKey_Screenshot) as? Data
            screenshot = screenshotData.flatMap { LookinImage(data: $0) }

            let appIconData = aDecoder.decodeObject(forKey: CodingKey_AppIcon) as? Data
            appIcon = appIconData.flatMap { LookinImage(data: $0) }

            appName = aDecoder.decodeObject(forKey: CodingKey_AppName) as? String
            appBundleIdentifier = aDecoder.decodeObject(forKey: "appBundleIdentifier") as? String
            deviceDescription = aDecoder.decodeObject(forKey: CodingKey_DeviceDescription) as? String
            deviceModelIdentifier = aDecoder.decodeObject(forKey: "deviceModelIdentifier") as? String
            osDescription = aDecoder.decodeObject(forKey: CodingKey_OsDescription) as? String
            osMainVersion = UInt(bitPattern: aDecoder.decodeInteger(forKey: "osMainVersion"))
            deviceType = LookinAppInfoDevice(rawValue: aDecoder.decodeInteger(forKey: CodingKey_DeviceType)) ?? .simulator
            screenWidth = aDecoder.decodeDouble(forKey: CodingKey_ScreenWidth)
            screenHeight = aDecoder.decodeDouble(forKey: CodingKey_ScreenHeight)
            screenScale = aDecoder.decodeDouble(forKey: "screenScale")
            appInfoIdentifier = UInt(bitPattern: aDecoder.decodeInteger(forKey: "appInfoIdentifier"))
            shouldUseCache = aDecoder.decodeBool(forKey: "shouldUseCache")
        }

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encodeCInt(serverVersion, forKey: "serverVersion")
            aCoder.encode(serverReadableVersion, forKey: "serverReadableVersion")
            aCoder.encodeCInt(swiftEnabledInLookinServer, forKey: "swiftEnabledInLookinServer")
            aCoder.encode(Int(bitPattern: gestureDebugProtocolVersion), forKey: "gestureDebugProtocolVersion")

            #if canImport(UIKit)
                let screenshotData = lookinPNGRepresentation(screenshot)
                aCoder.encode(screenshotData, forKey: CodingKey_Screenshot)

                let appIconData = lookinPNGRepresentation(appIcon)
                aCoder.encode(appIconData, forKey: CodingKey_AppIcon)
            #elseif os(macOS)
                let screenshotData = lookinTIFFRepresentation(screenshot)
                aCoder.encode(screenshotData, forKey: CodingKey_Screenshot)

                let appIconData = lookinTIFFRepresentation(appIcon)
                aCoder.encode(appIconData, forKey: CodingKey_AppIcon)
            #endif

            aCoder.encode(appName, forKey: CodingKey_AppName)
            aCoder.encode(appBundleIdentifier, forKey: "appBundleIdentifier")
            aCoder.encode(deviceDescription, forKey: CodingKey_DeviceDescription)
            aCoder.encode(deviceModelIdentifier, forKey: "deviceModelIdentifier")
            aCoder.encode(osDescription, forKey: CodingKey_OsDescription)
            aCoder.encode(Int(bitPattern: osMainVersion), forKey: "osMainVersion")
            aCoder.encode(deviceType.rawValue, forKey: CodingKey_DeviceType)
            aCoder.encode(screenWidth, forKey: CodingKey_ScreenWidth)
            aCoder.encode(screenHeight, forKey: CodingKey_ScreenHeight)
            aCoder.encode(screenScale, forKey: "screenScale")
            aCoder.encode(Int(bitPattern: appInfoIdentifier), forKey: "appInfoIdentifier")
            aCoder.encode(shouldUseCache, forKey: "shouldUseCache")
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }

        // MARK: Equality

        override open func isEqual(_ object: Any?) -> Bool {
            if let object = object as? NSObject, object === self {
                return true
            }
            guard let object = object as? LookinAppInfo else {
                return false
            }
            return isEqual(to: object)
        }

        override open var hash: Int {
            lookinStringHash(appName) ^ lookinStringHash(deviceDescription) ^ lookinStringHash(osDescription) ^ deviceType.rawValue
        }

        @objc(isEqualToAppInfo:)
        public func isEqual(to info: LookinAppInfo?) -> Bool {
            guard let info else {
                return false
            }
            return lookinStringsEqual(appName, info.appName)
                && lookinStringsEqual(deviceDescription, info.deviceDescription)
                && lookinStringsEqual(osDescription, info.osDescription)
                && deviceType == info.deviceType
        }

        // MARK: Current app

        @objc(currentInfoWithScreenshot:icon:localIdentifiers:)
        public class func currentInfo(withScreenshot hasScreenshot: Bool, icon hasIcon: Bool, localIdentifiers: [NSNumber]?) -> LookinAppInfo! {
            let selfIdentifier = LookinAppInfoIdentifier
            if let localIdentifiers, (localIdentifiers as NSArray).contains(NSNumber(value: selfIdentifier)) {
                let info = LookinAppInfo()
                info.appInfoIdentifier = UInt(bitPattern: selfIdentifier)
                info.shouldUseCache = true
                return info
            }

            let info = LookinAppInfo()
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, *) {
                info.gestureDebugProtocolVersion = NSClassFromString("LKS_GestureDebugService") != nil ? 1 : 0
            }
            info.serverReadableVersion = LOOKIN_SERVER_READABLE_VERSION
            // Report Swift optimization as enabled whenever the Swift-aware build
            // is compiled in. The CocoaPods subspec path defines
            // LOOKIN_SERVER_SWIFT_ENABLED; the SwiftPM / XCFramework path defines
            // SPM_LOOKIN_SERVER_ENABLED. Both imply the optimization is active,
            // matching the contract documented on -swiftEnabledInLookinServer
            // ("SPM 或 Swift Subspec → 1").
            #if LOOKIN_SERVER_SWIFT_ENABLED || SPM_LOOKIN_SERVER_ENABLED
                info.swiftEnabledInLookinServer = 1
            #else
                info.swiftEnabledInLookinServer = -1
            #endif
            info.appInfoIdentifier = UInt(bitPattern: selfIdentifier)
            info.appName = LookinAppInfoAppName()
            #if targetEnvironment(macCatalyst)
                // Ask the Mac for its own name. -[UIDevice name] is still consulted
                // as a last resort so the field is never empty, but on Catalyst it
                // only ever answers "iPad".
                info.deviceDescription = LookinAppInfoMacHostLocalizedName() ?? UIDevice.current.name
            #elseif canImport(UIKit)
                info.deviceDescription = UIDevice.current.name
            #elseif os(macOS)
                info.deviceDescription = Host.current().localizedName
            #endif
            info.deviceModelIdentifier = LookinAppInfoDeviceModelIdentifier
            info.appBundleIdentifier = Bundle.main.bundleIdentifier
            if LookinAppInfoIsSimulator() {
                info.deviceType = .simulator
            } else if LKS_MultiplatformAdapter.isMacCatalyst() {
                // Must precede the iPad check: -[UIDevice model] reports "iPad" on
                // Catalyst, so +isiPad matches a Catalyst build too and would
                // otherwise claim it first. +isMac never fires here either.
                info.deviceType = .macCatalyst
            } else if LKS_MultiplatformAdapter.isiPad() {
                info.deviceType = .iPad
            } else if LKS_MultiplatformAdapter.isMac() {
                info.deviceType = .mac
            } else {
                info.deviceType = .others
            }

            #if canImport(UIKit)
                let systemVersion = UIDevice.current.systemVersion
                #if targetEnvironment(macCatalyst)
                    // On Catalyst -[UIDevice systemVersion] answers the *macOS*
                    // version, not the iOS version Catalyst maps onto.
                    info.osDescription = "macCatalyst \(systemVersion)"
                #else
                    info.osDescription = "iOS \(systemVersion)"
                #endif
                let mainVersionStr = (systemVersion as NSString).components(separatedBy: ".").first
                info.osMainVersion = UInt(bitPattern: (mainVersionStr as NSString?)?.integerValue ?? 0)
            #elseif os(macOS)
                let operatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
                if operatingSystemVersion.patchVersion != 0 {
                    info.osDescription = "macOS \(operatingSystemVersion.majorVersion).\(operatingSystemVersion.minorVersion).\(operatingSystemVersion.patchVersion)"
                } else {
                    info.osDescription = "macOS \(operatingSystemVersion.majorVersion).\(operatingSystemVersion.minorVersion)"
                }
                info.osMainVersion = UInt(bitPattern: operatingSystemVersion.majorVersion)
            #endif

            let screenSize = LKS_MultiplatformAdapter.mainScreenBounds().size
            info.screenWidth = Double(screenSize.width)
            info.screenHeight = Double(screenSize.height)
            info.screenScale = Double(LKS_MultiplatformAdapter.mainScreenScale())

            if hasScreenshot {
                info.screenshot = LookinAppInfoScreenshotImage()
            }
            if hasIcon {
                info.appIcon = LookinAppInfoAppIcon()
            }

            return info
        }
    }

#endif
