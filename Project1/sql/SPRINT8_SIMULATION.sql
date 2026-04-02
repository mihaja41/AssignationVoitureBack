-- ================================================================================
-- SPRINT 8 - DONNEES DE SIMULATION COMPLETE
-- ================================================================================
-- Date: 2026-04-03
--
-- OBJECTIF: Tester TOUTES les regles Sprint 8 avec des scenarios complets
-- Structure: 6 jours de test (27/03 - 01/04) avec 18 reservations
-- Total passagers: 165
--
-- SCENARIOS:
--   Jour 1 (27/03): Regroupement Optimal CLOSEST FIT
--   Jour 2 (28/03): Division Optimale CLOSEST FIT
--   Jour 3 (29/03): Retours vehicules + Fenetres d'attente
--   Jour 4 (30/03): Disponibilite horaire (heure_disponible_debut)
--   Jour 5 (31/03): Division en 3 parties
--   Jour 6 (01/04): Vehicule + Reservation meme heure
--
-- WORKFLOW:
--   1. Executer ce script pour initialiser la base
--   2. GET /api/planning/auto?date=2026-03-27 (Jour 1)
--   3. GET /api/planning/auto?date=2026-03-28 (Jour 2)
--   4. ... ainsi de suite jusqu'au 01/04
-- ================================================================================

-- Fermer les connexions actives
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'hotel_reservation' AND pid <> pg_backend_pid();

-- Supprimer et recreer la base
DROP DATABASE IF EXISTS hotel_reservation;
CREATE DATABASE hotel_reservation;

\c hotel_reservation

-- ==========================================
-- 1. NETTOYAGE
-- ==========================================
DROP TABLE IF EXISTS attribution CASCADE;
DROP TABLE IF EXISTS distance CASCADE;
DROP TABLE IF EXISTS reservation CASCADE;
DROP TABLE IF EXISTS vehicule CASCADE;
DROP TABLE IF EXISTS lieu CASCADE;
DROP TABLE IF EXISTS parameters CASCADE;
DROP TABLE IF EXISTS token CASCADE;

DROP TYPE IF EXISTS type_carburant_enum CASCADE;

-- ==========================================
-- 2. TYPE ENUM
-- ==========================================
CREATE TYPE type_carburant_enum AS ENUM ('D', 'Es', 'H', 'El');

-- ==========================================
-- 3. CREATION DES TABLES
-- ==========================================

CREATE TABLE token (
    id SERIAL PRIMARY KEY,
    token_name TEXT NOT NULL UNIQUE,
    expire_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked BOOLEAN DEFAULT false
);

CREATE TABLE lieu (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(255) NOT NULL,
    initial VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE vehicule (
    id BIGSERIAL PRIMARY KEY,
    reference VARCHAR(100) NOT NULL,
    nb_place INT NOT NULL,
    type_carburant type_carburant_enum NOT NULL,
    heure_disponible_debut TIME DEFAULT NULL
);

CREATE TABLE reservation (
    id BIGSERIAL PRIMARY KEY,
    lieu_depart_id BIGINT NOT NULL REFERENCES lieu(id) ON DELETE CASCADE,
    customer_id VARCHAR(100) NOT NULL,
    passenger_nbr INT NOT NULL,
    arrival_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lieu_destination_id BIGINT REFERENCES lieu(id) ON DELETE SET NULL
);

CREATE TABLE parameters (
    id SERIAL PRIMARY KEY,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE distance (
    id BIGSERIAL PRIMARY KEY,
    from_lieu_id BIGINT NOT NULL REFERENCES lieu(id) ON DELETE CASCADE,
    to_lieu_id BIGINT NOT NULL REFERENCES lieu(id) ON DELETE CASCADE,
    km_distance NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_distance_pair UNIQUE (from_lieu_id, to_lieu_id)
);

CREATE TABLE attribution (
    id SERIAL PRIMARY KEY,
    reservation_id INTEGER NOT NULL REFERENCES reservation(id) ON DELETE CASCADE,
    vehicule_id INTEGER NOT NULL REFERENCES vehicule(id) ON DELETE CASCADE,
    date_heure_depart TIMESTAMP NOT NULL,
    date_heure_retour TIMESTAMP NOT NULL,
    statut VARCHAR(20) NOT NULL DEFAULT 'ASSIGNE',
    nb_passagers_assignes INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 4. INDEX
-- ==========================================
CREATE INDEX idx_attribution_reservation ON attribution(reservation_id);
CREATE INDEX idx_attribution_vehicule ON attribution(vehicule_id);
CREATE INDEX idx_attribution_date_depart ON attribution(date_heure_depart);
CREATE INDEX idx_attribution_date_retour ON attribution(date_heure_retour);
CREATE INDEX idx_reservation_lieu_destination ON reservation(lieu_destination_id);
CREATE INDEX idx_reservation_lieu_depart ON reservation(lieu_depart_id);
CREATE INDEX idx_reservation_arrival_date ON reservation(arrival_date);
CREATE INDEX idx_lieu_code ON lieu(code);
CREATE INDEX idx_distance_from_to ON distance(from_lieu_id, to_lieu_id);

-- ==========================================
-- 5. PARAMETRES
-- ==========================================
INSERT INTO parameters (key, value) VALUES
('vitesse_moyenne', '50'),    -- 50 km/h
('temps_attente', '30');      -- 30 minutes fenetre d'attente

-- ==========================================
-- 6. LIEUX
-- ==========================================
INSERT INTO lieu (code, libelle, initial) VALUES
('IVATO', 'Aeroport Ivato', 'A'),       -- id = 1
('CARLTON', 'Hotel Carlton', 'B'),      -- id = 2
('COLBERT', 'Hotel Colbert', 'C');      -- id = 3

-- ==========================================
-- 7. DISTANCES (bidirectionnelles)
-- ==========================================
-- CARLTON -> IVATO: 25km = 30min aller, 60min total
-- COLBERT -> IVATO: 30km = 36min aller, 72min total

INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(1, 2, 25.00), (1, 3, 30.00),  -- Depuis IVATO
(2, 1, 25.00), (2, 3, 10.00),  -- Depuis CARLTON
(3, 1, 30.00), (3, 2, 10.00);  -- Depuis COLBERT

-- ==========================================
-- 8. VEHICULES (Configuration Sprint 8)
-- ==========================================
-- v1: 10 places, Diesel, toujours disponible
-- v2: 10 places, Essence, toujours disponible
-- v3: 12 places, Diesel, toujours disponible
-- v4: 8 places, Hybride, disponible a partir de 10:30 seulement

INSERT INTO vehicule (reference, nb_place, type_carburant, heure_disponible_debut) VALUES
('v1', 10, 'D',  NULL),        -- id = 1, Diesel, toujours
('v2', 10, 'Es', NULL),        -- id = 2, Essence, toujours
('v3', 12, 'D',  NULL),        -- id = 3, Diesel, toujours
('v4', 8,  'H',  '10:30:00');  -- id = 4, Hybride, des 10:30

-- ==========================================
-- ==========================================
-- RESERVATIONS PAR JOUR
-- ==========================================
-- ==========================================

-- ====================================================================
-- JOUR 1: 27/03/2026 - REGROUPEMENT OPTIMAL (CLOSEST FIT)
-- ====================================================================
-- Scenario: Tester le tri DESC + regroupement CLOSEST FIT
--
-- FENETRE [07:40 - 08:10]:
--   r4(2) arrive 07:40 -> debut fenetre
--   r3(3) arrive 07:50
--   r2(5) arrive 07:55
--   r1(9) arrive 08:00 -> MAX arrival_date
--
-- ALGORITHME:
--   Tri DESC: r1(9) > r2(5) > r3(3) > r4(2)
--
--   r1(9) -> v1(10) ecart=1 (CLOSEST FIT, diesel)
--   Regroupement v1: r4(2) ecart=|1-2|=1 -> v1 prend 1 de r4 = PLEIN
--
--   r2(5) -> v2(10) ecart=5
--   Regroupement v2: r3(3) ecart=|5-3|=2 -> v2 prend r3
--   Regroupement v2: r4_reste(1) ecart=|2-1|=1 -> v2 prend 1
--
-- RESULTAT ATTENDU:
--   v1: r1(9) + r4(1) = 10 -> depart 08:00
--   v2: r2(5) + r3(3) + r4(1) = 9 -> depart 08:00

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(2, 'J1_r1_9pass',   9, '2026-03-27 08:00:00', 1),  -- id=1
(2, 'J1_r2_5pass',   5, '2026-03-27 07:55:00', 1),  -- id=2
(2, 'J1_r3_3pass',   3, '2026-03-27 07:50:00', 1),  -- id=3
(2, 'J1_r4_2pass',   2, '2026-03-27 07:40:00', 1);  -- id=4

-- ====================================================================
-- JOUR 2: 28/03/2026 - DIVISION OPTIMALE (CLOSEST FIT)
-- ====================================================================
-- Scenario: Une reservation necessitant plusieurs vehicules
--
-- r1(20 passagers) arrive a 09:00
-- Aucun vehicule ne peut contenir 20
--
-- ALGORITHME:
--   CLOSEST FIT parmi tous:
--     v1(10): |10-20| = 10
--     v2(10): |10-20| = 10
--     v3(12): |12-20| = 8 (MINIMUM)
--   -> v3 prend 12, reste 8
--
--   ITERATION 2 (8 restants):
--     v1(10): |10-8| = 2 (MINIMUM, diesel)
--     v2(10): |10-8| = 2
--   -> v1 prend 8
--
-- RESULTAT ATTENDU:
--   v3: r1_partie1(12) -> depart 09:00
--   v1: r1_partie2(8) -> depart 09:00

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(2, 'J2_r1_20pass', 20, '2026-03-28 09:00:00', 1);  -- id=5

-- ====================================================================
-- JOUR 3: 29/03/2026 - RETOUR VEHICULE + FENETRE D'ATTENTE
-- ====================================================================
-- Scenario complexe avec multiple fenetres et retours
--
-- FENETRE 1 [07:00 - 07:30]:
--   r1(10), r2(10), r3(12) arrivent a 07:00
--   Tri DESC: r3(12) > r1(10) > r2(10)
--   -> v3 prend r3(12), v1 prend r1(10), v2 prend r2(10)
--   -> Retours: 08:00 (CARLTON)
--
-- Reservations en attente (arrivent APRES debut fenetre):
--   r4(9) arrive 07:30
--   r5(5) arrive 07:45
--
-- A 08:00: v1, v2, v3 retournent
--   -> Traiter r4(9), r5(5) prioritaires
--
-- FENETRE 2 [08:00 - 08:30] (retour vehicules):
--   r4(9) -> v1(10) ecart=1
--   Regroupement: r5(5) -> v1 prend 1 de r5 = PLEIN
--   r5_reste(4) -> v2(10) ecart=6
--   Regroupement: r6(7) arrive 08:15, ecart=|6-7|=1
--   -> v2 prend 6 de r6 = PLEIN
--   r6_reste(1) + r7(8) -> v3(12)
--
-- RESULTAT ATTENDU:
--   v1: r1(10) -> 07:00
--   v2: r2(10) -> 07:00
--   v3: r3(12) -> 07:00
--   v1: r4(9) + r5(1) = 10 -> 08:00
--   v2: r5(4) + r6(6) = 10 -> 08:15
--   v3: r7(8) + r6(1) = 9 -> 08:20

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- Trajet matinal (occupent v1, v2, v3)
(2, 'J3_r1_10pass_MATIN',  10, '2026-03-29 07:00:00', 1),  -- id=6
(2, 'J3_r2_10pass_MATIN',  10, '2026-03-29 07:00:00', 1),  -- id=7
(2, 'J3_r3_12pass_MATIN',  12, '2026-03-29 07:00:00', 1),  -- id=8 (depart CARLTON)
-- Restes prioritaires (arrivent APRES debut fenetre 1)
(2, 'J3_r4_9pass_RESTE',    9, '2026-03-29 07:30:00', 1),  -- id=9
(2, 'J3_r5_5pass_RESTE',    5, '2026-03-29 07:45:00', 1),  -- id=10
-- Nouvelles arrivees dans fenetre d'attente
(2, 'J3_r6_7pass',          7, '2026-03-29 08:15:00', 1),  -- id=11
(2, 'J3_r7_8pass',          8, '2026-03-29 08:20:00', 1);  -- id=12

-- ====================================================================
-- JOUR 4: 30/03/2026 - DISPONIBILITE HORAIRE (heure_disponible_debut)
-- ====================================================================
-- Scenario: v4 disponible seulement a partir de 10:30
--
-- 10:00 - r1(4) arrive:
--   v4 NON disponible (10:00 < 10:30)
--   -> v1(10) choisie (CLOSEST FIT parmi v1, v2, v3)
--
-- 10:35 - r2(6) arrive:
--   v4 DISPONIBLE (10:35 >= 10:30)
--   -> v4(8) choisie (ecart=2 < ecart v2=4)
--
-- RESULTAT ATTENDU:
--   v1: r1(4) -> 10:00
--   v4: r2(6) -> 10:35 (premiere utilisation v4)

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(2, 'J4_r1_4pass_AVANT_V4', 4, '2026-03-30 10:00:00', 1),  -- id=13 (v4 pas dispo)
(2, 'J4_r2_6pass_APRES_V4', 6, '2026-03-30 10:35:00', 1);  -- id=14 (v4 dispo)

-- ====================================================================
-- JOUR 5: 31/03/2026 - GESTION DES RESTES (Division en 3 parties)
-- ====================================================================
-- Scenario: Grande reservation divisee sur plusieurs vehicules
--
-- 08:00 - r1(10), r2(12) arrivent:
--   -> v1 prend r1(10), v3 prend r2(12)
--   -> Retours: v1 a 09:00, v3 a 09:12 (COLBERT)
--
-- 08:30 - r3(25) arrive:
--   -> Seul v2(10) disponible
--   -> v2 prend 10 de r3, reste 15
--   -> Attendre retour v1 a 09:00
--
-- 09:00 - v1 retourne:
--   -> v1 prend 10 de r3_reste, reste 5
--   -> Attendre retour v3 a 09:12
--
-- 09:12 - v3 retourne:
--   -> v3 prend 5 de r3_reste
--   -> r3 completement assignee
--
-- RESULTAT ATTENDU:
--   v1: r1(10) -> 08:00
--   v3: r2(12) -> 08:00
--   v2: r3_partie1(10) -> 08:30
--   v1: r3_partie2(10) -> 09:00
--   v3: r3_partie3(5) -> 09:12

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- Trajets qui bloquent v1 et v3
(2, 'J5_r1_10pass_BLOQUE_V1', 10, '2026-03-31 08:00:00', 1),  -- id=15
(3, 'J5_r2_12pass_BLOQUE_V3', 12, '2026-03-31 08:00:00', 1),  -- id=16 (depart COLBERT)
-- Grande reservation divisee en 3
(2, 'J5_r3_25pass_GRANDE',   25, '2026-03-31 08:30:00', 1);   -- id=17

-- ====================================================================
-- JOUR 6: 01/04/2026 - CAS VEHICULE + RESERVATION MEME HEURE
-- ====================================================================
-- Scenario: v4 devient disponible au meme moment qu'une reservation arrive
--
-- 10:30 - r1(8) arrive ET v4 devient disponible:
--   CLOSEST FIT:
--     v1(10): |10-8| = 2
--     v4(8): |8-8| = 0 (PARFAIT)
--   -> v4 prend r1(8) = PLEIN
--   -> Pas de fenetre (vehicule rempli immediatement)
--
-- RESULTAT ATTENDU:
--   v4: r1(8) -> 10:30

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(2, 'J6_r1_8pass', 8, '2026-04-01 10:30:00', 1);  -- id=18

-- ==========================================
-- RESET SEQUENCE
-- ==========================================
SELECT setval('reservation_id_seq', (SELECT MAX(id) FROM reservation));
SELECT setval('vehicule_id_seq', (SELECT MAX(id) FROM vehicule));
SELECT setval('lieu_id_seq', (SELECT MAX(id) FROM lieu));

-- ==========================================
-- AFFICHAGE RESUME DES DONNEES
-- ==========================================

SELECT '========================================' as info;
SELECT 'SPRINT 8 - SIMULATION COMPLETE' as titre;
SELECT '========================================' as info;

SELECT '--- CONFIGURATION VEHICULES ---' as section;
SELECT
    id,
    reference,
    nb_place as places,
    type_carburant as carburant,
    COALESCE(heure_disponible_debut::text, 'Toujours') as disponibilite
FROM vehicule ORDER BY id;

SELECT '--- PARAMETRES ---' as section;
SELECT key, value FROM parameters;

SELECT '--- RESERVATIONS PAR JOUR ---' as section;

SELECT '>> JOUR 1 (27/03) - Regroupement Optimal' as jour;
SELECT id, customer_id, passenger_nbr as pass, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-03-27' ORDER BY arrival_date;

SELECT '>> JOUR 2 (28/03) - Division Optimale' as jour;
SELECT id, customer_id, passenger_nbr as pass, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-03-28' ORDER BY arrival_date;

SELECT '>> JOUR 3 (29/03) - Retour + Fenetre' as jour;
SELECT id, customer_id, passenger_nbr as pass, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-03-29' ORDER BY arrival_date;

SELECT '>> JOUR 4 (30/03) - Disponibilite v4' as jour;
SELECT id, customer_id, passenger_nbr as pass, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-03-30' ORDER BY arrival_date;

SELECT '>> JOUR 5 (31/03) - Division 3 parties' as jour;
SELECT id, customer_id, passenger_nbr as pass, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-03-31' ORDER BY arrival_date;

SELECT '>> JOUR 6 (01/04) - Meme heure' as jour;
SELECT id, customer_id, passenger_nbr as pass, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-04-01' ORDER BY arrival_date;

SELECT '========================================' as info;
SELECT 'RESUME GLOBAL' as titre;
SELECT '========================================' as info;

SELECT
    'Total Reservations: ' || COUNT(*)::text as stat
FROM reservation;

SELECT
    'Total Passagers: ' || SUM(passenger_nbr)::text as stat
FROM reservation;

SELECT '========================================' as info;
SELECT 'WORKFLOW DE TEST:' as workflow;
SELECT '  1. GET /api/planning/auto?date=2026-03-27' as step1;
SELECT '  2. GET /api/planning/auto?date=2026-03-28' as step2;
SELECT '  3. GET /api/planning/auto?date=2026-03-29' as step3;
SELECT '  4. GET /api/planning/auto?date=2026-03-30' as step4;
SELECT '  5. GET /api/planning/auto?date=2026-03-31' as step5;
SELECT '  6. GET /api/planning/auto?date=2026-04-01' as step6;
SELECT '========================================' as info;

-- ==========================================
-- REQUETES DE VERIFICATION
-- ==========================================

/*
========== APRES CHAQUE JOUR, EXECUTER: ==========

-- A. Toutes les attributions du jour
SELECT
    a.id,
    v.reference as vehicule,
    r.customer_id,
    a.nb_passagers_assignes as passagers,
    a.date_heure_depart::time as depart,
    a.date_heure_retour::time as retour
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
WHERE a.date_heure_depart::date = '2026-03-27'  -- Changer la date
ORDER BY a.date_heure_depart;

-- B. Resume par reservation
SELECT
    r.id,
    r.customer_id,
    r.passenger_nbr as demande,
    COALESCE(SUM(a.nb_passagers_assignes), 0)::int as assigne,
    (r.passenger_nbr - COALESCE(SUM(a.nb_passagers_assignes), 0))::int as reste,
    CASE
        WHEN r.passenger_nbr = COALESCE(SUM(a.nb_passagers_assignes), 0) THEN 'COMPLET'
        WHEN COALESCE(SUM(a.nb_passagers_assignes), 0) > 0 THEN 'PARTIEL'
        ELSE 'NON ASSIGNE'
    END as statut
FROM reservation r
LEFT JOIN attribution a ON r.id = a.reservation_id
WHERE r.arrival_date::date = '2026-03-27'  -- Changer la date
GROUP BY r.id, r.customer_id, r.passenger_nbr
ORDER BY r.arrival_date;

-- C. Verification v4 disponibilite
SELECT
    v.reference,
    v.heure_disponible_debut,
    a.date_heure_depart::time as depart,
    CASE
        WHEN v.heure_disponible_debut IS NULL THEN 'TOUJOURS OK'
        WHEN a.date_heure_depart::time >= v.heure_disponible_debut THEN 'OK'
        ELSE 'ERREUR - Depart avant disponibilite!'
    END as verification
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
WHERE v.reference = 'v4';

-- D. Utilisation des vehicules
SELECT
    v.reference,
    v.nb_place,
    COUNT(DISTINCT a.id) as nb_trajets,
    SUM(a.nb_passagers_assignes) as total_passagers
FROM vehicule v
LEFT JOIN attribution a ON v.id = a.vehicule_id
GROUP BY v.id, v.reference, v.nb_place
ORDER BY v.id;

-- E. Validation CLOSEST FIT (verifier les ecarts)
SELECT
    r.customer_id,
    v.reference,
    r.passenger_nbr,
    v.nb_place,
    ABS(v.nb_place - r.passenger_nbr) as ecart,
    a.nb_passagers_assignes
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
ORDER BY a.date_heure_depart, ecart;

*/

-- ==========================================
-- FIN INITIALISATION
-- ==========================================
SELECT '========================================' as info;
SELECT 'PRET POUR TEST - 6 jours, 18 reservations' as status;
SELECT '========================================' as info;
