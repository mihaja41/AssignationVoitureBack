<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%@ page import="model.Vehicule" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Liste des Véhicules</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .controls {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            justify-content: center;
        }
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            font-size: 14px;
            cursor: pointer;
            font-weight: bold;
            text-decoration: none;
            display: inline-block;
        }
        .btn-add {
            background-color: #4CAF50;
            color: white;
        }
        .btn-add:hover {
            background-color: #45a049;
        }
        .btn-edit {
            background-color: #2196F3;
            color: white;
            padding: 5px 10px;
            font-size: 12px;
        }
        .btn-edit:hover {
            background-color: #0b7dda;
        }
        .btn-delete {
            background-color: #f44336;
            color: white;
            padding: 5px 10px;
            font-size: 12px;
        }
        .btn-delete:hover {
            background-color: #da190b;
        }
        .alert {
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 4px;
        }
        .alert-success {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .alert-error {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th {
            background-color: #4CAF50;
            color: white;
            padding: 12px;
            text-align: left;
        }
        td {
            padding: 10px 12px;
            border-bottom: 1px solid #ddd;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .empty-message {
            text-align: center;
            padding: 30px;
            color: #888;
        }
        .actions {
            display: flex;
            gap: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Liste des Véhicules</h1>

        <% String success = (String) request.getAttribute("success"); %>
        <% String error = (String) request.getAttribute("error"); %>

        <% if (success != null) { %>
            <div class="alert alert-success"><%= success %></div>
        <% } %>

        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>

        <div class="controls">
            <a href="<%= request.getContextPath() %>/vehicules/form" class="btn btn-add">+ Ajouter un véhicule</a>
        </div>

        <%
            List<Vehicule> vehicules = (List<Vehicule>) request.getAttribute("vehicules");
            if (vehicules != null && !vehicules.isEmpty()) {
        %>
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Référence</th>
                        <th>Nombre de places</th>
                        <th>Type de carburant</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (Vehicule vehicule : vehicules) { %>
                        <tr>
                            <td><%= vehicule.getId() %></td>
                            <td><%= vehicule.getReference() %></td>
                            <td><%= vehicule.getNbPlace() %></td>
                            <td>
                                <% 
                                    String carburant = vehicule.getTypeCarburant().name();
                                    String carburantLabel = "";
                                    switch(carburant) {
                                        case "D": carburantLabel = "Diesel"; break;
                                        case "Es": carburantLabel = "Essence"; break;
                                        case "H": carburantLabel = "Hybride"; break;
                                        case "El": carburantLabel = "Électrique"; break;
                                    }
                                %>
                                <%= carburantLabel %> (<%= carburant %>)
                            </td>
                            <td>
                                <div class="actions">
                                    <a href="<%= request.getContextPath() %>/vehicules/edit?id=<%= vehicule.getId() %>" class="btn btn-edit">Modifier</a>
                                    <form method="POST" action="<%= request.getContextPath() %>/vehicules/delete" style="display:inline;">
                                        <input type="hidden" name="id" value="<%= vehicule.getId() %>">
                                        <button type="submit" class="btn btn-delete" onclick="return confirm('Êtes-vous sûr ?')">Supprimer</button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        <% } else { %>
            <div class="empty-message">
                <p>Aucun véhicule enregistré.</p>
                <a href="<%= request.getContextPath() %>/vehicules/form" class="btn btn-add">Ajouter le premier véhicule</a>
            </div>
        <% } %>
    </div>
</body>
</html>
