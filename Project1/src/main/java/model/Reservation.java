package model;

import java.time.LocalDateTime;

public class Reservation {
    private Long id;
    private Hotel hotel;
    private String customerId;  // ← Changé de Integer à String
    private Integer passengerNbr;
    private LocalDateTime arrivalDate;
    private LocalDateTime createdAt;

    public Reservation() {}

    public Reservation(Hotel hotel, String customerId, Integer passengerNbr, LocalDateTime arrivalDate) {
        this.hotel = hotel;
        this.customerId = customerId;
        this.passengerNbr = passengerNbr;
        this.arrivalDate = arrivalDate;
    }

    // Getters & Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Hotel getHotel() {
        return hotel;
    }

    public void setHotel(Hotel hotel) {
        this.hotel = hotel;
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
}