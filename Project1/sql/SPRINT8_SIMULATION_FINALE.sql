-- ================================================================================
-- SPRINT 8 - SIMULATION FINALE AVEC TOUS LES SCENARIOS DETAILLES
-- ================================================================================
-- Auteur: ETU003240
-- Date: 2026-04-02
--
-- Ce script contient les donnees de test correspondant exactement aux scenarios
-- decrits dans SPRINT8_RESULTATS_ATTENDUS.md
--
-- SCENARIOS:
-- - JOUR 1 (27/03): Regroupement Optimal avec CLOSEST FIT
-- - JOUR 2 (28/03): Division Optimale avec CLOSEST FIT
-- - JOUR 3 (29/03): Retour Vehicule + Fenetres d'attente (cas complexe)
-- ================================================================================

-- Fermer les connexions actives
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'hotel_reservation' AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS hotel_reservation;
CREATE DATABASE hotel_reservation;

\c hotel_reservation

-- ==========================================
-- 1. NETTOYAGE
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
-- 2. TYPE ENUM
-- ==========================================
CREATE TYPE type_carburant_enum AS ENUM ('D', 'Es', 'H', 'El');

-- ==========================================
-- 3. CREATION DES TABLES
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
-- 4. INDEX
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
-- 5. PARAMETRES
-- ==========================================
INSERT INTO parameters (key, value) VALUES
('vitesse_moyenne', '50'),    -- 50 km/h
('temps_attente', '30');      -- 30 minutes fenetre d'attente

-- ==========================================
-- 6. LIEUX
-- ==========================================
INSERT INTO lieu (code, libelle, initial) VALUES
('IVATO', 'Aeroport Ivato', 'A'),       -- id = 1
('CARLTON', 'Hotel Carlton', 'B'),      -- id = 2
('COLBERT', 'Hotel Colbert', 'C');      -- id = 3

-- ==========================================
-- 7. DISTANCES (bidirectionnelles)
-- ==========================================
-- CARLTON -> IVATO: 25km = 30min aller + 30min retour = 60min total
-- COLBERT -> IVATO: 30km = 36min aller + 36min retour = 72min total (arrondi)

INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(1, 2, 25.00), (1, 3, 30.00),  -- Depuis IVATO
(2, 1, 25.00), (2, 3, 10.00),  -- Depuis CARLTON
(3, 1, 30.00), (3, 2, 10.00);  -- Depuis COLBERT

-- ==========================================
-- 8. VEHICULES (Sprint 8)
-- ==========================================
-- v1: 10 places, Diesel, toujours disponible
-- v2: 10 places, Essence, toujours disponible
-- v3: 12 places, Diesel, toujours disponible
-- v4: 8 places, Hybride, disponible a partir de 10:30 seulement

INSERT INTO vehicule (reference, nb_place, type_carburant, heure_disponible_debut) VALUES
('v1', 10, 'D',  NULL),
('v2', 10, 'Es', NULL),
('v3', 12, 'D',  NULL),
('v4', 8,  'H',  '10:30:00');

-- ==========================================
-- ==========================================
-- RESERVATIONS JOUR PAR JOUR
-- ==========================================
-- ==========================================

-- ====================================================================
-- JOUR 1: 27/03/2026 - REGROUPEMENT OPTIMAL (Closest Fit)
-- ====================================================================
--
-- FENETRE [07:40 - 08:10]
--
-- ETAPE 0: Tri DESC: r1(9) > r2(5) > r3(3) > r4(2)
--
-- ETAPE 1: Traiter r1(9) - LE MAXIMUM
--   CLOSEST FIT: v1(10) ecart=1, v2(10) ecart=1, v3(12) ecart=3
--   -> v1 choisie (diesel prioritaire)
--   -> v1 prend r1(9), reste 1 place
--
--   Regroupement v1 (1 place):
--   r4(2): |1-2|=1 (MIN), r3(3): |1-3|=2, r2(5): |1-5|=4
--   -> v1 prend 1 de r4 = 10 PLEIN
--   -> v1 depart 08:00, retour 09:00
--
-- ETAPE 2: Traiter r2(5)
--   CLOSEST FIT: v2(10) ecart=5, v3(12) ecart=7
--   -> v2 choisie
--
--   Regroupement v2 (5 places):
--   r3(3): |5-3|=2 (MIN), r4_reste(1): |5-1|=4
--   -> v2 prend r3(3), reste 2 places
--
--   Regroupement v2 (2 places):
--   r4_reste(1): |2-1|=1
--   -> v2 prend r4_reste(1), total=9
--   -> v2 depart 08:00, retour 09:00
--
-- RESULTAT JOUR 1:
-- | v1 | r1(9)+r4(1) | 10 | 08:00 | 09:00 |
-- | v2 | r2(5)+r3(3)+r4(1) | 9 | 08:00 | 09:00 |

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(2, 'J1_r1_9pass',   9, '2026-03-27 08:00:00', 1),  -- id=1
(2, 'J1_r2_5pass',   5, '2026-03-27 07:55:00', 1),  -- id=2
(2, 'J1_r3_3pass',   3, '2026-03-27 07:50:00', 1),  -- id=3
(2, 'J1_r4_2pass',   2, '2026-03-27 07:40:00', 1);  -- id=4

-- ====================================================================
-- JOUR 2: 28/03/2026 - DIVISION OPTIMALE
-- ====================================================================
--
-- r1(20) arrive a 09:00
--
-- ETAPE 1: Division necessaire (20 > 12 max)
--   CLOSEST FIT: v3(12) ecart=8, v1(10) ecart=10, v2(10) ecart=10
--   -> v3 choisie (ecart minimum)
--   -> v3 prend 12 passagers, reste 8
--
-- ETAPE 2: 8 passagers restants
--   CLOSEST FIT: v1(10) ecart=2, v2(10) ecart=2
--   -> v1 choisie (diesel prioritaire)
--   -> v1 prend 8 passagers
--
-- RESULTAT JOUR 2:
-- | v3 | r1(partie1) | 12 | 09:00 | 10:00 |
-- | v1 | r1(partie2) | 8 | 09:00 | 10:00 |

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(2, 'J2_r1_20pass', 20, '2026-03-28 09:00:00', 1);  -- id=5

-- ====================================================================
-- JOUR 3: 29/03/2026 - RETOUR VEHICULE + FENETRE D'ATTENTE (CAS COMPLEXE)
-- ====================================================================
--
-- FENETRE 1 [07:00 - 07:30]
-- Reservations: r1(10), r2(10), r3(12)
-- Tri DESC: r3(12) > r1(10) = r2(10)
--
-- ETAPE 1: r3(12) -> v3(12) ecart=0 PARFAIT, v3 depart 07:00
-- ETAPE 2: r1(10) -> v1(10) ecart=0 (diesel), v1 depart 07:00
-- ETAPE 3: r2(10) -> v2(10) ecart=0, v2 depart 07:00
--
-- r4(9) arrive 07:30 - HORS fenetre [07:00-07:30]
-- r5(5) arrive 07:45 - HORS fenetre [07:00-07:30]
--
-- FENETRE 2 [07:45 - 08:15] (issue de r5 arrivee)
-- Vehicules: v3(12) retourne a 08:00 (environ, depuis COLBERT ~08:12)
-- Prioritaires: r4(9) avant 07:45
--
-- -> r4(9) assigne a v3(12), reste 3 places
-- -> Regroupement: r5(5) vs r6(7)?
--    r5(5): |3-5|=2, r6(7): |3-7|=4
--    -> v3 prend 3 de r5 = PLEIN
-- -> r5(2) reste non assigne
-- -> v3 depart 07:45
--
-- A 08:00: v1, v2, v3 retournent
-- Prioritaire: r5(2 restant)
-- -> v1(10): |10-2|=8, v2(10): |10-2|=8
-- -> v1 choisie (diesel prioritaire), r5(2) assigne
-- -> v1(8) places restantes -> fenetre groupement [08:00-08:30]
--
-- FENETRE 3 [08:00 - 08:30]
-- r6(7) arrive 08:15, r7(8) arrive 08:20
--
-- -> v1(8 places): r7(8) |8-8|=0 > r6(7) |8-7|=1
-- -> r7 assigne a v1 = PLEIN
-- -> v1 depart 08:20
--
-- -> v2(10 places): r6(7)
-- -> r6 assigne a v2, reste 3 places
-- -> Plus de reservations dans fenetre
-- -> v2 depart 08:20
--
-- v3 pas assigne dans cette fenetre (dispo pour prochain)
--
-- RESULTAT JOUR 3:
-- | v3 | r3(12) | 12 | 07:00 | 08:12 | (depuis COLBERT)
-- | v1 | r1(10) | 10 | 07:00 | 08:00 |
-- | v2 | r2(10) | 10 | 07:00 | 08:00 |
-- | v3 | r4(9)+r5(3) | 12 | 07:45 | ~08:45 |
-- | v1 | r5(2)+r7(8) | 10 | 08:20 | 09:20 |
-- | v2 | r6(7) | 7 | 08:20 | 09:20 |

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- Reservations dans fenetre [07:00 - 07:30]
(2, 'J3_r1_10pass_MATIN',  10, '2026-03-29 07:00:00', 1),  -- id=6
(2, 'J3_r2_10pass_MATIN',  10, '2026-03-29 07:00:00', 1),  -- id=7
(3, 'J3_r3_12pass_MATIN',  12, '2026-03-29 07:00:00', 1),  -- id=8 (depuis COLBERT)

-- Reservations hors premiere fenetre (prioritaires pour fenetre suivante)
(2, 'J3_r4_9pass_RESTE',    9, '2026-03-29 07:30:00', 1),  -- id=9
(2, 'J3_r5_5pass_RESTE',    5, '2026-03-29 07:45:00', 1),  -- id=10

-- Nouvelles arrivees dans fenetre [08:00-08:30]
(2, 'J3_r6_7pass',          7, '2026-03-29 08:15:00', 1),  -- id=11
(2, 'J3_r7_8pass',          8, '2026-03-29 08:20:00', 1);  -- id=12

-- ==========================================
-- RESET SEQUENCE
-- ==========================================
SELECT setval('reservation_id_seq', (SELECT MAX(id) FROM reservation));

-- ==========================================
-- AFFICHAGE DES DONNEES INSEREES
-- ==========================================

SELECT '========================================' as info;
SELECT 'SPRINT 8 - SIMULATION FINALE' as titre;
SELECT '========================================' as info;

SELECT '--- VEHICULES ---' as section;
SELECT id, reference, nb_place, type_carburant,
       COALESCE(heure_disponible_debut::text, 'Toujours dispo') as disponibilite
FROM vehicule ORDER BY id;

SELECT '--- RESERVATIONS PAR JOUR ---' as section;

SELECT '>> JOUR 1 (27/03) - Regroupement Optimal' as jour;
SELECT id, customer_id, passenger_nbr, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-03-27' ORDER BY arrival_date;

SELECT '>> JOUR 2 (28/03) - Division Optimale' as jour;
SELECT id, customer_id, passenger_nbr, arrival_date::time as heure
FROM reservation WHERE arrival_date::date = '2026-03-28' ORDER BY arrival_date;

SELECT '>> JOUR 3 (29/03) - Retour Vehicule + Fenetre' as jour;
SELECT id, customer_id, passenger_nbr, arrival_date::time as heure,
       CASE
           WHEN arrival_date::time < '07:30' THEN 'Fenetre 1 [07:00-07:30]'
           WHEN arrival_date::time < '08:00' THEN 'Hors fenetre (prioritaire suivant)'
           ELSE 'Fenetre 3 [08:00-08:30]'
       END as note
FROM reservation WHERE arrival_date::date = '2026-03-29' ORDER BY arrival_date;

SELECT '========================================' as info;
SELECT 'WORKFLOW DE TEST:' as workflow;
SELECT '1. GET /api/planning/auto?date=2026-03-27' as etape1;
SELECT '2. GET /api/planning/auto?date=2026-03-28' as etape2;
SELECT '3. GET /api/planning/auto?date=2026-03-29' as etape3;
SELECT '========================================' as info;

-- ==========================================
-- RESULTATS ATTENDUS PAR JOUR
-- ==========================================

SELECT '===========================================' as info;
SELECT 'RESULTATS ATTENDUS JOUR 1 (27/03)' as titre;
SELECT '===========================================' as info;
SELECT 'v1: r1(9) + r4(1) = 10 passagers, depart 08:00' as resultat1;
SELECT 'v2: r2(5) + r3(3) + r4(1) = 9 passagers, depart 08:00' as resultat2;
SELECT 'Total: 19 passagers assignes' as total;

SELECT '===========================================' as info;
SELECT 'RESULTATS ATTENDUS JOUR 2 (28/03)' as titre;
SELECT '===========================================' as info;
SELECT 'v3: r1(partie1) = 12 passagers, depart 09:00' as resultat1;
SELECT 'v1: r1(partie2) = 8 passagers, depart 09:00' as resultat2;
SELECT 'Total: 20 passagers assignes (1 reservation divisee)' as total;

SELECT '===========================================' as info;
SELECT 'RESULTATS ATTENDUS JOUR 3 (29/03)' as titre;
SELECT '===========================================' as info;
SELECT 'Fenetre 1 [07:00-07:30]:' as fenetre1;
SELECT '  v3: r3(12) = 12 pass, depart 07:00' as f1_r1;
SELECT '  v1: r1(10) = 10 pass, depart 07:00' as f1_r2;
SELECT '  v2: r2(10) = 10 pass, depart 07:00' as f1_r3;
SELECT 'Fenetre 2 [07:45-08:15]:' as fenetre2;
SELECT '  v3: r4(9) + r5(3) = 12 pass, depart 07:45' as f2_r1;
SELECT '  r5(2) reste non assigne' as f2_reste;
SELECT 'Fenetre 3 [08:00-08:30]:' as fenetre3;
SELECT '  v1: r5(2) + r7(8) = 10 pass, depart 08:20' as f3_r1;
SELECT '  v2: r6(7) = 7 pass, depart 08:20' as f3_r2;
SELECT 'Total: 61 passagers assignes' as total;

-- ==========================================
-- REQUETES DE VERIFICATION
-- ==========================================

/*
-- A. Voir toutes les attributions apres test
SELECT
    a.id,
    v.reference as vehicule,
    r.customer_id,
    a.nb_passagers_assignes as passagers,
    a.date_heure_depart::time as depart,
    a.date_heure_retour::time as retour,
    a.statut
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
ORDER BY a.date_heure_depart;

-- B. Resume par reservation
SELECT
    r.id,
    r.customer_id,
    r.passenger_nbr as demande,
    COALESCE(SUM(a.nb_passagers_assignes), 0) as assigne,
    r.passenger_nbr - COALESCE(SUM(a.nb_passagers_assignes), 0) as reste,
    CASE
        WHEN r.passenger_nbr = COALESCE(SUM(a.nb_passagers_assignes), 0) THEN 'COMPLET'
        WHEN COALESCE(SUM(a.nb_passagers_assignes), 0) > 0 THEN 'PARTIEL'
        ELSE 'NON ASSIGNE'
    END as statut
FROM reservation r
LEFT JOIN attribution a ON r.id = a.reservation_id
GROUP BY r.id, r.customer_id, r.passenger_nbr
ORDER BY r.arrival_date;

-- C. Attributions par jour
SELECT
    a.date_heure_depart::date as jour,
    COUNT(*) as nb_attributions,
    SUM(a.nb_passagers_assignes) as total_passagers
FROM attribution a
GROUP BY a.date_heure_depart::date
ORDER BY jour;

-- D. Verification v4 (disponibilite horaire)
SELECT
    v.reference,
    a.date_heure_depart::time as depart,
    v.heure_disponible_debut,
    CASE
        WHEN v.heure_disponible_debut IS NULL THEN 'OK (toujours dispo)'
        WHEN a.date_heure_depart::time >= v.heure_disponible_debut THEN 'OK'
        ELSE 'ERREUR: Depart avant disponibilite!'
    END as verification
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
WHERE v.reference = 'v4';
*/
