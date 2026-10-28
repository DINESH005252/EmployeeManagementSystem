package dao;

import model.Team;
import util.DBConnection;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class TeamDAO {
    private static final String SELECT =
            "SELECT t.id, t.team_name, t.description, t.department, t.manager_id, "
          + "m.name AS manager_name, t.status, t.created_at "
          + "FROM teams t LEFT JOIN managers m ON m.manager_id = t.manager_id ";

    public boolean nameExists(String teamName) {
        String sql = "SELECT COUNT(*) FROM teams WHERE team_name = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, teamName);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    public int insert(String teamName, String description, String department, String managerId, Team.Status status) {
        String sql = "INSERT INTO teams (team_name, description, department, manager_id, status) VALUES (?,?,?,?,?)";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, teamName);
            ps.setString(2, description);
            ps.setString(3, department);
            ps.setString(4, managerId);
            ps.setString(5, status.name());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getInt(1);
            }
        } catch (SQLException e) {
            if (e.getErrorCode() == 1062) throw new IllegalStateException("A team with this name already exists.");
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    public void update(int id, String teamName, String description, String department,
                       String managerId, Team.Status status) {
        String sql = "UPDATE teams SET team_name=?, description=?, department=?, manager_id=?, status=? WHERE id=?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, teamName);
            ps.setString(2, description);
            ps.setString(3, department);
            ps.setString(4, managerId);
            ps.setString(5, status.name());
            ps.setInt(6, id);
            if (ps.executeUpdate() == 0) throw new IllegalArgumentException("Team not found.");
        } catch (SQLException e) {
            if (e.getErrorCode() == 1062) throw new IllegalStateException("A team with this name already exists.");
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    public void delete(int id) {
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement("DELETE FROM teams WHERE id = ?")) {
            ps.setInt(1, id);
            if (ps.executeUpdate() == 0) throw new IllegalArgumentException("Team not found.");
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    public void setStatus(int id, Team.Status status) {
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement("UPDATE teams SET status = ? WHERE id = ?")) {
            ps.setString(1, status.name());
            ps.setInt(2, id);
            if (ps.executeUpdate() == 0) throw new IllegalArgumentException("Team not found.");
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    public Team findById(int id) {
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(SELECT + "WHERE t.id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    public List<Team> findAll() { return list(SELECT + "ORDER BY t.team_name"); }

    public List<Team> findByManager(String managerId) {
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(SELECT + "WHERE t.manager_id = ? ORDER BY t.team_name")) {
            ps.setString(1, managerId);
            try (ResultSet rs = ps.executeQuery()) {
                List<Team> out = new ArrayList<>();
                while (rs.next()) out.add(map(rs));
                return out;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    public List<Team> search(String keyword, String department, String status, String managerId) {
        StringBuilder sql = new StringBuilder(SELECT + "WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        if (keyword != null && !keyword.isEmpty()) {
        	sql.append("AND (t.team_name LIKE ? OR m.name LIKE ? OR t.department LIKE ?) ");
            String k = "%" + keyword + "%";
            params.add(k); params.add(k); params.add(k);
        }
        if (department != null && !department.isEmpty()) { sql.append("AND t.department = ? "); params.add(department); }
        if (status != null && !status.isEmpty())         { sql.append("AND t.status = ? ");      params.add(status); }
        if (managerId != null && !managerId.isEmpty())    { sql.append("AND t.manager_id = ? ");  params.add(managerId); }
        sql.append("ORDER BY t.team_name");

        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                List<Team> out = new ArrayList<>();
                while (rs.next()) out.add(map(rs));
                return out;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    /** Active member count per team id, for the dashboard and listings. */
    public int activeMemberCount(int teamId) {
        String sql = "SELECT COUNT(*) FROM team_members WHERE team_id = ? AND status = 'ACTIVE'";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, teamId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    /** [totalTeams, activeTeams, inactiveTeams, totalActiveMembers] */
    public int[] dashboardTotals() {
        int[] out = new int[4];
        try (Connection c = DBConnection.getConnection();
             Statement st = c.createStatement()) {
            try (ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM teams")) { rs.next(); out[0] = rs.getInt(1); }
            try (ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM teams WHERE status='ACTIVE'")) { rs.next(); out[1] = rs.getInt(1); }
            try (ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM teams WHERE status='INACTIVE'")) { rs.next(); out[2] = rs.getInt(1); }
            try (ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM team_members WHERE status='ACTIVE'")) { rs.next(); out[3] = rs.getInt(1); }
            return out;
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    /** Department -> active team count, for the dashboard. */
    public java.util.Map<String, Integer> departmentCounts() {
        java.util.Map<String, Integer> map = new java.util.LinkedHashMap<>();
        String sql = "SELECT department, COUNT(*) FROM teams WHERE status='ACTIVE' GROUP BY department ORDER BY department";
        try (Connection c = DBConnection.getConnection();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) map.put(rs.getString(1), rs.getInt(2));
            return map;
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    // ---------- helpers ----------

    private List<Team> list(String sql) {
        try (Connection c = DBConnection.getConnection();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            List<Team> out = new ArrayList<>();
            while (rs.next()) out.add(map(rs));
            return out;
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    private Team map(ResultSet rs) throws SQLException {
        Timestamp ts = rs.getTimestamp("created_at");
        return new Team(
                rs.getInt("id"),
                rs.getString("team_name"),
                rs.getString("description"),
                rs.getString("department"),
                rs.getString("manager_id"),
                rs.getString("manager_name"),
                Team.Status.valueOf(rs.getString("status")),
                ts == null ? null : ts.toLocalDateTime());
    }
}