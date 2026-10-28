package model;

import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class Task {
    public static final String STATUS_ASSIGNED = "ASSIGNED";
    public static final String STATUS_IN_PROGRESS = "IN_PROGRESS";
    public static final String STATUS_ON_HOLD = "ON_HOLD";
    public static final String STATUS_COMPLETED = "COMPLETED";
    public static final String STATUS_CANCELLED = "CANCELLED";

    public static final String PRIORITY_LOW = "LOW";
    public static final String PRIORITY_MEDIUM = "MEDIUM";
    public static final String PRIORITY_HIGH = "HIGH";

    private static final DateTimeFormatter DISPLAY_DATE_FORMAT = DateTimeFormatter.ofPattern("dd-MM-yyyy");

    private int id;
    private String taskTitle;
    private String description;
    private String assignedTo;       // e.g. "EMP101"
    private String assignedToName;   // e.g. "Abhishek"
    private String createdBy;        // e.g. "MGR101" or "admin"
    private String createdByName;    // e.g. "Manager" or "HR Admin"
    private String department;
    private String priority = PRIORITY_MEDIUM;
    private LocalDate startDate;
    private LocalDate dueDate;
    private String status = STATUS_ASSIGNED;
    private String employeeComment;
    private String workFile;         // Manager work details / spec attachment
    private String workProofFile;    // Employee deliverable / proof attachment
    private Integer rating;          // Rating: 1 to 5 stars
    private String feedback;         // Manager feedback about employee performance
    private Timestamp reviewedAt;    // Review timestamp
    private String reviewedBy;       // Manager who reviewed
    private Timestamp createdAt;
    private Timestamp updatedAt;

    public Task() {}

    public Task(int id, String taskTitle, String description, String assignedTo, String createdBy,
                String department, String priority, LocalDate startDate, LocalDate dueDate,
                String status, String employeeComment, Timestamp createdAt, Timestamp updatedAt) {
        this.id = id;
        this.taskTitle = taskTitle;
        this.description = description;
        this.assignedTo = assignedTo;
        this.createdBy = createdBy;
        this.department = department;
        this.priority = priority;
        this.startDate = startDate;
        this.dueDate = dueDate;
        this.status = status;
        this.employeeComment = employeeComment;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public Task(int id, String taskTitle, String description, String assignedTo, String createdBy,
                String department, String priority, LocalDate startDate, LocalDate dueDate,
                String status, String employeeComment, Timestamp createdAt, Timestamp updatedAt,
                String workFile, String workProofFile, Integer rating, String feedback,
                Timestamp reviewedAt, String reviewedBy) {
        this(id, taskTitle, description, assignedTo, createdBy, department, priority, startDate, dueDate,
             status, employeeComment, createdAt, updatedAt);
        this.workFile = workFile;
        this.workProofFile = workProofFile;
        this.rating = rating;
        this.feedback = feedback;
        this.reviewedAt = reviewedAt;
        this.reviewedBy = reviewedBy;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getFormattedId() {
        return "TASK" + String.format("%03d", id);
    }

    public String getTaskTitle() { return taskTitle; }
    public void setTaskTitle(String taskTitle) { this.taskTitle = taskTitle; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getAssignedTo() { return assignedTo; }
    public void setAssignedTo(String assignedTo) { this.assignedTo = assignedTo; }

    public String getAssignedToName() { return assignedToName; }
    public void setAssignedToName(String assignedToName) { this.assignedToName = assignedToName; }

    public String getCreatedBy() { return createdBy; }
    public void setCreatedBy(String createdBy) { this.createdBy = createdBy; }

    public String getCreatedByName() { return createdByName; }
    public void setCreatedByName(String createdByName) { this.createdByName = createdByName; }

    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }

    public String getPriority() { return priority; }
    public void setPriority(String priority) { this.priority = priority; }

    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }

    public LocalDate getDueDate() { return dueDate; }
    public void setDueDate(LocalDate dueDate) { this.dueDate = dueDate; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getEmployeeComment() { return employeeComment; }
    public void setEmployeeComment(String employeeComment) { this.employeeComment = employeeComment; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public Timestamp getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Timestamp updatedAt) { this.updatedAt = updatedAt; }

    public String getFormattedStartDate() {
        return startDate != null ? startDate.format(DISPLAY_DATE_FORMAT) : "";
    }

    public String getFormattedDueDate() {
        return dueDate != null ? dueDate.format(DISPLAY_DATE_FORMAT) : "";
    }

    public String getFormattedCreatedDate() {
        return createdAt != null ? createdAt.toLocalDateTime().toLocalDate().format(DISPLAY_DATE_FORMAT) : "";
    }

    public String getFormattedCreatedAt() {
        return getFormattedCreatedDate();
    }

    /**
     * Allowed next statuses for an employee based on the current status:
     * ASSIGNED -> IN_PROGRESS
     * IN_PROGRESS -> COMPLETED, ON_HOLD
     * ON_HOLD -> IN_PROGRESS
     */
    public List<String> getAllowedEmployeeNextStatuses() {
        if (STATUS_ASSIGNED.equalsIgnoreCase(status)) {
            return List.of(STATUS_ASSIGNED, STATUS_IN_PROGRESS);
        } else if (STATUS_IN_PROGRESS.equalsIgnoreCase(status)) {
            return List.of(STATUS_IN_PROGRESS, STATUS_COMPLETED, STATUS_ON_HOLD);
        } else if (STATUS_ON_HOLD.equalsIgnoreCase(status)) {
            return List.of(STATUS_ON_HOLD, STATUS_IN_PROGRESS);
        } else if (STATUS_COMPLETED.equalsIgnoreCase(status)) {
            return List.of(STATUS_COMPLETED);
        }
        return List.of(status);
    }

    public boolean canEmployeeTransitionTo(String newStatus) {
        if (newStatus == null) return false;
        String cur = this.status == null ? STATUS_ASSIGNED : this.status.toUpperCase();
        String nxt = newStatus.trim().toUpperCase();
        if (cur.equals(nxt)) return true;

        if (STATUS_ASSIGNED.equals(cur)) {
            return STATUS_IN_PROGRESS.equals(nxt);
        } else if (STATUS_IN_PROGRESS.equals(cur)) {
            return STATUS_COMPLETED.equals(nxt) || STATUS_ON_HOLD.equals(nxt);
        } else if (STATUS_ON_HOLD.equals(cur)) {
            return STATUS_IN_PROGRESS.equals(nxt);
        }
        return false;
    }

    public String getStatusBadgeClass() {
        if (STATUS_COMPLETED.equalsIgnoreCase(status)) return "badge-success";
        if (STATUS_IN_PROGRESS.equalsIgnoreCase(status)) return "badge-primary";
        if (STATUS_ON_HOLD.equalsIgnoreCase(status)) return "badge-warning";
        if (STATUS_CANCELLED.equalsIgnoreCase(status)) return "badge-danger";
        return "badge-secondary"; // ASSIGNED
    }

    public String getPriorityBadgeClass() {
        if (PRIORITY_HIGH.equalsIgnoreCase(priority)) return "priority-high";
        if (PRIORITY_MEDIUM.equalsIgnoreCase(priority)) return "priority-medium";
        return "priority-low";
    }

    public String getWorkFile() { return workFile; }
    public void setWorkFile(String workFile) { this.workFile = workFile; }
    public boolean hasWorkFile() { return workFile != null && !workFile.trim().isEmpty(); }

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

    public int getWorkFileCount() {
        return getWorkFileList().size();
    }

    public String getWorkProofFile() { return workProofFile; }
    public void setWorkProofFile(String workProofFile) { this.workProofFile = workProofFile; }
    public boolean hasWorkProofFile() { return workProofFile != null && !workProofFile.trim().isEmpty(); }

    public List<String> getWorkProofFileList() {
        if (!hasWorkProofFile()) return Collections.emptyList();
        String[] parts = workProofFile.split("[,;]");
        List<String> list = new ArrayList<>();
        for (String p : parts) {
            String clean = p.trim();
            if (!clean.isEmpty()) list.add(clean);
        }
        return list;
    }

    public int getWorkProofFileCount() {
        return getWorkProofFileList().size();
    }

    public Integer getRating() { return rating; }
    public void setRating(Integer rating) { this.rating = rating; }
    public boolean hasRating() { return rating != null && rating > 0; }

    public String getFeedback() { return feedback; }
    public void setFeedback(String feedback) { this.feedback = feedback; }
    public boolean hasFeedback() { return feedback != null && !feedback.trim().isEmpty(); }

    public Timestamp getReviewedAt() { return reviewedAt; }
    public void setReviewedAt(Timestamp reviewedAt) { this.reviewedAt = reviewedAt; }

    public String getReviewedBy() { return reviewedBy; }
    public void setReviewedBy(String reviewedBy) { this.reviewedBy = reviewedBy; }

    private String reviewedByName;
    public String getReviewedByName() {
        if (reviewedByName != null && !reviewedByName.trim().isEmpty()) {
            return reviewedByName;
        }
        if (reviewedBy != null && !reviewedBy.trim().isEmpty()) {
            return reviewedBy;
        }
        return "";
    }
    public void setReviewedByName(String reviewedByName) { this.reviewedByName = reviewedByName; }

    public static final String REVIEW_STATUS_AWAITING = "AWAITING COMPLETION";
    public static final String REVIEW_STATUS_PENDING = "PENDING REVIEW";
    public static final String REVIEW_STATUS_REVIEWED = "REVIEWED";

    public boolean isReviewCompleted() {
        return rating != null && rating > 0;
    }

    public boolean isPendingReview() {
        return !isReviewCompleted() && STATUS_COMPLETED.equalsIgnoreCase(status) && hasWorkProofFile();
    }

    public boolean isAwaitingCompletion() {
        return !isReviewCompleted() && !isPendingReview();
    }

    public String getReviewStatus() {
        if (isReviewCompleted()) return REVIEW_STATUS_REVIEWED;
        if (isPendingReview()) return REVIEW_STATUS_PENDING;
        return REVIEW_STATUS_AWAITING;
    }

    public boolean isReviewed() { return isReviewCompleted(); }

    public String getReviewStatusBadgeClass() {
        if (isReviewCompleted()) return "badge-reviewed";
        if (isPendingReview()) return "badge-pending";
        return "badge-awaiting";
    }

    public String getReviewStatusDisplay() {
        if (isReviewCompleted()) return "Reviewed";
        if (isPendingReview()) return "Pending Review";
        return "Awaiting Completion";
    }

    public boolean isOverdue() {
        if (isReviewCompleted() || STATUS_COMPLETED.equalsIgnoreCase(status)) return false;
        if (dueDate == null) return false;
        return dueDate.isBefore(LocalDate.now());
    }

    public boolean isDueToday() {
        if (isReviewCompleted() || STATUS_COMPLETED.equalsIgnoreCase(status)) return false;
        if (dueDate == null) return false;
        return dueDate.isEqual(LocalDate.now());
    }

    public String getFormattedReviewedAt() {
        if (reviewedAt == null) return "";
        return reviewedAt.toLocalDateTime().toLocalDate().format(DISPLAY_DATE_FORMAT);
    }

    public String getRatingStars() {
        if (rating == null || rating < 1) return "";
        int r = Math.min(5, Math.max(1, rating));
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < r; i++) sb.append("★");
        for (int i = r; i < 5; i++) sb.append("☆");
        return sb.toString();
    }

    public String getPerformanceLabel() {
        if (rating == null) return "Not Rated";
        return switch (rating) {
            case 5 -> "Outstanding";
            case 4 -> "Very Good";
            case 3 -> "Good";
            case 2 -> "Needs Improvement";
            case 1 -> "Poor";
            default -> "Rated (" + rating + "/5)";
        };
    }
}
