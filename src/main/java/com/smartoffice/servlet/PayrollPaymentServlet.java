package com.smartoffice.servlet;

import com.smartoffice.model.Payroll;
import com.smartoffice.service.PayrollService;
import com.smartoffice.util.CsrfUtil;
import com.smartoffice.util.PayrollException;
import com.smartoffice.util.RequestValidator;
import model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@WebServlet(urlPatterns = { "/payroll/payment" })
public class PayrollPaymentServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private PayrollService payrollService;

    @Override
    public void init() {
        this.payrollService = new PayrollService();
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        User user = (session == null) ? null : (User) session.getAttribute("user");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login.html");
            return;
        }

        if (!user.isHr()) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Access Denied: Only HR administrators can manage payroll payments.");
            return;
        }

        String idStr = req.getParameter("id");
        if (idStr == null || idStr.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/payroll/history");
            return;
        }

        try {
            int id = RequestValidator.parsePositiveInt(idStr, "Payroll ID");
            Payroll payroll = payrollService.getPayrollById(id);
            if (payroll == null) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Payroll record not found.");
                return;
            }

            req.setAttribute("payroll", payroll);
            req.getRequestDispatcher("/payroll/payroll-payment.jsp").forward(req, resp);
        } catch (Exception e) {
            resp.sendRedirect(req.getContextPath() + "/payroll/history");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        User user = (session == null) ? null : (User) session.getAttribute("user");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login.html");
            return;
        }

        if (!user.isHr()) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Access Denied: Only HR administrators can record payroll payments.");
            return;
        }

        // CSRF Check
        if (!CsrfUtil.validate(req)) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid or expired security token (CSRF).");
            return;
        }

        String idStr = req.getParameter("payrollId");
        int payrollId = 0;
        try {
            payrollId = RequestValidator.parsePositiveInt(idStr, "Payroll ID");
            LocalDate paymentDate = RequestValidator.parseDate(req.getParameter("paymentDate"), "Payment Date");
            String method = req.getParameter("paymentMethod");
            String ref = req.getParameter("referenceNumber");
            BigDecimal amountPaid = RequestValidator.parseMoney(req.getParameter("amountPaid"), "Amount Paid");
            String notes = req.getParameter("notes");

            payrollService.recordPayment(payrollId, paymentDate, method, ref, amountPaid, notes);

            sessionMessage(req, "successMessage", "Payment of ₹" + amountPaid + " recorded successfully for payroll #" + payrollId + ". Status updated to PAID.");
            resp.sendRedirect(req.getContextPath() + "/payroll/history");
        } catch (PayrollException pe) {
            sessionMessage(req, "errorMessage", pe.getMessage());
            resp.sendRedirect(req.getContextPath() + "/payroll/payment?id=" + payrollId);
        } catch (Exception e) {
            String ref = UUID.randomUUID().toString().substring(0, 8);
            getServletContext().log("Ref #" + ref + ": Error recording payment for payroll #" + payrollId, e);
            sessionMessage(req, "errorMessage", "An error occurred while recording payment (Ref #" + ref + ").");
            resp.sendRedirect(req.getContextPath() + "/payroll/payment?id=" + payrollId);
        }
    }

    private void sessionMessage(HttpServletRequest req, String key, String msg) {
        HttpSession s = req.getSession(false);
        if (s != null) {
            s.setAttribute(key, msg);
        }
    }
}
