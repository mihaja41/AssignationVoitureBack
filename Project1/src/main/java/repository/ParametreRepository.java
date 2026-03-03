package repository;

import config.DatabaseConnection;
import model.Parametre;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ParametreRepository {

    /**
     * Trouver un paramètre par sa clé.
     */
    public Parametre findByKey(String key) throws SQLException {
        String sql = "SELECT id, key, value, created_at, updated_at FROM parameters WHERE key = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, key);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSet(rs);
                }
            }
        }

        return null;
    }

    /**
     * Récupérer tous les paramètres.
     */
    public List<Parametre> findAll() throws SQLException {
        List<Parametre> parametres = new ArrayList<>();
        String sql = "SELECT id, key, value, created_at, updated_at FROM parameters ORDER BY key";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                parametres.add(mapResultSet(rs));
            }
        }

        return parametres;
    }

    /**
     * Récupérer la vitesse moyenne (km/h). Défaut : 30.
     */
    public double getVitesseMoyenne() throws SQLException {
        Parametre p = findByKey("vitesse_moyenne");
        return (p != null) ? p.getValueAsDouble() : 30.0;
    }

    /**
     * Récupérer le temps d'attente (en minutes). Défaut : 30.
     */
    public double getTempsAttente() throws SQLException {
        Parametre p = findByKey("temps_attente");
        return (p != null) ? p.getValueAsDouble() : 30.0;
    }

    private Parametre mapResultSet(ResultSet rs) throws SQLException {
        Parametre p = new Parametre();
        p.setId(rs.getLong("id"));
        p.setKey(rs.getString("key"));
        p.setValue(rs.getString("value"));
        Timestamp createdTs = rs.getTimestamp("created_at");
        if (createdTs != null) {
            p.setCreatedAt(createdTs.toLocalDateTime());
        }
        Timestamp updatedTs = rs.getTimestamp("updated_at");
        if (updatedTs != null) {
            p.setUpdatedAt(updatedTs.toLocalDateTime());
        }
        return p;
    }
}
