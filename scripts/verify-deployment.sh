#!/bin/bash
# Verify Geoportal Server deployment is working correctly.
#
# Tests:
# 1. Elasticsearch connectivity
# 2. Catalog UI availability
# 3. Harvester UI availability
# 4. CSW GetCapabilities
# 5. REST API metadata endpoint
#
# Usage: ./verify-deployment.sh [CATALOG_URL] [HARVESTER_URL] [ES_URL]

CATALOG_URL="${1:-http://localhost:8080/geoportal}"
HARVESTER_URL="${2:-http://localhost:8081/harvester}"
ES_URL="${3:-http://localhost:9200}"

PASS=0
FAIL=0

check() {
  local name="$1"
  local url="$2"
  local expect="$3"

  printf "%-45s" "  $name..."

  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)

  if [ "$RESPONSE" = "$expect" ]; then
    echo "PASS ($RESPONSE)"
    PASS=$((PASS + 1))
  else
    echo "FAIL (got $RESPONSE, expected $expect)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Geoportal Server Deployment Verification ==="
echo ""

echo "Elasticsearch:"
check "Cluster health" "$ES_URL/_cluster/health" "200"
check "Metadata index exists" "$ES_URL/metadata" "200"

echo ""
echo "Catalog:"
check "Catalog UI" "$CATALOG_URL" "200"
check "REST API" "$CATALOG_URL/rest/metadata/search" "200"
check "CSW GetCapabilities" "$CATALOG_URL/csw?service=CSW&request=GetCapabilities" "200"

echo ""
echo "Harvester:"
check "Harvester UI" "$HARVESTER_URL" "200"
check "Harvester REST API" "$HARVESTER_URL/rest/harvester/connectors" "200"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Some checks failed. Make sure all containers are running:"
  echo "  docker compose ps"
  echo "  docker compose logs geoportal-catalog"
  echo "  docker compose logs geoportal-harvester"
  exit 1
fi
