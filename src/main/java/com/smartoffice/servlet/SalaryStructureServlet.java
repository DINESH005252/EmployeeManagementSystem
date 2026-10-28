package com.smartoffice.servlet;

import com.smartoffice.model.Payroll;
import com.smartoffice.model.SalaryComponent;
import com.smartoffice.model.SalaryStructure;
import com.smartoffice.service.PayrollService;
import com.smartoffice.util.CsrfUtil;
import com.smartoffice.util.PayrollException;
import com.smartoffice.util.RequestValidator;
import dao.EmployeeDAO;
import dao.ManagerDAO;
import model.Employee;
import model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

@WebServlet(urlPatterns = {
        "/payroll",
        "/payroll/dashboard",
        "/payroll/salary-structures",
        "/payroll/salary-structure-form"
})
public class SalaryStructureServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private PayrollService payrollService;
    private EmployeeDAO employeeDAO;
    private ManagerDAO managerDAO;

    @Override
    public void init() {
        this.payrollService = new PayrollService();
        this.employeeDAO = new EmployeeDAO();
        this.managerDAO = new ManagerDAO();
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        User user = (session == null) ? null : (User) session.getAttribute("user");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login.html");
            return;
        }

        String path = req.getServletPath();

        // Dashboard
        if ("/payroll".equals(path) || "/payroll/dashboard".equals(path)) {
            renderDashboard(req, resp, user);
            return;
        }

        // Structure list and form are HR-only
        if (!user.isHr()) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Access Denied: Only HR administrators can manage salary structures.");
            return;
        }

        if ("/payroll/salary-structures".equals(path)) {
            renderStructureList(req, resp);
        } else if ("/payroll/salary-structure-form".equals(path)) {
            renderStructureForm(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        User user = (session == null) ? null : (User) session.getAttribute("user");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login.html");
            return;
        }

        if (!user.isHr()) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Access Denied: Only HR administrators can update salary structures.");
            return;
        }

        // CSRF Protection
        if (!CsrfUtil.validate(req)) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid or expired security token (CSRF).");
            return;
        }

        String action = req.getParameter("action");
        if ("save".equalsIgnoreCase(action) || action == null) {
            saveSalaryStructure(req, resp);
        } else {
            resp.sendRedirect(req.getContextPath() + "/payroll/salary-structures");
        }
    }

    private void renderDashboard(HttpServletRequest req, HttpServletResponse resp, User user)
            throws ServletException, IOException {
        LocalDate now = LocalDate.now();
        int curMonth = now.getMonthValue();
        int curYear = now.getYear();

        if (user.isHr()) {
            List<SalaryStructure> structures = payrollService.getAllCurrentSalaryStructures();
            List<Payroll> monthlyPayrolls = payrollService.getPayrollList(curMonth, curYear, null, null, null);

            BigDecimal totalGross = BigDecimal.ZERO;
            BigDecimal totalDeductions = BigDecimal.ZERO;
            BigDecimal totalNet = BigDecimal.ZERO;
            int paidCount = 0;
            int processedCount = 0;
            int draftCount = 0;
            int cancelledCount = 0;

            for (Payroll p : monthlyPayrolls) {
                if (!"CANCELLED".equalsIgnoreCase(p.getStatus())) {
                    totalGross = totalGross.add(p.getGrossSalary());
                    totalDeductions = totalDeductions.add(p.getTotalDeductions());
                    totalNet = totalNet.add(p.getNetSalary());
                }
                if ("PAID".equalsIgnoreCase(p.getStatus())) {
                    paidCount++;
                } else if ("PROCESSED".equalsIgnoreCase(p.getStatus())) {
                    processedCount++;
                } else if ("DRAFT".equalsIgnoreCase(p.getStatus())) {
                    draftCount++;
                } else if ("CANCELLED".equalsIgnoreCase(p.getStatus())) {
                    cancelledCount++;
                }
            }

            req.setAttribute("totalStructures", structures.size());
            req.setAttribute("monthlyPayrolls", monthlyPayrolls);
            req.setAttribute("totalGross", totalGross);
            req.setAttribute("totalDeductions", totalDeductions);
            req.setAttribute("totalNet", totalNet);
            req.setAttribute("paidCount", paidCount);
            req.setAttribute("pendingCount", processedCount); // "pending" = PROCESSED awaiting settlement
            req.setAttribute("draftCount", draftCount);
            req.setAttribute("cancelledCount", cancelledCount);
            req.setAttribute("currentMonth", curMonth);
            req.setAttribute("currentYear", curYear);

            req.getRequestDispatcher("/payroll/payroll-dashboard.jsp").forward(req, resp);
        } else {
            resp.sendRedirect(req.getContextPath() + "/payroll/history");
        }
    }

    private void renderStructureList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        List<SalaryStructure> structures = payrollService.getAllCurrentSalaryStructures();
        req.setAttribute("structures", structures);
        req.getRequestDispatcher("/payroll/salary-structures.jsp").forward(req, resp);
    }

    private void renderStructureForm(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String idStr = req.getParameter("id");
        String empId = req.getParameter("employeeId");

        SalaryStructure structure = null;
        if (idStr != null && !idStr.trim().isEmpty()) {
            try {
                int id = RequestValidator.parsePositiveInt(idStr, "Structure ID");
                structure = payrollService.getSalaryStructureById(id);
            } catch (Exception ignored) {}
        }

        if (structure == null && empId != null && !empId.trim().isEmpty()) {
            structure = payrollService.getSalaryStructure(empId.trim().toUpperCase());
            if (structure == null) {
                structure = new SalaryStructure();
                structure.setEmployeeId(empId.trim().toUpperCase());
                Employee emp = employeeDAO.findById(empId.trim().toUpperCase());
                if (emp != null) {
                    structure.setEmployeeName(emp.getName());
                    structure.setDepartment(emp.getDepartment());
                }
                structure.setEffectiveFrom(LocalDate.now().withDayOfMonth(1));
            }
        }

        if (structure == null) {
            structure = new SalaryStructure();
            structure.setEffectiveFrom(LocalDate.now().withDayOfMonth(1));
        }

        List<Employee> eligible = payrollService.getEligibleEmployees();
        req.setAttribute("structure", structure);
        req.setAttribute("employees", eligible);
        req.getRequestDispatcher("/payroll/salary-structure-form.jsp").forward(req, resp);
    }

    private void saveSalaryStructure(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            String empId = RequestValidator.requireEmployeeId(req.getParameter("employeeId"), employeeDAO, managerDAO);
            BigDecimal basicSalary = RequestValidator.parseMoney(req.getParameter("basicSalary"), "Basic Monthly Salary");
            if (basicSalary.compareTo(BigDecimal.ZERO) <= 0) {
                throw new PayrollException("Basic salary must be greater than zero.");
            }

            LocalDate effFrom = RequestValidator.parseDate(req.getParameter("effectiveFrom"), "Effective From Date");
            String effToStr = req.getParameter("effectiveTo");
            LocalDate effTo = (effToStr != null && !effToStr.trim().isEmpty())
                    ? RequestValidator.parseDate(effToStr, "Effective To Date") : null;

            if (effTo != null && effTo.isBefore(effFrom)) {
                throw new PayrollException("Effective To date cannot be earlier than Effective From date.");
            }

            SalaryStructure structure = new SalaryStructure();
            structure.setEmployeeId(empId);
            structure.setBasicSalary(basicSalary);
            structure.setEffectiveFrom(effFrom);
            structure.setEffectiveTo(effTo);

            // Components validation
            String[] compNames = req.getParameterValues("componentName");
            String[] compTypes = req.getParameterValues("componentType");
            String[] calcTypes = req.getParameterValues("calculationType");
            String[] amounts = req.getParameterValues("componentAmount");
            String[] descriptions = req.getParameterValues("componentDescription");

            List<SalaryComponent> components = new ArrayList<>();
            if (compNames != null) {
                int len = compNames.length;
                if ((compTypes != null && compTypes.length != len) ||
                    (calcTypes != null && calcTypes.length != len) ||
                    (amounts != null && amounts.length != len)) {
                    throw new PayrollException("Malformed component data: row arrays must have matching lengths.");
                }

                if (len > 30) {
                    throw new PayrollException("A salary structure cannot contain more than 30 components.");
                }

                Set<String> seenNames = new HashSet<>();
                BigDecimal totalFixedDeductions = BigDecimal.ZERO;
                BigDecimal totalPctDeductions = BigDecimal.ZERO;

                for (int i = 0; i < len; i++) {
                    String name = compNames[i] != null ? compNames[i].trim() : "";
                    if (name.isEmpty()) continue;

                    if (name.length() > 100) {
                        throw new PayrollException("Component name exceeds 100 characters: " + name);
                    }
                    if (!seenNames.add(name.toLowerCase())) {
                        throw new PayrollException("Duplicate component name: '" + name + "'. Component names must be unique.");
                    }

                    String typeStr = compTypes != null && compTypes[i] != null ? compTypes[i].trim().toUpperCase() : "";
                    if (!"EARNING".equals(typeStr) && !"DEDUCTION".equals(typeStr)) {
                        throw new PayrollException("Invalid component type for '" + name + "'. Must be EARNING or DEDUCTION.");
                    }

                    String calcStr = calcTypes != null && calcTypes[i] != null ? calcTypes[i].trim().toUpperCase() : "";
                    if (!"FIXED".equals(calcStr) && !"PERCENTAGE".equals(calcStr)) {
                        throw new PayrollException("Invalid calculation type for '" + name + "'. Must be FIXED or PERCENTAGE.");
                    }

                    String amtStr = amounts != null ? amounts[i] : "0";
                    BigDecimal amt = RequestValidator.parseMoney(amtStr, "Amount for '" + name + "'");

                    if ("PERCENTAGE".equals(calcStr) && amt.compareTo(new BigDecimal("100.00")) > 0) {
                        throw new PayrollException("Percentage rate for '" + name + "' cannot exceed 100%.");
                    }

                    String desc = (descriptions != null && i < descriptions.length && descriptions[i] != null)
                            ? descriptions[i].trim() : null;
                    if (desc != null && desc.length() > 255) {
                        desc = desc.substring(0, 255);
                    }

                    if ("DEDUCTION".equals(typeStr)) {
                        if ("PERCENTAGE".equals(calcStr)) {
                            totalPctDeductions = totalPctDeductions.add(amt);
                        } else {
                            totalFixedDeductions = totalFixedDeductions.add(amt);
                        }
                    }

                    components.add(new SalaryComponent(0, 0, name, typeStr, calcStr, amt, desc));
                }

                // Check total deductions do not exceed basic pay
                if (totalPctDeductions.compareTo(new BigDecimal("100.00")) > 0) {
                    throw new PayrollException("Total percentage deductions cannot exceed 100% of basic salary.");
                }
            }

            structure.setComponents(components);
            payrollService.saveSalaryStructure(structure);

            sessionMessage(req, "successMessage", "Salary structure for " + empId + " saved successfully.");
            resp.sendRedirect(req.getContextPath() + "/payroll/salary-structures");
        } catch (PayrollException pe) {
            req.setAttribute("errorMessage", pe.getMessage());
            renderStructureForm(req, resp);
        } catch (Exception e) {
            String ref = UUID.randomUUID().toString().substring(0, 8);
            getServletContext().log("Ref #" + ref + ": Error saving salary structure", e);
            req.setAttribute("errorMessage", "Unable to save salary structure. Please verify details (Ref #" + ref + ").");
            renderStructureForm(req, resp);
        }
    }

    private void sessionMessage(HttpServletRequest req, String key, String msg) {
        HttpSession s = req.getSession(false);
        if (s != null) {
            s.setAttribute(key, msg);
        }
    }
}
