/* PROTOTYPE ONLY: cross-platform, in-memory interaction design. Nothing here is production dose logic. */
const $ = selector => document.querySelector(selector);
const $$ = selector => [...document.querySelectorAll(selector)];
const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;
const scenarios = {
  everyday: 'A recent record is visible after the entered minimum gap has elapsed.',
  clear: 'There are no Paracetamol doses in the rolling 24-hour record.',
  maximum: 'The user-entered rolling 24-hour maximum has been reached.',
  new: 'A first-time user needs to add a medicine before planning a dose.',
};
const journeys = {
  everyday: 'Plan → confirm → correct time → open History → remove or undo.',
  clear: 'Plan a dose → choose Paracetamol → review → plan → confirm.',
  maximum: 'Open Paracetamol → review warning → check History or record what already happened.',
  new: 'Plan a dose → add medicine from its label → review → plan.',
};
const paths = {
  home: '<path d="M3 11.5 12 4l9 7.5V21h-6v-6H9v6H3Z"/>',
  history: '<path d="M4 12a8 8 0 1 0 2-5.3M4 4v5h5"/><path d="M12 8v5l3 2"/>',
  settings: '<path d="M4 7h16M4 17h16"/><circle cx="9" cy="7" r="3"/><circle cx="15" cy="17" r="3"/>',
  down: '<path d="m7 9 5 5 5-5"/>',
  moon: '<path d="M20 14A8 8 0 0 1 10 4a8 8 0 1 0 10 10Z"/>',
  sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M2 12h2m16 0h2M5 5l1.5 1.5m11 11L19 19M5 19l1.5-1.5m11-11L19 5"/>',
  pill: '<path d="m8 4-4 4a5.7 5.7 0 0 0 8 8l4-4a5.7 5.7 0 0 0-8-8Z"/><path d="m8 8 8 8"/>',
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  warning: '<path d="m12 3 10 18H2Z"/><path d="M12 9v5m0 3h.01"/>',
  check: '<path d="m5 12 4 4L19 6"/>',
  close: '<path d="m6 6 12 12M18 6 6 18"/>',
  back: '<path d="m15 5-7 7 7 7"/>',
  chevron: '<path d="m9 5 7 7-7 7"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  trash: '<path d="M5 7h14M9 7V4h6v3m2 0-1 14H8L7 7"/>',
  info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v6m0-10h.01"/>',
  edit: '<path d="m4 20 4-1 11-11-3-3L5 16Z"/><path d="m14 7 3 3"/>',
  bell: '<path d="M6 9a6 6 0 0 1 12 0v5l2 3H4l2-3Z"/><path d="M10 21h4"/>',
  help: '<circle cx="12" cy="12" r="9"/><path d="M9.5 9a2.5 2.5 0 1 1 4 2c-1 .7-1.5 1-1.5 3m0 3h.01"/>',
  archive: '<path d="M4 7h16v14H4Z"/><path d="M3 3h18v4H3Zm6 8h6"/>',
};
const icon = name => `<svg class="icon" aria-hidden="true" viewBox="0 0 24 24">${paths[name]}</svg>`;
const healthIcon = name => `<span class="health-icon health-icon-${name}" aria-hidden="true"></span>`;
const medicineHealthIcon = value => healthIcon(value?.unit === 'mL' ? 'medicine-bottle' : 'medicines');
const escapeHTML = value => String(value ?? '').replace(/[&<>"']/g, character => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[character]);

let state;
let selectedMedicineID = null;
let selectedEntryID = null;
let planAmount = null;
let returnFocus = null;

function reset(requestedScenario = null) {
  const now = Date.now();
  const params = new URLSearchParams(location.search);
  const scenario = scenarios[requestedScenario] ? requestedScenario : scenarios[params.get('scenario')] ? params.get('scenario') : 'everyday';
  const platform = params.get('platform');
  state = {
    platform: ['ios', 'android'].includes(platform) ? platform : state?.platform || 'ios',
    scenario,
    theme: state?.theme || 'light',
    tab: 'home',
    profileID: 'maya',
    profiles: [
      { id: 'maya', name: 'Maya' },
      { id: 'leo', name: 'Leo' },
    ],
    medicines: scenario === 'new' ? [] : [
      { id: 'para', profileID: 'maya', name: 'Paracetamol', strength: '500 mg tablet', amount: 1, unit: 'tablet', maximum: 4, gap: 4, archived: false },
      { id: 'ceti', profileID: 'maya', name: 'Cetirizine', strength: '10 mg tablet', amount: 1, unit: 'tablet', maximum: 1, gap: 24, archived: false },
      { id: 'liquid', profileID: 'leo', name: 'Prescribed liquid', strength: 'Example concentration', amount: 2.5, unit: 'mL', maximum: 3, gap: 8, archived: false },
    ],
    logs: [],
    plans: [],
    reminders: [],
    undo: null,
  };
  const addLog = (medicineID, hoursAgo, status = 'confirmed') => {
    const item = medicine(medicineID);
    if (!item) return;
    state.logs.push(makeLog(item, now - hoursAgo * HOUR, item.amount, item.unit, status));
  };
  if (scenario === 'everyday') [5, 11].forEach(hours => addLog('para', hours));
  if (scenario === 'maximum') [1.5, 6, 12, 18].forEach(hours => addLog('para', hours));
  if (scenario !== 'new') addLog('ceti', 27);
  if ($('#sheet').open) $('#sheet').close();
  selectedMedicineID = null;
  selectedEntryID = null;
  planAmount = null;
  $('#scenario').value = scenario;
  render();
}

const activeProfile = () => state.profiles.find(profile => profile.id === state.profileID);
const medicine = id => state.medicines.find(item => item.id === id);
const activeMedicines = (includeArchived = false) => state.medicines.filter(item => item.profileID === state.profileID && (includeArchived || !item.archived));
const activeLogs = () => state.logs.filter(log => log.profileID === state.profileID);
const activePlan = () => state.plans.find(plan => plan.profileID === state.profileID);
const logsFor = id => activeLogs().filter(log => log.medicineID === id && log.status === 'confirmed' && log.time <= Date.now()).sort((a, b) => b.time - a.time);
const recentLogsFor = id => logsFor(id).filter(log => log.time >= Date.now() - DAY);
const formatTime = value => new Intl.DateTimeFormat(undefined, { hour: 'numeric', minute: '2-digit' }).format(value);
const formatDay = value => new Intl.DateTimeFormat(undefined, { weekday: 'short', day: 'numeric', month: 'short' }).format(value);
const formatDateTime = value => `${formatDay(value)}, ${formatTime(value)}`;
const localInput = value => {
  const date = new Date(value);
  return new Date(value - date.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
};
const elapsed = value => {
  const minutes = Math.max(0, Math.round((Date.now() - value) / 60000));
  if (minutes < 2) return 'just now';
  if (minutes < 60) return `${minutes} min ago`;
  const hours = Math.floor(minutes / 60);
  const remainder = minutes % 60;
  return `${hours} hr${remainder ? ` ${remainder} min` : ''} ago`;
};
const doseText = value => `${new Intl.NumberFormat(undefined, { maximumFractionDigits: 3 }).format(Number(value.amount))} ${value.unit}${value.unit === 'tablet' && Number(value.amount) !== 1 ? 's' : ''}`;
function makeLog(item, time, amount, unit, status = 'confirmed') {
  return {
    id: crypto.randomUUID(), profileID: item.profileID, medicineID: item.id,
    medicineName: item.name, strength: item.strength, amount: Number(amount), unit,
    time, status, createdAt: Date.now(), correctedAt: null,
  };
}
function assessment(item) {
  const logs = recentLogsFor(item.id);
  const latest = logsFor(item.id)[0];
  const gapRemaining = latest ? Math.max(0, item.gap * HOUR - (Date.now() - latest.time)) : 0;
  return { count: logs.length, latest, gapRemaining, maximum: logs.length >= item.maximum };
}
const gapText = milliseconds => {
  const minutes = Math.max(1, Math.ceil(milliseconds / 60000));
  const hours = Math.floor(minutes / 60);
  return hours ? `${hours} hr${minutes % 60 ? ` ${minutes % 60} min` : ''}` : `${minutes} min`;
};

function planBanner() {
  const plan = activePlan();
  if (!plan) return '';
  const item = medicine(plan.medicineID);
  return `<section class="pending-plan" aria-label="Dose waiting for confirmation"><span class="pending-mark">${icon('clock')}</span><div><small>PLANNED · NOT YET RECORDED AS TAKEN</small><strong>${escapeHTML(item?.name || plan.medicineName)} · ${escapeHTML(doseText(plan))}</strong><span>Planned ${elapsed(plan.plannedAt)}</span></div><button class="mini-button" data-action="resume-plan">Continue</button></section>`;
}
function medicineRow(item, action = 'review') {
  const a = assessment(item);
  const attention = a.maximum || a.gapRemaining > 0;
  return `<button class="medicine-row ${a.maximum ? 'danger' : ''}" data-action="${activePlan() ? 'resume-plan' : action}" data-id="${item.id}"><span class="medicine-icon">${a.maximum ? healthIcon('alert-triangle') : medicineHealthIcon(item)}</span><span class="medicine-copy"><strong>${escapeHTML(item.name)}</strong><small>${escapeHTML(item.strength)} · ${a.latest ? `last ${elapsed(a.latest.time)}` : 'nothing recorded'}</small>${attention ? `<em>${a.maximum ? 'Entered maximum reached' : `${gapText(a.gapRemaining)} remains in entered gap`}</em>` : ''}</span>${icon('chevron')}</button>`;
}
function emptyMedicines() {
  return `<div class="empty-state">${healthIcon('medicines')}<strong>Add your first medicine</strong><p>Copy the name, amount and limits from the label. dot will not suggest them.</p><button class="primary-action" data-action="add-medicine">Add from the label</button></div>`;
}
function renderHome() {
  const pending = planBanner();
  const medicines = activeMedicines();
  if (!medicines.length) return `<section class="screen"><p class="kicker">FOR ${escapeHTML(activeProfile().name).toUpperCase()}</p><h1>Start with the label.</h1><p class="intro-copy">Add one medicine before planning a dose.</p>${emptyMedicines()}${boundary()}</section>`;
  const records = activeLogs().filter(log => log.time >= Date.now() - DAY).sort((a, b) => b.time - a.time);
  const confirmed = records.filter(log => log.status === 'confirmed');
  const uncertain = records.filter(log => log.status === 'uncertain');
  const recordRows = records.map(log => `<button class="timeline-row ${log.status === 'uncertain' ? 'uncertain' : ''}" data-action="entry" data-id="${log.id}"><span class="timeline-icon">${log.status === 'uncertain' ? healthIcon('question-circle') : medicineHealthIcon(log)}</span><span><strong>${escapeHTML(log.medicineName)}</strong><small>${log.status === 'uncertain' ? 'Uncertain · tap to review' : `${escapeHTML(doseText(log))} · confirmed${log.correctedAt ? ' · corrected' : ''}`}</small></span><time>${formatTime(log.time)}</time></button>`).join('');
  return `<section class="screen day-map">${pending}<p class="kicker">FOR ${escapeHTML(activeProfile().name).toUpperCase()} · ROLLING 24 HOURS</p><h1>Your day,<br>at a glance.</h1><div class="day-summary"><span class="day-summary-icon">${healthIcon('calendar')}</span><span><strong>${confirmed.length} confirmed ${confirmed.length === 1 ? 'dose' : 'doses'}</strong><small>Only what this device has recorded</small></span></div>${uncertain.length ? `<button class="uncertain-summary" data-action="tab" data-id="history">${healthIcon('question-circle')}<span><strong>${uncertain.length} uncertain ${uncertain.length === 1 ? 'record needs' : 'records need'} review</strong><small>Not counted as confirmed</small></span>${icon('chevron')}</button>` : ''}<button class="primary-action" data-action="${activePlan() ? 'resume-plan' : 'choose'}">${icon(activePlan() ? 'clock' : 'plus')} ${activePlan() ? 'Finish planned dose' : 'Plan a dose'}</button><div class="timeline-heading"><strong>Recent record</strong><span>Newest first</span></div><div class="timeline">${recordRows || '<p class="empty">No doses recorded in this window.</p>'}</div>${boundary()}</section>`;
}
function renderHistory() {
  const logs = activeLogs().sort((a, b) => b.time - a.time);
  return `<section class="screen"><p class="kicker">${escapeHTML(activeProfile().name).toUpperCase()}</p><h1>History</h1><p class="intro-copy">Open any entry to correct the amount or time, or remove a mistake.</p>${planBanner()}<div class="history-list">${logs.map(log => `<button class="history-row ${log.status === 'uncertain' ? 'uncertain' : ''}" data-action="entry" data-id="${log.id}"><span class="history-dot"></span><span><strong>${escapeHTML(log.medicineName)}</strong><small>${log.status === 'uncertain' ? 'Uncertain · not counted as confirmed' : `${escapeHTML(doseText(log))} · confirmed`}${log.correctedAt ? '<br>Corrected entry' : ''}</small></span><time>${formatDay(log.time)}<br>${formatTime(log.time)}</time></button>`).join('') || '<div class="empty-state compact"><strong>No history yet</strong><p>Confirmed and uncertain records will appear here.</p></div>'}</div><button class="secondary-action top-gap" data-action="record-earlier">${icon('clock')} Record an earlier dose</button>${boundary()}</section>`;
}
function renderSettings() {
  const reminders = state.reminders.filter(item => item.profileID === state.profileID).length;
  return `<section class="screen"><p class="kicker">DOT</p><h1>Settings</h1><div class="settings-group"><button class="setting-row" data-action="profiles"><span><strong>Profiles</strong><small>Recording for ${escapeHTML(activeProfile().name)} · this device</small></span>${icon('chevron')}</button><button class="setting-row" data-action="manage-medicines"><span><strong>Medicines</strong><small>Edit, archive or restore medicines</small></span>${icon('chevron')}</button><button class="setting-row" data-action="reminders"><span><strong>Reminders</strong><small>${reminders ? `${reminders} local reminder${reminders === 1 ? '' : 's'}` : 'Optional · review prompts only'}</small></span>${icon('bell')}</button><button class="setting-row" data-action="theme"><span><strong>Appearance</strong><small>${state.theme === 'light' ? 'Light' : 'Dark'}</small></span>${icon(state.theme === 'light' ? 'moon' : 'sun')}</button><button class="setting-row" data-action="help"><span><strong>Concerned about an extra dose?</strong><small>Find urgent help</small></span>${icon('chevron')}</button></div><div class="info-box">${icon('info')}<p><strong>What dot can check</strong><br>Only the recent records and limits you entered. It cannot tell you that a medicine is safe to take.</p></div>${boundary()}</section>`;
}
function boundary() { return `<p class="boundary-in-app">Uses your entered limits and this device’s records only. Check the medicine label.</p>`; }
function renderToast() {
  const toast = $('#toast');
  if (!state.undo) { toast.className = 'toast'; toast.innerHTML = ''; return; }
  toast.className = 'toast toast-visible';
  toast.innerHTML = `<span>${escapeHTML(state.undo.message)}</span><button data-action="undo-delete">Undo</button>`;
}
function render() {
  const device = $('#device');
  device.dataset.platform = state.platform;
  device.dataset.theme = state.theme;
  device.classList.toggle('has-dialog', $('#sheet').open);
  $$('.platform-control button').forEach(button => button.setAttribute('aria-pressed', button.dataset.platformChoice === state.platform));
  $('#app-bar').innerHTML = `<button class="profile-chip" data-action="profiles" aria-label="Recording for ${escapeHTML(activeProfile().name)}"><span>${escapeHTML(activeProfile().name[0])}</span><b>${escapeHTML(activeProfile().name)}</b>${icon('down')}</button><strong class="app-title">dot</strong><button class="app-icon-button" data-action="theme" aria-label="Switch appearance">${icon(state.theme === 'light' ? 'moon' : 'sun')}</button>`;
  $('#app-content').innerHTML = state.tab === 'history' ? renderHistory() : state.tab === 'settings' ? renderSettings() : renderHome();
  const nav = [['home', 'Home'], ['history', 'History'], ['settings', 'Settings']];
  $('#app-nav').innerHTML = nav.map(([key, label]) => `<button data-action="tab" data-id="${key}" ${state.tab === key ? 'aria-current="page"' : ''}><span>${icon(key)}</span><small>${label}</small></button>`).join('');
  $('#scenario-description').textContent = scenarios[state.scenario];
  $('#journey-copy').textContent = journeys[state.scenario];
  renderToast();
  inspect();
}
function inspect() {
  $('#state-inspector').textContent = JSON.stringify({
    platform: state.platform, home: 'Day map',
    profile: activeProfile().name, screen: state.tab,
    plan: activePlan() ? { medicine: activePlan().medicineName, amount: doseText(activePlan()), status: 'not counted as taken' } : null,
    confirmedLast24Hours: activeLogs().filter(log => log.status === 'confirmed' && log.time >= Date.now() - DAY).length,
    medicines: activeMedicines(true).map(item => ({ name: item.name, archived: item.archived, recorded: assessment(item).count, maximum: item.maximum })),
    records: activeLogs().map(log => ({ medicine: log.medicineName, dose: doseText(log), time: formatDateTime(log.time), status: log.status, corrected: Boolean(log.correctedAt) })),
  }, null, 2);
}
function announce(message) { $('#announcement').textContent = message; }
function navigate(tab) { state.tab = tab; render(); $('#app-content').scrollTop = 0; }

function showSheet(title, body, { back = '', label = '' } = {}) {
  const sheet = $('#sheet');
  if (!sheet.open) returnFocus = document.activeElement;
  sheet.innerHTML = `<div class="sheet-inner"><div class="sheet-handle" aria-hidden="true"></div><div class="sheet-toolbar">${back ? `<button class="sheet-icon" data-action="${back}" aria-label="Back">${icon('back')}</button>` : `<span>${escapeHTML(label || `For ${activeProfile().name}`)}</span>`}<button class="sheet-icon" data-action="close" aria-label="Close">${icon('close')}</button></div><h2 id="sheet-title" tabindex="-1">${title}</h2>${body}</div>`;
  if (!sheet.open) sheet.showModal();
  $('#device').classList.add('has-dialog');
  sheet.scrollTop = 0;
  $('#sheet-title').focus({ preventScroll: true });
}
function closeSheet() { $('#sheet').close(); $('#device').classList.remove('has-dialog'); returnFocus?.focus?.({ preventScroll: true }); inspect(); }
function chooseMedicine(mode = 'plan') {
  const medicines = activeMedicines();
  const choices = medicines.length
    ? `<div class="medicine-list sheet-list">${medicines.map(item => medicineRow(item, mode === 'actual' ? 'actual-medicine' : 'review')).join('')}</div><button class="secondary-action" data-action="add-medicine">${icon('plus')} Add medicine from its label</button>`
    : emptyMedicines();
  showSheet(mode === 'actual' ? 'Which medicine was taken?' : 'Choose a medicine', `<p class="sheet-copy">${mode === 'actual' ? 'Record what actually happened, including the real time and amount.' : 'Start with the medicine you intend to take. Nothing is recorded yet.'}</p>${choices}${boundary()}`);
}
function reviewMedicine(id, preserveAmount = false) {
  if (activePlan()) { resumePlan(); return; }
  if (!preserveAmount || selectedMedicineID !== id || planAmount == null) planAmount = medicine(id)?.amount;
  selectedMedicineID = id;
  const item = medicine(id);
  if (!item) return;
  const a = assessment(item);
  const warnings = `${a.maximum ? `<div class="warning-box danger">${healthIcon('alert-triangle')}<p><strong>Entered maximum reached.</strong><br>${a.count} confirmed in the last 24 hours. The maximum you entered is ${item.maximum}.</p></div>` : ''}${a.gapRemaining ? `<div class="warning-box">${icon('clock')}<p><strong>${gapText(a.gapRemaining)} remains in your entered gap.</strong><br>Last confirmed at ${formatTime(a.latest.time)}. This is not dosing advice.</p></div>` : ''}`;
  const canPlan = !a.maximum && !a.gapRemaining;
  showSheet('Review before taking', `<p class="sheet-copy">Check the person, medicine and recent record. Planning does not mean taken.</p><div class="review-card"><span>${medicineHealthIcon(item)}</span><div><small>FOR ${escapeHTML(activeProfile().name).toUpperCase()}</small><strong>${escapeHTML(item.name)}</strong><p>${escapeHTML(item.strength)} · ${escapeHTML(doseText({ amount: planAmount, unit: item.unit }))}</p></div></div><dl class="review-grid"><div><dt>Last confirmed</dt><dd>${a.latest ? `${formatTime(a.latest.time)}<small>${elapsed(a.latest.time)}</small>` : 'Nothing recorded'}</dd></div><div><dt>Last 24 hours</dt><dd>${a.count} confirmed<small>Entered maximum: ${item.maximum}</small></dd></div><div><dt>Entered minimum gap</dt><dd>${item.gap} hours</dd></div></dl><button class="text-action inline" data-action="change-plan-amount">${icon('edit')} Change amount for this plan</button>${warnings}${canPlan ? `<button class="primary-action" data-action="create-plan">Plan this dose</button><p class="button-note">Next, take the medicine. Then confirm what happened.</p>` : `<button class="primary-action" data-action="history-from-sheet">Review history</button><button class="secondary-action top-gap" data-action="already-taken">Already taken? Record what happened</button>`}<button class="quiet-action" data-action="uncertain-dose">Not sure whether a dose happened?</button><button class="quiet-action" data-action="edit-medicine" data-id="${item.id}">Edit medicine details</button>${boundary()}`, { back: 'choose' });
}
function changePlanAmount() {
  const item = medicine(selectedMedicineID);
  showSheet('Change planned amount', `<p class="sheet-copy">Copy the amount you intend to take from the instructions you are following.</p><form id="plan-amount-form"><label class="field"><span>Amount in ${escapeHTML(item.unit)}</span><input name="amount" type="number" min="0.001" step="any" value="${escapeHTML(planAmount)}" required></label><button class="primary-action" type="submit">Use this amount</button></form>${boundary()}`, { back: 'review-again' });
}
function createPlan() {
  if (activePlan()) { resumePlan(); return; }
  const item = medicine(selectedMedicineID);
  const plan = { id: crypto.randomUUID(), profileID: state.profileID, medicineID: item.id, medicineName: item.name, amount: Number(planAmount), unit: item.unit, plannedAt: Date.now() };
  state.plans.push(plan); render(); showPlan(plan, true); announce('Dose planned. It is not recorded as taken.');
}
function showPlan(plan, newlyCreated = false) {
  const item = medicine(plan.medicineID);
  showSheet(newlyCreated ? 'Dose planned' : 'Is this dose taken?', `<div class="plan-symbol">${icon(newlyCreated ? 'check' : 'clock')}</div><p class="sheet-copy large-copy"><strong>${escapeHTML(item?.name || plan.medicineName)} · ${escapeHTML(doseText(plan))}</strong><br>For ${escapeHTML(activeProfile().name)} · planned ${formatTime(plan.plannedAt)}</p><div class="plan-state"><small>NOT YET IN DOSE HISTORY</small><strong>${newlyCreated ? 'Take it now, then confirm.' : 'Confirm what actually happened.'}</strong><span>If you do not take it, cancel this plan. It will not count as a dose.</span></div><button class="primary-action" data-action="confirm-taken">${newlyCreated ? 'I took it' : 'Yes, I took it'}</button><button class="secondary-action top-gap" data-action="leave-planned">I’ll confirm later</button><button class="quiet-action" data-action="cancel-plan">Cancel plan</button>`, { label: newlyCreated ? 'Step 2 of 2' : 'Pending plan' });
}
function resumePlan() { const plan = activePlan(); if (!plan) return; selectedMedicineID = plan.medicineID; showPlan(plan, false); }
function confirmTaken() {
  const plan = activePlan();
  if (!plan) return;
  const item = medicine(plan.medicineID);
  const log = makeLog(item, Date.now(), plan.amount, plan.unit);
  state.logs.push(log); state.plans = state.plans.filter(candidate => candidate.id !== plan.id); render(); showConfirmation(log); announce('Dose confirmed and added to history.');
}
function showConfirmation(log, corrected = false) {
  const item = medicine(log.medicineID);
  const a = item ? assessment(item) : null;
  showSheet(corrected ? 'Record corrected' : 'Dose recorded', `<div class="plan-symbol">${icon('check')}</div><p class="sheet-copy large-copy"><strong>${escapeHTML(log.medicineName)} · ${escapeHTML(doseText(log))}</strong><br>${formatDateTime(log.time)} · for ${escapeHTML(activeProfile().name)}.</p>${a ? `<div class="confirmed-count"><strong>${a.count}</strong><span>confirmed in the rolling 24-hour record</span></div>` : ''}${a?.maximum ? `<div class="warning-box danger">${healthIcon('alert-triangle')}<p><strong>Your entered maximum is now reached.</strong><br>Review History before any future plan.</p></div>` : ''}<button class="primary-action" data-action="done">Done</button><button class="secondary-action top-gap" data-action="edit-entry" data-id="${log.id}">Correct time or amount</button><button class="quiet-action" data-action="history-from-sheet">View History</button>${boundary()}`);
}
function actualDoseForm(item, { uncertain = false } = {}) {
  return `<p class="sheet-copy">${uncertain ? 'Keep uncertainty visible without treating it as a confirmed dose or as zero.' : 'Use this only when the dose has already been taken. Recording it is not permission to take another.'}</p><div class="review-card"><span>${uncertain ? healthIcon('question-circle') : medicineHealthIcon(item)}</span><div><small>FOR ${escapeHTML(activeProfile().name).toUpperCase()}</small><strong>${escapeHTML(item.name)}</strong><p>${escapeHTML(item.strength)}</p></div></div><form id="${uncertain ? 'uncertain-form' : 'actual-form'}"><div class="field-pair"><label class="field"><span>Actual amount</span><input name="amount" type="number" min="0.001" step="any" value="${item.amount}" required></label><label class="field"><span>Unit</span><select name="unit"><option value="tablet" ${item.unit === 'tablet' ? 'selected' : ''}>tablet</option><option value="mL" ${item.unit === 'mL' ? 'selected' : ''}>mL</option><option value="mg" ${item.unit === 'mg' ? 'selected' : ''}>mg</option></select></label></div><label class="field"><span>${uncertain ? 'Approximate time' : 'Taken at'}</span><input name="time" type="datetime-local" value="${localInput(Date.now())}" max="${localInput(Date.now())}" required></label>${uncertain ? '' : '<label class="confirmation-check"><input type="checkbox" required><span>I confirm this dose was actually taken.</span></label>'}<button class="primary-action" type="submit">${uncertain ? 'Save as uncertain' : 'Record actual dose'}</button></form>${boundary()}`;
}
function recordAlreadyTaken() { const item = medicine(selectedMedicineID); showSheet('Record what happened', actualDoseForm(item), { back: 'review-again' }); }
function recordEarlierMedicine(id) { selectedMedicineID = id; const item = medicine(id); showSheet('Record an earlier dose', actualDoseForm(item), { back: 'record-earlier' }); }
function uncertainDose() { const item = medicine(selectedMedicineID); showSheet('Keep uncertainty visible', actualDoseForm(item, { uncertain: true }), { back: 'review-again' }); }
function openEntry(id) {
  const log = activeLogs().find(item => item.id === id);
  if (!log) return;
  selectedEntryID = id;
  showSheet(log.status === 'uncertain' ? 'Uncertain dose' : 'Recorded dose', `<p class="sheet-copy">For ${escapeHTML(activeProfile().name)}. This record keeps the amount that was entered at the time.</p><div class="review-card"><span>${log.status === 'uncertain' ? healthIcon('question-circle') : medicineHealthIcon(log)}</span><div><small>${log.status === 'uncertain' ? 'NOT COUNTED AS CONFIRMED' : 'CONFIRMED RECORD'}</small><strong>${escapeHTML(log.medicineName)}</strong><p>${escapeHTML(log.strength)}</p></div></div><dl class="review-grid"><div><dt>Amount</dt><dd>${escapeHTML(doseText(log))}</dd></div><div><dt>Time</dt><dd>${formatDateTime(log.time)}</dd></div><div><dt>Record</dt><dd>${log.status === 'uncertain' ? 'Uncertain' : log.correctedAt ? 'Corrected' : 'Confirmed'}${log.correctedAt ? `<small>Updated ${formatTime(log.correctedAt)}</small>` : ''}</dd></div></dl><button class="primary-action" data-action="edit-entry" data-id="${log.id}">${log.status === 'uncertain' ? 'Confirm or correct this dose' : 'Correct time or amount'}</button><button class="secondary-action top-gap destructive-text" data-action="remove-entry" data-id="${log.id}">${icon('trash')} Remove mistaken entry</button><p class="button-note">Only remove an entry if it did not happen or was entered twice.</p>${boundary()}`);
}
function editEntry(id = selectedEntryID) {
  const log = activeLogs().find(item => item.id === id);
  if (!log) return;
  selectedEntryID = id;
  showSheet('Correct the record', `<p class="sheet-copy">Update what actually happened. This changes the existing record and recalculates the rolling 24-hour view.</p><form id="entry-form"><div class="field-pair"><label class="field"><span>Actual amount</span><input name="amount" type="number" min="0.001" step="any" value="${log.amount}" required></label><label class="field"><span>Unit</span><select name="unit"><option value="tablet" ${log.unit === 'tablet' ? 'selected' : ''}>tablet</option><option value="mL" ${log.unit === 'mL' ? 'selected' : ''}>mL</option><option value="mg" ${log.unit === 'mg' ? 'selected' : ''}>mg</option></select></label></div><label class="field"><span>Taken at</span><input name="time" type="datetime-local" value="${localInput(log.time)}" max="${localInput(Date.now())}" required></label>${log.status === 'uncertain' ? '<label class="confirmation-check"><input name="confirm" type="checkbox"><span>I can now confirm this dose was taken.</span></label>' : ''}<button class="primary-action" type="submit">Save correction</button></form>${boundary()}`, { back: 'entry-again' });
}
function removeEntry(id = selectedEntryID) {
  selectedEntryID = id;
  const log = activeLogs().find(item => item.id === id);
  if (!log) return;
  showSheet('Remove this entry?', `<p class="sheet-copy">Only remove it if the dose did not happen or this same event was entered twice.</p><div class="warning-box">${icon('info')}<p><strong>This changes the record, not reality.</strong><br>Removing an entry does not reverse medicine that was actually taken.</p></div><button class="primary-action destructive" data-action="confirm-remove-entry">Remove mistaken entry</button><button class="secondary-action top-gap" data-action="entry-again">Keep entry</button>`);
}
function confirmRemoveEntry() {
  const index = state.logs.findIndex(item => item.id === selectedEntryID && item.profileID === state.profileID);
  if (index < 0) return;
  const [log] = state.logs.splice(index, 1);
  state.undo = { message: `${log.medicineName} entry removed`, type: 'log', item: log, index };
  closeSheet(); navigate('history'); announce('Mistaken entry removed. Undo is available.');
}
function undoDelete() {
  if (!state.undo) return;
  if (state.undo.type === 'log') state.logs.splice(state.undo.index, 0, state.undo.item);
  state.undo = null; render(); announce('Entry restored.');
}

function medicineForm(item = null) {
  if (item) selectedMedicineID = item.id;
  const value = item || { name: '', strength: '', amount: '', unit: 'tablet', maximum: '', gap: '' };
  showSheet(item ? 'Edit medicine' : 'Add from the label', `<p class="sheet-copy">Copy these values from the packet, pharmacy label or instructions you are following. dot does not suggest or verify them.</p><form id="medicine-form"><label class="field"><span>Medicine name</span><input name="name" value="${escapeHTML(value.name)}" maxlength="80" required></label><label class="field"><span>Strength or concentration</span><input name="strength" value="${escapeHTML(value.strength)}" maxlength="100" placeholder="For example, 500 mg tablet" required></label><div class="field-pair"><label class="field"><span>Amount per dose</span><input name="amount" type="number" min="0.001" step="any" value="${escapeHTML(value.amount)}" required></label><label class="field"><span>Unit</span><select name="unit"><option value="tablet" ${value.unit === 'tablet' ? 'selected' : ''}>tablet</option><option value="mL" ${value.unit === 'mL' ? 'selected' : ''}>mL</option><option value="mg" ${value.unit === 'mg' ? 'selected' : ''}>mg</option></select></label></div><label class="field"><span>Maximum doses in any 24 hours</span><input name="maximum" type="number" min="1" step="1" value="${escapeHTML(value.maximum)}" required></label><label class="field"><span>Minimum gap in hours</span><input name="gap" type="number" min="0.001" step="any" value="${escapeHTML(value.gap)}" required></label><label class="confirmation-check"><input type="checkbox" required><span>These details match the instructions I am using.</span></label><button class="primary-action" type="submit">${item ? 'Save changes' : 'Add medicine'}</button></form><p class="boundary-in-app">Existing history keeps its original name, amount and unit when medicine details change.</p>`, { back: item ? 'manage-medicines' : 'choose' });
}
function manageMedicines() {
  const items = activeMedicines(true);
  showSheet('Medicines', `<p class="sheet-copy">Edit future defaults or archive a medicine. Existing history is preserved.</p><div class="manage-list">${items.map(item => `<div class="manage-row ${item.archived ? 'archived' : ''}"><button data-action="edit-medicine" data-id="${item.id}"><span>${medicineHealthIcon(item)}</span><span><strong>${escapeHTML(item.name)}</strong><small>${escapeHTML(item.strength)} · ${escapeHTML(doseText(item))}${item.archived ? ' · archived' : ''}</small></span>${icon('chevron')}</button><button class="manage-action" data-action="${item.archived ? 'restore-medicine' : 'archive-medicine'}" data-id="${item.id}">${item.archived ? 'Restore' : 'Archive'}</button></div>`).join('') || '<p class="empty">No medicines yet.</p>'}</div><button class="primary-action top-gap" data-action="add-medicine">${icon('plus')} Add medicine</button>${boundary()}`);
}
function archiveMedicine(id) {
  selectedMedicineID = id;
  const item = medicine(id);
  showSheet('Archive this medicine?', `<p class="sheet-copy">${escapeHTML(item.name)} will disappear from planning choices. Its history will remain unchanged.</p>${activePlan()?.medicineID === id ? `<div class="warning-box">${icon('clock')}<p><strong>A plan is still waiting.</strong><br>Archiving will cancel that unconfirmed plan.</p></div>` : ''}<button class="primary-action" data-action="confirm-archive">Archive medicine</button><button class="secondary-action top-gap" data-action="manage-medicines">Keep active</button>`);
}
function confirmArchive() {
  const item = medicine(selectedMedicineID);
  if (!item) return;
  item.archived = true; state.plans = state.plans.filter(plan => plan.medicineID !== item.id); render(); manageMedicines(); announce(`${item.name} archived. History preserved.`);
}
function restoreMedicine(id) { const item = medicine(id); if (!item) return; item.archived = false; render(); manageMedicines(); announce(`${item.name} restored.`); }

function profilesSheet() {
  showSheet('Who are you recording for?', `<p class="sheet-copy">Each profile keeps its own medicines, plans and history on this device.</p><div class="profile-list">${state.profiles.map(profile => `<button class="setting-row" data-action="select-profile" data-id="${profile.id}"><span class="avatar-small">${escapeHTML(profile.name[0])}</span><span><strong>${escapeHTML(profile.name)}</strong><small>${profile.id === state.profileID ? 'Active profile' : 'Local profile'}</small></span>${icon(profile.id === state.profileID ? 'check' : 'chevron')}</button>`).join('')}</div><button class="secondary-action top-gap" data-action="add-profile">${icon('plus')} Add person</button>`);
}
function addProfile() { showSheet('Add a person', `<p class="sheet-copy">Use a short name you will recognise. No age or Medical ID is needed for this basic flow.</p><form id="profile-form"><label class="field"><span>Name or nickname</span><input name="name" maxlength="30" required></label><button class="primary-action" type="submit">Add profile</button></form>`, { back: 'profiles' }); }
function selectProfile(id) { if (!state.profiles.some(profile => profile.id === id)) return; state.profileID = id; closeSheet(); navigate('home'); announce(`Now recording for ${activeProfile().name}.`); }

function remindersSheet() {
  const reminders = state.reminders.filter(item => item.profileID === state.profileID);
  showSheet('Local reminders', `<p class="sheet-copy">A reminder opens dot for review. It is not permission to take medicine, and delivery cannot be guaranteed.</p><div class="manage-list">${reminders.map(reminder => { const item = medicine(reminder.medicineID); return `<div class="manage-row"><div class="reminder-row"><span>${icon('bell')}</span><span><strong>${escapeHTML(item?.name || 'Archived medicine')}</strong><small>Daily at ${escapeHTML(reminder.time)} · review prompt</small></span></div><button class="manage-action" data-action="remove-reminder" data-id="${reminder.id}">Remove</button></div>`; }).join('') || '<p class="empty">No reminders added.</p>'}</div><form id="reminder-form"><label class="field"><span>Medicine</span><select name="medicineID">${activeMedicines().map(item => `<option value="${item.id}">${escapeHTML(item.name)}</option>`).join('')}</select></label><label class="field"><span>Daily review time</span><input name="time" type="time" value="09:00" required></label><button class="primary-action" type="submit" ${activeMedicines().length ? '' : 'disabled'}>Add local reminder</button></form>${boundary()}`);
}
function help() {
  showSheet('Concerned about an extra dose?', `<p class="sheet-copy">Get medical advice promptly. Do not wait for symptoms to appear.</p><div class="warning-box">${healthIcon('emergency-post')}<p><strong>United Kingdom</strong><br>If you are unsure whether something swallowed is harmful, call NHS 111. Call 999 for collapse, a seizure or severe breathing problems.</p></div><a class="primary-action" href="tel:111">Call NHS 111</a><a class="secondary-action top-gap" href="tel:999">Call 999</a><p class="boundary-in-app">Keep the medicine packet and details of the amount and time nearby. dot does not contact anyone automatically.</p>`, { label: 'Help · United Kingdom' });
}

const actions = {
  close: closeSheet, done: () => { closeSheet(); navigate('home'); }, tab: navigate, history: () => navigate('history'),
  choose: () => chooseMedicine('plan'), 'record-earlier': () => chooseMedicine('actual'), review: id => reviewMedicine(id), 'review-again': () => reviewMedicine(selectedMedicineID, true),
  'change-plan-amount': changePlanAmount, 'create-plan': createPlan, 'resume-plan': resumePlan, 'confirm-taken': confirmTaken,
  'leave-planned': () => { closeSheet(); navigate('home'); },
  'cancel-plan': () => { const plan = activePlan(); if (plan) state.plans = state.plans.filter(item => item.id !== plan.id); closeSheet(); render(); announce('Plan cancelled. No dose was recorded.'); },
  'history-from-sheet': () => { closeSheet(); navigate('history'); }, 'already-taken': recordAlreadyTaken, 'actual-medicine': recordEarlierMedicine, 'uncertain-dose': uncertainDose,
  entry: openEntry, 'entry-again': () => openEntry(selectedEntryID), 'edit-entry': editEntry, 'remove-entry': removeEntry, 'confirm-remove-entry': confirmRemoveEntry, 'undo-delete': undoDelete,
  'add-medicine': () => medicineForm(), 'edit-medicine': id => medicineForm(medicine(id)), 'manage-medicines': manageMedicines, 'archive-medicine': archiveMedicine, 'confirm-archive': confirmArchive, 'restore-medicine': restoreMedicine,
  profiles: profilesSheet, 'add-profile': addProfile, 'select-profile': selectProfile, reminders: remindersSheet,
  'remove-reminder': id => { state.reminders = state.reminders.filter(item => item.id !== id); render(); remindersSheet(); },
  theme: () => { state.theme = state.theme === 'light' ? 'dark' : 'light'; render(); }, help,
};

document.addEventListener('click', event => { const target = event.target.closest('[data-action]'); if (!target || target.disabled) return; actions[target.dataset.action]?.(target.dataset.id); });
document.addEventListener('submit', event => {
  const form = event.target;
  event.preventDefault();
  if (!form.reportValidity()) return;
  const values = Object.fromEntries(new FormData(form));
  if (form.id === 'plan-amount-form') {
    planAmount = Number(values.amount); reviewMedicine(selectedMedicineID, true);
  } else if (form.id === 'actual-form' || form.id === 'uncertain-form') {
    const item = medicine(selectedMedicineID); const time = new Date(values.time).getTime();
    if (!item || !Number.isFinite(time) || time > Date.now()) return;
    const log = makeLog(item, time, Number(values.amount), values.unit, form.id === 'uncertain-form' ? 'uncertain' : 'confirmed');
    state.logs.push(log); render();
    if (log.status === 'uncertain') { closeSheet(); navigate('history'); announce('Uncertain dose saved. It is not counted as confirmed.'); } else showConfirmation(log);
  } else if (form.id === 'entry-form') {
    const log = activeLogs().find(item => item.id === selectedEntryID); const time = new Date(values.time).getTime();
    if (!log || !Number.isFinite(time) || time > Date.now()) return;
    log.amount = Number(values.amount); log.unit = values.unit; log.time = time; if (values.confirm === 'on') log.status = 'confirmed'; log.correctedAt = Date.now();
    render(); showConfirmation(log, true); announce('Record corrected. Rolling 24-hour view updated.');
  } else if (form.id === 'medicine-form') {
    const maximum = Number(values.maximum), gap = Number(values.gap), amount = Number(values.amount);
    if (!Number.isInteger(maximum) || maximum < 1 || !Number.isFinite(gap) || gap <= 0 || !Number.isFinite(amount) || amount <= 0) return;
    let item = medicine(selectedMedicineID);
    if (item && $('#sheet-title').textContent === 'Edit medicine') {
      Object.assign(item, { name: values.name.trim(), strength: values.strength.trim(), amount, unit: values.unit, maximum, gap }); render(); manageMedicines(); announce('Medicine details updated. Existing history unchanged.');
    } else {
      item = { id: crypto.randomUUID(), profileID: state.profileID, name: values.name.trim(), strength: values.strength.trim(), amount, unit: values.unit, maximum, gap, archived: false };
      state.medicines.push(item); selectedMedicineID = item.id; planAmount = item.amount; render();
      showSheet('Medicine added', `<div class="plan-symbol">${icon('check')}</div><p class="sheet-copy large-copy"><strong>${escapeHTML(item.name)}</strong><br>${escapeHTML(item.strength)} · ${escapeHTML(doseText(item))}</p><div class="warning-box">${icon('info')}<p><strong>No history exists yet.</strong><br>This does not prove that no doses were taken before the medicine was added.</p></div><button class="primary-action" data-action="review" data-id="${item.id}">Review and plan a dose</button><button class="quiet-action" data-action="done">Done for now</button>`);
    }
  } else if (form.id === 'profile-form') {
    const name = values.name.trim(); if (!name || state.profiles.some(profile => profile.name.toLocaleLowerCase() === name.toLocaleLowerCase())) return;
    const profile = { id: crypto.randomUUID(), name }; state.profiles.push(profile); state.profileID = profile.id; render(); closeSheet(); navigate('home'); announce(`Profile added for ${name}.`);
  } else if (form.id === 'reminder-form') {
    state.reminders.push({ id: crypto.randomUUID(), profileID: state.profileID, medicineID: values.medicineID, time: values.time }); render(); remindersSheet(); announce('Local reminder added in this prototype.');
  }
});
$('#sheet').addEventListener('cancel', event => { event.preventDefault(); closeSheet(); });

function setPlatform(platform) { state.platform = platform; const url = new URL(location.href); url.searchParams.set('platform', platform); history.replaceState({}, '', url); render(); announce(`${platform === 'ios' ? 'iOS' : 'Android'} prototype selected.`); }
$$('.platform-control button').forEach(button => button.addEventListener('click', () => setPlatform(button.dataset.platformChoice)));
$('#scenario').addEventListener('change', event => { const url = new URL(location.href); url.searchParams.set('scenario', event.target.value); history.replaceState({}, '', url); reset(event.target.value); });
$('#reset-demo').addEventListener('click', () => reset(state.scenario));

reset();
