#!/bin/bash
# Tests scan-private-keys.sh with throwaway keys generated for this run only.
#
# This script is kept identical in every repository that publishes artifacts.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scanner="$script_dir/scan-private-keys.sh"

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/scan-private-keys-test.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
umask 077

keys="$work_dir/keys"
mkdir -p "$keys"
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$keys/pkcs8.pem" 2>/dev/null
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$keys/ec-pkcs8.pem" 2>/dev/null
openssl pkey -in "$keys/ec-pkcs8.pem" -traditional -out "$keys/ec.pem" 2>/dev/null
openssl pkcs8 -topk8 -in "$keys/pkcs8.pem" -passout pass:throwaway -out "$keys/encrypted.pem" 2>/dev/null
openssl pkey -in "$keys/pkcs8.pem" -pubout -out "$keys/public.pem" 2>/dev/null
openssl req -new -x509 -key "$keys/pkcs8.pem" -subj "/CN=scan-test" -days 1 -out "$keys/cert.pem" 2>/dev/null
ssh-keygen -q -t ed25519 -N "" -C scan-test -f "$keys/openssh" >/dev/null
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out "$keys/rsa4096.pem" 2>/dev/null
openssl genpkey -algorithm ED25519 -out "$keys/ed25519.pem" 2>/dev/null
# DER forms of the same keys, as an app or a script could embed them.
openssl pkcs8 -topk8 -nocrypt -in "$keys/pkcs8.pem" -outform DER -out "$keys/pkcs8.der" 2>/dev/null
openssl pkey -in "$keys/pkcs8.pem" -traditional -outform DER -out "$keys/pkcs1.der" 2>/dev/null
openssl pkcs8 -topk8 -nocrypt -in "$keys/ec-pkcs8.pem" -outform DER -out "$keys/ec-pkcs8.der" 2>/dev/null
openssl pkey -in "$keys/ec-pkcs8.pem" -traditional -outform DER -out "$keys/ec.der" 2>/dev/null
openssl pkey -in "$keys/ed25519.pem" -outform DER -out "$keys/ed25519.der" 2>/dev/null
openssl pkcs8 -topk8 -nocrypt -in "$keys/rsa4096.pem" -outform DER -out "$keys/rsa4096.der" 2>/dev/null
openssl pkcs8 -topk8 -in "$keys/pkcs8.pem" -passout pass:throwaway -outform DER -out "$keys/encrypted.der" 2>/dev/null
openssl pkey -in "$keys/pkcs8.pem" -pubout -outform DER -out "$keys/public.der" 2>/dev/null
openssl x509 -in "$keys/cert.pem" -outform DER -out "$keys/cert.der" 2>/dev/null

# Base64 helpers: the body of a PEM file, a DER file on one line, and "/"
# escaped as "\/" the way JSON encoders may write it.
pem_body() { grep -v -- '-----' "$1" | tr -d '\n'; }
der_base64() { openssl base64 -A -in "$1"; }
json_slashes() { sed 's#/#\\/#g'; }

failures=0

expect_clean() {
	local label="$1"
	shift
	if ! bash "$scanner" "$@" >/dev/null 2>"$work_dir/stderr"; then
		echo "FAIL ($label): clean input was rejected" >&2
		cat "$work_dir/stderr" >&2
		failures=$((failures + 1))
		return
	fi
	echo "ok - $label"
}

expect_hit() {
	local label="$1"
	local needle="$2"
	shift 2
	if bash "$scanner" "$@" >/dev/null 2>"$work_dir/stderr"; then
		echo "FAIL ($label): private key was not detected" >&2
		failures=$((failures + 1))
		return
	fi
	if ! grep -F -- "$needle" "$work_dir/stderr" >/dev/null; then
		echo "FAIL ($label): report does not name $needle" >&2
		cat "$work_dir/stderr" >&2
		failures=$((failures + 1))
		return
	fi
	if grep -E '[A-Za-z0-9+/]{40}' "$work_dir/stderr" >/dev/null; then
		echo "FAIL ($label): report leaks key material" >&2
		failures=$((failures + 1))
		return
	fi
	echo "ok - $label"
}

make_zip() {
	local output="$1"
	local source="$2"
	(cd "$(dirname "$source")" && python3 -m zipfile -c "$output" "$(basename "$source")")
}

# A clean product: a bundle with a binary, a public key, a certificate, and
# source that only names PEM headers.
clean="$work_dir/clean"
mkdir -p "$clean/Clean.app/Contents/MacOS" "$clean/Clean.app/Contents/Resources"
head -c 65536 /dev/urandom >"$clean/Clean.app/Contents/MacOS/Clean"
cp "$keys/public.pem" "$keys/cert.pem" "$clean/Clean.app/Contents/Resources/"
cat >"$clean/pem.js" <<'JS'
const header = "-----BEGIN " + type + "-----";
if (line === "-----BEGIN RSA PRIVATE KEY-----") { parsePrivateKey(); }
const label = "-----BEGIN PRIVATE KEY-----\n";
JS
# DER and base64 certificates and public keys are not private keys, and a
# key's well-known base64 prefix alone (as in documentation) is not a key.
cp "$keys/public.der" "$keys/cert.der" "$clean/Clean.app/Contents/Resources/"
{
	head -c 4096 /dev/urandom
	cat "$keys/cert.der" "$keys/public.der"
	head -c 4096 /dev/urandom
} >"$clean/Clean.app/Contents/MacOS/Helper"
printf '{"certificate":"%s","publicKey":"%s"}\n' \
	"$(der_base64 "$keys/cert.der" | json_slashes)" \
	"$(der_base64 "$keys/public.der" | json_slashes)" >"$clean/Clean.app/Contents/Resources/keys.json"
printf 'RSA PKCS#8 keys start with %s, PKCS#1 keys with %s.\n' \
	"$(der_base64 "$keys/pkcs8.der" | cut -c1-48)" \
	"$(der_base64 "$keys/pkcs1.der" | cut -c1-24)" >"$clean/notes.md"
ln -s Contents/MacOS/Clean "$clean/Clean.app/link"
make_zip "$work_dir/clean.zip" "$clean/Clean.app"
tar -czf "$work_dir/clean.tar.gz" -C "$clean" Clean.app
expect_clean "clean directory passes" "$clean"
expect_clean "clean zip and tar.gz pass" "$work_dir/clean.zip" "$work_dir/clean.tar.gz"

# A plain PEM file in a directory.
plain="$work_dir/plain"
mkdir -p "$plain/nested"
cp "$keys/pkcs8.pem" "$plain/nested/server.pem"
expect_hit "plain PKCS#8 key in a directory" "BEGIN PRIVATE KEY" "$plain"

# A throwaway key inside a zip, under a harmless name.
zipped="$work_dir/zipped"
mkdir -p "$zipped/Payload.app"
cp "$keys/ec.pem" "$zipped/Payload.app/config.bin"
make_zip "$work_dir/app.zip" "$zipped/Payload.app"
expect_hit "EC key inside a zip" "app.zip!Payload.app/config.bin: BEGIN EC PRIVATE KEY" "$work_dir/app.zip"

# An encrypted key inside an xcframework, zipped, then nested in a tar.gz.
xcf="$work_dir/xcf"
mkdir -p "$xcf/Kit.xcframework/macos-arm64/Kit.framework/Resources"
cp "$keys/encrypted.pem" "$xcf/Kit.xcframework/macos-arm64/Kit.framework/Resources/data"
make_zip "$work_dir/Kit.xcframework.zip" "$xcf/Kit.xcframework"
mkdir -p "$work_dir/outer"
cp "$work_dir/Kit.xcframework.zip" "$work_dir/outer/"
tar -czf "$work_dir/release.tar.gz" -C "$work_dir/outer" Kit.xcframework.zip
expect_hit "encrypted key in an xcframework directory" "BEGIN ENCRYPTED PRIVATE KEY" "$xcf"
expect_hit "encrypted key in a zip nested in a tar.gz" \
	"release.tar.gz!Kit.xcframework.zip!Kit.xcframework/macos-arm64/Kit.framework/Resources/data" \
	"$work_dir/release.tar.gz"

# An OpenSSH key in a gzip file.
gzip -c "$keys/openssh" >"$work_dir/blob.gz"
expect_hit "OpenSSH key in a gzip file" "BEGIN OPENSSH PRIVATE KEY" "$work_dir/blob.gz"

# A key embedded in a JavaScript bundle as a string with \n escapes.
bundle="$work_dir/bundle"
mkdir -p "$bundle"
python3 - "$keys/pkcs8.pem" >"$bundle/worker.js" <<'PY'
import json
import sys

pem = open(sys.argv[1]).read()
print("var a=1;var key=" + json.dumps(pem) + ";export default key;")
PY
expect_hit "escaped key in a JavaScript bundle" "worker.js: BEGIN PRIVATE KEY" "$bundle"

# A key inside a binary file next to other bytes.
binary="$work_dir/binary"
mkdir -p "$binary"
{
	head -c 4096 /dev/urandom
	cat "$keys/pkcs8.pem"
	head -c 4096 /dev/urandom
} >"$binary/Host"
expect_hit "key embedded in a binary" "BEGIN PRIVATE KEY" "$binary"

# Raw DER keys with no PEM header, inside a binary or as a file.
embed_der() {
	local der="$1"
	local output="$2"
	mkdir -p "$(dirname "$output")"
	{
		head -c 4096 /dev/urandom
		cat "$der"
		head -c 4096 /dev/urandom
	} >"$output"
}
der="$work_dir/der"
embed_der "$keys/pkcs8.der" "$der/pkcs8/Host"
expect_hit "DER PKCS#8 RSA key in a binary" "Host: PKCS#8 RSA private key (DER)" "$der/pkcs8"
embed_der "$keys/pkcs1.der" "$der/pkcs1/Host"
expect_hit "DER PKCS#1 RSA key in a binary" "Host: PKCS#1 RSA private key (DER)" "$der/pkcs1"
embed_der "$keys/ec.der" "$der/sec1/Host"
expect_hit "DER SEC1 EC key in a binary" "Host: SEC1 EC private key (DER)" "$der/sec1"
embed_der "$keys/ec-pkcs8.der" "$der/ec-pkcs8/Host"
expect_hit "DER PKCS#8 EC key in a binary" "Host: PKCS#8 EC private key (DER)" "$der/ec-pkcs8"
embed_der "$keys/ed25519.der" "$der/ed25519/Host"
expect_hit "DER PKCS#8 Ed25519 key in a binary" "Host: PKCS#8 Ed25519 private key (DER)" "$der/ed25519"
embed_der "$keys/encrypted.der" "$der/encrypted/Host"
expect_hit "DER encrypted PKCS#8 key in a binary" "Host: encrypted PKCS#8 private key (DER)" "$der/encrypted"
cp "$keys/rsa4096.der" "$der/key.der"
make_zip "$work_dir/der.zip" "$der/key.der"
expect_hit "DER RSA-4096 key file inside a zip" "der.zip!key.der: PKCS#8 RSA private key (DER)" "$work_dir/der.zip"

# Base64 keys with no PEM header: one line, wrapped, indented, JSON-escaped.
b64="$work_dir/base64"
mkdir -p "$b64"
printf 'let key = "%s"\n' "$(der_base64 "$keys/rsa4096.der")" >"$b64/Key.swift"
expect_hit "one-line base64 RSA-4096 key in source" "Key.swift: PKCS#8 RSA private key (base64)" "$b64/Key.swift"
printf '{"key":"%s"}\n' "$(der_base64 "$keys/pkcs1.der" | fold -w 64 | json_slashes | awk '{ printf "%s\\n", $0 }')" >"$b64/config.json"
expect_hit "wrapped base64 PKCS#1 key with JSON escapes" "config.json: PKCS#1 RSA private key (base64)" "$b64/config.json"
{
	printf '<dict>\n\t<key>Key</key>\n\t<data>\n'
	der_base64 "$keys/ec.der" | fold -w 36 | sed 's/^/\t\t/'
	printf '\t</data>\n</dict>\n'
} >"$b64/Info.plist"
expect_hit "indented base64 SEC1 EC key in a plist" "Info.plist: SEC1 EC private key (base64)" "$b64/Info.plist"
printf 'export const k = "%s";\n' "$(der_base64 "$keys/ed25519.der")" >"$b64/ed.js"
expect_hit "base64 Ed25519 key in a script" "ed.js: PKCS#8 Ed25519 private key (base64)" "$b64/ed.js"
printf 'k=%s\n' "$(der_base64 "$keys/encrypted.der")" >"$b64/encrypted.env"
expect_hit "base64 encrypted PKCS#8 key" "encrypted.env: encrypted PKCS#8 private key (base64)" "$b64/encrypted.env"
printf 'ssh=%s\n' "$(pem_body "$keys/openssh")" >"$b64/ssh.env"
expect_hit "base64 OpenSSH key body" "ssh.env: OpenSSH private key (base64)" "$b64/ssh.env"
mkdir -p "$work_dir/openssh-binary"
{
	head -c 1024 /dev/urandom
	pem_body "$keys/openssh" | openssl base64 -d -A
	head -c 1024 /dev/urandom
} >"$work_dir/openssh-binary/blob"
expect_hit "binary OpenSSH key body" "blob: OpenSSH private key (binary)" "$work_dir/openssh-binary"

# A PEM key in JSON with "/" written as "\/" inside the first 40 data
# characters. EC keys are cheap, so generate until one has a "/" there.
first_data_has_slash() { sed -n 2p "$1" | cut -c1-40 | grep -q /; }
for _ in $(seq 1 200); do
	openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 2>/dev/null |
		openssl pkey -traditional -out "$keys/slash.pem" 2>/dev/null
	if first_data_has_slash "$keys/slash.pem"; then
		break
	fi
done
if first_data_has_slash "$keys/slash.pem"; then
	mkdir -p "$work_dir/escaped"
	printf '{"key":"%s"}\n' "$(json_slashes <"$keys/slash.pem" | awk '{ printf "%s\\n", $0 }')" >"$work_dir/escaped/keys.json"
	expect_hit "JSON-escaped PEM key with \\/" "keys.json: BEGIN EC PRIVATE KEY" "$work_dir/escaped"
else
	echo "FAIL (setup): no EC key had a \"/\" in its first 40 data characters" >&2
	failures=$((failures + 1))
fi

# One clean and one dirty path: the scan still fails.
expect_hit "any dirty path fails the run" "BEGIN PRIVATE KEY" "$clean" "$plain"

# A corrupt zip cannot be shown to be clean.
printf 'PK\003\004not really a zip' >"$work_dir/corrupt.zip"
expect_hit "corrupt zip fails closed" "unreadable zip" "$work_dir/corrupt.zip"

if bash "$scanner" >/dev/null 2>&1; then
	echo "FAIL (usage): scanner without paths passed" >&2
	failures=$((failures + 1))
else
	echo "ok - scanner without paths is a usage error"
fi

if ((failures > 0)); then
	echo "scan-private-keys tests failed: $failures" >&2
	exit 1
fi
echo "scan-private-keys tests passed"
