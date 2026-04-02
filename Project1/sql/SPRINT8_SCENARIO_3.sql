-- ================================================================================
-- SPRINT 8 - SCENARIO 3: RETOUR VEHICULE + FENETRE D'ATTENTE (PRINCIPAL)
-- ================================================================================
-- Date: 29/03/2026
-- Objectif: Tester les retours de véhicules et les fenêtres d'attente avec CLOSEST FIT
--
-- Ce scénario reproduit l'exemple de la specification:
-- - v1 et v2 reviennent a 09:45 avec attributions pré-existantes
-- - v3 revient a 10:12
-- - Restes de réservations: r1(9), r2(5) arrivent AVANT 09:45
-- - Nouvelles: r3(1), r4(7), r5(5) arrivent dans les fenêtres
-- ================================================================================

DELETE FROM attribution;
DELETE FROM reservation;

-- ==========================================
-- RESERVATIONS FICTIVES POUR ATTRIBUTIONS PRE-EXISTANTES
-- (Elles ne seront pas traitées, juste servant de lien)
-- ==========================================

INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(100, 2, 'INIT_V1', 10, '2026-03-28 07:00:00', 1),
(101, 2, 'INIT_V2', 10, '2026-03-28 07:00:00', 1),
(102, 3, 'INIT_V3', 12, '2026-03-28 07:30:00', 1);

-- ==========================================
-- ATTRIBUTIONS PRE-EXISTANTES (VEHICULES EN COURSE)
-- ==========================================
-- v1 et v2 reviennent a 09:45
-- v3 revient a 10:12

INSERT INTO attribution (id, reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes) VALUES
(100, 100, 1, '2026-03-29 08:45:00', '2026-03-29 09:45:00', 'TERMINE', 10),
(101, 101, 2, '2026-03-29 08:45:00', '2026-03-29 09:45:00', 'TERMINE', 10),
(102, 102, 3, '2026-03-29 09:00:00', '2026-03-29 10:12:00', 'TERMINE', 12);

-- ==========================================
-- RESERVATIONS REELLES A TRAITER (29/03/2026)
-- ==========================================

INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- Restes non assignes (PRIORITAIRES - arrivent AVANT 09:45)
(1, 2, 'r1_9pass_RESTE', 9, '2026-03-29 08:00:00', 1),
(2, 2, 'r2_5pass_RESTE', 5, '2026-03-29 07:30:00', 1),

-- Nouvelles arrivees (dans fenetre [09:45-10:15])
(3, 2, 'r3_1pass', 1, '2026-03-29 10:00:00', 1),
(4, 2, 'r4_7pass', 7, '2026-03-29 10:10:00', 1),

-- Apres v3 (10:12)
(5, 3, 'r5_5pass', 5, '2026-03-29 10:11:00', 1);

SELECT setval('reservation_id_seq', 102);

-- ==========================================
-- AFFICHAGE
-- ==========================================

SELECT '========================================' as info;
SELECT 'SCENARIO 3: RETOUR VEHICULE + FENETRE' as scenario;
SELECT '========================================' as info;

SELECT '--- ATTRIBUTIONS PRE-EXISTANTES ---' as section;
SELECT
    v.reference,
    a.date_heure_retour::time as retour_prevu
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
WHERE a.id IN (100, 101, 102)
ORDER BY a.date_heure_retour;

SELECT '--- RESERVATIONS REELLES ---' as section;
SELECT
    r.id,
    r.customer_id,
    r.passenger_nbr,
    r.arrival_date::time as arrivee
FROM reservation r
WHERE r.id < 100
ORDER BY r.arrival_date;

SELECT '--- LOGIQUE ATTENDUE ---' as logic;

SELECT '09:45 v1 et v2 reviennent:' as timeline;

SELECT '  v1 (10pl):' as v1;
SELECT '    - CLOSEST FIT 10 places: r1(9) ecart=1, r2(5) ecart=5' as detail;
SELECT '    - v1 prend r1(9), reste 1 place' as detail;
SELECT '    - Remplir avec r2(5): 1 place vs 5 pass ecart=4' as detail;
SELECT '    - v1 prend 1 de r2 -> 10 PLEIN' as detail;

SELECT '  v2 (10pl):' as v2;
SELECT '    - r2 reste (4 passagers)' as detail;
SELECT '    - v2 prend r2(4), reste 6 places' as detail;
SELECT '    - FENETRE [09:45-10:15] ouverte' as detail;

SELECT '10:00-10:10 Fenetre v2:' as fenetre;
SELECT '    - r3(1) arrive: ecart=|6-1|=5' as detail;
SELECT '    - r4(7) arrive: ecart=|6-7|=1 OPTIMAL' as detail;
SELECT '    - v2 prend 6 de r4 -> 10 PLEIN' as detail;

SELECT '10:12 v3 revient:' as v3_return;
SELECT '    - Reservations non assignees: r5(5), r3(1), r4_reste(1)' as detail;
SELECT '    - CLOSEST FIT: r5(5) ecart=7, autres ecart>7' as detail;
SELECT '    - v3 prend r5(5), puis r3(1), puis r4(1)' as detail;

SELECT '========================================' as info;
SELECT 'Lancer: GET /api/planning/auto?date=2026-03-29' as action;
SELECT '========================================' as info;
