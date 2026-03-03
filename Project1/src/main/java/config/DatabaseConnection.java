package config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseConnection {

    private static final String URL = "jdbc:postgresql://maglev.proxy.rlwy.net:47176/railway";
    // private static final String URL ="jdbc:postgresql://localhost:5432/hotel_reservation";
    private static final String USER = "postgres";  
    private static final String PASSWORD = "WmIPfLVyvjiumAmELYevLpvMbUgYHgQD";  
    // private static final String PASSWORD = "fanjatiana";  

    static {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("PostgreSQL Driver not found", e);
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}