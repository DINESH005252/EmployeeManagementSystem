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
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private AuthService authService;

    @Override
    public void init() {
        authService = new AuthService(new EmployeeService());
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.sendRedirect(req.getContextPath() + "/login.html");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String identifier = req.getParameter("identifier");
        String password = req.getParameter("password");

        try {
            User user = authService.login(identifier, password);

            HttpSession old = req.getSession(false);
            if (old != null) old.invalidate();
            HttpSession session = req.getSession(true);
            session.setAttribute("user", user);
            session.setMaxInactiveInterval(30 * 60);

            String dest = user.isHr() ? "/hr.html" : user.isManager() ? "/manager.html" : "/employee.html";
            resp.sendRedirect(req.getContextPath() + dest);
        } catch (IllegalArgumentException | IllegalStateException ex) {
            fail(req, resp, ex.getMessage());
        } catch (RuntimeException ex) {
            log("Login error", ex);
            fail(req, resp, "Server error. Please try again later.");
        }
    }

    private void fail(HttpServletRequest req, HttpServletResponse resp, String msg) throws IOException {
        resp.sendRedirect(req.getContextPath() + "/login.html?error=" + URLEncoder.encode(msg, StandardCharsets.UTF_8));
    }
}