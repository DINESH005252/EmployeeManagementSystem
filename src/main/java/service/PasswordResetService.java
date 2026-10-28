package service;

import dao.UserDAO;
import jakarta.mail.Authenticator;
import jakarta.mail.Message;
import jakarta.mail.PasswordAuthentication;
import jakarta.mail.Session;
import jakarta.mail.Transport;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;
import model.User;
import util.DBConnection;
import util.PasswordUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Properties;

public class PasswordResetService {
    private final UserDAO userDAO;

    // SMTP Configuration for WorkPulse Notifications
    private static final String SMTP_HOST = "smtp.gmail.com";
    private static final String SMTP_PORT = "587";
    private static final String SMTP_USER = "dineshkumar2010202003@gmail.com";
    private static final String SMTP_PASS = "ejzurahdfthqpvim";

    public PasswordResetService() {
        this.userDAO = new UserDAO();
    }

    public PasswordResetService(UserDAO userDAO) {
        this.userDAO = userDAO;
    }

    /**
     * Finds the user by identifier (Employee ID, Manager ID, Username, or Email),
     * generates a 6-digit code, stores it with 15-minute expiration, and sends an email.
     * Returns the masked email address.
     */
    public String requestVerificationCode(String identifier) {
        if (identifier == null || identifier.trim().isEmpty()) {
            throw new IllegalArgumentException("Please enter your Employee ID, Manager ID, or registered Email.");
        }

        String clean = identifier.trim();
        User user = userDAO.findByIdentifier(clean);
        String email = userDAO.findEmailByIdentifier(clean);

        if (user == null || email == null || email.trim().isEmpty()) {
            throw new IllegalArgumentException("No registered account found matching '" + clean + "'.");
        }

        String code = PasswordUtil.generateVerificationCode();

        // Store verification code in database with 15-minute expiration
        String sql = "INSERT INTO password_resets (identifier, email, code, expires_at) "
                   + "VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL 15 MINUTE))";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, user.getUsername());
            ps.setString(2, email);
            ps.setString(3, code);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("Database error saving verification code: " + e.getMessage(), e);
        }

        // Asynchronously dispatch the verification email so UI is fast and responsive
        String userDisplayName = user.getDisplayName() != null ? user.getDisplayName() : user.getUsername();
        new Thread(() -> sendVerificationEmail(email, code, userDisplayName)).start();

        return maskEmail(email);
    }

    /**
     * Verifies the code and resets the user's password.
     */
    public void verifyAndResetPassword(String identifier, String code, String newPassword, String confirmPassword) {
        if (identifier == null || identifier.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid user identifier.");
        }
        if (code == null || code.trim().isEmpty()) {
            throw new IllegalArgumentException("Please enter the 6-digit verification code sent to your email.");
        }
        if (newPassword == null || newPassword.length() < 8 || newPassword.length() > 100
                || !newPassword.matches(".*[A-Za-z].*") || !newPassword.matches(".*[0-9].*")) {
            throw new IllegalArgumentException("New password must be 8 to 100 characters and contain both a letter and a digit.");
        }
        if (!newPassword.equals(confirmPassword)) {
            throw new IllegalArgumentException("The two passwords do not match.");
        }

        String cleanId = identifier.trim();
        String cleanCode = code.trim();

        // Check if code is valid and unexpired
        String selectSql = "SELECT id, identifier FROM password_resets "
                         + "WHERE (identifier = ? OR email = ?) AND code = ? AND used = FALSE AND expires_at > NOW() "
                         + "ORDER BY id DESC LIMIT 1";

        int resetId = -1;
        String username = null;

        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(selectSql)) {
            ps.setString(1, cleanId);
            ps.setString(2, cleanId);
            ps.setString(3, cleanCode);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    resetId = rs.getInt("id");
                    username = rs.getString("identifier");
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error verifying code: " + e.getMessage(), e);
        }

        if (resetId == -1 || username == null) {
            throw new IllegalArgumentException("Invalid, expired, or already used verification code. Please request a new code.");
        }

        // Update password and clear temporary password flag
        boolean updated = userDAO.updatePassword(username, PasswordUtil.hash(newPassword));
        if (!updated) {
            throw new RuntimeException("Failed to update password. Please try again.");
        }

        // Mark code as used
        String markUsedSql = "UPDATE password_resets SET used = TRUE WHERE id = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(markUsedSql)) {
            ps.setInt(1, resetId);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println("Warning: failed to mark reset code as used: " + e.getMessage());
        }
    }

    private void sendVerificationEmail(String recipientEmail, String code, String recipientName) {
        Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.host", SMTP_HOST);
        props.put("mail.smtp.port", SMTP_PORT);

        Session session = Session.getInstance(props, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(SMTP_USER, SMTP_PASS);
            }
        });

        try {
            Message message = new MimeMessage(session);
            message.setFrom(new InternetAddress(SMTP_USER, "WorkPulse Security"));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(recipientEmail));
            message.setSubject("WorkPulse — Password Reset Verification Code: " + code);

            String html = "<div style='font-family:-apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif; max-width:560px; margin:0 auto; padding:28px; border:1px solid #e2e8f0; border-radius:14px; background:#ffffff;'>"
                + "<div style='text-align:center; margin-bottom:20px;'>"
                + "  <div style='display:inline-block; background:linear-gradient(135deg, #2563eb, #4f46e5); color:#ffffff; padding:10px 18px; border-radius:10px; font-weight:800; font-size:18px; letter-spacing:-0.02em;'>WorkPulse</div>"
                + "</div>"
                + "<h2 style='color:#0f172a; margin-bottom:10px; font-size:20px; text-align:center;'>Password Reset Verification Code</h2>"
                + "<p style='color:#475569; font-size:14px; line-height:1.6;'>Hello " + (recipientName != null ? recipientName : "Team Member") + ",</p>"
                + "<p style='color:#475569; font-size:14px; line-height:1.6;'>You requested to reset your password for your WorkPulse account. Enter the 6-digit verification code below to authorize the password change:</p>"
                + "<div style='margin:24px 0; text-align:center;'>"
                + "  <span style='display:inline-block; background:#eff6ff; color:#1d4ed8; letter-spacing:8px; font-size:32px; font-weight:800; padding:14px 28px; border-radius:10px; border:2px dashed #bfdbfe; font-family:monospace;'>" + code + "</span>"
                + "</div>"
                + "<p style='color:#b45309; font-size:13px; background:#fffbeb; padding:10px 14px; border-radius:8px; border:1px solid #fde68a;'>⏱️ <b>Important:</b> This verification code will expire in <b>15 minutes</b>.</p>"
                + "<p style='color:#64748b; font-size:13px; line-height:1.5; margin-top:14px;'>If you did not request a password reset, you can safely ignore this email or contact your HR Administrator if you have security concerns.</p>"
                + "<hr style='border:none; border-top:1px solid #e2e8f0; margin:24px 0;'/>"
                + "<p style='color:#94a3b8; font-size:12px; text-align:center;'>WorkPulse Enterprise Management System &bull; Automated Security Service</p>"
                + "</div>";

            message.setContent(html, "text/html; charset=utf-8");
            Transport.send(message);
            System.out.println("Verification code email successfully sent to " + recipientEmail);
        } catch (Exception e) {
            System.err.println("Failed to send verification code email to " + recipientEmail + ": " + e.getMessage());
        }
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) return email;
        int atIdx = email.indexOf('@');
        String name = email.substring(0, atIdx);
        String domain = email.substring(atIdx);
        if (name.length() <= 2) {
            return name.charAt(0) + "***" + domain;
        }
        return name.charAt(0) + "***" + name.charAt(name.length() - 1) + domain;
    }
}
