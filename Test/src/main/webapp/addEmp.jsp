<%@ page contentType="text/html; charset=UTF-8" %>  
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <h1>3255</h1>
    <form method="post" action="/test_app/save-employe">
        <input type="text" name="name" placeholder="Nom">
        <input type="text" name="departement.name" placeholder="Dept Nom">
        <input type="number" name="departement.level" placeholder="Niveau">
        <button type="submit">Envoyer</button>
    </form>
</body>
</html>
