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

## Inject into a running macOS application

Development builds with command-line injection can prepare an inspection session for a macOS app that has not loaded LookInsideServer. This requires LookInside Pro, a compatible injector already enabled through macOS, and a compatible signed Server framework already prepared by LookInside.

First install LookInside in Applications and use **Attach to Running App** in its graphical interface to prepare the injector, system approval, and Server framework. Keep that installation together. Command-line calls report missing prerequisites; they never register the privileged helper, open System Settings, download an unprepared framework, or prompt for activation.

Select the process explicitly, then use the returned session:

```sh
"$lookinside_command" injector status --format json
"$lookinside_command" inject --process-identifier 12345 --format json
"$lookinside_command" hierarchy read --session '<returned-session-identifier>'
```

Replace `12345` with the process identifier of the running macOS application you intend to modify. The process must belong to your user. The CLI does not accept a library path, start the target, or provide simulator/device injection. A successful result contains `processIdentifier`, `processStartIdentifier`, `applicationInstanceIdentifier`, `targetIdentifier`, `sessionIdentifier`, and `injectionStage: "sessionReady"`. Names and ports are never sufficient to associate the injected process with a Server connection.

Repeated calls reuse a verified session. A concurrent injection into the same process returns `injection.alreadyInProgress`. Injection requires a client timeout of at least five seconds; the service bounds the injection workflow to at most 25 seconds and all service requests to 30 seconds.

Failures include `error.details.injectionStage` when execution information is available:

| Stage               | Meaning                                                                                            |
| ------------------- | -------------------------------------------------------------------------------------------------- |
| `notSubmitted`      | This operation did not submit an injection, or the helper explicitly rejected it before execution. |
| `submissionUnknown` | A request may have executed, but its result was lost or cancelled.                                 |
| `injected`          | The helper confirmed injection; no verified inspection session is ready yet.                       |
| `sessionReady`      | A successful result associated the selected process with a live inspection session.                |

Cancellation cannot undo a submitted injection. A timeout never triggers automatic reinjection or service replacement. The running service retains uncertain submission receipts; repeated calls first try to discover the target, then report uncertainty without injecting again. Receipts are in memory and disappear when the service exits, so restarting the service is not evidence that retrying is safe.

| Error                                                                                                                                                  | Action                                                                                |
| ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| `injection.licenseRequired`                                                                                                                            | Activate or repair the existing license through LookInside.                           |
| `injection.helperMissing`, `injection.helperNotEnabled`, `injection.approvalRequired`, `injection.unsupportedLocation`, `injection.helperIncompatible` | Prepare or approve the compatible injector through LookInside in Applications.        |
| `injection.preparationRequired`, `injection.frameworkUnavailable`                                                                                      | Prepare the current compatible Server framework through LookInside.                   |
| `injection.targetNotFound`, `injection.targetChanged`, `injection.denied`                                                                              | Check the selected running process and macOS permissions; inspect the reported stage. |
| `injection.targetUnverified`, `injection.discoveryTimeout`, `injection.helperTimeout`                                                                  | Check the reported stage. Injection may have happened; do not retry blindly.          |
| `injection.alreadyInProgress`, `injection.historyFull`                                                                                                 | Finish the active operation or inspections before starting more work.                 |

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

| Exit code | Meaning                                                                                      |
| --------- | -------------------------------------------------------------------------------------------- |
| 0         | Success                                                                                      |
| 1         | Unclassified internal error                                                                  |
| 2         | Invalid arguments or output destination                                                      |
| 3         | Service/helper unavailable, missing preparation, or incompatible capabilities                |
| 4         | Missing/disconnected/unverified target, session, or object; injection denied                 |
| 5         | Requested protected capability unavailable                                                   |
| 6         | Operation timed out                                                                          |
| 7         | Ownership conflict, busy session or injection, stale data, service restart, or receipt limit |

The CLI checks the running service's protocol and supported commands before inspection. It preserves an incompatible running service. Finish existing work and terminate that service normally before using the service bundled with the intended App version. `service status` reports its process identifier. Do not delete a live socket or its lock file to force a takeover.

## Authorization

Basic UIKit/AppKit hierarchy, ordinary attributes, and screenshots work without activation. To require verified SwiftUI access explicitly, add `--require-capability swiftui` to a hierarchy, search, attribute, or screenshot command. Verification comes from the connected target's authorization handshake; refusal returns exit code 5.

Before using protected features, use LookInside's graphical authorization flow to install a compatible Auth Server and prepare the license. Unlock the login keychain through macOS if required. CLI inspection never installs the helper, creates a key, opens activation UI, or asks to unlock a keychain. If those steps are needed, it reports the condition and keeps basic inspection available.

An authorization helper owned by another live inspection cannot be reassigned by the CLI. Finish that inspection first. Trials remain tied to the existing helper process; ending the service/helper loses that in-memory trial. The CLI does not request, renew, persist, or recreate a trial.

## Choose a socket

The default socket is `~/Library/Application Support/LookInside/Inspection/run/lookinside-inspection.sock`. Its directory and socket are private to the current user.

`--socket-path '<absolute-path>'` connects to an explicitly managed service and never starts one. To launch such a service manually, run the bundled `Contents/MacOS/lookinside-service --socket-path '<absolute-path>'` with a dedicated directory owned by your user. The service creates/protects that directory and rejects unsafe or overlong socket paths.

For independent terminal jobs, `LOOKINSIDE_INSPECTION_RUNTIME_DIRECTORY` sets an absolute default runtime directory while preserving automatic bundle-based startup. It does not bypass the user's exclusive ownership of target connections.

This implementation covers a logged-in desktop environment. Starting target apps, booting simulators, device/simulator injection, and operating without a desktop login are outside its current scope.
