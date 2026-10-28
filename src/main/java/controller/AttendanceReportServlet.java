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
import java.time.YearMonth;
import java.time.format.DateTimeParseException;
import java.util.List;

/**
 * Servlet for generating and filtering Attendance Reports.
 * Supports Daily, Monthly, and Custom Date Range filters.
 */
@WebServlet(urlPatterns = { "/attendanceReport", "/reports/attendance" })
public class AttendanceReportServlet extends HttpServlet {
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

        boolean isEmp = user.isEmployee();
        String managerId = user.isManager() ? user.getManagerId() : null;

        String employeeId = isEmp ? user.getEmployeeId() : req.getParameter("employeeId");
        if (!isEmp && (employeeId == null || employeeId.trim().isEmpty() || "ALL".equalsIgnoreCase(employeeId.trim()))) {
            String searchParam = req.getParameter("search");
            if (searchParam != null && !searchParam.trim().isEmpty()) {
                employeeId = searchParam.trim();
            }
        }
        String periodType = req.getParameter("periodType"); // "custom", "daily", "monthly"
        String fromDateStr = req.getParameter("fromDate");
        String toDateStr = req.getParameter("toDate");
        String monthStr = req.getParameter("month"); // "YYYY-MM"
        String dailyDateStr = req.getParameter("dailyDate"); // "YYYY-MM-DD"
        String status = req.getParameter("status");
        String role = req.getParameter("role");
        if (role == null || role.trim().isEmpty()) role = "ALL";

        boolean isMyScope = false;
        if (user.isManager()) {
            String scope = req.getParameter("scope");
            if ("my".equalsIgnoreCase(scope)) {
                employeeId = user.getManagerId();
                isMyScope = true;
            } else if (employeeId != null && employeeId.equalsIgnoreCase(user.getManagerId())) {
                isMyScope = true;
            }
        }

        if (periodType == null || periodType.trim().isEmpty()) periodType = "custom";
        if (employeeId == null || employeeId.trim().isEmpty()) employeeId = isEmp ? user.getEmployeeId() : "ALL";
        if (status == null) status = "ALL";

        LocalDate fromDate = null;
        LocalDate toDate = null;

        if ("daily".equalsIgnoreCase(periodType)) {
            if (dailyDateStr != null && !dailyDateStr.trim().isEmpty()) {
                try {
                    fromDate = LocalDate.parse(dailyDateStr.trim());
                    toDate = fromDate;
                } catch (DateTimeParseException ignored) {
                    fromDate = LocalDate.now();
                    toDate = fromDate;
                }
            } else {
                fromDate = LocalDate.now();
                toDate = fromDate;
            }
        } else if ("monthly".equalsIgnoreCase(periodType)) {
            if (monthStr != null && !monthStr.trim().isEmpty()) {
                try {
                    YearMonth ym = YearMonth.parse(monthStr.trim());
                    fromDate = ym.atDay(1);
                    toDate = ym.atEndOfMonth();
                } catch (DateTimeParseException ignored) {
                    YearMonth ym = YearMonth.now();
                    fromDate = ym.atDay(1);
                    toDate = ym.atEndOfMonth();
                }
            } else {
                YearMonth ym = YearMonth.now();
                fromDate = ym.atDay(1);
                toDate = ym.atEndOfMonth();
            }
        } else {
            // custom date range
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

            // Server-side date range validation
            if (fromDate != null && toDate != null && fromDate.isAfter(toDate)) {
                LocalDate temp = fromDate;
                fromDate = toDate;
                toDate = temp;
                req.setAttribute("warningMessage", "Note: 'From Date' was after 'To Date'. The date range was automatically adjusted.");
            }
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
            List<Report.AttendanceItem> allItems = reportDAO.getAttendanceReport(managerId, employeeId, fromDate, toDate, status, role);

            String exportFormat = req.getParameter("export");
            if ("csv".equalsIgnoreCase(exportFormat)) {
                exportAttendanceCsv(resp, allItems);
                return;
            } else if ("excel".equalsIgnoreCase(exportFormat)) {
                exportAttendanceExcel(resp, allItems);
                return;
            }
            Report.AttendanceSummary summary = reportDAO.getAttendanceReportSummary(allItems);
            List<Employee> accessibleEmployees = isEmp ? java.util.Collections.emptyList() : reportDAO.getAccessibleEmployees(managerId);

            int totalRecords = allItems.size();
            int totalPages = totalRecords > 0 ? (int) Math.ceil((double) totalRecords / pageSize) : 1;
            if (page > totalPages) page = totalPages;

            int fromIndex = Math.min((page - 1) * pageSize, totalRecords);
            int toIndex = Math.min(fromIndex + pageSize, totalRecords);
            List<Report.AttendanceItem> pagedItems = allItems.subList(fromIndex, toIndex);

            req.setAttribute("reportItems", pagedItems);
            req.setAttribute("summary", summary);
            req.setAttribute("accessibleEmployees", accessibleEmployees);
            req.setAttribute("isEmployee", isEmp);
            req.setAttribute("totalRecords", totalRecords);
            req.setAttribute("currentPage", page);
            req.setAttribute("totalPages", totalPages);
            req.setAttribute("pageSize", pageSize);
            req.setAttribute("fromIndex", totalRecords > 0 ? fromIndex + 1 : 0);
            req.setAttribute("toIndex", toIndex);

            req.setAttribute("paramRole", role);
            req.setAttribute("isMyScope", isMyScope);
            req.setAttribute("paramPeriodType", periodType);
            req.setAttribute("paramEmployeeId", employeeId);
            req.setAttribute("paramFromDate", fromDate != null ? fromDate.toString() : "");
            req.setAttribute("paramToDate", toDate != null ? toDate.toString() : "");
            req.setAttribute("paramDailyDate", dailyDateStr != null ? dailyDateStr : (fromDate != null ? fromDate.toString() : ""));
            req.setAttribute("paramMonth", monthStr != null ? monthStr : YearMonth.now().toString());
            req.setAttribute("paramStatus", status);

            req.getRequestDispatcher("/reports/attendance-report.jsp").forward(req, resp);
        } catch (Exception e) {
            log("Error generating Attendance Report", e);
            req.setAttribute("errorMessage", "Unable to load Attendance Report: " + e.getMessage());
            req.getRequestDispatcher("/reports/attendance-report.jsp").forward(req, resp);
        }
    }

    private void exportAttendanceCsv(HttpServletResponse resp, List<Report.AttendanceItem> items) throws IOException {
        resp.setContentType("text/csv; charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Content-Disposition", "attachment; filename=\"attendance_report_" + LocalDate.now() + ".csv\"");
        java.io.PrintWriter out = resp.getWriter();
        out.write('\uFEFF');
        out.println("Attendance ID,Employee ID,Employee Name,Department,Date,Check-In,Check-Out,Status,Work Duration");
        for (Report.AttendanceItem it : items) {
            out.println(String.join(",",
                csv(it.getAttendanceId()),
                csv(it.getEmployeeId()),
                csv(it.getEmployeeName()),
                csv(it.getDepartment()),
                csv(it.getDateText()),
                csv(it.getCheckInText()),
                csv(it.getCheckOutText()),
                csv(it.getStatus()),
                csv(it.getWorkedText())
            ));
        }
        out.flush();
    }

    private void exportAttendanceExcel(HttpServletResponse resp, List<Report.AttendanceItem> items) throws IOException {
        resp.setContentType("application/vnd.ms-excel; charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Content-Disposition", "attachment; filename=\"attendance_report_" + LocalDate.now() + ".xls\"");
        java.io.PrintWriter out = resp.getWriter();
        out.println("<!DOCTYPE html><html><head><meta charset='UTF-8'>");
        out.println("<style>");
        out.println("th { background-color: #0f172a; color: #ffffff; font-weight: bold; border: 1px solid #cbd5e1; padding: 8px 12px; font-family: Calibri, sans-serif; font-size: 11pt; }");
        out.println("td { border: 1px solid #cbd5e1; padding: 6px 10px; font-family: Calibri, sans-serif; font-size: 10pt; }");
        out.println("</style></head><body>");
        out.println("<h2>Attendance Statement &amp; Report</h2>");
        out.println("<p>Generated on: " + LocalDate.now() + " | Total Records: " + items.size() + "</p>");
        out.println("<table border='1' cellspacing='0' cellpadding='5'>");
        out.println("<thead><tr>");
        out.println("<th>Attendance ID</th><th>Employee ID</th><th>Employee Name</th><th>Department</th><th>Date</th><th>Check-In</th><th>Check-Out</th><th>Status</th><th>Work Duration</th>");
        out.println("</tr></thead><tbody>");
        for (Report.AttendanceItem it : items) {
            out.println("<tr>");
            out.println("<td>" + esc(it.getAttendanceId()) + "</td>");
            out.println("<td>" + esc(it.getEmployeeId()) + "</td>");
            out.println("<td>" + esc(it.getEmployeeName()) + "</td>");
            out.println("<td>" + esc(it.getDepartment()) + "</td>");
            out.println("<td>" + esc(it.getDateText()) + "</td>");
            out.println("<td>" + esc(it.getCheckInText()) + "</td>");
            out.println("<td>" + esc(it.getCheckOutText()) + "</td>");
            out.println("<td>" + esc(it.getStatus()) + "</td>");
            out.println("<td>" + esc(it.getWorkedText()) + "</td>");
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
