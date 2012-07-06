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
            <h2><spring:message code="screen.logout.header"/></h2>

            <form id="auth-form">

                <p><span class="label label-info">信息</span> <spring:message code="screen.logout.success"/></p>

                <p><span class="label label-warning">警告</span> <spring:message code="screen.logout.security"/></p>

                <p><a class="btn btn-primary btn-large" href="login">重新登录</a></p>

                <p></p>
            </form>
        </div>
    </div>
</div>

<jsp:directive.include file="includes/footer.jsp"/>

</body>
</html>