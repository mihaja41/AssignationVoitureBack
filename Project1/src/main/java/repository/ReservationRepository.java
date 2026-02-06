package repository;

import config.DatabaseConnection;
import model.Hotel;
import model.Reservation;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class ReservationRepository {

    /**
     * Enregistrer une réservation
     */
    public Reservation save(Reservation reservation) throws SQLException {
        String sql = "INSERT INTO reservation (hotel_id, customer_id, passenger_nbr, arrival_date) " +
                     "VALUES (?, ?, ?, ?) RETURNING id, created_at";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, reservation.getHotel().getId());
            stmt.setString(2, reservation.getCustomerId());  // ← Changé de setInt à setString
            stmt.setInt(3, reservation.getPassengerNbr());
            stmt.setTimestamp(4, Timestamp.valueOf(reservation.getArrivalDate()));

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    reservation.setId(rs.getLong("id"));
                    reservation.setCreatedAt(rs.getTimestamp("created_at").toLocalDateTime());
                }
            }
        }

        return reservation;
    }

    /**
     * Récupérer toutes les réservations
     */
    public List<Reservation> findAll() throws SQLException {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.id, r.customer_id, r.passenger_nbr, r.arrival_date, r.created_at, " +
                     "h.id as hotel_id, h.name as hotel_name " +
                     "FROM reservation r " +
                     "JOIN hotel h ON r.hotel_id = h.id " +
                     "ORDER BY r.created_at DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Hotel hotel = new Hotel();
                hotel.setId(rs.getLong("hotel_id"));
                hotel.setName(rs.getString("hotel_name"));

                Reservation reservation = new Reservation();
                reservation.setId(rs.getLong("id"));
                reservation.setHotel(hotel);
                reservation.setCustomerId(rs.getString("customer_id"));  // ← Changé de getInt à getString
                reservation.setPassengerNbr(rs.getInt("passenger_nbr"));
                reservation.setArrivalDate(rs.getTimestamp("arrival_date").toLocalDateTime());
                reservation.setCreatedAt(rs.getTimestamp("created_at").toLocalDateTime());

                reservations.add(reservation);
            }
        }

        return reservations;
    }

    /**
     * Trouver les réservations par date
     */
    public List<Reservation> findByDate(LocalDateTime date) throws SQLException {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.id, r.customer_id, r.passenger_nbr, r.arrival_date, r.created_at, " +
                     "h.id as hotel_id, h.name as hotel_name " +
                     "FROM reservation r " +
                     "JOIN hotel h ON r.hotel_id = h.id " +
                     "WHERE DATE(r.arrival_date) = DATE(?) " +
                     "ORDER BY r.arrival_date";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setTimestamp(1, Timestamp.valueOf(date));

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Hotel hotel = new Hotel();
                    hotel.setId(rs.getLong("hotel_id"));
                    hotel.setName(rs.getString("hotel_name"));

                    Reservation reservation = new Reservation();
                    reservation.setId(rs.getLong("id"));
                    reservation.setHotel(hotel);
                    reservation.setCustomerId(rs.getString("customer_id"));  // ← Changé de getInt à getString
                    reservation.setPassengerNbr(rs.getInt("passenger_nbr"));
                    reservation.setArrivalDate(rs.getTimestamp("arrival_date").toLocalDateTime());
                    reservation.setCreatedAt(rs.getTimestamp("created_at").toLocalDateTime());

                    reservations.add(reservation);
                }
            }
        }

        return reservations;
    }
}