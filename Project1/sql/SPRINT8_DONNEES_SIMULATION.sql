-- ================================================================================
-- SPRINT 8 - DONNEES DE SIMULATION PROGRESSIVES
-- ================================================================================
-- Ce fichier contient les réservations pour PLUSIEURS JOURS
-- Chaque jour est un scénario différent
--
-- WORKFLOW:
-- 1. Initialiser une fois: SPRINT8_UNIQUE_INIT.sql
-- 2. Charger ce fichier pour ajouter les réservations
-- 3. Lancer la planification jour par jour
-- 4. Les attributions du jour précédent deviennent pré-existantes pour le jour suivant
-- ================================================================================

-- ==========================================
-- JOUR 1: 27/03/2026 - SCENARIO SIMPLE (PAS D'ATTRIBUTIONS PRE-EXISTANTES)
-- ==========================================
-- Ce jour, tous les véhicules sont disponibles dès le début
-- On teste: Regroupement optimal + Division

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES

-- JOUR 1 - 27/03/2026 - Regroupement optimal
(2, 'J1_r1_9pass', 9, '2026-03-27 08:00:00', 1),   -- 9 pass, arrive 08:00
(2, 'J1_r2_5pass', 5, '2026-03-27 08:05:00', 1),   -- 5 pass, arrive 08:05
(2, 'J1_r3_3pass', 3, '2026-03-27 08:10:00', 1),   -- 3 pass, arrive 08:10
(2, 'J1_r4_2pass', 2, '2026-03-27 08:15:00', 1),   -- 2 pass, arrive 08:15

-- JOUR 2 - 28/03/2026 - Division + Retour véhicules
-- Ce jour, les véhicules du Jour 1 sont probablement revenus
-- On ajoute de grandes réservations pour tester la division
(2, 'J2_r1_20pass', 20, '2026-03-28 09:00:00', 1),  -- 20 pass, nécessite division
(3, 'J2_r2_8pass', 8, '2026-03-28 09:30:00', 1),    -- 8 pass

-- JOUR 3 - 29/03/2026 - Fenêtre d'attente simulée
-- Si les véhicules du Jour 2 sont en course, ils reviennent pendant ce jour
-- On ajoute des réservations qui arrivent PENDANT la fenêtre d'attente
(2, 'J3_r1_4pass', 4, '2026-03-29 07:30:00', 1),    -- Arrive tôt (reste non assigné si pas de véhicule)
(2, 'J3_r2_6pass', 6, '2026-03-29 08:00:00', 1),    -- Arrive tôt
(2, 'J3_r3_1pass', 1, '2026-03-29 10:00:00', 1),    -- Arrive dans fenêtre probable
(2, 'J3_r4_7pass', 7, '2026-03-29 10:10:00', 1),    -- Arrive dans fenêtre probable
(3, 'J3_r5_5pass', 5, '2026-03-29 10:11:00', 1),    -- Arrive dans fenêtre probable

-- JOUR 4 - 30/03/2026 - Test heure_disponible_debut (v4)
-- v4 est disponible seulement à partir de 10:30
(2, 'J4_r1_4pass', 4, '2026-03-30 10:00:00', 1),    -- Avant 10:30, v4 pas dispo
(2, 'J4_r2_4pass', 4, '2026-03-30 10:35:00', 1),    -- Après 10:30, v4 dispo
(2, 'J4_r3_6pass', 6, '2026-03-30 11:00:00', 1),    -- Après, tous dispo

-- JOUR 5 - 31/03/2026 - Grande réservation + Restes
-- Test de gestion des restes non assignés
(2, 'J5_r1_35pass', 35, '2026-03-31 09:00:00', 1),  -- 35 pass, total places = 40
(2, 'J5_r2_10pass', 10, '2026-03-31 09:30:00', 1);  -- 10 pass supplémentaires

-- ==========================================
-- AFFICHAGE RESUME
-- ==========================================

SELECT '========================================' as info;
SELECT 'RESERVATIONS CHARGEES - SPRINT 8' as status;
SELECT '========================================' as info;

SELECT '--- PAR JOUR ---' as section;
SELECT
    DATE(arrival_date) as jour,
    COUNT(*) as nb_reservations,
    SUM(passenger_nbr) as total_passagers,
    STRING_AGG(customer_id || '(' || passenger_nbr || 'p)', ', ' ORDER BY arrival_date) as detail
FROM reservation
GROUP BY DATE(arrival_date)
ORDER BY jour;

SELECT '========================================' as info;
SELECT 'WORKFLOW DE SIMULATION' as guide;
SELECT '========================================' as info;

SELECT 'ETAPE 1: Jour 1 (27/03)' as etape;
SELECT '  - Appeler: GET /api/planning/auto?date=2026-03-27' as action;
SELECT '  - Verifier les attributions creees' as action;
SELECT '  - Noter les heures de retour' as action;

SELECT 'ETAPE 2: Jour 2 (28/03)' as etape;
SELECT '  - Les attributions du Jour 1 sont PRE-EXISTANTES' as note;
SELECT '  - Appeler: GET /api/planning/auto?date=2026-03-28' as action;

SELECT 'ETAPE 3: Jour 3 (29/03)' as etape;
SELECT '  - Les attributions des Jours 1+2 sont PRE-EXISTANTES' as note;
SELECT '  - Teste les FENETRES D''ATTENTE' as note;
SELECT '  - Appeler: GET /api/planning/auto?date=2026-03-29' as action;

SELECT 'ETAPE 4: Jour 4 (30/03)' as etape;
SELECT '  - Teste heure_disponible_debut de v4' as note;
SELECT '  - Appeler: GET /api/planning/auto?date=2026-03-30' as action;

SELECT 'ETAPE 5: Jour 5 (31/03)' as etape;
SELECT '  - Teste les RESTES non assignes' as note;
SELECT '  - Appeler: GET /api/planning/auto?date=2026-03-31' as action;

SELECT '========================================' as info;
