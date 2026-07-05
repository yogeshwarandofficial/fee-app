/**
 * seedAdmin.js
 *
 * One-time seed script: creates a single Admin document from environment
 * variables if none exists yet.
 *
 * Usage:
 *   node src/utils/seedAdmin.js
 *
 * Required env vars:
 *   ADMIN_USERNAME  — the admin login username
 *   ADMIN_PASSWORD  — the plain-text password (hashed with bcrypt before saving)
 */

require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });

const mongoose = require('mongoose');
const bcrypt   = require('bcrypt');
const connectDB = require('../config/db');
const Admin    = require('../models/Admin');

const BCRYPT_SALT_ROUNDS = 12;

const seed = async () => {
  const username = process.env.ADMIN_USERNAME;
  const password = process.env.ADMIN_PASSWORD;

  if (!username || !password) {
    console.error(
      '❌  ADMIN_USERNAME and ADMIN_PASSWORD must be set in .env before seeding.'
    );
    process.exit(1);
  }

  try {
    await connectDB();

    const existing = await Admin.findOne({ username });
    if (existing) {
      console.log(`ℹ️  Admin "${username}" already exists — seed skipped.`);
      await mongoose.disconnect();
      return;
    }

    const password_hash = await bcrypt.hash(password, BCRYPT_SALT_ROUNDS);
    await Admin.create({ username, password_hash });

    console.log(`✅  Admin "${username}" created successfully.`);
  } catch (err) {
    console.error('❌  Seed failed:', err.message);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
  }
};

seed();
