<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.util.ArrayList, java.util.Map, java.util.LinkedHashMap, model.Task, model.TaskGroup, model.User" %>
<%
    User currentUser = (User) session.getAttribute("user");
    String ctx = request.getContextPath();
    boolean isHr = currentUser != null && currentUser.isHr();
    boolean isManager = currentUser != null && currentUser.isManager();
    boolean isEmployee = currentUser != null && currentUser.isEmployee();
    String roleBadge = isHr ? "ADMIN" : (isManager ? "MANAGER" : "EMPLOYEE");
    String userName = (currentUser != null && currentUser.getUsername() != null) ? currentUser.getUsername() : "User";
    String userInitial = !userName.isEmpty() ? userName.substring(0, 1).toUpperCase() : "U";
    List<Task> tasks = (List<Task>) request.getAttribute("tasks");
    List<String> departments = (List<String>) request.getAttribute("departments");
    String keyword = (String) request.getAttribute("keyword");
    String selectedStatus = (String) request.getAttribute("selectedStatus");
    String selectedPriority = (String) request.getAttribute("selectedPriority");
    String selectedDept = (String) request.getAttribute("selectedDepartment");
    String currentSort = (String) request.getAttribute("sort");
    String currentOrder = (String) request.getAttribute("order");

    String flashMessage = (String) session.getAttribute("flashMessage");
    if (flashMessage != null) session.removeAttribute("flashMessage");
    String flashError = (String) session.getAttribute("flashError");
    if (flashError != null) session.removeAttribute("flashError");

    // Group individual employee assignments by Task Title into TaskGroup
    List<TaskGroup> taskGroups = new ArrayList<>();
    if (tasks != null && !tasks.isEmpty()) {
        Map<String, TaskGroup> groupMap = new LinkedHashMap<>();
        for (Task t : tasks) {
            String titleKey = (t.getTaskTitle() != null && !t.getTaskTitle().trim().isEmpty())
                    ? t.getTaskTitle().trim()
                    : ("TASK" + String.format("%03d", t.getId()));
            String key = titleKey.toLowerCase();
            TaskGroup g = groupMap.get(key);
            if (g == null) {
                g = new TaskGroup(titleKey);
                groupMap.put(key, g);
            }
            g.addTask(t);
        }
        taskGroups.addAll(groupMap.values());
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>WorkPulse — Manage Tasks</title>
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
      --brand-accent: #2563eb;

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
      --emerald-text: #047857;

      --rose-500: #f43f5e;
      --rose-50: #fff1f2;
      --rose-border: #fecdd3;
      --rose-text: #be123c;

      --amber-500: #f59e0b;
      --amber-50: #fffbeb;
      --amber-border: #fde68a;
      --amber-text: #b45309;

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
      border-radius: var(--radius-sm, 8px);
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
      border-radius: 8px;
      font-size: 13px;
      font-weight: 600;
      transition: all 0.15s ease;
    }
    .btn-signout:hover {
      background: #fef2f2;
      border-color: #f87171;
      color: #991b1b;
    }
    .content-wrap {
      padding: 32px 36px 60px;
      width: 100%;
      max-width: 1280px;
      margin: 0 auto;
    }

    header.topbar_old {
      background: #ffffff;
      border-bottom: 1px solid var(--slate-200);
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
      gap: 10px;
      text-decoration: none;
      color: var(--slate-900);
      font-weight: 800;
      font-size: 17px;
      letter-spacing: -0.01em;
    }
    .logo-badge {
      width: 34px;
      height: 34px;
      border-radius: 9px;
      background: var(--brand-gradient);
      display: flex;
      align-items: center;
      justify-content: center;
      color: #ffffff;
      box-shadow: 0 4px 12px rgba(37, 99, 235, 0.25);
    }
    .nav-links {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .nav-btn {
      padding: 8px 14px;
      border-radius: 8px;
      font-size: 13.5px;
      font-weight: 600;
      text-decoration: none;
      color: var(--slate-600);
      transition: all 0.15s;
    }
    .nav-btn:hover { background: var(--slate-100); color: var(--slate-900); }
    .nav-btn.active { 
      background: #eff6ff;
      color: #2563eb;
      border: 1px solid #bfdbfe;
      font-weight: 700;
    }
    .btn-create {
      background: var(--brand-gradient) !important;
      color: #ffffff !important;
      border: none;
      box-shadow: 0 4px 14px rgba(37, 99, 235, 0.25);
      display: inline-flex;
      align-items: center;
      gap: 7px;
      padding: 10px 18px !important;
      border-radius: 9px;
      font-weight: 700;
      text-decoration: none;
      transition: all 0.2s ease;
      cursor: pointer;
    }
    .btn-create:hover {
      background: linear-gradient(135deg, #1e40af 0%, #1d4ed8 100%) !important;
      transform: translateY(-1.5px);
      box-shadow: 0 6px 18px rgba(37, 99, 235, 0.35);
    }
    .container {
      max-width: 1260px;
      width: 100%;
      margin: 28px auto;
      padding: 0 20px;
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
      font-size: 14px;
      color: var(--slate-500);
      margin-top: 4px;
    }
    .filter-card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-md);
      padding: 16px 20px;
      margin-bottom: 20px;
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.05);
    }
    .filter-form {
      display: grid;
      grid-template-columns: 2fr 1.2fr 1.2fr 1.2fr auto auto;
      gap: 12px;
      align-items: center;
    }
    @media (max-width: 900px) {
      .filter-form { grid-template-columns: 1fr 1fr; }
    }
    input[type="text"], select {
      width: 100%;
      padding: 10px 13px;
      border: 1.5px solid var(--slate-300);
      border-radius: 8px;
      font-size: 13.5px;
      font-family: inherit;
      color: var(--slate-800);
      background: #ffffff;
      box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
      transition: all 0.15s ease;
    }
    input::placeholder { color: var(--slate-400); }
    input:focus, select:focus {
      outline: none;
      border-color: var(--brand-accent);
      box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
    }
    select option {
      background: #ffffff;
      color: var(--slate-800);
    }
    .btn-search {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      padding: 10px 18px;
      background: var(--brand-gradient);
      color: #ffffff;
      border: none;
      border-radius: 8px;
      font-weight: 700;
      font-size: 13.5px;
      cursor: pointer;
      transition: all 0.18s ease;
      white-space: nowrap;
      box-shadow: 0 2px 8px rgba(37, 99, 235, 0.25);
    }
    .btn-search:hover {
      transform: translateY(-1px);
      box-shadow: 0 4px 14px rgba(37, 99, 235, 0.35);
    }
    .btn-reset {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      padding: 10px 15px;
      background: var(--slate-100);
      color: var(--slate-700);
      border: 1px solid var(--slate-200);
      border-radius: 8px;
      font-weight: 600;
      font-size: 13.5px;
      text-decoration: none;
      text-align: center;
      transition: all 0.15s ease;
      white-space: nowrap;
      cursor: pointer;
    }
    .btn-reset:hover {
      background: var(--slate-200);
      color: var(--slate-900);
      transform: translateY(-1px);
    }

    .table-card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-lg);
      overflow: hidden;
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.06);
    }
    table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
      font-size: 13.5px;
      background: #ffffff;
    }
    thead {
      background: #f8fafc;
      border-bottom: 1px solid var(--slate-200);
    }
    th {
      padding: 13px 16px;
      font-weight: 700;
      color: var(--slate-600);
      text-transform: uppercase;
      font-size: 11.5px;
      letter-spacing: 0.04em;
    }
    th.col-expand { width: 44px; text-align: center; }
    th.col-task { min-width: 270px; }
    th.col-assignees { width: 175px; white-space: nowrap; }
    th.col-priority { width: 95px; white-space: nowrap; }
    th.col-progress { width: 175px; white-space: nowrap; }
    th.col-due { width: 130px; white-space: nowrap; cursor: pointer; user-select: none; transition: background 0.15s; }
    th.col-due:hover { background: #f1f5f9; color: var(--slate-900); }
    th.col-actions { width: 125px; text-align: right; white-space: nowrap; }

    /* Master Task Row Styles */
    .task-master-row {
      cursor: pointer;
      border-bottom: 1px solid var(--slate-200);
      transition: background 0.15s ease;
    }
    .task-master-row:hover {
      background: #f8fafc;
    }
    .task-master-row.expanded {
      background: #eff6ff;
      border-bottom-color: #bfdbfe;
    }
    td {
      padding: 13px 16px;
      color: var(--slate-700);
      vertical-align: middle;
    }
    .expand-btn {
      width: 26px;
      height: 26px;
      border-radius: 6px;
      background: #f1f5f9;
      color: #2563eb;
      border: 1px solid #cbd5e1;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      transition: all 0.2s ease;
    }
    .task-master-row:hover .expand-btn {
      background: #eff6ff;
      border-color: #bfdbfe;
    }
    .task-master-row.expanded .expand-btn {
      background: #2563eb;
      color: #ffffff;
      border-color: #2563eb;
      transform: rotate(90deg);
    }
    .task-master-title {
      font-weight: 800;
      color: var(--slate-900);
      font-size: 14.5px;
      line-height: 1.3;
    }
    .task-meta {
      display: flex;
      align-items: center;
      gap: 6px;
      margin-top: 4px;
      flex-wrap: wrap;
    }
    .dept-tag {
      font-size: 10.5px;
      font-weight: 700;
      color: var(--slate-600);
      background: var(--slate-100);
      border: 1px solid var(--slate-200);
      padding: 1px 6px;
      border-radius: 4px;
      letter-spacing: 0.03em;
    }
    .file-pill {
      display: inline-flex;
      align-items: center;
      gap: 4px;
      font-size: 11px;
      font-weight: 700;
      padding: 2px 7px;
      border-radius: 4px;
      text-decoration: none;
      white-space: nowrap;
      line-height: 1.2;
    }
    .pill-work {
      background: #eff6ff;
      color: #1d4ed8;
      border: 1px solid #bfdbfe;
    }
    .pill-work:hover {
      background: #dbeafe;
      color: #1e40af;
    }
    .pill-proof {
      background: #ecfdf5;
      color: #047857;
      border: 1px solid #a7f3d0;
    }
    .pill-proof:hover {
      background: #d1fae5;
      color: #064e3b;
    }
    .pill-no-proof {
      background: #f8fafc;
      color: #94a3b8;
      border: 1px dashed #cbd5e1;
      font-style: italic;
      font-weight: 500;
    }

    /* Assignees Pill Button */
    .assignees-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 5px 11px;
      border-radius: 8px;
      background: #eff6ff;
      border: 1px solid #bfdbfe;
      color: #1d4ed8;
      font-size: 12.5px;
      font-weight: 700;
      transition: all 0.15s ease;
      white-space: nowrap;
    }
    .task-master-row:hover .assignees-pill {
      background: #dbeafe;
      border-color: #93c5fd;
      color: #1e40af;
    }
    .task-master-row.expanded .assignees-pill {
      background: #2563eb;
      color: #ffffff;
      border-color: #2563eb;
    }

    .priority-pill {
      font-size: 11px;
      font-weight: 700;
      padding: 2px 8px;
      border-radius: 6px;
      display: inline-block;
      white-space: nowrap;
    }
    .priority-high { background: var(--rose-50); color: var(--rose-text); border: 1px solid var(--rose-border); }
    .priority-medium { background: var(--amber-50); color: var(--amber-text); border: 1px solid var(--amber-border); }
    .priority-low { background: var(--emerald-50); color: var(--emerald-text); border: 1px solid var(--emerald-border); }

    .progress-box {
      display: inline-flex;
      align-items: center;
      gap: 6px;
    }
    .progress-pill {
      display: inline-flex;
      align-items: center;
      gap: 4px;
      font-size: 11.5px;
      font-weight: 700;
      padding: 2px 8px;
      border-radius: 6px;
      background: #f8fafc;
      border: 1px solid #cbd5e1;
      color: var(--slate-700);
      white-space: nowrap;
    }
    .progress-pill.all-done {
      background: #ecfdf5;
      color: #047857;
      border-color: #a7f3d0;
    }
    .alert-pill {
      font-size: 11px;
      font-weight: 700;
      padding: 2px 7px;
      border-radius: 6px;
      background: #fffbeb;
      border: 1px solid #fde68a;
      color: #b45309;
      white-space: nowrap;
    }

    .due-date-val {
      font-weight: 600;
      color: var(--slate-800);
      font-size: 13px;
      white-space: nowrap;
    }
    .due-badge {
      display: inline-block;
      font-size: 10px;
      font-weight: 700;
      padding: 1px 6px;
      border-radius: 4px;
      margin-top: 3px;
      letter-spacing: 0.02em;
      text-transform: uppercase;
      white-space: nowrap;
    }
    .badge-overdue {
      background: #fee2e2;
      color: #b91c1c;
      border: 1px solid #fca5a5;
    }
    .badge-due-today {
      background: #fef3c7;
      color: #b45309;
      border: 1px solid #fde68a;
    }

    .action-group {
      display: flex;
      align-items: center;
      justify-content: flex-end;
      gap: 5px;
    }
    .icon-btn {
      width: 32px;
      height: 32px;
      border-radius: 7px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      border: 1px solid var(--slate-200);
      background: #ffffff;
      color: var(--slate-600);
      cursor: pointer;
      transition: all 0.15s ease;
      text-decoration: none;
      box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
    }
    .icon-view:hover {
      background: #eff6ff;
      border-color: #bfdbfe;
      color: #1d4ed8;
      transform: translateY(-1px);
    }
    .icon-edit:hover {
      background: #f1f5f9;
      border-color: #cbd5e1;
      color: #0f172a;
      transform: translateY(-1px);
    }
    .action-sep {
      width: 1px;
      height: 18px;
      background: var(--slate-200);
      margin: 0 2px;
    }
    .icon-del {
      background: #fff1f2;
      border-color: #fecdd3;
      color: #e11d48;
    }
    .icon-del:hover {
      background: #fee2e2;
      border-color: #fda4af;
      color: #be123c;
      transform: translateY(-1px);
    }
    .icon-del.icon-del-blocked {
      opacity: 0.5;
      cursor: not-allowed;
      background: #f8fafc;
      border-color: #e2e8f0;
      color: #94a3b8;
    }
    .icon-del.icon-del-blocked:hover {
      background: #f8fafc;
      border-color: #e2e8f0;
      color: #94a3b8;
      transform: none;
    }

    /* Sub-table Drawer for Assigned Employees */
    .task-drawer-row {
      display: none;
      background: #f8fafc;
      border-bottom: 1px solid var(--slate-300);
    }
    .task-drawer-row.open {
      display: table-row;
    }
    .task-drawer-cell {
      padding: 12px 18px 20px 52px;
      background: #f8fafc;
    }
    .sub-table-card {
      background: #ffffff;
      border: 1px solid #cbd5e1;
      border-radius: 10px;
      overflow: hidden;
      box-shadow: 0 2px 6px rgba(15, 23, 42, 0.05);
    }
    .sub-table-header {
      padding: 10px 16px;
      background: #f1f5f9;
      border-bottom: 1px solid #e2e8f0;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }
    .sub-table-title {
      font-size: 12px;
      font-weight: 800;
      color: var(--slate-700);
      text-transform: uppercase;
      letter-spacing: 0.04em;
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .sub-table {
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
      background: #ffffff;
    }
    .sub-table thead {
      background: #f8fafc;
      border-bottom: 1px solid var(--slate-200);
    }
    .sub-table th {
      padding: 9px 14px;
      font-size: 11px;
      font-weight: 700;
      color: var(--slate-600);
      text-transform: uppercase;
      letter-spacing: 0.03em;
    }
    .sub-table tbody tr {
      border-bottom: 1px solid #f1f5f9;
      transition: background 0.12s;
    }
    .sub-table tbody tr:hover {
      background: #f8fafc;
    }
    .sub-table tbody tr:last-child {
      border-bottom: none;
    }
    .sub-table td {
      padding: 10px 14px;
      color: var(--slate-700);
      vertical-align: middle;
    }
    .sub-emp-name {
      font-weight: 700;
      color: var(--slate-900);
      font-size: 13px;
    }
    .sub-emp-id {
      font-size: 11.5px;
      color: var(--slate-500);
      font-weight: 600;
      font-family: monospace;
      margin-top: 1px;
    }

    .badge {
      display: inline-block;
      padding: 3px 9px;
      border-radius: 9999px;
      font-size: 11.5px;
      font-weight: 700;
      letter-spacing: 0.02em;
      white-space: nowrap;
    }
    .badge-awaiting {
      background: #f1f5f9;
      color: #475569;
      border: 1px solid #cbd5e1;
    }
    .badge-pending {
      background: #fffbeb;
      color: #b45309;
      border: 1px solid #fde68a;
    }
    .badge-reviewed {
      background: #ecfdf5;
      color: #047857;
      border: 1px solid #a7f3d0;
    }

    .action-review-btn {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      font-size: 11.5px;
      font-weight: 700;
      color: var(--amber-text);
      background: var(--amber-50);
      padding: 4px 9px;
      border-radius: 6px;
      border: 1px solid var(--amber-border);
      text-decoration: none;
      transition: all 0.15s ease;
      line-height: 1.2;
      white-space: nowrap;
    }
    .action-review-btn:hover {
      background: #fef3c7;
      transform: translateY(-1px);
    }
    .msg-banner {
      padding: 12px 16px;
      border-radius: var(--radius-md);
      font-size: 14px;
      font-weight: 600;
      margin-bottom: 20px;
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .msg-ok { background: var(--emerald-50); color: var(--emerald-text); border: 1px solid var(--emerald-border); }
    .msg-err { background: var(--rose-50); color: var(--rose-text); border: 1px solid var(--rose-border); }
    .empty-state {
      padding: 60px 20px;
      text-align: center;
      color: var(--slate-500);
    }

    /* Pagination Bar */
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
      gap: 5px;
    }
    .page-btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-width: 30px;
      height: 30px;
      padding: 0 8px;
      border-radius: 6px;
      border: 1px solid var(--slate-200);
      background: #ffffff;
      color: var(--slate-700);
      font-size: 12.5px;
      font-weight: 600;
      cursor: pointer;
      text-decoration: none;
      transition: all 0.15s ease;
    }
    .page-btn:hover:not(.disabled):not(.active) {
      background: #f1f5f9;
      border-color: #cbd5e1;
      color: var(--slate-900);
    }
    .page-btn.active {
      background: var(--primary);
      border-color: var(--primary);
      color: #ffffff;
      font-weight: 700;
    }
    .page-btn.disabled {
      opacity: 0.45;
      cursor: not-allowed;
    }

    /* Modal */
    .modal-backdrop {
      display: none;
      position: fixed;
      inset: 0;
      background: rgba(15, 23, 42, 0.45);
      backdrop-filter: blur(4px);
      align-items: center;
      justify-content: center;
      z-index: 100;
    }
    .modal-box {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-lg);
      padding: 28px 24px;
      max-width: 440px;
      width: 90%;
      box-shadow: 0 20px 40px rgba(15, 23, 42, 0.15);
      text-align: center;
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

  <!-- Workspace Area -->
  <div class="workspace">
    <header class="topbar">
      <h1 class="page-title">Manage Tasks</h1>
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

    <div class="content-wrap">
    <div class="page-header">
      <div>
        <h1 class="page-title">Manage Tasks</h1>
        <p class="page-subtitle">Monitor team workload, update task specifications, and oversee assignments.</p>
      </div>
      <a href="createTask" class="nav-btn btn-create">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.8"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
        Create Task
      </a>
    </div>

    <% if (flashMessage != null) { %>
      <div class="msg-banner msg-ok">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg>
        <div><%= flashMessage %></div>
      </div>
    <% } %>
    <% if (flashError != null) { %>
      <div class="msg-banner msg-err">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
        <div><%= flashError %></div>
      </div>
    <% } %>

    <!-- Search & Filter Bar -->
    <div class="filter-card">
      <form action="searchTasks" method="get" class="filter-form">
        <div>
          <input type="text" name="keyword" aria-label="Search tasks" placeholder="Search by Task title, Assignment ID, employee..." value="<%= keyword != null ? keyword : "" %>">
        </div>
        <div>
          <select name="status" aria-label="Filter by review status">
            <option value="ALL">Status: All</option>
            <option value="AWAITING_COMPLETION" <%= ("AWAITING_COMPLETION".equalsIgnoreCase(selectedStatus) || "AWAITING COMPLETION".equalsIgnoreCase(selectedStatus)) ? "selected" : "" %>>Awaiting Completion</option>
            <option value="PENDING_REVIEW" <%= ("PENDING_REVIEW".equalsIgnoreCase(selectedStatus) || "PENDING REVIEW".equalsIgnoreCase(selectedStatus)) ? "selected" : "" %>>Pending Review</option>
            <option value="REVIEWED" <%= "REVIEWED".equalsIgnoreCase(selectedStatus) ? "selected" : "" %>>Reviewed</option>
          </select>
        </div>
        <div>
          <select name="priority" aria-label="Filter by priority">
            <option value="ALL">Priority: All</option>
            <option value="HIGH" <%= "HIGH".equalsIgnoreCase(selectedPriority) ? "selected" : "" %>>HIGH</option>
            <option value="MEDIUM" <%= "MEDIUM".equalsIgnoreCase(selectedPriority) ? "selected" : "" %>>MEDIUM</option>
            <option value="LOW" <%= "LOW".equalsIgnoreCase(selectedPriority) ? "selected" : "" %>>LOW</option>
          </select>
        </div>
        <div>
          <select name="department" aria-label="Filter by department">
            <option value="ALL">Department: All</option>
            <% if (departments != null) {
                 for (String d : departments) {
                   if (d == null || d.trim().isEmpty()) continue;
                   String normD = d.trim().toUpperCase();
            %>
              <option value="<%= normD %>" <%= normD.equalsIgnoreCase(selectedDept) ? "selected" : "" %>><%= normD %></option>
            <%   }
               } %>
          </select>
        </div>
        <button type="submit" class="btn-search">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
          Search
        </button>
        <a href="viewTask" class="btn-reset">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"></path><polyline points="3 3 3 8 8 8"></polyline></svg>
          Reset
        </a>
      </form>
    </div>

    <!-- Table Header Controls: Count & Global Expand/Collapse -->
    <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:12px; padding:0 4px; flex-wrap:wrap; gap:10px;">
      <div style="display:flex; align-items:center; gap:8px;">
        <span style="font-weight:800; font-size:15px; color:var(--slate-900);">Tasks Directory</span>
        <span style="font-size:12px; font-weight:700; color:var(--slate-600); background:#f1f5f9; border:1px solid #cbd5e1; padding:2px 9px; border-radius:9999px;">
          <%= taskGroups.size() %> <%= taskGroups.size() == 1 ? "Task" : "Tasks" %> &bull; <%= (tasks != null ? tasks.size() : 0) %> Total Assignments
        </span>
      </div>
      <div style="display:flex; align-items:center; gap:8px;">
        <button type="button" class="btn-reset" onclick="expandAllTasks()" style="padding:6px 12px; font-size:12.5px;">
          Expand All Tasks
        </button>
        <button type="button" class="btn-reset" onclick="collapseAllTasks()" style="padding:6px 12px; font-size:12.5px;">
          Collapse All Tasks
        </button>
      </div>
    </div>

    <!-- Hierarchical Tasks Table -->
    <div class="table-card">
      <% if (taskGroups.isEmpty()) { %>
        <div class="empty-state">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" style="margin:0 auto 12px; color:var(--slate-400);">
            <rect x="2" y="7" width="20" height="14" rx="2" ry="2"></rect>
            <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path>
          </svg>
          <p style="font-weight:700; font-size:16px; color:var(--slate-700);">No tasks found</p>
          <p style="font-size:13.5px; margin-top:4px;">Try refining your search filters or create a new task.</p>
        </div>
      <% } else { %>
        <table>
          <thead>
            <tr>
              <th class="col-expand" title="Expand / Collapse assigned employees"></th>
              <th class="col-task">Task Specifications</th>
              <th class="col-assignees">Assigned Employees</th>
              <th class="col-priority">Priority</th>
              <th class="col-progress">Completion Status</th>
              <th class="col-due" onclick="toggleDateSort()" title="Click to sort by Due Date">
                Due Date <span id="sortIndicator" style="font-size:10px; margin-left:3px;">⇅</span>
              </th>
              <th class="col-actions">Actions</th>
            </tr>
          </thead>
          <tbody id="tasksTableBody">
            <% int groupIdx = 0;
               for (TaskGroup g : taskGroups) { 
                 groupIdx++;
                 String drawerId = "taskDrawer_" + groupIdx;
                 String prClass = "priority-" + (g.getPriority() != null ? g.getPriority().toLowerCase() : "medium");
                 int totalAssigned = g.getTotalEmployees();
                 int completedCount = g.getCompletedCount();
                 int pendingCount = g.getPendingReviewCount();
                 int reviewedCount = g.getReviewedCount();
                 int awaitingCount = g.getAwaitingCompletionCount();
                 int repId = g.getMinTaskId();
                 boolean anyBlocked = false;
                 for (Task subT : g.getEmployeeTasks()) {
                     if (subT.isReviewed() || subT.hasWorkProofFile()) {
                         anyBlocked = true;
                         break;
                     }
                 }
            %>
              <!-- Master Task Row -->
              <tr class="task-master-row" id="masterRow_<%= groupIdx %>" onclick="toggleTaskDrawer('<%= groupIdx %>')" data-due-date="<%= g.getDueDate() != null ? g.getDueDate().toString() : "" %>">
                <td style="text-align:center;">
                  <button type="button" class="expand-btn" id="expandBtn_<%= groupIdx %>" aria-label="Expand employees">
                    <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.5"><polyline points="9 18 15 12 9 6"></polyline></svg>
                  </button>
                </td>
                <td>
                  <div class="task-master-title"><%= g.getTitle() %></div>
                  <div class="task-meta">
                    <span class="dept-tag"><%= g.getDepartment() %></span>
                    <% if (g.hasWorkFile()) { %>
                      <a href="downloadTaskFile?taskId=<%= repId %>&type=work" class="file-pill pill-work" onclick="event.stopPropagation();" title="Download Task Attachment Specifications">
                        &#128206; Task Attachment (<%= g.getWorkFileList().size() %>)
                      </a>
                    <% } %>
                  </div>
                </td>
                <td>
                  <div class="assignees-pill" title="Click to view assigned employees">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
                    <span><%= totalAssigned %> <%= totalAssigned == 1 ? "Employee" : "Employees" %></span>
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="6 9 12 15 18 9"></polyline></svg>
                  </div>
                </td>
                <td><span class="priority-pill <%= prClass %>"><%= g.getPriority() %></span></td>
                <td>
                  <div class="progress-box">
                    <span class="progress-pill <%= (completedCount == totalAssigned && totalAssigned > 0) ? "all-done" : "" %>">
                      <%= completedCount %>/<%= totalAssigned %> Completed
                    </span>
                    <% if (pendingCount > 0) { %>
                      <span class="alert-pill" title="<%= pendingCount %> assignment(s) completed and awaiting review">
                        <%= pendingCount %> Pending Review
                      </span>
                    <% } else if (reviewedCount > 0 && reviewedCount == totalAssigned) { %>
                      <span class="progress-pill all-done" style="background:#ecfdf5; border-color:#a7f3d0; color:#047857;">
                        All Reviewed &#10003;
                      </span>
                    <% } %>
                  </div>
                </td>
                <td>
                  <div class="due-date-val"><%= g.getFormattedDueDate() %></div>
                  <% if (g.isOverdue()) { %>
                    <span class="due-badge badge-overdue" title="Task is overdue">Overdue</span>
                  <% } else if (g.isDueToday()) { %>
                    <span class="due-badge badge-due-today" title="Task is due today">Due today</span>
                  <% } %>
                </td>
                <td style="text-align:right;">
                  <div class="action-group" onclick="event.stopPropagation();">
                    <a href="viewTask?id=<%= repId %>" class="icon-btn icon-view" title="View Task Specifications" aria-label="View Task">
                      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                    </a>
                    <a href="editTask?id=<%= repId %>" class="icon-btn icon-edit" title="Edit Task Specifications" aria-label="Edit Task">
                      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M17 3a2.828 2.828 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z"></path></svg>
                    </a>
                    <span class="action-sep"></span>
                    <button type="button" class="icon-btn icon-del <%= anyBlocked ? "icon-del-blocked" : "" %>" 
                            title="<%= anyBlocked ? "Cannot delete: Employee work proof or reviews exist" : "Delete Task" %>" 
                            aria-label="Delete Task" 
                            onclick="handleDeleteClick(<%= repId %>, 'TASK #<%= repId %>', '<%= g.getTitle().replace("'", "\\'") %>', <%= anyBlocked %>)">
                      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
                    </button>
                  </div>
                </td>
              </tr>

              <!-- Expanded Sub-Table Drawer for Employee Assignments -->
              <tr class="task-drawer-row" id="<%= drawerId %>">
                <td colspan="7" class="task-drawer-cell">
                  <div class="sub-table-card">
                    <div class="sub-table-header">
                      <div class="sub-table-title">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.5"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
                        <span>Assigned Employees for "<%= g.getTitle() %>" (<%= totalAssigned %>)</span>
                      </div>
                      <div style="font-size:12px; color:var(--slate-500); font-weight:600;">
                        <%= completedCount %> Completed &bull; <%= awaitingCount %> Awaiting Completion
                      </div>
                    </div>
                    <table class="sub-table">
                      <thead>
                        <tr>
                          <th style="width:130px;">Assignment ID</th>
                          <th style="width:220px;">Assigned Employee</th>
                          <th style="width:200px;">Work Proof Deliverables</th>
                          <th style="width:170px;">Status</th>
                          <th>Performance Rating & Feedback</th>
                          <th style="width:105px; text-align:right;">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        <% for (Task subT : g.getEmployeeTasks()) { 
                             boolean subBlocked = subT.isReviewed() || subT.hasWorkProofFile();
                        %>
                          <tr>
                            <td>
                              <span class="task-id-badge" style="font-size:12px;"><%= subT.getFormattedId() %></span>
                            </td>
                            <td>
                              <div class="sub-emp-name"><%= subT.getAssignedToName() != null ? subT.getAssignedToName() : subT.getAssignedTo() %></div>
                              <div class="sub-emp-id"><%= subT.getAssignedTo() %></div>
                            </td>
                            <td>
                              <% if (subT.hasWorkProofFile()) { %>
                                <a href="downloadTaskFile?taskId=<%= subT.getId() %>&type=proof" class="file-pill pill-proof" target="_blank" title="Download Employee Deliverable">
                                  Proof &#10003; (<%= subT.getWorkProofFileCount() %>)
                                </a>
                              <% } else { %>
                                <span class="file-pill pill-no-proof" title="No deliverables submitted yet">No proof yet</span>
                              <% } %>
                            </td>
                            <td>
                              <span class="badge <%= subT.getReviewStatusBadgeClass() %>">
                                <%= subT.getReviewStatusDisplay() %>
                              </span>
                            </td>
                            <td>
                              <% if (subT.isReviewed()) { %>
                                <div style="font-weight:700; color:#f59e0b; font-size:13px; white-space:nowrap;">
                                  <%= subT.getRatingStars() %> <span style="font-size:11.5px; color:#d97706;">(<%= subT.getRating() %>/5)</span>
                                </div>
                                <div style="font-size:11.5px; color:#64748b; margin-top:1px; max-width:240px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;" title="<%= subT.getFeedback() %>">
                                  <%= subT.getFeedback() %>
                                </div>
                              <% } else if ("COMPLETED".equalsIgnoreCase(subT.getStatus()) || subT.hasWorkProofFile()) { %>
                                <a href="viewTask?id=<%= subT.getId() %>" class="action-review-btn">
                                  <svg width="11" height="11" viewBox="0 0 24 24" fill="currentColor"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon></svg>
                                  Review Work
                                </a>
                              <% } else { %>
                                <span style="font-size:12px; color:#94a3b8; font-style:italic; white-space:nowrap;">Awaiting completion</span>
                              <% } %>
                            </td>
                            <td style="text-align:right;">
                              <div class="action-group">
                                <a href="viewTask?id=<%= subT.getId() %>" class="icon-btn icon-view" style="width:28px; height:28px;" title="View Assignment Details" aria-label="View Details">
                                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                                </a>
                                <button type="button" class="icon-btn icon-del <%= subBlocked ? "icon-del-blocked" : "" %>" style="width:28px; height:28px;" 
                                        title="<%= subBlocked ? "Cannot delete: Deliverables or ratings exist" : "Delete Assignment" %>" 
                                        aria-label="Delete Assignment" 
                                        onclick="handleDeleteClick(<%= subT.getId() %>, '<%= subT.getFormattedId() %>', '<%= (subT.getAssignedToName() != null ? subT.getAssignedToName() : subT.getAssignedTo()) + " — " + g.getTitle().replace("'", "\\'") %>', <%= subBlocked %>)">
                                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
                                </button>
                              </div>
                            </td>
                          </tr>
                        <% } %>
                      </tbody>
                    </table>
                  </div>
                </td>
              </tr>
            <% } %>
          </tbody>
        </table>

        <!-- Pagination Controls -->
        <div class="pagination-bar">
          <div id="paginationCount">Showing <%= taskGroups.size() %> Tasks (<%= tasks != null ? tasks.size() : 0 %> Assignments)</div>
          <div class="pagination-nav">
            <button type="button" class="page-btn" id="prevPageBtn" onclick="changePage(-1)">« Prev</button>
            <div id="pageNumbersContainer" style="display:flex; gap:4px;"></div>
            <button type="button" class="page-btn" id="nextPageBtn" onclick="changePage(1)">Next »</button>
          </div>
        </div>
      <% } %>
    </div>
  </div>

  <!-- Delete Confirmation / Blocked Modal -->
  <div class="modal-backdrop" id="deleteModal">
    <div class="modal-box">
      <div id="modalIconWrap" style="width:48px; height:48px; border-radius:50%; background:var(--rose-50); color:var(--rose-500); display:flex; align-items:center; justify-content:center; margin:0 auto 16px;">
        <svg id="delModalIcon" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M3 6h18m-2 0v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6m3 0V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path></svg>
      </div>
      <h3 id="delModalTitle" style="font-size:18px; font-weight:800; color:var(--slate-900); margin-bottom:8px;">Are you sure you want to delete this task?</h3>
      <p id="delTaskPrompt" style="font-size:14px; color:var(--slate-600); margin-bottom:24px; font-weight:500;">Task: Develop Login Module</p>
      
      <form id="delForm" action="deleteTask" method="post" style="display:flex; gap:12px; justify-content:center;">
        <input type="hidden" name="id" id="delTaskId" value="">
        <button type="submit" id="delConfirmBtn" class="btn-create" style="padding:10px 22px; font-size:13.5px; background:#dc2626 !important; border:none; box-shadow:0 4px 12px rgba(220,38,38,0.3);">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
          Yes, Delete
        </button>
        <button type="button" class="btn-reset" onclick="closeModal()" style="padding:10px 22px; font-size:13.5px;">Cancel</button>
      </form>
    </div>
  </div>
  </div><!-- .workspace -->
</div><!-- .app-shell -->

  <script>
    // Expand / Collapse Drawer for each task
    function toggleTaskDrawer(groupIdx) {
      const masterRow = document.getElementById('masterRow_' + groupIdx);
      const drawerRow = document.getElementById('taskDrawer_' + groupIdx);
      if (!masterRow || !drawerRow) return;

      const isExpanded = masterRow.classList.contains('expanded');
      if (isExpanded) {
        masterRow.classList.remove('expanded');
        drawerRow.classList.remove('open');
      } else {
        masterRow.classList.add('expanded');
        drawerRow.classList.add('open');
      }
    }

    function expandAllTasks() {
      document.querySelectorAll('.task-master-row').forEach(row => row.classList.add('expanded'));
      document.querySelectorAll('.task-drawer-row').forEach(row => row.classList.add('open'));
    }

    function collapseAllTasks() {
      document.querySelectorAll('.task-master-row').forEach(row => row.classList.remove('expanded'));
      document.querySelectorAll('.task-drawer-row').forEach(row => row.classList.remove('open'));
    }

    function handleDeleteClick(id, formattedId, title, isBlocked) {
      if (isBlocked) {
        document.getElementById('delModalTitle').textContent = 'Deletion Prohibited';
        document.getElementById('delTaskPrompt').textContent = formattedId + ' (' + title + ') already has submitted deliverables or an evaluation rating. It cannot be deleted.';
        document.getElementById('delConfirmBtn').style.display = 'none';
        document.getElementById('modalIconWrap').style.background = '#fffbeb';
        document.getElementById('modalIconWrap').style.color = '#b45309';
        document.getElementById('delModalIcon').innerHTML = '<circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line>';
      } else {
        document.getElementById('delModalTitle').textContent = 'Are you sure you want to delete this task?';
        document.getElementById('delTaskPrompt').textContent = formattedId + ' — ' + title;
        document.getElementById('delTaskId').value = id;
        document.getElementById('delConfirmBtn').style.display = 'inline-flex';
        document.getElementById('modalIconWrap').style.background = 'var(--rose-50)';
        document.getElementById('modalIconWrap').style.color = 'var(--rose-500)';
        document.getElementById('delModalIcon').innerHTML = '<path d="M3 6h18m-2 0v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6m3 0V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path>';
      }
      document.getElementById('deleteModal').style.display = 'flex';
    }

    function closeModal() {
      document.getElementById('deleteModal').style.display = 'none';
    }

    // Interactive Sorting & Pagination for Master Tasks
    let sortAsc = true;
    let currentPage = 1;
    const pageSize = 10;

    function getMasterRows() {
      const tbody = document.getElementById('tasksTableBody');
      return tbody ? Array.from(tbody.querySelectorAll('.task-master-row')) : [];
    }

    function updatePagination() {
      const rows = getMasterRows();
      const total = rows.length;
      if (total === 0) return;

      const totalPages = Math.max(1, Math.ceil(total / pageSize));
      if (currentPage > totalPages) currentPage = totalPages;
      if (currentPage < 1) currentPage = 1;

      const start = (currentPage - 1) * pageSize;
      const end = Math.min(start + pageSize, total);

      rows.forEach((row, idx) => {
        const drawerId = row.id.replace('masterRow_', 'taskDrawer_');
        const drawer = document.getElementById(drawerId);
        if (idx >= start && idx < end) {
          row.style.display = '';
          if (drawer && row.classList.contains('expanded')) {
            drawer.style.display = 'table-row';
          }
        } else {
          row.style.display = 'none';
          if (drawer) drawer.style.display = 'none';
        }
      });

      const countDisplay = document.getElementById('paginationCount');
      if (countDisplay) {
        countDisplay.textContent = 'Showing ' + (start + 1) + '–' + end + ' of ' + total + ' Tasks';
      }

      const prevBtn = document.getElementById('prevPageBtn');
      if (prevBtn) {
        if (currentPage <= 1) prevBtn.classList.add('disabled');
        else prevBtn.classList.remove('disabled');
      }

      const nextBtn = document.getElementById('nextPageBtn');
      if (nextBtn) {
        if (currentPage >= totalPages) nextBtn.classList.add('disabled');
        else nextBtn.classList.remove('disabled');
      }

      const pageContainer = document.getElementById('pageNumbersContainer');
      if (pageContainer) {
        pageContainer.innerHTML = '';
        for (let p = 1; p <= totalPages; p++) {
          const btn = document.createElement('button');
          btn.type = 'button';
          btn.className = 'page-btn' + (p === currentPage ? ' active' : '');
          btn.textContent = p;
          btn.onclick = () => { currentPage = p; updatePagination(); };
          pageContainer.appendChild(btn);
        }
      }
    }

    function changePage(delta) {
      const rows = getMasterRows();
      const totalPages = Math.max(1, Math.ceil(rows.length / pageSize));
      const target = currentPage + delta;
      if (target >= 1 && target <= totalPages) {
        currentPage = target;
        updatePagination();
      }
    }

    function toggleDateSort() {
      sortAsc = !sortAsc;
      const tbody = document.getElementById('tasksTableBody');
      const masterRows = getMasterRows();

      masterRows.sort((a, b) => {
        const da = a.getAttribute('data-due-date') || '';
        const db = b.getAttribute('data-due-date') || '';
        if (da < db) return sortAsc ? -1 : 1;
        if (da > db) return sortAsc ? 1 : -1;
        return 0;
      });

      masterRows.forEach(mr => {
        tbody.appendChild(mr);
        const drawerId = mr.id.replace('masterRow_', 'taskDrawer_');
        const dr = document.getElementById(drawerId);
        if (dr) tbody.appendChild(dr);
      });

      const indicator = document.getElementById('sortIndicator');
      if (indicator) {
        indicator.innerHTML = sortAsc ? '&#9650;' : '&#9660;';
      }
      currentPage = 1;
      updatePagination();
    }

    document.addEventListener('DOMContentLoaded', () => {
      updatePagination();
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
