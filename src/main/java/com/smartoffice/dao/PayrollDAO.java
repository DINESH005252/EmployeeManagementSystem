package com.smartoffice.dao;

import com.smartoffice.model.AttendanceMetrics;
import com.smartoffice.model.Payroll;
import com.smartoffice.model.PayrollItem;
import com.smartoffice.model.PayrollPayment;
import com.smartoffice.util.PayrollException;
import com.smartoffice.util.PayrollRules;
import util.DBConnection;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.*;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;

public class PayrollDAO {

    private static final Logger LOGGER = Logger.getLogger(PayrollDAO.class.getName());

    public Payroll findById(int id) {
        String sql = "SELECT p.*, " +
                     "COALESCE(e.name, m.name, p.employee_id) AS employee_name, " +
                     "COALESCE(e.department, m.department, 'General') AS department, " +
                     "COALESCE(e.designation, m.designation, '—') AS employee_designation, " +
                     "pay.id AS pay_id, pay.payment_date, pay.payment_method, pay.reference_number, " +
                     "pay.amount_paid, pay.notes AS pay_notes, pay.created_at AS pay_created_at " +
                     "FROM payroll p " +
                     "LEFT JOIN employees e ON p.employee_id = e.employee_id " +
                     "LEFT JOIN managers m ON p.employee_id = m.manager_id " +
                     "LEFT JOIN payroll_payments pay ON p.id = pay.payroll_id " +
                     "WHERE p.id = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Payroll p = map(rs);
                    p.setItems(findItemsByPayrollId(p.getId(), c));
                    if (rs.getObject("pay_id") != null) {
                        p.setPayment(mapPayment(rs));
                    }
                    return p;
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Database error retrieving payroll by ID: " + id, e);
            throw new RuntimeException("A database error occurred while accessing payroll data.");
        }
        return null;
    }

    public Payroll findByEmployeeAndPeriod(String employeeId, int month, int year) {
        String sql = "SELECT p.*, " +
                     "COALESCE(e.name, m.name, p.employee_id) AS employee_name, " +
                     "COALESCE(e.department, m.department, 'General') AS department, " +
                     "COALESCE(e.designation, m.designation, '—') AS employee_designation, " +
                     "pay.id AS pay_id, pay.payment_date, pay.payment_method, pay.reference_number, " +
                     "pay.amount_paid, pay.notes AS pay_notes, pay.created_at AS pay_created_at " +
                     "FROM payroll p " +
                     "LEFT JOIN employees e ON p.employee_id = e.employee_id " +
                     "LEFT JOIN managers m ON p.employee_id = m.manager_id " +
                     "LEFT JOIN payroll_payments pay ON p.id = pay.payroll_id " +
                     "WHERE p.employee_id = ? AND p.payroll_month = ? AND p.payroll_year = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, employeeId);
            ps.setInt(2, month);
            ps.setInt(3, year);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Payroll p = map(rs);
                    p.setItems(findItemsByPayrollId(p.getId(), c));
                    if (rs.getObject("pay_id") != null) {
                        p.setPayment(mapPayment(rs));
                    }
                    return p;
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Database error retrieving payroll for employee " + employeeId + " period " + month + "/" + year, e);
            throw new RuntimeException("A database error occurred while accessing payroll data.");
        }
        return null;
    }

    public List<Payroll> findFinalizedByEmployeeId(String employeeId) {
        String sql = "SELECT p.*, " +
                     "COALESCE(e.name, m.name, p.employee_id) AS employee_name, " +
                     "COALESCE(e.department, m.department, 'General') AS department, " +
                     "COALESCE(e.designation, m.designation, '—') AS employee_designation, " +
                     "pay.id AS pay_id, pay.payment_date, pay.payment_method, pay.reference_number, " +
                     "pay.amount_paid, pay.notes AS pay_notes, pay.created_at AS pay_created_at " +
                     "FROM payroll p " +
                     "LEFT JOIN employees e ON p.employee_id = e.employee_id " +
                     "LEFT JOIN managers m ON p.employee_id = m.manager_id " +
                     "LEFT JOIN payroll_payments pay ON p.id = pay.payroll_id " +
                     "WHERE p.employee_id = ? AND p.status IN ('PROCESSED', 'PAID') " +
                     "ORDER BY p.payroll_year DESC, p.payroll_month DESC";
        List<Payroll> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, employeeId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Payroll p = map(rs);
                    p.setItems(findItemsByPayrollId(p.getId(), c));
                    if (rs.getObject("pay_id") != null) {
                        p.setPayment(mapPayment(rs));
                    }
                    list.add(p);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Database error retrieving finalized payroll for employee: " + employeeId, e);
            throw new RuntimeException("A database error occurred while accessing payroll history.");
        }
        return list;
    }

    public List<Payroll> findAll(Integer month, Integer year, String department, String status, String employeeId) {
        StringBuilder sql = new StringBuilder(
                "SELECT p.*, " +
                "COALESCE(e.name, m.name, p.employee_id) AS employee_name, " +
                "COALESCE(e.department, m.department, 'General') AS department, " +
                "COALESCE(e.designation, m.designation, '—') AS employee_designation, " +
                "pay.id AS pay_id, pay.payment_date, pay.payment_method, pay.reference_number, " +
                "pay.amount_paid, pay.notes AS pay_notes, pay.created_at AS pay_created_at " +
                "FROM payroll p " +
                "LEFT JOIN employees e ON p.employee_id = e.employee_id " +
                "LEFT JOIN managers m ON p.employee_id = m.manager_id " +
                "LEFT JOIN payroll_payments pay ON p.id = pay.payroll_id " +
                "WHERE 1=1 "
        );

        List<Object> params = new ArrayList<>();
        if (month != null) {
            sql.append("AND p.payroll_month = ? ");
            params.add(month);
        }
        if (year != null) {
            sql.append("AND p.payroll_year = ? ");
            params.add(year);
        }
        if (department != null && !department.trim().isEmpty() && !"ALL".equalsIgnoreCase(department)) {
            sql.append("AND (e.department = ? OR m.department = ?) ");
            params.add(department.trim());
            params.add(department.trim());
        }
        if (status != null && !status.trim().isEmpty() && !"ALL".equalsIgnoreCase(status)) {
            sql.append("AND p.status = ? ");
            params.add(status.trim().toUpperCase());
        }
        if (employeeId != null && !employeeId.trim().isEmpty()) {
            sql.append("AND p.employee_id = ? ");
            params.add(employeeId.trim().toUpperCase());
        }

        sql.append("ORDER BY p.payroll_year DESC, p.payroll_month DESC, p.employee_id ASC");

        List<Payroll> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Payroll p = map(rs);
                    p.setItems(findItemsByPayrollId(p.getId(), c));
                    if (rs.getObject("pay_id") != null) {
                        p.setPayment(mapPayment(rs));
                    }
                    list.add(p);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Database error filtering payroll records", e);
            throw new RuntimeException("A database error occurred while accessing payroll records.");
        }
        return list;
    }

    public Payroll save(Payroll payroll) {
        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            // Lock existing row FOR UPDATE to prevent race conditions during recalculations
            String selectSql = "SELECT id, status FROM payroll WHERE employee_id = ? AND payroll_month = ? AND payroll_year = ? FOR UPDATE";
            Integer existingId = null;
            String existingStatus = null;
            try (PreparedStatement selPs = conn.prepareStatement(selectSql)) {
                selPs.setString(1, payroll.getEmployeeId());
                selPs.setInt(2, payroll.getPayrollMonth());
                selPs.setInt(3, payroll.getPayrollYear());
                try (ResultSet rs = selPs.executeQuery()) {
                    if (rs.next()) {
                        existingId = rs.getInt("id");
                        existingStatus = rs.getString("status");
                    }
                }
            }

            if (existingId != null) {
                // Immutable snapshot enforcement: never overwrite PROCESSED or PAID records
                if ("PROCESSED".equalsIgnoreCase(existingStatus) || "PAID".equalsIgnoreCase(existingStatus)) {
                    throw new IllegalStateException("Payroll record #" + existingId + " for " + payroll.getEmployeeId() +
                            " is finalized/paid and cannot be modified.");
                }

                payroll.setId(existingId);
                String updateSql = "UPDATE payroll SET basic_salary = ?, gross_salary = ?, total_deductions = ?, " +
                                   "net_salary = ?, status = ?, processed_by = ?, processed_at = ?, total_working_days = ?, " +
                                   "present_days = ?, paid_leave_days = ?, unpaid_days = ?, loss_of_pay = ?, remarks = ?, " +
                                   "cancelled_by = NULL, cancelled_at = NULL WHERE id = ?";
                try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                    ps.setBigDecimal(1, payroll.getBasicSalary());
                    ps.setBigDecimal(2, payroll.getGrossSalary());
                    ps.setBigDecimal(3, payroll.getTotalDeductions());
                    ps.setBigDecimal(4, payroll.getNetSalary());
                    ps.setString(5, payroll.getStatus());
                    ps.setString(6, payroll.getProcessedBy());
                    ps.setTimestamp(7, payroll.getProcessedAt());
                    ps.setInt(8, payroll.getTotalWorkingDays());
                    ps.setBigDecimal(9, payroll.getPresentDays());
                    ps.setBigDecimal(10, payroll.getPaidLeaveDays());
                    ps.setBigDecimal(11, payroll.getUnpaidDays());
                    ps.setBigDecimal(12, payroll.getLossOfPay());
                    ps.setString(13, payroll.getRemarks());
                    ps.setInt(14, payroll.getId());
                    ps.executeUpdate();
                }

                // Delete old items before re-inserting snapshot
                try (PreparedStatement delPs = conn.prepareStatement("DELETE FROM payroll_items WHERE payroll_id = ?")) {
                    delPs.setInt(1, payroll.getId());
                    delPs.executeUpdate();
                }
            } else {
                String insertSql = "INSERT INTO payroll (employee_id, payroll_month, payroll_year, basic_salary, gross_salary, " +
                                   "total_deductions, net_salary, status, processed_by, processed_at, total_working_days, " +
                                   "present_days, paid_leave_days, unpaid_days, loss_of_pay, remarks) " +
                                   "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                try (PreparedStatement ps = conn.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, payroll.getEmployeeId());
                    ps.setInt(2, payroll.getPayrollMonth());
                    ps.setInt(3, payroll.getPayrollYear());
                    ps.setBigDecimal(4, payroll.getBasicSalary());
                    ps.setBigDecimal(5, payroll.getGrossSalary());
                    ps.setBigDecimal(6, payroll.getTotalDeductions());
                    ps.setBigDecimal(7, payroll.getNetSalary());
                    ps.setString(8, payroll.getStatus());
                    ps.setString(9, payroll.getProcessedBy());
                    ps.setTimestamp(10, payroll.getProcessedAt());
                    ps.setInt(11, payroll.getTotalWorkingDays());
                    ps.setBigDecimal(12, payroll.getPresentDays());
                    ps.setBigDecimal(13, payroll.getPaidLeaveDays());
                    ps.setBigDecimal(14, payroll.getUnpaidDays());
                    ps.setBigDecimal(15, payroll.getLossOfPay());
                    ps.setString(16, payroll.getRemarks());
                    ps.executeUpdate();

                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        if (keys.next()) {
                            payroll.setId(keys.getInt(1));
                        }
                    }
                }
            }

            // Insert snapshot items
            if (payroll.getItems() != null && !payroll.getItems().isEmpty()) {
                String itemSql = "INSERT INTO payroll_items (payroll_id, component_name, component_type, amount) VALUES (?, ?, ?, ?)";
                try (PreparedStatement itemPs = conn.prepareStatement(itemSql)) {
                    for (PayrollItem item : payroll.getItems()) {
                        itemPs.setInt(1, payroll.getId());
                        itemPs.setString(2, item.getComponentName());
                        itemPs.setString(3, item.getComponentType());
                        itemPs.setBigDecimal(4, item.getAmount());
                        itemPs.addBatch();
                    }
                    itemPs.executeBatch();
                }
            }

            conn.commit();
            return payroll;
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ignored) {}
            }
            LOGGER.log(Level.SEVERE, "Database error saving payroll record for employee " + payroll.getEmployeeId() + " period " + payroll.getPayrollMonth() + "/" + payroll.getPayrollYear(), e);
            if (e.getErrorCode() == 1062 || "23000".equals(e.getSQLState())) {
                throw new PayrollException("Payroll already exists for employee " + payroll.getEmployeeId() +
                        " and period " + payroll.getPayrollMonth() + "/" + payroll.getPayrollYear() + ".");
            }
            throw new RuntimeException("A database error occurred while saving the payroll record.");
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (SQLException ignored) {}
            }
        }
    }

    public int updateStatus(int id, String expectedFrom, String newStatus, String actor) {
        String sql = "UPDATE payroll SET status = ?, processed_by = COALESCE(?, processed_by), " +
                     "processed_at = CURRENT_TIMESTAMP WHERE id = ? AND status = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, newStatus);
            ps.setString(2, actor);
            ps.setInt(3, id);
            ps.setString(4, expectedFrom);
            int rows = ps.executeUpdate();
            if (rows == 0) {
                throw new PayrollException("Status transition failed: payroll status was modified by another operation.");
            }
            return rows;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Database error updating payroll status for ID: " + id, e);
            throw new RuntimeException("A database error occurred while updating payroll status.");
        }
    }

    public int cancelPayroll(int id, String reason, String actor) {
        if (reason == null || reason.trim().isEmpty()) {
            throw new PayrollException("A cancellation reason is required.");
        }
        String sql = "UPDATE payroll SET status = 'CANCELLED', cancelled_by = ?, cancelled_at = CURRENT_TIMESTAMP, " +
                     "remarks = CASE WHEN remarks IS NULL OR remarks = '' THEN ? ELSE CONCAT(remarks, ' | Cancellation: ', ?) END " +
                     "WHERE id = ? AND status IN ('DRAFT', 'PROCESSED')";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, actor);
            ps.setString(2, "Cancelled: " + reason.trim());
            ps.setString(3, reason.trim());
            ps.setInt(4, id);
            int rows = ps.executeUpdate();
            if (rows == 0) {
                throw new PayrollException("Cannot cancel record #" + id + ": Record not found or already terminal (PAID / CANCELLED).");
            }
            return rows;
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Database error cancelling payroll ID: " + id, e);
            throw new RuntimeException("A database error occurred while cancelling the payroll record.");
        }
    }

    public AttendanceMetrics getAttendanceMetrics(String employeeId, int month, int year) {
        YearMonth ym = YearMonth.of(year, month);
        LocalDate start = ym.atDay(1);
        LocalDate end = ym.atEndOfMonth();
        LocalDate today = LocalDate.now();
        LocalDate auditEnd = end.isAfter(today) ? today : end;

        Set<DayOfWeek> weeklyOffs = PayrollRules.getWeeklyOffDays();
        Set<String> unpaidLeaveTypes = PayrollRules.getUnpaidLeaveTypes();
        String unmarkedPolicy = PayrollRules.getUnmarkedPolicy();
        double halfDayFraction = PayrollRules.getHalfDayDeductionFraction();

        int totalWorkingDays = 0;
        for (LocalDate d = start; !d.isAfter(end); d = d.plusDays(1)) {
            if (!weeklyOffs.contains(d.getDayOfWeek())) {
                totalWorkingDays++;
            }
        }

        Map<LocalDate, String[]> records = new HashMap<>();
        String sql = "SELECT attendance_date, status, leave_type FROM attendance " +
                     "WHERE employee_id = ? AND attendance_date BETWEEN ? AND ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, employeeId);
            ps.setObject(2, start);
            ps.setObject(3, end);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    LocalDate d = rs.getObject("attendance_date", LocalDate.class);
                    String st = rs.getString("status");
                    String lt = rs.getString("leave_type");
                    records.put(d, new String[]{st, lt});
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Database error computing attendance metrics for employee " + employeeId + " period " + month + "/" + year, e);
            throw new RuntimeException("A database error occurred while computing attendance metrics.");
        }

        double presentCount = 0.0;
        double paidLeaveCount = 0.0;
        double unpaidCount = 0.0;
        double unmarkedCount = 0.0;
        double discrepancyCount = 0.0;

        for (LocalDate d = start; !d.isAfter(auditEnd); d = d.plusDays(1)) {
            boolean isWeeklyOff = weeklyOffs.contains(d.getDayOfWeek());
            String[] rec = records.get(d);

            if (rec != null) {
                String st = rec[0];
                String lt = rec[1];

                if ("PRESENT".equalsIgnoreCase(st)) {
                    presentCount += 1.0;
                } else if ("HALF_DAY".equalsIgnoreCase(st)) {
                    presentCount += (1.0 - halfDayFraction);
                    unpaidCount += halfDayFraction;
                } else if ("LEAVE".equalsIgnoreCase(st)) {
                    if (lt != null && unpaidLeaveTypes.contains(lt.trim().toUpperCase())) {
                        unpaidCount += 1.0;
                    } else {
                        paidLeaveCount += 1.0;
                    }
                } else if ("ABSENT".equalsIgnoreCase(st)) {
                    unpaidCount += 1.0;
                }
            } else {
                if (!isWeeklyOff) {
                    unmarkedCount += 1.0;
                    discrepancyCount += 1.0;
                    if ("UNPAID".equalsIgnoreCase(unmarkedPolicy)) {
                        unpaidCount += 1.0;
                    }
                }
            }
        }

        // Clamp present days <= working days
        if (presentCount > totalWorkingDays) {
            presentCount = totalWorkingDays;
        }

        String notes = discrepancyCount > 0
                ? String.format("%.0f unmarked working day(s) detected up to %s", discrepancyCount, auditEnd)
                : null;

        BigDecimal presentBD = BigDecimal.valueOf(presentCount).setScale(1, RoundingMode.HALF_UP);
        BigDecimal paidLeaveBD = BigDecimal.valueOf(paidLeaveCount).setScale(1, RoundingMode.HALF_UP);
        BigDecimal unpaidBD = BigDecimal.valueOf(unpaidCount).setScale(1, RoundingMode.HALF_UP);
        BigDecimal unmarkedBD = BigDecimal.valueOf(unmarkedCount).setScale(1, RoundingMode.HALF_UP);
        BigDecimal discrepancyBD = BigDecimal.valueOf(discrepancyCount).setScale(1, RoundingMode.HALF_UP);

        return new AttendanceMetrics(
                totalWorkingDays, presentBD, paidLeaveBD, unpaidBD,
                unmarkedBD, discrepancyBD, notes
        );
    }

    public List<String> getDistinctDepartments() {
        String sql = "SELECT DISTINCT department FROM employees WHERE department IS NOT NULL AND department != '' " +
                     "UNION SELECT DISTINCT department FROM managers WHERE department IS NOT NULL AND department != '' " +
                     "ORDER BY department ASC";
        List<String> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(rs.getString(1));
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Database error retrieving distinct departments", e);
            throw new RuntimeException("A database error occurred while accessing department data.");
        }
        return list;
    }

    public static class DeptSummary {
        private String department;
        private int employeeCount;
        private BigDecimal totalGross = BigDecimal.ZERO;
        private BigDecimal totalDeductions = BigDecimal.ZERO;
        private BigDecimal totalNet = BigDecimal.ZERO;

        public String getDepartment() { return department; }
        public void setDepartment(String department) { this.department = department; }
        public int getEmployeeCount() { return employeeCount; }
        public void setEmployeeCount(int employeeCount) { this.employeeCount = employeeCount; }
        public int getCount() { return employeeCount; }
        public void setCount(int count) { this.employeeCount = count; }
        public BigDecimal getTotalGross() { return totalGross; }
        public void setTotalGross(BigDecimal totalGross) { this.totalGross = totalGross; }
        public BigDecimal getTotalDeductions() { return totalDeductions; }
        public void setTotalDeductions(BigDecimal totalDeductions) { this.totalDeductions = totalDeductions; }
        public BigDecimal getTotalNet() { return totalNet; }
        public void setTotalNet(BigDecimal totalNet) { this.totalNet = totalNet; }
    }

    public List<DeptSummary> getDepartmentSummary(Integer month, Integer year) {
        StringBuilder sql = new StringBuilder(
                "SELECT COALESCE(e.department, m.department, 'General') AS dept_name, " +
                "COUNT(p.id) AS emp_count, " +
                "SUM(p.gross_salary) AS total_gross, " +
                "SUM(p.total_deductions) AS total_ded, " +
                "SUM(p.net_salary) AS total_net " +
                "FROM payroll p " +
                "LEFT JOIN employees e ON p.employee_id = e.employee_id " +
                "LEFT JOIN managers m ON p.employee_id = m.manager_id " +
                "WHERE p.status != 'CANCELLED' "
        );
        List<Object> params = new ArrayList<>();
        if (month != null) {
            sql.append("AND p.payroll_month = ? ");
            params.add(month);
        }
        if (year != null) {
            sql.append("AND p.payroll_year = ? ");
            params.add(year);
        }
        sql.append("GROUP BY dept_name ORDER BY dept_name ASC");

        List<DeptSummary> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    DeptSummary s = new DeptSummary();
                    s.setDepartment(rs.getString("dept_name"));
                    s.setEmployeeCount(rs.getInt("emp_count"));
                    s.setTotalGross(rs.getBigDecimal("total_gross") != null ? rs.getBigDecimal("total_gross") : BigDecimal.ZERO);
                    s.setTotalDeductions(rs.getBigDecimal("total_ded") != null ? rs.getBigDecimal("total_ded") : BigDecimal.ZERO);
                    s.setTotalNet(rs.getBigDecimal("total_net") != null ? rs.getBigDecimal("total_net") : BigDecimal.ZERO);
                    list.add(s);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Database error computing department summaries", e);
            throw new RuntimeException("A database error occurred while computing department summary.");
        }
        return list;
    }

    private List<PayrollItem> findItemsByPayrollId(int payrollId, Connection conn) throws SQLException {
        String sql = "SELECT id, payroll_id, component_name, component_type, amount FROM payroll_items WHERE payroll_id = ? ORDER BY id ASC";
        List<PayrollItem> items = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, payrollId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    items.add(new PayrollItem(
                            rs.getInt("id"),
                            rs.getInt("payroll_id"),
                            rs.getString("component_name"),
                            rs.getString("component_type"),
                            rs.getBigDecimal("amount")
                    ));
                }
            }
        }
        return items;
    }

    private Payroll map(ResultSet rs) throws SQLException {
        Payroll p = new Payroll(
                rs.getInt("id"),
                rs.getString("employee_id"),
                rs.getInt("payroll_month"),
                rs.getInt("payroll_year"),
                rs.getBigDecimal("basic_salary"),
                rs.getBigDecimal("gross_salary"),
                rs.getBigDecimal("total_deductions"),
                rs.getBigDecimal("net_salary"),
                rs.getString("status"),
                rs.getString("processed_by"),
                rs.getTimestamp("processed_at"),
                rs.getInt("total_working_days"),
                rs.getBigDecimal("present_days"),
                rs.getBigDecimal("paid_leave_days"),
                rs.getBigDecimal("unpaid_days"),
                rs.getBigDecimal("loss_of_pay"),
                rs.getString("remarks"),
                rs.getString("cancelled_by"),
                rs.getTimestamp("cancelled_at"),
                rs.getTimestamp("created_at")
        );
        p.setEmployeeName(rs.getString("employee_name"));
        p.setDepartment(rs.getString("department"));
        try {
            p.setDesignation(rs.getString("employee_designation"));
        } catch (SQLException ignored) {}
        return p;
    }

    private PayrollPayment mapPayment(ResultSet rs) throws SQLException {
        return new PayrollPayment(
                rs.getInt("pay_id"),
                rs.getInt("id"),
                rs.getObject("payment_date", LocalDate.class),
                rs.getString("payment_method"),
                rs.getString("reference_number"),
                rs.getBigDecimal("amount_paid"),
                rs.getString("pay_notes"),
                rs.getTimestamp("pay_created_at")
        );
    }
}
