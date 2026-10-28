package dao;

import model.User;
import util.DBConnection;

import java.sql.*;

public class UserDAO {

    /** Used only for the fixed HR/admin account. */
    public User findByUsername(String username) {
        String sql = "SELECT id, username, password_hash, role, employee_id, manager_id, must_change_password FROM users WHERE username = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    /** Login lookup: matches the username, an employee's email/ID, or a manager's email/ID. */
    public User findByIdentifier(String identifier) {
        String sql = "SELECT u.id, u.username, u.password_hash, u.role, u.employee_id, u.manager_id, u.must_change_password "
                + "FROM users u "
                + "LEFT JOIN employees e ON e.employee_id = u.employee_id "
                + "LEFT JOIN managers  m ON m.manager_id  = u.manager_id "
                + "WHERE u.username = ? OR e.email = ? OR m.email = ? OR e.employee_id = ? OR m.manager_id = ? LIMIT 1";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, identifier);
            ps.setString(2, identifier);
            ps.setString(3, identifier);
            ps.setString(4, identifier);
            ps.setString(5, identifier);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    public boolean exists(String username) {
        return findByUsername(username) != null;
    }

    public void insert(String username, String passwordHash, User.Role role, String employeeId) {
        String sql = "INSERT INTO users (username, password_hash, role, employee_id) VALUES (?,?,?,?)";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, passwordHash);
            ps.setString(3, role.name());
            ps.setString(4, employeeId);          // null for HR
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    /** Self sign-up: generates a new Employee ID, creates the employee + login together. */
    public String registerEmployee(String name, String department, String email, String passwordHash) {
        try (Connection c = DBConnection.getConnection()) {
            c.setAutoCommit(false);
            try {
                String id = null;
                for (int attempt = 0; attempt < 5 && id == null; attempt++) {
                    String candidate = nextId(c, "employees", "employee_id", "EMP");
                    try (PreparedStatement emp = c.prepareStatement(
                            "INSERT INTO employees (employee_id, name, department, status, email) "
                          + "VALUES (?,?,?,'ACTIVE',?)")) {
                        emp.setString(1, candidate);
                        emp.setString(2, name);
                        emp.setString(3, department);
                        emp.setString(4, email);
                        emp.executeUpdate();
                        id = candidate;
                    } catch (SQLException dup) {
                        if (dup.getErrorCode() != 1062) throw dup;
                        if ((dup.getMessage() == null ? "" : dup.getMessage()).contains("email")) throw dup;
                    }
                }
                if (id == null) throw new IllegalStateException("Could not generate an Employee ID. Please try again.");

                try (PreparedStatement usr = c.prepareStatement(
                        "INSERT INTO users (username, password_hash, role, employee_id) VALUES (?,?,'EMPLOYEE',?)")) {
                    usr.setString(1, id);
                    usr.setString(2, passwordHash);
                    usr.setString(3, id);
                    usr.setString(4, id);
                    usr.executeUpdate();
                }
                c.commit();
                return id;
            } catch (SQLException ex) {
                c.rollback();
                if (ex.getErrorCode() == 1062) throw new IllegalStateException("This email is already registered.");
                throw ex;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    /** HR-created EMPLOYEE account (direct, HR sets the password). */
    public String adminRegisterEmployee(String name, String department, String email, String passwordHash) {
        try (Connection c = DBConnection.getConnection()) {
            c.setAutoCommit(false);
            try {
                String id = null;
                for (int attempt = 0; attempt < 5 && id == null; attempt++) {
                    String candidate = nextId(c, "employees", "employee_id", "EMP");
                    try (PreparedStatement emp = c.prepareStatement(
                            "INSERT INTO employees (employee_id, name, department, status, email) "
                          + "VALUES (?,?,?,'ACTIVE',?)")) {
                        emp.setString(1, candidate);
                        emp.setString(2, name);
                        emp.setString(3, department);
                        emp.setString(4, email);
                        emp.executeUpdate();
                        id = candidate;
                    } catch (SQLException dup) {
                        if (dup.getErrorCode() != 1062) throw dup;
                        if ((dup.getMessage() == null ? "" : dup.getMessage()).contains("email")) throw dup;
                    }
                }
                if (id == null) throw new IllegalStateException("Could not generate an Employee ID. Please try again.");

                try (PreparedStatement usr = c.prepareStatement(
                        "INSERT INTO users (username, password_hash, role, employee_id, must_change_password) VALUES (?,?,'EMPLOYEE',?,TRUE)")) {
                    usr.setString(1, id);
                    usr.setString(2, passwordHash);
                    usr.setString(3, id);
                    usr.setString(4, id);
                    usr.executeUpdate();
                }
                c.commit();
                return id;
            } catch (SQLException ex) {
                c.rollback();
                if (ex.getErrorCode() == 1062) throw new IllegalStateException("This email is already registered.");
                throw ex;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    /**
     * HR-created MANAGER account. A manager is its own entity — this does NOT create a row in
     * employees. Returns the generated Manager ID (e.g. MGR101).
     */
    public String adminRegisterManager(String name, String department, String email, String passwordHash) {
        try (Connection c = DBConnection.getConnection()) {
            c.setAutoCommit(false);
            try {
                String id = null;
                for (int attempt = 0; attempt < 5 && id == null; attempt++) {
                    String candidate = nextId(c, "managers", "manager_id", "MGR");
                    try (PreparedStatement mgr = c.prepareStatement(
                            "INSERT INTO managers (manager_id, name, department, status, email) "
                          + "VALUES (?,?,?,'ACTIVE',?)")) {
                        mgr.setString(1, candidate);
                        mgr.setString(2, name);
                        mgr.setString(3, department);
                        mgr.setString(4, email);
                        mgr.executeUpdate();
                        id = candidate;
                    } catch (SQLException dup) {
                        if (dup.getErrorCode() != 1062) throw dup;
                        if ((dup.getMessage() == null ? "" : dup.getMessage()).contains("email")) throw dup;
                    }
                }
                if (id == null) throw new IllegalStateException("Could not generate a Manager ID. Please try again.");

                try (PreparedStatement emp = c.prepareStatement(
                        "INSERT INTO employees (employee_id, name, department, status, email) "
                      + "VALUES (?,?,?,'ACTIVE',?) "
                      + "ON DUPLICATE KEY UPDATE name=VALUES(name), department=VALUES(department), email=VALUES(email), status='ACTIVE'")) {
                    emp.setString(1, id);
                    emp.setString(2, name);
                    emp.setString(3, department);
                    emp.setString(4, email);
                    emp.executeUpdate();
                }

                try (PreparedStatement usr = c.prepareStatement(
                        "INSERT INTO users (username, password_hash, role, manager_id, employee_id, must_change_password) VALUES (?,?,'MANAGER',?,?,TRUE)")) {
                    usr.setString(1, id);
                    usr.setString(2, passwordHash);
                    usr.setString(3, id);
                    usr.setString(4, id);
                    usr.executeUpdate();
                }
                c.commit();
                return id;
            } catch (SQLException ex) {
                c.rollback();
                if (ex.getErrorCode() == 1062) throw new IllegalStateException("This email is already registered.");
                throw ex;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    public boolean updatePassword(String username, String newPasswordHash) {
        String sql = "UPDATE users SET password_hash = ?, must_change_password = FALSE WHERE username = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, newPasswordHash);
            ps.setString(2, username);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Database error updating password: " + e.getMessage(), e);
        }
    }

    public String findEmailByIdentifier(String identifier) {
        if (identifier == null || identifier.trim().isEmpty()) return null;
        String sql = "SELECT COALESCE(e.email, m.email) AS email "
                   + "FROM users u "
                   + "LEFT JOIN employees e ON e.employee_id = u.employee_id "
                   + "LEFT JOIN managers  m ON m.manager_id  = u.manager_id "
                   + "WHERE u.username = ? OR e.email = ? OR m.email = ? OR e.employee_id = ? OR m.manager_id = ? "
                   + "LIMIT 1";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            String clean = identifier.trim();
            ps.setString(1, clean);
            ps.setString(2, clean);
            ps.setString(3, clean);
            ps.setString(4, clean);
            ps.setString(5, clean);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("email");
                }
            }
        } catch (SQLException e) {
            System.err.println("Error finding email by identifier: " + e.getMessage());
        }
        return null;
    }

    public String findUsernameByIdentifier(String identifier) {
        if (identifier == null || identifier.trim().isEmpty()) return null;
        String sql = "SELECT u.username "
                   + "FROM users u "
                   + "LEFT JOIN employees e ON e.employee_id = u.employee_id "
                   + "LEFT JOIN managers  m ON m.manager_id  = u.manager_id "
                   + "WHERE u.username = ? OR e.email = ? OR m.email = ? OR e.employee_id = ? OR m.manager_id = ? "
                   + "LIMIT 1";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            String clean = identifier.trim();
            ps.setString(1, clean);
            ps.setString(2, clean);
            ps.setString(3, clean);
            ps.setString(4, clean);
            ps.setString(5, clean);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("username");
                }
            }
        } catch (SQLException e) {
            System.err.println("Error finding username by identifier: " + e.getMessage());
        }
        return null;
    }

    public java.util.List<String> findIdsByRole(User.Role role) {
        String col = role == User.Role.MANAGER ? "manager_id" : "employee_id";
        String sql = "SELECT " + col + " FROM users WHERE role = ? AND " + col + " IS NOT NULL ORDER BY " + col;
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, role.name());
            try (ResultSet rs = ps.executeQuery()) {
                java.util.List<String> out = new java.util.ArrayList<>();
                while (rs.next()) out.add(rs.getString(1));
                return out;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    /** Next ID in a table like EMP101, EMP102... or MGR101, MGR102..., based on the highest existing number. */
    private String nextId(Connection c, String table, String idColumn, String prefix) throws SQLException {
        String sql = "SELECT COALESCE(MAX(CAST(SUBSTRING(" + idColumn + ", " + (prefix.length() + 1) + ") AS UNSIGNED)),100) "
                   + "FROM " + table + " WHERE " + idColumn + " REGEXP '^" + prefix + "[0-9]+$'";
        try (PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            rs.next();
            return prefix + (rs.getInt(1) + 1);
        }
    }

    private User map(ResultSet rs) throws SQLException {
        boolean mustChange = false;
        try {
            mustChange = rs.getBoolean("must_change_password");
        } catch (SQLException ignored) {}
        String empId = rs.getString("employee_id");
        String mgrId = rs.getString("manager_id");
        User.Role role = User.Role.valueOf(rs.getString("role"));
        if (role == User.Role.MANAGER && (empId == null || empId.isEmpty())) {
            empId = mgrId;
        }
        return new User(rs.getInt("id"), rs.getString("username"), rs.getString("password_hash"),
                role, empId, mgrId, null, mustChange);
    }
}