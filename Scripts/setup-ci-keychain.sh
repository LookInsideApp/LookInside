#!/bin/bash

set -euo pipefail

KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-}"
KEYCHAIN_PATH="${KEYCHAIN_PATH:-${RUNNER_TEMP:-/tmp}/lookinside-ci.keychain-db}"
ENV_OUTPUT_FILE=""
GITHUB_OUTPUT_FILE=""
PRESERVE_KEYCHAIN_STATE="${PRESERVE_KEYCHAIN_STATE:-}"
ORIGINAL_DEFAULT_KEYCHAIN=""
ORIGINAL_KEYCHAINS=()

usage() {
	cat <<'EOF'
Usage: bash Scripts/setup-ci-keychain.sh [options]

Options:
  --env-file <path>         Write detected values as shell exports to this file.
  --output-file <path>      Write detected values as GitHub-style outputs to this file.
  --keychain-path <path>    Restore the keychain to this path.
  --keychain-profile <name> Override the detected notarytool keychain profile.
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

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--env-file)
			ENV_OUTPUT_FILE="${2:-}"
			shift 2
			;;
		--output-file)
			GITHUB_OUTPUT_FILE="${2:-}"
			shift 2
			;;
		--keychain-path)
			KEYCHAIN_PATH="${2:-}"
			shift 2
			;;
		--keychain-profile)
			KEYCHAIN_PROFILE="${2:-}"
			shift 2
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

load_secrets_from_zshrc_if_needed() {
	if [[ -n "${KEYCHAIN_CONTENT_GZIP:-}" && -n "${KEYCHAIN_SECRET:-}" ]]; then
		return
	fi

	command -v zsh >/dev/null 2>&1 || return

	local tmp_dir
	tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/lookinside-keychain-env.XXXXXX")"
	chmod 700 "$tmp_dir"

	zsh -lc '
        source ~/.zshrc >/dev/null 2>&1 || true
        umask 077
        [[ -n "${KEYCHAIN_CONTENT_GZIP:-}" ]] && printf "%s" "$KEYCHAIN_CONTENT_GZIP" > "$1/content"
        [[ -n "${KEYCHAIN_SECRET:-}" ]] && printf "%s" "$KEYCHAIN_SECRET" > "$1/secret"
        true
    ' zsh "$tmp_dir"

	if [[ -z "${KEYCHAIN_CONTENT_GZIP:-}" && -f "$tmp_dir/content" ]]; then
		KEYCHAIN_CONTENT_GZIP="$(<"$tmp_dir/content")"
	fi
	if [[ -z "${KEYCHAIN_SECRET:-}" && -f "$tmp_dir/secret" ]]; then
		KEYCHAIN_SECRET="$(<"$tmp_dir/secret")"
	fi

	rm -rf "$tmp_dir"
}

restore_keychain() {
	if [[ -z "${KEYCHAIN_CONTENT_GZIP:-}" && -z "${KEYCHAIN_SECRET:-}" ]]; then
		KEYCHAIN_PATH="$(security default-keychain -d user 2>/dev/null | sed 's/^ *"//; s/"$//')"
		[[ -n "$KEYCHAIN_PATH" ]] || fail "Unable to detect current default keychain."
		log "Using current default keychain because CI keychain secrets are not set"
		return
	fi

	[[ -n "${KEYCHAIN_CONTENT_GZIP:-}" ]] || fail "KEYCHAIN_CONTENT_GZIP is not set."
	[[ -n "${KEYCHAIN_SECRET:-}" ]] || fail "KEYCHAIN_SECRET is not set."

	mkdir -p "$(dirname "$KEYCHAIN_PATH")"
	rm -f "$KEYCHAIN_PATH"

	log "Restoring signing keychain"
	printf "%s" "$KEYCHAIN_CONTENT_GZIP" | base64 -d | gzip -dc >"$KEYCHAIN_PATH"
	chmod 600 "$KEYCHAIN_PATH"

	log "Setting restored keychain as default"
	run_and_log_status "security default-keychain" security default-keychain -d user -s "$KEYCHAIN_PATH"

	log "Unlocking restored keychain"
	run_and_log_status "security unlock-keychain" security unlock-keychain -p "$KEYCHAIN_SECRET" "$KEYCHAIN_PATH"
	run_and_log_status "security set-keychain-settings" security set-keychain-settings -t 3600 -u "$KEYCHAIN_PATH"
	run_and_log_status "security set-key-partition-list" security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_SECRET" "$KEYCHAIN_PATH"

	local existing_keychains=()
	local line
	while IFS= read -r line; do
		line="$(sed 's/^ *"//; s/"$//' <<<"$line")"
		[[ -n "$line" ]] && existing_keychains+=("$line")
	done < <(security list-keychains -d user)

	log "Adding restored keychain to user search list"
	run_and_log_status "security list-keychains" security list-keychains -d user -s "$KEYCHAIN_PATH" "${existing_keychains[@]}"
}

detect_signing_identity() {
	local identity_line
	identity_line="$(
		security find-identity -v -p codesigning "$KEYCHAIN_PATH" 2>/dev/null |
			grep "Developer ID Application" |
			head -n 1
	)"

	[[ -n "$identity_line" ]] || fail "No Developer ID Application identity found in restored keychain."

	SIGNING_IDENTITY_NAME="$(sed -n 's/.*"\(Developer ID Application: [^"]*\)".*/\1/p' <<<"$identity_line")"
	SIGNING_IDENTITY_HASH="$(awk '{print $2}' <<<"$identity_line")"
	SIGNING_IDENTITY="${SIGNING_IDENTITY_HASH:-$SIGNING_IDENTITY_NAME}"
	DEVELOPMENT_TEAM="$(sed -n 's/.*(\([A-Z0-9]\{10\}\)).*/\1/p' <<<"$SIGNING_IDENTITY_NAME")"
	[[ -n "$DEVELOPMENT_TEAM" ]] || fail "Unable to derive DEVELOPMENT_TEAM from signing identity '$SIGNING_IDENTITY'."
}

detect_keychain_profile() {
	if [[ -n "$KEYCHAIN_PROFILE" ]]; then
		return
	fi

	KEYCHAIN_PROFILE="$(
		security dump-keychain -r "$KEYCHAIN_PATH" 2>/dev/null |
			strings |
			grep "com.apple.gke.notary.tool.saved-creds" |
			head -n 1 |
			awk -F. '{print $NF}' |
			tr -d '"'
	)"

	[[ -n "$KEYCHAIN_PROFILE" ]] || fail "Unable to detect a saved notarytool keychain profile from restored keychain."
}

write_env_file() {
	if [[ -n "$ENV_OUTPUT_FILE" ]]; then
		cat >"$ENV_OUTPUT_FILE" <<EOF
export KEYCHAIN_PATH=$(printf '%q' "$KEYCHAIN_PATH")
export KEYCHAIN_PROFILE=$(printf '%q' "$KEYCHAIN_PROFILE")
export SIGNING_IDENTITY=$(printf '%q' "$SIGNING_IDENTITY")
export SIGNING_IDENTITY_NAME=$(printf '%q' "$SIGNING_IDENTITY_NAME")
export SIGNING_IDENTITY_HASH=$(printf '%q' "$SIGNING_IDENTITY_HASH")
export DEVELOPMENT_TEAM=$(printf '%q' "$DEVELOPMENT_TEAM")
EOF
	fi

	if [[ -n "$GITHUB_OUTPUT_FILE" ]]; then
		{
			echo "keychain_path=$KEYCHAIN_PATH"
			echo "keychain_profile=$KEYCHAIN_PROFILE"
			echo "signing_identity=$SIGNING_IDENTITY"
			echo "signing_identity_name=$SIGNING_IDENTITY_NAME"
			echo "signing_identity_hash=$SIGNING_IDENTITY_HASH"
			echo "development_team=$DEVELOPMENT_TEAM"
		} >>"$GITHUB_OUTPUT_FILE"
	fi
}

parse_args "$@"

require_command base64
require_command gzip
require_command security

capture_original_keychain_state
trap restore_original_keychain_state EXIT

load_secrets_from_zshrc_if_needed
restore_keychain
detect_signing_identity
detect_keychain_profile
write_env_file

log "Using signing identity: $SIGNING_IDENTITY"
log "Using development team: $DEVELOPMENT_TEAM"
log "Using keychain profile: $KEYCHAIN_PROFILE"
log "Current default keychain: $(security default-keychain -d user | sed 's/\"//g')"
