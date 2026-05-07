const state = {
  source: { schema_version: 1, catalog: {} },
  activeView: "overview",
  dirty: false,
  validation: null,
  contactId: "",
  contactQuery: "",
  meetingProfileId: "",
  templateGroup: "tip_templates",
  rawMode: false
};

const viewEl = document.getElementById("view");
const statusEl = document.getElementById("status");

const TONES = ["positive", "negative", "mixed"];
const AFFILIATION_TYPES = ["floater", "insider_template"];
const INSIDER_ROLES = ["ceo", "cfo", "commissioner"];
const MEETING_STAGES = ["seating", "host_intro", "agenda_reveal", "vote"];
const TEMPLATE_GROUPS = ["tip_templates", "request_templates"];

function catalog() {
  if (!state.source.catalog || typeof state.source.catalog !== "object") {
    state.source.catalog = {};
  }
  return state.source.catalog;
}

function ensureCatalogDefaults() {
  const data = catalog();
  data.base_contact_cap = Number(data.base_contact_cap || 2);
  data.relationship_default = Number(data.relationship_default || 25);
  data.person_name_pools = isObject(data.person_name_pools) ? data.person_name_pools : {};
  data.person_name_pools.first_names = Array.isArray(data.person_name_pools.first_names) ? data.person_name_pools.first_names : [];
  data.person_name_pools.family_names = Array.isArray(data.person_name_pools.family_names) ? data.person_name_pools.family_names : [];
  data.meeting_lead_profiles = Array.isArray(data.meeting_lead_profiles) ? data.meeting_lead_profiles : [];
  data.contacts = Array.isArray(data.contacts) ? data.contacts : [];
  data.tip_templates = isObject(data.tip_templates) ? data.tip_templates : {};
  data.request_templates = isObject(data.request_templates) ? data.request_templates : {};
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
    setStatus("Loaded editable Network source.", "ok");
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
  const contactIds = data.contacts.map((row) => row.id);
  if (!contactIds.includes(state.contactId)) state.contactId = contactIds[0] || "";
  const profileIds = data.meeting_lead_profiles.map((row) => row.id);
  if (!profileIds.includes(state.meetingProfileId)) state.meetingProfileId = profileIds[0] || "";
  if (!TEMPLATE_GROUPS.includes(state.templateGroup)) state.templateGroup = TEMPLATE_GROUPS[0];
}

function render() {
  ensureCatalogDefaults();
  reconcileSelections();
  document.querySelectorAll(".nav").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === state.activeView);
  });
  if (state.activeView === "overview") renderOverview();
  if (state.activeView === "contacts") renderContacts();
  if (state.activeView === "meetingLeads") renderMeetingLeads();
  if (state.activeView === "templates") renderTemplates();
  if (state.activeView === "raw") renderRaw();
}

function renderOverview() {
  const data = catalog();
  const floaterCount = data.contacts.filter((row) => row.affiliation_type === "floater").length;
  const insiderCount = data.contacts.filter((row) => row.affiliation_type === "insider_template").length;
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Overview</h2>
        <p>Edit Network defaults and generated insider name pools. Contacts and meeting lead copy are runtime content, not save-game state.</p>
      </div>
    </div>
    <div class="grid two">
      <div class="card">
        <h3>Runtime Defaults</h3>
        ${numberField("Base Contact Cap", data.base_contact_cap, "base_contact_cap")}
        ${numberField("Default Relationship", data.relationship_default, "relationship_default")}
      </div>
      <div class="card">
        <h3>Catalog Counts</h3>
        <p><span class="chip">${data.contacts.length} contacts</span></p>
        <p><span class="chip">${floaterCount} floaters</span></p>
        <p><span class="chip">${insiderCount} insider templates</span></p>
        <p><span class="chip">${data.meeting_lead_profiles.length} meeting lead profiles</span></p>
      </div>
    </div>
    <div class="grid two" style="margin-top: 14px;">
      <div class="card">
        ${textAreaField("Generated First Names", arrayToLines(data.person_name_pools.first_names), "first_names", 16)}
      </div>
      <div class="card">
        ${textAreaField("Generated Family Names", arrayToLines(data.person_name_pools.family_names), "family_names", 16)}
      </div>
    </div>
    ${validationPanel()}
  `;
  bindNumber("base_contact_cap", (value) => data.base_contact_cap = value);
  bindNumber("relationship_default", (value) => data.relationship_default = value);
  document.querySelector("[data-field='first_names']").addEventListener("input", (event) => {
    data.person_name_pools.first_names = linesToArray(event.target.value);
    markDirty();
  });
  document.querySelector("[data-field='family_names']").addEventListener("input", (event) => {
    data.person_name_pools.family_names = linesToArray(event.target.value);
    markDirty();
  });
}

function renderContacts() {
  const data = catalog();
  const filtered = data.contacts.filter((contact) => {
    const query = state.contactQuery.toLowerCase();
    if (!query) return true;
    return [contact.id, contact.display_name, contact.role, contact.affiliation_type, contact.affiliation_role, ...(contact.sector_ids || []), ...(contact.categories || [])]
      .join(" ")
      .toLowerCase()
      .includes(query);
  });
  if (!filtered.some((row) => row.id === state.contactId) && filtered[0]) {
    state.contactId = filtered[0].id;
  }
  const contact = data.contacts.find((row) => row.id === state.contactId);
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Contacts</h2>
        <p>Authored contacts include floaters and insider templates. Generated per-company insiders are created from insider templates at runtime.</p>
      </div>
      <button id="addContact">Add Contact</button>
    </div>
    <div class="toolbar">
      <input id="contactSearch" value="${escapeHtml(state.contactQuery)}" placeholder="Search contacts, sectors, categories...">
    </div>
    <div class="pool-grid">
      <div class="key-list" id="contactKeys"></div>
      <div class="card" id="contactEditor"></div>
    </div>
  `;
  document.getElementById("contactSearch").addEventListener("input", (event) => {
    state.contactQuery = event.target.value;
    render();
  });
  renderKeyButtons("contactKeys", filtered.map((row) => row.id), state.contactId, (key) => {
    state.contactId = key;
    render();
  }, (key) => {
    const row = data.contacts.find((item) => item.id === key) || {};
    return row.affiliation_type === "insider_template" ? row.affiliation_role || "insider" : "floater";
  });
  renderContactEditor(contact);
  document.getElementById("addContact").addEventListener("click", () => {
    const id = uniqueId("new_contact", data.contacts.map((row) => row.id));
    data.contacts.push({
      id,
      display_name: "New Contact",
      role: "Market Contact",
      sector_ids: [],
      categories: [],
      recognition_required: 0,
      base_relationship: data.relationship_default || 25,
      reliability: 0.5,
      tone: "mixed",
      intro: "",
      affiliation_type: "floater"
    });
    state.contactId = id;
    markDirty();
    render();
  });
}

function renderContactEditor(contact) {
  const editor = document.getElementById("contactEditor");
  const data = catalog();
  if (!contact) {
    editor.innerHTML = `<div class="empty">Choose or add a contact.</div>`;
    return;
  }
  editor.innerHTML = `
    <div class="card-header">
      <div class="card-title">
        <h3>${escapeHtml(contact.display_name || contact.id)}</h3>
        <span class="chip">${escapeHtml(contact.role || "Contact")}</span>
      </div>
      <button id="deleteContact" class="small danger">Delete Contact</button>
    </div>
    <div class="row">
      ${textField("ID", contact.id, "id")}
      ${textField("Display Name", contact.display_name, "display_name")}
    </div>
    ${textField("Role", contact.role, "role")}
    <div class="row">
      ${selectField("Affiliation Type", contact.affiliation_type, "affiliation_type", AFFILIATION_TYPES)}
      ${selectField("Affiliation Role", contact.affiliation_role || "", "affiliation_role", ["", ...INSIDER_ROLES])}
    </div>
    <div class="row">
      ${numberField("Recognition Required", contact.recognition_required, "recognition_required")}
      ${numberField("Base Relationship", contact.base_relationship, "base_relationship")}
    </div>
    <div class="row">
      ${numberField("Reliability", contact.reliability, "reliability", "0.01")}
      ${selectField("Tone", contact.tone, "tone", ["positive", "negative", "mixed"])}
    </div>
    <div class="row">
      ${textAreaField("Sector IDs", arrayToLines(contact.sector_ids), "sector_ids", 7)}
      ${textAreaField("Categories", arrayToLines(contact.categories), "categories", 7)}
    </div>
    ${textAreaField("Intro", contact.intro, "intro", 8)}
  `;
  bindObjectInputs(editor, contact, ["sector_ids", "categories"]);
  editor.querySelector("[data-field='id']").addEventListener("change", (event) => {
    const oldId = contact.id;
    const newId = slugify(event.target.value);
    if (!newId || newId === oldId) return;
    if (data.contacts.some((row) => row !== contact && row.id === newId)) {
      setStatus(`Contact id already exists: ${newId}`, "error");
      event.target.value = oldId;
      return;
    }
    contact.id = newId;
    state.contactId = newId;
    markDirty();
    render();
  });
  editor.querySelector("[data-field='affiliation_type']").addEventListener("change", () => {
    if (contact.affiliation_type === "insider_template" && !contact.affiliation_role) {
      contact.affiliation_role = "ceo";
    }
    if (contact.affiliation_type !== "insider_template") {
      delete contact.affiliation_role;
    }
    markDirty();
    render();
  });
  document.getElementById("deleteContact").addEventListener("click", () => {
    if (!confirm("Delete this contact?")) return;
    const index = data.contacts.indexOf(contact);
    if (index >= 0) data.contacts.splice(index, 1);
    state.contactId = "";
    markDirty();
    render();
  });
}

function renderMeetingLeads() {
  const data = catalog();
  const profiles = data.meeting_lead_profiles;
  const profile = profiles.find((row) => row.id === state.meetingProfileId);
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Meeting Leads</h2>
        <p>Reusable RUPSLB room lead profiles. Stage bubbles must exist for seating, host intro, agenda reveal, and vote.</p>
      </div>
      <button id="addMeetingProfile">Add Profile</button>
    </div>
    <div class="pool-grid">
      <div class="key-list" id="profileKeys"></div>
      <div class="card" id="profileEditor"></div>
    </div>
  `;
  renderKeyButtons("profileKeys", profiles.map((row) => row.id), state.meetingProfileId, (key) => {
    state.meetingProfileId = key;
    render();
  }, (key) => {
    const row = profiles.find((item) => item.id === key) || {};
    return row.tier || "";
  });
  renderMeetingProfileEditor(profile);
  document.getElementById("addMeetingProfile").addEventListener("click", () => {
    const id = uniqueId("new_meeting_lead", profiles.map((row) => row.id));
    profiles.push({
      id,
      tier: "open",
      role_label: "Meeting Lead",
      recognition_required: 0,
      sector_match_required: false,
      category_ids: ["corporate_meeting"],
      speech_bubbles: ["{ticker} room chatter is worth hearing."],
      stage_speech_bubbles: Object.fromEntries(MEETING_STAGES.map((stage) => [stage, [`${stage} note for {ticker}.`]])),
      approach_prompt: "Ask about {agenda} on {ticker}.",
      success_responses: ["{contact} gives you a read on {ticker}."],
      locked_copy: "This attendee is not ready to talk yet."
    });
    state.meetingProfileId = id;
    markDirty();
    render();
  });
}

function renderMeetingProfileEditor(profile) {
  const editor = document.getElementById("profileEditor");
  const data = catalog();
  if (!profile) {
    editor.innerHTML = `<div class="empty">Choose or add a meeting lead profile.</div>`;
    return;
  }
  if (!isObject(profile.stage_speech_bubbles)) profile.stage_speech_bubbles = {};
  for (const stage of MEETING_STAGES) {
    profile.stage_speech_bubbles[stage] = Array.isArray(profile.stage_speech_bubbles[stage]) ? profile.stage_speech_bubbles[stage] : [];
  }
  editor.innerHTML = `
    <div class="card-header">
      <div class="card-title">
        <h3>${escapeHtml(profile.role_label || profile.id)}</h3>
        <span class="chip">${escapeHtml(profile.tier || "tier")}</span>
      </div>
      <button id="deleteMeetingProfile" class="small danger">Delete Profile</button>
    </div>
    <div class="row">
      ${textField("ID", profile.id, "id")}
      ${textField("Role Label", profile.role_label, "role_label")}
    </div>
    <div class="row">
      ${textField("Tier", profile.tier, "tier")}
      ${numberField("Recognition Required", profile.recognition_required, "recognition_required")}
    </div>
    <div class="toolbar">
      <label><input type="checkbox" data-check="sector_match_required" ${profile.sector_match_required ? "checked" : ""}> Sector match required</label>
    </div>
    ${textAreaField("Category IDs", arrayToLines(profile.category_ids), "category_ids", 5)}
    ${textAreaField("Speech Bubbles", arrayToLines(profile.speech_bubbles), "speech_bubbles", 5)}
    <div class="grid two">
      ${MEETING_STAGES.map((stage) => textAreaField(`Stage: ${stage}`, arrayToLines(profile.stage_speech_bubbles[stage]), `stage_${stage}`, 5)).join("")}
    </div>
    ${textAreaField("Approach Prompt", profile.approach_prompt, "approach_prompt", 3)}
    ${textAreaField("Success Responses", arrayToLines(profile.success_responses), "success_responses", 5)}
    ${textAreaField("Locked Copy", profile.locked_copy, "locked_copy", 3)}
  `;
  bindObjectInputs(editor, profile, ["category_ids", "speech_bubbles", "success_responses"]);
  for (const stage of MEETING_STAGES) {
    editor.querySelector(`[data-field='stage_${stage}']`).addEventListener("input", (event) => {
      profile.stage_speech_bubbles[stage] = linesToArray(event.target.value);
      markDirty();
    });
  }
  editor.querySelector("[data-check='sector_match_required']").addEventListener("change", (event) => {
    profile.sector_match_required = event.target.checked;
    markDirty();
  });
  editor.querySelector("[data-field='id']").addEventListener("change", (event) => {
    const oldId = profile.id;
    const newId = slugify(event.target.value);
    if (!newId || newId === oldId) return;
    if (data.meeting_lead_profiles.some((row) => row !== profile && row.id === newId)) {
      setStatus(`Meeting profile id already exists: ${newId}`, "error");
      event.target.value = oldId;
      return;
    }
    profile.id = newId;
    state.meetingProfileId = newId;
    markDirty();
    render();
  });
  document.getElementById("deleteMeetingProfile").addEventListener("click", () => {
    if (!confirm("Delete this meeting lead profile?")) return;
    const index = data.meeting_lead_profiles.indexOf(profile);
    if (index >= 0) data.meeting_lead_profiles.splice(index, 1);
    state.meetingProfileId = "";
    markDirty();
    render();
  });
}

function renderTemplates() {
  const data = catalog();
  const isTip = state.templateGroup === "tip_templates";
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Tip / Request Templates</h2>
        <p>Tip templates are pools by tone. Request templates are single lines by tone.</p>
      </div>
    </div>
    <div class="toolbar">
      <label>Template Group</label>
      <select id="templateGroup">${TEMPLATE_GROUPS.map((group) => option(group, group, state.templateGroup)).join("")}</select>
    </div>
    <div class="grid" id="templateRows"></div>
  `;
  document.getElementById("templateGroup").addEventListener("change", (event) => {
    state.templateGroup = event.target.value;
    render();
  });
  const rows = document.getElementById("templateRows");
  rows.innerHTML = TONES.map((tone) => `
    <div class="card">
      <h3>${escapeHtml(tone)}</h3>
      ${textAreaField(isTip ? "Template Pool" : "Request Template", isTip ? arrayToLines(data.tip_templates[tone]) : data.request_templates[tone], tone, isTip ? 8 : 4)}
    </div>
  `).join("");
  for (const tone of TONES) {
    rows.querySelector(`[data-field='${tone}']`).addEventListener("input", (event) => {
      if (isTip) {
        data.tip_templates[tone] = linesToArray(event.target.value);
      } else {
        data.request_templates[tone] = event.target.value;
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
  return `
    <div class="field">
      <label>${escapeHtml(label)}</label>
      <select data-field="${escapeHtml(field)}">
        ${options.map((row) => option(row, row, value)).join("")}
      </select>
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
