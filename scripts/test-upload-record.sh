#!/bin/bash
# Quick test: upload the sample ISO 19115-3 record to Geoportal and verify.
#
# Usage: ./scripts/test-upload-record.sh [GEOPORTAL_URL]

GEOPORTAL_URL="${1:-http://localhost:8080/geoportal}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Phase 2 Verification: ISO 19115-3 Upload Test ==="
echo ""

# 1. Upload the test record
echo "1. Uploading sample ISO 19115-3 record..."
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X PUT "$GEOPORTAL_URL/rest/metadata/item" \
  -u gptadmin:gptadmin \
  -H "Content-Type: application/xml" \
  --data-binary "@$PROJECT_DIR/test/sample-iso19115-3.xml")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
  echo "   Upload OK ($HTTP_CODE)"
  ITEM_ID=$(echo "$BODY" | grep -oP '"id"\s*:\s*"\K[^"]+' || echo "unknown")
  echo "   Item ID: $ITEM_ID"
else
  echo "   Upload FAILED ($HTTP_CODE): $BODY"
  exit 1
fi

# 2. Wait for indexing
echo ""
echo "2. Waiting for indexing..."
sleep 3

# 3. Search for the record
echo ""
echo "3. Searching for 'Test DDE Dataset'..."
SEARCH=$(curl -s "$GEOPORTAL_URL/rest/metadata/search?q=Test+DDE+Dataset")

if echo "$SEARCH" | grep -q "Test DDE Dataset"; then
  echo "   FOUND in search results"
else
  echo "   NOT FOUND in search results (may need more indexing time)"
fi

# 4. Check the record via CSW
echo ""
echo "4. Checking CSW GetRecordById..."
CSW_RESPONSE=$(curl -s "$GEOPORTAL_URL/csw?service=CSW&version=2.0.2&request=GetRecordById&id=test-dde-001&outputSchema=http://standards.iso.org/iso/19115/-3/mdb/2.0")

if echo "$CSW_RESPONSE" | grep -q "MD_Metadata"; then
  echo "   CSW returned ISO 19115-3 record"
else
  echo "   CSW did not return expected record"
fi

echo ""
echo "=== Test complete ==="
echo ""
echo "Next steps:"
echo "  - Open ${GEOPORTAL_URL} in browser"
echo "  - Search for 'DDE' or 'geology'"
echo "  - Click on the record to view the detail page"
echo "  - Verify: title, abstract, keywords, spatial extent all display correctly"
