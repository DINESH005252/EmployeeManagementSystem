package model;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class Team {
    public enum Status { ACTIVE, INACTIVE }

    private int id;
    private String teamName;
    private String description;
    private String department;
    private String managerId;        // employees.employee_id, nullable
    private String managerName;      // joined in from employees, for display only
    private Status status;
    private LocalDateTime createdAt;
    private int memberCount;         // filled in by reports; not a real column

    public Team(int id, String teamName, String description, String department,
               String managerId, String managerName, Status status, LocalDateTime createdAt) {
        this.id = id;
        this.teamName = teamName;
        this.description = description;
        this.department = department;
        this.managerId = managerId;
        this.managerName = managerName;
        this.status = status;
        this.createdAt = createdAt;
    }

    public int getId() { return id; }
    public String getTeamId() { return String.format("TEAM%03d", id); }
    public String getTeamName() { return teamName; }
    public String getName() { return teamName; }
    public String getDescription() { return description; }
    public String getDepartment() { return department; }
    public String getManagerId() { return managerId; }
    public String getManagerName() { return managerName == null ? "--" : managerName; }
    public Status getStatus() { return status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public int getMemberCount() { return memberCount; }
    public void setMemberCount(int n) { this.memberCount = n; }

    public String getCreatedAtText() {
        return createdAt == null ? "--" : createdAt.format(DateTimeFormatter.ofPattern("dd-MM-yyyy"));
    }
}