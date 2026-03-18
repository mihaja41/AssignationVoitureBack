-- psql -U postgres -d postgres -f /home/anita/Documents/itu_lesson/S5/FRAME_WORK/Project/AssignationVoitureBack/Project1/sql/reinit.sql

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

CREATE TABLE IF NOT EXISTS attribution (
    id SERIAL PRIMARY KEY,
    reservation_id INTEGER NOT NULL REFERENCES reservation(id),
    vehicule_id INTEGER NOT NULL REFERENCES vehicule(id),
    date_heure_depart TIMESTAMP NOT NULL,
    date_heure_retour TIMESTAMP NOT NULL,
    statut VARCHAR(20) NOT NULL DEFAULT 'ASSIGNE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour optimiser les requêtes fréquentes
CREATE INDEX IF NOT EXISTS idx_attribution_reservation ON attribution(reservation_id);
CREATE INDEX IF NOT EXISTS idx_attribution_vehicule ON attribution(vehicule_id);
CREATE INDEX IF NOT EXISTS idx_attribution_date_depart ON attribution(date_heure_depart);
CREATE INDEX IF NOT EXISTS idx_attribution_date_retour ON attribution(date_heure_retour);

-- ==========================================
-- 4. CRÉATION DES INDEX
-- ==========================================

CREATE INDEX idx_reservation_lieu_destination ON reservation(lieu_destination_id);
CREATE INDEX idx_reservation_lieu_depart ON reservation(lieu_depart_id);
CREATE INDEX idx_reservation_arrival_date ON reservation(arrival_date);
CREATE INDEX idx_lieu_code ON lieu(code);
CREATE INDEX idx_distance_from_to ON distance(from_lieu_id, to_lieu_id);


INSERT INTO lieu (code, libelle) VALUES
('IVATO',         'Aeroport Ivato'),               -- id = 1
('hotel1',       'Hotel1');                    -- id = 8


INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(1, 2,  50.00);

INSERT INTO vehicule (reference, nb_place, type_carburant) VALUES
('vehicule1', 12, 'D'),    -- Diesel, 4 places
('vehicule2', 5, 'Es'),   -- Essence, 4 places
('vehicule3', 5, 'D'),    -- Diesel, 7 places
('vehicule4', 12, 'Es');

-- 5.4 Paramètres de calcul
INSERT INTO parameters (key, value) VALUES
('vitesse_moyenne', '50'),    -- 30 km/h
('temps_attente', '30');      -- 30 minutes


-- ======================================================================
-- DATE: 2026-03-15 → Plusieurs réservations pour tester l'algorithme
-- ======================================================================

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'Client1', 7, '2026-03-12 09:00:00', 2);

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'Client2', 11, '2026-03-12 09:00:00', 2);

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'Client3', 3, '2026-03-12 09:00:00', 2);

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'Client4', 1, '2026-03-16 09:00:00', 2);

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'Client5', 2, '2026-03-16 09:00:00', 2);

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'Client6', 20, '2026-03-16 09:00:00', 2);

INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(1, 2, 50.00);       

 
 
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


  