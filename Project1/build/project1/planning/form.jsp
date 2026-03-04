<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Planification - Saisie de date</title>
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
        input {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
            font-size: 14px;
        }
        input:focus {
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
        .alert-error {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .hint {
            font-size: 0.9em;
            color: #666;
            margin-top: 3px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Planification des Véhicules</h1>

        <% String error = (String) request.getAttribute("error"); %>
        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>

        <form method="POST" action="<%= request.getContextPath() %>/planning/generate">
            <div class="form-group">
                <label for="date">Date de planification :</label>
                <input type="date" id="date" name="date" required>
                <div class="hint">Sélectionnez la date pour laquelle vous souhaitez générer le planning d'attribution des véhicules.</div>
            </div>

            <div class="button-group">
                <button type="submit" class="btn-submit">Générer le planning</button>
                <button type="button" class="btn-back" onclick="window.location.href='<%= request.getContextPath() %>/vehicules/list'">Retour aux véhicules</button>
            </div>
        </form>
    </div>
</body>
</html>
