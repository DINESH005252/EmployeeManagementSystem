<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, model.Report, model.User" %>
<%
    User currentUser = (User) session.getAttribute("user");
    List<Report.EmployeeItem> employees = (List<Report.EmployeeItem>) request.getAttribute("employees");
    List<String> departments = (List<String>) request.getAttribute("departments");
    List<Report.ManagerItem> managers = (List<Report.ManagerItem>) request.getAttribute("managers");

    Boolean showTeamViewAttr = (Boolean) request.getAttribute("showTeamView");
    boolean showTeamView = showTeamViewAttr != null && showTeamViewAttr;

    String paramSearch = (String) request.getAttribute("paramSearch");
    String paramDept = (String) request.getAttribute("paramDept");
    String paramStatus = (String) request.getAttribute("paramStatus");
    String paramManager = (String) request.getAttribute("paramManager");
    if (paramManager == null) paramManager = "";

    String ctx = request.getContextPath();
    boolean isManager = currentUser != null && currentUser.isManager();
    boolean isHr = currentUser != null && currentUser.isHr();
    boolean isEmployee = currentUser != null && currentUser.isEmployee();
    String portalUrl = ctx + (isHr ? "/hr.html" : (isManager ? "/manager.html" : "/employee.html"));
    String portalLabel = isHr ? "Back to HR Portal" : (isManager ? "Back to Manager Portal" : "Back to Employee Portal");
    String userInitial = (currentUser != null && currentUser.getUsername() != null && !currentUser.getUsername().isEmpty()) ? currentUser.getUsername().substring(0, 1).toUpperCase() : "U";
    String userName = (currentUser != null && currentUser.getUsername() != null) ? currentUser.getUsername() : "User";
    String roleLabel = isHr ? "HR Admin" : (isManager ? "Manager" : "Employee");
    String reportsMenuLabel = isEmployee ? "My Reports" : "Reports Hub";

    int totalEmps = employees != null ? employees.size() : 0;
    int managerCount = managers != null ? managers.size() : 0;

    // Find selected manager details if filtered
    Report.ManagerItem selectedManager = null;
    if (managers != null && !paramManager.isEmpty() && !"ALL".equalsIgnoreCase(paramManager)) {
        for (Report.ManagerItem m : managers) {
            if (m.getManagerId().equalsIgnoreCase(paramManager)) {
                selectedManager = m;
                break;
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>WorkPulse - Reports &amp; Analytics Hub</title>
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
      --emerald-600: #059669;
      --emerald-50: #ecfdf5;
      --emerald-border: #a7f3d0;
      --emerald-text: #065f46;
      --amber-500: #f59e0b;
      --amber-700: #92400e;
      --amber-50: #fffbeb;
      --amber-border: #fde68a;
      --rose-500: #f43f5e;
      --rose-50: #fef2f2;
      --rose-border: #fecaca;
      --rose-text: #991b1b;
      --indigo-500: #6366f1;
      --indigo-50: #eef2ff;
      --indigo-border: #c7d2fe;
      --indigo-text: #4338ca;
      --purple-50: #f5f3ff;
      --purple-border: #ddd6fe;
      --purple-text: #7c3aed;
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
    .sidebar::-webkit-scrollbar {
      width: 4px;
    }
    .sidebar::-webkit-scrollbar-thumb {
      background: var(--slate-200);
      border-radius: 4px;
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
    .logo-box svg {
      filter: drop-shadow(0 1px 2px rgba(0,0,0,0.15));
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

    /* Employee Personal Reports Grid */
    .employee-reports-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
      gap: 20px;
      margin-bottom: 32px;
    }
    .emp-report-box {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-lg);
      padding: 24px;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      gap: 20px;
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
      transition: all 0.2s ease;
    }
    .emp-report-box:hover {
      border-color: var(--primary);
      transform: translateY(-2px);
      box-shadow: 0 10px 24px rgba(15, 23, 42, 0.08);
    }
    .emp-report-icon-banner {
      width: 50px;
      height: 50px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      border: 1px solid;
    }
    .emp-report-title {
      font-size: 16px;
      font-weight: 800;
      color: var(--slate-900);
      margin-bottom: 6px;
    }
    .emp-report-desc {
      font-size: 13px;
      color: var(--slate-500);
      line-height: 1.5;
    }
    .btn-emp-report {
      display: inline-flex;
      align-items: center;
      justify-content: space-between;
      width: 100%;
      padding: 10px 16px;
      border-radius: var(--radius-sm);
      font-size: 13.5px;
      font-weight: 700;
      text-decoration: none;
      transition: all 0.15s ease;
    }
    .btn-emp-report:hover {
      filter: brightness(0.92);
      transform: translateX(2px);
    }
    .btn-emp-report svg {
      width: 15px;
      height: 15px;
    }

    /* Content Area */
    .content-wrap {
      padding: 24px 28px 40px;
      max-width: 1280px;
      width: 100%;
      margin: 0 auto;
    }

    /* Page Header */
    .page-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      margin-bottom: 24px;
    }
    .header-left {
      display: flex;
      flex-direction: column;
      gap: 4px;
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
    .role-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      font-size: 12px;
      font-weight: 700;
      padding: 6px 12px;
      border-radius: 20px;
      background: #ffffff;
      border: 1px solid var(--slate-200);
      color: var(--slate-600);
      box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
    }

    /* Back Button */
    .btn-back-mgr {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      font-size: 13px;
      font-weight: 700;
      color: var(--primary);
      text-decoration: none;
      margin-bottom: 4px;
      width: fit-content;
      padding: 4px 10px;
      background: var(--primary-light);
      border: 1px solid var(--primary-border);
      border-radius: var(--radius-sm);
      transition: all 0.15s ease;
    }
    .btn-back-mgr:hover {
      background: #dbeafe;
      color: var(--primary-dark);
      transform: translateX(-2px);
    }

    /* ============================================================== */
    /* STEP 1: COMPACT MANAGERS LIST (MATCHING PERFORMANCE & RATINGS) */
    /* ============================================================== */
    .admin-managers-toolbar {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 14px;
      margin-bottom: 16px;
      flex-wrap: wrap;
    }
    .toolbar-search-mgr {
      flex: 1 1 300px;
      max-width: 460px;
      position: relative;
      display: flex;
      align-items: center;
    }
    .toolbar-search-mgr svg {
      position: absolute;
      left: 12px;
      color: var(--slate-400);
      pointer-events: none;
    }
    .toolbar-search-mgr input {
      width: 100%;
      padding: 9px 12px 9px 36px;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-sm);
      font-size: 13.5px;
      font-family: inherit;
      color: var(--slate-800);
      background: #ffffff;
      transition: all 0.15s ease;
    }
    .toolbar-search-mgr input:focus {
      outline: none;
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
    }

    .admin-managers-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
      margin-bottom: 32px;
    }
    .admin-mgr-card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-lg);
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
      overflow: hidden;
      text-decoration: none;
      display: block;
      transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
    }
    .admin-mgr-card:hover {
      border-color: var(--primary);
      box-shadow: 0 6px 18px rgba(37, 99, 235, 0.08);
      transform: translateY(-1px);
    }
    .admin-mgr-header {
      padding: 16px 22px;
      background: #ffffff;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      flex-wrap: wrap;
      transition: background 0.15s ease;
    }
    .admin-mgr-card:hover .admin-mgr-header {
      background: var(--slate-50);
    }
    .admin-mgr-identity {
      display: flex;
      align-items: center;
      gap: 14px;
      flex: 1 1 280px;
    }
    .admin-mgr-avatar {
      width: 44px;
      height: 44px;
      border-radius: 12px;
      background: var(--brand-gradient);
      color: #ffffff;
      font-weight: 800;
      font-size: 17px;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 2px 8px rgba(37, 99, 235, 0.25);
      flex-shrink: 0;
      text-transform: uppercase;
    }
    .admin-mgr-name {
      font-size: 16px;
      font-weight: 800;
      color: var(--slate-900);
      letter-spacing: -0.01em;
      text-transform: capitalize;
    }
    .admin-mgr-code {
      font-family: monospace;
      font-size: 12px;
      font-weight: 800;
      color: var(--primary);
      background: var(--primary-light);
      border: 1px solid var(--primary-border);
      padding: 2px 8px;
      border-radius: 5px;
    }
    .admin-mgr-dept {
      font-size: 11.5px;
      font-weight: 700;
      background: var(--slate-100);
      color: var(--slate-700);
      border: 1px solid var(--slate-200);
      padding: 2px 8px;
      border-radius: 4px;
    }
    .admin-mgr-sub {
      font-size: 12px;
      color: var(--slate-400);
      margin-top: 3px;
    }
    .admin-mgr-stats {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .admin-stat-chip {
      background: var(--slate-50);
      border: 1px solid var(--slate-200);
      border-radius: 8px;
      padding: 6px 14px;
      display: flex;
      flex-direction: column;
      align-items: center;
      min-width: 90px;
    }
    .admin-stat-chip-num {
      font-size: 15px;
      font-weight: 800;
      color: var(--slate-900);
    }
    .admin-stat-chip-lbl {
      font-size: 10.5px;
      font-weight: 700;
      text-transform: uppercase;
      color: var(--slate-500);
      letter-spacing: 0.04em;
    }
    .btn-view-team-row {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      padding: 8px 16px;
      border-radius: var(--radius-sm);
      font-size: 13px;
      font-weight: 700;
      color: var(--primary);
      background: var(--primary-light);
      border: 1px solid var(--primary-border);
      transition: all 0.15s ease;
      white-space: nowrap;
    }
    .admin-mgr-card:hover .btn-view-team-row {
      background: var(--primary);
      color: #ffffff;
      border-color: var(--primary);
    }
    .btn-view-team-row svg {
      width: 15px;
      height: 15px;
      transition: transform 0.15s ease;
    }
    .admin-mgr-card:hover .btn-view-team-row svg {
      transform: translateX(3px);
    }

    /* ============================================================== */
    /* STEP 2: UNIFIED ROSTER TABLE CARD WITH INTEGRATED TOOLBAR      */
    /* ============================================================== */
    .roster-card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-lg);
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
      overflow: hidden;
    }

    .roster-toolbar {
      padding: 16px 20px;
      border-bottom: 1px solid var(--slate-200);
      background: #ffffff;
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 14px;
    }
    .toolbar-search {
      flex: 1 1 280px;
      min-width: 240px;
      position: relative;
      display: flex;
      align-items: center;
    }
    .toolbar-search svg {
      position: absolute;
      left: 12px;
      color: var(--slate-400);
      pointer-events: none;
    }
    .toolbar-search input {
      width: 100%;
      padding: 9px 12px 9px 36px;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-sm);
      font-size: 13.5px;
      font-family: inherit;
      color: var(--slate-800);
      background: var(--slate-50);
      transition: all 0.15s ease;
    }
    .toolbar-search input:focus {
      outline: none;
      background: #ffffff;
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
    }

    .toolbar-filters {
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
    }
    .toolbar-select {
      padding: 9px 32px 9px 12px;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-sm);
      font-size: 13px;
      font-weight: 600;
      color: var(--slate-700);
      background: #ffffff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%2364748b' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'%3E%3C/polyline%3E%3C/svg%3E") no-repeat right 10px center;
      appearance: none;
      -webkit-appearance: none;
      cursor: pointer;
    }
    .toolbar-select:focus {
      outline: none;
      border-color: var(--primary);
    }
    .btn-toolbar-reset {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 9px 12px;
      border-radius: var(--radius-sm);
      font-size: 13px;
      font-weight: 600;
      color: var(--slate-600);
      background: var(--slate-100);
      border: 1px solid var(--slate-200);
      text-decoration: none;
      transition: all 0.15s ease;
      cursor: pointer;
    }
    .btn-toolbar-reset:hover {
      background: var(--slate-200);
      color: var(--slate-900);
    }
    .badge-count {
      font-size: 12px;
      font-weight: 700;
      color: var(--primary);
      background: var(--primary-light);
      padding: 4px 10px;
      border-radius: 20px;
      border: 1px solid var(--primary-border);
      white-space: nowrap;
    }

    /* Employee Table */
    .emp-table {
      width: 100%;
      border-collapse: separate;
      border-spacing: 0;
      font-size: 13.5px;
    }
    .emp-table th {
      background: var(--slate-50);
      padding: 12px 18px;
      text-align: left;
      font-size: 11px;
      font-weight: 700;
      color: var(--slate-500);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      border-bottom: 1px solid var(--slate-200);
    }
    .emp-table td {
      padding: 14px 18px;
      border-bottom: 1px solid var(--slate-100);
      vertical-align: middle;
      color: var(--slate-700);
    }
    .emp-row {
      transition: background-color 0.15s ease;
      cursor: pointer;
    }
    .emp-row:hover {
      background-color: #f1f5f9;
    }
    .emp-user-cell {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .emp-avatar {
      width: 36px;
      height: 36px;
      border-radius: 50%;
      background: var(--brand-gradient);
      color: #ffffff;
      font-size: 13.5px;
      font-weight: 700;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }
    .emp-name {
      font-weight: 700;
      color: var(--slate-900);
      font-size: 14px;
      text-transform: capitalize;
    }
    .emp-email {
      font-size: 12px;
      color: var(--slate-400);
      margin-top: 1px;
    }
    .dept-tag {
      display: inline-block;
      font-size: 11.5px;
      font-weight: 600;
      padding: 2px 8px;
      border-radius: 4px;
      background: var(--slate-100);
      color: var(--slate-700);
      border: 1px solid var(--slate-200);
    }
    .role-tag {
      display: inline-block;
      font-size: 11px;
      font-weight: 700;
      padding: 2px 8px;
      border-radius: 4px;
      background: var(--indigo-50);
      color: var(--indigo-text);
      border: 1px solid var(--indigo-border);
    }
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      font-size: 11.5px;
      font-weight: 700;
      padding: 3px 8px;
      border-radius: 20px;
    }
    .status-active {
      background: var(--emerald-50);
      color: var(--emerald-text);
      border: 1px solid var(--emerald-border);
    }
    .status-active::before {
      content: '';
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: var(--emerald-500);
    }
    .status-inactive {
      background: var(--rose-50);
      color: var(--rose-text);
      border: 1px solid var(--rose-border);
    }
    .status-inactive::before {
      content: '';
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: var(--rose-500);
    }

    /* Action Button */
    .btn-choose-report {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 7px 14px;
      border-radius: var(--radius-sm);
      font-size: 12.5px;
      font-weight: 700;
      color: var(--primary);
      background: var(--primary-light);
      border: 1px solid var(--primary-border);
      cursor: pointer;
      transition: all 0.15s ease;
    }
    .emp-row:hover .btn-choose-report {
      background: var(--primary);
      color: #ffffff;
      border-color: var(--primary);
    }
    .btn-choose-report svg {
      width: 14px;
      height: 14px;
    }

    /* Empty State */
    .empty-state {
      padding: 48px 24px;
      text-align: center;
    }
    .empty-icon {
      width: 52px;
      height: 52px;
      border-radius: 50%;
      background: var(--slate-100);
      color: var(--slate-400);
      display: inline-flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 12px;
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
        <a href="<%= ctx %>/reportsDashboard" class="btn-sidebar-link on">
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
        <a href="<%= ctx %>/reportsDashboard" class="nav-accordion-item on">
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
        <a href="<%= ctx %>/reportsDashboard" class="nav-accordion-item on">
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
      <h1 class="topbar-title"><%= isEmployee ? "My Reports &amp; Analytics" : "Reports &amp; Analytics Hub" %></h1>
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
      <% if (isEmployee) { %>
        <!-- ============================================================== -->
        <!-- VIEW 0: EMPLOYEE PERSONAL REPORTS (ATTENDANCE & LEAVE ONLY)     -->
        <!-- ============================================================== -->
        <div class="page-header">
          <div class="header-left">
            <h1 class="page-title">My Reports Hub</h1>
            <p class="page-subtitle">Generate and download your personal attendance records and leave balance statement.</p>
          </div>
          <span class="role-pill">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
            Personal Scope &bull; <%= currentUser.getEmployeeId() %>
          </span>
        </div>

        <div class="employee-reports-grid">
          <!-- 1. Personal Attendance Report -->
          <div class="emp-report-box">
            <div class="emp-report-icon-banner" style="background:#ecfdf5; color:#059669; border-color:#a7f3d0;">
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
            </div>
            <div class="emp-report-body">
              <h3 class="emp-report-title">Attendance &amp; Punctuality Statement</h3>
              <p class="emp-report-desc">Review your daily check-in and check-out timestamps, total shift hours worked, late clock-ins, and monthly punctuality rate.</p>
            </div>
            <a href="<%= ctx %>/attendanceReport" class="btn-emp-report" style="background:#059669; color:#ffffff;">
              <span>Generate Attendance Statement</span>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 18 15 12 9 6"></polyline></svg>
            </a>
          </div>

          <!-- 2. Personal Leave Report -->
          <div class="emp-report-box">
            <div class="emp-report-icon-banner" style="background:#fffbeb; color:#d97706; border-color:#fde68a;">
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
            </div>
            <div class="emp-report-body">
              <h3 class="emp-report-title">Leave Requests &amp; Balance Statement</h3>
              <p class="emp-report-desc">Detailed statement of your submitted time-off applications, manager approvals, category allocations, and remaining balance quotas.</p>
            </div>
            <a href="<%= ctx %>/leaveReport" class="btn-emp-report" style="background:#d97706; color:#ffffff;">
              <span>Generate Leave Statement</span>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 18 15 12 9 6"></polyline></svg>
            </a>
          </div>
        </div>

      <% } else { %>
        <!-- ============================================================== -->
        <!-- VIEW 1: UNIFIED REPORTS HUB FOR ADMIN & MANAGER (CARDS ONLY)    -->
        <!-- ============================================================== -->
        <%
            String mgrParamSuffix = (paramManager != null && !paramManager.trim().isEmpty() && !"ALL".equalsIgnoreCase(paramManager.trim())) ? ("?managerId=" + paramManager.trim()) : "";
        %>
        <div class="page-header">
          <div class="header-left">
            <h1 class="page-title">Reports Hub</h1>
            <p class="page-subtitle">
              <%= isHr ? "Generate organization-wide attendance statements, leave audits, project task deliverables, and employee directories." : "Generate and download team attendance records, leave statements, task deliverables, and member directory." %>
            </p>
          </div>
          <span class="role-pill">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
            <%= isHr ? "HR Admin &bull; Full Organization" : ("Manager Scope &bull; " + (currentUser != null && currentUser.getEmployeeId() != null ? currentUser.getEmployeeId() : "Manager")) %>
          </span>
        </div>

        <div class="employee-reports-grid">
          <% if (isManager) { %>
          <!-- Manager Personal Attendance Statement -->
          <div class="emp-report-box" style="border-left: 4px solid #2563eb;">
            <div class="emp-report-icon-banner" style="background:#eff6ff; color:#2563eb; border-color:#bfdbfe;">
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="7" r="4"></circle><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path></svg>
            </div>
            <div class="emp-report-body">
              <h3 class="emp-report-title">My Personal Attendance Statement</h3>
              <p class="emp-report-desc">Audit your personal daily check-in and check-out timestamps, worked hours, breaks, and monthly attendance punctuality.</p>
            </div>
            <a href="<%= ctx %>/attendanceReport?scope=my" class="btn-emp-report" style="background:#2563eb; color:#ffffff;">
              <span>View My Attendance</span>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 18 15 12 9 6"></polyline></svg>
            </a>
          </div>

          <!-- Manager Personal Leave Statement -->
          <div class="emp-report-box" style="border-left: 4px solid #d97706;">
            <div class="emp-report-icon-banner" style="background:#fffbeb; color:#d97706; border-color:#fde68a;">
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="7" r="4"></circle><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path></svg>
            </div>
            <div class="emp-report-body">
              <h3 class="emp-report-title">My Personal Leave Statement</h3>
              <p class="emp-report-desc">Review your personal time-off applications, approval statuses, leave categories, and available balance allocations.</p>
            </div>
            <a href="<%= ctx %>/leaveReport?scope=my" class="btn-emp-report" style="background:#d97706; color:#ffffff;">
              <span>View My Leaves</span>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 18 15 12 9 6"></polyline></svg>
            </a>
          </div>
          <% } %>

          <!-- 1. Attendance Report -->
          <div class="emp-report-box">
            <div class="emp-report-icon-banner" style="background:#ecfdf5; color:#059669; border-color:#a7f3d0;">
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
            </div>
            <div class="emp-report-body">
              <h3 class="emp-report-title"><%= isManager ? "Team Attendance &amp; Punctuality Report" : "Attendance &amp; Punctuality Statement" %></h3>
              <p class="emp-report-desc"><%= isHr ? "Audit company-wide daily check-in and check-out timestamps, shift hours worked, late clock-ins, and department punctuality rates." : "Review your team's daily check-in and check-out timestamps, total shift hours worked, late clock-ins, and overall team punctuality rate." %></p>
            </div>
            <a href="<%= ctx %>/attendanceReport<%= isManager ? "?scope=team" : mgrParamSuffix %>" class="btn-emp-report" style="background:#059669; color:#ffffff;">
              <span><%= isManager ? "Generate Team Attendance" : "Generate Attendance Statement" %></span>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 18 15 12 9 6"></polyline></svg>
            </a>
          </div>

          <!-- 2. Leave Report -->
          <div class="emp-report-box">
            <div class="emp-report-icon-banner" style="background:#fffbeb; color:#d97706; border-color:#fde68a;">
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
            </div>
            <div class="emp-report-body">
              <h3 class="emp-report-title"><%= isManager ? "Team Leave Requests &amp; Balance Statement" : "Leave Requests &amp; Balance Statement" %></h3>
              <p class="emp-report-desc"><%= isHr ? "Comprehensive statement of company-wide time-off applications, manager approvals, category allocations, and remaining balance quotas." : "Detailed statement of team time-off applications, manager approvals, category allocations, and remaining balance quotas." %></p>
            </div>
            <a href="<%= ctx %>/leaveReport<%= isManager ? "?scope=team" : mgrParamSuffix %>" class="btn-emp-report" style="background:#d97706; color:#ffffff;">
              <span><%= isManager ? "Generate Team Leaves" : "Generate Leave Statement" %></span>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 18 15 12 9 6"></polyline></svg>
            </a>
          </div>

          <!-- 3. Task Report -->
          <div class="emp-report-box">
            <div class="emp-report-icon-banner" style="background:#eef2ff; color:#4338ca; border-color:#c7d2fe;">
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>
            </div>
            <div class="emp-report-body">
              <h3 class="emp-report-title">Task Deliverables &amp; Progress</h3>
              <p class="emp-report-desc"><%= isHr ? "Audit cross-department task completions, in-progress deliverables, deadlines, overdue assignments, and project milestone progress." : "Audit team task completions, in-progress deliverables, deadlines, overdue assignments, and project milestone progress." %></p>
            </div>
            <a href="<%= ctx %>/taskReport<%= mgrParamSuffix %>" class="btn-emp-report" style="background:#4338ca; color:#ffffff;">
              <span>Generate Task Statement</span>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 18 15 12 9 6"></polyline></svg>
            </a>
          </div>

          <!-- 4. Employee Directory Report -->
          <div class="emp-report-box">
            <div class="emp-report-icon-banner" style="background:#f5f3ff; color:#7c3aed; border-color:#ddd6fe;">
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
            </div>
            <div class="emp-report-body">
              <h3 class="emp-report-title"><%= isHr ? "Organization Employee Directory" : "Team Directory &amp; Member Profiles" %></h3>
              <p class="emp-report-desc"><%= isHr ? "Complete organizational personnel directory with employee profiles, departmental assignments, reporting structures, and active statuses." : "Comprehensive overview of team members under your supervision, employee contact info, department roles, and active statuses." %></p>
            </div>
            <a href="<%= ctx %>/employeeReport<%= mgrParamSuffix %>" class="btn-emp-report" style="background:#7c3aed; color:#ffffff;">
              <span>Generate Employee Directory</span>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 18 15 12 9 6"></polyline></svg>
            </a>
          </div>

          
        </div>
      <% } %>
    </div>
  </div>
</div>



<script>
  var currentCtx = '<%= ctx %>';

  function filterManagersRealtime() {
    var search = (document.getElementById('mgrSearchInput').value || '').toLowerCase().trim();
    var cards = document.querySelectorAll('.admin-mgr-card');
    var visible = 0;
    cards.forEach(function(card) {
      var data = (card.getAttribute('data-search') || '').toLowerCase();
      if (!search || data.indexOf(search) !== -1) {
        card.style.display = '';
        visible++;
      } else {
        card.style.display = 'none';
      }
    });
    var badge = document.getElementById('mgrCountBadge');
    if (badge) {
      badge.innerText = visible + ' Managers';
    }
  }



  function resetFilters() {
    document.getElementById('searchInput').value = '';
    document.getElementById('deptSelect').value = 'ALL';
    document.getElementById('statusSelect').value = 'ALL';
    filterTableRealtime();
  }

  function filterTableRealtime() {
    var searchVal = (document.getElementById('searchInput').value || '').toLowerCase().trim();
    var deptVal = (document.getElementById('deptSelect').value || 'ALL').toUpperCase();
    var statusVal = (document.getElementById('statusSelect').value || 'ALL').toUpperCase();

    var rows = document.querySelectorAll('.emp-row');
    var visible = 0;

    rows.forEach(function(row) {
      var text = row.innerText.toLowerCase();
      var matchSearch = !searchVal || text.indexOf(searchVal) !== -1;

      var deptTag = row.querySelector('.dept-tag');
      var rowDept = deptTag ? deptTag.innerText.toUpperCase().trim() : '';
      var matchDept = (deptVal === 'ALL') || (rowDept === deptVal);

      var statusTag = row.querySelector('.status-badge');
      var rowStatus = statusTag ? statusTag.innerText.toUpperCase().trim() : '';
      var matchStatus = (statusVal === 'ALL') || (rowStatus === statusVal);

      if (matchSearch && matchDept && matchStatus) {
        row.style.display = '';
        visible++;
      } else {
        row.style.display = 'none';
      }
    });

    var badge = document.getElementById('visibleCountBadge');
    if (badge) {
      badge.innerText = visible + ' Employees';
    }
  }
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
