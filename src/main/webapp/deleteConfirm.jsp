<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Task, model.User" %>
<%
    Task task = (Task) request.getAttribute("task");
    if (task == null) {
        response.sendRedirect("viewTask");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>WorkPulse — Delete Task</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-main: #f8fafc;
      --bg-card: #ffffff;
      --card-border: #e2e8f0;

      --primary: #2563eb;
      --brand-accent: #3b82f6;

      --slate-50: #f8fafc;
      --slate-100: #f1f5f9;
      --slate-200: #e2e8f0;
      --slate-400: #94a3b8;
      --slate-500: #64748b;
      --slate-600: #475569;
      --slate-700: #334155;
      --slate-800: #1e293b;
      --slate-900: #0f172a;

      --rose-500: #ef4444;
      --rose-50: #fef2f2;
      --rose-border: #fecaca;
      --rose-text: #991b1b;

      --radius-lg: 16px;
      --shadow-card: 0 4px 6px -1px rgba(15, 23, 42, 0.07), 0 2px 4px -2px rgba(15, 23, 42, 0.05);
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Plus Jakarta Sans', 'Inter', sans-serif;
      background: var(--bg-main);
      color: var(--slate-700);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
      -webkit-font-smoothing: antialiased;
    }
    .card {
      width: 100%;
      max-width: 460px;
      background: var(--bg-card);
      border: 1px solid var(--card-border);
      border-radius: var(--radius-lg);
      padding: 36px 30px;
      text-align: center;
      box-shadow: 0 10px 25px -5px rgba(15, 23, 42, 0.08), 0 8px 10px -6px rgba(15, 23, 42, 0.05);
    }
    .icon-box {
      width: 56px;
      height: 56px;
      border-radius: 50%;
      background: var(--rose-50);
      color: var(--rose-500);
      border: 1px solid var(--rose-border);
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 16px;
    }
    h2 {
      font-size: 20px;
      font-weight: 800;
      color: var(--slate-900);
      margin-bottom: 8px;
    }
    .task-preview {
      font-size: 14.5px;
      font-weight: 600;
      color: var(--slate-500);
      margin-bottom: 24px;
    }
    .actions {
      display: flex;
      gap: 12px;
      justify-content: center;
    }
    .btn {
      padding: 11px 22px;
      border-radius: 10px;
      font-size: 14px;
      font-weight: 700;
      text-decoration: none;
      cursor: pointer;
      border: 1px solid transparent;
      transition: all 0.15s;
    }
    .btn-danger { background: #dc2626; color: #ffffff; box-shadow: 0 4px 14px rgba(220, 38, 38, 0.25); }
    .btn-danger:hover { background: #b91c1c; transform: translateY(-1px); }
    .btn-cancel { background: #ffffff; color: var(--slate-700); border: 1.5px solid var(--slate-200); }
    .btn-cancel:hover { background: var(--slate-50); color: var(--slate-900); border-color: var(--slate-400); transform: translateY(-1px); }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon-box">
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
        <path d="M3 6h18m-2 0v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6m3 0V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path>
      </svg>
    </div>
    <h2>Are you sure you want to delete this task?</h2>
    <p class="task-preview">Task: <%= task.getFormattedId() %> — <%= task.getTaskTitle() %></p>
    <form action="deleteTask" method="post" class="actions">
      <input type="hidden" name="id" value="<%= task.getId() %>">
      <button type="submit" class="btn btn-danger">Yes, Delete</button>
      <a href="viewTask" class="btn btn-cancel">Cancel</a>
    </form>
  </div>
</body>
</html>
