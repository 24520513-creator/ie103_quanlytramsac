const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const authConfig = require('../config/auth');
const { execute } = require('../config/database');
const { UnauthorizedError, ValidationError, NotFoundError } = require('../utils/response');

class AuthService {
  async register({ Username, Email, Password, FullName, Phone, Role }) {
    if (!Email || !Email.includes('@')) throw new ValidationError('Valid email is required');
    if (!Password || Password.length < 6) throw new ValidationError('Password must be at least 6 characters');
    if (!FullName || !FullName.trim()) throw new ValidationError('Full name is required');

    const role = Role || 'Customer';
    if (!['Customer', 'Manager', 'Admin'].includes(role)) throw new ValidationError('Invalid role');
    if (!['Customer', 'Manager', 'Admin'].includes(role)) throw new ValidationError('Invalid role');

    const salt = await bcrypt.genSalt(authConfig.bcryptSaltRounds);
    const hash = await bcrypt.hash(Password, salt);
    const username = Username || Email.split('@')[0];

    const result = await execute('Users.sp_RegisterUser', {
      Username: username, Email, Phone: Phone || null,
      PasswordHash: hash, FullName: FullName || username, Role: role,
    });
    if (!result.recordset || result.recordset.length === 0) throw new Error('Registration failed');
    const user = result.recordset[0];
    return { UserID: user.UserID, Username: user.Username, Email: user.Email, Role: user.Role };
  }

  async login({ Email, Password, IPAddress, UserAgent }) {
    const userResult = await execute('Users.sp_GetUserByLogin', { Login: Email });
    if (userResult.recordset.length === 0) throw new UnauthorizedError('Invalid credentials');

    const user = userResult.recordset[0];
    if (user.AccountStatus !== 'Active') throw new UnauthorizedError(`Account is ${user.AccountStatus}`);
    if (user.LockoutEnd && new Date(user.LockoutEnd) > new Date()) {
      throw new UnauthorizedError('Account is locked. Try again later.');
    }

    const valid = await bcrypt.compare(Password, user.PasswordHash);
    if (!valid) {
      const newAttempts = (user.FailedLoginAttempts || 0) + 1;
      await execute('Users.sp_UpdateFailedLoginAttempts', { UserID: user.UserID, Attempts: newAttempts });
      throw new UnauthorizedError('Invalid credentials');
    }

    await execute('Users.sp_ResetLoginSuccess', { UserID: user.UserID });

    const token = jwt.sign(
      { UserID: user.UserID, Username: user.Username, Email: user.Email, Role: user.Role, FullName: user.FullName, FranchiseID: user.FranchiseID },
      authConfig.jwtSecret, { expiresIn: authConfig.jwtExpiresIn }
    );

    return { token, user: { UserID: user.UserID, Username: user.Username, Email: user.Email, FullName: user.FullName, Role: user.Role, FranchiseID: user.FranchiseID } };
  }

  async getProfile(userId) {
    const result = await execute('Users.sp_GetUserProfile', { UserID: userId });
    if (!result.recordset || result.recordset.length === 0) throw new NotFoundError('User');
    return result.recordset[0];
  }

  async updateProfile(userId, data) {
    const allowed = ['FullName', 'AvatarUrl', 'Phone'];
    const updates = Object.entries(data).filter(([k]) => allowed.includes(k));
    if (updates.length === 0) return this.getProfile(userId);
    const params = { UserID: userId };
    for (const [k, v] of updates) params[k] = v;
    const result = await execute('Users.sp_UpdateUserProfile', params);
    if (!result.recordset || result.recordset.length === 0) throw new NotFoundError('User');
    return result.recordset[0];
  }

  async forgotPassword({ Email }) {
    if (!Email) throw new ValidationError('Email is required');
    const result = await execute('Users.sp_CheckEmailExists', { Email });
    if (result.recordset.length === 0) return { message: 'If the email exists, a reset link has been sent.' };

    const token = jwt.sign(
      { UserID: result.recordset[0].UserID, Email: result.recordset[0].Email, purpose: 'password-reset' },
      authConfig.jwtSecret, { expiresIn: '15m' }
    );
    return { message: 'If the email exists, a reset link has been sent.', resetToken: token };
  }

  async resetPassword({ Token, Password }) {
    if (!Token) throw new ValidationError('Reset token is required');
    if (!Password || Password.length < 6) throw new ValidationError('Password must be at least 6 characters');

    let decoded;
    try { decoded = jwt.verify(Token, authConfig.jwtSecret); }
    catch { throw new ValidationError('Invalid or expired reset token'); }
    if (decoded.purpose !== 'password-reset') throw new ValidationError('Invalid reset token');

    const salt = await bcrypt.genSalt(authConfig.bcryptSaltRounds);
    const hash = await bcrypt.hash(Password, salt);
    await execute('Users.sp_UpdatePassword', { UserID: decoded.UserID, PasswordHash: hash });

    return { message: 'Password has been reset successfully.' };
  }
}

module.exports = new AuthService();
