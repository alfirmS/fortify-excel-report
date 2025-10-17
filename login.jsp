<%@ page import="java.io.*, java.net.*, org.json.*" %>
<html>
<head>
<title>Login ke Fortify SSC</title>
<style>
body {
    font-family: 'Segoe UI', Arial, sans-serif;
    background: linear-gradient(120deg, #007bff, #00bcd4);
    display: flex;
    align-items: center;
    justify-content: center;
    height: 100vh;
    margin: 0;
}
.container {
    background: white;
    padding: 40px 50px;
    border-radius: 12px;
    box-shadow: 0 4px 15px rgba(0,0,0,0.2);
    width: 360px;
    text-align: center;
}
h2 {
    color: #333;
    margin-bottom: 20px;
}
label {
    display: block;
    text-align: left;
    margin-top: 12px;
    font-weight: bold;
    color: #555;
}
input {
    width: 100%;
    padding: 10px;
    margin-top: 6px;
    border: 1px solid #ccc;
    border-radius: 6px;
    font-size: 14px;
}
button {
    background: #007bff;
    color: white;
    padding: 10px 20px;
    border: none;
    border-radius: 6px;
    margin-top: 20px;
    cursor: pointer;
    width: 100%;
    font-size: 15px;
}
button:hover {
    background: #0056b3;
}
.msg {
    margin-top: 15px;
    font-size: 13px;
    color: red;
}
footer {
    margin-top: 30px;
    font-size: 12px;
    color: #888;
}
</style>
</head>
<body>
<div class="container">
<h2>Login ke Fortify SSC</h2>

<form method="POST">
    <label>Base URL (SSC)</label>
    <input type="text" name="baseUrl" value="your SSC Fortify url" required>

    <label>Username</label>
    <input type="text" name="username" required>

    <label>Password</label>
    <input type="password" name="password" required>

    <button type="submit">Login</button>
</form>

<%
if ("POST".equalsIgnoreCase(request.getMethod())) {
    String baseUrl = request.getParameter("baseUrl");
    String username = request.getParameter("username");
    String password = request.getParameter("password");

    try {
        // Buat Basic Auth
        String creds = username + ":" + password;
        String basicAuth = new String(java.util.Base64.getEncoder().encode(creds.getBytes("UTF-8")));

        // Buat request ke Fortify SSC API untuk mendapatkan token
        URL url = new URL(baseUrl + "/api/v1/tokens");
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Authorization", "Basic " + basicAuth);
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setRequestProperty("Accept", "application/json");
        conn.setDoOutput(true);

        String payload = "{\"type\": \"UnifiedLoginToken\", \"description\": \"Fortify Report Generator\"}";
        try (OutputStream os = conn.getOutputStream()) {
            os.write(payload.getBytes("UTF-8"));
        }

        int status = conn.getResponseCode();

        if (status == 201) {
            // Ambil token dari respons JSON
            BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream(), "UTF-8"));
            String jsonText = br.lines().reduce("", (a,b) -> a + b);
            br.close();

            JSONObject json = new JSONObject(jsonText);
            String token = json.getJSONObject("data").getString("token");

            // Simpan ke session
            session.setAttribute("SSC_TOKEN", token);
            session.setAttribute("SSC_BASE_URL", baseUrl);
            session.setAttribute("SSC_USERNAME", username);
            session.setAttribute("SSC_PASSWORD", password);

            // Redirect ke halaman generate.jsp
            response.sendRedirect("generate.jsp");
        } else {
            BufferedReader err = new BufferedReader(new InputStreamReader(conn.getErrorStream(), "UTF-8"));
            String errorText = err.lines().reduce("", (a,b) -> a + b);
            err.close();
%>
            <div class="msg">❌ Login gagal (HTTP <%= status %>): <%= errorText %></div>
<%
        }
    } catch (Exception e) {
%>
        <div class="msg">⚠️ Error: <%= e.getMessage() %></div>
<%
    }
}
%>

<footer>Fortify SSC Report Generator @Copyright 2025</footer>
</div>
</body>
</html>
