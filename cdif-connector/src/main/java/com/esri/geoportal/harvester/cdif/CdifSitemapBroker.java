/*
 * CDIF Sitemap InputBroker.
 *
 * Follows sitemaps.org protocol to discover CDIF JSON-LD metadata:
 * 1. Fetch sitemap XML
 * 2. Extract <loc> URLs via JDOM child traversal (ported from GeoNetwork)
 * 3. For each URL: fetch JSON-LD, convert to intermediate XML, apply fromJsonCdif.xsl
 * 4. Yield ISO 19115-3 XML as Publishable DataReference
 */
package com.esri.geoportal.harvester.cdif;

import com.esri.geoportal.commons.constants.MimeType;
import com.esri.geoportal.commons.utils.SimpleCredentials;
import com.esri.geoportal.harvester.api.DataContent;
import com.esri.geoportal.harvester.api.DataReference;
import com.esri.geoportal.harvester.api.base.SimpleDataReference;
import com.esri.geoportal.harvester.api.defs.EntityDefinition;
import com.esri.geoportal.harvester.api.ex.DataInputException;
import com.esri.geoportal.harvester.api.ex.DataProcessorException;
import com.esri.geoportal.harvester.api.specs.InputBroker;
import com.esri.geoportal.harvester.api.specs.InputConnector;

import net.sf.saxon.TransformerFactoryImpl;

import org.jdom2.Document;
import org.jdom2.Element;
import org.jdom2.input.SAXBuilder;

import org.json.JSONObject;
import org.json.XML;

import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClientBuilder;
import org.apache.http.impl.client.LaxRedirectStrategy;
import org.apache.http.util.EntityUtils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.xml.transform.*;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import java.io.*;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.*;

/**
 * CDIF Sitemap InputBroker implementation.
 *
 * Ported from GeoNetwork's simpleurl.Harvester:
 * - extractUrlsFromSitemap() : direct JDOM child traversal
 * - collectSingleJsonRecord() : JSON -> intermediate XML -> XSLT
 * - UUID generation from @id via SHA-1
 */
public class CdifSitemapBroker implements InputBroker {

    private static final Logger LOG = LoggerFactory.getLogger(CdifSitemapBroker.class);

    private final CdifSitemapConnector connector;
    private final CdifSitemapDefinitionAdaptor definition;

    private CloseableHttpClient httpClient;
    private Templates xsltTemplates;

    /** Stored during initialize() for use in DataReference construction. */
    private String inputBrokerRef;
    private String taskRef;

    public CdifSitemapBroker(CdifSitemapConnector connector,
                              CdifSitemapDefinitionAdaptor definition) {
        this.connector = connector;
        this.definition = definition;
    }

    @Override
    public void initialize(InitContext context) throws DataProcessorException {
        // Apply runtime parameter overrides
        definition.override(context.getParams());

        // Store task/broker refs for DataReference construction
        if (context.getTask() != null && context.getTask().getTaskDefinition() != null) {
            this.taskRef = context.getTask().getTaskDefinition().getRef();
            if (context.getTask().getTaskDefinition().getSource() != null) {
                this.inputBrokerRef = context.getTask().getTaskDefinition()
                    .getSource().getRef();
            }
        }

        // Create HTTP client with redirect support (matching WAF broker pattern)
        this.httpClient = HttpClientBuilder.create()
            .useSystemProperties()
            .setRedirectStrategy(LaxRedirectStrategy.INSTANCE)
            .setUserAgent("GeoportalHarvester-CDIF/1.0")
            .build();

        // Pre-compile the XSLT template for performance
        try {
            String xsltPath = definition.getXsltPath();
            TransformerFactory factory = new TransformerFactoryImpl();

            // Try classpath first, then filesystem
            InputStream xsltStream = getClass().getClassLoader()
                .getResourceAsStream(xsltPath);
            if (xsltStream == null) {
                File xsltFile = new File(xsltPath);
                if (xsltFile.exists()) {
                    xsltStream = new FileInputStream(xsltFile);
                }
            }
            if (xsltStream == null) {
                throw new DataProcessorException(
                    "XSLT not found: " + xsltPath);
            }

            this.xsltTemplates = factory.newTemplates(
                new StreamSource(xsltStream));
            xsltStream.close();

            LOG.info("CDIF Sitemap broker initialized. Sitemap: {}",
                definition.getSitemapUrl());
        } catch (DataProcessorException e) {
            throw e;
        } catch (Exception e) {
            throw new DataProcessorException(
                "Failed to initialize XSLT: " + e.getMessage(), e);
        }
    }

    @Override
    public void terminate() {
        if (httpClient != null) {
            try {
                httpClient.close();
            } catch (IOException e) {
                LOG.error("Error terminating broker.", e);
            }
        }
    }

    @Override
    public URI getBrokerUri() throws URISyntaxException {
        try {
            return new URI("CDIF", definition.getSitemapUrl().toExternalForm(), null);
        } catch (java.net.MalformedURLException e) {
            throw new URISyntaxException(
                definition.getEntityDefinition().getProperties()
                    .getOrDefault(CdifConstants.P_SITEMAP_URL, ""),
                "Invalid sitemap URL: " + e.getMessage());
        }
    }

    @Override
    public Iterator iterator(IteratorContext iteratorContext)
            throws DataInputException {
        try {
            // 1. Fetch the sitemap XML
            String sitemapContent = httpGet(definition.getSitemapUrl().toExternalForm());

            // 2. Extract all <loc> URLs using JDOM child traversal
            //    (ported from GeoNetwork Harvester.java:479-505)
            List<String> urls = extractUrlsFromSitemap(sitemapContent);
            LOG.info("Found {} URLs in sitemap", urls.size());

            // 3. Return an iterator that fetches and converts each record
            return new CdifIterator(urls, iteratorContext);

        } catch (Exception e) {
            throw new DataInputException(this, "Failed to read sitemap", e);
        }
    }

    @Override
    public DataContent readContent(String id) throws DataInputException {
        // Not used in iterator-based harvesting; return null per API contract
        return null;
    }

    @Override
    public EntityDefinition getEntityDefinition() {
        return definition.getEntityDefinition();
    }

    @Override
    public InputConnector getConnector() {
        return connector;
    }

    @Override
    public boolean hasAccess(SimpleCredentials creds) {
        // No credentials required — sitemap URLs are public
        return true;
    }

    // =========================================================================
    // Sitemap parsing — ported from GeoNetwork Harvester.java:479-505
    // =========================================================================

    /**
     * Extract all URLs from a sitemap XML document.
     * Uses direct JDOM child traversal to avoid XPath issues with
     * detached elements. Handles both namespaced and non-namespaced
     * sitemap elements.
     *
     * @param content raw XML string of the sitemap
     * @return list of URL strings from &lt;loc&gt; elements
     */
    List<String> extractUrlsFromSitemap(String content) throws Exception {
        List<String> urls = new ArrayList<>();
        SAXBuilder builder = new SAXBuilder();
        // Disable external entities for security
        builder.setFeature(
            "http://apache.org/xml/features/disallow-doctype-decl", true);
        Document doc = builder.build(new StringReader(content));
        Element root = doc.getRootElement();

        // Handle sitemap index: if root is <sitemapindex>, recurse
        if ("sitemapindex".equals(root.getName())) {
            for (Object child : root.getChildren()) {
                if (child instanceof Element) {
                    Element sitemapEl = (Element) child;
                    if ("sitemap".equals(sitemapEl.getName())) {
                        for (Object locChild : sitemapEl.getChildren()) {
                            if (locChild instanceof Element) {
                                Element locEl = (Element) locChild;
                                if ("loc".equals(locEl.getName())) {
                                    String subSitemapUrl = locEl.getTextTrim();
                                    if (subSitemapUrl != null && !subSitemapUrl.isEmpty()) {
                                        LOG.info("Following sitemap index entry: {}",
                                            subSitemapUrl);
                                        String subContent = httpGet(subSitemapUrl);
                                        urls.addAll(extractUrlsFromSitemap(subContent));
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return urls;
        }

        // Standard sitemap: extract <url>/<loc> elements
        for (Object child : root.getChildren()) {
            if (child instanceof Element) {
                Element urlElement = (Element) child;
                if ("url".equals(urlElement.getName())) {
                    for (Object locChild : urlElement.getChildren()) {
                        if (locChild instanceof Element) {
                            Element locElement = (Element) locChild;
                            if ("loc".equals(locElement.getName())) {
                                String locText = locElement.getTextTrim();
                                if (locText != null && !locText.isEmpty()) {
                                    urls.add(locText);
                                }
                            }
                        }
                    }
                }
            }
        }
        return urls;
    }

    // =========================================================================
    // JSON-LD to ISO 19115-3 conversion
    // =========================================================================

    /**
     * Fetch JSON-LD from a URL, convert to ISO 19115-3 XML via XSLT.
     *
     * Flow (ported from GeoNetwork Harvester):
     * 1. HTTP GET the JSON-LD URL
     * 2. Parse as JSONObject
     * 3. Convert to intermediate XML using org.json.XML
     *    (schema:name -> schema_name, @id -> id, @type -> type)
     * 4. Inject UUID element
     * 5. Apply fromJsonCdif.xsl -> ISO 19115-3 mdb:MD_Metadata
     */
    byte[] convertJsonLdToIso19115(String jsonLdUrl) throws Exception {
        // 1. Fetch JSON-LD
        String jsonContent = httpGet(jsonLdUrl);

        // 2. Parse JSON
        JSONObject jsonObj = new JSONObject(jsonContent);

        // 3. Convert JSON to intermediate XML
        // Replaces special chars: "schema:name" -> "schema_name", "@id" -> "id"
        String intermediateXml = XML.toString(jsonObj, "record");

        // Normalize key names in XML element names:
        // - Replace namespace colons with underscores in tags
        //   (schema:name -> schema_name, prov:wasGeneratedBy -> prov_wasGeneratedBy, etc.)
        // - Remove @ prefix from element names (@id -> id, @type -> type)
        intermediateXml = intermediateXml
            .replaceAll("<([a-zA-Z]+):", "<$1_")
            .replaceAll("</([a-zA-Z]+):", "</$1_")
            .replaceAll("<@", "<")
            .replaceAll("</@", "</");

        // 4. Generate UUID from @id field (or URL as fallback)
        String recordId = jsonObj.optString("@id", jsonLdUrl);
        String uuid = sha1(recordId);

        // Inject <uuid> element right after <record>
        intermediateXml = intermediateXml.replaceFirst(
            "(<record>)", "$1<uuid>" + uuid + "</uuid>");

        // 5. Apply XSLT
        Transformer transformer = xsltTemplates.newTransformer();
        StringWriter result = new StringWriter();
        transformer.transform(
            new StreamSource(new StringReader(intermediateXml)),
            new StreamResult(result));

        return result.toString().getBytes(StandardCharsets.UTF_8);
    }

    // =========================================================================
    // Utility methods
    // =========================================================================

    /**
     * HTTP GET with basic error handling.
     */
    String httpGet(String url) throws IOException {
        HttpGet request = new HttpGet(url);
        request.addHeader("Accept",
            "application/json, application/ld+json, application/xml, text/xml");
        try (CloseableHttpResponse response = httpClient.execute(request)) {
            int status = response.getStatusLine().getStatusCode();
            if (status < 200 || status >= 300) {
                throw new IOException(
                    "HTTP " + status + " from " + url);
            }
            return EntityUtils.toString(response.getEntity(),
                StandardCharsets.UTF_8);
        }
    }

    /**
     * SHA-1 hash of a string, returned as hex.
     * Used to generate stable UUIDs from @id fields.
     */
    static String sha1(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-1");
            byte[] hash = md.digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder();
            for (byte b : hash) {
                hex.append(String.format("%02x", b));
            }
            return hex.toString();
        } catch (Exception e) {
            // SHA-1 is always available in standard JDK
            throw new RuntimeException("SHA-1 not available", e);
        }
    }

    // =========================================================================
    // Inner iterator class
    // =========================================================================

    /**
     * Iterator that walks the sitemap URL list, fetching and converting
     * each JSON-LD record to ISO 19115-3 XML.
     */
    private class CdifIterator implements InputBroker.Iterator {

        private final List<String> urls;
        private final IteratorContext context;
        private int index = 0;
        private int successCount = 0;
        private int errorCount = 0;

        CdifIterator(List<String> urls, IteratorContext context) {
            this.urls = urls;
            this.context = context;
        }

        @Override
        public boolean hasNext() throws DataInputException {
            return index < urls.size();
        }

        @Override
        public DataReference next() throws DataInputException {
            String url = urls.get(index++);
            try {
                byte[] isoXml = convertJsonLdToIso19115(url);
                String uuid = sha1(url);
                successCount++;

                LOG.info("Converted record {}/{}: {} (uuid={})",
                    index, urls.size(), url, uuid.substring(0, 8));

                // Construct SimpleDataReference per the actual API:
                // (URI brokerUri, String brokerName, String id,
                //  Date lastModifiedDate, URI sourceUri,
                //  String inputBrokerRef, String taskRef)
                SimpleDataReference ref = new SimpleDataReference(
                    getBrokerUri(),
                    getEntityDefinition().getLabel(),
                    uuid,
                    new Date(),
                    new URI(url),
                    inputBrokerRef,
                    taskRef
                );

                // Add XML content via addContext (not constructor)
                ref.addContext(MimeType.APPLICATION_XML, isoXml);

                return ref;

            } catch (Exception e) {
                errorCount++;
                LOG.error("Failed to convert record {}/{}: {} - {}",
                    index, urls.size(), url, e.getMessage());
                // Skip this record and try the next one instead of
                // aborting the entire harvest
                if (hasNext()) {
                    LOG.warn("Skipping failed record, continuing with next...");
                    return next();
                }
                throw new DataInputException(CdifSitemapBroker.this,
                    "Failed to process " + url, e);
            }
        }
    }
}
