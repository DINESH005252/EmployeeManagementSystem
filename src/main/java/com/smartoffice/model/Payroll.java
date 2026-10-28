package com.smartoffice.model;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Timestamp;
import java.time.Month;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class Payroll {
    private int id;
    private String employeeId;
    private String employeeName;
    private String department;
    private String designation;
    private int payrollMonth;
    private int payrollYear;
    private BigDecimal basicSalary;
    private BigDecimal grossSalary;
    private BigDecimal totalDeductions;
    private BigDecimal netSalary;
    private String status; // DRAFT, PROCESSED, PAID, CANCELLED
    private String processedBy;
    private Timestamp processedAt;
    private int totalWorkingDays;
    private BigDecimal presentDays;
    private BigDecimal paidLeaveDays;
    private BigDecimal unpaidDays;
    private BigDecimal lossOfPay;
    private String remarks;
    private String cancelledBy;
    private Timestamp cancelledAt;
    private Timestamp createdAt;

    private List<PayrollItem> items;
    private PayrollPayment payment;

    public Payroll() {
        this.basicSalary = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        this.grossSalary = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        this.totalDeductions = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        this.netSalary = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        this.lossOfPay = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        this.presentDays = BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        this.paidLeaveDays = BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        this.unpaidDays = BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        this.status = "DRAFT";
        this.designation = "—";
        this.items = new ArrayList<>();
    }

    public Payroll(int id, String employeeId, int payrollMonth, int payrollYear,
                   BigDecimal basicSalary, BigDecimal grossSalary, BigDecimal totalDeductions,
                   BigDecimal netSalary, String status, String processedBy, Timestamp processedAt,
                   int totalWorkingDays, BigDecimal presentDays, BigDecimal paidLeaveDays, BigDecimal unpaidDays,
                   BigDecimal lossOfPay, String remarks, Timestamp createdAt) {
        this(id, employeeId, payrollMonth, payrollYear, basicSalary, grossSalary, totalDeductions,
             netSalary, status, processedBy, processedAt, totalWorkingDays, presentDays, paidLeaveDays,
             unpaidDays, lossOfPay, remarks, null, null, createdAt);
    }

    public Payroll(int id, String employeeId, int payrollMonth, int payrollYear,
                   BigDecimal basicSalary, BigDecimal grossSalary, BigDecimal totalDeductions,
                   BigDecimal netSalary, String status, String processedBy, Timestamp processedAt,
                   int totalWorkingDays, double presentDays, double paidLeaveDays, double unpaidDays,
                   BigDecimal lossOfPay, String remarks, Timestamp createdAt) {
        this(id, employeeId, payrollMonth, payrollYear, basicSalary, grossSalary, totalDeductions,
             netSalary, status, processedBy, processedAt, totalWorkingDays,
             BigDecimal.valueOf(presentDays), BigDecimal.valueOf(paidLeaveDays), BigDecimal.valueOf(unpaidDays),
             lossOfPay, remarks, null, null, createdAt);
    }

    public Payroll(int id, String employeeId, int payrollMonth, int payrollYear,
                   BigDecimal basicSalary, BigDecimal grossSalary, BigDecimal totalDeductions,
                   BigDecimal netSalary, String status, String processedBy, Timestamp processedAt,
                   int totalWorkingDays, BigDecimal presentDays, BigDecimal paidLeaveDays, BigDecimal unpaidDays,
                   BigDecimal lossOfPay, String remarks, String cancelledBy, Timestamp cancelledAt, Timestamp createdAt) {
        this.id = id;
        this.employeeId = employeeId;
        this.payrollMonth = payrollMonth;
        this.payrollYear = payrollYear;
        this.basicSalary = basicSalary != null ? basicSalary.setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        this.grossSalary = grossSalary != null ? grossSalary.setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        this.totalDeductions = totalDeductions != null ? totalDeductions.setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        this.netSalary = netSalary != null ? netSalary.setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        this.status = status != null ? status : "DRAFT";
        this.processedBy = processedBy;
        this.processedAt = processedAt;
        this.totalWorkingDays = totalWorkingDays;
        this.presentDays = presentDays != null ? presentDays.setScale(1, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        this.paidLeaveDays = paidLeaveDays != null ? paidLeaveDays.setScale(1, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        this.unpaidDays = unpaidDays != null ? unpaidDays.setScale(1, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        this.lossOfPay = lossOfPay != null ? lossOfPay.setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        this.remarks = remarks;
        this.cancelledBy = cancelledBy;
        this.cancelledAt = cancelledAt;
        this.createdAt = createdAt;
        this.designation = "—";
        this.items = new ArrayList<>();
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getEmployeeId() { return employeeId; }
    public void setEmployeeId(String employeeId) { this.employeeId = employeeId; }

    public String getEmployeeName() { return employeeName; }
    public void setEmployeeName(String employeeName) { this.employeeName = employeeName; }

    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }

    public String getDesignation() { return designation; }
    public void setDesignation(String designation) { this.designation = designation; }

    public int getPayrollMonth() { return payrollMonth; }
    public void setPayrollMonth(int payrollMonth) { this.payrollMonth = payrollMonth; }

    public int getPayrollYear() { return payrollYear; }
    public void setPayrollYear(int payrollYear) { this.payrollYear = payrollYear; }

    public BigDecimal getBasicSalary() { return basicSalary; }
    public void setBasicSalary(BigDecimal basicSalary) {
        this.basicSalary = basicSalary != null ? basicSalary.setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
    }

    public BigDecimal getGrossSalary() { return grossSalary; }
    public void setGrossSalary(BigDecimal grossSalary) {
        this.grossSalary = grossSalary != null ? grossSalary.setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
    }

    public BigDecimal getTotalDeductions() { return totalDeductions; }
    public void setTotalDeductions(BigDecimal totalDeductions) {
        this.totalDeductions = totalDeductions != null ? totalDeductions.setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
    }

    public BigDecimal getNetSalary() { return netSalary; }
    public void setNetSalary(BigDecimal netSalary) {
        this.netSalary = netSalary != null ? netSalary.setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
    }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getProcessedBy() { return processedBy; }
    public void setProcessedBy(String processedBy) { this.processedBy = processedBy; }

    public Timestamp getProcessedAt() { return processedAt; }
    public void setProcessedAt(Timestamp processedAt) { this.processedAt = processedAt; }

    public int getTotalWorkingDays() { return totalWorkingDays; }
    public void setTotalWorkingDays(int totalWorkingDays) { this.totalWorkingDays = totalWorkingDays; }

    public BigDecimal getPresentDays() { return presentDays; }
    public void setPresentDays(BigDecimal presentDays) {
        this.presentDays = presentDays != null ? presentDays.setScale(1, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
    }
    public void setPresentDays(double presentDays) {
        setPresentDays(BigDecimal.valueOf(presentDays));
    }

    public BigDecimal getPaidLeaveDays() { return paidLeaveDays; }
    public void setPaidLeaveDays(BigDecimal paidLeaveDays) {
        this.paidLeaveDays = paidLeaveDays != null ? paidLeaveDays.setScale(1, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
    }
    public void setPaidLeaveDays(double paidLeaveDays) {
        setPaidLeaveDays(BigDecimal.valueOf(paidLeaveDays));
    }

    public BigDecimal getUnpaidDays() { return unpaidDays; }
    public void setUnpaidDays(BigDecimal unpaidDays) {
        this.unpaidDays = unpaidDays != null ? unpaidDays.setScale(1, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
    }
    public void setUnpaidDays(double unpaidDays) {
        setUnpaidDays(BigDecimal.valueOf(unpaidDays));
    }

    public boolean hasUnpaidDays() {
        return unpaidDays != null && unpaidDays.compareTo(BigDecimal.ZERO) > 0;
    }

    public BigDecimal getLossOfPay() { return lossOfPay; }
    public void setLossOfPay(BigDecimal lossOfPay) {
        this.lossOfPay = lossOfPay != null ? lossOfPay.setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
    }

    public String getRemarks() { return remarks; }
    public void setRemarks(String remarks) { this.remarks = remarks; }

    public String getCancelledBy() { return cancelledBy; }
    public void setCancelledBy(String cancelledBy) { this.cancelledBy = cancelledBy; }

    public Timestamp getCancelledAt() { return cancelledAt; }
    public void setCancelledAt(Timestamp cancelledAt) { this.cancelledAt = cancelledAt; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public List<PayrollItem> getItems() { return items; }
    public void setItems(List<PayrollItem> items) { this.items = items != null ? items : new ArrayList<>(); }

    public List<PayrollItem> getEarnings() {
        List<PayrollItem> list = new ArrayList<>();
        if (items != null) {
            for (PayrollItem it : items) {
                if (it.isEarning()) list.add(it);
            }
        }
        return list;
    }

    public List<PayrollItem> getDeductions() {
        List<PayrollItem> list = new ArrayList<>();
        if (items != null) {
            for (PayrollItem it : items) {
                if (it.isDeduction()) list.add(it);
            }
        }
        return list;
    }

    public PayrollPayment getPayment() { return payment; }
    public void setPayment(PayrollPayment payment) { this.payment = payment; }

    public String getMonthName() {
        if (payrollMonth >= 1 && payrollMonth <= 12) {
            return Month.of(payrollMonth).getDisplayName(TextStyle.FULL, Locale.ENGLISH);
        }
        return "Month " + payrollMonth;
    }

    public String getPeriodLabel() {
        return getMonthName() + " " + payrollYear;
    }

    public boolean isDraft() { return "DRAFT".equalsIgnoreCase(status); }
    public boolean isProcessed() { return "PROCESSED".equalsIgnoreCase(status); }
    public boolean isPaid() { return "PAID".equalsIgnoreCase(status); }
    public boolean isCancelled() { return "CANCELLED".equalsIgnoreCase(status); }
}
