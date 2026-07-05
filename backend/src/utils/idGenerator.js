const Student      = require('../models/Student');
const Transaction  = require('../models/Transaction');
const AllocationLog = require('../models/AllocationLog');

/**
 * Generates the next sequential human-readable ID for a collection.
 *
 * ID formats:
 *   Students:       ST001, ST002, ... ST999, ST1000, ...
 *   Transactions:   TXN_10001, TXN_10002, ...
 *   AllocationLogs: ALC_1001,  ALC_1002,  ...
 *
 * Strategy: find the current maximum numeric suffix, increment by 1.
 * This is collision-free for single-writer (admin-only) usage and produces
 * human-readable, gap-free IDs that match what school staff expect to see.
 *
 * Note: For high-concurrency systems a counter collection + findOneAndUpdate
 * atomic increment would be safer. This school app has a single admin user,
 * so sequential regex-based max is sufficient and simpler.
 */

// ── Student ID: ST001 ──────────────────────────────────────────────────────
const generateStudentId = async () => {
  const last = await Student.findOne(
    { student_id: /^ST\d+$/ },
    { student_id: 1 }
  ).sort({ student_id: -1 }).lean();

  if (!last) return 'ST001';

  const num    = parseInt(last.student_id.replace('ST', ''), 10);
  const next   = num + 1;
  const padded = String(next).padStart(3, '0');   // minimum 3 digits, grows naturally
  return `ST${padded}`;
};

// ── Transaction ID: TXN_10001 ──────────────────────────────────────────────
const generateTransactionId = async () => {
  const last = await Transaction.findOne(
    { transaction_id: /^TXN_\d+$/ },
    { transaction_id: 1 }
  ).sort({ transaction_id: -1 }).lean();

  if (!last) return 'TXN_10001';

  const num  = parseInt(last.transaction_id.replace('TXN_', ''), 10);
  return `TXN_${num + 1}`;
};

// ── Allocation Log ID: ALC_1001 ────────────────────────────────────────────
const generateAllocationLogId = async () => {
  const last = await AllocationLog.findOne(
    { log_id: /^ALC_\d+$/ },
    { log_id: 1 }
  ).sort({ log_id: -1 }).lean();

  if (!last) return 'ALC_1001';

  const num  = parseInt(last.log_id.replace('ALC_', ''), 10);
  return `ALC_${num + 1}`;
};

module.exports = {
  generateStudentId,
  generateTransactionId,
  generateAllocationLogId,
};
