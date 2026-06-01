import { actions } from './catalog.js';
import { runAction } from './actionRunner.js';

function escapeCsv(value) {
  if (value === null || value === undefined) return '';
  const text = value instanceof Date ? value.toISOString() : String(value);
  return `"${text.replaceAll('"', '""')}"`;
}

export async function buildCsvExport(actionId, user, body = {}) {
  const action = actions[actionId];
  if (!action || (!action.report && action.kind !== 'query' && action.kind !== 'static')) {
    const error = new Error('Chức năng này không hỗ trợ xuất CSV.');
    error.statusCode = 400;
    throw error;
  }

  const data = await runAction(actionId, user, {
    ...body,
    page: 1,
    pageSize: Math.min(Number(body.pageSize || 100), 100)
  });
  const columns = (action.columns?.length ? action.columns : data.columns).filter(Boolean);
  const header = columns.map(escapeCsv).join(',');
  const rows = data.rows.map((row) => columns.map((column) => escapeCsv(row[column])).join(','));
  return Buffer.from(`\uFEFF${[header, ...rows].join('\r\n')}`, 'utf8');
}
