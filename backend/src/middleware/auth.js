const jwt = require('jsonwebtoken');

/**
 * JWT authentication middleware.
 *
 * Verifies the Bearer token in the Authorization header.
 * On success: attaches decoded payload as `req.admin` and calls next().
 * On failure: returns 401 using the standard error envelope — never leaks
 * token internals or stack traces to the client.
 */
const auth = (req, res, next) => {
  const authHeader = req.headers['authorization'] || req.headers['Authorization'];

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      error:   'Authentication required. Please provide a valid Bearer token.',
    });
  }

  const token = authHeader.slice(7); // strip "Bearer "

  if (!token) {
    return res.status(401).json({
      success: false,
      error:   'Authentication token is missing.',
    });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.admin = decoded; // { id, username, iat, exp }
    next();
  } catch (err) {
    const isExpired = err.name === 'TokenExpiredError';
    return res.status(401).json({
      success: false,
      error:   isExpired
        ? 'Session expired. Please log in again.'
        : 'Invalid authentication token.',
    });
  }
};

module.exports = auth;
