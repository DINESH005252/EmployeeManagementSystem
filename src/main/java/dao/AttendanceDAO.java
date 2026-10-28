package dao;

import model.Attendance;
import util.DBConnection;

import java.sql.*;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;


public class AttendanceDAO {
    private static final String COLS =
            "id, employee_id, attendance_date, check_in_time, check_out_time, status, leave_type, reason, "
          + "break_start, break_end, break2_start, break2_end, worked_minutes, auto_checkout";

    /** Inserts a record and sets the generated id on the object. */
    public Attendance insert(Attendance a) {
        String sql = "INSERT INTO attendance "
                + "(employee_id, attendance_date, check_in_time, status, leave_type, reason) VALUES (?,?,?,?,?,?)";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, a.getEmployeeId());
            ps.setObject(2, a.getDate());
            if (a.getCheckInTime() == null) ps.setNull(3, Types.TIME);
            else ps.setObject(3, a.getCheckInTime());
            ps.setString(4, a.getStatus().name());
            ps.setString(5, a.getLeaveType());
            ps.setString(6, a.getReason());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) a.setId(keys.getInt(1));
            }
            return a;
        } catch (SQLException e) {
            if (e.getErrorCode() == 1062)   // duplicate (employee_id, attendance_date)
                throw new IllegalStateException("Attendance is already recorded for this employee on "
                        + a.getDateText() + ".");
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    /** Saves the check-out time, the net working minutes and the final status in one update. */
    public void completeCheckOut(int id, LocalTime checkOut, int workedMinutes, Attendance.Status status,
                                 boolean autoCheckout) {
        updateOne("UPDATE attendance SET check_out_time = ?, worked_minutes = ?, status = ?, auto_checkout = ? "
                + "WHERE id = ? AND check_out_time IS NULL",
                "Employee has already checked out today.",
                checkOut, workedMinutes, status.name(), autoCheckout ? 1 : 0, id);
    }

    /** index 0 = first break, 1 = second break (only allowed after the first one has ended). */
    public void updateBreakStart(int id, int index, LocalTime t) {
        String sql = index == 0
                ? "UPDATE attendance SET break_start = ? WHERE id = ? AND break_start IS NULL AND check_out_time IS NULL"
                : "UPDATE attendance SET break2_start = ? WHERE id = ? AND break_end IS NOT NULL "
                  + "AND break2_start IS NULL AND check_out_time IS NULL";
        updateOne(sql, "That break cannot be started now.", t, id);
    }

    public void updateBreakEnd(int id, int index, LocalTime t) {
        String sql = index == 0
                ? "UPDATE attendance SET break_end = ? WHERE id = ? AND break_start IS NOT NULL "
                  + "AND break_end IS NULL AND check_out_time IS NULL"
                : "UPDATE attendance SET break2_end = ? WHERE id = ? AND break2_start IS NOT NULL "
                  + "AND break2_end IS NULL AND check_out_time IS NULL";
        updateOne(sql, "There is no active break to end.", t, id);
    }

    public Attendance find(String employeeId, LocalDate date) {
        String sql = "SELECT " + COLS + " FROM attendance WHERE employee_id = ? AND attendance_date = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, employeeId);
            ps.setObject(2, date);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    public List<Attendance> findByDate(LocalDate date) {
        String sql = "SELECT " + COLS + " FROM attendance WHERE attendance_date = ? ORDER BY employee_id";
        return list(sql, date);
    }

    public List<Attendance> findByEmployee(String employeeId) {
        String sql = "SELECT " + COLS + " FROM attendance WHERE employee_id = ? ORDER BY attendance_date";
        return list(sql, employeeId);
    }

    /** Records for a date that were checked in but never checked out (used by the auto-checkout job). */
    public List<Attendance> findOpenByDate(LocalDate date) {
        String sql = "SELECT " + COLS + " FROM attendance WHERE attendance_date = ? "
                + "AND check_in_time IS NOT NULL AND check_out_time IS NULL";
        return list(sql, date);
    }
    /** Open records (checked in, never checked out) from any date before the given date. */
    public List<Attendance> findOpenBefore(LocalDate date) {
        String sql = "SELECT " + COLS + " FROM attendance WHERE attendance_date < ? "
                + "AND check_in_time IS NOT NULL AND check_out_time IS NULL";
        return list(sql, date);
    }

    /**
     * Counts between two dates (inclusive), indexed by Attendance.Status position:
     * [PRESENT, ABSENT, LEAVE, HALF_DAY]. Pass employeeId = null to count all employees.
     */
    public int[] countByStatus(String employeeId, LocalDate from, LocalDate to) {
        String sql = "SELECT status, COUNT(*) FROM attendance WHERE attendance_date BETWEEN ? AND ? "
                + (employeeId != null ? "AND employee_id = ? " : "") + "GROUP BY status";
        int[] counts = new int[Attendance.Status.values().length];
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setObject(1, from);
            ps.setObject(2, to);
            if (employeeId != null) ps.setString(3, employeeId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    counts[Attendance.Status.valueOf(rs.getString(1)).ordinal()] = rs.getInt(2);
            }
            return counts;
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    // ---------- helpers ----------

    /** Runs an UPDATE that must change exactly one row, otherwise throws failMessage. */
    private void updateOne(String sql, String failMessage, Object... params) {
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) ps.setObject(i + 1, params[i]);
            if (ps.executeUpdate() == 0) throw new IllegalStateException(failMessage);
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    private List<Attendance> list(String sql, Object param) {
        List<Attendance> result = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setObject(1, param);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(map(rs));
            }
            return result;
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    private Attendance map(ResultSet rs) throws SQLException {
        Attendance a = new Attendance(
                rs.getInt("id"),
                rs.getString("employee_id"),
                rs.getObject("attendance_date", LocalDate.class),
                rs.getObject("check_in_time", LocalTime.class),
                rs.getObject("check_out_time", LocalTime.class),
                Attendance.Status.valueOf(rs.getString("status")));
        a.setLeaveDetails(rs.getString("leave_type"), rs.getString("reason"));
        a.setBreakStart(0, rs.getObject("break_start", LocalTime.class));
        a.setBreakEnd(0, rs.getObject("break_end", LocalTime.class));
        a.setBreakStart(1, rs.getObject("break2_start", LocalTime.class));
        a.setBreakEnd(1, rs.getObject("break2_end", LocalTime.class));
        int worked = rs.getInt("worked_minutes");
        if (!rs.wasNull()) a.setWorkedMinutes(worked);
        a.setAutoCheckout(rs.getInt("auto_checkout") == 1);
        return a;
    }
}