const bcrypt = require('bcrypt');
const jwt    = require('jsonwebtoken');
const Admin  = require('../models/Admin');
const { sendSuccess, sendError } = require('../utils/responseHelper');

/**
 * POST /api/auth/login
 *
 * Security note: both "username not found" and "wrong password" return the
 * IDENTICAL message and status code to prevent username enumeration attacks.
 */
const login = async (req, res, next) => {
  try {
    const { username, password } = req.body;

    // Basic presence check — same generic error, never reveals which field
    if (!username || !password) {
      return sendError(res, 'Invalid Credentials', 401);
    }

    const admin = await Admin.findOne({ username: username.trim() });

    // Intentional: do NOT short-circuit here — always run bcrypt so response
    // time is constant whether the user exists or not (timing-attack mitigation).
    const DUMMY_HASH = '$2b$12$invalidhashusedfortimingprotectionXXXXXXXXXXXXXXXXXXXXX';
    const hashToCompare = admin ? admin.password_hash : DUMMY_HASH;

    const isMatch = await bcrypt.compare(password, hashToCompare);

    if (!admin || !isMatch) {
      return sendError(res, 'Invalid Credentials', 401);
    }

    const token = jwt.sign(
      { id: admin._id, username: admin.username },
      process.env.JWT_SECRET,
      { expiresIn: '12h' }
    );

    return sendSuccess(
      res,
      { token, username: admin.username },
      'Login successful'
    );
  } catch (err) {
    next(err);
  }
};

module.exports = { login };
