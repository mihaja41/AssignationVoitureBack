package  main.java.service;

import main.java.model.Hotel;
import main.java.model.Reservation;
import main.java.repository.HotelRepository;
import main.java.repository.ReservationRepository;

import java.time.LocalDateTime;

public class ReservationService {

    private final HotelRepository hotelRepository = new HotelRepository();
    private final ReservationRepository reservationRepository = new ReservationRepository();

    public void createReservation(
            Long hotelId,
            Long customerId,
            int passengerNbr,
            LocalDateTime arrivalDate
    ) {

        //Vérifier hôtel
        Hotel hotel = hotelRepository.findById(hotelId);
        if (hotel == null) {
            throw new IllegalArgumentException("Hotel not found");
        }

        //Créer l’objet métier
        Reservation reservation = new Reservation();
        reservation.setHotel(hotel);
        reservation.setCustomerId(customerId);
        reservation.setPassengerNbr(passengerNbr);
        reservation.setArrivalDate(arrivalDate);

        //Sauvegarder
        reservationRepository.save(reservation);
    }
}
