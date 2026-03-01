package dto;

import java.time.LocalDateTime;

/**
 * DTO représentant une ligne du planning d'attribution véhicule.
 * Colonnes: Véhicule | Réservation | Lieu | DateHeureDepart | DateHeureRetour
 */
public class PlanningDTO {

    // Infos véhicule
    private Long vehiculeId;
    private String vehiculeReference;
    private Integer vehiculeNbPlace;
    private String vehiculeTypeCarburant;

    // Infos réservation
    private Long reservationId;
    private String customerId;
    private Integer passengerNbr;
    private String hotelName;
    private LocalDateTime arrivalDate;

    // Infos lieu
    private Long lieuId;
    private String lieuCode;
    private String lieuLibelle;

    // Horaires
    private LocalDateTime heureDepart;
    private LocalDateTime heureArrivee;
    private LocalDateTime heureRetour;

    // Statut
    private String statut;

    public PlanningDTO() {}

    // === Getters & Setters ===

    public Long getVehiculeId() {
        return vehiculeId;
    }

    public void setVehiculeId(Long vehiculeId) {
        this.vehiculeId = vehiculeId;
    }

    public String getVehiculeReference() {
        return vehiculeReference;
    }

    public void setVehiculeReference(String vehiculeReference) {
        this.vehiculeReference = vehiculeReference;
    }

    public Integer getVehiculeNbPlace() {
        return vehiculeNbPlace;
    }

    public void setVehiculeNbPlace(Integer vehiculeNbPlace) {
        this.vehiculeNbPlace = vehiculeNbPlace;
    }

    public String getVehiculeTypeCarburant() {
        return vehiculeTypeCarburant;
    }

    public void setVehiculeTypeCarburant(String vehiculeTypeCarburant) {
        this.vehiculeTypeCarburant = vehiculeTypeCarburant;
    }

    public Long getReservationId() {
        return reservationId;
    }

    public void setReservationId(Long reservationId) {
        this.reservationId = reservationId;
    }

    public String getCustomerId() {
        return customerId;
    }

    public void setCustomerId(String customerId) {
        this.customerId = customerId;
    }

    public Integer getPassengerNbr() {
        return passengerNbr;
    }

    public void setPassengerNbr(Integer passengerNbr) {
        this.passengerNbr = passengerNbr;
    }

    public String getHotelName() {
        return hotelName;
    }

    public void setHotelName(String hotelName) {
        this.hotelName = hotelName;
    }

    public LocalDateTime getArrivalDate() {
        return arrivalDate;
    }

    public void setArrivalDate(LocalDateTime arrivalDate) {
        this.arrivalDate = arrivalDate;
    }

    public Long getLieuId() {
        return lieuId;
    }

    public void setLieuId(Long lieuId) {
        this.lieuId = lieuId;
    }

    public String getLieuCode() {
        return lieuCode;
    }

    public void setLieuCode(String lieuCode) {
        this.lieuCode = lieuCode;
    }

    public String getLieuLibelle() {
        return lieuLibelle;
    }

    public void setLieuLibelle(String lieuLibelle) {
        this.lieuLibelle = lieuLibelle;
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

    public String getStatut() {
        return statut;
    }

    public void setStatut(String statut) {
        this.statut = statut;
    }
}
