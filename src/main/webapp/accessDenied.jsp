<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>WorkPulse — Access Denied</title>
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
      --brand-gradient: linear-gradient(135deg, #1d4ed8 0%, #2563eb 100%);

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
      max-width: 480px;
      background: var(--bg-card);
      border: 1px solid var(--card-border);
      border-radius: 16px;
      padding: 40px 32px;
      text-align: center;
      box-shadow: 0 10px 25px -5px rgba(15, 23, 42, 0.08), 0 8px 10px -6px rgba(15, 23, 42, 0.05);
    }
    .icon-box {
      width: 64px;
      height: 64px;
      border-radius: 50%;
      background: var(--rose-50);
      border: 1px solid var(--rose-border);
      color: var(--rose-500);
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 20px;
    }
    h1 {
      font-size: 24px;
      font-weight: 800;
      color: var(--slate-900);
      margin-bottom: 10px;
      letter-spacing: -0.02em;
    }
    p {
      font-size: 14.5px;
      color: var(--slate-500);
      line-height: 1.6;
      margin-bottom: 28px;
    }
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      padding: 12px 24px;
      border-radius: 10px;
      font-size: 14px;
      font-weight: 700;
      color: #ffffff;
      background: var(--brand-gradient);
      text-decoration: none;
      transition: all 0.2s;
      box-shadow: 0 4px 14px rgba(37, 99, 235, 0.25);
      border: 1px solid rgba(255, 255, 255, 0.2);
    }
    .btn:hover {
      transform: translateY(-1.5px);
      box-shadow: 0 8px 20px rgba(37, 99, 235, 0.35);
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon-box">
      <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="12" cy="12" r="10"></circle>
        <line x1="4.93" y1="4.93" x2="19.07" y2="19.07"></line>
      </svg>
    </div>
    <h1>Access Denied</h1>
    <p><%= request.getAttribute("errorMessage") != null ? request.getAttribute("errorMessage") : "You do not have permission to access this resource. Employees are not authorized to create, edit, or delete tasks." %></p>
    <a href="index.html" class="btn">Return to Portal Home</a>
  </div>
</body>
</html>
