package com.smartoffice.dao;

import com.smartoffice.model.PayrollPayment;
import com.smartoffice.util.PayrollException;
import util.DBConnection;

import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

public class PayrollPaymentDAO {

    private static final Logger LOGGER = Logger.getLogger(PayrollPaymentDAO.class.getName());

    private static final Set<String> ALLOWED_METHODS = Set.of(
            "BANK_TRANSFER", "CHEQUE", "CASH", "UPI", "OTHER"
    );

    public PayrollPayment findByPayrollId(int payrollId) {
        String sql = "SELECT id, payroll_id, payment_date, payment_method, reference_number, amount_paid, notes, created_at " +
                     "FROM payroll_payments WHERE payroll_id = ? ORDER BY id DESC LIMIT 1";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, payrollId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return map(rs);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Database error retrieving payment for payroll ID: " + payrollId, e);
            throw new RuntimeException("A database error occurred while accessing payment data.");
        }
        return null;
    }

    public PayrollPayment recordPayment(PayrollPayment payment) {
        if (payment == null) {
            throw new PayrollException("Payment details cannot be null.");
        }

        LocalDate payDate = payment.getPaymentDate();
        if (payDate == null) {
            throw new PayrollException("Payment date is required.");
        }
        if (payDate.isAfter(LocalDate.now())) {
            throw new PayrollException("Payment date cannot be in the future.");
        }

        String rawMethod = payment.getPaymentMethod();
        if (rawMethod == null || rawMethod.trim().isEmpty()) {
            throw new PayrollException("Payment method is required.");
        }
        String normalizedMethod = rawMethod.trim().replace(" ", "_").toUpperCase();
        if (!ALLOWED_METHODS.contains(normalizedMethod)) {
            throw new PayrollException("Invalid payment method: " + rawMethod + ". Allowed: Bank Transfer, Cheque, UPI, Cash, Other.");
        }

        if (!"CASH".equalsIgnoreCase(normalizedMethod)) {
            if (payment.getReferenceNumber() == null || payment.getReferenceNumber().trim().isEmpty()) {
                throw new PayrollException("Reference / transaction number is required for " + rawMethod + ".");
            }
        }

        if (payment.getReferenceNumber() != null && payment.getReferenceNumber().length() > 100) {
            throw new PayrollException("Reference number cannot exceed 100 characters.");
        }
        if (payment.getNotes() != null && payment.getNotes().length() > 255) {
            throw new PayrollException("Payment notes cannot exceed 255 characters.");
        }

        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            // 1. SELECT payroll FOR UPDATE to lock row and verify status and net salary
            String checkPayrollSql = "SELECT status, net_salary FROM payroll WHERE id = ? FOR UPDATE";
            String currentStatus = null;
            BigDecimal netSalary = null;
            try (PreparedStatement checkPs = conn.prepareStatement(checkPayrollSql)) {
                checkPs.setInt(1, payment.getPayrollId());
                try (ResultSet rs = checkPs.executeQuery()) {
                    if (rs.next()) {
                        currentStatus = rs.getString("status");
                        netSalary = rs.getBigDecimal("net_salary");
                    } else {
                        throw new PayrollException("Payroll record #" + payment.getPayrollId() + " not found.");
                    }
                }
            }

            if (!"PROCESSED".equalsIgnoreCase(currentStatus)) {
                if ("PAID".equalsIgnoreCase(currentStatus)) {
                    throw new PayrollException("Payment has already been recorded for this payroll.");
                } else if ("DRAFT".equalsIgnoreCase(currentStatus)) {
                    throw new PayrollException("Payroll must be reviewed and finalized (PROCESSED) before recording payment.");
                } else {
                    throw new PayrollException("Cannot record payment for " + currentStatus + " payroll.");
                }
            }

            // 2. Validate amount_paid equals net_salary
            if (payment.getAmountPaid() == null || payment.getAmountPaid().compareTo(netSalary) != 0) {
                throw new PayrollException("Payment amount must equal the net salary payable (₹" + netSalary + ").");
            }

            // 3. Insert payment settlement record
            String insertPaySql = "INSERT INTO payroll_payments (payroll_id, payment_date, payment_method, reference_number, amount_paid, notes) " +
                                  "VALUES (?, ?, ?, ?, ?, ?)";
            try (PreparedStatement insPs = conn.prepareStatement(insertPaySql, Statement.RETURN_GENERATED_KEYS)) {
                insPs.setInt(1, payment.getPayrollId());
                insPs.setObject(2, payDate);
                insPs.setString(3, rawMethod.trim());
                insPs.setString(4, payment.getReferenceNumber() != null ? payment.getReferenceNumber().trim() : null);
                insPs.setBigDecimal(5, payment.getAmountPaid());
                insPs.setString(6, payment.getNotes() != null ? payment.getNotes().trim() : null);
                insPs.executeUpdate();

                try (ResultSet keys = insPs.getGeneratedKeys()) {
                    if (keys.next()) {
                        payment.setId(keys.getInt(1));
                    }
                }
            }

            // 4. Update payroll status to PAID
            String updatePayrollSql = "UPDATE payroll SET status = 'PAID' WHERE id = ? AND status = 'PROCESSED'";
            try (PreparedStatement upPs = conn.prepareStatement(updatePayrollSql)) {
                upPs.setInt(1, payment.getPayrollId());
                int rows = upPs.executeUpdate();
                if (rows == 0) {
                    throw new PayrollException("Failed to update status to PAID: record was modified concurrently.");
                }
            }

            conn.commit();
            return payment;
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ignored) {}
            }
            LOGGER.log(Level.SEVERE, "Database error recording payment for payroll ID: " + payment.getPayrollId(), e);
            if (e.getErrorCode() == 1062 || "23000".equals(e.getSQLState())) {
                throw new PayrollException("A payment has already been recorded for payroll #" + payment.getPayrollId() + ".");
            }
            throw new RuntimeException("A database error occurred while recording the payment.");
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (SQLException ignored) {}
            }
        }
    }

    private PayrollPayment map(ResultSet rs) throws SQLException {
        return new PayrollPayment(
                rs.getInt("id"),
                rs.getInt("payroll_id"),
                rs.getObject("payment_date", LocalDate.class),
                rs.getString("payment_method"),
                rs.getString("reference_number"),
                rs.getBigDecimal("amount_paid"),
                rs.getString("notes"),
                rs.getTimestamp("created_at")
        );
    }
}
