#!/usr/bin/env bash
set -euo pipefail
# Compose base openclaw.json from upstream + overlays
WORKDIR=$(pwd)
BASE="/home/node/.openclaw/openclaw.json"
OUT="$WORKDIR/openclaw.json"
# Start from upstream base if exists, else empty object
if [ -f "$BASE" ]; then
  cp "$BASE" "$OUT"
else
  echo '{}' > "$OUT"
fi
# Apply overlays in ops/overlays/*.json (ordered)
for f in ops/overlays/*.json; do
  [ -e "$f" ] || continue
  # Merge using jq: overlay wins for conflicting keys
  tmp=$(mktemp)
  jq -s '.[0] * .[1]' "$OUT" "$f" > "$tmp"
  mv "$tmp" "$OUT"
done
echo "Composed $OUT from upstream + overlays"
