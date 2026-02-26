#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 /path/to/YourApp.xcarchive missing_uuids.txt"
  exit 1
fi

ARCHIVE="$1"
MISSING_FILE="$2"
DSYMS_DIR="$ARCHIVE/dSYMs"

if [ ! -d "$DSYMS_DIR" ]; then
  echo "ERROR: dSYMs folder not found at: $DSYMS_DIR"
  exit 2
fi

TMP_UUIDS="$(mktemp /tmp/archive_dsym_uuids.XXXXXX)"

echo "Scanning dSYMs in: $DSYMS_DIR"
for f in "$DSYMS_DIR"/*.dSYM; do
  [ -e "$f" ] || continue
  dwarfdump --uuid "$f" || true
done > "$TMP_UUIDS"

echo "\nArchive dSYM UUIDs:" 
cat "$TMP_UUIDS"

if [ ! -f "$MISSING_FILE" ]; then
  echo "\nNo missing UUIDs file found at: $MISSING_FILE"
  echo "Provide a newline-separated file of UUIDs reported by App Store Connect."
  exit 3
fi

echo "\nComparing reported missing UUIDs to archive dSYMs:" 
while IFS= read -r uuid || [ -n "$uuid" ]; do
  uuid_trimmed=$(echo "$uuid" | tr -d '\r\n' | tr '[:lower:]' '[:upper:]' | xargs)
  if [ -z "$uuid_trimmed" ]; then
    continue
  fi
  if grep -i "$uuid_trimmed" "$TMP_UUIDS" >/dev/null 2>&1; then
    echo "FOUND: $uuid_trimmed ->" $(grep -i "$uuid_trimmed" "$TMP_UUIDS" )
  else
    echo "MISSING: $uuid_trimmed"
  fi
done < "$MISSING_FILE"

rm -f "$TMP_UUIDS"

echo "\nDone."
