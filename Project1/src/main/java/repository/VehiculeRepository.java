package repository;

import config.DatabaseConnection;
import model.Vehicule;
import model.TypeCarburant;

import java.sql.*;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Repository pour les véhicules.
 *  sprint 7 : Ajout de la colonne heure_disponible_debut.
 */
public class VehiculeRepository {

    /**
     * Enregistrer un véhicule
     *  sprint 7 : Inclut heure_disponible_debut
     */
    public Vehicule save(Vehicule vehicule) throws SQLException {
        String sql = "INSERT INTO vehicule (reference, nb_place, type_carburant, heure_disponible_debut) " +
                     "VALUES (?, ?, ?::type_carburant_enum, ?) RETURNING id";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, vehicule.getReference());
            stmt.setInt(2, vehicule.getNbPlace());
            stmt.setObject(3, vehicule.getTypeCarburant().name(), Types.OTHER);
            //  sprint 7 : heure_disponible_debut
            if (vehicule.getHeureDisponibleDebut() != null) {
                stmt.setTime(4, Time.valueOf(vehicule.getHeureDisponibleDebut()));
            } else {
                stmt.setNull(4, Types.TIME);
            }

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
     *  sprint 7 : Inclut heure_disponible_debut
     */
    public List<Vehicule> findAll() throws SQLException {
        List<Vehicule> vehicules = new ArrayList<>();
        String sql = "SELECT id, reference, nb_place, type_carburant, heure_disponible_debut " +
                     "FROM vehicule " +
                     "ORDER BY reference ASC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                vehicules.add(mapVehicule(rs));
            }
        }

        return vehicules;
    }

    /**
     * Trouver un véhicule par ID
     */
    public Vehicule findById(Long id) throws SQLException {
        String sql = "SELECT id, reference, nb_place, type_carburant, heure_disponible_debut " +
                     "FROM vehicule " +
                     "WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, id);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapVehicule(rs);
                }
            }
        }

        return null;
    }

    /**
     * Trouver un véhicule par référence
     */
    public Vehicule findByReference(String reference) throws SQLException {
        String sql = "SELECT id, reference, nb_place, type_carburant, heure_disponible_debut " +
                     "FROM vehicule " +
                     "WHERE reference = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, reference);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapVehicule(rs);
                }
            }
        }

        return null;
    }

    /**
     * Mettre à jour un véhicule
     *  sprint 7 : Inclut heure_disponible_debut
     */
    public Vehicule update(Vehicule vehicule) throws SQLException {
        String sql = "UPDATE vehicule " +
                     "SET reference = ?, nb_place = ?, type_carburant = ?::type_carburant_enum, " +
                     "    heure_disponible_debut = ? " +
                     "WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, vehicule.getReference());
            stmt.setInt(2, vehicule.getNbPlace());
            stmt.setObject(3, vehicule.getTypeCarburant().name(), Types.OTHER);
            //  sprint 7 : heure_disponible_debut
            if (vehicule.getHeureDisponibleDebut() != null) {
                stmt.setTime(4, Time.valueOf(vehicule.getHeureDisponibleDebut()));
            } else {
                stmt.setNull(4, Types.TIME);
            }
            stmt.setLong(5, vehicule.getId());

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

    /**
     * Trouver les véhicules avec assez de places pour un nombre de passagers donné.
     *  sprint 7 : Inclut heure_disponible_debut pour le filtrage.
     */
    public List<Vehicule> findAvailableVehicules(int passengerNbr) throws SQLException {
        List<Vehicule> vehicules = new ArrayList<>();
        String sql = "SELECT v.id, v.reference, v.nb_place, v.type_carburant, v.heure_disponible_debut " +
                     "FROM vehicule v " +
                     "WHERE v.nb_place >= ? " +
                     "ORDER BY v.nb_place ASC, v.type_carburant ASC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, passengerNbr);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    vehicules.add(mapVehicule(rs));
                }
            }
        }

        return vehicules;
    }

    /**
     *  sprint 7 : Trouver TOUS les véhicules (sans filtre de places).
     * Utilisé pour la division où on prend le véhicule le plus proche en capacité.
     */
    public List<Vehicule> findAllVehicules() throws SQLException {
        List<Vehicule> vehicules = new ArrayList<>();
        String sql = "SELECT id, reference, nb_place, type_carburant, heure_disponible_debut " +
                     "FROM vehicule " +
                     "WHERE nb_place > 0 " +
                     "ORDER BY nb_place DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                vehicules.add(mapVehicule(rs));
            }
        }

        return vehicules;
    }

    /**
     *  sprint 7 : Mapper un ResultSet vers un Vehicule.
     * Centralise le mapping pour éviter la duplication.
     */
    private Vehicule mapVehicule(ResultSet rs) throws SQLException {
        Vehicule vehicule = new Vehicule();
        vehicule.setId(rs.getLong("id"));
        vehicule.setReference(rs.getString("reference"));
        vehicule.setNbPlace(rs.getInt("nb_place"));
        vehicule.setTypeCarburant(TypeCarburant.valueOf(rs.getString("type_carburant")));

        //  sprint 7 : Lire heure_disponible_debut
        Time heureDispoTime = rs.getTime("heure_disponible_debut");
        if (heureDispoTime != null) {
            vehicule.setHeureDisponibleDebut(heureDispoTime.toLocalTime());
        }

        return vehicule;
    }
}
