#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")/.."

export HOME="${HOME:-/tmp/lookinside-home}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/lookinside-xdg-cache}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/tmp/clang-module-cache}"
export SWIFTPM_MODULECACHE_OVERRIDE="${SWIFTPM_MODULECACHE_OVERRIDE:-/tmp/swiftpm-module-cache}"

mkdir -p \
    "$HOME" \
    "$XDG_CACHE_HOME" \
    "$CLANG_MODULE_CACHE_PATH" \
    "$SWIFTPM_MODULECACHE_OVERRIDE"

format_output() {
    if command -v xcbeautify >/dev/null 2>&1; then
        xcbeautify --disable-logging
    else
        cat
    fi
}

run_command() {
    local label="$1"
    shift

    echo "[*] $label"
    "$@" 2>&1 | format_output
    local exit_code=${PIPESTATUS[0]}
    if [ "$exit_code" -ne 0 ]; then
        echo "[!] failed: $label"
        exit "$exit_code"
    fi
}

run_swift_build() {
    local description="$1"
    shift
    run_command "$description" swift "$@" --disable-sandbox
}

run_xcode_build() {
    local scheme="$1"
    local configuration="$2"
    run_command \
        "xcodebuild scheme=$scheme configuration=$configuration" \
        xcodebuild \
        -skipMacroValidation \
        -project LookInside.xcodeproj \
        -scheme "$scheme" \
        -configuration "$configuration" \
        -derivedDataPath /tmp/LookInsideDerivedData \
        CODE_SIGNING_ALLOWED=NO \
        build
}

run_command "sync derived source" bash Scripts/sync-derived-source.sh
run_swift_build "swift build" build
run_swift_build "swift build product=lookinside" build -c debug --product lookinside
run_xcode_build "LookInside" "Debug"

echo "[*] all tests passed"
