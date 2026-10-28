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

@WebServlet("/viewTask")
public class ViewTaskServlet extends HttpServlet {
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

        String idParam = req.getParameter("id");
        if (idParam == null || idParam.trim().isEmpty()) {
            idParam = req.getParameter("taskId");
        }

        if (idParam != null && !idParam.trim().isEmpty()) {
            // View single task details
            int taskId;
            try {
                String clean = idParam.trim().replaceAll("(?i)^task0*", "");
                taskId = Integer.parseInt(clean.isEmpty() ? "0" : clean);
            } catch (NumberFormatException e) {
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid task ID format.");
                return;
            }

            Task task = taskService.getTaskById(taskId);
            if (task == null) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Task not found.");
                return;
            }

            // Role check: Employee can only view their own assigned task
            if (user.getRole() == User.Role.EMPLOYEE) {
                if (!task.getAssignedTo().equalsIgnoreCase(user.getEmployeeId())) {
                    resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    req.setAttribute("errorMessage", "Access Denied: You can only view tasks assigned to you.");
                    req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
                    return;
                }
            }

            req.setAttribute("task", task);
            req.getRequestDispatcher("/viewTask.jsp").forward(req, resp);
        } else {
            // View tasks list
            if (user.getRole() == User.Role.EMPLOYEE) {
                resp.sendRedirect(req.getContextPath() + "/myTasks");
            } else if (user.isHr()) {
                resp.sendRedirect(req.getContextPath() + "/employeePerformance");
            } else {
                String keyword = req.getParameter("keyword");
                if (keyword == null) keyword = req.getParameter("search");
                String status = req.getParameter("status");
                String priority = req.getParameter("priority");
                String department = req.getParameter("department");
                String sort = req.getParameter("sort");
                String order = req.getParameter("order");

                List<Task> tasks;
                if ((keyword != null && !keyword.trim().isEmpty())
                        || (status != null && !status.trim().isEmpty() && !"ALL".equalsIgnoreCase(status))
                        || (priority != null && !priority.trim().isEmpty() && !"ALL".equalsIgnoreCase(priority))
                        || (department != null && !department.trim().isEmpty() && !"ALL".equalsIgnoreCase(department))
                        || (sort != null && !sort.trim().isEmpty())) {
                    tasks = taskService.searchTasks(keyword, status, priority, department, sort, order);
                } else {
                    tasks = taskService.getAllTasks(sort, order);
                }

                req.setAttribute("tasks", tasks);
                req.setAttribute("departments", taskService.getDistinctDepartments());
                req.setAttribute("keyword", keyword);
                req.setAttribute("selectedStatus", status);
                req.setAttribute("selectedPriority", priority);
                req.setAttribute("selectedDepartment", department);
                req.setAttribute("sort", sort);
                req.setAttribute("order", order);
                req.getRequestDispatcher("/manageTasks.jsp").forward(req, resp);
            }
        }
    }
}
