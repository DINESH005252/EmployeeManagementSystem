package model;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

/**
 * Encapsulates report records, data transfer objects, and summary statistics
 * for Employee, Attendance, Leave, and Task reports.
 */
public class Report implements Serializable {
    private static final long serialVersionUID = 1L;

    public static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd-MM-yyyy");
    public static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("hh:mm a", Locale.ENGLISH);

    // ==========================================
    // 1. Employee Report Item & Summary
    // ==========================================
    public static class EmployeeItem implements Serializable {
        private String employeeId;
        private String name;
        private String email;
        private String department;
        private String role;
        private String status;
        private String managerId;
        private String teamName;

        public EmployeeItem() {}

        public EmployeeItem(String employeeId, String name, String email, String department, String role, String status) {
            this(employeeId, name, email, department, role, status, null, null);
        }

        public EmployeeItem(String employeeId, String name, String email, String department, String role, String status, String managerId, String teamName) {
            this.employeeId = employeeId;
            this.name = name;
            this.email = email;
            this.department = department != null ? department.toUpperCase() : "GENERAL";
            this.role = role != null ? role.toUpperCase() : "EMPLOYEE";
            this.status = status != null ? status.toUpperCase() : "ACTIVE";
            this.managerId = managerId;
            this.teamName = teamName;
        }

        public String getEmployeeId() { return employeeId; }
        public void setEmployeeId(String employeeId) { this.employeeId = employeeId; }
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        public String getEmail() { return email != null ? email : "--"; }
        public void setEmail(String email) { this.email = email; }
        public String getDepartment() { return department != null ? department.toUpperCase() : "GENERAL"; }
        public void setDepartment(String department) { this.department = department; }
        public String getRole() { return role != null ? role.toUpperCase() : "EMPLOYEE"; }
        public void setRole(String role) { this.role = role; }
        public String getStatus() { return status != null ? status.toUpperCase() : "ACTIVE"; }
        public void setStatus(String status) { this.status = status; }
        public String getManagerId() { return managerId != null ? managerId : ""; }
        public void setManagerId(String managerId) { this.managerId = managerId; }
        public String getTeamName() { return teamName != null ? teamName : ""; }
        public void setTeamName(String teamName) { this.teamName = teamName; }

        public boolean isActive() {
            return "ACTIVE".equalsIgnoreCase(status);
        }
    }

    public static class ManagerItem implements Serializable {
        private String managerId;
        private String name;
        private String department;
        private String teamName;
        private int memberCount;

        public ManagerItem() {}

        public ManagerItem(String managerId, String name, String department, String teamName, int memberCount) {
            this.managerId = managerId;
            this.name = name;
            this.department = department != null ? department.toUpperCase() : "GENERAL";
            this.teamName = teamName != null ? teamName : "Team";
            this.memberCount = memberCount;
        }

        public String getManagerId() { return managerId; }
        public void setManagerId(String managerId) { this.managerId = managerId; }
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        public String getDepartment() { return department; }
        public void setDepartment(String department) { this.department = department; }
        public String getTeamName() { return teamName; }
        public void setTeamName(String teamName) { this.teamName = teamName; }
        public int getMemberCount() { return memberCount; }
        public void setMemberCount(int memberCount) { this.memberCount = memberCount; }
    }

    public static class EmployeeSummary implements Serializable {
        private int totalCount;
        private int activeCount;
        private int inactiveCount;
        private Map<String, Integer> departmentCounts = new LinkedHashMap<>();

        public int getTotalCount() { return totalCount; }
        public void setTotalCount(int totalCount) { this.totalCount = totalCount; }
        public int getActiveCount() { return activeCount; }
        public void setActiveCount(int activeCount) { this.activeCount = activeCount; }
        public int getInactiveCount() { return inactiveCount; }
        public void setInactiveCount(int inactiveCount) { this.inactiveCount = inactiveCount; }
        public Map<String, Integer> getDepartmentCounts() { return departmentCounts; }
        public void setDepartmentCounts(Map<String, Integer> departmentCounts) { this.departmentCounts = departmentCounts; }
    }

    // ==========================================
    // 2. Attendance Report Item & Summary
    // ==========================================
    public static class AttendanceItem implements Serializable {
        private int id;
        private String employeeId;
        private String employeeName;
        private String department;
        private LocalDate date;
        private LocalTime checkInTime;
        private LocalTime checkOutTime;
        private String status;
        private Integer workedMinutes;
        private String leaveType;
        private String reason;

        public int getId() { return id; }
        public void setId(int id) { this.id = id; }
        public String getAttendanceId() { return String.format("ATT%03d", id); }
        public String getEmployeeId() { return employeeId; }
        public void setEmployeeId(String employeeId) { this.employeeId = employeeId; }
        public String getEmployeeName() { return employeeName != null ? employeeName : employeeId; }
        public void setEmployeeName(String employeeName) { this.employeeName = employeeName; }
        public String getDepartment() { return department != null ? department.toUpperCase() : "GENERAL"; }
        public void setDepartment(String department) { this.department = department; }
        public LocalDate getDate() { return date; }
        public void setDate(LocalDate date) { this.date = date; }
        public LocalTime getCheckInTime() { return checkInTime; }
        public void setCheckInTime(LocalTime checkInTime) { this.checkInTime = checkInTime; }
        public LocalTime getCheckOutTime() { return checkOutTime; }
        public void setCheckOutTime(LocalTime checkOutTime) { this.checkOutTime = checkOutTime; }
        public String getStatus() { return status != null ? status.toUpperCase() : "PRESENT"; }
        public void setStatus(String status) { this.status = status; }
        public Integer getWorkedMinutes() { return workedMinutes; }
        public void setWorkedMinutes(Integer workedMinutes) { this.workedMinutes = workedMinutes; }
        public String getLeaveType() { return leaveType; }
        public void setLeaveType(String leaveType) { this.leaveType = leaveType; }
        public String getReason() { return reason; }
        public void setReason(String reason) { this.reason = reason; }

        public String getDateText() {
            return date != null ? date.format(DATE_FMT) : "--";
        }
        public String getCheckInText() {
            return checkInTime != null ? checkInTime.format(TIME_FMT) : "--";
        }
        public String getCheckOutText() {
            return checkOutTime != null ? checkOutTime.format(TIME_FMT) : "--";
        }
        public String getWorkedText() {
            if (workedMinutes == null || workedMinutes <= 0) return "--";
            return (workedMinutes / 60) + "h " + (workedMinutes % 60) + "m";
        }
        public boolean isLate() {
            return checkInTime != null && checkInTime.isAfter(LocalTime.of(9, 30));
        }
    }

    public static class AttendanceSummary implements Serializable {
        private int totalCount;
        private int presentCount;
        private int absentCount;
        private int halfDayCount;
        private int leaveCount;
        private int lateCount;

        public int getTotalCount() { return totalCount; }
        public void setTotalCount(int totalCount) { this.totalCount = totalCount; }
        public int getPresentCount() { return presentCount; }
        public void setPresentCount(int presentCount) { this.presentCount = presentCount; }
        public int getAbsentCount() { return absentCount; }
        public void setAbsentCount(int absentCount) { this.absentCount = absentCount; }
        public int getHalfDayCount() { return halfDayCount; }
        public void setHalfDayCount(int halfDayCount) { this.halfDayCount = halfDayCount; }
        public int getLeaveCount() { return leaveCount; }
        public void setLeaveCount(int leaveCount) { this.leaveCount = leaveCount; }
        public int getLateCount() { return lateCount; }
        public void setLateCount(int lateCount) { this.lateCount = lateCount; }
    }

    // ==========================================
    // 3. Leave Report Item & Summary
    // ==========================================
    public static class LeaveItem implements Serializable {
        private int id;
        private String employeeId;
        private String employeeName;
        private String department;
        private String leaveType;
        private LocalDate fromDate;
        private LocalDate toDate;
        private int workingDays;
        private String reason;
        private String status;
        private String decidedBy;
        private LocalDateTime decidedAt;
        private String decisionReason;

        public int getId() { return id; }
        public void setId(int id) { this.id = id; }
        public String getRequestId() { return String.format("LR%03d", id); }
        public String getEmployeeId() { return employeeId; }
        public void setEmployeeId(String employeeId) { this.employeeId = employeeId; }
        public String getEmployeeName() { return employeeName != null ? employeeName : employeeId; }
        public void setEmployeeName(String employeeName) { this.employeeName = employeeName; }
        public String getDepartment() { return department != null ? department.toUpperCase() : "GENERAL"; }
        public void setDepartment(String department) { this.department = department; }
        public String getLeaveType() { return leaveType != null ? leaveType.toUpperCase() : "CASUAL"; }
        public void setLeaveType(String leaveType) { this.leaveType = leaveType; }
        public LocalDate getFromDate() { return fromDate; }
        public void setFromDate(LocalDate fromDate) { this.fromDate = fromDate; }
        public LocalDate getToDate() { return toDate; }
        public void setToDate(LocalDate toDate) { this.toDate = toDate; }
        public int getWorkingDays() { return workingDays; }
        public void setWorkingDays(int workingDays) { this.workingDays = workingDays; }
        public String getReason() { return reason != null ? reason : ""; }
        public void setReason(String reason) { this.reason = reason; }
        public String getStatus() { return status != null ? status.toUpperCase() : "PENDING"; }
        public void setStatus(String status) { this.status = status; }
        public String getDecidedBy() { return decidedBy != null ? decidedBy : "--"; }
        public void setDecidedBy(String decidedBy) { this.decidedBy = decidedBy; }
        public LocalDateTime getDecidedAt() { return decidedAt; }
        public void setDecidedAt(LocalDateTime decidedAt) { this.decidedAt = decidedAt; }
        public String getDecisionReason() { return decisionReason != null ? decisionReason : "--"; }
        public void setDecisionReason(String decisionReason) { this.decisionReason = decisionReason; }

        public String getFromText() {
            return fromDate != null ? fromDate.format(DATE_FMT) : "--";
        }
        public String getToText() {
            return toDate != null ? toDate.format(DATE_FMT) : "--";
        }
    }

    public static class LeaveSummary implements Serializable {
        private int totalCount;
        private int pendingCount;
        private int approvedCount;
        private int rejectedCount;
        private int cancelledCount;

        public int getTotalCount() { return totalCount; }
        public void setTotalCount(int totalCount) { this.totalCount = totalCount; }
        public int getPendingCount() { return pendingCount; }
        public void setPendingCount(int pendingCount) { this.pendingCount = pendingCount; }
        public int getApprovedCount() { return approvedCount; }
        public void setApprovedCount(int approvedCount) { this.approvedCount = approvedCount; }
        public int getRejectedCount() { return rejectedCount; }
        public void setRejectedCount(int rejectedCount) { this.rejectedCount = rejectedCount; }
        public int getCancelledCount() { return cancelledCount; }
        public void setCancelledCount(int cancelledCount) { this.cancelledCount = cancelledCount; }
    }

    // ==========================================
    // 4. Task Report Item & Summary
    // ==========================================
    public static class TaskItem implements Serializable {
        private int id;
        private String taskTitle;
        private String description;
        private String department;
        private String assignedTo;
        private String assignedToName;
        private String createdBy;
        private String priority;
        private LocalDate startDate;
        private LocalDate dueDate;
        private String status;
        private Integer rating;
        private String feedback;

        public int getId() { return id; }
        public void setId(int id) { this.id = id; }
        public String getFormattedId() { return String.format("TSK%03d", id); }
        public String getTaskTitle() { return taskTitle != null ? taskTitle : "Task " + id; }
        public void setTaskTitle(String taskTitle) { this.taskTitle = taskTitle; }
        public String getDescription() { return description != null ? description : ""; }
        public void setDescription(String description) { this.description = description; }
        public String getDepartment() { return department != null ? department.toUpperCase() : "GENERAL"; }
        public void setDepartment(String department) { this.department = department; }
        public String getAssignedTo() { return assignedTo; }
        public void setAssignedTo(String assignedTo) { this.assignedTo = assignedTo; }
        public String getAssignedToName() { return assignedToName != null ? assignedToName : assignedTo; }
        public void setAssignedToName(String assignedToName) { this.assignedToName = assignedToName; }
        public String getCreatedBy() { return createdBy; }
        public void setCreatedBy(String createdBy) { this.createdBy = createdBy; }
        public String getPriority() { return priority != null ? priority.toUpperCase() : "MEDIUM"; }
        public void setPriority(String priority) { this.priority = priority; }
        public LocalDate getStartDate() { return startDate; }
        public void setStartDate(LocalDate startDate) { this.startDate = startDate; }
        public LocalDate getDueDate() { return dueDate; }
        public void setDueDate(LocalDate dueDate) { this.dueDate = dueDate; }
        public String getStatus() { return status != null ? status.toUpperCase() : "ASSIGNED"; }
        public void setStatus(String status) { this.status = status; }
        public Integer getRating() { return rating; }
        public void setRating(Integer rating) { this.rating = rating; }
        public String getFeedback() { return feedback != null ? feedback : ""; }
        public void setFeedback(String feedback) { this.feedback = feedback; }

        public String getStartDateText() {
            return startDate != null ? startDate.format(DATE_FMT) : "--";
        }
        public String getDueDateText() {
            return dueDate != null ? dueDate.format(DATE_FMT) : "--";
        }
        public boolean isOverdue() {
            return dueDate != null && dueDate.isBefore(LocalDate.now()) && !"COMPLETED".equalsIgnoreCase(status);
        }
    }

    public static class TaskSummary implements Serializable {
        private int totalCount;
        private int assignedCount;
        private int inProgressCount;
        private int onHoldCount;
        private int completedCount;
        private int cancelledCount;
        private int completionRate;

        public int getTotalCount() { return totalCount; }
        public void setTotalCount(int totalCount) { this.totalCount = totalCount; }
        public int getAssignedCount() { return assignedCount; }
        public void setAssignedCount(int assignedCount) { this.assignedCount = assignedCount; }
        public int getInProgressCount() { return inProgressCount; }
        public void setInProgressCount(int inProgressCount) { this.inProgressCount = inProgressCount; }
        public int getOnHoldCount() { return onHoldCount; }
        public void setOnHoldCount(int onHoldCount) { this.onHoldCount = onHoldCount; }
        public int getCompletedCount() { return completedCount; }
        public void setCompletedCount(int completedCount) { this.completedCount = completedCount; }
        public int getCancelledCount() { return cancelledCount; }
        public void setCancelledCount(int cancelledCount) { this.cancelledCount = cancelledCount; }
        public int getCompletionRate() { return completionRate; }
        public void setCompletionRate(int completionRate) { this.completionRate = completionRate; }
    }

    // ==========================================
    // 5. Reports Dashboard Overview Summary
    // ==========================================
    public static class DashboardSummary implements Serializable {
        private int totalEmployees;
        private int activeEmployees;
        private int todayAttendanceCount;
        private int pendingLeavesCount;
        private int activeTasksCount;
        private int totalTasksCount;

        public int getTotalEmployees() { return totalEmployees; }
        public void setTotalEmployees(int totalEmployees) { this.totalEmployees = totalEmployees; }
        public int getActiveEmployees() { return activeEmployees; }
        public void setActiveEmployees(int activeEmployees) { this.activeEmployees = activeEmployees; }
        public int getTodayAttendanceCount() { return todayAttendanceCount; }
        public void setTodayAttendanceCount(int todayAttendanceCount) { this.todayAttendanceCount = todayAttendanceCount; }
        public int getPendingLeavesCount() { return pendingLeavesCount; }
        public void setPendingLeavesCount(int pendingLeavesCount) { this.pendingLeavesCount = pendingLeavesCount; }
        public int getActiveTasksCount() { return activeTasksCount; }
        public void setActiveTasksCount(int activeTasksCount) { this.activeTasksCount = activeTasksCount; }
        public int getTotalTasksCount() { return totalTasksCount; }
        public void setTotalTasksCount(int totalTasksCount) { this.totalTasksCount = totalTasksCount; }
    }
}

