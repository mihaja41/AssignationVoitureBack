package repository;

import config.DatabaseConnection;
import model.Hotel;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class HotelRepository {

    /**
     * Récupérer tous les hôtels
     */
    public List<Hotel> findAll() throws SQLException {
        List<Hotel> hotels = new ArrayList<>();
        String sql = "SELECT id, name FROM hotel ORDER BY name";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Hotel hotel = new Hotel();
                hotel.setId(rs.getLong("id"));
                hotel.setName(rs.getString("name"));
                hotels.add(hotel);
            }
        }

        return hotels;
    }

    /**
     * Trouver un hôtel par ID
     */
    public Hotel findById(Long id) throws SQLException {
        String sql = "SELECT id, name FROM hotel WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, id);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Hotel hotel = new Hotel();
                    hotel.setId(rs.getLong("id"));
                    hotel.setName(rs.getString("name"));
                    return hotel;
                }
            }
        }

        return null;
    }
}