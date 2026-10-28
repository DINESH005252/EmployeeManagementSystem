package com.smartoffice.dao;

import com.smartoffice.model.SalaryComponent;
import com.smartoffice.model.SalaryStructure;
import com.smartoffice.util.PayrollException;
import util.DBConnection;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class SalaryStructureDAO {

    private static final Logger LOGGER = Logger.getLogger(SalaryStructureDAO.class.getName());
    private final SalaryComponentDAO componentDAO = new SalaryComponentDAO();

    public SalaryStructure findById(int id) {
        String sql = "SELECT s.id, s.employee_id, s.basic_salary, s.effective_from, s.effective_to, s.created_at, " +
                     "COALESCE(e.name, m.name, s.employee_id) AS employee_name, " +
                     "COALESCE(e.department, m.department, 'General') AS department " +
                     "FROM salary_structures s " +
                     "LEFT JOIN employees e ON s.employee_id = e.employee_id " +
                     "LEFT JOIN managers m ON s.employee_id = m.manager_id " +
                     "WHERE s.id = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    SalaryStructure s = map(rs);
                    s.setComponents(componentDAO.findByStructureId(s.getId(), c));
                    return s;
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Database error retrieving salary structure by ID: " + id, e);
            throw new RuntimeException("A database error occurred while retrieving the salary structure.");
        }
        return null;
    }

    public SalaryStructure findCurrentByEmployeeId(String employeeId) {
        String sql = "SELECT s.id, s.employee_id, s.basic_salary, s.effective_from, s.effective_to, s.created_at, " +
                     "COALESCE(e.name, m.name, s.employee_id) AS employee_name, " +
                     "COALESCE(e.department, m.department, 'General') AS department " +
                     "FROM salary_structures s " +
                     "LEFT JOIN employees e ON s.employee_id = e.employee_id " +
                     "LEFT JOIN managers m ON s.employee_id = m.manager_id " +
                     "WHERE s.employee_id = ? " +
                     "AND s.effective_from <= CURRENT_DATE " +
                     "AND (s.effective_to IS NULL OR s.effective_to >= CURRENT_DATE) " +
                     "ORDER BY s.effective_from DESC, s.id DESC LIMIT 1";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, employeeId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    SalaryStructure s = map(rs);
                    s.setComponents(componentDAO.findByStructureId(s.getId(), c));
                    return s;
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Database error retrieving current salary structure for employee: " + employeeId, e);
            throw new RuntimeException("A database error occurred while retrieving the salary structure.");
        }
        return null;
    }

    public SalaryStructure findApplicableForPeriod(String employeeId, LocalDate monthStart, LocalDate monthEnd) {
        String sql = "SELECT s.id, s.employee_id, s.basic_salary, s.effective_from, s.effective_to, s.created_at, " +
                     "COALESCE(e.name, m.name, s.employee_id) AS employee_name, " +
                     "COALESCE(e.department, m.department, 'General') AS department " +
                     "FROM salary_structures s " +
                     "LEFT JOIN employees e ON s.employee_id = e.employee_id " +
                     "LEFT JOIN managers m ON s.employee_id = m.manager_id " +
                     "WHERE s.employee_id = ? " +
                     "AND s.effective_from <= ? " +
                     "AND (s.effective_to IS NULL OR s.effective_to >= ?) " +
                     "ORDER BY s.effective_from DESC, s.id DESC LIMIT 1";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, employeeId);
            ps.setObject(2, monthEnd);
            ps.setObject(3, monthStart);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    SalaryStructure s = map(rs);
                    s.setComponents(componentDAO.findByStructureId(s.getId(), c));
                    return s;
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Database error retrieving applicable salary structure for employee: " + employeeId, e);
            throw new RuntimeException("A database error occurred while retrieving the salary structure.");
        }
        return null;
    }

    public List<SalaryStructure> findAllCurrent() {
        String sql = "SELECT s.id, s.employee_id, s.basic_salary, s.effective_from, s.effective_to, s.created_at, " +
                     "COALESCE(e.name, m.name, s.employee_id) AS employee_name, " +
                     "COALESCE(e.department, m.department, 'General') AS department " +
                     "FROM salary_structures s " +
                     "INNER JOIN ( " +
                     "    SELECT employee_id, MAX(effective_from) as max_eff " +
                     "    FROM salary_structures " +
                     "    WHERE effective_from <= CURRENT_DATE AND (effective_to IS NULL OR effective_to >= CURRENT_DATE) " +
                     "    GROUP BY employee_id " +
                     ") latest ON s.employee_id = latest.employee_id AND s.effective_from = latest.max_eff " +
                     "LEFT JOIN employees e ON s.employee_id = e.employee_id " +
                     "LEFT JOIN managers m ON s.employee_id = m.manager_id " +
                     "ORDER BY s.employee_id ASC";
        List<SalaryStructure> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                SalaryStructure s = map(rs);
                s.setComponents(componentDAO.findByStructureId(s.getId(), c));
                list.add(s);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Database error retrieving all current salary structures", e);
            throw new RuntimeException("A database error occurred while retrieving salary structures.");
        }
        return list;
    }

    public List<SalaryStructure> findHistoryByEmployeeId(String employeeId) {
        String sql = "SELECT s.id, s.employee_id, s.basic_salary, s.effective_from, s.effective_to, s.created_at, " +
                     "COALESCE(e.name, m.name, s.employee_id) AS employee_name, " +
                     "COALESCE(e.department, m.department, 'General') AS department " +
                     "FROM salary_structures s " +
                     "LEFT JOIN employees e ON s.employee_id = e.employee_id " +
                     "LEFT JOIN managers m ON s.employee_id = m.manager_id " +
                     "WHERE s.employee_id = ? " +
                     "ORDER BY s.effective_from DESC, s.id DESC";
        List<SalaryStructure> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, employeeId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    SalaryStructure s = map(rs);
                    s.setComponents(componentDAO.findByStructureId(s.getId(), c));
                    list.add(s);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Database error retrieving salary structure history for employee: " + employeeId, e);
            throw new RuntimeException("A database error occurred while retrieving salary structure history.");
        }
        return list;
    }

    public SalaryStructure save(SalaryStructure structure) {
        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            LocalDate effFrom = structure.getEffectiveFrom();
            if (effFrom == null) {
                effFrom = LocalDate.now().withDayOfMonth(1);
                structure.setEffectiveFrom(effFrom);
            }

            // 1. Check if employee already has PROCESSED or PAID payroll on or after new effective_from
            String payrollCheckSql = "SELECT COUNT(*) FROM payroll WHERE employee_id = ? AND status IN ('PROCESSED', 'PAID') " +
                                     "AND (payroll_year > ? OR (payroll_year = ? AND payroll_month >= ?))";
            try (PreparedStatement pcPs = conn.prepareStatement(payrollCheckSql)) {
                pcPs.setString(1, structure.getEmployeeId());
                pcPs.setInt(2, effFrom.getYear());
                pcPs.setInt(3, effFrom.getYear());
                pcPs.setInt(4, effFrom.getMonthValue());
                try (ResultSet rs = pcPs.executeQuery()) {
                    if (rs.next() && rs.getInt(1) > 0) {
                        throw new PayrollException("Cannot create or modify salary structure effective from " + effFrom +
                                ": employee already has finalized or paid payroll records for this period.");
                    }
                }
            }

            // 2. Overlap check: new effective_from must be after latest existing effective_from
            String latestEffSql = "SELECT MAX(effective_from) FROM salary_structures WHERE employee_id = ? AND id != ?";
            try (PreparedStatement lePs = conn.prepareStatement(latestEffSql)) {
                lePs.setString(1, structure.getEmployeeId());
                lePs.setInt(2, structure.getId());
                try (ResultSet rs = lePs.executeQuery()) {
                    if (rs.next() && rs.getDate(1) != null) {
                        LocalDate latestExisting = rs.getDate(1).toLocalDate();
                        if (!effFrom.isAfter(latestExisting)) {
                            throw new PayrollException("New effective date (" + effFrom +
                                    ") must be strictly after the previous effective date (" + latestExisting + ").");
                        }
                    }
                }
            }

            // 3. Close previous open-ended structures to effective_from - 1 day
            String closeSql = "UPDATE salary_structures SET effective_to = ? " +
                              "WHERE employee_id = ? AND (effective_to IS NULL OR effective_to >= ?) AND id != ?";
            try (PreparedStatement closePs = conn.prepareStatement(closeSql)) {
                closePs.setObject(1, effFrom.minusDays(1));
                closePs.setString(2, structure.getEmployeeId());
                closePs.setObject(3, effFrom);
                closePs.setInt(4, structure.getId());
                closePs.executeUpdate();
            }

            // 4. Insert new version (historical retention: never overwrite past records)
            String insertSql = "INSERT INTO salary_structures (employee_id, basic_salary, effective_from, effective_to) " +
                               "VALUES (?, ?, ?, ?)";
            try (PreparedStatement insPs = conn.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {
                insPs.setString(1, structure.getEmployeeId());
                insPs.setBigDecimal(2, structure.getBasicSalary());
                insPs.setObject(3, effFrom);
                insPs.setObject(4, structure.getEffectiveTo());
                insPs.executeUpdate();
                try (ResultSet keys = insPs.getGeneratedKeys()) {
                    if (keys.next()) {
                        structure.setId(keys.getInt(1));
                    }
                }
            }

            // 5. Insert components associated with this new structure version
            if (structure.getComponents() != null) {
                for (SalaryComponent comp : structure.getComponents()) {
                    comp.setSalaryStructureId(structure.getId());
                    componentDAO.insert(comp, conn);
                }
            }

            conn.commit();
            return structure;
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ignored) {}
            }
            LOGGER.log(Level.SEVERE, "Database error saving salary structure for employee: " + structure.getEmployeeId(), e);
            if (e.getErrorCode() == 1062 || "23000".equals(e.getSQLState())) {
                throw new PayrollException("A salary structure with conflicting dates already exists for employee " + structure.getEmployeeId() + ".");
            }
            throw new RuntimeException("A database error occurred while saving the salary structure.");
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (SQLException ignored) {}
            }
        }
    }

    private SalaryStructure map(ResultSet rs) throws SQLException {
        Date effTo = rs.getDate("effective_to");
        return new SalaryStructure(
                rs.getInt("id"),
                rs.getString("employee_id"),
                rs.getString("employee_name"),
                rs.getString("department"),
                rs.getBigDecimal("basic_salary"),
                rs.getDate("effective_from").toLocalDate(),
                effTo != null ? effTo.toLocalDate() : null,
                rs.getTimestamp("created_at")
        );
    }
}
