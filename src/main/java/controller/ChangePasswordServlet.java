package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.User;
import service.AuthService;
import service.EmployeeService;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@WebServlet(urlPatterns = {"/change-password", "/changePassword"})
public class ChangePasswordServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private AuthService authService;

    @Override
    public void init() {
        this.authService = new AuthService(new EmployeeService());
    }

    private User currentUser(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s == null ? null : (User) s.getAttribute("user");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        User user = currentUser(req);

        boolean isJson = "application/json".equalsIgnoreCase(req.getContentType())
                || "XMLHttpRequest".equalsIgnoreCase(req.getHeader("X-Requested-With"))
                || "true".equalsIgnoreCase(req.getParameter("ajax"));

        if (user == null) {
            if (isJson) {
                resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().print("{\"success\":false,\"message\":\"Session expired. Please sign in again.\"}");
            } else {
                resp.sendRedirect(req.getContextPath() + "/login.html");
            }
            return;
        }

        String currentPassword = req.getParameter("currentPassword");
        String newPassword = req.getParameter("newPassword");
        String confirmPassword = req.getParameter("confirmPassword");

        try {
            authService.changePassword(user.getUsername(), currentPassword, newPassword, confirmPassword);

            // Update user in session with mustChangePassword = false
            HttpSession session = req.getSession(false);
            if (session != null) {
                User updated = new User(user.getId(), user.getUsername(), null, user.getRole(),
                        user.getEmployeeId(), user.getManagerId(), user.getDisplayName(), false);
                session.setAttribute("user", updated);
            }

            if (isJson) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().print("{\"success\":true,\"message\":\"Password changed successfully.\"}");
            } else {
                String referer = req.getHeader("Referer");
                if (referer == null || referer.isEmpty()) {
                    referer = user.isManager() ? "manager.html" : "employee.html";
                }
                String sep = referer.contains("?") ? "&" : "?";
                resp.sendRedirect(referer + sep + "msg=" + URLEncoder.encode("Password changed successfully.", StandardCharsets.UTF_8));
            }
        } catch (IllegalArgumentException ex) {
            if (isJson) {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().print("{\"success\":false,\"message\":\"" + escapeJson(ex.getMessage()) + "\"}");
            } else {
                String referer = req.getHeader("Referer");
                if (referer == null || referer.isEmpty()) {
                    referer = user.isManager() ? "manager.html" : "employee.html";
                }
                String sep = referer.contains("?") ? "&" : "?";
                resp.sendRedirect(referer + sep + "err=" + URLEncoder.encode(ex.getMessage(), StandardCharsets.UTF_8));
            }
        } catch (Exception ex) {
            log("Error changing password", ex);
            if (isJson) {
                resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().print("{\"success\":false,\"message\":\"Server error changing password. Please try again.\"}");
            } else {
                String referer = req.getHeader("Referer");
                if (referer == null || referer.isEmpty()) {
                    referer = user.isManager() ? "manager.html" : "employee.html";
                }
                String sep = referer.contains("?") ? "&" : "?";
                resp.sendRedirect(referer + sep + "err=" + URLEncoder.encode("Failed to update password.", StandardCharsets.UTF_8));
            }
        }
    }

    private static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }
}
