#!/bin/sh
set -eu

PROJECT_DIR=${PROJECT_DIR:-"$(cd "$(dirname "$0")/.." && pwd)"}
SOURCE_ROOT="$PROJECT_DIR/Sources"
DERIVED_ROOT="$PROJECT_DIR/LookInside/DerivedSource"

mkdir -p "$DERIVED_ROOT"

for name in LookinCore LookinServerBase; do
  mkdir -p "$DERIVED_ROOT/$name"
  rsync -a --delete "$SOURCE_ROOT/$name/" "$DERIVED_ROOT/$name/"
done
