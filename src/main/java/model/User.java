package model;

public class User {
    public enum Role { EMPLOYEE, HR, MANAGER }

    private final int id;
    private final String username;
    private final String passwordHash;   // null once the user is stored in the session
    private final Role role;
    private final String employeeId;     // set only for EMPLOYEE accounts
    private final String managerId;      // set only for MANAGER accounts
    private final String displayName;
    private final boolean mustChangePassword;

    public User(int id, String username, String passwordHash, Role role,
               String employeeId, String managerId, String displayName) {
        this(id, username, passwordHash, role, employeeId, managerId, displayName, false);
    }

    public User(int id, String username, String passwordHash, Role role,
               String employeeId, String managerId, String displayName, boolean mustChangePassword) {
        this.id = id;
        this.username = username;
        this.passwordHash = passwordHash;
        this.role = role;
        this.employeeId = employeeId;
        this.managerId = managerId;
        this.displayName = displayName;
        this.mustChangePassword = mustChangePassword;
    }

    public int getId() { return id; }
    public String getUsername() { return username; }
    public String getPasswordHash() { return passwordHash; }
    public Role getRole() { return role; }
    public String getEmployeeId() {
        if (employeeId != null && !employeeId.isEmpty()) {
            return employeeId;
        }
        if (isManager() && managerId != null && !managerId.isEmpty()) {
            return managerId;
        }
        return employeeId;
    }
    public String getManagerId() { return managerId; }
    public String getDisplayName() { return displayName; }
    public boolean isMustChangePassword() { return mustChangePassword; }
    public boolean isHr() { return role == Role.HR; }
    public boolean isManager() { return role == Role.MANAGER; }
    public boolean isEmployee() { return role == Role.EMPLOYEE; }

    /** Copy without the password hash, safe to keep in the session. */
    public User withoutSecrets(String displayName) {
        return new User(id, username, null, role, employeeId, managerId, displayName, mustChangePassword);
    }
}