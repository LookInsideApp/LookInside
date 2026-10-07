#!/bin/bash

set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workflow_path="$root_dir/.github/workflows/release.yml"
xcconfig_writer="$root_dir/Scripts/write-github-action-xcconfig.sh"

if grep -n $'\t' "$workflow_path" >/dev/null; then
	echo "workflow contains tab indentation" >&2
	exit 1
fi

assert_contains() {
	local needle="$1"
	grep -F -- "$needle" "$workflow_path" >/dev/null
}

assert_absent() {
	local needle="$1"
	if grep -F -- "$needle" "$workflow_path" >/dev/null; then
		echo "unexpected release workflow text: $needle" >&2
		exit 1
	fi
}

assert_contains "parent-app-release"
assert_contains 'run-name: ${{ github.event.client_payload.release_id }}'
assert_contains 'SOURCE_REF="${{ github.event.client_payload.source_ref }}"'
assert_contains 'BUILD_NUMBER="${{ github.event.client_payload.build_number }}"'
assert_contains 'INJECTOR_REF="${{ github.event.client_payload.injector_ref }}"'
assert_contains 'RELEASE_REF="${{ github.event.client_payload.release_ref }}"'
assert_contains 'ref: ${{ needs.prepare.outputs.source_ref }}'
assert_contains 'checkout --detach "${{ needs.prepare.outputs.injector_ref }}"'
assert_absent 'LookInside-MCP'
assert_contains 'token: ${{ secrets.LOOKINSIDE_WEB_RELEASE_TOKEN }}'
assert_contains 'target_commitish: ${{ needs.prepare.outputs.source_ref }}'
assert_contains 'if existing_target="$(gh api'
assert_contains 'sparse-checkout: sparkle'
assert_contains 'bash Scripts/run-gitleaks.sh .'
assert_contains 'bash Scripts/scan-private-keys.sh'
assert_contains 'bash app/Scripts/scan-private-keys.sh dist'
assert_contains 'bash app/Scripts/scan-private-keys.sh web/public'
assert_contains 'bash Scripts/check-host-release-clean.sh --release-strict'
assert_absent 'check-host-release-clean.sh --local-build'
assert_absent 'sync-auth-server-assets-to-web.sh'
assert_absent 'public/downloads/auth-server'
assert_absent 'lookinside-auth-server'
assert_absent 'release-tools'
assert_contains 'Using parent-resolved Xcode version ${VERSION} (${BUILD_NUMBER}).'
assert_contains 'without leading zeroes'
assert_absent "workflow_dispatch:"
assert_absent "tags:"
assert_absent '2>/dev/null || true'
assert_absent 'APPCAST_URL="https://lookinside-app.com/appcast.xml"'

for workflow in "$root_dir"/.github/workflows/*.yml; do
	if grep -F -- 'SECRETS_SOURCE_REPO' "$workflow" >/dev/null &&
		! grep -F -- 'sparse-checkout: sparkle' "$workflow" >/dev/null; then
		echo "$(basename "$workflow") checks out the secrets repository without sparse-checkout: sparkle" >&2
		exit 1
	fi
done

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/lookinside-host-release-test.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
OUTPUT_PATH="$work_dir/release.xcconfig" bash "$xcconfig_writer" --version 2.3.13 --build-number 46 >/dev/null
grep -F 'MARKETING_VERSION = 2.3.13' "$work_dir/release.xcconfig" >/dev/null
grep -F 'CURRENT_PROJECT_VERSION = 46' "$work_dir/release.xcconfig" >/dev/null
OUTPUT_PATH="$work_dir/internal.xcconfig" bash "$xcconfig_writer" --version 2.3.12 --build-number 45.1.7 >/dev/null
grep -F 'MARKETING_VERSION = 2.3.12' "$work_dir/internal.xcconfig" >/dev/null
grep -F 'CURRENT_PROJECT_VERSION = 45.1.7' "$work_dir/internal.xcconfig" >/dev/null
if OUTPUT_PATH="$work_dir/invalid.xcconfig" bash "$xcconfig_writer" --version 02.3.13 --build-number 46 >/dev/null 2>&1; then
	echo "non-canonical Xcode version unexpectedly passed" >&2
	exit 1
fi
if OUTPUT_PATH="$work_dir/invalid-build.xcconfig" bash "$xcconfig_writer" --version 2.3.13 --build-number 45.100.1 >/dev/null 2>&1; then
	echo "oversized Xcode build component unexpectedly passed" >&2
	exit 1
fi

echo "host release workflow tests passed"
