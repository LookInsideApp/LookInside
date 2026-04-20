#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT_ROOT="$PWD"
PROJECT_FILE="$PROJECT_ROOT/LookInside.xcodeproj"
VERSION_XCCONFIG="$PROJECT_ROOT/Configuration/Version.xcconfig"
SCHEME="LookInside"
CONFIGURATION="Release"
REMOTE="origin"
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-Lakr233}"
RELEASE_TITLE="${RELEASE_TITLE:-automatic release}"
SKIP_TESTS=false
SKIP_NOTARIZE=false
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}"
REQUESTED_VERSION=""
REQUESTED_BUILD_NUMBER=""
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/LookInsideReleaseDerivedData}"

usage() {
    cat <<'EOF'
Usage: bash Scripts/build-and-release.sh [options]

Options:
  --version <x.y.z>          Release this version. If omitted, bump the current patch version by 1.
  --build-number <n>         Set CURRENT_PROJECT_VERSION. If omitted, increment the current build number by 1.
  --signing-identity <name>  Override the Developer ID Application identity used for archive signing.
  --keychain-profile <name>  notarytool keychain profile name. Default: Lakr233
  --remote <name>            Git remote to push. Default: origin
  --release-title <text>     GitHub release title. Default: automatic release
  --skip-tests               Skip Scripts/test.sh before archiving.
  --skip-notarize            Skip notarization and stapling.
  --help, -h                 Show this help.
EOF
}

log() {
    echo "==> $*"
}

fail() {
    echo "Error: $*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --version)
                REQUESTED_VERSION="${2:-}"
                shift 2
                ;;
            --build-number)
                REQUESTED_BUILD_NUMBER="${2:-}"
                shift 2
                ;;
            --signing-identity)
                SIGNING_IDENTITY="${2:-}"
                shift 2
                ;;
            --keychain-profile)
                KEYCHAIN_PROFILE="${2:-}"
                shift 2
                ;;
            --remote)
                REMOTE="${2:-}"
                shift 2
                ;;
            --release-title)
                RELEASE_TITLE="${2:-}"
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
            --help|-h)
                usage
                exit 0
                ;;
            *)
                fail "Unknown option: $1"
                ;;
        esac
    done
}

current_branch() {
    git branch --show-current
}

ensure_clean_worktree() {
    local status
    status="$(git status --porcelain)"
    [[ -z "$status" ]] || fail "Git worktree is not clean. Commit or stash changes before running a release."
}

ensure_valid_version() {
    [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Invalid version '$1'. Expected x.y.z"
}

ensure_valid_build_number() {
    [[ "$1" =~ ^[0-9]+$ ]] || fail "Invalid build number '$1'. Expected an integer"
}

build_setting() {
    local key="$1"
    xcodebuild \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -showBuildSettings 2>/dev/null \
        | awk -F' = ' -v search_key="$key" '$1 ~ search_key"$" { print $2; exit }'
}

increment_patch_version() {
    local version="$1"
    IFS='.' read -r major minor patch <<<"$version"
    echo "${major}.${minor}.$((patch + 1))"
}

detect_signing_identity() {
    if [[ -n "$SIGNING_IDENTITY" ]]; then
        echo "$SIGNING_IDENTITY"
        return
    fi

    local identity
    identity="$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' '/Developer ID Application:/ { print $2; exit }')"
    [[ -n "$identity" ]] || fail "Could not find a Developer ID Application identity in the local keychain."
    echo "$identity"
}

detect_development_team() {
    if [[ -n "$DEVELOPMENT_TEAM" ]]; then
        echo "$DEVELOPMENT_TEAM"
        return
    fi

    local team
    team="$(build_setting DEVELOPMENT_TEAM)"
    [[ -n "$team" ]] || fail "Set DEVELOPMENT_TEAM in Configuration/Base.xcconfig, a local Developer*.xcconfig override, or export DEVELOPMENT_TEAM before building a signed release."
    echo "$team"
}

update_target_versions() {
    local version="$1"
    local build_number="$2"

    mkdir -p "$(dirname "$VERSION_XCCONFIG")"
    cat > "$VERSION_XCCONFIG" <<EOF
//
//  Version.xcconfig
//  LookInside
//

MARKETING_VERSION = $version
CURRENT_PROJECT_VERSION = $build_number
EOF
}

ensure_tag_absent() {
    local tag="$1"
    if git rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1; then
        fail "Local tag '$tag' already exists."
    fi

    if git ls-remote --exit-code --tags "$REMOTE" "refs/tags/$tag" >/dev/null 2>&1; then
        fail "Remote tag '$tag' already exists on '$REMOTE'."
    fi
}

commit_version_bump() {
    local version="$1"
    local build_number="$2"
    git add "$VERSION_XCCONFIG"
    git commit -m "Release ${version} (${build_number})"
}

run_preflight() {
    if [[ "$SKIP_TESTS" == "true" ]]; then
        log "Skipping preflight checks"
        return
    fi

    log "Running preflight checks"
    bash Scripts/test.sh
}

create_archive() {
    local archive_path="$1"
    local identity="$2"
    local development_team
    development_team="$(detect_development_team)"

    rm -rf "$archive_path"
    rm -rf "$DERIVED_DATA_PATH"

    log "Archiving signed app"
    bash Scripts/write-github-action-xcconfig.sh \
        --version "$NEXT_VERSION" \
        --build-number "$NEXT_BUILD_NUMBER" \
        --development-team "$development_team" \
        --signing-identity "$identity"

    xcodebuild \
        -skipMacroValidation \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -destination "generic/platform=macOS" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -archivePath "$archive_path" \
        archive
}

verify_codesign() {
    local app_path="$1"
    log "Verifying code signature"
    codesign --verify --deep --strict --verbose=2 "$app_path"
}

notarize_app() {
    local app_path="$1"
    local zip_path="$2"

    rm -f "$zip_path"
    ditto -c -k --keepParent "$app_path" "$zip_path"

    if [[ "$SKIP_NOTARIZE" == "true" ]]; then
        log "Skipping notarization"
        return
    fi

    log "Submitting app for notarization"
    xcrun notarytool submit "$zip_path" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        --wait

    log "Stapling notarization ticket"
    xcrun stapler staple "$app_path"
}

verify_spctl() {
    local app_path="$1"
    if [[ "$SKIP_NOTARIZE" == "true" ]]; then
        log "Skipping spctl assessment because notarization was skipped"
        return
    fi

    log "Running spctl assessment"
    spctl --assess --type execute --verbose=4 "$app_path"
}

repack_release_zip() {
    local app_path="$1"
    local zip_path="$2"
    rm -f "$zip_path"
    ditto -c -k --keepParent "$app_path" "$zip_path"
}

push_release_refs() {
    local branch="$1"
    local tag="$2"

    log "Pushing branch $branch"
    git push "$REMOTE" "HEAD:$branch"

    log "Pushing tag $tag"
    git push "$REMOTE" "$tag"
}

create_github_release() {
    local tag="$1"
    local asset="$2"
    local notes="$3"

    log "Creating GitHub release"
    gh release create "$tag" "$asset" \
        --title "$RELEASE_TITLE" \
        --notes "$notes"
}

parse_args "$@"

require_command git
require_command xcodebuild
require_command codesign
require_command spctl
require_command xcrun
require_command gh
require_command security
require_command ditto

ensure_clean_worktree

BRANCH="$(current_branch)"
[[ -n "$BRANCH" ]] || fail "Detached HEAD is not supported for releases."

CURRENT_VERSION="$(build_setting MARKETING_VERSION)"
[[ -n "$CURRENT_VERSION" ]] || fail "Could not read MARKETING_VERSION from Xcode build settings."
ensure_valid_version "$CURRENT_VERSION"

CURRENT_BUILD_NUMBER="$(build_setting CURRENT_PROJECT_VERSION)"
[[ -n "$CURRENT_BUILD_NUMBER" ]] || fail "Could not read CURRENT_PROJECT_VERSION from Xcode build settings."
ensure_valid_build_number "$CURRENT_BUILD_NUMBER"

if [[ -n "$REQUESTED_VERSION" ]]; then
    ensure_valid_version "$REQUESTED_VERSION"
    NEXT_VERSION="$REQUESTED_VERSION"
else
    NEXT_VERSION="$(increment_patch_version "$CURRENT_VERSION")"
fi

if [[ -n "$REQUESTED_BUILD_NUMBER" ]]; then
    ensure_valid_build_number "$REQUESTED_BUILD_NUMBER"
    NEXT_BUILD_NUMBER="$REQUESTED_BUILD_NUMBER"
else
    NEXT_BUILD_NUMBER="$((CURRENT_BUILD_NUMBER + 1))"
fi

[[ "$NEXT_VERSION" != "$CURRENT_VERSION" ]] || fail "Next version matches current version ($CURRENT_VERSION)."

ensure_tag_absent "$NEXT_VERSION"

ARCHIVE_ROOT="$PROJECT_ROOT/build/releases/$NEXT_VERSION"
ARCHIVE_PATH="$ARCHIVE_ROOT/LookInside.xcarchive"
APP_PATH="$ARCHIVE_PATH/Products/Applications/LookInside.app"
RELEASE_ZIP="$ARCHIVE_ROOT/LookInside-${NEXT_VERSION}-macOS.zip"
NOTES="Automatic release for ${NEXT_VERSION}"

mkdir -p "$ARCHIVE_ROOT"

log "Current version: $CURRENT_VERSION ($CURRENT_BUILD_NUMBER)"
log "Next version: $NEXT_VERSION ($NEXT_BUILD_NUMBER)"

update_target_versions "$NEXT_VERSION" "$NEXT_BUILD_NUMBER"

if git diff --quiet -- "$VERSION_XCCONFIG"; then
    fail "Version update did not modify $VERSION_XCCONFIG."
fi

commit_version_bump "$NEXT_VERSION" "$NEXT_BUILD_NUMBER"
git tag -a "$NEXT_VERSION" -m "Release $NEXT_VERSION"

run_preflight

IDENTITY="$(detect_signing_identity)"
log "Using signing identity: $IDENTITY"

create_archive "$ARCHIVE_PATH" "$IDENTITY"
[[ -d "$APP_PATH" ]] || fail "Archived app not found at $APP_PATH"

verify_codesign "$APP_PATH"
notarize_app "$APP_PATH" "$RELEASE_ZIP"
verify_spctl "$APP_PATH"
repack_release_zip "$APP_PATH" "$RELEASE_ZIP"

push_release_refs "$BRANCH" "$NEXT_VERSION"
create_github_release "$NEXT_VERSION" "$RELEASE_ZIP" "$NOTES"

log "Release complete"
log "Artifact: $RELEASE_ZIP"
