# Troubleshooting `lookinside-mcp`

Start by running:

```sh
lookinside-mcp health
```

It reports what `lookinside-mcp serve` will see when an MCP client invokes it.

## `status: no_target`

No Debug build with `LookinServer` is reachable. Common causes:

- **App not running in Debug.** Release builds don't embed `LookinServer`. Check your scheme.
- **`LookinServer` not added.** SPM: depend on the `LookinServer` library; CocoaPods: add the `LookinServer` subspec. See the main [README](../README.md).
- **App is in the background.** `LookinServer` won't service requests while the app is suspended.
- **Wrong Simulator.** Ports are shared across all simulators on a Mac; if multiple sims run apps with `LookinServer`, the first 6 (47164–47169) get one port each. `lookinside-mcp list_apps` shows every reachable app.
- **USB device unlocked?** Physical-device support requires `usbmuxd` (built into Xcode) and an unlocked device.

## `decodeFailure: protocol version`

`LookinServer` was built against an older protocol. Update the dependency in your app target to match the LookInside version this MCP server ships from.

## `timeout`

The app responded slowly. Causes:
- Paused on a breakpoint in Xcode — resume.
- Main thread blocked — investigate.
- App in background — bring to foreground.

## Tool calls return `{ "ok": false, "reason": "highlight requires …" }`

`highlight_element` requires a server-side request type that hasn't shipped yet. The tool degrades gracefully so the agent can still recommend a fix. Track the follow-up issue in the repo.

## Client doesn't see the server

- Confirm the absolute path in your config — `lookinside-mcp print-config <client>` always emits the correct path.
- Restart the client after editing config.
- Tail stderr: most MCP clients capture stderr to a log file. `lookinside-mcp` writes a "listening on stdio" banner there at startup.
- If you see `Fatal:` on stderr, copy the full text — it includes the underlying error.

## Codesign / Gatekeeper

If you downloaded a release binary, macOS may quarantine it:

```sh
xattr -dr com.apple.quarantine /path/to/lookinside-mcp
```

The release script signs and notarizes builds, but a `curl` download still picks up the quarantine bit until you remove it.

## Firewall

Loopback Peertalk traffic is not blocked by the macOS firewall in any default configuration. If you've added a custom outbound rule, allow `lookinside-mcp` to connect to `127.0.0.1` on ports 47164–47179.

## Last resort

`lookinside-mcp` is intentionally small. If something is weird:

1. Reproduce with `lookinside-mcp health` (no MCP client involved).
2. Then try `lookinside-mcp serve --snapshot some.lookin` to confirm the MCP plumbing works against a static snapshot.
3. File an issue with both outputs and the LookInside / LookinServer versions.
