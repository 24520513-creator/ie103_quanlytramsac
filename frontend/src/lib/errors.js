// Turn raw thrown errors into messages safe to show end users.
// Server-provided Vietnamese messages pass through; low-level/technical
// errors (network, JSON parse, SQL/stack leaks) get a friendly fallback.

const TECHNICAL_HINTS = [
  'failed to fetch', 'networkerror', 'load failed', 'econnrefused', 'err_connection',
  'unexpected token', 'json', 'sqlstate', 'constraint', 'violation', 'undefined is not',
  'cannot read', 'syntaxerror', 'typeerror', '<!doctype', 'timeout'
];

export function friendlyError(error) {
  const raw = (error && error.message ? error.message : String(error || '')).trim();
  if (!raw) return 'Có lỗi xảy ra, vui lòng thử lại.';

  const lower = raw.toLowerCase();

  if (lower.includes('failed to fetch') || lower.includes('networkerror') || lower.includes('load failed')) {
    return 'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.';
  }
  if (lower.includes('unexpected token') || (lower.includes('json') && lower.includes('parse'))) {
    return 'Dữ liệu nhập không đúng định dạng.';
  }
  // Anything that looks like a leaked technical/stack message → generic.
  if (TECHNICAL_HINTS.some((hint) => lower.includes(hint))) {
    return 'Có lỗi xảy ra, vui lòng thử lại.';
  }
  // Otherwise the server message is already user-facing.
  return raw;
}
