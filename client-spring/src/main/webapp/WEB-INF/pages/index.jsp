<%@ page import="org.jasig.cas.client.authentication.AttributePrincipal" %>

<%
AttributePrincipal principal = (AttributePrincipal)request.getUserPrincipal();    
String username = principal.getName(); 
%>

<h1>This is CAS Client for Spring.</h1><br/>
Username: <%=username %><br/>
<a href="http://localhost:8080/client-java">Go Java Client</a><br/>
<a href="https://localhost:8443/cas/logout?service=http://www.google.com">logout</a><br/>