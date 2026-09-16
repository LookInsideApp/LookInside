#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MONOREPO_DIR="$(cd "$PROJECT_DIR/.." && pwd)"
AUTH_REPO="$MONOREPO_DIR/LookInside-Auth"
WORKSPACE="$AUTH_REPO/LookInsideAuthenticator.xcworkspace"

DEBUG_ROOT="/tmp/lookinside-auth-server-debug"
DERIVED_DATA="$DEBUG_ROOT/derived-data"
LOG="$DEBUG_ROOT/xcodebuild.log"
DEST_DIR="$DEBUG_ROOT/current"
DEST_APP="$DEST_DIR/lookinside-auth-server.app"

if [ ! -d "$AUTH_REPO" ]; then
	echo "warning: LookInside-Auth repo not found at $AUTH_REPO" >&2
	echo "         (private/source-available; public contributors can ignore)" >&2
	exit 1
fi

mkdir -p "$DEBUG_ROOT" "$DEST_DIR"
rm -rf "$DERIVED_DATA" "$DEST_APP"

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
# matter of taste. LookInsideAuthenticator.xcodeproj is a member of the
# monorepo's LookInside.xcworkspace. Rewriting a workspace member mid-build
# makes Xcode reload the workspace and cancel the build in progress, which kills
# this script before it can finish -- and since nothing was recorded, the next
# build repeats it. The result is a build that cancels itself forever.
# Generating is only safe when the workspace does not exist yet, because nothing
# can have it open.
#
# Staleness is decided by modification time rather than a stamp file, so that
# regenerating by hand is enough to clear it -- no bookkeeping this script has
# to be alive to perform.
PROJECT_FILE="$AUTH_REPO/LookInsideAuthenticator.xcodeproj/project.pbxproj"

newest_manifest_mtime=0
newest_manifest_file=""
for manifest_candidate in \
	"$AUTH_REPO/Project.swift" \
	"$AUTH_REPO/Workspace.swift" \
	"$AUTH_REPO/Tuist.swift" \
	"$AUTH_REPO/Tuist/Package.swift" \
	"$AUTH_REPO/mise.toml"
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
	# Prefer mise (matches internal toolchain pinning); fall back to bare tuist.
	if command -v mise >/dev/null 2>&1; then
		(cd "$AUTH_REPO" && mise exec -- tuist generate --no-open)
	elif command -v tuist >/dev/null 2>&1; then
		(cd "$AUTH_REPO" && tuist generate --no-open)
	else
		echo "warning: neither 'mise' nor 'tuist' is on PATH; cannot generate workspace" >&2
		exit 1
	fi
elif [ "$newest_manifest_mtime" -gt "$(stat -f %m "$PROJECT_FILE")" ]; then
	echo "error: $newest_manifest_file is newer than the generated LookInsideAuthenticator.xcodeproj," >&2
	echo "       so this build would use a stale project. Regenerate it, then build again:" >&2
	echo "           (cd $AUTH_REPO && mise exec -- tuist generate --no-open)" >&2
	echo "       Not done automatically: that project belongs to LookInside.xcworkspace, and" >&2
	echo "       rewriting it mid-build makes Xcode cancel the build. See docs/monorepo/workflow.md." >&2
	exit 1
fi

set +e
xcodebuild \
	-workspace "$WORKSPACE" \
	-scheme LookInsideAuthServer \
	-configuration Debug \
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
	echo "LookInsideAuthServer Debug build failed. Log: $LOG" >&2
	tail -80 "$LOG" >&2 || true
	exit "$build_status"
fi

built_app="$(find "$DERIVED_DATA/Build/Products" -type d -name 'lookinside-auth-server.app' | head -1)"
if [ -z "$built_app" ]; then
	echo "Built lookinside-auth-server.app was not found under $DERIVED_DATA/Build/Products" >&2
	exit 1
fi

cp -R "$built_app" "$DEST_APP"
chmod +x "$DEST_APP/Contents/MacOS/lookinside-auth-server"
echo "Prepared debug auth server at $DEST_APP"
