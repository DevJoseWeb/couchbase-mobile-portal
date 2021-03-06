<?xml version="1.0"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fn="http://www.couchbase.com/xsl/extension-functions"
                xmlns:uri="java:java.net.URI"
                xmlns:file="java:java.io.File"
                xmlns:runtime="java.lang.Runtime"
                exclude-result-prefixes="fn file runtime">

<xsl:param name="output-directory">gen/</xsl:param>

<!-- Creates a directory path using the output directory as root and using each set as a child directory. -->
<xsl:function name="fn:result-directory">
	<xsl:param name="node"/>
	
	<xsl:variable name="result-directory">
		<xsl:value-of select="$output-directory"/>
		
		<xsl:for-each select="$node/ancestor-or-self::*[self::group or self::item or self::set or self::guide or self::article or self::class or self::lesson or self::page or self::xhtml-page or self::api or self::package]">
			<xsl:if test="not(parent::top)">
				<xsl:value-of select="concat(@id, '/')"/>
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>
	
	<xsl:value-of select="$result-directory"/>
</xsl:function>

<!-- Creates a file path using the result directory. -->
<xsl:function name="fn:result-path">
    <xsl:param name="node"/>
    
	<xsl:variable name="result-path">
		<xsl:value-of select="fn:result-directory($node)"/>
	    <xsl:text>index.html</xsl:text>
	</xsl:variable>
	
	<xsl:value-of select="$result-path"/>
</xsl:function>
	
<!-- Creates a file path using the output directory as root and using each set as a child directory. -->
<xsl:function name="fn:relative-result-path">
	<xsl:param name="fromNode"/>
	<xsl:param name="toNode"/>
	
	<xsl:variable name="path">
		<!-- Back up the tree from the source node to root. -->
		<xsl:for-each select="$fromNode/ancestor-or-self::*[self::group[parent::site-map] or self::item[parent::site-map or parent::group[parent::site-map]] or self::set or self::guide or self::article or self::class or self::lesson or self::page or self::xhtml-page or self::api or self::package or self::hippo-root]">
			<xsl:if test="not(parent::top)">
				<xsl:value-of select="'../'"/>
			</xsl:if>
		</xsl:for-each>
		
		<!-- Drill down the tree to the target node. -->
		<xsl:for-each select="$toNode/ancestor-or-self::*[self::group[parent::site-map] or self::item[parent::site-map or parent::group[parent::site-map]] or self::set or self::guide or self::article or self::class or self::lesson or self::page or self::xhtml-page or self::api or self::package or self::hippo-root]">
			<xsl:if test="not(parent::top)">
				<xsl:value-of select="concat(@id, '/')"/>
			</xsl:if>
		</xsl:for-each>
		
		<xsl:text>index.html</xsl:text>
	</xsl:variable>
	
	<xsl:value-of select="$path"/>
</xsl:function>

<!-- Creates a relative file path starting w/ result-path(node) and backing down to root. -->
<xsl:function name="fn:root-path">
    <xsl:param name="node"/>
    <xsl:param name="file-name"/>
    
    <xsl:variable name="path">
    	<xsl:for-each select="$node/ancestor-or-self::*[self::group or self::item or self::set or self::guide or self::article or self::class or self::lesson or self::page or self::xhtml-page or self::api or self::package]">
    		<xsl:if test="not(parent::top)">
    			<xsl:value-of select="'../'"/>
    		</xsl:if>
    	</xsl:for-each>
    	
    	<xsl:value-of select="$file-name"/>
    </xsl:variable>
	
	<xsl:value-of select="$path"/>
</xsl:function>
	
<xsl:function name="fn:base-directory">
	<xsl:param name="current"/>
	
	<xsl:value-of select="file:getParent(file:new(uri:new(fn:get-uri($current))))"/>
</xsl:function>

<xsl:function name="fn:copy-file">
	<xsl:param name="source"/>
	<xsl:param name="destination"/>
	
	<xsl:if test="not(file:exists(file:new(string($source))))">
		<xsl:message>
			<xsl:text>ERROR: File does not exist</xsl:text>
			<xsl:text>&#10;  Source: </xsl:text>
			<xsl:value-of select="$source"/>
		</xsl:message>
	</xsl:if>
	
	<xsl:value-of select="fn:void(file:mkdirs(file:getParentFile(file:new(string($destination)))))"/>
	<xsl:value-of select="fn:void(runtime:exec(runtime:getRuntime(), concat('cp ', $source, ' ', $destination)))"/>
</xsl:function>
	
<xsl:function name="fn:copy-directory">
	<xsl:param name="source"/>
	<xsl:param name="destination"/>
	
	<xsl:value-of select="fn:void(file:mkdirs(file:getParentFile(file:new(string($destination)))))"/>
	<xsl:value-of select="fn:void(runtime:exec(runtime:getRuntime(), concat('cp -r ', $source, ' ', $destination)))"/>
</xsl:function>

<!-- If expr == true then returns the supplied 'true' othewise returns the supplied 'false'. -->
<xsl:function name="fn:iif">
    <xsl:param name="expr"/>
    <xsl:param name="true"/>
    <xsl:param name="false"/>
    
    <xsl:choose>
        <xsl:when test="$expr">
            <xsl:value-of select="$true"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$false"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:function>
	
<xsl:function name="fn:void">
	<xsl:param name="expr"/>
	
	<!-- Evaluate so that the expression will get executed but don't return anything. -->
	<xsl:if test="$expr">
		<xsl:text/>
	</xsl:if>
</xsl:function>
	
<xsl:function name="fn:trim">
	<xsl:param name="string"/>
	
	<xsl:value-of select="replace($string, '^(\s\n\r)*(.+?)(\s\n\r)*$', '$1')"/>
</xsl:function>
	
<xsl:function name="fn:equals">
	<xsl:param name="node1"/>
	<xsl:param name="node2"/>
	
	<xsl:copy-of select="generate-id($node1) = generate-id($node2)"/>
</xsl:function>
	
<!-- For nodes from imported documents, base-uri() doesn't return the actual URI path so we use
     the base-uri() of the current node and the base-uri() of its parent to figure it out.
     Specifically base-uri() includes duplicate nodes for imported child nodes so we clean out
     the duplicates by steping down the path using the parent's base-uri. -->
<xsl:function name="fn:get-uri">
	<xsl:param name="current"/>
	
	<xsl:if test="$current">
		<xsl:variable name="base-uri" select="base-uri($current[1])"/>
		
		<xsl:variable name="uri">
			<xsl:variable name="uri-parts" select="tokenize($base-uri, '/')"/>
			
			<xsl:value-of select="fn:dedup-uri($uri-parts, 1)"/>
		</xsl:variable>
		
		<!-- Emit an error if the URI doesn't actually exist. -->
		<xsl:if test="not(file:exists(file:new(uri:new($uri))))">
			<xsl:variable name="uri-chain" select="distinct-values($current/ancestor-or-self::*/base-uri())"/>
			
			<xsl:message>
				<xsl:text>ERROR: Uri doesn't exist</xsl:text>
				<xsl:text>&#10;  Uri: </xsl:text>
				<xsl:value-of select="$uri"/>
				
				<xsl:for-each select="$uri-chain">
					<xsl:text>&#10;    </xsl:text>
					<xsl:value-of select="."/>
				</xsl:for-each>
			</xsl:message>
		</xsl:if>
		
		<xsl:value-of select="$uri"/>
	</xsl:if>
</xsl:function>
<!-- Recursive de-dup companion method used by get-uri(). -->
<xsl:function name="fn:dedup-uri">
	<xsl:param name="uri-parts"/>
	<xsl:param name="from"/>
	
	<xsl:variable name="dedup-uri">
		<xsl:variable name="duplicate">
			<xsl:variable name="duplicates">
				<xsl:for-each select="$uri-parts">
					<xsl:variable name="position" select="position()"/>
					
					<xsl:if test="$position &gt; $from">
						<xsl:variable name="uri-prefix" select="fn:sub-uri($uri-parts, $from, $position - 1)"/>
						<xsl:variable name="sub-uri" select="fn:sub-uri($uri-parts, $position, last())"/>
						
						<xsl:if test="starts-with($sub-uri, $uri-prefix)">
							<xsl:text>#</xsl:text>
							<xsl:value-of select="$position"/>
							<xsl:text>#</xsl:text>
						</xsl:if>
					</xsl:if>
				</xsl:for-each>
			</xsl:variable>
			
			<xsl:value-of select="substring-before(substring-after($duplicates, '#'), '#')"/>
		</xsl:variable>
				
		<xsl:choose>
			<xsl:when test="string-length($duplicate) > 0">
				<xsl:value-of select="fn:dedup-uri($uri-parts, number($duplicate))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="$from &gt; 1">
					<xsl:text>/</xsl:text>
				</xsl:if>
				
				<xsl:value-of select="$uri-parts[$from]"/>
				
				<xsl:if test="$from &lt; count($uri-parts)">
					<xsl:value-of select="fn:dedup-uri($uri-parts, $from + 1)"/>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:value-of select="$dedup-uri"/>
</xsl:function>
<!-- Sub-URI companion method used by get-uri(). -->
<xsl:function name="fn:sub-uri">
	<xsl:param name="uri-parts"/>
	<xsl:param name="from"/>
	<xsl:param name="to"/>
	
	<xsl:variable name="sub-uri">
		<xsl:for-each select="$uri-parts">
			<xsl:variable name="position" select="position()"/>
			
			<xsl:if test="$position &gt;= $from and $position &lt;= $to">
				<xsl:if test="$position &gt; $from">
					<xsl:text>/</xsl:text>
				</xsl:if>
				<xsl:value-of select="."/>
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>
	
	<xsl:value-of select="$sub-uri"/>
</xsl:function>

<xsl:function name="fn:escape-css-name">
	<xsl:param name="current"/>
	
	<xsl:value-of select="replace(replace(lower-case($current), '[^a-z0-9\-\.\s]', ''), '\s', '-')"/>
</xsl:function>

</xsl:stylesheet>