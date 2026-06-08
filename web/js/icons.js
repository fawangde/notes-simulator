/** SF Symbols 风格图标（与 iOS 备忘录工具栏/导航一致） */
const S = (path, viewBox = "0 0 24 24", fill = "none") =>
  `<svg class="sf-icon" viewBox="${viewBox}" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" fill="${fill}">${path}</svg>`;

export const icons = {
  chevronLeft: S(
    `<path fill="currentColor" d="M14.5 5.5 8 12l6.5 6.5-1.4 1.4L5.2 12l7.9-7.9z"/>`
  ),
  squareAndArrowUp: S(
    `<path stroke="currentColor" stroke-width="1.65" stroke-linecap="round" stroke-linejoin="round" d="M8.5 4.5h11v11M17 9.5 12 4.5 7 9.5M6.5 19.5h11"/>`
  ),
  ellipsisCircle: S(
    `<circle cx="12" cy="12" r="9.25" stroke="currentColor" stroke-width="1.65"/><circle cx="8.2" cy="12" r="1.1" fill="currentColor"/><circle cx="12" cy="12" r="1.1" fill="currentColor"/><circle cx="15.8" cy="12" r="1.1" fill="currentColor"/>`
  ),
  checklist: S(
    `<circle cx="6.5" cy="7" r="3.25" stroke="currentColor" stroke-width="1.55"/><path stroke="currentColor" stroke-width="1.55" stroke-linecap="round" d="M5 7l1 1 2-2"/><path stroke="currentColor" stroke-width="1.55" stroke-linecap="round" d="M11 6.5h8M11 12h8M11 17.5h8"/>`
  ),
  tablecells: S(
    `<rect x="4" y="4" width="7" height="7" rx="1.6" stroke="currentColor" stroke-width="1.55"/><rect x="13" y="4" width="7" height="7" rx="1.6" stroke="currentColor" stroke-width="1.55"/><rect x="4" y="13" width="7" height="7" rx="1.6" stroke="currentColor" stroke-width="1.55"/><rect x="13" y="13" width="7" height="7" rx="1.6" stroke="currentColor" stroke-width="1.55"/>`
  ),
  paperclip: S(
    `<path stroke="currentColor" stroke-width="1.55" stroke-linecap="round" d="M8.5 13.5c0-2.5 2-4.5 4.5-4.5s4.5 2 4.5 4.5-2 4.5-4.5 4.5H10c-1.7 0-3-1.3-3-3s1.3-3 3-3h5"/>`
  ),
  pencilTip: S(
    `<circle cx="12" cy="12" r="9.25" stroke="currentColor" stroke-width="1.55"/><path stroke="currentColor" stroke-width="1.55" stroke-linecap="round" d="M8 15.5l8-8"/><path stroke="currentColor" stroke-width="1.55" stroke-linecap="round" d="M13 7.5l3.5 3.5"/>`
  ),
  squareAndPencil: S(
    `<rect x="5" y="3.5" width="13.5" height="17" rx="2.2" stroke="currentColor" stroke-width="1.55"/><path stroke="currentColor" stroke-width="1.55" stroke-linecap="round" d="M9 8.5h7M12 11.5v6"/><path stroke="currentColor" stroke-width="1.55" stroke-linecap="round" d="M14.5 14.5 17 17"/>`
  ),
  xmark: S(
    `<path stroke="currentColor" stroke-width="1.8" stroke-linecap="round" d="M8 8l8 8M16 8l-8 8"/>`
  ),
};
