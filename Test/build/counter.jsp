</head>
<body>
<div class="counter-box">
    <h1>Compteur de Visites</h1>
    <div class="counter-value"><%= request.getAttribute("counter") %></div>
    <p>Derniere incrémentation : <%= request.getAttribute("lastIncrement") %></p>
    
    <a href="<%= request.getContextPath() %>/session/increment" class="btn">➕ Incrémenter</a>
    <a href="<%= request.getContextPath() %>/session/show" class="btn">📦 Voir Session</a>
</div>
</body>
</html>