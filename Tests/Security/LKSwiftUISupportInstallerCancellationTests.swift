import Foundation

@main
struct LKSwiftUISupportInstallerCancellationTests {
    static func main() throws {
        let cancellation = LKSwiftUISupportInstallerCancellation()
        expect(cancellation.isCancelled == false, "starts active")

        cancellation.cancel()
        expect(cancellation.isCancelled, "cancel flips state")
        expectThrowsCancelled("check throws after cancel") {
            try cancellation.checkCancellation()
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sleep")
        process.arguments = ["10"]
        try process.run()
        cancellation.register(unzipProcess: process)
        cancellation.cancel()

        let deadline = Date().addingTimeInterval(2)
        while process.isRunning, Date() < deadline {
            usleep(50_000)
        }
        expect(process.isRunning == false, "cancel terminates unzip process")
    }

    private static func expect(_ condition: Bool, _ message: String) {
        guard condition else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            Foundation.exit(1)
        }
    }

    private static func expectThrowsCancelled(_ message: String, _ body: () throws -> Void) {
        do {
            try body()
        } catch LKSwiftUISupportInstallerError.cancelled {
            return
        } catch {
            FileHandle.standardError.write(Data("FAIL: \(message): \(error)\n".utf8))
            Foundation.exit(1)
        }
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        Foundation.exit(1)
    }
}
