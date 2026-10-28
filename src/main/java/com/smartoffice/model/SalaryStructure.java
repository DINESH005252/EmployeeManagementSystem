package com.smartoffice.model;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class SalaryStructure {
    private int id;
    private String employeeId;
    private String employeeName;
    private String department;
    private BigDecimal basicSalary;
    private LocalDate effectiveFrom;
    private LocalDate effectiveTo;
    private Timestamp createdAt;
    private List<SalaryComponent> components;

    public SalaryStructure() {
        this.basicSalary = BigDecimal.ZERO;
        this.components = new ArrayList<>();
    }

    public SalaryStructure(int id, String employeeId, BigDecimal basicSalary,
                           LocalDate effectiveFrom, LocalDate effectiveTo, Timestamp createdAt) {
        this(id, employeeId, null, null, basicSalary, effectiveFrom, effectiveTo, createdAt);
    }

    public SalaryStructure(int id, String employeeId, String employeeName, String department,
                           BigDecimal basicSalary, LocalDate effectiveFrom, LocalDate effectiveTo, Timestamp createdAt) {
        this.id = id;
        this.employeeId = employeeId;
        this.employeeName = employeeName;
        this.department = department;
        this.basicSalary = basicSalary != null ? basicSalary : BigDecimal.ZERO;
        this.effectiveFrom = effectiveFrom;
        this.effectiveTo = effectiveTo;
        this.createdAt = createdAt;
        this.components = new ArrayList<>();
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getEmployeeId() {
        return employeeId;
    }

    public void setEmployeeId(String employeeId) {
        this.employeeId = employeeId;
    }

    public String getEmployeeName() {
        return employeeName;
    }

    public void setEmployeeName(String employeeName) {
        this.employeeName = employeeName;
    }

    public String getDepartment() {
        return department;
    }

    public void setDepartment(String department) {
        this.department = department;
    }

    public BigDecimal getBasicSalary() {
        return basicSalary;
    }

    public void setBasicSalary(BigDecimal basicSalary) {
        this.basicSalary = basicSalary != null ? basicSalary : BigDecimal.ZERO;
    }

    public LocalDate getEffectiveFrom() {
        return effectiveFrom;
    }

    public void setEffectiveFrom(LocalDate effectiveFrom) {
        this.effectiveFrom = effectiveFrom;
    }

    public LocalDate getEffectiveTo() {
        return effectiveTo;
    }

    public void setEffectiveTo(LocalDate effectiveTo) {
        this.effectiveTo = effectiveTo;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    public List<SalaryComponent> getComponents() {
        return components;
    }

    public void setComponents(List<SalaryComponent> components) {
        this.components = components != null ? components : new ArrayList<>();
    }

    public List<SalaryComponent> getEarnings() {
        List<SalaryComponent> list = new ArrayList<>();
        if (components != null) {
            for (SalaryComponent c : components) {
                if (c.isEarning()) list.add(c);
            }
        }
        return list;
    }

    public List<SalaryComponent> getDeductions() {
        List<SalaryComponent> list = new ArrayList<>();
        if (components != null) {
            for (SalaryComponent c : components) {
                if (c.isDeduction()) list.add(c);
            }
        }
        return list;
    }

    public BigDecimal calculateTotalEarnings() {
        BigDecimal total = basicSalary != null ? basicSalary : BigDecimal.ZERO;
        for (SalaryComponent c : getEarnings()) {
            if (c.isPercentage()) {
                BigDecimal compAmt = basicSalary.multiply(c.getAmount())
                        .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
                total = total.add(compAmt);
            } else {
                total = total.add(c.getAmount());
            }
        }
        return total.setScale(2, RoundingMode.HALF_UP);
    }

    public BigDecimal calculateTotalDeductions() {
        BigDecimal total = BigDecimal.ZERO;
        for (SalaryComponent c : getDeductions()) {
            if (c.isPercentage()) {
                BigDecimal compAmt = basicSalary.multiply(c.getAmount())
                        .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
                total = total.add(compAmt);
            } else {
                total = total.add(c.getAmount());
            }
        }
        return total.setScale(2, RoundingMode.HALF_UP);
    }

    public BigDecimal calculateNetSalary() {
        return calculateTotalEarnings().subtract(calculateTotalDeductions()).setScale(2, RoundingMode.HALF_UP);
    }

    public boolean isActive() {
        return effectiveTo == null || effectiveTo.isAfter(LocalDate.now());
    }
}
