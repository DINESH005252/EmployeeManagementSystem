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
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@WebServlet("/reviewTask")
public class ReviewTaskServlet extends HttpServlet {
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
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String idStr = req.getParameter("id");
        if (idStr != null && !idStr.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/viewTask?id=" + idStr.trim());
        } else {
            resp.sendRedirect(req.getContextPath() + "/viewTask");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        User user = currentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login.html");
            return;
        }

        // Problem A6: Check user has manager or admin (HR) role before saving or updating a rating
        if (!user.isManager() && !user.isHr()) {
            resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            req.setAttribute("errorMessage", "Access Denied: Only Managers and Administrators can review tasks and assign performance ratings.");
            req.getRequestDispatcher("/accessDenied.jsp").forward(req, resp);
            return;
        }

        String idStr = req.getParameter("taskId");
        String ratingStr = req.getParameter("rating");
        String feedback = req.getParameter("feedback");
        String redirectUrl = req.getParameter("redirectUrl");

        int taskId;
        try {
            taskId = Integer.parseInt(idStr);
        } catch (NumberFormatException e) {
            resp.sendRedirect(req.getContextPath() + "/viewTask");
            return;
        }

        String targetUrl = (redirectUrl != null && !redirectUrl.trim().isEmpty())
                ? req.getContextPath() + "/" + redirectUrl.trim().replaceAll("^/+", "")
                : req.getContextPath() + "/viewTask?id=" + taskId;
        String sep = targetUrl.contains("?") ? "&" : "?";

        // Problem A7, A1: Fetch task and validate existence and completion
        Task task = taskService.getTaskById(taskId);
        if (task == null) {
            resp.sendRedirect(targetUrl + sep + "err="
                    + URLEncoder.encode("Task not found.", StandardCharsets.UTF_8));
            return;
        }

        // Problem A1: In the servlet (doPost), reject the rating if the assignment is not completed
        if (!Task.STATUS_COMPLETED.equalsIgnoreCase(task.getStatus())) {
            resp.sendRedirect(targetUrl + sep + "err="
                    + URLEncoder.encode("Cannot rate task: The assignment is awaiting completion and must be completed by the employee first.", StandardCharsets.UTF_8));
            return;
        }

        // Problem A7: Validate rating (1-5 only)
        int rating;
        try {
            rating = Integer.parseInt(ratingStr);
            if (rating < 1 || rating > 5) {
                throw new IllegalArgumentException("Rating must be between 1 and 5 stars.");
            }
        } catch (Exception e) {
            resp.sendRedirect(targetUrl + sep + "err="
                    + URLEncoder.encode("Please select a valid rating between 1 and 5 stars.", StandardCharsets.UTF_8));
            return;
        }

        // Problem C3: Client and server-side validation for feedback
        if (feedback == null || feedback.trim().isEmpty()) {
            resp.sendRedirect(targetUrl + sep + "err="
                    + URLEncoder.encode("Please enter feedback comments for the employee.", StandardCharsets.UTF_8));
            return;
        }

        if ((rating == 1 || rating == 2) && feedback.trim().length() < 5) {
            resp.sendRedirect(targetUrl + sep + "err="
                    + URLEncoder.encode("Constructive feedback is required when giving a rating of 1 or 2 stars.", StandardCharsets.UTF_8));
            return;
        }

        try {
            String reviewerId = user.isManager() && user.getManagerId() != null
                    ? user.getManagerId()
                    : user.getUsername();
            taskService.reviewTask(taskId, rating, feedback.trim(), reviewerId);

            // Problem C4: Success message after saving a rating
            String empName = task.getAssignedToName() != null ? task.getAssignedToName() : task.getAssignedTo();
            resp.sendRedirect(targetUrl + sep + "msg="
                    + URLEncoder.encode("Performance review and rating saved successfully for " + empName + " (" + task.getFormattedId() + ").", StandardCharsets.UTF_8));
        } catch (IllegalArgumentException | IllegalStateException e) {
            resp.sendRedirect(targetUrl + sep + "err="
                    + URLEncoder.encode(e.getMessage(), StandardCharsets.UTF_8));
        }
    }
}
