package model;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

public class TeamMember {
    public enum Status { ACTIVE, INACTIVE }

    private final int id;
    private final int teamId;
    private final String employeeId;
    private final String employeeName;     // joined in from employees
    private final String designation;      // uses employees.department for now (no separate field yet)
    private final LocalDate joinedDate;
    private final Status status;

    public TeamMember(int id, int teamId, String employeeId, String employeeName, String designation,
                      LocalDate joinedDate, Status status) {
        this.id = id;
        this.teamId = teamId;
        this.employeeId = employeeId;
        this.employeeName = employeeName;
        this.designation = designation;
        this.joinedDate = joinedDate;
        this.status = status;
    }

    public int getId() { return id; }
    public int getTeamId() { return teamId; }
    public String getEmployeeId() { return employeeId; }
    public String getEmployeeName() { return employeeName; }
    public String getDesignation() { return designation; }
    public LocalDate getJoinedDate() { return joinedDate; }
    public Status getStatus() { return status; }

    public String getJoinedDateText() {
        return joinedDate == null ? "--" : joinedDate.format(DateTimeFormatter.ofPattern("dd-MM-yyyy"));
    }
}