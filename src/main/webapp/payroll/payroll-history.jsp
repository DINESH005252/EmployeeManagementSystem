<%@ page contentType="text/html;charset=UTF-8" language="java" isELIgnored="true" %>
<%@ page import="java.util.List, java.math.BigDecimal, java.math.RoundingMode, com.smartoffice.model.Payroll, com.smartoffice.dao.PayrollDAO, com.smartoffice.util.HtmlUtil, com.smartoffice.util.PayrollRules, model.User, java.time.Month, java.time.format.TextStyle, java.util.Locale" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login.html");
        return;
    }

    String ctx = request.getContextPath();
    boolean isHr = currentUser.isHr();
    boolean isManager = currentUser.isManager();
    boolean isEmployee = currentUser.isEmployee();
    String portalUrl = ctx + (isHr ? "/hr.html" : (isManager ? "/manager.html" : "/employee.html"));
    String portalLabel = isHr ? "Back to HR Portal" : (isManager ? "Back to Manager Portal" : "Back to Employee Portal");
    String userInitial = (currentUser.getUsername() != null && !currentUser.getUsername().isEmpty()) ? currentUser.getUsername().substring(0, 1).toUpperCase() : "U";
    String userName = (currentUser.getUsername() != null) ? currentUser.getUsername() : "User";
    String roleLabel = isHr ? "HR Admin" : (isManager ? "Manager" : "Employee");

    List<Payroll> payrollList = (List<Payroll>) request.getAttribute("payrollList");
    List<String> departments = (List<String>) request.getAttribute("departments");
    List<PayrollDAO.DeptSummary> deptSummaries = (List<PayrollDAO.DeptSummary>) request.getAttribute("deptSummaries");

    BigDecimal totalGross = (BigDecimal) request.getAttribute("totalGross");
    if (totalGross == null) totalGross = BigDecimal.ZERO;
    BigDecimal totalDeductions = (BigDecimal) request.getAttribute("totalDeductions");
    if (totalDeductions == null) totalDeductions = BigDecimal.ZERO;
    BigDecimal totalNet = (BigDecimal) request.getAttribute("totalNet");
    if (totalNet == null) totalNet = BigDecimal.ZERO;

    Integer countDraft = (Integer) request.getAttribute("countDraft");
    Integer countProcessed = (Integer) request.getAttribute("countProcessed");
    Integer countPaid = (Integer) request.getAttribute("countPaid");
    Integer countCancelled = (Integer) request.getAttribute("countCancelled");
    if (countDraft == null) countDraft = 0;
    if (countProcessed == null) countProcessed = 0;
    if (countPaid == null) countPaid = 0;
    if (countCancelled == null) countCancelled = 0;

    Integer selectedMonth = (Integer) request.getAttribute("selectedMonth");
    Integer selectedYear = (Integer) request.getAttribute("selectedYear");
    String selectedDepartment = (String) request.getAttribute("selectedDepartment");
    String selectedStatus = (String) request.getAttribute("selectedStatus");

    String successMessage = (String) session.getAttribute("successMessage");
    if (successMessage != null) session.removeAttribute("successMessage");
    String errorMessage = (String) session.getAttribute("errorMessage");
    if (errorMessage != null) session.removeAttribute("errorMessage");

    // CSV export URL
    StringBuilder exportUrl = new StringBuilder(ctx).append("/payroll/history?export=csv");
    if (selectedMonth != null) exportUrl.append("&month=").append(selectedMonth);
    if (selectedYear != null) exportUrl.append("&year=").append(selectedYear);
    if (selectedDepartment != null && !selectedDepartment.isEmpty()) exportUrl.append("&department=").append(java.net.URLEncoder.encode(selectedDepartment, "UTF-8"));
    if (selectedStatus != null && !selectedStatus.isEmpty()) exportUrl.append("&status=").append(java.net.URLEncoder.encode(selectedStatus, "UTF-8"));
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>WorkPulse — <%= isHr ? "Payroll History & Reports" : "My Payslips & History" %></title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
  <style>
    :root {
      --primary: #2563eb;
      --primary-dark: #1d4ed8;
      --primary-light: #eff6ff;
      --primary-border: #bfdbfe;
      --brand-gradient: linear-gradient(135deg, #1d4ed8 0%, #2563eb 100%);
      --slate-50: #f8fafc;
      --slate-100: #f1f5f9;
      --slate-200: #e2e8f0;
      --slate-300: #cbd5e1;
      --slate-400: #94a3b8;
      --slate-500: #64748b;
      --slate-600: #475569;
      --slate-700: #334155;
      --slate-800: #1e293b;
      --slate-900: #0f172a;
      --emerald-500: #10b981;
      --emerald-600: #059669;
      --emerald-700: #047857;
      --emerald-50: #ecfdf5;
      --emerald-border: #a7f3d0;
      --emerald-text: #065f46;
      --amber-500: #f59e0b;
      --amber-600: #d97706;
      --amber-50: #fffbeb;
      --amber-border: #fde68a;
      --amber-text: #92400e;
      --rose-500: #f43f5e;
      --rose-600: #e11d48;
      --rose-50: #fef2f2;
      --rose-border: #fecaca;
      --rose-text: #991b1b;
      --radius-sm: 8px;
      --radius-md: 12px;
      --radius-lg: 16px;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Plus Jakarta Sans', 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
      background: #f8fafc;
      color: var(--slate-700);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      -webkit-font-smoothing: antialiased;
    }

    /* App Shell & Vertical Sidebar Layout */
    .app-shell {
      display: flex;
      min-height: 100vh;
      width: 100%;
    }
    .sidebar {
      width: 260px;
      background: #ffffff;
      border-right: 1px solid var(--slate-200);
      display: flex;
      flex-direction: column;
      flex-shrink: 0;
      height: 100vh;
      position: sticky;
      top: 0;
      overflow-y: auto;
      z-index: 10;
    }
    .sidebar::-webkit-scrollbar { width: 4px; }
    .sidebar::-webkit-scrollbar-thumb { background: var(--slate-200); border-radius: 4px; }

    .brand-header {
      height: 72px;
      padding: 0 22px;
      display: flex;
      align-items: center;
      gap: 12px;
      border-bottom: 1px solid var(--slate-200);
      flex-shrink: 0;
    }
    .logo-box {
      width: 36px;
      height: 36px;
      background: var(--brand-gradient);
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #ffffff;
      box-shadow: 0 4px 12px rgba(37, 99, 235, 0.25);
      flex-shrink: 0;
    }
    .brand-text {
      font-size: 15.5px;
      font-weight: 800;
      color: var(--slate-900);
      letter-spacing: 0.02em;
    }
    .brand-badge {
      font-size: 10px;
      text-transform: uppercase;
      font-weight: 700;
      background: var(--primary-light);
      color: var(--primary);
      border: 1px solid var(--primary-border);
      padding: 3px 7px;
      border-radius: 9999px;
      margin-left: auto;
      letter-spacing: 0.05em;
    }

    .nav-group {
      padding: 14px 14px 4px;
      display: flex;
      flex-direction: column;
      gap: 3px;
      flex: 0 0 auto;
    }
    .nav-label {
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      color: var(--slate-400);
      padding: 0 12px 6px 12px;
    }
    .tabs-nav {
      display: flex;
      flex-direction: column;
      gap: 3px;
      width: 100%;
    }
    .btn-sidebar-link {
      display: flex !important;
      align-items: center !important;
      justify-content: flex-start !important;
      gap: 12px !important;
      width: 100%;
      padding: 9.5px 14px;
      background: transparent;
      border: 1px solid transparent;
      border-radius: var(--radius-sm);
      color: var(--slate-600) !important;
      font-size: 13.5px;
      font-weight: 600;
      cursor: pointer;
      text-align: left;
      text-decoration: none;
      transition: all 0.18s ease;
      position: relative;
    }
    .btn-sidebar-link svg {
      width: 18px !important;
      height: 18px !important;
      min-width: 18px !important;
      flex-shrink: 0 !important;
      color: var(--slate-400);
      transition: color 0.18s ease, transform 0.18s ease;
    }
    .btn-sidebar-link:hover {
      background: var(--slate-100) !important;
      color: var(--slate-900) !important;
    }
    .btn-sidebar-link:hover svg {
      color: var(--primary);
      transform: scale(1.05);
    }
    .btn-sidebar-link.on {
      background: var(--primary-light) !important;
      color: var(--primary) !important;
      font-weight: 700;
      border-color: var(--primary-border);
      box-shadow: 0 1px 2px rgba(37, 99, 235, 0.08);
    }
    .btn-sidebar-link.on svg {
      color: var(--primary) !important;
    }
    .btn-sidebar-link.on::before {
      content: '';
      position: absolute;
      left: 0;
      top: 6px;
      bottom: 6px;
      width: 3px;
      border-radius: 0 3px 3px 0;
      background: var(--primary);
    }

    /* Workspace */
    .workspace {
      flex: 1;
      display: flex;
      flex-direction: column;
      overflow-x: hidden;
      background: #f8fafc;
      min-height: 100vh;
      min-width: 0;
    }
    .topbar {
      height: 72px;
      background: #ffffff;
      border-bottom: 1px solid var(--slate-200);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 36px;
      position: sticky;
      top: 0;
      z-index: 10;
    }
    .topbar-title {
      font-size: 16px;
      font-weight: 700;
      color: var(--slate-800);
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .topbar-title::before {
      content: '';
      display: inline-block;
      width: 4px;
      height: 16px;
      background: var(--primary);
      border-radius: 2px;
    }
    .user-ctrls {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .btn-back-portal {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      font-size: 12.5px;
      font-weight: 600;
      color: var(--slate-600);
      text-decoration: none;
      padding: 6px 12px;
      border-radius: var(--radius-sm);
      border: 1px solid var(--slate-200);
      background: #ffffff;
      transition: all 0.15s ease;
    }
    .btn-back-portal:hover {
      background: var(--slate-100);
      color: var(--slate-900);
      border-color: var(--slate-300);
    }
    .user-badge {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 5px 12px;
      background: var(--slate-100);
      border-radius: 30px;
      font-size: 13px;
      font-weight: 600;
      color: var(--slate-700);
    }
    .user-avatar {
      width: 26px;
      height: 26px;
      border-radius: 50%;
      background: var(--brand-gradient);
      color: #ffffff;
      font-size: 12px;
      font-weight: 700;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .btn-signout {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      font-size: 12.5px;
      font-weight: 600;
      color: var(--slate-600);
      text-decoration: none;
      padding: 6px 12px;
      border-radius: var(--radius-sm);
      border: 1px solid var(--slate-200);
      background: #ffffff;
      transition: all 0.15s ease;
    }
    .btn-signout:hover {
      background: var(--rose-50);
      border-color: var(--rose-border);
      color: var(--rose-text);
    }

    /* Content Area */
    .content-wrap {
      padding: 24px 32px 40px;
      max-width: 1440px;
      width: 100%;
      margin: 0 auto;
    }

    /* Alerts */
    .alert-banner {
      padding: 12px 18px;
      border-radius: var(--radius-sm);
      margin-bottom: 20px;
      font-size: 13.5px;
      font-weight: 500;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
    }
    .alert-banner-success { background: var(--emerald-50); border: 1px solid var(--emerald-border); color: var(--emerald-text); }
    .alert-banner-danger { background: var(--rose-50); border: 1px solid var(--rose-border); color: var(--rose-text); }
    .alert-close { background: transparent; border: none; cursor: pointer; font-size: 16px; color: inherit; opacity: 0.7; }

    /* Page Header */
    .page-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      margin-bottom: 22px;
      flex-wrap: wrap;
    }
    .header-left { display: flex; flex-direction: column; gap: 3px; }
    .page-title { font-size: 22px; font-weight: 800; color: var(--slate-900); letter-spacing: -0.01em; }
    .page-subtitle { font-size: 13.5px; color: var(--slate-500); }
    .header-toolbar { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }

    .btn-export-csv {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      padding: 8px 16px;
      border-radius: var(--radius-sm);
      font-size: 13px;
      font-weight: 700;
      color: var(--emerald-700);
      background: var(--emerald-50);
      border: 1px solid var(--emerald-border);
      text-decoration: none;
      transition: all 0.15s ease;
      white-space: nowrap;
    }
    .btn-export-csv:hover { background: #d1fae5; color: var(--emerald-800); }

    /* Filter Card */
    .filter-card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-md);
      padding: 18px 22px;
      margin-bottom: 20px;
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.03);
    }
    .filter-grid {
      display: grid;
      grid-template-columns: 160px 140px 200px 160px auto;
      gap: 14px;
      align-items: flex-end;
    }
    @media (max-width: 960px) {
      .filter-grid { grid-template-columns: 1fr 1fr; }
    }
    @media (max-width: 580px) {
      .filter-grid { grid-template-columns: 1fr; }
    }
    .form-ctrl-box label { font-size: 11px; font-weight: 700; text-transform: uppercase; color: var(--slate-400); margin-bottom: 5px; display: block; letter-spacing: 0.04em; }
    .form-ctrl-box select, .form-ctrl-box input {
      width: 100%;
      padding: 8px 12px;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-sm);
      font-size: 13px;
      font-family: inherit;
      color: var(--slate-800);
      background: #ffffff;
    }
    .form-ctrl-box select:focus, .form-ctrl-box input:focus {
      outline: none;
      border-color: var(--primary);
    }
    .filter-actions { display: flex; align-items: center; gap: 8px; }
    .btn-filter-apply {
      padding: 8px 16px;
      border-radius: var(--radius-sm);
      font-size: 13px;
      font-weight: 700;
      color: #ffffff;
      background: var(--primary);
      border: 1px solid var(--primary);
      cursor: pointer;
      transition: all 0.15s ease;
      white-space: nowrap;
    }
    .btn-filter-apply:hover { background: var(--primary-dark); }
    .btn-filter-reset {
      padding: 8px 14px;
      border-radius: var(--radius-sm);
      font-size: 13px;
      font-weight: 600;
      color: var(--slate-600);
      background: #ffffff;
      border: 1px solid var(--slate-200);
      text-decoration: none;
      transition: all 0.15s ease;
      white-space: nowrap;
    }
    .btn-filter-reset:hover { background: var(--slate-100); color: var(--slate-900); }

    /* KPI Grid */
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 16px;
      margin-bottom: 22px;
    }
    .stat-card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-md);
      padding: 16px 20px;
      display: flex;
      align-items: center;
      gap: 16px;
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.03);
    }
    .stat-icon {
      width: 44px;
      height: 44px;
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }
    .stat-body { display: flex; flex-direction: column; gap: 2px; }
    .stat-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em; color: var(--slate-400); }
    .stat-val { font-size: 20px; font-weight: 800; color: var(--slate-900); }
    .stat-sub { font-size: 11.5px; color: var(--slate-500); }

    /* Department Cost Center Card */
    .dept-card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-md);
      margin-bottom: 22px;
      overflow: hidden;
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.03);
    }
    .dept-header {
      padding: 14px 20px;
      background: #ffffff;
      border-bottom: 1px solid var(--slate-200);
      display: flex;
      align-items: center;
      justify-content: space-between;
    }
    .dept-title { font-size: 14px; font-weight: 800; color: var(--slate-900); display: flex; align-items: center; gap: 8px; }
    .dept-table { width: 100%; border-collapse: separate; border-spacing: 0; font-size: 13px; }
    .dept-table th {
      background: var(--slate-50);
      padding: 10px 16px;
      text-align: left;
      font-size: 11px;
      font-weight: 700;
      color: var(--slate-500);
      text-transform: uppercase;
      letter-spacing: 0.04em;
      border-bottom: 1px solid var(--slate-200);
    }
    .dept-table th.text-end, .dept-table td.text-end { text-align: right; }
    .dept-table td {
      padding: 12px 16px;
      border-bottom: 1px solid var(--slate-100);
      vertical-align: middle;
    }
    .progress-bar-bg {
      width: 100%;
      height: 6px;
      border-radius: 4px;
      background: var(--slate-100);
      overflow: hidden;
    }
    .progress-bar-fill {
      height: 100%;
      background: var(--primary);
      border-radius: 4px;
    }

    /* Main History Table Card */
    .table-card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-lg);
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
      overflow: hidden;
    }
    .table-card-header {
      padding: 16px 22px;
      border-bottom: 1px solid var(--slate-200);
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 14px;
      flex-wrap: wrap;
    }
    .card-title-text { font-size: 15px; font-weight: 800; color: var(--slate-900); }
    .payroll-table { width: 100%; border-collapse: separate; border-spacing: 0; font-size: 13px; }
    .payroll-table th {
      background: var(--slate-50);
      padding: 12px 16px;
      text-align: left;
      font-size: 11px;
      font-weight: 700;
      color: var(--slate-500);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      border-bottom: 1px solid var(--slate-200);
      white-space: nowrap;
    }
    .payroll-table th.text-end, .payroll-table td.text-end { text-align: right; }
    .payroll-table td {
      padding: 13px 16px;
      border-bottom: 1px solid var(--slate-100);
      vertical-align: middle;
      color: var(--slate-700);
      background: #ffffff;
    }
    .payroll-table tbody tr:hover td { background-color: #f8fafc; }

    .emp-user-cell { display: flex; align-items: center; gap: 10px; white-space: nowrap; }
    .emp-avatar {
      width: 32px;
      height: 32px;
      border-radius: 50%;
      background: var(--brand-gradient);
      color: #ffffff;
      font-size: 12px;
      font-weight: 700;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }
    .emp-name { font-weight: 700; color: var(--slate-900); font-size: 13px; white-space: nowrap; }
    .emp-id-code { font-family: monospace; font-size: 11px; color: var(--slate-400); font-weight: 600; }
    .dept-tag { display: inline-block; font-size: 11.5px; font-weight: 600; padding: 2px 7px; border-radius: 4px; background: var(--slate-100); color: var(--slate-700); border: 1px solid var(--slate-200); }

    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      font-size: 11px;
      font-weight: 700;
      padding: 3px 8px;
      border-radius: 20px;
      white-space: nowrap;
    }
    .status-paid { background: var(--emerald-50); color: var(--emerald-text); border: 1px solid var(--emerald-border); }
    .status-processed { background: var(--amber-50); color: var(--amber-text); border: 1px solid var(--amber-border); }
    .status-draft { background: var(--slate-100); color: var(--slate-600); border: 1px solid var(--slate-200); }
    .status-cancelled { background: var(--rose-50); color: var(--rose-text); border: 1px solid var(--rose-border); }

    .num-val { font-family: 'Plus Jakarta Sans', monospace; font-weight: 600; white-space: nowrap; }
    .val-net { color: var(--emerald-700); font-weight: 800; background: var(--emerald-50); border: 1px solid var(--emerald-border); padding: 3px 8px; border-radius: 6px; }

    .btn-row-action {
      display: inline-flex;
      align-items: center;
      gap: 4px;
      padding: 5px 10px;
      border-radius: 6px;
      font-size: 12px;
      font-weight: 700;
      color: var(--primary);
      background: var(--primary-light);
      border: 1px solid var(--primary-border);
      text-decoration: none;
      transition: all 0.15s ease;
      white-space: nowrap;
    }
    .btn-row-action:hover { background: var(--primary); color: #ffffff; }

    .empty-state { padding: 48px 24px; text-align: center; }
    .empty-icon { width: 48px; height: 48px; border-radius: 50%; background: var(--slate-100); color: var(--slate-400); display: inline-flex; align-items: center; justify-content: center; margin-bottom: 12px; }
  </style>
<style>

    /* Accordion Nav Groups (Matching User Reference Design) */
    .nav-accordion-group {
      margin-top: 10px;
      margin-bottom: 4px;
    }
    .nav-accordion-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      width: 100%;
      padding: 9px 12px;
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 10px;
      color: #1e293b;
      cursor: pointer;
      text-decoration: none;
      transition: all 0.18s ease;
      box-sizing: border-box;
      user-select: none;
    }
    .nav-accordion-header:hover {
      background: #f1f5f9;
      border-color: #cbd5e1;
      color: #0f172a;
    }
    .nav-accordion-header.open {
      background: #f1f5f9;
      border-color: #cbd5e1;
    }
    .nav-accordion-header .acc-icon-box {
      width: 32px;
      height: 32px;
      border-radius: 8px;
      background: #ffffff;
      border: 1px solid #e2e8f0;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      color: #2563eb;
      box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
      transition: all 0.18s ease;
    }
    .nav-accordion-header.open .acc-icon-box {
      background: #2563eb;
      color: #ffffff;
      border-color: #2563eb;
    }
    .nav-accordion-header .acc-text-wrap {
      display: flex;
      flex-direction: column;
      flex: 1;
      margin-left: 10px;
      min-width: 0;
      text-align: left;
    }
    .nav-accordion-header .acc-title {
      font-size: 13.5px;
      font-weight: 700;
      color: #0f172a;
      line-height: 1.25;
    }
    .nav-accordion-header .acc-subtitle {
      font-size: 11px;
      color: #64748b;
      line-height: 1.2;
      margin-top: 2px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .nav-accordion-header .acc-chevron {
      width: 16px;
      height: 16px;
      color: #94a3b8;
      transition: transform 0.22s cubic-bezier(0.4, 0, 0.2, 1);
      flex-shrink: 0;
    }
    .nav-accordion-header.open .acc-chevron {
      transform: rotate(180deg);
      color: #2563eb;
    }

    /* Vertical Tree Branch connecting children */
    .nav-accordion-body {
      display: none;
      position: relative;
      margin-left: 20px;
      padding-left: 12px;
      border-left: 2px solid #e2e8f0;
      margin-top: 6px;
      margin-bottom: 6px;
      flex-direction: column;
      gap: 3px;
    }
    .nav-accordion-body.open {
      display: flex;
    }
    .nav-accordion-item {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 7px 10px;
      border-radius: 8px;
      text-decoration: none;
      color: #475569;
      border: 1px solid transparent;
      transition: all 0.18s ease;
      position: relative;
    }
    .nav-accordion-item:hover {
      background: #f1f5f9;
      color: #0f172a;
      border-color: #e2e8f0;
    }
    .nav-accordion-item .item-icon-box {
      width: 26px;
      height: 26px;
      border-radius: 6px;
      background: #ffffff;
      border: 1px solid #e2e8f0;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      color: #64748b;
      transition: all 0.15s ease;
    }
    .nav-accordion-item:hover .item-icon-box {
      color: #2563eb;
      border-color: #bfdbfe;
    }
    .nav-accordion-item .item-text {
      display: flex;
      flex-direction: column;
      min-width: 0;
    }
    .nav-accordion-item .item-name {
      font-size: 13px;
      font-weight: 600;
      color: #1e293b;
      line-height: 1.25;
    }
    .nav-accordion-item .item-desc {
      font-size: 10.5px;
      color: #64748b;
      line-height: 1.2;
      margin-top: 1px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    /* Active highlighted item (matches user reference image) */
    .nav-accordion-item.on {
      background: #eff6ff;
      border-color: #93c5fd;
      box-shadow: 0 0 0 1px rgba(37, 99, 235, 0.12), 0 1px 3px rgba(37, 99, 235, 0.08);
    }
    .nav-accordion-item.on .item-icon-box {
      background: #2563eb;
      color: #ffffff;
      border-color: #2563eb;
    }
    .nav-accordion-item.on .item-name {
      color: #2563eb;
      font-weight: 700;
    }
    .nav-accordion-item.on .item-desc {
      color: #3b82f6;
    }

</style>
</head>
<body>

<div class="app-shell">
  <!-- Consistent WorkPulse Left Sidebar -->
        <aside class="sidebar">
    <div class="brand-header">
      <div class="logo-box">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <path d="M22 12h-4l-3 9L9 3l-3 9H2"/>
        </svg>
      </div>
      <span class="brand-text">WORKPULSE HRMS</span>
      <span class="brand-badge"><%= isHr ? "ADMIN" : (isManager ? "MANAGER" : "EMPLOYEE") %></span>
    </div>

    <% if (isEmployee) { %>
    <!-- EMPLOYEE SIDEBAR -->
    <div class="nav-group">
      <span class="nav-label">Attendance Menu</span>
      <div class="tabs-nav">
        <a href="<%= ctx %>/employee.html#history" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
          My Attendance
        </a>
        <a href="<%= ctx %>/employee.html#checkin" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" y1="12" x2="3" y2="12"/></svg>
          Check-In
        </a>
        <a href="<%= ctx %>/employee.html#break" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M18 8h1a4 4 0 0 1 0 8h-1"/><path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z"/><line x1="6" y1="1" x2="6" y2="4"/><line x1="10" y1="1" x2="10" y2="4"/><line x1="14" y1="1" x2="14" y2="4"/></svg>
          Breaks
        </a>
        <a href="<%= ctx %>/employee.html#checkout" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
          Check-Out
        </a>
        <a href="<%= ctx %>/employee.html#leave" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          Leave Request
        </a>
        <a href="<%= ctx %>/employee.html#myteam" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
          My Team
        </a>
        <a href="<%= ctx %>/employee.html#monthly" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M21.21 15.89A10 10 0 1 1 8 2.83"/><path d="M22 12A10 10 0 0 0 12 2v10z"/></svg>
          Monthly Summary
        </a>
      </div>
    </div>

    <div class="nav-group" style="margin-top: 6px;">
      <span class="nav-label">Task Management</span>
      <div class="tabs-nav">
        <a href="<%= ctx %>/myTasks" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>
          My Tasks
        </a>
        <a href="<%= ctx %>/taskDashboard" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="3" y="3" width="7" height="7"></rect><rect x="14" y="3" width="7" height="7"></rect><rect x="14" y="14" width="7" height="7"></rect><rect x="3" y="14" width="7" height="7"></rect></svg>
          Task Dashboard
        </a>
      </div>
    </div>

    <div class="nav-group" style="border-top: 1px solid var(--slate-200); padding-top: 12px; margin-top: 8px;">
      <span class="nav-label">Reports &amp; Analytics</span>
      <div class="tabs-nav">
        <a href="<%= ctx %>/reportsDashboard" class="btn-sidebar-link ">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M21.21 15.89A10 10 0 1 1 8 2.83"></path><path d="M22 12A10 10 0 0 0 12 2v10z"></path></svg>
          My Reports
        </a>
      </div>
    </div>

    <div class="nav-group" style="border-top: 1px solid var(--slate-200); padding-top: 12px; margin-top: 8px; margin-bottom: 20px;">
      <span class="nav-label">Payroll &amp; Payslips</span>
      <div class="tabs-nav">
        <a href="<%= ctx %>/payroll/history" class="btn-sidebar-link on">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
          My Payslips &amp; Payroll
        </a>
      </div>
    </div>

    <% } else if (isManager) { %>
    <!-- MANAGER SIDEBAR -->
    <div class="nav-group">
      <span class="nav-label">Team Operations</span>
      <div class="tabs-nav">
        <a href="<%= ctx %>/manager.html#myteams" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
          My Teams
        </a>
      </div>
    </div>

    <div class="nav-group" style="border-top: 1px solid var(--slate-200); padding-top: 14px; margin-top: 6px;">
      <span class="nav-label">Task Management</span>
      <div class="tabs-nav">
        <a href="<%= ctx %>/taskDashboard" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="3" y="3" width="7" height="7"></rect><rect x="14" y="3" width="7" height="7"></rect><rect x="14" y="14" width="7" height="7"></rect><rect x="3" y="14" width="7" height="7"></rect></svg>
          Task Dashboard
        </a>
        <a href="<%= ctx %>/viewTask" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
          Manage Tasks
        </a>
        <a href="<%= ctx %>/createTask" class="btn-sidebar-link create-task-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
          + Create Task
        </a>
      </div>
    </div>

    <!-- Reports Accordion (Matching Reference Design) -->
    <div class="nav-accordion-group">
      <div id="acc-reports-header-mgr" class="nav-accordion-header " onclick="toggleNavAccordion('acc-reports-mgr')">
        <div class="acc-icon-box">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M21.21 15.89A10 10 0 1 1 8 2.83"></path><path d="M22 12A10 10 0 0 0 12 2v10z"></path></svg>
        </div>
        <div class="acc-text-wrap">
          <span class="acc-title">Reports</span>
          <span class="acc-subtitle">Open report list</span>
        </div>
        <svg class="acc-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="6 9 12 15 18 9"></polyline></svg>
      </div>

      <div id="acc-reports-body-mgr" class="nav-accordion-body ">
        <a href="<%= ctx %>/reportsDashboard" class="nav-accordion-item ">
          <div class="item-icon-box">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="3" y="3" width="7" height="7"></rect><rect x="14" y="3" width="7" height="7"></rect><rect x="14" y="14" width="7" height="7"></rect><rect x="3" y="14" width="7" height="7"></rect></svg>
          </div>
          <div class="item-text">
            <span class="item-name">Reports Hub</span>
            <span class="item-desc">Pick an employee</span>
          </div>
        </a>
        <a href="<%= ctx %>/attendanceReport" class="nav-accordion-item ">
          <div class="item-icon-box">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
          </div>
          <div class="item-text">
            <span class="item-name">Attendance Report</span>
            <span class="item-desc">Daily and monthly attendance</span>
          </div>
        </a>
        <a href="<%= ctx %>/taskReport" class="nav-accordion-item ">
          <div class="item-icon-box">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M9 11l3 3L22 4"></path><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path></svg>
          </div>
          <div class="item-text">
            <span class="item-name">Task Report</span>
            <span class="item-desc">Task progress</span>
          </div>
        </a>
        <a href="<%= ctx %>/leaveReport" class="nav-accordion-item ">
          <div class="item-icon-box">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
          </div>
          <div class="item-text">
            <span class="item-name">Leave Report</span>
            <span class="item-desc">Leave requests by status</span>
          </div>
        </a>
        <a href="<%= ctx %>/employeeReport" class="nav-accordion-item ">
          <div class="item-icon-box">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle></svg>
          </div>
          <div class="item-text">
            <span class="item-name">Employee Report</span>
            <span class="item-desc">Department directory</span>
          </div>
        </a>
      </div>
    </div>

    <div class="nav-group" style="border-top: 1px solid var(--slate-200); padding-top: 12px; margin-top: 8px;">
      <span class="nav-label">Payroll &amp; Payslips</span>
      <div class="tabs-nav">
        <a href="<%= ctx %>/payroll/history" class="btn-sidebar-link on">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
          My Payslips &amp; Payroll
        </a>
      </div>
    </div>

    <div class="nav-group" style="border-top: 1px solid var(--slate-200); padding-top: 14px; margin-top: 6px; padding-bottom: 24px;">
      <span class="nav-label">Performance &amp; Ratings</span>
      <div class="tabs-nav">
        <a href="<%= ctx %>/employeePerformance" class="btn-sidebar-link ratings-link ">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon></svg>
          Performance &amp; Ratings
        </a>
      </div>
    </div>

    <% } else { %>
    <!-- ADMIN SIDEBAR -->
    <div class="nav-group">
      <span class="nav-label">Core Operations</span>
      <div class="tabs-nav">
        <a href="<%= ctx %>/hr.html#dashboard" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="3" y="3" width="7" height="7"></rect><rect x="14" y="3" width="7" height="7"></rect><rect x="14" y="14" width="7" height="7"></rect><rect x="3" y="14" width="7" height="7"></rect></svg>
          Dashboard
        </a>
        <a href="<%= ctx %>/hr.html#leaverequests" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
          Leave Requests
        </a>
        <a href="<%= ctx %>/hr.html#markabsent" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
          Mark Absent
        </a>
        <a href="<%= ctx %>/hr.html#markleave" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          Mark Leave
        </a>
        <a href="<%= ctx %>/hr.html#dailyreport" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
          Daily Report
        </a>
        <a href="<%= ctx %>/hr.html#history" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
          History
        </a>
        <a href="<%= ctx %>/hr.html#monthly" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M21.21 15.89A10 10 0 1 1 8 2.83"/><path d="M22 12A10 10 0 0 0 12 2v10z"/></svg>
          Monthly Summary
        </a>
        <a href="<%= ctx %>/hr.html#teams" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
          Manage Teams
        </a>
        <a href="<%= ctx %>/hr.html#teamdashboard" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
          Team Dashboard
        </a>
        <a href="<%= ctx %>/hr.html#createuser" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><line x1="20" y1="8" x2="20" y2="14"/><line x1="23" y1="11" x2="17" y2="11"/></svg>
          Create User
        </a>
      </div>
    </div>

    <!-- Task Management -->
    <div class="nav-group" style="border-top: 1px solid var(--slate-200); padding-top: 14px; margin-top: 6px;">
      <span class="nav-label">Task Management</span>
      <div class="tabs-nav">
        <a href="<%= ctx %>/taskDashboard" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="3" y="3" width="7" height="7"></rect><rect x="14" y="3" width="7" height="7"></rect><rect x="14" y="14" width="7" height="7"></rect><rect x="3" y="14" width="7" height="7"></rect></svg>
          Task Dashboard
        </a>
        <a href="<%= ctx %>/viewTask" class="btn-sidebar-link">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
          Manage Tasks
        </a>
      </div>
    </div>

    <!-- Reports Accordion (Matching Reference Design) -->
    <div class="nav-accordion-group">
      <div id="acc-reports-header" class="nav-accordion-header " onclick="toggleNavAccordion('acc-reports')">
        <div class="acc-icon-box">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M21.21 15.89A10 10 0 1 1 8 2.83"></path><path d="M22 12A10 10 0 0 0 12 2v10z"></path></svg>
        </div>
        <div class="acc-text-wrap">
          <span class="acc-title">Reports</span>
          <span class="acc-subtitle">Open report list</span>
        </div>
        <svg class="acc-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="6 9 12 15 18 9"></polyline></svg>
      </div>

      <div id="acc-reports-body" class="nav-accordion-body ">
        <a href="<%= ctx %>/reportsDashboard" class="nav-accordion-item ">
          <div class="item-icon-box">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="3" y="3" width="7" height="7"></rect><rect x="14" y="3" width="7" height="7"></rect><rect x="14" y="14" width="7" height="7"></rect><rect x="3" y="14" width="7" height="7"></rect></svg>
          </div>
          <div class="item-text">
            <span class="item-name">Reports Hub</span>
            <span class="item-desc">Pick an employee</span>
          </div>
        </a>
        <a href="<%= ctx %>/attendanceReport" class="nav-accordion-item ">
          <div class="item-icon-box">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
          </div>
          <div class="item-text">
            <span class="item-name">Attendance Report</span>
            <span class="item-desc">Daily and monthly attendance</span>
          </div>
        </a>
        <a href="<%= ctx %>/taskReport" class="nav-accordion-item ">
          <div class="item-icon-box">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M9 11l3 3L22 4"></path><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path></svg>
          </div>
          <div class="item-text">
            <span class="item-name">Task Report</span>
            <span class="item-desc">Task progress</span>
          </div>
        </a>
        <a href="<%= ctx %>/leaveReport" class="nav-accordion-item ">
          <div class="item-icon-box">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
          </div>
          <div class="item-text">
            <span class="item-name">Leave Report</span>
            <span class="item-desc">Leave requests by status</span>
          </div>
        </a>
        <a href="<%= ctx %>/employeeReport" class="nav-accordion-item ">
          <div class="item-icon-box">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle></svg>
          </div>
          <div class="item-text">
            <span class="item-name">Employee Report</span>
            <span class="item-desc">Department directory</span>
          </div>
        </a>
      </div>
    </div>

    <!-- Payroll Accordion (Matching Reference Design) -->
    <div class="nav-accordion-group">
      <div id="acc-payroll-header" class="nav-accordion-header open" onclick="toggleNavAccordion('acc-payroll')">
        <div class="acc-icon-box">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="2" y="4" width="20" height="16" rx="2"></rect><line x1="2" y1="10" x2="22" y2="10"></line><circle cx="16" cy="15" r="1"></circle></svg>
        </div>
        <div class="acc-text-wrap">
          <span class="acc-title">Payroll</span>
          <span class="acc-subtitle">Salary & compensation</span>
        </div>
        <svg class="acc-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="6 9 12 15 18 9"></polyline></svg>
      </div>

      <div id="acc-payroll-body" class="nav-accordion-body open">
        <a href="<%= ctx %>/payroll" class="nav-accordion-item ">
          <div class="item-icon-box">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="2" y="4" width="20" height="16" rx="2"></rect><line x1="2" y1="10" x2="22" y2="10"></line><circle cx="16" cy="15" r="1"></circle></svg>
          </div>
          <div class="item-text">
            <span class="item-name">Payroll Dashboard</span>
            <span class="item-desc">Overview & KPIs</span>
          </div>
        </a>
        <a href="<%= ctx %>/payroll/salary-structures" class="nav-accordion-item ">
          <div class="item-icon-box">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><line x1="4" y1="21" x2="4" y2="14"></line><line x1="4" y1="10" x2="4" y2="3"></line><line x1="12" y1="21" x2="12" y2="12"></line><line x1="12" y1="8" x2="12" y2="3"></line><line x1="20" y1="21" x2="20" y2="16"></line><line x1="20" y1="12" x2="20" y2="3"></line><line x1="1" y1="14" x2="7" y2="14"></line><line x1="9" y1="8" x2="15" y2="8"></line><line x1="17" y1="16" x2="23" y2="16"></line></svg>
          </div>
          <div class="item-text">
            <span class="item-name">Salary Structures</span>
            <span class="item-desc">Define pay grades</span>
          </div>
        </a>
        <a href="<%= ctx %>/payroll/processing" class="nav-accordion-item ">
          <div class="item-icon-box">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="4" y="2" width="16" height="20" rx="2"></rect><line x1="8" y1="6" x2="16" y2="6"></line><line x1="16" y1="14" x2="16" y2="18"></line><path d="M16 10h.01"></path><path d="M12 10h.01"></path><path d="M8 10h.01"></path><path d="M12 14h.01"></path><path d="M8 14h.01"></path><path d="M12 18h.01"></path><path d="M8 18h.01"></path></svg>
          </div>
          <div class="item-text">
            <span class="item-name">Process Payroll</span>
            <span class="item-desc">Monthly calculations</span>
          </div>
        </a>
        <a href="<%= ctx %>/payroll/history" class="nav-accordion-item on">
          <div class="item-icon-box">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
          </div>
          <div class="item-text">
            <span class="item-name">Payroll History &amp; Slips</span>
            <span class="item-desc">Review records & slips</span>
          </div>
        </a>
      </div>
    </div>

    <!-- Performance & Ratings -->
    <div class="nav-group" style="border-top: 1px solid var(--slate-200); padding-top: 14px; margin-top: 6px; padding-bottom: 24px;">
      <span class="nav-label">Ratings &amp; Performance</span>
      <div class="tabs-nav">
        <a href="<%= ctx %>/employeePerformance" class="btn-sidebar-link ratings-link ">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon></svg>
          Employee Ratings &amp; Performance
        </a>
      </div>
    </div>
    <% } %>
  </aside>

  <!-- Main Workspace -->
  <div class="workspace">
    <header class="topbar">
      <h1 class="topbar-title"><%= isHr ? "Company Payroll History &amp; Reports" : "My Payslips &amp; History" %></h1>
      <div class="user-ctrls">
        <a href="<%= portalUrl %>" class="btn-back-portal">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><polyline points="15 18 9 12 15 6"></polyline></svg>
          <%= portalLabel %>
        </a>
        <div class="user-badge">
          <div class="user-avatar"><%= userInitial %></div>
          <span><%= userName %> (<%= roleLabel %>)</span>
        </div>
        <a class="btn-signout" href="<%= ctx %>/logout">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
          Logout
        </a>
      </div>
    </header>

    <div class="content-wrap">
      <!-- Flash Notifications -->
      <% if (successMessage != null && !successMessage.isEmpty()) { %>
        <div class="alert-banner alert-banner-success">
          <span><i class="bi bi-check-circle-fill me-2"></i> <%= HtmlUtil.esc(successMessage) %></span>
          <button type="button" class="alert-close" onclick="this.parentElement.remove()">&times;</button>
        </div>
      <% } %>
      <% if (errorMessage != null && !errorMessage.isEmpty()) { %>
        <div class="alert-banner alert-banner-danger">
          <span><i class="bi bi-exclamation-triangle-fill me-2"></i> <%= HtmlUtil.esc(errorMessage) %></span>
          <button type="button" class="alert-close" onclick="this.parentElement.remove()">&times;</button>
        </div>
      <% } %>

      <!-- Page Header -->
      <div class="page-header">
        <div class="header-left">
          <h1 class="page-title"><%= isHr ? "Payroll History &amp; Reports" : "My Payslips &amp; Payment History" %></h1>
          <p class="page-subtitle">
            <%= isHr ? "Audit historical disbursements, inspect department cost distribution, and export official register reports." : "Review and download your monthly salary slips, deductions statements, and bank transfer confirmations." %>
          </p>
        </div>
        <% if (isHr) { %>
          <div class="header-toolbar">
            <a href="<%= exportUrl.toString() %>" class="btn-export-csv">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
              <span>Export CSV Register</span>
            </a>
          </div>
        <% } %>
      </div>

      <% if (isHr) { %>
        <!-- Multi-Parameter Filter Card -->
        <div class="filter-card">
          <form action="<%= ctx %>/payroll/history" method="get" class="filter-grid">
            <div class="form-ctrl-box">
              <label>Month</label>
              <select name="month">
                <option value="">All Months</option>
                <% for (int m = 1; m <= 12; m++) {
                     String mName = Month.of(m).getDisplayName(TextStyle.FULL, Locale.ENGLISH);
                     String sel = (selectedMonth != null && selectedMonth == m) ? "selected" : "";
                %>
                  <option value="<%= m %>" <%= sel %>><%= mName %></option>
                <% } %>
              </select>
            </div>
            <div class="form-ctrl-box">
              <label>Year</label>
              <select name="year">
                <option value="">All Years</option>
                <% int thisYear = java.time.LocalDate.now().getYear();
                   for (int y = thisYear; y >= thisYear - 3; y--) {
                     String sel = (selectedYear != null && selectedYear == y) ? "selected" : "";
                %>
                  <option value="<%= y %>" <%= sel %>><%= y %></option>
                <% } %>
              </select>
            </div>
            <div class="form-ctrl-box">
              <label>Department</label>
              <select name="department">
                <option value="ALL">All Departments</option>
                <% if (departments != null) {
                     for (String d : departments) {
                       String sel = (selectedDepartment != null && selectedDepartment.equalsIgnoreCase(d)) ? "selected" : "";
                %>
                  <option value="<%= HtmlUtil.esc(d) %>" <%= sel %>><%= HtmlUtil.esc(d) %></option>
                <%   }
                   } %>
              </select>
            </div>
            <div class="form-ctrl-box">
              <label>Status</label>
              <select name="status">
                <option value="ALL">All Statuses</option>
                <option value="DRAFT" <%= "DRAFT".equalsIgnoreCase(selectedStatus) ? "selected" : "" %>>Draft</option>
                <option value="PROCESSED" <%= "PROCESSED".equalsIgnoreCase(selectedStatus) ? "selected" : "" %>>Processed</option>
                <option value="PAID" <%= "PAID".equalsIgnoreCase(selectedStatus) ? "selected" : "" %>>Paid</option>
                <option value="CANCELLED" <%= "CANCELLED".equalsIgnoreCase(selectedStatus) ? "selected" : "" %>>Cancelled</option>
              </select>
            </div>
            <div class="filter-actions">
              <button type="submit" class="btn-filter-apply">Apply Filters</button>
              <a href="<%= ctx %>/payroll/history" class="btn-filter-reset">Reset</a>
            </div>
          </form>
        </div>
      <% } %>

      <!-- Financial Metric Cards -->
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-icon" style="background:#eff6ff; color:#2563eb;">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line></svg>
          </div>
          <div class="stat-body">
            <span class="stat-label">Matching Records</span>
            <span class="stat-val"><%= payrollList != null ? payrollList.size() : 0 %></span>
            <div style="display:flex; gap:4px; margin-top:2px; font-size:11px;">
              <span style="color:var(--emerald-600); font-weight:700;"><%= countPaid %> Paid</span> &bull;
              <span style="color:var(--amber-600); font-weight:700;"><%= countProcessed %> Processed</span>
            </div>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon" style="background:#ecfdf5; color:#059669;">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><line x1="12" y1="1" x2="12" y2="23"></line><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path></svg>
          </div>
          <div class="stat-body">
            <span class="stat-label">Total Net Disbursed</span>
            <span class="stat-val" style="color:var(--emerald-700);">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", totalNet) %></span>
            <span class="stat-sub">Take-home payout</span>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon" style="background:#f8fafc; color:#334155; border:1px solid var(--slate-200);">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="2" y="4" width="20" height="16" rx="2"></rect><line x1="2" y1="10" x2="22" y2="10"></line></svg>
          </div>
          <div class="stat-body">
            <span class="stat-label">Total Gross Earnings</span>
            <span class="stat-val">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", totalGross) %></span>
            <span class="stat-sub">Before statutory deductions</span>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon" style="background:#fef2f2; color:#e11d48;">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
          </div>
          <div class="stat-body">
            <span class="stat-label">Total Deductions</span>
            <span class="stat-val" style="color:var(--rose-600);">-&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", totalDeductions) %></span>
            <span class="stat-sub">PF, PT, TDS &amp; LOP</span>
          </div>
        </div>
      </div>

      <% if (isHr && deptSummaries != null && !deptSummaries.isEmpty()) { %>
        <!-- Department-Wise Cost Distribution -->
        <div class="dept-card">
          <div class="dept-header">
            <div class="dept-title">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="4" y="2" width="16" height="20" rx="2"></rect><line x1="9" y1="22" x2="9" y2="2"></line><line x1="15" y1="22" x2="15" y2="2"></line></svg>
              <span>Department Cost Distribution</span>
            </div>
            <span class="dept-tag" style="font-size:11.5px; font-weight:700;"><%= deptSummaries.size() %> Cost Centers</span>
          </div>
          <div style="overflow-x:auto;">
            <table class="dept-table">
              <thead>
                <tr>
                  <th style="min-width:180px;">Department</th>
                  <th style="min-width:100px;">Headcount</th>
                  <th class="text-end" style="min-width:130px;">Gross Total</th>
                  <th class="text-end" style="min-width:130px;">Deductions</th>
                  <th class="text-end" style="min-width:140px;">Net Disbursed</th>
                  <th style="min-width:180px;">Share of Total Payout</th>
                </tr>
              </thead>
              <tbody>
                <% for (PayrollDAO.DeptSummary ds : deptSummaries) {
                     double sharePercent = 0.0;
                     if (totalNet.compareTo(BigDecimal.ZERO) > 0 && ds.getTotalNet() != null) {
                         sharePercent = ds.getTotalNet().divide(totalNet, 4, RoundingMode.HALF_UP).doubleValue() * 100.0;
                     }
                %>
                  <tr>
                    <td><strong><%= HtmlUtil.esc(ds.getDepartment()) %></strong></td>
                    <td>
                      <span class="badge bg-light text-dark border px-2 py-0.5 rounded-2" style="font-size:11.5px;">
                        <%= ds.getEmployeeCount() %> emp
                      </span>
                    </td>
                    <td class="text-end num-val">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", ds.getTotalGross()) %></td>
                    <td class="text-end num-val" style="color:var(--rose-600);">-&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", ds.getTotalDeductions()) %></td>
                    <td class="text-end num-val" style="color:var(--emerald-700); font-weight:800;">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", ds.getTotalNet()) %></td>
                    <td>
                      <div style="display:flex; align-items:center; gap:8px;">
                        <div class="progress-bar-bg" style="flex:1;">
                          <div class="progress-bar-fill" style="width: <%= String.format(Locale.US, "%.1f", sharePercent) %>%;"></div>
                        </div>
                        <span style="font-size:11px; font-weight:700; color:var(--slate-500); width:38px; text-align:right;"><%= String.format(Locale.US, "%.1f", sharePercent) %>%</span>
                      </div>
                    </td>
                  </tr>
                <% } %>
              </tbody>
            </table>
          </div>
        </div>
      <% } %>

      <!-- Historical Register Table Card -->
      <div class="table-card">
        <div class="table-card-header">
          <div class="card-title-text">Payroll Records Register</div>
          <div style="font-size:12.5px; color:var(--slate-500);">
            Showing <%= payrollList != null ? payrollList.size() : 0 %> records
          </div>
        </div>
        <div class="table-responsive">
          <table class="payroll-table">
            <thead>
              <tr>
                <th style="min-width: 140px;">Period</th>
                <% if (isHr) { %>
                  <th style="min-width: 220px;">Employee</th>
                  <th style="min-width: 120px;">Department</th>
                <% } %>
                <th class="text-end" style="min-width: 110px;">Basic Pay</th>
                <th class="text-end" style="min-width: 110px;">Gross Pay</th>
                <th class="text-end" style="min-width: 110px;">Deductions</th>
                <th class="text-end" style="min-width: 130px;">Net Salary</th>
                <th style="min-width: 110px;">Attendance</th>
                <th style="min-width: 110px;">Status</th>
                <th style="min-width: 160px;">Settlement Details</th>
                <th class="text-end" style="min-width: 110px;">Action</th>
              </tr>
            </thead>
            <tbody>
              <% if (payrollList == null || payrollList.isEmpty()) { %>
                <tr>
                  <td colspan="<%= isHr ? 11 : 9 %>">
                    <div class="empty-state">
                      <div class="empty-icon">
                        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
                      </div>
                      <h4 style="font-size: 15px; font-weight: 700; color: var(--slate-800); margin-bottom: 4px;">No payroll records found</h4>
                      <p style="font-size: 13px; color: var(--slate-500); margin-bottom: 0;">Try adjusting your search filters or generate payroll for a new month.</p>
                    </div>
                  </td>
                </tr>
              <% } else {
                   for (Payroll p : payrollList) {
                     String st = p.getStatus() != null ? p.getStatus().toUpperCase() : "DRAFT";
                     String badgeClass = "status-draft";
                     if ("PAID".equals(st)) badgeClass = "status-paid";
                     else if ("PROCESSED".equals(st)) badgeClass = "status-processed";
                     else if ("CANCELLED".equals(st)) badgeClass = "status-cancelled";

                     String initials = "EM";
                     if (p.getEmployeeName() != null && !p.getEmployeeName().trim().isEmpty()) {
                         String[] parts = p.getEmployeeName().trim().split("\\s+");
                         if (parts.length >= 2) {
                             initials = (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
                         } else {
                             initials = parts[0].substring(0, Math.min(2, parts[0].length())).toUpperCase();
                         }
                     }
              %>
                <tr>
                  <td>
                    <span class="badge bg-light text-dark border px-2 py-1 rounded-2" style="font-size: 12px; font-weight: 600;">
                      <%= p.getMonthName() %> <%= p.getPayrollYear() %>
                    </span>
                  </td>
                  <% if (isHr) { %>
                    <td>
                      <div class="emp-user-cell">
                        <div class="emp-avatar"><%= initials %></div>
                        <div>
                          <div class="emp-name"><%= HtmlUtil.esc(p.getEmployeeName()) %></div>
                          <div class="emp-id-code"><%= HtmlUtil.esc(p.getEmployeeId()) %></div>
                        </div>
                      </div>
                    </td>
                    <td><span class="dept-tag"><%= HtmlUtil.esc(p.getDepartment()) %></span></td>
                  <% } %>
                  <td class="text-end num-val">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", p.getBasicSalary()) %></td>
                  <td class="text-end num-val">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", p.getGrossSalary()) %></td>
                  <td class="text-end num-val" style="color:var(--rose-600);">-&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", p.getTotalDeductions()) %></td>
                  <td class="text-end num-val val-net">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", p.getNetSalary()) %></td>
                  <td>
                    <div style="font-size:12px; font-weight:600; color:var(--slate-700);">
                      <%= p.getPresentDays() %> / <%= p.getTotalWorkingDays() %> d
                      <% if (p.getUnpaidDays() != null && p.getUnpaidDays().compareTo(BigDecimal.ZERO) > 0) { %>
                        <span class="badge bg-danger-subtle text-danger rounded-pill px-1.5" style="font-size:10px;"><%= p.getUnpaidDays() %> LOP</span>
                      <% } %>
                    </div>
                  </td>
                  <td>
                    <span class="status-badge <%= badgeClass %>"><%= st %></span>
                  </td>
                  <td>
                    <% if (p.getPayment() != null) { %>
                      <div style="font-size:12px; font-weight:700; color:var(--emerald-700);"><%= HtmlUtil.esc(p.getPayment().getPaymentMethod()) %></div>
                      <div style="font-size:11px; color:var(--slate-400); font-family:monospace;">
                        <%= p.getPayment().getReferenceNumber() != null ? HtmlUtil.esc(p.getPayment().getReferenceNumber()) : "" %> &bull; <%= p.getPayment().getPaymentDate() %>
                      </div>
                    <% } else if ("PROCESSED".equals(st)) { %>
                      <span style="font-size:12px; color:var(--amber-700); font-weight:600;">Pending Payment</span>
                    <% } else { %>
                      <span style="font-size:12px; color:var(--slate-400);">&mdash;</span>
                    <% } %>
                  </td>
                  <td class="text-end">
                    <div style="display:inline-flex; align-items:center; gap:5px; justify-content:flex-end;">
                      <a href="<%= ctx %>/payroll/salary-slip?id=<%= p.getId() %>" class="btn-row-action" title="View Official Salary Slip">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line></svg>
                        <span>Slip</span>
                      </a>
                      <% if (isHr && "PROCESSED".equals(st)) { %>
                        <a href="<%= ctx %>/payroll/payment?id=<%= p.getId() %>" class="btn-row-action" style="color:var(--emerald-700); background:var(--emerald-50); border-color:var(--emerald-border);" title="Record Payment Disbursement">
                          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><line x1="12" y1="1" x2="12" y2="23"></line><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path></svg>
                          <span>Pay</span>
                        </a>
                      <% } %>
                    </div>
                  </td>
                </tr>
              <%   }
                 } %>
            </tbody>
          </table>
        </div>
      </div>

    </div>
  </div>
</div>


<script>
function toggleNavAccordion(id) {
  var b = document.getElementById(id + '-body');
  var h = document.getElementById(id + '-header');
  if (b && h) {
    b.classList.toggle('open');
    h.classList.toggle('open');
  }
}
</script>

</body>
</html>