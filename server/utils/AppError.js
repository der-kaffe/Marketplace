// utils/AppError.js
class AppError extends Error {
  constructor(message, code = "APP_ERROR", statusCode = 400, details = null) {
    super(message);
    this.code = code;          // Código único del error (ej: USER_NOT_FOUND)
    this.statusCode = statusCode; // HTTP status (ej: 404)
    this.details = details;    // Info extra (ej: { field: "email" })
  }
}

module.exports = AppError;