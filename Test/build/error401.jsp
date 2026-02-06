<%@ page contentType="text/html; charset=UTF-8" %>
<html>
<body>
<h1>401 - NON AUTHENTIFIÉ</h1>
<p><%= request.getAttribute("errorMessage") %></p>
<p>Vous devez être connecté pour accéder à cette page.</p>
<hr>
<p><a href="<%= request.getContextPath() %>/login">Se connecter</a></p>
<p><a href="<%= request.getContextPath() %>/public">Page publique</a></p>
</body>
</html>