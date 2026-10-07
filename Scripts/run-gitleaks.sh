#!/bin/bash
# Scans a Git repository's history for secrets with a pinned gitleaks release.
#
# Usage: bash Scripts/run-gitleaks.sh [--config <gitleaks.toml>] [<repository dir>]
#
# The release archive is downloaded from GitHub and checked against the
# SHA-256 pinned below before it runs. Findings are redacted in the output.
# Check out the repository with full history (fetch-depth: 0) to scan every
# commit.
#
# Where the rules come from: --config, or by default the .gitleaks.toml at
# the root of the repository that holds this script (gitleaks' built-in rules
# when there is none). A .gitleaks.toml or GITLEAKS_CONFIG* setting from the
# scanned repository is never read, gitleaks runs on the repository's Git
# directory so a .gitleaksignore in its working tree is not read, and inline
# gitleaks:allow comments are ignored.
#
# That keeps the scanned repository from relaxing the scan only when this
# script and its config come from a separate, trusted checkout, as in the
# monorepo's internal-snapshot workflow. When a repository runs its own copy
# in its own CI, the script and the default config are that repository's own
# committed files, so a commit can change the rules it is scanned with.
# Exemptions belong in the trusted .gitleaks.toml, matched as exactly as
# possible (commit and path).
#
# Exit status: 0 clean, 1 secrets found, other values on setup errors.
#
# This script is kept identical in every repository that publishes artifacts.

set -euo pipefail

GITLEAKS_VERSION="8.30.1"

usage() {
	sed -n '2,28p' "$0" >&2
	exit 2
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config=""
repository=""
while [[ $# -gt 0 ]]; do
	case "$1" in
	--config)
		[[ $# -ge 2 && -n "$2" ]] || usage
		config="$2"
		shift 2
		;;
	-h | --help) usage ;;
	-*)
		echo "Unknown option: $1" >&2
		usage
		;;
	*)
		[[ -z "$repository" ]] || usage
		repository="$1"
		shift
		;;
	esac
done
repository="${repository:-.}"

[[ -d "$repository" ]] || {
	echo "Repository directory not found: $repository" >&2
	exit 2
}
git_dir="$(git -C "$repository" rev-parse --absolute-git-dir)" || {
	echo "Not a Git repository: $repository" >&2
	exit 2
}

if [[ -n "$config" ]]; then
	[[ -f "$config" ]] || {
		echo "gitleaks config not found: $config" >&2
		exit 2
	}
elif [[ -f "$script_dir/../.gitleaks.toml" ]]; then
	config="$script_dir/../.gitleaks.toml"
fi

case "$(uname -s)-$(uname -m)" in
Darwin-arm64)
	platform="darwin_arm64"
	checksum="b40ab0ae55c505963e365f271a8d3846efbc170aa17f2607f13df610a9aeb6a5"
	;;
Darwin-x86_64)
	platform="darwin_x64"
	checksum="dfe101a4db2255fc85120ac7f3d25e4342c3c20cf749f2c20a18081af1952709"
	;;
Linux-x86_64)
	platform="linux_x64"
	checksum="551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb"
	;;
Linux-aarch64 | Linux-arm64)
	platform="linux_arm64"
	checksum="e4a487ee7ccd7d3a7f7ec08657610aa3606637dab924210b3aee62570fb4b080"
	;;
*)
	echo "No pinned gitleaks build for $(uname -s)-$(uname -m)." >&2
	exit 2
	;;
esac

work_dir="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/gitleaks.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

if [[ -z "$config" ]]; then
	config="$work_dir/default.gitleaks.toml"
	printf '[extend]\nuseDefault = true\n' >"$config"
fi
mkdir "$work_dir/no-ignore-file"

archive="$work_dir/gitleaks.tar.gz"
curl -fsSL --retry 3 -o "$archive" \
	"https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_${platform}.tar.gz"

if command -v sha256sum >/dev/null 2>&1; then
	actual="$(sha256sum "$archive" | awk '{print $1}')"
else
	actual="$(shasum -a 256 "$archive" | awk '{print $1}')"
fi
[[ "$actual" == "$checksum" ]] || {
	echo "gitleaks archive checksum mismatch: expected $checksum, got $actual" >&2
	exit 2
}

tar -xzf "$archive" -C "$work_dir" gitleaks
"$work_dir/gitleaks" version
echo "gitleaks config: $config"

env -u GITLEAKS_CONFIG -u GITLEAKS_CONFIG_TOML \
	"$work_dir/gitleaks" git \
	--no-banner \
	--redact \
	--exit-code 1 \
	--config "$config" \
	--gitleaks-ignore-path "$work_dir/no-ignore-file" \
	--ignore-gitleaks-allow \
	"$git_dir"
