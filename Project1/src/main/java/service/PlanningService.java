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
 * Sprint 5 – Regroupement avec temps d'attente :
 *
 * ALGORITHME :
 * 1. Récupérer toutes les réservations d'une date donnée, triées par arrival_date ASC
 * 2. Pour chaque première réservation non traitée, créer une FENÊTRE DE REGROUPEMENT :
 *    - start_time = arrival_date
 *    - end_time = arrival_date + temps_attente (paramètre en minutes)
 * 3. Collecter toutes les réservations dans cette fenêtre :
 *    - arrival_date >= start_time AND arrival_date <= end_time
 * 4. heure_depart = MAX(arrival_date) de la fenêtre (tous véhicules partent ensemble)
 * 5. Trier les réservations de la fenêtre par passagers DÉCROISSANT
 * 6. Pour chaque réservation de la fenêtre :
 *    a. Chercher véhicules avec nb_places >= passengerNbr
 *    b. Exclure si heure_retour > heure_depart
 *    c. Choisir : minimiser écart places, priorité Diesel, sinon random
 *    d. REGROUPEMENT INTRA-FENÊTRE : si places restantes >= 1, ajouter d'autres
 *       réservations de la même fenêtre :
 *       - même lieu de départ
 *       - passengerNbr <= places_restantes
 * 7. heure_retour = heure_depart + temps_trajet
 * 8. Répéter avec la prochaine fenêtre (réservations non encore traitées)
 */
public class PlanningService {

    private final ReservationRepository reservationRepository = new ReservationRepository();
    private final VehiculeRepository vehiculeRepository = new VehiculeRepository();
    private final DistanceRepository distanceRepository = new DistanceRepository();
    private final ParametreRepository parametreRepository = new ParametreRepository();

    /**
     * Générer le planning pour une date donnée.
     * Attribution STATIQUE (en mémoire uniquement, aucune modification en base).
     * Sprint 5 : Implémente le regroupement avec fenêtre de temps d'attente.
     */
    public PlanningResult genererPlanning(LocalDateTime date) throws SQLException {

        // 1. Charger les paramètres
        double vitesseMoyenne = parametreRepository.getVitesseMoyenne(); // km/h
        double tempsAttenteMinutes = parametreRepository.getTempsAttente(); // minutes

        // 2. Récupérer toutes les réservations pour cette date (triées par arrival_date ASC)
        List<Reservation> reservations = reservationRepository.findByDate(date);

        if (reservations == null || reservations.isEmpty()) {
            System.out.println("Aucune réservation pour cette date");
            return new PlanningResult(new ArrayList<>(), new ArrayList<>());
        }

        // 3. Attribution en mémoire avec fenêtres de regroupement
        List<Attribution> attributions = new ArrayList<>();
        List<Reservation> nonAssignees = new ArrayList<>();
        Set<Long> assignedIds = new HashSet<>();

        // Parcourir les réservations et créer des fenêtres de regroupement
        for (Reservation premiereReservation : reservations) {
            // Sauter si déjà traitée
            if (assignedIds.contains(premiereReservation.getId())) {
                continue;
            }

            // ============================
            // CRÉER LA FENÊTRE DE REGROUPEMENT
            // ============================
            LocalDateTime startTime = premiereReservation.getArrivalDate();
            LocalDateTime endTime = startTime.plusMinutes((long) tempsAttenteMinutes);

            // Collecter toutes les réservations dans cette fenêtre
            List<Reservation> reservationsDansFenetre = new ArrayList<>();
            for (Reservation r : reservations) {
                if (assignedIds.contains(r.getId())) {
                    continue;
                }
                // arrival_date >= start_time AND arrival_date <= end_time
                if (!r.getArrivalDate().isBefore(startTime) && !r.getArrivalDate().isAfter(endTime)) {
                    reservationsDansFenetre.add(r);
                }
            }

            if (reservationsDansFenetre.isEmpty()) {
                continue;
            }

            // ============================
            // CALCUL DE L'HEURE DE DÉPART
            // ============================
            // heure_depart = MAX(arrival_date) de la fenêtre
            LocalDateTime heureDepart = reservationsDansFenetre.stream()
                    .map(Reservation::getArrivalDate)
                    .max(LocalDateTime::compareTo)
                    .orElse(startTime);

            System.out.println("=== FENÊTRE DE REGROUPEMENT ===");
            System.out.println("start_time: " + startTime + " | end_time: " + endTime);
            System.out.println("heure_depart (MAX): " + heureDepart);
            System.out.println("Réservations dans fenêtre: " + reservationsDansFenetre.size());

            // Trier par nombre de passagers DÉCROISSANT
            reservationsDansFenetre.sort((r1, r2) -> Integer.compare(r2.getPassengerNbr(), r1.getPassengerNbr()));

            // Marquer comme "en cours de traitement" (pour ne pas les reprendre dans une autre fenêtre)
            Set<Long> idsDansFenetre = new HashSet<>();
            for (Reservation r : reservationsDansFenetre) {
                idsDansFenetre.add(r.getId());
            }

            // ============================
            // ATTRIBUTION DES VÉHICULES POUR CETTE FENÊTRE
            // ============================
            for (Reservation reservation : reservationsDansFenetre) {
                if (assignedIds.contains(reservation.getId())) {
                    continue;
                }

                // Calculer la distance aller simple
                BigDecimal distanceAller = getDistanceAllerSimple(reservation);
                if (distanceAller == null) {
                    nonAssignees.add(reservation);
                    assignedIds.add(reservation.getId());
                    continue;
                }

                // Chercher le meilleur véhicule disponible
                Vehicule choisi = attribuerVehiculeEnMemoire(reservation, attributions, heureDepart);

                if (choisi != null) {
                    // Créer l'attribution
                    Attribution attribution = new Attribution();
                    attribution.setVehicule(choisi);
                    attribution.setReservation(reservation);
                    attribution.addReservation(reservation);
                    attribution.setStatut("ASSIGNE");
                    assignedIds.add(reservation.getId());

                    // ============================
                    // REGROUPEMENT INTRA-FENÊTRE
                    // ============================
                    int placesRestantes = choisi.getNbPlace() - reservation.getPassengerNbr();

                    if (placesRestantes >= 1) {
                        // Chercher d'autres réservations compatibles DANS LA MÊME FENÊTRE
                        for (Reservation autre : reservationsDansFenetre) {
                            if (placesRestantes < 1)
                                break;
                            if (assignedIds.contains(autre.getId()))
                                continue;

                            // Critères de compatibilité :
                            // 1. Même lieu de départ
                            if (autre.getLieuDepart() == null || reservation.getLieuDepart() == null)
                                continue;
                            if (!autre.getLieuDepart().getId().equals(reservation.getLieuDepart().getId()))
                                continue;
                            // 2. Nombre de passagers <= places restantes
                            if (autre.getPassengerNbr() > placesRestantes)
                                continue;

                            // Compatible → regrouper dans le même véhicule
                            attribution.addReservation(autre);
                            assignedIds.add(autre.getId());
                            placesRestantes -= autre.getPassengerNbr();
                        }
                    }

                    // Recalculer les trajets avec les réservations regroupées
                    List<Reservation> reservationsGroupees = directionX(attribution.getReservations());
                    List<TrajetCar> trajets = getDureTotalTrajet(reservationsGroupees, vitesseMoyenne);
                    
                    double dureeTotal = getTotalDuree(trajets);
                    double distanceTotal = getTotalDistance(trajets);

                    attribution.setDetailTraject(trajets);
                    attribution.setDateHeureDepart(heureDepart); // Tous partent à MAX(arrival_date)
                    attribution.setDistanceKm(distanceAller);
                    attribution.setDistanceAllerRetourKm(BigDecimal.valueOf(distanceTotal));
                    attribution.setDateHeureRetour(heureDepart.plusMinutes((long) (dureeTotal * 60)));

                    System.out.println("Attribution véhicule " + choisi.getReference() + 
                                       " | Réservations: " + attribution.getReservations().size() +
                                       " | Passagers: " + attribution.getTotalPassengers() +
                                       " | Départ: " + heureDepart + " | Retour: " + attribution.getDateHeureRetour());

                    attributions.add(attribution);
                } else {
                    nonAssignees.add(reservation);
                    assignedIds.add(reservation.getId());
                }
            }
        }

        return new PlanningResult(attributions, nonAssignees);
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
