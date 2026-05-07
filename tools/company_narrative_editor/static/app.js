const state = {
  source: { schema_version: 1, archetype_templates: [], word_data: {}, profile_data: {} },
  activeView: "overview",
  dirty: false,
  validation: null,
  templateId: "",
  archetypeId: "",
  sectorId: "",
  sizeId: "",
  tagId: "",
  weightSectorId: ""
};

const viewEl = document.getElementById("view");
const statusEl = document.getElementById("status");

const ANCHOR_FIELDS = [
  "base_price",
  "quality",
  "growth",
  "risk",
  "market_cap",
  "free_float_pct",
  "avg_daily_value",
  "net_profit_margin",
  "debt_to_equity"
];
const ARCHETYPE_POOLS = ["descriptor_pool", "verb_pool", "differentiator_pool", "tag_pool"];
const SECTOR_POOLS = ["business_pool", "scope_pool", "differentiator_pool", "tag_pool"];
const SIZE_POOLS = ["descriptor_pool", "tag_pool"];
const KNOWN_TAGS = [
  "domestic_demand",
  "quiet_execution",
  "stealth_interest",
  "retail_favorite",
  "narrative_hot",
  "commodity_beta",
  "policy_beta",
  "foreign_watchlist",
  "institution_quality",
  "supportive_balance_sheet",
  "capex_cycle"
];

function source() {
  if (!state.source || typeof state.source !== "object") state.source = {};
  return state.source;
}

function profileData() {
  const src = source();
  if (!src.profile_data || typeof src.profile_data !== "object") src.profile_data = {};
  return src.profile_data;
}

function ensureSourceDefaults() {
  const src = source();
  src.schema_version = Number(src.schema_version || 1);
  src.notes = String(src.notes || "");
  src.archetype_templates = Array.isArray(src.archetype_templates) ? src.archetype_templates : [];
  src.word_data = isObject(src.word_data) ? src.word_data : {};
  src.word_data.unique_words = Array.isArray(src.word_data.unique_words) ? src.word_data.unique_words : [];
  src.word_data.total_count = src.word_data.unique_words.length;
  const data = profileData();
  data._meta = isObject(data._meta) ? data._meta : {};
  data._meta.version = String(data._meta.version || "1.0.0");
  data._meta.description = String(data._meta.description || "");
  data.reference_year = Number(data.reference_year || 2020);
  data.sentence_settings = isObject(data.sentence_settings) ? data.sentence_settings : {};
  data.sentence_settings.optional_third_sentence_probability = Number(data.sentence_settings.optional_third_sentence_probability ?? 0.55);
  data.sentence_templates = isObject(data.sentence_templates) ? data.sentence_templates : {};
  data.sentence_templates.primary_pool = Array.isArray(data.sentence_templates.primary_pool) ? data.sentence_templates.primary_pool : [];
  data.archetype_weights_by_sector = isObject(data.archetype_weights_by_sector) ? data.archetype_weights_by_sector : {};
  data.archetypes = isObject(data.archetypes) ? data.archetypes : {};
  data.sizes = isObject(data.sizes) ? data.sizes : {};
  data.sectors = isObject(data.sectors) ? data.sectors : {};
  data.narrative_tag_sentences = isObject(data.narrative_tag_sentences) ? data.narrative_tag_sentences : {};
  data.global_differentiator_pool = Array.isArray(data.global_differentiator_pool) ? data.global_differentiator_pool : [];
  src.archetype_templates.forEach(normalizeTemplateForUi);
  Object.values(data.archetypes).forEach(normalizeArchetypeForUi);
  Object.values(data.sizes).forEach(normalizeSizeForUi);
  Object.values(data.sectors).forEach(normalizeSectorForUi);
}

function normalizeTemplateForUi(template) {
  template.id = slugify(template.id || "template");
  template.ticker = normalizeTicker(template.ticker || template.id);
  template.name = String(template.name || "");
  template.sector_id = String(template.sector_id || "");
  template.narrative_tags = Array.isArray(template.narrative_tags) ? template.narrative_tags : [];
  template.anchors = isObject(template.anchors) ? template.anchors : {};
  for (const field of ANCHOR_FIELDS) template.anchors[field] = Number(template.anchors[field] || 0);
}

function normalizeArchetypeForUi(row) {
  row.label = String(row.label || "");
  row.tone = String(row.tone || "");
  row.age_range = Array.isArray(row.age_range) ? row.age_range : [1, 20];
  row.allowed_sizes = Array.isArray(row.allowed_sizes) ? row.allowed_sizes : [];
  row.size_weights = isObject(row.size_weights) ? row.size_weights : {};
  for (const field of ARCHETYPE_POOLS) row[field] = Array.isArray(row[field]) ? row[field] : [];
}

function normalizeSizeForUi(row) {
  row.label = String(row.label || "");
  row.employee_range = Array.isArray(row.employee_range) ? row.employee_range : [1, 100];
  row.revenue_hint_range = Array.isArray(row.revenue_hint_range) ? row.revenue_hint_range : [0, 1];
  for (const field of SIZE_POOLS) row[field] = Array.isArray(row[field]) ? row[field] : [];
}

function normalizeSectorForUi(row) {
  for (const field of SECTOR_POOLS) row[field] = Array.isArray(row[field]) ? row[field] : [];
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

function rangeToLines(value) {
  return Array.isArray(value) ? value.slice(0, 2).join("\n") : "";
}

function linesToNumberRange(value, integer = false) {
  const rows = linesToArray(value);
  const left = Number(rows[0] || 0);
  const right = Number(rows[1] || left || 0);
  return integer ? [Math.trunc(left), Math.trunc(right)] : [left, right];
}

function slugify(value, fallback = "id") {
  const cleaned = String(value || "").toLowerCase().replace(/[^a-z0-9_]+/g, "_").replace(/^_+|_+$/g, "");
  return cleaned || fallback;
}

function normalizeTicker(value) {
  return String(value || "").toUpperCase().replace(/[^A-Z]/g, "").slice(0, 4);
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
    state.source = await requestJson("/api/source");
    ensureSourceDefaults();
    state.dirty = false;
    state.validation = null;
    reconcileSelections();
    setStatus("Loaded editable Company Narrative source.", "ok");
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
    setStatus(validationMessage(`Exported runtime JSON:\n${(payload.paths || []).join("\n")}`, state.validation), "ok");
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
  const src = source();
  const data = profileData();
  const templateIds = src.archetype_templates.map((row) => row.id);
  if (!templateIds.includes(state.templateId)) state.templateId = templateIds[0] || "";
  const archetypeIds = Object.keys(data.archetypes);
  if (!archetypeIds.includes(state.archetypeId)) state.archetypeId = archetypeIds[0] || "";
  const sectorIds = Object.keys(data.sectors);
  if (!sectorIds.includes(state.sectorId)) state.sectorId = sectorIds[0] || "";
  if (!sectorIds.includes(state.weightSectorId)) state.weightSectorId = sectorIds[0] || "";
  const sizeIds = Object.keys(data.sizes).sort((a, b) => Number(a) - Number(b));
  if (!sizeIds.includes(state.sizeId)) state.sizeId = sizeIds[0] || "";
  const tagIds = Object.keys(data.narrative_tag_sentences);
  if (!tagIds.includes(state.tagId)) state.tagId = tagIds[0] || "";
}

function render() {
  ensureSourceDefaults();
  reconcileSelections();
  document.querySelectorAll(".nav").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === state.activeView);
  });
  if (state.activeView === "overview") renderOverview();
  if (state.activeView === "templates") renderTemplates();
  if (state.activeView === "words") renderWords();
  if (state.activeView === "profile") renderProfileCopy();
  if (state.activeView === "archetypes") renderArchetypes();
  if (state.activeView === "sectors") renderSectors();
  if (state.activeView === "sizes") renderSizes();
  if (state.activeView === "tags") renderNarrativeTags();
  if (state.activeView === "weights") renderWeights();
  if (state.activeView === "raw") renderRaw();
}

function renderOverview() {
  const src = source();
  const data = profileData();
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Overview</h2>
        <p>Edit company seed templates, generated-name words, profile copy pools, archetype/sector/size metadata, and narrative tag sentences.</p>
      </div>
    </div>
    <div class="grid two">
      <div class="card">
        <h3>Runtime Files</h3>
        <p><span class="chip">${src.archetype_templates.length} seed templates</span></p>
        <p><span class="chip">${src.word_data.unique_words.length} name words</span></p>
        <p><span class="chip">${Object.keys(data.archetypes).length} profile archetypes</span></p>
      </div>
      <div class="card">
        <h3>Profile Pools</h3>
        <p><span class="chip">${Object.keys(data.sectors).length} sectors</span></p>
        <p><span class="chip">${Object.keys(data.sizes).length} sizes</span></p>
        <p><span class="chip">${Object.keys(data.narrative_tag_sentences).length} narrative tags</span></p>
      </div>
    </div>
    <div class="card" style="margin-top: 14px;">
      ${textAreaField("Source Notes", src.notes, "notes", 4)}
    </div>
    ${validationPanel()}
  `;
  document.querySelector("[data-field='notes']").addEventListener("input", (event) => {
    src.notes = event.target.value;
    markDirty();
  });
}

function renderTemplates() {
  const src = source();
  const template = src.archetype_templates.find((row) => row.id === state.templateId);
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Seed Templates</h2>
        <p>These rows are used directly when company_count is zero and as sector-matched anchors for generated rosters.</p>
      </div>
      <button id="addTemplate">Add Template</button>
    </div>
    <div class="pool-grid">
      <div class="key-list" id="templateKeys"></div>
      <div class="card" id="templateEditor"></div>
    </div>
    ${validationPanel()}
  `;
  renderKeyButtons("templateKeys", src.archetype_templates.map((row) => row.id), state.templateId, (key) => {
    state.templateId = key;
    render();
  }, (key) => {
    const row = src.archetype_templates.find((item) => item.id === key) || {};
    return row.ticker || "";
  });
  renderTemplateEditor(template);
  document.getElementById("addTemplate").addEventListener("click", () => {
    const id = uniqueId("new_company", src.archetype_templates.map((row) => row.id));
    src.archetype_templates.push({
      id,
      ticker: "NEWC",
      name: "New Company",
      sector_id: Object.keys(profileData().sectors)[0] || "consumer",
      narrative_tags: ["quiet_execution"],
      anchors: {
        base_price: 100,
        quality: 55,
        growth: 50,
        risk: 45,
        market_cap: 1000000000000,
        free_float_pct: 35,
        avg_daily_value: 5000000000,
        net_profit_margin: 5,
        debt_to_equity: 0.5
      }
    });
    state.templateId = id;
    markDirty();
    render();
  });
}

function renderTemplateEditor(template) {
  const editor = document.getElementById("templateEditor");
  const src = source();
  if (!template) {
    editor.innerHTML = `<div class="empty">Choose or add a seed template.</div>`;
    return;
  }
  normalizeTemplateForUi(template);
  editor.innerHTML = `
    <div class="card-header">
      <div class="card-title">
        <h3>${escapeHtml(template.ticker)} - ${escapeHtml(template.name)}</h3>
        <span class="chip">${escapeHtml(template.sector_id)}</span>
      </div>
      <button id="deleteTemplate" class="small danger">Delete Template</button>
    </div>
    <div class="row">
      ${textField("ID", template.id, "id")}
      ${textField("Ticker", template.ticker, "ticker")}
    </div>
    <div class="row">
      ${textField("Name", template.name, "name")}
      ${textField("Sector ID", template.sector_id, "sector_id")}
    </div>
    ${textAreaField("Narrative Tags", arrayToLines(template.narrative_tags), "narrative_tags", 5)}
    <div class="grid two">
      ${ANCHOR_FIELDS.map((field) => numberField(anchorLabel(field), template.anchors[field], `anchor_${field}`, field === "quality" || field === "growth" || field === "risk" ? "1" : "0.01")).join("")}
    </div>
  `;
  bindObjectInputs(editor, template, ["narrative_tags"]);
  editor.querySelector("[data-field='id']").addEventListener("change", (event) => {
    const oldId = template.id;
    const newId = slugify(event.target.value);
    if (!newId || newId === oldId) return;
    if (src.archetype_templates.some((row) => row !== template && row.id === newId)) {
      setStatus(`Template id already exists: ${newId}`, "error");
      event.target.value = oldId;
      return;
    }
    template.id = newId;
    state.templateId = newId;
    markDirty();
    render();
  });
  editor.querySelector("[data-field='ticker']").addEventListener("change", (event) => {
    template.ticker = normalizeTicker(event.target.value);
    markDirty();
    render();
  });
  for (const field of ANCHOR_FIELDS) {
    editor.querySelector(`[data-field='anchor_${field}']`).addEventListener("input", (event) => {
      template.anchors[field] = Number(event.target.value || 0);
      markDirty();
    });
  }
  document.getElementById("deleteTemplate").addEventListener("click", () => {
    if (!confirm("Delete this seed template?")) return;
    const index = src.archetype_templates.indexOf(template);
    if (index >= 0) src.archetype_templates.splice(index, 1);
    state.templateId = "";
    markDirty();
    render();
  });
}

function renderWords() {
  const words = source().word_data.unique_words;
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Name Words</h2>
        <p>Generated company names sample from this unique word pool. Export rewrites total_count from the line count.</p>
      </div>
    </div>
    <div class="card">
      <div class="card-header">
        <h3>Word Pool</h3>
        <span class="chip">${words.length} words</span>
      </div>
      ${textAreaField("Unique Words", arrayToLines(words), "unique_words", 28)}
    </div>
    ${validationPanel()}
  `;
  document.querySelector("[data-field='unique_words']").addEventListener("input", (event) => {
    source().word_data.unique_words = linesToArray(event.target.value);
    source().word_data.total_count = source().word_data.unique_words.length;
    markDirty();
  });
}

function renderProfileCopy() {
  const data = profileData();
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Profile Copy</h2>
        <p>Core metadata and global sentence pools used by CompanyNarrativeGenerator.</p>
      </div>
    </div>
    <div class="grid two">
      <div class="card">
        <h3>Metadata</h3>
        ${textField("Version", data._meta.version, "version")}
        ${textAreaField("Description", data._meta.description, "description", 4)}
        ${numberField("Reference Year", data.reference_year, "reference_year")}
        ${numberField("Optional Third Sentence Probability", data.sentence_settings.optional_third_sentence_probability, "optional_probability", "0.01")}
      </div>
      <div class="card">
        ${textAreaField("Primary Sentence Templates", arrayToLines(data.sentence_templates.primary_pool), "primary_pool", 12)}
      </div>
    </div>
    <div class="card" style="margin-top: 14px;">
      ${textAreaField("Global Differentiator Pool", arrayToLines(data.global_differentiator_pool), "global_differentiator_pool", 10)}
    </div>
    ${validationPanel()}
  `;
  document.querySelector("[data-field='version']").addEventListener("input", (event) => { data._meta.version = event.target.value; markDirty(); });
  document.querySelector("[data-field='description']").addEventListener("input", (event) => { data._meta.description = event.target.value; markDirty(); });
  document.querySelector("[data-field='reference_year']").addEventListener("input", (event) => { data.reference_year = Number(event.target.value || 0); markDirty(); });
  document.querySelector("[data-field='optional_probability']").addEventListener("input", (event) => { data.sentence_settings.optional_third_sentence_probability = Number(event.target.value || 0); markDirty(); });
  document.querySelector("[data-field='primary_pool']").addEventListener("input", (event) => { data.sentence_templates.primary_pool = linesToArray(event.target.value); markDirty(); });
  document.querySelector("[data-field='global_differentiator_pool']").addEventListener("input", (event) => { data.global_differentiator_pool = linesToArray(event.target.value); markDirty(); });
}

function renderArchetypes() {
  const data = profileData();
  const archetype = data.archetypes[state.archetypeId];
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Archetypes</h2>
        <p>Profile archetypes drive age, size selection, profile tags, descriptors, verbs, and differentiator lines.</p>
      </div>
      <button id="addArchetype">Add Archetype</button>
    </div>
    <div class="pool-grid">
      <div class="key-list" id="archetypeKeys"></div>
      <div class="card" id="archetypeEditor"></div>
    </div>
    ${validationPanel()}
  `;
  renderKeyButtons("archetypeKeys", Object.keys(data.archetypes), state.archetypeId, (key) => {
    state.archetypeId = key;
    render();
  }, (key) => data.archetypes[key]?.label || "");
  renderArchetypeEditor(archetype);
  document.getElementById("addArchetype").addEventListener("click", () => {
    const id = uniqueId("new_archetype", Object.keys(data.archetypes));
    data.archetypes[id] = {
      label: "New Archetype",
      tone: "neutral",
      age_range: [5, 30],
      allowed_sizes: [1, 2],
      size_weights: { "1": 1, "2": 1 },
      descriptor_pool: ["focused"],
      verb_pool: ["operates in"],
      differentiator_pool: ["The company is still building a clearer operating identity"],
      tag_pool: ["focused"]
    };
    for (const sectorId of Object.keys(data.archetype_weights_by_sector)) data.archetype_weights_by_sector[sectorId][id] = 1;
    state.archetypeId = id;
    markDirty();
    render();
  });
}

function renderArchetypeEditor(archetype) {
  const editor = document.getElementById("archetypeEditor");
  const data = profileData();
  if (!archetype) {
    editor.innerHTML = `<div class="empty">Choose or add an archetype.</div>`;
    return;
  }
  normalizeArchetypeForUi(archetype);
  editor.innerHTML = `
    <div class="card-header">
      <div class="card-title">
        <h3>${escapeHtml(archetype.label)}</h3>
        <span class="chip">${escapeHtml(state.archetypeId)}</span>
      </div>
      <button id="deleteArchetype" class="small danger">Delete Archetype</button>
    </div>
    <div class="row">
      ${textField("Label", archetype.label, "label")}
      ${textField("Tone", archetype.tone, "tone")}
    </div>
    <div class="row">
      ${textAreaField("Age Range", rangeToLines(archetype.age_range), "age_range", 3)}
      ${textAreaField("Allowed Sizes", arrayToLines(archetype.allowed_sizes), "allowed_sizes", 3)}
    </div>
    ${textAreaField("Size Weights JSON", JSON.stringify(archetype.size_weights, null, 2), "size_weights", 7)}
    <div class="grid two">
      ${ARCHETYPE_POOLS.map((field) => textAreaField(labelize(field), arrayToLines(archetype[field]), field, 8)).join("")}
    </div>
  `;
  bindObjectInputs(editor, archetype, ARCHETYPE_POOLS);
  editor.querySelector("[data-field='age_range']").addEventListener("input", (event) => { archetype.age_range = linesToNumberRange(event.target.value, true); markDirty(); });
  editor.querySelector("[data-field='allowed_sizes']").addEventListener("input", (event) => { archetype.allowed_sizes = linesToArray(event.target.value).map((row) => Number(row || 0)); markDirty(); });
  editor.querySelector("[data-field='size_weights']").addEventListener("change", (event) => {
    try {
      archetype.size_weights = JSON.parse(event.target.value);
      markDirty();
      setStatus("Size weights JSON applied.", "ok");
    } catch (error) {
      setStatus(`Invalid size weights JSON: ${error.message}`, "error");
    }
  });
  document.getElementById("deleteArchetype").addEventListener("click", () => {
    if (!confirm("Delete this archetype? Sector weight validation will require cleanup.")) return;
    delete data.archetypes[state.archetypeId];
    for (const sectorId of Object.keys(data.archetype_weights_by_sector)) delete data.archetype_weights_by_sector[sectorId][state.archetypeId];
    state.archetypeId = "";
    markDirty();
    render();
  });
}

function renderSectors() {
  const data = profileData();
  const sector = data.sectors[state.sectorId];
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Sectors</h2>
        <p>Sector pools provide business scope lines, differentiators, and profile tags.</p>
      </div>
      <button id="addSector">Add Sector</button>
    </div>
    <div class="pool-grid">
      <div class="key-list" id="sectorKeys"></div>
      <div class="card" id="sectorEditor"></div>
    </div>
    ${validationPanel()}
  `;
  renderKeyButtons("sectorKeys", Object.keys(data.sectors), state.sectorId, (key) => {
    state.sectorId = key;
    render();
  }, (key) => `${(data.sectors[key]?.business_pool || []).length} business`);
  renderSectorEditor(sector);
  document.getElementById("addSector").addEventListener("click", () => {
    const id = uniqueId("new_sector", Object.keys(data.sectors));
    data.sectors[id] = {
      business_pool: ["new sector business activity"],
      scope_pool: ["The company operates across a focused customer base."],
      differentiator_pool: ["Execution quality remains central to the story."],
      tag_pool: ["new-sector"]
    };
    data.archetype_weights_by_sector[id] = Object.fromEntries(Object.keys(data.archetypes).map((key) => [key, 1]));
    state.sectorId = id;
    state.weightSectorId = id;
    markDirty();
    render();
  });
}

function renderSectorEditor(sector) {
  const editor = document.getElementById("sectorEditor");
  const data = profileData();
  if (!sector) {
    editor.innerHTML = `<div class="empty">Choose or add a sector.</div>`;
    return;
  }
  normalizeSectorForUi(sector);
  editor.innerHTML = `
    <div class="card-header">
      <div class="card-title">
        <h3>${escapeHtml(state.sectorId)}</h3>
        <span class="chip">${(sector.tag_pool || []).length} tags</span>
      </div>
      <button id="deleteSector" class="small danger">Delete Sector</button>
    </div>
    <div class="grid two">
      ${SECTOR_POOLS.map((field) => textAreaField(labelize(field), arrayToLines(sector[field]), field, field === "scope_pool" ? 12 : 8)).join("")}
    </div>
  `;
  bindObjectInputs(editor, sector, SECTOR_POOLS);
  document.getElementById("deleteSector").addEventListener("click", () => {
    if (!confirm("Delete this sector? Runtime sector definitions may still require it.")) return;
    delete data.sectors[state.sectorId];
    delete data.archetype_weights_by_sector[state.sectorId];
    state.sectorId = "";
    markDirty();
    render();
  });
}

function renderSizes() {
  const data = profileData();
  const size = data.sizes[state.sizeId];
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Sizes</h2>
        <p>Size buckets influence employee count, revenue fit, descriptors, and generated profile tags.</p>
      </div>
      <button id="addSize">Add Size</button>
    </div>
    <div class="pool-grid">
      <div class="key-list" id="sizeKeys"></div>
      <div class="card" id="sizeEditor"></div>
    </div>
    ${validationPanel()}
  `;
  const sizeIds = Object.keys(data.sizes).sort((a, b) => Number(a) - Number(b));
  renderKeyButtons("sizeKeys", sizeIds, state.sizeId, (key) => {
    state.sizeId = key;
    render();
  }, (key) => data.sizes[key]?.label || "");
  renderSizeEditor(size);
  document.getElementById("addSize").addEventListener("click", () => {
    const nextId = String(Math.max(-1, ...Object.keys(data.sizes).map((key) => Number(key))) + 1);
    data.sizes[nextId] = {
      label: "New Size",
      employee_range: [100, 500],
      revenue_hint_range: [0, 1000000000],
      descriptor_pool: ["new"],
      tag_pool: ["new-size"]
    };
    state.sizeId = nextId;
    markDirty();
    render();
  });
}

function renderSizeEditor(size) {
  const editor = document.getElementById("sizeEditor");
  const data = profileData();
  if (!size) {
    editor.innerHTML = `<div class="empty">Choose or add a size bucket.</div>`;
    return;
  }
  normalizeSizeForUi(size);
  editor.innerHTML = `
    <div class="card-header">
      <div class="card-title">
        <h3>${escapeHtml(size.label)}</h3>
        <span class="chip">size ${escapeHtml(state.sizeId)}</span>
      </div>
      <button id="deleteSize" class="small danger">Delete Size</button>
    </div>
    ${textField("Label", size.label, "label")}
    <div class="row">
      ${textAreaField("Employee Range", rangeToLines(size.employee_range), "employee_range", 3)}
      ${textAreaField("Revenue Hint Range", rangeToLines(size.revenue_hint_range), "revenue_hint_range", 3)}
    </div>
    <div class="grid two">
      ${SIZE_POOLS.map((field) => textAreaField(labelize(field), arrayToLines(size[field]), field, 8)).join("")}
    </div>
  `;
  bindObjectInputs(editor, size, SIZE_POOLS);
  editor.querySelector("[data-field='employee_range']").addEventListener("input", (event) => { size.employee_range = linesToNumberRange(event.target.value, true); markDirty(); });
  editor.querySelector("[data-field='revenue_hint_range']").addEventListener("input", (event) => { size.revenue_hint_range = linesToNumberRange(event.target.value, false); markDirty(); });
  document.getElementById("deleteSize").addEventListener("click", () => {
    if (!confirm("Delete this size? Archetype allowed size lists may need cleanup.")) return;
    delete data.sizes[state.sizeId];
    state.sizeId = "";
    markDirty();
    render();
  });
}

function renderNarrativeTags() {
  const data = profileData();
  const pool = data.narrative_tag_sentences[state.tagId] || [];
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Narrative Tags</h2>
        <p>These optional third-sentence pools are selected from seeded template tags and generated sector tags.</p>
      </div>
      <button id="addTag">Add Tag</button>
    </div>
    <div class="pool-grid">
      <div class="key-list" id="tagKeys"></div>
      <div class="card" id="tagEditor"></div>
    </div>
    ${validationPanel()}
  `;
  renderKeyButtons("tagKeys", Object.keys(data.narrative_tag_sentences), state.tagId, (key) => {
    state.tagId = key;
    render();
  }, (key) => `${(data.narrative_tag_sentences[key] || []).length} lines`);
  const editor = document.getElementById("tagEditor");
  if (!state.tagId) {
    editor.innerHTML = `<div class="empty">Choose or add a narrative tag.</div>`;
  } else {
    editor.innerHTML = `
      <div class="card-header">
        <div class="card-title">
          <h3>${escapeHtml(state.tagId)}</h3>
          <span class="chip">${KNOWN_TAGS.includes(state.tagId) ? "generator tag" : "custom tag"}</span>
        </div>
        <button id="deleteTag" class="small danger">Delete Tag</button>
      </div>
      ${textAreaField("Sentence Pool", arrayToLines(pool), "tag_pool", 12)}
    `;
    editor.querySelector("[data-field='tag_pool']").addEventListener("input", (event) => {
      data.narrative_tag_sentences[state.tagId] = linesToArray(event.target.value);
      markDirty();
    });
    document.getElementById("deleteTag").addEventListener("click", () => {
      if (!confirm("Delete this narrative tag sentence pool? Generator tags are required by validation.")) return;
      delete data.narrative_tag_sentences[state.tagId];
      state.tagId = "";
      markDirty();
      render();
    });
  }
  document.getElementById("addTag").addEventListener("click", () => {
    const id = uniqueId("new_tag", Object.keys(data.narrative_tag_sentences));
    data.narrative_tag_sentences[id] = ["The name has a distinct narrative angle that can shape how investors read the setup."];
    state.tagId = id;
    markDirty();
    render();
  });
}

function renderWeights() {
  const data = profileData();
  const archetypeIds = Object.keys(data.archetypes);
  const sectorIds = Object.keys(data.sectors);
  const weights = data.archetype_weights_by_sector[state.weightSectorId] || {};
  data.archetype_weights_by_sector[state.weightSectorId] = weights;
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Weights</h2>
        <p>Sector weights control which profile archetype gets picked for generated companies in each sector.</p>
      </div>
    </div>
    <div class="pool-grid">
      <div class="key-list" id="weightSectorKeys"></div>
      <div class="card" id="weightEditor"></div>
    </div>
    ${validationPanel()}
  `;
  renderKeyButtons("weightSectorKeys", sectorIds, state.weightSectorId, (key) => {
    state.weightSectorId = key;
    render();
  }, (key) => `${Object.keys(data.archetype_weights_by_sector[key] || {}).length} weights`);
  const editor = document.getElementById("weightEditor");
  if (!state.weightSectorId) {
    editor.innerHTML = `<div class="empty">Choose a sector.</div>`;
    return;
  }
  editor.innerHTML = `
    <div class="card-header">
      <h3>${escapeHtml(state.weightSectorId)}</h3>
      <button id="fillMissingWeights" class="small">Fill Missing</button>
    </div>
    <div class="grid two">
      ${archetypeIds.map((id) => numberField(data.archetypes[id]?.label || id, weights[id] ?? 1, `weight_${id}`, "0.01")).join("")}
    </div>
  `;
  for (const id of archetypeIds) {
    editor.querySelector(`[data-field='weight_${id}']`).addEventListener("input", (event) => {
      weights[id] = Number(event.target.value || 0);
      markDirty();
    });
  }
  document.getElementById("fillMissingWeights").addEventListener("click", () => {
    for (const id of archetypeIds) if (!weights[id]) weights[id] = 1;
    markDirty();
    render();
  });
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

function bindObjectInputs(container, object, arrayFields = []) {
  container.querySelectorAll("[data-field]").forEach((element) => {
    const field = element.dataset.field;
    if (field === "id" || field === "ticker" || field.startsWith("anchor_") || field.endsWith("_range") || field === "allowed_sizes" || field === "size_weights") return;
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

function labelize(value) {
  return String(value || "").replace(/_/g, " ").replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function anchorLabel(value) {
  return labelize(value);
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
