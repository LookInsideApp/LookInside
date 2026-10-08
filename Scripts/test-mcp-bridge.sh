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

# The identifier list needs LKMCPBridgeFrame.swift alongside it for
# LKMCPBridgeJSONValue; that file is Foundation-only, so it compiles here.
FRAME="$ROOT/LookInside/MCPBridge/LKMCPBridgeFrame.swift"
OBJECT_IDENTIFIER_LIST="$ROOT/LookInside/MCPBridge/MCPBridgeObjectIdentifierList.swift"
OBJECT_IDENTIFIER_LIST_TEST="$ROOT/Tests/MCPBridge/MCPBridgeObjectIdentifierListTests.swift"

swiftc -parse-as-library "$FRAME" "$OBJECT_IDENTIFIER_LIST" "$OBJECT_IDENTIFIER_LIST_TEST" -o "$TMPDIR/object-identifier-list-test"
"$TMPDIR/object-identifier-list-test"

echo "MCPBridge tests passed"
