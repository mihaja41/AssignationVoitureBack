<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%@ page import="model.Attribution" %>
<%@ page import="model.TrajetCar" %>
<%@ page import="model.Reservation" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.util.stream.Collectors" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Map" %>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Planning d'attribution — Véhicules</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --ink:        #1a1a1a;
            --ink-light:  #6b6b6b;
            --ink-faint:  #a8a8a8;
            --paper:      #fafaf8;
            --surface:    #ffffff;
            --border:     #e8e6e1;
            --border-soft:#f0ede8;
            --accent:     #2c4a3e;
            --accent-dim: #e8eeec;
            --warn:       #8b3a3a;
            --warn-dim:   #f5eaea;
            --gold:       #b5872a;
            --gold-dim:   #fdf6e8;
        }

        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'DM Sans', sans-serif;
            font-weight: 400;
            background-color: var(--paper);
            color: var(--ink);
            min-height: 100vh;
            line-height: 1.6;
        }

        /* ── HEADER ── */
        .page-header {
            background: var(--surface);
            border-bottom: 1px solid var(--border);
            padding: 32px 48px 28px;
            position: sticky;
            top: 0;
            z-index: 10;
            backdrop-filter: blur(8px);
        }
        .header-inner {
            max-width: 1280px;
            margin: 0 auto;
            display: flex;
            align-items: flex-end;
            justify-content: space-between;
            gap: 24px;
        }
        .header-title-group {}
        .header-eyebrow {
            font-size: 11px;
            font-weight: 600;
            letter-spacing: .14em;
            text-transform: uppercase;
            color: var(--accent);
            margin-bottom: 6px;
        }
        .header-title {
            font-family: 'DM Serif Display', serif;
            font-size: 28px;
            font-weight: 400;
            color: var(--ink);
            line-height: 1.2;
        }
        .header-date {
            font-size: 13px;
            color: var(--ink-light);
            margin-top: 4px;
        }
        .header-date strong { color: var(--ink); font-weight: 500; }
        .header-actions { display: flex; gap: 10px; flex-shrink: 0; }
        .btn {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            padding: 9px 18px;
            border: 1px solid var(--border);
            border-radius: 6px;
            font-family: 'DM Sans', sans-serif;
            font-size: 13px;
            font-weight: 500;
            cursor: pointer;
            text-decoration: none;
            transition: all .18s ease;
            white-space: nowrap;
        }
        .btn-outline {
            background: transparent;
            color: var(--ink-light);
        }
        .btn-outline:hover {
            background: var(--surface);
            color: var(--ink);
            border-color: var(--ink-faint);
        }
        .btn-primary {
            background: var(--accent);
            color: #fff;
            border-color: var(--accent);
        }
        .btn-primary:hover {
            background: #223d32;
            border-color: #223d32;
        }
        .btn-icon { font-size: 14px; opacity: .75; }

        /* ── MAIN LAYOUT ── */
        .main {
            max-width: 1280px;
            margin: 0 auto;
            padding: 40px 48px 80px;
        }

        /* ── ALERT ── */
        .alert {
            display: flex;
            align-items: flex-start;
            gap: 12px;
            padding: 14px 18px;
            border-radius: 8px;
            font-size: 13.5px;
            margin-bottom: 32px;
            border: 1px solid;
        }
        .alert-error { background: var(--warn-dim); color: var(--warn); border-color: #e8c0c0; }
        .alert-info  { background: var(--accent-dim); color: var(--accent); border-color: #c6d8d2; }
        .alert-icon  { font-size: 16px; flex-shrink: 0; margin-top: 1px; }

        /* ── KPI STRIP ── */
        .kpi-strip {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 16px;
            margin-bottom: 48px;
        }
        .kpi-card {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 10px;
            padding: 22px 24px;
            position: relative;
            overflow: hidden;
            transition: box-shadow .2s;
        }
        .kpi-card:hover { box-shadow: 0 4px 20px rgba(0,0,0,.06); }
        .kpi-card::before {
            content: '';
            position: absolute;
            top: 0; left: 0; right: 0;
            height: 3px;
            background: var(--border);
        }
        .kpi-card.green::before  { background: var(--accent); }
        .kpi-card.red::before    { background: var(--warn); }
        .kpi-card.gold::before   { background: var(--gold); }
        .kpi-card.neutral::before { background: var(--ink); }
        .kpi-value {
            font-family: 'DM Serif Display', serif;
            font-size: 36px;
            line-height: 1;
            margin-bottom: 6px;
            color: var(--ink);
        }
        .kpi-card.green .kpi-value  { color: var(--accent); }
        .kpi-card.red .kpi-value    { color: var(--warn); }
        .kpi-card.gold .kpi-value   { color: var(--gold); }
        .kpi-label {
            font-size: 12px;
            font-weight: 600;
            letter-spacing: .08em;
            text-transform: uppercase;
            color: var(--ink-faint);
        }

        /* ── SECTION HEADING ── */
        .section-header {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 20px;
        }
        .section-title {
            font-family: 'DM Serif Display', serif;
            font-size: 20px;
            font-weight: 400;
            color: var(--ink);
        }
        .section-pill {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
            letter-spacing: .06em;
            text-transform: uppercase;
        }
        .pill-green { background: var(--accent-dim); color: var(--accent); }
        .pill-red   { background: var(--warn-dim);   color: var(--warn); }
        .section-divider {
            height: 1px;
            background: var(--border);
            margin-bottom: 20px;
        }

        /* ── TABLE ── */
        .table-wrap {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 10px;
            overflow: hidden;
            margin-bottom: 48px;
        }
        table { width: 100%; border-collapse: collapse; }
        thead tr {
            background: var(--ink);
            color: #fff;
        }
        thead th {
            padding: 13px 16px;
            font-size: 11px;
            font-weight: 600;
            letter-spacing: .1em;
            text-transform: uppercase;
            text-align: left;
            white-space: nowrap;
        }
        tbody tr.row-main {
            border-bottom: 1px solid var(--border-soft);
            transition: background .15s;
        }
        tbody tr.row-main:hover { background: #f7f6f3; }
        tbody tr.row-detail {
            background: var(--border-soft);
            border-bottom: 1px solid var(--border);
        }
        tbody tr.row-detail td {
            padding: 10px 16px 14px 40px;
            font-size: 12.5px;
            color: var(--ink-light);
            border-top: none;
        }
        td {
            padding: 14px 16px;
            font-size: 13.5px;
            vertical-align: top;
        }
        .vehicle-ref {
            font-weight: 600;
            color: var(--ink);
            font-size: 14px;
        }
        .vehicle-meta {
            font-size: 11.5px;
            color: var(--ink-faint);
            margin-top: 2px;
        }
        .resa-line { color: var(--ink); font-size: 13px; }
        .resa-line + .resa-line { margin-top: 4px; }
        .grouped-note {
            display: inline-block;
            margin-top: 6px;
            font-size: 11px;
            font-weight: 600;
            color: var(--gold);
            background: var(--gold-dim);
            padding: 2px 8px;
            border-radius: 4px;
        }
        .capacity-bar-wrap { display: flex; align-items: center; gap: 8px; margin-top: 4px; }
        .capacity-bar {
            flex: 1; height: 4px; background: var(--border);
            border-radius: 2px; overflow: hidden;
        }
        .capacity-bar-fill { height: 100%; border-radius: 2px; }
        .cap-ok   { background: var(--accent); }
        .cap-full { background: var(--warn); }
        .capacity-text { font-size: 12px; color: var(--ink-light); white-space: nowrap; }
        .time-main { font-weight: 500; font-size: 13.5px; }
        .time-date { font-size: 11.5px; color: var(--ink-faint); }

        /* badges */
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 10.5px;
            font-weight: 700;
            letter-spacing: .08em;
            text-transform: uppercase;
        }
        .badge-assigned   { background: var(--accent-dim); color: var(--accent); }
        .badge-unassigned { background: var(--warn-dim);   color: var(--warn); }

        /* traject detail rows */
        .traject-list { list-style: none; display: flex; flex-direction: column; gap: 4px; }
        .traject-item {
            display: flex; align-items: center; gap: 8px;
            font-size: 12px; color: var(--ink-light);
        }
        .traject-num {
            width: 18px; height: 18px; border-radius: 50%;
            background: var(--border); color: var(--ink-faint);
            display: flex; align-items: center; justify-content: center;
            font-size: 10px; font-weight: 700; flex-shrink: 0;
        }
        .traject-arrow { color: var(--ink-faint); font-size: 10px; }
        .traject-km {
            margin-left: auto;
            font-size: 11.5px;
            background: var(--border-soft);
            padding: 2px 7px;
            border-radius: 3px;
            white-space: nowrap;
            color: var(--ink-light);
        }
        .traject-totals {
            margin-top: 8px;
            display: flex; gap: 12px;
        }
        .traject-total-tag {
            font-size: 11.5px;
            font-weight: 600;
            padding: 3px 10px;
            border-radius: 4px;
            background: var(--accent-dim);
            color: var(--accent);
        }

        /* empty states */
        .empty-state {
            padding: 48px 24px;
            text-align: center;
            color: var(--ink-faint);
        }
        .empty-state-icon { font-size: 32px; margin-bottom: 12px; }
        .empty-state-text { font-size: 14px; }

        /* unassigned section */
        .section-unassigned { margin-top: 8px; }
        .section-unassigned thead tr { background: var(--warn); }

        /* responsive */
        @media (max-width: 900px) {
            .page-header { padding: 20px 24px 16px; }
            .main { padding: 24px 20px 60px; }
            .kpi-strip { grid-template-columns: repeat(2, 1fr); }
            .header-inner { flex-direction: column; align-items: flex-start; }
        }
    </style>
</head>
<body>

<%
    String selectedDate = (String) request.getAttribute("selectedDate");
    String error = (String) request.getAttribute("error");
    List<Attribution> attributions = (List<Attribution>) request.getAttribute("attributions");
    List<Reservation> reservationsNonAssignees = (List<Reservation>) request.getAttribute("reservationsNonAssignees");
    DateTimeFormatter dtf = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    // Sprint 7 : Correction du comptage (compter réservations DISTINCT + passagers corrects)
    int nbAssigned = 0;
    int totalPassagersAssigned = 0;
    Set<Long> assignedReservationIds = new HashSet<>();

    if (attributions != null) {
        for (Attribution a : attributions) {
            for (Reservation r : a.getReservations()) {
                assignedReservationIds.add(r.getId());
                // Sprint 7 : Utiliser nbPassagersAssignes (nombre dans CE véhicule), fallback to getTotalPassengers()
                Integer nbPass = a.getNbPassagersAssignes();
                if (nbPass != null) {
                    totalPassagersAssigned += nbPass;  // ✅ Safe unboxing
                } else {
                    totalPassagersAssigned += a.getTotalPassengers();
                }
            }
        }
        nbAssigned = assignedReservationIds.size();  // Nombre DISTINCT de réservations
    }
    int nbUnassigned = (reservationsNonAssignees != null) ? reservationsNonAssignees.size() : 0;
    int nbGroupes = (attributions != null) ? attributions.size() : 0;
%>

<!-- ══════════════ HEADER ══════════════ -->
<header class="page-header">
    <div class="header-inner">
        <div class="header-title-group">
            <div class="header-eyebrow">Gestion de flotte</div>
            <h1 class="header-title">Planning d'attribution</h1>
            <% if (selectedDate != null) { %>
                <div class="header-date">Date sélectionnée : <strong><%= selectedDate %></strong></div>
            <% } %>
        </div>
        <div class="header-actions">
            <a href="<%= request.getContextPath() %>/planning/form" class="btn btn-outline">
                <span class="btn-icon">←</span> Changer de date
            </a>
            <% if (selectedDate != null) { %>
                <a href="<%= request.getContextPath() %>/planning/result?date=<%= selectedDate %>" class="btn btn-primary">
                    <span class="btn-icon">↻</span> Rafraîchir
                </a>
            <% } %>
        </div>
    </div>
</header>

<!-- ══════════════ MAIN ══════════════ -->
<main class="main">

    <% if (error != null) { %>
        <div class="alert alert-error">
            <span class="alert-icon">⚠</span>
            <%= error %>
        </div>
    <% } %>

    <!-- KPI STRIP -->
    <div class="kpi-strip">
        <div class="kpi-card neutral">
            <div class="kpi-value"><%= nbAssigned + nbUnassigned %></div>
            <div class="kpi-label">Réservations totales</div>
        </div>
        <div class="kpi-card green">
            <div class="kpi-value"><%= nbAssigned %></div>
            <div class="kpi-label">Assignées</div>
        </div>
        <div class="kpi-card red">
            <div class="kpi-value"><%= nbUnassigned %></div>
            <div class="kpi-label">Non assignées</div>
        </div>
        <div class="kpi-card gold">
            <div class="kpi-value"><%= nbGroupes %></div>
            <div class="kpi-label">Véhicules utilisés</div>
        </div>
    </div>

    <!-- ══ SECTION : ATTRIBUTIONS ══ -->
    <div class="section-header">
        <h2 class="section-title">Attributions de véhicules</h2>
        <span class="section-pill pill-green"><%= nbGroupes %> véhicule<%= nbGroupes > 1 ? "s" : "" %></span>
    </div>
    <div class="section-divider"></div>

    <% if (attributions != null && !attributions.isEmpty()) { %>
        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Véhicule</th>
                        <th>Réservation(s)</th>
                        <th>Départ</th>
                        <th>Destination(s)</th>
                        <th>Capacité</th>
                        <th>Départ</th>
                        <th>Retour</th>
                        <th>Statut</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (Attribution attr : attributions) {
                        List<Reservation> grouped = attr.getReservations();
                        // Sprint 7 : Utiliser nbPassagersAssignes (passagers dans CE véhicule)
                        int totalPass = attr.getNbPassagersAssignes() != null ? attr.getNbPassagersAssignes() : attr.getTotalPassengers();
                        int placesRestantes = attr.getVehicule() != null ? attr.getVehicule().getNbPlace() - totalPass : 0;
                        int totalPlaces = attr.getVehicule() != null ? attr.getVehicule().getNbPlace() : 1;
                        double fillPct = totalPlaces > 0 ? (double) totalPass / totalPlaces * 100 : 0;
                        List<TrajetCar> trajects = attr.getDetailTraject();
                    %>
                    <!-- MAIN ROW -->
                    <tr class="row-main">
                        <!-- Véhicule -->
                        <td>
                            <div class="vehicle-ref">
                                <%= attr.getVehicule() != null ? attr.getVehicule().getReference() : "—" %>
                            </div>
                            <div class="vehicle-meta">
                                <%= attr.getVehicule() != null ? attr.getVehicule().getNbPlace() + " places" : "" %>
                                <%
                                    if (attr.getVehicule() != null && attr.getVehicule().getTypeCarburant() != null) {
                                        String tc = attr.getVehicule().getTypeCarburant().name();
                                        String cl = "";
                                        switch(tc) {
                                            case "D":  cl = "· Diesel";    break;
                                            case "Es": cl = "· Essence";   break;
                                            case "H":  cl = "· Hybride";   break;
                                            case "El": cl = "· Électrique"; break;
                                            default:   cl = "· " + tc;
                                        }
                                %>
                                    <%= cl %>
                                <% } %>
                            </div>
                        </td>

                        <!-- Réservations -->
                        <td>
                            <%
                                // Sprint 7 : Détection de division
                                // Une division = même réservation dans plusieurs véhicules
                                Map<Long, Long> reservationCount = new HashMap<>();
                                if (attributions != null) {
                                    for (Attribution a : attributions) {
                                        for (Reservation r : a.getReservations()) {
                                            reservationCount.put(r.getId(),
                                                reservationCount.getOrDefault(r.getId(), 0L) + 1);
                                        }
                                    }
                                }
                            %>
                            <% for (Reservation r : grouped) { %>
                                <div class="resa-line">
                                    <span style="font-weight:600;">#<%= r.getId() %></span>
                                    &ensp;<span style="color:var(--ink-light)"><%= r.getCustomerId() %></span>

                                    <!-- Sprint 7 : Afficher ratio si division -->
                                    <% if (reservationCount.getOrDefault(r.getId(), 0L) > 1 &&
                                            totalPass < r.getPassengerNbr()) { %>
                                        &ensp;<span style="color:var(--gold); font-weight:600; font-size:11px;">
                                            [<%= totalPass %>/<%= r.getPassengerNbr() %> pass.]
                                        </span>
                                    <% } else { %>
                                        &ensp;<span style="color:var(--ink-faint);font-size:12px;">
                                            <%= r.getPassengerNbr() %> pass.
                                        </span>
                                    <% } %>
                                </div>
                            <% } %>

                            <!-- Badge regroupement (existant) -->
                            <% if (grouped.size() > 1) { %>
                                <span class="grouped-note">↦ <%= grouped.size() %> groupées</span>
                            <% } %>

                            <!-- Sprint 7 : Badge division si applicable -->
                            <%
                                long divisionCount = 0;
                                if (grouped != null && !grouped.isEmpty()) {
                                    divisionCount = reservationCount.getOrDefault(grouped.get(0).getId(), 0L);
                                }
                            %>
                            <% if (divisionCount > 1) { %>
                                <span style="display:inline-block; margin-top:6px; padding:3px 8px;
                                           border-radius:4px; background:#fff3cd; color:#856404;
                                           font-size:10px; font-weight:600; letter-spacing:0.05em;">
                                    📊 DIVISÉE ×<%= divisionCount %>
                                </span>
                            <% } %>
                        </td>

                        <!-- Départ -->
                        <td>
                            <%= attr.getReservation().getLieuDepart() != null
                                ? attr.getReservation().getLieuDepart().getLibelle() : "—" %>
                        </td>

                        <!-- Destinations -->
                        <td>
                            <% for (int i = 0; i < grouped.size(); i++) {
                                Reservation r = grouped.get(i);
                            %>
                                <div class="resa-line">
                                    <%= r.getLieuDestination() != null ? r.getLieuDestination().getLibelle() : "—" %>
                                </div>
                            <% } %>
                        </td>

                        <!-- Capacité -->
                        <td style="min-width:120px;">
                            <div style="font-weight:600; font-size:14px;">
                                <%= totalPass %><span style="color:var(--ink-faint); font-weight:400;"> / <%= totalPlaces %></span>
                            </div>
                            <div class="capacity-bar-wrap">
                                <div class="capacity-bar">
                                    <div class="capacity-bar-fill <%= placesRestantes == 0 ? "cap-full" : "cap-ok" %>"
                                         style="width:<%= Math.min(fillPct, 100) %>%"></div>
                                </div>
                                <span class="capacity-text"><%= placesRestantes %> libre<%= placesRestantes > 1 ? "s" : "" %></span>
                            </div>
                        </td>

                        <!-- Heure départ -->
                        <td>
                            <% if (attr.getDateHeureDepart() != null) {
                                String[] dtParts = attr.getDateHeureDepart().format(dtf).split(" ");
                            %>
                                <div class="time-main"><%= dtParts.length > 1 ? dtParts[1] : dtParts[0] %></div>
                                <div class="time-date"><%= dtParts[0] %></div>
                            <% } else { %>—<% } %>
                        </td>

                        <!-- Heure retour -->
                        <td>
                            <% if (attr.getDateHeureRetour() != null) {
                                String[] dtParts = attr.getDateHeureRetour().format(dtf).split(" ");
                            %>
                                <div class="time-main"><%= dtParts.length > 1 ? dtParts[1] : dtParts[0] %></div>
                                <div class="time-date"><%= dtParts[0] %></div>
                            <% } else { %>—<% } %>
                        </td>

                        <!-- Statut -->
                        <td><span class="badge badge-assigned">Assigné</span></td>
                    </tr>

                    <!-- DETAIL TRAJECT ROW -->
                    <tr class="row-detail">
                        <td colspan="8">
                            <%
                                double sumDurre = 0.0;
                                double sumDistance = 0.0;
                                for (TrajetCar t : trajects) {
                                    sumDurre += t.getDurre();
                                    sumDistance += t.getDistance();
                                }
                            %>
                            <ul class="traject-list">
                                <% for (int i = 0; i < trajects.size(); i++) {
                                    TrajetCar t = trajects.get(i);
                                %>
                                    <li class="traject-item">
                                        <span class="traject-num"><%= i + 1 %></span>
                                        <span><%= t.getReservationFrom().getLibelle() %></span>
                                        <span class="traject-arrow">→</span>
                                        <span><%= t.getReservationTo().getLibelle() %></span>
                                        <span class="traject-km">
                                            <%= t.getDistance() %> km &nbsp;·&nbsp; <%= (int)(t.getDurre() * 60) %> min
                                        </span>
                                    </li>
                                <% } %>
                            </ul>
                            <% if (trajects.size() > 1) { %>
                                <div class="traject-totals">
                                    <span class="traject-total-tag">Ʃ <%= sumDistance %> km</span>
                                    <span class="traject-total-tag">Ʃ <%= (int)(sumDurre * 60) %> min</span>
                                </div>
                            <% } %>
                        </td>
                    </tr>

                    <% } %>
                </tbody>
            </table>
        </div>
    <% } else { %>
        <div class="table-wrap">
            <div class="empty-state">
                <div class="empty-state-icon">📋</div>
                <div class="empty-state-text">Aucune attribution pour cette date.</div>
            </div>
        </div>
    <% } %>

    <!-- ══ SECTION : NON ASSIGNÉES ══ -->
    <div class="section-unassigned">
        <div class="section-header">
            <h2 class="section-title">Réservations non assignées</h2>
            <span class="section-pill pill-red"><%= nbUnassigned %> réservation<%= nbUnassigned > 1 ? "s" : "" %></span>
        </div>
        <div class="section-divider"></div>

        <% if (reservationsNonAssignees != null && !reservationsNonAssignees.isEmpty()) { %>
            <div class="alert alert-info">
                <span class="alert-icon">ℹ</span>
                Ces réservations n'ont pas pu être assignées — aucun véhicule disponible, places insuffisantes, conflit horaire ou distance manquante.
            </div>
            <div class="table-wrap section-unassigned">
                <table>
                    <thead>
                        <tr>
                            <th>Réservation</th>
                            <th>Client</th>
                            <th>Passagers</th>
                            <th>Départ</th>
                            <th>Destination</th>
                            <th>Date d'arrivée</th>
                            <th>Statut</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (Reservation resa : reservationsNonAssignees) { %>
                            <tr class="row-main">
                                <td><span style="font-weight:600;">#<%= resa.getId() %></span></td>
                                <td><%= resa.getCustomerId() %></td>
                                <td><%= resa.getPassengerNbr() %></td>
                                <td><%= resa.getLieuDepart() != null ? resa.getLieuDepart().getLibelle() : "—" %></td>
                                <td><%= resa.getLieuDestination() != null ? resa.getLieuDestination().getLibelle() : "—" %></td>
                                <td>
                                    <% if (resa.getArrivalDate() != null) {
                                        String[] dtParts = resa.getArrivalDate().format(dtf).split(" ");
                                    %>
                                        <div class="time-main"><%= dtParts.length > 1 ? dtParts[1] : dtParts[0] %></div>
                                        <div class="time-date"><%= dtParts[0] %></div>
                                    <% } else { %>—<% } %>
                                </td>
                                <td><span class="badge badge-unassigned">Non assigné</span></td>
                            </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        <% } else { %>
            <div class="table-wrap">
                <div class="empty-state">
                    <div class="empty-state-icon">✓</div>
                    <div class="empty-state-text">Toutes les réservations ont été assignées avec succès.</div>
                </div>
            </div>
        <% } %>
    </div>

</main>
</body>
</html>
