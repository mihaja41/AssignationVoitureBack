-- ============================================================================
-- SPRINT 8 - FICHIER DE SIMULATION COMPLET
-- ============================================================================
-- Ce fichier contient toutes les données de test et les résultats attendus
-- pour vérifier l'implémentation des règles Sprint 8
-- ============================================================================

-- ============================================================================
-- NETTOYAGE PRÉALABLE
-- ============================================================================
DELETE FROM attribution WHERE id > 0;
DELETE FROM reservation WHERE id > 0;
DELETE FROM vehicule WHERE id > 0;
DELETE FROM lieu WHERE id > 0;
DELETE FROM distance WHERE id > 0;

-- ============================================================================
-- CONFIGURATION DES LIEUX
-- ============================================================================
INSERT INTO lieu (id, libelle, initial) VALUES (1, 'CARLTON', 'CAR');
INSERT INTO lieu (id, libelle, initial) VALUES (2, 'COLBERT', 'COL');
INSERT INTO lieu (id, libelle, initial) VALUES (3, 'IVATO AEROPORT', 'IVA');

-- ============================================================================
-- CONFIGURATION DES DISTANCES
-- ============================================================================
-- CARLTON -> IVATO: 25km = 30min aller (vitesse 50km/h), 60min total
-- COLBERT -> IVATO: 30km = 36min aller (vitesse 50km/h), 72min total
INSERT INTO distance (id, lieu_depart_id, lieu_arrivee_id, km_distance) VALUES (1, 1, 3, 25);
INSERT INTO distance (id, lieu_depart_id, lieu_arrivee_id, km_distance) VALUES (2, 3, 1, 25);
INSERT INTO distance (id, lieu_depart_id, lieu_arrivee_id, km_distance) VALUES (3, 2, 3, 30);
INSERT INTO distance (id, lieu_depart_id, lieu_arrivee_id, km_distance) VALUES (4, 3, 2, 30);

-- ============================================================================
-- CONFIGURATION DES VÉHICULES
-- ============================================================================
-- v1: 10 places, Diesel, toujours disponible
-- v2: 10 places, Essence, toujours disponible
-- v3: 12 places, Diesel, toujours disponible
-- v4: 8 places, Diesel, disponible à partir de 10:30

INSERT INTO vehicule (id, reference, nb_place, type_carburant, heure_disponible_debut)
VALUES (1, 'v1_10pl_D', 10, 'D', NULL);

INSERT INTO vehicule (id, reference, nb_place, type_carburant, heure_disponible_debut)
VALUES (2, 'v2_10pl_E', 10, 'E', NULL);

INSERT INTO vehicule (id, reference, nb_place, type_carburant, heure_disponible_debut)
VALUES (3, 'v3_12pl_D', 12, 'D', NULL);

INSERT INTO vehicule (id, reference, nb_place, type_carburant, heure_disponible_debut)
VALUES (4, 'v4_8pl_D', 8, 'D', '10:30:00');

-- ============================================================================
-- CONFIGURATION DES PARAMÈTRES
-- ============================================================================
UPDATE parametre SET valeur = '50' WHERE cle = 'vitesse_moyenne';
UPDATE parametre SET valeur = '30' WHERE cle = 'temps_attente';

-- Si parametre n'existe pas, les créer
INSERT INTO parametre (cle, valeur)
SELECT 'vitesse_moyenne', '50' WHERE NOT EXISTS (SELECT 1 FROM parametre WHERE cle = 'vitesse_moyenne');
INSERT INTO parametre (cle, valeur)
SELECT 'temps_attente', '30' WHERE NOT EXISTS (SELECT 1 FROM parametre WHERE cle = 'temps_attente');


-- ############################################################################
-- JOUR 1: 27/03/2026 - REGROUPEMENT OPTIMAL
-- ############################################################################
-- Scénario: 4 réservations, 19 passagers total
-- Tous les véhicules disponibles dès le début
-- ############################################################################

INSERT INTO reservation (id, client_name, passenger_nbr, arrival_date, lieu_depart_id, lieu_destination_id)
VALUES
(1, 'J1_r1_9pass', 9, '2026-03-27 08:00:00', 1, 3),
(2, 'J1_r2_5pass', 5, '2026-03-27 07:55:00', 1, 3),
(3, 'J1_r3_3pass', 3, '2026-03-27 07:50:00', 1, 3),
(4, 'J1_r4_2pass', 2, '2026-03-27 07:40:00', 1, 3);

-- ============================================================================
-- JOUR 1 - RÉSULTATS ATTENDUS
-- ============================================================================
/*
FENÊTRE: [07:40 - 08:10] (créée par r4, première arrivée)
MAX(arrival_date) = 08:00

ORDRE DE TRAITEMENT (Tri DESC par passagers):
1. r1(9) - MAXIMUM
2. r2(5)
3. r3(3)
4. r4(2)

ÉTAPE 1: Traiter r1(9 passagers)
- Sélection véhicule CLOSEST FIT parmi ceux qui peuvent contenir 9:
  * v1(10): |10-9| = 1 ← MINIMUM (Diesel prioritaire)
  * v2(10): |10-9| = 1
  * v3(12): |12-9| = 3
- v1 choisie (écart=1, Diesel prioritaire)
- v1 prend r1(9), reste 1 place

REGROUPEMENT v1 (1 place restante) - CLOSEST FIT:
- r4(2): |1-2| = 1 ← MINIMUM
- r3(3): |1-3| = 2
- r2(5): |1-5| = 4
- v1 prend 1 passager de r4 = 10 PLEIN
- v1 départ 08:00, retour ~09:00

RÉSERVATIONS RESTANTES après v1: r2(5), r3(3), r4(1 restant)

ÉTAPE 2: Traiter r2(5 passagers) - PROCHAIN MAXIMUM
- Véhicules disponibles: v2(10), v3(12)
- CLOSEST FIT:
  * v2(10): |10-5| = 5 ← MINIMUM
  * v3(12): |12-5| = 7
- v2 choisie (écart=5)
- v2 prend r2(5), reste 5 places

REGROUPEMENT v2 (5 places) - CLOSEST FIT:
- r3(3): |5-3| = 2 ← MINIMUM
- r4_reste(1): |5-1| = 4
- v2 prend r3(3), reste 2 places

REGROUPEMENT v2 (2 places) - CLOSEST FIT:
- r4_reste(1): |2-1| = 1
- v2 prend r4_reste(1), total = 9
- v2 départ 08:00, retour ~09:00

=== RÉSULTAT ATTENDU JOUR 1 ===
| Véhicule | Réservations      | Passagers | Départ | Retour |
|----------|-------------------|-----------|--------|--------|
| v1       | r1(9) + r4(1)     | 10        | 08:00  | ~09:00 |
| v2       | r2(5)+r3(3)+r4(1) | 9         | 08:00  | ~09:00 |
| v3       | -                 | 0         | -      | -      |
| v4       | -                 | 0         | -      | -      |

VÉRIFICATION: 9+1 + 5+3+1 = 19 passagers (tous assignés)
*/


-- ############################################################################
-- JOUR 2: 28/03/2026 - DIVISION OPTIMALE
-- ############################################################################
-- Scénario: 1 réservation avec 20 passagers
-- Aucun véhicule ne peut contenir 20 passagers -> DIVISION
-- ############################################################################

INSERT INTO reservation (id, client_name, passenger_nbr, arrival_date, lieu_depart_id, lieu_destination_id)
VALUES
(5, 'J2_r1_20pass', 20, '2026-03-28 09:00:00', 1, 3);

-- ============================================================================
-- JOUR 2 - RÉSULTATS ATTENDUS
-- ============================================================================
/*
FENÊTRE: [09:00 - 09:30]

ÉTAPE 1: r1(20 passagers) - Une seule réservation
- Aucun véhicule ne peut contenir 20 passagers
- DIVISION avec CLOSEST FIT:
  * v1(10): |10-20| = 10
  * v2(10): |10-20| = 10
  * v3(12): |12-20| = 8 ← MINIMUM
  * v4(8): Non disponible avant 10:30
- v3 choisie (écart=8)
- v3 prend 12 passagers, reste 8 passagers

ÉTAPE 2 (Division): 8 passagers restants
- Véhicules disponibles: v1(10), v2(10)
- CLOSEST FIT:
  * v1(10): |10-8| = 2 ← MINIMUM (égalité, moins trajets ou Diesel)
  * v2(10): |10-8| = 2
- v1 choisie (Diesel prioritaire)
- v1 prend 8 passagers = TOUS ASSIGNÉS

=== RÉSULTAT ATTENDU JOUR 2 ===
| Véhicule | Réservation    | Passagers | Départ | Retour |
|----------|----------------|-----------|--------|--------|
| v3       | r1 (partie 1)  | 12        | 09:00  | ~10:00 |
| v1       | r1 (partie 2)  | 8         | 09:00  | ~10:00 |

VÉRIFICATION: 12 + 8 = 20 passagers (tous assignés)
*/


-- ############################################################################
-- JOUR 3: 29/03/2026 - RETOUR VEHICULE + FENÊTRE D'ATTENTE (COMPLEXE)
-- ############################################################################
-- Scénario complexe avec:
-- - 3 véhicules qui partent et reviennent
-- - Réservations prioritaires (avant fenêtre)
-- - Création de fenêtre de regroupement
-- - Gestion des restes partiels
-- ############################################################################

INSERT INTO reservation (id, client_name, passenger_nbr, arrival_date, lieu_depart_id, lieu_destination_id)
VALUES
-- Matin: 3 réservations qui vont utiliser v1, v2, v3
(6, 'J3_r1_10pass_MATIN', 10, '2026-03-29 07:00:00', 1, 3),
(7, 'J3_r2_10pass_MATIN', 10, '2026-03-29 07:00:00', 1, 3),
(8, 'J3_r3_12pass_MATIN', 12, '2026-03-29 07:00:00', 1, 3),
-- Réservations qui arrivent APRÈS la première fenêtre
(9, 'J3_r4_9pass_RESTE', 9, '2026-03-29 07:30:00', 1, 3),
(10, 'J3_r5_5pass_RESTE', 5, '2026-03-29 07:45:00', 1, 3),
-- Réservations qui arrivent pendant la fenêtre de retour
(11, 'J3_r6_7pass', 7, '2026-03-29 08:15:00', 1, 3),
(12, 'J3_r7_8pass', 8, '2026-03-29 08:20:00', 1, 3);

-- ============================================================================
-- JOUR 3 - RÉSULTATS ATTENDUS
-- ============================================================================
/*
=== FENÊTRE 1: [07:00 - 07:30] ===
Réservations dans fenêtre: r1(10), r2(10), r3(12)
r4(9) arrive à 07:30 = HORS fenêtre (au bord)
r5(5) arrive à 07:45 = HORS fenêtre

TRI DESC: r3(12) > r1(10) = r2(10)

ÉTAPE 1: Traiter r3(12) - MAXIMUM
- CLOSEST FIT: seul v3(12) peut contenir 12
  * v3(12): |12-12| = 0 ← PARFAIT
- v3 prend r3(12) = PLEIN
- v3 départ 07:00, retour ~08:00 (CARLTON 25km -> 30min aller -> 08:00)

ÉTAPE 2: Traiter r1(10)
- CLOSEST FIT: v1(10) ou v2(10), écart=0
- v1 choisie (Diesel prioritaire, moins trajets)
- v1 prend r1(10) = PLEIN
- v1 départ 07:00, retour ~08:00

ÉTAPE 3: Traiter r2(10)
- v2 prend r2(10) = PLEIN
- v2 départ 07:00, retour ~08:00

RESTES NON ASSIGNÉS: r4(9), r5(5)
Véhicules disponibles: aucun (tous partis)

=== FENÊTRE 2: [07:45 - 08:15] (créée par r5, première non-assignée qui arrive) ===
Réservations non assignées AVANT 07:45: r4(9) arrivé à 07:30 = PRIORITAIRE
Réservations dans fenêtre: r5(5)
r6(7) arrive à 08:15 = au bord de la fenêtre

Véhicules disponibles à 07:45: AUCUN (tous reviennent à ~08:00)
Véhicules qui reviennent DANS la fenêtre: v1, v2, v3 à ~08:00

ATTENTE jusqu'à 08:00...
À 08:00, v1(10), v2(10), v3(12) reviennent

TRAITEMENT DES PRIORITAIRES (r4 arrivé AVANT 07:45):
TRI DESC: r4(9)

Trouver véhicule CLOSEST FIT pour r4(9):
- v1(10): |10-9| = 1 ← MINIMUM (Diesel prioritaire)
- v2(10): |10-9| = 1
- v3(12): |12-9| = 3
- v1 choisie
- v1 prend r4(9), reste 1 place

REGROUPEMENT v1 (1 place) - CLOSEST FIT:
- r5(5): |1-5| = 4
- r6(7): |1-7| = 6
- v1 prend 1 de r5 = 10 PLEIN
- r5 reste 4 passagers non assignés

v1 départ = MAX(arrival_date assignées) ou heure_retour
- r4 arrivé 07:30
- r5 arrivé 07:45
- v1 retour 08:00
- MAX(07:30, 07:45) = 07:45 < 08:00 (heure retour)
- Donc v1 départ = 08:00

=== FENÊTRE 3: [08:00 - 08:30] (créée car v1 non plein immédiatement) ===
Mais v1 est maintenant plein, donc on passe à v2 et v3

Réservations restantes: r5(4 restants), r6(7), r7(8)
Véhicules disponibles: v2(10), v3(12)

TRI DESC des non-assignés: r7(8) > r6(7) > r5(4)

TRAITER r7(8):
- v2(10): |10-8| = 2 ← MINIMUM
- v3(12): |12-8| = 4
- v2 prend r7(8), reste 2 places

REGROUPEMENT v2 (2 places) - CLOSEST FIT:
- r5(4): |2-4| = 2 ← égalité
- r6(7): |2-7| = 5
- v2 prend 2 de r5, v2 PLEIN
- r5 reste 2 passagers

v2 départ = MAX(r7 arrival=08:20, r5 partial=07:45) = 08:20

TRAITER r6(7):
- v3(12): seul véhicule dispo
- v3 prend r6(7), reste 5 places

REGROUPEMENT v3 (5 places) - CLOSEST FIT:
- r5(2 restants): |5-2| = 3
- v3 prend r5(2), reste 3 places

Pas d'autres réservations, v3 part avec 9 passagers (7+2)
v3 départ = MAX(r6 arrival=08:15, r5 arrival=07:45) = 08:15
MAIS v3 retour = 08:00 < 08:15, donc départ = 08:15 (MAX des assignées)

=== RÉSULTAT ATTENDU JOUR 3 ===
| Véhicule | Heure Départ | Réservations         | Passagers | Retour  |
|----------|--------------|----------------------|-----------|---------|
| v3       | 07:00        | r3(12)               | 12        | ~08:00  |
| v1       | 07:00        | r1(10)               | 10        | ~08:00  |
| v2       | 07:00        | r2(10)               | 10        | ~08:00  |
| v1       | 08:00        | r4(9) + r5(1)        | 10        | ~09:00  |
| v2       | 08:20        | r7(8) + r5(2)        | 10        | ~09:20  |
| v3       | 08:15        | r6(7) + r5(2)        | 9         | ~09:15  |

VÉRIFICATION:
- Matin: 12+10+10 = 32 passagers
- Après retour: 9+1 + 8+2 + 7+2 = 29 passagers
- r4: 9/9 OK, r5: 1+2+2=5/5 OK, r6: 7/7 OK, r7: 8/8 OK
- Total Jour 3: 61 passagers
*/


-- ############################################################################
-- JOUR 4: 30/03/2026 - HEURE_DISPONIBLE_DEBUT (v4 à 10:30)
-- ############################################################################
-- Scénario: Tester la disponibilité retardée de v4
-- ############################################################################

INSERT INTO reservation (id, client_name, passenger_nbr, arrival_date, lieu_depart_id, lieu_destination_id)
VALUES
(13, 'J4_r1_4pass', 4, '2026-03-30 10:00:00', 1, 3),
(14, 'J4_r2_6pass', 6, '2026-03-30 10:25:00', 1, 3);

-- ============================================================================
-- JOUR 4 - RÉSULTATS ATTENDUS
-- ============================================================================
/*
=== FENÊTRE 1: [10:00 - 10:30] ===
Réservations: r1(4) arrive 10:00, r2(6) arrive 10:25
Véhicules disponibles à 10:00: v1(10), v2(10), v3(12)
v4(8) disponible SEULEMENT à partir de 10:30

TRI DESC: r2(6) > r1(4)

ÉTAPE 1: Traiter r2(6) - MAXIMUM
- À 10:00, v4 N'EST PAS disponible
- CLOSEST FIT parmi v1, v2, v3:
  * v1(10): |10-6| = 4
  * v2(10): |10-6| = 4
  * v3(12): |12-6| = 6
- v1 choisie (écart=4, Diesel prioritaire)
- v1 prend r2(6), reste 4 places

REGROUPEMENT v1 (4 places) - CLOSEST FIT:
- r1(4): |4-4| = 0 ← PARFAIT
- v1 prend r1(4) = 10 PLEIN

v1 départ = MAX(r2=10:25, r1=10:00) = 10:25

=== RÉSULTAT ATTENDU JOUR 4 ===
| Véhicule | Réservations      | Passagers | Départ | Retour |
|----------|-------------------|-----------|--------|--------|
| v1       | r2(6) + r1(4)     | 10        | 10:25  | ~11:25 |
| v4       | -                 | 0         | -      | -      |

VÉRIFICATION: 6 + 4 = 10 passagers, v4 NON utilisé (disponible seulement à 10:30)
*/


-- ############################################################################
-- JOUR 5: 31/03/2026 - DIVISION EN 3 PARTIES
-- ############################################################################
-- Scénario: 1 réservation avec 25 passagers -> 3 véhicules
-- ############################################################################

INSERT INTO reservation (id, client_name, passenger_nbr, arrival_date, lieu_depart_id, lieu_destination_id)
VALUES
(15, 'J5_r1_25pass', 25, '2026-03-31 10:30:00', 1, 3);

-- ============================================================================
-- JOUR 5 - RÉSULTATS ATTENDUS
-- ============================================================================
/*
=== FENÊTRE: [10:30 - 11:00] ===
r1(25 passagers)
Véhicules disponibles: v1(10), v2(10), v3(12), v4(8) - tous disponibles à 10:30

DIVISION avec CLOSEST FIT à chaque itération:

ITÉRATION 1: 25 passagers restants
- v1(10): |10-25| = 15
- v2(10): |10-25| = 15
- v3(12): |12-25| = 13 ← MINIMUM
- v4(8): |8-25| = 17
- v3 prend 12 passagers, reste 13

ITÉRATION 2: 13 passagers restants
- v1(10): |10-13| = 3 ← MINIMUM (égalité Diesel/moins trajets)
- v2(10): |10-13| = 3
- v4(8): |8-13| = 5
- v1 prend 10 passagers, reste 3

ITÉRATION 3: 3 passagers restants
- v2(10): |10-3| = 7
- v4(8): |8-3| = 5 ← MINIMUM
- v4 prend 3 passagers = TOUS ASSIGNÉS

=== RÉSULTAT ATTENDU JOUR 5 ===
| Véhicule | Réservation    | Passagers | Départ | Retour |
|----------|----------------|-----------|--------|--------|
| v3       | r1 (partie 1)  | 12        | 10:30  | ~11:30 |
| v1       | r1 (partie 2)  | 10        | 10:30  | ~11:30 |
| v4       | r1 (partie 3)  | 3         | 10:30  | ~11:30 |

VÉRIFICATION: 12 + 10 + 3 = 25 passagers (tous assignés)
NOTE: v4 utilisé car disponible à 10:30
*/


-- ############################################################################
-- JOUR 6: 01/04/2026 - VÉHICULE REMPLI IMMÉDIATEMENT (pas de fenêtre)
-- ############################################################################
-- Scénario: Tester le cas où un véhicule est rempli IMMÉDIATEMENT au retour
-- ############################################################################

-- D'abord, créer une attribution pour simuler un véhicule qui revient
INSERT INTO attribution (id, vehicule_id, date_heure_depart, date_heure_retour, nb_passagers_assignes, statut)
VALUES (100, 1, '2026-04-01 07:00:00', '2026-04-01 08:00:00', 10, 'TERMINE');

INSERT INTO reservation (id, client_name, passenger_nbr, arrival_date, lieu_depart_id, lieu_destination_id)
VALUES
-- Réservation prioritaire qui arrive AVANT le retour de v1
(16, 'J6_r1_10pass_PRIORITAIRE', 10, '2026-04-01 07:30:00', 1, 3),
-- Autre réservation dans la fenêtre potentielle
(17, 'J6_r2_5pass', 5, '2026-04-01 08:15:00', 1, 3);

-- ============================================================================
-- JOUR 6 - RÉSULTATS ATTENDUS
-- ============================================================================
/*
CONTEXTE:
- v1 part à 07:00, retourne à 08:00 (attribution id=100)
- r1(10) arrive à 07:30 (AVANT le retour de v1) = PRIORITAIRE
- r2(5) arrive à 08:15 (APRÈS le retour)

=== À 08:00: v1 retourne ===
Réservations non assignées AVANT 08:00: r1(10) arrivé à 07:30 = PRIORITAIRE

TRAITEMENT PRIORITAIRE:
TRI DESC: r1(10)

Trouver véhicule CLOSEST FIT pour r1(10):
- v1(10): |10-10| = 0 ← PARFAIT
(v2, v3 aussi disponibles mais v1 a 0 écart)

v1 prend r1(10) = PLEIN IMMÉDIATEMENT

*** RÈGLE DÉPART IMMÉDIAT ***
Le véhicule est rempli PAR LES RÉSERVATIONS AVANT son heure de retour
r1(10) = v1(10) -> PLEIN AU MOMENT EXACT DU RETOUR
Donc v1 part IMMÉDIATEMENT à 08:00 (heure_retour)
PAS DE FENÊTRE DE REGROUPEMENT créée pour v1

=== v2, v3 restent disponibles ===
Prochaine réservation: r2(5) à 08:15

FENÊTRE: [08:15 - 08:45] (créée par r2)
- v2(10): |10-5| = 5
- v3(12): |12-5| = 7
- v2 prend r2(5), reste 5 places
- Pas d'autres réservations

v2 départ = 08:15

=== RÉSULTAT ATTENDU JOUR 6 ===
| Véhicule | Réservations | Passagers | Départ | Retour  | Note                    |
|----------|--------------|-----------|--------|---------|-------------------------|
| v1       | r1(10)       | 10        | 08:00  | ~09:00  | DÉPART IMMÉDIAT (plein) |
| v2       | r2(5)        | 5         | 08:15  | ~09:15  | Fenêtre créée           |

VÉRIFICATION: 10 + 5 = 15 passagers
Point clé: v1 part à 08:00 (heure_retour) car rempli immédiatement, pas à 08:15
*/


-- ############################################################################
-- JOUR 7: 02/04/2026 - CAS COMPLEXE: VÉHICULE ET RÉSERVATION ARRIVENT EN MÊME TEMPS
-- ############################################################################
-- Scénario: v4 devient disponible à 10:30 ET une réservation arrive à 10:30
-- ############################################################################

INSERT INTO reservation (id, client_name, passenger_nbr, arrival_date, lieu_depart_id, lieu_destination_id)
VALUES
-- Réservation qui arrive EXACTEMENT quand v4 devient disponible
(18, 'J7_r1_8pass_MEME_TEMPS', 8, '2026-04-02 10:30:00', 1, 3),
-- Autre réservation avant
(19, 'J7_r2_3pass_AVANT', 3, '2026-04-02 10:00:00', 1, 3);

-- ============================================================================
-- JOUR 7 - RÉSULTATS ATTENDUS
-- ============================================================================
/*
CONTEXTE:
- v4(8) disponible à partir de 10:30
- r2(3) arrive à 10:00
- r1(8) arrive à 10:30 (même heure que disponibilité v4)

=== FENÊTRE 1: [10:00 - 10:30] (créée par r2) ===
Réservations: r2(3)
Véhicules disponibles à 10:00: v1(10), v2(10), v3(12)
v4(8) PAS encore disponible

TRI DESC: r2(3)

CLOSEST FIT pour r2(3):
- v1(10): |10-3| = 7
- v2(10): |10-3| = 7
- v3(12): |12-3| = 9
Mais on préfère remplir, donc on cherche le plus petit qui peut contenir
- v4 pas dispo
- v1 ou v2 (écart 7, égalité -> Diesel -> v1)

Mais attendez - à 10:30, v4 devient disponible ET r1 arrive
Si on attend jusqu'à 10:30 (fin de fenêtre), v4 sera disponible

*** CAS SPÉCIAL: même heure d'arrivée réservation ET disponibilité véhicule ***
À 10:30:
- v4 devient disponible
- r1(8) arrive

Priorité: vérifier les non-assignés AVANT 10:30
- r2(3) est arrivé à 10:00, toujours non assigné

Si r2 a été assigné dans la fenêtre [10:00-10:30]:
- v1 aurait pris r2(3), reste 7 places
- À 10:30, r1(8) arrive - traiter comme nouvelle fenêtre

TRAITEMENT FENÊTRE 1:
v1 prend r2(3), reste 7 places
Pas d'autres réservations avant 10:30
Mais fenêtre va jusqu'à 10:30, donc r1 peut être considéré

À 10:30, r1(8) arrive:
REGROUPEMENT v1 (7 places) - CLOSEST FIT:
- r1(8): |7-8| = 1
v1 prend 7 de r1, reste 1 passager de r1

v1 PLEIN, départ = MAX(r2=10:00, r1=10:30) = 10:30

=== FENÊTRE 2 ou continuation ===
r1 reste 1 passager
v4(8) disponible à 10:30
v2(10), v3(12) aussi disponibles

CLOSEST FIT pour r1(1 restant):
- v4(8): |8-1| = 7
- v2(10): |10-1| = 9
- v3(12): |12-1| = 11
v4 choisie

v4 prend r1(1), reste 7 places
Pas d'autres réservations
v4 départ = MAX(r1=10:30) = 10:30

=== RÉSULTAT ATTENDU JOUR 7 ===
| Véhicule | Réservations      | Passagers | Départ | Retour  |
|----------|-------------------|-----------|--------|---------|
| v1       | r2(3) + r1(7)     | 10        | 10:30  | ~11:30  |
| v4       | r1(1)             | 1         | 10:30  | ~11:30  |

VÉRIFICATION: 3 + 7 + 1 = 11 passagers (r2=3, r1=8)
*/


-- ############################################################################
-- RÉSUMÉ DES RÉSULTATS ATTENDUS
-- ############################################################################
/*
=== JOUR 1 (27/03): REGROUPEMENT OPTIMAL ===
| v1 | r1(9)+r4(1)=10 | 08:00 |
| v2 | r2(5)+r3(3)+r4(1)=9 | 08:00 |
Total: 19 passagers

=== JOUR 2 (28/03): DIVISION OPTIMALE ===
| v3 | r1(12) | 09:00 |
| v1 | r1(8) | 09:00 |
Total: 20 passagers

=== JOUR 3 (29/03): RETOUR + FENÊTRE D'ATTENTE ===
| v3 | r3(12) | 07:00 |
| v1 | r1(10) | 07:00 |
| v2 | r2(10) | 07:00 |
| v1 | r4(9)+r5(1)=10 | 08:00 |
| v2 | r7(8)+r5(2)=10 | 08:20 |
| v3 | r6(7)+r5(2)=9 | 08:15 |
Total: 61 passagers

=== JOUR 4 (30/03): HEURE_DISPONIBLE_DEBUT ===
| v1 | r2(6)+r1(4)=10 | 10:25 |
Total: 10 passagers (v4 non utilisé)

=== JOUR 5 (31/03): DIVISION 3 PARTIES ===
| v3 | r1(12) | 10:30 |
| v1 | r1(10) | 10:30 |
| v4 | r1(3) | 10:30 |
Total: 25 passagers

=== JOUR 6 (01/04): DÉPART IMMÉDIAT ===
| v1 | r1(10) | 08:00 | IMMÉDIAT (plein au retour)
| v2 | r2(5) | 08:15 |
Total: 15 passagers

=== JOUR 7 (02/04): MÊME HEURE ARRIVÉE ===
| v1 | r2(3)+r1(7)=10 | 10:30 |
| v4 | r1(1) | 10:30 |
Total: 11 passagers

TOTAL GÉNÉRAL: 161 passagers sur 7 jours
*/


-- ############################################################################
-- REQUÊTES DE VÉRIFICATION
-- ############################################################################

-- Vérifier les réservations par jour
SELECT
    DATE(arrival_date) as jour,
    COUNT(*) as nb_reservations,
    SUM(passenger_nbr) as total_passagers
FROM reservation
WHERE id <= 19
GROUP BY DATE(arrival_date)
ORDER BY jour;

-- Vérifier les véhicules
SELECT id, reference, nb_place, type_carburant, heure_disponible_debut
FROM vehicule
ORDER BY id;

-- Vérifier les paramètres
SELECT * FROM parametre WHERE cle IN ('vitesse_moyenne', 'temps_attente');
