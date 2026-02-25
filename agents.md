# agents.md -- Project context for AI coding agents

## What this project is

geoportal-dde is a Docker Compose deployment of [Esri Geoportal Server](https://github.com/Esri/geoportal-server-catalog) customized for the [Deep-time Digital Earth (DDE)](https://www.ddeworld.org/) metadata catalog. It replaces a GeoNetwork 4.4.9 fork where customizations were embedded inside the monolith, requiring 100+ merge conflicts per upstream upgrade.

The key principle: **all DDE customizations are external to the base platform** -- environment variables, volume-mounted XSLTs, and a plugin JAR. The base Geoportal WAR files are unmodified.

## Repository layout

```
geoportal-dde/
├── docker-compose.yml         # Orchestrates the three services
├── catalog/Dockerfile         # Downloads + pre-expands Geoportal Catalog WAR v3.0.2
├── harvester/Dockerfile       # Downloads + pre-expands Geoportal Harvester WAR v3.0.0
├── harvester/hrv-beans.xml    # Spring bean config with CDIF connector registered
├── cdif-connector/            # Custom harvester plugin (Java, Maven)
├── xslt/                      # XSLT transforms (CDIF<->ISO 19115-3<->schema.org)
├── scripts/                   # Migration and verification scripts (bash)
├── test/                      # Test data (sample records, sitemaps)
└── pygeoapi-config.yml        # Future OGC API Records config
```

## Technology stack

| Component | Version | Role |
|-----------|---------|------|
| Elasticsearch | 8.14.3 | Sole datastore for all metadata |
| Geoportal Server Catalog | 3.0.2 | Search UI, editor, CSW 2/3, REST API, metadata profiles |
| Geoportal Server Harvester | 3.0.0 | Scheduled metadata harvesting from external sources |
| Tomcat | 9.x (JDK 11) | Servlet container for both Geoportal WARs |
| Saxon-HE | 12.4 | XSLT 2.0 processor (bundled in CDIF connector JAR) |

## Docker services and ports

| Service | Container name | Host port | Internal port |
|---------|---------------|-----------|---------------|
| Elasticsearch | geoportal-es | 9202 | 9200 |
| Geoportal Catalog | geoportal-catalog | 8082 | 8080 |
| Geoportal Harvester | geoportal-harvester | 8083 | 8080 |
| Kibana (debug profile) | geoportal-kibana | 5601 | 5601 |

Ports are offset to avoid conflicts with other services (GeoNetwork uses 9200/8080).

## Key REST API endpoints

### Catalog

- `GET /geoportal/rest/metadata/search` -- search all records (returns ES response)
- `GET /geoportal/rest/metadata/item/{id}` -- get a single record
- `PUT /geoportal/rest/metadata/item/{id}` -- create/update a record (requires auth)
- `DELETE /geoportal/rest/metadata/item/{id}` -- delete a record (requires auth)
- `GET /geoportal/csw?service=CSW&request=GetCapabilities` -- CSW endpoint

Authentication: HTTP Basic with `gptadmin`/`gptadmin` (simple auth, configurable via `gpt_authentication` env var).

### Harvester

- `GET /harvester/rest/harvester/connectors/inbound` -- list input connector types
- `GET /harvester/rest/harvester/connectors/outbound` -- list output connector types
- `GET /harvester/rest/harvester/brokers` -- list configured brokers
- `POST /harvester/rest/harvester/tasks` -- create a harvest task
- `POST /harvester/rest/harvester/tasks/{id}/execute` -- run a task
- `GET /harvester/rest/harvester/processes` -- list running processes

## The CDIF connector (`cdif-connector/`)

This is the main custom code in the project -- a Geoportal Harvester InputBroker plugin that harvests CDIF JSON-LD metadata from sitemaps.

### How it works

```
Sitemap XML                    JSON-LD documents
    │                               │
    ▼                               ▼
CdifSitemapBroker              CdifSitemapBroker
  .extractUrlsFromSitemap()      .convertJsonLdToIso19115()
    │                               │
    │  JDOM child traversal         │  1. org.json.XML.toString()
    │  (handles sitemapindex        │  2. Normalize keys (schema: -> schema_)
    │   recursion)                  │  3. Inject UUID from SHA-1(@id)
    │                               │  4. Apply fromJsonCdif.xsl (Saxon)
    ▼                               ▼
List<String> urls              byte[] isoXml (ISO 19115-3)
                                    │
                                    ▼
                              SimpleDataReference
                                (published to catalog)
```

### Source files

| File | Purpose |
|------|---------|
| `CdifConstants.java` | Property keys: `CDIF-SITEMAP` type, sitemap URL, XSLT path, record ID path |
| `CdifSitemapConnector.java` | `InputConnector` factory. Builds UI template (3 fields), creates broker instances |
| `CdifSitemapBroker.java` | `InputBroker` implementation. Sitemap parsing, HTTP fetching, JSON-LD conversion, XSLT application |
| `CdifSitemapDefinitionAdaptor.java` | `BrokerDefinitionAdaptor` subclass. Typed getters/setters over the string property map |
| `CdifResource.properties` | UI labels for the harvester web interface |

### Building

Requires the Geoportal Harvester SDK installed locally (one-time setup):

```bash
git clone https://github.com/Esri/geoportal-server-harvester.git
cd geoportal-server-harvester && git checkout v3.0.0
mvn clean install -DskipTests
```

Then build the connector:

```bash
cd cdif-connector
mvn clean package
```

Produces a shaded JAR (~5.8 MB) at `target/geoportal-harvester-cdif-sitemap-1.0.0.jar` that bundles JDOM2, org.json, and Saxon-HE.

The shade plugin `<filters>` section excludes:
- `META-INF/*.SF`, `*.DSA`, `*.RSA` -- JAR signature files that cause `Invalid signature file digest` errors in Tomcat
- `META-INF/services/javax.xml.transform.TransformerFactory` -- Saxon's SPI registration that would override the JVM's default Xalan processor, breaking the harvester's built-in `SimpleArcGISMetaAnalyzer` and other beans that call `TransformerFactory.newInstance()`. Our code uses `new TransformerFactoryImpl()` directly so the SPI is not needed.

### Important implementation details

- **`BrokerDefinitionAdaptor`** has `protected final get()/set()` methods -- do NOT redeclare them in subclasses
- **`BrokerDefinitionAdaptor`** requires implementing `abstract void override(Map<String,String>)` using the `consume()` helper
- **`InputBroker.hasAccess()`** takes `SimpleCredentials`, not `SimpleAccessList`
- **`InputBroker.readContent()`** returns `DataContent`, not `DataReference`
- **`InputBroker.getBrokerUri()`** throws `URISyntaxException`, not `DataProcessorException`
- **`SimpleDataReference`** is constructed with 7 args (brokerUri, brokerName, id, lastModifiedDate, sourceUri, inputBrokerRef, taskRef) then content is added via `addContext(MimeType, byte[])`
- Maven artifact IDs differ from directory names: `harvester-api` (not `geoportal-harvester-api`), `commons-utils` (not `geoportal-commons-utils`)

## XSLT transforms

### `xslt/fromJsonCdif.xsl`

Converts CDIF JSON-LD intermediate XML to ISO 19115-3 `mdb:MD_Metadata`. This is a direct copy from the GeoNetwork fork (`iso19115-3.2018/convert/fromJsonCdif.xsl`), ~715 lines, XSLT 2.0. Proven with 77 CDIF records.

Input is not raw JSON-LD but an intermediate XML produced by `org.json.XML.toString()` with key normalization applied:
- `schema:name` -> `schema_name`
- `@id` -> `id`
- `@type` -> `type`
- A `<uuid>` element is injected with a SHA-1 hash of the `@id` value

### `xslt/iso19115-3-to-schemaorg.xsl`

Reverse transform: ISO 19115-3 XML -> schema.org JSON-LD text output. ~324 lines, XSLT 2.0.

## Catalog configuration

The Geoportal Catalog is configured through **environment variables** in `docker-compose.yml`, not by replacing config files. The `app-context.xml` inside the WAR uses Spring `${variable:default}` placeholders:

| Variable | Default | Used for |
|----------|---------|----------|
| `es_node` | (empty) | Elasticsearch hostname (just the hostname, not a URL) |
| `gpt_indexName` | `metadata` | ES index name |
| `harvester_node` | (empty) | Harvester URL |
| `gpt_authentication` | `authentication-simple.xml` | Auth config file |
| `gpt_engineType` | `opensearch` | ES engine type (`opensearch` or `elasticsearch`) |

**Do not volume-mount `app-context.xml`** -- this breaks the Spring context because it imports security, factory, and DCAT configs that must be present.

## Harvester configuration

The harvester registers connectors via Spring beans in `hrv-beans.xml` (imported by `hrv-context.xml`). To add the CDIF connector:

1. Mount the custom `hrv-beans.xml` (which adds a `CdifSitemapConnector` bean)
2. Mount the connector JAR into `WEB-INF/lib/`
3. Mount the XSLT into the classpath

Harvest tasks are configured at runtime through the harvester UI or REST API, not config files. The `hrv-config.xml` in this repo is unused (legacy from initial development).

## Common tasks

### Upload a metadata record

```bash
curl -X PUT -u gptadmin:gptadmin \
  -H "Content-Type: application/xml" \
  -d @test/sample-iso19115-3.xml \
  http://localhost:8082/geoportal/rest/metadata/item/my-record-id
```

### Search records

```bash
curl http://localhost:8082/geoportal/rest/metadata/search
curl http://localhost:8082/geoportal/rest/metadata/search?q=geology
```

### Check ES index

```bash
curl http://localhost:9202/metadata_v1/_count
curl http://localhost:9202/metadata_v1/_search?pretty&size=1
```

### Rebuild harvester after connector changes

```bash
cd cdif-connector && mvn clean package
docker compose up -d geoportal-harvester --force-recreate
```

### View container logs

```bash
docker compose logs -f geoportal-catalog
docker compose logs -f geoportal-harvester
docker compose logs -f elasticsearch
```

## Known issues and gotchas

1. **Catalog `app-context.xml` must not be replaced** -- it imports security config. Use env vars instead.
2. **`es_node` is a hostname, not a URL** -- setting it to `http://elasticsearch:9200` causes `UnknownHostException: http`.
3. **Shaded JARs need signature stripping** -- Saxon-HE is signed; the shade plugin `<filters>` section excludes `META-INF/*.SF`, `*.DSA`, `*.RSA`.
4. **Saxon SPI must be excluded from the shaded JAR** -- Saxon-HE registers itself as the default `TransformerFactory` via `META-INF/services/javax.xml.transform.TransformerFactory`. If present, it replaces the JVM's Xalan and breaks the harvester's `SimpleArcGISMetaAnalyzer` with `TransformerFactoryConfigurationError`. Our code calls Saxon's `TransformerFactoryImpl` directly, so the SPI file must be excluded.
5. **Harvester SDK needs JDK 17+** to build (JDK 11.0.2 has TLS issues downloading from Maven Central). JDK 20 confirmed working.
6. **Port conflicts** -- default ports (9200, 8080) likely conflict with other services. Current mapping: ES=9202, Catalog=8082, Harvester=8083.
7. **Dockerfiles pre-expand WARs** with `jar xf` so that volume mounts targeting files inside the WAR work correctly. Mounting files into an unexpanded WAR doesn't work because Tomcat expands the WAR after container start, overwriting the mount.

## Migration context

This project replaces a GeoNetwork 4.4.9 fork (the `DDEconfig` branch in the `core-geonetwork` repo). The fork had ~15 custom files embedded in a 40-module Java monolith. Key pain points:
- Merging upstream tag `4.4.9` required resolving 100+ conflicts
- 200+ `-SMR-Samsung` backup files from manual merges
- Custom Java patches to core classes (EsSearchManager, XslUtil, BaseMetadataIndexer)
- Full Maven build of all 40 modules required for any change

Geoportal Server was chosen because:
- ISO 19115-3 is built-in (no custom profile code)
- ES 8.x works natively (no compatibility patches)
- Customizations are profiles and plugins in their own directories
- Simpler architecture (2 WARs + ES, no PostgreSQL)
