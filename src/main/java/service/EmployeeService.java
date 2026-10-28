package service;

import dao.EmployeeDAO;
import model.Employee;

import java.util.List;

public class EmployeeService {
    private final EmployeeDAO dao = new EmployeeDAO();

    public Employee findById(String id) { return dao.findById(id); }
    public List<Employee> getAllEmployees() { return dao.findAll(); }
    public List<Employee> getActiveEmployees() { return dao.findActive(); }
}