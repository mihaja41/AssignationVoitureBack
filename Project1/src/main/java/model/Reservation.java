package model;

import java.time.LocalDateTime;

public class Reservation {
    private Long id;
    private Lieu lieuDepart;
    private String customerId;
    private Integer passengerNbr;
    private LocalDateTime arrivalDate;
    private LocalDateTime createdAt;
    private Lieu lieuDestination;

    public Reservation() {}

    public Reservation(Lieu lieuDepart, String customerId, Integer passengerNbr, LocalDateTime arrivalDate) {
        this.lieuDepart = lieuDepart;
        this.customerId = customerId;
        this.passengerNbr = passengerNbr;
        this.arrivalDate = arrivalDate;
    }

    public Reservation(Lieu lieuDepart, String customerId, Integer passengerNbr, LocalDateTime arrivalDate,
                       Lieu lieuDestination) {
        this.lieuDepart = lieuDepart;
        this.customerId = customerId;
        this.passengerNbr = passengerNbr;
        this.arrivalDate = arrivalDate;
        this.lieuDestination = lieuDestination;
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
}