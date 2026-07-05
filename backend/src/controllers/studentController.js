const mongoose = require('mongoose');
const Student = require('../models/Student');
const Transaction = require('../models/Transaction');
const MasterConfig = require('../models/MasterConfig');
const { generateStudentId, generateTransactionId } = require('../utils/idGenerator');
const { generateExcelBuffer } = require('../utils/exportHelpers');
const { sendSuccess, sendError } = require('../utils/responseHelper');

// ── Phone sanitizer ──────────────────────────────────────────────────────────
// Strips spaces, hyphens, brackets, and leading country code (+91 or 91).
// Returns the cleaned string (does NOT validate — caller validates).
const sanitizePhone = (raw) => {
  if (!raw) return '';
  let s = String(raw).replace(/[\s\-()]/g, '');
  // Strip country code prefix: +91 or just 91 followed by 10 digits
  s = s.replace(/^(\+91|91)(?=\d{10}$)/, '');
  return s;
};

// ── Numeric guard: blank / null / undefined → 0, never NaN/negative ──────────
const safeNumber = (val, fallback = 0) => {
  if (val === null || val === undefined || val === '') return fallback;
  const n = Number(val);
  return isNaN(n) || n < 0 ? 0 : n;
};

// ── Build populated query (grade, section, route names inline) ────────────────
const populateQuery = (query) =>
  query
    .populate('grade_id', 'name')
    .populate('section_id', 'name')
    .populate('transport_route_id', 'name');

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/students
// ─────────────────────────────────────────────────────────────────────────────
const listStudents = async (req, res, next) => {
  try {
    const { grade_id, section_id, status, search, page = 1, limit = 20 } = req.query;

    const filter = {};
    if (grade_id)   filter.grade_id   = grade_id;
    if (section_id) filter.section_id = section_id;
    if (status)     filter.status     = status;
    if (search) {
      const regex = new RegExp(search.trim(), 'i');
      filter.$or = [{ full_name: regex }, { student_id: regex }];
    }

    const pageNum  = Math.max(1, parseInt(page, 10));
    const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10)));
    const skip     = (pageNum - 1) * limitNum;

    const [students, total] = await Promise.all([
      populateQuery(Student.find(filter)).sort({ student_id: 1 }).skip(skip).limit(limitNum).lean(),
      Student.countDocuments(filter),
    ]);

    return sendSuccess(res, {
      students,
      pagination: {
        total,
        page:       pageNum,
        limit:      limitNum,
        totalPages: Math.ceil(total / limitNum),
      },
    }, 'Students retrieved successfully');
  } catch (err) {
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/students/export — MUST be declared before /:id to avoid path clash
// ─────────────────────────────────────────────────────────────────────────────
const exportStudents = async (req, res, next) => {
  try {
    const { grade_id, section_id, status, search, ids } = req.query;

    const filter = {};
    if (grade_id)   filter.grade_id   = grade_id;
    if (section_id) filter.section_id = section_id;
    if (status)     filter.status     = status;
    if (search) {
      const regex = new RegExp(search.trim(), 'i');
      filter.$or = [{ full_name: regex }, { student_id: regex }];
    }
    // If specific IDs requested, narrow to only those (AND the other filters)
    if (ids) {
      const idList = (Array.isArray(ids) ? ids : ids.split(',')).map((i) => i.trim()).filter(Boolean);
      if (idList.length > 0) filter._id = { $in: idList };
    }

    const students = await populateQuery(Student.find(filter)).sort({ student_id: 1 }).lean();

    // Build human-readable filters map for the Excel header
    const appliedFilters = {};
    if (grade_id) {
      const g = await MasterConfig.findById(grade_id).lean();
      appliedFilters['Grade'] = g ? g.name : grade_id;
    }
    if (section_id) {
      const s = await MasterConfig.findById(section_id).lean();
      appliedFilters['Section'] = s ? s.name : section_id;
    }
    if (status)  appliedFilters['Status'] = status;
    if (search)  appliedFilters['Search'] = search;

    const columns = [
      { key: 'student_id',        header: 'Student ID',      width: 14 },
      { key: 'full_name',         header: 'Full Name',        width: 28 },
      { key: 'grade',             header: 'Grade',            width: 14 },
      { key: 'section',           header: 'Section',          width: 14 },
      { key: 'phone_number',      header: 'Phone',            width: 16 },
      { key: 'transport_route',   header: 'Transport Route',  width: 20 },
      { key: 'tuition_paid',      header: 'Tuition Paid ₹',   width: 16, numFmt: '#,##0.00' },
      { key: 'tuition_due',       header: 'Tuition Due ₹',    width: 16, numFmt: '#,##0.00' },
      { key: 'transport_paid',    header: 'Transport Paid ₹', width: 16, numFmt: '#,##0.00' },
      { key: 'transport_due',     header: 'Transport Due ₹',  width: 16, numFmt: '#,##0.00' },
      { key: 'other_paid',        header: 'Other Paid ₹',     width: 16, numFmt: '#,##0.00' },
      { key: 'other_due',         header: 'Other Due ₹',      width: 16, numFmt: '#,##0.00' },
      { key: 'status',            header: 'Status',           width: 12 },
    ];

    const rows = students.map((s) => ({
      student_id:      s.student_id,
      full_name:       s.full_name,
      grade:           s.grade_id?.name  || '',
      section:         s.section_id?.name || '',
      phone_number:    s.phone_number,
      transport_route: s.transport_route_id?.name || 'None',
      tuition_paid:    s.balances?.tuition?.paid    ?? 0,
      tuition_due:     s.balances?.tuition?.due     ?? 0,
      transport_paid:  s.balances?.transport?.paid  ?? 0,
      transport_due:   s.balances?.transport?.due   ?? 0,
      other_paid:      s.balances?.other?.paid      ?? 0,
      other_due:       s.balances?.other?.due       ?? 0,
      status:          s.status,
    }));

    // Filename: Students_Export_<grade-or-All>_<YYYY-MM-DD_HHMM>.xlsx
    const gradeLabel = appliedFilters['Grade'] ? appliedFilters['Grade'].replace(/\s+/g, '') : 'All';
    const now = new Date();
    const pad = (n) => String(n).padStart(2, '0');
    const datePart = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}_${pad(now.getHours())}${pad(now.getMinutes())}`;
    const filename = `Students_Export_${gradeLabel}_${datePart}.xlsx`;

    const buffer = await generateExcelBuffer('Student List', columns, rows, appliedFilters);

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    return res.send(buffer);
  } catch (err) {
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/students/:id
// ─────────────────────────────────────────────────────────────────────────────
const getStudent = async (req, res, next) => {
  try {
    const student = await populateQuery(Student.findById(req.params.id)).lean();
    if (!student) return sendError(res, 'Student not found.', 404);
    return sendSuccess(res, student, 'Student retrieved successfully');
  } catch (err) {
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/students/:id/history
// ─────────────────────────────────────────────────────────────────────────────
const getStudentHistory = async (req, res, next) => {
  try {
    const student = await Student.findById(req.params.id).lean();
    if (!student) return sendError(res, 'Student not found.', 404);

    const transactions = await Transaction.find({ student_id: req.params.id })
      .sort({ timestamp: -1 })
      .lean();

    return sendSuccess(res, transactions, 'Transaction history retrieved successfully');
  } catch (err) {
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/students
// ─────────────────────────────────────────────────────────────────────────────
const createStudent = async (req, res, next) => {
  try {
    const {
      full_name,
      grade_id,
      section_id,
      phone_number,
      avatar_url,
      transport_route_id,
      balances,
    } = req.body;

    // ── full_name required ────────────────────────────────────────────────
    if (!full_name || !full_name.trim()) {
      return sendError(res, 'full_name is required and cannot be empty.', 400);
    }

    // ── phone sanitize + validate ─────────────────────────────────────────
    const cleanPhone = sanitizePhone(phone_number);
    if (!/^\d{10}$/.test(cleanPhone)) {
      return sendError(res, 'phone_number must be exactly 10 digits (after stripping spaces, hyphens, and country code).', 400);
    }

    // ── grade_id required ─────────────────────────────────────────────────
    if (!grade_id) return sendError(res, 'grade_id is required.', 400);

    // ── section_id required ───────────────────────────────────────────────
    if (!section_id) return sendError(res, 'section_id is required.', 400);

    // ── balances: guard against negative / NaN ────────────────────────────
    const parsedBalances = {
      tuition:   { paid: safeNumber(balances?.tuition?.paid),   due: safeNumber(balances?.tuition?.due)   },
      transport: { paid: safeNumber(balances?.transport?.paid), due: safeNumber(balances?.transport?.due) },
      other:     { paid: safeNumber(balances?.other?.paid),     due: safeNumber(balances?.other?.due)     },
    };

    const student_id = await generateStudentId();

    // Derive initial status
    const totalDue =
      parsedBalances.tuition.due +
      parsedBalances.transport.due +
      parsedBalances.other.due;
    const status = totalDue === 0 ? 'cleared' : 'pending';

    const student = new Student({
      student_id,
      full_name:          full_name.trim(),
      grade_id,
      section_id,
      phone_number:       cleanPhone,
      avatar_url:         avatar_url || null,
      transport_route_id: transport_route_id || null,
      balances:           parsedBalances,
      status,
    });

    await student.save();
    const populated = await populateQuery(Student.findById(student._id)).lean();
    return sendSuccess(res, populated, 'Student created successfully', 201);
  } catch (err) {
    if (err.code === 11000) {
      return sendError(res, 'A student with this ID already exists.', 400);
    }
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// PUT /api/students/:id
// ─────────────────────────────────────────────────────────────────────────────
const updateStudent = async (req, res, next) => {
  try {
    const student = await Student.findById(req.params.id);
    if (!student) return sendError(res, 'Student not found.', 404);

    const {
      full_name,
      grade_id,
      section_id,
      phone_number,
      avatar_url,
      transport_route_id,
      balances,
    } = req.body;

    // ── full_name ─────────────────────────────────────────────────────────
    if (full_name !== undefined) {
      if (!full_name || !full_name.trim()) {
        return sendError(res, 'full_name cannot be empty.', 400);
      }
      student.full_name = full_name.trim();
    }

    // ── phone ─────────────────────────────────────────────────────────────
    if (phone_number !== undefined) {
      const cleanPhone = sanitizePhone(phone_number);
      if (!/^\d{10}$/.test(cleanPhone)) {
        return sendError(res, 'phone_number must be exactly 10 digits.', 400);
      }
      student.phone_number = cleanPhone;
    }

    if (grade_id   !== undefined) student.grade_id   = grade_id;
    if (section_id !== undefined) student.section_id = section_id;
    if (avatar_url !== undefined) student.avatar_url = avatar_url || null;

    // Transport route: pure reassignment, no fee logic here
    if (transport_route_id !== undefined) {
      student.transport_route_id = transport_route_id || null;
    }

    // ── balance override (manual correction by admin) ─────────────────────
    if (balances !== undefined) {
      student.balances = {
        tuition:   { paid: safeNumber(balances?.tuition?.paid),   due: safeNumber(balances?.tuition?.due)   },
        transport: { paid: safeNumber(balances?.transport?.paid), due: safeNumber(balances?.transport?.due) },
        other:     { paid: safeNumber(balances?.other?.paid),     due: safeNumber(balances?.other?.due)     },
      };
    }

    // Recompute status
    const totalDue =
      student.balances.tuition.due +
      student.balances.transport.due +
      student.balances.other.due;
    student.status = totalDue === 0 ? 'cleared' : 'pending';

    await student.save();
    const populated = await populateQuery(Student.findById(student._id)).lean();
    return sendSuccess(res, populated, 'Student updated successfully');
  } catch (err) {
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// PUT /api/students/:id/fees  — record a payment
// ─────────────────────────────────────────────────────────────────────────────
const updateStudentFees = async (req, res, next) => {
  try {
    const { fee_category, amount } = req.body;

    if (!['tuition', 'transport', 'other'].includes(fee_category)) {
      return sendError(res, 'fee_category must be tuition, transport, or other.', 400);
    }

    const parsedAmount = Number(amount);
    if (isNaN(parsedAmount) || parsedAmount <= 0) {
      return sendError(res, 'amount must be a positive number greater than 0.', 400);
    }

    const student = await Student.findById(req.params.id);
    if (!student) {
      return sendError(res, 'Student not found.', 404);
    }

    const currentDue = student.balances[fee_category].due;
    if (parsedAmount > currentDue) {
      return sendError(
        res,
        `Overpayment blocked: the current ${fee_category} due is ₹${currentDue.toFixed(2)}, but ₹${parsedAmount.toFixed(2)} was submitted.`,
        400
      );
    }

    // Atomic balance update
    student.balances[fee_category].due  -= parsedAmount;
    student.balances[fee_category].paid += parsedAmount;

    // Recompute status
    const totalDue =
      student.balances.tuition.due +
      student.balances.transport.due +
      student.balances.other.due;
    student.status = totalDue === 0 ? 'cleared' : 'pending';

    await student.save();

    // Create transaction record
    const transaction_id = await generateTransactionId();
    const txn = new Transaction({
      transaction_id,
      student_id:       student._id,
      fee_category,
      amount_collected: parsedAmount,
    });
    await txn.save();

    return sendSuccess(res, { student: student.toObject(), transaction: txn.toObject() }, 'Payment recorded successfully');
  } catch (err) {
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/students/:id/other-fee  — add a custom/other fee
// ─────────────────────────────────────────────────────────────────────────────
const addOtherFee = async (req, res, next) => {
  try {
    const { fee_description, amount } = req.body;

    if (!fee_description || !fee_description.trim()) {
      return sendError(res, 'fee_description is required and cannot be empty.', 400);
    }
    const parsedAmount = Number(amount);
    if (isNaN(parsedAmount) || parsedAmount <= 0) {
      return sendError(res, 'amount must be a positive number greater than 0.', 400);
    }

    const student = await Student.findById(req.params.id);
    if (!student) return sendError(res, 'Student not found.', 404);

    student.custom_fees.push({
      fee_description: fee_description.trim(),
      amount:          parsedAmount,
      status:          'pending',
    });
    student.balances.other.due += parsedAmount;
    student.status = 'pending'; // adding a fee always makes them pending

    await student.save();
    const populated = await populateQuery(Student.findById(student._id)).lean();
    return sendSuccess(res, populated, 'Other fee added successfully', 201);
  } catch (err) {
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// DELETE /api/students/:id
// ─────────────────────────────────────────────────────────────────────────────
const deleteStudent = async (req, res, next) => {
  try {
    const student = await Student.findById(req.params.id);
    if (!student) return sendError(res, 'Student not found.', 404);

    await student.deleteOne();
    return sendSuccess(res, null, 'Student deleted successfully');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  listStudents,
  exportStudents,
  getStudent,
  getStudentHistory,
  createStudent,
  updateStudent,
  updateStudentFees,
  addOtherFee,
  deleteStudent,
};
