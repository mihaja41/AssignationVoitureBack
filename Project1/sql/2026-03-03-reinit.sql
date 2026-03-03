-- psql -U postgres -d postgres -f /home/anita/Documents/itu_lesson/S5/FRAME_WORK/Project/AssignationVoitureBack/Project1/sql/reinit.sql


-- ==========================================
-- SCRIPT DE RÉINITIALISATION COMPLET
-- Base de données: hotel_reservation (PostgreSQL)
-- Sprint 3 - Planification & Attribution Véhicules
-- Date: 2026-03-01
-- ==========================================

-- ⚠️ ATTENTION : Ce script supprime et recrée TOUTE la base de données.
-- Utiliser uniquement pour les tests / démonstrations.
-- Exécuter en tant que superuser PostgreSQL (ex: postgres).
-- ⚠️ IMPORTANT : Exécuter ce script depuis la base "postgres" et non "hotel_reservation"
--   psql -U postgres -d postgres -f reinit.sql

-- ==========================================
-- 0. DROP & CREATE DATABASE
-- ==========================================
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


DROP TABLE IF EXISTS trajet CASCADE;
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

-- Table LIEU (tous les lieux : hôtels de départ + destinations)
-- Remplace l'ancienne table hotel
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

-- Table RESERVATION (simplifiée : l'assignation est gérée par la table TRAJET)
CREATE TABLE reservation (
    id BIGSERIAL PRIMARY KEY,
    lieu_depart_id BIGINT NOT NULL REFERENCES lieu(id) ON DELETE CASCADE,
    customer_id VARCHAR(100) NOT NULL,
    passenger_nbr INT NOT NULL,
    arrival_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lieu_destination_id BIGINT REFERENCES lieu(id) ON DELETE SET NULL
);

-- Table PARAMETERS (paramètres de calcul : vitesse moyenne, temps d'attente)
CREATE TABLE parameters (
    id SERIAL PRIMARY KEY,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Table TRAJET (résultat du planning : assignation véhicule ↔ réservation)
-- Les distances ne sont PAS stockées ici car elles existent déjà dans la table DISTANCE.
-- Elles sont calculées à la volée via DistanceRepository.findByFromAndTo(lieuDepart, lieuDestination).
CREATE TABLE trajet (
    id BIGSERIAL PRIMARY KEY,
    vehicule_id BIGINT NOT NULL REFERENCES vehicule(id) ON DELETE CASCADE,
    reservation_id BIGINT NOT NULL REFERENCES reservation(id) ON DELETE CASCADE,
    date_heure_depart TIMESTAMP NOT NULL,
    date_heure_retour TIMESTAMP NOT NULL,
    statut VARCHAR(50) DEFAULT 'ASSIGNE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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

CREATE INDEX idx_reservation_lieu_destination ON reservation(lieu_destination_id);
CREATE INDEX idx_reservation_lieu_depart ON reservation(lieu_depart_id);
CREATE INDEX idx_reservation_arrival_date ON reservation(arrival_date);
CREATE INDEX idx_lieu_code ON lieu(code);
CREATE INDEX idx_distance_from_to ON distance(from_lieu_id, to_lieu_id);
CREATE INDEX idx_trajet_vehicule ON trajet(vehicule_id);
CREATE INDEX idx_trajet_reservation ON trajet(reservation_id);
CREATE INDEX idx_trajet_depart ON trajet(date_heure_depart);
CREATE INDEX idx_trajet_retour ON trajet(date_heure_retour);

-- ==========================================
-- 5. DONNÉES DE TEST
-- ==========================================

-- 5.1 Lieux (hôtels de départ + destinations : aéroports, villes)
INSERT INTO lieu (code, libelle) VALUES
('COLBERT', 'Hotel Colbert, Antananarivo'),
('CARLTON', 'Hotel Carlton, Antananarivo'),
('IBIS', 'Hotel Ibis, Antananarivo'),
('IVATO', 'Ivato Airport, Antananarivo'),
('NOSY_BE', 'Nosy Be Airport'),
('SAINTE_MARIE', 'Sainte-Marie Airport'),
('ANTALAHA', 'Antalaha Airport'),
('SAMBAVA', 'Sambava Airport');

-- 5.2 Distances entre lieux (km)
INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(1, 4, 35.50),    -- Colbert -> Ivato
(4, 1, 35.50),    -- Ivato -> Colbert
(1, 5, 250.00),   -- Colbert -> Nosy Be
(5, 1, 250.00),   -- Nosy Be -> Colbert
(1, 6, 180.00),   -- Colbert -> Sainte-Marie
(6, 1, 180.00),   -- Sainte-Marie -> Colbert
(4, 5, 285.00),   -- Ivato -> Nosy Be
(5, 4, 285.00),   -- Nosy Be -> Ivato
(4, 6, 200.00),   -- Ivato -> Sainte-Marie
(6, 4, 200.00);   -- Sainte-Marie -> Ivato

-- 5.3 Véhicules (5 véhicules avec différents carburants et capacités)
INSERT INTO vehicule (reference, nb_place, type_carburant) VALUES
('AV-001', 4, 'D'),    -- Diesel, 4 places
('AV-002', 4, 'Es'),   -- Essence, 4 places
('AV-003', 7, 'D'),    -- Diesel, 7 places
('AV-004', 5, 'El'),   -- Électrique, 5 places
('AV-005', 8, 'D');     -- Diesel, 8 places

-- 5.4 Paramètres de calcul
INSERT INTO parameters (key, value) VALUES
('vitesse_moyenne', '30'),    -- 30 km/h
('temps_attente', '30');      -- 30 minutes

-- 5.5 Réservations de test (simplifiées : plus de vehicule_id, statut, heures)
-- Les horaires sont calculés automatiquement par le PlanningService
-- via : distance aller-retour / vitesse_moyenne + temps_attente

-- ======================================================================
-- DATE: 2026-03-15 → Plusieurs réservations pour tester l'algorithme
-- ======================================================================

-- Résa 1 : 4 passagers, départ Colbert → Ivato (distance: 35.5 km)
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'CLI001', 4, '2026-03-15 14:00:00', 4);

-- Résa 2 : 3 passagers, départ Carlton → Nosy Be (distance: 250 km — pas de distance directe Carlton→Nosy Be !)
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(2, 'CLI002', 3, '2026-03-15 16:00:00', 5);

-- Résa 3 : 6 passagers, départ Colbert → Sainte-Marie (distance: 180 km)
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'CLI003', 6, '2026-03-15 09:00:00', 6);

-- Résa 4 : 2 passagers, départ Ibis → Ivato (conflit horaire potentiel avec Résa 1)
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(3, 'CLI004', 2, '2026-03-15 14:00:00', 4);

-- Résa 5 : 10 passagers (aucun véhicule assez grand → restera NON_ASSIGNE)
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'CLI005', 10, '2026-03-15 11:00:00', 5);

-- ======================================================================
-- DATE: 2026-03-16 → Toutes les réservations (pour tester l'algo complet)
-- ======================================================================

-- Résa 6 : 4 passagers, départ Carlton → Ivato
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(2, 'CLI006', 4, '2026-03-16 10:00:00', 4);

-- Résa 7 : 3 passagers, départ Colbert → Sainte-Marie
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'CLI007', 3, '2026-03-16 15:00:00', 6);

-- Résa 8 : 5 passagers, départ Ibis → Nosy Be
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(3, 'CLI008', 5, '2026-03-16 12:00:00', 5);

-- ======================================================================
-- DATE: 2026-03-20 → Pour tester une autre date
-- ======================================================================

-- Résa 9 : 2 passagers, départ Colbert → Ivato
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'CLI009', 2, '2026-03-20 09:00:00', 4);

-- Résa 10 : 4 passagers, départ Carlton → Nosy Be
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(2, 'CLI010', 4, '2026-03-20 14:00:00', 5);

-- ==========================================
-- 6. AJOUT DE DISTANCES MANQUANTES
-- (pour que toutes les réservations aient une distance)
-- ==========================================

-- Carlton → Ivato et retour
INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(2, 4, 30.00),    -- Carlton -> Ivato
(4, 2, 30.00);    -- Ivato -> Carlton

-- Ibis → Ivato et retour
INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(3, 4, 28.00),    -- Ibis -> Ivato
(4, 3, 28.00);    -- Ivato -> Ibis

-- Carlton → Nosy Be et retour
INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(2, 5, 260.00),   -- Carlton -> Nosy Be
(5, 2, 260.00);   -- Nosy Be -> Carlton

-- Ibis → Nosy Be et retour
INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(3, 5, 255.00),   -- Ibis -> Nosy Be
(5, 3, 255.00);   -- Nosy Be -> Ibis

-- ==========================================
-- 7. VÉRIFICATION
-- ==========================================

SELECT 'Lieux' AS table_name, COUNT(*) AS total FROM lieu
UNION ALL
SELECT 'Distances', COUNT(*) FROM distance
UNION ALL
SELECT 'Véhicules', COUNT(*) FROM vehicule
UNION ALL
SELECT 'Paramètres', COUNT(*) FROM parameters
UNION ALL
SELECT 'Réservations (total)', COUNT(*) FROM reservation
UNION ALL
SELECT 'Trajets', COUNT(*) FROM trajet;
