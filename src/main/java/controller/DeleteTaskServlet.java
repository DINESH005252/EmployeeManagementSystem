package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.Task;
import model.User;
import service.TaskService;

import java.io.IOException;

@WebServlet("/deleteTask")
public class DeleteTaskServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private TaskService taskService;

    @Override
    public void init() {
        this.taskService = new TaskService();
    }

    private User currentUser(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s == null ? null : (User) s.getAttribute("user");
    }

    private boolean isAuthorized(User user) {
        return user != null && user.isManager();
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = currentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login.html");
            return;
        }

        if (!isAuthorized(user)) {
            resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            req.setAttribute("errorMessage", "Access Denied: Only Managers can delete tasks.");
            req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
            return;
        }

        String idParam = req.getParameter("id");
        if (idParam == null || idParam.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/viewTask");
            return;
        }

        int taskId;
        try {
            String clean = idParam.trim().replaceAll("(?i)^task0*", "");
            taskId = Integer.parseInt(clean.isEmpty() ? "0" : clean);
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid task ID.");
            return;
        }

        // If direct get with confirm=true, proceed to delete
        String confirm = req.getParameter("confirm");
        if ("true".equalsIgnoreCase(confirm)) {
            executeDelete(req, resp, taskId);
            return;
        }

        Task task = taskService.getTaskById(taskId);
        if (task == null) {
            resp.sendRedirect(req.getContextPath() + "/viewTask");
            return;
        }

        req.setAttribute("task", task);
        req.getRequestDispatcher("/deleteConfirm.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = currentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login.html");
            return;
        }

        if (!isAuthorized(user)) {
            resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            req.setAttribute("errorMessage", "Access Denied: Employees do not have access to task deletion.");
            req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
            return;
        }

        String idParam = req.getParameter("id");
        int taskId;
        try {
            String clean = (idParam == null ? "" : idParam.trim()).replaceAll("(?i)^task0*", "");
            taskId = Integer.parseInt(clean.isEmpty() ? "0" : clean);
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid task ID.");
            return;
        }

        executeDelete(req, resp, taskId);
    }

    private void executeDelete(HttpServletRequest req, HttpServletResponse resp, int taskId) throws ServletException, IOException {
        try {
            Task task = taskService.getTaskById(taskId);
            if (task == null) {
                req.getSession().setAttribute("flashError", "Task not found.");
                resp.sendRedirect(req.getContextPath() + "/viewTask");
                return;
            }
            if (task.isReviewed() || task.hasWorkProofFile()) {
                req.getSession().setAttribute("flashError", "Cannot delete assignment " + task.getFormattedId() + ": Employee work proof or performance review already exists.");
                resp.sendRedirect(req.getContextPath() + "/viewTask");
                return;
            }
            taskService.deleteTask(taskId);
            req.getSession().setAttribute("flashMessage", "Task " + task.getFormattedId() + " deleted successfully.");
        } catch (Exception e) {
            req.getSession().setAttribute("flashError", "Failed to delete task: " + e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/viewTask");
    }
}
