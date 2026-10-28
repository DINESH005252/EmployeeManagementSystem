package com.smartoffice.model;

import java.math.BigDecimal;
import java.math.RoundingMode;

public class AttendanceMetrics {
    private int totalWorkingDays;
    private BigDecimal presentDays;
    private BigDecimal paidLeaveDays;
    private BigDecimal unpaidDays;
    private BigDecimal unmarkedDays;
    private BigDecimal discrepancyDays;
    private String discrepancyNotes;

    public AttendanceMetrics() {
        this.totalWorkingDays = 30;
        this.presentDays = BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        this.paidLeaveDays = BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        this.unpaidDays = BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        this.unmarkedDays = BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        this.discrepancyDays = BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
    }

    public AttendanceMetrics(int totalWorkingDays, BigDecimal presentDays, BigDecimal paidLeaveDays, BigDecimal unpaidDays) {
        this(totalWorkingDays, presentDays, paidLeaveDays, unpaidDays,
             BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP), BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP), null);
    }

    public AttendanceMetrics(int totalWorkingDays, double presentDays, double paidLeaveDays, double unpaidDays) {
        this(totalWorkingDays, BigDecimal.valueOf(presentDays), BigDecimal.valueOf(paidLeaveDays), BigDecimal.valueOf(unpaidDays));
    }

    public AttendanceMetrics(int totalWorkingDays, BigDecimal presentDays, BigDecimal paidLeaveDays, BigDecimal unpaidDays,
                             BigDecimal unmarkedDays, BigDecimal discrepancyDays, String discrepancyNotes) {
        this.totalWorkingDays = totalWorkingDays;
        this.presentDays = presentDays != null ? presentDays.setScale(1, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        this.paidLeaveDays = paidLeaveDays != null ? paidLeaveDays.setScale(1, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        this.unpaidDays = unpaidDays != null ? unpaidDays.setScale(1, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        this.unmarkedDays = unmarkedDays != null ? unmarkedDays.setScale(1, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        this.discrepancyDays = discrepancyDays != null ? discrepancyDays.setScale(1, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        this.discrepancyNotes = discrepancyNotes;
    }

    public AttendanceMetrics(int totalWorkingDays, double presentDays, double paidLeaveDays, double unpaidDays,
                             double unmarkedDays, double discrepancyDays, String discrepancyNotes) {
        this(totalWorkingDays, BigDecimal.valueOf(presentDays), BigDecimal.valueOf(paidLeaveDays), BigDecimal.valueOf(unpaidDays),
             BigDecimal.valueOf(unmarkedDays), BigDecimal.valueOf(discrepancyDays), discrepancyNotes);
    }

    public int getTotalWorkingDays() { return totalWorkingDays; }
    public void setTotalWorkingDays(int totalWorkingDays) { this.totalWorkingDays = totalWorkingDays; }

    public BigDecimal getPresentDays() { return presentDays; }
    public void setPresentDays(BigDecimal presentDays) {
        this.presentDays = presentDays != null ? presentDays.setScale(1, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
    }
    public void setPresentDays(double presentDays) { setPresentDays(BigDecimal.valueOf(presentDays)); }

    public BigDecimal getPaidLeaveDays() { return paidLeaveDays; }
    public void setPaidLeaveDays(BigDecimal paidLeaveDays) {
        this.paidLeaveDays = paidLeaveDays != null ? paidLeaveDays.setScale(1, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
    }
    public void setPaidLeaveDays(double paidLeaveDays) { setPaidLeaveDays(BigDecimal.valueOf(paidLeaveDays)); }

    public BigDecimal getUnpaidDays() { return unpaidDays; }
    public void setUnpaidDays(BigDecimal unpaidDays) {
        this.unpaidDays = unpaidDays != null ? unpaidDays.setScale(1, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
    }
    public void setUnpaidDays(double unpaidDays) { setUnpaidDays(BigDecimal.valueOf(unpaidDays)); }

    public BigDecimal getUnmarkedDays() { return unmarkedDays; }
    public void setUnmarkedDays(BigDecimal unmarkedDays) {
        this.unmarkedDays = unmarkedDays != null ? unmarkedDays.setScale(1, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
    }
    public void setUnmarkedDays(double unmarkedDays) { setUnmarkedDays(BigDecimal.valueOf(unmarkedDays)); }

    public BigDecimal getDiscrepancyDays() { return discrepancyDays; }
    public void setDiscrepancyDays(BigDecimal discrepancyDays) {
        this.discrepancyDays = discrepancyDays != null ? discrepancyDays.setScale(1, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
    }
    public void setDiscrepancyDays(double discrepancyDays) { setDiscrepancyDays(BigDecimal.valueOf(discrepancyDays)); }

    public String getDiscrepancyNotes() { return discrepancyNotes; }
    public void setDiscrepancyNotes(String discrepancyNotes) { this.discrepancyNotes = discrepancyNotes; }

    public boolean hasDiscrepancy() {
        return discrepancyDays != null && discrepancyDays.compareTo(BigDecimal.ZERO) > 0;
    }
}
