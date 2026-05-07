const state = {
  source: { schema_version: 1, catalog: {} },
  activeView: "overview",
  dirty: false,
  validation: null,
  voiceId: "",
  voiceKey: "",
  threadVoiceId: "",
  threadKey: "",
  fallbackGroup: "fallback_templates",
  fallbackKey: ""
};

const viewEl = document.getElementById("view");
const statusEl = document.getElementById("status");

const FALLBACK_GROUPS = ["continuity_templates", "fallback_templates", "fallback_posts"];

function catalog() {
  if (!state.source.catalog || typeof state.source.catalog !== "object") {
    state.source.catalog = {};
  }
  return state.source.catalog;
}

function ensureCatalogDefaults() {
  const data = catalog();
  data.prototype_default_access_tier = Number(data.prototype_default_access_tier || 1);
  data.post_limit = Number(data.post_limit || 18);
  data.tier_labels = isObject(data.tier_labels) ? data.tier_labels : {};
  data.accounts = Array.isArray(data.accounts) ? data.accounts : [];
  data.voice_templates = isObject(data.voice_templates) ? data.voice_templates : {};
  data.thread_templates = isObject(data.thread_templates) ? data.thread_templates : {};
  data.continuity_templates = isObject(data.continuity_templates) ? data.continuity_templates : {};
  data.fallback_templates = isObject(data.fallback_templates) ? data.fallback_templates : {};
  data.fallback_posts = isObject(data.fallback_posts) ? data.fallback_posts : {};
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
    setStatus("Loaded editable Twooter source.", "ok");
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
  const voiceIds = Object.keys(data.voice_templates || {});
  if (!voiceIds.includes(state.voiceId)) state.voiceId = voiceIds[0] || "";
  const voiceKeys = Object.keys(data.voice_templates?.[state.voiceId] || {});
  if (!voiceKeys.includes(state.voiceKey)) state.voiceKey = voiceKeys[0] || "";
  const threadVoiceIds = Object.keys(data.thread_templates || {});
  if (!threadVoiceIds.includes(state.threadVoiceId)) state.threadVoiceId = threadVoiceIds[0] || "";
  const threadKeys = Object.keys(data.thread_templates?.[state.threadVoiceId] || {});
  if (!threadKeys.includes(state.threadKey)) state.threadKey = threadKeys[0] || "";
  if (!FALLBACK_GROUPS.includes(state.fallbackGroup)) state.fallbackGroup = FALLBACK_GROUPS[0];
  const fallbackKeys = Object.keys(data[state.fallbackGroup] || {});
  if (!fallbackKeys.includes(state.fallbackKey)) state.fallbackKey = fallbackKeys[0] || "";
}

function render() {
  ensureCatalogDefaults();
  reconcileSelections();
  document.querySelectorAll(".nav").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === state.activeView);
  });
  if (state.activeView === "overview") renderOverview();
  if (state.activeView === "accounts") renderAccounts();
  if (state.activeView === "voices") renderNestedTemplateEditor("voice");
  if (state.activeView === "threads") renderNestedTemplateEditor("thread");
  if (state.activeView === "fallbacks") renderFallbacks();
  if (state.activeView === "raw") renderRaw();
}

function renderOverview() {
  const data = catalog();
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Overview</h2>
        <p>Edit runtime-wide Twooter settings and access tier labels. Runtime posts are still generated in Godot from market/event state plus these template pools.</p>
      </div>
    </div>
    <div class="grid two">
      <div class="card">
        <h3>Runtime Settings</h3>
        ${numberField("Default Access Tier", data.prototype_default_access_tier, "prototype_default_access_tier")}
        ${numberField("Post Limit", data.post_limit, "post_limit")}
      </div>
      <div class="card">
        <h3>Catalog Counts</h3>
        <p><span class="chip">${data.accounts.length} accounts</span></p>
        <p><span class="chip">${Object.keys(data.voice_templates).length} voices</span></p>
        <p><span class="chip">${Object.keys(data.thread_templates).length} thread voices</span></p>
        <p><span class="chip">${Object.keys(data.fallback_templates).length} fallback pools</span></p>
      </div>
    </div>
    <div class="card" style="margin-top: 14px;">
      <div class="card-header">
        <h3>Tier Labels</h3>
        <button id="addTierLabel" class="small">Add Label</button>
      </div>
      <div id="tierRows" class="grid"></div>
    </div>
    ${validationPanel()}
  `;
  bindNumber("prototype_default_access_tier", (value) => data.prototype_default_access_tier = value);
  bindNumber("post_limit", (value) => data.post_limit = value);
  renderKeyValueRows("tierRows", data.tier_labels, "Tier", "Label");
  document.getElementById("addTierLabel").addEventListener("click", () => {
    const key = prompt("Tier id");
    if (!key) return;
    data.tier_labels[String(key).trim()] = "New Tier";
    markDirty();
    render();
  });
}

function renderAccounts() {
  const data = catalog();
  const voiceOptions = Object.keys(data.voice_templates);
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Accounts</h2>
        <p>Accounts are unlocked by Twooter Content tier. Persona accounts should keep their person_id, while regular accounts should leave it blank.</p>
      </div>
      <button id="addAccount">Add Account</button>
    </div>
    <div class="grid" id="accountCards"></div>
  `;
  const cards = document.getElementById("accountCards");
  if (!data.accounts.length) {
    cards.innerHTML = `<div class="empty">No accounts yet.</div>`;
  }
  data.accounts.forEach((account, index) => {
    const card = document.createElement("div");
    card.className = "card";
    card.innerHTML = `
      <div class="card-header">
        <div class="card-title">
          <h3>${escapeHtml(account.display_name || account.id || "Untitled account")}</h3>
          <span class="chip">${escapeHtml(account.handle || "@handle")} / Tier ${escapeHtml(account.tier || 1)}</span>
        </div>
        <button class="danger small" data-delete>Delete</button>
      </div>
      <div class="row">
        ${textField("ID", account.id, "id")}
        ${textField("Display Name", account.display_name, "display_name")}
      </div>
      <div class="row">
        ${textField("Handle", account.handle, "handle")}
        ${numberField("Tier", account.tier, "tier")}
      </div>
      <div class="row">
        ${selectField("Voice", account.voice, "voice", voiceOptions)}
        ${textField("Person ID", account.person_id || "", "person_id")}
      </div>
      <div class="toolbar">
        <label><input type="checkbox" data-check="verified" ${account.verified ? "checked" : ""}> Verified</label>
        <label><input type="checkbox" data-check="thread_preference" ${account.thread_preference ? "checked" : ""}> Thread Preference</label>
      </div>
    `;
    bindObjectInputs(card, account);
    card.querySelectorAll("[data-check]").forEach((checkbox) => {
      checkbox.addEventListener("change", (event) => {
        account[event.target.dataset.check] = event.target.checked;
        markDirty();
      });
    });
    card.querySelector("[data-delete]").addEventListener("click", () => {
      if (!confirm("Delete this account?")) return;
      data.accounts.splice(index, 1);
      markDirty();
      render();
    });
    cards.appendChild(card);
  });
  document.getElementById("addAccount").addEventListener("click", () => {
    const id = uniqueId("new_account", data.accounts.map((row) => row.id));
    data.accounts.push({
      id,
      display_name: "New Account",
      handle: `@${id.replace(/_/g, "")}`,
      tier: 1,
      verified: false,
      voice: voiceOptions[0] || "",
      thread_preference: false
    });
    markDirty();
    render();
  });
}

function renderNestedTemplateEditor(kind) {
  const data = catalog();
  const isVoice = kind === "voice";
  const mapName = isVoice ? "voice_templates" : "thread_templates";
  const title = isVoice ? "Voice Templates" : "Thread Templates";
  const copy = isVoice
    ? "Voice pools produce the visible post text. Keys are selected by category, scope, tone, and corporate-action state."
    : "Thread pools render numbered thread lines for accounts with thread_preference enabled.";
  const selectedVoiceKey = isVoice ? "voiceId" : "threadVoiceId";
  const selectedPoolKey = isVoice ? "voiceKey" : "threadKey";
  const templates = data[mapName] || {};
  const voiceIds = Object.keys(templates);
  if (!voiceIds.includes(state[selectedVoiceKey])) state[selectedVoiceKey] = voiceIds[0] || "";
  const currentVoice = templates[state[selectedVoiceKey]] || {};
  const poolKeys = Object.keys(currentVoice);
  if (!poolKeys.includes(state[selectedPoolKey])) state[selectedPoolKey] = poolKeys[0] || "";
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>${title}</h2>
        <p>${copy}</p>
      </div>
      <button id="addVoice">Add Voice</button>
    </div>
    <div class="pool-grid">
      <div class="key-list" id="voiceKeys"></div>
      <div class="card" id="templateEditor"></div>
    </div>
  `;
  renderKeyButtons("voiceKeys", voiceIds, state[selectedVoiceKey], (key) => {
    state[selectedVoiceKey] = key;
    state[selectedPoolKey] = "";
    render();
  }, (key) => `${Object.keys(templates[key] || {}).length}`);
  const editor = document.getElementById("templateEditor");
  if (!state[selectedVoiceKey]) {
    editor.innerHTML = `<div class="empty">Choose or add a voice.</div>`;
  } else {
    editor.innerHTML = `
      <div class="card-header">
        <div class="card-title">
          <h3>${escapeHtml(state[selectedVoiceKey])}</h3>
          <span class="chip">${escapeHtml(mapName)}</span>
        </div>
        <div class="actions">
          <button id="addPoolKey" class="small">Add Pool</button>
          <button id="deleteVoice" class="danger small">Delete Voice</button>
        </div>
      </div>
      <div class="pool-grid">
        <div class="key-list" id="poolKeys"></div>
        <div id="poolEditor"></div>
      </div>
    `;
    renderKeyButtons("poolKeys", poolKeys, state[selectedPoolKey], (key) => {
      state[selectedPoolKey] = key;
      render();
    }, (key) => `${(currentVoice[key] || []).length}`);
    const poolEditor = document.getElementById("poolEditor");
    if (!state[selectedPoolKey]) {
      poolEditor.innerHTML = `<div class="empty">Choose or add a pool.</div>`;
    } else {
      poolEditor.innerHTML = `
        <div class="toolbar">
          <span class="chip">${escapeHtml(state[selectedPoolKey])}</span>
          <button id="deletePoolKey" class="small danger">Delete Pool</button>
        </div>
        ${textAreaField("Templates", arrayToLines(currentVoice[state[selectedPoolKey]]), "template_lines", 14)}
      `;
      poolEditor.querySelector("[data-field='template_lines']").addEventListener("input", (event) => {
        currentVoice[state[selectedPoolKey]] = linesToArray(event.target.value);
        markDirty();
      });
      document.getElementById("deletePoolKey").addEventListener("click", () => {
        if (!confirm(`Delete pool ${state[selectedPoolKey]}?`)) return;
        delete currentVoice[state[selectedPoolKey]];
        state[selectedPoolKey] = "";
        markDirty();
        render();
      });
    }
    document.getElementById("addPoolKey").addEventListener("click", () => {
      const key = prompt("Pool key");
      if (!key) return;
      const id = uniqueId(key, Object.keys(currentVoice));
      currentVoice[id] = [isVoice ? "New post template for {target_ticker}." : "1. New thread line."];
      state[selectedPoolKey] = id;
      markDirty();
      render();
    });
    document.getElementById("deleteVoice").addEventListener("click", () => {
      if (!confirm(`Delete voice ${state[selectedVoiceKey]}?`)) return;
      delete templates[state[selectedVoiceKey]];
      state[selectedVoiceKey] = "";
      markDirty();
      render();
    });
  }
  document.getElementById("addVoice").addEventListener("click", () => {
    const key = prompt("Voice id");
    if (!key) return;
    const id = uniqueId(key, Object.keys(templates));
    templates[id] = isVoice
      ? { company_positive: ["New post template for {target_ticker}."], market_wrap: ["Market note: {market_change}."] }
      : { company_positive: ["1. New thread line.", "2. Add another check."] };
    state[selectedVoiceKey] = id;
    state[selectedPoolKey] = Object.keys(templates[id])[0] || "";
    markDirty();
    render();
  });
}

function renderFallbacks() {
  const data = catalog();
  const group = data[state.fallbackGroup] || {};
  const keys = Object.keys(group);
  if (!keys.includes(state.fallbackKey)) state.fallbackKey = keys[0] || "";
  viewEl.innerHTML = `
    <div class="section-header">
      <div>
        <h2>Fallbacks</h2>
        <p>Fallback pools keep the feed populated when an account voice lacks a specific event key.</p>
      </div>
    </div>
    <div class="toolbar">
      <label>Fallback Group</label>
      <select id="fallbackGroup">${FALLBACK_GROUPS.map((slot) => option(slot, slot, state.fallbackGroup)).join("")}</select>
      <button id="addFallbackKey" class="small">Add Pool</button>
      <button id="deleteFallbackKey" class="small danger" ${state.fallbackKey ? "" : "disabled"}>Delete Pool</button>
    </div>
    <div class="pool-grid">
      <div class="key-list" id="fallbackKeys"></div>
      <div class="card" id="fallbackEditor"></div>
    </div>
  `;
  document.getElementById("fallbackGroup").addEventListener("change", (event) => {
    state.fallbackGroup = event.target.value;
    state.fallbackKey = "";
    render();
  });
  renderKeyButtons("fallbackKeys", keys, state.fallbackKey, (key) => {
    state.fallbackKey = key;
    render();
  }, (key) => `${(group[key] || []).length}`);
  const editor = document.getElementById("fallbackEditor");
  if (!state.fallbackKey) {
    editor.innerHTML = `<div class="empty">Choose or add a fallback pool.</div>`;
  } else {
    editor.innerHTML = `
      <div class="card-header">
        <h3>${escapeHtml(state.fallbackKey)}</h3>
        <span class="chip">${escapeHtml(state.fallbackGroup)}</span>
      </div>
      ${textAreaField("Templates", arrayToLines(group[state.fallbackKey]), "fallback_lines", 14)}
    `;
    editor.querySelector("[data-field='fallback_lines']").addEventListener("input", (event) => {
      group[state.fallbackKey] = linesToArray(event.target.value);
      markDirty();
    });
  }
  document.getElementById("addFallbackKey").addEventListener("click", () => {
    const key = prompt("Fallback key");
    if (!key) return;
    const id = uniqueId(key, Object.keys(group));
    group[id] = ["New fallback template."];
    state.fallbackKey = id;
    markDirty();
    render();
  });
  document.getElementById("deleteFallbackKey").addEventListener("click", () => {
    if (!state.fallbackKey || !confirm(`Delete fallback pool ${state.fallbackKey}?`)) return;
    delete group[state.fallbackKey];
    state.fallbackKey = "";
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
      const newKey = String(event.target.value || "").trim();
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

function bindObjectInputs(root, object) {
  root.querySelectorAll("[data-field]").forEach((input) => {
    const field = input.dataset.field;
    input.addEventListener("input", (event) => {
      if (input.type === "number") {
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
