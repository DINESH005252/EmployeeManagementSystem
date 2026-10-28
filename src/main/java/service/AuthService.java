package service;

import dao.ManagerDAO;
import dao.UserDAO;
import model.Employee;
import model.Manager;
import model.User;
import util.PasswordUtil;

import java.util.List;
import java.util.regex.Pattern;

public class AuthService {
    public static final String DEFAULT_HR_USER = "admin";
    public static final String DEFAULT_HR_PASSWORD = "Admin@123";

    private static final Pattern NAME_PATTERN = Pattern.compile("^[\\p{L} .'-]{2,100}$");
    private static final Pattern DEPT_PATTERN = Pattern.compile("^[\\p{L}0-9 &.-]{2,50}$");
    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[\\w.+-]+@[\\w-]+\\.[A-Za-z]{2,}$");

    // Used so an unknown identifier takes as long to reject as a wrong password.
    private static final String DUMMY_HASH = PasswordUtil.hash("not-a-real-password");

    private final UserDAO userDAO = new UserDAO();
    private final ManagerDAO managerDAO = new ManagerDAO();
    private final EmployeeService employeeService;

    public AuthService(EmployeeService employeeService) {
        this.employeeService = employeeService;
    }

    // ---------------- sign in ----------------

    /** identifier can be an Employee ID, a Manager ID, an email, or the HR username ("admin"). */
    public User login(String identifier, String password) {
        if (identifier == null || identifier.trim().isEmpty() || password == null || password.isEmpty())
            throw new IllegalArgumentException("Please enter your ID/email and password.");

        String id = identifier.trim();
        if (id.length() > 100 || password.length() > 100)
            throw new IllegalArgumentException("Invalid ID/email or password.");

        User user = userDAO.findByIdentifier(id);
        boolean passwordOk = PasswordUtil.verify(password, user == null ? DUMMY_HASH : user.getPasswordHash());

        if (user == null || !passwordOk)
            throw new IllegalArgumentException("Invalid ID/email or password.");

        String displayName = "HR Admin";
        if (user.getRole() == User.Role.EMPLOYEE) {
            Employee e = employeeService.findById(user.getEmployeeId());
            if (e == null || !e.isActive())
                throw new IllegalStateException("This account is inactive. Please contact HR.");
            displayName = e.getName();
        } else if (user.getRole() == User.Role.MANAGER) {
            Manager m = managerDAO.findById(user.getManagerId());
            if (m == null || !m.isActive())
                throw new IllegalStateException("This account is inactive. Please contact HR.");
            displayName = m.getName();
        }
        return user.withoutSecrets(displayName);
    }

    // ---------------- sign up (employees only; managers are created by HR) ----------------

    public String register(String name, String email, String department, String password, String confirm) {
        String n = name == null ? "" : name.trim();
        String em = email == null ? "" : email.trim().toLowerCase();
        String d = department == null ? "" : department.trim();

        if (!NAME_PATTERN.matcher(n).matches())
            throw new IllegalArgumentException("Please enter your full name (letters only, 2 to 100 characters).");
        if (!EMAIL_PATTERN.matcher(em).matches())
            throw new IllegalArgumentException("Please enter a valid email address.");
        if (!DEPT_PATTERN.matcher(d).matches())
            throw new IllegalArgumentException("Please enter a valid department (2 to 50 characters).");
        if (password == null || password.length() < 8 || password.length() > 100
                || !password.matches(".*[A-Za-z].*") || !password.matches(".*[0-9].*"))
            throw new IllegalArgumentException("Password must be 8 to 100 characters and contain a letter and a digit.");
        if (!password.equals(confirm))
            throw new IllegalArgumentException("The two passwords do not match.");

        return userDAO.registerEmployee(n, d, em, PasswordUtil.hash(password));
    }

    // ---------------- HR creates Employee or Manager accounts directly ----------------

    /** role must be "EMPLOYEE" or "MANAGER". Returns the generated ID. */
    public String adminCreateUser(String name, String email, String department, String role, String password) {
        String n = name == null ? "" : name.trim();
        String em = email == null ? "" : email.trim().toLowerCase();
        String d = department == null ? "" : department.trim();

        if (!NAME_PATTERN.matcher(n).matches())
            throw new IllegalArgumentException("Please enter a valid full name (letters only, 2 to 100 characters).");
        if (!EMAIL_PATTERN.matcher(em).matches())
            throw new IllegalArgumentException("Please enter a valid email address.");
        if (!DEPT_PATTERN.matcher(d).matches())
            throw new IllegalArgumentException("Please enter a valid department (2 to 50 characters).");

        User.Role r;
        try {
            r = User.Role.valueOf(role);
            if (r == User.Role.HR) throw new IllegalArgumentException();
        } catch (Exception ex) {
            throw new IllegalArgumentException("Please choose a valid role (Employee or Manager).");
        }

        String pwd = (password != null && !password.trim().isEmpty())
                ? password.trim()
                : PasswordUtil.generateTemporaryPassword();

        if (pwd.length() < 8 || pwd.length() > 100
                || !pwd.matches(".*[A-Za-z].*") || !pwd.matches(".*[0-9].*"))
            throw new IllegalArgumentException("Password must be 8 to 100 characters and contain a letter and a digit.");

        return r == User.Role.MANAGER
                ? userDAO.adminRegisterManager(n, d, em, PasswordUtil.hash(pwd))
                : userDAO.adminRegisterEmployee(n, d, em, PasswordUtil.hash(pwd));
    }

    public void changePassword(String username, String currentPassword, String newPassword, String confirmPassword) {
        if (username == null || username.trim().isEmpty())
            throw new IllegalArgumentException("User session is invalid.");
        if (currentPassword == null || currentPassword.isEmpty())
            throw new IllegalArgumentException("Current password is required.");
        if (newPassword == null || newPassword.length() < 8 || newPassword.length() > 100
                || !newPassword.matches(".*[A-Za-z].*") || !newPassword.matches(".*[0-9].*"))
            throw new IllegalArgumentException("New password must be 8 to 100 characters and contain a letter and a digit.");
        if (!newPassword.equals(confirmPassword))
            throw new IllegalArgumentException("New password and confirmation do not match.");
        if (newPassword.equals(currentPassword))
            throw new IllegalArgumentException("New password cannot be identical to your current password.");

        User existing = userDAO.findByUsername(username.trim());
        if (existing == null) {
            // Identifier fallback if username is emp/mgr ID
            existing = userDAO.findByIdentifier(username.trim());
        }
        if (existing == null)
            throw new IllegalArgumentException("User account not found.");

        if (!PasswordUtil.verify(currentPassword, existing.getPasswordHash()))
            throw new IllegalArgumentException("Current password is incorrect.");

        boolean ok = userDAO.updatePassword(existing.getUsername(), PasswordUtil.hash(newPassword));
        if (!ok)
            throw new RuntimeException("Failed to update password in database.");
    }

    public List<String> listManagerIds() { return userDAO.findIdsByRole(User.Role.MANAGER); }

    /** Creates the default HR account if it does not exist yet. */
    public void seedDefaultUsers() {
        if (!userDAO.exists(DEFAULT_HR_USER))
            userDAO.insert(DEFAULT_HR_USER, PasswordUtil.hash(DEFAULT_HR_PASSWORD), User.Role.HR, null);
    }
}