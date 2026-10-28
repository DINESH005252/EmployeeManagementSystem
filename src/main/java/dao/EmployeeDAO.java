package dao;

import model.Employee;
import util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class EmployeeDAO {
    private static final String COLS = "employee_id, name, department, status, designation";

    public Employee findById(String id) {
        if (id == null || id.trim().isEmpty()) return null;
        String sql = "SELECT " + COLS + " FROM employees WHERE employee_id = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, id.trim().toUpperCase());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    public List<Employee> findAll() {
        return query("SELECT " + COLS + " FROM employees ORDER BY employee_id");
    }

    public List<Employee> findActive() {
        return query("SELECT " + COLS + " FROM employees WHERE status = 'ACTIVE' ORDER BY employee_id");
    }

    private List<Employee> query(String sql) {
        List<Employee> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(map(rs));
            return list;
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    private Employee map(ResultSet rs) throws SQLException {
        String desig = "—";
        try {
            desig = rs.getString("designation");
            if (desig == null || desig.trim().isEmpty()) desig = "—";
        } catch (SQLException ignored) {}
        return new Employee(
                rs.getString("employee_id"),
                rs.getString("name"),
                rs.getString("department"),
                desig,
                Employee.Status.valueOf(rs.getString("status"))
        );
    }
}
