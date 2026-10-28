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
import util.FileStorageUtil;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;

@WebServlet("/downloadTaskFile")
public class DownloadTaskFileServlet extends HttpServlet {
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

        String idParam = req.getParameter("taskId");
        String type = req.getParameter("type"); // "work" or "proof"

        if (idParam == null || idParam.trim().isEmpty() || type == null) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing task ID or file type.");
            return;
        }

        int taskId;
        try {
            taskId = Integer.parseInt(idParam.trim().replaceAll("(?i)^task0*", ""));
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid task ID.");
            return;
        }

        Task task = taskService.getTaskById(taskId);
        if (task == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Task not found.");
            return;
        }

        // Security authorization check
        if (user.getRole() == User.Role.EMPLOYEE) {
            if (!task.getAssignedTo().equalsIgnoreCase(user.getEmployeeId())) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Access Denied.");
                return;
            }
        }

        List<String> allowedFiles = "proof".equalsIgnoreCase(type) ? task.getWorkProofFileList() : task.getWorkFileList();
        if (allowedFiles.isEmpty()) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "No file attached for this task.");
            return;
        }

        String requestedFile = req.getParameter("file");
        String targetFilename;
        if (requestedFile != null && !requestedFile.trim().isEmpty()) {
            String cleanReq = java.nio.file.Paths.get(requestedFile.trim()).getFileName().toString();
            if (!allowedFiles.contains(cleanReq)) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Requested file does not belong to this task.");
                return;
            }
            targetFilename = cleanReq;
        } else {
            targetFilename = allowedFiles.get(0);
        }

        File file = FileStorageUtil.getFile(getServletContext(), targetFilename);
        if (file == null || !file.exists()) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "File not found on server.");
            return;
        }

        String mimeType = getServletContext().getMimeType(file.getName());
        if (mimeType == null) {
            mimeType = "application/octet-stream";
        }

        resp.setContentType(mimeType);
        resp.setContentLengthLong(file.length());

        // Extract friendly display name
        String downloadName = FileStorageUtil.getOriginalFileName(file.getName());
        if (downloadName == null || downloadName.isEmpty()) {
            downloadName = file.getName();
        }

        String encodedName = URLEncoder.encode(downloadName, StandardCharsets.UTF_8).replace("+", "%20");
        resp.setHeader("Content-Disposition", "inline; filename=\"" + downloadName + "\"; filename*=UTF-8''" + encodedName);

        try (FileInputStream in = new FileInputStream(file);
             OutputStream out = resp.getOutputStream()) {
            byte[] buffer = new byte[8192];
            int bytesRead;
            while ((bytesRead = in.read(buffer)) != -1) {
                out.write(buffer, 0, bytesRead);
            }
            out.flush();
        }
    }
}
