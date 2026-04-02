# SPRINT 8 - GUIDE COMPLET DE SIMULATION ET VALIDATION

**Date**: 2026-04-03
**Statut**: ✅ Prêt pour test complet
**Documents créés**: 4 fichiers de simulation et validation

---

## 📋 TABLE DES MATIÈRES

### 1️⃣ **Documentation Principale (Ce fichier)**
   - Vue d'ensemble du Sprint 8
   - Navigation dans les documents
   - Instructions rapides

### 2️⃣ **SPRINT8_RESULTATS_ATTENDUS.md**
   📄 [Lire le fichier complet](SPRINT8_RESULTATS_ATTENDUS.md)

   **Contenu**: Les règles exactes attendues pour Sprint 8
   - Logique des 2 types de fenêtres (ARRIVÉE et RETOUR)
   - 5 scénarios détaillés avec attendus exacts
   - Configuration: 4 véhicules, 3 lieux
   - Paramètres: vitesse 50km/h, fenêtre 30 min

   **À lire EN PREMIER avant toute implémentation**

### 3️⃣ **SPRINT8_SIMULATION_SCENARIOS.md**
   📄 [Lire le fichier complet](SPRINT8_SIMULATION_SCENARIOS.md)

   **Contenu**: Détail complet de 6 scénarios de test
   - 6 scénarios progressifs de complexité
   - Chaque scénario avec: description, données, algorithm expectedé, résultat attendu
   - Tous les cas d'usage du Sprint 8
   - Critères de validation pour chaque scénario

   **À consulter avant de lancer les tests**

### 4️⃣ **SPRINT8_VALIDATION_CHECKLIST.md**
   📄 [Lire le fichier complet](SPRINT8_VALIDATION_CHECKLIST.md)

   **Contenu**: Guide pratique de validation et checklist
   - Installation et préparation
   - Protocole de test par scénario
   - Requêtes SQL pour vérification
   - Critères de succès
   - Debugging en cas d'erreur

   **À utiliser pendant l'exécution des tests**

### 5️⃣ **SPRINT8_TEST_SIMULATION.sql**
   📄 [Fichier SQL](Project1/sql/SPRINT8_TEST_SIMULATION.sql)

   **Contenu**: Données de test complètes
   - Initialisation base de données
   - 4 véhicules (v1, v2, v3, v4)
   - 3 lieux (IVATO, CARLTON, COLBERT)
   - 25 réservations sur 6 jours
   - Requêtes MySQL de vérification

   **À exécuter pour initialiser les données**

---

## 🚀 DÉMARRAGE RAPIDE

### Avant les tests (5-10 min)

```bash
# 1. Lire les règles
cat SPRINT8_RESULTATS_ATTENDUS.md

# 2. Lire les scénarios
cat SPRINT8_SIMULATION_SCENARIOS.md

# 3. Initialiser les données
psql -U postgres -f Project1/sql/SPRINT8_TEST_SIMULATION.sql
```

### Pendant les tests (30-60 min)

```bash
# 4. Compiler le projet
mvn clean compile package

# 5. Démarrer l'application
# (Dans l'IDE ou via tomcat)

# 6. Exécuter les 6 API calls (voir VALIDATION_CHECKLIST.md)
curl "http://localhost:8080/planning/auto?date=2026-03-27"
curl "http://localhost:8080/planning/auto?date=2026-03-28"
# ... etc jusqu'à 2026-04-01

# 7. Vérifier les résultats (requêtes SQL du CHECKLIST)
```

### Valider les résultats (20-30 min)

```bash
# 8. Vérifier avec la checklist
# Utiliser les requêtes SQL dans SPRINT8_VALIDATION_CHECKLIST.md

# 9. Comparer avec les attendus
# Utiliser les tables de validation dans SPRINT8_SIMULATION_SCENARIOS.md
```

---

## 📊 RÉSUMÉ DES SCÉNARIOS

### Jour 1: 27/03 - Scénario 1
**Regroupement Optimal avec CLOSEST FIT**
- 4 réservations: 9, 5, 3, 2 passagers
- 2 véhicules utilisés (v1, v2)
- 19 passagers assignés / 19 total
- ✅ Valide si: 2 attributions avec écarts minimaux

### Jour 2: 28/03 - Scénario 2
**Division Optimale (20 passagers > 12 places max)**
- 1 réservation de 20 passagers
- 2 véhicules (v3=12, v1=8)
- Division avec CLOSEST FIT
- ✅ Valide si: v3=8, v1=2, tous 20 assignés

### Jour 3: 29/03 - Scénario 3
**Retours Véhicules + Fenêtres Dynamiques**
- 7 réservations (3 matin, 4 attente)
- 3-4 fenêtres d'attente créées
- Retours créent nouvelles fenêtres
- ✅ Valide si: 4-5 attributions, 29/29 assignés

### Jour 4: 30/03 - Scénario 4
**Validation heure_disponible_debut (v4 → 10:30)**
- 2 réservations: 4 à 10:00, 6 à 10:35
- v4 NON disponible avant 10:30
- Respect de la restriction horaire
- ✅ Valide si: r1→v1, r2→v4, vérif heure >= 10:30

### Jour 5: 31/03 - Scénario 5
**Division Complexe en 3 Parties (25 passagers)**
- Grande réservation nécessite 3 véhicules
- v1(10) + v2(10) + v4(5)
- Gestion des restes avec disponibilité
- ✅ Valide si: 3 attributions, 25/25 assignés

### Jour 6: 01/04 - Scénario 6
**Cas Complexe Multi-Fenêtres (8 réservations)**
- 52 passagers sur 8 réservations
- 4-5 fenêtres imbriquées
- Multiples regroupements
- ✅ Valide si: 6-7 attributions, 52/52 assignés

---

## 🔍 RÈGLES SPRINT 8 À VALIDER

### ✅ MODIFICATION 1: Regroupement Optimal (CLOSEST FIT)
**Contexte**: Fenêtre issue d'une arrivée de réservation

```
Tri: DÉCROISSANT par nb_passagers
Sélection: véhicule avec |nb_places - nb_passagers| = MINIMUM
Regroupement: CLOSEST FIT pour remplir places restantes
Formule clé: Math.abs(places - passagers) = min
```

**Validé dans**: Scénarios 1, 3, 6

### ✅ MODIFICATION 2: Division Optimale (CLOSEST FIT pour division)
**Contexte**: Réservation requiert plusieurs véhicules

```
Chaque itération: Sélectionner véhicule avec écart minimum
Math.abs(nb_places - passagers_restants) = minimum
Tie-break: Moins de trajets → Diesel → Aléatoire
Continue jusqu'à tous passagers assignés
```

**Validé dans**: Scénarios 2, 5, 6

### ✅ MODIFICATION 3: Disponibilité Horaire
**Contexte**: Véhicules avec heure_disponible_debut

```
Validation: heure_depart >= heure_disponible_debut
Vérification: Avant d'assigner un véhicule
Impact: Exclure les véhicules non disponibles
```

**Validé dans**: Scénarios 4, 5

---

## 📈 MÉTRIQUES ATTENDUES (GLOBALES)

| Métrique | Total | Détail |
|----------|-------|--------|
| **Total Réservations** | 25 | 4+1+7+2+3+8 |
| **Total Passagers** | 155 | 19+20+29+10+25+52 |
| **Attributions** | 20-25 | Dépend des regroupements |
| **Passagers Assignés** | 155 | 100% assignés si OK |
| **Véhicules Utilisés** | 4 | v1, v2, v3, v4 |
| **Trajets Totaux** | 20-25 | Moyenne 4/jour |

---

## 🎯 POINTS CLÉS À VALIDER

### Avant de Commencer:

- [ ] Version Java: 21+ ✓
- [ ] Framework: Spring 6.1.3+ ✓
- [ ] Base PostgreSQL accessible
- [ ] PlanningService.java compilé
- [ ] Transactions DB en place

### Pendant les Tests:

- [ ] Appels API retournent code 200
- [ ] Attributions insérées en DB
- [ ] Heures départ/retour calculées
- [ ] Écarts CLOSEST FIT minimaux
- [ ] Division activée quand nécessaire
- [ ] Fenêtres créées correctement

### Après les Tests:

- [ ] Tous les passagers assignés
- [ ] Pas de doublons en DB
- [ ] Heures cohérentes (départ <= retour)
- [ ] heure_disponible_debut respectée (v4)
- [ ] Tri DÉCROISSANT appliqué (fenêtre arrivée)
- [ ] CLOSEST FIT appliqué partout

---

## 📚 FICHIERS DE RÉFÉRENCE

### Code Source:
- `Project1/src/main/java/service/PlanningService.java` - Implémentation
- `Project1/src/main/java/model/Attribution.java` - Modèle attribution
- `Project1/src/main/java/model/Vehicule.java` - Modèle véhicule

### Configuration:
- `pom.xml` - Dépendances Maven
- `Project1/sql/` - Scripts SQL

### Tests Existants (si applicable):
- `SPRINT8_DATA_COMPLET.sql` - Données anciennes (reference)
- `SPRINT8_DONNEES_SIMULATION.sql` - Données anciennes

---

## 🔗 LIENS RAPIDES

### Documentation Sprint 8:
- [Règles Attendues](SPRINT8_RESULTATS_ATTENDUS.md)
- [Simulation Scénarios](SPRINT8_SIMULATION_SCENARIOS.md)
- [Checklist Validation](SPRINT8_VALIDATION_CHECKLIST.md)

### Données SQL:
- [Script Test Complet](Project1/sql/SPRINT8_TEST_SIMULATION.sql)
- [Données Anciennes Ref](Project1/sql/SPRINT8_DATA_COMPLET.sql)

### Code Source:
- [PlanningService.java](Project1/src/main/java/service/PlanningService.java)
- [Attribution.java](Project1/src/main/java/model/Attribution.java)

---

## 📞 FAQ RAPIDE

**Q: Par où commencer?**
A: Lire `SPRINT8_RESULTATS_ATTENDUS.md` puis `SPRINT8_SIMULATION_SCENARIOS.md`

**Q: Où trouver les attendus exacts?**
A: Dans `SPRINT8_SIMULATION_SCENARIOS.md` - chaque scénario détaille le résultat

**Q: Comment valider mon implémentation?**
A: Utiliser `SPRINT8_VALIDATION_CHECKLIST.md` avec les requêtes SQL

**Q: Quelles sont les métriques de succès?**
A: Voir section "MÉTRIQUES ATTENDUES" ou la feuille d'examen dans CHECKLIST

**Q: Comment déboguer si ça ne marche pas?**
A: Section "DÉBOGAGE EN CAS D'ERREUR" dans `SPRINT8_VALIDATION_CHECKLIST.md`

---

## ✨ STATUT DU PROJET

**Date Création**: 2026-04-03
**Dernière Mise à Jour**: 2026-04-03
**Documents Créés**: 4
**Scénarios Documentés**: 6
**Total Réservations Test**: 25
**Total Passagers Test**: 155

**État**: ✅ **PRÊT POUR TEST COMPLET**

Tous les documents de simulation, validation et checklist sont préparés.
Prêt à tester la conformité du projet avec les règles Sprint 8.

---

## 🎓 AIDE SUPPLÉMENTAIRE

**Pour comprendre les règles Sprint 8**:
1. Lire d'abord `SPRINT8_RESULTATS_ATTENDUS.md` - OBLIGATOIRE
2. Consulter les scénarios détaillés dans `SPRINT8_SIMULATION_SCENARIOS.md`
3. Regarder les algorithmes étape par étape

**Pour exécuter les tests**:
1. Suivre le guide dans `SPRINT8_VALIDATION_CHECKLIST.md`
2. Utiliser les requêtes SQL fournies
3. Cocher les case à case dans la checklist

**Pour déboguer**:
1. Consulter la section "DÉBOGAGE" du CHECKLIST
2. Exécuter les requêtes de vérification SQL
3. Comparer avec les attendus dans les scénarios

---

**FIN DU GUIDE - BONNE CHANCE AVEC VOS TESTS! 🚀**

*Pour toute question, référez-vous à un des 4 documents de simulation.*
