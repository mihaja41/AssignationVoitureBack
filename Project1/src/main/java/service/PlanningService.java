package service;

import dto.PlanningDTO;
import model.Reservation;
import model.TypeCarburant;
import model.Vehicule;
import repository.ReservationRepository;
import repository.VehiculeRepository;

import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service de planification et d'attribution automatique de véhicules.
 *
 * Algorithme d'attribution :
 * 1. Pour chaque réservation NON_ASSIGNE à la date donnée :
 *    - Chercher les véhicules avec nb_places >= reservation.passengerNbr
 *    - Vérifier la disponibilité : heure_retour du véhicule <= heure_depart de la réservation
 *    - Si >= 2 véhicules éligibles : priorité au Diesel (D)
 *    - Si >= 2 véhicules Diesel éligibles : choix aléatoire parmi eux
 *    - Si aucun véhicule disponible : la réservation reste NON_ASSIGNE
 */
public class PlanningService {

    private final ReservationRepository reservationRepository = new ReservationRepository();
    private final VehiculeRepository vehiculeRepository = new VehiculeRepository();

    /**
     * Générer le planning pour une date donnée.
     * Lance l'attribution automatique, puis retourne :
     * - La liste des lignes de planning (réservations assignées)
     * - La liste des réservations non assignées
     */
    public PlanningResult genererPlanning(LocalDateTime date) throws SQLException {

        // 1. Récupérer les réservations NON_ASSIGNE pour cette date
        List<Reservation> nonAssignees = reservationRepository.findUnassignedByDate(date);

        // 2. Pour chaque réservation non assignée, tenter l'attribution
        for (Reservation reservation : nonAssignees) {
            attribuerVehicule(reservation);
        }

        // 3. Après attribution, récupérer le résultat final
        List<Reservation> assignees = reservationRepository.findAssignedByDate(date);
        List<Reservation> restantesNonAssignees = reservationRepository.findUnassignedByDate(date);

        // 4. Convertir en DTOs
        List<PlanningDTO> planningLines = assignees.stream()
                .map(this::toPlanningDTO)
                .collect(Collectors.toList());

        List<PlanningDTO> unassignedLines = restantesNonAssignees.stream()
                .map(this::toPlanningDTO)
                .collect(Collectors.toList());

        return new PlanningResult(planningLines, unassignedLines);
    }

    /**
     * Algorithme d'attribution d'un véhicule à une réservation.
     */
    private void attribuerVehicule(Reservation reservation) throws SQLException {
        // Heure de départ : utiliser heure_depart si définie, sinon arrival_date
        LocalDateTime heureDepart = reservation.getHeureDepart() != null
                ? reservation.getHeureDepart()
                : reservation.getArrivalDate();

        // Chercher véhicules disponibles (nb_places >= passengerNbr ET pas de conflit horaire)
        List<Vehicule> disponibles = vehiculeRepository.findAvailableVehicules(
                reservation.getPassengerNbr(), heureDepart);

        if (disponibles.isEmpty()) {
            // Aucun véhicule disponible → reste NON_ASSIGNE
            return;
        }

        Vehicule choisi = choisirVehicule(disponibles);

        if (choisi != null) {
            // Assigner le véhicule à la réservation
            reservationRepository.updateAssignment(
                    reservation.getId(),
                    choisi.getId(),
                    "ASSIGNE",
                    heureDepart,
                    reservation.getHeureArrivee() != null ? reservation.getHeureArrivee() : reservation.getArrivalDate(),
                    reservation.getHeureRetour()
            );
        }
    }

    /**
     * Choisir le meilleur véhicule selon les règles métier :
     * 1. Si >= 2 véhicules éligibles → priorité Diesel
     * 2. Si >= 2 Diesel → random parmi les Diesel
     * 3. Sinon → prendre le seul disponible
     */
    private Vehicule choisirVehicule(List<Vehicule> disponibles) {
        if (disponibles.size() == 1) {
            return disponibles.get(0);
        }

        // Filtrer les véhicules Diesel
        List<Vehicule> diesels = disponibles.stream()
                .filter(v -> v.getTypeCarburant() == TypeCarburant.D)
                .collect(Collectors.toList());

        if (diesels.size() >= 2) {
            // >= 2 Diesel disponibles → choix aléatoire parmi les Diesel
            Collections.shuffle(diesels);
            return diesels.get(0);
        } else if (diesels.size() == 1) {
            // 1 seul Diesel → on le prend en priorité
            return diesels.get(0);
        } else {
            // Aucun Diesel → choix aléatoire parmi tous les disponibles
            Collections.shuffle(disponibles);
            return disponibles.get(0);
        }
    }

    /**
     * Convertir une Reservation en PlanningDTO
     */
    private PlanningDTO toPlanningDTO(Reservation r) {
        PlanningDTO dto = new PlanningDTO();

        // Infos réservation
        dto.setReservationId(r.getId());
        dto.setCustomerId(r.getCustomerId());
        dto.setPassengerNbr(r.getPassengerNbr());
        dto.setArrivalDate(r.getArrivalDate());
        dto.setStatut(r.getStatut());

        // Infos lieu de départ (anciennement hôtel)
        if (r.getLieuDepart() != null) {
            dto.setHotelName(r.getLieuDepart().getLibelle());
        }

        // Infos véhicule (peut être null si non assigné)
        if (r.getVehicule() != null) {
            dto.setVehiculeId(r.getVehicule().getId());
            dto.setVehiculeReference(r.getVehicule().getReference());
            dto.setVehiculeNbPlace(r.getVehicule().getNbPlace());
            if (r.getVehicule().getTypeCarburant() != null) {
                dto.setVehiculeTypeCarburant(r.getVehicule().getTypeCarburant().name());
            }
        }

        // Infos lieu (peut être null)
        if (r.getLieuDestination() != null) {
            dto.setLieuId(r.getLieuDestination().getId());
            dto.setLieuCode(r.getLieuDestination().getCode());
            dto.setLieuLibelle(r.getLieuDestination().getLibelle());
        }

        // Horaires
        dto.setHeureDepart(r.getHeureDepart());
        dto.setHeureArrivee(r.getHeureArrivee());
        dto.setHeureRetour(r.getHeureRetour());

        return dto;
    }

    /**
     * Classe interne pour retourner le résultat du planning.
     */
    public static class PlanningResult {
        private final List<PlanningDTO> planningLines;
        private final List<PlanningDTO> unassignedReservations;

        public PlanningResult(List<PlanningDTO> planningLines, List<PlanningDTO> unassignedReservations) {
            this.planningLines = planningLines;
            this.unassignedReservations = unassignedReservations;
        }

        public List<PlanningDTO> getPlanningLines() {
            return planningLines;
        }

        public List<PlanningDTO> getUnassignedReservations() {
            return unassignedReservations;
        }
    }
}
