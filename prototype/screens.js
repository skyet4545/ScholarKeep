// ============================================================
// All screens for the ScholarKeep v0.5.0 prototype
// Each is a function returning an HTML string.
// ============================================================

const icons = {
  grad: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 3L1 9l4 2.18v6L12 21l7-3.82v-6l2-1.09V17h2V9L12 3zm6.82 6L12 12.72 5.18 9 12 5.28 18.82 9zM17 15.99l-5 2.73-5-2.73v-3.72L12 15l5-2.73v3.72z"/></svg>`,
  scan: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7V4a1 1 0 0 1 1-1h3"/><path d="M17 3h3a1 1 0 0 1 1 1v3"/><path d="M21 17v3a1 1 0 0 1-1 1h-3"/><path d="M7 21H4a1 1 0 0 1-1-1v-3"/><line x1="7" y1="9" x2="17" y2="9"/><line x1="7" y1="13" x2="17" y2="13"/><line x1="7" y1="17" x2="13" y2="17"/></svg>`,
  check: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>`,
  tray: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 12h-6l-2 3h-4l-2-3H2"/><path d="M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/></svg>`,
  shield: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><polyline points="9 12 11 14 15 10"/></svg>`,
  bubble: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/></svg>`,
  recurring: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>`,
  gear: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>`,
  home: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 3l-9 8h2v9h6v-6h2v6h6v-9h2z"/></svg>`,
  person: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></svg>`,
  chart: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M3 13h2v8H3v-8zm4-6h2v14H7V7zm4 3h2v11h-2V10zm4-7h2v18h-2V3zm4 9h2v9h-2v-9z"/></svg>`,
  chevron: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"/></svg>`,
  send: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M2 21l21-9L2 3v7l15 2-15 2z"/></svg>`,
  warning: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>`,
  info: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z"/></svg>`,
  doc: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M14 2H6c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V8l-6-6zm-1 7V3.5L18.5 9H13z"/></svg>`,
};

function statusBar() {
  return `<div class="status-bar">
    <span>9:41</span>
    <span class="icons">●●● 􀙥 􀛨</span>
  </div>`;
}

function tabBar(active) {
  // 4 tabs + center FAB for Scan (Cash App / Day One pattern)
  const navMap = { home: 'dashboard', check: 'chat', claims: 'claims', more: 'more' };
  function tab(key, label, icon) {
    return `<button class="tab ${key === active ? 'active' : ''}" data-nav="${navMap[key]}">${icon}<span>${label}</span></button>`;
  }
  return `<div class="tabbar">
    ${tab('home', 'Home', icons.home)}
    ${tab('check', 'Check', icons.bubble)}
    <button class="fab" data-nav="scanReview" aria-label="Scan receipt">${icons.scan}</button>
    ${tab('claims', 'Claims', icons.tray)}
    ${tab('more', 'More', icons.gear)}
  </div>`;
}

function studentStrip() {
  // Always-visible context: whose data am I looking at?
  return `<button class="student-strip" data-nav="studentDetail">
    <span class="ss-avatar">M</span>
    <span class="ss-name">Maya</span>
    <span class="ss-sub">FES-UA · 2026-27</span>
    <span class="ss-chev">▾</span>
  </button>`;
}

// ===== Screens =====

const Screens = {

  // 1. Welcome
  welcome: () => `
    ${statusBar()}
    <div class="onb-hero">
      <div class="onb-icon">${icons.grad}</div>
      <div>
        <div class="onb-title">Welcome to ScholarKeep</div>
        <div class="onb-body" style="margin-top:12px;">A private companion for Florida ESA scholarship parents — so you never lose a receipt or miss a deadline.</div>
      </div>
      <div class="trust-strip"><span class="dot">●</span> Everything stays on your phone</div>
    </div>
    <div class="onb-footer">
      <button class="btn-primary" data-nav="howItWorks">Get started</button>
    </div>
  `,

  // 2. How it works
  howItWorks: () => `
    ${statusBar()}
    <div class="nav-bar"><button class="nav-action" data-nav="welcome">‹ Back</button><div class="nav-title">How it works</div><span style="width:32px;"></span></div>
    <div class="scroll" style="padding-top:8px;">
      <div class="benefit-card">
        <div class="b-icon">${icons.scan}</div>
        <div>
          <div class="b-title">Scan receipts in seconds</div>
          <div class="b-body">Snap one or many at a time — Apple Vision reads the merchant, amount, and date right on your device.</div>
        </div>
      </div>
      <div class="benefit-card">
        <div class="b-icon">${icons.check}</div>
        <div>
          <div class="b-title">Get a verdict instantly</div>
          <div class="b-body">Tell ScholarKeep what you're buying and it cites the exact Purchasing Guide line that says yes, no, or "needs pre-auth."</div>
        </div>
      </div>
      <div class="benefit-card">
        <div class="b-icon">${icons.tray}</div>
        <div>
          <div class="b-title">Stay submission-ready</div>
          <div class="b-body">Track every claim from draft to paid. Generate a clean PDF package right before the July 31 deadline.</div>
        </div>
      </div>
    </div>
    <div class="onb-footer">
      <button class="btn-primary" data-nav="addStudent">Next</button>
    </div>
  `,

  // 3. Add student
  addStudent: () => `
    ${statusBar()}
    <div class="nav-bar"><button class="nav-action" data-nav="howItWorks">‹ Back</button><div class="nav-title">Add your first student</div><span style="width:32px;"></span></div>
    <div class="scroll" style="padding-top:12px;">
      <div class="field-group">
        <div class="group-header">Student</div>
        <div class="field"><input type="text" placeholder="First name or nickname" value="Maya"/></div>
        <div class="group-footer">You can add a second student later.</div>
      </div>
      <div class="field-group">
        <div class="group-header">Scholarship program</div>
        <div class="field"><select><option>FES-UA — Unique Abilities</option><option>FES-EO — Educational Options</option><option>PEP — Personalized Education Program</option></select></div>
        <button class="btn-text" style="margin-top:6px;padding:8px 4px;" data-nav="programHelp">Not sure which one? →</button>
      </div>
      <div class="card compact">
        <div class="footnote">Award amount, county, grade level, and notes can be added later from the student detail screen.</div>
      </div>
    </div>
    <div class="onb-footer">
      <button class="btn-primary" data-nav="disclaimer">Next</button>
    </div>
  `,

  // 4. Disclaimer
  disclaimer: () => `
    ${statusBar()}
    <div class="nav-bar"><button class="nav-action" data-nav="addStudent">‹ Back</button><div class="nav-title">Disclaimer</div><span style="width:32px;"></span></div>
    <div class="scroll" style="padding-top:8px;">
      <div class="title-1" style="padding:0 0 16px;">Two things to know</div>
      <div class="fact-card warn">
        <div class="f-head">
          <div class="f-icon">${icons.warning}</div>
          <div class="f-title">We're not Step Up, AAA, or the state</div>
        </div>
        <div class="f-body">ScholarKeep is an independent app. It doesn't connect to EMA, SMP, MyScholarShop, Tipalti, or any official portal. You still submit your claims yourself.</div>
      </div>
      <div class="fact-card info">
        <div class="f-head">
          <div class="f-icon">${icons.info}</div>
          <div class="f-title">Verdicts are educated estimates</div>
        </div>
        <div class="f-body">We mirror the official Purchasing Guide as closely as we can, but rules change every year and your SFO has the final say. Always double-check the guide before big purchases.</div>
      </div>
      <details class="disclose-card">
        <summary>
          <span class="d-icon">${icons.doc}</span>
          <span class="d-label">Read the full disclosure</span>
          <span class="d-chev">›</span>
        </summary>
        <div class="disclose-body">
          <p>Not affiliated with the State of Florida, FLDOE, Step Up For Students, AAA Scholarship Foundation, or EMA. ScholarKeep is a personal record-keeping and preparation tool. It does not connect to, submit to, or retrieve data from any official scholarship system.</p>
          <p>Eligibility results are estimates based on published program rules as of the 2026-27 school year and may be incomplete or out of date. Always confirm purchases and requirements against your program's official Purchasing Guide and Family Handbook before buying or submitting.</p>
          <p>You are responsible for your own submissions and records.</p>
        </div>
      </details>
    </div>
    <div class="onb-footer">
      <button class="btn-primary" data-nav="preferences">I understand — continue</button>
    </div>
  `,

  // 5. Preferences
  preferences: () => `
    ${statusBar()}
    <div class="nav-bar"><button class="nav-action" data-nav="disclaimer">‹ Back</button><div class="nav-title">A few preferences</div><span style="width:32px;"></span></div>
    <div class="scroll" style="padding-top:12px;">
      <div class="field-group">
        <div class="group-header">Privacy</div>
        <div class="toggle-row">
          <div class="toggle-content"><div class="toggle-title">Lock with Face ID</div><div class="toggle-sub">Require authentication when you open ScholarKeep.</div></div>
          <div class="toggle on" onclick="this.classList.toggle('on')"></div>
        </div>
        <div class="group-footer">Recommended if your phone is shared.</div>
      </div>
      <div class="field-group">
        <div class="group-header">Reminders</div>
        <div class="toggle-row">
          <div class="toggle-content"><div class="toggle-title">Deadline reminders</div><div class="toggle-sub">July 31 cutoff, pre-auth windows, on-hold clocks.</div></div>
          <div class="toggle on" onclick="this.classList.toggle('on')"></div>
        </div>
        <div class="group-footer">Local notifications only — never sent to a server.</div>
      </div>
      <div class="field-group">
        <div class="group-header">Backup</div>
        <div class="toggle-row">
          <div class="toggle-content"><div class="toggle-title">Back up to iCloud</div><div class="toggle-sub">Off by default. Saves preference; sync ships later.</div></div>
          <div class="toggle" onclick="this.classList.toggle('on')"></div>
        </div>
        <div class="group-footer">All three are optional. Change them anytime in Settings.</div>
      </div>
    </div>
    <div class="onb-footer">
      <button class="btn-primary" data-nav="dashboard">Finish</button>
    </div>
  `,

  // 6. Dashboard / Home — Apple Wallet feel: hero + 3 quick stats + activity
  dashboard: () => `
    ${statusBar()}
    ${studentStrip()}
    <div class="scroll" style="padding-top:8px;">
      <div class="wallet-hero" data-nav="studentDetail">
        <div class="wh-row">
          <span class="eyebrow" style="color:rgba(255,255,255,0.75);">Available now</span>
          <span class="caption" style="color:rgba(255,255,255,0.65);">FES-UA</span>
        </div>
        <div class="wh-number">$3,847.20</div>
        <div class="wh-row">
          <span class="footnote" style="color:rgba(255,255,255,0.8);">of $9,997.00 award</span>
          <span class="footnote" style="color:rgba(255,255,255,0.8);">38%</span>
        </div>
        <div class="wh-progress"><span style="width:38%"></span></div>
      </div>

      <div class="tile-grid">
        <button class="tile" data-nav="claims">
          <div class="t-num">11</div>
          <div class="t-label">Claims</div>
          <div class="t-sub" style="color:var(--status-warn);">1 on hold</div>
        </button>
        <button class="tile" data-nav="chat">
          <div class="t-num">$1,250</div>
          <div class="t-label">Pending</div>
          <div class="t-sub muted">awaiting review</div>
        </button>
        <button class="tile" data-nav="claims">
          <div class="t-num" style="color:var(--status-bad);">5d</div>
          <div class="t-label">Pre-auth cutoff</div>
          <div class="t-sub muted">May 29</div>
        </button>
      </div>

      <div class="section-header"><div class="h-title">Recent activity</div><div class="h-action" data-nav="claims">See all</div></div>
      <div class="card" style="padding:8px 16px;">
        <div class="row" data-nav="claimDetail">
          <div class="row-icon" style="background:var(--status-good-bg);color:var(--status-good);">${icons.check}</div>
          <div class="row-content">
            <div class="row-title">May submission package</div>
            <div class="row-subtitle">Submitted May 15 · $847.20</div>
          </div>
          <div class="chevron">›</div>
        </div>
        <div class="row" data-nav="claimDetail">
          <div class="row-icon" style="background:var(--status-warn-bg);color:var(--status-warn);">${icons.warning}</div>
          <div class="row-content">
            <div class="row-title">April therapy claim</div>
            <div class="row-subtitle">On hold · needs BCBA credentials</div>
          </div>
          <div class="chevron">›</div>
        </div>
        <div class="row" data-nav="scanReview">
          <div class="row-icon">${icons.doc}</div>
          <div class="row-content">
            <div class="row-title">Office Depot · $84.97</div>
            <div class="row-subtitle">Scanned May 23 · likely eligible</div>
          </div>
          <div class="chevron">›</div>
        </div>
      </div>

      <div class="section-header"><div class="h-title">Key dates</div></div>
      <div class="card">
        <div class="deadline-row soon">
          <span class="d-dot"></span>
          <div class="d-content">
            <div class="d-title">Pre-auth cutoff</div>
            <div class="d-sub">May 29</div>
          </div>
          <div class="d-count">5d</div>
        </div>
        <div class="deadline-row soon">
          <span class="d-dot"></span>
          <div class="d-content">
            <div class="d-title">Spend cliff</div>
            <div class="d-sub">June 30</div>
          </div>
          <div class="d-count">37d</div>
        </div>
        <div class="deadline-row far">
          <span class="d-dot"></span>
          <div class="d-content">
            <div class="d-title">Submission cliff</div>
            <div class="d-sub">July 31</div>
          </div>
          <div class="d-count">68d</div>
        </div>
      </div>
    </div>
    ${tabBar('home')}
  `,

  // 7. Scan review
  scanReview: () => `
    ${statusBar()}
    <div class="nav-bar"><button class="nav-action" data-nav="dashboard">‹ Cancel</button><div class="nav-title">Review</div><button class="nav-action" data-nav="dashboard" style="font-weight:600;">Save</button></div>
    <div class="scroll" style="padding-top:8px;">
      <div class="receipt-preview">
        <div style="text-align:center;">
          <div style="font-size:48px;color:var(--text-tertiary);">${icons.doc}</div>
          <div class="footnote" style="margin-top:8px;">Office Depot · receipt</div>
        </div>
        <div class="rx-pages">1 of 3</div>
      </div>

      <div class="card">
        <div class="eyebrow">Verdict</div>
        <div style="display:flex;align-items:center;gap:10px;margin-top:8px;">
          <span class="badge good">${icons.check} Likely eligible</span>
        </div>
        <div class="footnote" style="margin-top:8px;line-height:1.5;">Curriculum and instructional materials are eligible under FES-UA Section 4.2. Keep the itemized receipt and a copy of the curriculum scope-and-sequence.</div>
        <div class="footnote citation" style="margin-top:6px;font-size:11px;">📖 FES-UA Purchasing Guide · §4.2 Instructional materials</div>
      </div>

      <div class="card">
        <div class="row">
          <div class="row-content">
            <div class="footnote">Merchant</div>
            <div class="body" style="margin-top:2px;">Office Depot #1247</div>
          </div>
        </div>
        <div class="row">
          <div class="row-content">
            <div class="footnote">Total</div>
            <div class="body" style="margin-top:2px;font-weight:600;">$84.97</div>
          </div>
        </div>
        <div class="row">
          <div class="row-content">
            <div class="footnote">Purchased</div>
            <div class="body" style="margin-top:2px;">May 23, 2026</div>
          </div>
        </div>
        <div class="row">
          <div class="row-content">
            <div class="footnote">Category</div>
            <div class="body" style="margin-top:2px;">Curriculum</div>
          </div>
          <div class="chevron">›</div>
        </div>
      </div>
    </div>
    ${tabBar('home')}
  `,

  // 8. Can I buy this — chat
  chat: () => `
    ${statusBar()}
    ${studentStrip()}
    <div class="nav-bar" style="padding-top:4px;"><span style="width:60px;"></span><div class="nav-title">Can I buy this?</div><button class="nav-action" style="font-size:15px;">Clear</button></div>
    <div style="padding:2px 16px 8px;display:flex;gap:6px;">
      <span class="pill neutral">Reimburse ▼</span>
    </div>
    <div class="scroll" style="padding:8px 16px 100px;">
      <div class="bubble user">Magic Kingdom annual pass ($1,499)</div>
      <div class="bot-card bad">
        <div class="verdict-line">${icons.warning} Ineligible</div>
        <div class="reason">Entertainment, theme park admission, and personal recreation are explicitly excluded under the FES-UA Purchasing Guide. No documentation will make this eligible.</div>
        <div class="citation">📖 FES-UA Purchasing Guide · §6.1 Excluded purchases</div>
      </div>

      <div class="bubble user">ABA therapy session with BCBA ($180/hr)</div>
      <div class="bot-card good">
        <div class="verdict-line">${icons.check} Eligible</div>
        <div class="reason">Applied Behavior Analysis services from a BCBA are eligible. The provider must be enrolled or you'll need to submit credentials with the claim.</div>
        <div class="citation">📖 FES-UA Purchasing Guide · §3.4 Specialized therapy</div>
      </div>

      <div class="bubble user">Chromebook for school ($329)</div>
      <div class="bot-card warn">
        <div class="verdict-line">${icons.info} Needs pre-auth</div>
        <div class="reason">Devices over $300 require an approved device pre-authorization request <strong>before</strong> purchase. Submit through EMA first.</div>
        <div class="citation">📖 FES-UA Purchasing Guide · §5.1 Technology</div>
      </div>
    </div>
    <div class="chat-input">
      <div class="amount-chip">$ 89</div>
      <div class="input-pill">Co-op tuition</div>
      <button class="send">${icons.send}</button>
    </div>
    ${tabBar('check')}
  `,

  // 9. Claims list
  claims: () => `
    ${statusBar()}
    ${studentStrip()}
    <div class="nav-bar" style="padding-top:4px;"><span style="width:32px;"></span><div class="nav-title">Claims</div><button class="nav-action">+</button></div>
    <div class="scroll" style="padding-top:4px;">
      <div style="display:flex;gap:6px;margin-bottom:16px;overflow-x:auto;padding-bottom:4px;">
        <span class="pill">All 11</span>
        <span class="pill neutral">Draft 3</span>
        <span class="pill neutral">Submitted 2</span>
        <span class="pill neutral">On hold 1</span>
        <span class="pill neutral">Paid 5</span>
      </div>

      <div class="claim-card" data-nav="claimDetail">
        <div class="claim-head">
          <div>
            <div class="claim-title">May submission package</div>
            <div class="claim-meta">4 receipts · submitted May 15</div>
          </div>
          <div class="claim-amount">$847.20</div>
        </div>
        <span class="badge info">${icons.info} Submitted · awaiting review</span>
      </div>

      <div class="claim-card" data-nav="claimDetail">
        <div class="claim-head">
          <div>
            <div class="claim-title">April therapy claim</div>
            <div class="claim-meta">6 receipts · on hold since Apr 28</div>
          </div>
          <div class="claim-amount">$1,240.00</div>
        </div>
        <span class="badge warn">${icons.warning} On hold · needs BCBA credentials</span>
      </div>

      <div class="claim-card" data-nav="claimDetail">
        <div class="claim-head">
          <div>
            <div class="claim-title">March curriculum batch</div>
            <div class="claim-meta">3 receipts · paid Mar 22</div>
          </div>
          <div class="claim-amount">$326.50</div>
        </div>
        <span class="badge good">${icons.check} Paid</span>
      </div>

      <div class="claim-card" data-nav="claimDetail">
        <div class="claim-head">
          <div>
            <div class="claim-title">Device pre-auth #2486</div>
            <div class="claim-meta">1 receipt · draft</div>
          </div>
          <div class="claim-amount">$329.00</div>
        </div>
        <span class="badge" style="background:var(--bg-subtle);color:var(--text-secondary);">Draft</span>
      </div>
    </div>
    ${tabBar('claims')}
  `,

  // 10. Settings
  settings: () => `
    ${statusBar()}
    <div class="nav-bar"><button class="nav-action" data-nav="more">‹ More</button><div class="nav-title">Settings</div><span style="width:32px;"></span></div>
    <div class="large-title">Settings</div>
    <div class="scroll" style="padding-top:4px;">
      <div class="settings-header">Subscription</div>
      <div class="settings-group">
        <div class="settings-row">
          <div class="s-title"><span style="color:var(--status-good);font-weight:600;">Pro is active</span></div>
        </div>
        <div class="settings-row" data-nav="paywall">
          <div class="s-title">Manage subscription</div>
          <div class="s-trail">↗</div>
        </div>
      </div>

      <div class="settings-header">Privacy</div>
      <div class="settings-group">
        <div class="settings-row">
          <div>
            <div class="s-title">Lock with Face ID</div>
            <div class="footnote" style="margin-top:2px;">Authentication required to open.</div>
          </div>
          <div class="toggle on" onclick="this.classList.toggle('on')"></div>
        </div>
      </div>
      <div class="settings-footer">Biometrics or device passcode required. Nothing leaves this device.</div>

      <div class="settings-header" style="margin-top:24px;">Backup</div>
      <div class="settings-group">
        <div class="settings-row">
          <div>
            <div class="s-title">Back up to iCloud</div>
            <div class="footnote" style="margin-top:2px;">Pro required to enable sync.</div>
          </div>
          <div class="toggle" onclick="this.classList.toggle('on')"></div>
        </div>
      </div>

      <div class="settings-header" style="margin-top:24px;">Ruleset</div>
      <div class="settings-group">
        <div class="settings-row">
          <div class="s-title">School year</div>
          <div class="s-trail">2026-27</div>
        </div>
        <div class="settings-row">
          <div class="s-title">Last refresh</div>
          <div class="s-trail">May 23, 9:18 AM</div>
        </div>
        <div class="settings-row">
          <div class="s-title" style="color:var(--accent);">Check for updates</div>
        </div>
      </div>

      <div class="settings-header" style="margin-top:24px;">Account</div>
      <div class="settings-group">
        <div class="settings-row">
          <div>
            <div class="s-title">Signed in as</div>
            <div class="footnote" style="margin-top:2px;">carlos.reyesiii@gmail.com</div>
          </div>
        </div>
        <div class="settings-row" data-nav="welcome">
          <div class="s-title" style="color:var(--status-bad);">Sign out</div>
        </div>
      </div>

      <div class="settings-footer" style="margin-top:32px;text-align:center;padding-bottom:24px;">
        <button class="btn-text" data-nav="welcome" style="font-size:13px;">↺ Restart onboarding (prototype only)</button>
      </div>
    </div>
    ${tabBar('more')}
  `,

  // 10b. More — hub screen (not a junk drawer)
  more: () => `
    ${statusBar()}
    ${studentStrip()}
    <div class="nav-bar" style="padding-top:4px;"><span style="width:32px;"></span><div class="nav-title">More</div><span style="width:32px;"></span></div>
    <div class="large-title">More</div>
    <div class="scroll" style="padding-top:4px;">
      <div class="more-grid">
        <button class="more-tile" data-nav="studentDetail">
          <div class="mt-icon" style="background:var(--accent-soft);color:var(--accent);">${icons.person}</div>
          <div class="mt-title">Students</div>
          <div class="mt-sub">2</div>
        </button>
        <button class="more-tile" data-nav="claims">
          <div class="mt-icon" style="background:var(--accent-soft);color:var(--accent);">${icons.recurring}</div>
          <div class="mt-title">Recurring tasks</div>
          <div class="mt-sub">3 active</div>
        </button>
        <button class="more-tile" data-nav="paywall">
          <div class="mt-icon" style="background:var(--accent-soft);color:var(--accent);">${icons.grad}</div>
          <div class="mt-title">ScholarKeep Pro</div>
          <div class="mt-sub" style="color:var(--status-good);">Active</div>
        </button>
        <button class="more-tile" data-nav="settings">
          <div class="mt-icon" style="background:var(--accent-soft);color:var(--accent);">${icons.gear}</div>
          <div class="mt-title">Settings</div>
          <div class="mt-sub">Privacy, backup, exports</div>
        </button>
      </div>

      <div class="section-header" style="margin-top:24px;"><div class="h-title">Reference</div></div>
      <div class="card" style="padding:0;">
        <div class="row" style="padding:14px 16px;">
          <div class="row-icon">${icons.doc}</div>
          <div class="row-content"><div class="row-title">Reference guide</div><div class="row-subtitle">FES-UA, FES-EO, PEP rules</div></div>
          <div class="chevron">›</div>
        </div>
        <div class="row" style="padding:14px 16px;">
          <div class="row-icon">${icons.info}</div>
          <div class="row-content"><div class="row-title">Disclaimer</div><div class="row-subtitle">Not affiliated with Step Up, AAA, or FLDOE</div></div>
          <div class="chevron">›</div>
        </div>
        <div class="row" style="padding:14px 16px;">
          <div class="row-icon">${icons.shield}</div>
          <div class="row-content"><div class="row-title">Privacy policy</div><div class="row-subtitle">What we never collect</div></div>
          <div class="chevron">›</div>
        </div>
      </div>

      <div class="footnote" style="text-align:center;margin:24px 0 8px;color:var(--text-tertiary);">ScholarKeep v0.5.0 (build 7)</div>
    </div>
    ${tabBar('more')}
  `,

  // 11. Claim detail — sub-screen (no tab bar, has back arrow)
  claimDetail: () => `
    ${statusBar()}
    <div class="nav-bar"><button class="nav-action" data-nav="claims">‹ Claims</button><div class="nav-title">Claim</div><button class="nav-action">⋯</button></div>
    <div class="scroll" style="padding-top:8px;padding-bottom:32px;">
      <div class="title-1" style="padding:4px 0 4px;">May submission package</div>
      <div class="subhead" style="margin-bottom:16px;">Submitted May 15 · awaiting review</div>

      <span class="badge info" style="margin-bottom:16px;display:inline-flex;">${icons.info} Submitted · awaiting review</span>

      <div class="card hero">
        <div class="eyebrow">Total claimed</div>
        <div class="hero-number">$847.20</div>
        <div class="footnote" style="margin-top:6px;">4 receipts · 2 categories</div>
      </div>

      <div class="section-header"><div class="h-title">Receipts</div></div>
      <div class="card" style="padding:8px 16px;">
        <div class="row">
          <div class="row-icon">${icons.doc}</div>
          <div class="row-content">
            <div class="row-title">Office Depot</div>
            <div class="row-subtitle">May 12 · Curriculum · $84.97</div>
          </div>
          <div class="chevron">›</div>
        </div>
        <div class="row">
          <div class="row-icon">${icons.doc}</div>
          <div class="row-content">
            <div class="row-title">Lakeshore Learning</div>
            <div class="row-subtitle">May 8 · Curriculum · $156.40</div>
          </div>
          <div class="chevron">›</div>
        </div>
        <div class="row">
          <div class="row-icon">${icons.doc}</div>
          <div class="row-content">
            <div class="row-title">Dr. Patel · BCBA</div>
            <div class="row-subtitle">May 5 · Therapy · $540.00</div>
          </div>
          <div class="chevron">›</div>
        </div>
        <div class="row">
          <div class="row-icon">${icons.doc}</div>
          <div class="row-content">
            <div class="row-title">Tutor receipt #3148</div>
            <div class="row-subtitle">May 2 · Tutoring · $65.83</div>
          </div>
          <div class="chevron">›</div>
        </div>
      </div>

      <div class="section-header" style="margin-top:16px;"><div class="h-title">Timeline</div></div>
      <div class="card">
        <div class="row" style="padding:8px 0;">
          <div class="row-icon" style="background:var(--status-good-bg);color:var(--status-good);">${icons.check}</div>
          <div class="row-content"><div class="row-title">Submitted</div><div class="row-subtitle">May 15, 10:42 AM</div></div>
        </div>
        <div class="row" style="padding:8px 0;">
          <div class="row-icon" style="background:var(--bg-subtle);color:var(--text-secondary);">${icons.doc}</div>
          <div class="row-content"><div class="row-title">PDF generated</div><div class="row-subtitle">May 15, 10:38 AM</div></div>
        </div>
        <div class="row" style="padding:8px 0;">
          <div class="row-icon" style="background:var(--bg-subtle);color:var(--text-secondary);">${icons.check}</div>
          <div class="row-content"><div class="row-title">Marked ready to submit</div><div class="row-subtitle">May 14, 9:15 PM</div></div>
        </div>
      </div>

      <button class="btn-primary" style="margin-top:24px;">Regenerate PDF</button>
      <button class="btn-secondary" style="margin-top:4px;">Mark as paid</button>
      <button class="btn-secondary" style="color:var(--status-bad);">Delete claim</button>
    </div>
  `,

  // 12. Student detail — sub-screen
  studentDetail: () => `
    ${statusBar()}
    <div class="nav-bar"><button class="nav-action" data-nav="dashboard">‹ Home</button><div class="nav-title">Student</div><button class="nav-action">Edit</button></div>
    <div class="scroll" style="padding-top:8px;padding-bottom:32px;">
      <div style="display:flex;flex-direction:column;align-items:center;gap:8px;padding:20px 0;">
        <div style="width:80px;height:80px;border-radius:24px;background:var(--accent-soft);display:flex;align-items:center;justify-content:center;color:var(--accent);font-size:36px;font-weight:600;">M</div>
        <div class="title-1" style="padding:0;">Maya</div>
        <div style="display:flex;gap:6px;">
          <span class="pill">FES-UA</span>
          <span class="pill neutral">Step Up</span>
          <span class="pill neutral">2026-27</span>
        </div>
      </div>

      <div class="section-header"><div class="h-title">Balance</div><div class="h-action">Ledger</div></div>
      <div class="card">
        <div class="eyebrow">Available</div>
        <div class="hero-number" style="font-size:30px;">$3,847.20</div>
        <div class="progress"><span style="width:38%"></span></div>
        <div class="footnote" style="margin-top:8px;">of $9,997.00 award</div>
      </div>

      <div class="section-header"><div class="h-title">Details</div></div>
      <div class="card" style="padding:0;">
        <div class="row" style="padding:14px 16px;">
          <div class="row-content"><div class="row-subtitle">Grade level</div><div class="row-title">3rd</div></div>
        </div>
        <div class="row" style="padding:14px 16px;">
          <div class="row-content"><div class="row-subtitle">County</div><div class="row-title">Hillsborough</div></div>
        </div>
        <div class="row" style="padding:14px 16px;">
          <div class="row-content"><div class="row-subtitle">Award amount</div><div class="row-title">$9,997.00</div></div>
        </div>
        <div class="row" style="padding:14px 16px;">
          <div class="row-content"><div class="row-subtitle">Notes</div><div class="row-title">IEP diagnosis: dyslexia, ADHD</div></div>
        </div>
      </div>

      <div class="section-header" style="margin-top:16px;"><div class="h-title">Other students</div><div class="h-action">+ Add</div></div>
      <div class="card" style="padding:0;">
        <div class="row" style="padding:14px 16px;">
          <div class="row-icon">${icons.person}</div>
          <div class="row-content"><div class="row-title">Ezra</div><div class="row-subtitle">PEP · 1st grade</div></div>
          <div class="chevron">›</div>
        </div>
      </div>

      <button class="btn-secondary" style="color:var(--status-bad);margin-top:32px;">Delete student</button>
    </div>
  `,

  // 13. Program help sheet
  programHelp: () => `
    ${statusBar()}
    <div class="nav-bar"><span style="width:32px;"></span><div class="nav-title">Pick your program</div><button class="nav-action" data-nav="addStudent">Close</button></div>
    <div class="scroll" style="padding-top:8px;padding-bottom:32px;">
      <div class="subhead" style="margin-bottom:16px;">Not sure which scholarship is yours? Match the description below.</div>

      <div class="card hero" style="margin-bottom:12px;">
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:10px;">
          <span style="font-size:22px;">🧩</span>
          <div><div class="title-3">FES-UA</div><div class="caption">Family Empowerment — Unique Abilities</div></div>
        </div>
        <ul style="margin:0;padding-left:20px;font-size:14px;color:var(--text-secondary);line-height:1.6;">
          <li>Your child has an IEP, 504, or qualifying diagnosis</li>
          <li>Up to ~$10K per year, no income cap</li>
          <li>Largest category list (therapy, curriculum, devices, tuition)</li>
        </ul>
        <button class="btn-primary" style="margin-top:14px;" data-nav="addStudent">This is mine</button>
      </div>

      <div class="card hero" style="margin-bottom:12px;">
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:10px;">
          <span style="font-size:22px;">🎒</span>
          <div><div class="title-3">FES-EO</div><div class="caption">Family Empowerment — Educational Options</div></div>
        </div>
        <ul style="margin:0;padding-left:20px;font-size:14px;color:var(--text-secondary);line-height:1.6;">
          <li>Universal school-choice voucher</li>
          <li>Used for private-school tuition; reimbursements for fees/uniforms/etc</li>
          <li>Tuition usually paid direct to the school</li>
        </ul>
        <button class="btn-primary" style="margin-top:14px;" data-nav="addStudent">This is mine</button>
      </div>

      <div class="card hero">
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:10px;">
          <span style="font-size:22px;">🏠</span>
          <div><div class="title-3">PEP</div><div class="caption">Personalized Education Program (homeschool)</div></div>
        </div>
        <ul style="margin:0;padding-left:20px;font-size:14px;color:var(--text-secondary);line-height:1.6;">
          <li>Homeschool families registered through Step Up's PEP</li>
          <li>Requires an approved Student Learning Plan (SLP) before purchases count</li>
          <li>Up to ~$8K per year; devices NOT eligible</li>
        </ul>
        <button class="btn-primary" style="margin-top:14px;" data-nav="addStudent">This is mine</button>
      </div>

      <div class="footnote" style="margin-top:16px;text-align:center;">Still unsure? Check your acceptance email from Step Up or AAA — the program name is on the first line.</div>
    </div>
  `,

  // 14. Paywall (manage subscription / upgrade)
  paywall: () => `
    ${statusBar()}
    <div class="nav-bar"><button class="nav-action" data-nav="settings">‹ Settings</button><div class="nav-title">ScholarKeep Pro</div><span style="width:32px;"></span></div>
    <div class="scroll" style="padding-top:8px;padding-bottom:32px;">
      <div style="text-align:center;padding:20px 0;">
        <div class="onb-icon" style="margin:0 auto;">${icons.grad}</div>
        <div class="onb-title" style="margin-top:16px;">ScholarKeep Pro</div>
        <div class="onb-body" style="margin-top:8px;color:var(--text-secondary);">Submission-ready packages, exports, and iCloud backup.</div>
      </div>

      <div class="card hero" style="border:2px solid var(--accent);">
        <div style="display:flex;justify-content:space-between;align-items:baseline;">
          <div class="title-2">Yearly</div>
          <div><span class="hero-number" style="font-size:24px;">$39.99</span><span class="footnote">/year</span></div>
        </div>
        <span class="pill" style="margin-top:8px;">SAVE 33% · 7-day free trial</span>
        <button class="btn-primary" style="margin-top:16px;">Current plan</button>
      </div>

      <div class="card">
        <div style="display:flex;justify-content:space-between;align-items:baseline;">
          <div class="title-2">Monthly</div>
          <div><span class="hero-number" style="font-size:24px;">$4.99</span><span class="footnote">/month</span></div>
        </div>
        <button class="btn-secondary" style="margin-top:12px;">Switch to monthly</button>
      </div>

      <div class="section-header" style="margin-top:16px;"><div class="h-title">What's included</div></div>
      <div class="card">
        <div class="row"><div class="row-icon" style="background:var(--status-good-bg);color:var(--status-good);">${icons.check}</div><div class="row-content"><div class="row-title">PDF submission packages</div></div></div>
        <div class="row"><div class="row-icon" style="background:var(--status-good-bg);color:var(--status-good);">${icons.check}</div><div class="row-content"><div class="row-title">CSV exports (full & filtered)</div></div></div>
        <div class="row"><div class="row-icon" style="background:var(--status-good-bg);color:var(--status-good);">${icons.check}</div><div class="row-content"><div class="row-title">iCloud backup</div></div></div>
        <div class="row"><div class="row-icon" style="background:var(--status-good-bg);color:var(--status-good);">${icons.check}</div><div class="row-content"><div class="row-title">Year-end summary report</div></div></div>
        <div class="row"><div class="row-icon" style="background:var(--status-good-bg);color:var(--status-good);">${icons.check}</div><div class="row-content"><div class="row-title">Family Sharing (up to 6)</div></div></div>
      </div>

      <div class="footnote" style="margin-top:16px;text-align:center;line-height:1.6;">Auto-renews via Apple. Cancel anytime in iOS Settings → Subscriptions.</div>
    </div>
  `,
};

const screenOrder = [
  { key: 'welcome', label: 'Welcome', group: 'Onboarding' },
  { key: 'howItWorks', label: 'How it works', group: 'Onboarding' },
  { key: 'addStudent', label: 'Add student', group: 'Onboarding' },
  { key: 'programHelp', label: '↳ Program help sheet', group: 'Onboarding' },
  { key: 'disclaimer', label: 'Disclaimer', group: 'Onboarding' },
  { key: 'preferences', label: 'Preferences', group: 'Onboarding' },
  { key: 'dashboard', label: 'Dashboard / Home', group: 'Main' },
  { key: 'studentDetail', label: '↳ Student detail', group: 'Main' },
  { key: 'scanReview', label: '↳ Scan review', group: 'Main' },
  { key: 'chat', label: 'Can I buy this? (chat)', group: 'Main' },
  { key: 'claims', label: 'Claims list', group: 'Main' },
  { key: 'claimDetail', label: '↳ Claim detail', group: 'Main' },
  { key: 'more', label: 'More (hub)', group: 'Main' },
  { key: 'settings', label: '↳ Settings', group: 'Main' },
  { key: 'paywall', label: '↳ Paywall / Manage Pro', group: 'Main' },
];
