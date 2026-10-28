package service;

import dao.ManagerDAO;
import model.Manager;

import java.util.List;

public class ManagerService {
    private final ManagerDAO dao = new ManagerDAO();

    public Manager findById(String id) { return dao.findById(id); }
    public List<Manager> getAllManagers() { return dao.findAll(); }
    public List<Manager> getActiveManagers() { return dao.findActive(); }
}