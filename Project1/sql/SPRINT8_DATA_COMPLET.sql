-- ================================================================================
-- SPRINT 8 - SCRIPT DE REINITIALISATION COMPLET AVEC DONNEES DE SIMULATION
-- ================================================================================
-- Auteur: ETU003240
-- Date: 2026-04-01
-- Description: Script de reinitialisation complete de la base de donnees
--              avec toutes les colonnes Sprint 7/8 et donnees de test
--              pour valider les fonctionnalites Sprint 8:
--              - Retour vehicules et fenetres d'attente
--              - Restes/reports de reservations
--              - Regroupement optimal (closest fit)
--              - Division optimale
--              - Disponibilite horaire (heure_disponible_debut)
-- ================================================================================
-- Usage: psql -U postgres -d postgres -f reinit_sprint8_complet.sql
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

-- Table VEHICULE (Sprint 8 : avec heure_disponible_debut)
CREATE TABLE vehicule (
    id BIGSERIAL PRIMARY KEY,
    reference VARCHAR(100) NOT NULL,
    nb_place INT NOT NULL,
    type_carburant type_carburant_enum NOT NULL,
    -- Sprint 8 : Heure de disponibilite quotidienne
    heure_disponible_debut TIME DEFAULT NULL
);

COMMENT ON COLUMN vehicule.heure_disponible_debut IS
    'Sprint 8 : Heure quotidienne a partir de laquelle le vehicule est disponible';

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

-- Table ATTRIBUTION (Sprint 7/8 : nb_passagers_assignes)
CREATE TABLE attribution (
    id SERIAL PRIMARY KEY,
    reservation_id INTEGER NOT NULL REFERENCES reservation(id) ON DELETE CASCADE,
    vehicule_id INTEGER NOT NULL REFERENCES vehicule(id) ON DELETE CASCADE,
    date_heure_depart TIMESTAMP NOT NULL,
    date_heure_retour TIMESTAMP NOT NULL,
    statut VARCHAR(20) NOT NULL DEFAULT 'ASSIGNE',
    -- Sprint 7/8 : Colonne pour la division des passagers
    nb_passagers_assignes INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON COLUMN attribution.nb_passagers_assignes IS
    'Sprint 7/8 : Nombre de passagers transportes dans CE vehicule (pour supporter la division)';

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
('temps_attente', '30');      -- 30 minutes fenetre d'attente

-- ==========================================
-- 6. INSERTION DES LIEUX
-- ==========================================

INSERT INTO lieu (code, libelle, initial) VALUES
('IVATO', 'Aeroport Ivato', 'A'),       -- id = 1
('CARLTON', 'Hotel Carlton', 'B'),      -- id = 2
('COLBERT', 'Hotel Colbert', 'C');      -- id = 3

-- ==========================================
-- 7. INSERTION DES DISTANCES
-- ==========================================
-- Distances bidirectionnelles pour les calculs de trajet aller-retour

INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
-- Depuis IVATO (id=1)
(1, 2, 25.00),   -- IVATO -> CARLTON
(1, 3, 30.00),   -- IVATO -> COLBERT

-- Depuis CARLTON (id=2)
(2, 1, 25.00),   -- CARLTON -> IVATO
(2, 3, 10.00),   -- CARLTON -> COLBERT

-- Depuis COLBERT (id=3)
(3, 1, 30.00),   -- COLBERT -> IVATO
(3, 2, 10.00);   -- COLBERT -> CARLTON

-- ==========================================
-- 8. INSERTION DES VEHICULES (Sprint 8)
-- ==========================================
-- Vehicules selon la specification Sprint 8:
-- v1: 10 places, Diesel, revient a 09:45
-- v2: 10 places, Essence, revient a 09:45
-- v3: 12 places, Diesel, revient a 10:12
-- v4: 8 places, Hybride, disponible a partir de 10:30 (test heure_disponible_debut)

INSERT INTO vehicule (reference, nb_place, type_carburant, heure_disponible_debut) VALUES
('v1', 10, 'D',  NULL),        -- Diesel, toujours disponible
('v2', 10, 'Es', NULL),        -- Essence, toujours disponible
('v3', 12, 'D',  NULL),        -- Diesel, toujours disponible
('v4', 8,  'H',  '10:30:00');  -- Hybride, disponible a partir de 10:30

-- ==========================================
-- 9. RESERVATIONS FICTIVES POUR TRAJETS PRECEDENTS
-- ==========================================
-- Ces reservations servent a creer les attributions pre-existantes
-- (vehicules "en course" qui vont revenir)

INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(100, 2, 'TRAJET_INIT_V1', 10, '2026-03-27 07:00:00', 1),
(101, 2, 'TRAJET_INIT_V2', 10, '2026-03-27 07:00:00', 1),
(102, 3, 'TRAJET_INIT_V3', 12, '2026-03-27 07:30:00', 1);

-- ==========================================
-- 10. ATTRIBUTIONS PRE-EXISTANTES (vehicules en course)
-- ==========================================
-- Simule les vehicules qui sont partis et vont revenir:
-- v1 et v2 reviennent a 09:45
-- v3 revient a 10:12

INSERT INTO attribution (id, reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes) VALUES
-- v1 revient a 09:45
(100, 100, 1, '2026-03-27 08:45:00', '2026-03-27 09:45:00', 'TERMINE', 10),
-- v2 revient a 09:45
(101, 101, 2, '2026-03-27 08:45:00', '2026-03-27 09:45:00', 'TERMINE', 10),
-- v3 revient a 10:12
(102, 102, 3, '2026-03-27 09:00:00', '2026-03-27 10:12:00', 'TERMINE', 12);

-- Mise a jour des sequences
SELECT setval('attribution_id_seq', 102);

-- ==========================================
-- 11. RESERVATIONS - RESTES NON ASSIGNES (PRIORITAIRES)
-- ==========================================
-- r1 et r2 sont des "restes" de reservations precedentes
-- Ils sont arrives AVANT le retour des vehicules (09:45)
-- Ils doivent etre traites EN PRIORITE

INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- r1: 9 passagers, arrive a 08:00 (reste non assigne - PRIORITAIRE)
(1, 2, 'r1_RESTE_9pass', 9, '2026-03-27 08:00:00', 1),
-- r2: 5 passagers, arrive a 07:30 (reste non assigne - PRIORITAIRE)
(2, 2, 'r2_RESTE_5pass', 5, '2026-03-27 07:30:00', 1);

-- ==========================================
-- 12. RESERVATIONS - NOUVELLES ARRIVEES
-- ==========================================
-- Ces reservations arrivent pendant ou apres la fenetre d'attente

INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- r3: 1 passager, arrive a 10:00 (dans fenetre [09:45-10:15])
(3, 2, 'r3_1pass', 1, '2026-03-27 10:00:00', 1),
-- r4: 7 passagers, arrive a 10:10 (dans fenetre [09:45-10:15])
(4, 2, 'r4_7pass', 7, '2026-03-27 10:10:00', 1),
-- r5: 5 passagers, arrive a 10:11 (juste apres r4)
(5, 3, 'r5_5pass', 5, '2026-03-27 10:11:00', 1);

-- Mise a jour de la sequence
SELECT setval('reservation_id_seq', 102);

-- ==========================================
-- 13. AFFICHAGE DES DONNEES INSEREES
-- ==========================================

SELECT '========================================' as info;
SELECT 'SPRINT 8 - DONNEES DE SIMULATION' as info;
SELECT '========================================' as info;

SELECT '--- PARAMETRES ---' as section;
SELECT key, value FROM parameters;

SELECT '--- LIEUX ---' as section;
SELECT id, code, libelle FROM lieu ORDER BY id;

SELECT '--- VEHICULES ---' as section;
SELECT id, reference, nb_place, type_carburant, heure_disponible_debut FROM vehicule ORDER BY id;

SELECT '--- DISTANCES (km) ---' as section;
SELECT l1.code as de, l2.code as vers, d.km_distance as km
FROM distance d
JOIN lieu l1 ON d.from_lieu_id = l1.id
JOIN lieu l2 ON d.to_lieu_id = l2.id
ORDER BY l1.code, l2.code;

SELECT '--- ATTRIBUTIONS PRE-EXISTANTES (vehicules en retour) ---' as section;
SELECT
    v.reference as vehicule,
    v.nb_place as places,
    v.type_carburant as carburant,
    a.date_heure_retour::time as heure_retour
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
WHERE a.id >= 100
ORDER BY a.date_heure_retour;

SELECT '--- RESERVATIONS A TRAITER ---' as section;
SELECT
    r.id,
    r.customer_id,
    r.passenger_nbr as passagers,
    r.arrival_date::time as arrivee,
    l.code as hotel,
    CASE
        WHEN r.arrival_date < '2026-03-27 09:45:00' THEN 'RESTE (prioritaire)'
        WHEN r.arrival_date BETWEEN '2026-03-27 09:45:00' AND '2026-03-27 10:15:00' THEN 'Fenetre [09:45-10:15]'
        ELSE 'Apres fenetre'
    END as statut
FROM reservation r
JOIN lieu l ON r.lieu_depart_id = l.id
WHERE r.id < 100
ORDER BY r.arrival_date;

SELECT '========================================' as info;
SELECT 'RESULTATS ATTENDUS (27/03/2026)' as info;
SELECT '========================================' as info;

SELECT 'Etape 1: v1 et v2 reviennent a 09:45' as etape;
SELECT 'Etape 2: v1 recoit r1(9p) + r2(1p) = 10p -> PART a 09:45' as etape;
SELECT 'Etape 3: v2 recoit r2(4p reste), fenetre [09:45-10:15] ouverte' as etape;
SELECT 'Etape 4: r4(7p) arrive, v2 recoit r4(6p) = 10p -> PART a 10:10' as etape;
SELECT 'Etape 5: v3 revient a 10:12' as etape;
SELECT 'Etape 6: v3 recoit r5(5p) + r4(1p reste) + r3(1p) = 7p -> PART a 10:11' as etape;

SELECT '========================================' as info;
SELECT 'Lancer: GET /api/planning/auto?date=2026-03-27' as info;
SELECT '========================================' as info;

-- ==========================================
-- 14. REQUETES DE VERIFICATION POST-PLANIFICATION
-- ==========================================

/*
-- Executer APRES la planification pour verifier les resultats

-- A. Vue des attributions creees
SELECT
    a.id,
    v.reference,
    STRING_AGG(r.customer_id, ' + ') as clients,
    SUM(a.nb_passagers_assignes) as passagers,
    a.date_heure_depart::time as depart
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
WHERE a.id > 102
GROUP BY a.id, v.reference, a.date_heure_depart
ORDER BY a.date_heure_depart;

-- B. Verification des divisions
SELECT
    r.customer_id,
    r.passenger_nbr as demande,
    COALESCE(SUM(a.nb_passagers_assignes), 0) as assigne,
    r.passenger_nbr - COALESCE(SUM(a.nb_passagers_assignes), 0) as reste
FROM reservation r
LEFT JOIN attribution a ON r.id = a.reservation_id
WHERE r.id < 100
GROUP BY r.id, r.customer_id, r.passenger_nbr
ORDER BY r.arrival_date;

-- C. Verification ordre de traitement
SELECT
    a.date_heure_depart::time as depart,
    v.reference,
    r.customer_id,
    r.arrival_date::time as arrivee_client,
    a.nb_passagers_assignes
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
WHERE a.id > 102
ORDER BY a.date_heure_depart, a.id;
*/
