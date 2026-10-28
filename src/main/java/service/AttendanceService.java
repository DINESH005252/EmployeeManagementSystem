package service;

import dao.AttendanceDAO;
import dao.LeaveDAO;
import model.Attendance;
import model.Employee;

import java.time.*;
import java.util.List;

/**
 * All attendance business rules live here (not in the servlet).
 * Throws IllegalArgumentException / IllegalStateException with user-friendly messages.
 */
public class AttendanceService {

    // ----- rules (change these if the limits change) -----
    public static final int FULL_DAY_MINUTES = 8 * 60;      // 8 hours or more  -> PRESENT
    public static final int HALF_DAY_MINUTES = 4 * 60;      // 4 to under 8     -> HALF_DAY, under 4 -> ABSENT
    public static final int BREAK_ALLOWED_MINUTES = Attendance.BREAK_ALLOWED_MINUTES;   // 15 per break
    public static final int MAX_BREAKS = Attendance.MAX_BREAKS;                          // 2 per day

    /** Result holder for the monthly report. */
    public static class MonthlySummary {
        private final Employee employee;
        private final YearMonth month;
        private final int workingDays, present, halfDay, absent, leave;
        private final double percentage;

        public MonthlySummary(Employee employee, YearMonth month, int workingDays,
                              int present, int halfDay, int absent, int leave, double percentage) {
            this.employee = employee; this.month = month; this.workingDays = workingDays;
            this.present = present; this.halfDay = halfDay; this.absent = absent; this.leave = leave;
            this.percentage = percentage;
        }
        public Employee getEmployee() { return employee; }
        public YearMonth getMonth() { return month; }
        public int getWorkingDays() { return workingDays; }
        public int getPresent() { return present; }
        public int getHalfDay() { return halfDay; }
        public int getAbsent() { return absent; }
        public int getLeave() { return leave; }
        public double getPercentage() { return percentage; }
    }

    private final EmployeeService employeeService;
    private final AttendanceDAO dao = new AttendanceDAO();
    private final LeaveDAO leaveDao = new LeaveDAO();

    public AttendanceService(EmployeeService employeeService) {
        this.employeeService = employeeService;
    }

    // ---------- helpers ----------

    public Employee getEmployee(String employeeId) {
        Employee e = employeeService.findById(employeeId);
        if (e == null) throw new IllegalArgumentException("Employee not found: " + employeeId);
        return e;
    }

    private Employee requireActiveEmployee(String employeeId) {
        Employee e = getEmployee(employeeId);
        if (!e.isActive()) throw new IllegalStateException("Employee " + e.getName() + " is not ACTIVE.");
        return e;
    }

    private static LocalTime nowToMinute() { return LocalTime.now().withSecond(0).withNano(0); }

    /** Breaks keep the seconds so the 15-minute countdown on the page is accurate. */
    private static LocalTime nowToSecond() { return LocalTime.now().withNano(0); }

    public Attendance findRecord(String employeeId, LocalDate date) {
        return dao.find(employeeId, date);
    }

    /** Today's record, which must have a check-in. */
    private Attendance todaysCheckedInRecord(Employee e) {
        Attendance a = dao.find(e.getId(), LocalDate.now());
        if (a == null || a.getCheckInTime() == null)
            throw new IllegalStateException("Employee has not checked in today.");
        return a;
    }

    // ---------- approved leave ----------

    /**
     * True when today is covered by an APPROVED leave request and the employee has not already
     * started working today. Pending and rejected requests never block anything.
     */
    public boolean isBlockedByLeave(String employeeId) {
        Attendance today = dao.find(employeeId, LocalDate.now());
        if (today != null && today.getCheckInTime() != null) return false;
        return leaveDao.isOnApprovedLeave(employeeId, LocalDate.now());
    }

    private void requireNotOnLeave(Employee e) {
        if (isBlockedByLeave(e.getId()))
            throw new IllegalStateException(
                    "You are on approved leave today, so check-in, breaks and check-out are disabled.");
    }

    // ---------- check-in ----------

    public Attendance checkIn(String employeeId) {
        Employee e = requireActiveEmployee(employeeId);
        requireNotOnLeave(e);
        LocalDate today = LocalDate.now();
        Attendance existing = dao.find(e.getId(), today);
        if (existing != null) {
            throw new IllegalStateException(existing.getCheckInTime() != null
                    ? "Employee has already checked in today."
                    : "Attendance already marked as " + existing.getStatusLabel() + " for today.");
        }
        // Provisional PRESENT: the final status is decided at check-out from the hours worked.
        return dao.insert(new Attendance(0, e.getId(), today, nowToMinute(), null, Attendance.Status.PRESENT));
    }

    // ---------- breaks (2 per day, 15 minutes each) ----------

    public Attendance startBreak(String employeeId) {
        Employee e = getEmployee(employeeId);
        requireNotOnLeave(e);
        Attendance a = todaysCheckedInRecord(e);
        if (a.getCheckOutTime() != null)
            throw new IllegalStateException("Employee has already checked out today.");
        if (a.isOnBreak())
            throw new IllegalStateException("You are already on a break. End it first.");
        int used = a.breaksStarted();
        if (used >= MAX_BREAKS)
            throw new IllegalStateException("Both breaks have been used today. No more breaks are allowed.");

        LocalTime t = nowToSecond();
        dao.updateBreakStart(a.getId(), used, t);
        a.setBreakStart(used, t);
        return a;
    }

    public Attendance endBreak(String employeeId) {
        Employee e = getEmployee(employeeId);
        requireNotOnLeave(e);
        Attendance a = todaysCheckedInRecord(e);
        if (a.getCheckOutTime() != null)
            throw new IllegalStateException("Employee has already checked out today.");
        if (!a.isOnBreak())
            throw new IllegalStateException("You are not on a break.");

        int index = a.breaksStarted() - 1;
        LocalTime t = nowToSecond();
        dao.updateBreakEnd(a.getId(), index, t);
        a.setBreakEnd(index, t);
        return a;
    }

    // ---------- check-out ----------

    public Attendance checkOut(String employeeId) {
        Employee e = getEmployee(employeeId);
        requireNotOnLeave(e);
        Attendance a = todaysCheckedInRecord(e);
        if (a.getCheckOutTime() != null)
            throw new IllegalStateException("Employee has already checked out today.");
        if (a.isOnBreak())
            throw new IllegalStateException("Please end your break before checking out.");

        LocalTime out = nowToMinute();
        if (!out.isAfter(a.getCheckInTime()))
            throw new IllegalStateException("Check-out time must be after check-in time.");

        return closeOut(a, out, false);
    }

    /** Shared by manual check-out and the auto-checkout job. */
    private Attendance closeOut(Attendance a, LocalTime out, boolean auto) {
        long netMinutes = calculateNetMinutes(a.getCheckInTime(), out, a.getExtraBreakMinutes());
        Attendance.Status status = determineStatus(netMinutes);

        dao.completeCheckOut(a.getId(), out, (int) netMinutes, status, auto);
        a.setCheckOutTime(out);
        a.setWorkedMinutes((int) netMinutes);
        a.setStatus(status);
        a.setAutoCheckout(auto);
        return a;
    }

    /**
     * Runs once a day: finds every record for the given date that was checked in but never
     * checked out, closes an open break automatically, and checks them out using the given time.
     * Returns how many records were auto-closed.
     */
    public int autoCheckOutOpenRecords(LocalDate date, LocalTime closeAt) {
        int closed = 0;
        for (Attendance a : dao.findByDate(date)) {
            if (a.getCheckInTime() == null || a.getCheckOutTime() != null) continue;   // not open

            if (a.isOnBreak()) {
                int idx = a.breaksStarted() - 1;
                dao.updateBreakEnd(a.getId(), idx, closeAt);
                a.setBreakEnd(idx, closeAt);
            }

            LocalTime out = closeAt.isAfter(a.getCheckInTime()) ? closeAt : a.getCheckInTime().plusMinutes(1);
            closeOut(a, out, true);
            closed++;
        }
        return closed;
    }
    
    /**
     * Startup catch-up: closes any open record left over from a previous day (e.g. Tomcat was off
     * at 11:55 PM that night). Uses 11:55 PM of that record's own date as the close time.
     */
    public int autoCheckOutStaleRecords(LocalDate today) {
        int closed = 0;
        LocalTime endOfDay = LocalTime.of(23, 55);
        for (Attendance a : dao.findOpenBefore(today)) {
            if (a.isOnBreak()) {
                int idx = a.breaksStarted() - 1;
                dao.updateBreakEnd(a.getId(), idx, endOfDay);
                a.setBreakEnd(idx, endOfDay);
            }
            LocalTime out = endOfDay.isAfter(a.getCheckInTime()) ? endOfDay : a.getCheckInTime().plusMinutes(1);
            closeOut(a, out, true);
            closed++;
        }
        return closed;
    }

    /** Total time between check-in and check-out (before any break deduction). */
    public Duration calculateWorkingHours(LocalTime checkIn, LocalTime checkOut) {
        if (checkIn == null || checkOut == null || !checkOut.isAfter(checkIn))
            throw new IllegalArgumentException("Invalid check-in / check-out times.");
        return Duration.between(checkIn, checkOut);
    }

    /** Working minutes after deducting the break time that went beyond 15 minutes per break. */
    public long calculateNetMinutes(LocalTime checkIn, LocalTime checkOut, long extraBreakMinutes) {
        long gross = calculateWorkingHours(checkIn, checkOut).toMinutes();
        return Math.max(0, gross - extraBreakMinutes);
    }

    /** 8h or more = PRESENT, 4h or more = HALF_DAY, otherwise ABSENT. */
    public static Attendance.Status determineStatus(long netMinutes) {
        if (netMinutes >= FULL_DAY_MINUTES) return Attendance.Status.PRESENT;
        if (netMinutes >= HALF_DAY_MINUTES) return Attendance.Status.HALF_DAY;
        return Attendance.Status.ABSENT;
    }

    public static String formatDuration(Duration d) { return formatMinutes(d.toMinutes()); }

    public static String formatMinutes(long minutes) {
        return (minutes / 60) + " Hours " + (minutes % 60) + " Minutes";
    }

    // ---------- absent / leave (marked by HR) ----------

    public Attendance markAbsent(String employeeId) {
        Employee e = requireActiveEmployee(employeeId);
        return markNonPresent(e, Attendance.Status.ABSENT, null, null);
    }

    public Attendance markLeave(String employeeId, String leaveType, String reason) {
        Employee e = requireActiveEmployee(employeeId);
        return markNonPresent(e, Attendance.Status.LEAVE, leaveType, reason);
    }

    private Attendance markNonPresent(Employee e, Attendance.Status status, String leaveType, String reason) {
        LocalDate today = LocalDate.now();
        if (dao.find(e.getId(), today) != null)
            throw new IllegalStateException("Attendance is already recorded for " + e.getName() + " today.");
        Attendance a = new Attendance(0, e.getId(), today, null, null, status);
        if (status == Attendance.Status.LEAVE) a.setLeaveDetails(leaveType, reason);
        return dao.insert(a);
    }

    // ---------- reports ----------

    public List<Attendance> getDailyAttendance(LocalDate date) { return dao.findByDate(date); }

    public List<Attendance> getEmployeeAttendance(String employeeId) {
        getEmployee(employeeId);
        return dao.findByEmployee(employeeId.trim().toUpperCase());
    }

    /** A half day counts as 0.5 day in the attendance percentage. */
    public MonthlySummary getMonthlySummary(String employeeId, YearMonth month) {
        Employee e = getEmployee(employeeId);
        int[] c = dao.countByStatus(e.getId(), month.atDay(1), month.atEndOfMonth());
        int present = c[Attendance.Status.PRESENT.ordinal()];
        int absent = c[Attendance.Status.ABSENT.ordinal()];
        int leave = c[Attendance.Status.LEAVE.ordinal()];
        int half = c[Attendance.Status.HALF_DAY.ordinal()];

        int workingDays = countWorkingDays(month);
        double pct = workingDays == 0 ? 0 : (present + 0.5 * half) * 100.0 / workingDays;
        return new MonthlySummary(e, month, workingDays, present, half, absent, leave, pct);
    }

    /** Working days = Monday to Friday (holidays not modelled in this version). */
    public int countWorkingDays(YearMonth month) {
        int count = 0;
        for (int d = 1; d <= month.lengthOfMonth(); d++) {
            DayOfWeek dow = month.atDay(d).getDayOfWeek();
            if (dow != DayOfWeek.SATURDAY && dow != DayOfWeek.SUNDAY) count++;
        }
        return count;
    }

    /** Counts for one date across all employees: [PRESENT, ABSENT, LEAVE, HALF_DAY]. */
    public int[] countByStatus(LocalDate date) { return dao.countByStatus(null, date, date); }
}