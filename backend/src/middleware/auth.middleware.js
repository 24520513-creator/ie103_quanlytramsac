const { verifyToken } = require('../utils/jwt');
const { UnauthorizedError } = require('../utils/response');

function verifyTokenMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new UnauthorizedError('No token provided');
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = verifyToken(token);
    req.user = decoded;
    next();
  } catch (err) {
    throw new UnauthorizedError('Invalid or expired token');
  }
}

module.exports = { verifyToken: verifyTokenMiddleware };
