package service;

import model.Attribution;
import model.Distance;
import model.FenetreRegroupement;
import model.Reservation;
import model.ReservationPartielle;
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
 *  sprint 7 – Optimisation de l'algorithme d'assignation et disponibilité véhicule.
 *
 * CORRECTIONS  sprint 7 :
 * FIX 1 : Réservations partielles reportées ajoutées directement à la fenêtre suivante
 *          sans filtrage par arrivalDate (qui serait hors fenêtre).
 * FIX 2 : L'heure de départ tient compte du retour réel des véhicules précédents,
 *          sans être écrasée par validerHeureDepartCritique.
 * FIX 3 : Score calculé sur passagers réellement assignés (totalPassagersGroupes).
 * FIX 4 : Accepte tous les véhicules avec >= 1 place.
 * FIX 5 : Après trouverMeilleureAttributionAvecRegroupement, si la réservation principale
 *          n'est que partiellement assignée, créer une ReservationPartielle pour le reste.
 * FIX 6 : trouverMeilleureAttributionAvecDivision utilise passagersDejaAssignes initiaux
 *          pour calculer passagersRestants correctement.
 */
public class PlanningService {

    private final ReservationRepository reservationRepository = new ReservationRepository();
    private final VehiculeRepository vehiculeRepository = new VehiculeRepository();
    private final DistanceRepository distanceRepository = new DistanceRepository();
    private final ParametreRepository parametreRepository = new ParametreRepository();
    private final AttributionRepository attributionRepository = new AttributionRepository();

    // ============================================================================
    // MÉTHODE PRINCIPALE
    // ============================================================================

    /**
     * SPRINT 8: Génère le planning basé sur les retours de véhicules.
     *
     * Algorithme:
     * 1. Construire les fenêtres basées sur les retours de véhicules
     * 2. Pour chaque fenêtre:
     *    - Traiter les réservations prioritaires (arrivées avant le début de la fenêtre)
     *    - Trier par passagers décroissant
     *    - Sélectionner le véhicule optimal
     *    - Fenêtre d'attente dynamique pour remplir les véhicules non pleins
     */
    public PlanningResult genererPlanning(LocalDateTime date) throws SQLException {
        double vitesseMoyenne = parametreRepository.getVitesseMoyenne();
        double tempsAttente = parametreRepository.getTempsAttente();

        List<Reservation> reservations = reservationRepository.findByDate(date);
        if (reservations == null || reservations.isEmpty()) {
            return new PlanningResult(new ArrayList<>(), new ArrayList<>());
        }

        List<Reservation> reservationsTriees = reservations.stream()
                .sorted(Comparator.comparing(Reservation::getArrivalDate))
                .collect(Collectors.toList());

        List<Attribution> toutesAttributions = new ArrayList<>();
        List<ReservationPartielle> toutesPartielles = new ArrayList<>();
        Set<Long> globalAssignedReservationIds = new HashSet<>();
        Map<Long, Integer> trajetsSessionParVehicule = new HashMap<>();
        Map<Long, Integer> passagersDejaAssignes = new HashMap<>();

        // SPRINT 8: Gérer les réservations non assignées entre les fenêtres
        List<Reservation> reservationsNonAssignees = new ArrayList<>(reservationsTriees);
        Set<String> fenetresTraitees = new HashSet<>();
        int gardeFouIterations = 0;

        while (gardeFouIterations++ < 1000) {
            reservationsNonAssignees.removeIf(r -> globalAssignedReservationIds.contains(r.getId()));
            if (reservationsNonAssignees.isEmpty()) break;

            // Fenêtres basées sur retours (recalculées dynamiquement à chaque tour)
            List<FenetreSprint8> fenetresSprint8 = construireFenetresBaseesSurRetourVehicules(
                    date, reservationsTriees, tempsAttente, toutesAttributions);

            fenetresSprint8.sort(Comparator.comparing(FenetreSprint8::getStartTime));
            FenetreSprint8 prochaineFenetreRetour = fenetresSprint8.stream()
                    .filter(f -> !fenetresTraitees.contains(buildFenetreKey(f)))
                    .findFirst()
                    .orElse(null);

            Reservation prochaineNonAssignee = reservationsNonAssignees.stream()
                    .filter(r -> r.getArrivalDate() != null)
                    .min(Comparator.comparing(Reservation::getArrivalDate))
                    .orElse(null);

            FenetreSprint8 fenetreATraiter = null;
            String fenetreKey = null;

            // Point 5 Sprint 8: fenêtre issue d'une arrivée de réservation non assignée
            if (prochaineNonAssignee != null) {
                LocalDateTime debutResa = prochaineNonAssignee.getArrivalDate();
                boolean avantProchainRetour = (prochaineFenetreRetour == null)
                        || debutResa.isBefore(prochaineFenetreRetour.getStartTime());

                if (avantProchainRetour) {
                    List<Vehicule> vehiculesDispo = getVehiculesDisponiblesAInstant(debutResa, toutesAttributions);
                    FenetreSprint8 fenetreArrivee = new FenetreSprint8(
                            debutResa,
                            debutResa.plusMinutes((long) tempsAttente),
                            TypeFenetreSprint8.ARRIVEE_NON_ASSIGNEE);
                    for (Vehicule v : vehiculesDispo) {
                        fenetreArrivee.addVehicule(v, debutResa);
                    }
                    ajouterVehiculesRetournantDansIntervalle(
                            fenetreArrivee, debutResa, fenetreArrivee.getEndTime(), toutesAttributions);

                    if (!fenetreArrivee.getVehiculesDisponibles().isEmpty()) {
                        fenetreATraiter = fenetreArrivee;
                        fenetreKey = buildFenetreKey(fenetreArrivee) + "_arrival";
                    }
                }
            }

            if (fenetreATraiter == null && prochaineFenetreRetour != null) {
                fenetreATraiter = prochaineFenetreRetour;
                fenetreKey = buildFenetreKey(prochaineFenetreRetour);
            }

            if (fenetreATraiter == null) {
                break;
            }

            fenetresTraitees.add(fenetreKey);

            PlanningResult resultatFenetre = traiterFenetreSprint8(
                    fenetreATraiter,
                    reservationsTriees,
                    reservationsNonAssignees,
                    toutesAttributions,
                    vitesseMoyenne,
                    tempsAttente,
                    trajetsSessionParVehicule,
                    passagersDejaAssignes,
                    globalAssignedReservationIds);

            globalAssignedReservationIds.addAll(resultatFenetre.getReservationIdsCompletementAssignees());
            toutesPartielles.addAll(resultatFenetre.getReservationsPartielles());

            // Ajouter les partielles aux non assignées pour les tours suivants
            for (ReservationPartielle rp : resultatFenetre.getReservationsPartielles()) {
                Reservation resteReservation = rp.creerReservationPourFenetresuivante();
                reservationsNonAssignees.add(resteReservation);
            }
        }

        // Déduplication : clé = vehicule_id + heure_depart
        List<Attribution> finalAttributions = new java.util.ArrayList<>();
        Set<String> seenKeys = new java.util.HashSet<>();
        for (Attribution attr : toutesAttributions) {
            if (attr.getVehicule() != null && attr.getDateHeureDepart() != null) {
                String key = attr.getVehicule().getId() + "_" + attr.getDateHeureDepart().toString();
                if (seenKeys.add(key)) {
                    finalAttributions.add(attr);
                }
            } else {
                finalAttributions.add(attr);
            }
        }

        // Collecter les réservations non assignées restantes
        List<Reservation> nonAssigneesFinales = new ArrayList<>();
        for (Reservation r : reservationsNonAssignees) {
            if (!globalAssignedReservationIds.contains(r.getId())) {
                nonAssigneesFinales.add(r);
            }
        }

        return new PlanningResult(finalAttributions, nonAssigneesFinales, toutesPartielles);
    }

    public PlanningResult genererPlanningAvecEnregistrement(LocalDateTime date) throws SQLException {
        PlanningResult result = genererPlanning(date);
        for (Attribution attribution : result.getAttributions()) {
            attributionRepository.saveAll(attribution);
        }
        return result;
    }

    // ============================================================================
    // CONSTRUCTION DES FENÊTRES
    // ============================================================================

    private List<FenetreRegroupement> construireFenetresRegroupement(
            List<Reservation> reservations,
            double tempsAttenteMinutes) {

        List<FenetreRegroupement> fenetres = new ArrayList<>();
        if (reservations == null || reservations.isEmpty()) return fenetres;

        List<Reservation> restantes = new ArrayList<>(reservations);

        while (!restantes.isEmpty()) {
            Reservation premiere = restantes.get(0);
            LocalDateTime startTime = premiere.getArrivalDate();
            LocalDateTime endTime = startTime.plusMinutes((long) tempsAttenteMinutes);

            FenetreRegroupement fenetre = new FenetreRegroupement(startTime, endTime);

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
     * SPRINT 8: Classe interne pour représenter un événement de disponibilité de véhicule.
     */
    private static class VehicleAvailabilityEvent {
        private final Vehicule vehicule;
        private final LocalDateTime availableAt;

        public VehicleAvailabilityEvent(Vehicule vehicule, LocalDateTime availableAt) {
            this.vehicule = vehicule;
            this.availableAt = availableAt;
        }

        public Vehicule getVehicule() { return vehicule; }
        public LocalDateTime getAvailableAt() { return availableAt; }
    }

    private enum TypeFenetreSprint8 {
        RETOUR_VEHICULE,
        ARRIVEE_NON_ASSIGNEE
    }

    /**
     * SPRINT 8: Classe interne pour une fenêtre avec véhicules disponibles.
     */
    private static class FenetreSprint8 {
        private final FenetreRegroupement fenetre;
        private final TypeFenetreSprint8 typeFenetre;
        private final List<Vehicule> vehiculesDisponibles;
        private final Map<Long, LocalDateTime> disponibiliteParVehicule;

        public FenetreSprint8(LocalDateTime startTime, LocalDateTime endTime, TypeFenetreSprint8 typeFenetre) {
            this.fenetre = new FenetreRegroupement(startTime, endTime);
            this.typeFenetre = typeFenetre;
            this.vehiculesDisponibles = new ArrayList<>();
            this.disponibiliteParVehicule = new HashMap<>();
        }

        public FenetreRegroupement getFenetre() { return fenetre; }
        public TypeFenetreSprint8 getTypeFenetre() { return typeFenetre; }
        public List<Vehicule> getVehiculesDisponibles() { return vehiculesDisponibles; }
        public void addVehicule(Vehicule v, LocalDateTime availableAt) {
            if (v == null || v.getId() == null) return;
            if (availableAt == null) availableAt = fenetre.getStartTime();
            LocalDateTime old = disponibiliteParVehicule.get(v.getId());
            if (old == null || availableAt.isBefore(old)) {
                disponibiliteParVehicule.put(v.getId(), availableAt);
            }
            boolean dejaPresent = vehiculesDisponibles.stream()
                    .anyMatch(existing -> existing != null
                            && existing.getId() != null
                            && existing.getId().equals(v.getId()));
            if (!dejaPresent) {
                vehiculesDisponibles.add(v);
            }
        }
        public LocalDateTime getDisponibiliteVehicule(Long vehiculeId) {
            return disponibiliteParVehicule.getOrDefault(vehiculeId, fenetre.getStartTime());
        }
        public LocalDateTime getStartTime() { return fenetre.getStartTime(); }
        public LocalDateTime getEndTime() { return fenetre.getEndTime(); }
    }

    /**
     * SPRINT 8: Construit les fenêtres basées sur les retours de véhicules.
     *
     * Algorithme:
     * 1. Récupérer les véhicules disponibles dès le début (aucune attribution)
     * 2. Récupérer les véhicules qui reviennent pendant la journée
     * 3. Créer des événements de disponibilité triés chronologiquement
     * 4. Grouper les événements en fenêtres (véhicules revenant à la même heure = même fenêtre)
     *
     * @param date La date de planification
     * @param reservations Toutes les réservations du jour
     * @param tempsAttenteMinutes Durée de la fenêtre d'attente
     * @param attributionsExistantes Attributions déjà existantes dans la session
     * @return Liste de fenêtres Sprint 8 avec véhicules disponibles
     */
    private List<FenetreSprint8> construireFenetresBaseesSurRetourVehicules(
            LocalDateTime date,
            List<Reservation> reservations,
            double tempsAttenteMinutes,
            List<Attribution> attributionsExistantes) throws SQLException {

        List<FenetreSprint8> fenetres = new ArrayList<>();
        if (reservations == null || reservations.isEmpty()) return fenetres;

        // Déterminer l'horizon de planification
        LocalDateTime premiereArrivee = reservations.stream()
                .map(Reservation::getArrivalDate)
                .filter(d -> d != null)
                .min(LocalDateTime::compareTo)
                .orElse(date);

        LocalDateTime finJournee = date.toLocalDate().atTime(23, 59, 59);

        // 1. Récupérer les véhicules disponibles dès le début (aucune attribution après premiereArrivee)
        List<Vehicule> vehiculesDisponiblesDebut = vehiculeRepository.findVehiculesDisponiblesAuDebut(premiereArrivee);

        // 2. Récupérer TOUS les événements de retour pendant la journée
        List<AttributionRepository.VehiculeRetourEvent> vehiculesRevenant =
                attributionRepository.getEvenementsRetourVehicules(premiereArrivee, finJournee);

        // 3. Créer les événements de disponibilité
        List<VehicleAvailabilityEvent> events = new ArrayList<>();

        // Ajouter les véhicules disponibles dès le début
        for (Vehicule v : vehiculesDisponiblesDebut) {
            events.add(new VehicleAvailabilityEvent(v, premiereArrivee));
        }

        // Ajouter tous les retours (pas uniquement le dernier retour par véhicule)
        for (AttributionRepository.VehiculeRetourEvent entry : vehiculesRevenant) {
            Vehicule v = vehiculeRepository.findById(entry.getVehiculeId());
            if (v == null) continue;
            boolean dejaPresent = events.stream()
                    .anyMatch(e -> e.getVehicule().getId().equals(v.getId())
                            && e.getAvailableAt().equals(entry.getHeureRetour()));
            if (!dejaPresent) {
                events.add(new VehicleAvailabilityEvent(v, entry.getHeureRetour()));
            }
        }

        // Ajouter aussi les véhicules qui reviennent depuis attributionsExistantes (session courante)
        for (Attribution attr : attributionsExistantes) {
            if (attr.getVehicule() != null && attr.getDateHeureRetour() != null) {
                LocalDateTime retour = attr.getDateHeureRetour();
                if (!retour.isBefore(premiereArrivee) && !retour.isAfter(finJournee)) {
                    boolean dejaPresent = events.stream()
                            .anyMatch(e -> e.getVehicule().getId().equals(attr.getVehicule().getId())
                                    && e.getAvailableAt().equals(retour));
                    if (!dejaPresent) {
                        events.add(new VehicleAvailabilityEvent(attr.getVehicule(), retour));
                    }
                }
            }
        }

        if (events.isEmpty()) return fenetres;

        // 4. Trier par heure de disponibilité
        events.sort(Comparator.comparing(VehicleAvailabilityEvent::getAvailableAt));

        // 5. Grouper en fenêtres
        FenetreSprint8 currentFenetre = null;

        for (VehicleAvailabilityEvent event : events) {
            LocalDateTime eventTime = event.getAvailableAt();

            // Nouvelle fenêtre si:
            // - Pas de fenêtre courante, OU
            // - L'événement est après la fin de la fenêtre courante
            if (currentFenetre == null || eventTime.isAfter(currentFenetre.getEndTime())) {
                currentFenetre = new FenetreSprint8(
                        eventTime,
                        eventTime.plusMinutes((long) tempsAttenteMinutes),
                        TypeFenetreSprint8.RETOUR_VEHICULE);
                fenetres.add(currentFenetre);
            }

            // Ajouter le véhicule à la fenêtre courante
            currentFenetre.addVehicule(event.getVehicule(), eventTime);
        }

        return fenetres;
    }

    /**
     *  sprint 8 :
     * - Priorité 1: anciennes non assignées (arrivées avant le début de fenêtre), triées par passagers DESC.
     * - Priorité 2: nouvelles arrivées de la fenêtre, triées par arrival_date ASC puis passagers DESC.
     */
    private List<Reservation> trierReservationsFenetreSprint8(FenetreRegroupement fenetre) {
        List<Reservation> prioritaires = new ArrayList<>();
        List<Reservation> nouvelles = new ArrayList<>();

        for (Reservation r : fenetre.getReservations()) {
            if (r.getArrivalDate() != null && r.getArrivalDate().isBefore(fenetre.getStartTime())) {
                prioritaires.add(r);
            } else {
                nouvelles.add(r);
            }
        }

        prioritaires.sort(Comparator.comparingInt(Reservation::getPassengerNbr).reversed());
        nouvelles.sort(Comparator
                .comparing(Reservation::getArrivalDate, Comparator.nullsLast(LocalDateTime::compareTo))
                .thenComparing(Comparator.comparingInt(Reservation::getPassengerNbr).reversed()));

        List<Reservation> resultat = new ArrayList<>(prioritaires.size() + nouvelles.size());
        resultat.addAll(prioritaires);
        resultat.addAll(nouvelles);
        return resultat;
    }

    private String buildFenetreKey(FenetreSprint8 fenetre) {
        String vehicules = fenetre.getVehiculesDisponibles().stream()
                .map(v -> String.valueOf(v.getId()))
                .sorted()
                .collect(Collectors.joining(","));
        return fenetre.getTypeFenetre() + "|" + fenetre.getStartTime() + "|" + fenetre.getEndTime() + "|" + vehicules;
    }

    /**
     * SPRINT 8 - Point 5: véhicules réellement disponibles à un instant donné,
     * en tenant compte de la BD et des attributions en mémoire (session courante).
     */
    private List<Vehicule> getVehiculesDisponiblesAInstant(
            LocalDateTime instant,
            List<Attribution> attributionsExistantes) throws SQLException {

        List<Vehicule> tousVehicules = vehiculeRepository.findAllVehicules();
        List<Vehicule> disponibles = new ArrayList<>();

        for (Vehicule vehicule : tousVehicules) {
            if (vehicule.getNbPlace() < 1) continue;
            if (!vehicule.estDisponibleAHeure(instant.toLocalTime())) continue;

            boolean disponibleBD = attributionRepository.isVehiculeDisponible(vehicule.getId(), instant);
            boolean conflitSession = hasConflitHoraire(vehicule.getId(), instant, attributionsExistantes);

            if (disponibleBD && !conflitSession) {
                disponibles.add(vehicule);
            }
        }

        return disponibles;
    }

    /**
     * SPRINT 8 - Point 5: pour une fenêtre issue d'une non assignée, inclure aussi
     * les véhicules qui reviennent pendant l'intervalle de cette fenêtre.
     */
    private void ajouterVehiculesRetournantDansIntervalle(
            FenetreSprint8 fenetre,
            LocalDateTime startInclusive,
            LocalDateTime endInclusive,
            List<Attribution> attributionsExistantes) throws SQLException {

        if (fenetre == null || startInclusive == null || endInclusive == null) return;
        if (endInclusive.isBefore(startInclusive)) return;

        List<AttributionRepository.VehiculeRetourEvent> retoursDB =
                attributionRepository.getEvenementsRetourVehicules(startInclusive, endInclusive);
        for (AttributionRepository.VehiculeRetourEvent event : retoursDB) {
            Vehicule vehicule = vehiculeRepository.findById(event.getVehiculeId());
            if (vehicule == null) continue;
            if (!vehicule.estDisponibleAHeure(event.getHeureRetour().toLocalTime())) continue;
            fenetre.addVehicule(vehicule, event.getHeureRetour());
        }

        for (Attribution attr : attributionsExistantes) {
            if (attr.getVehicule() == null || attr.getDateHeureRetour() == null) continue;
            LocalDateTime retour = attr.getDateHeureRetour();
            if (retour.isBefore(startInclusive) || retour.isAfter(endInclusive)) continue;
            if (!attr.getVehicule().estDisponibleAHeure(retour.toLocalTime())) continue;
            fenetre.addVehicule(attr.getVehicule(), retour);
        }
    }

    // ============================================================================
    // TRAITEMENT D'UNE FENÊTRE
    // ============================================================================

    private PlanningResult traiterFenetre(
            FenetreRegroupement fenetre,
            List<Reservation> toutesReservationsJour,
            List<Attribution> attributionsExistantes,
            double vitesseMoyenne,
            double tempsAttenteMinutes,
            Map<Long, Integer> trajetsSessionParVehicule,
            AttributionRepository attributionRepository) throws SQLException {

        List<Attribution> attributionsFenetre = new ArrayList<>();
        List<Reservation> nonAssigneesFenetre = new ArrayList<>();
        List<ReservationPartielle> reservationsPartielles = new ArrayList<>();
        Set<Long> assignedIds = new HashSet<>();

        // passagersDejaAssignes : Map PARTAGÉE entre toutes les itérations de la fenêtre.
        // Garantit la cohérence : si client3 est partiellement assigné par vehicule3,
        // vehicule4 sait qu'il en reste seulement X.
        Map<Long, Integer> passagersDejaAssignes = new HashMap<>();

        // FIX 2 : heureDepart = MAX(arrivalDate originales, retour véhicules précédents)
        LocalDateTime heureDepart = calculerHeureDepartSansPartielles(fenetre);
        for (Attribution attr : attributionsExistantes) {
            if (attr.getDateHeureRetour() == null) continue;
            LocalDateTime retour = attr.getDateHeureRetour();
            if (!retour.isBefore(fenetre.getStartTime()) && retour.isAfter(heureDepart)) {
                heureDepart = retour;
            }
        }

        //  sprint 8: prioriser les anciennes non assignées avant les nouvelles arrivées.
        List<Reservation> reservationsTriees = trierReservationsFenetreSprint8(fenetre);

        for (Reservation reservation : reservationsTriees) {

            int passagersDejaAss = passagersDejaAssignes.getOrDefault(reservation.getId(), 0);
            int passagersAAssigner = reservation.getPassengerNbr() - passagersDejaAss;

            if (passagersAAssigner <= 0) {
                assignedIds.add(reservation.getId());
                continue;
            }

            BigDecimal distanceAller = getDistanceAllerSimple(reservation);
            if (distanceAller == null) {
                nonAssigneesFenetre.add(reservation);
                continue;
            }

            // Tentative 1 : regroupement optimal
            Attribution meilleureAttribution = trouverMeilleureAttributionAvecRegroupement(
                    reservation, toutesReservationsJour, assignedIds,
                    attributionsExistantes, heureDepart, vitesseMoyenne, passagersDejaAssignes,
                    fenetre.getStartTime(), fenetre.getEndTime(), tempsAttenteMinutes, trajetsSessionParVehicule);

            if (meilleureAttribution != null) {
                // Mettre à jour assignedIds
                for (Reservation r : meilleureAttribution.getReservations()) {
                    int total = passagersDejaAssignes.getOrDefault(r.getId(), 0);
                    if (total >= r.getPassengerNbr()) {
                        assignedIds.add(r.getId());
                    }
                }

                List<TrajetCar> trajets = getDureTotalTrajet(
                        meilleureAttribution.getReservations(), vitesseMoyenne);
                double dureeTotale = getTotalDuree(trajets);
                double distanceTotale = getTotalDistance(trajets);

                LocalDateTime heureDepartEffective = heureDepart;
                if (meilleureAttribution.getDateHeureDepart() != null
                        && meilleureAttribution.getDateHeureDepart().isAfter(heureDepart)) {
                    heureDepartEffective = meilleureAttribution.getDateHeureDepart();
                }

                meilleureAttribution.setDetailTraject(trajets);
                meilleureAttribution.setDateHeureDepart(heureDepartEffective);
                meilleureAttribution.setDistanceKm(distanceAller);
                meilleureAttribution.setDistanceAllerRetourKm(BigDecimal.valueOf(distanceTotale));
                meilleureAttribution.setDateHeureRetour(
                        heureDepartEffective.plusMinutes((long) (dureeTotale * 60)));

                attributionsFenetre.add(meilleureAttribution);
                attributionsExistantes.add(meilleureAttribution);


                // FIX 5 : Si la réservation principale n'est QUE partiellement assignée
                // par ce véhicule (nb_passagers > nb_places), créer une partielle.
                int totalAssignePrincipal = passagersDejaAssignes.getOrDefault(reservation.getId(), 0);
                int passagersRestantsPrincipal = reservation.getPassengerNbr() - totalAssignePrincipal;
                if (passagersRestantsPrincipal > 0 && reservation.getId() > 0
                        && !assignedIds.contains(reservation.getId())) {
                    reservationsPartielles.add(
                            new ReservationPartielle(reservation, passagersRestantsPrincipal));
                }

            } else {
                // Tentative 2 : division entre plusieurs véhicules
                List<Attribution> attributionsParDivision = trouverMeilleureAttributionAvecDivision(
                        reservation, toutesReservationsJour, assignedIds,
                        attributionsExistantes, heureDepart, vitesseMoyenne, passagersDejaAssignes,
                        fenetre.getStartTime(), fenetre.getEndTime(), trajetsSessionParVehicule);

                if (!attributionsParDivision.isEmpty()) {
                    attributionsFenetre.addAll(attributionsParDivision);


                    int totalAssignePrincipal = passagersDejaAssignes.getOrDefault(reservation.getId(), 0);
                    int passagersRestantsPrincipal = reservation.getPassengerNbr() - totalAssignePrincipal;

                    if (passagersRestantsPrincipal > 0 && reservation.getId() > 0) {
                        reservationsPartielles.add(
                                new ReservationPartielle(reservation, passagersRestantsPrincipal));
                    } else {
                        assignedIds.add(reservation.getId());
                    }
                } else {
                    // FIX: Vérifier si la réservation a été partiellement assignée via regroupement
                    int totalAssigne = passagersDejaAssignes.getOrDefault(reservation.getId(), 0);
                    int passagersRestants = reservation.getPassengerNbr() - totalAssigne;

                    if (passagersRestants > 0 && passagersRestants < reservation.getPassengerNbr()) {
                        // Partiellement assignée via regroupement, créer une partielle pour le reste
                        reservationsPartielles.add(
                                new ReservationPartielle(reservation, passagersRestants));
                    } else {
                        // Pas du tout assignée, ajouter aux non-assignées
                        nonAssigneesFenetre.add(reservation);
                    }
                }
            }
        }

        // Synchroniser les attributions sans heure de départ
        for (Attribution attribution : attributionsFenetre) {
            if (attribution.getDateHeureDepart() == null) {
                attribution.setDateHeureDepart(heureDepart);
                if (attribution.getDateHeureRetour() == null) {
                    attribution.setDateHeureRetour(heureDepart.plusMinutes(120));
                }
            }
        }

        Set<Long> reservationIdsCompletementAssignees = passagersDejaAssignes.entrySet().stream()
                .filter(e -> e.getKey() != null && e.getKey() > 0)
                .filter(e -> {
                    Reservation source = trouverReservationParId(toutesReservationsJour, e.getKey());
                    return source != null && e.getValue() >= source.getPassengerNbr();
                })
                .map(Map.Entry::getKey)
                .collect(Collectors.toSet());

        return new PlanningResult(
                attributionsFenetre,
                nonAssigneesFenetre,
                reservationsPartielles,
                reservationIdsCompletementAssignees);
    }

    private Reservation trouverReservationParId(List<Reservation> reservations, Long id) {
        if (reservations == null || id == null) return null;
        for (Reservation r : reservations) {
            if (r.getId() != null && r.getId().equals(id)) {
                return r;
            }
        }
        return null;
    }

    /**
     * FIX 2 : Heure de départ basée uniquement sur les réservations originales (ID > 0).
     */
    private LocalDateTime calculerHeureDepartSansPartielles(FenetreRegroupement fenetre) {
        return fenetre.getReservations().stream()
                .filter(r -> r.getId() != null && r.getId() > 0)
                .map(Reservation::getArrivalDate)
                .filter(d -> d != null)
                .max(LocalDateTime::compareTo)
                .orElse(fenetre.getStartTime());
    }

    /**
     * SPRINT 8: Traite une fenêtre basée sur le retour de véhicules.
     *
     * Algorithme:
     * 1. Collecter les réservations non assignées arrivées AVANT le début de la fenêtre (prioritaires)
     * 2. Collecter les nouvelles arrivées dans la fenêtre
     * 3. Trier les prioritaires par passagers décroissant
     * 4. Pour chaque réservation:
     *    - Sélectionner le véhicule optimal parmi ceux disponibles
     *    - Assigner les passagers
     *    - Si le véhicule n'est pas plein, remplir avec des réservations compatibles (fenêtre d'attente)
     *    - Créer des partielles pour le reste si nécessaire
     */
    private PlanningResult traiterFenetreSprint8(
            FenetreSprint8 fenetreSprint8,
            List<Reservation> toutesReservationsJour,
            List<Reservation> reservationsNonAssignees,
            List<Attribution> attributionsExistantes,
            double vitesseMoyenne,
            double tempsAttenteMinutes,
            Map<Long, Integer> trajetsSessionParVehicule,
            Map<Long, Integer> passagersDejaAssignes,
            Set<Long> globalAssignedIds) throws SQLException {

        List<Attribution> attributionsFenetre = new ArrayList<>();
        List<Reservation> nonAssigneesFenetre = new ArrayList<>();
        List<ReservationPartielle> reservationsPartielles = new ArrayList<>();
        Set<Long> assignedIds = new HashSet<>(globalAssignedIds);

        LocalDateTime fenetreStart = fenetreSprint8.getStartTime();
        LocalDateTime fenetreEnd = fenetreSprint8.getEndTime();
        boolean fenetreIssueArrivee = fenetreSprint8.getTypeFenetre() == TypeFenetreSprint8.ARRIVEE_NON_ASSIGNEE;

        // Copie modifiable des véhicules disponibles
        List<Vehicule> vehiculesDisponibles = new ArrayList<>(fenetreSprint8.getVehiculesDisponibles());

        // Charger les trajets par véhicule
        Map<Long, Integer> trajetsParVehiculeDB = attributionRepository.countTrajetsParVehicule();
        Map<Long, Integer> trajetsParVehicule = new HashMap<>(trajetsParVehiculeDB);
        for (Map.Entry<Long, Integer> entry : trajetsSessionParVehicule.entrySet()) {
            trajetsParVehicule.put(entry.getKey(),
                    trajetsParVehicule.getOrDefault(entry.getKey(), 0) + entry.getValue());
        }

        // 1. Collecter les réservations prioritaires (arrivées AVANT fenêtre)
        List<Reservation> prioritaires = new ArrayList<>();
        List<Reservation> nouvelles = new ArrayList<>();

        for (Reservation r : reservationsNonAssignees) {
            if (assignedIds.contains(r.getId())) continue;

            if (r.getArrivalDate() != null && r.getArrivalDate().isBefore(fenetreStart)) {
                prioritaires.add(r);
            } else if (r.getArrivalDate() != null && !r.getArrivalDate().isAfter(fenetreEnd)) {
                nouvelles.add(r);
            }
        }

        // 2. Trier prioritaires par passagers décroissant
        prioritaires.sort(Comparator.comparingInt(Reservation::getPassengerNbr).reversed());

        // Trier nouvelles par arrival_date ASC puis passagers DESC
        nouvelles.sort(Comparator
                .comparing(Reservation::getArrivalDate, Comparator.nullsLast(LocalDateTime::compareTo))
                .thenComparing(Comparator.comparingInt(Reservation::getPassengerNbr).reversed()));

        // 3. Combiner: prioritaires d'abord, puis nouvelles
        List<Reservation> reservationsATraiter = new ArrayList<>();
        reservationsATraiter.addAll(prioritaires);
        reservationsATraiter.addAll(nouvelles);

        // 4. Traiter chaque réservation
        for (Reservation reservation : reservationsATraiter) {
            if (assignedIds.contains(reservation.getId())) continue;
            if (vehiculesDisponibles.isEmpty()) {
                nonAssigneesFenetre.add(reservation);
                continue;
            }

            int passagersDejaAss = passagersDejaAssignes.getOrDefault(reservation.getId(), 0);
            int passagersAAssigner = reservation.getPassengerNbr() - passagersDejaAss;

            if (passagersAAssigner <= 0) {
                assignedIds.add(reservation.getId());
                continue;
            }

            BigDecimal distanceAller = getDistanceAllerSimple(reservation);
            if (distanceAller == null) {
                nonAssigneesFenetre.add(reservation);
                continue;
            }

            // Sélectionner le véhicule optimal parmi les véhicules de la fenêtre
            Vehicule vehiculeOptimal = selectionnerVehiculeOptimalPourAssignation(
                    passagersAAssigner, vehiculesDisponibles, trajetsParVehicule);

            if (vehiculeOptimal == null) {
                // Aucun véhicule n'a assez de places -> essayer la division
                Vehicule vehiculePlusPetit = selectionnerMeilleureVehiculeForDivision(
                        passagersAAssigner, vehiculesDisponibles, trajetsParVehicule);

                if (vehiculePlusPetit != null) {
                    // Division: assigner partiellement
                    int passagersAssignes = Math.min(passagersAAssigner, vehiculePlusPetit.getNbPlace());
                    LocalDateTime heureDisponibiliteVehicule =
                            getHeureDisponibiliteVehicule(fenetreSprint8, vehiculePlusPetit, fenetreStart);

                    Attribution attribution = creerAttributionSprint8(
                            reservation, vehiculePlusPetit, passagersAssignes,
                            heureDisponibiliteVehicule, vitesseMoyenne, distanceAller);

                    // Mettre à jour le tracking
                    int totalAssigne = passagersDejaAssignes.getOrDefault(reservation.getId(), 0) + passagersAssignes;
                    passagersDejaAssignes.put(reservation.getId(), totalAssigne);
                    attribution.setPassagersPourReservation(reservation.getId(), passagersAssignes);

                    // Remplir le véhicule avec des réservations compatibles si places restantes
                    int placesRestantes = vehiculePlusPetit.getNbPlace() - passagersAssignes;
                    LocalDateTime heureDepartVehicule = heureDisponibiliteVehicule;
                    if (reservation.getArrivalDate() != null && reservation.getArrivalDate().isAfter(heureDepartVehicule)) {
                        heureDepartVehicule = reservation.getArrivalDate();
                    }

                    if (placesRestantes > 0) {
                        // Fenêtre d'attente dynamique: closest fit à chaque itération
                        while (placesRestantes > 0) {
                            Reservation autre = trouverMeilleureReservationPourFenetreSprint8(
                                    placesRestantes,
                                    reservationsATraiter,
                                    assignedIds,
                                    passagersDejaAssignes,
                                    reservation.getLieuDepart(),
                                    fenetreEnd,
                                    reservation.getId());

                            if (autre == null) break;

                            int autrePassagersRestants = autre.getPassengerNbr()
                                    - passagersDejaAssignes.getOrDefault(autre.getId(), 0);
                            if (autrePassagersRestants <= 0) {
                                assignedIds.add(autre.getId());
                                continue;
                            }

                            int passagersAPrendre = Math.min(autrePassagersRestants, placesRestantes);
                            attribution.addReservation(autre);
                            attribution.setPassagersPourReservation(autre.getId(), passagersAPrendre);
                            attribution.setNbPassagersAssignes(attribution.getNbPassagersAssignes() + passagersAPrendre);

                            int autreTotal = passagersDejaAssignes.getOrDefault(autre.getId(), 0) + passagersAPrendre;
                            passagersDejaAssignes.put(autre.getId(), autreTotal);

                            if (autreTotal >= autre.getPassengerNbr()) {
                                assignedIds.add(autre.getId());
                            }

                            if (autre.getArrivalDate() != null && autre.getArrivalDate().isAfter(heureDepartVehicule)) {
                                heureDepartVehicule = autre.getArrivalDate();
                            }

                            placesRestantes -= passagersAPrendre;
                        }
                    }

                    // Finaliser l'attribution
                    attribution.setDateHeureDepart(heureDepartVehicule);
                    List<TrajetCar> trajets = getDureTotalTrajet(attribution.getReservations(), vitesseMoyenne);
                    double dureeTotale = getTotalDuree(trajets);
                    attribution.setDetailTraject(trajets);
                    attribution.setDateHeureRetour(heureDepartVehicule.plusMinutes((long) (dureeTotale * 60)));

                    attributionsFenetre.add(attribution);
                    attributionsExistantes.add(attribution);

                    // Mettre à jour les trajets du véhicule
                    trajetsSessionParVehicule.put(vehiculePlusPetit.getId(),
                            trajetsSessionParVehicule.getOrDefault(vehiculePlusPetit.getId(), 0) + 1);

                    // Retirer le véhicule de la liste des disponibles
                    vehiculesDisponibles.remove(vehiculePlusPetit);

                    // Gérer le reste non assigné de la réservation principale
                    int resteNonAssigne = reservation.getPassengerNbr() - passagersDejaAssignes.getOrDefault(reservation.getId(), 0);
                    if (resteNonAssigne > 0) {
                        reservationsPartielles.add(new ReservationPartielle(reservation, resteNonAssigne));
                    } else {
                        assignedIds.add(reservation.getId());
                    }
                } else {
                    // Aucun véhicule disponible
                    nonAssigneesFenetre.add(reservation);
                }
            } else {
                // Véhicule peut contenir tous les passagers
                int passagersAssignes = passagersAAssigner;
                LocalDateTime heureDisponibiliteVehicule =
                        getHeureDisponibiliteVehicule(fenetreSprint8, vehiculeOptimal, fenetreStart);

                Attribution attribution = creerAttributionSprint8(
                        reservation, vehiculeOptimal, passagersAssignes,
                        heureDisponibiliteVehicule, vitesseMoyenne, distanceAller);

                int totalAssigne = passagersDejaAssignes.getOrDefault(reservation.getId(), 0) + passagersAssignes;
                passagersDejaAssignes.put(reservation.getId(), totalAssigne);
                attribution.setPassagersPourReservation(reservation.getId(), passagersAssignes);

                // Remplir le véhicule avec d'autres réservations si places restantes
                int placesRestantes = vehiculeOptimal.getNbPlace() - passagersAssignes;
                LocalDateTime heureDepartVehicule = heureDisponibiliteVehicule;

                if (reservation.getArrivalDate() != null && reservation.getArrivalDate().isAfter(heureDepartVehicule)) {
                    heureDepartVehicule = reservation.getArrivalDate();
                }

                if (placesRestantes > 0) {
                    // Fenêtre d'attente dynamique: closest fit à chaque itération
                    while (placesRestantes > 0) {
                        Reservation autre = trouverMeilleureReservationPourFenetreSprint8(
                                placesRestantes,
                                reservationsATraiter,
                                assignedIds,
                                passagersDejaAssignes,
                                reservation.getLieuDepart(),
                                fenetreEnd,
                                reservation.getId());

                        if (autre == null) break;

                        int autrePassagersRestants = autre.getPassengerNbr()
                                - passagersDejaAssignes.getOrDefault(autre.getId(), 0);
                        if (autrePassagersRestants <= 0) {
                            assignedIds.add(autre.getId());
                            continue;
                        }

                        int passagersAPrendre = Math.min(autrePassagersRestants, placesRestantes);
                        attribution.addReservation(autre);
                        attribution.setPassagersPourReservation(autre.getId(), passagersAPrendre);
                        attribution.setNbPassagersAssignes(attribution.getNbPassagersAssignes() + passagersAPrendre);

                        int autreTotal = passagersDejaAssignes.getOrDefault(autre.getId(), 0) + passagersAPrendre;
                        passagersDejaAssignes.put(autre.getId(), autreTotal);

                        if (autreTotal >= autre.getPassengerNbr()) {
                            assignedIds.add(autre.getId());
                        }

                        if (autre.getArrivalDate() != null && autre.getArrivalDate().isAfter(heureDepartVehicule)) {
                            heureDepartVehicule = autre.getArrivalDate();
                        }

                        placesRestantes -= passagersAPrendre;
                    }
                }

                // Finaliser l'attribution
                attribution.setDateHeureDepart(heureDepartVehicule);
                List<TrajetCar> trajets = getDureTotalTrajet(attribution.getReservations(), vitesseMoyenne);
                double dureeTotale = getTotalDuree(trajets);
                attribution.setDetailTraject(trajets);
                attribution.setDateHeureRetour(heureDepartVehicule.plusMinutes((long) (dureeTotale * 60)));

                attributionsFenetre.add(attribution);
                attributionsExistantes.add(attribution);

                trajetsSessionParVehicule.put(vehiculeOptimal.getId(),
                        trajetsSessionParVehicule.getOrDefault(vehiculeOptimal.getId(), 0) + 1);

                vehiculesDisponibles.remove(vehiculeOptimal);
                assignedIds.add(reservation.getId());
            }
        }

        if (fenetreIssueArrivee) {
            appliquerDepartCommunPourFenetreArrivee(fenetreSprint8, attributionsFenetre, vitesseMoyenne);
        }

        return new PlanningResult(attributionsFenetre, nonAssigneesFenetre, reservationsPartielles, assignedIds);
    }

    private LocalDateTime getHeureDisponibiliteVehicule(
            FenetreSprint8 fenetreSprint8,
            Vehicule vehicule,
            LocalDateTime heureParDefaut) {
        if (vehicule == null || vehicule.getId() == null) return heureParDefaut;
        LocalDateTime dispo = fenetreSprint8.getDisponibiliteVehicule(vehicule.getId());
        if (dispo == null) return heureParDefaut;
        if (heureParDefaut != null && dispo.isBefore(heureParDefaut)) {
            return heureParDefaut;
        }
        return dispo;
    }

    /**
     * SPRINT 8 - Fenêtre issue d'une non assignée:
     * tous les véhicules assignés sur cette fenêtre partent à la même date/heure.
     */
    private void appliquerDepartCommunPourFenetreArrivee(
            FenetreSprint8 fenetreSprint8,
            List<Attribution> attributionsFenetre,
            double vitesseMoyenne) throws SQLException {

        if (attributionsFenetre == null || attributionsFenetre.isEmpty()) return;

        LocalDateTime departCommun = fenetreSprint8.getStartTime();
        for (Attribution attr : attributionsFenetre) {
            if (attr.getDateHeureDepart() != null && attr.getDateHeureDepart().isAfter(departCommun)) {
                departCommun = attr.getDateHeureDepart();
            }
        }

        for (Attribution attr : attributionsFenetre) {
            attr.setDateHeureDepart(departCommun);
            if (attr.getReservations() == null || attr.getReservations().isEmpty()) {
                attr.setDateHeureRetour(departCommun.plusMinutes(120));
                continue;
            }
            List<TrajetCar> trajets = attr.getDetailTraject();
            if (trajets == null || trajets.isEmpty()) {
                trajets = getDureTotalTrajet(attr.getReservations(), vitesseMoyenne);
                attr.setDetailTraject(trajets);
            }
            double dureeTotale = getTotalDuree(trajets);
            attr.setDateHeureRetour(departCommun.plusMinutes((long) (dureeTotale * 60)));
        }
    }

    /**
     * SPRINT 8: Crée une attribution avec les paramètres Sprint 8.
     */
    private Attribution creerAttributionSprint8(
            Reservation reservation, Vehicule vehicule, int passagersAssignes,
            LocalDateTime heureDepart, double vitesseMoyenne, BigDecimal distanceAller) {

        Attribution attribution = new Attribution();
        attribution.setVehicule(vehicule);
        attribution.setReservation(reservation);
        attribution.addReservation(reservation);
        attribution.setNbPassagersAssignes(passagersAssignes);
        attribution.setStatut("ASSIGNE");
        attribution.setDateHeureDepart(heureDepart);
        attribution.setDistanceKm(distanceAller);
        attribution.setDistanceAllerRetourKm(distanceAller.multiply(BigDecimal.valueOf(2)));

        return attribution;
    }

    /**
     * SPRINT 8: Vérifie si deux réservations sont compatibles pour le regroupement.
     * (Même lieu de départ)
     */
    private boolean estCompatiblePourRegroupement(Reservation r1, Reservation r2) {
        if (r1.getLieuDepart() == null || r2.getLieuDepart() == null) return false;
        return r1.getLieuDepart().getId().equals(r2.getLieuDepart().getId());
    }

    /**
     * SPRINT 8: choisir la réservation non assignée la plus proche des places restantes.
     * Tie-break: plus grand nombre de passagers restants.
     */
    private Reservation trouverMeilleureReservationPourFenetreSprint8(
            int placesRestantes,
            List<Reservation> reservationsATraiter,
            Set<Long> assignedIds,
            Map<Long, Integer> passagersDejaAssignes,
            Lieu lieuDepart,
            LocalDateTime limiteArriveeIncluse,
            Long reservationAExclure) {

        Reservation meilleure = null;
        int ecartMin = Integer.MAX_VALUE;
        int passagersRestantsMeilleure = -1;

        for (Reservation r : reservationsATraiter) {
            if (r == null || r.getId() == null) continue;
            if (reservationAExclure != null && r.getId().equals(reservationAExclure)) continue;
            if (assignedIds.contains(r.getId())) continue;
            if (r.getArrivalDate() == null) continue;
            if (limiteArriveeIncluse != null && r.getArrivalDate().isAfter(limiteArriveeIncluse)) continue;
            if (r.getLieuDepart() == null || lieuDepart == null) continue;
            if (!r.getLieuDepart().getId().equals(lieuDepart.getId())) continue;

            int restants = r.getPassengerNbr() - passagersDejaAssignes.getOrDefault(r.getId(), 0);
            if (restants <= 0) continue;

            int ecart = Math.abs(restants - placesRestantes);
            if (ecart < ecartMin || (ecart == ecartMin && restants > passagersRestantsMeilleure)) {
                ecartMin = ecart;
                passagersRestantsMeilleure = restants;
                meilleure = r;
            }
        }

        return meilleure;
    }

    // ============================================================================
    // SÉLECTION DU MEILLEUR VÉHICULE AVEC REGROUPEMENT OPTIMAL
    // ============================================================================

    private Attribution trouverMeilleureAttributionAvecRegroupement(
            Reservation reservationPrincipale,
            List<Reservation> toutesReservations,
            Set<Long> assignedIds,
            List<Attribution> attributionsExistantes,
            LocalDateTime dateHeureDepart,
            double vitesseMoyenne,
            Map<Long, Integer> passagersDejaAssignesGlobal,
            LocalDateTime startTime,
            LocalDateTime endTime,
            double tempsAttenteMinutes,
            Map<Long, Integer> trajetsSessionParVehicule) throws SQLException {

        List<Vehicule> tousVehicules = vehiculeRepository.findAvailableVehicules(1);
        Map<Long, Integer> trajetsParVehiculeDB = attributionRepository.countTrajetsParVehicule();

        //  sprint 7: Combiner les trajets de la BD et de la session courante
        Map<Long, Integer> trajetsParVehicule = new HashMap<>(trajetsParVehiculeDB);
        for (Map.Entry<Long, Integer> entry : trajetsSessionParVehicule.entrySet()) {
            trajetsParVehicule.put(entry.getKey(),
                    trajetsParVehicule.getOrDefault(entry.getKey(), 0) + entry.getValue());
        }

        List<Vehicule> vehiculesDisponibles = new ArrayList<>();
        Map<Long, LocalDateTime> heuresRetourVehicules = new HashMap<>();
        LocalDateTime borneRetourMax = endTime;
        LocalDateTime borneAttente = dateHeureDepart.plusMinutes((long) tempsAttenteMinutes);
        if (borneAttente.isAfter(borneRetourMax)) {
            borneRetourMax = borneAttente;
        }

        for (Vehicule vehicule : tousVehicules) {
            if (vehicule.getNbPlace() < 1) continue;
            if (!vehicule.estDisponibleAHeure(dateHeureDepart.toLocalTime())) continue;

            if (!hasConflitHoraire(vehicule.getId(), dateHeureDepart, attributionsExistantes)) {
                vehiculesDisponibles.add(vehicule);
            } else {
                // FIX: Vérifier si le véhicule revient PENDANT la fenêtre
                LocalDateTime heureRetour = getHeureRetourVehicule(vehicule.getId(), attributionsExistantes);
                if (heureRetour != null
                        && !heureRetour.isBefore(startTime)  // heureRetour >= startTime
                        && !heureRetour.isAfter(borneRetourMax) // heureRetour <= fin fenêtre d'attente
                        && vehicule.estDisponibleAHeure(heureRetour.toLocalTime())) {
                    vehiculesDisponibles.add(vehicule);
                    heuresRetourVehicules.put(vehicule.getId(), heureRetour);
                }
            }
        }

        if (vehiculesDisponibles.isEmpty()) return null;

        // Calculer les passagers restants de la réservation principale
        int passagersRestantsPrincipale = reservationPrincipale.getPassengerNbr()
                - passagersDejaAssignesGlobal.getOrDefault(reservationPrincipale.getId(), 0);

        if (passagersRestantsPrincipale <= 0) return null;

        //  sprint 7 MODIFICATION 2: Sélectionner le véhicule avec écart minimum
        // Priorité: 1) écart minimum, 2) moins de trajets, 3) diesel, 4) random
        Vehicule vehiculeOptimal = selectionnerVehiculeOptimalPourAssignation(
                passagersRestantsPrincipale, vehiculesDisponibles, trajetsParVehicule);

        if (vehiculeOptimal == null) return null;

        LocalDateTime heureDepartInitiale = dateHeureDepart;
        LocalDateTime heureRetourVehicule = heuresRetourVehicules.get(vehiculeOptimal.getId());
        if (heureRetourVehicule != null && heureRetourVehicule.isAfter(heureDepartInitiale)) {
            heureDepartInitiale = heureRetourVehicule;
        }
        LocalDateTime finFenetreAttente = heureDepartInitiale.plusMinutes((long) tempsAttenteMinutes);

        List<Reservation> compatibles = trouverReservationsCompatibles(
                reservationPrincipale, toutesReservations, assignedIds, finFenetreAttente);

        int placesDisponibles = vehiculeOptimal.getNbPlace();
        List<Reservation> reservationsGroupees = new ArrayList<>();
        Map<Long, Integer> passagersTracking = new HashMap<>(passagersDejaAssignesGlobal);
        Set<Long> assignedTrackingLocal = new HashSet<>(assignedIds);

        // Map pour tracker les passagers assignés à cette attribution spécifique
        Map<Long, Integer> passagersCetteAttribution = new HashMap<>();

        // Assigner la réservation principale (avec division si nécessaire)
        reservationsGroupees.add(reservationPrincipale);
        int passagersAssignesIci = Math.min(passagersRestantsPrincipale, placesDisponibles);
        placesDisponibles -= passagersAssignesIci;
        int totalPassagersGroupes = passagersAssignesIci;
        passagersCetteAttribution.put(reservationPrincipale.getId(), passagersAssignesIci);
        int nvTotalPrincipal = passagersTracking.getOrDefault(reservationPrincipale.getId(), 0)
                + passagersAssignesIci;
        passagersTracking.put(reservationPrincipale.getId(), nvTotalPrincipal);
        if (nvTotalPrincipal >= reservationPrincipale.getPassengerNbr()) {
            assignedTrackingLocal.add(reservationPrincipale.getId());
        }

        //  sprint 7 MODIFICATION 1: Remplir avec les compatibles (écart minimum)
        while (placesDisponibles > 0) {
            Reservation meilleure = trouverMeilleureReservationPourRegroupementOptimal(
                    placesDisponibles, compatibles, assignedTrackingLocal, passagersTracking,
                    reservationPrincipale.getLieuDepart());

            if (meilleure == null) break;

            int passagersRestantsDeCetteRes = meilleure.getPassengerNbr()
                    - passagersTracking.getOrDefault(meilleure.getId(), 0);

            if (passagersRestantsDeCetteRes <= 0) {
                assignedTrackingLocal.add(meilleure.getId());
                continue;
            }

            if (!reservationsGroupees.contains(meilleure)) {
                reservationsGroupees.add(meilleure);
            }

            if (passagersRestantsDeCetteRes <= placesDisponibles) {
                placesDisponibles -= passagersRestantsDeCetteRes;
                totalPassagersGroupes += passagersRestantsDeCetteRes;
                passagersCetteAttribution.put(meilleure.getId(), passagersRestantsDeCetteRes);
                passagersTracking.put(meilleure.getId(), meilleure.getPassengerNbr());
                assignedTrackingLocal.add(meilleure.getId());
            } else {
                totalPassagersGroupes += placesDisponibles;
                passagersCetteAttribution.put(meilleure.getId(), placesDisponibles);
                int nvTotal = passagersTracking.getOrDefault(meilleure.getId(), 0) + placesDisponibles;
                passagersTracking.put(meilleure.getId(), nvTotal);
                if (nvTotal >= meilleure.getPassengerNbr()) {
                    assignedTrackingLocal.add(meilleure.getId());
                }
                placesDisponibles = 0;
            }
        }

        // Mettre à jour le tracking global
        passagersDejaAssignesGlobal.putAll(passagersTracking);

        Attribution attribution = new Attribution();
        attribution.setVehicule(vehiculeOptimal);
        attribution.setReservation(reservationPrincipale);
        for (Reservation r : reservationsGroupees) {
            attribution.addReservation(r);
        }
        attribution.setNbPassagersAssignes(totalPassagersGroupes);
        attribution.setStatut("ASSIGNE");

        //  sprint 7: Enregistrer les passagers par réservation pour cette attribution
        for (Map.Entry<Long, Integer> entry : passagersCetteAttribution.entrySet()) {
            attribution.setPassagersPourReservation(entry.getKey(), entry.getValue());
        }

        LocalDateTime heureDepartFinale = heureDepartInitiale;
        LocalDateTime derniereArriveeAssignee = reservationsGroupees.stream()
                .map(Reservation::getArrivalDate)
                .filter(java.util.Objects::nonNull)
                .max(LocalDateTime::compareTo)
                .orElse(heureDepartInitiale);
        if (derniereArriveeAssignee.isAfter(heureDepartFinale)) {
            heureDepartFinale = derniereArriveeAssignee;
        }
        attribution.setDateHeureDepart(heureDepartFinale);

        return attribution;
    }

    /**
     *  sprint 7 MODIFICATION 2: Sélectionne le véhicule optimal.
     *
     * RÈGLE IMPORTANTE:
     * 1. D'abord, chercher les véhicules qui peuvent CONTENIR TOUS les passagers (nb_places >= passagers)
     * 2. Parmi ceux-ci, sélectionner celui avec l'écart minimum |nb_places - passagers|
     * 3. Si aucun véhicule ne peut contenir tous les passagers, retourner null (division sera utilisée)
     *
     * Critères de priorité en cas d'égalité d'écart:
     * - Moins de trajets effectués
     * - Diesel prioritaire
     * - Aléatoire
     */
    private Vehicule selectionnerVehiculeOptimalPourAssignation(
            int passagersAAssigner,
            List<Vehicule> vehiculesDisponibles,
            Map<Long, Integer> trajetsParVehicule) {

        if (vehiculesDisponibles == null || vehiculesDisponibles.isEmpty()) return null;

        // PRIORITÉ 1: Véhicules qui peuvent contenir TOUS les passagers (CAS 1: Assignation complète)
        List<Vehicule> vehiculesComplets = vehiculesDisponibles.stream()
                .filter(v -> v.getNbPlace() >= passagersAAssigner)
                .collect(Collectors.toList());

        // Si aucun véhicule ne peut contenir tous les passagers, retourner null
        // Le code appelant utilisera la division (CAS 2)
        if (vehiculesComplets.isEmpty()) {
            return null;
        }

        //  sprint 7 MODIFICATION 2: Parmi les véhicules complets, sélectionner avec écart minimum
        Map<Vehicule, Integer> ecartMap = new HashMap<>();
        for (Vehicule v : vehiculesComplets) {
            ecartMap.put(v, Math.abs(v.getNbPlace() - passagersAAssigner));
        }

        int ecartMin = ecartMap.values().stream().mapToInt(Integer::intValue).min().orElse(Integer.MAX_VALUE);

        List<Vehicule> meilleurs = vehiculesComplets.stream()
                .filter(v -> ecartMap.get(v) == ecartMin)
                .collect(Collectors.toList());

        if (meilleurs.size() == 1) return meilleurs.get(0);

        // Tie-breaker 1: moins de trajets
        Map<Vehicule, Integer> trajetsMap = new HashMap<>();
        for (Vehicule v : meilleurs) {
            trajetsMap.put(v, trajetsParVehicule.getOrDefault(v.getId(), 0));
        }
        int trajetsMin = trajetsMap.values().stream().mapToInt(Integer::intValue).min().orElse(0);
        List<Vehicule> moinsTrajets = meilleurs.stream()
                .filter(v -> trajetsMap.get(v) == trajetsMin)
                .collect(Collectors.toList());

        if (moinsTrajets.size() == 1) return moinsTrajets.get(0);

        // Tie-breaker 2: diesel prioritaire
        List<Vehicule> diesels = moinsTrajets.stream()
                .filter(v -> v.getTypeCarburant() == TypeCarburant.D)
                .collect(Collectors.toList());

        if (!diesels.isEmpty()) {
            Collections.shuffle(diesels);
            return diesels.get(0);
        }

        // Tie-breaker 3: aléatoire
        Collections.shuffle(moinsTrajets);
        return moinsTrajets.get(0);
    }

    // ============================================================================
    // DIVISION ENTRE PLUSIEURS VÉHICULES
    // ============================================================================

    private List<Attribution> trouverMeilleureAttributionAvecDivision(
            Reservation reservationPrincipale,
            List<Reservation> toutesReservations,
            Set<Long> assignedIds,
            List<Attribution> attributionsExistantes,
            LocalDateTime dateHeureDepart,
            double vitesseMoyenne,
            Map<Long, Integer> passagersDejaAssignesGlobal,
            LocalDateTime startTime,
            LocalDateTime endTime,
            Map<Long, Integer> trajetsSessionParVehicule) throws SQLException {

        List<Attribution> attributionsDivision = new ArrayList<>();
        List<Vehicule> tousVehicules = vehiculeRepository.findAvailableVehicules(1);
        Map<Long, Integer> trajetsParVehiculeDB = attributionRepository.countTrajetsParVehicule();

        //  sprint 7: Combiner les trajets de la BD et de la session courante
        Map<Long, Integer> trajetsParVehicule = new HashMap<>(trajetsParVehiculeDB);
        for (Map.Entry<Long, Integer> entry : trajetsSessionParVehicule.entrySet()) {
            trajetsParVehicule.put(entry.getKey(),
                    trajetsParVehicule.getOrDefault(entry.getKey(), 0) + entry.getValue());
        }

        List<Vehicule> vehiculesDisponibles = new ArrayList<>();
        Map<Long, LocalDateTime> heuresRetourVehicules = new HashMap<>();

        for (Vehicule vehicule : tousVehicules) {
            if (vehicule.getNbPlace() < 1) continue;
            if (!vehicule.estDisponibleAHeure(dateHeureDepart.toLocalTime())) continue;

            if (!hasConflitHoraire(vehicule.getId(), dateHeureDepart, attributionsExistantes)) {
                vehiculesDisponibles.add(vehicule);
            } else {
                // FIX: Vérifier si le véhicule revient AVANT ou AU MOMENT du départ demandé
                LocalDateTime heureRetour = getHeureRetourVehicule(vehicule.getId(), attributionsExistantes);
                if (heureRetour != null
                        && !heureRetour.isAfter(dateHeureDepart)  // heureRetour <= dateHeureDepart
                        && vehicule.estDisponibleAHeure(heureRetour.toLocalTime())) {
                    vehiculesDisponibles.add(vehicule);
                    heuresRetourVehicules.put(vehicule.getId(), heureRetour);
                }
            }
        }

        if (vehiculesDisponibles.isEmpty()) return attributionsDivision;

        // FIX 6 : passagersRestants = total - déjà assignés dans cette fenêtre
        int passagersRestants = reservationPrincipale.getPassengerNbr()
                - passagersDejaAssignesGlobal.getOrDefault(reservationPrincipale.getId(), 0);

        List<Vehicule> vehiculesUsables = new ArrayList<>(vehiculesDisponibles);

        while (passagersRestants > 0 && !vehiculesUsables.isEmpty()) {
            Vehicule vehiculeChoisi = selectionnerMeilleureVehiculeForDivision(
                    passagersRestants, vehiculesUsables, trajetsParVehicule);
            if (vehiculeChoisi == null) break;

            int passagersAssignes = Math.min(passagersRestants, vehiculeChoisi.getNbPlace());

            Attribution attribution = new Attribution();
            attribution.setVehicule(vehiculeChoisi);
            attribution.setReservation(reservationPrincipale);
            attribution.addReservation(reservationPrincipale);
            attribution.setNbPassagersAssignes(passagersAssignes);
            attribution.setStatut("ASSIGNE");
            attribution.setDateHeureDepart(dateHeureDepart);

            //  sprint 7: Tracker les passagers de la réservation principale pour cette attribution
            attribution.setPassagersPourReservation(reservationPrincipale.getId(), passagersAssignes);

            int totalAssignesPrincipal =
                    passagersDejaAssignesGlobal.getOrDefault(reservationPrincipale.getId(), 0) + passagersAssignes;
            passagersDejaAssignesGlobal.put(reservationPrincipale.getId(), totalAssignesPrincipal);

            int placesRestantes = vehiculeChoisi.getNbPlace() - passagersAssignes;
            if (placesRestantes > 0) {
                regroupperApressDivisionOptimal(
                        attribution, toutesReservations, assignedIds, passagersDejaAssignesGlobal);
            }

            try {
                BigDecimal distanceAller = getDistanceAllerSimple(reservationPrincipale);
                List<TrajetCar> trajets = attribution.getReservations().isEmpty()
                        ? new ArrayList<>()
                        : getDureTotalTrajet(attribution.getReservations(), vitesseMoyenne);
                double dureeTotale = getTotalDuree(trajets);
                double distanceTotale = getTotalDistance(trajets);

                attribution.setDetailTraject(trajets);
                attribution.setDistanceKm(distanceAller);
                attribution.setDistanceAllerRetourKm(BigDecimal.valueOf(distanceTotale));
                attribution.setDateHeureRetour(dateHeureDepart.plusMinutes((long) (dureeTotale * 60)));
            } catch (SQLException e) {
                attribution.setDateHeureRetour(dateHeureDepart.plusMinutes(120));
            }

            attributionsDivision.add(attribution);
            attributionsExistantes.add(attribution);
            passagersRestants -= passagersAssignes;
            vehiculesUsables.remove(vehiculeChoisi);
        }

        return attributionsDivision;
    }

    // ============================================================================
    // REGROUPEMENT APRÈS DIVISION
    // ============================================================================

    protected List<Reservation> regroupperApressDivisionOptimal(
            Attribution attribution,
            List<Reservation> toutesReservations,
            Set<Long> assignedIds,
            Map<Long, Integer> passagersDejaAssignes) throws SQLException {

        List<Reservation> ajoutees = new ArrayList<>();
        int placesRestantes = attribution.getVehicule().getNbPlace() - attribution.getNbPassagersAssignes();
        if (placesRestantes <= 0) return ajoutees;

        Lieu lieuDepart = attribution.getReservation().getLieuDepart();

        while (placesRestantes > 0) {
            Reservation meilleure = trouverMeilleureReservationPourRegroupementOptimal(
                    placesRestantes, toutesReservations, assignedIds, passagersDejaAssignes, lieuDepart);

            if (meilleure == null) break;

            int passagersDejaAss = passagersDejaAssignes.getOrDefault(meilleure.getId(), 0);
            int passagersRestantsDeCetteRes = meilleure.getPassengerNbr() - passagersDejaAss;

            if (passagersRestantsDeCetteRes <= 0) {
                assignedIds.add(meilleure.getId());
                continue;
            }

            attribution.addReservation(meilleure);

            if (passagersRestantsDeCetteRes <= placesRestantes) {
                attribution.setNbPassagersAssignes(
                        attribution.getNbPassagersAssignes() + passagersRestantsDeCetteRes);
                //  sprint 7: Tracker les passagers de cette réservation pour cette attribution
                attribution.setPassagersPourReservation(meilleure.getId(), passagersRestantsDeCetteRes);
                placesRestantes -= passagersRestantsDeCetteRes;
                passagersDejaAssignes.put(meilleure.getId(), meilleure.getPassengerNbr());
                assignedIds.add(meilleure.getId());
            } else {
                attribution.setNbPassagersAssignes(
                        attribution.getNbPassagersAssignes() + placesRestantes);
                //  sprint 7: Tracker les passagers partiels de cette réservation
                attribution.setPassagersPourReservation(meilleure.getId(), placesRestantes);
                int nvTotal = passagersDejaAss + placesRestantes;
                passagersDejaAssignes.put(meilleure.getId(), nvTotal);
                if (nvTotal >= meilleure.getPassengerNbr()) {
                    assignedIds.add(meilleure.getId());
                }
                placesRestantes = 0;
            }

            ajoutees.add(meilleure);
        }

        return ajoutees;
    }

    protected List<Reservation> regroupperApressDivision(
            Attribution attribution,
            List<Reservation> toutesReservations,
            Set<Long> assignedIds) throws SQLException {
        return regroupperApressDivisionOptimal(attribution, toutesReservations, assignedIds, new HashMap<>());
    }

    // ============================================================================
    // SÉLECTION DE LA MEILLEURE RÉSERVATION POUR REGROUPEMENT
    // ============================================================================

    private Reservation trouverMeilleureReservationPourRegroupementOptimal(
            int placesRestantes,
            List<Reservation> toutesReservations,
            Set<Long> assignedIds,
            Map<Long, Integer> passagersDejaAssignes,
            Lieu lieuDepart) {

        if (toutesReservations == null || lieuDepart == null || placesRestantes <= 0) return null;

        Reservation meilleure = null;
        int ecartMin = Integer.MAX_VALUE;

        for (Reservation r : toutesReservations) {
            if (r.getId() == null) continue;
            if (assignedIds.contains(r.getId())) continue;
            if (r.getLieuDepart() == null || !r.getLieuDepart().getId().equals(lieuDepart.getId())) continue;

            int passagersRestantsDeCetteRes = r.getPassengerNbr()
                    - passagersDejaAssignes.getOrDefault(r.getId(), 0);
            if (passagersRestantsDeCetteRes <= 0) continue;

            int ecart = Math.abs(passagersRestantsDeCetteRes - placesRestantes);

            if (ecart < ecartMin) {
                ecartMin = ecart;
                meilleure = r;
            } else if (ecart == ecartMin && meilleure != null) {
                int passagersRestantsMeilleure = meilleure.getPassengerNbr()
                        - passagersDejaAssignes.getOrDefault(meilleure.getId(), 0);
                if (passagersRestantsDeCetteRes > passagersRestantsMeilleure) {
                    meilleure = r;
                }
            }
        }

        return meilleure;
    }

    private Reservation trouverMeilleureReservationPourRegroupement(
            int placesRestantes,
            List<Reservation> toutesReservations,
            Set<Long> assignedIds,
            Lieu lieuDepart) {
        return trouverMeilleureReservationPourRegroupementOptimal(
                placesRestantes, toutesReservations, assignedIds, new HashMap<>(), lieuDepart);
    }

    // ============================================================================
    // SÉLECTION DU MEILLEUR VÉHICULE POUR LA DIVISION
    // ============================================================================

    private Vehicule selectionnerMeilleureVehiculeForDivision(
            int passagersAAssigner,
            List<Vehicule> vehiculesDisponibles,
            Map<Long, Integer> trajetsParVehicule) {

        if (vehiculesDisponibles == null || vehiculesDisponibles.isEmpty()) return null;

        List<Vehicule> candidats = vehiculesDisponibles.stream()
                .filter(v -> v.getNbPlace() > 0)
                .collect(Collectors.toList());
        if (candidats.isEmpty()) return null;

        Map<Vehicule, Integer> ecartMap = new HashMap<>();
        for (Vehicule v : candidats) {
            ecartMap.put(v, Math.abs(v.getNbPlace() - passagersAAssigner));
        }

        int ecartMin = ecartMap.values().stream().mapToInt(Integer::intValue).min().orElse(Integer.MAX_VALUE);

        List<Vehicule> meilleurs = candidats.stream()
                .filter(v -> ecartMap.get(v) == ecartMin)
                .collect(Collectors.toList());
        if (meilleurs.size() == 1) return meilleurs.get(0);

        Map<Vehicule, Integer> trajetsMap = new HashMap<>();
        for (Vehicule v : meilleurs) {
            trajetsMap.put(v, trajetsParVehicule.getOrDefault(v.getId(), 0));
        }
        int trajetsMin = trajetsMap.values().stream().mapToInt(Integer::intValue).min().orElse(0);
        List<Vehicule> moinsTrajets = meilleurs.stream()
                .filter(v -> trajetsMap.get(v) == trajetsMin)
                .collect(Collectors.toList());
        if (moinsTrajets.size() == 1) return moinsTrajets.get(0);

        List<Vehicule> diesels = moinsTrajets.stream()
                .filter(v -> v.getTypeCarburant() == TypeCarburant.D)
                .collect(Collectors.toList());
        if (!diesels.isEmpty()) {
            Collections.shuffle(diesels);
            return diesels.get(0);
        }

        Collections.shuffle(moinsTrajets);
        return moinsTrajets.get(0);
    }

    // ============================================================================
    // GESTION DES CONFLITS HORAIRES ET DISPONIBILITÉ
    // ============================================================================

    private boolean hasConflitHoraire(Long vehiculeId, LocalDateTime nouveauDepart,
            List<Attribution> attributionsExistantes) {
        for (Attribution t : attributionsExistantes) {
            if (t.getVehicule() != null && t.getVehicule().getId().equals(vehiculeId)) {
                LocalDateTime heureRetour = t.getDateHeureRetour();
                if (heureRetour == null) return true;
                if (heureRetour.compareTo(nouveauDepart) > 0) return true;
            }
        }
        return false;
    }

    private LocalDateTime getHeureRetourVehicule(Long vehiculeId, List<Attribution> attributions) {
        return attributions.stream()
                .filter(a -> a.getVehicule() != null && a.getVehicule().getId().equals(vehiculeId))
                .map(Attribution::getDateHeureRetour)
                .filter(java.util.Objects::nonNull)
                .max(LocalDateTime::compareTo)
                .orElse(null);
    }

    // ============================================================================
    // MÉTHODES UTILITAIRES
    // ============================================================================

    private List<Reservation> trouverReservationsCompatibles(
            Reservation reservationPrincipale,
            List<Reservation> toutesReservations,
            Set<Long> assignedIds,
            LocalDateTime limiteArriveeIncluse) {

        return toutesReservations.stream()
                .filter(r -> !assignedIds.contains(r.getId()))
                .filter(r -> !r.getId().equals(reservationPrincipale.getId()))
                .filter(r -> r.getArrivalDate() != null)
                .filter(r -> limiteArriveeIncluse == null || !r.getArrivalDate().isAfter(limiteArriveeIncluse))
                .filter(r -> r.getLieuDepart() != null && reservationPrincipale.getLieuDepart() != null)
                .filter(r -> r.getLieuDepart().getId().equals(reservationPrincipale.getLieuDepart().getId()))
                .sorted((r1, r2) -> Integer.compare(r2.getPassengerNbr(), r1.getPassengerNbr()))
                .collect(Collectors.toList());
    }

    private int evaluerAttributionAvecEquilibrage(Vehicule vehicule, List<Reservation> reservations, int nbTrajets) {
        int totalPassagers = reservations.stream().mapToInt(Reservation::getPassengerNbr).sum();
        int placesVides = vehicule.getNbPlace() - totalPassagers;
        int score = placesVides * 100 + nbTrajets * 10;
        if (vehicule.getTypeCarburant() != TypeCarburant.D) score += 5;
        score -= totalPassagers;
        return score;
    }

    private int evaluerAttribution(Vehicule vehicule, List<Reservation> reservations) {
        int totalPassagers = reservations.stream().mapToInt(Reservation::getPassengerNbr).sum();
        int placesVides = vehicule.getNbPlace() - totalPassagers;
        int score = placesVides * 10;
        if (vehicule.getTypeCarburant() != TypeCarburant.D) score += 5;
        score -= totalPassagers;
        return score;
    }

    private Vehicule choisirVehiculeOptimise(List<Vehicule> disponibles, int passengerNbr) {
        Map<Vehicule, Integer> ecarts = new HashMap<>();
        for (Vehicule v : disponibles) ecarts.put(v, v.getNbPlace() - passengerNbr);
        int ecartMin = ecarts.values().stream().mapToInt(Integer::intValue).min().orElse(Integer.MAX_VALUE);
        List<Vehicule> meilleurs = disponibles.stream()
                .filter(v -> (v.getNbPlace() - passengerNbr) == ecartMin).collect(Collectors.toList());
        if (meilleurs.size() == 1) return meilleurs.get(0);
        List<Vehicule> diesels = meilleurs.stream()
                .filter(v -> v.getTypeCarburant() == TypeCarburant.D).collect(Collectors.toList());
        if (!diesels.isEmpty()) { Collections.shuffle(diesels); return diesels.get(0); }
        Collections.shuffle(meilleurs);
        return meilleurs.get(0);
    }

    private Vehicule attribuerVehiculeEnMemoire(Reservation reservation,
            List<Attribution> attributionsExistantes, LocalDateTime dateHeureDepart) throws SQLException {
        List<Vehicule> disponibles = vehiculeRepository.findAvailableVehicules(reservation.getPassengerNbr());
        disponibles = disponibles.stream()
                .filter(v -> v.estDisponibleAHeure(dateHeureDepart.toLocalTime()))
                .filter(v -> !hasConflitHoraire(v.getId(), dateHeureDepart, attributionsExistantes))
                .collect(Collectors.toList());
        if (disponibles.isEmpty()) return null;
        return choisirVehicule(disponibles, reservation.getPassengerNbr());
    }

    private Vehicule choisirVehicule(List<Vehicule> disponibles, int passengerNbr) {
        if (disponibles.size() == 1) return disponibles.get(0);
        int minPlaces = disponibles.stream().mapToInt(Vehicule::getNbPlace).min().orElse(Integer.MAX_VALUE);
        List<Vehicule> plusProches = disponibles.stream()
                .filter(v -> v.getNbPlace() == minPlaces).collect(Collectors.toList());
        if (plusProches.size() == 1) return plusProches.get(0);
        List<Vehicule> diesels = plusProches.stream()
                .filter(v -> v.getTypeCarburant() == TypeCarburant.D).collect(Collectors.toList());
        if (diesels.size() >= 2) { Collections.shuffle(diesels); return diesels.get(0); }
        if (diesels.size() == 1) return diesels.get(0);
        Collections.shuffle(plusProches);
        return plusProches.get(0);
    }

    protected List<Attribution> diviserPassagersEntreVehicules(
            Reservation reservationPrincipale,
            List<Vehicule> vehiculesDisponibles,
            List<Attribution> attributionsExistantes,
            LocalDateTime dateHeureDepart,
            Map<Long, Integer> trajetsParVehicule) throws SQLException {

        List<Attribution> attributionsDivision = new ArrayList<>();
        int passagersRestants = reservationPrincipale.getPassengerNbr();
        List<Vehicule> vehiculesUsables = new ArrayList<>(vehiculesDisponibles);

        while (passagersRestants > 0 && !vehiculesUsables.isEmpty()) {
            Vehicule vehiculeChoisi = selectionnerMeilleureVehiculeForDivision(
                    passagersRestants, vehiculesUsables, trajetsParVehicule);
            if (vehiculeChoisi == null) break;
            int passagersAssignes = Math.min(passagersRestants, vehiculeChoisi.getNbPlace());
            Attribution attribution = new Attribution();
            attribution.setVehicule(vehiculeChoisi);
            attribution.setReservation(reservationPrincipale);
            attribution.addReservation(reservationPrincipale);
            attribution.setNbPassagersAssignes(passagersAssignes);
            attribution.setStatut("ASSIGNE");
            attribution.setDateHeureDepart(dateHeureDepart);
            attributionsDivision.add(attribution);
            passagersRestants -= passagersAssignes;
            vehiculesUsables.remove(vehiculeChoisi);
        }

        return attributionsDivision;
    }

    // ============================================================================
    // CALCUL DES DISTANCES ET TRAJETS
    // ============================================================================

    public double getTotalDuree(List<TrajetCar> result) {
        double val = 0.0;
        for (TrajetCar t : result) val += t.getDurre();
        return val;
    }

    public double getTotalDistance(List<TrajetCar> result) {
        double val = 0.0;
        for (TrajetCar t : result) val += t.getDistance();
        return val;
    }

    private BigDecimal getDistanceAllerSimple(Reservation reservation) throws SQLException {
        System.out.println(reservation.getLieuDepart().getId() + " ---- " + reservation.getLieuDestination().getId());
        if (reservation.getLieuDepart() == null || reservation.getLieuDestination() == null) return null;
        Distance distance = distanceRepository.findByFromAndTo(
                reservation.getLieuDepart().getId(), reservation.getLieuDestination().getId());
        return (distance != null) ? distance.getKmDistance() : null;
    }

    private double getDistanceLieu(Lieu lieuDepart, Lieu lieuDestination) throws SQLException {
        if (lieuDepart == null || lieuDestination == null) return 0.0;
        if (lieuDepart.getId() == lieuDestination.getId()) return 0.0;
        Distance distance = distanceRepository.findByFromAndTo(
                lieuDepart.getId(), lieuDestination.getId());
        if (distance == null) throw new IllegalArgumentException(
                "Distance non trouvée entre " + lieuDepart.getLibelle() + " et " + lieuDestination.getLibelle());
        return distance.getKmDistance().doubleValue();
    }

    private double getDistanceMin1(List<Reservation> reservation) throws SQLException {
        if (reservation == null) throw new IllegalArgumentException("Reservation non trouvée !");
        double min = Double.MAX_VALUE;
        for (Reservation reserv : reservation) {
            double distance = getDistanceAllerSimple(reserv).doubleValue();
            if (distance < min) min = distance;
        }
        return min;
    }

    private List<Reservation> getSameOrderReservation(List<Reservation> reservation, double distanceMin)
            throws SQLException {
        if (reservation == null) throw new IllegalArgumentException("Reservation non trouvée !");
        List<Reservation> reservationMin = new ArrayList<>();
        double epsilon = 0.1;
        Iterator<Reservation> it = reservation.iterator();
        while (it.hasNext()) {
            Reservation reserv = it.next();
            double distance = getDistanceAllerSimple(reserv).doubleValue();
            if (Math.abs(distance - distanceMin) < epsilon) {
                reservationMin.add(reserv);
                it.remove();
            }
        }
        return reservationMin;
    }

    private double getDistanceMin1(List<Reservation> reservation, Lieu nextPlace) throws SQLException {
        if (reservation == null || reservation.isEmpty())
            throw new IllegalArgumentException("Reservation non trouvée !");
        double min = Double.MAX_VALUE;
        for (Reservation reserv : reservation) {
            double distance = getDistanceLieu(nextPlace, reserv.getLieuDestination());
            if (distance < min) min = distance;
        }
        return min;
    }

    private List<Reservation> getListDistanceOrderByInitial(List<Reservation> reservation) throws SQLException {
        if (reservation == null) throw new IllegalArgumentException("Reservation non trouvée !");
        Map<Reservation, Integer> values = new HashMap<>();
        for (Reservation reserv : reservation) {
            String initString = reserv.getLieuDestination().getInitial();
            values.put(reserv, new Utilitaire().getValueInitial(initString));
        }
        return values.entrySet().stream()
                .sorted(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .toList();
    }

    private List<TrajetCar> getDureTotalTrajet(List<Reservation> reservations, double vitessMoyenne)
            throws SQLException {
        if (reservations == null) throw new IllegalArgumentException("Reservation non trouvée !");
        List<TrajetCar> resultFinal = new ArrayList<>();
        Reservation firstDeparture = reservations.get(0);
        Reservation lastDeparture = reservations.get(reservations.size() - 1);
        Reservation temporary = firstDeparture;
        double distanceInitial = getDistanceLieu(firstDeparture.getLieuDestination(), firstDeparture.getLieuDepart());
        double dureeTotal = distanceInitial / vitessMoyenne;
        resultFinal.add(new TrajetCar(firstDeparture.getLieuDepart(), firstDeparture.getLieuDestination(),
                distanceInitial, dureeTotal));
        for (int i = 1; i < reservations.size(); i++) {
            double value = getDistanceLieu(temporary.getLieuDestination(), reservations.get(i).getLieuDestination());
            dureeTotal += value / vitessMoyenne;
            resultFinal.add(new TrajetCar(temporary.getLieuDestination(), reservations.get(i).getLieuDestination(),
                    value, value / vitessMoyenne));
            temporary = reservations.get(i);
        }
        double goBack = getDistanceLieu(lastDeparture.getLieuDestination(), firstDeparture.getLieuDepart());
        dureeTotal += goBack / vitessMoyenne;
        resultFinal.add(new TrajetCar(lastDeparture.getLieuDestination(), firstDeparture.getLieuDepart(),
                goBack, goBack / vitessMoyenne));
        return resultFinal;
    }

    private List<Reservation> directionX(List<Reservation> reservations) throws SQLException {
        if (reservations == null || reservations.isEmpty()) return new ArrayList<>();
        List<Reservation> restantes = new ArrayList<>(reservations);
        List<Reservation> ordonnees = new ArrayList<>();
        double minDirect = getMinDistanceDirecte(restantes);
        List<Reservation> premieres = getReservationsAvecDistanceDirecte(restantes, minDirect);
        List<Reservation> premieresTriees = getListDistanceOrderByInitial(premieres);
        ordonnees.addAll(premieresTriees);
        if (ordonnees.isEmpty()) return ordonnees;
        Reservation derniere = ordonnees.get(ordonnees.size() - 1);
        while (!restantes.isEmpty()) {
            double minTransition = getMinDistanceTransition(restantes, derniere.getLieuDestination());
            List<Reservation> candidates = getReservationsAvecDistanceTransition(
                    restantes, derniere.getLieuDestination(), minTransition);
            List<Reservation> candidatsTries = getListDistanceOrderByInitial(candidates);
            ordonnees.addAll(candidatsTries);
            if (!candidatsTries.isEmpty()) derniere = candidatsTries.get(candidatsTries.size() - 1);
        }
        return ordonnees;
    }

    private double getMinDistanceDirecte(List<Reservation> reservations) throws SQLException {
        double min = Double.MAX_VALUE;
        for (Reservation r : reservations) {
            double d = getDistanceAllerSimple(r).doubleValue();
            if (d < min) min = d;
        }
        return min;
    }

    private List<Reservation> getReservationsAvecDistanceDirecte(List<Reservation> reservations, double target)
            throws SQLException {
        List<Reservation> result = new ArrayList<>();
        double epsilon = 0.0001;
        Iterator<Reservation> it = reservations.iterator();
        while (it.hasNext()) {
            Reservation r = it.next();
            double d = getDistanceAllerSimple(r).doubleValue();
            if (Math.abs(d - target) < epsilon) { result.add(r); it.remove(); }
        }
        return result;
    }

    private double getMinDistanceTransition(List<Reservation> reservations, Lieu from) throws SQLException {
        double min = Double.MAX_VALUE;
        for (Reservation r : reservations) {
            double d = getDistanceLieu(from, r.getLieuDestination());
            if (d < min) min = d;
        }
        return min;
    }

    private List<Reservation> getReservationsAvecDistanceTransition(List<Reservation> reservations,
            Lieu from, double target) throws SQLException {
        List<Reservation> result = new ArrayList<>();
        double epsilon = 0.0001;
        Iterator<Reservation> it = reservations.iterator();
        while (it.hasNext()) {
            Reservation r = it.next();
            double d = getDistanceLieu(from, r.getLieuDestination());
            if (Math.abs(d - target) < epsilon) { result.add(r); it.remove(); }
        }
        return result;
    }

    private double getDistanceRegrouper(List<Reservation> reservation) throws SQLException {
        if (reservation == null) throw new IllegalArgumentException("Reservation non trouvée !");
        double totalDistance = 0.0;
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
        return totalDistance;
    }

    // ============================================================================
    // CLASSES INTERNES
    // ============================================================================

    public static class DivisionResult {
        private final List<Attribution> attributions;
        private final int passagersRestants;

        public DivisionResult(List<Attribution> attributions, int passagersRestants) {
            this.attributions = attributions != null ? attributions : new ArrayList<>();
            this.passagersRestants = passagersRestants;
        }

        public List<Attribution> getAttributions() { return attributions; }
        public int getPassagersRestants() { return passagersRestants; }
        public boolean aDesPassagersRestants() { return passagersRestants > 0; }
    }

    public static class PlanningResult {
        private final List<Attribution> attributions;
        private final List<Reservation> reservationsNonAssignees;
        private final List<ReservationPartielle> reservationsPartielles;
        private final Set<Long> reservationIdsCompletementAssignees;

        public PlanningResult(List<Attribution> attributions, List<Reservation> reservationsNonAssignees) {
            this(attributions, reservationsNonAssignees, new ArrayList<>(), new HashSet<>());
        }

        public PlanningResult(List<Attribution> attributions,
                List<Reservation> reservationsNonAssignees,
                List<ReservationPartielle> reservationsPartielles) {
            this(attributions, reservationsNonAssignees, reservationsPartielles, new HashSet<>());
        }

        public PlanningResult(List<Attribution> attributions,
                List<Reservation> reservationsNonAssignees,
                List<ReservationPartielle> reservationsPartielles,
                Set<Long> reservationIdsCompletementAssignees) {
            this.attributions = attributions != null ? attributions : new ArrayList<>();
            this.reservationsNonAssignees = reservationsNonAssignees != null
                    ? reservationsNonAssignees : new ArrayList<>();
            this.reservationsPartielles = reservationsPartielles != null
                    ? reservationsPartielles : new ArrayList<>();
            this.reservationIdsCompletementAssignees = reservationIdsCompletementAssignees != null
                    ? reservationIdsCompletementAssignees : new HashSet<>();
        }

        public List<Attribution> getAttributions() { return attributions; }
        public List<Reservation> getReservationsNonAssignees() { return reservationsNonAssignees; }
        public List<ReservationPartielle> getReservationsPartielles() { return reservationsPartielles; }
        public Set<Long> getReservationIdsCompletementAssignees() { return reservationIdsCompletementAssignees; }

        public int getTotalPassagersAssignes() {
            int total = 0;
            for (Attribution a : attributions) {
                Integer nbPass = a.getNbPassagersAssignes();
                total += (nbPass != null) ? nbPass : a.getTotalPassengers();
            }
            return total;
        }

        public int getTotalPassagersReportes() {
            int total = 0;
            for (ReservationPartielle rp : reservationsPartielles) total += rp.getPassagersRestants();
            for (Reservation r : reservationsNonAssignees) total += r.getPassengerNbr();
            return total;
        }
    }
}
