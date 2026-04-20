#!/bin/sh
set -eu

PROJECT_DIR=${PROJECT_DIR:-"$(cd "$(dirname "$0")/.." && pwd)"}
CHECKOUT_ROOT="$PROJECT_DIR/.build/checkouts/LookInsideServer"
DERIVED_ROOT="$PROJECT_DIR/LookInside/DerivedSource"

cd "$PROJECT_DIR"

if [ ! -d "$CHECKOUT_ROOT/Sources" ]; then
  swift package resolve
fi

if [ ! -d "$CHECKOUT_ROOT/Sources" ]; then
  echo "error: LookInsideServer checkout missing at $CHECKOUT_ROOT after swift package resolve" >&2
  exit 1
fi

SOURCE_ROOT="$CHECKOUT_ROOT/Sources"

mkdir -p "$DERIVED_ROOT"

for name in LookinCore LookinServerBase; do
  mkdir -p "$DERIVED_ROOT/$name"
  rsync -a --delete "$SOURCE_ROOT/$name/" "$DERIVED_ROOT/$name/"
done
