import dotenv from 'dotenv';

dotenv.config();

const bool = (value, fallback = false) => {
  if (value === undefined) return fallback;
  return ['1', 'true', 'yes'].includes(String(value).toLowerCase());
};

const dbServerRaw = process.env.DB_SERVER || 'localhost\\SQLEXPRESS';
const dbPort = process.env.DB_PORT ? Number(process.env.DB_PORT) : undefined;
const [dbHostRaw, dbInstanceName] = dbServerRaw.split('\\');
const dbServer = dbHostRaw === '.' ? 'localhost' : dbHostRaw;
const dbBase = {
  server: dbServer,
  database: process.env.DB_DATABASE || 'EV_Charging_System',
  options: {
    encrypt: bool(process.env.DB_ENCRYPT, false),
    trustServerCertificate: bool(process.env.DB_TRUST_SERVER_CERTIFICATE, true),
    ...(dbInstanceName ? { instanceName: dbInstanceName } : {})
  }
};

if (dbPort && !dbInstanceName) {
  dbBase.port = dbPort;
}

export const config = {
  port: Number(process.env.PORT || 8000),
  frontendUrl: process.env.FRONTEND_URL || 'http://localhost:3000',
  jwtSecret: process.env.JWT_SECRET || 'dev-secret',
  auth: {
    cookieName: process.env.AUTH_COOKIE_NAME || 'ev_session',
    accessTokenTtl: process.env.ACCESS_TOKEN_TTL || '8h',
    cookieMaxAgeMs: Number(process.env.AUTH_COOKIE_MAX_AGE_MS || 8 * 60 * 60 * 1000),
    resetTokenMinutes: Number(process.env.RESET_TOKEN_MINUTES || 30),
    logResetTokens: bool(process.env.LOG_RESET_TOKENS, true)
  },
  db: dbBase,
  logins: {
    auth: { user: process.env.DB_AUTH_USER || process.env.DB_ADMIN_USER, password: process.env.DB_AUTH_PASSWORD || process.env.DB_ADMIN_PASSWORD },
    SystemAdmin: { user: process.env.DB_ADMIN_USER, password: process.env.DB_ADMIN_PASSWORD },
    OperationsStaff: { user: process.env.DB_OPERATOR_USER, password: process.env.DB_OPERATOR_PASSWORD },
    BusinessManager: { user: process.env.DB_BUSINESS_USER, password: process.env.DB_BUSINESS_PASSWORD },
    FranchisePartner: { user: process.env.DB_FRANCHISE_USER, password: process.env.DB_FRANCHISE_PASSWORD },
    Customer: { user: process.env.DB_CUSTOMER_USER, password: process.env.DB_CUSTOMER_PASSWORD }
  }
};
