package repository;

import config.DatabaseConnection;
import model.Attribution;
import model.Reservation;
import model.Vehicule;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Repository pour la gestion des attributions en base de données.
 * Sprint 7 - Developer 2 (ETU003283): Support de la division avec nb_passagers_assignes
 * Sprint 5/6 - Developer 2 (ETU003283)
 */
public class AttributionRepository {

    private final VehiculeRepository vehiculeRepository = new VehiculeRepository();
    private final ReservationRepository reservationRepository = new ReservationRepository();

    /**
     * Enregistrer une attribution en base de données.
     * Sprint 7: Inclut nb_passagers_assignes pour supporter la division
     */
    public Attribution save(Attribution attribution) throws SQLException {
        String sql = "INSERT INTO attribution (reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes) " +
                     "VALUES (?, ?, ?, ?, ?, ?) RETURNING id, created_at, updated_at";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, attribution.getReservation().getId());
            stmt.setLong(2, attribution.getVehicule().getId());
            stmt.setTimestamp(3, Timestamp.valueOf(attribution.getDateHeureDepart()));
            stmt.setTimestamp(4, Timestamp.valueOf(attribution.getDateHeureRetour()));
            stmt.setString(5, attribution.getStatut());

            // Sprint 7: Inclure nb_passagers_assignes
            if (attribution.getNbPassagersAssignes() != null) {
                stmt.setInt(6, attribution.getNbPassagersAssignes());
            } else {
                // Par défaut: nombre total de passagers de la réservation
                stmt.setInt(6, attribution.getReservation().getPassengerNbr());
            }

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    attribution.setId(rs.getLong("id"));
                }
            }
        }

        return attribution;
    }

    /**
     * Enregistrer plusieurs attributions (pour un véhicule avec plusieurs réservations regroupées).
     * Sprint 7: Inclut nb_passagers_assignes pour supporter la division
     *
     * A.3 - CORRECTION: nbPassagersAssignes s'applique UNIQUEMENT à la réservation divisée
     * Pour les réservations regroupées, toujours utiliser reservation.getPassengerNbr()
     */
    public void saveAll(Attribution attribution) throws SQLException {
        String sql = "INSERT INTO attribution (reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes) " +
                     "VALUES (?, ?, ?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            Reservation reservationPrincipale = attribution.getReservation();

            // Enregistrer une ligne pour chaque réservation du regroupement
            for (Reservation reservation : attribution.getReservations()) {
                stmt.setLong(1, reservation.getId());
                stmt.setLong(2, attribution.getVehicule().getId());
                stmt.setTimestamp(3, Timestamp.valueOf(attribution.getDateHeureDepart()));
                stmt.setTimestamp(4, Timestamp.valueOf(attribution.getDateHeureRetour()));
                stmt.setString(5, attribution.getStatut());

                // Sprint 7: A.3 - CORRECTION
                // nbPassagersAssignes s'applique SEULEMENT à la réservation principale (divisée)
                // Pour les autres (regroupées), utiliser toujours leur nombre de passagers
                if (reservation.getId().equals(reservationPrincipale.getId()) &&
                    attribution.getNbPassagersAssignes() != null) {
                    // Réservation principale avec division
                    stmt.setInt(6, attribution.getNbPassagersAssignes());
                } else {
                    // Réservation regroupée OU pas de division
                    stmt.setInt(6, reservation.getPassengerNbr());
                }

                stmt.addBatch();
            }

            stmt.executeBatch();
        }
    }

    /**
     * Récupérer toutes les attributions.
     */
    public List<Attribution> findAll() throws SQLException {
        List<Attribution> attributions = new ArrayList<>();
        String sql = "SELECT id, reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes, created_at " +
                     "FROM attribution ORDER BY date_heure_depart";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Attribution attribution = mapAttribution(rs);
                attributions.add(attribution);
            }
        }

        return attributions;
    }

    /**
     * Récupérer les attributions pour une date donnée.
     */
    public List<Attribution> findByDate(LocalDateTime date) throws SQLException {
        List<Attribution> attributions = new ArrayList<>();
        String sql = "SELECT id, reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes, created_at " +
                     "FROM attribution WHERE DATE(date_heure_depart) = DATE(?) ORDER BY date_heure_depart";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setTimestamp(1, Timestamp.valueOf(date));

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Attribution attribution = mapAttribution(rs);
                    attributions.add(attribution);
                }
            }
        }

        return attributions;
    }

    /**
     * Récupérer les attributions pour un véhicule donné.
     */
    public List<Attribution> findByVehiculeId(Long vehiculeId) throws SQLException {
        List<Attribution> attributions = new ArrayList<>();
        String sql = "SELECT id, reservation_id, vehicule_id, date_heure_depart, date_heure_retour, statut, nb_passagers_assignes, created_at " +
                     "FROM attribution WHERE vehicule_id = ? ORDER BY date_heure_depart";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, vehiculeId);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Attribution attribution = mapAttribution(rs);
                    attributions.add(attribution);
                }
            }
        }

        return attributions;
    }

    /**
     * Compter le nombre de trajets effectués par chaque véhicule.
     * Sprint 5/6 - Developer 2 (ETU003283)
     *
     * @return Map avec vehicule_id comme clé et nombre de trajets comme valeur
     */
    public Map<Long, Integer> countTrajetsParVehicule() throws SQLException {
        Map<Long, Integer> trajets = new HashMap<>();
        String sql = "SELECT vehicule_id, COUNT(DISTINCT date_heure_depart) as nb_trajets " +
                     "FROM attribution GROUP BY vehicule_id";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                trajets.put(rs.getLong("vehicule_id"), rs.getInt("nb_trajets"));
            }
        }

        return trajets;
    }

    /**
     * Récupérer la dernière heure de retour pour un véhicule.
     * Permet de savoir quand le véhicule sera disponible.
     */
    public LocalDateTime getLastHeureRetour(Long vehiculeId) throws SQLException {
        String sql = "SELECT MAX(date_heure_retour) as last_retour FROM attribution WHERE vehicule_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, vehiculeId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next() && rs.getTimestamp("last_retour") != null) {
                    return rs.getTimestamp("last_retour").toLocalDateTime();
                }
            }
        }

        return null; // Véhicule jamais utilisé
    }

    /**
     * Récupérer les véhicules qui reviennent dans une fenêtre de temps.
     * Sprint 5/6 - Developer 2 (ETU003283)
     *
     * @param startTime Début de la fenêtre
     * @param endTime Fin de la fenêtre
     * @return Map avec vehicule_id comme clé et heure_retour comme valeur
     */
    public Map<Long, LocalDateTime> getVehiculesRevenant(LocalDateTime startTime, LocalDateTime endTime) throws SQLException {
        Map<Long, LocalDateTime> vehiculesRevenant = new HashMap<>();
        String sql = "SELECT vehicule_id, MAX(date_heure_retour) as heure_retour " +
                     "FROM attribution " +
                     "WHERE date_heure_retour >= ? AND date_heure_retour <= ? " +
                     "GROUP BY vehicule_id";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setTimestamp(1, Timestamp.valueOf(startTime));
            stmt.setTimestamp(2, Timestamp.valueOf(endTime));

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    vehiculesRevenant.put(
                        rs.getLong("vehicule_id"),
                        rs.getTimestamp("heure_retour").toLocalDateTime()
                    );
                }
            }
        }

        return vehiculesRevenant;
    }

    /**
     * Vérifier si un véhicule est disponible à une heure donnée.
     */
    public boolean isVehiculeDisponible(Long vehiculeId, LocalDateTime heureDepart) throws SQLException {
        String sql = "SELECT COUNT(*) as count FROM attribution " +
                     "WHERE vehicule_id = ? AND date_heure_retour > ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, vehiculeId);
            stmt.setTimestamp(2, Timestamp.valueOf(heureDepart));

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("count") == 0;
                }
            }
        }

        return true;
    }

    /**
     * Mapper un ResultSet vers un objet Attribution.
     */
    private Attribution mapAttribution(ResultSet rs) throws SQLException {
        Attribution attribution = new Attribution();
        attribution.setId(rs.getLong("id"));
        attribution.setDateHeureDepart(rs.getTimestamp("date_heure_depart").toLocalDateTime());
        attribution.setDateHeureRetour(rs.getTimestamp("date_heure_retour").toLocalDateTime());
        attribution.setStatut(rs.getString("statut"));

        // Sprint 7: Mapper nb_passagers_assignes
        if (rs.getObject("nb_passagers_assignes") != null) {
            attribution.setNbPassagersAssignes(rs.getInt("nb_passagers_assignes"));
        }

        // Charger le véhicule
        Long vehiculeId = rs.getLong("vehicule_id");
        Vehicule vehicule = vehiculeRepository.findById(vehiculeId);
        attribution.setVehicule(vehicule);

        // Charger la réservation
        Long reservationId = rs.getLong("reservation_id");
        Reservation reservation = reservationRepository.findById(reservationId);
        attribution.setReservation(reservation);
        attribution.addReservation(reservation);

        return attribution;
    }
}
