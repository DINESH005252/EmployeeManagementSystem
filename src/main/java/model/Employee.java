package model;

public class Employee {
    public enum Status { ACTIVE, INACTIVE }

    private final String id;
    private final String name;
    private final String department;
    private final String designation;
    private Status status;

    public Employee(String id, String name, String department, Status status) {
        this(id, name, department, "—", status);
    }

    public Employee(String id, String name, String department, String designation, Status status) {
        this.id = id;
        this.name = name;
        this.department = department;
        this.designation = (designation != null && !designation.trim().isEmpty()) ? designation.trim() : "—";
        this.status = status;
    }

    public String getId() { return id; }
    public String getEmployeeId() { return id; }
    public String getName() { return name; }
    public String getDepartment() { return department; }
    public String getDesignation() { return designation != null ? designation : "—"; }
    public Status getStatus() { return status; }
    public void setStatus(Status status) { this.status = status; }
    public boolean isActive() { return status == Status.ACTIVE; }
}
