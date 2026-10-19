#!/bin/sh
set -eu

# MessageAttribute's subscriptions: duplicates, related objects, targets that
# went away, and that subscribing many targets stays linear. The class only
# needs AppKit, so it compiles with its test into a standalone binary.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MESSAGE_ATTRIBUTE_TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/lookinside-message-attribute.XXXXXX")"
trap 'rm -rf "$MESSAGE_ATTRIBUTE_TEST_DIR"' EXIT
swiftc -parse-as-library -O \
	"$ROOT/LookInside/Base/Message/MessageAttribute.swift" \
	"$ROOT/Tests/Message/MessageAttributeTests.swift" -o "$MESSAGE_ATTRIBUTE_TEST_DIR/message-attribute"
"$MESSAGE_ATTRIBUTE_TEST_DIR/message-attribute"
