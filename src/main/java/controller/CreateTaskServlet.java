package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import model.Employee;
import model.Team;
import model.TeamMember;
import model.User;
import service.TaskService;
import util.FileStorageUtil;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/createTask")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,      // 1 MB in memory
    maxFileSize = 25 * 1024 * 1024,       // 25 MB max per file
    maxRequestSize = 50 * 1024 * 1024     // 50 MB max cumulative request
)
public class CreateTaskServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private TaskService taskService;

    @Override
    public void init() {
        this.taskService = new TaskService();
    }

    private User currentUser(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s == null ? null : (User) s.getAttribute("user");
    }

    private boolean isAuthorized(User user) {
        // Only managers are authorized to create/assign tasks
        return user != null && user.isManager();
    }

    private void populateTeamData(HttpServletRequest req, User user) {
        String managerId = user.getManagerId() != null ? user.getManagerId() : user.getUsername();
        List<Team> teams = taskService.getTeamsForManager(managerId);
        List<Employee> teamEmployees = taskService.getEmployeesForManager(managerId);

        Map<Integer, List<TeamMember>> teamMembersMap = new HashMap<>();
        for (Team t : teams) {
            List<TeamMember> members = taskService.getActiveMembersForTeam(t.getId());
            teamMembersMap.put(t.getId(), members);
            t.setMemberCount(members.size());
        }

        req.setAttribute("teams", teams);
        req.setAttribute("teamEmployees", teamEmployees);
        req.setAttribute("teamMembersMap", teamMembersMap);
        req.setAttribute("hasTeams", !teams.isEmpty());
        req.setAttribute("hasMembers", !teamEmployees.isEmpty());
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = currentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login.html");
            return;
        }

        if (!isAuthorized(user)) {
            resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            req.setAttribute("errorMessage", "Access Denied: Only Managers can create and assign tasks. Administrators can view Employee Performance & Ratings.");
            req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
            return;
        }

        populateTeamData(req, user);
        req.getRequestDispatcher("/createTask.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        User user = currentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login.html");
            return;
        }

        if (!isAuthorized(user)) {
            resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            req.setAttribute("errorMessage", "Access Denied: Only Managers can create and assign tasks.");
            req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
            return;
        }

        String title = req.getParameter("taskTitle");
        String description = req.getParameter("description");
        String assignmentMode = req.getParameter("assignmentMode"); // "single", "multiple", "team"
        String assignedTo = req.getParameter("assignedTo");
        String department = req.getParameter("department");
        String priority = req.getParameter("priority");
        String startDate = req.getParameter("startDate");
        String dueDate = req.getParameter("dueDate");
        String targetTeamId = req.getParameter("targetTeamId");

        String managerId = user.getManagerId() != null ? user.getManagerId() : user.getUsername();
        List<Team> teams = taskService.getTeamsForManager(managerId);

        try {
            List<String> targetEmployeeIds = new ArrayList<>();

            if ("multiple".equalsIgnoreCase(assignmentMode)) {
                String[] empIds = req.getParameterValues("assignedEmployees");
                if (empIds == null || empIds.length == 0) {
                    throw new IllegalArgumentException("Please select at least one employee from your team.");
                }
                for (String e : empIds) {
                    if (e != null && !e.trim().isEmpty() && !targetEmployeeIds.contains(e.trim())) {
                        targetEmployeeIds.add(e.trim());
                    }
                }
            } else if ("team".equalsIgnoreCase(assignmentMode)) {
                if (targetTeamId == null || targetTeamId.trim().isEmpty()) {
                    throw new IllegalArgumentException("Please select a team to assign the task.");
                }
                if ("ALL".equalsIgnoreCase(targetTeamId.trim())) {
                    for (Team t : teams) {
                        List<TeamMember> members = taskService.getActiveMembersForTeam(t.getId());
                        for (TeamMember m : members) {
                            if (!targetEmployeeIds.contains(m.getEmployeeId())) {
                                targetEmployeeIds.add(m.getEmployeeId());
                            }
                        }
                    }
                } else {
                    int tid = Integer.parseInt(targetTeamId.trim());
                    List<TeamMember> members = taskService.getActiveMembersForTeam(tid);
                    for (TeamMember m : members) {
                        if (!targetEmployeeIds.contains(m.getEmployeeId())) {
                            targetEmployeeIds.add(m.getEmployeeId());
                        }
                    }
                }
                if (targetEmployeeIds.isEmpty()) {
                    throw new IllegalArgumentException("The selected team currently has no active members to assign.");
                }
            } else {
                // Default: single employee
                if (assignedTo == null || assignedTo.trim().isEmpty()) {
                    throw new IllegalArgumentException("Please select an employee to assign the task.");
                }
                targetEmployeeIds.add(assignedTo.trim());
            }

            // Security check: Validate every target employee is in the manager's team(s)
            for (String empId : targetEmployeeIds) {
                if (!taskService.isEmployeeInManagerTeams(managerId, empId)) {
                    throw new IllegalArgumentException("Access Denied: Employee (" + empId + ") does not belong to any team under your management.");
                }
            }

            // Handle uploaded work details / specification files
            String workFile = null;
            try {
                List<String> files = FileStorageUtil.saveUploadedFiles(req, "workDetailsFile", getServletContext(), "work", FileStorageUtil.DEFAULT_MAX_TOTAL_BYTES);
                if (!files.isEmpty()) {
                    workFile = FileStorageUtil.joinFileNames(files);
                }
            } catch (IllegalArgumentException e) {
                throw e;
            } catch (Exception e) {
                System.err.println("Warning: Could not process workDetailsFile upload: " + e.getMessage());
            }

            List<Integer> createdIds = new ArrayList<>();
            for (String empId : targetEmployeeIds) {
                String empDept = department;
                if (empDept == null || empDept.trim().isEmpty()) {
                    empDept = taskService.lookupEmployeeDepartment(empId);
                }
                int newId = taskService.createTask(title, description, empId, managerId, empDept, priority, startDate, dueDate, workFile);
                createdIds.add(newId);
            }

            if (createdIds.size() == 1) {
                req.setAttribute("successMessage", "Task created successfully (" + String.format("TASK%03d", createdIds.get(0)) + ") and assigned to " + targetEmployeeIds.get(0) + ".");
                req.setAttribute("createdTaskId", String.format("TASK%03d", createdIds.get(0)));
            } else {
                req.setAttribute("successMessage", "Task successfully created and assigned to " + createdIds.size() + " team members (" + String.join(", ", targetEmployeeIds) + ").");
            }

            populateTeamData(req, user);
            req.getRequestDispatcher("/createTask.jsp").forward(req, resp);
        } catch (IllegalArgumentException | IllegalStateException e) {
            req.setAttribute("errorMessage", e.getMessage());
            populateTeamData(req, user);
            req.setAttribute("taskTitle", title);
            req.setAttribute("description", description);
            req.setAttribute("assignmentMode", assignmentMode);
            req.setAttribute("assignedTo", assignedTo);
            req.setAttribute("department", department);
            req.setAttribute("priority", priority);
            req.setAttribute("startDate", startDate);
            req.setAttribute("dueDate", dueDate);
            req.setAttribute("targetTeamId", targetTeamId);
            req.getRequestDispatcher("/createTask.jsp").forward(req, resp);
        }
    }
}
