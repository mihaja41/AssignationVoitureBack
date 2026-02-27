-- ==========================================
-- SCRIPT DE RÉINITIALISATION COMPLET
-- Base de données: hotel_reservation (PostgreSQL)
-- Sprint 3 - Planification & Attribution Véhicules
-- Date: 2026-02-27
-- ==========================================

-- ⚠️ ATTENTION : Ce script supprime et recrée TOUTES les données.
-- Utiliser uniquement pour les tests / démonstrations.

-- ==========================================
-- 1. NETTOYAGE (ordre inverse des dépendances)
-- ==========================================

DROP TABLE IF EXISTS distance CASCADE;
DROP TABLE IF EXISTS reservation CASCADE;
DROP TABLE IF EXISTS vehicule CASCADE;
DROP TABLE IF EXISTS lieu CASCADE;
DROP TABLE IF EXISTS hotel CASCADE;
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

-- Table HOTEL (conservée pour compatibilité avec l'autre repo frontend)
-- Note: Hotel = lieu de départ du client (ex: Hotel Colbert)
CREATE TABLE hotel (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Table LIEU (lieux de destination : aéroports, villes, etc.)
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
    hotel_id BIGINT NOT NULL REFERENCES hotel(id) ON DELETE CASCADE,
    customer_id VARCHAR(100) NOT NULL,
    passenger_nbr INT NOT NULL,
    arrival_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lieu_destination_id BIGINT REFERENCES lieu(id) ON DELETE SET NULL,
    vehicule_id BIGINT REFERENCES vehicule(id) ON DELETE SET NULL,
    statut VARCHAR(50) DEFAULT 'NON_ASSIGNE',
    heure_depart TIMESTAMP,
    heure_arrivee TIMESTAMP,
    heure_retour TIMESTAMP
);

-- Table DISTANCE (distances entre lieux)
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

CREATE INDEX idx_reservation_statut ON reservation(statut);
CREATE INDEX idx_reservation_heure_depart ON reservation(heure_depart);
CREATE INDEX idx_reservation_vehicule_id ON reservation(vehicule_id);
CREATE INDEX idx_reservation_lieu_destination ON reservation(lieu_destination_id);
CREATE INDEX idx_lieu_code ON lieu(code);
CREATE INDEX idx_distance_from_to ON distance(from_lieu_id, to_lieu_id);

-- ==========================================
-- 5. DONNÉES DE TEST
-- ==========================================

-- 5.1 Hotels (lieux de départ des clients)
INSERT INTO hotel (name) VALUES
('Hotel Colbert, Antananarivo'),
('Hotel Carlton, Antananarivo'),
('Hotel Ibis, Antananarivo');

-- 5.2 Lieux (destinations : aéroports)
INSERT INTO lieu (code, libelle) VALUES
('COLBERT', 'Colbert, Antananarivo'),
('IVATO', 'Ivato Airport, Antananarivo'),
('NOSY_BE', 'Nosy Be Airport'),
('SAINTE_MARIE', 'Sainte-Marie Airport'),
('ANTALAHA', 'Antalaha Airport'),
('SAMBAVA', 'Sambava Airport');

-- 5.3 Distances entre lieux (km)
INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(1, 2, 35.50),    -- Colbert -> Ivato
(2, 1, 35.50),    -- Ivato -> Colbert
(1, 3, 250.00),   -- Colbert -> Nosy Be
(3, 1, 250.00),   -- Nosy Be -> Colbert
(1, 4, 180.00),   -- Colbert -> Sainte-Marie
(4, 1, 180.00),   -- Sainte-Marie -> Colbert
(2, 3, 285.00),   -- Ivato -> Nosy Be
(3, 2, 285.00),   -- Nosy Be -> Ivato
(2, 4, 200.00),   -- Ivato -> Sainte-Marie
(4, 2, 200.00);   -- Sainte-Marie -> Ivato

-- 5.4 Véhicules
INSERT INTO vehicule (reference, nb_place, type_carburant) VALUES
('AV-001', 4, 'D'),    -- Diesel, 4 places
('AV-002', 4, 'Es'),   -- Essence, 4 places
('AV-003', 7, 'D'),    -- Diesel, 7 places
('AV-004', 5, 'El'),   -- Électrique, 5 places
('AV-005', 8, 'D');     -- Diesel, 8 places

-- 5.5 Réservations de test (différents cas pour tester l'algorithme)

-- Réservation 1 : 4 passagers, NON_ASSIGNE, pour le 15 mars
INSERT INTO reservation (hotel_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id, statut, heure_depart, heure_arrivee, heure_retour) VALUES
(1, 'CLI001', 4, '2026-03-15 14:00:00', 2, 'NON_ASSIGNE', '2026-03-15 08:00:00', '2026-03-15 14:00:00', '2026-03-15 18:00:00');

-- Réservation 2 : 3 passagers, NON_ASSIGNE, même date (devrait aussi trouver un véhicule)
INSERT INTO reservation (hotel_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id, statut, heure_depart, heure_arrivee, heure_retour) VALUES
(2, 'CLI002', 3, '2026-03-15 16:00:00', 3, 'NON_ASSIGNE', '2026-03-15 10:00:00', '2026-03-15 16:00:00', '2026-03-15 20:00:00');

-- Réservation 3 : 6 passagers, NON_ASSIGNE (nécessite véhicule >= 6 places)
INSERT INTO reservation (hotel_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id, statut, heure_depart, heure_arrivee, heure_retour) VALUES
(1, 'CLI003', 6, '2026-03-15 09:00:00', 4, 'NON_ASSIGNE', '2026-03-15 06:00:00', '2026-03-15 09:00:00', '2026-03-15 15:00:00');

-- Réservation 4 : 2 passagers, même date, conflit horaire possible
INSERT INTO reservation (hotel_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id, statut, heure_depart, heure_arrivee, heure_retour) VALUES
(3, 'CLI004', 2, '2026-03-15 14:00:00', 2, 'NON_ASSIGNE', '2026-03-15 08:00:00', '2026-03-15 14:00:00', '2026-03-15 19:00:00');

-- Réservation 5 : 10 passagers (aucun véhicule assez grand → restera NON_ASSIGNE)
INSERT INTO reservation (hotel_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id, statut, heure_depart, heure_arrivee, heure_retour) VALUES
(1, 'CLI005', 10, '2026-03-15 11:00:00', 3, 'NON_ASSIGNE', '2026-03-15 07:00:00', '2026-03-15 11:00:00', '2026-03-15 16:00:00');

-- Réservation 6 : autre date (16 mars) pour vérifier le filtre par date
INSERT INTO reservation (hotel_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id, statut, heure_depart, heure_arrivee, heure_retour) VALUES
(2, 'CLI006', 4, '2026-03-16 10:00:00', 2, 'NON_ASSIGNE', '2026-03-16 06:00:00', '2026-03-16 10:00:00', '2026-03-16 14:00:00');

-- ==========================================
-- 6. VÉRIFICATION
-- ==========================================

SELECT 'Hotels' AS table_name, COUNT(*) AS total FROM hotel
UNION ALL
SELECT 'Lieux', COUNT(*) FROM lieu
UNION ALL
SELECT 'Distances', COUNT(*) FROM distance
UNION ALL
SELECT 'Véhicules', COUNT(*) FROM vehicule
UNION ALL
SELECT 'Réservations', COUNT(*) FROM reservation
UNION ALL
SELECT 'Réservations NON_ASSIGNE', COUNT(*) FROM reservation WHERE statut = 'NON_ASSIGNE';
