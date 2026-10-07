import Foundation
import os

enum LKSwiftUISupportLogger {
    static let activation = Logger(subsystem: subsystem, category: "Activation")

    private static let subsystem = "com.lookinside.app"
}
