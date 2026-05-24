import Foundation

enum LKInstallerArchiveExtractor {
    static func unzip(
        _ zipURL: URL,
        into destination: URL,
        cancellation: LKInstallerCancellation,
        errorBuilder: (String) -> Error
    ) throws {
        try cancellation.checkCancellation()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", zipURL.path, destination.path]
        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = Pipe()
        do {
            try process.run()
        } catch {
            throw errorBuilder(error.localizedDescription)
        }
        cancellation.register(unzipProcess: process)
        process.waitUntilExit()
        cancellation.register(unzipProcess: nil)
        try cancellation.checkCancellation()
        if process.terminationStatus != 0 {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)
                ?? String(format: NSLocalizedString("ditto exited with status %d.", comment: ""), process.terminationStatus)
            throw errorBuilder(message)
        }
    }
}
