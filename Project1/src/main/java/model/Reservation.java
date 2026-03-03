package model;

import java.time.LocalDateTime;

public class Reservation {
    private Long id;
    private Lieu lieuDepart;
    private String customerId;  // ← Changé de Integer à String
    private Integer passengerNbr;
    private LocalDateTime arrivalDate;
    private LocalDateTime createdAt;
    private Lieu lieuDestination;
    private Vehicule vehicule;
    private String statut;
    private LocalDateTime heureDepart;
    private LocalDateTime heureArrivee;
    private LocalDateTime heureRetour;

    public Reservation() {}

    public Reservation(Lieu lieuDepart, String customerId, Integer passengerNbr, LocalDateTime arrivalDate) {
        this.lieuDepart = lieuDepart;
        this.customerId = customerId;
        this.passengerNbr = passengerNbr;
        this.arrivalDate = arrivalDate;
    }

    public Reservation(Lieu lieuDepart, String customerId, Integer passengerNbr, LocalDateTime arrivalDate,
                       Lieu lieuDestination, Vehicule vehicule, String statut,
                       LocalDateTime heureDepart, LocalDateTime heureArrivee, LocalDateTime heureRetour) {
        this.lieuDepart = lieuDepart;
        this.customerId = customerId;
        this.passengerNbr = passengerNbr;
        this.arrivalDate = arrivalDate;
        this.lieuDestination = lieuDestination;
        this.vehicule = vehicule;
        this.statut = statut;
        this.heureDepart = heureDepart;
        this.heureArrivee = heureArrivee;
        this.heureRetour = heureRetour;
    }

    // Getters & Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    /**
     * Alias : getHotel() retourne lieuDepart pour compatibilité frontend
     */
    public Lieu getHotel() {
        return lieuDepart;
    }

    public void setHotel(Lieu lieuDepart) {
        this.lieuDepart = lieuDepart;
    }

    public Lieu getLieuDepart() {
        return lieuDepart;
    }

    public void setLieuDepart(Lieu lieuDepart) {
        this.lieuDepart = lieuDepart;
    }

    public String getCustomerId() {  // ← Changé de Integer à String
        return customerId;
    }

    public void setCustomerId(String customerId) {  // ← Changé de Integer à String
        this.customerId = customerId;
    }

    public Integer getPassengerNbr() {
        return passengerNbr;
    }

    public void setPassengerNbr(Integer passengerNbr) {
        this.passengerNbr = passengerNbr;
    }

    public LocalDateTime getArrivalDate() {
        return arrivalDate;
    }

    public void setArrivalDate(LocalDateTime arrivalDate) {
        this.arrivalDate = arrivalDate;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public Lieu getLieuDestination() {
        return lieuDestination;
    }

    public void setLieuDestination(Lieu lieuDestination) {
        this.lieuDestination = lieuDestination;
    }

    public Vehicule getVehicule() {
        return vehicule;
    }

    public void setVehicule(Vehicule vehicule) {
        this.vehicule = vehicule;
    }

    public String getStatut() {
        return statut;
    }

    public void setStatut(String statut) {
        this.statut = statut;
    }

    public LocalDateTime getHeureDepart() {
        return heureDepart;
    }

    public void setHeureDepart(LocalDateTime heureDepart) {
        this.heureDepart = heureDepart;
    }

    public LocalDateTime getHeureArrivee() {
        return heureArrivee;
    }

    public void setHeureArrivee(LocalDateTime heureArrivee) {
        this.heureArrivee = heureArrivee;
    }

    public LocalDateTime getHeureRetour() {
        return heureRetour;
    }

    public void setHeureRetour(LocalDateTime heureRetour) {
        this.heureRetour = heureRetour;
    }
}