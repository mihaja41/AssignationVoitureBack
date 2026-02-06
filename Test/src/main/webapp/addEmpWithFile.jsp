<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <title>Ajout Employé + Upload + Test Map</title>
</head>
<body>
    <h1>Ajouter un employé avec fichiers et paramètres supplémentaires</h1>

    <form method="post" action="/test_app/save-employe-with-file" enctype="multipart/form-data">
        
        <p><label>Nom :</label><br>
            <input type="text" name="name" required></p>

        <p><label>Nom département :</label><br>
            <input type="text" name="departement.name"></p>

        <p><label>Niveau département :</label><br>
            <input type="number" name="departement.level" value="1"></p>

        <!-- Champs supplémentaires pour tester Map<String,Object> -->
        <hr>
        <h3>Paramètres supplémentaires (capturés dans Map)</h3>
        <p><label>Poste :</label><br>
            <input type="text" name="poste"></p>

        <p><label>Loisirs (checkbox) :</label><br>
            <input type="checkbox" name="loisirs" value="Sport"> Sport<br>
            <input type="checkbox" name="loisirs" value="Lecture"> Lecture<br>
            <input type="checkbox" name="loisirs" value="Musique"> Musique</p>

        <hr>
        <h3>Upload fichiers</h3>
        <p><label>Photo profil :</label><br>
            <input type="file" name="photo"></p>

        <p><label>Documents (multiples) :</label><br>
            <input type="file" name="documents" multiple></p>

        <button type="submit">Envoyer tout</button>
    </form>
</body>
</html>