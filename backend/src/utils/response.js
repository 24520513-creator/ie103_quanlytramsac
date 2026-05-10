function success(data, message = 'Success') {
  return { success: true, message, data };
}

function successResponse(data, message = 'Success') {
  return { success: true, message, data };
}

function fail(message = 'Internal server error', statusCode = 500) {
  return { success: false, message, error: message };
}

function errorResponse(message = 'Internal server error', statusCode = 500) {
  return { success: false, message, statusCode };
}

class AppError extends Error {
  constructor(message, statusCode = 400) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

class BadRequestError extends AppError {
  constructor(message = 'Bad request') { super(message, 400); }
}

class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') { super(message, 401); }
}

class NotFoundError extends AppError {
  constructor(message = 'Resource not found') { super(message, 404); }
}

class ConflictError extends AppError {
  constructor(message = 'Resource already exists') { super(message, 409); }
}

class ValidationError extends AppError {
  constructor(message = 'Validation failed') { super(message, 422); }
}

function paginatedResponse(data, total, page, limit) {
  return {
    success: true,
    data,
    pagination: {
      total,
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 10,
      totalPages: Math.ceil(total / (parseInt(limit) || 10)),
    },
  };
}

module.exports = {
  success, successResponse, fail, errorResponse, paginatedResponse,
  AppError, BadRequestError, UnauthorizedError,
  NotFoundError, ConflictError, ValidationError,
};
