package service;

import dao.TeamDAO;
import java.util.ArrayList;
import dao.TeamMemberDAO;
import model.Manager;
import model.Team;

import java.util.List;

public class TeamService {
    private final TeamDAO teamDao = new TeamDAO();
    private final TeamMemberDAO memberDao = new TeamMemberDAO();
    private final ManagerService managerService;
    private final EmployeeService employeeService;

    public TeamService(ManagerService managerService, EmployeeService employeeService) {
        this.managerService = managerService;
        this.employeeService = employeeService;
    }

    private void validateCommon(String name, String description, String department) {
        if (name == null || name.trim().isEmpty()) throw new IllegalArgumentException("Team name is required.");
        if (name.trim().length() > 100) throw new IllegalArgumentException("Team name is too long (max 100 characters).");
        if (department == null || department.trim().isEmpty()) throw new IllegalArgumentException("Department is required.");
        if (description != null && description.length() > 500) throw new IllegalArgumentException("Description is too long (max 500 characters).");
    }

    public Team createTeam(String name, String description, String department, String managerId, String statusStr) {
        validateCommon(name, description, department);
        if (managerId == null || managerId.trim().isEmpty()) throw new IllegalArgumentException("Team manager must be selected.");
        Manager m = managerService.findById(managerId);
        if (m == null || !m.isActive()) throw new IllegalArgumentException("Please select a valid, active manager.");
        if (teamDao.nameExists(name.trim())) throw new IllegalStateException("A team with this name already exists.");
        Team.Status status = parseStatus(statusStr);
        int id = teamDao.insert(name.trim(), blankToNull(description), department.trim(), managerId.trim().toUpperCase(), status);
        return teamDao.findById(id);
    }

    public Team updateTeamByHr(int id, String name, String description, String department, String managerId, String statusStr) {
        Team existing = requireTeam(id);
        validateCommon(name, description, department);
        if (managerId == null || managerId.trim().isEmpty()) throw new IllegalArgumentException("Team manager must be selected.");
        Manager m = managerService.findById(managerId);
        if (m == null || !m.isActive()) throw new IllegalArgumentException("Please select a valid, active manager.");
        if (!name.trim().equalsIgnoreCase(existing.getTeamName()) && teamDao.nameExists(name.trim()))
            throw new IllegalStateException("A team with this name already exists.");
        Team.Status status = parseStatus(statusStr);
        teamDao.update(id, name.trim(), blankToNull(description), department.trim(), managerId.trim().toUpperCase(), status);
        return teamDao.findById(id);
    }

    /** Manager can only edit description and status of their own team. */
    public Team updateTeamByManager(String managerId, int id, String description, String statusStr) {
        Team existing = requireTeam(id);
        if (existing.getManagerId() == null || !existing.getManagerId().equalsIgnoreCase(managerId))
            throw new IllegalStateException("You can only update teams assigned to you.");
        if (description != null && description.length() > 500)
            throw new IllegalArgumentException("Description is too long (max 500 characters).");
        Team.Status status = parseStatus(statusStr);
        teamDao.update(id, existing.getTeamName(), blankToNull(description), existing.getDepartment(),
                existing.getManagerId(), status);
        return teamDao.findById(id);
    }

    public void deleteTeam(int id) {
        requireTeam(id);
        if (teamDao.activeMemberCount(id) > 0)
            throw new IllegalStateException("This team contains active members. Please remove or transfer members before deleting the team.");
        memberDao.removeAllForTeam(id);
        teamDao.delete(id);
    }

    public Team requireTeam(int id) {
        Team t = teamDao.findById(id);
        if (t == null) throw new IllegalArgumentException("Team not found.");
        return t;
    }

    public List<Team> getAllTeams() { return teamDao.findAll(); }
    public List<Team> getTeamsForManager(String managerId) { return teamDao.findByManager(managerId); }
    public List<Team> search(String keyword, String department, String status, String managerId) {
        return teamDao.search(keyword, department, status, managerId);
    }

    public List<Team> getMyTeamsForEmployee(String employeeId) {
        List<Team> out = new ArrayList<>();
        for (Integer teamId : memberDao.findActiveTeamIdsForEmployee(employeeId)) {
            Team t = teamDao.findById(teamId);
            if (t != null) out.add(t);
        }
        return out;
    }

    public int activeMemberCount(int teamId) { return teamDao.activeMemberCount(teamId); }
    public int[] dashboardTotals() { return teamDao.dashboardTotals(); }
    public java.util.Map<String, Integer> departmentCounts() { return teamDao.departmentCounts(); }

    private Team.Status parseStatus(String s) {
        try { return Team.Status.valueOf(s == null ? "" : s.trim().toUpperCase()); }
        catch (Exception e) { throw new IllegalArgumentException("Please choose a valid status."); }
    }

    private static String blankToNull(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }
}