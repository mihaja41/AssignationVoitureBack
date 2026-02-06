package  main.java.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "reservation")
public class Reservation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 🔗 Relation ManyToOne vers Hotel
    @ManyToOne
    @JoinColumn(name = "hotel_id", nullable = false)
    private Hotel hotel;

    @Column(name = "customer_id", nullable = false)
    private Long customerId;

    @Column(name = "passenger_nbr", nullable = false)
    private int passengerNbr;

    @Column(name = "arrival_date", nullable = false)
    private LocalDateTime arrivalDate;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    // 🔹 Initialisation automatique de created_at
    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    // 🔹 Constructeurs
    public Reservation() {}

    public Reservation(Hotel hotel, Long customerId, int passengerNbr, LocalDateTime arrivalDate) {
        this.hotel = hotel;
        this.customerId = customerId;
        this.passengerNbr = passengerNbr;
        this.arrivalDate = arrivalDate;
    }

    // 🔹 Getters & Setters
    public Long getId() {
        return id;
    }

    public Hotel getHotel() {
        return hotel;
    }

    public void setHotel(Hotel hotel) {
        this.hotel = hotel;
    }

    public Long getCustomerId() {
        return customerId;
    }

    public void setCustomerId(Long customerId) {
        this.customerId = customerId;
    }

    public int getPassengerNbr() {
        return passengerNbr;
    }

    public void setPassengerNbr(int passengerNbr) {
        if (passengerNbr <= 0) {
            throw new IllegalArgumentException("Passenger number must be greater than 0");
        }
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
}
