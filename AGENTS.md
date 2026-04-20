# AGENTS

## Purpose

This repository packages the LookInside desktop app, shared inspection runtime, and CLI in one GPL-3.0 monorepo. Agent work should preserve release readiness, compatibility, and a no-telemetry/no-auto-update distribution model.

## Current Product Boundaries

- Repository/product name: `LookInside`
- Compatibility/runtime names intentionally kept: `LookinServer`, `LookinShared`, `LookinCore`
- macOS GUI app entrypoint: [`LookInside.xcworkspace`](LookInside.xcworkspace)
- GUI scheme/target: `LookInside`
- SwiftPM root package: [`Package.swift`](Package.swift)
- CLI executable product: `lookinside`

Do not reintroduce analytics, crash upload SDKs, or automatic update frameworks unless the user explicitly asks for them.

## Repository Map

- [`LookInside/`](LookInside/): macOS app sources, resources, vendored dependencies, and derived shared-source mirror
- [`LookInside.xcodeproj`](LookInside.xcodeproj): macOS app project
- [`LookInside.xcworkspace`](LookInside.xcworkspace): macOS app workspace
- [`Sources/`](Sources/): canonical shared C/ObjC/Swift sources and CLI target
- [`Scripts/`](Scripts/): local helper scripts
- [`Resources/Licenses/`](Resources/Licenses/): upstream and third-party notices

The top-level [`App/`](App/) directory is not the active app workspace entrypoint for the current repository layout.

## Dependency Rules

- SwiftPM is used for the root package and CLI.
- The macOS app must remain CocoaPods-free.
- `ReactiveObjC` is vendored under [`LookInside/ReactiveObjC`](LookInside/ReactiveObjC) and compiled directly by the app target.
- Canonical shared app/runtime source lives in [`Sources/LookinCore`](Sources/LookinCore) and [`Sources/LookinServerBase`](Sources/LookinServerBase).
- The macOS app compiles mirrored copies under [`LookInside/DerivedSource`](LookInside/DerivedSource); refresh them with [`Scripts/sync-derived-source.sh`](Scripts/sync-derived-source.sh) instead of editing `DerivedSource` manually.
- Do not reintroduce `Podfile`, `Pods/`, `[CP]` build phases, or Pods xcconfig references unless the user explicitly asks for CocoaPods again.

## Build Commands

### Root package

```bash
bash Scripts/sync-derived-source.sh
swift build
swift build -c debug --product lookinside
```

### App workspace

```bash
xcodebuild -skipMacroValidation -project LookInside.xcodeproj -scheme LookInside -configuration Debug -derivedDataPath /tmp/LookInsideDerivedData CODE_SIGNING_ALLOWED=NO build
```

## Release Expectations

- Keep README accurate to the current dependency graph and distribution model.
- Keep release artifacts free of AppCenter, Sparkle, and similar hosted services unless explicitly requested.
- Preserve upstream attribution to Lookin and LookinServer.
- Prefer compatibility-safe renames. Public branding can change faster than runtime module names.
- Keep [`Scripts/test.sh`](Scripts/test.sh) and [`Scripts/sync-derived-source.sh`](Scripts/sync-derived-source.sh) aligned with the actual workspace, scheme, and shared-source layout.

## Validation Checklist

Before calling a release-ready change complete:

1. Run `bash Scripts/sync-derived-source.sh`.
2. Run `swift build`.
3. Run `swift build -c debug --product lookinside`.
4. Run `xcodebuild -skipMacroValidation -project LookInside.xcodeproj -scheme LookInside -configuration Debug -derivedDataPath /tmp/LookInsideDerivedData CODE_SIGNING_ALLOWED=NO build`.
5. Confirm `bash Scripts/test.sh` matches the current workspace/scheme paths, then run it.
6. Smoke-check that the app launches, opens a target, and exports a hierarchy archive.
7. Confirm README and dependency declarations match the actual workspace state.
