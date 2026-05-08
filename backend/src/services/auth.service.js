const bcrypt = require('bcryptjs');
const { query } = require('../config/db');
const { generateToken } = require('../utils/jwt');
const { ConflictError, UnauthorizedError, ValidationError } = require('../utils/response');

const SALT_ROUNDS = parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12;

async function signup({ FullName, Email, Phone, Password }) {
  if (!Email || !Email.includes('@')) {
    throw new ValidationError('Valid email is required');
  }
  if (!Password || Password.length < 6) {
    throw new ValidationError('Password must be at least 6 characters');
  }
  if (!FullName || FullName.trim().length === 0) {
    throw new ValidationError('Full name is required');
  }

  const existing = await query(
    `SELECT UserID FROM [Users].[User] WHERE Email = @Email`,
    { Email }
  );
  if (existing.recordset.length > 0) {
    throw new ConflictError('Email already registered');
  }

  const salt = await bcrypt.genSalt(SALT_ROUNDS);
  const hash = await bcrypt.hash(Password, salt);

  const userResult = await query(
    `INSERT INTO [Users].[User] (Username, Email, Phone, AccountStatus, CreatedAt)
     OUTPUT INSERTED.*
     VALUES (@Email, @Email, @Phone, 'Active', SYSDATETIME())`,
    { Email, Phone: Phone || null }
  );
  const user = userResult.recordset[0];

  await query(
    `INSERT INTO [Users].[UserProfile] (UserID, FullName, CreatedAt)
     VALUES (@UserID, @FullName, SYSDATETIME())`,
    { UserID: user.UserID, FullName }
  );

  await query(
    `INSERT INTO [Users].[UserCredential] (UserID, PasswordHash, PasswordSalt, HashAlgorithm, PasswordChangedAt)
     VALUES (@UserID, @Hash, @Salt, 'BCrypt', SYSDATETIME())`,
    { UserID: user.UserID, Hash: hash, Salt: salt }
  );

  const token = generateToken({ UserID: user.UserID, Email: user.Email });

  return {
    token,
    user: {
      UserID: user.UserID,
      Email: user.Email,
      FullName,
      Phone: Phone || null,
    },
  };
}

async function signin({ Email, Password }) {
  if (!Email || !Password) {
    throw new ValidationError('Email and password are required');
  }

  const userResult = await query(
    `SELECT u.UserID, u.Email, u.Phone, u.AccountStatus, u.FailedLoginAttempts, u.LockoutEnd,
            up.FullName, uc.PasswordHash
     FROM [Users].[User] u
     LEFT JOIN [Users].[UserProfile] up ON u.UserID = up.UserID
     LEFT JOIN [Users].[UserCredential] uc ON u.UserID = uc.UserID
     WHERE u.Email = @Email AND u.IsDeleted = 0`,
    { Email }
  );

  if (userResult.recordset.length === 0) {
    throw new UnauthorizedError('Invalid email or password');
  }

  const user = userResult.recordset[0];

  if (user.AccountStatus !== 'Active') {
    throw new UnauthorizedError(`Account is ${user.AccountStatus}`);
  }

  if (user.LockoutEnd && new Date(user.LockoutEnd) > new Date()) {
    throw new UnauthorizedError('Account is temporarily locked. Try again later.');
  }

  if (!user.PasswordHash) {
    throw new UnauthorizedError('No credentials configured for this account');
  }

  const valid = await bcrypt.compare(Password, user.PasswordHash);
  if (!valid) {
    await query(
      `UPDATE [Users].[User] SET FailedLoginAttempts = FailedLoginAttempts + 1 WHERE UserID = @UserID`,
      { UserID: user.UserID }
    );
    if (user.FailedLoginAttempts + 1 >= 5) {
      await query(
        `UPDATE [Users].[User] SET LockoutEnd = DATEADD(HOUR, 1, SYSDATETIME()) WHERE UserID = @UserID`,
        { UserID: user.UserID }
      );
    }
    throw new UnauthorizedError('Invalid email or password');
  }

  await query(
    `UPDATE [Users].[User] SET FailedLoginAttempts = 0, LastLoginAt = SYSDATETIME() WHERE UserID = @UserID`,
    { UserID: user.UserID }
  );

  const token = generateToken({ UserID: user.UserID, Email: user.Email });

  return {
    token,
    user: {
      UserID: user.UserID,
      Email: user.Email,
      FullName: user.FullName,
      Phone: user.Phone,
      AccountStatus: user.AccountStatus,
    },
  };
}

module.exports = { signup, signin };
