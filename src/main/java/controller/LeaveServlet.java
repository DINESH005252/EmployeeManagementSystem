package controller;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.LeaveRequest;
import model.User;
import service.EmployeeService;
import service.LeaveService;

import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;

/**
 * Leave requests.
 *  GET  /leave                      employee: own requests, HR: all requests
 *  POST /leave action=request       employee submits a request
 *  POST /leave action=decide        HR approves / rejects (id, decision=approve|reject, reason for reject)
 */
@WebServlet("/leave")
public class LeaveServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private LeaveService leaveService;

    @Override
    public void init() {
        leaveService = new LeaveService(new EmployeeService());
    }

    private User currentUser(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s == null ? null : (User) s.getAttribute("user");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User u = currentUser(req);
        if (u == null) { resp.sendError(HttpServletResponse.SC_UNAUTHORIZED); return; }
        try {
            if (u.isHr()) page(resp, "LEAVE REQUESTS", hrTable());
            else page(resp, "MY LEAVE REQUESTS", employeeTable(u.getEmployeeId()));
        } catch (RuntimeException ex) {
            log("Leave error", ex);
            error(resp, "Database error. Check the Tomcat console for details.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        req.setCharacterEncoding("UTF-8");
        User u = currentUser(req);
        if (u == null) { resp.sendError(HttpServletResponse.SC_UNAUTHORIZED); return; }
        String action = param(req, "action");
        try {
            if ("request".equals(action)) {
            	if (u.isHr()) throw new IllegalStateException("HR cannot submit leave requests.");
                leaveService.submit(u.getEmployeeId(), param(req, "leaveType"),
                        LocalDate.parse(param(req, "fromDate")), LocalDate.parse(param(req, "toDate")),
                        param(req, "reason"));
                page(resp, "LEAVE REQUEST",
                        ok("Leave request submitted. HR will review it.") + employeeTable(u.getEmployeeId()));

            } else if ("decide".equals(action)) {
                if (!u.isHr()) throw new IllegalStateException("Only HR can approve or reject leave requests.");
                int id;
                try { id = Integer.parseInt(param(req, "id")); }
                catch (NumberFormatException ex) { throw new IllegalArgumentException("Invalid request."); }
                boolean approve = "approve".equals(param(req, "decision"));
                leaveService.decide(id, approve, u.getUsername(), param(req, "reason"));
                page(resp, "LEAVE REQUESTS",
                        ok(approve ? "Leave approved. The employee's attendance is marked LEAVE for those days."
                                   : "Leave request rejected. The employee will see your reason.")
                        + hrTable());
            } else {
                throw new IllegalArgumentException("Unknown action.");
            }
        } catch (DateTimeParseException ex) {
            error(resp, "Please choose valid dates.");
        } catch (IllegalArgumentException | IllegalStateException ex) {
            error(resp, ex.getMessage());
        } catch (RuntimeException ex) {
            log("Leave error", ex);
            error(resp, "Database error. Check the Tomcat console for details.");
        }
    }

    // ---------------- tables ----------------

    private String employeeTable(String employeeId) {
        List<LeaveRequest> list = leaveService.listMine(employeeId);
        StringBuilder sb = new StringBuilder("<h2>My Leave Requests</h2>");
        if (list.isEmpty()) return sb.append("<p>You have not requested any leave yet.</p>").toString();
        sb.append("<table><tr><th>Type</th><th>From</th><th>To</th><th>Working days</th><th>Reason</th>"
                + "<th>Status</th><th>HR Note</th></tr>");
        for (LeaveRequest r : list) {
            sb.append("<tr><td>").append(esc(r.getLeaveType())).append("</td><td>").append(r.getFromText())
              .append("</td><td>").append(r.getToText()).append("</td><td>").append(r.getWorkingDays())
              .append("</td><td>").append(esc(r.getReason())).append("</td><td>").append(statusCell(r))
              .append("</td><td>").append(hrNoteCell(r)).append("</td></tr>");
        }
        return sb.append("</table>").toString();
    }

    private String hrTable() {
        List<LeaveRequest> list = leaveService.listAll();
        StringBuilder sb = new StringBuilder("<h2>Leave Requests</h2>");
        if (list.isEmpty()) return sb.append("<p>No leave requests yet.</p>").toString();
        sb.append("<table><tr><th>Employee</th><th>Type</th><th>From</th><th>To</th><th>Days</th>"
                + "<th>Reason</th><th>Status</th><th>HR Note</th><th>Action</th></tr>");
        for (LeaveRequest r : list) {
            sb.append("<tr><td>").append(esc(r.getEmployeeId())).append(" - ").append(esc(r.getEmployeeName()))
              .append("</td><td>").append(esc(r.getLeaveType()))
              .append("</td><td>").append(r.getFromText()).append("</td><td>").append(r.getToText())
              .append("</td><td>").append(r.getWorkingDays())
              .append("</td><td>").append(esc(r.getReason()))
              .append("</td><td>").append(statusCell(r))
              .append("</td><td>").append(hrNoteCell(r)).append("</td><td>");
            if (r.getStatus() == LeaveRequest.Status.PENDING) {
                sb.append("<button class='approve' data-id='").append(r.getId()).append("'>Approve</button>")
                  .append("<button class='reject' data-id='").append(r.getId()).append("'>Reject</button>")
                  .append("<div class='reject-box' id='rb-").append(r.getId()).append("' style='display:none;margin-top:6px'>")
                  .append("<input class='reject-reason' id='rr-").append(r.getId())
                  .append("' placeholder='Reason for rejecting' maxlength='255'>")
                  .append("<button class='confirm-reject' data-id='").append(r.getId()).append("'>Confirm Reject</button>")
                  .append("</div>");
            } else {
                sb.append("--");
            }
            sb.append("</td></tr>");
        }
        return sb.append("</table>").toString();
    }

    private static String statusCell(LeaveRequest r) {
        String s = "<span class='" + r.getStatus() + "'>" + r.getStatus() + "</span>";
        if (r.getDecidedBy() != null) s += "<br><small>by " + esc(r.getDecidedBy()) + "</small>";
        return s;
    }

    private static String hrNoteCell(LeaveRequest r) {
        if (r.getStatus() == LeaveRequest.Status.REJECTED && r.getDecisionReason() != null)
            return esc(r.getDecisionReason());
        return "--";
    }

    // ---------------- helpers ----------------

    private void page(HttpServletResponse resp, String title, String body) throws IOException {
        resp.setContentType("text/html;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        out.println("<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><title>" + esc(title)
                + "</title></head><body><div class='wrap'><h1>" + esc(title) + "</h1>" + body + "</div></body></html>");
    }

    private void error(HttpServletResponse resp, String message) throws IOException {
        page(resp, "Leave", "<div class='msg err'>" + esc(message) + "</div>");
    }

    private static String ok(String msg) { return "<div class='msg ok'>" + esc(msg) + "</div>"; }

    private static String param(HttpServletRequest req, String name) {
        String v = req.getParameter(name);
        return v == null ? "" : v.trim();
    }

    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
}