<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.util.Map, model.Report, model.User" %>
<%
    User currentUser = (User) session.getAttribute("user");
    List<Report.EmployeeItem> reportItems = (List<Report.EmployeeItem>) request.getAttribute("reportItems");
    Report.EmployeeSummary summary = (Report.EmployeeSummary) request.getAttribute("summary");
    if (summary == null) summary = new Report.EmployeeSummary();
    List<String> departments = (List<String>) request.getAttribute("departments");

    String paramSearch = (String) request.getAttribute("paramSearch");
    String paramDept = (String) request.getAttribute("paramDept");
    String paramStatus = (String) request.getAttribute("paramStatus");

    Integer totalRecordsAttr = (Integer) request.getAttribute("totalRecords");
    int totalRecords = totalRecordsAttr != null ? totalRecordsAttr : 0;
    Integer currentPageAttr = (Integer) request.getAttribute("currentPage");
    int currentPage = currentPageAttr != null ? currentPageAttr : 1;
    Integer totalPagesAttr = (Integer) request.getAttribute("totalPages");
    int totalPages = totalPagesAttr != null ? totalPagesAttr : 1;
    Integer fromIndexAttr = (Integer) request.getAttribute("fromIndex");
    int fromIndex = fromIndexAttr != null ? fromIndexAttr : 0;
    Integer toIndexAttr = (Integer) request.getAttribute("toIndex");
    int toIndex = toIndexAttr != null ? toIndexAttr : 0;

    String ctx = request.getContextPath();
    boolean isHr = currentUser != null && currentUser.isHr();
    boolean isManager = currentUser != null && currentUser.isManager();
    boolean isEmployee = currentUser != null && currentUser.isEmployee();
    String portalUrl = ctx + (isHr ? "/hr.html" : (isManager ? "/manager.html" : "/employee.html"));
    String portalLabel = isHr ? "Back to HR Portal" : (isManager ? "Back to Manager Portal" : "Back to Employee Portal");
    String reportsHubLabel = isEmployee ? "My Reports" : "Reports Hub";
    String userInitial = (currentUser != null && currentUser.getUsername() != null && !currentUser.getUsername().isEmpty()) ? currentUser.getUsername().substring(0, 1).toUpperCase() : "U";
    String userName = (currentUser != null && currentUser.getUsername() != null) ? currentUser.getUsername() : "User";
    String roleLabel = isHr ? "HR Admin" : (isManager ? "Manager" : "Employee");

    String paramRole = (String) request.getAttribute("paramRole");
    if (paramRole == null) paramRole = "ALL";

    String filterQuery = "search=" + java.net.URLEncoder.encode(paramSearch != null ? paramSearch : "", "UTF-8")
                       + "&department=" + java.net.URLEncoder.encode(paramDept != null ? paramDept : "ALL", "UTF-8")
                       + "&status=" + java.net.URLEncoder.encode(paramStatus != null ? paramStatus : "ALL", "UTF-8")
                       + "&role=" + java.net.URLEncoder.encode(paramRole != null ? paramRole : "ALL", "UTF-8");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>WorkPulse — Employee Report</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
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
      --emerald-50: #ecfdf5;
      --emerald-border: #a7f3d0;
      --emerald-text: #065f46;
      --amber-500: #f59e0b;
      --amber-50: #fffbeb;
      --amber-border: #fde68a;
      --amber-text: #92400e;
      --rose-500: #f43f5e;
      --rose-50: #fef2f2;
      --rose-border: #fecaca;
      --rose-text: #991b1b;
      --radius-sm: 8px;
      --radius-md: 12px;
      --radius-lg: 16px;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Plus Jakarta Sans', 'Inter', sans-serif;
      background: #f8fafc;
      color: var(--slate-700);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      -webkit-font-smoothing: antialiased;
    }
    /* App Shell & Sidebar Layout */
    .app-shell {
      display: flex;
      min-height: 100vh;
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
      z-index: 100;
    }
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
      padding: 16px 14px 6px;
      display: flex;
      flex-direction: column;
      gap: 4px;
      flex: 0 0 auto;
    }
    .nav-label {
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      color: var(--slate-400);
      padding: 0 10px 8px 10px;
    }
    .tabs-nav {
      display: flex;
      flex-direction: column;
      gap: 4px;
      width: 100%;
    }
    .tabs-nav .btn-sidebar-link {
      display: flex !important;
      align-items: center !important;
      justify-content: flex-start !important;
      gap: 12px !important;
      width: 100%;
      padding: 10px 14px !important;
      background: transparent;
      border: 1px solid transparent;
      border-radius: var(--radius-sm);
      color: var(--slate-600);
      font-size: 13.5px;
      font-weight: 600;
      cursor: pointer;
      text-align: left;
      text-decoration: none !important;
      transition: all 0.18s ease;
    }
    .tabs-nav .btn-sidebar-link svg {
      width: 18px !important;
      height: 18px !important;
      min-width: 18px !important;
      flex-shrink: 0 !important;
      color: var(--slate-400);
      transition: color 0.18s ease, transform 0.18s ease;
    }
    .tabs-nav .btn-sidebar-link:hover {
      background: var(--slate-100);
      color: var(--slate-900);
    }
    .tabs-nav .btn-sidebar-link:hover svg {
      color: var(--primary);
      transform: scale(1.08);
    }
    .tabs-nav .btn-sidebar-link.on {
      background: var(--primary-light);
      color: var(--primary);
      font-weight: 700;
      border-color: var(--primary-border);
      box-shadow: 0 1px 2px rgba(37, 99, 235, 0.08);
    }
        .tabs-nav .btn-sidebar-link {
      position: relative !important;
    }
    .tabs-nav .btn-sidebar-link.on::before {
      content: '';
      position: absolute;
      left: 0;
      top: 6px;
      bottom: 6px;
      width: 3px;
      border-radius: 0 3px 3px 0;
      background: var(--primary);
    }
    .tabs-nav .btn-sidebar-link.on svg {
      color: var(--primary);
    }

    /* Workspace */
    .workspace {
      flex: 1;
      display: flex;
      flex-direction: column;
      min-width: 0;
      background: #f8fafc;
      min-height: 100vh;
    }
    header.topbar {
      height: 72px;
      background: #ffffff;
      border-bottom: 1px solid var(--slate-200);
      padding: 0 36px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      position: sticky;
      top: 0;
      z-index: 50;
    }
    .topbar-title {
      font-size: 19px;
      font-weight: 800;
      color: var(--slate-900);
      letter-spacing: -0.02em;
    }
    .user-ctrls {
      display: flex;
      align-items: center;
      gap: 14px;
    }
    .user-badge {
      display: flex;
      align-items: center;
      gap: 10px;
      background: #ffffff;
      border: 1px solid var(--slate-200);
      padding: 6px 14px;
      border-radius: 9999px;
    }
    .user-avatar {
      width: 26px;
      height: 26px;
      border-radius: 50%;
      background: var(--brand-gradient);
      color: #ffffff;
      font-weight: 800;
      font-size: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .user-info-text {
      font-size: 12.5px;
      font-weight: 700;
      color: var(--slate-800);
    }
    .btn-signout {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: #ffffff;
      border: 1px solid var(--slate-200);
      color: var(--slate-600);
      padding: 7px 14px;
      border-radius: 9999px;
      font-size: 12px;
      font-weight: 700;
      cursor: pointer;
      text-decoration: none;
      transition: all 0.15s ease;
    }
    .btn-signout:hover {
      background: #fef2f2;
      border-color: #fecaca;
      color: #dc2626;
    }
    .content-wrap {
      padding: 28px 36px 60px;
      width: 100%;
      max-width: 1440px;
      margin: 0 auto;
    }
    @media (max-width: 900px) {
      .app-shell { flex-direction: column; }
      .sidebar { width: 100%; height: auto; border-right: none; position: static; }
      .topbar { padding: 0 18px; }
      .content-wrap { padding: 18px; }
    }
    .page-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 24px;
      flex-wrap: wrap;
      gap: 16px;
    }
    .page-title {
      font-size: 24px;
      font-weight: 800;
      color: var(--slate-900);
      letter-spacing: -0.02em;
    }
    .page-subtitle {
      font-size: 13.5px;
      color: var(--slate-500);
      margin-top: 4px;
    }

    /* KPI Grid */
    .kpi-grid {
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }
    @media (max-width: 900px) {
      .kpi-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    }
    .kpi-card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-md);
      padding: 16px 18px;
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.05);
      display: flex;
      flex-direction: column;
      justify-content: space-between;
    }
    .kpi-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 8px;
    }
    .kpi-label {
      font-size: 11.5px;
      font-weight: 700;
      color: var(--slate-500);
      text-transform: uppercase;
      letter-spacing: 0.04em;
    }
    .kpi-icon {
      width: 32px;
      height: 32px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .kpi-val {
      font-size: 26px;
      font-weight: 800;
      color: var(--slate-900);
    }
    .kpi-sub {
      font-size: 11.5px;
      color: var(--slate-500);
      margin-top: 4px;
    }

    /* Filter Card */
    .filter-card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-md);
      padding: 18px 20px;
      margin-bottom: 24px;
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.05);
    }
    .filter-form {
      display: flex;
      flex-wrap: wrap;
      gap: 14px;
      align-items: flex-end;
    }
    .form-group {
      display: flex;
      flex-direction: column;
      flex: 1 1 180px;
      min-width: 140px;
    }
    .form-group label {
      font-size: 11.5px;
      font-weight: 700;
      color: var(--slate-600);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      margin-bottom: 6px;
    }
    .form-group input, .form-group select {
      height: 38px;
      background: #ffffff;
      border: 1.5px solid var(--slate-300);
      border-radius: var(--radius-sm);
      padding: 0 12px;
      font-size: 13.5px;
      color: var(--slate-800);
      font-family: inherit;
      width: 100%;
    }
    .form-group input:focus, .form-group select:focus {
      outline: none;
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12);
    }
    .filter-actions {
      display: flex;
      gap: 8px;
      align-items: flex-end;
      flex-shrink: 0;
    }
    .btn-submit {
      height: 38px;
      padding: 0 18px;
      background: var(--brand-gradient);
      color: #ffffff;
      font-size: 13px;
      font-weight: 700;
      border: none;
      border-radius: var(--radius-sm);
      display: inline-flex;
      align-items: center;
      gap: 6px;
      cursor: pointer;
      box-shadow: 0 2px 6px rgba(37, 99, 235, 0.25);
      transition: all 0.15s ease;
      white-space: nowrap;
    }
    .btn-submit:hover {
      background: linear-gradient(135deg, #1e40af 0%, #1d4ed8 100%);
      transform: translateY(-1px);
    }
    .btn-reset {
      height: 38px;
      padding: 0 14px;
      background: #ffffff;
      color: var(--slate-600);
      border: 1.5px solid var(--slate-300);
      border-radius: var(--radius-sm);
      font-size: 13px;
      font-weight: 700;
      text-decoration: none;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: all 0.15s ease;
      white-space: nowrap;
    }
    .btn-reset:hover {
      background: var(--slate-100);
      color: var(--slate-900);
      border-color: var(--slate-400);
    }
    .btn-print {
      height: 38px;
      padding: 0 16px;
      background: #ffffff;
      color: var(--slate-700);
      border: 1.5px solid var(--slate-300);
      border-radius: var(--radius-sm);
      font-size: 13px;
      font-weight: 700;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      cursor: pointer;
      margin-left: auto;
      transition: all 0.15s ease;
    }
    .btn-print:hover { background: var(--slate-100); border-color: var(--slate-400); }

    /* Table Card */
    .table-card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-lg);
      overflow: hidden;
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.05);
    }
    .table-top {
      padding: 16px 22px;
      border-bottom: 1px solid var(--slate-200);
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 12px;
      background: #ffffff;
    }
    .table-title {
      font-size: 15.5px;
      font-weight: 800;
      color: var(--slate-900);
    }
    table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
      font-size: 13.5px;
    }
    thead {
      background: #f8fafc;
      border-bottom: 1px solid var(--slate-200);
    }
    th {
      padding: 12px 18px;
      font-weight: 700;
      color: var(--slate-600);
      text-transform: uppercase;
      font-size: 11.5px;
      letter-spacing: 0.04em;
    }
    tbody tr {
      border-bottom: 1px solid var(--slate-200);
      transition: background 0.15s;
    }
    tbody tr:hover { background: #f8fafc; }
    tbody tr:last-child { border-bottom: none; }
    td {
      padding: 13px 18px;
      color: var(--slate-700);
      vertical-align: middle;
    }
    .id-badge {
      font-family: monospace;
      font-size: 12.5px;
      font-weight: 700;
      color: #1d4ed8;
      background: #eff6ff;
      border: 1px solid #bfdbfe;
      padding: 2px 7px;
      border-radius: 6px;
      display: inline-block;
    }
    .badge {
      display: inline-block;
      padding: 3px 9px;
      border-radius: 9999px;
      font-size: 11.5px;
      font-weight: 700;
      letter-spacing: 0.02em;
      text-transform: uppercase;
    }
    .badge-active { background: #ecfdf5; color: #065f46; border: 1px solid #a7f3d0; }
    .badge-inactive { background: #fef2f2; color: #991b1b; border: 1px solid #fecaca; }
    .role-badge {
      font-size: 11.5px;
      font-weight: 700;
      padding: 2px 8px;
      border-radius: 6px;
      background: var(--slate-100);
      color: var(--slate-700);
      border: 1px solid var(--slate-200);
    }

    /* Empty state */
    .empty-state {
      padding: 60px 20px;
      text-align: center;
      color: var(--slate-500);
    }
    .empty-icon {
      width: 56px;
      height: 56px;
      margin: 0 auto 16px;
      border-radius: 16px;
      background: var(--slate-100);
      color: var(--slate-400);
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .empty-title {
      font-size: 16px;
      font-weight: 700;
      color: var(--slate-800);
      margin-bottom: 6px;
    }
    .empty-desc {
      font-size: 13.5px;
      max-width: 420px;
      margin: 0 auto 16px;
      line-height: 1.5;
    }

    /* Pagination */
    .pagination-bar {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 13px 20px;
      background: #ffffff;
      border-top: 1px solid var(--slate-200);
      font-size: 13px;
      color: var(--slate-600);
      flex-wrap: wrap;
      gap: 12px;
    }
    .pagination-nav {
      display: flex;
      align-items: center;
      gap: 4px;
    }
    .page-btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-width: 32px;
      height: 32px;
      padding: 0 8px;
      border-radius: 6px;
      border: 1px solid var(--slate-200);
      background: #ffffff;
      color: var(--slate-700);
      font-size: 12.5px;
      font-weight: 600;
      text-decoration: none;
      transition: all 0.15s;
    }
    .page-btn:hover:not(.disabled):not(.active) {
      background: var(--slate-100);
      border-color: var(--slate-300);
      color: var(--slate-900);
    }
    .page-btn.active {
      background: var(--primary);
      border-color: var(--primary);
      color: #ffffff;
      font-weight: 700;
    }
    .page-btn.disabled {
      opacity: 0.4;
      cursor: not-allowed;
      pointer-events: none;
    }

    @media print {
      header.topbar, .filter-card, .pagination-bar, .btn-print, .btn-launch { display: none !important; }
      body { background: #ffffff; }
      .container { max-width: 100%; margin: 0; padding: 0; }
      .table-card { border: none; box-shadow: none; }
    }
  
    
      to { opacity: 1; transform: translateY(0); }
    }

  
    /* Direct Report Action Buttons (No Popups) */
    .report-header-actions {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      flex-wrap: wrap;
    }
    .btn-rep-action {
      height: 38px;
      padding: 0 14px;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 600;
      display: inline-flex;
      align-items: center;
      gap: 7px;
      text-decoration: none;
      cursor: pointer;
      transition: all 0.15s ease;
      box-shadow: 0 1px 2px 0 rgba(0,0,0,0.05);
      white-space: nowrap;
    }
    
    .btn-rep-excel {
      background: #059669;
      color: #ffffff;
      border: 1px solid #059669;
    }
    .btn-rep-excel:hover {
      background: #047857;
      border-color: #047857;
      color: #ffffff;
    }
    .btn-rep-csv {
      background: #2563eb;
      color: #ffffff;
      border: 1px solid #2563eb;
    }
    .btn-rep-csv:hover {
      background: #1d4ed8;
      border-color: #1d4ed8;
      color: #ffffff;
    }
    .btn-rep-print {
      background: #ffffff;
      color: var(--slate-700);
      border: 1px solid var(--slate-300);
    }
    .btn-rep-print:hover {
      background: var(--slate-100);
      border-color: var(--slate-400);
      color: var(--slate-900);
    }
    @media print {
      header.topbar, .filter-card, .pagination-bar, .report-header-actions, .btn-rep-action, .btn-print, .btn-export-main, .export-dropdown-container { display: none !important; }
    }

  </style>
  <script>
    function downloadReport(format) {
      var form = document.querySelector('form.filter-form');
      if (form) {
        var expInput = form.querySelector('input[name="export"]');
        if (!expInput) {
          expInput = document.createElement('input');
          expInput.type = 'hidden';
          expInput.name = 'export';
          form.appendChild(expInput);
        }
        expInput.value = format;
        form.submit();
        setTimeout(function() {
          if (expInput) expInput.value = '';
        }, 600);
        return false;
      }
      return true;
    }
  </script>

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
<div class="app-shell">  <!-- Consistent WorkPulse Left Sidebar -->
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
      <div id="acc-reports-header-mgr" class="nav-accordion-header open" onclick="toggleNavAccordion('acc-reports-mgr')">
        <div class="acc-icon-box">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M21.21 15.89A10 10 0 1 1 8 2.83"></path><path d="M22 12A10 10 0 0 0 12 2v10z"></path></svg>
        </div>
        <div class="acc-text-wrap">
          <span class="acc-title">Reports</span>
          <span class="acc-subtitle">Open report list</span>
        </div>
        <svg class="acc-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="6 9 12 15 18 9"></polyline></svg>
      </div>

      <div id="acc-reports-body-mgr" class="nav-accordion-body open">
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
        <a href="<%= ctx %>/employeeReport" class="nav-accordion-item on">
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
      <div id="acc-reports-header" class="nav-accordion-header open" onclick="toggleNavAccordion('acc-reports')">
        <div class="acc-icon-box">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M21.21 15.89A10 10 0 1 1 8 2.83"></path><path d="M22 12A10 10 0 0 0 12 2v10z"></path></svg>
        </div>
        <div class="acc-text-wrap">
          <span class="acc-title">Reports</span>
          <span class="acc-subtitle">Open report list</span>
        </div>
        <svg class="acc-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="6 9 12 15 18 9"></polyline></svg>
      </div>

      <div id="acc-reports-body" class="nav-accordion-body open">
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
        <a href="<%= ctx %>/employeeReport" class="nav-accordion-item on">
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
      <div id="acc-payroll-header" class="nav-accordion-header " onclick="toggleNavAccordion('acc-payroll')">
        <div class="acc-icon-box">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="2" y="4" width="20" height="16" rx="2"></rect><line x1="2" y1="10" x2="22" y2="10"></line><circle cx="16" cy="15" r="1"></circle></svg>
        </div>
        <div class="acc-text-wrap">
          <span class="acc-title">Payroll</span>
          <span class="acc-subtitle">Salary & compensation</span>
        </div>
        <svg class="acc-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="6 9 12 15 18 9"></polyline></svg>
      </div>

      <div id="acc-payroll-body" class="nav-accordion-body ">
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
      <h1 class="topbar-title"><%= isEmployee ? "Employee Directory" : "Employee Headcount & Status Report" %></h1>
      <div class="user-ctrls">
        <div class="user-badge">
          <div class="user-avatar"><%= userInitial %></div>
          <span class="user-info-text"><%= userName %><%= (isEmployee && currentUser != null && currentUser.getEmployeeId() != null && !currentUser.getEmployeeId().isEmpty()) ? " (" + currentUser.getEmployeeId() + ")" : " (" + roleLabel + ")" %></span>
        </div>
        <a class="btn-signout" href="<%= ctx %>/logout">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
          Logout
        </a>
      </div>
    </header>

    <div class="content-wrap">
    <div class="page-header">
      <div>
        <h1 class="page-title">Employee Directory Report</h1>
        <p class="page-subtitle">Roster of employee records, roles, departmental mapping, and account access status.</p>
      </div>
            <div class="report-header-actions">
        <a href="<%= ctx %>/employeeReport?export=excel&<%= filterQuery %>" onclick="return downloadReport('excel')" class="btn-rep-action btn-rep-excel" download>
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="8" y1="13" x2="16" y2="13"></line><line x1="8" y1="17" x2="16" y2="17"></line></svg>
          Download Excel
        </a>
        <button type="button" onclick="window.print()" class="btn-rep-action btn-rep-print">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 6 2 18 2 18 9"></polyline><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path><rect x="6" y="14" width="12" height="8"></rect></svg>
          Print / PDF
        </button>
      </div>
    </div>

    <!-- Summary KPI Cards -->
    <div class="kpi-grid">
      <div class="kpi-card">
        <div class="kpi-header">
          <span class="kpi-label">Total Employees</span>
          <div class="kpi-icon" style="background:#eff6ff; color:#2563eb;">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle></svg>
          </div>
        </div>
        <div class="kpi-val"><%= summary.getTotalCount() %></div>
        <div class="kpi-sub">In current view</div>
      </div>

      <div class="kpi-card">
        <div class="kpi-header">
          <span class="kpi-label">Active Accounts</span>
          <div class="kpi-icon" style="background:#ecfdf5; color:#059669;">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"></polyline></svg>
          </div>
        </div>
        <div class="kpi-val" style="color:#059669;"><%= summary.getActiveCount() %></div>
        <div class="kpi-sub">Active status</div>
      </div>

      <div class="kpi-card">
        <div class="kpi-header">
          <span class="kpi-label">Inactive Accounts</span>
          <div class="kpi-icon" style="background:#fef2f2; color:#dc2626;">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>
          </div>
        </div>
        <div class="kpi-val" style="color:#dc2626;"><%= summary.getInactiveCount() %></div>
        <div class="kpi-sub">Disabled accounts</div>
      </div>

      <div class="kpi-card">
        <div class="kpi-header">
          <span class="kpi-label">Departments</span>
          <div class="kpi-icon" style="background:#f5f3ff; color:#7c3aed;">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path></svg>
          </div>
        </div>
        <div class="kpi-val" style="color:#7c3aed;"><%= summary.getDepartmentCounts().size() %></div>
        <div class="kpi-sub">Distinct units</div>
      </div>
    </div>

    <!-- Filter Card -->
    <div class="filter-card">
      <form action="<%= ctx %>/employeeReport" method="GET" class="filter-form">
        <div class="form-group" style="flex:2 1 240px;">
          <label for="searchInput">Search by Name, ID, or Email</label>
          <input type="text" id="searchInput" name="search" value="<%= paramSearch != null ? paramSearch : "" %>" placeholder="e.g. Dinesh, EMP101, @gmail.com">
        </div>

        <div class="form-group">
          <label for="deptSelect">Department</label>
          <select id="deptSelect" name="department">
            <option value="ALL" <%= "ALL".equalsIgnoreCase(paramDept) ? "selected" : "" %>>All Departments</option>
            <% if (departments != null) {
                 for (String d : departments) { %>
                   <option value="<%= d %>" <%= d.equalsIgnoreCase(paramDept) ? "selected" : "" %>><%= d %></option>
            <%   }
               } %>
          </select>
        </div>

        <% if (isHr) { %>
        <div class="form-group">
          <label for="roleSelect">Staff Role</label>
          <select id="roleSelect" name="role">
            <option value="ALL" <%= "ALL".equalsIgnoreCase(paramRole) ? "selected" : "" %>>All Staff (Employees & Managers)</option>
            <option value="EMPLOYEE" <%= "EMPLOYEE".equalsIgnoreCase(paramRole) ? "selected" : "" %>>Employees Only</option>
            <option value="MANAGER" <%= "MANAGER".equalsIgnoreCase(paramRole) ? "selected" : "" %>>Managers Only</option>
          </select>
        </div>
        <% } %>

        <div class="form-group">
          <label for="statusSelect">Account Status</label>
          <select id="statusSelect" name="status">
            <option value="ALL" <%= "ALL".equalsIgnoreCase(paramStatus) ? "selected" : "" %>>All Statuses</option>
            <option value="ACTIVE" <%= "ACTIVE".equalsIgnoreCase(paramStatus) ? "selected" : "" %>>ACTIVE</option>
            <option value="INACTIVE" <%= "INACTIVE".equalsIgnoreCase(paramStatus) ? "selected" : "" %>>INACTIVE</option>
          </select>
        </div>

        <div class="filter-actions">
          <button type="submit" class="btn-submit">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
            Search
          </button>

          <a href="<%= ctx %>/employeeReport" class="btn-reset">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"></path><polyline points="3 3 3 8 8 8"></polyline></svg>
            Reset
          </a>
        </div>
      </form>
    </div>

    <!-- Data Table Card -->
    <div class="table-card">
      <div class="table-top">
        <h2 class="table-title">Employee Directory (<%= totalRecords %> records)</h2>
      </div>

      <% if (reportItems == null || reportItems.isEmpty()) { %>
        <div class="empty-state">
          <div class="empty-icon">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
          </div>
          <h3 class="empty-title">No matching employee records found</h3>
          <p class="empty-desc">No employees match your current filter criteria. Try adjusting your search query, selecting "All Departments", or click Reset.</p>
          <a href="<%= ctx %>/employeeReport" class="btn-submit" style="display:inline-flex;">Reset Filters</a>
        </div>
      <% } else { %>
        <table>
          <thead>
            <tr>
              <th>Employee ID</th>
              <th>Full Name</th>
              <th>Email Address</th>
              <th>Department</th>
              <th>Role</th>
              <th>Account Status</th>
            </tr>
          </thead>
          <tbody>
            <% for (Report.EmployeeItem emp : reportItems) { %>
              <tr>
                <td><span class="id-badge"><%= emp.getEmployeeId() %></span></td>
                <td><strong style="color:var(--slate-900);"><%= emp.getName() %></strong></td>
                <td><a href="mailto:<%= emp.getEmail() %>" style="color:var(--primary); text-decoration:none;"><%= emp.getEmail() %></a></td>
                <td><span style="font-weight:600;"><%= emp.getDepartment() %></span></td>
                <td><span class="role-badge"><%= emp.getRole() %></span></td>
                <td>
                  <span class="badge <%= emp.isActive() ? "badge-active" : "badge-inactive" %>">
                    <%= emp.getStatus() %>
                  </span>
                </td>
              </tr>
            <% } %>
          </tbody>
        </table>

        <!-- Pagination -->
        <% if (totalPages > 1) { %>
          <div class="pagination-bar">
            <div>
              Showing <strong><%= fromIndex %></strong> to <strong><%= toIndex %></strong> of <strong><%= totalRecords %></strong> employees
            </div>
            <div class="pagination-nav">
              <a href="employeeReport?<%= filterQuery %>&page=1" class="page-btn <%= currentPage == 1 ? "disabled" : "" %>">&laquo;</a>
              <a href="employeeReport?<%= filterQuery %>&page=<%= currentPage - 1 %>" class="page-btn <%= currentPage == 1 ? "disabled" : "" %>">&lsaquo;</a>

              <% for (int p = 1; p <= totalPages; p++) { %>
                <a href="employeeReport?<%= filterQuery %>&page=<%= p %>" class="page-btn <%= p == currentPage ? "active" : "" %>"><%= p %></a>
              <% } %>

              <a href="employeeReport?<%= filterQuery %>&page=<%= currentPage + 1 %>" class="page-btn <%= currentPage == totalPages ? "disabled" : "" %>">&rsaquo;</a>
              <a href="employeeReport?<%= filterQuery %>&page=<%= totalPages %>" class="page-btn <%= currentPage == totalPages ? "disabled" : "" %>">&raquo;</a>
            </div>
          </div>
        <% } %>
      <% } %>
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
