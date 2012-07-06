<%@ page contentType="text/html; charset=utf-8" %>
<head>
    <meta charset="utf-8">
    <title>CAS | Central Authentication Service</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="">
    <meta name="author" content="">

    <c:choose>
        <c:when test="${not empty requestScope['isMobile'] and not empty mobileCss}">
            <meta name="viewport" content="width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;"/>
            <meta name="apple-mobile-web-app-capable" content="yes"/>
            <meta name="apple-mobile-web-app-status-bar-style" content="black"/>
            <link type="text/css" rel="stylesheet" media="screen"
                  href="<c:url value="/css/fss-framework-1.1.2.css" />"/>
            <link type="text/css" rel="stylesheet"
                  href="<c:url value="/css/fss-mobile-${requestScope['browserType']}-layout.css" />"/>
            <link type="text/css" rel="stylesheet" href="${mobileCss}"/>
        </c:when>
        <c:otherwise>
            <spring:theme code="standard.custom.css.file" var="customCssFile"/>
            <link type="text/css" rel="stylesheet" href="<c:url value="${customCssFile}" />"/>
            <link href="<c:url value='/themes/cas-theme-twitter-bootstrap/css/theme.css'/>" rel="stylesheet">
        </c:otherwise>
    </c:choose>

    <!-- Le HTML5 shim, for IE6-8 support of HTML5 elements -->
    <!--[if lt IE 9]>
    <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->

    <link rel="icon" href="<c:url value="/themes/cas-theme-twitter-bootstrap/ico/favicon.ico" />" type="image/x-icon"/>
    <link rel="shortcut icon" href="<c:url value='/themes/cas-theme-twitter-bootstrap/ico/favicon.ico'/>">
    <link rel="apple-touch-icon-precomposed" sizes="144x144"
          href="<c:url value='/themes/cas-theme-twitter-bootstrap/ico/apple-touch-icon-144-precomposed.png'/>">
    <link rel="apple-touch-icon-precomposed" sizes="114x114"
          href="<c:url value='/themes/cas-theme-twitter-bootstrap/ico/apple-touch-icon-114-precomposed.png'/>">
    <link rel="apple-touch-icon-precomposed" sizes="72x72"
          href="<c:url value='/themes/cas-theme-twitter-bootstrap/ico/apple-touch-icon-72-precomposed.png'/>">
    <link rel="apple-touch-icon-precomposed"
          href="<c:url value='/themes/cas-theme-twitter-bootstrap/ico/apple-touch-icon-57-precomposed.png'/>">
</head>