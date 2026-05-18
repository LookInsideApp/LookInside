import Foundation

@main
struct LKSwiftUISupportAuthServerPathPolicyTests {
    static func main() {
        let environment = [
            "LOOKINSIDE_AUTH_SERVER_PATH": "/tmp/attacker-helper",
            "LOOKINSIDE_AUTH_SERVER_SOCKET_PATH": "/tmp/attacker.sock",
            "LOOKINSIDE_AUTH_SERVER_VERSION": "999.0.0",
            "KEEP": "1",
        ]
        let defaultExecutable = URL(fileURLWithPath: "/default/helper")
        let defaultSocket = URL(fileURLWithPath: "/default/helper.sock")

        let executable = LKSwiftUISupportAuthServerPathPolicy.executableURL(
            environment: environment,
            overrideKey: "LOOKINSIDE_AUTH_SERVER_PATH",
            defaultURL: defaultExecutable
        )
        let socket = LKSwiftUISupportAuthServerPathPolicy.socketURL(
            environment: environment,
            overrideKey: "LOOKINSIDE_AUTH_SERVER_SOCKET_PATH",
            defaultURL: defaultSocket
        )
        let launchEnvironment = LKSwiftUISupportAuthServerPathPolicy.launchEnvironment(
            from: environment,
            helperPathKey: "LOOKINSIDE_AUTH_SERVER_PATH",
            helperVersionKey: "LOOKINSIDE_AUTH_SERVER_VERSION"
        )

        #if DEBUG
            expect(executable.path == "/tmp/attacker-helper", "debug executable override")
            expect(socket.path == "/tmp/attacker.sock", "debug socket override")
            expect(launchEnvironment["LOOKINSIDE_AUTH_SERVER_PATH"] == "/tmp/attacker-helper", "debug keeps helper path")
            expect(launchEnvironment["LOOKINSIDE_AUTH_SERVER_VERSION"] == "999.0.0", "debug keeps helper version")
            expect(
                LKSwiftUISupportActivationStateRefreshPolicy.startupAction == .installAndLaunch,
                "debug activation refresh can install and launch helper"
            )
        #else
            expect(executable == defaultExecutable, "release executable uses installed helper")
            expect(socket == defaultSocket, "release socket uses installed socket")
            expect(launchEnvironment["LOOKINSIDE_AUTH_SERVER_PATH"] == nil, "release strips helper path")
            expect(launchEnvironment["LOOKINSIDE_AUTH_SERVER_VERSION"] == nil, "release strips helper version")
            expect(
                LKSwiftUISupportActivationStateRefreshPolicy.startupAction == .installAndLaunch,
                "release activation refresh installs and launches helper"
            )
        #endif

        expect(launchEnvironment["KEEP"] == "1", "unrelated env preserved")
    }

    private static func expect(_ condition: Bool, _ message: String) {
        guard condition else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            Foundation.exit(1)
        }
    }
}
