import AppKit
import Foundation
import LookInsideInspectionCore
import LookInsideInspectionProtocol

@objc(LKHeadlessFixtureApplication)
private final class HeadlessFixtureApplication: InspectableApp {
    var isAvailable = true
    var captureCount = 0
    var requestDelay: Double = 0.01

    init(transport: String) {
        super.init()
        let information = LookinAppInfo()
        information.appInfoIdentifier = 123_456
        information.appName = "Fixture application"
        information.appBundleIdentifier = "com.lookinside.fixture"
        information.deviceType = .mac
        appInfo = information
        transportIdentifier = transport
    }

    override func performInspectionRequest(withType requestType: UInt32, payload _: Any!) -> RACSignal<AnyObject>! {
        precondition(Thread.isMainThread)
        let response: AnyObject
        if requestType == UInt32(LookinRequestTypeHierarchy) {
            captureCount += 1
            let hierarchy = LookinHierarchyInfo()
            hierarchy.appInfo = appInfo
            let root = LookinDisplayItem()
            let object = LookinObject()
            object.oid = 20
            object.classChainList = ["NSButton", "NSView", "NSObject"]
            root.viewObject = object
            root.frame = CGRect(x: 4, y: 5, width: 40 + captureCount, height: 30)
            root.representedAsKeyWindow = true
            hierarchy.displayItems = [root]
            response = hierarchy
        } else {
            let detail = LookinDisplayItemDetail()
            detail.displayItemOid = 20
            let attribute = LookinAttribute()
            attribute.identifier = "title"
            attribute.displayTitle = "Title"
            attribute.attrType = .nsString
            attribute.value = "Fixture button"
            let section = LookinAttributesSection()
            section.identifier = "content"
            section.attributes = [attribute]
            let group = LookinAttributesGroup()
            group.identifier = "view"
            group.attrSections = [section]
            detail.attributesGroupList = [group]
            let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 2, bitsPerSample: 8, samplesPerPixel: 4,
                                          hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
            for column in 0 ..< 2 {
                for row in 0 ..< 2 {
                    bitmap.setColor(.red, atX: column, y: row)
                }
            }
            let image = NSImage(size: NSSize(width: 2, height: 2))
            image.addRepresentation(bitmap)
            detail.groupScreenshot = image
            response = [detail] as NSArray
        }
        return RACSignal<AnyObject>.return(response).delay(requestDelay).deliverOnMainThread()
    }
}

let socketPath = try CommandLine.arguments.dropFirst().first ?? InspectionRuntimePaths().socketPath
try MainActor.assumeIsolated {
    let applications = [HeadlessFixtureApplication(transport: "fixture:first"), HeadlessFixtureApplication(transport: "fixture:second")]
    let backend = InspectionServiceBackend(discoverApplications: { applications }, isConnected: { ($0 as? HeadlessFixtureApplication)?.isAvailable == true })
    let supportedMethods = CommandLine.arguments.contains("--status-only") ? ["service.status"] : InspectionCapabilities.methods
    let server = try InspectionSocketServer(paths: InspectionRuntimePaths(socketPath: socketPath), idleTimeout: 10, supportedMethods: supportedMethods) { request, clientIdentifier in
        if request.method == "fixture.incompatible" {
            let metadata = try! JSONDecoder().decode(InspectionMetadata.self, from: Data(#"{"schemaVersion":2}"#.utf8))
            return InspectionResponse(identifier: request.identifier, result: .bool(true), error: nil, metadata: metadata)
        }
        if request.method == "fixture.state" {
            return .success(identifier: request.identifier, result: .object(["headless": .bool(NSApp == nil),
                                                                             "captures": .integer(Int64(applications.reduce(0) { $0 + $1.captureCount }))]))
        }
        if request.method == "fixture.disconnect" {
            for application in applications where application.transportIdentifier == request.parameters?["transportIdentifier"]?.stringValue {
                application.isAvailable = false
            }
            return .success(identifier: request.identifier, result: .bool(true))
        }
        if request.method == "fixture.delay", case let .double(seconds)? = request.parameters?["seconds"] {
            applications.forEach { $0.requestDelay = seconds }
            return .success(identifier: request.identifier, result: .bool(true))
        }
        return await backend.handle(request, clientIdentifier: clientIdentifier)
    }
    backend.instanceIdentifier = server.instanceIdentifier
    server.onClientDisconnect = { backend.disconnect(clientIdentifier: $0) }
    server.onStop = { backend.stop(); CFRunLoopStop(CFRunLoopGetMain()) }
    try server.start()
    withExtendedLifetime(server) { CFRunLoopRun() }
}
