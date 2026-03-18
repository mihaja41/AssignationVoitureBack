package service;

import model.Attribution;
import model.Distance;
import model.FenetreRegroupement;
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
import repository.AttributionRepository;

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
import java.util.Comparator;

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
    private final AttributionRepository attributionRepository = new AttributionRepository();  // Sprint 5/6

    /**
     * Générer le planning pour une date donnée.
     * Attribution STATIQUE (en mémoire uniquement, aucune modification en base).
     *
     * Sprint 5/6 - Developer 1 (ETU003255) :
     * Implémente le regroupement avec fenêtre de temps d'attente.
     *
     * ALGORITHME :
     * 1. Charger temps_attente et vitesse_moyenne
     * 2. Récupérer les réservations triées par arrival_date ASC
     * 3. Construire les fenêtres de regroupement [start, start + temps_attente]
     * 4. Pour chaque fenêtre : traiter, reporter les non assignées vers la suivante
     * 5. Retourner les attributions et non assignées finales
     */
    public PlanningResult genererPlanning(LocalDateTime date) throws SQLException {
        // 1. Charger les paramètres
        double vitesseMoyenne = parametreRepository.getVitesseMoyenne();
        double tempsAttente = parametreRepository.getTempsAttente();

        // 2. Récupérer toutes les réservations pour cette date
        List<Reservation> reservations = reservationRepository.findByDate(date);

        if (reservations == null || reservations.isEmpty()) {
            return new PlanningResult(new ArrayList<>(), new ArrayList<>());
        }

        // 3. SPRINT 5 : Trier par arrival_date ASC (pour créer les fenêtres chronologiquement)
        List<Reservation> reservationsTriees = reservations.stream()
                .sorted(Comparator.comparing(Reservation::getArrivalDate))
                .collect(Collectors.toList());

        // 4. Construire les fenêtres de regroupement
        List<FenetreRegroupement> fenetres = construireFenetresRegroupement(reservationsTriees, tempsAttente);

        // 5. Traiter chaque fenêtre
        List<Attribution> toutesAttributions = new ArrayList<>();
        List<Reservation> aReporter = new ArrayList<>();

        for (int i = 0; i < fenetres.size(); i++) {
            FenetreRegroupement fenetre = fenetres.get(i);

            // Ajouter les réservations reportées de la fenêtre précédente
            if (!aReporter.isEmpty()) {
                fenetre.addAllReservations(aReporter);
                fenetre.setHeureDepart(fenetre.calculerHeureDepart());
                aReporter.clear();
            }

            // Traiter la fenêtre (utilise la logique existante)
            PlanningResult resultatFenetre = traiterFenetre(fenetre, toutesAttributions, vitesseMoyenne);

            // Collecter les attributions
            toutesAttributions.addAll(resultatFenetre.getAttributions());

            // Reporter les non assignées vers la prochaine fenêtre
            List<Reservation> nonAssigneesFenetre = resultatFenetre.getReservationsNonAssignees();
            if (!nonAssigneesFenetre.isEmpty() && i < fenetres.size() - 1) {
                aReporter.addAll(nonAssigneesFenetre);
            } else {
                aReporter.addAll(nonAssigneesFenetre);
            }
        }

        // Les réservations qui restent dans aReporter sont les non assignées finales
        return new PlanningResult(toutesAttributions, aReporter);
    }

    /**
     * Générer le planning ET enregistrer les attributions en base de données.
     * Sprint 5/6 - Developer 2 (ETU003283)
     *
     * Cette méthode appelle genererPlanning() puis sauvegarde toutes les
     * attributions dans la table attribution.
     *
     * @param date La date pour laquelle générer le planning
     * @return PlanningResult avec les attributions (maintenant persistées)
     */
    public PlanningResult genererPlanningAvecEnregistrement(LocalDateTime date) throws SQLException {
        // 1. Générer le planning en mémoire
        PlanningResult result = genererPlanning(date);

        // 2. Enregistrer chaque attribution en base
        for (Attribution attribution : result.getAttributions()) {
            attributionRepository.saveAll(attribution);
        }

        return result;
    }

    // ============================================================================
    // MÉTHODES DEVELOPER 1 (ETU003255) - SPRINT 5/6
    // Gestion des fenêtres de regroupement et du temps d'attente
    // ============================================================================

    /**
     * Construit les fenêtres de regroupement à partir des réservations.
     * Sprint 5 - Developer 1 (ETU003255)
     *
     * @param reservations Liste des réservations triées par arrival_date ASC
     * @param tempsAttenteMinutes Temps d'attente en minutes
     * @return Liste des fenêtres de regroupement
     */
    private List<FenetreRegroupement> construireFenetresRegroupement(
            List<Reservation> reservations,
            double tempsAttenteMinutes) {

        List<FenetreRegroupement> fenetres = new ArrayList<>();

        if (reservations == null || reservations.isEmpty()) {
            return fenetres;
        }

        List<Reservation> restantes = new ArrayList<>(reservations);

        while (!restantes.isEmpty()) {
            Reservation premiere = restantes.get(0);
            LocalDateTime startTime = premiere.getArrivalDate();
            LocalDateTime endTime = startTime.plusMinutes((long) tempsAttenteMinutes);

            FenetreRegroupement fenetre = new FenetreRegroupement(startTime, endTime);

            // Collecter les réservations dans cette fenêtre
            Iterator<Reservation> iterator = restantes.iterator();
            while (iterator.hasNext()) {
                Reservation r = iterator.next();
                if (fenetre.estDansFenetre(r.getArrivalDate())) {
                    fenetre.addReservation(r);
                    iterator.remove();
                }
            }

            fenetre.setHeureDepart(fenetre.calculerHeureDepart());
            fenetres.add(fenetre);
        }

        return fenetres;
    }

    /**
     * Traite une fenêtre de regroupement.
     * Sprint 5 - Developer 1 (ETU003255)
     *
     * Cette méthode prépare les données et appelle la logique d'assignation.
     * Le Developer 2 améliorera la partie sélection de véhicules.
     */
    private PlanningResult traiterFenetre(
            FenetreRegroupement fenetre,
            List<Attribution> attributionsExistantes,
            double vitesseMoyenne) throws SQLException {

        List<Attribution> attributionsFenetre = new ArrayList<>();
        List<Reservation> nonAssigneesFenetre = new ArrayList<>();
        Set<Long> assignedIds = new HashSet<>();

        // Récupérer l'heure de départ de la fenêtre (tous les véhicules partent ensemble)
        LocalDateTime heureDepart = fenetre.getHeureDepart();

        // Validation : l'heure de départ doit être dans la fenêtre
        if (!fenetre.estDansFenetre(heureDepart)) {
            heureDepart = fenetre.getStartTime();
        }

        // Trier par passagers décroissant pour le regroupement optimal
        List<Reservation> reservationsTriees = fenetre.getReservationsTrieesParPassagers();

        for (Reservation reservation : reservationsTriees) {
            if (assignedIds.contains(reservation.getId())) {
                continue;
            }

            BigDecimal distanceAller = getDistanceAllerSimple(reservation);
            if (distanceAller == null) {
                nonAssigneesFenetre.add(reservation);
                continue;
            }

            // Utiliser la logique existante d'assignation
            Attribution meilleureAttribution = trouverMeilleureAttributionAvecRegroupement(
                    reservation, reservationsTriees, assignedIds,
                    attributionsExistantes, heureDepart, vitesseMoyenne);

            if (meilleureAttribution != null) {
                for (Reservation r : meilleureAttribution.getReservations()) {
                    assignedIds.add(r.getId());
                }

                List<TrajetCar> trajets = getDureTotalTrajet(
                        meilleureAttribution.getReservations(), vitesseMoyenne);
                double dureeTotale = getTotalDuree(trajets);
                double distanceTotale = getTotalDistance(trajets);

                meilleureAttribution.setDetailTraject(trajets);
                meilleureAttribution.setDateHeureDepart(heureDepart);
                meilleureAttribution.setDistanceKm(distanceAller);
                meilleureAttribution.setDistanceAllerRetourKm(BigDecimal.valueOf(distanceTotale));
                meilleureAttribution.setDateHeureRetour(heureDepart.plusMinutes((long) (dureeTotale * 60)));

                attributionsFenetre.add(meilleureAttribution);
            } else {
                nonAssigneesFenetre.add(reservation);
            }
        }

        // ⭐ VALIDATION CRITIQUE : Un départ n'est valide que s'il existe AU MOINS UNE réservation assignée
        // Sprint 5/6 - Developer 1 (ETU003255)
        if (!attributionsFenetre.isEmpty()) {
            // Vérifier que l'heure de départ est valide (au moins 1 attribution existe)
            LocalDateTime heureDepartValidee = validerHeureDepartCritique(attributionsFenetre, fenetre);

            // Mettre à jour toutes les attributions avec l'heure de départ validée
            for (Attribution attribution : attributionsFenetre) {
                if (!attribution.getDateHeureDepart().equals(heureDepartValidee)) {
                    // Recalculer l'heure de retour avec la nouvelle heure de départ
                    long dureeMinutes = java.time.Duration.between(
                            attribution.getDateHeureDepart(),
                            attribution.getDateHeureRetour()).toMinutes();
                    attribution.setDateHeureDepart(heureDepartValidee);
                    attribution.setDateHeureRetour(heureDepartValidee.plusMinutes(dureeMinutes));
                }
            }
        }

        return new PlanningResult(attributionsFenetre, nonAssigneesFenetre);
    }

    /**
     * Valide l'heure de départ critique.
     * Sprint 5/6 - Developer 1 (ETU003255)
     *
     * Un départ n'est VALIDE que s'il existe AU MOINS UNE réservation assignée.
     * Retourne l'heure de départ validée.
     *
     * @param attributions Liste des attributions de la fenêtre
     * @param fenetre La fenêtre de regroupement
     * @return L'heure de départ validée
     */
    private LocalDateTime validerHeureDepartCritique(
            List<Attribution> attributions,
            FenetreRegroupement fenetre) {

        if (attributions == null || attributions.isEmpty()) {
            // Pas d'attribution = pas de départ valide
            return fenetre.getHeureDepart();
        }

        // Trouver le MAX(arrival_date) parmi les réservations ASSIGNÉES
        LocalDateTime maxArrivalAssignee = null;

        for (Attribution attribution : attributions) {
            for (Reservation reservation : attribution.getReservations()) {
                LocalDateTime arrivalDate = reservation.getArrivalDate();
                if (maxArrivalAssignee == null || arrivalDate.isAfter(maxArrivalAssignee)) {
                    maxArrivalAssignee = arrivalDate;
                }
            }
        }

        if (maxArrivalAssignee == null) {
            return fenetre.getHeureDepart();
        }

        // Vérifier que l'heure est dans la fenêtre
        if (!fenetre.estDansFenetre(maxArrivalAssignee)) {
            // Forcer à MAX(arrival_date) de la fenêtre
            return fenetre.calculerHeureDepart();
        }

        return maxArrivalAssignee;
    }

    // ============================================================================
    // MÉTHODES DEVELOPER 2 (ETU003283) - SPRINT 5/6
    // Gestion des véhicules, sélection optimale, enregistrement en base
    // ============================================================================

    /**
     * Trouve la meilleure attribution avec regroupement.
     * Sprint 5/6 - Developer 2 (ETU003283)
     *
     * Critères de sélection (dans l'ordre) :
     * 1. Capacité suffisante (nb_places >= passagers)
     * 2. Disponibilité (pas de conflit horaire OU revient dans la fenêtre)
     * 3. Écart minimum (places - passagers)
     * 4. Équilibrage (moins de trajets effectués = prioritaire)
     * 5. Priorité DIESEL
     * 6. Choix aléatoire si égalité
     */
    private Attribution trouverMeilleureAttributionAvecRegroupement(
            Reservation reservationPrincipale,
            List<Reservation> toutesReservations,
            Set<Long> assignedIds,
            List<Attribution> attributionsExistantes,
            LocalDateTime dateHeureDepart,
            double vitesseMoyenne) throws SQLException {

        // 1. Récupérer tous les véhicules
        List<Vehicule> tousVehicules = vehiculeRepository.findAvailableVehicules(1);

        // 2. Récupérer le nombre de trajets par véhicule (pour équilibrage)
        Map<Long, Integer> trajetsParVehicule = attributionRepository.countTrajetsParVehicule();

        // 3. Filtrer les véhicules disponibles
        List<Vehicule> vehiculesDisponibles = new ArrayList<>();
        Map<Long, LocalDateTime> heuresRetourVehicules = new HashMap<>();

        for (Vehicule vehicule : tousVehicules) {
            // Vérifier capacité minimale
            if (vehicule.getNbPlace() < reservationPrincipale.getPassengerNbr()) {
                continue;
            }

            // Vérifier disponibilité
            if (!hasConflitHoraire(vehicule.getId(), dateHeureDepart, attributionsExistantes)) {
                // Véhicule directement disponible
                vehiculesDisponibles.add(vehicule);
            } else {
                // Vérifier si le véhicule revient DANS la fenêtre
                LocalDateTime heureRetour = getHeureRetourVehicule(vehicule.getId(), attributionsExistantes);
                if (heureRetour != null && !heureRetour.isAfter(dateHeureDepart)) {
                    vehiculesDisponibles.add(vehicule);
                    heuresRetourVehicules.put(vehicule.getId(), heureRetour);
                }
            }
        }

        if (vehiculesDisponibles.isEmpty()) {
            return null;
        }

        // 4. Trouver les réservations compatibles pour le regroupement
        List<Reservation> compatibles = trouverReservationsCompatibles(
                reservationPrincipale, toutesReservations, assignedIds);

        // 5. Évaluer chaque véhicule et trouver le meilleur
        Attribution meilleureAttribution = null;
        int meilleurScore = Integer.MAX_VALUE;

        for (Vehicule vehicule : vehiculesDisponibles) {
            int placesDisponibles = vehicule.getNbPlace();
            List<Reservation> reservationsGroupees = new ArrayList<>();
            reservationsGroupees.add(reservationPrincipale);
            placesDisponibles -= reservationPrincipale.getPassengerNbr();

            // Regrouper d'autres réservations compatibles
            for (Reservation compatible : compatibles) {
                if (compatible.getPassengerNbr() <= placesDisponibles) {
                    reservationsGroupees.add(compatible);
                    placesDisponibles -= compatible.getPassengerNbr();
                }
            }

            // Calculer le score avec les nouveaux critères
            int nbTrajets = trajetsParVehicule.getOrDefault(vehicule.getId(), 0);
            int score = evaluerAttributionAvecEquilibrage(vehicule, reservationsGroupees, nbTrajets);

            if (score < meilleurScore) {
                meilleurScore = score;

                Attribution attribution = new Attribution();
                attribution.setVehicule(vehicule);
                attribution.setReservation(reservationPrincipale);
                for (Reservation r : reservationsGroupees) {
                    attribution.addReservation(r);
                }
                attribution.setStatut("ASSIGNE");

                // Gérer l'heure de départ pour véhicule revenant
                LocalDateTime heureRetourVehicule = heuresRetourVehicules.get(vehicule.getId());
                if (heureRetourVehicule != null && heureRetourVehicule.isAfter(dateHeureDepart)) {
                    // CAS 1: heure_retour > MAX(arrival_date) → départ = heure_retour
                    attribution.setDateHeureDepart(heureRetourVehicule);
                }

                meilleureAttribution = attribution;
            }
        }

        return meilleureAttribution;
    }

    /**
     * Récupère l'heure de retour d'un véhicule depuis les attributions existantes.
     */
    private LocalDateTime getHeureRetourVehicule(Long vehiculeId, List<Attribution> attributions) {
        return attributions.stream()
                .filter(a -> a.getVehicule().getId().equals(vehiculeId))
                .map(Attribution::getDateHeureRetour)
                .max(LocalDateTime::compareTo)
                .orElse(null);
    }

    /**
     * Évaluation du score avec équilibrage par nombre de trajets.
     * Sprint 5/6 - Developer 2 (ETU003283)
     *
     * Score plus bas = meilleure attribution
     * Critères :
     * 1. Écart places (pondération forte)
     * 2. Nombre de trajets effectués (équilibrage)
     * 3. Priorité DIESEL
     */
    private int evaluerAttributionAvecEquilibrage(Vehicule vehicule, List<Reservation> reservations, int nbTrajets) {
        int totalPassagers = reservations.stream()
                .mapToInt(Reservation::getPassengerNbr)
                .sum();

        // Critère 1: Minimiser les places vides (pondération x100)
        int placesVides = vehicule.getNbPlace() - totalPassagers;
        int score = placesVides * 100;

        // Critère 2: Équilibrage - moins de trajets = meilleur (pondération x10)
        score += nbTrajets * 10;

        // Critère 3: Priorité DIESEL uniquement
        if (vehicule.getTypeCarburant() != TypeCarburant.D) {
            score += 5;
        }

        // Critère 4: Maximiser le nombre de passagers transportés (bonus)
        score -= totalPassagers;

        return score;
    }

/**
 * SPRINT 5/6 : Trouver toutes les réservations compatibles pour regroupement INTRA-FENÊTRE.
 *
 * Les réservations dans toutesReservations sont DÉJÀ dans la même fenêtre de temps,
 * donc on ne filtre PAS sur arrival_date exacte mais sur :
 * - Non assignée
 * - Pas la réservation principale
 * - Même lieu de départ
 * - Triées par passagers décroissant (pour optimiser le remplissage)
 */
private List<Reservation> trouverReservationsCompatibles(
        Reservation reservationPrincipale,
        List<Reservation> toutesReservations,
        Set<Long> assignedIds) {

    return toutesReservations.stream()
            .filter(r -> !assignedIds.contains(r.getId()))
            .filter(r -> !r.getId().equals(reservationPrincipale.getId()))
            // SPRINT 5/6 : PAS de filtre sur arrival_date exacte car les réservations
            // sont déjà dans la même fenêtre [start_time, end_time]
            .filter(r -> r.getLieuDepart() != null && reservationPrincipale.getLieuDepart() != null)
            .filter(r -> r.getLieuDepart().getId().equals(reservationPrincipale.getLieuDepart().getId()))
            .sorted((r1, r2) -> Integer.compare(r2.getPassengerNbr(), r1.getPassengerNbr())) // Trier par taille décroissante
            .collect(Collectors.toList());
}

/**
 * AMÉLIORATION 5: Évaluation du score d'une attribution
 * Score plus bas = meilleure attribution
 */
private int evaluerAttribution(Vehicule vehicule, List<Reservation> reservations) {
    int totalPassagers = reservations.stream()
            .mapToInt(Reservation::getPassengerNbr)
            .sum();
    
    // Critère 1: Minimiser les places vides (pondération forte)
    int placesVides = vehicule.getNbPlace() - totalPassagers;
    int score = placesVides * 10;
    
    // Critère 2: Privilégier le Diesel (pondération moyenne)
    if (vehicule.getTypeCarburant() != TypeCarburant.D) {
        score += 5; // Pénalité pour non-Diesel
    }
    
    // Critère 3: Maximiser le nombre de passagers transportés (bonus)
    score -= totalPassagers; // Bonus pour transporter plus de monde
    
    return score;
}

/**
 * AMÉLIORATION 6: Version améliorée de choisirVehicule avec calcul d'écart réel
 */
private Vehicule choisirVehiculeOptimise(List<Vehicule> disponibles, int passengerNbr) {
    // Calculer l'écart pour chaque véhicule
    Map<Vehicule, Integer> ecarts = new HashMap<>();
    for (Vehicule v : disponibles) {
        ecarts.put(v, v.getNbPlace() - passengerNbr);
    }
    
    // Trouver l'écart minimum
    int ecartMin = ecarts.values().stream()
            .mapToInt(Integer::intValue)
            .min()
            .orElse(Integer.MAX_VALUE);
    
    // Garder les véhicules avec l'écart minimum
    List<Vehicule> meilleurs = disponibles.stream()
            .filter(v -> (v.getNbPlace() - passengerNbr) == ecartMin)
            .collect(Collectors.toList());
    
    if (meilleurs.size() == 1) {
        return meilleurs.get(0);
    }
    
    // Priorité Diesel
    List<Vehicule> diesels = meilleurs.stream()
            .filter(v -> v.getTypeCarburant() == TypeCarburant.D)
            .collect(Collectors.toList());
    
    if (!diesels.isEmpty()) {
        Collections.shuffle(diesels);
        return diesels.get(0);
    }
    
    // Random parmi les meilleurs
    Collections.shuffle(meilleurs);
    return meilleurs.get(0);
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

        if ( lieuDepart.getId() == lieuDestination.getId() ) {
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

    // fonction
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
