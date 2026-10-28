<%@ page contentType="text/html;charset=UTF-8" language="java" isELIgnored="true" %>
<%@ page import="java.util.List, java.math.BigDecimal, com.smartoffice.model.SalaryStructure, com.smartoffice.model.SalaryComponent, com.smartoffice.util.HtmlUtil, com.smartoffice.util.PayrollRules, com.smartoffice.util.CsrfUtil, model.Employee, model.User" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login.html");
        return;
    }
    if (!currentUser.isHr()) {
        response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access Denied: Only HR administrators can edit salary structures.");
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

    SalaryStructure structure = (SalaryStructure) request.getAttribute("structure");
    List<Employee> employees = (List<Employee>) request.getAttribute("employees");

    String errorMessage = (String) request.getAttribute("errorMessage");
    boolean isEdit = structure != null && structure.getId() > 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>WorkPulse — <%= isEdit ? "Revise" : "Configure" %> Salary Structure</title>
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

    /* Breadcrumbs */
    .breadcrumb-bar {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 13px;
      margin-bottom: 16px;
      color: var(--slate-400);
    }
    .breadcrumb-link {
      color: var(--primary);
      text-decoration: none;
      font-weight: 600;
    }
    .breadcrumb-link:hover { text-decoration: underline; }

    /* Page Header */
    .page-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      margin-bottom: 22px;
    }
    .page-title { font-size: 22px; font-weight: 800; color: var(--slate-900); letter-spacing: -0.01em; }
    .page-subtitle { font-size: 13.5px; color: var(--slate-500); }

    /* Cards */
    .form-card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-md);
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.03);
    }
    .card-preview {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-md);
      box-shadow: 0 4px 14px rgba(15, 23, 42, 0.05);
    }
    .component-row {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: 8px;
      padding: 12px 14px;
      margin-bottom: 10px;
      transition: all 0.15s ease;
    }
    .component-row:hover {
      border-color: var(--primary-border);
      box-shadow: 0 2px 6px rgba(37, 99, 235, 0.06);
    }
    .quick-pill {
      font-size: 12px;
      font-weight: 600;
      padding: 4px 10px;
      border-radius: 20px;
      border: 1px solid var(--slate-200);
      background: #ffffff;
      color: var(--slate-700);
      transition: all 0.15s ease;
      cursor: pointer;
    }
    .quick-pill:hover {
      background-color: var(--primary-light);
      color: var(--primary-dark);
      border-color: var(--primary-border);
    }
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
        <a href="<%= ctx %>/payroll/salary-structures" class="nav-accordion-item on">
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
      <h1 class="topbar-title"><%= isEdit ? "Revise Salary Structure" : "Configure Salary Structure" %></h1>
      <div class="user-ctrls">
        <a href="<%= ctx %>/payroll/salary-structures" class="btn-back-portal">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><polyline points="15 18 9 12 15 6"></polyline></svg>
          Back to Structures
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
      <!-- Breadcrumb Bar -->
      <div class="breadcrumb-bar">
        <a href="<%= ctx %>/payroll" class="breadcrumb-link">Payroll Hub</a>
        <span>&bull;</span>
        <a href="<%= ctx %>/payroll/salary-structures" class="breadcrumb-link">Salary Structures</a>
        <span>&bull;</span>
        <span style="color:var(--slate-800); font-weight:700;"><%= isEdit ? "Revise Structure" : "Configure New" %></span>
      </div>

      <!-- Error Alert -->
      <% if (errorMessage != null && !errorMessage.isEmpty()) { %>
        <div class="alert alert-danger alert-dismissible fade show border-0 shadow-sm rounded-3 mb-4 d-flex align-items-center" role="alert">
          <i class="bi bi-exclamation-triangle-fill text-danger fs-5 me-2"></i>
          <div><%= HtmlUtil.esc(errorMessage) %></div>
          <button type="button" class="btn-close ms-auto" data-bs-dismiss="alert"></button>
        </div>
      <% } %>

      <!-- Form & Live Preview Row -->
      <form action="<%= ctx %>/payroll/salary-structure-form" method="post" id="structureForm">
        <input type="hidden" name="csrfToken" value="<%= CsrfUtil.getToken(session) %>">
        <% if (isEdit) { %>
          <input type="hidden" name="id" value="<%= structure.getId() %>">
          <input type="hidden" name="employeeId" value="<%= HtmlUtil.esc(structure.getEmployeeId()) %>">
        <% } %>

        <div class="row g-4">
          <!-- Left Column: Form Controls -->
          <div class="col-lg-8">
            <!-- 1. Employee & Base Pay Card -->
            <div class="form-card p-4 mb-4 bg-white">
              <h6 class="fw-bold mb-3 text-dark d-flex align-items-center gap-2 border-bottom pb-2">
                <i class="bi bi-person-badge text-primary"></i> 1. Employee &amp; Baseline Pay
              </h6>
              <div class="row g-3">
                <div class="col-md-6">
                  <label class="form-label fw-semibold small text-muted mb-1">Employee <span class="text-danger">*</span></label>
                  <% if (isEdit) { %>
                    <input type="text" class="form-control form-control-sm bg-light"
                           value="<%= HtmlUtil.esc(structure.getEmployeeName()) %> (<%= HtmlUtil.esc(structure.getEmployeeId()) %>) &mdash; <%= HtmlUtil.esc(structure.getDepartment()) %>"
                           readonly>
                    <div class="form-text" style="font-size: 0.72rem;">Employee ID cannot be altered during structure revision.</div>
                  <% } else { %>
                    <select name="employeeId" class="form-select form-select-sm" required>
                      <option value="">-- Select Active Employee --</option>
                      <% if (employees != null) {
                           for (Employee emp : employees) {
                             String sel = (structure != null && emp.getId().equalsIgnoreCase(structure.getEmployeeId())) ? "selected" : "";
                      %>
                        <option value="<%= HtmlUtil.esc(emp.getId()) %>" <%= sel %>>
                          <%= HtmlUtil.esc(emp.getId()) %> &mdash; <%= HtmlUtil.esc(emp.getName()) %> (<%= HtmlUtil.esc(emp.getDepartment()) %>)
                        </option>
                      <%   }
                         } %>
                    </select>
                  <% } %>
                </div>
                <div class="col-md-6">
                  <label class="form-label fw-semibold small text-muted mb-1">Basic Monthly Salary (&#x20b9;) <span class="text-danger">*</span></label>
                  <div class="input-group input-group-sm">
                    <span class="input-group-text bg-light text-muted">&#x20b9;</span>
                    <input type="number" step="0.01" min="1" name="basicSalary" id="basicSalaryInput" class="form-control fw-bold"
                           value="<%= structure != null && structure.getBasicSalary() != null ? structure.getBasicSalary() : "" %>"
                           placeholder="e.g. 50000.00" required>
                  </div>
                </div>
                <div class="col-md-6">
                  <label class="form-label fw-semibold small text-muted mb-1">Effective From Date <span class="text-danger">*</span></label>
                  <input type="date" name="effectiveFrom" class="form-control form-control-sm"
                         value="<%= structure != null && structure.getEffectiveFrom() != null ? structure.getEffectiveFrom().toString() : java.time.LocalDate.now().withDayOfMonth(1).toString() %>" required>
                </div>
                <div class="col-md-6">
                  <label class="form-label fw-semibold small text-muted mb-1">Effective To Date (Optional)</label>
                  <input type="date" name="effectiveTo" class="form-control form-control-sm"
                         value="<%= structure != null && structure.getEffectiveTo() != null ? structure.getEffectiveTo().toString() : "" %>"
                         placeholder="Leave empty for ongoing structure">
                </div>
              </div>
            </div>

            <!-- 2. Dynamic Allowances & Deductions Builder -->
            <div class="form-card p-4 bg-white">
              <div class="d-flex flex-wrap justify-content-between align-items-center mb-3 border-bottom pb-2.5 gap-2">
                <div>
                  <h6 class="fw-bold mb-0 text-dark d-flex align-items-center gap-2">
                    <i class="bi bi-calculator text-primary"></i> 2. Allowances &amp; Deductions
                  </h6>
                  <span class="text-muted small" style="font-size: 0.75rem;">Fixed amounts or percentage rates computed on Basic Salary (max 30 items)</span>
                </div>
                <div class="d-flex gap-2">
                  <button type="button" class="btn btn-outline-success btn-sm rounded-pill px-3 fw-semibold" onclick="addComponentRow('EARNING')">
                    <i class="bi bi-plus-lg me-1"></i> Add Earning
                  </button>
                  <button type="button" class="btn btn-outline-danger btn-sm rounded-pill px-3 fw-semibold" onclick="addComponentRow('DEDUCTION')">
                    <i class="bi bi-dash-lg me-1"></i> Add Deduction
                  </button>
                </div>
              </div>

              <!-- Quick Template Chips -->
              <div class="mb-3 d-flex flex-wrap gap-1.5 align-items-center">
                <span class="small text-muted fw-semibold me-1" style="font-size: 0.75rem;">Quick Templates:</span>
                <button type="button" class="quick-pill" onclick="quickAdd('House Rent Allowance (HRA)', 'EARNING', 'PERCENTAGE', 40, 'Housing allowance at 40% of basic')">+ HRA (40%)</button>
                <button type="button" class="quick-pill" onclick="quickAdd('Conveyance Allowance', 'EARNING', 'FIXED', 2500, 'Monthly conveyance reimbursement')">+ Conveyance (&#x20b9;2,500)</button>
                <button type="button" class="quick-pill" onclick="quickAdd('Medical Allowance', 'EARNING', 'FIXED', 1500, 'Monthly medical allowance')">+ Medical (&#x20b9;1,500)</button>
                <button type="button" class="quick-pill" onclick="quickAdd('Special Allowance', 'EARNING', 'FIXED', 5000, 'Special compensatory allowance')">+ Special (&#x20b9;5,000)</button>
                <button type="button" class="quick-pill" onclick="quickAdd('Provident Fund (PF)', 'DEDUCTION', 'PERCENTAGE', 12, 'Employee EPF statutory contribution (12%)')">- PF (12%)</button>
                <button type="button" class="quick-pill" onclick="quickAdd('Professional Tax (PT)', 'DEDUCTION', 'FIXED', 200, 'State professional tax deduction')">- PT (&#x20b9;200)</button>
              </div>

              <!-- Dynamic Components Container -->
              <div id="componentsContainer">
                <% if (structure != null && structure.getComponents() != null && !structure.getComponents().isEmpty()) {
                     for (SalaryComponent comp : structure.getComponents()) {
                %>
                  <div class="component-row">
                    <div class="row g-2 align-items-center">
                      <div class="col-md-3">
                        <label class="form-label small text-muted mb-1">Component Name <span class="text-danger">*</span></label>
                        <input type="text" name="componentName" class="form-control form-control-sm comp-name" value="<%= HtmlUtil.esc(comp.getComponentName()) %>" required placeholder="e.g. HRA">
                      </div>
                      <div class="col-md-2">
                        <label class="form-label small text-muted mb-1">Type</label>
                        <select name="componentType" class="form-select form-select-sm comp-type" onchange="updateLivePreview()">
                          <option value="EARNING" <%= "EARNING".equalsIgnoreCase(comp.getComponentType()) ? "selected" : "" %>>Earning (+)</option>
                          <option value="DEDUCTION" <%= "DEDUCTION".equalsIgnoreCase(comp.getComponentType()) ? "selected" : "" %>>Deduction (-)</option>
                        </select>
                      </div>
                      <div class="col-md-2">
                        <label class="form-label small text-muted mb-1">Calculation</label>
                        <select name="calculationType" class="form-select form-select-sm comp-calc" onchange="updateLivePreview()">
                          <option value="FIXED" <%= "FIXED".equalsIgnoreCase(comp.getCalculationType()) ? "selected" : "" %>>Fixed (&#x20b9;)</option>
                          <option value="PERCENTAGE" <%= "PERCENTAGE".equalsIgnoreCase(comp.getCalculationType()) ? "selected" : "" %>>% of Basic</option>
                        </select>
                      </div>
                      <div class="col-md-2">
                        <label class="form-label small text-muted mb-1">Amount / % <span class="text-danger">*</span></label>
                        <input type="number" step="0.01" min="0" name="componentAmount" class="form-control form-control-sm comp-amt" value="<%= comp.getAmount() %>" required oninput="updateLivePreview()">
                      </div>
                      <div class="col-md-2">
                        <label class="form-label small text-muted mb-1">Description</label>
                        <input type="text" name="componentDescription" class="form-control form-control-sm comp-desc" value="<%= comp.getDescription() != null ? HtmlUtil.esc(comp.getDescription()) : "" %>" placeholder="Optional notes">
                      </div>
                      <div class="col-md-1 text-end pt-3">
                        <button type="button" class="btn btn-outline-danger btn-sm border-0 rounded-circle" onclick="removeComponentRow(this)" title="Remove" style="width: 28px; height: 28px; padding: 0;">
                          <i class="bi bi-trash fs-6"></i>
                        </button>
                      </div>
                    </div>
                  </div>
                <%   }
                   } %>
              </div>

              <div id="emptyComponentsMsg" class="text-center py-4 text-muted <%= (structure != null && structure.getComponents() != null && !structure.getComponents().isEmpty()) ? "d-none" : "" %>">
                <i class="bi bi-calculator text-secondary fs-3 d-block mb-1 opacity-50"></i>
                No components configured yet. Click "Add Earning" or select a template above.
              </div>

            </div>
          </div>

          <!-- Right Column: Real-Time Live Preview -->
          <div class="col-lg-4">
            <div class="card card-preview p-4 sticky-top" style="top: 86px;">
              <h6 class="fw-bold mb-3 text-dark d-flex align-items-center gap-2 border-bottom pb-2">
                <i class="bi bi-cash-coin text-primary"></i> Live Compensation Preview
              </h6>
              <div class="border-bottom pb-2 mb-3">
                <div class="d-flex justify-content-between mb-1.5">
                  <span class="text-muted small">Basic Monthly Pay:</span>
                  <span class="fw-semibold text-dark" id="previewBasic">&#x20b9;0.00</span>
                </div>
                <div class="d-flex justify-content-between mb-1.5">
                  <span class="text-success small fw-medium">+ Allowances (Total):</span>
                  <span class="fw-semibold text-success" id="previewEarnings">+&#x20b9;0.00</span>
                </div>
                <div class="d-flex justify-content-between mb-1.5">
                  <span class="text-muted small">Monthly Gross Salary:</span>
                  <span class="fw-bold text-dark" id="previewGross">&#x20b9;0.00</span>
                </div>
                <div class="d-flex justify-content-between mb-1.5">
                  <span class="text-danger small fw-medium">- Deductions (Total):</span>
                  <span class="fw-semibold text-danger" id="previewDeductions">-&#x20b9;0.00</span>
                </div>
              </div>

              <div class="p-3 mb-3 rounded-3" style="background: #ecfdf5; border: 1px solid #a7f3d0;">
                <span class="text-muted small fw-semibold text-uppercase d-block" style="font-size: 0.7rem; color: #065f46;">Estimated Net Take-Home</span>
                <div class="fs-4 fw-extrabold text-success mt-0.5" id="previewNet">&#x20b9;0.00</div>
              </div>

              <div id="validationWarning" class="alert alert-warning py-2 small d-none mb-3"></div>

              <div class="d-grid gap-2">
                <button type="submit" id="submitBtn" class="btn btn-primary btn-sm py-2 fw-semibold rounded-pill shadow-sm">
                  <i class="bi bi-check-circle me-1"></i> <%= isEdit ? "Save Revised Structure" : "Save Salary Structure" %>
                </button>
                <a href="<%= ctx %>/payroll/salary-structures" class="btn btn-outline-secondary btn-sm py-2 rounded-pill">
                  Cancel
                </a>
              </div>
            </div>
          </div>
        </div>
      </form>

    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
  function addComponentRow(type, name, calc, amt, desc) {
    const container = document.getElementById('componentsContainer');
    if (container.querySelectorAll('.component-row').length >= 30) {
      alert('Maximum 30 components allowed per salary structure.');
      return;
    }
    name = name || '';
    calc = calc || 'FIXED';
    amt = amt || '';
    desc = desc || '';
    document.getElementById('emptyComponentsMsg').classList.add('d-none');
    const div = document.createElement('div');
    div.className = 'component-row';
    div.innerHTML = 
      '<div class="row g-2 align-items-center">' +
        '<div class="col-md-3">' +
          '<label class="form-label small text-muted mb-1">Component Name <span class="text-danger">*</span></label>' +
          '<input type="text" name="componentName" class="form-control form-control-sm comp-name" value="' + name + '" required placeholder="e.g. HRA">' +
        '</div>' +
        '<div class="col-md-2">' +
          '<label class="form-label small text-muted mb-1">Type</label>' +
          '<select name="componentType" class="form-select form-select-sm comp-type" onchange="updateLivePreview()">' +
            '<option value="EARNING" ' + (type === 'EARNING' ? 'selected' : '') + '>Earning (+)</option>' +
            '<option value="DEDUCTION" ' + (type === 'DEDUCTION' ? 'selected' : '') + '>Deduction (-)</option>' +
          '</select>' +
        '</div>' +
        '<div class="col-md-2">' +
          '<label class="form-label small text-muted mb-1">Calculation</label>' +
          '<select name="calculationType" class="form-select form-select-sm comp-calc" onchange="updateLivePreview()">' +
            '<option value="FIXED" ' + (calc === 'FIXED' ? 'selected' : '') + '>Fixed (₹)</option>' +
            '<option value="PERCENTAGE" ' + (calc === 'PERCENTAGE' ? 'selected' : '') + '>% of Basic</option>' +
          '</select>' +
        '</div>' +
        '<div class="col-md-2">' +
          '<label class="form-label small text-muted mb-1">Amount / % <span class="text-danger">*</span></label>' +
          '<input type="number" step="0.01" min="0" name="componentAmount" class="form-control form-control-sm comp-amt" value="' + amt + '" required oninput="updateLivePreview()">' +
        '</div>' +
        '<div class="col-md-2">' +
          '<label class="form-label small text-muted mb-1">Description</label>' +
          '<input type="text" name="componentDescription" class="form-control form-control-sm comp-desc" value="' + desc + '" placeholder="Optional notes">' +
        '</div>' +
        '<div class="col-md-1 text-end pt-3">' +
          '<button type="button" class="btn btn-outline-danger btn-sm border-0 rounded-circle" onclick="removeComponentRow(this)" title="Remove" style="width: 28px; height: 28px; padding: 0;">' +
            '<i class="bi bi-trash fs-6"></i>' +
          '</button>' +
        '</div>' +
      '</div>';
    container.appendChild(div);
    updateLivePreview();
  }

  function quickAdd(name, type, calc, amt, desc) {
    addComponentRow(type, name, calc, amt, desc);
  }

  function removeComponentRow(btn) {
    const row = btn.closest('.component-row');
    row.remove();
    const container = document.getElementById('componentsContainer');
    if (container.querySelectorAll('.component-row').length === 0) {
      document.getElementById('emptyComponentsMsg').classList.remove('d-none');
    }
    updateLivePreview();
  }

  function updateLivePreview() {
    const basic = parseFloat(document.getElementById('basicSalaryInput').value) || 0;
    let totalEarn = 0;
    let totalDed = 0;

    const rows = document.querySelectorAll('.component-row');
    rows.forEach(r => {
      const type = r.querySelector('.comp-type').value;
      const calc = r.querySelector('.comp-calc').value;
      const amt = parseFloat(r.querySelector('.comp-amt').value) || 0;

      let compVal = 0;
      if (calc === 'PERCENTAGE') {
        compVal = (basic * amt) / 100.0;
      } else {
        compVal = amt;
      }

      if (type === 'EARNING') {
        totalEarn += compVal;
      } else {
        totalDed += compVal;
      }
    });

    const gross = basic + totalEarn;
    const net = gross - totalDed;

    document.getElementById('previewBasic').textContent = '₹' + basic.toLocaleString('en-IN', {minimumFractionDigits: 2, maximumFractionDigits: 2});
    document.getElementById('previewEarnings').textContent = '+₹' + totalEarn.toLocaleString('en-IN', {minimumFractionDigits: 2, maximumFractionDigits: 2});
    document.getElementById('previewGross').textContent = '₹' + gross.toLocaleString('en-IN', {minimumFractionDigits: 2, maximumFractionDigits: 2});
    document.getElementById('previewDeductions').textContent = '-₹' + totalDed.toLocaleString('en-IN', {minimumFractionDigits: 2, maximumFractionDigits: 2});
    document.getElementById('previewNet').textContent = '₹' + net.toLocaleString('en-IN', {minimumFractionDigits: 2, maximumFractionDigits: 2});

    const warn = document.getElementById('validationWarning');
    const submitBtn = document.getElementById('submitBtn');
    if (net < 0) {
      warn.textContent = 'Warning: Total deductions exceed gross earnings. Net salary cannot be negative.';
      warn.classList.remove('d-none');
      submitBtn.disabled = true;
    } else {
      warn.classList.add('d-none');
      submitBtn.disabled = false;
    }
  }

  document.getElementById('basicSalaryInput').addEventListener('input', updateLivePreview);
  window.addEventListener('DOMContentLoaded', updateLivePreview);
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