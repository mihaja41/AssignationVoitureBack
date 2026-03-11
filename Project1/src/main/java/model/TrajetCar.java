package model;

public class TrajetCar {
    private Lieu reservationFrom ; 
    private Lieu reservationTo ; 
    private double distance ; 
    private double durre ;

    public TrajetCar( Lieu reservationFrom1 ,Lieu reservationTo1 , double distance1 , double durre1 ){
        this.reservationFrom = reservationFrom1 ; 
        this.reservationTo = reservationTo1 ; 
        this.distance =  distance1 ; 
        this.durre= durre1; 
    }
    // Getter and Setter
    public Lieu getReservationFrom() {
        return reservationFrom;
    }
    public void setReservationFrom(Lieu reservationFrom) {
        this.reservationFrom = reservationFrom;
    }
    public Lieu getReservationTo() {
        return reservationTo;
    }
    public void setReservationTo(Lieu reservationTo) {
        this.reservationTo = reservationTo;
    }
    public double getDistance() {
        return distance;
    }
    public void setDistance(double distance) {
        this.distance = distance;
    }
    public double getDurre() {
        return durre;
    }
    public void setDurre(double durre) {
        this.durre = durre;
    }

    public String toString() {
        return "TrajetCar{" +
                "reservationFrom=" + reservationFrom.getLibelle() +
                ", reservationTo=" + reservationTo.getLibelle() +
                ", distance=" + distance +
                ", durre=" + durre +
                '}';
    }
}