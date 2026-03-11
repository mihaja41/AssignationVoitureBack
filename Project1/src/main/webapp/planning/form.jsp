<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Planification — Sélection de date</title>
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
            background: linear-gradient(135deg, #f5f7fa 0%, #e9ecef 100%);
            color: var(--ink);
            min-height: 100vh;
            line-height: 1.6;
            display: flex;
            flex-direction: column;
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
        .btn-icon { font-size: 14px; opacity: .75; }

        /* ── MAIN ── */
        .main {
            max-width: 1280px;
            margin: 0 auto;
            padding: 60px 48px;
            flex: 1;
            width: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        /* ── FORM CARD ── */
        .form-card {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 16px;
            box-shadow: 0 20px 40px -12px rgba(0,0,0,0.1);
            width: 100%;
            max-width: 520px;
            margin: 0 auto;
            overflow: hidden;
            animation: fadeUp 0.5s ease;
        }

        @keyframes fadeUp {
            from {
                opacity: 0;
                transform: translateY(12px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .form-header {
            padding: 28px 32px 12px;
            border-bottom: 1px solid var(--border-soft);
            background: linear-gradient(to bottom, #ffffff, var(--paper));
        }
        .form-header-title {
            font-family: 'DM Serif Display', serif;
            font-size: 24px;
            font-weight: 400;
            color: var(--ink);
            margin-bottom: 4px;
        }
        .form-header-sub {
            font-size: 13px;
            color: var(--ink-light);
        }

        .form-body {
            padding: 32px;
        }

        .form-group {
            margin-bottom: 28px;
        }
        .form-label {
            display: block;
            font-size: 12px;
            font-weight: 600;
            letter-spacing: .08em;
            text-transform: uppercase;
            color: var(--ink-light);
            margin-bottom: 8px;
        }
        .form-input {
            width: 100%;
            padding: 14px 16px;
            background: var(--paper);
            border: 1px solid var(--border);
            border-radius: 8px;
            font-family: 'DM Sans', sans-serif;
            font-size: 15px;
            color: var(--ink);
            transition: all .2s ease;
        }
        .form-input:focus {
            outline: none;
            border-color: var(--accent);
            box-shadow: 0 0 0 3px var(--accent-dim);
            background: var(--surface);
        }
        .form-input::placeholder {
            color: var(--ink-faint);
            opacity: 0.7;
        }
        .form-hint {
            font-size: 12px;
            color: var(--ink-faint);
            margin-top: 8px;
            padding-left: 4px;
        }

        /* Custom date input styling */
        input[type="date"]::-webkit-calendar-picker-indicator {
            opacity: 0.5;
            padding: 4px;
            cursor: pointer;
            transition: opacity .2s;
        }
        input[type="date"]::-webkit-calendar-picker-indicator:hover {
            opacity: 1;
        }

        .button-group {
            display: flex;
            gap: 16px;
            margin-top: 32px;
        }
        .btn-primary {
            background: var(--accent);
            color: #fff;
            border-color: var(--accent);
            flex: 2;
            padding: 14px 20px;
            font-size: 14px;
            font-weight: 600;
            letter-spacing: .05em;
            border-radius: 8px;
            border: none;
            cursor: pointer;
            transition: all .2s ease;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }
        .btn-primary:hover {
            background: #223d32;
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(44, 74, 62, 0.2);
        }
        .btn-primary:active {
            transform: translateY(0);
        }
        .btn-secondary {
            background: transparent;
            color: var(--ink-light);
            border: 1px solid var(--border);
            flex: 1;
            padding: 14px 20px;
            font-size: 14px;
            font-weight: 500;
            border-radius: 8px;
            cursor: pointer;
            transition: all .2s ease;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            text-decoration: none;
        }
        .btn-secondary:hover {
            background: var(--border-soft);
            color: var(--ink);
            border-color: var(--ink-faint);
        }

        /* ── ALERT ── */
        .alert {
            display: flex;
            align-items: flex-start;
            gap: 12px;
            padding: 14px 18px;
            border-radius: 8px;
            font-size: 13.5px;
            margin-bottom: 24px;
            border: 1px solid;
        }
        .alert-error {
            background: var(--warn-dim);
            color: var(--warn);
            border-color: #e8c0c0;
        }
        .alert-icon {
            font-size: 16px;
            flex-shrink: 0;
            margin-top: 1px;
        }

        /* ── FOOTER / BACK LINK (optionnel) ── */
        .form-footer {
            text-align: center;
            margin-top: 24px;
        }
        .back-link {
            color: var(--ink-light);
            text-decoration: none;
            font-size: 13px;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: color .2s;
        }
        .back-link:hover {
            color: var(--accent);
        }

        /* responsive */
        @media (max-width: 700px) {
            .page-header { padding: 20px 24px 16px; }
            .main { padding: 30px 20px; }
            .header-inner { flex-direction: column; align-items: flex-start; }
            .button-group { flex-direction: column; }
            .btn-primary, .btn-secondary { width: 100%; }
            .form-header { padding: 24px 24px 12px; }
            .form-body { padding: 24px; }
        }
    </style>
</head>
<body>

<!-- ══════════════ HEADER (identique à la page planning) ══════════════ -->
<header class="page-header">
    <div class="header-inner">
        <div class="header-title-group">
            <div class="header-eyebrow">Gestion de flotte</div>
            <h1 class="header-title">Planification des véhicules</h1>
        </div>
        <div class="header-actions">
            <a href="<%= request.getContextPath() %>/vehicules/list" class="btn btn-outline">
                <span class="btn-icon">←</span> Retour aux véhicules
            </a>
        </div>
    </div>
</header>

<!-- ══════════════ MAIN CONTENT ══════════════ -->
<main class="main">

    <div class="form-card">

        <div class="form-header">
            <div class="form-header-title">Sélectionner une date</div>
            <div class="form-header-sub">Générer le planning d'attribution des véhicules</div>
        </div>

        <div class="form-body">

            <% String error = (String) request.getAttribute("error"); %>
            <% if (error != null) { %>
                <div class="alert alert-error">
                    <span class="alert-icon">⚠</span>
                    <%= error %>
                </div>
            <% } %>

            <form method="POST" action="<%= request.getContextPath() %>/planning/generate">

                <div class="form-group">
                    <label for="date" class="form-label">Date de planification</label>
                    <input type="date" id="date" name="date" required 
                           class="form-input"
                           value="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>">
                    <div class="form-hint">
                        Choisissez une date pour laquelle vous souhaitez générer le planning d'attribution.
                        Les réservations existantes pour cette date seront automatiquement assignées aux véhicules disponibles.
                    </div>
                </div>

                <div class="button-group">
                    <button type="submit" class="btn-primary">
                        <span>📅</span> Générer le planning
                    </button>
                    <a href="<%= request.getContextPath() %>/vehicules/list" class="btn-secondary">
                        <span>←</span> Annuler
                    </a>
                </div>

                <!-- Lien discret retour (optionnel) -->
                <div class="form-footer">
                    <a href="<%= request.getContextPath() %>/planning/result?date=<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>" 
                       class="back-link">
                        <span>↻</span> Voir le planning d'aujourd'hui
                    </a>
                </div>

            </form>

        </div> <!-- .form-body -->
    </div> <!-- .form-card -->

</main>

</body>
</html>