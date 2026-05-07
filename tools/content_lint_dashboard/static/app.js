const state = {
  dashboard: null,
  preview: null,
  previewScan: null,
  activeView: "overview",
  seed: 42,
  scanCount: 20
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
    state.seed = parseInteger(state.seed, 42);
    state.preview = await requestJson(`/api/preview?seed=${state.seed}`);
    state.activeView = "preview";
    const issueCount = state.preview.quality_summary?.issues || 0;
    const kind = issueCount > 0 ? "error" : "ok";
    setStatus(`Generated preview seed ${state.seed}. ${issueCount} quality issues.`, kind);
    render();
  } catch (error) {
    setStatus(error.message, "error");
  }
}

async function loadPreviewScan() {
  try {
    state.seed = parseInteger(state.seed, 42);
    state.scanCount = clamp(parseInteger(state.scanCount, 20), 1, 200);
    state.previewScan = await requestJson(`/api/preview-scan?seed=${state.seed}&count=${state.scanCount}`);
    state.activeView = "previewQa";
    const total = state.previewScan.total_issues || 0;
    const kind = total > 0 ? "error" : "ok";
    setStatus(`Scanned ${state.previewScan.count} preview seeds. ${total} quality issues.`, kind);
    render();
  } catch (error) {
    setStatus(error.message, "error");
  }
}

function parseInteger(value, fallback) {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function render() {
  document.querySelectorAll(".nav").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === state.activeView);
  });
  if (state.activeView === "overview") renderOverview();
  if (state.activeView === "launcher") renderLauncher();
  if (state.activeView === "tools") renderTools();
  if (state.activeView === "runtime") renderRuntime();
  if (state.activeView === "preview") renderPreview();
  if (state.activeView === "previewQa") renderPreviewQa();
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
        <p>Aggregated validation across content tools, runtime JSON parse checks, deterministic generated previews, and preview QA scans.</p>
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
      <div class="card">
        <h3>Generated Preview</h3>
        <p><span class="chip">seed ${state.preview?.seed ?? state.seed}</span></p>
        <p><span class="chip">${state.preview?.quality_summary?.issues ?? 0} quality issues</span></p>
      </div>
      <div class="card">
        <h3>Tool Launcher</h3>
        <p><span class="chip">${(state.dashboard?.tools || []).length} local editors</span></p>
        <p><span class="chip">ports 8765-8774</span></p>
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

function renderLauncher() {
  const tools = state.dashboard?.tools || [];
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Tool Launcher</h2>
        <p>Quick links and commands for the local editor tools. Start an editor in a terminal, then open its local URL.</p>
      </div>
    </div>
    <div class="grid two">
      ${tools.map(launcherCard).join("")}
    </div>
  `;
}

function launcherCard(tool) {
  return `
    <div class="card">
      <div class="card-header">
        <div class="card-title">
          <h3>${escapeHtml(tool.label)}</h3>
          <span class="chip">port ${escapeHtml(tool.port || "")}</span>
        </div>
        <a class="button-link" href="${escapeHtml(tool.launch_url || "#")}" target="_blank" rel="noreferrer">Open</a>
      </div>
      <p>${escapeHtml(tool.description || "")}</p>
      <div class="command-list">
        <div>
          <label>Launch</label>
          <code>${escapeHtml(tool.launch_command || "")}</code>
        </div>
        <div>
          <label>Validate</label>
          <code>${escapeHtml(tool.validate_command || "")}</code>
        </div>
        <div>
          <label>Dry-run Export</label>
          <code>${escapeHtml(tool.dry_run_export_command || "")}</code>
        </div>
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
      <p><strong>Validate:</strong> <code>${escapeHtml(tool.validate_command || "")}</code></p>
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
        ${previewControls()}
      </div>
    `;
    bindPreviewControls();
    return;
  }
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Generated Preview</h2>
        <p>Seed ${state.preview.seed}. Samples are deterministic and rendered directly from runtime content JSON.</p>
      </div>
      ${previewControls()}
    </div>
    ${qualityPanel(state.preview.quality || [])}
    ${state.preview.sections.map(previewSection).join("")}
  `;
  bindPreviewControls();
}

function previewControls() {
  return `
    <div class="control-panel">
      <label for="previewSeed">Seed</label>
      <input id="previewSeed" type="number" value="${escapeHtml(state.seed)}">
      <button id="renderSeedPreview" class="primary">Render Seed</button>
      <button id="nextSeedPreview">Next Seed</button>
      <button id="scanPreviewSeeds">Scan ${state.scanCount} Seeds</button>
    </div>
  `;
}

function bindPreviewControls() {
  const seedInput = document.getElementById("previewSeed");
  if (!seedInput) return;
  seedInput.addEventListener("input", () => {
    state.seed = parseInteger(seedInput.value, state.seed);
  });
  document.getElementById("renderSeedPreview")?.addEventListener("click", () => {
    state.seed = parseInteger(seedInput.value, state.seed);
    loadPreview(false);
  });
  document.getElementById("nextSeedPreview")?.addEventListener("click", () => {
    state.seed = parseInteger(seedInput.value, state.seed);
    loadPreview(true);
  });
  document.getElementById("scanPreviewSeeds")?.addEventListener("click", () => {
    state.seed = parseInteger(seedInput.value, state.seed);
    loadPreviewScan();
  });
}

function qualityPanel(rows) {
  if (!rows.length) {
    return `
      <div class="card quality ok">
        <div class="card-header">
          <h3>Preview Quality</h3>
          <span class="chip">0 issues</span>
        </div>
        <p>No generated-copy issues detected for this seed.</p>
      </div>
    `;
  }
  return `
    <div class="card quality error">
      <div class="card-header">
        <h3>Preview Quality</h3>
        <span class="chip">${rows.length} issues</span>
      </div>
      <div class="validation-list">
        ${rows.slice(0, 12).map(qualityRow).join("")}
      </div>
    </div>
  `;
}

function qualityRow(row) {
  const klass = row.severity === "error" ? "error" : "warning";
  return `
    <div class="validation-row ${klass}">
      <strong>${escapeHtml(row.section_label)} / ${escapeHtml(row.field)}:</strong>
      ${escapeHtml(row.message)}
      <br><span>${escapeHtml(row.sample || row.item_title || "")}</span>
    </div>
  `;
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

function renderPreviewQa() {
  const scan = state.previewScan;
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Preview QA</h2>
        <p>Scan generated previews across a seed range for unresolved tokens, repeated punctuation, spacing issues, empty copy, and long titles.</p>
      </div>
      <div class="control-panel">
        <label for="scanSeed">Start Seed</label>
        <input id="scanSeed" type="number" value="${escapeHtml(state.seed)}">
        <label for="scanCount">Count</label>
        <input id="scanCount" type="number" min="1" max="200" value="${escapeHtml(state.scanCount)}">
        <button id="runPreviewScan" class="primary">Run Scan</button>
      </div>
    </div>
    ${scan ? previewScanSummary(scan) : `<div class="empty">No preview scan has been run yet.</div>`}
  `;
  document.getElementById("runPreviewScan")?.addEventListener("click", () => {
    state.seed = parseInteger(document.getElementById("scanSeed")?.value, state.seed);
    state.scanCount = clamp(parseInteger(document.getElementById("scanCount")?.value, state.scanCount), 1, 200);
    loadPreviewScan();
  });
}

function previewScanSummary(scan) {
  return `
    <div class="card quality ${scan.total_issues ? "error" : "ok"}">
      <div class="card-header">
        <div class="card-title">
          <h3>Scan ${scan.seed}-${scan.seed + scan.count - 1}</h3>
          <span class="chip">${scan.total_issues || 0} issues across ${scan.seeds_with_issues || 0} seeds</span>
        </div>
      </div>
      <div class="validation-list">
        ${(scan.rows || []).map(scanRow).join("")}
      </div>
    </div>
  `;
}

function scanRow(row) {
  const issueText = row.issue_count
    ? (row.issues || []).map((issue) => `${issue.section_label} ${issue.field}: ${issue.message}`).join(" / ")
    : "No quality issues.";
  return `
    <div class="validation-row ${row.issue_count ? "warning" : ""}">
      <strong>Seed ${row.seed}</strong>
      <span class="chip">${row.item_count || 0} samples</span>
      <span class="chip">${row.issue_count || 0} issues</span>
      <div>${escapeHtml(issueText)}</div>
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
    <textarea class="tall">${escapeHtml(JSON.stringify({ dashboard: state.dashboard, preview: state.preview, previewScan: state.previewScan }, null, 2))}</textarea>
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
