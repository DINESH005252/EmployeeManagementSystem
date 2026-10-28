package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import service.PasswordResetService;

import java.io.IOException;
import java.io.PrintWriter;

@WebServlet(urlPatterns = {"/forgotPassword", "/forgot-password"})
public class ForgotPasswordServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private PasswordResetService resetService;

    @Override
    public void init() {
        this.resetService = new PasswordResetService();
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.sendRedirect(req.getContextPath() + "/forgotPassword.html");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json;charset=UTF-8");

        String action = req.getParameter("action");
        if (action == null) action = "";

        PrintWriter out = resp.getWriter();

        try {
            if ("send_code".equalsIgnoreCase(action)) {
                String identifier = req.getParameter("identifier");
                String maskedEmail = resetService.requestVerificationCode(identifier);
                out.print("{\"success\":true,\"maskedEmail\":\"" + escapeJson(maskedEmail) + "\",\"message\":\"Verification code sent successfully to " + escapeJson(maskedEmail) + ".\"}");
            } else if ("verify_and_reset".equalsIgnoreCase(action)) {
                String identifier = req.getParameter("identifier");
                String code = req.getParameter("code");
                String newPassword = req.getParameter("newPassword");
                String confirmPassword = req.getParameter("confirmPassword");

                resetService.verifyAndResetPassword(identifier, code, newPassword, confirmPassword);
                out.print("{\"success\":true,\"message\":\"Password reset successfully. You can now sign in with your new password.\"}");
            } else {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"success\":false,\"message\":\"Unknown action: " + escapeJson(action) + "\"}");
            }
        } catch (IllegalArgumentException ex) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print("{\"success\":false,\"message\":\"" + escapeJson(ex.getMessage()) + "\"}");
        } catch (Exception ex) {
            log("Error processing forgot password request", ex);
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"success\":false,\"message\":\"Server error processing request. Please try again later.\"}");
        }
    }

    private static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }
}
