<%@ page contentType="text/html;charset=UTF-8" language="java" isELIgnored="true" %>
<%@ page import="java.util.List, java.math.BigDecimal, com.smartoffice.model.Payroll, com.smartoffice.util.HtmlUtil, com.smartoffice.util.PayrollRules, com.smartoffice.util.CsrfUtil, model.User, java.time.Month, java.time.format.TextStyle, java.util.Locale" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login.html");
        return;
    }
    if (!currentUser.isHr()) {
        response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access Denied: Only HR administrators can process payroll.");
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

    Integer selectedMonth = (Integer) request.getAttribute("selectedMonth");
    Integer selectedYear = (Integer) request.getAttribute("selectedYear");
    Boolean applyAttendance = (Boolean) request.getAttribute("applyAttendance");
    if (selectedMonth == null) selectedMonth = java.time.LocalDate.now().getMonthValue();
    if (selectedYear == null) selectedYear = java.time.LocalDate.now().getYear();
    if (applyAttendance == null) applyAttendance = true;

    String monthName = Month.of(selectedMonth).getDisplayName(TextStyle.FULL, Locale.ENGLISH);

    List<Payroll> previewList = (List<Payroll>) request.getAttribute("previewList");
    List<String> missingStructures = (List<String>) request.getAttribute("missingStructures");

    String successMessage = (String) session.getAttribute("successMessage");
    if (successMessage != null) session.removeAttribute("successMessage");
    String errorMessage = (String) session.getAttribute("errorMessage");
    if (errorMessage != null) session.removeAttribute("errorMessage");

    BigDecimal totalBatchNet = BigDecimal.ZERO;
    BigDecimal totalBatchGross = BigDecimal.ZERO;
    BigDecimal totalBatchDed = BigDecimal.ZERO;
    int processedCount = 0;
    int draftCount = 0;
    int paidCount = 0;
    int cancelledCount = 0;

    if (previewList != null) {
        for (Payroll p : previewList) {
            if (!"CANCELLED".equalsIgnoreCase(p.getStatus())) {
                totalBatchNet = totalBatchNet.add(p.getNetSalary() != null ? p.getNetSalary() : BigDecimal.ZERO);
                totalBatchGross = totalBatchGross.add(p.getGrossSalary() != null ? p.getGrossSalary() : BigDecimal.ZERO);
                totalBatchDed = totalBatchDed.add(p.getTotalDeductions() != null ? p.getTotalDeductions() : BigDecimal.ZERO);
            }
            if ("PAID".equalsIgnoreCase(p.getStatus())) {
                paidCount++;
            } else if ("PROCESSED".equalsIgnoreCase(p.getStatus())) {
                processedCount++;
            } else if ("CANCELLED".equalsIgnoreCase(p.getStatus())) {
                cancelledCount++;
            } else {
                draftCount++;
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>WorkPulse — Process Monthly Payroll</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
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

    /* App Shell & Vertical Sidebar Layout (Matching Report Hub) */
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
      margin-bottom: 20px;
      flex-wrap: wrap;
    }
    .header-left { display: flex; flex-direction: column; gap: 3px; }
    .page-title { font-size: 22px; font-weight: 800; color: var(--slate-900); letter-spacing: -0.01em; }
    .page-subtitle { font-size: 13.5px; color: var(--slate-500); }

    /* Period Filter Card */
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
      grid-template-columns: 200px 140px 1fr auto;
      gap: 16px;
      align-items: flex-end;
    }
    @media (max-width: 900px) {
      .filter-grid { grid-template-columns: 1fr 1fr; }
    }
    @media (max-width: 600px) {
      .filter-grid { grid-template-columns: 1fr; }
    }

    /* Batch Summary Bar */
    .batch-summary-card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-md);
      padding: 16px 22px;
      margin-bottom: 20px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      flex-wrap: wrap;
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.03);
    }
    .summary-metrics-group {
      display: flex;
      align-items: center;
      gap: 24px;
      flex-wrap: wrap;
    }
    .summary-item { display: flex; flex-direction: column; gap: 2px; }
    .summary-item-label { font-size: 11px; font-weight: 700; text-transform: uppercase; color: var(--slate-400); letter-spacing: 0.04em; }
    .summary-item-val { font-size: 17px; font-weight: 800; color: var(--slate-900); }

    .batch-actions-group {
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
    }

    /* Primary buttons */
    .btn-action-primary {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      padding: 8px 16px;
      border-radius: var(--radius-sm);
      font-size: 13px;
      font-weight: 700;
      color: #ffffff;
      background: var(--primary);
      border: 1px solid var(--primary);
      text-decoration: none;
      box-shadow: 0 1px 3px rgba(37, 99, 235, 0.2);
      transition: all 0.15s ease;
      cursor: pointer;
      white-space: nowrap;
    }
    .btn-action-primary:hover { background: var(--primary-dark); border-color: var(--primary-dark); }
    .btn-action-secondary {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      padding: 8px 14px;
      border-radius: var(--radius-sm);
      font-size: 13px;
      font-weight: 600;
      color: var(--slate-700);
      background: #ffffff;
      border: 1px solid var(--slate-200);
      text-decoration: none;
      transition: all 0.15s ease;
      cursor: pointer;
      white-space: nowrap;
    }
    .btn-action-secondary:hover { background: var(--slate-100); color: var(--slate-900); }

    /* Missing Structures Alert Box */
    .missing-alert-box {
      background: var(--amber-50);
      border: 1px solid var(--amber-border);
      border-radius: var(--radius-md);
      padding: 14px 18px;
      margin-bottom: 20px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 14px;
      flex-wrap: wrap;
    }
    .missing-alert-left {
      display: flex;
      align-items: flex-start;
      gap: 12px;
    }

    /* Table Card */
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
      padding: 12px 16px;
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

    .btn-tbl-action {
      display: inline-flex;
      align-items: center;
      gap: 4px;
      padding: 4px 9px;
      border-radius: 6px;
      font-size: 11.5px;
      font-weight: 700;
      text-decoration: none;
      transition: all 0.15s ease;
      cursor: pointer;
      white-space: nowrap;
      border: 1px solid transparent;
    }
    .btn-tbl-primary { background: var(--primary-light); color: var(--primary); border-color: var(--primary-border); }
    .btn-tbl-primary:hover { background: var(--primary); color: #ffffff; }
    .btn-tbl-secondary { background: var(--slate-100); color: var(--slate-700); border-color: var(--slate-200); }
    .btn-tbl-secondary:hover { background: var(--slate-200); color: var(--slate-900); }
    .btn-tbl-success { background: var(--emerald-50); color: var(--emerald-text); border-color: var(--emerald-border); }
    .btn-tbl-success:hover { background: var(--emerald-600); color: #ffffff; }
    .btn-tbl-danger { background: var(--rose-50); color: var(--rose-text); border-color: var(--rose-border); }
    .btn-tbl-danger:hover { background: var(--rose-600); color: #ffffff; }

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
        <a href="<%= ctx %>/payroll/history" class="btn-sidebar-link ">
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
        <a href="<%= ctx %>/payroll/history" class="btn-sidebar-link ">
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
        <a href="<%= ctx %>/payroll/processing" class="nav-accordion-item on">
          <div class="item-icon-box">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="4" y="2" width="16" height="20" rx="2"></rect><line x1="8" y1="6" x2="16" y2="6"></line><line x1="16" y1="14" x2="16" y2="18"></line><path d="M16 10h.01"></path><path d="M12 10h.01"></path><path d="M8 10h.01"></path><path d="M12 14h.01"></path><path d="M8 14h.01"></path><path d="M12 18h.01"></path><path d="M8 18h.01"></path></svg>
          </div>
          <div class="item-text">
            <span class="item-name">Process Payroll</span>
            <span class="item-desc">Monthly calculations</span>
          </div>
        </a>
        <a href="<%= ctx %>/payroll/history" class="nav-accordion-item ">
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
      <h1 class="topbar-title">Monthly Payroll Processing</h1>
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
          <h1 class="page-title">Process Monthly Payroll</h1>
          <p class="page-subtitle">Reconcile attendance records, apply statutory deductions, and finalize compensation snapshots for <strong><%= monthName %> <%= selectedYear %></strong>.</p>
        </div>
      </div>

      <!-- Filter & Configuration Toolbar Card -->
      <div class="filter-card">
        <form action="<%= ctx %>/payroll/processing" method="get" class="filter-grid">
          <div>
            <label class="form-label small fw-semibold text-muted mb-1">Payroll Month</label>
            <select name="month" class="form-select form-select-sm">
              <% for (int m = 1; m <= 12; m++) {
                   String mName = Month.of(m).getDisplayName(TextStyle.FULL, Locale.ENGLISH);
                   String sel = (m == selectedMonth) ? "selected" : "";
              %>
                <option value="<%= m %>" <%= sel %>><%= mName %> (<%= String.format("%02d", m) %>)</option>
              <% } %>
            </select>
          </div>
          <div>
            <label class="form-label small fw-semibold text-muted mb-1">Payroll Year</label>
            <input type="number" name="year" class="form-control form-control-sm" value="<%= selectedYear %>" min="2020" max="2035">
          </div>
          <div>
            <label class="form-label small fw-semibold text-muted mb-1">Attendance Loss of Pay</label>
            <select name="applyAttendance" class="form-select form-select-sm">
              <option value="true" <%= applyAttendance ? "selected" : "" %>>Yes - apply attendance adjustments</option>
              <option value="false" <%= !applyAttendance ? "selected" : "" %>>No - ignore attendance</option>
            </select>
          </div>
          <div>
            <button type="submit" class="btn-action-primary" style="height: 31px; padding: 4px 16px;">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="23 4 23 10 17 10"></polyline><polyline points="1 20 1 14 7 14"></polyline><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"></path></svg>
              Load Period
            </button>
          </div>
        </form>
      </div>

      <!-- Missing Salary Structures Warning -->
      <% if (missingStructures != null && !missingStructures.isEmpty()) { %>
        <div class="missing-alert-box">
          <div class="missing-alert-left">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="2.2" style="flex-shrink:0; margin-top:2px;"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>
            <div>
              <strong style="color:var(--amber-text); font-size:13.5px;"><%= missingStructures.size() %> active employees require payroll review:</strong>
              <div style="font-size:12.5px; color:var(--amber-text); opacity:0.9; margin-top:3px;">
                <%= HtmlUtil.esc(String.join(", ", missingStructures)) %>
              </div>
            </div>
          </div>
          <a href="<%= ctx %>/payroll/salary-structure-form" class="btn-action-secondary" style="border-color:var(--amber-border); background:#ffffff; color:var(--amber-text); font-weight:700;">
            Configure Structures
          </a>
        </div>
      <% } %>

      <!-- Batch Executive Summary Bar & Actions -->
      <div class="batch-summary-card">
        <div class="summary-metrics-group">
          <div class="summary-item">
            <span class="summary-item-label">Period Cycle</span>
            <span class="summary-item-val" style="color:var(--slate-900);"><%= monthName %> <%= selectedYear %></span>
          </div>
          <div class="summary-item" style="border-left:1px solid var(--slate-200); padding-left:18px;">
            <span class="summary-item-label">Batch Gross Pay</span>
            <span class="summary-item-val" style="color:var(--slate-900);">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", totalBatchGross) %></span>
          </div>
          <div class="summary-item" style="border-left:1px solid var(--slate-200); padding-left:18px;">
            <span class="summary-item-label">Total Deductions</span>
            <span class="summary-item-val" style="color:var(--rose-600);">-&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", totalBatchDed) %></span>
          </div>
          <div class="summary-item" style="border-left:1px solid var(--slate-200); padding-left:18px;">
            <span class="summary-item-label">Net Disbursable</span>
            <span class="summary-item-val" style="color:var(--emerald-600);">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", totalBatchNet) %></span>
          </div>
          <div class="summary-item" style="border-left:1px solid var(--slate-200); padding-left:18px;">
            <span class="summary-item-label">Status Summary</span>
            <div style="display:flex; align-items:center; gap:6px; margin-top:2px;">
              <% if (draftCount > 0) { %><span class="status-badge status-draft"><%= draftCount %> Draft</span><% } %>
              <% if (processedCount > 0) { %><span class="status-badge status-processed"><%= processedCount %> Processed</span><% } %>
              <% if (paidCount > 0) { %><span class="status-badge status-paid"><%= paidCount %> Paid</span><% } %>
              <% if (cancelledCount > 0) { %><span class="status-badge status-cancelled"><%= cancelledCount %> Cancelled</span><% } %>
            </div>
          </div>
        </div>

        <div class="batch-actions-group">
          <!-- Generate / Re-calculate Batch -->
          <form action="<%= ctx %>/payroll/processing" method="post" style="display:inline;">
            <input type="hidden" name="csrfToken" value="<%= CsrfUtil.getToken(session) %>">
            <input type="hidden" name="action" value="generate_all">
            <input type="hidden" name="month" value="<%= selectedMonth %>">
            <input type="hidden" name="year" value="<%= selectedYear %>">
            <input type="hidden" name="applyAttendance" value="<%= applyAttendance %>">
            <button type="submit" class="btn-action-secondary">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="12" y1="18" x2="12" y2="12"></line><line x1="9" y1="15" x2="15" y2="15"></line></svg>
              <span>Generate Drafts</span>
            </button>
          </form>

          <!-- Finalize All Drafts -->
          <% if (draftCount > 0) { %>
            <form action="<%= ctx %>/payroll/processing" method="post" style="display:inline;" onsubmit="return confirm('Finalize all <%= draftCount %> draft payroll calculations for <%= monthName %> <%= selectedYear %>? Once finalized, snapshot records are locked for payment disbursement.');">
              <input type="hidden" name="csrfToken" value="<%= CsrfUtil.getToken(session) %>">
              <input type="hidden" name="action" value="finalize_all">
              <input type="hidden" name="month" value="<%= selectedMonth %>">
              <input type="hidden" name="year" value="<%= selectedYear %>">
              <input type="hidden" name="applyAttendance" value="<%= applyAttendance %>">
              <button type="submit" class="btn-action-primary">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg>
                <span>Finalize All (<%= draftCount %>)</span>
              </button>
            </form>
          <% } %>
        </div>
      </div>

      <!-- Calculations Review Table Card -->
      <div class="table-card">
        <div class="table-card-header">
          <div class="card-title-text"><%= monthName %> <%= selectedYear %> Payroll Calculations</div>
          <div style="font-size:12.5px; color:var(--slate-500);">
            Showing <%= previewList != null ? previewList.size() : 0 %> employee records
          </div>
        </div>
        <div class="table-responsive">
          <table class="payroll-table">
            <thead>
              <tr>
                <th style="min-width: 220px;">Employee</th>
                <th class="text-end" style="min-width: 110px;">Basic Pay</th>
                <th style="min-width: 130px;">Attendance</th>
                <th class="text-end" style="min-width: 100px;">LOP Loss</th>
                <th class="text-end" style="min-width: 110px;">Gross Pay</th>
                <th class="text-end" style="min-width: 110px;">Deductions</th>
                <th class="text-end" style="min-width: 130px;">Net Payable</th>
                <th style="min-width: 110px;">Status</th>
                <th class="text-end" style="min-width: 160px;">Actions</th>
              </tr>
            </thead>
            <tbody>
              <% if (previewList == null || previewList.isEmpty()) { %>
                <tr>
                  <td colspan="9">
                    <div class="empty-state">
                      <div class="empty-icon">
                        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="4" y="2" width="16" height="20" rx="2"></rect><line x1="8" y1="6" x2="16" y2="6"></line><line x1="16" y1="14" x2="16" y2="18"></line></svg>
                      </div>
                      <h4 style="font-size: 15px; font-weight: 700; color: var(--slate-800); margin-bottom: 4px;">No payroll records generated for <%= monthName %> <%= selectedYear %></h4>
                      <p style="font-size: 13px; color: var(--slate-500); margin-bottom: 16px;">Click "Generate Drafts" above to prepare automated calculations for all active employees.</p>
                      <form action="<%= ctx %>/payroll/processing" method="post" style="display:inline;">
                        <input type="hidden" name="csrfToken" value="<%= CsrfUtil.getToken(session) %>">
                        <input type="hidden" name="action" value="generate_all">
                        <input type="hidden" name="month" value="<%= selectedMonth %>">
                        <input type="hidden" name="year" value="<%= selectedYear %>">
                        <input type="hidden" name="applyAttendance" value="<%= applyAttendance %>">
                        <button type="submit" class="btn-action-primary" style="margin: 0 auto;">
                          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg>
                          Generate Batch Drafts
                        </button>
                      </form>
                    </div>
                  </td>
                </tr>
              <% } else {
                   for (Payroll p : previewList) {
                     String st = p.getStatus() != null ? p.getStatus().toUpperCase() : "DRAFT";
                     String badgeClass = "status-draft";
                     if ("PAID".equals(st)) badgeClass = "status-paid";
                     else if ("PROCESSED".equals(st)) badgeClass = "status-processed";
                     else if ("CANCELLED".equals(st)) badgeClass = "status-cancelled";

                     boolean isDraft = "DRAFT".equals(st);
                     boolean isProcessed = "PROCESSED".equals(st);
                     boolean isPaid = "PAID".equals(st);
                     boolean isCancelled = "CANCELLED".equals(st);
                     boolean hasDiscrepancy = (p.getRemarks() != null && p.getRemarks().toLowerCase().contains("discrepancy"));

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
                    <div class="emp-user-cell">
                      <div class="emp-avatar"><%= initials %></div>
                      <div>
                        <div class="emp-name d-flex align-items-center gap-1">
                          <%= HtmlUtil.esc(p.getEmployeeName()) %>
                          <% if (hasDiscrepancy) { %>
                            <i class="bi bi-exclamation-circle-fill text-warning" title="<%= HtmlUtil.esc(p.getRemarks()) %>"></i>
                          <% } %>
                        </div>
                        <div class="emp-id-code">
                          <%= HtmlUtil.esc(p.getEmployeeId()) %> &bull; <%= HtmlUtil.esc(p.getDepartment()) %>
                        </div>
                      </div>
                    </div>
                  </td>
                  <td class="text-end">
                    <span class="num-val">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", p.getBasicSalary()) %></span>
                  </td>
                  <td>
                    <div style="display:flex; align-items:center; gap:5px; flex-wrap:wrap;">
                      <span class="badge bg-light text-dark border px-2 py-1 rounded-2" style="font-size: 11.5px; font-weight: 600;">
                        <%= p.getPresentDays() %> / <%= p.getTotalWorkingDays() %> d
                      </span>
                      <% if (p.getUnpaidDays() != null && p.getUnpaidDays().compareTo(BigDecimal.ZERO) > 0) { %>
                        <span class="badge bg-danger-subtle text-danger border border-danger-subtle rounded-2" style="font-size: 11px;">
                          <%= p.getUnpaidDays() %> LOP
                        </span>
                      <% } %>
                    </div>
                  </td>
                  <td class="text-end">
                    <% if (p.getLossOfPay() != null && p.getLossOfPay().compareTo(BigDecimal.ZERO) > 0) { %>
                      <span class="num-val" style="color:var(--rose-600);">-&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", p.getLossOfPay()) %></span>
                    <% } else { %>
                      <span class="num-val text-muted">&#x20b9;0.00</span>
                    <% } %>
                  </td>
                  <td class="text-end">
                    <span class="num-val">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", p.getGrossSalary()) %></span>
                  </td>
                  <td class="text-end">
                    <span class="num-val" style="color:var(--rose-600);">-&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", p.getTotalDeductions()) %></span>
                  </td>
                  <td class="text-end">
                    <span class="num-val val-net">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", p.getNetSalary()) %></span>
                  </td>
                  <td>
                    <span class="status-badge <%= badgeClass %>"><%= st %></span>
                  </td>
                  <td class="text-end">
                    <div style="display:inline-flex; align-items:center; gap:5px; justify-content:flex-end;">
                      <% if (isDraft) { %>
                        <!-- Adjust Attendance -->
                        <button type="button" class="btn-tbl-action btn-tbl-secondary btn-override" title="Review attendance or adjust days"
                                data-id="<%= p.getId() %>"
                                data-emp-id="<%= HtmlUtil.esc(p.getEmployeeId()) %>"
                                data-emp-name="<%= HtmlUtil.esc(p.getEmployeeName()) %>"
                                data-working-days="<%= p.getTotalWorkingDays() %>"
                                data-present-days="<%= p.getPresentDays() %>"
                                data-paid-leave-days="<%= p.getPaidLeaveDays() %>"
                                data-unpaid-days="<%= p.getUnpaidDays() %>"
                                data-remarks="<%= p.getRemarks() != null ? HtmlUtil.esc(p.getRemarks()) : "" %>">
                          <i class="bi bi-pencil"></i> Adjust
                        </button>

                        <!-- Finalize Record -->
                        <form action="<%= ctx %>/payroll/processing" method="post" style="display:inline;" onsubmit="return confirm('Finalize payroll calculation for <%= HtmlUtil.esc(p.getEmployeeName()) %>?');">
                          <input type="hidden" name="csrfToken" value="<%= CsrfUtil.getToken(session) %>">
                          <input type="hidden" name="action" value="finalize_single">
                          <input type="hidden" name="payrollId" value="<%= p.getId() %>">
                          <input type="hidden" name="id" value="<%= p.getId() %>">
                          <input type="hidden" name="month" value="<%= selectedMonth %>">
                          <input type="hidden" name="year" value="<%= selectedYear %>">
                          <input type="hidden" name="applyAttendance" value="<%= applyAttendance %>">
                          <button type="submit" class="btn-tbl-action btn-tbl-primary" title="Finalize snapshot">
                            <i class="bi bi-check2"></i> Finalize
                          </button>
                        </form>

                        <!-- Cancel Record -->
                        <button type="button" class="btn-tbl-action btn-tbl-danger btn-cancel-modal" title="Cancel record"
                                data-id="<%= p.getId() %>"
                                data-emp-name="<%= HtmlUtil.esc(p.getEmployeeName()) %>">
                          <i class="bi bi-x"></i>
                        </button>
                      <% } else if (isProcessed) { %>
                        <a href="<%= ctx %>/payroll/salary-slip?id=<%= p.getId() %>" class="btn-tbl-action btn-tbl-primary" title="View Payslip">
                          <i class="bi bi-receipt"></i> Slip
                        </a>
                        <a href="<%= ctx %>/payroll/payment?id=<%= p.getId() %>" class="btn-tbl-action btn-tbl-success" title="Record Payment Voucher">
                          <i class="bi bi-cash-stack"></i> Pay
                        </a>
                        <button type="button" class="btn-tbl-action btn-tbl-danger btn-cancel-modal" title="Cancel finalized record"
                                data-id="<%= p.getId() %>"
                                data-emp-name="<%= HtmlUtil.esc(p.getEmployeeName()) %>">
                          <i class="bi bi-x"></i>
                        </button>
                      <% } else if (isPaid) { %>
                        <a href="<%= ctx %>/payroll/salary-slip?id=<%= p.getId() %>" class="btn-tbl-action btn-tbl-success" title="View Paid Slip">
                          <i class="bi bi-check-circle"></i> Paid Slip
                        </a>
                      <% } else if (isCancelled) { %>
                        <span style="font-size:11px; color:var(--slate-400);">Cancelled</span>
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

<!-- Attendance Review & Override Modal -->
<div class="modal fade" id="reviewModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content border-0 shadow rounded-4 overflow-hidden">
      <form action="<%= ctx %>/payroll/processing" method="post" id="overrideForm">
        <input type="hidden" name="csrfToken" value="<%= CsrfUtil.getToken(session) %>">
        <input type="hidden" name="action" value="save_override">
        <input type="hidden" name="payrollId" id="modalId">
        <input type="hidden" name="id" id="modalIdFallback">
        <input type="hidden" name="employeeId" id="modalEmployeeId">
        <input type="hidden" name="month" value="<%= selectedMonth %>">
        <input type="hidden" name="year" value="<%= selectedYear %>">
        <input type="hidden" name="applyAttendance" value="<%= applyAttendance %>">

        <div class="modal-header border-bottom py-3 px-4 bg-light">
          <h6 class="modal-title fw-bold text-dark mb-0" id="modalEmpTitle">Review &amp; Adjust Attendance</h6>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body p-4">
          <div class="row g-3">
            <div class="col-6">
              <label class="form-label small fw-semibold text-muted">Total Working Days <span class="text-danger">*</span></label>
              <input type="number" name="workingDays" id="modalWorkingDays" class="form-control form-control-sm" required min="1" max="31">
            </div>
            <div class="col-6">
              <label class="form-label small fw-semibold text-muted">Present Days <span class="text-danger">*</span></label>
              <input type="number" step="0.5" name="presentDays" id="modalPresentDays" class="form-control form-control-sm" required min="0" max="31">
            </div>
            <div class="col-6">
              <label class="form-label small fw-semibold text-muted">Approved Paid Leaves <span class="text-danger">*</span></label>
              <input type="number" step="0.5" name="paidLeaveDays" id="modalPaidLeaveDays" class="form-control form-control-sm" required min="0" max="31">
            </div>
            <div class="col-6">
              <label class="form-label small fw-semibold text-muted">Unpaid / LOP Days <span class="text-danger">*</span></label>
              <input type="number" step="0.5" name="unpaidDays" id="modalUnpaidDays" class="form-control form-control-sm text-danger fw-bold" required min="0" max="31">
            </div>
            <div class="col-12">
              <label class="form-label small fw-semibold text-muted">Adjustment Reason / Remarks <span class="text-danger">*</span></label>
              <input type="text" name="remarks" id="modalRemarks" class="form-control form-control-sm" required placeholder="Mandatory explanation for audit trail">
              <div class="form-text" style="font-size: 0.72rem;">Remarks are recorded in the audit trail for payroll discrepancy tracking.</div>
            </div>
          </div>
        </div>
        <div class="modal-footer border-top py-2.5 px-4 bg-light">
          <button type="button" class="btn btn-outline-secondary btn-sm rounded-pill px-3" data-bs-dismiss="modal">Cancel</button>
          <button type="submit" class="btn btn-primary btn-sm rounded-pill px-4 fw-semibold">Save Adjustments</button>
        </div>
      </form>
    </div>
  </div>
</div>

<!-- Cancel Payroll Modal -->
<div class="modal fade" id="cancelModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content border-0 shadow rounded-4 overflow-hidden">
      <form action="<%= ctx %>/payroll/processing" method="post">
        <input type="hidden" name="csrfToken" value="<%= CsrfUtil.getToken(session) %>">
        <input type="hidden" name="action" value="cancel">
        <input type="hidden" name="payrollId" id="cancelModalId">
        <input type="hidden" name="id" id="cancelModalIdFallback">
        <input type="hidden" name="month" value="<%= selectedMonth %>">
        <input type="hidden" name="year" value="<%= selectedYear %>">
        <input type="hidden" name="applyAttendance" value="<%= applyAttendance %>">

        <div class="modal-header border-bottom py-3 px-4 bg-light">
          <h6 class="modal-title fw-bold text-danger mb-0">Cancel Payroll Record</h6>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body p-4">
          <p class="small text-muted mb-3" id="cancelModalPrompt">Please provide a reason for cancelling this record:</p>
          <div>
            <label class="form-label small fw-semibold text-muted">Cancellation Reason <span class="text-danger">*</span></label>
            <textarea name="reason" class="form-control form-control-sm" rows="3" required placeholder="e.g. Structure revised after generation, duplicate entry, incorrect attendance recorded"></textarea>
          </div>
        </div>
        <div class="modal-footer border-top py-2.5 px-4 bg-light">
          <button type="button" class="btn btn-outline-secondary btn-sm rounded-pill px-3" data-bs-dismiss="modal">Close</button>
          <button type="submit" class="btn btn-danger btn-sm rounded-pill px-4 fw-semibold">Confirm Cancellation</button>
        </div>
      </form>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
  document.querySelectorAll('.btn-override').forEach(btn => {
    btn.addEventListener('click', function() {
      const id = this.getAttribute('data-id');
      const empId = this.getAttribute('data-emp-id');
      const empName = this.getAttribute('data-emp-name');
      const working = this.getAttribute('data-working-days');
      const present = this.getAttribute('data-present-days');
      const leaves = this.getAttribute('data-paid-leave-days');
      const unpaid = this.getAttribute('data-unpaid-days');
      const remarks = this.getAttribute('data-remarks');

      document.getElementById('modalId').value = id;
      document.getElementById('modalIdFallback').value = id;
      document.getElementById('modalEmployeeId').value = empId;
      document.getElementById('modalEmpTitle').textContent = 'Review & Adjust: ' + empName + ' (' + empId + ')';
      document.getElementById('modalWorkingDays').value = working;
      document.getElementById('modalPresentDays').value = present;
      document.getElementById('modalPaidLeaveDays').value = leaves;
      document.getElementById('modalUnpaidDays').value = unpaid;
      document.getElementById('modalRemarks').value = remarks || '';

      new bootstrap.Modal(document.getElementById('reviewModal')).show();
    });
  });

  document.querySelectorAll('.btn-cancel-modal').forEach(btn => {
    btn.addEventListener('click', function() {
      const id = this.getAttribute('data-id');
      const empName = this.getAttribute('data-emp-name');

      document.getElementById('cancelModalId').value = id;
      document.getElementById('cancelModalIdFallback').value = id;
      document.getElementById('cancelModalPrompt').textContent = 'Are you sure you want to cancel the payroll record for ' + empName + '? Please provide an audit reason:';

      new bootstrap.Modal(document.getElementById('cancelModal')).show();
    });
  });
</script>


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