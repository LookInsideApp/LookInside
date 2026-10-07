#!/bin/sh
set -eu

# Host-side tests for the Launch, Toolbar and Read modules.
#
# The logic under test lives in Foundation-only Swift files (the .lookin
# archive coding, the reader's screenshot lookup, the apps popover copy, the
# toolbar identifiers and steppers). They are compiled with the test file and
# the LookinCore objects into a standalone binary, the same way
# test-xcode-viewhierarchy.sh covers the Xcode capture converter.
#
# --make-fixture rebuilds Tests/Read/Fixtures/legacy-host.lookin with the
# Objective-C generator instead. The committed fixture was made from the
# encoding call of the Objective-C reader; do not regenerate it from the
# Swift code under test.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# A fresh directory per run: objects left over from an earlier layout (an
# Objective-C model file that is Swift now) would otherwise link twice.
WORK="${TMPDIR:-/tmp}/lookinside-launch-toolbar-read-tests.$$"
mkdir -p "$WORK/lookin-core"
trap 'rm -rf "$WORK"' EXIT

SOURCE_DIR="$ROOT/LookInside"
TEST_DIR="$ROOT/Tests/Read"
LOOKIN_CORE_DIR="$ROOT/Sources/LookinCore"
LOOKIN_SERVER_BASE_DIR="$ROOT/Sources/LookinServerBase"
# The Swift `@objc @implementation` of the LookinCore model classes.
LOOKIN_CORE_IMPL_DIR="$ROOT/Sources/LookinCoreImpl"
DEPLOYMENT_TARGET=14.0

for source_file in "$LOOKIN_CORE_DIR"/*.m "$LOOKIN_CORE_DIR"/Shim/*.m "$LOOKIN_SERVER_BASE_DIR"/*.m; do
	[ -e "$source_file" ] || continue
	xcrun clang -c -fobjc-arc -w -DSHOULD_COMPILE_LOOKIN_SERVER=1 \
		-mmacosx-version-min="$DEPLOYMENT_TARGET" \
		-I "$LOOKIN_CORE_DIR" -I "$LOOKIN_CORE_DIR/include" \
		-I "$LOOKIN_SERVER_BASE_DIR" \
		"$source_file" -o "$WORK/lookin-core/$(basename "$source_file" .m).o"
done

if [ "${1:-}" = "--make-fixture" ]; then
	xcrun clang -c -fobjc-arc -DSHOULD_COMPILE_LOOKIN_SERVER=1 \
		-mmacosx-version-min="$DEPLOYMENT_TARGET" \
		-I "$LOOKIN_CORE_DIR" -I "$LOOKIN_CORE_DIR/include" \
		-I "$LOOKIN_SERVER_BASE_DIR" \
		"$TEST_DIR/LookinArchiveFixtureGenerator.m" -o "$WORK/fixture-generator.o"
	# The model classes are Swift: swiftc links them (and the Swift runtime)
	# with the Objective-C generator, whose main() is the entry point.
	swiftc -parse-as-library \
		-target "$(uname -m)-apple-macos$DEPLOYMENT_TARGET" \
		-import-objc-header "$TEST_DIR/LaunchToolbarReadTests-Bridging-Header.h" \
		-Xcc -DSHOULD_COMPILE_LOOKIN_SERVER=1 \
		-D SHOULD_COMPILE_LOOKIN_SERVER -D LOOKIN_CORE_STANDALONE \
		-Xcc -I"$LOOKIN_CORE_DIR" -Xcc -I"$LOOKIN_CORE_DIR/include" \
		-Xcc -I"$LOOKIN_SERVER_BASE_DIR" \
		$(find "$LOOKIN_CORE_IMPL_DIR" -name '*.swift' | sort) \
		"$WORK/fixture-generator.o" "$WORK"/lookin-core/*.o \
		-framework AppKit -framework QuartzCore \
		-o "$WORK/fixture-generator"
	"$WORK/fixture-generator" "$TEST_DIR/Fixtures/legacy-host.lookin"
	exit 0
fi

swiftc -parse-as-library \
	-target "$(uname -m)-apple-macos$DEPLOYMENT_TARGET" \
	-import-objc-header "$TEST_DIR/LaunchToolbarReadTests-Bridging-Header.h" \
	-Xcc -DSHOULD_COMPILE_LOOKIN_SERVER=1 \
	-D SHOULD_COMPILE_LOOKIN_SERVER -D LOOKIN_CORE_STANDALONE \
	-Xcc -I"$LOOKIN_CORE_DIR" -Xcc -I"$LOOKIN_CORE_DIR/include" \
	-Xcc -I"$LOOKIN_SERVER_BASE_DIR" \
	"$SOURCE_DIR/Read/LookinArchiveCoding.swift" \
	"$SOURCE_DIR/Read/LKReadScreenshotLookup.swift" \
	"$SOURCE_DIR/Toolbar/LKToolbarRules.swift" \
	"$SOURCE_DIR/Launch/LKLaunchRules.swift" \
	$(find "$LOOKIN_CORE_IMPL_DIR" -name '*.swift' | sort) \
	"$TEST_DIR/LaunchToolbarReadTests.swift" \
	"$WORK"/lookin-core/*.o \
	-framework AppKit -framework QuartzCore \
	-o "$WORK/launch-toolbar-read-test"
"$WORK/launch-toolbar-read-test" "$TEST_DIR/Fixtures/legacy-host.lookin"

echo "Launch / Toolbar / Read tests passed"
