import Foundation
import os

enum LKSwiftUISupportLogger {
    static let authServer = Logger(subsystem: subsystem, category: "AuthServer")
    static let installer = Logger(subsystem: subsystem, category: "Installer")

    private static let subsystem = "com.lookinside.app"
}
