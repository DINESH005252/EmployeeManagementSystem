package model;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

public class Attendance {
    /** Keep HALF_DAY last: the count arrays use the position of each value. */
    public enum Status { PRESENT, ABSENT, LEAVE, HALF_DAY }

    public static final int MAX_BREAKS = 2;
    public static final int BREAK_ALLOWED_MINUTES = 15;

    public static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd-MM-yyyy");
    public static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("hh:mm a", Locale.ENGLISH);

    private int id;
    private final String employeeId;
    private final LocalDate date;
    private LocalTime checkInTime;
    private LocalTime checkOutTime;
    private Status status;
    private String leaveType;
    private String reason;
    private final LocalTime[] breakStart = new LocalTime[MAX_BREAKS];
    private final LocalTime[] breakEnd = new LocalTime[MAX_BREAKS];
    private Integer workedMinutes;
    private boolean autoCheckout;

    public Attendance(int id, String employeeId, LocalDate date,
                      LocalTime checkInTime, LocalTime checkOutTime, Status status) {
        this.id = id;
        this.employeeId = employeeId;
        this.date = date;
        this.checkInTime = checkInTime;
        this.checkOutTime = checkOutTime;
        this.status = status;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getAttendanceId() { return String.format("ATT%03d", id); }
    public String getEmployeeId() { return employeeId; }
    public LocalDate getDate() { return date; }
    public LocalTime getCheckInTime() { return checkInTime; }
    public LocalTime getCheckOutTime() { return checkOutTime; }
    public Status getStatus() { return status; }
    public String getLeaveType() { return leaveType; }
    public String getReason() { return reason; }
    public Integer getWorkedMinutes() { return workedMinutes; }
    public boolean isAutoCheckout() { return autoCheckout; }
    public void setAutoCheckout(boolean b) { this.autoCheckout = b; }

    public void setCheckOutTime(LocalTime t) { this.checkOutTime = t; }
    public void setStatus(Status status) { this.status = status; }
    public void setWorkedMinutes(Integer m) { this.workedMinutes = m; }
    public void setLeaveDetails(String leaveType, String reason) {
        this.leaveType = leaveType;
        this.reason = reason;
    }

    // ---------- breaks (index 0 = first break, 1 = second break) ----------

    public LocalTime getBreakStart(int i) { return breakStart[i]; }
    public LocalTime getBreakEnd(int i) { return breakEnd[i]; }
    public void setBreakStart(int i, LocalTime t) { breakStart[i] = t; }
    public void setBreakEnd(int i, LocalTime t) { breakEnd[i] = t; }

    public int breaksStarted() {
        int n = 0;
        for (LocalTime t : breakStart) if (t != null) n++;
        return n;
    }

    public int breaksCompleted() {
        int n = 0;
        for (int i = 0; i < MAX_BREAKS; i++) if (breakStart[i] != null && breakEnd[i] != null) n++;
        return n;
    }

    public boolean isOnBreak() { return breaksStarted() > breaksCompleted(); }

    /** Whole minutes of one completed break (0 if it is not completed). */
    public long getBreakMinutes(int i) {
        if (breakStart[i] == null || breakEnd[i] == null) return 0;
        return Math.max(0, Duration.between(breakStart[i], breakEnd[i]).toMinutes());
    }

    /** Minutes beyond the allowed 15 per break, added up over both breaks. */
    public long getExtraBreakMinutes() {
        long extra = 0;
        for (int i = 0; i < MAX_BREAKS; i++) extra += Math.max(0, getBreakMinutes(i) - BREAK_ALLOWED_MINUTES);
        return extra;
    }

    // Helpers about the most recent break (kept so older code keeps working)
    public String getBreakStartText() {
        int n = breaksStarted();
        return n == 0 ? "--" : breakStart[n - 1].format(TIME_FMT);
    }
    public String getBreakEndText() {
        int n = breaksCompleted();
        return n == 0 ? "--" : breakEnd[n - 1].format(TIME_FMT);
    }
    public long getBreakMinutes() {
        int n = breaksCompleted();
        return n == 0 ? 0 : getBreakMinutes(n - 1);
    }

    // ---------- display helpers ----------
    public String getDateText()     { return date.format(DATE_FMT); }
    public String getCheckInText()  { return checkInTime  == null ? "--" : checkInTime.format(TIME_FMT); }
    public String getCheckOutText() { return checkOutTime == null ? "--" : checkOutTime.format(TIME_FMT); }
    public String getStatusLabel()  { return status.name().replace('_', ' '); }

    public String getBreakText() {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < MAX_BREAKS; i++) {
            if (breakStart[i] == null) break;
            if (sb.length() > 0) sb.append("; ");
            sb.append("B").append(i + 1).append(": ").append(breakStart[i].format(TIME_FMT));
            if (breakEnd[i] == null) sb.append(" (on break)");
            else sb.append(" - ").append(breakEnd[i].format(TIME_FMT)).append(" (").append(getBreakMinutes(i)).append(" min)");
        }
        return sb.length() == 0 ? "--" : sb.toString();
    }

    public String getWorkedText() {
        if (workedMinutes == null) return "--";
        String t = (workedMinutes / 60) + "h " + (workedMinutes % 60) + "m";
        return autoCheckout ? t + " (auto)" : t;
    }
}