# CLAUDE.md -- Instructions for Claude Code

## Project overview

This is `geoportal-dde`, a Docker Compose deployment of Esri Geoportal Server for the DDE metadata catalog. The main custom code is a CDIF sitemap harvester connector (`cdif-connector/`) that converts JSON-LD to ISO 19115-3 via XSLT.

See `agents.md` for full project context including architecture, API endpoints, and implementation details.

## Common commands

```bash
# Start the full stack (ES + Catalog + Harvester)
docker compose up -d

# Rebuild the CDIF connector after code changes
cd cdif-connector && mvn clean package
docker compose up -d geoportal-harvester --force-recreate

# Upload a test record
curl -X PUT -u gptadmin:gptadmin -H "Content-Type: application/xml" \
  -d @test/sample-iso19115-3.xml \
  http://localhost:8082/geoportal/rest/metadata/item/test-dde-001

# Search the catalog
curl http://localhost:8082/geoportal/rest/metadata/search

# Check ES record count
curl http://localhost:9202/metadata_v1/_count

# View logs
docker compose logs -f geoportal-harvester
docker compose logs -f geoportal-catalog
```

## Key architecture decisions

- **No config file overrides for the catalog** -- use environment variables (`es_node`, `harvester_node`, etc.). Volume-mounting `app-context.xml` breaks the Spring context.
- **`es_node` is a hostname only** -- not a URL. `elasticsearch` not `http://elasticsearch:9200`.
- **Shaded JAR bundles 4 libraries** -- JDOM2, org.json, Saxon-HE, xmlresolver. All others are `provided` by the WAR.
- **Saxon SPI excluded** -- `META-INF/services/javax.xml.transform.TransformerFactory` must be excluded from the shaded JAR or it breaks the harvester's built-in XSLT processing. Our code calls `new TransformerFactoryImpl()` directly.
- **All namespace prefixes normalized** -- JSON-LD keys like `schema:name`, `prov:wasGeneratedBy` are converted to `schema_name`, `prov_wasGeneratedBy` in intermediate XML using regex on element tags.

## Code locations

| What | Where |
|------|-------|
| Docker stack definition | `docker-compose.yml` |
| CDIF broker (main logic) | `cdif-connector/src/main/java/.../cdif/CdifSitemapBroker.java` |
| Connector factory | `cdif-connector/src/main/java/.../cdif/CdifSitemapConnector.java` |
| Config adaptor | `cdif-connector/src/main/java/.../cdif/CdifSitemapDefinitionAdaptor.java` |
| Constants | `cdif-connector/src/main/java/.../cdif/CdifConstants.java` |
| Maven build (shade config) | `cdif-connector/pom.xml` |
| CDIF->ISO XSLT | `xslt/fromJsonCdif.xsl` |
| ISO->schema.org XSLT | `xslt/iso19115-3-to-schemaorg.xsl` |
| Harvester Spring beans | `harvester/hrv-beans.xml` |
| Test sitemaps | `test/cdif-sitemap.xml`, `test/cdif-sitemap-local.xml` |

## Gotchas to watch for

1. Saxon-HE 12.x requires `org.xmlresolver:xmlresolver:5.2.2` at runtime -- without it you get `NoClassDefFoundError: org/xmlresolver/Resolver`.
2. CDIF JSON-LD uses 8+ namespace prefixes (`schema`, `prov`, `dcat`, `dcterms`, `cdi`, `ada`, `spdx`, `xas`). ALL must be normalized to underscores before XSLT processing or Saxon rejects the XML.
3. Harvester task `destinations` must be wrapped in `{"action": {...}}` (LinkDefinition format), not bare EntityDefinition objects.
4. The harvester REST API paths all start with `/rest/harvester/` (e.g., `/rest/harvester/tasks`, not `/rest/tasks`).
5. Passwords posted to the harvester API are auto-scrambled by `TextScrambler.encode()`. Always POST plain text.
6. Dockerfiles pre-expand WARs with `jar xf` so volume mounts work. Mounting into an unexpanded WAR gets overwritten by Tomcat.

## Build prerequisites

The Geoportal Harvester SDK must be installed locally before building the connector:

```bash
git clone https://github.com/Esri/geoportal-server-harvester.git
cd geoportal-server-harvester && git checkout v3.0.0
mvn clean install -DskipTests
```

Use JDK 17+ for building (JDK 11.0.2 has TLS issues with Maven Central).
