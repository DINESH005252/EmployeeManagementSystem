package com.smartoffice.dao;

import com.smartoffice.model.SalaryComponent;
import util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class SalaryComponentDAO {

    private static final Logger LOGGER = Logger.getLogger(SalaryComponentDAO.class.getName());

    public List<SalaryComponent> findByStructureId(int structureId) {
        try (Connection c = DBConnection.getConnection()) {
            return findByStructureId(structureId, c);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Database error retrieving salary components for structure ID: " + structureId, e);
            throw new RuntimeException("A database error occurred while retrieving salary components.");
        }
    }

    public List<SalaryComponent> findByStructureId(int structureId, Connection conn) throws SQLException {
        String sql = "SELECT id, salary_structure_id, component_name, component_type, calculation_type, amount, description " +
                     "FROM salary_components WHERE salary_structure_id = ? ORDER BY component_type DESC, id ASC";
        List<SalaryComponent> list = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, structureId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(map(rs));
                }
            }
        }
        return list;
    }

    public void insert(SalaryComponent comp, Connection conn) throws SQLException {
        String sql = "INSERT INTO salary_components (salary_structure_id, component_name, component_type, calculation_type, amount, description) " +
                     "VALUES (?, ?, ?, ?, ?, ?)";
        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, comp.getSalaryStructureId());
            ps.setString(2, comp.getComponentName());
            ps.setString(3, comp.getComponentType());
            ps.setString(4, comp.getCalculationType());
            ps.setBigDecimal(5, comp.getAmount());
            ps.setString(6, comp.getDescription());
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    comp.setId(rs.getInt(1));
                }
            }
        }
    }

    public void deleteByStructureId(int structureId, Connection conn) throws SQLException {
        String sql = "DELETE FROM salary_components WHERE salary_structure_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, structureId);
            ps.executeUpdate();
        }
    }

    private SalaryComponent map(ResultSet rs) throws SQLException {
        String desc = null;
        try { desc = rs.getString("description"); } catch (SQLException ignored) {}
        return new SalaryComponent(
                rs.getInt("id"),
                rs.getInt("salary_structure_id"),
                rs.getString("component_name"),
                rs.getString("component_type"),
                rs.getString("calculation_type"),
                rs.getBigDecimal("amount"),
                desc
        );
    }
}
