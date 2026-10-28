package controller;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.User;

import java.io.IOException;

@WebServlet("/session")
public class SessionServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        User u = session == null ? null : (User) session.getAttribute("user");
        if (u == null) {
            resp.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        resp.getWriter().write("{\"name\":\"" + json(u.getDisplayName()) + "\",\"role\":\"" + u.getRole()
                + "\",\"employeeId\":\"" + json(u.getEmployeeId())
                + "\",\"managerId\":\"" + json(u.getManagerId())
                + "\",\"mustChangePassword\":" + u.isMustChangePassword() + "}");
    }

    private static String json(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
