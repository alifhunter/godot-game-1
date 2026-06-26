const state = {
  source: { schema_version: 1, status: "planning_seed", description: "", field_notes: {}, companies: [] },
  metadata: { sectors: [], commodity_ids: [], hook_types: [], hook_visibilities: [], liquidity_profiles: [], volatility_profiles: [] },
  activeView: "overview",
  selectedId: "",
  filter: "",
  dirty: false,
  validation: null,
  rawDraft: ""
};

const viewEl = document.getElementById("view");
const statusEl = document.getElementById("status");

function companies() {
  if (!Array.isArray(state.source.companies)) state.source.companies = [];
  return state.source.companies;
}

function selectedCompany() {
  const rows = companies();
  let company = rows.find((row) => row.id === state.selectedId);
  if (!company && rows.length) {
    company = rows[0];
    state.selectedId = company.id;
  }
  return company || null;
}

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function slugify(value, fallback = "new_company") {
  const cleaned = String(value || "").toLowerCase().replace(/[^a-z0-9_]+/g, "_").replace(/^_+|_+$/g, "");
  return cleaned || fallback;
}

function normalizeTicker(value) {
  return String(value || "").toUpperCase().replace(/[^A-Z0-9]+/g, "").slice(0, 6);
}

function linesToArray(value) {
  return String(value || "")
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
    .filter((line, index, rows) => rows.indexOf(line) === index);
}

function arrayToLines(value) {
  return Array.isArray(value) ? value.join("\n") : "";
}

function mapToLines(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) return "";
  return Object.entries(value)
    .map(([key, score]) => `${key}: ${score}`)
    .join("\n");
}

function linesToMap(value) {
  const map = {};
  for (const line of String(value || "").split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    const separator = trimmed.includes(":") ? ":" : trimmed.includes("=") ? "=" : "";
    if (!separator) continue;
    const [rawKey, ...rest] = trimmed.split(separator);
    const key = slugify(rawKey);
    const score = Number(rest.join(separator).trim());
    if (key && Number.isFinite(score)) map[key] = Math.max(-1, Math.min(1, score));
  }
  return map;
}

function setStatus(message, kind = "") {
  statusEl.textContent = message;
  statusEl.className = `status ${kind}`.trim();
}

function markDirty(message = "Unsaved source changes.") {
  state.dirty = true;
  if (!statusEl.classList.contains("error")) setStatus(message);
}

async function requestJson(path, options = {}) {
  const response = await fetch(path, {
    headers: { "Content-Type": "application/json" },
    ...options
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(payload.error || payload.message || `Request failed: ${response.status}`);
  }
  return payload;
}

async function loadSource() {
  try {
    const [source, metadata] = await Promise.all([
      requestJson("/api/source"),
      requestJson("/api/metadata")
    ]);
    state.source = source;
    state.metadata = metadata;
    state.selectedId = companies()[0]?.id || "";
    state.rawDraft = JSON.stringify(state.source, null, 2);
    state.dirty = false;
    state.validation = null;
    setStatus("Loaded Company Universe source.", "ok");
    render();
  } catch (error) {
    setStatus(error.message, "error");
  }
}

async function saveSource() {
  try {
    const payload = await requestJson("/api/source", {
      method: "POST",
      body: JSON.stringify(state.source)
    });
    state.validation = payload.validation || null;
    state.dirty = false;
    setStatus(validationMessage(`Saved source:\n${payload.path}`, state.validation), state.validation?.valid ? "ok" : "error");
    render();
  } catch (error) {
    setStatus(error.message, "error");
  }
}

async function validateSource() {
  try {
    state.validation = await requestJson("/api/validate", {
      method: "POST",
      body: JSON.stringify(state.source)
    });
    setStatus(validationMessage("Validation complete.", state.validation), state.validation.valid ? "ok" : "error");
    render();
  } catch (error) {
    setStatus(error.message, "error");
  }
}

async function exportSource() {
  try {
    const payload = await requestJson("/api/export", {
      method: "POST",
      body: JSON.stringify(state.source)
    });
    state.validation = payload.validation || null;
    state.dirty = false;
    setStatus(validationMessage(`Exported runtime JSON:\n${payload.runtime_path}`, state.validation), "ok");
    render();
  } catch (error) {
    setStatus(error.message, "error");
  }
}

function validationMessage(prefix, validation) {
  if (!validation) return prefix;
  const errors = validation.errors?.length || 0;
  const warnings = validation.warnings?.length || 0;
  return `${prefix}\n${errors} errors, ${warnings} warnings.`;
}

function render() {
  document.querySelectorAll(".nav").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === state.activeView);
  });
  if (state.activeView === "overview") renderOverview();
  if (state.activeView === "companies") renderCompanies();
  if (state.activeView === "raw") renderRaw();
}

function renderOverview() {
  const rows = companies();
  const sectorCounts = {};
  const commodityKeys = new Set();
  const macroKeys = new Set();
  for (const company of rows) {
    sectorCounts[company.sector] = (sectorCounts[company.sector] || 0) + 1;
    Object.keys(company.commodity_exposures || {}).forEach((key) => commodityKeys.add(key));
    Object.keys(company.macro_exposures || {}).forEach((key) => macroKeys.add(key));
  }
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Overview</h2>
        <p>Dev-only editor for the catalog-backed company universe. Save Source keeps an editable copy in the tool folder; Export Runtime JSON writes the game runtime catalog.</p>
      </div>
    </div>
    <div class="grid three">
      ${statCard("Companies", rows.length)}
      ${statCard("Sectors", Object.keys(sectorCounts).length)}
      ${statCard("Runtime", state.metadata.runtime_path || "data/companies/company_universe_catalog.json")}
    </div>
    <div class="grid two" style="margin-top:14px">
      <div class="card">
        <h3>Catalog Metadata</h3>
        ${textField("Status", state.source.status || "", "source-status")}
        ${textArea("Description", state.source.description || "", "source-description", "data-source-field")}
      </div>
      <div class="card">
        <h3>Sector Counts</h3>
        <div class="chip-list">${Object.entries(sectorCounts).sort().map(([key, count]) => `<span class="chip">${escapeHtml(key)} ${count}</span>`).join("")}</div>
        <h3 style="margin-top:16px">Exposure Keys</h3>
        <p class="muted">Commodity: ${commodityKeys.size}; Macro: ${macroKeys.size}</p>
        <div class="chip-list">${Array.from(commodityKeys).sort().slice(0, 36).map((key) => `<span class="chip">${escapeHtml(key)}</span>`).join("")}</div>
      </div>
    </div>
    ${renderValidationPanel()}
  `;
}

function statCard(label, value) {
  return `<div class="card"><h3>${escapeHtml(label)}</h3><p class="muted" style="font-size:20px;font-weight:800">${escapeHtml(value)}</p></div>`;
}

function renderValidationPanel() {
  const validation = state.validation;
  if (!validation) {
    return `<div class="card" style="margin-top:14px"><h3>Validation</h3><p class="muted">Run Validate to see duplicate ids, ticker issues, unknown sectors, malformed hooks, and exposure range problems.</p></div>`;
  }
  const errors = validation.errors || [];
  const warnings = validation.warnings || [];
  return `
    <div class="grid two" style="margin-top:14px">
      <div class="card">
        <h3>Errors (${errors.length})</h3>
        ${errors.length ? `<ul class="issue-list">${errors.slice(0, 80).map((row) => `<li>${escapeHtml(row)}</li>`).join("")}</ul>` : `<p class="muted">No errors.</p>`}
      </div>
      <div class="card">
        <h3>Warnings (${warnings.length})</h3>
        ${warnings.length ? `<ul class="issue-list warn">${warnings.slice(0, 80).map((row) => `<li>${escapeHtml(row)}</li>`).join("")}</ul>` : `<p class="muted">No warnings.</p>`}
      </div>
    </div>
  `;
}

function renderCompanies() {
  const rows = companies();
  if (!state.selectedId && rows[0]) state.selectedId = rows[0].id;
  const needle = state.filter.trim().toLowerCase();
  const filtered = rows.filter((company) => {
    if (!needle) return true;
    return [company.id, company.ticker, company.name, company.sector, company.subsector].join(" ").toLowerCase().includes(needle);
  });
  const company = selectedCompany();
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Companies</h2>
        <p>Edit identity, sector placement, exposures, price traits, relationship hooks, and story hooks for catalog-backed run selection.</p>
      </div>
    </div>
    <div class="company-layout">
      <div class="card">
        <div class="toolbar">
          <input id="filterInput" value="${escapeHtml(state.filter)}" placeholder="Filter id, ticker, name, sector">
          <button class="small" data-action="add-company">Add</button>
        </div>
        <div class="company-list">
          ${filtered.map((row) => companyListButton(row)).join("") || `<p class="muted">No companies match this filter.</p>`}
        </div>
      </div>
      <div>
        ${company ? companyEditor(company) : `<div class="card"><p class="muted">Add a company to start editing.</p></div>`}
      </div>
    </div>
  `;
}

function companyListButton(company) {
  const active = company.id === state.selectedId ? " active" : "";
  return `
    <button class="company-button${active}" data-select-company="${escapeHtml(company.id)}">
      <strong>${escapeHtml(company.ticker || "-")} ${escapeHtml(company.name || company.id || "Unnamed")}</strong>
      <span>${escapeHtml(company.sector || "-")} / ${escapeHtml(company.subsector || "-")}</span>
    </button>
  `;
}

function companyEditor(company) {
  return `
    <div class="card">
      <div class="card-header">
        <div>
          <h3>${escapeHtml(company.ticker || "-")} ${escapeHtml(company.name || company.id)}</h3>
          <p class="muted">${escapeHtml(company.id)}</p>
        </div>
        <div class="actions">
          <button class="small" data-action="duplicate-company">Duplicate</button>
          <button class="small danger" data-action="delete-company">Delete</button>
        </div>
      </div>
      <div class="row">
        ${inputField("Id", company.id, "id")}
        ${inputField("Ticker", company.ticker, "ticker")}
      </div>
      ${inputField("Name", company.name, "name")}
      <div class="row">
        ${selectField("Sector", company.sector, "sector", state.metadata.sectors)}
        ${inputField("Subsector", company.subsector, "subsector")}
      </div>
      ${textArea("Business Summary", company.business_summary, "business_summary", "data-company-field")}
    </div>
    <div class="grid two" style="margin-top:14px">
      <div class="card">
        <h3>Tags And Hooks</h3>
        ${textArea("Moat Tags", arrayToLines(company.moat_tags), "moat_tags", "data-array-field")}
        ${textArea("Story Hooks", arrayToLines(company.story_hooks), "story_hooks", "data-array-field")}
      </div>
      <div class="card">
        <h3>Exposures</h3>
        <p class="muted">Use one line per exposure: <code>key: value</code>. Values are clamped to -1.0..1.0.</p>
        ${textArea("Commodity Exposures", mapToLines(company.commodity_exposures), "commodity_exposures", "data-map-field")}
        ${textArea("Macro Exposures", mapToLines(company.macro_exposures), "macro_exposures", "data-map-field")}
      </div>
    </div>
    <div class="grid two" style="margin-top:14px">
      <div class="card">
        <h3>Price Traits</h3>
        <div class="row">
          ${selectField("Liquidity", company.price_traits?.liquidity_profile || "mid", "liquidity_profile", state.metadata.liquidity_profiles, "data-price-field")}
          ${selectField("Volatility", company.price_traits?.volatility_profile || "moderate", "volatility_profile", state.metadata.volatility_profiles, "data-price-field")}
        </div>
        <div class="row">
          ${numberField("Quality Bias", company.price_traits?.quality_bias || 0, "quality_bias")}
          ${numberField("Growth Bias", company.price_traits?.growth_bias || 0, "growth_bias")}
          ${numberField("Risk Bias", company.price_traits?.risk_bias || 0, "risk_bias")}
          ${numberField("Retail Attention", company.price_traits?.retail_attention_bias || 0, "retail_attention_bias")}
          ${numberField("Event Sensitivity", company.price_traits?.event_sensitivity || 0, "event_sensitivity")}
        </div>
      </div>
      <div class="card">
        <h3>Relationship Hooks</h3>
        <p class="muted">Advanced field. Keep as JSON array of hook objects with type, target_sector, target_subsector, strength, and visibility.</p>
        <textarea data-hooks-field="relationship_hooks">${escapeHtml(JSON.stringify(company.relationship_hooks || [], null, 2))}</textarea>
      </div>
    </div>
  `;
}

function inputField(label, value, field) {
  return `
    <div class="field">
      <label>${escapeHtml(label)}</label>
      <input value="${escapeHtml(value || "")}" data-company-field="${escapeHtml(field)}">
    </div>
  `;
}

function numberField(label, value, field) {
  return `
    <div class="field">
      <label>${escapeHtml(label)}</label>
      <input type="number" step="0.01" min="-1" max="1" value="${escapeHtml(value)}" data-price-field="${escapeHtml(field)}">
    </div>
  `;
}

function selectField(label, value, field, options, attribute = "data-company-field") {
  const rows = Array.isArray(options) ? options : [];
  const optionHtml = rows.map((option) => {
    const selected = option === value ? " selected" : "";
    return `<option value="${escapeHtml(option)}"${selected}>${escapeHtml(option)}</option>`;
  }).join("");
  return `
    <div class="field">
      <label>${escapeHtml(label)}</label>
      <select ${attribute}="${escapeHtml(field)}">
        <option value=""></option>
        ${optionHtml}
      </select>
    </div>
  `;
}

function textField(label, value, field) {
  return `
    <div class="field">
      <label>${escapeHtml(label)}</label>
      <input value="${escapeHtml(value || "")}" data-source-field="${escapeHtml(field)}">
    </div>
  `;
}

function textArea(label, value, field, attribute) {
  const attr = attribute || "data-source-field";
  return `
    <div class="field">
      <label>${escapeHtml(label)}</label>
      <textarea ${attr}="${escapeHtml(field)}">${escapeHtml(value || "")}</textarea>
    </div>
  `;
}

function renderRaw() {
  state.rawDraft = JSON.stringify(state.source, null, 2);
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Raw JSON</h2>
        <p>Use this for bulk edits. Apply parses the JSON into the editable source. Export still validates before writing runtime JSON.</p>
      </div>
    </div>
    <div class="card">
      <textarea id="rawEditor" class="tall">${escapeHtml(state.rawDraft)}</textarea>
      <div class="raw-actions">
        <button data-action="apply-raw" class="primary">Apply Raw JSON</button>
        <button data-action="reset-raw">Reset From Source</button>
      </div>
    </div>
  `;
}

function addCompany() {
  const existing = companies().map((row) => row.id);
  let id = "new_company";
  let counter = 1;
  while (existing.includes(id)) {
    counter += 1;
    id = `new_company_${counter}`;
  }
  const company = {
    id,
    ticker: `NC${String(counter).padStart(2, "0")}`.slice(0, 6),
    name: "New Company",
    sector: state.metadata.sectors[0] || "consumer",
    subsector: "new_subsector",
    business_summary: "Describe the company business model and operating footprint.",
    moat_tags: [],
    commodity_exposures: {},
    macro_exposures: {},
    price_traits: {
      liquidity_profile: "mid",
      volatility_profile: "moderate",
      quality_bias: 0,
      growth_bias: 0,
      risk_bias: 0,
      retail_attention_bias: 0,
      event_sensitivity: 0
    },
    relationship_hooks: [],
    story_hooks: []
  };
  companies().push(company);
  state.selectedId = id;
  markDirty();
  renderCompanies();
}

function duplicateCompany() {
  const company = selectedCompany();
  if (!company) return;
  const copy = JSON.parse(JSON.stringify(company));
  const base = `${company.id}_copy`;
  const existing = companies().map((row) => row.id);
  let id = base;
  let counter = 2;
  while (existing.includes(id)) {
    id = `${base}_${counter}`;
    counter += 1;
  }
  copy.id = id;
  copy.ticker = normalizeTicker(`${company.ticker || "COPY"}X`);
  copy.name = `${company.name || "Company"} Copy`;
  companies().push(copy);
  state.selectedId = copy.id;
  markDirty();
  renderCompanies();
}

function deleteCompany() {
  const company = selectedCompany();
  if (!company) return;
  if (!confirm(`Delete ${company.ticker} ${company.name}?`)) return;
  const rows = companies();
  const index = rows.indexOf(company);
  if (index >= 0) rows.splice(index, 1);
  state.selectedId = rows[Math.min(index, rows.length - 1)]?.id || "";
  markDirty();
  renderCompanies();
}

function handleInput(event) {
  const target = event.target;
  const company = selectedCompany();
  if (target.id === "filterInput") {
    state.filter = target.value;
    renderCompanies();
    return;
  }
  if (target.dataset.sourceField) {
    const field = target.dataset.sourceField;
    if (field === "source-status") state.source.status = target.value;
    if (field === "source-description") state.source.description = target.value;
    markDirty();
    return;
  }
  if (!company) return;
  if (target.dataset.companyField) {
    const field = target.dataset.companyField;
    let value = target.value;
    if (field === "id" || field === "subsector") value = slugify(value);
    if (field === "ticker") value = normalizeTicker(value);
    company[field] = value;
    if (field === "id") state.selectedId = value;
    markDirty();
    return;
  }
  if (target.dataset.arrayField) {
    company[target.dataset.arrayField] = linesToArray(target.value);
    markDirty();
    return;
  }
  if (target.dataset.mapField) {
    company[target.dataset.mapField] = linesToMap(target.value);
    markDirty();
    return;
  }
  if (target.dataset.priceField) {
    company.price_traits = company.price_traits || {};
    const field = target.dataset.priceField;
    if (target.type === "number") {
      const value = Number(target.value);
      company.price_traits[field] = Number.isFinite(value) ? Math.max(-1, Math.min(1, value)) : 0;
    } else {
      company.price_traits[field] = target.value;
    }
    markDirty();
    return;
  }
  if (target.dataset.hooksField) {
    try {
      const parsed = JSON.parse(target.value || "[]");
      company.relationship_hooks = Array.isArray(parsed) ? parsed : [];
      markDirty();
      setStatus("Relationship hooks parsed.");
    } catch (error) {
      setStatus(`Relationship hook JSON is invalid: ${error.message}`, "error");
    }
  }
}

function handleClick(event) {
  const selectButton = event.target.closest("[data-select-company]");
  if (selectButton) {
    state.selectedId = selectButton.dataset.selectCompany;
    renderCompanies();
    return;
  }
  const actionButton = event.target.closest("[data-action]");
  if (!actionButton) return;
  const action = actionButton.dataset.action;
  if (action === "add-company") addCompany();
  if (action === "duplicate-company") duplicateCompany();
  if (action === "delete-company") deleteCompany();
  if (action === "apply-raw") applyRawJson();
  if (action === "reset-raw") renderRaw();
}

function applyRawJson() {
  const editor = document.getElementById("rawEditor");
  try {
    const parsed = JSON.parse(editor.value || "{}");
    state.source = parsed;
    state.selectedId = companies()[0]?.id || "";
    state.validation = null;
    markDirty("Raw JSON applied. Validate before export.");
    renderRaw();
  } catch (error) {
    setStatus(`Raw JSON parse failed: ${error.message}`, "error");
  }
}

document.querySelectorAll(".nav").forEach((button) => {
  button.addEventListener("click", () => {
    state.activeView = button.dataset.view;
    render();
  });
});

document.getElementById("loadButton").addEventListener("click", loadSource);
document.getElementById("saveButton").addEventListener("click", saveSource);
document.getElementById("validateButton").addEventListener("click", validateSource);
document.getElementById("exportButton").addEventListener("click", exportSource);
viewEl.addEventListener("input", handleInput);
viewEl.addEventListener("change", handleInput);
viewEl.addEventListener("click", handleClick);

loadSource();
