let source = null;
let selectedCategoryIndex = 0;
let selectedSectionIndex = 0;
let mode = "section";

const categoryList = document.getElementById("categoryList");
const sectionList = document.getElementById("sectionList");
const form = document.getElementById("form");
const message = document.getElementById("message");
const previewPane = document.getElementById("previewPane");
const validationPane = document.getElementById("validationPane");

function catalog() {
  if (!source.catalog) source.catalog = { categories: [], glossary: [] };
  if (!Array.isArray(source.catalog.categories)) source.catalog.categories = [];
  if (!Array.isArray(source.catalog.glossary)) source.catalog.glossary = [];
  return source.catalog;
}

function selectedCategory() {
  return catalog().categories[selectedCategoryIndex] || null;
}

function selectedSection() {
  const category = selectedCategory();
  if (!category || !Array.isArray(category.sections)) return null;
  return category.sections[selectedSectionIndex] || null;
}

function setMessage(text, kind = "") {
  message.textContent = text;
  message.className = `message ${kind}`;
}

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, char => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    "\"": "&quot;",
    "'": "&#39;"
  }[char]));
}

function safeId(value, fallback) {
  return String(value || fallback)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "") || fallback;
}

async function api(path, options = {}) {
  const response = await fetch(path, options);
  const payload = await response.json();
  if (!response.ok) {
    throw new Error(payload.error || JSON.stringify(payload, null, 2));
  }
  return payload;
}

async function loadSource() {
  source = await api("/api/source");
  selectedCategoryIndex = Math.min(selectedCategoryIndex, Math.max(catalog().categories.length - 1, 0));
  selectedSectionIndex = 0;
  mode = "section";
  renderAll();
  setMessage("Source loaded.", "ok");
}

async function saveSource() {
  const result = await api("/api/source", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(source)
  });
  renderValidation(result.validation);
  setMessage("Source saved.", result.validation.valid ? "ok" : "error");
}

async function validateSource() {
  const result = await api("/api/validate", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(source)
  });
  renderValidation(result);
  setMessage(result.valid ? "Validation passed." : "Validation found errors.", result.valid ? "ok" : "error");
}

async function exportRuntime() {
  const result = await api("/api/export", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(source)
  });
  renderValidation(result.validation);
  setMessage(`Exported runtime JSON: ${result.path}`, "ok");
}

function renderAll() {
  renderLists();
  renderForm();
  renderPreview();
}

function renderLists() {
  categoryList.innerHTML = "";
  catalog().categories.forEach((category, index) => {
    const button = document.createElement("button");
    button.textContent = category.label || category.id || `Category ${index + 1}`;
    button.className = index === selectedCategoryIndex ? "selected" : "";
    button.onclick = () => {
      selectedCategoryIndex = index;
      selectedSectionIndex = 0;
      mode = "section";
      renderAll();
    };
    categoryList.appendChild(button);
  });

  sectionList.innerHTML = "";
  const category = selectedCategory();
  const sections = Array.isArray(category?.sections) ? category.sections : [];
  sections.forEach((section, index) => {
    const button = document.createElement("button");
    button.textContent = `${section.order || index + 1}. ${section.title || section.label || section.id}`;
    button.className = mode === "section" && index === selectedSectionIndex ? "selected" : "";
    button.onclick = () => {
      selectedSectionIndex = index;
      mode = "section";
      renderAll();
    };
    sectionList.appendChild(button);
  });
}

function inputField(label, value, onInput, type = "text") {
  const wrapper = document.createElement("div");
  wrapper.className = "field";
  const labelNode = document.createElement("label");
  labelNode.textContent = label;
  const input = document.createElement(type === "textarea" ? "textarea" : "input");
  if (type !== "textarea") input.type = type;
  input.value = value ?? "";
  input.oninput = () => {
    onInput(input.value);
    renderPreview();
  };
  wrapper.append(labelNode, input);
  return wrapper;
}

function selectField(label, value, options, onInput) {
  const wrapper = document.createElement("div");
  wrapper.className = "field";
  const labelNode = document.createElement("label");
  labelNode.textContent = label;
  const select = document.createElement("select");
  options.forEach(option => {
    const node = document.createElement("option");
    node.value = option;
    node.textContent = option;
    select.appendChild(node);
  });
  select.value = value;
  select.onchange = () => {
    onInput(select.value);
    renderAll();
  };
  wrapper.append(labelNode, select);
  return wrapper;
}

function renderForm() {
  form.innerHTML = "";
  if (mode === "glossary") {
    renderGlossaryForm();
    return;
  }
  const category = selectedCategory();
  if (!category) {
    form.textContent = "No category selected.";
    return;
  }

  const categoryCard = document.createElement("div");
  categoryCard.className = "card";
  categoryCard.innerHTML = "<div class=\"card-head\"><strong>Category</strong></div>";
  categoryCard.append(
    inputField("ID", category.id, value => category.id = safeId(value, "category")),
    inputField("Label", category.label, value => category.label = value),
    selectField("Status", category.status || "coming_soon", ["coming_soon", "playable"], value => category.status = value),
    inputField("Summary", category.summary, value => category.summary = value, "textarea"),
    inputField("Coming Soon Copy", category.coming_soon_copy, value => category.coming_soon_copy = value, "textarea")
  );
  if (category.status === "playable") {
    categoryCard.append(
      inputField("Quiz Passing Score", category.quiz_passing_score ?? 0.8, value => category.quiz_passing_score = Number(value), "number"),
      inputField("Required Section IDs (comma-separated)", (category.quiz_required_section_ids || []).join(", "), value => {
        category.quiz_required_section_ids = value.split(",").map(item => item.trim()).filter(Boolean);
      })
    );
    const quizButton = document.createElement("button");
    quizButton.textContent = "Edit Quiz Questions";
    quizButton.onclick = () => {
      mode = "quiz";
      renderAll();
    };
    categoryCard.appendChild(quizButton);
  }
  form.appendChild(categoryCard);

  if (mode === "quiz") {
    renderQuizForm(category);
    return;
  }
  renderSectionForm(category);
}

function renderSectionForm(category) {
  if (!Array.isArray(category.sections)) category.sections = [];
  const section = selectedSection();
  if (!section) {
    form.appendChild(document.createTextNode("No section selected."));
    return;
  }

  const card = document.createElement("div");
  card.className = "card";
  card.innerHTML = "<div class=\"card-head\"><strong>Section</strong></div>";
  card.append(
    inputField("ID", section.id, value => section.id = safeId(value, "section")),
    inputField("Order", section.order ?? selectedSectionIndex + 1, value => section.order = Number(value), "number"),
    inputField("Label", section.label, value => section.label = value),
    inputField("Title", section.title, value => section.title = value),
    selectField("Kind", section.kind || "lesson", ["lesson", "quiz", "glossary"], value => section.kind = value),
    inputField("Completion Signal", section.completion_signal, value => section.completion_signal = value, "textarea")
  );
  form.appendChild(card);

  if ((section.kind || "lesson") === "lesson") {
    renderContentBlocks(section);
    renderQuickChecks(section);
  }
}

function renderContentBlocks(section) {
  if (!Array.isArray(section.content_blocks)) section.content_blocks = [];
  const card = document.createElement("div");
  card.className = "card";
  card.innerHTML = "<div class=\"card-head\"><strong>Lesson Blocks</strong></div>";
  section.content_blocks.forEach((block, index) => card.appendChild(blockEditor(section.content_blocks, block, index)));
  const row = document.createElement("div");
  row.className = "button-row";
  row.append(
    actionButton("Add Text Block", () => {
      section.content_blocks.push({ type: "text", heading: "New heading", body: "", infoboxes: [], images: [] });
      renderAll();
    }),
    actionButton("Add Image Block", () => {
      section.content_blocks.push({ type: "image", asset_path: "", caption: "", alt: "" });
      renderAll();
    }),
    actionButton("Add Key Insights", () => {
      section.content_blocks.push({ type: "key_insights", title: "Key Insights", bullets: [""] });
      renderAll();
    })
  );
  card.appendChild(row);
  form.appendChild(card);
}

function blockEditor(blocks, block, index) {
  const card = document.createElement("div");
  card.className = "card";
  const title = block.type === "image" ? "Image Block" : (block.type === "key_insights" ? "Key Insights" : "Text Block");
  card.innerHTML = `<div class="card-head"><strong>${title} ${index + 1}</strong></div>`;
  card.appendChild(selectField("Type", block.type || "text", ["text", "image", "key_insights"], value => {
    block.type = value;
    if (value === "text") {
      block.heading ??= "";
      block.body ??= "";
      if (!Array.isArray(block.infoboxes)) block.infoboxes = [];
      if (!Array.isArray(block.images)) block.images = [];
    } else if (value === "image") {
      block.asset_path ??= "";
      block.caption ??= "";
      block.alt ??= "";
    } else {
      block.title ??= "Key Insights";
      if (!Array.isArray(block.bullets)) block.bullets = [""];
    }
  }));
  if ((block.type || "text") === "image") {
    card.append(
      inputField("Asset Path", block.asset_path, value => block.asset_path = value),
      inputField("Caption", block.caption, value => block.caption = value),
      inputField("Alt Text", block.alt, value => block.alt = value)
    );
    const upload = document.createElement("input");
    upload.type = "file";
    upload.accept = "image/png,image/jpeg,image/webp";
    upload.onchange = () => uploadImage(upload.files[0], block);
    const uploadField = document.createElement("div");
    uploadField.className = "field";
    uploadField.innerHTML = "<label>Upload Image</label>";
    uploadField.appendChild(upload);
    card.appendChild(uploadField);
  } else if (block.type === "key_insights") {
    card.append(
      inputField("Title", block.title, value => block.title = value),
      inputField("Bullets (one per line)", Array.isArray(block.bullets) ? block.bullets.join("\n") : "", value => {
        block.bullets = value.split("\n").map(item => item.trim()).filter(Boolean);
      }, "textarea")
    );
  } else {
    card.append(
      inputField("Heading", block.heading, value => block.heading = value),
      inputField("Body", block.body, value => block.body = value, "textarea")
    );
    card.appendChild(textImageEditor(block));
    card.appendChild(infoboxEditor(block));
  }
  card.appendChild(reorderButtons(blocks, index));
  return card;
}

function textImageEditor(block) {
  if (!Array.isArray(block.images)) block.images = [];
  const wrapper = document.createElement("div");
  wrapper.className = "card";
  wrapper.innerHTML = "<div class=\"card-head\"><strong>Inline Images</strong></div>";
  block.images.forEach((image, index) => {
    const item = document.createElement("div");
    item.className = "card";
    item.append(
      inputField("Asset Path", image.asset_path, value => image.asset_path = value),
      inputField("Caption", image.caption, value => image.caption = value),
      inputField("Alt Text", image.alt, value => image.alt = value)
    );
    const upload = document.createElement("input");
    upload.type = "file";
    upload.accept = "image/png,image/jpeg,image/webp";
    upload.onchange = () => uploadImage(upload.files[0], image);
    const uploadField = document.createElement("div");
    uploadField.className = "field";
    uploadField.innerHTML = "<label>Upload Image</label>";
    uploadField.appendChild(upload);
    item.append(uploadField, reorderButtons(block.images, index));
    wrapper.appendChild(item);
  });
  wrapper.appendChild(actionButton("Add Inline Image", () => {
    block.images.push({ asset_path: "", caption: "", alt: "" });
    renderAll();
  }));
  return wrapper;
}

function infoboxEditor(block) {
  if (!Array.isArray(block.infoboxes)) block.infoboxes = [];
  const wrapper = document.createElement("div");
  wrapper.className = "card";
  wrapper.innerHTML = "<div class=\"card-head\"><strong>Infoboxes</strong></div>";
  block.infoboxes.forEach((infobox, index) => {
    const item = document.createElement("div");
    item.className = "card";
    item.append(
      inputField("Title", infobox.title, value => infobox.title = value),
      inputField("Body", infobox.body, value => infobox.body = value, "textarea"),
      reorderButtons(block.infoboxes, index)
    );
    wrapper.appendChild(item);
  });
  wrapper.appendChild(actionButton("Add Infobox", () => {
    block.infoboxes.push({ title: "Note", body: "" });
    renderAll();
  }));
  return wrapper;
}

async function uploadImage(file, block) {
  if (!file) return;
  const dataUrl = await new Promise(resolve => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.readAsDataURL(file);
  });
  const result = await api("/api/upload", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ filename: file.name, data_url: dataUrl })
  });
  block.asset_path = result.asset_path;
  renderAll();
  setMessage(`Uploaded ${result.filename}.`, "ok");
}

function renderQuickChecks(section) {
  if (!Array.isArray(section.checks)) section.checks = [];
  const card = document.createElement("div");
  card.className = "card";
  card.innerHTML = "<div class=\"card-head\"><strong>Quick Checks</strong></div>";
  section.checks.forEach((check, index) => {
    const checkCard = document.createElement("div");
    checkCard.className = "card";
    checkCard.append(
      inputField("ID", check.id, value => check.id = safeId(value, "check")),
      inputField("Question", check.question, value => check.question = value, "textarea")
    );
    if (!Array.isArray(check.options)) check.options = [];
    check.options.forEach((option, optionIndex) => checkCard.appendChild(optionEditor(check.options, option, optionIndex, "quick")));
    checkCard.append(
      actionButton("Add Option", () => {
        check.options.push({ id: `option_${check.options.length + 1}`, label: "", correct: false, feedback: "" });
        renderAll();
      }),
      reorderButtons(section.checks, index)
    );
    card.appendChild(checkCard);
  });
  card.appendChild(actionButton("Add Quick Check", () => {
    section.checks.push({ id: `check_${section.checks.length + 1}`, question: "", options: [
      { id: "a", label: "", correct: true, feedback: "" },
      { id: "b", label: "", correct: false, feedback: "" }
    ] });
    renderAll();
  }));
  form.appendChild(card);
}

function renderQuizForm(category) {
  if (!Array.isArray(category.quiz_questions)) category.quiz_questions = [];
  const card = document.createElement("div");
  card.className = "card";
  card.innerHTML = "<div class=\"card-head\"><strong>Quiz Questions</strong></div>";
  category.quiz_questions.forEach((question, index) => {
    const questionCard = document.createElement("div");
    questionCard.className = "card";
    questionCard.append(
      inputField("ID", question.id, value => question.id = safeId(value, "question")),
      inputField("Category Label", question.category, value => question.category = value),
      inputField("Prompt", question.prompt, value => question.prompt = value, "textarea"),
      inputField("Correct Feedback", question.feedback_correct, value => question.feedback_correct = value, "textarea"),
      inputField("Wrong Feedback", question.feedback_wrong, value => question.feedback_wrong = value, "textarea")
    );
    if (!Array.isArray(question.options)) question.options = [];
    question.options.forEach((option, optionIndex) => questionCard.appendChild(optionEditor(question.options, option, optionIndex, "quiz", question)));
    questionCard.append(
      actionButton("Add Option", () => {
        question.options.push({ id: `option_${question.options.length + 1}`, label: "" });
        renderAll();
      }),
      reorderButtons(category.quiz_questions, index)
    );
    card.appendChild(questionCard);
  });
  card.appendChild(actionButton("Add Quiz Question", () => {
    category.quiz_questions.push({
      id: `q_${category.quiz_questions.length + 1}`,
      category: category.label || "",
      prompt: "",
      options: [{ id: "a", label: "" }, { id: "b", label: "" }],
      correct_answer_id: "a",
      feedback_correct: "",
      feedback_wrong: ""
    });
    renderAll();
  }));
  form.appendChild(card);
}

function optionEditor(options, option, index, modeName, question = null) {
  const row = document.createElement("div");
  row.className = "option-row";
  const radio = document.createElement("input");
  radio.type = "radio";
  radio.checked = modeName === "quiz" ? question.correct_answer_id === option.id : Boolean(option.correct);
  radio.onchange = () => {
    if (modeName === "quiz") {
      question.correct_answer_id = option.id;
    } else {
      options.forEach(item => item.correct = false);
      option.correct = true;
    }
    renderAll();
  };
  row.append(
    radio,
    compactInput(option.id, value => option.id = safeId(value, "option")),
    compactInput(option.label, value => option.label = value),
    compactInput(option.feedback || "", value => option.feedback = value),
    document.createTextNode(""),
    actionButton("Remove", () => {
      options.splice(index, 1);
      renderAll();
    }, "danger")
  );
  return row;
}

function compactInput(value, onInput) {
  const input = document.createElement("input");
  input.value = value ?? "";
  input.oninput = () => {
    onInput(input.value);
    renderPreview();
  };
  return input;
}

function renderGlossaryForm() {
  const glossary = catalog().glossary;
  const card = document.createElement("div");
  card.className = "card";
  card.innerHTML = "<div class=\"card-head\"><strong>Glossary</strong></div>";
  glossary.forEach((row, index) => {
    const item = document.createElement("div");
    item.className = "card";
    item.append(
      inputField("Term", row.term, value => row.term = value),
      inputField("Definition", row.definition, value => row.definition = value, "textarea"),
      reorderButtons(glossary, index)
    );
    card.appendChild(item);
  });
  card.appendChild(actionButton("Add Term", () => {
    glossary.push({ term: "New Term", definition: "" });
    renderAll();
  }));
  form.appendChild(card);
}

function reorderButtons(array, index) {
  const row = document.createElement("div");
  row.className = "button-row";
  row.append(
    actionButton("Up", () => {
      if (index > 0) [array[index - 1], array[index]] = [array[index], array[index - 1]];
      renderAll();
    }),
    actionButton("Down", () => {
      if (index < array.length - 1) [array[index + 1], array[index]] = [array[index], array[index + 1]];
      renderAll();
    }),
    actionButton("Duplicate", () => {
      array.splice(index + 1, 0, JSON.parse(JSON.stringify(array[index])));
      renderAll();
    }),
    actionButton("Remove", () => {
      array.splice(index, 1);
      renderAll();
    }, "danger")
  );
  return row;
}

function actionButton(label, onClick, className = "") {
  const button = document.createElement("button");
  button.textContent = label;
  if (className) button.className = className;
  button.onclick = onClick;
  return button;
}

function renderPreview() {
  const section = selectedSection();
  if (!section || mode === "glossary") {
    previewPane.innerHTML = "<p>Select a lesson section to preview it.</p>";
    return;
  }
  const blocks = Array.isArray(section.content_blocks) ? section.content_blocks : [];
  let html = `<div class="preview-chip">CURRENT SELECTION: MODULE ${section.order || selectedSectionIndex + 1}</div>`;
  html += `<h2 class="preview-title">${escapeHtml(section.title || section.label || section.id)}</h2>`;
  html += `<div class="preview-deck">${escapeHtml(section.completion_signal || "")}</div>`;
  blocks.forEach(block => {
    if ((block.type || "text") === "image") {
      const path = block.asset_path || "";
      const src = path ? `/asset?path=${encodeURIComponent(path)}` : "";
      html += `<div class="preview-image">${src ? `<img src="${src}" alt="${escapeHtml(block.alt || "")}">` : "IMAGE PLACEHOLDER"}</div>`;
      if (block.caption) html += `<div class="caption">${escapeHtml(block.caption)}</div>`;
    } else if (block.type === "key_insights") {
      const bullets = Array.isArray(block.bullets) ? block.bullets : [];
      html += `<div class="preview-insights"><h3>${escapeHtml(block.title || "Key Insights")}</h3>`;
      bullets.forEach(bullet => {
        if (String(bullet).trim()) html += `<div class="preview-bullet">- ${escapeHtml(bullet)}</div>`;
      });
      html += "</div>";
    } else {
      html += `<div class="preview-block"><h3>${escapeHtml(block.heading || "Lesson")}</h3>${renderMarkdownBody(block.body || "")}`;
      const images = Array.isArray(block.images) ? block.images : [];
      images.forEach(image => {
        const path = image.asset_path || "";
        const src = path ? `/asset?path=${encodeURIComponent(path)}` : "";
        html += `<div class="preview-inline-image">${src ? `<img src="${src}" alt="${escapeHtml(image.alt || "")}">` : "IMAGE PLACEHOLDER"}</div>`;
        if (image.caption) html += `<div class="caption">${escapeHtml(image.caption)}</div>`;
      });
      const infoboxes = Array.isArray(block.infoboxes) ? block.infoboxes : [];
      infoboxes.forEach(infobox => {
        if (!String(infobox.title || "").trim() && !String(infobox.body || "").trim()) return;
        html += `<div class="preview-infobox"><strong>${escapeHtml(infobox.title || "Note")}</strong><p>${escapeHtml(infobox.body || "").replace(/\n/g, "<br>")}</p></div>`;
      });
      html += "</div>";
    }
  });
  previewPane.innerHTML = html;
}

function renderMarkdownBody(body) {
  const segments = splitMarkdownTables(String(body || ""));
  return segments.map(segment => {
    if (segment.type === "table") return renderPreviewTable(segment);
    const text = String(segment.text || "").trim();
    if (!text) return "";
    return `<p>${escapeHtml(text).replace(/\n/g, "<br>")}</p>`;
  }).join("");
}

function splitMarkdownTables(body) {
  const lines = body.split("\n");
  const segments = [];
  let textLines = [];
  let index = 0;
  const flushText = () => {
    const text = textLines.join("\n").trim();
    if (text) segments.push({ type: "text", text });
    textLines = [];
  };
  while (index < lines.length) {
    const line = lines[index] || "";
    const nextLine = lines[index + 1] || "";
    if (isMarkdownTableRow(line) && isMarkdownTableSeparator(nextLine)) {
      flushText();
      const headers = parseMarkdownTableRow(line);
      const alignments = parseMarkdownTableAlignments(nextLine);
      const rows = [];
      index += 2;
      while (index < lines.length && isMarkdownTableRow(lines[index] || "")) {
        rows.push(parseMarkdownTableRow(lines[index] || ""));
        index += 1;
      }
      segments.push({ type: "table", headers, alignments, rows });
      continue;
    }
    textLines.push(line);
    index += 1;
  }
  flushText();
  return segments;
}

function isMarkdownTableRow(line) {
  const trimmed = String(line || "").trim();
  return trimmed.startsWith("|") && trimmed.endsWith("|") && (trimmed.match(/\|/g) || []).length >= 3;
}

function isMarkdownTableSeparator(line) {
  if (!isMarkdownTableRow(line)) return false;
  const cells = parseMarkdownTableRow(line);
  return cells.length > 0 && cells.every(cell => {
    const value = String(cell || "").trim();
    return value.includes("-") && /^[:\-\s]+$/.test(value);
  });
}

function parseMarkdownTableRow(line) {
  let trimmed = String(line || "").trim();
  if (trimmed.startsWith("|")) trimmed = trimmed.slice(1);
  if (trimmed.endsWith("|")) trimmed = trimmed.slice(0, -1);
  return trimmed.split("|").map(cell => cell.trim());
}

function parseMarkdownTableAlignments(line) {
  return parseMarkdownTableRow(line).map(cell => {
    const value = String(cell || "").trim();
    if (value.startsWith(":") && value.endsWith(":")) return "center";
    if (value.endsWith(":")) return "right";
    return "left";
  });
}

function renderPreviewTable(segment) {
  const alignments = Array.isArray(segment.alignments) ? segment.alignments : [];
  const cell = (value, index, tag) => {
    const align = alignments[index] || "left";
    return `<${tag} style="text-align:${align}">${escapeHtml(value || "")}</${tag}>`;
  };
  let html = "<table class=\"preview-table\"><thead><tr>";
  (segment.headers || []).forEach((header, index) => html += cell(header, index, "th"));
  html += "</tr></thead><tbody>";
  (segment.rows || []).forEach(row => {
    html += "<tr>";
    row.forEach((value, index) => html += cell(value, index, "td"));
    html += "</tr>";
  });
  html += "</tbody></table>";
  return html;
}

function renderValidation(result) {
  validationPane.textContent = JSON.stringify(result, null, 2);
}

document.getElementById("reloadBtn").onclick = () => loadSource().catch(error => setMessage(error.message, "error"));
document.getElementById("saveBtn").onclick = () => saveSource().catch(error => setMessage(error.message, "error"));
document.getElementById("validateBtn").onclick = () => validateSource().catch(error => setMessage(error.message, "error"));
document.getElementById("exportBtn").onclick = () => exportRuntime().catch(error => setMessage(error.message, "error"));
document.getElementById("addCategoryBtn").onclick = () => {
  catalog().categories.push({ id: "new_category", label: "New Category", status: "coming_soon", summary: "", coming_soon_copy: "" });
  selectedCategoryIndex = catalog().categories.length - 1;
  selectedSectionIndex = 0;
  renderAll();
};
document.getElementById("addSectionBtn").onclick = () => {
  const category = selectedCategory();
  if (!category) return;
  if (!Array.isArray(category.sections)) category.sections = [];
  category.sections.push({
    id: "new_section",
    order: category.sections.length + 1,
    label: "New Section",
    title: "New Section",
    kind: "lesson",
    completion_signal: "",
    content_blocks: [{ type: "text", heading: "Concept", body: "", infoboxes: [], images: [] }],
    checks: []
  });
  selectedSectionIndex = category.sections.length - 1;
  mode = "section";
  renderAll();
};
document.getElementById("glossaryBtn").onclick = () => {
  mode = "glossary";
  renderAll();
};

loadSource().catch(error => setMessage(error.message, "error"));
