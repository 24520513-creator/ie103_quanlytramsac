const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const authConfig = require('../config/auth');
const { query, sql } = require('../config/database');
const { UnauthorizedError, ValidationError, NotFoundError } = require('../utils/response');
const { UserProfileRepository, UserCredentialRepository, UserSessionRepository, UserLoginHistoryRepository, UserRoleRepository } = require('../repositories/UsersRepository');
const { UserModel } = require('../models/Users');

class AuthService {
  async register({ Username, Email, Password, FullName, Phone }) {
    const existing = await query(`SELECT UserID FROM [Users].[User] WHERE Email = @Email OR Username = @Username`,
      { Email, Username });
    if (existing.recordset.length > 0) throw new ValidationError('Username or email already exists');

    const salt = await bcrypt.genSalt(authConfig.bcryptSaltRounds);
    const hash = await bcrypt.hash(Password, salt);

    const userResult = await query(`INSERT INTO [Users].[User] (UserGuid, Username, Email, Phone, AccountStatus, CreatedAt)
      OUTPUT INSERTED.* VALUES (@Guid, @Username, @Email, @Phone, 'Active', SYSDATETIME())`, {
      Guid: uuidv4(), Username, Email, Phone: Phone || null,
    });
    const user = userResult.recordset[0];

    await query(`INSERT INTO [Users].[UserProfile] (UserID, FullName, CreatedAt) VALUES (@UserID, @FullName, SYSDATETIME())`,
      { UserID: user.UserID, FullName });

    await query(`INSERT INTO [Users].[UserCredential] (UserID, PasswordHash, PasswordSalt, HashAlgorithm, PasswordChangedAt)
      VALUES (@UserID, @Hash, @Salt, 'BCrypt', SYSDATETIME())`, {
      UserID: user.UserID, Hash: hash, Salt: salt,
    });

    const customerRole = await query(`SELECT RoleID FROM [Access].[Role] WHERE RoleCode = 'CUSTOMER'`);
    if (customerRole.recordset.length > 0) {
      await query(`INSERT INTO [Users].[UserRole] (UserID, RoleID, AssignedAt) VALUES (@UserID, @RoleID, SYSDATETIME())`,
        { UserID: user.UserID, RoleID: customerRole.recordset[0].RoleID });
    }

    return { UserID: user.UserID, Username: user.Username, Email: user.Email };
  }

  async login({ Email, Password, IPAddress, UserAgent }) {
    const userResult = await query(`SELECT * FROM [Users].[User] WHERE (Email = @Email OR Username = @Email) AND IsDeleted = 0`,
      { Email });
    if (userResult.recordset.length === 0) throw new UnauthorizedError('Invalid credentials');

    const user = userResult.recordset[0];
    if (user.AccountStatus !== 'Active') throw new UnauthorizedError(`Account is ${user.AccountStatus}`);

    if (user.LockoutEnd && new Date(user.LockoutEnd) > new Date()) {
      throw new UnauthorizedError('Account is locked. Try again later.');
    }

    const credResult = await query(`SELECT * FROM [Users].[UserCredential] WHERE UserID = @UserID`, { UserID: user.UserID });
    if (credResult.recordset.length === 0) throw new UnauthorizedError('No credentials configured');

    const cred = credResult.recordset[0];
    const valid = await bcrypt.compare(Password, cred.PasswordHash);
    if (!valid) {
      await query(`UPDATE [Users].[User] SET FailedLoginAttempts = FailedLoginAttempts + 1 WHERE UserID = @UserID`, { UserID: user.UserID });
      await this._logLogin(user.UserID, false, IPAddress, UserAgent, 'Invalid password');
      const attempts = user.FailedLoginAttempts + 1;
      if (attempts >= 5) {
        await query(`UPDATE [Users].[User] SET LockoutEnd = DATEADD(HOUR, 1, SYSDATETIME()) WHERE UserID = @UserID`, { UserID: user.UserID });
      }
      throw new UnauthorizedError('Invalid credentials');
    }

    await query(`UPDATE [Users].[User] SET FailedLoginAttempts = 0, LastLoginAt = SYSDATETIME() WHERE UserID = @UserID`, { UserID: user.UserID });

    const rolesResult = await query(`SELECT r.RoleCode FROM [Users].[UserRole] ur JOIN [Access].[Role] r ON ur.RoleID = r.RoleID WHERE ur.UserID = @UserID AND ur.IsActive = 1`,
      { UserID: user.UserID });
    const roles = rolesResult.recordset.map(r => r.RoleCode);

    const token = jwt.sign(
      { UserID: user.UserID, Username: user.Username, Email: user.Email, roles },
      authConfig.jwtSecret, { expiresIn: authConfig.jwtExpiresIn }
    );
    const refreshToken = uuidv4();

    await query(`INSERT INTO [Users].[UserSession] (UserID, SessionToken, RefreshToken, IPAddress, UserAgent, LoginAt, ExpiresAt)
      VALUES (@UserID, @Token, @Refresh, @IP, @UA, SYSDATETIME(), DATEADD(DAY, 7, SYSDATETIME()))`, {
      UserID: user.UserID, Token: token, Refresh: refreshToken, IP: IPAddress || null, UA: UserAgent || null,
    });

    await this._logLogin(user.UserID, true, IPAddress, UserAgent, 'Success');

    return {
      token, refreshToken,
      user: { UserID: user.UserID, Username: user.Username, Email: user.Email, roles },
    };
  }

  async refreshToken(refreshToken) {
    const sessionResult = await query(`SELECT us.*, u.Username, u.Email FROM [Users].[UserSession] us
      JOIN [Users].[User] u ON us.UserID = u.UserID
      WHERE us.RefreshToken = @Token AND us.IsRevoked = 0 AND us.ExpiresAt > SYSDATETIME()`, { Token: refreshToken });
    if (sessionResult.recordset.length === 0) throw new UnauthorizedError('Invalid or expired refresh token');

    const session = sessionResult.recordset[0];

    const rolesResult = await query(`SELECT r.RoleCode FROM [Users].[UserRole] ur JOIN [Access].[Role] r ON ur.RoleID = r.RoleID WHERE ur.UserID = @UserID AND ur.IsActive = 1`,
      { UserID: session.UserID });
    const roles = rolesResult.recordset.map(r => r.RoleCode);

    const token = jwt.sign(
      { UserID: session.UserID, Username: session.Username, Email: session.Email, roles },
      authConfig.jwtSecret, { expiresIn: authConfig.jwtExpiresIn }
    );

    await query(`UPDATE [Users].[UserSession] SET SessionToken = @Token WHERE SessionID = @SessionID`,
      { Token: token, SessionID: session.SessionID });

    return { token };
  }

  async logout(userId) {
    await query(`UPDATE [Users].[UserSession] SET IsRevoked = 1, RevokedAt = SYSDATETIME(), LogoutAt = SYSDATETIME() WHERE UserID = @UserID AND IsRevoked = 0`,
      { UserID: userId });
  }

  async getProfile(userId) {
    const user = await query(`SELECT u.*, up.FullName, up.DisplayName, up.AvatarUrl, up.DateOfBirth, up.Gender,
      up.PreferredLanguage, up.NationalID, a.FullAddress
      FROM [Users].[User] u
      LEFT JOIN [Users].[UserProfile] up ON u.UserID = up.UserID
      LEFT JOIN [Infrastructure].[Address] a ON up.AddressID = a.AddressID
      WHERE u.UserID = @UserID`, { UserID: userId });
    if (user.recordset.length === 0) throw new NotFoundError('User');
    return user.recordset[0];
  }

  async updateProfile(userId, data) {
    const allowed = ['FullName', 'DisplayName', 'AvatarUrl', 'DateOfBirth', 'Gender', 'PreferredLanguage', 'NationalID'];
    const updates = Object.entries(data).filter(([k]) => allowed.includes(k));
    if (updates.length === 0) return this.getProfile(userId);

    const setClause = updates.map(([k]) => `[${k}] = @${k}`).join(', ');
    await query(`UPDATE [Users].[UserProfile] SET ${setClause}, UpdatedAt = SYSDATETIME() WHERE UserID = @UserID`,
      { ...Object.fromEntries(updates), UserID: userId });

    return this.getProfile(userId);
  }

  async _logLogin(userId, success, ip, ua, reason) {
    await query(`INSERT INTO [Users].[UserLoginHistory] (UserID, LoginAt, IPAddress, UserAgent, LoginSuccess, FailureReason, AuthMethod)
      VALUES (@UserID, SYSDATETIME(), @IP, @UA, @Success, @Reason, 'Password')`, {
      UserID: userId, IP: ip || null, UA: ua || null, Success: success ? 1 : 0, Reason: reason || null,
    });
  }
}

module.exports = new AuthService();
