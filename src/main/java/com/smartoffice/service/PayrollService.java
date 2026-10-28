package com.smartoffice.service;

import com.smartoffice.dao.PayrollDAO;
import com.smartoffice.dao.PayrollPaymentDAO;
import com.smartoffice.dao.SalaryStructureDAO;
import com.smartoffice.model.*;
import com.smartoffice.util.PayrollCalculator;
import com.smartoffice.util.PayrollException;
import com.smartoffice.util.PayrollRules;
import dao.EmployeeDAO;
import dao.ManagerDAO;
import model.Employee;
import model.Manager;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;

public class PayrollService {

    private final SalaryStructureDAO salaryStructureDAO = new SalaryStructureDAO();
    private final PayrollDAO payrollDAO = new PayrollDAO();
    private final PayrollPaymentDAO paymentDAO = new PayrollPaymentDAO();
    private final EmployeeDAO employeeDAO = new EmployeeDAO();
    private final ManagerDAO managerDAO = new ManagerDAO();

    public static boolean isValidTransition(String fromStatus, String toStatus) {
        if (fromStatus == null || toStatus == null) return false;
        String from = fromStatus.trim().toUpperCase();
        String to = toStatus.trim().toUpperCase();

        if ("DRAFT".equals(from)) {
            return "PROCESSED".equals(to) || "CANCELLED".equals(to);
        }
        if ("PROCESSED".equals(from)) {
            return "PAID".equals(to) || "CANCELLED".equals(to);
        }
        return false;
    }

    public List<Employee> getEligibleEmployees() {
        List<Employee> eligible = new ArrayList<>();
        List<Employee> activeEmps = employeeDAO.findActive();
        if (activeEmps != null) eligible.addAll(activeEmps);

        List<Manager> activeMgrs = managerDAO.findActive();
        if (activeMgrs != null) {
            for (Manager m : activeMgrs) {
                eligible.add(new Employee(
                        m.getId(),
                        m.getName(),
                        m.getDepartment(),
                        "Manager",
                        Employee.Status.ACTIVE
                ));
            }
        }
        return eligible;
    }

    public SalaryStructure getSalaryStructure(String employeeId) {
        return salaryStructureDAO.findCurrentByEmployeeId(employeeId);
    }

    public List<SalaryStructure> getAllCurrentSalaryStructures() {
        return salaryStructureDAO.findAllCurrent();
    }

    public SalaryStructure saveSalaryStructure(SalaryStructure structure) {
        return salaryStructureDAO.save(structure);
    }

    public SalaryStructure getSalaryStructureById(int id) {
        return salaryStructureDAO.findById(id);
    }

    public List<SalaryStructure> getSalaryStructureHistory(String employeeId) {
        return salaryStructureDAO.findHistoryByEmployeeId(employeeId);
    }

    public Payroll prepareDraftPayroll(String employeeId, int month, int year,
                                       boolean applyAttendanceAdjustment,
                                       Integer customWorkingDays,
                                       Double customPresentDays,
                                       Double customPaidLeaveDays,
                                       Double customUnpaidDays,
                                       String manualRemarks) {
        return prepareDraftPayroll(employeeId, month, year, applyAttendanceAdjustment, customWorkingDays,
                customPresentDays != null ? BigDecimal.valueOf(customPresentDays) : null,
                customPaidLeaveDays != null ? BigDecimal.valueOf(customPaidLeaveDays) : null,
                customUnpaidDays != null ? BigDecimal.valueOf(customUnpaidDays) : null,
                manualRemarks);
    }

    public Payroll prepareDraftPayroll(String employeeId, int month, int year,
                                       boolean applyAttendanceAdjustment,
                                       Integer customWorkingDays,
                                       BigDecimal customPresentDays,
                                       BigDecimal customPaidLeaveDays,
                                       BigDecimal customUnpaidDays,
                                       String manualRemarks) {
        YearMonth ym = YearMonth.of(year, month);
        LocalDate monthStart = ym.atDay(1);
        LocalDate monthEnd = ym.atEndOfMonth();

        SalaryStructure structure = salaryStructureDAO.findApplicableForPeriod(employeeId, monthStart, monthEnd);
        if (structure == null) {
            throw new PayrollException("No salary structure in effect for employee " + employeeId +
                    " during " + ym + ". Please configure a salary structure before generating payroll.");
        }

        Employee emp = employeeDAO.findById(employeeId);
        String empName = emp != null ? emp.getName() : structure.getEmployeeName();
        String dept = emp != null ? emp.getDepartment() : structure.getDepartment();
        String desig = (emp != null && emp.getDesignation() != null && !emp.getDesignation().isEmpty())
                ? emp.getDesignation() : "Software Engineer";

        if (emp == null) {
            Manager mgr = managerDAO.findById(employeeId);
            if (mgr != null) {
                empName = mgr.getName();
                dept = mgr.getDepartment();
                desig = "Manager";
            }
        }

        Payroll payroll = new Payroll();
        payroll.setEmployeeId(employeeId);
        payroll.setEmployeeName(empName);
        payroll.setDepartment(dept);
        payroll.setDesignation(desig);
        payroll.setPayrollMonth(month);
        payroll.setPayrollYear(year);
        payroll.setBasicSalary(structure.getBasicSalary());
        payroll.setStatus("DRAFT");

        // Attendance metrics
        AttendanceMetrics metrics = payrollDAO.getAttendanceMetrics(employeeId, month, year);
        int totalWorkingDays = customWorkingDays != null ? customWorkingDays : metrics.getTotalWorkingDays();
        BigDecimal presentDays = customPresentDays != null ? customPresentDays.setScale(1, RoundingMode.HALF_UP) : metrics.getPresentDays();
        BigDecimal paidLeaveDays = customPaidLeaveDays != null ? customPaidLeaveDays.setScale(1, RoundingMode.HALF_UP) : metrics.getPaidLeaveDays();
        BigDecimal unpaidDays = customUnpaidDays != null ? customUnpaidDays.setScale(1, RoundingMode.HALF_UP) : metrics.getUnpaidDays();

        payroll.setTotalWorkingDays(totalWorkingDays);
        payroll.setPresentDays(presentDays);
        payroll.setPaidLeaveDays(paidLeaveDays);
        payroll.setUnpaidDays(unpaidDays);

        List<PayrollItem> items = new ArrayList<>();
        List<PayrollItem> earningsList = new ArrayList<>();
        List<PayrollItem> deductionsList = new ArrayList<>();

        // Add allowances & statutory deductions from structure
        for (SalaryComponent comp : structure.getComponents()) {
            BigDecimal amt = PayrollCalculator.calculateComponentAmount(comp, structure.getBasicSalary());
            PayrollItem item = new PayrollItem(0, 0, comp.getComponentName(), comp.getComponentType(), amt);
            items.add(item);
            if (comp.isEarning()) {
                earningsList.add(item);
            } else if (comp.isDeduction()) {
                deductionsList.add(item);
            }
        }

        BigDecimal gross = PayrollCalculator.calculateGrossSalary(structure.getBasicSalary(), earningsList);

        // Attendance Loss of Pay (LOP)
        BigDecimal lossOfPay = BigDecimal.ZERO;
        if (applyAttendanceAdjustment && unpaidDays.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal lopBase = "GROSS".equalsIgnoreCase(PayrollRules.getLopBasis()) ? gross : structure.getBasicSalary();
            lossOfPay = PayrollCalculator.calculateLossOfPay(lopBase, totalWorkingDays, unpaidDays);

            PayrollItem lopItem = new PayrollItem(0, 0, "Loss of Pay (" + unpaidDays.stripTrailingZeros().toPlainString() + " d)", "DEDUCTION", lossOfPay);
            items.add(lopItem);
            deductionsList.add(lopItem);
        }
        payroll.setLossOfPay(lossOfPay);

        // Deductions & Net salary calculated strictly from items (prevents double counting)
        BigDecimal totalDeductions = PayrollCalculator.calculateTotalDeductions(deductionsList);
        BigDecimal net = PayrollCalculator.calculateNetSalary(gross, totalDeductions);

        payroll.setGrossSalary(gross);
        payroll.setTotalDeductions(totalDeductions);
        payroll.setNetSalary(net);
        payroll.setItems(items);

        StringBuilder remarksBuilder = new StringBuilder();
        if (manualRemarks != null && !manualRemarks.trim().isEmpty()) {
            remarksBuilder.append(manualRemarks.trim());
        }
        if (metrics.hasDiscrepancy()) {
            if (remarksBuilder.length() > 0) remarksBuilder.append(" | ");
            remarksBuilder.append("Attendance discrepancy: ").append(metrics.getDiscrepancyNotes());
        }
        if (net.compareTo(BigDecimal.ZERO) < 0) {
            if (remarksBuilder.length() > 0) remarksBuilder.append(" | ");
            remarksBuilder.append("WARNING: Deductions exceed gross salary — review required.");
        }
        payroll.setRemarks(remarksBuilder.length() > 0 ? remarksBuilder.toString() : null);

        return payroll;
    }

    public static class BatchGenerationResult {
        private int generatedCount = 0;
        private int skippedCount = 0;
        private final List<String> failures = new ArrayList<>();

        public int getGeneratedCount() { return generatedCount; }
        public void incrementGenerated() { this.generatedCount++; }
        public int getSkippedCount() { return skippedCount; }
        public void incrementSkipped() { this.skippedCount++; }
        public List<String> getFailures() { return failures; }
        public void addFailure(String empId, String reason) { this.failures.add(empId + ": " + reason); }
    }

    public BatchGenerationResult generateAllDrafts(int month, int year, String actor, boolean applyAttendance) {
        List<Employee> eligible = getEligibleEmployees();
        BatchGenerationResult result = new BatchGenerationResult();

        for (Employee emp : eligible) {
            try {
                Payroll existing = payrollDAO.findByEmployeeAndPeriod(emp.getId(), month, year);
                if (existing != null && ("PROCESSED".equalsIgnoreCase(existing.getStatus()) || "PAID".equalsIgnoreCase(existing.getStatus()))) {
                    result.incrementSkipped();
                    continue;
                }

                Payroll draft = prepareDraftPayroll(emp.getId(), month, year, applyAttendance, null, (BigDecimal) null, null, null, null);
                draft.setStatus("DRAFT");
                draft.setProcessedBy(actor);
                payrollDAO.save(draft);
                result.incrementGenerated();
            } catch (PayrollException pe) {
                result.addFailure(emp.getId(), pe.getMessage());
            } catch (Exception e) {
                result.addFailure(emp.getId(), "Calculation error (" + e.getClass().getSimpleName() + ")");
            }
        }
        return result;
    }

    public void finalizeSingle(int payrollId, String actor) {
        Payroll p = payrollDAO.findById(payrollId);
        if (p == null) {
            throw new PayrollException("Payroll record #" + payrollId + " not found.");
        }
        if (!"DRAFT".equalsIgnoreCase(p.getStatus())) {
            throw new PayrollException("Only DRAFT records can be finalized (current status: " + p.getStatus() + ").");
        }
        if (p.getNetSalary().compareTo(BigDecimal.ZERO) < 0) {
            throw new PayrollException("Cannot finalize payroll #" + payrollId + ": Net salary is negative. Please review deductions.");
        }
        payrollDAO.updateStatus(payrollId, "DRAFT", "PROCESSED", actor);
    }

    public int finalizeAllDrafts(int month, int year, String actor) {
        List<Payroll> list = payrollDAO.findAll(month, year, null, "DRAFT", null);
        int count = 0;
        for (Payroll p : list) {
            if (p.getNetSalary().compareTo(BigDecimal.ZERO) >= 0) {
                try {
                    payrollDAO.updateStatus(p.getId(), "DRAFT", "PROCESSED", actor);
                    count++;
                } catch (Exception ignored) {}
            }
        }
        return count;
    }

    public void cancelPayroll(int payrollId, String reason, String actor) {
        payrollDAO.cancelPayroll(payrollId, reason, actor);
    }

    public Payroll getPayrollById(int id) {
        return payrollDAO.findById(id);
    }

    public Payroll getPayrollByEmployeeAndPeriod(String employeeId, int month, int year) {
        return payrollDAO.findByEmployeeAndPeriod(employeeId, month, year);
    }

    public List<Payroll> getPayrollHistoryByEmployee(String employeeId) {
        return payrollDAO.findFinalizedByEmployeeId(employeeId);
    }

    public List<Payroll> getPayrollList(Integer month, Integer year, String department, String status, String employeeId) {
        return payrollDAO.findAll(month, year, department, status, employeeId);
    }

    public List<String> getDepartments() {
        return payrollDAO.getDistinctDepartments();
    }

    public List<PayrollDAO.DeptSummary> getDepartmentSummary(Integer month, Integer year) {
        return payrollDAO.getDepartmentSummary(month, year);
    }

    public PayrollPayment recordPayment(int payrollId, LocalDate paymentDate, String paymentMethod,
                                        String refNumber, BigDecimal amountPaid, String notes) {
        PayrollPayment payment = new PayrollPayment();
        payment.setPayrollId(payrollId);
        payment.setPaymentDate(paymentDate);
        payment.setPaymentMethod(paymentMethod);
        payment.setReferenceNumber(refNumber);
        payment.setAmountPaid(amountPaid);
        payment.setNotes(notes);
        return paymentDAO.recordPayment(payment);
    }
}
