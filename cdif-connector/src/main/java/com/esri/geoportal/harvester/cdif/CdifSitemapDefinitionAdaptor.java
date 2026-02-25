/*
 * CDIF Sitemap Harvester Connector - Definition adaptor.
 * Wraps EntityDefinition (a string map) with typed accessors.
 */
package com.esri.geoportal.harvester.cdif;

import com.esri.geoportal.harvester.api.defs.EntityDefinition;
import com.esri.geoportal.harvester.api.base.BrokerDefinitionAdaptor;
import com.esri.geoportal.harvester.api.ex.InvalidDefinitionException;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.Map;

/**
 * Typed configuration adaptor for the CDIF sitemap connector.
 *
 * Extends BrokerDefinitionAdaptor which provides:
 * - protected final String get(String propertyName)
 * - protected final void set(String propertyName, String propertyValue)
 * - EntityDefinition getEntityDefinition()
 */
public class CdifSitemapDefinitionAdaptor extends BrokerDefinitionAdaptor {

    /** Default XSLT path (inside the WAR classpath). */
    public static final String DEFAULT_XSLT_PATH = "xslt/fromJsonCdif.xsl";

    /** Default JSONPath for record ID. */
    public static final String DEFAULT_RECORD_ID_PATH = "/@id";

    /**
     * Construct adaptor and validate the definition has a sitemap URL.
     */
    public CdifSitemapDefinitionAdaptor(EntityDefinition ed)
            throws InvalidDefinitionException {
        super(ed);
        if (ed.getType() == null || ed.getType().isEmpty()) {
            ed.setType(CdifConstants.TYPE);
        }
    }

    /**
     * Required by BrokerDefinitionAdaptor: merge runtime parameters
     * into this definition (called during initialize).
     */
    @Override
    public void override(Map<String, String> params) {
        consume(params, CdifConstants.P_SITEMAP_URL);
        consume(params, CdifConstants.P_XSLT_PATH);
        consume(params, CdifConstants.P_RECORD_ID_PATH);
    }

    /**
     * Get the sitemap URL to crawl.
     */
    public URL getSitemapUrl() throws MalformedURLException {
        String val = get(CdifConstants.P_SITEMAP_URL);
        return val != null && !val.isEmpty() ? new URL(val) : null;
    }

    public void setSitemapUrl(URL url) {
        set(CdifConstants.P_SITEMAP_URL, url != null ? url.toExternalForm() : null);
    }

    /**
     * Get the path to the CDIF-to-ISO 19115-3 XSLT.
     */
    public String getXsltPath() {
        String val = get(CdifConstants.P_XSLT_PATH);
        return val != null && !val.isEmpty() ? val : DEFAULT_XSLT_PATH;
    }

    public void setXsltPath(String path) {
        set(CdifConstants.P_XSLT_PATH, path);
    }

    /**
     * Get the JSONPath expression for extracting the record identifier.
     */
    public String getRecordIdPath() {
        String val = get(CdifConstants.P_RECORD_ID_PATH);
        return val != null && !val.isEmpty() ? val : DEFAULT_RECORD_ID_PATH;
    }

    public void setRecordIdPath(String path) {
        set(CdifConstants.P_RECORD_ID_PATH, path);
    }
}
