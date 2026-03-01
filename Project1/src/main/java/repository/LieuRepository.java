package repository;

import config.DatabaseConnection;
import model.Lieu;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class LieuRepository {

    /**
     * Récupérer tous les lieux
     */
    public List<Lieu> findAll() throws SQLException {
        List<Lieu> lieux = new ArrayList<>();
        String sql = "SELECT id, code, libelle, created_at FROM lieu ORDER BY libelle ASC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                lieux.add(mapResultSetToLieu(rs));
            }
        }

        return lieux;
    }

    /**
     * Trouver un lieu par ID
     */
    public Lieu findById(Long id) throws SQLException {
        String sql = "SELECT id, code, libelle, created_at FROM lieu WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, id);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToLieu(rs);
                }
            }
        }

        return null;
    }

    /**
     * Trouver un lieu par code
     */
    public Lieu findByCode(String code) throws SQLException {
        String sql = "SELECT id, code, libelle, created_at FROM lieu WHERE code = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, code);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToLieu(rs);
                }
            }
        }

        return null;
    }

    private Lieu mapResultSetToLieu(ResultSet rs) throws SQLException {
        Lieu lieu = new Lieu();
        lieu.setId(rs.getLong("id"));
        lieu.setCode(rs.getString("code"));
        lieu.setLibelle(rs.getString("libelle"));
        Timestamp ts = rs.getTimestamp("created_at");
        if (ts != null) {
            lieu.setCreatedAt(ts.toLocalDateTime());
        }
        return lieu;
    }
}
