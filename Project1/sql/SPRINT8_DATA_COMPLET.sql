-- ================================================================================
-- SPRINT 8 - DONNEES DE SIMULATION COMPLETE (SANS ATTRIBUTIONS PRE-EXISTANTES)
-- ================================================================================
-- Auteur: ETU003240
-- Date: 2026-04-01
--
-- CONCEPT: Les reservations sont reparties sur 5 jours (27-31 Mars 2026)
-- AUCUNE attribution n'est inseree manuellement.
-- Le systeme calcule les attributions progressivement:
--   - Jour 1: Planning calcule les attributions initiales
--   - Jour 2+: Les attributions du jour precedent deviennent les "pre-existantes"
--
-- WORKFLOW:
--   1. Executer ce script UNE FOIS pour initialiser
--   2. GET /api/planning/auto?date=2026-03-27 (Jour 1)
--   3. GET /api/planning/auto?date=2026-03-28 (Jour 2 - utilise attributions Jour 1)
--   4. ... ainsi de suite
-- ================================================================================

-- Fermer les connexions actives
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'hotel_reservation' AND pid <> pg_backend_pid();

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
DROP TABLE IF EXISTS hotel CASCADE;
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
-- CARLTON -> IVATO: 25km = 30min aller + 30min retour = 60min total
-- COLBERT -> IVATO: 30km = 36min aller + 36min retour = 72min total (arrondi)

INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(1, 2, 25.00), (1, 3, 30.00),  -- Depuis IVATO
(2, 1, 25.00), (2, 3, 10.00),  -- Depuis CARLTON
(3, 1, 30.00), (3, 2, 10.00);  -- Depuis COLBERT

-- ==========================================
-- 8. VEHICULES (Sprint 8)
-- ==========================================
-- v1: 10 places, Diesel, toujours disponible
-- v2: 10 places, Essence, toujours disponible
-- v3: 12 places, Diesel, toujours disponible
-- v4: 8 places, Hybride, disponible a partir de 10:30 seulement

INSERT INTO vehicule (reference, nb_place, type_carburant, heure_disponible_debut) VALUES
('v1', 10, 'D',  NULL),
('v2', 10, 'Es', NULL),
('v3', 12, 'D',  NULL),
('v4', 8,  'H',  '10:30:00');

-- ==========================================
-- ==========================================
-- RESERVATIONS JOUR PAR JOUR
-- ==========================================
-- ==========================================

-- ====================================================================
-- JOUR 1: 27/03/2026 - REGROUPEMENT OPTIMAL (Closest Fit)
-- ====================================================================
-- Scenario: Tester le CYCLE DE REGROUPEMENT avec CLOSEST FIT
-- Vehicules tous disponibles immediatement (pas d'attributions pre-existantes)
--
-- IMPORTANT: Toutes les reservations arrivent dans une SEULE fenetre de 30 min
-- Fenetre: [07:40 - 08:10] commence avec r4 a 07:40
--
-- CALCUL DE L'HEURE DE DEPART:
-- heure_depart = MAX(arrival_date) = 08:00 (r1)
-- VALIDATION: r1 doit avoir au moins 1 partie assignee pour valider 08:00
--
-- LOGIQUE - CYCLE DE REGROUPEMENT:
--
-- ETAPE 1: Tri DESC: r1(9) > r2(5) > r3(3) > r4(2)
-- Traiter r1(9) - LE MAXIMUM:
--   Selection vehicule (CLOSEST FIT parmi ceux qui peuvent contenir 9):
--   - v1(10): |10-9| = 1 (MINIMUM, diesel prioritaire)
--   -> v1 prend r1(9), reste 1 place
--   -> r1 assignee → heure_depart = 08:00 VALIDEE pour v1
--
--   Regroupement v1 (1 place) - CLOSEST FIT:
--   - r4(2): |1-2| = 1 (MINIMUM)
--   -> v1 prend 1 de r4 = 10 PLEIN
--   -> v1 depart 08:00, retour 09:00
--   -> r4 RESTE 1 passager
--
-- ETAPE 1bis: Cycle pour r4_reste(1):
--   Chercher vehicule avec nb_places le plus proche de 1:
--   - v2(10): |10-1| = 9 (MINIMUM parmi disponibles)
--   -> v2 prend r4_reste(1), reste 9 places
--   -> r4 assignee → heure_depart = 08:00 VALIDEE pour v2
--
--   Regroupement v2 (9 places) - CLOSEST FIT:
--   - r2(5): |9-5| = 4 (MINIMUM)
--   -> v2 prend r2(5), reste 4 places
--
--   Regroupement v2 (4 places) - CLOSEST FIT:
--   - r3(3): |4-3| = 1 (MINIMUM)
--   -> v2 prend r3(3), reste 1 place
--   -> Plus de reservations disponibles
--   -> v2 total = r4_reste(1) + r2(5) + r3(3) = 9
--
-- ETAPE 2: r2, r3, r4 deja assignes dans le cycle → FIN
--
-- RESULTAT JOUR 1:
-- v1: r1(9) + r4(1) = 10 passagers -> depart 08:00, retour 09:00
-- v2: r4(1) + r2(5) + r3(3) = 9 passagers -> depart 08:00, retour 09:00

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- IMPORTANT: Toutes dans fenetre [07:40 - 08:10]
(2, 'J1_r1_9pass',   9, '2026-03-27 08:00:00', 1),  -- id=1: MAX arrival
(2, 'J1_r2_5pass',   5, '2026-03-27 07:55:00', 1),  -- id=2
(2, 'J1_r3_3pass',   3, '2026-03-27 07:50:00', 1),  -- id=3
(2, 'J1_r4_2pass',   2, '2026-03-27 07:40:00', 1);  -- id=4: Debut fenetre

-- ====================================================================
-- JOUR 2: 28/03/2026 - DIVISION OPTIMALE
-- ====================================================================
-- Scenario: Une grande reservation necessite plusieurs vehicules
-- PRE-REQUIS: Attributions du Jour 1 doivent exister
--   -> v1 et v2 sont retournes a 09:00 le 27/03
--   -> Le 28/03, tous vehicules disponibles des le matin
--
-- LOGIQUE ATTENDUE:
-- 09:00 - r1(20 pass) arrive:
--   - Division necessaire (20 > 12 max)
--   - v3(12pl): ecart=|12-20|=8 (OPTIMAL)
--   - v1(10pl): ecart=|10-20|=10
--   - v2(10pl): ecart=|10-20|=10
--   - v3 choisie -> assigne 12, reste 8
--
--   - Iteration 2: 8 passagers restants
--   - v1(10pl): ecart=|10-8|=2
--   - v2(10pl): ecart=|10-8|=2 (egale, v1 ou v2)
--   - v1 choisie -> assigne 8
--
-- RESULTAT JOUR 2:
-- v3: r1_partie1(12) -> depart 09:00, retour 10:00
-- v1: r1_partie2(8) -> depart 09:00, retour 10:00
-- v2, v4: non utilises

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(2, 'J2_r1_20pass', 20, '2026-03-28 09:00:00', 1);  -- id=5: 20 passagers (division)

-- ====================================================================
-- JOUR 3: 29/03/2026 - RETOUR VEHICULE + FENETRE D'ATTENTE (CAS PRINCIPAL)
-- ====================================================================
-- Scenario: Vehicules en course reviennent, ouvrent des fenetres d'attente
--
-- PRE-REQUIS: On simule des trajets matinaux qui bloquent les vehicules
-- Pour ce scenario, on ajoute des reservations tres tot (07:00) qui vont
-- occuper v1, v2, v3 le matin
--
-- STRUCTURE DU JOUR 3:
-- 07:00 - r1(10), r2(10), r3(12) arrivent -> v1, v2, v3 partent immediatement
--   - v1: part 07:00, retour 08:00 (CARLTON->IVATO: 60min)
--   - v2: part 07:00, retour 08:00
--   - v3: part 07:00, retour 08:00
--
-- 08:00 - v1, v2, v3 reviennent (FENETRES [08:00-08:30])
--   - r4(9 pass) arrive 07:30 (RESTE non assigne - prioritaire)
--   - r5(5 pass) arrive 07:45 (RESTE non assigne - prioritaire)
--
--   v1(10pl) revient, CLOSEST FIT parmi restes:
--     - r4(9): ecart=|10-9|=1 (OPTIMAL)
--     - r5(5): ecart=|10-5|=5
--   -> v1 prend r4(9), reste 1 place
--   -> Regroupement: r5(5)? ecart=|1-5|=4 -> prend 1 de r5
--   -> v1 = r4(9) + r5(1) = 10 PLEIN, part 08:00, retour 09:00
--
--   v2(10pl) revient:
--     - r5_reste(4): ecart=|10-4|=6
--   -> v2 prend r5(4), reste 6 places
--   -> Fenetre ouverte [08:00-08:30], attend r6(7) qui arrive 08:15
--
-- 08:15 - r6(7 pass) arrive dans fenetre v2:
--   - v2 a 6 places, r6(7): ecart=|6-7|=1
--   -> v2 prend 6 de r6, PLEIN, part 08:15, retour 09:15
--   -> r6_reste(1) non assigne
--
-- 08:00 - v3(12pl) revient:
--   -> Pas de reservation compatible immediatement
--   -> Fenetre [08:00-08:30], attend r7(8) qui arrive 08:20
--
-- 08:20 - r7(8 pass) arrive:
--   - v3(12pl): ecart=|12-8|=4
--   -> v3 prend r7(8) + r6_reste(1) = 9, part 08:20, retour 09:20
--
-- RESULTAT JOUR 3:
-- v1: r4(9) + r5(1) = 10 -> depart 08:00, retour 09:00
-- v2: r5(4) + r6(6) = 10 -> depart 08:15, retour 09:15
-- v3: r1(10) puis r7(8) + r6(1) = 9 -> deux trajets

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- Trajet matinal pour occuper les vehicules
(2, 'J3_r1_10pass_MATIN',  10, '2026-03-29 07:00:00', 1),  -- id=6: v1 occupe
(2, 'J3_r2_10pass_MATIN',  10, '2026-03-29 07:00:00', 1),  -- id=7: v2 occupe
(3, 'J3_r3_12pass_MATIN',  12, '2026-03-29 07:00:00', 1),  -- id=8: v3 occupe (depart COLBERT)

-- Restes (arrivent AVANT retour vehicules - PRIORITAIRES)
(2, 'J3_r4_9pass_RESTE',    9, '2026-03-29 07:30:00', 1),  -- id=9: reste prioritaire
(2, 'J3_r5_5pass_RESTE',    5, '2026-03-29 07:45:00', 1),  -- id=10: reste prioritaire

-- Nouvelles arrivees (dans fenetres d'attente)
(2, 'J3_r6_7pass',          7, '2026-03-29 08:15:00', 1),  -- id=11: fenetre v2
(2, 'J3_r7_8pass',          8, '2026-03-29 08:20:00', 1);  -- id=12: fenetre v3

-- ====================================================================
-- JOUR 4: 30/03/2026 - DISPONIBILITE HORAIRE (heure_disponible_debut)
-- ====================================================================
-- Scenario: v4 est disponible seulement a partir de 10:30
--
-- LOGIQUE ATTENDUE:
-- 10:00 - r1(4 pass) arrive:
--   - v4 NON disponible (heure_disponible_debut = 10:30)
--   - v1(10pl) disponible: ecart=|10-4|=6
--   -> v1 prend r1(4), part 10:00, retour 11:00
--
-- 10:35 - r2(6 pass) arrive:
--   - v4 DISPONIBLE maintenant (10:35 > 10:30)
--   - v4(8pl): ecart=|8-6|=2 (PLUS PROCHE)
--   - v2(10pl): ecart=|10-6|=4
--   -> v4 prend r2(6), part 10:35, retour 11:35
--
-- RESULTAT JOUR 4:
-- v1: r1(4) -> depart 10:00, retour 11:00
-- v4: r2(6) -> depart 10:35, retour 11:35 (premiere utilisation de v4)

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- Avant 10:30 (v4 pas encore dispo)
(2, 'J4_r1_4pass_AVANT_V4', 4, '2026-03-30 10:00:00', 1),  -- id=13
-- Apres 10:30 (v4 dispo)
(2, 'J4_r2_6pass_APRES_V4', 6, '2026-03-30 10:35:00', 1);  -- id=14

-- ====================================================================
-- JOUR 5: 31/03/2026 - GESTION DES RESTES (ReservationPartielle)
-- ====================================================================
-- Scenario: Capacite insuffisante, des passagers restent non assignes
--
-- PRE-REQUIS: On simule que v2 et v3 sont en course (indisponibles)
-- Pour cela, on ajoute des reservations qui les occupent
--
-- LOGIQUE ATTENDUE:
-- 08:00 - r1(10), r2(12) arrivent -> v2, v3 partent
--   - v2: part 08:00, retour 09:00
--   - v3: part 08:00, retour 09:00
--
-- 08:30 - r3(25 pass) arrive:
--   - Seul v1(10pl) disponible immediatement
--   - v1 prend 10 de r3, part 08:30, retour 09:30
--   - Reste: 15 passagers non assignes
--
--   - v4 non disponible (avant 10:30)
--   - v2, v3 reviennent a 09:00 mais r3 devrait deja etre traite
--
-- Si fenetre d'attente de v2/v3 (09:00-09:30):
--   - r3_reste(15) toujours en attente
--   - v2(10pl): prend 10 de r3_reste, reste 5
--   - v3(12pl): prend les 5 restants
--
-- RESULTAT JOUR 5: Tous les 25 passagers assignes sur 3 vehicules
-- v1: r3_partie1(10) -> depart 08:30, retour 09:30
-- v2: r3_partie2(10) -> depart 09:00, retour 10:00
-- v3: r3_partie3(5) -> depart 09:00, retour 10:00

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- Trajets pour bloquer v2 et v3
(2, 'J5_r1_10pass_BLOQUE_V2', 10, '2026-03-31 08:00:00', 1),  -- id=15: v2 occupe
(3, 'J5_r2_12pass_BLOQUE_V3', 12, '2026-03-31 08:00:00', 1),  -- id=16: v3 occupe

-- Grande reservation (necessite division + gestion des restes)
(2, 'J5_r3_25pass_GRANDE',   25, '2026-03-31 08:30:00', 1);   -- id=17: division sur 3 vehicules

-- ==========================================
-- RESET SEQUENCE
-- ==========================================
SELECT setval('reservation_id_seq', (SELECT MAX(id) FROM reservation));

-- ==========================================
-- AFFICHAGE DES DONNEES INSEREES
-- ==========================================

SELECT '========================================' as info;
SELECT 'SPRINT 8 - DONNEES DE SIMULATION' as titre;
SELECT '========================================' as info;

SELECT '--- VEHICULES ---' as section;
SELECT id, reference, nb_place,
       COALESCE(heure_disponible_debut::text, 'Toujours dispo') as disponibilite
FROM vehicule ORDER BY id;

SELECT '--- RESERVATIONS PAR JOUR ---' as section;

SELECT '>> JOUR 1 (27/03) - Regroupement Optimal' as jour;
SELECT id, customer_id, passenger_nbr, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-03-27' ORDER BY arrival_date;

SELECT '>> JOUR 2 (28/03) - Division Optimale' as jour;
SELECT id, customer_id, passenger_nbr, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-03-28' ORDER BY arrival_date;

SELECT '>> JOUR 3 (29/03) - Retour Vehicule + Fenetre' as jour;
SELECT id, customer_id, passenger_nbr, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-03-29' ORDER BY arrival_date;

SELECT '>> JOUR 4 (30/03) - Disponibilite Horaire' as jour;
SELECT id, customer_id, passenger_nbr, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-03-30' ORDER BY arrival_date;

SELECT '>> JOUR 5 (31/03) - Gestion des Restes' as jour;
SELECT id, customer_id, passenger_nbr, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-03-31' ORDER BY arrival_date;

SELECT '========================================' as info;
SELECT 'WORKFLOW:' as workflow;
SELECT '1. GET /api/planning/auto?date=2026-03-27' as etape1;
SELECT '2. GET /api/planning/auto?date=2026-03-28' as etape2;
SELECT '3. GET /api/planning/auto?date=2026-03-29' as etape3;
SELECT '4. GET /api/planning/auto?date=2026-03-30' as etape4;
SELECT '5. GET /api/planning/auto?date=2026-03-31' as etape5;
SELECT '========================================' as info;

-- ==========================================
-- REQUETES DE VERIFICATION (A EXECUTER APRES CHAQUE JOUR)
-- ==========================================

/*
-- Apres chaque appel API, verifier les attributions:

-- A. Voir toutes les attributions
SELECT
    a.id,
    v.reference as vehicule,
    r.customer_id,
    a.nb_passagers_assignes as passagers,
    a.date_heure_depart::time as depart,
    a.date_heure_retour::time as retour,
    a.statut
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
ORDER BY a.date_heure_depart;

-- B. Resume par reservation
SELECT
    r.id,
    r.customer_id,
    r.passenger_nbr as demande,
    COALESCE(SUM(a.nb_passagers_assignes), 0) as assigne,
    r.passenger_nbr - COALESCE(SUM(a.nb_passagers_assignes), 0) as reste,
    CASE
        WHEN r.passenger_nbr = COALESCE(SUM(a.nb_passagers_assignes), 0) THEN 'COMPLET'
        WHEN COALESCE(SUM(a.nb_passagers_assignes), 0) > 0 THEN 'PARTIEL'
        ELSE 'NON ASSIGNE'
    END as statut
FROM reservation r
LEFT JOIN attribution a ON r.id = a.reservation_id
GROUP BY r.id, r.customer_id, r.passenger_nbr
ORDER BY r.arrival_date;

-- C. Attributions par jour
SELECT
    a.date_heure_depart::date as jour,
    COUNT(*) as nb_attributions,
    SUM(a.nb_passagers_assignes) as total_passagers
FROM attribution a
GROUP BY a.date_heure_depart::date
ORDER BY jour;

-- D. Verification v4 (disponibilite horaire)
SELECT
    v.reference,
    a.date_heure_depart::time as depart,
    v.heure_disponible_debut,
    CASE
        WHEN a.date_heure_depart::time >= v.heure_disponible_debut THEN 'OK'
        ELSE 'ERREUR: Depart avant disponibilite!'
    END as verification
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
WHERE v.reference = 'v4';
*/
