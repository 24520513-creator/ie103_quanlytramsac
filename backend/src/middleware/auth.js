const jwt = require('jsonwebtoken');
const { UnauthorizedError, ForbiddenError } = require('../utils/response');
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

function authorize(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) throw new UnauthorizedError();
    if (!allowedRoles.includes(req.user.Role) && !allowedRoles.includes('*')) {
      throw new ForbiddenError('Insufficient permissions');
    }
    next();
  };
}

module.exports = { authenticate, authorize };
