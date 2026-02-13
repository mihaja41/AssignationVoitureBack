package service;

import model.Token;
import repository.TokenRepository;

import java.sql.SQLException;
import java.time.OffsetDateTime;

public class TokenService {

    private final TokenRepository tokenRepository = new TokenRepository();
    private final int durationMinutes = 30 ;

    /**
     * Générer et sauvegarder un token
     */
    public Token generateAndSaveToken() throws SQLException {

        // 1️⃣ Génération du token (UUID / GUID)
        String tokenValue = tokenRepository.generateToken();

        // 2️⃣ Calcul de la date d'expiration
        OffsetDateTime expireDate =
                OffsetDateTime.now().plusMinutes(durationMinutes);

        // 3️⃣ Création de l'objet Token
        Token token = new Token();
        token.setTokenName(tokenValue);
        token.setExpireDate(expireDate);
        token.setRevoked(false);

        // 4️⃣ Sauvegarde en base
        tokenRepository.save(token);

        // 5️⃣ Retourner le token (avec ID)
        return token;
    }
}
