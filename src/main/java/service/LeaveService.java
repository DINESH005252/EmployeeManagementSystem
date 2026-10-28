package service;

import dao.LeaveDAO;
import model.Employee;
import model.LeaveRequest;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

public class LeaveService {
    public static final List<String> TYPES = List.of("Casual Leave", "Sick Leave", "Earned Leave", "Other");
    private static final int MAX_DAYS = 30;

    private final LeaveDAO dao = new LeaveDAO();
    private final EmployeeService employeeService;

    public LeaveService(EmployeeService employeeService) {
        this.employeeService = employeeService;
    }

    public void submit(String employeeId, String type, LocalDate from, LocalDate to, String reason) {
        Employee e = employeeService.findById(employeeId);
        if (e == null || !e.isActive())
            throw new IllegalStateException("Only active employees can request leave.");
        if (type == null || !TYPES.contains(type))
            throw new IllegalArgumentException("Please choose a valid leave type.");
        if (from == null || to == null)
            throw new IllegalArgumentException("Please choose the from and to dates.");
        if (from.isBefore(LocalDate.now()))
            throw new IllegalArgumentException("The leave cannot start in the past.");
        if (to.isBefore(from))
            throw new IllegalArgumentException("The end date cannot be before the start date.");
        if (ChronoUnit.DAYS.between(from, to) >= MAX_DAYS)
            throw new IllegalArgumentException("A leave request can cover at most " + MAX_DAYS + " days.");

        String r = reason == null ? "" : reason.trim();
        if (r.isEmpty()) throw new IllegalArgumentException("Please enter a reason.");
        if (r.length() > 255) throw new IllegalArgumentException("The reason is too long (maximum 255 characters).");

        if (LeaveRequest.countWorkingDays(from, to) == 0)
            throw new IllegalArgumentException("The selected dates are all weekends.");
        if (dao.hasOverlap(e.getId(), from, to))
            throw new IllegalStateException("You already have a pending or approved leave request for these dates.");

        dao.insert(e.getId(), type, from, to, r);
    }

    public List<LeaveRequest> listMine(String employeeId) { return dao.findByEmployee(employeeId); }

    public List<LeaveRequest> listAll() { return dao.findAll(); }

    /** Approve needs no reason. Reject must include one, since the employee needs to know why. */
    public void decide(int id, boolean approve, String hrUsername, String decisionReason) {
        String r = decisionReason == null ? "" : decisionReason.trim();
        if (!approve) {
            if (r.isEmpty()) throw new IllegalArgumentException("Please enter a reason for rejecting this request.");
            if (r.length() > 255) throw new IllegalArgumentException("The reason is too long (maximum 255 characters).");
        }
        dao.decide(id, approve, hrUsername, approve ? null : r);
    }
}