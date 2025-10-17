
function errorHandler(err, req, res, next) {
  console.error(err); // log interno

  // Código HTTP
  const statusCode = err.statusCode || 500;

  res.status(statusCode).json({
    success: false,
    error: {
      code: err.code || "INTERNAL_SERVER_ERROR",
      message: err.message || "Ocurrió un error inesperado",
      details: err.details || null
    }
  });
}

module.exports = errorHandler;
