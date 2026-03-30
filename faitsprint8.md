# Sprint 8 - Implémentation complète

## Résumé des fonctionnalités implémentées

### 1. Fenêtres basées sur les retours de véhicules

**Avant (Sprint 7):** Les fenêtres étaient créées à partir des dates d'arrivée des réservations.

**Après (Sprint 8):** Les fenêtres sont créées à partir des heures de retour des véhicules à l'aéroport.

### 2. Priorisation des réservations non assignées

À chaque fenêtre:
1. **Prioritaires** (arrivées AVANT le début de la fenêtre) → triées par passagers décroissant
2. **Nouvelles** (arrivées DANS la fenêtre) → triées par date d'arrivée puis passagers décroissant

### 3. Sélection du véhicule optimal

Critères de sélection (dans l'ordre):
1. Écart minimum entre places disponibles et passagers
2. Moins de trajets effectués
3. Diesel prioritaire
4. Aléatoire

### 4. Fenêtres d'attente dynamiques

- Si un véhicule n'est pas plein après assignation initiale, il ouvre une fenêtre d'attente
- Pendant cette fenêtre, les nouvelles réservations compatibles sont assignées pour remplir le véhicule
- Le véhicule part quand il est plein OU à l'heure d'arrivée de la dernière réservation assignée

### 5. Gestion des restes et divisions

- Si une réservation ne peut pas être entièrement assignée (passagers > places), elle est divisée
- Le reste devient une réservation partielle traitée en priorité dans la fenêtre suivante

---

## Fichiers modifiés

### `Project1/src/main/java/repository/VehiculeRepository.java`

**Nouvelle méthode ajoutée:**
```java
public List<Vehicule> findVehiculesDisponiblesAuDebut(LocalDateTime date) throws SQLException
```
- Trouve les véhicules sans attribution se terminant après la date donnée
- Utilisée pour identifier les véhicules disponibles dès le début de la journée

### `Project1/src/main/java/service/PlanningService.java`

**Nouvelles classes internes:**
- `VehicleAvailabilityEvent` - Représente un événement de disponibilité de véhicule
- `FenetreSprint8` - Fenêtre avec liste de véhicules disponibles

**Nouvelles méthodes:**

| Méthode | Description |
|---------|-------------|
| `construireFenetresBaseesSurRetourVehicules()` | Construit les fenêtres à partir des retours de véhicules |
| `traiterFenetreSprint8()` | Traite une fenêtre Sprint 8 avec priorité aux anciennes réservations |
| `creerAttributionSprint8()` | Crée une attribution avec les paramètres Sprint 8 |
| `estCompatiblePourRegroupement()` | Vérifie si deux réservations peuvent être regroupées (même lieu de départ) |

**Méthode principale modifiée:**
- `genererPlanning()` utilise maintenant le nouveau système Sprint 8

---

## Algorithme détaillé

```
ENTRÉE: Date de planification

1. Récupérer toutes les réservations du jour
2. Construire les fenêtres basées sur les retours de véhicules:
   a. Récupérer véhicules disponibles dès le début (aucune attribution)
   b. Récupérer véhicules qui reviennent pendant la journée
   c. Créer des "événements de disponibilité" triés chronologiquement
   d. Grouper les événements en fenêtres (même heure = même fenêtre)

3. Pour chaque fenêtre:
   a. Collecter réservations prioritaires (arrivées AVANT fenêtre)
   b. Trier par passagers décroissant
   c. Collecter nouvelles arrivées (dans la fenêtre)
   d. Pour chaque réservation:
      - Sélectionner véhicule optimal (écart minimum)
      - Assigner passagers
      - Si véhicule pas plein: remplir avec réservations compatibles
      - Si division nécessaire: créer partielle pour le reste

4. Reporter les partielles vers la fenêtre suivante

SORTIE: Liste d'attributions, réservations non assignées, partielles
```

---

## Exemple de fonctionnement

### Données d'entrée:
```
Véhicules:
  v2: 10 places, retour 09:45 (Es)
  v3: 12 places, retour 10:12 (D)

Réservations non assignées (restes):
  r1: 9 passagers, arrivée 08:00
  r2: 5 passagers, arrivée 07:30

Nouvelles réservations:
  r3: 1 passager, arrivée 10:00
  r4: 7 passagers, arrivée 10:10
  r5: 5 passagers, arrivée 10:11
```

### Exécution:

**Fenêtre 1: [09:45 - 10:15] (v2 retourne)**
1. Prioritaires: [r1(9), r2(5)] triés par passagers DESC
2. r1(9) → v2(10), reste 1 place
3. r2(5) partiellement → 1 passager dans v2, v2 plein
4. v2 part à 09:45
5. r2 reste(4) → partielle pour prochaine fenêtre

**Fenêtre 2: [10:12 - 10:42] (v3 retourne)**
1. Prioritaires: [r2-reste(4), r3(1)] (arrivées avant 10:12)
2. Nouvelles: [r4(7), r5(5)]
3. r2-reste(4) → v3(12), reste 8 places
4. r4(7) → v3, reste 1 place
5. r3(1) → v3, plein
6. v3 part à 10:10 (heure d'arrivée de r4)
7. r5(5) → non assignée (pas de véhicule disponible)

---

## Tests recommandés

1. **Cas simple:** Un véhicule, une réservation
2. **Priorité:** Plusieurs réservations arrivées avant le retour du véhicule
3. **Division:** Réservation plus grande que la capacité du véhicule
4. **Fenêtre d'attente:** Véhicule pas plein, remplissage avec nouvelles arrivées
5. **Regroupement:** Plusieurs réservations du même lieu de départ
6. **Exemple complet:** Scénario ci-dessus avec v2, v3, r1-r5

---

## Notes techniques

- La durée de la fenêtre d'attente est récupérée depuis la BD via `parametreRepository.getTempsAttente()`
- Les critères de sélection de véhicule (écart minimum, trajets, diesel) étaient déjà implémentés dans Sprint 7
- La méthode `genererPlanningAvecEnregistrement()` sauvegarde automatiquement les attributions en BD
- Le fichier de debug `/tmp/planning_debug.log` contient les informations sur les fenêtres créées
