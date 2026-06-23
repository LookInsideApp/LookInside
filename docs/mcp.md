# MCP integration (Debug-only)

LookInside ships an optional MCP server, `lookinside-mcp`, that lets AI coding agents inspect a running Debug build's UI through the same plumbing the macOS LookInside.app uses. Once installed, any MCP-compatible client — Claude Desktop, Claude Code, Cursor, Windsurf, VS Code, continue.dev — can ask the agent things like:

- *"Inspect the current screen and tell me what UI issues you see."*
- *"Why is this button not visible?"*
- *"Find clipped labels on this screen."*
- *"Highlight the checkout button."*
- *"Check accessibility problems on the current screen."*
- *"Export a bug report for this UI state."*

## What it can do

| Tool | Purpose |
|---|---|
| `health_check` | Is a Debug app reachable? Returns version + connected-app metadata. |
| `list_apps` | Every Debug app currently reachable on Peertalk ports. |
| `current_screen` | Quick screen summary with a depth-2 hierarchy preview. |
| `get_hierarchy` | Full hierarchy tree (configurable depth). |
| `search_elements` | Filter by text, accessibility id, class, role, visibility. |
| `get_element` | Full attribute groups for one oid. |
| `capture_screenshot` | Base64 PNG of the key window. |
| `highlight_element` | Flash a highlight overlay in-app. |
| `diagnose_layout` | Heuristics: zero-size views, tap targets < 44pt, overlapping interactives, offscreen children. |
| `diagnose_accessibility` | Missing labels, duplicates, small touch targets. |
| `export_bug_report` | Bundle screen + hierarchy + diagnostics + screenshot into one JSON. |

## Debug-only by design

`lookinside-mcp` works only against apps that embed `LookinServer`, which is a Debug-only library. Release builds simply have nothing to talk to. The server enforces no proprietary handshake — but the client refuses any operation beyond hierarchy reads:

- No arbitrary selector invocation.
- No shell exec.
- Secure text field contents (`UITextField.isSecureTextEntry`, `NSSecureTextField`) are redacted at the data layer — they cannot leak through any current or future tool.
- Transport is stdio only; no network listener is opened.

## Install

### Build from source

```sh
./Scripts/build-mcp-server.sh
```

Drops the binary at `./build/lookinside-mcp`. Add it to `PATH`, or reference the absolute path in your client config.

### From a release artifact

Download the latest `lookinside-mcp` binary from [GitHub Releases](../README.md) and `chmod +x` it.

## Connect a client

Run `lookinside-mcp print-config <client>` to get a ready-to-paste snippet. See [`mcp-client-configs.md`](mcp-client-configs.md) for client-specific instructions.

## Verify

```sh
lookinside-mcp health
```

Should print `status: ok` and one or more reachable apps. If it prints `status: no_target`, see [`mcp-troubleshooting.md`](mcp-troubleshooting.md).

## Architecture

```
AI agent ↔ MCP client (Claude Desktop, etc.)
            │ stdio JSON-RPC
            ▼
       lookinside-mcp ──────────► Peertalk TCP (47164–47179)
            │                                │
            └── LookinMCPCore                ▼
                 (hierarchy index,    LookinServer (in-process
                  search, diagnostics,  in your Debug build)
                  bug-report builder)
```

The MCP server is a parallel consumer of `LookinServer` alongside the macOS LookInside.app — both speak the same protocol, but the MCP server skips the macOS app's license gate because that gate is enforced client-side, not by the in-process server.

## Limitations (today)

- `highlight_element` requires a server-side request type that doesn't exist yet — coming in a follow-up.
- No write-side tools (tap, scroll, type, temporary property changes). The protocol supports them; we deliberately gated them out of the first version.
- Source-code mapping (oid → file:line) ships when SwiftUI trace data is stable enough to rely on.

## Known errors

| Error | What it means |
|---|---|
| `noTargetApp` | No Debug build with `LookinServer` was reachable. Launch one and retry. |
| `timeout` | The app responded slowly — usually paused at a breakpoint or in background. |
| `decodeFailure` | Protocol version mismatch. Update `LookinServer` in your app. |
| `unsupported` | A tool isn't implemented for this provider (e.g. highlight from a snapshot file). |

## Offline / snapshot mode

`lookinside-mcp serve --snapshot path/to/screen.lookin` serves an exported `.lookin` snapshot. Useful for analyzing captured bug states without keeping the app running.
