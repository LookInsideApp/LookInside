#!/bin/zsh
set -euo pipefail

# Builds the lookinside-injector daemon out of the sibling LookInside-Injector
# repo (when present) and embeds the binary + launchd plist into the
# LookInside.app bundle currently being built.
#
# Layout written:
#   $BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/MacOS/lookinside-injector
#   $BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/Library/LaunchDaemons/app.lookinside.LookInsideInjector.plist
#
# Public/contributor builds without the sibling repo are tolerated: the script
# logs a warning and exits 0. In that case the host app will be missing the
# attach-to-process feature at runtime but otherwise builds and runs fine.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MONOREPO_DIR="$(cd "$PROJECT_DIR/.." && pwd)"
INJECTOR_REPO="$MONOREPO_DIR/LookInside-Injector"
WORKSPACE="$INJECTOR_REPO/LookInsideInjector.xcworkspace"

if [ ! -d "$INJECTOR_REPO" ]; then
    if [ "${CONFIGURATION:-}" = "Release" ]; then
        echo "error: LookInside-Injector repo not found at $INJECTOR_REPO" >&2
        echo "       Release builds must embed the injector daemon and launchd plist." >&2
        exit 1
    fi
    echo "warning: LookInside-Injector repo not found at $INJECTOR_REPO" >&2
    echo "         (private/source-available; public contributors can ignore)" >&2
    exit 0
fi

if [ -z "${CONFIGURATION:-}" ]; then
    echo "error: CONFIGURATION is unset (not running under Xcode?)" >&2
    exit 1
fi

if [ -z "${BUILT_PRODUCTS_DIR:-}" ] || [ -z "${CONTENTS_FOLDER_PATH:-}" ]; then
    echo "error: BUILT_PRODUCTS_DIR / CONTENTS_FOLDER_PATH are unset (not running under Xcode?)" >&2
    exit 1
fi

case "$CONFIGURATION" in
    Debug|Release) ;;
    *)
        echo "warning: unknown CONFIGURATION=$CONFIGURATION, skipping injector daemon embed" >&2
        exit 0
        ;;
esac

DERIVED_DATA="$INJECTOR_REPO/build/host-derived/$CONFIGURATION"
LOG="$DERIVED_DATA/xcodebuild.log"
TOOLCHAIN_STAMP="$DERIVED_DATA/.toolchain-stamp"

# Reset the nested build's derived data whenever the Swift toolchain
# changes.
#
# This derived data path is fixed rather than Xcode-managed, so it
# survives Xcode upgrades -- and one thing inside it must not. For macro
# support, SwiftPM caches a prebuilt swift-syntax under
# SourcePackages/prebuilts/ in a directory named after the compiler that
# produced it (e.g. swiftlang-6.3.2.1.108-macosx26.5-MacroSupport). That
# cache is not invalidated on upgrade, so the next Xcode feeds its own
# compiler a swiftmodule built by the previous one and every macro
# target dies with "Unable to resolve Swift module dependency to a
# compatible module: 'SwiftDiagnostics'".
#
# Deleting just the prebuilts directory is not enough: the build
# description is cached as well, so the already-planned compile commands
# keep the now-missing -I path and the failure only changes shape
# ("unable to resolve module dependency"). Wiping the whole derived data
# is the reliable reset.
current_toolchain="$(xcrun swiftc -version 2>/dev/null | head -1)"
if [ -z "$current_toolchain" ]; then
    echo "warning: could not determine the Swift toolchain version; leaving $DERIVED_DATA as-is" >&2
elif [ ! -f "$TOOLCHAIN_STAMP" ] || [ "$(cat "$TOOLCHAIN_STAMP")" != "$current_toolchain" ]; then
    if [ -d "$DERIVED_DATA" ]; then
        echo "note: Swift toolchain changed; resetting $DERIVED_DATA" >&2
    fi
    rm -rf "$DERIVED_DATA"
fi

mkdir -p "$DERIVED_DATA"

# Refuse to build a project that no longer matches its Tuist manifests.
#
# The workspace and xcodeproj are gitignored build artifacts, so testing only
# for their presence means a checkout that already has them keeps building a
# stale project after Project.swift changes -- and does so silently, since the
# only symptom is whatever the stale project happens to get wrong. Raising a
# package version requirement is the case that bites: the generated project
# still carries the old requirement, SwiftPM keeps honouring the old pin, and
# the build fails inside a dependency far away from the edit.
#
# This reports the problem rather than regenerating in place, and that is not a
# matter of taste. LookInsideInjector.xcodeproj is a member of the monorepo's
# LookInside.xcworkspace. Rewriting a workspace member mid-build makes Xcode
# reload the workspace and cancel the build in progress, which kills this script
# before it can finish -- and since nothing was recorded, the next build repeats
# it. The result is a build that cancels itself forever. Generating is only safe
# when the workspace does not exist yet, because nothing can have it open.
#
# Staleness is decided by modification time rather than a stamp file, so that
# regenerating by hand is enough to clear it -- no bookkeeping this script has
# to be alive to perform.
PROJECT_FILE="$INJECTOR_REPO/LookInsideInjector.xcodeproj/project.pbxproj"

newest_manifest_mtime=0
newest_manifest_file=""
for manifest_candidate in \
    "$INJECTOR_REPO/Project.swift" \
    "$INJECTOR_REPO/Workspace.swift" \
    "$INJECTOR_REPO/Tuist.swift" \
    "$INJECTOR_REPO/Tuist/Package.swift" \
    "$INJECTOR_REPO/mise.toml"
do
    if [ -f "$manifest_candidate" ]; then
        candidate_mtime="$(stat -f %m "$manifest_candidate")"
        if [ "$candidate_mtime" -gt "$newest_manifest_mtime" ]; then
            newest_manifest_mtime="$candidate_mtime"
            newest_manifest_file="$manifest_candidate"
        fi
    fi
done

if [ ! -d "$WORKSPACE" ] || [ ! -f "$PROJECT_FILE" ]; then
    if command -v mise >/dev/null 2>&1; then
        (cd "$INJECTOR_REPO" && mise trust -y mise.toml >/dev/null && mise exec -- tuist generate --no-open)
    elif command -v tuist >/dev/null 2>&1; then
        (cd "$INJECTOR_REPO" && tuist generate --no-open)
    else
        echo "error: neither 'mise' nor 'tuist' is on PATH; cannot generate LookInside-Injector workspace" >&2
        exit 1
    fi
elif [ "$newest_manifest_mtime" -gt "$(stat -f %m "$PROJECT_FILE")" ]; then
    echo "error: $newest_manifest_file is newer than the generated LookInsideInjector.xcodeproj," >&2
    echo "       so this build would use a stale project. Regenerate it, then build again:" >&2
    echo "           (cd $INJECTOR_REPO && mise exec -- tuist generate --no-open)" >&2
    echo "       Not done automatically: that project belongs to LookInside.xcworkspace, and" >&2
    echo "       rewriting it mid-build makes Xcode cancel the build. See docs/monorepo/workflow.md." >&2
    exit 1
fi

set +e
xcodebuild \
    -workspace "$WORKSPACE" \
    -scheme lookinside-injector \
    -configuration "$CONFIGURATION" \
    -destination 'platform=macOS' \
    -derivedDataPath "$DERIVED_DATA" \
    -skipMacroValidation \
    -skipPackagePluginValidation \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY= \
    ONLY_ACTIVE_ARCH=YES \
    build >"$LOG" 2>&1
build_status=$?
set -e

if [ "$build_status" -ne 0 ]; then
    echo "lookinside-injector $CONFIGURATION build failed. Log: $LOG" >&2
    tail -80 "$LOG" >&2 || true
    exit "$build_status"
fi

# Record the toolchain only after a successful build, so a build that
# failed for unrelated reasons does not leave a stamp claiming this
# derived data is good for the current compiler.
if [ -n "$current_toolchain" ]; then
    printf '%s' "$current_toolchain" > "$TOOLCHAIN_STAMP"
fi

built_binary="$(find "$DERIVED_DATA/Build/Products" -type f -name 'lookinside-injector' -perm +111 | head -1)"
if [ -z "$built_binary" ]; then
    echo "lookinside-injector binary not found under $DERIVED_DATA/Build/Products" >&2
    exit 1
fi

LAUNCHD_PLIST="$INJECTOR_REPO/Resources/lookinside-injector-Launchd.plist"
if [ ! -f "$LAUNCHD_PLIST" ]; then
    echo "LaunchDaemon plist missing at $LAUNCHD_PLIST" >&2
    exit 1
fi

APP_CONTENTS_DIR="$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH"
DEST_DAEMON_DIR="$APP_CONTENTS_DIR/MacOS"
DEST_LAUNCHD_DIR="$APP_CONTENTS_DIR/Library/LaunchDaemons"
mkdir -p "$DEST_DAEMON_DIR" "$DEST_LAUNCHD_DIR"

cp -f "$built_binary" "$DEST_DAEMON_DIR/lookinside-injector"
chmod +x "$DEST_DAEMON_DIR/lookinside-injector"
cp -f "$LAUNCHD_PLIST" "$DEST_LAUNCHD_DIR/app.lookinside.LookInsideInjector.plist"

echo "Embedded lookinside-injector ($CONFIGURATION) into $APP_CONTENTS_DIR"
