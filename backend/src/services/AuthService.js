const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const authConfig = require('../config/auth');
const { query } = require('../config/database');
const { UnauthorizedError, ValidationError, NotFoundError } = require('../utils/response');

class AuthService {
  async register({ Username, Email, Password, FullName, Phone, Role }) {
    const existing = await query(`SELECT UserID FROM [Users].[User] WHERE Email = @Email OR Username = @Username`,
      { Email, Username });
    if (existing.recordset.length > 0) throw new ValidationError('Username or email already exists');

    const role = Role || 'Customer';
    if (!['Customer', 'Manager', 'Admin'].includes(role)) throw new ValidationError('Invalid role');

    const salt = await bcrypt.genSalt(authConfig.bcryptSaltRounds);
    const hash = await bcrypt.hash(Password, salt);
    const username = Username || Email.split('@')[0];

    const userResult = await query(`INSERT INTO [Users].[User]
      (Username, Email, Phone, PasswordHash, FullName, Role, AccountStatus, CreatedAt)
      OUTPUT INSERTED.*
      VALUES (@Username, @Email, @Phone, @Hash, @FullName, @Role, 'Active', SYSDATETIME())`, {
      Username: username, Email, Phone: Phone || null, Hash: hash,
      FullName: FullName || username, Role: role,
    });
    const user = userResult.recordset[0];

    await query(`INSERT INTO Payments.Wallet (UserID, WalletCode, Balance)
      VALUES (@UserID, @Code, 0)`, { UserID: user.UserID, Code: 'WAL-' + username });

    return { UserID: user.UserID, Username: user.Username, Email: user.Email, Role: user.Role };
  }

  async login({ Email, Password, IPAddress, UserAgent }) {
    const userResult = await query(`SELECT * FROM [Users].[User] WHERE (Email = @Email OR Username = @Email)`,
      { Email });
    if (userResult.recordset.length === 0) throw new UnauthorizedError('Invalid credentials');

    const user = userResult.recordset[0];
    if (user.AccountStatus !== 'Active') throw new UnauthorizedError(`Account is ${user.AccountStatus}`);
    if (user.LockoutEnd && new Date(user.LockoutEnd) > new Date()) {
      throw new UnauthorizedError('Account is locked. Try again later.');
    }

    const valid = await bcrypt.compare(Password, user.PasswordHash);
    if (!valid) {
      await query(`UPDATE [Users].[User] SET FailedLoginAttempts = FailedLoginAttempts + 1 WHERE UserID = @UserID`,
        { UserID: user.UserID });
      const attempts = user.FailedLoginAttempts + 1;
      if (attempts >= 5) {
        await query(`UPDATE [Users].[User] SET LockoutEnd = DATEADD(HOUR, 1, SYSDATETIME()) WHERE UserID = @UserID`,
          { UserID: user.UserID });
      }
      throw new UnauthorizedError('Invalid credentials');
    }

    await query(`UPDATE [Users].[User] SET FailedLoginAttempts = 0, LastLoginAt = SYSDATETIME() WHERE UserID = @UserID`,
      { UserID: user.UserID });

    const token = jwt.sign(
      { UserID: user.UserID, Username: user.Username, Email: user.Email, Role: user.Role, FullName: user.FullName, FranchiseID: user.FranchiseID },
      authConfig.jwtSecret, { expiresIn: authConfig.jwtExpiresIn }
    );

    return { token, user: { UserID: user.UserID, Username: user.Username, Email: user.Email, FullName: user.FullName, Role: user.Role, FranchiseID: user.FranchiseID } };
  }

  async getProfile(userId) {
    const user = await query(`SELECT UserID, Username, Email, Phone, FullName, AvatarUrl, Role,
      FranchiseID, AccountStatus, LastLoginAt, CreatedAt
      FROM [Users].[User] WHERE UserID = @UserID`, { UserID: userId });
    if (user.recordset.length === 0) throw new NotFoundError('User');
    return user.recordset[0];
  }

  async updateProfile(userId, data) {
    const allowed = ['FullName', 'AvatarUrl', 'Phone'];
    const updates = Object.entries(data).filter(([k]) => allowed.includes(k));
    if (updates.length === 0) return this.getProfile(userId);
    const setClause = updates.map(([k]) => `[${k}] = @${k}`).join(', ');
    await query(`UPDATE [Users].[User] SET ${setClause}, UpdatedAt = SYSDATETIME() WHERE UserID = @UserID`,
      { ...Object.fromEntries(updates), UserID: userId });
    return this.getProfile(userId);
  }

  async forgotPassword({ Email }) {
    const user = await query(`SELECT UserID, Email FROM [Users].[User] WHERE Email = @Email`, { Email });
    if (user.recordset.length === 0) return { message: 'If the email exists, a reset link has been sent.' };

    const token = jwt.sign(
      { UserID: user.recordset[0].UserID, Email: user.recordset[0].Email, purpose: 'password-reset' },
      authConfig.jwtSecret, { expiresIn: '15m' }
    );
    return { message: 'If the email exists, a reset link has been sent.', resetToken: token };
  }

  async resetPassword({ Token, Password }) {
    let decoded;
    try { decoded = jwt.verify(Token, authConfig.jwtSecret); }
    catch (err) { throw new ValidationError('Invalid or expired reset token'); }
    if (decoded.purpose !== 'password-reset') throw new ValidationError('Invalid reset token');

    const salt = await bcrypt.genSalt(authConfig.bcryptSaltRounds);
    const hash = await bcrypt.hash(Password, salt);
    await query(`UPDATE [Users].[User] SET PasswordHash = @Hash, UpdatedAt = SYSDATETIME() WHERE UserID = @UserID`,
      { UserID: decoded.UserID, Hash: hash });

    return { message: 'Password has been reset successfully.' };
  }
}

module.exports = new AuthService();
