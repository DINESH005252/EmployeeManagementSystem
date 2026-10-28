package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import model.Task;
import model.User;
import service.TaskService;
import util.FileStorageUtil;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/editTask")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize = 25 * 1024 * 1024,
    maxRequestSize = 50 * 1024 * 1024
)
public class EditTaskServlet extends HttpServlet {
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
        // Only managers are authorized to edit tasks
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
            req.setAttribute("errorMessage", "Access Denied: Only Managers can edit tasks.");
            req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
            return;
        }

        String idParam = req.getParameter("id");
        if (idParam == null || idParam.trim().isEmpty()) {
            idParam = req.getParameter("taskId");
        }

        if (idParam == null || idParam.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/viewTask");
            return;
        }

        int taskId;
        try {
            String clean = idParam.trim().replaceAll("(?i)^task0*", "");
            taskId = Integer.parseInt(clean.isEmpty() ? "0" : clean);
        } catch (NumberFormatException e) {
            resp.sendRedirect(req.getContextPath() + "/viewTask");
            return;
        }

        Task task = taskService.getTaskById(taskId);
        if (task == null) {
            req.setAttribute("errorMessage", "Task not found.");
            req.getRequestDispatcher("/viewTask").forward(req, resp);
            return;
        }

        String managerId = user.getManagerId() != null ? user.getManagerId() : user.getUsername();
        req.setAttribute("task", task);
        req.setAttribute("employees", taskService.getEmployeesForManager(managerId));
        req.getRequestDispatcher("/editTask.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        User user = currentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login.html");
            return;
        }

        if (!isAuthorized(user)) {
            resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            req.setAttribute("errorMessage", "Access Denied: Only Managers can edit tasks.");
            req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
            return;
        }

        int taskId;
        try {
            String rawId = req.getParameter("id");
            String clean = (rawId == null ? "" : rawId.trim()).replaceAll("(?i)^task0*", "");
            taskId = Integer.parseInt(clean.isEmpty() ? "0" : clean);
        } catch (NumberFormatException e) {
            resp.sendRedirect(req.getContextPath() + "/viewTask");
            return;
        }

        String title = req.getParameter("taskTitle");
        String description = req.getParameter("description");
        String assignedTo = req.getParameter("assignedTo");
        String department = req.getParameter("department");
        String priority = req.getParameter("priority");
        String startDate = req.getParameter("startDate");
        String dueDate = req.getParameter("dueDate");
        String status = req.getParameter("status");

        String managerId = user.getManagerId() != null ? user.getManagerId() : user.getUsername();

        Task existingTask = taskService.getTaskById(taskId);
        if (existingTask == null) {
            resp.sendRedirect(req.getContextPath() + "/viewTask");
            return;
        }

        List<String> combinedFiles = new ArrayList<>();
        String[] keptFiles = req.getParameterValues("existingWorkFiles");
        if (keptFiles != null) {
            for (String k : keptFiles) {
                if (k != null && !k.trim().isEmpty() && existingTask.getWorkFileList().contains(k.trim())) {
                    combinedFiles.add(k.trim());
                }
            }
        } else if (req.getParameter("hasExistingFilesCheck") == null && existingTask.hasWorkFile()) {
            combinedFiles.addAll(existingTask.getWorkFileList());
        }

        try {
            List<String> newFiles = FileStorageUtil.saveUploadedFiles(req, "workDetailsFile", getServletContext(), "work", FileStorageUtil.DEFAULT_MAX_TOTAL_BYTES);
            combinedFiles.addAll(newFiles);
        } catch (IllegalArgumentException e) {
            req.setAttribute("task", existingTask);
            req.setAttribute("employees", taskService.getEmployeesForManager(managerId));
            req.setAttribute("errorMessage", e.getMessage());
            req.getRequestDispatcher("/editTask.jsp").forward(req, resp);
            return;
        } catch (Exception e) {
            System.err.println("Warning: could not process replacement file: " + e.getMessage());
        }

        String workFile = FileStorageUtil.joinFileNames(combinedFiles);

        try {
            if (assignedTo != null && !assignedTo.trim().isEmpty()) {
                if (!taskService.isEmployeeInManagerTeams(managerId, assignedTo.trim())) {
                    throw new IllegalArgumentException("Access Denied: Employee (" + assignedTo + ") does not belong to any team under your management.");
                }
            }
            taskService.updateTask(taskId, title, description, assignedTo, department, priority, startDate, dueDate, status, workFile);
            resp.sendRedirect(req.getContextPath() + "/viewTask?id=" + taskId);
        } catch (IllegalArgumentException e) {
            Task task = taskService.getTaskById(taskId);
            req.setAttribute("task", task);
            req.setAttribute("employees", taskService.getEmployeesForManager(managerId));
            req.setAttribute("errorMessage", e.getMessage());
            req.getRequestDispatcher("/editTask.jsp").forward(req, resp);
        }
    }
}
