package com.smartoffice.util;

import com.smartoffice.model.PayrollItem;
import com.smartoffice.model.SalaryComponent;
import com.smartoffice.service.PayrollService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("PayrollCalculator and Workflow Unit Tests")
public class PayrollCalculatorTest {

    @Test
    @DisplayName("Fixed Component: should return exact fixed amount with scale 2")
    public void testFixedComponentCalculation() {
        SalaryComponent comp = new SalaryComponent(1, 10, "Conveyance", "EARNING", "FIXED", new BigDecimal("2500.00"), "Fixed Conveyance");
        BigDecimal result = PayrollCalculator.calculateComponentAmount(comp, new BigDecimal("50000.00"));
        assertEquals(new BigDecimal("2500.00"), result);
    }

    @Test
    @DisplayName("Percentage Component: should calculate percentage of basic salary")
    public void testPercentageComponentCalculation() {
        SalaryComponent comp = new SalaryComponent(2, 10, "HRA", "EARNING", "PERCENTAGE", new BigDecimal("40.00"), "HRA 40%");
        BigDecimal result = PayrollCalculator.calculateComponentAmount(comp, new BigDecimal("60000.00"));
        assertEquals(new BigDecimal("24000.00"), result);

        SalaryComponent pf = new SalaryComponent(3, 10, "PF", "DEDUCTION", "PERCENTAGE", new BigDecimal("12.00"), "EPF 12%");
        BigDecimal pfResult = PayrollCalculator.calculateComponentAmount(pf, new BigDecimal("50000.00"));
        assertEquals(new BigDecimal("6000.00"), pfResult);
    }

    @Test
    @DisplayName("Rounding: percentage calculations must round using HALF_UP")
    public void testPercentageRoundingHalfUp() {
        // 33.33% of 1000.05 = 333.316665 -> rounds to 333.32
        SalaryComponent comp = new SalaryComponent(4, 10, "Special", "EARNING", "PERCENTAGE", new BigDecimal("33.33"), "Test Rounding");
        BigDecimal result = PayrollCalculator.calculateComponentAmount(comp, new BigDecimal("1000.05"));
        assertEquals(new BigDecimal("333.32"), result);

        // 12.5% of 100.05 = 12.50625 -> rounds to 12.51
        SalaryComponent comp2 = new SalaryComponent(5, 10, "Rate", "EARNING", "PERCENTAGE", new BigDecimal("12.50"), "Test Half-Up");
        BigDecimal result2 = PayrollCalculator.calculateComponentAmount(comp2, new BigDecimal("100.05"));
        assertEquals(new BigDecimal("12.51"), result2);
    }

    @Test
    @DisplayName("Loss of Pay: zero unpaid days returns 0.00")
    public void testLossOfPayZeroUnpaidDays() {
        BigDecimal base = new BigDecimal("44000.00");
        BigDecimal lop = PayrollCalculator.calculateLossOfPay(base, 22, BigDecimal.ZERO);
        assertEquals(new BigDecimal("0.00"), lop);

        BigDecimal lopDouble = PayrollCalculator.calculateLossOfPay(base, 22, 0.0);
        assertEquals(new BigDecimal("0.00"), lopDouble);
    }

    @Test
    @DisplayName("Loss of Pay: half-day unpaid calculation with BigDecimal")
    public void testLossOfPayHalfDay() {
        BigDecimal base = new BigDecimal("44000.00");
        // 44000 / 22 = 2000 per day; 0.5 day = 1000.00
        BigDecimal lop = PayrollCalculator.calculateLossOfPay(base, 22, new BigDecimal("0.5"));
        assertEquals(new BigDecimal("1000.00"), lop);

        BigDecimal lopDouble = PayrollCalculator.calculateLossOfPay(base, 22, 0.5);
        assertEquals(new BigDecimal("1000.00"), lopDouble);
    }

    @Test
    @DisplayName("Loss of Pay: across varying month lengths (28, 29, 30, 31 working days) with HALF_UP rounding")
    public void testLossOfPayAcrossMonthLengths() {
        BigDecimal base = new BigDecimal("62000.00");

        // 31 days month: 62000 / 31 = 2000.00 per day; 2 days = 4000.00
        BigDecimal lop31 = PayrollCalculator.calculateLossOfPay(base, 31, new BigDecimal("2.0"));
        assertEquals(new BigDecimal("4000.00"), lop31);

        // 30 days month: 62000 / 30 = 2066.6667 per day; 1 day = 2066.67
        BigDecimal lop30 = PayrollCalculator.calculateLossOfPay(base, 30, new BigDecimal("1.0"));
        assertEquals(new BigDecimal("2066.67"), lop30);

        // 29 days month: 58000 / 29 = 2000.00 per day; 3 days = 6000.00
        BigDecimal lop29 = PayrollCalculator.calculateLossOfPay(new BigDecimal("58000.00"), 29, new BigDecimal("3.0"));
        assertEquals(new BigDecimal("6000.00"), lop29);

        // 28 days month: 56000 / 28 = 2000.00 per day; 1.5 days = 3000.00
        BigDecimal lop28 = PayrollCalculator.calculateLossOfPay(new BigDecimal("56000.00"), 28, new BigDecimal("1.5"));
        assertEquals(new BigDecimal("3000.00"), lop28);
    }

    @Test
    @DisplayName("Gross Salary: sums basic salary and all earning items")
    public void testCalculateGrossSalary() {
        BigDecimal basic = new BigDecimal("50000.00");
        List<PayrollItem> items = new ArrayList<>();
        items.add(new PayrollItem(1, 100, "HRA", "EARNING", new BigDecimal("20000.00")));
        items.add(new PayrollItem(2, 100, "Conveyance", "EARNING", new BigDecimal("2500.00")));
        items.add(new PayrollItem(3, 100, "PF", "DEDUCTION", new BigDecimal("6000.00"))); // deduction should be ignored

        BigDecimal gross = PayrollCalculator.calculateGrossSalary(basic, items);
        assertEquals(new BigDecimal("72500.00"), gross);
    }

    @Test
    @DisplayName("Total Deductions: sums strictly deduction items")
    public void testCalculateTotalDeductions() {
        List<PayrollItem> items = new ArrayList<>();
        items.add(new PayrollItem(1, 100, "HRA", "EARNING", new BigDecimal("20000.00")));
        items.add(new PayrollItem(2, 100, "PF", "DEDUCTION", new BigDecimal("6000.00")));
        items.add(new PayrollItem(3, 100, "PT", "DEDUCTION", new BigDecimal("200.00")));
        items.add(new PayrollItem(4, 100, "Loss of Pay", "DEDUCTION", new BigDecimal("1500.00")));

        BigDecimal deductions = PayrollCalculator.calculateTotalDeductions(items);
        assertEquals(new BigDecimal("7700.00"), deductions);
    }

    @Test
    @DisplayName("Net Salary: gross minus total deductions")
    public void testCalculateNetSalaryStandard() {
        BigDecimal gross = new BigDecimal("72500.00");
        BigDecimal deductions = new BigDecimal("7700.00");
        BigDecimal net = PayrollCalculator.calculateNetSalary(gross, deductions);
        assertEquals(new BigDecimal("64800.00"), net);
    }

    @Test
    @DisplayName("Negative Net Salary: when deductions exceed gross, do NOT clamp to zero")
    public void testNetSalaryDeductionsExceedGross() {
        BigDecimal gross = new BigDecimal("20000.00");
        BigDecimal deductions = new BigDecimal("25000.00");
        BigDecimal net = PayrollCalculator.calculateNetSalary(gross, deductions);
        assertEquals(new BigDecimal("-5000.00"), net);
    }

    @Test
    @DisplayName("Status Transition Rules: defined lifecycle workflow")
    public void testStatusTransitions() {
        // Valid transitions
        assertTrue(PayrollService.isValidTransition("DRAFT", "PROCESSED"));
        assertTrue(PayrollService.isValidTransition("DRAFT", "CANCELLED"));
        assertTrue(PayrollService.isValidTransition("PROCESSED", "PAID"));
        assertTrue(PayrollService.isValidTransition("PROCESSED", "CANCELLED"));

        // Invalid transitions
        assertFalse(PayrollService.isValidTransition("DRAFT", "PAID"));
        assertFalse(PayrollService.isValidTransition("PROCESSED", "DRAFT"));
        assertFalse(PayrollService.isValidTransition("PAID", "DRAFT"));
        assertFalse(PayrollService.isValidTransition("PAID", "PROCESSED"));
        assertFalse(PayrollService.isValidTransition("PAID", "CANCELLED"));
        assertFalse(PayrollService.isValidTransition("CANCELLED", "DRAFT"));
        assertFalse(PayrollService.isValidTransition("CANCELLED", "PROCESSED"));
        assertFalse(PayrollService.isValidTransition("CANCELLED", "PAID"));
        assertFalse(PayrollService.isValidTransition(null, "PROCESSED"));
        assertFalse(PayrollService.isValidTransition("DRAFT", null));
    }

    @Test
    @DisplayName("Null Safety: null arguments must not throw NullPointerException")
    public void testNullSafety() {
        assertDoesNotThrow(() -> {
            BigDecimal comp = PayrollCalculator.calculateComponentAmount(null, null);
            assertEquals(new BigDecimal("0.00"), comp);

            BigDecimal lop = PayrollCalculator.calculateLossOfPay(null, 0, (BigDecimal) null);
            assertEquals(new BigDecimal("0.00"), lop);

            BigDecimal gross = PayrollCalculator.calculateGrossSalary(null, null);
            assertEquals(new BigDecimal("0.00"), gross);

            BigDecimal ded = PayrollCalculator.calculateTotalDeductions(null);
            assertEquals(new BigDecimal("0.00"), ded);

            BigDecimal net = PayrollCalculator.calculateNetSalary(null, null);
            assertEquals(new BigDecimal("0.00"), net);

            String words = PayrollCalculator.convertToWords(null);
            assertEquals("Zero Rupees Only", words);
        });
    }

    @Test
    @DisplayName("Currency in Words: Indian numbering conversion")
    public void testConvertToWordsIndianNumbering() {
        assertEquals("Zero Rupees Only", PayrollCalculator.convertToWords(BigDecimal.ZERO));
        assertEquals("Rupees Fifty Thousand Only", PayrollCalculator.convertToWords(new BigDecimal("50000.00")));
        assertEquals("Rupees One Lakh Twenty-Five Thousand Four Hundred Only",
                PayrollCalculator.convertToWords(new BigDecimal("125400.00")));
        assertEquals("Rupees Forty-Five Thousand Two Hundred and Fifty Paise Only",
                PayrollCalculator.convertToWords(new BigDecimal("45200.50")));
    }
}
