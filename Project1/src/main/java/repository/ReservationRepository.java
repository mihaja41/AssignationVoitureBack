package repository;

import config.DatabaseConnection;
import model.Lieu;
import model.Reservation;
import model.Vehicule;
import model.TypeCarburant;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class ReservationRepository {

    /**
     * Enregistrer une réservation
     */
    public Reservation save(Reservation reservation) throws SQLException {
        String sql = "INSERT INTO reservation (lieu_depart_id, customer_id, passenger_nbr, arrival_date) " +
                     "VALUES (?, ?, ?, ?) RETURNING id, created_at";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, reservation.getLieuDepart().getId());
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
                     "ld.id as lieu_depart_id, ld.libelle as lieu_depart_name " +
                     "FROM reservation r " +
                     "JOIN lieu ld ON r.lieu_depart_id = ld.id " +
                     "ORDER BY r.created_at DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Lieu lieuDepart = new Lieu();
                lieuDepart.setId(rs.getLong("lieu_depart_id"));
                lieuDepart.setLibelle(rs.getString("lieu_depart_name"));

                Reservation reservation = new Reservation();
                reservation.setId(rs.getLong("id"));
                reservation.setLieuDepart(lieuDepart);
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
                     "ld.id as lieu_depart_id, ld.libelle as lieu_depart_name " +
                     "FROM reservation r " +
                     "JOIN lieu ld ON r.lieu_depart_id = ld.id " +
                     "WHERE DATE(r.arrival_date) = DATE(?) " +
                     "ORDER BY r.arrival_date";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setTimestamp(1, Timestamp.valueOf(date));

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Lieu lieuDepart = new Lieu();
                    lieuDepart.setId(rs.getLong("lieu_depart_id"));
                    lieuDepart.setLibelle(rs.getString("lieu_depart_name"));

                    Reservation reservation = new Reservation();
                    reservation.setId(rs.getLong("id"));
                    reservation.setLieuDepart(lieuDepart);
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

    /**
     * Trouver les réservations assignées pour une date donnée (pour le planning).
     * Inclut les infos véhicule et lieu destination.
     */
    public List<Reservation> findAssignedByDate(LocalDateTime date) throws SQLException {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.id, r.customer_id, r.passenger_nbr, r.arrival_date, r.created_at, " +
                     "r.statut, r.heure_depart, r.heure_arrivee, r.heure_retour, " +
                     "ld.id AS lieu_depart_id, ld.libelle AS lieu_depart_name, " +
                     "v.id AS vehicule_id, v.reference AS vehicule_reference, v.nb_place AS vehicule_nb_place, v.type_carburant AS vehicule_type_carburant, " +
                     "l.id AS lieu_id, l.code AS lieu_code, l.libelle AS lieu_libelle " +
                     "FROM reservation r " +
                     "JOIN lieu ld ON r.lieu_depart_id = ld.id " +
                     "LEFT JOIN vehicule v ON r.vehicule_id = v.id " +
                     "LEFT JOIN lieu l ON r.lieu_destination_id = l.id " +
                     "WHERE DATE(r.arrival_date) = DATE(?) " +
                     "AND r.statut = 'ASSIGNE' " +
                     "ORDER BY r.heure_depart ASC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setTimestamp(1, Timestamp.valueOf(date));

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    reservations.add(mapFullReservation(rs));
                }
            }
        }

        return reservations;
    }

    /**
     * Trouver les réservations non assignées pour une date donnée.
     */
    public List<Reservation> findUnassignedByDate(LocalDateTime date) throws SQLException {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.id, r.customer_id, r.passenger_nbr, r.arrival_date, r.created_at, " +
                     "r.statut, r.heure_depart, r.heure_arrivee, r.heure_retour, " +
                     "ld.id AS lieu_depart_id, ld.libelle AS lieu_depart_name, " +
                     "v.id AS vehicule_id, v.reference AS vehicule_reference, v.nb_place AS vehicule_nb_place, v.type_carburant AS vehicule_type_carburant, " +
                     "l.id AS lieu_id, l.code AS lieu_code, l.libelle AS lieu_libelle " +
                     "FROM reservation r " +
                     "JOIN lieu ld ON r.lieu_depart_id = ld.id " +
                     "LEFT JOIN vehicule v ON r.vehicule_id = v.id " +
                     "LEFT JOIN lieu l ON r.lieu_destination_id = l.id " +
                     "WHERE DATE(r.arrival_date) = DATE(?) " +
                     "AND (r.statut = 'NON_ASSIGNE' OR r.statut IS NULL) " +
                     "ORDER BY r.arrival_date ASC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setTimestamp(1, Timestamp.valueOf(date));

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    reservations.add(mapFullReservation(rs));
                }
            }
        }

        return reservations;
    }

    /**
     * Mettre à jour l'assignation d'une réservation (véhicule, statut, heures)
     */
    public void updateAssignment(Long reservationId, Long vehiculeId, String statut,
                                  LocalDateTime heureDepart, LocalDateTime heureArrivee,
                                  LocalDateTime heureRetour) throws SQLException {
        String sql = "UPDATE reservation SET vehicule_id = ?, statut = ?, " +
                     "heure_depart = ?, heure_arrivee = ?, heure_retour = ? " +
                     "WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            if (vehiculeId != null) {
                stmt.setLong(1, vehiculeId);
            } else {
                stmt.setNull(1, Types.BIGINT);
            }
            stmt.setString(2, statut);
            stmt.setTimestamp(3, heureDepart != null ? Timestamp.valueOf(heureDepart) : null);
            stmt.setTimestamp(4, heureArrivee != null ? Timestamp.valueOf(heureArrivee) : null);
            stmt.setTimestamp(5, heureRetour != null ? Timestamp.valueOf(heureRetour) : null);
            stmt.setLong(6, reservationId);

            stmt.executeUpdate();
        }
    }

    /**
     * Trouver toutes les réservations pour une date (assignées + non assignées) avec tous les détails
     */
    public List<Reservation> findAllByDate(LocalDateTime date) throws SQLException {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.id, r.customer_id, r.passenger_nbr, r.arrival_date, r.created_at, " +
                     "r.statut, r.heure_depart, r.heure_arrivee, r.heure_retour, " +
                     "ld.id AS lieu_depart_id, ld.libelle AS lieu_depart_name, " +
                     "v.id AS vehicule_id, v.reference AS vehicule_reference, v.nb_place AS vehicule_nb_place, v.type_carburant AS vehicule_type_carburant, " +
                     "l.id AS lieu_id, l.code AS lieu_code, l.libelle AS lieu_libelle " +
                     "FROM reservation r " +
                     "JOIN lieu ld ON r.lieu_depart_id = ld.id " +
                     "LEFT JOIN vehicule v ON r.vehicule_id = v.id " +
                     "LEFT JOIN lieu l ON r.lieu_destination_id = l.id " +
                     "WHERE DATE(r.arrival_date) = DATE(?) " +
                     "ORDER BY r.arrival_date ASC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setTimestamp(1, Timestamp.valueOf(date));

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    reservations.add(mapFullReservation(rs));
                }
            }
        }

        return reservations;
    }

    /**
     * Mapper un ResultSet complet (avec jointures vehicule et lieu) vers un objet Reservation
     */
    private Reservation mapFullReservation(ResultSet rs) throws SQLException {
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
        reservation.setStatut(rs.getString("statut"));

        Timestamp heureDepartTs = rs.getTimestamp("heure_depart");
        if (heureDepartTs != null) {
            reservation.setHeureDepart(heureDepartTs.toLocalDateTime());
        }
        Timestamp heureArriveeTs = rs.getTimestamp("heure_arrivee");
        if (heureArriveeTs != null) {
            reservation.setHeureArrivee(heureArriveeTs.toLocalDateTime());
        }
        Timestamp heureRetourTs = rs.getTimestamp("heure_retour");
        if (heureRetourTs != null) {
            reservation.setHeureRetour(heureRetourTs.toLocalDateTime());
        }

        // Véhicule (peut être null si non assigné)
        Long vehiculeId = rs.getLong("vehicule_id");
        if (!rs.wasNull()) {
            Vehicule vehicule = new Vehicule();
            vehicule.setId(vehiculeId);
            vehicule.setReference(rs.getString("vehicule_reference"));
            vehicule.setNbPlace(rs.getInt("vehicule_nb_place"));
            String typeCarb = rs.getString("vehicule_type_carburant");
            if (typeCarb != null) {
                vehicule.setTypeCarburant(TypeCarburant.valueOf(typeCarb));
            }
            reservation.setVehicule(vehicule);
        }

        // Lieu destination (peut être null)
        Long lieuId = rs.getLong("lieu_id");
        if (!rs.wasNull()) {
            Lieu lieu = new Lieu();
            lieu.setId(lieuId);
            lieu.setCode(rs.getString("lieu_code"));
            lieu.setLibelle(rs.getString("lieu_libelle"));
            reservation.setLieuDestination(lieu);
        }

        return reservation;
    }
}