import Darwin
import Foundation

/// The graphical application and service use one process-held lock until their
/// transport shuts down. A peer must never replace another owner's connections.
@objc(LKInspectionConnectionOwnership)
@MainActor
public final class InspectionConnectionOwnership: NSObject {
    @objc(sharedOwnership) public static let shared = InspectionConnectionOwnership()
    private var ownership: InspectionFileLock?

    @objc public func acquire() throws {
        guard ownership == nil else { return }
        let defaultSocket = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/LookInside/Inspection/run/lookinside-inspection.sock").path
        let paths = try InspectionRuntimePaths(socketPath: defaultSocket)
        try paths.prepareDirectory()
        let ownership: InspectionFileLock
        do { ownership = try InspectionFileLock(path: paths.directory.appendingPathComponent("connection-owner.lock").path) }
        catch let failure as InspectionFailure where failure.code == "service.inUse" {
            throw InspectionFailure(code: "service.ownerConflict", message: "Another LookInside process owns the target connections. Quit that application or stop its inspection service, then retry.")
        }
        try rejectLegacyHost()
        self.ownership = ownership
    }

    @objc public func releaseOwnership() {
        ownership = nil
    }

    private func rejectLegacyHost() throws {
        let legacyPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/LookInside/Host/run/lookinside-host-mcp.sock").path
        var address = try InspectionSocketAddress(path: legacyPath)
        let descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw InspectionFailure.internalError }
        defer { close(descriptor) }
        _ = fcntl(descriptor, F_SETFL, O_NONBLOCK)
        guard address.withAddress({ connect(descriptor, $0, $1) }) == 0 else {
            guard errno == ENOENT || errno == ECONNREFUSED else {
                throw InspectionFailure(code: "service.ownerConflict", message: "An existing LookInside bridge may still own target connections. Quit it before starting headless inspection.")
            }
            return
        }
        var processIdentifier: pid_t = 0
        var length = socklen_t(MemoryLayout<pid_t>.size)
        guard getsockopt(descriptor, SOL_LOCAL, LOCAL_PEERPID, &processIdentifier, &length) == 0,
              processIdentifier == getpid()
        else {
            throw InspectionFailure(code: "service.ownerConflict", message: "The graphical LookInside bridge is running. Quit it before using the headless service.")
        }
    }
}
