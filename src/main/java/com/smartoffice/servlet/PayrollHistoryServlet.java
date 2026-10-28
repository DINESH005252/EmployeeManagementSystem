package com.smartoffice.servlet;

import com.smartoffice.dao.PayrollDAO;
import com.smartoffice.model.Payroll;
import com.smartoffice.service.PayrollService;
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
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.*;

@WebServlet(urlPatterns = { "/payroll/history" })
public class PayrollHistoryServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private static final Set<String> ALLOWED_STATUSES = Set.of("DRAFT", "PROCESSED", "PAID", "CANCELLED");

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

        List<Payroll> payrollList;
        BigDecimal totalGross = BigDecimal.ZERO;
        BigDecimal totalDeductions = BigDecimal.ZERO;
        BigDecimal totalNet = BigDecimal.ZERO;
        int draftCount = 0;
        int processedCount = 0;
        int paidCount = 0;
        int cancelledCount = 0;

        List<String> departmentList = payrollService.getDepartments();
        List<PayrollDAO.DeptSummary> deptSummaries = null;

        Integer month = null;
        Integer year = null;
        String department = null;
        String status = null;
        String employeeId = null;

        if (user.isHr()) {
            String monthStr = req.getParameter("month");
            String yearStr = req.getParameter("year");
            department = req.getParameter("department");
            status = req.getParameter("status");
            employeeId = req.getParameter("employeeId");

            try {
                if (monthStr != null && !monthStr.trim().isEmpty() && !"ALL".equalsIgnoreCase(monthStr)) {
                    month = RequestValidator.parseMonth(monthStr);
                }
                if (yearStr != null && !yearStr.trim().isEmpty() && !"ALL".equalsIgnoreCase(yearStr)) {
                    year = RequestValidator.parseYear(yearStr);
                }
            } catch (PayrollException pe) {
                session.setAttribute("errorMessage", pe.getMessage());
                month = null;
                year = null;
            }

            if (status != null) {
                status = status.trim().toUpperCase();
                if (!ALLOWED_STATUSES.contains(status) && !"ALL".equals(status)) {
                    status = null;
                }
            }

            if (department != null && !departmentList.contains(department.trim()) && !"ALL".equalsIgnoreCase(department)) {
                department = null;
            }

            // CSV Export option (HR only)
            if ("csv".equalsIgnoreCase(req.getParameter("export"))) {
                exportCsv(resp, month, year, department, status, employeeId);
                return;
            }

            payrollList = payrollService.getPayrollList(month, year, department, status, employeeId);
            deptSummaries = payrollService.getDepartmentSummary(month, year);

            req.setAttribute("selectedMonth", month);
            req.setAttribute("selectedYear", year);
            req.setAttribute("selectedDepartment", department);
            req.setAttribute("selectedStatus", status);
            req.setAttribute("selectedEmployeeId", employeeId);
        } else {
            // Non-HR: strictly their own finalized records
            String ownEmpId = user.getEmployeeId();
            payrollList = payrollService.getPayrollHistoryByEmployee(ownEmpId);
        }

        for (Payroll p : payrollList) {
            String st = p.getStatus();
            if ("PAID".equalsIgnoreCase(st)) {
                paidCount++;
            } else if ("PROCESSED".equalsIgnoreCase(st)) {
                processedCount++;
            } else if ("DRAFT".equalsIgnoreCase(st)) {
                draftCount++;
            } else if ("CANCELLED".equalsIgnoreCase(st)) {
                cancelledCount++;
            }

            // Spec 8: Exclude CANCELLED records from totals
            if (!"CANCELLED".equalsIgnoreCase(st)) {
                totalGross = totalGross.add(p.getGrossSalary());
                totalDeductions = totalDeductions.add(p.getTotalDeductions());
                totalNet = totalNet.add(p.getNetSalary());
            }
        }

        req.setAttribute("payrollList", payrollList);
        req.setAttribute("departmentList", departmentList);
        req.setAttribute("deptSummaries", deptSummaries);
        req.setAttribute("totalGross", totalGross);
        req.setAttribute("totalDeductions", totalDeductions);
        req.setAttribute("totalNet", totalNet);
        req.setAttribute("draftCount", draftCount);
        req.setAttribute("processedCount", processedCount);
        req.setAttribute("paidCount", paidCount);
        req.setAttribute("cancelledCount", cancelledCount);

        req.getRequestDispatcher("/payroll/payroll-history.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        doGet(req, resp);
    }

    private void exportCsv(HttpServletResponse resp, Integer month, Integer year,
                           String department, String status, String employeeId) throws IOException {
        List<Payroll> list = payrollService.getPayrollList(month, year, department, status, employeeId);
        String filename = "payroll-report-" + (month != null ? month : "all") + "-" + (year != null ? year : "all") + ".csv";

        resp.setContentType("text/csv; charset=UTF-8");
        resp.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");

        PrintWriter writer = resp.getWriter();
        writer.println("Payroll ID,Employee ID,Employee Name,Department,Month,Year,Basic Salary,Gross Salary,Total Deductions,Net Salary,Status,Payment Date,Payment Method,Reference Number");

        for (Payroll p : list) {
            String payDate = p.getPayment() != null && p.getPayment().getPaymentDate() != null
                    ? p.getPayment().getPaymentDate().toString() : "";
            String payMethod = p.getPayment() != null && p.getPayment().getPaymentMethod() != null
                    ? p.getPayment().getPaymentMethod() : "";
            String payRef = p.getPayment() != null && p.getPayment().getReferenceNumber() != null
                    ? p.getPayment().getReferenceNumber() : "";

            writer.printf("%d,\"%s\",\"%s\",\"%s\",%d,%d,%.2f,%.2f,%.2f,%.2f,\"%s\",\"%s\",\"%s\",\"%s\"%n",
                    p.getId(),
                    csvEsc(p.getEmployeeId()),
                    csvEsc(p.getEmployeeName()),
                    csvEsc(p.getDepartment()),
                    p.getPayrollMonth(),
                    p.getPayrollYear(),
                    p.getBasicSalary(),
                    p.getGrossSalary(),
                    p.getTotalDeductions(),
                    p.getNetSalary(),
                    p.getStatus(),
                    payDate,
                    csvEsc(payMethod),
                    csvEsc(payRef)
            );
        }
        writer.flush();
    }

    private String csvEsc(String val) {
        if (val == null) return "";
        return val.replace("\"", "\"\"");
    }
}
