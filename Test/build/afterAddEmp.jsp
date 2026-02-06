<%@ page import="main.java.class_object.Employe" %>
<%@ page import="main.java.class_object.Departement" %>
<%
    Employe e = (Employe) request.getAttribute("emp");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Informations enregistrées</title>
</head>
<body>

<h2>Informations de l'employé ajouté :</h2>

<ul>
    <li>ID : <%= e != null ? e.getId() : "?" %></li>
    <li>Nom : <%= e != null ? e.getName() : "?" %></li>
    <li>Email : <%= e != null ? e.getEmail() : "?" %></li>
    <li>Département :
        <%= (e != null && e.getDepartement() != null)
            ? e.getDepartement().getName()
            : "Non défini" %>
    </li>
</ul>

<p><a href="addEmp.jsp">Ajouter un autre employé</a></p>

</body>
</html>
