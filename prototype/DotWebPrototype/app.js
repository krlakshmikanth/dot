const state = {
  variant: "A",
  screen: "home",
  timeFormat: "12",
  selectedMedication: null,
  theme: "light",
  statusPeriod: "today",
  medications: [
    { id: 1, name: "Metformin", dose: "500 mg", status: "Within your limits", icon: "check", detail: "Last taken 6 hr ago", gap: 6, max: 2 },
    { id: 2, name: "Paracetamol", dose: "500 mg", status: "Wait 1 hr", icon: "clock", detail: "Last taken 3 hr ago", gap: 4, max: 4 },
    { id: 3, name: "Ibuprofen", dose: "200 mg", status: "Limit reached", icon: "warning", detail: "4 of 4 in rolling 24 hr", gap: 6, max: 4 }
  ],
  history: [
    { day: "Yesterday", time: "20:15", name: "Metformin", dose: "500 mg" },
    { day: "Yesterday", time: "14:20", name: "Paracetamol", dose: "500 mg" },
    { day: "Monday", time: "08:10", name: "Ibuprofen", dose: "200 mg" },
    { day: "Monday", time: "07:45", name: "Metformin", dose: "500 mg" }
  ]
};

const $ = selector => document.querySelector(selector);
const $$ = selector => [...document.querySelectorAll(selector)];
const icon = name => `<svg aria-hidden="true"><use href="#i-${name}"></use></svg>`;
const escapeHTML = value => String(value).replace(/[&<>'"]/g, char => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;" }[char]));

function buildDither() {
  const container = $("#particles");
  for (let i = 0; i < 34; i += 1) {
    const dot = document.createElement("span");
    dot.className = "particle";
    dot.style.setProperty("--size", `${2 + (i % 4)}px`);
    dot.style.setProperty("--x", `${65 + ((i * 47) % 260)}px`);
    dot.style.setProperty("--y", `${300 + ((i * 71) % 230)}px`);
    dot.style.setProperty("--tx", `${((i % 11) - 5) * 15}px`);
    dot.style.setProperty("--ty", `${((i % 5) - 2) * 10}px`);
    dot.style.setProperty("--opacity", i % 3 === 0 ? ".8" : ".35");
    container.append(dot);
  }
  const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches;
  const splash = $("#splash");
  setTimeout(() => splash.classList.add("coalesce"), reduced ? 0 : 600);
  setTimeout(() => splash.classList.add("reveal"), reduced ? 0 : 1400);
  setTimeout(() => {
    splash.hidden = true;
    $("#prototype").hidden = false;
    renderAll();
  }, reduced ? 100 : 2350);
}

function formatTime(date = new Date()) {
  return new Intl.DateTimeFormat("en-GB", state.timeFormat === "24"
    ? { hour: "2-digit", minute: "2-digit", hour12: false }
    : { hour: "numeric", minute: "2-digit", hour12: true }
  ).format(date);
}

function renderVariant() {
  $$(".home-variant").forEach(node => { node.hidden = node.dataset.variant !== state.variant; });
  $$('[data-home-action]').forEach(button => button.setAttribute("aria-pressed", String(button.dataset.homeAction === state.variant)));
  history.replaceState({}, "", location.pathname);
}

function severityFor(medication) {
  if (medication.icon === "warning") return "danger";
  if (medication.icon === "clock") return "medium";
  return "safe";
}

function statusRow(medication) {
  const severity = severityFor(medication);
  const accessibleStatus = severity === "danger" ? ", danger" : "";
  return `<article class="status-row ${severity}" aria-label="${escapeHTML(medication.name)}, ${escapeHTML(medication.dose)}, ${escapeHTML(medication.detail)}${accessibleStatus}">${icon(medication.icon)}<div class="status-copy"><strong>${escapeHTML(medication.name)} ${escapeHTML(medication.dose)}</strong><small>${escapeHTML(medication.detail)}</small></div></article>`;
}

function renderMedications() {
  $("#status-list").innerHTML = state.medications.map(med => statusRow(med)).join("");
  $("#medicine-options").innerHTML = state.medications.map(med => `
    <button class="medicine-option${state.selectedMedication === med.id ? " selected" : ""}" type="button" data-medication="${med.id}" aria-pressed="${state.selectedMedication === med.id}">
      <span><strong>${escapeHTML(med.name)}</strong><small>${escapeHTML(med.dose)}</small></span>
      ${state.selectedMedication === med.id ? icon("check") : ""}
    </button>`).join("");
  $$('[data-medication]').forEach(button => button.addEventListener("click", () => {
    state.selectedMedication = Number(button.dataset.medication);
    $("#log-now").disabled = false;
    renderMedications();
  }));
}

function renderHistory() {
  const days = [...new Set(state.history.map(item => item.day))];
  $("#past-list").innerHTML = days.map(day => `
    <section class="history-day" aria-labelledby="history-${escapeHTML(day.toLowerCase())}">
      <h2 id="history-${escapeHTML(day.toLowerCase())}">${escapeHTML(day)}</h2>
      ${state.history.filter(item => item.day === day).map(item => `
        <article class="past-row"><time>${escapeHTML(item.time)}</time><strong>${escapeHTML(item.name)}</strong><span>${escapeHTML(item.dose)}</span></article>`).join("")}
    </section>`).join("");
}

function renderStatusPeriod() {
  $$('[data-status-period]').forEach(button => button.setAttribute("aria-pressed", String(button.dataset.statusPeriod === state.statusPeriod)));
  $$('[data-status-panel]').forEach(panel => { panel.hidden = panel.dataset.statusPanel !== state.statusPeriod; });
}

function goTo(screen) {
  state.screen = screen;
  $$(".screen").forEach(node => { node.hidden = node.id !== screen; node.classList.toggle("active", node.id === screen); });
  $$(".tab-bar [data-go]").forEach(button => button.classList.toggle("active", button.dataset.go === screen));
}

function openLogSheet() {
  state.selectedMedication = null;
  $("#log-select-phase").hidden = false;
  $("#log-done-phase").hidden = true;
  $("#log-now").disabled = true;
  $("#log-sheet").hidden = false;
  renderMedications();
  setTimeout(() => $("#medicine-options button")?.focus(), 0);
}

function closeLogSheet() { $("#log-sheet").hidden = true; }

function logDose() {
  const medication = state.medications.find(item => item.id === state.selectedMedication);
  if (!medication) return;
  medication.status = `Wait ${medication.gap} hr`;
  medication.icon = "clock";
  medication.detail = "Logged just now";
  $("#logged-at").textContent = formatTime();
  $("#log-select-phase").hidden = true;
  $("#log-done-phase").hidden = false;
  renderMedications();
}

function setTheme(theme) {
  state.theme = theme;
  document.body.toggleAttribute("data-theme", theme !== "system");
  if (theme === "system") document.body.removeAttribute("data-theme");
  else document.body.dataset.theme = theme;
  $$('[data-theme-value]').forEach(button => button.setAttribute("aria-pressed", String(button.dataset.themeValue === theme)));
  const nextTheme = theme === "dark" ? "light" : "dark";
  const themeToggle = $("#theme-toggle");
  themeToggle.setAttribute("aria-label", `Switch to ${nextTheme} mode`);
  themeToggle.title = `Switch to ${nextTheme} mode`;
  themeToggle.querySelector("use").setAttribute("href", theme === "dark" ? "#i-sun" : "#i-moon");
}

function renderAll() {
  $("#header-time").textContent = formatTime();
  setTheme(state.theme);
  renderVariant();
  renderMedications();
  renderHistory();
  renderStatusPeriod();
  goTo(state.screen);
}

document.addEventListener("click", event => {
  const go = event.target.closest("[data-go]");
  if (go) goTo(go.dataset.go);
  if (event.target.closest("[data-open-log]")) openLogSheet();
  if (event.target.closest("[data-close-sheet]")) closeLogSheet();
  if (event.target.closest("[data-close-add]")) $("#add-sheet").hidden = true;
});

$$('[data-time-format]').forEach(button => button.addEventListener("click", () => {
  state.timeFormat = button.dataset.timeFormat;
  $$('[data-time-format]').forEach(item => item.setAttribute("aria-pressed", String(item === button)));
  $("#header-time").textContent = formatTime();
}));
$$('[data-theme-value]').forEach(button => button.addEventListener("click", () => setTheme(button.dataset.themeValue)));
$("#theme-toggle").addEventListener("click", () => setTheme(state.theme === "dark" ? "light" : "dark"));
$$('[data-status-period]').forEach(button => button.addEventListener("click", () => {
  state.statusPeriod = button.dataset.statusPeriod;
  renderStatusPeriod();
}));
$("#reduce-motion").addEventListener("change", event => document.body.classList.toggle("reduce-motion", event.target.checked));
$("#log-now").addEventListener("click", logDose);
$("#view-status").addEventListener("click", () => { closeLogSheet(); goTo("status"); });
$("#open-add").addEventListener("click", () => { $("#add-sheet").hidden = false; setTimeout(() => $('#add-form input[name="name"]').focus(), 0); });
$$('[data-home-action]').forEach(button => button.addEventListener("click", () => {
  state.variant = button.dataset.homeAction;
  renderVariant();
}));
document.addEventListener("keydown", event => {
  if (["INPUT", "TEXTAREA", "SELECT"].includes(document.activeElement?.tagName)) return;
  if (event.key === "Escape") { closeLogSheet(); $("#add-sheet").hidden = true; }
});

$("#add-form").addEventListener("submit", event => {
  event.preventDefault();
  const data = new FormData(event.currentTarget);
  state.medications.push({
    id: Date.now(),
    name: data.get("name"),
    dose: `${data.get("dose")} ${data.get("unit")}`,
    status: "Within your limits",
    icon: "check",
    detail: "Not logged yet",
    gap: Number(data.get("gap")),
    max: Number(data.get("max"))
  });
  event.currentTarget.reset();
  $("#add-sheet").hidden = true;
  renderMedications();
});

buildDither();
