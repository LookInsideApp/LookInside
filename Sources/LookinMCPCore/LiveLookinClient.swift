import Foundation
import LookinCore
import Darwin

/// Live connection to a `LookinServer` running inside a Debug build. Speaks the same
/// framed NSSecureCoding protocol the macOS LookInside.app uses (see
/// `LookInside/Connection/LKConnectionManager.m`), but stripped to a synchronous,
/// headless API suitable for an MCP tool dispatch.
///
/// Why we don't reuse `LKConnectionManager`:
///   - It depends on ReactiveObjC (`RACSignal`), pulling a heavy dep into the SPM build.
///   - It performs a client-side license handshake before non-Ping requests; that gate
///     is enforced by the Mac app, not by `LookinServer` itself (`Sources/LookinServer/
///     Server/Connection/LKS_RequestHandler.m` has no license check). A separate Debug
///     tooling client is free to skip it.
///
/// Reachable ports (defined in `LookinDefines.h`):
///   - Simulator: 47164–47169
///   - USB device: 47175–47179
///   - macOS target: 47170–47174
public final class LiveLookinClient: NSObject, HierarchyProvider, Lookin_PTChannelDelegate {

    public struct DiscoveredApp {
        public let port: Int
        public let platform: String   // "simulator" | "macos" | "device"
        public let appInfo: LookinAppInfo
    }

    public var isLive: Bool { true }

    private let queue = DispatchQueue(label: "lookin.mcp.client", qos: .userInitiated)
    private let connectTimeout: TimeInterval
    private let requestTimeout: TimeInterval

    private var channel: Lookin_PTChannel?
    private var pendingRequests: [UInt32: PendingRequest] = [:]
    private var hierarchyCache: LookinHierarchyInfo?
    private var indexCache: HierarchyIndex?

    public init(connectTimeout: TimeInterval = 1.5, requestTimeout: TimeInterval = 10) {
        self.connectTimeout = connectTimeout
        self.requestTimeout = requestTimeout
        super.init()
    }

    // MARK: Discovery & connect

    public func discover() -> [DiscoveredApp] {
        let ranges = [
            ("simulator", LookinSimulatorIPv4PortNumberStart...LookinSimulatorIPv4PortNumberEnd),
            ("macos",     LookinMacIPv4PortNumberStart...LookinMacIPv4PortNumberEnd),
            ("device",    LookinUSBDeviceIPv4PortNumberStart...LookinUSBDeviceIPv4PortNumberEnd),
        ]
        var found: [DiscoveredApp] = []
        for (platform, range) in ranges {
            for port in range {
                guard let client = try? Self.makeAndConnect(port: Int(port), timeout: connectTimeout) else { continue }
                defer { client.disconnect() }
                if let app = try? client.fetchAppInfo() {
                    found.append(DiscoveredApp(port: Int(port), platform: platform, appInfo: app))
                }
            }
        }
        return found
    }

    /// Connect to the first reachable app, preferring simulator → macOS → device.
    @discardableResult
    public func connectToFirstAvailable() throws -> DiscoveredApp {
        let apps = discover()
        guard let pick = apps.first else { throw HierarchyProviderError.noTargetApp }
        try connect(port: pick.port)
        return pick
    }

    public func connect(port: Int) throws {
        disconnect()
        let ch = try Self.openChannel(port: port, timeout: connectTimeout, delegate: self)
        channel = ch
    }

    public func disconnect() {
        channel?.close()
        channel = nil
        pendingRequests.removeAll()
        hierarchyCache = nil
        indexCache = nil
    }

    // MARK: HierarchyProvider

    public func appInfo() throws -> LookinAppInfo { try fetchAppInfo() }

    public func hierarchy() throws -> LookinHierarchyInfo {
        if let cached = hierarchyCache { return cached }
        let resp = try sendRequest(type: UInt32(LookinRequestTypeHierarchy), payload: nil)
        guard let info = resp.data as? LookinHierarchyInfo else {
            throw HierarchyProviderError.decodeFailure(reason: "expected LookinHierarchyInfo, got \(String(describing: type(of: resp.data)))")
        }
        hierarchyCache = info
        indexCache = HierarchyIndex(info: info)
        return info
    }

    public func elementDetails(oid: UInt) throws -> ElementDetails? {
        let info = try hierarchy()
        let index = indexCache ?? HierarchyIndex(info: info)
        guard let item = index.find(oid: oid) else { return nil }
        // The hierarchy response already carries attribute groups and screenshots for each item.
        return ElementDetails(item: item,
                              attributeGroups: (item.attributesGroupList as? [LookinAttributesGroup]) ?? [],
                              soloScreenshot: item.soloScreenshot)
    }

    public func highlight(oid: UInt, durationMs: Int) throws {
        // No first-class highlight request type exists yet on the server. Real
        // highlight runs through the macOS app's preview overlay. Until LookinServer
        // gains a server-side highlight request (tracked as a follow-up), this is a
        // no-op rather than a lie.
        throw HierarchyProviderError.unsupported("highlight requires a server-side request type — coming in a follow-up PR.")
    }

    public func screenshot() throws -> PlatformImage? {
        try fetchAppInfo().screenshot
    }

    // MARK: Internals

    fileprivate func fetchAppInfo() throws -> LookinAppInfo {
        let resp = try sendRequest(type: UInt32(LookinRequestTypeApp), payload: nil)
        guard let info = resp.data as? LookinAppInfo else {
            throw HierarchyProviderError.decodeFailure(reason: "expected LookinAppInfo, got \(String(describing: type(of: resp.data)))")
        }
        return info
    }

    private static func makeAndConnect(port: Int, timeout: TimeInterval) throws -> ProbeClient {
        let probe = ProbeClient()
        let channel = try Self.openChannel(port: port, timeout: timeout, delegate: probe)
        probe.channel = channel
        return probe
    }

    fileprivate static func openChannel(port: Int,
                                        timeout: TimeInterval,
                                        delegate: Lookin_PTChannelDelegate) throws -> Lookin_PTChannel {
        guard let channel = Lookin_PTChannel() else {
            throw HierarchyProviderError.transport(underlying: NSError(domain: "Lookin", code: -1,
                                                                       userInfo: [NSLocalizedDescriptionKey: "Failed to allocate Peertalk channel."]))
        }
        channel.delegate = delegate
        channel.targetPort = port
        let sem = DispatchSemaphore(value: 0)
        var connectError: Error?
        // Loopback in network byte order — Peertalk wants host byte order, so use INADDR_LOOPBACK directly.
        channel.connect(toPort: in_port_t(port), iPv4Address: in_addr_t(INADDR_LOOPBACK)) { error, _ in
            connectError = error
            sem.signal()
        }
        if sem.wait(timeout: .now() + timeout) == .timedOut {
            channel.close()
            throw HierarchyProviderError.transport(underlying: NSError(domain: "Lookin", code: -1,
                                                                       userInfo: [NSLocalizedDescriptionKey: "Connect to port \(port) timed out."]))
        }
        if let e = connectError { throw HierarchyProviderError.transport(underlying: e) }
        return channel
    }

    fileprivate func sendRequest(type: UInt32, payload: Any?) throws -> LookinConnectionResponseAttachment {
        guard let channel else { throw HierarchyProviderError.noTargetApp }
        let attachment = LookinConnectionAttachment()
        attachment.data = payload
        let data: Data
        do {
            data = try NSKeyedArchiver.archivedData(withRootObject: attachment, requiringSecureCoding: true)
        } catch {
            throw HierarchyProviderError.transport(underlying: error)
        }
        let tag = UInt32(truncatingIfNeeded: UInt64(Date().timeIntervalSince1970 * 1000))
        let dispatchPayload = data.withUnsafeBytes { raw -> DispatchData in
            DispatchData(bytes: raw)
        }
        let sem = DispatchSemaphore(value: 0)
        let pending = PendingRequest()
        queue.sync { pendingRequests[tag] = pending }
        channel.sendFrame(ofType: type, tag: tag, withPayload: dispatchPayload as __DispatchData) { err in
            if let err = err {
                self.queue.sync {
                    pending.error = err
                    self.pendingRequests.removeValue(forKey: tag)
                }
                sem.signal()
            }
        }
        if sem.wait(timeout: .now() + requestTimeout) == .timedOut, pending.response == nil {
            queue.sync { pendingRequests.removeValue(forKey: tag) }
            throw HierarchyProviderError.timeout(requestType: type)
        }
        if let response = pending.response { return response }
        if let err = pending.error { throw HierarchyProviderError.transport(underlying: err) }
        // Wait for the response delivered via delegate callback; if we got here without one, it's a transport issue.
        // (sendFrame's callback fires before the response — we need to wait for the read path.)
        let secondSem = pending.semaphore
        if secondSem.wait(timeout: .now() + requestTimeout) == .timedOut {
            queue.sync { pendingRequests.removeValue(forKey: tag) }
            throw HierarchyProviderError.timeout(requestType: type)
        }
        if let response = pending.response { return response }
        throw HierarchyProviderError.transport(underlying: NSError(domain: "Lookin", code: -2, userInfo: [NSLocalizedDescriptionKey: "No response and no error for request \(type)."]))
    }

    // MARK: Lookin_PTChannelDelegate

    public func ioFrameChannel(_ channel: Lookin_PTChannel,
                               didReceiveFrameOfType type: UInt32,
                               tag: UInt32,
                               payload: Lookin_PTData?) {
        guard let payload else { return }
        let data = Data(bytes: payload.data, count: payload.length)
        let allowed: [AnyClass] = [
            LookinConnectionResponseAttachment.self,
            LookinHierarchyInfo.self,
            LookinDisplayItem.self, LookinAppInfo.self,
            LookinAttributesGroup.self, LookinAttribute.self, LookinObject.self,
            PlatformImage.self,
            NSArray.self, NSDictionary.self, NSString.self, NSNumber.self, NSData.self, NSValue.self,
        ]
        guard let response = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: allowed, from: data) as? LookinConnectionResponseAttachment else {
            return
        }
        queue.async {
            if let pending = self.pendingRequests.removeValue(forKey: tag) {
                pending.response = response
                pending.semaphore.signal()
            }
        }
    }

    public func ioFrameChannel(_ channel: Lookin_PTChannel, didEndWithError error: Error?) {
        queue.async {
            self.pendingRequests.values.forEach { pending in
                pending.error = error ?? NSError(domain: "Lookin", code: -3, userInfo: [NSLocalizedDescriptionKey: "Channel closed."])
                pending.semaphore.signal()
            }
            self.pendingRequests.removeAll()
            self.channel = nil
        }
    }

    private final class PendingRequest {
        var response: LookinConnectionResponseAttachment?
        var error: Error?
        let semaphore = DispatchSemaphore(value: 0)
    }
}

/// Minimal probe used during port discovery. Mirrors LiveLookinClient's frame
/// handling but holds nothing beyond the channel lifetime.
fileprivate final class ProbeClient: NSObject, Lookin_PTChannelDelegate {
    var channel: Lookin_PTChannel?
    private let queue = DispatchQueue(label: "lookin.mcp.probe")
    private var pending: [UInt32: (LookinConnectionResponseAttachment?) -> Void] = [:]

    func disconnect() { channel?.close(); channel = nil }

    func fetchAppInfo() throws -> LookinAppInfo {
        guard let channel else { throw HierarchyProviderError.noTargetApp }
        let attachment = LookinConnectionAttachment()
        let data = try NSKeyedArchiver.archivedData(withRootObject: attachment, requiringSecureCoding: true)
        let tag = UInt32.random(in: 1..<UInt32.max)
        let payload = data.withUnsafeBytes { raw -> DispatchData in
            DispatchData(bytes: raw)
        }
        let sem = DispatchSemaphore(value: 0)
        var resp: LookinConnectionResponseAttachment?
        queue.sync { pending[tag] = { resp = $0; sem.signal() } }
        channel.sendFrame(ofType: UInt32(LookinRequestTypeApp), tag: tag, withPayload: payload as __DispatchData, callback: nil)
        if sem.wait(timeout: .now() + 1.5) == .timedOut {
            queue.sync { pending.removeValue(forKey: tag) }
            throw HierarchyProviderError.timeout(requestType: UInt32(LookinRequestTypeApp))
        }
        guard let info = resp?.data as? LookinAppInfo else { throw HierarchyProviderError.noTargetApp }
        return info
    }

    func ioFrameChannel(_ channel: Lookin_PTChannel, didReceiveFrameOfType type: UInt32, tag: UInt32, payload: Lookin_PTData?) {
        guard let payload else { return }
        let data = Data(bytes: payload.data, count: payload.length)
        let allowed: [AnyClass] = [
            LookinConnectionResponseAttachment.self, LookinAppInfo.self, PlatformImage.self,
            NSArray.self, NSDictionary.self, NSString.self, NSNumber.self, NSData.self,
        ]
        let response = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: allowed, from: data) as? LookinConnectionResponseAttachment
        queue.async {
            if let cb = self.pending.removeValue(forKey: tag) { cb(response) }
        }
    }

    func ioFrameChannel(_ channel: Lookin_PTChannel, didEndWithError error: Error?) {
        queue.async {
            self.pending.values.forEach { $0(nil) }
            self.pending.removeAll()
        }
    }
}
