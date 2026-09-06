import AppKit
import Foundation
import LookInsideInspectionCore
import LookInsideInspectionProtocol

@objc(LKHeadlessFixtureApplication)
private final class HeadlessFixtureApplication: InspectableApp {
    var isAvailable = true
    var captureCount = 0
    var requestDelay: Double = 0.01
    var invocationCount = 0
    var modificationCount = 0
    var title = "Fixture button"
    var losesInvocationReply = false
    var returnsOnlyAlpha = false

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

    override func performInspectionRequest(withType requestType: UInt32, payload: Any!) -> RACSignal<AnyObject>! {
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
        } else if requestType == UInt32(LookinRequestTypeAllSelectorNames) {
            response = ["description", "title", "performClick:"] as NSArray
        } else if requestType == UInt32(LookinRequestTypeInvokeMethod) {
            invocationCount += 1
            if losesInvocationReply {
                return RACSignal<AnyObject>.error(NSError(domain: LookinErrorDomain, code: LookinErrCode_NoConnect))
                    .delay(requestDelay).deliverOnMainThread()
            }
            response = ["description": "Fixture invocation \(invocationCount)"] as NSDictionary
        } else {
            if let modification = payload as? LookinAttributeModification {
                modificationCount += 1
                title = modification.value as? String ?? title
            }
            let detail = LookinDisplayItemDetail()
            detail.displayItemOid = 20
            if returnsOnlyAlpha {
                detail.alphaValue = 0.25
                return RACSignal<AnyObject>.return([detail] as NSArray).delay(requestDelay).deliverOnMainThread()
            }
            let attribute = LookinAttribute()
            attribute.identifier = "title"
            attribute.displayTitle = "Title"
            attribute.attrType = .nsString
            attribute.value = title
            let editableAttribute = LookinAttribute()
            editableAttribute.identifier = "NSButton_Title_Title"
            editableAttribute.attrType = .nsString
            editableAttribute.value = title
            let section = LookinAttributesSection()
            section.identifier = "content"
            section.attributes = [attribute, editableAttribute]
            let group = LookinAttributesGroup()
            group.identifier = "view"
            group.attrSections = [section]
            detail.attributesGroupList = [group]
            let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 2, bitsPerSample: 8, samplesPerPixel: 4,
                                          hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
            for column in 0 ..< 2 {
                for row in 0 ..< 2 {
                    bitmap.setColor(NSColor(deviceRed: 1, green: 0, blue: 0, alpha: 1), atX: column, y: row)
                }
            }
            let image = NSImage(size: NSSize(width: 2, height: 2))
            image.addRepresentation(bitmap)
            detail.groupScreenshot = image
            response = requestType == UInt32(LookinRequestTypeInbuiltAttrModification) ? detail : [detail] as NSArray
        }
        return RACSignal<AnyObject>.return(response).delay(requestDelay).deliverOnMainThread()
    }
}

let socketPath = try CommandLine.arguments.dropFirst().first ?? InspectionRuntimePaths().socketPath
try MainActor.assumeIsolated {
    var applications = [HeadlessFixtureApplication(transport: "fixture:first"), HeadlessFixtureApplication(transport: "fixture:second")]
    let backend = InspectionServiceBackend(discoverApplications: { applications }, isConnected: { ($0 as? HeadlessFixtureApplication)?.isAvailable == true })
    let injectionScenario = CommandLine.arguments.firstIndex(of: "--injection").flatMap { index in
        CommandLine.arguments.indices.contains(index + 1) ? CommandLine.arguments[index + 1] : nil
    }
    var injectionCount = 0
    var processReadCount = 0
    if let injectionScenario {
        applications[0].transportIdentifier = "mac"
        applications[1].transportIdentifier = "mac"
        applications[1].appInfo.appInfoIdentifier = 654_321
        backend.injection = InspectionInjection(environment: InspectionInjectionEnvironment(process: { identifier in
            processReadCount += 1
            if injectionScenario == "absent" || (injectionScenario == "exited" && injectionCount > 0) {
                throw InspectionFailure(code: "injection.targetNotFound", message: "The fixture process exited.")
            }
            let changed = (injectionScenario == "changed" && processReadCount > 1)
                || (injectionScenario == "reused" && injectionCount > 0)
            return InjectionProcessIdentity(processIdentifier: identifier, startIdentifier: changed ? "200:1" : "100:1",
                                            executablePath: "/Applications/Fixture.app/Contents/MacOS/Fixture",
                                            architecture: CPU_TYPE_ARM64, userIdentifier: geteuid())
        }, authorize: {
            if injectionScenario == "license" {
                throw InspectionFailure(code: "injection.licenseRequired", message: "Activate LookInside Pro first.")
            }
        }, helperStatus: {
            let state = ["missing", "requiresApproval", "notRegistered", "unsupportedLocation"].contains(injectionScenario) ? injectionScenario : "enabled"
            return .object(["state": .string(state)])
        }, framework: { _ in
            if injectionScenario == "framework" {
                throw InspectionFailure(code: "injection.preparationRequired", message: "Prepare the fixture framework first.")
            }
            return URL(fileURLWithPath: "/fixture/LookInsideServer.framework")
        }, submit: { identity, _ in
            injectionCount += 1
            if injectionScenario == "delayed" || injectionScenario == "cancelled" {
                try await Task.sleep(for: .milliseconds(350))
            }
            if injectionScenario == "lostReply" {
                throw InspectionFailure(code: "injection.helperTimeout", message: "The fixture helper reply was lost.")
            }
            if injectionScenario == "denied" {
                throw InspectionFailure(code: "injection.denied", message: "The fixture helper rejected the request.",
                                        details: ["injectionStage": .string("notSubmitted")])
            }
            if ["otherProcess", "portReused"].contains(injectionScenario) {
                applications[0].appInfo.processIdentifier = injectionScenario == "portReused" ? 12345 : 54321
                applications[0].appInfo.processStartIdentifier = injectionScenario == "portReused" ? "200:1" : "100:1"
                applications[1].appInfo.processIdentifier = 65432
                applications[1].appInfo.processStartIdentifier = "100:2"
            }
            guard ["ready", "delayed"].contains(injectionScenario) else { return }
            applications[0].appInfo.processIdentifier = NSNumber(value: identity.processIdentifier)
            applications[0].appInfo.processStartIdentifier = identity.startIdentifier
            // A second application has the same visible name but a different PID.
            applications[1].appInfo.processIdentifier = 54321
            applications[1].appInfo.processStartIdentifier = "100:2"
        }))
    }

    let supportedMethods = CommandLine.arguments.contains("--status-only") ? ["service.status"] : InspectionCapabilities.methods
    let server = try InspectionSocketServer(paths: InspectionRuntimePaths(socketPath: socketPath), idleTimeout: 10, supportedMethods: supportedMethods) { request, clientIdentifier in
        if request.method == "injection.inject", CommandLine.arguments.contains("--lose-service-reply") {
            Darwin.exit(73)
        }
        if request.method == "fixture.incompatible" {
            let metadata = try! JSONDecoder().decode(InspectionMetadata.self, from: Data(#"{"schemaVersion":2}"#.utf8))
            return InspectionResponse(identifier: request.identifier, result: .bool(true), error: nil, metadata: metadata)
        }
        if request.method == "fixture.state" {
            return .success(identifier: request.identifier, result: .object(["headless": .bool(NSApp == nil),
                                                                             "injections": .integer(Int64(injectionCount)),
                                                                             "captures": .integer(Int64(applications.reduce(0) { $0 + $1.captureCount })),
                                                                             "invocations": .integer(Int64(applications.reduce(0) { $0 + $1.invocationCount })),
                                                                             "modifications": .integer(Int64(applications.reduce(0) { $0 + $1.modificationCount })),
                                                                             "sessions": .integer(Int64(backend.sessions.count))]))
        }
        if request.method == "fixture.loseInvocationReply" {
            applications.forEach { $0.losesInvocationReply = true }
            return .success(identifier: request.identifier, result: .bool(true))
        }
        if request.method == "fixture.partialDetails" {
            applications.forEach { $0.returnsOnlyAlpha = true }
            return .success(identifier: request.identifier, result: .bool(true))
        }
        if request.method == "fixture.reconnect", let transport = request.parameters?["transportIdentifier"]?.stringValue,
           let index = applications.firstIndex(where: { $0.transportIdentifier == transport })
        {
            let previous = applications[index]
            let replacement = HeadlessFixtureApplication(transport: transport)
            applications[index] = replacement
            for session in backend.sessions.values where session.inspectableApp === previous {
                session.replaceInspectableApp(replacement)
            }
            return .success(identifier: request.identifier, result: .bool(true))
        }
        if request.method == "fixture.disconnect" {
            for application in applications where application.transportIdentifier == request.parameters?["transportIdentifier"]?.stringValue {
                application.isAvailable = false
                for session in backend.sessions.values where session.inspectableApp === application {
                    session.markMirrorDisconnected("Fixture target disconnected.")
                    NotificationCenter.default.post(name: InspectionSession.didDisconnectNotification, object: session)
                }
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
    backend.publish = { [weak server] event in server?.publish(event) }
    server.onClientDisconnect = { backend.disconnect(clientIdentifier: $0) }
    server.onStop = { backend.stop(); CFRunLoopStop(CFRunLoopGetMain()) }
    try server.start()
    withExtendedLifetime(server) { CFRunLoopRun() }
}
