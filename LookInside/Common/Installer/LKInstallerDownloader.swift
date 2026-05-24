import Foundation

enum LKInstallerDownloader {
    static func download(
        from url: URL,
        to destination: URL,
        cancellation: LKInstallerCancellation,
        timeout: TimeInterval = 30,
        errorBuilder: @escaping (String) -> Error
    ) throws {
        try cancellation.checkCancellation()

        var capturedError: Error?
        var downloadedToDestination = false
        let semaphore = DispatchSemaphore(value: 0)

        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let task = URLSession.shared.downloadTask(with: request) { tempURL, response, error in
            defer { semaphore.signal() }
            if let error {
                if cancellation.isCancelled || (error as NSError).code == NSURLErrorCancelled {
                    capturedError = LKInstallerCancelled()
                } else {
                    capturedError = errorBuilder(error.localizedDescription)
                }
                return
            }
            guard cancellation.isCancelled == false else {
                capturedError = LKInstallerCancelled()
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                capturedError = errorBuilder(NSLocalizedString("No response received.", comment: ""))
                return
            }
            guard (200 ... 299).contains(httpResponse.statusCode) else {
                capturedError = errorBuilder("HTTP \(httpResponse.statusCode)")
                return
            }
            guard let tempURL else {
                capturedError = errorBuilder(NSLocalizedString("Empty download payload.", comment: ""))
                return
            }
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: tempURL, to: destination)
                downloadedToDestination = true
            } catch {
                capturedError = errorBuilder(error.localizedDescription)
            }
        }
        cancellation.register(downloadTask: task)
        task.resume()
        semaphore.wait()
        cancellation.register(downloadTask: nil)

        try cancellation.checkCancellation()
        if let capturedError {
            throw capturedError
        }
        guard downloadedToDestination else {
            throw errorBuilder(NSLocalizedString("Unknown download failure.", comment: ""))
        }
    }
}
