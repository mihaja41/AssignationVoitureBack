<!-- sessionTests.jsp -->
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head>
<title>Tests de Session</title>
</head>
<body>
<div class="container">
    <h1>Tests de Gestion de Session</h1>
    <p class="subtitle">Framework MVC Maison - Démonstration complète</p>
    
    <div class="important">
        <strong>Important :</strong> Toutes les opérations (ajout, modification, suppression) 
        se font via <span class="highlight">@Session Map&lt;String, Object&gt;</span> 
        et sont automatiquement synchronisées avec <span class="highlight">HttpSession</span>
    </div>
    
    <!-- Section 1 : Authentification -->
    <div class="test-section">
        <h2>Authentification et Gestion Utilisateur</h2>
        <ul class="test-list">
            <li>
                <a href="<%= request.getContextPath() %>/login">Page de Login</a>
                <div class="description">
                    Tester avec : <strong>admin</strong> / <strong>1234</strong><br>
                    Cree la session avec userId, role, loggedIn, lastLogin
                </div>
            </li>
            <li>
                <a href="<%= request.getContextPath() %>/dashboard">Dashboard</a>
                <div class="description">
                    Accès protégé - nécessite une session active avec loggedIn=true
                </div>
            </li>
            <li>
                <a href="<%= request.getContextPath() %>/logout">🚪 Logout</a>
                <div class="description">
                    Vide la session via <code>session.clear()</code>
                </div>
            </li>
        </ul>
    </div>
    
    <!-- Section 2 : Visualisation -->
    <div class="test-section">
        <h2>Visualisation de la Session</h2>
        <ul class="test-list">
            <li>
                <a href="<%= request.getContextPath() %>/session/show">👁️ Afficher toute la session</a>
                <div class="description">
                    Affiche tous les attributs stockés en session<br>
                    Prouve que les données persistent entre les requêtes
                </div>
            </li>
        </ul>
    </div>
    
    <!-- Section 3 : Modification -->
    <div class="test-section">
        <h2>Modification de la Session</h2>
        <ul class="test-list">
            <li>
                <a href="<%= request.getContextPath() %>/session/add?key=testKey&value=testValue">➕ Ajouter une clé</a>
                <div class="description">
                    Exemple : <code>session.put("testKey", "testValue")</code><br>
                    Modifiez les paramètres <strong>key</strong> et <strong>value</strong> dans l'URL
                </div>
            </li>
            <li>
                <a href="<%= request.getContextPath() %>/session/change-role?newRole=superadmin"> Changer le rôle</a>
                <div class="description">
                    Modifie le rôle de l'utilisateur connecté<br>
                    <code>session.put("role", newRole)</code>
                </div>
            </li>
            <li>
                <a href="<%= request.getContextPath() %>/session/add-complex">Ajouter données complexes</a>
                <div class="description">
                    Ajoute List, Map, Integer dans la session<br>
                    Prouve que tous types d'objets sont supportés
                </div>
            </li>
        </ul>
    </div>
    
    <!-- Section 4 : Suppression -->
    <div class="test-section">
        <h2>Suppression de Données</h2>
        <ul class="test-list">
            <li>
                <a href="<%= request.getContextPath() %>/session/remove?key=testKey">Supprimer une clé</a>
                <div class="description">
                    Supprime une clé spécifique : <code>session.remove("testKey")</code>
                </div>
            </li>
            <li>
                <a href="<%= request.getContextPath() %>/session/clear" onclick="return confirm('Vider toute la session ?')"> Vider la session</a>
                <div class="description">
                    Supprime TOUT : <code>session.clear()</code><br>
                    Vous serez déconnecté
                </div>
            </li>
        </ul>
    </div>
    
    <!-- Section 5 : Persistance -->
    <div class="test-section">
        <h2>Test de Persistance</h2>
        <ul class="test-list">
            <li>
                <a href="<%= request.getContextPath() %>/session/increment">Compteur de visites</a>
                <div class="description">
                    Incrémente un compteur à chaque visite<br>
                    Prouve que les données persistent entre les requêtes
                </div>
            </li>
            <li>
                <a href="<%= request.getContextPath() %>/session/replace-all"> Remplacer toute la session</a>
                <div class="description">
                    <code>session.clear()</code> puis réinsertion de nouvelles données<br>
                    Test de remplacement complet
                </div>
            </li>
        </ul>
    </div>
    
    <!-- Section 6 : Scénario complet -->
    <div class="test-section">
        <h2>Scénario de Test Complet</h2>
        <p><strong>Pour démontrer au professeur :</strong></p>
        <ol style="line-height: 2; color: #555;">
            <li>Se connecter via <strong>/login</strong> (admin/1234)</li>
            <li>Aller au <strong>/dashboard</strong> - vérifier que les données de session sont affichées</li>
            <li>Aller à <strong>/session/show</strong> - voir tous les attributs de session</li>
            <li>Cliquer sur <strong>Ajouter données complexes</strong></li>
            <li>Rafraîchir <strong>/session/show</strong> - les nouvelles données apparaissent</li>
            <li>Changer le rôle via <strong>/session/change-role?newRole=admin-premium</strong></li>
            <li>Retourner au <strong>/dashboard</strong> - le nouveau rôle est affiché</li>
            <li>Incrémenter le compteur plusieurs fois - vérifier la persistance</li>
            <li>Supprimer une clé spécifique</li>
            <li>Vider la session - vérifier la déconnexion</li>
        </ol>
    </div>
    
    <div style="text-align: center; margin-top: 40px; padding-top: 30px; border-top: 2px solid #eee;">
        <p style="color: #999;">
            <strong>Tous les tests utilisent @Session Map&lt;String, Object&gt;</strong><br>
            Les modifications sont automatiquement synchronisées avec HttpSession dans FrontServlet
        </p>
    </div>
</div>
</body>
</html>