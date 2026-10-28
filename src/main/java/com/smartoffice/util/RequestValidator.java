package com.smartoffice.util;

import dao.EmployeeDAO;
import dao.ManagerDAO;
import model.Employee;
import model.Manager;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeParseException;
import java.util.regex.Pattern;

public class RequestValidator {

    private static final Pattern EMP_ID_PATTERN = Pattern.compile("^[A-Za-z0-9_-]{2,20}$");
    private static final BigDecimal MAX_MONEY = new BigDecimal("99999999.99");

    public static int parseMonth(String monthStr) {
        if (monthStr == null || monthStr.trim().isEmpty()) {
            throw new PayrollException("Payroll month is required.");
        }
        try {
            int m = Integer.parseInt(monthStr.trim());
            if (m < 1 || m > 12) {
                throw new PayrollException("Invalid payroll month: " + m + ". Must be between 1 and 12.");
            }
            return m;
        } catch (NumberFormatException e) {
            throw new PayrollException("Invalid payroll month format.");
        }
    }

    public static int parseYear(String yearStr) {
        if (yearStr == null || yearStr.trim().isEmpty()) {
            throw new PayrollException("Payroll year is required.");
        }
        int curYear = LocalDate.now().getYear();
        try {
            int y = Integer.parseInt(yearStr.trim());
            if (y < 2000 || y > curYear + 1) {
                throw new PayrollException("Payroll year must be between 2000 and " + (curYear + 1) + ".");
            }
            return y;
        } catch (NumberFormatException e) {
            throw new PayrollException("Invalid payroll year format.");
        }
    }

    public static void validatePeriodNotFuture(int month, int year) {
        YearMonth selected = YearMonth.of(year, month);
        YearMonth current = YearMonth.now();
        if (selected.isAfter(current)) {
            throw new PayrollException("Cannot process or generate payroll for future periods (" + selected + ").");
        }
    }

    public static int parsePositiveInt(String str, String fieldName) {
        if (str == null || str.trim().isEmpty()) {
            throw new PayrollException(fieldName + " is required.");
        }
        try {
            int val = Integer.parseInt(str.trim());
            if (val <= 0) {
                throw new PayrollException(fieldName + " must be a positive integer.");
            }
            return val;
        } catch (NumberFormatException e) {
            throw new PayrollException("Invalid numeric format for " + fieldName + ".");
        }
    }

    public static BigDecimal parseMoney(String str, String fieldName) {
        if (str == null || str.trim().isEmpty()) {
            throw new PayrollException(fieldName + " is required.");
        }
        try {
            BigDecimal val = new BigDecimal(str.trim());
            if (val.compareTo(BigDecimal.ZERO) < 0) {
                throw new PayrollException(fieldName + " cannot be negative.");
            }
            if (val.scale() > 2) {
                throw new PayrollException(fieldName + " cannot have more than 2 decimal places.");
            }
            if (val.compareTo(MAX_MONEY) > 0) {
                throw new PayrollException(fieldName + " exceeds the maximum allowed value of 99,999,999.99.");
            }
            return val.setScale(2, RoundingMode.HALF_UP);
        } catch (NumberFormatException e) {
            throw new PayrollException("Invalid monetary amount for " + fieldName + ".");
        }
    }

    public static LocalDate parseDate(String dateStr, String fieldName) {
        if (dateStr == null || dateStr.trim().isEmpty()) {
            throw new PayrollException(fieldName + " is required.");
        }
        try {
            return LocalDate.parse(dateStr.trim());
        } catch (DateTimeParseException e) {
            throw new PayrollException("Invalid date format for " + fieldName + " (expected YYYY-MM-DD).");
        }
    }

    public static BigDecimal parseDaysBigDecimal(String daysStr, String fieldName) {
        if (daysStr == null || daysStr.trim().isEmpty()) {
            throw new PayrollException(fieldName + " is required.");
        }
        try {
            BigDecimal d = new BigDecimal(daysStr.trim());
            if (d.compareTo(BigDecimal.ZERO) < 0 || d.compareTo(new BigDecimal("31")) > 0) {
                throw new PayrollException(fieldName + " must be between 0 and 31 days.");
            }
            // Check multiples of 0.5
            BigDecimal doubled = d.multiply(new BigDecimal("2"));
            if (doubled.remainder(BigDecimal.ONE).compareTo(BigDecimal.ZERO) != 0) {
                throw new PayrollException(fieldName + " must be in multiples of 0.5 days.");
            }
            return d.setScale(1, RoundingMode.HALF_UP);
        } catch (NumberFormatException e) {
            throw new PayrollException("Invalid days count for " + fieldName + ".");
        }
    }

    public static double parseDays(String daysStr, String fieldName) {
        return parseDaysBigDecimal(daysStr, fieldName).doubleValue();
    }

    public static String requireEmployeeId(String empId, EmployeeDAO employeeDAO, ManagerDAO managerDAO) {
        if (empId == null || empId.trim().isEmpty()) {
            throw new PayrollException("Employee ID is required.");
        }
        String id = empId.trim().toUpperCase();
        if (!EMP_ID_PATTERN.matcher(id).matches()) {
            throw new PayrollException("Invalid Employee ID format.");
        }
        Employee emp = employeeDAO != null ? employeeDAO.findById(id) : null;
        if (emp != null) {
            if (!emp.isActive()) {
                throw new PayrollException("Employee " + id + " is not active.");
            }
            return id;
        }
        Manager mgr = managerDAO != null ? managerDAO.findById(id) : null;
        if (mgr != null) {
            if (!mgr.isActive()) {
                throw new PayrollException("Manager " + id + " is not active.");
            }
            return id;
        }
        throw new PayrollException("No active employee or manager found with ID: " + id);
    }

    public static <T extends Enum<T>> T enumOf(Class<T> enumClass, String value, String fieldName) {
        if (value == null || value.trim().isEmpty()) {
            throw new PayrollException(fieldName + " is required.");
        }
        try {
            return Enum.valueOf(enumClass, value.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new PayrollException("Invalid value for " + fieldName + ": " + value);
        }
    }
}
