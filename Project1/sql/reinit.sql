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
('AV-001', 4, 'D'),    -- Diesel, 4 places
('AV-002', 4, 'Es'),   -- Essence, 4 places
('AV-003', 12, 'D'),    -- Diesel, 7 places
('AV-004', 5, 'El'),   -- Électrique, 5 places
('AV-005', 8, 'D');     -- Diesel, 8 places

-- 5.4 Paramètres de calcul
INSERT INTO parameters (key, value) VALUES
('vitesse_moyenne', '30'),    -- 30 km/h
('temps_attente', '30');      -- 30 minutes


-- ======================================================================
-- DATE: 2026-03-15 → Plusieurs réservations pour tester l'algorithme
-- ======================================================================

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(4, 'CLI001', 4, '2026-03-15 16:00:00', 1);

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(4, 'CLI002', 3, '2026-03-15 16:00:00', 2);

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(4, 'CLI003', 6, '2026-03-15 09:00:00', 3);

 

INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(1, 2, 30.00),    
(1, 3, 48.00),     
(2, 3, 26.00) ;        

INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(4, 1, 10.00),    -- Carlton ↔ Ivato
(4, 2, 48.00),    -- Ibis ↔ Ivato
(4, 3, 17.00),   -- Carlton ↔ Nosy Be
(4, 5, 18.00),   -- Carlton ↔ Nosy Be
(4, 6, 127.00),   -- Carlton ↔ Sainte-Marie
(4, 7, 127.00),   -- Carlton ↔ Sainte-Marie
(4, 8, 255.00);   -- Ibis ↔ Nosy Be

 
 
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
--   drop database hotel_reservation ;
--   create database hotel_reservation  ; 
--   \c hotel_reservation 



INSERT into  distance  ( from_lieu_id  ,  to_lieu_id  ,  km_distance ) VALUES (1,2,40) ;    

  30 km -> 1h 
  