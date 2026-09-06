import AppKit
import Darwin
import Foundation
import LookInsideInspectionCore
import LookInsideInspectionProtocol
import Testing

@MainActor
struct InspectionModelTransferTests {
    @Test func `large graphical models preserve pixels across the socket and report transfer cost`() async throws {
        let hierarchy = LookinHierarchyInfo()
        hierarchy.appInfo = LookinAppInfo()
        let root = LookinDisplayItem()
        root.nodeKind = .window
        var children: [LookinDisplayItem] = []
        for index in 0 ..< 10000 {
            let child = LookinDisplayItem()
            child.nodeKind = .view
            let object = LookinObject()
            object.oid = UInt(index + 1)
            object.classChainList = ["NSView", "NSObject"]
            child.viewObject = object
            child.frame = CGRect(x: index % 100, y: index / 100, width: 256, height: 256)
            if index < 32 {
                let bitmap = try #require(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 256, pixelsHigh: 256,
                                                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
                let pixels = try #require(bitmap.bitmapData)
                var sequence = UInt32(index + 1)
                for offset in 0 ..< (bitmap.bytesPerRow * bitmap.pixelsHigh) {
                    sequence = sequence &* 1_664_525 &+ 1_013_904_223
                    pixels[offset] = offset % 4 == 3 ? 255 : UInt8(truncatingIfNeeded: sequence >> 24)
                }
                let image = NSImage(size: NSSize(width: 256, height: 256))
                image.addRepresentation(bitmap)
                child.groupScreenshot = image
            }
            children.append(child)
        }
        root.subitems = children
        hierarchy.displayItems = [root]
        let start = ContinuousClock.now
        let archive = try InspectionModelArchive.encode(hierarchy)
        let encoded = ContinuousClock.now
        let directDecodeStart = ContinuousClock.now
        try autoreleasepool {
            let direct = try #require(InspectionModelArchive.decode(archive) as? LookinHierarchyInfo)
            #expect(direct.displayItems.first?.subitems.count == 10000)
        }
        let directDecodeTime = directDecodeStart.duration(to: .now)
        let directory = URL(fileURLWithPath: "/tmp/codex").appendingPathComponent("large-model-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let paths = try InspectionRuntimePaths(socketPath: directory.appendingPathComponent("service.sock").path)
        let store = InspectionTransferStore()
        let server = InspectionSocketServer(paths: paths) { request, owner in
            do {
                if request.method == "model" {
                    return try .success(identifier: request.identifier, result: .encoding(store.publish(archive, owner: owner)))
                }
                let identifier = request.parameters?["transferIdentifier"]?.stringValue ?? ""
                if request.method == "transfer.release" {
                    try store.release(identifier: identifier, owner: owner)
                    return .success(identifier: request.identifier, result: .bool(true))
                }
                let offset = Int(request.parameters?["offset"]?.integerValue ?? -1)
                let chunk = try store.read(identifier: identifier, offset: offset, owner: owner)
                return .success(identifier: request.identifier, result: .object(["offset": .integer(Int64(offset)), "data": .string(chunk.base64EncodedString())]))
            } catch {
                return .init(identifier: request.identifier, result: nil, error: .internalError, metadata: nil)
            }
        }
        try server.start()
        defer { server.stop() }
        let connection = InspectionServiceConnection()
        try connection.connect(socketPath: paths.socketPath)
        defer { connection.close() }
        let transferStart = ContinuousClock.now
        let response = try await connection.request("model")
        let manifestValue = try #require(response.result)
        let manifest = try manifestValue.decode(InspectionTransferManifest.self)
        let received = try await connection.download(manifest)
        let transferred = ContinuousClock.now
        let decoded = try #require(InspectionModelArchive.decode(received) as? LookinHierarchyInfo)
        let ready = ContinuousClock.now
        #expect(decoded.displayItems.first?.subitems.count == 10000)
        #expect(decoded.displayItems.first?.subitems.filter { $0.groupScreenshot != nil }.count == 32)
        #expect(received == archive)
        #expect(archive.count > 5 * 1024 * 1024)
        #expect(NSApp == nil)
        var usage = rusage()
        getrusage(RUSAGE_SELF, &usage)
        let metrics: [String: Any] = [
            "nodes": 10001, "images": 32, "archiveBytes": archive.count,
            "encodeSeconds": seconds(start.duration(to: encoded)),
            "directDecodeSeconds": seconds(directDecodeTime),
            "socketTransferSeconds": seconds(transferStart.duration(to: transferred)),
            "receivedDecodeSeconds": seconds(transferred.duration(to: ready)),
            "modelReadySeconds": seconds(start.duration(to: encoded)) + seconds(transferStart.duration(to: ready)),
            "processPeakResidentBytes": usage.ru_maxrss,
        ]
        let metricData = try JSONSerialization.data(withJSONObject: metrics, options: .sortedKeys)
        FileHandle.standardError.write(Data("INSPECTION_MODEL_BENCHMARK ".utf8) + metricData + Data([10]))
    }

    private func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }

    @Test func `a multi-megabyte archive transfers in bounded chunks and verifies before becoming visible`() throws {
        let payload = Data((0 ..< (5 * 1024 * 1024)).map { UInt8(truncatingIfNeeded: $0) })
        let store = InspectionTransferStore()
        let manifest = try store.publish(payload, owner: "first")
        var assembler = try InspectionTransferAssembler(manifest: manifest)
        #expect(throws: InspectionFailure.self) { try assembler.finish() }
        while !assembler.isComplete {
            let offset = assembler.nextOffset
            let chunk = try store.read(identifier: manifest.transferIdentifier, offset: offset, owner: "first")
            #expect(chunk.count <= 256 * 1024)
            try assembler.append(chunk, offset: offset)
        }
        #expect(try assembler.finish() == payload)
        #expect(throws: InspectionFailure.self) { try store.read(identifier: manifest.transferIdentifier, offset: 0, owner: "second") }
        try store.release(identifier: manifest.transferIdentifier, owner: "first")
        #expect(throws: InspectionFailure.self) { try store.read(identifier: manifest.transferIdentifier, offset: 0, owner: "first") }
    }

    @Test func `partial damaged out-of-order and expired uploads cannot enter the model decoder`() throws {
        var now: TimeInterval = 0
        let store = InspectionTransferStore(lifetime: 5, clock: { now })
        let payload = Data("complete archive".utf8)
        let manifest = InspectionTransferManifest(data: payload)
        try store.beginUpload(manifest, owner: "first")
        #expect(throws: InspectionFailure.self) {
            try store.append(payload, offset: 1, identifier: manifest.transferIdentifier, owner: "first")
        }
        try store.append(Data(repeating: 0, count: payload.count), offset: 0, identifier: manifest.transferIdentifier, owner: "first")
        #expect(throws: InspectionFailure.self) { try store.consumeUpload(identifier: manifest.transferIdentifier, owner: "first") }
        try store.beginUpload(manifest, owner: "first")
        try store.append(payload.prefix(4), offset: 0, identifier: manifest.transferIdentifier, owner: "first")
        #expect(throws: InspectionFailure.self) { try store.consumeUpload(identifier: manifest.transferIdentifier, owner: "first") }
        try store.beginUpload(manifest, owner: "first")
        try store.append(payload, offset: 0, identifier: manifest.transferIdentifier, owner: "first")
        now = 6
        #expect(throws: InspectionFailure.self) { try store.consumeUpload(identifier: manifest.transferIdentifier, owner: "first") }
        try store.beginUpload(manifest, owner: "first")
        try store.append(payload, offset: 0, identifier: manifest.transferIdentifier, owner: "first")
        #expect(try store.consumeUpload(identifier: manifest.transferIdentifier, owner: "first") == payload)
    }

    @Test func `connection cleanup releases reserved capacity without disturbing another client`() throws {
        let store = InspectionTransferStore()
        let first = try store.publish(Data("first".utf8), owner: "first")
        let second = try store.publish(Data("second".utf8), owner: "second")
        store.disconnect(owner: "first")
        #expect(throws: InspectionFailure.self) { try store.read(identifier: first.transferIdentifier, offset: 0, owner: "first") }
        #expect(try store.read(identifier: second.transferIdentifier, offset: 0, owner: "second") == Data("second".utf8))
        let damaged = InspectionTransferManifest(data: Data("expected".utf8))
        var assembler = try InspectionTransferAssembler(manifest: damaged)
        try assembler.append(Data("modified".utf8), offset: 0)
        #expect(throws: InspectionFailure.self) { try assembler.finish() }
    }

    @Test func `one connection accepts concurrent requests and events without interleaving frames`() async throws {
        let directory = URL(fileURLWithPath: "/tmp/codex").appendingPathComponent("inspection-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let paths = try InspectionRuntimePaths(socketPath: directory.appendingPathComponent("service.sock").path)
        let server = InspectionSocketServer(paths: paths) { request, _ in
            if request.method == "slow" {
                try? await Task.sleep(for: .milliseconds(100))
            }
            return .success(identifier: request.identifier, result: .string(request.method))
        }
        try server.start()
        defer { server.stop() }
        let connection = InspectionServiceConnection()
        try connection.connect(socketPath: paths.socketPath)
        defer { connection.close() }
        var events: [InspectionEvent] = []
        connection.onEvent = { events.append($0) }
        async let slow = connection.request("slow")
        async let fast = connection.request("fast")
        let firstResponse = try await fast
        server.publish(InspectionEvent(topic: "hierarchy.reloaded", payload: ["hierarchyRevision": .integer(2)]))
        let secondResponse = try await slow
        #expect(firstResponse.result == .string("fast"))
        #expect(secondResponse.result == .string("slow"))
        #expect(events.count == 1)
        #expect(connection.isConnected)
    }
}
