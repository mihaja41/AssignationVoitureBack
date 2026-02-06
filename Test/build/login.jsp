<%@ page contentType="text/html; charset=UTF-8" %>
<html>
<body>
<h1>LOGIN</h1>

<% if (request.getAttribute("error") != null) { %>
<p style="color:red;"><b><%= request.getAttribute("error") %></b></p>
<% } %>

<% if (request.getAttribute("message") != null) { %>
<p style="color:green;"><b><%= request.getAttribute("message") %></b></p>
<% } %>

<form method="POST" action="login">
<p>Username: <input type="text" name="username"></p>
<p>Password: <input type="password" name="password"></p>
<p><button type="submit">LOGIN</button></p>
</form>

<hr>
<h3>Comptes:</h3>
<p>admin / 1234</p>
<p>manager / 1234</p>
<p>user / 1234</p>

<p><a href="public">Page publique</a> | <a href="test-permissions">Tests</a></p>

</body>
</html>