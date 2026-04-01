# SPRINT 8 - SCENARIOS DE TEST COMPLETS

## Resume des Fonctionnalites Sprint 8

| # | Modification | Description | Critere de Validation |
|---|--------------|-------------|----------------------|
| 1 | Regroupement Optimal | Trouver reservation avec `Math.abs(passagers - places_restantes)` minimal | Ecart minimum choisi |
| 2 | Division Optimale | Selectionner vehicule avec nb_places le plus proche des passagers restants | Vehicule optimal choisi |
| 3 | Disponibilite Horaire | Vehicule disponible seulement apres `heure_disponible_debut` | heure_depart >= heure_dispo |
| 4 | Fenetre Retour Vehicule | Ouverture d'une fenetre quand un vehicule retourne | Fenetre creee au retour |
| 5 | Gestion Restes/Partielles | Passagers non assignes deviennent ReservationPartielle | Restes reportes correctement |

---

## DONNEES DE BASE

### Lieux (3 lieux)
| ID | Code | Libelle | Initial |
|----|------|---------|---------|
| 1 | IVATO | Aeroport Ivato | A |
| 2 | CARLTON | Hotel Carlton | B |
| 3 | COLBERT | Hotel Colbert | C |

### Distances (km)
| De | Vers | Distance |
|----|------|----------|
| IVATO (1) | CARLTON (2) | 25 km |
| IVATO (1) | COLBERT (3) | 30 km |
| CARLTON (2) | COLBERT (3) | 10 km |
| COLBERT (3) | CARLTON (2) | 10 km |
| CARLTON (2) | IVATO (1) | 25 km |
| COLBERT (3) | IVATO (1) | 30 km |

### Vehicules (6 vehicules)
| ID | Reference | Places | Carburant | Heure Dispo Debut |
|----|-----------|--------|-----------|-------------------|
| 1 | VEH-12A | 12 | D | NULL (toujours) |
| 2 | VEH-10B | 10 | Es | 08:00 |
| 3 | VEH-08C | 8 | D | 09:00 |
| 4 | VEH-05D | 5 | H | NULL (toujours) |
| 5 | VEH-05E | 5 | El | 10:00 |
| 6 | VEH-03F | 3 | Es | NULL (toujours) |

### Parametres
| Cle | Valeur |
|-----|--------|
| vitesse_moyenne | 50 km/h |
| temps_attente | 30 minutes |

---

## SCENARIO 1: REGROUPEMENT OPTIMAL (Closest Fit)
**Date: 2026-04-01**
**Objectif: Verifier que le systeme choisit la reservation avec l'ecart minimum**

### Donnees de Test
| ID | Client | Passagers | Arrivee | Hotel |
|----|--------|-----------|---------|-------|
| 1 | CLI001 | 9 | 08:00 | CARLTON |
| 2 | CLI002 | 5 | 08:10 | CARLTON |
| 3 | CLI003 | 3 | 08:15 | CARLTON |
| 4 | CLI004 | 2 | 08:20 | CARLTON |

### Logique Attendue
1. R1 (9 passagers) prend VEH-12A (12 places) -> 3 places restantes
2. Pour combler 3 places, chercher parmi R2(5), R3(3), R4(2):
   - R2: |5-3| = 2
   - R3: |3-3| = 0  <-- MINIMUM
   - R4: |2-3| = 1
3. **R3 est choisie** car ecart = 0

### Resultat Attendu
| Attribution | Vehicule | Reservations | Passagers Assignes |
|-------------|----------|--------------|-------------------|
| ATT1 | VEH-12A (12 pl) | R1 + R3 | 9 + 3 = 12 |
| ATT2 | VEH-10B (10 pl) | R2 | 5 |
| ATT3 | VEH-05D (5 pl) | R4 | 2 |

### Verification SQL
```sql
-- Verifier que R1 et R3 sont groupees ensemble
SELECT a.id, v.reference, r.customer_id, a.nb_passagers_assignes
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
WHERE DATE(a.date_heure_depart) = '2026-04-01'
ORDER BY a.id;
```

---

## SCENARIO 2: DIVISION OPTIMALE (Selection Vehicule Optimal)
**Date: 2026-04-02**
**Objectif: Verifier que lors d'une division, le vehicule avec places les plus proches est choisi**

### Donnees de Test
| ID | Client | Passagers | Arrivee | Hotel |
|----|--------|-----------|---------|-------|
| 5 | CLI005 | 20 | 09:30 | COLBERT |

### Vehicules Disponibles a 09:30
| ID | Reference | Places | Disponible |
|----|-----------|--------|------------|
| 1 | VEH-12A | 12 | Oui (NULL) |
| 2 | VEH-10B | 10 | Oui (08:00 < 09:30) |
| 3 | VEH-08C | 8 | Oui (09:00 < 09:30) |
| 4 | VEH-05D | 5 | Oui (NULL) |
| 5 | VEH-05E | 5 | Non (10:00 > 09:30) |
| 6 | VEH-03F | 3 | Oui (NULL) |

### Logique Attendue (Division)
1. 20 passagers a assigner
2. **Iteration 1**: Chercher vehicule avec places le plus proche de 20
   - VEH-12A: |12-20| = 8 <-- MINIMUM
   - VEH-10B: |10-20| = 10
   - etc.
   - **VEH-12A choisi** -> 12 passagers assignes, reste 8
3. **Iteration 2**: Chercher vehicule avec places le plus proche de 8
   - VEH-10B: |10-8| = 2
   - VEH-08C: |8-8| = 0 <-- MINIMUM
   - VEH-05D: |5-8| = 3
   - **VEH-08C choisi** -> 8 passagers assignes, reste 0
4. **Termine**: Tous les 20 passagers assignes

### Resultat Attendu
| Attribution | Vehicule | Reservation | Passagers Assignes |
|-------------|----------|-------------|-------------------|
| ATT1 | VEH-12A (12 pl) | R5 | 12 |
| ATT2 | VEH-08C (8 pl) | R5 | 8 |

### Verification SQL
```sql
-- Verifier la division sur 2 vehicules
SELECT a.id, v.reference, v.nb_place, a.nb_passagers_assignes,
       r.customer_id, r.passenger_nbr as total_passagers
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
WHERE r.id = 5
ORDER BY a.date_heure_depart;
```

---

## SCENARIO 3: DISPONIBILITE HORAIRE (heure_disponible_debut)
**Date: 2026-04-03**
**Objectif: Verifier que les vehicules ne sont utilises qu'apres leur heure de disponibilite**

### Donnees de Test
| ID | Client | Passagers | Arrivee | Hotel |
|----|--------|-----------|---------|-------|
| 6 | CLI006 | 4 | 07:00 | CARLTON |
| 7 | CLI007 | 4 | 09:30 | CARLTON |

### Vehicules et Disponibilite
| Vehicule | Places | Heure Dispo | Dispo a 07:00? | Dispo a 09:30? |
|----------|--------|-------------|----------------|----------------|
| VEH-12A | 12 | NULL | OUI | OUI |
| VEH-10B | 10 | 08:00 | NON | OUI |
| VEH-08C | 8 | 09:00 | NON | OUI |
| VEH-05D | 5 | NULL | OUI | OUI |
| VEH-05E | 5 | 10:00 | NON | NON |
| VEH-03F | 3 | NULL | OUI | OUI |

### Logique Attendue
1. **R6 (07:00, 4 passagers)**:
   - Vehicules disponibles: VEH-12A, VEH-05D, VEH-03F
   - Optimal pour 4 places: VEH-05D (5 pl, ecart=1) > VEH-03F (3 pl) > VEH-12A (12 pl)
   - **VEH-05D choisi**

2. **R7 (09:30, 4 passagers)**:
   - Vehicules disponibles: VEH-12A, VEH-10B, VEH-08C, VEH-03F
   - Optimal pour 4 places: VEH-08C (8 pl) ou VEH-10B (10 pl) ou VEH-03F (3 pl)
   - **VEH-08C ou similaire choisi** (selon disponibilite apres trajet precedent)

### Resultat Attendu
| Attribution | Vehicule | Reservation | heure_depart | Validation |
|-------------|----------|-------------|--------------|------------|
| ATT1 | VEH-05D | R6 | 07:00 | OK (NULL = toujours dispo) |
| ATT2 | VEH-08C ou autre | R7 | >= 09:30 | OK (09:00 <= 09:30) |

### Verification SQL
```sql
-- Verifier que l'heure de depart >= heure_disponible_debut du vehicule
SELECT a.id, v.reference, v.heure_disponible_debut,
       a.date_heure_depart,
       CASE WHEN v.heure_disponible_debut IS NULL
            OR a.date_heure_depart::time >= v.heure_disponible_debut
            THEN 'VALIDE' ELSE 'ERREUR' END as validation
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
WHERE DATE(a.date_heure_depart) = '2026-04-03';
```

---

## SCENARIO 4: FENETRE DE RETOUR VEHICULE
**Date: 2026-04-04**
**Objectif: Verifier que le retour d'un vehicule declenche une fenetre d'attente**

### Contexte Initial
- Attribution existante: VEH-12A part a 08:00, retour prevu a 10:00
- Nouvelles reservations arrivent a 09:30 et 10:10

### Donnees de Test
| ID | Client | Passagers | Arrivee | Hotel |
|----|--------|-----------|---------|-------|
| 8 | CLI008 | 6 | 08:00 | CARLTON |
| 9 | CLI009 | 7 | 09:30 | COLBERT |
| 10 | CLI010 | 5 | 10:10 | CARLTON |

### Logique Attendue
1. **08:00**: R8 assignee a VEH-12A, depart 08:00
   - Trajet: CARLTON (25km) -> retour IVATO
   - Duree: 50km / 50km/h = 1h -> retour a 09:00

2. **Fenetre [09:00 - 09:30]**: VEH-12A revient a 09:00
   - R9 arrive a 09:30, dans la fenetre d'attente (30 min)
   - VEH-12A attend R9

3. **09:30**: VEH-12A repart avec R9
   - Trajet: COLBERT (30km) -> retour IVATO
   - Duree: 60km / 50km/h = 1.2h -> retour a ~10:42

4. **Fenetre [10:42 - 11:12]**: VEH-12A revient
   - R10 est arrivee a 10:10 (avant retour)
   - R10 est assignee quand vehicule disponible

### Resultat Attendu
| Attribution | Vehicule | Reservation | Depart | Retour |
|-------------|----------|-------------|--------|--------|
| ATT1 | VEH-12A | R8 | 08:00 | ~09:00 |
| ATT2 | VEH-12A | R9 | 09:30 | ~10:42 |
| ATT3 | VEH-12A ou autre | R10 | ~10:42 | ~11:42 |

### Verification SQL
```sql
-- Verifier l'enchaînement des attributions du meme vehicule
SELECT a.id, v.reference, r.customer_id, r.arrival_date,
       a.date_heure_depart, a.date_heure_retour,
       LEAD(a.date_heure_depart) OVER (PARTITION BY v.id ORDER BY a.date_heure_depart) as prochain_depart
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
WHERE DATE(a.date_heure_depart) = '2026-04-04'
ORDER BY a.date_heure_depart;
```

---

## SCENARIO 5: GESTION DES RESTES (ReservationPartielle)
**Date: 2026-04-05**
**Objectif: Verifier que les passagers non assignes sont correctement reportes**

### Donnees de Test
| ID | Client | Passagers | Arrivee | Hotel |
|----|--------|-----------|---------|-------|
| 11 | CLI011 | 25 | 08:30 | CARLTON |

### Vehicules Disponibles a 08:30
- VEH-12A (12 pl), VEH-10B (10 pl), VEH-05D (5 pl), VEH-03F (3 pl)
- Total places disponibles: 30 places

**Mais supposons que VEH-10B et VEH-05D sont deja en course**
- Disponibles: VEH-12A (12 pl), VEH-03F (3 pl) = 15 places

### Logique Attendue
1. 25 passagers, seulement 15 places disponibles
2. **Division**:
   - VEH-12A: 12 passagers assignes
   - VEH-03F: 3 passagers assignes
   - **Reste: 25 - 15 = 10 passagers non assignes**
3. **ReservationPartielle creee**: R11 avec 10 passagers restants
4. Ces 10 passagers seront traites dans la prochaine fenetre disponible

### Resultat Attendu
| Attribution | Vehicule | Reservation | Passagers Assignes |
|-------------|----------|-------------|-------------------|
| ATT1 | VEH-12A | R11 | 12 |
| ATT2 | VEH-03F | R11 | 3 |
| **Reste** | - | R11 | 10 (non assignes) |

### Verification SQL
```sql
-- Verifier le total assigne vs total demande
SELECT r.id, r.customer_id, r.passenger_nbr as demande,
       COALESCE(SUM(a.nb_passagers_assignes), 0) as assigne,
       r.passenger_nbr - COALESCE(SUM(a.nb_passagers_assignes), 0) as reste
FROM reservation r
LEFT JOIN attribution a ON r.id = a.reservation_id
WHERE r.id = 11
GROUP BY r.id, r.customer_id, r.passenger_nbr;
```

---

## SCENARIO 6: CAS COMBINE COMPLEXE
**Date: 2026-04-06**
**Objectif: Tester tous les aspects en un seul jour**

### Donnees de Test
| ID | Client | Passagers | Arrivee | Hotel |
|----|--------|-----------|---------|-------|
| 12 | CLI012 | 10 | 07:00 | CARLTON |
| 13 | CLI013 | 8 | 07:15 | CARLTON |
| 14 | CLI014 | 3 | 07:20 | COLBERT |
| 15 | CLI015 | 15 | 09:00 | CARLTON |
| 16 | CLI016 | 6 | 10:30 | COLBERT |
| 17 | CLI017 | 4 | 11:00 | CARLTON |

### Execution Attendue

#### Phase 1: Fenetre Initiale [07:00 - 07:30]
1. **R12 (10 pass, 07:00)**: VEH-12A (12 pl) -> 2 places restantes
   - Regroupement: R14(3) ecart=1, R13(8) ecart=6
   - **Proche mais R14 depasse de 1** -> Si division autorisee: R14 avec 2 pass assignes, 1 reste
   - OU R12 seul dans VEH-12A

2. **R13 (8 pass, 07:15)**: VEH-10B (10 pl, dispo 08:00) NON DISPO
   - VEH-08C (8 pl, dispo 09:00) NON DISPO
   - VEH-05D (5 pl) + VEH-03F (3 pl) = 8 -> Division!
   - **VEH-05D: 5 pass, VEH-03F: 3 pass**

3. **R14 (3 pass, 07:20)**: Vehicules restants apres R12/R13
   - Depend de ce qui reste disponible

#### Phase 2: Fenetre [09:00 - 09:30] (Retour vehicules)
- VEH-12A revient ~08:00 (trajet 1h)
- VEH-05D revient ~08:15
- VEH-03F revient ~08:20
- **R15 (15 pass, 09:00)**: Division entre vehicules revenus

#### Phase 3: Fenetre [10:30 - 11:00]
- **R16 et R17** assignes selon vehicules disponibles

### Points de Validation
1. Regroupement optimal: ecarts minimaux respectes
2. Division optimale: vehicules les plus proches choisis
3. Disponibilite horaire: VEH-10B/VEH-08C/VEH-05E non utilises avant leur heure
4. Fenetres de retour: vehicules reutilises apres retour
5. Restes: tout passager non assigne est trace

---

## TABLEAU RECAPITULATIF DES VALIDATIONS

| Scenario | Date | Fonctionnalite Testee | Critere de Succes |
|----------|------|----------------------|-------------------|
| 1 | 04-01 | Regroupement Optimal | R3 choisie (ecart=0) |
| 2 | 04-02 | Division Optimale | VEH-12A puis VEH-08C |
| 3 | 04-03 | Disponibilite Horaire | heure_depart >= heure_dispo |
| 4 | 04-04 | Fenetre Retour | Enchainement correct |
| 5 | 04-05 | Gestion Restes | 10 passagers en reste |
| 6 | 04-06 | Cas Combine | Tous criteres |

---

## REQUETES DE VERIFICATION GLOBALES

### 1. Vue d'ensemble des attributions
```sql
SELECT
    DATE(a.date_heure_depart) as date_trajet,
    v.reference as vehicule,
    v.nb_place as places_vehicule,
    r.customer_id as client,
    r.passenger_nbr as passagers_demandes,
    a.nb_passagers_assignes as passagers_assignes,
    a.date_heure_depart,
    a.date_heure_retour
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
ORDER BY a.date_heure_depart;
```

### 2. Reservations avec restes non assignes
```sql
SELECT
    r.id,
    r.customer_id,
    r.passenger_nbr as total_demande,
    COALESCE(SUM(a.nb_passagers_assignes), 0) as total_assigne,
    r.passenger_nbr - COALESCE(SUM(a.nb_passagers_assignes), 0) as reste
FROM reservation r
LEFT JOIN attribution a ON r.id = a.reservation_id
GROUP BY r.id, r.customer_id, r.passenger_nbr
HAVING r.passenger_nbr > COALESCE(SUM(a.nb_passagers_assignes), 0);
```

### 3. Validation disponibilite horaire
```sql
SELECT
    a.id,
    v.reference,
    v.heure_disponible_debut,
    a.date_heure_depart::time as heure_depart,
    CASE
        WHEN v.heure_disponible_debut IS NULL THEN 'OK - Toujours dispo'
        WHEN a.date_heure_depart::time >= v.heure_disponible_debut THEN 'OK - Apres heure dispo'
        ELSE 'ERREUR - Avant heure dispo'
    END as validation
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id;
```

### 4. Utilisation des vehicules par jour
```sql
SELECT
    DATE(a.date_heure_depart) as date_jour,
    v.reference,
    COUNT(*) as nb_trajets,
    SUM(a.nb_passagers_assignes) as total_passagers
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
GROUP BY DATE(a.date_heure_depart), v.reference
ORDER BY date_jour, v.reference;
```
