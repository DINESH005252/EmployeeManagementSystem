package model;

public class Manager {
    public enum Status { ACTIVE, INACTIVE }

    private final String id;
    private final String name;
    private final String department;
    private final String email;
    private final Status status;

    public Manager(String id, String name, String department, String email, Status status) {
        this.id = id;
        this.name = name;
        this.department = department;
        this.email = email;
        this.status = status;
    }

    public String getId() { return id; }
    public String getManagerId() { return id; }
    public String getName() { return name; }
    public String getDepartment() { return department; }
    public String getEmail() { return email; }
    public Status getStatus() { return status; }
    public boolean isActive() { return status == Status.ACTIVE; }
}