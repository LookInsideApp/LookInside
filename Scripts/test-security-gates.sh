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
COMMON_INSTALLER_ARCHIVE="$ROOT/LookInside/Common/Installer/LKInstallerArchiveExtractor.swift"
COMMON_INSTALLER_CANCELLATION="$ROOT/LookInside/Common/Installer/LKInstallerCancellation.swift"
COMMON_INSTALLER_CODE_SIGNATURE="$ROOT/LookInside/Common/Installer/LKInstallerCodeSignature.swift"
COMMON_INSTALLER_DOWNLOADER="$ROOT/LookInside/Common/Installer/LKInstallerDownloader.swift"
COMMON_INSTALLER_FILESYSTEM="$ROOT/LookInside/Common/Installer/LKInstallerFilesystem.swift"
COMMON_INSTALLER_LOGGER="$ROOT/LookInside/Common/Installer/LKInstallerLogger.swift"
COMMON_INSTALLER_PROGRESS="$ROOT/LookInside/Common/Installer/LKInstallerProgressWindowController.swift"
INSTALLER_CANCELLATION_TEST="$ROOT/Tests/Security/LKSwiftUISupportInstallerCancellationTests.swift"
INJECTION_START_GATE="$ROOT/LookInside/Injection/LKInjectionStartGate.swift"
INJECTION_START_GATE_TEST="$ROOT/Tests/Security/LKInjectionStartGateTests.swift"

swiftc -parse-as-library "$POLICY" "$PATH_POLICY_TEST" -o "$TMPDIR/path-policy-release"
"$TMPDIR/path-policy-release"

swiftc -D DEBUG -parse-as-library "$POLICY" "$PATH_POLICY_TEST" -o "$TMPDIR/path-policy-debug"
"$TMPDIR/path-policy-debug"

swiftc -parse-as-library "$LOCAL_LICENSE_PROBE" "$LOCAL_LICENSE_PROBE_TEST" -o "$TMPDIR/local-license-probe-test"
"$TMPDIR/local-license-probe-test" "$TMPDIR"

swiftc -parse-as-library \
	"$LOGGER" \
	"$COMMON_INSTALLER_LOGGER" \
	"$COMMON_INSTALLER_CANCELLATION" \
	"$COMMON_INSTALLER_ARCHIVE" \
	"$COMMON_INSTALLER_CODE_SIGNATURE" \
	"$COMMON_INSTALLER_DOWNLOADER" \
	"$COMMON_INSTALLER_FILESYSTEM" \
	"$COMMON_INSTALLER_PROGRESS" \
	"$INSTALLER" \
	"$INSTALLER_CANCELLATION_TEST" \
	-o "$TMPDIR/installer-cancellation-test"
"$TMPDIR/installer-cancellation-test"

swiftc -parse-as-library "$INJECTION_START_GATE" "$INJECTION_START_GATE_TEST" -o "$TMPDIR/injection-start-gate-test"
"$TMPDIR/injection-start-gate-test"

echo "Security gate tests passed"
