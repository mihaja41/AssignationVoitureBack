-- ================================================================================
-- SPRINT 8 - SCRIPT SQL COMPLET POUR TESTS
-- ================================================================================
-- Auteur: Assistant IA
-- Date: 2026-04-01
-- Description: Donnees de test completes pour valider toutes les fonctionnalites
--              du Sprint 8 (Regroupement optimal, Division optimale, Disponibilite
--              horaire, Fenetres de retour, Gestion des restes)
-- ================================================================================
-- Usage: psql -U postgres -d hotel_reservation -f SPRINT8_DATA_COMPLET.sql
-- ================================================================================

-- ==========================================
-- 0. CONNEXION A LA BASE
-- ==========================================
-- Si vous executez depuis psql avec l'option -d postgres:
-- \c hotel_reservation

-- ==========================================
-- 1. NETTOYAGE DES DONNEES EXISTANTES
-- ==========================================

-- Supprimer les attributions existantes
DELETE FROM attribution;

-- Supprimer les reservations existantes
DELETE FROM reservation;

-- Supprimer les distances existantes
DELETE FROM distance;

-- Supprimer les vehicules existants
DELETE FROM vehicule;

-- Supprimer les lieux existants
DELETE FROM lieu;

-- Reset des sequences
ALTER SEQUENCE IF EXISTS lieu_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS vehicule_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS reservation_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS attribution_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS distance_id_seq RESTART WITH 1;

-- ==========================================
-- 2. INSERTION DES PARAMETRES
-- ==========================================

-- Supprimer les anciens parametres
DELETE FROM parameters WHERE key IN ('vitesse_moyenne', 'temps_attente');

-- Inserer les parametres de test
INSERT INTO parameters (key, value) VALUES
('vitesse_moyenne', '50'),    -- 50 km/h
('temps_attente', '30')       -- 30 minutes fenetre d'attente
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- ==========================================
-- 3. INSERTION DES LIEUX
-- ==========================================

INSERT INTO lieu (id, code, libelle, initial) VALUES
(1, 'IVATO', 'Aeroport Ivato', 'A'),
(2, 'CARLTON', 'Hotel Carlton', 'B'),
(3, 'COLBERT', 'Hotel Colbert', 'C');

-- Mise a jour de la sequence
SELECT setval('lieu_id_seq', (SELECT MAX(id) FROM lieu));

-- ==========================================
-- 4. INSERTION DES DISTANCES
-- ==========================================
-- Distances bidirectionnelles pour les calculs de trajet aller-retour

INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
-- Depuis IVATO
(1, 2, 25.00),   -- IVATO -> CARLTON
(1, 3, 30.00),   -- IVATO -> COLBERT

-- Depuis CARLTON
(2, 1, 25.00),   -- CARLTON -> IVATO
(2, 3, 10.00),   -- CARLTON -> COLBERT

-- Depuis COLBERT
(3, 1, 30.00),   -- COLBERT -> IVATO
(3, 2, 10.00);   -- COLBERT -> CARLTON

-- ==========================================
-- 5. INSERTION DES VEHICULES
-- ==========================================
-- Vehicules avec differentes capacites et heures de disponibilite

INSERT INTO vehicule (id, reference, nb_place, type_carburant, heure_disponible_debut) VALUES
-- Grands vehicules
(1, 'VEH-12A', 12, 'D',  NULL),        -- Diesel, toujours disponible
(2, 'VEH-10B', 10, 'Es', '08:00:00'),  -- Essence, disponible des 08:00

-- Vehicules moyens
(3, 'VEH-08C', 8,  'D',  '09:00:00'),  -- Diesel, disponible des 09:00
(4, 'VEH-05D', 5,  'H',  NULL),        -- Hybride, toujours disponible
(5, 'VEH-05E', 5,  'El', '10:00:00'),  -- Electrique, disponible des 10:00

-- Petit vehicule
(6, 'VEH-03F', 3,  'Es', NULL);        -- Essence, toujours disponible

-- Mise a jour de la sequence
SELECT setval('vehicule_id_seq', (SELECT MAX(id) FROM vehicule));

-- ==========================================
-- 6. RESERVATIONS - SCENARIO 1: REGROUPEMENT OPTIMAL
-- ==========================================
-- Date: 2026-04-01
-- Test: Le systeme doit choisir R3 pour regrouper avec R1 car ecart = 0

INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- R1: 9 passagers -> VEH-12A laisse 3 places
(1, 2, 'CLI001', 9, '2026-04-01 08:00:00', 1),
-- R2: 5 passagers -> ecart avec 3 places = |5-3| = 2
(2, 2, 'CLI002', 5, '2026-04-01 08:10:00', 1),
-- R3: 3 passagers -> ecart avec 3 places = |3-3| = 0 (OPTIMAL)
(3, 2, 'CLI003', 3, '2026-04-01 08:15:00', 1),
-- R4: 2 passagers -> ecart avec 3 places = |2-3| = 1
(4, 2, 'CLI004', 2, '2026-04-01 08:20:00', 1);

-- ==========================================
-- 7. RESERVATIONS - SCENARIO 2: DIVISION OPTIMALE
-- ==========================================
-- Date: 2026-04-02
-- Test: Division de 20 passagers avec selection optimale des vehicules

INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- R5: 20 passagers -> necessite division
-- Attendu: VEH-12A (12 pass, ecart=8) puis VEH-08C (8 pass, ecart=0)
(5, 3, 'CLI005', 20, '2026-04-02 09:30:00', 1);

-- ==========================================
-- 8. RESERVATIONS - SCENARIO 3: DISPONIBILITE HORAIRE
-- ==========================================
-- Date: 2026-04-03
-- Test: Verification que les vehicules respectent leur heure de disponibilite

INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- R6: 07:00 -> VEH-10B (08:00) et VEH-08C (09:00) NON disponibles
(6, 2, 'CLI006', 4, '2026-04-03 07:00:00', 1),
-- R7: 09:30 -> VEH-08C (09:00) maintenant disponible
(7, 2, 'CLI007', 4, '2026-04-03 09:30:00', 1);

-- ==========================================
-- 9. RESERVATIONS - SCENARIO 4: FENETRE DE RETOUR VEHICULE
-- ==========================================
-- Date: 2026-04-04
-- Test: Enchainement des trajets avec fenetres de retour

INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- R8: 08:00 -> VEH-12A part, retour ~09:00
(8, 2, 'CLI008', 6, '2026-04-04 08:00:00', 1),
-- R9: 09:30 -> Dans fenetre d'attente apres retour VEH-12A
(9, 3, 'CLI009', 7, '2026-04-04 09:30:00', 1),
-- R10: 10:10 -> Apres second retour de VEH-12A
(10, 2, 'CLI010', 5, '2026-04-04 10:10:00', 1);

-- ==========================================
-- 10. RESERVATIONS - SCENARIO 5: GESTION DES RESTES
-- ==========================================
-- Date: 2026-04-05
-- Test: 25 passagers avec vehicules limites -> reste non assigne

INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- R11: 25 passagers -> si seulement 15 places dispo, 10 restent
(11, 2, 'CLI011', 25, '2026-04-05 08:30:00', 1);

-- ==========================================
-- 11. RESERVATIONS - SCENARIO 6: CAS COMBINE COMPLEXE
-- ==========================================
-- Date: 2026-04-06
-- Test: Tous les aspects combines

INSERT INTO reservation (id, lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
-- Phase 1: Fenetre initiale 07:00-07:30
(12, 2, 'CLI012', 10, '2026-04-06 07:00:00', 1),  -- CARLTON
(13, 2, 'CLI013', 8,  '2026-04-06 07:15:00', 1),  -- CARLTON
(14, 3, 'CLI014', 3,  '2026-04-06 07:20:00', 1),  -- COLBERT

-- Phase 2: Apres retour vehicules
(15, 2, 'CLI015', 15, '2026-04-06 09:00:00', 1),  -- CARLTON - Division probable

-- Phase 3: Fin de matinee
(16, 3, 'CLI016', 6,  '2026-04-06 10:30:00', 1),  -- COLBERT
(17, 2, 'CLI017', 4,  '2026-04-06 11:00:00', 1);  -- CARLTON

-- Mise a jour de la sequence
SELECT setval('reservation_id_seq', (SELECT MAX(id) FROM reservation));

-- ==========================================
-- 12. CREATION D'ATTRIBUTIONS PRE-EXISTANTES (Optionnel)
-- ==========================================
-- Pour simuler des vehicules deja en course pour le Scenario 5

-- Decommenter pour simuler des vehicules indisponibles au 2026-04-05
/*
INSERT INTO attribution (reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes) VALUES
-- VEH-10B en course de 07:00 a 10:00 le 2026-04-05
(11, 2, '2026-04-05 07:00:00', '2026-04-05 10:00:00', 'ASSIGNE', 10),
-- VEH-05D en course de 07:30 a 09:30 le 2026-04-05
(11, 4, '2026-04-05 07:30:00', '2026-04-05 09:30:00', 'ASSIGNE', 5);
*/

-- ==========================================
-- 13. VERIFICATION DES DONNEES INSEREES
-- ==========================================

-- Afficher le resume des lieux
SELECT '=== LIEUX ===' as info;
SELECT id, code, libelle FROM lieu ORDER BY id;

-- Afficher le resume des vehicules
SELECT '=== VEHICULES ===' as info;
SELECT id, reference, nb_place, type_carburant, heure_disponible_debut
FROM vehicule ORDER BY id;

-- Afficher le resume des distances
SELECT '=== DISTANCES ===' as info;
SELECT l1.code as de, l2.code as vers, d.km_distance
FROM distance d
JOIN lieu l1 ON d.from_lieu_id = l1.id
JOIN lieu l2 ON d.to_lieu_id = l2.id
ORDER BY l1.code, l2.code;

-- Afficher le resume des reservations par jour
SELECT '=== RESERVATIONS PAR JOUR ===' as info;
SELECT
    DATE(arrival_date) as date_jour,
    COUNT(*) as nb_reservations,
    SUM(passenger_nbr) as total_passagers
FROM reservation
GROUP BY DATE(arrival_date)
ORDER BY date_jour;

-- Afficher le detail des reservations
SELECT '=== DETAIL RESERVATIONS ===' as info;
SELECT
    r.id,
    r.customer_id,
    r.passenger_nbr,
    l1.code as depart,
    l2.code as destination,
    r.arrival_date
FROM reservation r
JOIN lieu l1 ON r.lieu_depart_id = l1.id
JOIN lieu l2 ON r.lieu_destination_id = l2.id
ORDER BY r.arrival_date;

-- Afficher les parametres
SELECT '=== PARAMETRES ===' as info;
SELECT key, value FROM parameters WHERE key IN ('vitesse_moyenne', 'temps_attente');

-- ==========================================
-- 14. REQUETES DE TEST POST-PLANIFICATION
-- ==========================================

-- Ces requetes sont a executer APRES avoir lance la planification

/*
-- A. Vue d'ensemble des attributions
SELECT
    DATE(a.date_heure_depart) as date_trajet,
    v.reference as vehicule,
    v.nb_place as places_vehicule,
    r.customer_id as client,
    r.passenger_nbr as passagers_demandes,
    a.nb_passagers_assignes as passagers_assignes,
    a.date_heure_depart::time as heure_depart,
    a.date_heure_retour::time as heure_retour
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
ORDER BY a.date_heure_depart;

-- B. Verification Scenario 1: Regroupement Optimal (2026-04-01)
-- R3 doit etre groupee avec R1 car ecart = 0
SELECT
    a.id as attribution_id,
    v.reference,
    STRING_AGG(r.customer_id, ', ') as clients_groupes,
    SUM(a.nb_passagers_assignes) as total_passagers
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
WHERE DATE(a.date_heure_depart) = '2026-04-01'
GROUP BY a.id, v.reference
ORDER BY a.id;

-- C. Verification Scenario 2: Division Optimale (2026-04-02)
-- R5 (20 pass) doit etre divisee: VEH-12A (12) + VEH-08C (8)
SELECT
    v.reference,
    v.nb_place,
    a.nb_passagers_assignes,
    ABS(v.nb_place - a.nb_passagers_assignes) as ecart
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
WHERE r.id = 5
ORDER BY a.date_heure_depart;

-- D. Verification Scenario 3: Disponibilite Horaire (2026-04-03)
SELECT
    v.reference,
    v.heure_disponible_debut,
    a.date_heure_depart::time as heure_depart,
    CASE
        WHEN v.heure_disponible_debut IS NULL THEN 'OK - Toujours dispo'
        WHEN a.date_heure_depart::time >= v.heure_disponible_debut THEN 'OK - Respecte'
        ELSE 'ERREUR - Avant dispo'
    END as validation
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
WHERE DATE(a.date_heure_depart) = '2026-04-03';

-- E. Verification Scenario 4: Fenetres de Retour (2026-04-04)
SELECT
    v.reference,
    a.date_heure_depart,
    a.date_heure_retour,
    LEAD(a.date_heure_depart) OVER (PARTITION BY v.id ORDER BY a.date_heure_depart) as prochain_depart,
    CASE
        WHEN LEAD(a.date_heure_depart) OVER (PARTITION BY v.id ORDER BY a.date_heure_depart) >= a.date_heure_retour
        THEN 'OK' ELSE 'Chevauchement'
    END as validation
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
WHERE DATE(a.date_heure_depart) = '2026-04-04'
ORDER BY v.reference, a.date_heure_depart;

-- F. Verification Scenario 5: Gestion des Restes (2026-04-05)
SELECT
    r.id,
    r.customer_id,
    r.passenger_nbr as demande,
    COALESCE(SUM(a.nb_passagers_assignes), 0) as assigne,
    r.passenger_nbr - COALESCE(SUM(a.nb_passagers_assignes), 0) as reste_non_assigne
FROM reservation r
LEFT JOIN attribution a ON r.id = a.reservation_id
WHERE DATE(r.arrival_date) = '2026-04-05'
GROUP BY r.id, r.customer_id, r.passenger_nbr;

-- G. Resume global par jour
SELECT
    DATE(r.arrival_date) as date_jour,
    COUNT(DISTINCT r.id) as nb_reservations,
    SUM(r.passenger_nbr) as passagers_demandes,
    COALESCE(SUM(a.nb_passagers_assignes), 0) as passagers_assignes,
    SUM(r.passenger_nbr) - COALESCE(SUM(a.nb_passagers_assignes), 0) as passagers_restants
FROM reservation r
LEFT JOIN attribution a ON r.id = a.reservation_id
GROUP BY DATE(r.arrival_date)
ORDER BY date_jour;
*/

-- ==========================================
-- FIN DU SCRIPT
-- ==========================================

SELECT '========================================' as info;
SELECT 'SPRINT 8 - DONNEES DE TEST INSEREES' as info;
SELECT '========================================' as info;
SELECT 'Lieux: ' || COUNT(*) FROM lieu;
SELECT 'Vehicules: ' || COUNT(*) FROM vehicule;
SELECT 'Distances: ' || COUNT(*) FROM distance;
SELECT 'Reservations: ' || COUNT(*) FROM reservation;
SELECT '========================================' as info;
SELECT 'Pret pour lancer la planification!' as info;
SELECT '========================================' as info;
