/*
 * CDIF Sitemap Harvester Connector - Configuration property keys.
 */
package com.esri.geoportal.harvester.cdif;

/**
 * Property key constants for CDIF sitemap connector configuration.
 */
public final class CdifConstants {

    /** Connector type identifier, used in Spring bean registration. */
    public static final String TYPE = "CDIF-SITEMAP";

    /** URL of the sitemap XML to crawl. */
    public static final String P_SITEMAP_URL = "cdif-sitemap-url";

    /** Classpath or filesystem path to the CDIF-to-ISO 19115-3 XSLT. */
    public static final String P_XSLT_PATH = "cdif-xslt-path";

    /** JSONPath expression to extract the record identifier (default: /@id). */
    public static final String P_RECORD_ID_PATH = "cdif-record-id-path";

    private CdifConstants() {}
}
