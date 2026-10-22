#!/bin/bash

# Builds the throwaway ViewHierarchyProbe diagnostic (see Scripts/ViewHierarchyProbe/main.swift).
# Usage: build-viewhierarchy-probe.sh [output-binary-path]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_BINARY="${1:-$ROOT/build/ViewHierarchyProbe/ViewHierarchyProbe}"

mkdir -p "$(dirname "$OUTPUT_BINARY")"

xcrun swiftc \
	-O \
	-target arm64-apple-macos14.0 \
	-framework AppKit \
	"$ROOT/Scripts/ViewHierarchyProbe/main.swift" \
	-o "$OUTPUT_BINARY"

echo "$OUTPUT_BINARY"
