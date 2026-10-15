#!/bin/bash
# Tests check-host-release-clean.sh with throwaway app bundles built for this
# run only.
#
# The DEBUG-only end-to-end dump and UI snapshots in LookInside/DebugE2E/ are
# Swift types without Objective-C names, so the check recognises them by their
# Swift type names. For every file there, a bundle whose binary declares that
# file's file-scope types must fail the check, with its symbol table and
# without it. Renaming one of those types without updating the check fails
# this test. A bundle declaring ordinary host types must pass.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
check="$script_dir/check-host-release-clean.sh"
debug_sources="$script_dir/../LookInside/DebugE2E"

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/check-host-release-clean-test.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

failures=0

# The file-scope types a DebugE2E file declares. Its code sits inside
# `#if DEBUG`, one level in, so nested types are indented further.
file_scope_types() {
	sed -n -E 's/^( {4})?((public|internal|fileprivate|private) )?(final )?(class|enum|struct|actor) ([A-Za-z_][A-Za-z0-9_]*).*/\6/p' "$1" |
		grep -v -x -E 'func|var|let|override|static|final|public|internal|fileprivate|private' || true
}

# Builds <bundle>/LookInside.app around a binary of module LookInside, the
# host's module name, that declares the given types and uses them.
make_bundle() {
	local bundle="$1"
	shift
	local source="$work_dir/$bundle.swift"
	local executable="$work_dir/$bundle/LookInside.app/Contents/MacOS/LookInside"
	mkdir -p "$(dirname "$executable")"
	{
		local type_name
		for type_name in "$@"; do
			echo "final class $type_name {}"
		done
		echo "print([$(printf '%s.self, ' "$@")] as [AnyObject.Type])"
	} >"$source"
	swiftc -module-name LookInside -module-cache-path "$work_dir/ModuleCache" "$source" -o "$executable"
}

# Copies a bundle and strips its binary's symbol table, as a Release build does.
make_stripped_copy() {
	local bundle="$1" copy="$2"
	cp -R "$work_dir/$bundle" "$work_dir/$copy"
	strip "$work_dir/$copy/LookInside.app/Contents/MacOS/LookInside" 2>/dev/null
}

run_check() {
	local status=0
	bash "$check" --local-build "$work_dir/$1" >"$work_dir/output" 2>&1 || status=$?
	return "$status"
}

expect_rejected() {
	local label="$1" bundle="$2"
	local status=0
	run_check "$bundle" || status=$?
	if [ "$status" -ne 1 ]; then
		echo "FAIL ($label): expected exit status 1 for DEBUG-only types, got $status" >&2
		cat "$work_dir/output" >&2
		failures=$((failures + 1))
		return
	fi
	echo "ok - $label"
}

expect_clean() {
	local label="$1" bundle="$2"
	local status=0
	run_check "$bundle" || status=$?
	if [ "$status" -ne 0 ]; then
		echo "FAIL ($label): expected exit status 0, got $status" >&2
		cat "$work_dir/output" >&2
		failures=$((failures + 1))
		return
	fi
	echo "ok - $label"
}

checked_files=0
for source_file in "$debug_sources"/*.swift; do
	file_name="$(basename "$source_file" .swift)"
	types=()
	while IFS= read -r type_name; do
		types+=("$type_name")
	done < <(file_scope_types "$source_file")
	if [ "${#types[@]}" -eq 0 ]; then
		echo "skip - $file_name.swift declares no file-scope type"
		continue
	fi
	make_bundle "$file_name" "${types[@]}"
	expect_rejected "$file_name.swift (${types[*]})" "$file_name"
	make_stripped_copy "$file_name" "$file_name-stripped"
	expect_rejected "$file_name.swift, stripped (${types[*]})" "$file_name-stripped"
	checked_files=$((checked_files + 1))
done

if [ "$checked_files" -eq 0 ]; then
	echo "FAIL: found no DebugE2E file to build a bundle from in $debug_sources" >&2
	failures=$((failures + 1))
fi

make_bundle "Ordinary" AppDelegate HierarchyDataSource StaticWindowController
expect_clean "ordinary host types" "Ordinary"
make_stripped_copy "Ordinary" "Ordinary-stripped"
expect_clean "ordinary host types, stripped" "Ordinary-stripped"

if [ "$failures" -gt 0 ]; then
	echo "$failures check-host-release-clean test(s) failed" >&2
	exit 1
fi
echo "check-host-release-clean tests passed"
