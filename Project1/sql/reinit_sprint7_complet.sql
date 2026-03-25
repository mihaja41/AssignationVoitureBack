-- ================================================================================
-- SPRINT 7 - SCRIPT DE REINITIALISATION COMPLET
-- ================================================================================
-- Auteur: ETU003240
-- Date: 2026-03-19
-- Description: Script de reinitialisation complete de la base de donnees
--              avec toutes les colonnes necessaires pour le Sprint 7
-- ================================================================================
-- Usage: psql -U postgres -d postgres -f reinit_sprint7_complet.sql
-- ================================================================================

-- Fermer toutes les connexions actives a la base
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'hotel_reservation' AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS hotel_reservation;
CREATE DATABASE hotel_reservation;

-- Se connecter a la nouvelle base
\c hotel_reservation

-- ==========================================
-- 1. NETTOYAGE (securite supplementaire)
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
-- 2. CREATION DU TYPE ENUM
-- ==========================================

CREATE TYPE type_carburant_enum AS ENUM ('D', 'Es', 'H', 'El');
-- D  = Diesel
-- Es = Essence
-- H  = Hybride
-- El = Electrique

-- ==========================================
-- 3. CREATION DES TABLES
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
    initial VARCHAR(10),
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
-- Table ATTRIBUTION (Sprint 5/6/7)
-- ==========================================
-- Sprint 7: Inclut nb_passagers_assignes pour la division

CREATE TABLE attribution (
    id SERIAL PRIMARY KEY,
    reservation_id INTEGER NOT NULL REFERENCES reservation(id) ON DELETE CASCADE,
    vehicule_id INTEGER NOT NULL REFERENCES vehicule(id) ON DELETE CASCADE,
    date_heure_depart TIMESTAMP NOT NULL,
    date_heure_retour TIMESTAMP NOT NULL,
    statut VARCHAR(20) NOT NULL DEFAULT 'ASSIGNE',
    -- Sprint 7: Colonne pour la division des passagers
    nb_passagers_assignes INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Commentaires Sprint 7
COMMENT ON TABLE attribution IS 'Table des attributions de vehicules aux reservations (Sprint 7: supporte la division)';
COMMENT ON COLUMN attribution.nb_passagers_assignes IS 'Sprint 7: Nombre de passagers transportes dans CE vehicule (pour supporter la division)';

-- ==========================================
-- 4. CREATION DES INDEX
-- ==========================================

-- Index pour attribution
CREATE INDEX idx_attribution_reservation ON attribution(reservation_id);
CREATE INDEX idx_attribution_vehicule ON attribution(vehicule_id);
CREATE INDEX idx_attribution_date_depart ON attribution(date_heure_depart);
CREATE INDEX idx_attribution_date_retour ON attribution(date_heure_retour);

-- Index pour autres tables
CREATE INDEX idx_reservation_lieu_destination ON reservation(lieu_destination_id);
CREATE INDEX idx_reservation_lieu_depart ON reservation(lieu_depart_id);
CREATE INDEX idx_reservation_arrival_date ON reservation(arrival_date);
CREATE INDEX idx_lieu_code ON lieu(code);
CREATE INDEX idx_distance_from_to ON distance(from_lieu_id, to_lieu_id);

-- ==========================================
-- 5. PARAMETRES PAR DEFAUT
-- ==========================================

INSERT INTO parameters (key, value) VALUES
('vitesse_moyenne', '50'),    -- 50 km/h
('temps_attente', '30');      -- 30 minutes

-- ==========================================
-- 6. VERIFICATION FINALE
-- ==========================================

SELECT '=== REINITIALISATION SPRINT 7 COMPLETE ===' AS message;

SELECT '--- STRUCTURE DES TABLES ---' AS info;

SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name IN ('attribution', 'reservation', 'vehicule', 'lieu', 'distance')
ORDER BY table_name, ordinal_position;

SELECT '--- VERIFICATION COLONNE NB_PASSAGERS_ASSIGNES ---' AS info;

SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'attribution' AND column_name = 'nb_passagers_assignes';

SELECT '=== BASE PRETE POUR LES DONNEES DE TEST ===' AS message;
