(function () {
  const FORM = { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8' };

  // WorkPulse Theme Helpers: Clean Loaders and Enterprise Notifications
  function renderLoadingState(text = 'Loading data...') {
    return `
      <div style="display:flex; flex-direction:column; align-items:center; justify-content:center; padding:54px 16px; gap:16px; color:var(--slate-500, #64748b);">
        <div style="width:36px; height:36px; border:3px solid var(--slate-200, #e2e8f0); border-top-color:var(--primary, #2563eb); border-radius:50%; animation:wpSpin 0.7s cubic-bezier(0.4, 0, 0.2, 1) infinite;"></div>
        <span style="font-size:13.5px; font-weight:600; letter-spacing:-0.01em;">${text}</span>
      </div>
      <style>@keyframes wpSpin { to { transform: rotate(360deg); } }</style>
    `;
  }

  function renderErrorBanner(message) {
    return `
      <div class="msg err" style="display:flex; align-items:center; gap:12px; padding:14px 18px; border-radius:8px; margin:16px 0; font-size:13.5px; font-weight:500; background:#fff1f2; border:1px solid #fecdd3; color:#be123c;">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" style="flex-shrink:0;">
          <circle cx="12" cy="12" r="10"></circle>
          <line x1="12" y1="8" x2="12" y2="12"></line>
          <line x1="12" y1="16" x2="12.01" y2="16"></line>
        </svg>
        <span>${message}</span>
      </div>
    `;
  }

  // Modernize raw servlet DOM into an executive, high-end SaaS UI
  function beautifyTeamDom(container) {
    if (!container) return;

    // 1. Elevate "+ Create Team" button into an executive header action bar
    const buttons = Array.from(container.querySelectorAll('button'));
    const createBtn = buttons.find(b => {
      const txt = (b.textContent || '').trim();
      return txt.includes('Create Team') && !b.closest('form.team-form');
    });

    if (createBtn) {
      createBtn.className = 'btn-create-team';
      createBtn.innerHTML = `
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <line x1="12" y1="5" x2="12" y2="19"></line>
          <line x1="5" y1="12" x2="19" y2="12"></line>
        </svg>
        <span>Create New Team</span>
      `;

      const pParent = createBtn.closest('p');

      if (!container.querySelector('.team-top-bar')) {
        const topBar = document.createElement('div');
        topBar.className = 'team-top-bar';
        topBar.innerHTML = `
          <div class="team-header-title">
            <h3>Team Directory</h3>
            <p>Manage organizational teams, assign managers, and configure rosters</p>
          </div>
        `;
        topBar.appendChild(createBtn);

        const searchForm = container.querySelector('form.team-search-form, .team-search-card');
        if (searchForm) {
          searchForm.parentNode.insertBefore(topBar, searchForm);
        } else {
          container.insertBefore(topBar, container.firstChild);
        }
      }

      if (pParent && pParent.children.length === 0) {
        pParent.remove();
      }
    }

    // 2. Ensure Filter button in searchForm has clean styling and icon
    const filterBtn = container.querySelector('form.team-search-form button[type="submit"]');
    if (filterBtn) {
      filterBtn.classList.add('btn-filter');
      if (!filterBtn.querySelector('svg')) {
        filterBtn.innerHTML = `
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="11" cy="11" r="8"></circle>
            <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
          </svg>
          <span>Filter</span>
        `;
      }
    }

    // Wrap buttons into an action-btn-group flex container and mark cell
    container.querySelectorAll('td').forEach(td => {
      const btns = Array.from(td.querySelectorAll('button.view-team, button.edit-team, button.delete-team, button.remove-member'));
      if (btns.length > 0 && !td.querySelector('.action-btn-group')) {
        td.classList.add('actions-cell');
        const grp = document.createElement('div');
        grp.className = 'action-btn-group';
        btns.forEach(b => grp.appendChild(b));
        td.appendChild(grp);
      }
    });

    container.querySelectorAll('th').forEach(th => {
      const txt = (th.textContent || '').trim().toLowerCase();
      if (txt === 'actions' || txt === 'action') {
        th.classList.add('actions-col');
      }
    });

    // 3. Elevate table action buttons (View, Edit, Delete, Remove)
    container.querySelectorAll('button.view-team').forEach(btn => {
      if (!btn.querySelector('svg')) {
        btn.innerHTML = `
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
            <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
            <circle cx="12" cy="12" r="3"></circle>
          </svg>
          <span>View</span>
        `;
      }
    });

    container.querySelectorAll('button.edit-team').forEach(btn => {
      if (!btn.querySelector('svg')) {
        const isDetails = !btn.closest('td');
        btn.innerHTML = `
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
          </svg>
          <span>${isDetails ? 'Edit Team Info' : 'Edit'}</span>
        `;
        if (isDetails && !btn.closest('.team-actions-bar')) {
          const bar = document.createElement('div');
          bar.className = 'team-actions-bar';
          btn.parentNode.insertBefore(bar, btn);
          bar.appendChild(btn);

          const delBtn = container.querySelector('button.delete-team:not(td button)');
          if (delBtn) bar.appendChild(delBtn);
        }
      }
    });

    container.querySelectorAll('button.delete-team, button.remove-member').forEach(btn => {
      if (!btn.querySelector('svg')) {
        const isRemove = btn.classList.contains('remove-member');
        const text = isRemove ? 'Remove' : (btn.closest('td') ? 'Delete' : 'Delete Team');
        btn.innerHTML = `
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="3 6 5 6 21 6"></polyline>
            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
          </svg>
          <span>${text}</span>
        `;
      }
    });

    container.querySelectorAll('button.back-to-list').forEach(btn => {
      if (!btn.querySelector('svg')) {
        btn.innerHTML = `
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
            <line x1="19" y1="12" x2="5" y2="12"></line>
            <polyline points="12 19 5 12 12 5"></polyline>
          </svg>
          <span>Back to Teams</span>
        `;
      }
    });
  }

  async function fetchHtml(url, options) {
    try {
      const r = await fetch(url, options);
      if (r.status === 401) { location.href = 'login.html'; return ''; }
      const text = await r.text();
      const doc = new DOMParser().parseFromString(text, 'text/html');
      const wrap = doc.querySelector('.wrap') || doc.querySelector('.content-wrap') || doc.body;
      if (!wrap) return renderErrorBanner('Unexpected response from the server (status ' + r.status + ').');
      
      const h1 = wrap.querySelector('h1'); 
      if (h1) h1.remove();
      
      beautifyTeamDom(wrap);
      return wrap.innerHTML;
    } catch (e) {
      return renderErrorBanner('Cannot reach the server. Please verify application connectivity.');
    }
  }

  async function show(target, url) {
    target.innerHTML = renderLoadingState('Loading team details...');
    target.innerHTML = await fetchHtml(url);
  }

  async function postThenShowTeam(target, url, params, teamId) {
    target.innerHTML = renderLoadingState('Saving changes...');
    const respHtml = await fetchHtml(url, { method: 'POST', headers: FORM, body: params });
    const tmp = document.createElement('div');
    tmp.innerHTML = respHtml;
    const msgEl = tmp.querySelector('.msg');
    const msgHtml = msgEl ? msgEl.outerHTML : '';
    const viewHtml = await fetchHtml('team?action=view&id=' + teamId);
    target.innerHTML = msgHtml + viewHtml;
  }

  function init(target) {
    target.addEventListener('click', async function (e) {
      const v = e.target.closest('button.view-team');
      if (v) { 
        await show(target, 'team?action=view&id=' + v.dataset.id); 
        return; 
      }

      const ed = e.target.closest('button.edit-team');
      if (ed) { 
        await show(target, 'team?action=editForm&id=' + ed.dataset.id); 
        return; 
      }

      const del = e.target.closest('button.delete-team');
      if (del) {
        if (!window.confirm('Delete team "' + del.dataset.name + '"? This cannot be undone.')) return;
        target.innerHTML = renderLoadingState('Deleting team...');
        target.innerHTML = await fetchHtml('team', {
          method: 'POST', headers: FORM,
          body: new URLSearchParams({ action: 'delete', id: del.dataset.id })
        });
        return;
      }

      const rm = e.target.closest('button.remove-member');
      if (rm) {
        if (!window.confirm('Remove ' + rm.dataset.name + ' from this team?')) return;
        await postThenShowTeam(target, 'team-member',
          new URLSearchParams({ action: 'remove', teamId: rm.dataset.teamId, employeeId: rm.dataset.employeeId }),
          rm.dataset.teamId);
        return;
      }

      const back = e.target.closest('button.back-to-list');
      if (back) { 
        await show(target, 'team?action=list'); 
        return; 
      }
    });

    target.addEventListener('submit', async function (e) {
      const searchForm = e.target.closest('form.team-search-form');
      if (searchForm) {
        e.preventDefault();
        const params = new URLSearchParams(new FormData(searchForm));
        await show(target, 'team?action=list&' + params.toString());
        return;
      }
      
      const form = e.target.closest('form.team-form');
      if (!form) return;
      
      e.preventDefault();
      const url = form.dataset.url || 'team';
      const params = new URLSearchParams(new FormData(form));
      
      if (url === 'team-member') {
        const teamId = form.querySelector('[name=teamId]').value;
        await postThenShowTeam(target, url, params, teamId);
      } else {
        target.innerHTML = renderLoadingState('Processing request...');
        target.innerHTML = await fetchHtml(url, { method: 'POST', headers: FORM, body: params });
      }
    });
  }

  window.TeamsUI = {
    init: init,
    showList: function (target) { show(target, 'team?action=list'); },
    showMyTeams: function (target) { show(target, 'team?action=myteams'); },
    showCreateForm: function (target) { show(target, 'team?action=createForm'); },
    showDashboard: function (target) { show(target, 'team-dashboard'); }
  };
})();
