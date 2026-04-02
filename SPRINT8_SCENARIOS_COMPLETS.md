# SPRINT 8 - SIMULATION COMPLETE AVEC TOUS LES SCENARIOS

## REGLES SPRINT 8 - RAPPEL

### DEUX TYPES DE FENETRES

#### 1. Fenetre issue d'une ARRIVEE DE RESERVATION
- Creee a partir de la premiere reservation qui arrive
- Duree: temps_attente (30 min) apres la premiere arrivee
- **Tri DECROISSANT** par nb_passagers
- Traiter d'abord la reservation avec le **MAXIMUM** de passagers
- Selectionner le vehicule avec **CLOSEST FIT** (ecart minimum)
- Remplir le vehicule avec **CLOSEST FIT**

**CALCUL DE L'HEURE DE DEPART:**
```
Par defaut: heure_depart = MAX(arrival_date) dans la fenetre

CAS: vehicule revenant DANS la fenetre
  Si heure_retour >= MAX(arrival_date):
    -> heure_depart = heure_retour
  Sinon:
    -> heure_depart = MAX(arrival_date)

VALIDATION: Un depart est valide UNIQUEMENT si au moins une reservation est assignee
```

#### 2. Fenetre issue d'un RETOUR VEHICULE (vehicule revient non plein)
- Creee quand un vehicule revient de course et n'est pas immediatement plein
- **CLOSEST FIT** directement sur les restes prioritaires et nouvelles arrivees
- Pas de tri DESC prealable

### REGLES DE SELECTION VEHICULE (CLOSEST FIT)
```
1. Calculer ecart = |nb_places - nb_passagers| pour chaque vehicule
2. Choisir le vehicule avec l'ecart MINIMUM
3. En cas d'egalite:
   a. Moins de trajets effectues
   b. Diesel prioritaire
   c. Aleatoire
```

### REGLES DE REGROUPEMENT (CLOSEST FIT)
```
Apres assignation d'une reservation a un vehicule:
1. Calculer places_restantes = nb_places - passagers_assignes
2. Si places_restantes > 0:
   a. Chercher reservations non assignees avec meme lieu_depart
   b. Pour chaque candidat: ecart = |places_restantes - nb_passagers|
   c. Choisir celui avec ecart MINIMUM
   d. Si egalite d'ecart: preferer celui qui REMPLIT le vehicule (nb_passagers >= places_restantes)
   e. Repeter jusqu'a vehicule plein ou plus de candidats
```

### REGLES DE DIVISION
```
Si reservation.nb_passagers > vehicule.nb_places:
1. Assigner ce que le vehicule peut prendre
2. Creer reste_non_assigne = nb_passagers - places_vehicule
3. Chercher prochain vehicule avec CLOSEST FIT pour le reste
4. Repeter jusqu'a tous passagers assignes ou plus de vehicule
```

### REGLES DE RETOUR VEHICULE
```
A l'heure de retour d'un vehicule:
1. Verifier s'il existe des reservations non assignees avant cette heure
2. Si oui:
   a. Trier par nb_passagers DESC
   b. Prendre le MAX
   c. Assigner avec CLOSEST FIT
   d. Si vehicule PLEIN -> part immediatement (pas de fenetre)
   e. Si vehicule NON PLEIN -> creer fenetre de regroupement
3. Si non:
   a. Verifier si une reservation arrive au meme moment
   b. Si oui: traiter comme fenetre d'arrivee de reservation
```

---

## CONFIGURATION

| Vehicule | Places | Carburant | Disponibilite |
|----------|--------|-----------|---------------|
| v1 | 10 | Diesel | Toujours |
| v2 | 10 | Essence | Toujours |
| v3 | 12 | Diesel | Toujours |
| v4 | 8 | Hybride | A partir de 10:30 |

**Parametres:**
- Vitesse moyenne: 50 km/h
- Temps d'attente (fenetre): 30 min
- CARLTON -> IVATO: 25km = 30min aller, 60min total
- COLBERT -> IVATO: 30km = 36min aller, 72min total

---

## JOUR 1: 27/03/2026 - REGROUPEMENT OPTIMAL

### Reservations

| ID | Client | Passagers | Heure arrivee |
|----|--------|-----------|---------------|
| 1 | J1_r1_9pass | 9 | 08:00 |
| 2 | J1_r2_5pass | 5 | 07:55 |
| 3 | J1_r3_3pass | 3 | 07:50 |
| 4 | J1_r4_2pass | 2 | 07:40 |

**Total: 19 passagers**

### Construction de la Fenetre

```
Premiere arrivee: r4 a 07:40
Fenetre: [07:40 - 08:10] (temps_attente = 30 min)

Reservations dans la fenetre:
- r4(2) arrive 07:40 OK
- r3(3) arrive 07:50 OK
- r2(5) arrive 07:55 OK
- r1(9) arrive 08:00 OK

MAX(arrival_date) = 08:00
heure_depart = 08:00 (aucun vehicule en cours)
```

### Logique Appliquee

```
FENETRE ARRIVEE RESERVATION [07:40 - 08:10]

ETAPE 0: Tri DECROISSANT par passagers
  Ordre de traitement: r1(9) > r2(5) > r3(3) > r4(2)

ETAPE 1: Traiter r1(9 passagers) - LE MAXIMUM
  Selection vehicule (CLOSEST FIT parmi ceux qui peuvent contenir 9):
    - v1(10): |10-9| = 1 (MINIMUM, diesel prioritaire)
    - v2(10): |10-9| = 1
    - v3(12): |12-9| = 3
  -> v1 choisie (ecart=1, diesel)
  -> v1 prend r1(9), reste 1 place

  Regroupement v1 (1 place restante) - CLOSEST FIT:
    - r4(2): |1-2| = 1 (MINIMUM, car 2 >= 1 remplit le vehicule)
    - r3(3): |1-3| = 2
    - r2(5): |1-5| = 4
  -> v1 prend 1 passager de r4 = 10 PLEIN
  -> v1 depart 08:00, retour 09:00
  -> r4 RESTE 1 passager non assigne

Reservation restante apres ETAPE 1:
- r2(5) complet
- r3(3) complet
- r4(1) restant

Vehicule disponible restant entre [07:40 - 08:10]:
- v2(10)
- v3(12)

ETAPE 2: Traiter r2(5 passagers) - PROCHAIN MAXIMUM
  Selection vehicule:
    - v2(10): |10-5| = 5 (MINIMUM)
    - v3(12): |12-5| = 7
  -> v2 choisie (ecart=5)
  -> v2 prend r2(5), reste 5 places

  Regroupement v2 (5 places) - CLOSEST FIT:
    - r3(3): |5-3| = 2 (MINIMUM)
    - r4_reste(1): |5-1| = 4
  -> v2 prend r3(3), reste 2 places

  Regroupement v2 (2 places) - CLOSEST FIT:
    - r4_reste(1): |2-1| = 1
  -> v2 prend r4_reste(1), total = 9
  -> v2 depart 08:00, retour 09:00

ETAPE 3: Plus de reservations a traiter
  -> v3, v4 non utilises
```

### Resultat Attendu Jour 1

| Vehicule | Reservations | Passagers | Depart | Retour |
|----------|--------------|-----------|--------|--------|
| v1 | r1(9) + r4(1) | 10 | 08:00 | 09:00 |
| v2 | r2(5) + r3(3) + r4(1) | 9 | 08:00 | 09:00 |
| v3 | - | 0 | - | - |
| v4 | - | 0 | - | - |

**Verification:** 9+1 + 5+3+1 = 19 passagers (tous assignes)

**Points cles:**
- r1 traitee EN PREMIER car 9 = maximum (tri DESC)
- r4 choisie pour regroupement car ecart=1 (CLOSEST FIT)
- r4 divisee entre v1(1) et v2(1)

---

## JOUR 2: 28/03/2026 - DIVISION OPTIMALE

### Reservations

| ID | Client | Passagers | Heure arrivee |
|----|--------|-----------|---------------|
| 5 | J2_r1_20pass | 20 | 09:00 |

### Logique DIVISION

```
09:00 - r1(20 pass) arrive:

ETAPE 1: Une seule reservation, pas de tri necessaire
  Selection vehicule (CLOSEST FIT parmi TOUS car aucun ne peut contenir 20):
    - v1(10): |10-20| = 10
    - v2(10): |10-20| = 10
    - v3(12): |12-20| = 8 (MINIMUM)
  -> v3 choisie
  -> v3 prend 12 passagers, reste 8

ETAPE 2 (Division): 8 passagers restants
  Vehicules disponibles: v1, v2, v4(non dispo avant 10:30)
  CLOSEST FIT:
    - v1(10): |10-8| = 2 (MINIMUM, egalite avec v2)
    - v2(10): |10-8| = 2
  -> Tie-break: moins de trajets > diesel > aleatoire
  -> v1 choisie (diesel prioritaire)
  -> v1 prend 8 passagers
  -> TOUS assignes
```

### Resultat Attendu Jour 2

| Vehicule | Reservation | Passagers | Depart | Retour |
|----------|-------------|-----------|--------|--------|
| v3 | r1 (partie 1) | 12 | 09:00 | 10:00 |
| v1 | r1 (partie 2) | 8 | 09:00 | 10:00 |

**Verification:** 12 + 8 = 20 passagers (tous assignes)

**Points cles:**
- v3(12) choisie car ecart=8 < ecart v1/v2=10 (CLOSEST FIT pour division)
- v4 non disponible (heure_disponible_debut = 10:30)

---

## JOUR 3: 29/03/2026 - RETOUR VEHICULE + FENETRE D'ATTENTE (CAS COMPLEXE)

### Reservations

| ID | Client | Passagers | Heure arrivee | Note |
|----|--------|-----------|---------------|------|
| 6 | J3_r1_10pass_MATIN | 10 | 07:00 | Occupe v1 |
| 7 | J3_r2_10pass_MATIN | 10 | 07:00 | Occupe v2 |
| 8 | J3_r3_12pass_MATIN | 12 | 07:00 | Occupe v3 |
| 9 | J3_r4_9pass_RESTE | 9 | 07:30 | Prioritaire |
| 10 | J3_r5_5pass_RESTE | 5 | 07:45 | Prioritaire |
| 11 | J3_r6_7pass | 7 | 08:15 | Dans fenetre |
| 12 | J3_r7_8pass | 8 | 08:20 | Dans fenetre |

### Logique Complete

```
========================================
FENETRE 1 [07:00 - 07:30]
========================================

Tri DESC: r3(12) > r1(10) = r2(10)
(r4, r5 arrivent APRES le debut de fenetre donc pas incluses)

ETAPE 1: Traiter r3(12) - MAXIMUM
  Vehicules: v1(10), v2(10), v3(12), v4(non dispo)
  CLOSEST FIT pour contenir 12:
    - v3(12): |12-12| = 0 (PARFAIT)
  -> v3 prend r3(12) = PLEIN
  -> v3 depart 07:00, retour 08:00 (CARLTON)

ETAPE 2: Traiter r1(10)
  Vehicules restants: v1(10), v2(10)
  CLOSEST FIT:
    - v1(10): |10-10| = 0
    - v2(10): |10-10| = 0
  -> Tie-break: diesel > v1 choisie
  -> v1 prend r1(10) = PLEIN
  -> v1 depart 07:00, retour 08:00

ETAPE 3: Traiter r2(10)
  -> v2 prend r2(10) = PLEIN
  -> v2 depart 07:00, retour 08:00

RESERVATIONS NON ASSIGNEES: r4(9), r5(5)
(arrivent a 07:30 et 07:45, apres la fenetre)

========================================
FENETRE 2 [07:45 - 08:15] (issue de r5 arrivee)
========================================
r5 arrive a 07:45, non assignee
-> Creer fenetre d'arrivee reservation [07:45 - 08:15]

Reservations dans cette fenetre:
- r4(9) arrive 07:30 (AVANT fenetre = prioritaire)
- r5(5) arrive 07:45 (debut fenetre)
- r6(7) arrive 08:15 (fin fenetre)

Vehicules disponibles a 07:45:
- v3(12) retourne a 08:00 (dans fenetre)
-> Seul v3 sera disponible, mais a 08:00

Comme aucun vehicule n'est dispo a 07:45, attendre...

A 08:00: v1, v2, v3 retournent tous

-> Traiter d'abord les reservations NON ASSIGNEES AVANT 08:00
-> r4(9) et r5(5) sont prioritaires

========================================
FENETRE 3 [08:00 - 08:30] (issue du retour v1, v2, v3)
========================================

Reservations non assignees avant 08:00 (PRIORITAIRES):
- r4(9)
- r5(5)

Tri DESC: r4(9) > r5(5)

ETAPE 1: Traiter r4(9) - MAXIMUM
  Vehicules dispo a 08:00: v1(10), v2(10), v3(12)
  CLOSEST FIT:
    - v1(10): |10-9| = 1 (MINIMUM, diesel)
    - v2(10): |10-9| = 1
    - v3(12): |12-9| = 3
  -> v1 choisie
  -> v1 prend r4(9), reste 1 place

  Regroupement v1 (1 place) - CLOSEST FIT:
    Candidats: r5(5)
    - r5(5): |1-5| = 4
  -> v1 prend 1 passager de r5 = 10 PLEIN
  -> v1 depart 08:00, retour 09:00
  -> r5 RESTE 4 passagers

ETAPE 2: Traiter r5_reste(4)
  Vehicules: v2(10), v3(12)
  CLOSEST FIT:
    - v2(10): |10-4| = 6 (MINIMUM)
    - v3(12): |12-4| = 8
  -> v2 choisie
  -> v2 prend r5_reste(4), reste 6 places

  v2 NON PLEIN -> creer fenetre de regroupement [08:00 - 08:30]

  Reservations arrivant dans [08:00 - 08:30]:
  - r6(7) arrive 08:15
  - r7(8) arrive 08:20

  Regroupement v2 (6 places) - CLOSEST FIT:
    - r6(7): |6-7| = 1 (MINIMUM, car 7 >= 6 remplit)
    - r7(8): |6-8| = 2
  -> v2 prend 6 passagers de r6 = 10 PLEIN
  -> r6 RESTE 1 passager
  -> v2 depart 08:15, retour 09:15

ETAPE 3: Traiter r6_reste(1) et r7(8)
  Vehicules: v3(12)

  Tri DESC: r7(8) > r6_reste(1)

  -> v3 prend r7(8), reste 4 places
  Regroupement v3 (4 places):
    - r6_reste(1): |4-1| = 3
  -> v3 prend r6_reste(1) = 9 total
  -> v3 depart 08:20, retour 09:20

FIN - Tous passagers assignes
```

### Resultat Attendu Jour 3

| Vehicule | Reservations | Passagers | Depart | Retour |
|----------|--------------|-----------|--------|--------|
| v3 | r3(12) | 12 | 07:00 | 08:00 |
| v1 | r1(10) | 10 | 07:00 | 08:00 |
| v2 | r2(10) | 10 | 07:00 | 08:00 |
| v1 | r4(9) + r5(1) | 10 | 08:00 | 09:00 |
| v2 | r5(4) + r6(6) | 10 | 08:15 | 09:15 |
| v3 | r7(8) + r6(1) | 9 | 08:20 | 09:20 |

**Verification:**
- Matin: 12 + 10 + 10 = 32 passagers
- Apres-midi: 10 + 10 + 9 = 29 passagers
- Total: 61 passagers (tous assignes)

---

## JOUR 4: 30/03/2026 - DISPONIBILITE HORAIRE (v4)

### Reservations

| ID | Client | Passagers | Heure arrivee |
|----|--------|-----------|---------------|
| 13 | J4_r1_4pass_AVANT_V4 | 4 | 10:00 |
| 14 | J4_r2_6pass_APRES_V4 | 6 | 10:35 |

### Logique

```
========================================
10:00 - r1(4 pass) arrive
========================================

VALIDATION v4: heure_disponible_debut = 10:30
  10:00 < 10:30 -> v4 NON DISPONIBLE

Vehicules disponibles:
  - v1(10): |10-4| = 6
  - v2(10): |10-4| = 6
  - v3(12): |12-4| = 8

CLOSEST FIT: v1 ou v2 (ecart=6)
  -> Tie-break: diesel -> v1 choisie
  -> v1 prend r1(4)
  -> v1 depart 10:00, retour 11:00

========================================
10:35 - r2(6 pass) arrive
========================================

VALIDATION v4: 10:35 >= 10:30 -> v4 DISPONIBLE

Vehicules disponibles:
  - v2(10): |10-6| = 4
  - v3(12): |12-6| = 6
  - v4(8): |8-6| = 2 (MINIMUM)

-> v4 choisie
-> v4 prend r2(6)
-> v4 depart 10:35, retour 11:35
```

### Resultat Attendu Jour 4

| Vehicule | Reservation | Passagers | Depart | Retour |
|----------|-------------|-----------|--------|--------|
| v1 | r1(4) | 4 | 10:00 | 11:00 |
| v4 | r2(6) | 6 | 10:35 | 11:35 |

**Verification:**
- v4 NON utilisee a 10:00 (avant heure_disponible)
- v4 utilisee a 10:35 (apres heure_disponible) avec CLOSEST FIT

---

## JOUR 5: 31/03/2026 - GESTION DES RESTES AVEC DIVISION

### Reservations

| ID | Client | Passagers | Heure arrivee |
|----|--------|-----------|---------------|
| 15 | J5_r1_10pass_BLOQUE_V2 | 10 | 08:00 |
| 16 | J5_r2_12pass_BLOQUE_V3 | 12 | 08:00 |
| 17 | J5_r3_25pass_GRANDE | 25 | 08:30 |

### Logique

```
========================================
FENETRE 1 [08:00 - 08:30]
========================================

Tri DESC: r2(12) > r1(10)

ETAPE 1: Traiter r2(12)
  CLOSEST FIT: v3(12) ecart=0
  -> v3 prend r2(12) = PLEIN
  -> v3 depart 08:00, retour 09:12 (COLBERT)

ETAPE 2: Traiter r1(10)
  CLOSEST FIT: v1(10) ou v2(10) ecart=0
  -> v1 choisie (diesel)
  -> v1 prend r1(10) = PLEIN
  -> v1 depart 08:00, retour 09:00

Vehicules restants: v2(10)
Pas d'autres reservations dans cette fenetre

========================================
08:30 - r3(25 pass) arrive
========================================

Vehicules disponibles a 08:30: v2(10) seulement
(v1 revient 09:00, v3 revient 09:12, v4 non dispo)

DIVISION NECESSAIRE:
  r3(25) > v2(10)

ITERATION 1:
  -> v2(10) prend 10 de r3
  -> r3 RESTE 15 passagers
  -> v2 depart 08:30, retour 09:30

ATTENTE: Plus de vehicule disponible a 08:30
-> Attendre retour v1 a 09:00

========================================
FENETRE 2 [09:00 - 09:30] (retour v1)
========================================

Reservation non assignee avant 09:00: r3_reste(15)

ITERATION 2:
  Vehicule dispo: v1(10)
  -> v1 prend 10 de r3_reste
  -> r3 RESTE 5 passagers
  -> v1 depart 09:00, retour 10:00

========================================
09:12 - v3 retourne
========================================

ITERATION 3:
  Reservation non assignee: r3_reste(5)
  Vehicule: v3(12)
  -> v3 prend 5 de r3_reste
  -> r3 COMPLETEMENT assignee
  -> v3 depart 09:12, retour 10:12

TOUS assignes
```

### Resultat Attendu Jour 5

| Vehicule | Reservations | Passagers | Depart | Retour |
|----------|--------------|-----------|--------|--------|
| v3 | r2(12) | 12 | 08:00 | 09:12 |
| v1 | r1(10) | 10 | 08:00 | 09:00 |
| v2 | r3_partie1(10) | 10 | 08:30 | 09:30 |
| v1 | r3_partie2(10) | 10 | 09:00 | 10:00 |
| v3 | r3_partie3(5) | 5 | 09:12 | 10:12 |

**Verification:** 12 + 10 + 10 + 10 + 5 = 47 passagers (tous assignes)

---

## JOUR 6: 01/04/2026 - CAS COMBINE (VEHICULE RETOUR + RESERVATION MEME HEURE)

### Reservations

| ID | Client | Passagers | Heure arrivee |
|----|--------|-----------|---------------|
| 18 | J6_r1_8pass | 8 | 10:30 |

### Logique

```
========================================
10:30 - r1(8 pass) arrive ET v4 devient disponible
========================================

Cas particulier: Reservation ET vehicule disponible au meme moment

REGLE: Verifier d'abord s'il existe des reservations non assignees avant 10:30
-> Aucune

REGLE: Comme les 2 arrivent en meme temps:
  Chercher parmi les vehicules dispo celui le plus proche de r1(8)

Vehicules disponibles a 10:30:
- v1(10): |10-8| = 2
- v2(10): |10-8| = 2
- v3(12): |12-8| = 4
- v4(8): |8-8| = 0 (PARFAIT)

CLOSEST FIT: v4(8) ecart=0
-> v4 prend r1(8) = PLEIN
-> v4 depart 10:30, retour 11:30

PAS DE FENETRE CREEE (vehicule rempli immediatement)
```

### Resultat Attendu Jour 6

| Vehicule | Reservation | Passagers | Depart | Retour |
|----------|-------------|-----------|--------|--------|
| v4 | r1(8) | 8 | 10:30 | 11:30 |

**Points cles:**
- v4 devient disponible a 10:30 (heure_disponible_debut)
- r1 arrive a 10:30 au meme moment
- v4 remplit completement -> pas de fenetre de regroupement

---

## RESUME DES SCENARIOS

| Jour | Date | Scenario | Reservations | Passagers | Vehicules | Note |
|------|------|----------|--------------|-----------|-----------|------|
| 1 | 27/03 | Regroupement CLOSEST FIT | 4 | 19 | v1, v2 | Tri DESC + regroupement |
| 2 | 28/03 | Division CLOSEST FIT | 1 | 20 | v3, v1 | Division sur 2 vehicules |
| 3 | 29/03 | Retours + Fenetres | 7 | 61 | Tous | Multiple fenetres |
| 4 | 30/03 | heure_disponible_debut | 2 | 10 | v1, v4 | Validation v4 |
| 5 | 31/03 | Division en 3 parties | 3 | 47 | v1, v2, v3 | Grande reservation |
| 6 | 01/04 | Vehicule+Reservation meme heure | 1 | 8 | v4 | Cas special |

**TOTAL GLOBAL: 18 reservations, 165 passagers**

---

## CRITERES DE VALIDATION

### Modification 1: Regroupement Optimal (CLOSEST FIT)
- [x] Tri DECROISSANT par nb_passagers
- [x] Traiter d'abord le MAXIMUM
- [x] Selection vehicule: ecart minimum
- [x] Regroupement: ecart minimum (preferer remplissage)
- [x] Valide dans: Jour 1, Jour 3

### Modification 2: Division Optimale (CLOSEST FIT)
- [x] Chaque iteration: vehicule avec ecart minimum
- [x] Continue jusqu'a tous assignes
- [x] Tie-break: trajets < diesel < aleatoire
- [x] Valide dans: Jour 2, Jour 5

### Modification 3: Disponibilite Horaire
- [x] Verifier heure_depart >= heure_disponible_debut
- [x] Exclure vehicule si non disponible
- [x] Inclure vehicule des qu'il devient disponible
- [x] Valide dans: Jour 4, Jour 6

### Regles Fenetres
- [x] Fenetre arrivee reservation: tri DESC
- [x] Fenetre retour vehicule: CLOSEST FIT direct
- [x] Vehicule rempli immediatement: part sans fenetre
- [x] Vehicule non rempli: cree fenetre de regroupement
- [x] Valide dans: Jour 3, Jour 5, Jour 6

---

## REQUETES SQL DE VERIFICATION

### Apres chaque jour, executer:

```sql
-- A. Voir toutes les attributions
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

-- B. Resume par reservation
SELECT
    r.id,
    r.customer_id,
    r.passenger_nbr as demande,
    COALESCE(SUM(a.nb_passagers_assignes), 0) as assigne,
    r.passenger_nbr - COALESCE(SUM(a.nb_passagers_assignes), 0) as reste
FROM reservation r
LEFT JOIN attribution a ON r.id = a.reservation_id
GROUP BY r.id, r.customer_id, r.passenger_nbr
ORDER BY r.arrival_date;

-- C. Verification v4 (disponibilite)
SELECT
    v.reference,
    a.date_heure_depart::time as depart,
    v.heure_disponible_debut,
    CASE
        WHEN a.date_heure_depart::time >= v.heure_disponible_debut THEN 'OK'
        ELSE 'ERREUR!'
    END as verification
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
WHERE v.reference = 'v4';
```
