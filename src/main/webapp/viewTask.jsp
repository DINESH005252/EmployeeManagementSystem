<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Task, model.User, java.util.List" %>
<%
    User currentUser = (User) session.getAttribute("user");
    String ctx = request.getContextPath();
    Task task = (Task) request.getAttribute("task");
    if (task == null) {
        response.sendRedirect("viewTask");
        return;
    }
    String stClass = "badge-" + (task.getStatus() != null ? task.getStatus().toLowerCase() : "assigned");
    String prClass = "priority-" + (task.getPriority() != null ? task.getPriority().toLowerCase() : "medium");
    boolean isManager = currentUser != null && currentUser.isManager();
    boolean isHr = currentUser != null && currentUser.isHr();
    boolean isEmployee = currentUser != null && currentUser.isEmployee();
    boolean canEdit = isManager; // Manager only!
    String msg = request.getParameter("msg");
    String err = request.getParameter("err");
    String userName = (currentUser != null && currentUser.getUsername() != null) ? currentUser.getUsername() : "User";
    String userInitial = !userName.isEmpty() ? userName.substring(0, 1).toUpperCase() : "U";
    String roleBadge = isHr ? "ADMIN" : (isManager ? "MANAGER" : "EMPLOYEE");
    String empIdDisplay = (currentUser != null && currentUser.getEmployeeId() != null) ? currentUser.getEmployeeId() : "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>WorkPulse — Task Details (<%= task.getFormattedId() %>)</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --brand-dark: #f8fafc;
      --brand-dark-surface: #ffffff;
      --brand-dark-card: #ffffff;
      --brand-dark-card-hover: #f1f5f9;
      --brand-dark-border: #e2e8f0;

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
      --emerald-text: #065f46;

      --rose-500: #f43f5e;
      --rose-50: #fef2f2;
      --rose-border: #fecaca;
      --rose-text: #991b1b;

      --amber-500: #f59e0b;
      --amber-50: #fffbeb;
      --amber-border: #fde68a;
      --amber-text: #92400e;

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
    header.topbar {
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
    .container {
      max-width: 820px;
      width: 100%;
      margin: 28px auto 40px;
      padding: 0 16px;
    }
    .card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-lg);
      padding: 24px 28px;
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.06);
    }
    .card-top {
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      border-bottom: 1px solid var(--slate-200);
      padding-bottom: 14px;
      margin-bottom: 16px;
      gap: 16px;
    }
    .task-title {
      font-size: 21px;
      font-weight: 800;
      color: var(--slate-900);
      letter-spacing: -0.01em;
      margin-top: 5px;
    }
    .task-id-badge {
      font-family: monospace;
      font-size: 13px;
      font-weight: 700;
      color: #1d4ed8;
      background: #eff6ff;
      border: 1px solid #bfdbfe;
      padding: 3px 9px;
      border-radius: 6px;
      display: inline-block;
    }
    .badge {
      display: inline-block;
      padding: 4px 12px;
      border-radius: 9999px;
      font-size: 12px;
      font-weight: 700;
      letter-spacing: 0.02em;
      text-transform: uppercase;
    }
    .badge-assigned { background: #f1f5f9; color: #475569; border: 1px solid #cbd5e1; }
    .badge-in_progress { background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe; }
    .badge-on_hold { background: var(--amber-50); color: var(--amber-text); border: 1px solid var(--amber-border); }
    .badge-completed { background: var(--emerald-50); color: var(--emerald-text); border: 1px solid var(--emerald-border); }
    .badge-cancelled { background: var(--rose-50); color: var(--rose-text); border: 1px solid var(--rose-border); }
    .badge-awaiting { background: #f1f5f9; color: #475569; border: 1px solid #cbd5e1; }
    .badge-pending { background: #fffbeb; color: #b45309; border: 1px solid #fde68a; }
    .badge-reviewed { background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; }
    .priority-pill {
      font-size: 12px;
      font-weight: 700;
      padding: 3px 9px;
      border-radius: 6px;
      display: inline-block;
    }
    .priority-high { background: var(--rose-50); color: var(--rose-text); border: 1px solid var(--rose-border); }
    .priority-medium { background: var(--amber-50); color: var(--amber-text); border: 1px solid var(--amber-border); }
    .priority-low { background: var(--emerald-50); color: var(--emerald-text); border: 1px solid var(--emerald-border); }
    .detail-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      row-gap: 12px;
      column-gap: 22px;
      margin-bottom: 16px;
    }
    @media (max-width: 600px) {
      .detail-grid { grid-template-columns: 1fr; }
    }
    .detail-item {
      display: flex;
      flex-direction: column;
      gap: 3px;
    }
    .detail-label {
      font-size: 11.5px;
      font-weight: 700;
      color: var(--slate-500);
      text-transform: uppercase;
      letter-spacing: 0.04em;
    }
    .detail-val {
      font-size: 14px;
      font-weight: 600;
      color: var(--slate-900);
    }
    .desc-box {
      background: #f8fafc;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-md);
      padding: 12px 16px;
      margin-bottom: 16px;
    }
    .desc-text {
      font-size: 14px;
      color: var(--slate-700);
      line-height: 1.6;
      white-space: pre-wrap;
    }
    .comment-box {
      background: #eff6ff;
      border: 1px solid #bfdbfe;
      border-radius: var(--radius-md);
      padding: 16px 18px;
      margin-bottom: 26px;
    }
    .action-bar {
      display: flex;
      align-items: center;
      gap: 12px;
      border-top: 1px solid var(--slate-200);
      padding-top: 24px;
      flex-wrap: wrap;
    }
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 10px 20px;
      border-radius: 9px;
      font-size: 13.5px;
      font-weight: 700;
      text-decoration: none;
      cursor: pointer;
      transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
      border: 1px solid transparent;
      box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
    }
    .btn-primary {
      background: var(--brand-gradient);
      color: #ffffff;
      border: none;
      box-shadow: 0 2px 8px rgba(37, 99, 235, 0.25);
    }
    .btn-primary:hover {
      transform: translateY(-1.5px);
      box-shadow: 0 4px 14px rgba(37, 99, 235, 0.35);
    }
    .btn-secondary {
      background: var(--slate-100);
      color: var(--slate-700);
      border-color: var(--slate-300);
    }
    .btn-secondary:hover {
      background: var(--slate-200);
      color: var(--slate-900);
      transform: translateY(-1px);
    }
    .btn-danger {
      background: var(--rose-50);
      color: var(--rose-text);
      border-color: var(--rose-border);
    }
    .btn-danger:hover {
      background: #fee2e2;
      color: #7f1d1d;
      transform: translateY(-1px);
    }
    .btn-review {
      background: linear-gradient(135deg, #d97706 0%, #f59e0b 100%);
      color: #ffffff;
      border: none;
      box-shadow: 0 2px 8px rgba(217, 119, 6, 0.25);
    }
    .btn-review:hover {
      background: linear-gradient(135deg, #b45309 0%, #d97706 100%);
      transform: translateY(-1.5px);
      box-shadow: 0 4px 14px rgba(217, 119, 6, 0.35);
    }
    .btn-download {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 7px 14px;
      border-radius: 8px;
      font-size: 12.5px;
      font-weight: 700;
      text-decoration: none;
      transition: all 0.15s ease;
      cursor: pointer;
      flex-shrink: 0;
    }
    .btn-download-work {
      background: #eff6ff;
      border: 1px solid #bfdbfe;
      color: #1d4ed8;
    }
    .btn-download-work:hover {
      background: #dbeafe;
      color: #1e40af;
      transform: translateY(-1px);
    }
    .btn-download-proof {
      background: #ecfdf5;
      border: 1px solid #a7f3d0;
      color: #065f46;
    }
    .btn-download-proof:hover {
      background: #d1fae5;
      color: #064e3b;
      transform: translateY(-1px);
    }

    /* File Attachment Cards & Interactive Dropdown */
    .file-attachment-card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: 10px;
      padding: 12px 16px;
      display: flex;
      flex-direction: column;
      box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
      transition: all 0.2s ease;
    }
    .file-attachment-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 8px;
    }
    .file-dropdown-wrapper {
      position: relative;
      width: 100%;
    }
    .file-dropdown-btn {
      width: 100%;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
      padding: 9px 12px;
      background: #f8fafc;
      border: 1.5px solid var(--slate-300);
      border-radius: 8px;
      color: var(--slate-800);
      font-size: 13px;
      font-weight: 600;
      font-family: inherit;
      cursor: pointer;
      transition: all 0.18s ease;
      text-align: left;
    }
    .file-dropdown-btn:hover {
      background: #ffffff;
      border-color: #94a3b8;
      box-shadow: 0 2px 4px rgba(15, 23, 42, 0.04);
    }
    .file-dropdown-wrapper.open .file-dropdown-btn {
      background: #ffffff;
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12);
    }
    .file-dropdown-wrapper.proof-wrapper.open .file-dropdown-btn {
      border-color: #059669;
      box-shadow: 0 0 0 3px rgba(5, 150, 105, 0.12);
    }
    .file-drop-btn-left {
      display: flex;
      align-items: center;
      gap: 8px;
      min-width: 0;
      flex: 1;
    }
    .file-drop-arrow {
      transition: transform 0.2s ease;
      color: var(--slate-400);
      flex-shrink: 0;
    }
    .file-dropdown-wrapper.open .file-drop-arrow {
      transform: rotate(180deg);
      color: var(--slate-700);
    }
    .file-dropdown-menu {
      display: none;
      margin-top: 8px;
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: 8px;
      padding: 6px;
      max-height: 180px;
      overflow-y: auto;
      box-shadow: 0 4px 12px rgba(15, 23, 42, 0.08);
      animation: dropSlideDown 0.18s ease-out;
    }
    .file-dropdown-wrapper.open .file-dropdown-menu {
      display: flex;
      flex-direction: column;
      gap: 5px;
    }
    @keyframes dropSlideDown {
      from { opacity: 0; transform: translateY(-5px); }
      to { opacity: 1; transform: translateY(0); }
    }
    .file-dropdown-menu::-webkit-scrollbar {
      width: 4px;
    }
    .file-dropdown-menu::-webkit-scrollbar-thumb {
      background: #cbd5e1;
      border-radius: 3px;
    }
    .file-dropdown-item {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
      padding: 7px 10px;
      border-radius: 6px;
      background: #f8fafc;
      border: 1px solid var(--slate-200);
      transition: all 0.15s ease;
    }
    .file-dropdown-item:hover {
      background: #ffffff;
      border-color: #cbd5e1;
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
    }
    .dropdown-item-info {
      display: flex;
      align-items: center;
      gap: 8px;
      min-width: 0;
      flex: 1;
    }
    .dropdown-filename {
      font-size: 12.5px;
      font-weight: 600;
      color: var(--slate-900);
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .dropdown-dl-btn {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      padding: 4px 10px;
      border-radius: 6px;
      font-size: 11.5px;
      font-weight: 700;
      text-decoration: none;
      flex-shrink: 0;
      transition: all 0.15s ease;
      cursor: pointer;
    }
    .dropdown-dl-work {
      background: #eff6ff;
      border: 1px solid #bfdbfe;
      color: #1d4ed8;
    }
    .dropdown-dl-work:hover {
      background: #2563eb;
      border-color: #2563eb;
      color: #ffffff;
    }
    .dropdown-dl-proof {
      background: #ecfdf5;
      border: 1px solid #a7f3d0;
      color: #065f46;
    }
    .dropdown-dl-proof:hover {
      background: #059669;
      border-color: #059669;
      color: #ffffff;
    }
    .file-ext-badge {
      font-size: 9.5px;
      font-weight: 800;
      letter-spacing: 0.04em;
      padding: 2px 5px;
      border-radius: 4px;
      flex-shrink: 0;
      text-transform: uppercase;
    }
    .file-ext-pdf { background: #fee2e2; color: #b91c1c; }
    .file-ext-doc { background: #dbeafe; color: #1d4ed8; }
    .file-ext-zip { background: #fef3c7; color: #92400e; }
    .file-ext-img { background: #ede9fe; color: #6d28d9; }
    .file-ext-gen { background: #e2e8f0; color: #475569; }

    .file-empty-compact {
      display: flex;
      align-items: center;
      gap: 7px;
      padding: 8px 12px;
      background: #f8fafc;
      border: 1px dashed var(--slate-300);
      border-radius: 8px;
      color: var(--slate-400);
      font-size: 12.5px;
      justify-content: center;
    }

    /* Interactive 5-Star Rating Picker */
    .star-rating-container {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .star-rating-bar {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: #fffbeb;
      border: 1px solid #fde68a;
      padding: 8px 14px;
      border-radius: 10px;
      width: fit-content;
    }
    .star-btn {
      background: none;
      border: none;
      cursor: pointer;
      padding: 2px;
      font-size: 26px;
      color: #cbd5e1;
      line-height: 1;
      transition: all 0.15s ease;
    }
    .star-btn:hover,
    .star-btn.hovered,
    .star-btn.active {
      color: #f59e0b;
      transform: scale(1.15);
    }
    .star-label-badge {
      font-size: 13.5px;
      font-weight: 700;
      color: #92400e;
      margin-left: 8px;
    }
  
    /* App Shell & Sidebar */
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
      border-radius: var(--radius-full);
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
    .btn-sidebar-link.on svg { color: var(--primary) !important; }
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
    }
    .page-title {
      font-size: 19px;
      font-weight: 800;
      color: var(--slate-900);
      letter-spacing: -0.02em;
      display: flex;
      align-items: center;
      gap: 8px;
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
      border-radius: var(--radius-full);
      transition: all 0.2s ease;
    }
    .user-badge:hover {
      background: var(--slate-50);
      border-color: var(--slate-300);
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
      box-shadow: 0 2px 6px rgba(37, 99, 235, 0.25);
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
      border: 1px solid var(--slate-200);
      color: var(--slate-600);
      font-size: 12.5px;
      font-weight: 700;
      padding: 7px 14px;
      border-radius: 8px;
      transition: all 0.15s ease;
    }
    .btn-signout:hover {
      background: #fef2f2;
      border-color: #fecaca;
      color: #991b1b;
    }

    /* Content Area */
    .content-wrap {
      padding: 30px 36px;
      max-width: 1240px;
      width: 100%;
      margin: 0 auto;
    }
    .page-header {
      margin-bottom: 22px;
    }
    .page-subtitle {
      font-size: 13.5px;
      color: var(--slate-500);
      line-height: 1.5;
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
      <h1 class="page-title">
        Task Details
      </h1>
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
<div class="container">
    <div class="card">
      <div class="card-top">
        <div>
          <span class="task-id-badge"><%= task.getFormattedId() %></span>
          <h1 class="task-title"><%= task.getTaskTitle() %></h1>
        </div>
        <div style="display:flex; flex-direction:column; align-items:flex-end; gap:8px;">
          <span class="badge <%= task.getReviewStatusBadgeClass() %>"><%= task.getReviewStatusDisplay() %></span>
          <span class="priority-pill <%= prClass %>">Priority: <%= task.getPriority() %></span>
        </div>
      </div>

      <div class="desc-box">
        <div class="detail-label" style="margin-bottom:6px;">Description</div>
        <div class="desc-text"><%= (task.getDescription() != null && !task.getDescription().trim().isEmpty()) ? task.getDescription() : "No detailed description provided." %></div>
      </div>

      <div class="detail-grid">
        <div class="detail-item">
          <span class="detail-label">Assigned To</span>
          <span class="detail-val"><%= task.getAssignedToName() != null ? task.getAssignedToName() : task.getAssignedTo() %> (<%= task.getAssignedTo() %>)</span>
        </div>
        <div class="detail-item">
          <span class="detail-label">Department</span>
          <span class="detail-val"><%= task.getDepartment() != null ? task.getDepartment().trim().toUpperCase() : "GENERAL" %></span>
        </div>
        <div class="detail-item">
          <span class="detail-label">Start Date</span>
          <span class="detail-val"><%= task.getFormattedStartDate() %></span>
        </div>
        <div class="detail-item">
          <span class="detail-label">Due Date</span>
          <span class="detail-val"><%= task.getFormattedDueDate() %></span>
        </div>
        <div class="detail-item">
          <span class="detail-label">Created By</span>
          <span class="detail-val"><%= task.getCreatedByName() != null ? task.getCreatedByName() : task.getCreatedBy() %></span>
        </div>
        <div class="detail-item">
          <span class="detail-label">Created Date</span>
          <span class="detail-val"><%= task.getFormattedCreatedDate() %></span>
        </div>
      </div>

      <!-- File Attachments Section -->
      <div style="display:grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap:14px; margin-bottom:18px; align-items:start;">
        <!-- Work Details Files (Manager Attached) -->
        <div class="file-attachment-card">
          <div class="file-attachment-header">
            <span class="detail-label" style="display:flex; align-items:center; gap:6px;">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline></svg>
              Work Details Specifications
            </span>
            <% if (task.hasWorkFile()) { %>
              <span style="font-size:10.5px; font-weight:700; color:#2563eb; background:#eff6ff; border:1px solid #bfdbfe; padding:1px 6px; border-radius:4px; text-transform:uppercase;"><%= task.getWorkFileCount() %> Attached</span>
            <% } %>
          </div>
          <% if (task.hasWorkFile()) { %>
            <div class="file-dropdown-wrapper" id="workFilesWrapper">
              <button type="button" class="file-dropdown-btn" onclick="toggleFileDropdown('workFilesWrapper')">
                <span class="file-drop-btn-left">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2.2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline></svg>
                  <span>View Specifications (<%= task.getWorkFileCount() %> <%= task.getWorkFileCount() == 1 ? "file" : "files" %>)</span>
                </span>
                <svg class="file-drop-arrow" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="6 9 12 15 18 9"></polyline></svg>
              </button>
              <div class="file-dropdown-menu">
                <% for (String fn : task.getWorkFileList()) { 
                     String orig = util.FileStorageUtil.getOriginalFileName(fn);
                     String ext = "";
                     int dot = orig.lastIndexOf('.');
                     if (dot > 0 && dot < orig.length() - 1) ext = orig.substring(dot + 1).toUpperCase();
                     String badgeClass = "file-ext-gen";
                     if ("PDF".equals(ext)) badgeClass = "file-ext-pdf";
                     else if ("DOC".equals(ext) || "DOCX".equals(ext)) badgeClass = "file-ext-doc";
                     else if ("ZIP".equals(ext) || "RAR".equals(ext) || "7Z".equals(ext) || "TAR".equals(ext)) badgeClass = "file-ext-zip";
                     else if ("PNG".equals(ext) || "JPG".equals(ext) || "JPEG".equals(ext) || "GIF".equals(ext)) badgeClass = "file-ext-img";
                %>
                  <div class="file-dropdown-item">
                    <div class="dropdown-item-info">
                      <% if (!ext.isEmpty()) { %><span class="file-ext-badge <%= badgeClass %>"><%= ext %></span><% } %>
                      <span class="dropdown-filename" title="<%= orig %>"><%= orig %></span>
                    </div>
                    <a href="downloadTaskFile?taskId=<%= task.getId() %>&type=work&file=<%= java.net.URLEncoder.encode(fn, java.nio.charset.StandardCharsets.UTF_8) %>" class="dropdown-dl-btn dropdown-dl-work" target="_blank" title="Download <%= orig %>">
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                      Download
                    </a>
                  </div>
                <% } %>
              </div>
            </div>
          <% } else { %>
            <div class="file-empty-compact">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
              <span>No specification files attached</span>
            </div>
          <% } %>
        </div>

        <!-- Work Proof / Deliverables (Employee Uploaded) -->
        <div class="file-attachment-card">
          <div class="file-attachment-header">
            <span class="detail-label" style="display:flex; align-items:center; gap:6px;">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>
              Work Proof / Deliverables
            </span>
            <% if (task.hasWorkProofFile()) { %>
              <span style="font-size:10.5px; font-weight:700; color:#065f46; background:#ecfdf5; border:1px solid #a7f3d0; padding:1px 6px; border-radius:4px; text-transform:uppercase;"><%= task.getWorkProofFileCount() %> Submitted</span>
            <% } %>
          </div>
          <% if (task.hasWorkProofFile()) { %>
            <div class="file-dropdown-wrapper proof-wrapper" id="proofFilesWrapper">
              <button type="button" class="file-dropdown-btn" onclick="toggleFileDropdown('proofFilesWrapper')">
                <span class="file-drop-btn-left">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#059669" stroke-width="2.2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>
                  <span>View Deliverables (<%= task.getWorkProofFileCount() %> <%= task.getWorkProofFileCount() == 1 ? "file" : "files" %>)</span>
                </span>
                <svg class="file-drop-arrow" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="6 9 12 15 18 9"></polyline></svg>
              </button>
              <div class="file-dropdown-menu">
                <% for (String fn : task.getWorkProofFileList()) { 
                     String orig = util.FileStorageUtil.getOriginalFileName(fn);
                     String ext = "";
                     int dot = orig.lastIndexOf('.');
                     if (dot > 0 && dot < orig.length() - 1) ext = orig.substring(dot + 1).toUpperCase();
                     String badgeClass = "file-ext-gen";
                     if ("PDF".equals(ext)) badgeClass = "file-ext-pdf";
                     else if ("DOC".equals(ext) || "DOCX".equals(ext)) badgeClass = "file-ext-doc";
                     else if ("ZIP".equals(ext) || "RAR".equals(ext) || "7Z".equals(ext) || "TAR".equals(ext)) badgeClass = "file-ext-zip";
                     else if ("PNG".equals(ext) || "JPG".equals(ext) || "JPEG".equals(ext) || "GIF".equals(ext)) badgeClass = "file-ext-img";
                %>
                  <div class="file-dropdown-item">
                    <div class="dropdown-item-info">
                      <% if (!ext.isEmpty()) { %><span class="file-ext-badge <%= badgeClass %>"><%= ext %></span><% } %>
                      <span class="dropdown-filename" title="<%= orig %>"><%= orig %></span>
                    </div>
                    <a href="downloadTaskFile?taskId=<%= task.getId() %>&type=proof&file=<%= java.net.URLEncoder.encode(fn, java.nio.charset.StandardCharsets.UTF_8) %>" class="dropdown-dl-btn dropdown-dl-proof" target="_blank" title="Download <%= orig %>">
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                      Download
                    </a>
                  </div>
                <% } %>
              </div>
            </div>
          <% } else { %>
            <div class="file-empty-compact">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
              <span>No completion proof uploaded by employee yet</span>
            </div>
          <% } %>
        </div>
      </div>

      <% if (task.getEmployeeComment() != null && !task.getEmployeeComment().trim().isEmpty()) { %>
        <div class="comment-box">
          <div class="detail-label" style="color:#1d4ed8; margin-bottom:6px;">Employee Comment</div>
          <div style="font-size:14px; color:var(--slate-800); font-style:italic;"><%= task.getEmployeeComment() %></div>
        </div>
      <% } %>

      <!-- Performance Review & Rating Section -->
      <% if (isEmployee) { %>
        <!-- EMPLOYEE VIEW: Only feedback is visible. Rating and stars are strictly hidden! -->
        <% if (task.hasFeedback()) { %>
          <div style="background:#ecfdf5; border:1px solid #a7f3d0; border-radius:12px; padding:20px; margin-bottom:24px;">
            <div style="display:flex; align-items:center; gap:8px; color:#065f46; font-weight:800; font-size:14px; margin-bottom:8px;">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg>
              Manager Feedback
            </div>
            <div style="font-size:14.5px; color:var(--slate-800); line-height:1.6; white-space:pre-wrap;"><%= task.getFeedback() %></div>
            <div style="font-size:12px; color:var(--slate-500); margin-top:10px;">Reviewed on <%= task.getFormattedReviewedAt() %> by <%= task.getReviewedByName() %></div>
          </div>
        <% } else if ("COMPLETED".equalsIgnoreCase(task.getStatus())) { %>
          <div style="background:#eff6ff; border:1px solid #bfdbfe; border-radius:10px; padding:14px 18px; margin-bottom:24px; font-size:13.5px; color:#1d4ed8; display:flex; align-items:center; gap:8px;">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
            Task completed! Awaiting manager's review and feedback.
          </div>
        <% } %>

      <% } else if (isManager) { %>
        <!-- MANAGER VIEW: Reviews work proof, rates employee (1-5 stars), writes feedback -->
        <% if (task.isReviewed()) { %>
          <div style="background:#fffbeb; border:1px solid #fde68a; border-radius:12px; padding:20px; margin-bottom:24px;">
            <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:10px; flex-wrap:wrap; gap:8px;">
              <div style="color:#92400e; font-weight:800; font-size:14.5px; display:flex; align-items:center; gap:8px;">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="#f59e0b" stroke="#f59e0b" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon></svg>
                Employee Performance Review & Rating
              </div>
              <span style="font-size:15px; font-weight:800; color:#b45309;"><%= task.getRatingStars() %> (<%= task.getRating() %>/5 — <%= task.getPerformanceLabel() %>)</span>
            </div>
            <div style="font-size:14px; color:var(--slate-800); line-height:1.6; white-space:pre-wrap; background:#ffffff; padding:12px 14px; border-radius:8px; border:1px solid #fde68a;"><%= task.getFeedback() %></div>
            <div style="font-size:12px; color:#b45309; margin-top:10px;">Reviewed by <%= task.getReviewedByName() %> on <%= task.getFormattedReviewedAt() %></div>
          </div>
        <% } %>

        <!-- Review / Re-review Form for Manager -->
        <% if (task.isAwaitingCompletion()) { %>
          <div style="background:#f8fafc; border:1.5px dashed var(--slate-300); border-radius:12px; padding:20px 24px; margin-bottom:24px; display:flex; align-items:center; gap:14px;">
            <div style="width:38px; height:38px; border-radius:50%; background:#f1f5f9; border:1px solid #cbd5e1; display:flex; align-items:center; justify-content:center; color:var(--slate-500); flex-shrink:0;">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
            </div>
            <div>
              <div style="font-weight:700; color:var(--slate-800); font-size:14.5px;">Awaiting Task Completion</div>
              <div style="font-size:13px; color:var(--slate-500); margin-top:2px;">Performance evaluation is locked until the employee completes the task assignment and submits deliverables.</div>
            </div>
          </div>
        <% } else { %>
          <div style="background:#ffffff; border:1px solid var(--slate-200); border-radius:14px; padding:24px; margin-bottom:24px; box-shadow:0 1px 3px rgba(15,23,42,0.06);">
            <div style="display:flex; align-items:center; gap:10px; margin-bottom:6px;">
              <div style="width:32px; height:32px; border-radius:8px; background:#fef3c7; color:#d97706; display:flex; align-items:center; justify-content:center;">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon></svg>
              </div>
              <h3 style="font-size:16px; font-weight:800; color:var(--slate-900);">
                <%= task.isReviewed() ? "Update Review & Rating" : "Review Work Proof & Submit Performance Rating" %>
              </h3>
            </div>
            <p style="font-size:13px; color:var(--slate-500); margin-bottom:18px;">
              Evaluate the employee's submitted deliverable. <strong>Note:</strong> Employees will only see your feedback comment; the numerical star rating is confidential to managers and administrators.
            </p>
            <form action="reviewTask" method="post">
              <input type="hidden" name="taskId" value="<%= task.getId() %>">
              <input type="hidden" name="rating" id="ratingInput" value="<%= (task.getRating() != null) ? task.getRating() : 4 %>">

              <div style="margin-bottom:18px;">
                <label style="font-size:13px; font-weight:700; color:var(--slate-700); display:block; margin-bottom:8px;">Performance Rating (1 to 5 Stars) *</label>
                <div class="star-rating-container">
                  <div class="star-rating-bar" id="starBar">
                    <% int curRating = (task.getRating() != null) ? task.getRating() : 4; %>
                    <button type="button" class="star-btn <%= curRating >= 1 ? "active" : "" %>" data-val="1" title="1 Star">&#9733;</button>
                    <button type="button" class="star-btn <%= curRating >= 2 ? "active" : "" %>" data-val="2" title="2 Stars">&#9733;</button>
                    <button type="button" class="star-btn <%= curRating >= 3 ? "active" : "" %>" data-val="3" title="3 Stars">&#9733;</button>
                    <button type="button" class="star-btn <%= curRating >= 4 ? "active" : "" %>" data-val="4" title="4 Stars">&#9733;</button>
                    <button type="button" class="star-btn <%= curRating >= 5 ? "active" : "" %>" data-val="5" title="5 Stars">&#9733;</button>
                    <span class="star-label-badge" id="starLabel">
                      <%= curRating == 5 ? "5 - Outstanding" : (curRating == 4 ? "4 - Very Good" : (curRating == 3 ? "3 - Good" : (curRating == 2 ? "2 - Needs Improvement" : "1 - Poor"))) %>
                    </span>
                  </div>
                </div>
              </div>

              <div style="margin-bottom:18px;">
                <label style="font-size:13px; font-weight:700; color:var(--slate-700); display:block; margin-bottom:8px;">Constructive Feedback (Visible to Employee) *</label>
                <textarea name="feedback" rows="3" required maxlength="1000" placeholder="Provide clear feedback about deliverable quality, execution, timeliness..." style="width:100%; padding:12px 14px; border:1.5px solid var(--slate-300); border-radius:10px; font-family:inherit; font-size:13.5px; background:#ffffff; color:var(--slate-800); box-shadow:0 1px 2px rgba(15,23,42,0.04);"><%= task.getFeedback() != null ? task.getFeedback() : "" %></textarea>
              </div>

              <button type="submit" class="btn btn-review">
                <svg width="17" height="17" viewBox="0 0 24 24" fill="currentColor">
                  <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
                </svg>
                <%= task.isReviewed() ? "Save Changes" : "Submit Review" %>
              </button>
            </form>
          </div>
        <% } %>

      <% } else if (isHr) { %>
        <!-- ADMIN (HR) VIEW: Can see Rating and Feedback, but cannot edit/delete tasks -->
        <% if (task.isReviewed()) { %>
          <div style="background:#fffbeb; border:1px solid #fde68a; border-radius:12px; padding:20px; margin-bottom:24px;">
            <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:10px; flex-wrap:wrap; gap:8px;">
              <div style="color:#92400e; font-weight:800; font-size:14px; display:flex; align-items:center; gap:8px;">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="#f59e0b" stroke="#f59e0b" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon></svg>
                Employee Performance Rating
              </div>
              <span style="font-size:16px; font-weight:800; color:#b45309;"><%= task.getRatingStars() %> (<%= task.getRating() %>/5 — <%= task.getPerformanceLabel() %>)</span>
            </div>
            <div style="font-size:14px; color:var(--slate-800); line-height:1.6; white-space:pre-wrap; background:#ffffff; padding:12px 14px; border-radius:8px; border:1px solid #fde68a;"><%= task.getFeedback() %></div>
            <div style="font-size:12px; color:#b45309; margin-top:10px;">Reviewed by <%= task.getReviewedByName() %> on <%= task.getFormattedReviewedAt() %></div>
          </div>
        <% } else { %>
          <div style="background:#f8fafc; border:1px solid var(--slate-200); border-radius:10px; padding:14px 18px; margin-bottom:24px; font-size:13px; color:var(--slate-500);">
            Status: Awaiting manager's review and performance rating upon task completion.
          </div>
        <% } %>
      <% } %>

      <div class="action-bar">
        <% if (isEmployee || isManager) { %>
          <a href="updateTaskStatus?id=<%= task.getId() %>" class="btn btn-primary">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
            Update Status
          </a>
        <% } %>
        <% if (isManager) { %>
          <a href="editTask?id=<%= task.getId() %>" class="btn btn-secondary">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M17 3a2.828 2.828 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z"></path></svg>
            Edit Task
          </a>
          <a href="deleteTask?id=<%= task.getId() %>" class="btn btn-danger">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
            Delete Task
          </a>
        <% } %>
        <a href="<%= isHr ? "employeePerformance" : (isManager ? "viewTask" : "myTasks") %>" class="btn btn-secondary" style="margin-left:auto;">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><line x1="19" y1="12" x2="5" y2="12"></line><polyline points="12 19 5 12 12 5"></polyline></svg>
          Back to <%= isHr ? "Performance & Ratings" : "Tasks" %>
        </a>
      </div>
    </div>
  </div>

  <script>
    // File Attachments Dropdown Toggle
    function toggleFileDropdown(wrapperId) {
      var w = document.getElementById(wrapperId);
      if (!w) return;
      var isOpen = w.classList.contains('open');
      // Close any other open dropdowns first for clean presentation
      document.querySelectorAll('.file-dropdown-wrapper').forEach(function(el) {
        if (el !== w) el.classList.remove('open');
      });
      w.classList.toggle('open', !isOpen);
    }
    // Close dropdown when clicking outside
    document.addEventListener('click', function(e) {
      if (!e.target.closest('.file-dropdown-wrapper')) {
        document.querySelectorAll('.file-dropdown-wrapper').forEach(function(el) {
          el.classList.remove('open');
        });
      }
    });

    // Interactive 5-Star Rating Picker
    (function initStarRating() {
      var starBtns = document.querySelectorAll('.star-btn');
      var ratingInput = document.getElementById('ratingInput');
      var starLabel = document.getElementById('starLabel');
      if (!starBtns.length || !ratingInput) return;

      var labels = {
        1: '1 - Poor / Unsatisfactory',
        2: '2 - Needs Improvement',
        3: '3 - Good (Meets expectations)',
        4: '4 - Very Good (High quality)',
        5: '5 - Outstanding (Exceeds all expectations)'
      };

      function updateActiveStars(val) {
        starBtns.forEach(function(btn) {
          var bVal = parseInt(btn.getAttribute('data-val'), 10);
          if (bVal <= val) {
            btn.classList.add('active');
          } else {
            btn.classList.remove('active');
          }
        });
        if (starLabel && labels[val]) {
          starLabel.textContent = labels[val];
        }
      }

      function highlightHoverStars(val) {
        starBtns.forEach(function(btn) {
          var bVal = parseInt(btn.getAttribute('data-val'), 10);
          if (bVal <= val) {
            btn.classList.add('hovered');
          } else {
            btn.classList.remove('hovered');
          }
        });
      }

      function clearHoverStars() {
        starBtns.forEach(function(btn) {
          btn.classList.remove('hovered');
        });
      }

      starBtns.forEach(function(btn) {
        var val = parseInt(btn.getAttribute('data-val'), 10);

        btn.addEventListener('mouseenter', function() {
          highlightHoverStars(val);
          if (starLabel && labels[val]) {
            starLabel.textContent = labels[val];
          }
        });

        btn.addEventListener('mouseleave', function() {
          clearHoverStars();
          var currentVal = parseInt(ratingInput.value, 10) || 4;
          if (starLabel && labels[currentVal]) {
            starLabel.textContent = labels[currentVal];
          }
        });

        btn.addEventListener('click', function(e) {
          e.preventDefault();
          ratingInput.value = val;
          updateActiveStars(val);
        });
      });
    })();
  </script>

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
