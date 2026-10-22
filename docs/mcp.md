# Use LookInside with MCP clients

LookInside 2.3.11 and later include a local [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server. It lets MCP-compatible AI clients inspect the iOS or macOS app that is open in LookInside.

The server is bundled inside the signed LookInside app. There is no separate package to install and no API key or network endpoint to configure.

## Before you configure a client

Make sure all of the following are true:

1. Install an official LookInside 2.3.11 or later release as `/Applications/LookInside.app`.
2. Add the [LookInside server package](https://github.com/LookInsideApp/LookInside-Release) to the Debug build of the app you want to inspect.
3. Run the target app.
4. Open LookInside and connect to the running app from the launch window.
5. Keep LookInside running while the MCP client uses its tools.

Verify that the bundled executable is present:

```sh
test -x /Applications/LookInside.app/Contents/Resources/lookinside-mcp \
  && echo "LookInside MCP server is installed"
```

If LookInside is installed somewhere else, replace the absolute path in the examples below. Use the executable inside the same LookInside app that you run so the host and MCP server stay on matching versions.

## Configure an MCP client

LookInside uses the local `stdio` MCP transport. The command is:

```text
/Applications/LookInside.app/Contents/Resources/lookinside-mcp
```

It does not need arguments, environment variables, credentials, or OAuth.

### Codex

Add the server with the Codex CLI:

```sh
codex mcp add lookinside -- /Applications/LookInside.app/Contents/Resources/lookinside-mcp
codex mcp get lookinside
```

Start a new Codex session after adding the server. In the Codex terminal UI, `/mcp` shows the active servers. The Codex app, CLI, and IDE extension share MCP configuration for the same Codex host.

The equivalent `~/.codex/config.toml` entry is:

```toml
[mcp_servers.lookinside]
command = "/Applications/LookInside.app/Contents/Resources/lookinside-mcp"
```

See the [official Codex MCP documentation](https://learn.chatgpt.com/docs/extend/mcp?surface=cli) for more client-side options.

### Claude Code

Add LookInside as a user-scoped local server:

```sh
claude mcp add --transport stdio --scope user lookinside \
  -- /Applications/LookInside.app/Contents/Resources/lookinside-mcp
claude mcp get lookinside
```

Use `/mcp` inside Claude Code to inspect or reconnect the server. See the [Claude Code MCP documentation](https://code.claude.com/docs/en/mcp) for scope and approval options.

### Claude Desktop

Open **Settings > Developer > Edit Config**, then add this entry to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "lookinside": {
      "command": "/Applications/LookInside.app/Contents/Resources/lookinside-mcp",
      "args": []
    }
  }
}
```

Merge the `lookinside` entry into the existing `mcpServers` object if the file already contains other servers. Quit and reopen Claude Desktop after saving it.

See the [MCP guide for connecting local servers](https://modelcontextprotocol.io/docs/develop/connect-local-servers) for configuration and log locations.

### Other clients

Cursor, Windsurf, VS Code, and other MCP clients can use the same executable. Add a local `stdio` server named `lookinside` with:

- **Command:** `/Applications/LookInside.app/Contents/Resources/lookinside-mcp`
- **Arguments:** none
- **Environment:** none

The surrounding JSON or settings UI differs by client, so use that client's local `stdio` server format.

## Verify the connection

After restarting or opening a new client session, ask the agent:

> Use LookInside's `ping_host` tool and report the connected host version. Do not use a shell command.

A successful response looks like:

```text
Host MCPBridge alive (LookInside 3.0.0).
```

Then verify that the current inspection session is visible:

> Use LookInside to list the attached targets. Report the app name, device, OS, and license state.

`list_targets` returns an empty list when LookInside is running but has not opened a target. Return to the LookInside launch window, connect to the app, and retry.

## Recommended inspection workflow

Agents get the most reliable results when they follow this order:

1. Call `ping_host` to verify that LookInside is running.
2. Call `list_targets` and choose a target whose `licenseState` allows inspection.
3. Call `refresh_hierarchy` if the user navigated, presented a sheet, or otherwise changed the target app since the last read.
4. Use `take_screenshot` without an object identifier for a visual overview.
5. Use `find_views` when looking for a specific class, label, or address. Prefer it over loading a large complete tree.
6. Use `get_hierarchy` with a bounded `depth`, or scope it to a `rootObjectIdentifier` returned by an earlier call.
7. Call `read_view_details` before `read_attributes` when inspecting newly discovered object identifiers.
8. Re-find views after a hierarchy refresh. Object identifiers from the previous tree may no longer resolve.

For example:

> Use LookInside to inspect the first attached target. Refresh its hierarchy, take a window screenshot, find visible button views, and summarize each button's frame and title. Do not mutate the app.

## Available tools

| Area | Tools | Purpose |
| --- | --- | --- |
| Connection | `ping_host`, `list_targets` | Check the host and discover attached apps. |
| Hierarchy | `get_hierarchy`, `find_views` | Read or search the current view tree. |
| Details | `read_attributes`, `read_view_details`, `list_class_methods` | Inspect properties and available Objective-C selectors. |
| Visuals | `take_screenshot` | Capture the key window or one view as PNG. |
| Refresh | `refresh_hierarchy` | Reload the tree after the target UI changes. |
| Snapshots | `capture_snapshot`, `list_snapshots`, `drop_snapshot`, `diff_snapshots` | Compare structure, frames, and visibility across two points in time. |
| Mutation | `invoke_method`, `modify_attribute` | Call a zero-argument selector or change a supported attribute in the Debug app. |

The MCP client receives each tool's complete input schema and description when it connects. Let the client use those schemas instead of guessing argument names or value shapes.

## Compare UI changes

Snapshots are useful when you want to understand the effect of a navigation or interaction without comparing two large trees manually:

1. Call `capture_snapshot` with a label such as `before`.
2. Change the target app, or ask the user to perform the interaction.
3. Call `capture_snapshot` again with a label such as `after`.
4. Call `diff_snapshots` with the two returned snapshot identifiers.

Example prompt:

> Capture a LookInside hierarchy snapshot named `before`. Ask me to perform the interaction, then capture `after` and diff the two snapshots. Summarize added, removed, moved, resized, and visibility-changed views.

Snapshots live only for the lifetime of that MCP server process. Capture both snapshots in the same client session.

## Safety and privacy

- Treat the target app as a development or debugging environment. `invoke_method` and `modify_attribute` can change its state immediately.
- Ask before using mutation tools unless the user explicitly requested the change.
- Prefer `list_class_methods` before `invoke_method`; method invocation currently supports zero-argument Objective-C selectors.
- Secure text attributes are redacted. Screenshot capture refuses regions containing detected secure input unless the caller explicitly acknowledges the risk.
- Do not acknowledge secure-content screenshots unless the user understands what is visible and has asked for that capture.
- The MCP server is local and does not configure credentials. Your AI client still applies its own data-handling and tool-approval policies to any hierarchy, attributes, or screenshots it reads.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| The client cannot start `lookinside` | Confirm the command is an absolute path and the bundled executable passes the `test -x` check above. Official releases include it; a local source build may not. |
| `ping_host` says LookInside is not running | Launch the same LookInside app bundle referenced by the MCP command, then retry. |
| `list_targets` returns `[]` | Run the target app and connect to it from the LookInside launch window. Opening LookInside alone is not enough. |
| A target reports a blocked license state | Resolve activation in the LookInside app, reconnect the target, and run `list_targets` again. |
| Results describe the previous screen | Call `refresh_hierarchy`, then locate the views again instead of reusing old object identifiers. |
| `read_attributes` reports uncached details | Call `read_view_details` for that object identifier, then retry. |
| A screenshot is blank | Capture a descendant that performs the drawing; upper window, theme-frame, or hosting views can render no pixels by themselves. |
| The server was added but does not appear | Restart or open a new MCP client session and use the client's MCP status command or panel. |
