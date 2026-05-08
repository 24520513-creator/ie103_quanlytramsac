const sql = require('mssql');
require('dotenv').config();

const config = {
  server: process.env.DB_SERVER,
  port: parseInt(process.env.DB_PORT),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  options: {
    encrypt: false,
    trustServerCertificate: true,
    enableArithAbort: true,
  },
  pool: {
    max: 20,
    min: 5,
    idleTimeoutMillis: 30000,
  },
};

let pool = null;

async function getPool() {
  if (!pool) {
    pool = await sql.connect(config);
  }
  return pool;
}

async function query(queryStr, params = {}) {
  const p = await getPool();
  const request = p.request();
  Object.entries(params).forEach(([key, value]) => {
    request.input(key, value);
  });
  const result = await request.query(queryStr);
  return result;
}

async function execute(procName, params = {}) {
  const p = await getPool();
  const request = p.request();
  Object.entries(params).forEach(([key, value]) => {
    request.input(key, value);
  });
  const result = await request.execute(procName);
  return result;
}

async function getTransaction() {
  const p = await getPool();
  const transaction = p.transaction();
  await transaction.begin();
  return transaction;
}

module.exports = { sql, getPool, query, execute, getTransaction };
