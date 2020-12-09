<%--
  -
  - Copyright (C) 2004-2008 Jive Software. All rights reserved.
  -
  - Licensed under the Apache License, Version 2.0 (the "License");
  - you may not use this file except in compliance with the License.
  - You may obtain a copy of the License at
  -
  -     http://www.apache.org/licenses/LICENSE-2.0
  -
  - Unless required by applicable law or agreed to in writing, software
  - distributed under the License is distributed on an "AS IS" BASIS,
  - WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  - See the License for the specific language governing permissions and
  - limitations under the License.
--%>

<%@ page import="org.jivesoftware.util.LocaleUtils" %>
<%@ page import="java.beans.PropertyDescriptor" %>
<%@ page import="java.io.File" %>
<%@ page import="org.jivesoftware.database.DbConnectionManager" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.sql.Statement" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="org.jivesoftware.admin.AdminConsole" %>

<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://www.opensymphony.com/sitemesh/decorator" prefix="decorator" %>
<%@ taglib uri="http://www.opensymphony.com/sitemesh/page" prefix="page" %>

<decorator:usePage id="decoratedPage"/>
<%
    // Check to see if the sidebar should be shown; default to true unless the page specifies
    // that it shouldn't be.
    String sidebar = decoratedPage.getProperty("meta.showSidebar");
    if (sidebar == null) {
        sidebar = "true";
    }
    boolean showSidebar = Boolean.parseBoolean(sidebar);
    int currentStep = decoratedPage.getIntProperty("meta.currentStep");
%>

<%
    String preloginSidebar = (String) session.getAttribute("prelogin.setup.sidebar");
    if (preloginSidebar == null) {
        preloginSidebar = "false";
    }
    boolean showPreloginSidebar = Boolean.parseBoolean(preloginSidebar);
%>

<%!
    final PropertyDescriptor getPropertyDescriptor(PropertyDescriptor[] pd, String name) {
        for (PropertyDescriptor aPd : pd) {
            if (name.equals(aPd.getName())) {
                return aPd;
            }
        }
        return null;
    }

    boolean testConnection(Map<String, String> errors) {
        boolean success = true;
        Connection con = null;
        try {
            con = DbConnectionManager.getConnection();
            if (con == null) {
                success = false;
                errors.put("general", "A connection to the database could not be "
                    + "made. View the error message by opening the "
                    + "\"" + File.separator + "logs" + File.separator + "error.log\" log "
                    + "file, then go back to fix the problem.");
            } else {
                // See if the Jive db schema is installed.
                try {
                    Statement stmt = con.createStatement();
                    // Pick an arbitrary table to see if it's there.
                    stmt.executeQuery("SELECT * FROM ofID");
                    stmt.close();
                } catch (SQLException sqle) {
                    success = false;
                    sqle.printStackTrace();
                    errors.put("general", "The Openfire database schema does not "
                        + "appear to be installed. Follow the installation guide to "
                        + "fix this error.");
                }
            }
        } catch (Exception ignored) {
        } finally {
            try {
                con.close();
            } catch (Exception ignored) {
            }
        }
        return success;
    }
%>

<html>
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><fmt:message key="title"/> <fmt:message key="setup.title"/>: <decorator:title/></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0-beta1/dist/css/bootstrap.min.css" rel="stylesheet"
          integrity="sha384-giJF6kkoqNQ00vy+HMDP7azOuL0xtbfIcaT9wjKHr8RbDVddVHyTfAAsrekwKmP1" crossorigin="anonymous">
    <link rel="stylesheet" href="../style/sticky_footer.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.1/css/all.min.css"
          type="text/css">
    <link rel="apple-touch-icon" sizes="180x180" href="../images/apple-touch-icon.png">
    <link rel="icon" type="image/png" sizes="32x32" href="../images/favicon-32x32.png">
    <link rel="icon" type="image/png" sizes="16x16" href="../images/favicon-16x16.png">
    <link rel="manifest" href="../files/site.webmanifest">
    <meta name="msapplication-TileColor" content="#da532c">
    <meta name="theme-color" content="#ffffff">

    <script type="text/javascript" src="../js/prototype.js"></script>
    <script type="text/javascript" src="../js/scriptaculous.js"></script>
    <!--<script language="JavaScript" type="text/javascript" src="../js/lightbox.js"></script> -->
    <script type="text/javascript" src="../js/tooltips/domLib.js"></script>
    <script type="text/javascript" src="../js/tooltips/domTT.js"></script>
    <script type="text/javascript" src="../js/setup.js"></script>
    <decorator:head/>
</head>

<body onload="<decorator:getProperty property="body.onload" />">

<!-- BEGIN jive-main -->
<header>
    <div class="header">
        <div class="container">
            <nav class="navbar navbar-light">
                <a class="navbar-brand" href="#">
                    <img src="/images/siper.svg" width="30" height="30" class="d-inline-block align-top" alt=""
                         loading="lazy">
                    Siper
                </a>
            </nav>
        </div>
    </div>
</header>
<main>
    <div class="container">


            <%  if (showSidebar) {
            String[] names;
            String[] links;
            if (showPreloginSidebar) {
                names = new String[] {
                    LocaleUtils.getLocalizedString((String) session.getAttribute("prelogin.setup.sidebar.title"))
                };
                links = new String[] {
                    (String) session.getAttribute("prelogin.setup.sidebar.link")
                };
            } else {
                names = new String[] {
                    LocaleUtils.getLocalizedString("setup.sidebar.language"),
                    LocaleUtils.getLocalizedString("setup.sidebar.settings"),
                    LocaleUtils.getLocalizedString("setup.sidebar.datasource"),
                    LocaleUtils.getLocalizedString("setup.sidebar.profile"),
                    LocaleUtils.getLocalizedString("setup.sidebar.admin")
                };
                links = new String[] {
                    "index.jsp",
                    "setup-host-settings.jsp",
                    "setup-datasource-settings.jsp",
                    "setup-profile-settings.jsp",
                    "setup-admin-settings.jsp"
                };
            }
        %>


            <%  if (!showPreloginSidebar) { %>
        <br/>
        <div class="row">
            <div class="col-12">
                <div class="progress">
                    <div class="progress-bar" role="progressbar" style="width: <%= currentStep*20 %>%"
                         aria-valuenow="<%= currentStep*20 %>" aria-valuemin="0"
                         aria-valuemax="100"></div>
                </div>
            </div>
        </div>
        <br/>
            <%  } %>
        <div class="row">
            <div class="col-3">
                <div class="nav flex-column nav-pills" id="v-pills-tab" role="tablist" aria-orientation="vertical">
                    <div class="shadow-lg p-3 mb-5 bg-white rounded">
                        <% for (int i = 0; i < names.length; i++) { %>
                        <% if (currentStep != i) { %>
                            <a class="nav-link" id="v-pills-home-tab" data-toggle="pill" href="<%= links[i] %>" role="tab"
                               aria-controls="v-pills-home" aria-selected="true"><%= names[i] %>
                            </a>
                        <% } else { %>
                            <a class="nav-link active" id="v-pills-profile-tab" data-toggle="pill"
                               href="<%= links[i] %>" role="tab" aria-controls="v-pills-profile"
                               aria-selected="false"><%= names[i] %>
                            </a>
                        <% } %>
                        <% } %>
                    </div>
                </div>
            </div>

            <% } %>
            <div class="col-9">
                <div class="tab-content" id="v-pills-tabContent">
                <div class="shadow-lg p-3 mb-5 bg-white rounded">
                    <decorator:body/>
                </div>
                </div>
            </div>
        </div>

    </div>
</main>

<footer class="footer">
    <div class="container text-center">
        <span class="text-muted">Açık Deniz Bilişim A.Ş.</span>
    </div>
</footer>
</body>
</html>
