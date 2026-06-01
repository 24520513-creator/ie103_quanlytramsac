import React, { useEffect, useId, useRef } from 'react';
import { CloseIcon, SearchIcon, SpinnerIcon, ChevronLeftIcon, ChevronRightIcon } from '../Icons';
import { statusClass, formatValue } from '../../lib/format';

/* ------------------------------ Buttons ------------------------------ */
export function Button({ variant = 'primary', icon, children, className = '', ...rest }) {
  return (
    <button className={`ui-btn ui-btn-${variant} ${className}`} {...rest}>
      {icon}
      {children && <span>{children}</span>}
    </button>
  );
}

/* ------------------------------ Section header ------------------------------ */
export function PageHeader({ icon, title, subtitle, actions }) {
  return (
    <div className="ui-pageHeader">
      <div className="ui-pageHeader-main">
        {icon && <span className="ui-pageHeader-icon">{icon}</span>}
        <div>
          <h1>{title}</h1>
          {subtitle && <p>{subtitle}</p>}
        </div>
      </div>
      {actions && <div className="ui-pageHeader-actions">{actions}</div>}
    </div>
  );
}

/* ------------------------------ Card ------------------------------ */
export function Card({ children, className = '', as: Tag = 'div', ...rest }) {
  return <Tag className={`ui-card ${className}`} {...rest}>{children}</Tag>;
}

export function CardHeader({ title, subtitle, action }) {
  return (
    <div className="ui-card-header">
      <div>
        <h3>{title}</h3>
        {subtitle && <span>{subtitle}</span>}
      </div>
      {action}
    </div>
  );
}

/* ------------------------------ Stat tile ------------------------------ */
export function StatTile({ icon, label, value, unit, accent = 'brand', hint }) {
  return (
    <article className={`ui-stat ui-stat-${accent}`}>
      <div className="ui-stat-top">
        <span className="ui-stat-label">{label}</span>
        {icon && <span className="ui-stat-icon">{icon}</span>}
      </div>
      <strong className="ui-stat-value">{value}{unit && <em>{unit}</em>}</strong>
      {hint && <small className="ui-stat-hint">{hint}</small>}
    </article>
  );
}

/* ------------------------------ Badge ------------------------------ */
export function Badge({ value, tone }) {
  return <span className={`chip ${tone || statusClass(value)}`}>{String(value)}</span>;
}

/* ------------------------------ Empty / Loader ------------------------------ */
export function EmptyState({ icon, title = 'Không có dữ liệu', message }) {
  return (
    <div className="ui-empty">
      {icon && <span className="ui-empty-icon">{icon}</span>}
      <strong>{title}</strong>
      {message && <p>{message}</p>}
    </div>
  );
}

export function Loader({ label = 'Đang tải...' }) {
  return <div className="ui-loader"><SpinnerIcon size={18} /><span>{label}</span></div>;
}

/* ------------------------------ Modal ------------------------------ */
const FOCUSABLE = 'a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])';

export function Modal({ open, title, subtitle, onClose, children, footer, wide = false }) {
  const titleId = useId();
  const panelRef = useRef(null);
  // Tracks whether a pointer press *started* on the overlay, so dragging a text
  // selection out of the dialog never closes it (only a clean overlay click does).
  const downOnOverlay = useRef(false);

  // Escape to close + focus trap (Tab cycles within the dialog).
  useEffect(() => {
    if (!open) return undefined;
    const onKey = (e) => {
      if (e.key === 'Escape') { onClose?.(); return; }
      if (e.key !== 'Tab') return;
      const nodes = panelRef.current?.querySelectorAll(FOCUSABLE);
      if (!nodes || !nodes.length) return;
      const list = Array.from(nodes);
      const first = list[0];
      const last = list[list.length - 1];
      const activeEl = document.activeElement;
      if (e.shiftKey && (activeEl === first || !panelRef.current.contains(activeEl))) {
        e.preventDefault(); last.focus();
      } else if (!e.shiftKey && activeEl === last) {
        e.preventDefault(); first.focus();
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open, onClose]);

  // Move focus into the dialog and lock background scroll while open.
  useEffect(() => {
    if (!open) return undefined;
    const previouslyFocused = document.activeElement;
    const node = panelRef.current?.querySelector(FOCUSABLE) || panelRef.current;
    node?.focus?.();
    const prevOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = prevOverflow;
      if (previouslyFocused instanceof HTMLElement) previouslyFocused.focus();
    };
  }, [open]);

  if (!open) return null;
  return (
    <div
      className="ui-modal-overlay"
      onMouseDown={(e) => { downOnOverlay.current = e.target === e.currentTarget; }}
      onMouseUp={(e) => { if (downOnOverlay.current && e.target === e.currentTarget) onClose?.(); downOnOverlay.current = false; }}
    >
      <div
        ref={panelRef}
        className={`ui-modal ${wide ? 'ui-modal-wide' : ''}`}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        tabIndex={-1}
      >
        <div className="ui-modal-head">
          <div>
            <h3 id={titleId}>{title}</h3>
            {subtitle && <p>{subtitle}</p>}
          </div>
          <button className="ui-iconbtn" onClick={onClose} aria-label="Đóng"><CloseIcon size={18} /></button>
        </div>
        <div className="ui-modal-body">{children}</div>
        {footer && <div className="ui-modal-foot">{footer}</div>}
      </div>
    </div>
  );
}

/* ------------------------------ Tabs ------------------------------ */
export function Tabs({ tabs, active, onChange }) {
  return (
    <div className="ui-tabs">
      {tabs.map((tab) => (
        <button key={tab.id} className={active === tab.id ? 'active' : ''} onClick={() => onChange(tab.id)}>
          {tab.icon}{tab.label}
        </button>
      ))}
    </div>
  );
}

/* ------------------------------ Search ------------------------------ */
export function SearchInput({ value, onChange, onSubmit, placeholder = 'Tìm kiếm...' }) {
  return (
    <div className="ui-search">
      <SearchIcon size={18} className="ui-search-icon" />
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        onKeyDown={(e) => { if (e.key === 'Enter') onSubmit?.(); }}
        placeholder={placeholder}
      />
    </div>
  );
}

/* ------------------------------ Progress ring ------------------------------ */
export function ProgressRing({ value = 0, max = 100, size = 132, label, sub }) {
  const pct = max > 0 ? Math.min(Math.max(value / max, 0), 1) : 0;
  const stroke = 11;
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  return (
    <div className="ui-ring" style={{ width: size, height: size }}>
      <svg width={size} height={size}>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="#e6ebf2" strokeWidth={stroke} />
        <circle
          cx={size / 2} cy={size / 2} r={r} fill="none" stroke="url(#ringGrad)" strokeWidth={stroke}
          strokeLinecap="round" strokeDasharray={c} strokeDashoffset={c * (1 - pct)}
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
        <defs>
          <linearGradient id="ringGrad" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor="#10b981" />
            <stop offset="100%" stopColor="#06b6d4" />
          </linearGradient>
        </defs>
      </svg>
      <div className="ui-ring-center">
        <strong>{label}</strong>
        {sub && <span>{sub}</span>}
      </div>
    </div>
  );
}

/* ------------------------------ Data table (upgraded) ------------------------------ */
export function DataTable({ columns, rows, renderCell, page, totalPages, onPage, meta }) {
  return (
    <div className="tableSection">
      {meta && (
        <div className="tableMeta">
          <span>{meta.left}</span>
          <span>{meta.right}</span>
        </div>
      )}
      <div className="tableWrap">
        <table>
          <thead><tr>{columns.map((c) => <th key={c}>{c}</th>)}</tr></thead>
          <tbody>
            {rows.length === 0 ? (
              <tr><td colSpan={columns.length || 1} className="empty">Không có dữ liệu.</td></tr>
            ) : rows.map((row, i) => (
              <tr key={i}>{columns.map((c) => <td key={c}>{renderCell ? renderCell(c, row[c], row) : formatValue(row[c])}</td>)}</tr>
            ))}
          </tbody>
        </table>
      </div>
      {onPage && (
        <div className="pager">
          <button disabled={page <= 1} onClick={() => onPage(page - 1)}><ChevronLeftIcon size={16} />Trang trước</button>
          <button disabled={page >= (totalPages || 1)} onClick={() => onPage(page + 1)}>Trang sau<ChevronRightIcon size={16} /></button>
        </div>
      )}
    </div>
  );
}
