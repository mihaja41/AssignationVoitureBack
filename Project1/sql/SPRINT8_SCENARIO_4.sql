-- ================================================================================
-- SPRINT 8 - SCENARIO 4: DISPONIBILITE HORAIRE (heure_disponible_debut)
-- ================================================================================
-- Date: 30/03/2026
-- Objectif: Verifier que les vehicules ne sont utilises qu'apres leur heure de dispo
--
-- v4 (8pl) est disponible seulement a partir de 10:30
-- ================================================================================

DELETE FROM attribution;
DELETE FROM reservation;

INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- Avant 10:30 (v4 pas encore dispo)
(1, 2, 'r1_4pass', 4, '2026-03-30 10:00:00', 1),
-- Apres 10:30 (v4 dispo)
(2, 2, 'r2_4pass', 4, '2026-03-30 10:35:00', 1);

SELECT setval('reservation_id_seq', 2);

SELECT '========================================' as info;
SELECT 'SCENARIO 4: DISPONIBILITE HORAIRE' as scenario;
SELECT '========================================' as info;

SELECT 'v4 est dispo seulement a partir de 10:30' as rule;

SELECT '--- RESERVATIONS ---' as section;
SELECT r.id, r.customer_id, r.passenger_nbr, r.arrival_date::time FROM reservation r;

SELECT '--- LOGIQUE ATTENDUE ---' as logic;
SELECT 'r1 (10:00): v4 NON dispo, utiliser v1/v2/v3' as r1;
SELECT 'r2 (10:35): v4 DISPO maintenant, peut utiliser v4' as r2;

SELECT '========================================' as info;
SELECT 'Lancer: GET /api/planning/auto?date=2026-03-30' as action;
SELECT '========================================' as info;
