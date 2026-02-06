<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="model.Hotel" %>
<!DOCTYPE html>
<html>
<head>
    <title>Nouvelle Réservation</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; }
        h1 { color: #333; }
        form { background: #f4f4f4; padding: 20px; border-radius: 8px; }
        label { display: block; margin-top: 15px; font-weight: bold; }
        input, select { width: 100%; padding: 8px; margin-top: 5px; border: 1px solid #ddd; border-radius: 4px; }
        button { margin-top: 20px; padding: 10px 20px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; }
        button:hover { background: #0056b3; }
        .error { color: red; background: #ffe6e6; padding: 10px; border-radius: 4px; margin-bottom: 15px; }
        .success { color: green; background: #e6ffe6; padding: 10px; border-radius: 4px; margin-bottom: 15px; }
        .links { margin-top: 20px; }
        .links a { color: #007bff; text-decoration: none; margin-right: 15px; }
        .hint { font-size: 0.9em; color: #666; margin-top: 3px; }
    </style>
</head>
<body>
    <h1>Nouvelle Réservation</h1>

    <% String error = (String) request.getAttribute("error");
       if (error != null) { %>
        <div class="error"><%= error %></div>
    <% } %>

    <% String success = (String) request.getAttribute("success");
       if (success != null) { %>
        <div class="success"><%= success %></div>
    <% } %>

    <form action="<%= request.getContextPath() %>/reservations/add" method="post">
        
        <label for="hotelId">Hôtel :</label>
        <select id="hotelId" name="hotelId" required>
            <option value="">-- Sélectionnez un hôtel --</option>
            <% List<Hotel> hotels = (List<Hotel>) request.getAttribute("hotels");
               if (hotels != null) {
                   for (Hotel hotel : hotels) { %>
                        <option value="<%= hotel.getId() %>"><%= hotel.getName() %></option>
            <%     }
               } %>
        </select>

        <label for="customerId">ID Client :</label>
        <input type="text" id="customerId" name="customerId" required placeholder="Ex: CUST1001 ou CLI-2024-001">
        <div class="hint">Vous pouvez entrer du texte et/ou des chiffres</div>

        <label for="passengerNbr">Nombre de passagers :</label>
        <input type="number" id="passengerNbr" name="passengerNbr" required min="1" placeholder="Ex: 3">

        <label for="arrivalDate">Date d'arrivée :</label>
        <input type="datetime-local" id="arrivalDate" name="arrivalDate" required>

        <button type="submit">Créer la réservation</button>
    </form>

    <div class="links">
        <%-- <a href="<%= request.getContextPath() %>/reservations/list">Voir toutes les réservations</a> --%>
        <a href="<%= request.getContextPath() %>/reservations/form">Nouvelle réservation</a>
    </div>
</body>
</html>