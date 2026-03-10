package service;

import model.Attribution;
import model.Distance;
import model.Reservation;
import model.TypeCarburant;
import model.Vehicule;
import model.Lieu;
import model.TrajetCar;
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
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import java.util.Iterator;
import java.util.Map;
import java.util.HashMap;

/**
 * Service de planification et d'attribution automatique de véhicules.
 * 
 * Sprint 4 – Regroupement d'assignation :
 *
 * ALGORITHME :
 * 1. Récupérer toutes les réservations d'une date donnée
 * 2. Trier par nombre de passagers DÉCROISSANT (traiter le plus gros groupe en
 * premier)
 * 3. Pour chaque réservation non encore assignée :
 * a. Chercher les véhicules avec nb_places >= passengerNbr
 * b. Exclure véhicule si heure_retour > heure_depart (pas encore revenu)
 * c. Choisir le véhicule :
 * - minimiser (nb_places - passengerNbr) → moins de places vides
 * - si égalité → priorité Diesel ('D')
 * - si encore égalité → random
 * d. REGROUPEMENT : si places restantes >= 1, chercher d'autres réservations
 * compatibles :
 * - même date et heure de départ
 * - même lieu de départ (aéroport)
 * - passengerNbr <= places restantes
 * - non encore assignées
 * Les assigner au même véhicule, recalculer places restantes, répéter.
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
        double vitesseMoyenne = parametreRepository.getVitesseMoyenne(); // km/h

        // 2. Récupérer toutes les réservations pour cette date
        List<Reservation> reservations = reservationRepository.findByDate(date);

        // Checking de la validiter de la reservation
        if (reservations != null) {
            List<Reservation> values = directionX(reservations);

            // Liste des durees de chaque traject
            List<TrajetCar> val = getDureTotalTrajet(values, vitesseMoyenne);

            // for (TrajetCar trajetCar : val) {
            //     System.out.println(trajetCar.toString());
            // }

            System.out.println(" ---------------------------------------------------");
            // for (Reservation reserv : values) {
            //     System.out.println(reserv.getId() + " - " + reserv.getLieuDepart().getLibelle() + " → "
            //             + reserv.getLieuDestination().getLibelle());
            // }

            // 3. Attribution en mémoire
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

                // dateHeureDepart = arrivalDate (le véhicule part à l'heure d'arrivée du
                // client)
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
                    attribution.setReservation(reservation); // backward compat
                    attribution.addReservation(reservation); // liste regroupée
             
                    attribution.setStatut("ASSIGNE");

                    assignedIds.add(reservation.getId());

                    // ============================
                    // REGROUPEMENT (Sprint 4 DEV1)
                    // ============================
                    int placesRestantes = choisi.getNbPlace() - reservation.getPassengerNbr();

                    if (placesRestantes >= 1) {
                        // Chercher d'autres réservations compatibles à regrouper
                        for (Reservation autre : reservations) {
                            if (placesRestantes < 1)
                                break;
                            if (assignedIds.contains(autre.getId()))
                                continue;

                            // Critères de compatibilité pour regroupement :
                            // 1. Même date ET même heure de départ (arrivalDate identique)
                            if (!autre.getArrivalDate().equals(reservation.getArrivalDate()))
                                continue;
                            // 2. Même lieu de départ (aéroport)
                            if (autre.getLieuDepart() == null || reservation.getLieuDepart() == null)
                                continue;
                            if (!autre.getLieuDepart().getId().equals(reservation.getLieuDepart().getId()))
                                continue;
                            // 3. Nombre de passagers <= places restantes
                            if (autre.getPassengerNbr() > placesRestantes)
                                continue;

                            // Compatible → regrouper dans le même véhicule
                            attribution.addReservation(autre);
                            assignedIds.add(autre.getId());
                            placesRestantes -= autre.getPassengerNbr();
                        }
                    }
                    List<TrajetCar> valx = getDureTotalTrajet( attribution.getReservations() , vitesseMoyenne);
                     for (TrajetCar trajetCar : valx) {
                            System.out.println(trajetCar.toString());
                    }
                    double  dureeTotal  =  getTotalDuree( valx  )   ; 
                    double  distanceTotal  = getTotalDistance( valx  ) ; 
                    

                    attribution.setDateHeureDepart(dateHeureDepart);
                    attribution.setDistanceKm(distanceAller);
                    attribution.setDistanceAllerRetourKm( BigDecimal.valueOf(distanceTotal) );
                    attribution.setDateHeureRetour(dateHeureDepart.plusMinutes( (long) (dureeTotal*60) ));
                    for (Reservation reserv : attribution.getReservations() ) {
                        System.out.println(reserv.getId() + " - " + reserv.getLieuDepart().getLibelle() + " → "
                                + reserv.getLieuDestination().getLibelle());
                    }
                    attributions.add(attribution);
                } else {
                    nonAssignees.add(reservation);
                }
            }
            return new PlanningResult(attributions, nonAssignees);

        } else {
            System.out.println(" nulllllllllllll = 0 ");
        }
        return null;
    }


    public double getTotalDuree(List<TrajetCar> result ){
        double val  = 0.0 ;         
        for (TrajetCar trajetCar : result) {
            val += trajetCar.getDurre() ; 
        }
        return val ; 
    }

    public double getTotalDistance(List<TrajetCar> result ){
        double val  = 0.0 ;         
        for (TrajetCar trajetCar : result) {
            val += trajetCar.getDistance() ; 
        }
        return val ; 
    }

    /**
     * Récupérer la distance aller simple entre le lieu de départ et le lieu de
     * destination.
     */
    private BigDecimal getDistanceAllerSimple(Reservation reservation) throws SQLException {
        System.out.println(reservation.getLieuDepart().getId() + " ---- " + reservation.getLieuDestination().getId());
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
        return distance.getKmDistance().doubleValue();
    }


    private double getDistanceMin1(List<Reservation> reservation) throws SQLException {
        if (reservation == null) {
            throw new IllegalArgumentException("Reservation non trouvée !");
        }
        System.out.println(" result  = " + reservation);
        double min = Double.MAX_VALUE;

        for (Reservation reserv : reservation) {
            double distance = getDistanceAllerSimple(reserv).doubleValue();

            if (distance < min) {
                min = distance;
            }
        }

        return min;
    }

    /// distance par rapport lieu
    private List<Reservation> getSameOrderReservation(List<Reservation> reservation, double distanceMin)
            throws SQLException {
        if (reservation == null) {
            throw new IllegalArgumentException("Reservation non trouvée !");
        }

        List<Reservation> reservationMin = new ArrayList<>();
        double epsilon = 0.1; // Tolerance for floating-point comparison

        Iterator<Reservation> it = reservation.iterator();

        while (it.hasNext()) {
            Reservation reserv = it.next();
            double distance = getDistanceAllerSimple(reserv).doubleValue();
            System.out.println("1 - distance min = " + distanceMin + " , distance = " + distance);
            // Compare with tolerance
            if (Math.abs(distance - distanceMin) < epsilon) {
                reservationMin.add(reserv);
                System.out.println("2 - distance min = " + distanceMin + " , distance = " + distance);
                it.remove(); // Remove from original list
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

    // this function sort a reservation list by there initial string of the place
    // name
    // Dans le cas hoe mitovy tss hafa n distance entre 2 reservation dia atao sort
    // par initial string
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

    private List<TrajetCar> getDureTotalTrajet(List<Reservation> reservations, double vitessMoyenne)
            throws SQLException {
        if (reservations == null) {
            throw new IllegalArgumentException("Reservation non trouvée !");
        }
        List<TrajetCar> resultFinal = new ArrayList<>();

        Reservation firstDeparture = reservations.get(0);
        Reservation lastDeparture = reservations.get(reservations.size() - 1);
        Reservation temporary = firstDeparture;
        double distanceInitial = getDistanceLieu(firstDeparture.getLieuDestination(), firstDeparture.getLieuDepart());
        // System.out.println("Distance volohany " + " = " + distanceInitial );
        double dureeTotal = distanceInitial / vitessMoyenne;
        // System.out.println("Duree de cette trajet = " + " = " + dureeTotal );
        resultFinal.add(new TrajetCar(firstDeparture.getLieuDepart(), firstDeparture.getLieuDestination(),
                distanceInitial, dureeTotal));
        for (int i = 1; i < reservations.size(); i++) {
            double value = getDistanceLieu(temporary.getLieuDestination(), reservations.get(i).getLieuDestination());
            // System.out.println("Distance " + i + " = " + value);
            dureeTotal += value / vitessMoyenne;
            // System.out.println("Duree de cette trajet = " + i + " = " + dureeTotal);
            resultFinal.add(new TrajetCar(temporary.getLieuDestination(), reservations.get(i).getLieuDestination(),
                    value, value / vitessMoyenne));

            temporary = reservations.get(i);
        }
        double goBack = getDistanceLieu(lastDeparture.getLieuDestination(), firstDeparture.getLieuDepart());
        // System.out.println("Distance farany " + " = " + goBack);
        dureeTotal += goBack / vitessMoyenne;
        resultFinal.add(new TrajetCar(lastDeparture.getLieuDestination(), firstDeparture.getLieuDepart(), goBack,
                goBack / vitessMoyenne));

        // System.out.println("Duree de cette trajet = " + " = " + dureeTotal);
        return resultFinal;
    }

    private List<Reservation> directionX(List<Reservation> reservations) throws SQLException {
        if (reservations == null || reservations.isEmpty()) {
            return new ArrayList<>();
        }

        // Copie de travail pour ne pas modifier la liste originale
        List<Reservation> restantes = new ArrayList<>(reservations);
        List<Reservation> ordonnees = new ArrayList<>();

        // Étape 1 : trouver la réservation avec la plus petite distance DIRECTE
        double minDirect = getMinDistanceDirecte(restantes);
        List<Reservation> premieres = getReservationsAvecDistanceDirecte(restantes, minDirect);
        List<Reservation> premieresTriees = getListDistanceOrderByInitial(premieres);
        ordonnees.addAll(premieresTriees);

        if (ordonnees.isEmpty()) {
            return ordonnees;
        }

        Reservation derniere = ordonnees.get(ordonnees.size() - 1);

        // Étape 2 : construire le chemin en utilisant les distances de TRANSITION
        while (!restantes.isEmpty()) {
            double minTransition = getMinDistanceTransition(restantes, derniere.getLieuDestination());
            List<Reservation> candidates = getReservationsAvecDistanceTransition(restantes,
                    derniere.getLieuDestination(), minTransition);
            List<Reservation> candidatsTries = getListDistanceOrderByInitial(candidates);
            ordonnees.addAll(candidatsTries);

            if (!candidatsTries.isEmpty()) {
                derniere = candidatsTries.get(candidatsTries.size() - 1);
            }
        }

        return ordonnees;
    }

    // Calcule la plus petite distance DIRECTE parmi les réservations
    private double getMinDistanceDirecte(List<Reservation> reservations) throws SQLException {
        double min = Double.MAX_VALUE;
        for (Reservation r : reservations) {
            double d = getDistanceAllerSimple(r).doubleValue();
            if (d < min)
                min = d;
        }
        return min;
    }

    // Récupère toutes les réservations ayant une distance DIRECTE égale à target
    // (avec tolérance)
    private List<Reservation> getReservationsAvecDistanceDirecte(List<Reservation> reservations, double target)
            throws SQLException {
        List<Reservation> result = new ArrayList<>();
        double epsilon = 0.0001;
        Iterator<Reservation> it = reservations.iterator();
        while (it.hasNext()) {
            Reservation r = it.next();
            double d = getDistanceAllerSimple(r).doubleValue();
            if (Math.abs(d - target) < epsilon) {
                result.add(r);
                it.remove(); // On retire de la liste des restantes
            }
        }
        return result;
    }

    // Calcule la plus petite distance de TRANSITION entre un lieu et les
    // destinations des réservations
    private double getMinDistanceTransition(List<Reservation> reservations, Lieu from) throws SQLException {
        double min = Double.MAX_VALUE;
        for (Reservation r : reservations) {
            double d = getDistanceLieu(from, r.getLieuDestination());
            if (d < min)
                min = d;
        }
        return min;
    }

    // Récupère les réservations dont la distance de TRANSITION depuis 'from' est
    // égale à target
    private List<Reservation> getReservationsAvecDistanceTransition(List<Reservation> reservations, Lieu from,
            double target) throws SQLException {
        List<Reservation> result = new ArrayList<>();
        double epsilon = 0.0001;
        Iterator<Reservation> it = reservations.iterator();
        while (it.hasNext()) {
            Reservation r = it.next();
            double d = getDistanceLieu(from, r.getLieuDestination());
            if (Math.abs(d - target) < epsilon) {
                result.add(r);
                it.remove();
            }
        }
        return result;
    }

    // private List<Reservation> directionX(List<Reservation> reservation) throws
    // SQLException {
    // if (reservation == null) {
    // throw new IllegalArgumentException("Reservation non trouvée !");
    // }

    // List<Reservation> reservationOrder = new ArrayList<>();

    // double distanceMin = getDistanceMin1(reservation);
    // List<Reservation> listSameMin = getSameOrderReservation(reservation,
    // distanceMin);

    // List<Reservation> result = getListDistanceOrderByInitial(listSameMin);

    // reservationOrder.addAll(result);

    // if(result.isEmpty()){
    // return reservationOrder;
    // }

    // Reservation lastReservation = result.get(result.size() - 1);

    // while (!reservation.isEmpty()) {
    // System.out.println("resultttttt"+reservation);
    // double distance = getDistanceMin1(reservation,
    // lastReservation.getLieuDestination());
    // System.out.println( "tetttttooo ahooo faranyyy : " + distance );

    // List<Reservation> listSame = getSameOrderReservation(reservation, distance);
    // System.out.println( "tetttttooo ahooo : " +listSame );

    // List<Reservation> resultSame = getListDistanceOrderByInitial(listSame); //
    // correction
    // System.out.println( "tetttttooo ahooo : " + resultSame );

    // reservationOrder.addAll(resultSame);

    // if(!resultSame.isEmpty()){
    // lastReservation = resultSame.get(resultSame.size() - 1);
    // }
    // }

    // return reservationOrder;
    // }
    // private List<Reservation> OrderReservation(List<Reservation> reservation)
    // throws SQLException {
    // if (reservation == null) {
    // throw new IllegalArgumentException("Reservation non trouvée !");
    // }
    // List<Reservation> reservationOrder = new ArrayList<>();
    // for (Reservation reserv : reservationOrder) {

    // }

    // return distance.getKmDistance();
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
     * Vérifie la disponibilité : exclut les véhicules dont heure_retour >
     * heure_depart.
     */
    private Vehicule attribuerVehiculeEnMemoire(Reservation reservation, List<Attribution> attributionsExistantes,
            LocalDateTime dateHeureDepart) throws SQLException {
        // Chercher véhicules avec assez de places
        List<Vehicule> disponibles = vehiculeRepository.findAvailableVehicules(reservation.getPassengerNbr());

        // Exclure les véhicules pas encore revenus (heure_retour > heure_depart de la
        // réservation)
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
     * → (nb_places - passengerNbr) le plus petit → minimiser places vides
     * 2. Si plusieurs avec même écart → priorité DIESEL ('D')
     * 3. Si encore égalité (même places + même carburant) → choix aléatoire
     * (random)
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
