<%@ page contentType="text/html;charset=UTF-8" %>
<html>
<head>
    <title>Map Test&lt;String,Object&gt;</title>
</head>
<body>
<div class="form">
    <h2>Test Map</h2>
    <form action="<%= request.getContextPath() %>/test-map" method="post">
        
        <label>Name:</label>
        <input type="text" name="name" value="Rakoto Jean" required><br>

        <label>QI</label> :</label>
        <input type="text" name="qi" value="100" required><br>

        <label>Leasures:</label><br>
        <input type="checkbox" name="leasures" value="foot"> Football<br>
        <input type="checkbox" name="leasures" value="manga" checked> Manga<br>
        <input type="checkbox" name="leasures" value="music" checked> Music<br>
        <input type="checkbox" name="leasures" value="travel"> Travel<br>

        <button type="submit">Validate</button>
    </form>
</div>
</body>
</html>