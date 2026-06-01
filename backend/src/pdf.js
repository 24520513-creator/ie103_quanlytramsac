import fs from 'node:fs';
import PDFDocument from 'pdfkit';
import { actions } from './catalog.js';
import { runAction } from './actionRunner.js';
import { getReportTemplate } from './reportTemplates.js';

const PAGE = {
  margin: 36,
  width: 595.28,
  height: 841.89,
  contentWidth: 523.28
};

const COLORS = {
  ink: '#172033',
  muted: '#64748b',
  line: '#dbe4ef',
  soft: '#f4f7fb',
  brand: '#0f766e',
  brandDark: '#115e59',
  info: '#2563eb',
  warn: '#d97706',
  bad: '#dc2626',
  purple: '#7c3aed',
  pink: '#db2777',
  white: '#ffffff'
};

const PALETTE = [COLORS.brand, COLORS.info, COLORS.warn, COLORS.bad, COLORS.purple, '#0891b2', '#16a34a', COLORS.pink];
const OMIT_FILTER_KEYS = new Set(['page', 'pageSize']);
const MAX_TABLE_ROWS = 80;
const MAX_TABLE_COLUMNS = 7;

const candidateFonts = {
  regular: [
    'C:/Windows/Fonts/arial.ttf',
    'C:/Windows/Fonts/calibri.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
  ],
  bold: [
    'C:/Windows/Fonts/arialbd.ttf',
    'C:/Windows/Fonts/calibrib.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
  ]
};

function pickFont(paths) {
  return paths.find((item) => fs.existsSync(item));
}

function registerVietnameseFonts(doc) {
  const regular = pickFont(candidateFonts.regular);
  const bold = pickFont(candidateFonts.bold);
  if (regular) doc.registerFont('Vietnamese', regular);
  if (bold) doc.registerFont('VietnameseBold', bold);
  doc._evReportFontRegular = Boolean(regular);
  doc._evReportFontBold = Boolean(bold);
  doc.font(regular ? 'Vietnamese' : 'Helvetica');
}

function font(doc, weight = 'regular') {
  const name = weight === 'bold' && doc._evReportFontBold ? 'VietnameseBold' : doc._evReportFontRegular ? 'Vietnamese' : weight === 'bold' ? 'Helvetica-Bold' : 'Helvetica';
  doc.font(name);
  return doc;
}

function formatNumber(value, digits = 0) {
  const n = Number(value);
  if (!Number.isFinite(n)) return '';
  return new Intl.NumberFormat('vi-VN', { maximumFractionDigits: digits }).format(n);
}

function formatCurrency(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return '0 đ';
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(n);
}

function formatPercent(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return '';
  return `${formatNumber(n, 1)}%`;
}

function formatDate(value, withTime = false) {
  if (!value) return '';
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return String(value);
  return withTime ? date.toLocaleString('vi-VN') : date.toLocaleDateString('vi-VN');
}

function formatCell(value, column = '') {
  if (value === null || value === undefined) return '';
  if (value instanceof Date) return formatDate(value);
  if (typeof value === 'number') {
    if (/amount|revenue|spend|price|cost|totalrevenue|share/i.test(column)) return formatCurrency(value);
    if (/rate|percent/i.test(column)) return formatPercent(value);
    return formatNumber(value, Number.isInteger(value) ? 0 : 2);
  }
  if (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}T/.test(value)) return formatDate(value, true);
  return String(value);
}

function numeric(value) {
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

function summarizeRows(rows, key) {
  return rows.reduce((sum, row) => sum + numeric(row[key]), 0);
}

function aggregateRows(rows, labelKey, valueKey, { countRows = false } = {}) {
  const map = new Map();
  for (const row of rows) {
    const label = row[labelKey] ?? 'Không xác định';
    const value = countRows ? 1 : numeric(row[valueKey]);
    map.set(label, (map.get(label) || 0) + value);
  }
  return [...map.entries()].map(([label, value]) => ({ label: String(label), value }));
}

function getTop(rows, labelKey, valueKey, options = {}) {
  const data = aggregateRows(rows, labelKey, valueKey, options).sort((a, b) => b.value - a.value);
  return data[0] || null;
}

function metricValue(metric, rows) {
  if (metric.op === 'countRows') return rows.length;
  if (metric.op === 'sum') return summarizeRows(rows, metric.key);
  if (metric.op === 'countDistinct') return new Set(rows.map((row) => row[metric.key]).filter((value) => value !== null && value !== undefined && value !== '')).size;
  if (metric.op === 'topLabel') return getTop(rows, metric.labelKey, metric.valueKey, metric)?.label || 'Không có';
  return '';
}

function formatMetric(value, metric) {
  if (typeof value === 'string') return value;
  if (metric.type === 'currency') return formatCurrency(value);
  if (metric.type === 'percent') return formatPercent(value);
  return formatNumber(value, Number.isInteger(value) ? 0 : 2);
}

function defaultMetrics(rows, columns) {
  const metrics = [{ label: 'Số dòng dữ liệu', op: 'countRows', type: 'number' }];
  const moneyColumn = columns.find((column) => /amount|revenue|spend|total|cost/i.test(column) && rows.some((row) => Number.isFinite(Number(row[column]))));
  const numericColumn = columns.find((column) => column !== moneyColumn && rows.some((row) => Number.isFinite(Number(row[column]))));
  if (moneyColumn) metrics.push({ label: `Tổng ${moneyColumn}`, op: 'sum', key: moneyColumn, type: /amount|revenue|spend|cost/i.test(moneyColumn) ? 'currency' : 'number' });
  if (numericColumn && metrics.length < 4) metrics.push({ label: `Tổng ${numericColumn}`, op: 'sum', key: numericColumn, type: 'number' });
  return metrics;
}

function buildInsights(rows, template) {
  if (!rows.length) return ['Không có dữ liệu trong phạm vi báo cáo.'];
  const rules = template?.insightRules || [];
  const insights = [];
  for (const rule of rules) {
    const top = getTop(rows, rule.labelKey, rule.valueKey, rule);
    if (!top) continue;
    if (rule.type === 'share') {
      const total = aggregateRows(rows, rule.labelKey, rule.valueKey, rule).reduce((sum, item) => sum + item.value, 0);
      const share = total ? (top.value / total) * 100 : 0;
      insights.push(`${top.label} chiếm tỷ trọng lớn nhất theo ${rule.metricLabel || 'chỉ số'} (${formatPercent(share)}).`);
    } else {
      insights.push(`${top.label} có ${rule.metricLabel || 'giá trị'} cao nhất (${formatCell(top.value, rule.valueKey)}).`);
    }
  }
  if (!insights.length) insights.push(`Báo cáo ghi nhận ${formatNumber(rows.length)} dòng dữ liệu chi tiết.`);
  return insights.slice(0, 3);
}

function ensureSpace(doc, height) {
  if (doc.y + height > PAGE.height - PAGE.margin - 28) doc.addPage();
}

function drawSectionTitle(doc, title) {
  ensureSpace(doc, 34);
  doc.moveDown(0.8);
  font(doc, 'bold').fontSize(12).fillColor(COLORS.ink).text(title);
  doc.moveTo(PAGE.margin, doc.y + 4).lineTo(PAGE.width - PAGE.margin, doc.y + 4).strokeColor(COLORS.line).lineWidth(1).stroke();
  doc.moveDown(0.8);
}

function renderHeader(doc, action, issuedAt) {
  const top = PAGE.margin;
  doc.rect(0, 0, PAGE.width, 116).fill(COLORS.soft);
  doc.rect(0, 0, 8, 116).fill(COLORS.brand);
  font(doc, 'bold').fontSize(11).fillColor(COLORS.brandDark).text('EV Charging Management', PAGE.margin, top, { width: PAGE.contentWidth });
  font(doc, 'bold').fontSize(20).fillColor(COLORS.ink).text(action.title, PAGE.margin, top + 24, { width: PAGE.contentWidth - 120 });
  font(doc).fontSize(10).fillColor(COLORS.muted).text(action.description || 'Báo cáo hệ thống', PAGE.margin, top + 54, { width: PAGE.contentWidth - 120 });
  doc.roundedRect(PAGE.width - PAGE.margin - 110, top + 4, 110, 42, 5).fill(COLORS.white).strokeColor(COLORS.line).stroke();
  font(doc, 'bold').fontSize(8).fillColor(COLORS.muted).text('NGÀY XUẤT', PAGE.width - PAGE.margin - 98, top + 13, { width: 86, align: 'center' });
  font(doc).fontSize(10).fillColor(COLORS.ink).text(formatDate(issuedAt), PAGE.width - PAGE.margin - 98, top + 27, { width: 86, align: 'center' });
  doc.y = 132;
}

function renderReportMeta(doc, action, user, body, issuedAt) {
  const rows = [
    ['Người lập', user.fullName || user.username],
    ['Tên đăng nhập', user.username],
    ['Vai trò', user.roleCode],
    ['Nhóm báo cáo', action.group || 'reports'],
    ['Thời điểm xuất', formatDate(issuedAt, true)]
  ];

  const labels = Object.fromEntries((action.params || []).map((param) => [param.name, param.label || param.name]));
  const filters = Object.entries(body || {})
    .filter(([key, value]) => !OMIT_FILTER_KEYS.has(key) && value !== undefined && value !== null && value !== '')
    .map(([key, value]) => [labels[key] || key, formatCell(value, key)]);
  if (filters.length) rows.push(...filters);

  const rowHeight = 20;
  const height = Math.ceil(rows.length / 2) * rowHeight + 18;
  ensureSpace(doc, height + 8);
  const x = PAGE.margin;
  const y = doc.y;
  const width = PAGE.contentWidth;
  doc.roundedRect(x, y, width, height, 5).fill(COLORS.white).strokeColor(COLORS.line).stroke();
  rows.forEach(([label, value], index) => {
    const col = index % 2;
    const row = Math.floor(index / 2);
    const cellX = x + 14 + col * (width / 2);
    const cellY = y + 10 + row * rowHeight;
    font(doc, 'bold').fontSize(8).fillColor(COLORS.muted).text(label.toUpperCase(), cellX, cellY, { width: 88 });
    font(doc).fontSize(9).fillColor(COLORS.ink).text(String(value), cellX + 92, cellY, { width: width / 2 - 116, ellipsis: true });
  });
  doc.y = y + height + 4;
}

function renderKpiCards(doc, rows, columns, template) {
  const metricDefs = (template?.summaryMetrics?.length ? template.summaryMetrics : defaultMetrics(rows, columns)).slice(0, 4);
  if (!metricDefs.length) return;
  drawSectionTitle(doc, 'Tổng quan chỉ số');

  const gap = 10;
  const cardWidth = (PAGE.contentWidth - gap * (metricDefs.length - 1)) / metricDefs.length;
  const cardHeight = 62;
  ensureSpace(doc, cardHeight + 8);
  const y = doc.y;
  metricDefs.forEach((metric, index) => {
    const x = PAGE.margin + index * (cardWidth + gap);
    const value = rows.length || metric.op === 'countRows' ? formatMetric(metricValue(metric, rows), metric) : 'Không có';
    doc.roundedRect(x, y, cardWidth, cardHeight, 6).fill(COLORS.soft).strokeColor(COLORS.line).stroke();
    doc.rect(x, y, 4, cardHeight).fill(PALETTE[index % PALETTE.length]);
    font(doc, 'bold').fontSize(8).fillColor(COLORS.muted).text(metric.label.toUpperCase(), x + 12, y + 12, { width: cardWidth - 20, ellipsis: true });
    font(doc, 'bold').fontSize(value.length > 18 ? 11 : 14).fillColor(COLORS.ink).text(value, x + 12, y + 31, { width: cardWidth - 20, ellipsis: true });
  });
  doc.y = y + cardHeight + 2;
}

function prepareChartData(rows, chart) {
  if (!chart || chart.type === 'none' || !rows.length) return [];
  if (chart.type === 'donut') return aggregateRows(rows, chart.nameKey, chart.valueKey, chart).sort((a, b) => b.value - a.value).slice(0, 8);
  if (chart.aggregate) {
    const valueKey = chart.yKey || chart.yKeys?.[0];
    return aggregateRows(rows, chart.xKey, valueKey).sort((a, b) => String(a.label).localeCompare(String(b.label), 'vi')).slice(0, 12);
  }
  const valueKey = chart.yKey || chart.yKeys?.[0];
  return rows
    .map((row) => ({ label: String(row[chart.xKey] ?? ''), value: numeric(row[valueKey]), raw: row }))
    .sort((a, b) => chart.type === 'line' ? 0 : b.value - a.value)
    .slice(0, chart.type === 'line' ? 14 : 10);
}

function formatAxis(value, format) {
  if (format === 'currency') {
    const n = Number(value);
    if (Math.abs(n) >= 1_000_000_000) return `${formatNumber(n / 1_000_000_000, 1)}B`;
    if (Math.abs(n) >= 1_000_000) return `${formatNumber(n / 1_000_000, 1)}M`;
    if (Math.abs(n) >= 1_000) return `${formatNumber(n / 1_000, 1)}K`;
  }
  return formatNumber(value, 0);
}

function drawBarChart(doc, data, box, { horizontal = false, format = 'number' } = {}) {
  const max = Math.max(...data.map((item) => item.value), 1);
  const left = box.x + 8;
  const top = box.y + 12;
  const width = box.width - 16;
  const height = box.height - 28;
  font(doc).fontSize(7).fillColor(COLORS.muted);

  if (horizontal) {
    const rowHeight = Math.min(24, height / data.length);
    data.forEach((item, index) => {
      const y = top + index * rowHeight;
      const labelWidth = 118;
      const barWidth = Math.max(2, (width - labelWidth - 54) * (item.value / max));
      doc.fillColor(COLORS.muted).text(item.label, left, y + 3, { width: labelWidth - 6, ellipsis: true });
      doc.roundedRect(left + labelWidth, y + 3, barWidth, 10, 3).fill(PALETTE[index % PALETTE.length]);
      doc.fillColor(COLORS.ink).text(formatAxis(item.value, format), left + labelWidth + barWidth + 5, y + 1, { width: 48 });
    });
    return;
  }

  const baseY = top + height - 18;
  const barGap = 6;
  const barWidth = Math.max(12, (width - barGap * (data.length - 1)) / data.length);
  doc.moveTo(left, baseY).lineTo(left + width, baseY).strokeColor(COLORS.line).stroke();
  data.forEach((item, index) => {
    const x = left + index * (barWidth + barGap);
    const h = Math.max(2, (height - 44) * (item.value / max));
    doc.roundedRect(x, baseY - h, barWidth, h, 3).fill(PALETTE[index % PALETTE.length]);
    doc.fillColor(COLORS.ink).fontSize(7).text(formatAxis(item.value, format), x - 4, baseY - h - 11, { width: barWidth + 8, align: 'center' });
    doc.fillColor(COLORS.muted).fontSize(7).text(item.label, x - 4, baseY + 4, { width: barWidth + 8, align: 'center', ellipsis: true });
  });
}

function drawLineChart(doc, data, box, { format = 'number' } = {}) {
  const max = Math.max(...data.map((item) => item.value), 1);
  const min = Math.min(...data.map((item) => item.value), 0);
  const range = Math.max(max - min, 1);
  const left = box.x + 34;
  const top = box.y + 16;
  const width = box.width - 52;
  const height = box.height - 48;
  const baseY = top + height;

  doc.strokeColor(COLORS.line).lineWidth(1);
  for (let i = 0; i <= 3; i += 1) {
    const y = top + (height / 3) * i;
    doc.moveTo(left, y).lineTo(left + width, y).stroke();
  }
  font(doc).fontSize(7).fillColor(COLORS.muted).text(formatAxis(max, format), box.x + 4, top - 4, { width: 28, align: 'right' });
  doc.text(formatAxis(min, format), box.x + 4, baseY - 4, { width: 28, align: 'right' });

  const points = data.map((item, index) => {
    const x = left + (data.length === 1 ? width / 2 : (width / (data.length - 1)) * index);
    const y = baseY - ((item.value - min) / range) * height;
    return { ...item, x, y };
  });

  doc.strokeColor(COLORS.brand).lineWidth(2);
  points.forEach((point, index) => {
    if (index === 0) doc.moveTo(point.x, point.y);
    else doc.lineTo(point.x, point.y);
  });
  doc.stroke();
  points.forEach((point, index) => {
    doc.circle(point.x, point.y, 2.8).fill(PALETTE[index % PALETTE.length]);
    if (index % Math.ceil(points.length / 6) === 0) {
      font(doc).fontSize(7).fillColor(COLORS.muted).text(point.label, point.x - 18, baseY + 6, { width: 36, align: 'center', ellipsis: true });
    }
  });
}

function drawDonutChart(doc, data, box, { format = 'number' } = {}) {
  const total = data.reduce((sum, item) => sum + item.value, 0);
  if (!total) return;
  const cx = box.x + 90;
  const cy = box.y + box.height / 2 + 4;
  const r = 58;
  let start = -90;

  data.forEach((item, index) => {
    const angle = (item.value / total) * 360;
    doc.moveTo(cx, cy).arc(cx, cy, r, start, start + angle).lineTo(cx, cy).fill(PALETTE[index % PALETTE.length]);
    start += angle;
  });
  doc.circle(cx, cy, 30).fill(COLORS.white);
  font(doc, 'bold').fontSize(10).fillColor(COLORS.ink).text(formatAxis(total, format), cx - 35, cy - 6, { width: 70, align: 'center' });

  const legendX = box.x + 180;
  let legendY = box.y + 20;
  data.slice(0, 7).forEach((item, index) => {
    const share = (item.value / total) * 100;
    doc.rect(legendX, legendY + 3, 8, 8).fill(PALETTE[index % PALETTE.length]);
    font(doc).fontSize(8).fillColor(COLORS.ink).text(item.label, legendX + 14, legendY, { width: 120, ellipsis: true });
    doc.fillColor(COLORS.muted).text(`${formatAxis(item.value, format)} | ${formatPercent(share)}`, legendX + 140, legendY, { width: 120 });
    legendY += 17;
  });
}

function renderChart(doc, rows, template) {
  const chart = template?.chart;
  const data = prepareChartData(rows, chart);
  if (!chart || chart.type === 'none' || data.length === 0) return;
  drawSectionTitle(doc, chart.title || 'Biểu đồ phân tích');
  const box = { x: PAGE.margin, y: doc.y, width: PAGE.contentWidth, height: chart.type === 'donut' ? 178 : 190 };
  ensureSpace(doc, box.height + 6);
  box.y = doc.y;
  doc.roundedRect(box.x, box.y, box.width, box.height, 5).fill(COLORS.white).strokeColor(COLORS.line).stroke();
  if (chart.type === 'donut') drawDonutChart(doc, data, box, chart);
  else if (chart.type === 'line') drawLineChart(doc, data, box, chart);
  else drawBarChart(doc, data, box, { ...chart, horizontal: chart.type === 'horizontalBar' });
  doc.y = box.y + box.height + 4;
}

function renderInsights(doc, rows, template) {
  const insights = buildInsights(rows, template);
  drawSectionTitle(doc, 'Nhận xét nhanh');
  const height = 28 + insights.length * 18;
  ensureSpace(doc, height);
  const y = doc.y;
  doc.roundedRect(PAGE.margin, y, PAGE.contentWidth, height, 5).fill(COLORS.soft).strokeColor(COLORS.line).stroke();
  insights.forEach((item, index) => {
    doc.circle(PAGE.margin + 16, y + 18 + index * 18, 3).fill(PALETTE[index % PALETTE.length]);
    font(doc).fontSize(9).fillColor(COLORS.ink).text(item, PAGE.margin + 28, y + 12 + index * 18, { width: PAGE.contentWidth - 42 });
  });
  doc.y = y + height + 4;
}

function columnWidths(columns) {
  const width = PAGE.contentWidth;
  if (columns.length <= 3) return columns.map(() => width / columns.length);
  const first = Math.min(110, width * 0.22);
  const remaining = (width - first) / (columns.length - 1);
  return [first, ...columns.slice(1).map(() => remaining)];
}

function renderDataTable(doc, columns, rows) {
  drawSectionTitle(doc, 'Bảng dữ liệu chi tiết');
  if (!columns.length || !rows.length) {
    ensureSpace(doc, 40);
    font(doc).fontSize(10).fillColor(COLORS.muted).text('Không có dữ liệu.', PAGE.margin, doc.y + 4);
    doc.moveDown();
    return;
  }

  const widths = columnWidths(columns);
  const rowHeight = 24;
  const headerHeight = 26;

  function header() {
    ensureSpace(doc, headerHeight + rowHeight);
    let x = PAGE.margin;
    const y = doc.y;
    doc.rect(PAGE.margin, y, PAGE.contentWidth, headerHeight).fill(COLORS.brand);
    columns.forEach((column, index) => {
      font(doc, 'bold').fontSize(7.5).fillColor(COLORS.white).text(column, x + 4, y + 8, { width: widths[index] - 8, ellipsis: true });
      x += widths[index];
    });
    doc.y = y + headerHeight;
  }

  header();
  rows.slice(0, MAX_TABLE_ROWS).forEach((row, rowIndex) => {
    if (doc.y + rowHeight > PAGE.height - PAGE.margin - 30) {
      doc.addPage();
      header();
    }
    const y = doc.y;
    if (rowIndex % 2 === 0) doc.rect(PAGE.margin, y, PAGE.contentWidth, rowHeight).fill(COLORS.soft);
    let x = PAGE.margin;
    columns.forEach((column, index) => {
      const value = formatCell(row[column], column);
      font(doc).fontSize(7.5).fillColor(COLORS.ink).text(value, x + 4, y + 7, { width: widths[index] - 8, height: 11, ellipsis: true });
      x += widths[index];
    });
    doc.moveTo(PAGE.margin, y + rowHeight).lineTo(PAGE.width - PAGE.margin, y + rowHeight).strokeColor(COLORS.line).lineWidth(0.5).stroke();
    doc.y = y + rowHeight;
  });

  if (rows.length > MAX_TABLE_ROWS) {
    doc.moveDown(0.5);
    font(doc).fontSize(8).fillColor(COLORS.muted).text(`PDF hiển thị ${MAX_TABLE_ROWS}/${rows.length} dòng đầu tiên. Tải CSV để xem toàn bộ dữ liệu.`);
  }
}

function renderSignature(doc, user, issuedAt) {
  ensureSpace(doc, 110);
  doc.moveDown(1.4);
  const x = PAGE.width - PAGE.margin - 190;
  font(doc).fontSize(10).fillColor(COLORS.ink).text(`Ngày ..... tháng ..... năm ${issuedAt.getFullYear()}`, x, doc.y, { width: 190, align: 'center' });
  font(doc, 'bold').fontSize(10).text('Người ký xác nhận', x, doc.y + 6, { width: 190, align: 'center' });
  doc.moveDown(3.2);
  font(doc).fontSize(10).text(user.fullName || user.username, x, doc.y, { width: 190, align: 'center' });
}

function renderFooters(doc) {
  const range = doc.bufferedPageRange();
  for (let i = range.start; i < range.start + range.count; i += 1) {
    doc.switchToPage(i);
    const pageNumber = i - range.start + 1;
    font(doc).fontSize(8).fillColor(COLORS.muted);
    doc.moveTo(PAGE.margin, PAGE.height - 34).lineTo(PAGE.width - PAGE.margin, PAGE.height - 34).strokeColor(COLORS.line).stroke();
    doc.text('EV Charging Management', PAGE.margin, PAGE.height - 25, { width: 200 });
    doc.text(`Trang ${pageNumber}/${range.count}`, PAGE.width - PAGE.margin - 80, PAGE.height - 25, { width: 80, align: 'right' });
  }
}

export async function buildReportPdf(actionId, user, body = {}) {
  const action = actions[actionId];
  if (!action?.report) {
    const error = new Error('Chức năng này không phải báo cáo có thể xuất PDF.');
    error.statusCode = 400;
    throw error;
  }

  const data = await runAction(actionId, user, { ...body, pageSize: body.pageSize || 80 });
  const rows = data.rows || [];
  const columns = (action.columns?.length ? action.columns : data.columns || []).filter(Boolean).slice(0, MAX_TABLE_COLUMNS);
  const template = getReportTemplate(actionId);
  const issuedAt = new Date();

  const doc = new PDFDocument({ margin: PAGE.margin, size: 'A4', bufferPages: true, info: { Title: action.title, Author: user.fullName || user.username } });
  registerVietnameseFonts(doc);
  const chunks = [];
  doc.on('data', (chunk) => chunks.push(chunk));

  renderHeader(doc, action, issuedAt);
  renderReportMeta(doc, action, user, body, issuedAt);
  renderKpiCards(doc, rows, columns, template);
  renderChart(doc, rows, template);
  renderInsights(doc, rows, template);
  renderDataTable(doc, columns, rows);
  renderSignature(doc, user, issuedAt);
  renderFooters(doc);

  doc.end();
  return new Promise((resolve) => {
    doc.on('end', () => resolve(Buffer.concat(chunks)));
  });
}
