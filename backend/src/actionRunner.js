import sql from 'mssql';
import { actions } from './catalog.js';
import { hashPassword } from './auth.js';
import { normalizeRecordset, sqlTypes, withSession } from './db.js';
import { validateActionLookups } from './lookups.js';

const maxPageSize = 100;

function assertRole(action, user) {
  if (!action.roles.includes(user.roleCode)) {
    const error = new Error('Bạn không có quyền thực hiện chức năng này.');
    error.statusCode = 403;
    throw error;
  }
}

function coerceValue(param, value) {
  if (value === undefined || value === '') return null;
  if (param.type === 'int' || param.type === 'bigInt') return Number(value);
  if (param.type === 'decimal') return Number(value);
  if (param.type === 'bit') return value === true || value === 'true' || value === '1' || value === 1;
  return value;
}

function bindInputs(request, action, body, user) {
  const values = {};
  for (const param of action.params || []) {
    const raw = body[param.name] ?? param.defaultValue;
    const value = coerceValue(param, raw);
    if (param.required && (value === null || Number.isNaN(value))) {
      throw new Error(`Thiếu dữ liệu bắt buộc: ${param.label || param.name}.`);
    }
    values[param.name] = value;
  }

  for (const [paramName, userField] of Object.entries(action.inject || {})) {
    values[paramName] = user[userField];
  }

  for (const [name, value] of Object.entries(values)) {
    const param = (action.params || []).find((item) => item.name === name) || {};
    request.input(name, sqlTypes[param.type || 'int'] || sql.NVarChar(sql.MAX), value);
  }
}

function buildSearchClause(action, body, request) {
  const search = String(body.search || '').trim();
  if (!search || !action.searchColumns?.length) return '';

  request.input('Search', sql.NVarChar(200), `%${search}%`);
  const predicates = action.searchColumns.map((column) => `CONVERT(NVARCHAR(4000), data.[${column}]) LIKE @Search`);
  return `WHERE ${predicates.join(' OR ')}`;
}

function buildPagedQuery(action, body, request) {
  const pageSize = Math.min(Math.max(Number(body.pageSize || action.pageSize || 25), 1), maxPageSize);
  const page = Math.max(Number(body.page || 1), 1);
  const offset = (page - 1) * pageSize;
  request.input('Offset', sql.Int, offset);
  request.input('PageSize', sql.Int, pageSize);

  const searchClause = buildSearchClause(action, body, request);
  const orderBy = action.orderBy || '1';
  const baseSql = action.sql.trim().replace(/;+\s*$/g, '');

  return `
    SELECT *
    FROM (${baseSql}) AS data
    ${searchClause}
    ORDER BY ${orderBy}
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    SELECT COUNT(1) AS TotalRows
    FROM (${baseSql}) AS data
    ${searchClause};
  `;
}

function normalizeResult(result, action, body) {
  const firstSet = result.recordsets?.[0] || result.recordset || [];
  const countSet = result.recordsets?.[1] || [];
  const normalized = normalizeRecordset(firstSet);
  const totalRows = countSet[0]?.TotalRows ?? normalized.summary.rowCount;
  const pageSize = Math.min(Math.max(Number(body.pageSize || action.pageSize || totalRows || 25), 1), maxPageSize);
  const page = Math.max(Number(body.page || 1), 1);

  return {
    ...normalized,
    columns: normalized.columns.length ? normalized.columns : (action.columns || []),
    summary: {
      ...normalized.summary,
      totalRows,
      page,
      pageSize,
      totalPages: pageSize ? Math.max(Math.ceil(totalRows / pageSize), 1) : 1
    },
    meta: {
      title: action.title,
      description: action.description,
      group: action.group,
      report: Boolean(action.report),
      columns: action.columns || normalized.columns
    },
    message: 'Thực hiện thành công.'
  };
}

async function prepareBody(actionId, body) {
  if ((actionId === 'createUser' || actionId === 'resetPassword') && body.PasswordHash) {
    return { ...body, PasswordHash: await hashPassword(body.PasswordHash) };
  }
  return body;
}

export async function runAction(actionId, user, body = {}) {
  const action = actions[actionId];
  if (!action) {
    const error = new Error('Chức năng không tồn tại.');
    error.statusCode = 404;
    throw error;
  }
  assertRole(action, user);

  if (action.kind === 'static') {
    return normalizeResult({ recordset: action.rows || [] }, action, body);
  }

  const preparedBody = await prepareBody(actionId, body);
  const result = await withSession(user, async (transaction) => {
    await validateActionLookups(action, user, preparedBody, transaction);
    const request = new sql.Request(transaction);
    bindInputs(request, action, preparedBody, user);
    if (action.kind === 'procedure') {
      return request.execute(action.procedure);
    }
    if (action.paginated) {
      return request.query(buildPagedQuery(action, preparedBody, request));
    }
    return request.query(action.sql);
  });

  return normalizeResult(result, action, preparedBody);
}
