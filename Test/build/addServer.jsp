<%@ page contentType="text/html; charset=UTF-8" %>  
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <form action="/test_app/add" method="post">
        Name :<input type="text"  name="name">
        Number :<input type="number"  name="number">
        <input type="submit" value="Add Post">
    </form>
    <!-- <form action="/test_app/add" method="get">
    <% if (request.getAttribute("id") != null) { %>
        <h1>RECEIVED ID : ${id}</h1>
        <input type="hidden" name="id" value="<%= request.getAttribute("id") %>">
    <% } %>        
        Name :<input type="text"  name="name">
        Number :<input type="number"  name="number">
        <input type="submit" value="Add Get">
    </form> -->
    <!-- <form action="/test_app/pass" method="get">
        Today'date on : <input type="date" name="date">
        <input type="submit" value="see">
    </form> -->

</body>
</html>
