# Command-line inspection

`lookinside-cli` is available in development builds containing the headless inspection tools. This guide describes that implementation; it does not establish availability in an existing published release.

It requires macOS 14 or later and a logged-in macOS user session. Start the target application with LookInsideServer already loaded. The CLI can discover local macOS apps, running iOS Simulator apps, and apps on connected iOS devices through the existing server transports.

## Run a command

Keep the entire LookInside.app bundle together. The CLI locates its service and frameworks inside that bundle, including when invoked through a symbolic link.

```sh
lookinside_command='/Applications/LookInside.app/Contents/Resources/lookinside-cli'
"$lookinside_command" --help
"$lookinside_command" service status
"$lookinside_command" targets discover
```

`--help`, `--version`, and `service status` never start a service. Other commands start the bundled service when the default socket is unavailable. This process runs as the current user and continues after the initiating command exits. There is no login item or system daemon to install.

Development builds with shared inspection clients allow the CLI, MCP clients, and graphical LookInside app to inspect the same target together. The service owns the connection, capture settings, and committed hierarchy. A running older LookInside app that still owns its connections must finish its inspection before the new service can take ownership.

## Inspect a target

Copy the `targetIdentifier` from discovery, then copy the `sessionIdentifier` from `sessions open`. Identifiers identify a particular running instance; an app name or port number is not a target identifier.

```sh
"$lookinside_command" sessions open --target '<target-identifier>'
"$lookinside_command" sessions list
"$lookinside_command" hierarchy read --session '<session-identifier>' --depth 4
"$lookinside_command" views find --session '<session-identifier>' --class-name NSButton
"$lookinside_command" attributes read --session '<session-identifier>' --object '<object-identifier>'
"$lookinside_command" screenshot --session '<session-identifier>' --output screen.png --fresh
"$lookinside_command" hierarchy refresh --session '<session-identifier>'
"$lookinside_command" sessions close --session '<session-identifier>'
```

Use `UIButton` for a UIKit example. `views find` searches the reported class chain. Object identifiers come from hierarchy or search results. An optional `--object` on `screenshot` selects a particular node; otherwise the command captures the key window, falling back to the first root.

The first read captures a hierarchy. Concurrent first readers share that capture. Later reads reuse committed data until a client explicitly refreshes it. Responses include `captureDate`, `fromCache`, `connectionGeneration`, `hierarchyRevision`, and `requiresRefresh` when relevant. Attribute and image details may be fetched on demand. A cached screenshot is not a promise that the target still renders those pixels. Mutations through another client can mark the cache as requiring a refresh without changing its hierarchy revision.

Sessions persist across CLI invocations. Closing a session while another connected client uses it returns `session.inUse`. Closing a graphical window or detaching an MCP client releases only its own reference. An idle service exits after 300 seconds without connected clients; cached targets and sessions do not keep it alive. A target reconnection changes `connectionGeneration`; a service restart invalidates all previous session identifiers. Discover and open again after a service restart.

## Output and errors

The default `--format json` writes one JSON envelope to stdout. `--format text` pretty-prints the same envelope. Each command returns either `result` or `error`, with `schemaVersion: 1` and available service/session metadata. Screenshot bytes go to the requested PNG file; stdout reports its path and metadata.

```json
{
  "schemaVersion": 1,
  "error": {
    "code": "session.notFound",
    "message": "The session no longer exists. Open a new session."
  }
}
```

Read `error.code` for automation; messages may change. `--timeout` controls the client's socket deadline in seconds (default 30); service operations also have bounded deadlines.

| Exit code | Meaning                                                                           |
| --------- | --------------------------------------------------------------------------------- |
| 0         | Success                                                                           |
| 1         | Unclassified internal error                                                       |
| 2         | Invalid arguments or output destination                                           |
| 3         | Service unavailable or incompatible protocol/capabilities                         |
| 4         | Missing target, session, or object; disconnected target                           |
| 5         | Requested protected capability unavailable                                        |
| 6         | Operation timed out                                                               |
| 7         | Ownership conflict, busy session, stale data, or service restart during a command |

The CLI checks the running service's protocol and supported commands before inspection. It preserves an incompatible running service. Finish existing work and terminate that service normally before using the service bundled with the intended App version. `service status` reports its process identifier. Do not delete a live socket or its lock file to force a takeover.

## Authorization

Basic UIKit/AppKit hierarchy, ordinary attributes, and screenshots work without activation. To require verified SwiftUI access explicitly, add `--require-capability swiftui` to a hierarchy, search, attribute, or screenshot command. Verification comes from the connected target's authorization handshake; refusal returns exit code 5.

Before using protected features, use LookInside's graphical authorization flow to install a compatible Auth Server and prepare the license, then quit LookInside. Unlock the login keychain through macOS if required. CLI inspection never installs the helper, creates a key, opens activation UI, or asks to unlock a keychain. If those steps are needed, it reports the condition and keeps basic inspection available.

An authorization helper owned by another live inspection cannot be reassigned by the CLI. Finish that inspection first. Trials remain tied to the existing helper process; ending the service/helper loses that in-memory trial. The CLI does not request, renew, persist, or recreate a trial.

## Choose a socket

The default socket is `~/Library/Application Support/LookInside/Inspection/run/lookinside-inspection.sock`. Its directory and socket are private to the current user.

`--socket-path '<absolute-path>'` connects to an explicitly managed service and never starts one. To launch such a service manually, run the bundled `Contents/MacOS/lookinside-service --socket-path '<absolute-path>'` with a dedicated directory owned by your user. The service creates/protects that directory and rejects unsafe or overlong socket paths.

For independent terminal jobs, `LOOKINSIDE_INSPECTION_RUNTIME_DIRECTORY` sets an absolute default runtime directory while preserving automatic bundle-based startup. It does not bypass the user's exclusive ownership of target connections.

This implementation covers a logged-in desktop environment. Starting target apps, booting simulators, injecting servers, and operating without a desktop login are outside its current scope.
