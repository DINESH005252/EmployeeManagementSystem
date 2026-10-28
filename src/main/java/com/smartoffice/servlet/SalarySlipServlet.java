package com.smartoffice.servlet;

import com.smartoffice.model.Payroll;
import com.smartoffice.service.PayrollService;
import com.smartoffice.util.RequestValidator;
import model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet(urlPatterns = { "/payroll/salary-slip" })
public class SalarySlipServlet extends HttpServlet {
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

        String idStr = req.getParameter("id");
        if (idStr == null || idStr.trim().isEmpty()) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Salary slip not found.");
            return;
        }

        Payroll payroll = null;
        try {
            int id = RequestValidator.parsePositiveInt(idStr, "Payroll ID");
            payroll = payrollService.getPayrollById(id);
        } catch (Exception e) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Salary slip not found.");
            return;
        }

        if (payroll == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Salary slip not found.");
            return;
        }

        // Authorization check: Non-HR can ONLY view their own FINALIZED (PROCESSED or PAID) slip.
        // Returning 404 for both 'not found' and 'not authorized' prevents ID enumeration attacks.
        if (!user.isHr()) {
            boolean isOwnRecord = payroll.getEmployeeId() != null &&
                    payroll.getEmployeeId().equalsIgnoreCase(user.getEmployeeId());
            boolean isFinalized = payroll.isProcessed() || payroll.isPaid();

            if (!isOwnRecord || !isFinalized) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Salary slip not found.");
                return;
            }
        }

        req.setAttribute("payroll", payroll);
        req.getRequestDispatcher("/payroll/salary-slip.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED, "POST method is not supported for salary slips.");
    }
}
