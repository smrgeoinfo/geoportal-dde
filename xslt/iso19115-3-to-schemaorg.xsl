<?xml version="1.0" encoding="UTF-8"?>
<!--
  ISO 19115-3 to schema.org/CDIF JSON-LD conversion.
  Reverse of fromJsonCdif.xsl: maps ISO 19115-3 (mdb:MD_Metadata) fields
  back to schema.org Dataset vocabulary as JSON-LD.

  Output: JSON-LD text (XSLT 2.0 text output method).

  Field mapping:
    mdb:metadataIdentifier → @id (as UUID-based URI)
    mri:citation/cit:title → schema:name
    mri:abstract → schema:description
    mri:pointOfContact → schema:creator
    mri:descriptiveKeywords → schema:keywords
    mco:MD_LegalConstraints → schema:license
    gex:EX_GeographicBoundingBox → schema:spatialCoverage
    mrd:MD_Distribution → schema:distribution
    cit:date → schema:datePublished / schema:dateModified
-->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:mdb="http://standards.iso.org/iso/19115/-3/mdb/2.0"
                xmlns:mri="http://standards.iso.org/iso/19115/-3/mri/1.0"
                xmlns:mrd="http://standards.iso.org/iso/19115/-3/mrd/1.0"
                xmlns:mco="http://standards.iso.org/iso/19115/-3/mco/1.0"
                xmlns:mcc="http://standards.iso.org/iso/19115/-3/mcc/1.0"
                xmlns:mrl="http://standards.iso.org/iso/19115/-3/mrl/1.0"
                xmlns:cit="http://standards.iso.org/iso/19115/-3/cit/2.0"
                xmlns:gex="http://standards.iso.org/iso/19115/-3/gex/1.0"
                xmlns:lan="http://standards.iso.org/iso/19115/-3/lan/1.0"
                xmlns:gco="http://standards.iso.org/iso/19115/-3/gco/1.0"
                xmlns:gml="http://www.opengis.net/gml/3.2"
                exclude-result-prefixes="#all">

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:strip-space elements="*"/>

  <!-- Helper: escape JSON string values -->
  <xsl:template name="escapeJson">
    <xsl:param name="text"/>
    <xsl:variable name="step1" select="replace($text, '\\', '\\\\')"/>
    <xsl:variable name="step2" select="replace($step1, '&quot;', '\\&quot;')"/>
    <xsl:variable name="step3" select="replace($step2, '&#10;', '\\n')"/>
    <xsl:variable name="step4" select="replace($step3, '&#13;', '\\r')"/>
    <xsl:variable name="step5" select="replace($step4, '&#9;', '\\t')"/>
    <xsl:value-of select="$step5"/>
  </xsl:template>

  <!-- Root template -->
  <xsl:template match="/mdb:MD_Metadata">
    <!-- Collect values -->
    <xsl:variable name="fileId"
      select="mdb:metadataIdentifier/mcc:MD_Identifier/mcc:code/gco:CharacterString"/>
    <xsl:variable name="title"
      select="mdb:identificationInfo/mri:MD_DataIdentification/mri:citation/cit:CI_Citation/cit:title/gco:CharacterString"/>
    <xsl:variable name="abstract"
      select="mdb:identificationInfo/mri:MD_DataIdentification/mri:abstract/gco:CharacterString"/>
    <xsl:variable name="scopeCode"
      select="mdb:metadataScope/mdb:MD_MetadataScope/mdb:resourceScope/mcc:MD_ScopeCode/@codeListValue"/>

    <!-- Map scope code back to schema.org @type -->
    <xsl:variable name="schemaType">
      <xsl:choose>
        <xsl:when test="$scopeCode = 'service'">schema:Service</xsl:when>
        <xsl:when test="$scopeCode = 'software'">schema:SoftwareApplication</xsl:when>
        <xsl:otherwise>schema:Dataset</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Publication date -->
    <xsl:variable name="pubDate"
      select="mdb:identificationInfo/mri:MD_DataIdentification/mri:citation/cit:CI_Citation/cit:date/cit:CI_Date[cit:dateType/cit:CI_DateTypeCode/@codeListValue='publication']/cit:date/gco:DateTime"/>

    <!-- Begin JSON-LD output -->
    <xsl:text>{
  "@context": {
    "schema": "https://schema.org/",
    "xsd": "http://www.w3.org/2001/XMLSchema#"
  },
  "@type": "</xsl:text>
    <xsl:value-of select="$schemaType"/>
    <xsl:text>",
  "@id": "</xsl:text>
    <xsl:call-template name="escapeJson"><xsl:with-param name="text" select="$fileId"/></xsl:call-template>
    <xsl:text>",
  "schema:name": "</xsl:text>
    <xsl:call-template name="escapeJson"><xsl:with-param name="text" select="$title"/></xsl:call-template>
    <xsl:text>"</xsl:text>

    <!-- Description -->
    <xsl:if test="$abstract != '' and $abstract != $title">
      <xsl:text>,
  "schema:description": "</xsl:text>
      <xsl:call-template name="escapeJson"><xsl:with-param name="text" select="$abstract"/></xsl:call-template>
      <xsl:text>"</xsl:text>
    </xsl:if>

    <!-- Publication date -->
    <xsl:if test="$pubDate != ''">
      <xsl:text>,
  "schema:datePublished": "</xsl:text>
      <xsl:value-of select="$pubDate"/>
      <xsl:text>"</xsl:text>
    </xsl:if>

    <!-- Metadata modification date -->
    <xsl:variable name="metaDate"
      select="mdb:dateInfo/cit:CI_Date[cit:dateType/cit:CI_DateTypeCode/@codeListValue='revision']/cit:date/gco:DateTime"/>
    <xsl:if test="$metaDate != ''">
      <xsl:text>,
  "schema:dateModified": "</xsl:text>
      <xsl:value-of select="$metaDate"/>
      <xsl:text>"</xsl:text>
    </xsl:if>

    <!-- Resource identifier (DOI) -->
    <xsl:variable name="resId"
      select="mdb:identificationInfo/mri:MD_DataIdentification/mri:citation/cit:CI_Citation/cit:identifier/mcc:MD_Identifier"/>
    <xsl:if test="$resId">
      <xsl:text>,
  "schema:identifier": </xsl:text>
      <xsl:choose>
        <xsl:when test="$resId/mcc:codeSpace/gco:CharacterString != ''">
          <xsl:text>{
    "@type": "schema:PropertyValue",
    "schema:propertyID": "</xsl:text>
          <xsl:call-template name="escapeJson">
            <xsl:with-param name="text" select="$resId/mcc:codeSpace/gco:CharacterString"/>
          </xsl:call-template>
          <xsl:text>",
    "schema:value": "</xsl:text>
          <xsl:call-template name="escapeJson">
            <xsl:with-param name="text" select="$resId/mcc:code/gco:CharacterString"/>
          </xsl:call-template>
          <xsl:text>"
  }</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>"</xsl:text>
          <xsl:call-template name="escapeJson">
            <xsl:with-param name="text" select="$resId/mcc:code/gco:CharacterString"/>
          </xsl:call-template>
          <xsl:text>"</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

    <!-- Creators -->
    <xsl:variable name="creators"
      select="mdb:identificationInfo/mri:MD_DataIdentification/mri:pointOfContact/cit:CI_Responsibility"/>
    <xsl:if test="$creators">
      <xsl:text>,
  "schema:creator": [</xsl:text>
      <xsl:for-each select="$creators">
        <xsl:if test="position() > 1"><xsl:text>,</xsl:text></xsl:if>
        <xsl:text>
    {</xsl:text>
        <xsl:choose>
          <xsl:when test="cit:party/cit:CI_Organisation">
            <xsl:text>
      "@type": "schema:Organization",
      "schema:name": "</xsl:text>
            <xsl:call-template name="escapeJson">
              <xsl:with-param name="text" select="cit:party/cit:CI_Organisation/cit:name/gco:CharacterString"/>
            </xsl:call-template>
            <xsl:text>"</xsl:text>
            <xsl:if test="cit:party/cit:CI_Organisation/cit:partyIdentifier/mcc:MD_Identifier/mcc:code/gco:CharacterString != ''">
              <xsl:text>,
      "schema:identifier": "</xsl:text>
              <xsl:call-template name="escapeJson">
                <xsl:with-param name="text" select="cit:party/cit:CI_Organisation/cit:partyIdentifier/mcc:MD_Identifier/mcc:code/gco:CharacterString"/>
              </xsl:call-template>
              <xsl:text>"</xsl:text>
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>
      "@type": "schema:Person",
      "schema:name": "</xsl:text>
            <xsl:call-template name="escapeJson">
              <xsl:with-param name="text" select="cit:party/cit:CI_Individual/cit:name/gco:CharacterString"/>
            </xsl:call-template>
            <xsl:text>"</xsl:text>
            <xsl:if test="cit:party/cit:CI_Individual/cit:partyIdentifier/mcc:MD_Identifier/mcc:code/gco:CharacterString != ''">
              <xsl:text>,
      "schema:identifier": "</xsl:text>
              <xsl:call-template name="escapeJson">
                <xsl:with-param name="text" select="cit:party/cit:CI_Individual/cit:partyIdentifier/mcc:MD_Identifier/mcc:code/gco:CharacterString"/>
              </xsl:call-template>
              <xsl:text>"</xsl:text>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>
    }</xsl:text>
      </xsl:for-each>
      <xsl:text>
  ]</xsl:text>
    </xsl:if>

    <!-- Keywords -->
    <xsl:variable name="allKeywords"
      select="mdb:identificationInfo/mri:MD_DataIdentification/mri:descriptiveKeywords/mri:MD_Keywords/mri:keyword/gco:CharacterString[. != '']"/>
    <xsl:if test="$allKeywords">
      <xsl:text>,
  "schema:keywords": [</xsl:text>
      <xsl:for-each select="$allKeywords">
        <xsl:if test="position() > 1"><xsl:text>, </xsl:text></xsl:if>
        <xsl:text>"</xsl:text>
        <xsl:call-template name="escapeJson"><xsl:with-param name="text" select="."/></xsl:call-template>
        <xsl:text>"</xsl:text>
      </xsl:for-each>
      <xsl:text>]</xsl:text>
    </xsl:if>

    <!-- License -->
    <xsl:variable name="legalConstraints"
      select="mdb:identificationInfo/mri:MD_DataIdentification/mri:resourceConstraints/mco:MD_LegalConstraints"/>
    <xsl:if test="$legalConstraints/mco:reference/cit:CI_Citation">
      <xsl:text>,
  "schema:license": </xsl:text>
      <xsl:variable name="licenseUrl"
        select="$legalConstraints/mco:reference/cit:CI_Citation/cit:onlineResource/cit:CI_OnlineResource/cit:linkage/gco:CharacterString"/>
      <xsl:variable name="licenseName"
        select="$legalConstraints/mco:reference/cit:CI_Citation/cit:title/gco:CharacterString"/>
      <xsl:choose>
        <xsl:when test="$licenseUrl != ''">
          <xsl:text>{
    "@type": "schema:CreativeWork",
    "schema:name": "</xsl:text>
          <xsl:call-template name="escapeJson"><xsl:with-param name="text" select="$licenseName"/></xsl:call-template>
          <xsl:text>",
    "schema:url": "</xsl:text>
          <xsl:call-template name="escapeJson"><xsl:with-param name="text" select="$licenseUrl"/></xsl:call-template>
          <xsl:text>"
  }</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>"</xsl:text>
          <xsl:call-template name="escapeJson"><xsl:with-param name="text" select="$licenseName"/></xsl:call-template>
          <xsl:text>"</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

    <!-- Spatial Coverage -->
    <xsl:variable name="bbox"
      select="mdb:identificationInfo/mri:MD_DataIdentification/mri:extent/gex:EX_Extent/gex:geographicElement/gex:EX_GeographicBoundingBox"/>
    <xsl:if test="$bbox">
      <xsl:text>,
  "schema:spatialCoverage": {
    "@type": "schema:Place",
    "schema:geo": {
      "@type": "schema:GeoShape",
      "schema:box": "</xsl:text>
      <xsl:value-of select="$bbox/gex:southBoundLatitude/gco:Decimal"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="$bbox/gex:westBoundLongitude/gco:Decimal"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="$bbox/gex:northBoundLatitude/gco:Decimal"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="$bbox/gex:eastBoundLongitude/gco:Decimal"/>
      <xsl:text>"
    }
  }</xsl:text>
    </xsl:if>

    <!-- Distribution -->
    <xsl:variable name="transfers"
      select="mdb:distributionInfo/mrd:MD_Distribution/mrd:transferOptions/mrd:MD_DigitalTransferOptions/mrd:onLine/cit:CI_OnlineResource"/>
    <xsl:if test="$transfers">
      <xsl:text>,
  "schema:distribution": [</xsl:text>
      <xsl:for-each select="$transfers">
        <xsl:if test="position() > 1"><xsl:text>,</xsl:text></xsl:if>
        <xsl:text>
    {
      "@type": "schema:DataDownload",
      "schema:contentUrl": "</xsl:text>
        <xsl:call-template name="escapeJson">
          <xsl:with-param name="text" select="cit:linkage/gco:CharacterString"/>
        </xsl:call-template>
        <xsl:text>"</xsl:text>
        <xsl:if test="cit:protocol/gco:CharacterString != ''">
          <xsl:text>,
      "schema:encodingFormat": "</xsl:text>
          <xsl:call-template name="escapeJson">
            <xsl:with-param name="text" select="cit:protocol/gco:CharacterString"/>
          </xsl:call-template>
          <xsl:text>"</xsl:text>
        </xsl:if>
        <xsl:if test="cit:name/gco:CharacterString != ''">
          <xsl:text>,
      "schema:name": "</xsl:text>
          <xsl:call-template name="escapeJson">
            <xsl:with-param name="text" select="cit:name/gco:CharacterString"/>
          </xsl:call-template>
          <xsl:text>"</xsl:text>
        </xsl:if>
        <xsl:text>
    }</xsl:text>
      </xsl:for-each>
      <xsl:text>
  ]</xsl:text>
    </xsl:if>

    <!-- Landing page URL (from distribution or @id) -->
    <xsl:variable name="landingUrl"
      select="mdb:distributionInfo/mrd:MD_Distribution/mrd:transferOptions/mrd:MD_DigitalTransferOptions/mrd:onLine/cit:CI_OnlineResource/cit:linkage/gco:CharacterString"/>
    <xsl:if test="$landingUrl[1] != ''">
      <xsl:text>,
  "schema:url": "</xsl:text>
      <xsl:call-template name="escapeJson"><xsl:with-param name="text" select="$landingUrl[1]"/></xsl:call-template>
      <xsl:text>"</xsl:text>
    </xsl:if>

    <!-- Close JSON-LD object -->
    <xsl:text>
}
</xsl:text>
  </xsl:template>

</xsl:stylesheet>
