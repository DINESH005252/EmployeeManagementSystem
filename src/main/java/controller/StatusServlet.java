package controller;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.Attendance;
import model.User;
import service.AttendanceService;
import service.EmployeeService;

import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;

/** Live status of the logged-in employee for today. The employee page uses it to enable/disable buttons. */
@WebServlet("/status")
public class StatusServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private AttendanceService service;

    @Override
    public void init() {
        service = new AttendanceService(new EmployeeService());
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        User u = session == null ? null : (User) session.getAttribute("user");
        if (u == null || u.isHr()) { resp.sendError(HttpServletResponse.SC_UNAUTHORIZED); return; }

        try {
            String id = u.getEmployeeId();
            LocalDate today = LocalDate.now();
            Attendance a = service.findRecord(id, today);

            boolean hasRecord = a != null;
            boolean checkedIn = hasRecord && a.getCheckInTime() != null;
            boolean checkedOut = hasRecord && a.getCheckOutTime() != null;
            boolean onBreak = hasRecord && a.isOnBreak();
            int started = hasRecord ? a.breaksStarted() : 0;
            int completed = hasRecord ? a.breaksCompleted() : 0;
            boolean onLeave = service.isBlockedByLeave(id);
            String recordStatus = hasRecord ? a.getStatus().name() : "";

            long breakStartMillis = 0;
            if (onBreak) {
                LocalTime t = a.getBreakStart(started - 1);
                breakStartMillis = today.atTime(t).atZone(ZoneId.systemDefault()).toInstant().toEpochMilli();
            }

            resp.setContentType("application/json;charset=UTF-8");
            resp.getWriter().write("{"
                    + "\"hasRecord\":" + hasRecord
                    + ",\"recordStatus\":\"" + recordStatus + "\""
                    + ",\"checkedIn\":" + checkedIn
                    + ",\"checkedOut\":" + checkedOut
                    + ",\"onLeave\":" + onLeave
                    + ",\"onBreak\":" + onBreak
                    + ",\"breaksStarted\":" + started
                    + ",\"breaksCompleted\":" + completed
                    + ",\"maxBreaks\":" + Attendance.MAX_BREAKS
                    + ",\"breakAllowedMinutes\":" + Attendance.BREAK_ALLOWED_MINUTES
                    + ",\"breakStartMillis\":" + breakStartMillis
                    + ",\"nowMillis\":" + System.currentTimeMillis()
                    + "}");
        } catch (RuntimeException ex) {
            log("Status error", ex);
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }
}