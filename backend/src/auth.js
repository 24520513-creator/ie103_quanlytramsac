import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import sql from 'mssql';
import { authQuery } from './db.js';
import { config } from './config.js';

const rolePriority = ['SystemAdmin', 'OperationsStaff', 'BusinessManager', 'FranchisePartner', 'Customer'];
const genericLoginError = 'Thông tin đăng nhập không đúng hoặc tài khoản không khả dụng.';
const commonPasswords = new Set(['password', '123456', '123456789', 'admin123', 'qwerty123', '111111', 'abc123456']);
const devResetTokens = new Map();

function authError(message, statusCode = 400) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function pickPrimaryRole(roles) {
  return rolePriority.find((role) => roles.includes(role)) || roles[0];
}

function publicUserPayload(user, roles) {
  return {
    userId: user.UserID,
    username: user.Username,
    fullName: user.FullName,
    email: user.Email,
    phone: user.Phone,
    accountStatus: user.AccountStatus,
    roles,
    roleCode: pickPrimaryRole(roles)
  };
}

function signUser(user, roles) {
  const payload = publicUserPayload(user, roles);
  return {
    token: jwt.sign(payload, config.jwtSecret, { expiresIn: config.auth.accessTokenTtl }),
    user: payload
  };
}

export function validatePassword(password) {
  const value = String(password || '');
  if (value.length < 10) throw authError('Mật khẩu phải có ít nhất 10 ký tự.');
  if (commonPasswords.has(value.toLowerCase())) throw authError('Mật khẩu quá phổ biến, vui lòng chọn mật khẩu khác.');
  if (!/[A-Za-zÀ-ỹ]/.test(value) || !/\d/.test(value)) throw authError('Mật khẩu phải có cả chữ và số.');
}

export async function hashPassword(password) {
  validatePassword(password);
  return bcrypt.hash(password, 12);
}

export function hashToken(token) {
  return crypto.createHash('sha256').update(String(token || '')).digest('hex');
}

export function issuePlainToken() {
  return crypto.randomBytes(32).toString('base64url');
}

export async function login(identifier, password) {
  const value = String(identifier || '').trim();
  if (!value || !password) throw authError(genericLoginError, 401);

  const result = await authQuery(async (pool) => {
    const request = pool.request();
    request.input('Identifier', sql.NVarChar(120), value);
    return request.query(`
      SELECT u.UserID, u.Username, u.FullName, u.Email, u.Phone, u.PasswordHash, u.AccountStatus, r.RoleCode
      FROM [Identity].UserAccount u
      JOIN [Identity].UserRole ur ON ur.UserID = u.UserID
      JOIN [Identity].[Role] r ON r.RoleID = ur.RoleID
      WHERE u.Username = @Identifier OR u.Email = @Identifier OR u.Phone = @Identifier
    `);
  });

  if (result.recordset.length === 0) {
    await bcrypt.compare(String(password), '$2a$12$5NoW5vSX5wU0NdCu79aIXOkSjLj1RtAfCY7APMWlwie3kgUc11f/m');
    throw authError(genericLoginError, 401);
  }

  const user = result.recordset[0];
  const roles = [...new Set(result.recordset.map((row) => row.RoleCode))];
  const hash = user.PasswordHash || '';
  const demoPasswordOk = hash.includes('DemoHashForIE103DatabaseOnly') && password === 'password';
  const exactHashOk = password === hash;
  const bcryptOk = hash.startsWith('$2') ? await bcrypt.compare(password, hash) : false;
  if (!demoPasswordOk && !exactHashOk && !bcryptOk) throw authError(genericLoginError, 401);

  if (user.AccountStatus === 'Pending') throw authError('Tài khoản đang chờ xác minh. Vui lòng kiểm tra email hoặc liên hệ quản trị viên.', 403);
  if (user.AccountStatus === 'Locked') throw authError('Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên.', 403);
  if (user.AccountStatus === 'Suspended') throw authError('Tài khoản đang bị tạm ngưng. Vui lòng liên hệ bộ phận hỗ trợ.', 403);
  if (user.AccountStatus !== 'Active') throw authError(genericLoginError, 401);

  await authQuery(async (pool) => {
    const request = pool.request();
    request.input('UserID', sql.Int, user.UserID);
    return request.query(`
      UPDATE [Identity].UserAccount
      SET LastLoginAt = SYSDATETIME(), UpdatedAt = SYSDATETIME()
      WHERE UserID = @UserID
    `);
  });

  return signUser(user, roles);
}

export async function registerCustomer({ username, email, phone, password, fullName }) {
  const clean = {
    username: String(username || '').trim(),
    email: String(email || '').trim().toLowerCase(),
    phone: String(phone || '').trim(),
    fullName: String(fullName || '').trim()
  };

  if (!/^[a-zA-Z0-9._-]{4,50}$/.test(clean.username)) throw authError('Tên đăng nhập phải có 4-50 ký tự, chỉ gồm chữ, số, dấu chấm, gạch dưới hoặc gạch ngang.');
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(clean.email)) throw authError('Email không hợp lệ.');
  if (!clean.fullName || clean.fullName.length < 2) throw authError('Họ và tên không hợp lệ.');
  if (clean.phone && !/^[0-9+()\s.-]{8,20}$/.test(clean.phone)) throw authError('Số điện thoại không hợp lệ.');

  const passwordHash = await hashPassword(password);
  let result;
  try {
    result = await authQuery(async (pool) => {
      const request = pool.request();
      request.input('Username', sql.NVarChar(50), clean.username);
      request.input('Email', sql.NVarChar(120), clean.email);
      request.input('Phone', sql.NVarChar(20), clean.phone || null);
      request.input('PasswordHash', sql.NVarChar(256), passwordHash);
      request.input('FullName', sql.NVarChar(120), clean.fullName);
      return request.execute('[Identity].sp_RegisterCustomer');
    });
  } catch (error) {
    if (!isMissingAuthProcedure(error)) throw normalizeSqlAuthError(error);
    result = await directRegisterCustomer(clean, passwordHash);
  }

  return {
    columns: Object.keys(result.recordset?.[0] || {}),
    rows: result.recordset || [],
    summary: { rowCount: result.recordset?.length || 0 },
    message: 'Đăng kí tài khoản khách hàng thành công. Bạn có thể đăng nhập ngay.'
  };
}

export async function requestPasswordReset(identifier) {
  const plainToken = issuePlainToken();
  let row;
  try {
    const result = await authQuery(async (pool) => {
      const request = pool.request();
      request.input('Identifier', sql.NVarChar(120), String(identifier || '').trim());
      request.input('TokenHash', sql.NVarChar(128), hashToken(plainToken));
      request.input('ExpiresAt', sql.DateTime2, new Date(Date.now() + config.auth.resetTokenMinutes * 60 * 1000));
      return request.execute('[Identity].sp_RequestPasswordReset');
    });
    row = result.recordset?.[0];
  } catch (error) {
    if (!isMissingAuthProcedure(error)) throw error;
    row = await directRequestPasswordReset(identifier, plainToken);
  }

  if (row?.UserID && config.auth.logResetTokens) {
    console.log(`[DEV RESET LINK] ${config.frontendUrl}/reset-password?token=${plainToken}`);
  }

  return {
    message: 'Nếu thông tin hợp lệ, hệ thống đã gửi hướng dẫn đặt lại mật khẩu.',
    devResetToken: config.auth.logResetTokens && row?.UserID ? plainToken : undefined
  };
}

export async function resetPassword(token, password) {
  const passwordHash = await hashPassword(password);
  try {
    await authQuery(async (pool) => {
      const request = pool.request();
      request.input('TokenHash', sql.NVarChar(128), hashToken(token));
      request.input('PasswordHash', sql.NVarChar(256), passwordHash);
      return request.execute('[Identity].sp_ResetPasswordByToken');
    });
  } catch (error) {
    if (!isMissingAuthProcedure(error)) throw error;
    await directResetPassword(token, passwordHash);
  }
  return { message: 'Mật khẩu đã được cập nhật. Vui lòng đăng nhập lại.' };
}

export async function verifyEmail(token) {
  await authQuery(async (pool) => {
    const request = pool.request();
    request.input('TokenHash', sql.NVarChar(128), hashToken(token));
    return request.execute('[Identity].sp_VerifyEmailToken');
  });
  return { message: 'Email đã được xác minh.' };
}

function readCookieToken(req) {
  const cookie = req.headers.cookie || '';
  const found = cookie.split(';').map((item) => item.trim()).find((item) => item.startsWith(`${config.auth.cookieName}=`));
  return found ? decodeURIComponent(found.slice(config.auth.cookieName.length + 1)) : '';
}

export function requireAuth(req, res, next) {
  const bearerToken = req.headers.authorization?.replace(/^Bearer\s+/i, '');
  const token = bearerToken || readCookieToken(req);
  if (!token) return res.status(401).json({ message: 'Chưa đăng nhập.' });

  try {
    req.user = jwt.verify(token, config.jwtSecret);
    next();
  } catch {
    res.status(401).json({ message: 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.' });
  }
}

function isMissingAuthProcedure(error) {
  const message = error.originalError?.info?.message || error.message || '';
  return error.number === 2812 || /sp_RegisterCustomer|sp_RequestPasswordReset|sp_ResetPasswordByToken|sp_VerifyEmailToken|Could not find stored procedure/i.test(message);
}

function normalizeSqlAuthError(error) {
  const number = error.number || error.originalError?.info?.number;
  if ([2601, 2627].includes(number)) return authError('Tên đăng nhập, email hoặc số điện thoại đã được sử dụng.');
  return error;
}

async function directRegisterCustomer(clean, passwordHash) {
  return authQuery(async (pool) => {
    const transaction = new sql.Transaction(pool);
    await transaction.begin();
    try {
      let request = new sql.Request(transaction);
      request.input('Username', sql.NVarChar(50), clean.username);
      request.input('Email', sql.NVarChar(120), clean.email);
      request.input('Phone', sql.NVarChar(20), clean.phone || null);
      const duplicate = await request.query(`
        SELECT TOP 1 Username, Email, Phone
        FROM [Identity].UserAccount
        WHERE Username = @Username OR Email = @Email OR (@Phone IS NOT NULL AND Phone = @Phone)
      `);
      if (duplicate.recordset.length > 0) throw authError('Tên đăng nhập, email hoặc số điện thoại đã được sử dụng.');

      request = new sql.Request(transaction);
      request.input('Username', sql.NVarChar(50), clean.username);
      request.input('Email', sql.NVarChar(120), clean.email);
      request.input('Phone', sql.NVarChar(20), clean.phone || null);
      request.input('PasswordHash', sql.NVarChar(256), passwordHash);
      request.input('FullName', sql.NVarChar(120), clean.fullName);
      const inserted = await request.query(`
        DECLARE @RoleID INT = (SELECT RoleID FROM [Identity].[Role] WHERE RoleCode = N'Customer');
        IF @RoleID IS NULL THROW 51104, N'Vai trò Customer chưa tồn tại.', 1;

        INSERT INTO [Identity].UserAccount (Username, Email, Phone, PasswordHash, FullName, AccountStatus)
        VALUES (@Username, @Email, NULLIF(@Phone, N''), @PasswordHash, @FullName, N'Active');

        DECLARE @UserID INT = SCOPE_IDENTITY();
        INSERT INTO [Identity].UserRole (UserID, RoleID) VALUES (@UserID, @RoleID);
        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Identity', N'UserAccount', CAST(@UserID AS NVARCHAR(100)), N'SECURITY', N'Register customer');

        SELECT UserID, Username, Email, Phone, FullName, AccountStatus
        FROM [Identity].UserAccount
        WHERE UserID = @UserID;
      `);
      await transaction.commit();
      return inserted;
    } catch (error) {
      if (transaction._aborted !== true) await transaction.rollback();
      throw normalizeSqlAuthError(error);
    }
  });
}

async function directRequestPasswordReset(identifier, plainToken) {
  const value = String(identifier || '').trim();
  const result = await authQuery(async (pool) => {
    const request = pool.request();
    request.input('Identifier', sql.NVarChar(120), value);
    return request.query(`
      SELECT TOP 1 UserID
      FROM [Identity].UserAccount
      WHERE Username = @Identifier OR Email = @Identifier OR Phone = @Identifier
    `);
  });
  const row = result.recordset?.[0];
  if (row?.UserID) {
    devResetTokens.set(hashToken(plainToken), {
      userId: row.UserID,
      expiresAt: Date.now() + config.auth.resetTokenMinutes * 60 * 1000
    });
  }
  return row || { UserID: null };
}

async function directResetPassword(token, passwordHash) {
  const key = hashToken(token);
  const entry = devResetTokens.get(key);
  if (!entry || entry.expiresAt < Date.now()) {
    devResetTokens.delete(key);
    throw authError('Token đặt lại mật khẩu không hợp lệ hoặc đã hết hạn.');
  }

  await authQuery(async (pool) => {
    const request = pool.request();
    request.input('UserID', sql.Int, entry.userId);
    request.input('PasswordHash', sql.NVarChar(256), passwordHash);
    return request.query(`
      UPDATE [Identity].UserAccount
      SET PasswordHash = @PasswordHash, UpdatedAt = SYSDATETIME()
      WHERE UserID = @UserID;

      INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
      VALUES (N'Identity', N'UserAccount', CAST(@UserID AS NVARCHAR(100)), N'SECURITY', N'Password reset by dev token');
    `);
  });
  devResetTokens.delete(key);
}
