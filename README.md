# Geoportal DDE — Migration from GeoNetwork to Esri Geoportal Server

Replacement catalog system for the DDE (Deep-time Digital Earth) metadata
catalog, migrating from a GeoNetwork 4.4.9 fork to Esri Geoportal Server.

## Why migrate?

The GeoNetwork fork embeds ~15 custom files inside a 40-module Java monolith.
Every upstream upgrade requires resolving 100+ merge conflicts. Esri Geoportal
Server keeps customizations as external profiles and plugins — upgrading the
base is a WAR swap.

## Architecture

```
Geoportal Catalog (Tomcat)     Geoportal Harvester (Tomcat)
  - ISO 19115-3 profile          - CDIF Sitemap InputBroker
  - Search UI / Editor           - fromJsonCdif.xsl conversion
  - CSW 2/3                      - Geoportal OutputBroker
  - XSLT transforms
         |                              |
         v                              v
    Elasticsearch 8.14.3          (pushes to Catalog REST API)
    (sole datastore)
```

## Directory structure

```
geoportal-dde/
  docker-compose.yml          # Full stack: ES + Catalog + Harvester
  catalog/
    Dockerfile                # Tomcat 9 + Catalog WAR (v3.0.2)
    app-context.xml           # Spring config → ES connection
    elastic-config.xml        # ES host/port settings
  harvester/
    Dockerfile                # Tomcat 9 + Harvester WAR (v3.0.0)
    hrv-config.xml            # Harvester → Catalog connection
    hrv-beans-cdif.xml        # Spring bean registration for CDIF connector
  cdif-connector/
    pom.xml                   # Maven module for the CDIF InputBroker
    src/main/java/.../cdif/
      CdifConstants.java      # Property key constants
      CdifSitemapConnector.java    # Factory (InputConnector impl)
      CdifSitemapBroker.java       # Worker (InputBroker impl)
      CdifSitemapDefinitionAdaptor.java  # Typed config wrapper
    src/main/resources/
      CdifResource.properties # UI labels
  xslt/
    fromJsonCdif.xsl          # CDIF JSON-LD → ISO 19115-3 (from GeoNetwork)
    iso19115-3-to-schemaorg.xsl  # ISO 19115-3 → schema.org JSON-LD
  scripts/
    export-geonetwork-records.sh  # Export from GeoNetwork via CSW
    import-to-geoportal.sh       # Bulk import into Geoportal REST API
    verify-deployment.sh          # Smoke test the deployment
```

## Quick start

### 1. Start the stack

```bash
docker compose up -d
```

Wait for Elasticsearch to be healthy, then the catalog and harvester will start.

### 2. Verify

```bash
./scripts/verify-deployment.sh
```

- Catalog UI: http://localhost:8080/geoportal
- Harvester UI: http://localhost:8081/harvester
- Elasticsearch: http://localhost:9200
- Kibana (debug): `docker compose --profile debug up kibana`

### 3. Build and install the CDIF connector

```bash
cd cdif-connector
mvn clean package

# Copy the shaded JAR into the harvester WAR
docker cp target/geoportal-harvester-cdif-sitemap-1.0.0.jar \
  geoportal-harvester:/usr/local/tomcat/webapps/harvester/WEB-INF/lib/

# Restart harvester to pick up the new connector
docker compose restart geoportal-harvester
```

### 4. Configure a CDIF harvest

1. Open http://localhost:8081/harvester
2. Create new task: Input = "CDIF Sitemap (JSON-LD)"
3. Sitemap URL: `https://raw.githubusercontent.com/Cross-Domain-Interoperability-Framework/validation/main/testJSONMetadata/sitemap.xml`
4. Output = "Geoportal" → http://geoportal-catalog:8080/geoportal
5. Run the harvest — 77 records should appear in the catalog

### 5. Migrate existing GeoNetwork records

```bash
# Export from GeoNetwork as ISO 19115-3
./scripts/export-geonetwork-records.sh http://localhost:8080/geonetwork ./exported-records

# Import into Geoportal
./scripts/import-to-geoportal.sh ./exported-records http://localhost:8080/geoportal gptadmin gptadmin
```

## What was carried over from GeoNetwork

| Asset | Status |
|-------|--------|
| `fromJsonCdif.xsl` (CDIF→ISO 19115-3) | Direct copy, proven with 77 records |
| Sitemap parsing (JDOM traversal) | Ported to CdifSitemapBroker.java |
| CDIF field mappings | Same mappings in Geoportal's JS evaluator |
| ISO 19115-3 profile | Already built into Geoportal v3.0.2 |
| ES 8.x compatibility | Native in Geoportal (no patches needed) |

## What was left behind

- GeoNetwork monolith fork (~1GB repo, 100-conflict merges)
- All SMR-Samsung backup files
- Custom patches to GeoNetwork core Java code
- Complex Maven multi-module build (40+ modules)

## Output formats

Records can be served in three formats:

| Format | Method |
|--------|--------|
| ISO 19115-3 XML | Native — records stored as ISO 19115-3 |
| ISO 19139 XML | CSW outputSchema=`http://www.isotc211.org/2005/gmd` |
| schema.org JSON-LD | Via `iso19115-3-to-schemaorg.xsl` transform |

## Future: OGC API Records

Deploy pygeoapi with the Elasticsearch backend pointing at the same `metadata`
index. Single Docker container, no code changes to the catalog:

```yaml
# Add to docker-compose.yml
pygeoapi:
  image: geopython/pygeoapi:latest
  ports:
    - "5000:80"
  volumes:
    - ./pygeoapi-config.yml:/pygeoapi/local.config.yml
```
