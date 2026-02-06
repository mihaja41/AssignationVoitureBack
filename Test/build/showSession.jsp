<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<!DOCTYPE html>
<html>
<head>
<title>Session Data</title>

</head>
<body>
<div class="container">
    <h1>Donnees de Session</h1>
    
    <%
        Map<String, Object> sessionData = (Map<String, Object>) request.getAttribute("sessionData");
        if (sessionData == null || sessionData.isEmpty()) {
    %>
        <div class="empty">
            Aucune donnee en session
        </div>
    <%
        } else {
    %>
        <p><strong>Nombre d'attributs :</strong> <%= sessionData.size() %></p>
        
        <%
            for (Map.Entry<String, Object> entry : sessionData.entrySet()) {
        %>
            <div class="session-item">
                <span class="key"><%= entry.getKey() %></span>
                <span class="value">= <%= entry.getValue() %></span>
                <a href="<%= request.getContextPath() %>/session/remove?key=<%= entry.getKey() %>" 
                   onclick="return confirm('Supprimer <%= entry.getKey() %> ?')">
                    Supprimer
                </a>
            </div>
        <%
            }
        %>
    <%
        }
    %>
    
    <div class="actions">
        <h3>Actions</h3>
        
        <!-- Ajouter une valeur -->
        <form class="form-inline" action="<%= request.getContextPath() %>/session/add" method="get">
            <input type="text" name="key" placeholder="Clé" required>
            <input type="text" name="value" placeholder="Valeur" required>
            <button type="submit" class="btn">Ajouter</button>
        </form>
        
        <br><br>
        
        <a href="<%= request.getContextPath() %>/session/add-complex" class="btn">Ajouter donnees complexes</a>
        <a href="<%= request.getContextPath() %>/session/increment" class="btn">Incrementer compteur</a>
        <a href="<%= request.getContextPath() %>/session/replace-all" class="btn btn-warning">Remplacer tout</a>
        <a href="<%= request.getContextPath() %>/session/clear" class="btn btn-danger" 
           onclick="return confirm('Vider toute la session ?')">Vider session</a>
        
        <br><br>
        
        <a href="<%= request.getContextPath() %>/dashboard" class="btn">Dashboard</a>
        <a href="<%= request.getContextPath() %>/session/show" class="btn">Rafraîchir</a>
    </div>
</div>
</body>
</html>
