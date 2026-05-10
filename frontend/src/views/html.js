export function escapeHtml(value = '') {
  return String(value).replace(/[&<>"]/g, (char) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
  }[char]));
}

export function page(content, extraClass = '') {
  return `<main class="page ${extraClass}">${content}</main>`;
}
