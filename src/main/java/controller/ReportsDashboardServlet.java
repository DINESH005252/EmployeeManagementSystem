package controller;

import dao.ReportDAO;
import model.Report;
import model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.List;

/**
 * Servlet for the central Reports & Analytics Dashboard.
 */
@WebServlet(urlPatterns = { "/reportsDashboard", "/reports" })
public class ReportsDashboardServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private ReportDAO reportDAO;

    @Override
    public void init() {
        this.reportDAO = new ReportDAO();
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        User user = (session == null) ? null : (User) session.getAttribute("user");

        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login.html");
            return;
        }

        boolean isEmployee = user.isEmployee();
        boolean isManager = user.isManager();
        boolean isHr = user.isHr();
        String managerId = isManager ? user.getManagerId() : null;

        String paramManager = req.getParameter("managerId");
        boolean showTeamView = false;

        if (isEmployee) {
            showTeamView = false;
            managerId = null;
        } else if (isHr) {
            if (paramManager != null && !paramManager.trim().isEmpty()) {
                showTeamView = true;
                if (!"ALL".equalsIgnoreCase(paramManager)) {
                    managerId = paramManager.trim();
                } else {
                    managerId = null;
                }
            } else {
                showTeamView = false;
            }
        } else {
            showTeamView = true;
        }

        String search = req.getParameter("search");
        String department = req.getParameter("department");
        String status = req.getParameter("status");

        try {
            Report.DashboardSummary summary = reportDAO.getDashboardSummary(managerId);
            List<Report.EmployeeItem> employees = reportDAO.getEmployeeReport(managerId, search, department, status);
            List<String> departments = reportDAO.getDistinctDepartments();
            List<Report.ManagerItem> managers = isHr ? reportDAO.getActiveManagers() : java.util.Collections.emptyList();

            req.setAttribute("summary", summary);
            req.setAttribute("employees", employees);
            req.setAttribute("departments", departments);
            req.setAttribute("managers", managers);
            req.setAttribute("showTeamView", showTeamView);
            req.setAttribute("isEmployee", isEmployee);
            req.setAttribute("paramManager", paramManager != null ? paramManager : "");
            req.setAttribute("paramSearch", search != null ? search : "");
            req.setAttribute("paramDept", department != null ? department : "ALL");
            req.setAttribute("paramStatus", status != null ? status : "ALL");

            req.getRequestDispatcher("/reports/reports-dashboard.jsp").forward(req, resp);
        } catch (Exception e) {
            log("Error loading Reports Dashboard", e);
            req.setAttribute("errorMessage", "Unable to load Reports Dashboard: " + e.getMessage());
            req.getRequestDispatcher("/reports/reports-dashboard.jsp").forward(req, resp);
        }
    }
}
