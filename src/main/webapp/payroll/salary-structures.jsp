<%@ page contentType="text/html;charset=UTF-8" language="java" isELIgnored="true" %>
<%@ page import="java.util.List, java.math.BigDecimal, com.smartoffice.model.SalaryStructure, com.smartoffice.model.SalaryComponent, com.smartoffice.util.HtmlUtil, com.smartoffice.util.PayrollRules, model.User" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login.html");
        return;
    }
    if (!currentUser.isHr()) {
        response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access Denied: Only HR administrators can manage salary structures.");
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

    List<SalaryStructure> structures = (List<SalaryStructure>) request.getAttribute("structures");

    String successMessage = (String) session.getAttribute("successMessage");
    if (successMessage != null) session.removeAttribute("successMessage");
    String errorMessage = (String) session.getAttribute("errorMessage");
    if (errorMessage != null) session.removeAttribute("errorMessage");

    int totalCount = structures != null ? structures.size() : 0;
    BigDecimal totalNetCommitment = BigDecimal.ZERO;
    BigDecimal totalAllowancesCommitment = BigDecimal.ZERO;
    BigDecimal totalBasicCommitment = BigDecimal.ZERO;
    if (structures != null) {
        for (SalaryStructure s : structures) {
            BigDecimal b = s.getBasicSalary() != null ? s.getBasicSalary() : BigDecimal.ZERO;
            BigDecimal earn = s.calculateTotalEarnings();
            BigDecimal net = s.calculateNetSalary();
            totalBasicCommitment = totalBasicCommitment.add(b);
            totalAllowancesCommitment = totalAllowancesCommitment.add(earn.subtract(b));
            totalNetCommitment = totalNetCommitment.add(net);
        }
    }
    BigDecimal avgNet = totalCount > 0 ? totalNetCommitment.divide(BigDecimal.valueOf(totalCount), 2, java.math.RoundingMode.HALF_UP) : BigDecimal.ZERO;
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>WorkPulse — Salary Structures</title>
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
      --amber-50: #fffbeb;
      --amber-border: #fde68a;
      --amber-text: #92400e;
      --rose-500: #f43f5e;
      --rose-600: #e11d48;
      --rose-700: #be123c;
      --rose-50: #fef2f2;
      --rose-border: #fecaca;
      --rose-text: #991b1b;
      --indigo-500: #6366f1;
      --indigo-50: #eef2ff;
      --indigo-border: #c7d2fe;
      --indigo-text: #4338ca;
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

    /* App Shell & Vertical Sidebar Layout (Identical to Report Hub) */
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
    .logo-box svg { filter: drop-shadow(0 1px 2px rgba(0,0,0,0.15)); }
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

    /* Flash Alerts */
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
    .alert-banner-success {
      background: var(--emerald-50);
      border: 1px solid var(--emerald-border);
      color: var(--emerald-text);
    }
    .alert-banner-danger {
      background: var(--rose-50);
      border: 1px solid var(--rose-border);
      color: var(--rose-text);
    }
    .alert-close {
      background: transparent;
      border: none;
      cursor: pointer;
      font-size: 16px;
      color: inherit;
      opacity: 0.7;
    }
    .alert-close:hover { opacity: 1; }

    /* Page Header Toolbar */
    .page-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      margin-bottom: 22px;
      flex-wrap: wrap;
    }
    .header-left {
      display: flex;
      flex-direction: column;
      gap: 3px;
    }
    .page-title {
      font-size: 22px;
      font-weight: 800;
      color: var(--slate-900);
      letter-spacing: -0.01em;
    }
    .page-subtitle {
      font-size: 13.5px;
      color: var(--slate-500);
    }
    .header-toolbar {
      display: flex;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
    }

    /* Search Box */
    .search-box {
      position: relative;
      display: flex;
      align-items: center;
      width: 280px;
    }
    .search-box svg {
      position: absolute;
      left: 12px;
      color: var(--slate-400);
      pointer-events: none;
      width: 16px;
      height: 16px;
    }
    .search-box input {
      width: 100%;
      padding: 8.5px 12px 8.5px 36px;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-sm);
      font-size: 13px;
      font-family: inherit;
      color: var(--slate-800);
      background: #ffffff;
      transition: all 0.15s ease;
    }
    .search-box input:focus {
      outline: none;
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
    }

    /* Primary Action Button */
    .btn-primary-action {
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
    .btn-primary-action:hover {
      background: var(--primary-dark);
      border-color: var(--primary-dark);
      box-shadow: 0 4px 10px rgba(37, 99, 235, 0.25);
    }
    .btn-primary-action svg { width: 15px; height: 15px; }

    /* KPI Summary Cards Grid */
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
    .stat-label { font-size: 11.5px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em; color: var(--slate-400); }
    .stat-val { font-size: 20px; font-weight: 800; color: var(--slate-900); }
    .stat-sub { font-size: 11.5px; color: var(--slate-500); }

    /* Table Card */
    .table-card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-lg);
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
      overflow: hidden;
    }
    .table-responsive {
      overflow-x: auto;
      width: 100%;
    }
    .payroll-table {
      width: 100%;
      border-collapse: separate;
      border-spacing: 0;
      font-size: 13.5px;
    }
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
      padding: 14px 18px;
      border-bottom: 1px solid var(--slate-100);
      vertical-align: middle;
      color: var(--slate-700);
      background: #ffffff;
      transition: background-color 0.15s ease;
    }
    .payroll-table tbody tr:hover td {
      background-color: #f8fafc;
    }

    /* Employee Cell: strictly prevents wrapping & aligns ID */
    .emp-user-cell {
      display: flex;
      align-items: center;
      gap: 12px;
      white-space: nowrap;
    }
    .emp-avatar {
      width: 36px;
      height: 36px;
      border-radius: 50%;
      background: var(--brand-gradient);
      color: #ffffff;
      font-size: 13px;
      font-weight: 700;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      box-shadow: 0 2px 4px rgba(37, 99, 235, 0.2);
    }
    .emp-meta { display: flex; flex-direction: column; gap: 1px; }
    .emp-name {
      font-weight: 700;
      color: var(--slate-900);
      font-size: 13.5px;
      white-space: nowrap;
    }
    .emp-id-code {
      font-family: monospace;
      font-size: 11.5px;
      color: var(--slate-400);
      font-weight: 600;
    }

    /* Tags & Badges */
    .dept-tag {
      display: inline-block;
      font-size: 11.5px;
      font-weight: 600;
      padding: 3px 9px;
      border-radius: 4px;
      background: var(--slate-100);
      color: var(--slate-700);
      border: 1px solid var(--slate-200);
      white-space: nowrap;
    }
    .period-badge {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      font-size: 11.5px;
      font-weight: 600;
      padding: 3px 8px;
      border-radius: 6px;
      background: var(--slate-100);
      color: var(--slate-700);
      border: 1px solid var(--slate-200);
      white-space: nowrap;
    }
    .period-badge svg { color: var(--primary); }

    /* Currency Values */
    .num-val {
      font-family: 'Plus Jakarta Sans', monospace;
      font-weight: 600;
      white-space: nowrap;
    }
    .val-basic { color: var(--slate-800); }
    .val-allowance { color: var(--emerald-600); font-weight: 600; }
    .val-deduction { color: var(--rose-600); font-weight: 600; }
    .val-net {
      color: var(--emerald-700);
      font-weight: 800;
      background: var(--emerald-50);
      border: 1px solid var(--emerald-border);
      padding: 4px 10px;
      border-radius: 6px;
      display: inline-block;
    }

    /* Components Breakdown Summary Pill - Solves Clutter */
    .btn-breakdown-pill {
      display: inline-flex;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
      padding: 5px 10px;
      border-radius: 20px;
      background: #ffffff;
      border: 1px solid var(--slate-200);
      cursor: pointer;
      text-decoration: none;
      transition: all 0.15s ease;
      font-size: 12px;
      white-space: nowrap;
      min-width: 175px;
    }
    .btn-breakdown-pill:hover {
      background: var(--primary-light);
      border-color: var(--primary-border);
      color: var(--primary-dark);
      transform: translateY(-1px);
    }
    .breakdown-counts {
      display: flex;
      align-items: center;
      gap: 5px;
      font-weight: 600;
    }
    .count-allow { color: var(--emerald-600); }
    .count-ded { color: var(--rose-600); }
    .breakdown-action-label {
      font-size: 11px;
      font-weight: 700;
      color: var(--primary);
      display: inline-flex;
      align-items: center;
      gap: 2px;
    }

    /* Action Buttons */
    .btn-edit-action {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      padding: 6px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 700;
      color: var(--primary);
      background: var(--primary-light);
      border: 1px solid var(--primary-border);
      text-decoration: none;
      transition: all 0.15s ease;
      white-space: nowrap;
    }
    .btn-edit-action:hover {
      background: var(--primary);
      color: #ffffff;
      border-color: var(--primary);
    }
    .btn-edit-action svg { width: 13px; height: 13px; }

    /* Empty State */
    .empty-state {
      padding: 60px 24px;
      text-align: center;
    }
    .empty-icon {
      width: 54px;
      height: 54px;
      border-radius: 50%;
      background: var(--slate-100);
      color: var(--slate-400);
      display: inline-flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 14px;
    }

    /* Interactive Breakdown Modal */
    .modal-backdrop-custom {
      display: none;
      position: fixed;
      top: 0;
      left: 0;
      width: 100vw;
      height: 100vh;
      background: rgba(15, 23, 42, 0.45);
      backdrop-filter: blur(3px);
      z-index: 1000;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .modal-backdrop-custom.show {
      display: flex;
    }
    .modal-card {
      background: #ffffff;
      border-radius: var(--radius-lg);
      border: 1px solid var(--slate-200);
      box-shadow: 0 20px 40px rgba(15, 23, 42, 0.15);
      width: 100%;
      max-width: 680px;
      overflow: hidden;
      animation: modalSlide 0.2s cubic-bezier(0.16, 1, 0.3, 1);
    }
    @keyframes modalSlide {
      from { transform: translateY(16px); opacity: 0; }
      to { transform: translateY(0); opacity: 1; }
    }
    .modal-header-custom {
      padding: 20px 24px;
      background: #ffffff;
      border-bottom: 1px solid var(--slate-200);
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 14px;
    }
    .modal-title-custom {
      font-size: 16px;
      font-weight: 800;
      color: var(--slate-900);
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .modal-close-btn {
      width: 32px;
      height: 32px;
      border-radius: 8px;
      border: 1px solid var(--slate-200);
      background: #ffffff;
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--slate-500);
      cursor: pointer;
      font-size: 18px;
      transition: all 0.15s ease;
    }
    .modal-close-btn:hover {
      background: var(--slate-100);
      color: var(--slate-900);
    }
    .modal-body-custom {
      padding: 24px;
      max-height: 70vh;
      overflow-y: auto;
    }
    .modal-split-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 20px;
      margin-bottom: 20px;
    }
    @media (max-width: 640px) {
      .modal-split-grid { grid-template-columns: 1fr; }
    }
    .comp-col-card {
      background: var(--slate-50);
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-md);
      padding: 16px;
    }
    .comp-col-header {
      font-size: 12px;
      font-weight: 800;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      margin-bottom: 12px;
      padding-bottom: 8px;
      border-bottom: 1px solid var(--slate-200);
      display: flex;
      align-items: center;
      justify-content: space-between;
    }
    .comp-item-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
      padding: 7px 0;
      border-bottom: 1px dashed var(--slate-200);
      font-size: 13px;
    }
    .comp-item-row:last-child { border-bottom: none; }
    .comp-name-box { display: flex; flex-direction: column; gap: 1px; }
    .comp-title { font-weight: 600; color: var(--slate-800); }
    .comp-rule-tag { font-size: 11px; color: var(--slate-400); }
    .comp-val-text { font-weight: 700; white-space: nowrap; }

    .modal-net-banner {
      background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%);
      border: 1px solid var(--emerald-border);
      border-radius: var(--radius-md);
      padding: 16px 20px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
    }
    .modal-footer-custom {
      padding: 16px 24px;
      background: var(--slate-50);
      border-top: 1px solid var(--slate-200);
      display: flex;
      align-items: center;
      justify-content: flex-end;
      gap: 10px;
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
  <!-- Consistent WorkPulse Left Sidebar (Reused from Report Hub) -->
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
      <h1 class="topbar-title">Salary Structures &amp; Compensation</h1>
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

      <!-- Page Header & Action Toolbar -->
      <div class="page-header">
        <div class="header-left">
          <h1 class="page-title">Salary Structures</h1>
          <p class="page-subtitle">Configure baseline pay, recurring allowances (HRA, DA, Special), and statutory deductions with immutable audit trails.</p>
        </div>
        <div class="header-toolbar">
          <div class="search-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
            <input type="text" id="structureSearch" placeholder="Search employee, ID, dept...">
          </div>
          <a href="<%= ctx %>/payroll/salary-structure-form" class="btn-primary-action">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
            Configure Structure
          </a>
        </div>
      </div>

      <!-- Quick Executive Summary Cards -->
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-icon" style="background:#eff6ff; color:#2563eb;">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
          </div>
          <div class="stat-body">
            <span class="stat-label">Active Structures</span>
            <span class="stat-val"><%= totalCount %></span>
            <span class="stat-sub">Employees with active rules</span>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon" style="background:#ecfdf5; color:#059669;">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><line x1="12" y1="1" x2="12" y2="23"></line><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path></svg>
          </div>
          <div class="stat-body">
            <span class="stat-label">Total Net Pay Commitment</span>
            <span class="stat-val">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.0f", totalNetCommitment) %></span>
            <span class="stat-sub">Monthly take-home sum</span>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon" style="background:#fffbeb; color:#d97706;">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="2" y="4" width="20" height="16" rx="2"></rect><line x1="2" y1="10" x2="22" y2="10"></line></svg>
          </div>
          <div class="stat-body">
            <span class="stat-label">Total Allowances</span>
            <span class="stat-val">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.0f", totalAllowancesCommitment) %></span>
            <span class="stat-sub">HRA, DA, Special</span>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon" style="background:#f5f3ff; color:#7c3aed;">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M21.21 15.89A10 10 0 1 1 8 2.83"></path><path d="M22 12A10 10 0 0 0 12 2v10z"></path></svg>
          </div>
          <div class="stat-body">
            <span class="stat-label">Average Net Monthly Pay</span>
            <span class="stat-val">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.0f", avgNet) %></span>
            <span class="stat-sub">Across configured team</span>
          </div>
        </div>
      </div>

      <!-- Salary Structures Table Card -->
      <div class="table-card">
        <div class="table-responsive">
          <table class="payroll-table" id="structuresTable">
            <thead>
              <tr>
                <th style="min-width: 220px;">Employee</th>
                <th style="min-width: 120px;">Department</th>
                <th class="text-end" style="min-width: 120px;">Basic Salary</th>
                <th class="text-end" style="min-width: 120px;">Allowances</th>
                <th class="text-end" style="min-width: 120px;">Deductions</th>
                <th class="text-end" style="min-width: 140px;">Net Monthly Pay</th>
                <th style="min-width: 170px;">Effective Period</th>
                <th style="min-width: 210px;">Components Breakdown</th>
                <th class="text-end" style="min-width: 90px;">Action</th>
              </tr>
            </thead>
            <tbody>
              <% if (structures == null || structures.isEmpty()) { %>
                <tr>
                  <td colspan="9">
                    <div class="empty-state">
                      <div class="empty-icon">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
                      </div>
                      <h3 style="font-size: 15px; font-weight: 700; color: var(--slate-800); margin-bottom: 4px;">No salary structures configured yet</h3>
                      <p style="font-size: 13px; color: var(--slate-500); margin-bottom: 16px;">Configure baseline salary structures for your employees to start processing monthly payroll.</p>
                      <a href="<%= ctx %>/payroll/salary-structure-form" class="btn-primary-action" style="margin: 0 auto;">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
                        Configure First Structure
                      </a>
                    </div>
                  </td>
                </tr>
              <% } else {
                   for (SalaryStructure s : structures) {
                     BigDecimal totalEarn = s.calculateTotalEarnings();
                     BigDecimal totalDed = s.calculateTotalDeductions();
                     BigDecimal net = s.calculateNetSalary();
                     BigDecimal allowanceSum = totalEarn.subtract(s.getBasicSalary() != null ? s.getBasicSalary() : BigDecimal.ZERO);

                     int earnCount = 0;
                     int dedCount = 0;
                     if (s.getComponents() != null) {
                       for (SalaryComponent c : s.getComponents()) {
                         if (c.isEarning()) earnCount++;
                         else dedCount++;
                       }
                     }

                     String initials = "EM";
                     if (s.getEmployeeName() != null && !s.getEmployeeName().trim().isEmpty()) {
                         String[] parts = s.getEmployeeName().trim().split("\\s+");
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
                      <div class="emp-meta">
                        <span class="emp-name"><%= HtmlUtil.esc(s.getEmployeeName()) %></span>
                        <span class="emp-id-code"><%= HtmlUtil.esc(s.getEmployeeId()) %></span>
                      </div>
                    </div>
                  </td>
                  <td>
                    <span class="dept-tag"><%= HtmlUtil.esc(s.getDepartment()) %></span>
                  </td>
                  <td class="text-end">
                    <span class="num-val val-basic">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", s.getBasicSalary() != null ? s.getBasicSalary() : BigDecimal.ZERO) %></span>
                  </td>
                  <td class="text-end">
                    <span class="num-val val-allowance">+&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", allowanceSum) %></span>
                  </td>
                  <td class="text-end">
                    <span class="num-val val-deduction">-&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", totalDed) %></span>
                  </td>
                  <td class="text-end">
                    <span class="num-val val-net">&#x20b9;<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", net) %></span>
                  </td>
                  <td>
                    <span class="period-badge">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
                      <%= s.getEffectiveFrom() %> &rarr; <%= s.getEffectiveTo() != null ? s.getEffectiveTo().toString() : "Present" %>
                    </span>
                  </td>
                  <td>
                    <!-- Clean Breakdown Summary Pill: Replaces clumsy badge clutter -->
                    <button type="button" class="btn-breakdown-pill" onclick="openBreakdownModal('<%= s.getId() %>')" title="View detailed earnings and deductions breakdown">
                      <span class="breakdown-counts">
                        <span class="count-allow"><%= earnCount %> allow.</span>
                        <span style="color:var(--slate-300);">&bull;</span>
                        <span class="count-ded"><%= dedCount %> ded.</span>
                      </span>
                      <span class="breakdown-action-label">
                        <span>Details</span>
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 18 15 12 9 6"></polyline></svg>
                      </span>
                    </button>
                  </td>
                  <td class="text-end">
                    <a href="<%= ctx %>/payroll/salary-structure-form?id=<%= s.getId() %>" class="btn-edit-action" title="Revise structure">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
                      <span>Edit</span>
                    </a>
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

<!-- Interactive Components Breakdown Modal -->
<div class="modal-backdrop-custom" id="breakdownModal">
  <div class="modal-card">
    <div class="modal-header-custom">
      <div class="modal-title-custom">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><line x1="12" y1="1" x2="12" y2="23"></line><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path></svg>
        <span id="modalEmpTitle">Compensation Breakdown</span>
      </div>
      <button type="button" class="modal-close-btn" onclick="closeBreakdownModal()">&times;</button>
    </div>
    <div class="modal-body-custom">
      <!-- Employee Meta Pill -->
      <div style="background:var(--slate-50); border:1px solid var(--slate-200); border-radius:8px; padding:10px 14px; margin-bottom:18px; display:flex; align-items:center; justify-content:space-between; gap:10px; font-size:12.5px; flex-wrap:wrap;">
        <div>
          <span style="color:var(--slate-400); font-weight:600;">Employee: </span>
          <strong id="modalEmpMeta" style="color:var(--slate-900);">--</strong>
        </div>
        <div>
          <span style="color:var(--slate-400); font-weight:600;">Department: </span>
          <span id="modalDeptMeta" class="dept-tag" style="margin-left:4px;">--</span>
        </div>
        <div>
          <span style="color:var(--slate-400); font-weight:600;">Effective: </span>
          <span id="modalPeriodMeta" style="font-weight:600; color:var(--slate-700);">--</span>
        </div>
      </div>

      <!-- Split Earnings vs Deductions -->
      <div class="modal-split-grid">
        <!-- Earnings Column -->
        <div class="comp-col-card">
          <div class="comp-col-header" style="color:var(--emerald-700);">
            <span>Earnings &amp; Allowances</span>
            <span id="modalEarnTotal" style="font-weight:800;">&#x20b9;0.00</span>
          </div>
          <div id="modalEarnList">
            <!-- Dynamic items -->
          </div>
        </div>

        <!-- Deductions Column -->
        <div class="comp-col-card">
          <div class="comp-col-header" style="color:var(--rose-700);">
            <span>Statutory Deductions</span>
            <span id="modalDedTotal" style="font-weight:800;">&#x20b9;0.00</span>
          </div>
          <div id="modalDedList">
            <!-- Dynamic items -->
          </div>
        </div>
      </div>

      <!-- Net Monthly Pay Banner -->
      <div class="modal-net-banner">
        <div>
          <div style="font-size:11.5px; font-weight:700; text-transform:uppercase; letter-spacing:0.04em; color:var(--emerald-800);">Net Monthly Take-Home Pay</div>
          <div style="font-size:12px; color:var(--emerald-700); margin-top:2px;">(Gross Earnings minus Total Deductions)</div>
        </div>
        <div id="modalNetTotal" style="font-size:24px; font-weight:800; color:var(--emerald-800);">&#x20b9;0.00</div>
      </div>
    </div>
    <div class="modal-footer-custom">
      <button type="button" class="btn-back-portal" onclick="closeBreakdownModal()">Close</button>
      <a id="modalEditLink" href="#" class="btn-primary-action" style="padding:6.5px 16px;">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
        Edit Structure
      </a>
    </div>
  </div>
</div>

<!-- Embedded Data Store for instant modal rendering -->
<script>
const structureStore = {
<% if (structures != null) {
     for (SalaryStructure s : structures) {
       BigDecimal totalEarn = s.calculateTotalEarnings();
       BigDecimal totalDed = s.calculateTotalDeductions();
       BigDecimal net = s.calculateNetSalary();
       BigDecimal basic = s.getBasicSalary() != null ? s.getBasicSalary() : BigDecimal.ZERO;
%>
  "<%= s.getId() %>": {
    id: "<%= s.getId() %>",
    employeeName: "<%= HtmlUtil.esc(s.getEmployeeName()) %>",
    employeeId: "<%= HtmlUtil.esc(s.getEmployeeId()) %>",
    department: "<%= HtmlUtil.esc(s.getDepartment()) %>",
    basicSalary: "<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", basic) %>",
    grossTotal: "<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", totalEarn) %>",
    dedTotal: "<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", totalDed) %>",
    netSalary: "<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", net) %>",
    period: "<%= s.getEffectiveFrom() %> &rarr; <%= s.getEffectiveTo() != null ? s.getEffectiveTo().toString() : "Present" %>",
    components: [
      <% if (s.getComponents() != null) {
           for (SalaryComponent c : s.getComponents()) {
             BigDecimal compAmount = c.isPercentage()
                 ? (basic != null ? basic : BigDecimal.ZERO).multiply(c.getAmount() != null ? c.getAmount() : BigDecimal.ZERO).divide(BigDecimal.valueOf(100), 2, java.math.RoundingMode.HALF_UP)
                 : (c.getAmount() != null ? c.getAmount() : BigDecimal.ZERO);
      %>
      {
        name: "<%= HtmlUtil.esc(c.getComponentName()) %>",
        type: "<%= c.getComponentType() %>",
        isPercentage: <%= c.isPercentage() %>,
        rate: "<%= c.getAmount() %>",
        amountStr: "<%= String.format(java.util.Locale.forLanguageTag("en-IN"), "%,.2f", compAmount) %>",
        desc: "<%= HtmlUtil.esc(c.getDescription() != null ? c.getDescription() : "") %>"
      },
      <%   }
         } %>
    ]
  },
<%   }
   } %>
};

function openBreakdownModal(id) {
  const data = structureStore[id];
  if (!data) return;

  document.getElementById('modalEmpTitle').textContent = data.employeeName + " — Salary Breakdown";
  document.getElementById('modalEmpMeta').textContent = data.employeeName + " (" + data.employeeId + ")";
  document.getElementById('modalDeptMeta').textContent = data.department;
  document.getElementById('modalPeriodMeta').innerHTML = data.period;
  document.getElementById('modalEarnTotal').innerHTML = "&#x20b9;" + data.grossTotal;
  document.getElementById('modalDedTotal').innerHTML = "&#x20b9;" + data.dedTotal;
  document.getElementById('modalNetTotal').innerHTML = "&#x20b9;" + data.netSalary;
  document.getElementById('modalEditLink').href = "<%= ctx %>/payroll/salary-structure-form?id=" + data.id;

  // Render Earnings List: Basic first, then allowances
  const earnList = document.getElementById('modalEarnList');
  let earnHtml = `
    <div class="comp-item-row">
      <div class="comp-name-box">
        <span class="comp-title">Basic Salary</span>
        <span class="comp-rule-tag">Base contractual wage</span>
      </div>
      <span class="comp-val-text" style="color:var(--slate-900);">&#x20b9;` + data.basicSalary + `</span>
    </div>
  `;
  let earnComponents = data.components.filter(c => c.type === 'EARNING');
  if (earnComponents.length === 0) {
    earnHtml += `<div style="font-size:12px; color:var(--slate-400); padding:10px 0; text-align:center;">No additional allowances configured</div>`;
  } else {
    earnComponents.forEach(c => {
      const ruleText = c.isPercentage ? (c.rate + "% of Basic") : "Fixed monthly allowance";
      earnHtml += `
        <div class="comp-item-row">
          <div class="comp-name-box">
            <span class="comp-title">` + c.name + `</span>
            <span class="comp-rule-tag">` + ruleText + `</span>
          </div>
          <span class="comp-val-text" style="color:var(--emerald-600);">+&#x20b9;` + c.amountStr + `</span>
        </div>
      `;
    });
  }
  earnList.innerHTML = earnHtml;

  // Render Deductions List
  const dedList = document.getElementById('modalDedList');
  let dedComponents = data.components.filter(c => c.type === 'DEDUCTION');
  let dedHtml = '';
  if (dedComponents.length === 0) {
    dedHtml = `<div style="font-size:12px; color:var(--slate-400); padding:14px 0; text-align:center;">No recurring deductions configured</div>`;
  } else {
    dedComponents.forEach(c => {
      const ruleText = c.isPercentage ? (c.rate + "% of Basic") : "Fixed statutory deduction";
      dedHtml += `
        <div class="comp-item-row">
          <div class="comp-name-box">
            <span class="comp-title">` + c.name + `</span>
            <span class="comp-rule-tag">` + ruleText + `</span>
          </div>
          <span class="comp-val-text" style="color:var(--rose-600);">-&#x20b9;` + c.amountStr + `</span>
        </div>
      `;
    });
  }
  dedList.innerHTML = dedHtml;

  document.getElementById('breakdownModal').classList.add('show');
}

function closeBreakdownModal() {
  document.getElementById('breakdownModal').classList.remove('show');
}

// Close modal on click outside card
document.getElementById('breakdownModal').addEventListener('click', function(e) {
  if (e.target === this) closeBreakdownModal();
});

// Close modal on Escape key
document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') closeBreakdownModal();
});

// Instant Search Filtering
document.getElementById('structureSearch')?.addEventListener('input', function() {
  const query = this.value.toLowerCase().trim();
  const rows = document.querySelectorAll('#structuresTable tbody tr');
  rows.forEach(row => {
    const text = row.textContent.toLowerCase();
    row.style.display = text.includes(query) ? '' : 'none';
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