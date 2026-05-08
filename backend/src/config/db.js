const sql = require('mssql');

const config = {
  server: process.env.DB_SERVER,
  port: parseInt(process.env.DB_PORT) || 1433,
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

// Debug: Log environment variables (excluding password)
console.log('DB Config:');
console.log(`  SERVER: ${process.env.DB_SERVER}`);
console.log(`  PORT: ${process.env.DB_PORT}`);
console.log(`  USER: ${process.env.DB_USER}`);
console.log(`  DATABASE: ${process.env.DB_NAME}`);

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

async function closePool() {
  if (pool) {
    await pool.close();
    pool = null;
  }
}

module.exports = { sql, getPool, query, closePool };
