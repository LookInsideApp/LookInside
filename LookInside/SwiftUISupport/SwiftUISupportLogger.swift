import Foundation
import os

enum SwiftUISupportLogger {
    static let activation = Logger(subsystem: subsystem, category: "Activation")

    private static let subsystem = "com.lookinside.app"
}
