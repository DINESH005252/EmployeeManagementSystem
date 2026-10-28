package model;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class ManagerReviewSummary {
    private String managerId;
    private String managerName;
    private String department;
    private String email;
    private int totalAssignedTasks;
    private int totalReviewedTasks;
    private double averageRatingGiven;
    private List<Task> reviewedTasks = new ArrayList<>();
    private List<Task> allTasks = new ArrayList<>();

    public ManagerReviewSummary() {}

    public ManagerReviewSummary(String managerId, String managerName, String department, String email) {
        this.managerId = managerId;
        this.managerName = managerName;
        this.department = department;
        this.email = email;
    }

    public String getManagerId() { return managerId; }
    public void setManagerId(String managerId) { this.managerId = managerId; }

    public String getManagerName() { return managerName; }
    public void setManagerName(String managerName) { this.managerName = managerName; }

    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public int getTotalAssignedTasks() { return totalAssignedTasks; }
    public void setTotalAssignedTasks(int totalAssignedTasks) { this.totalAssignedTasks = totalAssignedTasks; }

    public int getTotalReviewedTasks() { return totalReviewedTasks; }
    public void setTotalReviewedTasks(int totalReviewedTasks) { this.totalReviewedTasks = totalReviewedTasks; }

    public double getAverageRatingGiven() { return averageRatingGiven; }
    public void setAverageRatingGiven(double averageRatingGiven) { this.averageRatingGiven = averageRatingGiven; }

    public List<Task> getReviewedTasks() { return reviewedTasks; }
    public void setReviewedTasks(List<Task> reviewedTasks) { this.reviewedTasks = reviewedTasks; }

    public List<Task> getAllTasks() { return allTasks; }
    public void setAllTasks(List<Task> allTasks) { this.allTasks = allTasks; }

    public String getFormattedAvgRating() {
        if (totalReviewedTasks == 0 || averageRatingGiven <= 0) return "N/A";
        return String.format("%.1f", averageRatingGiven);
    }

    public String getStarDisplay() {
        if (totalReviewedTasks == 0 || averageRatingGiven <= 0) return "☆☆☆☆☆";
        int rounded = (int) Math.round(averageRatingGiven);
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < rounded; i++) sb.append("★");
        for (int i = rounded; i < 5; i++) sb.append("☆");
        return sb.toString();
    }

    public int getPendingReviewCount() {
        int pending = 0;
        for (Task t : allTasks) {
            if ("COMPLETED".equalsIgnoreCase(t.getStatus()) && !t.isReviewed()) {
                pending++;
            }
        }
        return pending;
    }

    public int getCompletedTasksCount() {
        int completed = 0;
        for (Task t : allTasks) {
            if ("COMPLETED".equalsIgnoreCase(t.getStatus())) {
                completed++;
            }
        }
        return completed;
    }

    public int getTotalEmployeesAssigned() {
        Set<String> empIds = new HashSet<>();
        for (Task t : allTasks) {
            if (t.getAssignedTo() != null && !t.getAssignedTo().trim().isEmpty()) {
                empIds.add(t.getAssignedTo().trim());
            }
        }
        return empIds.size();
    }

    public List<TaskGroup> getTaskGroups() {
        if (allTasks == null || allTasks.isEmpty()) {
            return Collections.emptyList();
        }
        Map<String, TaskGroup> map = new LinkedHashMap<>();
        for (Task t : allTasks) {
            String titleKey = (t.getTaskTitle() != null && !t.getTaskTitle().trim().isEmpty())
                    ? t.getTaskTitle().trim()
                    : ("TASK" + String.format("%03d", t.getId()));
            String groupKey = titleKey.toLowerCase() + "_" + (t.getDueDate() != null ? t.getDueDate().toString() : "");
            TaskGroup group = map.get(groupKey);
            if (group == null) {
                group = new TaskGroup(titleKey);
                map.put(groupKey, group);
            }
            group.addTask(t);
        }
        return new ArrayList<>(map.values());
    }

    public int getDistinctTaskCount() {
        return getTaskGroups().size();
    }
}
