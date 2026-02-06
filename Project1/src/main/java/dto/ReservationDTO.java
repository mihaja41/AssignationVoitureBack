package dto;

import java.time.LocalDateTime;
public class ReservationDTO {

    private Long id;
    private String hotelName;
    private String customerId;
    private int passengerNbr;
    private LocalDateTime arrivalDate;

    public Long getId() {
        return id;
    }
    public void setId(Long id) {
        this.id = id;
    }
    public String getHotelName() {
        return hotelName;
    }
    public void setHotelName(String hotelName) {
        this.hotelName = hotelName;
    }
    public String getCustomerId() {
        return customerId;
    }
    public void setCustomerId(String customerId) {
        this.customerId = customerId;
    }
    public int getPassengerNbr() {
        return passengerNbr;
    }
    public void setPassengerNbr(int passengerNbr) {
        this.passengerNbr = passengerNbr;
    }
    public LocalDateTime getArrivalDate() {
        return arrivalDate;
    }
    public void setArrivalDate(LocalDateTime arrivalDate) {
        this.arrivalDate = arrivalDate;
    }

    // getters / setters
}
