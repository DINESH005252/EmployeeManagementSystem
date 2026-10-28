<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.util.Map, model.EmployeePerformance, model.Manager, model.ManagerReviewSummary, model.Task, model.TaskGroup, model.User, java.net.URLEncoder, java.nio.charset.StandardCharsets" %>
<%
    User currentUser = (User) session.getAttribute("user");
    String viewMode = (String) request.getAttribute("viewMode");
    if (viewMode == null || viewMode.isEmpty()) viewMode = "task";

    List<Task> taskReviews = (List<Task>) request.getAttribute("taskReviews");
    List<TaskGroup> taskGroups = (List<TaskGroup>) request.getAttribute("taskGroups");
    List<ManagerReviewSummary> managerSummaries = (List<ManagerReviewSummary>) request.getAttribute("managerSummaries");
    List<EmployeePerformance> performanceList = (List<EmployeePerformance>) request.getAttribute("performanceList");
    Map<String, Object> orgStats = (Map<String, Object>) request.getAttribute("orgStats");
    List<Manager> activeManagers = (List<Manager>) request.getAttribute("activeManagers");
    List<String> distinctDepartments = (List<String>) request.getAttribute("distinctDepartments");

    String selectedDept = (String) request.getAttribute("selectedDept");
    String selectedManager = (String) request.getAttribute("selectedManager");
    String selectedStatus = (String) request.getAttribute("selectedStatus");
    String selectedRating = (String) request.getAttribute("selectedRating");
    String keyword = (String) request.getAttribute("keyword");

    if (selectedDept == null) selectedDept = "ALL";
    if (selectedManager == null) selectedManager = "ALL";
    if (selectedStatus == null) selectedStatus = "ALL";
    if (selectedRating == null) selectedRating = "ALL";
    if (keyword == null) keyword = "";

    boolean isHr = currentUser != null && currentUser.isHr();
    boolean isManager = currentUser != null && currentUser.isManager();
    boolean isEmployee = currentUser != null && currentUser.isEmployee();
    String ctx = request.getContextPath();
    String roleBadge = isHr ? "ADMIN" : (isManager ? "MANAGER" : "EMPLOYEE");
    String userName = (currentUser != null && currentUser.getUsername() != null) ? currentUser.getUsername() : "User";
    String userInitial = !userName.isEmpty() ? userName.substring(0, 1).toUpperCase() : "U";

    double orgAvg = orgStats != null && orgStats.get("orgAvgRating") != null ? (Double) orgStats.get("orgAvgRating") : 0.0;
    int evalCount = orgStats != null && orgStats.get("evaluatedEmployees") != null ? (Integer) orgStats.get("evaluatedEmployees") : 0;
    int totalReviewed = orgStats != null && orgStats.get("totalReviewed") != null ? (Integer) orgStats.get("totalReviewed") : 0;
    int highCount = orgStats != null && orgStats.get("highPerformers") != null ? (Integer) orgStats.get("highPerformers") : 0;
    int pendingRev = orgStats != null && orgStats.get("pendingReviews") != null ? (Integer) orgStats.get("pendingReviews") : 0;
    int awaitingComp = orgStats != null && orgStats.get("awaitingCompletion") != null ? (Integer) orgStats.get("awaitingCompletion") : 0;
    int uniqueTasks = orgStats != null && orgStats.get("uniqueTasks") != null ? (Integer) orgStats.get("uniqueTasks") : 0;
    int totalAssignments = orgStats != null && orgStats.get("totalAssignments") != null ? (Integer) orgStats.get("totalAssignments") : 0;
    int managerCount = activeManagers != null ? activeManagers.size() : 0;

    int taskReviewsCount = taskReviews != null ? taskReviews.size() : 0;
    int taskGroupsCount = taskGroups != null ? taskGroups.size() : 0;
    int mgrSummariesCount = managerSummaries != null ? managerSummaries.size() : 0;
    int empCount = performanceList != null ? performanceList.size() : 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>WorkPulse — Performance & Review Management Center</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-main: #f8fafc;
      --bg-card: #ffffff;
      --card-border: #e2e8f0;
      --card-hover-border: #cbd5e1;

      --primary: #2563eb;
      --primary-dark: #1d4ed8;
      --primary-light: #eff6ff;
      --primary-border: #bfdbfe;

      --brand-gradient: linear-gradient(135deg, #1d4ed8 0%, #2563eb 100%);
      --brand-accent: #3b82f6;

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
      --amber-600: #d97706;
      --amber-50: #fffbeb;
      --amber-border: #fde68a;
      --amber-text: #92400e;

      --rose-500: #ef4444;
      --rose-50: #fef2f2;
      --rose-border: #fecaca;
      --rose-text: #991b1b;

      --purple-50: #faf5ff;
      --purple-100: #f3e8ff;
      --purple-border: #e9d5ff;
      --purple-text: #6b21a8;

      --radius-sm: 8px;
      --radius-md: 12px;
      --radius-lg: 16px;
      --shadow-sm: 0 1px 3px rgba(15, 23, 42, 0.06), 0 1px 2px rgba(15, 23, 42, 0.04);
      --shadow-card: 0 4px 6px -1px rgba(15, 23, 42, 0.07), 0 2px 4px -2px rgba(15, 23, 42, 0.05);
      --shadow-lg: 0 10px 15px -3px rgba(15, 23, 42, 0.08), 0 4px 6px -4px rgba(15, 23, 42, 0.04);
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Plus Jakarta Sans', 'Inter', sans-serif;
      background: var(--bg-main);
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
      min-width: 0;
      background: var(--slate-50);
      min-height: 100vh;
    }
    .topbar {
      height: 72px;
      background: #ffffff;
      border-bottom: 1px solid var(--slate-200);
      padding: 0 36px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      position: sticky;
      top: 0;
      z-index: 10;
    }
    .topbar .page-title {
      font-size: 19px;
      font-weight: 800;
      color: var(--slate-900);
      letter-spacing: -0.02em;
    }
    .user-ctrls {
      display: flex;
      align-items: center;
      gap: 12px;
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
      width: 28px;
      height: 28px;
      border-radius: 50%;
      background: var(--brand-gradient);
      display: flex;
      align-items: center;
      justify-content: center;
      color: #fff;
      font-weight: 700;
      font-size: 12px;
    }
    .user-info-text {
      font-size: 13.5px;
      font-weight: 600;
      color: var(--slate-800);
    }
    .btn-signout {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      text-decoration: none;
      background: #ffffff;
      border: 1px solid #fecaca;
      color: #dc2626;
      padding: 7px 14px;
      border-radius: var(--radius-sm);
      font-size: 13px;
      font-weight: 600;
      transition: all 0.15s ease;
    }
    .btn-signout:hover {
      background: #fef2f2;
      border-color: #f87171;
      color: #991b1b;
    }

    header.topbar_old {
      background: #ffffff;
      border-bottom: 1px solid var(--card-border);
      padding: 14px 28px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      position: sticky;
      top: 0;
      z-index: 50;
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.05);
    }
    .brand-link {
      display: flex;
      align-items: center;
      gap: 12px;
      text-decoration: none;
      color: var(--slate-900);
      font-weight: 800;
      font-size: 17px;
      letter-spacing: -0.02em;
    }
    .logo-badge {
      width: 34px;
      height: 34px;
      border-radius: 9px;
      background: var(--primary);
      display: flex;
      align-items: center;
      justify-content: center;
      color: #ffffff;
      box-shadow: 0 2px 8px rgba(37, 99, 235, 0.25);
    }
    .nav-links {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .nav-btn {
      padding: 8px 14px;
      border-radius: var(--radius-sm);
      font-size: 13.5px;
      font-weight: 600;
      text-decoration: none;
      color: var(--slate-600);
      transition: all 0.15s;
    }
    .nav-btn:hover { background: var(--slate-100); color: var(--slate-900); }
    .nav-btn.active { 
      background: var(--primary-light);
      color: var(--primary-dark);
      font-weight: 700;
      border: 1px solid var(--primary-border);
    }
    
    .container {
      max-width: 1320px;
      margin: 0 auto;
      padding: 24px 28px 48px;
      width: 100%;
    }
    
    /* Page Title & Subtitle */
    .page-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 24px;
      flex-wrap: wrap;
      gap: 16px;
    }
    .page-title {
      font-size: 25px;
      font-weight: 800;
      color: var(--slate-900);
      letter-spacing: -0.025em;
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .page-subtitle {
      font-size: 14px;
      color: var(--slate-500);
      margin-top: 4px;
      max-width: 820px;
      line-height: 1.5;
    }

    /* KPI Summary Cards */
    .kpi-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }
    .kpi-card {
      background: var(--bg-card);
      border: 1px solid var(--card-border);
      border-radius: var(--radius-md);
      padding: 18px 22px;
      box-shadow: var(--shadow-sm);
      display: flex;
      align-items: center;
      gap: 16px;
      min-height: 108px;
      box-sizing: border-box;
      transition: transform 0.2s, box-shadow 0.2s, border-color 0.2s;
    }
    .kpi-card:hover {
      transform: translateY(-2px);
      border-color: var(--card-hover-border);
      box-shadow: var(--shadow-card);
    }
    .kpi-icon-box {
      width: 48px;
      height: 48px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }
    .kpi-icon-amber { background: var(--amber-50); color: var(--amber-600); border: 1px solid var(--amber-border); }
    .kpi-icon-blue { background: var(--primary-light); color: var(--primary); border: 1px solid var(--primary-border); }
    .kpi-icon-emerald { background: var(--emerald-50); color: var(--emerald-600); border: 1px solid var(--emerald-border); }
    .kpi-icon-purple { background: var(--purple-50); color: #7c3aed; border: 1px solid var(--purple-border); }
    .kpi-meta { display: flex; flex-direction: column; gap: 2px; }
    .kpi-label {
      font-size: 12px;
      font-weight: 700;
      color: var(--slate-500);
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    .kpi-num {
      font-size: 26px;
      font-weight: 800;
      color: var(--slate-900);
      letter-spacing: -0.02em;
      display: flex;
      align-items: baseline;
      gap: 6px;
    }
    .kpi-subtext {
      font-size: 12px;
      color: var(--slate-400);
    }

    /* Mode Switcher Tabs */
    .view-switcher-container {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 20px;
      flex-wrap: wrap;
      gap: 12px;
      border-bottom: 1px solid var(--card-border);
      padding-bottom: 14px;
    }
    .view-segmented-tabs {
      display: flex;
      background: #ffffff;
      border: 1px solid var(--card-border);
      padding: 4px;
      border-radius: 12px;
      gap: 4px;
      box-shadow: var(--shadow-sm);
    }
    .tab-btn {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 9px 18px;
      border: none;
      border-radius: 9px;
      background: transparent;
      color: var(--slate-600);
      font-family: inherit;
      font-size: 13.5px;
      font-weight: 700;
      cursor: pointer;
      text-decoration: none;
      transition: all 0.18s ease;
    }
    .tab-btn:hover {
      color: var(--slate-900);
      background: var(--slate-50);
    }
    .tab-btn.active {
      background: var(--primary-light);
      color: var(--primary-dark);
      border: 1px solid var(--primary-border);
    }
    .tab-badge {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      padding: 2px 7px;
      border-radius: 20px;
      font-size: 11px;
      font-weight: 800;
      background: var(--slate-100);
      color: var(--slate-600);
    }
    .tab-btn.active .tab-badge {
      background: var(--primary);
      color: #ffffff;
    }

    /* Filter Card */
    .filter-card {
      background: var(--bg-card);
      border: 1px solid var(--card-border);
      border-radius: var(--radius-md);
      padding: 16px 20px;
      margin-bottom: 24px;
      box-shadow: var(--shadow-sm);
    }
    .filter-form {
      display: flex;
      gap: 14px;
      flex-wrap: wrap;
      align-items: flex-end;
    }
    .filter-field-group {
      display: flex;
      flex-direction: column;
      gap: 5px;
    }
    .filter-field-label {
      font-size: 11.5px;
      font-weight: 700;
      color: var(--slate-600);
      text-transform: uppercase;
      letter-spacing: 0.04em;
    }
    .filter-input, .filter-select {
      padding: 10px 14px;
      border: 1.5px solid var(--slate-300);
      border-radius: var(--radius-sm);
      font-size: 13.5px;
      font-family: inherit;
      color: var(--slate-900);
      background: #ffffff;
      transition: border-color 0.15s;
    }
    .filter-input:focus, .filter-select:focus {
      outline: none;
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
    }
    .filter-input {
      flex: 1;
      min-width: 240px;
    }
    .btn-filter-apply {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      padding: 10px 20px;
      background: var(--brand-gradient);
      color: #ffffff;
      border: none;
      border-radius: var(--radius-sm);
      font-size: 13.5px;
      font-weight: 700;
      cursor: pointer;
      box-shadow: 0 4px 14px rgba(29, 78, 216, 0.25);
      transition: all 0.18s ease;
    }
    .btn-filter-apply:hover {
      background: linear-gradient(135deg, #1e40af 0%, #1d4ed8 50%, #2563eb 100%);
      transform: translateY(-1px);
      box-shadow: 0 6px 18px rgba(29, 78, 216, 0.35);
    }
    .btn-filter-reset {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 10px 16px;
      background: #ffffff;
      color: var(--slate-700);
      border: 1.5px solid var(--slate-300);
      border-radius: var(--radius-sm);
      font-size: 13.5px;
      font-weight: 600;
      text-decoration: none;
      transition: all 0.15s ease;
    }
    .btn-filter-reset:hover {
      background: var(--slate-50);
      color: var(--slate-900);
      border-color: var(--slate-400);
    }

    /* Card Panels & Containers */
    .view-panel {
      display: none;
    }
    .view-panel.active {
      display: block;
    }

    /* VIEW 1: By Task - Clean Review Cards */
    .task-review-card {
      background: var(--bg-card);
      border: 1px solid var(--card-border);
      border-radius: var(--radius-md);
      box-shadow: var(--shadow-sm);
      padding: 22px 24px;
      margin-bottom: 18px;
      transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
    }
    .task-review-card:hover {
      border-color: var(--card-hover-border);
      box-shadow: var(--shadow-card);
      transform: translateY(-1.5px);
    }
    .task-card-header {
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      gap: 14px;
      margin-bottom: 16px;
      flex-wrap: wrap;
    }
    .task-title-group {
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
    }
    .task-id-badge {
      font-family: monospace;
      font-size: 13px;
      font-weight: 800;
      color: var(--primary);
      background: var(--primary-light);
      border: 1px solid var(--primary-border);
      padding: 3px 9px;
      border-radius: 6px;
    }
    .task-title-heading {
      font-size: 16.5px;
      font-weight: 800;
      color: var(--slate-900);
      letter-spacing: -0.015em;
    }
    
    /* Meta Pills Grid */
    .task-parties-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      background: var(--slate-50);
      border: 1px solid var(--card-border);
      border-radius: 10px;
      padding: 14px 18px;
      margin-bottom: 16px;
    }
    @media (max-width: 768px) {
      .task-parties-grid { grid-template-columns: 1fr; }
    }
    .party-item {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .party-avatar {
      width: 38px;
      height: 38px;
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 800;
      font-size: 14px;
      flex-shrink: 0;
    }
    .avatar-mgr { background: var(--purple-50); color: #7c3aed; border: 1px solid var(--purple-border); }
    .avatar-emp { background: var(--primary-light); color: var(--primary); border: 1px solid var(--primary-border); }
    .party-role-tag {
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: var(--slate-500);
    }
    .party-name {
      font-size: 14px;
      font-weight: 700;
      color: var(--slate-900);
    }
    .party-sub {
      font-size: 11.5px;
      color: var(--slate-400);
      font-family: monospace;
    }

    /* Rating & Feedback Banner */
    .review-feedback-box {
      background: var(--amber-50);
      border: 1px solid var(--amber-border);
      border-radius: 10px;
      padding: 16px 20px;
      margin-bottom: 16px;
    }
    .review-feedback-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      margin-bottom: 10px;
      flex-wrap: wrap;
    }
    .review-stars-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      color: var(--amber-600);
      font-weight: 800;
      font-size: 15px;
    }
    .stars-char {
      color: var(--amber-500);
      font-size: 17px;
      letter-spacing: 1.5px;
    }
    .review-quote-text {
      font-size: 14px;
      color: var(--amber-text);
      line-height: 1.6;
      background: #ffffff;
      padding: 12px 16px;
      border-radius: 8px;
      border: 1px solid var(--amber-border);
      font-style: normal;
      position: relative;
    }
    .review-quote-text::before {
      content: "“";
      font-size: 26px;
      color: var(--amber-500);
      line-height: 0;
      position: relative;
      top: 6px;
      margin-right: 4px;
    }

    .unreviewed-banner {
      background: var(--slate-50);
      border: 1px dashed var(--slate-300);
      border-radius: 10px;
      padding: 14px 18px;
      display: flex;
      align-items: center;
      gap: 10px;
      color: var(--slate-500);
      font-size: 13.5px;
      margin-bottom: 16px;
    }

    /* Deliverables & Actions Row */
    .task-card-footer {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      flex-wrap: wrap;
      padding-top: 12px;
      border-top: 1px solid var(--card-border);
    }
    .deliverables-group {
      display: flex;
      align-items: center;
      gap: 8px;
      flex-wrap: wrap;
    }
    .btn-file-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 12px;
      border-radius: 6px;
      font-size: 12.5px;
      font-weight: 700;
      text-decoration: none;
      transition: all 0.15s;
      max-width: 320px;
      white-space: nowrap;
    }
    .file-pill-name {
      max-width: 170px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      display: inline-block;
      vertical-align: bottom;
    }
    .btn-file-proof {
      background: var(--emerald-50);
      color: var(--emerald-text);
      border: 1px solid var(--emerald-border);
    }
    .btn-file-proof:hover {
      background: #d1fae5;
      color: #064e3b;
    }
    .btn-file-spec {
      background: var(--primary-light);
      color: var(--primary-dark);
      border: 1px solid var(--primary-border);
    }
    .btn-file-spec:hover {
      background: #dbeafe;
      color: #1e40af;
    }

    /* VIEW 2: By Manager Cards */
    .manager-scorecard-card {
      background: var(--bg-card);
      border: 1px solid var(--card-border);
      border-radius: var(--radius-lg);
      box-shadow: var(--shadow-sm);
      margin-bottom: 24px;
      overflow: hidden;
      transition: box-shadow 0.2s;
    }
    .manager-scorecard-card:hover {
      box-shadow: var(--shadow-card);
    }
    .manager-card-top {
      padding: 20px 24px;
      background: var(--slate-50);
      border-bottom: 1px solid var(--card-border);
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 16px;
    }
    .manager-info-wrap {
      display: flex;
      align-items: center;
      gap: 14px;
    }
    .manager-avatar-large {
      width: 48px;
      height: 48px;
      border-radius: 12px;
      background: var(--brand-gradient);
      color: #ffffff;
      font-weight: 800;
      font-size: 18px;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 2px 8px rgba(37, 99, 235, 0.25);
    }
    .manager-name-title {
      font-size: 17px;
      font-weight: 800;
      color: var(--slate-900);
    }
    .manager-stats-pills {
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
    }
    .mgr-stat-chip {
      background: #ffffff;
      border: 1px solid var(--card-border);
      border-radius: 8px;
      padding: 6px 14px;
      display: flex;
      flex-direction: column;
      align-items: center;
      min-width: 90px;
      box-shadow: var(--shadow-sm);
    }
    .mgr-stat-chip-num {
      font-size: 16px;
      font-weight: 800;
      color: var(--slate-900);
    }
    .mgr-stat-chip-lbl {
      font-size: 10.5px;
      font-weight: 700;
      text-transform: uppercase;
      color: var(--slate-500);
      letter-spacing: 0.04em;
    }

    .manager-reviews-body {
      padding: 20px 24px;
    }
    .manager-review-item {
      background: var(--slate-50);
      border: 1px solid var(--card-border);
      border-radius: 10px;
      padding: 16px 18px;
      margin-bottom: 12px;
      transition: background 0.15s;
    }
    .manager-review-item:last-child {
      margin-bottom: 0;
    }
    .manager-review-item:hover {
      background: #ffffff;
      border-color: var(--card-hover-border);
    }

    /* VIEW 3: By Employee Table */
    .table-wrapper {
      background: var(--bg-card);
      border: 1px solid var(--card-border);
      border-radius: var(--radius-lg);
      box-shadow: var(--shadow-sm);
      overflow: hidden;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 13.5px;
      background: #ffffff;
    }
    th {
      background: var(--slate-50);
      text-align: left;
      padding: 14px 18px;
      font-weight: 700;
      color: var(--slate-500);
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      border-bottom: 1px solid var(--card-border);
    }
    td {
      padding: 16px 18px;
      border-bottom: 1px solid var(--slate-100);
      color: var(--slate-700);
      vertical-align: middle;
    }
    tr:last-child td { border-bottom: none; }
    tr:hover td { background: var(--slate-50); }

    /* Badges */
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.03em;
    }
    .badge-success { background: var(--emerald-50); color: var(--emerald-text); border: 1px solid var(--emerald-border); }
    .badge-primary { background: var(--primary-light); color: var(--primary-dark); border: 1px solid var(--primary-border); }
    .badge-warning { background: var(--amber-50); color: var(--amber-text); border: 1px solid var(--amber-border); }
    .badge-danger { background: var(--rose-50); color: var(--rose-text); border: 1px solid var(--rose-border); }
    .badge-secondary { background: var(--slate-100); color: var(--slate-600); border: 1px solid var(--slate-300); }
    .badge-awaiting { background: var(--slate-100); color: var(--slate-600); border: 1px solid var(--slate-300); }
    .badge-pending { background: var(--amber-50); color: var(--amber-text); border: 1px solid var(--amber-border); }
    .badge-reviewed { background: var(--emerald-50); color: var(--emerald-text); border: 1px solid var(--emerald-border); }

    .priority-pill {
      font-size: 11px;
      font-weight: 800;
      padding: 3px 8px;
      border-radius: 4px;
      text-transform: uppercase;
      letter-spacing: 0.04em;
    }
    .priority-high { background: var(--rose-50); color: var(--rose-text); border: 1px solid var(--rose-border); }
    .priority-medium { background: var(--amber-50); color: var(--amber-text); border: 1px solid var(--amber-border); }
    .priority-low { background: var(--emerald-50); color: var(--emerald-text); border: 1px solid var(--emerald-border); }

    .btn-toggle-reviews {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: #ffffff;
      color: var(--slate-700);
      border: 1.5px solid var(--slate-300);
      border-radius: 8px;
      padding: 6px 14px;
      font-size: 12.5px;
      font-weight: 700;
      cursor: pointer;
      transition: all 0.18s ease;
      box-shadow: var(--shadow-sm);
    }
    .btn-toggle-reviews:hover {
      background: var(--slate-50);
      border-color: var(--slate-400);
      color: var(--slate-900);
    }

    .emp-drawer-row {
      display: none;
    }
    .emp-drawer-box {
      background: var(--slate-50);
      padding: 20px 24px;
      border-top: 1px solid var(--card-border);
    }

    /* Empty State */
    .empty-state {
      padding: 64px 24px;
      text-align: center;
      background: var(--bg-card);
      border: 1px solid var(--card-border);
      border-radius: var(--radius-md);
      color: var(--slate-500);
    }
    .empty-icon-circle {
      width: 56px;
      height: 56px;
      border-radius: 50%;
      background: var(--slate-100);
      color: var(--slate-400);
      display: inline-flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 14px;
    }

    .btn-tasks-expand {
      background: none;
      border: none;
      padding: 0;
      cursor: pointer;
      font-family: inherit;
      display: inline-block;
      text-align: left;
    }
    .btn-tasks-expand:hover .total-tasks-pill {
      background: var(--primary);
      border-color: var(--primary);
      color: #ffffff;
      box-shadow: 0 2px 8px rgba(37, 99, 235, 0.25);
      transform: translateY(-1px);
    }
    .total-tasks-pill {
      font-size: 13px;
      font-weight: 800;
      color: var(--primary);
      background: var(--primary-light);
      border: 1px solid var(--primary-border);
      padding: 5px 12px;
      border-radius: 6px;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: all 0.15s ease;
    }
    .drawer-header-bar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
      margin-bottom: 16px;
      padding-bottom: 12px;
      border-bottom: 1px solid var(--card-border);
    }
    .drawer-header-title {
      font-size: 15px;
      font-weight: 800;
      color: var(--slate-900);
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .drawer-badge-count {
      font-size: 11.5px;
      font-weight: 700;
      background: var(--primary-light);
      color: var(--primary-dark);
      border: 1px solid var(--primary-border);
      padding: 2px 8px;
      border-radius: 20px;
    }
    .drawer-header-desc {
      font-size: 12.5px;
      color: var(--slate-500);
      margin-top: 2px;
    }
    .btn-close-drawer {
      background: #ffffff;
      border: 1.5px solid var(--slate-300);
      color: var(--slate-700);
      font-size: 12px;
      font-weight: 700;
      padding: 5px 12px;
      border-radius: 6px;
      cursor: pointer;
      transition: all 0.15s ease;
    }
    .btn-close-drawer:hover {
      background: var(--slate-50);
      color: var(--slate-900);
      border-color: var(--slate-400);
    }
    .tasks-numbered-container {
      display: flex;
      flex-direction: column;
      gap: 14px;
    }
    .task-card-numbered {
      background: #ffffff;
      border: 1px solid var(--card-border);
      border-radius: 10px;
      box-shadow: var(--shadow-sm);
      overflow: hidden;
      transition: border-color 0.15s ease, box-shadow 0.15s ease;
    }
    .task-card-numbered:hover {
      border-color: var(--card-hover-border);
      box-shadow: var(--shadow-card);
    }
    .task-card-numbered-header {
      padding: 13px 18px;
      background: #ffffff;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      cursor: pointer;
      user-select: none;
      transition: background 0.15s ease;
    }
    .task-card-numbered-header:hover {
      background: var(--slate-50);
    }
    .task-header-left {
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
    }
    .task-step-badge {
      background: var(--brand-gradient);
      color: #ffffff;
      font-size: 12px;
      font-weight: 800;
      padding: 4px 11px;
      border-radius: 6px;
      letter-spacing: 0.03em;
      text-transform: uppercase;
      box-shadow: 0 2px 4px rgba(29, 78, 216, 0.25);
    }
    .task-code-pill {
      font-family: monospace;
      font-size: 12.5px;
      font-weight: 800;
      color: var(--primary);
      background: var(--primary-light);
      border: 1px solid var(--primary-border);
      padding: 3px 8px;
      border-radius: 5px;
    }
    .task-title-text {
      font-size: 14.5px;
      font-weight: 800;
      color: var(--slate-900);
    }
    .task-header-right {
      display: flex;
      align-items: center;
      gap: 10px;
      flex-shrink: 0;
    }
    .task-rating-display {
      font-size: 13.5px;
      font-weight: 800;
      color: var(--amber-600);
    }
    .badge-pending-tag {
      background: var(--amber-50);
      color: var(--amber-text);
      border: 1px solid var(--amber-border);
      font-size: 11.5px;
      font-weight: 700;
      padding: 3px 8px;
      border-radius: 4px;
    }
    .task-chevron-icon {
      font-size: 13px;
      color: var(--slate-400);
      margin-left: 4px;
    }
    .task-card-numbered-body {
      padding: 16px 20px;
      border-top: 1px solid var(--card-border);
      background: var(--slate-50);
    }
    .task-meta-row {
      display: flex;
      align-items: center;
      gap: 16px;
      font-size: 12.5px;
      color: var(--slate-500);
      margin-bottom: 12px;
      flex-wrap: wrap;
    }
    .task-meta-item strong {
      color: var(--slate-900);
    }
    .task-desc-box {
      background: #ffffff;
      border: 1px solid var(--card-border);
      border-radius: 8px;
      padding: 12px 14px;
      font-size: 13px;
      color: var(--slate-700);
      margin-bottom: 14px;
    }
    .task-files-row {
      margin-bottom: 14px;
      padding-bottom: 12px;
      border-bottom: 1px solid var(--card-border);
    }
    .task-review-section {
      background: #ffffff;
      border: 1px solid var(--amber-border);
      border-radius: 8px;
      padding: 16px 18px;
    }
    .review-section-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 10px;
      margin-bottom: 10px;
      flex-wrap: wrap;
    }
    .review-section-title {
      font-size: 13.5px;
      font-weight: 800;
      color: var(--amber-text);
      display: flex;
      align-items: center;
      gap: 7px;
    }
    .review-status-tag {
      font-size: 11.5px;
      font-weight: 700;
      padding: 2px 8px;
      border-radius: 4px;
    }
    .review-status-tag.reviewed {
      background: var(--amber-50);
      color: var(--amber-text);
      border: 1px solid var(--amber-border);
    }
    .review-status-tag.pending {
      background: var(--primary-light);
      color: var(--primary-dark);
      border: 1px solid var(--primary-border);
    }
    .current-feedback-quote {
      background: var(--amber-50);
      border: 1px solid var(--amber-border);
      border-radius: 6px;
      padding: 10px 14px;
      font-size: 13px;
      color: var(--amber-text);
      margin-bottom: 12px;
      line-height: 1.5;
    }
    .quote-date {
      font-size: 11.5px;
      color: var(--amber-600);
      margin-left: 6px;
    }
    .rating-label-title {
      display: block;
      font-size: 12px;
      font-weight: 700;
      color: var(--slate-700);
      text-transform: uppercase;
      letter-spacing: 0.04em;
      margin-bottom: 6px;
    }
    .feedback-textarea {
      width: 100%;
      padding: 10px 12px;
      font-size: 13px;
      border: 1.5px solid var(--slate-300);
      border-radius: 6px;
      font-family: inherit;
      resize: vertical;
      background: #ffffff;
      color: var(--slate-900);
      box-sizing: border-box;
    }
    .feedback-textarea:focus {
      outline: none;
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
    }
    .star-rating-radio-group {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }
    .star-radio-btn {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: #ffffff;
      border: 1.5px solid var(--slate-300);
      padding: 6px 12px;
      border-radius: 6px;
      font-size: 12px;
      font-weight: 700;
      cursor: pointer;
      color: var(--slate-700);
      transition: all 0.15s ease;
    }
    .star-radio-btn:hover {
      border-color: var(--primary);
      background: var(--primary-light);
      color: var(--primary-dark);
    }
    .star-radio-btn:has(input[type="radio"]:checked),
    .star-radio-btn.selected {
      border-color: var(--primary) !important;
      background: var(--primary-light) !important;
      color: var(--primary-dark) !important;
      box-shadow: 0 0 0 2px rgba(37, 99, 235, 0.2);
    }
    .star-radio-btn input[type="radio"] {
      accent-color: var(--primary);
      cursor: pointer;
    }
    .btn-save-rating {
      background: var(--brand-gradient);
      color: #ffffff;
      border: none;
      border-radius: 6px;
      padding: 9px 18px;
      font-size: 13px;
      font-weight: 700;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 7px;
      box-shadow: 0 4px 14px rgba(29, 78, 216, 0.25);
      transition: all 0.15s ease;
    }
    .btn-save-rating:hover {
      background: linear-gradient(135deg, #1e40af 0%, #1d4ed8 50%, #2563eb 100%);
      transform: translateY(-1px);
      box-shadow: 0 6px 18px rgba(29, 78, 216, 0.35);
    }

    /* Task Groups View */
    .task-groups-list {
      display: flex;
      flex-direction: column;
      gap: 18px;
    }
    .task-group-card {
      background: #ffffff;
      border: 1px solid var(--card-border);
      border-radius: var(--radius-md);
      box-shadow: var(--shadow-sm);
      overflow: hidden;
      transition: all 0.2s ease;
    }
    .task-group-card:hover {
      border-color: var(--card-hover-border);
      box-shadow: var(--shadow-card);
    }
    .task-group-header {
      padding: 16px 22px;
      background: #ffffff;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 14px;
      cursor: pointer;
      user-select: none;
      transition: background 0.15s ease;
      flex-wrap: wrap;
    }
    .task-group-header:hover {
      background: var(--slate-50);
    }
    .tg-header-left {
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
    }
    .tg-seq-pill {
      background: var(--brand-gradient);
      color: #ffffff;
      font-size: 12px;
      font-weight: 800;
      padding: 4px 12px;
      border-radius: 6px;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      box-shadow: 0 2px 6px rgba(29, 78, 216, 0.25);
    }
    .tg-title-text {
      font-size: 16px;
      font-weight: 800;
      color: var(--slate-900);
      letter-spacing: -0.01em;
    }
    .tg-dept-pill {
      font-size: 11.5px;
      font-weight: 700;
      background: var(--purple-50);
      color: #7c3aed;
      border: 1px solid var(--purple-border);
      padding: 2px 8px;
      border-radius: 4px;
    }
    .tg-header-right {
      display: flex;
      align-items: center;
      gap: 14px;
      flex-wrap: wrap;
    }
    .tg-stats-chips {
      display: flex;
      align-items: center;
      gap: 10px;
      font-size: 12px;
      color: var(--slate-500);
    }
    .tg-stat-item {
      background: var(--slate-50);
      padding: 4px 10px;
      border-radius: 6px;
      border: 1px solid var(--card-border);
      color: var(--slate-700);
    }
    .tg-stat-item strong {
      color: var(--slate-900);
    }
    .tg-stat-rating {
      background: var(--amber-50);
      color: var(--amber-text);
      border: 1px solid var(--amber-border);
      padding: 4px 10px;
      border-radius: 6px;
      font-weight: 800;
    }
    .tg-stat-pending {
      background: var(--primary-light);
      color: var(--primary-dark);
      border: 1px solid var(--primary-border);
      padding: 4px 10px;
      border-radius: 6px;
      font-weight: 700;
    }
    .tg-expand-btn {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      font-size: 12.5px;
      font-weight: 700;
      color: var(--primary);
      background: var(--primary-light);
      border: 1px solid var(--primary-border);
      padding: 5px 12px;
      border-radius: 6px;
    }
    .tg-chevron {
      font-size: 14px;
      transition: transform 0.2s ease;
    }
    .task-group-body {
      padding: 20px 24px;
      background: var(--slate-50);
      border-top: 1px solid var(--card-border);
    }
    .tg-meta-banner {
      background: #ffffff;
      border: 1px solid var(--card-border);
      border-radius: 8px;
      padding: 14px 18px;
      margin-bottom: 16px;
      color: var(--slate-700);
    }
    .tg-employees-container {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    .employee-task-row-card {
      background: #ffffff;
      border: 1px solid var(--card-border);
      border-radius: 8px;
      padding: 16px 18px;
      transition: all 0.15s ease;
    }
    .employee-task-row-card:hover {
      border-color: var(--card-hover-border);
      box-shadow: var(--shadow-card);
    }
    .emp-row-top {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
      margin-bottom: 10px;
    }
    .emp-row-identity {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .emp-avatar-sm {
      width: 36px;
      height: 36px;
      border-radius: 8px;
      background: var(--brand-gradient);
      color: #ffffff;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 800;
      font-size: 14px;
      flex-shrink: 0;
    }
    .emp-name-bold {
      font-size: 14.5px;
      font-weight: 800;
      color: var(--slate-900);
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .emp-code-sub {
      font-size: 11.5px;
      color: var(--primary);
      background: var(--primary-light);
      border: 1px solid var(--primary-border);
      padding: 1px 6px;
      border-radius: 4px;
      font-family: monospace;
      font-weight: 700;
    }
    .emp-row-status-right {
      display: flex;
      align-items: center;
      gap: 8px;
      flex-wrap: wrap;
    }
    .emp-row-deliverables {
      padding: 8px 0;
      border-top: 1px solid var(--card-border);
      border-bottom: 1px solid var(--card-border);
      margin-bottom: 10px;
    }
    .emp-row-review-box {
      background: var(--amber-50);
      border: 1px solid var(--amber-border);
      border-radius: 8px;
      padding: 14px 16px;
      margin-top: 10px;
    }
    .btn-toggle-all-tasks {
      background: #ffffff;
      border: 1.5px solid var(--slate-300);
      color: var(--slate-700);
      padding: 6px 14px;
      font-size: 12.5px;
      font-weight: 700;
      border-radius: 6px;
      cursor: pointer;
      transition: all 0.15s ease;
    }
    .btn-toggle-all-tasks:hover {
      background: var(--slate-50);
      color: var(--slate-900);
      border-color: var(--slate-400);
    }

    /* Admin 3-Tier Drilldown Hierarchy (Managers -> Tasks -> Employees & Reviews) */
    .admin-managers-list {
      display: flex;
      flex-direction: column;
      gap: 16px;
      margin-bottom: 32px;
    }
    .admin-mgr-card {
      background: var(--bg-card);
      border: 1px solid var(--card-border);
      border-radius: var(--radius-lg);
      box-shadow: var(--shadow-sm);
      overflow: hidden;
      transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
    }
    .admin-mgr-card:hover {
      border-color: var(--card-hover-border);
      box-shadow: var(--shadow-card);
    }
    .admin-mgr-header {
      padding: 18px 24px;
      background: #ffffff;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      cursor: pointer;
      user-select: none;
      transition: background 0.15s ease;
      flex-wrap: wrap;
    }
    .admin-mgr-header:hover {
      background: var(--slate-50);
    }
    .admin-mgr-identity {
      display: flex;
      align-items: center;
      gap: 14px;
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
    }
    .admin-mgr-name {
      font-size: 16.5px;
      font-weight: 800;
      color: var(--slate-900);
      letter-spacing: -0.01em;
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
      background: var(--purple-50);
      color: #7c3aed;
      border: 1px solid var(--purple-border);
      padding: 2px 8px;
      border-radius: 4px;
    }
    .admin-mgr-email {
      font-size: 12px;
      color: var(--slate-400);
      margin-top: 2px;
    }
    .admin-mgr-stats {
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
    }
    .admin-stat-chip {
      background: var(--slate-50);
      border: 1px solid var(--card-border);
      border-radius: 8px;
      padding: 6px 12px;
      display: flex;
      flex-direction: column;
      align-items: center;
      min-width: 82px;
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
    .admin-stat-chip-rating {
      background: var(--amber-50);
      border-color: var(--amber-border);
    }
    .admin-stat-chip-rating .admin-stat-chip-num {
      color: #b45309;
    }
    .admin-stat-chip-pending {
      background: #fffbeb;
      border-color: #fde68a;
    }
    .admin-stat-chip-pending .admin-stat-chip-num {
      color: #d97706;
    }
    .admin-mgr-expand-btn {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      padding: 8px 14px;
      border-radius: 8px;
      background: var(--primary-light);
      color: var(--primary);
      font-size: 13px;
      font-weight: 700;
      border: 1px solid var(--primary-border);
      transition: all 0.15s ease;
    }
    .admin-mgr-expand-btn:hover {
      background: var(--primary);
      color: #ffffff;
    }
    .admin-chevron {
      transition: transform 0.2s ease;
    }
    .admin-mgr-body {
      display: none;
      padding: 20px 24px;
      background: var(--slate-50);
      border-top: 1px solid var(--card-border);
    }
    .admin-tasks-subbar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      margin-bottom: 14px;
      padding-bottom: 8px;
      border-bottom: 1px solid var(--card-border);
    }
    .btn-sub-toggle {
      background: #ffffff;
      border: 1px solid var(--slate-300);
      color: var(--slate-700);
      font-size: 11.5px;
      font-weight: 700;
      padding: 4px 10px;
      border-radius: 5px;
      cursor: pointer;
      transition: all 0.15s ease;
    }
    .btn-sub-toggle:hover {
      background: var(--slate-100);
      color: var(--slate-900);
    }
    .admin-tasks-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    .admin-task-card {
      background: #ffffff;
      border: 1px solid var(--card-border);
      border-radius: 12px;
      box-shadow: var(--shadow-sm);
      overflow: hidden;
      transition: all 0.15s ease;
    }
    .admin-task-card:hover {
      border-color: var(--card-hover-border);
    }
    .admin-task-header {
      padding: 14px 18px;
      background: #ffffff;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      cursor: pointer;
      user-select: none;
      transition: background 0.15s ease;
      flex-wrap: wrap;
    }
    .admin-task-header:hover {
      background: var(--slate-50);
    }
    .admin-task-header-left {
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
    }
    .admin-task-title {
      font-size: 15px;
      font-weight: 800;
      color: var(--slate-900);
    }
    .admin-meta-pill {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      font-size: 12px;
      color: var(--slate-500);
      font-weight: 600;
    }
    .admin-assignees-count-pill {
      font-size: 12px;
      font-weight: 700;
      color: var(--primary);
      background: var(--primary-light);
      border: 1px solid var(--primary-border);
      padding: 2px 8px;
      border-radius: 5px;
    }
    .admin-task-header-right {
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
    }
    .admin-task-progress-badge {
      font-size: 12px;
      font-weight: 700;
      background: var(--slate-100);
      color: var(--slate-700);
      border: 1px solid var(--slate-300);
      padding: 3px 9px;
      border-radius: 20px;
    }
    .admin-task-progress-badge.progress-done {
      background: var(--emerald-50);
      color: var(--emerald-text);
      border-color: var(--emerald-border);
    }
    .admin-rating-pill {
      background: var(--amber-50);
      color: #b45309;
      border: 1px solid var(--amber-border);
      font-weight: 800;
      font-size: 12px;
      padding: 3px 9px;
      border-radius: 6px;
    }
    .admin-task-expand-btn {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 5px 12px;
      border-radius: 6px;
      background: #ffffff;
      border: 1.5px solid var(--slate-300);
      color: var(--slate-700);
      font-size: 12px;
      font-weight: 700;
      transition: all 0.15s ease;
    }
    .admin-task-expand-btn:hover {
      background: var(--slate-50);
      color: var(--slate-900);
      border-color: var(--slate-400);
    }
    .admin-task-desc-row {
      padding: 12px 18px;
      background: #ffffff;
      border-top: 1px solid var(--slate-100);
    }
    .admin-task-body {
      display: none;
      padding: 16px 18px;
      background: var(--slate-50);
      border-top: 1px solid var(--card-border);
    }
    .admin-emp-cards-list {
      display: flex;
      flex-direction: column;
      gap: 10px;
    }
    .admin-emp-row-card {
      background: #ffffff;
      border: 1px solid var(--card-border);
      border-radius: 10px;
      padding: 14px 16px;
      box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
    }
    .admin-emp-top-bar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
      margin-bottom: 8px;
    }
    .admin-emp-identity {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .admin-emp-avatar {
      width: 32px;
      height: 32px;
      border-radius: 8px;
      background: var(--primary-light);
      color: var(--primary);
      font-weight: 800;
      font-size: 13px;
      display: flex;
      align-items: center;
      justify-content: center;
      border: 1px solid var(--primary-border);
      flex-shrink: 0;
    }
    .admin-emp-name {
      font-size: 14px;
      font-weight: 800;
      color: var(--slate-900);
    }
    .admin-emp-code {
      font-family: monospace;
      font-size: 11.5px;
      font-weight: 700;
      color: var(--primary);
      background: var(--primary-light);
      border: 1px solid var(--primary-border);
      padding: 1px 6px;
      border-radius: 4px;
    }
    .admin-emp-dept {
      font-size: 11px;
      font-weight: 700;
      background: var(--slate-100);
      color: var(--slate-600);
      border: 1px solid var(--slate-300);
      padding: 1px 6px;
      border-radius: 4px;
    }
    .admin-emp-deliverables-row {
      padding: 8px 0;
      border-top: 1px solid var(--slate-100);
      border-bottom: 1px solid var(--slate-100);
      margin-top: 6px;
      margin-bottom: 8px;
    }
    .btn-file-chip {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 10px;
      border-radius: 6px;
      font-size: 11.5px;
      font-weight: 700;
      text-decoration: none;
      background: var(--slate-100);
      border: 1px solid var(--slate-300);
      color: var(--slate-700);
      max-width: 260px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      transition: all 0.15s ease;
    }
    .btn-file-chip:hover {
      background: #ffffff;
      border-color: var(--primary);
      color: var(--primary);
      transform: translateY(-1px);
    }
    .admin-emp-comment-box {
      font-size: 12.5px;
      color: var(--slate-700);
      background: var(--slate-50);
      padding: 8px 12px;
      border-radius: 6px;
      border: 1px solid var(--card-border);
      margin-bottom: 6px;
      line-height: 1.5;
    }
    .admin-review-box-reviewed {
      background: var(--amber-50);
      border: 1px solid var(--amber-border);
      border-radius: 8px;
      padding: 12px 14px;
    }
    .admin-review-box-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
      margin-bottom: 6px;
    }
    .admin-review-feedback-quote {
      font-size: 13px;
      color: var(--amber-text);
      line-height: 1.5;
      font-style: italic;
    }
    .admin-review-box-pending {
      display: flex;
      align-items: center;
      gap: 8px;
      background: #fffbeb;
      border: 1px dashed #fde68a;
      border-radius: 6px;
      padding: 9px 12px;
      font-size: 12.5px;
      color: #92400e;
    }
    .admin-review-box-working {
      display: flex;
      align-items: center;
      gap: 8px;
      background: var(--slate-50);
      border: 1px dashed var(--slate-300);
      border-radius: 6px;
      padding: 9px 12px;
      font-size: 12.5px;
      color: var(--slate-500);
    }
    .admin-empty-nested {
      padding: 20px;
      text-align: center;
      color: var(--slate-400);
      font-size: 13px;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
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
  <!-- Topbar -->
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
        <a href="<%= ctx %>/employeePerformance" class="btn-sidebar-link ratings-link on">
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
        <a href="<%= ctx %>/employeePerformance" class="btn-sidebar-link ratings-link on">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon></svg>
          Employee Ratings &amp; Performance
        </a>
      </div>
    </div>
    <% } %>
  </aside>

  <!-- Workspace Area -->
  <div class="workspace">
    <header class="topbar">
      <h1 class="page-title">Performance &amp; Review Management Center</h1>
      <div class="user-ctrls">
        <div class="user-badge">
          <div class="user-avatar"><%= userInitial %></div>
          <span class="user-info-text"><%= userName %> (<%= roleBadge %>)</span>
        </div>
        <a class="btn-signout" href="logout">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
          Logout
        </a>
      </div>
    </header>

    <div class="content-wrap" style="max-width:1360px; width:100%; padding:24px 32px 48px; margin:0 auto;">
    <!-- Success & Error Alert Banners -->
    <% 
       String succMsg = (String) request.getAttribute("successMessage");
       if (succMsg == null) succMsg = request.getParameter("msg");
       String errMsg = (String) request.getAttribute("errorMessage");
       if (errMsg == null) errMsg = request.getParameter("err");
    %>
    <% if (succMsg != null && !succMsg.isEmpty()) { %>
      <div style="background:#ecfdf5; border:1px solid #a7f3d0; border-radius:10px; padding:12px 18px; margin-bottom:18px; display:flex; align-items:center; gap:10px; color:#065f46; font-size:14px; font-weight:700;">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg>
        <span><%= succMsg %></span>
      </div>
    <% } %>
    <% if (errMsg != null && !errMsg.isEmpty()) { %>
      <div style="background:#fef2f2; border:1px solid #fecaca; border-radius:10px; padding:12px 18px; margin-bottom:18px; display:flex; align-items:center; gap:10px; color:#991b1b; font-size:14px; font-weight:700;">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
        <span><%= errMsg %></span>
      </div>
    <% } %>

    <!-- Page Header -->
    <div class="page-header">
      <div>
        <h1 class="page-title">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="#f59e0b" stroke="#d97706" stroke-width="1.5">
            <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
          </svg>
          Performance &amp; Review Management Center
        </h1>
        <p class="page-subtitle">
          <% if (isHr) { %>
            Executive audit of employee task deliverables, performance ratings, and evaluations conducted by managers across the organization.
          <% } else { %>
            Team performance tracking center: monitor total assigned tasks, inspect employee deliverables, and update review ratings and feedback.
          <% } %>
        </p>
      </div>
    </div>

    <!-- KPI Metric Cards -->
    <div class="kpi-grid">
      <div class="kpi-card">
        <div class="kpi-icon-box kpi-icon-amber">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
            <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
          </svg>
        </div>
        <div class="kpi-meta">
          <span class="kpi-label"><%= isHr ? "Organization Avg Rating" : "Team Avg Rating" %></span>
          <div class="kpi-num" style="color:#b45309;">
            <%= totalReviewed > 0 ? String.format("%.1f", orgAvg) : "Unrated" %> <span style="font-size:18px; color:#f59e0b;">★</span>
          </div>
          <span class="kpi-subtext">Across <%= totalReviewed %> evaluated deliverable<%= totalReviewed == 1 ? "" : "s" %></span>
        </div>
      </div>

      <% if (!isHr) { %>
      <div class="kpi-card">
        <div class="kpi-icon-box kpi-icon-blue">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
            <rect x="2" y="7" width="20" height="14" rx="2" ry="2"></rect>
            <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path>
          </svg>
        </div>
        <div class="kpi-meta">
          <span class="kpi-label">Total Tasks</span>
          <div class="kpi-num" style="color:#2563eb;"><%= uniqueTasks %></div>
          <span class="kpi-subtext"><%= totalAssignments %> Total Assignments</span>
        </div>
      </div>
      <% } %>

      <div class="kpi-card">
        <div class="kpi-icon-box kpi-icon-emerald">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
            <polyline points="20 6 9 17 4 12"></polyline>
          </svg>
        </div>
        <div class="kpi-meta">
          <span class="kpi-label"><%= isHr ? "Tasks Reviewed" : "Tasks Evaluated" %></span>
          <div class="kpi-num" style="color:#059669;"><%= totalReviewed %></div>
          <span class="kpi-subtext"><%= isHr ? "Completed evaluations with feedback" : "Deliverables with rating & feedback" %></span>
        </div>
      </div>

      <% if (isHr) { %>
      <div class="kpi-card">
        <div class="kpi-icon-box kpi-icon-purple">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
            <rect x="2" y="7" width="20" height="14" rx="2" ry="2"></rect>
            <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path>
          </svg>
        </div>
        <div class="kpi-meta">
          <span class="kpi-label">Active Reviewing Managers</span>
          <div class="kpi-num" style="color:#6d28d9;"><%= managerCount %></div>
          <span class="kpi-subtext">Managers conducting task evaluations</span>
        </div>
      </div>
      <% } else { %>
      <div class="kpi-card">
        <div class="kpi-icon-box <%= pendingRev > 0 ? "kpi-icon-amber" : "kpi-icon-blue" %>">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
            <circle cx="12" cy="12" r="10"></circle>
            <polyline points="12 6 12 12 16 14"></polyline>
          </svg>
        </div>
        <div class="kpi-meta">
          <span class="kpi-label">Pending Your Review</span>
          <div class="kpi-num" style="color:<%= pendingRev > 0 ? "#d97706" : "#2563eb" %>;"><%= pendingRev %></div>
          <span class="kpi-subtext">Awaiting Completion: <strong><%= awaitingComp %></strong></span>
        </div>
      </div>
      <% } %>

      <% if (isHr) { %>
      <div class="kpi-card">
        <div class="kpi-icon-box kpi-icon-blue">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
            <circle cx="9" cy="7" r="4"></circle>
            <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
            <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
          </svg>
        </div>
        <div class="kpi-meta">
          <span class="kpi-label">High Performers</span>
          <div class="kpi-num" style="color:#2563eb;"><%= highCount %></div>
          <span class="kpi-subtext">Maintained ratings of 4.0 or higher</span>
        </div>
      </div>
      <% } %>
    </div>

    <!-- Mode Switcher Tabs (Managers Only) -->
    <% if (!isHr) { %>
    <div class="view-switcher-container">
      <div class="view-segmented-tabs">
        <button type="button" class="tab-btn <%= "task".equalsIgnoreCase(viewMode) ? "active" : "" %>" data-mode="task" onclick="switchViewMode('task')">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
            <polyline points="9 11 12 14 22 4"></polyline>
            <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path>
          </svg>
          Tasks &amp; Employee Reviews
          <span class="tab-badge"><%= taskGroupsCount %></span>
        </button>

        <button type="button" class="tab-btn <%= "employee".equalsIgnoreCase(viewMode) ? "active" : "" %>" data-mode="employee" onclick="switchViewMode('employee')">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
            <circle cx="9" cy="7" r="4"></circle>
          </svg>
          Employee Scorecards
          <span class="tab-badge"><%= empCount %></span>
        </button>
      </div>

      <!-- Problem B8: Active Filter shows both department and status/rating filter -->
      <div style="font-size:12.5px; color:var(--slate-500);">
        Active Filter: <b><%= "ALL".equalsIgnoreCase(selectedDept) ? "All Departments" : selectedDept.trim().toUpperCase() %></b>
        &bull; Status: <b><%= "ALL".equalsIgnoreCase(selectedStatus) ? "All Statuses" : selectedStatus %></b>
        <% if (!"ALL".equalsIgnoreCase(selectedRating)) { %>
          &bull; Rating: <b><%= selectedRating %>★</b>
        <% } %>
      </div>
    </div>
    <% } %>

    <!-- Filter Bar (Problem C1, C2) -->
    <div class="filter-card">
      <form action="employeePerformance" method="get" class="filter-form" id="filterForm">
        <input type="hidden" name="view" id="filterViewMode" value="<%= viewMode %>">

        <!-- Search with visible label (Problem C2) -->
        <div class="filter-field-group" style="flex:1; min-width:220px;">
          <label for="adminSearchInput" class="filter-field-label">Search</label>
          <input type="text" name="keyword" id="adminSearchInput" class="filter-input" aria-label="Search by employee, task or department" placeholder="<%= isHr ? "Search by Manager, Task, Employee or Department..." : "Search by Employee, ID, or Department..." %>" value="<%= keyword %>">
        </div>

        <!-- Manager Filter (Admin only) with visible label (Problem C2) -->
        <% if (isHr) { %>
        <div class="filter-field-group">
          <label for="mgrSelect" class="filter-field-label">Manager</label>
          <select name="managerId" id="mgrSelect" class="filter-select" aria-label="Filter by Manager">
            <option value="ALL" <%= "ALL".equalsIgnoreCase(selectedManager) ? "selected" : "" %>>All Managers</option>
            <% if (activeManagers != null) {
                 for (Manager m : activeManagers) {
                   String sel = selectedManager.equalsIgnoreCase(m.getManagerId()) ? "selected" : "";
            %>
              <option value="<%= m.getManagerId() %>" <%= sel %>>
                <%= m.getName() %> (<%= m.getManagerId() %>) <%= m.getDepartment() != null ? "• " + m.getDepartment().trim().toUpperCase() : "" %>
              </option>
            <%   }
               } %>
          </select>
        </div>
        <% } %>

        <!-- Department Filter with visible label (Problem C2, B2) -->
        <div class="filter-field-group">
          <label for="deptSelect" class="filter-field-label">Department</label>
          <select name="department" id="deptSelect" class="filter-select" aria-label="Filter by Department">
            <option value="ALL" <%= "ALL".equalsIgnoreCase(selectedDept) ? "selected" : "" %>>All Departments</option>
            <% if (distinctDepartments != null) {
                 for (String d : distinctDepartments) {
                   String normD = d != null ? d.trim().toUpperCase() : "";
                   String sel = selectedDept.equalsIgnoreCase(d) ? "selected" : "";
            %>
              <option value="<%= d %>" <%= sel %>><%= normD %></option>
            <%   }
               } %>
          </select>
        </div>

        <!-- Review Status Filter (Problem C1, C2) -->
        <div class="filter-field-group">
          <label for="statusSelect" class="filter-field-label">Review Status</label>
          <select name="status" id="statusSelect" class="filter-select" aria-label="Filter by Review Status">
            <option value="ALL" <%= "ALL".equalsIgnoreCase(selectedStatus) ? "selected" : "" %>>All Review Statuses</option>
            <option value="AWAITING COMPLETION" <%= "AWAITING COMPLETION".equalsIgnoreCase(selectedStatus) ? "selected" : "" %>>Awaiting Completion</option>
            <option value="PENDING REVIEW" <%= "PENDING REVIEW".equalsIgnoreCase(selectedStatus) ? "selected" : "" %>>Pending Review</option>
            <option value="REVIEWED" <%= "REVIEWED".equalsIgnoreCase(selectedStatus) ? "selected" : "" %>>Reviewed</option>
          </select>
        </div>

        <!-- Rating Filter with visible label (Problem C1, C2) -->
        <div class="filter-field-group">
          <label for="ratingSelect" class="filter-field-label">Rating</label>
          <select name="rating" id="ratingSelect" class="filter-select" aria-label="Filter by Star Rating">
            <option value="ALL" <%= "ALL".equalsIgnoreCase(selectedRating) ? "selected" : "" %>>All Ratings</option>
            <option value="5" <%= "5".equalsIgnoreCase(selectedRating) ? "selected" : "" %>>★★★★★ 5 Stars (Outstanding)</option>
            <option value="4" <%= "4".equalsIgnoreCase(selectedRating) ? "selected" : "" %>>★★★★☆ 4 Stars (Very Good)</option>
            <option value="3" <%= "3".equalsIgnoreCase(selectedRating) ? "selected" : "" %>>★★★☆☆ 3 Stars (Good)</option>
            <option value="1-2" <%= "1-2".equalsIgnoreCase(selectedRating) ? "selected" : "" %>>★/★★ 1-2 Stars (Needs Improvement)</option>
          </select>
        </div>

        <div class="filter-field-group" style="align-self:flex-end;">
          <button type="submit" class="btn-filter-apply">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"></polygon></svg>
            Filter Reviews
          </button>
        </div>
        <% if (!keyword.isEmpty() || !"ALL".equalsIgnoreCase(selectedDept) || !"ALL".equalsIgnoreCase(selectedManager) || !"ALL".equalsIgnoreCase(selectedStatus) || !"ALL".equalsIgnoreCase(selectedRating)) { %>
          <div class="filter-field-group" style="align-self:flex-end;">
            <a href="employeePerformance?view=<%= viewMode %>" class="btn-filter-reset">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"></path><polyline points="3 3 3 8 8 8"></polyline></svg>
              Reset
            </a>
          </div>
        <% } %>
      </form>
    </div>



    <% if (isHr) { %>
    <!-- ======================================================== -->
    <!-- ADMIN 3-TIER DRILLDOWN HIERARCHY: MANAGERS -> TASKS -> EMPLOYEES & REVIEWS -->
    <!-- ======================================================== -->
    <div class="admin-hierarchy-section">
      <!-- Section Header -->
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:18px; flex-wrap:wrap; gap:12px;">
        <div>
          <h2 style="font-size:18.5px; font-weight:800; color:var(--slate-900); display:flex; align-items:center; gap:8px;">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" color="#2563eb">
              <rect x="2" y="7" width="20" height="14" rx="2" ry="2"></rect>
              <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path>
            </svg>
            Managers &amp; Task Performance Hierarchy
          </h2>
          <p style="font-size:13px; color:var(--slate-500); margin-top:2px;">
            Expand any manager to view their created tasks, then expand each task to inspect employee deliverables, statuses, and review ratings.
          </p>
        </div>
        <div style="display:flex; gap:8px;">
          <button type="button" class="btn-toggle-all-tasks" onclick="toggleAllAdminManagers(true)">
            Expand All Managers
          </button>
          <button type="button" class="btn-toggle-all-tasks" onclick="toggleAllAdminManagers(false)">
            Collapse All Managers
          </button>
        </div>
      </div>

      <!-- Level 1: Managers List -->
      <% if (managerSummaries == null || managerSummaries.isEmpty()) { %>
        <div class="empty-state">
          <div class="empty-icon-circle">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
          </div>
          <h3 style="font-size:16px; font-weight:800; color:var(--slate-800); margin-bottom:4px;">No Managers Found</h3>
          <p style="font-size:13.5px; color:var(--slate-500);">No managers match your search or filter criteria.</p>
        </div>
      <% } else { %>
        <div class="admin-managers-list" id="adminManagersList">
          <% int mIdx = 0;
             for (ManagerReviewSummary ms : managerSummaries) {
               mIdx++;
               String mgrBodyId = "admin_mgr_body_" + mIdx;
               String mgrChevronId = "admin_mgr_chevron_" + mIdx;
               List<TaskGroup> mgrTaskGroups = ms.getTaskGroups();
          %>
            <div class="admin-mgr-card" data-mgr-id="<%= ms.getManagerId() %>" data-mgr-name="<%= ms.getManagerName() != null ? ms.getManagerName().toLowerCase() : "" %>">
              <!-- Level 1 Header: Manager Profile & Metrics Banner -->
              <div class="admin-mgr-header" onclick="toggleAdminManager('<%= mgrBodyId %>', '<%= mgrChevronId %>')">
                <div class="admin-mgr-identity">
                  <div class="admin-mgr-avatar">
                    <%= ms.getManagerName() != null && !ms.getManagerName().isEmpty() ? ms.getManagerName().substring(0, 1).toUpperCase() : "M" %>
                  </div>
                  <div>
                    <div style="display:flex; align-items:center; gap:8px; flex-wrap:wrap;">
                      <span class="admin-mgr-name"><%= ms.getManagerName() %></span>
                      <span class="admin-mgr-code"><%= ms.getManagerId() %></span>
                      <% if (ms.getDepartment() != null && !ms.getDepartment().trim().isEmpty()) { %>
                        <span class="admin-mgr-dept"><%= ms.getDepartment() %></span>
                      <% } %>
                    </div>
                    <% if (ms.getEmail() != null && !ms.getEmail().trim().isEmpty()) { %>
                      <div class="admin-mgr-email"><%= ms.getEmail() %></div>
                    <% } %>
                  </div>
                </div>

                <!-- Manager Aggregated Stats Chips -->
                <div class="admin-mgr-stats">
                  <div class="admin-stat-chip">
                    <span class="admin-stat-chip-num"><%= ms.getDistinctTaskCount() %></span>
                    <span class="admin-stat-chip-lbl">Tasks Created</span>
                  </div>
                  <div class="admin-stat-chip">
                    <span class="admin-stat-chip-num" style="color:var(--primary);"><%= ms.getTotalEmployeesAssigned() %></span>
                    <span class="admin-stat-chip-lbl">Assignees</span>
                  </div>
                  <div class="admin-stat-chip">
                    <span class="admin-stat-chip-num" style="color:#059669;"><%= ms.getCompletedTasksCount() %></span>
                    <span class="admin-stat-chip-lbl">Completed</span>
                  </div>
                  <div class="admin-stat-chip">
                    <span class="admin-stat-chip-num" style="color:#2563eb;"><%= ms.getTotalReviewedTasks() %></span>
                    <span class="admin-stat-chip-lbl">Evaluated</span>
                  </div>
                  <div class="admin-stat-chip <%= ms.getTotalReviewedTasks() > 0 ? "admin-stat-chip-rating" : "" %>">
                    <span class="admin-stat-chip-num">
                      <% if (ms.getTotalReviewedTasks() > 0) { %>
                        ★ <%= ms.getFormattedAvgRating() %>
                      <% } else { %>
                        —
                      <% } %>
                    </span>
                    <span class="admin-stat-chip-lbl">Avg Rating</span>
                  </div>
                  <% if (ms.getPendingReviewCount() > 0) { %>
                    <div class="admin-stat-chip admin-stat-chip-pending" title="Completed by employee, waiting for manager evaluation">
                      <span class="admin-stat-chip-num"><%= ms.getPendingReviewCount() %></span>
                      <span class="admin-stat-chip-lbl">Pending Review</span>
                    </div>
                  <% } %>

                  <span class="admin-mgr-expand-btn">
                    <span>Tasks (<%= ms.getDistinctTaskCount() %>)</span>
                    <span class="admin-chevron" id="<%= mgrChevronId %>">&#9662;</span>
                  </span>
                </div>
              </div>

              <!-- Level 2 Body: Tasks Created by this Manager -->
              <div class="admin-mgr-body" id="<%= mgrBodyId %>">
                <div class="admin-tasks-subbar">
                  <div style="font-size:13px; font-weight:700; color:var(--slate-700); display:flex; align-items:center; gap:6px;">
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" color="#2563eb">
                      <polyline points="9 11 12 14 22 4"></polyline>
                      <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path>
                    </svg>
                    Tasks Created by <strong><%= ms.getManagerName() %></strong> (<%= mgrTaskGroups.size() %>)
                  </div>
                  <% if (!mgrTaskGroups.isEmpty()) { %>
                    <div style="display:flex; gap:6px;">
                      <button type="button" class="btn-sub-toggle" onclick="toggleManagerTasks('<%= mgrBodyId %>', true)">
                        Expand All Tasks
                      </button>
                      <button type="button" class="btn-sub-toggle" onclick="toggleManagerTasks('<%= mgrBodyId %>', false)">
                        Collapse All Tasks
                      </button>
                    </div>
                  <% } %>
                </div>

                <% if (mgrTaskGroups.isEmpty()) { %>
                  <div class="admin-empty-nested">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
                    No tasks have been created by <%= ms.getManagerName() %> matching the current filters.
                  </div>
                <% } else { %>
                  <div class="admin-tasks-list">
                    <% int tIdx = 0;
                       for (TaskGroup tg : mgrTaskGroups) {
                         tIdx++;
                         String taskBodyId = "admin_task_body_" + mIdx + "_" + tIdx;
                         String taskChevronId = "admin_task_chevron_" + mIdx + "_" + tIdx;
                         List<Task> empTasks = tg.getEmployeeTasks();
                    %>
                      <div class="admin-task-card">
                        <!-- Level 2 Task Header (Clickable to Expand Level 3) -->
                        <div class="admin-task-header" onclick="toggleAdminTask('<%= taskBodyId %>', '<%= taskChevronId %>')">
                          <div class="admin-task-header-left">
                            <span class="tg-seq-pill">Task <%= tIdx %></span>
                            <span class="admin-task-title"><%= tg.getTitle() %></span>
                            <span class="priority-pill <%= tg.getPriorityBadgeClass() %>"><%= tg.getPriority() %></span>
                            <% if (tg.getDepartment() != null && !tg.getDepartment().trim().isEmpty()) { %>
                              <span class="admin-emp-dept"><%= tg.getDepartment() %></span>
                            <% } %>
                            <span class="admin-assignees-count-pill">
                              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="display:inline; vertical-align:-1px;"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle></svg>
                              <%= tg.getTotalEmployees() %> Assignee<%= tg.getTotalEmployees() == 1 ? "" : "s" %>
                            </span>
                            <% if (tg.getDueDate() != null) { %>
                              <span class="admin-meta-pill">
                                <strong>Due:</strong> <%= tg.getFormattedDueDate() %>
                              </span>
                            <% } %>
                          </div>

                          <div class="admin-task-header-right">
                            <span class="admin-task-progress-badge <%= tg.getCompletedCount() == tg.getTotalEmployees() && tg.getTotalEmployees() > 0 ? "progress-done" : "" %>">
                              <%= tg.getCompletedCount() %>/<%= tg.getTotalEmployees() %> Completed
                            </span>
                            <span class="admin-task-progress-badge">
                              <%= tg.getReviewedCount() %>/<%= tg.getTotalEmployees() %> Evaluated
                            </span>
                            <% if (tg.getReviewedCount() > 0) { %>
                              <span class="admin-rating-pill">
                                ★ <%= tg.getFormattedAvgRating() %> / 5.0
                              </span>
                            <% } %>
                            <span class="admin-task-expand-btn">
                              <span>View Employees &amp; Status</span>
                              <span class="admin-chevron" id="<%= taskChevronId %>">&#9662;</span>
                            </span>
                          </div>
                        </div>

                        <!-- Task Description & Work Spec attachments row (if present) -->
                        <% if ((tg.getDescription() != null && !tg.getDescription().trim().isEmpty()) || tg.hasWorkFile()) { %>
                          <div class="admin-task-desc-row">
                            <% if (tg.getDescription() != null && !tg.getDescription().trim().isEmpty()) { %>
                              <div style="font-size:12.5px; color:var(--slate-600); margin-bottom:6px; line-height:1.45;">
                                <strong>Specification:</strong> <%= tg.getDescription() %>
                              </div>
                            <% } %>
                            <% if (tg.hasWorkFile() && !empTasks.isEmpty()) { 
                                 Task refTask = empTasks.get(0);
                            %>
                              <div style="display:flex; align-items:center; gap:8px; font-size:12px; flex-wrap:wrap;">
                                <strong style="color:var(--slate-500);">Specification Attachments:</strong>
                                <% for (String fn : tg.getWorkFileList()) { 
                                     String fnOrig = util.FileStorageUtil.getOriginalFileName(fn);
                                %>
                                  <a href="downloadTaskFile?taskId=<%= refTask.getId() %>&type=work&file=<%= URLEncoder.encode(fn, StandardCharsets.UTF_8) %>" class="btn-file-chip" title="Download Specification Deliverable">
                                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline></svg>
                                    <%= fnOrig %>
                                  </a>
                                <% } %>
                              </div>
                            <% } %>
                          </div>
                        <% } %>

                        <!-- Level 3 Body: Assigned Employees, Statuses, Deliverables & Reviews -->
                        <div class="admin-task-body" id="<%= taskBodyId %>">
                          <div style="font-size:12px; font-weight:800; color:var(--slate-600); text-transform:uppercase; letter-spacing:0.04em; margin-bottom:10px; display:flex; justify-content:space-between; align-items:center;">
                            <span>Assigned Employees (<%= empTasks.size() %>)</span>
                            <span style="font-weight:600; text-transform:none; color:var(--slate-500);">Inspect individual deliverables, progress remarks, and manager reviews</span>
                          </div>

                          <div class="admin-emp-cards-list">
                            <% for (Task empTask : empTasks) { %>
                              <div class="admin-emp-row-card">
                                <!-- Employee Top Bar -->
                                <div class="admin-emp-top-bar">
                                  <div class="admin-emp-identity">
                                    <div class="admin-emp-avatar">
                                      <%= empTask.getAssignedToName() != null && !empTask.getAssignedToName().isEmpty() ? empTask.getAssignedToName().substring(0, 1).toUpperCase() : "E" %>
                                    </div>
                                    <div>
                                      <div style="display:flex; align-items:center; gap:8px; flex-wrap:wrap;">
                                        <span class="admin-emp-name"><%= empTask.getAssignedToName() != null ? empTask.getAssignedToName() : "Employee" %></span>
                                        <span class="admin-emp-code"><%= empTask.getAssignedTo() %></span>
                                        <% if (empTask.getDepartment() != null && !empTask.getDepartment().trim().isEmpty()) { %>
                                          <span class="admin-emp-dept"><%= empTask.getDepartment() %></span>
                                        <% } %>
                                        <span style="font-family:monospace; font-size:11px; color:var(--slate-400);"><%= empTask.getFormattedId() %></span>
                                      </div>
                                    </div>
                                  </div>

                                  <!-- Right: Review Status Badge & Star Rating (Problem B4, B5) -->
                                  <div style="display:flex; align-items:center; gap:10px; flex-wrap:wrap;">
                                    <span class="badge <%= empTask.getReviewStatusBadgeClass() %>"><%= empTask.getReviewStatus() %></span>

                                    <% if (empTask.isReviewCompleted()) { %>
                                      <span class="task-rating-display" title="<%= empTask.getPerformanceLabel() %>">
                                        <%= empTask.getRatingStars() %> (<%= empTask.getRating() %>/5)
                                      </span>
                                    <% } %>
                                  </div>
                                </div>

                                <!-- Employee Deliverables / Proof files -->
                                <% if (empTask.hasWorkProofFile()) { %>
                                  <div class="admin-emp-deliverables-row">
                                    <div style="display:flex; align-items:center; gap:8px; flex-wrap:wrap; font-size:12px;">
                                      <strong style="color:#047857; display:flex; align-items:center; gap:4px;">
                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg>
                                        Submitted Deliverable / Proof:
                                      </strong>
                                      <% for (String pf : empTask.getWorkProofFileList()) { 
                                           String pfOrig = util.FileStorageUtil.getOriginalFileName(pf);
                                      %>
                                        <a href="downloadTaskFile?taskId=<%= empTask.getId() %>&type=proof&file=<%= URLEncoder.encode(pf, StandardCharsets.UTF_8) %>" class="btn-file-chip" style="background:#ecfdf5; border-color:#a7f3d0; color:#065f46;" title="Download <%= pfOrig %>">
                                          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                                          <%= pfOrig %>
                                        </a>
                                      <% } %>
                                    </div>
                                  </div>
                                <% } %>

                                <!-- Employee Remarks / Notes -->
                                <% if (empTask.getEmployeeComment() != null && !empTask.getEmployeeComment().trim().isEmpty()) { %>
                                  <div class="admin-emp-comment-box">
                                    <strong>Employee Submission Notes:</strong> "<%= empTask.getEmployeeComment() %>"
                                  </div>
                                <% } %>

                                <!-- Manager Review & Performance Rating Block -->
                                <% if (empTask.isReviewed()) { %>
                                  <div class="admin-review-box-reviewed">
                                    <div class="admin-review-box-header">
                                      <div style="font-weight:800; font-size:12.5px; color:#92400e; display:flex; align-items:center; gap:6px;">
                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="#f59e0b" stroke="#f59e0b"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon></svg>
                                        Manager Evaluation by <%= empTask.getReviewedByName() %>
                                        <% if (!empTask.getFormattedReviewedAt().isEmpty()) { %>
                                          <span style="font-weight:600; color:#b45309; font-size:11.5px;">on <%= empTask.getFormattedReviewedAt() %></span>
                                        <% } %>
                                      </div>
                                      <% if (empTask.hasRating()) { %>
                                        <div style="font-weight:800; font-size:13px; color:#b45309;">
                                          <%= empTask.getRatingStars() %> <%= empTask.getRating() %>/5.0 (<%= empTask.getPerformanceLabel() %>)
                                        </div>
                                      <% } %>
                                    </div>
                                    <% if (empTask.hasFeedback()) { %>
                                      <div class="admin-review-feedback-quote">
                                        "<%= empTask.getFeedback() %>"
                                      </div>
                                    <% } %>
                                  </div>
                                <% } else if (Task.STATUS_COMPLETED.equalsIgnoreCase(empTask.getStatus())) { %>
                                  <div class="admin-review-box-pending">
                                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
                                    <span><strong>Pending Manager Review:</strong> Employee completed this task and submitted deliverables. Awaiting evaluation by Manager <%= ms.getManagerName() %>.</span>
                                  </div>
                                <% } else { %>
                                  <div class="admin-review-box-working">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
                                    <span><strong>Task In Progress:</strong> Employee is actively working on this assignment. Status: <%= empTask.getStatus() %>.</span>
                                  </div>
                                <% } %>
                              </div>
                            <% } %>
                          </div>
                        </div>
                      </div>
                    <% } %>
                  </div>
                <% } %>
              </div>
            </div>
          <% } %>
        </div>
      <% } %>
    </div>
    <% } else { %>

    <!-- ========================================== -->
    <!-- VIEW 1: TASKS & EMPLOYEE RATINGS (Grouped by Task) -->
    <!-- ========================================== -->
    <div id="panel_task" class="view-panel <%= "task".equalsIgnoreCase(viewMode) ? "active" : "" %>">
      <!-- Section Header -->
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px; flex-wrap:wrap; gap:12px;">
        <div>
          <h2 style="font-size:18px; font-weight:800; color:var(--slate-900); display:flex; align-items:center; gap:8px;">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" color="#2563eb">
              <polyline points="9 11 12 14 22 4"></polyline>
              <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path>
            </svg>
            Tasks &amp; Assigned Employee Reviews
          </h2>
          <p style="font-size:13px; color:var(--slate-500); margin-top:2px;">
            Under each task, inspect all assigned employees, review their deliverables, and update or submit performance ratings.
          </p>
        </div>
        <div style="display:flex; gap:8px;">
          <button type="button" class="btn-toggle-all-tasks" onclick="toggleAllTaskPanels(true)">
            Expand All
          </button>
          <button type="button" class="btn-toggle-all-tasks" onclick="toggleAllTaskPanels(false)">
            Collapse All
          </button>
        </div>
      </div>

      <% if (taskGroups == null || taskGroups.isEmpty()) { %>
        <div class="empty-state">
          <div class="empty-icon-circle">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
          </div>
          <h3 style="font-size:16px; font-weight:800; color:var(--slate-800); margin-bottom:4px;">No Tasks Found</h3>
          <p style="font-size:13.5px; color:var(--slate-500);">No tasks match your filter criteria.</p>
        </div>
      <% } else { %>
        <div class="task-groups-list">
          <% int tgIdx = 0;
             for (TaskGroup tg : taskGroups) {
               tgIdx++;
               String tgPanelId = "tg_panel_" + tgIdx;
               String tgChevronId = "tg_chevron_" + tgIdx;
          %>
            <div class="task-group-card">
              <!-- Task Group Banner Header (Clickable to Expand/Collapse, Problem C6) -->
              <div class="task-group-header" id="tg_header_<%= tgIdx %>" role="button" tabindex="0" aria-expanded="true" onclick="toggleGroupPanel('<%= tgPanelId %>', '<%= tgChevronId %>', this)" onkeydown="if(event.key==='Enter'||event.key===' '){toggleGroupPanel('<%= tgPanelId %>', '<%= tgChevronId %>', this);event.preventDefault();}">
                <div class="tg-header-left">
                  <span class="tg-seq-pill">Task <%= tgIdx %></span>
                  <span class="tg-title-text"><%= tg.getTitle() %></span>
                  <span class="badge badge-primary" style="font-size:11px;">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle></svg>
                    <%= tg.getTotalEmployees() %> Employee<%= tg.getTotalEmployees() == 1 ? "" : "s" %> Assigned
                  </span>
                  <% if (tg.getDepartment() != null && !tg.getDepartment().isEmpty()) { %>
                    <span class="tg-dept-pill"><%= tg.getDepartment().trim().toUpperCase() %></span>
                  <% } %>
                  <% if (tg.getPriority() != null) { %>
                    <span class="priority-pill <%= tg.getPriorityBadgeClass() %>"><%= tg.getPriority() %></span>
                  <% } %>
                </div>

                <div class="tg-header-right">
                  <div class="tg-stats-chips">
                    <span class="tg-stat-item">
                      <strong><%= tg.getCompletedCount() %>/<%= tg.getTotalEmployees() %></strong> Completed
                    </span>
                    <span class="tg-stat-item">
                      <strong><%= tg.getReviewedCount() %>/<%= tg.getTotalEmployees() %></strong> Evaluated
                    </span>
                    <% if (tg.getReviewedCount() > 0) { %>
                      <span class="tg-stat-rating">
                        ★ <%= tg.getFormattedAvgRating() %> / 5.0
                      </span>
                    <% } else if (tg.getPendingReviewCount() > 0) { %>
                      <span class="tg-stat-pending">Pending Review</span>
                    <% } else { %>
                      <span class="tg-stat-item">Awaiting Completion</span>
                    <% } %>
                  </div>
                  <span class="tg-expand-btn">
                    <span>View Employees &amp; Ratings</span>
                    <span class="tg-chevron" id="<%= tgChevronId %>">&#9662;</span>
                  </span>
                </div>
              </div>

              <!-- Task Group Body (Expanded by Default) -->
              <div class="task-group-body" id="<%= tgPanelId %>" style="display:block;">
                <!-- Task Details & Spec Meta -->
                <% if ((tg.getDescription() != null && !tg.getDescription().trim().isEmpty()) || tg.hasWorkFile() || tg.getDueDate() != null) { %>
                  <div class="tg-meta-banner">
                    <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px;">
                      <div style="display:flex; gap:16px; font-size:12.5px; color:var(--slate-600); flex-wrap:wrap;">
                        <% if (tg.getDueDate() != null) { %>
                          <span><strong>Due Date:</strong> <%= tg.getFormattedDueDate() %></span>
                        <% } %>
                        <% if (tg.getCreatedByName() != null) { %>
                          <span><strong>Assigned by:</strong> <%= tg.getCreatedByName() %></span>
                        <% } %>
                      </div>
                      <% if (tg.hasWorkFile() && !tg.getEmployeeTasks().isEmpty()) { %>
                        <div style="display:flex; gap:8px; align-items:center;">
                          <% for (String fn : tg.getWorkFileList()) { 
                               String orig = util.FileStorageUtil.getOriginalFileName(fn);
                          %>
                            <a href="downloadTaskFile?taskId=<%= tg.getEmployeeTasks().get(0).getId() %>&type=work&file=<%= java.net.URLEncoder.encode(fn, java.nio.charset.StandardCharsets.UTF_8) %>" class="btn-file-pill btn-file-spec" target="_blank" title="Requirements Spec: <%= orig %>">
                              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline></svg>
                              <span>Requirements Spec (</span><span class="file-pill-name" title="<%= orig %>"><%= orig %></span><span>)</span>
                            </a>
                          <% } %>
                        </div>
                      <% } %>
                    </div>
                    <% if (tg.getDescription() != null && !tg.getDescription().trim().isEmpty()) { %>
                      <div style="margin-top:8px; font-size:13px; color:var(--slate-700); line-height:1.45;">
                        <%= tg.getDescription() %>
                      </div>
                    <% } %>
                  </div>
                <% } %>

                <!-- Employees Assigned to this Task -->
                <div class="tg-employees-container">
                  <div style="font-size:12px; font-weight:800; color:var(--slate-500); text-transform:uppercase; letter-spacing:0.04em; margin-bottom:6px;">
                    Assigned Employees &amp; Deliverables Evaluation (<%= tg.getEmployeeTasks().size() %>):
                  </div>

                  <% for (Task t : tg.getEmployeeTasks()) { %>
                    <div class="employee-task-row-card">
                      <!-- Employee Info & Status (Problem B4, B5) -->
                      <div class="emp-row-top">
                        <div class="emp-row-identity">
                          <div class="emp-avatar-sm">
                            <%= t.getAssignedToName() != null && !t.getAssignedToName().isEmpty() ? t.getAssignedToName().substring(0, 1).toUpperCase() : "E" %>
                          </div>
                          <div>
                            <div class="emp-name-bold">
                              <%= t.getAssignedToName() %>
                              <span class="emp-code-sub"><%= t.getAssignedTo() %></span>
                            </div>
                            <div style="font-size:11.5px; color:var(--slate-500); font-family:monospace; margin-top:2px;">
                              Task Ref: <strong><%= t.getFormattedId() %></strong> &bull; Dept: <%= t.getDepartment() != null ? t.getDepartment().trim().toUpperCase() : "GENERAL" %>
                            </div>
                          </div>
                        </div>

                        <!-- Right: Review Status Badge and Star Rating (Problem B4, B5) -->
                        <div class="emp-row-status-right">
                          <span class="badge <%= t.getReviewStatusBadgeClass() %>"><%= t.getReviewStatus() %></span>
                          <% if (t.isReviewCompleted()) { %>
                            <span class="task-rating-display" title="<%= t.getPerformanceLabel() %>">
                              <%= t.getRatingStars() %> (<%= t.getRating() %>/5)
                            </span>
                          <% } %>
                        </div>
                      </div>

                      <!-- Deliverables -->
                      <div class="emp-row-deliverables">
                        <div style="display:flex; align-items:center; gap:10px; flex-wrap:wrap; font-size:12.5px;">
                          <span style="font-weight:700; color:var(--slate-600);">Deliverables:</span>
                          <% if (t.hasWorkProofFile()) { %>
                            <% for (String fn : t.getWorkProofFileList()) { 
                                 String orig = util.FileStorageUtil.getOriginalFileName(fn);
                            %>
                              <a href="downloadTaskFile?taskId=<%= t.getId() %>&type=proof&file=<%= java.net.URLEncoder.encode(fn, java.nio.charset.StandardCharsets.UTF_8) %>" class="btn-file-pill btn-file-proof" target="_blank" title="Work Proof: <%= orig %>">
                                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                                <span>Work Proof (</span><span class="file-pill-name" title="<%= orig %>"><%= orig %></span><span>)</span>
                              </a>
                            <% } %>
                          <% } else { %>
                            <span style="color:var(--slate-400); font-style:italic;">No work proof uploaded yet</span>
                          <% } %>

                          <% if (t.getEmployeeComment() != null && !t.getEmployeeComment().trim().isEmpty()) { %>
                            <span style="color:var(--slate-600); background:#f1f5f9; padding:3px 8px; border-radius:4px; font-size:12px;">
                              Note: "<%= t.getEmployeeComment() %>"
                            </span>
                          <% } %>

                          <a href="viewTask?id=<%= t.getId() %>" style="color:var(--slate-500); text-decoration:none; font-size:12px; margin-left:auto;">
                            Task Details &rarr;
                          </a>
                        </div>
                      </div>

                      <!-- Existing Feedback Banner if present -->
                      <% if (t.hasFeedback()) { %>
                        <div class="current-feedback-quote" style="margin: 10px 0;">
                          <b>Manager Feedback:</b> "<%= t.getFeedback() %>"
                          <% if (!t.getFormattedReviewedAt().isEmpty()) { %>
                            <span class="quote-date">&bull; <%= t.getFormattedReviewedAt() %></span>
                          <% } %>
                        </div>
                      <% } %>

                      <!-- Manager Rating & Feedback Block -->
                      <% if (t.isAwaitingCompletion()) { %>
                        <!-- Problem A1: In UI, do not show the rating form for AWAITING COMPLETION. Show text instead -->
                        <div class="awaiting-completion-box" style="background:var(--slate-50); border:1px dashed var(--slate-300); border-radius:8px; padding:12px 16px; margin-top:10px; display:flex; align-items:center; gap:8px; color:var(--slate-500); font-size:13px; font-weight:600;">
                          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
                          <span>Awaiting Task Completion</span>
                        </div>
                      <% } else if (isManager) { %>
                        <!-- Rating form for PENDING REVIEW and REVIEWED -->
                        <div class="emp-row-review-box">
                          <form action="reviewTask" method="post" class="review-update-form" onsubmit="return validateReviewForm(this);">
                            <input type="hidden" name="taskId" value="<%= t.getId() %>">
                            <input type="hidden" name="redirectUrl" value="employeePerformance?view=task">

                            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px; flex-wrap:wrap; gap:8px;">
                              <span style="font-size:12px; font-weight:800; color:#92400e; text-transform:uppercase; letter-spacing:0.04em;">
                                ⭐ <%= t.isReviewCompleted() ? "Update Rating & Feedback for " + t.getAssignedToName() : "Rate & Review " + t.getAssignedToName() %>:
                              </span>
                              <!-- Problem A5: "Reviewed by: <manager>" only shown after review has been saved -->
                              <% if (t.isReviewCompleted() && t.getReviewedByName() != null && !t.getReviewedByName().isEmpty()) { %>
                                <span style="font-size:11.5px; color:var(--slate-500); font-weight:600;">Reviewed by: <%= t.getReviewedByName() %></span>
                              <% } %>
                            </div>

                            <!-- 5 Star Selection (Problem B7: Filled/Empty stars and highlight) -->
                            <div class="star-rating-radio-group">
                              <label class="star-radio-btn <%= (t.getRating() != null && t.getRating() == 5) ? "selected" : "" %>">
                                <input type="radio" name="rating" value="5" <%= (t.getRating() != null && t.getRating() == 5) ? "checked" : "" %> onchange="onRatingChange(this)">
                                <span>★★★★★ 5 - Outstanding</span>
                              </label>
                              <label class="star-radio-btn <%= (t.getRating() != null && t.getRating() == 4) ? "selected" : "" %>">
                                <input type="radio" name="rating" value="4" <%= (t.getRating() != null && t.getRating() == 4) ? "checked" : "" %> onchange="onRatingChange(this)">
                                <span>★★★★☆ 4 - Exceeds</span>
                              </label>
                              <label class="star-radio-btn <%= (t.getRating() != null && t.getRating() == 3) ? "selected" : "" %>">
                                <input type="radio" name="rating" value="3" <%= (t.getRating() != null && t.getRating() == 3) ? "checked" : "" %> onchange="onRatingChange(this)">
                                <span>★★★☆☆ 3 - Meets</span>
                              </label>
                              <label class="star-radio-btn <%= (t.getRating() != null && t.getRating() == 2) ? "selected" : "" %>">
                                <input type="radio" name="rating" value="2" <%= (t.getRating() != null && t.getRating() == 2) ? "checked" : "" %> onchange="onRatingChange(this)">
                                <span>★★☆☆☆ 2 - Below</span>
                              </label>
                              <label class="star-radio-btn <%= (t.getRating() != null && t.getRating() == 1) ? "selected" : "" %>">
                                <input type="radio" name="rating" value="1" <%= (t.getRating() != null && t.getRating() == 1) ? "checked" : "" %> onchange="onRatingChange(this)">
                                <span>★☆☆☆☆ 1 - Needs Improvement</span>
                              </label>
                            </div>

                            <!-- Feedback Comment Textarea with label (Problem C2, C3) -->
                            <div style="margin-top:10px;">
                              <label for="feedback_<%= t.getId() %>" class="rating-label-title" style="font-size:11px; margin-bottom:4px; color:#78350f;">Feedback Comments</label>
                              <textarea name="feedback" id="feedback_<%= t.getId() %>" rows="2" class="feedback-textarea" aria-label="Feedback comments for <%= t.getAssignedToName() %>" placeholder="Provide constructive feedback for <%= t.getAssignedToName() %> on <%= tg.getTitle() %>..."><%= t.hasFeedback() ? t.getFeedback() : "" %></textarea>
                            </div>

                            <!-- Problem C3: Inline Error Container -->
                            <div class="review-inline-error" style="display:none; color:#b91c1c; font-size:12px; font-weight:700; margin-top:6px;"></div>

                            <!-- Problem C5: Button text "Submit Review" or "Save Changes" -->
                            <div style="margin-top:10px; display:flex; align-items:center; gap:8px;">
                              <button type="submit" class="btn-save-rating">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg>
                                <%= t.isReviewCompleted() ? "Save Changes" : "Submit Review" %>
                              </button>
                            </div>
                          </form>
                        </div>
                      <% } %>
                    </div>
                  <% } %>
                </div>
              </div>
            </div>
          <% } %>
        </div>
      <% } %>
    </div>

    <!-- ========================================== -->
    <!-- VIEW 2: BY EMPLOYEE (Employee Scorecards) -->
    <!-- ========================================== -->
    <div id="panel_employee" class="view-panel <%= "employee".equalsIgnoreCase(viewMode) ? "active" : "" %>">
      <div class="table-wrapper">
        <% if (performanceList == null || performanceList.isEmpty()) { %>
          <div class="empty-state">
            <div class="empty-icon-circle">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
            </div>
            <h3 style="font-size:16px; font-weight:800; color:var(--slate-800); margin-bottom:4px;">No Employees Found</h3>
            <p style="font-size:13.5px; color:var(--slate-500);">No employees match your filter criteria.</p>
          </div>
        <% } else { %>
          <table>
            <thead>
              <tr>
                <th>Employee</th>
                <th>Department</th>
                <th>Completion Status</th>
                <th>Average Rating</th>
                <th>Performance Tier</th>
                <th>Latest Manager Feedback</th>
              </tr>
            </thead>
            <tbody>
              <% int idx = 0;
                 for (EmployeePerformance ep : performanceList) {
                   idx++;
              %>
                <tr>
                  <td>
                    <div style="font-weight:800; color:var(--slate-900); font-size:14px;"><%= ep.getEmployeeName() %></div>
                    <div style="font-size:11.5px; color:var(--slate-400); font-family:monospace;"><%= ep.getEmployeeId() %></div>
                  </td>
                  <td>
                    <span style="font-weight:700; color:#1e40af; background:#dbeafe; padding:2px 8px; border-radius:4px; font-size:11.5px;">
                      <%= ep.getDepartment() != null ? ep.getDepartment() : "General" %>
                    </span>
                  </td>
                  <td>
                    <div style="display:flex; align-items:center; gap:8px;">
                      <span style="font-weight:800; color:#059669;"><%= ep.getCompletedTasks() %></span>
                      <span style="color:#94a3b8; font-size:12px;">/ <%= ep.getTotalTasks() %> completed</span>
                    </div>
                    <% if (ep.getTotalTasks() > 0) { 
                         int pct = (int) Math.round(((double) ep.getCompletedTasks() / ep.getTotalTasks()) * 100);
                    %>
                      <div style="width:100px; height:5px; background:#e2e8f0; border-radius:3px; margin-top:5px; overflow:hidden;">
                        <div style="width:<%= pct %>%; height:100%; background:#10b981; border-radius:3px;"></div>
                      </div>
                    <% } %>
                  </td>
                  <td>
                    <% if (ep.getReviewedTasks() > 0) { %>
                      <div style="color:#f59e0b; font-size:14px; letter-spacing:1px; font-weight:800;"><%= ep.getStarDisplay() %></div>
                      <div style="font-size:12px; font-weight:800; color:#b45309;"><%= ep.getFormattedAvgRating() %> / 5.0</div>
                    <% } else { %>
                      <span style="font-size:12px; color:var(--slate-400); font-style:italic;">No ratings yet</span>
                    <% } %>
                  </td>
                  <td>
                    <span class="badge <%= ep.getTierBadgeClass() %>"><%= ep.getPerformanceTier() %></span>
                  </td>
                  <td>
                    <% if (ep.getLatestFeedback() != null && !ep.getLatestFeedback().isEmpty()) { %>
                      <div style="max-width:280px; font-size:12.5px; color:#475569; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;" title="<%= ep.getLatestFeedback() %>">
                        "<%= ep.getLatestFeedback() %>"
                      </div>
                    <% } else { %>
                      <span style="font-size:12px; color:var(--slate-400); font-style:italic;">None recorded</span>
                    <% } %>
                  </td>
                </tr>
              <% } %>
            </tbody>
          </table>
        <% } %>
      </div>
    </div>
    <% } %>
  </div><!-- .content-wrap -->
  </div><!-- .workspace -->
</div><!-- .app-shell -->

  <script>
    function toggleAdminManager(bodyId, chevronId) {
      var body = document.getElementById(bodyId);
      var chevron = document.getElementById(chevronId);
      if (body) {
        var isHidden = (body.style.display === 'none' || body.style.display === '');
        body.style.display = isHidden ? 'block' : 'none';
        if (chevron) {
          chevron.innerHTML = isHidden ? '&#9662;' : '&#9656;';
        }
      }
    }

    function toggleAdminTask(bodyId, chevronId) {
      var body = document.getElementById(bodyId);
      var chevron = document.getElementById(chevronId);
      if (body) {
        var isHidden = (body.style.display === 'none' || body.style.display === '');
        body.style.display = isHidden ? 'block' : 'none';
        if (chevron) {
          chevron.innerHTML = isHidden ? '&#9662;' : '&#9656;';
        }
      }
    }

    function toggleAllAdminManagers(expand) {
      var bodies = document.querySelectorAll('.admin-mgr-body');
      var chevrons = document.querySelectorAll('.admin-mgr-header .admin-chevron');
      bodies.forEach(function(b) {
        b.style.display = expand ? 'block' : 'none';
      });
      chevrons.forEach(function(c) {
        c.innerHTML = expand ? '&#9662;' : '&#9656;';
      });
    }

    function toggleManagerTasks(mgrBodyId, expand) {
      var container = document.getElementById(mgrBodyId);
      if (!container) return;
      var taskBodies = container.querySelectorAll('.admin-task-body');
      var taskChevrons = container.querySelectorAll('.admin-task-header .admin-chevron');
      taskBodies.forEach(function(tb) {
        tb.style.display = expand ? 'block' : 'none';
      });
      taskChevrons.forEach(function(tc) {
        tc.innerHTML = expand ? '&#9662;' : '&#9656;';
      });
    }

    function switchViewMode(mode) {
      var filterInput = document.getElementById('filterViewMode');
      if (filterInput) filterInput.value = mode;

      // Update Tab button active state by data-mode
      var buttons = document.querySelectorAll('.tab-btn');
      buttons.forEach(function(b) {
        if (b.getAttribute('data-mode') === mode) {
          b.classList.add('active');
        } else {
          b.classList.remove('active');
        }
      });

      // Update Panel visibility
      document.querySelectorAll('.view-panel').forEach(function(p) { p.classList.remove('active'); });

      var targetPanel = document.getElementById('panel_' + mode);
      if (targetPanel) {
        targetPanel.classList.add('active');
      }

      // Update browser history URL without page reload
      var url = new URL(window.location.href);
      url.searchParams.set('view', mode);
      window.history.replaceState({}, '', url.toString());
    }

    function onRatingChange(radio) {
      var parentGroup = radio.closest('.star-rating-radio-group');
      if (parentGroup) {
        var labels = parentGroup.querySelectorAll('.star-radio-btn');
        labels.forEach(function(lbl) {
          lbl.classList.remove('selected');
        });
        var parentLabel = radio.closest('.star-radio-btn');
        if (parentLabel) {
          parentLabel.classList.add('selected');
        }
      }
    }

    function validateReviewForm(form) {
      var errDiv = form.querySelector('.review-inline-error');
      if (errDiv) {
        errDiv.style.display = 'none';
        errDiv.textContent = '';
      }

      // Problem C3: Rating is required before submit
      var ratingChecked = form.querySelector('input[name="rating"]:checked');
      if (!ratingChecked) {
        if (errDiv) {
          errDiv.textContent = 'Please select a star rating (1-5) before submitting.';
          errDiv.style.display = 'block';
        } else {
          alert('Please select a star rating (1-5) before submitting.');
        }
        return false;
      }

      var ratingVal = parseInt(ratingChecked.value, 10);
      var feedbackInput = form.querySelector('textarea[name="feedback"]');
      var feedbackVal = feedbackInput ? feedbackInput.value.trim() : '';

      // Problem C3: Feedback is required when rating is 1 or 2
      if ((ratingVal === 1 || ratingVal === 2) && (!feedbackVal || feedbackVal.length < 5)) {
        if (errDiv) {
          errDiv.textContent = 'Constructive feedback is required when assigning a rating of 1 or 2 stars.';
          errDiv.style.display = 'block';
          if (feedbackInput) feedbackInput.focus();
        } else {
          alert('Constructive feedback is required when assigning a rating of 1 or 2 stars.');
        }
        return false;
      }

      // Feedback is required
      if (!feedbackVal) {
        if (errDiv) {
          errDiv.textContent = 'Please enter feedback comments for the employee.';
          errDiv.style.display = 'block';
          if (feedbackInput) feedbackInput.focus();
        } else {
          alert('Please enter feedback comments for the employee.');
        }
        return false;
      }

      // Problem C4: Confirm step before saving rating
      var confirmMsg = (ratingVal <= 2)
          ? 'You are submitting a rating of ' + ratingVal + ' star(s). Do you want to proceed and save this review?'
          : 'Are you sure you want to save this performance review?';
      return confirm(confirmMsg);
    }

    function toggleGroupPanel(panelId, chevronId, headerElem) {
      var panel = document.getElementById(panelId);
      var chevron = document.getElementById(chevronId);
      if (panel) {
        var isHidden = (panel.style.display === 'none');
        panel.style.display = isHidden ? 'block' : 'none';
        if (chevron) {
          chevron.innerHTML = isHidden ? '&#9662;' : '&#9656;';
        }
        if (headerElem) {
          headerElem.setAttribute('aria-expanded', isHidden ? 'true' : 'false');
        }
      }
    }

    function toggleAllTaskPanels(expand) {
      var panels = document.querySelectorAll('.task-group-body');
      var chevrons = document.querySelectorAll('.tg-chevron');
      var headers = document.querySelectorAll('.task-group-header');
      panels.forEach(function(p) {
        p.style.display = expand ? 'block' : 'none';
      });
      chevrons.forEach(function(c) {
        c.innerHTML = expand ? '&#9662;' : '&#9656;';
      });
      headers.forEach(function(h) {
        h.setAttribute('aria-expanded', expand ? 'true' : 'false');
      });
    }

    function toggleEmpDrawer(id) {
      var row = document.getElementById(id);
      if (row) {
        var isHidden = (row.style.display === 'none' || row.style.display === '');
        row.style.display = isHidden ? 'table-row' : 'none';
        if (isHidden) {
          row.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        }
      }
    }

    function toggleTaskItem(bodyId, chevronId) {
      var body = document.getElementById(bodyId);
      var chevron = document.getElementById(chevronId);
      if (body) {
        var isHidden = (body.style.display === 'none');
        body.style.display = isHidden ? 'block' : 'none';
        if (chevron) {
          chevron.innerHTML = isHidden ? '&#9662;' : '&#9656;';
        }
      }
    }

    window.addEventListener('DOMContentLoaded', function() {
      // Real-time client filter on keyword input for Admin hierarchy
      var adminSearch = document.getElementById('adminSearchInput');
      if (adminSearch) {
        adminSearch.addEventListener('input', function(e) {
          var q = e.target.value.toLowerCase().trim();
          var mgrCards = document.querySelectorAll('.admin-mgr-card');
          if (!mgrCards.length) return;
          mgrCards.forEach(function(card) {
            if (!q) {
              card.style.display = '';
              return;
            }
            var text = card.textContent.toLowerCase();
            if (text.indexOf(q) !== -1) {
              card.style.display = '';
              var body = card.querySelector('.admin-mgr-body');
              var chevron = card.querySelector('.admin-mgr-header .admin-chevron');
              if (body) body.style.display = 'block';
              if (chevron) chevron.innerHTML = '&#9662;';
            } else {
              card.style.display = 'none';
            }
          });
        });
      }

      // If a task was just reviewed, auto-expand the employee's drawer containing that task
      var msg = "<%= succMsg != null ? succMsg.replace("\"", "\\\"").replace("\n", " ") : "" %>";
      if (msg && msg.indexOf("TASK") !== -1) {
        var match = msg.match(/TASK\d+/i);
        if (match) {
          var taskCode = match[0].toUpperCase();
          var codePills = document.querySelectorAll('.task-code-pill');
          for (var i = 0; i < codePills.length; i++) {
            if (codePills[i].textContent.trim().toUpperCase() === taskCode) {
              var drawerRow = codePills[i].closest('.emp-drawer-row');
              if (drawerRow) {
                drawerRow.style.display = 'table-row';
                drawerRow.scrollIntoView({ behavior: 'smooth', block: 'center' });
              }
              break;
            }
          }
        }
      }
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
