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

@WebServlet("/taskDashboard")
public class TaskDashboardServlet extends HttpServlet {
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

        if (user.isHr()) {
            resp.sendRedirect(req.getContextPath() + "/employeePerformance");
            return;
        }

        Map<String, Integer> stats;
        List<Task> recentTasks;

        if (user.getRole() == User.Role.EMPLOYEE) {
            String empId = user.getEmployeeId() != null ? user.getEmployeeId() : user.getUsername();
            stats = taskService.getEmployeeStats(empId);
            recentTasks = taskService.getTasksByEmployee(empId);
            req.setAttribute("isEmployee", true);
        } else {
            List<Task> allTasks = taskService.getAllTasks();
            if (user.isManager() && user.getManagerId() != null && !user.getManagerId().trim().isEmpty()) {
                String mgrId = user.getManagerId().trim();
                List<Task> mgrTasks = new java.util.ArrayList<>();
                for (Task t : allTasks) {
                    if (mgrId.equalsIgnoreCase(t.getCreatedBy()) || mgrId.equalsIgnoreCase(t.getReviewedBy())) {
                        mgrTasks.add(t);
                    }
                }
                if (!mgrTasks.isEmpty()) {
                    recentTasks = mgrTasks;
                    stats = calculateStats(mgrTasks);
                } else {
                    recentTasks = allTasks;
                    stats = taskService.getOverallStats();
                }
            } else {
                recentTasks = allTasks;
                stats = taskService.getOverallStats();
            }
            req.setAttribute("isEmployee", false);
        }

        // Calculate Average Rating based on total tasks and evaluated tasks
        double avgRating = 0.0;
        int ratedCount = 0;
        int sumRating = 0;
        int totalTasks = (recentTasks != null) ? recentTasks.size() : (stats != null ? stats.getOrDefault("total", 0) : 0);

        if (recentTasks != null) {
            for (Task t : recentTasks) {
                if (t.isReviewed() && t.getRating() != null && t.getRating() > 0) {
                    sumRating += t.getRating();
                    ratedCount++;
                }
            }
            if (ratedCount > 0) {
                avgRating = (double) sumRating / ratedCount;
            }
        }

        req.setAttribute("stats", stats);
        req.setAttribute("recentTasks", recentTasks);
        req.setAttribute("user", user);
        req.setAttribute("avgRating", avgRating);
        req.setAttribute("ratedCount", ratedCount);
        req.setAttribute("totalTasks", totalTasks);
        req.getRequestDispatcher("/taskDashboard.jsp").forward(req, resp);
    }

    private Map<String, Integer> calculateStats(List<Task> tasks) {
        Map<String, Integer> s = new java.util.LinkedHashMap<>();
        s.put("total", 0);
        s.put("assigned", 0);
        s.put("inProgress", 0);
        s.put("onHold", 0);
        s.put("completed", 0);
        s.put("cancelled", 0);

        if (tasks == null) return s;

        int total = tasks.size();
        int assigned = 0;
        int inProgress = 0;
        int onHold = 0;
        int completed = 0;
        int cancelled = 0;

        for (Task t : tasks) {
            String st = t.getStatus();
            if (Task.STATUS_ASSIGNED.equalsIgnoreCase(st)) assigned++;
            else if (Task.STATUS_IN_PROGRESS.equalsIgnoreCase(st)) inProgress++;
            else if (Task.STATUS_ON_HOLD.equalsIgnoreCase(st)) onHold++;
            else if (Task.STATUS_COMPLETED.equalsIgnoreCase(st)) completed++;
            else if (Task.STATUS_CANCELLED.equalsIgnoreCase(st)) cancelled++;
        }

        s.put("total", total);
        s.put("assigned", assigned);
        s.put("inProgress", inProgress);
        s.put("onHold", onHold);
        s.put("completed", completed);
        s.put("cancelled", cancelled);
        return s;
    }
}
