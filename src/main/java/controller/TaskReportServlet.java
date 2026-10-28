package controller;

import dao.ReportDAO;
import model.Employee;
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
import java.time.format.DateTimeParseException;
import java.util.List;

/**
 * Servlet for generating and filtering Task Progress Reports.
 */
@WebServlet(urlPatterns = { "/taskReport", "/reports/task" })
public class TaskReportServlet extends HttpServlet {
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
            req.setAttribute("errorMessage", "Access Denied: Task reports are reserved for Managers and Administrators.");
            req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
            return;
        }

        boolean isEmp = user.isEmployee();
        String managerId = user.isManager() ? user.getManagerId() : null;

        String employeeId = isEmp ? user.getEmployeeId() : req.getParameter("employeeId");
        if (!isEmp && (employeeId == null || employeeId.trim().isEmpty() || "ALL".equalsIgnoreCase(employeeId.trim()))) {
            String searchParam = req.getParameter("search");
            if (searchParam != null && !searchParam.trim().isEmpty()) {
                employeeId = searchParam.trim();
            }
        }
        String status = req.getParameter("status");
        String priority = req.getParameter("priority");
        String department = isEmp ? "ALL" : req.getParameter("department");
        String fromDateStr = req.getParameter("fromDate");
        String toDateStr = req.getParameter("toDate");
        String role = req.getParameter("role");
        if (role == null || role.trim().isEmpty()) role = "ALL";

        if (employeeId == null || employeeId.trim().isEmpty()) employeeId = isEmp ? user.getEmployeeId() : "ALL";
        if (status == null) status = "ALL";
        if (priority == null) priority = "ALL";
        if (department == null) department = "ALL";

        LocalDate fromDate = null;
        LocalDate toDate = null;

        if (fromDateStr != null && !fromDateStr.trim().isEmpty()) {
            try {
                fromDate = LocalDate.parse(fromDateStr.trim());
            } catch (DateTimeParseException ignored) {}
        }
        if (toDateStr != null && !toDateStr.trim().isEmpty()) {
            try {
                toDate = LocalDate.parse(toDateStr.trim());
            } catch (DateTimeParseException ignored) {}
        }

        if (fromDate != null && toDate != null && fromDate.isAfter(toDate)) {
            LocalDate temp = fromDate;
            fromDate = toDate;
            toDate = temp;
            req.setAttribute("warningMessage", "Note: 'From Date' was after 'To Date'. The date range was automatically adjusted.");
        }

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
            List<Report.TaskItem> allItems = reportDAO.getTaskReport(managerId, employeeId, status, priority, department, fromDate, toDate, role);

            String exportFormat = req.getParameter("export");
            if ("csv".equalsIgnoreCase(exportFormat)) {
                exportTaskCsv(resp, allItems);
                return;
            } else if ("excel".equalsIgnoreCase(exportFormat)) {
                exportTaskExcel(resp, allItems);
                return;
            }
            Report.TaskSummary summary = reportDAO.getTaskReportSummary(allItems);
            List<Employee> accessibleEmployees = isEmp ? java.util.Collections.emptyList() : reportDAO.getAccessibleEmployees(managerId);
            List<String> departments = isEmp ? java.util.Collections.emptyList() : reportDAO.getDistinctDepartments();

            int totalRecords = allItems.size();
            int totalPages = totalRecords > 0 ? (int) Math.ceil((double) totalRecords / pageSize) : 1;
            if (page > totalPages) page = totalPages;

            int fromIndex = Math.min((page - 1) * pageSize, totalRecords);
            int toIndex = Math.min(fromIndex + pageSize, totalRecords);
            List<Report.TaskItem> pagedItems = allItems.subList(fromIndex, toIndex);

            req.setAttribute("reportItems", pagedItems);
            req.setAttribute("summary", summary);
            req.setAttribute("accessibleEmployees", accessibleEmployees);
            req.setAttribute("departments", departments);
            req.setAttribute("isEmployee", isEmp);
            req.setAttribute("totalRecords", totalRecords);
            req.setAttribute("currentPage", page);
            req.setAttribute("totalPages", totalPages);
            req.setAttribute("pageSize", pageSize);
            req.setAttribute("fromIndex", totalRecords > 0 ? fromIndex + 1 : 0);
            req.setAttribute("toIndex", toIndex);
            req.setAttribute("paramRole", role);

            req.setAttribute("paramEmployeeId", employeeId);
            req.setAttribute("paramStatus", status);
            req.setAttribute("paramPriority", priority);
            req.setAttribute("paramDepartment", department);
            req.setAttribute("paramFromDate", fromDate != null ? fromDate.toString() : "");
            req.setAttribute("paramToDate", toDate != null ? toDate.toString() : "");

            req.getRequestDispatcher("/reports/task-report.jsp").forward(req, resp);
        } catch (Exception e) {
            log("Error generating Task Report", e);
            req.setAttribute("errorMessage", "Unable to load Task Report: " + e.getMessage());
            req.getRequestDispatcher("/reports/task-report.jsp").forward(req, resp);
        }
    }

    private void exportTaskCsv(HttpServletResponse resp, List<Report.TaskItem> items) throws IOException {
        resp.setContentType("text/csv; charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Content-Disposition", "attachment; filename=\"task_report_" + LocalDate.now() + ".csv\"");
        java.io.PrintWriter out = resp.getWriter();
        out.write('\uFEFF');
        out.println("Task ID,Title,Department,Assigned To ID,Assigned To Name,Created By,Priority,Start Date,Due Date,Status,Rating,Feedback");
        for (Report.TaskItem it : items) {
            out.println(String.join(",",
                csv(it.getFormattedId()),
                csv(it.getTaskTitle()),
                csv(it.getDepartment()),
                csv(it.getAssignedTo()),
                csv(it.getAssignedToName()),
                csv(it.getCreatedBy()),
                csv(it.getPriority()),
                csv(it.getStartDate() != null ? it.getStartDate().toString() : "--"),
                csv(it.getDueDate() != null ? it.getDueDate().toString() : "--"),
                csv(it.getStatus()),
                csv(it.getRating() != null ? it.getRating() + "/5" : "--"),
                csv(it.getFeedback() != null ? it.getFeedback() : "--")
            ));
        }
        out.flush();
    }

    private void exportTaskExcel(HttpServletResponse resp, List<Report.TaskItem> items) throws IOException {
        resp.setContentType("application/vnd.ms-excel; charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Content-Disposition", "attachment; filename=\"task_report_" + LocalDate.now() + ".xls\"");
        java.io.PrintWriter out = resp.getWriter();
        out.println("<!DOCTYPE html><html><head><meta charset='UTF-8'>");
        out.println("<style>");
        out.println("th { background-color: #0f172a; color: #ffffff; font-weight: bold; border: 1px solid #cbd5e1; padding: 8px 12px; font-family: Calibri, sans-serif; font-size: 11pt; }");
        out.println("td { border: 1px solid #cbd5e1; padding: 6px 10px; font-family: Calibri, sans-serif; font-size: 10pt; }");
        out.println("</style></head><body>");
        out.println("<h2>Task Progress &amp; Completion Report</h2>");
        out.println("<p>Generated on: " + LocalDate.now() + " | Total Records: " + items.size() + "</p>");
        out.println("<table border='1' cellspacing='0' cellpadding='5'>");
        out.println("<thead><tr>");
        out.println("<th>Task ID</th><th>Title</th><th>Department</th><th>Assigned To</th><th>Assigned Name</th><th>Created By</th><th>Priority</th><th>Start Date</th><th>Due Date</th><th>Status</th><th>Rating</th><th>Feedback</th>");
        out.println("</tr></thead><tbody>");
        for (Report.TaskItem it : items) {
            out.println("<tr>");
            out.println("<td>" + esc(it.getFormattedId()) + "</td>");
            out.println("<td>" + esc(it.getTaskTitle()) + "</td>");
            out.println("<td>" + esc(it.getDepartment()) + "</td>");
            out.println("<td>" + esc(it.getAssignedTo()) + "</td>");
            out.println("<td>" + esc(it.getAssignedToName()) + "</td>");
            out.println("<td>" + esc(it.getCreatedBy()) + "</td>");
            out.println("<td>" + esc(it.getPriority()) + "</td>");
            out.println("<td>" + esc(it.getStartDate() != null ? it.getStartDate().toString() : "--") + "</td>");
            out.println("<td>" + esc(it.getDueDate() != null ? it.getDueDate().toString() : "--") + "</td>");
            out.println("<td>" + esc(it.getStatus()) + "</td>");
            out.println("<td>" + esc(it.getRating() != null ? it.getRating() + "/5" : "--") + "</td>");
            out.println("<td>" + esc(it.getFeedback() != null ? it.getFeedback() : "--") + "</td>");
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
