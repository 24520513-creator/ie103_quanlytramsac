const numberFmt = new Intl.NumberFormat('vi-VN');
const vndFmt = new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 });

const ISO = /^\d{4}-\d{2}-\d{2}T/;

export function formatValue(value) {
  if (value === null || value === undefined) return '';
  if (typeof value === 'number') return numberFmt.format(value);
  if (typeof value === 'string' && ISO.test(value)) return new Date(value).toLocaleString('vi-VN');
  return String(value);
}

export function formatVND(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return '0 ₫';
  return vndFmt.format(n);
}

export function formatNumber(value) {
  const n = Number(value);
  return Number.isFinite(n) ? numberFmt.format(n) : String(value ?? '');
}

export function formatDate(value, withTime = true) {
  if (!value) return '';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return String(value);
  return withTime ? d.toLocaleString('vi-VN') : d.toLocaleDateString('vi-VN');
}

export function statusClass(value) {
  const text = String(value ?? '').toLowerCase();
  if (['active', 'available', 'completed', 'paid', 'approved', 'normal', 'resolved', 'closed', 'true', '1'].some((i) => text.includes(i))) return 'ok';
  if (['pending', 'reserved', 'charging', 'open', 'assigned', 'inprogress', 'issued', 'draft'].some((i) => text.includes(i))) return 'info';
  if (['warning', 'maintenance', 'undermaintenance'].some((i) => text.includes(i))) return 'warn';
  if (['failed', 'error', 'critical', 'offline', 'locked', 'suspended', 'refunded', 'cancelled', 'retired', 'false', '0'].some((i) => text.includes(i))) return 'bad';
  return 'muted';
}

export function getInitials(value = '') {
  return String(value)
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() || '')
    .join('') || 'EV';
}

/** Heuristic: should this column render as a status badge? */
export function isStatusColumn(column) {
  return /status|trạng|health|active|isactive/i.test(column);
}
