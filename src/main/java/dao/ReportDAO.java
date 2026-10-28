package dao;

import model.Employee;
import model.Report;
import util.DBConnection;

import java.sql.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;

/**
 * Data Access Object dedicated to all Report generation operations.
 * Enforces role-based data access (Manager vs. HR/Admin) using PreparedStatements.
 */
public class ReportDAO {

    // ==========================================
    // 1. Employee Report Operations
    // ==========================================

    public List<Report.EmployeeItem> getEmployeeReport(String managerId, String keyword, String department, String status) {
        return getEmployeeReport(managerId, keyword, department, status, "ALL");
    }

    public List<Report.EmployeeItem> getEmployeeReport(String managerId, String keyword, String department, String status, String staffRole) {
        StringBuilder sql = new StringBuilder(
                "SELECT e.employee_id, e.name, e.department, e.status, e.email, " +
                "COALESCE(u.role, 'EMPLOYEE') AS user_role, " +
                "(SELECT t.manager_id FROM team_members tm JOIN teams t ON t.id = tm.team_id WHERE tm.employee_id = e.employee_id LIMIT 1) AS emp_manager_id, " +
                "(SELECT t.team_name FROM team_members tm JOIN teams t ON t.id = tm.team_id WHERE tm.employee_id = e.employee_id LIMIT 1) AS emp_team_name " +
                "FROM employees e " +
                "LEFT JOIN users u ON u.employee_id = e.employee_id " +
                "WHERE 1=1 ");

        List<Object> params = new ArrayList<>();

        if (managerId != null && !managerId.trim().isEmpty()) {
            sql.append("AND (e.employee_id = ? ")
               .append("OR e.employee_id IN (SELECT tm.employee_id FROM team_members tm JOIN teams t ON t.id = tm.team_id WHERE t.manager_id = ?) ")
               .append("OR e.employee_id IN (SELECT tsk.assigned_to FROM tasks tsk WHERE tsk.created_by = ?)) ");
            params.add(managerId.trim());
            params.add(managerId.trim());
            params.add(managerId.trim());
        }

        if (keyword != null && !keyword.trim().isEmpty()) {
            String kw = "%" + keyword.trim().toLowerCase() + "%";
            sql.append("AND (LOWER(e.name) LIKE ? OR LOWER(e.employee_id) LIKE ? OR LOWER(e.email) LIKE ?) ");
            params.add(kw);
            params.add(kw);
            params.add(kw);
        }

        if (department != null && !department.trim().isEmpty() && !"ALL".equalsIgnoreCase(department.trim())) {
            sql.append("AND UPPER(e.department) = ? ");
            params.add(department.trim().toUpperCase());
        }

        if (status != null && !status.trim().isEmpty() && !"ALL".equalsIgnoreCase(status.trim())) {
            sql.append("AND UPPER(e.status) = ? ");
            params.add(status.trim().toUpperCase());
        }

        if (staffRole != null && !staffRole.trim().isEmpty() && !"ALL".equalsIgnoreCase(staffRole.trim())) {
            if ("MANAGER".equalsIgnoreCase(staffRole.trim())) {
                sql.append("AND (e.employee_id LIKE 'MGR%' OR UPPER(COALESCE(u.role, 'EMPLOYEE')) = 'MANAGER') ");
            } else if ("EMPLOYEE".equalsIgnoreCase(staffRole.trim())) {
                sql.append("AND (e.employee_id LIKE 'EMP%' AND UPPER(COALESCE(u.role, 'EMPLOYEE')) != 'MANAGER') ");
            }
        }

        sql.append("ORDER BY e.employee_id ASC");

        List<Report.EmployeeItem> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Report.EmployeeItem item = new Report.EmployeeItem(
                            rs.getString("employee_id"),
                            rs.getString("name"),
                            rs.getString("email"),
                            rs.getString("department"),
                            rs.getString("user_role"),
                            rs.getString("status"),
                            rs.getString("emp_manager_id"),
                            rs.getString("emp_team_name")
                    );
                    list.add(item);
                }
            }
            return list;
        } catch (SQLException e) {
            throw new RuntimeException("Database error in getEmployeeReport: " + e.getMessage(), e);
        }
    }

    public List<Report.ManagerItem> getActiveManagers() {
        List<Report.ManagerItem> list = new ArrayList<>();
        String sql = "SELECT m.manager_id, m.name, m.department, COALESCE(t.team_name, 'Team') as team_name, " +
                     "COUNT(tm.employee_id) as member_count " +
                     "FROM managers m " +
                     "LEFT JOIN teams t ON t.manager_id = m.manager_id " +
                     "LEFT JOIN team_members tm ON tm.team_id = t.id " +
                     "WHERE m.status = 'ACTIVE' " +
                     "GROUP BY m.manager_id, m.name, m.department, t.team_name " +
                     "ORDER BY m.name";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new Report.ManagerItem(
                    rs.getString("manager_id"),
                    rs.getString("name"),
                    rs.getString("department"),
                    rs.getString("team_name"),
                    rs.getInt("member_count")
                ));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error in getActiveManagers: " + e.getMessage(), e);
        }
        return list;
    }

    public Report.EmployeeSummary getEmployeeReportSummary(List<Report.EmployeeItem> items) {
        Report.EmployeeSummary summary = new Report.EmployeeSummary();
        if (items == null) return summary;

        summary.setTotalCount(items.size());
        int active = 0;
        int inactive = 0;
        Map<String, Integer> deptMap = new LinkedHashMap<>();

        for (Report.EmployeeItem emp : items) {
            if (emp.isActive()) active++;
            else inactive++;

            String dept = emp.getDepartment();
            deptMap.put(dept, deptMap.getOrDefault(dept, 0) + 1);
        }

        summary.setActiveCount(active);
        summary.setInactiveCount(inactive);
        summary.setDepartmentCounts(deptMap);
        return summary;
    }

    // ==========================================
    // 2. Attendance Report Operations
    // ==========================================

    public List<Report.AttendanceItem> getAttendanceReport(String managerId, String employeeId,
                                                          LocalDate fromDate, LocalDate toDate,
                                                          String status) {
        return getAttendanceReport(managerId, employeeId, fromDate, toDate, status, "ALL");
    }

    public List<Report.AttendanceItem> getAttendanceReport(String managerId, String employeeId,
                                                          LocalDate fromDate, LocalDate toDate,
                                                          String status, String staffRole) {
        StringBuilder sql = new StringBuilder(
                "SELECT a.id, a.employee_id, e.name AS employee_name, e.department, " +
                "a.attendance_date, a.check_in_time, a.check_out_time, a.status, " +
                "a.worked_minutes, a.leave_type, a.reason " +
                "FROM attendance a " +
                "JOIN employees e ON e.employee_id = a.employee_id " +
                "WHERE 1=1 ");

        List<Object> params = new ArrayList<>();

        if (managerId != null && !managerId.trim().isEmpty()) {
            sql.append("AND (a.employee_id = ? ")
               .append("OR a.employee_id IN (SELECT tm.employee_id FROM team_members tm JOIN teams t ON t.id = tm.team_id WHERE t.manager_id = ?) ")
               .append("OR a.employee_id IN (SELECT tsk.assigned_to FROM tasks tsk WHERE tsk.created_by = ?)) ");
            params.add(managerId.trim());
            params.add(managerId.trim());
            params.add(managerId.trim());
        }

        if (staffRole != null && !staffRole.trim().isEmpty() && !"ALL".equalsIgnoreCase(staffRole.trim())) {
            if ("MANAGER".equalsIgnoreCase(staffRole.trim())) {
                sql.append("AND (a.employee_id LIKE 'MGR%' OR a.employee_id IN (SELECT manager_id FROM managers)) ");
            } else if ("EMPLOYEE".equalsIgnoreCase(staffRole.trim())) {
                sql.append("AND (a.employee_id LIKE 'EMP%' AND a.employee_id NOT IN (SELECT manager_id FROM managers)) ");
            }
        }

        if (employeeId != null && !employeeId.trim().isEmpty() && !"ALL".equalsIgnoreCase(employeeId.trim())) {
            String clean = employeeId.trim();
            String kw = "%" + clean.toLowerCase() + "%";
            sql.append("AND (a.employee_id = ? OR LOWER(a.employee_id) LIKE ? OR LOWER(e.name) LIKE ?) ");
            params.add(clean);
            params.add(kw);
            params.add(kw);
        }

        if (fromDate != null) {
            sql.append("AND a.attendance_date >= ? ");
            params.add(fromDate);
        }

        if (toDate != null) {
            sql.append("AND a.attendance_date <= ? ");
            params.add(toDate);
        }

        if (status != null && !status.trim().isEmpty() && !"ALL".equalsIgnoreCase(status.trim())) {
            sql.append("AND UPPER(a.status) = ? ");
            params.add(status.trim().toUpperCase());
        }

        sql.append("ORDER BY a.attendance_date DESC, e.name ASC");

        List<Report.AttendanceItem> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Report.AttendanceItem item = new Report.AttendanceItem();
                    item.setId(rs.getInt("id"));
                    item.setEmployeeId(rs.getString("employee_id"));
                    item.setEmployeeName(rs.getString("employee_name"));
                    item.setDepartment(rs.getString("department"));
                    item.setDate(rs.getObject("attendance_date", LocalDate.class));
                    Time cin = rs.getTime("check_in_time");
                    item.setCheckInTime(cin != null ? cin.toLocalTime() : null);
                    Time cout = rs.getTime("check_out_time");
                    item.setCheckOutTime(cout != null ? cout.toLocalTime() : null);
                    item.setStatus(rs.getString("status"));
                    int wm = rs.getInt("worked_minutes");
                    item.setWorkedMinutes(rs.wasNull() ? null : wm);
                    item.setLeaveType(rs.getString("leave_type"));
                    item.setReason(rs.getString("reason"));
                    list.add(item);
                }
            }
            return list;
        } catch (SQLException e) {
            throw new RuntimeException("Database error in getAttendanceReport: " + e.getMessage(), e);
        }
    }

    public Report.AttendanceSummary getAttendanceReportSummary(List<Report.AttendanceItem> items) {
        Report.AttendanceSummary summary = new Report.AttendanceSummary();
        if (items == null) return summary;

        summary.setTotalCount(items.size());
        int present = 0, absent = 0, halfDay = 0, leave = 0, late = 0;

        for (Report.AttendanceItem a : items) {
            String st = a.getStatus();
            if ("PRESENT".equalsIgnoreCase(st)) present++;
            else if ("ABSENT".equalsIgnoreCase(st)) absent++;
            else if ("HALF_DAY".equalsIgnoreCase(st)) halfDay++;
            else if ("LEAVE".equalsIgnoreCase(st)) leave++;

            if (a.isLate()) late++;
        }

        summary.setPresentCount(present);
        summary.setAbsentCount(absent);
        summary.setHalfDayCount(halfDay);
        summary.setLeaveCount(leave);
        summary.setLateCount(late);
        return summary;
    }

    // ==========================================
    // 3. Leave Report Operations
    // ==========================================

    public List<Report.LeaveItem> getLeaveReport(String managerId, String employeeId,
                                                LocalDate fromDate, LocalDate toDate,
                                                String status) {
        return getLeaveReport(managerId, employeeId, fromDate, toDate, status, "ALL");
    }

    public List<Report.LeaveItem> getLeaveReport(String managerId, String employeeId,
                                                LocalDate fromDate, LocalDate toDate,
                                                String status, String staffRole) {
        StringBuilder sql = new StringBuilder(
                "SELECT l.id, l.employee_id, e.name AS employee_name, e.department, " +
                "l.leave_type, l.from_date, l.to_date, l.reason, l.status, " +
                "l.decided_by, l.decided_at, l.decision_reason " +
                "FROM leave_requests l " +
                "JOIN employees e ON e.employee_id = l.employee_id " +
                "WHERE 1=1 ");

        List<Object> params = new ArrayList<>();

        if (managerId != null && !managerId.trim().isEmpty()) {
            sql.append("AND (l.employee_id = ? ")
               .append("OR l.employee_id IN (SELECT tm.employee_id FROM team_members tm JOIN teams t ON t.id = tm.team_id WHERE t.manager_id = ?) ")
               .append("OR l.employee_id IN (SELECT tsk.assigned_to FROM tasks tsk WHERE tsk.created_by = ?)) ");
            params.add(managerId.trim());
            params.add(managerId.trim());
            params.add(managerId.trim());
        }

        if (staffRole != null && !staffRole.trim().isEmpty() && !"ALL".equalsIgnoreCase(staffRole.trim())) {
            if ("MANAGER".equalsIgnoreCase(staffRole.trim())) {
                sql.append("AND (l.employee_id LIKE 'MGR%' OR l.employee_id IN (SELECT manager_id FROM managers)) ");
            } else if ("EMPLOYEE".equalsIgnoreCase(staffRole.trim())) {
                sql.append("AND (l.employee_id LIKE 'EMP%' AND l.employee_id NOT IN (SELECT manager_id FROM managers)) ");
            }
        }

        if (employeeId != null && !employeeId.trim().isEmpty() && !"ALL".equalsIgnoreCase(employeeId.trim())) {
            String clean = employeeId.trim();
            String kw = "%" + clean.toLowerCase() + "%";
            sql.append("AND (l.employee_id = ? OR LOWER(l.employee_id) LIKE ? OR LOWER(e.name) LIKE ?) ");
            params.add(clean);
            params.add(kw);
            params.add(kw);
        }

        if (fromDate != null) {
            sql.append("AND l.to_date >= ? ");
            params.add(fromDate);
        }

        if (toDate != null) {
            sql.append("AND l.from_date <= ? ");
            params.add(toDate);
        }

        if (status != null && !status.trim().isEmpty() && !"ALL".equalsIgnoreCase(status.trim())) {
            sql.append("AND UPPER(l.status) = ? ");
            params.add(status.trim().toUpperCase());
        }

        sql.append("ORDER BY l.from_date DESC, l.id DESC");

        List<Report.LeaveItem> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Report.LeaveItem item = new Report.LeaveItem();
                    item.setId(rs.getInt("id"));
                    item.setEmployeeId(rs.getString("employee_id"));
                    item.setEmployeeName(rs.getString("employee_name"));
                    item.setDepartment(rs.getString("department"));
                    item.setLeaveType(rs.getString("leave_type"));
                    LocalDate fd = rs.getObject("from_date", LocalDate.class);
                    LocalDate td = rs.getObject("to_date", LocalDate.class);
                    item.setFromDate(fd);
                    item.setToDate(td);
                    item.setWorkingDays(countWorkingDays(fd, td));
                    item.setReason(rs.getString("reason"));
                    item.setStatus(rs.getString("status"));
                    item.setDecidedBy(rs.getString("decided_by"));
                    Timestamp dat = rs.getTimestamp("decided_at");
                    item.setDecidedAt(dat != null ? dat.toLocalDateTime() : null);
                    item.setDecisionReason(rs.getString("decision_reason"));
                    list.add(item);
                }
            }
            return list;
        } catch (SQLException e) {
            throw new RuntimeException("Database error in getLeaveReport: " + e.getMessage(), e);
        }
    }

    private int countWorkingDays(LocalDate from, LocalDate to) {
        if (from == null || to == null) return 0;
        int n = 0;
        for (LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) {
            java.time.DayOfWeek w = d.getDayOfWeek();
            if (w != java.time.DayOfWeek.SATURDAY && w != java.time.DayOfWeek.SUNDAY) n++;
        }
        return n;
    }

    public Report.LeaveSummary getLeaveReportSummary(List<Report.LeaveItem> items) {
        Report.LeaveSummary summary = new Report.LeaveSummary();
        if (items == null) return summary;

        summary.setTotalCount(items.size());
        int pending = 0, approved = 0, rejected = 0, cancelled = 0;

        for (Report.LeaveItem l : items) {
            String st = l.getStatus();
            if ("APPROVED".equalsIgnoreCase(st)) approved++;
            else if ("REJECTED".equalsIgnoreCase(st)) rejected++;
            else if ("CANCELLED".equalsIgnoreCase(st)) cancelled++;
            else pending++;
        }

        summary.setPendingCount(pending);
        summary.setApprovedCount(approved);
        summary.setRejectedCount(rejected);
        summary.setCancelledCount(cancelled);
        return summary;
    }

    // ==========================================
    // 4. Task Report Operations
    // ==========================================

    public List<Report.TaskItem> getTaskReport(String managerId, String employeeId,
                                              String status, String priority,
                                              String department,
                                              LocalDate fromDate, LocalDate toDate) {
        return getTaskReport(managerId, employeeId, status, priority, department, fromDate, toDate, "ALL");
    }

    public List<Report.TaskItem> getTaskReport(String managerId, String employeeId,
                                              String status, String priority,
                                              String department,
                                              LocalDate fromDate, LocalDate toDate,
                                              String staffRole) {
        StringBuilder sql = new StringBuilder(
                "SELECT t.id, t.task_title, t.description, t.assigned_to, " +
                "COALESCE(e.name, t.assigned_to) AS assigned_to_name, " +
                "t.created_by, COALESCE(t.department, e.department, 'GENERAL') AS department, " +
                "t.priority, t.start_date, t.due_date, t.status, t.rating, t.feedback " +
                "FROM tasks t " +
                "LEFT JOIN employees e ON e.employee_id = t.assigned_to " +
                "WHERE 1=1 ");

        List<Object> params = new ArrayList<>();

        if (managerId != null && !managerId.trim().isEmpty()) {
            sql.append("AND (t.created_by = ? OR t.assigned_to = ? OR t.assigned_to IN (SELECT tm.employee_id FROM team_members tm JOIN teams tm_t ON tm_t.id = tm.team_id WHERE tm_t.manager_id = ?)) ");
            params.add(managerId.trim());
            params.add(managerId.trim());
            params.add(managerId.trim());
        }

        if (staffRole != null && !staffRole.trim().isEmpty() && !"ALL".equalsIgnoreCase(staffRole.trim())) {
            if ("MANAGER".equalsIgnoreCase(staffRole.trim())) {
                sql.append("AND (t.assigned_to LIKE 'MGR%' OR t.created_by LIKE 'MGR%' OR t.assigned_to IN (SELECT manager_id FROM managers)) ");
            } else if ("EMPLOYEE".equalsIgnoreCase(staffRole.trim())) {
                sql.append("AND (t.assigned_to LIKE 'EMP%' AND t.assigned_to NOT IN (SELECT manager_id FROM managers)) ");
            }
        }

        if (employeeId != null && !employeeId.trim().isEmpty() && !"ALL".equalsIgnoreCase(employeeId.trim())) {
            String clean = employeeId.trim();
            String kw = "%" + clean.toLowerCase() + "%";
            sql.append("AND (t.assigned_to = ? OR LOWER(t.assigned_to) LIKE ? OR LOWER(e.name) LIKE ?) ");
            params.add(clean);
            params.add(kw);
            params.add(kw);
        }

        if (status != null && !status.trim().isEmpty() && !"ALL".equalsIgnoreCase(status.trim())) {
            sql.append("AND UPPER(t.status) = ? ");
            params.add(status.trim().toUpperCase());
        }

        if (priority != null && !priority.trim().isEmpty() && !"ALL".equalsIgnoreCase(priority.trim())) {
            sql.append("AND UPPER(t.priority) = ? ");
            params.add(priority.trim().toUpperCase());
        }

        if (department != null && !department.trim().isEmpty() && !"ALL".equalsIgnoreCase(department.trim())) {
            sql.append("AND UPPER(t.department) = ? ");
            params.add(department.trim().toUpperCase());
        }

        if (fromDate != null) {
            sql.append("AND t.due_date >= ? ");
            params.add(fromDate);
        }

        if (toDate != null) {
            sql.append("AND t.due_date <= ? ");
            params.add(toDate);
        }

        sql.append("ORDER BY t.due_date DESC, t.id DESC");

        List<Report.TaskItem> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Report.TaskItem item = new Report.TaskItem();
                    item.setId(rs.getInt("id"));
                    item.setTaskTitle(rs.getString("task_title"));
                    item.setDescription(rs.getString("description"));
                    item.setAssignedTo(rs.getString("assigned_to"));
                    item.setAssignedToName(rs.getString("assigned_to_name"));
                    item.setCreatedBy(rs.getString("created_by"));
                    item.setDepartment(rs.getString("department"));
                    item.setPriority(rs.getString("priority"));
                    item.setStartDate(rs.getObject("start_date", LocalDate.class));
                    item.setDueDate(rs.getObject("due_date", LocalDate.class));
                    item.setStatus(rs.getString("status"));
                    int rt = rs.getInt("rating");
                    item.setRating(rs.wasNull() ? null : rt);
                    item.setFeedback(rs.getString("feedback"));
                    list.add(item);
                }
            }
            return list;
        } catch (SQLException e) {
            throw new RuntimeException("Database error in getTaskReport: " + e.getMessage(), e);
        }
    }

    public Report.TaskSummary getTaskReportSummary(List<Report.TaskItem> items) {
        Report.TaskSummary summary = new Report.TaskSummary();
        if (items == null) return summary;

        summary.setTotalCount(items.size());
        int assigned = 0, inProgress = 0, onHold = 0, completed = 0, cancelled = 0;

        for (Report.TaskItem t : items) {
            String st = t.getStatus();
            if ("ASSIGNED".equalsIgnoreCase(st)) assigned++;
            else if ("IN_PROGRESS".equalsIgnoreCase(st) || "IN PROGRESS".equalsIgnoreCase(st)) inProgress++;
            else if ("ON_HOLD".equalsIgnoreCase(st) || "ON HOLD".equalsIgnoreCase(st)) onHold++;
            else if ("COMPLETED".equalsIgnoreCase(st)) completed++;
            else if ("CANCELLED".equalsIgnoreCase(st)) cancelled++;
        }

        summary.setAssignedCount(assigned);
        summary.setInProgressCount(inProgress);
        summary.setOnHoldCount(onHold);
        summary.setCompletedCount(completed);
        summary.setCancelledCount(cancelled);

        int total = items.size();
        summary.setCompletionRate(total > 0 ? (int) Math.round(((double) completed / total) * 100) : 0);
        return summary;
    }

    // ==========================================
    // 5. Reports Dashboard Overview
    // ==========================================

    public Report.DashboardSummary getDashboardSummary(String managerId) {
        Report.DashboardSummary ds = new Report.DashboardSummary();
        try (Connection c = DBConnection.getConnection()) {
            // Employees count
            String empSql = (managerId != null && !managerId.trim().isEmpty())
                    ? "SELECT COUNT(*), SUM(CASE WHEN status='ACTIVE' THEN 1 ELSE 0 END) FROM employees " +
                      "WHERE employee_id IN (SELECT tm.employee_id FROM team_members tm JOIN teams t ON t.id = tm.team_id WHERE t.manager_id = ?) " +
                      "OR employee_id IN (SELECT tsk.assigned_to FROM tasks tsk WHERE tsk.created_by = ?)"
                    : "SELECT COUNT(*), SUM(CASE WHEN status='ACTIVE' THEN 1 ELSE 0 END) FROM employees";
            try (PreparedStatement ps = c.prepareStatement(empSql)) {
                if (managerId != null && !managerId.trim().isEmpty()) {
                    ps.setString(1, managerId.trim());
                    ps.setString(2, managerId.trim());
                }
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        ds.setTotalEmployees(rs.getInt(1));
                        ds.setActiveEmployees(rs.getInt(2));
                    }
                }
            }

            // Today's attendance
            String attSql = (managerId != null && !managerId.trim().isEmpty())
                    ? "SELECT COUNT(*) FROM attendance a WHERE a.attendance_date = CURRENT_DATE " +
                      "AND (a.employee_id IN (SELECT tm.employee_id FROM team_members tm JOIN teams t ON t.id = tm.team_id WHERE t.manager_id = ?) " +
                      "OR a.employee_id IN (SELECT tsk.assigned_to FROM tasks tsk WHERE tsk.created_by = ?))"
                    : "SELECT COUNT(*) FROM attendance WHERE attendance_date = CURRENT_DATE";
            try (PreparedStatement ps = c.prepareStatement(attSql)) {
                if (managerId != null && !managerId.trim().isEmpty()) {
                    ps.setString(1, managerId.trim());
                    ps.setString(2, managerId.trim());
                }
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) ds.setTodayAttendanceCount(rs.getInt(1));
                }
            }

            // Pending leaves
            String leaveSql = (managerId != null && !managerId.trim().isEmpty())
                    ? "SELECT COUNT(*) FROM leave_requests l WHERE l.status = 'PENDING' " +
                      "AND (l.employee_id IN (SELECT tm.employee_id FROM team_members tm JOIN teams t ON t.id = tm.team_id WHERE t.manager_id = ?) " +
                      "OR l.employee_id IN (SELECT tsk.assigned_to FROM tasks tsk WHERE tsk.created_by = ?))"
                    : "SELECT COUNT(*) FROM leave_requests WHERE status = 'PENDING'";
            try (PreparedStatement ps = c.prepareStatement(leaveSql)) {
                if (managerId != null && !managerId.trim().isEmpty()) {
                    ps.setString(1, managerId.trim());
                    ps.setString(2, managerId.trim());
                }
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) ds.setPendingLeavesCount(rs.getInt(1));
                }
            }

            // Tasks counts
            String taskSql = (managerId != null && !managerId.trim().isEmpty())
                    ? "SELECT COUNT(*), SUM(CASE WHEN status IN ('ASSIGNED','IN_PROGRESS','ON_HOLD') THEN 1 ELSE 0 END) FROM tasks " +
                      "WHERE created_by = ? OR assigned_to IN (SELECT tm.employee_id FROM team_members tm JOIN teams t ON t.id = tm.team_id WHERE t.manager_id = ?)"
                    : "SELECT COUNT(*), SUM(CASE WHEN status IN ('ASSIGNED','IN_PROGRESS','ON_HOLD') THEN 1 ELSE 0 END) FROM tasks";
            try (PreparedStatement ps = c.prepareStatement(taskSql)) {
                if (managerId != null && !managerId.trim().isEmpty()) {
                    ps.setString(1, managerId.trim());
                    ps.setString(2, managerId.trim());
                }
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        ds.setTotalTasksCount(rs.getInt(1));
                        ds.setActiveTasksCount(rs.getInt(2));
                    }
                }
            }

            return ds;
        } catch (SQLException e) {
            throw new RuntimeException("Database error in getDashboardSummary: " + e.getMessage(), e);
        }
    }

    // ==========================================
    // 6. Filter Helper Methods
    // ==========================================

    public List<String> getDistinctDepartments() {
        List<String> list = new ArrayList<>();
        String sql = "SELECT DISTINCT UPPER(TRIM(department)) AS dept FROM employees " +
                     "WHERE department IS NOT NULL AND TRIM(department) <> '' ORDER BY dept";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(rs.getString("dept"));
            }
            return list;
        } catch (SQLException e) {
            throw new RuntimeException("Database error in getDistinctDepartments: " + e.getMessage(), e);
        }
    }

    public List<Employee> getAccessibleEmployees(String managerId) {
        List<Employee> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder("SELECT employee_id, name, department, status FROM employees WHERE 1=1 ");
        List<Object> params = new ArrayList<>();

        if (managerId != null && !managerId.trim().isEmpty()) {
            sql.append("AND (employee_id = ? ")
               .append("OR employee_id IN (SELECT tm.employee_id FROM team_members tm JOIN teams t ON t.id = tm.team_id WHERE t.manager_id = ?) ")
               .append("OR employee_id IN (SELECT tsk.assigned_to FROM tasks tsk WHERE tsk.created_by = ?)) ");
            params.add(managerId.trim());
            params.add(managerId.trim());
            params.add(managerId.trim());
        }

        sql.append("ORDER BY name ASC");

        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Employee e = new Employee(
                            rs.getString("employee_id"),
                            rs.getString("name"),
                            rs.getString("department"),
                            Employee.Status.valueOf(rs.getString("status"))
                    );
                    list.add(e);
                }
            }
            return list;
        } catch (SQLException e) {
            throw new RuntimeException("Database error in getAccessibleEmployees: " + e.getMessage(), e);
        }
    }
}
