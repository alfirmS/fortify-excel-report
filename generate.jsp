<%@ page import="java.io.*, java.net.*, org.json.*" %>
<%
    String token = (String) session.getAttribute("SSC_TOKEN");
    String baseUrl = (String) session.getAttribute("SSC_BASE_URL");
    String username = (String) session.getAttribute("SSC_USERNAME");
    String password = (String) session.getAttribute("SSC_PASSWORD");

    if (token == null || baseUrl == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>
<html>
<head>
<title>Generate Fortify SSC Report</title>
<style>
body {
    font-family: 'Segoe UI', Arial;
    background: #f8f9fa;
    margin: 40px;
}
.container {
    background: white;
    padding: 25px 40px;
    border-radius: 12px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    max-width: 600px;
    margin: auto;
}
h2 { color: #333; }
label { font-weight: bold; display: block; margin-top: 12px; }
select, input {
    padding: 8px;
    margin-top: 5px;
    width: 100%;
    border: 1px solid #ccc;
    border-radius: 6px;
}
input[type=submit] {
    margin-top: 20px;
    background-color: #007bff;
    color: white;
    padding: 10px 20px;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-size: 15px;
}
button {
    margin-top: 20px;
    background-color: #007bff;
    color: white;
    padding: 10px 20px;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-size: 15px;
}
button:hover { background-color: #0056b3; }
#progressBox {
    display: none;
    margin-top: 25px;
}
.progress-bar {
    width: 0%;
    height: 22px;
    background: linear-gradient(90deg, #007bff, #00bfff);
    text-align: center;
    color: white;
    border-radius: 5px;
    transition: width 0.4s ease;
}
#statusText {
    font-style: italic;
    margin-top: 8px;
    color: #555;
}
</style>

<script>
function startGenerate(e) {
    e.preventDefault();
    const form = e.target;
    const data = new URLSearchParams(new FormData(form)); // 🔥 ubah jadi form-urlencoded

    const projectId = form.projectVersion.value;
    if (!projectId) {
        alert("⚠️ Pilih project version terlebih dahulu!");
        return;
    }

    document.getElementById('progressBox').style.display = 'block';
    document.getElementById('progressBar').style.width = '20%';
    document.getElementById('statusText').innerText = 'Generating report...';

    fetch('downloadReport.jsp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: data
    })
    .then(res => {
        if (!res.ok) throw new Error("Response not OK: " + res.status);
        return res.blob();
    })
    .then(blob => {
        document.getElementById('progressBar').style.width = '100%';
        document.getElementById('statusText').innerText = '✅ Selesai! Mengunduh file...';
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = form.outputName.value;
        document.body.appendChild(a);
        a.click();
        a.remove();
        document.getElementById('progressBox').style.display = 'none';
    })
    .catch(err => {
        alert('❌ Gagal generate: ' + err);
        document.getElementById('statusText').innerText = '❌ Gagal generate.';
    });
}
</script>
</head>
<body>
<div class="container">
<h2>Generate Fortify SSC Report</h2>

<form id="generateForm" onsubmit="startGenerate(event)">
  <label>Project Version:</label>
  <select name="projectVersion" required>
    <option value="">-- pilih project version --</option>
    <%
      try {
          URL url = new URL(baseUrl + "/api/v1/projectVersions?limit=500");
          HttpURLConnection conn = (HttpURLConnection) url.openConnection();
          conn.setRequestProperty("Authorization", "FortifyToken " + token);
          conn.setRequestProperty("Accept", "application/json");

          BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream()));
          String jsonText = br.lines().reduce("", (a,b) -> a + b);
          br.close();

          JSONObject json = new JSONObject(jsonText);
          JSONArray arr = json.getJSONArray("data");

          for (int i = 0; i < arr.length(); i++) {
              JSONObject obj = arr.getJSONObject(i);
              JSONObject proj = obj.getJSONObject("project");
              String name = proj.getString("name") + " - " + obj.getString("name");
              int id = obj.getInt("id");
    %>
              <option value="<%= id %>"><%= name %></option>
    <%
          }
      } catch (Exception e) {
          out.println("<option disabled>Error: " + e.getMessage() + "</option>");
      }
    %>
  </select>

  <label>Engine Type:</label>
  <select name="engineType" required>
      <option value="Webinspect">Webinspect</option>
      <option value="SCA">SCA</option>
      <option value="Sonatype">Sonatype</option>
      <option value="all">All Issues</option>
  </select>

  <label>Output Filename:</label>
  <input type="text" name="outputName" value="Fortify_Report.xlsx" required>

  <button type="submit">Generate & Download</button>
</form>

<div id="progressBox">
  <div class="progress-bar" id="progressBar">Loading...</div>
  <div id="statusText"></div>
</div>
<form method="link" action="logout.jsp">
    <input type="submit" value="Logout"/>
</form>
</div>
</body>
</html>
