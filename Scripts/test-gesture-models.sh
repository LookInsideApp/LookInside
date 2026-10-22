#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GESTURE_TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/lookinside-gesture-models.XXXXXX")"
trap 'rm -rf "$GESTURE_TEST_DIR"' EXIT
swiftc -parse-as-library -import-objc-header "$ROOT/Sources/LookinCore/include/LookinHitTargetSize.h" \
	"$ROOT/LookInside/GestureDebug/GestureCaptureModels.swift" \
	"$ROOT/LookInside/GestureDebug/HitTargetSuggestions.swift" \
	"$ROOT/Tests/GestureDebug/GestureCaptureModelsTests.swift" -o "$GESTURE_TEST_DIR/gesture-models"
"$GESTURE_TEST_DIR/gesture-models"
