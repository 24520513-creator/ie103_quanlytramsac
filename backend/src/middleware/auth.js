const jwt = require('jsonwebtoken');
const { UnauthorizedError } = require('../utils/response');
const authConfig = require('../config/auth');

function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new UnauthorizedError('No token provided');
  }
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, authConfig.jwtSecret);
    req.user = decoded;
    next();
  } catch (err) {
    throw new UnauthorizedError('Invalid or expired token');
  }
}

function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const token = authHeader.split(' ')[1];
      req.user = jwt.verify(token, authConfig.jwtSecret);
    } catch (_) { /* ignore */ }
  }
  next();
}

function authorize(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) throw new UnauthorizedError();
    const hasRole = req.user.roles?.some(r => allowedRoles.includes(r));
    if (!hasRole && !allowedRoles.includes('*')) {
      throw new UnauthorizedError('Insufficient permissions');
    }
    next();
  };
}

module.exports = { authenticate, optionalAuth, authorize };
