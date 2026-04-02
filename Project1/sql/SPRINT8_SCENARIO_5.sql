-- ================================================================================
-- SPRINT 8 - SCENARIO 5: GESTION DES RESTES (ReservationPartielle)
-- ================================================================================
-- Date: 31/03/2026
-- Objectif: Verifier que les passagers non assignes sont correctement reportes
--
-- r1 (25 pass) avec places limitees -> restes non assignes
-- ================================================================================

DELETE FROM attribution;
DELETE FROM reservation;

-- Attributions fictives pour bloquer v2 et v3
INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(100, 2, 'BLOCKER_V2', 10, '2026-03-30 07:00:00', 1),
(101, 2, 'BLOCKER_V3', 12, '2026-03-30 07:00:00', 1);

INSERT INTO attribution (id, reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes) VALUES
(100, 100, 2, '2026-03-31 07:00:00', '2026-03-31 10:00:00', 'TERMINE', 10),
(101, 101, 3, '2026-03-31 07:00:00', '2026-03-31 10:00:00', 'TERMINE', 12);

-- Reservation reelle
INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 2, 'r1_25pass', 25, '2026-03-31 08:30:00', 1);

SELECT setval('reservation_id_seq', 101);

SELECT '========================================' as info;
SELECT 'SCENARIO 5: GESTION DES RESTES' as scenario;
SELECT '========================================' as info;

SELECT 'Situation:' as context;
SELECT '  - r1: 25 passagers' as detail;
SELECT '  - v1: 10 places (SEUL disponible)' as detail;
SELECT '  - v2, v3: bloques jusqu''a 10:00' as detail;

SELECT '--- LOGIQUE ATTENDUE ---' as logic;
SELECT 'v1 prend 10 de r1' as assign;
SELECT 'Reste: 15 passagers non assignes' as remainder;
SELECT 'ReservationPartielle creee pour les 15' as partial;

SELECT '========================================' as info;
SELECT 'Lancer: GET /api/planning/auto?date=2026-03-31' as action;
SELECT '========================================' as info;
