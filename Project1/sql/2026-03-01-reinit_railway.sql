-- ==========================================
-- SCRIPT DE RÉINITIALISATION POUR RAILWAY
-- Base de données: railway (PostgreSQL)
-- Sprint 3 - Planification & Attribution Véhicules
-- Date: 2026-03-01
-- ==========================================

-- ⚠️ Pas de DROP/CREATE DATABASE sur Railway (pas les droits).
-- On fait un DROP TABLE complet à la place.

-- ==========================================
-- 1. NETTOYAGE
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

-- ==========================================
-- 3. CRÉATION DES TABLES
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE vehicule (
    id BIGSERIAL PRIMARY KEY,
    reference VARCHAR(100) NOT NULL,
    nb_place INT NOT NULL,
    type_carburant type_carburant_enum NOT NULL
);

CREATE TABLE reservation (
    id BIGSERIAL PRIMARY KEY,
    lieu_depart_id BIGINT NOT NULL REFERENCES lieu(id) ON DELETE CASCADE,
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
CREATE INDEX idx_reservation_lieu_depart ON reservation(lieu_depart_id);
CREATE INDEX idx_lieu_code ON lieu(code);
CREATE INDEX idx_distance_from_to ON distance(from_lieu_id, to_lieu_id);

-- ==========================================
-- 5. DONNÉES DE TEST
-- ==========================================

INSERT INTO lieu (code, libelle) VALUES
('COLBERT', 'Hotel Colbert, Antananarivo'),
('CARLTON', 'Hotel Carlton, Antananarivo'),
('IBIS', 'Hotel Ibis, Antananarivo'),
('IVATO', 'Ivato Airport, Antananarivo'),
('NOSY_BE', 'Nosy Be Airport'),
('SAINTE_MARIE', 'Sainte-Marie Airport'),
('ANTALAHA', 'Antalaha Airport'),
('SAMBAVA', 'Sambava Airport');

INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(1, 4, 35.50),
(4, 1, 35.50),
(1, 5, 250.00),
(5, 1, 250.00),
(1, 6, 180.00),
(6, 1, 180.00),
(4, 5, 285.00),
(5, 4, 285.00),
(4, 6, 200.00),
(6, 4, 200.00);

INSERT INTO vehicule (reference, nb_place, type_carburant) VALUES
('AV-001', 4, 'D'),
('AV-002', 4, 'Es'),
('AV-003', 7, 'D'),
('AV-004', 5, 'El'),
('AV-005', 8, 'D');

-- Date 2026-03-15 : Mix assignées + non assignées
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id, vehicule_id, statut, heure_depart, heure_arrivee, heure_retour) VALUES
(1, 'CLI001', 4, '2026-03-15 14:00:00', 4, 1, 'ASSIGNE', '2026-03-15 08:00:00', '2026-03-15 14:00:00', '2026-03-15 18:00:00');
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id, vehicule_id, statut, heure_depart, heure_arrivee, heure_retour) VALUES
(2, 'CLI002', 3, '2026-03-15 16:00:00', 5, 3, 'ASSIGNE', '2026-03-15 10:00:00', '2026-03-15 16:00:00', '2026-03-15 20:00:00');
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id, statut, heure_depart, heure_arrivee, heure_retour) VALUES
(1, 'CLI003', 6, '2026-03-15 09:00:00', 6, 'NON_ASSIGNE', '2026-03-15 06:00:00', '2026-03-15 09:00:00', '2026-03-15 15:00:00');
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id, statut, heure_depart, heure_arrivee, heure_retour) VALUES
(3, 'CLI004', 2, '2026-03-15 14:00:00', 4, 'NON_ASSIGNE', '2026-03-15 08:00:00', '2026-03-15 14:00:00', '2026-03-15 19:00:00');
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id, statut, heure_depart, heure_arrivee, heure_retour) VALUES
(1, 'CLI005', 10, '2026-03-15 11:00:00', 5, 'NON_ASSIGNE', '2026-03-15 07:00:00', '2026-03-15 11:00:00', '2026-03-15 16:00:00');

-- Date 2026-03-16 : Toutes NON_ASSIGNE
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id, statut, heure_depart, heure_arrivee, heure_retour) VALUES
(2, 'CLI006', 4, '2026-03-16 10:00:00', 4, 'NON_ASSIGNE', '2026-03-16 06:00:00', '2026-03-16 10:00:00', '2026-03-16 14:00:00');
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id, statut, heure_depart, heure_arrivee, heure_retour) VALUES
(1, 'CLI007', 3, '2026-03-16 15:00:00', 6, 'NON_ASSIGNE', '2026-03-16 09:00:00', '2026-03-16 15:00:00', '2026-03-16 19:00:00');
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id, statut, heure_depart, heure_arrivee, heure_retour) VALUES
(3, 'CLI008', 5, '2026-03-16 12:00:00', 5, 'NON_ASSIGNE', '2026-03-16 07:00:00', '2026-03-16 12:00:00', '2026-03-16 17:00:00');

-- Date 2026-03-20 : Toutes ASSIGNE
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id, vehicule_id, statut, heure_depart, heure_arrivee, heure_retour) VALUES
(1, 'CLI009', 2, '2026-03-20 09:00:00', 4, 2, 'ASSIGNE', '2026-03-20 06:00:00', '2026-03-20 09:00:00', '2026-03-20 13:00:00');
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id, vehicule_id, statut, heure_depart, heure_arrivee, heure_retour) VALUES
(2, 'CLI010', 4, '2026-03-20 14:00:00', 5, 5, 'ASSIGNE', '2026-03-20 08:00:00', '2026-03-20 14:00:00', '2026-03-20 20:00:00');

-- ==========================================
-- 6. VÉRIFICATION
-- ==========================================

SELECT 'Lieux' AS table_name, COUNT(*) AS total FROM lieu
UNION ALL
SELECT 'Distances', COUNT(*) FROM distance
UNION ALL
SELECT 'Véhicules', COUNT(*) FROM vehicule
UNION ALL
SELECT 'Réservations (total)', COUNT(*) FROM reservation
UNION ALL
SELECT 'Réservations ASSIGNE', COUNT(*) FROM reservation WHERE statut = 'ASSIGNE'
UNION ALL
SELECT 'Réservations NON_ASSIGNE', COUNT(*) FROM reservation WHERE statut = 'NON_ASSIGNE';
