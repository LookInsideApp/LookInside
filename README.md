# LookInside

LookInside is a Mac app that lets you click through your iOS or macOS app UI and see every view, layer, frame, and property live.

![Preview](./Resources/SCR-20260502-svqx.jpeg)

- Website: [lookinside-app.com](https://lookinside-app.com)
- Server package: [LookInside-Release](https://github.com/LookInsideApp/LookInside-Release)

LookInside continues the work of [Lookin](https://lookin.work/), the original iOS view debugger.

## Use it

1. Download LookInside from the [Releases page](https://github.com/LookInsideApp/LookInside/releases).
2. Add the server package to the app you want to inspect.
3. Run your app.
4. Open LookInside on your Mac and pick the running app.

## What you can inspect

- UIKit, AppKit, and SwiftUI view trees
- Frames, layers, screenshots, and resolved properties
- SwiftUI modifiers and layout details
- Live property changes while your app is running

## Add the server package

Use [LookInside-Release](https://github.com/LookInsideApp/LookInside-Release) with Swift Package Manager or CocoaPods.

## MCP integration (Debug)

LookInside ships an optional MCP server, `lookinside-mcp`, so AI coding agents (Claude Desktop, Claude Code, Cursor, Windsurf, VS Code, …) can inspect the running Debug build directly — hierarchy, screenshots, element search, highlight, layout/accessibility diagnostics, and a one-shot bug report.

Build and try it:

```sh
./Scripts/build-mcp-server.sh
./build/lookinside-mcp health
./build/lookinside-mcp print-config claude-desktop
```

See [docs/mcp.md](docs/mcp.md) for the full feature set, [docs/mcp-client-configs.md](docs/mcp-client-configs.md) for client setup, and [docs/mcp-troubleshooting.md](docs/mcp-troubleshooting.md) if something looks off.

## License

GPL-3.0. See [`LICENSE`](LICENSE).
