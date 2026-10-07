#!/bin/bash
# Fails when a PEM private key is found in the given files or directories.
#
# Usage: bash Scripts/scan-private-keys.sh <path> [<path> ...]
#
# Directories are walked recursively, so .app, .xcframework and .xcarchive
# bundles are covered. Zip files (including .ipa) and tar files (plain, gzip,
# bzip2, xz) are opened and their members scanned, nested archives included;
# standalone gzip, bzip2 and xz files are decompressed and scanned. Detection
# is by content, not by file name. An archive that cannot be fully read (for
# example an encrypted zip member) fails the scan, because it cannot be shown
# to be clean.
#
# A hit is a PEM private-key header (PRIVATE KEY, RSA/EC/DSA/ENCRYPTED/OPENSSH
# PRIVATE KEY, PGP PRIVATE KEY BLOCK) followed by key data, also when the
# line breaks are written as \n escapes and slashes as \/ inside a string
# literal. Key data without a header is a hit too: a raw DER key (PKCS#8,
# encrypted PKCS#8, PKCS#1 RSA, SEC1 EC) or an OpenSSH key body anywhere in a
# file, or the same encoded as base64 (one line or wrapped, plain or escaped).
# Each candidate is parsed as DER, so certificates and public keys pass. Code
# that only names a header, such as a PEM parser, does not count. Matches are
# reported by location and key type only; key material is never printed.
#
# Exit status: 0 clean, 1 private key found or archive unreadable, 2 usage.
#
# This script is kept identical in every repository that publishes artifacts.

set -euo pipefail

if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
	sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//' >&2
	exit 2
fi

exec python3 - "$@" <<'PY'
import base64
import binascii
import bz2
import gzip
import io
import lzma
import os
import re
import stat
import sys
import tarfile
import zipfile

MAX_DEPTH = 8

PEM_PRIVATE_KEY = re.compile(
    rb"-----BEGIN ((?:[A-Z0-9]+ )*PRIVATE KEY(?: BLOCK)?)-----"
    # Optional RFC 1421 headers (Proc-Type, DEK-Info) or PGP armor headers.
    rb"(?:(?:\s|\\[rn])+[A-Za-z][A-Za-z0-9-]*:[^\r\n\\]*)*"
    # Real key data follows the header; JSON may escape "/" as "\/".
    rb"(?:\s|\\[rn])+(?:[A-Za-z0-9+/=]|\\/){40}"
)

# Where a raw DER private key can start: a SEQUENCE holding version 0 or 1
# followed by an AlgorithmIdentifier (PKCS#8), an INTEGER (PKCS#1) or an
# OCTET STRING (SEC1), or a SEQUENCE whose first element is an encryption
# AlgorithmIdentifier (encrypted PKCS#8). Candidates are confirmed by parsing.
DER_CANDIDATE = re.compile(
    rb"\x30(?:\x83...|\x82..|\x81.|[\x00-\x7f])"
    rb"(?:\x02\x01[\x00\x01][\x02\x04\x30]|\x30(?:\x81.|[\x00-\x7f])\x06)",
    re.DOTALL,
)

# The OpenSSH key body: magic, then the cipher name as an SSH string.
OPENSSH_KEY_MAGIC = b"openssh-key-" + b"v1\x00"
OPENSSH_KEY = re.compile(
    re.escape(OPENSSH_KEY_MAGIC) + rb"\x00\x00\x00[\x03-\x20][a-z0-9]", re.DOTALL
)

# A base64 run that may encode a key: DER keys start with 0x30 ("M" followed
# by "A".."P"), the OpenSSH body with its magic ("b3Bl"). The run may wrap
# with real (indented) or escaped line breaks, and JSON may escape "/" as "\/".
BASE64_START = re.compile(rb"(?:(?<![A-Za-z0-9+/\\])|(?<=\\[nr]))(?:M[A-P]|b3Bl)")
BASE64_RUN = re.compile(rb"(?:[A-Za-z0-9+=]|\\?/|\\[rn]|[\r\n][ \t]*)+")
BASE64_SEPARATORS = re.compile(rb"\\[rn]|[\r\n][ \t]*|\\(?=/)")
MAX_BASE64_RUN = 32 * 1024
MIN_KEY_BYTES = 40

PKCS8_ALGORITHMS = {
    bytes.fromhex("2a864886f70d010101"): "RSA",
    bytes.fromhex("2a864886f70d01010a"): "RSA-PSS",
    bytes.fromhex("2a8648ce3d0201"): "EC",
    bytes.fromhex("2a8648ce380401"): "DSA",
    bytes.fromhex("2b656e"): "X25519",
    bytes.fromhex("2b656f"): "X448",
    bytes.fromhex("2b6570"): "Ed25519",
    bytes.fromhex("2b6571"): "Ed448",
}

ENCRYPTION_ALGORITHM_PREFIXES = (
    # PKCS#5 PBES1 and PBES2.
    bytes.fromhex("2a864886f70d0105"),
    # PKCS#12 password-based encryption.
    bytes.fromhex("2a864886f70d010c01"),
)

hits = []
errors = []


def read_tlv(data, position, end):
    """Returns (tag, content start, content end) of one DER element, or None."""
    if position + 2 > end:
        return None
    tag = data[position]
    first = data[position + 1]
    position += 2
    if first < 0x80:
        length = first
    elif 0x81 <= first <= 0x83:
        size = first - 0x80
        if position + size > end:
            return None
        length = int.from_bytes(data[position : position + size], "big")
        position += size
        # DER uses the shortest length form.
        if length < 0x80 or length < (1 << (8 * (size - 1))):
            return None
    else:
        return None
    if position + length > end:
        return None
    return tag, position, position + length


def read_children(data, start, end, limit=12):
    children = []
    position = start
    while position < end:
        element = read_tlv(data, position, end)
        if element is None or len(children) == limit:
            return None
        children.append(element)
        position = element[2]
    return children


def algorithm_oid(data, algorithm):
    tag, start, end = algorithm
    if tag != 0x30:
        return None
    children = read_children(data, start, end)
    if not children or children[0][0] != 0x06:
        return None
    return data[children[0][1] : children[0][2]]


def classify_der(data, offset):
    """Names the private-key structure that starts at offset, or None."""
    outer = read_tlv(data, offset, len(data))
    if outer is None or outer[0] != 0x30:
        return None
    children = read_children(data, outer[1], outer[2])
    if not children or len(children) < 2:
        return None
    first, second = children[0], children[1]
    content = lambda element: data[element[1] : element[2]]

    if first[0] == 0x02 and content(first) in (b"\x00", b"\x01"):
        version = content(first)[0]
        if (
            second[0] == 0x30
            and len(children) >= 3
            and children[2][0] == 0x04
            and children[2][2] > children[2][1]
        ):
            name = PKCS8_ALGORITHMS.get(algorithm_oid(data, second))
            if name:
                return f"PKCS#8 {name} private key"
        if (
            version == 0
            and len(children) == 9
            and all(element[0] == 0x02 for element in children)
        ):
            return "PKCS#1 RSA private key"
        if (
            version == 1
            and second[0] == 0x04
            and 16 <= second[2] - second[1] <= 66
            and len(children) >= 3
            and all(element[0] in (0xA0, 0xA1) for element in children[2:])
        ):
            return "SEC1 EC private key"
        return None

    if first[0] == 0x30 and len(children) == 2 and second[0] == 0x04:
        oid = algorithm_oid(data, first)
        if oid and oid.startswith(ENCRYPTION_ALGORITHM_PREFIXES):
            return "encrypted PKCS#8 private key"
    return None


def classify_key_bytes(data):
    if len(data) < MIN_KEY_BYTES:
        return None
    if data.startswith(OPENSSH_KEY_MAGIC):
        return "OpenSSH private key" if OPENSSH_KEY.match(data) else None
    return classify_der(data, 0)


def decode_base64_run(run):
    text = BASE64_SEPARATORS.sub(b"", run).split(b"=", 1)[0]
    # A lone trailing character cannot be decoded; anything after "=" is not
    # part of this value.
    if len(text) % 4 == 1:
        text = text[:-1]
    try:
        return base64.b64decode(text + b"=" * (-len(text) % 4), validate=True)
    except (binascii.Error, ValueError):
        return b""


def report_hits(data, location):
    seen = set()

    def add(description):
        if description not in seen:
            seen.add(description)
            hits.append(f"{location}: {description}")

    for match in PEM_PRIVATE_KEY.finditer(data):
        add("BEGIN " + match.group(1).decode("ascii"))
    for match in DER_CANDIDATE.finditer(data):
        description = classify_der(data, match.start())
        if description:
            add(f"{description} (DER)")
    for match in OPENSSH_KEY.finditer(data):
        add("OpenSSH private key (binary)")
    for match in BASE64_START.finditer(data):
        run = BASE64_RUN.match(data, match.start(), match.start() + MAX_BASE64_RUN)
        description = classify_key_bytes(decode_base64_run(run.group(0)))
        if description:
            add(f"{description} (base64)")


def scan_bytes(data, location, depth):
    report_hits(data, location)
    if depth >= MAX_DEPTH:
        errors.append(f"{location}: archive nesting deeper than {MAX_DEPTH}")
        return
    scan_container(io.BytesIO(data), data[:6], location, depth)


def scan_container(stream, magic, location, depth):
    if magic.startswith(b"PK\x03\x04") or magic.startswith(b"PK\x05\x06"):
        scan_zip(stream, location, depth)
        return
    stream.seek(0)
    if tarfile.is_tarfile(stream):
        stream.seek(0)
        scan_tar(stream, location, depth)
        return
    for prefix, opener in (
        (b"\x1f\x8b", gzip.GzipFile),
        (b"BZh", bz2.BZ2File),
        (b"\xfd7zXZ\x00", lzma.LZMAFile),
    ):
        if magic.startswith(prefix):
            stream.seek(0)
            try:
                with opener(fileobj=stream) as decompressed:
                    data = decompressed.read()
            except Exception as error:
                errors.append(f"{location}: cannot decompress ({error})")
                return
            scan_bytes(data, f"{location}!<decompressed>", depth + 1)
            return


def scan_zip(stream, location, depth):
    try:
        archive = zipfile.ZipFile(stream)
    except zipfile.BadZipFile as error:
        errors.append(f"{location}: unreadable zip ({error})")
        return
    with archive:
        for info in archive.infolist():
            if info.is_dir():
                continue
            member = f"{location}!{info.filename}"
            try:
                data = archive.read(info)
            except Exception as error:
                errors.append(f"{member}: cannot read zip member ({error})")
                continue
            scan_bytes(data, member, depth + 1)


def scan_tar(stream, location, depth):
    try:
        archive = tarfile.open(fileobj=stream, mode="r:*")
    except tarfile.TarError as error:
        errors.append(f"{location}: unreadable tar ({error})")
        return
    with archive:
        try:
            for info in archive:
                if not info.isfile():
                    continue
                member = f"{location}!{info.name}"
                extracted = archive.extractfile(info)
                if extracted is None:
                    continue
                with extracted:
                    data = extracted.read()
                scan_bytes(data, member, depth + 1)
        except (tarfile.TarError, EOFError, OSError, lzma.LZMAError) as error:
            errors.append(f"{location}: unreadable tar ({error})")


def scan_file(path):
    try:
        with open(path, "rb") as handle:
            magic = handle.read(6)
            handle.seek(0)
            data = handle.read()
    except OSError as error:
        errors.append(f"{path}: cannot read ({error})")
        return
    report_hits(data, path)
    scan_container(io.BytesIO(data), magic, path, 0)


def scan_path(root):
    try:
        mode = os.lstat(root).st_mode
    except OSError as error:
        errors.append(f"{root}: cannot stat ({error})")
        return
    if stat.S_ISREG(mode):
        scan_file(root)
        return
    if not stat.S_ISDIR(mode):
        # Symlinks are not followed: bundle symlinks point inside the bundle.
        return
    def listing_failed(error):
        errors.append(f"{error.filename}: cannot list ({error.strerror})")

    for directory, _subdirectories, files in os.walk(root, onerror=listing_failed):
        for name in sorted(files):
            path = os.path.join(directory, name)
            if stat.S_ISREG(os.lstat(path).st_mode):
                scan_file(path)


for argument in sys.argv[1:]:
    scan_path(argument)

for line in hits:
    print(f"private key found: {line}", file=sys.stderr)
for line in errors:
    print(f"scan error: {line}", file=sys.stderr)

if hits or errors:
    print(
        f"private key scan failed: {len(hits)} key(s), {len(errors)} unreadable item(s)",
        file=sys.stderr,
    )
    sys.exit(1)

print(f"private key scan passed: {' '.join(sys.argv[1:])}")
PY
