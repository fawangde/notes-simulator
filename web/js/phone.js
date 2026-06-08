/** 中国大陆 11 位手机号 */
export const PHONE_RE = /1[3-9]\d{9}/g;

export function formatPhoneIMessage(phone) {
  if (!phone || phone.length !== 11) return phone;
  return `+86 ${phone.slice(0, 3)} ${phone.slice(3, 7)} ${phone.slice(7)}`;
}

export function linkifyPhones(text) {
  if (!text) return "";
  const escaped = text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");

  return escaped.replace(PHONE_RE, (num) => {
    return `<span class="phone-link" data-phone="${num}" role="button" tabindex="0">${num}</span>`;
  });
}
