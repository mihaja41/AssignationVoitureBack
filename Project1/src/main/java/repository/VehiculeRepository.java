package repository;

import config.DatabaseConnection;
import model.Vehicule;
import model.TypeCarburant;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class VehiculeRepository {

    /**
     * Enregistrer un véhicule
     */
    public Vehicule save(Vehicule vehicule) throws SQLException {
        String sql = "INSERT INTO vehicule (reference, nb_place, type_carburant) " +
                     "VALUES (?, ?, ?::type_carburant_enum) RETURNING id";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, vehicule.getReference());
            stmt.setInt(2, vehicule.getNbPlace());
            stmt.setObject(3, vehicule.getTypeCarburant().name(), Types.OTHER);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    vehicule.setId(rs.getLong("id"));
                }
            }
        }

        return vehicule;
    }

    /**
     * Récupérer tous les véhicules
     */
    public List<Vehicule> findAll() throws SQLException {
        List<Vehicule> vehicules = new ArrayList<>();
        String sql = "SELECT id, reference, nb_place, type_carburant " +
                     "FROM vehicule " +
                     "ORDER BY reference ASC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Vehicule vehicule = new Vehicule();
                vehicule.setId(rs.getLong("id"));
                vehicule.setReference(rs.getString("reference"));
                vehicule.setNbPlace(rs.getInt("nb_place"));
                vehicule.setTypeCarburant(TypeCarburant.valueOf(rs.getString("type_carburant")));

                vehicules.add(vehicule);
            }
        }

        return vehicules;
    }

    /**
     * Trouver un véhicule par ID
     */
    public Vehicule findById(Long id) throws SQLException {
        String sql = "SELECT id, reference, nb_place, type_carburant " +
                     "FROM vehicule " +
                     "WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, id);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Vehicule vehicule = new Vehicule();
                    vehicule.setId(rs.getLong("id"));
                    vehicule.setReference(rs.getString("reference"));
                    vehicule.setNbPlace(rs.getInt("nb_place"));
                    vehicule.setTypeCarburant(TypeCarburant.valueOf(rs.getString("type_carburant")));

                    return vehicule;
                }
            }
        }

        return null;
    }

    /**
     * Trouver un véhicule par référence
     */
    public Vehicule findByReference(String reference) throws SQLException {
        String sql = "SELECT id, reference, nb_place, type_carburant " +
                     "FROM vehicule " +
                     "WHERE reference = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, reference);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Vehicule vehicule = new Vehicule();
                    vehicule.setId(rs.getLong("id"));
                    vehicule.setReference(rs.getString("reference"));
                    vehicule.setNbPlace(rs.getInt("nb_place"));
                    vehicule.setTypeCarburant(TypeCarburant.valueOf(rs.getString("type_carburant")));

                    return vehicule;
                }
            }
        }

        return null;
    }

    /**
     * Mettre à jour un véhicule
     */
    public Vehicule update(Vehicule vehicule) throws SQLException {
        String sql = "UPDATE vehicule " +
                     "SET reference = ?, nb_place = ?, type_carburant = ?::type_carburant_enum " +
                     "WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, vehicule.getReference());
            stmt.setInt(2, vehicule.getNbPlace());
            stmt.setObject(3, vehicule.getTypeCarburant().name(), Types.OTHER);
            stmt.setLong(4, vehicule.getId());

            stmt.executeUpdate();
        }

        return vehicule;
    }

    /**
     * Supprimer un véhicule
     */
    public boolean delete(Long id) throws SQLException {
        String sql = "DELETE FROM vehicule WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, id);
            int rowsAffected = stmt.executeUpdate();

            return rowsAffected > 0;
        }
    }
}
