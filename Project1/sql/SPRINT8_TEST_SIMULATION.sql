-- ================================================================================
-- SPRINT 8 - DONNÉES DE TEST COMPLÈTES POUR TOUS LES SCÉNARIOS
-- ================================================================================
-- Auteur: ETU Test Suite
-- Date: 2026-04-03
--
-- OBJECTIF: Tester tous les 6 scénarios de simulation avec données réalistes
-- Structure: 6 jours de test (27-03 à 01-04) avec 52 réservations totales
-- ================================================================================

-- Fermer les connexions actives
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'hotel_reservation' AND pid <> pg_backend_pid();

-- Supprimer et recréer la base
DROP DATABASE IF EXISTS hotel_reservation;
CREATE DATABASE hotel_reservation;

\c hotel_reservation

-- ==========================================
-- 1. NETTOYAGE - CRÉER TYPE ENUM
-- ==========================================
CREATE TYPE type_carburant_enum AS ENUM ('D', 'Es', 'H', 'El');

-- ==========================================
-- 2. CRÉATION DES TABLES
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
-- 3. INDEX
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
-- 4. PARAMETRES
-- ==========================================
INSERT INTO parameters (key, value) VALUES
('vitesse_moyenne', '50'),    -- 50 km/h
('temps_attente', '30');      -- 30 minutes fenetre d'attente

-- ==========================================
-- 5. LIEUX
-- ==========================================
INSERT INTO lieu (code, libelle, initial) VALUES
('IVATO', 'Aeroport Ivato', 'A'),       -- id = 1
('CARLTON', 'Hotel Carlton', 'B'),      -- id = 2
('COLBERT', 'Hotel Colbert', 'C');      -- id = 3

-- ==========================================
-- 6. DISTANCES (bidirectionnelles)
-- ==========================================
INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(1, 2, 25.00), (1, 3, 30.00),  -- Depuis IVATO
(2, 1, 25.00), (2, 3, 10.00),  -- Depuis CARLTON
(3, 1, 30.00), (3, 2, 10.00);  -- Depuis COLBERT

-- ==========================================
-- 7. VEHICULES (Sprint 8)
-- ==========================================
INSERT INTO vehicule (reference, nb_place, type_carburant, heure_disponible_debut) VALUES
('v1', 10, 'D',  NULL),        -- id = 1, Diesel, toujours disponible
('v2', 10, 'Es', NULL),        -- id = 2, Essence, toujours disponible
('v3', 12, 'D',  NULL),        -- id = 3, Diesel, toujours disponible
('v4', 8,  'H',  '10:30:00');  -- id = 4, Hybride, dès 10:30

-- ==========================================
-- ==========================================
-- RESERVATIONS PAR JOUR DE TEST
-- ==========================================
-- ==========================================

-- ====================================================================
-- JOUR 1: 27/03/2026 - SCÉNARIO 1 REGROUPEMENT OPTIMAL
-- ====================================================================
-- Description: Fenêtre [07:40 - 08:10], 4 réservations
-- Résultat attendu: r1→v1+r4(1), r2→v2+r3+r4(1), v3,v4 non utilisés
--
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(2, 'J1_r1_9pass',   9, '2026-03-27 08:00:00', 1),  -- id=1: r1
(2, 'J1_r2_5pass',   5, '2026-03-27 07:55:00', 1),  -- id=2: r2
(2, 'J1_r3_3pass',   3, '2026-03-27 07:50:00', 1),  -- id=3: r3
(2, 'J1_r4_2pass',   2, '2026-03-27 07:40:00', 1);  -- id=4: r4

-- ====================================================================
-- JOUR 2: 28/03/2026 - SCÉNARIO 2 DIVISION OPTIMALE
-- ====================================================================
-- Description: 1 réservation 20 passagers → division sur 2 véhicules
-- Résultat attendu: r1→v3(12)+v1(8)
--
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(2, 'J2_r1_20pass', 20, '2026-03-28 09:00:00', 1);  -- id=5: 20 passagers (division)

-- ====================================================================
-- JOUR 3: 29/03/2026 - SCÉNARIO 3 RETOUR VEHICULE + FENETRE ATTENTE
-- ====================================================================
-- Description: Trajets matinaux + retours + fenêtres dynamiques
-- Résultat attendu: Multiples fenêtres avec regroupements complexes
--
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- Trajet matinal pour occuper les véhicules
(2, 'J3_r1_10pass_MATIN',  10, '2026-03-29 07:00:00', 1),  -- id=6: v1 occupe
(2, 'J3_r2_10pass_MATIN',  10, '2026-03-29 07:00:00', 1),  -- id=7: v2 occupe (retour 09:00->COLBERT)
(3, 'J3_r3_12pass_MATIN',  12, '2026-03-29 07:00:00', 1),  -- id=8: v3 occupe (depart COLBERT)
-- Restes en attente (arrivent avant les retours)
(2, 'J3_r4_9pass_RESTE',    9, '2026-03-29 07:30:00', 1),  -- id=9: reste prioritaire
(2, 'J3_r5_5pass_RESTE',    5, '2026-03-29 07:45:00', 1),  -- id=10: reste prioritaire
-- Nouvelles arrivées dans fenêtres d'attente
(2, 'J3_r6_7pass',          7, '2026-03-29 08:15:00', 1),  -- id=11: dans fenetre
(2, 'J3_r7_8pass',          8, '2026-03-29 08:20:00', 1);  -- id=12: dans fenetre

-- ====================================================================
-- JOUR 4: 30/03/2026 - SCÉNARIO 4 DISPONIBILITE HORAIRE (v4)
-- ====================================================================
-- Description: v4 disponible uniquement à partir de 10:30
-- Résultat attendu: r1→v1(avant 10:30), r2→v4(après 10:30)
--
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(2, 'J4_r1_4pass_AVANT_V4', 4, '2026-03-30 10:00:00', 1),  -- id=13: avant 10:30
(2, 'J4_r2_6pass_APRES_V4', 6, '2026-03-30 10:35:00', 1);  -- id=14: apres 10:30

-- ====================================================================
-- JOUR 5: 31/03/2026 - SCÉNARIO 5 GESTION DES RESTES
-- ====================================================================
-- Description: Grande réservation divisée en 3 parties
-- Résultat attendu: r17→v1(10)+v2(10)+v4(5)
--
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- Trajets pour bloquer v2 et v3
(2, 'J5_r1_10pass_BLOQUE_V2', 10, '2026-03-31 08:00:00', 1),  -- id=15: v2 occupe
(3, 'J5_r2_12pass_BLOQUE_V3', 12, '2026-03-31 08:00:00', 1),  -- id=16: v3 occupe (COLBERT)
-- Grande réservation (division sur 3 véhicules)
(2, 'J5_r3_25pass_GRANDE',   25, '2026-03-31 08:30:00', 1);   -- id=17: division 3 parties

-- ====================================================================
-- JOUR 6: 01/04/2026 - SCÉNARIO 6 CAS COMPLEXE (8 RESERVATIONS)
-- ====================================================================
-- Description: 8 réservations sur 4 fenêtres complexes
-- Total: 52 passagers, 4-5 trajets de véhicules
--
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- Matin (occupent v1, v2, v3)
(2, 'J6_r1_10pass',   10, '2026-04-01 07:00:00', 1),  -- id=18
(2, 'J6_r2_10pass',   10, '2026-04-01 07:05:00', 1),  -- id=19
(2, 'J6_r3_8pass',     8, '2026-04-01 07:30:00', 1),  -- id=20
-- Attente et retours
(2, 'J6_r4_9pass',     9, '2026-04-01 07:45:00', 1),  -- id=21
(2, 'J6_r5_4pass',     4, '2026-04-01 08:15:00', 1),  -- id=22
(2, 'J6_r6_6pass',     6, '2026-04-01 08:20:00', 1),  -- id=23
-- Fin matin/Midi
(2, 'J6_r7_3pass',     3, '2026-04-01 08:50:00', 1),  -- id=24
(2, 'J6_r8_2pass',     2, '2026-04-01 09:10:00', 1);  -- id=25

-- ==========================================
-- RESET SEQUENCE
-- ==========================================
SELECT setval('reservation_id_seq', (SELECT MAX(id) FROM reservation));
SELECT setval('vehicule_id_seq', (SELECT MAX(id) FROM vehicule));
SELECT setval('lieu_id_seq', (SELECT MAX(id) FROM lieu));

-- ==========================================
-- AFFICHAGE RÉSUMÉ DES DONNÉES
-- ==========================================

SELECT '========================================' as info;
SELECT 'SPRINT 8 - DONNÉES DE TEST COMPLÈTES' as titre;
SELECT '========================================' as info;

SELECT '--- CONFIGURATION ---' as section;
SELECT '4 Véhicules:' as data;
SELECT
  '  - v1: 10 places, Diesel (toujours)'  UNION ALL
SELECT
  '  - v2: 10 places, Essence (toujours)' UNION ALL
SELECT
  '  - v3: 12 places, Diesel (toujours)' UNION ALL
SELECT
  '  - v4: 8 places, Hybride (dès 10:30)' as vehicule;

SELECT '--- RÉSERVATIONS PAR JOUR ---' as section;

SELECT '>>> JOUR 1 (27/03) - Scénario 1: Regroupement Optimal' as jour;
SELECT COUNT(*) as nb_reservations, SUM(passenger_nbr) as total_passagers
FROM reservation WHERE arrival_date::date = '2026-03-27';
SELECT customer_id, passenger_nbr, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-03-27' ORDER BY arrival_date;

SELECT '>>> JOUR 2 (28/03) - Scénario 2: Division Optimale' as jour;
SELECT COUNT(*) as nb_reservations, SUM(passenger_nbr) as total_passagers
FROM reservation WHERE arrival_date::date = '2026-03-28';
SELECT customer_id, passenger_nbr, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-03-28' ORDER BY arrival_date;

SELECT '>>> JOUR 3 (29/03) - Scénario 3: Retour Véhicule + Fenêtre' as jour;
SELECT COUNT(*) as nb_reservations, SUM(passenger_nbr) as total_passagers
FROM reservation WHERE arrival_date::date = '2026-03-29';
SELECT customer_id, passenger_nbr, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-03-29' ORDER BY arrival_date;

SELECT '>>> JOUR 4 (30/03) - Scénario 4: Disponibilité Horaire (v4)' as jour;
SELECT COUNT(*) as nb_reservations, SUM(passenger_nbr) as total_passagers
FROM reservation WHERE arrival_date::date = '2026-03-30';
SELECT customer_id, passenger_nbr, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-03-30' ORDER BY arrival_date;

SELECT '>>> JOUR 5 (31/03) - Scénario 5: Gestion des Restes' as jour;
SELECT COUNT(*) as nb_reservations, SUM(passenger_nbr) as total_passagers
FROM reservation WHERE arrival_date::date = '2026-03-31';
SELECT customer_id, passenger_nbr, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-03-31' ORDER BY arrival_date;

SELECT '>>> JOUR 6 (01/04) - Scénario 6: Cas Complexe (8 réservations)' as jour;
SELECT COUNT(*) as nb_reservations, SUM(passenger_nbr) as total_passagers
FROM reservation WHERE arrival_date::date = '2026-04-01';
SELECT customer_id, passenger_nbr, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-04-01' ORDER BY arrival_date;

SELECT '========================================' as info;
SELECT 'RÉSUMÉ GLOBAL' as titre;
SELECT '========================================' as info;
SELECT COUNT(*) as total_reservations, SUM(passenger_nbr) as total_passagers
FROM reservation;

-- ==========================================
-- REQUÊTES DE VÉRIFICATION (À EXÉCUTER APRÈS TESTS)
-- ==========================================

/*
========== APRÈS AVOIR GÉNÉRÉ LE PLANNING ==========

-- 1. VOIR TOUTES LES ATTRIBUTIONS
SELECT
    a.id,
    v.reference as vehicule,
    r.customer_id,
    a.nb_passagers_assignes as passagers,
    a.date_heure_depart::date as jour,
    a.date_heure_depart::time as depart,
    a.date_heure_retour::time as retour,
    (a.date_heure_retour - a.date_heure_depart) as duree
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
ORDER BY a.date_heure_depart, v.id;

-- 2. RÉSUMÉ PAR RESERVATION
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

-- 3. ATTRIBUTIONS PAR JOUR
SELECT
    a.date_heure_depart::date as jour,
    COUNT(*) as nb_attributions,
    SUM(a.nb_passagers_assignes) as total_passagers
FROM attribution a
GROUP BY a.date_heure_depart::date
ORDER BY jour;

-- 4. VÉRIFICATION DISPONIBILITÉ V4
SELECT
    v.reference,
    v.heure_disponible_debut,
    a.date_heure_depart::time as depart,
    CASE
        WHEN a.date_heure_depart::time >= v.heure_disponible_debut THEN 'OK'
        ELSE 'ERREUR: Depart avant disponibilite!'
    END as verification
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
WHERE v.reference = 'v4';

-- 5. UTILISATION VÉHICULES
SELECT
    v.reference,
    COUNT(DISTINCT a.id) as nb_trajets,
    SUM(a.nb_passagers_assignes) as total_passagers
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
GROUP BY v.reference
ORDER BY v.id;

-- 6. CLOSEST FIT VALIDATION (écarts)
SELECT
    r.customer_id,
    v.reference,
    r.passenger_nbr,
    v.nb_place,
    (v.nb_place - r.passenger_nbr) as ecart_check,
    a.nb_passagers_assignes
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
WHERE r.passenger_nbr <= v.nb_place
ORDER BY a.date_heure_depart;

*/

-- ==========================================
-- INITIALISATION COMPLÉTÉE
-- ==========================================
SELECT '========================================' as info;
SELECT 'PRÊT POUR TEST - 6 Scénarios avec 25 réservations' as status;
SELECT 'Exécutez: GET /planning/auto?date=2026-03-27' as etape1;
SELECT 'Puis: GET /planning/auto?date=2026-03-28' as etape2;
SELECT '... jusqu à 2026-04-01' as etape_final;
SELECT '========================================' as info;
