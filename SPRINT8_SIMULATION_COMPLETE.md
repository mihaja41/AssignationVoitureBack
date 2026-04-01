# SPRINT 8 - SIMULATION COMPLETE DES SCENARIOS

## SIMULATION PRINCIPALE (Exemple de la Specification)

**Date de simulation: 27/03/2026**

---

### ETAT INITIAL

#### Vehicules avec attributions pre-existantes (en course)
| Vehicule | Places | Carburant | Etat Initial | Heure Retour Prevue |
|----------|--------|-----------|--------------|---------------------|
| v1 | 10 | Diesel (D) | En course | 09:45 |
| v2 | 10 | Essence (Es) | En course | 09:45 |
| v3 | 12 | Diesel (D) | En course | 10:12 |

#### Restes de Reservations NON ASSIGNEES (avant 09:45)
| ID | Client | Passagers | Arrivee | Statut |
|----|--------|-----------|---------|--------|
| r1 | CLI001 | 9 | 08:00 | Non assigne (reste) |
| r2 | CLI002 | 5 | 07:30 | Non assigne (reste) |

#### Nouvelles Reservations (arrivent apres)
| ID | Client | Passagers | Arrivee | Statut |
|----|--------|-----------|---------|--------|
| r3 | CLI003 | 1 | 10:00 | Nouvelle |
| r4 | CLI004 | 7 | 10:10 | Nouvelle |
| r5 | CLI005 | 5 | 10:11 | Nouvelle |

---

### DEROULEMENT ETAPE PAR ETAPE

#### ETAPE 1: Retour de v1 et v2 a 09:45
**Evenement:** v1 (D, 10pl) et v2 (Es, 10pl) reviennent a l'aeroport

**Reservations non assignees disponibles:**
- r1: 9 passagers (arrivee 08:00)
- r2: 5 passagers (arrivee 07:30)

**Tri par passagers decroissant:** r1 (9) > r2 (5)

---

#### ETAPE 2: Attribution de r1 (9 passagers)
**Vehicules disponibles:**
| Vehicule | Places | Ecart avec 9 pass | Trajets | Carburant |
|----------|--------|-------------------|---------|-----------|
| v1 | 10 | \|10-9\| = 1 | ? | D |
| v2 | 10 | \|10-9\| = 1 | ? | Es |

**Criteres de selection (ecart egal):**
1. Ecart: 1 = 1 (egalite)
2. Nb trajets: (a verifier)
3. Diesel prioritaire: v1 gagne

**RESULTAT:**
- **v1 recoit r1** (9 passagers)
- v1 a maintenant: 10 - 9 = **1 place restante**

---

#### ETAPE 3: Remplissage de v1 avec r2
**Places restantes dans v1:** 1
**r2 a:** 5 passagers

**Ecart:** |1 - 5| = 4

**Action:** Assigner 1 passager de r2 a v1
- v1 est maintenant PLEIN (10/10)
- **v1 PART a 09:45**

**Reste de r2:** 5 - 1 = **4 passagers non assignes**

---

#### ETAPE 4: Attribution du reste de r2 (4 passagers) a v2
**Vehicules disponibles:** v2 (10 places)

**Action:** Assigner les 4 passagers restants de r2 a v2
- v2 a maintenant: 10 - 4 = **6 places restantes**
- v2 n'est PAS plein

**Fenetre d'attente creee pour v2:**
- Debut: 09:45
- Fin: 09:45 + 30 min = **10:15**

---

#### ETAPE 5: Fenetre d'attente [09:45 - 10:15]
**Vehicule en attente:** v2 (6 places restantes)
**Type de fenetre:** Issue d'un vehicule retourne NON PLEIN

**Reservations arrivant dans cette fenetre:**
| ID | Passagers | Arrivee | Ecart avec 6 places |
|----|-----------|---------|---------------------|
| r3 | 1 | 10:00 | \|6-1\| = 5 |
| r4 | 7 | 10:10 | \|6-7\| = 1 ← MINIMUM |
| r5 | 5 | 10:11 | \|6-5\| = 1 ← MINIMUM |

**Selection par CLOSEST FIT (ecart minimum):**
- r4 et r5 ont le meme ecart (1)
- r4 arrive en premier (10:10 < 10:11)
- **r4 est selectionnee**

> **IMPORTANT:** Pour une fenetre issue d'un vehicule retourne non plein,
> on cherche la reservation avec l'ecart MINIMUM (closest fit),
> PAS un tri decroissant par passagers.

---

#### ETAPE 6: Attribution de r4 (7 passagers) a v2 - Closest Fit
**Places restantes dans v2:** 6
**r4 a:** 7 passagers
**Ecart:** |6 - 7| = 1 (le plus proche)

**Action:** Assigner 6 passagers de r4 a v2
- v2 est maintenant PLEIN (10/10)
- **v2 PART a 10:10** (heure d'arrivee de r4)

**Reste de r4:** 7 - 6 = **1 passager non assigne**

---

#### ETAPE 7: v3 revient a 10:12
**Evenement:** v3 (D, 12 places) revient a l'aeroport

**Reservations non assignees a 10:12:**
- Reste de r4: 1 passager
- r3: 1 passager (arrivee 10:00)
- r5: 5 passagers (arrivee 10:11)

---

#### ETAPE 8: Attribution a v3 - Fenetre issue d'arrivee non assignee

> **Note:** Ici v3 revient et va traiter les reservations non assignees.
> Comme c'est une nouvelle fenetre issue d'une arrivee de reservation non assignee
> (restes de r4, r3, r5), on traite d'abord les RESTES puis les nouvelles.
> Les restes sont tries par passagers DECROISSANT (r5 > r4_reste = r3).

**8a. Attribution de r5 (5 passagers) - Plus grand reste**
- v3 recoit r5: 5 passagers
- v3 a maintenant: 12 - 5 = **7 places restantes**

**8b. Closest fit pour remplir v3 (7 places restantes)**
| Reservation | Passagers | Ecart avec 7 places |
|-------------|-----------|---------------------|
| r4 reste | 1 | \|7-1\| = 6 |
| r3 | 1 | \|7-1\| = 6 |

- Ecarts egaux, on prend par ordre d'arrivee
- r3 est arrivee a 10:00, r4 reste est cree a 10:10
- **r3 est selectionnee** puis r4 reste

**8c. v3 recoit r3 (1 passager)**
- v3 a maintenant: 7 - 1 = **6 places restantes**

**8d. v3 recoit reste de r4 (1 passager)**
- v3 a maintenant: 6 - 1 = **5 places restantes**

---

#### ETAPE 9: Fenetre d'attente pour v3 [10:12 - 10:42]
**v3 n'est pas plein** (7/12 passagers)

**Aucune nouvelle reservation dans cette fenetre**

**Action:** v3 part a 10:11 (heure d'arrivee de la derniere reservation assignee = r5)

---

### RESULTAT FINAL DE LA SIMULATION

| Attribution | Vehicule | Reservations | Passagers | Heure Depart |
|-------------|----------|--------------|-----------|--------------|
| ATT1 | v1 (10pl, D) | r1 + r2 (partiel) | 9 + 1 = 10 | 09:45 |
| ATT2 | v2 (10pl, Es) | r2 (partiel) + r4 (partiel) | 4 + 6 = 10 | 10:10 |
| ATT3 | v3 (12pl, D) | r5 + r4 (reste) + r3 | 5 + 1 + 1 = 7 | 10:11 |

**Verification des totaux:**
| Reservation | Passagers Demandes | Passagers Assignes | Complet? |
|-------------|-------------------|-------------------|----------|
| r1 | 9 | 9 | OUI |
| r2 | 5 | 1 + 4 = 5 | OUI |
| r3 | 1 | 1 | OUI |
| r4 | 7 | 6 + 1 = 7 | OUI |
| r5 | 5 | 5 | OUI |
| **TOTAL** | **27** | **27** | **OUI** |

---

## SCENARIOS ADDITIONNELS

### SCENARIO A: Vehicule avec heure_disponible_debut

**Contexte:** Ajouter un vehicule v4 (8 places) disponible seulement a partir de 10:30

| Vehicule | Places | Carburant | heure_disponible_debut |
|----------|--------|-----------|------------------------|
| v4 | 8 | Hybride | 10:30 |

**Test:**
- Si une reservation arrive a 10:00, v4 ne doit PAS etre selectionne
- Si une reservation arrive a 10:35, v4 peut etre selectionne

---

### SCENARIO B: Plusieurs vehicules reviennent simultanement

**Contexte:** v1 et v2 reviennent exactement a la meme heure (09:45)

**Regle:** Traiter par ordre de priorite:
1. Plus petit ecart avec passagers
2. Moins de trajets effectues
3. Diesel prioritaire
4. Aleatoire

---

### SCENARIO C: Aucun vehicule disponible

**Contexte:** Tous les vehicules sont en course, une reservation arrive

**Resultat attendu:**
- La reservation devient "non assignee"
- Elle sera traitee en priorite a la prochaine fenetre

---

### SCENARIO D: Reservation plus grande que tous les vehicules

**Contexte:** r6 (50 passagers), vehicules max 12 places

**Resultat attendu:**
- Division sur plusieurs vehicules
- Chaque vehicule remplit au maximum
- Les restes deviennent des reservations partielles

---

### SCENARIO E: Fenetre d'attente sans nouvelle arrivee

**Contexte:** v1 revient, prend une reservation, n'est pas plein, fenetre s'ouvre mais aucune reservation n'arrive

**Resultat attendu:**
- v1 part a la fin de la fenetre avec les passagers deja assignes
- Heure de depart = heure d'arrivee de la derniere reservation assignee

---

## TABLEAU RECAPITULATIF DES CAS TESTES

| # | Cas | Description | Validation |
|---|-----|-------------|------------|
| 1 | Retour vehicule | v1/v2 reviennent a 09:45 | Fenetre creee |
| 2 | Restes prioritaires | r1, r2 traites avant r3, r4, r5 | Ordre correct |
| 3 | Tri decroissant | 9 > 5 > 7 > 5 > 1 | Traitement dans l'ordre |
| 4 | Ecart minimum | v1 choisit r1 (ecart=1) | Selection optimale |
| 5 | Diesel prioritaire | v1 (D) > v2 (Es) si egalite | Diesel gagne |
| 6 | Division reservation | r2 divise: 1 + 4 | Passagers correctement repartis |
| 7 | Fenetre d'attente | [09:45 - 10:15] pour v2 | Duree = 30 min |
| 8 | Remplissage fenetre | r4 remplit v2 | Vehicule plein, part |
| 9 | Reste apres division | r4 reste 1 passager | Report correct |
| 10 | Depart vehicule non plein | v3 part a 10:11 avec 7/12 | Heure derniere reservation |
| 11 | heure_disponible_debut | v4 indisponible avant 10:30 | Filtrage respecte |
| 12 | Aucun vehicule | Reservation mise en attente | Non assignee correctement |

---

## REQUETES SQL DE VERIFICATION

### Verification des attributions finales
```sql
SELECT
    a.id,
    v.reference,
    v.nb_place,
    r.customer_id,
    r.passenger_nbr as demande,
    a.nb_passagers_assignes as assigne,
    a.date_heure_depart,
    a.date_heure_retour
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
WHERE DATE(a.date_heure_depart) = '2026-03-27'
ORDER BY a.date_heure_depart;
```

### Verification des divisions
```sql
SELECT
    r.customer_id,
    r.passenger_nbr as total_demande,
    COUNT(a.id) as nb_vehicules,
    SUM(a.nb_passagers_assignes) as total_assigne,
    STRING_AGG(v.reference || ':' || a.nb_passagers_assignes::text, ', ') as detail
FROM reservation r
LEFT JOIN attribution a ON r.id = a.reservation_id
LEFT JOIN vehicule v ON a.vehicule_id = v.id
WHERE DATE(r.arrival_date) = '2026-03-27'
GROUP BY r.id, r.customer_id, r.passenger_nbr
ORDER BY r.arrival_date;
```

### Verification heure_disponible_debut
```sql
SELECT
    v.reference,
    v.heure_disponible_debut,
    a.date_heure_depart::time as heure_depart_effective,
    CASE
        WHEN v.heure_disponible_debut IS NULL THEN 'OK - Toujours dispo'
        WHEN a.date_heure_depart::time >= v.heure_disponible_debut THEN 'OK - Respecte'
        ELSE 'ERREUR - Avant heure dispo'
    END as validation
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
WHERE DATE(a.date_heure_depart) = '2026-03-27';
```
