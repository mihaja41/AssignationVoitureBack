<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%@ page import="model.Attribution" %>
<%@ page import="model.Reservation" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.math.BigDecimal" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Planning d'attribution - Résultat</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1, h2 {
            color: #333;
            text-align: center;
        }
        h2 {
            font-size: 1.2em;
            margin-top: 30px;
        }
        .date-info {
            text-align: center;
            font-size: 1.1em;
            color: #555;
            margin-bottom: 20px;
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
        .btn-back {
            background-color: #2196F3;
            color: white;
        }
        .btn-back:hover {
            background-color: #0b7dda;
        }
        .btn-refresh {
            background-color: #4CAF50;
            color: white;
        }
        .btn-refresh:hover {
            background-color: #45a049;
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
        .alert-info {
            background-color: #d1ecf1;
            color: #0c5460;
            border: 1px solid #bee5eb;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
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
        .section-unassigned {
            margin-top: 40px;
            border-top: 2px solid #f44336;
            padding-top: 20px;
        }
        .section-unassigned h2 {
            color: #f44336;
        }
        .section-unassigned th {
            background-color: #f44336;
        }
        .badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: bold;
            color: white;
        }
        .badge-assigne {
            background-color: #4CAF50;
        }
        .badge-non-assigne {
            background-color: #f44336;
        }
        .stats {
            display: flex;
            gap: 20px;
            justify-content: center;
            margin-bottom: 20px;
        }
        .stat-box {
            background: #f9f9f9;
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 15px 25px;
            text-align: center;
        }
        .stat-box .number {
            font-size: 24px;
            font-weight: bold;
            display: block;
        }
        .stat-box .label {
            font-size: 13px;
            color: #666;
        }
        .stat-green .number { color: #4CAF50; }
        .stat-red .number { color: #f44336; }
        .stat-blue .number { color: #2196F3; }
        .info-note {
            text-align: center;
            font-size: 12px;
            color: #999;
            margin-top: 5px;
            font-style: italic;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Planning d'attribution des Véhicules</h1>

        <%
            String selectedDate = (String) request.getAttribute("selectedDate");
            String error = (String) request.getAttribute("error");
            List<Attribution> attributions = (List<Attribution>) request.getAttribute("attributions");
            List<Reservation> reservationsNonAssignees = (List<Reservation>) request.getAttribute("reservationsNonAssignees");
            DateTimeFormatter dtf = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

            int nbAssigned = (attributions != null) ? attributions.size() : 0;
            int nbUnassigned = (reservationsNonAssignees != null) ? reservationsNonAssignees.size() : 0;
        %>

        <% if (selectedDate != null) { %>
            <div class="date-info">Date sélectionnée : <strong><%= selectedDate %></strong></div>
        <% } %>

        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>

        <div class="controls">
            <a href="<%= request.getContextPath() %>/planning/form" class="btn btn-back">← Changer de date</a>
            <% if (selectedDate != null) { %>
                <a href="<%= request.getContextPath() %>/planning/result?date=<%= selectedDate %>" class="btn btn-refresh">↻ Rafraîchir</a>
            <% } %>
        </div>

        <!-- Statistiques -->
        <div class="stats">
            <div class="stat-box stat-blue">
                <span class="number"><%= nbAssigned + nbUnassigned %></span>
                <span class="label">Total réservations</span>
            </div>
            <div class="stat-box stat-green">
                <span class="number"><%= nbAssigned %></span>
                <span class="label">Attributions</span>
            </div>
            <div class="stat-box stat-red">
                <span class="number"><%= nbUnassigned %></span>
                <span class="label">Non assignées</span>
            </div>
        </div>

        <!-- ========================================== -->
        <!-- TABLEAU PLANNING : ATTRIBUTIONS            -->
        <!-- ========================================== -->

        <h2>Attributions de véhicules</h2>

        <% if (attributions != null && !attributions.isEmpty()) { %>
            <table>
                <thead>
                    <tr>
                        <th>Véhicule</th>
                        <th>Réservation</th>
                        <th>Lieu départ</th>
                        <th>Lieu destination</th>
                        <th>Distance (A/R)</th>
                        <th>Heure départ</th>
                        <th>Heure retour</th>
                        <th>Statut</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (Attribution attr : attributions) { %>
                        <tr>
                            <td>
                                <strong><%= attr.getVehicule() != null ? attr.getVehicule().getReference() : "-" %></strong>
                                <br>
                                <small>
                                    <%= attr.getVehicule() != null ? attr.getVehicule().getNbPlace() + " places" : "" %>
                                    <%
                                        if (attr.getVehicule() != null && attr.getVehicule().getTypeCarburant() != null) {
                                            String typeCarb = attr.getVehicule().getTypeCarburant().name();
                                            String carbLabel = "";
                                            switch(typeCarb) {
                                                case "D": carbLabel = "Diesel"; break;
                                                case "Es": carbLabel = "Essence"; break;
                                                case "H": carbLabel = "Hybride"; break;
                                                case "El": carbLabel = "Électrique"; break;
                                                default: carbLabel = typeCarb;
                                            }
                                    %>
                                        - <%= carbLabel %>
                                    <% } %>
                                </small>
                            </td>
                            <td>
                                #<%= attr.getReservation().getId() %> - <%= attr.getReservation().getCustomerId() %>
                                <br>
                                <small><%= attr.getReservation().getPassengerNbr() %> passager(s)</small>
                            </td>
                            <td><%= attr.getReservation().getLieuDepart() != null ? attr.getReservation().getLieuDepart().getLibelle() : "-" %></td>
                            <td><%= attr.getReservation().getLieuDestination() != null ? attr.getReservation().getLieuDestination().getLibelle() : "-" %></td>
                            <td>
                                <%= attr.getDistanceKm() != null ? attr.getDistanceKm() + " km" : "-" %>
                                <br>
                                <small>(<%= attr.getDistanceAllerRetourKm() != null ? attr.getDistanceAllerRetourKm() + " km A/R" : "" %>)</small>
                            </td>
                            <td><%= attr.getDateHeureDepart() != null ? attr.getDateHeureDepart().format(dtf) : "-" %></td>
                            <td><%= attr.getDateHeureRetour() != null ? attr.getDateHeureRetour().format(dtf) : "-" %></td>
                            <td><span class="badge badge-assigne">ASSIGNÉ</span></td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        <% } else { %>
            <div class="empty-message">
                <p>Aucune attribution pour cette date.</p>
            </div>
        <% } %>

        <!-- ========================================== -->
        <!-- RÉSERVATIONS NON ASSIGNÉES                 -->
        <!-- ========================================== -->

        <div class="section-unassigned">
            <h2>Réservations non assignées</h2>

            <% if (reservationsNonAssignees != null && !reservationsNonAssignees.isEmpty()) { %>
                <div class="alert alert-info">
                    Ces réservations n'ont pas pu être assignées (aucun véhicule disponible, pas assez de places, conflit horaire ou distance manquante).
                </div>
                <table>
                    <thead>
                        <tr>
                            <th>Réservation</th>
                            <th>Client</th>
                            <th>Nb passagers</th>
                            <th>Lieu départ</th>
                            <th>Lieu destination</th>
                            <th>Date arrivée</th>
                            <th>Statut</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (Reservation resa : reservationsNonAssignees) { %>
                            <tr>
                                <td>#<%= resa.getId() %></td>
                                <td><%= resa.getCustomerId() %></td>
                                <td><%= resa.getPassengerNbr() %></td>
                                <td><%= resa.getLieuDepart() != null ? resa.getLieuDepart().getLibelle() : "-" %></td>
                                <td><%= resa.getLieuDestination() != null ? resa.getLieuDestination().getLibelle() : "-" %></td>
                                <td><%= resa.getArrivalDate() != null ? resa.getArrivalDate().format(dtf) : "-" %></td>
                                <td><span class="badge badge-non-assigne">NON ASSIGNÉ</span></td>
                            </tr>
                        <% } %>
                    </tbody>
                </table>
            <% } else { %>
                <div class="empty-message">
                    <p>Toutes les réservations ont été assignées avec succès !</p>
                </div>
            <% } %>
        </div>

    </div>
</body>
</html>
