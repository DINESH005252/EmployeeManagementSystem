package service;

import dao.EmployeeDAO;
import dao.ManagerDAO;
import dao.TaskDAO;
import dao.TeamDAO;
import dao.TeamMemberDAO;
import model.Employee;
import model.EmployeePerformance;
import model.Manager;
import model.ManagerReviewSummary;
import model.Task;
import model.TaskGroup;
import model.Team;
import model.TeamMember;
import model.User;

import java.util.LinkedHashMap;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class TaskService {
    private final TaskDAO taskDAO;
    private final EmployeeDAO employeeDAO;
    private final TeamDAO teamDAO;
    private final TeamMemberDAO teamMemberDAO;
    private final ManagerDAO managerDAO;

    private static final DateTimeFormatter ISO_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final DateTimeFormatter DISPLAY_FORMAT = DateTimeFormatter.ofPattern("dd-MM-yyyy");

    public TaskService() {
        this.taskDAO = new TaskDAO();
        this.employeeDAO = new EmployeeDAO();
        this.teamDAO = new TeamDAO();
        this.teamMemberDAO = new TeamMemberDAO();
        this.managerDAO = new ManagerDAO();
    }

    public TaskService(TaskDAO taskDAO, EmployeeDAO employeeDAO) {
        this.taskDAO = taskDAO;
        this.employeeDAO = employeeDAO;
        this.teamDAO = new TeamDAO();
        this.teamMemberDAO = new TeamMemberDAO();
        this.managerDAO = new ManagerDAO();
    }

    public Task getTaskById(int id) {
        return taskDAO.getTaskById(id);
    }

    public List<Task> getAllTasks() {
        return taskDAO.getAllTasks();
    }

    public List<Task> getAllTasks(String sort, String order) {
        return taskDAO.getAllTasks(sort, order);
    }

    public List<Task> getTasksByEmployee(String employeeId) {
        return taskDAO.getTasksByEmployee(employeeId);
    }

    public List<Task> getTasksByDepartment(String dept) {
        return taskDAO.getTasksByDepartment(dept);
    }

    public List<Employee> getActiveEmployees() {
        return employeeDAO.findActive();
    }

    public Map<String, Integer> getOverallStats() {
        return taskDAO.getTaskStatistics();
    }

    public Map<String, Integer> getEmployeeStats(String employeeId) {
        return taskDAO.getTaskStatisticsByEmployee(employeeId);
    }

    public List<Task> searchTasks(String keyword, String status, String priority, String department) {
        return taskDAO.searchTasks(keyword, status, priority, department);
    }

    public List<Task> searchTasks(String keyword, String status, String priority, String department, String sort, String order) {
        return taskDAO.searchTasks(keyword, status, priority, department, sort, order);
    }

    /**
     * Validates and creates a new task.
     */
    public int createTask(String title, String description, String assignedTo, String createdBy,
                          String department, String priority, String startDateStr, String dueDateStr) {
        return createTask(title, description, assignedTo, createdBy, department, priority, startDateStr, dueDateStr, null);
    }

    public int createTask(String title, String description, String assignedTo, String createdBy,
                          String department, String priority, String startDateStr, String dueDateStr,
                          String workFile) {
        validateTaskFields(title, description, assignedTo, priority, startDateStr, dueDateStr);

        LocalDate start = parseDate(startDateStr);
        LocalDate due = parseDate(dueDateStr);

        if (due.isBefore(start)) {
            throw new IllegalArgumentException("Due date cannot be before start date.");
        }

        String dept = (department != null && !department.trim().isEmpty())
                ? department.trim()
                : lookupEmployeeDepartment(assignedTo);

        Task task = new Task();
        task.setTaskTitle(title.trim());
        task.setDescription(description != null ? description.trim() : "");
        task.setAssignedTo(assignedTo.trim());
        task.setCreatedBy(createdBy != null ? createdBy.trim() : "ADMIN");
        task.setDepartment(dept);
        task.setPriority(priority.trim().toUpperCase());
        task.setStartDate(start);
        task.setDueDate(due);
        task.setStatus(Task.STATUS_ASSIGNED);
        task.setWorkFile(workFile);

        return taskDAO.createTask(task);
    }

    /**
     * Validates and updates task details (Manager / Admin).
     */
    public void updateTask(int id, String title, String description, String assignedTo,
                           String department, String priority, String startDateStr, String dueDateStr,
                           String status) {
        updateTask(id, title, description, assignedTo, department, priority, startDateStr, dueDateStr, status, null);
    }

    public void updateTask(int id, String title, String description, String assignedTo,
                           String department, String priority, String startDateStr, String dueDateStr,
                           String status, String workFile) {
        Task existing = taskDAO.getTaskById(id);
        if (existing == null) {
            throw new IllegalArgumentException("Task not found.");
        }

        validateTaskFields(title, description, assignedTo, priority, startDateStr, dueDateStr);

        LocalDate start = parseDate(startDateStr);
        LocalDate due = parseDate(dueDateStr);

        if (due.isBefore(start)) {
            throw new IllegalArgumentException("Due date cannot be before start date.");
        }

        String targetStatus = (status != null && !status.trim().isEmpty())
                ? status.trim().toUpperCase()
                : existing.getStatus();

        existing.setTaskTitle(title.trim());
        existing.setDescription(description != null ? description.trim() : "");
        existing.setAssignedTo(assignedTo.trim());
        existing.setDepartment(department != null ? department.trim() : existing.getDepartment());
        existing.setPriority(priority.trim().toUpperCase());
        existing.setStartDate(start);
        existing.setDueDate(due);
        existing.setStatus(targetStatus);
        if (workFile != null && !workFile.trim().isEmpty()) {
            existing.setWorkFile(workFile.trim());
        }

        taskDAO.updateTask(existing);
    }

    /**
     * Updates task status and optional comment with role-based restriction enforcement.
     */
    public void updateTaskStatus(int id, String newStatus, String comment, User user) {
        updateTaskStatus(id, newStatus, comment, user, null);
    }

    public void updateTaskStatus(int id, String newStatus, String comment, User user, String workProofFile) {
        Task task = taskDAO.getTaskById(id);
        if (task == null) {
            throw new IllegalArgumentException("Task not found.");
        }

        if (newStatus == null || newStatus.trim().isEmpty()) {
            throw new IllegalArgumentException("Please select a status.");
        }

        String targetStatus = newStatus.trim().toUpperCase();

        if (comment != null && comment.length() > 1000) {
            throw new IllegalArgumentException("Comment cannot exceed 1000 characters.");
        }

        // Employee restrictions
        if (user.getRole() == User.Role.EMPLOYEE) {
            // Verify employee is assigned to this task
            if (!task.getAssignedTo().equalsIgnoreCase(user.getEmployeeId())) {
                throw new IllegalStateException("You can only update tasks assigned to you.");
            }

            if (!task.canEmployeeTransitionTo(targetStatus)) {
                throw new IllegalArgumentException("Invalid status transition from " + task.getStatus()
                        + " to " + targetStatus + ". Employees can transition ASSIGNED -> IN_PROGRESS -> COMPLETED, or IN_PROGRESS <-> ON_HOLD.");
            }
        }

        taskDAO.updateTaskStatus(id, targetStatus, comment != null ? comment.trim() : "", workProofFile);
    }

    /**
     * Manager reviews completed task, evaluates work proof, assigns rating (1-5) and feedback.
     * Problem A1: Rejects review if the employee assignment is not completed.
     * Problem A7, C3: Validates rating (1-5) and feedback requirement for low ratings.
     */
    public void reviewTask(int id, int rating, String feedback, String managerId) {
        Task task = taskDAO.getTaskById(id);
        if (task == null) {
            throw new IllegalArgumentException("Task not found.");
        }
        // Problem A1: Reject rating if assignment is not completed
        if (!Task.STATUS_COMPLETED.equalsIgnoreCase(task.getStatus())) {
            throw new IllegalStateException("Task assignment must be completed before submitting a performance review.");
        }
        if (rating < 1 || rating > 5) {
            throw new IllegalArgumentException("Rating must be between 1 and 5 stars.");
        }
        if (feedback == null || feedback.trim().isEmpty()) {
            throw new IllegalArgumentException("Feedback cannot be empty.");
        }
        if ((rating == 1 || rating == 2) && feedback.trim().length() < 5) {
            throw new IllegalArgumentException("Detailed feedback is required when assigning a rating of 1 or 2 stars.");
        }
        if (feedback.trim().length() > 1000) {
            throw new IllegalArgumentException("Feedback cannot exceed 1000 characters.");
        }
        taskDAO.reviewTask(id, rating, feedback.trim(), managerId);
    }

    public List<EmployeePerformance> getEmployeePerformanceList(String department, String keyword) {
        return taskDAO.getEmployeePerformanceList(department, keyword);
    }

    public Map<String, Object> getOrgPerformanceStats() {
        return taskDAO.getOrgPerformanceStats();
    }

    public Map<String, Object> getPerformanceStats(String managerId) {
        return taskDAO.getPerformanceStats(managerId);
    }

    public void deleteTask(int id) {
        Task task = taskDAO.getTaskById(id);
        if (task == null) {
            throw new IllegalArgumentException("Task not found.");
        }
        if (task.isReviewed() || task.hasWorkProofFile()) {
            throw new IllegalStateException("Cannot delete task: It already has an employee work proof or a submitted performance review.");
        }
        taskDAO.deleteTask(id);
    }

    private void validateTaskFields(String title, String description, String assignedTo,
                                    String priority, String startDateStr, String dueDateStr) {
        if (title == null || title.trim().isEmpty()) {
            throw new IllegalArgumentException("Task title cannot be empty.");
        }
        if (title.trim().length() > 150) {
            throw new IllegalArgumentException("Task title cannot exceed 150 characters.");
        }
        if (description != null && description.length() > 1000) {
            throw new IllegalArgumentException("Description cannot exceed 1000 characters.");
        }
        if (assignedTo == null || assignedTo.trim().isEmpty()) {
            throw new IllegalArgumentException("Employee must be selected.");
        }
        if (priority == null || priority.trim().isEmpty()) {
            throw new IllegalArgumentException("Priority must be selected.");
        }
        if (startDateStr == null || startDateStr.trim().isEmpty()) {
            throw new IllegalArgumentException("Start date cannot be empty.");
        }
        if (dueDateStr == null || dueDateStr.trim().isEmpty()) {
            throw new IllegalArgumentException("Due date cannot be empty.");
        }
    }

    public static LocalDate parseDate(String text) {
        if (text == null || text.trim().isEmpty()) return null;
        String trimmed = text.trim();
        try {
            return LocalDate.parse(trimmed, ISO_FORMAT);
        } catch (DateTimeParseException e1) {
            try {
                return LocalDate.parse(trimmed, DISPLAY_FORMAT);
            } catch (DateTimeParseException e2) {
                throw new IllegalArgumentException("Invalid date format: " + text + ". Expected yyyy-MM-dd or dd-MM-yyyy.");
            }
        }
    }

    public String lookupEmployeeDepartment(String empId) {
        if (empId == null) return "General";
        Employee emp = employeeDAO.findById(empId);
        return emp != null && emp.getDepartment() != null ? emp.getDepartment() : "General";
    }

    public List<Team> getTeamsForManager(String managerId) {
        if (managerId == null || managerId.trim().isEmpty()) {
            return Collections.emptyList();
        }
        return teamDAO.findByManager(managerId.trim());
    }

    public List<TeamMember> getActiveMembersForTeam(int teamId) {
        return teamMemberDAO.findActiveByTeam(teamId);
    }

    public List<Employee> getEmployeesForManager(String managerId) {
        List<Team> teams = getTeamsForManager(managerId);
        Set<String> empIds = new LinkedHashSet<>();
        List<Employee> result = new ArrayList<>();
        for (Team t : teams) {
            List<TeamMember> members = teamMemberDAO.findActiveByTeam(t.getId());
            for (TeamMember tm : members) {
                if (empIds.add(tm.getEmployeeId())) {
                    Employee e = employeeDAO.findById(tm.getEmployeeId());
                    if (e != null) {
                        result.add(e);
                    }
                }
            }
        }
        return result;
    }

    public boolean isEmployeeInManagerTeams(String managerId, String employeeId) {
        if (managerId == null || managerId.trim().isEmpty()) {
            return true; // Non-manager (e.g. Admin fallback)
        }
        if (employeeId == null || employeeId.trim().isEmpty()) {
            return false;
        }
        List<Team> teams = getTeamsForManager(managerId);
        for (Team t : teams) {
            if (teamMemberDAO.isActiveMember(t.getId(), employeeId.trim())) {
                return true;
            }
        }
        return false;
    }

    public List<Task> getDetailedTaskReviews(String managerId, String department, String rating, String keyword) {
        return taskDAO.getDetailedTaskReviews(managerId, department, "ALL", rating, keyword);
    }

    public List<Task> getDetailedTaskReviews(String managerId, String department, String reviewStatus, String rating, String keyword) {
        return taskDAO.getDetailedTaskReviews(managerId, department, reviewStatus, rating, keyword);
    }

    public List<TaskGroup> getGroupedTaskReviews(String managerId, String department, String rating, String keyword) {
        return getGroupedTaskReviews(managerId, department, "ALL", rating, keyword);
    }

    public List<TaskGroup> getGroupedTaskReviews(String managerId, String department, String reviewStatus, String rating, String keyword) {
        List<Task> all = getDetailedTaskReviews(managerId, department, reviewStatus, rating, keyword);
        Map<String, TaskGroup> map = new LinkedHashMap<>();
        for (Task t : all) {
            String titleKey = (t.getTaskTitle() != null && !t.getTaskTitle().trim().isEmpty())
                    ? t.getTaskTitle().trim()
                    : ("TASK" + String.format("%03d", t.getId()));
            String key = titleKey.toLowerCase();
            TaskGroup group = map.get(key);
            if (group == null) {
                group = new TaskGroup(titleKey);
                map.put(key, group);
            }
            group.addTask(t);
        }
        List<TaskGroup> groups = new ArrayList<>(map.values());
        // Problem B1: Sort task groups consistently by min task ID so Task 1 -> Task 1, task 2 -> Task 2, task3 -> Task 3
        groups.sort(java.util.Comparator.comparingInt(TaskGroup::getMinTaskId));
        return groups;
    }

    public List<ManagerReviewSummary> getManagerReviewSummaries(String managerFilter, String departmentFilter, String keyword) {
        return taskDAO.getManagerReviewSummaries(managerFilter, departmentFilter, keyword);
    }

    public List<ManagerReviewSummary> getManagerReviewSummaries(String managerFilter, String departmentFilter, String ratingFilter, String keyword) {
        return taskDAO.getManagerReviewSummaries(managerFilter, departmentFilter, ratingFilter, keyword);
    }

    public List<Manager> getActiveManagers() {
        return managerDAO.findActive();
    }

    public List<String> getDistinctDepartments() {
        return taskDAO.getDistinctDepartments();
    }
}
