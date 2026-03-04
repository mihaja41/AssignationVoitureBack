<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="model.Vehicule" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Modifier un Véhicule</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 600px;
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
        .form-group {
            margin-bottom: 15px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            color: #555;
            font-weight: bold;
        }
        input, select {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
            font-size: 14px;
        }
        input:focus, select:focus {
            outline: none;
            border-color: #2196F3;
            box-shadow: 0 0 5px rgba(33, 150, 243, 0.3);
        }
        .button-group {
            display: flex;
            gap: 10px;
            margin-top: 20px;
        }
        button {
            flex: 1;
            padding: 12px;
            border: none;
            border-radius: 4px;
            font-size: 16px;
            cursor: pointer;
            font-weight: bold;
        }
        .btn-submit {
            background-color: #2196F3;
            color: white;
        }
        .btn-submit:hover {
            background-color: #0b7dda;
        }
        .btn-back {
            background-color: #808080;
            color: white;
        }
        .btn-back:hover {
            background-color: #606060;
        }
        .alert {
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 4px;
        }
        .alert-error {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .form-info {
            background-color: #e3f2fd;
            padding: 10px;
            border-radius: 4px;
            margin-bottom: 15px;
            font-size: 14px;
            color: #1565c0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Modifier un Véhicule</h1>

        <% String error = (String) request.getAttribute("error"); %>
        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>

        <%
            Vehicule vehicule = (Vehicule) request.getAttribute("vehicule");
            if (vehicule != null) {
        %>
        <div class="form-info">
            Modification du véhicule ID: <%= vehicule.getId() %>
        </div>

        <form method="POST" action="<%= request.getContextPath() %>/vehicules/update">
            <input type="hidden" name="id" value="<%= vehicule.getId() %>">

            <div class="form-group">
                <label for="reference">Référence du véhicule :</label>
                <input type="text" id="reference" name="reference" required value="<%= vehicule.getReference() %>">
            </div>

            <div class="form-group">
                <label for="nbPlace">Nombre de places :</label>
                <input type="number" id="nbPlace" name="nbPlace" required min="1" value="<%= vehicule.getNbPlace() %>">
            </div>

            <div class="form-group">
                <label for="typeCarburant">Type de carburant :</label>
                <select id="typeCarburant" name="typeCarburant" required>
                    <option value="">-- Sélectionner --</option>
                    <option value="D" <%= vehicule.getTypeCarburant().name().equals("D") ? "selected" : "" %>>Diesel (D)</option>
                    <option value="Es" <%= vehicule.getTypeCarburant().name().equals("Es") ? "selected" : "" %>>Essence (Es)</option>
                    <option value="H" <%= vehicule.getTypeCarburant().name().equals("H") ? "selected" : "" %>>Hybride (H)</option>
                    <option value="El" <%= vehicule.getTypeCarburant().name().equals("El") ? "selected" : "" %>>Électrique (El)</option>
                </select>
            </div>

            <div class="button-group">
                <button type="submit" class="btn-submit">Mettre à jour</button>
                <button type="button" class="btn-back" onclick="window.location.href='<%= request.getContextPath() %>/vehicules/list'">Annuler</button>
            </div>
        </form>

        <% } else { %>
            <div class="alert alert-error">
                Véhicule non trouvé. <a href="<%= request.getContextPath() %>/vehicules/list">Retour à la liste</a>
            </div>
        <% } %>
    </div>
</body>
</html>
