<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head><title>Test Complet</title></head>
<body>
<h1>Test complet du framework</h1>
<form method="post" action="/test_app/save-employe-full-test" enctype="multipart/form-data">
    <h3>Employé</h3>
    <p>Nom : <input type="text" name="name" required></p>
    <p>Dépt : <input type="text" name="departement.name"></p>
    <p>Niveau : <input type="number" name="departement.level" value="1"></p>

    <h3>Paramètres simples</h3>
    <p>Poste (@RequestParam) : <input type="text" name="poste"></p>
    <p>Salaire (sans annotation) : <input type="text" name="salaire"></p>

    <h3>Upload</h3>
    <p>Photo : <input type="file" name="photo"></p>
    <p>Documents : <input type="file" name="documents" multiple></p>

    <button type="submit">Tester tout</button>
</form>
</body>
</html>