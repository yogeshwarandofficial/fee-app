/**
 * Standard JSON API response helpers.
 *
 * Every API response must be sent through one of these helpers so the
 * envelope shape is consistent across the entire codebase.
 *
 * Success envelope: { "success": true,  "data": <payload>, "message": "..." }
 * Error envelope:   { "success": false, "error": "<message>" }
 */

/**
 * Send a successful response.
 * @param {import('express').Response} res
 * @param {*} data   - The payload to return (object, array, null, etc.)
 * @param {string} [message='Success']
 * @param {number} [statusCode=200]
 */
const sendSuccess = (res, data, message = 'Success', statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    data,
    message,
  });
};

/**
 * Send an error response.
 * @param {import('express').Response} res
 * @param {string} error   - Human-readable error message (no stack trace)
 * @param {number} [statusCode=500]
 */
const sendError = (res, error, statusCode = 500) => {
  return res.status(statusCode).json({
    success: false,
    error,
  });
};

module.exports = { sendSuccess, sendError };
