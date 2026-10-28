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
import java.util.List;
import java.util.Map;

@WebServlet("/myTasks")
public class MyTasksServlet extends HttpServlet {
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

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = currentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login.html");
            return;
        }

        String employeeId = user.getEmployeeId();
        if (employeeId == null || employeeId.trim().isEmpty()) {
            // If logged in as Manager or HR, they can either view manageTasks or their own tasks
            if (user.isManager() || user.isHr()) {
                resp.sendRedirect(req.getContextPath() + "/viewTask");
                return;
            }
            employeeId = user.getUsername();
        }

        List<Task> tasks = taskService.getTasksByEmployee(employeeId);
        Map<String, Integer> stats = taskService.getEmployeeStats(employeeId);

        req.setAttribute("tasks", tasks);
        req.setAttribute("stats", stats);
        req.setAttribute("employeeId", employeeId);
        req.getRequestDispatcher("/myTasks.jsp").forward(req, resp);
    }
}
