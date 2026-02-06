package  main.java.repository;

import  main.java.config.DatabaseConnection;
import  main.java.model.Reservation;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;

public class ReservationRepository {

    public void save(Reservation reservation) {

        String sql = """
            INSERT INTO reservation
            (hotel_id, customer_id, passenger_nbr, arrival_date)
            VALUES (?, ?, ?, ?)
        """;

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setLong(1, reservation.getHotel().getId());
            ps.setLong(2, reservation.getCustomerId());
            ps.setInt(3, reservation.getPassengerNbr());
            ps.setTimestamp(4,
                    Timestamp.valueOf(reservation.getArrivalDate()));

            ps.executeUpdate();

        } catch (SQLException e) {
            throw new RuntimeException("Error saving reservation", e);
        }
    }
}
