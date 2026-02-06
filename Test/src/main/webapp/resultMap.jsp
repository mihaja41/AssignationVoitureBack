<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Set" %>
<html>
<head>
    <title>Map result</title>
</head>
<body>
<div class="box">
    <h1>OK !</h1>

    <p><strong>Name :</strong> ${name}</p>
    <p><strong>QI :</strong> ${qi}</p>

    <h3>Leasures selected:</h3>
    <ul>
    <%
        Object loisirsObj = request.getAttribute("leasures");
        if (loisirsObj instanceof String[]) {
            String[] loisirs = (String[]) loisirsObj;
            if (loisirs.length == 0) {
                out.println("<li>No leasure</li>");
            } else {
                for (String l : loisirs) {
                    out.println("<li>" + l + "</li>");
                }
            }
        } else {
            out.println("<li>No distraction</li>");
        }
    %>
    </ul>

    <hr>

    <h3>All Map&lt;String, Object&gt; received in controller :</h3>
    <pre>
<%
    Map<String, Object> formData = (Map<String, Object>) request.getAttribute("formData");
    if (formData == null || formData.isEmpty()) {
        out.println("Aucune donnée reçue");
    } else {
        for (Map.Entry<String, Object> entry : formData.entrySet()) {
            String key = entry.getKey();
            Object value = entry.getValue();

            if (value instanceof String[]) {
                String[] arr = (String[]) value;
                out.println(key + " → [ " + String.join(", ", arr) + " ] (String[])");
            } else {
                out.println(key + " → " + value + " (" + (value != null ? value.getClass().getSimpleName() : "null") + ")");
            }
        }
    }
%>
    </pre>
</div>
</body>
</html>