const state = {
  dashboard: null,
  preview: null,
  activeView: "overview",
  seed: 42
};

const viewEl = document.getElementById("view");
const statusEl = document.getElementById("status");

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

async function requestJson(path) {
  const response = await fetch(path);
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(payload.error || `Request failed: ${response.status}`);
  return payload;
}

function setStatus(message, kind = "") {
  statusEl.textContent = message;
  statusEl.className = `status ${kind}`.trim();
}

async function loadDashboard() {
  try {
    setStatus("Running content validators...");
    state.dashboard = await requestJson("/api/dashboard");
    const summary = state.dashboard.summary || {};
    const kind = summary.errors > 0 ? "error" : "ok";
    setStatus(`Lint complete. ${summary.errors || 0} errors, ${summary.warnings || 0} warnings.`, kind);
    render();
  } catch (error) {
    setStatus(error.message, "error");
  }
}

async function loadPreview(incrementSeed = false) {
  try {
    if (incrementSeed) state.seed += 1;
    state.preview = await requestJson(`/api/preview?seed=${state.seed}`);
    state.activeView = "preview";
    setStatus(`Generated preview seed ${state.seed}.`, "ok");
    render();
  } catch (error) {
    setStatus(error.message, "error");
  }
}

function render() {
  document.querySelectorAll(".nav").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === state.activeView);
  });
  if (state.activeView === "overview") renderOverview();
  if (state.activeView === "tools") renderTools();
  if (state.activeView === "runtime") renderRuntime();
  if (state.activeView === "preview") renderPreview();
  if (state.activeView === "raw") renderRaw();
}

function summary() {
  return state.dashboard?.summary || {};
}

function renderOverview() {
  const data = state.dashboard;
  if (!data) {
    viewEl.innerHTML = `<div class="empty">Dashboard not loaded.</div>`;
    return;
  }
  const s = summary();
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Overview</h2>
        <p>Aggregated validation across content tools, runtime JSON parse checks, and deterministic generated previews.</p>
      </div>
    </div>
    <div class="grid two">
      <div class="card">
        <h3>Content Tools</h3>
        <p><span class="chip">${s.valid_tools || 0}/${s.tools || 0} validators passing</span></p>
        <p><span class="chip">${s.errors || 0} errors</span></p>
        <p><span class="chip">${s.warnings || 0} warnings</span></p>
      </div>
      <div class="card">
        <h3>Runtime JSON</h3>
        <p><span class="chip">${s.valid_runtime_files || 0}/${s.runtime_files || 0} files parse</span></p>
        <p><span class="chip">${tokenTotal()} template token references</span></p>
      </div>
    </div>
    ${crossLintPanel()}
  `;
}

function tokenTotal() {
  return (state.dashboard?.runtime_files || []).reduce((sum, row) => sum + Number(row.token_count || 0), 0);
}

function crossLintPanel() {
  const rows = state.dashboard?.cross_lints || [];
  if (!rows.length) return "";
  return `
    <div class="card" style="margin-top: 14px;">
      <div class="card-header">
        <h3>Cross Lints</h3>
        <span class="chip">${rows.length} notes</span>
      </div>
      <div class="validation-list">
        ${rows.map((row) => `<div class="validation-row ${row.severity === "warning" ? "warning" : ""}">${escapeHtml(row.message)}</div>`).join("")}
      </div>
    </div>
  `;
}

function renderTools() {
  const tools = state.dashboard?.tools || [];
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Tool Lints</h2>
        <p>These are the same validators used by each editor tool, run in one pass.</p>
      </div>
    </div>
    <div class="grid two">
      ${tools.map(toolCard).join("")}
    </div>
  `;
}

function toolCard(tool) {
  const errors = tool.errors || [];
  const warnings = tool.warnings || [];
  return `
    <div class="card">
      <div class="card-header">
        <div class="card-title">
          <h3>${escapeHtml(tool.label)}</h3>
          <span class="chip">${tool.valid ? "valid" : "failing"} / ${tool.duration_ms} ms</span>
        </div>
      </div>
      <p><strong>Source:</strong> ${escapeHtml(tool.source)}</p>
      <p><strong>Runtime:</strong> ${escapeHtml((tool.runtime || []).join(", "))}</p>
      <div class="validation-list">
        ${errors.map((message) => `<div class="validation-row error">${escapeHtml(message)}</div>`).join("")}
        ${warnings.map((message) => `<div class="validation-row warning">${escapeHtml(message)}</div>`).join("")}
        ${!errors.length && !warnings.length ? `<div class="validation-row">No validation messages.</div>` : ""}
      </div>
    </div>
  `;
}

function renderRuntime() {
  const rows = state.dashboard?.runtime_files || [];
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Runtime JSON</h2>
        <p>Parse checks, file sizes, entry counts, and template-token counts for runtime content files.</p>
      </div>
    </div>
    <div class="card">
      <table style="width: 100%; border-collapse: collapse;">
        <thead>
          <tr>
            <th style="text-align:left; padding: 8px; border-bottom: 1px solid var(--line);">File</th>
            <th style="text-align:left; padding: 8px; border-bottom: 1px solid var(--line);">Shape</th>
            <th style="text-align:left; padding: 8px; border-bottom: 1px solid var(--line);">Tokens</th>
            <th style="text-align:left; padding: 8px; border-bottom: 1px solid var(--line);">Messages</th>
          </tr>
        </thead>
        <tbody>
          ${rows.map(runtimeRow).join("")}
        </tbody>
      </table>
    </div>
  `;
}

function runtimeRow(row) {
  const messages = [...(row.errors || []), ...(row.warnings || [])];
  return `
    <tr>
      <td style="vertical-align: top; padding: 8px; border-bottom: 1px solid var(--line);">
        <strong>${escapeHtml(row.path)}</strong><br>
        <span class="chip">${row.valid ? "valid" : "invalid"}</span>
      </td>
      <td style="vertical-align: top; padding: 8px; border-bottom: 1px solid var(--line);">
        ${escapeHtml(row.type)} / ${row.count} entries<br>${Number(row.bytes || 0).toLocaleString()} bytes
      </td>
      <td style="vertical-align: top; padding: 8px; border-bottom: 1px solid var(--line);">
        ${row.token_count || 0}<br>
        <span style="color: var(--muted);">${escapeHtml((row.sample_tokens || []).join(", "))}</span>
      </td>
      <td style="vertical-align: top; padding: 8px; border-bottom: 1px solid var(--line);">
        ${messages.map((message) => `<div>${escapeHtml(message)}</div>`).join("") || "No messages."}
      </td>
    </tr>
  `;
}

function renderPreview() {
  if (!state.preview) {
    viewEl.innerHTML = `
      <div class="section-header">
        <div>
          <h2>Generated Preview</h2>
          <p>No preview generated yet.</p>
        </div>
        <button id="generateInlinePreview" class="primary">Generate Preview</button>
      </div>
    `;
    document.getElementById("generateInlinePreview").addEventListener("click", () => loadPreview(true));
    return;
  }
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Generated Preview</h2>
        <p>Seed ${state.preview.seed}. Samples are deterministic and rendered directly from runtime content JSON.</p>
      </div>
      <button id="generateInlinePreview" class="primary">New Seed</button>
    </div>
    ${state.preview.sections.map(previewSection).join("")}
  `;
  document.getElementById("generateInlinePreview").addEventListener("click", () => loadPreview(true));
}

function previewSection(section) {
  return `
    <div class="card" style="margin-bottom: 14px;">
      <div class="card-header">
        <h3>${escapeHtml(section.label)}</h3>
        <span class="chip">${(section.items || []).length} samples</span>
      </div>
      <div class="grid two">
        ${(section.items || []).map(previewItem).join("")}
      </div>
    </div>
  `;
}

function previewItem(item) {
  return `
    <div class="card">
      <h3>${escapeHtml(item.title)}</h3>
      <p><span class="chip">${escapeHtml(item.meta || "")}</span></p>
      <p style="white-space: pre-wrap;">${escapeHtml(item.body || "")}</p>
    </div>
  `;
}

function renderRaw() {
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Raw JSON</h2>
        <p>Current dashboard and preview payloads.</p>
      </div>
    </div>
    <textarea class="tall">${escapeHtml(JSON.stringify({ dashboard: state.dashboard, preview: state.preview }, null, 2))}</textarea>
  `;
}

document.querySelectorAll(".nav").forEach((button) => {
  button.addEventListener("click", () => {
    state.activeView = button.dataset.view;
    render();
  });
});

document.getElementById("refreshButton").addEventListener("click", loadDashboard);
document.getElementById("previewButton").addEventListener("click", () => loadPreview(true));

loadDashboard().then(() => loadPreview(false));
