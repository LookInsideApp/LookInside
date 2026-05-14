# Connecting `lookinside-mcp` to MCP clients

Always start with `lookinside-mcp print-config <client>` — it prints the snippet below with the binary's absolute path filled in.

## Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "lookinside": {
      "command": "/absolute/path/to/lookinside-mcp",
      "args": ["serve"]
    }
  }
}
```

Restart Claude Desktop. The 🔌 indicator should show `lookinside` connected.

## Claude Code

```sh
claude mcp add lookinside /absolute/path/to/lookinside-mcp serve
```

## Cursor

Edit `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "lookinside": {
      "command": "/absolute/path/to/lookinside-mcp",
      "args": ["serve"]
    }
  }
}
```

## Windsurf

Edit `~/.codeium/windsurf/mcp_config.json` with the same shape as Cursor.

## VS Code (Copilot Chat / Continue / Claude extension)

Under your MCP-aware extension's config block:

```json
"lookinside": {
  "command": "/absolute/path/to/lookinside-mcp",
  "args": ["serve"]
}
```

## Custom — anything that speaks MCP

`lookinside-mcp serve` reads JSON-RPC framed by newlines on stdin and writes responses to stdout. Stderr is reserved for human-readable diagnostics. No environment variables are required.

## Example prompts

After connecting, try:

- "Inspect the current screen using lookinside and summarize the layout."
- "Find every UILabel with empty text on this screen."
- "Run accessibility diagnostics and propose fixes."
- "Export a bug report with screenshot for the current screen."
- "Highlight the element with text 'Continue'."

## Offline / snapshot mode

To analyze a captured `.lookin` snapshot:

```json
{
  "mcpServers": {
    "lookinside-offline": {
      "command": "/absolute/path/to/lookinside-mcp",
      "args": ["serve", "--snapshot", "/abs/path/to/snapshot.lookin"]
    }
  }
}
```
