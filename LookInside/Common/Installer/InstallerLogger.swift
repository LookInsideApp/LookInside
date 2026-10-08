import Foundation
import os

enum InstallerLogger {
    static let installer = Logger(subsystem: subsystem, category: "Installer")

    private static let subsystem = "com.lookinside.app"
}
