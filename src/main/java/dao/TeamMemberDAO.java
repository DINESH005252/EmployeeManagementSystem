package dao;

import model.TeamMember;
import util.DBConnection;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class TeamMemberDAO {
    private static final String SELECT =
            "SELECT tm.id, tm.team_id, tm.employee_id, e.name AS employee_name, e.department AS designation, "
          + "tm.joined_date, tm.status "
          + "FROM team_members tm JOIN employees e ON e.employee_id = tm.employee_id ";

    public boolean isActiveMember(int teamId, String employeeId) {
        String sql = "SELECT COUNT(*) FROM team_members WHERE team_id = ? AND employee_id = ? AND status = 'ACTIVE'";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, teamId);
            ps.setString(2, employeeId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    public void add(int teamId, String employeeId) {
        if (isActiveMember(teamId, employeeId))
            throw new IllegalStateException("Employee is already a member of this team.");

        try (Connection c = DBConnection.getConnection()) {
            try (PreparedStatement check = c.prepareStatement(
                    "SELECT id FROM team_members WHERE team_id = ? AND employee_id = ?")) {
                check.setInt(1, teamId);
                check.setString(2, employeeId);
                try (ResultSet rs = check.executeQuery()) {
                    if (rs.next()) {
                        try (PreparedStatement reactivate = c.prepareStatement(
                                "UPDATE team_members SET status='ACTIVE', joined_date=CURRENT_DATE WHERE id=?")) {
                            reactivate.setInt(1, rs.getInt("id"));
                            reactivate.executeUpdate();
                        }
                        return;
                    }
                }
            }
            try (PreparedStatement ins = c.prepareStatement(
                    "INSERT INTO team_members (team_id, employee_id) VALUES (?,?)")) {
                ins.setInt(1, teamId);
                ins.setString(2, employeeId);
                ins.executeUpdate();
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    public void remove(int teamId, String employeeId) {
        String sql = "UPDATE team_members SET status='INACTIVE' WHERE team_id=? AND employee_id=? AND status='ACTIVE'";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, teamId);
            ps.setString(2, employeeId);
            if (ps.executeUpdate() == 0)
                throw new IllegalStateException("Employee is not an active member of this team.");
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    /** Removes every membership row for a team (used when the team itself is deleted). */
    public void removeAllForTeam(int teamId) {
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement("DELETE FROM team_members WHERE team_id = ?")) {
            ps.setInt(1, teamId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    public List<TeamMember> findActiveByTeam(int teamId) {
        String sql = SELECT + "WHERE tm.team_id = ? AND tm.status = 'ACTIVE' ORDER BY e.name";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, teamId);
            try (ResultSet rs = ps.executeQuery()) {
                List<TeamMember> out = new ArrayList<>();
                while (rs.next()) out.add(map(rs));
                return out;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    /** Every ACTIVE team id the employee currently belongs to. An employee may be on multiple teams. */
    public List<Integer> findActiveTeamIdsForEmployee(String employeeId) {
        String sql = "SELECT team_id FROM team_members WHERE employee_id = ? AND status = 'ACTIVE' ORDER BY team_id";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, employeeId);
            try (ResultSet rs = ps.executeQuery()) {
                List<Integer> out = new ArrayList<>();
                while (rs.next()) out.add(rs.getInt(1));
                return out;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    private TeamMember map(ResultSet rs) throws SQLException {
        return new TeamMember(
                rs.getInt("id"), rs.getInt("team_id"), rs.getString("employee_id"),
                rs.getString("employee_name"), rs.getString("designation"),
                rs.getObject("joined_date", LocalDate.class),
                TeamMember.Status.valueOf(rs.getString("status")));
    }
}