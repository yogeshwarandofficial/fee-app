const express = require('express');
const router  = express.Router();
const { login } = require('../controllers/authController');

// POST /api/auth/login  — public, no auth middleware
router.post('/login', login);

module.exports = router;
