#!/bin/sh
set -eu

# Host-side MCPBridge tests.
#
# Same shape as test-security-gates.sh: compile the unit under test
# together with its test file into a standalone binary and run it. Only
# units that depend on Darwin / Foundation alone can be covered this
# way -- the routing services pull in AppKit, NSDocumentController and
# the inspector's documents, so they are exercised end to end against a
# running Host instead (see docs/mcp.md).

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="${TMPDIR:-/tmp}/lookinside-mcp-bridge-tests.$$"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

LISTEN_SOCKET="$ROOT/LookInside/MCPBridge/MCPBridgeListenSocket.swift"
LISTEN_SOCKET_TEST="$ROOT/Tests/MCPBridge/MCPBridgeListenSocketTests.swift"

swiftc -parse-as-library "$LISTEN_SOCKET" "$LISTEN_SOCKET_TEST" -o "$TMPDIR/listen-socket-test"
"$TMPDIR/listen-socket-test"

SEARCH_QUERY="$ROOT/LookInside/MCPBridge/MCPBridgeSearchQuery.swift"
SEARCH_QUERY_TEST="$ROOT/Tests/MCPBridge/MCPBridgeSearchQueryTests.swift"

swiftc -parse-as-library "$SEARCH_QUERY" "$SEARCH_QUERY_TEST" -o "$TMPDIR/search-query-test"
"$TMPDIR/search-query-test"

# The identifier list needs MCPBridgeFrame.swift alongside it for
# MCPBridgeJSONValue; that file is Foundation-only, so it compiles here.
FRAME="$ROOT/LookInside/MCPBridge/MCPBridgeFrame.swift"
OBJECT_IDENTIFIER_LIST="$ROOT/LookInside/MCPBridge/MCPBridgeObjectIdentifierList.swift"
OBJECT_IDENTIFIER_LIST_TEST="$ROOT/Tests/MCPBridge/MCPBridgeObjectIdentifierListTests.swift"

swiftc -parse-as-library "$FRAME" "$OBJECT_IDENTIFIER_LIST" "$OBJECT_IDENTIFIER_LIST_TEST" -o "$TMPDIR/object-identifier-list-test"
"$TMPDIR/object-identifier-list-test"

RECOVERY_HINT="$ROOT/LookInside/MCPBridge/MCPBridgeRecoveryHint.swift"
RECOVERY_HINT_TEST="$ROOT/Tests/MCPBridge/MCPBridgeRecoveryHintTests.swift"

swiftc -parse-as-library "$RECOVERY_HINT" "$RECOVERY_HINT_TEST" -o "$TMPDIR/recovery-hint-test"
"$TMPDIR/recovery-hint-test"

# Exercise virtual-node identity against the real wire model. Only the C
# declarations are imported; Swift model implementations compile alongside it.
CORE="$ROOT/Sources/LookinCore"
SERVER_BASE="$ROOT/Sources/LookinServerBase"
mkdir -p "$TMPDIR/core"
for source_file in "$CORE"/*.m "$CORE"/Shim/*.m "$SERVER_BASE"/*.m; do
	[ -e "$source_file" ] || continue
	xcrun clang -c -fobjc-arc -w -DSHOULD_COMPILE_LOOKIN_SERVER=1 \
		-mmacosx-version-min=14.0 -I "$CORE" -I "$CORE/include" -I "$SERVER_BASE" \
		"$source_file" -o "$TMPDIR/core/$(basename "$source_file" .m).o"
done
swiftc -parse-as-library -target "$(uname -m)-apple-macos14.0" \
	-import-objc-header "$ROOT/Tests/Dashboard/LKDashboardTests-Bridging-Header.h" \
	-Xcc -DSHOULD_COMPILE_LOOKIN_SERVER=1 -D SHOULD_COMPILE_LOOKIN_SERVER -D LOOKIN_CORE_STANDALONE \
	-Xcc -I"$CORE" -Xcc -I"$CORE/include" -Xcc -I"$SERVER_BASE" \
	$(find "$ROOT/Sources/LookinCoreImpl" -name '*.swift' -type f | sort) \
	"$ROOT/LookInside/MCPBridge/MCPBridgeDisplayItemAccess.swift" \
	"$ROOT/Tests/MCPBridge/MCPBridgeDisplayItemAccessTests.swift" \
	"$TMPDIR"/core/*.o -framework AppKit -framework QuartzCore -o "$TMPDIR/display-item-test"
"$TMPDIR/display-item-test"

echo "MCPBridge tests passed"
