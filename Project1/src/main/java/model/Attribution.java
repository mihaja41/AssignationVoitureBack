package model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Représente une attribution de véhicule à une ou plusieurs réservations regroupées (résultat du planning).
 * Objet en mémoire uniquement — PAS de table en base de données.
 *
 * Sprint 4 – Regroupement :
 *   Un même véhicule peut transporter plusieurs réservations si :
 *     - même date et heure de départ
 *     - même lieu de départ (aéroport)
 *     - total passagers <= nb_places du véhicule
 *
 * Calcul des horaires :
 *   - dateHeureDepart = reservation.arrivalDate
 *   - duree = distanceAllerRetour / vitesseMoyenne
 *   - dateHeureRetour = dateHeureDepart + duree
 */
public class Attribution {
    private Vehicule vehicule;
    private Reservation reservation;                         // réservation principale (backward compat)
    private List<Reservation> reservations = new ArrayList<>();  // toutes les réservations regroupées
    private LocalDateTime dateHeureDepart;
    private LocalDateTime dateHeureRetour;
    private BigDecimal distanceKm;            // distance aller simple (calculée depuis table distance)
    private BigDecimal distanceAllerRetourKm;  // distance aller-retour (= distanceKm × 2)
    private String statut;                     // "ASSIGNE"

    public Attribution() {}

    // ========== Regroupement ==========

    /**
     * Ajouter une réservation au regroupement de ce véhicule.
     */
    public void addReservation(Reservation r) {
        this.reservations.add(r);
    }

    /**
     * Retourne toutes les réservations regroupées dans ce véhicule.
     */
    public List<Reservation> getReservations() {
        return reservations;
    }

    /**
     * Nombre total de passagers dans ce véhicule (somme de toutes les réservations regroupées).
     */
    public int getTotalPassengers() {
        return reservations.stream().mapToInt(Reservation::getPassengerNbr).sum();
    }

    /**
     * Nombre de places restantes dans le véhicule après regroupement.
     */
    public int getPlacesRestantes() {
        if (vehicule == null) return 0;
        return vehicule.getNbPlace() - getTotalPassengers();
    }

    // ========== Getters & Setters ==========

    public Vehicule getVehicule() {
        return vehicule;
    }

    public void setVehicule(Vehicule vehicule) {
        this.vehicule = vehicule;
    }

    /**
     * Retourne la réservation principale (la première assignée).
     * Conservé pour compatibilité avec l'existant.
     */
    public Reservation getReservation() {
        return reservation;
    }

    public void setReservation(Reservation reservation) {
        this.reservation = reservation;
    }

    public LocalDateTime getDateHeureDepart() {
        return dateHeureDepart;
    }

    public void setDateHeureDepart(LocalDateTime dateHeureDepart) {
        this.dateHeureDepart = dateHeureDepart;
    }

    public LocalDateTime getDateHeureRetour() {
        return dateHeureRetour;
    }

    public void setDateHeureRetour(LocalDateTime dateHeureRetour) {
        this.dateHeureRetour = dateHeureRetour;
    }

    public BigDecimal getDistanceKm() {
        return distanceKm;
    }

    public void setDistanceKm(BigDecimal distanceKm) {
        this.distanceKm = distanceKm;
    }

    public BigDecimal getDistanceAllerRetourKm() {
        return distanceAllerRetourKm;
    }

    public void setDistanceAllerRetourKm(BigDecimal distanceAllerRetourKm) {
        this.distanceAllerRetourKm = distanceAllerRetourKm;
    }

    public String getStatut() {
        return statut;
    }

    public void setStatut(String statut) {
        this.statut = statut;
    }
}
