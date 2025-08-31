<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:output method="html" />
	<xsl:template match="menu">
		<div id="a460Bifc"></div>
		<xsl:for-each select="item">
            <xsl:apply-templates select="item" />
		</xsl:for-each>
</xsl:template>
	<xsl:template match="item">
			<td onmouseover="dm.v(this)" onmouseout="dm.u(this)" class="a1B1BMainTdd">
                <xsl:attribute name="id">a460B_<xsl:value-of select="@id" /></xsl:attribute>
                <img style="float:left" alt="">
					<xsl:attribute name="height">
					<xsl:if test="string-length(@iconHeight) > 0">
						<xsl:value-of select="@iconHeight" />
					</xsl:if>
					<xsl:if test="string-length(@iconHeight) = 0">16</xsl:if>
					</xsl:attribute>
					
					<xsl:if test="string-length(@icon) > 0">
					<xsl:attribute name="src">
						<xsl:value-of select="@icon" />
					</xsl:attribute>
					</xsl:if>
					<xsl:if test="string-length(@href) > 0">
						<xsl:attribute name="onclick">dm.r('<xsl:value-of select="@href" />')</xsl:attribute>
					</xsl:if>
					<xsl:attribute name="alt">
						<xsl:value-of select="@tooltip"></xsl:value-of>
					</xsl:attribute>
				</img>
                <xsl:value-of select="@title"></xsl:value-of>
            </td>
            <xsl:apply-templates select="item" />
</xsl:template>

</xsl:stylesheet>