package controller;

import model.Team;
import model.User;
import service.EmployeeService;
import service.ManagerService;
import service.TeamMemberService;
import service.TeamService;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.PrintWriter;

@WebServlet("/team-member")
public class TeamMemberServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private TeamService teamService;
    private TeamMemberService teamMemberService;

    @Override
    public void init() {
        EmployeeService employeeService = new EmployeeService();
        ManagerService managerService = new ManagerService();
        teamService = new TeamService(managerService, employeeService);
        teamMemberService = new TeamMemberService(employeeService);
    }

    private User currentUser(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s == null ? null : (User) s.getAttribute("user");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        req.setCharacterEncoding("UTF-8");
        User u = currentUser(req);
        if (u == null) { resp.sendError(HttpServletResponse.SC_UNAUTHORIZED); return; }
        String action = param(req, "action", "");
        try {
            int teamId = Integer.parseInt(param(req, "teamId", "0"));
            teamService.requireTeam(teamId);

            // Only HR adds or removes team members now. Managers may view and edit team info,
            // but no longer manage membership.
            if (!u.isHr()) throw new IllegalStateException("Only HR can manage team members.");

            if ("add".equals(action)) {
                teamMemberService.addMember(teamId, param(req, "employeeId", ""));
                page(resp, "Add Member", "<div class='msg ok'>Employee added to team successfully.</div>");
            } else if ("remove".equals(action)) {
                teamMemberService.removeMember(teamId, param(req, "employeeId", ""));
                page(resp, "Remove Member", "<div class='msg ok'>Employee removed from team successfully.</div>");
            } else {
                throw new IllegalArgumentException("Unknown action.");
            }
        } catch (NumberFormatException ex) {
            page(resp, "Team Member", "<div class='msg err'>Invalid team.</div>");
        } catch (IllegalArgumentException | IllegalStateException ex) {
            page(resp, "Team Member", "<div class='msg err'>" + esc(ex.getMessage()) + "</div>");
        } catch (RuntimeException ex) {
            log("Team member error", ex);
            page(resp, "Team Member", "<div class='msg err'>Database error. Check the Tomcat console.</div>");
        }
    }
    private void page(HttpServletResponse resp, String title, String body) throws IOException {
        resp.setContentType("text/html;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        out.println("<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><title>" + esc(title)
                + "</title></head><body><div class='wrap'><h1>" + esc(title) + "</h1>" + body + "</div></body></html>");
    }

    private static String param(HttpServletRequest req, String name, String def) {
        String v = req.getParameter(name);
        return v == null ? def : v.trim();
    }

    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
}