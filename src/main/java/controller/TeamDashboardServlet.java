package controller;

import model.User;
import service.EmployeeService;
import service.ManagerService;
import service.TeamService;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Map;

@WebServlet("/team-dashboard")
public class TeamDashboardServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private TeamService teamService;

    @Override
    public void init() {
        teamService = new TeamService(new ManagerService(), new EmployeeService());
    }

    private User currentUser(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s == null ? null : (User) s.getAttribute("user");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User u = currentUser(req);
        if (u == null) { resp.sendError(HttpServletResponse.SC_UNAUTHORIZED); return; }
        if (!u.isHr()) { resp.sendError(HttpServletResponse.SC_FORBIDDEN); return; }

        try {
            int[] totals = teamService.dashboardTotals();   // [total, active, inactive, totalMembers]
            Map<String, Integer> byDept = teamService.departmentCounts();

            StringBuilder sb = new StringBuilder();
            sb.append("<div class='stats'>")
              .append(stat(totals[0], "Total Teams")).append(stat(totals[1], "Active Teams"))
              .append(stat(totals[2], "Inactive Teams")).append(stat(totals[3], "Total Team Members"))
              .append("</div>");
            sb.append("<h2>Department-wise</h2><table><tr><th>Department</th><th>Teams</th></tr>");
            if (byDept.isEmpty()) sb.append("<tr><td colspan='2'>No active teams yet.</td></tr>");
            for (Map.Entry<String, Integer> e : byDept.entrySet())
                sb.append("<tr><td>").append(esc(e.getKey())).append("</td><td>").append(e.getValue()).append("</td></tr>");
            sb.append("</table>");

            resp.setContentType("text/html;charset=UTF-8");
            PrintWriter out = resp.getWriter();
            out.println("<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><title>Team Dashboard</title></head>"
                    + "<body><div class='wrap'><h1>TEAM DASHBOARD</h1>" + sb + "</div></body></html>");
        } catch (RuntimeException ex) {
            log("Team dashboard error", ex);
            resp.setContentType("text/html;charset=UTF-8");
            resp.getWriter().println("<div class='wrap'><h1>Team Dashboard</h1>"
                    + "<div class='msg err'>Database error. Check the Tomcat console.</div></div>");
        }
    }

    private static String stat(int n, String label) { return "<div class='stat'><b>" + n + "</b>" + label + "</div>"; }

    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
}