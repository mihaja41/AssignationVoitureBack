-- ================================================================================
--  sprint 7 - SCRIPT DE REINITIALISATION COMPLET AVEC DONNEES
-- ================================================================================
-- Auteur: ETU003240
-- Date: 2026-03-19
-- Description: Script de reinitialisation complete de la base de donnees
--              avec toutes les colonnes Sprint 7 et  sprint 7
--              Inclut les donnees de test pour valider les fonctionnalites
-- ================================================================================
-- Usage: psql -U postgres -d postgres -f reinit_ sprint7_complet.sql
-- ================================================================================
-- psql -U postgres -d postgres -f /home/anita/Documents/itu_lesson/S5/FRAME_WORK/Project/AssignationVoitureBack/Project1/sql/reinit_ sprint7_complet.sql
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

-- Table VEHICULE ( sprint 7 : avec heure_disponible_debut)
CREATE TABLE vehicule (
    id BIGSERIAL PRIMARY KEY,
    reference VARCHAR(100) NOT NULL,
    nb_place INT NOT NULL,
    type_carburant type_carburant_enum NOT NULL,
    --  sprint 7 : Heure de disponibilite quotidienne
    heure_disponible_debut TIME DEFAULT NULL
);

COMMENT ON COLUMN vehicule.heure_disponible_debut IS
    ' sprint 7 : Heure quotidienne a partir de laquelle le vehicule est disponible';

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

-- Table ATTRIBUTION (Sprint 7 : nb_passagers_assignes)
CREATE TABLE attribution (
    id SERIAL PRIMARY KEY,
    reservation_id INTEGER NOT NULL REFERENCES reservation(id) ON DELETE CASCADE,
    vehicule_id INTEGER NOT NULL REFERENCES vehicule(id) ON DELETE CASCADE,
    date_heure_depart TIMESTAMP NOT NULL,
    date_heure_retour TIMESTAMP NOT NULL,
    statut VARCHAR(20) NOT NULL DEFAULT 'ASSIGNE',
    -- Sprint 7 : Colonne pour la division des passagers
    nb_passagers_assignes INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON COLUMN attribution.nb_passagers_assignes IS
    'Sprint 7 : Nombre de passagers transportes dans CE vehicule (pour supporter la division)';

-- ==========================================
-- 4. CREATION DES INDEX
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
-- 5. INSERTION DES PARAMETRES
-- ==========================================

INSERT INTO parameters (key, value) VALUES
('vitesse_moyenne', '50'),    -- 50 km/h
('temps_attente', '30');      -- 30 minutes

-- ==========================================
-- 6. INSERTION DES LIEUX
-- ==========================================

INSERT INTO lieu (code, libelle, initial) VALUES
('IVATO',    'Aeroport Ivato','A'),    -- id = 1
('hotel1', 'Hotel 1', 'B'),
('hotel2', 'Hotel 2', 'C');

-- ==========================================
-- 7. INSERTION DES DISTANCES
-- ==========================================

-- Depuis IVATO (id=1) vers tous les hotels
INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(1, 2, 90.00),   -- IVATO -> CARLTON
(1, 3, 35.00),   -- IVATO -> COLBERT
(2, 3, 60.00);  -- IVATO -> IBIS


-- ==========================================
-- 8. INSERTION DES VEHICULES ( sprint 7)
-- ==========================================
-- Avec heure_disponible_debut pour tester le filtrage

INSERT INTO vehicule (reference, nb_place, type_carburant, heure_disponible_debut) VALUES
-- Grands vehicules (12 places)
('vehicule1',  5, 'D',  '09:00:00'),   -- Diesel, disponible des 06:00
('vehicule2',  5, 'Es', '09:00:00'),         -- Essence, toujours disponible

-- Vehicules moyens (5 places)
('vehicule3',  12,  'D',  '07:00:00'),   -- Diesel, disponible des 07:00
('vehicule4',  9,  'D',  '09:00:00'),   -- Diesel, disponible des 08:00
('vehicule5',  12,  'Es', '13:00:00');      -- Essence, toujours disponible

-- ==========================================
-- 9. INSERTION DES RESERVATIONS (SCENARIOS DE TEST)
-- ==========================================

-- ==========================================
-- SCENARIO 1: REGROUPEMENT OPTIMAL
-- Date: 2026-04-01
-- Test: Regroupement avec ecart minimum
-- ==========================================
-- Places restantes = 5, reservations: 2, 4, 5, 6
-- Attendu: Prendre 5 (ecart = 0) au lieu de 2 ou 4

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'client1', 7,  '2026-03-19 09:00:00', 2),  
(1, 'client2', 20,  '2026-03-19 08:00:00', 3),
(1, 'client3', 3,  '2026-03-19 09:10:00', 2),
(1, 'client4', 10,  '2026-03-19 09:15:00', 2),
(1, 'client5', 5,  '2026-03-19 09:20:00', 2),
(1, 'client6', 12,  '2026-03-19 13:30:00', 2);
