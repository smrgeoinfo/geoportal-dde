# geoportal-dde

Metadata catalog for [Deep-time Digital Earth (DDE)](https://www.ddeworld.org/), built on [Esri Geoportal Server](https://github.com/Esri/geoportal-server-catalog). Replaces a GeoNetwork 4.4.9 fork that required 100+ merge conflicts per upstream upgrade.

All DDE customizations live outside the base platform as config files, XSLTs, and a plugin JAR. Upgrading Geoportal Server is a WAR swap.

## Architecture

```
                 ┌─────────────────────────────┐
                 │  Geoportal Catalog v3.0.2   │
  Browser ──────│  (Tomcat 9)                  │
                 │                              │
                 │  Search UI, Editor, CSW 2/3  │
                 │  ISO 19115-3 (built-in)      │
                 └──────────┬──────────────────┘
                            │
                  ┌─────────▼──────────┐
                  │  Elasticsearch     │
                  │  8.14.3            │
                  │  (sole datastore)  │
                  └─────────▲──────────┘
                            │
  ┌─────────────────────────┴──────────────────┐
  │  Geoportal Harvester v3.0.0                │
  │  (Tomcat 9)                                │
  │                                            │
  │  Built-in: WAF, CSW, CKAN, OAI-PMH, DCAT, │
  │            STAC, THREDDS, ArcGIS, JDBC     │
  │  Custom:   CDIF Sitemap (JSON-LD)          │
  │            fromJsonCdif.xsl conversion     │
  └────────────────────────────────────────────┘
```

## Quick start

### 1. Start the stack

```bash
docker compose up -d
```

Elasticsearch starts first (healthcheck), then the catalog and harvester. Three containers total.

### 2. Verify

| Service | URL | Credentials |
|---------|-----|-------------|
| Catalog UI | http://localhost:8082/geoportal | `gptadmin` / `gptadmin` |
| Catalog REST API | http://localhost:8082/geoportal/rest/metadata/search | |
| Harvester UI | http://localhost:8083/harvester | |
| Harvester REST API | http://localhost:8083/harvester/rest/harvester/connectors/inbound | |
| Elasticsearch | http://localhost:9202 | |
| Kibana (debug) | `docker compose --profile debug up kibana` then http://localhost:5601 | |

Upload a test record:

```bash
curl -X PUT -u gptadmin:gptadmin \
  -H "Content-Type: application/xml" \
  -d @test/sample-iso19115-3.xml \
  http://localhost:8082/geoportal/rest/metadata/item/test-dde-001
```

### 3. Build and install the CDIF connector

Prerequisites: clone and build the Geoportal Harvester SDK (needed once):

```bash
git clone https://github.com/Esri/geoportal-server-harvester.git
cd geoportal-server-harvester && git checkout v3.0.0
mvn clean install -DskipTests
cd ..
```

Build the connector:

```bash
cd cdif-connector
mvn clean package
```

Enable the connector by uncommenting the two volume mounts in `docker-compose.yml` under `geoportal-harvester`:

```yaml
- ./harvester/hrv-beans.xml:/usr/local/tomcat/webapps/harvester/WEB-INF/classes/config/hrv-beans.xml
- ./cdif-connector/target/geoportal-harvester-cdif-sitemap-1.0.0.jar:/usr/local/tomcat/webapps/harvester/WEB-INF/lib/geoportal-harvester-cdif-sitemap-1.0.0.jar
```

Then recreate the harvester:

```bash
docker compose up -d geoportal-harvester --force-recreate
```

### 4. Run a CDIF harvest

1. Open http://localhost:8083/harvester
2. Create a new task with Input = **CDIF Sitemap (JSON-LD)**
3. Set Sitemap URL to a CDIF sitemap (e.g. the test sitemap in `test/cdif-sitemap.xml`)
4. Set Output = **Geoportal** with URL `http://geoportal-catalog:8080/geoportal`
5. Execute -- records are converted from JSON-LD to ISO 19115-3 and published to the catalog

### 5. Migrate existing GeoNetwork records

```bash
# Export from GeoNetwork as ISO 19115-3
./scripts/export-geonetwork-records.sh http://localhost:8080/geonetwork ./exported-records

# Import into Geoportal
./scripts/import-to-geoportal.sh ./exported-records http://localhost:8082/geoportal gptadmin gptadmin
```

## Project structure

```
geoportal-dde/
├── docker-compose.yml              # Full stack: ES + Catalog + Harvester (+Kibana)
├── catalog/
│   ├── Dockerfile                   # Tomcat 9 + Catalog WAR v3.0.2
│   ├── app-context.xml              # (unused -- config via env vars instead)
│   └── elastic-config.xml           # (unused)
├── harvester/
│   ├── Dockerfile                   # Tomcat 9 + Harvester WAR v3.0.0
│   ├── hrv-beans.xml                # Spring beans with CDIF connector registered
│   ├── hrv-beans-cdif.xml           # Standalone CDIF-only bean definition
│   └── hrv-config.xml               # (unused -- harvester configured via UI)
├── cdif-connector/                  # Custom Geoportal Harvester plugin
│   ├── pom.xml                      # Maven build (shaded JAR with JDOM2, json, Saxon-HE)
│   └── src/main/java/.../cdif/
│       ├── CdifConstants.java       # Property key constants
│       ├── CdifSitemapConnector.java # InputConnector factory (UI template, validation)
│       ├── CdifSitemapBroker.java   # InputBroker (sitemap parse, JSON-LD fetch, XSLT)
│       └── CdifSitemapDefinitionAdaptor.java  # Typed config wrapper
├── xslt/
│   ├── fromJsonCdif.xsl             # CDIF JSON-LD intermediate XML -> ISO 19115-3
│   └── iso19115-3-to-schemaorg.xsl  # ISO 19115-3 -> schema.org JSON-LD
├── scripts/
│   ├── export-geonetwork-records.sh # Export from GeoNetwork via CSW
│   ├── import-to-geoportal.sh       # Bulk import via REST API
│   ├── test-upload-record.sh        # Upload a single test record
│   └── verify-deployment.sh         # Smoke test all endpoints
├── test/
│   ├── sample-iso19115-3.xml        # Test ISO 19115-3 record
│   └── cdif-sitemap.xml             # Test sitemap with 77 CDIF record URLs
└── pygeoapi-config.yml              # OGC API Records config (future)
```

## Configuration

The catalog uses **environment variables** for configuration (no config file overrides needed):

| Variable | Default | Description |
|----------|---------|-------------|
| `es_node` | (empty -- connects to localhost) | Elasticsearch hostname |
| `harvester_node` | (empty) | Harvester REST API URL |
| `gpt_authentication` | `authentication-simple.xml` | Auth method |
| `gpt_indexName` | `metadata` | ES index name |

These are set in `docker-compose.yml` under the `geoportal-catalog` service.

## CDIF connector

The CDIF connector (`cdif-connector/`) is a Geoportal Harvester InputBroker that:

1. Fetches a sitemap XML from a configured URL
2. Parses `<url>/<loc>` elements (handles `<sitemapindex>` recursion)
3. For each URL: fetches JSON-LD, converts to intermediate XML via `org.json.XML`
4. Normalizes keys (`schema:name` -> `schema_name`, `@id` -> `id`)
5. Generates a stable UUID from the `@id` field via SHA-1
6. Applies `fromJsonCdif.xsl` (XSLT 2.0 via Saxon-HE) to produce ISO 19115-3
7. Yields the result as a `SimpleDataReference` for the Geoportal OutputBroker

The sitemap parsing is ported from GeoNetwork's `simpleurl.Harvester` using direct JDOM child traversal (avoids XPath issues with detached elements). The XSLT is a direct copy of GeoNetwork's `fromJsonCdif.xsl`, proven with 77 CDIF records.

## Output formats

| Format | How to access |
|--------|---------------|
| ISO 19115-3 XML | Native storage format. `GET /rest/metadata/item/{id}` |
| ISO 19139 XML | CSW with `outputSchema=http://www.isotc211.org/2005/gmd` |
| schema.org JSON-LD | Via `xslt/iso19115-3-to-schemaorg.xsl` transform |

## What was carried over from GeoNetwork

| Asset | Status |
|-------|--------|
| `fromJsonCdif.xsl` (CDIF -> ISO 19115-3) | Direct copy, proven with 77 records |
| Sitemap parsing logic (JDOM traversal) | Ported to CdifSitemapBroker |
| ISO 19115-3 support | Built into Geoportal v3.0.2 (no custom profile needed) |
| ES 8.x compatibility | Native in Geoportal (no patches needed) |

## What was left behind

- GeoNetwork monolith fork (~1GB repo, 100-conflict merges per upgrade)
- All SMR-Samsung backup files (200+ files)
- Custom patches to GeoNetwork core Java code
- 40-module Maven build

## Future: OGC API Records

Add a [pygeoapi](https://pygeoapi.io/) container reading from the same Elasticsearch index:

```yaml
# Add to docker-compose.yml
pygeoapi:
  image: geopython/pygeoapi:latest
  ports:
    - "5000:80"
  volumes:
    - ./pygeoapi-config.yml:/pygeoapi/local.config.yml
```

A skeleton config is provided in `pygeoapi-config.yml`.
