/**
 * Global error-handling middleware.
 *
 * Catches any error thrown or passed via next(err) in Express route handlers
 * and returns a standardised JSON error envelope.
 * A raw stack trace is NEVER leaked to the client.
 *
 * Response shape:
 *   { "success": false, "error": "<human-readable message>" }
 */
const errorHandler = (err, req, res, next) => { // eslint-disable-line no-unused-vars
  // Log the full error server-side for debugging
  console.error('[ErrorHandler]', err);

  // Determine HTTP status code
  const statusCode = err.statusCode || err.status || 500;

  // Determine a safe, human-readable message
  const message =
    process.env.NODE_ENV === 'production' && statusCode === 500
      ? 'An internal server error occurred.'
      : err.message || 'An unexpected error occurred.';

  return res.status(statusCode).json({
    success: false,
    error: message,
  });
};

module.exports = errorHandler;
