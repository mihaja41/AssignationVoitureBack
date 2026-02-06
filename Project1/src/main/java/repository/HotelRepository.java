package  main.java.repository;

import  main.java.config.DatabaseConnection;
import  main.java.model.Hotel;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class HotelRepository {

    public List<Hotel> findAll() {
        List<Hotel> hotels = new ArrayList<>();

        String sql = "SELECT id, name FROM hotel";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Hotel hotel = new Hotel();
                hotel.setId(rs.getLong("id"));
                hotel.setName(rs.getString("name"));
                hotels.add(hotel);
            }

        } catch (SQLException e) {
            throw new RuntimeException("Error fetching hotels", e);
        }

        return hotels;
    }

    public Hotel findById(Long id) {
        String sql = "SELECT id, name FROM hotel WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setLong(1, id);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                Hotel hotel = new Hotel();
                hotel.setId(rs.getLong("id"));
                hotel.setName(rs.getString("name"));
                return hotel;
            }

        } catch (SQLException e) {
            throw new RuntimeException("Error fetching hotel", e);
        }

        return null;
    }
}
