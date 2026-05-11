const sql = require('mssql');
require('dotenv').config();

const config = {
  server: process.env.DB_SERVER,
  port: parseInt(process.env.DB_PORT) || 1433,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  options: {
    encrypt: process.env.DB_ENCRYPT === 'true',
    trustServerCertificate: process.env.DB_TRUST_CERT !== 'false',
    enableArithAbort: true,
  },
  pool: {
    max: 20,
    min: 5,
    idleTimeoutMillis: 30000,
  },
};

let pool = null;
let poolError = null;

function applyParams(request, params = {}) {
  Object.entries(params).forEach(([key, value]) => {
    if (value === null || value === undefined) {
      request.input(key, sql.NVarChar(sql.MAX), null);
    } else if (value instanceof Date) {
      request.input(key, sql.DateTime2, value);
    } else if (typeof value === 'boolean') {
      request.input(key, sql.Bit, value);
    } else if (typeof value === 'number') {
      request.input(key, value);
    } else if (typeof value === 'string') {
      // Auto-detect datetime strings (ISO 8601 or similar)
      if (/^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}/.test(value)) {
        request.input(key, sql.DateTime2, new Date(value));
      } else if (/^-?\d+$/.test(value) && !(value.length > 1 && value.startsWith('0'))) {
        const num = BigInt(value);
        if (num <= 2147483647n && num >= -2147483648n) {
          request.input(key, sql.Int, Number(num));
        } else {
          request.input(key, sql.BigInt, num);
        }
      } else if (/^-?\d+\.?\d*$/.test(value) && !(value.length > 1 && value.startsWith('0'))) {
        request.input(key, sql.Decimal(28, 10), parseFloat(value));
      } else {
        request.input(key, sql.NVarChar(sql.MAX), value);
      }
    } else {
      request.input(key, sql.NVarChar(sql.MAX), String(value));
    }
  });
}

async function getPool() {
  if (poolError) {
    const err = poolError;
    poolError = null;
    pool = null;
    throw err;
  }
  if (!pool) {
    pool = await sql.connect(config);
    pool.on('error', (err) => {
      console.error('[DB] Pool error:', err.message);
      poolError = err;
      pool = null;
    });
  }
  return pool;
}

async function query(queryStr, params = {}) {
  const p = await getPool();
  const request = p.request();
  applyParams(request, params);
  return request.query(queryStr);
}

async function execute(procName, params = {}) {
  const p = await getPool();
  const request = p.request();
  applyParams(request, params);
  return request.execute(procName);
}

// Transaction-scoped query
async function txQuery(transaction, queryStr, params = {}) {
  const request = transaction.request();
  applyParams(request, params);
  return request.query(queryStr);
}

// Transaction-scoped execute
async function txExecute(transaction, procName, params = {}) {
  const request = transaction.request();
  applyParams(request, params);
  return request.execute(procName);
}

async function safeRollback(transaction) {
  try {
    await transaction.rollback();
  } catch (err) {
    console.error('[DB] Rollback failed (transaction may already be aborted):', err.message);
  }
}

async function getTransaction() {
  const p = await getPool();
  const transaction = p.transaction();
  await transaction.begin();
  transaction.safeRollback = () => safeRollback(transaction);
  return transaction;
}

async function closePool() {
  if (pool) {
    await pool.close();
    pool = null;
  }
}

module.exports = {
  sql, getPool, query, execute,
  txQuery, txExecute, getTransaction, safeRollback, closePool,
};
