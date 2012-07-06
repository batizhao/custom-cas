<!DOCTYPE html>
<%@ page contentType="text/html; charset=utf-8" %>
<jsp:directive.include file="includes/taglibs.jsp"/>

<html lang="utf-8">

<jsp:directive.include file="includes/header.jsp"/>

<body data-spy="scroll" data-target=".subnav" data-offset="50">

<jsp:directive.include file="includes/top.jsp"/>

<div class="container">
    <div class="row-fluid">
        <div id="login" class="accounts-form">
            <h2><spring:message code="screen.welcome.instructions"/></h2>
            <form:form method="post" id="auth-form" commandName="${commandName}" htmlEscape="true">
                <div class="control-group error">
                    <div class="controls">
                        <form:errors path="*" id="msg" cssClass="help-inline" element="span"/>
                    </div>
                </div>
                <%--<spring:message code="screen.welcome.welcome"/>--%>
                <div class="control-group">
                    <c:if test="${not empty sessionScope.openIdLocalId}">
                        <strong>${sessionScope.openIdLocalId}</strong>
                        <input type="hidden" id="username" name="username" value="${sessionScope.openIdLocalId}"/>
                    </c:if>
                    <c:if test="${empty sessionScope.openIdLocalId}">
                        <spring:message code="screen.welcome.label.netid.accesskey" var="userNameAccessKey"/>
                        <spring:message code="screen.welcome.label.netid" var="username_placeholder"/>
                        <form:input id="username" tabindex="1" accesskey="${userNameAccessKey}" path="username"
                                    cssClass="required" cssErrorClass="alert alert-error"
                                    placeholder="${username_placeholder}" autocomplete="false" htmlEscape="true"/>
                    </c:if>
                </div>
                <div class="control-group">
                    <spring:message code="screen.welcome.label.password.accesskey" var="passwordAccessKey"/>
                    <spring:message code="screen.welcome.label.password" var="password_placeholder"/>
                    <form:password id="password" size="25" tabindex="2" path="password" accesskey="${passwordAccessKey}"
                                   cssClass="required" cssErrorClass="alert alert-error"
                                   placeholder="${password_placeholder}" htmlEscape="true" autocomplete="off"/>
                </div>
                <div>
                    <input type="hidden" name="lt" value="${loginTicket}"/>
                    <input type="hidden" name="execution" value="${flowExecutionKey}"/>
                    <input type="hidden" name="_eventId" value="submit"/>

                    <input class="btn btn-success" name="submit" accesskey="l"
                           value="<spring:message code="screen.welcome.button.login" />" tabindex="3" type="submit"/>
                </div>
            </form:form>
        </div>
        <p class="note"><a href="/accounts/password/reset">忘记密码？</a></p>
    </div>
</div>

<jsp:directive.include file="includes/footer.jsp"/>

</body>
</html>