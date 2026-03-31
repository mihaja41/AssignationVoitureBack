# Sprint 8 - Suivi des écarts (après corrections)

Date de mise à jour: 31/03/2026

## Résumé

- État global: **Corrections appliquées**
- Build: `mvn -DskipTests compile` **OK**

## Points demandés et statut

1. Fenêtres recalculées dynamiquement après nouveaux retours  
Statut: **Fait**

2. Cas particulier point 5 (fenêtre issue d’une réservation non assignée)  
Statut: **Fait**

3. Remplissage fenêtre d’attente en “closest fit”  
Statut: **Fait**

4. Retours véhicules: récupérer tous les événements (pas seulement `MAX`)  
Statut: **Fait**

5. Double enregistrement `saveAll`  
Statut: **Fait** (`genererPlanning()` ne persiste plus, la persistance reste dans `genererPlanningAvecEnregistrement()`)

## Détail des modifications

- `Project1/src/main/java/service/PlanningService.java`
  - Recalcul dynamique des fenêtres à chaque itération.
  - Ajout d’une fenêtre “arrival-driven” pour réservation non assignée (point 5).
  - Remplissage véhicule via sélection itérative de la réservation la plus proche des places restantes.
  - Suppression des écritures BD directes dans `genererPlanning()` / traitement fenêtre.

- `Project1/src/main/java/repository/AttributionRepository.java`
  - Ajout de `getEvenementsRetourVehicules(...)` pour remonter tous les retours chronologiques.

## Validation technique

- Compilation réussie: `mvn -DskipTests compile`
