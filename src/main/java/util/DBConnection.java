package util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {
    private static final String DEFAULT_URL =
            "jdbc:mysql://localhost:3306/employee_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
    private static final String DEFAULT_USER = "root";
    // Default development password fallback; can be overridden in production via DB_PASSWORD env var or system property
    private static final String DEFAULT_PASSWORD = "****";

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new ExceptionInInitializerError(
                    "MySQL driver not found. Put mysql-connector-j jar in WEB-INF/lib.");
        }
    }

    public static Connection getConnection() throws SQLException {
        String envUrl = System.getenv("DB_URL");
        if (envUrl == null || envUrl.trim().isEmpty()) {
            envUrl = System.getProperty("DB_URL", System.getProperty("db.url", DEFAULT_URL));
        }

        String envUser = System.getenv("DB_USER");
        if (envUser == null || envUser.trim().isEmpty()) {
            envUser = System.getProperty("DB_USER", System.getProperty("db.user", DEFAULT_USER));
        }

        String pass = System.getenv("DB_PASSWORD");
        if (pass == null) {
            pass = System.getProperty("DB_PASSWORD");
        }
        if (pass == null) {
            pass = System.getProperty("db.password");
        }
        if (pass == null) {
            pass = DEFAULT_PASSWORD;
        }

        return DriverManager.getConnection(envUrl, envUser, pass);
    }
}
