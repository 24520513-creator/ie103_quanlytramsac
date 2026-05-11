// Re-export canonical error handler
const { errorHandler, asyncHandler } = require('./errorHandler');
module.exports = { errorHandler, asyncHandler };
