package dao;

import model.Manager;
import util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ManagerDAO {
    private static final String COLS = "manager_id, name, department, email, status";

    public Manager findById(String id) {
        if (id == null || id.trim().isEmpty()) return null;
        String sql = "SELECT " + COLS + " FROM managers WHERE manager_id = ?";
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

    public List<Manager> findAll() {
        return query("SELECT " + COLS + " FROM managers ORDER BY manager_id");
    }

    public List<Manager> findActive() {
        return query("SELECT " + COLS + " FROM managers WHERE status = 'ACTIVE' ORDER BY name");
    }

    private List<Manager> query(String sql) {
        List<Manager> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(map(rs));
            return list;
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    private Manager map(ResultSet rs) throws SQLException {
        return new Manager(rs.getString("manager_id"), rs.getString("name"), rs.getString("department"),
                rs.getString("email"), Manager.Status.valueOf(rs.getString("status")));
    }
}