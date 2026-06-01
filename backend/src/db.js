import sql from 'mssql';
import { config } from './config.js';

const pools = new Map();

const roleForPool = (roleCode) => (config.logins[roleCode] ? roleCode : 'Customer');

export const sqlTypes = {
  int: sql.Int,
  bigInt: sql.BigInt,
  bit: sql.Bit,
  decimal: sql.Decimal(19, 4),
  date: sql.Date,
  time: sql.Time,
  dateTime: sql.DateTime2,
  nvarchar: sql.NVarChar(sql.MAX)
};

export function normalizeRecordset(recordset = []) {
  const first = recordset[0] || {};
  return {
    columns: Object.keys(first),
    rows: recordset,
    summary: { rowCount: recordset.length }
  };
}

async function getPool(roleCode) {
  const role = roleForPool(roleCode);
  if (pools.has(role)) return pools.get(role);

  const login = role === 'auth' ? config.logins.auth : config.logins[role];
  if (!login?.user || !login?.password) {
    throw new Error(`Missing database login configuration for ${role}`);
  }

  const pool = new sql.ConnectionPool({
    ...config.db,
    user: login.user,
    password: login.password
  });
  pools.set(role, pool.connect());
  return pools.get(role);
}

export async function withSession(user, handler) {
  const pool = await getPool(user.roleCode);
  const transaction = new sql.Transaction(pool);
  await transaction.begin();

  try {
    const contextRequest = new sql.Request(transaction);
    contextRequest.input('UserID', sql.Int, user.userId);
    contextRequest.input('Username', sql.NVarChar(50), user.username);
    contextRequest.input('RoleCode', sql.NVarChar(40), user.roleCode);
    await contextRequest.query(`
      EXEC sys.sp_set_session_context @key=N'UserID', @value=@UserID;
      EXEC sys.sp_set_session_context @key=N'Username', @value=@Username;
      EXEC sys.sp_set_session_context @key=N'RoleCode', @value=@RoleCode;
    `);

    const result = await handler(transaction);
    await transaction.commit();
    return result;
  } catch (error) {
    if (transaction._aborted !== true) await transaction.rollback();
    throw error;
  }
}

export async function authQuery(handler) {
  const pool = await getPool('auth');
  return handler(pool);
}

export async function closePools() {
  await Promise.all([...pools.values()].map(async (poolPromise) => {
    const pool = await poolPromise;
    await pool.close();
  }));
}
