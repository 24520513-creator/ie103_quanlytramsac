import React, { useMemo, useState } from 'react';
import { useActionData } from '../lib/useAction';
import { runAction, downloadReportPdf, downloadCsv } from '../lib/api';
import { formatValue, formatNumber, isStatusColumn } from '../lib/format';
import { Modal, Loader, EmptyState, StatTile, Badge, DataTable, Button, Card, CardHeader } from '../components/ui';
import { ActionForm } from '../components/ui/ActionForm';
import { friendlyError } from '../lib/errors';
import { BoltIcon, TrendingUpIcon, ActivityIcon, CheckIcon, DownloadIcon } from '../components/Icons';

const STAT_ICONS = [<BoltIcon size={18} />, <TrendingUpIcon size={18} />, <CheckIcon size={18} />, <ActivityIcon size={18} />];
const ACCENTS = ['brand', 'info', 'warn', 'bad'];
const RANGE_OPTIONS = [
  { value: 'all', label: 'Tất cả' },
  { value: 'today', label: 'Hôm nay', days: 0 },
  { value: '3d', label: '3 ngày', days: 2 },
  { value: '7d', label: '1 tuần', days: 6 },
  { value: '1m', label: '1 tháng', months: 1 },
  { value: '3m', label: '3 tháng', months: 3 },
  { value: '6m', label: '6 tháng', months: 6 },
  { value: '1y', label: '1 năm', years: 1 },
  { value: '2y', label: '2 năm', years: 2 },
  { value: 'custom', label: 'Tùy chỉnh' }
];

function toIsoDate(date) {
  const copy = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
  return copy.toISOString().slice(0, 10);
}

function rangeFromPreset(value) {
  if (value === 'all') return {};
  const preset = RANGE_OPTIONS.find((item) => item.value === value);
  if (!preset || value === 'custom') return null;
  const end = new Date();
  const start = new Date(end);
  if (preset.days != null) start.setDate(end.getDate() - preset.days);
  if (preset.months) start.setMonth(end.getMonth() - preset.months);
  if (preset.years) start.setFullYear(end.getFullYear() - preset.years);
  return { FromDate: toIsoDate(start), ToDate: toIsoDate(end) };
}

function DateRangeControls({ value, onChange, compact = false }) {
  const [preset, setPreset] = useState('all');

  function applyPreset(nextPreset) {
    setPreset(nextPreset);
    const nextRange = rangeFromPreset(nextPreset);
    if (nextRange) onChange(nextRange);
    if (nextPreset === 'all') onChange({});
  }

  function updateCustom(key, nextValue) {
    setPreset('custom');
    onChange({ ...value, [key]: nextValue || undefined });
  }

  return (
    <div className={`date-range-controls${compact ? ' date-range-controls-compact' : ''}`}>
      <select value={preset} onChange={(event) => applyPreset(event.target.value)} aria-label="Khoảng thời gian">
        {RANGE_OPTIONS.map((item) => <option key={item.value} value={item.value}>{item.label}</option>)}
      </select>
      <input type="date" value={value.FromDate || ''} onChange={(event) => updateCustom('FromDate', event.target.value)} aria-label="Từ ngày" />
      <input type="date" value={value.ToDate || ''} onChange={(event) => updateCustom('ToDate', event.target.value)} aria-label="Đến ngày" />
    </div>
  );
}

/** Renders KPI tiles from a dashboard action returning ChiSo/GiaTri/DonVi rows. */
export function DashboardStats({ actionId, token, accents }) {
  const [range, setRange] = useState({});
  const requestBody = useMemo(() => ({ ...range }), [range]);
  const { rows, loading } = useActionData(actionId, { token, body: requestBody });
  if (loading) return <Loader />;
  if (!rows.length) return <EmptyState title="Chưa có số liệu" message="Dữ liệu tổng quan sẽ hiển thị tại đây." />;
  return (
    <div className="ui-stack">
      <div className="ui-toolbar date-range-toolbar">
        <DateRangeControls value={range} onChange={setRange} compact />
      </div>
      <div className="ui-grid ui-grid-stats">
        {rows.map((row, i) => {
          const keys = Object.keys(row);
          const label = row.ChiSo ?? row[keys[0]];
          const value = row.GiaTri ?? row[keys[1]];
          const unit = row.DonVi ?? row[keys[2]] ?? '';
          return (
            <StatTile
              key={i}
              icon={STAT_ICONS[i % STAT_ICONS.length]}
              label={label}
              value={formatValue(value)}
              unit={unit}
              accent={(accents && accents[i]) || ACCENTS[i % ACCENTS.length]}
            />
          );
        })}
      </div>
    </div>
  );
}

/**
 * Modal that wraps an action's form, runs it, toasts, and calls onDone.
 * Used by every "create/update/cancel/..." flow so actions become buttons, not pages.
 */
export function ActionModal({ action, open, onClose, initial, token, onToast, onDone, title, subtitle, submitLabel, columns = 2 }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function submit(values) {
    setBusy(true);
    setError('');
    try {
      const res = await runAction(action.id, values, token);
      onToast?.(res.message || 'Thực hiện thành công.', 'success');
      onDone?.(res);
      onClose?.();
    } catch (err) {
      setError(friendlyError(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <Modal open={open} title={title || action.title} subtitle={subtitle || action.description} onClose={onClose} wide={columns > 2}>
      {open && (
        <ActionForm
          key={JSON.stringify(initial || {})}
          action={action}
          initial={initial}
          onSubmit={submit}
          submitLabel={submitLabel}
          busy={busy}
          error={error}
          columns={columns}
          token={token}
        />
      )}
    </Modal>
  );
}

/** Confirmation dialog that runs a no/low-param action (cancel, lock, close...). */
export function ConfirmAction({ action, open, onClose, params, token, onToast, onDone, title, message, danger }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function confirm() {
    setBusy(true);
    setError('');
    try {
      const res = await runAction(action.id, params || {}, token);
      onToast?.(res.message || 'Thực hiện thành công.', 'success');
      onDone?.(res);
      onClose?.();
    } catch (err) {
      setError(friendlyError(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <Modal
      open={open}
      title={title || action.title}
      onClose={onClose}
      footer={(
        <>
          <Button variant="ghost" onClick={onClose} disabled={busy}>Huỷ</Button>
          <Button variant={danger ? 'danger' : 'primary'} onClick={confirm} disabled={busy}>{busy ? 'Đang xử lý...' : 'Xác nhận'}</Button>
        </>
      )}
    >
      <p style={{ fontSize: 14, lineHeight: 1.6, color: 'var(--text-main)' }}>{message || action.description}</p>
      {error && <p className="error" style={{ marginTop: 12 }}>{error}</p>}
    </Modal>
  );
}

/**
 * Generic report view: optional chart on top + data table + export buttons.
 * `chart` is a render function (rows) => ReactNode.
 */
export function ReportView({ action, token, chart, columns, body = {} }) {
  const [range, setRange] = useState({});
  const requestBody = useMemo(() => ({ ...body, ...range, pageSize: action.pageSize || body.pageSize || 50 }), [action.pageSize, body, range]);
  const { data, rows, loading, error } = useActionData(action.id, { token, body: requestBody });
  const [exporting, setExporting] = useState(false);

  async function exportFile(kind) {
    setExporting(true);
    try {
      if (kind === 'pdf') await downloadReportPdf(action.id, requestBody, token);
      else await downloadCsv(action.id, requestBody, token);
    } catch (err) {
      // surfaced by caller toast normally; ignore here
    } finally {
      setExporting(false);
    }
  }

  const cols = (columns?.length ? columns : action.columns?.length ? action.columns : data?.columns) || [];

  return (
    <div className="ui-stack">
      {action.report || action.exportable ? (
        <div className="ui-toolbar date-range-toolbar">
          <DateRangeControls value={range} onChange={setRange} />
          <div className="ui-toolbar" style={{ justifyContent: 'flex-end' }}>
            {action.exportable && <Button variant="ghost" icon={<DownloadIcon size={16} />} disabled={exporting} onClick={() => exportFile('csv')}>Tải CSV</Button>}
            {action.report && <Button variant="secondary" icon={<DownloadIcon size={16} />} disabled={exporting} onClick={() => exportFile('pdf')}>Tải PDF</Button>}
          </div>
        </div>
      ) : null}
      {loading ? <Loader /> : error ? <EmptyState title="Không tải được dữ liệu" message={error} /> : (
        <>
          {chart && rows.length > 0 && <div className="ui-card">{chart(rows)}</div>}
          <DataTable
            columns={cols}
            rows={rows}
            renderCell={(c, v) => (isStatusColumn(c) && v != null ? <Badge value={v} /> : formatValue(v))}
            meta={{ left: `${rows.length} dòng dữ liệu`, right: action.title }}
          />
        </>
      )}
    </div>
  );
}

/**
 * Dashboard panel that turns key reports into one-click PDF/CSV downloads.
 * `reports` = [{ id, label, icon? }]; only those present in the catalog (h.has) show.
 */
export function QuickReports({ h, reports = [], token, onToast, title = 'Xuất báo cáo nhanh', subtitle = 'Tải nhanh PDF hoặc CSV' }) {
  const list = reports.filter((r) => r && (!h || h.has(r.id)));
  const [busy, setBusy] = useState('');
  const [range, setRange] = useState({});

  async function download(report, kind) {
    setBusy(`${report.id}:${kind}`);
    try {
      if (kind === 'pdf') await downloadReportPdf(report.id, range, token);
      else await downloadCsv(report.id, range, token);
    } catch (err) {
      onToast?.(friendlyError(err), 'error');
    } finally {
      setBusy('');
    }
  }

  if (!list.length) return null;
  return (
    <Card>
      <CardHeader title={title} subtitle={subtitle} />
      <div className="quick-report-range">
        <DateRangeControls value={range} onChange={setRange} compact />
      </div>
      <div className="quick-reports">
        {list.map((r) => (
          <div className="quick-report" key={r.id}>
            <span className="quick-report-name">{r.icon}<span className="u-truncate">{r.label}</span></span>
            <div className="quick-report-actions">
              <Button variant="ghost" className="ui-btn-sm" icon={<DownloadIcon size={14} />} disabled={busy === `${r.id}:pdf`} onClick={() => download(r, 'pdf')}>PDF</Button>
              <Button variant="ghost" className="ui-btn-sm" icon={<DownloadIcon size={14} />} disabled={busy === `${r.id}:csv`} onClick={() => download(r, 'csv')}>CSV</Button>
            </div>
          </div>
        ))}
      </div>
    </Card>
  );
}

export { formatNumber };
