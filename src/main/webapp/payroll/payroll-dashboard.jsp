<%@ page contentType="text/html;charset=UTF-8" language="java" isELIgnored="true" %>
<%@ page import="java.util.List, java.math.BigDecimal, com.smartoffice.model.Payroll, model.User, com.smartoffice.util.HtmlUtil, com.smartoffice.util.PayrollRules, java.time.Month, java.time.format.TextStyle, java.util.Locale" %>
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

    Integer totalStructures = (Integer) request.getAttribute("totalStructures");
    if (totalStructures == null) totalStructures = 0;

    List<Payroll> monthlyPayrolls = (List<Payroll>) request.getAttribute("monthlyPayrolls");
    BigDecimal totalGross = (BigDecimal) request.getAttribute("totalGross");
    if (totalGross == null) totalGross = BigDecimal.ZERO;
    BigDecimal totalDeductions = (BigDecimal) request.getAttribute("totalDeductions");
    if (totalDeductions == null) totalDeductions = BigDecimal.ZERO;
    BigDecimal totalNet = (BigDecimal) request.getAttribute("totalNet");
    if (totalNet == null) totalNet = BigDecimal.ZERO;

    Integer paidCount = (Integer) request.getAttribute("paidCount");
    if (paidCount == null) paidCount = 0;
    Integer pendingCount = (Integer) request.getAttribute("pendingCount");
    if (pendingCount == null) pendingCount = 0;
    Integer draftCount = (Integer) request.getAttribute("draftCount");
    if (draftCount == null) draftCount = 0;
    Integer cancelledCount = (Integer) request.getAttribute("cancelledCount");
    if (cancelledCount == null) cancelledCount = 0;

    Integer curMonth = (Integer) request.getAttribute("currentMonth");
    Integer curYear = (Integer) request.getAttribute("currentYear");
    if (curMonth == null) curMonth = java.time.LocalDate.now().getMonthValue();
    if (curYear == null) curYear = java.time.LocalDate.now().getYear();

    String monthName = Month.of(curMonth).getDisplayName(TextStyle.FULL, Locale.ENGLISH);

    String successMessage = (String) session.getAttribute("successMessage");
    if (successMessage != null) session.removeAttribute("successMessage");
    String errorMessage = (String) session.getAttribute("errorMessage");
    if (errorMessage != null) session.removeAttribute("errorMessage");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>WorkPulse — Payroll Hub</title>
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
      margin-bottom: 22px;
      flex-wrap: wrap;
    }
    .header-left { display: flex; flex-direction: column; gap: 3px; }
    .page-title { font-size: 22px; font-weight: 800; color: var(--slate-900); letter-spacing: -0.01em; }
    .page-subtitle { font-size: 13.5px; color: var(--slate-500); }
    .header-toolbar { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }

    .btn-action-primary {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      padding: 8.5px 18px;
      border-radius: var(--radius-sm);
      font-size: 13px;
      font-weight: 700;
      color: #ffffff;
      background: var(--primary);
      border: 1px solid var(--primary);
      text-decoration: none;
      box-shadow: 0 1px 3px rgba(37, 99, 235, 0.2);
      transition: all 0.15s ease;
      white-space: nowrap;
    }
    .btn-action-primary:hover { background: var(--primary-dark); border-color: var(--primary-dark); }
    .btn-action-secondary {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      padding: 8.5px 16px;
      border-radius: var(--radius-sm);
      font-size: 13px;
      font-weight: 600;
      color: var(--slate-700);
      background: #ffffff;
      border: 1px solid var(--slate-200);
      text-decoration: none;
      transition: all 0.15s ease;
      white-space: nowrap;
    }
    .btn-action-secondary:hover { background: var(--slate-100); color: var(--slate-900); }

    /* Stats KPI Grid */
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 16px;
      margin-bottom: 20px;
    }
    .stat-card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-md);
      padding: 18px 20px;
      display: flex;
      align-items: center;
      gap: 16px;
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.03);
    }
    .stat-icon {
      width: 48px;
      height: 48px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }
    .stat-body { display: flex; flex-direction: column; gap: 2px; }
    .stat-label { font-size: 11.5px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em; color: var(--slate-400); }
    .stat-val { font-size: 22px; font-weight: 800; color: var(--slate-900); }
    .stat-sub { font-size: 11.5px; color: var(--slate-500); }

    /* Pipeline Status Ribbon */
    .status-ribbon {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-md);
      padding: 14px 20px;
      margin-bottom: 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      flex-wrap: wrap;
    }
    .status-ribbon-title {
      font-size: 12.5px;
      font-weight: 700;
      color: var(--slate-800);
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .status-chips-wrap {
      display: flex;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
    }
    .status-count-chip {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      padding: 5px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      border: 1px solid;
    }
    .chip-paid { background: var(--emerald-50); color: var(--emerald-text); border-color: var(--emerald-border); }
    .chip-processed { background: var(--amber-50); color: var(--amber-text); border-color: var(--amber-border); }
    .chip-draft { background: var(--slate-100); color: var(--slate-700); border-color: var(--slate-200); }
    .chip-cancelled { background: var(--rose-50); color: var(--rose-text); border-color: var(--rose-border); }
    .chip-dot { width: 7px; height: 7px; border-radius: 50%; }

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
    .payroll-table { width: 100%; border-collapse: separate; border-spacing: 0; font-size: 13.5px; }
    .payroll-table th {
      background: var(--slate-50);
      padding: 12px 18px;
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
      padding: 13px 18px;
      border-bottom: 1px solid var(--slate-100);
      vertical-align: middle;
      color: var(--slate-700);
      background: #ffffff;
    }
    .payroll-table tbody tr:hover td { background-color: #f8fafc; }

    .emp-user-cell { display: flex; align-items: center; gap: 12px; white-space: nowrap; }
    .emp-avatar {
      width: 34px;
      height: 34px;
      border-radius: 50%;
      background: var(--brand-gradient);
      color: #ffffff;
      font-size: 12.5px;
      font-weight: 700;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }
    .emp-name { font-weight: 700; color: var(--slate-900); font-size: 13.5px; white-space: nowrap; }
    .emp-id-code { font-family: monospace; font-size: 11.5px; color: var(--slate-400); font-weight: 600; }
    .dept-tag { display: inline-block; font-size: 11.5px; font-weight: 600; padding: 3px 8px; border-radius: 4px; background: var(--slate-100); color: var(--slate-700); border: 1px solid var(--slate-200); }

    /* Status Pills */
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      font-size: 11.5px;
      font-weight: 700;
      padding: 3px 9px;
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
      gap: 5px;
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

    .empty-state { padding: 50px 24px; text-align: center; }
    .empty-icon { width: 50px; height: 50px; border-radius: 50%; background: var(--slate-100); color: var(--slate-400); display: inline-flex; align-items: center; justify-content: center; margin-bottom: 12px; }
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
        <a href="<%= ctx %>/payroll" class="nav-accordion-item on">
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
      <h1 class="topbar-title">Payroll Management Hub</h1>
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
          <h1 class="page-title">Payroll Overview &amp; Analytics</h1>
          <p class="page-subtitle">Consolidated compensation summary for <strong><%= monthName %> <%= curYear %></strong>, settlement metrics, and quick workflows.</p>
        </div>
        <div class="header-toolbar">
          <a href="<%= ctx %>/payroll/processing?month=<%= curMonth %>&year=<%= curYear %>" class="btn-action-primary">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect x="4" y="2" width="16" height="20" rx="2"></rect><line x1="8" y1="6" x2="16" y2="6"></line><line x1="16" y1="14" x2="16" y2="18"></line><path d="M16 10h.01"></path><path d="M12 10h.01"></path><path d="M8 10h.01"></path><path d="M12 14h.01"></path><path d="M8 14h.01"></path><path d="M12 18h.01"></path><path d="M8 18h.01"></path></svg>
            Process <%= monthName %> Payroll
          </a>
          <a href="<%= ctx %>/payroll/salary-structures" class="btn-action-secondary">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><line x1="4" y1="21" x2="4" y2="14"></line><line x1="4" y1="10" x2="4" y2="3"></line><line x1="12" y1="21" x2="12" y2="12"></line><line x1="12" y1="8" x2="12" y2="3"></line><line x1="20" y1="21" x2="20" y2="16"></line><line x1="20" y1="12" x2="20" y2="3"></line><line x1="1" y1="14" x2="7" y2="14"></line><line x1="9" y1="8" x2="15" y2="8"></line><line x1="17" y1="16" x2="23" y2="16"></line></svg>
            Salary Structures
          </a>
          <a href="<%= ctx %>/payroll/history" class="btn-action-secondary">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
            Historical Archive
          </a>
        </div>
      </div>

      <!-- Financial Metric Cards -->
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-icon" style="background:#ecfdf5; color:#059669;">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><line x1="12" y1="1" x2="12" y2="23"></line><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path></svg>
          </div>
          <div class="stat-body">
            <span class="stat-label">Net Disbursed / Due</span>
            <span class="stat-val">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", totalNet) %></span>
            <span class="stat-sub">For <%= monthName %> <%= curYear %></span>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon" style="background:#eff6ff; color:#2563eb;">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="2" y="4" width="20" height="16" rx="2"></rect><line x1="2" y1="10" x2="22" y2="10"></line></svg>
          </div>
          <div class="stat-body">
            <span class="stat-label">Gross Payroll Earnings</span>
            <span class="stat-val">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", totalGross) %></span>
            <span class="stat-sub">Basic + all allowances</span>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon" style="background:#fffbeb; color:#d97706;">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
          </div>
          <div class="stat-body">
            <span class="stat-label">Total Statutory Deductions</span>
            <span class="stat-val">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", totalDeductions) %></span>
            <span class="stat-sub">PF, PT, TDS &amp; LOP</span>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon" style="background:#f5f3ff; color:#7c3aed;">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
          </div>
          <div class="stat-body">
            <span class="stat-label">Salary Structures</span>
            <span class="stat-val"><%= totalStructures %></span>
            <span class="stat-sub">Active configured profiles</span>
          </div>
        </div>
      </div>

      <!-- Processing Pipeline Status Ribbon -->
      <div class="status-ribbon">
        <div class="status-ribbon-title">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
          <span>Batch Status &bull; <%= monthName %> <%= curYear %></span>
        </div>
        <div class="status-chips-wrap">
          <div class="status-count-chip chip-paid">
            <span class="chip-dot" style="background:#059669;"></span>
            <span>Paid: <strong><%= paidCount %></strong></span>
          </div>
          <div class="status-count-chip chip-processed">
            <span class="chip-dot" style="background:#d97706;"></span>
            <span>Awaiting Settlement: <strong><%= pendingCount %></strong></span>
          </div>
          <div class="status-count-chip chip-draft">
            <span class="chip-dot" style="background:#64748b;"></span>
            <span>Draft Calculations: <strong><%= draftCount %></strong></span>
          </div>
          <% if (cancelledCount > 0) { %>
            <div class="status-count-chip chip-cancelled">
              <span class="chip-dot" style="background:#e11d48;"></span>
              <span>Cancelled: <strong><%= cancelledCount %></strong></span>
            </div>
          <% } %>
        </div>
      </div>

      <!-- Current Period Register Table -->
      <div class="table-card">
        <div class="table-card-header">
          <div class="card-title-text"><%= monthName %> <%= curYear %> Payroll Register</div>
          <div style="font-size:12.5px; color:var(--slate-500);">
            Showing <%= monthlyPayrolls != null ? monthlyPayrolls.size() : 0 %> employee records
          </div>
        </div>
        <div class="table-responsive">
          <table class="payroll-table">
            <thead>
              <tr>
                <th style="min-width: 220px;">Employee</th>
                <th style="min-width: 120px;">Department</th>
                <th class="text-end" style="min-width: 120px;">Gross Pay</th>
                <th class="text-end" style="min-width: 120px;">Deductions</th>
                <th class="text-end" style="min-width: 130px;">Net Payable</th>
                <th style="min-width: 130px;">Status</th>
                <th style="min-width: 150px;">Disbursement</th>
                <th class="text-end" style="min-width: 120px;">Action</th>
              </tr>
            </thead>
            <tbody>
              <% if (monthlyPayrolls == null || monthlyPayrolls.isEmpty()) { %>
                <tr>
                  <td colspan="8">
                    <div class="empty-state">
                      <div class="empty-icon">
                        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="4" y="2" width="16" height="20" rx="2"></rect><line x1="8" y1="6" x2="16" y2="6"></line><line x1="16" y1="14" x2="16" y2="18"></line></svg>
                      </div>
                      <h4 style="font-size: 15px; font-weight: 700; color: var(--slate-800); margin-bottom: 4px;">No payroll generated for <%= monthName %> <%= curYear %></h4>
                      <p style="font-size: 13px; color: var(--slate-500); margin-bottom: 16px;">Initiate automated calculation with attendance reconciliation for this monthly cycle.</p>
                      <a href="<%= ctx %>/payroll/processing?month=<%= curMonth %>&year=<%= curYear %>" class="btn-action-primary" style="margin: 0 auto;">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg>
                        Initiate <%= monthName %> Processing
                      </a>
                    </div>
                  </td>
                </tr>
              <% } else {
                   for (Payroll p : monthlyPayrolls) {
                     String initials = "EM";
                     if (p.getEmployeeName() != null && !p.getEmployeeName().trim().isEmpty()) {
                         String[] parts = p.getEmployeeName().trim().split("\\s+");
                         if (parts.length >= 2) {
                             initials = (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
                         } else {
                             initials = parts[0].substring(0, Math.min(2, parts[0].length())).toUpperCase();
                         }
                     }
                     String st = p.getStatus() != null ? p.getStatus().toUpperCase() : "DRAFT";
                     String stClass = "status-draft";
                     if ("PAID".equals(st)) stClass = "status-paid";
                     else if ("PROCESSED".equals(st)) stClass = "status-processed";
                     else if ("CANCELLED".equals(st)) stClass = "status-cancelled";
              %>
                <tr>
                  <td>
                    <div class="emp-user-cell">
                      <div class="emp-avatar"><%= initials %></div>
                      <div class="emp-meta">
                        <span class="emp-name"><%= HtmlUtil.esc(p.getEmployeeName()) %></span>
                        <span class="emp-id-code"><%= HtmlUtil.esc(p.getEmployeeId()) %></span>
                      </div>
                    </div>
                  </td>
                  <td><span class="dept-tag"><%= HtmlUtil.esc(p.getDepartment()) %></span></td>
                  <td class="text-end"><span class="num-val">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", p.getGrossSalary()) %></span></td>
                  <td class="text-end"><span class="num-val" style="color:var(--rose-600);">-&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", p.getTotalDeductions()) %></span></td>
                  <td class="text-end"><span class="num-val val-net">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", p.getNetSalary()) %></span></td>
                  <td><span class="status-badge <%= stClass %>"><%= st %></span></td>
                  <td>
                    <% if ("PAID".equals(st) && p.getPayment() != null) { %>
                      <div style="font-size:12px; font-weight:600; color:var(--emerald-700);"><%= HtmlUtil.esc(p.getPayment().getPaymentMethod()) %></div>
                      <div style="font-size:11px; color:var(--slate-400);"><%= p.getPayment().getPaymentDate() %></div>
                    <% } else if ("PROCESSED".equals(st)) { %>
                      <span style="font-size:12px; color:var(--amber-700); font-weight:600;">Pending Payment</span>
                    <% } else { %>
                      <span style="font-size:12px; color:var(--slate-400);">--</span>
                    <% } %>
                  </td>
                  <td class="text-end">
                    <div style="display:inline-flex; align-items:center; gap:6px;">
                      <a href="<%= ctx %>/payroll/salary-slip?id=<%= p.getId() %>" class="btn-row-action" title="View Payslip">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line></svg>
                        <span>Slip</span>
                      </a>
                      <% if ("PROCESSED".equals(st) && isHr) { %>
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