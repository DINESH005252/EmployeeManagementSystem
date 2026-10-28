package dao;

import model.EmployeePerformance;
import model.ManagerReviewSummary;
import model.Task;
import util.DBConnection;

import java.sql.*;
import java.time.LocalDate;
import java.util.*;

public class TaskDAO {

    static {
        initTable();
    }

    public static void initTable() {
        String sql = "CREATE TABLE IF NOT EXISTS tasks ("
                + " id INT PRIMARY KEY AUTO_INCREMENT,"
                + " task_title VARCHAR(150) NOT NULL,"
                + " description VARCHAR(1000),"
                + " assigned_to VARCHAR(50) NOT NULL,"
                + " created_by VARCHAR(50) NOT NULL,"
                + " department VARCHAR(100),"
                + " priority VARCHAR(20) DEFAULT 'MEDIUM',"
                + " start_date DATE NOT NULL,"
                + " due_date DATE NOT NULL,"
                + " status VARCHAR(30) DEFAULT 'ASSIGNED',"
                + " employee_comment VARCHAR(1000),"
                + " work_file VARCHAR(255) DEFAULT NULL,"
                + " work_proof_file VARCHAR(255) DEFAULT NULL,"
                + " rating INT DEFAULT NULL,"
                + " feedback VARCHAR(1000) DEFAULT NULL,"
                + " reviewed_at TIMESTAMP NULL DEFAULT NULL,"
                + " reviewed_by VARCHAR(50) DEFAULT NULL,"
                + " created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
                + " updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
                + ")";
        try (Connection c = DBConnection.getConnection();
             Statement st = c.createStatement()) {
            st.execute(sql);
            String[] alters = {
                "ALTER TABLE tasks ADD COLUMN work_file VARCHAR(255) DEFAULT NULL",
                "ALTER TABLE tasks ADD COLUMN work_proof_file VARCHAR(255) DEFAULT NULL",
                "ALTER TABLE tasks ADD COLUMN rating INT DEFAULT NULL",
                "ALTER TABLE tasks ADD COLUMN feedback VARCHAR(1000) DEFAULT NULL",
                "ALTER TABLE tasks ADD COLUMN reviewed_at TIMESTAMP NULL DEFAULT NULL",
                "ALTER TABLE tasks ADD COLUMN reviewed_by VARCHAR(50) DEFAULT NULL"
            };
            for (String alt : alters) {
                try { st.execute(alt); } catch (SQLException ignored) {}
            }
        } catch (SQLException e) {
            System.err.println("Task table init warning: " + e.getMessage());
        }
    }

    private static final String SELECT_BASE =
            "SELECT t.id, t.task_title, t.description, t.assigned_to, t.created_by, t.department, "
          + "t.priority, t.start_date, t.due_date, t.status, t.employee_comment, "
          + "t.work_file, t.work_proof_file, t.rating, t.feedback, t.reviewed_at, t.reviewed_by, "
          + "t.created_at, t.updated_at, "
          + "COALESCE(e.name, u1.username, t.assigned_to) AS assigned_to_name, "
          + "COALESCE(m.name, u2.username, t.created_by) AS created_by_name, "
          + "COALESCE(rm.name, u3.username, m.name, u2.username, t.reviewed_by, t.created_by) AS reviewed_by_name "
          + "FROM tasks t "
          + "LEFT JOIN employees e ON e.employee_id = t.assigned_to "
          + "LEFT JOIN users u1 ON CAST(u1.id AS CHAR) = t.assigned_to "
          + "LEFT JOIN managers m ON m.manager_id = t.created_by "
          + "LEFT JOIN users u2 ON (CAST(u2.id AS CHAR) = t.created_by OR u2.username = t.created_by) "
          + "LEFT JOIN managers rm ON rm.manager_id = t.reviewed_by "
          + "LEFT JOIN users u3 ON (CAST(u3.id AS CHAR) = t.reviewed_by OR u3.username = t.reviewed_by) ";

    /**
     * Inserts a new task and returns its generated ID.
     */
    public int createTask(Task task) {
        String sql = "INSERT INTO tasks (task_title, description, assigned_to, created_by, department, "
                   + "priority, start_date, due_date, status, employee_comment, work_file) "
                   + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, task.getTaskTitle());
            ps.setString(2, task.getDescription());
            ps.setString(3, task.getAssignedTo());
            ps.setString(4, task.getCreatedBy());
            ps.setString(5, task.getDepartment());
            ps.setString(6, task.getPriority());
            ps.setDate(7, java.sql.Date.valueOf(task.getStartDate()));
            ps.setDate(8, java.sql.Date.valueOf(task.getDueDate()));
            ps.setString(9, task.getStatus() == null ? Task.STATUS_ASSIGNED : task.getStatus());
            ps.setString(10, task.getEmployeeComment());
            ps.setString(11, task.getWorkFile());

            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    int genId = rs.getInt(1);
                    task.setId(genId);
                    return genId;
                }
            }
            return 0;
        } catch (SQLException e) {
            throw new RuntimeException("Database error creating task: " + e.getMessage(), e);
        }
    }

    /**
     * Finds a task by ID.
     */
    public Task getTaskById(int id) {
        String sql = SELECT_BASE + "WHERE t.id = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error fetching task " + id + ": " + e.getMessage(), e);
        }
    }

    /**
     * Gets all tasks ordered by ID descending.
     */
    public List<Task> getAllTasks() {
        return searchTasks(null, null, null, null, null, null);
    }

    public List<Task> getAllTasks(String sort, String order) {
        return searchTasks(null, null, null, null, sort, order);
    }

    /**
     * Gets tasks assigned to a specific employee (matching employee_id or user id).
     */
    public List<Task> getTasksByEmployee(String employeeId) {
        if (employeeId == null || employeeId.trim().isEmpty()) return Collections.emptyList();
        String sql = SELECT_BASE + "WHERE t.assigned_to = ? OR e.employee_id = ? ORDER BY t.id DESC";
        List<Task> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, employeeId.trim());
            ps.setString(2, employeeId.trim());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
            return list;
        } catch (SQLException e) {
            throw new RuntimeException("Database error fetching tasks for employee: " + e.getMessage(), e);
        }
    }

    /**
     * Gets tasks by department.
     */
    public List<Task> getTasksByDepartment(String dept) {
        if (dept == null || dept.trim().isEmpty()) return getAllTasks();
        String sql = SELECT_BASE + "WHERE LOWER(t.department) = LOWER(?) ORDER BY t.id DESC";
        List<Task> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, dept.trim());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
            return list;
        } catch (SQLException e) {
            throw new RuntimeException("Database error fetching tasks by department: " + e.getMessage(), e);
        }
    }

    /**
     * Updates full task details (by Manager / Admin).
     */
    public boolean updateTask(Task task) {
        String sql = "UPDATE tasks SET task_title = ?, description = ?, assigned_to = ?, department = ?, "
                   + "priority = ?, start_date = ?, due_date = ?, status = ?, "
                   + "work_file = COALESCE(?, work_file) "
                   + "WHERE id = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, task.getTaskTitle());
            ps.setString(2, task.getDescription());
            ps.setString(3, task.getAssignedTo());
            ps.setString(4, task.getDepartment());
            ps.setString(5, task.getPriority());
            ps.setDate(6, java.sql.Date.valueOf(task.getStartDate()));
            ps.setDate(7, java.sql.Date.valueOf(task.getDueDate()));
            ps.setString(8, task.getStatus());
            ps.setString(9, task.getWorkFile());
            ps.setInt(10, task.getId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Database error updating task " + task.getId() + ": " + e.getMessage(), e);
        }
    }

    /**
     * Updates task status and employee comment.
     */
    public boolean updateTaskStatus(int id, String status, String comment) {
        return updateTaskStatus(id, status, comment, null);
    }

    /**
     * Updates task status, employee comment, and attaches work proof file.
     */
    public boolean updateTaskStatus(int id, String status, String comment, String workProofFile) {
        String sql = "UPDATE tasks SET status = ?, employee_comment = ?, "
                   + "work_proof_file = COALESCE(?, work_proof_file) "
                   + "WHERE id = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setString(2, comment);
            ps.setString(3, workProofFile);
            ps.setInt(4, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Database error updating status for task " + id + ": " + e.getMessage(), e);
        }
    }

    /**
     * Manager reviews work proof, assigns rating (1-5) and feedback comment.
     */
    public boolean reviewTask(int id, int rating, String feedback, String reviewedBy) {
        String sql = "UPDATE tasks SET rating = ?, feedback = ?, reviewed_by = ?, reviewed_at = CURRENT_TIMESTAMP WHERE id = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, rating);
            ps.setString(2, feedback);
            ps.setString(3, reviewedBy);
            ps.setInt(4, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Database error reviewing task " + id + ": " + e.getMessage(), e);
        }
    }

    /**
     * Deletes a task by ID.
     */
    public boolean deleteTask(int id) {
        String sql = "DELETE FROM tasks WHERE id = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Database error deleting task " + id + ": " + e.getMessage(), e);
        }
    }

    /**
     * Search and filter tasks by keyword (Task ID, Title, Employee Name),
     * status, priority, and department.
     */
    public List<Task> searchTasks(String keyword, String status, String priority, String department) {
        return searchTasks(keyword, status, priority, department, null, null);
    }

    public List<Task> searchTasks(String keyword, String status, String priority, String department, String sort, String order) {
        StringBuilder sql = new StringBuilder(SELECT_BASE).append("WHERE 1=1 ");
        List<Object> params = new ArrayList<>();

        if (keyword != null && !keyword.trim().isEmpty()) {
            String kw = "%" + keyword.trim().toLowerCase() + "%";
            // Check if user entered "TASK001"
            String numericId = keyword.trim().replaceAll("(?i)^task0*", "");
            if (numericId.matches("\\d+")) {
                sql.append("AND (LOWER(t.task_title) LIKE ? OR LOWER(e.name) LIKE ? OR LOWER(t.assigned_to) LIKE ? OR t.id = ?) ");
                params.add(kw);
                params.add(kw);
                params.add(kw);
                params.add(Integer.parseInt(numericId));
            } else {
                sql.append("AND (LOWER(t.task_title) LIKE ? OR LOWER(e.name) LIKE ? OR LOWER(t.assigned_to) LIKE ?) ");
                params.add(kw);
                params.add(kw);
                params.add(kw);
            }
        }

        if (status != null && !status.trim().isEmpty() && !"ALL".equalsIgnoreCase(status)) {
            String s = status.trim().toUpperCase();
            if ("AWAITING_COMPLETION".equals(s) || "AWAITING".equals(s) || "AWAITING COMPLETION".equals(s)) {
                sql.append("AND t.rating IS NULL AND (t.status IS NULL OR UPPER(t.status) != 'COMPLETED' OR t.work_proof_file IS NULL OR TRIM(t.work_proof_file) = '') ");
            } else if ("PENDING_REVIEW".equals(s) || "PENDING".equals(s) || "PENDING REVIEW".equals(s)) {
                sql.append("AND t.rating IS NULL AND UPPER(t.status) = 'COMPLETED' AND (t.work_proof_file IS NOT NULL AND TRIM(t.work_proof_file) != '') ");
            } else if ("REVIEWED".equals(s)) {
                sql.append("AND t.rating IS NOT NULL ");
            } else {
                sql.append("AND UPPER(t.status) = ? ");
                params.add(s);
            }
        }

        if (priority != null && !priority.trim().isEmpty() && !"ALL".equalsIgnoreCase(priority)) {
            sql.append("AND UPPER(t.priority) = ? ");
            params.add(priority.trim().toUpperCase());
        }

        if (department != null && !department.trim().isEmpty() && !"ALL".equalsIgnoreCase(department)) {
            sql.append("AND LOWER(t.department) = LOWER(?) ");
            params.add(department.trim());
        }

        String orderDir = "asc".equalsIgnoreCase(order) ? "ASC" : "DESC";
        if ("dueDate".equalsIgnoreCase(sort) || "due_date".equalsIgnoreCase(sort)) {
            sql.append("ORDER BY t.due_date ").append(orderDir).append(", t.id ASC");
        } else if ("priority".equalsIgnoreCase(sort)) {
            sql.append("ORDER BY CASE WHEN UPPER(t.priority) = 'HIGH' THEN 1 WHEN UPPER(t.priority) = 'MEDIUM' THEN 2 ELSE 3 END ").append(orderDir);
        } else if ("status".equalsIgnoreCase(sort)) {
            sql.append("ORDER BY t.status ").append(orderDir);
        } else {
            sql.append("ORDER BY t.id ").append("asc".equalsIgnoreCase(order) ? "ASC" : "DESC");
        }

        List<Task> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
            return list;
        } catch (SQLException e) {
            throw new RuntimeException("Database error searching tasks: " + e.getMessage(), e);
        }
    }

    /**
     * Overall task statistics across the organization.
     */
    public Map<String, Integer> getTaskStatistics() {
        return getStatsWithCondition("", null);
    }

    /**
     * Task statistics filtered for a specific employee.
     */
    public Map<String, Integer> getTaskStatisticsByEmployee(String employeeId) {
        return getStatsWithCondition("WHERE assigned_to = ? ", employeeId);
    }

    private Map<String, Integer> getStatsWithCondition(String whereClause, String param) {
        Map<String, Integer> stats = new LinkedHashMap<>();
        stats.put("total", 0);
        stats.put("assigned", 0);
        stats.put("inProgress", 0);
        stats.put("onHold", 0);
        stats.put("completed", 0);
        stats.put("cancelled", 0);

        String sql = "SELECT status, COUNT(*) AS cnt FROM tasks " + whereClause + "GROUP BY status";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            if (param != null && !param.isEmpty()) {
                ps.setString(1, param);
            }
            try (ResultSet rs = ps.executeQuery()) {
                int total = 0;
                while (rs.next()) {
                    String st = rs.getString("status");
                    int count = rs.getInt("cnt");
                    total += count;
                    if (Task.STATUS_ASSIGNED.equalsIgnoreCase(st)) stats.put("assigned", count);
                    else if (Task.STATUS_IN_PROGRESS.equalsIgnoreCase(st)) stats.put("inProgress", count);
                    else if (Task.STATUS_ON_HOLD.equalsIgnoreCase(st)) stats.put("onHold", count);
                    else if (Task.STATUS_COMPLETED.equalsIgnoreCase(st)) stats.put("completed", count);
                    else if (Task.STATUS_CANCELLED.equalsIgnoreCase(st)) stats.put("cancelled", count);
                }
                stats.put("total", total);
            }
        } catch (SQLException e) {
            System.err.println("Error calculating task statistics: " + e.getMessage());
        }
        return stats;
    }

    private List<Task> queryList(String sql) {
        List<Task> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(map(rs));
            return list;
        } catch (SQLException e) {
            throw new RuntimeException("Database error: " + e.getMessage(), e);
        }
    }

    public List<EmployeePerformance> getEmployeePerformanceList(String department, String keyword) {
        StringBuilder sql = new StringBuilder(
            "SELECT e.employee_id, e.name AS employee_name, e.department, "
          + "COUNT(t.id) AS total_tasks, "
          + "SUM(CASE WHEN t.status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed_tasks, "
          + "SUM(CASE WHEN t.rating IS NOT NULL THEN 1 ELSE 0 END) AS reviewed_tasks, "
          + "COALESCE(AVG(t.rating), 0) AS avg_rating "
          + "FROM employees e "
          + "LEFT JOIN tasks t ON (t.assigned_to = e.employee_id) "
          + "WHERE e.status = 'ACTIVE' "
        );
        List<Object> params = new ArrayList<>();
        if (department != null && !department.trim().isEmpty() && !"ALL".equalsIgnoreCase(department)) {
            sql.append("AND LOWER(e.department) = LOWER(?) ");
            params.add(department.trim());
        }
        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND (LOWER(e.name) LIKE ? OR LOWER(e.employee_id) LIKE ?) ");
            String kw = "%" + keyword.trim().toLowerCase() + "%";
            params.add(kw);
            params.add(kw);
        }
        sql.append("GROUP BY e.employee_id, e.name, e.department ");
        sql.append("ORDER BY avg_rating DESC, completed_tasks DESC, e.name ASC");

        List<EmployeePerformance> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    EmployeePerformance ep = new EmployeePerformance();
                    ep.setEmployeeId(rs.getString("employee_id"));
                    ep.setEmployeeName(rs.getString("employee_name"));
                    ep.setDepartment(rs.getString("department"));
                    ep.setTotalTasks(rs.getInt("total_tasks"));
                    ep.setCompletedTasks(rs.getInt("completed_tasks"));
                    ep.setReviewedTasks(rs.getInt("reviewed_tasks"));
                    ep.setAverageRating(rs.getDouble("avg_rating"));
                    list.add(ep);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error calculating employee performance: " + e.getMessage(), e);
        }

        // Fetch reviewed task history for each employee
        for (EmployeePerformance ep : list) {
            List<Task> empTasks = getTasksByEmployee(ep.getEmployeeId());
            ep.setTaskHistory(empTasks);
            for (Task t : empTasks) {
                if (t.hasFeedback()) {
                    ep.setLatestFeedback(t.getFeedback());
                    break;
                }
            }
        }

        return list;
    }

    public Map<String, Object> getOrgPerformanceStats() {
        return getPerformanceStats(null);
    }

    public Map<String, Object> getPerformanceStats(String managerId) {
        Map<String, Object> stats = new HashMap<>();
        stats.put("evaluatedEmployees", 0);
        stats.put("totalReviewed", 0);
        stats.put("orgAvgRating", 0.0);
        stats.put("highPerformers", 0);
        stats.put("pendingReviews", 0);
        stats.put("awaitingCompletion", 0);
        stats.put("uniqueTasks", 0);
        stats.put("totalAssignments", 0);

        StringBuilder sql = new StringBuilder(
            "SELECT COUNT(DISTINCT CASE WHEN rating IS NOT NULL THEN assigned_to END) AS evaluated_emps, "
          + "COUNT(CASE WHEN rating IS NOT NULL THEN 1 END) AS total_reviewed, "
          + "COALESCE(AVG(rating), 0.0) AS org_avg_rating, "
          + "SUM(CASE WHEN rating >= 4 THEN 1 ELSE 0 END) AS high_performers, "
          + "SUM(CASE WHEN rating IS NULL AND UPPER(status) = 'COMPLETED' AND (work_proof_file IS NOT NULL AND TRIM(work_proof_file) != '') THEN 1 ELSE 0 END) AS pending_reviews, "
          + "SUM(CASE WHEN rating IS NULL AND (status IS NULL OR UPPER(status) != 'COMPLETED' OR work_proof_file IS NULL OR TRIM(work_proof_file) = '') THEN 1 ELSE 0 END) AS awaiting_completion, "
          + "COUNT(DISTINCT task_title) AS unique_tasks, "
          + "COUNT(*) AS total_assignments "
          + "FROM tasks "
        );

        boolean hasManager = managerId != null && !managerId.trim().isEmpty() && !"ALL".equalsIgnoreCase(managerId);
        if (hasManager) {
            sql.append("WHERE created_by = ? OR reviewed_by = ? ");
        }

        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql.toString())) {
            if (hasManager) {
                ps.setString(1, managerId.trim());
                ps.setString(2, managerId.trim());
            }
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    stats.put("evaluatedEmployees", rs.getInt("evaluated_emps"));
                    stats.put("totalReviewed", rs.getInt("total_reviewed"));
                    stats.put("orgAvgRating", rs.getDouble("org_avg_rating"));
                    stats.put("highPerformers", rs.getInt("high_performers"));
                    stats.put("pendingReviews", rs.getInt("pending_reviews"));
                    stats.put("awaitingCompletion", rs.getInt("awaiting_completion"));
                    stats.put("uniqueTasks", rs.getInt("unique_tasks"));
                    stats.put("totalAssignments", rs.getInt("total_assignments"));
                }
            }
        } catch (SQLException e) {
            System.err.println("Error calculating performance stats: " + e.getMessage());
        }
        return stats;
    }

    private Task map(ResultSet rs) throws SQLException {
        java.sql.Date start = rs.getDate("start_date");
        java.sql.Date due = rs.getDate("due_date");
        LocalDate sDate = start != null ? start.toLocalDate() : null;
        LocalDate dDate = due != null ? due.toLocalDate() : null;

        Task t = new Task(
                rs.getInt("id"),
                rs.getString("task_title"),
                rs.getString("description"),
                rs.getString("assigned_to"),
                rs.getString("created_by"),
                rs.getString("department"),
                rs.getString("priority"),
                sDate,
                dDate,
                rs.getString("status"),
                rs.getString("employee_comment"),
                rs.getTimestamp("created_at"),
                rs.getTimestamp("updated_at")
        );
        t.setAssignedToName(rs.getString("assigned_to_name"));
        t.setCreatedByName(rs.getString("created_by_name"));
        t.setWorkFile(rs.getString("work_file"));
        t.setWorkProofFile(rs.getString("work_proof_file"));
        Object rObj = rs.getObject("rating");
        t.setRating(rObj != null ? ((Number) rObj).intValue() : null);
        t.setFeedback(rs.getString("feedback"));
        t.setReviewedAt(rs.getTimestamp("reviewed_at"));
        t.setReviewedBy(rs.getString("reviewed_by"));
        t.setReviewedByName(rs.getString("reviewed_by_name"));
        return t;
    }

    public List<Task> getDetailedTaskReviews(String managerId, String department, String rating, String keyword) {
        return getDetailedTaskReviews(managerId, department, "ALL", rating, keyword);
    }

    /**
     * Retrieves all tasks with detailed review evaluations, filterable by manager, department, reviewStatus, rating, and keyword.
     */
    public List<Task> getDetailedTaskReviews(String managerId, String department, String reviewStatus, String rating, String keyword) {
        StringBuilder sql = new StringBuilder(SELECT_BASE);
        sql.append("WHERE 1=1 ");
        List<Object> params = new ArrayList<>();

        if (managerId != null && !managerId.trim().isEmpty() && !"ALL".equalsIgnoreCase(managerId)) {
            sql.append("AND (t.created_by = ? OR t.reviewed_by = ?) ");
            params.add(managerId.trim());
            params.add(managerId.trim());
        }

        if (department != null && !department.trim().isEmpty() && !"ALL".equalsIgnoreCase(department)) {
            sql.append("AND LOWER(t.department) = LOWER(?) ");
            params.add(department.trim());
        }

        if (reviewStatus != null && !reviewStatus.trim().isEmpty() && !"ALL".equalsIgnoreCase(reviewStatus)) {
            String rs = reviewStatus.trim().toUpperCase();
            if ("AWAITING".equals(rs) || "AWAITING COMPLETION".equals(rs)) {
                sql.append("AND t.rating IS NULL AND (t.status IS NULL OR UPPER(t.status) != 'COMPLETED' OR t.work_proof_file IS NULL OR TRIM(t.work_proof_file) = '') ");
            } else if ("PENDING".equals(rs) || "PENDING REVIEW".equals(rs)) {
                sql.append("AND t.rating IS NULL AND UPPER(t.status) = 'COMPLETED' AND (t.work_proof_file IS NOT NULL AND TRIM(t.work_proof_file) != '') ");
            } else if ("REVIEWED".equals(rs)) {
                sql.append("AND t.rating IS NOT NULL ");
            }
        }

        if (rating != null && !rating.trim().isEmpty() && !"ALL".equalsIgnoreCase(rating)) {
            String r = rating.trim().toUpperCase();
            if ("5".equals(r)) {
                sql.append("AND t.rating = 5 ");
            } else if ("4".equals(r)) {
                sql.append("AND t.rating = 4 ");
            } else if ("3".equals(r)) {
                sql.append("AND t.rating = 3 ");
            } else if ("1-2".equals(r)) {
                sql.append("AND t.rating IN (1, 2) ");
            } else if ("REVIEWED".equals(r)) {
                sql.append("AND t.rating IS NOT NULL ");
            } else if ("UNRATED".equals(r)) {
                sql.append("AND t.rating IS NULL ");
            }
        }

        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND (LOWER(t.task_title) LIKE ? OR LOWER(e.name) LIKE ? OR LOWER(t.assigned_to) LIKE ? "
                     + "OR LOWER(m.name) LIKE ? OR LOWER(rm.name) LIKE ? OR LOWER(CAST(t.id AS CHAR)) LIKE ?) ");
            String kw = "%" + keyword.trim().toLowerCase() + "%";
            params.add(kw);
            params.add(kw);
            params.add(kw);
            params.add(kw);
            params.add(kw);
            params.add(kw);
        }

        sql.append("ORDER BY t.id ASC");

        List<Task> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
            return list;
        } catch (SQLException e) {
            throw new RuntimeException("Database error querying detailed task reviews: " + e.getMessage(), e);
        }
    }

    /**
     * Retrieves aggregated evaluation summaries grouped by each manager.
     */
    public List<ManagerReviewSummary> getManagerReviewSummaries(String managerFilter, String departmentFilter, String keyword) {
        return getManagerReviewSummaries(managerFilter, departmentFilter, null, keyword);
    }

    public List<ManagerReviewSummary> getManagerReviewSummaries(String managerFilter, String departmentFilter, String ratingFilter, String keyword) {
        StringBuilder sql = new StringBuilder("SELECT manager_id, name, department, email FROM managers WHERE status = 'ACTIVE' ");
        List<Object> params = new ArrayList<>();

        if (managerFilter != null && !managerFilter.trim().isEmpty() && !"ALL".equalsIgnoreCase(managerFilter)) {
            sql.append("AND manager_id = ? ");
            params.add(managerFilter.trim());
        }

        if (departmentFilter != null && !departmentFilter.trim().isEmpty() && !"ALL".equalsIgnoreCase(departmentFilter)) {
            sql.append("AND LOWER(department) = LOWER(?) ");
            params.add(departmentFilter.trim());
        }

        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND (LOWER(name) LIKE ? OR LOWER(manager_id) LIKE ? OR LOWER(department) LIKE ? "
                     + "OR manager_id IN (SELECT DISTINCT t.created_by FROM tasks t LEFT JOIN employees e ON e.employee_id = t.assigned_to "
                     + "                  WHERE LOWER(t.task_title) LIKE ? OR LOWER(e.name) LIKE ? OR LOWER(t.assigned_to) LIKE ?)) ");
            String kw = "%" + keyword.trim().toLowerCase() + "%";
            params.add(kw);
            params.add(kw);
            params.add(kw);
            params.add(kw);
            params.add(kw);
            params.add(kw);
        }

        sql.append("ORDER BY name ASC");

        List<ManagerReviewSummary> summaries = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ManagerReviewSummary ms = new ManagerReviewSummary(
                            rs.getString("manager_id"),
                            rs.getString("name"),
                            rs.getString("department"),
                            rs.getString("email")
                    );
                    summaries.add(ms);
                }
            }
        } catch (SQLException e) {
            System.err.println("Error fetching managers for review summary: " + e.getMessage());
        }

        List<ManagerReviewSummary> result = new ArrayList<>();
        // For each manager, query their assigned and reviewed tasks
        for (ManagerReviewSummary ms : summaries) {
            List<Task> mgrTasks = getDetailedTaskReviews(ms.getManagerId(), departmentFilter, ratingFilter, keyword);
            if (ratingFilter != null && !ratingFilter.trim().isEmpty() && !"ALL".equalsIgnoreCase(ratingFilter) && mgrTasks.isEmpty()) {
                continue;
            }
            ms.setAllTasks(mgrTasks);

            List<Task> reviewed = new ArrayList<>();
            double ratingSum = 0.0;
            for (Task t : mgrTasks) {
                if (t.isReviewed()) {
                    reviewed.add(t);
                    if (t.getRating() != null) {
                        ratingSum += t.getRating();
                    }
                }
            }
            ms.setReviewedTasks(reviewed);
            ms.setTotalAssignedTasks(mgrTasks.size());
            ms.setTotalReviewedTasks(reviewed.size());
            ms.setAverageRatingGiven(reviewed.isEmpty() ? 0.0 : ratingSum / reviewed.size());
            result.add(ms);
        }

        return result;
    }

    /**
     * Gets all distinct departments across employees, managers, and tasks.
     */
    public List<String> getDistinctDepartments() {
        Set<String> depts = new TreeSet<>(String.CASE_INSENSITIVE_ORDER);
        String sql = "SELECT DISTINCT department FROM employees WHERE department IS NOT NULL AND TRIM(department) != '' "
                   + "UNION SELECT DISTINCT department FROM managers WHERE department IS NOT NULL AND TRIM(department) != '' "
                   + "UNION SELECT DISTINCT department FROM tasks WHERE department IS NOT NULL AND TRIM(department) != ''";
        try (Connection c = DBConnection.getConnection();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                String d = rs.getString(1);
                if (d != null && !d.trim().isEmpty()) {
                    depts.add(d.trim().toUpperCase());
                }
            }
        } catch (SQLException e) {
            System.err.println("Error fetching distinct departments: " + e.getMessage());
        }
        return new ArrayList<>(depts);
    }
}
