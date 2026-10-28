<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.util.Map, model.Employee, model.Team, model.TeamMember, model.User" %>
<%
    User currentUser = (User) session.getAttribute("user");
    String ctx = request.getContextPath();
    boolean isHr = currentUser != null && currentUser.isHr();
    boolean isManager = currentUser != null && currentUser.isManager();
    boolean isEmployee = currentUser != null && currentUser.isEmployee();
    String roleBadge = isHr ? "ADMIN" : (isManager ? "MANAGER" : "EMPLOYEE");
    String userName = (currentUser != null && currentUser.getUsername() != null) ? currentUser.getUsername() : "User";
    String userInitial = !userName.isEmpty() ? userName.substring(0, 1).toUpperCase() : "U";
    List<Team> teams = (List<Team>) request.getAttribute("teams");
    List<Employee> teamEmployees = (List<Employee>) request.getAttribute("teamEmployees");
    Map<Integer, List<TeamMember>> teamMembersMap = (Map<Integer, List<TeamMember>>) request.getAttribute("teamMembersMap");
    Boolean hasTeams = (Boolean) request.getAttribute("hasTeams");
    Boolean hasMembers = (Boolean) request.getAttribute("hasMembers");

    String successMessage = (String) request.getAttribute("successMessage");
    String errorMessage = (String) request.getAttribute("errorMessage");
    String createdTaskId = (String) request.getAttribute("createdTaskId");

    String valTitle = (String) request.getAttribute("taskTitle");
    String valDesc = (String) request.getAttribute("description");
    String valMode = (String) request.getAttribute("assignmentMode");
    if (valMode == null || valMode.trim().isEmpty()) valMode = "single";

    String valAssignedTo = (String) request.getAttribute("assignedTo");
    String valDept = (String) request.getAttribute("department");
    String valPriority = (String) request.getAttribute("priority");
    String valStartDate = (String) request.getAttribute("startDate");
    String valDueDate = (String) request.getAttribute("dueDate");
    String valTargetTeamId = (String) request.getAttribute("targetTeamId");

    boolean noMembersAvailable = (hasMembers != null && !hasMembers) || (teamEmployees == null || teamEmployees.isEmpty());
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>WorkPulse — Create &amp; Assign Task</title>
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
      --rose-500: #f43f5e;
      --rose-50: #fef2f2;
      --rose-border: #fecaca;
      --amber-500: #f59e0b;
      --amber-50: #fffbeb;
      --amber-border: #fde68a;
      --radius-sm: 8px;
      --radius-md: 12px;
      --radius-lg: 16px;
      --radius-full: 9999px;
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
    .page-title {
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
      border-radius: var(--radius-full);
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
    .content-wrap {
      padding: 32px 36px 60px;
      width: 100%;
      max-width: 1100px;
      margin: 0 auto;
    }

    header.topbar_old {
      background: #ffffff;
      border-bottom: 1px solid var(--slate-200);
      padding: 12px 28px;
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
      font-size: 16.5px;
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
      gap: 8px;
    }
    .nav-btn {
      padding: 7px 13px;
      border-radius: var(--radius-sm);
      font-size: 13px;
      font-weight: 600;
      text-decoration: none;
      color: var(--slate-600);
      transition: all 0.15s;
    }
    .nav-btn:hover { background: var(--slate-100); color: var(--slate-900); }
    .nav-btn.active { 
      background: #eff6ff;
      color: #2563eb;
      font-weight: 700;
      border: 1px solid #bfdbfe;
    }
    
    .container {
      max-width: 760px;
      width: 100%;
      margin: 24px auto 40px;
      padding: 0 16px;
    }
    .card {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-lg);
      padding: 28px 32px;
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.06);
    }
    .card-title {
      font-size: 21px;
      font-weight: 800;
      color: var(--slate-900);
      margin-bottom: 4px;
      letter-spacing: -0.02em;
    }
    .card-subtitle {
      font-size: 13.5px;
      color: var(--slate-500);
      margin-bottom: 20px;
    }
    .msg-banner {
      padding: 12px 16px;
      border-radius: var(--radius-md);
      font-size: 13.5px;
      font-weight: 600;
      margin-bottom: 18px;
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .msg-ok { background: var(--emerald-50); color: #065f46; border: 1px solid var(--emerald-border); }
    .msg-err { background: var(--rose-50); color: #991b1b; border: 1px solid var(--rose-border); }
    .msg-warn { background: var(--amber-50); color: #92400e; border: 1px solid var(--amber-border); }

    .form-group {
      margin-bottom: 16px;
    }
    label {
      display: block;
      font-size: 13px;
      font-weight: 700;
      color: var(--slate-700);
      margin-bottom: 6px;
    }
    .label-hint {
      font-weight: 500;
      font-size: 12px;
      color: var(--slate-500);
      margin-left: 4px;
    }
    input[type="text"], input[type="date"], select, textarea {
      width: 100%;
      padding: 10px 13px;
      border: 1.5px solid var(--slate-300);
      border-radius: var(--radius-sm);
      font-size: 13.5px;
      font-family: inherit;
      color: var(--slate-800);
      background: #ffffff;
      transition: all 0.15s ease;
      box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
    }
    input::placeholder, textarea::placeholder {
      color: var(--slate-400);
    }
    input:focus, select:focus, textarea:focus {
      outline: none;
      border-color: var(--brand-accent);
      box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
    }
    select option {
      background: #ffffff;
      color: var(--slate-800);
    }
    .row {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
    }

    /* Assignment Section Box */
    .assignment-box {
      background: #f8fafc;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-md);
      padding: 18px 20px;
      margin-bottom: 18px;
    }
    .assignment-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 12px;
      flex-wrap: wrap;
      gap: 8px;
    }
    .assignment-title {
      font-size: 13px;
      font-weight: 700;
      color: var(--slate-800);
      text-transform: uppercase;
      letter-spacing: 0.04em;
      display: flex;
      align-items: center;
      gap: 7px;
    }
    .team-badge {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      background: #eff6ff;
      border: 1px solid #bfdbfe;
      color: #1d4ed8;
      font-size: 11.5px;
      font-weight: 700;
      padding: 3px 9px;
      border-radius: var(--radius-full);
    }

    /* Segmented Mode Switcher */
    .mode-switcher {
      display: grid;
      grid-template-columns: 1fr 1fr 1fr;
      background: var(--slate-100);
      border: 1px solid var(--slate-200);
      padding: 4px;
      border-radius: 10px;
      gap: 4px;
      margin-bottom: 14px;
    }
    .mode-btn {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 7px;
      padding: 9px 12px;
      background: transparent;
      border: none;
      border-radius: 7px;
      font-family: inherit;
      font-size: 13px;
      font-weight: 600;
      color: var(--slate-600);
      cursor: pointer;
      transition: all 0.16s ease;
    }
    .mode-btn:hover {
      color: var(--slate-900);
    }
    .mode-btn.active {
      background: #ffffff;
      color: #1d4ed8;
      border: 1px solid var(--slate-200);
      font-weight: 700;
      box-shadow: 0 1px 3px rgba(15, 23, 42, 0.08);
    }

    /* Multi-select Member Grid */
    .member-grid-container {
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-sm);
      padding: 10px;
      max-height: 220px;
      overflow-y: auto;
    }
    .member-grid-actions {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 4px 8px;
      border-bottom: 1px solid var(--slate-200);
      margin-bottom: 8px;
    }
    .btn-text-action {
      background: none;
      border: none;
      color: #2563eb;
      font-size: 12px;
      font-weight: 700;
      cursor: pointer;
      padding: 4px 8px;
      border-radius: 4px;
      transition: background 0.15s;
    }
    .btn-text-action:hover {
      background: #eff6ff;
    }
    .member-item-label {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 8px 10px;
      border-radius: 6px;
      cursor: pointer;
      transition: background 0.15s;
      user-select: none;
    }
    .member-item-label:hover {
      background: #f8fafc;
    }
    .member-item-label input[type="checkbox"] {
      width: 16px;
      height: 16px;
      accent-color: var(--primary);
      cursor: pointer;
    }
    .member-avatar-pill {
      width: 28px;
      height: 28px;
      border-radius: 50%;
      background: linear-gradient(135deg, #1d4ed8, #2563eb);
      color: #fff;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 11.5px;
      font-weight: 700;
      flex-shrink: 0;
    }
    .member-info-text {
      flex: 1;
      min-width: 0;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 8px;
    }
    .member-name {
      font-size: 13px;
      font-weight: 600;
      color: var(--slate-800);
    }
    .member-id-tag {
      font-family: monospace;
      font-size: 11px;
      color: var(--slate-500);
      background: var(--slate-100);
      padding: 2px 6px;
      border-radius: 4px;
    }

    /* Broadcast Info Pill */
    .broadcast-info-box {
      background: #eff6ff;
      border: 1px solid #bfdbfe;
      border-radius: var(--radius-sm);
      padding: 12px 14px;
      display: flex;
      align-items: flex-start;
      gap: 10px;
      font-size: 12.5px;
      color: #1d4ed8;
      margin-top: 10px;
    }

    /* Custom File Dropzone UI */
    .file-upload-wrapper {
      width: 100%;
    }
    .file-input-hidden {
      display: none !important;
    }
    .file-dropzone {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 18px 16px;
      background: #f8fafc;
      border: 2px dashed var(--slate-300);
      border-radius: var(--radius-md);
      cursor: pointer;
      transition: all 0.2s ease;
      text-align: center;
    }
    .file-dropzone:hover, .file-dropzone.dragover {
      border-color: #2563eb;
      background: #eff6ff;
    }
    .dropzone-icon {
      width: 38px;
      height: 38px;
      border-radius: 10px;
      background: #eff6ff;
      color: #2563eb;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 8px;
      transition: transform 0.2s ease;
    }
    .file-dropzone:hover .dropzone-icon {
      transform: scale(1.06);
    }
    .dropzone-text {
      font-size: 13px;
      color: var(--slate-700);
      font-weight: 500;
    }
    .dropzone-browse {
      font-weight: 700;
      color: #2563eb;
      text-decoration: underline;
    }
    .dropzone-hint {
      font-size: 11.5px;
      color: var(--slate-500);
      margin-top: 3px;
    }
    /* Multi-file Upload Styling */
    .file-usage-bar-wrap {
      display: none;
      margin-top: 10px;
      padding: 10px 14px;
      background: #ffffff;
      border: 1px solid var(--slate-200);
      border-radius: var(--radius-sm);
    }
    .file-usage-info {
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 12px;
      margin-bottom: 6px;
      color: var(--slate-600);
    }
    .file-usage-progress-track {
      width: 100%;
      height: 7px;
      background: var(--slate-100);
      border-radius: 9999px;
      overflow: hidden;
    }
    .file-usage-progress-bar {
      height: 100%;
      width: 0%;
      background: #2563eb;
      border-radius: 9999px;
      transition: width 0.25s ease, background-color 0.25s ease;
    }
    .file-chips-list {
      display: flex;
      flex-direction: column;
      gap: 7px;
      margin-top: 10px;
      max-height: 240px;
      overflow-y: auto;
    }
    .file-chip-item {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
      padding: 8px 12px;
      background: #f8fafc;
      border: 1px solid var(--slate-200);
      border-radius: 8px;
      transition: all 0.15s ease;
    }
    .file-chip-item:hover {
      border-color: #bfdbfe;
      background: #eff6ff;
    }
    .file-chip-meta {
      display: flex;
      align-items: center;
      gap: 10px;
      min-width: 0;
      flex: 1;
    }
    .file-chip-icon {
      width: 30px;
      height: 30px;
      border-radius: 6px;
      background: #eff6ff;
      color: #1d4ed8;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }
    .file-chip-title {
      font-size: 13px;
      font-weight: 600;
      color: var(--slate-900);
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .file-chip-size {
      font-size: 11.5px;
      color: var(--slate-500);
    }
    .btn-remove-chip {
      background: #fef2f2;
      border: 1px solid #fecaca;
      color: #991b1b;
      border-radius: 6px;
      width: 26px;
      height: 26px;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      flex-shrink: 0;
      transition: all 0.15s;
    }
    .btn-remove-chip:hover {
      background: #fee2e2;
    }

    /* Buttons */
    .btn-primary {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 11px 22px;
      border-radius: var(--radius-sm);
      background: var(--brand-gradient);
      color: #ffffff;
      font-family: inherit;
      font-size: 14px;
      font-weight: 700;
      border: none;
      cursor: pointer;
      transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
      box-shadow: 0 2px 8px rgba(37, 99, 235, 0.25);
      text-decoration: none;
    }
    .btn-primary:hover:not(:disabled) {
      transform: translateY(-1.5px);
      box-shadow: 0 4px 14px rgba(37, 99, 235, 0.35);
    }
    .btn-primary:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }
    .btn-secondary {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 10px 18px;
      border-radius: var(--radius-sm);
      background: var(--slate-100);
      color: var(--slate-700);
      font-family: inherit;
      font-size: 13.5px;
      font-weight: 600;
      border: 1px solid var(--slate-200);
      cursor: pointer;
      transition: all 0.15s ease;
      text-decoration: none;
    }
    .btn-secondary:hover {
      background: var(--slate-200);
      color: var(--slate-900);
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
      <h1 class="page-title">Create &amp; Assign Task</h1>
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
    <div class="card">
      <h1 class="card-title">Create Task</h1>
      <p class="card-subtitle">Assign work orders to your team members, attach requirement specifications, and set deadlines.</p>

      <% if (successMessage != null) { %>
        <div class="msg-banner msg-ok">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg>
          <div><%= successMessage %> <% if (createdTaskId != null) { %><span style="font-family:monospace; background:rgba(16, 185, 129, 0.25); color:#34d399; border:1px solid rgba(16, 185, 129, 0.4); padding:2px 6px; border-radius:4px; margin-left:6px;"><%= createdTaskId %></span><% } %></div>
        </div>
      <% } %>

      <% if (errorMessage != null) { %>
        <div class="msg-banner msg-err">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
          <div><%= errorMessage %></div>
        </div>
      <% } %>

      <% if (noMembersAvailable) { %>
        <div class="msg-banner msg-warn">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>
          <div>
            <b>No Active Team Members Found:</b> You do not currently have any active members assigned to your managed teams. Tasks can only be assigned to employees in your team roster.
            <div style="margin-top:6px;">
              <a href="manager.html" style="color:#fde047; font-weight:700; text-decoration:underline;">Open Manager Portal to Add Team Members &rarr;</a>
            </div>
          </div>
        </div>
      <% } %>

      <form action="createTask" method="post" enctype="multipart/form-data" id="taskForm">
        <!-- Hidden input holding current assignment mode -->
        <input type="hidden" name="assignmentMode" id="assignmentMode" value="<%= valMode %>">

        <div class="form-group">
          <label for="taskTitle">Task Title *</label>
          <input type="text" id="taskTitle" name="taskTitle" required maxlength="150" placeholder="e.g. Develop Login Module" value="<%= valTitle != null ? valTitle : "" %>">
        </div>

        <div class="form-group">
          <label for="description">Task Description</label>
          <textarea id="description" name="description" rows="3" maxlength="1000" placeholder="e.g. Implement login functionality, input validation, and password hashing"><%= valDesc != null ? valDesc : "" %></textarea>
        </div>

        <!-- Work Details / Requirements Upload -->
        <div class="form-group">
          <label for="workDetailsFile">Work Details / Requirements Specifications <span class="label-hint">(Upload multiple files up to 25 MB max total)</span></label>
          <div class="file-upload-wrapper">
            <!-- Form input submitted to server -->
            <input type="file" id="workDetailsFile" name="workDetailsFile" class="file-input-hidden" multiple style="display:none;"
                   accept=".pdf,.doc,.docx,.txt,.zip,.png,.jpg,.jpeg">
            <!-- Helper picker for triggering OS file dialog -->
            <input type="file" id="picker_workDetailsFile" class="file-input-hidden" multiple style="display:none;"
                   accept=".pdf,.doc,.docx,.txt,.zip,.png,.jpg,.jpeg">
            <label for="picker_workDetailsFile" class="file-dropzone" id="dropzone_workDetailsFile">
              <div class="dropzone-icon">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                  <polyline points="17 8 12 3 7 8"></polyline>
                  <line x1="12" y1="3" x2="12" y2="15"></line>
                </svg>
              </div>
              <div class="dropzone-text" id="dropzoneText_workDetailsFile">
                <span class="dropzone-browse">Choose files</span> or drag &amp; drop here
              </div>
              <span class="dropzone-hint">Upload multiple files (PDF, DOCX, TXT, ZIP, PNG, JPG) up to 25 MB total limit</span>
            </label>

            <!-- Usage storage meter -->
            <div class="file-usage-bar-wrap" id="usageWrap_workDetailsFile">
              <div class="file-usage-info">
                <span style="font-weight:700; color:var(--slate-700);" id="usageText_workDetailsFile">0 MB / 25 MB (0 files)</span>
                <span style="color:var(--slate-500);" id="usageRemaining_workDetailsFile">25 MB remaining</span>
              </div>
              <div class="file-usage-progress-track">
                <div class="file-usage-progress-bar" id="usageBar_workDetailsFile"></div>
              </div>
            </div>

            <!-- List of selected file chips -->
            <div class="file-chips-list" id="chipsList_workDetailsFile"></div>
          </div>
        </div>

        <!-- Task Assignment Target Box -->
        <div class="assignment-box">
          <div class="assignment-header">
            <div class="assignment-title">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
              Team Task Assignment Target *
            </div>
            <% if (teams != null && !teams.isEmpty()) { %>
              <div class="team-badge">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg>
                <%= teams.size() %> Team<%= teams.size() > 1 ? "s" : "" %> Under Management
              </div>
            <% } %>
          </div>

          <!-- Mode Switcher -->
          <div class="mode-switcher">
            <button type="button" class="mode-btn <%= "single".equalsIgnoreCase(valMode) ? "active" : "" %>" id="modeBtnSingle" onclick="switchMode('single')">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
              Single Member
            </button>
            <button type="button" class="mode-btn <%= "multiple".equalsIgnoreCase(valMode) ? "active" : "" %>" id="modeBtnMultiple" onclick="switchMode('multiple')">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
              Multiple Members
            </button>
            <button type="button" class="mode-btn <%= "team".equalsIgnoreCase(valMode) ? "active" : "" %>" id="modeBtnTeam" onclick="switchMode('team')">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2" ry="2"></rect><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path></svg>
              Entire Team
            </button>
          </div>

          <!-- Mode 1: Single Member Dropdown -->
          <div id="targetMode_single" style="<%= !"single".equalsIgnoreCase(valMode) ? "display:none;" : "" %>">
            <label for="assignedTo">Select Team Member *</label>
            <select id="assignedTo" name="assignedTo" onchange="autoFillDepartment(this)">
              <option value="">-- Choose Employee From Your Team --</option>
              <% if (teamEmployees != null) {
                   for (Employee emp : teamEmployees) {
                     String sel = (valAssignedTo != null && valAssignedTo.equalsIgnoreCase(emp.getId())) ? "selected" : "";
              %>
                <option value="<%= emp.getId() %>" data-dept="<%= emp.getDepartment() != null ? emp.getDepartment() : "" %>" <%= sel %>>
                  <%= emp.getName() %> (<%= emp.getId() %>)<%= emp.getDepartment() != null && !emp.getDepartment().isEmpty() ? " &bull; " + emp.getDepartment() : "" %>
                </option>
              <%   }
                 } %>
            </select>
            <div style="font-size:12px; color:var(--slate-500); margin-top:5px;">
              Only active members of your assigned teams are available for selection.
            </div>
          </div>

          <!-- Mode 2: Multiple Members Checkboxes -->
          <div id="targetMode_multiple" style="<%= !"multiple".equalsIgnoreCase(valMode) ? "display:none;" : "" %>">
            <div class="member-grid-container">
              <div class="member-grid-actions">
                <span style="font-size:12px; font-weight:700; color:var(--slate-700);" id="selectedCountBadge">
                  0 members selected
                </span>
                <div style="display:flex; gap:6px;">
                  <button type="button" class="btn-text-action" onclick="toggleAllCheckboxes(true)">Select All</button>
                  <button type="button" class="btn-text-action" onclick="toggleAllCheckboxes(false)">Clear</button>
                </div>
              </div>
              <% if (teamEmployees != null && !teamEmployees.isEmpty()) {
                   for (Employee emp : teamEmployees) {
              %>
                <label class="member-item-label">
                  <input type="checkbox" name="assignedEmployees" value="<%= emp.getId() %>" onchange="updateSelectedCount()">
                  <div class="member-avatar-pill">
                    <%= emp.getName() != null && !emp.getName().isEmpty() ? emp.getName().substring(0, 1).toUpperCase() : "E" %>
                  </div>
                  <div class="member-info-text">
                    <span class="member-name"><%= emp.getName() %></span>
                    <div>
                      <% if (emp.getDepartment() != null && !emp.getDepartment().isEmpty()) { %>
                        <span style="font-size:11px; color:#1e40af; background:#dbeafe; padding:2px 6px; border-radius:4px; margin-right:4px;"><%= emp.getDepartment() %></span>
                      <% } %>
                      <span class="member-id-tag"><%= emp.getId() %></span>
                    </div>
                  </div>
                </label>
              <%   }
                 } else { %>
                <div style="text-align:center; padding:16px; color:var(--slate-500); font-size:13px;">No team members found in your roster.</div>
              <% } %>
            </div>
            <div style="font-size:12px; color:var(--slate-500); margin-top:5px;">
              An individual task copy will be created for each selected team member with independent progress tracking.
            </div>
          </div>

          <!-- Mode 3: Entire Team Dropdown -->
          <div id="targetMode_team" style="<%= !"team".equalsIgnoreCase(valMode) ? "display:none;" : "" %>">
            <label for="targetTeamId">Select Managed Team *</label>
            <select id="targetTeamId" name="targetTeamId">
              <option value="">-- Choose Team to Assign --</option>
              <% if (teams != null && teams.size() > 1) { %>
                <option value="ALL" <%= "ALL".equalsIgnoreCase(valTargetTeamId) ? "selected" : "" %>>🌟 All My Managed Teams (Broadcast to All Members)</option>
              <% } %>
              <% if (teams != null) {
                   for (Team t : teams) {
                     String sel = (valTargetTeamId != null && valTargetTeamId.equals(String.valueOf(t.getId()))) ? "selected" : "";
              %>
                <option value="<%= t.getId() %>" <%= sel %>>
                  <%= t.getName() %> (<%= t.getMemberCount() %> active member<%= t.getMemberCount() == 1 ? "" : "s" %>)
                </option>
              <%   }
                 } %>
            </select>
            <div class="broadcast-info-box">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" style="flex-shrink:0; margin-top:1px;"><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"></path></svg>
              <div>
                <b>Instant Team Broadcast:</b> Selecting a team will automatically assign an identical task copy to every active member of that team in one click.
              </div>
            </div>
          </div>
        </div>

        <div class="row">
          <div class="form-group">
            <label for="department">Department</label>
            <input type="text" id="department" name="department" maxlength="100" placeholder="e.g. IT, Engineering" value="<%= valDept != null ? valDept : "" %>">
          </div>

          <div class="form-group">
            <label for="priority">Priority *</label>
            <select id="priority" name="priority" required>
              <option value="LOW" <%= "LOW".equalsIgnoreCase(valPriority) ? "selected" : "" %>>LOW</option>
              <option value="MEDIUM" <%= (valPriority == null || "MEDIUM".equalsIgnoreCase(valPriority)) ? "selected" : "" %>>MEDIUM</option>
              <option value="HIGH" <%= "HIGH".equalsIgnoreCase(valPriority) ? "selected" : "" %>>HIGH</option>
            </select>
          </div>
        </div>

        <div class="row">
          <div class="form-group">
            <label for="startDate">Start Date *</label>
            <input type="date" id="startDate" name="startDate" required value="<%= valStartDate != null ? valStartDate : "" %>">
          </div>

          <div class="form-group">
            <label for="dueDate">Due Date *</label>
            <input type="date" id="dueDate" name="dueDate" required value="<%= valDueDate != null ? valDueDate : "" %>">
          </div>
        </div>

        <div style="display:flex; gap:12px; align-items:center; margin-top:20px;">
          <button type="submit" class="btn-primary" id="btnSubmitTask" style="flex:1;" <%= noMembersAvailable ? "disabled" : "" %>>
            <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M12 5v14m-7-7h14"/></svg>
            Create &amp; Assign Task
          </button>
          <a href="viewTask" class="btn-secondary">Cancel</a>
        </div>
      </form>
    </div>
  </div>
  </div><!-- .workspace -->
</div><!-- .app-shell -->

  <script>
    function switchMode(mode) {
      document.getElementById('assignmentMode').value = mode;

      // Update button styles
      document.getElementById('modeBtnSingle').classList.toggle('active', mode === 'single');
      document.getElementById('modeBtnMultiple').classList.toggle('active', mode === 'multiple');
      document.getElementById('modeBtnTeam').classList.toggle('active', mode === 'team');

      // Update panels
      document.getElementById('targetMode_single').style.display = (mode === 'single') ? 'block' : 'none';
      document.getElementById('targetMode_multiple').style.display = (mode === 'multiple') ? 'block' : 'none';
      document.getElementById('targetMode_team').style.display = (mode === 'team') ? 'block' : 'none';

      // Update required attributes
      var singleSelect = document.getElementById('assignedTo');
      var teamSelect = document.getElementById('targetTeamId');

      if (mode === 'single') {
        singleSelect.setAttribute('required', 'required');
        teamSelect.removeAttribute('required');
      } else if (mode === 'team') {
        teamSelect.setAttribute('required', 'required');
        singleSelect.removeAttribute('required');
      } else {
        singleSelect.removeAttribute('required');
        teamSelect.removeAttribute('required');
      }
    }

    function toggleAllCheckboxes(checked) {
      var cbs = document.querySelectorAll('input[name="assignedEmployees"]');
      cbs.forEach(function(cb) { cb.checked = checked; });
      updateSelectedCount();
    }

    function updateSelectedCount() {
      var checked = document.querySelectorAll('input[name="assignedEmployees"]:checked').length;
      var badge = document.getElementById('selectedCountBadge');
      if (badge) {
        badge.textContent = checked + (checked === 1 ? ' member selected' : ' members selected');
      }
    }

    function autoFillDepartment(selectEl) {
      var opt = selectEl.options[selectEl.selectedIndex];
      if (!opt) return;
      var dept = opt.getAttribute('data-dept');
      var deptInput = document.getElementById('department');
      if (dept && !deptInput.value) {
        deptInput.value = dept;
      }
    }

    // Multi-File Upload Manager (supports multiple files until maxBytes limit is reached)
    function createMultiFileUploadManager(fieldId, maxBytes) {
      var input = document.getElementById(fieldId);
      var picker = document.getElementById('picker_' + fieldId) || input;
      var dropzone = document.getElementById('dropzone_' + fieldId);
      var dropzoneText = document.getElementById('dropzoneText_' + fieldId);
      var usageWrap = document.getElementById('usageWrap_' + fieldId);
      var usageText = document.getElementById('usageText_' + fieldId);
      var usageRemaining = document.getElementById('usageRemaining_' + fieldId);
      var usageBar = document.getElementById('usageBar_' + fieldId);
      var chipsList = document.getElementById('chipsList_' + fieldId);

      var dt = new DataTransfer();

      function syncInput() {
        if (input && dt) {
          try {
            input.files = dt.files;
          } catch (e) {
            console.error('Error syncing files to input:', e);
          }
        }
      }

      function formatBytes(bytes) {
        if (bytes === 0) return '0 Bytes';
        var k = 1024, dm = 1;
        var sizes = ['Bytes', 'KB', 'MB', 'GB'];
        var i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
      }

      function getFileIcon(filename) {
        var ext = filename.split('.').pop().toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif', 'svg'].indexOf(ext) !== -1) {
          return '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>';
        }
        if (['zip', 'rar', 'tar', 'gz', '7z'].indexOf(ext) !== -1) {
          return '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="21 8 21 21 3 21 3 8"/><rect x="1" y="3" width="22" height="5"/><line x1="10" y1="12" x2="14" y2="12"/></svg>';
        }
        return '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>';
      }

      function getTotalBytes() {
        var total = 0;
        for (var i = 0; i < dt.files.length; i++) {
          total += dt.files[i].size;
        }
        return total;
      }

      function render() {
        syncInput();
        var totalBytes = getTotalBytes();
        var count = dt.files.length;

        if (count === 0) {
          if (usageWrap) usageWrap.style.display = 'none';
          if (chipsList) chipsList.innerHTML = '';
          if (dropzoneText) dropzoneText.innerHTML = '<span class="dropzone-browse">Choose files</span> or drag &amp; drop here';
          return;
        }

        if (usageWrap) usageWrap.style.display = 'block';
        var pct = Math.min(100, (totalBytes / maxBytes) * 100);
        if (usageBar) {
          usageBar.style.width = pct + '%';
          if (pct > 95) {
            usageBar.style.backgroundColor = '#ef4444';
          } else if (pct > 70) {
            usageBar.style.backgroundColor = '#f59e0b';
          } else {
            usageBar.style.backgroundColor = '#2563eb';
          }
        }

        if (usageText) {
          usageText.textContent = formatBytes(totalBytes) + ' / ' + formatBytes(maxBytes) + ' (' + count + ' file' + (count === 1 ? '' : 's') + ' attached)';
        }

        var remaining = Math.max(0, maxBytes - totalBytes);
        if (usageRemaining) {
          usageRemaining.textContent = formatBytes(remaining) + ' remaining';
          usageRemaining.style.color = (remaining < 1024 * 1024) ? '#ef4444' : '#64748b';
        }

        if (dropzoneText) {
          if (remaining <= 0) {
            dropzoneText.innerHTML = '<span style="color:#ef4444; font-weight:700;">Maximum limit reached (25 MB)</span> &bull; Remove files to add others';
          } else {
            dropzoneText.innerHTML = '<span class="dropzone-browse">+ Add more files</span> (' + formatBytes(remaining) + ' remaining)';
          }
        }

        if (chipsList) {
          chipsList.innerHTML = '';
          for (var i = 0; i < dt.files.length; i++) {
            (function(index) {
              var f = dt.files[index];
              var item = document.createElement('div');
              item.className = 'file-chip-item';
              item.innerHTML = 
                '<div class="file-chip-meta">' +
                  '<div class="file-chip-icon">' + getFileIcon(f.name) + '</div>' +
                  '<div style="min-width:0;">' +
                    '<div class="file-chip-title" title="' + f.name + '">' + f.name + '</div>' +
                    '<div class="file-chip-size">' + formatBytes(f.size) + '</div>' +
                  '</div>' +
                '</div>' +
                '<button type="button" class="btn-remove-chip" title="Remove file">' +
                  '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>' +
                '</button>';
              
              item.querySelector('.btn-remove-chip').addEventListener('click', function(e) {
                e.stopPropagation();
                removeFile(index);
              });
              chipsList.appendChild(item);
            })(i);
          }
        }
      }

      function addFiles(newFiles) {
        if (!newFiles || newFiles.length === 0) return;
        var currentTotal = getTotalBytes();
        var rejected = [];

        for (var i = 0; i < newFiles.length; i++) {
          var f = newFiles[i];
          var isDup = false;
          for (var j = 0; j < dt.files.length; j++) {
            if (dt.files[j].name === f.name && dt.files[j].size === f.size) {
              isDup = true;
              break;
            }
          }
          if (isDup) continue;

          if (currentTotal + f.size > maxBytes) {
            rejected.push(f.name + ' (' + formatBytes(f.size) + ')');
          } else {
            dt.items.add(f);
            currentTotal += f.size;
          }
        }

        if (rejected.length > 0) {
          alert('Cannot add the following file(s) because they would exceed the total upload limit of ' + formatBytes(maxBytes) + ':\n\n• ' + rejected.join('\n• ') + '\n\nRemaining space: ' + formatBytes(Math.max(0, maxBytes - currentTotal)));
        }

        render();
      }

      function removeFile(index) {
        var newDt = new DataTransfer();
        for (var i = 0; i < dt.files.length; i++) {
          if (i !== index) {
            newDt.items.add(dt.files[i]);
          }
        }
        dt = newDt;
        render();
      }

      if (picker) {
        picker.addEventListener('change', function() {
          addFiles(picker.files);
          picker.value = '';
        });
      }

      if (dropzone) {
        ['dragenter', 'dragover'].forEach(function(evt) {
          dropzone.addEventListener(evt, function(e) {
            e.preventDefault();
            e.stopPropagation();
            dropzone.classList.add('dragover');
          });
        });

        ['dragleave', 'drop'].forEach(function(evt) {
          dropzone.addEventListener(evt, function(e) {
            e.preventDefault();
            e.stopPropagation();
            dropzone.classList.remove('dragover');
          });
        });

        dropzone.addEventListener('drop', function(e) {
          if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files.length > 0) {
            addFiles(e.dataTransfer.files);
          }
        });
      }

      render();
      return {
        getTotalBytes: getTotalBytes,
        syncInput: syncInput
      };
    }

    var workDetailsUploadMgr = createMultiFileUploadManager('workDetailsFile', 25 * 1024 * 1024);

    // Client-side quick check
    document.getElementById('taskForm').addEventListener('submit', function(e) {
      if (workDetailsUploadMgr && workDetailsUploadMgr.syncInput) {
        workDetailsUploadMgr.syncInput();
      }
      var mode = document.getElementById('assignmentMode').value;
      if (mode === 'multiple') {
        var checked = document.querySelectorAll('input[name="assignedEmployees"]:checked').length;
        if (checked === 0) {
          alert('Please select at least one team member from the checklist.');
          e.preventDefault();
          return;
        }
      } else if (mode === 'team') {
        var teamId = document.getElementById('targetTeamId').value;
        if (!teamId) {
          alert('Please select a team to broadcast the task.');
          e.preventDefault();
          return;
        }
      } else {
        var singleEmp = document.getElementById('assignedTo').value;
        if (!singleEmp) {
          alert('Please select an employee to assign the task.');
          e.preventDefault();
          return;
        }
      }

      var start = document.getElementById('startDate').value;
      var due = document.getElementById('dueDate').value;
      if (start && due && due < start) {
        alert('Error: Due date cannot be before start date.');
        e.preventDefault();
      }
    });

    // Initialize mode
    switchMode('<%= valMode %>');
    updateSelectedCount();
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
