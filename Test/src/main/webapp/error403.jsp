<%@ page contentType="text/html; charset=UTF-8" %>
<html>
<body>
<h1>403 - ACCÈS INTERDIT</h1>
<p><%= request.getAttribute("errorMessage") %></p>
<p>Vous n'avez pas les permissions nécessaires.</p>

<%
    String role = (String) session.getAttribute("role");
    if (role != null) {
        out.println("<p>Votre rôle actuel: <strong>" + role + "</strong></p>");
    }
%>

<hr>
<p><a href="<%= request.getContextPath() %>/dashboard">Dashboard</a></p>
<p><a href="<%= request.getContextPath() %>/logout">Se déconnecter</a></p>
<p><a href="<%= request.getContextPath() %>/login">Changer d'utilisateur</a></p>
</body>
</html>