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

## Use it with AI agents

LookInside 2.3.11 and later include a local MCP server for Codex, Claude, Cursor, Windsurf, VS Code, and other MCP clients. Agents can inspect hierarchies, attributes, screenshots, and UI changes through the app you already opened in LookInside.

See the [MCP configuration and usage guide](docs/mcp.md).

## Use it from the terminal

Development builds include `lookinside-cli` for inspecting a running target without opening the LookInside window. The CLI starts a local service on demand and keeps inspection sessions between commands.

See the [command-line guide](docs/cli.md) for availability, commands, authorization, and session behavior.

## What you can inspect

- UIKit, AppKit, and SwiftUI view trees
- Frames, layers, screenshots, and resolved properties
- SwiftUI modifiers and layout details
- Live property changes while your app is running

## Add the server package

Use [LookInside-Release](https://github.com/LookInsideApp/LookInside-Release) with Swift Package Manager or CocoaPods.

## License

GPL-3.0. See [`LICENSE`](LICENSE).
