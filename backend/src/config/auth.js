module.exports = {
  jwtSecret: process.env.JWT_SECRET || 'ev-charging-super-secret-key-2026',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '8h',
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  bcryptSaltRounds: parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12,
  port: parseInt(process.env.PORT) || 3000,
};
