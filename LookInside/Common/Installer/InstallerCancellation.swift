import Foundation

struct InstallerCancelled: Error, LocalizedError {
    var errorDescription: String? {
        NSLocalizedString("Installation was cancelled.", comment: "")
    }
}

final class InstallerCancellation {
    private let lock = NSLock()
    private var cancelled = false
    private weak var downloadTask: URLSessionDownloadTask?
    private weak var unzipProcess: Process?

    var isCancelled: Bool {
        lock.withLock { cancelled }
    }

    func cancel() {
        let task: URLSessionDownloadTask?
        let process: Process?
        lock.lock()
        cancelled = true
        task = downloadTask
        process = unzipProcess
        lock.unlock()

        task?.cancel()
        if process?.isRunning == true {
            process?.terminate()
        }
    }

    func register(downloadTask task: URLSessionDownloadTask?) {
        let shouldCancel = lock.withLock {
            downloadTask = task
            return cancelled
        }
        if shouldCancel {
            task?.cancel()
        }
    }

    func register(unzipProcess process: Process?) {
        let shouldCancel = lock.withLock {
            unzipProcess = process
            return cancelled
        }
        if shouldCancel, process?.isRunning == true {
            process?.terminate()
        }
    }

    func checkCancellation() throws {
        if isCancelled {
            throw InstallerCancelled()
        }
    }
}
