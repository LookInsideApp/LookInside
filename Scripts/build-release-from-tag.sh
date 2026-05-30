#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT_ROOT="$PWD"
PROJECT_FILE="$PROJECT_ROOT/LookInside.xcodeproj"
SCHEME="LookInside"
CONFIGURATION="Release"
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-}"
RELEASE_BUILD_NUMBER="${RELEASE_BUILD_NUMBER:-0}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${RUNNER_TEMP:-/tmp}/LookInsideReleaseDerivedData}"
ARCHIVE_ROOT=""
RAW_TAG=""
RELEASE_VERSION=""
STAGE="all"
SKIP_TESTS=false
SKIP_NOTARIZE=false
PRESERVE_KEYCHAIN_STATE="${PRESERVE_KEYCHAIN_STATE:-}"
ORIGINAL_DEFAULT_KEYCHAIN=""
ORIGINAL_KEYCHAINS=()

usage() {
	cat <<'EOF'
Usage: bash Scripts/build-release-from-tag.sh --tag <tag> [options]

Options:
  --tag <tag>               Git tag or ref name, for example 2.2.0 or v2.2.0.
  --archive-root <path>     Output directory. Default: build/releases/<tag>
  --stage <name>            all, build-cli, package-cli, sign-cli, notarize-cli,
                            archive-app, sign-app, notarize-app, finalize
  --keychain-profile <name> Override the auto-detected notarytool keychain profile.
  --skip-tests              Skip preflight validation.
  --skip-notarize           Skip notarization.
  --help, -h                Show this help.
EOF
}

log() {
	echo "==> $*"
}

run_and_log_status() {
	local label="$1"
	shift

	"$@"
	local status=$?
	echo "==> ${label} exit status: ${status}"
	return "$status"
}

log_kv() {
	echo "    $1: $2"
}

fail() {
	echo "Error: $*" >&2
	exit 1
}

require_command() {
	command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

capture_original_keychain_state() {
	local line

	ORIGINAL_DEFAULT_KEYCHAIN="$(security default-keychain -d user 2>/dev/null | sed 's/^ *"//; s/"$//')"
	while IFS= read -r line; do
		line="$(sed 's/^ *"//; s/"$//' <<<"$line")"
		[[ -n "$line" ]] && ORIGINAL_KEYCHAINS+=("$line")
	done < <(security list-keychains -d user 2>/dev/null || true)
}

restore_original_keychain_state() {
	[[ "$PRESERVE_KEYCHAIN_STATE" == "1" ]] && return

	if [[ -n "$ORIGINAL_DEFAULT_KEYCHAIN" ]]; then
		security default-keychain -d user -s "$ORIGINAL_DEFAULT_KEYCHAIN" >/dev/null 2>&1 || true
	fi

	if [[ "${#ORIGINAL_KEYCHAINS[@]}" -gt 0 ]]; then
		security list-keychains -d user -s "${ORIGINAL_KEYCHAINS[@]}" >/dev/null 2>&1 || true
	fi
}

load_keychain_secret_from_zshrc_if_needed() {
	if [[ -n "${KEYCHAIN_SECRET:-}" ]]; then
		return
	fi

	command -v zsh >/dev/null 2>&1 || return

	local tmp_file
	tmp_file="$(mktemp "${TMPDIR:-/tmp}/lookinside-keychain-secret.XXXXXX")"
	chmod 600 "$tmp_file"

	zsh -lc '
        source ~/.zshrc >/dev/null 2>&1 || true
        umask 077
        [[ -n "${KEYCHAIN_SECRET:-}" ]] && printf "%s" "$KEYCHAIN_SECRET" > "$1"
    ' zsh "$tmp_file"

	if [[ -s "$tmp_file" ]]; then
		KEYCHAIN_SECRET="$(<"$tmp_file")"
	fi

	rm -f "$tmp_file"
}

format_output() {
	if command -v xcbeautify >/dev/null 2>&1; then
		xcbeautify --disable-logging
	else
		cat
	fi
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--tag)
			RAW_TAG="${2:-}"
			shift 2
			;;
		--archive-root)
			ARCHIVE_ROOT="${2:-}"
			shift 2
			;;
		--stage)
			STAGE="${2:-}"
			shift 2
			;;
		--keychain-profile)
			KEYCHAIN_PROFILE="${2:-}"
			shift 2
			;;
		--skip-tests)
			SKIP_TESTS=true
			shift
			;;
		--skip-notarize)
			SKIP_NOTARIZE=true
			shift
			;;
		--help | -h)
			usage
			exit 0
			;;
		*)
			fail "Unknown option: $1"
			;;
		esac
	done
}

normalize_tag_version() {
	local raw="$1"
	raw="${raw#refs/tags/}"
	raw="${raw#v}"
	[[ "$raw" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Invalid tag '$1'. Expected x.y.z or vX.Y.Z."
	echo "$raw"
}

build_setting() {
	local key="$1"
	xcodebuild \
		-project "$PROJECT_FILE" \
		-scheme "$SCHEME" \
		-configuration "$CONFIGURATION" \
		-showBuildSettings 2>/dev/null |
		awk -F' = ' -v search_key="$key" '$1 ~ search_key"$" { print $2; exit }'
}

write_release_xcconfig() {
	local args=(
		--version "$RELEASE_VERSION"
		--build-number "$RELEASE_BUILD_NUMBER"
	)

	[[ -n "${DEVELOPMENT_TEAM:-}" ]] && args+=(--development-team "$DEVELOPMENT_TEAM")
	[[ -n "${SIGNING_IDENTITY:-}" ]] && args+=(--signing-identity "$SIGNING_IDENTITY")
	[[ -n "${PRODUCT_BUNDLE_IDENTIFIER:-}" ]] && args+=(--bundle-id "$PRODUCT_BUNDLE_IDENTIFIER")

	bash Scripts/write-github-action-xcconfig.sh "${args[@]}"
}

run_preflight() {
	if [[ "$SKIP_TESTS" == "true" ]]; then
		log "Skipping preflight checks"
		return
	fi

	log "Running preflight checks"
	bash Scripts/test.sh
}

print_signing_context() {
	log "Signing context"
	log_kv "signing_identity" "${SIGNING_IDENTITY:-<unset>}"
	log_kv "development_team" "${DEVELOPMENT_TEAM:-<unset>}"
	log_kv "keychain_path" "${KEYCHAIN_PATH:-<unset>}"
	log_kv "keychain_profile" "${KEYCHAIN_PROFILE:-<unset>}"
	security find-identity -v -p codesigning "${KEYCHAIN_PATH:-}" 2>/dev/null || true
}

ensure_keychain_unlocked() {
	[[ -n "${KEYCHAIN_PATH:-}" ]] || fail "KEYCHAIN_PATH is not set."

	load_keychain_secret_from_zshrc_if_needed
	[[ -n "${KEYCHAIN_SECRET:-}" ]] || fail "KEYCHAIN_SECRET is required to unlock the signing keychain before signing."

	log "Setting signing keychain as default for build step"
	run_and_log_status "security default-keychain" security default-keychain -d user -s "$KEYCHAIN_PATH"

	log "Unlocking signing keychain for build step"
	run_and_log_status "security unlock-keychain" security unlock-keychain -p "$KEYCHAIN_SECRET" "$KEYCHAIN_PATH"
	run_and_log_status "security set-keychain-settings" security set-keychain-settings -t 3600 -u "$KEYCHAIN_PATH"
	run_and_log_status "security set-key-partition-list" security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_SECRET" "$KEYCHAIN_PATH"
}

ensure_signing_context() {
	if [[ -n "${SIGNING_IDENTITY:-}" && -n "${DEVELOPMENT_TEAM:-}" && -n "${KEYCHAIN_PATH:-}" && -n "${KEYCHAIN_PROFILE:-}" ]]; then
		log "Using signing context from environment"
		return
	fi

	local env_file
	env_file="$(mktemp "${TMPDIR:-/tmp}/lookinside-release-env.XXXXXX")"
	trap 'rm -f "$env_file"' RETURN

	bash Scripts/setup-ci-keychain.sh --env-file "$env_file" --keychain-profile "$KEYCHAIN_PROFILE"
	# shellcheck disable=SC1090
	source "$env_file"

	[[ -n "${SIGNING_IDENTITY:-}" ]] || fail "SIGNING_IDENTITY was not detected."
	[[ -n "${DEVELOPMENT_TEAM:-}" ]] || fail "DEVELOPMENT_TEAM was not detected."
	[[ -n "${KEYCHAIN_PATH:-}" ]] || fail "KEYCHAIN_PATH was not detected."
	[[ -n "${KEYCHAIN_PROFILE:-}" ]] || fail "KEYCHAIN_PROFILE was not detected."
}

sign_cli() {
	local cli_binary="$1"

	chmod 755 "$cli_binary"
	[[ -x "$cli_binary" ]] || fail "CLI binary is not executable: $cli_binary"

	log "Signing CLI binary"
	print_signing_context
	codesign \
		--sign "$SIGNING_IDENTITY" \
		--options runtime \
		--timestamp \
		--verbose=4 \
		--force \
		"$cli_binary"

	log "Verifying CLI signature"
	codesign --verify --verbose=2 "$cli_binary"
}

is_mach_o_file() {
	local path="$1"
	file -b "$path" 2>/dev/null | grep -q "Mach-O"
}

path_contains_symlink() {
	local path="$1"
	local current="$path"

	while [[ "$current" != "/" && "$current" != "." ]]; do
		[[ -L "$current" ]] && return 0
		current="$(dirname "$current")"
	done

	return 1
}

should_skip_nested_code_path() {
	local path="$1"

	[[ "$path" == *"/Versions/Current"* ]] && return 0
	path_contains_symlink "$path"
}

sign_code_path() {
	local path="$1"

	log "Signing nested code: ${path#$PROJECT_ROOT/}"
	codesign \
		--sign "$SIGNING_IDENTITY" \
		--options runtime \
		--timestamp \
		--verbose=4 \
		--force \
		"$path"
}

sign_nested_code() {
	local app_path="$1"
	local main_executable="$app_path/Contents/MacOS/LookInside"
	local mach_o_files=()
	local bundles=()
	local candidate

	while IFS= read -r candidate; do
		[[ "$candidate" == "$main_executable" ]] && continue
		should_skip_nested_code_path "$candidate" && continue
		if is_mach_o_file "$candidate"; then
			mach_o_files+=("$candidate")
		fi
	done < <(find "$app_path/Contents" -type f -print)

	while IFS= read -r candidate; do
		bundles+=("$candidate")
	done < <(
		find "$app_path/Contents" -type d \
			\( -name "*.app" -o -name "*.appex" -o -name "*.bundle" -o -name "*.framework" -o -name "*.xpc" \) \
			-print |
			awk '{ print length, $0 }' |
			sort -rn |
			cut -d' ' -f2-
	)

	for candidate in "${mach_o_files[@]}"; do
		sign_code_path "$candidate"
	done

	for candidate in "${bundles[@]}"; do
		should_skip_nested_code_path "$candidate" && continue
		sign_code_path "$candidate"
	done
}

package_cli() {
	local cli_binary="$1"
	local cli_zip="$2"

	rm -f "$cli_zip"
	ditto -c -k --keepParent "$cli_binary" "$cli_zip"
}

archive_app_unsigned() {
	local archive_path="$1"
	local xcodebuild_args=(
		-skipMacroValidation
		-project "$PROJECT_FILE"
		-scheme "$SCHEME"
		-configuration "$CONFIGURATION"
		-destination "generic/platform=macOS"
		-derivedDataPath "$DERIVED_DATA_PATH"
		-archivePath "$archive_path"
		CODE_SIGNING_ALLOWED=NO
	)

	if [[ -n "${SPARKLE_PUBLIC_ED_KEY:-}" ]]; then
		xcodebuild_args+=(SPARKLE_PUBLIC_ED_KEY="$SPARKLE_PUBLIC_ED_KEY")
	fi

	rm -rf "$archive_path" "$DERIVED_DATA_PATH"

	log "Syncing derived source mirror"
	bash Scripts/sync-derived-source.sh

	log "Archiving app without Xcode signing"
	xcodebuild "${xcodebuild_args[@]}" archive 2>&1 | format_output
}

sign_app_bundle() {
	local app_path="$1"
	local entitlements_path="$2"

	[[ -f "$app_path/Contents/MacOS/LookInside" ]] || fail "Main app executable not found at $app_path/Contents/MacOS/LookInside"

	chmod 755 "$app_path/Contents/MacOS/LookInside"
	[[ -x "$app_path/Contents/MacOS/LookInside" ]] || fail "Main app executable is not executable: $app_path/Contents/MacOS/LookInside"

	local injector_binary="$app_path/Contents/MacOS/lookinside-injector"
	local injector_plist="$app_path/Contents/Library/LaunchDaemons/app.lookinside.LookInsideInjector.plist"
	[[ -x "$injector_binary" ]] || fail "Injector daemon executable is not executable: $injector_binary"
	[[ -f "$injector_plist" ]] || fail "Injector daemon launchd plist is missing: $injector_plist"

	log "Signing nested app code"
	sign_nested_code "$app_path"

	log "Signing app bundle"
	print_signing_context
	codesign \
		--sign "$SIGNING_IDENTITY" \
		--entitlements "$entitlements_path" \
		--options runtime \
		--timestamp \
		--verbose=4 \
		--force \
		"$app_path"

	log "Verifying app signature"
	codesign --verify --deep --strict --verbose=2 "$app_path"
}

notarize_file() {
	local artifact="$1"
	local description="$2"

	if [[ "$SKIP_NOTARIZE" == "true" ]]; then
		log "Skipping notarization for $description"
		return
	fi

	log "Submitting $description for notarization"
	xcrun notarytool submit "$artifact" \
		--keychain-profile "$KEYCHAIN_PROFILE" \
		--wait
}

staple_app() {
	local app_path="$1"

	if [[ "$SKIP_NOTARIZE" == "true" ]]; then
		log "Skipping stapling"
		return
	fi

	log "Stapling notarization ticket"
	xcrun stapler staple "$app_path"

	log "Assessing app with spctl"
	spctl --assess --type execute --verbose=4 "$app_path"
}

write_checksums() {
	local checksum_file="$1"
	shift

	rm -f "$checksum_file"
	(
		cd "$(dirname "$checksum_file")"
		shasum -a 256 "$@"
	) >"$checksum_file"
}

init_release_paths() {
	CLI_UNSIGNED_DIR="$ARCHIVE_ROOT/unsigned-cli"
	CLI_UNSIGNED_BINARY="$CLI_UNSIGNED_DIR/lookinside"
	if [[ -f "$CLI_UNSIGNED_BINARY" ]]; then
		CLI_BINARY="$CLI_UNSIGNED_BINARY"
	else
		CLI_BINARY_DIR="$(swift build -c release --product lookinside --show-bin-path)"
		CLI_BINARY="$CLI_BINARY_DIR/lookinside"
	fi
	CLI_ZIP="$ARCHIVE_ROOT/lookinside-${RELEASE_VERSION}-macOS-cli.zip"

	APP_ARCHIVE_PATH="$ARCHIVE_ROOT/LookInside.xcarchive"
	APP_PATH="$APP_ARCHIVE_PATH/Products/Applications/LookInside.app"
	APP_ZIP="$ARCHIVE_ROOT/LookInside-${RELEASE_VERSION}-macOS-app.zip"
	CHECKSUM_FILE="$ARCHIVE_ROOT/checksums.txt"
}

run_stage() {
	case "$STAGE" in
	build-cli)
		run_preflight
		write_release_xcconfig
		log "Release version override: MARKETING_VERSION=$RELEASE_VERSION CURRENT_PROJECT_VERSION=$RELEASE_BUILD_NUMBER"
		log "Building CLI release binary"
		swift build -c release --product lookinside
		[[ -f "$CLI_BINARY" ]] || fail "CLI binary not found at $CLI_BINARY"
		;;
	package-cli)
		[[ -f "$CLI_BINARY" ]] || fail "CLI binary not found at $CLI_BINARY"
		mkdir -p "$CLI_UNSIGNED_DIR"
		cp "$CLI_BINARY" "$CLI_UNSIGNED_BINARY"
		chmod 755 "$CLI_UNSIGNED_BINARY"
		log "Prepared unsigned CLI binary"
		log "CLI unsigned binary: $CLI_UNSIGNED_BINARY"
		;;
	sign-cli)
		ensure_signing_context
		ensure_keychain_unlocked
		[[ -f "$CLI_BINARY" ]] || fail "CLI binary not found at $CLI_BINARY"
		sign_cli "$CLI_BINARY"
		package_cli "$CLI_BINARY" "$CLI_ZIP"
		;;
	notarize-cli)
		ensure_signing_context
		[[ -f "$CLI_ZIP" ]] || fail "CLI archive not found at $CLI_ZIP"
		notarize_file "$CLI_ZIP" "CLI archive"
		;;
	archive-app)
		write_release_xcconfig
		log "Release version override: MARKETING_VERSION=$RELEASE_VERSION CURRENT_PROJECT_VERSION=$RELEASE_BUILD_NUMBER"
		archive_app_unsigned "$APP_ARCHIVE_PATH"
		[[ -d "$APP_PATH" ]] || fail "Archived app not found at $APP_PATH"
		;;
	sign-app)
		ensure_signing_context
		ensure_keychain_unlocked
		[[ -d "$APP_PATH" ]] || fail "Archived app not found at $APP_PATH"
		sign_app_bundle "$APP_PATH" "$PROJECT_ROOT/LookInside/Lookin.entitlements"
		rm -f "$APP_ZIP"
		ditto -c -k --keepParent "$APP_PATH" "$APP_ZIP"
		;;
	notarize-app)
		ensure_signing_context
		[[ -f "$APP_ZIP" ]] || fail "App archive not found at $APP_ZIP"
		notarize_file "$APP_ZIP" "macOS app archive"
		staple_app "$APP_PATH"
		rm -f "$APP_ZIP"
		ditto -c -k --keepParent "$APP_PATH" "$APP_ZIP"
		;;
	finalize)
		[[ -f "$CLI_ZIP" ]] || fail "CLI archive not found at $CLI_ZIP"
		[[ -f "$APP_ZIP" ]] || fail "App archive not found at $APP_ZIP"
		write_checksums "$CHECKSUM_FILE" \
			"$(basename "$CLI_ZIP")" \
			"$(basename "$APP_ZIP")"
		log "Release artifacts ready"
		log "CLI zip: $CLI_ZIP"
		log "App zip: $APP_ZIP"
		log "Checksums: $CHECKSUM_FILE"
		;;
	all)
		STAGE="build-cli"
		run_stage
		STAGE="package-cli"
		run_stage
		STAGE="archive-app"
		run_stage
		STAGE="sign-cli"
		run_stage
		STAGE="notarize-cli"
		run_stage
		STAGE="sign-app"
		run_stage
		STAGE="notarize-app"
		run_stage
		STAGE="finalize"
		run_stage
		;;
	*)
		fail "Unknown stage '$STAGE'"
		;;
	esac
}

parse_args "$@"

capture_original_keychain_state
trap restore_original_keychain_state EXIT

[[ -n "$RAW_TAG" ]] || fail "--tag is required."
RELEASE_VERSION="$(normalize_tag_version "$RAW_TAG")"
RAW_TAG="${RAW_TAG#refs/tags/}"

if [[ -z "$ARCHIVE_ROOT" ]]; then
	ARCHIVE_ROOT="$PROJECT_ROOT/build/releases/$RAW_TAG"
fi

require_command bash
require_command swift
require_command xcodebuild
require_command codesign
require_command xcrun
require_command ditto
require_command shasum
require_command security
require_command spctl
require_command find
require_command file

mkdir -p "$ARCHIVE_ROOT"
init_release_paths
run_stage
