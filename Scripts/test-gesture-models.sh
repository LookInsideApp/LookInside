#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GESTURE_TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/lookinside-gesture-models.XXXXXX")"
trap 'rm -rf "$GESTURE_TEST_DIR"' EXIT
swiftc -parse-as-library "$ROOT/LookInside/GestureDebug/LKGestureCaptureModels.swift" \
	"$ROOT/Tests/GestureDebug/LKGestureCaptureModelsTests.swift" -o "$GESTURE_TEST_DIR/gesture-models"
"$GESTURE_TEST_DIR/gesture-models"
