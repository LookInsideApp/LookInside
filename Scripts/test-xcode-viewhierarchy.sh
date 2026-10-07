#!/bin/sh
set -eu

# Host-side tests for reading Xcode-exported .viewhierarchy documents.
#
# Compile the unit under test together with its test file into a standalone
# binary and run it. The parsing layer is deliberately Foundation-only so it
# can be covered this way; the pixel recovery and conversion layers pull in
# QuartzCore and the ObjC model and are exercised against real captures
# instead.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="${TMPDIR:-/tmp}/lookinside-xcode-viewhierarchy-tests.$$"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

SOURCE_DIR="$ROOT/LookInside/XcodeViewHierarchy"
TEST_DIR="$ROOT/Tests/XcodeViewHierarchy"

# Gzip inflation: response entries are gzip members whose header length varies,
# and whose payload exceeds the inflater's buffer.
swiftc -parse-as-library \
	"$SOURCE_DIR/LKXcodeViewHierarchyGzip.swift" \
	"$TEST_DIR/LKXcodeViewHierarchyGzipTests.swift" \
	-o "$TMPDIR/gzip-test"
"$TMPDIR/gzip-test"

# Property value decoding: the format-specifier scheme, including the
# hexadecimal floats and the per-specifier integer radix.
swiftc -parse-as-library \
	"$SOURCE_DIR/LKXcodeViewHierarchyValue.swift" \
	"$TEST_DIR/LKXcodeViewHierarchyValueTests.swift" \
	-o "$TMPDIR/value-test"
"$TMPDIR/value-test"

# Object graph assembly: merge rules across responses.
swiftc -parse-as-library \
	"$SOURCE_DIR/LKXcodeViewHierarchyValue.swift" \
	"$SOURCE_DIR/LKXcodeViewHierarchyObjectGraph.swift" \
	"$TEST_DIR/LKXcodeViewHierarchyObjectGraphTests.swift" \
	-o "$TMPDIR/object-graph-test"
"$TMPDIR/object-graph-test"

# Pixel recovery: the two-part orientation correction for y-down captures.
swiftc -parse-as-library \
	"$SOURCE_DIR/LKXcodeViewHierarchyValue.swift" \
	"$SOURCE_DIR/LKXcodeViewHierarchyObjectGraph.swift" \
	"$SOURCE_DIR/LKXcodeViewHierarchyLayerArchive.swift" \
	"$SOURCE_DIR/LKXcodeViewHierarchyLayerTopology.swift" \
	"$SOURCE_DIR/LKXcodeViewHierarchyPixelRecovery.swift" \
	"$TEST_DIR/LKXcodeViewHierarchyPixelRecoveryTests.swift" \
	-o "$TMPDIR/pixel-recovery-test"
"$TMPDIR/pixel-recovery-test"

# Conversion into the inspector's model: the converter and the attribute
# builder produce LookinDisplayItem trees, so the Objective-C model
# (LookinCore, system frameworks only) is compiled in alongside them. The
# cases guard the fields whose Objective-C defaults differ from what the
# reader expects — the one place such defaults are neither set by the server
# nor patched by the archive decoder.
LOOKIN_CORE_DIR="$ROOT/Sources/LookinCore"
# LookinDisplayItem pulls one header from the server base sources.
LOOKIN_SERVER_BASE_DIR="$ROOT/Sources/LookinServerBase"
# The Swift `@objc @implementation` of the LookinCore model classes.
LOOKIN_CORE_IMPL_DIR="$ROOT/Sources/LookinCoreImpl"
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
swiftc -parse-as-library \
	-target "$(uname -m)-apple-macos$DEPLOYMENT_TARGET" \
	-import-objc-header "$TEST_DIR/LKXcodeViewHierarchyConverterTests-Bridging-Header.h" \
	-Xcc -DSHOULD_COMPILE_LOOKIN_SERVER=1 \
	-D SHOULD_COMPILE_LOOKIN_SERVER -D LOOKIN_CORE_STANDALONE \
	-Xcc -I"$LOOKIN_CORE_DIR" -Xcc -I"$LOOKIN_CORE_DIR/include" \
	-Xcc -I"$LOOKIN_SERVER_BASE_DIR" \
	"$SOURCE_DIR/LKXcodeViewHierarchyGzip.swift" \
	"$SOURCE_DIR/LKXcodeViewHierarchyValue.swift" \
	"$SOURCE_DIR/LKXcodeViewHierarchyObjectGraph.swift" \
	"$SOURCE_DIR/LKXcodeViewHierarchyBundleReader.swift" \
	"$SOURCE_DIR/LKXcodeViewHierarchyLayerArchive.swift" \
	"$SOURCE_DIR/LKXcodeViewHierarchyLayerTopology.swift" \
	"$SOURCE_DIR/LKXcodeViewHierarchyPixelRecovery.swift" \
	"$SOURCE_DIR/LKXcodeViewHierarchyAttributeCatalog.swift" \
	"$SOURCE_DIR/LKXcodeViewHierarchyAttributes.swift" \
	"$SOURCE_DIR/LKXcodeViewHierarchyConverter.swift" \
	$(find "$LOOKIN_CORE_IMPL_DIR" -name '*.swift' | sort) \
	"$TEST_DIR/LKXcodeViewHierarchyConverterTests.swift" \
	"$TMPDIR"/lookin-core/*.o \
	-framework AppKit -framework QuartzCore \
	-o "$TMPDIR/converter-test"
"$TMPDIR/converter-test"

echo "Xcode view hierarchy tests passed"
