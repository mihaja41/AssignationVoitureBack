-- ================================================================================
--  SPRINT 8 - SCRIPT DE SIMULATION COMPLET - TOUS LES CAS POSSIBLES
-- ================================================================================
-- Usage: psql -U postgres -d postgres -f sprint8.sql
-- ================================================================================

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'hotel_reservation' AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS hotel_reservation;
CREATE DATABASE hotel_reservation;

\c hotel_reservation

-- ==========================================
-- STRUCTURE DES TABLES
-- ==========================================
DROP TYPE IF EXISTS type_carburant_enum CASCADE;
CREATE TYPE type_carburant_enum AS ENUM ('D', 'Es', 'H', 'El');

CREATE TABLE lieu (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(255) NOT NULL,
    initial VARCHAR(10)
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
    lieu_depart_id BIGINT NOT NULL REFERENCES lieu(id),
    customer_id VARCHAR(100) NOT NULL,
    passenger_nbr INT NOT NULL,
    arrival_date TIMESTAMP NOT NULL,
    lieu_destination_id BIGINT REFERENCES lieu(id)
);

CREATE TABLE parameters (
    id SERIAL PRIMARY KEY,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL
);

CREATE TABLE distance (
    id BIGSERIAL PRIMARY KEY,
    from_lieu_id BIGINT NOT NULL REFERENCES lieu(id),
    to_lieu_id BIGINT NOT NULL REFERENCES lieu(id),
    km_distance NUMERIC(10, 2) NOT NULL
);

CREATE TABLE attribution (
    id SERIAL PRIMARY KEY,
    reservation_id INTEGER NOT NULL REFERENCES reservation(id),
    vehicule_id INTEGER NOT NULL REFERENCES vehicule(id),
    date_heure_depart TIMESTAMP NOT NULL,
    date_heure_retour TIMESTAMP NOT NULL,
    statut VARCHAR(20) NOT NULL DEFAULT 'ASSIGNE',
    nb_passagers_assignes INT NOT NULL DEFAULT 0
);

-- ==========================================
-- DONNÉES DE BASE
-- ==========================================
INSERT INTO parameters (key, value) VALUES
('vitesse_moyenne', '90'),
('temps_attente', '30');

INSERT INTO lieu (code, libelle, initial) VALUES
('AEROPORT', 'Aeroport', 'A'),
('HOTEL_A', 'Hotel A', 'B'),
('HOTEL_B', 'Hotel B', 'C');

INSERT INTO distance (from_lieu_id, to_lieu_id, km_distance) VALUES
(1, 2, 45.00),
(1, 3, 30.00);


-- ================================================================================
-- CAS 1: RÉSERVATION ARRIVE → VÉHICULE DISPONIBLE → FENÊTRE CRÉÉE
-- Date: 2026-04-01
-- Véhicules disponibles au départ (pas de retour simulé)
-- ================================================================================
-- ENTRÉE:
-- v1      10      D       (disponible)
-- v2       8      Es      (disponible)
-- r1       7      08:00
--
-- ATTENDU:
-- → r1(7) arrive à 08:00
-- → v1 ou v2 disponible (écart: v2=1, v1=3) → v2 choisi
-- → v2 ← r1(7) = 1 place restante
-- → v2 PAS PLEIN → fenêtre [08:00-08:30]
-- → Pas de nouvelles réservations
-- → v2 part à 08:00 avec r1(7)
--
-- RÉSULTAT ATTENDU:
-- Attribution: v2 | r1(7) | 7 pax | départ: 08:00 | (fenêtre créée mais vide)
-- ================================================================================

INSERT INTO vehicule (reference, nb_place, type_carburant, heure_disponible_debut) VALUES
('v1', 10, 'D',  NULL),
('v2', 8,  'Es', NULL);

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r1', 7, '2026-04-01 08:00:00', 2);


-- ================================================================================
-- CAS 2: VÉHICULE RETOURNE → PLEIN IMMÉDIATEMENT → PART SANS FENÊTRE
-- Date: 2026-04-02
-- ================================================================================
-- ENTRÉE:
-- v3       8      D       retour: 09:00
-- r2       8      08:30   (prioritaire, arrive avant retour)
--
-- ATTENDU:
-- → v3 retourne à 09:00
-- → r2(8) prioritaire (arrivé 08:30)
-- → v3(8) ← r2(8) = écart 0 PARFAIT
-- → v3 PLEIN → PART IMMÉDIATEMENT à 09:00
-- → PAS DE FENÊTRE CRÉÉE
--
-- RÉSULTAT ATTENDU:
-- Attribution: v3 | r2(8) | 8 pax | départ: 09:00 | (PLEIN, pas de fenêtre)
-- ================================================================================

INSERT INTO vehicule (reference, nb_place, type_carburant, heure_disponible_debut) VALUES
('v3', 8, 'D', NULL);

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r2', 8, '2026-04-02 08:30:00', 2);

-- Simuler retour v3 à 09:00 (attribution passée)
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r_hist_v3', 8, '2026-04-02 06:00:00', 3);
INSERT INTO attribution (reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes) VALUES
(3, 3, '2026-04-02 06:00:00', '2026-04-02 09:00:00', 'TERMINE', 8);


-- ================================================================================
-- CAS 3: VÉHICULE RETOURNE → PAS PLEIN → FENÊTRE CRÉÉE → REMPLISSAGE
-- Date: 2026-04-02
-- ================================================================================
-- ENTRÉE:
-- v4      10      D       retour: 10:00
-- r3       5      09:30   (prioritaire)
-- r4       3      10:15   (arrive dans fenêtre)
--
-- ATTENDU:
-- → v4 retourne à 10:00
-- → r3(5) prioritaire → v4 ← r3(5) = 5 places restantes
-- → v4 PAS PLEIN → fenêtre [10:00-10:30]
-- → r4(3) arrive à 10:15 (dans fenêtre)
-- → v4 ← r4(3) = 2 places restantes
-- → Fin fenêtre 10:30 → v4 part à 10:15 (heure dernière résa)
--
-- RÉSULTAT ATTENDU:
-- Attribution: v4 | r3(5) + r4(3) | 8 pax | départ: 10:15 | (fenêtre remplie)
-- ================================================================================

INSERT INTO vehicule (reference, nb_place, type_carburant, heure_disponible_debut) VALUES
('v4', 10, 'D', NULL);

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r3', 5, '2026-04-02 09:30:00', 2),
(1, 'r4', 3, '2026-04-02 10:15:00', 2);

-- Simuler retour v4 à 10:00
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r_hist_v4', 10, '2026-04-02 06:00:00', 3);
INSERT INTO attribution (reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes) VALUES
(6, 4, '2026-04-02 06:00:00', '2026-04-02 10:00:00', 'TERMINE', 10);


-- ================================================================================
-- CAS 4: REGROUPEMENT OPTIMAL (MOD 1)
-- Date: 2026-04-03
-- ================================================================================
-- ENTRÉE:
-- v5      10      D       retour: 09:00
-- r5       7      08:00
-- r6       5      08:00
-- r7       3      08:00
--
-- ATTENDU:
-- → v5 retourne à 09:00
-- → Prioritaires triées: r5(7), r6(5), r7(3)
-- → v5 ← r5(7) = 3 places restantes
-- → Regroupement optimal pour 3 places:
--   • r6(5): écart = |5-3| = 2
--   • r7(3): écart = |3-3| = 0 ← MEILLEUR
-- → v5 ← r7(3) = 0 places = PLEIN
-- → v5 part à 09:00 avec r5(7) + r7(3) = 10
-- → r6(5) reporté
--
-- RÉSULTAT ATTENDU:
-- Attribution: v5 | r5(7) + r7(3) | 10 pax | départ: 09:00 | (PLEIN, regroupement optimal)
-- NON ASSIGNÉ: r6(5)
-- ================================================================================

INSERT INTO vehicule (reference, nb_place, type_carburant, heure_disponible_debut) VALUES
('v5', 10, 'D', NULL);

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r5', 7, '2026-04-03 08:00:00', 2),
(1, 'r6', 5, '2026-04-03 08:00:00', 2),
(1, 'r7', 3, '2026-04-03 08:00:00', 2);

-- Simuler retour v5 à 09:00
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r_hist_v5', 10, '2026-04-03 06:00:00', 3);
INSERT INTO attribution (reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes) VALUES
(10, 5, '2026-04-03 06:00:00', '2026-04-03 09:00:00', 'TERMINE', 10);


-- ================================================================================
-- CAS 5: DIVISION OPTIMALE (MOD 2)
-- Date: 2026-04-03
-- ================================================================================
-- ENTRÉE:
-- v6       5      D       retour: 10:00
-- v7       8      Es      retour: 10:00
-- v8      12      D       retour: 10:00
-- r8      18      09:30
--
-- ATTENDU:
-- → v6, v7, v8 retournent à 10:00
-- → r8(18) = besoin de division
-- → Meilleur véhicule pour 18:
--   • v6(5): écart = 13
--   • v7(8): écart = 10
--   • v8(12): écart = 6 ← MEILLEUR
-- → v8 ← r8(12) = PLEIN, reste 6 pax
-- → Meilleur véhicule pour 6 restants:
--   • v6(5): écart = 1
--   • v7(8): écart = 2
--   → v6 ← r8(5) = PLEIN, reste 1 pax
-- → Meilleur pour 1 restant:
--   • v7(8): écart = 7
--   → v7 ← r8(1) = 7 places vides
-- → v7 PAS PLEIN → fenêtre [10:00-10:30]
--
-- RÉSULTAT ATTENDU:
-- Attribution 1: v8 | r8(12) | 12 pax | départ: 10:00 | (PLEIN)
-- Attribution 2: v6 | r8(5) | 5 pax | départ: 10:00 | (PLEIN)
-- Attribution 3: v7 | r8(1) | 1 pax | départ: 10:00 | (fenêtre)
-- ================================================================================

INSERT INTO vehicule (reference, nb_place, type_carburant, heure_disponible_debut) VALUES
('v6', 5,  'D',  NULL),
('v7', 8,  'Es', NULL),
('v8', 12, 'D',  NULL);

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r8', 18, '2026-04-03 09:30:00', 2);

-- Simuler retours v6, v7, v8 à 10:00
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r_hist_v6', 5, '2026-04-03 06:00:00', 3),
(1, 'r_hist_v7', 8, '2026-04-03 06:00:00', 3),
(1, 'r_hist_v8', 12, '2026-04-03 06:00:00', 3);
INSERT INTO attribution (reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes) VALUES
(12, 6, '2026-04-03 06:00:00', '2026-04-03 10:00:00', 'TERMINE', 5),
(13, 7, '2026-04-03 06:00:00', '2026-04-03 10:00:00', 'TERMINE', 8),
(14, 8, '2026-04-03 06:00:00', '2026-04-03 10:00:00', 'TERMINE', 12);


-- ================================================================================
-- CAS 6: DISPONIBILITÉ HORAIRE (MOD 3)
-- Date: 2026-04-04
-- ================================================================================
-- ENTRÉE:
-- v9      10      D       dispo: 09:00   (pas avant 09:00!)
-- v10      5      Es      dispo: NULL    (toujours disponible)
-- r9       8      08:30   (arrive AVANT v9 dispo)
--
-- ATTENDU:
-- → r9(8) arrive à 08:30
-- → v9: dispo 09:00 > 08:30 → NON DISPONIBLE
-- → v10: dispo NULL → DISPONIBLE mais 5 < 8
-- → r9 REPORTÉ jusqu'à 09:00
-- → À 09:00, v9 devient disponible
-- → v9 ← r9(8) = 2 places restantes
-- → v9 PAS PLEIN → fenêtre [09:00-09:30]
--
-- RÉSULTAT ATTENDU:
-- Attribution: v9 | r9(8) | 8 pax | départ: 09:00 | (fenêtre, dispo horaire respectée)
-- ================================================================================

INSERT INTO vehicule (reference, nb_place, type_carburant, heure_disponible_debut) VALUES
('v9',  10, 'D',  '09:00:00'),
('v10', 5,  'Es', NULL);

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r9', 8, '2026-04-04 08:30:00', 2);


-- ================================================================================
-- CAS 7: MULTI-VÉHICULES RETOURNENT → UN PLEIN, UN FENÊTRE
-- Date: 2026-04-04
-- ================================================================================
-- ENTRÉE:
-- v11      8      D       retour: 11:00
-- v12     10      Es      retour: 11:00
-- r10      8      10:30   (prioritaire)
-- r11      5      10:45   (prioritaire)
-- r12      3      11:10   (arrive dans fenêtre)
--
-- ATTENDU:
-- → v11, v12 retournent à 11:00
-- → Prioritaires: r10(8), r11(5)
-- → r10(8) meilleur véhicule:
--   • v11(8): écart = 0 ← PARFAIT
--   • v12(10): écart = 2
-- → v11 ← r10(8) = PLEIN → PART À 11:00 (pas de fenêtre)
-- → r11(5) → v12(10) = 5 places
-- → v12 PAS PLEIN → fenêtre [11:00-11:30]
-- → r12(3) arrive à 11:10
-- → v12 ← r12(3) = 2 places
-- → Fin fenêtre → v12 part à 11:10
--
-- RÉSULTAT ATTENDU:
-- Attribution 1: v11 | r10(8) | 8 pax | départ: 11:00 | (PLEIN immédiat)
-- Attribution 2: v12 | r11(5) + r12(3) | 8 pax | départ: 11:10 | (fenêtre remplie)
-- ================================================================================

INSERT INTO vehicule (reference, nb_place, type_carburant, heure_disponible_debut) VALUES
('v11', 8,  'D',  NULL),
('v12', 10, 'Es', NULL);

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r10', 8, '2026-04-04 10:30:00', 2),
(1, 'r11', 5, '2026-04-04 10:45:00', 2),
(1, 'r12', 3, '2026-04-04 11:10:00', 2);

-- Simuler retours v11, v12 à 11:00
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r_hist_v11', 8, '2026-04-04 06:00:00', 3),
(1, 'r_hist_v12', 10, '2026-04-04 06:00:00', 3);
INSERT INTO attribution (reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes) VALUES
(19, 11, '2026-04-04 06:00:00', '2026-04-04 11:00:00', 'TERMINE', 8),
(20, 12, '2026-04-04 06:00:00', '2026-04-04 11:00:00', 'TERMINE', 10);


-- ================================================================================
-- CAS 8: RESTES ET REPORTS (passagers non assignés)
-- Date: 2026-04-05
-- ================================================================================
-- ENTRÉE:
-- v13      7      D       retour: 09:00
-- r13     10      08:30   (10 > 7 = division)
-- r14      4      09:10   (arrive dans fenêtre)
--
-- ATTENDU:
-- → v13 retourne à 09:00
-- → r13(10) > v13(7) → division
-- → v13 ← r13(7) = PLEIN, reste r13_rest(3)
-- → v13 PART À 09:00 (PLEIN)
-- → r13_rest(3) reporté
-- → r14(4) arrive à 09:10, pas de véhicule
-- → r13_rest(3) + r14(4) = NON ASSIGNÉS
--
-- RÉSULTAT ATTENDU:
-- Attribution: v13 | r13(7) | 7 pax | départ: 09:00 | (PLEIN, division)
-- NON ASSIGNÉ: r13_rest(3), r14(4)
-- ================================================================================

INSERT INTO vehicule (reference, nb_place, type_carburant, heure_disponible_debut) VALUES
('v13', 7, 'D', NULL);

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r13', 10, '2026-04-05 08:30:00', 2),
(1, 'r14', 4,  '2026-04-05 09:10:00', 2);

-- Simuler retour v13 à 09:00
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r_hist_v13', 7, '2026-04-05 06:00:00', 3);
INSERT INTO attribution (reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes) VALUES
(23, 13, '2026-04-05 06:00:00', '2026-04-05 09:00:00', 'TERMINE', 7);


-- ================================================================================
-- CAS 9: FENÊTRE ISSUE D'UNE NOUVELLE ARRIVÉE (après fin fenêtre précédente)
-- Date: 2026-04-05
-- ================================================================================
-- ENTRÉE:
-- v14     12      D       retour: 10:00
-- r15      6      09:30
-- r16      4      10:45   (après fin fenêtre 10:30)
--
-- ATTENDU:
-- → v14 retourne à 10:00
-- → r15(6) → v14(12) = 6 places
-- → v14 PAS PLEIN → fenêtre [10:00-10:30]
-- → Pas de nouvelles jusqu'à 10:30
-- → v14 part à 10:00 avec r15(6)
-- → r16(4) arrive à 10:45 (APRÈS fenêtre)
-- → Nouvelle fenêtre créée [10:45-11:15]
-- → Pas de véhicule disponible
-- → r16 reporté
--
-- RÉSULTAT ATTENDU:
-- Attribution: v14 | r15(6) | 6 pax | départ: 10:00 | (fenêtre vide)
-- NON ASSIGNÉ: r16(4) (pas de véhicule après sa fenêtre)
-- ================================================================================

INSERT INTO vehicule (reference, nb_place, type_carburant, heure_disponible_debut) VALUES
('v14', 12, 'D', NULL);

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r15', 6, '2026-04-05 09:30:00', 2),
(1, 'r16', 4, '2026-04-05 10:45:00', 2);

-- Simuler retour v14 à 10:00
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r_hist_v14', 12, '2026-04-05 06:00:00', 3);
INSERT INTO attribution (reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes) VALUES
(26, 14, '2026-04-05 06:00:00', '2026-04-05 10:00:00', 'TERMINE', 12);


-- ================================================================================
-- CAS 10: COMPLEXE - TOUS LES MÉCANISMES COMBINÉS
-- Date: 2026-04-06
-- ================================================================================
-- ENTRÉE:
-- v15     15      D       dispo: 07:00   retour: 09:00
-- v16     10      Es      dispo: 09:30   retour: 10:30
-- v17      8      D       dispo: NULL    retour: 09:30
-- r17     12      08:00   (v15 seul dispo à 08:00)
-- r18      9      09:00   (v17 dispo, v16 pas encore)
-- r19      5      09:45   (v16 dispo maintenant)
-- r20      3      10:00   (dans fenêtre)
--
-- ATTENDU:
-- → r17(12) arrive à 08:00
-- → v15: dispo 07:00 ≤ 08:00 → DISPONIBLE
-- → v16: dispo 09:30 > 08:00 → NON DISPONIBLE
-- → v17: pas de retour simulé avant 09:30
-- → v15 ← r17(12) = 3 places
-- → v15 PAS PLEIN → fenêtre [08:00-08:30]
-- → Pas de nouvelles → v15 part à 08:00 avec r17(12)
--
-- → v17 retourne à 09:30
-- → r18(9) prioritaire (arrivé 09:00)
-- → v17(8) < r18(9) → division: v17 ← r18(8) = PLEIN
-- → r18_rest(1)
-- → v17 PART À 09:30
--
-- → v16 retourne à 10:30, dispo depuis 09:30
-- → Prioritaires: r18_rest(1), r19(5)
-- → r19(5): v16(10) écart=5
-- → v16 ← r19(5) = 5 places
-- → v16 ← r18_rest(1) = 4 places
-- → v16 PAS PLEIN → fenêtre [10:30-11:00]
-- → r20(3) arrive à 10:00... AVANT retour v16!
-- → Doit attendre ou assigner à fenêtre précédente
--
-- RÉSULTAT ATTENDU:
-- Attribution 1: v15 | r17(12) | 12 pax | départ: 08:00 | (fenêtre vide)
-- Attribution 2: v17 | r18(8) | 8 pax | départ: 09:30 | (PLEIN, division)
-- Attribution 3: v16 | r19(5) + r18_rest(1) + r20(3) | 9 pax | départ: 10:30 | (fenêtre)
-- ================================================================================

INSERT INTO vehicule (reference, nb_place, type_carburant, heure_disponible_debut) VALUES
('v15', 15, 'D',  '07:00:00'),
('v16', 10, 'Es', '09:30:00'),
('v17', 8,  'D',  NULL);

INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r17', 12, '2026-04-06 08:00:00', 2),
(1, 'r18', 9,  '2026-04-06 09:00:00', 2),
(1, 'r19', 5,  '2026-04-06 09:45:00', 2),
(1, 'r20', 3,  '2026-04-06 10:00:00', 2);

-- Simuler retours
INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) VALUES
(1, 'r_hist_v15', 15, '2026-04-06 05:00:00', 3),
(1, 'r_hist_v16', 10, '2026-04-06 06:00:00', 3),
(1, 'r_hist_v17', 8, '2026-04-06 06:00:00', 3);
INSERT INTO attribution (reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes) VALUES
(31, 15, '2026-04-06 05:00:00', '2026-04-06 09:00:00', 'TERMINE', 15),
(32, 16, '2026-04-06 06:00:00', '2026-04-06 10:30:00', 'TERMINE', 10),
(33, 17, '2026-04-06 06:00:00', '2026-04-06 09:30:00', 'TERMINE', 8);


-- ================================================================================
-- VÉRIFICATION
-- ================================================================================
\echo ''
\echo '=========================================='
\echo 'VÉHICULES'
\echo '=========================================='
SELECT id, reference, nb_place, type_carburant, heure_disponible_debut
FROM vehicule WHERE reference NOT LIKE 'r_hist%' ORDER BY id;

\echo ''
\echo '=========================================='
\echo 'RÉSERVATIONS À TRAITER'
\echo '=========================================='
SELECT id, customer_id, passenger_nbr, arrival_date
FROM reservation
WHERE customer_id NOT LIKE 'r_hist%'
ORDER BY arrival_date;

\echo ''
\echo '=========================================='
\echo 'RETOURS SIMULÉS (attributions existantes)'
\echo '=========================================='
SELECT v.reference, a.date_heure_retour AS retour
FROM attribution a
JOIN vehicule v ON v.id = a.vehicule_id
WHERE a.statut = 'TERMINE'
ORDER BY a.date_heure_retour;

\echo ''
\echo '=========================================='
\echo 'RÉSUMÉ DES CAS À TESTER'
\echo '=========================================='
\echo 'CAS 1 (2026-04-01): Réservation arrive → fenêtre créée'
\echo 'CAS 2 (2026-04-02): Véhicule retourne → PLEIN → pas de fenêtre'
\echo 'CAS 3 (2026-04-02): Véhicule retourne → fenêtre → remplissage'
\echo 'CAS 4 (2026-04-03): Regroupement optimal (MOD 1)'
\echo 'CAS 5 (2026-04-03): Division optimale (MOD 2)'
\echo 'CAS 6 (2026-04-04): Disponibilité horaire (MOD 3)'
\echo 'CAS 7 (2026-04-04): Multi-véhicules: un PLEIN, un fenêtre'
\echo 'CAS 8 (2026-04-05): Restes et reports'
\echo 'CAS 9 (2026-04-05): Fenêtre issue nouvelle arrivée'
\echo 'CAS 10 (2026-04-06): Tous mécanismes combinés'
\echo ''
\echo 'DATES DE TEST:'
\echo '  genererPlanning(2026-04-01) → CAS 1'
\echo '  genererPlanning(2026-04-02) → CAS 2, 3'
\echo '  genererPlanning(2026-04-03) → CAS 4, 5'
\echo '  genererPlanning(2026-04-04) → CAS 6, 7'
\echo '  genererPlanning(2026-04-05) → CAS 8, 9'
\echo '  genererPlanning(2026-04-06) → CAS 10'
