package model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Représente une attribution de véhicule à une réservation (résultat du planning).
 * Objet en mémoire uniquement — PAS de table en base de données.
 * 
 * Calcul des horaires :
 *   - dateHeureDepart = reservation.arrivalDate
 *   - duree = (distanceAllerRetour / vitesseMoyenne) + tempsAttente
 *   - dateHeureRetour = dateHeureDepart + duree
 */
public class Attribution {
    private Vehicule vehicule;
    private Reservation reservation;
    private LocalDateTime dateHeureDepart;
    private LocalDateTime dateHeureRetour;
    private BigDecimal distanceKm;            // distance aller simple (calculée depuis table distance)
    private BigDecimal distanceAllerRetourKm;  // distance aller-retour (= distanceKm × 2)
    private String statut;                     // "ASSIGNE"

    public Attribution() {}

    // Getters & Setters
    public Vehicule getVehicule() {
        return vehicule;
    }

    public void setVehicule(Vehicule vehicule) {
        this.vehicule = vehicule;
    }

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
