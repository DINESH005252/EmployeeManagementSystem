package com.smartoffice.util;

import com.smartoffice.model.PayrollItem;
import com.smartoffice.model.SalaryComponent;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

public class PayrollCalculator {

    private static final String[] UNITS = {
        "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten",
        "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"
    };

    private static final String[] TENS = {
        "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
    };

    public static BigDecimal calculateComponentAmount(SalaryComponent component, BigDecimal basicSalary) {
        if (component == null || basicSalary == null) {
            return BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        }
        if (component.isPercentage()) {
            return basicSalary.multiply(component.getAmount())
                    .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        } else {
            return component.getAmount().setScale(2, RoundingMode.HALF_UP);
        }
    }

    public static BigDecimal calculateLossOfPay(BigDecimal baseSalary, int totalWorkingDays, BigDecimal unpaidDays) {
        if (baseSalary == null || totalWorkingDays <= 0 || unpaidDays == null || unpaidDays.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        }
        BigDecimal dailyRate = baseSalary.divide(BigDecimal.valueOf(totalWorkingDays), 4, RoundingMode.HALF_UP);
        BigDecimal lop = dailyRate.multiply(unpaidDays.setScale(1, RoundingMode.HALF_UP));
        return lop.setScale(2, RoundingMode.HALF_UP);
    }

    public static BigDecimal calculateLossOfPay(BigDecimal baseSalary, int totalWorkingDays, double unpaidDays) {
        return calculateLossOfPay(baseSalary, totalWorkingDays, BigDecimal.valueOf(unpaidDays).setScale(1, RoundingMode.HALF_UP));
    }

    public static BigDecimal calculateGrossSalary(BigDecimal basicSalary, List<PayrollItem> earnings) {
        BigDecimal total = basicSalary != null ? basicSalary : BigDecimal.ZERO;
        if (earnings != null) {
            for (PayrollItem item : earnings) {
                if (item != null && item.isEarning()) {
                    total = total.add(item.getAmount() != null ? item.getAmount() : BigDecimal.ZERO);
                }
            }
        }
        return total.setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Calculates total deductions strictly from deduction PayrollItems (which includes LOP if applicable).
     * Prevents double counting of loss of pay.
     */
    public static BigDecimal calculateTotalDeductions(List<PayrollItem> deductions) {
        BigDecimal total = BigDecimal.ZERO;
        if (deductions != null) {
            for (PayrollItem item : deductions) {
                if (item != null && item.isDeduction()) {
                    total = total.add(item.getAmount() != null ? item.getAmount() : BigDecimal.ZERO);
                }
            }
        }
        return total.setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Calculates Net Salary = Gross Salary - Total Deductions.
     * Does NOT silently clamp negative amounts to zero so that discrepancies can be audited.
     */
    public static BigDecimal calculateNetSalary(BigDecimal grossSalary, BigDecimal totalDeductions) {
        BigDecimal gross = grossSalary != null ? grossSalary : BigDecimal.ZERO;
        BigDecimal deductions = totalDeductions != null ? totalDeductions : BigDecimal.ZERO;
        return gross.subtract(deductions).setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Converts a monetary amount to Indian Rupee words (e.g. "Rupees Fifty Thousand Two Hundred Only").
     */
    public static String convertToWords(BigDecimal amount) {
        if (amount == null) return "Zero Rupees Only";
        long wholePart = amount.setScale(2, RoundingMode.HALF_UP).longValue();
        int paise = amount.setScale(2, RoundingMode.HALF_UP).remainder(BigDecimal.ONE)
                .multiply(BigDecimal.valueOf(100)).intValue();

        if (wholePart == 0 && paise == 0) return "Zero Rupees Only";

        StringBuilder words = new StringBuilder("Rupees ");
        if (wholePart > 0) {
            words.append(convertNumberToWordsIndian(wholePart)).append(" ");
        }
        if (paise > 0) {
            if (wholePart > 0) words.append("and ");
            words.append(convertTwoDigits(paise)).append(" Paise ");
        }
        words.append("Only");
        return words.toString().replaceAll("\\s+", " ").trim();
    }

    private static String convertNumberToWordsIndian(long n) {
        if (n == 0) return "";
        if (n >= 10000000) {
            return convertNumberToWordsIndian(n / 10000000) + " Crore " + convertNumberToWordsIndian(n % 10000000);
        }
        if (n >= 100000) {
            return convertNumberToWordsIndian(n / 100000) + " Lakh " + convertNumberToWordsIndian(n % 100000);
        }
        if (n >= 1000) {
            return convertNumberToWordsIndian(n / 1000) + " Thousand " + convertNumberToWordsIndian(n % 1000);
        }
        if (n >= 100) {
            return convertNumberToWordsIndian(n / 100) + " Hundred " + convertNumberToWordsIndian(n % 100);
        }
        return convertTwoDigits((int) n);
    }

    private static String convertTwoDigits(int n) {
        if (n < 20) {
            return UNITS[n];
        }
        return TENS[n / 10] + ((n % 10 != 0) ? "-" + UNITS[n % 10] : "");
    }
}
