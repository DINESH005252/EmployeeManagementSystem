package util;

import jakarta.mail.*;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;

import java.util.Properties;

/** Sends login-credential emails via Gmail SMTP when HR creates an Employee or Manager account. */
public class MailService {
    private static final String SMTP_HOST = "smtp.gmail.com";
    private static final String SMTP_PORT = "587";

    // The Gmail account that sends these emails, and its 16-character App Password (NOT your normal password).
    private static final String SMTP_USER = "dineshkumar2010202003@gmail.com";   // <-- change this
    private static final String SMTP_APP_PASSWORD = "ejzurahdfthqpvim";  // <-- change this, no spaces

    public static final String DEFAULT_LOGIN_URL = "http://localhost:8080/EmployeeManagementSystemTask3Web/login.html";

    public static void sendCredentialsEmail(String toEmail, String toName, String loginId,
                                            String password, String role) throws MessagingException {
        sendCredentialsEmail(toEmail, toName, loginId, password, role, DEFAULT_LOGIN_URL);
    }

    public static void sendCredentialsEmail(String toEmail, String toName, String loginId,
                                            String password, String role, String loginUrl) throws MessagingException {
        if (toEmail == null || toEmail.trim().isEmpty())
            throw new MessagingException("No email address on file for this account.");

        String targetLoginUrl = (loginUrl != null && !loginUrl.trim().isEmpty())
                ? loginUrl.trim()
                : DEFAULT_LOGIN_URL;

        Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.host", SMTP_HOST);
        props.put("mail.smtp.port", SMTP_PORT);
        props.put("mail.smtp.connectiontimeout", "10000");
        props.put("mail.smtp.timeout", "10000");

        Session session = Session.getInstance(props, new Authenticator() {
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(SMTP_USER, SMTP_APP_PASSWORD);
            }
        });

        String roleLabel = "MANAGER".equalsIgnoreCase(role) ? "Manager" : "Employee";

        Message message = new MimeMessage(session);
        message.setFrom(new InternetAddress(SMTP_USER));
        message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
        message.setSubject("Your " + roleLabel + " Account - Employee Management System");

        String body =
                "Hello " + toName + ",\n\n"
              + "An account has been created for you in the Employee Management System as a " + roleLabel + ".\n\n"
              + "Login ID     : " + loginId + "\n"
              + "Password     : " + password + "\n\n"
              + "Login Portal : " + targetLoginUrl + "\n\n"
              + "You can sign in using your ID or this email address at the login page:\n"
              + targetLoginUrl + "\n\n"
              + "For security, please change your password after your first login.\n\n"
              + "Regards,\nHR Team";

        message.setText(body);
        Transport.send(message);
    }
}