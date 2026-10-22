#!/bin/bash
#
# End-to-end reconnect / background check of the Host against a live app.
#
# Builds a DEBUG Host and LookInside-Example against the local
# LookInside-Server checkout, opens the example app's live document in the
# Host (LOOKINSIDE_DEBUG_E2E_KEEP_OPEN=1) and then ends, pauses and
# backgrounds the app while Scripts/e2e-reconnect-driver.py asserts what the
# Host does and how fast:
#
#   terminate   the app is terminated: targets.disconnected and the
#               connection-lost banner; relaunched: banner cleared and
#               hierarchy.reloaded{initiator: host}, new pid
#   background  another app comes to the front: the background banner (or
#               connection lost, when the app is suspended); back to the
#               front: banner cleared and an automatic refresh
#               (simulator only)
#   stop        SIGSTOP, silence, an MCP hierarchy.refresh: "closing a silent
#               channel" and connection lost; SIGCONT: reconnect + refresh
#   pending     an MCP refresh in flight when the app dies fails at once,
#               not at its timeout; the refresh after the reconnect is not
#               refused as already running
#
# Usage:
#   Scripts/e2e-reconnect.sh [--mode simulator|appkit] [--skip-build]
#                            [--scenarios terminate,background,stop,pending]
#                            [--udid <booted simulator>] [--keep-simulator]
#                            [--clean]
#
# --mode simulator (default) creates and boots its own simulator
#   (lookinside-e2e-<suffix>), which teardown shuts down and deletes; --udid
#   uses an existing one instead and leaves it alone.
# --mode appkit runs LookInsideExampleAppKit on this Mac instead: no
#   simulator, and the background scenario is skipped (an AppKit Server does
#   not report its app state).
# --skip-build reuses the products in the derived data directories.
# --clean deletes both derived data directories at the end.
#
# Environment (defaults in parentheses):
#   E2E_HOST_DERIVED_DATA     (/private/tmp/lookinside-e2e-host-dd)
#   E2E_EXAMPLE_DERIVED_DATA  (/private/tmp/lookinside-e2e-example-dd); also
#                             holds the generated copy of LookInside-Example,
#                             so the checkout stays untouched
#   E2E_WORK_DIR              ($E2E_HOST_DERIVED_DATA/e2e-run): logs, socket
#   E2E_SERVER_PATH           (../LookInside-Server next to this repository)
#   E2E_EXAMPLE_PATH          (../LookInside-Example next to this repository)
#   E2E_SIM_DEVICE_TYPE       (iPhone 18 Pro)
#   E2E_SIM_RUNTIME           (the newest available iOS runtime)
#   TUIST                     (tuist on PATH, else mise's install)
#   E2E_*_TIMEOUT, E2E_STOP_SILENCE, E2E_SETTLE: limits of the checks, see
#                             the TIMEOUTS table in e2e-reconnect-driver.py
#
# Another LookInside Host running on this Mac sees the example app too, and a
# simulator app's Server takes one Host at a time; quit it (or accept that it
# may take the session) before running this.
#
# Exit status: 0 when every check passed, 1 when one failed, 2 on a setup
# error.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

MODE=simulator
SKIP_BUILD=0
CLEAN=0
KEEP_SIMULATOR=0
SCENARIOS=""
UDID=""
CREATED_UDID=""

while [ "$#" -gt 0 ]; do
	case "$1" in
	--mode)
		MODE="$2"
		shift
		;;
	--skip-build) SKIP_BUILD=1 ;;
	--clean) CLEAN=1 ;;
	--keep-simulator) KEEP_SIMULATOR=1 ;;
	--scenarios)
		SCENARIOS="$2"
		shift
		;;
	--udid)
		UDID="$2"
		shift
		;;
	-h | --help)
		sed -n '2,57p' "$0"
		exit 0
		;;
	*)
		echo "Unknown option: $1" >&2
		exit 2
		;;
	esac
	shift
done

case "$MODE" in
simulator) SCENARIOS="${SCENARIOS:-terminate,background,stop,pending}" ;;
appkit) SCENARIOS="${SCENARIOS:-terminate,stop,pending}" ;;
*)
	echo "--mode must be simulator or appkit" >&2
	exit 2
	;;
esac

HOST_DD="${E2E_HOST_DERIVED_DATA:-/private/tmp/lookinside-e2e-host-dd}"
EXAMPLE_DD="${E2E_EXAMPLE_DERIVED_DATA:-/private/tmp/lookinside-e2e-example-dd}"
WORK_DIR="${E2E_WORK_DIR:-$HOST_DD/e2e-run}"
SERVER_PATH="${E2E_SERVER_PATH:-$REPO_DIR/../LookInside-Server}"
EXAMPLE_PATH="${E2E_EXAMPLE_PATH:-$REPO_DIR/../LookInside-Example}"
SIM_DEVICE_TYPE="${E2E_SIM_DEVICE_TYPE:-iPhone 18 Pro}"
EXAMPLE_COPY="$EXAMPLE_DD/src"

HOST_APP="$HOST_DD/Build/Products/Debug/LookInside.app"
HOST_PID=""
LOG_STREAM_PID=""

say() {
	printf '[e2e-reconnect] %s\n' "$*"
}

die() {
	say "ERROR: $*" >&2
	exit 2
}

teardown() {
	local status=$?
	trap - EXIT INT TERM
	say "teardown"
	if [ -n "$LOG_STREAM_PID" ]; then
		kill "$LOG_STREAM_PID" 2>/dev/null
	fi
	if [ -n "$HOST_PID" ]; then
		kill "$HOST_PID" 2>/dev/null
		for _ in 1 2 3 4 5 6 7 8 9 10; do
			kill -0 "$HOST_PID" 2>/dev/null || break
			sleep 0.5
		done
		kill -9 "$HOST_PID" 2>/dev/null
	fi
	if [ -n "$CREATED_UDID" ] && [ "$KEEP_SIMULATOR" -eq 0 ]; then
		say "deleting simulator $CREATED_UDID"
		xcrun simctl shutdown "$CREATED_UDID" >/dev/null 2>&1
		xcrun simctl delete "$CREATED_UDID" >/dev/null 2>&1
	elif [ -n "$UDID" ] && [ "$MODE" = simulator ]; then
		xcrun simctl terminate "$UDID" app.lookinside.example >/dev/null 2>&1
	fi
	if [ "$MODE" = appkit ] && [ -n "${EXAMPLE_APP:-}" ]; then
		pkill -f "$EXAMPLE_APP/Contents/MacOS/LookInsideExampleAppKit" 2>/dev/null
	fi
	rm -f "$WORK_DIR/mcp.sock"
	if [ "$CLEAN" -eq 1 ]; then
		say "deleting $HOST_DD and $EXAMPLE_DD"
		rm -rf "$HOST_DD" "$EXAMPLE_DD"
	else
		say "logs kept in $WORK_DIR"
	fi
	exit "$status"
}
trap teardown EXIT
trap 'exit 2' INT TERM

find_tuist() {
	if [ -n "${TUIST:-}" ]; then
		echo "$TUIST"
	elif command -v tuist >/dev/null 2>&1; then
		command -v tuist
	else
		ls -d "$HOME"/.local/share/mise/installs/tuist/*/tuist 2>/dev/null | sort -V | tail -1
	fi
}

newest_ios_runtime() {
	xcrun simctl list runtimes available -j | python3 -I -c '
import json, sys
runtimes = [r for r in json.load(sys.stdin)["runtimes"] if r.get("platform") == "iOS" and r.get("isAvailable")]
runtimes.sort(key=lambda r: [int(p) for p in r["version"].split(".")])
print(runtimes[-1]["identifier"] if runtimes else "")
'
}

# MARK: - Build

build_host() {
	say "building the Host (Debug) into $HOST_DD"
	xcodebuild \
		-workspace "$REPO_DIR/LookInside.xcworkspace" \
		-scheme LookInside \
		-configuration Debug \
		-destination 'platform=macOS' \
		-derivedDataPath "$HOST_DD" \
		-skipMacroValidation \
		-skipPackagePluginValidation \
		CODE_SIGNING_ALLOWED=NO \
		build >"$WORK_DIR/host-build.log" 2>&1 || die "Host build failed, see $WORK_DIR/host-build.log"
}

# Generates the example's project into a copy: generating in the checkout
# would rewrite its tracked LookInsideExample.xcodeproj.
generate_example() {
	local tuist
	tuist="$(find_tuist)"
	[ -x "$tuist" ] || die "tuist not found; set TUIST"
	[ -d "$SERVER_PATH" ] || die "LookInside-Server not found at $SERVER_PATH"
	[ -d "$EXAMPLE_PATH" ] || die "LookInside-Example not found at $EXAMPLE_PATH"
	say "generating LookInside-Example against $(cd "$SERVER_PATH" && pwd) in $EXAMPLE_COPY"
	mkdir -p "$EXAMPLE_COPY"
	rsync -a --delete --exclude .git --exclude LookInsideExample.xcodeproj --exclude Derived "$EXAMPLE_PATH"/ "$EXAMPLE_COPY"/
	(cd "$EXAMPLE_COPY" && TUIST_LOOKINSIDE_SERVER_PATH="$(cd "$SERVER_PATH" && pwd)" "$tuist" generate --no-open) \
		>"$WORK_DIR/example-generate.log" 2>&1 || die "tuist generate failed, see $WORK_DIR/example-generate.log"
}

build_example() {
	local scheme="$1" destination="$2"
	say "building $scheme for $destination into $EXAMPLE_DD/dd"
	xcodebuild \
		-project "$EXAMPLE_COPY/LookInsideExample.xcodeproj" \
		-scheme "$scheme" \
		-configuration Debug \
		-destination "$destination" \
		-derivedDataPath "$EXAMPLE_DD/dd" \
		-skipMacroValidation \
		-skipPackagePluginValidation \
		CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
		build >"$WORK_DIR/example-build-$scheme.log" 2>&1 || die "$scheme build failed, see $WORK_DIR/example-build-$scheme.log"
}

# MARK: - Simulator

prepare_simulator() {
	if [ -z "$UDID" ]; then
		local runtime="${E2E_SIM_RUNTIME:-$(newest_ios_runtime)}"
		[ -n "$runtime" ] || die "no iOS simulator runtime available"
		local name
		name="lookinside-e2e-$(date +%H%M%S)-$$"
		CREATED_UDID="$(xcrun simctl create "$name" "$SIM_DEVICE_TYPE" "$runtime")" || die "simctl create failed"
		UDID="$CREATED_UDID"
		say "created simulator $name ($UDID, $runtime)"
	fi
	xcrun simctl boot "$UDID" >/dev/null 2>&1
	xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || die "simulator $UDID did not boot"
}

# MARK: - Main

mkdir -p "$WORK_DIR"
rm -f "$WORK_DIR"/*.jsonl "$WORK_DIR"/*.ndjson "$WORK_DIR"/host-output.log "$WORK_DIR"/appkit-output.log "$WORK_DIR/mcp.sock"

if [ "$SKIP_BUILD" -eq 0 ]; then
	[ -d "$SERVER_PATH" ] || die "LookInside-Server not found at $SERVER_PATH; set E2E_SERVER_PATH"
	[ -d "$EXAMPLE_PATH" ] || die "LookInside-Example not found at $EXAMPLE_PATH; set E2E_EXAMPLE_PATH"
fi
if [ "$MODE" = simulator ]; then
	prepare_simulator
fi

if [ "$SKIP_BUILD" -eq 0 ]; then
	build_host
	generate_example
	if [ "$MODE" = simulator ]; then
		build_example LookInsideExample "platform=iOS Simulator,id=$UDID"
	else
		build_example LookInsideExampleAppKit "platform=macOS"
	fi
fi
[ -x "$HOST_APP/Contents/MacOS/LookInside" ] || die "no Host build at $HOST_APP"

if [ "$MODE" = simulator ]; then
	BUNDLE_ID=app.lookinside.example
	EXAMPLE_APP="$(find "$EXAMPLE_DD/dd/Build/Products" -maxdepth 2 -name LookInsideExample.app -path '*iphonesimulator*' | head -1)"
	[ -n "$EXAMPLE_APP" ] || die "no simulator build of LookInsideExample in $EXAMPLE_DD/dd"
	say "installing $EXAMPLE_APP"
	xcrun simctl install "$UDID" "$EXAMPLE_APP" || die "simctl install failed"
	xcrun simctl launch "$UDID" "$BUNDLE_ID" >/dev/null || die "simctl launch failed"
else
	BUNDLE_ID=app.lookinside.example.appkit
	EXAMPLE_APP="$(find "$EXAMPLE_DD/dd/Build/Products/Debug" -maxdepth 1 -name LookInsideExampleAppKit.app | head -1)"
	[ -n "$EXAMPLE_APP" ] || die "no build of LookInsideExampleAppKit in $EXAMPLE_DD/dd"
fi

# The Host runs with its own activation state, an empty test keychain (no
# license key, so no keychain prompt) and its own MCP socket, so it neither
# reads nor changes an installed Host's.
mkdir -p "$WORK_DIR/activation-state" "$WORK_DIR/dump"
say "launching the Host"
env \
	LOOKINSIDE_DEBUG_E2E_DUMP_DIR="$WORK_DIR/dump" \
	LOOKINSIDE_DEBUG_E2E_BUNDLE_ID="$BUNDLE_ID" \
	LOOKINSIDE_DEBUG_E2E_KEEP_OPEN=1 \
	LOOKINSIDE_DEBUG_E2E_SESSION_LOG="$WORK_DIR/session.jsonl" \
	LOOKINSIDE_DEBUG_E2E_TIMEOUT="${E2E_OPEN_TIMEOUT:-180}" \
	LOOKINSIDE_MCP_SOCKET_PATH="$WORK_DIR/mcp.sock" \
	LOOKINSIDE_ACTIVATION_STATE_DIR="$WORK_DIR/activation-state" \
	LOOKINSIDE_ACTIVATION_KEYCHAIN_PATH="$WORK_DIR/activation-state/none.keychain" \
	"$HOST_APP/Contents/MacOS/LookInside" >"$WORK_DIR/host-output.log" 2>&1 &
HOST_PID=$!
disown "$HOST_PID"

log stream --style ndjson --level info \
	--predicate "subsystem == \"com.lookinside.app\" AND processIdentifier == $HOST_PID" \
	>"$WORK_DIR/host-os-log.ndjson" 2>/dev/null &
LOG_STREAM_PID=$!
disown "$LOG_STREAM_PID"

DRIVER_ARGS=(
	--mode "$MODE"
	--bundle-id "$BUNDLE_ID"
	--socket "$WORK_DIR/mcp.sock"
	--session-log "$WORK_DIR/session.jsonl"
	--os-log "$WORK_DIR/host-os-log.ndjson"
	--host-output "$WORK_DIR/host-output.log"
	--host-pid "$HOST_PID"
	--scenarios "$SCENARIOS"
)
if [ "$MODE" = simulator ]; then
	DRIVER_ARGS+=(--udid "$UDID")
else
	DRIVER_ARGS+=(--app-executable "$EXAMPLE_APP/Contents/MacOS/LookInsideExampleAppKit" --app-output "$WORK_DIR/appkit-output.log")
fi

python3 -I "$SCRIPT_DIR/e2e-reconnect-driver.py" "${DRIVER_ARGS[@]}"
DRIVER_STATUS=$?
[ "$DRIVER_STATUS" -le 1 ] || DRIVER_STATUS=2
exit "$DRIVER_STATUS"
