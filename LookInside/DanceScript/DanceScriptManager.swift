//
//  DanceScriptManager.swift
//  LookInside
//
//  Jumps from a DanceUI source location to Xcode. The dashboard hands over a
//  JSON payload like
//  {"type":"DanceUIApp.ContentView","method":"body.get","build_path":"…/DanceUIApp.app/DanceUIApp"};
//  the bundled DanceScript.sh is copied to the temporary directory once and
//  run as `DanceScript.sh <build_path> <type> <method>`.
//

import AppKit

@objc(DanceScriptManager)
final class DanceScriptManager: NSObject {
    private static let sharedManager = DanceScriptManager()

    @objc class func shared() -> DanceScriptManager {
        sharedManager
    }

    /// The fields of the dashboard's JSON payload.
    struct Request: Equatable {
        var type: String
        var method: String
        var buildPath: String
    }

    enum ParseError: Error, Equatable {
        case invalidJSON
        case unexpectedFormat
    }

    static func parse(_ json: String) -> Result<Request, ParseError> {
        guard let object = try? JSONSerialization.jsonObject(with: Data(json.utf8)) else {
            return .failure(.invalidJSON)
        }
        guard let dict = object as? [String: Any] else {
            return .failure(.unexpectedFormat)
        }
        guard let type = dict["type"] as? String, let method = dict["method"] as? String,
              let buildPath = dict["build_path"] as? String
        else {
            return .failure(.unexpectedFormat)
        }
        return .success(Request(type: type, method: method, buildPath: buildPath))
    }

    @MainActor
    @objc(handleText:)
    func handleText(_ json: String?) {
        guard let json else {
            LKPeripheralAlerts.show(LKConnectionError.inner, in: LKPeripheralAlerts.keyWindow)
            return
        }
        switch Self.parse(json) {
        case let .success(request):
            execute(request)
        case .failure(.invalidJSON):
            LKPeripheralAlerts.show(title: NSLocalizedString("Unable to Run Script", comment: ""), detail: String(format: NSLocalizedString("Unable to parse the request: %@", comment: ""), json), in: LKPeripheralAlerts.keyWindow)
            assertionFailure("DanceScript payload is not JSON")
        case .failure(.unexpectedFormat):
            LKPeripheralAlerts.show(title: NSLocalizedString("Unable to Run Script", comment: ""), detail: String(format: NSLocalizedString("Unexpected request format: %@", comment: ""), json), in: LKPeripheralAlerts.keyWindow)
        }
    }

    @MainActor
    private func copyScriptFromAppToDisk() -> String? {
        let fileManager = FileManager.default
        let newScriptPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("Lookin_DanceJump.sh")
        if fileManager.fileExists(atPath: newScriptPath) {
            return newScriptPath
        }
        let scriptPath = Bundle.main.url(forResource: "DanceScript", withExtension: "sh")?.relativePath
        guard let scriptPath, fileManager.fileExists(atPath: scriptPath) else {
            LKPeripheralAlerts.show(title: NSLocalizedString("Unable to Run Script", comment: ""), detail: String(format: NSLocalizedString("Unable to find the script at %@.", comment: ""), scriptPath ?? "(null)"),
                                    in: LKPeripheralAlerts.keyWindow)
            return nil
        }
        let copied = (try? fileManager.copyItem(atPath: scriptPath, toPath: newScriptPath)) != nil
        try? fileManager.setAttributes([.posixPermissions: NSNumber(value: Int16(0o755))], ofItemAtPath: newScriptPath)
        guard copied else {
            LKPeripheralAlerts.show(title: NSLocalizedString("Unable to Run Script", comment: ""), detail: NSLocalizedString("Unable to copy the script.", comment: ""), in: LKPeripheralAlerts.keyWindow)
            return nil
        }
        guard fileManager.fileExists(atPath: newScriptPath) else {
            LKPeripheralAlerts.show(title: NSLocalizedString("Unable to Run Script", comment: ""), detail: NSLocalizedString("The copied script is missing.", comment: ""), in: LKPeripheralAlerts.keyWindow)
            return nil
        }
        return newScriptPath
    }

    @MainActor
    private func execute(_ request: Request) {
        let scriptPath = copyScriptFromAppToDisk() ?? "(null)"
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", "\(scriptPath) \(request.buildPath) \(request.type) \(request.method)"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
        } catch {
            NSLog("DanceScript failed to launch: %@", String(describing: error))
            return
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        NSLog("脚本执行输出：%@", output)
    }
}
