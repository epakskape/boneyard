<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="html"/>

	<xsl:template name="row-color">
		<xsl:param name="index"/>
		<xsl:choose>
			<xsl:when test="$index mod 2 != 0">background: #f8e6cb</xsl:when>
			<xsl:otherwise>background: #cbe6f8 </xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="get-player-at">
		<xsl:param name="index"/>
		<xsl:value-of select="//Boneyard/Game/Players/Player[position() = $index]/@name"/>
	</xsl:template>

	<xsl:template name="get-domino">
		<xsl:param name="suite"/>
		<xsl:param name="degree"/>
		<img>
			<xsl:choose>
				<xsl:when test="$suite &lt; $degree">
					<xsl:attribute name="src">images/<xsl:value-of select="$suite"/><xsl:value-of select="$degree"/>.gif</xsl:attribute>
				</xsl:when>
				<xsl:otherwise>
					<xsl:attribute name="src">images/<xsl:value-of select="$degree"/><xsl:value-of select="$suite"/>.gif</xsl:attribute>
				</xsl:otherwise>
			</xsl:choose>
		</img>
	</xsl:template>

	<xsl:template name="get-round-for-player-at">
		<xsl:param name="index"/>
		<xsl:variable name="name">
			<xsl:call-template name="get-player-at">
				<xsl:with-param name="index" select="$index"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:for-each select="Bone">
			<xsl:if test="text() = $name">
				<xsl:call-template name="get-domino">
					<xsl:with-param name="suite" select="@suite"/>
					<xsl:with-param name="degree" select="@degree"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="/">
		<HTML>
			<TITLE>
				Boneyard: 42 Game Simulator
			</TITLE>
			<BODY>
				<STYLE type="text/css">
					table
					{
						background: #cccccc;
						color: #444444;
						border-spacing: 1px;
						font: 10px 'Verdana', Arial, Helvetica, sans-serif;
					}
					td, th 
					{
						padding: 4px;
					}
					th
					{
						font-weight: bold;
						text-align: left;
						background: #F5F5F5;
						color: #666666;
						border: 1px;
						font-size: 12px;
					}
					tbody tr td
					{
						background: #c9e4e9;
						text-align: left;
					}

					body
					{
						font-family: arial, helvetica, sans-serif;
					}

					.tdp
					{
						font-weight: bold;
					}
				</STYLE>
				<xsl:apply-templates select="Boneyard/Game"/>
				<br/>
				<xsl:apply-templates select="Boneyard/Game/Players"/>
				<br/>
				<xsl:apply-templates select="Boneyard/Game/Rounds"/>
			</BODY>
		</HTML>
	</xsl:template>

	<xsl:template match="Boneyard/Game">
		<table width="100%">
			<th colspan="2" style="background: #59bba5; height: 30px">Game Information</th>
			<tbody>
				<tr><td class="tdp"><nobr>Trump</nobr></td><td width="100%"><xsl:value-of select="Trump"/></td></tr>
				<tr><td class="tdp"><nobr>Winner</nobr></td><td><xsl:value-of select="Winner"/></td></tr>
				<tr><td class="tdp"><nobr>Points Won</nobr></td><td><xsl:value-of select="PointsWon"/></td></tr>
			</tbody>
		</table>
	</xsl:template>

	<xsl:template match="Boneyard/Game/Players">
		<table width="100%">
			<th><b>Player</b></th>
			<th><b>Class</b></th>
			<th colspan="7" width="100%"><b>Starting Bones</b></th>
			<xsl:for-each select="Player">
				<tr>
					<td><xsl:value-of select="@name"/></td>
					<td><xsl:value-of select="@class"/></td>
					<td>
					<xsl:for-each select="StartingBones/Bone">
						<xsl:call-template name="get-domino">
							<xsl:with-param name="suite" select="@suite"/>
							<xsl:with-param name="degree" select="@degree"/>
						</xsl:call-template>
					</xsl:for-each>
					</td>
				</tr>
			</xsl:for-each>
		</table>
	</xsl:template>

	<xsl:template match="Boneyard/Game/Rounds">
		<table>
			<th><b>Suite</b></th>
			<th><b>Winner</b></th>
			<th><b>Points Won</b></th>
			<th><b><xsl:call-template name="get-player-at"><xsl:with-param name="index" select="1"/></xsl:call-template></b></th>
			<th><b><xsl:call-template name="get-player-at"><xsl:with-param name="index" select="2"/></xsl:call-template></b></th>
			<th><b><xsl:call-template name="get-player-at"><xsl:with-param name="index" select="3"/></xsl:call-template></b></th>
			<th><b><xsl:call-template name="get-player-at"><xsl:with-param name="index" select="4"/></xsl:call-template></b></th>
			<xsl:for-each select="Round">
				<tr>
					<td><xsl:value-of select="Suite"/></td>
					<td><xsl:value-of select="Winner"/></td>
					<td><xsl:value-of select="PointsWon"/></td>
					<td><xsl:call-template name="get-round-for-player-at"><xsl:with-param name="index" select="1"/></xsl:call-template></td>
					<td><xsl:call-template name="get-round-for-player-at"><xsl:with-param name="index" select="2"/></xsl:call-template></td>
					<td><xsl:call-template name="get-round-for-player-at"><xsl:with-param name="index" select="3"/></xsl:call-template></td>
					<td><xsl:call-template name="get-round-for-player-at"><xsl:with-param name="index" select="4"/></xsl:call-template></td>
				</tr>
			</xsl:for-each>
 		</table>
	</xsl:template>
</xsl:stylesheet>
