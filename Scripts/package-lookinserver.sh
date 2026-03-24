#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT_DIR="$PWD"
WORKSPACE_PATH="LookInside.xcworkspace"
SCHEME="${SCHEME:-LookinServerDynamic}"
CONFIGURATION="${CONFIGURATION:-Release}"
OUTPUT_ROOT="${OUTPUT_ROOT:-$PROJECT_DIR/build/lookinserver}"
DERIVED_ROOT="${DERIVED_ROOT:-/tmp/LookinServerDynamicDD}"
SKIP_BUILD="${SKIP_BUILD:-0}"

FRAMEWORK_NAME="LookinServer"
PRODUCT_NAME="LookinServerDynamic"
MIN_IOS_VERSION="${MIN_IOS_VERSION:-12.0}"
USE_XCBEAUTIFY="${USE_XCBEAUTIFY:-1}"

copy_public_headers() {
    local headers_dir="$1"

    mkdir -p "$headers_dir"

    while IFS= read -r -d '' header; do
        cp "$header" "$headers_dir/$(basename "$header")"
    done < <(
        find \
            "$PROJECT_DIR/Sources/LookinServer/Shared" \
            "$PROJECT_DIR/Sources/LookinServer/Server" \
            "$PROJECT_DIR/Sources/LookinServerBase" \
            -name '*.h' -print0
    )
}

write_modulemap() {
    local framework_dir="$1"

    mkdir -p "$framework_dir/Modules"
    cat >"$framework_dir/Modules/module.modulemap" <<'EOF'
framework module LookinServer {
  umbrella "../Headers"
  export *
  module * { export * }
}
EOF
}

run_xcodebuild() {
    if [ "$USE_XCBEAUTIFY" = "1" ] && command -v xcbeautify >/dev/null 2>&1; then
        xcodebuild "$@" 2>&1 | xcbeautify
    else
        xcodebuild "$@"
    fi
}

stage_framework_bundle() {
    local sdk="$1"
    local derived_dir="$2"
    local release_dir="$derived_dir/Build/Products/$CONFIGURATION-$sdk"
    local source_framework="$release_dir/PackageFrameworks/$PRODUCT_NAME.framework"
    local staged_root="$OUTPUT_ROOT/$sdk"
    local staged_framework="$staged_root/$FRAMEWORK_NAME.framework"
    local staged_binary="$staged_framework/$FRAMEWORK_NAME"
    local staged_dylib="$staged_root/$FRAMEWORK_NAME.dylib"
    local swift_header

    rm -rf "$staged_framework"
    mkdir -p "$staged_root"
    cp -R "$source_framework" "$staged_framework"

    mv "$staged_framework/$PRODUCT_NAME" "$staged_binary"

    /usr/libexec/PlistBuddy \
        -c "Set :CFBundleExecutable $FRAMEWORK_NAME" \
        -c "Set :CFBundleName $FRAMEWORK_NAME" \
        -c "Set :CFBundleIdentifier lookinside.$FRAMEWORK_NAME" \
        "$staged_framework/Info.plist"

    copy_public_headers "$staged_framework/Headers"

    swift_header="$derived_dir/Build/Intermediates.noindex/LookInside.build/$CONFIGURATION-$sdk/LookinServerSwift.build/Objects-normal"
    if [ "$sdk" = "iphoneos" ]; then
        swift_header="$swift_header/arm64/LookinServerSwift-Swift.h"
    else
        swift_header="$swift_header/arm64/LookinServerSwift-Swift.h"
    fi
    cp "$swift_header" "$staged_framework/Headers/$FRAMEWORK_NAME-Swift.h"

    write_modulemap "$staged_framework"

    install_name_tool -id "@rpath/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" "$staged_binary"

    cp "$staged_binary" "$staged_dylib"
    install_name_tool -id "@rpath/$FRAMEWORK_NAME.dylib" "$staged_dylib"
}

build_sdk() {
    local sdk="$1"
    local derived_dir="$DERIVED_ROOT/$sdk"

    run_xcodebuild \
        -workspace "$WORKSPACE_PATH" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -sdk "$sdk" \
        -derivedDataPath "$derived_dir" \
        CODE_SIGNING_ALLOWED=NO \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        IPHONEOS_DEPLOYMENT_TARGET="$MIN_IOS_VERSION" \
        build
}

mkdir -p "$OUTPUT_ROOT"

if [ "$SKIP_BUILD" != "1" ]; then
    build_sdk iphoneos
    build_sdk iphonesimulator
fi

stage_framework_bundle iphoneos "$DERIVED_ROOT/iphoneos"
stage_framework_bundle iphonesimulator "$DERIVED_ROOT/iphonesimulator"

rm -rf "$OUTPUT_ROOT/$FRAMEWORK_NAME.xcframework"
run_xcodebuild -create-xcframework \
    -framework "$OUTPUT_ROOT/iphoneos/$FRAMEWORK_NAME.framework" \
    -framework "$OUTPUT_ROOT/iphonesimulator/$FRAMEWORK_NAME.framework" \
    -output "$OUTPUT_ROOT/$FRAMEWORK_NAME.xcframework"

echo "Packaged artifacts under $OUTPUT_ROOT"
