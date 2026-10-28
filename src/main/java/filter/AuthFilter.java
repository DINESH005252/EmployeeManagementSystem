package filter;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.User;

import java.io.IOException;
import java.util.*;

@WebFilter(urlPatterns = { "/attendance", "/session", "/status", "/leave", "/admin-user",
        "/team", "/team-member", "/team-dashboard", "/hr.html", "/manager.html", "/employee.html",
        "/createTask", "/editTask", "/deleteTask", "/viewTask", "/myTasks", "/updateTaskStatus",
        "/searchTasks", "/taskDashboard", "/reviewTask", "/employeePerformance", "/downloadTaskFile",
        "/reportsDashboard", "/reports", "/employeeReport", "/attendanceReport", "/leaveReport",
        "/taskReport",
        "/payroll/*", "/payroll",
        "/payroll/payroll-dashboard.jsp", "/payroll/salary-structures.jsp", "/payroll/salary-structure-form.jsp",
        "/payroll/payroll-processing.jsp", "/payroll/payroll-history.jsp", "/payroll/salary-slip.jsp",
        "/payroll/payroll-payment.jsp",
        "/createTask.jsp", "/editTask.jsp", "/deleteConfirm.jsp", "/manageTasks.jsp", "/myTasks.jsp",
        "/updateTaskStatus.jsp", "/taskDashboard.jsp", "/viewTask.jsp", "/employeePerformance.jsp",
        "/reports/reports-dashboard.jsp", "/reports/employee-report.jsp", "/reports/attendance-report.jsp",
        "/reports/leave-report.jsp", "/reports/task-report.jsp" })
public class AuthFilter implements Filter {

    private static final Set<String> EMPLOYEE_ACTIONS =
            Set.of("checkin", "checkout", "breakstart", "breakend", "history", "monthly");

    private static final Set<String> HR_ACTIONS =
            Set.of("dashboard", "absent", "leave", "daily", "history", "monthly");

    @Override
    public void doFilter(ServletRequest sreq, ServletResponse sres, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) sreq;
        HttpServletResponse resp = (HttpServletResponse) sres;
        req.setCharacterEncoding("UTF-8");

        resp.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        resp.setHeader("Pragma", "no-cache");
        resp.setDateHeader("Expires", 0);

        HttpSession session = req.getSession(false);
        User user = session == null ? null : (User) session.getAttribute("user");
        String path = req.getServletPath();
        String ctx = req.getContextPath();

        boolean hrPage = path.equals("/hr.html");
        boolean managerPage = path.equals("/manager.html");
        boolean employeePage = path.equals("/employee.html");

        // ----- HTML pages -----
        if (hrPage || managerPage || employeePage) {
            if (user == null) {
                resp.sendRedirect(ctx + "/login.html");
                return;
            }
            if (hrPage && !user.isHr()) {
                resp.sendRedirect(ctx + (user.isManager() ? "/manager.html" : "/employee.html"));
                return;
            }
            if (managerPage && !user.isManager()) {
                resp.sendRedirect(ctx + (user.isHr() ? "/hr.html" : "/employee.html"));
                return;
            }
            if (employeePage && (user.isHr() || user.isManager())) {
                resp.sendRedirect(ctx + (user.isHr() ? "/hr.html" : "/manager.html"));
                return;
            }
            chain.doFilter(req, resp);
            return;
        }

        // ----- data endpoints & JSPs -----
        if (user == null) {
            if (path.endsWith(".jsp")) {
                resp.sendRedirect(ctx + "/login.html");
                return;
            }
            deny(resp, HttpServletResponse.SC_UNAUTHORIZED, "Your session has expired. Please log in again.");
            return;
        }

        // Direct JSP access interception
        if (path.endsWith(".jsp") && !path.equals("/accessDenied.jsp")) {
            if (path.equals("/createTask.jsp") || path.equals("/editTask.jsp") || path.equals("/deleteConfirm.jsp")) {
                if (!user.isManager()) {
                    resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    req.setAttribute("errorMessage", "Access Denied: Task creation, editing, and deletion are managed exclusively by Managers.");
                    req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
                    return;
                }
                resp.sendRedirect(ctx + (path.equals("/createTask.jsp") ? "/createTask" : "/viewTask"));
                return;
            }
            if (path.equals("/manageTasks.jsp")) {
                if (user.getRole() == User.Role.EMPLOYEE) {
                    resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    req.setAttribute("errorMessage", "Access Denied: Employees do not have access to manage tasks.");
                    req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
                    return;
                } else if (user.isHr()) {
                    resp.sendRedirect(ctx + "/employeePerformance");
                    return;
                }
                resp.sendRedirect(ctx + "/viewTask");
                return;
            }
            if (path.equals("/employeePerformance.jsp")) {
                if (user.getRole() == User.Role.EMPLOYEE) {
                    resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    req.setAttribute("errorMessage", "Access Denied: Employee performance ratings and reviews are reserved for Managers and Administrators.");
                    req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
                    return;
                }
                resp.sendRedirect(ctx + "/employeePerformance");
                return;
            }
            if (path.equals("/taskDashboard.jsp")) {
                if (user.isHr()) {
                    resp.sendRedirect(ctx + "/employeePerformance");
                    return;
                }
                resp.sendRedirect(ctx + "/taskDashboard");
                return;
            }
            if (path.equals("/myTasks.jsp")) {
                resp.sendRedirect(ctx + "/myTasks");
                return;
            }
            if (path.equals("/updateTaskStatus.jsp")) {
                if (user.isHr()) {
                    resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    req.setAttribute("errorMessage", "Access Denied: Administrators do not have task update permissions.");
                    req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
                    return;
                }
                resp.sendRedirect(ctx + "/viewTask");
                return;
            }
            if (path.equals("/viewTask.jsp")) {
                resp.sendRedirect(ctx + (user.isHr() ? "/employeePerformance" : "/viewTask"));
                return;
            }
            if (path.startsWith("/payroll/")) {
                if (path.equals("/payroll/payroll-dashboard.jsp")) { resp.sendRedirect(ctx + "/payroll"); return; }
                if (path.equals("/payroll/salary-structures.jsp")) { resp.sendRedirect(ctx + "/payroll/salary-structures"); return; }
                if (path.equals("/payroll/salary-structure-form.jsp")) { resp.sendRedirect(ctx + "/payroll/salary-structure-form"); return; }
                if (path.equals("/payroll/payroll-processing.jsp")) { resp.sendRedirect(ctx + "/payroll/processing"); return; }
                if (path.equals("/payroll/payroll-history.jsp")) { resp.sendRedirect(ctx + "/payroll/history"); return; }
                if (path.equals("/payroll/salary-slip.jsp")) { resp.sendRedirect(ctx + "/payroll/history"); return; }
                if (path.equals("/payroll/payroll-payment.jsp")) { resp.sendRedirect(ctx + "/payroll/history"); return; }
            }
            if (path.startsWith("/reports/")) {
                if (path.equals("/reports/employee-report.jsp")) { resp.sendRedirect(ctx + "/employeeReport"); return; }
                if (path.equals("/reports/attendance-report.jsp")) { resp.sendRedirect(ctx + "/attendanceReport"); return; }
                if (path.equals("/reports/leave-report.jsp")) { resp.sendRedirect(ctx + "/leaveReport"); return; }
                if (path.equals("/reports/task-report.jsp")) { resp.sendRedirect(ctx + "/taskReport"); return; }
                if (path.equals("/reports/reports-dashboard.jsp")) { resp.sendRedirect(ctx + "/reportsDashboard"); return; }
            }
        }

        if (path.equals("/session")) { chain.doFilter(req, resp); return; }

        if (path.equals("/admin-user")) {
            if (!user.isHr()) { deny(resp, HttpServletResponse.SC_FORBIDDEN, "HR only."); return; }
            chain.doFilter(req, resp);
            return;
        }

        if (path.equals("/createTask") || path.equals("/editTask") || path.equals("/deleteTask") || path.equals("/reviewTask")) {
            if (!user.isManager()) {
                resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                req.setAttribute("errorMessage", "Access Denied: Task creation, editing, deletion, and reviews are managed exclusively by Managers. Administrators can view Employee Performance & Ratings.");
                req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
                return;
            }
            chain.doFilter(req, resp);
            return;
        }

        if (path.equals("/employeePerformance")) {
            if (user.getRole() == User.Role.EMPLOYEE) {
                resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                req.setAttribute("errorMessage", "Access Denied: Employee performance ratings and reviews are reserved for Managers and Administrators.");
                req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
                return;
            }
            chain.doFilter(req, resp);
            return;
        }

        if (path.equals("/updateTaskStatus")) {
            if (user.isHr()) {
                resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                req.setAttribute("errorMessage", "Access Denied: Administrators do not have task update permissions.");
                req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
                return;
            }
            chain.doFilter(req, resp);
            return;
        }

        if (path.equals("/viewTask") || path.equals("/myTasks")
                || path.equals("/searchTasks") || path.equals("/taskDashboard") || path.equals("/downloadTaskFile")) {
            chain.doFilter(req, resp);
            return;
        }

        if (path.equals("/employeeReport") || path.equals("/taskReport")) {
            if (user.getRole() == User.Role.EMPLOYEE) {
                resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                req.setAttribute("errorMessage", "Access Denied: Task and Employee reports are reserved for Managers and Administrators.");
                req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
                return;
            }
            chain.doFilter(req, resp);
            return;
        }

        if (path.equals("/reportsDashboard") || path.equals("/reports")
                || path.equals("/attendanceReport") || path.equals("/leaveReport")) {
            chain.doFilter(req, resp);
            return;
        }

        if (path.equals("/payroll") || path.startsWith("/payroll/")) {
            if (path.equals("/payroll/salary-structures") || path.equals("/payroll/salary-structure-form")
                    || path.equals("/payroll/processing") || path.equals("/payroll/payment")) {
                if (!user.isHr()) {
                    resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    req.setAttribute("errorMessage", "Access Denied: Only HR administrators can access this payroll module.");
                    req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
                    return;
                }
            }
            chain.doFilter(req, resp);
            return;
        }

        if (path.equals("/team") || path.equals("/team-member") || path.equals("/team-dashboard")) {
            // every logged-in role may reach these; exact permissions are checked inside the servlets
            chain.doFilter(req, resp);
            return;
        }

        if (path.equals("/leave")) {
            // LeaveServlet checks: EMPLOYEE submits, HR decides; MANAGER is rejected inside the servlet
            chain.doFilter(req, resp);
            return;
        }

        if (path.equals("/status")) {
            if (user.isHr()) {
                deny(resp, HttpServletResponse.SC_FORBIDDEN, "Not available for this role.");
                return;
            }
            chain.doFilter(req, resp);
            return;
        }

        // /attendance
        if (user.isHr()) {
            String a = (req.getParameter("action") == null || req.getParameter("action").isEmpty())
                    ? "dashboard" : req.getParameter("action");
            if (!HR_ACTIONS.contains(a)) {
                deny(resp, HttpServletResponse.SC_FORBIDDEN,
                        "HR cannot record check-in, break or check-out. Employees do this themselves.");
                return;
            }
            chain.doFilter(req, resp);
            return;
        }

        String action = req.getParameter("action");
        if (action == null || !EMPLOYEE_ACTIONS.contains(action)) {
            deny(resp, HttpServletResponse.SC_FORBIDDEN, "You are not allowed to do this.");
            return;
        }
        chain.doFilter(new EmployeeRequest(req, user.getEmployeeId()), resp);
    }

    private void deny(HttpServletResponse resp, int status, String message) throws IOException {
        resp.setStatus(status);
        resp.setContentType("text/html;charset=UTF-8");
        resp.getWriter().write("<div class='wrap'><div class='msg err'>" + message + "</div></div>");
    }

    private static class EmployeeRequest extends HttpServletRequestWrapper {
        private final String employeeId;

        EmployeeRequest(HttpServletRequest req, String employeeId) {
            super(req);
            this.employeeId = employeeId == null ? "" : employeeId;
        }

        @Override
        public String getParameter(String name) {
            return "employeeId".equals(name) ? employeeId : super.getParameter(name);
        }

        @Override
        public String[] getParameterValues(String name) {
            return "employeeId".equals(name) ? new String[] { employeeId } : super.getParameterValues(name);
        }

        @Override
        public Map<String, String[]> getParameterMap() {
            Map<String, String[]> map = new HashMap<>(super.getParameterMap());
            map.put("employeeId", new String[] { employeeId });
            return Collections.unmodifiableMap(map);
        }
    }
}