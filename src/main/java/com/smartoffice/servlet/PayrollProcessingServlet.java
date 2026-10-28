package com.smartoffice.servlet;

import com.smartoffice.model.Payroll;
import com.smartoffice.model.SalaryStructure;
import com.smartoffice.service.PayrollService;
import com.smartoffice.util.CsrfUtil;
import com.smartoffice.util.PayrollException;
import com.smartoffice.util.RequestValidator;
import model.Employee;
import model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@WebServlet(urlPatterns = { "/payroll/processing" })
public class PayrollProcessingServlet extends HttpServlet {
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
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Access Denied: Only HR administrators can process payroll.");
            return;
        }

        LocalDate now = LocalDate.now();
        int month = now.getMonthValue();
        int year = now.getYear();

        String monthStr = req.getParameter("month");
        String yearStr = req.getParameter("year");

        try {
            if (monthStr != null && !monthStr.trim().isEmpty()) {
                month = RequestValidator.parseMonth(monthStr);
            }
            if (yearStr != null && !yearStr.trim().isEmpty()) {
                year = RequestValidator.parseYear(yearStr);
            }
            RequestValidator.validatePeriodNotFuture(month, year);
        } catch (PayrollException pe) {
            sessionMessage(req, "errorMessage", pe.getMessage());
            month = now.getMonthValue();
            year = now.getYear();
        }

        String applyAttParam = req.getParameter("applyAttendance");
        boolean applyAttendance = (applyAttParam == null) || "true".equalsIgnoreCase(applyAttParam);

        List<Employee> eligible = payrollService.getEligibleEmployees();
        List<Payroll> previewList = new ArrayList<>();
        List<String> missingStructures = new ArrayList<>();

        for (Employee emp : eligible) {
            try {
                Payroll existing = payrollService.getPayrollByEmployeeAndPeriod(emp.getId(), month, year);
                if (existing != null) {
                    previewList.add(existing);
                } else {
                    SalaryStructure ss = payrollService.getSalaryStructure(emp.getId());
                    if (ss == null) {
                        missingStructures.add(emp.getId() + " (" + emp.getName() + ")");
                        continue;
                    }
                    Payroll draft = payrollService.prepareDraftPayroll(emp.getId(), month, year, applyAttendance,
                            null, (BigDecimal) null, null, null, null);
                    previewList.add(draft);
                }
            } catch (PayrollException pe) {
                getServletContext().log("Payroll preview failed for employee " + emp.getId(), pe);
                missingStructures.add(emp.getId() + " (" + emp.getName() + "): " + pe.getMessage());
            } catch (Exception ex) {
                getServletContext().log("Payroll preview failed for employee " + emp.getId(), ex);
                missingStructures.add(emp.getId() + " (" + emp.getName() + "): could not prepare payroll - review salary structure/attendance");
            }
        }

        req.setAttribute("selectedMonth", month);
        req.setAttribute("selectedYear", year);
        req.setAttribute("applyAttendance", applyAttendance);
        req.setAttribute("previewList", previewList);
        req.setAttribute("missingStructures", missingStructures);

        req.getRequestDispatcher("/payroll/payroll-processing.jsp").forward(req, resp);
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
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Access Denied: Only HR administrators can process payroll.");
            return;
        }

        // CSRF Protection
        if (!CsrfUtil.validate(req)) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid or expired security token (CSRF).");
            return;
        }

        boolean applyAttendance = "true".equalsIgnoreCase(req.getParameter("applyAttendance"));
        int month = LocalDate.now().getMonthValue();
        int year = LocalDate.now().getYear();

        try {
            month = RequestValidator.parseMonth(req.getParameter("month"));
            year = RequestValidator.parseYear(req.getParameter("year"));
            RequestValidator.validatePeriodNotFuture(month, year);
        } catch (PayrollException pe) {
            sessionMessage(req, "errorMessage", pe.getMessage());
            resp.sendRedirect(req.getContextPath() + "/payroll/processing?month=" + month + "&year=" + year +
                    "&applyAttendance=" + applyAttendance);
            return;
        }

        String action = req.getParameter("action");

        try {
            if ("generate_all".equalsIgnoreCase(action) || "process_all".equalsIgnoreCase(action)) {
                // Spec 2.2: Generate DRAFTs for review before finalizing
                PayrollService.BatchGenerationResult res = payrollService.generateAllDrafts(month, year, user.getUsername(), applyAttendance);
                StringBuilder msg = new StringBuilder();
                msg.append("Payroll generation completed: ")
                   .append(res.getGeneratedCount()).append(" draft(s) created, ")
                   .append(res.getSkippedCount()).append(" skipped (already finalized).");
                if (!res.getFailures().isEmpty()) {
                    msg.append(" ").append(res.getFailures().size()).append(" issue(s): ")
                       .append(String.join("; ", res.getFailures()));
                }
                sessionMessage(req, "successMessage", msg.toString());

            } else if ("finalize_single".equalsIgnoreCase(action)) {
                String pidParam = req.getParameter("payrollId");
                if (pidParam == null || pidParam.trim().isEmpty()) {
                    pidParam = req.getParameter("id");
                }
                int payrollId = RequestValidator.parsePositiveInt(pidParam, "Payroll ID");
                payrollService.finalizeSingle(payrollId, user.getUsername());
                sessionMessage(req, "successMessage", "Payroll #" + payrollId + " finalized successfully (Status: PROCESSED).");

            } else if ("finalize_all".equalsIgnoreCase(action)) {
                int finalized = payrollService.finalizeAllDrafts(month, year, user.getUsername());
                sessionMessage(req, "successMessage", "Finalized " + finalized + " payroll record(s) to PROCESSED status.");

            } else if ("save_override".equalsIgnoreCase(action)) {
                String empId = req.getParameter("employeeId");
                if (empId == null || empId.trim().isEmpty()) {
                    empId = req.getParameter("id");
                }
                String remarks = req.getParameter("remarks");
                if (remarks == null || remarks.trim().isEmpty()) {
                    throw new PayrollException("Adjustment remarks are required when manually modifying attendance days.");
                }

                String wStr = req.getParameter("workingDays");
                String pStr = req.getParameter("presentDays");
                String plStr = req.getParameter("paidLeaveDays");
                String uStr = req.getParameter("unpaidDays");

                int workingDays = (wStr != null && !wStr.trim().isEmpty())
                        ? RequestValidator.parsePositiveInt(wStr, "Working Days") : 30;
                BigDecimal presentDays = (pStr != null && !pStr.trim().isEmpty())
                        ? RequestValidator.parseDaysBigDecimal(pStr, "Present Days") : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
                BigDecimal paidLeaves = (plStr != null && !plStr.trim().isEmpty())
                        ? RequestValidator.parseDaysBigDecimal(plStr, "Paid Leave Days") : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
                BigDecimal unpaidDays = (uStr != null && !uStr.trim().isEmpty())
                        ? RequestValidator.parseDaysBigDecimal(uStr, "Unpaid Days") : BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);

                BigDecimal workingDaysBD = BigDecimal.valueOf(workingDays);
                if (presentDays.compareTo(workingDaysBD) > 0) {
                    throw new PayrollException("Present days cannot exceed total working days (" + workingDays + ").");
                }
                if (presentDays.add(paidLeaves).add(unpaidDays).compareTo(workingDaysBD) > 0) {
                    throw new PayrollException("Total days (present + paid leave + unpaid) cannot exceed working days (" + workingDays + ").");
                }

                Payroll draft = payrollService.prepareDraftPayroll(empId, month, year, applyAttendance,
                        workingDays, presentDays, paidLeaves, unpaidDays, remarks.trim());
                draft.setStatus("DRAFT");
                draft.setProcessedBy(user.getUsername());
                // Save draft record in DB
                com.smartoffice.dao.PayrollDAO dao = new com.smartoffice.dao.PayrollDAO();
                dao.save(draft);

                sessionMessage(req, "successMessage", "Attendance override saved for " + empId + " (Status: DRAFT).");

            } else if ("cancel".equalsIgnoreCase(action)) {
                String pidParam = req.getParameter("payrollId");
                if (pidParam == null || pidParam.trim().isEmpty()) {
                    pidParam = req.getParameter("id");
                }
                int payrollId = RequestValidator.parsePositiveInt(pidParam, "Payroll ID");
                String reason = req.getParameter("reason");
                if (reason == null || reason.trim().isEmpty()) {
                    reason = req.getParameter("cancelReason");
                }
                if (reason == null || reason.trim().isEmpty()) {
                    throw new PayrollException("Cancellation reason is required.");
                }
                payrollService.cancelPayroll(payrollId, reason.trim(), user.getUsername());
                sessionMessage(req, "successMessage", "Payroll #" + payrollId + " marked as CANCELLED.");
            }
        } catch (PayrollException pe) {
            sessionMessage(req, "errorMessage", pe.getMessage());
        } catch (Exception e) {
            String ref = UUID.randomUUID().toString().substring(0, 8);
            getServletContext().log("Ref #" + ref + ": Error processing payroll action=" + action, e);
            sessionMessage(req, "errorMessage", "An error occurred while processing payroll (Ref #" + ref + ").");
        }

        resp.sendRedirect(req.getContextPath() + "/payroll/processing?month=" + month + "&year=" + year +
                "&applyAttendance=" + applyAttendance);
    }

    private void sessionMessage(HttpServletRequest req, String key, String msg) {
        HttpSession s = req.getSession(false);
        if (s != null) {
            s.setAttribute(key, msg);
        }
    }
}
