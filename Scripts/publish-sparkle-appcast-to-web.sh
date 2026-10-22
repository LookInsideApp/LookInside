#!/bin/bash

set -euo pipefail

WEB_DIR=""
APP_ZIP=""
PRIVATE_KEY_FILE=""
SPARKLE_TOOLS_DIR="${SPARKLE_TOOLS_DIR:-}"
PUBLIC_BASE_URL="${PUBLIC_BASE_URL:-https://lookinside-app.com}"
RELEASE_NOTES_FILE=""
RELEASE_VERSION=""
ASSET_DOWNLOAD_URL=""
MANIFEST_ASSET_ID="${MANIFEST_ASSET_ID:-lookinside-app}"
PRUNE_APPCAST_VERSIONS="${PRUNE_APPCAST_VERSIONS:-}"
PRUNE_APPCAST_DELTAS="${PRUNE_APPCAST_DELTAS:-false}"

usage() {
	cat <<'EOF'
Usage: bash Scripts/publish-sparkle-appcast-to-web.sh --web-dir <path> --app-zip <path> --private-key-file <path> [options]

Options:
  --web-dir <path>             Checkout path of the website target repo.
  --app-zip <path>             Signed, notarized LookInside app zip.
  --private-key-file <path>    Plaintext Sparkle private EdDSA key file, usually decrypted into RUNNER_TEMP.
  --sparkle-tools-dir <path>   Sparkle distribution directory containing bin/generate_appcast.
  --public-base-url <url>      Public website origin. Default: https://lookinside-app.com.
  --release-notes-file <path>  Markdown release notes to copy next to the archive.
  --version <version>          Version string used for fallback release notes.
  --help, -h                   Show this help.
EOF
}

fail() {
	echo "Error: $*" >&2
	exit 1
}

file_size() {
	local path="$1"
	if stat -f%z "$path" >/dev/null 2>&1; then
		stat -f%z "$path"
	else
		stat -c%s "$path"
	fi
}

trim_whitespace() {
	local value="$1"
	value="${value#"${value%%[![:space:]]*}"}"
	value="${value%"${value##*[![:space:]]}"}"
	printf '%s' "$value"
}

prune_appcast_assets() {
	local prune_versions="$1"
	local prune_deltas="$2"
	local should_regenerate_cleanly="false"
	local old_ifs version normalized

	if [[ -n "$prune_versions" ]]; then
		should_regenerate_cleanly="true"
		old_ifs="$IFS"
		IFS=","
		read -ra versions <<<"$prune_versions"
		IFS="$old_ifs"

		for version in "${versions[@]}"; do
			normalized="$(trim_whitespace "$version")"
			normalized="${normalized#v}"
			[[ -n "$normalized" ]] || continue
			[[ "$normalized" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
				fail "Invalid prune appcast version: $version"

			rm -f \
				"$updates_dir/LookInside-${normalized}-macOS-app.zip" \
				"$updates_dir/LookInside-${normalized}-macOS-app.md"
		done
	fi

	if [[ "$prune_deltas" == "true" ]]; then
		should_regenerate_cleanly="true"
		find "$updates_dir" -maxdepth 1 -type f -name '*.delta' -delete
	fi

	if [[ "$should_regenerate_cleanly" == "true" ]]; then
		rm -f "$public_dir/appcast.xml"
	fi
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--web-dir)
			WEB_DIR="${2:-}"
			shift 2
			;;
		--app-zip)
			APP_ZIP="${2:-}"
			shift 2
			;;
		--private-key-file)
			PRIVATE_KEY_FILE="${2:-}"
			shift 2
			;;
		--sparkle-tools-dir)
			SPARKLE_TOOLS_DIR="${2:-}"
			shift 2
			;;
		--public-base-url)
			PUBLIC_BASE_URL="${2:-}"
			shift 2
			;;
		--release-notes-file)
			RELEASE_NOTES_FILE="${2:-}"
			shift 2
			;;
		--version)
			RELEASE_VERSION="${2:-}"
			shift 2
			;;
		--asset-download-url)
			ASSET_DOWNLOAD_URL="${2:-}"
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

parse_args "$@"

[[ -n "$WEB_DIR" ]] || fail "--web-dir is required."
[[ -n "$APP_ZIP" ]] || fail "--app-zip is required."
[[ -n "$PRIVATE_KEY_FILE" ]] || fail "--private-key-file is required."
[[ -n "$SPARKLE_TOOLS_DIR" ]] || fail "--sparkle-tools-dir is required."
[[ -n "$ASSET_DOWNLOAD_URL" ]] || fail "--asset-download-url is required."
[[ -n "$RELEASE_VERSION" ]] || fail "--version is required."
[[ -d "$WEB_DIR/public" ]] || fail "Web public directory not found: $WEB_DIR/public"
[[ -f "$APP_ZIP" ]] || fail "App zip not found: $APP_ZIP"
[[ -f "$PRIVATE_KEY_FILE" ]] || fail "Sparkle private key file not found: $PRIVATE_KEY_FILE"
[[ -f "$WEB_DIR/scripts/update-manifest.mjs" ]] || fail "Manifest update script not found at $WEB_DIR/scripts/update-manifest.mjs."

generate_appcast="$SPARKLE_TOOLS_DIR/bin/generate_appcast"
[[ -x "$generate_appcast" ]] || fail "generate_appcast is not executable: $generate_appcast"

app_size="$(file_size "$APP_ZIP")"
app_sha256="$(shasum -a 256 "$APP_ZIP" | awk '{ print $1 }')"
[[ -n "$app_sha256" ]] || fail "Failed to compute sha256 for $APP_ZIP."

public_dir="$WEB_DIR/public"
updates_dir="$public_dir/downloads/lookinside"
mkdir -p "$updates_dir"

zip_name="$(basename "$APP_ZIP")"
published_zip="$updates_dir/$zip_name"
cp "$APP_ZIP" "$published_zip"

notes_name="${zip_name%.zip}.md"
published_notes="$updates_dir/$notes_name"
if [[ -n "$RELEASE_NOTES_FILE" ]]; then
	[[ -f "$RELEASE_NOTES_FILE" ]] || fail "Release notes file not found: $RELEASE_NOTES_FILE"
	cp "$RELEASE_NOTES_FILE" "$published_notes"
else
	display_version="${RELEASE_VERSION:-${zip_name}}"
	printf '# LookInside %s\n\nRelease notes are available on GitHub.\n' "$display_version" >"$published_notes"
fi

prune_appcast_assets "$PRUNE_APPCAST_VERSIONS" "$PRUNE_APPCAST_DELTAS"

private_key="$(tr -d '\r\n' <"$PRIVATE_KEY_FILE")"
[[ -n "$private_key" ]] || fail "Sparkle private key file is empty."

printf '%s\n' "$private_key" | "$generate_appcast" \
	--ed-key-file - \
	--download-url-prefix "${PUBLIC_BASE_URL}/downloads/lookinside/" \
	--release-notes-url-prefix "${PUBLIC_BASE_URL}/downloads/lookinside/" \
	--embed-release-notes \
	--maximum-versions 0 \
	-o "$public_dir/appcast.xml" \
	"$updates_dir"

[[ -f "$public_dir/appcast.xml" ]] || fail "Appcast was not generated."
grep -q "sparkle:edSignature=" "$public_dir/appcast.xml" ||
	fail "Generated appcast is missing Sparkle EdDSA signatures. Check that SPARKLE_PUBLIC_ED_KEY matches the encrypted private key."

manifest_path="$public_dir/downloads/manifest.json"
[[ -f "$manifest_path" ]] || fail "Web manifest not found: $manifest_path"

node "$WEB_DIR/scripts/update-manifest.mjs" \
	--manifest "$manifest_path" \
	--id "$MANIFEST_ASSET_ID" \
	--destination "public/downloads/lookinside/$zip_name" \
	--version "$RELEASE_VERSION" \
	--tag "$RELEASE_VERSION" \
	--size "$app_size" \
	--sha256 "$app_sha256" \
	--url "$ASSET_DOWNLOAD_URL"

# The zip itself stays out of the web git repo, and out of the site: it is
# above the 25 MiB Cloudflare Workers asset limit, so the site answers its
# download path with a 302 to $ASSET_DOWNLOAD_URL (see the web repo's
# scripts/download-assets.mjs).
rm -f "$published_zip"
