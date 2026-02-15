package repository;

import config.DatabaseConnection;
import model.Token;

import java.sql.*;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
public class TokenRepository {

    /**
     * Récupérer tous les tokens
     */
    public List<Token> findAll() throws SQLException {
        List<Token> tokens = new ArrayList<>();
        String sql = """
            SELECT id, token_name, expire_date, created_at, revoked
            FROM token
            ORDER BY created_at DESC
        """;

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Token token = new Token();
                token.setId(rs.getLong("id"));
                token.setTokenName(rs.getString("token_name"));
                token.setExpireDate(rs.getObject("expire_date", OffsetDateTime.class));
                token.setCreatedAt(rs.getObject("created_at", OffsetDateTime.class));
                token.setRevoked(rs.getBoolean("revoked"));
                tokens.add(token);
            }
        }

        return tokens;
    }

    /**
     * Trouver un token par ID
     */

    public Token findById(Long id) throws SQLException {
        String sql = """
            SELECT id, token_name, expire_date, created_at, revoked
            FROM token
            WHERE id = ?
        """;

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, id);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Token token = new Token();
                    token.setId(rs.getLong("id"));
                    token.setTokenName(rs.getString("token_name"));
                    token.setExpireDate(rs.getObject("expire_date", OffsetDateTime.class));
                    token.setCreatedAt(rs.getObject("created_at", OffsetDateTime.class));
                    token.setRevoked(rs.getBoolean("revoked"));
                    return token;
                }
            }
        }

        return null;
    }

    /**
     * Trouver un token par sa valeur
     */
    public Token findByTokenName(String tokenName) throws SQLException {
        String sql = """
            SELECT id, token_name, expire_date, created_at, revoked
            FROM token
            WHERE token_name = ?
        """;

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, tokenName);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Token token = new Token();
                    token.setId(rs.getLong("id"));
                    token.setTokenName(rs.getString("token_name"));
                    token.setExpireDate(rs.getObject("expire_date", OffsetDateTime.class));
                    token.setCreatedAt(rs.getObject("created_at", OffsetDateTime.class));
                    token.setRevoked(rs.getBoolean("revoked"));
                    return token;
                }
            }
        }

        return null;
    }

    /**
     * Sauvegarder un token
     */
    public void save(Token token) throws SQLException {
        String sql = """
            INSERT INTO token (token_name, expire_date, revoked)
            VALUES (?, ?, ?)
        """;

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            stmt.setString(1, token.getTokenName());
            stmt.setObject(2, token.getExpireDate());
            stmt.setBoolean(3, token.getRevoked());

            stmt.executeUpdate();

            try (ResultSet keys = stmt.getGeneratedKeys()) {
                if (keys.next()) {
                    token.setId(keys.getLong(1));
                }
            }
        }
    }

    /**
     * Révoquer un token
     */
    public void revoke(Long id) throws SQLException {
        String sql = "UPDATE token SET revoked = true WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, id);
            stmt.executeUpdate();
        }
    }

    public String generateToken() {
        return UUID.randomUUID().toString();
    }

}
