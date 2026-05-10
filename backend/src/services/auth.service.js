const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { query } = require('../config/database');
const { ConflictError, UnauthorizedError, ValidationError } = require('../utils/response');
const authConfig = require('../config/auth');

const SALT_ROUNDS = parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12;

async function signup({ FullName, Email, Phone, Password }) {
  if (!Email || !Email.includes('@')) throw new ValidationError('Valid email is required');
  if (!Password || Password.length < 6) throw new ValidationError('Password must be at least 6 characters');
  if (!FullName || FullName.trim().length === 0) throw new ValidationError('Full name is required');

  const existing = await query(`SELECT UserID FROM [Users].[User] WHERE Email = @Email`, { Email });
  if (existing.recordset.length > 0) throw new ConflictError('Email already registered');

  const salt = await bcrypt.genSalt(SALT_ROUNDS);
  const hash = await bcrypt.hash(Password, salt);

  const userResult = await query(
    `INSERT INTO [Users].[User] (Username, Email, Phone, PasswordHash, FullName, Role, AccountStatus, CreatedAt)
     OUTPUT INSERTED.*
     VALUES (@Username, @Email, @Phone, @Hash, @FullName, 'Customer', 'Active', SYSDATETIME())`,
    { Username: Email.split('@')[0], Email, Phone: Phone || null, Hash: hash, FullName }
  );
  const user = userResult.recordset[0];

  await query(`INSERT INTO Payments.Wallet (UserID, WalletCode, Balance) VALUES (@UserID, @Code, 0)`,
    { UserID: user.UserID, Code: 'WAL-' + user.Username });

  const token = jwt.sign(
    { UserID: user.UserID, Email: user.Email, Role: 'Customer' },
    authConfig.jwtSecret, { expiresIn: authConfig.jwtExpiresIn }
  );

  return { token, user: { UserID: user.UserID, Email: user.Email, FullName, Phone: Phone || null, Role: 'Customer' } };
}

async function signin({ Email, Password }) {
  const userResult = await query(
    `SELECT * FROM [Users].[User] WHERE Email = @Email`, { Email }
  );

  if (userResult.recordset.length === 0) throw new UnauthorizedError('Invalid email or password');
  const user = userResult.recordset[0];

  if (user.AccountStatus !== 'Active') throw new UnauthorizedError(`Account is ${user.AccountStatus}`);
  if (user.LockoutEnd && new Date(user.LockoutEnd) > new Date()) {
    throw new UnauthorizedError('Account is temporarily locked. Try again later.');
  }

  const valid = await bcrypt.compare(Password, user.PasswordHash);
  if (!valid) {
    await query(`UPDATE [Users].[User] SET FailedLoginAttempts = FailedLoginAttempts + 1 WHERE UserID = @UserID`,
      { UserID: user.UserID });
    if (user.FailedLoginAttempts + 1 >= 5) {
      await query(`UPDATE [Users].[User] SET LockoutEnd = DATEADD(HOUR, 1, SYSDATETIME()) WHERE UserID = @UserID`,
        { UserID: user.UserID });
    }
    throw new UnauthorizedError('Invalid email or password');
  }

  await query(`UPDATE [Users].[User] SET FailedLoginAttempts = 0, LastLoginAt = SYSDATETIME() WHERE UserID = @UserID`,
    { UserID: user.UserID });

  const token = jwt.sign(
    { UserID: user.UserID, Email: user.Email, Role: user.Role, FullName: user.FullName, FranchiseID: user.FranchiseID },
    authConfig.jwtSecret, { expiresIn: authConfig.jwtExpiresIn }
  );

  return { token, user: { UserID: user.UserID, Email: user.Email, FullName: user.FullName, Phone: user.Phone, Role: user.Role } };
}

async function forgotPassword({ Email }) {
  const user = await query(`SELECT UserID, Email FROM [Users].[User] WHERE Email = @Email`, { Email });
  if (user.recordset.length === 0) return { message: 'If the email exists, a reset link has been sent.' };

  const token = jwt.sign(
    { UserID: user.recordset[0].UserID, Email: user.recordset[0].Email, purpose: 'password-reset' },
    authConfig.jwtSecret, { expiresIn: '15m' }
  );
  return { message: 'If the email exists, a reset link has been sent.', resetToken: token };
}

async function resetPassword({ Token, Password }) {
  let decoded;
  try { decoded = jwt.verify(Token, authConfig.jwtSecret); }
  catch (err) { throw new ValidationError('Invalid or expired reset token'); }
  if (decoded.purpose !== 'password-reset') throw new ValidationError('Invalid reset token');

  const salt = await bcrypt.genSalt(SALT_ROUNDS);
  const hash = await bcrypt.hash(Password, salt);
  await query(`UPDATE [Users].[User] SET PasswordHash = @Hash, UpdatedAt = SYSDATETIME() WHERE UserID = @UserID`,
    { UserID: decoded.UserID, Hash: hash });

  return { message: 'Password has been reset successfully.' };
}

module.exports = { signup, signin, forgotPassword, resetPassword };
