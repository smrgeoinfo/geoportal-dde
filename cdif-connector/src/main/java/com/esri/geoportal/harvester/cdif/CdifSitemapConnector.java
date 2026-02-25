/*
 * CDIF Sitemap Harvester Connector.
 * Factory that creates CdifSitemapBroker instances and defines the UI template.
 */
package com.esri.geoportal.harvester.cdif;

import com.esri.geoportal.harvester.api.defs.EntityDefinition;
import com.esri.geoportal.harvester.api.defs.UITemplate;
import com.esri.geoportal.harvester.api.ex.InvalidDefinitionException;
import com.esri.geoportal.harvester.api.specs.InputBroker;
import com.esri.geoportal.harvester.api.specs.InputConnector;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.ResourceBundle;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Connector factory for the CDIF Sitemap InputBroker.
 * Registered as a Spring bean in hrv-beans.xml.
 *
 * Follows the same pattern as WafConnector:
 * - getType() returns unique type string
 * - getTemplate() builds UI form arguments
 * - validateDefinition() constructs the adaptor (which validates)
 * - createBroker() returns a new CdifSitemapBroker
 */
public class CdifSitemapConnector implements InputConnector<InputBroker> {

    private static final Logger LOG = LoggerFactory.getLogger(CdifSitemapConnector.class);

    @Override
    public String getType() {
        return CdifConstants.TYPE;
    }

    @Override
    public UITemplate getTemplate(Locale locale) {
        ResourceBundle bundle;
        try {
            bundle = ResourceBundle.getBundle(
                "com.esri.geoportal.harvester.cdif.CdifResource", locale);
        } catch (Exception e) {
            bundle = ResourceBundle.getBundle(
                "com.esri.geoportal.harvester.cdif.CdifResource");
        }

        List<UITemplate.Argument> args = new ArrayList<>();

        // Sitemap URL (required)
        args.add(new UITemplate.StringArgument(
            CdifConstants.P_SITEMAP_URL,
            bundle.getString("cdif.sitemap.url.label"),
            true) {
            @Override
            public String getHint() {
                return bundle.getString("cdif.sitemap.url.hint");
            }
        });

        // XSLT path (optional, has default)
        args.add(new UITemplate.StringArgument(
            CdifConstants.P_XSLT_PATH,
            bundle.getString("cdif.xslt.path.label"),
            false) {
            @Override
            public String getHint() {
                return bundle.getString("cdif.xslt.path.hint");
            }
        });

        // Record ID JSONPath (optional, has default)
        args.add(new UITemplate.StringArgument(
            CdifConstants.P_RECORD_ID_PATH,
            bundle.getString("cdif.recordid.path.label"),
            false) {
            @Override
            public String getHint() {
                return bundle.getString("cdif.recordid.path.hint");
            }
        });

        return new UITemplate(getType(),
            bundle.getString("cdif.connector.label"),
            args);
    }

    @Override
    public void validateDefinition(EntityDefinition definition)
            throws InvalidDefinitionException {
        // Constructing the adaptor validates required fields
        new CdifSitemapDefinitionAdaptor(definition);
    }

    @Override
    public InputBroker createBroker(EntityDefinition definition)
            throws InvalidDefinitionException {
        return new CdifSitemapBroker(this,
            new CdifSitemapDefinitionAdaptor(definition));
    }

    @Override
    public String getResourceLocator(EntityDefinition definition) {
        try {
            CdifSitemapDefinitionAdaptor adaptor =
                new CdifSitemapDefinitionAdaptor(definition);
            return adaptor.getSitemapUrl() != null
                ? adaptor.getSitemapUrl().toExternalForm() : "";
        } catch (Exception e) {
            return "";
        }
    }
}
