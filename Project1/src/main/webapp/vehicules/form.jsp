<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Ajouter un Véhicule</title>
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
            border-color: #4CAF50;
            box-shadow: 0 0 5px rgba(76, 175, 80, 0.3);
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
            background-color: #4CAF50;
            color: white;
        }
        .btn-submit:hover {
            background-color: #45a049;
        }
        .btn-back {
            background-color: #2196F3;
            color: white;
        }
        .btn-back:hover {
            background-color: #0b7dda;
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
    </style>
</head>
<body>
    <div class="container">
        <h1>Ajouter un nouveau Véhicule</h1>

        <% String success = (String) request.getAttribute("success"); %>
        <% String error = (String) request.getAttribute("error"); %>

        <% if (success != null) { %>
            <div class="alert alert-success"><%= success %></div>
        <% } %>

        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>

        <form method="POST" action="<%= request.getContextPath() %>/vehicules/add">
            <div class="form-group">
                <label for="reference">Référence du véhicule :</label>
                <input type="text" id="reference" name="reference" required placeholder="Ex: VH-001">
            </div>

            <div class="form-group">
                <label for="nbPlace">Nombre de places :</label>
                <input type="number" id="nbPlace" name="nbPlace" required min="1" placeholder="Ex: 5">
            </div>

            <div class="form-group">
                <label for="typeCarburant">Type de carburant :</label>
                <select id="typeCarburant" name="typeCarburant" required>
                    <option value="">-- Sélectionner --</option>
                    <option value="D">Diesel (D)</option>
                    <option value="Es">Essence (Es)</option>
                    <option value="H">Hybride (H)</option>
                    <option value="El">Électrique (El)</option>
                </select>
            </div>

            <div class="button-group">
                <button type="submit" class="btn-submit">Créer le véhicule</button>
                <button type="button" class="btn-back" onclick="window.location.href='<%= request.getContextPath() %>/vehicules/list'">Retour à la liste</button>
            </div>
        </form>
    </div>
</body>
</html>
