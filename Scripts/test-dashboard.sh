#!/bin/sh
set -eu

# Host-side tests for the Dashboard's payload and display rules.
#
# The modification payloads, the edited values, the enum lists and the JSON
# attribute tree are kept in Foundation-only files that depend on the
# LookinCore model alone, so they compile here with LookinCore into a
# standalone binary, without building or launching the app.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="${TMPDIR:-/tmp}/lookinside-dashboard-tests.$$"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

SOURCE_DIR="$ROOT/LookInside/Dashboard"
TEST_DIR="$ROOT/Tests/Dashboard"
LOOKIN_CORE_DIR="$ROOT/Sources/LookinCore"
# LookinDisplayItem pulls one header from the server base sources.
LOOKIN_SERVER_BASE_DIR="$ROOT/Sources/LookinServerBase"
# The Swift `@objc @implementation` of the LookinCore model classes.
LOOKIN_CORE_IMPL_DIR="$ROOT/Sources/LookinCoreImpl"
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
	-import-objc-header "$TEST_DIR/LKDashboardTests-Bridging-Header.h" \
	-Xcc -DSHOULD_COMPILE_LOOKIN_SERVER=1 \
	-D SHOULD_COMPILE_LOOKIN_SERVER -D LOOKIN_CORE_STANDALONE \
	-Xcc -I"$LOOKIN_CORE_DIR" -Xcc -I"$LOOKIN_CORE_DIR/include" \
	-Xcc -I"$LOOKIN_SERVER_BASE_DIR" \
	"$SOURCE_DIR/LKDashboardModification.swift" \
	"$SOURCE_DIR/LKEnumListRegistry.swift" \
	"$SOURCE_DIR/AttributeView/JSON/LKJSONAttributeItem.swift" \
	$(find "$LOOKIN_CORE_IMPL_DIR" -name '*.swift' | sort) \
	"$TEST_DIR/LKDashboardTests.swift" \
	"$TMPDIR"/lookin-core/*.o \
	-framework AppKit -framework QuartzCore \
	-o "$TMPDIR/dashboard-test"
"$TMPDIR/dashboard-test" "$TEST_DIR/Fixtures"

echo "Dashboard tests passed"
