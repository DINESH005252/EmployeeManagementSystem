package util;

import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

/** Salted PBKDF2 password hashing using only the JDK. Stored format: iterations:salt:hash */
public class PasswordUtil {
    private static final int ITERATIONS = 65536;
    private static final int KEY_BITS = 256;
    private static final int SALT_BYTES = 16;

    public static String hash(String password) {
        byte[] salt = new byte[SALT_BYTES];
        new SecureRandom().nextBytes(salt);
        byte[] hash = pbkdf2(password.toCharArray(), salt, ITERATIONS);
        return ITERATIONS + ":" + Base64.getEncoder().encodeToString(salt)
                + ":" + Base64.getEncoder().encodeToString(hash);
    }

    public static boolean verify(String password, String stored) {
        try {
            String[] parts = stored.split(":");
            int iterations = Integer.parseInt(parts[0]);
            byte[] salt = Base64.getDecoder().decode(parts[1]);
            byte[] expected = Base64.getDecoder().decode(parts[2]);
            byte[] actual = pbkdf2(password.toCharArray(), salt, iterations);
            return MessageDigest.isEqual(expected, actual);   // constant-time comparison
        } catch (Exception e) {
            return false;
        }
    }

    private static byte[] pbkdf2(char[] password, byte[] salt, int iterations) {
        try {
            PBEKeySpec spec = new PBEKeySpec(password, salt, iterations, KEY_BITS);
            return SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).getEncoded();
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException("Password hashing failed", e);
        }
    }

    /**
     * Generates a cryptographically random, secure temporary password (e.g. "Tmp#8dE9k2").
     * Contains uppercase, lowercase, numbers, and a special character, satisfying password policies.
     */
    public static String generateTemporaryPassword() {
        String upper = "ABCDEFGHJKLMNPQRSTUVWXYZ";
        String lower = "abcdefghijkmnopqrstuvwxyz";
        String digits = "23456789";
        String special = "!@#$%&*";
        SecureRandom sr = new SecureRandom();
        StringBuilder sb = new StringBuilder();
        sb.append("Tmp");
        sb.append(special.charAt(sr.nextInt(special.length())));
        sb.append(upper.charAt(sr.nextInt(upper.length())));
        sb.append(lower.charAt(sr.nextInt(lower.length())));
        sb.append(digits.charAt(sr.nextInt(digits.length())));
        String all = upper + lower + digits;
        for (int i = 0; i < 4; i++) {
            sb.append(all.charAt(sr.nextInt(all.length())));
        }
        return sb.toString();
    }

    /**
     * Generates a 6-digit numeric verification code for forgot password verification (e.g. "729410").
     */
    public static String generateVerificationCode() {
        SecureRandom sr = new SecureRandom();
        int code = 100000 + sr.nextInt(900000);
        return String.valueOf(code);
    }
}