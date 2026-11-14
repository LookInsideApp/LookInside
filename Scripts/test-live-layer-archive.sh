#!/bin/sh
set -eu

# Host-side tests for drawing a live macOS session's node images from the
# layer archives its Server encodes (LookinRequestTypeLayerArchive, 211).
#
# Like the .caar tests, the units are compiled together with their test file
# into a standalone binary and run. The archive decoder and the renderer come
# from the .caar and .viewhierarchy imports, the reply type from
# LookinCoreImpl; the decoder calls LookinCatchException, so LookinCore's C
# side is compiled in.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="${TMPDIR:-/tmp}/lookinside-live-layer-archive-tests.$$"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

SOURCE_DIR="$ROOT/LookInside/LiveLayerArchive"
TEST_DIR="$ROOT/Tests/LiveLayerArchive"
CORE_ANIMATION_ARCHIVE_DIR="$ROOT/LookInside/CoreAnimationArchive"
VIEW_HIERARCHY_DIR="$ROOT/LookInside/XcodeViewHierarchy"
LOOKIN_CORE_DIR="$ROOT/Sources/LookinCore"
LOOKIN_CORE_IMPL_DIR="$ROOT/Sources/LookinCoreImpl"
LOOKIN_SERVER_BASE_DIR="$ROOT/Sources/LookinServerBase"
# The app's deployment target.
DEPLOYMENT_TARGET=14.0

mkdir -p "$TMPDIR/lookin-core"
for source_file in "$LOOKIN_CORE_DIR"/*.m "$LOOKIN_CORE_DIR"/Shim/*.m "$LOOKIN_SERVER_BASE_DIR"/*.m; do
	[ -e "$source_file" ] || continue
	xcrun clang -c -fobjc-arc -w -DSHOULD_COMPILE_LOOKIN_SERVER=1 \
		-mmacosx-version-min="$DEPLOYMENT_TARGET" \
		-I "$LOOKIN_CORE_DIR" -I "$LOOKIN_CORE_DIR/include" \
		-I "$LOOKIN_SERVER_BASE_DIR" \
		"$source_file" -o "$TMPDIR/lookin-core/$(basename "$source_file" .m).o"
done

# Decoding a window's archive and checking it against the Server's walk.
swiftc -parse-as-library \
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
	"$CORE_ANIMATION_ARCHIVE_DIR/CoreAnimationArchive.swift" \
	"$CORE_ANIMATION_ARCHIVE_DIR/CoreAnimationArchivePixelRecovery.swift" \
	"$SOURCE_DIR/LiveLayerArchive.swift" \
	"$SOURCE_DIR/LiveLayerArchiveImages.swift" \
	$(find "$LOOKIN_CORE_IMPL_DIR" -name '*.swift' | sort) \
	"$TEST_DIR/LiveLayerArchiveTests.swift" \
	"$TMPDIR"/lookin-core/*.o \
	-framework AppKit -framework QuartzCore -framework Metal \
	-o "$TMPDIR/live-layer-archive-test"
"$TMPDIR/live-layer-archive-test"

echo "Live layer archive tests passed"
