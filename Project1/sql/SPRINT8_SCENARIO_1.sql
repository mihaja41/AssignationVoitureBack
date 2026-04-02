-- ================================================================================
-- SPRINT 8 - SCENARIO 1: REGROUPEMENT OPTIMAL (Closest Fit)
-- ================================================================================
-- Date: 27/03/2026
-- Objectif: Verifier que le systeme choisit la reservation avec l'ecart minimum
--
-- Logique:
-- - r1 (9 pass) prend v1 (10 places) -> 1 place restante
-- - Pour 1 place: r2(5) ecart=4, r3(3) ecart=0, r4(2) ecart=1
-- - r3 est choisie (ecart minimum)
-- ================================================================================

-- Nettoyer les reservations et attributions (garder lieux/vehicules/distances/parametres)
DELETE FROM attribution;
DELETE FROM reservation;

-- ==========================================
-- RESERVATIONS
-- ==========================================

INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 2, 'r1_9pass', 9, '2026-03-27 08:00:00', 1),
(2, 2, 'r2_5pass', 5, '2026-03-27 08:10:00', 1),
(3, 2, 'r3_3pass', 3, '2026-03-27 08:15:00', 1),
(4, 2, 'r4_2pass', 2, '2026-03-27 08:20:00', 1);

SELECT setval('reservation_id_seq', 4);

-- ==========================================
-- AFFICHAGE
-- ==========================================

SELECT '========================================' as info;
SELECT 'SCENARIO 1: REGROUPEMENT OPTIMAL' as scenario;
SELECT '========================================' as info;

SELECT 'Reservations:' as section;
SELECT r.id, r.customer_id, r.passenger_nbr, r.arrival_date::time
FROM reservation r
ORDER BY r.arrival_date;

SELECT '--- LOGIQUE ATTENDUE ---' as logic;
SELECT 'v1 (10pl): r1(9) + r3(3) arrive a 08:15' as step_1;
SELECT '  - r1 prend 9 places, reste 1' as detail;
SELECT '  - r3 ecart=|1-3|=0 (minimum pour remplir)' as detail;
SELECT '  - r1+r3 = 10 PLEIN' as detail;

SELECT 'v2 (10pl): r2(5)' as step_2;

SELECT 'v3 (12pl): r4(2)' as step_3;

SELECT '========================================' as info;
SELECT 'Lancer: GET /api/planning/auto?date=2026-03-27' as action;
SELECT '========================================' as info;
