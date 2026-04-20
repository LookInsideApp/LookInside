# LookInside

LookInside is a macOS UI inspector for debuggable macOS and iOS apps.

![Preview](./Resources/SCR-20260330-ccud.png)

This repository hosts the macOS client app in [`LookInside/`](LookInside/), [`LookInside.xcodeproj`](LookInside.xcodeproj), and [`LookInside.xcworkspace`](LookInside.xcworkspace). The embeddable server runtime and `lookinside` CLI live in the MIT-licensed [`LookInsideApp/LookInsideServer`](https://github.com/LookInsideApp/LookInsideServer) repository and are consumed here as a SwiftPM dependency.

LookInside is a community continuation of Lookin. The public product name in this repository is `LookInside`, while compatibility module names such as `LookinServer`, `LookinShared`, and `LookinCore` are intentionally preserved to reduce migration friction for existing integrations.

The project ships without telemetry, crash upload, or automatic update services.

## What It Does

LookInside can:

- discover inspectable macOS targets, iOS Simulator apps, and USB-connected devices
- inspect target metadata
- fetch live view hierarchies
- export hierarchy archives for later analysis

GitHub releases also include the notarized `lookinside` CLI built from [`LookInsideServer`](https://github.com/LookInsideApp/LookInsideServer) at the matching tag.

## Build

### Requirements

- macOS
- Xcode and command line tools
- a debuggable macOS or iOS app running locally, in Simulator, or on a connected device if you want to inspect something live

### Build the macOS app

```bash
swift package resolve
bash Scripts/sync-derived-source.sh
xcodebuild -project LookInside.xcodeproj -scheme LookInside -configuration Debug -derivedDataPath /tmp/LookInsideDerivedData CODE_SIGNING_ALLOWED=NO build
```

`swift package resolve` fetches [`LookInsideServer`](https://github.com/LookInsideApp/LookInsideServer) into `.build/checkouts/`. `Scripts/sync-derived-source.sh` mirrors the shared runtime sources from that checkout into [`LookInside/DerivedSource`](LookInside/DerivedSource), which the Xcode project compiles against.

### Local Release

To run a signed local release build, bump the app version, notarize it, push the release tag, and publish a GitHub Release from your machine:

```bash
bash Scripts/build-and-release.sh
```

By default the script increments the app target's patch version and build number. You can override the version explicitly with `--version x.y.z`.

## Integrating the Server

The embeddable in-app server and the `lookinside` CLI are MIT-licensed and live in [`LookInsideApp/LookInsideServer`](https://github.com/LookInsideApp/LookInsideServer). Add them to your app via SwiftPM:

```swift
.package(url: "https://github.com/LookInsideApp/LookInsideServer.git", from: "1.0.0")
```

See that repository for CLI usage, integration notes, and samples.

## Project Notes

- `ReactiveObjC` is vendored under [`LookInside/ReactiveObjC`](LookInside/ReactiveObjC)
- `ShortCocoa` is vendored under [`LookInside/ShortCocoa`](LookInside/ShortCocoa) and distributed here on the same GPL-3.0 basis as upstream Lookin; see [`Resources/Licenses/ShortCocoa.md`](Resources/Licenses/ShortCocoa.md)
- shared runtime sources are pulled from the `LookInsideServer` SwiftPM checkout and mirrored into [`LookInside/DerivedSource`](LookInside/DerivedSource) by `Scripts/sync-derived-source.sh`; changes to the shared runtime should be made in the `LookInsideServer` repository

## License

This repository is distributed under GPL-3.0. See [`LICENSE`](LICENSE) and preserved third-party notices in [`Resources/Licenses/`](Resources/Licenses/).

Notable bundled components:

- `ReactiveObjC`: MIT, see [`Resources/Licenses/ReactiveObjC.md`](Resources/Licenses/ReactiveObjC.md)
- `ShortCocoa`: distributed in this repository on the same GPL-3.0 basis as upstream Lookin, see [`Resources/Licenses/ShortCocoa.md`](Resources/Licenses/ShortCocoa.md)
- `Lookin` upstream client code: GPL-3.0, see [`Resources/Licenses/LookinClient.txt`](Resources/Licenses/LookinClient.txt)
- shared MIT runtime sources pulled from [`LookInsideServer`](https://github.com/LookInsideApp/LookInsideServer)

## Acknowledgements

LookInside is derived from upstream Lookin work and keeps compatibility with that ecosystem where practical.

Primary upstream references:

- `CocoaUIInspector/Lookin`
- `QMUI/LookinServer`
