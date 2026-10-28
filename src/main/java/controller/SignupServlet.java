package controller;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import service.AuthService;
import service.EmployeeService;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@WebServlet("/signup")
public class SignupServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private AuthService authService;

    @Override
    public void init() {
        authService = new AuthService(new EmployeeService());
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.sendRedirect(req.getContextPath() + "/login.html?error=" + URLEncoder.encode("Self-registration is disabled. Accounts are provisioned by HR Administration.", StandardCharsets.UTF_8));
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.sendRedirect(req.getContextPath() + "/login.html?error=" + URLEncoder.encode("Self-registration is disabled. Accounts are provisioned by HR Administration.", StandardCharsets.UTF_8));
    }
}