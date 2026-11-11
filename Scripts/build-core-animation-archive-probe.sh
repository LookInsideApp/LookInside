#!/bin/sh
set -eu

# Builds the throwaway CoreAnimationArchiveProbe diagnostic
# (see Scripts/CoreAnimationArchiveProbe/main.swift) from the importer's own
# sources, the way Scripts/test-core-animation-archive.sh builds its tests.
# Usage: build-core-animation-archive-probe.sh [output-binary-path]

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_BINARY="${1:-$ROOT/build/CoreAnimationArchiveProbe/CoreAnimationArchiveProbe}"
WORK_DIR="$(dirname "$OUTPUT_BINARY")/objects"

SOURCE_DIR="$ROOT/LookInside/CoreAnimationArchive"
VIEW_HIERARCHY_DIR="$ROOT/LookInside/XcodeViewHierarchy"
LOOKIN_CORE_DIR="$ROOT/Sources/LookinCore"
LOOKIN_CORE_IMPL_DIR="$ROOT/Sources/LookinCoreImpl"
LOOKIN_SERVER_BASE_DIR="$ROOT/Sources/LookinServerBase"
DEPLOYMENT_TARGET=14.0

mkdir -p "$WORK_DIR"
for source_file in "$LOOKIN_CORE_DIR"/*.m "$LOOKIN_CORE_DIR"/Shim/*.m "$LOOKIN_SERVER_BASE_DIR"/*.m; do
	[ -e "$source_file" ] || continue
	xcrun clang -c -fobjc-arc -w -DSHOULD_COMPILE_LOOKIN_SERVER=1 \
		-mmacosx-version-min="$DEPLOYMENT_TARGET" \
		-I "$LOOKIN_CORE_DIR" -I "$LOOKIN_CORE_DIR/include" \
		-I "$LOOKIN_SERVER_BASE_DIR" \
		"$source_file" -o "$WORK_DIR/$(basename "$source_file" .m).o"
done

xcrun swiftc \
	-target "$(uname -m)-apple-macos$DEPLOYMENT_TARGET" \
	-import-objc-header "$ROOT/Tests/CoreAnimationArchive/CoreAnimationArchiveTests-Bridging-Header.h" \
	-Xcc -DSHOULD_COMPILE_LOOKIN_SERVER=1 \
	-D SHOULD_COMPILE_LOOKIN_SERVER -D LOOKIN_CORE_STANDALONE \
	-Xcc -I"$LOOKIN_CORE_DIR" -Xcc -I"$LOOKIN_CORE_DIR/include" \
	-Xcc -I"$LOOKIN_SERVER_BASE_DIR" \
	"$VIEW_HIERARCHY_DIR/XcodeViewHierarchyValue.swift" \
	"$VIEW_HIERARCHY_DIR/XcodeViewHierarchyObjectGraph.swift" \
	"$VIEW_HIERARCHY_DIR/XcodeViewHierarchyLayerArchive.swift" \
	"$VIEW_HIERARCHY_DIR/XcodeViewHierarchyLayerTopology.swift" \
	"$VIEW_HIERARCHY_DIR/XcodeViewHierarchyPixelRecovery.swift" \
	"$VIEW_HIERARCHY_DIR/XcodeViewHierarchyAttributeCatalog.swift" \
	"$SOURCE_DIR/CoreAnimationArchive.swift" \
	"$SOURCE_DIR/CoreAnimationArchivePixelRecovery.swift" \
	"$SOURCE_DIR/CoreAnimationArchiveConverter.swift" \
	$(find "$LOOKIN_CORE_IMPL_DIR" -name '*.swift' | sort) \
	"$ROOT/Scripts/CoreAnimationArchiveProbe/main.swift" \
	"$WORK_DIR"/*.o \
	-framework AppKit -framework QuartzCore \
	-o "$OUTPUT_BINARY"

echo "$OUTPUT_BINARY"
