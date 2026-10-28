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
import java.time.LocalDate;
import java.util.List;

/**
 * Servlet for generating and filtering Employee Reports.
 */
@WebServlet(urlPatterns = { "/employeeReport", "/reports/employee" })
public class EmployeeReportServlet extends HttpServlet {
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

        if (user.getRole() == User.Role.EMPLOYEE) {
            resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            req.setAttribute("errorMessage", "Access Denied: Employee directory reports are reserved for Managers and Administrators.");
            req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
            return;
        }

        boolean isEmp = user.isEmployee();
        String managerId = user.isManager() ? user.getManagerId() : null;

        String search = isEmp ? user.getEmployeeId() : req.getParameter("search");
        if (!isEmp && (search == null || search.trim().isEmpty())) {
            search = req.getParameter("employeeId");
        }
        String department = isEmp ? "ALL" : req.getParameter("department");
        String status = isEmp ? "ALL" : req.getParameter("status");
        String role = req.getParameter("role");
        if (role == null || role.trim().isEmpty()) role = "ALL";

        if (department == null) department = "ALL";
        if (status == null) status = "ALL";
        if (search != null) search = search.trim();

        // Pagination parameters
        int page = 1;
        int pageSize = 10;
        String pageParam = req.getParameter("page");
        if (pageParam != null && !pageParam.trim().isEmpty()) {
            try {
                page = Math.max(1, Integer.parseInt(pageParam.trim()));
            } catch (NumberFormatException ignored) {}
        }

        try {
            List<Report.EmployeeItem> allItems = reportDAO.getEmployeeReport(managerId, search, department, status, role);

            String exportFormat = req.getParameter("export");
            if ("csv".equalsIgnoreCase(exportFormat)) {
                exportEmployeeCsv(resp, allItems);
                return;
            } else if ("excel".equalsIgnoreCase(exportFormat)) {
                exportEmployeeExcel(resp, allItems);
                return;
            }
            Report.EmployeeSummary summary = reportDAO.getEmployeeReportSummary(allItems);
            List<String> departments = reportDAO.getDistinctDepartments();

            int totalRecords = allItems.size();
            int totalPages = totalRecords > 0 ? (int) Math.ceil((double) totalRecords / pageSize) : 1;
            if (page > totalPages) page = totalPages;

            int fromIndex = Math.min((page - 1) * pageSize, totalRecords);
            int toIndex = Math.min(fromIndex + pageSize, totalRecords);
            List<Report.EmployeeItem> pagedItems = allItems.subList(fromIndex, toIndex);

            req.setAttribute("reportItems", pagedItems);
            req.setAttribute("summary", summary);
            req.setAttribute("departments", departments);
            req.setAttribute("isEmployee", isEmp);
            req.setAttribute("totalRecords", totalRecords);
            req.setAttribute("currentPage", page);
            req.setAttribute("totalPages", totalPages);
            req.setAttribute("pageSize", pageSize);
            req.setAttribute("fromIndex", totalRecords > 0 ? fromIndex + 1 : 0);
            req.setAttribute("toIndex", toIndex);

            req.setAttribute("paramSearch", search != null ? search : "");
            req.setAttribute("paramDept", department);
            req.setAttribute("paramStatus", status);
            req.setAttribute("paramRole", role);

            req.getRequestDispatcher("/reports/employee-report.jsp").forward(req, resp);
        } catch (Exception e) {
            log("Error generating Employee Report", e);
            req.setAttribute("errorMessage", "Unable to load Employee Report: " + e.getMessage());
            req.getRequestDispatcher("/reports/employee-report.jsp").forward(req, resp);
        }
    }

    private void exportEmployeeCsv(HttpServletResponse resp, List<Report.EmployeeItem> items) throws IOException {
        resp.setContentType("text/csv; charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Content-Disposition", "attachment; filename=\"employee_directory_report_" + LocalDate.now() + ".csv\"");
        java.io.PrintWriter out = resp.getWriter();
        out.write('\uFEFF');
        out.println("Employee ID,Name,Email,Department,Role,Status,Manager ID,Team");
        for (Report.EmployeeItem it : items) {
            out.println(String.join(",",
                csv(it.getEmployeeId()),
                csv(it.getName()),
                csv(it.getEmail()),
                csv(it.getDepartment()),
                csv(it.getRole()),
                csv(it.getStatus()),
                csv(it.getManagerId() != null ? it.getManagerId() : "--"),
                csv(it.getTeamName() != null ? it.getTeamName() : "--")
            ));
        }
        out.flush();
    }

    private void exportEmployeeExcel(HttpServletResponse resp, List<Report.EmployeeItem> items) throws IOException {
        resp.setContentType("application/vnd.ms-excel; charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Content-Disposition", "attachment; filename=\"employee_directory_report_" + LocalDate.now() + ".xls\"");
        java.io.PrintWriter out = resp.getWriter();
        out.println("<!DOCTYPE html><html><head><meta charset='UTF-8'>");
        out.println("<style>");
        out.println("th { background-color: #0f172a; color: #ffffff; font-weight: bold; border: 1px solid #cbd5e1; padding: 8px 12px; font-family: Calibri, sans-serif; font-size: 11pt; }");
        out.println("td { border: 1px solid #cbd5e1; padding: 6px 10px; font-family: Calibri, sans-serif; font-size: 10pt; }");
        out.println("</style></head><body>");
        out.println("<h2>Employee Directory Report</h2>");
        out.println("<p>Generated on: " + LocalDate.now() + " | Total Records: " + items.size() + "</p>");
        out.println("<table border='1' cellspacing='0' cellpadding='5'>");
        out.println("<thead><tr>");
        out.println("<th>Employee ID</th><th>Name</th><th>Email</th><th>Department</th><th>Role</th><th>Status</th><th>Manager ID</th><th>Team</th>");
        out.println("</tr></thead><tbody>");
        for (Report.EmployeeItem it : items) {
            out.println("<tr>");
            out.println("<td>" + esc(it.getEmployeeId()) + "</td>");
            out.println("<td>" + esc(it.getName()) + "</td>");
            out.println("<td>" + esc(it.getEmail()) + "</td>");
            out.println("<td>" + esc(it.getDepartment()) + "</td>");
            out.println("<td>" + esc(it.getRole()) + "</td>");
            out.println("<td>" + esc(it.getStatus()) + "</td>");
            out.println("<td>" + esc(it.getManagerId() != null ? it.getManagerId() : "--") + "</td>");
            out.println("<td>" + esc(it.getTeamName() != null ? it.getTeamName() : "--") + "</td>");
            out.println("</tr>");
        }
        out.println("</tbody></table></body></html>");
        out.flush();
    }

    private static String csv(Object val) {
        if (val == null) return "\"\"";
        String s = String.valueOf(val);
        return "\"" + s.replace("\"", "\"\"").replace("\r", " ").replace("\n", " ") + "\"";
    }

    private static String esc(Object val) {
        if (val == null) return "";
        return String.valueOf(val).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
}
