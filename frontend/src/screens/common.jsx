import React, { useMemo, useState } from 'react';
import { useActionData } from '../lib/useAction';
import { runAction, downloadReportPdf, downloadCsv } from '../lib/api';
import { formatValue, formatNumber, isStatusColumn } from '../lib/format';
import { Modal, Loader, EmptyState, StatTile, Badge, DataTable, Button, Card, CardHeader, PageHeader } from '../components/ui';
import { ActionForm } from '../components/ui/ActionForm';
import { friendlyError } from '../lib/errors';
import { BoltIcon, TrendingUpIcon, ActivityIcon, CheckIcon, DownloadIcon, CalendarIcon, CameraIcon } from '../components/Icons';
import { Bars, AreaTrend, Donut } from '../components/charts';
import { SQL_HINTS } from '../lib/sqlHints';

const STAT_ICONS = [<BoltIcon size={18} />, <TrendingUpIcon size={18} />, <CheckIcon size={18} />, <ActivityIcon size={18} />];
const ACCENTS = ['brand', 'info', 'warn', 'bad'];
const MONEY_RE = /amount|revenue|spend|price|cost|totalrevenue|share/i;
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

function parseDate(value) {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function startOfWeek(date) {
  const copy = new Date(date);
  const day = copy.getDay() || 7;
  copy.setDate(copy.getDate() - day + 1);
  copy.setHours(0, 0, 0, 0);
  return copy;
}

function daysBetween(from, to) {
  if (!from || !to) return null;
  return Math.max(0, Math.round((to - from) / 86400000));
}

function bucketForRange(range = {}, rows = [], dateKey) {
  let from = parseDate(range.FromDate);
  let to = parseDate(range.ToDate);
  if ((!from || !to) && rows.length && dateKey) {
    const dates = rows.map((row) => parseDate(row[dateKey])).filter(Boolean).sort((a, b) => a - b);
    from = from || dates[0];
    to = to || dates[dates.length - 1];
  }
  const span = daysBetween(from, to);
  if (span == null) return 'month';
  if (span <= 31) return 'day';
  if (span < 180) return 'week';
  if (span < 730) return 'month';
  return 'quarter';
}

function bucketKey(date, bucket) {
  const year = date.getFullYear();
  const month = date.getMonth() + 1;
  if (bucket === 'day') return { key: toIsoDate(date), label: date.toLocaleDateString('vi-VN'), sort: toIsoDate(date) };
  if (bucket === 'week') {
    const start = startOfWeek(date);
    const end = new Date(start);
    end.setDate(start.getDate() + 6);
    return { key: toIsoDate(start), label: `${start.toLocaleDateString('vi-VN')} - ${end.toLocaleDateString('vi-VN')}`, sort: toIsoDate(start) };
  }
  if (bucket === 'quarter') {
    const quarter = Math.floor((month - 1) / 3) + 1;
    return { key: `${year}-Q${quarter}`, label: `Q${quarter}/${year}`, sort: `${year}-${quarter}` };
  }
  return { key: `${year}-${String(month).padStart(2, '0')}`, label: `${month}/${year}`, sort: `${year}-${String(month).padStart(2, '0')}` };
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

function num(value) {
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

function sum(rows, key) {
  return rows.reduce((total, row) => total + num(row[key]), 0);
}

function aggregate(rows, nameKey, valueKey, { countRows = false } = {}) {
  const map = new Map();
  rows.forEach((row) => {
    const label = row[nameKey] ?? 'Không xác định';
    map.set(label, (map.get(label) || 0) + (countRows ? 1 : num(row[valueKey])));
  });
  return [...map.entries()].map(([name, value]) => ({ name: String(name), value }));
}

function labelByParts(row, parts = []) {
  const values = parts.map((part) => row[part]).filter((value) => value !== null && value !== undefined && value !== '');
  if (values.length >= 2 && /month/i.test(parts[0])) return `${values[0]}/${values[1]}`;
  return values.join(' - ');
}

function isDateKey(key) {
  return /date|time|issued|opened|created|period/i.test(String(key || ''));
}

function chartConfigFor(action, columns = [], rows = []) {
  const byId = {
    stationRevenueDaily: { type: 'line', xKey: 'RevenueDate', yKey: 'RevenueTotal' },
    stationRevenueTrend: { type: 'line', xKey: 'RevenueDate', yKey: 'RevenueTotal' },
    stationRevenueByYear: { type: 'bar', xKey: 'RevenueYear', yKey: 'RevenueTotal', aggregate: true },
    stationRevenue: { type: 'bar', xKey: 'StationName', yKey: 'RevenueTotal', horizontal: true },
    regionRevenue: { type: 'bar', xKey: 'RegionName', yKey: 'RevenueTotal' },
    topRevenueStations: { type: 'bar', xKey: 'StationName', yKey: 'RevenueTotal', horizontal: true },
    peakHours: { type: 'bar', xKey: 'StartHour', yKey: 'SessionCount' },
    customerGrowth: { type: 'line', parts: ['CreatedMonth', 'CreatedYear'], yKey: 'NewCustomers' },
    paymentSummary: { type: 'donut', xKey: 'PaymentMethod', yKey: 'TotalAmount' },
    sessionStatistics: { type: 'donut', xKey: 'SessionStatus', yKey: 'SessionCount' },
    topCustomerUsage: { type: 'bar', xKey: 'FullName', yKey: 'TotalSpend', horizontal: true },
    connectorUtilization: { type: 'bar', xKey: 'ConnectorName', yKey: 'TotalRevenue' },
    systemKpi: { type: 'kpiBars', keys: ['ActiveStations', 'ActivePoints', 'ActiveSessions', 'CompletedSessions', 'FailedSessions', 'OpenTickets'] },
    profitSharing: { type: 'bar', xKey: 'FranchiseName', yKey: 'PartnerShareAmount', horizontal: true },
    myFranchiseSettlements: { type: 'line', xKey: 'PeriodEnd', yKey: 'GrossRevenue' },
    myFranchiseStations: { type: 'donut', xKey: 'StationStatus', countRows: true },
    myRevenueSharePolicies: { type: 'bar', xKey: 'PolicyCode', yKey: 'PartnerShareRate' },
    maintenanceKpi: { type: 'bar', xKey: 'StationName', yKeys: ['OpenTicketCount', 'ActiveErrorCount'] },
    maintenanceTickets: { type: 'donut', xKey: 'TicketStatus', countRows: true },
    telemetryHealth: { type: 'bar', xKey: 'StationCode', yKey: 'IssueSamples', horizontal: true },
    errorLogActive: { type: 'donut', xKey: 'Severity', countRows: true },
    stationStatus: { type: 'bar', xKey: 'StationName', yKeys: ['AvailablePoints', 'ProblemPoints'] },
    accountsByRole: { type: 'bar', xKey: 'RoleCode', yKey: 'AccountCount' },
    userRoleSummary: { type: 'donut', xKey: 'AccountStatus', countRows: true },
    auditLog: { type: 'donut', xKey: 'ActionType', countRows: true },
    chargingHistory: { type: 'line', xKey: 'StartTime', yKey: 'CostTotal' },
    invoiceDetail: { type: 'donut', xKey: 'InvoiceStatus', yKey: 'TotalAmount' },
    myChargingSummary: { type: 'line', parts: ['UsageMonth', 'UsageYear'], yKey: 'TotalSpend' }
  };
  if (byId[action.id]) return byId[action.id];

  const sample = rows[0] || {};
  const stringKey = columns.find((key) => typeof sample[key] === 'string') || columns.find((key) => /status|name|code/i.test(key));
  const valueKey = columns.find((key) => rows.some((row) => Number.isFinite(Number(row[key]))) && !/id$/i.test(key));
  if (stringKey && valueKey) return { type: 'bar', xKey: stringKey, yKey: valueKey, horizontal: rows.length > 8 };
  return null;
}

function chartRows(rows, cfg, range = {}) {
  if (!cfg || !rows.length) return [];
  if (cfg.type === 'kpiBars') {
    const row = rows[0] || {};
    return cfg.keys.filter((key) => row[key] !== undefined).map((key) => ({ name: key, value: num(row[key]) }));
  }
  if (cfg.parts) {
    return rows.map((row) => ({ label: labelByParts(row, cfg.parts), value: num(row[cfg.yKey]) })).reverse();
  }
  if (cfg.type === 'donut') return aggregate(rows, cfg.xKey, cfg.yKey, { countRows: cfg.countRows }).sort((a, b) => b.value - a.value);
  if (cfg.type === 'line' && cfg.xKey && cfg.yKey && isDateKey(cfg.xKey)) {
    const bucket = bucketForRange(range, rows, cfg.xKey);
    const map = new Map();
    rows.forEach((row) => {
      const date = parseDate(row[cfg.xKey]);
      if (!date) return;
      const b = bucketKey(date, bucket);
      const current = map.get(b.key) || { label: b.label, sort: b.sort, value: 0 };
      current.value += num(row[cfg.yKey]);
      map.set(b.key, current);
    });
    return [...map.values()].sort((a, b) => String(a.sort).localeCompare(String(b.sort)));
  }
  if (cfg.aggregate) return aggregate(rows, cfg.xKey, cfg.yKey).sort((a, b) => String(a.name).localeCompare(String(b.name), 'vi'));
  return rows.slice(0, cfg.type === 'line' ? 18 : 12);
}

function ReportChart({ action, rows, columns, customChart, range }) {
  if (customChart && rows.length > 0) return customChart(rows);
  const cfg = chartConfigFor(action, columns, rows);
  const data = chartRows(rows, cfg, range);
  if (!cfg || data.length === 0) return null;

  if (cfg.type === 'line') {
    if (cfg.parts || cfg.aggregate || isDateKey(cfg.xKey) || cfg.type === 'kpiBars') return <AreaTrend data={data} xKey={data[0]?.label !== undefined ? 'label' : 'name'} yKey="value" height={300} />;
    return <AreaTrend data={rows.slice().reverse()} xKey={cfg.xKey} yKey={cfg.yKey} height={300} />;
  }
  if (cfg.type === 'donut') return <Donut data={data} nameKey="name" valueKey="value" height={300} />;
  if (cfg.type === 'kpiBars') return <Bars data={data} xKey="name" yKeys={['value']} height={300} />;
  if (cfg.yKeys?.length) return <Bars data={data} xKey={cfg.xKey} yKeys={cfg.yKeys} height={320} horizontal={cfg.horizontal} />;
  if (cfg.aggregate || cfg.parts) return <Bars data={data} xKey="name" yKeys={['value']} height={300} horizontal={cfg.horizontal} />;
  return <Bars data={data} xKey={cfg.xKey} yKeys={[cfg.yKey]} height={320} horizontal={cfg.horizontal} />;
}

function reportMetrics(rows, columns) {
  if (!rows.length) return [];
  const numericColumns = columns.filter((column) => rows.some((row) => Number.isFinite(Number(row[column]))) && !/id$/i.test(column));
  const moneyColumn = numericColumns.find((column) => MONEY_RE.test(column));
  const mainNumeric = numericColumns.find((column) => column !== moneyColumn);
  const statusColumn = columns.find((column) => /status|severity|priority|method|role/i.test(column));
  const metrics = [{ label: 'Dòng dữ liệu', value: formatNumber(rows.length), hint: 'bản ghi' }];
  if (moneyColumn) metrics.push({ label: moneyColumn, value: formatValue(sum(rows, moneyColumn)), hint: 'tổng giá trị' });
  if (mainNumeric) metrics.push({ label: mainNumeric, value: formatValue(sum(rows, mainNumeric)), hint: 'tổng cộng' });
  if (statusColumn) metrics.push({ label: statusColumn, value: aggregate(rows, statusColumn, statusColumn, { countRows: true }).sort((a, b) => b.value - a.value)[0]?.name || 'Không có', hint: 'nhóm lớn nhất' });
  return metrics.slice(0, 4);
}

function reportInsights(action, rows, columns) {
  if (!rows.length) return ['Không có dữ liệu trong phạm vi lọc hiện tại.'];
  const cfg = chartConfigFor(action, columns, rows);
  const insights = [];
  if (cfg?.xKey && (cfg.yKey || cfg.countRows)) {
    const data = aggregate(rows, cfg.xKey, cfg.yKey, { countRows: cfg.countRows }).sort((a, b) => b.value - a.value);
    const total = data.reduce((acc, item) => acc + item.value, 0);
    const top = data[0];
    if (top && total) insights.push(`${top.name} đang chiếm ${formatNumber((top.value / total) * 100)}% trong chỉ số chính của báo cáo.`);
  }
  const moneyColumn = columns.find((column) => MONEY_RE.test(column) && rows.some((row) => Number.isFinite(Number(row[column]))));
  if (moneyColumn) insights.push(`Tổng ${moneyColumn} trong phạm vi hiện tại là ${formatValue(sum(rows, moneyColumn))}.`);
  if (insights.length < 2) insights.push('Biểu đồ phía trên giúp xác định nhóm nổi bật; bảng chi tiết dùng để truy vết từng bản ghi.');
  return insights.slice(0, 3);
}

function ReportBrief({ action, rows, columns }) {
  const metrics = reportMetrics(rows, columns);
  const insights = reportInsights(action, rows, columns);
  return (
    <div className="report-brief">
      <div className="report-kpis">
        {metrics.map((metric, index) => (
          <StatTile key={`${metric.label}-${index}`} icon={STAT_ICONS[index % STAT_ICONS.length]} label={metric.label} value={metric.value} unit={metric.hint} accent={ACCENTS[index % ACCENTS.length]} />
        ))}
      </div>
      <div className="report-insights">
        <CardHeader title="Nhận xét quản trị" subtitle="Tóm tắt nhanh từ dữ liệu đang hiển thị" />
        <ul>
          {insights.map((item, index) => <li key={index}>{item}</li>)}
        </ul>
      </div>
    </div>
  );
}

export function DateRangeControls({ value, onChange, compact = false }) {
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

  // Only the "Tùy chỉnh" preset exposes the raw date inputs — keeps the timeframe
  // picker compact (a single dropdown) for the dashboards, like a stat console.
  const showDates = preset === 'custom';

  return (
    <div className={`date-range-controls${compact ? ' date-range-controls-compact' : ''}`}>
      <span className="date-range-icon" aria-hidden="true"><CalendarIcon size={15} /></span>
      <select value={preset} onChange={(event) => applyPreset(event.target.value)} aria-label="Khoảng thời gian">
        {RANGE_OPTIONS.map((item) => <option key={item.value} value={item.value}>{item.label}</option>)}
      </select>
      {showDates && <input type="date" value={value.FromDate || ''} onChange={(event) => updateCustom('FromDate', event.target.value)} aria-label="Từ ngày" />}
      {showDates && <input type="date" value={value.ToDate || ''} onChange={(event) => updateCustom('ToDate', event.target.value)} aria-label="Đến ngày" />}
    </div>
  );
}

/**
 * Captures the whole dashboard (the nearest `.ui-stack` ancestor) to a PNG and
 * downloads it. Uses html2canvas, loaded on demand so it never weighs down the
 * initial bundle. The button itself is excluded from the capture.
 */
export function ScreenshotButton({ onToast, label = 'Chụp màn hình', className = '' }) {
  const [busy, setBusy] = useState(false);

  async function capture(event) {
    const root = event.currentTarget.closest('.ui-stack');
    if (!root) return;
    setBusy(true);
    try {
      const { default: html2canvas } = await import('html2canvas');
      const bg = getComputedStyle(document.body).backgroundColor || '#ffffff';
      const canvas = await html2canvas(root, {
        backgroundColor: bg && bg !== 'rgba(0, 0, 0, 0)' ? bg : '#ffffff',
        scale: 2,
        useCORS: true,
        logging: false,
        scrollX: 0,
        scrollY: -window.scrollY,
        windowWidth: root.scrollWidth
      });
      const link = document.createElement('a');
      link.download = `dashboard-${new Date().toISOString().slice(0, 10)}.png`;
      link.href = canvas.toDataURL('image/png');
      link.click();
      onToast?.('Đã tải ảnh dashboard.', 'success');
    } catch (err) {
      onToast?.('Không chụp được màn hình. Vui lòng thử lại.', 'error');
    } finally {
      setBusy(false);
    }
  }

  return (
    <Button
      variant="ghost"
      className={className}
      icon={<CameraIcon size={16} />}
      onClick={capture}
      disabled={busy}
      data-html2canvas-ignore="true"
    >
      {busy ? 'Đang chụp...' : label}
    </Button>
  );
}

/**
 * Dashboard header: title + a single timeframe picker on the right (stat-console
 * style). The picker is the one control that governs both the KPI tiles and every
 * chart on the dashboard — the parent owns `range` and feeds it to all of them.
 */
export function DashboardHeader({ icon, title, subtitle, range, onRangeChange, actions, onToast }) {
  return (
    <PageHeader
      icon={icon}
      title={title}
      subtitle={subtitle}
      actions={(
        <div className="dash-header-tools">
          <DateRangeControls value={range} onChange={onRangeChange} compact />
          <ScreenshotButton onToast={onToast} />
          {actions}
        </div>
      )}
    />
  );
}

/** Renders KPI tiles from a dashboard action returning ChiSo/GiaTri/DonVi rows.
 *  Controlled: `range` is owned by the parent dashboard (shared with the charts). */
export function DashboardStats({ actionId, token, accents, range = {} }) {
  const requestBody = useMemo(() => ({ ...range }), [range]);
  const { rows, loading } = useActionData(actionId, { token, body: requestBody });
  if (loading) return <Loader />;
  if (!rows.length) return <EmptyState title="Chưa có số liệu" message="Dữ liệu tổng quan sẽ hiển thị tại đây." />;
  return (
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
  );
}

/**
 * Buckets daily-grained rows (each with a real date column) into day/week/month/
 * quarter buckets according to the selected range — so the chart's time axis
 * granularity follows the timeframe picker. Returns rows shaped { label, sort, ...sums }.
 */
export function bucketSeries(rows, dateKey, valueKeys, range = {}) {
  const keys = Array.isArray(valueKeys) ? valueKeys : [valueKeys];
  if (!rows?.length) return [];
  const bucket = bucketForRange(range, rows, dateKey);
  const map = new Map();
  rows.forEach((row) => {
    const date = parseDate(row[dateKey]);
    if (!date) return;
    const b = bucketKey(date, bucket);
    const current = map.get(b.key) || { label: b.label, sort: b.sort };
    keys.forEach((key) => { current[key] = (current[key] || 0) + num(row[key]); });
    map.set(b.key, current);
  });
  return [...map.values()].sort((a, b) => String(a.sort).localeCompare(String(b.sort)));
}

function pctDelta(series, key) {
  if (!series || series.length < 2) return null;
  const last = num(series[series.length - 1][key]);
  const prev = num(series[series.length - 2][key]);
  if (!prev) return null;
  return ((last - prev) / Math.abs(prev)) * 100;
}

/**
 * Primary "analytics" panel for a dashboard: a headline total + period-over-period
 * delta over a daily series that re-buckets with the timeframe. The economic/stat
 * centerpiece of the redesigned dashboards.
 */
export function TrendPanel({ title, subtitle, rows, loading, dateKey, valueKey, range, color = '#10b981', format = formatNumber, height = 300, kind = 'area' }) {
  const series = useMemo(() => bucketSeries(rows, dateKey, valueKey, range), [rows, dateKey, valueKey, range]);
  const total = series.reduce((acc, item) => acc + num(item[valueKey]), 0);
  const delta = pctDelta(series, valueKey);
  return (
    <Card className="trend-panel">
      <div className="trend-panel-head">
        <div>
          <h3>{title}</h3>
          {subtitle && <span className="trend-panel-sub">{subtitle}</span>}
        </div>
        <div className="trend-panel-figure">
          <strong>{format(total)}</strong>
          {delta != null && (
            <span className={`trend-delta ${delta >= 0 ? 'up' : 'down'}`}>
              {delta >= 0 ? '▲' : '▼'} {formatNumber(Math.abs(delta).toFixed(1))}%
            </span>
          )}
        </div>
      </div>
      {loading ? <Loader /> : series.length === 0
        ? <EmptyState icon={<TrendingUpIcon size={26} />} title="Chưa có dữ liệu" message="Chọn khoảng thời gian khác để xem xu hướng." />
        : kind === 'bar'
          ? <Bars data={series} xKey="label" yKeys={[valueKey]} height={height} />
          : <AreaTrend data={series} xKey="label" yKey={valueKey} height={height} color={color} />}
    </Card>
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
export function ReportView({ action, token, chart, columns, body = {}, chartActionId }) {
  const [range, setRange] = useState({});
  const requestBody = useMemo(() => ({ ...body, ...range, pageSize: action.pageSize || body.pageSize || 50 }), [action.pageSize, body, range]);
  const { data, rows, loading, error } = useActionData(action.id, { token, body: requestBody });
  const chartRequestBody = useMemo(() => ({ ...body, ...range, pageSize: 5000 }), [body, range]);
  const chartResult = useActionData(chartActionId || action.id, { token, body: chartRequestBody, auto: Boolean(chartActionId) });
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
  const visualAction = chartActionId ? { ...action, id: chartActionId } : action;
  const visualRows = chartActionId && !chartResult.error ? chartResult.rows : rows;
  const hasChart = Boolean(chart) || Boolean(chartConfigFor(visualAction, cols, visualRows));

  return (
    <div className="ui-stack">
      {action.report || action.exportable ? (
        <div className="ui-toolbar date-range-toolbar">
          <DateRangeControls value={range} onChange={setRange} />
          <div className="ui-toolbar" style={{ justifyContent: 'flex-end' }}>
            {action.exportable && <Button variant="ghost" icon={<DownloadIcon size={16} />} sqlHint={SQL_HINTS.exportCsv} disabled={exporting} onClick={() => exportFile('csv')}>Tải CSV</Button>}
            {action.report && <Button variant="secondary" icon={<DownloadIcon size={16} />} sqlHint={SQL_HINTS.exportPdf} disabled={exporting} onClick={() => exportFile('pdf')}>Tải PDF</Button>}
          </div>
        </div>
      ) : null}
      {loading ? <Loader /> : error ? <EmptyState title="Không tải được dữ liệu" message={error} /> : (
        <>
          <ReportBrief action={action} rows={rows} columns={cols} />
          {rows.length > 0 && hasChart && (
            <div className="ui-card report-chart-card">
              <CardHeader title="Biểu đồ phân tích" subtitle="Trực quan hóa chỉ số chính trong phạm vi dữ liệu" />
              {chartActionId && chartResult.loading
                ? <Loader />
                : <ReportChart action={visualAction} rows={visualRows} columns={cols} customChart={chart} range={range} />}
            </div>
          )}
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
              <Button variant="ghost" className="ui-btn-sm" icon={<DownloadIcon size={14} />} sqlHint={SQL_HINTS.exportPdf} disabled={busy === `${r.id}:pdf`} onClick={() => download(r, 'pdf')}>PDF</Button>
              <Button variant="ghost" className="ui-btn-sm" icon={<DownloadIcon size={14} />} sqlHint={SQL_HINTS.exportCsv} disabled={busy === `${r.id}:csv`} onClick={() => download(r, 'csv')}>CSV</Button>
            </div>
          </div>
        ))}
      </div>
    </Card>
  );
}

export { formatNumber };
