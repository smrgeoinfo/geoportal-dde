<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:gmd="http://www.isotc211.org/2005/gmd"
                xmlns:gcoold="http://www.isotc211.org/2005/gco"
                xmlns:gmi="http://www.isotc211.org/2005/gmi"
                xmlns:gmx="http://www.isotc211.org/2005/gmx"
                xmlns:gsr="http://www.isotc211.org/2005/gsr"
                xmlns:gss="http://www.isotc211.org/2005/gss"
                xmlns:gts="http://www.isotc211.org/2005/gts"
                xmlns:srvold="http://www.isotc211.org/2005/srv"
                xmlns:gml30="http://www.opengis.net/gml"
                xmlns:cat="http://standards.iso.org/iso/19115/-3/cat/1.0"
                xmlns:cit="http://standards.iso.org/iso/19115/-3/cit/2.0"
                xmlns:gcx="http://standards.iso.org/iso/19115/-3/gcx/1.0"
                xmlns:gex="http://standards.iso.org/iso/19115/-3/gex/1.0"
                xmlns:lan="http://standards.iso.org/iso/19115/-3/lan/1.0"
                xmlns:srv="http://standards.iso.org/iso/19115/-3/srv/2.1"
                xmlns:mac="http://standards.iso.org/iso/19115/-3/mac/2.0"
                xmlns:mas="http://standards.iso.org/iso/19115/-3/mas/1.0"
                xmlns:mcc="http://standards.iso.org/iso/19115/-3/mcc/1.0"
                xmlns:mco="http://standards.iso.org/iso/19115/-3/mco/1.0"
                xmlns:mda="http://standards.iso.org/iso/19115/-3/mda/1.0"
                xmlns:mdb="http://standards.iso.org/iso/19115/-3/mdb/2.0"
                xmlns:mdt="http://standards.iso.org/iso/19115/-3/mdt/1.0"
                xmlns:mex="http://standards.iso.org/iso/19115/-3/mex/1.0"
                xmlns:mic="http://standards.iso.org/iso/19115/-3/mic/1.0"
                xmlns:mil="http://standards.iso.org/iso/19115/-3/mil/1.0"
                xmlns:mrl="http://standards.iso.org/iso/19115/-3/mrl/1.0"
                xmlns:mds="http://standards.iso.org/iso/19115/-3/mds/2.0"
                xmlns:mmi="http://standards.iso.org/iso/19115/-3/mmi/1.0"
                xmlns:mpc="http://standards.iso.org/iso/19115/-3/mpc/1.0"
                xmlns:mrc="http://standards.iso.org/iso/19115/-3/mrc/1.0"
                xmlns:mrd="http://standards.iso.org/iso/19115/-3/mrd/1.0"
                xmlns:mri="http://standards.iso.org/iso/19115/-3/mri/1.0"
                xmlns:mrs="http://standards.iso.org/iso/19115/-3/mrs/1.0"
                xmlns:msr="http://standards.iso.org/iso/19115/-3/msr/2.0"
                xmlns:mai="http://standards.iso.org/iso/19115/-3/mai/1.0"
                xmlns:mdq="http://standards.iso.org/iso/19157/-2/mdq/1.0"
                xmlns:gco="http://standards.iso.org/iso/19115/-3/gco/1.0"
                xmlns:gml="http://www.opengis.net/gml/3.2"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
                exclude-result-prefixes="#all">

    <xsl:output method="xml" indent="yes"/>

    <xsl:strip-space elements="*"/>

    <!-- Convert CDIF JSON-LD (via JSON-to-XML intermediate form) to ISO 19115-3.
         JSON keys are transformed: schema:name -> schema_name, @id -> id, @type -> type.
         Arrays become repeated sibling elements. -->

    <xsl:template match="/record">

      <mdb:MD_Metadata xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                       xmlns:cit="http://standards.iso.org/iso/19115/-3/cit/2.0"
                       xmlns:gex="http://standards.iso.org/iso/19115/-3/gex/1.0"
                       xmlns:lan="http://standards.iso.org/iso/19115/-3/lan/1.0"
                       xmlns:mcc="http://standards.iso.org/iso/19115/-3/mcc/1.0"
                       xmlns:mco="http://standards.iso.org/iso/19115/-3/mco/1.0"
                       xmlns:mdb="http://standards.iso.org/iso/19115/-3/mdb/2.0"
                       xmlns:mmi="http://standards.iso.org/iso/19115/-3/mmi/1.0"
                       xmlns:mrd="http://standards.iso.org/iso/19115/-3/mrd/1.0"
                       xmlns:mri="http://standards.iso.org/iso/19115/-3/mri/1.0"
                       xmlns:mrl="http://standards.iso.org/iso/19115/-3/mrl/2.0"
                       xmlns:mrs="http://standards.iso.org/iso/19115/-3/mrs/1.0"
                       xmlns:mrc="http://standards.iso.org/iso/19115/-3/mrc/2.0"
                       xmlns:gco="http://standards.iso.org/iso/19115/-3/gco/1.0"
                       xmlns:gfc="http://standards.iso.org/iso/19110/gfc/1.1"
                       xmlns:gml="http://www.opengis.net/gml/3.2">

        <!-- Metadata Identifier: use uuid injected by harvester -->
        <mdb:metadataIdentifier>
          <mcc:MD_Identifier>
            <mcc:code>
              <gco:CharacterString>
                <xsl:value-of select="uuid"/>
              </gco:CharacterString>
            </mcc:code>
          </mcc:MD_Identifier>
        </mdb:metadataIdentifier>

        <!-- Default Locale -->
        <mdb:defaultLocale>
          <lan:PT_Locale>
            <lan:language>
              <lan:LanguageCode codeList="codeListLocation#LanguageCode" codeListValue="eng"/>
            </lan:language>
            <lan:characterEncoding>
              <lan:MD_CharacterSetCode codeList="codeListLocation#MD_CharacterSetCode"
                                       codeListValue="utf8"/>
            </lan:characterEncoding>
          </lan:PT_Locale>
        </mdb:defaultLocale>

        <!-- Metadata Scope: map @type to MD_ScopeCode -->
        <mdb:metadataScope>
          <mdb:MD_MetadataScope>
            <mdb:resourceScope>
              <xsl:variable name="scopeCode">
                <xsl:choose>
                  <xsl:when test="type[contains(., 'Dataset')] or type[contains(., 'schema_Dataset')]">dataset</xsl:when>
                  <xsl:when test="type[contains(., 'Service')]">service</xsl:when>
                  <xsl:when test="type[contains(., 'SoftwareApplication')] or type[contains(., 'SoftwareSourceCode')]">software</xsl:when>
                  <xsl:otherwise>dataset</xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <mcc:MD_ScopeCode codeList="http://standards.iso.org/iso/19115/resources/Codelists/cat/codelists.xml#MD_ScopeCode"
                                codeListValue="{$scopeCode}"/>
            </mdb:resourceScope>
          </mdb:MD_MetadataScope>
        </mdb:metadataScope>

        <!-- Metadata Contact: first creator as metadata contact -->
        <xsl:choose>
          <xsl:when test="schema_creator[1]">
            <xsl:for-each select="schema_creator[1]">
              <mdb:contact>
                <xsl:call-template name="buildResponsibility">
                  <xsl:with-param name="role">author</xsl:with-param>
                </xsl:call-template>
              </mdb:contact>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <mdb:contact>
              <cit:CI_Responsibility>
                <cit:role>
                  <cit:CI_RoleCode codeList="codeListLocation#CI_RoleCode" codeListValue="author"/>
                </cit:role>
                <cit:party>
                  <cit:CI_Organisation>
                    <cit:name>
                      <gco:CharacterString/>
                    </cit:name>
                  </cit:CI_Organisation>
                </cit:party>
              </cit:CI_Responsibility>
            </mdb:contact>
          </xsl:otherwise>
        </xsl:choose>

        <!-- Metadata Date: dateModified from subjectOf (metadata about metadata) -->
        <xsl:if test="schema_subjectOf/schema_dateModified">
          <mdb:dateInfo>
            <cit:CI_Date>
              <cit:date>
                <gco:DateTime><xsl:value-of select="schema_subjectOf/schema_dateModified"/></gco:DateTime>
              </cit:date>
              <cit:dateType>
                <cit:CI_DateTypeCode codeList="codeListLocation#CI_DateTypeCode" codeListValue="revision"/>
              </cit:dateType>
            </cit:CI_Date>
          </mdb:dateInfo>
        </xsl:if>

        <!-- Resource publication date at metadata level -->
        <xsl:if test="schema_datePublished">
          <mdb:dateInfo>
            <cit:CI_Date>
              <cit:date>
                <gco:DateTime><xsl:value-of select="schema_datePublished"/></gco:DateTime>
              </cit:date>
              <cit:dateType>
                <cit:CI_DateTypeCode codeList="codeListLocation#CI_DateTypeCode" codeListValue="publication"/>
              </cit:dateType>
            </cit:CI_Date>
          </mdb:dateInfo>
        </xsl:if>

        <!-- Metadata Standard -->
        <mdb:metadataStandard>
          <cit:CI_Citation>
            <cit:title>
              <gco:CharacterString>ISO 19115-3</gco:CharacterString>
            </cit:title>
          </cit:CI_Citation>
        </mdb:metadataStandard>

        <!-- Identification Info -->
        <mdb:identificationInfo>
          <mri:MD_DataIdentification>
            <mri:citation>
              <cit:CI_Citation>
                <!-- Title -->
                <cit:title>
                  <gco:CharacterString>
                    <xsl:value-of select="schema_name"/>
                  </gco:CharacterString>
                </cit:title>

                <!-- Publication date -->
                <xsl:if test="schema_datePublished">
                  <cit:date>
                    <cit:CI_Date>
                      <cit:date>
                        <gco:DateTime><xsl:value-of select="schema_datePublished"/></gco:DateTime>
                      </cit:date>
                      <cit:dateType>
                        <cit:CI_DateTypeCode codeList="codeListLocation#CI_DateTypeCode" codeListValue="publication"/>
                      </cit:dateType>
                    </cit:CI_Date>
                  </cit:date>
                </xsl:if>

                <!-- Resource Identifier (DOI) -->
                <xsl:if test="schema_identifier">
                  <cit:identifier>
                    <mcc:MD_Identifier>
                      <mcc:code>
                        <gco:CharacterString>
                          <xsl:choose>
                            <xsl:when test="schema_identifier/schema_value">
                              <xsl:value-of select="schema_identifier/schema_value"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="schema_identifier"/>
                            </xsl:otherwise>
                          </xsl:choose>
                        </gco:CharacterString>
                      </mcc:code>
                      <xsl:if test="schema_identifier/schema_propertyID">
                        <mcc:codeSpace>
                          <gco:CharacterString>
                            <xsl:value-of select="schema_identifier/schema_propertyID"/>
                          </gco:CharacterString>
                        </mcc:codeSpace>
                      </xsl:if>
                    </mcc:MD_Identifier>
                  </cit:identifier>
                </xsl:if>

                <!-- Cited Responsible Parties (creators) -->
                <xsl:for-each select="schema_creator">
                  <cit:citedResponsibleParty>
                    <xsl:call-template name="buildResponsibility">
                      <xsl:with-param name="role">author</xsl:with-param>
                    </xsl:call-template>
                  </cit:citedResponsibleParty>
                </xsl:for-each>
              </cit:CI_Citation>
            </mri:citation>

            <!-- Abstract -->
            <mri:abstract>
              <gco:CharacterString>
                <xsl:choose>
                  <xsl:when test="schema_description != ''">
                    <xsl:value-of select="schema_description"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="schema_name"/>
                  </xsl:otherwise>
                </xsl:choose>
              </gco:CharacterString>
            </mri:abstract>

            <!-- Point of Contact (creators) -->
            <xsl:for-each select="schema_creator">
              <mri:pointOfContact>
                <xsl:call-template name="buildResponsibility">
                  <xsl:with-param name="role">author</xsl:with-param>
                </xsl:call-template>
              </mri:pointOfContact>
            </xsl:for-each>

            <!-- Keywords -->
            <xsl:if test="schema_keywords">
              <mri:descriptiveKeywords>
                <mri:MD_Keywords>
                  <xsl:for-each select="schema_keywords">
                    <mri:keyword>
                      <gco:CharacterString>
                        <xsl:choose>
                          <xsl:when test="schema_name"><xsl:value-of select="schema_name"/></xsl:when>
                          <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
                        </xsl:choose>
                      </gco:CharacterString>
                    </mri:keyword>
                  </xsl:for-each>
                  <mri:type>
                    <mri:MD_KeywordTypeCode codeListValue="theme"
                                            codeList="./resources/codeList.xml#MD_KeywordTypeCode"/>
                  </mri:type>
                </mri:MD_Keywords>
              </mri:descriptiveKeywords>
            </xsl:if>

            <!-- additionalType as keywords -->
            <xsl:if test="schema_additionalType">
              <mri:descriptiveKeywords>
                <mri:MD_Keywords>
                  <xsl:for-each select="schema_additionalType">
                    <mri:keyword>
                      <gco:CharacterString>
                        <xsl:choose>
                          <xsl:when test="schema_name"><xsl:value-of select="schema_name"/></xsl:when>
                          <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
                        </xsl:choose>
                      </gco:CharacterString>
                    </mri:keyword>
                  </xsl:for-each>
                  <mri:type>
                    <mri:MD_KeywordTypeCode codeListValue="theme"
                                            codeList="./resources/codeList.xml#MD_KeywordTypeCode"/>
                  </mri:type>
                </mri:MD_Keywords>
              </mri:descriptiveKeywords>
            </xsl:if>

            <!-- License / Resource Constraints -->
            <xsl:if test="schema_license">
              <mri:resourceConstraints>
                <mco:MD_LegalConstraints>
                  <mco:reference>
                    <cit:CI_Citation>
                      <cit:title>
                        <gco:CharacterString>
                          <xsl:choose>
                            <xsl:when test="schema_license/schema_name">
                              <xsl:value-of select="schema_license/schema_name"/>
                            </xsl:when>
                            <xsl:when test="schema_license/schema_text">
                              <xsl:value-of select="schema_license/schema_text"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="schema_license"/>
                            </xsl:otherwise>
                          </xsl:choose>
                        </gco:CharacterString>
                      </cit:title>
                      <xsl:if test="schema_license/schema_url or (not(schema_license/*) and starts-with(schema_license, 'http'))">
                        <cit:onlineResource>
                          <cit:CI_OnlineResource>
                            <cit:linkage>
                              <gco:CharacterString>
                                <xsl:choose>
                                  <xsl:when test="schema_license/schema_url">
                                    <xsl:value-of select="schema_license/schema_url"/>
                                  </xsl:when>
                                  <xsl:otherwise>
                                    <xsl:value-of select="schema_license"/>
                                  </xsl:otherwise>
                                </xsl:choose>
                              </gco:CharacterString>
                            </cit:linkage>
                          </cit:CI_OnlineResource>
                        </cit:onlineResource>
                      </xsl:if>
                    </cit:CI_Citation>
                  </mco:reference>
                  <mco:accessConstraints>
                    <mco:MD_RestrictionCode codeListValue="otherRestrictions"
                                            codeList="http://standards.iso.org/iso/19139/resources/gmxCodelists.xml#MD_RestrictionCode"/>
                  </mco:accessConstraints>
                  <mco:useConstraints>
                    <mco:MD_RestrictionCode codeListValue="otherRestrictions"
                                            codeList="http://standards.iso.org/iso/19139/resources/gmxCodelists.xml#MD_RestrictionCode"/>
                  </mco:useConstraints>
                </mco:MD_LegalConstraints>
              </mri:resourceConstraints>
            </xsl:if>

            <!-- conditionsOfAccess (alternative to license) -->
            <xsl:if test="schema_conditionsOfAccess and not(schema_license)">
              <mri:resourceConstraints>
                <mco:MD_LegalConstraints>
                  <mco:otherConstraints>
                    <gco:CharacterString>
                      <xsl:value-of select="schema_conditionsOfAccess"/>
                    </gco:CharacterString>
                  </mco:otherConstraints>
                  <mco:accessConstraints>
                    <mco:MD_RestrictionCode codeListValue="otherRestrictions"
                                            codeList="http://standards.iso.org/iso/19139/resources/gmxCodelists.xml#MD_RestrictionCode"/>
                  </mco:accessConstraints>
                </mco:MD_LegalConstraints>
              </mri:resourceConstraints>
            </xsl:if>

            <!-- Spatial Coverage -->
            <xsl:if test="schema_spatialCoverage/schema_geo">
              <mri:extent>
                <gex:EX_Extent>
                  <gex:geographicElement>
                    <gex:EX_GeographicBoundingBox>
                      <gex:westBoundLongitude>
                        <gco:Decimal>
                          <xsl:choose>
                            <xsl:when test="schema_spatialCoverage/schema_geo/schema_box">
                              <xsl:value-of select="tokenize(schema_spatialCoverage/schema_geo/schema_box, '\s+')[2]"/>
                            </xsl:when>
                            <xsl:when test="schema_spatialCoverage/schema_geo/schema_longitude">
                              <xsl:value-of select="schema_spatialCoverage/schema_geo/schema_longitude"/>
                            </xsl:when>
                            <xsl:otherwise>-180</xsl:otherwise>
                          </xsl:choose>
                        </gco:Decimal>
                      </gex:westBoundLongitude>
                      <gex:eastBoundLongitude>
                        <gco:Decimal>
                          <xsl:choose>
                            <xsl:when test="schema_spatialCoverage/schema_geo/schema_box">
                              <xsl:value-of select="tokenize(schema_spatialCoverage/schema_geo/schema_box, '\s+')[4]"/>
                            </xsl:when>
                            <xsl:when test="schema_spatialCoverage/schema_geo/schema_longitude">
                              <xsl:value-of select="schema_spatialCoverage/schema_geo/schema_longitude"/>
                            </xsl:when>
                            <xsl:otherwise>180</xsl:otherwise>
                          </xsl:choose>
                        </gco:Decimal>
                      </gex:eastBoundLongitude>
                      <gex:southBoundLatitude>
                        <gco:Decimal>
                          <xsl:choose>
                            <xsl:when test="schema_spatialCoverage/schema_geo/schema_box">
                              <xsl:value-of select="tokenize(schema_spatialCoverage/schema_geo/schema_box, '\s+')[1]"/>
                            </xsl:when>
                            <xsl:when test="schema_spatialCoverage/schema_geo/schema_latitude">
                              <xsl:value-of select="schema_spatialCoverage/schema_geo/schema_latitude"/>
                            </xsl:when>
                            <xsl:otherwise>-90</xsl:otherwise>
                          </xsl:choose>
                        </gco:Decimal>
                      </gex:southBoundLatitude>
                      <gex:northBoundLatitude>
                        <gco:Decimal>
                          <xsl:choose>
                            <xsl:when test="schema_spatialCoverage/schema_geo/schema_box">
                              <xsl:value-of select="tokenize(schema_spatialCoverage/schema_geo/schema_box, '\s+')[3]"/>
                            </xsl:when>
                            <xsl:when test="schema_spatialCoverage/schema_geo/schema_latitude">
                              <xsl:value-of select="schema_spatialCoverage/schema_geo/schema_latitude"/>
                            </xsl:when>
                            <xsl:otherwise>90</xsl:otherwise>
                          </xsl:choose>
                        </gco:Decimal>
                      </gex:northBoundLatitude>
                    </gex:EX_GeographicBoundingBox>
                  </gex:geographicElement>
                </gex:EX_Extent>
              </mri:extent>
            </xsl:if>

            <!-- Default Locale for resource -->
            <mri:defaultLocale>
              <lan:PT_Locale>
                <lan:language>
                  <lan:LanguageCode codeList="codeListLocation#LanguageCode" codeListValue="eng"/>
                </lan:language>
                <lan:characterEncoding>
                  <lan:MD_CharacterSetCode codeList="codeListLocation#MD_CharacterSetCode"
                                           codeListValue="utf8"/>
                </lan:characterEncoding>
              </lan:PT_Locale>
            </mri:defaultLocale>
          </mri:MD_DataIdentification>
        </mdb:identificationInfo>

        <!-- Distribution Info -->
        <xsl:if test="schema_distribution or schema_url">
          <mdb:distributionInfo>
            <mrd:MD_Distribution>
              <!-- Distribution formats -->
              <xsl:for-each select="schema_distribution/schema_encodingFormat[not(. = preceding-sibling::schema_encodingFormat)]">
                <mrd:distributionFormat>
                  <mrd:MD_Format>
                    <mrd:formatSpecificationCitation>
                      <cit:CI_Citation>
                        <cit:title>
                          <gco:CharacterString>
                            <xsl:value-of select="."/>
                          </gco:CharacterString>
                        </cit:title>
                      </cit:CI_Citation>
                    </mrd:formatSpecificationCitation>
                  </mrd:MD_Format>
                </mrd:distributionFormat>
              </xsl:for-each>

              <!-- Distribution formats from hasPart sub-elements -->
              <xsl:for-each select="schema_distribution/schema_hasPart/schema_encodingFormat[not(. = preceding-sibling::schema_encodingFormat)]">
                <mrd:distributionFormat>
                  <mrd:MD_Format>
                    <mrd:formatSpecificationCitation>
                      <cit:CI_Citation>
                        <cit:title>
                          <gco:CharacterString>
                            <xsl:value-of select="."/>
                          </gco:CharacterString>
                        </cit:title>
                      </cit:CI_Citation>
                    </mrd:formatSpecificationCitation>
                  </mrd:MD_Format>
                </mrd:distributionFormat>
              </xsl:for-each>

              <!-- Transfer options from schema_distribution -->
              <xsl:for-each select="schema_distribution">
                <xsl:if test="schema_contentUrl">
                  <mrd:transferOptions>
                    <mrd:MD_DigitalTransferOptions>
                      <mrd:onLine>
                        <cit:CI_OnlineResource>
                          <cit:linkage>
                            <gco:CharacterString>
                              <xsl:value-of select="schema_contentUrl"/>
                            </gco:CharacterString>
                          </cit:linkage>
                          <xsl:if test="schema_encodingFormat">
                            <cit:protocol>
                              <gco:CharacterString>
                                <xsl:value-of select="schema_encodingFormat"/>
                              </gco:CharacterString>
                            </cit:protocol>
                          </xsl:if>
                          <xsl:if test="schema_name">
                            <cit:name>
                              <gco:CharacterString>
                                <xsl:value-of select="schema_name"/>
                              </gco:CharacterString>
                            </cit:name>
                          </xsl:if>
                          <xsl:if test="schema_description">
                            <cit:description>
                              <gco:CharacterString>
                                <xsl:value-of select="schema_description"/>
                              </gco:CharacterString>
                            </cit:description>
                          </xsl:if>
                        </cit:CI_OnlineResource>
                      </mrd:onLine>
                    </mrd:MD_DigitalTransferOptions>
                  </mrd:transferOptions>
                </xsl:if>

                <!-- Transfer options from hasPart sub-distributions -->
                <xsl:for-each select="schema_hasPart[schema_contentUrl]">
                  <mrd:transferOptions>
                    <mrd:MD_DigitalTransferOptions>
                      <mrd:onLine>
                        <cit:CI_OnlineResource>
                          <cit:linkage>
                            <gco:CharacterString>
                              <xsl:value-of select="schema_contentUrl"/>
                            </gco:CharacterString>
                          </cit:linkage>
                          <xsl:if test="schema_encodingFormat">
                            <cit:protocol>
                              <gco:CharacterString>
                                <xsl:value-of select="schema_encodingFormat"/>
                              </gco:CharacterString>
                            </cit:protocol>
                          </xsl:if>
                          <xsl:if test="schema_name">
                            <cit:name>
                              <gco:CharacterString>
                                <xsl:value-of select="schema_name"/>
                              </gco:CharacterString>
                            </cit:name>
                          </xsl:if>
                        </cit:CI_OnlineResource>
                      </mrd:onLine>
                    </mrd:MD_DigitalTransferOptions>
                  </mrd:transferOptions>
                </xsl:for-each>
              </xsl:for-each>

              <!-- Simple URL fallback -->
              <xsl:if test="schema_url and not(schema_distribution/schema_contentUrl)">
                <mrd:transferOptions>
                  <mrd:MD_DigitalTransferOptions>
                    <mrd:onLine>
                      <cit:CI_OnlineResource>
                        <cit:linkage>
                          <gco:CharacterString>
                            <xsl:value-of select="schema_url"/>
                          </gco:CharacterString>
                        </cit:linkage>
                      </cit:CI_OnlineResource>
                    </mrd:onLine>
                  </mrd:MD_DigitalTransferOptions>
                </mrd:transferOptions>
              </xsl:if>
            </mrd:MD_Distribution>
          </mdb:distributionInfo>
        </xsl:if>

        <!-- Resource Lineage (required by schema) -->
        <mdb:resourceLineage>
          <mrl:LI_Lineage>
            <mrl:statement>
              <gco:CharacterString/>
            </mrl:statement>
            <mrl:scope>
              <mcc:MD_Scope>
                <mcc:level>
                  <mcc:MD_ScopeCode codeList="codeListLocation#MD_ScopeCode" codeListValue="dataset"/>
                </mcc:level>
              </mcc:MD_Scope>
            </mrl:scope>
          </mrl:LI_Lineage>
        </mdb:resourceLineage>
      </mdb:MD_Metadata>
    </xsl:template>

    <!-- Named template: build a CI_Responsibility from a schema_creator element -->
    <xsl:template name="buildResponsibility">
      <xsl:param name="role" select="'author'"/>

      <cit:CI_Responsibility>
        <cit:role>
          <cit:CI_RoleCode codeList="codeListLocation#CI_RoleCode" codeListValue="{$role}"/>
        </cit:role>
        <cit:party>
          <xsl:choose>
            <!-- Person with @type containing Person -->
            <xsl:when test="type[contains(., 'Person')]">
              <cit:CI_Individual>
                <cit:name>
                  <gco:CharacterString>
                    <xsl:value-of select="schema_name"/>
                  </gco:CharacterString>
                </cit:name>
                <!-- ORCID or other identifier -->
                <xsl:if test="schema_identifier">
                  <cit:partyIdentifier>
                    <mcc:MD_Identifier>
                      <mcc:code>
                        <gco:CharacterString>
                          <xsl:choose>
                            <xsl:when test="schema_identifier/schema_value">
                              <xsl:value-of select="schema_identifier/schema_value"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="schema_identifier"/>
                            </xsl:otherwise>
                          </xsl:choose>
                        </gco:CharacterString>
                      </mcc:code>
                      <xsl:if test="schema_identifier/schema_propertyID">
                        <mcc:codeSpace>
                          <gco:CharacterString>
                            <xsl:value-of select="schema_identifier/schema_propertyID"/>
                          </gco:CharacterString>
                        </mcc:codeSpace>
                      </xsl:if>
                    </mcc:MD_Identifier>
                  </cit:partyIdentifier>
                </xsl:if>
              </cit:CI_Individual>
            </xsl:when>
            <!-- Organization -->
            <xsl:when test="type[contains(., 'Organization')]">
              <cit:CI_Organisation>
                <cit:name>
                  <gco:CharacterString>
                    <xsl:value-of select="schema_name"/>
                  </gco:CharacterString>
                </cit:name>
                <xsl:if test="schema_identifier">
                  <cit:partyIdentifier>
                    <mcc:MD_Identifier>
                      <mcc:code>
                        <gco:CharacterString>
                          <xsl:choose>
                            <xsl:when test="schema_identifier/schema_value">
                              <xsl:value-of select="schema_identifier/schema_value"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="schema_identifier"/>
                            </xsl:otherwise>
                          </xsl:choose>
                        </gco:CharacterString>
                      </mcc:code>
                    </mcc:MD_Identifier>
                  </cit:partyIdentifier>
                </xsl:if>
              </cit:CI_Organisation>
            </xsl:when>
            <!-- Default: treat as Individual if has a name, otherwise Organisation -->
            <xsl:otherwise>
              <cit:CI_Individual>
                <cit:name>
                  <gco:CharacterString>
                    <xsl:value-of select="schema_name"/>
                  </gco:CharacterString>
                </cit:name>
                <xsl:if test="schema_identifier">
                  <cit:partyIdentifier>
                    <mcc:MD_Identifier>
                      <mcc:code>
                        <gco:CharacterString>
                          <xsl:choose>
                            <xsl:when test="schema_identifier/schema_value">
                              <xsl:value-of select="schema_identifier/schema_value"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="schema_identifier"/>
                            </xsl:otherwise>
                          </xsl:choose>
                        </gco:CharacterString>
                      </mcc:code>
                    </mcc:MD_Identifier>
                  </cit:partyIdentifier>
                </xsl:if>
              </cit:CI_Individual>
            </xsl:otherwise>
          </xsl:choose>
        </cit:party>
      </cit:CI_Responsibility>
    </xsl:template>
</xsl:stylesheet>
