package com.smartoffice.util;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

public class CsrfUtil {
    private static final String CSRF_SESSION_ATTR = "CSRF_TOKEN";
    private static final SecureRandom RANDOM = new SecureRandom();

    public static String getToken(HttpSession session) {
        if (session == null) return "";
        synchronized (session) {
            String token = (String) session.getAttribute(CSRF_SESSION_ATTR);
            if (token == null || token.isEmpty()) {
                byte[] bytes = new byte[32];
                RANDOM.nextBytes(bytes);
                token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
                session.setAttribute(CSRF_SESSION_ATTR, token);
            }
            return token;
        }
    }

    public static boolean validate(HttpServletRequest request) {
        if (request == null) return false;
        HttpSession session = request.getSession(false);
        if (session == null) return false;

        String sessionToken = (String) session.getAttribute(CSRF_SESSION_ATTR);
        if (sessionToken == null || sessionToken.isEmpty()) return false;

        String requestToken = request.getParameter("csrfToken");
        if (requestToken == null || requestToken.isEmpty()) {
            requestToken = request.getHeader("X-CSRF-Token");
        }
        if (requestToken == null || requestToken.isEmpty()) return false;

        return MessageDigest.isEqual(
                sessionToken.getBytes(StandardCharsets.UTF_8),
                requestToken.getBytes(StandardCharsets.UTF_8)
        );
    }
}
