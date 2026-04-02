# SPRINT 8 - SIMULATION DÉTAILLÉE AVEC HEURES DE RETOUR

## Configuration

| Véhicule | Places | Carburant | Disponibilité |
|----------|--------|-----------|---------------|
| v1 | 10 | Diesel | Toujours |
| v2 | 10 | Essence | Toujours |
| v3 | 12 | Diesel | Toujours |
| v4 | 8 | Diesel | À partir de 10:30 |

**Calcul des temps de trajet:**
- CARLTON -> IVATO: 25km / 50km/h = 30min aller = **60min aller-retour**
- COLBERT -> IVATO: 30km / 50km/h = 36min aller = **72min aller-retour**

---

## RÈGLE FONDAMENTALE - TOUJOURS VÉRIFIER EN PREMIER

```
À CHAQUE INSTANT DE TRAITEMENT (début fenêtre, retour véhicule, etc.):
  1. TOUJOURS vérifier s'il existe des réservations NON ASSIGNÉES
     avec arrival_date < instant_courant
  2. Si OUI:
     a. Trier par nb_passagers DESC
     b. Prendre le MAX
     c. Trouver le véhicule CLOSEST FIT
     d. Assigner
  3. Continuer avec les réservations de la fenêtre courante
```

---

# JOUR 1: 27/03/2026 - REGROUPEMENT OPTIMAL

## Données d'entrée

| ID | Client | Passagers | arrival_date |
|----|--------|-----------|--------------|
| 1 | J1_r1_9pass | 9 | 08:00 |
| 2 | J1_r2_5pass | 5 | 07:55 |
| 3 | J1_r3_3pass | 3 | 07:50 |
| 4 | J1_r4_2pass | 2 | 07:40 |

## État des véhicules au début

| Véhicule | Statut à 07:40 | Heure Retour |
|----------|----------------|--------------|
| v1 | DISPONIBLE | - |
| v2 | DISPONIBLE | - |
| v3 | DISPONIBLE | - |
| v4 | INDISPONIBLE (avant 10:30) | - |

## Simulation pas à pas

### 07:40 - Début de traitement

**Vérification réservations non assignées avant 07:40:** AUCUNE

**Fenêtre créée:** [07:40 - 08:10] (première réservation r4 arrive)

**Réservations dans la fenêtre:**
- r4(2) arrive 07:40 ✓
- r3(3) arrive 07:50 ✓
- r2(5) arrive 07:55 ✓
- r1(9) arrive 08:00 ✓

**Tri DESC:** r1(9) > r2(5) > r3(3) > r4(2)

**MAX(arrival_date) = 08:00**

### Traitement r1(9) - MAXIMUM

```
Vehicules disponibles: v1(10), v2(10), v3(12)
CLOSEST FIT pour 9 passagers:
  v1(10): |10-9| = 1 ← MINIMUM (Diesel prioritaire)
  v2(10): |10-9| = 1
  v3(12): |12-9| = 3
→ v1 choisie
→ v1 prend r1(9), reste 1 place
```

**Regroupement v1 (1 place):**
```
CLOSEST FIT:
  r4(2): |1-2| = 1 ← MINIMUM (préfère remplir: 2 >= 1)
  r3(3): |1-3| = 2
  r2(5): |1-5| = 4
→ v1 prend 1 de r4
→ v1 = 10 PLEIN
```

### Traitement r2(5) - PROCHAIN MAX

```
Vehicules disponibles: v2(10), v3(12)
CLOSEST FIT pour 5 passagers:
  v2(10): |10-5| = 5 ← MINIMUM
  v3(12): |12-5| = 7
→ v2 choisie
→ v2 prend r2(5), reste 5 places
```

**Regroupement v2 (5 places):**
```
CLOSEST FIT:
  r3(3): |5-3| = 2 ← MINIMUM
  r4_reste(1): |5-1| = 4
→ v2 prend r3(3), reste 2 places

CLOSEST FIT (2 places):
  r4_reste(1): |2-1| = 1
→ v2 prend r4_reste(1)
→ v2 = 9 passagers
```

## Résultat JOUR 1

| Véhicule | Réservations | Pass. | Départ | Retour Calculé |
|----------|--------------|-------|--------|----------------|
| v1 | r1(9) + r4(1) | 10 | **08:00** | **09:00** (08:00 + 60min) |
| v2 | r2(5) + r3(3) + r4(1) | 9 | **08:00** | **09:00** (08:00 + 60min) |
| v3 | - | 0 | - | - |
| v4 | - | 0 | - | - |

**Vérification:** 9+1 + 5+3+1 = **19 passagers** ✓

---

# JOUR 2: 28/03/2026 - DIVISION OPTIMALE

## Données d'entrée

| ID | Client | Passagers | arrival_date |
|----|--------|-----------|--------------|
| 5 | J2_r1_20pass | 20 | 09:00 |

## État des véhicules au début

| Véhicule | Statut à 09:00 | Heure Retour |
|----------|----------------|--------------|
| v1 | DISPONIBLE | - |
| v2 | DISPONIBLE | - |
| v3 | DISPONIBLE | - |
| v4 | INDISPONIBLE (avant 10:30) | - |

## Simulation pas à pas

### 09:00 - Début de traitement

**Vérification réservations non assignées avant 09:00:** AUCUNE

**Fenêtre créée:** [09:00 - 09:30]

**Division r1(20):**
```
Iteration 1: 20 passagers restants
CLOSEST FIT:
  v1(10): |10-20| = 10
  v2(10): |10-20| = 10
  v3(12): |12-20| = 8 ← MINIMUM
  v4: INDISPONIBLE
→ v3 prend 12 passagers
→ Reste: 8 passagers

Iteration 2: 8 passagers restants
CLOSEST FIT:
  v1(10): |10-8| = 2 ← MINIMUM (Diesel)
  v2(10): |10-8| = 2
→ v1 prend 8 passagers
→ TOUS ASSIGNÉS
```

## Résultat JOUR 2

| Véhicule | Réservation | Pass. | Départ | Retour Calculé |
|----------|-------------|-------|--------|----------------|
| v3 | r1 (partie 1) | 12 | **09:00** | **10:00** (09:00 + 60min) |
| v1 | r1 (partie 2) | 8 | **09:00** | **10:00** (09:00 + 60min) |

**Vérification:** 12 + 8 = **20 passagers** ✓

---

# JOUR 3: 29/03/2026 - RETOUR VÉHICULE + FENÊTRE (COMPLEXE)

## Données d'entrée

| ID | Client | Passagers | arrival_date | Note |
|----|--------|-----------|--------------|------|
| 6 | J3_r1_10pass | 10 | 07:00 | Matin |
| 7 | J3_r2_10pass | 10 | 07:00 | Matin |
| 8 | J3_r3_12pass | 12 | 07:00 | Matin |
| 9 | J3_r4_9pass | 9 | 07:30 | HORS fenêtre 1 |
| 10 | J3_r5_5pass | 5 | 07:45 | HORS fenêtre 1 |
| 11 | J3_r6_7pass | 7 | 08:15 | Dans fenêtre retour |
| 12 | J3_r7_8pass | 8 | 08:20 | Dans fenêtre retour |

## Simulation pas à pas

### 07:00 - FENÊTRE 1 [07:00 - 07:30] (INTERVALLE FERMÉ)

**Vérification réservations non assignées avant 07:00:** AUCUNE

**Réservations dans fenêtre [07:00-07:30]:** (intervalle fermé, 07:30 INCLUS)
- r1(10) arrive 07:00 ✓
- r2(10) arrive 07:00 ✓
- r3(12) arrive 07:00 ✓
- r4(9) arrive 07:30 ✓ (INCLUS car intervalle fermé)

**Tri DESC:** r3(12) > r1(10) = r2(10) > r4(9)

**Total passagers:** 10+10+12+9 = 41
**Places disponibles:** v1(10)+v2(10)+v3(12) = 32
→ Pas assez de places pour tous!

```
Traiter r3(12) - MAX:
  v3(12): |12-12| = 0 ← PARFAIT
→ v3 prend r3(12) = PLEIN

Traiter r1(10):
  v1(10): |10-10| = 0 ← (Diesel prioritaire)
  v2(10): |10-10| = 0
→ v1 prend r1(10) = PLEIN

Traiter r2(10):
→ v2 prend r2(10) = PLEIN

Traiter r4(9):
→ AUCUN VÉHICULE DISPONIBLE
→ r4 reste NON ASSIGNÉE
```

**Calcul heure_depart:**
- v3: réservations assignées = r3(07:00) → heure_depart = 07:00
- v1: réservations assignées = r1(07:00) → heure_depart = 07:00
- v2: réservations assignées = r2(07:00) → heure_depart = 07:00

Note: r4 n'a pas été assignée, donc son arrival_date (07:30) n'affecte PAS heure_depart

**État après fenêtre 1:**

| Véhicule | Départ | Retour Calculé | Passagers |
|----------|--------|----------------|-----------|
| v3 | 07:00 | **08:00** | 12 |
| v1 | 07:00 | **08:00** | 10 |
| v2 | 07:00 | **08:00** | 10 |

**Réservations NON ASSIGNÉES:** r4(9) arrivé 07:30, r5(5) arrivé 07:45

### 07:30 - r4 arrive

**Véhicules disponibles à 07:30:** AUCUN (tous reviennent à 08:00)

→ r4 reste NON ASSIGNÉE

### 07:45 - r5 arrive

**Véhicules disponibles à 07:45:** AUCUN (tous reviennent à 08:00)

→ r5 reste NON ASSIGNÉE

### ⚠️ 08:00 - v1, v2, v3 RETOURNENT (POINT CLÉ)

**Vérification réservations non assignées AVANT 08:00:**
- r4(9) arrivé 07:30 = **PRIORITAIRE**
- r5(5) arrivé 07:45 = **PRIORITAIRE**

**Tri DESC des prioritaires:** r4(9) > r5(5)

---

#### ÉTAPE 1: Traiter r4(9) - MAX des prioritaires

```
CLOSEST FIT parmi v1, v2, v3:
  v1(10): |10-9| = 1 ← MINIMUM (Diesel)
  v2(10): |10-9| = 1
  v3(12): |12-9| = 3
→ v1 choisie

v1 prend r4(9), reste 1 place

Regroupement v1 (1 place) - autres prioritaires:
  r5(5): |1-5| = 4
→ v1 prend 1 de r5
→ v1 = 10 PLEIN

*** v1 PLEIN AU MOMENT EXACT DE SON RETOUR (08:00) ***
→ v1 DÉPART IMMÉDIAT à 08:00
→ PAS DE FENÊTRE créée pour v1
```

**v1 part à 08:00** (retour prévu 09:00)

---

#### ÉTAPE 2: Traiter r5(4 restants) avec v2, v3

**Il reste v2(10), v3(12) à 08:00**

**Vérification réservations non assignées AVANT 08:00:**
- r5(4 restants) arrivé 07:45 = **PRIORITAIRE**

```
CLOSEST FIT parmi v2, v3:
  v2(10): |10-4| = 6 ← MINIMUM
  v3(12): |12-4| = 8
→ v2 choisie

v2 prend r5(4), reste 6 places

Vérification: autres réservations AVANT 08:00?
→ AUCUNE

*** v2 NON PLEIN après les prioritaires ***
→ CRÉER FENÊTRE DE REGROUPEMENT [08:00 - 08:30]
→ v3 aussi retourné à 08:00 → INCLUS dans cette fenêtre
```

---

#### ÉTAPE 3: FENÊTRE [08:00 - 08:30] - v2 (6 places), v3 (12 places)

**Réservations dans la fenêtre:**
- r6(7) arrive à 08:15 ✓
- r7(8) arrive à 08:20 ✓

**D'abord: REMPLIR v2 (6 places restantes)**

```
CLOSEST FIT pour 6 places:
  r6(7): |6-7| = 1 ← MINIMUM (préfère remplir: 7 >= 6)
  r7(8): |6-8| = 2
→ v2 prend 6 de r6
→ v2 = 10 PLEIN

r6 reste 1 passager non assigné
```

**Ensuite: Traiter v3 (12 places) avec réservations restantes**

**Tri DESC:** r7(8) > r6(1 restant)

```
Traiter r7(8) - MAX:
  v3(12): |12-8| = 4
→ v3 prend r7(8), reste 4 places

Regroupement v3 (4 places):
  r6(1 restant): |4-1| = 3
→ v3 prend r6(1)
→ v3 = 9 passagers
```

**Calcul heure_depart commune pour la fenêtre:**
```
Réservations assignées dans la fenêtre:
  - v2: r5(07:45), r6(08:15)
  - v3: r7(08:20), r6(08:15)

MAX(arrival_date des ASSIGNÉES) = MAX(07:45, 08:15, 08:20, 08:15) = 08:20
heure_retour des véhicules = 08:00 < 08:20

→ v2 et v3 partent à 08:20 (MAX des assignées dans la fenêtre)
```

## Résultat JOUR 3

| Véhicule | Trajet | Réservations | Pass. | Départ | Retour Calculé | Note |
|----------|--------|--------------|-------|--------|----------------|------|
| v3 | 1 | r3(12) | 12 | 07:00 | **08:00** | |
| v1 | 1 | r1(10) | 10 | 07:00 | **08:00** | |
| v2 | 1 | r2(10) | 10 | 07:00 | **08:00** | |
| v1 | 2 | r4(9) + r5(1) | 10 | **08:00** | **09:00** | DÉPART IMMÉDIAT |
| v2 | 2 | r5(4) + r6(6) | 10 | **08:20** | **09:20** | Fenêtre [08:00-08:30] |
| v3 | 2 | r7(8) + r6(1) | 9 | **08:20** | **09:20** | Même fenêtre que v2 |

**Vérification:**
- r1: 10/10 ✓
- r2: 10/10 ✓
- r3: 12/12 ✓
- r4: 9/9 ✓
- r5: 1+4 = 5/5 ✓
- r6: 6+1 = 7/7 ✓
- r7: 8/8 ✓
- **Total: 61 passagers** ✓

**Points clés JOUR 3:**
1. v1 part à **08:00** car PLEIN immédiatement (pas de fenêtre)
2. v2 et v3 partent à **08:20** car dans la même fenêtre [08:00-08:30]
3. Fenêtre créée à partir de **08:00** (heure retour véhicule non plein), PAS 07:45

---

# JOUR 4: 30/03/2026 - HEURE_DISPONIBLE_DEBUT

## Données d'entrée

| ID | Client | Passagers | arrival_date |
|----|--------|-----------|--------------|
| 13 | J4_r1_4pass | 4 | 10:00 |
| 14 | J4_r2_6pass | 6 | 10:25 |

## État des véhicules

| Véhicule | Statut à 10:00 | heure_disponible_debut |
|----------|----------------|------------------------|
| v1 | DISPONIBLE | - |
| v2 | DISPONIBLE | - |
| v3 | DISPONIBLE | - |
| v4 | **INDISPONIBLE** | **10:30** |

## Simulation

### 10:00 - FENÊTRE [10:00 - 10:30]

**Vérification réservations non assignées avant 10:00:** AUCUNE

**Tri DESC:** r2(6) > r1(4)

```
Traiter r2(6):
Véhicules disponibles à 10:00: v1, v2, v3 (v4 PAS DISPONIBLE)
CLOSEST FIT:
  v1(10): |10-6| = 4 ← MINIMUM (Diesel)
  v2(10): |10-6| = 4
  v3(12): |12-6| = 6
→ v1 prend r2(6), reste 4 places

Regroupement v1 (4 places):
  r1(4): |4-4| = 0 ← PARFAIT
→ v1 prend r1(4)
→ v1 = 10 PLEIN

heure_depart = MAX(r2=10:25, r1=10:00) = 10:25
```

## Résultat JOUR 4

| Véhicule | Réservations | Pass. | Départ | Retour Calculé |
|----------|--------------|-------|--------|----------------|
| v1 | r2(6) + r1(4) | 10 | **10:25** | **11:25** |
| v4 | - | 0 | - | - |

**Vérification:** v4 NON utilisée (disponible seulement à 10:30) ✓

---

# JOUR 5: 31/03/2026 - DIVISION 3 PARTIES

## Données d'entrée

| ID | Client | Passagers | arrival_date |
|----|--------|-----------|--------------|
| 15 | J5_r1_25pass | 25 | 10:30 |

## État des véhicules à 10:30

| Véhicule | Statut | Places |
|----------|--------|--------|
| v1 | DISPONIBLE | 10 |
| v2 | DISPONIBLE | 10 |
| v3 | DISPONIBLE | 12 |
| v4 | **DISPONIBLE** (10:30) | 8 |

## Simulation

**Vérification réservations non assignées avant 10:30:** AUCUNE

**Division r1(25):**
```
Iteration 1: 25 passagers
CLOSEST FIT:
  v1(10): |10-25| = 15
  v2(10): |10-25| = 15
  v3(12): |12-25| = 13 ← MINIMUM
  v4(8): |8-25| = 17
→ v3 prend 12
→ Reste: 13

Iteration 2: 13 passagers
CLOSEST FIT:
  v1(10): |10-13| = 3 ← MINIMUM (Diesel)
  v2(10): |10-13| = 3
  v4(8): |8-13| = 5
→ v1 prend 10
→ Reste: 3

Iteration 3: 3 passagers
CLOSEST FIT:
  v2(10): |10-3| = 7
  v4(8): |8-3| = 5 ← MINIMUM
→ v4 prend 3
→ TOUS ASSIGNÉS
```

## Résultat JOUR 5

| Véhicule | Réservation | Pass. | Départ | Retour Calculé |
|----------|-------------|-------|--------|----------------|
| v3 | r1 (12/25) | 12 | **10:30** | **11:30** |
| v1 | r1 (10/25) | 10 | **10:30** | **11:30** |
| v4 | r1 (3/25) | 3 | **10:30** | **11:30** |

**Vérification:** 12 + 10 + 3 = **25 passagers** ✓
**Note:** v4 UTILISÉE car disponible à 10:30 ✓

---

# JOUR 6: 01/04/2026 - DÉPART IMMÉDIAT

## Contexte initial

Attribution existante:
| Véhicule | Départ | Retour | Passagers |
|----------|--------|--------|-----------|
| v1 | 07:00 | **08:00** | 10 |

## Données d'entrée

| ID | Client | Passagers | arrival_date | Note |
|----|--------|-----------|--------------|------|
| 16 | J6_r1_10pass | 10 | 07:30 | AVANT retour v1 |
| 17 | J6_r2_5pass | 5 | 08:15 | APRÈS retour v1 |

## Simulation

### 08:00 - v1 retourne

**Vérification réservations non assignées avant 08:00:**
- r1(10) arrivé 07:30 = **PRIORITAIRE**

**Tri DESC:** r1(10)

```
Traiter r1(10) PRIORITAIRE:
CLOSEST FIT:
  v1(10): |10-10| = 0 ← PARFAIT
  v2(10): |10-10| = 0
  v3(12): |12-10| = 2
→ v1 prend r1(10) = PLEIN IMMÉDIATEMENT

*** DÉPART IMMÉDIAT ***
v1 remplie PAR réservation arrivée AVANT heure_retour
→ v1 part à 08:00 (heure_retour)
→ PAS DE FENÊTRE DE REGROUPEMENT
```

**heure_depart v1 = 08:00 (heure_retour car rempli immédiatement)**

### 08:15 - r2 arrive

**Véhicules disponibles:** v2(10), v3(12)

**Fenêtre:** [08:15 - 08:45]

```
Traiter r2(5):
CLOSEST FIT:
  v2(10): |10-5| = 5 ← MINIMUM
  v3(12): |12-5| = 7
→ v2 prend r2(5), reste 5 places
→ Pas d'autres réservations

heure_depart v2 = 08:15
```

## Résultat JOUR 6

| Véhicule | Réservations | Pass. | Départ | Retour Calculé | Note |
|----------|--------------|-------|--------|----------------|------|
| v1 | r1(10) | 10 | **08:00** | **09:00** | **DÉPART IMMÉDIAT** |
| v2 | r2(5) | 5 | **08:15** | **09:15** | Fenêtre créée |

**Point clé:** v1 part à **08:00** (pas 08:15) car remplie immédiatement au retour

---

# JOUR 7: 02/04/2026 - MÊME HEURE ARRIVÉE

## Données d'entrée

| ID | Client | Passagers | arrival_date |
|----|--------|-----------|--------------|
| 18 | J7_r1_8pass | 8 | 10:30 |
| 19 | J7_r2_3pass | 3 | 10:00 |

## État véhicules

v4 devient disponible à **10:30** (heure_disponible_debut)

## Simulation

### 10:00 - FENÊTRE 1 [10:00 - 10:30]

**Vérification réservations non assignées avant 10:00:** AUCUNE

**Véhicules disponibles:** v1, v2, v3 (v4 pas encore)

**Tri DESC:** r2(3)

```
Traiter r2(3):
CLOSEST FIT:
  v1(10): |10-3| = 7 ← (Diesel)
  v2(10): |10-3| = 7
  v3(12): |12-3| = 9
→ v1 prend r2(3), reste 7 places
```

### 10:30 - r1 arrive ET v4 devient disponible

**Véhicules disponibles:** v1 (7 places restantes), v2, v3, v4

**Regroupement v1 (7 places):**
```
CLOSEST FIT:
  r1(8): |7-8| = 1 ← préfère remplir (8 >= 7)
→ v1 prend 7 de r1
→ v1 = 10 PLEIN

heure_depart v1 = MAX(r2=10:00, r1=10:30) = 10:30
```

**Reste de r1:** 1 passager

```
Traiter r1(1 restant):
CLOSEST FIT:
  v4(8): |8-1| = 7 ← MINIMUM
  v2(10): |10-1| = 9
  v3(12): |12-1| = 11
→ v4 prend r1(1)

heure_depart v4 = 10:30 (arrival_date de r1)
```

## Résultat JOUR 7

| Véhicule | Réservations | Pass. | Départ | Retour Calculé |
|----------|--------------|-------|--------|----------------|
| v1 | r2(3) + r1(7) | 10 | **10:30** | **11:30** |
| v4 | r1(1) | 1 | **10:30** | **11:30** |

**Vérification:** 3 + 7 + 1 = **11 passagers** (r2=3, r1=8) ✓

---

# TABLEAU RÉCAPITULATIF COMPLET

| Jour | Véhicule | Trajet | Départ | Retour | Passagers | Réservations | Note |
|------|----------|--------|--------|--------|-----------|--------------|------|
| J1 | v1 | 1 | 08:00 | 09:00 | 10 | r1(9)+r4(1) | |
| J1 | v2 | 1 | 08:00 | 09:00 | 9 | r2(5)+r3(3)+r4(1) | |
| J2 | v3 | 1 | 09:00 | 10:00 | 12 | r1(12) | Division |
| J2 | v1 | 1 | 09:00 | 10:00 | 8 | r1(8) | Division |
| J3 | v3 | 1 | 07:00 | 08:00 | 12 | r3(12) | |
| J3 | v1 | 1 | 07:00 | 08:00 | 10 | r1(10) | |
| J3 | v2 | 1 | 07:00 | 08:00 | 10 | r2(10) | |
| J3 | v1 | 2 | **08:00** | 09:00 | 10 | r4(9)+r5(1) | **DÉPART IMMÉDIAT** |
| J3 | v2 | 2 | **08:20** | 09:20 | 10 | r5(4)+r6(6) | Fenêtre [08:00-08:30] |
| J3 | v3 | 2 | **08:20** | 09:20 | 9 | r7(8)+r6(1) | Même fenêtre |
| J4 | v1 | 1 | 10:25 | 11:25 | 10 | r2(6)+r1(4) | |
| J5 | v3 | 1 | 10:30 | 11:30 | 12 | r1(12) | Division |
| J5 | v1 | 1 | 10:30 | 11:30 | 10 | r1(10) | Division |
| J5 | v4 | 1 | 10:30 | 11:30 | 3 | r1(3) | Division |
| J6 | v1 | 2 | 08:00 | 09:00 | 10 | r1(10) | DÉPART IMMÉDIAT |
| J6 | v2 | 1 | 08:15 | 09:15 | 5 | r2(5) | |
| J7 | v1 | 1 | 10:30 | 11:30 | 10 | r2(3)+r1(7) | |
| J7 | v4 | 1 | 10:30 | 11:30 | 1 | r1(1) | |

**TOTAL: 161 passagers sur 7 jours**

---

## RÈGLES CLÉS ILLUSTRÉES

### 1. Départ Immédiat (J3-v1, J6-v1)
```
CONDITION: Véhicule rempli UNIQUEMENT par réservations avec:
  arrival_date <= heure_retour_vehicule (ou heure_disponible_debut)

→ DÉPART IMMÉDIAT à heure_retour (ou heure_disponible_debut)
→ PAS de fenêtre de regroupement créée

Exemple:
  v1 retourne à 08:00
  r4 arrive 07:30 (07:30 <= 08:00) ✓
  r5 arrive 08:00 (08:00 <= 08:00) ✓  ← INCLUS car arrivée = heure_retour
  Si v1 rempli par r4+r5 → DÉPART IMMÉDIAT à 08:00
```

### 2. Fenêtre créée à partir du retour véhicule (J3-v2,v3)
```
CONDITION: Véhicule NON PLEIN par réservations <= heure_retour
  OU Véhicule reçoit des réservations avec arrival_date > heure_retour

→ CRÉER FENÊTRE [heure_retour - heure_retour + 30min]
→ Tous les véhicules retournés en même temps sont dans la même fenêtre
→ Ils partent tous à la même heure = MAX(arrival_date des TOUTES réservations assignées)
```

### 3. Tri des priorités (en cas d'égalité d'écart)
```
1. Écart minimum (CLOSEST FIT): |nb_places - nb_passagers|
2. Moins de trajets (véhicule avec le moins de trajets effectués)
3. Diesel prioritaire
4. Aléatoire
```
