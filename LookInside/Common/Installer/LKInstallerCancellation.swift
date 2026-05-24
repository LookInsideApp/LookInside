import Foundation

struct LKInstallerCancelled: Error, LocalizedError {
    var errorDescription: String? {
        NSLocalizedString("Installation was cancelled.", comment: "")
    }
}

final class LKInstallerCancellation {
    private let lock = NSLock()
    private var cancelled = false
    private weak var downloadTask: URLSessionDownloadTask?
    private weak var unzipProcess: Process?

    var isCancelled: Bool {
        lock.lkLock { cancelled }
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
        let shouldCancel = lock.lkLock {
            downloadTask = task
            return cancelled
        }
        if shouldCancel {
            task?.cancel()
        }
    }

    func register(unzipProcess process: Process?) {
        let shouldCancel = lock.lkLock {
            unzipProcess = process
            return cancelled
        }
        if shouldCancel, process?.isRunning == true {
            process?.terminate()
        }
    }

    func checkCancellation() throws {
        if isCancelled {
            throw LKInstallerCancelled()
        }
    }
}
