package model;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class TaskGroup {
    private static final DateTimeFormatter DISPLAY_FORMAT = DateTimeFormatter.ofPattern("dd-MM-yyyy");

    private String title;
    private String description;
    private String department;
    private String priority;
    private LocalDate startDate;
    private LocalDate dueDate;
    private String createdBy;
    private String createdByName;
    private String workFile;
    private final List<Task> employeeTasks = new ArrayList<>();

    public TaskGroup(String title) {
        this.title = title;
    }

    public void addTask(Task t) {
        if (t == null) return;
        employeeTasks.add(t);
        if (description == null || description.isEmpty()) description = t.getDescription();
        if (department == null || department.isEmpty()) department = t.getDepartment();
        if (priority == null || priority.isEmpty()) priority = t.getPriority();
        if (startDate == null) startDate = t.getStartDate();
        if (dueDate == null) dueDate = t.getDueDate();
        if (createdBy == null) createdBy = t.getCreatedBy();
        if (createdByName == null) createdByName = t.getCreatedByName();
        if (workFile == null || workFile.isEmpty()) workFile = t.getWorkFile();
    }

    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public String getDepartment() { return department != null ? department.trim().toUpperCase() : "GENERAL"; }
    public String getPriority() { return priority != null ? priority : "MEDIUM"; }
    public LocalDate getStartDate() { return startDate; }
    public LocalDate getDueDate() { return dueDate; }
    public String getCreatedBy() { return createdBy; }
    public String getCreatedByName() { return createdByName; }
    public String getWorkFile() { return workFile; }
    public List<Task> getEmployeeTasks() { return employeeTasks; }

    public int getMinTaskId() {
        int min = Integer.MAX_VALUE;
        for (Task t : employeeTasks) {
            if (t.getId() < min) min = t.getId();
        }
        return min == Integer.MAX_VALUE ? 0 : min;
    }

    public int getTotalEmployees() {
        return employeeTasks.size();
    }

    public int getCompletedCount() {
        int count = 0;
        for (Task t : employeeTasks) {
            if (Task.STATUS_COMPLETED.equalsIgnoreCase(t.getStatus())) count++;
        }
        return count;
    }

    public int getReviewedCount() {
        int count = 0;
        for (Task t : employeeTasks) {
            if (t.isReviewCompleted()) count++;
        }
        return count;
    }

    public int getPendingReviewCount() {
        int count = 0;
        for (Task t : employeeTasks) {
            if (t.isPendingReview()) count++;
        }
        return count;
    }

    public int getAwaitingCompletionCount() {
        int count = 0;
        for (Task t : employeeTasks) {
            if (t.isAwaitingCompletion()) count++;
        }
        return count;
    }

    public double getAvgRating() {
        double sum = 0;
        int count = 0;
        for (Task t : employeeTasks) {
            if (t.getRating() != null && t.getRating() > 0) {
                sum += t.getRating();
                count++;
            }
        }
        return count > 0 ? (sum / count) : 0.0;
    }

    public String getFormattedAvgRating() {
        double avg = getAvgRating();
        return avg > 0 ? String.format("%.1f", avg) : "Unrated";
    }

    public String getFormattedDueDate() {
        return dueDate != null ? dueDate.format(DISPLAY_FORMAT) : "";
    }

    public String getFormattedStartDate() {
        return startDate != null ? startDate.format(DISPLAY_FORMAT) : "";
    }

    public boolean hasWorkFile() {
        return workFile != null && !workFile.trim().isEmpty();
    }

    public List<String> getWorkFileList() {
        if (!hasWorkFile()) return Collections.emptyList();
        String[] parts = workFile.split("[,;]");
        List<String> list = new ArrayList<>();
        for (String p : parts) {
            String clean = p.trim();
            if (!clean.isEmpty()) list.add(clean);
        }
        return list;
    }

    public String getPriorityBadgeClass() {
        if ("HIGH".equalsIgnoreCase(priority)) return "priority-high";
        if ("MEDIUM".equalsIgnoreCase(priority)) return "priority-medium";
        return "priority-low";
    }

    public boolean isOverdue() {
        if (getCompletedCount() == getTotalEmployees() && getTotalEmployees() > 0) return false;
        if (dueDate == null) return false;
        return dueDate.isBefore(LocalDate.now());
    }

    public boolean isDueToday() {
        if (getCompletedCount() == getTotalEmployees() && getTotalEmployees() > 0) return false;
        if (dueDate == null) return false;
        return dueDate.isEqual(LocalDate.now());
    }
}
