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

@WebServlet("/searchTasks")
public class SearchTaskServlet extends HttpServlet {
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
        processSearch(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        processSearch(req, resp);
    }

    private void processSearch(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        User user = currentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login.html");
            return;
        }

        String keyword = req.getParameter("keyword");
        if (keyword == null) keyword = req.getParameter("search");
        String status = req.getParameter("status");
        String priority = req.getParameter("priority");
        String department = req.getParameter("department");

        List<Task> tasks;
        if (user.getRole() == User.Role.EMPLOYEE) {
            // Employee only searches within their assigned tasks
            tasks = taskService.searchTasks(keyword, status, priority, department);
            String empId = user.getEmployeeId();
            tasks.removeIf(t -> !empId.equalsIgnoreCase(t.getAssignedTo()));
            req.setAttribute("tasks", tasks);
            req.setAttribute("keyword", keyword);
            req.setAttribute("selectedStatus", status);
            req.setAttribute("selectedPriority", priority);
            req.getRequestDispatcher("/myTasks.jsp").forward(req, resp);
        } else if (user.isHr()) {
            resp.sendRedirect(req.getContextPath() + "/employeePerformance" + (keyword != null && !keyword.trim().isEmpty() ? "?keyword=" + java.net.URLEncoder.encode(keyword.trim(), "UTF-8") : ""));
        } else {
            String sort = req.getParameter("sort");
            String order = req.getParameter("order");
            tasks = taskService.searchTasks(keyword, status, priority, department, sort, order);
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
