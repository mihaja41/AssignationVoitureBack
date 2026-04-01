-- ================================================================================
-- SPRINT 8 - SIMULATION SQL COMPLETE
-- ================================================================================
-- Date de simulation: 27/03/2026
-- Ce script reproduit exactement l'exemple de la specification Sprint 8
-- ================================================================================
-- Usage: psql -U postgres -d hotel_reservation -f SPRINT8_SIMULATION.sql
-- ================================================================================

-- ==========================================
-- 1. NETTOYAGE COMPLET
-- ==========================================

DELETE FROM attribution;
DELETE FROM reservation;
DELETE FROM distance;
DELETE FROM vehicule;
DELETE FROM lieu;

-- Reset des sequences
ALTER SEQUENCE IF EXISTS lieu_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS vehicule_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS reservation_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS attribution_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS distance_id_seq RESTART WITH 1;

-- ==========================================
-- 2. PARAMETRES
-- ==========================================

DELETE FROM parameters WHERE key IN ('vitesse_moyenne', 'temps_attente');
INSERT INTO parameters (key, value) VALUES
('vitesse_moyenne', '50'),    -- 50 km/h
('temps_attente', '30')       -- 30 minutes fenetre d'attente
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- ==========================================
-- 3. LIEUX
-- ==========================================

INSERT INTO lieu (id, code, libelle, initial) VALUES
(1, 'IVATO', 'Aeroport Ivato', 'A'),
(2, 'CARLTON', 'Hotel Carlton', 'B'),
(3, 'COLBERT', 'Hotel Colbert', 'C');

SELECT setval('lieu_id_seq', 3);

-- ==========================================
-- 4. DISTANCES (aller-retour)
-- ==========================================

INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(1, 2, 25.00),   -- IVATO -> CARLTON
(1, 3, 30.00),   -- IVATO -> COLBERT
(2, 1, 25.00),   -- CARLTON -> IVATO
(2, 3, 10.00),   -- CARLTON -> COLBERT
(3, 1, 30.00),   -- COLBERT -> IVATO
(3, 2, 10.00);   -- COLBERT -> CARLTON

-- ==========================================
-- 5. VEHICULES
-- ==========================================
-- v1, v2, v3 comme dans la specification
-- v4 pour tester heure_disponible_debut

INSERT INTO vehicule (id, reference, nb_place, type_carburant, heure_disponible_debut) VALUES
(1, 'v1', 10, 'D',  NULL),        -- Diesel, toujours disponible
(2, 'v2', 10, 'Es', NULL),        -- Essence, toujours disponible
(3, 'v3', 12, 'D',  NULL),        -- Diesel, toujours disponible
(4, 'v4', 8,  'H',  '10:30:00');  -- Hybride, disponible a partir de 10:30

SELECT setval('vehicule_id_seq', 4);

-- ==========================================
-- 6. ATTRIBUTIONS PRE-EXISTANTES
-- ==========================================
-- Simule les vehicules "en course" qui vont revenir

-- Reservation fictive pour les attributions initiales (trajet precedent)
INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(100, 2, 'TRAJET_PRECEDENT_V1', 10, '2026-03-27 07:00:00', 1),
(101, 2, 'TRAJET_PRECEDENT_V2', 10, '2026-03-27 07:00:00', 1),
(102, 3, 'TRAJET_PRECEDENT_V3', 12, '2026-03-27 07:30:00', 1);

-- Attributions qui simulent les vehicules en course
INSERT INTO attribution (id, reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes) VALUES
-- v1 revient a 09:45
(100, 100, 1, '2026-03-27 08:45:00', '2026-03-27 09:45:00', 'EN_COURS', 10),
-- v2 revient a 09:45
(101, 101, 2, '2026-03-27 08:45:00', '2026-03-27 09:45:00', 'EN_COURS', 10),
-- v3 revient a 10:12
(102, 102, 3, '2026-03-27 09:00:00', '2026-03-27 10:12:00', 'EN_COURS', 12);

SELECT setval('attribution_id_seq', 102);

-- ==========================================
-- 7. RESERVATIONS - RESTES NON ASSIGNES
-- ==========================================
-- r1 et r2 sont des "restes" de reservations precedentes
-- Ils arrivent AVANT le retour des vehicules (09:45)

INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- r1: 9 passagers, arrive a 08:00 (reste non assigne)
(1, 2, 'CLI001_RESTE', 9, '2026-03-27 08:00:00', 1),
-- r2: 5 passagers, arrive a 07:30 (reste non assigne)
(2, 2, 'CLI002_RESTE', 5, '2026-03-27 07:30:00', 1);

-- ==========================================
-- 8. RESERVATIONS - NOUVELLES ARRIVEES
-- ==========================================
-- Arrivent pendant ou apres la fenetre d'attente

INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- r3: 1 passager, arrive a 10:00 (dans fenetre [09:45-10:15])
(3, 2, 'CLI003', 1, '2026-03-27 10:00:00', 1),
-- r4: 7 passagers, arrive a 10:10 (dans fenetre [09:45-10:15])
(4, 2, 'CLI004', 7, '2026-03-27 10:10:00', 1),
-- r5: 5 passagers, arrive a 10:11 (dans fenetre [09:45-10:15])
(5, 3, 'CLI005', 5, '2026-03-27 10:11:00', 1);

SELECT setval('reservation_id_seq', 102);

-- ==========================================
-- 9. SCENARIOS ADDITIONNELS (autres dates)
-- ==========================================

-- SCENARIO A: Test heure_disponible_debut (28/03/2026)
INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(6, 2, 'CLI006_AVANT_DISPO', 4, '2026-03-28 10:00:00', 1),  -- v4 pas encore dispo
(7, 2, 'CLI007_APRES_DISPO', 4, '2026-03-28 10:35:00', 1);  -- v4 maintenant dispo

-- SCENARIO B: Grande reservation avec division (29/03/2026)
INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(8, 2, 'CLI008_GRANDE', 25, '2026-03-29 09:00:00', 1);  -- Necessite plusieurs vehicules

-- SCENARIO C: Plusieurs petites reservations (30/03/2026)
INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(9, 2, 'CLI009_PETIT_A', 2, '2026-03-30 09:00:00', 1),
(10, 2, 'CLI010_PETIT_B', 3, '2026-03-30 09:05:00', 1),
(11, 3, 'CLI011_PETIT_C', 4, '2026-03-30 09:10:00', 1),
(12, 2, 'CLI012_PETIT_D', 1, '2026-03-30 09:15:00', 1);

-- SCENARIO D: Reservations espacees (31/03/2026)
INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(13, 2, 'CLI013_MATIN', 8, '2026-03-31 08:00:00', 1),
(14, 3, 'CLI014_MIDI', 6, '2026-03-31 12:00:00', 1),
(15, 2, 'CLI015_APREM', 10, '2026-03-31 15:00:00', 1);

-- SCENARIO E: Cas extreme - beaucoup de passagers (01/04/2026)
INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(16, 2, 'CLI016_GROUPE_A', 15, '2026-04-01 09:00:00', 1),
(17, 2, 'CLI017_GROUPE_B', 12, '2026-04-01 09:10:00', 1),
(18, 3, 'CLI018_GROUPE_C', 20, '2026-04-01 09:20:00', 1);

SELECT setval('reservation_id_seq', 18);

-- ==========================================
-- 10. AFFICHAGE DES DONNEES
-- ==========================================

SELECT '========================================' as info;
SELECT 'DONNEES CHARGEES POUR SIMULATION' as info;
SELECT '========================================' as info;

SELECT '--- PARAMETRES ---' as section;
SELECT key, value FROM parameters WHERE key IN ('vitesse_moyenne', 'temps_attente');

SELECT '--- LIEUX ---' as section;
SELECT id, code, libelle FROM lieu ORDER BY id;

SELECT '--- VEHICULES ---' as section;
SELECT id, reference, nb_place, type_carburant, heure_disponible_debut FROM vehicule ORDER BY id;

SELECT '--- DISTANCES ---' as section;
SELECT l1.code as de, l2.code as vers, d.km_distance as km
FROM distance d
JOIN lieu l1 ON d.from_lieu_id = l1.id
JOIN lieu l2 ON d.to_lieu_id = l2.id
ORDER BY l1.code, l2.code;

SELECT '--- ATTRIBUTIONS PRE-EXISTANTES (vehicules en course) ---' as section;
SELECT
    a.id,
    v.reference as vehicule,
    r.customer_id,
    a.date_heure_depart::time as depart,
    a.date_heure_retour::time as retour_prevu,
    a.statut
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
WHERE a.id >= 100
ORDER BY a.date_heure_retour;

SELECT '--- RESERVATIONS A TRAITER PAR DATE ---' as section;
SELECT
    DATE(arrival_date) as date_jour,
    COUNT(*) as nb_reservations,
    SUM(passenger_nbr) as total_passagers,
    STRING_AGG(customer_id || '(' || passenger_nbr || 'p)', ', ' ORDER BY arrival_date) as detail
FROM reservation
WHERE id < 100  -- Exclure les trajets precedents fictifs
GROUP BY DATE(arrival_date)
ORDER BY date_jour;

SELECT '========================================' as info;
SELECT 'SIMULATION PRINCIPALE: 27/03/2026' as info;
SELECT '========================================' as info;

SELECT '--- RESERVATIONS DU 27/03/2026 ---' as section;
SELECT
    r.id,
    r.customer_id,
    r.passenger_nbr as passagers,
    r.arrival_date::time as arrivee,
    l.code as hotel,
    CASE
        WHEN r.arrival_date < '2026-03-27 09:45:00' THEN 'RESTE (prioritaire)'
        WHEN r.arrival_date >= '2026-03-27 09:45:00' AND r.arrival_date <= '2026-03-27 10:15:00' THEN 'Dans fenetre [09:45-10:15]'
        ELSE 'Apres fenetre'
    END as statut_fenetre
FROM reservation r
JOIN lieu l ON r.lieu_depart_id = l.id
WHERE DATE(r.arrival_date) = '2026-03-27'
  AND r.id < 100
ORDER BY r.arrival_date;

SELECT '========================================' as info;
SELECT 'RESULTATS ATTENDUS (27/03/2026)' as info;
SELECT '========================================' as info;

SELECT 'Attribution 1: v1 recoit r1(9p) + r2(1p) = 10p -> PART a 09:45' as resultat_attendu;
SELECT 'Attribution 2: v2 recoit r2(4p) + r4(6p) = 10p -> PART a 10:10' as resultat_attendu;
SELECT 'Attribution 3: v3 recoit r5(5p) + r4(1p) + r3(1p) = 7p -> PART a 10:11' as resultat_attendu;

SELECT '========================================' as info;
SELECT 'Pret pour lancer la planification!' as info;
SELECT 'API: GET /api/planning/auto?date=2026-03-27' as info;
SELECT '========================================' as info;

-- ==========================================
-- 11. REQUETES DE VERIFICATION POST-PLANIFICATION
-- ==========================================

/*
-- A executer APRES la planification

-- Verification des attributions creees
SELECT
    a.id,
    v.reference,
    STRING_AGG(r.customer_id, ' + ') as clients,
    SUM(a.nb_passagers_assignes) as total_passagers,
    a.date_heure_depart::time as depart
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
WHERE DATE(a.date_heure_depart) = '2026-03-27'
  AND a.id > 102  -- Nouvelles attributions seulement
GROUP BY a.id, v.reference, a.date_heure_depart
ORDER BY a.date_heure_depart;

-- Verification que toutes les reservations sont assignees
SELECT
    r.id,
    r.customer_id,
    r.passenger_nbr as demande,
    COALESCE(SUM(a.nb_passagers_assignes), 0) as assigne,
    r.passenger_nbr - COALESCE(SUM(a.nb_passagers_assignes), 0) as reste
FROM reservation r
LEFT JOIN attribution a ON r.id = a.reservation_id
WHERE DATE(r.arrival_date) = '2026-03-27'
  AND r.id < 100
GROUP BY r.id, r.customer_id, r.passenger_nbr
ORDER BY r.arrival_date;

-- Verification de l'ordre de traitement (prioritaires en premier)
SELECT
    a.date_heure_depart,
    v.reference,
    r.customer_id,
    r.arrival_date::time as arrivee_client,
    a.nb_passagers_assignes
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
WHERE DATE(a.date_heure_depart) = '2026-03-27'
  AND a.id > 102
ORDER BY a.date_heure_depart, a.id;
*/
