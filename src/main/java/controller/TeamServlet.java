package controller;

import model.Employee;
import model.Manager;
import model.Team;
import model.TeamMember;
import model.User;
import service.EmployeeService;
import service.ManagerService;
import service.TeamMemberService;
import service.TeamService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@WebServlet("/team")
public class TeamServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private TeamService teamService;
    private TeamMemberService teamMemberService;
    private ManagerService managerService;
    private EmployeeService employeeService;
    private service.AttendanceService attendanceService;

    @Override
    public void init() {
        employeeService = new EmployeeService();
        managerService = new ManagerService();
        teamService = new TeamService(managerService, employeeService);
        teamMemberService = new TeamMemberService(employeeService);
        attendanceService = new service.AttendanceService(employeeService);
    }

    private User currentUser(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s == null ? null : (User) s.getAttribute("user");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User u = currentUser(req);
        if (u == null) { resp.sendError(HttpServletResponse.SC_UNAUTHORIZED); return; }
        String action = param(req, "action", "list");
        try {
            switch (action) {
                case "list":
                    requireHr(u);
                    page(resp, "MANAGE TEAMS", buildListBody(param(req, "q", ""), param(req, "department", ""),
                            param(req, "status", ""), param(req, "managerId", "")));
                    break;
                case "view":
                    page(resp, "TEAM DETAILS", buildViewBody(u, parseId(req)));
                    break;
                case "myteam":
                    requireEmployee(u);
                    page(resp, "MY TEAM", buildMyTeamBody(u));
                    break;
                case "myteams":
                    requireManager(u);
                    page(resp, "MY TEAMS", buildMyTeamsBody(u));
                    break;
                case "createForm":
                    requireHr(u);
                    page(resp, "CREATE TEAM", buildFormBody(null));
                    break;
                case "editForm":
                    page(resp, "EDIT TEAM", buildEditFormBody(u, parseId(req)));
                    break;
                default:
                    requireHr(u);
                    page(resp, "MANAGE TEAMS", buildListBody("", "", "", ""));
            }
        } catch (IllegalArgumentException | IllegalStateException ex) {
            error(resp, ex.getMessage());
        } catch (RuntimeException ex) {
            log("Team error", ex);
            error(resp, "Database error. Check the Tomcat console for details.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        User u = currentUser(req);
        if (u == null) { resp.sendError(HttpServletResponse.SC_UNAUTHORIZED); return; }
        String action = param(req, "action", "");
        try {
            switch (action) {
                case "create": {
                    requireHr(u);
                    teamService.createTeam(param(req, "teamName", ""), param(req, "description", ""),
                            param(req, "department", ""), param(req, "managerId", ""), param(req, "status", "ACTIVE"));
                    page(resp, "MANAGE TEAMS", ok("Team created successfully.") + buildListBody("", "", "", ""));
                    break;
                }
                case "update": {
                    int id = parseId(req);
                    if (u.isHr()) {
                        teamService.updateTeamByHr(id, param(req, "teamName", ""), param(req, "description", ""),
                                param(req, "department", ""), param(req, "managerId", ""), param(req, "status", "ACTIVE"));
                    } else if (u.isManager()) {
                        teamService.updateTeamByManager(u.getManagerId(), id, param(req, "description", ""),
                                param(req, "status", "ACTIVE"));
                    } else {
                        throw new IllegalStateException("You are not allowed to update teams.");
                    }
                    page(resp, "TEAM DETAILS", ok("Team updated successfully.") + buildViewBody(u, id));
                    break;
                }
                case "delete": {
                    requireHr(u);
                    int id = parseId(req);
                    teamService.deleteTeam(id);
                    page(resp, "MANAGE TEAMS", ok("Team deleted successfully.") + buildListBody("", "", "", ""));
                    break;
                }
                default:
                    resp.sendRedirect(req.getContextPath() + "/team?action=list");
            }
        } catch (IllegalArgumentException | IllegalStateException ex) {
            error(resp, ex.getMessage());
        } catch (RuntimeException ex) {
            log("Team error", ex);
            error(resp, "Database error. Check the Tomcat console for details.");
        }
    }

    // ---------------- permission helpers ----------------

    private void requireHr(User u) { if (!u.isHr()) throw new IllegalStateException("HR only."); }
    private void requireManager(User u) { if (!u.isManager()) throw new IllegalStateException("Managers only."); }
    private void requireEmployee(User u) { if (u.isHr() || u.isManager()) throw new IllegalStateException("Employees only."); }

    private boolean canManageTeam(User u, Team t) {
        if (u.isHr()) return true;
        return u.isManager() && t.getManagerId() != null && t.getManagerId().equalsIgnoreCase(u.getManagerId());
    }

    // ---------------- body builders ----------------

    private String buildListBody(String q, String dept, String status, String mgr) {
        List<Team> teams = (q.isEmpty() && dept.isEmpty() && status.isEmpty() && mgr.isEmpty())
                ? teamService.getAllTeams() : teamService.search(q, dept, status, mgr);

        StringBuilder sb = new StringBuilder();
        sb.append("<div class='team-top-bar'>");
        sb.append("<div class='team-header-title'><h3>Team Directory</h3><p>Manage organizational teams, assign managers, and configure rosters</p></div>");
        sb.append("<button type='button' class='btn-create-team' onclick=\"TeamsUI.showCreateForm(document.getElementById('result'))\">+ Create New Team</button>");
        sb.append("</div>");
        sb.append(searchFilterForm(q, dept, status, mgr));
        sb.append("<table><tr><th>Team ID</th><th>Team Name</th><th>Department</th><th>Manager</th>"
                + "<th>Members</th><th>Status</th><th class='actions-col'>Actions</th></tr>");
        if (teams.isEmpty()) sb.append("<tr><td colspan='7'>No teams found.</td></tr>");
        for (Team t : teams) {
            sb.append("<tr><td>").append(t.getTeamId()).append("</td><td>").append(esc(t.getTeamName()))
              .append("</td><td>").append(esc(t.getDepartment())).append("</td><td>").append(esc(t.getManagerName()))
              .append("</td><td>").append(teamService.activeMemberCount(t.getId()))
              .append("</td><td><span class='").append(t.getStatus()).append("'>").append(t.getStatus())
              .append("</span></td><td class='actions-cell'><div class='action-btn-group'>")
              .append("<button type='button' class='view-team' data-id='").append(t.getId()).append("'>View</button>")
              .append("<button type='button' class='edit-team' data-id='").append(t.getId()).append("'>Edit</button>")
              .append("<button type='button' class='delete-team' data-id='").append(t.getId())
              .append("' data-name='").append(esc(t.getTeamName())).append("'>Delete</button>")
              .append("</div></td></tr>");
        }
        sb.append("</table>");
        return sb.toString();
    }

    private String buildViewBody(User u, int id) {
        Team t = teamService.requireTeam(id);
        if (!u.isHr()) {
            if (u.isManager()) {
                if (t.getManagerId() == null || !t.getManagerId().equalsIgnoreCase(u.getManagerId()))
                    throw new IllegalStateException("You can only view teams assigned to you.");
            } else {
                throw new IllegalStateException("You are not allowed to view this team directly. Use My Team.");
            }
        }
        boolean canEditInfo = canManageTeam(u, t);          // HR, or this team's own Manager
        boolean canManageMembers = u.isHr();                 // only HR adds/removes members now
        List<TeamMember> members = teamMemberService.getMembers(id);
        java.time.LocalDate today = java.time.LocalDate.now();

        StringBuilder sb = new StringBuilder();
        sb.append("<h2>").append(esc(t.getTeamName())).append(" (").append(t.getTeamId()).append(")</h2>");
        sb.append("<table>")
          .append(row("Description", t.getDescription() == null ? "--" : t.getDescription()))
          .append(row("Department", t.getDepartment()))
          .append(row("Team Manager", t.getManagerName()))
          .append(rowHtml("Status", "<span class='" + t.getStatus() + "'>" + t.getStatus() + "</span>"))
          .append(row("Created Date", t.getCreatedAtText()))
          .append("</table>");

        if (canEditInfo) {
            sb.append("<div class='team-actions-bar'>");
            sb.append("<button type='button' class='edit-team btn-edit-info' data-id='").append(t.getId()).append("'>Edit Team Info</button>");
            if (u.isHr())
                sb.append("<button type='button' class='delete-team btn-delete-info' data-id='").append(t.getId())
                  .append("' data-name='").append(esc(t.getTeamName())).append("'>Delete Team</button>");
            sb.append("</div>");
        }

        sb.append("<h2>Team Members &mdash; Today's Attendance</h2>");
        sb.append("<table><tr><th>Employee ID</th><th>Name</th><th>Designation</th><th>Joined</th>"
                + "<th>Member Status</th><th>Check-In</th><th>Today</th>");
        if (canManageMembers) sb.append("<th>Action</th>");
        sb.append("</tr>");
        int cols = canManageMembers ? 8 : 7;
        if (members.isEmpty()) sb.append("<tr><td colspan='").append(cols).append("'>No members yet.</td></tr>");
        for (TeamMember m : members) {
            model.Attendance a = attendanceService.findRecord(m.getEmployeeId(), today);
            String checkIn = a == null ? "--" : a.getCheckInText();
            String todayStatus = a == null ? "NOT MARKED" : a.getStatusLabel();
            String todayCell = a == null ? todayStatus : "<span class='" + a.getStatus() + "'>" + todayStatus + "</span>";

            sb.append("<tr><td>").append(esc(m.getEmployeeId())).append("</td><td>").append(esc(m.getEmployeeName()))
              .append("</td><td>").append(esc(m.getDesignation())).append("</td><td>").append(m.getJoinedDateText())
              .append("</td><td><span class='").append(m.getStatus()).append("'>").append(m.getStatus())
              .append("</span></td><td>").append(checkIn).append("</td><td>").append(todayCell).append("</td>");
            if (canManageMembers)
                sb.append("<td class='actions-cell'><div class='action-btn-group'><button type='button' class='remove-member' data-team-id='").append(t.getId())
                  .append("' data-employee-id='").append(esc(m.getEmployeeId())).append("' data-name='")
                  .append(esc(m.getEmployeeName())).append("'>Remove</button></div></td>");
            sb.append("</tr>");
        }
        sb.append("</table>");

        if (canManageMembers) {
            Set<String> currentIds = new HashSet<>();
            for (TeamMember m : members) currentIds.add(m.getEmployeeId());
            List<Employee> addable = new ArrayList<>();
            for (Employee e : employeeService.getActiveEmployees()) if (!currentIds.contains(e.getId())) addable.add(e);

            sb.append("<h2>Add Team Member</h2>");
            if (addable.isEmpty()) {
                sb.append("<p>No available employees to add right now.</p>");
            } else {
                sb.append("<form class='team-form' data-url='team-member'>")
                  .append("<input type='hidden' name='action' value='add'>")
                  .append("<input type='hidden' name='teamId' value='").append(t.getId()).append("'>")
                  .append("<label>Employee</label><select name='employeeId' required>");
                for (Employee e : addable)
                    sb.append("<option value='").append(e.getId()).append("'>").append(esc(e.getId()))
                      .append(" - ").append(esc(e.getName())).append("</option>");
                sb.append("</select><button type='submit'>Add Employee</button></form>");
            }
        }

        sb.append("<p><button type='button' class='back-to-list' onclick=\"TeamsUI.showList(document.getElementById('result'))\">Back to Teams</button></p>");
        return sb.toString();
    }

    private String buildMyTeamBody(User u) {
        List<Team> teams = teamService.getMyTeamsForEmployee(u.getEmployeeId());
        if (teams.isEmpty()) return "<p>You are not currently assigned to any team.</p>";

        java.time.LocalDate today = java.time.LocalDate.now();
        StringBuilder sb = new StringBuilder();
        for (Team t : teams) {
            List<TeamMember> members = teamMemberService.getMembers(t.getId());
            sb.append("<h2>").append(esc(t.getTeamName())).append("</h2>");
            sb.append("<table>")
              .append(row("Department", t.getDepartment()))
              .append(row("Team Manager", t.getManagerName()))
              .append(row("Description", t.getDescription() == null ? "--" : t.getDescription()))
              .append("</table>");
            sb.append("<h2>Team Members &mdash; Today's Attendance</h2>");
            sb.append("<table><tr><th>Name</th><th>Designation</th><th>Check-In</th><th>Status</th></tr>");
            if (members.isEmpty()) sb.append("<tr><td colspan='4'>No members yet.</td></tr>");
            for (TeamMember m : members) {
                model.Attendance a = attendanceService.findRecord(m.getEmployeeId(), today);
                String checkIn = a == null ? "--" : a.getCheckInText();
                String status = a == null ? "NOT MARKED" : a.getStatusLabel();
                sb.append("<tr><td>").append(esc(m.getEmployeeName())).append("</td><td>")
                  .append(esc(m.getDesignation())).append("</td><td>").append(checkIn).append("</td><td>")
                  .append(a == null ? status : "<span class='" + a.getStatus() + "'>" + status + "</span>")
                  .append("</td></tr>");
            }
            sb.append("</table>");
        }
        return sb.toString();
    }

    private String buildMyTeamsBody(User u) {
        List<Team> teams = teamService.getTeamsForManager(u.getManagerId());
        StringBuilder sb = new StringBuilder();
        sb.append("<table><tr><th>Team ID</th><th>Team Name</th><th>Department</th><th>Members</th>"
                + "<th>Status</th><th>Action</th></tr>");
        if (teams.isEmpty()) sb.append("<tr><td colspan='6'>No teams assigned to you yet.</td></tr>");
        for (Team t : teams) {
            sb.append("<tr><td>").append(t.getTeamId()).append("</td><td>").append(esc(t.getTeamName()))
              .append("</td><td>").append(esc(t.getDepartment())).append("</td><td>")
              .append(teamService.activeMemberCount(t.getId())).append("</td><td><span class='")
              .append(t.getStatus()).append("'>").append(t.getStatus()).append("</span></td>")
              .append("<td class='actions-cell'><div class='action-btn-group'><button type='button' class='view-team' data-id='").append(t.getId())
              .append("'>View / Manage</button></div></td></tr>");
        }
        sb.append("</table>");
        return sb.toString();
    }

    private String buildFormBody(Team existing) {
        boolean editing = existing != null;
        StringBuilder sb = new StringBuilder();
        sb.append("<form class='team-form' data-url='team'>");
        sb.append("<input type='hidden' name='action' value='").append(editing ? "update" : "create").append("'>");
        if (editing) sb.append("<input type='hidden' name='id' value='").append(existing.getId()).append("'>");
        sb.append("<label>Team Name</label><input name='teamName' maxlength='100' required value='")
          .append(editing ? esc(existing.getTeamName()) : "").append("'>");
        sb.append("<label>Description</label><input name='description' maxlength='500' value='")
          .append(editing && existing.getDescription() != null ? esc(existing.getDescription()) : "").append("'>");
        sb.append("<label>Department</label><input name='department' maxlength='50' required value='")
          .append(editing ? esc(existing.getDepartment()) : "").append("'>");
        sb.append("<label>Team Manager</label><select name='managerId' required><option value=''>-- choose --</option>");
        for (Manager m : managerService.getActiveManagers()) {
            boolean sel = editing && existing.getManagerId() != null && existing.getManagerId().equalsIgnoreCase(m.getId());
            sb.append("<option value='").append(m.getId()).append("'").append(sel ? " selected" : "").append(">")
              .append(esc(m.getId())).append(" - ").append(esc(m.getName())).append("</option>");
        }
        sb.append("</select>");
        sb.append("<label>Status</label><select name='status'>");
        for (Team.Status s : Team.Status.values()) {
            boolean sel = editing && existing.getStatus() == s;
            sb.append("<option value='").append(s).append("'").append(sel ? " selected" : "").append(">").append(s).append("</option>");
        }
        sb.append("</select>");
        sb.append("<button type='submit'>").append(editing ? "Update Team" : "Create Team").append("</button>");
        sb.append("</form>");
        return sb.toString();
    }

    private String buildEditFormBody(User u, int id) {
        Team t = teamService.requireTeam(id);
        if (u.isHr()) return buildFormBody(t);
        if (u.isManager() && t.getManagerId() != null && t.getManagerId().equalsIgnoreCase(u.getManagerId())) {
            StringBuilder sb = new StringBuilder();
            sb.append("<table>")
              .append(row("Team Name", t.getTeamName()))
              .append(row("Department", t.getDepartment()))
              .append(row("Team Manager", t.getManagerName()))
              .append("</table>");
            sb.append("<form class='team-form' data-url='team'>")
              .append("<input type='hidden' name='action' value='update'>")
              .append("<input type='hidden' name='id' value='").append(id).append("'>")
              .append("<label>Description</label><input name='description' maxlength='500' value='")
              .append(t.getDescription() != null ? esc(t.getDescription()) : "").append("'>")
              .append("<label>Status</label><select name='status'>");
            for (Team.Status s : Team.Status.values()) {
                boolean sel = t.getStatus() == s;
                sb.append("<option value='").append(s).append("'").append(sel ? " selected" : "").append(">").append(s).append("</option>");
            }
            sb.append("</select><button type='submit'>Update Team</button></form>");
            return sb.toString();
        }
        throw new IllegalStateException("You are not allowed to edit this team.");
    }

    private String searchFilterForm(String q, String dept, String status, String mgr) {
        StringBuilder sb = new StringBuilder("<div class='team-search-card'><form class='team-search-form'>");
        sb.append("<div class='form-group'><label>Search</label><input name='q' placeholder='Team name, dept, mgr...' value='").append(esc(q)).append("'></div>");
        sb.append("<div class='form-group'><label>Department</label><input name='department' placeholder='e.g. Engineering' value='").append(esc(dept)).append("'></div>");
        sb.append("<div class='form-group'><label>Status</label><select name='status'><option value=''>All Statuses</option>");
        for (Team.Status s : Team.Status.values())
            sb.append("<option value='").append(s).append("'").append(s.name().equals(status) ? " selected" : "")
              .append(">").append(s).append("</option>");
        sb.append("</select></div>");
        sb.append("<div class='form-group'><label>Manager</label><select name='managerId'><option value=''>All Managers</option>");
        for (Manager m : managerService.getActiveManagers())
            sb.append("<option value='").append(m.getId()).append("'").append(m.getId().equalsIgnoreCase(mgr) ? " selected" : "")
              .append(">").append(esc(m.getId())).append(" - ").append(esc(m.getName())).append("</option>");
        sb.append("</select></div>");
        sb.append("<button type='submit' class='btn-filter'>")
          .append("<svg width='14' height='14' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2.4' stroke-linecap='round' stroke-linejoin='round'><circle cx='11' cy='11' r='8'></circle><line x1='21' y1='21' x2='16.65' y2='16.65'></line></svg>")
          .append("<span>Filter</span></button></form></div>");
        return sb.toString();
    }

    // ---------------- utils ----------------

    private void page(HttpServletResponse resp, String title, String body) throws IOException {
        resp.setContentType("text/html;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        out.println("<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><title>" + esc(title)
                + "</title></head><body><div class='wrap'><h1>" + esc(title) + "</h1>" + body + "</div></body></html>");
    }

    private void error(HttpServletResponse resp, String message) throws IOException {
        page(resp, "Team", "<div class='msg err'>" + esc(message) + "</div>");
    }

    private static String ok(String msg) { return "<div class='msg ok'>" + esc(msg) + "</div>"; }
    private static String row(String k, String v) { return "<tr><th>" + k + "</th><td>" + esc(v) + "</td></tr>"; }
    private static String rowHtml(String k, String html) { return "<tr><th>" + k + "</th><td>" + html + "</td></tr>"; }

    private int parseId(HttpServletRequest req) {
        try { return Integer.parseInt(param(req, "id", "0")); }
        catch (NumberFormatException e) { throw new IllegalArgumentException("Invalid team."); }
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