---
name: lookinside-mcp-ui-debugging
description: Use when inspecting or debugging iOS/macOS app UI with LookInside, lookinside-mcp, MCP, Claude, Codex, UI hierarchy, layout, accessibility, clipped views, hidden buttons, wrong labels, screenshots, Debug builds, LookinServer, CocoaPods LookinServer pods, bundle id targeting, or when comparing AI-readable UI state with LookInside.app.
---

# LookInside MCP UI Debugging

## Overview

Use `lookinside-mcp` to let AI tools inspect a running Debug app's UI hierarchy without relying on the LookInside.app GUI. The target app must expose `LookinServer`; AI clients talk to the CLI over MCP stdio.

## Trigger Keywords

Use this skill for requests containing or implying:

- `LookInside`, `LookinServer`, `lookinside-mcp`, `MCP`, `UI hierarchy`, `层级`, `界面调试`, `调试 UI`
- `Claude 调试界面`, `Codex 调试界面`, `AI 看界面`, `AI 检查 UI`
- `bundle id`, `LOOKIN_MCP_TARGET_BUNDLE_ID`, `print-config`, `codex mcp add`
- `Podfile`, `CocoaPods`, `LookinServerBase`, `LookinCore`, `LookinShared`, `kUse_Local_Lookin`
- `current_screen`, `get_hierarchy`, `search_elements`, `diagnose_layout`, `diagnose_accessibility`
- UI symptoms: hidden/missing button, clipped label, wrong frame, wrong text, overlay, z-order, accessibility label, small tap target, offscreen view, layout overlap
- Questions like: "不用 GUI 客户端能不能调 UI?", "连接到某个 app 看层级", "告诉我当前界面信息"

Do not use it for ordinary macOS accessibility inspection unless `lookinside-mcp` is unavailable or the user only wants a surface-level screen read.

## Required Mental Model

- `lookinside-mcp` is a CLI executable and MCP stdio server.
- It does not inspect arbitrary apps by itself. The target app must be a Debug build with `LookinServer` embedded or injected.
- `LookInside.app` GUI and `lookinside-mcp` are both clients of the same in-app `LookinServer`.
- `LookinServer` is effectively single-client. If the GUI is connected, MCP may see `no_target` until the GUI disconnects.
- In multi-app environments, always target by bundle id.

## Target App Integration

The expected target-side setup is a Debug-only CocoaPods integration that brings `LookinServer` into the app process. This pattern is compatible:

```ruby
def install_lookin_server_pods
  lookin_pods = %w[
    LookinServerBase
    LookinCore
    LookinShared
    LookinServer
  ]
  debug_only_options = { :configurations => ['Debug'] }

  use_local_lookin = %w[1 true yes].include?(ENV['kUse_Local_Lookin'].to_s.downcase)
  lookin_source = if use_local_lookin
    { :path => '../LookInside' }
  else
    { :git => 'https://kgit.kugou.net/iOS/KGLookInside.git', :branch => 'feature/vanjay/kg_main' }
  end

  lookin_pods.each do |pod_name|
    pod pod_name, lookin_source.merge(debug_only_options)
  end
end
```

Use this helper inside each target that should be inspectable:

```ruby
target 'YourApp' do
  install_lookin_server_pods
end
```

Important checks:

- Build the target with the `Debug` configuration. These pods are intentionally absent from `Release`.
- Run `pod install` after changing the Podfile, then build from the workspace.
- Set `kUse_Local_Lookin=1` only when the target app should use the local `../LookInside` checkout; otherwise it should pull the configured git branch.
- If the target has app extensions, install the pods only into the app process that owns the UI being inspected, unless there is a specific extension UI to debug.
- Do not treat MCP `no_target` as an MCP bug until the app has been rebuilt and relaunched with these Debug pods present.

## Configuration

Build or locate the binary:

```sh
swift build --product lookinside-mcp
```

Common binary path in this workspace:

```sh
/Users/VanJay/Documents/Work/Private/LookInsideWorkspace/LookInside/.build/debug/lookinside-mcp
```

Configure Codex for a specific app:

```sh
codex mcp add lookinside \
  LOOKIN_MCP_TARGET_BUNDLE_ID=<bundle.id> \
  /path/to/lookinside-mcp serve
```

For example:

```sh
codex mcp add lookinside \
  LOOKIN_MCP_TARGET_BUNDLE_ID=cn.vanjay.HostsEditor \
  /Users/VanJay/Documents/Work/Private/LookInsideWorkspace/LookInside/.build/debug/lookinside-mcp serve
```

For Claude/Cursor/other MCP clients, use:

```sh
lookinside-mcp print-config claude-code
lookinside-mcp print-config codex
lookinside-mcp print-config cursor
```

Then add `LOOKIN_MCP_TARGET_BUNDLE_ID` to the MCP server environment when more than one app may be reachable.

## Inspection Workflow

1. Identify the target bundle id.
   - macOS: `osascript -e 'id of app "AppName"'`
   - From LookInside response: check `bundleIdentifier`
   - From Xcode project: check `PRODUCT_BUNDLE_IDENTIFIER`

2. Confirm the app is running and has `LookinServer`.
   - For iOS Simulator: launch the Debug app through Xcode/XcodeBuildMCP.
   - For CocoaPods projects: confirm the app target calls `install_lookin_server_pods`, `pod install` has run, and the app was rebuilt in `Debug`.
   - For macOS: launch a Debug app that links `LookinServer`, or ensure the GUI injected it.

3. Check whether another client is occupying the server.

```sh
lsof -nP -iTCP:47164-47179
```

Look for established GUI connections such as:

```text
LookInside.app -> 127.0.0.1:47170
Target.app     -> 127.0.0.1:47170
```

If the GUI is connected, quit/disconnect LookInside.app before using MCP.

4. Probe reachability.

```sh
LOOKIN_MCP_TARGET_BUNDLE_ID=<bundle.id> /path/to/lookinside-mcp health
```

Expected:

```text
status: ok
found 1 reachable app:
```

5. Inspect through MCP tools.
   - First call `current_screen`.
   - If the screen is large, call `get_hierarchy` with a bounded `maxDepth`.
   - Use `search_elements` by `className`, `role`, `accessibilityId`, or text.
   - Use `diagnose_layout` / `diagnose_accessibility` for heuristics.
   - Use `capture_screenshot` only when the caller needs visual evidence; it can return large base64 payloads.

## Manual MCP Smoke Test

Use this when validating CLI behavior outside a configured MCP client:

```sh
LOOKIN_MCP_TARGET_BUNDLE_ID=<bundle.id> node - <<'NODE'
const { spawn } = require('child_process');
const bin = '/path/to/lookinside-mcp';
const env = { ...process.env, LOOKIN_MCP_TARGET_BUNDLE_ID: '<bundle.id>' };
const child = spawn(bin, ['serve'], { env, stdio: ['pipe', 'pipe', 'pipe'] });
child.stderr.on('data', d => process.stderr.write(d));
child.stdout.on('data', d => process.stdout.write(d));
function send(msg) { child.stdin.write(JSON.stringify(msg) + '\n'); }
setTimeout(() => send({jsonrpc:'2.0', id:1, method:'initialize', params:{protocolVersion:'2025-11-25', capabilities:{}, clientInfo:{name:'smoke', version:'1.0'}}}), 300);
setTimeout(() => send({jsonrpc:'2.0', method:'notifications/initialized', params:{}}), 700);
setTimeout(() => send({jsonrpc:'2.0', id:2, method:'tools/call', params:{name:'current_screen', arguments:{}}}), 1100);
setTimeout(() => child.kill('SIGTERM'), 8000);
NODE
```

The stdio transport is newline-delimited JSON, not `Content-Length` framing.

## Troubleshooting

### `status: no_target`

Check in this order:

- Target app is running.
- Target app is Debug and has `LookinServer`.
- CocoaPods integration includes `LookinServerBase`, `LookinCore`, `LookinShared`, and `LookinServer` for the app target.
- App was rebuilt from the `.xcworkspace` after `pod install`.
- Bundle id is exact.
- GUI LookInside.app is not connected to the same server.
- Ports are visible with `lsof -nP -iTCP:47164-47179`.
- macOS target should usually listen on `47170-47174`; simulator target on `47164-47169`.

### GUI can see the app but MCP cannot

Most likely LookInside.app is occupying the single LookinServer connection. Quit/disconnect GUI, then retry MCP. If the GUI was needed to inject `LookinServer` into a macOS process, inject first, then disconnect the GUI so MCP can connect.

### MCP connects to the wrong app

Set:

```sh
LOOKIN_MCP_TARGET_BUNDLE_ID=<bundle.id>
```

Then rerun `health` or `current_screen`. Without this, the server may choose the first reachable app by port order.

### `current_screen` times out

Use `LOOKIN_MCP_DEBUG=1` to verify request/response flow:

```sh
LOOKIN_MCP_DEBUG=1 LOOKIN_MCP_TARGET_BUNDLE_ID=<bundle.id> /path/to/lookinside-mcp serve
```

Expected debug lines include send callback and received frame. If send succeeds but no response arrives, check target logs for LookinServer request handling. If response arrives but decoding fails, suspect archive compatibility or missing allowed classes.

### Text search returns empty

`search_elements(text:)` depends on text attributes being present in LookinServer's hierarchy data. If text search is weak, first verify the hierarchy with `className` or `role`, then inspect element details.

## Reporting Format

When reporting findings, include:

- Target bundle id and app name.
- Whether inspection came from `lookinside-mcp` or fallback macOS accessibility.
- Connection status and whether GUI LookInside.app was connected.
- Summary: app, device, hierarchy depth, key window/root class.
- Relevant nodes: class, role, oid, path, frame/bounds, hidden/alpha.
- Diagnostics: layout/accessibility findings with severity and why they matter.
- Limitations: e.g. GUI occupied server, target not Debug, text attributes unavailable.

Do not claim MCP inspection succeeded unless `current_screen`, `get_hierarchy`, or another MCP tool returned a non-error result for the intended bundle id.
