const state = {
  source: { schema_version: 1, events: [] },
  reference: {
    scopes: ["market", "sector", "company"],
    event_families: ["market", "company", "person", "special", "corporate_action"],
    tones: ["positive", "negative", "mixed", "neutral"],
    broker_biases: ["foreign", "retail", "institution", "bandar", "zombie", "balanced"],
    sector_ids: []
  },
  activeView: "overview",
  dirty: false,
  validation: null,
  eventId: "",
  query: "",
  familyFilter: "all"
};

const viewEl = document.getElementById("view");
const statusEl = document.getElementById("status");

function events() {
  if (!Array.isArray(state.source.events)) state.source.events = [];
  return state.source.events;
}

function ensureSourceDefaults() {
  state.source.schema_version = Number(state.source.schema_version || 1);
  state.source.notes = String(state.source.notes || "");
  for (const event of events()) {
    event.id = slugify(event.id || "event");
    event.scope = String(event.scope || "company");
    event.event_family = String(event.event_family || "company");
    event.category = slugify(event.category || event.event_family || "event");
    event.tone = String(event.tone || "mixed");
    event.duration_days = Number(event.duration_days || 1);
    event.sentiment_shift = Number(event.sentiment_shift || 0);
    event.broker_bias = String(event.broker_bias || "balanced");
    event.description = String(event.description || "");
    if (event.event_family === "person") {
      event.person_id = slugify(event.person_id || "person");
      event.person_name = String(event.person_name || "");
    }
    if (event.event_family === "special") ensureSpecialDefaults(event);
  }
}

function ensureSpecialDefaults(event) {
  event.duration_days_min = Number(event.duration_days_min || event.duration_days || 1);
  event.duration_days_max = Number(event.duration_days_max || event.duration_days_min || event.duration_days || 1);
  event.once_per_run = Boolean(event.once_per_run);
  event.market_bias_shift = Number(event.market_bias_shift || 0);
  event.volatility_multiplier = Number(event.volatility_multiplier || 1);
  event.shock_profile = isObject(event.shock_profile) ? event.shock_profile : {};
  event.sector_biases = isObject(event.sector_biases) ? event.sector_biases : {};
  event.headline_template = String(event.headline_template || "");
  event.headline_detail_template = String(event.headline_detail_template || "");
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
    const [sourcePayload, referencePayload] = await Promise.all([
      requestJson("/api/source"),
      requestJson("/api/reference")
    ]);
    state.source = sourcePayload;
    state.reference = { ...state.reference, ...referencePayload };
    ensureSourceDefaults();
    state.dirty = false;
    state.validation = null;
    reconcileSelection();
    setStatus("Loaded editable Event Content source.", "ok");
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
  const ids = events().map((event) => event.id);
  if (!ids.includes(state.eventId)) state.eventId = ids[0] || "";
}

function selectedEvent() {
  return events().find((event) => event.id === state.eventId);
}

function filteredEvents() {
  const query = state.query.trim().toLowerCase();
  return events().filter((event) => {
    if (state.familyFilter !== "all" && event.event_family !== state.familyFilter) return false;
    if (!query) return true;
    return [event.id, event.category, event.description, event.event_family, event.scope]
      .join(" ")
      .toLowerCase()
      .includes(query);
  });
}

function render() {
  ensureSourceDefaults();
  reconcileSelection();
  document.querySelectorAll(".nav").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === state.activeView);
  });
  if (state.activeView === "overview") renderOverview();
  if (state.activeView === "events") renderEvents();
  if (state.activeView === "special") renderSpecialEffects();
  if (state.activeView === "sectors") renderSectorBiases();
  if (state.activeView === "raw") renderRaw();
}

function countBy(field) {
  const counts = {};
  for (const event of events()) counts[event[field]] = (counts[event[field]] || 0) + 1;
  return counts;
}

function renderOverview() {
  const familyCounts = countBy("event_family");
  const scopeCounts = countBy("scope");
  const toneCounts = countBy("tone");
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Overview</h2>
        <p>Edit event definitions used by market events, company events, person posts, active special shocks, corporate-action fallback metadata, News, and Twooter.</p>
      </div>
    </div>
    <div class="grid two">
      <div class="card">
        <h3>Families</h3>
        ${chipRows(familyCounts)}
      </div>
      <div class="card">
        <h3>Scopes</h3>
        ${chipRows(scopeCounts)}
      </div>
      <div class="card">
        <h3>Tones</h3>
        ${chipRows(toneCounts)}
      </div>
      <div class="card">
        <h3>Runtime Files</h3>
        <p><span class="chip">${events().length} event definitions</span></p>
        <p><span class="chip">${state.reference.sector_ids.length} known sectors</span></p>
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

function chipRows(counts) {
  const keys = Object.keys(counts).sort();
  return keys.map((key) => `<p><span class="chip">${escapeHtml(key)}: ${counts[key]}</span></p>`).join("") || `<p><span class="chip">none</span></p>`;
}

function renderEvents() {
  const event = selectedEvent();
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Events</h2>
        <p>Edit runtime event metadata, daily impact knobs, person labels, and special-event templates.</p>
      </div>
      <button id="addEvent">Add Event</button>
    </div>
    <div class="row" style="margin-bottom: 12px;">
      ${textField("Search", state.query, "event_query")}
      ${selectField("Family Filter", state.familyFilter, "family_filter", ["all", ...state.reference.event_families])}
    </div>
    <div class="pool-grid">
      <div class="key-list" id="eventKeys"></div>
      <div class="card" id="eventEditor"></div>
    </div>
    ${validationPanel()}
  `;
  document.querySelector("[data-field='event_query']").addEventListener("input", (inputEvent) => {
    state.query = inputEvent.target.value;
    renderEvents();
  });
  document.querySelector("[data-field='family_filter']").addEventListener("change", (inputEvent) => {
    state.familyFilter = inputEvent.target.value;
    renderEvents();
  });
  renderKeyButtons("eventKeys", filteredEvents().map((row) => row.id), state.eventId, (key) => {
    state.eventId = key;
    render();
  }, (key) => {
    const row = events().find((item) => item.id === key) || {};
    return row.event_family || "";
  });
  renderEventEditor(event);
  document.getElementById("addEvent").addEventListener("click", () => {
    const id = uniqueId("new_event", events().map((row) => row.id));
    events().push({
      id,
      scope: "company",
      event_family: "company",
      category: "custom",
      tone: "mixed",
      duration_days: 1,
      sentiment_shift: 0,
      broker_bias: "balanced",
      description: "Describe the event."
    });
    state.eventId = id;
    markDirty();
    render();
  });
}

function renderEventEditor(event) {
  const editor = document.getElementById("eventEditor");
  if (!event) {
    editor.innerHTML = `<div class="empty">Choose or add an event definition.</div>`;
    return;
  }
  if (event.event_family === "special") ensureSpecialDefaults(event);
  editor.innerHTML = `
    <div class="card-header">
      <div class="card-title">
        <h3>${escapeHtml(event.id)}</h3>
        <span class="chip">${escapeHtml(event.event_family)} / ${escapeHtml(event.scope)} / ${escapeHtml(event.tone)}</span>
      </div>
      <div class="actions">
        <button id="duplicateEvent" class="small">Duplicate</button>
        <button id="deleteEvent" class="small danger">Delete</button>
      </div>
    </div>
    <div class="grid two">
      <div>
        <div class="row">
          ${textField("ID", event.id, "id")}
          ${textField("Category", event.category, "category")}
        </div>
        <div class="row">
          ${selectField("Scope", event.scope, "scope", state.reference.scopes)}
          ${selectField("Family", event.event_family, "event_family", state.reference.event_families)}
        </div>
        <div class="row">
          ${selectField("Tone", event.tone, "tone", state.reference.tones)}
          ${selectField("Broker Bias", event.broker_bias, "broker_bias", state.reference.broker_biases)}
        </div>
        <div class="row">
          ${numberField("Duration Days", event.duration_days, "duration_days", "1")}
          ${numberField("Sentiment Shift", event.sentiment_shift, "sentiment_shift", "0.001")}
        </div>
        ${textAreaField("Description", event.description, "description", 5)}
      </div>
      <div>
        ${personFields(event)}
        ${specialFields(event)}
      </div>
    </div>
  `;
  bindEventFields(editor, event);
  document.getElementById("duplicateEvent").addEventListener("click", () => {
    const copy = JSON.parse(JSON.stringify(event));
    copy.id = uniqueId(`${event.id}_copy`, events().map((row) => row.id));
    events().push(copy);
    state.eventId = copy.id;
    markDirty();
    render();
  });
  document.getElementById("deleteEvent").addEventListener("click", () => {
    if (!confirm("Delete this event definition? Runtime validation may require this ID.")) return;
    const index = events().indexOf(event);
    if (index >= 0) events().splice(index, 1);
    state.eventId = "";
    markDirty();
    render();
  });
}

function personFields(event) {
  if (event.event_family !== "person" && event.person_id === undefined && event.person_name === undefined) return "";
  return `
    <div class="card" style="margin-bottom: 14px;">
      <h3>Person Metadata</h3>
      ${textField("Person ID", event.person_id || "", "person_id")}
      ${textField("Person Name", event.person_name || "", "person_name")}
    </div>
  `;
}

function specialFields(event) {
  if (event.event_family !== "special") return "";
  return `
    <div class="card">
      <h3>Special Event</h3>
      <div class="row">
        ${numberField("Duration Min", event.duration_days_min, "duration_days_min", "1")}
        ${numberField("Duration Max", event.duration_days_max, "duration_days_max", "1")}
      </div>
      <div class="row">
        ${numberField("Market Bias Shift", event.market_bias_shift, "market_bias_shift", "0.001")}
        ${numberField("Volatility Multiplier", event.volatility_multiplier, "volatility_multiplier", "0.01")}
      </div>
      <div class="row">
        ${numberField("Min Year", event.min_year ?? "", "min_year", "1")}
        ${numberField("Min Month", event.min_month ?? "", "min_month", "1")}
      </div>
      <div class="row">
        ${numberField("Max Year", event.max_year ?? "", "max_year", "1")}
        ${numberField("Max Month", event.max_month ?? "", "max_month", "1")}
      </div>
      ${checkboxField("Once Per Run", Boolean(event.once_per_run), "once_per_run")}
      ${textField("Headline Template", event.headline_template, "headline_template")}
      ${textAreaField("Headline Detail Template", event.headline_detail_template, "headline_detail_template", 3)}
      ${textAreaField("Shock Profile JSON", JSON.stringify(event.shock_profile || {}, null, 2), "shock_profile", 8)}
      ${textAreaField("Sector Biases JSON", JSON.stringify(event.sector_biases || {}, null, 2), "sector_biases", 8)}
    </div>
  `;
}

function bindEventFields(container, event) {
  bindId(container, event);
  bindString(container, "category", event, "category", slugify);
  bindSelect(container, "scope", event, "scope");
  bindSelect(container, "tone", event, "tone");
  bindSelect(container, "broker_bias", event, "broker_bias");
  bindNumber(container, "duration_days", event, "duration_days", true);
  bindNumber(container, "sentiment_shift", event, "sentiment_shift", false);
  bindString(container, "description", event, "description");
  const familyInput = container.querySelector("[data-field='event_family']");
  familyInput.addEventListener("change", () => {
    event.event_family = familyInput.value;
    if (event.event_family === "person") {
      event.person_id = event.person_id || "person";
      event.person_name = event.person_name || "";
    }
    if (event.event_family === "special") ensureSpecialDefaults(event);
    markDirty();
    render();
  });
  if (event.event_family === "person") {
    bindString(container, "person_id", event, "person_id", slugify);
    bindString(container, "person_name", event, "person_name");
  }
  if (event.event_family === "special") {
    for (const field of ["duration_days_min", "duration_days_max", "min_year", "min_month", "max_year", "max_month"]) {
      bindOptionalNumber(container, field, event, field, true);
    }
    bindNumber(container, "market_bias_shift", event, "market_bias_shift", false);
    bindNumber(container, "volatility_multiplier", event, "volatility_multiplier", false);
    bindCheckbox(container, "once_per_run", event, "once_per_run");
    bindString(container, "headline_template", event, "headline_template");
    bindString(container, "headline_detail_template", event, "headline_detail_template");
    bindJson(container, "shock_profile", event, "shock_profile");
    bindJson(container, "sector_biases", event, "sector_biases");
  }
}

function bindId(container, event) {
  const input = container.querySelector("[data-field='id']");
  input.addEventListener("change", () => {
    const oldId = event.id;
    const newId = slugify(input.value);
    if (!newId || newId === oldId) return;
    if (events().some((row) => row !== event && row.id === newId)) {
      setStatus(`Event id already exists: ${newId}`, "error");
      input.value = oldId;
      return;
    }
    event.id = newId;
    state.eventId = newId;
    markDirty();
    render();
  });
}

function bindString(container, field, object, key, transform = null) {
  const input = container.querySelector(`[data-field='${field}']`);
  if (!input) return;
  input.addEventListener("input", () => {
    object[key] = transform ? transform(input.value) : input.value;
    markDirty();
  });
}

function bindSelect(container, field, object, key) {
  const input = container.querySelector(`[data-field='${field}']`);
  if (!input) return;
  input.addEventListener("change", () => {
    object[key] = input.value;
    markDirty();
  });
}

function bindNumber(container, field, object, key, integer = false) {
  const input = container.querySelector(`[data-field='${field}']`);
  if (!input) return;
  input.addEventListener("input", () => {
    const value = Number(input.value || 0);
    object[key] = integer ? Math.trunc(value) : value;
    markDirty();
  });
}

function bindOptionalNumber(container, field, object, key, integer = false) {
  const input = container.querySelector(`[data-field='${field}']`);
  if (!input) return;
  input.addEventListener("input", () => {
    if (input.value === "") {
      delete object[key];
    } else {
      const value = Number(input.value || 0);
      object[key] = integer ? Math.trunc(value) : value;
    }
    markDirty();
  });
}

function bindCheckbox(container, field, object, key) {
  const input = container.querySelector(`[data-field='${field}']`);
  if (!input) return;
  input.addEventListener("change", () => {
    object[key] = input.checked;
    markDirty();
  });
}

function bindJson(container, field, object, key) {
  const input = container.querySelector(`[data-field='${field}']`);
  if (!input) return;
  input.addEventListener("change", () => {
    try {
      object[key] = JSON.parse(input.value || "{}");
      markDirty();
      setStatus(`${labelize(field)} applied.`, "ok");
    } catch (error) {
      setStatus(`Invalid ${labelize(field)} JSON: ${error.message}`, "error");
    }
  });
}

function specialEvents() {
  return events().filter((event) => event.event_family === "special");
}

function renderSpecialEffects() {
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Special Effects</h2>
        <p>Fast-edit multi-day market shock duration, market bias, volatility, and headline fields.</p>
      </div>
    </div>
    <div class="card">
      <table style="width: 100%; border-collapse: collapse;">
        <thead>
          <tr>
            <th style="text-align:left; padding: 8px; border-bottom: 1px solid var(--line);">Event</th>
            <th style="text-align:left; padding: 8px; border-bottom: 1px solid var(--line);">Duration</th>
            <th style="text-align:left; padding: 8px; border-bottom: 1px solid var(--line);">Market</th>
            <th style="text-align:left; padding: 8px; border-bottom: 1px solid var(--line);">Headline</th>
          </tr>
        </thead>
        <tbody>
          ${specialEvents().map((event, index) => specialEffectRow(event, index)).join("")}
        </tbody>
      </table>
      ${specialEvents().length ? "" : `<div class="empty">No special events.</div>`}
    </div>
    ${validationPanel()}
  `;
  specialEvents().forEach((event, index) => {
    for (const field of ["duration_days", "duration_days_min", "duration_days_max"]) {
      bindNumber(document, `special_${index}_${field}`, event, field, true);
    }
    for (const field of ["sentiment_shift", "market_bias_shift", "volatility_multiplier"]) {
      bindNumber(document, `special_${index}_${field}`, event, field, false);
    }
    bindString(document, `special_${index}_headline_template`, event, "headline_template");
    bindString(document, `special_${index}_headline_detail_template`, event, "headline_detail_template");
  });
}

function specialEffectRow(event, index) {
  ensureSpecialDefaults(event);
  return `
    <tr>
      <td style="vertical-align: top; min-width: 180px; padding: 8px; border-bottom: 1px solid var(--line);">
        <strong>${escapeHtml(event.id)}</strong><br>
        <span class="chip">${escapeHtml(event.category)}</span>
      </td>
      <td style="vertical-align: top; min-width: 170px; padding: 8px; border-bottom: 1px solid var(--line);">
        ${numberField("Base", event.duration_days, `special_${index}_duration_days`, "1")}
        ${numberField("Min", event.duration_days_min, `special_${index}_duration_days_min`, "1")}
        ${numberField("Max", event.duration_days_max, `special_${index}_duration_days_max`, "1")}
      </td>
      <td style="vertical-align: top; min-width: 170px; padding: 8px; border-bottom: 1px solid var(--line);">
        ${numberField("Sentiment", event.sentiment_shift, `special_${index}_sentiment_shift`, "0.001")}
        ${numberField("Market Bias", event.market_bias_shift, `special_${index}_market_bias_shift`, "0.001")}
        ${numberField("Volatility", event.volatility_multiplier, `special_${index}_volatility_multiplier`, "0.01")}
      </td>
      <td style="vertical-align: top; min-width: 260px; padding: 8px; border-bottom: 1px solid var(--line);">
        ${textField("Headline", event.headline_template, `special_${index}_headline_template`)}
        ${textAreaField("Detail", event.headline_detail_template, `special_${index}_headline_detail_template`, 3)}
      </td>
    </tr>
  `;
}

function renderSectorBiases() {
  const specials = specialEvents();
  if (!specials.some((event) => event.id === state.eventId)) state.eventId = specials[0]?.id || "";
  const event = selectedEvent();
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Sector Biases</h2>
        <p>Special-event sector biases are added to macro sector biases while the shock is active.</p>
      </div>
      <button id="fillSectorBiases">Fill Missing Sectors</button>
    </div>
    <div class="pool-grid">
      <div class="key-list" id="specialKeys"></div>
      <div class="card" id="sectorEditor"></div>
    </div>
    ${validationPanel()}
  `;
  renderKeyButtons("specialKeys", specials.map((row) => row.id), state.eventId, (key) => {
    state.eventId = key;
    render();
  }, (key) => {
    const row = events().find((item) => item.id === key) || {};
    return row.tone || "";
  });
  renderSectorBiasEditor(event);
  document.getElementById("fillSectorBiases").addEventListener("click", () => {
    if (!event || event.event_family !== "special") return;
    ensureSpecialDefaults(event);
    for (const sectorId of state.reference.sector_ids) {
      if (event.sector_biases[sectorId] === undefined) event.sector_biases[sectorId] = 0;
    }
    markDirty();
    render();
  });
}

function renderSectorBiasEditor(event) {
  const editor = document.getElementById("sectorEditor");
  if (!event || event.event_family !== "special") {
    editor.innerHTML = `<div class="empty">Choose a special event.</div>`;
    return;
  }
  ensureSpecialDefaults(event);
  const sectors = state.reference.sector_ids.length ? state.reference.sector_ids : Object.keys(event.sector_biases);
  editor.innerHTML = `
    <div class="card-header">
      <div class="card-title">
        <h3>${escapeHtml(event.id)}</h3>
        <span class="chip">${Object.keys(event.sector_biases).length} sector biases</span>
      </div>
    </div>
    <div class="grid two">
      ${sectors.map((sectorId) => numberField(sectorId, event.sector_biases[sectorId] ?? "", `sector_bias_${sectorId}`, "0.001")).join("")}
    </div>
  `;
  for (const sectorId of sectors) {
    const input = editor.querySelector(`[data-field='sector_bias_${sectorId}']`);
    input.addEventListener("input", () => {
      if (input.value === "") {
        delete event.sector_biases[sectorId];
      } else {
        event.sector_biases[sectorId] = Number(input.value || 0);
      }
      markDirty();
    });
  }
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

function selectField(label, value, field, options) {
  const optionHtml = options.map((option) => {
    const selected = String(option) === String(value) ? " selected" : "";
    return `<option value="${escapeHtml(option)}"${selected}>${escapeHtml(option)}</option>`;
  }).join("");
  return `
    <div class="field">
      <label>${escapeHtml(label)}</label>
      <select data-field="${escapeHtml(field)}">${optionHtml}</select>
    </div>
  `;
}

function checkboxField(label, value, field) {
  return `
    <div class="field">
      <label>${escapeHtml(label)}</label>
      <input type="checkbox" ${value ? "checked" : ""} data-field="${escapeHtml(field)}">
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
