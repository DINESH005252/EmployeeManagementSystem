package com.smartoffice.model;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.LocalDate;

public class PayrollPayment {
    private int id;
    private int payrollId;
    private LocalDate paymentDate;
    private String paymentMethod;    // Bank Transfer, Cheque, UPI, Cash
    private String referenceNumber;
    private BigDecimal amountPaid;
    private String notes;
    private Timestamp createdAt;

    public PayrollPayment() {
        this.amountPaid = BigDecimal.ZERO;
    }

    public PayrollPayment(int id, int payrollId, LocalDate paymentDate, String paymentMethod,
                          String referenceNumber, BigDecimal amountPaid, String notes, Timestamp createdAt) {
        this.id = id;
        this.payrollId = payrollId;
        this.paymentDate = paymentDate;
        this.paymentMethod = paymentMethod;
        this.referenceNumber = referenceNumber;
        this.amountPaid = amountPaid != null ? amountPaid : BigDecimal.ZERO;
        this.notes = notes;
        this.createdAt = createdAt;
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

    public LocalDate getPaymentDate() {
        return paymentDate;
    }

    public void setPaymentDate(LocalDate paymentDate) {
        this.paymentDate = paymentDate;
    }

    public String getPaymentMethod() {
        return paymentMethod;
    }

    public void setPaymentMethod(String paymentMethod) {
        this.paymentMethod = paymentMethod;
    }

    public String getReferenceNumber() {
        return referenceNumber;
    }

    public void setReferenceNumber(String referenceNumber) {
        this.referenceNumber = referenceNumber;
    }

    public BigDecimal getAmountPaid() {
        return amountPaid;
    }

    public void setAmountPaid(BigDecimal amountPaid) {
        this.amountPaid = amountPaid != null ? amountPaid : BigDecimal.ZERO;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}
