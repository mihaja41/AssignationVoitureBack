package filter;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import repository.TokenRepository;
import model.Token;

import java.io.IOException;
import java.time.OffsetDateTime;

public class AuthTokenFilter implements Filter {

    private TokenRepository tokenRepository;
    private String tokenValues = "Bearer 790eeb70-0dd1-43bb-a457-49d922272adf" ; 

    @Override
    public void init(FilterConfig filterConfig) {
        tokenRepository = new TokenRepository();
    }

    @Override
    public void doFilter(
            ServletRequest request,
            ServletResponse response,
            FilterChain chain
    ) throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;

        String path = req.getRequestURI();

        // 🔓 Route publique (génération du token)
        if (path.endsWith("/token")) {
            chain.doFilter(request, response);
            return;
        }

        // 🔐 Lecture du header Authorization
        String authHeader = tokenValues ;

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            res.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            res.getWriter().write("Unauthorized: token manquant");
            return;
        }

        String tokenValue = authHeader.substring("Bearer ".length());

        try {
            Token token = tokenRepository.findByTokenName(tokenValue);

            // ❌ Token inexistant
            if (token == null) {
                unauthorized(res, "Token invalide");
                return;
            }

            // ❌ Token révoqué
            if (token.getRevoked()) {
                unauthorized(res, "Token révoqué");
                return;
            }

            // ❌ Token expiré
            if (token.getExpireDate().isBefore(OffsetDateTime.now())) {
                unauthorized(res, "Token expiré");
                return;
            }

            // ✅ Token valide
            chain.doFilter(request, response);

        } catch (Exception e) {
            res.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            res.getWriter().write("Erreur serveur");
        }
    }

    private void unauthorized(HttpServletResponse res, String message) throws IOException {
        res.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        res.getWriter().write("Unauthorized: " + message);
    }

    @Override
    public void destroy() {}
}
