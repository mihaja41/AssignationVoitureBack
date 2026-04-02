-- ================================================================================
-- SPRINT 8 - SCENARIO 2: DIVISION OPTIMALE
-- ================================================================================
-- Date: 28/03/2026
-- Objectif: Verifier que lors d'une division, le vehicule avec places les plus proches est choisi
--
-- Logique:
-- - r1 (20 pass) necessite division
-- - V1 (10pl) ecart=|10-20|=10
-- - V3 (12pl) ecart=|12-20|=8 (OPTIMAL)
-- - Apres V3: reste 8 pass, V2 (10pl) ecart=|10-8|=2
-- ================================================================================

DELETE FROM attribution;
DELETE FROM reservation;

INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 2, 'r1_20pass', 20, '2026-03-28 09:30:00', 1);

SELECT setval('reservation_id_seq', 1);

SELECT '========================================' as info;
SELECT 'SCENARIO 2: DIVISION OPTIMALE' as scenario;
SELECT '========================================' as info;

SELECT 'Reservations:' as section;
SELECT r.id, r.customer_id, r.passenger_nbr
FROM reservation r
ORDER BY r.id;

SELECT '--- LOGIQUE ATTENDUE ---' as logic;
SELECT 'Iteration 1: 20 passagers' as iter;
SELECT '  - V1 (10pl): ecart=|10-20|=10' as detail;
SELECT '  - V3 (12pl): ecart=|12-20|=8 OPTIMAL' as detail;
SELECT '  - V3 prend 12 passagers' as detail;

SELECT 'Iteration 2: 8 passagers restants' as iter;
SELECT '  - V2 (10pl): ecart=|10-8|=2' as detail;
SELECT '  - V1 (10pl): ecart=|10-8|=2' as detail;
SELECT '  - V2 prend 8 passagers (ou V1)' as detail;

SELECT '========================================' as info;
SELECT 'Lancer: GET /api/planning/auto?date=2026-03-28' as action;
SELECT '========================================' as info;
