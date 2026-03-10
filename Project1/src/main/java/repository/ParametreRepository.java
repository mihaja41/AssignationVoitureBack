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
        if (p == null){
            throw new IllegalArgumentException("La vitesse moyenne n'existe pas dans la base , Veillez la creer  ! ");
        }
        return  p.getValueAsDouble() ; 
    }

    /**
     * Récupérer le temps d'attente (en minutes). Défaut : 30.
     */
    public double getTempsAttente()  throws SQLException, IllegalArgumentException {
        Parametre p = findByKey("temps_attente");
        if (p == null){
            throw new IllegalArgumentException("Le temps d'attente n'existe pas dans la base, Veillez le creer   ! ");
        }
        return  p.getValueAsDouble() ; 
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
