import Darwin
import Foundation

public enum InspectionServiceLauncher {
    public static func bundledServiceURL(executableURL: URL) throws -> URL {
        let resolvedExecutable = executableURL.resolvingSymlinksInPath()
        let contentsDirectory = resolvedExecutable.deletingLastPathComponent().deletingLastPathComponent()
        guard contentsDirectory.lastPathComponent == "Contents",
              contentsDirectory.deletingLastPathComponent().pathExtension == "app"
        else {
            throw InspectionFailure(code: "service.launchFailed", message: "Automatic startup requires the CLI inside LookInside.app. Use --socket-path for a separately started service.")
        }
        let serviceURL = contentsDirectory.appendingPathComponent("MacOS/lookinside-service")
        guard FileManager.default.isExecutableFile(atPath: serviceURL.path) else {
            throw InspectionFailure(code: "service.launchFailed", message: "This LookInside.app does not contain an executable inspection service.")
        }
        return serviceURL
    }

    /// A separate session and /dev/null standard streams keep the service alive
    /// after the originating terminal or CLI process exits.
    public static func launch(executableURL: URL, arguments: [String] = []) throws -> pid_t {
        var attributes: posix_spawnattr_t?
        var fileActions: posix_spawn_file_actions_t?
        guard posix_spawnattr_init(&attributes) == 0 else { throw launchFailure() }
        defer { posix_spawnattr_destroy(&attributes) }
        guard posix_spawn_file_actions_init(&fileActions) == 0 else { throw launchFailure() }
        defer { posix_spawn_file_actions_destroy(&fileActions) }
        guard posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETSID | POSIX_SPAWN_CLOEXEC_DEFAULT)) == 0,
              posix_spawn_file_actions_addopen(&fileActions, STDIN_FILENO, "/dev/null", O_RDONLY, 0) == 0,
              posix_spawn_file_actions_addopen(&fileActions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0) == 0,
              posix_spawn_file_actions_addopen(&fileActions, STDERR_FILENO, "/dev/null", O_WRONLY, 0) == 0 else { throw launchFailure() }
        let argumentPointers = ([executableURL.path] + arguments).map { strdup($0) } + [nil]
        defer { for argumentPointer in argumentPointers {
            free(argumentPointer)
        } }
        let environmentPointers = ProcessInfo.processInfo.environment.map { strdup("\($0.key)=\($0.value)") } + [nil]
        defer { for environmentPointer in environmentPointers {
            free(environmentPointer)
        } }
        var processIdentifier: pid_t = 0
        let status = argumentPointers.withUnsafeBufferPointer { arguments in
            environmentPointers.withUnsafeBufferPointer { environment in
                posix_spawn(&processIdentifier, executableURL.path, &fileActions, &attributes, arguments.baseAddress!, environment.baseAddress!)
            }
        }
        guard status == 0 else { throw launchFailure() }
        return processIdentifier
    }

    private static func launchFailure() -> InspectionFailure {
        InspectionFailure(code: "service.launchFailed", message: "The bundled inspection service could not be started.")
    }
}
