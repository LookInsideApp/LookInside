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

        LKInstallerLogger.installer.info(
            "downloader: start url=\(url.absoluteString, privacy: .public) timeout=\(timeout)"
        )

        var capturedError: Error?
        var downloadedToDestination = false
        let semaphore = DispatchSemaphore(value: 0)

        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let task = URLSession.shared.downloadTask(with: request) { tempURL, response, error in
            defer { semaphore.signal() }
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            LKInstallerLogger.installer.info(
                "downloader: completion status=\(status) error=\(error?.localizedDescription ?? "nil", privacy: .public)"
            )
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
                let movedSize = (try? FileManager.default.attributesOfItem(atPath: destination.path)[.size] as? Int) ?? -1
                LKInstallerLogger.installer.info("downloader: moved to destination bytes=\(movedSize)")
                downloadedToDestination = true
            } catch {
                capturedError = errorBuilder(error.localizedDescription)
            }
        }
        cancellation.register(downloadTask: task)
        task.resume()
        LKInstallerLogger.installer.info("downloader: task.resume() called, waiting on semaphore")
        semaphore.wait()
        LKInstallerLogger.installer.info("downloader: semaphore released")
        cancellation.register(downloadTask: nil)

        try cancellation.checkCancellation()
        if let capturedError {
            LKInstallerLogger.installer.error(
                "downloader: throwing error=\(capturedError.localizedDescription, privacy: .public)"
            )
            throw capturedError
        }
        guard downloadedToDestination else {
            throw errorBuilder(NSLocalizedString("Unknown download failure.", comment: ""))
        }
    }
}
