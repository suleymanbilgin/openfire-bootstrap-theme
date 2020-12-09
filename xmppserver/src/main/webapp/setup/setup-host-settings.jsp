<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.net.InetAddress" %>
<%@ page import="java.net.UnknownHostException" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.HashSet" %>
<%@ page import="java.util.Map" %>
<%@ page import="org.jivesoftware.openfire.XMPPServer" %>
<%@ page import="org.jivesoftware.openfire.sasl.AnonymousSaslServer" %>
<%@ page import="org.jivesoftware.openfire.session.ConnectionSettings" %>
<%@ page import="org.jivesoftware.util.JiveGlobals" %>
<%@ page import="org.jivesoftware.util.ParamUtils" %>
<%@ page import="org.jivesoftware.util.StringUtils" %>
<%@ page import="org.xmpp.packet.JID" %>
<%@ page import="org.jivesoftware.openfire.XMPPServerInfo" %>
<%@ page import="org.jivesoftware.util.CookieUtils" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>

<%
    // Redirect if we've already run setup:
    if (!XMPPServer.getInstance().isSetupMode()) {
        response.sendRedirect("setup-completed.jsp");
        return;
    }
%>

<% // Get parameters
    String domain = ParamUtils.getParameter(request, "domain");
    String fqdn = ParamUtils.getParameter(request, "fqdn");
    int embeddedPort = ParamUtils.getIntParameter(request, "embeddedPort", Integer.MIN_VALUE);
    int securePort = ParamUtils.getIntParameter(request, "securePort", Integer.MIN_VALUE);
    boolean sslEnabled = ParamUtils.getBooleanParameter(request, "sslEnabled", true);
    boolean anonymousAuthentication = JiveGlobals.getXMLProperty(AnonymousSaslServer.ENABLED.getKey(), false);
    String encryptionAlgorithm = ParamUtils.getParameter(request, "encryptionAlgorithm");
    String encryptionKey = ParamUtils.getParameter(request, "encryptionKey");

    boolean doContinue = request.getParameter("continue") != null;

    Cookie csrfCookie = CookieUtils.getCookie(request, "csrf");
    String csrfParam = ParamUtils.getParameter(request, "csrf");

    // Handle a continue request:
    Map<String, String> errors = new HashMap<>();

    if (doContinue) {
        if (csrfCookie == null || csrfParam == null || !csrfCookie.getValue().equals(csrfParam)) {
            doContinue = false;
            errors.put("csrf", "CSRF Failure!");
        }
    }

    csrfParam = StringUtils.randomString(15);
    CookieUtils.setCookie(request, response, "csrf", csrfParam, -1);
    pageContext.setAttribute("csrf", csrfParam);

    if (doContinue) {
        // Validate parameters
        if (domain == null || domain.isEmpty()) {
            errors.put("domain", "domain");
        } else {
            try {
                domain = JID.domainprep(domain);
            } catch (IllegalArgumentException e) {
                errors.put("domain", "domain");
            }
        }
        if (fqdn == null || fqdn.isEmpty()) {
            errors.put("fqdn", "fqdn");
        } else {
            try {
                fqdn = JID.domainprep(fqdn);
            } catch (IllegalArgumentException e) {
                errors.put("fqdn", "fqdn");
            }
        }
        if (XMPPServer.getInstance().isStandAlone()) {
            if (embeddedPort == Integer.MIN_VALUE) {
                errors.put("embeddedPort", "embeddedPort");
            }
            // Force any negative value to -1.
            else if (embeddedPort < 0) {
                embeddedPort = -1;
            }

            if (securePort == Integer.MIN_VALUE) {
                errors.put("securePort", "securePort");
            }
            // Force any negative value to -1.
            else if (securePort < 0) {
                securePort = -1;
            }

            if (encryptionKey != null) {
                // ensure the same key value was provided twice
                String repeat = ParamUtils.getParameter(request, "encryptionKey1");
                if (!encryptionKey.equals(repeat)) {
                    errors.put("encryptionKey", "encryptionKey");
                }
            }
        } else {
            embeddedPort = -1;
            securePort = -1;
        }
        // Continue if there were no errors
        if (errors.size() == 0) {
            Map<String, String> xmppSettings = new HashMap<String, String>();

            xmppSettings.put(XMPPServerInfo.XMPP_DOMAIN.getKey(), domain);
            xmppSettings.put(ConnectionSettings.Client.ENABLE_OLD_SSLPORT_PROPERTY.getKey(), "" + sslEnabled);
            xmppSettings.put(AnonymousSaslServer.ENABLED.getKey(), "" + anonymousAuthentication);
            session.setAttribute("xmppSettings", xmppSettings);

            Map<String, String> xmlSettings = new HashMap<String, String>();
            xmlSettings.put("adminConsole.port", Integer.toString(embeddedPort));
            xmlSettings.put("adminConsole.securePort", Integer.toString(securePort));
            xmlSettings.put("fqdn", fqdn);
            session.setAttribute("xmlSettings", xmlSettings);

            session.setAttribute("encryptedSettings", new HashSet<String>());

            JiveGlobals.setupPropertyEncryptionAlgorithm(encryptionAlgorithm);
            JiveGlobals.setupPropertyEncryptionKey(encryptionKey);

            // Successful, so redirect
            response.sendRedirect("setup-datasource-settings.jsp");
            return;
        }
    }

    // Load the current values:
    if (!doContinue) {
        domain = JiveGlobals.getXMLProperty(XMPPServerInfo.XMPP_DOMAIN.getKey());
        fqdn = JiveGlobals.getXMLProperty("fqdn");
        embeddedPort = JiveGlobals.getXMLProperty("adminConsole.port", 9090);
        securePort = JiveGlobals.getXMLProperty("adminConsole.securePort", 9091);

        // If the fqdn (server name) is still blank, guess:
        if (fqdn == null || fqdn.isEmpty()) {
            try {
                fqdn = InetAddress.getLocalHost().getCanonicalHostName();
            } catch (UnknownHostException ex) {
                System.err.println("Unable to determine the fully qualified domain name (canonical hostname) of this server.");
                ex.printStackTrace();
                fqdn = "localhost";
            }
        }

        // If the domain is still blank, use the host name.
        if (domain == null) {
            domain = fqdn;
        }
    }

    pageContext.setAttribute("errors", errors);
    pageContext.setAttribute("domain", domain);
    pageContext.setAttribute("fqdn", fqdn);
    if (embeddedPort != Integer.MIN_VALUE) {
        pageContext.setAttribute("embeddedPort", embeddedPort);
    }
    if (securePort != Integer.MIN_VALUE) {
        pageContext.setAttribute("securePort", securePort);
    }
    pageContext.setAttribute("xmppServer", XMPPServer.getInstance());
%>

<html>
<head>
    <title><fmt:message key="setup.host.settings.title"/></title>
    <meta name="currentStep" content="1"/>
</head>
<body>

<c:if test="${not empty errors['csrf']}">
    <div class="alert alert-danger" role="alert">
        <fmt:message key="global.csrf.failed"/>
    </div>
</c:if>

<h1>
    <fmt:message key="setup.host.settings.title"/>
</h1>

<p>
    <fmt:message key="setup.host.settings.info"/>
</p>


<form action="setup-host-settings.jsp" name="f" method="post">
    <input type="hidden" name="csrf" value="${csrf}">

    <div class="form-group">
        <label for="domain"><fmt:message key="setup.host.settings.domain"/></label>
        <input  class="form-control" type="text" size="30" maxlength="150" name="domain" id="domain" value="${not empty domain ? fn:escapeXml(domain) : ''}">
        <c:if test="${not empty errors['domain']}">
            <span class="jive-error-text">
            <fmt:message key="setup.host.settings.invalid_domain"/>
            </span>
        </c:if>
    </div>


    <div class="form-group">
        <label for="fqdn"><fmt:message key="setup.host.settings.fqdn"/></label>
        <input class="form-control" type="text" size="30" maxlength="150" name="fqdn" id="fqdn"
               value="${not empty fqdn ? fn:escapeXml(fqdn) : ''}">        <c:if test="${not empty errors['domain']}">
            <span class="jive-error-text">
            <fmt:message key="setup.host.settings.invalid_fqdn"/>
            </span>
        </c:if>
    </div>


        <c:if test="${xmppServer.standAlone}">
            <tr valign="top">
                <td width="1%" nowrap align="right">
                    <label for="embeddedPort"><fmt:message key="setup.host.settings.port"/></label>
                </td>
                <td width="99%">
                    <input type="number" min="1" max="65535" size="6" maxlength="6" name="embeddedPort"
                           id="embeddedPort" value="${not empty embeddedPort ? embeddedPort : 9090}">
                    <span class="jive-setup-helpicon" onmouseover="domTT_activate(this, event, 'content', '<fmt:message
                        key="setup.host.settings.port_number"/>', 'styleClass', 'jiveTooltip', 'trail', true, 'delay', 300, 'lifetime', 8000);"></span>
                    <c:if test="${not empty errors['embeddedPort']}">
            <span class="jive-error-text">
            <fmt:message key="setup.host.settings.invalid_port"/>
            </span>
                    </c:if>
                </td>
            </tr>
            <tr valign="top">
                <td width="1%" nowrap align="right">
                    <label for="securePort"><fmt:message key="setup.host.settings.secure_port"/></label>
                </td>
                <td width="99%">
                    <input type="number" min="1" max="65535" size="6" maxlength="6" name="securePort" id="securePort"
                           value="${not empty securePort ? securePort : 9091}">
                    <span class="jive-setup-helpicon" onmouseover="domTT_activate(this, event, 'content', '<fmt:message
                        key="setup.host.settings.secure_port_number"/>', 'styleClass', 'jiveTooltip', 'trail', true, 'delay', 300, 'lifetime', 8000);"></span>
                    <c:if test="${not empty errors['securePort']}">
            <span class="jive-error-text">
            <fmt:message key="setup.host.settings.invalid_port"/>
            </span>
                    </c:if>
                </td>
            </tr>
            <tr valign="top">
                <td width="1%" nowrap align="right">
                    <fmt:message key="setup.host.settings.encryption_algorithm"/>
                </td>
                <td width="99%">
                    <span class="jive-setup-helpicon" onmouseover="domTT_activate(this, event, 'content', '<fmt:message
                        key="setup.host.settings.encryption_algorithm_info"/>', 'styleClass', 'jiveTooltip', 'trail', true, 'delay', 300, 'lifetime', 8000);"></span><br/><br/>
                    <input type="radio" name="encryptionAlgorithm" value="Blowfish" id="Blowfish" checked><label
                    for="Blowfish"><fmt:message key="setup.host.settings.encryption_blowfish"/></label><br/><br/>
                    <input type="radio" name="encryptionAlgorithm" value="AES" id="AES"><label for="AES"><fmt:message
                    key="setup.host.settings.encryption_aes"/></label><br/><br/>
                </td>
            </tr>
            <tr valign="top">
                <td width="1%" nowrap align="right">
                    <label for="encryptionKey"><fmt:message key="setup.host.settings.encryption_key"/></label>
                </td>
                <td width="99%">
                    <input type="password" size="50" name="encryptionKey" id="encryptionKey"/><br/><br/>
                    <input type="password" size="50" name="encryptionKey1" id="encryptionKey1"/>
                    <span class="jive-setup-helpicon" onmouseover="domTT_activate(this, event, 'content', '<fmt:message
                        key="setup.host.settings.encryption_key_info"/>', 'styleClass', 'jiveTooltip', 'trail', true, 'delay', 300, 'lifetime', 8000);"></span>
                    <c:if test="${not empty errors['encryptionKey']}">
            <span class="jive-error-text">
            <fmt:message key="setup.host.settings.encryption_key_invalid"/>
            </span>
                    </c:if>
                </td>
            </tr>
        </c:if>
    </table>

    <br><br>

    <button type="Submit" name="save" id="jive-setup-save" class="btn btn-primary btn-lg btn-block">
        <fmt:message key="global.continue"/></button>

</form>


<script language="JavaScript" type="text/javascript">
    // give focus to domain field
    document.f.domain.focus();
</script>


</body>
</html>
