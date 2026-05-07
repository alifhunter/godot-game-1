const state = {
  source: { schema_version: 1, roster: [] },
  activeView: "overview",
  dirty: false,
  validation: null,
  brokerCode: "",
  brokerQuery: ""
};

const viewEl = document.getElementById("view");
const statusEl = document.getElementById("status");

const BROKER_TYPES = ["foreign", "retail", "institution", "bandar", "zombie"];
const PLAYER_BROKER_CODE = "XL";
const KNOWN_TAGS = [
  ["robotic", "Rules-based flow and tighter price discipline."],
  ["trading", "Higher two-sided activity during volatile days."],
  ["quality_buyer", "Leans toward better quality and pullback entries."],
  ["retail_facing", "More active with retail heat and momentum."],
  ["dumb_money", "Chases moves and reacts to weak tape."],
  ["market_maker", "Adds two-sided volume, especially in volatility."],
  ["smart_money", "Responds more to hidden accumulation/distribution setups."],
  ["quiet_accumulator", "Buys more in quiet or stealth-interest setups."],
  ["follow_the_wave", "Chases momentum on both sides."],
  ["speculative", "Higher activity in hot or volatile names."],
  ["distributor", "Sells more into distribution setups."],
  ["evil_to_retail", "Fades retail-friendly rallies more often."],
  ["defensive", "Prefers quality and defensive conditions."],
  ["government", "Quality/large-name support behavior."],
  ["retail", "Simple retail-style behavior tag."],
  ["player", "Fallback tag for injected player broker flow."]
];

function roster() {
  if (!Array.isArray(state.source.roster)) state.source.roster = [];
  return state.source.roster;
}

function ensureSourceDefaults() {
  state.source.schema_version = Number(state.source.schema_version || 1);
  state.source.notes = String(state.source.notes || "");
  for (const broker of roster()) {
    broker.code = String(broker.code || "").trim().toUpperCase();
    broker.company_name = String(broker.company_name || "");
    broker.broker_type = String(broker.broker_type || "retail");
    broker.personality_tags = Array.isArray(broker.personality_tags) ? broker.personality_tags : [];
  }
}

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function linesToArray(value) {
  return String(value || "")
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
}

function arrayToLines(value) {
  return Array.isArray(value) ? value.join("\n") : "";
}

function normalizeCode(value) {
  return String(value || "").toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, 4);
}

function nextBrokerCode() {
  const used = new Set(roster().map((broker) => broker.code));
  for (let first = 65; first <= 90; first += 1) {
    for (let second = 65; second <= 90; second += 1) {
      const code = String.fromCharCode(first) + String.fromCharCode(second);
      if (!used.has(code)) return code;
    }
  }
  return "N1";
}

function setStatus(message, kind = "") {
  statusEl.textContent = message;
  statusEl.className = `status ${kind}`.trim();
}

function markDirty() {
  state.dirty = true;
  if (!statusEl.classList.contains("error")) {
    setStatus("Unsaved source changes.", "");
  }
}

async function requestJson(path, options = {}) {
  const response = await fetch(path, {
    headers: { "Content-Type": "application/json" },
    ...options
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message = payload.error || payload.message || `Request failed: ${response.status}`;
    throw new Error(message);
  }
  return payload;
}

async function loadSource() {
  try {
    state.source = await requestJson("/api/source");
    ensureSourceDefaults();
    state.dirty = false;
    state.validation = null;
    reconcileSelection();
    setStatus("Loaded editable Broker Roster source.", "ok");
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
    setStatus(validationMessage("Saved source.", state.validation), state.validation?.valid ? "ok" : "error");
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
    setStatus(validationMessage(`Exported runtime JSON:\n${payload.path}`, state.validation), "ok");
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

function reconcileSelection() {
  const codes = roster().map((broker) => broker.code);
  if (!codes.includes(state.brokerCode)) state.brokerCode = codes[0] || "";
}

function render() {
  ensureSourceDefaults();
  reconcileSelection();
  document.querySelectorAll(".nav").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === state.activeView);
  });
  if (state.activeView === "overview") renderOverview();
  if (state.activeView === "brokers") renderBrokers();
  if (state.activeView === "types") renderTypes();
  if (state.activeView === "raw") renderRaw();
}

function typeCounts() {
  return BROKER_TYPES.reduce((acc, type) => {
    acc[type] = roster().filter((broker) => broker.broker_type === type).length;
    return acc;
  }, {});
}

function tagCounts() {
  const counts = {};
  for (const broker of roster()) {
    for (const tag of broker.personality_tags || []) {
      counts[tag] = (counts[tag] || 0) + 1;
    }
  }
  return counts;
}

function renderOverview() {
  const counts = typeCounts();
  const tags = tagCounts();
  const playerBroker = roster().find((broker) => broker.code === PLAYER_BROKER_CODE);
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Overview</h2>
        <p>Edit broker identities and behavior tags used by the Broker tab, type totals, top buy/sell rows, and player-flow injection.</p>
      </div>
    </div>
    <div class="grid two">
      <div class="card">
        <h3>Roster</h3>
        <p><span class="chip">${roster().length} brokers</span></p>
        <p><span class="chip">${Object.keys(tags).length} unique tags</span></p>
        <p><span class="chip">${playerBroker ? "XL player broker present" : "XL player broker missing"}</span></p>
      </div>
      <div class="card">
        <h3>Broker Types</h3>
        <div class="toolbar">
          ${BROKER_TYPES.map((type) => `<span class="chip">${escapeHtml(type)}: ${counts[type] || 0}</span>`).join("")}
        </div>
      </div>
    </div>
    <div class="card" style="margin-top: 14px;">
      ${textAreaField("Source Notes", state.source.notes, "notes", 4)}
    </div>
    ${validationPanel()}
  `;
  document.querySelector("[data-field='notes']").addEventListener("input", (event) => {
    state.source.notes = event.target.value;
    markDirty();
  });
}

function renderBrokers() {
  const rows = roster();
  const query = state.brokerQuery.toLowerCase();
  const filtered = rows.filter((broker) => {
    if (!query) return true;
    return [broker.code, broker.company_name, broker.broker_type, ...(broker.personality_tags || [])]
      .join(" ")
      .toLowerCase()
      .includes(query);
  });
  if (!filtered.some((broker) => broker.code === state.brokerCode) && filtered[0]) {
    state.brokerCode = filtered[0].code;
  }
  const broker = rows.find((row) => row.code === state.brokerCode);
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Brokers</h2>
        <p>Broker type controls pressure buckets. Personality tags control side weights, coverage, and smart/dumb flow readings.</p>
      </div>
      <button id="addBroker">Add Broker</button>
    </div>
    <div class="toolbar">
      <input id="brokerSearch" value="${escapeHtml(state.brokerQuery)}" placeholder="Search code, name, type, tags...">
    </div>
    <div class="pool-grid">
      <div class="key-list" id="brokerKeys"></div>
      <div class="card" id="brokerEditor"></div>
    </div>
  `;
  document.getElementById("brokerSearch").addEventListener("input", (event) => {
    state.brokerQuery = event.target.value;
    render();
  });
  renderKeyButtons("brokerKeys", filtered.map((brokerRow) => brokerRow.code), state.brokerCode, (code) => {
    state.brokerCode = code;
    render();
  }, (code) => {
    const row = rows.find((item) => item.code === code) || {};
    return row.broker_type || "";
  });
  renderBrokerEditor(broker);
  document.getElementById("addBroker").addEventListener("click", () => {
    const code = nextBrokerCode();
    rows.push({
      code,
      company_name: "PT. New Sekuritas",
      broker_type: "retail",
      personality_tags: ["trading"]
    });
    state.brokerCode = code;
    markDirty();
    render();
  });
}

function renderBrokerEditor(broker) {
  const editor = document.getElementById("brokerEditor");
  if (!broker) {
    editor.innerHTML = `<div class="empty">Choose or add a broker.</div>`;
    return;
  }
  editor.innerHTML = `
    <div class="card-header">
      <div class="card-title">
        <h3>${escapeHtml(broker.code)} - ${escapeHtml(broker.company_name)}</h3>
        <span class="chip">${escapeHtml(broker.broker_type)}</span>
      </div>
      <button id="deleteBroker" class="small danger">Delete Broker</button>
    </div>
    <div class="row">
      ${textField("Code", broker.code, "code")}
      ${selectField("Broker Type", broker.broker_type, "broker_type", BROKER_TYPES)}
    </div>
    ${textField("Company Name", broker.company_name, "company_name")}
    ${textAreaField("Personality Tags", arrayToLines(broker.personality_tags), "personality_tags", 8)}
    <div class="card" style="margin-top: 14px;">
      <h3>Known Tags</h3>
      <div class="toolbar">
        ${KNOWN_TAGS.map(([tag]) => `<button class="small" data-tag="${escapeHtml(tag)}">${escapeHtml(tag)}</button>`).join("")}
      </div>
    </div>
  `;
  editor.querySelector("[data-field='code']").addEventListener("change", (event) => {
    const oldCode = broker.code;
    const newCode = normalizeCode(event.target.value);
    if (!newCode || newCode === oldCode) {
      event.target.value = oldCode;
      return;
    }
    if (roster().some((row) => row !== broker && row.code === newCode)) {
      setStatus(`Broker code already exists: ${newCode}`, "error");
      event.target.value = oldCode;
      return;
    }
    broker.code = newCode;
    state.brokerCode = newCode;
    markDirty();
    render();
  });
  editor.querySelector("[data-field='broker_type']").addEventListener("change", (event) => {
    broker.broker_type = event.target.value;
    markDirty();
    render();
  });
  editor.querySelector("[data-field='company_name']").addEventListener("input", (event) => {
    broker.company_name = event.target.value;
    markDirty();
  });
  editor.querySelector("[data-field='personality_tags']").addEventListener("input", (event) => {
    broker.personality_tags = linesToArray(event.target.value);
    markDirty();
  });
  editor.querySelectorAll("[data-tag]").forEach((button) => {
    button.addEventListener("click", () => {
      const tag = button.dataset.tag;
      broker.personality_tags = Array.isArray(broker.personality_tags) ? broker.personality_tags : [];
      if (broker.personality_tags.includes(tag)) {
        broker.personality_tags = broker.personality_tags.filter((row) => row !== tag);
      } else {
        broker.personality_tags.push(tag);
      }
      markDirty();
      render();
    });
  });
  document.getElementById("deleteBroker").addEventListener("click", () => {
    if (!confirm("Delete this broker? Validation requires all broker types and XL player broker coverage.")) return;
    const index = roster().indexOf(broker);
    if (index >= 0) roster().splice(index, 1);
    state.brokerCode = "";
    markDirty();
    render();
  });
}

function renderTypes() {
  const counts = typeCounts();
  const tags = tagCounts();
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Types / Tags</h2>
        <p>Reference for the broker types and tags that BrokerFlowSystem currently reads.</p>
      </div>
    </div>
    <div class="grid two">
      <div class="card">
        <h3>Broker Types</h3>
        <div class="validation-list">
          ${BROKER_TYPES.map((type) => `<div class="validation-row"><strong>${escapeHtml(type)}</strong> ${counts[type] || 0} brokers</div>`).join("")}
        </div>
      </div>
      <div class="card">
        <h3>Tag Coverage</h3>
        <div class="validation-list">
          ${KNOWN_TAGS.map(([tag, detail]) => `<div class="validation-row"><strong>${escapeHtml(tag)}</strong> ${tags[tag] || 0}<br>${escapeHtml(detail)}</div>`).join("")}
        </div>
      </div>
    </div>
    ${validationPanel()}
  `;
}

function renderRaw() {
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Raw JSON</h2>
        <p>Use this for bulk edits. Apply accepts either the source wrapper or the runtime roster array.</p>
      </div>
      <div class="actions">
        <button id="formatRaw">Format</button>
        <button id="applyRaw" class="primary">Apply Raw JSON</button>
      </div>
    </div>
    <textarea id="rawJson" class="tall">${escapeHtml(JSON.stringify(state.source, null, 2))}</textarea>
  `;
  document.getElementById("formatRaw").addEventListener("click", () => {
    const raw = document.getElementById("rawJson");
    try {
      raw.value = JSON.stringify(JSON.parse(raw.value), null, 2);
      setStatus("Raw JSON formatted.", "ok");
    } catch (error) {
      setStatus(`Invalid JSON: ${error.message}`, "error");
    }
  });
  document.getElementById("applyRaw").addEventListener("click", () => {
    const raw = document.getElementById("rawJson").value;
    try {
      const parsed = JSON.parse(raw);
      state.source = Array.isArray(parsed) ? { schema_version: 1, roster: parsed } : parsed;
      ensureSourceDefaults();
      markDirty();
      setStatus("Raw JSON applied to editor state.", "ok");
      render();
    } catch (error) {
      setStatus(`Invalid JSON: ${error.message}`, "error");
    }
  });
}

function validationPanel() {
  if (!state.validation) return "";
  const errors = state.validation.errors || [];
  const warnings = state.validation.warnings || [];
  const rows = [
    ...errors.map((message) => `<div class="validation-row error">${escapeHtml(message)}</div>`),
    ...warnings.map((message) => `<div class="validation-row warning">${escapeHtml(message)}</div>`)
  ].join("");
  return `
    <div class="card" style="margin-top: 14px;">
      <div class="card-header">
        <h3>Validation</h3>
        <span class="chip">${errors.length} errors / ${warnings.length} warnings</span>
      </div>
      <div class="validation-list">${rows || `<div class="validation-row">No validation messages.</div>`}</div>
    </div>
  `;
}

function renderKeyButtons(containerId, keys, activeKey, onSelect, badgeFn) {
  const container = document.getElementById(containerId);
  container.innerHTML = "";
  if (!keys.length) {
    container.innerHTML = `<div class="empty">No rows.</div>`;
    return;
  }
  keys.forEach((key) => {
    const button = document.createElement("button");
    button.className = `key-button ${key === activeKey ? "active" : ""}`;
    button.innerHTML = `<span>${escapeHtml(key)}</span><span>${escapeHtml(badgeFn ? badgeFn(key) : "")}</span>`;
    button.addEventListener("click", () => onSelect(key));
    container.appendChild(button);
  });
}

function textField(label, value, field) {
  return `
    <div class="field">
      <label>${escapeHtml(label)}</label>
      <input value="${escapeHtml(value)}" data-field="${escapeHtml(field)}">
    </div>
  `;
}

function textAreaField(label, value, field, rows = 4) {
  return `
    <div class="field">
      <label>${escapeHtml(label)}</label>
      <textarea rows="${rows}" data-field="${escapeHtml(field)}">${escapeHtml(value)}</textarea>
    </div>
  `;
}

function selectField(label, value, field, options) {
  return `
    <div class="field">
      <label>${escapeHtml(label)}</label>
      <select data-field="${escapeHtml(field)}">
        ${options.map((item) => option(item, item, value)).join("")}
      </select>
    </div>
  `;
}

function option(value, label, currentValue) {
  const selected = String(value) === String(currentValue) ? "selected" : "";
  return `<option value="${escapeHtml(value)}" ${selected}>${escapeHtml(label)}</option>`;
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

window.addEventListener("beforeunload", (event) => {
  if (!state.dirty) return;
  event.preventDefault();
  event.returnValue = "";
});

loadSource();
