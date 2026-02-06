<%@ page contentType="text/html; charset=UTF-8" %>
<html>
<body>
<h1>PAGE PROTÉGÉE</h1>
<p>User: <%= request.getAttribute("user") %></p>
<p>Vous êtes connecté !</p>
<a href="dashboard">Dashboard</a> | <a href="logout">Logout</a>
</body>
</html>