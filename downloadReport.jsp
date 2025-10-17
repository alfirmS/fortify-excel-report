<%@ page import="java.io.*, java.net.*, org.json.*, java.util.*" %>
<%
response.setContentType("application/octet-stream");
response.setHeader("Content-Disposition", "attachment; filename=\"Fortify_Report.xlsx\"");

String token = (String) session.getAttribute("SSC_TOKEN");
String baseUrl = (String) session.getAttribute("SSC_BASE_URL");
String username = (String) session.getAttribute("SSC_USERNAME");
String password = (String) session.getAttribute("SSC_PASSWORD");

String projectVersion = request.getParameter("projectVersion");
String engineType = request.getParameter("engineType");
String outputName = request.getParameter("outputName");

PrintWriter log = new PrintWriter(System.out, true); // log ke catalina.out
log.println("[DEBUG] ====== Fortify downloadReport.jsp started ======");
log.println("[DEBUG] projectId=" + projectVersion + ", engineType=" + engineType + ", output=" + outputName);

try {
    if (token == null || baseUrl == null) {
        log.println("[ERROR] Session expired or missing token.");
        response.setStatus(401);
        out.print("Session expired, please re-login.");
        return;
    }

    // Contoh: gunakan fcli atau script CLI
    String cmd = "python3 /opt/tomcat9.0.105/webapps/fortify-report/python/ssc_export_cli.py " +
                 "--base-url " + baseUrl + " " +
                 "--user " + username + " " +
                 "--pass " + '"' + password + '"' + " " +
                 "--project-version " + projectVersion + " " +
                 "--engine-type " + engineType + " " +
                 "--output /opt/tomcat9.0.105/webapps/fortify-report/reports/" + outputName + " " + "--insecure";

    log.println("[DEBUG] Command: " + cmd);

    ProcessBuilder pb = new ProcessBuilder("bash", "-c", cmd);
    pb.redirectErrorStream(true);
    Process p = pb.start();

    BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()));
    String line;
    while ((line = reader.readLine()) != null) {
        log.println("[CLI] " + line);
    }

    int exitCode = p.waitFor();
    log.println("[DEBUG] CLI exit code = " + exitCode);

    File file = new File("/opt/tomcat9.0.105/webapps/fortify-report/reports/" + outputName);
    if (!file.exists()) {
        log.println("[ERROR] Output file not found: " + file.getAbsolutePath());
        response.setStatus(500);
        out.print("Gagal generate file report. Cek log di catalina.out");
        return;
    }

    FileInputStream fis = new FileInputStream(file);
    byte[] buffer = new byte[4096];
    int bytesRead;
    ServletOutputStream os = response.getOutputStream();
    while ((bytesRead = fis.read(buffer)) != -1) {
        os.write(buffer, 0, bytesRead);
    }
    fis.close();
    os.flush();
    log.println("[DEBUG] Report successfully sent to client.");

} catch (Exception e) {
    log.println("[EXCEPTION] " + e.toString());
    e.printStackTrace(log); // tampil di catalina.out
    response.setStatus(500);
    out.print("Server error: " + e.getMessage());
}
%>
