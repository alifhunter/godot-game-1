const state = {
  source: { schema_version: 1, catalog: {} },
  activeView: "overview",
  dirty: false,
  validation: null,
  globalKey: "annual_rups",
  stageId: "",
  familyId: "",
  presentationFamilyId: "",
  rawMode: false
};

const viewEl = document.getElementById("view");
const statusEl = document.getElementById("status");

const CONFIG_SECTIONS = [
  "annual_rups",
  "cash_dividend",
  "stock_dividend",
  "stock_buyback",
  "stock_split",
  "tender_offer",
  "strategic_merger_acquisition",
  "backdoor_listing",
  "ceo_change",
  "rights_issue",
  "restructuring",
  "meeting_defaults"
];
const V1_FAMILY_IDS = [
  "rights_issue",
  "stock_buyback",
  "stock_split",
  "tender_offer",
  "strategic_merger_acquisition",
  "backdoor_listing",
  "ceo_change",
  "private_placement",
  "restructuring"
];
const SESSION_STAGES = ["arrival", "seating", "host_intro", "agenda_reveal", "vote", "result"];
const TONES = ["positive", "negative", "mixed"];
const VISIBILITIES = ["hidden", "visible"];
const ARTICLE_STAGES = ["whisper", "analysis", "confirmation", "recap"];
const PROGRESS_KEYS = ["early", "developing", "follow_through", "recap"];
const VENUES = ["annual_rups", "rupslb"];
const TENDER_BUTTON_FIELDS = ["agree_button_label", "disagree_button_label", "abstain_button_label"];

function catalog() {
  if (!state.source.catalog || typeof state.source.catalog !== "object") {
    state.source.catalog = {};
  }
  return state.source.catalog;
}

function ensureCatalogDefaults() {
  const data = catalog();
  data.review_interval_days = Number(data.review_interval_days || 5);
  for (const section of CONFIG_SECTIONS) {
    data[section] = isObject(data[section]) ? data[section] : {};
  }
  data.stage_order = Array.isArray(data.stage_order) ? data.stage_order : [];
  data.stage_templates = isObject(data.stage_templates) ? data.stage_templates : {};
  data.families = Array.isArray(data.families) ? data.families : [];
  for (const stageId of data.stage_order) {
    if (!isObject(data.stage_templates[stageId])) {
      data.stage_templates[stageId] = defaultStageTemplate(stageId);
    }
  }
  for (const family of data.families) {
    normalizeFamilyForUi(family);
  }
}

function normalizeFamilyForUi(family) {
  family.id = String(family.id || "").trim();
  family.enabled = Boolean(family.enabled);
  family.label = String(family.label || titleize(family.id));
  family.default_venue_type = String(family.default_venue_type || "annual_rups");
  family.mutually_exclusive_families = Array.isArray(family.mutually_exclusive_families) ? family.mutually_exclusive_families : [];
  family.supports_delay = Boolean(family.supports_delay);
  family.prefers_denial_response = Boolean(family.prefers_denial_response);
  family.story_bias = Number(family.story_bias || 1);
  family.agendas = Array.isArray(family.agendas) ? family.agendas : [];
  family.meeting_presentation = isObject(family.meeting_presentation) ? family.meeting_presentation : {};
  ensurePresentationDefaults(family);
}

function defaultStageTemplate(stageId) {
  return {
    label: titleize(stageId),
    visibility: "visible",
    tone: "mixed",
    category: "corporate_action_rumor",
    article_stage: "analysis",
    progress_key: "developing",
    sentiment_shift: 0,
    volatility_multiplier: 1
  };
}

function ensurePresentationDefaults(family) {
  const presentation = family.meeting_presentation;
  presentation.stage_labels = isObject(presentation.stage_labels) ? presentation.stage_labels : {};
  for (const stage of SESSION_STAGES) {
    if (!presentation.stage_labels[stage]) presentation.stage_labels[stage] = titleize(stage);
  }
  presentation.host_intro_lines = Array.isArray(presentation.host_intro_lines) ? presentation.host_intro_lines : [];
  for (const field of ["observer_copy", "vote_prompt", "approved_result_copy", "rejected_result_copy"]) {
    presentation[field] = String(presentation[field] || "");
  }
  if (family.id === "tender_offer") {
    presentation.agree_button_label = String(presentation.agree_button_label || "Tender Shares");
    presentation.disagree_button_label = String(presentation.disagree_button_label || "Hold Shares");
    presentation.abstain_button_label = String(presentation.abstain_button_label || "Observe");
  }
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

function titleize(value) {
  return String(value || "")
    .replace(/_/g, " ")
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function slugify(value, fallback = "id") {
  const cleaned = String(value || "").toLowerCase().replace(/[^a-z0-9_]+/g, "_").replace(/^_+|_+$/g, "");
  return cleaned || fallback;
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
    ensureCatalogDefaults();
    state.dirty = false;
    state.validation = null;
    reconcileSelections();
    setStatus("Loaded editable Corporate Action source.", "ok");
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

function reconcileSelections() {
  const data = catalog();
  if (!["review_interval_days", ...CONFIG_SECTIONS].includes(state.globalKey)) state.globalKey = "annual_rups";
  if (!data.stage_order.includes(state.stageId)) state.stageId = data.stage_order[0] || "";
  const familyIds = data.families.map((row) => row.id);
  if (!familyIds.includes(state.familyId)) state.familyId = familyIds[0] || "";
  if (!familyIds.includes(state.presentationFamilyId)) state.presentationFamilyId = state.familyId || familyIds[0] || "";
}

function render() {
  ensureCatalogDefaults();
  reconcileSelections();
  document.querySelectorAll(".nav").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === state.activeView);
  });
  if (state.activeView === "overview") renderOverview();
  if (state.activeView === "global") renderGlobal();
  if (state.activeView === "stages") renderStages();
  if (state.activeView === "families") renderFamilies();
  if (state.activeView === "presentation") renderPresentation();
  if (state.activeView === "raw") renderRaw();
}

function renderOverview() {
  const data = catalog();
  const enabledFamilies = data.families.filter((family) => family.enabled).length;
  const rupslbFamilies = data.families.filter((family) => family.default_venue_type === "rupslb").length;
  const agendaCount = data.families.reduce((total, family) => total + (family.agendas || []).length, 0);
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Overview</h2>
        <p>Edit the corporate-action generator catalog used for dividends, organic chain review, RUPSLB/Annual RUPS meeting setup, stage-driven news arcs, and interactive meeting copy.</p>
      </div>
    </div>
    <div class="grid two">
      <div class="card">
        <h3>Runtime Shape</h3>
        <p><span class="chip">${data.families.length} families</span></p>
        <p><span class="chip">${enabledFamilies} enabled</span></p>
        <p><span class="chip">${rupslbFamilies} RUPSLB default</span></p>
        <p><span class="chip">${agendaCount} agendas</span></p>
      </div>
      <div class="card">
        <h3>Timing</h3>
        ${numberField("Family Review Interval Days", data.review_interval_days, "review_interval_days")}
        <p><span class="chip">${data.stage_order.length} chain stages</span></p>
        <p><span class="chip">${data.annual_rups.start_year || "-"}-${data.annual_rups.end_year || "-"} Annual RUPS</span></p>
      </div>
    </div>
    <div class="card" style="margin-top: 14px;">
      <div class="card-header">
        <h3>V1 Family Coverage</h3>
        <span class="chip">${V1_FAMILY_IDS.filter((id) => data.families.some((family) => family.id === id)).length}/${V1_FAMILY_IDS.length}</span>
      </div>
      <div class="toolbar">
        ${V1_FAMILY_IDS.map((id) => `<span class="chip">${escapeHtml(id)} ${data.families.some((family) => family.id === id) ? "ok" : "missing"}</span>`).join("")}
      </div>
    </div>
    ${validationPanel()}
  `;
  document.querySelector("[data-field='review_interval_days']").addEventListener("input", (event) => {
    data.review_interval_days = Number(event.target.value || 0);
    markDirty();
  });
}

function renderGlobal() {
  const data = catalog();
  const keys = ["review_interval_days", ...CONFIG_SECTIONS];
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Global Rules</h2>
        <p>Numeric knobs for dividends, family terms, meeting timing, price support, dilution, lockups, and probability windows.</p>
      </div>
    </div>
    <div class="pool-grid">
      <div class="key-list" id="globalKeys"></div>
      <div class="card" id="globalEditor"></div>
    </div>
    ${validationPanel()}
  `;
  renderKeyButtons("globalKeys", keys, state.globalKey, (key) => {
    state.globalKey = key;
    render();
  }, (key) => key === "review_interval_days" ? `${data.review_interval_days} days` : `${Object.keys(data[key] || {}).length} keys`);
  const editor = document.getElementById("globalEditor");
  if (state.globalKey === "review_interval_days") {
    editor.innerHTML = `
      <h3>review_interval_days</h3>
      ${numberField("Review Interval Days", data.review_interval_days, "review_interval_days")}
    `;
    editor.querySelector("[data-field='review_interval_days']").addEventListener("input", (event) => {
      data.review_interval_days = Number(event.target.value || 0);
      markDirty();
    });
    return;
  }
  editor.innerHTML = `
    <div class="card-header">
      <div class="card-title">
        <h3>${escapeHtml(state.globalKey)}</h3>
        <span class="chip">${Object.keys(data[state.globalKey] || {}).length} fields</span>
      </div>
    </div>
    ${renderGenericObject(data[state.globalKey], state.globalKey)}
  `;
  bindGenericInputs(editor);
}

function renderStages() {
  const data = catalog();
  const stage = data.stage_templates[state.stageId] || defaultStageTemplate(state.stageId);
  data.stage_templates[state.stageId] = stage;
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Stages</h2>
        <p>Stage order controls chain continuity. Stage templates feed news/twooter category, public visibility, sentiment, and volatility context.</p>
      </div>
    </div>
    <div class="card" style="margin-bottom: 14px;">
      ${textAreaField("Stage Order", arrayToLines(data.stage_order), "stage_order", 5)}
    </div>
    <div class="pool-grid">
      <div class="key-list" id="stageKeys"></div>
      <div class="card" id="stageEditor"></div>
    </div>
    ${validationPanel()}
  `;
  document.querySelector("[data-field='stage_order']").addEventListener("change", (event) => {
    data.stage_order = linesToArray(event.target.value).map((row) => slugify(row));
    for (const stageId of data.stage_order) {
      if (!isObject(data.stage_templates[stageId])) data.stage_templates[stageId] = defaultStageTemplate(stageId);
    }
    state.stageId = data.stage_order.includes(state.stageId) ? state.stageId : data.stage_order[0] || "";
    markDirty();
    render();
  });
  renderKeyButtons("stageKeys", data.stage_order, state.stageId, (key) => {
    state.stageId = key;
    render();
  }, (key) => {
    const row = data.stage_templates[key] || {};
    return `${row.visibility || ""} / ${row.tone || ""}`;
  });
  renderStageEditor(stage);
}

function renderStageEditor(stage) {
  const editor = document.getElementById("stageEditor");
  if (!state.stageId) {
    editor.innerHTML = `<div class="empty">Add a stage id to the stage order.</div>`;
    return;
  }
  editor.innerHTML = `
    <div class="card-header">
      <div class="card-title">
        <h3>${escapeHtml(stage.label || state.stageId)}</h3>
        <span class="chip">${escapeHtml(state.stageId)}</span>
      </div>
    </div>
    ${textField("Label", stage.label, "label")}
    <div class="row">
      ${selectField("Visibility", stage.visibility, "visibility", VISIBILITIES)}
      ${selectField("Tone", stage.tone, "tone", TONES)}
    </div>
    <div class="row">
      ${textField("News Category", stage.category, "category")}
      ${selectField("Article Stage", stage.article_stage, "article_stage", ARTICLE_STAGES)}
    </div>
    <div class="row">
      ${selectField("Progress Key", stage.progress_key, "progress_key", PROGRESS_KEYS)}
      ${numberField("Sentiment Shift", stage.sentiment_shift, "sentiment_shift", "0.01")}
    </div>
    ${numberField("Volatility Multiplier", stage.volatility_multiplier, "volatility_multiplier", "0.01")}
  `;
  bindObjectInputs(editor, stage);
}

function renderFamilies() {
  const data = catalog();
  const family = data.families.find((row) => row.id === state.familyId);
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Families</h2>
        <p>Family rows define the generator-facing identity, meeting venue, mutual-exclusion behavior, spawn bias, and shareholder agenda payload.</p>
      </div>
      <button id="addFamily">Add Family</button>
    </div>
    <div class="pool-grid">
      <div class="key-list" id="familyKeys"></div>
      <div class="card" id="familyEditor"></div>
    </div>
    ${validationPanel()}
  `;
  renderKeyButtons("familyKeys", data.families.map((row) => row.id), state.familyId, (key) => {
    state.familyId = key;
    render();
  }, (key) => {
    const row = data.families.find((item) => item.id === key) || {};
    return row.enabled ? row.default_venue_type || "" : "disabled";
  });
  renderFamilyEditor(family);
  document.getElementById("addFamily").addEventListener("click", () => {
    const id = uniqueId("new_family", data.families.map((row) => row.id));
    data.families.push({
      id,
      enabled: false,
      label: "New Family",
      default_venue_type: "annual_rups",
      mutually_exclusive_families: [],
      supports_delay: false,
      prefers_denial_response: false,
      story_bias: 0.5,
      agendas: [{ id: `${id}_approval`, label: "Approve agenda", description: "Shareholders review the proposed agenda." }],
      meeting_presentation: {
        stage_labels: Object.fromEntries(SESSION_STAGES.map((stage) => [stage, titleize(stage)])),
        host_intro_lines: ["The chair opens the meeting and frames the proposed agenda."],
        observer_copy: "You can watch the room, but only shareholders recorded before the meeting can cast a weighted vote.",
        vote_prompt: "The host now asks shareholders to vote on the proposed agenda.",
        approved_result_copy: "The room approves the proposal. The market will digest the outcome on the next simulation day.",
        rejected_result_copy: "The room rejects the proposal. The market will react to the failed agenda on the next simulation day."
      }
    });
    state.familyId = id;
    state.presentationFamilyId = id;
    markDirty();
    render();
  });
}

function renderFamilyEditor(family) {
  const editor = document.getElementById("familyEditor");
  const data = catalog();
  if (!family) {
    editor.innerHTML = `<div class="empty">Choose or add a family.</div>`;
    return;
  }
  normalizeFamilyForUi(family);
  editor.innerHTML = `
    <div class="card-header">
      <div class="card-title">
        <h3>${escapeHtml(family.label || family.id)}</h3>
        <span class="chip">${escapeHtml(family.default_venue_type || "venue")}</span>
      </div>
      <button id="deleteFamily" class="small danger">Delete Family</button>
    </div>
    <div class="row">
      ${textField("ID", family.id, "id")}
      ${textField("Label", family.label, "label")}
    </div>
    <div class="row">
      ${selectField("Default Venue", family.default_venue_type, "default_venue_type", VENUES)}
      ${numberField("Story Bias", family.story_bias, "story_bias", "0.01")}
    </div>
    <div class="toolbar">
      <label><input type="checkbox" data-check="enabled" ${family.enabled ? "checked" : ""}> Enabled</label>
      <label><input type="checkbox" data-check="supports_delay" ${family.supports_delay ? "checked" : ""}> Supports delay</label>
      <label><input type="checkbox" data-check="prefers_denial_response" ${family.prefers_denial_response ? "checked" : ""}> Prefers denial response</label>
    </div>
    ${textAreaField("Mutually Exclusive Families", arrayToLines(family.mutually_exclusive_families), "mutually_exclusive_families", 5)}
    <div class="card" style="margin-top: 14px;">
      <div class="card-header">
        <h3>Agendas</h3>
        <button id="addAgenda" class="small">Add Agenda</button>
      </div>
      <div id="agendaRows"></div>
    </div>
  `;
  bindObjectInputs(editor, family, ["mutually_exclusive_families"]);
  editor.querySelector("[data-field='id']").addEventListener("change", (event) => {
    const oldId = family.id;
    const newId = slugify(event.target.value);
    if (!newId || newId === oldId) return;
    if (data.families.some((row) => row !== family && row.id === newId)) {
      setStatus(`Family id already exists: ${newId}`, "error");
      event.target.value = oldId;
      return;
    }
    family.id = newId;
    state.familyId = newId;
    state.presentationFamilyId = newId;
    markDirty();
    render();
  });
  document.getElementById("deleteFamily").addEventListener("click", () => {
    if (!confirm("Delete this family? V1 families are required by validation.")) return;
    const index = data.families.indexOf(family);
    if (index >= 0) data.families.splice(index, 1);
    state.familyId = "";
    markDirty();
    render();
  });
  document.getElementById("addAgenda").addEventListener("click", () => {
    const id = uniqueId(`${family.id}_agenda`, family.agendas.map((row) => row.id));
    family.agendas.push({ id, label: "Approve agenda", description: "Shareholders review the proposed agenda." });
    markDirty();
    render();
  });
  renderAgendaRows(family);
}

function renderAgendaRows(family) {
  const rows = document.getElementById("agendaRows");
  rows.innerHTML = family.agendas.map((agenda, index) => `
    <div class="card" style="margin-bottom: 10px;">
      <div class="card-header">
        <h4>${escapeHtml(agenda.label || agenda.id || `Agenda ${index + 1}`)}</h4>
        <button class="small danger" data-delete-agenda="${index}">Delete</button>
      </div>
      <div class="row">
        ${textField("ID", agenda.id, `agenda_id_${index}`)}
        ${textField("Label", agenda.label, `agenda_label_${index}`)}
      </div>
      ${textAreaField("Description", agenda.description, `agenda_description_${index}`, 3)}
    </div>
  `).join("") || `<div class="empty">No agendas.</div>`;
  family.agendas.forEach((agenda, index) => {
    rows.querySelector(`[data-field='agenda_id_${index}']`).addEventListener("change", (event) => {
      const newId = slugify(event.target.value);
      if (!newId) return;
      if (family.agendas.some((row) => row !== agenda && row.id === newId)) {
        setStatus(`Agenda id already exists: ${newId}`, "error");
        event.target.value = agenda.id;
        return;
      }
      agenda.id = newId;
      markDirty();
      render();
    });
    rows.querySelector(`[data-field='agenda_label_${index}']`).addEventListener("input", (event) => {
      agenda.label = event.target.value;
      markDirty();
    });
    rows.querySelector(`[data-field='agenda_description_${index}']`).addEventListener("input", (event) => {
      agenda.description = event.target.value;
      markDirty();
    });
  });
  rows.querySelectorAll("[data-delete-agenda]").forEach((button) => {
    button.addEventListener("click", () => {
      const index = Number(button.dataset.deleteAgenda);
      family.agendas.splice(index, 1);
      markDirty();
      render();
    });
  });
}

function renderPresentation() {
  const data = catalog();
  const family = data.families.find((row) => row.id === state.presentationFamilyId);
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Meeting Copy</h2>
        <p>Interactive RUPSLB/meeting presentation copy for each family. Stage labels must cover every session stage.</p>
      </div>
    </div>
    <div class="pool-grid">
      <div class="key-list" id="presentationKeys"></div>
      <div class="card" id="presentationEditor"></div>
    </div>
    ${validationPanel()}
  `;
  renderKeyButtons("presentationKeys", data.families.map((row) => row.id), state.presentationFamilyId, (key) => {
    state.presentationFamilyId = key;
    render();
  }, (key) => {
    const row = data.families.find((item) => item.id === key) || {};
    return row.default_venue_type || "";
  });
  renderPresentationEditor(family);
}

function renderPresentationEditor(family) {
  const editor = document.getElementById("presentationEditor");
  if (!family) {
    editor.innerHTML = `<div class="empty">Choose a family.</div>`;
    return;
  }
  normalizeFamilyForUi(family);
  const presentation = family.meeting_presentation;
  const showTenderButtons = family.id === "tender_offer" || TENDER_BUTTON_FIELDS.some((field) => presentation[field]);
  editor.innerHTML = `
    <div class="card-header">
      <div class="card-title">
        <h3>${escapeHtml(family.label || family.id)}</h3>
        <span class="chip">${escapeHtml(family.id)}</span>
      </div>
    </div>
    <div class="grid two">
      ${SESSION_STAGES.map((stage) => textField(`Stage Label: ${stage}`, presentation.stage_labels[stage], `stage_${stage}`)).join("")}
    </div>
    ${textAreaField("Host Intro Lines", arrayToLines(presentation.host_intro_lines), "host_intro_lines", 6)}
    ${textAreaField("Observer Copy", presentation.observer_copy, "observer_copy", 3)}
    ${textAreaField("Vote Prompt", presentation.vote_prompt, "vote_prompt", 3)}
    <div class="row">
      ${textAreaField("Approved Result Copy", presentation.approved_result_copy, "approved_result_copy", 5)}
      ${textAreaField("Rejected Result Copy", presentation.rejected_result_copy, "rejected_result_copy", 5)}
    </div>
    ${showTenderButtons ? `
      <div class="card" style="margin-top: 14px;">
        <h3>Tender / Election Buttons</h3>
        <div class="row">
          ${textField("Agree Button", presentation.agree_button_label || "", "agree_button_label")}
          ${textField("Disagree Button", presentation.disagree_button_label || "", "disagree_button_label")}
        </div>
        ${textField("Abstain Button", presentation.abstain_button_label || "", "abstain_button_label")}
      </div>
    ` : ""}
  `;
  for (const stage of SESSION_STAGES) {
    editor.querySelector(`[data-field='stage_${stage}']`).addEventListener("input", (event) => {
      presentation.stage_labels[stage] = event.target.value;
      markDirty();
    });
  }
  editor.querySelector("[data-field='host_intro_lines']").addEventListener("input", (event) => {
    presentation.host_intro_lines = linesToArray(event.target.value);
    markDirty();
  });
  for (const field of ["observer_copy", "vote_prompt", "approved_result_copy", "rejected_result_copy", ...TENDER_BUTTON_FIELDS]) {
    const element = editor.querySelector(`[data-field='${field}']`);
    if (!element) continue;
    element.addEventListener("input", (event) => {
      presentation[field] = event.target.value;
      markDirty();
    });
  }
}

function renderRaw() {
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Raw JSON</h2>
        <p>Use this for bulk edits. Apply parses into the editable source wrapper; Save Source persists it.</p>
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
      state.source = parsed.catalog ? parsed : { schema_version: 1, catalog: parsed };
      ensureCatalogDefaults();
      markDirty();
      setStatus("Raw JSON applied to editor state.", "ok");
      render();
    } catch (error) {
      setStatus(`Invalid JSON: ${error.message}`, "error");
    }
  });
}

function renderGenericObject(value, pathPrefix) {
  if (!isObject(value)) return `<div class="empty">This section is not an object.</div>`;
  return Object.keys(value).map((key) => {
    const path = `${pathPrefix}.${key}`;
    const row = value[key];
    if (isObject(row)) {
      return `
        <div class="card" style="margin-bottom: 12px;">
          <h4>${escapeHtml(key)}</h4>
          ${renderGenericObject(row, path)}
        </div>
      `;
    }
    if (Array.isArray(row)) {
      const primitive = row.every((item) => !isObject(item) && !Array.isArray(item));
      const numberArray = primitive && row.length > 0 && row.every((item) => typeof item === "number");
      if (primitive) {
        return textAreaField(titleize(key), arrayToLines(row), path, Math.min(Math.max(row.length + 2, 4), 10), {
          "data-array-path": path,
          "data-array-type": numberArray ? "number" : "string"
        });
      }
      return textAreaField(titleize(key), JSON.stringify(row, null, 2), path, 10, { "data-json-path": path });
    }
    if (typeof row === "boolean") {
      return `<div class="toolbar"><label><input type="checkbox" data-bool-path="${escapeHtml(path)}" ${row ? "checked" : ""}> ${escapeHtml(titleize(key))}</label></div>`;
    }
    if (typeof row === "number") {
      return numberField(titleize(key), row, path, numberStep(row), { "data-number-path": path });
    }
    const text = String(row ?? "");
    if (text.length > 80) {
      return textAreaField(titleize(key), text, path, 4, { "data-string-path": path });
    }
    return textField(titleize(key), text, path, { "data-string-path": path });
  }).join("");
}

function bindGenericInputs(container) {
  container.querySelectorAll("[data-number-path]").forEach((element) => {
    element.addEventListener("input", () => {
      setByPath(element.dataset.numberPath, Number(element.value || 0));
      markDirty();
    });
  });
  container.querySelectorAll("[data-bool-path]").forEach((element) => {
    element.addEventListener("change", () => {
      setByPath(element.dataset.boolPath, element.checked);
      markDirty();
    });
  });
  container.querySelectorAll("[data-string-path]").forEach((element) => {
    element.addEventListener("input", () => {
      setByPath(element.dataset.stringPath, element.value);
      markDirty();
    });
  });
  container.querySelectorAll("[data-array-path]").forEach((element) => {
    element.addEventListener("input", () => {
      const rows = linesToArray(element.value);
      setByPath(element.dataset.arrayPath, element.dataset.arrayType === "number" ? rows.map((row) => Number(row || 0)) : rows);
      markDirty();
    });
  });
  container.querySelectorAll("[data-json-path]").forEach((element) => {
    element.addEventListener("change", () => {
      try {
        setByPath(element.dataset.jsonPath, JSON.parse(element.value));
        setStatus("JSON field applied.", "ok");
        markDirty();
      } catch (error) {
        setStatus(`Invalid JSON field: ${error.message}`, "error");
      }
    });
  });
}

function setByPath(path, value) {
  const parts = path.split(".");
  let target = catalog();
  for (let index = 0; index < parts.length - 1; index += 1) {
    const key = parts[index];
    if (!isObject(target[key])) target[key] = {};
    target = target[key];
  }
  target[parts[parts.length - 1]] = value;
}

function bindObjectInputs(container, object, arrayFields = []) {
  container.querySelectorAll("[data-field]").forEach((element) => {
    const field = element.dataset.field;
    if (field === "id") return;
    element.addEventListener("input", () => {
      if (arrayFields.includes(field)) {
        object[field] = linesToArray(element.value);
      } else if (element.type === "number") {
        object[field] = Number(element.value || 0);
      } else {
        object[field] = element.value;
      }
      markDirty();
    });
    if (element.tagName === "SELECT") {
      element.addEventListener("change", () => {
        object[field] = element.value;
        markDirty();
      });
    }
  });
  container.querySelectorAll("[data-check]").forEach((element) => {
    element.addEventListener("change", () => {
      object[element.dataset.check] = element.checked;
      markDirty();
    });
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

function textField(label, value, field, attrs = {}) {
  return `
    <div class="field">
      <label>${escapeHtml(label)}</label>
      <input value="${escapeHtml(value)}" data-field="${escapeHtml(field)}" ${attrsToHtml(attrs)}>
    </div>
  `;
}

function numberField(label, value, field, step = "1", attrs = {}) {
  return `
    <div class="field">
      <label>${escapeHtml(label)}</label>
      <input type="number" step="${escapeHtml(step)}" value="${escapeHtml(value)}" data-field="${escapeHtml(field)}" ${attrsToHtml(attrs)}>
    </div>
  `;
}

function textAreaField(label, value, field, rows = 4, attrs = {}) {
  return `
    <div class="field">
      <label>${escapeHtml(label)}</label>
      <textarea rows="${rows}" data-field="${escapeHtml(field)}" ${attrsToHtml(attrs)}>${escapeHtml(value)}</textarea>
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

function attrsToHtml(attrs) {
  return Object.entries(attrs).map(([key, value]) => `${escapeHtml(key)}="${escapeHtml(value)}"`).join(" ");
}

function numberStep(value) {
  return Number.isInteger(Number(value)) ? "1" : "0.01";
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
