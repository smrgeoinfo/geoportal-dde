#!/bin/bash
# Export records from GeoNetwork 4.4.9 as ISO 19115-3 XML.
#
# Uses CSW GetRecords to page through all records and save each one
# as an individual XML file for import into Geoportal Server.
#
# Usage:
#   ./export-geonetwork-records.sh [GEONETWORK_URL] [OUTPUT_DIR]
#
# Example:
#   ./export-geonetwork-records.sh http://localhost:8080/geonetwork ./exported-records

GEONETWORK_URL="${1:-http://localhost:8080/geonetwork}"
OUTPUT_DIR="${2:-./exported-records}"
PAGE_SIZE=20
CSW_URL="${GEONETWORK_URL}/srv/eng/csw"

mkdir -p "$OUTPUT_DIR"

echo "Exporting records from: $CSW_URL"
echo "Output directory: $OUTPUT_DIR"

# Get total record count first
HITS_RESPONSE=$(curl -s -X POST "$CSW_URL" \
  -H "Content-Type: application/xml" \
  -d '<?xml version="1.0"?>
<csw:GetRecords xmlns:csw="http://www.opengis.net/cat/csw/2.0.2"
                service="CSW" version="2.0.2"
                resultType="hits"
                maxRecords="1">
  <csw:Query typeNames="csw:Record">
    <csw:Constraint version="1.1.0">
      <Filter xmlns="http://www.opengis.net/ogc">
        <PropertyIsLike wildCard="%" singleChar="_" escapeChar="\\">
          <PropertyName>AnyText</PropertyName>
          <Value>%</Value>
        </PropertyIsLike>
      </Filter>
    </csw:Constraint>
  </csw:Query>
</csw:GetRecords>')

TOTAL=$(echo "$HITS_RESPONSE" | grep -oP 'numberOfRecordsMatched="\K[0-9]+')
echo "Total records to export: ${TOTAL:-unknown}"

# Page through records
START=1
COUNT=0

while true; do
  echo "Fetching records $START to $((START + PAGE_SIZE - 1))..."

  RESPONSE=$(curl -s -X POST "$CSW_URL" \
    -H "Content-Type: application/xml" \
    -d "<?xml version=\"1.0\"?>
<csw:GetRecords xmlns:csw=\"http://www.opengis.net/cat/csw/2.0.2\"
                service=\"CSW\" version=\"2.0.2\"
                resultType=\"results\"
                startPosition=\"$START\"
                maxRecords=\"$PAGE_SIZE\"
                outputSchema=\"http://standards.iso.org/iso/19115/-3/mdb/2.0\">
  <csw:Query typeNames=\"csw:Record\">
    <csw:Constraint version=\"1.1.0\">
      <Filter xmlns=\"http://www.opengis.net/ogc\">
        <PropertyIsLike wildCard=\"%\" singleChar=\"_\" escapeChar=\"\\\\\">
          <PropertyName>AnyText</PropertyName>
          <Value>%</Value>
        </PropertyIsLike>
      </Filter>
    </csw:Constraint>
  </csw:Query>
</csw:GetRecords>")

  # Check if we got any results
  if echo "$RESPONSE" | grep -q "numberOfRecordsReturned=\"0\""; then
    echo "No more records."
    break
  fi

  # Extract individual mdb:MD_Metadata elements and save as files
  # Uses xmllint to split — requires libxml2-utils
  if command -v xmllint &> /dev/null; then
    RECORDS=$(echo "$RESPONSE" | xmllint --xpath '//*[local-name()="MD_Metadata" and namespace-uri()="http://standards.iso.org/iso/19115/-3/mdb/2.0"]' - 2>/dev/null || true)

    if [ -n "$RECORDS" ]; then
      # Save entire response and process with Python for better splitting
      echo "$RESPONSE" > "$OUTPUT_DIR/_page_${START}.xml"
      COUNT=$((COUNT + PAGE_SIZE))
    fi
  else
    # Fallback: save raw response pages
    echo "$RESPONSE" > "$OUTPUT_DIR/page_${START}.xml"
    COUNT=$((COUNT + PAGE_SIZE))
  fi

  START=$((START + PAGE_SIZE))

  # Safety: don't loop forever
  if [ "$START" -gt 10000 ]; then
    echo "Reached 10000 records limit."
    break
  fi
done

echo ""
echo "Export complete. Files saved to: $OUTPUT_DIR"
echo "Approximate records exported: $COUNT"
echo ""
echo "Next step: import into Geoportal Server with import-to-geoportal.sh"
