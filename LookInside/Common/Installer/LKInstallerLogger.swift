import Foundation
import os

enum LKInstallerLogger {
    static let installer = Logger(subsystem: subsystem, category: "Installer")

    private static let subsystem = "com.lookinside.app"
}

extension NSLock {
    func lkLock<T>(_ work: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try work()
    }
}
