// Delegates to canonical AuthService (preserving signup/signin interface for swagger)
const authService = require('./AuthService');

async function signup({ FullName, Email, Phone, Password }) {
  const result = await authService.register({ FullName, Email, Phone, Password, Username: Email.split('@')[0] });
  const token = require('jsonwebtoken').sign(
    { UserID: result.UserID, Email: result.Email, Role: result.Role },
    require('../config/auth').jwtSecret,
    { expiresIn: require('../config/auth').jwtExpiresIn }
  );
  return { token, user: { UserID: result.UserID, Email: result.Email, FullName, Phone: Phone || null, Role: result.Role } };
}

async function signin({ Email, Password }) {
  return authService.login({ Email, Password });
}

async function forgotPassword({ Email }) {
  return authService.forgotPassword({ Email });
}

async function resetPassword({ Token, Password }) {
  return authService.resetPassword({ Token, Password });
}

module.exports = { signup, signin, forgotPassword, resetPassword };
