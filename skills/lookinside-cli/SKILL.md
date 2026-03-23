---
name: lookinside-cli
description: Use this skill when working with the LookInside command-line tool to discover inspectable iOS apps, inspect target metadata, fetch live hierarchies, export `.lookinside` or JSON snapshots, or explain what LookInside CLI output means. Trigger on requests involving `lookinside list`, `inspect`, `hierarchy`, `export`, target IDs, hierarchy trees, hierarchy JSON payloads, or README/docs/examples for the LookInside CLI.
---

# LookInside CLI

Use the repository's CLI to inspect live iOS app targets and capture hierarchy data.

## Quick Start

Work from the repository root so SwiftPM can find `Package.swift`.

Prefer the built binary for repeat commands:

```bash
.build/debug/lookinside list
```

If the binary is missing, build it first:

```bash
swift build -c debug --product lookinside
```

## Workflow

### 1. Discover targets

Start with `list`.

Use text mode for quick terminal inspection:

```bash
.build/debug/lookinside list
```

Use JSON when you need a stable shape for docs, parsing, or follow-up automation:

```bash
.build/debug/lookinside list --format json
```

Useful filters:

- `--transport simulator` or `--transport usb`
- `--name-contains <text>`
- `--bundle-id <bundle-id>`
- `--ids-only` for text mode pipelines

`targetID` values are runtime-discovered opaque strings like `simulator:47164:1774294178`.

### 2. Inspect one target

Use `inspect` to print metadata for a target returned by `list`.

```bash
.build/debug/lookinside inspect --target <id>
.build/debug/lookinside inspect --target <id> --format json
```

Prefer JSON when the user asks what fields exist or wants machine-readable output.

### 3. Fetch a live hierarchy

Use tree mode for human-readable terminal output:

```bash
.build/debug/lookinside hierarchy --target <id>
```

Use JSON for structured analysis:

```bash
.build/debug/lookinside hierarchy --target <id> --format json
```

Use `--output` when the result is too large for the terminal or the user wants an artifact:

```bash
.build/debug/lookinside hierarchy --target <id> --output /tmp/sample-tree.txt
```

### 4. Export a reusable snapshot

Use JSON when another tool should consume the hierarchy payload:

```bash
.build/debug/lookinside export --target <id> --output /tmp/sample.json --format json
```

Use archive output when the snapshot should be opened later in LookInside:

```bash
.build/debug/lookinside export --target <id> --output /tmp/sample.lookinside
```

Format rules:

- `--format auto` infers from the file extension
- JSON exports must use `.json`
- archive exports must use `.archive`, `.lookin`, or `.lookinside`
- archive output with no extension becomes `.lookinside`

## Output Reference

Read [output-shapes.md](references/output-shapes.md) when the user asks what the data looks like, wants example snippets for docs, or needs to know which fields exist in JSON output.

## Troubleshooting

- If `swift run lookinside ...` says `Could not find Package.swift`, change into the repo root first.
- If live discovery is flaky, re-run `list` immediately before `inspect`, `hierarchy`, or `export`.
- Prefer `.build/debug/lookinside` over repeated `swift run` calls once the CLI is built.
- Expect hierarchy JSON to be large; write it to a file when you only need a sample or want to inspect it incrementally.
