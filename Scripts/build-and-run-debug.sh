#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

pkill -x LookInside 2>/dev/null || true

cd "$PROJECT_DIR"
rm -rf build/derived
xcodebuild \
	-workspace LookInside.xcworkspace \
	-scheme LookInside \
	-configuration Debug \
	-destination 'platform=macOS' \
	-derivedDataPath build/derived \
	-skipMacroValidation \
	-skipPackagePluginValidation \
	CODE_SIGNING_ALLOWED=NO \
	build

open -n "$PROJECT_DIR/build/derived/Build/Products/Debug/LookInside.app"
