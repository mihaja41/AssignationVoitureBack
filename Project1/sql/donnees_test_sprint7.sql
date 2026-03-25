-- ================================================================================
-- SPRINT 7 - DONNEES DE TEST COMPLETES
-- ================================================================================
-- Auteur: ETU003240
-- Date: 2026-03-19
-- Description: Donnees de test pour valider toutes les fonctionnalites Sprint 7
-- ================================================================================
-- Usage: psql -U postgres -d hotel_reservation -f donnees_test_sprint7.sql
-- Note: Executer APRES reinit_sprint7_complet.sql
-- ================================================================================

-- ==========================================
-- 1. LIEUX (Aeroport + Hotels)
-- ==========================================

INSERT INTO lieu (code, libelle, initial) VALUES
('IVATO',    'Aeroport Ivato',           'A'),    -- id = 1
('CARLTON', 'Hotel Carlton Antananarivo', 'B'),   -- id = 2
('COLBERT', 'Hotel Colbert',              'C'),   -- id = 3
('IBIS',    'Hotel Ibis Ankorondrano',    'D'),   -- id = 4
('TAMANA',  'Hotel Tamana',               'E'),   -- id = 5
('SAKAMANGA','Hotel Sakamanga',           'F'),   -- id = 6
('RADISSON','Radisson Blu',               'G'),   -- id = 7
('LOUVRE',  'Hotel du Louvre',            'H');   -- id = 8

-- ==========================================
-- 2. DISTANCES (Aller-Retour pour chaque paire)
-- ==========================================

-- Depuis IVATO (id=1) vers tous les hotels
INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(1, 2, 25.00),   -- IVATO -> CARLTON
(1, 3, 22.00),   -- IVATO -> COLBERT
(1, 4, 18.00),   -- IVATO -> IBIS
(1, 5, 30.00),   -- IVATO -> TAMANA
(1, 6, 20.00),   -- IVATO -> SAKAMANGA
(1, 7, 28.00),   -- IVATO -> RADISSON
(1, 8, 35.00);   -- IVATO -> LOUVRE

-- Retours (hotels vers IVATO)
INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(2, 1, 25.00),   -- CARLTON -> IVATO
(3, 1, 22.00),   -- COLBERT -> IVATO
(4, 1, 18.00),   -- IBIS -> IVATO
(5, 1, 30.00),   -- TAMANA -> IVATO
(6, 1, 20.00),   -- SAKAMANGA -> IVATO
(7, 1, 28.00),   -- RADISSON -> IVATO
(8, 1, 35.00);   -- LOUVRE -> IVATO

-- Distances entre hotels (pour le regroupement)
INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(2, 3, 5.00),    -- CARLTON -> COLBERT
(3, 2, 5.00),    -- COLBERT -> CARLTON
(2, 4, 8.00),    -- CARLTON -> IBIS
(4, 2, 8.00),    -- IBIS -> CARLTON
(3, 4, 6.00),    -- COLBERT -> IBIS
(4, 3, 6.00),    -- IBIS -> COLBERT
(4, 5, 12.00),   -- IBIS -> TAMANA
(5, 4, 12.00),   -- TAMANA -> IBIS
(5, 6, 10.00),   -- TAMANA -> SAKAMANGA
(6, 5, 10.00),   -- SAKAMANGA -> TAMANA
(6, 7, 8.00),    -- SAKAMANGA -> RADISSON
(7, 6, 8.00),    -- RADISSON -> SAKAMANGA
(7, 8, 7.00),    -- RADISSON -> LOUVRE
(8, 7, 7.00);    -- LOUVRE -> RADISSON

-- ==========================================
-- 3. VEHICULES (Mix de capacites et carburants)
-- ==========================================

-- Vehicules pour tests de division
INSERT INTO vehicule (reference, nb_place, type_carburant) VALUES
-- Grands vehicules (12 places)
('BUS-001',  12, 'D'),    -- id=1: Diesel, 12 places
('BUS-002',  12, 'Es'),   -- id=2: Essence, 12 places

-- Vehicules moyens (5 places)
('VAN-001',  5, 'D'),     -- id=3: Diesel, 5 places
('VAN-002',  5, 'D'),     -- id=4: Diesel, 5 places
('VAN-003',  5, 'Es'),    -- id=5: Essence, 5 places
('VAN-004',  5, 'H'),     -- id=6: Hybride, 5 places

-- Petits vehicules (3 places)
('CAR-001',  3, 'D'),     -- id=7: Diesel, 3 places
('CAR-002',  3, 'El'),    -- id=8: Electrique, 3 places

-- Vehicule special (7 places)
('MINI-001', 7, 'D');     -- id=9: Diesel, 7 places

-- ==========================================
-- 4. RESERVATIONS - SCENARIO 1: DIVISION SIMPLE
-- Date: 2026-03-20
-- ==========================================
-- Test: 8 passagers, aucun vehicule >= 8 places disponible (max 5)
-- Attendu: Division en 2 vehicules (5 + 3)

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'SCENARIO1_CLIENT1', 8, '2026-03-20 09:00:00', 2);   -- id=1: 8 passagers -> CARLTON

-- ==========================================
-- 5. RESERVATIONS - SCENARIO 2: DIVISION AVEC REGROUPEMENT
-- Date: 2026-03-21
-- ==========================================
-- Test: Grande reservation divisee + petites reservations regroupees
-- R1: 15 passagers (division requise)
-- R2: 4 passagers (peut etre regroupe)
-- R3: 2 passagers (peut etre regroupe)

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'SCENARIO2_CLIENT1', 15, '2026-03-21 10:00:00', 2),  -- id=2: 15 passagers -> CARLTON
(1, 'SCENARIO2_CLIENT2', 4,  '2026-03-21 10:15:00', 3),  -- id=3: 4 passagers -> COLBERT
(1, 'SCENARIO2_CLIENT3', 2,  '2026-03-21 10:20:00', 2);  -- id=4: 2 passagers -> CARLTON (meme lieu que R1)

-- ==========================================
-- 6. RESERVATIONS - SCENARIO 3: DIVISION AVEC REPORT PARTIEL
-- Date: 2026-03-22
-- ==========================================
-- Test: Reservation trop grande pour TOUS les vehicules disponibles
-- 30 passagers > capacite totale disponible
-- Attendu: Assigner max possible, reporter le reste

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'SCENARIO3_CLIENT1', 30, '2026-03-22 11:00:00', 4);  -- id=5: 30 passagers -> IBIS

-- ==========================================
-- 7. RESERVATIONS - SCENARIO 4: CRITERES DE SELECTION
-- Date: 2026-03-23
-- ==========================================
-- Test des criteres: ecart min, moins de trajets, diesel prioritaire
-- 3 reservations identiques pour tester l'equilibrage

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'SCENARIO4_CLIENT1', 4, '2026-03-23 08:00:00', 5),   -- id=6: 4 passagers -> TAMANA
(1, 'SCENARIO4_CLIENT2', 4, '2026-03-23 08:05:00', 6),   -- id=7: 4 passagers -> SAKAMANGA
(1, 'SCENARIO4_CLIENT3', 4, '2026-03-23 08:10:00', 7);   -- id=8: 4 passagers -> RADISSON

-- ==========================================
-- 8. RESERVATIONS - SCENARIO 5: FENETRE DE REGROUPEMENT
-- Date: 2026-03-24
-- ==========================================
-- Test du regroupement dans la meme fenetre de temps (30 min)
-- Toutes ces reservations sont dans le meme temps_attente

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'SCENARIO5_CLIENT1', 3, '2026-03-24 14:00:00', 2),   -- id=9:  3 passagers -> CARLTON
(1, 'SCENARIO5_CLIENT2', 2, '2026-03-24 14:10:00', 2),   -- id=10: 2 passagers -> CARLTON (meme lieu)
(1, 'SCENARIO5_CLIENT3', 4, '2026-03-24 14:20:00', 3),   -- id=11: 4 passagers -> COLBERT
(1, 'SCENARIO5_CLIENT4', 1, '2026-03-24 14:25:00', 2);   -- id=12: 1 passager -> CARLTON (meme lieu)

-- ==========================================
-- 9. RESERVATIONS - SCENARIO 6: ASSIGNATION COMPLETE (PAS DE DIVISION)
-- Date: 2026-03-25
-- ==========================================
-- Test: Reservations qui rentrent dans un seul vehicule
-- Pas de division necessaire

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'SCENARIO6_CLIENT1', 5, '2026-03-25 09:00:00', 4),   -- id=13: 5 passagers -> IBIS
(1, 'SCENARIO6_CLIENT2', 3, '2026-03-25 09:30:00', 5);   -- id=14: 3 passagers -> TAMANA

-- ==========================================
-- 10. RESERVATIONS - SCENARIO 7: PRIORITE DIESEL
-- Date: 2026-03-26
-- ==========================================
-- Test: Plusieurs vehicules avec meme ecart, diesel doit etre prefere

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'SCENARIO7_CLIENT1', 5, '2026-03-26 10:00:00', 8);   -- id=15: 5 passagers -> LOUVRE

-- ==========================================
-- 11. RESERVATIONS - SCENARIO 8: CONFLIT HORAIRE
-- Date: 2026-03-27
-- ==========================================
-- Test: Deux reservations, le vehicule revient juste a temps pour la 2eme
-- R1: 09:00 (depart) -> retour vers 10:00
-- R2: 10:30 (depart) -> vehicule libere et disponible

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'SCENARIO8_CLIENT1', 4, '2026-03-27 09:00:00', 2),   -- id=16: 4 passagers -> CARLTON
(1, 'SCENARIO8_CLIENT2', 4, '2026-03-27 10:30:00', 3);   -- id=17: 4 passagers -> COLBERT

-- ==========================================
-- 12. RESERVATIONS - SCENARIO 9: MULTI-FENETRES
-- Date: 2026-03-28
-- ==========================================
-- Test: Reservations dans plusieurs fenetres distinctes (> 30 min d'ecart)

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'SCENARIO9_F1_CLIENT1', 6, '2026-03-28 08:00:00', 2),   -- id=18: Fenetre 1 - 6 passagers
(1, 'SCENARIO9_F1_CLIENT2', 3, '2026-03-28 08:15:00', 3),   -- id=19: Fenetre 1 - 3 passagers
(1, 'SCENARIO9_F2_CLIENT1', 7, '2026-03-28 10:00:00', 4),   -- id=20: Fenetre 2 - 7 passagers
(1, 'SCENARIO9_F2_CLIENT2', 2, '2026-03-28 10:10:00', 5);   -- id=21: Fenetre 2 - 2 passagers

-- ==========================================
-- 13. VERIFICATIONS FINALES
-- ==========================================

SELECT '=== DONNEES DE TEST INSEREES ===' AS message;

SELECT '--- RESUME PAR SCENARIO ---' AS info;

SELECT
    DATE(arrival_date) AS date_test,
    CASE
        WHEN DATE(arrival_date) = '2026-03-20' THEN 'SCENARIO 1: Division Simple'
        WHEN DATE(arrival_date) = '2026-03-21' THEN 'SCENARIO 2: Division + Regroupement'
        WHEN DATE(arrival_date) = '2026-03-22' THEN 'SCENARIO 3: Division + Report Partiel'
        WHEN DATE(arrival_date) = '2026-03-23' THEN 'SCENARIO 4: Criteres Selection'
        WHEN DATE(arrival_date) = '2026-03-24' THEN 'SCENARIO 5: Fenetre Regroupement'
        WHEN DATE(arrival_date) = '2026-03-25' THEN 'SCENARIO 6: Assignation Complete'
        WHEN DATE(arrival_date) = '2026-03-26' THEN 'SCENARIO 7: Priorite Diesel'
        WHEN DATE(arrival_date) = '2026-03-27' THEN 'SCENARIO 8: Conflit Horaire'
        WHEN DATE(arrival_date) = '2026-03-28' THEN 'SCENARIO 9: Multi-Fenetres'
        ELSE 'AUTRE'
    END AS scenario,
    COUNT(*) AS nb_reservations,
    SUM(passenger_nbr) AS total_passagers
FROM reservation
GROUP BY DATE(arrival_date)
ORDER BY date_test;

SELECT '--- VEHICULES DISPONIBLES ---' AS info;

SELECT reference, nb_place, type_carburant
FROM vehicule
ORDER BY nb_place DESC, type_carburant;

SELECT '--- CAPACITE TOTALE ---' AS info;

SELECT
    SUM(nb_place) AS capacite_totale,
    SUM(CASE WHEN type_carburant = 'D' THEN nb_place ELSE 0 END) AS places_diesel,
    SUM(CASE WHEN type_carburant != 'D' THEN nb_place ELSE 0 END) AS places_autres
FROM vehicule;

SELECT '=== PRET POUR LES TESTS ===' AS message;
