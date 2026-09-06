import Darwin
import Foundation

public struct InspectionRuntimePaths: Sendable {
    public let directory: URL
    public let socketPath: String

    public init(socketPath: String? = nil) throws {
        if let socketPath {
            guard socketPath.hasPrefix("/") else {
                throw InspectionFailure(code: "service.invalidPath", message: "The socket path must be absolute.")
            }
            self.socketPath = socketPath
            directory = URL(fileURLWithPath: socketPath).deletingLastPathComponent()
        } else {
            if let configuredDirectory = ProcessInfo.processInfo.environment["LOOKINSIDE_INSPECTION_RUNTIME_DIRECTORY"] {
                guard configuredDirectory.hasPrefix("/") else { throw InspectionFailure(code: "service.invalidPath", message: "LOOKINSIDE_INSPECTION_RUNTIME_DIRECTORY must be absolute.") }
                directory = URL(fileURLWithPath: configuredDirectory, isDirectory: true)
            } else {
                directory = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent("Library/Application Support/LookInside/Inspection/run", isDirectory: true)
            }
            self.socketPath = directory.appendingPathComponent("lookinside-inspection.sock").path
        }
        _ = try InspectionSocketAddress(path: self.socketPath)
    }

    public func prepareDirectory() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        var information = stat()
        guard lstat(directory.path, &information) == 0,
              information.st_mode & S_IFMT == S_IFDIR, information.st_uid == geteuid(),
              chmod(directory.path, 0o700) == 0
        else {
            throw InspectionFailure(code: "service.invalidPath", message: "The runtime directory must be owned by the current user and must not be a symbolic link.")
        }
    }
}

struct InspectionSocketAddress {
    var address = sockaddr_un()

    init(path: String) throws {
        let pathBytes = Array(path.utf8) + [0]
        guard pathBytes.count <= MemoryLayout.size(ofValue: address.sun_path) else {
            throw InspectionFailure(code: "service.invalidPath", message: "The Unix socket path is too long.")
        }
        address.sun_family = sa_family_t(AF_UNIX)
        address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        withUnsafeMutableBytes(of: &address.sun_path) { destination in
            destination.copyBytes(from: pathBytes)
        }
    }

    mutating func withAddress<Result>(_ operation: (UnsafePointer<sockaddr>, socklen_t) -> Result) -> Result {
        withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                operation($0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
    }
}

/// The file remains in place after release: removing it would let another process
/// lock a different inode while an existing waiter still owns the original one.
public final class InspectionFileLock {
    private var descriptor: Int32 = -1

    public init(path: String) throws {
        let descriptor = open(path, O_CREAT | O_RDWR | O_CLOEXEC | O_NOFOLLOW, 0o600)
        guard descriptor >= 0 else {
            throw InspectionFailure(code: "service.invalidPath", message: "Cannot open the inspection ownership lock.")
        }
        var information = stat()
        guard fstat(descriptor, &information) == 0, information.st_uid == geteuid(),
              information.st_mode & S_IFMT == S_IFREG, fchmod(descriptor, 0o600) == 0
        else {
            close(descriptor)
            throw InspectionFailure(code: "service.invalidPath", message: "The ownership lock must be a regular file owned by the current user.")
        }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            close(descriptor)
            throw InspectionFailure(code: "service.inUse", message: "An inspection service already owns this socket.")
        }
        self.descriptor = descriptor
    }

    deinit {
        if descriptor >= 0 {
            close(descriptor)
        }
    }
}
