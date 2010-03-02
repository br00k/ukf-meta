<?xml version="1.0" encoding="UTF-8"?>
<!--

	check_misc.xsl
	
	Checking ruleset containing generally applicable rules not falling into any
	other category.
	
	Author: Ian A. Young <ian@iay.org.uk>

-->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
	xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
	xmlns:shibmd="urn:mace:shibboleth:metadata:1.0"
	xmlns:set="http://exslt.org/sets"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:idpdisc="urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol"

	xmlns:mdxURL="xalan://uk.ac.sdss.xalan.md.URLchecker"

	xmlns="urn:oasis:names:tc:SAML:2.0:metadata">

	<!--
		Common support functions.
	-->
	<xsl:import href="check_framework.xsl"/>

	
	<!--
		Checks across the whole of the document are defined here.
		
		Only bother with these when the document element is an EntitiesDescriptor.
	-->
	<xsl:template match="/md:EntitiesDescriptor">
		<xsl:variable name="entities" select="//md:EntityDescriptor"/>
		<xsl:variable name="idps" select="$entities[md:IDPSSODescriptor]"/>
		
		<!-- check for duplicate entityID values -->
		<xsl:variable name="distinct.entityIDs" select="set:distinct($entities/@entityID)"/>
		<xsl:variable name="dup.entityIDs"
			select="set:distinct(set:difference($entities/@entityID, $distinct.entityIDs))"/>
		<xsl:for-each select="$dup.entityIDs">
			<xsl:variable name="dup.entityID" select="."/>
			<xsl:for-each select="$entities[@entityID = $dup.entityID]">
				<xsl:call-template name="fatal">
					<xsl:with-param name="m">duplicate entityID: <xsl:value-of select='$dup.entityID'/></xsl:with-param>
				</xsl:call-template>
			</xsl:for-each>
		</xsl:for-each>
		
		<!-- check for duplicate OrganisationDisplayName values -->
		<xsl:variable name="distinct.ODNs"
			select="set:distinct($idps/md:Organization/md:OrganizationDisplayName)"/>
		<xsl:variable name="dup.ODNs"
			select="set:distinct(set:difference($idps/md:Organization/md:OrganizationDisplayName, $distinct.ODNs))"/>
		<xsl:for-each select="$dup.ODNs">
			<xsl:variable name="dup.ODN" select="."/>
			<xsl:for-each select="$idps[md:Organization/md:OrganizationDisplayName = $dup.ODN]">
				<xsl:call-template name="fatal">
					<xsl:with-param name="m">duplicate OrganisationDisplayName: <xsl:value-of select='$dup.ODN'/></xsl:with-param>
				</xsl:call-template>
			</xsl:for-each>
		</xsl:for-each>
		
		<!--
			Perform checks on child elements.
		-->
		<xsl:apply-templates/>
	</xsl:template>
	
	
	<!--
		Check for entities which do not have an OrganizationName at all.
	-->
	<xsl:template match="md:EntityDescriptor[not(md:Organization/md:OrganizationName)]">
		<xsl:call-template name="fatal">
			<xsl:with-param name="m">entity lacks OrganizationName</xsl:with-param>
		</xsl:call-template>
	</xsl:template>


	<!--
		Check for role descriptors with missing KeyDescriptor elements.
	-->
	
	<xsl:template match="md:IDPSSODescriptor[not(md:KeyDescriptor)]">
		<xsl:call-template name="fatal">
			<xsl:with-param name="m">IdP SSO Descriptor lacking KeyDescriptor</xsl:with-param>
		</xsl:call-template>	
	</xsl:template>

	<xsl:template match="md:SPSSODescriptor[not(md:KeyDescriptor)]">
		<xsl:call-template name="fatal">
			<xsl:with-param name="m">SP SSO Descriptor lacking KeyDescriptor</xsl:with-param>
		</xsl:call-template>	
	</xsl:template>
	
	<xsl:template match="md:AttributeAuthorityDescriptor[not(md:KeyDescriptor)]">
		<xsl:call-template name="fatal">
			<xsl:with-param name="m">IdP AA Descriptor lacking KeyDescriptor</xsl:with-param>
		</xsl:call-template>	
	</xsl:template>
	
	
	<!--
		Entity IDs should not contain space characters.
	-->
	<xsl:template match="md:EntityDescriptor[contains(@entityID, ' ')]">
		<xsl:call-template name="fatal">
			<xsl:with-param name="m">entity ID contains space character</xsl:with-param>
		</xsl:call-template>
	</xsl:template>


	<!--
		Entity IDs should start with one of "http://", "https://" or "urn:mace:".
	-->
	<xsl:template match="md:EntityDescriptor[not(starts-with(@entityID, 'urn:mace:'))]
		[not(starts-with(@entityID, 'http://'))]
		[not(starts-with(@entityID, 'https://'))]">
		<xsl:call-template name="fatal">
			<xsl:with-param name="m">entity ID <xsl:value-of select="@entityID"/> does not start with acceptable prefix</xsl:with-param>
		</xsl:call-template>
	</xsl:template>


	<!--
		@Location attributes should not contain space characters.
		
		This may be a little strict, and might be better confined to md:* elements.
		At present, however, this produces no false positives.
	-->
	<xsl:template match="*[contains(@Location, ' ')]">
		<xsl:call-template name="fatal">
			<xsl:with-param name="m"><xsl:value-of select='local-name()'/> Location contains space character</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	
	
	<!--
		Check for Locations that don't start with https://
		
		This may be a little strict, and might be better confined to md:* elements.
		In addition, we might at some point require more complex rules: whitelisting certain
		entities, or permitting http:// to Locations associated with certain bindngs.
		
		At present, however, this simpler rule produces no false positives.
	-->
	<xsl:template match="*[@Location and not(starts-with(@Location,'https://'))]">
		<xsl:call-template name="fatal">
			<xsl:with-param name="m"><xsl:value-of select='local-name()'/> Location does not start with https://</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	
	
	<!--
		Check for Locations that aren't valid URLs.
	-->
	<xsl:template match="*[@Location and mdxURL:invalidURL(@Location)]">
		<xsl:call-template name="fatal">
			<xsl:with-param name="m">
				<xsl:value-of select='local-name()'/>
				<xsl:text> Location is not a valid URL: </xsl:text>
				<xsl:value-of select="mdxURL:whyInvalid(@Location)"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<!--
		Check for empty xml:lang elements, automatically generated by OIOSAML.
		
		This is not schema-valid so would be caught further down the line anyway,
		but it's nice to have a clear error message earlier in the process.
	-->
	<xsl:template match="@xml:lang[.='']">
		<xsl:call-template name="fatal">
			<xsl:with-param name="m">empty xml:lang attribute</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

</xsl:stylesheet>