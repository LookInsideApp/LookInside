#!/usr/bin/env bash
# Build the lookinside-mcp executable in release configuration and stage the
# binary at ./build/lookinside-mcp. Designed to be safe to re-run.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

OUT_DIR="$REPO_ROOT/build"
mkdir -p "$OUT_DIR"

echo "› swift build -c release --product lookinside-mcp"
swift build -c release --product lookinside-mcp

BIN_PATH="$(swift build -c release --product lookinside-mcp --show-bin-path)/lookinside-mcp"
cp "$BIN_PATH" "$OUT_DIR/lookinside-mcp"
chmod +x "$OUT_DIR/lookinside-mcp"

echo
echo "Built: $OUT_DIR/lookinside-mcp"
echo "Try:   $OUT_DIR/lookinside-mcp health"
echo "Or:    $OUT_DIR/lookinside-mcp print-config claude-desktop"
