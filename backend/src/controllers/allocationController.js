const mongoose = require('mongoose');
const Student = require('../models/Student');
const AllocationLog = require('../models/AllocationLog');
const { generateAllocationLogId } = require('../utils/idGenerator');
const { sendSuccess, sendError } = require('../utils/responseHelper');
const { generateCsvString } = require('../utils/exportHelpers');

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Builds the MongoDB query filter based on fee_category and target scope.
 */
const buildFilterFromScope = (fee_category, target) => {
  if (!target || typeof target !== 'object') {
    throw new Error('Target scope must be explicitly provided.');
  }

  const filter = {};

  if (fee_category === 'tuition') {
    if (!target.grade_id) throw new Error('Tuition allocation requires a grade_id or "all".');
    if (target.grade_id !== 'all') {
      filter.grade_id = target.grade_id;
    }
  } else if (fee_category === 'transport') {
    if (!target.route_id || target.route_id === 'all') {
      throw new Error('Transport allocation requires a specific route_id. "All Routes" is not permitted.');
    }
    filter.transport_route_id = target.route_id;
  } else if (fee_category === 'other') {
    if (!target.grade_id || target.grade_id === 'all') {
      throw new Error('Other fee allocation requires a specific grade_id.');
    }
    filter.grade_id = target.grade_id;
    if (target.section_id && target.section_id !== 'all') {
      filter.section_id = target.section_id;
    }
  } else {
    throw new Error('Invalid fee_category.');
  }

  return filter;
};

// ── Endpoints ─────────────────────────────────────────────────────────────────

const previewAllocation = async (req, res, next) => {
  try {
    const { fee_category, target, amount, description } = req.body;

    // Validate inputs (similar to model validation)
    if (!['tuition', 'transport', 'other'].includes(fee_category)) {
      return sendError(res, 'Invalid fee_category.', 400);
    }
    if (typeof amount !== 'number' || isNaN(amount) || amount <= 0) {
      return sendError(res, 'amount must be a positive integer greater than 0.', 400);
    }
    if (!description || description.trim().length === 0) {
      return sendError(res, 'description is required.', 400);
    }

    let filter;
    try {
      filter = buildFilterFromScope(fee_category, target);
    } catch (err) {
      return sendError(res, err.message, 400);
    }

    // Resolve matching students
    const matchedStudents = await Student.find(filter)
      .select('full_name student_id')
      .lean();

    const matchedCount = matchedStudents.length;
    // Return a sample of up to 5 names for the UI confirmation modal
    const sampleStudentNames = matchedStudents
      .slice(0, 5)
      .map(s => `${s.full_name} (${s.student_id})`);

    return sendSuccess(res, { matchedCount, sampleStudentNames }, 'Preview successful.');
  } catch (err) {
    next(err);
  }
};

const executeAllocation = async (req, res, next) => {
  try {
    const { fee_category, target, amount, description } = req.body;

    if (!['tuition', 'transport', 'other'].includes(fee_category)) {
      return sendError(res, 'Invalid fee_category.', 400);
    }
    if (typeof amount !== 'number' || isNaN(amount) || amount <= 0) {
      return sendError(res, 'amount must be a positive integer greater than 0.', 400);
    }
    if (!description || description.trim().length === 0) {
      return sendError(res, 'description is required.', 400);
    }

    let filter;
    try {
      filter = buildFilterFromScope(fee_category, target);
    } catch (err) {
      return sendError(res, err.message, 400);
    }

    // Execute atomic bulk update
    const updateField = `balances.${fee_category}.due`;

    // Build the update operation.
    // For 'other' fee category we also push a custom_fees entry on each
    // student so the per-student breakdown stays in sync — exactly what
    // the individual addOtherFee endpoint does for a single student.
    const updateOp = {
      $inc: { [updateField]: amount },
      // also set status to pending if they had cleared dues previously
      $set: { status: 'pending' },
    };

    if (fee_category === 'other') {
      updateOp.$push = {
        custom_fees: {
          fee_description: description.trim(),
          amount,
          status: 'pending',
        },
      };
    }

    // updateMany is atomic per document and highly efficient
    const updateResult = await Student.updateMany(filter, updateOp);

    const matchedCount = updateResult.matchedCount;

    if (matchedCount > 0) {
      // Create Audit Log
      const log_id = await generateAllocationLogId();
      await AllocationLog.create({
        log_id,
        fee_category,
        target_scope: target,
        amount,
        description: description.trim(),
      });
    }

    return sendSuccess(
      res, 
      { matchedCount, modifiedCount: updateResult.modifiedCount }, 
      'Fee allocation applied successfully.'
    );
  } catch (err) {
    next(err);
  }
};

const getAllocationLog = async (req, res, next) => {
  try {
    const page  = parseInt(req.query.page, 10)  || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const skip  = (page - 1) * limit;

    const [logs, total] = await Promise.all([
      AllocationLog.find()
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      AllocationLog.countDocuments()
    ]);

    const totalPages = Math.ceil(total / limit);

    return sendSuccess(res, {
      logs,
      pagination: { total, page, limit, totalPages }
    }, 'Allocation logs fetched.');
  } catch (err) {
    next(err);
  }
};

const exportAllocationLog = async (req, res, next) => {
  try {
    const logs = await AllocationLog.find()
      .sort({ createdAt: -1 })
      .lean();

    const columns = [
      { key: 'log_id',       header: 'Log ID' },
      { key: 'timestamp',    header: 'Timestamp' },
      { key: 'fee_category', header: 'Category' },
      { key: 'target_scope', header: 'Target Scope' },
      { key: 'amount',       header: 'Amount (₹)' },
      { key: 'description',  header: 'Description' },
    ];

    const rows = logs.map(log => ({
      log_id:       log.log_id,
      timestamp:    log.timestamp ? log.timestamp.toISOString() : '',
      fee_category: log.fee_category,
      target_scope: JSON.stringify(log.target_scope), // Convert object to string for CSV
      amount:       log.amount,
      description:  log.description,
    }));

    const csvData = generateCsvString(columns, rows);

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="Allocation_Log_Export.csv"');
    return res.send(csvData);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  previewAllocation,
  executeAllocation,
  getAllocationLog,
  exportAllocationLog,
};
