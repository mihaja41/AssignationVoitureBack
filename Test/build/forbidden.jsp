<%@ page contentType="text/html; charset=UTF-8" %>
<html>
<body>
<h1>403 - ACCÈS INTERDIT</h1>
<p>Vous n'avez pas les permissions nécessaires.</p>
<hr>
<p><a href="<%= request.getContextPath() %>/dashboard">Dashboard</a></p>
<p><a href="<%= request.getContextPath() %>/logout">Se déconnecter</a></p>
</body>
</html>