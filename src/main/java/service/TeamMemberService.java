package service;

import dao.TeamDAO;
import dao.TeamMemberDAO;
import model.Employee;
import model.Team;
import model.TeamMember;

import java.util.List;

public class TeamMemberService {
    private final TeamMemberDAO memberDao = new TeamMemberDAO();
    private final TeamDAO teamDao = new TeamDAO();
    private final EmployeeService employeeService;

    public TeamMemberService(EmployeeService employeeService) {
        this.employeeService = employeeService;
    }

    public List<TeamMember> getMembers(int teamId) { return memberDao.findActiveByTeam(teamId); }

    public void addMember(int teamId, String employeeId) {
        requireTeam(teamId);
        Employee e = employeeService.findById(employeeId);
        if (e == null || !e.isActive()) throw new IllegalArgumentException("Please select a valid, active employee.");
        if (memberDao.isActiveMember(teamId, e.getId())) throw new IllegalStateException("Employee is already a member of this team.");
        memberDao.add(teamId, e.getId());
    }

    public void removeMember(int teamId, String employeeId) {
        requireTeam(teamId);
        memberDao.remove(teamId, employeeId.trim().toUpperCase());
    }

    private Team requireTeam(int teamId) {
        Team t = teamDao.findById(teamId);
        if (t == null) throw new IllegalArgumentException("Team not found.");
        return t;
    }
}