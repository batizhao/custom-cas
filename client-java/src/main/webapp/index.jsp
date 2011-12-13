<%@ page import="org.jasig.cas.client.authentication.AttributePrincipal" %>

<%
AttributePrincipal principal = (AttributePrincipal)request.getUserPrincipal();
String username = principal.getName(); 
%>

<h1>This is CAS Client for Java.</h1><br/>
Username: <%=username %><br/>
<a href="http://localhost:8080/client-spring">Go Spring Client</a><br/>
<a href="https://localhost:8443/cas/logout?service=https://twitter.com">logout</a><br/>