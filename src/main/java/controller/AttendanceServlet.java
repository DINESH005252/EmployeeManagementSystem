package controller;

import model.Attendance;
import model.Employee;
import service.AttendanceService;
import service.EmployeeService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.time.*;
import java.time.format.DateTimeParseException;
import java.time.format.TextStyle;
import java.util.*;

/** Handles all attendance actions and renders the result pages as HTML. */
@WebServlet("/attendance")
public class AttendanceServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private EmployeeService employeeService;
    private AttendanceService attendanceService;

    @Override
    public void init() {
        employeeService = new EmployeeService();
        attendanceService = new AttendanceService(employeeService);
    }

    // ================= GET: dashboard and reports =================

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = param(req, "action", "dashboard");
        try {
            switch (action) {
                case "daily":   daily(req, resp);   break;
                case "history": history(req, resp); break;
                case "monthly": monthly(req, resp); break;
                default:        dashboard(resp);
            }
        } catch (IllegalArgumentException | IllegalStateException | DateTimeParseException ex) {
            error(resp, ex.getMessage());
        } catch (RuntimeException ex) {
            log("Database/unexpected error", ex);
            error(resp, "Database error. Check the Tomcat console for details.");
        }
    }

    // ================= POST: check-in, break, check-out, absent, leave =================

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String action = param(req, "action", "");
        String id = param(req, "employeeId", "").trim();
        try {
            switch (action) {
                case "checkin": {
                    Employee e = attendanceService.getEmployee(id);
                    Attendance a = attendanceService.checkIn(id);
                    render(resp, "Employee Check-In",
                            ok("Check-in time recorded successfully.")
                            + table(row("Employee", e.getId() + " - " + e.getName()),
                                    row("Department", e.getDepartment()),
                                    row("Date", a.getDateText()),
                                    row("Check-in", a.getCheckInText()),
                                    rowHtml("Status", badge(a.getStatus())),
                                    row("Note", "Final status is decided at check-out from your working hours."))
                            + back("checkin.html", "Check in another employee"));
                    break;
                }
                case "breakstart": {
                    Employee e = attendanceService.getEmployee(id);
                    Attendance a = attendanceService.startBreak(id);
                    render(resp, "Start Break",
                            ok("Break started.")
                            + table(row("Employee", e.getId() + " - " + e.getName()),
                                    row("Break started at", a.getBreakStartText()),
                                    row("Break allowed", AttendanceService.BREAK_ALLOWED_MINUTES + " minutes"),
                                    row("Note", "Break time beyond " + AttendanceService.BREAK_ALLOWED_MINUTES
                                            + " minutes is deducted from your working hours."))
                            + back("break.html", "Go to Break"));
                    break;
                }
                case "breakend": {
                    Employee e = attendanceService.getEmployee(id);
                    Attendance a = attendanceService.endBreak(id);
                    long taken = a.getBreakMinutes();
                    long extra = Math.max(0, taken - AttendanceService.BREAK_ALLOWED_MINUTES);
                    render(resp, "End Break",
                            ok("Break ended. Welcome back!")
                            + table(row("Employee", e.getId() + " - " + e.getName()),
                                    row("Break started", a.getBreakStartText()),
                                    row("Break ended", a.getBreakEndText()),
                                    row("Break taken", taken + " minutes"),
                                    row("Deducted from working hours", extra + " minutes"))
                            + back("break.html", "Go to Break"));
                    break;
                }
                case "checkout": {
                    Employee e = attendanceService.getEmployee(id);
                    Attendance a = attendanceService.checkOut(id);
                    render(resp, "Employee Check-Out",
                            ok("Check-out time recorded successfully.")
                            + table(row("Employee", e.getId() + " - " + e.getName()),
                                    row("Check-in", a.getCheckInText()),
                                    row("Check-out", a.getCheckOutText()),
                                    row("Break", a.getBreakText()),
                                    row("Working Time", AttendanceService.formatMinutes(a.getWorkedMinutes())),
                                    rowHtml("Status", badge(a.getStatus())),
                                    row("Result", resultNote(a.getStatus())))
                            + back("checkout.html", "Check out another employee"));
                    break;
                }
                case "absent": {
                    Employee e = attendanceService.getEmployee(id);
                    if (!"Y".equalsIgnoreCase(param(req, "confirm", "N")))
                        throw new IllegalStateException("Cancelled. Employee was not marked absent.");
                    Attendance a = attendanceService.markAbsent(id);
                    render(resp, "Mark Employee Absent",
                            ok("Attendance marked successfully.")
                            + table(row("Employee", e.getId() + " - " + e.getName()),
                                    row("Date", a.getDateText()),
                                    rowHtml("Status", badge(a.getStatus())))
                            + back("absent.html", "Mark another employee"));
                    break;
                }
                case "leave": {
                    Employee e = attendanceService.getEmployee(id);
                    String type = param(req, "leaveType", "").trim();
                    String reason = param(req, "reason", "").trim();
                    if (type.isEmpty()) throw new IllegalArgumentException("Leave type is required.");
                    Attendance a = attendanceService.markLeave(id, type, reason);
                    render(resp, "Mark Employee Leave",
                            ok("Leave recorded successfully.")
                            + table(row("Employee", e.getId() + " - " + e.getName()),
                                    row("Leave Type", type),
                                    row("Reason", reason),
                                    rowHtml("Status", badge(a.getStatus())))
                            + back("leave.html", "Record another leave"));
                    break;
                }
                default:
                    resp.sendRedirect(req.getContextPath() + "/attendance");
            }
        } catch (IllegalArgumentException | IllegalStateException ex) {
            error(resp, ex.getMessage());
        } catch (RuntimeException ex) {
            log("Database/unexpected error", ex);
            error(resp, "Database error. Check the Tomcat console for details.");
        }
    }

    // ================= page builders =================

    private void dashboard(HttpServletResponse resp) throws IOException {
        LocalDate today = LocalDate.now();
        int[] c = attendanceService.countByStatus(today);
        int present = c[Attendance.Status.PRESENT.ordinal()];
        int absent = c[Attendance.Status.ABSENT.ordinal()];
        int leave = c[Attendance.Status.LEAVE.ordinal()];
        int half = c[Attendance.Status.HALF_DAY.ordinal()];
        int total = employeeService.getActiveEmployees().size();
        String body =
                "<p>Today's Date: <b>" + today.format(Attendance.DATE_FMT) + "</b></p>"
              + "<div class='stats'>"
              + stat(total, "Total Employees") + stat(present, "Present") + stat(half, "Half Day")
              + stat(absent, "Absent") + stat(leave, "On Leave")
              + stat(Math.max(0, total - present - half - absent - leave), "Not Marked")
              + "</div>"
              + "<div class='menu'>"
              + "<a href='absent.html'>1. Mark Absent</a>"
              + "<a href='leave.html'>2. Mark Leave</a>"
              + "<a href='attendance?action=daily'>3. Today's Attendance</a>"
              + "<a href='history.html'>4. Employee Attendance History</a>"
              + "<a href='monthly.html'>5. Monthly Attendance Report</a>"
              + "</div>";
        render(resp, "ATTENDANCE DASHBOARD", body);
    }

    private void daily(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String d = param(req, "date", "");
        LocalDate date = d.isEmpty() ? LocalDate.now() : LocalDate.parse(d);   // yyyy-MM-dd from <input type="date">

        Map<String, Attendance> byEmp = new HashMap<>();
        for (Attendance a : attendanceService.getDailyAttendance(date)) byEmp.put(a.getEmployeeId(), a);

        StringBuilder sb = new StringBuilder();
        sb.append("<h2>").append(date.format(Attendance.DATE_FMT)).append("</h2>");
        sb.append("<table><tr><th>ID</th><th>Name</th><th>Department</th><th>Check-In</th><th>Worked</th><th>Status</th></tr>");
        for (Employee e : employeeService.getActiveEmployees()) {
            Attendance a = byEmp.get(e.getId());
            sb.append("<tr><td>").append(esc(e.getId())).append("</td><td>").append(esc(e.getName()))
              .append("</td><td>").append(esc(e.getDepartment())).append("</td><td>")
              .append(a == null ? "--" : a.getCheckInText()).append("</td><td>")
              .append(a == null ? "--" : a.getWorkedText()).append("</td><td>")
              .append(a == null ? "NOT MARKED" : badge(a.getStatus())).append("</td></tr>");
        }
        sb.append("</table>");
        int[] c = attendanceService.countByStatus(date);
        sb.append("<p>Present : <b>").append(c[Attendance.Status.PRESENT.ordinal()])
          .append("</b> &nbsp; Half Day : <b>").append(c[Attendance.Status.HALF_DAY.ordinal()])
          .append("</b> &nbsp; Absent : <b>").append(c[Attendance.Status.ABSENT.ordinal()])
          .append("</b> &nbsp; Leave : <b>").append(c[Attendance.Status.LEAVE.ordinal()]).append("</b></p>");
        sb.append(back("daily.html", "Choose another date"));
        render(resp, "DAILY ATTENDANCE REPORT", sb.toString());
    }

    private void history(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String id = param(req, "employeeId", "").trim();
        if (id.isEmpty()) throw new IllegalArgumentException("Please enter an Employee ID.");
        Employee e = attendanceService.getEmployee(id);
        List<Attendance> list = attendanceService.getEmployeeAttendance(id);

        int present = 0, half = 0, absent = 0, leave = 0;
        StringBuilder sb = new StringBuilder();
        sb.append("<div class='table-responsive'>");
        sb.append("<table><thead><tr><th>Date</th><th>Check-In</th><th>Check-Out</th><th>Break</th><th>Worked</th><th>Status</th></tr></thead><tbody>");
        if (list.isEmpty()) {
            sb.append("<tr><td colspan='6' style='text-align:center; padding:28px 16px; color:var(--slate-400); font-weight:500;'>No attendance records recorded yet.</td></tr>");
        }
        for (Attendance a : list) {
            sb.append("<tr><td style='font-weight:700; color:var(--slate-900);'>").append(a.getDateText()).append("</td><td>")
              .append(a.getCheckInText()).append("</td><td>")
              .append(a.getCheckOutText()).append("</td><td>")
              .append(a.getBreakText()).append("</td><td style='font-weight:600; color:var(--primary);'>")
              .append(a.getWorkedText()).append("</td><td>")
              .append(badge(a.getStatus())).append("</td></tr>");
            switch (a.getStatus()) {
                case PRESENT:  present++; break;
                case HALF_DAY: half++;    break;
                case ABSENT:   absent++;  break;
                default:       leave++;   break;
            }
        }
        sb.append("</tbody></table></div>");
        sb.append("<div class='attendance-summary-chips'>");
        sb.append("<div class='att-chip att-chip-present'><span class='chip-dot'></span><span class='chip-label'>Present:</span><span class='chip-val'>").append(present).append("</span></div>");
        sb.append("<div class='att-chip att-chip-half'><span class='chip-dot'></span><span class='chip-label'>Half Day:</span><span class='chip-val'>").append(half).append("</span></div>");
        sb.append("<div class='att-chip att-chip-absent'><span class='chip-dot'></span><span class='chip-label'>Absent:</span><span class='chip-val'>").append(absent).append("</span></div>");
        sb.append("<div class='att-chip att-chip-leave'><span class='chip-dot'></span><span class='chip-label'>Leave:</span><span class='chip-val'>").append(leave).append("</span></div>");
        sb.append("</div>");
        render(resp, "ATTENDANCE HISTORY", sb.toString());
    }

    private void monthly(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String id = param(req, "employeeId", "").trim();
        if (id.isEmpty()) throw new IllegalArgumentException("Please enter an Employee ID.");
        String m = param(req, "month", "");
        YearMonth ym = m.isEmpty() ? YearMonth.now() : YearMonth.parse(m);      // yyyy-MM from <input type="month">
        AttendanceService.MonthlySummary s = attendanceService.getMonthlySummary(id, ym);

        String monthTitle = ym.getMonth().getDisplayName(TextStyle.FULL, Locale.ENGLISH) + " " + ym.getYear();
        String body = "<div class='monthly-summary-wrap'>"
                + "<div style='display:flex; align-items:center; justify-content:space-between; margin-bottom:14px;'>"
                + "<h3 style='font-size:16px; font-weight:700; color:var(--slate-800); margin:0;'>Cycle Breakdown</h3>"
                + "<span class='monthly-month-pill' style='display:inline-flex; align-items:center; padding:4px 12px; border-radius:9999px; background:#eff6ff; color:#1d4ed8; font-weight:700; font-size:12.5px; border:1px solid #bfdbfe;'>" + monthTitle + "</span>"
                + "</div>"
                + table(row("Working Days", String.valueOf(s.getWorkingDays())),
                        row("Present", String.valueOf(s.getPresent())),
                        row("Half Day", String.valueOf(s.getHalfDay())),
                        row("Absent", String.valueOf(s.getAbsent())),
                        row("Leave", String.valueOf(s.getLeave())),
                        rowHtml("Attendance Percentage",
                                "<span style='display:inline-block; padding:4px 12px; border-radius:6px; background:#ecfdf5; color:#065f46; font-weight:800; border:1px solid #a7f3d0; font-size:14px;'>" + String.format(Locale.ENGLISH, "%.2f%%", s.getPercentage()) + "</span>"))
                + "<p class='hint' style='margin-top:14px; color:var(--slate-500); font-size:13px;'>A half day counts as 0.5 day in the percentage calculation.</p>"
                + "</div>";
        render(resp, "MONTHLY ATTENDANCE SUMMARY", body);
    }

    // ================= HTML helpers =================

    private void render(HttpServletResponse resp, String title, String body) throws IOException {
        resp.setContentType("text/html;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        out.println("<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'>");
        out.println("<meta name='viewport' content='width=device-width, initial-scale=1'>");
        out.println("<title>" + esc(title) + "</title><link rel='stylesheet' href='style.css'></head>");
        out.println("<body><div class='wrap'><h1>" + esc(title) + "</h1>" + body);
        out.println("<p><a class='btn grey' href='attendance'>&larr; Attendance Dashboard</a></p>");
        out.println("</div></body></html>");
    }

    private void error(HttpServletResponse resp, String message) throws IOException {
        render(resp, "Attendance", "<div class='msg err'>" + esc(message) + "</div>"
                + "<p><a class='btn' href='javascript:history.back()'>Go back</a></p>");
    }

    private static String resultNote(Attendance.Status s) {
        switch (s) {
            case PRESENT:  return "Worked 8 hours or more: marked PRESENT.";
            case HALF_DAY: return "Worked less than 8 hours: marked HALF DAY.";
            default:       return "Worked less than 4 hours: marked ABSENT.";
        }
    }

    private static String ok(String msg)   { return "<div class='msg ok'>" + esc(msg) + "</div>"; }
    private static String back(String href, String label) { return "<p><a class='btn' href='" + href + "'>" + esc(label) + "</a></p>"; }
    private static String stat(int n, String label) { return "<div class='stat'><b>" + n + "</b>" + label + "</div>"; }
    private static String badge(Attendance.Status s) { return "<span class='" + s + "'>" + s.name().replace('_', ' ') + "</span>"; }
    private static String row(String k, String v) { return "<tr><th>" + k + "</th><td>" + esc(v) + "</td></tr>"; }
    private static String rowHtml(String k, String html) { return "<tr><th>" + k + "</th><td>" + html + "</td></tr>"; }
    private static String table(String... rows) { return "<table>" + String.join("", rows) + "</table>"; }

    private static String param(HttpServletRequest req, String name, String def) {
        String v = req.getParameter(name);
        return v == null ? def : v;
    }

    /** Escape user-supplied text before it is written into HTML (prevents XSS). */
    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
}