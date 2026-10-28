package dao;

import model.LeaveRequest;
import util.DBConnection;

import java.sql.*;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class LeaveDAO {
    private static final String SELECT =
            "SELECT l.id, l.employee_id, e.name AS employee_name, l.leave_type, l.from_date, l.to_date, "
          + "l.reason, l.status, l.decided_by, l.decision_reason "
          + "FROM leave_requests l JOIN employees e ON e.employee_id = l.employee_id ";

    public void insert(String employeeId, String type, LocalDate from, LocalDate to, String reason) {
        String sql = "INSERT INTO leave_requests (employee_id, leave_type, from_date, to_date, reason) VALUES (?,?,?,?,?)";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, employeeId);
            ps.setString(2, type);
            ps.setObject(3, from);
            ps.setObject(4, to);
            ps.setString(5, reason);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    /** True if the employee already has a PENDING or APPROVED request touching these dates. */
    public boolean hasOverlap(String employeeId, LocalDate from, LocalDate to) {
        String sql = "SELECT COUNT(*) FROM leave_requests WHERE employee_id = ? "
                + "AND status IN ('PENDING','APPROVED') AND from_date <= ? AND to_date >= ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, employeeId);
            ps.setObject(2, to);
            ps.setObject(3, from);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    public boolean isOnApprovedLeave(String employeeId, LocalDate date) {
        String sql = "SELECT COUNT(*) FROM leave_requests WHERE employee_id = ? "
                + "AND status = 'APPROVED' AND ? BETWEEN from_date AND to_date";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, employeeId);
            ps.setObject(2, date);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    public List<LeaveRequest> findByEmployee(String employeeId) {
        return list(SELECT + "WHERE l.employee_id = ? ORDER BY l.requested_at DESC, l.id DESC", employeeId);
    }

    /** Pending requests first, then the rest, newest first. */
    public List<LeaveRequest> findAll() {
        return list(SELECT + "ORDER BY (l.status = 'PENDING') DESC, l.requested_at DESC, l.id DESC", null);
    }

    /**
     * Approves or rejects a PENDING request. A rejection must include a reason.
     * On approval, a LEAVE attendance record is added for every weekday in the range that has no
     * attendance record yet. Everything happens in one transaction.
     */
    public void decide(int id, boolean approve, String decidedBy, String decisionReason) {
        try (Connection c = DBConnection.getConnection()) {
            c.setAutoCommit(false);
            try {
                String empId = null, type = null, reason = null, status = null;
                LocalDate from = null, to = null;
                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT employee_id, leave_type, from_date, to_date, reason, status "
                      + "FROM leave_requests WHERE id = ? FOR UPDATE")) {
                    ps.setInt(1, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) throw new IllegalArgumentException("Leave request not found.");
                        empId = rs.getString("employee_id");
                        type = rs.getString("leave_type");
                        from = rs.getObject("from_date", LocalDate.class);
                        to = rs.getObject("to_date", LocalDate.class);
                        reason = rs.getString("reason");
                        status = rs.getString("status");
                    }
                }
                if (!"PENDING".equals(status))
                    throw new IllegalStateException("This request has already been " + status.toLowerCase() + ".");

                try (PreparedStatement ps = c.prepareStatement(
                        "UPDATE leave_requests SET status = ?, decided_by = ?, decided_at = NOW(), decision_reason = ? "
                      + "WHERE id = ?")) {
                    ps.setString(1, approve ? "APPROVED" : "REJECTED");
                    ps.setString(2, decidedBy);
                    ps.setString(3, decisionReason);
                    ps.setInt(4, id);
                    ps.executeUpdate();
                }

                if (approve) {
                    try (PreparedStatement ps = c.prepareStatement(
                            "INSERT IGNORE INTO attendance (employee_id, attendance_date, status, leave_type, reason) "
                          + "VALUES (?,?,'LEAVE',?,?)")) {
                        for (LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) {
                            DayOfWeek w = d.getDayOfWeek();
                            if (w == DayOfWeek.SATURDAY || w == DayOfWeek.SUNDAY) continue;
                            ps.setString(1, empId);
                            ps.setObject(2, d);
                            ps.setString(3, type);
                            ps.setString(4, reason);
                            ps.addBatch();
                        }
                        ps.executeBatch();
                    }
                }
                c.commit();
            } catch (RuntimeException | SQLException ex) {
                c.rollback();
                throw ex;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    private List<LeaveRequest> list(String sql, String param) {
        List<LeaveRequest> result = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            if (param != null) ps.setString(1, param);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(map(rs));
            }
            return result;
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    private LeaveRequest map(ResultSet rs) throws SQLException {
        return new LeaveRequest(
                rs.getInt("id"),
                rs.getString("employee_id"),
                rs.getString("employee_name"),
                rs.getString("leave_type"),
                rs.getObject("from_date", LocalDate.class),
                rs.getObject("to_date", LocalDate.class),
                rs.getString("reason"),
                LeaveRequest.Status.valueOf(rs.getString("status")),
                rs.getString("decided_by"),
                rs.getString("decision_reason"));
    }
}