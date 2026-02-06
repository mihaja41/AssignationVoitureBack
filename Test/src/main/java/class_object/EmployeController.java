package main.java.class_object;

import class_annotations.Controller;
import method_annotations.*;
import view.ModelView;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
public class EmployeController {

    // ========================================
    // MÉTHODES ORIGINALES
    // ========================================

    @Json
    @PostRouteMapping(value = "/save-employe")
    public ModelView save(Employe employe) {
        System.out.println(employe.getName());
        if (employe.getDepartement() != null) {
            System.out.println(employe.getDepartement().getName());
        }
        ModelView mv = new ModelView("afterAddEmp.jsp");
        mv.setData("emp", employe);
        return mv;
    }

    @Route("/add-emp")
    public ModelView showForm() {
        return new ModelView("addEmp.jsp");
    }

    @PostRouteMapping(value = "/save-employe-with-file")
    public ModelView saveWithFile(
            Employe employe,
            Map<String, List<byte[]>> uploadedFiles,
            Map<String, Object> formData,
            HttpServletRequest request
    ) {
        System.out.println("=== DONNÉES EMPLOYÉ ===");
        System.out.println("Nom Employé : " + employe.getName());
        if (employe.getDepartement() != null) {
            System.out.println("Département : " + employe.getDepartement().getName());
            System.out.println("Niveau : " + employe.getDepartement().getLevel());
        }

        System.out.println("\n=== TOUS LES PARAMÈTRES (Map<String,Object>) ===");
        formData.forEach((key, value) -> {
            if (value.getClass().isArray()) {
                System.out.println(key + " : " + Arrays.toString((Object[]) value));
            } else {
                System.out.println(key + " : " + value);
            }
        });

        String uploadDirPath = request.getServletContext().getRealPath("/uploads/");
        File uploadDir = new File(uploadDirPath);
        if (!uploadDir.exists()) {
            uploadDir.mkdirs();
            System.out.println("Dossier /uploads créé automatiquement : " + uploadDirPath);
        }

        List<String> savedFiles = new ArrayList<>();
        for (Map.Entry<String, List<byte[]>> entry : uploadedFiles.entrySet()) {
            String fieldName = entry.getKey();
            List<byte[]> files = entry.getValue();
            for (int i = 0; i < files.size(); i++) {
                byte[] bytes = files.get(i);
                String fileName = fieldName + (files.size() > 1 ? "_" + i : "")
                        + "_" + System.currentTimeMillis() + ".uploaded";
                String fullPath = uploadDirPath + fileName;
                try (FileOutputStream fos = new FileOutputStream(fullPath)) {
                    fos.write(bytes);
                    savedFiles.add("/uploads/" + fileName);
                    System.out.println("Fichier sauvegardé : " + fullPath + " (" + bytes.length + " bytes)");
                } catch (IOException e) {
                    System.err.println("Erreur lors de la sauvegarde du fichier : " + e.getMessage());
                }
            }
        }

        ModelView mv = new ModelView("afterUpload.jsp");
        mv.setData("employe", employe);
        mv.setData("savedFiles", savedFiles);
        mv.setData("formData", formData);
        mv.setData("message", savedFiles.isEmpty()
                ? "Employé ajouté (sans fichier)."
                : "Employé + " + savedFiles.size() + " fichier(s) uploadé(s) !");
        return mv;
    }

    @PostRouteMapping(value = "/save-employe-full-test")
    public ModelView saveFullTest(
            Employe employe,
            @RequestParam("poste") String posteAnnoté,
            String salaire,
            Map<String, List<byte[]>> uploadedFiles,
            Map<String, Object> formData,
            HttpServletRequest request
    ) {
        System.out.println("=== TEST COMPLET ===");
        System.out.println("Employé : " + employe.getName() + " (Dépt: " +
                (employe.getDepartement() != null ? employe.getDepartement().getName() : "aucun") + ")");
        System.out.println("Poste (annoté) : " + posteAnnoté);
        System.out.println("Salaire (simple) : " + salaire);
        System.out.println("Nombre de fichiers uploadés : " +
                uploadedFiles.values().stream().mapToInt(List::size).sum());

        formData.forEach((k, v) -> {
            if (v.getClass().isArray()) {
                System.out.println("formData[" + k + "] = " + Arrays.toString((Object[]) v));
            } else {
                System.out.println("formData[" + k + "] = " + v);
            }
        });

        String uploadDirPath = request.getServletContext().getRealPath("/uploads/");
        File uploadDir = new File(uploadDirPath);
        if (!uploadDir.exists()) {
            uploadDir.mkdirs();
        }

        List<String> savedFiles = new ArrayList<>();
        for (Map.Entry<String, List<byte[]>> entry : uploadedFiles.entrySet()) {
            String field = entry.getKey();
            List<byte[]> files = entry.getValue();
            for (int i = 0; i < files.size(); i++) {
                byte[] bytes = files.get(i);
                String fileName = field + (files.size() > 1 ? "_" + i : "")
                        + "_" + System.currentTimeMillis() + ".uploaded";
                String fullPath = uploadDirPath + fileName;
                try (FileOutputStream fos = new FileOutputStream(fullPath)) {
                    fos.write(bytes);
                    savedFiles.add("/uploads/" + fileName);
                } catch (IOException e) {
                    System.err.println("Erreur sauvegarde : " + e.getMessage());
                }
            }
        }

        ModelView mv = new ModelView("afterUpload.jsp");
        mv.setData("employe", employe);
        mv.setData("savedFiles", savedFiles);
        mv.setData("formData", formData);
        mv.setData("message", "TEST COMPLET RÉUSSI ! Tout fonctionne parfaitement.");
        return mv;
    }

    // ========================================
    // AUTHENTIFICATION ET SESSION
    // ========================================

    @GetRouteMapping(value = "/login")
    public ModelView showLoginForm() {
        return new ModelView("login.jsp");
    }

    @PostRouteMapping(value = "/login")
    public ModelView login(
            @RequestParam("username") String username,
            @RequestParam("password") String password,
            @Session Map<String, Object> session
    ) {
        System.out.println("🔍 DEBUG LOGIN - username : '" + username + "'");
        System.out.println("🔍 DEBUG LOGIN - password : '" + password + "'");
        
        // Vérifications pour les tests
        String role = null;
        
        if ("admin".equals(username) && "1234".equals(password)) {
            role = "admin";
        } else if ("manager".equals(username) && "1234".equals(password)) {
            role = "manager";
        } else if ("user".equals(username) && "1234".equals(password)) {
            role = "user";
        }
        
        if (role != null) {
            System.out.println("✅ Login réussi");
            
            session.put("userId", username);
            session.put("role", role);
            session.put("loggedIn", true);
            session.put("lastLogin", new java.util.Date());
            
            System.out.println("✅ Login réussi pour : " + username + " (rôle: " + role + ")");
            System.out.println("🔍 Session : " + session);

            return new ModelView("redirect:/dashboard");
        } else {
            System.out.println("❌ LOGIN ÉCHOUÉ - identifiants incorrects");
            ModelView mv = new ModelView("login.jsp");
            mv.setData("error", "Identifiants incorrects");
            return mv;
        }
    }

    @GetRouteMapping(value = "/dashboard")
    public ModelView dashboard(@Session Map<String, Object> session) {
        Boolean loggedIn = (Boolean) session.get("loggedIn");
        
        System.out.println("=== DASHBOARD ===");
        System.out.println("Session complète : " + session);
        System.out.println("loggedIn : " + loggedIn);

        if (loggedIn == null || !loggedIn) {
            ModelView mv = new ModelView("login.jsp");
            mv.setData("error", "Veuillez vous connecter");
            return mv;
        }

        ModelView mv = new ModelView("dashboard.jsp");
        mv.setData("user", session.get("userId"));
        mv.setData("role", session.get("role"));
        mv.setData("lastLogin", session.get("lastLogin"));
        return mv;
    }

    @GetRouteMapping(value = "/logout")
    public ModelView logout(@Session Map<String, Object> session) {
        session.clear();
        
        ModelView mv = new ModelView("login.jsp");
        mv.setData("message", "Déconnexion réussie");
        return mv;
    }

    // ========================================
    // TESTS DE SESSION
    // ========================================

    @GetRouteMapping(value = "/session_show")
    public ModelView showSession(@Session Map<String, Object> session) {
        System.out.println("=== AFFICHAGE SESSION ===");
        System.out.println("Nombre d'attributs : " + session.size());
        session.forEach((k, v) -> System.out.println("  " + k + " = " + v));
        
        ModelView mv = new ModelView("showSession.jsp");
        mv.setData("sessionData", session);
        return mv;
    }

    @GetRouteMapping(value = "/session_add")
    public ModelView addToSession(
            @RequestParam("key") String key,
            @RequestParam("value") String value,
            @Session Map<String, Object> session
    ) {
        System.out.println("=== AJOUT/MODIFICATION SESSION ===");
        System.out.println("Avant : " + session);
        
        Object oldValue = session.put(key, value);
        
        System.out.println("Clé : " + key);
        System.out.println("Ancienne valeur : " + oldValue);
        System.out.println("Nouvelle valeur : " + value);
        System.out.println("Après : " + session);
        
        return new ModelView("redirect:/session_show");
    }

    @GetRouteMapping(value = "/session_remove")
    public ModelView removeFromSession(
            @RequestParam("key") String key,
            @Session Map<String, Object> session
    ) {
        System.out.println("=== SUPPRESSION SESSION ===");
        System.out.println("Avant : " + session);
        
        Object removed = session.remove(key);
        
        System.out.println("Clé supprimée : " + key);
        System.out.println("Valeur supprimée : " + removed);
        System.out.println("Après : " + session);
        
        return new ModelView("redirect:/session_show");
    }

    @GetRouteMapping(value = "/session_clear")
    public ModelView clearSession(@Session Map<String, Object> session) {
        System.out.println("=== VIDAGE SESSION ===");
        System.out.println("Avant : " + session);
        
        session.clear();
        
        System.out.println("Après clear() : " + session);
        
        return new ModelView("redirect:/session_show");
    }

    @GetRouteMapping(value = "/session_change-role")
    public ModelView changeRole(
            @RequestParam("newRole") String newRole,
            @Session Map<String, Object> session
    ) {
        System.out.println("=== CHANGEMENT DE RÔLE ===");
        
        if (!session.containsKey("loggedIn") || !(Boolean) session.get("loggedIn")) {
            ModelView mv = new ModelView("login.jsp");
            mv.setData("error", "Vous devez être connecté");
            return mv;
        }
        
        String oldRole = (String) session.get("role");
        session.put("role", newRole);
        session.put("roleChangedAt", new java.util.Date());
        
        System.out.println("Ancien rôle : " + oldRole);
        System.out.println("Nouveau rôle : " + newRole);
        System.out.println("Session mise à jour : " + session);
        
        return new ModelView("redirect:/dashboard");
    }

    @GetRouteMapping(value = "/session_add-complex")
    public ModelView addComplexData(@Session Map<String, Object> session) {
        System.out.println("=== AJOUT DONNÉES COMPLEXES ===");
        
        List<String> favoriteColors = new ArrayList<>();
        favoriteColors.add("Rouge");
        favoriteColors.add("Bleu");
        favoriteColors.add("Vert");
        session.put("favoriteColors", favoriteColors);
        
        Map<String, Object> preferences = new HashMap<>();
        preferences.put("theme", "dark");
        preferences.put("language", "fr");
        preferences.put("notifications", true);
        session.put("preferences", preferences);
        
        Integer visitCount = (Integer) session.get("visitCount");
        session.put("visitCount", visitCount == null ? 1 : visitCount + 1);
        
        System.out.println("Données ajoutées : " + session);
        
        return new ModelView("redirect:/session_show");
    }

    @GetRouteMapping(value = "/session_increment")
    public ModelView incrementCounter(@Session Map<String, Object> session) {
        Integer counter = (Integer) session.get("counter");
        
        if (counter == null) {
            counter = 0;
            System.out.println("🆕 Création du compteur");
        }
        
        counter++;
        session.put("counter", counter);
        session.put("lastIncrement", new java.util.Date());
        
        System.out.println("=== INCRÉMENT COMPTEUR ===");
        System.out.println("Valeur actuelle : " + counter);
        
        ModelView mv = new ModelView("counter.jsp");
        mv.setData("counter", counter);
        mv.setData("lastIncrement", session.get("lastIncrement"));
        return mv;
    }

    @GetRouteMapping(value = "/session_replace-all")
    public ModelView replaceAllSession(@Session Map<String, Object> session) {
        System.out.println("=== REMPLACEMENT COMPLET SESSION ===");
        System.out.println("Avant : " + session);
        
        session.clear();
        session.put("newKey1", "value1");
        session.put("newKey2", "value2");
        session.put("newKey3", "value3");
        session.put("replacedAt", new java.util.Date());
        
        System.out.println("Après : " + session);
        
        return new ModelView("redirect:/session_show");
    }

    @GetRouteMapping(value = "/session-tests")
    public ModelView showSessionTests() {
        return new ModelView("sessionTests.jsp");
    }

    // ========================================
    // TESTS D'AUTHENTIFICATION ET RÔLES
    // ========================================

    /**
     * Page accessible à tous (pas d'annotation)
     */
    @GetRouteMapping(value = "/public")
    public ModelView publicPage() {
        ModelView mv = new ModelView("publicPage.jsp");
        mv.setData("message", "Cette page est accessible à tous, même sans être connecté");
        return mv;
    }

    /**
     * Page nécessitant une authentification
     */
    @Authentified
    @GetRouteMapping(value = "/protected")
    public ModelView protectedPage(@Session Map<String, Object> session) {
        ModelView mv = new ModelView("protectedPage.jsp");
        mv.setData("message", "Bravo ! Vous êtes authentifié");
        mv.setData("user", session.get("userId"));
        return mv;
    }

    /**
     * Page accessible uniquement aux admins
     */
    @Role({"admin"})
    @GetRouteMapping(value = "/admin-only")
    public ModelView adminOnlyPage(@Session Map<String, Object> session) {
        ModelView mv = new ModelView("rolePage.jsp");
        mv.setData("message", "Bienvenue Admin ! Vous avez accès à cette page");
        mv.setData("role", session.get("role"));
        mv.setData("pageType", "Admin Only");
        return mv;
    }

    /**
     * Page accessible aux admins ET aux managers
     */
    @Role({"admin", "manager"})
    @GetRouteMapping(value = "/admin-or-manager")
    public ModelView adminOrManagerPage(@Session Map<String, Object> session) {
        ModelView mv = new ModelView("rolePage.jsp");
        mv.setData("message", "Vous êtes soit Admin soit Manager");
        mv.setData("role", session.get("role"));
        mv.setData("pageType", "Admin or Manager");
        return mv;
    }

    /**
     * Page accessible uniquement aux managers
     */
    @Role({"manager"})
    @GetRouteMapping(value = "/manager-only")
    public ModelView managerOnlyPage(@Session Map<String, Object> session) {
        ModelView mv = new ModelView("rolePage.jsp");
        mv.setData("message", "Bienvenue Manager !");
        mv.setData("role", session.get("role"));
        mv.setData("pageType", "Manager Only");
        return mv;
    }

    /**
     * Page pour utilisateurs simples
     */
    @Role({"user"})
    @GetRouteMapping(value = "/user-only")
    public ModelView userOnlyPage(@Session Map<String, Object> session) {
        ModelView mv = new ModelView("rolePage.jsp");
        mv.setData("message", "Bienvenue utilisateur simple !");
        mv.setData("role", session.get("role"));
        mv.setData("pageType", "User Only");
        return mv;
    }

    /**
     * API protégée retournant du JSON
     */
    @Json
    @Authentified
    @GetRouteMapping(value = "/api/user-info")
    public Map<String, Object> getUserInfo(@Session Map<String, Object> session) {
        Map<String, Object> result = new HashMap<>();
        result.put("userId", session.get("userId"));
        result.put("role", session.get("role"));
        result.put("loggedIn", session.get("loggedIn"));
        result.put("timestamp", new java.util.Date());
        return result;
    }

    /**
     * API admin retournant du JSON
     */
    @Json
    @Role({"admin"})
    @GetRouteMapping(value = "/api/admin/stats")
    public Map<String, Object> getAdminStats() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalUsers", 150);
        stats.put("activeUsers", 42);
        stats.put("serverUptime", "15 days");
        stats.put("message", "Statistiques réservées aux admins");
        return stats;
    }

    /**
     * Page de test des permissions
     */
    @GetRouteMapping(value = "/test-permissions")
    public ModelView testPermissions() {
        return new ModelView("testPermissions.jsp");
    }
}