package service;

import model.Attribution;
import model.Distance;
import model.Reservation;
import model.TypeCarburant;
import model.Vehicule;
import model.Lieu;
import model.Utilitaire;
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
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Service de planification et d'attribution automatique de véhicules.
 * 
 * ATTRIBUTION STATIQUE : les attributions sont calculées en mémoire uniquement,
 * aucune modification en base de données.
 *
 * Calcul des horaires :
 * - dateHeureDepart = reservation.arrivalDate
 * - distanceAllerRetour = distance(lieuDepart → lieuDestination) × 2
 * - duree (heures) = distanceAllerRetour / vitesseMoyenne
 * - dateHeureRetour = dateHeureDepart + duree
 *
 * Algorithme d'attribution :
 * 1. Pour chaque réservation à la date donnée :
 * - Chercher les véhicules avec nb_places >= passengerNbr
 * - Exclure les véhicules déjà occupés (dont dateHeureRetour > dateHeureDepart)
 * - Priorité : nb places le plus proche, puis Diesel
 * - Si aucun véhicule disponible : la réservation reste NON_ASSIGNE
 */
public class PlanningService {

    private final ReservationRepository reservationRepository = new ReservationRepository();
    private final VehiculeRepository vehiculeRepository = new VehiculeRepository();
    private final DistanceRepository distanceRepository = new DistanceRepository();
    private final ParametreRepository parametreRepository = new ParametreRepository();

    /**
     * Générer le planning pour une date donnée.
     * Attribution STATIQUE (en mémoire uniquement, aucune modification en base).
     * Retourne la liste des Attribution assignées et la liste des réservations non
     * assignées.
     */
    public PlanningResult genererPlanning(LocalDateTime date) throws SQLException {

        // 1. Charger les paramètres
        double vitesseMoyenne = parametreRepository.getVitesseMoyenne(); // km/h

        // 2. Récupérer toutes les réservations pour cette date
        List<Reservation> reservations = reservationRepository.findByDate(date);

        // 3. Attribution en mémoire
        List<Attribution> attributions = new ArrayList<>();
        List<Reservation> nonAssignees = new ArrayList<>();

        for (Reservation reservation : reservations) {
            // Calculer la distance aller-retour
            BigDecimal distanceAller = getDistanceAllerSimple(reservation);

            if (distanceAller == null) {
                // Pas de distance trouvée → non assignable
                nonAssignees.add(reservation);
                continue;
            }

            BigDecimal distanceAllerRetour = distanceAller.multiply(BigDecimal.valueOf(2));

            // dateHeureDepart = arrivalDate (le véhicule part à l'heure d'arrivée du
            // client)
            LocalDateTime dateHeureDepart = reservation.getArrivalDate();

            // duree en heures = distanceAllerRetour / vitesseMoyenne
            double dureeHeures = distanceAllerRetour.doubleValue() / vitesseMoyenne;
            // Convertir en minutes (pas de temps d'attente pour l'instant)
            long dureeMinutes = Math.round(dureeHeures * 60);

            LocalDateTime dateHeureRetour = dateHeureDepart.plusMinutes(dureeMinutes);

            // Chercher véhicules disponibles (assez de places + pas de conflit horaire)
            Vehicule choisi = attribuerVehiculeEnMemoire(reservation, attributions, dateHeureDepart, dateHeureRetour);

            if (choisi != null) {
                // Créer une attribution en mémoire
                Attribution attribution = new Attribution();
                attribution.setVehicule(choisi);
                attribution.setReservation(reservation);
                attribution.setDateHeureDepart(dateHeureDepart);
                attribution.setDateHeureRetour(dateHeureRetour);
                attribution.setDistanceKm(distanceAller);
                attribution.setDistanceAllerRetourKm(distanceAllerRetour);
                attribution.setStatut("ASSIGNE");

                attributions.add(attribution);
            } else {
                nonAssignees.add(reservation);
            }
        }

        return new PlanningResult(attributions, nonAssignees);
    }

    /**
     * Récupérer la distance aller simple entre le lieu de départ et le lieu de
     * destination.
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

    private double getDistanceLieu(Lieu lieuDepart, Lieu lieuDestination) throws SQLException {
        if (lieuDepart == null || lieuDestination == null) {
            return 0.0;
        }

        Distance distance = distanceRepository.findByFromAndTo(
                lieuDepart.getId(),
                lieuDestination.getId());
        if (distance == null) {
            throw new IllegalArgumentException(
                    "Distance non trouvée entre " + lieuDepart.getLibelle() + " et " + lieuDestination.getLibelle());
        }
        return distance.getKmDistance().doubleValue() ;
    }

   private Reservation getDistanceMin(List<Reservation> reservation) throws SQLException {
        if (reservation == null) {
            throw new IllegalArgumentException("Reservation non trouvée !");
        }

        Reservation reservationMin = null;
        double min = Double.MAX_VALUE;

        for (Reservation reserv : reservation) {
            double distance = getDistanceAllerSimple(reserv).doubleValue();

            if (distance < min) {
                min = distance;
                reservationMin = reserv;
            }
        }

        return reservationMin;
    }



    
   private double getDistanceMin1(List<Reservation> reservation) throws SQLException {
        if (reservation == null) {
            throw new IllegalArgumentException("Reservation non trouvée !");
        }

        Reservation reservationMin = null;
        double min = Double.MAX_VALUE;

        for (Reservation reserv : reservation) {
            double distance = getDistanceAllerSimple(reserv).doubleValue();

            if (distance < min) {
                min = distance;
            }
        }

        return min;
    }


    ///  distance par rapport lieu 
    private List<Reservation> getSameOrderReservation(List<Reservation> reservation, double distanceMin) throws SQLException {
        if (reservation == null) {
            throw new IllegalArgumentException("Reservation non trouvée !");
        }

        List<Reservation> reservationMin = new ArrayList<>();

        Iterator<Reservation> it = reservation.iterator();

        while (it.hasNext()) {
            Reservation reserv = it.next();
            double distance = getDistanceAllerSimple(reserv).doubleValue();

            if (Math.abs(distance - distanceMin) < 0.0001) {
                reservationMin.add(reserv);
                it.remove();
            }
        }

        return reservationMin;
    }


    //     ///  distance par rapport lieu 
    private Reservation getDistanceMin(List<Reservation> reservation, Lieu nextPlace) throws SQLException {
        if (reservation == null || reservation.isEmpty()) {
            throw new IllegalArgumentException("Reservation non trouvée !");
        }

        Reservation reservationMin = null;
        double min = Double.MAX_VALUE;

        for (Reservation reserv : reservation) {
            double distance = getDistanceLieu(nextPlace, reserv.getLieuDestination());

            if (distance < min) {
                min = distance;
                reservationMin = reserv;
            }
        }

        return reservationMin;
    }


    private double getDistanceMin1(List<Reservation> reservation, Lieu nextPlace) throws SQLException {
        if (reservation == null || reservation.isEmpty()) {
            throw new IllegalArgumentException("Reservation non trouvée !");
        }

        Reservation reservationMin = null;
        double min = Double.MAX_VALUE;

        for (Reservation reserv : reservation) {
            double distance = getDistanceLieu(nextPlace, reserv.getLieuDestination());

            if (distance < min) {
                min = distance;
                reservationMin = reserv;
            }
        }

        return min;
    }



    // private List<Reservation> getListDistanceMin(List<Reservation> reservation) throws SQLException {
    //     if (reservation == null) {
    //         throw new IllegalArgumentException("Reservation non trouvée !");
    //     }
    //     List<Reservation> reservationMin = new ArrayList<>();
    //     // double min = getDistanceAllerSimple(getDistanceMin(reservation)).doubleValue();
    //     Map<Reservation, Integer> values = new HashMap<>();
    //     for (Reservation reserv : reservation) {
    //         // double distance = getDistanceAllerSimple(reserv).doubleValue();
    //         String initString = reserv.getLieuDestination().getInitial();
    //         values.put(reserv, new Utilitaire().getValueInitial(initString));
    //     }

    //     reservationMin = values.entrySet()
    //             .stream()
    //             .sorted(Map.Entry.comparingByValue())
    //             .map(Map.Entry::getKey)
    //             .toList();

    //     return reservationMin;
    // }



    //  this function sort a reservation list by there initial string  of the place name
    // Dans le cas hoe mitovy tss hafa n distance entre 2 reservation dia atao sort par initial string
    private List<Reservation> getListDistanceOrderByInitial(List<Reservation> reservation) throws SQLException {
        if (reservation == null) {
            throw new IllegalArgumentException("Reservation non trouvée !");
        }

        List<Reservation> reservationMin = new ArrayList<>();
        Map<Reservation, Integer> values = new HashMap<>();

        for (Reservation reserv : reservation) {
            String initString = reserv.getLieuDestination().getInitial();
            values.put(reserv, new Utilitaire().getValueInitial(initString));
        }

        reservationMin = values.entrySet()
                .stream()
                .sorted(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .toList();

        return reservationMin;
    }

    


    private List<Reservation> directionX(List<Reservation> reservation) throws SQLException {
        if (reservation == null) {
            throw new IllegalArgumentException("Reservation non trouvée !");
        }

        List<Reservation> reservationOrder = new ArrayList<>();

        double distanceMin = getDistanceMin1(reservation);
        List<Reservation> listSameMin = getSameOrderReservation(reservation, distanceMin);

        List<Reservation> result = getListDistanceOrderByInitial(listSameMin);

        reservationOrder.addAll(result);

        if(result.isEmpty()){
            return reservationOrder;
        }

        Reservation lastReservation = result.get(result.size() - 1);

        while (!reservation.isEmpty()) {

            double distance = getDistanceMin1(reservation, lastReservation.getLieuDestination());

            List<Reservation> listSame = getSameOrderReservation(reservation, distance);

            List<Reservation> resultSame = getListDistanceOrderByInitial(listSame); // correction

            reservationOrder.addAll(resultSame);

            if(!resultSame.isEmpty()){
                lastReservation = resultSame.get(resultSame.size() - 1);
            }
        }

        return reservationOrder;
    }
    // private List<Reservation> OrderReservation(List<Reservation> reservation) throws SQLException {
    //     if (reservation == null) {
    //         throw new IllegalArgumentException("Reservation non trouvée !");
    //     }
    //     List<Reservation> reservationOrder = new ArrayList<>();
    //     for (Reservation reserv : reservationOrder) {

    //     }

    //     return distance.getKmDistance();
    // }

    private double getDistanceRegrouper(List<Reservation> reservation) throws SQLException {
        if (reservation == null) {
            throw new IllegalArgumentException("Reservation non trouvée !");
        }
        double totalDistance = 0.0;
        Lieu LieuDepart = new Lieu();
        Lieu LieuFinal = new Lieu();
        for (int i = 1; i < reservation.size(); i++) {
            if (i == 0) {
                LieuFinal = reservation.get(i).getLieuDestination();
            } else {
                totalDistance += getDistanceLieu(LieuFinal, reservation.get(i).getLieuDestination());
                LieuFinal = reservation.get(i).getLieuDestination();
            }

            if (i == reservation.size() - 1) {
                totalDistance += getDistanceLieu(reservation.get(i).getLieuDestination(),
                        reservation.get(i).getLieuDepart());
            }
        }

        // return BigDecimal.valueOf(totalDistance);
        return totalDistance;
    }

    // private BigDecimal getDistanceTotal(List<Reservation> reservation) throws
    // SQLException {

    // }

    /**
     * Attribution en mémoire d'un véhicule à une réservation.
     * Vérifie les conflits horaires avec les attributions déjà faites dans cette
     * simulation.
     * Ne modifie PAS la base de données.
     */
    private Vehicule attribuerVehiculeEnMemoire(Reservation reservation, List<Attribution> attributionsExistantes,
            LocalDateTime dateHeureDepart, LocalDateTime dateHeureRetour) throws SQLException {
        // Chercher véhicules avec assez de places
        List<Vehicule> disponibles = vehiculeRepository.findAvailableVehicules(reservation.getPassengerNbr());

        // Exclure les véhicules déjà occupés dans cette simulation (conflit horaire)
        disponibles = disponibles.stream()
                .filter(v -> !hasConflitHoraire(v.getId(), dateHeureDepart, dateHeureRetour, attributionsExistantes))
                .collect(Collectors.toList());

        if (disponibles.isEmpty()) {
            return null;
        }

        return choisirVehicule(disponibles, reservation.getPassengerNbr());
    }

    /**
     * Vérifier si un véhicule a un conflit horaire avec les attributions déjà
     * faites.
     * Conflit = le véhicule est occupé (pas encore de retour au moment du nouveau
     * départ).
     */
    private boolean hasConflitHoraire(Long vehiculeId, LocalDateTime nouveauDepart, LocalDateTime nouveauRetour,
            List<Attribution> attributionsExistantes) {
        for (Attribution t : attributionsExistantes) {
            if (t.getVehicule().getId().equals(vehiculeId)) {
                // Conflit si les plages horaires se chevauchent
                // Pas de conflit si : nouveauRetour <= existantDepart OU nouveauDepart >=
                // existantRetour
                boolean pasDeConflit = nouveauRetour.compareTo(t.getDateHeureDepart()) <= 0
                        || nouveauDepart.compareTo(t.getDateHeureRetour()) >= 0;
                if (!pasDeConflit) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Choisir le meilleur véhicule selon les règles métier :
     * 1. Priorité au nb de places le plus PROCHE du nb de passagers
     * 2. Si plusieurs avec même nb de places → priorité DIESEL
     * 3. Si plusieurs Diesel → choix aléatoire
     * 4. Si aucun Diesel → choix aléatoire
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

        // Étape 3 : Parmi les plus proches, priorité Diesel
        List<Vehicule> diesels = plusProches.stream()
                .filter(v -> v.getTypeCarburant() == TypeCarburant.D)
                .collect(Collectors.toList());

        if (diesels.size() >= 2) {
            Collections.shuffle(diesels);
            return diesels.get(0);
        } else if (diesels.size() == 1) {
            return diesels.get(0);
        } else {
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
