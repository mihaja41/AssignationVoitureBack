package service;

import model.Attribution;
import model.Distance;
import model.Reservation;
import model.TypeCarburant;
import model.Vehicule;
import repository.DistanceRepository;
import repository.ParametreRepository;
import repository.ReservationRepository;
import repository.VehiculeRepository;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Service de planification et d'attribution automatique de véhicules.
 * 
 * Sprint 4 – Regroupement d'assignation :
 *
 * ALGORITHME :
 * 1. Récupérer toutes les réservations d'une date donnée
 * 2. Trier par nombre de passagers DÉCROISSANT (traiter le plus gros groupe en premier)
 * 3. Pour chaque réservation non encore assignée :
 *    a. Chercher les véhicules avec nb_places >= passengerNbr
 *    b. Exclure véhicule si heure_retour > heure_depart (pas encore revenu)
 *    c. Choisir le véhicule : 
 *       - minimiser (nb_places - passengerNbr) → moins de places vides
 *       - si égalité → priorité Diesel ('D')
 *       - si encore égalité → random
 *    d. REGROUPEMENT : si places restantes >= 1, chercher d'autres réservations compatibles :
 *       - même date et heure de départ
 *       - même lieu de départ (aéroport)
 *       - passengerNbr <= places restantes
 *       - non encore assignées
 *       Les assigner au même véhicule, recalculer places restantes, répéter.
 * 4. Retourner les attributions et les réservations non assignées.
 */
public class PlanningService {

    private final ReservationRepository reservationRepository = new ReservationRepository();
    private final VehiculeRepository vehiculeRepository = new VehiculeRepository();
    private final DistanceRepository distanceRepository = new DistanceRepository();
    private final ParametreRepository parametreRepository = new ParametreRepository();

    /**
     * Générer le planning pour une date donnée.
     * Attribution STATIQUE (en mémoire uniquement, aucune modification en base).
     * Implémente le regroupement Sprint 4.
     */
    public PlanningResult genererPlanning(LocalDateTime date) throws SQLException {

        // 1. Charger les paramètres
        double vitesseMoyenne = parametreRepository.getVitesseMoyenne();   // km/h

        // 2. Récupérer toutes les réservations pour cette date
        List<Reservation> reservations = reservationRepository.findByDate(date);

        // 3. Trier par nombre de passagers DÉCROISSANT
        //    Traiter en premier la réservation avec le plus grand nombre de passagers
        reservations.sort((a, b) -> Integer.compare(b.getPassengerNbr(), a.getPassengerNbr()));

        // 4. Attribution avec regroupement
        List<Attribution> attributions = new ArrayList<>();
        List<Reservation> nonAssignees = new ArrayList<>();
        Set<Long> assignedIds = new HashSet<>();

        for (Reservation reservation : reservations) {
            // Sauter si déjà assignée (regroupée dans un véhicule précédent)
            if (assignedIds.contains(reservation.getId())) {
                continue;
            }

            // Calculer la distance aller simple
            BigDecimal distanceAller = getDistanceAllerSimple(reservation);
            if (distanceAller == null) {
                // Pas de distance trouvée → non assignable
                nonAssignees.add(reservation);
                continue;
            }

            BigDecimal distanceAllerRetour = distanceAller.multiply(BigDecimal.valueOf(2));

            // dateHeureDepart = arrivalDate (le véhicule part à l'heure d'arrivée du client)
            LocalDateTime dateHeureDepart = reservation.getArrivalDate();

            // duree en heures = distanceAllerRetour / vitesseMoyenne
            double dureeHeures = distanceAllerRetour.doubleValue() / vitesseMoyenne;
            long dureeMinutes = Math.round(dureeHeures * 60);
            LocalDateTime dateHeureRetour = dateHeureDepart.plusMinutes(dureeMinutes);

            // Chercher le meilleur véhicule disponible
            Vehicule choisi = attribuerVehiculeEnMemoire(reservation, attributions, dateHeureDepart);

            if (choisi != null) {
                // Créer l'attribution
                Attribution attribution = new Attribution();
                attribution.setVehicule(choisi);
                attribution.setReservation(reservation);   // backward compat
                attribution.addReservation(reservation);    // liste regroupée
                attribution.setDateHeureDepart(dateHeureDepart);
                attribution.setDateHeureRetour(dateHeureRetour);
                attribution.setDistanceKm(distanceAller);
                attribution.setDistanceAllerRetourKm(distanceAllerRetour);
                attribution.setStatut("ASSIGNE");

                assignedIds.add(reservation.getId());

                // ============================
                // REGROUPEMENT (Sprint 4 DEV1)
                // ============================
                int placesRestantes = choisi.getNbPlace() - reservation.getPassengerNbr();

                if (placesRestantes >= 1) {
                    // Chercher d'autres réservations compatibles à regrouper
                    for (Reservation autre : reservations) {
                        if (placesRestantes < 1) break;
                        if (assignedIds.contains(autre.getId())) continue;

                        // Critères de compatibilité pour regroupement :
                        // 1. Même date ET même heure de départ (arrivalDate identique)
                        if (!autre.getArrivalDate().equals(reservation.getArrivalDate())) continue;
                        // 2. Même lieu de départ (aéroport)
                        if (autre.getLieuDepart() == null || reservation.getLieuDepart() == null) continue;
                        if (!autre.getLieuDepart().getId().equals(reservation.getLieuDepart().getId())) continue;
                        // 3. Nombre de passagers <= places restantes
                        if (autre.getPassengerNbr() > placesRestantes) continue;

                        // Compatible → regrouper dans le même véhicule
                        attribution.addReservation(autre);
                        assignedIds.add(autre.getId());
                        placesRestantes -= autre.getPassengerNbr();
                    }
                }

                attributions.add(attribution);
            } else {
                nonAssignees.add(reservation);
            }
        }

        return new PlanningResult(attributions, nonAssignees);
    }

    /**
     * Récupérer la distance aller simple entre le lieu de départ et le lieu de destination.
     */
    private BigDecimal getDistanceAllerSimple(Reservation reservation) throws SQLException {
        if (reservation.getLieuDepart() == null || reservation.getLieuDestination() == null) {
            return null;
        }

        Distance distance = distanceRepository.findByFromAndTo(
                reservation.getLieuDepart().getId(),
                reservation.getLieuDestination().getId());

        return (distance != null) ? distance.getKmDistance() : null;
    }

    /**
     * Attribution en mémoire d'un véhicule à une réservation.
     * Vérifie la disponibilité : exclut les véhicules dont heure_retour > heure_depart.
     */
    private Vehicule attribuerVehiculeEnMemoire(Reservation reservation, List<Attribution> attributionsExistantes,
                                                 LocalDateTime dateHeureDepart) throws SQLException {
        // Chercher véhicules avec assez de places
        List<Vehicule> disponibles = vehiculeRepository.findAvailableVehicules(reservation.getPassengerNbr());

        // Exclure les véhicules pas encore revenus (heure_retour > heure_depart de la réservation)
        disponibles = disponibles.stream()
                .filter(v -> !hasConflitHoraire(v.getId(), dateHeureDepart, attributionsExistantes))
                .collect(Collectors.toList());

        if (disponibles.isEmpty()) {
            return null;
        }

        return choisirVehicule(disponibles, reservation.getPassengerNbr());
    }

    /**
     * Vérifier si un véhicule a un conflit horaire.
     * Sprint 4 : Exclure véhicule si heure_retour > heure_depart de la réservation
     * (le véhicule n'est pas encore revenu au moment du nouveau départ).
     */
    private boolean hasConflitHoraire(Long vehiculeId, LocalDateTime nouveauDepart,
                                       List<Attribution> attributionsExistantes) {
        for (Attribution t : attributionsExistantes) {
            if (t.getVehicule().getId().equals(vehiculeId)) {
                // Conflit si le véhicule n'est pas encore revenu
                if (t.getDateHeureRetour().compareTo(nouveauDepart) > 0) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Choisir le meilleur véhicule selon les règles métier Sprint 4 :
     * 1. Priorité au nb de places le plus PROCHE du nb de passagers
     *    → (nb_places - passengerNbr) le plus petit → minimiser places vides
     * 2. Si plusieurs avec même écart → priorité DIESEL ('D')
     * 3. Si encore égalité (même places + même carburant) → choix aléatoire (random)
     */
    private Vehicule choisirVehicule(List<Vehicule> disponibles, int passengerNbr) {
        if (disponibles.size() == 1) {
            return disponibles.get(0);
        }

        // Étape 1 : Trouver le nb de places minimum (le plus proche du nb passagers)
        int minPlaces = disponibles.stream()
                .mapToInt(Vehicule::getNbPlace)
                .min()
                .orElse(Integer.MAX_VALUE);

        // Étape 2 : Garder uniquement les véhicules avec ce nb de places minimum
        List<Vehicule> plusProches = disponibles.stream()
                .filter(v -> v.getNbPlace() == minPlaces)
                .collect(Collectors.toList());

        if (plusProches.size() == 1) {
            return plusProches.get(0);
        }

        // Étape 3 : Parmi les plus proches, priorité Diesel ('D')
        List<Vehicule> diesels = plusProches.stream()
                .filter(v -> v.getTypeCarburant() == TypeCarburant.D)
                .collect(Collectors.toList());

        if (diesels.size() >= 2) {
            // Encore égalité → random
            Collections.shuffle(diesels);
            return diesels.get(0);
        } else if (diesels.size() == 1) {
            return diesels.get(0);
        } else {
            // Aucun diesel → random parmi les plus proches
            Collections.shuffle(plusProches);
            return plusProches.get(0);
        }
    }

    /**
     * Classe interne pour retourner le résultat du planning.
     */
    public static class PlanningResult {
        private final List<Attribution> attributions;
        private final List<Reservation> reservationsNonAssignees;

        public PlanningResult(List<Attribution> attributions, List<Reservation> reservationsNonAssignees) {
            this.attributions = attributions;
            this.reservationsNonAssignees = reservationsNonAssignees;
        }

        public List<Attribution> getAttributions() {
            return attributions;
        }

        public List<Reservation> getReservationsNonAssignees() {
            return reservationsNonAssignees;
        }
    }
}
