package model;

import java.util.ArrayList;
import java.util.List;

public class EmployeePerformance {
    private String employeeId;
    private String employeeName;
    private String department;
    private int totalTasks;
    private int completedTasks;
    private int reviewedTasks;
    private double averageRating;
    private String latestFeedback;
    private List<Task> taskHistory = new ArrayList<>();

    public EmployeePerformance() {}

    public EmployeePerformance(String employeeId, String employeeName, String department) {
        this.employeeId = employeeId;
        this.employeeName = employeeName;
        this.department = department;
    }

    public String getEmployeeId() { return employeeId; }
    public void setEmployeeId(String employeeId) { this.employeeId = employeeId; }

    public String getEmployeeName() { return employeeName; }
    public void setEmployeeName(String employeeName) { this.employeeName = employeeName; }

    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }

    public int getTotalTasks() { return totalTasks; }
    public void setTotalTasks(int totalTasks) { this.totalTasks = totalTasks; }

    public int getCompletedTasks() { return completedTasks; }
    public void setCompletedTasks(int completedTasks) { this.completedTasks = completedTasks; }

    public int getReviewedTasks() { return reviewedTasks; }
    public void setReviewedTasks(int reviewedTasks) { this.reviewedTasks = reviewedTasks; }

    public double getAverageRating() { return averageRating; }
    public void setAverageRating(double averageRating) { this.averageRating = averageRating; }

    public String getFormattedAvgRating() {
        if (reviewedTasks == 0 || averageRating <= 0) return "N/A";
        return String.format("%.1f", averageRating);
    }

    public String getStarDisplay() {
        if (reviewedTasks == 0 || averageRating <= 0) return "☆☆☆☆☆";
        int rounded = (int) Math.round(averageRating);
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < rounded; i++) sb.append("★");
        for (int i = rounded; i < 5; i++) sb.append("☆");
        return sb.toString();
    }

    public String getPerformanceTier() {
        if (reviewedTasks == 0) return "Pending Review";
        if (averageRating >= 4.5) return "Top Performer";
        if (averageRating >= 3.5) return "Exceeds Expectations";
        if (averageRating >= 2.5) return "Meets Expectations";
        return "Needs Improvement";
    }

    public String getTierBadgeClass() {
        if (reviewedTasks == 0) return "badge-secondary";
        if (averageRating >= 4.5) return "badge-success";
        if (averageRating >= 3.5) return "badge-primary";
        if (averageRating >= 2.5) return "badge-warning";
        return "badge-danger";
    }

    public String getLatestFeedback() { return latestFeedback; }
    public void setLatestFeedback(String latestFeedback) { this.latestFeedback = latestFeedback; }

    public List<Task> getTaskHistory() { return taskHistory; }
    public void setTaskHistory(List<Task> taskHistory) { this.taskHistory = taskHistory; }
}
