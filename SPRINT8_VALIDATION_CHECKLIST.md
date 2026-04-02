# SPRINT 8 - GUIDE DE VALIDATION ET CHECKLIST

**Version**: 1.0
**Date**: 2026-04-03
**Statut**: Prêt pour test complet

---

## INSTALLATION ET PRÉPARATION

### Étape 1: Initialiser la Base de Données

```bash
# Accéder au répertoire du projet
cd /home/anita/Documents/itu_lesson/S5/FRAME_WORK/Project/AssignationVoitureBack

# Exécuter le script SQL d'initialisation
psql -U postgres -f Project1/sql/SPRINT8_TEST_SIMULATION.sql

# Vérifier l'insertion des données
psql -U postgres -d hotel_reservation -c "SELECT COUNT(*) FROM reservation;"
# Résultat attendu: 25 réservations
```

### Étape 2: Compiler et Déployer le Projet

```bash
# Compiler
mvn clean compile

# Tester la compilation
mvn test

# Construire le WAR
mvn package
```

### Étape 3: Démarrer l'Application

```bash
# Démarrer Tomcat avec l'application
# L'application sera disponible à http://localhost:8080

# Ou via IDE si utilisé
```

---

## PROTOCOLE DE TEST PAR SCÉNARIO

### 🧪 SCÉNARIO 1: Regroupement Optimal (27/03)

**Objectif**: Valider le tri DÉCROISSANT et CLOSEST FIT du regroupement

**URL API**: `GET /planning/auto?date=2026-03-27`

**Données d'entrée**:
- 4 réservations: r1(9), r2(5), r3(3), r4(2)
- Total: 19 passagers
- Fenêtre: [07:40 - 08:10]

**Résultats Attendus**:

| Vérification | Attendu | Validation |
|--------------|---------|-----------|
| v1 assignée | r1(9) + r4(1) = 10 PLEIN | ✅ |
| v2 assignée | r4(0) + r2(5) + r3(3) = 8 | ✅ |
| v3 utilisée | Non | ✅ |
| Départ v1 | 08:00 | ✅ |
| Départ v2 | 08:00 | ✅ |
| Retour v1 | 09:00 | ✅ |
| Retour v2 | 09:00 | ✅ |
| Total passagers | 19/19 | ✅ |

**Procédure Vérification**:

```sql
-- Exécuter après l'appel API
SELECT
    v.reference as vehicule,
    STRING_AGG(r.customer_id, ', ') as reservations,
    SUM(a.nb_passagers_assignes) as total_passagers,
    a.date_heure_depart::time as depart,
    a.date_heure_retour::time as retour
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
WHERE r.arrival_date::date = '2026-03-27'
GROUP BY v.id, v.reference, a.date_heure_depart, a.date_heure_retour
ORDER BY v.id;

-- Résultat attendu:
-- v1 | J1_r1_9pass, J1_r4_2pass | 10 | 08:00 | 09:00
-- v2 | J1_r2_5pass, J1_r3_3pass | 8  | 08:00 | 09:00
```

**Checklist**:
- [ ] r1 assignée complètement (9/9)
- [ ] r2 assignée complètement (5/5)
- [ ] r3 assignée complètement (3/3)
- [ ] r4 assignée complètement (2/2) divisée
- [ ] Attribue à 2 véhicules seulement
- [ ] Total 19 passagers
- [ ] Écarts minimaux (v1=1, v2=2)
- [ ] Heures départ/retour correctes

---

### 🧪 SCÉNARIO 2: Division Optimale (28/03)

**Objectif**: Valider la division avec CLOSEST FIT

**URL API**: `GET /planning/auto?date=2026-03-28`

**Données d'entrée**:
- 1 réservation: r1(20)
- Total: 20 passagers
- Seul départ: 09:00

**Résultats Attendus**:

| Vérification | Attendu | Validation |
|--------------|---------|-----------|
| v3 assignée | 12 passagers (1ère partie) | ✅ |
| v1 assignée | 8 passagers (2ème partie) | ✅ |
| v2 utilisée | Non | ✅ |
| v4 utilisée | Non (pas dispo avant 10:30) | ✅ |
| Total passagers | 20/20 divisée en 2 | ✅ |
| Écart v3 | \|12-20\| = 8 MIN | ✅ |
| Écart v1 | \|10-8\| = 2 MIN | ✅ |

**Procédure Vérification**:

```sql
-- Vérifier la division
SELECT
    r.id,
    r.customer_id,
    r.passenger_nbr as demande,
    COUNT(a.id) as nb_attributions,
    SUM(a.nb_passagers_assignes) as assigne_total,
    STRING_AGG(v.reference, ' + ') as vehicules_utilises
FROM reservation r
LEFT JOIN attribution a ON r.id = a.reservation_id
LEFT JOIN vehicule v ON a.vehicule_id = v.id
WHERE r.arrival_date::date = '2026-03-28'
GROUP BY r.id, r.customer_id, r.passenger_nbr;

-- Résultat attendu:
-- 5 | J2_r1_20pass | 20 | 2 | 20 | v3 + v1
```

**Checklist**:
- [ ] Division en 2 attributions
- [ ] v3 sélectionnée d'abord (écart 8)
- [ ] v1 sélectionnée en second (écart 2)
- [ ] Total 20 passagers assignés
- [ ] Pas d'utilisation de v4
- [ ] Même heure_depart pour les deux véhicules

---

### 🧪 SCÉNARIO 3: Retour Véhicule + Fenêtre (29/03)

**Objectif**: Valider les fenêtres d'attente créées par les retours

**URL API**: `GET /planning/auto?date=2026-03-29`

**Données d'entrée**:
- 7 réservations totales (3 matin + 4 attente)
- Total: 29 passagers
- Multiples fenêtres attendues

**Résultats Attendus**:

| Vérification | Attendu | Validation |
|--------------|---------|-----------|
| Fenêtres créées | 3-4 fenêtres | ✅ |
| r6(10) assignée | Matin v1 | ✅ |
| r7(10) assignée | Matin v2 | ✅ |
| r8(12) assignée | Matin v3 | ✅ |
| r9(9) assignée | v3 ou v1 retour | ✅ |
| r10(5) assignée | Regroupement v1 | ✅ |
| r11(7) assignée | Regroupement v2 | ✅ |
| r12(8) assignée | v3 retour | ✅ |
| Total passagers | 29/29 | ✅ |

**Procédure Vérification**:

```sql
-- Voir les trajets par jour
SELECT
    a.date_heure_depart::date as jour,
    (ROW_NUMBER() OVER (ORDER BY a.date_heure_depart))::INT as trajet_num,
    v.reference as vehicule,
    STRING_AGG(DISTINCT r.customer_id, ', ') as reservations,
    SUM(a.nb_passagers_assignes) as passagers,
    a.date_heure_depart::time as depart,
    a.date_heure_retour::time as retour
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
WHERE r.arrival_date::date = '2026-03-29'
GROUP BY v.id, v.reference, a.date_heure_depart, a.date_heure_retour, a.id
ORDER BY a.date_heure_depart;
```

**Checklist**:
- [ ] Matin: v1, v2, v3 occupées simultanément
- [ ] Fenêtre créée après retour v1/v2/v3
- [ ] r9 assignée immédiatement (reste prioritaire)
- [ ] r10 regroupée avec r9
- [ ] r11 assignée dans fenêtre d'attente
- [ ] r12 assignée après retour v3
- [ ] Tous les 29 passagers assignés
- [ ] 4-5 trajectoires de véhicules

---

### 🧪 SCÉNARIO 4: Disponibilité Horaire v4 (30/03)

**Objectif**: Valider la restriction heure_disponible_debut pour v4

**URL API**: `GET /planning/auto?date=2026-03-30`

**Données d'entrée**:
- 2 réservations: r1(4) à 10:00, r2(6) à 10:35
- v4 disponible UNIQUEMENT à partir de 10:30
- Total: 10 passagers

**Résultats Attendus**:

| Vérification | Attendu | Validation |
|--------------|---------|-----------|
| r1 à 10:00 | Assignée à v1 (v4 non dispo) | ✅ |
| r2 à 10:35 | Assignée à v4 (v4 dispo) | ✅ |
| v4 départ | 10:35 >= 10:30 ✓ | ✅ |
| Écart v2(4) | \|10-4\| = 6 | ✅ |
| Écart v4(6) | \|8-6\| = 2 MIN Pour r2 | ✅ |

**Procédure Vérification**:

```sql
-- Vérifier la disponibilité
SELECT
    r.arrival_date::time as arrivee,
    r.customer_id,
    r.passenger_nbr,
    v.reference as vehicule,
    v.heure_disponible_debut as v_dispo_debut,
    a.date_heure_depart::time as depart_effectif,
    CASE
        WHEN v.heure_disponible_debut IS NULL THEN 'Toujours OK'
        WHEN a.date_heure_depart::time >= v.heure_disponible_debut THEN 'OK'
        ELSE 'ERREUR!'
    END as verification
FROM reservation r
LEFT JOIN attribution a ON r.id = a.reservation_id
LEFT JOIN vehicule v ON a.vehicule_id = v.id
WHERE r.arrival_date::date = '2026-03-30'
ORDER BY r.arrival_date;

-- Résultat attendu:
-- 10:00 | J4_r1_4pass_AVANT_V4 | 4 | v1 | NULL       | 10:00 | Toujours OK
-- 10:35 | J4_r2_6pass_APRES_V4 | 6 | v4 | 10:30:00   | 10:35 | OK
```

**Checklist**:
- [ ] r1 assignée à v1 (10:00, v4 pas dispo)
- [ ] r2 assignée à v4 (10:35, v4 dispo)
- [ ] Vérification: 10:35 >= 10:30 passée
- [ ] v4 EXCLUS pour r1
- [ ] v4 INCLUS pour r2
- [ ] CLOSEST FIT appliqué (v4=2 < v2/v3)

---

### 🧪 SCÉNARIO 5: Gestion des Restes (31/03)

**Objectif**: Valider la division complexe sur 3 véhicules

**URL API**: `GET /planning/auto?date=2026-03-31`

**Données d'entrée**:
- r15(10) et r16(12) occupent v2 et v3
- r17(25 passagers) GRANDE réservation
- Total: 37 passagers

**Résultats Attendus**:

| Vérification | Attendu | Validation |
|--------------|---------|-----------|
| r17 partie 1 | v1(10) à 08:30 | ✅ |
| r17 partie 2 | v2(10) à 09:00 (après retour) | ✅ |
| r17 partie 3 | v4(5) à 10:30 (après dispo) | ✅ |
| Total divisé | 10+10+5=25 ✓ | ✅ |
| Tous assignés | 37/37 | ✅ |

**Procédure Vérification**:

```sql
-- Vérifier la division multi-véhicule
SELECT
    r.id,
    r.customer_id,
    r.passenger_nbr as demande,
    STRING_AGG(v.reference || '(' || a.nb_passagers_assignes::TEXT || ')', ' + ') as attributions,
    SUM(a.nb_passagers_assignes) as total_assigne,
    COUNT(DISTINCT a.vehicule_id) as nb_vehicules
FROM reservation r
LEFT JOIN attribution a ON r.id = a.reservation_id
LEFT JOIN vehicule v ON a.vehicule_id = v.id
WHERE r.arrival_date::date = '2026-03-31' AND r.passenger_nbr = 25
GROUP BY r.id, r.customer_id, r.passenger_nbr;

-- Résultat attendu:
-- 17 | J5_r3_25pass_GRANDE | 25 | v1(10) + v2(10) + v4(5) | 25 | 3
```

**Checklist**:
- [ ] r17 divisée en 3 parties
- [ ] v1: 10 passagers, 08:30
- [ ] v2: 10 passagers, 09:00
- [ ] v4: 5 passagers, 10:30 (respect heure_dispo)
- [ ] Total 25 assignés
- [ ] r15 et r16 complètement assignées
- [ ] Tous les 37 passagers assignés

---

### 🧪 SCÉNARIO 6: Cas Complexe (01/04)

**Objectif**: Valider la gestion globale avec 8 réservations et multiples fenêtres

**URL API**: `GET /planning/auto?date=2026-04-01`

**Données d'entrée**:
- 8 réservations (52 passagers)
- Multiples fenêtres d'arrivée et de retour
- Configuration complexe

**Résultats Attendus**:

| Vérification | Attendu | Validation |
|--------------|---------|-----------|
| Matin | r18,r19,r20 assignées | ✅ |
| Retours | Fenêtres créées | ✅ |
| Regroupements | r21,r22,r23 groupées | ✅ |
| r24, r25 | Assignées dans dernière fenêtre | ✅ |
| Total passagers | 52/52 | ✅ |
| Nombre trajets | 6-7 trajets | ✅ |

**Procédure Vérification**:

```sql
-- Résumé global Jour 6
SELECT
    COUNT(DISTINCT a.id) as nb_attributions,
    SUM(a.nb_passagers_assignes) as total_passagers,
    COUNT(DISTINCT a.vehicule_id) as nb_vehicules_utilises,
    MIN(a.date_heure_depart::time) as premier_depart,
    MAX(a.date_heure_retour::time) as dernier_retour
FROM attribution a
JOIN reservation r ON a.reservation_id = r.id
WHERE r.arrival_date::date = '2026-04-01';

-- Résultat attendu:
-- nb_attributions: 6-7
-- total_passagers: 52
-- nb_vehicules_utilises: 4
-- premier_depart: 07:00
-- dernier_retour: 10:00+
```

**Checklist**:
- [ ] 6-7 attributions créées
- [ ] 52 passagers assignés
- [ ] tous 4 véhicules utilisés
- [ ] Multiples fenêtres gérées
- [ ] Heures cohérentes
- [ ] CLOSEST FIT appliqué systematiquement

---

## VÉRIFICATION GLOBALE FINALE

Après tous les scénarios, exécuter cette vérification:

```sql
-- RÉSUMÉ GLOBAL DE TOUS LES TESTS
SELECT
    'Total Réservations' as metrique,
    COUNT(*) as valeur,
    '= 25' as attendu
FROM reservation
UNION ALL
SELECT
    'Total Passagers',
    SUM(passenger_nbr)::TEXT,
    '= 155'
FROM reservation
UNION ALL
SELECT
    'Attributions Créées',
    COUNT(*)::TEXT,
    '>= 20'
FROM attribution
UNION ALL
SELECT
    'Passagers Assignés',
    SUM(nb_passagers_assignes)::TEXT,
    '>= 140'
FROM attribution
UNION ALL
SELECT
    'Véhicules Utilisés',
    COUNT(DISTINCT vehicule_id)::TEXT,
    '= 4'
FROM attribution;

-- VALIDATION PAR JOUR
SELECT
    r.arrival_date::date as jour,
    COUNT(DISTINCT r.id) as nb_reservations,
    SUM(r.passenger_nbr) as total_demande,
    COUNT(DISTINCT a.id) as nb_attributions,
    COALESCE(SUM(a.nb_passagers_assignes), 0)::INT as total_assigne,
    COALESCE(SUM(r.passenger_nbr) - SUM(a.nb_passagers_assignes), 0)::INT as reste_non_assigne
FROM reservation r
LEFT JOIN attribution a ON r.id = a.reservation_id
GROUP BY r.arrival_date::date
ORDER BY jour;

-- VALIDATION ÉCARTS CLOSEST FIT
SELECT
    r.customer_id,
    v.reference,
    r.passenger_nbr,
    v.nb_place,
    ABS(v.nb_place - r.passenger_nbr) as ecart,
    a.nb_passagers_assignes,
    CASE
        WHEN r.passenger_nbr <= v.nb_place THEN 'OK'
        ELSE 'Division attendue'
    END as note
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
JOIN reservation r ON a.reservation_id = r.id
WHERE r.passenger_nbr <= v.nb_place
ORDER BY a.date_heure_depart, ecart;
```

---

## CRITÈRES DE SUCCÈS

### ✅ Tous les scénarios passent si:

1. **Scénario 1**: 2 attributions v1+v2, 19 passagers
2. **Scénario 2**: 2 attributions v3+v1, 20 passagers (division)
3. **Scénario 3**: 4-5 attributions, 29 passagers, fenêtres OK
4. **Scénario 4**: v1 assignée 10:00, v4 assignée 10:35
5. **Scénario 5**: 3 attributions v1+v2+v4, 25 passagers
6. **Scénario 6**: 6-7 attributions, 52 passagers

### ✅ Règles Sprint 8 validées:

- [ ] **Modification 1**: CLOSEST FIT regroupement (écart min)
- [ ] **Modification 2**: CLOSEST FIT division (écart min par itération)
- [ ] **Modification 3**: heure_disponible_debut respectée
- [ ] Tri DÉCROISSANT fenêtre arrivée
- [ ] CLOSEST FIT fenêtre retour
- [ ] Création fenêtres dynamiques
- [ ] Calcul heure_depart = MAX(arrival_date)
- [ ] Tous passagers assignés ou partiels

---

## DÉBOGAGE EN CAS D'ERREUR

Si un scénario ne passe pas:

### 1. Vérifier les données d'entrée:

```sql
SELECT * FROM reservation
WHERE arrival_date::date = '2026-03-27'
ORDER BY arrival_date;
```

### 2. Vérifier les attributions créées:

```sql
SELECT * FROM attribution
WHERE DATE(date_heure_depart) = '2026-03-27'
ORDER BY date_heure_depart;
```

### 3. Vérifier les écarts (debug CLOSEST FIT):

```sql
SELECT
    r.customer_id,
    v.reference,
    r.passenger_nbr,
    v.nb_place,
    ABS(v.nb_place - r.passenger_nbr) as ecart_calcule
FROM reservation r, vehicule v
WHERE r.arrival_date::date = '2026-03-27'
ORDER BY r.arrival_date, ecart_calcule;
```

### 4. Vérifier les conflits horaires:

```sql
SELECT
    v.reference,
    COUNT(*) as nb_attributions,
    STRING_AGG(a.date_heure_depart::time || '-' || a.date_heure_retour::time, ', ') as heures
FROM attribution a
JOIN vehicule v ON a.vehicule_id = v.id
GROUP BY v.reference
ORDER BY v.id;
```

---

## DOCUMENTATION COMPLÈTE

Pour plus de détails, consulter:
- `SPRINT8_RESULTATS_ATTENDUS.md` - Règles Sprint 8
- `SPRINT8_SIMULATION_SCENARIOS.md` - Détail de chaque scénario
- `PlanningService.java` - Implémentation de l'algorithme

---

**FIN DE LA CHECKLIST SPRINT 8**

*Tous les tests sont prêts. Procédez à l'exécution selon le protocole.*
