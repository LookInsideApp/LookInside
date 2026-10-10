#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="${TMPDIR:-/tmp}/lookinside-security-tests.$$"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

INJECTION_START_GATE="$ROOT/LookInside/Injection/InjectionStartGate.swift"
INJECTION_START_GATE_TEST="$ROOT/Tests/Security/InjectionStartGateTests.swift"

swiftc -parse-as-library "$INJECTION_START_GATE" "$INJECTION_START_GATE_TEST" -o "$TMPDIR/injection-start-gate-test"
"$TMPDIR/injection-start-gate-test"

echo "Security gate tests passed"
