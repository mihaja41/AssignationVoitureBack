<%@ page contentType="text/html; charset=UTF-8" %>
<html>
<body>
<h1>TESTS DE PERMISSIONS</h1>

<h2>STATUT:</h2>
<%
    String userId = (String) session.getAttribute("userId");
    String role = (String) session.getAttribute("role");
    Boolean loggedIn = (Boolean) session.getAttribute("loggedIn");
    
    if (loggedIn != null && loggedIn) {
        out.println("<p>User: <b>" + userId + "</b></p>");
        out.println("<p>Role: <b>" + role + "</b></p>");
        out.println("<p><a href='logout'>LOGOUT</a></p>");
    } else {
        out.println("<p>NON CONNECTÉ</p>");
        out.println("<p><a href='login'>LOGIN</a></p>");
    }
%>

<hr>
<h2>COMPTES DE TEST:</h2>
<p>admin / 1234</p>
<p>manager / 1234</p>
<p>user / 1234</p>

<hr>
<h2>TESTS:</h2>

<h3>1. PUBLIC (sans annotation)</h3>
<p><a href="public">Page Publique</a></p>

<h3>2. AUTHENTIFICATION (@Authentified)</h3>
<p><a href="protected">Page Protégée</a></p>

<h3>3. ROLES (@Role)</h3>
<p><a href="admin-only">Admin Only</a> - @Role({"admin"})</p>
<p><a href="manager-only">Manager Only</a> - @Role({"manager"})</p>
<p><a href="user-only">User Only</a> - @Role({"user"})</p>
<p><a href="admin-or-manager">Admin OR Manager</a> - @Role({"admin", "manager"})</p>

<h3>4. API JSON</h3>
<p><a href="api/user-info" target="_blank">User Info JSON</a> - @Json @Authentified</p>
<p><a href="api/admin/stats" target="_blank">Admin Stats JSON</a> - @Json @Role({"admin"})</p>

<hr>

</body>
</html>