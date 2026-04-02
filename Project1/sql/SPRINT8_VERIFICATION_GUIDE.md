# SPRINT 8 - GUIDE DE VÉRIFICATION DES RÉSULTATS

## Configuration de Base

| Véhicule | Places | Carburant | Disponibilité |
|----------|--------|-----------|---------------|
| v1 | 10 | Diesel | Toujours |
| v2 | 10 | Essence | Toujours |
| v3 | 12 | Diesel | Toujours |
| v4 | 8 | Diesel | À partir de 10:30 |

**Paramètres:**
- Vitesse moyenne: 50 km/h
- Temps d'attente (fenêtre): 30 min
- CARLTON -> IVATO: 25km = 30min aller, 60min total
- COLBERT -> IVATO: 30km = 36min aller, 72min total

---

## RÈGLES SPRINT 8 À VÉRIFIER

### Règle 1: Tri DÉCROISSANT pour fenêtre ARRIVÉE_RESERVATION
- Les réservations sont triées par `nb_passagers DESC`
- On traite d'abord le **MAXIMUM**

### Règle 2: CLOSEST FIT
- Formule: `|nb_places - nb_passagers|` = minimum
- En cas d'égalité: moins de trajets > Diesel > aléatoire

### Règle 3: Priorité des réservations non assignées AVANT fenêtre
- Réservations arrivées AVANT `fenetreStart` = PRIORITAIRES
- Triées DESC par passagers
- Traitées en PREMIER

### Règle 4: Départ immédiat vs Fenêtre de regroupement
- **DÉPART IMMÉDIAT**: Véhicule rempli UNIQUEMENT par réservations avec `arrival_date <= heure_retour`
  - Inclut les réservations arrivées EXACTEMENT à l'heure de retour du véhicule
  - Le véhicule part à `heure_retour` (ou `heure_disponible_debut` si applicable)
- **FENÊTRE DE REGROUPEMENT**: Véhicule reçoit des réservations avec `arrival_date > heure_retour`
  - Ou véhicule non rempli par les réservations <= heure_retour

### Règle 5: Calcul heure_depart
- Pour DÉPART IMMÉDIAT: `heure_depart = heure_retour` (ou `heure_disponible_debut`)
- Pour DÉPART COMMUN: `heure_depart = MAX(arrival_date de TOUTES les réservations de la fenêtre)`
- Si `heure_retour > MAX(arrival_date)`, alors `heure_depart = heure_retour`

### Règle 6: heure_disponible_debut
- v4 ne peut pas être assigné AVANT 10:30

---

## SCÉNARIO 1: JOUR 1 (27/03/2026) - REGROUPEMENT OPTIMAL

### Données d'entrée
| ID | Client | Passagers | Arrivée |
|----|--------|-----------|---------|
| 1 | J1_r1_9pass | 9 | 08:00 |
| 2 | J1_r2_5pass | 5 | 07:55 |
| 3 | J1_r3_3pass | 3 | 07:50 |
| 4 | J1_r4_2pass | 2 | 07:40 |

### Résultat Attendu
| Véhicule | Réservations | Passagers Assignés | Heure Départ |
|----------|--------------|-------------------|--------------|
| v1 | r1(9) + r4(1) | 10 | 08:00 |
| v2 | r2(5) + r3(3) + r4(1) | 9 | 08:00 |

### Points de vérification
- [ ] r1(9) traité en premier (MAX)
- [ ] v1 choisie pour r1 (écart=1, Diesel)
- [ ] r4 choisie pour regroupement v1 (écart min |1-2|=1)
- [ ] r4 divisée: 1 dans v1, 1 dans v2
- [ ] Total: 19 passagers assignés

---

## SCÉNARIO 2: JOUR 2 (28/03/2026) - DIVISION OPTIMALE

### Données d'entrée
| ID | Client | Passagers | Arrivée |
|----|--------|-----------|---------|
| 5 | J2_r1_20pass | 20 | 09:00 |

### Résultat Attendu
| Véhicule | Réservation | Passagers | Heure Départ |
|----------|-------------|-----------|--------------|
| v3 | r1 (partie 1) | 12 | 09:00 |
| v1 | r1 (partie 2) | 8 | 09:00 |

### Points de vérification
- [ ] v3(12) choisie d'abord (écart |12-20|=8 < |10-20|=10)
- [ ] v1 choisie pour le reste (écart |10-8|=2, Diesel prioritaire)
- [ ] v4 NON utilisée (pas disponible avant 10:30)
- [ ] Total: 20 passagers assignés

---

## SCÉNARIO 3: JOUR 3 (29/03/2026) - RETOUR VÉHICULE + FENÊTRE

### Données d'entrée
| ID | Client | Passagers | Arrivée | Note |
|----|--------|-----------|---------|------|
| 6 | J3_r1_10pass_MATIN | 10 | 07:00 | Fenêtre 1 |
| 7 | J3_r2_10pass_MATIN | 10 | 07:00 | Fenêtre 1 |
| 8 | J3_r3_12pass_MATIN | 12 | 07:00 | Fenêtre 1 |
| 9 | J3_r4_9pass_RESTE | 9 | 07:30 | PRIORITAIRE |
| 10 | J3_r5_5pass_RESTE | 5 | 07:45 | Fenêtre 2 |
| 11 | J3_r6_7pass | 7 | 08:15 | Fenêtre retour |
| 12 | J3_r7_8pass | 8 | 08:20 | Fenêtre retour |

### Résultat Attendu
| Véhicule | Heure Départ | Réservations | Passagers |
|----------|--------------|--------------|-----------|
| v3 | 07:00 | r3(12) | 12 |
| v1 | 07:00 | r1(10) | 10 |
| v2 | 07:00 | r2(10) | 10 |
| v1 | 08:00 | r4(9) + r5(1) | 10 |
| v2 | **08:20** | r5(4) + r6(6) | 10 |
| v3 | **08:20** | r7(8) + r6(1) | 9 |

### Points de vérification
- [ ] Fenêtre 1 [07:00-07:30]: intervalle FERMÉ, r4(9) à 07:30 est dans la fenêtre mais pas de véhicule disponible
- [ ] v1, v2, v3 partent à 07:00 (MAX des assignées = 07:00)
- [ ] r4(9) = PRIORITAIRE au moment du retour (arrivé AVANT 08:00)
- [ ] r5(5) = PRIORITAIRE au moment du retour (arrivé AVANT 08:00)
- [ ] v1: r4(9) + r5(1) = 10 → DÉPART IMMÉDIAT à 08:00 (rempli par prioritaires uniquement)
- [ ] v2, v3: DÉPART COMMUN à **08:20** = MAX(arrival_date de TOUTES les réservations de la fenêtre [08:00-08:30])
- [ ] r5 divisée: 1 dans v1, 4 dans v2
- [ ] r6 divisée: 6 dans v2, 1 dans v3
- [ ] Total: 61 passagers

---

## SCÉNARIO 4: JOUR 4 (30/03/2026) - HEURE_DISPONIBLE_DEBUT

### Données d'entrée
| ID | Client | Passagers | Arrivée |
|----|--------|-----------|---------|
| 13 | J4_r1_4pass | 4 | 10:00 |
| 14 | J4_r2_6pass | 6 | 10:25 |

### Résultat Attendu
| Véhicule | Réservations | Passagers | Heure Départ |
|----------|--------------|-----------|--------------|
| v1 | r2(6) + r1(4) | 10 | 10:25 |

### Points de vérification
- [ ] v4 NON utilisée (disponible seulement à 10:30)
- [ ] v1 choisie (Diesel prioritaire avec écart=4)
- [ ] Heure départ = 10:25 (MAX des assignées)
- [ ] Total: 10 passagers

---

## SCÉNARIO 5: JOUR 5 (31/03/2026) - DIVISION 3 PARTIES

### Données d'entrée
| ID | Client | Passagers | Arrivée |
|----|--------|-----------|---------|
| 15 | J5_r1_25pass | 25 | 10:30 |

### Résultat Attendu
| Véhicule | Réservation | Passagers | Heure Départ |
|----------|-------------|-----------|--------------|
| v3 | r1 (12/25) | 12 | 10:30 |
| v1 | r1 (10/25) | 10 | 10:30 |
| v4 | r1 (3/25) | 3 | 10:30 |

### Points de vérification
- [ ] v3 choisie d'abord (écart |12-25|=13 < autres)
- [ ] v1 ensuite (écart |10-13|=3)
- [ ] v4 pour le reste (écart |8-3|=5 < |10-3|=7)
- [ ] v4 utilisée (disponible à 10:30)
- [ ] Total: 25 passagers

---

## SCÉNARIO 6: JOUR 6 (01/04/2026) - DÉPART IMMÉDIAT

### Contexte
- v1 fait un trajet 07:00 -> retour 08:00
- r1(10) arrive à 07:30 (AVANT retour)
- r2(5) arrive à 08:15 (APRÈS retour)

### Résultat Attendu
| Véhicule | Réservations | Passagers | Heure Départ | Note |
|----------|--------------|-----------|--------------|------|
| v1 | r1(10) | 10 | 08:00 | **DÉPART IMMÉDIAT** |
| v2 | r2(5) | 5 | 08:15 | Fenêtre créée |

### Points de vérification
- [ ] r1 = PRIORITAIRE (arrivé avant 08:00)
- [ ] v1 remplie immédiatement (10=10) → **PAS DE FENÊTRE**
- [ ] v1 départ = 08:00 (heure_retour, car rempli immédiatement)
- [ ] v1 NE PART PAS à 08:15
- [ ] Total: 15 passagers

---

## SCÉNARIO 7: JOUR 7 (02/04/2026) - MÊME HEURE ARRIVÉE

### Données d'entrée
| ID | Client | Passagers | Arrivée |
|----|--------|-----------|---------|
| 18 | J7_r1_8pass | 8 | 10:30 |
| 19 | J7_r2_3pass | 3 | 10:00 |

### Résultat Attendu
| Véhicule | Réservations | Passagers | Heure Départ |
|----------|--------------|-----------|--------------|
| v1 | r2(3) + r1(7) | 10 | 10:30 |
| v4 | r1(1) | 1 | 10:30 |

### Points de vérification
- [ ] r2 traité dans fenêtre [10:00-10:30]
- [ ] v4 disponible à 10:30 (utilisée pour reste de r1)
- [ ] r1 divisée: 7 dans v1, 1 dans v4
- [ ] Total: 11 passagers

---

## TABLEAU RÉCAPITULATIF

| Jour | Date | Scénario | Passagers Total | Véhicules Utilisés |
|------|------|----------|-----------------|-------------------|
| 1 | 27/03 | Regroupement Optimal | 19 | v1, v2 |
| 2 | 28/03 | Division Optimale | 20 | v3, v1 |
| 3 | 29/03 | Retour + Fenêtre | 61 | v1, v2, v3 (x2) |
| 4 | 30/03 | heure_disponible | 10 | v1 |
| 5 | 31/03 | Division 3 parties | 25 | v3, v1, v4 |
| 6 | 01/04 | Départ Immédiat | 15 | v1, v2 |
| 7 | 02/04 | Même Heure | 11 | v1, v4 |
| **TOTAL** | | | **161** | |

---

## REQUÊTES SQL DE VÉRIFICATION

```sql
-- Vérifier les attributions générées
SELECT
    a.id,
    v.reference as vehicule,
    v.nb_place as places_vehicule,
    a.nb_passagers_assignes,
    a.date_heure_depart,
    a.date_heure_retour,
    GROUP_CONCAT(r.client_name) as reservations
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
LEFT JOIN attribution_reservation ar ON a.id = ar.attribution_id
LEFT JOIN reservation r ON ar.reservation_id = r.id
WHERE DATE(a.date_heure_depart) = '2026-03-27'
GROUP BY a.id
ORDER BY a.date_heure_depart;

-- Vérifier que tous les passagers sont assignés
SELECT
    DATE(r.arrival_date) as jour,
    SUM(r.passenger_nbr) as passagers_total,
    (SELECT COALESCE(SUM(nb_passagers_assignes), 0)
     FROM attribution
     WHERE DATE(date_heure_depart) = DATE(r.arrival_date)) as passagers_assignes
FROM reservation r
GROUP BY DATE(r.arrival_date)
ORDER BY jour;
```

---

## COMMENT UTILISER CE GUIDE

1. **Exécuter le SQL de simulation**: `SPRINT8_SIMULATION_COMPLETE.sql`
2. **Lancer le planning pour chaque jour**
3. **Comparer les résultats** avec les tableaux ci-dessus
4. **Cocher les points de vérification** pour chaque scénario
5. **Identifier les écarts** et corriger le code si nécessaire
