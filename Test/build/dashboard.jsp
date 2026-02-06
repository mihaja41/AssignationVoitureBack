<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <title>Tableau de bord</title>
    <style>
        body { font-family: Arial; margin: 40px; }
        .info { background: #f0f8ff; padding: 15px; border-radius: 8px; margin: 20px 0; }
    </style>
</head>
<body>
    <h1>Bienvenue <%= request.getAttribute("user") %> !</h1>

    <div class="info">
        <p><strong>Rôle :</strong> <%= request.getAttribute("role") %></p>
        <p><strong>Dernière connexion :</strong> <%= request.getAttribute("lastLogin") %></p>
    </div>

    <p><a href="/test_app/dashboard">Rafraîchir</a> | <a href="/test_app/logout">Déconnexion</a></p>
</body>
</html>