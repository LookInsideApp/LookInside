#!/usr/bin/env bash
#
# Build a notarized LookInside DMG.
#
# Usage:
#   Scripts/build-dmg.sh [--keychain-profile PROFILE] [--no-notarize]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_FILE="$PROJECT_ROOT/LookInside.xcworkspace"
SCHEME="LookInside"
CONFIGURATION="Release"
BUNDLE_IDENTIFIER="cn.vanjay.lookinside"
DEVELOPMENT_TEAM="X6B6C6U6QV"
DEVELOPER_ID_APPLICATION_REQUIREMENT="anchor apple generic and certificate leaf[field.1.2.840.113635.100.6.1.13] exists"
KEYCHAIN_PROFILE="vanjay_mac_stapler"
SKIP_NOTARIZE=false
BUILD_ROOT="$PROJECT_ROOT/build"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$BUILD_ROOT/DerivedData}"
SOURCE_PACKAGES_PATH="${SOURCE_PACKAGES_PATH:-$DERIVED_DATA_PATH/SourcePackages}"
ARCHIVE_PATH="$BUILD_ROOT/dmg-archive/LookInside.xcarchive"
DMG_OUTPUT_DIR="$BUILD_ROOT/dmg"
DMG_WORK_DIR="$BUILD_ROOT/dmg-tmp"
PACKAGE_SCM_PROVIDER="${PACKAGE_SCM_PROVIDER:-system}"
PACKAGE_AUTH_PROVIDER="${PACKAGE_AUTH_PROVIDER:-}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
APP_PRODUCT_NAME=""
APP_EXECUTABLE_NAME=""
MARKETING_VERSION=""
CURRENT_PROJECT_VERSION=""
APP_PATH=""
INJECTOR_REPO="$PROJECT_ROOT/../LookInside-Injector"

usage() {
	cat <<'EOF'
Usage: Scripts/build-dmg.sh [options]

Options:
  --keychain-profile <name> Notarytool keychain profile. Default: vanjay_mac_stapler.
  --no-notarize            Build the DMG without submitting to Apple notarization.
  --help, -h               Show this help.
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
		--keychain-profile)
			[[ -n "${2:-}" && "$2" != --* ]] || fail "--keychain-profile requires a profile name."
			KEYCHAIN_PROFILE="$2"
			shift 2
			;;
		--no-notarize)
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

format_output() {
	if command -v xcbeautify >/dev/null 2>&1; then
		xcbeautify --disable-logging
	else
		cat
	fi
}

read_build_setting() {
	local key="$1"
	local overrides=(
		PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_IDENTIFIER"
		DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"
	)

	xcodebuild \
		-workspace "$WORKSPACE_FILE" \
		-scheme "$SCHEME" \
		-configuration "$CONFIGURATION" \
		-showBuildSettings \
		"${overrides[@]}" 2>/dev/null |
		awk -F' = ' -v search_key="$key" '$1 ~ search_key"$" { print $2; exit }'
}

load_build_settings() {
	APP_PRODUCT_NAME="$(read_build_setting FULL_PRODUCT_NAME)"
	APP_EXECUTABLE_NAME="$(read_build_setting EXECUTABLE_NAME)"
	MARKETING_VERSION="$(read_build_setting MARKETING_VERSION)"
	CURRENT_PROJECT_VERSION="$(read_build_setting CURRENT_PROJECT_VERSION)"

	[[ -n "$APP_PRODUCT_NAME" ]] || fail "Unable to read FULL_PRODUCT_NAME."
	[[ -n "$APP_EXECUTABLE_NAME" ]] || fail "Unable to read EXECUTABLE_NAME."
	[[ -n "$MARKETING_VERSION" ]] || fail "Unable to read MARKETING_VERSION."
	[[ -n "$CURRENT_PROJECT_VERSION" ]] || fail "Unable to read CURRENT_PROJECT_VERSION."

	APP_PATH="$ARCHIVE_PATH/Products/Applications/$APP_PRODUCT_NAME"
}

note_release_prerequisites() {
	if [[ ! -d "$INJECTOR_REPO" ]]; then
		log "LookInside-Injector repo not found; building DMG without the injector daemon."
		log "Injector-dependent attach/injection features will be unavailable in this build."
	fi
}

detect_signing_identity() {
	if [[ -n "$SIGNING_IDENTITY" ]]; then
		return
	fi

	SIGNING_IDENTITY="$(
		security find-identity -v -p codesigning 2>/dev/null |
			grep "Developer ID Application: .*($DEVELOPMENT_TEAM)" |
			head -n 1 |
			awk '{print $2}'
	)"

	[[ -n "$SIGNING_IDENTITY" ]] || fail "No Developer ID Application identity found for team $DEVELOPMENT_TEAM."
}

is_mach_o_file() {
	local path="$1"
	file -b "$path" 2>/dev/null | grep -q "Mach-O"
}

path_contains_symlink() {
	local path="$1"
	local root="${2:-}"
	local current="$path"

	if [[ -n "$root" ]]; then
		while [[ "$current" == "$root" || "$current" == "$root/"* ]]; do
			[[ -L "$current" ]] && return 0
			[[ "$current" == "$root" ]] && break
			current="$(dirname "$current")"
		done
		return 1
	fi

	while [[ "$current" != "/" && "$current" != "." ]]; do
		[[ -L "$current" ]] && return 0
		current="$(dirname "$current")"
	done

	return 1
}

should_skip_nested_code_path() {
	local path="$1"
	local root="${2:-}"

	[[ "$path" == *"/Versions/Current"* ]] && return 0
	path_contains_symlink "$path" "$root"
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

remove_legacy_code_resources() {
	local legacy_code_resources="$APP_PATH/Contents/CodeResources"

	if [[ -e "$legacy_code_resources" || -L "$legacy_code_resources" ]]; then
		rm -f "$legacy_code_resources"
	fi
}

sign_nested_code() {
	local main_executable="$APP_PATH/Contents/MacOS/$APP_EXECUTABLE_NAME"
	local mach_o_files=()
	local bundles=()
	local candidate

	while IFS= read -r candidate; do
		[[ "$candidate" == "$main_executable" ]] && continue
		should_skip_nested_code_path "$candidate" "$APP_PATH/Contents" && continue
		if is_mach_o_file "$candidate"; then
			mach_o_files+=("$candidate")
		fi
	done < <(find "$APP_PATH/Contents" -type f -print)

	while IFS= read -r candidate; do
		bundles+=("$candidate")
	done < <(
		find "$APP_PATH/Contents" -type d \
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
		should_skip_nested_code_path "$candidate" "$APP_PATH/Contents" && continue
		sign_code_path "$candidate"
	done
}

verify_developer_id_signature() {
	local path="$1"

	codesign \
		--verify \
		--strict \
		--verbose=2 \
		-R="$DEVELOPER_ID_APPLICATION_REQUIREMENT" \
		"$path"
}

verify_developer_id_signatures() {
	local candidate
	local signed_paths_file
	local legacy_code_resources="$APP_PATH/Contents/CodeResources"

	[[ ! -e "$legacy_code_resources" && ! -L "$legacy_code_resources" ]] ||
		fail "Legacy code signature resource envelope is present: $legacy_code_resources"

	signed_paths_file="$(mktemp "${TMPDIR:-/tmp}/lookinside-dmg-signed-code.XXXXXX")"
	printf "%s\n" "$APP_PATH" >>"$signed_paths_file"

	while IFS= read -r candidate; do
		should_skip_nested_code_path "$candidate" "$APP_PATH/Contents" && continue
		printf "%s\n" "$candidate" >>"$signed_paths_file"
	done < <(
		find "$APP_PATH/Contents" -type d \
			\( -name "*.app" -o -name "*.appex" -o -name "*.bundle" -o -name "*.framework" -o -name "*.xpc" \) \
			-print
	)

	while IFS= read -r candidate; do
		should_skip_nested_code_path "$candidate" "$APP_PATH/Contents" && continue
		if is_mach_o_file "$candidate"; then
			printf "%s\n" "$candidate" >>"$signed_paths_file"
		fi
	done < <(find "$APP_PATH/Contents" -type f -print)

	while IFS= read -r candidate; do
		log "Verifying Developer ID signature: ${candidate#$PROJECT_ROOT/}"
		verify_developer_id_signature "$candidate"
	done < <(sort -u "$signed_paths_file")

	rm -f "$signed_paths_file"
}

build_app_unsigned() {
	local app_products_dir="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION"
	local built_app_path="$app_products_dir/$APP_PRODUCT_NAME"
	local resolve_args=(
		-skipMacroValidation
		-skipPackagePluginValidation
		-skipPackageUpdates
		-disablePackageRepositoryCache
		-skipPackageSignatureValidation
		-packageFingerprintPolicy warn
		-packageSigningEntityPolicy warn
		-scmProvider "$PACKAGE_SCM_PROVIDER"
		-workspace "$WORKSPACE_FILE"
		-scheme "$SCHEME"
		-configuration "$CONFIGURATION"
		-clonedSourcePackagesDirPath "$SOURCE_PACKAGES_PATH"
	)
	local xcodebuild_args=(
		-skipMacroValidation
		-skipPackagePluginValidation
		-disableAutomaticPackageResolution
		-onlyUsePackageVersionsFromResolvedFile
		-skipPackageUpdates
		-disablePackageRepositoryCache
		-skipPackageSignatureValidation
		-packageFingerprintPolicy warn
		-packageSigningEntityPolicy warn
		-scmProvider "$PACKAGE_SCM_PROVIDER"
		-workspace "$WORKSPACE_FILE"
		-scheme "$SCHEME"
		-configuration "$CONFIGURATION"
		-destination "generic/platform=macOS"
		-derivedDataPath "$DERIVED_DATA_PATH"
		-clonedSourcePackagesDirPath "$SOURCE_PACKAGES_PATH"
		PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_IDENTIFIER"
		DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"
		LOOKINSIDE_ALLOW_MISSING_INJECTOR=YES
		CODE_SIGNING_ALLOWED=NO
	)

	if [[ -n "${SPARKLE_PUBLIC_ED_KEY:-}" ]]; then
		xcodebuild_args+=(SPARKLE_PUBLIC_ED_KEY="$SPARKLE_PUBLIC_ED_KEY")
	fi

	if [[ -n "$PACKAGE_AUTH_PROVIDER" ]]; then
		resolve_args+=(-packageAuthorizationProvider "$PACKAGE_AUTH_PROVIDER")
		xcodebuild_args+=(-packageAuthorizationProvider "$PACKAGE_AUTH_PROVIDER")
	fi

	rm -rf "$ARCHIVE_PATH" "$DERIVED_DATA_PATH/Build" "$DERIVED_DATA_PATH/Logs"
	mkdir -p "$DERIVED_DATA_PATH" "$SOURCE_PACKAGES_PATH"

	log "Syncing derived source mirror"
	bash "$PROJECT_ROOT/Scripts/sync-derived-source.sh"

	log "Resolving Swift package dependencies"
	xcodebuild "${resolve_args[@]}" -resolvePackageDependencies 2>&1 | format_output

	log "Building $APP_PRODUCT_NAME without Xcode signing"
	xcodebuild "${xcodebuild_args[@]}" clean build 2>&1 | format_output

	[[ -d "$built_app_path" ]] || fail "Built app not found at $built_app_path"

	log "Assembling archive at ${ARCHIVE_PATH#$PROJECT_ROOT/}"
	mkdir -p "$ARCHIVE_PATH/Products/Applications"
	ditto "$built_app_path" "$APP_PATH"
	/usr/libexec/PlistBuddy -c "Add :ApplicationProperties dict" "$ARCHIVE_PATH/Info.plist" >/dev/null
	/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:ApplicationPath string Applications/$APP_PRODUCT_NAME" "$ARCHIVE_PATH/Info.plist" >/dev/null
	/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleIdentifier string $BUNDLE_IDENTIFIER" "$ARCHIVE_PATH/Info.plist" >/dev/null
	/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleShortVersionString string $MARKETING_VERSION" "$ARCHIVE_PATH/Info.plist" >/dev/null
	/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleVersion string $CURRENT_PROJECT_VERSION" "$ARCHIVE_PATH/Info.plist" >/dev/null
	/usr/libexec/PlistBuddy -c "Add :ArchiveVersion integer 2" "$ARCHIVE_PATH/Info.plist" >/dev/null
	/usr/libexec/PlistBuddy -c "Add :Name string LookInside" "$ARCHIVE_PATH/Info.plist" >/dev/null
	/usr/libexec/PlistBuddy -c "Add :SchemeName string $SCHEME" "$ARCHIVE_PATH/Info.plist" >/dev/null
}

sign_app_bundle() {
	local entitlements_path="$PROJECT_ROOT/LookInside/Lookin.entitlements"
	local main_executable="$APP_PATH/Contents/MacOS/$APP_EXECUTABLE_NAME"

	[[ -f "$main_executable" ]] || fail "Main app executable not found at $main_executable"
	chmod 755 "$main_executable"
	[[ -x "$main_executable" ]] || fail "Main app executable is not executable: $main_executable"

	remove_legacy_code_resources
	sign_nested_code

	log "Signing app bundle"
	codesign \
		--sign "$SIGNING_IDENTITY" \
		--entitlements "$entitlements_path" \
		--options runtime \
		--timestamp \
		--verbose=4 \
		--force \
		"$APP_PATH"

	log "Verifying app signature"
	codesign --verify --deep --strict --verbose=2 "$APP_PATH"
	verify_developer_id_signatures
}

verify_bundle_identifier() {
	local actual_bundle_identifier

	actual_bundle_identifier="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Contents/Info.plist")"
	[[ "$actual_bundle_identifier" == "$BUNDLE_IDENTIFIER" ]] ||
		fail "CFBundleIdentifier is $actual_bundle_identifier, expected $BUNDLE_IDENTIFIER"
}

generate_dmg_background() {
	local output_path="$1"

	/usr/bin/swift - "$output_path" <<'SWIFT'
import Cocoa
import Foundation

guard CommandLine.arguments.count >= 2 else {
    fputs("Error: Missing output path\n", stderr)
    exit(1)
}

let outputPath = CommandLine.arguments[1]

final class BackgroundView: NSView {
    private enum C {
        static let width: CGFloat = 620
        static let height: CGFloat = 360
        static let background = NSColor(srgbRed: 0.94, green: 0.96, blue: 0.98, alpha: 1)
        static let header = NSColor(srgbRed: 0.74, green: 0.86, blue: 0.93, alpha: 1)
        static let accent = NSColor(srgbRed: 0.08, green: 0.38, blue: 0.56, alpha: 1)
        static let text = NSColor(srgbRed: 0.09, green: 0.14, blue: 0.18, alpha: 1)
        static let subtext = NSColor(srgbRed: 0.28, green: 0.35, blue: 0.41, alpha: 1)
        static let panelFill = NSColor.white.withAlphaComponent(0.95)
        static let panelStroke = NSColor(srgbRed: 0.70, green: 0.80, blue: 0.87, alpha: 1)
        static let titleFont = NSFont(name: "Avenir Next Demi Bold", size: 26) ?? .systemFont(ofSize: 26, weight: .semibold)
        static let subtitleFont = NSFont(name: "Avenir Next Regular", size: 14) ?? .systemFont(ofSize: 14)
    }

    override func draw(_ dirtyRect: NSRect) {
        let bg = NSBezierPath(roundedRect: bounds, xRadius: 24, yRadius: 24)
        C.background.setFill()
        bg.fill()

        NSGradient(starting: C.header, ending: C.background)?.draw(in: NSRect(x: 0, y: 248, width: bounds.width, height: 112), angle: -90)
        drawText("Drag LookInside to Applications", font: C.titleFont, color: C.text, in: NSRect(x: 56, y: 286, width: 508, height: 34))
        drawText("Install the macOS UI inspector by dragging it onto the Applications shortcut", font: C.subtitleFont, color: C.subtext, in: NSRect(x: 50, y: 242, width: 520, height: 24))
        drawPanel(NSRect(x: 58, y: 72, width: 192, height: 168))
        drawPanel(NSRect(x: 370, y: 72, width: 192, height: 168))

        let arrowBody = NSBezierPath()
        arrowBody.move(to: NSPoint(x: 254, y: 156))
        arrowBody.line(to: NSPoint(x: 338, y: 156))
        C.accent.setStroke()
        arrowBody.lineWidth = 14
        arrowBody.stroke()

        let arrowHead = NSBezierPath()
        arrowHead.move(to: NSPoint(x: 326, y: 178))
        arrowHead.line(to: NSPoint(x: 364, y: 156))
        arrowHead.line(to: NSPoint(x: 326, y: 134))
        arrowHead.close()
        C.accent.setFill()
        arrowHead.fill()
    }

    private func drawPanel(_ rect: NSRect) {
        let panel = NSBezierPath(roundedRect: rect, xRadius: 26, yRadius: 26)
        C.panelFill.setFill()
        panel.fill()
        C.panelStroke.setStroke()
        panel.lineWidth = 2
        panel.stroke()
    }

    private func drawText(_ text: String, font: NSFont, color: NSColor, in rect: NSRect) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: paragraph]
        (text as NSString).draw(in: rect, withAttributes: attrs)
    }
}

let frame = NSRect(x: 0, y: 0, width: 620, height: 360)
let view = BackgroundView(frame: frame)
guard let rep = view.bitmapImageRepForCachingDisplay(in: frame) else {
    fputs("Error: Could not create bitmap rep\n", stderr)
    exit(1)
}
view.cacheDisplay(in: frame, to: rep)
guard let data = rep.representation(using: .png, properties: [:]) else {
    fputs("Error: Could not generate PNG data\n", stderr)
    exit(1)
}
try data.write(to: URL(fileURLWithPath: outputPath))
SWIFT
}

create_pretty_dmg() {
	local dmg_path="$1"
	local volume_name="$2"
	local staging_dir="$DMG_WORK_DIR/staging"
	local background_dir="$staging_dir/.background"
	local background_path="$background_dir/installer-background.png"
	local rw_dmg_path="$DMG_WORK_DIR/${volume_name}.temp.dmg"
	local device
	local attach_output
	local mounted_volume_path
	local mounted_volume_name

	rm -rf "$DMG_WORK_DIR"
	mkdir -p "$staging_dir" "$background_dir"
	ditto "$APP_PATH" "$staging_dir/$APP_PRODUCT_NAME"
	ln -s /Applications "$staging_dir/Applications"
	generate_dmg_background "$background_path"
	chflags hidden "$background_dir" 2>/dev/null || true

	hdiutil create -volname "$volume_name" \
		-srcfolder "$staging_dir" \
		-fs HFS+ \
		-fsargs "-c c=64,a=16,e=16" \
		-ov -format UDRW \
		"$rw_dmg_path"

	attach_output="$(hdiutil attach -readwrite -noverify -noautoopen "$rw_dmg_path")"
	device="$(printf '%s\n' "$attach_output" | awk -F '\t' '/\/Volumes\// {print $1; exit}')"
	mounted_volume_path="$(printf '%s\n' "$attach_output" | awk -F '\t' '/\/Volumes\// {print $NF; exit}')"
	mounted_volume_name="$(basename "$mounted_volume_path")"

	if [[ -z "$device" || -z "$mounted_volume_name" ]]; then
		echo "$attach_output" >&2
		fail "Unable to mount temporary DMG."
	fi

	osascript <<EOF
tell application "Finder"
    tell disk "$mounted_volume_name"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {220, 120, 840, 520}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 96
        set text size of viewOptions to 13
        set background picture of viewOptions to file ".background:installer-background.png"
        set position of every item of container window to {760, 40}
        set position of item "$APP_PRODUCT_NAME" of container window to {154, 160}
        set position of item "Applications" of container window to {466, 160}
        close
        open
        update without registering applications
        delay 1
        set bounds of container window to {220, 120, 830, 510}
        delay 1
        set bounds of container window to {220, 120, 840, 520}
        delay 2
    end tell
end tell
EOF

	if [[ -e "$mounted_volume_path/.fseventsd" ]]; then
		chflags hidden "$mounted_volume_path/.fseventsd" 2>/dev/null || true
	fi

	sync
	sleep 1
	hdiutil detach "$mounted_volume_path" || hdiutil detach "$device" -force
	hdiutil convert "$rw_dmg_path" -format UDZO -imagekey zlib-level=9 -o "$dmg_path"
	rm -rf "$DMG_WORK_DIR"
}

notarize_dmg() {
	local dmg_path="$1"
	local notary_output

	if [[ "$SKIP_NOTARIZE" == "true" ]]; then
		log "Skipping notarization"
		return
	fi

	log "Submitting DMG for notarization with keychain profile: $KEYCHAIN_PROFILE"
	notary_output="$(xcrun notarytool submit "$dmg_path" --keychain-profile "$KEYCHAIN_PROFILE" --wait 2>&1)" || {
		echo "$notary_output" >&2
		return 1
	}
	echo "$notary_output"

	if ! grep -q "status: Accepted" <<<"$notary_output"; then
		echo "$notary_output" >&2
		fail "DMG notarization was not accepted."
	fi

	log "Stapling notarization ticket"
	xcrun stapler staple "$dmg_path"
	xcrun stapler validate "$dmg_path"
}

main() {
	parse_args "$@"
	require_command xcodebuild
	require_command swift
	require_command security
	require_command codesign
	require_command xcrun
	require_command ditto
	require_command hdiutil
	require_command osascript
	require_command file
	require_command awk

	cd "$PROJECT_ROOT"
	note_release_prerequisites
	load_build_settings
	detect_signing_identity

	log "Bundle identifier: $BUNDLE_IDENTIFIER"
	log "App product: $APP_PRODUCT_NAME"
	log "Version: $MARKETING_VERSION ($CURRENT_PROJECT_VERSION)"
	log "Signing identity: $SIGNING_IDENTITY"

	build_app_unsigned
	verify_bundle_identifier
	sign_app_bundle

	mkdir -p "$DMG_OUTPUT_DIR"
	local dmg_name="LookInside_V_${MARKETING_VERSION}.dmg"
	local dmg_path="$DMG_OUTPUT_DIR/$dmg_name"
	local volume_name="LookInside V$MARKETING_VERSION"
	rm -f "$dmg_path"

	log "Creating DMG: ${dmg_path#$PROJECT_ROOT/}"
	create_pretty_dmg "$dmg_path" "$volume_name"
	notarize_dmg "$dmg_path"

	log "DMG ready: $dmg_path"
}

main "$@"
