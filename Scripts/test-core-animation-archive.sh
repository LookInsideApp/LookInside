#!/bin/sh
set -eu

# Host-side tests for opening Core Animation archives (.caar), the files the
# AppKit debug menu's Dump Layer writes.
#
# Like the .viewhierarchy tests, each unit is compiled together with its test
# file into a standalone binary and run. The decoder calls
# LookinCatchException, so LookinCore's C side is compiled in; the converter
# builds LookinDisplayItem trees, so it also needs the LookinCoreImpl model.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="${TMPDIR:-/tmp}/lookinside-core-animation-archive-tests.$$"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

SOURCE_DIR="$ROOT/LookInside/CoreAnimationArchive"
TEST_DIR="$ROOT/Tests/CoreAnimationArchive"
LOOKIN_CORE_DIR="$ROOT/Sources/LookinCore"
LOOKIN_SERVER_BASE_DIR="$ROOT/Sources/LookinServerBase"
# The app's deployment target; against the bare SDK the model's window
# capture call is already obsoleted.
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

# Decoding: QuartzCore's own encoder against the reader, plus the files a
# reader must refuse without raising, and the Dump Layer file name.
swiftc -parse-as-library \
	-target "$(uname -m)-apple-macos$DEPLOYMENT_TARGET" \
	-import-objc-header "$TEST_DIR/CoreAnimationArchiveTests-Bridging-Header.h" \
	-Xcc -DSHOULD_COMPILE_LOOKIN_SERVER=1 \
	-Xcc -I"$LOOKIN_CORE_DIR" -Xcc -I"$LOOKIN_CORE_DIR/include" \
	-Xcc -I"$LOOKIN_SERVER_BASE_DIR" \
	"$SOURCE_DIR/CoreAnimationArchive.swift" \
	"$TEST_DIR/CoreAnimationArchiveDecodingTests.swift" \
	"$TMPDIR"/lookin-core/*.o \
	-framework AppKit -framework QuartzCore \
	-o "$TMPDIR/decoding-test"
"$TMPDIR/decoding-test"

# Numbering, rendering and conversion into the inspector's model. The
# rendering primitives and the dashboard's card order come from the
# .viewhierarchy import, and the model from LookinCoreImpl.
VIEW_HIERARCHY_DIR="$ROOT/LookInside/XcodeViewHierarchy"
LOOKIN_CORE_IMPL_DIR="$ROOT/Sources/LookinCoreImpl"
swiftc -parse-as-library \
	-target "$(uname -m)-apple-macos$DEPLOYMENT_TARGET" \
	-import-objc-header "$TEST_DIR/CoreAnimationArchiveTests-Bridging-Header.h" \
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
	"$TEST_DIR/CoreAnimationArchiveConverterTests.swift" \
	"$TMPDIR"/lookin-core/*.o \
	-framework AppKit -framework QuartzCore \
	-o "$TMPDIR/converter-test"
"$TMPDIR/converter-test"

echo "Core Animation archive tests passed"
