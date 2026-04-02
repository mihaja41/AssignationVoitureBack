-- ================================================================================
-- SPRINT 8 - FICHIER SQL UNIQUE D'INITIALISATION
-- ================================================================================
-- Ce fichier crée UNE SEULE FOIS la base avec:
-- - Lieux
-- - Véhicules
-- - Distances
-- - Paramètres
--
-- PAS d'attributions
-- PAS de réservations pré-chargées
--
-- Les scénarios vont AJOUTER progressivement des réservations et réutiliser
-- les attributions calculées comme pré-existantes pour les simulations suivantes
-- ================================================================================

-- Fermer les connexions
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'hotel_reservation' AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS hotel_reservation;
CREATE DATABASE hotel_reservation;

\c hotel_reservation

-- ==========================================
-- NETTOYAGE
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
-- TYPE ENUM
-- ==========================================

CREATE TYPE type_carburant_enum AS ENUM ('D', 'Es', 'H', 'El');

-- ==========================================
-- TABLES
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
-- INDEX
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
-- PARAMETRES
-- ==========================================

INSERT INTO parameters (key, value) VALUES
('vitesse_moyenne', '50'),
('temps_attente', '30');

-- ==========================================
-- LIEUX
-- ==========================================

INSERT INTO lieu (id, code, libelle, initial) VALUES
(1, 'IVATO', 'Aeroport Ivato', 'A'),
(2, 'CARLTON', 'Hotel Carlton', 'B'),
(3, 'COLBERT', 'Hotel Colbert', 'C');

SELECT setval('lieu_id_seq', 3);

-- ==========================================
-- DISTANCES
-- ==========================================

INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(1, 2, 25.00),
(1, 3, 30.00),
(2, 1, 25.00),
(2, 3, 10.00),
(3, 1, 30.00),
(3, 2, 10.00);

-- ==========================================
-- VEHICULES
-- ==========================================

INSERT INTO vehicule (id, reference, nb_place, type_carburant, heure_disponible_debut) VALUES
(1, 'v1', 10, 'D',  NULL),
(2, 'v2', 10, 'Es', NULL),
(3, 'v3', 12, 'D',  NULL),
(4, 'v4', 8,  'H',  '10:30:00');

SELECT setval('vehicule_id_seq', 4);

-- ==========================================
-- AFFICHAGE
-- ==========================================

SELECT '========================================' as info;
SELECT 'BASE INITIALISEE - SPRINT 8' as status;
SELECT '========================================' as info;

SELECT '--- CONFIGURATION STATIQUE ---' as section;

SELECT 'Lieux:' as subsection;
SELECT code, libelle FROM lieu ORDER BY id;

SELECT 'Vehicules:' as subsection;
SELECT reference, nb_place, type_carburant, COALESCE(heure_disponible_debut::text, 'Toujours') as dispo FROM vehicule ORDER BY id;

SELECT 'Parametres:' as subsection;
SELECT key, value FROM parameters;

SELECT '========================================' as info;
SELECT 'Pret pour les simulations progressives!' as status;
SELECT '========================================' as info;

SELECT 'Workflow:' as guide;
SELECT '1. Jour 1 (27/03): Ajouter reservations + Planifier' as step;
SELECT '2. Jour 2 (28/03): Utiliser attributions du Jour 1 comme pre-existantes + nouvelles reservations' as step;
SELECT '3. Jour 3+ : Repeter' as step;

SELECT '========================================' as info;
