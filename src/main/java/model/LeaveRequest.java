package model;

import java.time.DayOfWeek;
import java.time.LocalDate;

public class LeaveRequest {
    public enum Status { PENDING, APPROVED, REJECTED }

    private final int id;
    private final String employeeId;
    private final String employeeName;
    private final String leaveType;
    private final LocalDate fromDate;
    private final LocalDate toDate;
    private final String reason;
    private final Status status;
    private final String decidedBy;
    private final String decisionReason;

    public LeaveRequest(int id, String employeeId, String employeeName, String leaveType,
                        LocalDate fromDate, LocalDate toDate, String reason, Status status,
                        String decidedBy, String decisionReason) {
        this.id = id;
        this.employeeId = employeeId;
        this.employeeName = employeeName;
        this.leaveType = leaveType;
        this.fromDate = fromDate;
        this.toDate = toDate;
        this.reason = reason;
        this.status = status;
        this.decidedBy = decidedBy;
        this.decisionReason = decisionReason;
    }

    public int getId() { return id; }
    public String getEmployeeId() { return employeeId; }
    public String getEmployeeName() { return employeeName; }
    public String getLeaveType() { return leaveType; }
    public LocalDate getFromDate() { return fromDate; }
    public LocalDate getToDate() { return toDate; }
    public String getReason() { return reason; }
    public Status getStatus() { return status; }
    public String getDecidedBy() { return decidedBy; }
    public String getDecisionReason() { return decisionReason; }

    public String getFromText() { return fromDate.format(Attendance.DATE_FMT); }
    public String getToText() { return toDate.format(Attendance.DATE_FMT); }
    public int getWorkingDays() { return countWorkingDays(fromDate, toDate); }

    /** Monday to Friday days between two dates, inclusive. */
    public static int countWorkingDays(LocalDate from, LocalDate to) {
        int n = 0;
        for (LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) {
            DayOfWeek w = d.getDayOfWeek();
            if (w != DayOfWeek.SATURDAY && w != DayOfWeek.SUNDAY) n++;
        }
        return n;
    }
}	