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

@WebServlet("/updateTaskStatus")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,      // 1 MB buffer
    maxFileSize = 25 * 1024 * 1024,       // 25 MB max file
    maxRequestSize = 50 * 1024 * 1024     // 50 MB max cumulative request
)
public class UpdateTaskStatusServlet extends HttpServlet {
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

        Task task = taskService.getTaskById(taskId);
        if (task == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Task not found.");
            return;
        }

        if (user.getRole() == User.Role.EMPLOYEE) {
            if (!task.getAssignedTo().equalsIgnoreCase(user.getEmployeeId())) {
                resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                req.setAttribute("errorMessage", "Access Denied: You can only update tasks assigned to you.");
                req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
                return;
            }
        }

        req.setAttribute("task", task);
        req.getRequestDispatcher("/updateTaskStatus.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        User user = currentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login.html");
            return;
        }

        String idParam = req.getParameter("id");
        String status = req.getParameter("status");
        String comment = req.getParameter("comment");

        int taskId;
        try {
            String clean = (idParam == null ? "" : idParam.trim()).replaceAll("(?i)^task0*", "");
            taskId = Integer.parseInt(clean.isEmpty() ? "0" : clean);
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid task ID.");
            return;
        }

        Task task = taskService.getTaskById(taskId);
        if (task == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Task not found.");
            return;
        }

        // Handle uploaded work proof deliverable files
        List<String> combinedProofFiles = new ArrayList<>();
        String[] keptProof = req.getParameterValues("existingProofFiles");
        if (keptProof != null) {
            for (String p : keptProof) {
                if (p != null && !p.trim().isEmpty() && task.getWorkProofFileList().contains(p.trim())) {
                    combinedProofFiles.add(p.trim());
                }
            }
        } else if (req.getParameter("hasExistingProofCheck") == null && task.hasWorkProofFile()) {
            combinedProofFiles.addAll(task.getWorkProofFileList());
        }

        try {
            List<String> newProof = FileStorageUtil.saveUploadedFiles(req, "workProofFile", getServletContext(), "proof", FileStorageUtil.DEFAULT_MAX_TOTAL_BYTES);
            combinedProofFiles.addAll(newProof);
        } catch (IllegalArgumentException ex) {
            req.setAttribute("errorMessage", ex.getMessage());
            req.setAttribute("task", task);
            req.getRequestDispatcher("/updateTaskStatus.jsp").forward(req, resp);
            return;
        } catch (Exception e) {
            System.err.println("Warning: could not process workProofFile: " + e.getMessage());
        }

        String workProofFile = combinedProofFiles.isEmpty() ? (task.hasWorkProofFile() && req.getParameter("hasExistingProofCheck") != null ? "" : null) : FileStorageUtil.joinFileNames(combinedProofFiles);

        try {
            taskService.updateTaskStatus(taskId, status, comment, user, workProofFile);
            int count = combinedProofFiles.size();
            req.setAttribute("successMessage", "Task status updated successfully."
                    + (count > 0 ? " (" + count + " proof deliverable file" + (count > 1 ? "s" : "") + " attached)." : ""));
            // Reload updated task
            task = taskService.getTaskById(taskId);
        } catch (IllegalArgumentException | IllegalStateException ex) {
            req.setAttribute("errorMessage", ex.getMessage());
        } catch (Exception ex) {
            req.setAttribute("errorMessage", "Server error updating status. Please try again.");
        }

        req.setAttribute("task", task);
        req.getRequestDispatcher("/updateTaskStatus.jsp").forward(req, resp);
    }
}
