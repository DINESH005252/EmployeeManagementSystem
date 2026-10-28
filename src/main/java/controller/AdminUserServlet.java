package controller;

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

/** HR-only: create an Employee or Manager account directly. POST /admin-user action=create */
@WebServlet("/admin-user")
public class AdminUserServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private AuthService authService;

    @Override
    public void init() {
        authService = new AuthService(new EmployeeService());
    }

    private User currentUser(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s == null ? null : (User) s.getAttribute("user");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        req.setCharacterEncoding("UTF-8");
        User u = currentUser(req);
        if (u == null || !u.isHr()) { resp.sendError(HttpServletResponse.SC_FORBIDDEN); return; }

        String name = req.getParameter("name");
        String email = req.getParameter("email");
        String department = req.getParameter("department");
        String role = req.getParameter("role");

        String tempPassword = util.PasswordUtil.generateTemporaryPassword();

        try {
            String newId = authService.adminCreateUser(name, email, department, role, tempPassword);
            StringBuilder msg = new StringBuilder(
                    "Account created successfully.<br>"
                    + "&bull; Role: <b>" + esc(role) + "</b><br>"
                    + "&bull; Generated User ID: <b style='color:#2563eb; font-size:15px; font-family:monospace;'>" + esc(newId) + "</b><br>"
                    + "&bull; Temporary Password: <b style='color:#b45309; font-size:15px; font-family:monospace; background:#fef3c7; padding:2px 8px; border-radius:4px;'>" + esc(tempPassword) + "</b><br>");
            try {
                String loginUrl = req.getScheme() + "://" + req.getServerName() + ":" + req.getServerPort()
                        + req.getContextPath() + "/login.html";
                util.MailService.sendCredentialsEmail(email, name, newId, tempPassword, role, loginUrl);
                msg.append("The temporary password and login link have been emailed to <b>").append(esc(email)).append("</b>. The user will be required to change their password upon logging in.");
            } catch (Exception mailEx) {
                log("Failed to send credentials email", mailEx);
                msg.append("<br><span style='color:#b91c1c;'><b>Note:</b> Account was created, but email delivery encountered an issue. Please share the generated ID and temporary password above with the user.</span>");
            }
            page(resp, "Create Employee / Manager", "<div class='msg ok'>" + msg + "</div>");
        } catch (IllegalArgumentException | IllegalStateException ex) {
            page(resp, "Create Employee / Manager", "<div class='msg err'>" + esc(ex.getMessage()) + "</div>");
        } catch (RuntimeException ex) {
            log("Admin create user error", ex);
            page(resp, "Create Employee / Manager", "<div class='msg err'>Database error. Check the Tomcat console.</div>");
        }
    }

    private void page(HttpServletResponse resp, String title, String body) throws IOException {
        resp.setContentType("text/html;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        out.println("<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><title>" + esc(title)
                + "</title></head><body><div class='wrap'><h1>" + esc(title) + "</h1>" + body + "</div></body></html>");
    }

    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
}