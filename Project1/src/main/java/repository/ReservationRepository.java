package repository;

import config.DatabaseConnection;
import model.Lieu;
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
        String sql = "INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date, lieu_destination_id) " +
                     "VALUES (?, ?, ?, ?, ?) RETURNING id, created_at";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, reservation.getLieuDepart().getId());
            stmt.setString(2, reservation.getCustomerId());
            stmt.setInt(3, reservation.getPassengerNbr());
            stmt.setTimestamp(4, Timestamp.valueOf(reservation.getArrivalDate()));
            if (reservation.getLieuDestination() != null) {
                stmt.setLong(5, reservation.getLieuDestination().getId());
            } else {
                stmt.setNull(5, Types.BIGINT);
            }

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
                     "ld.id as lieu_depart_id, ld.libelle as lieu_depart_name, " +
                     "l.id AS lieu_dest_id, l.code AS lieu_dest_code, l.libelle AS lieu_dest_libelle " +
                     "FROM reservation r " +
                     "JOIN lieu ld ON r.lieu_depart_id = ld.id " +
                     "LEFT JOIN lieu l ON r.lieu_destination_id = l.id " +
                     "ORDER BY r.created_at DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                reservations.add(mapReservation(rs));
            }
        }

        return reservations;
    }

    /**
     * Trouver les réservations par date (toutes les réservations pour cette date)
     */
    public List<Reservation> findByDate(LocalDateTime date) throws SQLException {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.id, r.customer_id, r.passenger_nbr, r.arrival_date, r.created_at, " +
                     "ld.id as lieu_depart_id, ld.libelle as lieu_depart_name, " +
                     "l.id AS lieu_dest_id, l.code AS lieu_dest_code, l.libelle AS lieu_dest_libelle " +
                     "FROM reservation r " +
                     "JOIN lieu ld ON r.lieu_depart_id = ld.id " +
                     "LEFT JOIN lieu l ON r.lieu_destination_id = l.id " +
                     "WHERE DATE(r.arrival_date) = DATE(?) " +
                     "ORDER BY r.arrival_date ASC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setTimestamp(1, Timestamp.valueOf(date));

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    reservations.add(mapReservation(rs));
                }
            }
        }

        return reservations;
    }

    /**
     * Trouver une réservation par ID
     */
    public Reservation findById(Long id) throws SQLException {
        String sql = "SELECT r.id, r.customer_id, r.passenger_nbr, r.arrival_date, r.created_at, " +
                     "ld.id as lieu_depart_id, ld.libelle as lieu_depart_name, " +
                     "l.id AS lieu_dest_id, l.code AS lieu_dest_code, l.libelle AS lieu_dest_libelle " +
                     "FROM reservation r " +
                     "JOIN lieu ld ON r.lieu_depart_id = ld.id " +
                     "LEFT JOIN lieu l ON r.lieu_destination_id = l.id " +
                     "WHERE r.id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, id);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapReservation(rs);
                }
            }
        }

        return null;
    }

    /**
     * Mapper un ResultSet vers un objet Reservation
     */
    private Reservation mapReservation(ResultSet rs) throws SQLException {
        Lieu lieuDepart = new Lieu();
        lieuDepart.setId(rs.getLong("lieu_depart_id"));
        lieuDepart.setLibelle(rs.getString("lieu_depart_name"));

        Reservation reservation = new Reservation();
        reservation.setId(rs.getLong("id"));
        reservation.setLieuDepart(lieuDepart);
        reservation.setCustomerId(rs.getString("customer_id"));
        reservation.setPassengerNbr(rs.getInt("passenger_nbr"));
        reservation.setArrivalDate(rs.getTimestamp("arrival_date").toLocalDateTime());
        Timestamp createdTs = rs.getTimestamp("created_at");
        if (createdTs != null) {
            reservation.setCreatedAt(createdTs.toLocalDateTime());
        }

        // Lieu destination (peut être null)
        Long lieuDestId = rs.getLong("lieu_dest_id");
        if (!rs.wasNull()) {
            Lieu lieuDest = new Lieu();
            lieuDest.setId(lieuDestId);
            lieuDest.setCode(rs.getString("lieu_dest_code"));
            lieuDest.setLibelle(rs.getString("lieu_dest_libelle"));
            reservation.setLieuDestination(lieuDest);
        }

        return reservation;
    }
}