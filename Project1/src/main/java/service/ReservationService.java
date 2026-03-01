package service;

import model.Lieu;
import model.Reservation;
import repository.LieuRepository;
import repository.ReservationRepository;

import java.sql.SQLException;
import java.time.LocalDateTime;

public class ReservationService {

    private final LieuRepository lieuRepository = new LieuRepository();
    private final ReservationRepository reservationRepository = new ReservationRepository();

    /**
     * Créer une réservation avec validation métier
     */
    public Reservation createReservation(Long hotelId, String customerId, Integer passengerNbr, LocalDateTime arrivalDate) 
            throws SQLException, IllegalArgumentException {

        // Validation 1 : Vérifier que le lieu existe
        Lieu lieu = lieuRepository.findById(hotelId);
        if (lieu == null) {
            throw new IllegalArgumentException("Le lieu avec l'ID " + hotelId + " n'existe pas");
        }

        // Validation 2 : Customer ID obligatoire
        if (customerId == null || customerId.trim().isEmpty()) {
            throw new IllegalArgumentException("L'ID client est obligatoire");
        }

        // Validation 3 : Nombre de passagers doit être positif
        if (passengerNbr == null || passengerNbr <= 0) {
            throw new IllegalArgumentException("Le nombre de passagers doit être supérieur à 0");
        }

        // Validation 4 : Date d'arrivée obligatoire
        if (arrivalDate == null) {
            throw new IllegalArgumentException("La date d'arrivée est obligatoire");
        }

        // Validation 5 : Date d'arrivée ne peut pas être dans le passé
        if (arrivalDate.isBefore(LocalDateTime.now())) {
            throw new IllegalArgumentException("La date d'arrivée ne peut pas être dans le passé");
        }

        // Créer la réservation
        Reservation reservation = new Reservation(lieu, customerId, passengerNbr, arrivalDate);

        // Sauvegarder
        return reservationRepository.save(reservation);
    }
}