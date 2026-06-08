import { linkifyPhones, formatPhoneIMessage } from "./phone.js";
import { icons } from "./icons.js";

/** @typedef {'text' | 'image' | 'both'} ContentMode */

const DEFAULT_BODY = `17336282609
17745000944
17368198705
18093344383
18010673728`;

const state = {
  view: "home",
  imessageOpen: false,
  mode: /** @type {ContentMode} */ ("text"),
  messageText: "你好老婆",
  messageImageUrl: null,
  selectedPhone: null,
  noteDate: "2026年6月4日 20:24",
  noteTitle: "0604 媛-500-18",
  noteBody: DEFAULT_BODY,
};

const $ = (sel, root = document) => root.querySelector(sel);

const IMESSAGE_MS = 450;

function updateClock() {
  const el = $("#statusTime");
  if (!el) return;
  const now = new Date();
  el.textContent = now.toLocaleTimeString("zh-CN", {
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
}

function getMessagePayload() {
  const { mode, messageText, messageImageUrl } = state;
  if (mode === "text") return { text: messageText.trim() || "你好老婆", image: null };
  if (mode === "image") return { text: null, image: messageImageUrl };
  return { text: messageText.trim() || null, image: messageImageUrl };
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function setDeviceChrome() {
  const device = $("#device");
  if (!device) return;
  const inNotes = state.view === "notes";
  device.classList.toggle("chrome-notes", inNotes && !state.imessageOpen);
  device.classList.toggle("chrome-imessage", state.imessageOpen);
}

function render() {
  const app = $("#app");
  if (!app) return;

  hidePhoneMenu();

  if (state.view === "home") app.innerHTML = renderHome();
  else if (state.view === "notes") app.innerHTML = renderNotes();

  setDeviceChrome();
  bindViewEvents();
}

function renderHome() {
  const { mode, messageText, messageImageUrl } = state;
  const textPanel =
    mode === "text" || mode === "both"
      ? `<textarea id="messageText" placeholder="iMessage 气泡文字，如：你好老婆">${escapeHtml(messageText)}</textarea>`
      : "";
  const imagePanel =
    mode === "image" || mode === "both"
      ? `
    <div class="image-picker">
      <label class="image-picker-label">
        <input type="file" id="messageImage" accept="image/*" />
        ${messageImageUrl ? "更换图片" : "选择图片"}
      </label>
      ${messageImageUrl ? `<div class="image-preview"><img src="${messageImageUrl}" alt="" /></div>` : ""}
    </div>`
      : "";

  return `
    <div class="view-home">
      <div class="home-header">
        <h1>演示控制台</h1>
        <p>配置 iMessage 内容；备忘录内标题、日期、号码均可直接改。</p>
      </div>
      <div class="home-section">
        <p class="home-section-label">模式选择</p>
        <div class="mode-segment">
          <button type="button" data-mode="text" class="${mode === "text" ? "active" : ""}">1 纯文</button>
          <button type="button" data-mode="image" class="${mode === "image" ? "active" : ""}">2 图片</button>
          <button type="button" data-mode="both" class="${mode === "both" ? "active" : ""}">3 图文</button>
        </div>
        <div class="mode-panel">${textPanel}${imagePanel}</div>
      </div>
      <div class="home-actions">
        <button type="button" class="btn-ios btn-notes" id="openNotes">
          <span class="btn-notes-icon">📝</span>
          模拟备忘录
        </button>
      </div>
    </div>`;
}

function renderNotes() {
  const bodyHtml = linkifyPhones(state.noteBody);
  return `
    <div class="view-notes" id="viewNotes">
      <nav class="notes-nav">
        <button type="button" class="notes-nav-back" id="notesBack" aria-label="返回">${icons.chevronLeft}</button>
        <div class="notes-nav-actions">
          <button type="button" class="notes-nav-btn" aria-label="共享">${icons.squareAndArrowUp}</button>
          <button type="button" class="notes-nav-btn" aria-label="更多">${icons.ellipsisCircle}</button>
        </div>
      </nav>
      <div class="notes-scroll">
        <div class="notes-date" id="notesDate" contenteditable="true">${escapeHtml(state.noteDate)}</div>
        <div class="notes-title" id="notesTitle" contenteditable="true">${escapeHtml(state.noteTitle)}</div>
        <div class="notes-body" id="notesBody" contenteditable="true" spellcheck="false">${bodyHtml}</div>
      </div>
      <footer class="notes-bottom-bar">
        <div class="notes-tool-pill">
          <button type="button" class="notes-tool-btn" aria-label="清单">${icons.checklist}</button>
          <button type="button" class="notes-tool-btn" aria-label="表格">${icons.tablecells}</button>
          <button type="button" class="notes-tool-btn" aria-label="附件">${icons.paperclip}</button>
          <button type="button" class="notes-tool-btn" aria-label="涂鸦">${icons.pencilTip}</button>
        </div>
        <button type="button" class="notes-new-btn" aria-label="新建备忘录">${icons.squareAndPencil}</button>
      </footer>
    </div>`;
}

function renderIMessageMarkup() {
  const phone = state.selectedPhone || "15580045133";
  const recipient = formatPhoneIMessage(phone);
  const { text, image } = getMessagePayload();
  const now = new Date();
  const timeLabel = now.toLocaleTimeString("zh-CN", {
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });

  let bubble = "";
  if (text) {
    bubble += `
      <div class="imessage-bubble-wrap">
        <div class="imessage-bubble">${escapeHtml(text)}</div>
        <span class="imessage-delivered">已送达</span>
      </div>`;
  }
  if (image) {
    bubble += `
      <div class="imessage-bubble-wrap">
        <div class="imessage-bubble image-bubble"><img src="${image}" alt="" /></div>
        <span class="imessage-delivered">已送达</span>
      </div>`;
  }

  return `
    <div class="imessage-scrim" id="imessageScrim" data-action="imessage-dismiss"></div>
    <div class="view-imessage" id="viewIMessage">
      <header class="imessage-header">
        <h1>新 iMessage 信息</h1>
        <button type="button" class="imessage-close" id="imessageClose" aria-label="关闭">${icons.xmark}</button>
      </header>
      <div class="imessage-address">
        <div class="imessage-address-row">
          <span class="label">收件人：</span>
          <span class="imessage-pill">${escapeHtml(recipient)}</span>
        </div>
        <div class="imessage-address-row">
          <span class="label">发件人：</span>
          <span class="imessage-sender-badge">
            <span class="badge-icon">副</span>副号
          </span>
        </div>
      </div>
      <div class="imessage-thread">
        <div class="imessage-thread-meta">iMessage 信息<br />今天 ${timeLabel}</div>
        ${bubble}
      </div>
      <div class="imessage-input-bar">
        <button type="button" class="imessage-input-plus" disabled>+</button>
        <div class="imessage-input-field">
          iMessage 信息
          <span class="imessage-input-mic"></span>
        </div>
      </div>
      <div class="imessage-keyboard" aria-hidden="true">
        <div class="kb-suggest">
          <span>我</span><span>你</span><span>信息</span><span>好</span><span>这</span><span>是</span><span>不</span>
        </div>
        <div class="kb-grid">
          <button class="kb-key" type="button" tabindex="-1">，<small>分词</small></button>
          <button class="kb-key" type="button" tabindex="-1">。!<small>ABC</small></button>
          <button class="kb-key" type="button" tabindex="-1">?<small>DEF</small></button>
          <button class="kb-key kb-return" type="button" tabindex="-1">↵</button>
          <button class="kb-key" type="button" tabindex="-1">A<small>GHI</small></button>
          <button class="kb-key" type="button" tabindex="-1">B<small>JKL</small></button>
          <button class="kb-key" type="button" tabindex="-1">C<small>MNO</small></button>
          <button class="kb-key" type="button" tabindex="-1">D<small>PQRS</small></button>
          <button class="kb-key" type="button" tabindex="-1">E<small>TUV</small></button>
          <button class="kb-key" type="button" tabindex="-1">F<small>WXYZ</small></button>
        </div>
        <div class="kb-bottom">
          <button class="kb-key gray" type="button" tabindex="-1">🌐</button>
          <button class="kb-key gray" type="button" tabindex="-1">选拼音</button>
          <button class="kb-key space" type="button" tabindex="-1">空格</button>
          <button class="kb-key gray" type="button" tabindex="-1">🎤</button>
        </div>
      </div>
    </div>`;
}

function openIMessage() {
  if (state.imessageOpen) return;
  const host = $("#imessageSheet");
  if (!host) return;

  persistNoteFields();
  state.imessageOpen = true;
  setDeviceChrome();

  host.innerHTML = renderIMessageMarkup();
  host.setAttribute("aria-hidden", "false");

  const scrim = $("#imessageScrim", host);
  const sheet = $("#viewIMessage", host);

  bindIMessageEvents();

  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      scrim?.classList.add("is-visible");
      sheet?.classList.add("is-visible");
    });
  });
}

function closeIMessage() {
  if (!state.imessageOpen) return;
  const host = $("#imessageSheet");
  const sheet = $("#viewIMessage", host);
  const scrim = $("#imessageScrim", host);
  if (!host || !sheet) return;

  sheet.classList.remove("is-visible");
  sheet.classList.add("is-closing");
  scrim?.classList.remove("is-visible");

  const finish = () => {
    host.innerHTML = "";
    host.setAttribute("aria-hidden", "true");
    state.imessageOpen = false;
    setDeviceChrome();
    sheet.removeEventListener("transitionend", finish);
  };

  sheet.addEventListener("transitionend", (e) => {
    if (e.propertyName === "transform") finish();
  });

  setTimeout(finish, IMESSAGE_MS + 80);
}

function bindIMessageEvents() {
  $("#imessageClose")?.addEventListener("click", closeIMessage);
  $("#imessageScrim")?.addEventListener("click", closeIMessage);
}

function persistNoteFields() {
  const date = $("#notesDate");
  const title = $("#notesTitle");
  const body = $("#notesBody");
  if (date) state.noteDate = date.innerText.trim() || state.noteDate;
  if (title) state.noteTitle = title.innerText.trim() || state.noteTitle;
  if (body) state.noteBody = body.innerText || "";
}

function syncNoteBody(linkify = true) {
  const body = $("#notesBody");
  if (!body) return;
  state.noteBody = body.innerText || "";
  if (linkify) body.innerHTML = linkifyPhones(state.noteBody) || "";
}

function bindViewEvents() {
  document.querySelectorAll(".mode-segment button").forEach((btn) => {
    btn.addEventListener("click", () => {
      state.mode = btn.dataset.mode;
      render();
    });
  });

  $("#messageText")?.addEventListener("input", (e) => {
    state.messageText = e.target.value;
  });

  $("#messageImage")?.addEventListener("change", (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      state.messageImageUrl = reader.result;
      render();
    };
    reader.readAsDataURL(file);
  });

  $("#openNotes")?.addEventListener("click", () => {
    closeIMessage();
    state.view = "notes";
    render();
    bindNotesInteractions();
  });

  $("#notesBack")?.addEventListener("click", () => {
    closeIMessage();
    persistNoteFields();
    hidePhoneMenu();
    state.view = "home";
    render();
  });

  if (state.view === "notes") bindNotesInteractions();
  bindPhoneMenu();
}

function bindNotesInteractions() {
  const date = $("#notesDate");
  const title = $("#notesTitle");
  const body = $("#notesBody");

  date?.addEventListener("input", () => {
    state.noteDate = date.innerText.trim();
  });
  title?.addEventListener("input", () => {
    state.noteTitle = title.innerText.trim();
  });

  body?.addEventListener("input", () => syncNoteBody(false));
  body?.addEventListener("blur", () => syncNoteBody(true));
  body?.addEventListener("paste", (e) => {
    e.preventDefault();
    const text = e.clipboardData?.getData("text/plain") ?? "";
    document.execCommand("insertText", false, text);
    requestAnimationFrame(() => syncNoteBody(true));
  });

  bindPhoneLongPress();
}

function bindPhoneLongPress() {
  const body = $("#notesBody");
  if (!body || body.dataset.phoneBound) return;
  body.dataset.phoneBound = "1";

  let timer = null;

  const clear = () => {
    if (timer) clearTimeout(timer);
    timer = null;
  };

  const startPress = (link) => {
    timer = setTimeout(() => showPhoneMenu(link), 420);
  };

  body.addEventListener("touchstart", (e) => {
    const link = e.target.closest?.(".phone-link");
    if (!link) return;
    startPress(link);
  }, { passive: true });
  body.addEventListener("touchend", clear);
  body.addEventListener("touchmove", clear);

  body.addEventListener("mousedown", (e) => {
    const link = e.target.closest?.(".phone-link");
    if (!link) return;
    startPress(link);
  });
  body.addEventListener("mouseup", clear);

  body.addEventListener("contextmenu", (e) => {
    const link = e.target.closest?.(".phone-link");
    if (link) {
      e.preventDefault();
      showPhoneMenu(link);
    }
  });
}

function showPhoneMenu(linkEl) {
  persistNoteFields();
  const phone = linkEl.dataset.phone;
  if (!phone) return;

  state.selectedPhone = phone;

  const menu = $("#phoneMenu");
  const phoneHeader = $("#phoneMenuPhone");
  const chip = $("#phoneSelectionChip");
  const card = $("#phoneMenuCard");
  const device = $("#device");
  const viewNotes = $("#viewNotes");

  if (!menu || !chip || !card || !device) return;

  document.querySelectorAll(".phone-link.is-pressed").forEach((el) => el.classList.remove("is-pressed"));
  linkEl.classList.add("is-pressed");
  viewNotes?.classList.add("is-menu-open");

  if (phoneHeader) phoneHeader.textContent = phone;
  chip.textContent = phone;

  menu.classList.remove("hidden");
  menu.setAttribute("aria-hidden", "false");

  const deviceRect = device.getBoundingClientRect();
  const linkRect = linkEl.getBoundingClientRect();
  const top = linkRect.top - deviceRect.top;
  const left = linkRect.left - deviceRect.left;
  const menuTop = top + linkRect.height + 10;

  chip.style.top = `${top}px`;
  chip.style.left = `${left}px`;
  card.style.top = `${Math.min(menuTop, deviceRect.height - 360)}px`;
}

function hidePhoneMenu() {
  const menu = $("#phoneMenu");
  menu?.classList.add("hidden");
  menu?.setAttribute("aria-hidden", "true");
  $("#viewNotes")?.classList.remove("is-menu-open");
  document.querySelectorAll(".phone-link.is-pressed").forEach((el) => el.classList.remove("is-pressed"));
}

function bindPhoneMenu() {
  const menu = $("#phoneMenu");
  if (!menu || menu.dataset.bound) return;
  menu.dataset.bound = "1";

  menu.addEventListener("click", (e) => {
    const row = e.target.closest("[data-action]");
    if (!row) return;
    const action = row.dataset.action;

    if (action === "dismiss") {
      hidePhoneMenu();
      return;
    }
    if (action === "copy" && state.selectedPhone) {
      navigator.clipboard?.writeText(state.selectedPhone);
      hidePhoneMenu();
      return;
    }
    if (action === "message") {
      hidePhoneMenu();
      openIMessage();
      return;
    }
    if (action === "noop") hidePhoneMenu();
  });
}

updateClock();
setInterval(updateClock, 30000);
render();
