#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="${TMPDIR:-/tmp}/lookinside-security-tests.$$"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

POLICY="$ROOT/LookInside/SwiftUISupport/LKSwiftUISupportAuthServerPathPolicy.swift"
PATH_POLICY_TEST="$ROOT/Tests/Security/LKSwiftUISupportAuthServerPathPolicyTests.swift"
LOCAL_LICENSE_PROBE="$ROOT/LookInside/SwiftUISupport/LKSwiftUISupportLocalLicenseProbe.swift"
LOCAL_LICENSE_PROBE_TEST="$ROOT/Tests/Security/LKSwiftUISupportLocalLicenseProbeTests.swift"
INSTALLER="$ROOT/LookInside/SwiftUISupport/LKSwiftUISupportInstaller.swift"
LOGGER="$ROOT/LookInside/SwiftUISupport/LKSwiftUISupportLogger.swift"
INSTALLER_CANCELLATION_TEST="$ROOT/Tests/Security/LKSwiftUISupportInstallerCancellationTests.swift"

swiftc -parse-as-library "$POLICY" "$PATH_POLICY_TEST" -o "$TMPDIR/path-policy-release"
"$TMPDIR/path-policy-release"

swiftc -D DEBUG -parse-as-library "$POLICY" "$PATH_POLICY_TEST" -o "$TMPDIR/path-policy-debug"
"$TMPDIR/path-policy-debug"

swiftc -parse-as-library "$LOCAL_LICENSE_PROBE" "$LOCAL_LICENSE_PROBE_TEST" -o "$TMPDIR/local-license-probe-test"
"$TMPDIR/local-license-probe-test" "$TMPDIR"

swiftc -parse-as-library "$LOGGER" "$INSTALLER" "$INSTALLER_CANCELLATION_TEST" -o "$TMPDIR/installer-cancellation-test"
"$TMPDIR/installer-cancellation-test"

echo "Security gate tests passed"
