# 说明 #

这是一个使用 `Maven` 和 `CAS` 实现配置 CAS Server 的项目。
主要参考 [Best Practice - Setting Up CAS Locally using the Maven2 WAR Overlay Method]
(https://wiki.jasig.org/display/CASUM/Best+Practice+-+Setting+Up+CAS+Locally+using+the+Maven2+WAR+Overlay+Method)
这个文档。主要内容包括：

* 实现了 generic 和 jdbc 两个 Authentication 。
* 使用单机完成了两个客户端的 SSO 。
* 使用多机完成了两个客户端的 SSO 。
* CAS Server 的管理配置。

## 相关软件 ##
* cas-server-3 （这里用的是 3.4.11，可以在 pom 中配置）
* maven3
* jdk6
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
      `id` VARCHAR(45) NOT NULL ,
      `password` VARCHAR(45) NULL ,
      PRIMARY KEY (`id`) )
    ENGINE = InnoDB;

    INSERT INTO `cas`.`users` (`id`, `password`) VALUES ('admin', 'e10adc3949ba59abbe56e057f20f883e');

运行 mvn package 之后，把 cas.war 放到 Tomcat 中，使用 admin/123456 登录。

这里对密码 `123456` 做了 MD5 加密，如果在 authenticationHandlers 中去掉 `passwordEncoder` 这个属性，就可以使用明码登录。

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

## 三台机器 SSO ##

修改 hosts 文件（三台机器都增加以下内容）：

    # CAS Server
    10.4.251.149 batizhao

    # CAS Client for Java
    10.4.247.94 client-java

    # CAS Client for Spring
    10.4.247.95 client-spring

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

对 jsp 文件稍作修改，在三台机器任意一台登录客户端测试。

## CAS Server 的管理配置 ##

从源码中 Copy `cas.properties`（或者项目的 overlays 目录），修改 `server.prefix` ：  

    server.prefix=https://batizhao:8443/cas

重新部署 `server-jdbc`

    mvn clean package    
    
访问 `https://batizhao:8443/cas/services` ，使用之前的帐号密码登录。    

## 参考文档 ##
* [CAS User Manual](https://wiki.jasig.org/display/CASUM/Home)
* [CAS Client](https://wiki.jasig.org/display/CASC/CAS+Client+for+Java+3.1)
* [SSL Troubleshooting and Reference Guide](https://wiki.jasig.org/display/CASUM/SSL+Troubleshooting+and+Reference+Guide)

