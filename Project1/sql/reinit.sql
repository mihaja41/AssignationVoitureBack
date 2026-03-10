-- psql -U postgres -d postgres -f reinit.sql

-- Fermer toutes les connexions actives à la base
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'hotel_reservation' AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS hotel_reservation;
CREATE DATABASE hotel_reservation;

-- Se connecter à la nouvelle base
\c hotel_reservation

-- ==========================================
-- 1. NETTOYAGE (sécurité supplémentaire)
-- ==========================================

DROP TABLE IF EXISTS distance CASCADE;
DROP TABLE IF EXISTS reservation CASCADE;
DROP TABLE IF EXISTS vehicule CASCADE;
DROP TABLE IF EXISTS lieu CASCADE;
DROP TABLE IF EXISTS hotel CASCADE;
DROP TABLE IF EXISTS parameters CASCADE;
DROP TABLE IF EXISTS token CASCADE;

DROP TYPE IF EXISTS type_carburant_enum CASCADE;

-- ==========================================
-- 2. CRÉATION DU TYPE ENUM
-- ==========================================

CREATE TYPE type_carburant_enum AS ENUM ('D', 'Es', 'H', 'El');
-- D  = Diesel
-- Es = Essence
-- H  = Hybride
-- El = Électrique

-- ==========================================
-- 3. CRÉATION DES TABLES
-- ==========================================

-- Table TOKEN (authentification)
CREATE TABLE token (
    id SERIAL PRIMARY KEY,
    token_name TEXT NOT NULL UNIQUE,
    expire_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked BOOLEAN DEFAULT false
);

-- Table LIEU
CREATE TABLE lieu (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table VEHICULE
CREATE TABLE vehicule (
    id BIGSERIAL PRIMARY KEY,
    reference VARCHAR(100) NOT NULL,
    nb_place INT NOT NULL,
    type_carburant type_carburant_enum NOT NULL
);

-- Table RESERVATION
CREATE TABLE reservation (
    id BIGSERIAL PRIMARY KEY,
    lieu_depart_id BIGINT NOT NULL REFERENCES lieu(id) ON DELETE CASCADE,
    customer_id VARCHAR(100) NOT NULL,
    passenger_nbr INT NOT NULL,
    arrival_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lieu_destination_id BIGINT REFERENCES lieu(id) ON DELETE SET NULL
);

-- Table PARAMETERS
CREATE TABLE parameters (
    id SERIAL PRIMARY KEY,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Table DISTANCE
CREATE TABLE distance (
    id BIGSERIAL PRIMARY KEY,
    from_lieu_id BIGINT NOT NULL REFERENCES lieu(id) ON DELETE CASCADE,
    to_lieu_id BIGINT NOT NULL REFERENCES lieu(id) ON DELETE CASCADE,
    km_distance NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_distance_pair UNIQUE (from_lieu_id, to_lieu_id)
);

-- ==========================================
-- 4. CRÉATION DES INDEX
-- ==========================================

CREATE INDEX idx_reservation_lieu_destination ON reservation(lieu_destination_id);
CREATE INDEX idx_reservation_lieu_depart ON reservation(lieu_depart_id);
CREATE INDEX idx_reservation_arrival_date ON reservation(arrival_date);
CREATE INDEX idx_lieu_code ON lieu(code);
CREATE INDEX idx_distance_from_to ON distance(from_lieu_id, to_lieu_id);

-- ==========================================
-- 5. DONNÉES DE TEST — SPRINT 4 (REGROUPEMENT)
-- ==========================================
-- NB : Le lieu de départ est TOUJOURS l'aéroport (IVATO).
--       Il s'agit d'un RACCOMPAGNEMENT des clients depuis l'aéroport.

-- 5.1 LIEUX
-- id=1 Aéroport (TOUJOURS le point de départ)
-- id=2..8 Destinations
INSERT INTO lieu (code, libelle) VALUES
('IVATO',         'Aeroport Ivato'),               -- id = 1
('COLBERT',       'Hotel Colbert'),                 -- id = 2
('CARLTON',       'Hotel Carlton'),                 -- id = 3
('IBIS',          'Hotel Ibis'),                    -- id = 4
('NOSY_BE',       'Nosy Be'),                       -- id = 5
('SAINTE_MARIE',  'Sainte-Marie'),                  -- id = 6
('ANTSIRABE',     'Antsirabe'),                     -- id = 7
('MAHAJANGA',     'Mahajanga');                      -- id = 8

-- 5.2 DISTANCES (Aéroport IVATO vers chaque destination)
INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(1, 2,  20.00),   -- Ivato -> Colbert        20 km
(1, 3,  22.00),   -- Ivato -> Carlton        22 km
(1, 4,  18.00),   -- Ivato -> Ibis           18 km
(1, 5, 285.00),   -- Ivato -> Nosy Be       285 km
(1, 6, 200.00),   -- Ivato -> Sainte-Marie  200 km
(1, 7, 170.00),   -- Ivato -> Antsirabe     170 km
(1, 8, 380.00);   -- Ivato -> Mahajanga     380 km

-- 5.3 VÉHICULES
-- 2x 4 places (Diesel + Essence)  -> teste priorité Diesel en cas d'égalité
-- 2x 7 places (Diesel + Diesel)   -> teste random en cas d'égalité complète
-- 1x 5 places Électrique
-- 1x 8 places Hybride
-- 1x 2 places Essence (petit véhicule)
INSERT INTO vehicule (reference, nb_place, type_carburant) VALUES
('AV-001', 4,  'D'),    -- id=1  Diesel,      4 places
('AV-002', 4,  'Es'),   -- id=2  Essence,     4 places
('AV-003', 7,  'D'),    -- id=3  Diesel,      7 places
('AV-004', 7,  'D'),    -- id=4  Diesel,      7 places  (doublon -> random)
('AV-005', 5,  'El'),   -- id=5  Électrique,  5 places
('AV-006', 8,  'H'),    -- id=6  Hybride,     8 places
('AV-007', 2,  'Es');   -- id=7  Essence,     2 places

-- 5.4 PARAMÈTRES
INSERT INTO parameters (key, value) VALUES
('vitesse_moyenne', '60'),    -- 60 km/h
('temps_attente', '15');      -- 15 minutes


-- =====================================================================
-- 5.5 RÉSERVATIONS — Départ TOUJOURS depuis IVATO (id = 1)
-- =====================================================================
-- ═════════════════════════════════════════════════════════════════
-- DATE 2026-03-10  08:00 — SCÉNARIO A : REGROUPEMENT BASIQUE
-- 3 réservations, MÊME heure, MÊME départ (aéroport)
-- ═════════════════════════════════════════════════════════════════

-- R1 : 4 pass -> Carlton (22 km)
--   Tri décrois -> traité en 1er (4 est le max)
--   Véhicule 4 places : AV-001 (D) vs AV-002 (Es) -> Diesel gagne -> AV-001
--   Écart = 4-4 = 0 -> AUCUN regroupement possible
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id)
VALUES (1, 'CLI-A01', 4, '2026-03-10 08:00:00', 3);

-- R2 : 3 pass -> Colbert (20 km)
--   Traité en 2e -> véhicule 4 places AV-002 (Es) dispo
--   Écart = 4-3 = 1 -> 1 place restante -> cherche regroupement
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id)
VALUES (1, 'CLI-A02', 3, '2026-03-10 08:00:00', 2);

-- R3 : 1 pass -> Ibis (18 km)
--   Même heure + même départ + 1 pass <= 1 restante -> REGROUPÉ avec R2
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id)
VALUES (1, 'CLI-A03', 1, '2026-03-10 08:00:00', 4);

-- ATTENDU :
--   AV-001 (4pl, D)  -> [R1: 4 pass]             -> 0 restante
--   AV-002 (4pl, Es) -> [R2: 3 pass, R3: 1 pass] -> regroupement -> 0

-- ═════════════════════════════════════════════════════════════════
-- DATE 2026-03-10  10:00 — SCÉNARIO B : GROS GROUPE + RELIQUAT
-- ═════════════════════════════════════════════════════════════════

-- R4 : 6 pass -> Antsirabe (170 km)
--   Véhicule >= 6 : AV-003(7,D), AV-004(7,D), AV-006(8,H)
--   Min écart : 7-6=1 -> AV-003 vs AV-004 (même places + même carbu D) -> RANDOM
--   Place restante = 1
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id)
VALUES (1, 'CLI-B01', 6, '2026-03-10 10:00:00', 7);

-- R5 : 1 pass -> Nosy Be (285 km)
--   Même heure -> 1 pass <= 1 restante -> REGROUPÉ avec R4
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id)
VALUES (1, 'CLI-B02', 1, '2026-03-10 10:00:00', 5);

-- R6 : 2 pass -> Sainte-Marie (200 km)
--   Après R4+R5 = 0 restante -> nouveau véhicule
--   AV-007 (2, Es) -> écart 0 -> parfait
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id)
VALUES (1, 'CLI-B03', 2, '2026-03-10 10:00:00', 6);

-- ATTENDU :
--   AV-003 ou AV-004 (7pl, D) -> [R4: 6p, R5: 1p] -> regroupement -> 0
--   AV-007 (2pl, Es)          -> [R6: 2p]          -> 0

-- ═════════════════════════════════════════════════════════════════
-- DATE 2026-03-10  14:00 — SCÉNARIO C : CONFLIT HORAIRE
-- Véhicules partis à 10h pas encore revenus à 14h
--   R4: 10:00, Antsirabe 170km A/R=340km -> 340/60=5h40 -> retour ~15:40
--   -> CONFLIT avec départ 14:00
-- ═════════════════════════════════════════════════════════════════

-- R7 : 3 pass -> Mahajanga (380 km)
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id)
VALUES (1, 'CLI-C01', 3, '2026-03-10 14:00:00', 8);

-- R8 : 1 pass -> Colbert (20 km)
--   Même heure -> regroupable avec R7
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id)
VALUES (1, 'CLI-C02', 1, '2026-03-10 14:00:00', 2);

-- ATTENDU :
--   Véhicules de scénario B exclus (pas encore revenus)
--   AV-001 (4pl, D) -> [R7: 3p, R8: 1p] -> regroupement -> 0

-- ═════════════════════════════════════════════════════════════════
-- DATE 2026-03-10  18:00 — SCÉNARIO D : TROP DE PASSAGERS
-- ═════════════════════════════════════════════════════════════════

-- R9 : 10 pass -> Nosy Be
--   Max véhicule = 8 (AV-006) -> 10 > 8 -> NON ASSIGNÉ
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id)
VALUES (1, 'CLI-D01', 10, '2026-03-10 18:00:00', 5);

-- ═════════════════════════════════════════════════════════════════
-- DATE 2026-03-10  20:00 — SCÉNARIO E : PRIORITÉ DIESEL
-- ═════════════════════════════════════════════════════════════════

-- R10 : 4 pass -> Ibis (18 km)
--   AV-001 (D) et AV-002 (Es) tous revenus -> même écart 0 -> Diesel gagne
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id)
VALUES (1, 'CLI-E01', 4, '2026-03-10 20:00:00', 4);

-- ═════════════════════════════════════════════════════════════════
-- DATE 2026-03-15  09:00 — SCÉNARIO F : REGROUPEMENT MASSIF
-- Plein de petites réservations -> remplissage optimal
-- ═════════════════════════════════════════════════════════════════

-- R11 : 2 pass -> Colbert
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id)
VALUES (1, 'CLI-F01', 2, '2026-03-15 09:00:00', 2);

-- R12 : 2 pass -> Carlton
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id)
VALUES (1, 'CLI-F02', 2, '2026-03-15 09:00:00', 3);

-- R13 : 1 pass -> Ibis
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id)
VALUES (1, 'CLI-F03', 1, '2026-03-15 09:00:00', 4);

-- R14 : 1 pass -> Antsirabe
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id)
VALUES (1, 'CLI-F04', 1, '2026-03-15 09:00:00', 7);

-- R15 : 1 pass -> Sainte-Marie
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id)
VALUES (1, 'CLI-F05', 1, '2026-03-15 09:00:00', 6);

-- ATTENDU (tri décrois : R11=R12 (2p) > R13=R14=R15 (1p)) :
--   R11 (2p) -> AV-007 (2pl, écart 0) -> 0 restante
--   R12 (2p) -> AV-001 (4pl, D, écart 2) -> 2 restantes
--     -> R13 (1p) regroupée -> 1 restante -> R14 (1p) regroupée -> 0
--   R15 (1p) -> AV-002 (4pl, Es)

-- ═════════════════════════════════════════════════════════════════
-- DATE 2026-03-15  14:00 — SCÉNARIO G : HORAIRES DIFFÉRENTES
-- Même date mais heure != -> PAS de regroupement entre elles
-- ═════════════════════════════════════════════════════════════════

-- R16 : 2 pass -> Colbert, 14:00
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id)
VALUES (1, 'CLI-G01', 2, '2026-03-15 14:00:00', 2);

-- R17 : 1 pass -> Carlton, 14:30 (30 min plus tard)
--   Heure != 14:00 -> NE DOIT PAS être regroupée avec R16
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id)
VALUES (1, 'CLI-G02', 1, '2026-03-15 14:30:00', 3);

-- ATTENDU :
--   R16 -> son propre véhicule
--   R17 -> son propre véhicule (heure différente)

-- ==========================================
-- 6. VÉRIFICATION
-- ==========================================

SELECT '--- DONNÉES CHARGÉES ---' AS info;

SELECT 'Lieux' AS table_name, COUNT(*) AS total FROM lieu
UNION ALL SELECT 'Distances', COUNT(*) FROM distance
UNION ALL SELECT 'Vehicules', COUNT(*) FROM vehicule
UNION ALL SELECT 'Parametres', COUNT(*) FROM parameters
UNION ALL SELECT 'Reservations', COUNT(*) FROM reservation;

SELECT '--- RÉSERVATIONS PAR DATE ET HEURE ---' AS info;

SELECT DATE(arrival_date) AS date_depart,
       arrival_date::time AS heure,
       COUNT(*) AS nb_reservations,
       SUM(passenger_nbr) AS total_passagers
FROM reservation
GROUP BY DATE(arrival_date), arrival_date::time
ORDER BY date_depart, heure;

SELECT '--- VÉHICULES ---' AS info;

SELECT reference, nb_place, type_carburant FROM vehicule ORDER BY nb_place, type_carburant;

--   \c postgres
--   DROP DATABASE hotel_reservation;
--   CREATE DATABASE hotel_reservation;
--   \c hotel_reservation
--   \i reinit.sql
