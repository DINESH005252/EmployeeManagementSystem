package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.Employee;
import model.EmployeePerformance;
import model.Manager;
import model.ManagerReviewSummary;
import model.Task;
import model.TaskGroup;
import model.User;
import service.TaskService;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@WebServlet("/employeePerformance")
public class EmployeePerformanceServlet extends HttpServlet {
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

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = currentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login.html");
            return;
        }

        // Ratings & Performance reports are exclusively visible to Managers and Administrators (HR)
        if (user.getRole() == User.Role.EMPLOYEE) {
            resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            req.setAttribute("errorMessage", "Access Denied: Performance ratings and evaluations are reserved for Managers and Administrators.");
            req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
            return;
        }

        boolean isHr = user.isHr();
        boolean isManager = user.isManager();

        String view = req.getParameter("view");
        if (view == null || view.trim().isEmpty()) {
            view = "task"; // Default is Tasks view
        }
        view = view.trim().toLowerCase();

        // Managers cannot access the cross-manager audit view
        if (isManager && "manager".equals(view)) {
            view = "task";
        }

        String msg = req.getParameter("msg");
        String err = req.getParameter("err");
        if (msg != null && !msg.trim().isEmpty()) req.setAttribute("successMessage", msg.trim());
        if (err != null && !err.trim().isEmpty()) req.setAttribute("errorMessage", err.trim());

        String dept = req.getParameter("department");
        String managerId = req.getParameter("managerId");
        String reviewStatus = req.getParameter("status");
        String rating = req.getParameter("rating");
        String keyword = req.getParameter("keyword");

        if (dept == null || dept.trim().isEmpty()) dept = "ALL";
        if (reviewStatus == null || reviewStatus.trim().isEmpty()) reviewStatus = "ALL";
        if (rating == null || rating.trim().isEmpty()) rating = "ALL";
        if (keyword == null) keyword = "";

        // If manager is logged in, restrict to their own manager ID
        if (isManager) {
            managerId = (user.getManagerId() != null && !user.getManagerId().trim().isEmpty())
                    ? user.getManagerId().trim()
                    : "ALL";
        } else if (managerId == null || managerId.trim().isEmpty()) {
            managerId = "ALL";
        }

        // Query data with reviewStatus and rating filters
        List<Task> taskReviews = taskService.getDetailedTaskReviews(managerId, dept, reviewStatus, rating, keyword);
        List<TaskGroup> taskGroups = taskService.getGroupedTaskReviews(managerId, dept, reviewStatus, rating, keyword);
        List<ManagerReviewSummary> managerSummaries = isHr
                ? taskService.getManagerReviewSummaries(managerId, dept, rating, keyword)
                : Collections.emptyList();

        List<EmployeePerformance> performanceList;
        if (isManager && user.getManagerId() != null && !user.getManagerId().trim().isEmpty()) {
            // Scope employee performance to the manager's team members and assignees
            List<Employee> managerTeam = taskService.getEmployeesForManager(user.getManagerId().trim());
            Set<String> teamEmpIds = new HashSet<>();
            for (Employee e : managerTeam) {
                teamEmpIds.add(e.getEmployeeId());
            }
            for (Task t : taskReviews) {
                if (t.getAssignedTo() != null) {
                    teamEmpIds.add(t.getAssignedTo());
                }
            }
            List<EmployeePerformance> allEp = taskService.getEmployeePerformanceList(dept, keyword);
            performanceList = new ArrayList<>();
            for (EmployeePerformance ep : allEp) {
                if (teamEmpIds.contains(ep.getEmployeeId())) {
                    performanceList.add(ep);
                }
            }
        } else {
            performanceList = taskService.getEmployeePerformanceList(dept, keyword);
        }

        // Problems A2, A3, A4: Calculate metrics from database using PreparedStatement
        Map<String, Object> orgStats = taskService.getPerformanceStats(isManager ? managerId : ("ALL".equalsIgnoreCase(managerId) ? null : managerId));

        List<Manager> activeManagers = isHr ? taskService.getActiveManagers() : Collections.emptyList();
        List<String> distinctDepartments = taskService.getDistinctDepartments();

        req.setAttribute("viewMode", view);
        req.setAttribute("taskReviews", taskReviews);
        req.setAttribute("taskGroups", taskGroups);
        req.setAttribute("managerSummaries", managerSummaries);
        req.setAttribute("performanceList", performanceList);
        req.setAttribute("orgStats", orgStats);
        req.setAttribute("activeManagers", activeManagers);
        req.setAttribute("distinctDepartments", distinctDepartments);

        req.setAttribute("selectedDept", dept);
        req.setAttribute("selectedManager", managerId);
        req.setAttribute("selectedStatus", reviewStatus);
        req.setAttribute("selectedRating", rating);
        req.setAttribute("keyword", keyword);

        req.getRequestDispatcher("/employeePerformance.jsp").forward(req, resp);
    }
}
