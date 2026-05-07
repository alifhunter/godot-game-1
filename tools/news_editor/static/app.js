const state = {
  source: { schema_version: 1, catalog: {} },
  activeView: "overview",
  dirty: false,
  validation: null,
  poolGroup: "reference_signals",
  poolKey: "",
  bodyGroup: "market_reaction_templates",
  bodyKey: "",
  voiceId: "",
  voiceSection: "headline_templates",
  voiceStage: "recap",
  uploadCallback: null
};

const viewEl = document.getElementById("view");
const statusEl = document.getElementById("status");
const uploadInput = document.getElementById("uploadInput");

const POOL_GROUPS = ["reference_signals", "driver_phrases", "watch_phrases"];
const BODY_GROUPS = ["market_reaction_templates", "source_color_templates", "continuity_templates", "closing_templates"];
const VOICE_SECTIONS = ["headline_templates", "deck_templates", "lead_templates"];
const VOICE_ARRAY_SECTIONS = ["context_templates", "impact_templates"];

function catalog() {
  if (!state.source.catalog || typeof state.source.catalog !== "object") {
    state.source.catalog = {};
  }
  return state.source.catalog;
}

function ensureCatalogDefaults() {
  const data = catalog();
  data.prototype_default_intel_level = Number(data.prototype_default_intel_level || 1);
  data.article_limit = Number(data.article_limit || 12);
  data.outlets = Array.isArray(data.outlets) ? data.outlets : [];
  data.authors = Array.isArray(data.authors) ? data.authors : [];
  data.progress_labels = data.progress_labels && typeof data.progress_labels === "object" ? data.progress_labels : {};
  data.reference_signals = normalizeMap(data.reference_signals);
  data.driver_phrases = normalizeMap(data.driver_phrases);
  data.watch_phrases = normalizeMap(data.watch_phrases);
  data.body_slots = data.body_slots && typeof data.body_slots === "object" ? data.body_slots : {};
  for (const group of BODY_GROUPS) {
    data.body_slots[group] = normalizeMap(data.body_slots[group]);
  }
  data.voice_profiles = data.voice_profiles && typeof data.voice_profiles === "object" ? data.voice_profiles : {};
}

function normalizeMap(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};
  return value;
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

function uniqueId(base, existing) {
  let id = slugify(base);
  let counter = 2;
  while (existing.includes(id)) {
    id = `${slugify(base)}_${counter}`;
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
    setStatus("Loaded editable News source.", "ok");
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
  if (!POOL_GROUPS.includes(state.poolGroup)) state.poolGroup = POOL_GROUPS[0];
  const poolKeys = Object.keys(data[state.poolGroup] || {});
  if (!poolKeys.includes(state.poolKey)) state.poolKey = poolKeys[0] || "";
  if (!BODY_GROUPS.includes(state.bodyGroup)) state.bodyGroup = BODY_GROUPS[0];
  const bodyKeys = Object.keys(data.body_slots?.[state.bodyGroup] || {});
  if (!bodyKeys.includes(state.bodyKey)) state.bodyKey = bodyKeys[0] || "";
  const voiceIds = Object.keys(data.voice_profiles || {});
  if (!voiceIds.includes(state.voiceId)) state.voiceId = voiceIds[0] || "";
  if (!VOICE_SECTIONS.includes(state.voiceSection)) state.voiceSection = VOICE_SECTIONS[0];
  const voice = data.voice_profiles?.[state.voiceId] || {};
  const stageKeys = Object.keys(voice[state.voiceSection] || {});
  if (!stageKeys.includes(state.voiceStage)) state.voiceStage = stageKeys[0] || "recap";
}

function render() {
  ensureCatalogDefaults();
  reconcileSelections();
  document.querySelectorAll(".nav").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === state.activeView);
  });
  if (state.activeView === "overview") renderOverview();
  if (state.activeView === "outlets") renderOutlets();
  if (state.activeView === "authors") renderAuthors();
  if (state.activeView === "pools") renderPools();
  if (state.activeView === "bodySlots") renderBodySlots();
  if (state.activeView === "voices") renderVoices();
  if (state.activeView === "raw") renderRaw();
}

function renderOverview() {
  const data = catalog();
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Overview</h2>
        <p>Edit runtime-wide News settings and progress labels. Runtime articles are still generated in Godot from this template catalog.</p>
      </div>
    </div>
    <div class="grid two">
      <div class="card">
        <h3>Runtime Settings</h3>
        ${numberField("Default Intel Level", data.prototype_default_intel_level, "prototype_default_intel_level")}
        ${numberField("Article Limit", data.article_limit, "article_limit")}
      </div>
      <div class="card">
        <h3>Catalog Counts</h3>
        <p><span class="chip">${data.outlets.length} outlets</span></p>
        <p><span class="chip">${data.authors.length} authors</span></p>
        <p><span class="chip">${Object.keys(data.driver_phrases).length} driver pools</span></p>
        <p><span class="chip">${Object.keys(data.voice_profiles).length} voices</span></p>
      </div>
    </div>
    <div class="card" style="margin-top: 14px;">
      <div class="card-header">
        <h3>Progress Labels</h3>
        <button id="addProgressLabel" class="small">Add Label</button>
      </div>
      <div id="progressRows" class="grid"></div>
    </div>
    ${validationPanel()}
  `;
  bindNumber("prototype_default_intel_level", (value) => data.prototype_default_intel_level = value);
  bindNumber("article_limit", (value) => data.article_limit = value);
  renderKeyValueRows("progressRows", data.progress_labels, "Label", "Text");
  document.getElementById("addProgressLabel").addEventListener("click", () => {
    const key = prompt("Progress label id");
    if (!key) return;
    data.progress_labels[slugify(key)] = "New label";
    markDirty();
    render();
  });
}

function renderOutlets() {
  const data = catalog();
  const voiceOptions = Object.keys(data.voice_profiles);
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Outlets</h2>
        <p>Outlets map to News Content intel levels. Each outlet should reference an existing voice profile.</p>
      </div>
      <button id="addOutlet">Add Outlet</button>
    </div>
    <div class="grid" id="outletCards"></div>
  `;
  const cards = document.getElementById("outletCards");
  if (!data.outlets.length) {
    cards.innerHTML = `<div class="empty">No outlets yet.</div>`;
  }
  data.outlets.forEach((outlet, index) => {
    const card = document.createElement("div");
    card.className = "card";
    card.innerHTML = `
      <div class="card-header">
        <div class="card-title">
          <h3>${escapeHtml(outlet.label || outlet.id || "Untitled outlet")}</h3>
          <span class="chip">Intel ${escapeHtml(outlet.intel_level || 1)}</span>
        </div>
        <button class="danger small" data-delete>Delete</button>
      </div>
      <div class="row">
        ${textField("ID", outlet.id, "id")}
        ${textField("Label", outlet.label, "label")}
      </div>
      <div class="row">
        ${selectField("Voice", outlet.voice, "voice", voiceOptions)}
        ${numberField("Intel Level", outlet.intel_level, "intel_level")}
      </div>
      ${textAreaField("Tagline", outlet.tagline, "tagline", 2)}
      ${textAreaField("Summary", outlet.summary, "summary", 3)}
      ${assetField("Logo Asset", outlet.logo_asset || "", "logo_asset")}
    `;
    bindObjectInputs(card, outlet);
    card.querySelector("[data-delete]").addEventListener("click", () => {
      if (!confirm("Delete this outlet?")) return;
      data.outlets.splice(index, 1);
      markDirty();
      render();
    });
    bindAssetUpload(card, outlet, "logo_asset");
    cards.appendChild(card);
  });
  document.getElementById("addOutlet").addEventListener("click", () => {
    const id = uniqueId("new_outlet", data.outlets.map((row) => row.id));
    data.outlets.push({
      id,
      label: "New Outlet",
      voice: voiceOptions[0] || id,
      intel_level: 1,
      tagline: "",
      summary: ""
    });
    markDirty();
    render();
  });
}

function renderAuthors() {
  const data = catalog();
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Authors</h2>
        <p>Authors are selected by outlet, specialty, sector fit, and deterministic article id. Positive lead frequency requires a contact id.</p>
      </div>
      <button id="addAuthor">Add Author</button>
    </div>
    <div class="grid" id="authorCards"></div>
  `;
  const cards = document.getElementById("authorCards");
  if (!data.authors.length) {
    cards.innerHTML = `<div class="empty">No authors yet.</div>`;
  }
  data.authors.forEach((author, index) => {
    const card = document.createElement("div");
    card.className = "card";
    card.innerHTML = `
      <div class="card-header">
        <div class="card-title">
          <h3>${escapeHtml(author.display_name || author.id || "Untitled author")}</h3>
          <span class="chip">${escapeHtml(author.role || "News Desk")}</span>
        </div>
        <button class="danger small" data-delete>Delete</button>
      </div>
      <div class="row">
        ${textField("ID", author.id, "id")}
        ${textField("Display Name", author.display_name, "display_name")}
      </div>
      <div class="row">
        ${textField("Role", author.role, "role")}
        ${numberField("Lead Frequency", author.lead_frequency, "lead_frequency", "0.01")}
      </div>
      ${textField("Contact ID", author.contact_id, "contact_id")}
      <div class="row">
        ${textAreaField("Outlet IDs", arrayToLines(author.outlet_ids), "outlet_ids", 4)}
        ${textAreaField("Specialties", arrayToLines(author.specialties), "specialties", 4)}
      </div>
      ${textAreaField("Sector IDs", arrayToLines(author.sector_ids), "sector_ids", 3)}
      ${assetField("Portrait Asset", author.portrait_asset || "", "portrait_asset")}
    `;
    bindObjectInputs(card, author, ["outlet_ids", "specialties", "sector_ids"]);
    card.querySelector("[data-delete]").addEventListener("click", () => {
      if (!confirm("Delete this author?")) return;
      data.authors.splice(index, 1);
      markDirty();
      render();
    });
    bindAssetUpload(card, author, "portrait_asset");
    cards.appendChild(card);
  });
  document.getElementById("addAuthor").addEventListener("click", () => {
    const id = uniqueId("new_author", data.authors.map((row) => row.id));
    data.authors.push({
      id,
      display_name: "New Author",
      role: "News Desk",
      outlet_ids: data.outlets[0] ? [data.outlets[0].id] : [],
      specialties: [],
      sector_ids: [],
      contact_id: "",
      portrait_asset: "",
      lead_frequency: 0.0
    });
    markDirty();
    render();
  });
}

function renderPools() {
  const data = catalog();
  const pools = data[state.poolGroup] || {};
  const keys = Object.keys(pools);
  if (!keys.includes(state.poolKey)) state.poolKey = keys[0] || "";
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Phrase Pools</h2>
        <p>One phrase per line. Driver and watch pools need fallbacks because the runtime chooses by category, tone, stage, and event family.</p>
      </div>
    </div>
    <div class="toolbar">
      <label>Pool Group</label>
      <select id="poolGroup">${POOL_GROUPS.map((group) => option(group, group, state.poolGroup)).join("")}</select>
      <button id="addPoolKey" class="small">Add Pool</button>
      <button id="deletePoolKey" class="small danger" ${state.poolKey ? "" : "disabled"}>Delete Pool</button>
    </div>
    <div class="pool-grid">
      <div class="key-list" id="poolKeys"></div>
      <div class="card" id="poolEditor"></div>
    </div>
  `;
  document.getElementById("poolGroup").addEventListener("change", (event) => {
    state.poolGroup = event.target.value;
    state.poolKey = "";
    render();
  });
  renderKeyButtons("poolKeys", keys, state.poolKey, (key) => {
    state.poolKey = key;
    render();
  }, (key) => `${(pools[key] || []).length}`);
  const editor = document.getElementById("poolEditor");
  if (!state.poolKey) {
    editor.innerHTML = `<div class="empty">Choose or add a pool.</div>`;
  } else {
    editor.innerHTML = `
      <div class="card-header">
        <h3>${escapeHtml(state.poolKey)}</h3>
        <span class="chip">${escapeHtml(state.poolGroup)}</span>
      </div>
      ${textAreaField("Phrases", arrayToLines(pools[state.poolKey]), "pool_lines", 12)}
    `;
    editor.querySelector("[data-field='pool_lines']").addEventListener("input", (event) => {
      pools[state.poolKey] = linesToArray(event.target.value);
      markDirty();
    });
  }
  document.getElementById("addPoolKey").addEventListener("click", () => {
    const key = prompt("Pool key");
    if (!key) return;
    const id = uniqueId(key, Object.keys(pools));
    pools[id] = ["New phrase"];
    state.poolKey = id;
    markDirty();
    render();
  });
  document.getElementById("deletePoolKey").addEventListener("click", () => {
    if (!state.poolKey || !confirm(`Delete pool ${state.poolKey}?`)) return;
    delete pools[state.poolKey];
    state.poolKey = "";
    markDirty();
    render();
  });
}

function renderBodySlots() {
  const data = catalog();
  const bodySlots = data.body_slots || {};
  const group = bodySlots[state.bodyGroup] || {};
  const keys = Object.keys(group);
  if (!keys.includes(state.bodyKey)) state.bodyKey = keys[0] || "";
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Body Slots</h2>
        <p>These paragraph pools form the longer article body: reaction, source color, continuity, and closing. Every group should keep a fallback key.</p>
      </div>
    </div>
    <div class="toolbar">
      <label>Slot Group</label>
      <select id="bodyGroup">${BODY_GROUPS.map((slot) => option(slot, slot, state.bodyGroup)).join("")}</select>
      <button id="addBodyKey" class="small">Add Category</button>
      <button id="deleteBodyKey" class="small danger" ${state.bodyKey ? "" : "disabled"}>Delete Category</button>
    </div>
    <div class="pool-grid">
      <div class="key-list" id="bodyKeys"></div>
      <div class="card" id="bodyEditor"></div>
    </div>
  `;
  document.getElementById("bodyGroup").addEventListener("change", (event) => {
    state.bodyGroup = event.target.value;
    state.bodyKey = "";
    render();
  });
  renderKeyButtons("bodyKeys", keys, state.bodyKey, (key) => {
    state.bodyKey = key;
    render();
  }, (key) => `${(group[key] || []).length}`);
  const editor = document.getElementById("bodyEditor");
  if (!state.bodyKey) {
    editor.innerHTML = `<div class="empty">Choose or add a body category.</div>`;
  } else {
    editor.innerHTML = `
      <div class="card-header">
        <h3>${escapeHtml(state.bodyKey)}</h3>
        <span class="chip">${escapeHtml(state.bodyGroup)}</span>
      </div>
      ${textAreaField("Templates", arrayToLines(group[state.bodyKey]), "body_lines", 12)}
    `;
    editor.querySelector("[data-field='body_lines']").addEventListener("input", (event) => {
      group[state.bodyKey] = linesToArray(event.target.value);
      markDirty();
    });
  }
  document.getElementById("addBodyKey").addEventListener("click", () => {
    const key = prompt("Body category key");
    if (!key) return;
    const id = uniqueId(key, Object.keys(group));
    group[id] = ["New body template with {focus_label}."];
    state.bodyKey = id;
    markDirty();
    render();
  });
  document.getElementById("deleteBodyKey").addEventListener("click", () => {
    if (!state.bodyKey || !confirm(`Delete body category ${state.bodyKey}?`)) return;
    delete group[state.bodyKey];
    state.bodyKey = "";
    markDirty();
    render();
  });
}

function renderVoices() {
  const data = catalog();
  const voices = data.voice_profiles || {};
  const voiceIds = Object.keys(voices);
  if (!voiceIds.includes(state.voiceId)) state.voiceId = voiceIds[0] || "";
  const voice = voices[state.voiceId] || {};
  const sectionMap = voice[state.voiceSection] || {};
  const stageKeys = Object.keys(sectionMap);
  if (!stageKeys.includes(state.voiceStage)) state.voiceStage = stageKeys[0] || "recap";
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Voice Profiles</h2>
        <p>Voice profiles provide headline, deck, lead, context, and impact templates for each outlet voice.</p>
      </div>
      <button id="addVoice">Add Voice</button>
    </div>
    <div class="pool-grid">
      <div class="key-list" id="voiceKeys"></div>
      <div class="card" id="voiceEditor"></div>
    </div>
  `;
  renderKeyButtons("voiceKeys", voiceIds, state.voiceId, (key) => {
    state.voiceId = key;
    render();
  }, (key) => `${Object.keys(voices[key]?.headline_templates || {}).length} stages`);
  const editor = document.getElementById("voiceEditor");
  if (!state.voiceId) {
    editor.innerHTML = `<div class="empty">Choose or add a voice profile.</div>`;
  } else {
    editor.innerHTML = `
      <div class="card-header">
        <h3>${escapeHtml(state.voiceId)}</h3>
        <button id="deleteVoice" class="danger small">Delete Voice</button>
      </div>
      ${textAreaField("Headline Prefixes", arrayToLines(voice.headline_prefixes), "headline_prefixes", 4)}
      <div class="toolbar">
        <label>Template Section</label>
        <select id="voiceSection">${VOICE_SECTIONS.map((section) => option(section, section, state.voiceSection)).join("")}</select>
        <button id="addVoiceStage" class="small">Add Stage</button>
        <button id="deleteVoiceStage" class="small danger" ${state.voiceStage ? "" : "disabled"}>Delete Stage</button>
      </div>
      <div class="pool-grid">
        <div class="key-list" id="voiceStages"></div>
        <div>
          ${state.voiceStage ? textAreaField("Stage Templates", arrayToLines(sectionMap[state.voiceStage]), "voice_stage_lines", 10) : `<div class="empty">Choose or add a stage.</div>`}
        </div>
      </div>
      <div class="grid two" style="margin-top: 14px;">
        ${VOICE_ARRAY_SECTIONS.map((section) => textAreaField(section, arrayToLines(voice[section]), section, 6)).join("")}
      </div>
    `;
    editor.querySelector("[data-field='headline_prefixes']").addEventListener("input", (event) => {
      voice.headline_prefixes = linesToArray(event.target.value);
      markDirty();
    });
    for (const section of VOICE_ARRAY_SECTIONS) {
      editor.querySelector(`[data-field='${section}']`).addEventListener("input", (event) => {
        voice[section] = linesToArray(event.target.value);
        markDirty();
      });
    }
    document.getElementById("voiceSection").addEventListener("change", (event) => {
      state.voiceSection = event.target.value;
      state.voiceStage = "";
      render();
    });
    renderKeyButtons("voiceStages", stageKeys, state.voiceStage, (key) => {
      state.voiceStage = key;
      render();
    }, (key) => `${(sectionMap[key] || []).length}`);
    const stageInput = editor.querySelector("[data-field='voice_stage_lines']");
    if (stageInput) {
      stageInput.addEventListener("input", (event) => {
        sectionMap[state.voiceStage] = linesToArray(event.target.value);
        markDirty();
      });
    }
    document.getElementById("addVoiceStage").addEventListener("click", () => {
      const key = prompt("Stage key");
      if (!key) return;
      const id = uniqueId(key, Object.keys(sectionMap));
      sectionMap[id] = ["New template for {focus_label}."];
      state.voiceStage = id;
      markDirty();
      render();
    });
    document.getElementById("deleteVoiceStage").addEventListener("click", () => {
      if (!state.voiceStage || !confirm(`Delete stage ${state.voiceStage}?`)) return;
      delete sectionMap[state.voiceStage];
      state.voiceStage = "";
      markDirty();
      render();
    });
    document.getElementById("deleteVoice").addEventListener("click", () => {
      if (!confirm(`Delete voice ${state.voiceId}?`)) return;
      delete voices[state.voiceId];
      state.voiceId = "";
      markDirty();
      render();
    });
  }
  document.getElementById("addVoice").addEventListener("click", () => {
    const key = prompt("Voice profile id");
    if (!key) return;
    const id = uniqueId(key, Object.keys(voices));
    voices[id] = {
      headline_prefixes: ["News note"],
      headline_templates: { recap: ["{focus_label} stays on the desk watch"] },
      deck_templates: { recap: ["{detail_blend}"] },
      lead_templates: { recap: ["{subject_reference} is still part of today's market conversation."] },
      context_templates: ["{analysis_phrase}, {driver_phrase}."],
      impact_templates: ["For traders, {watch_phrase}"]
    };
    state.voiceId = id;
    markDirty();
    render();
  });
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

function renderKeyValueRows(containerId, object, keyLabel, valueLabel) {
  const container = document.getElementById(containerId);
  container.innerHTML = "";
  for (const [key, value] of Object.entries(object)) {
    const row = document.createElement("div");
    row.className = "row";
    row.innerHTML = `
      <div class="field">
        <label>${escapeHtml(keyLabel)}</label>
        <input value="${escapeHtml(key)}" data-key-input>
      </div>
      <div class="field">
        <label>${escapeHtml(valueLabel)}</label>
        <input value="${escapeHtml(value)}" data-value-input>
      </div>
    `;
    row.querySelector("[data-key-input]").addEventListener("change", (event) => {
      const newKey = slugify(event.target.value);
      if (!newKey || newKey === key) return;
      object[newKey] = object[key];
      delete object[key];
      markDirty();
      render();
    });
    row.querySelector("[data-value-input]").addEventListener("input", (event) => {
      object[key] = event.target.value;
      markDirty();
    });
    container.appendChild(row);
  }
}

function renderKeyButtons(containerId, keys, activeKey, onSelect, badgeFn) {
  const container = document.getElementById(containerId);
  container.innerHTML = "";
  if (!keys.length) {
    container.innerHTML = `<div class="empty">No keys yet.</div>`;
    return;
  }
  keys.sort().forEach((key) => {
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
  return `
    <div class="field">
      <label>${escapeHtml(label)}</label>
      <select data-field="${escapeHtml(field)}">
        ${options.map((row) => option(row, row, value)).join("")}
      </select>
    </div>
  `;
}

function assetField(label, value, field) {
  const preview = value ? `<img class="preview" src="/asset?path=${encodeURIComponent(value)}" alt="">` : "";
  return `
    <div class="field">
      <label>${escapeHtml(label)}</label>
      <div class="asset-row">
        <input value="${escapeHtml(value)}" data-field="${escapeHtml(field)}">
        <button class="small" data-upload="${escapeHtml(field)}">Upload</button>
      </div>
      ${preview}
    </div>
  `;
}

function option(value, label, selected) {
  return `<option value="${escapeHtml(value)}" ${String(value) === String(selected) ? "selected" : ""}>${escapeHtml(label)}</option>`;
}

function bindNumber(field, setter) {
  const input = document.querySelector(`[data-field='${field}']`);
  input.addEventListener("input", (event) => {
    setter(Number(event.target.value || 0));
    markDirty();
  });
}

function bindObjectInputs(root, object, arrayFields = []) {
  root.querySelectorAll("[data-field]").forEach((input) => {
    const field = input.dataset.field;
    input.addEventListener("input", (event) => {
      if (arrayFields.includes(field)) {
        object[field] = linesToArray(event.target.value);
      } else if (input.type === "number") {
        object[field] = Number(event.target.value || 0);
      } else {
        object[field] = event.target.value;
      }
      markDirty();
    });
  });
}

function bindAssetUpload(root, object, field) {
  const button = root.querySelector(`[data-upload='${field}']`);
  if (!button) return;
  button.addEventListener("click", () => {
    state.uploadCallback = (assetPath) => {
      object[field] = assetPath;
      markDirty();
      render();
    };
    uploadInput.value = "";
    uploadInput.click();
  });
}

uploadInput.addEventListener("change", async () => {
  const file = uploadInput.files?.[0];
  if (!file || !state.uploadCallback) return;
  const reader = new FileReader();
  reader.onload = async () => {
    try {
      const result = await requestJson("/api/upload", {
        method: "POST",
        body: JSON.stringify({ filename: file.name, data_url: reader.result })
      });
      state.uploadCallback(result.asset_path);
      setStatus(`Uploaded ${result.filename}.`, "ok");
    } catch (error) {
      setStatus(error.message, "error");
    } finally {
      state.uploadCallback = null;
    }
  };
  reader.readAsDataURL(file);
});

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
