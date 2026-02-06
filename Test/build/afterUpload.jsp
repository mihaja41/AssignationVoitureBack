<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <title>Résultat - Employé ajouté</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }
        h1, h2 { color: #333; }
        img { max-width: 400px; margin: 10px; border: 2px solid #333; border-radius: 8px; }
        .file { margin: 20px 0; padding: 15px; border: 1px solid #ccc; background: #f9f9f9; border-radius: 8px; }
        a { color: #0066cc; text-decoration: none; font-weight: bold; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>
        <%
            String message = (String) request.getAttribute("message");
            out.print(message != null ? message : "Opération terminée");
        %>
    </h1>

    <h2>Informations employé</h2>
    <%
        Object empObj = request.getAttribute("employe");
        java.util.Map<String, Object> formData = (java.util.Map<String, Object>) request.getAttribute("formData");

        if (empObj != null) {
            String name = (String) empObj.getClass().getMethod("getName").invoke(empObj);
            Object deptObj = empObj.getClass().getMethod("getDepartement").invoke(empObj);
            out.println("<p><strong>Nom :</strong> " + name + "</p>");

            if (deptObj != null) {
                String deptName = (String) deptObj.getClass().getMethod("getName").invoke(deptObj);
                Integer level = (Integer) deptObj.getClass().getMethod("getLevel").invoke(deptObj);
                out.println("<p><strong>Département :</strong> " + deptName + "</p>");
                out.println("<p><strong>Niveau :</strong> " + level + "</p>");
            }

            // === Poste et salaire (gestion manuelle des String[]) ===
            if (formData != null) {
                // Poste
                Object posteObj = formData.get("poste");
                String poste = "";
                if (posteObj instanceof String[]) {
                    String[] array = (String[]) posteObj;
                    poste = array.length > 0 ? array[0] : "";
                } else if (posteObj != null) {
                    poste = posteObj.toString();
                }
                if (!poste.isEmpty()) {
                    out.println("<p><strong>Poste :</strong> " + poste + "</p>");
                }

                // Salaire
                Object salaireObj = formData.get("salaire");
                String salaire = "";
                if (salaireObj instanceof String[]) {
                    String[] array = (String[]) salaireObj;
                    salaire = array.length > 0 ? array[0] : "";
                } else if (salaireObj != null) {
                    salaire = salaireObj.toString();
                }
                if (!salaire.isEmpty()) {
                    out.println("<p><strong>Salaire :</strong> " + salaire + "</p>");
                }

                // Loisirs
                Object loisirsObj = formData.get("loisirs");
                if (loisirsObj instanceof String[] && ((String[]) loisirsObj).length > 0) {
                    String[] loisirs = (String[]) loisirsObj;
                    out.println("<p><strong>Loisirs :</strong> " + String.join(", ", loisirs) + "</p>");
                }
            }
        } else {
            out.println("<p>Aucun employé reçu.</p>");
        }
    %>

    <h2>Fichiers uploadés</h2>
    <%
        java.util.List<String> savedFiles = (java.util.List<String>) request.getAttribute("savedFiles");
        if (savedFiles == null || savedFiles.isEmpty()) {
            out.println("<p>Aucun fichier n'a été uploadé.</p>");
        } else {
            for (String fileUrl : savedFiles) {
                String fileName = fileUrl.substring(fileUrl.lastIndexOf("/") + 1);
    %>
                <div class="file">
                    <p><strong>Fichier :</strong> 
                        <a href="<%= fileUrl %>" target="_blank"><%= fileName %></a>
                    </p>
                    <img src="<%= fileUrl %>" alt="Fichier uploadé" 
                         onerror="this.style.display='none'; this.alt='Ce fichier n\'est pas une image';">
                </div>
    <%
            }
        }
    %>

    <br><br>
    <a href="/test_app/addEmpWithFile.jsp">← Ajouter un autre employé</a>
</body>
</html>