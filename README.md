# 说明 #

这是一个使用 `Maven` 和 `CAS` 定制 CAS 的项目。
最开始以 [Best Practice - Setting Up CAS Locally using the Maven2 WAR Overlay Method]
(https://wiki.jasig.org/display/CASUM/Best+Practice+-+Setting+Up+CAS+Locally+using+the+Maven2+WAR+Overlay+Method) 为指导，
后续又作了很多扩展。主要内容包括：

* 实现了 Generic(server-generic), Jdbc(server-jdbc), LDAP(server-ldap) 三种 Authentication 。
* 实现了 Java(client-java), Spring(client-spring), Spring Security(client-spring-security) 三种客户端。
* 使用单机完成了三个客户端的 SSO 。
* 使用多机完成了三个客户端的 SSO 。
* CAS without SSL 。
* 整合遗留系统。

## 相关软件 ##
* cas-server-3.4.11
* cas-client-core 3.2.0
* maven3
* jdk6
* spring 3.0.5.RELEASE
* spring security 3.0.6.RELEASE
* openDJ 2.4.3
* tomcat7

## CAS Server 配置 ##

主要内容都可以参考 `Best Practice`，这里只对 `配置 Tomcat 的 HTTPS` 做一点修改 。

    # keytool -genkey -alias tomcat -keyalg RSA -validity 365 -keystore my.keystore
    输入keystore密码：
    再次输入新密码:
    您的名字与姓氏是什么？
      [Unknown]：  localhost
    您的组织单位名称是什么？
      [Unknown]：
    您的组织名称是什么？
      [Unknown]：
    您所在的城市或区域名称是什么？
      [Unknown]：
    您所在的州或省份名称是什么？
      [Unknown]：
    该单位的两字母国家代码是什么
      [Unknown]：
    CN=localhost, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=Unknown 正确吗？
      [否]：  y

    输入<tomcat>的主密码
            （如果和 keystore 密码相同，按回车）：

修改 Tomcat 的 server.xml 文件(注意这里对 protocol 进行了修改)：

    <Connector protocol="org.apache.coyote.http11.Http11NioProtocol"
               port="8443" SSLEnabled="true"
               maxThreads="150" scheme="https" secure="true"
               clientAuth="false" sslProtocol="TLS"
               keystoreFile="conf/my.keystore" keystorePass="123456"/>

### Generic Authentication ###

在 server-generic 模块中，从源码中 Copy `deployerConfigContext.xml`（或者项目的 overlays 目录），把其中的以下代码注释：

    <bean class="org.jasig.cas.authentication.handler.support.SimpleTestUsernamePasswordAuthenticationHandler" />

修改为：

    <bean class="org.jasig.cas.adaptors.generic.AcceptUsersAuthenticationHandler">
        <property name="users">
            <map>
                <entry>
                    <key>
                        <value>scott</value>
                    </key>
                    <value>secret</value>
                </entry>
            </map>
        </property>
    </bean>

运行 mvn package 之后，把 cas.war 放到 Tomcat 中，使用 scott/secret 登录。
认证信息在 authenticationHandlers 中配置。

### JDBC Authentication ###

这个模块对 SearchModeSearchDatabaseAuthenticationHandler 和 QueryDatabaseAuthenticationHandler 都做了配置。
但默认实现是 QueryDatabaseAuthenticationHandler ，并且对密码做了 MD5 加密。

在 server-jdbc 模块使用之前，需要先在 mysql 中执行以下语句：

    CREATE DATABASE cas;
    CREATE  TABLE `cas`.`users` (
      `username` VARCHAR(45) NOT NULL ,
      `password` VARCHAR(45) NULL ,
      PRIMARY KEY (`username`) )
    ENGINE = InnoDB;

    INSERT INTO `cas`.`users` (`username`, `password`) VALUES ('admin', 'e10adc3949ba59abbe56e057f20f883e');
    INSERT INTO `cas`.`users` (`username`, `password`) VALUES ('rod', 'e10adc3949ba59abbe56e057f20f883e');


运行 mvn package 之后，把 cas.war 放到 Tomcat 中，使用 admin/123456 登录。

这里对密码 `123456` 做了 MD5 加密，如果在 authenticationHandlers 中去掉 `passwordEncoder` 这个属性，就可以使用明码登录。

### LDAP Authentication ###

请参考[这里](https://wiki.jasig.org/display/CASUM/LDAP)

### 实现 Single Sign Out 后返回到自定义页面 ###

从源码 Copy `cas-servlet.xml` 到 `server-jdbc`，找到以下代码，增加属性 `p:followServiceRedirects="true"`

    <bean id="logoutController" class="org.jasig.cas.web.LogoutController" ... .../>

运行 mvn clean package，重新部署 CAS Server。

客户端 logout 时，使用：

    https://localhost:8443/cas/logout?service=你要跳转的URL

## CAS Client 配置 ##

根据 Server 的 my.keystore 导出客户端证书：

    # keytool -export -alias tomcat -file server.crt -keystore my.keystore

导入 Client JVM 默认的 keystore（客户端 Tomcat 使用的 JVM，cacerts 的默认密码是 `changeit`）：

    # keytool -import -file server.crt -keystore $JAVA_HOME/lib/security/cacerts -alias tomcat
    
在 Mac 上，这里的 `cacerts` 可能是：

    /System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents/Home/lib/security/cacerts
    
在 Win 上，这里的 `cacerts` 可能是：

    D:\jdk1.6\jre\lib\security\cacerts
    
查看证书的命令是：

    # keytool -list -keystore $JAVA_HOME/lib/security/cacerts -alias tomcat

测试

* 分别打开 http://localhost:8080/client-java 或 http://localhost:8080/client-spring ，都被重定向到登录界面。
* 任意登录其中之一，然后在浏览器直接输入另外一个地址，可以看到已经不需要登录。
* Single Sign Out: https://localhost:8443/cas/logout（Spring 客户端的 logout 好像不起作用，Java 客户端没问题）

## 四台机器 SSO ##

修改 hosts 文件（四台机器都增加以下内容）：

    # CAS Server
    10.4.251.149 batizhao

    # CAS Client for Java
    10.4.247.94 client-java

    # CAS Client for Spring
    10.4.247.95 client-spring
    
    # CAS Client for Spring Security
    10.4.247.96 client-spring-security

根据域名重新生成证书（在这里只能使用域名，不可以使用 IP，否则会抛出异常）。在使用之前删除原证书（如果 alias 不变）：

    # keytool -delete -keystore $JAVA_HOME/lib/security/cacerts -alias tomcat

参考 `CAS Server 配置` 这一段，使用 `batizhao` 替换 `localhost` 生成新证书。参考 `CAS Client 配置` 重新导出服务端证书，并导入客户端。

修改 `client-java` web.xml ：

    <filter>
        <filter-name>CAS Authentication Filter</filter-name>
        <filter-class>org.jasig.cas.client.authentication.AuthenticationFilter</filter-class>
        <init-param>
            <param-name>casServerLoginUrl</param-name>
            <param-value>https://batizhao:8443/cas/login</param-value>
        </init-param>
        <init-param>
            <param-name>serverName</param-name>
            <param-value>http://client-java</param-value>
        </init-param>
    </filter>

    <filter>
        <filter-name>CAS Validation Filter</filter-name>
        <filter-class>org.jasig.cas.client.validation.Cas20ProxyReceivingTicketValidationFilter</filter-class>
        <init-param>
            <param-name>casServerUrlPrefix</param-name>
            <param-value>https://batizhao:8443/cas</param-value>
        </init-param>
        <init-param>
            <param-name>serverName</param-name>
            <param-value>http://client-java</param-value>
        </init-param>
    </filter>

修改 `client-spring` applicationContext.xml ：

    <bean name="authenticationFilter"
          class="org.jasig.cas.client.authentication.AuthenticationFilter"
          p:casServerLoginUrl="https://batizhao:8443/cas/login"
          p:renew="false"
          p:gateway="false"
          p:service="http://client-spring/client-spring"/>

    <bean name="validationFilter"
          class="org.jasig.cas.client.validation.Cas20ProxyReceivingTicketValidationFilter"
          p:service="http://client-spring/client-spring">
        <property name="ticketValidator">
            <bean class="org.jasig.cas.client.validation.Cas20ServiceTicketValidator">
                <constructor-arg index="0" value="https://batizhao:8443/cas"/>
            </bean>
        </property>
    </bean>
    
修改 `client-spring-security` applicationContext-security.xml 为以下内容，其余都替换为 Server 地址。

    <bean id="serviceProperties" class="org.springframework.security.cas.ServiceProperties">
        <property name="service" value="http://client-spring-security/j_spring_cas_security_check"/>
        <property name="sendRenew" value="false"/>
    </bean>

对 jsp 文件稍作修改，在四台机器任意一台登录客户端测试。

## CAS without SSL ##

之前使用 SSL 证书的时候，单机 CN 是使用 localhost ，多机使用自己定制的机器名或者域名（通过修改 hosts）。 

关于 SSL： 

* HTTPS 是 CAS Server 的默认访问通道，由于考虑到安全性，数据都通过 SSL 通道加密传送。 
* 使用 HTTPS 时，CA 证书是必须的，而生成证书时的 CN 尤其重要，其他应用访问 CAS Server 的时候也受到 CN 所影响，若不匹配则会报异常。
* CN 不可以使用 IP，否则会抛出 `java.security.cert.CertificateException: No subject alternative names present`。
* 在生产环境中，CN 不可以使用 localhost ，因为其他应用访问时也必须以 `https://CN/` 这样的访问限定。 
* 在内网中，如果没有 DNS Server，只能靠 hosts 作 CN 的域名映射。那每台 CAS Server 和 CAS Client 的 hosts 都必须增加 CN 和 IP 映射条目（甚至包括每个浏览器客户端）。这会带来大量难以预知的问题。 
* 默认情况下不信任的授权机构生成的 CA 证书必然引起浏览器提示。
* 如果对安全性要求不高，可能需要去掉 SSL 。

如何去掉 SSL ？

修改 `deployerConfigContext.xml`，找到以下内容，增加属性 `p:requireSecure="false"`：

    <bean class="org.jasig.cas.authentication.handler.support.HttpBasedServiceCredentialsAuthenticationHandler"
                      p:httpClient-ref="httpClient"/>
                      
在 WEB-INF 下增加目录 `spring-configuration`，放入 `ticketGrantingTicketCookieGenerator.xml` 和 `warnCookieGenerator.xml`，
找到 `p:cookieSecure="true"`，替换为 `p:cookieSecure="false"`。

重新部署 `server-jdbc`

    mvn clean package
    
访问 `http://IP:8080/cas/login` ，使用之前的帐号密码可以登录。在登录界面，CAS 会警告 `Non-secure Connection
You are currently accessing CAS over a non-secure connection. 
Single Sign On WILL NOT WORK. In order to have single sign on work, 
you MUST log in over HTTPS.` 这个可以忽略。同时修改所有 Client 的配置，都改为 IP 就可以了。

## client-spring-security ##

我们知道，Spring Security 本身已经支持各种方式的认证（内存、数据库、LDAP...）。
前边的 `client-java`, `client-spring` 都没有自己的认证模块，完全依赖于 CAS Server。
对于遗留系统，已经拥有自己的用户数据库，也有自己的认证模块。`client-spring-security` 主要演示了在这种场景下如何整合。

首先，我们假设遗留系统已经存在用户表 users 和权限表 authorities：

    CREATE DATABASE cas_ss;

    CREATE TABLE `users` (
      `username` varchar(45) NOT NULL,
      `password` varchar(45) DEFAULT NULL,
      `enabled` varchar(10) NOT NULL,
      PRIMARY KEY (`username`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    INSERT INTO `users` VALUES ('admin', 'e10adc3949ba59abbe56e057f20f883e', 'true');
    INSERT INTO `users` VALUES ('rod', 'e10adc3949ba59abbe56e057f20f883e', 'true');

    CREATE TABLE `authorities` (
      `username` varchar(45) NOT NULL,
      `authority` varchar(45) DEFAULT NULL,
      KEY `fk_authorities_users` (`username`),
      CONSTRAINT `fk_authorities_users` FOREIGN KEY (`username`) REFERENCES `users` (`username`) ON DELETE NO ACTION ON UPDATE NO ACTION
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    INSERT INTO `authorities` VALUES ('admin', 'ROLE_USER'), ('admin', 'ROLE_SUPERVISOR');
    INSERT INTO `authorities` VALUES ('rod', 'ROLE_USER');

这里可以不用部署到 Tomcat，直接运行 mvn jetty:run，访问 http://localhost:8081/，分别用 `admin` 和 `rod` 登录，
在 CAS 认证完成后转到应用首页，Spring Security 的授权已经生效。
 
## 整合遗留系统 ##

### Spring Security 应用 ###

如果你的系统是基于 Spring Security 构建，那整合 CAS 就非常容易，基本改几个配置就可以。
如果你的项目基于 Maven ，只要在 pom.xml 文件中增加

    <dependency>
        <groupId>org.springframework.security</groupId>
        <artifactId>spring-security-cas-client</artifactId>
        <version>${spring.version}</version>
    </dependency>
    
如果你的 *-servlet.xml 文件中有配置 `path="/"` 神马的，把他注释掉。比如下边的代码。

    <!--<mvc:view-controller path="/" view-name="login"/>-->

打开你的 applicationContext-security.xml，基本配置如下：

    <?xml version="1.0" encoding="UTF-8"?>
	<beans xmlns="http://www.springframework.org/schema/beans"
		   xmlns:sec="http://www.springframework.org/schema/security"
		   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
		   xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-3.0.xsd
							http://www.springframework.org/schema/security http://www.springframework.org/schema/security/spring-security-3.0.xsd">
	
		<sec:http entry-point-ref="casProcessingFilterEntryPoint">
			<sec:intercept-url pattern="/secure/extreme/**" access="ROLE_SUPERVISOR" requires-channel="http"/>
			<sec:intercept-url pattern="/secure/**" access="ROLE_USER"/>
			<sec:logout logout-success-url="/cas-logout.jsp"/>
			<sec:custom-filter ref="requestSingleLogoutFilter" before="LOGOUT_FILTER"/>
			<sec:custom-filter ref="singleLogoutFilter" before="CAS_FILTER"/>
			<sec:custom-filter ref="casAuthenticationFilter" after="CAS_FILTER"/>
		</sec:http>
	
		<!-- 客户端配置 -->
		<bean id="serviceProperties" class="org.springframework.security.cas.ServiceProperties">
			<property name="service" value="http://localhost:8080/client-spring-security/j_spring_cas_security_check"/>
			<property name="sendRenew" value="false"/>
		</bean>
	
		<!-- CAS 认证入口 -->
		<bean id="casProcessingFilterEntryPoint" class="org.springframework.security.cas.web.CasAuthenticationEntryPoint">
			<property name="loginUrl" value="http://localhost:8080/cas/login"/>
			<property name="serviceProperties" ref="serviceProperties"/>
		</bean>
	
		<!-- CAS 认证过滤器，认证管理器、成功、失败配置 -->
		<bean id="casAuthenticationFilter" class="org.springframework.security.cas.web.CasAuthenticationFilter">
			<property name="authenticationManager" ref="authenticationManager"/>
			<property name="authenticationFailureHandler">
				<bean class="org.springframework.security.web.authentication.SimpleUrlAuthenticationFailureHandler">
					<property name="defaultFailureUrl" value="/casfailed.jsp"/>
				</bean>
			</property>
			<!-- 登录成功后的页面，如果是固定的。否则 ref="authenticationSuccessHandler" -->
			<property name="authenticationSuccessHandler">
				<bean class="org.springframework.security.web.authentication.SimpleUrlAuthenticationSuccessHandler">
					<property name="defaultTargetUrl" value="/"/>
				</bean>
			</property>
		</bean>
	
		<sec:authentication-manager alias="authenticationManager">
			<sec:authentication-provider ref="casAuthenticationProvider"/>
		</sec:authentication-manager>
	
		<bean id="casAuthenticationProvider"
			  class="org.springframework.security.cas.authentication.CasAuthenticationProvider">
			<property name="authenticationUserDetailsService" ref="authenticationUserDetailsService"/>
			<property name="serviceProperties" ref="serviceProperties"></property>
			<property name="ticketValidator">
				<bean class="org.jasig.cas.client.validation.Cas20ServiceTicketValidator">
					<constructor-arg index="0" value="http://localhost:8080/cas"/>
				</bean>
			</property>
			<property name="key" value="cas"></property>
		</bean>
	
		<bean id="authenticationUserDetailsService"
			  class="org.springframework.security.cas.userdetails.GrantedAuthorityFromAssertionAttributesUserDetailsService">
			<constructor-arg>
				<array>
					<value>authorities</value>
				</array>
			</constructor-arg>
		</bean>
	
		<!-- This filter redirects to the CAS Server to signal Single Logout should be performed -->
		<bean id="requestSingleLogoutFilter"
			  class="org.springframework.security.web.authentication.logout.LogoutFilter">
			<constructor-arg value="http://localhost:8080/cas/logout"/>
			<constructor-arg>
				<bean class="org.springframework.security.web.authentication.logout.SecurityContextLogoutHandler"/>
			</constructor-arg>
			<property name="filterProcessesUrl" value="/j_spring_cas_security_logout"/>
		</bean>
		<!-- This filter handles a Single Logout Request from the CAS Server -->
		<bean id="singleLogoutFilter" class="org.jasig.cas.client.session.SingleSignOutFilter"/>
	
		<bean class="org.springframework.security.web.access.expression.DefaultWebSecurityExpressionHandler"/>
	
	</beans>
    
实现登录后自定义的跳转处理：

    public class MyAuthenticationSuccessHandler extends SimpleUrlAuthenticationSuccessHandler {           
    
        @Override
        public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response, Authentication authentication)
                throws IOException, ServletException {
    
            User user = (User) authentication.getPrincipal();            
            HttpSession session = request.getSession();
            session.setAttribute(Constants.CURRENT_USER, user);
            session.setAttribute(Constants.ENTITIES, entities);
    
            if (authentication != null) {
                setDefaultTargetUrl(getDefaultUrl(user.getUserId()));
                super.onAuthenticationSuccess(request, response, authentication);
            }
        }    
    }
    
这样配置就基本完成了。这里实现整合的原则就是：

* username 全局唯一，并且各业务系统保持和 CAS Server 数据库的同步（CAS 提供一个同步帐号密码的接口）。
* 当某一个业务系统密码改变以后，也需要同步到 CAS Server 数据库（CAS 提供一个修改密码的接口）。
* 当首次访问系统中任意需要认证的页面时，会自动跳转到 CAS Server 端的登录页面。
* 认证完成后，CAS 会跳转回你之前需要访问的系统，由业务系统自己完成授权（比如前边的表：authorities）。    

## 参考文档 ##
* [CAS User Manual](https://wiki.jasig.org/display/CASUM/Home)
* [CAS Client](https://wiki.jasig.org/display/CASC/CAS+Client+for+Java+3.1)
* [SSL Troubleshooting and Reference Guide](https://wiki.jasig.org/display/CASUM/SSL+Troubleshooting+and+Reference+Guide)

