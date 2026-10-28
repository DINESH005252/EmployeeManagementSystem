package com.smartoffice.model;

import java.math.BigDecimal;

public class PayrollItem {
    private int id;
    private int payrollId;
    private String componentName;
    private String componentType; // EARNING or DEDUCTION
    private BigDecimal amount;

    public PayrollItem() {
        this.amount = BigDecimal.ZERO;
    }

    public PayrollItem(int id, int payrollId, String componentName, String componentType, BigDecimal amount) {
        this.id = id;
        this.payrollId = payrollId;
        this.componentName = componentName;
        this.componentType = componentType;
        this.amount = amount != null ? amount : BigDecimal.ZERO;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getPayrollId() {
        return payrollId;
    }

    public void setPayrollId(int payrollId) {
        this.payrollId = payrollId;
    }

    public String getComponentName() {
        return componentName;
    }

    public void setComponentName(String componentName) {
        this.componentName = componentName;
    }

    public String getComponentType() {
        return componentType;
    }

    public void setComponentType(String componentType) {
        this.componentType = componentType;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount != null ? amount : BigDecimal.ZERO;
    }

    public boolean isEarning() {
        return "EARNING".equalsIgnoreCase(componentType);
    }

    public boolean isDeduction() {
        return "DEDUCTION".equalsIgnoreCase(componentType);
    }
}
