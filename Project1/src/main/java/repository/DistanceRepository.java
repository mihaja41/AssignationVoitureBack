package repository;

import config.DatabaseConnection;
import model.Distance;
import model.Lieu;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class DistanceRepository {

    /**
     * Trouver la distance entre deux lieux.
     * Cherche dans les deux sens : (A → B) ou (B → A).
     * Une seule entrée est stockée par paire de lieux.
     */
    public Distance findByFromAndTo(Long fromLieuId, Long toLieuId) throws SQLException {
        String sql = "SELECT d.id, d.km_distance, d.created_at, " +
                     "f.id AS from_id, f.code AS from_code, f.libelle AS from_libelle, " +
                     "t.id AS to_id, t.code AS to_code, t.libelle AS to_libelle " +
                     "FROM distance d " +
                     "JOIN lieu f ON d.from_lieu_id = f.id " +
                     "JOIN lieu t ON d.to_lieu_id = t.id " +
                     "WHERE (d.from_lieu_id = ? AND d.to_lieu_id = ?) " +
                     "   OR (d.from_lieu_id = ? AND d.to_lieu_id = ?)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, fromLieuId);
            stmt.setLong(2, toLieuId);
            stmt.setLong(3, toLieuId);
            stmt.setLong(4, fromLieuId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToDistance(rs);
                }
            }
        }
        return null;
    }
 
    /**
     * Récupérer toutes les distances
     */
    public List<Distance> findAll() throws SQLException {
        List<Distance> distances = new ArrayList<>();
        String sql = "SELECT d.id, d.km_distance, d.created_at, " +
                     "f.id AS from_id, f.code AS from_code, f.libelle AS from_libelle, " +
                     "t.id AS to_id, t.code AS to_code, t.libelle AS to_libelle " +
                     "FROM distance d " +
                     "JOIN lieu f ON d.from_lieu_id = f.id " +
                     "JOIN lieu t ON d.to_lieu_id = t.id " +
                     "ORDER BY f.libelle, t.libelle";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                distances.add(mapResultSetToDistance(rs));
            }
        }

        return distances;
    }

    private Distance mapResultSetToDistance(ResultSet rs) throws SQLException {
        Lieu fromLieu = new Lieu();
        fromLieu.setId(rs.getLong("from_id"));
        fromLieu.setCode(rs.getString("from_code"));
        fromLieu.setLibelle(rs.getString("from_libelle"));

        Lieu toLieu = new Lieu();
        toLieu.setId(rs.getLong("to_id"));
        toLieu.setCode(rs.getString("to_code"));
        toLieu.setLibelle(rs.getString("to_libelle"));

        Distance distance = new Distance();
        distance.setId(rs.getLong("id"));
        distance.setFromLieu(fromLieu);
        distance.setToLieu(toLieu);
        distance.setKmDistance(rs.getBigDecimal("km_distance"));
        Timestamp ts = rs.getTimestamp("created_at");
        if (ts != null) {
            distance.setCreatedAt(ts.toLocalDateTime());
        }

        return distance;
    }
}
