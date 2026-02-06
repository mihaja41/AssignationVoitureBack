<%@ page contentType="text/html; charset=UTF-8" %>
<html>
<body>
<h1><%= request.getAttribute("pageType") %></h1>
<p><%= request.getAttribute("message") %></p>
<p>Votre rôle: <strong><%= request.getAttribute("role") %></strong></p>
<a href="dashboard">Dashboard</a> | <a href="logout">Logout</a>
</body>
</html>