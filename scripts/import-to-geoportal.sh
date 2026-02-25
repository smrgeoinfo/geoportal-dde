#!/bin/bash
# Import ISO 19115-3 XML records into Geoportal Server Catalog via REST API.
#
# Uses PUT /geoportal/rest/metadata/item to upload each record.
#
# Usage:
#   ./import-to-geoportal.sh [INPUT_DIR] [GEOPORTAL_URL] [USERNAME] [PASSWORD]
#
# Example:
#   ./import-to-geoportal.sh ./exported-records http://localhost:8080/geoportal gptadmin gptadmin

INPUT_DIR="${1:-./exported-records}"
GEOPORTAL_URL="${2:-http://localhost:8080/geoportal}"
USERNAME="${3:-gptadmin}"
PASSWORD="${4:-gptadmin}"

REST_URL="${GEOPORTAL_URL}/rest/metadata/item"

echo "Importing records from: $INPUT_DIR"
echo "Target: $REST_URL"
echo ""

SUCCESS=0
FAIL=0

for xmlfile in "$INPUT_DIR"/*.xml; do
  if [ ! -f "$xmlfile" ]; then
    echo "No XML files found in $INPUT_DIR"
    exit 1
  fi

  FILENAME=$(basename "$xmlfile")
  echo -n "Importing $FILENAME ... "

  RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X PUT "$REST_URL" \
    -u "$USERNAME:$PASSWORD" \
    -H "Content-Type: application/xml" \
    --data-binary "@$xmlfile")

  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | sed '$d')

  if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    echo "OK ($HTTP_CODE)"
    SUCCESS=$((SUCCESS + 1))
  else
    echo "FAILED ($HTTP_CODE): $BODY"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "Import complete."
echo "  Success: $SUCCESS"
echo "  Failed:  $FAIL"
echo "  Total:   $((SUCCESS + FAIL))"
