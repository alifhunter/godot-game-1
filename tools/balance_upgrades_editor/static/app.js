const state = {
  source: { schema_version: 1, catalog: { tracks: [] } },
  activeView: "overview",
  dirty: false,
  validation: null,
  trackId: ""
};

const viewEl = document.getElementById("view");
const statusEl = document.getElementById("status");

const TIER_KEYS = ["4", "3", "2", "1"];
const PAID_TIER_KEYS = ["3", "2", "1"];
const REQUIRED_TRACK_IDS = [
  "trading_fee",
  "news_content",
  "twooter_content",
  "chart_indicators",
  "daily_action_points"
];
const KNOWN_INDICATORS = [
  "sma_3",
  "sma_5",
  "sma_10",
  "sma_20",
  "sma_50",
  "sma_60",
  "sma_100",
  "sma_200",
  "ema_20",
  "rsi_14"
];

function source() {
  if (!state.source || typeof state.source !== "object") state.source = {};
  return state.source;
}

function catalog() {
  const src = source();
  if (!src.catalog || typeof src.catalog !== "object" || Array.isArray(src.catalog)) src.catalog = {};
  if (!Array.isArray(src.catalog.tracks)) src.catalog.tracks = [];
  return src.catalog;
}

function tracks() {
  return catalog().tracks;
}

function ensureSourceDefaults() {
  const src = source();
  src.schema_version = Number(src.schema_version || 1);
  src.notes = String(src.notes || "");
  for (const track of tracks()) {
    track.id = slugify(track.id || "upgrade_track");
    track.label = String(track.label || labelize(track.id));
    track.description = String(track.description || "");
    track.tiers = isObject(track.tiers) ? track.tiers : {};
    for (const tierKey of TIER_KEYS) {
      if (!isObject(track.tiers[tierKey])) track.tiers[tierKey] = { effect_label: `Tier ${tierKey}` };
      normalizeTierForUi(track.tiers[tierKey]);
    }
  }
}

function normalizeTierForUi(tier) {
  tier.effect_label = String(tier.effect_label || "");
  if (tier.cost !== undefined && tier.cost !== "") tier.cost = Number(tier.cost || 0);
  if (tier.buy_fee_rate !== undefined && tier.buy_fee_rate !== "") tier.buy_fee_rate = Number(tier.buy_fee_rate || 0);
  if (tier.sell_fee_rate !== undefined && tier.sell_fee_rate !== "") tier.sell_fee_rate = Number(tier.sell_fee_rate || 0);
  if (tier.content_level !== undefined && tier.content_level !== "") tier.content_level = Number(tier.content_level || 1);
  if (tier.daily_action_limit !== undefined && tier.daily_action_limit !== "") tier.daily_action_limit = Number(tier.daily_action_limit || 0);
  if (tier.indicator_ids !== undefined) tier.indicator_ids = Array.isArray(tier.indicator_ids) ? tier.indicator_ids : [];
}

function isObject(value) {
  return value && typeof value === "object" && !Array.isArray(value);
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

function slugify(value, fallback = "id") {
  const cleaned = String(value || "").toLowerCase().replace(/[^a-z0-9_]+/g, "_").replace(/^_+|_+$/g, "");
  return cleaned || fallback;
}

function labelize(value) {
  return String(value || "").replace(/_/g, " ").replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function uniqueId(base, existing) {
  const root = slugify(base);
  let id = root;
  let counter = 2;
  while (existing.includes(id)) {
    id = `${root}_${counter}`;
    counter += 1;
  }
  return id;
}

function formatCurrency(value) {
  const number = Number(value || 0);
  return `Rp${Math.round(number).toLocaleString("id-ID")}`;
}

function setStatus(message, kind = "") {
  statusEl.textContent = message;
  statusEl.className = `status ${kind}`.trim();
}

function markDirty() {
  state.dirty = true;
  if (!statusEl.classList.contains("error")) setStatus("Unsaved source changes.", "");
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
    setStatus("Loaded editable Balance / Upgrades source.", "ok");
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
  const ids = tracks().map((track) => track.id);
  if (!ids.includes(state.trackId)) state.trackId = ids[0] || "";
}

function selectedTrack() {
  return tracks().find((track) => track.id === state.trackId);
}

function render() {
  ensureSourceDefaults();
  reconcileSelection();
  document.querySelectorAll(".nav").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === state.activeView);
  });
  if (state.activeView === "overview") renderOverview();
  if (state.activeView === "tracks") renderTracks();
  if (state.activeView === "balance") renderBalanceMatrix();
  if (state.activeView === "raw") renderRaw();
}

function totalMaxCost() {
  return tracks().reduce((total, track) => {
    return total + PAID_TIER_KEYS.reduce((trackTotal, tierKey) => {
      return trackTotal + Number(track.tiers?.[tierKey]?.cost || 0);
    }, 0);
  }, 0);
}

function renderOverview() {
  const trackIds = tracks().map((track) => track.id);
  const missingRequired = REQUIRED_TRACK_IDS.filter((id) => !trackIds.includes(id));
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Overview</h2>
        <p>Edit upgrade costs, shop copy, content unlock levels, chart indicator unlocks, trading fees, and Network daily AP limits.</p>
      </div>
    </div>
    <div class="grid two">
      <div class="card">
        <h3>Catalog</h3>
        <p><span class="chip">${tracks().length} tracks</span></p>
        <p><span class="chip">${formatCurrency(totalMaxCost())} full-upgrade cost</span></p>
        <p><span class="chip">${missingRequired.length ? `${missingRequired.length} required missing` : "required tracks present"}</span></p>
      </div>
      <div class="card">
        <h3>Runtime Effects</h3>
        <p><span class="chip">fees read from trading_fee</span></p>
        <p><span class="chip">News/Twooter content_level</span></p>
        <p><span class="chip">chart indicator_ids</span></p>
        <p><span class="chip">Network daily_action_limit</span></p>
      </div>
    </div>
    <div class="card" style="margin-top: 14px;">
      ${textAreaField("Source Notes", source().notes, "notes", 4)}
    </div>
    ${validationPanel()}
  `;
  document.querySelector("[data-field='notes']").addEventListener("input", (event) => {
    source().notes = event.target.value;
    markDirty();
  });
}

function renderTracks() {
  const track = selectedTrack();
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Tracks</h2>
        <p>Each track starts at tier 4. Buying an upgrade moves down one tier until tier 1.</p>
      </div>
      <button id="addTrack">Add Track</button>
    </div>
    <div class="pool-grid">
      <div class="key-list" id="trackKeys"></div>
      <div class="card" id="trackEditor"></div>
    </div>
    ${validationPanel()}
  `;
  renderKeyButtons("trackKeys", tracks().map((row) => row.id), state.trackId, (key) => {
    state.trackId = key;
    render();
  }, (key) => trackBadge(key));
  renderTrackEditor(track);
  document.getElementById("addTrack").addEventListener("click", () => {
    const id = uniqueId("new_upgrade", tracks().map((row) => row.id));
    tracks().push({
      id,
      label: "New Upgrade",
      description: "Describe the upgrade effect.",
      tiers: {
        "4": { effect_label: "Baseline" },
        "3": { cost: 1000000, effect_label: "Tier 3" },
        "2": { cost: 3000000, effect_label: "Tier 2" },
        "1": { cost: 9000000, effect_label: "Tier 1" }
      }
    });
    state.trackId = id;
    markDirty();
    render();
  });
}

function trackBadge(trackId) {
  if (trackId === "trading_fee") return "fees";
  if (trackId === "news_content" || trackId === "twooter_content") return "content";
  if (trackId === "chart_indicators") return "charts";
  if (trackId === "daily_action_points") return "network";
  return "custom";
}

function renderTrackEditor(track) {
  const editor = document.getElementById("trackEditor");
  if (!track) {
    editor.innerHTML = `<div class="empty">Choose or add an upgrade track.</div>`;
    return;
  }
  editor.innerHTML = `
    <div class="card-header">
      <div class="card-title">
        <h3>${escapeHtml(track.label)}</h3>
        <span class="chip">${escapeHtml(track.id)} / ${escapeHtml(trackBadge(track.id))}</span>
      </div>
      <button id="deleteTrack" class="small danger">Delete Track</button>
    </div>
    <div class="row">
      ${textField("ID", track.id, "id")}
      ${textField("Label", track.label, "label")}
    </div>
    ${textAreaField("Description", track.description, "description", 3)}
    <div class="grid two" style="margin-top: 14px;">
      ${TIER_KEYS.map((tierKey) => tierEditor(track, tierKey)).join("")}
    </div>
  `;
  bindTrackFields(editor, track);
  bindTierFields(editor, track);
  document.getElementById("deleteTrack").addEventListener("click", () => {
    if (REQUIRED_TRACK_IDS.includes(track.id) && !confirm("Delete required track? Validation will fail until it is restored.")) return;
    if (!REQUIRED_TRACK_IDS.includes(track.id) && !confirm("Delete this upgrade track?")) return;
    const index = tracks().indexOf(track);
    if (index >= 0) tracks().splice(index, 1);
    state.trackId = "";
    markDirty();
    render();
  });
}

function tierEditor(track, tierKey) {
  const tier = track.tiers[tierKey] || {};
  return `
    <div class="card">
      <div class="card-header">
        <h3>Tier ${tierKey}${tierKey === "4" ? " Baseline" : ""}</h3>
        <span class="chip">${tierKey === "1" ? "max" : tierKey === "4" ? "default" : "paid"}</span>
      </div>
      ${numberField("Cost", tier.cost ?? "", `tier_${tierKey}_cost`, "1")}
      ${textField("Effect Label", tier.effect_label || "", `tier_${tierKey}_effect_label`)}
      ${tierSpecificFields(track.id, tier, tierKey)}
    </div>
  `;
}

function tierSpecificFields(trackId, tier, tierKey) {
  if (trackId === "trading_fee") {
    return `
      <div class="row">
        ${numberField("Buy Fee Rate", tier.buy_fee_rate ?? "", `tier_${tierKey}_buy_fee_rate`, "0.0001")}
        ${numberField("Sell Fee Rate", tier.sell_fee_rate ?? "", `tier_${tierKey}_sell_fee_rate`, "0.0001")}
      </div>
    `;
  }
  if (trackId === "news_content" || trackId === "twooter_content") {
    return numberField("Content Level", tier.content_level ?? "", `tier_${tierKey}_content_level`, "1");
  }
  if (trackId === "chart_indicators") {
    return `
      ${textAreaField("Indicator IDs", arrayToLines(tier.indicator_ids || []), `tier_${tierKey}_indicator_ids`, 5)}
      <p style="margin: 6px 0 0; color: var(--muted);">${escapeHtml(KNOWN_INDICATORS.join(", "))}</p>
    `;
  }
  if (trackId === "daily_action_points") {
    return numberField("Daily Action Limit", tier.daily_action_limit ?? "", `tier_${tierKey}_daily_action_limit`, "1");
  }
  return "";
}

function bindTrackFields(editor, track) {
  editor.querySelector("[data-field='id']").addEventListener("change", (event) => {
    const oldId = track.id;
    const newId = slugify(event.target.value);
    if (!newId || newId === oldId) return;
    if (tracks().some((row) => row !== track && row.id === newId)) {
      setStatus(`Track id already exists: ${newId}`, "error");
      event.target.value = oldId;
      return;
    }
    track.id = newId;
    state.trackId = newId;
    markDirty();
    render();
  });
  editor.querySelector("[data-field='label']").addEventListener("input", (event) => {
    track.label = event.target.value;
    markDirty();
  });
  editor.querySelector("[data-field='description']").addEventListener("input", (event) => {
    track.description = event.target.value;
    markDirty();
  });
}

function bindTierFields(editor, track) {
  for (const tierKey of TIER_KEYS) {
    const tier = track.tiers[tierKey];
    bindOptionalNumber(editor, `tier_${tierKey}_cost`, tier, "cost");
    bindString(editor, `tier_${tierKey}_effect_label`, tier, "effect_label");
    if (track.id === "trading_fee") {
      bindOptionalNumber(editor, `tier_${tierKey}_buy_fee_rate`, tier, "buy_fee_rate");
      bindOptionalNumber(editor, `tier_${tierKey}_sell_fee_rate`, tier, "sell_fee_rate");
    }
    if (track.id === "news_content" || track.id === "twooter_content") {
      bindOptionalNumber(editor, `tier_${tierKey}_content_level`, tier, "content_level");
    }
    if (track.id === "chart_indicators") {
      const input = editor.querySelector(`[data-field='tier_${tierKey}_indicator_ids']`);
      if (input) {
        input.addEventListener("input", () => {
          tier.indicator_ids = linesToArray(input.value);
          markDirty();
        });
      }
    }
    if (track.id === "daily_action_points") {
      bindOptionalNumber(editor, `tier_${tierKey}_daily_action_limit`, tier, "daily_action_limit");
    }
  }
}

function bindOptionalNumber(container, field, object, key) {
  const input = container.querySelector(`[data-field='${field}']`);
  if (!input) return;
  input.addEventListener("input", () => {
    if (input.value === "") {
      delete object[key];
    } else {
      object[key] = Number(input.value || 0);
    }
    markDirty();
  });
}

function bindString(container, field, object, key) {
  const input = container.querySelector(`[data-field='${field}']`);
  if (!input) return;
  input.addEventListener("input", () => {
    object[key] = input.value;
    markDirty();
  });
}

function renderBalanceMatrix() {
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Balance Matrix</h2>
        <p>Fast edit cost curves and effect labels across all upgrade tracks.</p>
      </div>
    </div>
    <div class="card">
      <table style="width: 100%; border-collapse: collapse;">
        <thead>
          <tr>
            <th style="text-align:left; padding: 8px; border-bottom: 1px solid var(--line);">Track</th>
            ${TIER_KEYS.map((tierKey) => `<th style="text-align:left; padding: 8px; border-bottom: 1px solid var(--line);">Tier ${tierKey}</th>`).join("")}
            <th style="text-align:left; padding: 8px; border-bottom: 1px solid var(--line);">Paid Total</th>
          </tr>
        </thead>
        <tbody>
          ${tracks().map((track, trackIndex) => matrixRow(track, trackIndex)).join("")}
        </tbody>
      </table>
    </div>
    ${validationPanel()}
  `;
  tracks().forEach((track, trackIndex) => {
    for (const tierKey of TIER_KEYS) {
      const tier = track.tiers[tierKey];
      bindOptionalNumber(document, `matrix_${trackIndex}_${tierKey}_cost`, tier, "cost");
      bindString(document, `matrix_${trackIndex}_${tierKey}_effect_label`, tier, "effect_label");
    }
  });
}

function matrixRow(track, trackIndex) {
  const paidTotal = PAID_TIER_KEYS.reduce((sum, tierKey) => sum + Number(track.tiers?.[tierKey]?.cost || 0), 0);
  return `
    <tr>
      <td style="vertical-align: top; padding: 8px; border-bottom: 1px solid var(--line);">
        <strong>${escapeHtml(track.label)}</strong><br>
        <span class="chip">${escapeHtml(track.id)}</span>
      </td>
      ${TIER_KEYS.map((tierKey) => matrixTierCell(track, trackIndex, tierKey)).join("")}
      <td style="vertical-align: top; padding: 8px; border-bottom: 1px solid var(--line);">${formatCurrency(paidTotal)}</td>
    </tr>
  `;
}

function matrixTierCell(track, trackIndex, tierKey) {
  const tier = track.tiers[tierKey] || {};
  return `
    <td style="vertical-align: top; min-width: 170px; padding: 8px; border-bottom: 1px solid var(--line);">
      ${numberField("Cost", tier.cost ?? "", `matrix_${trackIndex}_${tierKey}_cost`, "1")}
      ${textField("Effect", tier.effect_label || "", `matrix_${trackIndex}_${tierKey}_effect_label`)}
    </td>
  `;
}

function renderRaw() {
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Raw JSON</h2>
        <p>Use this for bulk edits. Apply parses the full source wrapper; Save Source persists it.</p>
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
    try {
      state.source = JSON.parse(document.getElementById("rawJson").value);
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

function numberField(label, value, field, step = "1") {
  return `
    <div class="field">
      <label>${escapeHtml(label)}</label>
      <input type="number" step="${escapeHtml(step)}" value="${escapeHtml(value)}" data-field="${escapeHtml(field)}">
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
