#!/bin/zsh
set -euo pipefail

# Builds the lookinside-mcp stdio server out of the sibling LookInside-MCP
# repo (when present) and embeds the binary into the LookInside.app bundle
# currently being built.
#
# Layout written:
#   $BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/Resources/lookinside-mcp
#
# Resources/ rather than MacOS/, because the host never launches this binary.
# MCP clients (Claude Desktop, Claude Code, Codex CLI, …) spawn it themselves
# and speak Model Context Protocol to it over stdio; the host only ever sees
# it as one more connection on its Unix socket. Shipping it inside the bundle
# is a distribution convenience -- it inherits the host's notarization and
# rides the same Sparkle channel, so the binary can never drift out of step
# with the MCPBridge protocol version the host speaks.
#
# GPL boundary: lookinside-mcp is proprietary and stays a separate process. It
# is never linked into the GPL host -- process isolation is the license
# boundary, and placing an independent executable in the bundle is
# aggregation, not linking. See docs/monorepo/mcp-design.md §0.2-0.3.
#
# Signing is deliberately not done here. The release flow's `sign_nested_code`
# walks every file under Contents/, detects Mach-O binaries and signs each one
# before sealing the outer bundle, so this binary is picked up automatically.
#
# Public/contributor builds without the sibling repo are tolerated: the script
# warns and exits 0, exactly like prepare-injector-daemon.sh. Those builds
# simply ship without the MCP server; nothing else about the app changes.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MONOREPO_DIR="$(cd "$PROJECT_DIR/.." && pwd)"
MCP_REPO="$MONOREPO_DIR/LookInside-MCP"

if [ ! -d "$MCP_REPO" ]; then
    if [ "${CONFIGURATION:-}" = "Release" ]; then
        echo "error: LookInside-MCP repo not found at $MCP_REPO" >&2
        echo "       Release builds must embed the MCP server binary." >&2
        exit 1
    fi
    echo "warning: LookInside-MCP repo not found at $MCP_REPO" >&2
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
    Debug)
        swift_configuration="debug"
        ;;
    Release)
        swift_configuration="release"
        ;;
    *)
        echo "warning: unknown CONFIGURATION=$CONFIGURATION, skipping MCP CLI embed" >&2
        exit 0
        ;;
esac

# A scratch path of our own, never the package's default .build. A developer
# very likely has `swift build` running in this same package from a terminal,
# and SwiftPM takes an exclusive lock on its scratch directory -- sharing one
# would make the two builds block each other.
SCRATCH_PATH="$MCP_REPO/build/host-derived"
LOG="$SCRATCH_PATH/swift-build-$swift_configuration.log"

mkdir -p "$SCRATCH_PATH"

set +e
swift build \
    --package-path "$MCP_REPO" \
    --scratch-path "$SCRATCH_PATH" \
    --configuration "$swift_configuration" \
    --product lookinside-mcp >"$LOG" 2>&1
build_status=$?
set -e

if [ "$build_status" -ne 0 ]; then
    echo "lookinside-mcp $swift_configuration build failed. Log: $LOG" >&2
    tail -80 "$LOG" >&2 || true
    exit "$build_status"
fi

BIN_PATH="$(swift build \
    --package-path "$MCP_REPO" \
    --scratch-path "$SCRATCH_PATH" \
    --configuration "$swift_configuration" \
    --show-bin-path 2>/dev/null)"

built_binary="$BIN_PATH/lookinside-mcp"
if [ ! -x "$built_binary" ]; then
    echo "error: lookinside-mcp binary not found at $built_binary" >&2
    exit 1
fi

APP_CONTENTS_DIR="$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH"
DEST_DIR="$APP_CONTENTS_DIR/Resources"
mkdir -p "$DEST_DIR"

cp -f "$built_binary" "$DEST_DIR/lookinside-mcp"
chmod +x "$DEST_DIR/lookinside-mcp"

echo "Embedded lookinside-mcp ($swift_configuration) into $DEST_DIR"
