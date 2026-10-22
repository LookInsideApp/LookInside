import os

enum ActivationLogger {
    static let rpc = Logger(subsystem: subsystem, category: "rpc")
    static let runtime = Logger(subsystem: subsystem, category: "runtime")
    static let ui = Logger(subsystem: subsystem, category: "ui")

    private static let subsystem = "app.lookinside.activation"
}
