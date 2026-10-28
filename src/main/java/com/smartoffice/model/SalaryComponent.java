package com.smartoffice.model;

import java.math.BigDecimal;

public class SalaryComponent {
    private int id;
    private int salaryStructureId;
    private String componentName;
    private String componentType;    // EARNING or DEDUCTION
    private String calculationType;  // FIXED or PERCENTAGE
    private BigDecimal amount;       // Fixed amount or percentage rate
    private String description;

    public SalaryComponent() {
        this.amount = BigDecimal.ZERO;
    }

    public SalaryComponent(int id, int salaryStructureId, String componentName,
                           String componentType, String calculationType, BigDecimal amount) {
        this(id, salaryStructureId, componentName, componentType, calculationType, amount, null);
    }

    public SalaryComponent(int id, int salaryStructureId, String componentName,
                           String componentType, String calculationType, BigDecimal amount, String description) {
        this.id = id;
        this.salaryStructureId = salaryStructureId;
        this.componentName = componentName;
        this.componentType = componentType;
        this.calculationType = calculationType;
        this.amount = amount != null ? amount : BigDecimal.ZERO;
        this.description = description;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getSalaryStructureId() {
        return salaryStructureId;
    }

    public void setSalaryStructureId(int salaryStructureId) {
        this.salaryStructureId = salaryStructureId;
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

    public String getCalculationType() {
        return calculationType;
    }

    public void setCalculationType(String calculationType) {
        this.calculationType = calculationType;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount != null ? amount : BigDecimal.ZERO;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public boolean isEarning() {
        return "EARNING".equalsIgnoreCase(componentType);
    }

    public boolean isDeduction() {
        return "DEDUCTION".equalsIgnoreCase(componentType);
    }

    public boolean isPercentage() {
        return "PERCENTAGE".equalsIgnoreCase(calculationType);
    }

    public boolean isFixed() {
        return "FIXED".equalsIgnoreCase(calculationType);
    }

    public BigDecimal calculateAmount(BigDecimal basicSalary) {
        if (basicSalary == null) basicSalary = BigDecimal.ZERO;
        if (isPercentage()) {
            return basicSalary.multiply(amount != null ? amount : BigDecimal.ZERO)
                    .divide(BigDecimal.valueOf(100), 2, java.math.RoundingMode.HALF_UP);
        }
        return amount != null ? amount : BigDecimal.ZERO;
    }
}
