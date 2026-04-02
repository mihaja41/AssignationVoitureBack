# SPRINT 8 - SIMULATION COMPLÈTE DES SCÉNARIOS

**Date de création**: 2026-04-03
**État du projet**: Prêt pour test complet
**Règles validées**: 3 modifications Sprint 8 implémentées

---

## TABLE DES MATIÈRES

1. [Règles Sprint 8 Rappel](#règles-sprint-8-rappel)
2. [Configuration de Base](#configuration-de-base)
3. [Scénarios de Test](#scénarios-de-test)
4. [Guide Exécution](#guide-exécution)
5. [Validation Attendue](#validation-attendue)

---

## RÈGLES SPRINT 8 RAPPEL

### Modification 1: Regroupement Optimal (CLOSEST FIT)
**Contexte**: Fenêtre issue d'une arrivée de réservation
- **Tri**: DÉCROISSANT par nb_passagers
- **Sélection véhicule**: nb_places le plus PROCHE du nombre de passagers
- **Formule**: `Math.abs(nb_places - nb_passagers)` = minimum
- **Regroupement**: CLOSEST FIT pour remplir les places restantes

### Modification 2: Division Optimale (CLOSEST FIT pour division)
**Contexte**: Réservation requiert plusieurs véhicules
- **Sélection véhicule division**: nb_places le plus PROCHE des passagers restants
- **Itération**: Chaque véhicule prend le maximum possible
- **Priorités en cas d'égalité**:
  1. Moins de trajets effectués
  2. Diesel prioritaire
  3. Aléatoire

### Modification 3: Disponibilité Horaire
**Contexte**: Véhicules avec heure_disponible_debut
- **Validation**: `heure_depart >= heure_disponible_debut`
- **Vérification**: Avant d'assigner un véhicule, vérifier sa disponibilité
- **Impact**: Exclure les véhicules non disponibles à une heure donnée

---

## CONFIGURATION DE BASE

### Véhicules Flotte

| Ref | Places | Carburant | Disponibilité | Retours Simulés |
|-----|--------|-----------|---------------|-----------------|
| v1  | 10     | Diesel    | Toujours      | 09:00, 13:00   |
| v2  | 10     | Essence   | Toujours      | 09:30, 14:00   |
| v3  | 12     | Diesel    | Toujours      | 08:00, 10:30   |
| v4  | 8      | Hybride   | À partir 10:30| 15:00          |

### Paramètres Globaux

| Paramètre           | Valeur |
|-------------------|--------|
| Vitesse moyenne   | 50 km/h|
| Fenêtre d'attente | 30 min |
| Distance CARLTON→IVATO | 25 km |
| Distance COLBERT→IVATO | 30 km |
| Durée trajet CARLTON | 60 min (aller-retour) |
| Durée trajet COLBERT | 72 min (aller-retour) |

### Lieux (Lieu de départ par défaut: CARLTON)

| Code | Libelle | Initial |
|------|---------|---------|
| IVATO | Aéroport Ivato | A |
| CARLTON | Hôtel Carlton | B |
| COLBERT | Hôtel Colbert | C |

---

## SCÉNARIOS DE TEST

### ✅ SCÉNARIO 1: Regroupement Optimal Simple (JOUR 27/03)

**Titre**: Remplissage progressif du véhicule avec CLOSEST FIT

**Description**: Une fenêtre d'arrivée avec 4 réservations de tailles différentes. Chaque véhicule doit être assigné avec l'écart minimum par rapport aux passagers.

**Réservations**:

| ID | Client | Lieu_Depart | Passagers | Arrivée |
|----|--------|-------------|-----------|---------|
| 1  | J1_r1  | CARLTON     | 9         | 08:00   |
| 2  | J1_r2  | CARLTON     | 5         | 07:55   |
| 3  | J1_r3  | CARLTON     | 3         | 07:50   |
| 4  | J1_r4  | CARLTON     | 2         | 07:40   |

**Total Passagers**: 19

**Fenêtre Calculée**:
- Première arrivée: 07:40 (r4)
- Fin fenêtre: 08:10
- Heure de départ: 08:00 (MAX des arrivées)

**Algorithme Attendu**:

```
Tri DÉCROISSANT:
r1(9) → r2(5) → r3(3) → r4(2)

CYCLE 1 - Assigner r1(9):
  Véhicules candidats: v1(10), v2(10), v3(12)
  Écarts: v1=|10-9|=1 (MIN), v2=|10-9|=1, v3=|12-9|=3
  Choix: v1 (écart=1, diesel)
  v1 prend r1(9) → RESTE 1 place

  Regroupement v1 (places=1):
    r4(2): écart=|1-2|=1 (MIN) → assigner 1
    r3(3): écart=|1-3|=2
    r2(5): écart=|1-5|=4
  v1 = r1(9) + r4(1) = 10 PLEIN ✓
  Départ: 08:00, Retour: 09:00

CYCLE 2 - Assigner r4_reste(1):
  Véhicules: v2(10), v3(12)
  v2(10): écart=|10-1|=9 (MIN)
  v3(12): écart=|12-1|=11
  Choix: v2
  v2 = r4_reste(1) → RESTE 9 places

  Regroupement v2 (places=9):
    r2(5): écart=|9-5|=4 (MIN)
    r3(3): écart=|9-3|=6
  v2 = r4_reste(1) + r2(5) → RESTE 4 places

  Regroupement v2 (places=4):
    r3(3): écart=|4-3|=1 (MIN)
  v2 = r4_reste(1) + r2(5) + r3(3) = 9 → RESTE 1 place
  Plus de réservations
  Départ: 08:00, Retour: 09:00
```

**Résultat Attendu**:

| Véhicule | Réservations | Passagers | Départ | Retour | Notes |
|----------|-------------|-----------|--------|--------|-------|
| v1 | r1(9) + r4(1) | 10 | 08:00 | 09:00 | PLEIN |
| v2 | r4(0) + r2(5) + r3(3) | 8 | 08:00 | 09:00 | Reste 2 |
| v3 | - | 0 | - | - | Non utilisé |
| v4 | - | 0 | - | - | Non dispo |

**Validation**:
- ✅ r1 assignée complètement (9/9)
- ✅ r2 assignée complètement (5/5)
- ✅ r3 assignée complètement (3/3)
- ✅ r4 assignée complètement (2/2) - divisée
- ✅ Total: 19 passagers
- ✅ Écarts véhicules minimaux

---

### ✅ SCÉNARIO 2: Division Optimale (JOUR 28/03)

**Titre**: Grande réservation divisée entre véhicules

**Description**: Une seule grande réservation (20 passagers) qui ne rentre dans aucun véhicule. Division avec CLOSEST FIT.

**Réservations**:

| ID | Client | Lieu_Depart | Passagers | Arrivée |
|----|--------|-------------|-----------|---------|
| 5  | J2_r1  | CARLTON     | 20        | 09:00   |

**Total Passagers**: 20

**Fenêtre Calculée**:
- Début: 09:00
- Fin: 09:30
- Heure de départ: 09:00

**Algorithme Attendu**:

```
Assignation r1(20):
  Max véhicule: v3(12)
  Impossible d'assigner 20 dans un seul véhicule
  → DIVISION activée

DIVISION ITÉRATION 1:
  Véhicules disponibles: v1(10), v2(10), v3(12), v4(0 - pas dispo 09:00)
  Écarts: v1=|10-20|=10, v2=|10-20|=10, v3=|12-20|=8 (MIN)
  Choix: v3 (écart=8)
  v3 prend 12 passagers → RESTE 8

DIVISION ITÉRATION 2:
  Véhicules restants: v1(10), v2(10)
  Écarts: v1=|10-8|=2 (MIN), v2=|10-8|=2 (égal)
  Tie-break: Moins de trajets → v1 (supposé)
  v1 prend 8 passagers → TOUS assignés ✓
```

**Résultat Attendu**:

| Véhicule | Réservations | Passagers | Départ | Retour | Notes |
|----------|-------------|-----------|--------|--------|-------|
| v3 | r1_partie1 | 12 | 09:00 | 10:00 | 1ère division |
| v1 | r1_partie2 | 8 | 09:00 | 10:00 | 2ème division |
| v2 | - | 0 | - | - | Non utilisé |
| v4 | - | 0 | - | - | Pas dispo (début 10:30) |

**Validation**:
- ✅ r1 division en 2 parties
- ✅ Totale assignée (20/20)
- ✅ Écarts minimaux (v3=8 < v1=10)
- ✅ Respect heure_disponible_debut pour v4

---

### ✅ SCÉNARIO 3: Retour Véhicule + Fenêtre d'Attente (JOUR 29/03)

**Titre**: Gestion des retours de véhicules et création de fenêtres dynamiques

**Description**: Matinée avec 3 réservations occupant les véhicules. Retour à 08:00. Jusqu'à 5 réservations arrivent pendant la fenêtre d'attente.

**Réservations Matinales** (occupent les véhicules):

| ID | Client | Lieu_Depart | Passagers | Arrivée |
|----|--------|-------------|-----------|---------|
| 6  | J3_r1_matin  | CARLTON | 10 | 07:00 |
| 7  | J3_r2_matin  | CARLTON | 10 | 07:00 |
| 8  | J3_r3_matin  | COLBERT | 12 | 07:00 |

**Allocation**:
- v1 ← r6(10) → Retour: 08:00
- v2 ← r7(10) → Retour: 09:00 (COLBERT)
- v3 ← r8(12) → Retour: 08:12

**Réservations Arrivant Après 07:30** (en attente):

| ID | Client | Lieu_Depart | Passagers | Arrivée |
|----|--------|-------------|-----------|---------|
| 9  | J3_r4  | CARLTON     | 9         | 07:30   |
| 10 | J3_r5  | CARLTON     | 5         | 07:45   |
| 11 | J3_r6  | CARLTON     | 7         | 08:15   |
| 12 | J3_r7  | CARLTON     | 8         | 08:20   |

**Total Passagers Attente**: 29

**Fenêtres Créées**:

```
À 07:30 - r4(9) non assignée:
  Fenêtre [07:30 - 08:00] (30 min)
  Véhicules dispo: v2(10), v3(12)
  (v1 retour 08:00, mais limite fenêtre=08:00)

  r4(9) → v2? Non, v2 pas encore revenu (retour 09:00)
  r4(9) → v3(12): écart=|12-9|=3, assigner 9
  v3 = r4(9) → RESTE 3

  Recherche regroupement r5(5)?
  r5 arrive 07:45 < 08:00 ✓
  écart=|3-5|=2
  v3 = r4(9) + r5(3) = 12 PLEIN
  Départ: 07:45 (dernière arrivée), Retour: 08:57

À 08:00 - v1 retour:
  Fenêtre [08:00 - 08:30]
  v1(10) revenu, reste non assigné = r5(2)
  v1 = r5(2) → RESTE 8

  Regroupement r6(7)? Non, arrive 08:15
  À 08:15, inclure r6(7):
  écart=|8-7|=1
  v1 = r5(2) + r6(6) = 10 PLEIN
  r6 = 1 restant
  Départ: 08:15, Retour: 09:15

À 08:20 - r7(8) arrive:
  Si v3 libre, assigner
  Si pas libre, v2 (retour 09:00)

  Or v3 part à 07:45<08:20, donc v3 libre
  v3 = r7(8) + r6(1) = 9
  Pas regroupement possible
  Départ: 08:20, Retour: 09:32
```

**Résultat Attendu**:

| Véhicule | Réservations | Passagers | Départ | Retour | Notes |
|----------|-------------|-----------|--------|--------|-------|
| v1 | r6(10) | 10 | 07:00 | 08:00 | Matin |
| v2 | r7(10) | 10 | 07:00 | 09:00 | Retour COLBERT |
| v3 | r8(12) puis r4(9)+r5(3)+[r6(6)] → r7(8) | Multi | 07:00 → 07:45 → 08:20 | 08:12 → 08:57 → 09:32 | Multiples trajets |
| v1 | r5(2)+r6(6) | 8 | 08:00 | 09:15 | 2ème trajet |
| v2 | - | 0 | - | - | Occupée |

**Validation**:
- ✅ Fenêtres créées au moment des retours
- ✅ Fenêtres créées au moment des nouvelles arrivées non assignées
- ✅ CLOSEST FIT appliqué lors des retours
- ✅ Respect des plages d'attente (±30 min)

---

### ✅ SCÉNARIO 4: Disponibilité Horaire (JOUR 30/03)

**Titre**: Restriction de disponibilité pour v4 (À partir 10:30)

**Description**: Deux réservations avant et après l'heure de disponibilité de v4.

**Réservations**:

| ID | Client | Lieu_Depart | Passagers | Arrivée |
|----|--------|-------------|-----------|---------|
| 13 | J4_r1  | CARLTON     | 4         | 10:00   |
| 14 | J4_r2  | CARLTON     | 6         | 10:35   |

**Total Passagers**: 10

**Algorithme Attendu**:

```
À 10:00 - r1(4) arrive:
  v4(8) NON dispo (heure_disponible_debut = 10:30)
  v4 exclu de la sélection
  Candidats: v1(10), v2(10), v3(12)
  Écarts: v1=|10-4|=6, v2=|10-4|=6, v3=|12-4|=8
  Choix: v1 ou v2 (écart=6) → v1 (diesel, supposé)
  v1 = r1(4)
  Départ: 10:00, Retour: 11:00

À 10:35 - r2(6) arrive:
  v4(8) MAINTENANT dispo (10:35 >= 10:30)
  v4 inclus explicitement
  Candidats: v2(10), v3(12), v4(8)
  Écarts: v2=|10-6|=4, v3=|12-6|=6, v4=|8-6|=2 (MIN)
  Choix: v4 (écart=2)
  v4 = r2(6)
  Départ: 10:35, Retour: 11:35

  Vérification: 10:35 >= 10:30 ✓ Valide
```

**Résultat Attendu**:

| Véhicule | Réservations | Passagers | Départ | Retour | Notes |
|----------|-------------|-----------|--------|--------|-------|
| v1 | r1(4) | 4 | 10:00 | 11:00 | v4 non dispo |
| v4 | r2(6) | 6 | 10:35 | 11:35 | 1ère utilisation v4 |

**Validation**:
- ✅ r1 assignée à v1 (v4 excluded)
- ✅ r2 assignée à v4 (heure >= 10:30)
- ✅ Vérification heure_disponible_debut respectée
- ✅ CLOSEST FIT appliqué (v4=2 < v2=4)

---

### ✅ SCÉNARIO 5: Gestion des Restes (JOUR 31/03)

**Titre**: Division complexe avec restes non assignables

**Description**: Capacité insuffisante globale. Certains passagers restent non assignés dans les fenêtres successives.

**Réservations Initiales**:

| ID | Client | Lieu_Depart | Passagers | Arrivée | Notes |
|----|--------|-------------|-----------|---------|-------|
| 15 | J5_r1  | CARLTON     | 10        | 08:00   | Occupe v2 |
| 16 | J5_r2  | COLBERT     | 12        | 08:00   | Occupe v3 |
| 17 | J5_r3  | CARLTON     | 25        | 08:30   | GRANDE |

**Allocations Matinales**:
- v2 ← r15(10) → Retour: 09:00 (COLBERT)
- v3 ← r16(12) → Retour: 10:12 (COLBERT)

**Algorithme Attendu**:

```
À 08:30 - r17(25) arrive:
  v1 libre, v4 pas dispo (avant 10:30)
  v1(10) < 25 → DIVISION

  Itération 1: Assigner 10 à v1
  r17 RESTE: 15 passagers
  Retour v1: 09:30

À 09:00 - v2 retour:
  Fenêtre [09:00 - 09:30]
  v2(10) libre
  r17_reste(15) en attente
  v2 = r17_reste(10)
  r17 RESTE: 5 passagers
  Retour v2: 10:00

À 10:00 - v2 retour + v3 ne retour pas encore:
  Fenêtre [10:00 - 10:30]
  v2, v4 disponibles
  r17_reste(5)
  v4(8): écart=|8-5|=3 (MIN, v4 dispo à 10:30)
  Mais v4 dispo DÉBUT fenêtre? Non, à 10:30
  → Attendre jusqu'à 10:30

À 10:30 - v4 devient dispo:
  v4(8) assigner r17_reste(5)
  r17 COMPLÈTEMENT assignée ✓
  Tous 25 passagers distribués
```

**Résultat Attendu**:

| Véhicule | Réservations | Passagers | Départ | Retour | Notes |
|----------|-------------|-----------|--------|--------|-------|
| v2 | r15(10) | 10 | 08:00 | 09:00 | Matin |
| v3 | r16(12) | 12 | 08:00 | 10:12 | Matin COLBERT |
| v1 | r17_p1(10) | 10 | 08:30 | 09:30 | Division 1 |
| v2 | r17_p2(10) | 10 | 09:00 | 10:00 | Division 2 |
| v4 | r17_p3(5) | 5 | 10:30 | 11:38 | Division 3 |

**Validation**:
- ✅ r17 divisée en 3 parties
- ✅ Total assigné (25/25)
- ✅ Respect heure_disponible_debut v4
- ✅ Utilisation v4 uniquement après 10:30

---

### ✅ SCÉNARIO 6: Cas Complexe Multi-Fenêtres (JOUR 27/03 - AVANCÉ)

**Titre**: Simulation réaliste avec 8 réservations et 4 fenêtres

**Description**: Scénario complexe avec imbrication de fenêtres d'arrivée et de retour.

**Réservations**:

| ID | Client | Lieu | Passagers | Arrivée |
|----|--------|------|-----------|---------|
| 1  | r1_10 | CARLTON | 10 | 07:00 |
| 2  | r2_10 | CARLTON | 10 | 07:05 |
| 3  | r3_8  | CARLTON | 8  | 07:30 |
| 4  | r4_9  | CARLTON | 9  | 07:45 |
| 5  | r5_4  | CARLTON | 4  | 08:15 |
| 6  | r6_6  | CARLTON | 6  | 08:20 |
| 7  | r7_3  | CARLTON | 3  | 08:50 |
| 8  | r8_2  | CARLTON | 2  | 09:10 |

**Total**: 52 passagers

**Fenêtres Créées**:

```
FENETRE 1 [07:00 - 07:30]:
  Arrivées: r1(10), r2(10), r3(8 à 07:30 justemment)
  Tri DESC: r1(10), r2(10), r3(8)

  Assigner r1(10) → v1(10): écart=0, PLEIN
  Assigner r2(10) → v2(10): écart=0, PLEIN
  Assigner r3(8) → v3(12): écart=4
  Retours: v1(08:00), v2(08:00), v3(08:12)

FENETRE 2 [07:30 - 08:00] (issue de r3 arrivée):
  Aucun nouveau, tous assignés ou pas encore

FENETRE 3 [08:00 - 08:30] (issue retour v1, v2):
  Restes attendus: r4(9)
  Arrivées dans fenêtre: r5(4 à 08:15), r6(6 à 08:20)

  v1(10) revenu: r4(9) → écart=1 (MIN)
  v1 = r4(9) → RESTE 1
  Regroupement r5(4): écart=|1-4|=3 → assigner 1
  v1 = r4(9) + r5(1) = 10 PLEIN
  r5_reste: 3 passagers

  v2(10) revenu: r5_reste(3)
  v2 = r5_reste(3) → RESTE 7
  Regroupement r6(6): écart=7-6=1 → assigner 6
  v2 = r5(3) + r6(6) = 9 → RESTE 1

FENETRE 4 [08:20 - 08:50] (issue de r6 ou retour):
  r6_reste(1 passager)? Non, tous 6 assignés
  r7(3) arrive 08:50

  Aucun véhicule dispo avant 08:50
  v1 retour 09:00 (r4+r5(1))
  v2 retour 09:00 (r5(3)+r6(6))
  v3 retour 08:12 (r3(8))

  v3 libre depuis 08:12 !
  Peut assigner r7(3) immédiatement?
  Attendre fenêtre naturelle...

  À 08:50, créer fenêtre [08:50-09:20]:
  r7(3) dans fenêtre
  v3(12) revenu depuis 08:12 et peut prendre
  v3 = r7(3) → RESTE 9

FENETRE 5 [09:00 - 09:30] (issue retour v1, v2):
  v1, v2 reviennent
  r8(2) arrive 09:10

  r8(2) dans fenêtre [09:00-09:30]
  v1(10) revenu: r8(2) → écart=8
  v2(10) revenu: r8(2) → écart=8
  Choix: V1 (supposé)
  v1 = r8(2) → RESTE 8
```

**Résultat Attendu**:

| Séquence | Véhicule | Réservations | Passagers | Départ | Retour |
|----------|----------|-------------|-----------|--------|--------|
| Matin    | v1 | r1(10) | 10 | 07:00 | 08:00 |
| Matin    | v2 | r2(10) | 10 | 07:05 | 08:00 |
| Matin    | v3 | r3(8) | 8 | 07:30 | 08:12 |
| Retour 1 | v1 | r4(9)+r5(1) | 10 | 08:00 | 09:00 |
| Retour 1 | v2 | r5(3)+r6(6) | 9 | 08:00 | 09:00 |
| Retour 2 | v3 | r7(3) | 3 | 08:50 | 10:02 |
| Retour 3 | v1 | r8(2) | 2 | 09:00 | 10:00 |

**Validation**:
- ✅ r1-r8 toutes assignées (52/52)
- ✅ 4 fenêtres créées
- ✅ Multiples retours et regroupements
- ✅ CLOSEST FIT à chaque étape

---

## GUIDE EXÉCUTION

### Procédure Test

```bash
# 1. Exécuter le SQL d'initialisation
psql -U postgres -d hotel_reservation -f SPRINT8_TEST_SIMULATION.sql

# 2. Vérifier les données insérées
psql -U postgres -d hotel_reservation -c "SELECT COUNT(*) FROM reservation;"

# 3. Générer le planning pour chaque jour
# API: GET /planning/auto?date=2026-03-27
# API: GET /planning/auto?date=2026-03-28
# ... etc

# 4. Vérifier les attributions en base
SELECT
    a.id,
    v.reference as vehicule,
    r.customer_id,
    a.nb_passagers_assignes as passagers,
    a.date_heure_depart::time as depart,
    a.date_heure_retour::time as retour
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
ORDER BY a.date_heure_depart;
```

### Checklist Validation

- [ ] Scénario 1: Regroupement optimal avec r1(9) → v1, r2,r3,r4 → v2
- [ ] Scénario 2: Division r1(20) → v3(12) + v1(8)
- [ ] Scénario 3: Retours véhicules créent fenêtres d'attente
- [ ] Scénario 4: v4 non utilisée 10:00, utilisée 10:35
- [ ] Scénario 5: r17(25) divisée en 3 parties
- [ ] Scénario 6: 8 réservations → 7 trajets avec multiple regroupements
- [ ] Tous les passagers assignés ou partiels documentés
- [ ] Heures de départ/retour calculées correctement
- [ ] Écarts véhicules minimaux en toute occasion

---

## VALIDATION ATTENDUE

### Critères de Succès Globaux

| Critère | Validation |
|---------|-----------|
| Règle 1: CLOSEST FIT regroupement | ✅ Démontré Scénarios 1,3,6 |
| Règle 2: CLOSEST FIT division | ✅ Démontré Scénarios 2,5 |
| Règle 3: heure_disponible_debut | ✅ Démontré Scénario 4 |
| Tri DÉCROISSANT fenêtre arrivée | ✅ Scénarios 1,6 |
| CLOSEST FIT fenêtre retour | ✅ Scénarios 3,6 |
| Fenêtres créées OK | ✅ Scénarios 3,6 |
| Heure_depart = MAX(arrival) | ✅ Tous scénarios |
| Passagers 100% assignés | ✅ Scénarios 1,2,4,5,6 |

### Métriques Attendues (Après tous les scénarios)

```
Total Réservations: 52
Total Passagers: 19+20+29+10+25+52 = 155

Attribution Prévu:
- Véhicule v1: 6 trajets, 40 passagers
- Véhicule v2: 4 trajets, 35 passagers
- Véhicule v3: 3 trajets, 32 passagers
- Véhicule v4: 1 trajet, 5 passagers
Total: 155 passagers assignés ✓

Partielles: 0 (tous assignés)
Non-assignées: 0
```

---

## NOTES IMPORTANTES

### Points Importants à Valider

1. **Ordre de traitement des réservations**:
   - Fenêtre arrivée: Tri DESC par passagers
   - Fenêtre retour: Pas de tri, CLOSEST FIT direct

2. **Sélection véhicule**:
   - Formule: `Math.abs(places - passagers)` = minimum
   - Tie-break: Moins de trajets → Diesel → Aléatoire

3. **Division**:
   - Chaque itération assigne MAX possible
   - Cherche CLOSEST FIT à chaque itération

4. **Disponibilité**:
   - Vérifier `heure_depart >= heure_disponible_debut`
   - v4 exclue avant 10:30

5. **Fenêtres d'attente**:
   - Durée: ± temps_attente (30 min)
   - Créées au retour si places restantes
   - Créées au nouvel arrivée si non assignée

### Debugging

Si un résultat ne correspond pas:

1. Vérifier l'ordre des arrivées (ORDER BY arrival_date)
2. Vérifier les écarts calculés (DEBUG print)
3. Vérifier les fenêtres créées (début/fin)
4. Vérifier les conflits d'horaires
5. Vérifier les trajets (pour le tie-break)

---

**Fin du document de simulation Sprint 8**

*Tous les scénarios sont prêts pour exécution et validation.*
